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

Pre-commit handles all linting. Hooks run automatically on commit:

```bash
uv run pre-commit run --all-files   # Run all pre-commit hooks manually
uv run ruff check .                 # Lint only
uv run ruff format .                # Format only
uv run mypy galactus                # Type checking
```

Ruff config is in `pyproject.toml`. Migrations and `staticfiles/` are excluded from linting. Django templates are linted with djLint (profile: `django`).

### Other Commands

```bash
uv run python manage.py createsuperuser       # Create admin user
uv run coverage run -m pytest && uv run coverage html  # Coverage report
```

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

### Frontend

Bootstrap 5 with Sass compilation via Webpack. Static files in `galactus/static/`. The Node container runs `npm run dev` for hot-reload. Webpack configs are in `webpack/`.

### Background Tasks

Celery with Redis broker. Tasks use `@shared_task` decorator. Celery Beat uses `django_celery_beat.schedulers:DatabaseScheduler` for periodic task scheduling. The Celery app is configured in `config/celery_app.py`.

### ASGI & WebSockets

`config/asgi.py` routes HTTP to Django and WebSocket connections to `config/websocket.py` (basic ping/pong handler). Production uses uvicorn.

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs on PRs/pushes to `main`:
1. **Linter job**: pre-commit hooks
2. **Pytest job**: builds Docker images, checks for pending migrations (`makemigrations --check`), runs migrations, then `pytest`
