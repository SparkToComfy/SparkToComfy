# config.yaml 欄位參考與常見調整

> **上游來源：** 本檔複製自 `SparkToComfy-backend/docs/guidelines/config.md`，欄位語意以 backend 為權威來源；如與後端不一致，以後端為準並回報。部署啟動流程見 [../CONFIGURATION.md](../CONFIGURATION.md)。

這份文件說明 `config/config.yaml` 的所有欄位、預設值、以及常見調整情境。

## 檔案結構

`config/config.yaml` 包含三個 top-level sections：

```yaml
auth:              # 本機使用者驗證
  ...

generation_queue:  # 文字生成 queue 限制與 ETA metrics
  ...

image_generation:  # ComfyUI 圖片生成閘道
  ...
```

## `auth` Section

本機後端擁有的使用者驗證，invite codes 控制註冊。

### 欄位表格

| 欄位 | 類型 | 預設值 | 說明 |
|---|---|---|---|
| `enabled` | boolean | `true` | 是否啟用 auth（停用時所有受保護路由變為公開） |
| `cookie_name` | string | `sparktocomfy_session` | Session cookie 名稱 |
| `cookie_secure` | string | `auto` | Cookie `Secure` 旗標（`auto` / `true` / `false`） |
| `cookie_samesite` | string | `lax` | Cookie `SameSite` 設定（`lax` / `strict` / `none`） |
| `access_token_ttl_seconds` | int | `900` | Access token 有效期限（15 分鐘） |
| `session_ttl_seconds` | int | `2592000` | Session 有效期限（30 天） |
| `password.min_length` | int | `12` | 密碼最小長度 |
| `password.max_length` | int | `256` | 密碼最大長度 |
| `password.hash_algorithm` | string | `argon2id` | 密碼雜湊演算法（目前僅支援 `argon2id`） |
| `login_rate_limit.max_attempts` | int | `5` | 登入失敗次數限制（單一 username） |
| `login_rate_limit.window_seconds` | int | `300` | 登入 rate limit 視窗（5 分鐘） |
| `webauthn.enabled` | boolean | `true` | 是否啟用 WebAuthn (passkeys) |
| `webauthn.rp_id` | string | `localhost` | WebAuthn Relying Party ID（通常是 domain） |
| `webauthn.rp_name` | string | `SparkToComfy` | WebAuthn Relying Party 顯示名稱 |
| `webauthn.challenge_ttl_seconds` | int | `300` | WebAuthn challenge 有效期限（5 分鐘） |
| `webauthn.timeout_ms` | int | `60000` | WebAuthn 操作逾時（60 秒） |

### 完整範例

```yaml
auth:
  enabled: true
  cookie_name: sparktocomfy_session
  cookie_secure: auto
  cookie_samesite: lax
  access_token_ttl_seconds: 900
  session_ttl_seconds: 2592000
  password:
    min_length: 12
    max_length: 256
    hash_algorithm: argon2id
  login_rate_limit:
    max_attempts: 5
    window_seconds: 300
  webauthn:
    enabled: true
    rp_id: localhost
    rp_name: SparkToComfy
    challenge_ttl_seconds: 300
    timeout_ms: 60000
```

### 常見調整情境

#### 停用 Auth（開發/測試環境）

```yaml
auth:
  enabled: false
```

停用後，所有受保護的路由（`/v1/prompts/generate`、`/v1/images/generate` 等）不再需要 session cookie，`X-Client-ID` 成為 owner scope 的來源。

#### 調整密碼強度要求

```yaml
auth:
  enabled: true
  password:
    min_length: 16    # 改為 16 字元
    max_length: 256
```

#### 延長 Session 有效期限（記住我功能）

```yaml
auth:
  enabled: true
  session_ttl_seconds: 7776000    # 改為 90 天
```

#### 停用 WebAuthn（只允許密碼登入）

```yaml
auth:
  enabled: true
  webauthn:
    enabled: false
```

#### 調整 WebAuthn Relying Party ID（Production）

```yaml
auth:
  enabled: true
  webauthn:
    enabled: true
    rp_id: app.example.com    # 改為 production domain
    rp_name: SparkToComfy
```

**注意：** `rp_id` 必須與 `.env` 的 `FRONTEND_ORIGINS` 中的 domain 一致。

