FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Upgrade paket OS
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# 1. Upgrade pip & install requirements tanpa cache
# 2. Hapus setuptools, wheel, dan jaraco setelah install selesai
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir --upgrade -r requirements.txt \
    && pip uninstall -y setuptools wheel || true \
    && rm -rf /usr/local/lib/python3.10/site-packages/setuptools* \
    && rm -rf /usr/local/lib/python3.10/site-packages/wheel* \
    && rm -rf /usr/local/lib/python3.10/site-packages/jaraco*

COPY . .

RUN addgroup --system appuser && adduser --system --group appuser \
    && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
