# prompts.yaml 結構說明與新增 Prompt Module 的方法

> **上游來源：** 本檔複製自 `SparkToComfy-backend/docs/guidelines/prompts.md`。
>
> **部署端限制：** 你可以修改既有 `config/prompts/` 的內容（例如 `modules/*.md` 文字、`prompts.yaml` 的 `order`）後重新掛載；但**新增** prompt module 需在 backend 修改 `PromptOptions` 並重新 build app image。本檔中的 `poetry` 與 `src/app/...` 步驟屬 backend 開發流程，部署端無法直接執行。

這份文件說明 `config/prompts/prompts.yaml` 的結構、命名慣例、以及如何新增一個 prompt module 的完整步驟。

## Prompt Assembly 概述

SparkToComfy 的文字生成使用**平鋪式 prompt assembly**：

1. **`prompts.yaml`** 定義組裝順序（`order`）與 module 註冊表（`modules`）
2. **Builtin 欄位**（`detailed_input`, `identity`, `costume`, `composition`, `count`）根據 input mode 條件渲染
3. **Module 片段**（`modules/*.md`）根據命名慣例啟用，注入到最終 user message 中
4. **零隱式規則**：order 由上到下 = 最終組裝順序，啟用判定走命名慣例

## 檔案結構

```
config/prompts/
  prompts.yaml       ← 組裝順序與 module 註冊表
  system.md          ← System prompt
  output_schema.json ← 輸出 JSON schema
  fewshot/
    examples.json    ← Few-shot 範例
  modules/
    multi_character.md
    fashion_clothing.md
    cultural_costume.md
    ... 其他 modules
```

## `prompts.yaml` 結構

```yaml
# Assembly order (top-to-bottom = final user message order)
order:
  - multi_character
  - fashion_clothing
  - detailed_input
  - identity
  - costume
  - composition
  - count
  - per_prompt_self_check

# Module registry (id: snippet_path)
modules:
  multi_character: modules/multi_character.md
  fashion_clothing: modules/fashion_clothing.md
  per_prompt_self_check: modules/per_prompt_self_check.md
```

### `order` Section

**純 ID 清單**，由上到下定義最終 user message 的組裝順序。

#### 五個 Builtin IDs

這五個 builtin ID **必須各出現一次**：

| Builtin ID | 對應欄位 | Label | 渲染模式 |
|---|---|---|---|
| `detailed_input` | `detailed_input` | 詳細描述 | 只在 detailed mode 渲染 |
| `identity` | `identity` | 主體身分 | 只在 quick mode 渲染 |
| `costume` | `costume` | 服裝設計 | 只在 quick mode 渲染 |
| `composition` | `composition` | 整體構圖 | 只在 quick mode 渲染 |
| `count` | `count` | 生成數量 | 兩種 mode 都渲染 |

#### Module IDs

所有其他 IDs 必須：

1. 在 `modules` section 中有對應的註冊項
2. 可對應到 `PromptOptions` 中的欄位（透過命名慣例）

### `modules` Section

**平鋪的 `id: snippet_path` 映射**，無巢狀結構。

- `id`：module 識別名稱（對應 `order` 中的 ID）
- `snippet_path`：相對於 `config/prompts/` 的檔案路徑

**範例：**
```yaml
modules:
  multi_character: modules/multi_character.md
  fashion_clothing: modules/fashion_clothing.md
```

## 命名慣例與啟用邏輯

Module 啟用使用**命名慣例**，自動對應到 `PromptOptions`（定義在 `src/app/schemas/generate.py`）：

### 規則 1：Boolean 欄位

**ID 與 `PromptOptions` boolean 欄位名稱相同 → 當該欄位為 `true` 時啟用**

**範例：**

`PromptOptions`:
```python
class PromptOptions(BaseModel):
    multi_character: bool = False
    fashion_clothing: bool = False
```

`order`:
```yaml
order:
  - multi_character      # 啟用條件：prompt_options.multi_character == true
  - fashion_clothing     # 啟用條件：prompt_options.fashion_clothing == true
```

### 規則 2：Enum 欄位（visual_emphasis）

**ID 格式為 `visual_emphasis_<值>` → 當 `visual_emphasis` 等於 `<值>` 時啟用**

**範例：**

`PromptOptions`:
```python
class PromptOptions(BaseModel):
    visual_emphasis: Literal[
        "none",
        "character_and_outfit",
        "background_environment",
    ] = "none"
```

`order`:
```yaml
order:
  - visual_emphasis_character_and_outfit      # 啟用條件：visual_emphasis == "character_and_outfit"
  - visual_emphasis_background_environment    # 啟用條件：visual_emphasis == "background_environment"
```

