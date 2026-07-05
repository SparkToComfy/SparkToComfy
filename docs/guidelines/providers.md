# providers.yaml 設定教學

> **上游來源：** 本檔複製自 `SparkToComfy-backend/docs/guidelines/providers.md`，欄位語意以 backend 為權威來源；如與後端不一致，以後端為準並回報。部署啟動流程見 [../CONFIGURATION.md](../CONFIGURATION.md)。

這份文件說明 `config/providers.yaml` 的結構、欄位定義、以及如何新增 provider 與 model 的逐步教學。

## 檔案結構

`config/providers.yaml` 包含兩個 top-level sections：

```yaml
rate_limit:        # Request-count quota 模式
  ...

providers:         # LLM providers 與 models
  - name: ...
    ...
```

## `rate_limit` Section

Request-count quota 模式設定。

### 欄位表格

| 欄位 | 類型 | 說明 |
|---|---|---|
| `mode` | string | `global` / `provider` / `model` / `mixed` / `disabled` |
| `global` | object | 當 `mode: global` 時必填 |
| `global.max_requests` | int | 全域 request 數量限制 |
| `global.window_seconds` | int | 全域視窗秒數 |

### Rate Limit 模式說明

| 模式 | 行為 |
|---|---|
| `global` | 所有 requests 共用一個全域限制（需設定 `global` block） |
| `provider` | 每個 provider 獨立計算限制（需在 provider 設定 `rate_limit`） |
| `model` | 每個 model 獨立計算限制（需在 model 設定 `rate_limit`） |
| `mixed` | Provider-level 與 model-level 限制混合使用 |
| `disabled` | 停用 request-count rate limit |

### 範例

#### Global Mode

```yaml
rate_limit:
  mode: global
  global:
    max_requests: 20
    window_seconds: 3600    # 每小時 20 個 requests
```

#### Provider Mode

```yaml
rate_limit:
  mode: provider

providers:
  - name: openai
    rate_limit:
      max_requests: 150
      window_seconds: 86400    # 每天 150 個 requests
```

#### Model Mode

```yaml
rate_limit:
  mode: model

providers:
  - name: openai
    models:
      - id: gpt-4o
        rate_limit:
          max_requests: 50
          window_seconds: 3600    # 每小時 50 個 requests
```

#### Mixed Mode

```yaml
rate_limit:
  mode: mixed

providers:
  - name: openai
    rate_limit:
      max_requests: 150
      window_seconds: 86400
    models:
      - id: gpt-4o
        rate_limit:
          max_requests: 50
          window_seconds: 3600
      - id: gpt-3.5-turbo
        # 此 model 沿用 provider-level 限制
```

#### Disabled Mode

```yaml
rate_limit:
  mode: disabled
```

## `providers` Section

LLM provider 與 model 清單。

### Provider 欄位表格

| 欄位 | 類型 | 必填 | 說明 |
|---|---|---|---|
| `name` | string | ✅ | Provider 識別名稱（全域唯一） |
| `env_key` | string | ✅ | 讀取 API key 的環境變數名稱 |
| `base_url` | string | ✅ | Provider API base URL |
| `protocol` | string | ✅ | `openai` / `openai_compatible` / `anthropic` / `gemini` |
| `streaming` | boolean |  | 是否啟用 upstream streaming（預設 `true`） |
| `rate_limit` | object |  | Provider-level rate limit（當 mode 為 `provider` 或 `mixed` 時） |
| `models` | list | ✅ | Model 清單（至少一個） |

### Model 欄位表格

| 欄位 | 類型 | 必填 | 說明 |
|---|---|---|---|
| `id` | string | ✅ | Model ID（傳給 provider API） |
| `name` | string | ✅ | Model 顯示名稱（前端顯示） |
| `labels` | list |  | Model 標籤（例如 `SFW`, `FAST`）（已不對外暴露） |
| `temperature` | float | ✅ | 預設 temperature |
| `timeout` | int | ✅ | Request timeout（秒） |
| `structured_output` | object | ✅ | Structured output 設定 |
| `structured_output.mode` | string | ✅ | `openai_chat_json_schema` / `openai_responses_json_schema` / `anthropic_tool_schema` / `gemini_response_schema` / `prompt_only` |
| `thinking` | object |  | Thinking/reasoning 設定（可選） |
| `prompt_cache` | object |  | Prompt caching 設定（可選） |
| `token_rate_limit` | object |  | Token quota 設定（可選） |
| `rate_limit` | object |  | Model-level request rate limit（當 mode 為 `model` 或 `mixed` 時） |

### Structured Output Modes

| Mode | 適用 Protocol | 說明 |
|---|---|---|
| `openai_chat_json_schema` | `openai`, `openai_compatible` | OpenAI Chat Completions JSON schema mode |
| `openai_responses_json_schema` | `openai` | OpenAI Responses API JSON schema mode |
| `anthropic_tool_schema` | `anthropic` | Anthropic tool use schema mode |
| `gemini_response_schema` | `gemini` | Gemini response schema mode |
| `prompt_only` | 任何 | 只在 prompt 中提供 schema，不使用 provider-native 功能 |

