# OntoKit API

[![CI](https://github.com/CatholicOS/ontokit-api/actions/workflows/release.yml/badge.svg)](https://github.com/CatholicOS/ontokit-api/actions/workflows/release.yml)
[![PyPI](https://img.shields.io/pypi/v/ontokit)](https://pypi.org/project/ontokit/)
[![Python](https://img.shields.io/python/required-version-toml?tomlFilePath=https%3A%2F%2Fraw.githubusercontent.com%2FCatholicOS%2Fontokit-api%2Fmain%2Fpyproject.toml)](https://github.com/CatholicOS/ontokit-api)
[![Ruff](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json)](https://github.com/astral-sh/ruff)
[![codecov](https://codecov.io/gh/CatholicOS/ontokit-api/branch/dev/graph/badge.svg?token=MUF88DIN0X)](https://codecov.io/gh/CatholicOS/ontokit-api)

Collaborative OWL ontology curation API built with FastAPI.

## Features

- **RESTful API** for managing ontologies, classes, properties, and individuals
- **Project management** with public/private visibility and team collaboration
- **Git-based version control** with branching, pull requests, and sync from remote (pygit2 bare repos)
- **Ontology linting** with 20+ semantic validation rules
- **Semantic search** powered by sentence-transformers
- **Authentication** via Zitadel (OpenID Connect)
- **Real-time collaboration** via WebSockets
- **Background job queue** with ARQ + Redis
- **Object storage** integration with MinIO for ontology files

## Quick Start

### Full Docker Mode

```bash
# Start all services
docker compose up -d

# Run database migrations
docker compose exec api alembic upgrade head

# Set up Zitadel authentication (creates OIDC apps, updates .env files)
./scripts/setup-zitadel.sh --update-env

# Recreate API/worker containers to pick up the new credentials
docker compose up -d --force-recreate api worker
```

### Hybrid Mode (API on host)

```bash
# Start infrastructure
docker compose -f compose.prod.yaml up -d

# Install dependencies and pre-commit hooks (one command)
make setup

# Configure
cp .env.example .env

# Set up Zitadel authentication (creates OIDC apps, updates .env files)
./scripts/setup-zitadel.sh --update-env

# Run database migrations
alembic upgrade head

# Start server
uvicorn ontokit.main:app --reload
```

> **Note:** `make setup` requires [uv](https://docs.astral.sh/uv/). It installs
> all dev dependencies and sets up pre-commit hooks (ruff + mypy) so that code
> quality checks run automatically on every commit.

## Documentation

See the [wiki](https://github.com/CatholicOS/ontokit-api/wiki) for full documentation.

## Running OntoKit in GitHub Codespaces

Create the Codespace from this (`ontokit-api`) repository. The dev-container
initialization clones the canonical `ontokit-web` repository alongside it, so
the Codespace contains two independent Git repositories:

```text
/workspaces/ontokit-api
/workspaces/ontokit-web
```

Codespaces asks for read access to `r23riopel/ontokit-web`; approve that
request when prompted. The repository is currently public, but the permission
declaration also makes the required access explicit if its visibility changes.
The Codespace then starts the existing API Compose stack plus the web service
defined in `.devcontainer/compose.codespaces.yaml`. VS Code attaches to the
`api` service at `/workspaces/ontokit-api`. The web and API are forwarded on
ports 3000 and 8000. Zitadel and its login UI use ports 8080 and 8081. Database,
Redis, and MinIO ports are not forwarded by the dev-container configuration.

For a fresh Codespace, wait for the containers to become healthy, then configure
the local Zitadel instance from the VS Code terminal:

```bash
export WEB_URL="https://${CODESPACE_NAME}-3000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
export ZITADEL_URL="http://zitadel:8080"
export ZITADEL_INSTANCE_HOST="${CODESPACE_NAME}-8080.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
./scripts/setup-zitadel.sh --update-env </dev/null
```

Then apply the generated credentials by rebuilding the dev container: open the
Command Palette and run **Codespaces: Rebuild Container**. The rebuild re-runs
Docker Compose from the Codespaces host, which re-reads `.env` and recreates
the services with the new values.

> **Warning:** do not run `docker compose up`, `--force-recreate`, or any
> other command that creates containers from the integrated terminal with
> default paths. The terminal runs inside the `api` container, where the
> repository lives at `/workspaces/ontokit-api` — a path the host Docker
> daemon cannot resolve. Containers created that way record broken bind-mount
> sources and put the Codespace into recovery mode at the next restart.
> Rebuild Container is the supported way to recreate services. If a one-off
> manual recreation of a non-`api` service is unavoidable, pass the host-side
> project directory explicitly and never target the `api` service (its
> dev-container configuration only exists in the host-side invocation):
>
> ```bash
> docker compose \
>   --project-directory /var/lib/docker/codespacemount/workspace/ontokit-api \
>   -f /workspaces/ontokit-api/compose.yaml \
>   -f /workspaces/ontokit-api/.devcontainer/compose.codespaces.yaml \
>   --env-file /workspaces/ontokit-api/.env \
>   -p ontokit-api \
>   up -d --no-deps <service>
> ```

Generated OIDC credentials are written only to the ignored `ontokit-api/.env`
and `ontokit-web/.env.local` files. For shared or externally supplied
credentials, configure Codespaces secrets named `ZITADEL_CLIENT_ID`,
`ZITADEL_CLIENT_SECRET`, `ZITADEL_SERVICE_TOKEN`, `GITHUB_TOKEN_ENCRYPTION_KEY`,
and `AUTH_SECRET` as applicable; do not commit their values. The bundled local
Zitadel development setup generates its own values, so no repository secret is
required for the default first run.

Ontology source edits are persisted in two file-oriented stores: Turtle content
is uploaded to the `minio_data` volume and committed into per-project bare Git
repositories in the `git_repos` volume. PostgreSQL (`postgres_data`) stores
project, user, revision-related, indexing, and other application metadata; it is
not the sole source of ontology content. All volumes persist across normal
Codespace container rebuilds but are lost when the Codespace itself is deleted.

The normal local workflow remains unchanged: from this directory, run
`docker compose up -d`. The Codespaces override and sibling web checkout are
used only when the dev-container explicitly supplies the second Compose file.

## Tech Stack

- **Framework**: FastAPI (Python 3.13)
- **Database**: PostgreSQL 17 + SQLAlchemy 2.0 (async)
- **Cache/Queue**: Redis 7 + ARQ
- **Object Storage**: MinIO (S3-compatible)
- **Authentication**: Zitadel (OIDC)
- **Git**: pygit2 (bare repositories for concurrent access)
- **Ontology Processing**: RDFLib, OWLReady2
- **Semantic Search**: sentence-transformers

## License

MIT
