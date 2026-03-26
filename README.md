# XRAY — 项目架构文档自动维护

## 安装

### 1. 复制 skill 文件
```bash
mkdir -p ~/.claude/skills/xray
cp SKILL.md ~/.claude/skills/xray/
```

### 2. 安装 hook
```bash
mkdir -p ~/.claude/hooks
cp hooks/xray-push-detect.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/xray-push-detect.sh
```

在 `~/.claude/settings.json` 的 `hooks` 中添加：
```json
"PostToolUse": [
  {
    "matcher": "Bash",
    "hooks": [
      {
        "type": "command",
        "command": "~/.claude/hooks/xray-push-detect.sh"
      }
    ]
  }
]
```

### 3. 添加架构感知指令

在 `~/.claude/CLAUDE.md` 中添加：
```markdown
## XRAY 架构文档
在对话过程中，如果意识到涉及架构级变更，主动向用户提议执行 /xray 更新架构文档。
```

## 使用

- `/xray` — 手动触发，分析当前项目并生成/更新架构文档
- 自动触发 — git push 后自动提醒，Claude 对话中主动感知

## 输出文件

- `XRAY.html` — 项目根目录，单文件自包含架构文档
- `XRAY-CHANGELOG.md` — 项目根目录，变更日志

## 依赖

- jq（hook 脚本需要）
