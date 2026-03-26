---
name: xray
description: 自动维护项目架构文档站（xray/ 目录，多 HTML 文件）。当检测到架构变更时主动提议更新。也可通过 /xray 手动触发。
---

# XRAY — 项目架构文档维护

维护项目根目录下的 `xray/` 文档站和 `XRAY-CHANGELOG.md` 变更日志。

## 触发场景

1. **用户输入 `/xray`** — 手动触发，执行完整的分析和更新流程
2. **git push hook 提醒** — Claude 自主判断是否需要更新
3. **对话中主动感知** — Claude 发现架构级变更时主动提议（由 CLAUDE.md 指令驱动）

## 工作流程

### Phase 1：判断是否需要更新

综合分析代码变更和对话上下文，判断是否涉及架构级变更。

如果判断需要更新，**必须先向用户展示变更摘要**，等用户确认后再执行：

```
⚡ XRAY 架构变更检测

发现以下架构变更，建议更新 XRAY 文档：

1. 【变更类型】 变更描述
2. 【变更类型】 变更描述

需要更新的页面：index.html, api-routes.html, database.html

是否更新 XRAY？(y/n)
```

用户确认后才继续。如果不需要更新，输出"本次无架构变更，XRAY 文档无需更新"后结束。

### Phase 2：识别用户身份

检查 `~/.xray_user` 文件：
- 如果存在，读取内容作为操作人昵称
- 如果不存在，询问用户昵称，写入 `~/.xray_user`（纯文本，一行）

### Phase 3：批量收集项目元数据

根据项目类型，生成并执行一段 Bash 脚本，批量收集以下信息（一次性输出，避免逐个文件读取）：

```bash
# 示例收集脚本（Claude 应根据实际项目类型调整）
echo "=== 目录结构 ==="
find . -type f -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/__pycache__/*' -not -path '*/.next/*' | head -500

echo "=== Package 依赖 ==="
cat package.json 2>/dev/null || cat pyproject.toml 2>/dev/null || echo "无包管理文件"

echo "=== API 路由文件 ==="
find . -type f \( -name "route.ts" -o -name "route.js" -o -name "routes.py" -o -name "*.controller.ts" \) -not -path '*/node_modules/*' 2>/dev/null

echo "=== 数据库 Schema/Migration ==="
find . -type f \( -name "*.sql" -o -name "*migration*" -o -name "schema.*" \) -not -path '*/node_modules/*' 2>/dev/null

echo "=== Docker 配置 ==="
cat docker-compose.yml 2>/dev/null; cat Dockerfile 2>/dev/null

echo "=== 环境变量引用 ==="
grep -rh "process\.env\.\|os\.environ\|os\.getenv" --include="*.ts" --include="*.js" --include="*.py" . 2>/dev/null | sort -u | head -100
```

收集完后，对关键文件（路由文件、schema 文件等）用 Read 工具读取具体内容。

### Phase 4：读取现有文档站

如果项目根目录已有 `xray/` 目录，读取相关页面作为基线，进行增量更新。如果没有，全量生成。

### Phase 5：生成/更新文档站

在项目根目录下生成 `xray/` 目录，包含多个独立 HTML 页面。每个页面都是单文件自包含（内联 CSS/JS），共享统一的视觉风格。

#### 文件结构

```
xray/
├── index.html              # 导航首页：项目概览 + 各页面导航卡片
├── modules.html            # 目录结构与模块职责
├── api-routes.html         # API 路由清单（按功能分组）
├── data-flow.html          # 数据流与上下游关系图
├── database.html           # 数据库表结构（字段级详情）
├── deployment.html         # 部署架构（服务器、域名、CI/CD）
├── env-config.html         # 环境变量与配置项
└── integrations.html       # 第三方服务集成
```

#### 各页面内容要求

**index.html（导航首页）：**
- Hero 区域：项目名称、一句话简介
- 项目概览卡片：核心功能列表、技术栈表格、仓库信息
- 导航卡片网格：每个子页面一张卡片，包含标题、简介、状态徽章
- 底部：最后更新时间、变更摘要（最近 3 条，完整见 XRAY-CHANGELOG.md）

**modules.html（目录结构与模块职责）：**
- 用 ASCII 代码块展示完整目录树
- 每个模块/目录的职责说明（表格或卡片）
- 模块间的依赖关系

**api-routes.html（API 路由清单）：**
- 按功能模块分组（Auth、Data、Billing 等）
- 每个路由：方法、路径、说明、认证方式
- 定时任务（Cron）路由单独一节

**data-flow.html（数据流与上下游）：**
- ASCII 架构图展示完整数据流
- 关键业务链路逐条说明（用户请求 → 前端 → API → 上游/DB → 响应）
- 上下游系统清单及交互方式
- 认证流程图

**database.html（数据库表结构）：**
- 每张表：表名、字段、类型、约束、说明
- 表间关系说明
- 多数据库情况下分节展示

**deployment.html（部署架构）：**
- 部署拓扑图（ASCII）
- 各服务部署方式、域名、服务器
- CI/CD 流程（分支策略 → 自动部署）
- 快速操作命令

**env-config.html（环境变量与配置）：**
- 所有环境变量：名称、所属服务、必填/可选、说明
- 按服务/部署环境分组

**integrations.html（第三方服务集成）：**
- 每个外部服务：名称、用途、接入方式、相关文件
- SDK/API Key 配置方式

#### 视觉风格

所有页面共享统一风格（参考 admapix-data 文档站）：

- **配色**：深色主题为主——背景 `#0f172a`，卡片 `#1e293b`，边框 `#334155`，强调色 `#38bdf8`
- **布局**：卡片式，每个主题独立卡片，圆角 `0.75rem`
- **表格**：深色交替行，表头 `#334155`，sticky header
- **代码块**：`#0d1117` 背景，等宽字体，支持 ASCII 架构图
- **字体**：`system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif`
- **导航栏**：顶部 sticky，左侧项目名称，右侧面包屑导航（当前页面位置）
- **导航卡片**：hover 时边框高亮 + 轻微上移，包含标题、描述、状态徽章
- **状态徽章**：绿色（已完成）、蓝色（已实现）、黄色（待完成）
- **响应式**：移动端适配
- **页面间导航**：每个子页面顶部有返回 index 的链接，底部有上一页/下一页导航

#### 增量更新策略

- 只更新受变更影响的页面文件，不需要每次全量重写所有页面
- 在变更摘要中告知用户具体更新了哪些页面
- index.html 的变更历史摘要部分每次都需要更新

### Phase 6：更新 XRAY-CHANGELOG.md

在项目根目录 `XRAY-CHANGELOG.md` 顶部追加（新记录在最前面）。

**时间戳必须使用北京时间（UTC+8）**，通过 `date -u -v+8H '+%Y-%m-%d %H:%M'`（macOS）或 `TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M'` 获取。

```markdown
## [YYYY-MM-DD HH:mm] @昵称
- 【变更类型】 变更描述
- 【变更类型】 变更描述
- 更新页面：xxx.html, xxx.html
```

如果文件不存在则创建，首行加标题 `# XRAY Changelog`。

### Phase 7：完成确认

输出更新完成的提示，包含：
- 更新/新建了哪些页面
- 各页面的主要变更内容
- 提示用户可以用 `open xray/index.html` 在浏览器中查看
