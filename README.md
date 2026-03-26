# XRAY — 项目架构文档自动维护

AI 写的代码，AI 来维护文档。在 Claude Code 中自动感知架构变更，生成可视化文档站。

## 安装

```bash
git clone git@github.com:fly0pants/xray-skill.git /tmp/xray-skill && /tmp/xray-skill/install.sh
```

重启 Claude Code 即可使用。

## 使用

- `/xray` — 手动触发，生成/更新架构文档
- 自动触发 — git push 后自动提醒，对话中 Claude 主动感知架构变更

## 输出

在项目根目录生成 `xray/` 文档站：

```
xray/
├── index.html          # 导航首页 + 项目概览
├── modules.html        # 目录结构与模块职责
├── api-routes.html     # API 路由清单
├── data-flow.html      # 数据流与上下游
├── database.html       # 数据库表结构
├── deployment.html     # 部署架构
├── env-config.html     # 环境变量与配置
└── integrations.html   # 第三方服务集成
```

变更日志：`XRAY-CHANGELOG.md`

## 依赖

- jq（hook 脚本需要）
