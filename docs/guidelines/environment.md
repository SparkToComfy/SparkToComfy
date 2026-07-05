# 環境變數完整說明（`.env`）

> **上游來源：** 本檔複製自 `SparkToComfy-backend/docs/guidelines/environment.md`，欄位語意以 backend 為權威來源；如與後端不一致，以後端為準並回報。部署啟動流程見 [../CONFIGURATION.md](../CONFIGURATION.md)。

這份文件說明 SparkToComfy 後端所有可用的環境變數、預設值、以及使用範例。

## 設定方式

環境變數可以透過以下方式設定：

1. **本機開發：** 複製 `.env.example` 為 `.env` 並編輯
2. **Docker 部署：** 在 `docker-compose.yml` 或 `docker run` 指令中設定
3. **系統環境變數：** 直接在 shell 或作業系統設定

**注意：** 如果系統已經設定了某個環境變數，`.env` 檔案中的同名變數**不會覆蓋**系統環境變數。

## 變數清單

### 一般設定

#### `APP_ENV`

- **說明：** 應用程式執行環境模式
- **預設值：** `development`
- **可選值：** `development`, `staging`, `production`
- **影響：**
  - `production` 模式下，FastAPI 的 `/docs`、`/redoc`、`/openapi.json` 路由會被停用
  - `production` 模式下，auth cookies 的 `secure` 旗標行為會更嚴格
  - 其他任何值都視為非 production 環境

**範例：**
```env
APP_ENV=production
```

#### `DEBUG`

- **說明：** 是否啟用除錯模式（影響 log 輸出詳細程度）
- **預設值：** `false`
- **可選值：** `true`, `false`

**範例：**
```env
DEBUG=true
```

#### `LOG_LEVEL`

- **說明：** Log 輸出等級
- **預設值：** `INFO`
- **可選值：** `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`

**範例：**
```env
LOG_LEVEL=DEBUG
```

### 路徑覆寫（可選）

#### `CONFIG_DIR`

- **說明：** 設定檔目錄路徑
- **預設值：** `./config`
- **用途：** 覆寫 `config/config.yaml`、`config/providers.yaml`、`config/image-options.yaml` 等檔案的搜尋路徑

**範例：**
```env
CONFIG_DIR=/etc/sparktocomfy/config
```

#### `DATA_DIR`

- **說明：** 執行時期資料目錄路徑
- **預設值：** `./data`
- **用途：** SQLite 資料庫固定位於 `{DATA_DIR}/database/sparktocomfy.sqlite3`

**範例：**
```env
DATA_DIR=/var/lib/sparktocomfy/data
```

#### `STATIC_DIR`

- **說明：** 靜態前端檔案目錄路徑（可選）
- **預設值：** 未設定（不掛載靜態前端）
- **用途：** 當設定此變數且目錄下包含 `index.html` 時，後端會同時提供：
  - `/v1/*` → API
  - `/health/*` → 健康檢查
  - `/*` → 前端 SPA（fallback 到 `index.html`）

**範例：**
```env
STATIC_DIR=./dist
```

**Docker 範例：**
```env
STATIC_DIR=/workspace/frontend-dist
```

### 前端來源（CORS 與 WebAuthn）

#### `FRONTEND_ORIGINS`

- **說明：** 允許的瀏覽器來源，以逗號分隔，同時控制 CORS 與 WebAuthn（passkeys）允許的 origins
- **預設值：**
  - **未設定時：** development 模式預設為 `http://localhost:5173`，production 模式為 same-origin only
- **用途：** 當啟用 `auth.webauthn` 時，此變數為必填；空值會導致啟動失敗
- **格式：** 逗號分隔的完整 URL（包含協定與埠號）

**重要：** 這是一個特殊的逗號分隔變數，由 pydantic-settings 解析，不需要用引號包裹或跳脫。

**範例：**

本機開發（單一來源）：
```env
FRONTEND_ORIGINS=http://localhost:5173
```

Staging 與 Production（多個來源）：
```env
FRONTEND_ORIGINS=https://app.example.com,https://staging.example.com
```

Docker 開發環境（對應前端容器）：
```env
FRONTEND_ORIGINS=http://localhost:3000
```

### ComfyUI

#### `COMFYUI_BASE_URL`

- **說明：** ComfyUI 實例的基礎 URL
- **預設值：** `http://127.0.0.1:8188`
- **用途：** 後端內部連線使用，瀏覽器**不需要**直接存取此位址（圖片透過後端 proxy 傳送）

**範例：**

本機 ComfyUI：
```env
COMFYUI_BASE_URL=http://127.0.0.1:8188
```

Docker 內部服務：
```env
COMFYUI_BASE_URL=http://comfy_proxy
```

遠端 ComfyUI：
```env
COMFYUI_BASE_URL=https://comfyui.example.com
```

### LLM Provider API Keys

