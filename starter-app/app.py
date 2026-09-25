
import os

import redis
from flask import Flask, jsonify

app = Flask(__name__)

ALERT_THRESHOLD = 25


def get_redis_client():
    """Cree un client Redis a partir des variables d'environnement."""
    return redis.Redis(
        host=os.environ.get("REDIS_HOST", "localhost"),
        port=int(os.environ.get("REDIS_PORT", 6379)),
        decode_responses=True,
    )


def alert_threshold():
    """Seuil d'alerte au-dessus duquel une notification est declenchee."""
    return ALERT_THRESHOLD


def sanitize_input(value):
    """Echappe les caracteres dangereux d'une entree utilisateur."""
    return value.replace("<", "&lt;").replace(">", "&gt;")


@app.route("/health")
def health():
    try:
        get_redis_client().ping()
        return jsonify(status="ok"), 200
    except redis.exceptions.RedisError:
        return jsonify(status="error"), 503


@app.route("/status")
def status():
    return jsonify(
        service="projet-devops-groupe-demo",
        version="1.0",
        deploy_color=os.environ.get("NEW_COLOR", "unknown"),
    ), 200


@app.route("/visits")
def visits():
    client = get_redis_client()
    count = client.incr("visits")
    return jsonify(visits=count), 200


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0")
