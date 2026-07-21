# =============================================================================
# FILE: backend/migrate_add_role.py
# ROLE: One-time (idempotent, safe to re-run) migration script.
#       Adds everything needed for the Admin Panel to an EXISTING database:
#         - users.role
#         - users.created_at
#         - food_logs.logged_at
#         - login_sessions table (new table — auto-created)
#       Also lets you promote a user to admin.
#
# Usage:
#   python migrate_add_role.py                     # just runs the migration
#   python migrate_add_role.py you@example.com      # migration + makes this user admin
# =============================================================================
import sys
from datetime import datetime
from sqlalchemy import text
from database import engine, SessionLocal, use_sqlite
from models import Base, User, FoodLog

# 1. Create any brand-new tables (e.g. login_sessions). Existing tables are untouched.
Base.metadata.create_all(bind=engine)


def _add_column_if_missing(table, column, ddl_type_sqlite, ddl_type_mysql):
    with engine.connect() as conn:
        if use_sqlite:
            cols = [row[1] for row in conn.execute(text(f"PRAGMA table_info({table})"))]
            if column not in cols:
                conn.execute(text(f"ALTER TABLE {table} ADD COLUMN {column} {ddl_type_sqlite}"))
                conn.commit()
                print(f"Added '{column}' column to {table} (SQLite).")
            else:
                print(f"'{column}' column already exists on {table}.")
        else:
            result = conn.execute(text(f"""
                SELECT COUNT(*) FROM information_schema.columns
                WHERE table_name = '{table}' AND column_name = '{column}'
            """))
            if result.scalar() == 0:
                conn.execute(text(f"ALTER TABLE {table} ADD COLUMN {column} {ddl_type_mysql}"))
                conn.commit()
                print(f"Added '{column}' column to {table} (MySQL).")
            else:
                print(f"'{column}' column already exists on {table}.")


# 2. users.role
_add_column_if_missing("users", "role", "VARCHAR(20) DEFAULT 'user'", "VARCHAR(20) DEFAULT 'user'")
# 3. users.created_at
_add_column_if_missing("users", "created_at", "DATETIME", "DATETIME NULL")
# 4. food_logs.logged_at
_add_column_if_missing("food_logs", "logged_at", "DATETIME", "DATETIME NULL")

# 5. Backfill NULLs so existing rows don't break admin screens
with SessionLocal() as db:
    now = datetime.utcnow()
    db.query(User).filter(User.role.is_(None)).update({User.role: "user"})
    db.query(User).filter(User.created_at.is_(None)).update({User.created_at: now})
    db.query(FoodLog).filter(FoodLog.logged_at.is_(None)).update({FoodLog.logged_at: now})
    db.commit()
    print("Backfilled NULL values on existing rows.")

# 6. Optionally promote a user to admin
if len(sys.argv) > 1:
    email = sys.argv[1].strip().lower()
    with SessionLocal() as db:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            print(f"No user found with email: {email}")
        else:
            user.role = "admin"
            db.commit()
            print(f"'{email}' is now an admin.")

print("Migration complete.")
