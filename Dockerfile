# ==============================================================================
# STAGE 1 — BUILD
# ==============================================================================
FROM python:3.11-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /build

COPY app/requirements.txt .
RUN pip install --prefix=/install -r requirements.txt

# ==============================================================================
# STAGE 2 — RUNTIME
# ==============================================================================
FROM python:3.11-slim AS runtime

ARG APP_VERSION=1.0.0
ARG APP_USER=appuser
ARG APP_UID=1001

LABEL maintainer="devops@firma.de"
LABEL version=$APP_VERSION
LABEL description="Snake Game — DevOps Edition"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_ENV=production \
    APP_PORT=5000 \
    APP_VERSION=$APP_VERSION \
    PYTHONPATH=/install/lib/python3.11/site-packages \
    PATH="/install/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid $APP_UID $APP_USER \
    && useradd --uid $APP_UID --gid $APP_UID --no-create-home --shell /bin/false $APP_USER

WORKDIR /app

COPY --from=builder /install /install
COPY --chown=$APP_USER:$APP_USER app/ .

USER $APP_USER

EXPOSE 5000

HEALTHCHECK \
    --interval=30s \
    --timeout=5s \
    --start-period=10s \
    --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

CMD ["gunicorn", \
     "--bind", "0.0.0.0:5000", \
     "--workers", "2", \
     "--threads", "2", \
     "--timeout", "120", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "--log-level", "info", \
     "main:app"]
