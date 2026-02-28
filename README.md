# OpenClaw 本地部署仓库（Windows + Docker）

在 Windows + Docker Desktop 上运行 OpenClaw AI 网关的完整部署模板。

## 架构概览

```
  Windows 主机
  ╔══════════════════════════════════════════════════════════╗
  ║  Docker Desktop (WSL2)                                   ║
  ║                                                          ║
  ║  ┌───────────────────────┐    ┌────────────────────┐    ║
  ║  │   openclaw-gateway    │    │   openclaw-cli     │    ║
  ║  │                       │    │                    │    ║
  ║  │  18789 ── Web UI      │    │   交互式 CLI       │    ║
  ║  │  18790 ── Bridge      │    │   （按需启动）      │    ║
  ║  │  18792 ── Browser     │    └────────────────────┘    ║
  ║  └──────────┬────────────┘                              ║
  ║             │ 绑定 127.0.0.1（仅本机可访问）              ║
  ╚═════════════╪══════════════════════════════════════════╝
                │
         本机浏览器
    http://127.0.0.1:18789

  挂载卷
  ├── ./volumes/openclaw/config     AI 配置 & 运行时状态
  ├── ./volumes/openclaw/workspace  AI 工作区（记忆 / 技能）
  ├── ${PROJECTS_DIR}               项目目录
  └── ${DESKTOP_DIR}                桌面目录
```

## 目录结构

```
openclaw/
├── deploy/openclaw/            # OpenClaw 网关部署（主体）
│   ├── docker-compose.yml      # 服务编排
│   ├── Dockerfile              # 自定义镜像（基于官方镜像扩展工具链）
│   ├── entrypoint.sh           # 启动注入脚本（从环境变量写入配置）
│   ├── .env.example            # 环境变量模板（复制为 .env 后填写）
│   ├── .env                    # 本地环境变量（不提交 Git）
│   ├── ops/                    # 运维脚本
│   │   ├── start.ps1           # 启动网关
│   │   ├── stop.ps1            # 停止网关
│   │   ├── status.ps1          # 查看容器状态
│   │   ├── logs.ps1            # 查看日志
│   │   └── dashboard.ps1       # 打开控制台
│   └── volumes/                # 运行时数据（不提交 Git）
│       ├── openclaw/config/    # openclaw.json、模型/会话配置
│       └── openclaw/workspace/ # AI 工作区（记忆、技能、日记）
│
├── compose.yaml                # 可选：定时任务模板（Redis + Worker）
├── config/tasks.yaml           # Worker 任务配置
├── services/worker/            # Worker 服务源码（Python）
├── skills/                     # 全局技能（通过 clawhub 安装）
├── ops/                        # 根目录运维脚本
├── .gitignore
└── README.md
```

## 前置要求

| 软件 | 版本 | 说明 |
|------|------|------|
| Windows | 10 / 11 | WSL2 需已启用 |
| Docker Desktop | 4.x+ | 启用 WSL2 backend |
| PowerShell | 5.1+ | 运维脚本依赖 |

验证环境：

```powershell
wsl --status
docker version
docker compose version
```

## 快速开始

### 1. 克隆仓库

```powershell
git clone https://github.com/AI-Wallfacer/Open_Claw_windows.git
cd openclaw
```

### 2. 配置环境变量

```powershell
cd deploy\openclaw
Copy-Item .env.example .env
```

编辑 `.env`，填写以下必填项：

```ini
# Gateway 访问令牌（自行生成一个随机 hex 串）
OPENCLAW_GATEWAY_TOKEN=your_64_hex_token_here

# 自定义 API 中转地址和密钥
SELF_API_URL=https://your-api-proxy.example.com/v1
SELF_API_KEY=sk-your-api-key

# 飞书机器人（可选，不用飞书留空即可）
FEISHU_APP_ID=cli_xxxx
FEISHU_APP_SECRET=your_secret

# 本机目录挂载（按实际路径填写）
PROJECTS_DIR=D:/your/projects
DESKTOP_DIR=C:/Users/YourName/Desktop
```

### 3. 启动

```powershell
.\ops\start.ps1
```

脚本会自动：
- 创建 `volumes/` 目录结构
- 拉取最新镜像
- 构建自定义镜像（包含工具链扩展）
- 启动 `openclaw-gateway` 容器

### 4. 访问

