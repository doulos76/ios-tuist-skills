#!/bin/bash
# Fails when a skill folder is not self-contained: every relative markdown
# link and every ${CLAUDE_SKILL_DIR}/... path in a skill's .md files must
# resolve inside that skill's own folder (skills can be installed one folder
# at a time; the Agent Skills spec only defines paths relative to the skill root).
# Usage: check-skill-links.sh [SKILLS_DIR]   (default: <repo>/skills)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${1:-$REPO_ROOT/skills}"

ruby -rpathname - "$SKILLS_DIR" <<'RUBY'
skills_dir = Pathname(ARGV[0]).expand_path
abort "no such directory: #{skills_dir}" unless skills_dir.directory?
skill_dirs = skills_dir.children.select { |d| (d / "SKILL.md").file? }.sort
abort "no skills under #{skills_dir}" if skill_dirs.empty?
checked = 0
problems = []

skill_dirs.each do |skill|
  Dir.glob("**/*.md", base: skill.to_s).sort.each do |rel|
    file = skill / rel
    in_fence = false
    File.foreach(file).with_index(1) do |line, n|
      if line.lstrip.start_with?("```")
        in_fence = !in_fence
        next
      end
      next if in_fence
      line.scan(/\]\(([^)\s]+)\)/).flatten.each do |target|
        next if target.start_with?("#") || target.match?(/\A[a-z][a-z0-9+.-]*:/i)
        checked += 1
        path = target.sub(/#.*\z/, "")
        resolved = (file.dirname / path).expand_path
        problem =
          if path.start_with?("/") then "absolute path"
          elsif path.split("/").include?("..") then "uses .."
          elsif !resolved.to_s.start_with?("#{skill}/") then "outside the skill"
          elsif !resolved.exist? then "missing"
          end
        problems << "#{skill.basename}/#{rel}:#{n}: #{target} (#{problem})" if problem
      end
      line.scan(%r{\$\{CLAUDE_SKILL_DIR\}/([^\s`"')]+)}).flatten.each do |p|
        checked += 1
        problems << "#{skill.basename}/#{rel}:#{n}: ${CLAUDE_SKILL_DIR}/#{p} (missing)" unless (skill / p).exist?
      end
    end
  end
end

problems.each { |p| puts "FAIL #{p}" }
puts "checked #{checked} link(s) in #{skill_dirs.size} skill(s), #{problems.size} problem(s)"
exit(problems.empty? ? 0 : 1)
RUBY
