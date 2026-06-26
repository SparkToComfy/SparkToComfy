# syntax=docker/dockerfile:1.7

FROM node:24-alpine AS frontend-build

ARG FRONTEND_REPO=https://github.com/SparkToComfy/SparkToComfy-frontend.git
ARG FRONTEND_REF=main
ARG VITE_API_BASE=

RUN apk add --no-cache git
RUN --mount=type=secret,id=github_token,required=false \
    token="$(cat /run/secrets/github_token 2>/dev/null || true)" \
    && if [ -n "$token" ]; then \
        git config --global url."https://x-access-token:${token}@github.com/".insteadOf "https://github.com/"; \
    fi \
    && git clone --depth 1 --branch "$FRONTEND_REF" "$FRONTEND_REPO" /frontend \
    || (git clone "$FRONTEND_REPO" /frontend && cd /frontend && git checkout "$FRONTEND_REF")

WORKDIR /frontend
ENV VITE_API_BASE=$VITE_API_BASE
RUN npm ci && npm run build


FROM alpine:3.20 AS backend-source
ARG BACKEND_REPO=https://github.com/SparkToComfy/SparkToComfy-backend.git
ARG BACKEND_REF=main

RUN apk add --no-cache git
RUN --mount=type=secret,id=github_token,required=false \
    token="$(cat /run/secrets/github_token 2>/dev/null || true)" \
    && if [ -n "$token" ]; then \
        git config --global url."https://x-access-token:${token}@github.com/".insteadOf "https://github.com/"; \
    fi \
    && git clone --depth 1 --branch "$BACKEND_REF" "$BACKEND_REPO" /backend \
    || (git clone "$BACKEND_REPO" /backend && cd /backend && git checkout "$BACKEND_REF")


FROM python:3.11-slim AS app

ARG BACKEND_REF=main
ARG FRONTEND_REF=main
ARG APP_VERSION=dev

WORKDIR /workspace

ENV PYTHONUNBUFFERED=1
ENV CONFIG_DIR=/config
ENV DATA_DIR=/data
ENV STATIC_DIR=/workspace/frontend-dist

RUN pip install --no-cache-dir poetry \
    && poetry config virtualenvs.create false

COPY --from=backend-source /backend/pyproject.toml /backend/poetry.lock ./
RUN poetry install --only main --no-root --no-interaction --no-ansi

COPY --from=backend-source /backend/src ./src
COPY --from=backend-source /backend/config /config
RUN mkdir -p /data

COPY --from=frontend-build /frontend/dist /workspace/frontend-dist

RUN printf '{\n  "app_version": "%s",\n  "backend_ref": "%s",\n  "frontend_ref": "%s"\n}\n' \
    "$APP_VERSION" "$BACKEND_REF" "$FRONTEND_REF" > /workspace/build-info.json

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--app-dir", "src"]
