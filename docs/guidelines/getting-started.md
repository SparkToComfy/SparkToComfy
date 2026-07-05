# 快速開始：從 Clone 到啟動

> **上游來源：** 本檔複製自 `SparkToComfy-backend/docs/guidelines/getting-started.md`，是 backend 的**開發**啟動流程（`poetry` / `uvicorn`）。
>
> **容器部署請改看 [../CONFIGURATION.md](../CONFIGURATION.md)**（`docker compose up`）。這裡保留原文供理解後端啟動與健康檢查行為。

這份指南將帶你從零開始完成 SparkToComfy 後端的安裝與設定，直到成功啟動並驗證服務正常運作。

## 前置需求

在開始之前，請確認你的系統已安裝：

- **Python 3.11 或更高版本**
- **Poetry**（Python 依賴管理工具）
- **（可選）ComfyUI**（如果要啟用圖片生成功能）

檢查版本：

```powershell
python --version    # 應顯示 3.11.x 或更高
poetry --version    # 應顯示 Poetry 版本
```

## 安裝步驟

### 1. Clone 專案並安裝依賴

```powershell
# Clone 專案（如果尚未 clone）
git clone <repository-url>
cd SparkToComfy-backend

# 安裝依賴
poetry install
```

Poetry 會建立虛擬環境並安裝所有必要的套件。這個步驟可能需要幾分鐘。

### 2. 複製設定檔範本

後端需要四個設定檔。每個檔案都有一個 `.example` 範本可供參考：

```powershell
# 複製環境變數檔案
Copy-Item .env.example .env

# 複製三個 YAML 設定檔
Copy-Item config/config.yaml.example config/config.yaml
Copy-Item config/providers.yaml.example config/providers.yaml
Copy-Item config/image-options.yaml.example config/image-options.yaml
```

**重要：** `config/workflow.json` 與 `config/prompts/` 目錄下的檔案已經追蹤在版控中，不需要複製。

### 3. 設定環境變數（`.env`）

使用文字編輯器開啟 `.env` 並填入必要的值。

#### 最低需求：至少一個 LLM provider 的 API key

```env
# 至少填入其中一個 provider 的 API key
OPENAI_API_KEY=sk-proj-...
# ANTHROPIC_API_KEY=sk-ant-...
# GCP_API_KEY=...
# NVIDIA_API_KEY=...
# DEEPSEEK_API_KEY=...
```

#### 其他重要變數

```env
# 環境模式（development 啟用 /docs, production 停用）
APP_ENV=development

# ComfyUI 位址（只有啟用 image generation 時才需要）
COMFYUI_BASE_URL=http://127.0.0.1:8188

# CORS 與 WebAuthn 允許的前端來源（啟用 auth 時需要）
# 未設定時，development 預設為 http://localhost:5173
# FRONTEND_ORIGINS=http://localhost:5173
```

完整變數說明請參考 **[environment.md](environment.md)**。

### 4. 調整 YAML 設定（可選）

根據你的需求調整三個 YAML 設定檔。

#### `config/config.yaml` — 主要功能開關

最常見的調整：

```yaml
# 如果不需要使用者驗證，可以停用 auth
auth:
  enabled: false

# 如果不需要圖片生成，可以停用 image_generation
image_generation:
  enabled: false
```

完整欄位說明請參考 **[config.md](config.md)**。

#### `config/providers.yaml` — Provider 與 Model

範本檔案已包含 OpenAI、Gemini、Anthropic、NVIDIA、DeepSeek 的範例設定。

確認至少一個 provider 的設定與你在 `.env` 填入的 API key 對應：

```yaml
providers:
  - name: openai
    env_key: OPENAI_API_KEY    # 對應 .env 中的變數名稱
    base_url: https://api.openai.com
    protocol: openai
    models:
      - id: gpt-4o
        name: GPT-4o
        temperature: 1.0
        timeout: 360
        structured_output:
          mode: openai_chat_json_schema
```

如何新增其他 provider 或 model，請參考 **[providers.md](providers.md)**。

#### `config/image-options.yaml` — 圖片生成選項

如果啟用了 `image_generation`，這個檔案定義前端可選的尺寸、sampler、quality、negative、LoRA 等選項。

範本檔案已包含完整的預設值，通常不需要修改。如何新增 LoRA 或 preset，請參考 **[image-options.md](image-options.md)**。

### 5. 啟動後端

使用 Poetry 執行 Uvicorn：

```powershell
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 --app-dir src
```

參數說明：
- `--reload`：檔案變更時自動重載（開發模式）
- `--host 0.0.0.0`：允許外部連線
- `--port 8000`：監聽埠號
- `--app-dir src`：指定應用程式根目錄

你應該會看到類似以下的輸出：