## 可照做範例

### 範例 1：新增一個 OpenAI Model

新增 `gpt-4-turbo` model 到現有的 `openai` provider：

```yaml
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

      # 新增的 model
      - id: gpt-4-turbo
        name: GPT-4 Turbo
        temperature: 1.0
        timeout: 360
        structured_output:
          mode: openai_chat_json_schema
```

### 範例 2：新增一個 Anthropic Model

新增 `claude-sonnet-4` model 到現有的 `anthropic` provider：

```yaml
providers:
  - name: anthropic
    env_key: ANTHROPIC_API_KEY
    base_url: https://api.anthropic.com
    protocol: anthropic
    models:
      - id: claude-opus-4
        name: Claude Opus 4
        temperature: 1.0
        timeout: 360
        structured_output:
          mode: anthropic_tool_schema
        thinking:
          supported: true
          effort: low

      # 新增的 model
      - id: claude-sonnet-4
        name: Claude Sonnet 4
        temperature: 1.0
        timeout: 360
        structured_output:
          mode: anthropic_tool_schema
```

### 範例 3：新增一個 Gemini Model

新增 `gemini-1.5-pro` model 到現有的 `gemini` provider：

```yaml
providers:
  - name: gemini
    env_key: GCP_API_KEY
    base_url: https://generativelanguage.googleapis.com
    protocol: gemini
    models:
      - id: gemini-2.0-flash-exp
        name: Gemini 2.0 Flash
        temperature: 1.0
        timeout: 360
        structured_output:
          mode: gemini_response_schema

      # 新增的 model
      - id: gemini-1.5-pro
        name: Gemini 1.5 Pro
        temperature: 1.0
        timeout: 360
        structured_output:
          mode: gemini_response_schema
```

### 範例 4：新增一個 OpenAI-Compatible Provider（NVIDIA / DeepSeek / OpenRouter）

#### NVIDIA

```yaml
providers:
  # ... 其他 providers

  - name: nvidia
    env_key: NVIDIA_API_KEY
    base_url: https://integrate.api.nvidia.com
    protocol: openai_compatible
    models:
      - id: nvidia/llama-3.1-nemotron-70b-instruct
        name: Llama 3.1 Nemotron 70B
        temperature: 1.0
        timeout: 360
        structured_output:
          mode: prompt_only
```

**注意：**
1. 在 `.env` 加入 `NVIDIA_API_KEY=你的金鑰`
2. `protocol: openai_compatible` 表示使用 OpenAI-compatible API
3. `structured_output.mode: prompt_only` 表示不使用 provider-native structured output

#### DeepSeek

```yaml
providers:
  # ... 其他 providers

  - name: deepseek
    env_key: DEEPSEEK_API_KEY
    base_url: https://api.deepseek.com
    protocol: openai_compatible
    models:
      - id: deepseek-chat
        name: DeepSeek Chat
        temperature: 1.0
        timeout: 360
        structured_output:
          mode: openai_chat_json_object    # DeepSeek 支援 json_object mode
```

#### OpenRouter

```yaml
providers:
  # ... 其他 providers

  - name: openrouter
    env_key: OPENROUTER_API_KEY
    base_url: https://openrouter.ai/api
    protocol: openai_compatible
    models:
      - id: anthropic/claude-3.5-sonnet
        name: Claude 3.5 Sonnet (OpenRouter)
        temperature: 1.0
        timeout: 360
        structured_output:
          mode: prompt_only
```

### 範例 5：完整的 Provider（包含所有可選欄位）

```yaml
providers:
  - name: openai
    env_key: OPENAI_API_KEY
    base_url: https://api.openai.com
    protocol: openai
    streaming: true    # 啟用 upstream streaming（預設）
    rate_limit:
      max_requests: 150
      window_seconds: 86400
    models:
      - id: gpt-5.4-mini
        name: GPT-5.4 Mini
        labels:
          - SFW
          - FAST
        temperature: 1.0
        timeout: 360
        structured_output:
          mode: openai_chat_json_schema
        thinking:
          supported: true
          options:
            - id: none
              label: None
              provider_payload: {}
            - id: low
              label: Low
              openai:
                reasoning_effort: low
            - id: medium
              label: Medium
              openai:
                reasoning_effort: medium
        prompt_cache:
          enabled: true
          key_strategy: system_prompt_hash
        token_rate_limit:
          max_tokens: 1000000
          window_seconds: 86400
          missing_usage_tokens: 30000
          estimate:
            enabled: true
            chars_per_token: 4.0
            output_tokens_per_generation: 1200
            safety_margin_tokens: 256
```

## Per-Provider Streaming 開關說明

### 什麼是 Streaming？

Streaming 指的是 provider 回傳 generation 結果時，是否使用 delta streaming（逐步回傳內容），而非等待完整結果再一次回傳。

### `streaming` 欄位

```yaml
providers:
  - name: openai
    streaming: true     # 啟用 streaming（預設）
```

- **預設值：** `true`
- **停用 streaming：** 設定 `streaming: false`

