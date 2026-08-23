# STAGE 1: Builder
FROM python:3.10-slim-bookworm AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .

# Install paket, lalu HAPUS setuptools, pip, dan wheel dari virtualenv
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && rm -rf /opt/venv/lib/python3.10/site-packages/setuptools* \
    && rm -rf /opt/venv/lib/python3.10/site-packages/pip* \
    && rm -rf /opt/venv/lib/python3.10/site-packages/wheel*

# STAGE 2: Clean Runtime
FROM python:3.10-slim-bookworm AS runner

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Update paket OS Debian 12 Stable
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Bersihkan python global bawaan OS
RUN rm -rf /usr/local/lib/python3.10/site-packages/*

COPY --from=builder /opt/venv /opt/venv
COPY . .

RUN addgroup --system appuser && adduser --system --group appuser \
    && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
