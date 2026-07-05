#!/usr/bin/env bash
#
# Sync runtime config and deployment config docs FROM SparkToComfy-backend.
#
# This repo's config/ is a flat byte-for-byte mirror of backend/config/, and
# docs/guidelines/ is a banner-annotated copy of backend/docs/guidelines/.
# This script regenerates both so they never silently drift.
#
# Usage:
#   scripts/sync-from-backend.sh [BACKEND_DIR]          # rewrite mirror in place
#   scripts/sync-from-backend.sh --check [BACKEND_DIR]  # fail if out of sync (CI)
#
# BACKEND_DIR defaults to ../SparkToComfy-backend (sibling checkout).
#
# Local runs mirror from that backend WORKING COPY. The CI check
# (.github/workflows/check-config-sync.yml) runs --check against a fresh backend
# `main` checkout, which is the authority — keep your backend checkout on a clean
# `main` when syncing so the two agree (the script warns if they might not).
#
# Run this in the SparkToComfy repo only. It rewrites tracked mirror files
# (the *.yaml.example, workflow.json, prompts/, and the mirrored guides); it
# leaves a deployer's real config/*.yaml and docs/guidelines/README.md alone.
set -euo pipefail

CHECK=0
if [ "${1:-}" = "--check" ]; then CHECK=1; shift; fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_ARG="${1:-$ROOT/../SparkToComfy-backend}"
BACKEND="$(cd "$BACKEND_ARG" && pwd)"
cd "$ROOT"

BE_CFG="$BACKEND/config"
BE_GL="$BACKEND/docs/guidelines"
GL="docs/guidelines"
[ -d "$BE_CFG" ] || { echo "backend config not found: $BE_CFG" >&2; exit 2; }
[ -d "$BE_GL" ]  || { echo "backend guidelines not found: $BE_GL" >&2; exit 2; }

# ---------------------------------------------------------------------------
# 1. config/ — flat, byte-identical mirror (only the three *.yaml are examples;
#    workflow.json and prompts/ are tracked as-is, matching the backend).
# ---------------------------------------------------------------------------
rm -f config/config.yaml.example config/providers.yaml.example \
      config/image-options.yaml.example config/workflow.json
rm -rf config/prompts
mkdir -p config/prompts/fewshot config/prompts/modules
cp "$BE_CFG/config.yaml.example"           config/config.yaml.example
cp "$BE_CFG/providers.yaml.example"        config/providers.yaml.example
cp "$BE_CFG/image-options.yaml.example"    config/image-options.yaml.example
cp "$BE_CFG/workflow.json"                 config/workflow.json
cp "$BE_CFG/prompts/prompts.yaml"          config/prompts/prompts.yaml
cp "$BE_CFG/prompts/system.md"             config/prompts/system.md
cp "$BE_CFG/prompts/output_schema.json"    config/prompts/output_schema.json
cp "$BE_CFG/prompts/fewshot/examples.json" config/prompts/fewshot/examples.json
cp "$BE_CFG/prompts/modules/"*.md          config/prompts/modules/

# ---------------------------------------------------------------------------
# 2. docs/guidelines/ — copy each backend guide, insert a deployment banner
#    after the H1, and replace the footer (which links to backend-only paths).
#    The footer section starts at "## 參考連結" or "## 下一步".
# ---------------------------------------------------------------------------
mkdir -p "$GL"
emit() {  # $1 = guide filename ; reads $BANNER and $FOOTER
  local src="$BE_GL/$1" dst="$GL/$1"
  head -1 "$src" > "$dst"
  printf '\n%s\n' "$BANNER" >> "$dst"
  awk 'NR==1{next} /^## 參考連結/{exit} /^## 下一步/{exit} {print}' "$src" >> "$dst"
  printf '\n%s\n' "$FOOTER" >> "$dst"
}

BANNER='> **上游來源：** 本檔複製自 `SparkToComfy-backend/docs/guidelines/config.md`，欄位語意以 backend 為權威來源；如與後端不一致，以後端為準並回報。部署啟動流程見 [../CONFIGURATION.md](../CONFIGURATION.md)。'
FOOTER=$(cat <<'EOF'
## 參考連結

- **[../CONFIGURATION.md](../CONFIGURATION.md)** — 部署設定與啟動流程
- **[environment.md](environment.md)** — 環境變數說明
- **[image-options.md](image-options.md)** — 圖片選項設定
- **[providers.md](providers.md)** — Provider 設定教學
- backend `docs/SPEC/specs/API_CONTRACT.md` — API 完整規格（開發文件）
EOF
)
emit config.md

BANNER='> **上游來源：** 本檔複製自 `SparkToComfy-backend/docs/guidelines/environment.md`，欄位語意以 backend 為權威來源；如與後端不一致，以後端為準並回報。部署啟動流程見 [../CONFIGURATION.md](../CONFIGURATION.md)。'
FOOTER=$(cat <<'EOF'
## 參考連結

- **[../CONFIGURATION.md](../CONFIGURATION.md)** — 部署設定與啟動流程
- **[config.md](config.md)** — `config.yaml` 欄位參考
- **[providers.md](providers.md)** — Provider 設定教學
EOF
)
emit environment.md
sed -i 's#\./config/backend:/config#./config:/config#g' "$GL/environment.md"

