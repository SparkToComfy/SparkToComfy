# Configuration

`SparkToComfy-compose` is the runtime entrypoint for the combined app image.
It does not build backend or frontend source on the VM.

## Runtime Mounts

```yaml
./config/backend:/config:ro
./data:/data
```

The app container uses:

```text
CONFIG_DIR=/config
DATA_DIR=/data
STATIC_DIR=/workspace/frontend-dist
```

`/config` must contain:

```text
config.yaml
config.d/
prompts/
```

`config.yaml` is a manifest. It lists files under `config.d/`, and each listed
file must contain exactly one backend runtime config section. `/data` is
writable runtime storage. SQLite state and request capture reports should stay
under `/data`.

## VM Runtime Setup

From a fresh clone on the VM:

```bash
cp .env.example .env
find config/backend -name '*.example' -type f | while read -r file; do
  cp "$file" "${file%.example}"
done
mkdir -p data
```

Set a published app image in `.env`:

```env
APP_IMAGE=ghcr.io/sparktocomfy/app:v0.1.0
APP_PORT=8000
APP_ENV=production
```

Fill provider secrets in `.env`, then start:

```bash
docker compose up -d
```

For upgrades to an existing tag, pull first:

```bash
docker compose pull
docker compose up -d
```

If `ghcr.io/sparktocomfy/app:<tag>` is public, the VM does not need GHCR login.

## Version Selection

Set the image tag in `.env`:

```env
APP_IMAGE=ghcr.io/sparktocomfy/app:v0.1.0
```

Build that tag from the workflow inputs:

```text
app_version   final app image tag
backend_ref   backend branch, tag, or commit
frontend_ref  frontend branch, tag, or commit
```

Use tags or commit SHAs for production releases. Use `main` only for test
images.

## Frontend Serving

The app image contains both the FastAPI backend and the compiled frontend dist.
The backend serves the static frontend from `STATIC_DIR`, so production
`VITE_API_BASE` remains empty and browser calls use same-origin paths:

```text
/v1/*      API
/health/*  health
/          frontend SPA
```

Cloudflared should route the public domain to the compose app port. No separate
frontend container or frontend runtime config is required.

## Auth And Passkey

The example `config/backend/config.d/auth.yaml.example` enables backend auth
but disables passkey/WebAuthn for the first VM deployment:

```yaml
auth:
  enabled: true
  cookie_secure: auto
  cookie_samesite: lax
  webauthn:
    enabled: false
```

With `webauthn.enabled: false`, the placeholder `rp_id` and `origins` do not
need to match the public domain.

If passkey is enabled later, update the runtime `auth.yaml` to the public
browser origin:

```yaml
auth:
  webauthn:
    enabled: true
    rp_id: app.example.com
    origins:
      - https://app.example.com
```

`rp_id` is the hostname only. `origins` must include the full `https://` origin.

## Local Secrets

Do not commit real `.env`, provider keys, `config/backend/config.yaml`,
`config/backend/config.d/*.yaml`, private prompt templates, or files under
`data/`. Commit only `.example` files.
