#!/bin/bash
# Reads `claude -p --output-format stream-json --verbose` on stdin and prints one JSON line:
# which skill was selected and why reading stopped. Exits at the stop event so the producer
# gets SIGPIPE instead of running (and spending) to the end.
#   routing-observe.sh [plugin-name] [plans-dir]
#   defaults: ios-tuist-skills, ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plans
# Plan mode writes its own plan file under plans-dir. That write is planning, not acting
# without a skill: it is recorded in plan_writes and reading continues.
set -euo pipefail

exec ruby -rjson -e '
  plugin = ARGV[0] || "ios-tuist-skills"
  plans_dir = ARGV[1].to_s.sub(%r{/+\z}, "")
  info = {
    "selected" => nil, "stop_reason" => "eof", "nested" => false, "tools_before_stop" => [],
    "write_path" => nil, "plan_writes" => [], "plugin_version" => nil, "claude_code_version" => nil,
    "model" => nil, "permission_mode" => nil, "cost_usd" => nil, "result_subtype" => nil
  }
  emit = lambda do
    info["selected"] ||= "none"
    puts JSON.generate(info)
    STDOUT.flush
    exit 0
  end
  STDIN.each_line do |line|
    event = (JSON.parse(line) rescue nil)
    next unless event.is_a?(Hash)
    case event["type"]
    when "system"
      next unless event["subtype"] == "init"
      entry = (event["plugins"] || []).find { |p| p["name"] == plugin }
      info["plugin_version"] = entry && entry["version"]
      info["claude_code_version"] = event["claude_code_version"]
      info["model"] = event["model"]
      info["permission_mode"] = event["permissionMode"]
    when "assistant"
      (event.dig("message", "content") || []).each do |item|
        next unless item.is_a?(Hash) && item["type"] == "tool_use"
        name = item["name"].to_s
        if name == "Skill"
          skill = item.dig("input", "skill").to_s
          info["selected"] = skill.start_with?("#{plugin}:") ? skill.delete_prefix("#{plugin}:") : "other:#{skill}"
          info["nested"] = !event["parent_tool_use_id"].nil?
          info["stop_reason"] = "skill"
          emit.call
        end
        info["tools_before_stop"] << name
        # A write before any skill means the model chose to act without one.
        if %w[Write Edit NotebookEdit].include?(name)
          path = item.dig("input", "file_path") || item.dig("input", "notebook_path")
          if !plans_dir.empty? && path.to_s.start_with?(plans_dir + "/")
            info["plan_writes"] << path
            next
          end
          info["write_path"] = path
          info["stop_reason"] = "write-tool"
          emit.call
        end
      end
    when "result"
      info["stop_reason"] = "result"
      info["result_subtype"] = event["subtype"]
      info["cost_usd"] = event["total_cost_usd"]
      emit.call
    end
  end
  emit.call
' "${1:-ios-tuist-skills}" "${2:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plans}"
