# Releases

This repo's version **is** the app image version: a `vX.Y.Z` git tag here maps 1:1
to `ghcr.io/sparktocomfy/app:vX.Y.Z`. The backend and frontend are **not** pinned
to this number — each release chooses its source refs at build time via the
`build-app-image` workflow inputs (`backend_ref`, `frontend_ref`). So one app
release can be built from any backend/frontend refs.

Versions use the `vX.Y.Z` form. Old unversioned (`X.Y.Z`, no `v`) images may be
deleted from GHCR.

| App image / repo tag | backend_ref | frontend_ref | Notes |
|---|---|---|---|
| `v0.0.1` | `v0.0.5` | `v0.0.5` | First tagged release: flat config mirror of the backend, deployment docs + mirrored guidelines, product overview, sync-from-backend script + CI drift check. |

## Cutting a release

1. Tag this repo: `git tag -a vX.Y.Z -m "…"` and push it.
2. Build and publish the image:

   ```bash
   gh workflow run build-app-image.yml -R SparkToComfy/SparkToComfy \
     -f app_version=vX.Y.Z \
     -f backend_ref=<backend tag> \
     -f frontend_ref=<frontend tag>
   ```

3. On the deployment host, adopt it:

   ```bash
   # .env: APP_IMAGE=ghcr.io/sparktocomfy/app:vX.Y.Z
   docker compose pull
   docker compose up -d
   ```

Each image records its provenance at `/workspace/build-info.json`
(`app_version`, `backend_ref`, `frontend_ref`) — inspect with
`docker run --rm ghcr.io/sparktocomfy/app:vX.Y.Z cat /workspace/build-info.json`.
