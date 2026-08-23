# Stage 1: Builder
FROM python:3.10-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .

# Upgrade pip, setuptools, dan msgpack ke versi spesifik yang aman
RUN pip install --no-cache-dir --upgrade pip setuptools==78.1.1 wheel \
    && pip install --no-cache-dir --force-reinstall -r requirements.txt

# Stage 2: Runner
FROM python:3.10-slim AS runner

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Upgrade OS Packages
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# BERSIHKAN TOTAL seluruh paket bawaan OS Debian di semua path Python
RUN rm -rf /usr/local/lib/python3.10/site-packages/* \
    && rm -rf /usr/local/lib/python3.10/dist-packages/* \
    && rm -rf /usr/lib/python3.10/site-packages/* \
    && rm -rf /usr/lib/python3.10/dist-packages/*

COPY --from=builder /opt/venv /opt/venv
COPY . .

RUN addgroup --system appuser && adduser --system --group appuser \
    && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
