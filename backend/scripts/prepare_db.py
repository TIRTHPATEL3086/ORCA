"""Make sure PostGIS is enabled before migrations run.

ORCA's tables use PostGIS geography columns, so a fresh cloud database
needs the extension created once. Safe to run on every start.
"""

from sqlalchemy import text

from app.database import engine


def main() -> None:
    with engine.begin() as connection:
        connection.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        version = connection.execute(text("SELECT PostGIS_Version()")).scalar_one()
    print(f"PostGIS ready: {version}")


if __name__ == "__main__":
    main()
