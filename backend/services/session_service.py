# =============================================================================
# FILE: backend/services/session_service.py
# ROLE: Login/logout session tracking for the admin "Login Activity" view
# -----------------------------------------------------------------------------
# - A session row is created on every successful /login
# - /logout closes the most recent open session for that user
# - token_required (api/auth.py) best-effort "touches" last_activity on every
#   authenticated request, so admins can see how recently a user was active
# =============================================================================
from database import SessionLocal
import crud


def _session_to_dict(session, user=None):
    if not session:
        return None

    login_time = session.login_time
    logout_time = session.logout_time
    duration_seconds = None
    if login_time and logout_time:
        duration_seconds = (logout_time - login_time).total_seconds()

    data = {
        "session_id": session.session_id,
        "user_id": session.user_id,
        "login_time": login_time.isoformat() if login_time else None,
        "logout_time": logout_time.isoformat() if logout_time else None,
        "last_activity": session.last_activity.isoformat() if session.last_activity else None,
        "duration_seconds": duration_seconds,
        "is_active": logout_time is None,
    }
    if user is not None:
        data["user_name"] = user.name
        data["user_email"] = user.email
    return data


def start_session(user_id):
    with SessionLocal() as db:
        session = crud.create_login_session(db, user_id)
        return _session_to_dict(session)


def end_session(user_id):
    with SessionLocal() as db:
        session = crud.close_login_session(db, user_id)
        return _session_to_dict(session)


def touch_activity(user_id):
    """Best-effort — never raise, this runs on every authenticated request."""
    try:
        with SessionLocal() as db:
            crud.touch_last_activity(db, user_id)
    except Exception:
        pass


def list_all_sessions():
    with SessionLocal() as db:
        rows = crud.get_all_login_sessions(db)
        return [_session_to_dict(session, user) for session, user in rows]