每個在 `config/providers.yaml` 設定的 provider 都會讀取其 `env_key` 指定的環境變數。

#### `OPENAI_API_KEY`

- **說明：** OpenAI API 金鑰
- **用途：** 對應 `providers.yaml` 中 `env_key: OPENAI_API_KEY` 的 provider
- **格式：** `sk-proj-...` 或 `sk-...`

**範例：**
```env
OPENAI_API_KEY=sk-proj-abc123...
```

#### `ANTHROPIC_API_KEY`

- **說明：** Anthropic API 金鑰
- **用途：** 對應 `providers.yaml` 中 `env_key: ANTHROPIC_API_KEY` 的 provider
- **格式：** `sk-ant-...`

**範例：**
```env
ANTHROPIC_API_KEY=sk-ant-api03-xyz789...
```

#### `GCP_API_KEY`

- **說明：** Google Cloud Platform API 金鑰（用於 Gemini models）
- **用途：** 對應 `providers.yaml` 中 `env_key: GCP_API_KEY` 的 provider

**範例：**
```env
GCP_API_KEY=AIzaSy...
```

#### `NVIDIA_API_KEY`

- **說明：** NVIDIA API 金鑰
- **用途：** 對應 `providers.yaml` 中 `env_key: NVIDIA_API_KEY` 的 provider

**範例：**
```env
NVIDIA_API_KEY=nvapi-...
```

#### `DEEPSEEK_API_KEY`

- **說明：** DeepSeek API 金鑰
- **用途：** 對應 `providers.yaml` 中 `env_key: DEEPSEEK_API_KEY` 的 provider

**範例：**
```env
DEEPSEEK_API_KEY=sk-...
```

#### `OPENROUTER_API_KEY`

- **說明：** OpenRouter API 金鑰
- **用途：** 對應 `providers.yaml` 中 `env_key: OPENROUTER_API_KEY` 的 provider

**範例：**
```env
OPENROUTER_API_KEY=sk-or-v1-...
```

**注意：** 你可以定義自己的環境變數名稱，只要在 `providers.yaml` 的 `env_key` 中指定相同的名稱即可。

## 完整範例

### 開發環境（Development）

```env
# ============================================
# SparkToComfy - Development Environment
# ============================================

APP_ENV=development
DEBUG=true
LOG_LEVEL=DEBUG

# 前端來源（本機 Vite dev server）
FRONTEND_ORIGINS=http://localhost:5173

# ComfyUI（本機）
COMFYUI_BASE_URL=http://127.0.0.1:8188

# LLM Providers
OPENAI_API_KEY=sk-proj-abc123...
ANTHROPIC_API_KEY=sk-ant-api03-xyz789...
GCP_API_KEY=AIzaSy...

# 其他 providers（未使用可留空）
# NVIDIA_API_KEY=
# DEEPSEEK_API_KEY=
# OPENROUTER_API_KEY=
```

### 生產環境（Production）

```env
# ============================================
# SparkToComfy - Production Environment
# ============================================

APP_ENV=production
DEBUG=false
LOG_LEVEL=INFO

# 前端來源（production domain）
FRONTEND_ORIGINS=https://app.example.com

# ComfyUI（Docker 內部服務，透過 Cloudflare Access）
COMFYUI_BASE_URL=http://comfy_proxy

# 路徑覆寫（Docker 掛載）
CONFIG_DIR=/config
DATA_DIR=/data
STATIC_DIR=/workspace/frontend-dist

# LLM Providers
OPENAI_API_KEY=sk-proj-prod...
ANTHROPIC_API_KEY=sk-ant-api03-prod...
GCP_API_KEY=AIzaSy...prod
NVIDIA_API_KEY=nvapi-prod...
DEEPSEEK_API_KEY=sk-prod...
```

### Staging 環境（Staging）

```env
# ============================================
# SparkToComfy - Staging Environment
# ============================================

APP_ENV=staging
DEBUG=false
LOG_LEVEL=INFO

# 前端來源（staging domain）
FRONTEND_ORIGINS=https://staging.example.com

# ComfyUI（staging 實例）
COMFYUI_BASE_URL=http://comfy-staging

# LLM Providers（使用與 production 相同或獨立的金鑰）
OPENAI_API_KEY=sk-proj-staging...
ANTHROPIC_API_KEY=sk-ant-api03-staging...
GCP_API_KEY=AIzaSy...staging
```

## 逗號分隔變數解析行為

### `FRONTEND_ORIGINS`

這個變數使用 pydantic-settings 的 `NoDecode` 模式解析逗號分隔清單：

**單一來源：**
```env
FRONTEND_ORIGINS=http://localhost:5173
```
解析為：`["http://localhost:5173"]`

**多個來源：**
```env
FRONTEND_ORIGINS=https://app.example.com,https://staging.example.com
```
解析為：`["https://app.example.com", "https://staging.example.com"]`

