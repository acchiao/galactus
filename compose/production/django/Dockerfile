FROM docker.io/node:24.14-bookworm-slim AS client-builder

ARG APP_HOME=/app
WORKDIR ${APP_HOME}

COPY ./package.json ./package-lock.json ${APP_HOME}/
RUN --mount=type=cache,target=/root/.npm npm ci
# Only copy what the frontend build needs so npm build stays cached on
# backend-only changes.
COPY ./webpack ${APP_HOME}/webpack
COPY ./galactus/static ${APP_HOME}/galactus/static
RUN npm run build
# define an alias for the specific python version used in this file.
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS python-build-stage

ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy UV_PYTHON_DOWNLOADS=0

ARG APP_HOME=/app

WORKDIR ${APP_HOME}

# Install apt packages
RUN apt-get update && apt-get install --no-install-recommends -y \
  # dependencies for building Python packages
  build-essential \
  # psycopg dependencies
  libpq-dev


# Requirements are installed here to ensure they will be cached.
RUN --mount=type=cache,target=/root/.cache/uv \
  --mount=type=bind,source=uv.lock,target=uv.lock \
  --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
  uv sync --locked --no-install-project --no-dev

# Copy the application source, then install the project itself.
COPY . ${APP_HOME}

RUN --mount=type=cache,target=/root/.cache/uv \
  --mount=type=bind,source=uv.lock,target=uv.lock \
  --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
  uv sync --locked --no-dev

# Copy only the compiled frontend assets from the client build stage
# (avoids dragging node_modules into the Python image).
COPY --from=client-builder ${APP_HOME}/galactus/static/webpack_bundles ${APP_HOME}/galactus/static/webpack_bundles
COPY --from=client-builder ${APP_HOME}/webpack-stats.json ${APP_HOME}/webpack-stats.json

# Python 'run' stage
FROM python:3.13.14-slim-bookworm AS python-run-stage

ARG APP_HOME=/app

WORKDIR ${APP_HOME}

RUN addgroup --system django \
  && adduser --system --ingroup django django


# Install required system dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
  # psycopg dependencies
  libpq-dev \
  # Translations dependencies
  gettext \
  # entrypoint
  wait-for-it \
  # cleaning up unused files
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  && rm -rf /var/lib/apt/lists/*


COPY --chown=django:django ./compose/production/django/entrypoint /entrypoint
COPY --chown=django:django ./compose/production/django/start /start
COPY --chown=django:django ./compose/production/django/celery/worker/start /start-celeryworker
COPY --chown=django:django ./compose/production/django/celery/beat/start /start-celerybeat
COPY --chown=django:django ./compose/production/django/celery/flower/start /start-flower
RUN sed -i 's/\r$//g' /entrypoint /start /start-celeryworker /start-celerybeat /start-flower \
  && chmod +x /entrypoint /start /start-celeryworker /start-celerybeat /start-flower

# Copy the application from the builder
COPY --from=python-build-stage --chown=django:django ${APP_HOME} ${APP_HOME}

# make django owner of the WORKDIR directory as well.
RUN chown django:django ${APP_HOME}

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

USER django

RUN DATABASE_URL="" \
  DJANGO_SETTINGS_MODULE="config.settings.test" \
  python manage.py compilemessages

ENTRYPOINT ["/entrypoint"]
