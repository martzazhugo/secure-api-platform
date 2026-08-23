FROM python:3.10-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install build dependencies sementara untuk compile msgpack & package C lainnya
RUN apk add --no-cache --virtual .build-deps gcc musl-dev python3-dev \
    && apk add --no-cache curl

COPY requirements.txt .

# Upgrade pip & install dependensi tanpa menyisakan paket build
RUN pip install --no-cache-dir --upgrade pip setuptools>=78.1.1 wheel \
    && pip install --no-cache-dir -r requirements.txt \
    && apk del .build-deps

COPY . .

RUN addgroup -S appuser && adduser -S appuser -G appuser \
    && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
