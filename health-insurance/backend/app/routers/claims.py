from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from decimal import Decimal
from typing import List, Optional
import datetime
from app.database import get_db
from app.models.models import (
    InsuranceClaim, Employee, FamilyMember, InsuranceSettings,
    ClaimStatusEnum, BeneficiaryTypeEnum
)
from app.schemas.schemas import ClaimCreate, ClaimStatusUpdate, ClaimOut
from app.services.insurance import calculator, get_annual_used

router = APIRouter(prefix="/api/claims", tags=["claims"])


def _get_settings(employee: Employee, db: Session) -> Optional[InsuranceSettings]:
    if employee.settings_id:
        return db.query(InsuranceSettings).filter(InsuranceSettings.id == employee.settings_id).first()
    return db.query(InsuranceSettings).filter(InsuranceSettings.is_active == True).first()


def _generate_claim_number(db: Session) -> str:
    year = datetime.date.today().year
    last = db.query(InsuranceClaim).order_by(InsuranceClaim.id.desc()).first()
    seq = (last.id + 1) if last else 1
    return f"CLM-{year}-{seq:05d}"


@router.get("", response_model=List[ClaimOut])
def list_claims(
    status: Optional[str] = None,
    claim_type: Optional[str] = None,
    employee_id: Optional[int] = None,
    year: Optional[int] = None,
    q: str = Query(""),
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    query = db.query(InsuranceClaim).options(
        joinedload(InsuranceClaim.employee),
        joinedload(InsuranceClaim.family_member),
        joinedload(InsuranceClaim.documents),
    )
    if status:
        query = query.filter(InsuranceClaim.status == status)
    if claim_type:
        query = query.filter(InsuranceClaim.claim_type == claim_type)
    if employee_id:
        query = query.filter(InsuranceClaim.employee_id == employee_id)
    if year:
        from sqlalchemy import extract
        query = query.filter(extract("year", InsuranceClaim.claim_date) == year)
    if q:
        query = query.join(Employee).filter(
            InsuranceClaim.claim_number.ilike(f"%{q}%") |
            Employee.full_name.ilike(f"%{q}%") |
            InsuranceClaim.hospital_name.ilike(f"%{q}%")
        )
    claims = query.order_by(InsuranceClaim.created_at.desc()).offset(skip).limit(limit).all()
    return _enrich_claims(claims)


def _enrich_claims(claims: list) -> list:
    result = []
    for c in claims:
        out = ClaimOut.model_validate(c)
        out.employee_name = c.employee.full_name if c.employee else ""
        if c.beneficiary_type == BeneficiaryTypeEnum.employee:
            out.beneficiary_name = c.employee.full_name if c.employee else ""
        else:
            out.beneficiary_name = c.family_member.full_name if c.family_member else ""
        result.append(out)
    return result


@router.post("", response_model=ClaimOut, status_code=201)
def create_claim(data: ClaimCreate, db: Session = Depends(get_db)):
    employee = db.query(Employee).filter(Employee.id == data.employee_id).first()
    if not employee:
        raise HTTPException(404, "الموظف غير موجود")

    if data.beneficiary_type == BeneficiaryTypeEnum.family and not data.family_member_id:
        raise HTTPException(400, "يجب تحديد فرد العائلة")

    settings = _get_settings(employee, db)
    if not settings:
        raise HTTPException(400, "لا توجد سياسة تأمين نشطة")

    # Get annual used for the correct beneficiary
    if data.beneficiary_type == BeneficiaryTypeEnum.employee:
        annual_used = get_annual_used(db, employee.id, data.claim_date.year, "employee")
        annual_limit = Decimal(str(settings.employee_annual_limit))
    else:
        annual_used = get_annual_used(db, employee.id, data.claim_date.year, "family", data.family_member_id)
        annual_limit = Decimal(str(settings.family_annual_limit))

    # Override settings limit for family
    if data.beneficiary_type == BeneficiaryTypeEnum.family:
        temp_settings = InsuranceSettings(
            inpatient_pct=settings.inpatient_pct,
            outpatient_pct=settings.outpatient_pct,
            employee_annual_limit=annual_limit,
            family_annual_limit=annual_limit,
            max_per_claim=settings.max_per_claim,
        )
        calc_result = calculator.calculate(
            data.invoice_amount, data.claim_type, temp_settings, annual_used
        )
    else:
        calc_result = calculator.calculate(
            data.invoice_amount, data.claim_type, settings, annual_used
        )

    claim = InsuranceClaim(
        claim_number=_generate_claim_number(db),
        **data.model_dump(),
        coverage_pct=calc_result["coverage_pct"],
        insurance_amount=calc_result["insurance_amount"],
        employee_amount=calc_result["employee_amount"],
        approved_amount=calc_result["insurance_amount"],
    )
    db.add(claim)
    db.commit()
    db.refresh(claim)

    # Reload with relationships
    claim = db.query(InsuranceClaim).options(
        joinedload(InsuranceClaim.employee),
        joinedload(InsuranceClaim.family_member),
        joinedload(InsuranceClaim.documents),
    ).filter(InsuranceClaim.id == claim.id).first()
    return _enrich_claims([claim])[0]


@router.get("/{id}", response_model=ClaimOut)
def get_claim(id: int, db: Session = Depends(get_db)):
    claim = db.query(InsuranceClaim).options(
        joinedload(InsuranceClaim.employee),
        joinedload(InsuranceClaim.family_member),
        joinedload(InsuranceClaim.documents),
    ).filter(InsuranceClaim.id == id).first()
    if not claim:
        raise HTTPException(404, "المطالبة غير موجودة")
    return _enrich_claims([claim])[0]


@router.put("/{id}/status", response_model=ClaimOut)
def update_claim_status(id: int, data: ClaimStatusUpdate, db: Session = Depends(get_db)):
    claim = db.query(InsuranceClaim).filter(InsuranceClaim.id == id).first()
    if not claim:
        raise HTTPException(404, "المطالبة غير موجودة")
    claim.status = data.status
    if data.approved_amount is not None:
        claim.approved_amount = data.approved_amount
    if data.notes is not None:
        claim.notes = data.notes
    if data.rejection_reason is not None:
        claim.rejection_reason = data.rejection_reason
    claim.updated_at = datetime.datetime.utcnow()
    db.commit()
    db.refresh(claim)

    claim = db.query(InsuranceClaim).options(
        joinedload(InsuranceClaim.employee),
        joinedload(InsuranceClaim.family_member),
        joinedload(InsuranceClaim.documents),
    ).filter(InsuranceClaim.id == id).first()
    return _enrich_claims([claim])[0]
