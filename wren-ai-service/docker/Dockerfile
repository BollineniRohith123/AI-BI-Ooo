# reference: https://medium.com/@albertazzir/blazing-fast-python-docker-builds-with-poetry-a78a66f5aed0
FROM python:3.12.0-bookworm as builder

RUN pip install poetry==1.8.3

ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

WORKDIR /app

COPY pyproject.toml poetry.lock ./

RUN poetry install --without dev,eval,test --no-root && rm -rf $POETRY_CACHE_DIR

FROM python:3.12.0-slim-bookworm as runtime

# Install only necessary dependencies and clean up in same layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    netcat-traditional \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user for security
RUN groupadd -g 1001 appuser && \
    useradd -u 1001 -g appuser -s /bin/bash -m appuser

# Set up virtual environment
ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Copy only the virtual environment from builder
COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

WORKDIR /app

# Copy application files
COPY src src
COPY entrypoint.sh /app/entrypoint.sh
COPY pyproject.toml pyproject.toml

# Set proper permissions
RUN chmod +x /app/entrypoint.sh && \
    chown -R appuser:appuser /app

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:${WREN_AI_SERVICE_PORT:-8000}/health || exit 1

# Switch to non-root user
USER appuser

ENTRYPOINT [ "/app/entrypoint.sh" ]