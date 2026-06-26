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
prompts/
```

`/data` is writable runtime storage. Request capture reports should be written
to `/data/request-captures`.

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

## Local Secrets

Do not commit real `.env`, provider keys, `config/backend/config.yaml`, private
prompt templates, or files under `data/`. Commit only `.example` files.
