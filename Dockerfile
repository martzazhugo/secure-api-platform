# ==========================================
# STAGE 1: Builder (Compile & Install Dependencies)
# ==========================================
FROM python:3.10-slim AS builder

WORKDIR /app

# Install compiler agar pip bisa nge-build msgpack >= 1.2.1 dari source jika diperlukan
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Buat Virtual Environment terisolasi
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .

# Upgrade pip, install requirements (termasuk msgpack 1.2.1), lalu hapus setuptools & wheel dari venv
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && pip uninstall -y setuptools wheel jaraco.context || true

# ==========================================
# STAGE 2: Runner (Clean Production Image)
# ==========================================
FROM python:3.10-slim AS runner

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Upgrade OS Package untuk menutupi celah keamanan level Linux OS
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# HAPUS SELURUH paket Python bawaan OS Debian agar Trivy tidak mendeteksi setuptools/wheel/jaraco bawaan
RUN rm -rf /usr/local/lib/python3.10/site-packages/*

# Copy Virtual Environment yang sudah bersih & ter-compile dari stage builder
COPY --from=builder /opt/venv /opt/venv

COPY . .

RUN addgroup --system appuser && adduser --system --group appuser \
    && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
