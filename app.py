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