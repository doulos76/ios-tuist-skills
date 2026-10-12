#!/bin/bash
# Validates tests/routing/cases.yaml (schema, fixture/skill references, PRD WS-C category minimums).
#   check-routing-cases.sh [cases.yaml]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CASES="${1:-$REPO_ROOT/tests/routing/cases.yaml}"
[ -f "$CASES" ] || { echo "FAIL no such file: $CASES" >&2; exit 1; }

ruby -ryaml -e '
  cases_file, repo = ARGV
  errors = []
  doc = YAML.safe_load(File.read(cases_file))
  unless doc.is_a?(Hash) && doc["version"] == 1 && doc["cases"].is_a?(Array)
    puts "FAIL schema: top level must be {version: 1, cases: [...]}"
    exit 1
  end
  skills = Dir.children(File.join(repo, "skills")).select { |d| File.file?(File.join(repo, "skills", d, "SKILL.md")) }.sort
  fixtures = Dir.children(File.join(repo, "tests", "fixtures")).select { |d| File.directory?(File.join(repo, "tests", "fixtures", d)) }
  categories = %w[positive negative adjacent official-conflict ambiguous]
  allowed = %w[id prompt fixture expected_skill category note forbidden_skills]
  seen = {}
  cases = doc["cases"]
  cases.each_with_index do |c, i|
    unless c.is_a?(Hash)
      errors << "case ##{i + 1}: not a mapping"
      next
    end
    where = "case ##{i + 1} (#{c["id"]})"
    extra = c.keys - allowed
    errors << "#{where}: unknown keys #{extra.join(", ")}" unless extra.empty?
    %w[id prompt fixture expected_skill category note].each do |k|
      errors << "#{where}: missing #{k}" unless c[k].is_a?(String) && !c[k].strip.empty?
    end
    id = c["id"].to_s
    errors << "#{where}: id must be kebab-case" unless id.match?(/\A[a-z0-9]+(-[a-z0-9]+)*\z/)
    errors << "#{where}: duplicate id" if seen[id]
    seen[id] = true
    errors << "#{where}: unknown fixture #{c["fixture"]}" unless fixtures.include?(c["fixture"])
    errors << "#{where}: unknown expected_skill #{c["expected_skill"]}" unless (skills + ["none"]).include?(c["expected_skill"])
    errors << "#{where}: unknown category #{c["category"]}" unless categories.include?(c["category"])
    if c.key?("forbidden_skills")
      f = c["forbidden_skills"]
      if !f.is_a?(Array) || f.empty? || f.any? { |s| !skills.include?(s) }
        errors << "#{where}: forbidden_skills must be a non-empty list of skill dirs"
      elsif f.include?(c["expected_skill"])
        errors << "#{where}: forbidden_skills contains expected_skill"
      end
    end
    errors << "#{where}: ambiguous case needs forbidden_skills" if c["category"] == "ambiguous" && !c.key?("forbidden_skills")
  end
  valid = cases.select { |c| c.is_a?(Hash) }
  count = ->(cat) { valid.count { |c| c["category"] == cat } }
  { "negative" => 8, "adjacent" => 6, "official-conflict" => 5, "ambiguous" => 3 }.each do |cat, min|
    n = count.call(cat)
    errors << "category #{cat}: #{n} < #{min}" if n < min
  end
  skills.each do |s|
    n = valid.count { |c| c["category"] == "positive" && c["expected_skill"] == s }
    errors << "category positive #{s}: #{n} < 2" if n < 2
  end
  errors << "total cases: #{valid.size} not in 30..50" unless (30..50).cover?(valid.size)
  korean = valid.count { |c| c["prompt"].to_s.match?(/\p{Hangul}/) }
  english = valid.size - korean
  errors << "korean prompts: #{korean} < 8" if korean < 8
  errors << "english prompts: #{english} < 8" if english < 8
  if errors.empty?
    summary = categories.map { |cat| "#{cat}=#{count.call(cat)}" }.join(" ")
    puts "ok   #{File.basename(cases_file)}: #{valid.size} cases (#{summary}; korean=#{korean} english=#{english})"
  else
    errors.each { |e| puts "FAIL #{e}" }
    exit 1
  end
' "$CASES" "$REPO_ROOT"
