from flask import Blueprint, jsonify

health_bp = Blueprint("health", __name__)


@health_bp.route("/")
def home():
    return jsonify({
        "status": "running",
        "app": "Calorie Monitoring API",
        "version": "2.0",
        "note": "API-only backend — database & ML layers on separate branches",
    })


@health_bp.route("/api/endpoints")
def list_endpoints():
    return jsonify({
        "auth": {
            "POST /register": "Register a new user",
            "POST /login": "Login and receive JWT token",
        },
        "food": {
            "GET /search?q=": "Search food catalog",
            "GET /food/<name>": "Get food nutrition details",
            "POST /manual": "Add custom food entry (requires auth)",
        },
        "tracking": {
            "POST /log": "Log food intake (requires auth)",
            "GET /daily": "Today's calorie total (requires auth)",
            "GET /weekly": "7-day summary (requires auth)",
            "GET /history?days=30": "Calorie history (requires auth)",
        },
        "alerts": {
            "GET /alerts?days=30": "Calorie spike & pattern alerts (requires auth)",
        },
    })
