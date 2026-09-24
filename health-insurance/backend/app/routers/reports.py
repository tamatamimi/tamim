from decimal import Decimal
from typing import List, Optional
import datetime

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, extract

from app.database import get_db
from app.models.models import (
    InsuranceClaim, Employee, InsuranceSettings,
    ClaimStatusEnum, ClaimTypeEnum, BeneficiaryTypeEnum,
)
from app.schemas.schemas import (
    ReportSummary, ClaimTypeStat, MonthlyStats, EmployeeReport,
)
from app.services.insurance import get_annual_used

router = APIRouter(prefix="/api/reports", tags=["reports"])

ARABIC_MONTHS = [
    "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
    "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر",
]

CLAIM_TYPE_LABELS = {
    ClaimTypeEnum.inpatient.value: "مريض داخلي",
    ClaimTypeEnum.outpatient.value: "عيادات خارجية",
    ClaimTypeEnum.emergency.value: "طوارئ",
}


@router.get("/summary", response_model=ReportSummary, summary="ملخص تقرير التأمين")
def get_summary(
    year: int = Query(default=None),
    db: Session = Depends(get_db),
):
    year = year or datetime.date.today().year

    base = db.query(InsuranceClaim).filter(
        extract("year", InsuranceClaim.claim_date) == year
    )

    total_claims = base.count()
    pending_claims = base.filter(InsuranceClaim.status == ClaimStatusEnum.pending).count()
    total_employees = db.query(func.count(func.distinct(InsuranceClaim.employee_id))).filter(
        extract("year", InsuranceClaim.claim_date) == year
    ).scalar() or 0

    agg = db.query(
        func.coalesce(func.sum(InsuranceClaim.invoice_amount), 0).label("total_invoice"),
        func.coalesce(func.sum(InsuranceClaim.insurance_amount), 0).label("total_insurance"),
        func.coalesce(func.sum(InsuranceClaim.employee_amount), 0).label("total_employee"),
    ).filter(extract("year", InsuranceClaim.claim_date) == year).first()

    # By type
    by_type_rows = db.query(
        InsuranceClaim.claim_type,
        func.count(InsuranceClaim.id).label("count"),
        func.coalesce(func.sum(InsuranceClaim.invoice_amount), 0).label("total_invoice"),
        func.coalesce(func.sum(InsuranceClaim.insurance_amount), 0).label("total_insurance"),
    ).filter(
        extract("year", InsuranceClaim.claim_date) == year
    ).group_by(InsuranceClaim.claim_type).all()

    by_type = [
        ClaimTypeStat(
            claim_type=row.claim_type,
            label=CLAIM_TYPE_LABELS.get(row.claim_type, row.claim_type),
            count=row.count,
            total_invoice=Decimal(str(row.total_invoice)),
            total_insurance=Decimal(str(row.total_insurance)),
        )
        for row in by_type_rows
    ]

    # Monthly
    monthly_rows = db.query(
        extract("month", InsuranceClaim.claim_date).label("month"),
        func.count(InsuranceClaim.id).label("count"),
        func.coalesce(func.sum(InsuranceClaim.insurance_amount), 0).label("total_insurance"),
    ).filter(
        extract("year", InsuranceClaim.claim_date) == year
    ).group_by(extract("month", InsuranceClaim.claim_date)).order_by("month").all()

    monthly = [
        MonthlyStats(
            month=int(row.month),
            month_label=ARABIC_MONTHS[int(row.month) - 1],
            count=row.count,
            total_insurance=Decimal(str(row.total_insurance)),
        )
        for row in monthly_rows
    ]

    return ReportSummary(
        year=year,
        total_employees=total_employees,
        total_claims=total_claims,
        pending_claims=pending_claims,
        total_invoice=Decimal(str(agg.total_invoice)),
        total_insurance=Decimal(str(agg.total_insurance)),
        total_employee_amount=Decimal(str(agg.total_employee)),
        by_type=by_type,
        monthly=monthly,
    )


@router.get("/employees", response_model=List[EmployeeReport], summary="تقرير استخدام الموظفين")
def get_employee_report(
    year: int = Query(default=None),
    db: Session = Depends(get_db),
):
    year = year or datetime.date.today().year

    employees = db.query(Employee).filter(Employee.is_active == True).all()
    result = []

    for emp in employees:
        # Resolve settings
        if emp.settings_id:
            s = db.query(InsuranceSettings).filter(InsuranceSettings.id == emp.settings_id).first()
        else:
            s = db.query(InsuranceSettings).filter(InsuranceSettings.is_active == True).first()

        annual_limit = Decimal(str(s.employee_annual_limit)) if s else Decimal("0")
        annual_used = get_annual_used(db, emp.id, year, "employee")
        annual_remaining = max(annual_limit - annual_used, Decimal("0"))
        usage_pct = (annual_used / annual_limit * 100).quantize(Decimal("0.1")) if annual_limit > 0 else Decimal("0")

        claim_count = db.query(func.count(InsuranceClaim.id)).filter(
            InsuranceClaim.employee_id == emp.id,
            extract("year", InsuranceClaim.claim_date) == year,
        ).scalar() or 0

        result.append(EmployeeReport(
            employee_id=emp.employee_id,
            full_name=emp.full_name,
            department=emp.department or "",
            annual_limit=annual_limit,
            annual_used=annual_used,
            annual_remaining=annual_remaining,
            usage_pct=usage_pct,
            claim_count=claim_count,
        ))

    # Sort by usage descending
    result.sort(key=lambda r: r.annual_used, reverse=True)
    return result


@router.get("/monthly", summary="التقرير الشهري التفصيلي")
def get_monthly_report(
    year: int = Query(default=None),
    db: Session = Depends(get_db),
):
    year = year or datetime.date.today().year

    rows = db.query(
        extract("month", InsuranceClaim.claim_date).label("month"),
        InsuranceClaim.claim_type,
        func.count(InsuranceClaim.id).label("count"),
        func.coalesce(func.sum(InsuranceClaim.invoice_amount), 0).label("total_invoice"),
        func.coalesce(func.sum(InsuranceClaim.insurance_amount), 0).label("total_insurance"),
        func.coalesce(func.sum(InsuranceClaim.employee_amount), 0).label("total_employee"),
    ).filter(
        extract("year", InsuranceClaim.claim_date) == year
    ).group_by(
        extract("month", InsuranceClaim.claim_date),
        InsuranceClaim.claim_type,
    ).order_by("month").all()

    # Build nested structure: month -> list of types
    months_map: dict = {}
    for row in rows:
        m = int(row.month)
        if m not in months_map:
            months_map[m] = {
                "month": m,
                "month_label": ARABIC_MONTHS[m - 1],
                "total_count": 0,
                "total_invoice": Decimal("0"),
                "total_insurance": Decimal("0"),
                "total_employee": Decimal("0"),
                "by_type": [],
            }
        months_map[m]["total_count"] += row.count
        months_map[m]["total_invoice"] += Decimal(str(row.total_invoice))
        months_map[m]["total_insurance"] += Decimal(str(row.total_insurance))
        months_map[m]["total_employee"] += Decimal(str(row.total_employee))
        months_map[m]["by_type"].append({
            "claim_type": row.claim_type,
            "label": CLAIM_TYPE_LABELS.get(row.claim_type, row.claim_type),
            "count": row.count,
            "total_invoice": Decimal(str(row.total_invoice)),
            "total_insurance": Decimal(str(row.total_insurance)),
            "total_employee": Decimal(str(row.total_employee)),
        })

    return {
        "year": year,
        "months": list(months_map.values()),
    }