**注意：** `visual_emphasis_none` 不需要定義（`none` 表示不啟用任何 emphasis module）。

### 規則 3：無法對應 → 啟動錯誤

如果 `order` 中的 module ID（非 builtin）無法對應到 `PromptOptions` 欄位，**啟動時會報錯**。

這個驗證機制防止 typo 與死 modules。

## 完整範例

### `prompts.yaml`

```yaml
# Prompt Assembly Layout for SparkToComfy

order:
  - multi_character
  - fashion_clothing
  - cultural_costume
  - character_creativity
  - nsfw_techniques
  - character_detailing
  - detailed_input                           # Builtin: detailed mode
  - identity                                 # Builtin: quick mode
  - costume                                  # Builtin: quick mode
  - composition                              # Builtin: quick mode
  - visual_emphasis_character_and_outfit
  - visual_emphasis_background_environment
  - image_narrative
  - lighting_mood
  - color_play
  - scene_logic
  - count                                    # Builtin: both modes
  - per_prompt_self_check

modules:
  multi_character: modules/multi_character.md
  fashion_clothing: modules/fashion_clothing.md
  cultural_costume: modules/cultural_costume.md
  character_creativity: modules/character_creativity.md
  nsfw_techniques: modules/nsfw_techniques.md
  character_detailing: modules/character_detailing.md
  visual_emphasis_character_and_outfit: modules/visual_emphasis_character_and_outfit.md
  visual_emphasis_background_environment: modules/visual_emphasis_background_environment.md
  image_narrative: modules/image_narrative.md
  lighting_mood: modules/lighting_mood.md
  color_play: modules/color_play.md
  scene_logic: modules/scene_logic.md
  per_prompt_self_check: modules/per_prompt_self_check.md
```

### 對應的 `PromptOptions`

```python
class PromptOptions(BaseModel):
    multi_character: bool = False
    fashion_clothing: bool = False
    cultural_costume: bool = False
    character_creativity: bool = False
    nsfw_techniques: bool = False
    image_narrative: bool = False
    lighting_mood: bool = False
    color_play: bool = False
    character_detailing: bool = False
    scene_logic: bool = False
    per_prompt_self_check: bool = False
    visual_emphasis: Literal[
        "none",
        "character_and_outfit",
        "background_environment",
    ] = "none"
```

## 可照做範例：新增一個 Prompt Module

假設我們要新增一個「背景複雜度」module，讓使用者可以要求更詳細的背景描述。

### 步驟 1：撰寫 Module 片段

建立 `config/prompts/modules/background_complexity.md`：

```markdown
背景複雜度：描述背景時，提供豐富的環境細節，包括場景元素、空間深度、與氛圍營造。
```

### 步驟 2：在 `prompts.yaml` 的 `order` 中插入 Module ID

決定這個 module 應該出現在哪個位置。通常背景相關的 module 會放在 composition 附近。

```yaml
order:
  - multi_character
  - fashion_clothing
  - detailed_input
  - identity
  - costume
  - composition
  - background_complexity         # ← 新增在這裡
  - visual_emphasis_character_and_outfit
  - visual_emphasis_background_environment
  - count
  - per_prompt_self_check
```

### 步驟 3：在 `prompts.yaml` 的 `modules` 中註冊

```yaml
modules:
  multi_character: modules/multi_character.md
  fashion_clothing: modules/fashion_clothing.md
  # ... 其他 modules
  background_complexity: modules/background_complexity.md    # ← 新增這一行
```

### 步驟 4：在 `PromptOptions` 中加入對應欄位

編輯 `src/app/schemas/generate.py`：

```python
class PromptOptions(BaseModel):
    multi_character: bool = False
    fashion_clothing: bool = False
    cultural_costume: bool = False
    character_creativity: bool = False
    nsfw_techniques: bool = False
    image_narrative: bool = False
    lighting_mood: bool = False
    color_play: bool = False
    character_detailing: bool = False
    scene_logic: bool = False
    per_prompt_self_check: bool = False
    background_complexity: bool = False    # ← 新增這一行
    visual_emphasis: Literal[
        "none",
        "character_and_outfit",
        "background_environment",
    ] = "none"
```

### 步驟 5：啟動驗證

```powershell
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 --app-dir src
```

後端會在啟動時驗證：

1. `order` 中的每個 ID 都在 `modules` 中有對應項（除了 5 個 builtins）
2. `modules` 中的每個 ID 都在 `order` 中被引用
3. 每個 module ID 可以對應到 `PromptOptions` 欄位
4. Module 檔案存在且可讀取

如果驗證通過，啟動成功。

### 步驟 6：測試

