# 1. Gunakan minimal base image (Debian Slim / Alpine) untuk mengurangi attack surface
FROM python:3.10-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install dependensi sistem secara minimal
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy dan install requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy sisa kode aplikasi
COPY . .

# SECURITY HARDENING: Buat non-root user dan berikan kepemilikan folder
RUN addgroup --system appuser && adduser --system --group appuser \
    && chown -R appuser:appuser /app

# Pindah ke non-root user
USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
