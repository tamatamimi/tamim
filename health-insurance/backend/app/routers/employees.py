from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func
from decimal import Decimal
from typing import List, Optional
import datetime
from app.database import get_db
from app.models.models import Employee, FamilyMember, InsuranceSettings, InsuranceClaim, ClaimStatusEnum
from app.schemas.schemas import EmployeeCreate, EmployeeUpdate, EmployeeOut, EmployeeWithStats, FamilyMemberOut
from app.services.insurance import get_annual_used

router = APIRouter(prefix="/api/employees", tags=["employees"])


def _get_settings(employee: Employee, db: Session) -> Optional[InsuranceSettings]:
    if employee.settings_id:
        return db.query(InsuranceSettings).filter(InsuranceSettings.id == employee.settings_id).first()
    return db.query(InsuranceSettings).filter(InsuranceSettings.is_active == True).first()


@router.get("", response_model=List[EmployeeOut])
def list_employees(
    q: str = Query("", description="Search"),
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    query = db.query(Employee).options(joinedload(Employee.family_members)).filter(Employee.is_active == True)
    if q:
        query = query.filter(
            Employee.full_name.ilike(f"%{q}%") |
            Employee.employee_id.ilike(f"%{q}%") |
            Employee.department.ilike(f"%{q}%")
        )
    return query.offset(skip).limit(limit).all()


@router.post("", response_model=EmployeeOut, status_code=201)
def create_employee(data: EmployeeCreate, db: Session = Depends(get_db)):
    if db.query(Employee).filter(Employee.employee_id == data.employee_id).first():
        raise HTTPException(400, "رقم الموظف مستخدم مسبقاً")
    if db.query(Employee).filter(Employee.national_id == data.national_id).first():
        raise HTTPException(400, "رقم الهوية مستخدم مسبقاً")
    emp = Employee(**data.model_dump())
    db.add(emp)
    db.commit()
    db.refresh(emp)
    return emp


@router.get("/{id}", response_model=EmployeeWithStats)
def get_employee(id: int, year: Optional[int] = None, db: Session = Depends(get_db)):
    emp = db.query(Employee).options(
        joinedload(Employee.family_members),
        joinedload(Employee.settings),
    ).filter(Employee.id == id).first()
    if not emp:
        raise HTTPException(404, "الموظف غير موجود")

    year = year or datetime.date.today().year
    settings = _get_settings(emp, db)
    annual_limit = Decimal(str(settings.employee_annual_limit)) if settings else Decimal("0")
    used = get_annual_used(db, emp.id, year, "employee")
    remaining = max(annual_limit - used, Decimal("0"))
    usage_pct = (used / annual_limit * 100).quantize(Decimal("0.1")) if annual_limit > 0 else Decimal("0")

    result = EmployeeWithStats.model_validate(emp)
    result.annual_used = used
    result.annual_remaining = remaining
    result.annual_limit = annual_limit
    result.usage_pct = usage_pct
    result.settings = settings
    return result


@router.put("/{id}", response_model=EmployeeOut)
def update_employee(id: int, data: EmployeeUpdate, db: Session = Depends(get_db)):
    emp = db.query(Employee).filter(Employee.id == id).first()
    if not emp:
        raise HTTPException(404, "الموظف غير موجود")
    for k, v in data.model_dump().items():
        setattr(emp, k, v)
    db.commit()
    db.refresh(emp)
    return emp


@router.delete("/{id}")
def delete_employee(id: int, db: Session = Depends(get_db)):
    emp = db.query(Employee).filter(Employee.id == id).first()
    if not emp:
        raise HTTPException(404, "الموظف غير موجود")
    emp.is_active = False
    db.commit()
    return {"message": "تم حذف الموظف"}


@router.get("/{id}/family", response_model=List[FamilyMemberOut])
def get_family(id: int, year: Optional[int] = None, db: Session = Depends(get_db)):
    emp = db.query(Employee).filter(Employee.id == id).first()
    if not emp:
        raise HTTPException(404, "الموظف غير موجود")
    year = year or datetime.date.today().year
    settings = _get_settings(emp, db)
    family_limit = Decimal(str(settings.family_annual_limit)) if settings else Decimal("0")

    members = db.query(FamilyMember).filter(
        FamilyMember.employee_id == id,
        FamilyMember.is_active == True,
    ).all()

    result = []
    for m in members:
        used = get_annual_used(db, emp.id, year, "family", m.id)
        remaining = max(family_limit - used, Decimal("0"))
        out = FamilyMemberOut.model_validate(m)
        out.annual_used = used
        out.annual_remaining = remaining
        result.append(out)
    return result
