# Configuration

`SparkToComfy` is the runtime entrypoint for the combined app image. It does not
build backend or frontend source on the VM; it mounts a config directory and a
data directory into the published app image.

The config layout mirrors `SparkToComfy-backend` exactly. The backend repo owns
the field-level semantics of every file; this guide covers what an operator needs
to deploy. For exhaustive per-field reference, see the backend guidelines under
`SparkToComfy-backend/docs/guidelines/`.

## Runtime Mounts

```yaml
./config:/config:ro
./data:/data
```

The app container uses:

```text
CONFIG_DIR=/config
DATA_DIR=/data
STATIC_DIR=/workspace/frontend-dist
```

## Config Files

`/config` contains three backend config files, the fixed workflow prompt, and the
prompt assets:

```text
config/
  config.yaml          auth, generation_queue, image_generation
  providers.yaml       rate_limit, providers (LLM provider/model list)
  image-options.yaml   image_options (size, sampling, base models, quality, negative, LoRA)
  workflow.json        fixed ComfyUI workflow prompt
  prompts/
    prompts.yaml       assembly order + module registry
    system.md
    output_schema.json
    fewshot/examples.json
    modules/*.md
```

The backend reads exactly three YAML files under `/config` — there is no
`config.d/` manifest and no fallback to `.example` files. A missing file fails
startup with an explicit error naming the file to copy. `workflow.json` and
everything under `prompts/` are tracked in this repo and used as-is. `/data` is
writable runtime storage; SQLite state and request-capture reports stay under
`/data`.

## VM Runtime Setup

From a fresh clone on the VM:

```bash
cp .env.example .env
find config -name '*.example' -type f | while read -r file; do
  cp "$file" "${file%.example}"
done
mkdir -p data
```

This copies the three `*.yaml.example` files to their real names. `workflow.json`
and the `prompts/` assets are already present (tracked), so there is nothing else
to copy.

Set a published app image in `.env`:

```env
APP_IMAGE=ghcr.io/sparktocomfy/app:v0.1.0
APP_PORT=8000
APP_ENV=production
```

Fill provider secrets in `.env` (the API keys referenced by `env_key` in
`config/providers.yaml`), then start:

```bash
docker compose up -d
```

For upgrades to an existing tag, pull first:

```bash
docker compose pull
docker compose up -d
```

If `ghcr.io/sparktocomfy/app:<tag>` is public, the VM does not need GHCR login.

## What Each File Controls

| File | Sections | Common edits |
|---|---|---|
| `config/config.yaml` | `auth`, `generation_queue`, `image_generation` | disable auth, enable/disable image generation, queue limits |
| `config/providers.yaml` | `rate_limit`, `providers` | add a provider/model, change rate limits |
| `config/image-options.yaml` | `image_options` | add a LoRA, quality/negative preset, size limits |
| `config/workflow.json` | fixed ComfyUI graph | only when the ComfyUI workflow itself changes |
| `config/prompts/` | prompt assembly | add or adjust prompt modules |

`.env` provides secrets and runtime endpoints: provider API keys,
`COMFYUI_BASE_URL`, and `FRONTEND_ORIGINS` (CORS + WebAuthn browser origins).

## Version Selection

Set the image tag in `.env`:

```env
APP_IMAGE=ghcr.io/sparktocomfy/app:v0.1.0
```

Build that tag from the workflow inputs (`app_version`, `backend_ref`,
`frontend_ref`). Use tags or commit SHAs for production releases; use `main` only
for test images.

## Frontend Serving

The app image contains both the FastAPI backend and the compiled frontend dist.
The backend serves the static frontend from `STATIC_DIR`, so production
`VITE_API_BASE` stays empty and the browser uses same-origin paths:

```text
/v1/*      API
/health/*  health
/          frontend SPA
```

Cloudflared routes the public domain to the compose app port. No separate frontend
container or frontend runtime config is required.

## Auth And Passkey

The `auth` section of `config/config.yaml` controls account/session auth. The
synced example enables auth and WebAuthn with a local-dev `rp_id`:

```yaml
auth:
  enabled: true
  cookie_secure: auto
  cookie_samesite: lax
  webauthn:
    enabled: true
    rp_id: localhost
```

`rp_id: localhost` only works locally. For a VM behind Cloudflared, either set
`webauthn.enabled: false`, or set `rp_id` to the public hostname (without
`https://`). Browser origins for CORS and WebAuthn come from `FRONTEND_ORIGINS` in
`.env`, not from the YAML.

## Local Secrets

Do not commit real `.env`, provider keys, `config/config.yaml`,
`config/providers.yaml`, `config/image-options.yaml`, or anything under `data/`.
The repository tracks only the three `.example` files plus `workflow.json` and the
`prompts/` assets.
