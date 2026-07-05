# image-options.yaml 設定教學

> **上游來源：** 本檔複製自 `SparkToComfy-backend/docs/guidelines/image-options.md`，欄位語意以 backend 為權威來源；如與後端不一致，以後端為準並回報。部署啟動流程見 [../CONFIGURATION.md](../CONFIGURATION.md)。

這份文件說明 `config/image-options.yaml` 的結構、欄位定義、以及如何新增 LoRA、quality preset、negative preset 等選項的逐步教學。

## 檔案結構

`config/image-options.yaml` 包含一個 top-level section：

```yaml
image_options:
  size:           # 尺寸控制（寬高、步進）
    ...
  sampling:       # 採樣控制（steps、cfg、sampler、scheduler）
    ...
  base_models:    # 基礎模型選項
    ...
  quality:        # Quality prompt presets
    ...
  negative:       # Negative prompt presets
    ...
  loras:          # LoRA 選項
    ...
```

這個檔案定義了**所有前端可選的圖片生成選項**，包括尺寸界限、預設值、sampler/scheduler 清單、quality/negative presets、以及 LoRA 清單。

## `size` Section

圖片尺寸控制。

### 欄位表格

| 欄位 | 類型 | 說明 |
|---|---|---|
| `default_width` | int | 預設寬度 |
| `min_width` | int | 最小寬度 |
| `max_width` | int | 最大寬度 |
| `width_step` | int | 寬度步進（必須是此值的倍數） |
| `default_height` | int | 預設高度 |
| `min_height` | int | 最小高度 |
| `max_height` | int | 最大高度 |
| `height_step` | int | 高度步進（必須是此值的倍數） |

### 範例

```yaml
image_options:
  size:
    default_width: 1024
    min_width: 512
    max_width: 2560
    width_step: 8
    default_height: 1536
    min_height: 512
    max_height: 2560
    height_step: 8
```

### 常見調整

#### 調整尺寸界限

```yaml
size:
  default_width: 1024
  min_width: 256        # 改為 256
  max_width: 4096       # 改為 4096
  width_step: 8
```

#### 改變預設尺寸

```yaml
size:
  default_width: 768    # 改為 768
  default_height: 1024  # 改為 1024
```

## `sampling` Section

採樣參數控制。

### 欄位表格

| 欄位 | 類型 | 說明 |
|---|---|---|
| `default_steps` | int | 預設 steps |
| `min_steps` | int | 最小 steps |
| `max_steps` | int | 最大 steps |
| `default_cfg` | float | 預設 CFG scale |
| `min_cfg` | float | 最小 CFG scale |
| `max_cfg` | float | 最大 CFG scale |
| `cfg_step` | float | CFG 步進（必須是此值的倍數） |
| `default_sampler_name` | string | 預設 sampler |
| `default_scheduler` | string | 預設 scheduler |
| `samplers` | list | 可選的 sampler 清單 |
| `schedulers` | list | 可選的 scheduler 清單 |

### 範例

```yaml
image_options:
  sampling:
    default_steps: 30
    min_steps: 0
    max_steps: 50
    default_cfg: 4.6
    min_cfg: 0.0
    max_cfg: 7.0
    cfg_step: 0.1
    default_sampler_name: dpmpp_3m_sde
    default_scheduler: sgm_uniform
    samplers:
      - dpmpp_2m_sde
      - dpmpp_3m_sde
      - exp_heun_2_x0_sde
    schedulers:
      - simple
      - normal
      - beta
      - sgm_uniform
      - karras
```

### 常見調整

#### 調整預設 Sampler 與 Scheduler

```yaml
sampling:
  default_sampler_name: dpmpp_2m_sde    # 改為 dpmpp_2m_sde
  default_scheduler: karras             # 改為 karras
```

#### 調整 Steps 界限

```yaml
sampling:
  default_steps: 20       # 改為 20
  min_steps: 10           # 改為 10
  max_steps: 100          # 改為 100
```

#### 新增其他 Sampler 選項

```yaml
sampling:
  samplers:
    - dpmpp_2m_sde
    - dpmpp_3m_sde
    - exp_heun_2_x0_sde
    - euler               # 新增
    - euler_a             # 新增
```

## `base_models` Section

基礎模型選項。前端使用 `id`，後端將 `value`（ComfyUI UNET 檔名）寫入 workflow。

### 欄位表格

| 欄位 | 類型 | 說明 |
|---|---|---|
| `id` | string | 前端選項 ID（唯一） |
| `label` | string | 前端顯示名稱 |
| `value` | string | ComfyUI UNET 檔名（`.safetensors` 完整檔名） |

