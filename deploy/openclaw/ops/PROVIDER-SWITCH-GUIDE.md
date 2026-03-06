# OpenClaw Provider 切换指南

## 快速使用

### 1. 查看当前配置和可用选项
```powershell
cd D:\openclaw\deploy\openclaw\ops
.\switch-provider.ps1
```

### 2. 切换 Provider
```powershell
# 切换到 FuCheers Key1，使用 claude-sonnet-4-6-thinking
.\switch-provider.ps1 self claude-sonnet-4-6-thinking

# 切换到 FuCheers Key2，使用 claude-opus-4-6
.\switch-provider.ps1 self2 claude-opus-4-6

# 切换到 CodeFlow，使用 claude-sonnet-4-6
.\switch-provider.ps1 codeflow claude-sonnet-4-6

# 使用默认模型（不指定模型名称）
.\switch-provider.ps1 self      # 默认使用 claude-sonnet-4-6-thinking
.\switch-provider.ps1 codeflow  # 默认使用 claude-sonnet-4-6
```

## 手动修改配置

如果你想手动修改配置，编辑这个文件：
```
D:\openclaw\deploy\openclaw\volumes\openclaw\config\openclaw.json
```

### 需要修改的部分

找到 `agents.defaults.model` 部分：

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "self/claude-sonnet-4-6-thinking",
        "fallbacks": [
          "self2/claude-sonnet-4-6-thinking",
          "self/claude-sonnet-4-6",
          "self2/claude-sonnet-4-6"
        ]
      }
    }
  }
}
```

### 修改说明

1. **primary**: 主要使用的模型，格式为 `provider/model-id`
   - 例如: `"self/claude-opus-4-6"`
   - 例如: `"codeflow/claude-sonnet-4-6"`

2. **fallbacks**: 备用模型列表，当主模型失败时按顺序尝试
   - 数组格式，可以有多个备用模型
   - 建议配置不同 provider 的模型作为备用

### 配置示例

#### 示例 1: 使用 FuCheers Key1 作为主要 provider
```json
"model": {
  "primary": "self/claude-sonnet-4-6-thinking",
  "fallbacks": [
    "self2/claude-sonnet-4-6-thinking",
    "codeflow/claude-sonnet-4-6",
    "codeflow/claude-opus-4-6"
  ]
}
```

#### 示例 2: 使用 CodeFlow 作为主要 provider
```json
"model": {
  "primary": "codeflow/claude-sonnet-4-6",
  "fallbacks": [
    "codeflow/claude-opus-4-6",
    "self/claude-sonnet-4-6-thinking",
    "self2/claude-sonnet-4-6-thinking"
  ]
}
```

#### 示例 3: 使用 FuCheers Key2 作为主要 provider
```json
"model": {
  "primary": "self2/claude-opus-4-6",
  "fallbacks": [
    "self/claude-opus-4-6",
    "codeflow/claude-opus-4-6",
    "codeflow/claude-sonnet-4-6"
  ]
}
```

## 重要提示

1. **修改配置后必须重启 OpenClaw**
   ```powershell
   docker restart openclaw-gateway
   ```

2. **配置文件格式**
   - 必须是有效的 JSON 格式
   - 注意逗号、引号、括号的正确使用
   - 建议使用脚本修改，避免手动编辑出错

3. **备份配置**
   - 脚本会自动备份配置文件
   - 手动修改前建议先备份：
     ```powershell
     copy D:\openclaw\deploy\openclaw\volumes\openclaw\config\openclaw.json D:\openclaw\deploy\openclaw\volumes\openclaw\config\openclaw.json.backup
     ```

4. **查看日志**
   - 切换后可以查看日志确认是否生效：
     ```powershell
     docker logs openclaw-gateway --tail 50
     ```
   - 查找类似这样的日志：
     ```
     [gateway] agent model: codeflow/claude-sonnet-4-6
     ```

## Provider 和模型对照表

### FuCheers (self/self2)
- API 端点: https://www.fucheers.top/v1
- 支持的模型:
  - `claude-opus-4-6` - 最强大的模型
  - `claude-haiku-4-5-20251001` - 最快速的模型
  - `claude-sonnet-4-6-thinking` - 带思考链的 Sonnet（推荐）
  - `claude-sonnet-4-6` - 标准 Sonnet

### CodeFlow (codeflow)
- API 端点: https://codeflow.asia
- 支持的模型:
  - `claude-haiku-4-5-20251001` - 最快速的模型
  - `claude-sonnet-4-5-20250929` - Sonnet 4.5
  - `claude-opus-4-5-20251101` - Opus 4.5
  - `claude-opus-4-6` - Opus 4.6
  - `claude-sonnet-4-6` - Sonnet 4.6（推荐）

### 共通模型（三个 provider 都支持）
- `claude-haiku-4-5-20251001`
- `claude-opus-4-6`
- `claude-sonnet-4-6`

## 故障排查

### 问题 1: 切换后仍然使用旧的 provider
**解决方法**: 确保重启了 OpenClaw 容器
```powershell
docker restart openclaw-gateway
```

### 问题 2: 配置文件格式错误
**解决方法**: 恢复备份文件
```powershell
# 查看备份文件
ls D:\openclaw\deploy\openclaw\volumes\openclaw\config\openclaw.json.backup*

# 恢复最新的备份
copy D:\openclaw\deploy\openclaw\volumes\openclaw\config\openclaw.json.backup.20260301-143000 D:\openclaw\deploy\openclaw\volumes\openclaw\config\openclaw.json
```

### 问题 3: Provider 不可用（503 错误）
**解决方法**: 切换到其他可用的 provider
```powershell
# 如果 FuCheers 维修中，切换到 CodeFlow
.\switch-provider.ps1 codeflow claude-sonnet-4-6
```

### 问题 4: 模型不支持
**错误信息**: `No available channel for model xxx`
**解决方法**: 检查该 provider 是否支持该模型，参考上面的对照表
