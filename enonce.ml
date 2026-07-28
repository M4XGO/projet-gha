Objet: Déployer une application avec:

Récupérer le dépôt                     ✓
Afficher les versions                  ✓
Construire l'image Docker              ✓
Exécuter les tests unitaires           ✓
Démarrer le conteneur                  ✓
Attendre que l'application...          ✓
Afficher l'état des conteneurs         ✓
Afficher les logs en cas d'échec       -
Nettoyer les ressources                ✓


—-----------------------
*Créer repository Github:



tp9-github-actions/
├── Dockerfile
├── app.py
├── test_app.py
├── requirements.txt
└── .github/
    └── workflows/
        └── ci.yml
—---------------------------

Créer app.py

cat > app.py <<'EOF'
from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def home():
    return jsonify(
        message="Bienvenue dans le TP GitHub Actions",
        version="1.0"
    ), 200


@app.get("/health")
def health():
    return jsonify(status="ok"), 200


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000
    )
EOF

—------------

Créer fichier Dockerfile

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .

RUN pip install \
    --no-cache-dir \
    -r requirements.txt

COPY app.py test_app.py ./

RUN useradd \
    --create-home \
    --uid 10001 \
    appuser

USER appuser

EXPOSE 5000

HEALTHCHECK \
    --interval=10s \
    --timeout=3s \
    --start-period=5s \
    --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/health')"

CMD ["python", "app.py"]

—------------------------------------



Créer test_app.py

cat > test_app.py <<'EOF'
from app import app


def test_home():
    client = app.test_client()

    response = client.get("/")

    assert response.status_code == 200
    assert response.get_json()["version"] == "1.0"


def test_health():
    client = app.test_client()

    response = client.get("/health")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}
EOF



Créér requirements.txt 

cat > requirements.txt <<'EOF'
Flask>=3.0,<4
pytest>=8,<9
EOF


Envoie fichiers github

git add Dockerfile app.py test_app.py requirements.txt
git commit -m "Ajout de l'application Flask et des tests"
git push


Créer fichier ci.yml  (dans .github/workflows/ci.yml)

name: CI Docker

on:
  push:
    branches:
      - main

  pull_request:
    branches:
      - main

  workflow_dispatch:

permissions:
  contents: read

env:
  IMAGE_NAME: tp9-app

jobs:
  test-build-run:
    name: Tests, build et validation Docker

    runs-on: ubuntu-24.04

    timeout-minutes: 10

    steps:
      - name: Récupérer le dépôt
        uses: actions/checkout@v6

      - name: Afficher les versions
        run: |
          docker version
          docker buildx version

      - name: Construire l'image Docker
        run: |
          docker build \
            --tag "${IMAGE_NAME}:${GITHUB_SHA}" \
            .

      - name: Exécuter les tests unitaires
        run: |
          docker run \
            --rm \
            "${IMAGE_NAME}:${GITHUB_SHA}" \
            pytest -q

      - name: Démarrer le conteneur
        run: |
          docker run \
            --detach \
            --name tp9-app \
            --publish 8080:5000 \
            "${IMAGE_NAME}:${GITHUB_SHA}"

      - name: Attendre que l'application soit disponible
        run: |
          for attempt in {1..15}; do
            echo "Tentative ${attempt}/15"

            if curl \
              --fail \
              --silent \
              --show-error \
              http://127.0.0.1:8080/health
            then
              echo
              echo "Application disponible"
              exit 0
            fi

            sleep 2
          done

          echo "La route /health ne répond pas correctement"
          exit 1

      - name: Afficher l'état des conteneurs
        if: ${{ !cancelled() }}
        run: docker ps -a

      - name: Afficher les logs en cas d'échec
        if: ${{ failure() }}
        run: docker logs tp9-app || true

      - name: Nettoyer les ressources
        if: ${{ always() }}
        run: docker rm -f tp9-app || true


Envoie fichier dans github

Vérifier dans onglet “actions” le déroulement du pipeline. Corriger les erreurs jusqu’au succés
Mettre dans le repo dans un fichier “readme” à la racine les corrections et explications apportées
