# SparkToComfy Compose

This repo owns Docker Compose app wiring and runtime config layout for the
split SparkToComfy repos.

Expected sibling repos:

```text
SparkToComfy/
  SparkToComfy-backend/
  SparkToComfy-frontend/
  SparkToComfy-compose/
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
./config/backend:/workspace/config:ro
```

Inside the backend container, `/workspace/config/config.yaml` is the backend
config file and `/workspace/config/prompts/` contains prompt templates.

The user's earlier `backend.yaml` name is not used yet. The backend currently
loads `config.yaml`; renaming it should be a deliberate backend loader change,
not a docker-only rename.

## First Run

```powershell
Copy-Item .env.example .env
Copy-Item config/backend/config.yaml.example config/backend/config.yaml
Copy-Item config/backend/prompts/system.md.example config/backend/prompts/system.md
docker compose up --build
```

Fill `.env` provider keys before generating prompts.

## Ownership

- `SparkToComfy-backend` owns API code, Python dependencies, and backend tests.
- `SparkToComfy-frontend` owns Vue/Vite code, frontend checks, and browser build output.
- `SparkToComfy-compose` owns compose files and mounted runtime config layout.
- `SparkToComfy-bot` is intentionally not created yet.