呼叫文字生成 API 並啟用新 module：

```json
{
  "model_id": "gpt-4o",
  "input_mode": "quick",
  "identity": "一位女性角色",
  "costume": "白色連衣裙",
  "composition": "站在花園中",
  "count": 1,
  "prompt_options": {
    "background_complexity": true
  },
  "output_format": "tags+nl"
}
```

組裝的 user message 會在 `composition` 之後、`visual_emphasis_*` 之前注入 `background_complexity` 的內容。

## 特殊情況：新增 Enum Value 的 Module

假設我們要新增第三個 `visual_emphasis` 選項：`full_scene`。

### 步驟 1：撰寫 Module 片段

建立 `config/prompts/modules/visual_emphasis_full_scene.md`：

```markdown
視覺重點：全場景。整體構圖應平衡人物與背景，兩者同等重要，創造完整的敘事空間。
```

### 步驟 2：在 `order` 中插入

```yaml
order:
  # ...
  - visual_emphasis_character_and_outfit
  - visual_emphasis_background_environment
  - visual_emphasis_full_scene           # ← 新增
  # ...
```

### 步驟 3：在 `modules` 中註冊

```yaml
modules:
  # ...
  visual_emphasis_character_and_outfit: modules/visual_emphasis_character_and_outfit.md
  visual_emphasis_background_environment: modules/visual_emphasis_background_environment.md
  visual_emphasis_full_scene: modules/visual_emphasis_full_scene.md    # ← 新增
```

### 步驟 4：在 `PromptOptions` 中加入新值

```python
class PromptOptions(BaseModel):
    # ...
    visual_emphasis: Literal[
        "none",
        "character_and_outfit",
        "background_environment",
        "full_scene",              # ← 新增
    ] = "none"
```

### 步驟 5：啟動驗證

```powershell
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 --app-dir src
```

### 步驟 6：測試

```json
{
  "model_id": "gpt-4o",
  "input_mode": "quick",
  "identity": "一位女性角色",
  "costume": "白色連衣裙",
  "composition": "站在花園中",
  "count": 1,
  "prompt_options": {
    "visual_emphasis": "full_scene"
  },
  "output_format": "tags+nl"
}
```

## 陷阱與注意事項

### ❌ 不要在 `modules` 中加入 Metadata

**錯誤範例：**
```yaml
modules:
  multi_character:
    path: modules/multi_character.md     # ❌ 不要巢狀
    field: multi_character
    value: true
```

**正確範例：**
```yaml
modules:
  multi_character: modules/multi_character.md    # ✅ 平鋪映射
```

### ❌ 不要在 `order` 中重複同一個 ID

**錯誤範例：**
```yaml
order:
  - multi_character
  - identity
  - multi_character      # ❌ 重複
```

### ❌ 不要忘記更新 `PromptOptions`

如果新增了 module ID 但沒有在 `PromptOptions` 中加入對應欄位，**啟動時會報錯**。

### ❌ 不要改變 Builtin 的位置沒有同步更新語意

雖然你可以調整 builtin 在 `order` 中的位置，但要確保語意合理。

**範例：**
```yaml
order:
  - count             # ✅ 技術上可行，但語意上「生成數量」通常放最後
  - identity
  - costume
  - composition
  - detailed_input
```

建議保持 builtin 位置與範本一致，除非有明確需求。

### ❌ Module 檔案不存在

如果 `modules` section 註冊的檔案路徑不存在，**啟動時會報錯**。

**錯誤範例：**
```yaml
modules:
  my_module: modules/non_existent.md    # ❌ 檔案不存在
```

## 零隱式規則聲明

`prompts.yaml` 使用完全平鋪的 `order` 與 `modules` 結構。`order` 的順序就是最後 user message 的組裝順序；module 是否啟用只由 `PromptOptions` 欄位名稱或 `visual_emphasis_<value>` 命名慣例決定。

## 設定檔驗證

後端啟動時會驗證：

1. `prompts.yaml` 存在且格式正確
2. `order` 包含五個 builtin ID，各出現一次
3. `order` 中的每個 non-builtin ID 在 `modules` 中有對應項
4. `modules` 中的每個 ID 在 `order` 中被引用（防止死 module）
5. 每個 module ID 可對應到 `PromptOptions` 欄位或 `visual_emphasis` 值
6. 每個 module 檔案存在且可讀取


## 參考連結

- **[../CONFIGURATION.md](../CONFIGURATION.md)** — 部署設定與啟動流程
- 新增／修改 prompt module 的完整開發流程見 backend `docs/guidelines/prompts.md`
- backend `docs/SPEC/specs/GENERATION.md` — 文字生成完整規格（開發文件）
