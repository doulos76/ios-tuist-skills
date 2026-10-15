#!/bin/bash
# Routing evaluation (PRD v0.9 WS-C): which skill does a headless Claude Code session pick?
#   run-routing-eval.sh run --condition plugin-only|plugin+official|none --out DIR \
#       [--cases FILE] [--only id1,id2] [--budget USD] [--official-plugin-dir DIR] [--yes]
#   run-routing-eval.sh summarize DIR
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

usage() {
  sed -n '3,5p' "$0" | sed 's/^# //' >&2
  exit 2
}

summarize() {
  local dir="$1"
  [ -s "$dir/results.jsonl" ] || { echo "error: no results in $dir/results.jsonl" >&2; exit 1; }
  ruby -rjson -e '
    dir = ARGV[0]
    rows = File.readlines(File.join(dir, "results.jsonl"), chomp: true).reject(&:empty?).map { |l| JSON.parse(l) }
    meta_path = File.join(dir, "meta.json")
    meta = File.exist?(meta_path) ? JSON.parse(File.read(meta_path)) : {}
    short = ->(s) { s.to_s.sub(/\Aios-tuist-/, "") }
    pct = ->(a, b) { b.zero? ? "n/a" : format("%.1f%%", 100.0 * a / b) }
    correct = ->(r) { r["selected"] == r["expected_skill"] }
    n_correct = rows.count(&correct)
    by_cat = rows.group_by { |r| r["category"] }.sort.map { |c, rs| [c, rs.count(&correct), rs.size] }
    violations = rows.select { |r| (r["forbidden_skills"] || []).include?(r["selected"]) }
    anomalies = rows.select { |r| r["stop_reason"] == "eof" || r["nested"] }
    plan_cases = rows.reject { |r| (r["plan_writes"] || []).empty? }
    skills = rows.flat_map { |r| [r["expected_skill"], r["selected"]] }.uniq
                 .reject { |s| s == "none" || s.to_s.start_with?("other:") }.sort
    per_skill = skills.map do |s|
      tp = rows.count { |r| r["selected"] == s && r["expected_skill"] == s }
      fp = rows.count { |r| r["selected"] == s && r["expected_skill"] != s }
      fn = rows.count { |r| r["expected_skill"] == s && r["selected"] != s }
      { "skill" => s, "tp" => tp, "fp" => fp, "fn" => fn,
        "precision" => (tp + fp).zero? ? nil : (tp.to_f / (tp + fp)).round(3),
        "recall" => (tp + fn).zero? ? nil : (tp.to_f / (tp + fn)).round(3) }
    end
    others = rows.map { |r| r["selected"] }.select { |s| s.to_s.start_with?("other:") }.uniq.sort
    row_labels = skills + ["none"]
    col_labels = skills + ["none"] + others
    matrix = row_labels.map { |e| col_labels.map { |s| rows.count { |r| r["expected_skill"] == e && r["selected"] == s } } }
    known = rows.map { |r| r["cost_usd"] }.compact
    plugin_versions = rows.map { |r| r["plugin_version"] }.compact.uniq
    aggregate = {
      "cases" => rows.size, "correct" => n_correct, "by_category" => by_cat.map { |c, k, n| { "category" => c, "correct" => k, "total" => n } },
      "violations" => violations.map { |r| r["id"] }, "anomalies" => anomalies.map { |r| r["id"] },
      "plan_write_cases" => plan_cases.map { |r| r["id"] },
      "per_skill" => per_skill, "confusion" => { "rows" => row_labels, "cols" => col_labels, "counts" => matrix },
      "known_cost_usd" => known.sum.round(4), "cost_known_cases" => known.size, "cost_unknown_cases" => rows.size - known.size,
      "plugin_versions" => plugin_versions
    }
    File.write(File.join(dir, "results.json"), JSON.pretty_generate({ "meta" => meta, "aggregate" => aggregate, "cases" => rows }) + "\n")
    fmt = ->(x) { x.nil? ? "n/a" : x.to_s }
    md = []
    md << "# Routing evaluation — #{meta["condition"] || "unknown condition"}"
    md << ""
    md << "Date: #{meta["date"] || "unknown"} | Claude Code: #{rows.map { |r| r["claude_code_version"] }.compact.uniq.join(", ")} | Plugin version: #{plugin_versions.join(", ")} | Budget/case: $#{meta["budget_usd"] || "?"}"
    md << ""
    md << "Accuracy: #{n_correct}/#{rows.size} (#{pct.call(n_correct, rows.size)})"
    md << ""
    md << "| Category | Correct | Rate |"
    md << "|---|---|---|"
    by_cat.each { |c, k, n| md << "| #{c} | #{k}/#{n} | #{pct.call(k, n)} |" }
    md << ""
    md << "## Forbidden-skill violations"
    md << (violations.empty? ? "- none" : violations.map { |r| "- #{r["id"]}: selected #{r["selected"]} (forbidden)" })
    md << ""
    md << "## Per skill"
    md << "| Skill | TP | FP | FN | Precision | Recall |"
    md << "|---|---|---|---|---|---|"
    per_skill.each { |p| md << "| #{short.call(p["skill"])} | #{p["tp"]} | #{p["fp"]} | #{p["fn"]} | #{fmt.call(p["precision"])} | #{fmt.call(p["recall"])} |" }
    md << ""
    md << "## Confusion matrix (rows = expected, columns = selected)"
    md << "| expected \\ selected | #{col_labels.map { |c| short.call(c) }.join(" | ")} |"
    md << "|---|#{col_labels.map { "---" }.join("|")}|"
    row_labels.each_with_index { |e, i| md << "| #{short.call(e)} | #{matrix[i].join(" | ")} |" }
    md << ""
    md << "## Anomalies"
    md << (anomalies.empty? ? "- none" : anomalies.map { |r| r["nested"] ? "- #{r["id"]}: skill selected inside a subagent" : "- #{r["id"]}: stop_reason eof" })
    md << ""
    md << "## Plan-mode plan files (recorded, not a stop)"
    md << (plan_cases.empty? ? "- none" : plan_cases.map { |r| "- #{r["id"]}: #{r["plan_writes"].size} plan-file write(s), then #{r["stop_reason"]}" })
    md << ""
    md << format("Known cost: $%.2f over %d cases; %d cases stopped before a result (cost unknown)", known.sum, known.size, rows.size - known.size)
    File.write(File.join(dir, "summary.md"), md.flatten.join("\n") + "\n")
    puts md.flatten
  ' "$dir"
}

