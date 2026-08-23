FROM python:3.10-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install build tools untuk compile msgpack 1.2.1
RUN apk add --no-cache --virtual .build-deps gcc musl-dev python3-dev \
    && apk add --no-cache curl

COPY requirements.txt .

# 1. Upgrade pip
# 2. Force install msgpack 1.2.1 secara spesifik
# 3. Install sisa requirements
# 4. Hapus setuptools & wheel agar Trivy tidak mendeteksi CVE-2025-47273
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir --force-reinstall "msgpack>=1.2.1" \
    && pip install --no-cache-dir -r requirements.txt \
    && pip uninstall -y setuptools wheel \
    && apk del .build-deps

COPY . .

RUN addgroup -S appuser && adduser -S appuser -G appuser \
    && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
