# =============================================================================
# FILE: backend/app.py
# ROLE: Flask server entry point
# -----------------------------------------------------------------------------
# - Creates the Flask app via create_app() (defined in api/app_factory.py)
# - Runs on 0.0.0.0:5000 (all interfaces) so Android emulator can reach it
# - Debug mode ON for auto-reload during development
#
# HOW TO RUN:
#   cd backend
#   .\venv\Scripts\python.exe app.py
# =============================================================================
from api.app_factory import create_app


app = create_app()

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