# Same rules as isolation_guard in benchmark-isolated-run.sh: the case must not see this repo.
isolation_guard() {
  local work="$1" path
  case "$work" in "$REPO_ROOT"|"$REPO_ROOT"/*) echo "ISOLATION VIOLATION: $work" >&2; return 1 ;; esac
  path="$work"
  while :; do
    if { [ -d "$path/skills" ] && [ -d "$path/references" ]; } || [ -e "$path/CLAUDE.md" ]; then
      echo "ISOLATION VIOLATION: $path" >&2
      return 1
    fi
    [ "$path" = / ] && break
    path="$(dirname "$path")"
  done
}

run() {
  local condition="" out="" cases="$REPO_ROOT/tests/routing/cases.yaml" only="" budget="0.30" official="" yes=0
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --condition) condition="$2"; shift 2 ;;
      --out) out="$2"; shift 2 ;;
      --cases) cases="$2"; shift 2 ;;
      --only) only="$2"; shift 2 ;;
      --budget) budget="$2"; shift 2 ;;
      --official-plugin-dir) official="$2"; shift 2 ;;
      --yes) yes=1; shift ;;
      *) usage ;;
    esac
  done
  [ -n "$condition" ] && [ -n "$out" ] || usage
  local plugin_args=()
  case "$condition" in
    plugin-only) plugin_args=(--plugin-dir "$REPO_ROOT") ;;
    plugin+official)
      [ -n "$official" ] && [ -d "$official/.claude-plugin" ] || { echo "error: --official-plugin-dir must be a local tuist/agent-plugin checkout" >&2; exit 2; }
      official="$(cd "$official" && pwd -P)"
      plugin_args=(--plugin-dir "$REPO_ROOT" --plugin-dir "$official") ;;
    none) plugin_args=() ;;
    *) usage ;;
  esac
  "$REPO_ROOT/scripts/check-routing-cases.sh" "$cases"
  [ ! -e "$out/results.jsonl" ] || { echo "error: $out/results.jsonl exists; use a fresh --out" >&2; exit 2; }
  mkdir -p "$out/observe" "$out/raw" "$out/stderr"
  out="$(cd "$out" && pwd -P)"
  local tmp_root list prompts
  tmp_root="$(cd "${TMPDIR:-/tmp}" && pwd -P)"
  prompts="$(mktemp -d "$tmp_root/routing-prompts.XXXXXX")"
  list="$prompts/list.tsv"
  ruby -ryaml -e '
    only = ARGV[1].to_s.split(",")
    YAML.safe_load(File.read(ARGV[0]))["cases"].each do |c|
      next unless only.empty? || only.include?(c["id"])
      File.write(File.join(ARGV[2], c["id"] + ".txt"), c["prompt"])
      puts [c["id"], c["fixture"]].join("\t")
    end
  ' "$cases" "$only" "$prompts" > "$list"
  local count; count="$(wc -l < "$list" | tr -d " ")"
  [ "$count" -gt 0 ] || { echo "error: no cases selected" >&2; exit 2; }
  echo "Cases: $count, budget/case: \$$budget, worst case: \$$(ruby -e "puts format('%.2f', $count * $budget)")"
  # Guard against accidental spend: more than 5 cases needs an explicit --yes.
  [ "$count" -le 5 ] || [ "$yes" -eq 1 ] || { echo "error: $count cases; re-run with --yes to spend up to the amount above" >&2; exit 2; }
  ruby -rjson -rdigest -e '
    File.write(ARGV[0], JSON.pretty_generate({
      "condition" => ARGV[1], "date" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"), "repo_revision" => ARGV[2],
      "claude_version" => ARGV[3], "budget_usd" => ARGV[4].to_f, "cases_sha256" => Digest::SHA256.file(ARGV[5]).hexdigest,
      "official_plugin_dir" => (ARGV[6].empty? ? nil : ARGV[6]),
      "plugin_version" => JSON.parse(File.read(ARGV[7])).fetch("version")
    }) + "\n")
  ' "$out/meta.json" "$condition" "$(git -C "$REPO_ROOT" rev-parse HEAD)" "$(claude --version 2>&1)" "$budget" "$cases" "$official" "$REPO_ROOT/.claude-plugin/plugin.json"
  local plans_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plans"
  : > "$out/plans-created.txt"
  local id fixture parent work prompt start statuses observe_status claude_exit
  while IFS=$'\t' read -r id fixture; do
    parent="$(mktemp -d "$tmp_root/routing-eval.XXXXXX")"
    work="$parent/$fixture"
    cp -R "$REPO_ROOT/tests/fixtures/$fixture" "$work"
    # The expectation document would hand the model the answer.
    rm -f "$work/EXPECTATIONS.md" "$work/.gitkeep"
    isolation_guard "$work"
    prompt="$(cat "$prompts/$id.txt")"
    ls -1 "$plans_dir" 2>/dev/null | sort > "$parent/plans-before.txt" || true
    echo "--- $id ($fixture)"
    start=$SECONDS
    set +e
    (cd "$work" && claude -p "$prompt" "${plugin_args[@]}" --setting-sources project --permission-mode plan \
        --output-format stream-json --verbose --max-budget-usd "$budget" < /dev/null 2> "$out/stderr/$id.txt") \
      | tee "$out/raw/$id.jsonl" | "$REPO_ROOT/scripts/routing-observe.sh" ios-tuist-skills "$plans_dir" > "$out/observe/$id.json"
    statuses=("${PIPESTATUS[@]}")
    set -e
    claude_exit="${statuses[0]}"
    observe_status="${statuses[2]}"
    [ "$observe_status" -eq 0 ] || { echo "error: observer failed on $id" >&2; exit 1; }
    [ -s "$out/observe/$id.json" ] || echo '{"selected":"none","stop_reason":"no-output"}' > "$out/observe/$id.json"
    ruby -ryaml -rjson -e '
      c = YAML.safe_load(File.read(ARGV[0]))["cases"].find { |x| x["id"] == ARGV[1] }
      o = JSON.parse(File.read(ARGV[2]))
      row = { "id" => c["id"], "category" => c["category"], "fixture" => c["fixture"],
              "expected_skill" => c["expected_skill"], "forbidden_skills" => c["forbidden_skills"] || [] }
      puts JSON.generate(row.merge(o).merge("elapsed_s" => ARGV[3].to_i, "claude_exit" => ARGV[4].to_i))
    ' "$cases" "$id" "$out/observe/$id.json" "$((SECONDS - start))" "$claude_exit" >> "$out/results.jsonl"
    # Plan mode writes plan files outside the workdir. List them, never delete: another session may own them.
    ls -1 "$plans_dir" 2>/dev/null | sort | comm -13 "$parent/plans-before.txt" - | sed "s|^|$id\t$plans_dir/|" >> "$out/plans-created.txt" || true
    rm -rf -- "$parent"
  done < "$list"
  rm -rf -- "$prompts"
  summarize "$out"
}

[ "$#" -ge 1 ] || usage
case "$1" in
  run) shift; run "$@" ;;
  summarize) [ "$#" -eq 2 ] || usage; summarize "$2" ;;
  *) usage ;;
esac
