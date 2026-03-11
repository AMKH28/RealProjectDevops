from flask import Flask, jsonify, render_template
import time
import os

app = Flask(__name__)

# In-memory highscore list (kein DB nötig)
highscores = []
start_time = time.time()

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/health")
def health():
    """Kubernetes Liveness Probe Endpoint"""
    return jsonify({
        "status": "healthy",
        "uptime_seconds": round(time.time() - start_time, 2),
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "environment": os.getenv("APP_ENV", "development")
    }), 200

@app.route("/ready")
def ready():
    """Kubernetes Readiness Probe Endpoint"""
    return jsonify({"status": "ready"}), 200

@app.route("/api/highscores", methods=["GET"])
def get_highscores():
    """Top 10 Highscores zurückgeben"""
    sorted_scores = sorted(highscores, key=lambda x: x["score"], reverse=True)[:10]
    return jsonify(sorted_scores)

@app.route("/api/highscores/<name>/<int:score>", methods=["POST"])
def add_highscore(name, score):
    """Neuen Highscore speichern"""
    entry = {
        "name": name[:20],  # Max 20 Zeichen
        "score": score,
        "timestamp": time.strftime("%Y-%m-%d %H:%M")
    }
    highscores.append(entry)
    return jsonify({"message": "Score saved!", "entry": entry}), 201

@app.route("/api/info")
def info():
    """App-Info für DevOps Monitoring"""
    return jsonify({
        "app": "Snake Game",
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "environment": os.getenv("APP_ENV", "development"),
        "total_scores": len(highscores),
    })

if __name__ == "__main__":
    port = int(os.getenv("APP_PORT", 5000))
    debug = os.getenv("APP_ENV", "development") == "development"
    app.run(host="0.0.0.0", port=port, debug=debug)