#### 加嚴登入 Rate Limit

```yaml
auth:
  enabled: true
  login_rate_limit:
    max_attempts: 3           # 改為 3 次
    window_seconds: 600       # 改為 10 分鐘
```

## `generation_queue` Section

文字生成 queue 限制、prompt count 上限、以及 ETA metrics 設定。

### 欄位表格

| 欄位 | 類型 | 預設值 | 說明 |
|---|---|---|---|
| `max_pending_jobs` | int | `25` | Pending queue 最大容量（超過回傳 `QUEUE_FULL` 503） |
| `max_running_jobs` | int | `5` | 同時執行的 job 數量上限 |
| `max_generation_count` | int | `3` | 單次請求可要求的生成數量上限（schema 絕對上限為 5） |
| `default_provider_concurrency` | int | `2` | 預設每個 provider 的並行數量 |
| `provider_concurrency` | map | `{}` | 個別 provider 的並行數量覆寫 |
| `runtime_metrics.default_generation_seconds` | int | `180` | ETA 預設每次生成耗時（3 分鐘） |
| `runtime_metrics.max_samples_per_bucket` | int | `50` | ETA metrics 每個 bucket 保留的樣本數上限 |

### 完整範例

```yaml
generation_queue:
  max_pending_jobs: 25
  max_running_jobs: 5
  max_generation_count: 3
  default_provider_concurrency: 2
  provider_concurrency:
    openai: 2
    anthropic: 2
  runtime_metrics:
    default_generation_seconds: 180
    max_samples_per_bucket: 50
```

### 常見調整情境

#### 調整文字生成 Queue 上限

高流量環境可以提高 pending queue 容量：

```yaml
generation_queue:
  max_pending_jobs: 100     # 改為 100
  max_running_jobs: 10      # 改為 10
```

#### 限制單次生成數量

降低資源消耗：

```yaml
generation_queue:
  max_generation_count: 1   # 改為 1（每次請求只能生成 1 個）
```

#### 調整特定 Provider 的並行數量

```yaml
generation_queue:
  default_provider_concurrency: 2
  provider_concurrency:
    openai: 5               # OpenAI 允許 5 個並行
    anthropic: 1            # Anthropic 限制為 1 個
    gemini: 3               # Gemini 允許 3 個並行
```

#### 調整 ETA 預設估計值

```yaml
generation_queue:
  runtime_metrics:
    default_generation_seconds: 120    # 改為 2 分鐘
```

## `image_generation` Section

ComfyUI 圖片生成閘道。**預設停用**；自動化測試不需要 ComfyUI runtime。

### 欄位表格

| 欄位 | 類型 | 預設值 | 說明 |
|---|---|---|---|
| `enabled` | boolean | `false` | 是否啟用圖片生成功能 |
| `client_id` | string | `sparktocomfy-backend` | ComfyUI client ID（用於 WebSocket 訂閱） |
| `timeout_seconds` | int | `300` | 圖片生成總逾時（5 分鐘） |
| `health_timeout_seconds` | float | `2.0` | ComfyUI 健康檢查逾時 |
| `health_poll_interval_seconds` | float | `5.0` | ComfyUI 健康檢查輪詢間隔 |
| `poll_interval_seconds` | float | `1.0` | ComfyUI 執行狀態輪詢間隔 |
| `max_poll_attempts` | int | `300` | 最大輪詢次數（配合 `poll_interval_seconds`） |
| `preview_max_bytes` | int | `2000000` | Preview 圖片最大 bytes（2 MB） |
| `finished_ttl_seconds` | int | `1800` | 完成的 image job 記錄保留時間（30 分鐘） |
| `outputs.sub_folder` | string | `API` | ComfyUI 輸出 subfolder |
| `outputs.filename` | string | `%date:yyyy-MM-dd-hh-mm-ss%_%model%-%seed%` | ComfyUI 檔案名稱 prefix（支援 ComfyUI tokens） |
| `workflow.nodes.*` | string | 各 node ID | ComfyUI workflow 中各 role 的 node ID 對應 |
| `workflow.upscale.*` | list | 各 source | Upscale routing 的 source 設定 |

### 完整範例