```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [12345] using WatchFiles
INFO:     Started server process [12346]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

## 驗證

### 1. 健康檢查

```powershell
curl http://localhost:8000/health/live
```

預期回應：
```json
{
  "status": "ok"
}
```

```powershell
curl http://localhost:8000/health/ready
```

預期回應（image generation 停用時）：
```json
{
  "status": "ok",
  "checks": {
    "config_loaded": true,
    "providers_available": true
  }
}
```

如果啟用了 image generation，輸出會包含 `comfyui_online` 檢查。

### 2. 列出可用的 models

```powershell
curl http://localhost:8000/v1/models
```

預期回應：
```json
{
  "models": [
    {
      "id": "gpt-4o",
      "name": "GPT-4o",
      "provider": "openai",
      "thinking_options": null
    }
  ]
}
```

你應該能看到在 `config/providers.yaml` 中設定的所有 models。

### 3. （可選）測試文字生成

如果啟用了 auth，你需要先註冊並登入。如果停用了 auth，可以直接呼叫生成 API：

```powershell
curl -X POST http://localhost:8000/v1/prompts/generate `
  -H "Content-Type: application/json" `
  -H "X-Client-ID: test-client" `
  -H "Idempotency-Key: test-key-001" `
  -d '{
    "model_id": "gpt-4o",
    "input_mode": "quick",
    "identity": "一位女性角色",
    "costume": "白色連衣裙",
    "composition": "站在花園中",
    "count": 1,
    "output_format": "tags+nl"
  }'
```

預期回應：
```json
{
  "id": "gen_...",
  "status": "queued",
  "request": { ... },
  "queue": { ... },
  "created_at": "2026-07-03T...",
  "updated_at": "2026-07-03T..."
}
```

之後可以透過 `GET /v1/prompts/jobs/{job_id}` 查詢結果。

### 4. （可選）測試圖片生成

如果啟用了 `image_generation` 並且 ComfyUI 正在運作：

```powershell
# 先查詢可用的選項
curl http://localhost:8000/v1/images/options

# 提交圖片生成請求
curl -X POST http://localhost:8000/v1/images/generate `
  -H "Content-Type: application/json" `
  -H "X-Client-ID: test-client" `
  -H "Idempotency-Key: test-img-001" `
  -d '{
    "width": 1024,
    "height": 1536,
    "base_model": "anima_base_v10",
    "quality": "masterpiece",
    "positive": "1girl, white dress, standing in garden",
    "negative": "standard",
    "seed": -1,
    "steps": 30,
    "cfg": 4.6,
    "sampler": "dpmpp_3m_sde",
    "scheduler": "sgm_uniform",
    "loras": [],
    "upscale": false
  }'
```

## 最簡範例設定

這是一個可直接使用的最簡設定，適合第一次啟動測試：

### `.env`

```env
APP_ENV=development
OPENAI_API_KEY=sk-proj-你的OpenAI金鑰
```

### `config/config.yaml`

```yaml
auth:
  enabled: false

generation_queue:
  max_pending_jobs: 25
  max_running_jobs: 5
  max_generation_count: 3
  default_provider_concurrency: 2
  runtime_metrics:
    default_generation_seconds: 180
    max_samples_per_bucket: 50

image_generation:
  enabled: false
```

### `config/providers.yaml`

```yaml
rate_limit:
  mode: disabled

providers:
  - name: openai
    env_key: OPENAI_API_KEY
    base_url: https://api.openai.com
    protocol: openai
    models:
      - id: gpt-4o
        name: GPT-4o
        temperature: 1.0
        timeout: 360
        structured_output:
          mode: openai_chat_json_schema
```

### `config/image-options.yaml`

直接使用 `config/image-options.yaml.example` 的內容即可（因為 image_generation 已停用）。

## 常見問題

### 啟動失敗：缺少設定檔

**錯誤訊息：**
```
ConfigFileError: Config file not found: D:\...\config\config.yaml
Copy config/config.yaml.example to config/config.yaml and edit your values.
See docs/guidelines/ for setup guides.
```

**解決方式：** 執行步驟 2 複製設定檔範本。

### 啟動失敗：Provider API key 未設定

**錯誤訊息：**
```
ValueError: Provider 'openai' requires env var OPENAI_API_KEY
```

**解決方式：** 在 `.env` 中填入對應的 API key。

### `/health/ready` 回應 503

**錯誤訊息：**
```json
{
  "status": "unavailable",
  "reason": "comfyui_unavailable"
}
```

**解決方式：**
1. 如果不需要圖片生成，在 `config/config.yaml` 設定 `image_generation.enabled: false`
2. 如果需要圖片生成，確認 ComfyUI 正在運作並且 `.env` 的 `COMFYUI_BASE_URL` 設定正確

### CORS 錯誤（前端連線失敗）

**錯誤訊息：** 瀏覽器 console 顯示 CORS policy blocked

**解決方式：** 在 `.env` 設定 `FRONTEND_ORIGINS`，例如：
```env
FRONTEND_ORIGINS=http://localhost:5173
```


## 下一步

- **[../CONFIGURATION.md](../CONFIGURATION.md)** — 容器部署流程（本 repo 的快速開始）
- **[environment.md](environment.md)** — 環境變數詳細說明
- **[config.md](config.md)** — 調整 auth、queue、image generation 設定
- **[providers.md](providers.md)** — 新增更多 provider 與 model
- backend `docs/SPEC/` — 完整 API 規格與架構文件（開發文件）
