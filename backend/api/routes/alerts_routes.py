from flask import Blueprint, jsonify, request

from api.auth import get_current_user_id, token_required
from services import tracking_service
from services.analytics_service import get_all_alerts

alerts_bp = Blueprint("alerts", __name__)


@alerts_bp.route("/alerts", methods=["GET"])
@alerts_bp.route("/alerts/<int:user_id>", methods=["GET"])
@token_required
def get_alerts(user_id=None):
    auth_user_id = get_current_user_id()
    if user_id and user_id != auth_user_id:
        return jsonify({"error": "Unauthorized access"}), 403

    user_id = auth_user_id
    days = request.args.get("days", 30, type=int)
    days = min(max(days, 1), 90)

    history = tracking_service.get_daily_history(user_id, days=days)
    alert_list = get_all_alerts(history)

    return jsonify({
        "user_id": user_id,
        "alert_count": len(alert_list),
        "alerts": alert_list,
    }), 200
