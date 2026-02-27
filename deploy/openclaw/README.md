# OpenClaw 长期运行方案（Win11 + Docker Desktop + WSL2）

本目录采用 OpenClaw 官方 Docker 架构：

- `openclaw-gateway`：常驻服务（长期运行）
- `openclaw-cli`：按需执行命令（onboard、dashboard、channels 等）

说明：当前官方 Docker 方案不依赖 Postgres/Redis，状态和会话主要落在 `~/.openclaw`（本模板映射到 `./volumes/openclaw/*`），更接近官方路径，也更易迁移到云主机。

## 1) 前置检查（Win11）

```powershell
wsl --status
wsl -l -v
docker version
docker compose version
docker info
```

确认：

- Docker Desktop 已启用 `Use the WSL 2 based engine`
- 目标发行版为 WSL2
- Docker Engine 正常

## 2) 初始化配置与目录

```powershell
cd d:\openclaw\deploy\openclaw
Copy-Item .env.example .env
```

生成并写入一个 token（PowerShell）：

```powershell
$token = -join ((48..57 + 97..102) | Get-Random -Count 64 | % {[char]$_})
(Get-Content .env) -replace "OPENCLAW_GATEWAY_TOKEN=replace_with_64_hex_token", "OPENCLAW_GATEWAY_TOKEN=$token" | Set-Content .env
```

创建挂载目录：

```powershell
New-Item -ItemType Directory -Force -Path .\volumes\openclaw\config | Out-Null
New-Item -ItemType Directory -Force -Path .\volumes\openclaw\workspace | Out-Null
New-Item -ItemType Directory -Force -Path .\volumes\openclaw\logs | Out-Null
```

## 3) 启动（镜像方式）

默认使用 `ghcr.io/openclaw/openclaw:main`：

```powershell
docker compose pull
docker compose up -d openclaw-gateway
docker compose ps
```

首次引导（交互）：

```powershell
docker compose run --rm openclaw-cli onboard --no-install-daemon
```

获取 Dashboard URL（不自动开浏览器）：

```powershell
docker compose run --rm openclaw-cli dashboard --no-open
```

健康检查：

```powershell
docker compose exec openclaw-gateway node dist/index.js health --token "$env:OPENCLAW_GATEWAY_TOKEN"
```

看日志：

```powershell
docker compose logs -f --tail=200 openclaw-gateway
```

## 4) 本地构建（可选）

如果你要从源码构建而不是拉远程镜像：

```powershell
docker build -t openclaw:local -f ..\..\Dockerfile ..\..
```

然后把 `.env` 的 `OPENCLAW_IMAGE=openclaw:local`，再执行：

```powershell
docker compose up -d openclaw-gateway
```

## 5) 停止/重启

```powershell
docker compose down
docker compose up -d openclaw-gateway
```

## 6) 常见故障排查

- 端口冲突：`netstat -ano | findstr :18789`（同理 `18790`）
- 防火墙：默认仅监听 `127.0.0.1`，若改成局域网访问再放行规则
- 代理拉镜像失败：设置 `.env` 中 `HTTP_PROXY/HTTPS_PROXY/NO_PROXY`
- 容器 DNS：`docker exec -it openclaw-gateway sh` 后测试 `nslookup`
- Windows 路径与权限：避免 OneDrive 目录；使用本模板相对挂载路径
- 睡眠/休眠中断：接电场景关闭自动睡眠，避免长任务被暂停

## 7) GPU 可选段（默认不启用）

OpenClaw 网关本身通常 CPU 即可。仅在你明确有 GPU 推理插件/工具链时再启用。

新建 `docker-compose.gpu.yml`：

```yaml
services:
  openclaw-gateway:
    gpus: all
    environment:
      NVIDIA_VISIBLE_DEVICES: all
      NVIDIA_DRIVER_CAPABILITIES: compute,utility
```

启动：

```powershell
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d openclaw-gateway
```

Windows + WSL2 需先验证：

```powershell
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

## 8) 保守并发与带宽估算

- 并发建议：先保持单实例网关；需要并行抓取时，优先在 OpenClaw 侧把任务并发从 1 增到 2，再观察 24h
- 资源红线：CPU 持续 > 70% 或内存 > 85% 超过 10 分钟，就回退并发
- 硬盘规则：保留可用空间至少 80GB；每周执行一次 `docker system df`
- 带宽估算：
  - 实时带宽（Mbps）约等于 `平均响应大小MB * 每秒请求数 * 8 * 重试系数(1.2~1.5)`
  - 月流量（GB）约等于 `平均响应大小MB * 每秒请求数 * 3600 * 每日小时 * 30 * 重试系数 / 1024`