### 範例

```yaml
image_options:
  base_models:
    - id: anima_base_v10
      label: Anima Base V10
      value: anima_baseV10.safetensors
```

### 新增一個 Base Model

```yaml
image_options:
  base_models:
    - id: anima_base_v10
      label: Anima Base V10
      value: anima_baseV10.safetensors

    # 新增的 base model
    - id: my_custom_model
      label: My Custom Model
      value: my_custom_model.safetensors
```

**注意：**
1. `id` 必須唯一
2. `value` 必須是 ComfyUI 實際載入的 UNET 檔名（包含 `.safetensors`）
3. 需要 `config/config.yaml` 中設定 `image_generation.workflow.nodes.base_model`

## `quality` Section

Quality prompt presets。

### 欄位表格

| 欄位 | 類型 | 說明 |
|---|---|---|
| `default` | string | 預設選項 ID |
| `options` | list | Quality preset 清單 |
| `options[].id` | string | Preset ID（唯一） |
| `options[].label` | string | 前端顯示名稱 |
| `options[].value` | string | 實際 prompt 文字 |

### 範例

```yaml
image_options:
  quality:
    default: masterpiece
    options:
      - id: masterpiece
        label: Masterpiece
        value: "masterpiece, best quality, very aesthetic, ultra-detailed, score_9, score_8, score_7,"
      - id: balanced
        label: Balanced
        value: "best quality, high detail, clean linework"
      - id: soft_detail
        label: Soft Detail
        value: "best quality, soft lighting, detailed textures, refined composition"
```

### 可照做範例

#### 範例 1：新增一個 Quality Preset

```yaml
quality:
  default: masterpiece
  options:
    - id: masterpiece
      label: Masterpiece
      value: "masterpiece, best quality, very aesthetic, ultra-detailed, score_9, score_8, score_7,"
    - id: balanced
      label: Balanced
      value: "best quality, high detail, clean linework"
    - id: soft_detail
      label: Soft Detail
      value: "best quality, soft lighting, detailed textures, refined composition"

    # 新增的 preset
    - id: cinematic
      label: Cinematic
      value: "cinematic lighting, dramatic composition, professional photography, best quality"
```

#### 範例 2：修改預設 Quality

```yaml
quality:
  default: balanced    # 改為 balanced
  options:
    - id: masterpiece
      label: Masterpiece
      value: "masterpiece, best quality, very aesthetic, ultra-detailed, score_9, score_8, score_7,"
    - id: balanced
      label: Balanced
      value: "best quality, high detail, clean linework"
```

## `negative` Section

Negative prompt presets。

### 欄位表格

| 欄位 | 類型 | 說明 |
|---|---|---|
| `default` | string | 預設選項 ID |
| `options` | list | Negative preset 清單 |
| `options[].id` | string | Preset ID（唯一） |
| `options[].label` | string | 前端顯示名稱 |
| `options[].value` | string | 實際 negative prompt 文字 |

### 範例

```yaml
image_options:
  negative:
    default: standard
    options:
      - id: standard
        label: Standard
        value: "worst quality, low quality, score_1, score_2, score_3"
      - id: strict_quality
        label: Strict Quality
        value: "worst quality, low quality, score_1, score_2, score_3, bad anatomy, bad hands, blurry"
      - id: minimal
        label: Minimal
        value: "worst quality, low quality"
```

### 可照做範例

#### 範例 2：新增一個 Negative Preset

```yaml
negative:
  default: standard
  options:
    - id: standard
      label: Standard
      value: "worst quality, low quality, score_1, score_2, score_3"
    - id: strict_quality
      label: Strict Quality
      value: "worst quality, low quality, score_1, score_2, score_3, bad anatomy, bad hands, blurry"
    - id: minimal
      label: Minimal
      value: "worst quality, low quality"

    # 新增的 preset
    - id: ultra_strict
      label: Ultra Strict
      value: "worst quality, low quality, score_1, score_2, score_3, bad anatomy, bad hands, blurry, watermark, signature, text, lowres, jpeg artifacts"
```

#### 範例 3：修改預設 Negative

```yaml
negative:
  default: strict_quality    # 改為 strict_quality
  options:
    - id: standard
      label: Standard
      value: "worst quality, low quality, score_1, score_2, score_3"
    - id: strict_quality
      label: Strict Quality
      value: "worst quality, low quality, score_1, score_2, score_3, bad anatomy, bad hands, blurry"
```

