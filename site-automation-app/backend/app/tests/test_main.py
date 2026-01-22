from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app, get_db
from app.database import Base
from app.schemas import UserCreate, ProjectCreate
from app.crud import create_user

SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)

def override_get_db():
    try {
        db = TestingSessionLocal()
        yield db
    } finally {
        db.close()
    }

app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

def test_create_user():
    response = client.post(
        "/token",
        data={"username": "testuser", "password": "testpassword"},
    )
    assert response.status_code == 200
    assert "access_token" in response.json()
    assert response.json()["token_type"] == "bearer"

def test_create_project():
    db = next(override_get_db())
    user = create_user(db, UserCreate(username="testuser", password="testpassword", role="Site Administrator"))
    access_token = client.post(
        "/token",
        data={"username": "testuser", "password": "testpassword"},
    ).json()["access_token"]

    response = client.post(
        "/projects/",
        json={"name": "Test Project", "status": "Draft"},
        headers={"Authorization": `Bearer ${access_token}`},
    )
    assert response.status_code == 200
    assert response.json()["name"] == "Test Project"
    assert response.json()["status"] == "Draft"

def test_read_projects():
    db = next(override_get_db())
    user = create_user(db, UserCreate(username="testuser", password="testpassword", role="Site Administrator"))
    access_token = client.post(
        "/token",
        data={"username": "testuser", "password": "testpassword"},
    ).json()["access_token"]

    response = client.get(
        "/projects/",
        headers={"Authorization": `Bearer ${access_token}`},
    )
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_read_project():
    db = next(override_get_db())
    user = create_user(db, UserCreate(username="testuser", password="testpassword", role="Site Administrator"))
    access_token = client.post(
        "/token",
        data={"username": "testuser", "password": "testpassword"},
    ).json()["access_token"]

    project = client.post(
        "/projects/",
        json={"name": "Test Project", "status": "Draft"},
        headers={"Authorization": `Bearer ${access_token}`},
    ).json()

    response = client.get(
        `/projects/${project['id']}`,
        headers={"Authorization": `Bearer ${access_token}`},
    )
    assert response.status_code == 200
    assert response.json()["name"] == "Test Project"
    assert response.json()["status"] == "Draft"

def test_update_project():
    db = next(override_get_db())
    user = create_user(db, UserCreate(username="testuser", password="testpassword", role="Site Administrator"))
    access_token = client.post(
        "/token",
        data={"username": "testuser", "password": "testpassword"},
    ).json()["access_token"]

    project = client.post(
        "/projects/",
        json={"name": "Test Project", "status": "Draft"},
        headers={"Authorization": `Bearer ${access_token}`},
    ).json()

    response = client.put(
        `/projects/${project['id']}`,
        json={"name": "Updated Project", "status": "In Setup"},
        headers={"Authorization": `Bearer ${access_token}`},
    )
    assert response.status_code == 200
    assert response.json()["name"] == "Updated Project"
    assert response.json()["status"] == "In Setup"

def test_delete_project():
    db = next(override_get_db())
    user = create_user(db, UserCreate(username="testuser", password="testpassword", role="Site Administrator"))
    access_token = client.post(
        "/token",
        data={"username": "testuser", "password": "testpassword"},
    ).json()["access_token"]

    project = client.post(
        "/projects/",
        json={"name": "Test Project", "status": "Draft"},
        headers={"Authorization": `Bearer ${access_token}`},
    ).json()

    response = client.delete(
        `/projects/${project['id']}`,
        headers={"Authorization": `Bearer ${access_token}`},
    )
    assert response.status_code == 200
    assert response.json()["name"] == "Test Project"
    assert response.json()["status"] == "Draft"