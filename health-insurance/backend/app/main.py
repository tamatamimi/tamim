import datetime
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session

from app.config import settings
from app.database import SessionLocal, create_tables
from app.routers import auth, employees, family, claims, documents, settings as settings_router, reports

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Seed data
# ---------------------------------------------------------------------------

def _seed(db: Session) -> None:
    from app.models.models import InsuranceSettings, Employee, FamilyMember, User, GenderEnum, RelationEnum
    from app.core.security import hash_password

    # 1. Default insurance settings
    existing_settings = db.query(InsuranceSettings).first()
    if not existing_settings:
        default_settings = InsuranceSettings(
            name="الخطة التأمينية الافتراضية",
            inpatient_pct=90.00,
            outpatient_pct=70.00,
            employee_annual_limit=15000.00,
            family_annual_limit=10000.00,
            max_per_claim=5000.00,
            is_active=True,
        )
        db.add(default_settings)
        db.flush()
        logger.info("Seeded default InsuranceSettings (id=%d)", default_settings.id)
    else:
        default_settings = existing_settings

    # 2. Admin user
    if not db.query(User).filter(User.username == "admin").first():
        admin = User(
            username="admin",
            email="admin@insurance.local",
            hashed_password=hash_password("admin123"),
            is_active=True,
            is_superuser=True,
        )
        db.add(admin)
        logger.info("Seeded admin user (admin / admin123)")

    # 3. Sample employees
    if not db.query(Employee).filter(Employee.employee_id == "EMP-001").first():
        emp1 = Employee(
            employee_id="EMP-001",
            full_name="أحمد محمد العمري",
            national_id="1234567890",
            gender=GenderEnum.male,
            date_of_birth=datetime.date(1985, 3, 15),
            hire_date=datetime.date(2015, 6, 1),
            department="تقنية المعلومات",
            job_title="مطور برمجيات",
            phone="0501234567",
            email="ahmed@company.com",
            is_active=True,
            settings_id=default_settings.id,
        )
        db.add(emp1)
        db.flush()

        # Family members for emp1
        db.add(FamilyMember(
            employee_id=emp1.id,
            full_name="سارة أحمد العمري",
            national_id="2345678901",
            relation=RelationEnum.spouse,
            date_of_birth=datetime.date(1988, 7, 20),
            is_active=True,
        ))
        db.add(FamilyMember(
            employee_id=emp1.id,
            full_name="محمد أحمد العمري",
            relation=RelationEnum.son,
            date_of_birth=datetime.date(2012, 4, 10),
            is_active=True,
        ))
        logger.info("Seeded sample employee EMP-001 with 2 family members")

    if not db.query(Employee).filter(Employee.employee_id == "EMP-002").first():
        emp2 = Employee(
            employee_id="EMP-002",
            full_name="فاطمة خالد الزهراني",
            national_id="3456789012",
            gender=GenderEnum.female,
            date_of_birth=datetime.date(1990, 11, 5),
            hire_date=datetime.date(2018, 9, 15),
            department="الموارد البشرية",
            job_title="مختصة موارد بشرية",
            phone="0557654321",
            email="fatima@company.com",
            is_active=True,
            settings_id=default_settings.id,
        )
        db.add(emp2)
        db.flush()

        db.add(FamilyMember(
            employee_id=emp2.id,
            full_name="خالد عبدالله الزهراني",
            national_id="4567890123",
            relation=RelationEnum.father,
            date_of_birth=datetime.date(1958, 2, 28),
            is_active=True,
        ))
        logger.info("Seeded sample employee EMP-002 with 1 family member")

    db.commit()


# ---------------------------------------------------------------------------
# Lifespan
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Creating database tables…")
    create_tables()

    logger.info("Seeding initial data…")
    with SessionLocal() as db:
        try:
            _seed(db)
        except Exception as exc:
            logger.warning("Seed failed (probably already seeded): %s", exc)
            db.rollback()

    yield
    # Shutdown (nothing to clean up)


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------

app = FastAPI(
    title="نظام إدارة التأمين الصحي",
    description=(
        "نظام متكامل لإدارة مطالبات التأمين الصحي للموظفين وأسرهم، "
        "يدعم المرضى الداخليين (90%) والعيادات الخارجية والطوارئ (70%)."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# ---------------------------------------------------------------------------
# CORS
# ---------------------------------------------------------------------------

origins = [o.strip() for o in settings.ALLOWED_ORIGINS.split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------------

app.include_router(auth.router)
app.include_router(employees.router)
app.include_router(family.router)
app.include_router(claims.router)
app.include_router(documents.router)
app.include_router(settings_router.router)
app.include_router(reports.router)

# ---------------------------------------------------------------------------
# Static files (uploaded documents served at /uploads/...)
# ---------------------------------------------------------------------------

try:
    app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")
except RuntimeError:
    # Directory may not exist yet in some CI environments
    import os
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------

@app.get("/health", tags=["system"], summary="فحص الصحة")
def health_check():
    return {"status": "ok", "service": settings.APP_NAME}


@app.get("/", tags=["system"], include_in_schema=False)
def root():
    return {"message": "نظام إدارة التأمين الصحي — /docs للواجهة التفاعلية"}