浏览器打开：[http://127.0.0.1:18789](http://127.0.0.1:18789)

使用 `.env` 中配置的 `OPENCLAW_GATEWAY_TOKEN` 登录。

## 自定义镜像（Dockerfile）

基于官方 `ghcr.io/openclaw/openclaw:main` 镜像，额外集成：

| 工具 | 用途 |
|------|------|
| `jq` | JSON 处理（entrypoint 注入配置依赖） |
| `vim` / `less` | 容器内文本编辑与查看 |
| `ffmpeg` | 音视频处理 |
| `ripgrep` | 高速文本搜索 |
| `gh`（GitHub CLI）| Git 操作 |
| `python3` + `openpyxl` + `pandas` | Office 文档处理 |
| `clawhub` | 技能市场命令行工具 |
| `summarize` | 内容总结工具 |

## 配置注入机制（entrypoint.sh）

为避免敏感凭据硬编码在 JSON 配置文件中，容器启动时 `entrypoint.sh` 会自动将环境变量注入到运行时配置：

```
.env 环境变量
    ↓ docker-compose 传入容器
    ↓ entrypoint.sh 用 jq 写入
openclaw.json / models.json / auth.json
    ↓
openclaw-gateway 进程启动
```

注入的字段：

| 环境变量 | 注入目标 |
|----------|----------|
| `SELF_API_KEY` / `SELF_API_URL` | `openclaw.json` 模型提供商 + `models.json` + `auth.json` |
| `FEISHU_APP_ID` / `FEISHU_APP_SECRET` | `openclaw.json` 飞书渠道配置 |
| `OPENCLAW_GATEWAY_TOKEN` | `openclaw.json` 网关认证 token |

## 运维命令

```powershell
# 在 deploy/openclaw 目录下执行

.\ops\start.ps1      # 启动网关
.\ops\stop.ps1       # 停止网关
.\ops\status.ps1     # 查看容器状态
.\ops\logs.ps1       # 查看实时日志
.\ops\dashboard.ps1  # 打开 Web 控制台

# 重建镜像（Dockerfile 有变更时）
docker compose build --no-cache
docker compose up -d
```

## 默认端口

| 端口 | 服务 | 说明 |
|------|------|------|
| `127.0.0.1:18789` | Web UI / API | 控制台 & OpenAI 兼容接口 |
| `127.0.0.1:18790` | Bridge | Cursor / IDE 桥接 |
| `127.0.0.1:18792` | Browser Relay | 浏览器控制中继 |

所有端口仅绑定 `127.0.0.1`，不对局域网暴露。

## 模型配置

模型配置存放于 `volumes/openclaw/config/openclaw.json`（运行时生成，不提交 Git）。  
初次启动后通过 Web UI 的"设置 → 模型"进行配置，或参考以下结构手动编辑：

```json
{
  "models": {
    "providers": {
      "self": {
        "baseUrl": "${SELF_API_URL}",
        "apiKey": "${SELF_API_KEY}",
        "api": "openai-completions",
        "models": [
          { "id": "claude-sonnet-4-6-thinking", "reasoning": true,  "maxTokens": 65536 },
          { "id": "claude-opus-4-6",            "reasoning": true,  "maxTokens": 65536 },
          { "id": "claude-sonnet-4-6",          "reasoning": false, "maxTokens": 32768 },
          { "id": "claude-haiku-4-5-20251001",  "reasoning": false, "maxTokens": 8192  }
        ]
      }
    }
  }
}
```

## 可选：定时任务模板（根目录 compose.yaml）

根目录提供一个独立的 `Redis + Worker` 定时任务模板，与 OpenClaw 完全解耦。

```powershell
# 在根目录 openclaw/ 下执行
Copy-Item .env.example .env
.\ops\start.ps1
.\ops\logs.ps1 -Service worker
```

任务配置：`config/tasks.yaml`

```yaml
tasks:
  - name: my-task
    command: 'python -c "print(\"hello\")"'
    timeout_seconds: 30
```

Worker 每隔 `LOOP_INTERVAL_SECONDS`（默认 60s）轮询执行所有任务，将结果写入 `runtime/state/heartbeat.json`。

## 安全说明

- `.env` 文件含真实密钥，已通过 `.gitignore` 排除，**禁止提交**
- `volumes/` 含 AI 运行时数据（记忆、会话、凭据），已排除，**禁止提交**
- 所有端口绑定 `127.0.0.1`，仅本机可访问
- Gateway 使用 token 认证，飞书渠道限定指定用户 ID

## 常见问题

**`gateway token missing`**  
检查 `.env` 中 `OPENCLAW_GATEWAY_TOKEN` 是否已填写，重启容器生效。

**`503 No available channel for model xxx`**  
API 中转服务没有该模型的可用通道，检查 `SELF_API_URL` / `SELF_API_KEY` 是否正确，或联系中转服务提供方确认模型名称。

**Browser Relay 状态显示 `!`**  
先确认 `openclaw-gateway` 状态为 healthy，再检查浏览器扩展中的 token 是否与 `.env` 一致。

**模型切换后仍使用旧模型**  
会话存在 `modelOverride` 缓存，需开启新会话或重启 gateway 容器。

**重建镜像后 entrypoint.sh 权限问题**  
确保 `entrypoint.sh` 已转换为 LF 换行符（非 CRLF），否则容器内执行报错。

## 许可

本仓库为个人本地部署模板，敏感配置和运行时数据始终保留在本地，不进入版本库。
