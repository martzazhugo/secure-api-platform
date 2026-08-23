# STAGE 1: Build
FROM python:3.10-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && pip uninstall -y wheel jaraco.context || true

# STAGE 2: Runtime
FROM python:3.10-slim AS runner

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Hapus seluruh paket Python global OS bawaan Debian yang dibaca Trivy
RUN rm -rf /usr/local/lib/python3.10/site-packages/*

COPY --from=builder /opt/venv /opt/venv
COPY . .

RUN addgroup --system appuser && adduser --system --group appuser \
    && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
