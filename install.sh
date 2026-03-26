#!/bin/bash
# XRAY Skill 一键安装
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "⚡ 安装 XRAY Skill..."

# 1. 复制 skill 文件
mkdir -p ~/.claude/skills/xray
cp "$REPO_DIR/SKILL.md" ~/.claude/skills/xray/
echo "  ✓ Skill 已安装"

# 2. 安装 hook
mkdir -p ~/.claude/hooks
cp "$REPO_DIR/xray-push-detect.sh" ~/.claude/hooks/
chmod +x ~/.claude/hooks/xray-push-detect.sh
echo "  ✓ Hook 已安装"

# 3. 更新 settings.json（添加 PostToolUse hook）
SETTINGS=~/.claude/settings.json
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

# 检查是否已配置
if grep -q "xray-push-detect" "$SETTINGS" 2>/dev/null; then
  echo "  ✓ Hook 配置已存在，跳过"
else
  # 用 python 或 node 安全地修改 JSON
  if command -v python3 &>/dev/null; then
    python3 -c "
import json
with open('$SETTINGS') as f:
    cfg = json.load(f)
hooks = cfg.setdefault('hooks', {})
ptu = hooks.setdefault('PostToolUse', [])
ptu.append({
    'matcher': 'Bash',
    'hooks': [{'type': 'command', 'command': '~/.claude/hooks/xray-push-detect.sh'}]
})
with open('$SETTINGS', 'w') as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
print('  ✓ Hook 配置已添加到 settings.json')
"
  elif command -v node &>/dev/null; then
    node -e "
const fs = require('fs');
const cfg = JSON.parse(fs.readFileSync('$SETTINGS'));
cfg.hooks = cfg.hooks || {};
cfg.hooks.PostToolUse = cfg.hooks.PostToolUse || [];
cfg.hooks.PostToolUse.push({
  matcher: 'Bash',
  hooks: [{type: 'command', command: '~/.claude/hooks/xray-push-detect.sh'}]
});
fs.writeFileSync('$SETTINGS', JSON.stringify(cfg, null, 2));
console.log('  ✓ Hook 配置已添加到 settings.json');
"
  else
    echo "  ⚠ 需要手动配置 settings.json（无 python3/node）"
  fi
fi

# 4. 更新 CLAUDE.md（添加架构感知指令）
CLAUDE_MD=~/.claude/CLAUDE.md
if [ ! -f "$CLAUDE_MD" ]; then
  echo "" > "$CLAUDE_MD"
fi

if grep -q "XRAY 架构文档" "$CLAUDE_MD" 2>/dev/null; then
  echo "  ✓ CLAUDE.md 指令已存在，跳过"
else
  cat >> "$CLAUDE_MD" << 'XRAY_BLOCK'

## XRAY 架构文档

在对话过程中，如果意识到涉及架构级变更（例如：新增/删除模块、改变数据流或上下游关系、修改部署方式、变更数据库表结构、引入新的第三方依赖等），主动向用户提议执行 /xray 更新架构文档。
XRAY_BLOCK
  echo "  ✓ CLAUDE.md 架构感知指令已添加"
fi

echo ""
echo "✅ 安装完成！重启 Claude Code 后生效。"
echo "   使用方式：在任意项目中输入 /xray"
