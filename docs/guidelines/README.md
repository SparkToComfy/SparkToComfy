# 設定指南（部署端）

這個目錄放 SparkToComfy **部署端**會用到的設定檔逐欄位說明，複製自
`SparkToComfy-backend/docs/guidelines/`，方便你在部署這個 repo 時就地查閱，不必另外打開
backend repo。

> 欄位語意的**權威來源仍是 backend**。這裡是給部署者的便利副本；如發現與後端行為不一致，
> 以 backend 為準並回報。**不要手動編輯這裡的鏡像檔** —— 改動請回到 backend，再用下方的
> 同步腳本重新產生（見「與 backend 同步」）。

## 部署流程

從 clone 到 `docker compose up` 的完整容器部署流程請看
**[../CONFIGURATION.md](../CONFIGURATION.md)**，那份文件就是這個 repo 的「快速開始」。

`getting-started.md` 是 backend 的 `poetry`/`uvicorn` **開發**啟動流程，這裡保留一份供理解
後端啟動與健康檢查行為，但容器部署請以 `CONFIGURATION.md` 為準。

## 設定檔逐欄位說明

- **[environment.md](environment.md)** — `.env` 環境變數（API keys、`COMFYUI_BASE_URL`、`FRONTEND_ORIGINS`、路徑覆寫）
- **[config.md](config.md)** — `config/config.yaml`（`auth`、`generation_queue`、`image_generation`）
- **[providers.md](providers.md)** — `config/providers.yaml`（`rate_limit` 與 LLM provider/model）
- **[image-options.md](image-options.md)** — `config/image-options.yaml`（尺寸、sampler、quality、negative、LoRA）
- **[prompts.md](prompts.md)** — `config/prompts/`（組裝結構；**新增** module 屬 backend 開發，見檔內說明）
- **[getting-started.md](getting-started.md)** — backend 開發啟動流程參考（容器部署請看 `../CONFIGURATION.md`）

## 設定檔與執行期路徑對應

| 設定檔（此 repo） | 容器內路徑 | 說明文件 |
|---|---|---|
| `config/config.yaml` | `/config/config.yaml` | [config.md](config.md) |
| `config/providers.yaml` | `/config/providers.yaml` | [providers.md](providers.md) |
| `config/image-options.yaml` | `/config/image-options.yaml` | [image-options.md](image-options.md) |
| `config/workflow.json` | `/config/workflow.json` | 固定 ComfyUI workflow（不需手改） |
| `config/prompts/` | `/config/prompts/` | [prompts.md](prompts.md) |
| `.env` | 由 compose 以 `env_file` 注入 | [environment.md](environment.md) |

## 與 backend 同步

`config/` 與 `docs/guidelines/` 都是 backend 的鏡像，由一支腳本產生，不要手改：

```bash
# 從 sibling 的 backend checkout 重新產生鏡像（預設 ../SparkToComfy-backend）
scripts/sync-from-backend.sh
git diff --staged   # 檢視變更後再 commit
```

CI 會用 `--check` 模式擋住 drift：`.github/workflows/check-config-sync.yml` 會 checkout
backend、重新產生鏡像，只要與 committed 內容不一致就**紅燈**（相關 push/PR 時，以及每週
排程一次）。所以 backend 改了 config 或 guidelines 後，這裡沒同步就會被 CI 擋下。