**空白會被自動去除：**
```env
FRONTEND_ORIGINS=http://localhost:5173, http://localhost:3000
```
解析為：`["http://localhost:5173", "http://localhost:3000"]`

**不要用引號包裹整個字串：**
```env
# ❌ 錯誤
FRONTEND_ORIGINS="https://app.example.com,https://staging.example.com"

# ✅ 正確
FRONTEND_ORIGINS=https://app.example.com,https://staging.example.com
```

## 常見情境

### 停用 Auth 與 Image Generation（最簡設定）

只需要文字生成功能，不需要使用者驗證與圖片生成：

```env
APP_ENV=development
OPENAI_API_KEY=sk-proj-...
```

然後在 `config/config.yaml` 設定：
```yaml
auth:
  enabled: false

image_generation:
  enabled: false
```

### 啟用 Auth 但停用 Image Generation

需要使用者驗證，但不需要圖片生成：

```env
APP_ENV=development
FRONTEND_ORIGINS=http://localhost:5173
OPENAI_API_KEY=sk-proj-...
```

然後在 `config/config.yaml` 設定：
```yaml
auth:
  enabled: true
  webauthn:
    enabled: true

image_generation:
  enabled: false
```

### 完整啟用所有功能

啟用 Auth、WebAuthn、Image Generation：

```env
APP_ENV=development
FRONTEND_ORIGINS=http://localhost:5173
COMFYUI_BASE_URL=http://127.0.0.1:8188
OPENAI_API_KEY=sk-proj-...
ANTHROPIC_API_KEY=sk-ant-...
```

然後在 `config/config.yaml` 確認：
```yaml
auth:
  enabled: true
  webauthn:
    enabled: true

image_generation:
  enabled: true
```

### 調整 ComfyUI Timeout（長時間生成）

如果圖片生成需要更長時間（例如超過 5 分鐘）：

`.env` 保持預設：
```env
COMFYUI_BASE_URL=http://127.0.0.1:8188
```

然後在 `config/config.yaml` 調整：
```yaml
image_generation:
  enabled: true
  timeout_seconds: 600    # 改為 10 分鐘
```

### Docker 部署範例

`docker-compose.yml`：
```yaml
version: '3.8'
services:
  app:
    image: ghcr.io/sparktocomfy/app:latest
    environment:
      - APP_ENV=production
      - FRONTEND_ORIGINS=https://app.example.com
      - COMFYUI_BASE_URL=http://comfy_proxy
      - CONFIG_DIR=/config
      - DATA_DIR=/data
      - STATIC_DIR=/workspace/frontend-dist
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
    volumes:
      - ./config:/config:ro
      - ./data:/data
```

宿主機的 `.env`（給 docker-compose 使用）：
```env
OPENAI_API_KEY=sk-proj-...
ANTHROPIC_API_KEY=sk-ant-...
```

## 疑難排解

### 錯誤：Provider requires env var

**錯誤訊息：**
```
ValueError: Provider 'openai' requires env var OPENAI_API_KEY
```

**原因：** `config/providers.yaml` 中定義了 provider，但對應的環境變數未設定或為空。

**解決：** 在 `.env` 填入對應的 API key，或從 `providers.yaml` 移除該 provider。

### 錯誤：Auth enabled with empty origins

**錯誤訊息：**
```
ValueError: Auth with WebAuthn enabled requires FRONTEND_ORIGINS to be set
```

**原因：** 啟用了 `auth.webauthn` 但 `FRONTEND_ORIGINS` 未設定或解析為空清單。

**解決：** 在 `.env` 設定 `FRONTEND_ORIGINS`。

### 錯誤：ComfyUI unavailable

**錯誤訊息（`/health/ready` 回應 503）：**
```json
{
  "status": "unavailable",
  "reason": "comfyui_unavailable"
}
```

**原因：** `image_generation.enabled: true` 但後端無法連線到 `COMFYUI_BASE_URL`。

**解決：**
1. 確認 ComfyUI 正在運作
2. 檢查 `COMFYUI_BASE_URL` 設定是否正確
3. 如果不需要圖片生成，在 `config/config.yaml` 設定 `image_generation.enabled: false`

### CORS 錯誤

**錯誤訊息（瀏覽器 console）：**
```
Access to fetch at 'http://localhost:8000/v1/...' from origin 'http://localhost:5173' has been blocked by CORS policy
```

**原因：** 前端來源未包含在 `FRONTEND_ORIGINS` 中。

**解決：** 在 `.env` 加入前端 URL：
```env
FRONTEND_ORIGINS=http://localhost:5173
```


## 參考連結

- **[../CONFIGURATION.md](../CONFIGURATION.md)** — 部署設定與啟動流程
- **[config.md](config.md)** — `config.yaml` 欄位參考
- **[providers.md](providers.md)** — Provider 設定教學