**何時停用 streaming？**
- Provider 不支援 streaming
- Provider 的 streaming 有 bug
- 測試環境需要強制使用 non-streaming mode

### 個別 Provider 設定

```yaml
providers:
  - name: openai
    streaming: true    # OpenAI 啟用

  - name: slow-provider
    streaming: false   # 此 provider 停用
```

## Rate Limit 情境範例

### 情境 1：停用所有 Rate Limit

```yaml
rate_limit:
  mode: disabled
```

### 情境 2：Global 限制（所有 requests 共用一個 quota）

```yaml
rate_limit:
  mode: global
  global:
    max_requests: 100
    window_seconds: 3600    # 每小時所有 providers 合計 100 requests
```

### 情境 3：Provider-Level 限制（每個 provider 獨立計算）

```yaml
rate_limit:
  mode: provider

providers:
  - name: openai
    env_key: OPENAI_API_KEY
    base_url: https://api.openai.com
    protocol: openai
    rate_limit:
      max_requests: 150
      window_seconds: 86400    # OpenAI 每天 150 requests
    models:
      - id: gpt-4o
        name: GPT-4o
        temperature: 1.0
        timeout: 360
        structured_output:
          mode: openai_chat_json_schema

  - name: anthropic
    env_key: ANTHROPIC_API_KEY
    base_url: https://api.anthropic.com
    protocol: anthropic
    rate_limit:
      max_requests: 50
      window_seconds: 86400    # Anthropic 每天 50 requests
    models:
      - id: claude-opus-4
        name: Claude Opus 4
        temperature: 1.0
        timeout: 360
        structured_output:
          mode: anthropic_tool_schema
```

### 情境 4：Model-Level 限制（每個 model 獨立計算）

```yaml
rate_limit:
  mode: model

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
        rate_limit:
          max_requests: 30
          window_seconds: 3600    # gpt-4o 每小時 30 requests

      - id: gpt-3.5-turbo
        name: GPT-3.5 Turbo
        temperature: 1.0
        timeout: 360
        structured_output:
          mode: openai_chat_json_schema
        rate_limit:
          max_requests: 100
          window_seconds: 3600    # gpt-3.5-turbo 每小時 100 requests
```

### 情境 5：Mixed 限制（Provider 與 Model 混合）

```yaml
rate_limit:
  mode: mixed

providers:
  - name: openai
    env_key: OPENAI_API_KEY
    base_url: https://api.openai.com
    protocol: openai
    rate_limit:
      max_requests: 150
      window_seconds: 86400    # OpenAI provider 整體每天 150 requests
    models:
      - id: gpt-4o
        name: GPT-4o
        temperature: 1.0
        timeout: 360
        structured_output:
          mode: openai_chat_json_schema
        rate_limit:
          max_requests: 50
          window_seconds: 3600    # gpt-4o 額外限制每小時 50 requests

      - id: gpt-3.5-turbo
        name: GPT-3.5 Turbo
        temperature: 1.0
        timeout: 360
        structured_output:
          mode: openai_chat_json_schema
        # 此 model 只受 provider-level 限制
```

## 所有 YAML 範例使用原生 Block 結構

**✅ 正確：**
```yaml
providers:
  - name: openai
    models:
      - id: gpt-4o
        name: GPT-4o
```

**❌ 錯誤（禁止使用 JSON flow style）：**
```yaml
providers:
  - {name: openai, models: [{id: gpt-4o, name: GPT-4o}]}
```

## 設定檔驗證

後端啟動時會驗證：

1. 檔案必須存在
2. YAML 格式正確
3. 每個 provider 的 `env_key` 對應的環境變數已設定且非空
4. `rate_limit.mode` 為有效值
5. 每個 model 的 `structured_output.mode` 為有效值
6. Protocol 與 structured output mode 相容
7. 未知欄位會被拒絕（`extra="forbid"`）

## 常見錯誤與解決方式

### 錯誤：Provider requires env var

**錯誤訊息：**
```
ValueError: Provider 'openai' requires env var OPENAI_API_KEY
```

**原因：** `env_key` 指定的環境變數未設定或為空。

**解決：** 在 `.env` 加入對應的 API key。

### 錯誤：Unknown structured_output mode

**錯誤訊息：**
```
ValueError: Unknown structured_output mode: invalid_mode
```

**原因：** `structured_output.mode` 使用了不支援的值。

**解決：** 使用有效的 mode（參考上方「Structured Output Modes」表格）。

### 錯誤：Incompatible protocol and mode

**錯誤訊息：**
```
ValueError: Protocol 'gemini' does not support structured_output mode 'openai_chat_json_schema'
```

**原因：** Protocol 與 structured output mode 不相容。

**解決：** 使用對應的 mode（例如 `gemini` protocol 使用 `gemini_response_schema`）。


## 參考連結

- **[../CONFIGURATION.md](../CONFIGURATION.md)** — 部署設定與啟動流程
- **[environment.md](environment.md)** — 環境變數說明（包含 API keys）
- **[config.md](config.md)** — `config.yaml` 欄位參考
- backend `docs/SPEC/specs/API_CONTRACT.md` — API 完整規格（開發文件）
