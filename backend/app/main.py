from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.api.dependencies import require_roles
from app.api.routes.auth import router as auth_router
from app.api.routes.fisherman import router as fisherman_router
from app.api.routes.gis import router as gis_router
from app.api.routes.habitat import router as habitat_router
from app.api.routes.marine import router as marine_router
from app.api.routes.orca_agent import router as orca_agent_router
from app.database import engine
from app.models.user import User

app = FastAPI(
    title="ORCA Marine Intelligence API",
    description=(
        "Backend service for the ORCA Agentic Marine Intelligence Platform."
    ),
    version="0.1.0",
)

app.include_router(auth_router)
app.include_router(fisherman_router)
app.include_router(marine_router)
app.include_router(gis_router)
app.include_router(orca_agent_router)
app.include_router(habitat_router)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {
        "application": "ORCA",
        "full_name": "Marine Intelligence Platform",
        "version": "0.1.0",
        "status": "running",
    }

@app.get("/api/v1/health")
def health():
    return {
        "status": "healthy",
        "service": "orca-backend",
        "version": "0.1.0",
    }

@app.get("/api/v1/meta/roles")
def get_roles():
    return {
        "roles": [
            {"code": "FISHERMAN", "name": "Fisherman", "interface": "mobile"},
            {"code": "RESEARCHER", "name": "Marine Researcher", "interface": "web"},
            {"code": "AUTHORITY", "name": "Coastal Authority", "interface": "web"},
            {"code": "ADMIN", "name": "Administrator", "interface": "web"},
        ]
    }

@app.get("/api/v1/database/health")
def database_health():
    try:
        with engine.connect() as connection:
            database_name = connection.execute(text("SELECT current_database();")).scalar_one()
            database_user = connection.execute(text("SELECT current_user;")).scalar_one()
            postgis_version = connection.execute(text("SELECT PostGIS_Version();")).scalar_one()
        return {
            "status": "healthy",
            "database": database_name,
            "user": database_user,
            "postgis": postgis_version,
        }
    except SQLAlchemyError:
        return {"status": "unhealthy", "database": "connection_failed"}

@app.get("/api/v1/test/fisherman")
def fisherman_test(current_user: User = Depends(require_roles("FISHERMAN"))):
    return {"message": "Fisherman access granted.", "user": current_user.email}

@app.get("/api/v1/test/researcher")
def researcher_test(current_user: User = Depends(require_roles("RESEARCHER"))):
    return {"message": "Researcher access granted.", "user": current_user.email}

@app.get("/api/v1/test/authority")
def authority_test(current_user: User = Depends(require_roles("AUTHORITY", "ADMIN"))):
    return {"message": "Authority access granted.", "user": current_user.email}
