from flask import Flask
from flask_cors import CORS

from api.routes.admin_routes import admin_bp
from api.routes.alerts_routes import alerts_bp
from api.routes.auth_routes import auth_bp
from api.routes.food_routes import food_bp
from api.routes.health import health_bp
from api.routes.predict_routes import predict_bp
from api.routes.tracking_routes import tracking_bp


def create_app():
    """Application factory — registers all API route blueprints."""
    app = Flask(__name__)
    CORS(app)

    app.register_blueprint(health_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(food_bp)
    app.register_blueprint(predict_bp)
    app.register_blueprint(tracking_bp)
    app.register_blueprint(alerts_bp)
    app.register_blueprint(admin_bp)

    return app

