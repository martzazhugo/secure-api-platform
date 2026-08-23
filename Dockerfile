# Stage 1: Build & Install
FROM python:3.10-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .

# Force upgrade seluruh dependensi dan sub-dependensi (termasuk msgpack)
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir --upgrade --upgrade-strategy eager -r requirements.txt \
    && pip uninstall -y setuptools wheel

# Stage 2: Final Runtime Image
FROM python:3.10-slim AS runner

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Copy virtualenv bersih dari builder stage
COPY --from=builder /opt/venv /opt/venv
COPY . .

RUN addgroup --system appuser && adduser --system --group appuser \
    && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