BANNER='> **上游來源：** 本檔複製自 `SparkToComfy-backend/docs/guidelines/providers.md`，欄位語意以 backend 為權威來源；如與後端不一致，以後端為準並回報。部署啟動流程見 [../CONFIGURATION.md](../CONFIGURATION.md)。'
FOOTER=$(cat <<'EOF'
## 參考連結

- **[../CONFIGURATION.md](../CONFIGURATION.md)** — 部署設定與啟動流程
- **[environment.md](environment.md)** — 環境變數說明（包含 API keys）
- **[config.md](config.md)** — `config.yaml` 欄位參考
- backend `docs/SPEC/specs/API_CONTRACT.md` — API 完整規格（開發文件）
EOF
)
emit providers.md

BANNER='> **上游來源：** 本檔複製自 `SparkToComfy-backend/docs/guidelines/image-options.md`，欄位語意以 backend 為權威來源；如與後端不一致，以後端為準並回報。部署啟動流程見 [../CONFIGURATION.md](../CONFIGURATION.md)。'
FOOTER=$(cat <<'EOF'
## 參考連結

- **[../CONFIGURATION.md](../CONFIGURATION.md)** — 部署設定與啟動流程
- **[config.md](config.md)** — `config.yaml` 欄位參考（包含 workflow nodes）
- backend `docs/SPEC/specs/GENERATION.md` — 圖片生成完整規格（開發文件）
EOF
)
emit image-options.md

BANNER=$(cat <<'EOF'
> **上游來源：** 本檔複製自 `SparkToComfy-backend/docs/guidelines/prompts.md`。
>
> **部署端限制：** 你可以修改既有 `config/prompts/` 的內容（例如 `modules/*.md` 文字、`prompts.yaml` 的 `order`）後重新掛載；但**新增** prompt module 需在 backend 修改 `PromptOptions` 並重新 build app image。本檔中的 `poetry` 與 `src/app/...` 步驟屬 backend 開發流程，部署端無法直接執行。
EOF
)
FOOTER=$(cat <<'EOF'
## 參考連結

- **[../CONFIGURATION.md](../CONFIGURATION.md)** — 部署設定與啟動流程
- 新增／修改 prompt module 的完整開發流程見 backend `docs/guidelines/prompts.md`
- backend `docs/SPEC/specs/GENERATION.md` — 文字生成完整規格（開發文件）
EOF
)
emit prompts.md

BANNER=$(cat <<'EOF'
> **上游來源：** 本檔複製自 `SparkToComfy-backend/docs/guidelines/getting-started.md`，是 backend 的**開發**啟動流程（`poetry` / `uvicorn`）。
>
> **容器部署請改看 [../CONFIGURATION.md](../CONFIGURATION.md)**（`docker compose up`）。這裡保留原文供理解後端啟動與健康檢查行為。
EOF
)
FOOTER=$(cat <<'EOF'
## 下一步

- **[../CONFIGURATION.md](../CONFIGURATION.md)** — 容器部署流程（本 repo 的快速開始）
- **[environment.md](environment.md)** — 環境變數詳細說明
- **[config.md](config.md)** — 調整 auth、queue、image generation 設定
- **[providers.md](providers.md)** — 新增更多 provider 與 model
- backend `docs/SPEC/` — 完整 API 規格與架構文件（開發文件）
EOF
)
emit getting-started.md

# ---------------------------------------------------------------------------
# 3. Report / check
# ---------------------------------------------------------------------------
REF="$(git -C "$BACKEND" rev-parse --short HEAD 2>/dev/null || echo unknown)"
BRANCH="$(git -C "$BACKEND" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"

if [ "$CHECK" = 1 ]; then
  if git diff --quiet -- config "$GL"; then
    echo "In sync with backend @ $REF."
  else
    echo "DRIFT: config/ or docs/guidelines/ is out of sync with backend @ $REF." >&2
    echo "Run: scripts/sync-from-backend.sh   (then commit the result)" >&2
    git --no-pager diff --stat -- config "$GL" >&2
    exit 1
  fi
else
  echo "Synced config/ and docs/guidelines/ from local backend checkout:"
  echo "  $BACKEND @ $REF ($BRANCH)"
  if [ "$BRANCH" != "main" ]; then
    echo "  NOTE: backend is on '$BRANCH', not 'main'; CI compares against backend main." >&2
  fi
  if ! git -C "$BACKEND" diff --quiet 2>/dev/null || ! git -C "$BACKEND" diff --cached --quiet 2>/dev/null; then
    echo "  NOTE: backend checkout has uncommitted changes; the mirror may differ from committed main." >&2
  fi
  echo "Review with: git diff --staged"
fi
