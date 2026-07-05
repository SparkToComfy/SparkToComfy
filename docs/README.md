# SparkToComfy Docs

This repo (the main `SparkToComfy` project) holds deployment, configuration, and
product-level documentation. Implementation specs and detailed diagrams live in
`SparkToComfy-backend/docs/`, next to the code they describe.

## In this repo

- [CONFIGURATION.md](CONFIGURATION.md) — runtime config layout, VM setup, per-file reference, auth, and secrets (the deployment "quick start").
- [guidelines/](guidelines/README.md) — per-field config reference (config, providers, image-options, environment, prompts, getting-started), mirrored from the backend so deployers can read it here without opening the backend repo.
- [PRODUCT_OVERVIEW.md](PRODUCT_OVERVIEW.md) — actors, use-case diagram, and user stories (product view).

## In SparkToComfy-backend

- `docs/guidelines/` — upstream source of the config field guides mirrored here.
- `docs/SPEC/` — architecture, decisions, glossary, API contracts, and all flow/interaction diagrams.
- `docs/SPEC/USE_CASES_AND_FLOWS.md` — authoritative use cases, user stories, and detailed flows.
- `docs/CODEBASE_GUIDE.md` — code walkthrough and debugging map.

## Where new docs go

| Doc type | Home |
|---|---|
| Deployment / runtime config | this repo (`SparkToComfy`) |
| Product overview, use-case diagram, user-story catalog | this repo (`SparkToComfy`) |
| Config field semantics (what each YAML key means) | backend is the source; a deployer-facing copy is mirrored into `docs/guidelines/` here |
| Interaction / sequence / flow / state / architecture diagrams | backend (`docs/SPEC/`) |
| API contracts, decisions, glossary | backend (`docs/SPEC/`) |

Rule of thumb: **diagrams and specs that track the code live with the code
(backend); deployment, configuration, and the product overview live here.** The
`config/` tree and the `docs/guidelines/` field guides are deliberate mirrors of
the backend, kept for the runtime mount and for deployer convenience.

## Keeping in sync with the backend

`config/` and `docs/guidelines/` are generated mirrors — do not hand-edit them.
Change the backend, then regenerate:

```bash
scripts/sync-from-backend.sh            # rewrite the mirror from ../SparkToComfy-backend
git diff --staged                       # review, then commit
```

Drift is enforced, not just documented: `.github/workflows/check-config-sync.yml`
checks out the backend, re-runs `scripts/sync-from-backend.sh --check`, and fails
the build if the committed mirror differs from the backend — on relevant push/PR
and on a weekly schedule (so an upstream backend change that isn't mirrored here
turns the check red). See [guidelines/README.md](guidelines/README.md#與-backend-同步).