## `loras` Section

LoRA 選項。

### 欄位表格

| 欄位 | 類型 | 說明 |
|---|---|---|
| `id` | string | 前端選項 ID（唯一） |
| `label` | string | 前端顯示名稱 |
| `name` | string | 後端專用 ComfyUI LoRA runtime 名稱（不對外暴露） |
| `default_weight` | float | 預設 weight（strength） |
| `min_weight` | float | 最小 weight |
| `max_weight` | float | 最大 weight |
| `step` | float | Weight 步進 |
| `clipStrength` | float | CLIP strength（固定值） |
| `trigger_words` | list | LoRA trigger words 清單 |

### 範例

```yaml
image_options:
  loras:
    - id: ps_gpt2_style_v1
      label: Ps GPT2 style v1
      name: Ps_gpt2-style_v1_epoch25
      default_weight: 1.0
      min_weight: 0.0
      max_weight: 2.0
      step: 0.05
      clipStrength: 1.0
      trigger_words:
        - "@gpt2"

    - id: ps_gpt2_style_v2
      label: Ps GPT2 style v2
      name: Ps_gpt2-style_v2-petite_epoch22
      default_weight: 1.0
      min_weight: 0.0
      max_weight: 2.0
      step: 0.05
      clipStrength: 1.0
      trigger_words:
        - "@gpt2"
```

### 可照做範例

#### 範例 4：新增一個 LoRA

完整步驟：

1. 確認 ComfyUI 已載入該 LoRA（在 ComfyUI `models/loras/` 目錄下）
2. 在 `image-options.yaml` 的 `loras` 清單中新增一個項目：

```yaml
loras:
  - id: ps_gpt2_style_v1
    label: Ps GPT2 style v1
    name: Ps_gpt2-style_v1_epoch25
    default_weight: 1.0
    min_weight: 0.0
    max_weight: 2.0
    step: 0.05
    clipStrength: 1.0
    trigger_words:
      - "@gpt2"

  # 新增的 LoRA
  - id: my_custom_lora
    label: My Custom LoRA
    name: my_custom_lora_v1        # ComfyUI 載入的 LoRA 名稱（不含 .safetensors）
    default_weight: 0.8
    min_weight: 0.0
    max_weight: 1.5
    step: 0.05
    clipStrength: 1.0
    trigger_words:
      - "custom_trigger"
      - "another_trigger"
```

**注意：**
1. `id`：前端選項 ID（必須唯一）
2. `label`：前端顯示名稱
3. `name`：ComfyUI LoRA runtime 名稱（不含 `.safetensors`，必須與 ComfyUI 中的名稱一致）
4. `trigger_words`：當使用此 LoRA 時，後端會自動將 trigger words 加入 prompt（需要 `config/config.yaml` 設定 `image_generation.workflow.nodes.lora_trigger`）

#### 範例 5：調整 LoRA Weight 界限

```yaml
loras:
  - id: ps_gpt2_style_v1
    label: Ps GPT2 style v1
    name: Ps_gpt2-style_v1_epoch25
    default_weight: 0.8        # 改為 0.8
    min_weight: 0.0
    max_weight: 1.5            # 改為 1.5
    step: 0.1                  # 改為 0.1
    clipStrength: 1.0
    trigger_words:
      - "@gpt2"
```

#### 範例 6：LoRA 無 Trigger Words

```yaml
loras:
  - id: style_lora_no_trigger
    label: Style LoRA (No Trigger)
    name: style_lora_no_trigger
    default_weight: 1.0
    min_weight: 0.0
    max_weight: 2.0
    step: 0.05
    clipStrength: 1.0
    trigger_words: []          # 空清單，不注入 trigger words
```

## 完整範例檔案

