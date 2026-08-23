FROM python:3.10-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .

# 1. Install compiler sementara
# 2. Upgrade paket dan paksa install versi aman
# 3. HAPUS PAKSA sisa direktori metadata versi lama yang mengelabui Trivy
RUN apk add --no-cache --virtual .build-deps gcc musl-dev python3-dev \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir msgpack==1.2.1 setuptools==78.1.1 \
    && find /usr -type d -name "setuptools-70.3.0*" -exec rm -rf {} + \
    && find /usr -type d -name "msgpack-1.1.2*" -exec rm -rf {} + \
    && apk del .build-deps

COPY . .

RUN addgroup -S appuser && adduser -S appuser -G appuser \
    && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
