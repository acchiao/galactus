# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Galactus is a Django 6.0 web application ("The All-Knowing User Service Provider Aggregator") built from Cookiecutter Django. It uses Python 3.13, Docker Compose for local development, and `uv` as the package manager.

## Development Commands

All local development runs in Docker. The `justfile` wraps common Docker Compose operations (uses `docker-compose.local.yml` by default):

```bash
just build          # Build the Django Docker image
just up             # Start all containers (detached)
just down           # Stop containers
just prune          # Stop containers and remove volumes
just logs django    # Tail logs for a specific service
just manage <cmd>   # Run manage.py inside the Django container
```

### Tests

```bash
# Run all tests (inside Docker)
docker compose -f docker-compose.local.yml run django pytest

# Run a single test file
docker compose -f docker-compose.local.yml run django pytest galactus/users/tests/test_models.py

# Run a single test
docker compose -f docker-compose.local.yml run django pytest galactus/users/tests/test_models.py::TestUserModel::test_get_absolute_url -v

# Run tests outside Docker (requires local DB, Redis)
uv run pytest
```

Pytest is configured in `pyproject.toml` with `--ds=config.settings.test --reuse-db --import-mode=importlib`.

### Linting & Formatting

Pre-commit handles all Python linting. Prettier handles JS/YAML/JSON formatting. Hooks run automatically on commit:

```bash
uv run pre-commit run --all-files   # Run all pre-commit hooks manually
uv run ruff check .                 # Lint only
uv run ruff format .                # Format only
uv run mypy galactus                # Type checking
npm run format:check                # Prettier check (JS, YAML, JSON)
npm run format                      # Prettier auto-fix
```

Ruff config is in `pyproject.toml`. Migrations, `staticfiles/`, and `charts/` are excluded from linting. Django templates are linted with djLint (profile: `django`). The `charts/` directory is excluded from both pre-commit and Prettier (Helm templates use Go template syntax that breaks YAML parsers).

## Architecture

### Settings Hierarchy

Split settings in `config/settings/`:

- `base.py` — shared settings (DB, apps, middleware, Celery, allauth, DRF, webpack)
- `local.py` — dev overrides (DEBUG=True, debug toolbar, django-extensions, LocMemCache, Mailpit email)
- `test.py` — fast test settings (MD5 passwords, locmem email, FakeWebpackLoader)
- `production.py` — production settings (GCS storage, SendGrid email, Sentry, Traefik)

Settings are selected via `DJANGO_SETTINGS_MODULE`. Pytest uses `config.settings.test`.

### URL Structure

- `/` — Home page (template view)
- `/admin/` — Django admin
- `/users/` — Template-based user views (detail, update, redirect)
- `/accounts/` — django-allauth authentication flows
- `/api/` — DRF API router (users viewset with `/api/users/me/` endpoint)
- `/api/auth-token/` — DRF token auth endpoint
- `/api/schema/` — OpenAPI schema (drf-spectacular)
- `/api/docs/` — Swagger UI

### User Model

Custom user model at `galactus/users/models.py` — **email-only authentication, no username field**. Uses `AbstractUser` with a custom `UserManager`. Login methods: `{"email"}`. The `User` model has a single `name` field instead of `first_name`/`last_name`.

### App Structure

New Django apps go in `galactus/` (the `APPS_DIR`). Each app follows this pattern:

- `models.py`, `admin.py`, `views.py`, `urls.py`, `tasks.py`
- `api/views.py`, `api/serializers.py` — DRF API layer
- `tests/` — test directory with `factories.py` (factory_boy), test files per layer
- Register API viewsets in `config/api_router.py`
- Register URL includes in `config/urls.py`

Shared test fixtures are in `galactus/conftest.py` (provides `user` fixture via `UserFactory`).

### Docker Services (local)

`docker-compose.local.yml` defines: **django** (:8000), **postgres** (PostgreSQL 18), **redis** (7.2), **mailpit** (:8025 web UI), **celeryworker**, **celerybeat**, **flower** (:5555), **node** (:3000 — webpack dev server).

Environment variables live in `.envs/.local/` (`.django` and `.postgres` files).

### Frontend

Bootstrap 5 with Sass compilation via Webpack (Node 24). Static files in `galactus/static/`. The Node container runs `npm run dev` for hot-reload on port 3000, proxying to Django on 8000. Webpack configs are in `webpack/`.

### Background Tasks

Celery with Redis broker. Tasks use `@shared_task` decorator. Celery Beat uses `django_celery_beat.schedulers:DatabaseScheduler` for periodic task scheduling. The Celery app is configured in `config/celery_app.py`. In local dev, tasks execute synchronously (`CELERY_TASK_EAGER_PROPAGATES = True`).

### ASGI & WebSockets

`config/asgi.py` routes HTTP to Django and WebSocket connections to `config/websocket.py` (basic ping/pong handler). Production uses uvicorn.

### Kubernetes Deployment

Helm chart in `charts/galactus/` deploys the full stack to Kubernetes:

- **Deployments**: web (Django/gunicorn), celery-worker, celery-beat, flower (optional)
- **Pre-install hook**: migration Job runs `manage.py migrate` before each deploy
- **Ingress**: Traefik IngressRoute with TLS (Let's Encrypt via ClusterIssuer)
- **Scaling**: HPA on CPU for web pods, KEDA ScaledObject on Celery queue depth for workers
- **Secrets**: supports inline secrets or ExternalSecret (GCP Secret Manager)
- **Sub-charts**: Bitnami PostgreSQL and Redis for dev; disabled in production (use managed services)

Value files: `values.yaml` (dev defaults), `values-staging.yaml`, `values-production.yaml`.

### Production Docker Image

Multi-stage build in `compose/production/django/Dockerfile`:

1. **client-builder** (Node 24) — installs npm deps, runs `npm run build`
2. **python-build-stage** (uv + Python 3.13) — syncs Python deps, copies built frontend assets
3. **python-run-stage** (Python 3.13-slim) — minimal runtime, runs as non-root `django` user

The entrypoint script constructs `DATABASE_URL` from env vars and waits for PostgreSQL before starting.

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs on PRs/pushes to `main`:

1. **Linter job**: pre-commit hooks (ruff, djLint, django-upgrade, check-yaml, etc.)
2. **Prettier job**: `npm run format:check` for JS/YAML/JSON formatting
3. **Pytest job**: builds Docker images (with GHA layer caching), checks for pending migrations (`makemigrations --check`), runs migrations, then `pytest`
