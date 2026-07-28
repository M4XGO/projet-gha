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