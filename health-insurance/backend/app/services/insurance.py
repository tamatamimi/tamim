from decimal import Decimal
from typing import Optional
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.models import InsuranceClaim, InsuranceSettings, ClaimStatusEnum, ClaimTypeEnum


class InsuranceCalculator:
    def calculate(
        self,
        invoice_amount: Decimal,
        claim_type: ClaimTypeEnum,
        settings: InsuranceSettings,
        annual_used: Decimal = Decimal("0"),
        exclude_claim_id: Optional[int] = None,
    ) -> dict:
        # Determine coverage percentage
        if claim_type == ClaimTypeEnum.inpatient:
            pct = Decimal(str(settings.inpatient_pct))
        else:
            pct = Decimal(str(settings.outpatient_pct))

        # Apply max per claim cap
        capped_invoice = min(invoice_amount, Decimal(str(settings.max_per_claim)))

        # Calculate gross insurance amount
        gross_insurance = (capped_invoice * pct / Decimal("100")).quantize(Decimal("0.01"))

        # Apply annual limit
        annual_limit = Decimal(str(settings.employee_annual_limit))
        remaining_limit = max(annual_limit - annual_used, Decimal("0"))
        insurance_amount = min(gross_insurance, remaining_limit).quantize(Decimal("0.01"))

        employee_amount = (invoice_amount - insurance_amount).quantize(Decimal("0.01"))

        return {
            "coverage_pct": pct,
            "insurance_amount": insurance_amount,
            "employee_amount": employee_amount,
        }


def get_annual_used(
    db: Session,
    employee_id: int,
    year: int,
    beneficiary_type: str = "employee",
    family_member_id: Optional[int] = None,
    exclude_claim_id: Optional[int] = None,
) -> Decimal:
    query = db.query(func.coalesce(func.sum(InsuranceClaim.approved_amount), 0)).filter(
        InsuranceClaim.employee_id == employee_id,
        func.extract("year", InsuranceClaim.claim_date) == year,
        InsuranceClaim.status.in_([ClaimStatusEnum.approved, ClaimStatusEnum.paid]),
        InsuranceClaim.beneficiary_type == beneficiary_type,
    )
    if family_member_id:
        query = query.filter(InsuranceClaim.family_member_id == family_member_id)
    if exclude_claim_id:
        query = query.filter(InsuranceClaim.id != exclude_claim_id)
    result = query.scalar()
    return Decimal(str(result)) if result else Decimal("0")


calculator = InsuranceCalculator()
