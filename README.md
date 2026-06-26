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
    prompts/
      system.md
      modules/
  bot/
    discord.yaml
```

The compose file mounts:

```yaml
./config/backend:/config:ro
./data:/data
```

Inside the app container, `/config/config.yaml` is the backend config file and
`/config/prompts/` contains prompt templates. Runtime-only data, including
request capture Markdown files, belongs under `/data`.

## First Run

```bash
cp .env.example .env
cp config/backend/config.yaml.example config/backend/config.yaml
find config/backend/prompts -name '*.example' -type f | while read -r file; do
  cp "$file" "${file%.example}"
done
mkdir -p data
docker compose pull
docker compose up -d
```

Fill `.env` provider keys before generating prompts.

## Runtime Paths

The compose runtime intentionally matches the combined app image layout:

```text
CONFIG_DIR=/config
DATA_DIR=/data
STATIC_DIR=/workspace/frontend-dist
```

Keep real `.env`, `config/backend/config.yaml`, prompt templates, and `data/`
local to the deployment host. The repository tracks only examples.

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

Use tags or commit SHAs for production releases. Use `main` only for test
images.

## Ownership

- `SparkToComfy-backend` owns API code, Python dependencies, backend tests, and optional `STATIC_DIR` serving.
- `SparkToComfy-frontend` owns Vue/Vite code, frontend checks, and static build output.
- `SparkToComfy-compose` owns compose files, app image build workflow, and mounted runtime config layout.
- `SparkToComfy-bot` is intentionally not created yet.