```yaml
image_generation:
  enabled: false
  client_id: sparktocomfy-backend
  timeout_seconds: 300
  health_timeout_seconds: 2.0
  health_poll_interval_seconds: 5.0
  poll_interval_seconds: 1.0
  max_poll_attempts: 300
  preview_max_bytes: 2000000
  finished_ttl_seconds: 1800
  outputs:
    sub_folder: API
    filename: "%date:yyyy-MM-dd-hh-mm-ss%_%model%-%seed%"
  workflow:
    nodes:
      size: "20736"
      base_model: "20735:6196"
      lora_loader: "20737"
      lora_trigger: "20738"
      quality_prompt: "20739"
      positive_prompt: "20740"
      negative_prompt: "20741"
      sampler: "20742"
      save_image: "20745"
      output_switch: "20753"
    upscale:
      disabled_source:
        - "20743"
        - 0
      enabled_source:
        - "20752"
        - 0
```

### 常見調整情境

#### 啟用圖片生成

```yaml
image_generation:
  enabled: true
```

**注意：** 啟用前需確認：
1. `.env` 已設定 `COMFYUI_BASE_URL`
2. ComfyUI 正在運作並可連線
3. `config/workflow.json` 存在且與 `workflow.nodes` 對應

#### 停用圖片生成（測試環境）

```yaml
image_generation:
  enabled: false
```

停用後，`/health/ready` 不會檢查 ComfyUI 連線。

#### 調整 ComfyUI Timeout（長時間生成）

```yaml
image_generation:
  enabled: true
  timeout_seconds: 600           # 改為 10 分鐘
  max_poll_attempts: 600         # 配合增加輪詢次數
```

#### 調整完成 Job 的保留時間

```yaml
image_generation:
  enabled: true
  finished_ttl_seconds: 3600     # 改為 1 小時
```

#### 調整 ComfyUI 輸出路徑

```yaml
image_generation:
  enabled: true
  outputs:
    sub_folder: MY_OUTPUT         # 改為自訂 subfolder
    filename: "img_%seed%"        # 改為自訂檔名格式
```

**注意：** `sub_folder` 必須與 ComfyUI 的輸出設定一致，且前端 view proxy 只接受此 subfolder 值。

#### 調整 Workflow Node Mapping（使用不同的 Workflow）

當你使用自己的 ComfyUI workflow 時，需要更新 node ID 對應：

```yaml
image_generation:
  enabled: true
  workflow:
    nodes:
      size: "12345"                  # 改為你的 size node ID
      base_model: "12346:6196"       # 改為你的 base_model node ID 與 input index
      lora_loader: "12347"           # 改為你的 LoRA loader node ID
      # ... 其他 nodes
```

**重要：** 每個 node ID 必須對應到 `config/workflow.json` 中存在的 node。

#### 停用 Upscale 支援

如果你的 workflow 不支援 upscale routing：

移除或註解 `workflow.upscale` 區塊（或保持原樣但前端不會看到 `upscale_available: true`）。

後端會在啟動時驗證 `output_switch` 與 sources 是否存在；如果 workflow 中缺少對應 node，啟動會失敗。

### 相關檔案

- ComfyUI 位址設定在 `.env` 的 `COMFYUI_BASE_URL`
- Workflow prompt 固定讀取 `config/workflow.json`（追蹤版控）
- Public image options 設定在 `config/image-options.yaml`
- `image_generation.workflow` 只放 node mapping 與 upscale routing

## 設定檔驗證

後端啟動時會驗證：

1. 檔案必須存在（缺少檔案會大聲報錯）
2. YAML 格式正確
3. 所有欄位符合 Pydantic schema（`MainFileConfig`）
4. 未知欄位會被拒絕（`extra="forbid"`）
5. Image generation 啟用時，workflow nodes 必須在 `config/workflow.json` 中存在

## 完整最簡設定範例

只啟用文字生成，停用 auth 與 image generation：

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


## 參考連結

- **[../CONFIGURATION.md](../CONFIGURATION.md)** — 部署設定與啟動流程
- **[environment.md](environment.md)** — 環境變數說明
- **[image-options.md](image-options.md)** — 圖片選項設定
- **[providers.md](providers.md)** — Provider 設定教學
- backend `docs/SPEC/specs/API_CONTRACT.md` — API 完整規格（開發文件）
