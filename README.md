# SparkToComfy Compose

This repo owns Docker Compose app wiring and runtime config layout.

VMs should not build backend/frontend source. The normal production flow is:

```text
GitHub Actions builds ghcr.io/sparktocomfy/app:<tag>
VM runs docker compose pull
VM runs docker compose up -d
```

The app image contains:

```text
FastAPI backend
frontend dist served by the backend through STATIC_DIR
```

## Config Layout

```text
config/
  backend/
    config.yaml
    config.d/
      auth.yaml
      providers.yaml
      ...
    prompts/
      system.md
      fewshot/
      modules/
  bot/
    discord.yaml
```

The compose file mounts:

```yaml
./config/backend:/config:ro
./data:/data
```

Inside the app container, `/config/config.yaml` is the backend config manifest,
`/config/config.d/` contains backend runtime sections, and `/config/prompts/`
contains prompt templates. Runtime-only data, including SQLite state and request
capture Markdown files, belongs under `/data`.

## First Run

On a VM, clone this repo and prepare local runtime files:

```bash
cp .env.example .env
find config/backend -name '*.example' -type f | while read -r file; do
  cp "$file" "${file%.example}"
done
mkdir -p data
```

Edit `.env` and set a published app image tag:

```env
APP_IMAGE=ghcr.io/sparktocomfy/app:v0.1.0
APP_PORT=8000
APP_ENV=production
```

Fill the provider keys used by `config/backend/config.d/providers.yaml`, then
start the app:

```bash
docker compose up -d
```

For upgrades to an existing VM image tag, pull first:

```bash
docker compose pull
docker compose up -d
```

With the GHCR app package set to public, the VM does not need
`docker login ghcr.io`.

## Runtime Paths

The compose runtime intentionally matches the combined app image layout:

```text
CONFIG_DIR=/config
DATA_DIR=/data
STATIC_DIR=/workspace/frontend-dist
```

The frontend is already compiled into the app image and served by the backend.
Production builds intentionally leave `VITE_API_BASE` empty so browser requests
use the same origin for `/v1/*`, `/health/*`, and WebSocket traffic. This works
behind Docker and Cloudflared as long as Cloudflared routes the public domain to
`APP_PORT`.

Keep real `.env`, `config/backend/config.yaml`, `config/backend/config.d/*.yaml`,
prompt templates, and `data/` local to the deployment host. The repository
tracks only examples.

## Auth Notes

The default VM example enables backend account/session auth but disables
passkey/WebAuthn:

```yaml
auth:
  enabled: true
  webauthn:
    enabled: false
```

When WebAuthn is disabled, `auth.webauthn.rp_id` and `auth.webauthn.origins`
do not need to match the Cloudflared public domain.

If passkey support is enabled later, set `rp_id` to the public hostname without
`https://` and set `origins` to the browser origin:

```yaml
auth:
  webauthn:
    enabled: true
    rp_id: app.example.com
    origins:
      - https://app.example.com
```

## Building App Images

App images are built by `.github/workflows/build-app-image.yml`.

If `SparkToComfy-backend` or `SparkToComfy-frontend` are private repositories,
create a fine-grained GitHub token with read access to both repos and save it in
this repo as an Actions secret:

```text
SPARKTOCOMFY_SOURCE_TOKEN
```

Manual workflow inputs:

```text
app_version   image tag to publish, for example v0.3.1
backend_ref   backend branch, tag, or commit
frontend_ref  frontend branch, tag, or commit
```

The workflow builds:

```text
ghcr.io/sparktocomfy/app:<app_version>
```

Set the `ghcr.io/sparktocomfy/app` package visibility to public in GitHub
Package settings if VMs should run without `docker login ghcr.io`.

Use tags or commit SHAs for production releases. Use `main` only for test
images.

## Ownership

- `SparkToComfy-backend` owns API code, Python dependencies, backend tests, and optional `STATIC_DIR` serving.
- `SparkToComfy-frontend` owns Vue/Vite code, frontend checks, and static build output.
- `SparkToComfy-compose` owns compose files, app image build workflow, and mounted runtime config layout.
- `SparkToComfy-bot` is intentionally not created yet.
