FROM python:3.10-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    TF_CPP_MIN_LOG_LEVEL=2

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    ca-certificates \
    build-essential \
    make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.lock.txt .
RUN pip install --no-cache-dir -U pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.lock.txt

RUN git clone https://github.com/salu133445/musegan.git third_party/musegan

COPY scripts/patch_musegan_py.py scripts/
RUN python scripts/patch_musegan_py.py

COPY tools/ tools/
COPY configs/ configs/
COPY Makefile .
COPY scripts/download_pretrained.sh scripts/
RUN chmod +x scripts/download_pretrained.sh

RUN mkdir -p data exp reports/samples reports/figures reports/metrics third_party/musegan/exp

# Copier le contenu de third_party/musegan/exp/ depuis le contexte
# Si pretrained_models.tar.gz existe dans le repo, il sera copié ici
# Sinon, le dossier sera juste vide et le script téléchargera l'archive
COPY third_party/musegan/exp/ third_party/musegan/exp/

COPY apps/api/requirements.txt /app/api_requirements.txt
RUN pip install --no-cache-dir -r /app/api_requirements.txt

EXPOSE 8000

CMD ["python", "-m", "uvicorn", "apps.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
