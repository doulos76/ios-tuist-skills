#!/bin/bash
# Lists target dependency edges added/removed between two manifest states and
# searches each added edge's consumer sources for an import of the dependency.
# Static evidence only: "no usage found" is reported, never acted on (WS1 rule:
# an edge is not removed because this script found no import).
set -euo pipefail

usage() {
  echo "Usage: $0 [--json] --before <dir|git-rev> [PROJECT_ROOT]" >&2
  exit 2
}

json=0
before=""
root=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --json) json=1 ;;
    --before) [ "$#" -ge 2 ] || usage; before="$2"; shift ;;
    -*) usage ;;
    *) [ -z "$root" ] || usage; root="$1" ;;
  esac
  shift
done
[ -n "$before" ] || usage
root="${root:-$PWD}"
[ -d "$root" ] || { echo "Not a directory: $root" >&2; exit 2; }
root="$(cd "$root" && pwd -P)"

exec ruby -rjson -ropen3 - "$root" "$before" "$json" <<'RUBY'
root, before, json_mode = ARGV[0], ARGV[1], ARGV[2] == "1"
NOTE = "no usage found != dependency unnecessary (static search; @_exported, macros, resources not detected)"
SKIP_DIRS = %w[.git .build Derived Tuist DerivedData]

def keep_manifest?(rel)
  File.basename(rel) == "Project.swift" && (rel.split("/")[0..-2] & SKIP_DIRS).empty?
end

def manifests_from_dir(dir)
  Dir.glob(File.join(dir, "**", "Project.swift")).sort.each_with_object({}) do |path, acc|
    rel = path.sub(/\A#{Regexp.escape(dir)}\//, "")
    acc[rel] = File.binread(path).force_encoding("UTF-8").scrub if keep_manifest?(rel)
  end
end

def manifests_from_rev(root, rev)
  list, status = Open3.capture2("git", "-C", root, "ls-tree", "-r", "--name-only", rev, "--", ".")
  unless status.success?
    warn "Not a directory or git revision: #{rev}"
    exit 2
  end
  list.lines.map(&:chomp).select { |rel| keep_manifest?(rel) }.sort.each_with_object({}) do |rel, acc|
    text, st = Open3.capture2("git", "-C", root, "show", "#{rev}:./#{rel}")
    acc[rel] = text.force_encoding("UTF-8").scrub if st.success?
  end
end

# Returns the text between the bracket at open_idx and its match; strings are skipped.
def balanced(text, open_idx)
  open = text[open_idx]
  close = open == "(" ? ")" : "]"
  depth = 0
  in_str = false
  i = open_idx
  while i < text.length
    c = text[i]
    if in_str
      in_str = false if c == '"' && text[i - 1] != "\\"
    elsif c == '"'
      in_str = true
    elsif c == open
      depth += 1
    elsif c == close
      depth -= 1
      return text[(open_idx + 1)...i] if depth.zero?
    end
    i += 1
  end
  nil
end

# A target definition is a `.target(`/`Target(` call that has `product:`; the
# same call without `product:` is a dependency reference and is skipped here.
def parse_targets(text)
  text = text.lines.reject { |l| l.strip.start_with?("//") }.join
  targets = []
  starts = []
  text.scan(/(?:\.target|\bTarget)\s*\(/) { starts << Regexp.last_match.end(0) - 1 }
  starts.each do |idx|
    body = balanced(text, idx)
    next unless body && body =~ /\bproduct:/
    name = body[/\bname:\s*"([^"]+)"/, 1]
    next unless name
    deps = []
    if (m = body.match(/\bdependencies:\s*\[/))
      dbody = balanced(body, m.end(0) - 1) || ""
      dbody.scan(/\.target\(\s*name:\s*"([^"]+)"/) { deps << $1 }
      dbody.scan(/\.project\(\s*target:\s*"([^"]+)"/) { deps << $1 }
    end
    dirs = []
    %w[buildableFolders sources].each do |key|
      if (m = body.match(/\b#{key}:\s*\[/))
        (balanced(body, m.end(0) - 1) || "").scan(/"([^"]+)"/) { dirs << $1 }
      elsif (m = body.match(/\b#{key}:\s*"([^"]+)"/))
        dirs << m[1]
      end
    end
    dirs = dirs.map { |d| d.split("*").first.to_s.chomp("/") }.reject(&:empty?)
    targets << { "name" => name, "deps" => deps.uniq, "dirs" => dirs.uniq }
  end
  targets
end

def edges(manifests)
  manifests.flat_map do |rel, text|
    parse_targets(text).flat_map { |t| t["deps"].map { |d| [rel, t["name"], d] } }
  end
end

def first_usage(root, manifest_rel, target, dep)
  project_dir = File.dirname(File.join(root, manifest_rel))
  dirs = target ? target["dirs"] : []
  if dirs.empty? && target
    dirs = [target["name"], "Targets/#{target["name"]}", "Sources/#{target["name"]}"]
  end
  re = /^\s*(?:@testable\s+|@_exported\s+|@_implementationOnly\s+)*import\s+(?:(?:class|struct|enum|protocol|func|var|let|typealias)\s+)?#{Regexp.escape(dep)}(?:\.|\s|$)/
  dirs.map { |d| File.join(project_dir, d) }.select { |d| File.directory?(d) }.each do |dir|
    Dir.glob(File.join(dir, "**", "*.swift")).sort.each do |file|
      File.foreach(file).with_index(1) do |line, n|
        return "#{file.sub(/\A#{Regexp.escape(root)}\//, "")}:#{n}" if line.scrub =~ re
      end
    end
  end
  nil
end

before_manifests = File.directory?(before) ? manifests_from_dir(File.expand_path(before)) : manifests_from_rev(root, before)
after_manifests = manifests_from_dir(root)
before_edges = edges(before_manifests)
after_edges = edges(after_manifests)

added = (after_edges - before_edges).map do |rel, from, to|
  target = parse_targets(after_manifests[rel]).find { |t| t["name"] == from }
  { "from" => from, "to" => to, "usage" => first_usage(root, rel, target, to) }
end
removed = (before_edges - after_edges).map { |_, from, to| { "from" => from, "to" => to } }

if json_mode
  puts JSON.pretty_generate("schema" => "ios-tuist-consumer-edges/1", "added" => added, "removed" => removed, "note" => NOTE)
else
  puts "Added edges (#{added.size}):"
  added.each { |e| puts "  #{e["from"]} -> #{e["to"]}: #{e["usage"] ? "usage found (#{e["usage"]})" : "no usage found"}" }
  puts "Removed edges (#{removed.size}):"
  removed.each { |e| puts "  #{e["from"]} -> #{e["to"]}" }
  puts "note: #{NOTE}"
end
RUBY
