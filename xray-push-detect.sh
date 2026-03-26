#!/bin/bash
# XRAY: detect git push and remind Claude to check architecture docs
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if echo "$COMMAND" | grep -q "git push"; then
  echo '{"additionalContext": "⚡ XRAY 提醒：检测到 git push，请回顾本次对话中的变更，判断是否涉及架构变更。如果涉及，请主动向用户展示变更摘要并提议执行 /xray 更新架构文档。"}'
fi

exit 0