```yaml
# config/image-options.yaml.example - public image generation options

image_options:
  size:
    default_width: 1024
    min_width: 512
    max_width: 2560
    width_step: 8
    default_height: 1536
    min_height: 512
    max_height: 2560
    height_step: 8

  sampling:
    default_steps: 30
    min_steps: 0
    max_steps: 50
    default_cfg: 4.6
    min_cfg: 0.0
    max_cfg: 7.0
    cfg_step: 0.1
    default_sampler_name: dpmpp_3m_sde
    default_scheduler: sgm_uniform
    samplers:
      - dpmpp_2m_sde
      - dpmpp_3m_sde
      - exp_heun_2_x0_sde
    schedulers:
      - simple
      - normal
      - beta
      - sgm_uniform
      - karras

  base_models:
    - id: anima_base_v10
      label: Anima Base V10
      value: anima_baseV10.safetensors

  quality:
    default: masterpiece
    options:
      - id: masterpiece
        label: Masterpiece
        value: "masterpiece, best quality, very aesthetic, ultra-detailed, score_9, score_8, score_7,"
      - id: balanced
        label: Balanced
        value: "best quality, high detail, clean linework"
      - id: soft_detail
        label: Soft Detail
        value: "best quality, soft lighting, detailed textures, refined composition"

  negative:
    default: standard
    options:
      - id: standard
        label: Standard
        value: "worst quality, low quality, score_1, score_2, score_3"
      - id: strict_quality
        label: Strict Quality
        value: "worst quality, low quality, score_1, score_2, score_3, bad anatomy, bad hands, blurry"
      - id: minimal
        label: Minimal
        value: "worst quality, low quality"

  loras:
    - id: ps_gpt2_style_v1
      label: Ps GPT2 style v1
      name: Ps_gpt2-style_v1_epoch25
      default_weight: 1.0
      min_weight: 0.0
      max_weight: 2.0
      step: 0.05
      clipStrength: 1.0
      trigger_words:
        - "@gpt2"

    - id: ps_gpt2_style_v2
      label: Ps GPT2 style v2
      name: Ps_gpt2-style_v2-petite_epoch22
      default_weight: 1.0
      min_weight: 0.0
      max_weight: 2.0
      step: 0.05
      clipStrength: 1.0
      trigger_words:
        - "@gpt2"
```

## 所有 YAML 範例使用原生 Block 結構

**✅ 正確：**
```yaml
loras:
  - id: my_lora
    label: My LoRA
    trigger_words:
      - "trigger1"
      - "trigger2"
```

**❌ 錯誤（禁止使用 JSON flow style）：**
```yaml
loras:
  - {id: my_lora, label: My LoRA, trigger_words: ["trigger1", "trigger2"]}
```

## 設定檔驗證

後端啟動時會驗證：

1. 檔案必須存在
2. YAML 格式正確
3. 所有必填欄位存在
4. ID 唯一性（`base_models[].id`, `quality.options[].id`, `negative.options[].id`, `loras[].id`）
5. 預設值（`quality.default`, `negative.default`）必須存在於對應的 `options[].id` 中
6. 數值界限合理（`min_*` <= `default_*` <= `max_*`）
7. 未知欄位會被拒絕（`extra="forbid"`）

## 與 config.yaml 的關聯

### Workflow Node Mapping

`image-options.yaml` 定義的選項需要 `config/config.yaml` 中對應的 workflow nodes：

| image-options 欄位 | 需要的 config.yaml node |
|---|---|
| `base_models` | `image_generation.workflow.nodes.base_model` |
| `quality` | `image_generation.workflow.nodes.quality_prompt` |
| `loras` | `image_generation.workflow.nodes.lora_loader` |
| `loras[].trigger_words` | `image_generation.workflow.nodes.lora_trigger` |

如果 `image-options.yaml` 定義了選項但 `config.yaml` 缺少對應的 node，啟動時會報錯。

## 常見錯誤與解決方式

### 錯誤：Default quality/negative not found

**錯誤訊息：**
```
ValueError: quality.default 'invalid_id' not found in quality.options
```

**原因：** `default` 指定的 ID 在 `options` 清單中不存在。

**解決：** 確認 `default` 值是某個 `options[].id` 的值。

### 錯誤：Duplicate ID

**錯誤訊息：**
```
ValueError: Duplicate lora id: 'my_lora'
```

**原因：** 同一個 section 中有重複的 `id`。

**解決：** 確保所有 `id` 唯一。

### 錯誤：LoRA name not found in ComfyUI

這不是啟動錯誤，而是**執行時期錯誤**（當實際提交圖片生成請求時）。

**錯誤訊息：**
```
ImageGenerationError: ComfyUI LoRA not found: 'invalid_lora_name'
```

**原因：** `loras[].name` 指定的 LoRA 在 ComfyUI 中不存在。

**解決：** 確認 ComfyUI `models/loras/` 目錄下存在對應的 `.safetensors` 檔案，且 `name` 欄位不含副檔名。


## 參考連結

- **[../CONFIGURATION.md](../CONFIGURATION.md)** — 部署設定與啟動流程
- **[config.md](config.md)** — `config.yaml` 欄位參考（包含 workflow nodes）
- backend `docs/SPEC/specs/GENERATION.md` — 圖片生成完整規格（開發文件）
