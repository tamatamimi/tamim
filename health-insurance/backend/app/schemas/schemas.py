from datetime import date, datetime
from decimal import Decimal
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field
from app.models.models import (
    GenderEnum, RelationEnum, ClaimTypeEnum,
    BeneficiaryTypeEnum, ClaimStatusEnum, DocumentTypeEnum
)


# ── Insurance Settings ──────────────────────────────────────────────────────

class InsuranceSettingsBase(BaseModel):
    name: str
    inpatient_pct: Decimal = Field(default=Decimal("90.00"), ge=0, le=100)
    outpatient_pct: Decimal = Field(default=Decimal("70.00"), ge=0, le=100)
    employee_annual_limit: Decimal = Field(default=Decimal("15000.00"), ge=0)
    family_annual_limit: Decimal = Field(default=Decimal("10000.00"), ge=0)
    max_per_claim: Decimal = Field(default=Decimal("5000.00"), ge=0)
    is_active: bool = True


class InsuranceSettingsCreate(InsuranceSettingsBase):
    pass


class InsuranceSettingsUpdate(InsuranceSettingsBase):
    pass


class InsuranceSettingsOut(InsuranceSettingsBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


# ── Family Member ────────────────────────────────────────────────────────────

class FamilyMemberBase(BaseModel):
    full_name: str
    national_id: Optional[str] = ""
    relation: RelationEnum
    date_of_birth: date
    is_active: bool = True


class FamilyMemberCreate(FamilyMemberBase):
    employee_id: int


class FamilyMemberOut(FamilyMemberBase):
    id: int
    employee_id: int
    annual_used: Optional[Decimal] = Decimal("0")
    annual_remaining: Optional[Decimal] = None

    class Config:
        from_attributes = True


# ── Employee ─────────────────────────────────────────────────────────────────

class EmployeeBase(BaseModel):
    employee_id: str
    full_name: str
    national_id: str
    gender: GenderEnum
    date_of_birth: date
    hire_date: date
    department: Optional[str] = ""
    job_title: Optional[str] = ""
    phone: Optional[str] = ""
    email: Optional[str] = ""
    is_active: bool = True
    settings_id: Optional[int] = None


class EmployeeCreate(EmployeeBase):
    pass


class EmployeeUpdate(EmployeeBase):
    pass


class EmployeeOut(EmployeeBase):
    id: int
    created_at: datetime
    family_members: List[FamilyMemberOut] = []

    class Config:
        from_attributes = True


class EmployeeWithStats(EmployeeOut):
    annual_used: Decimal = Decimal("0")
    annual_remaining: Decimal = Decimal("0")
    annual_limit: Decimal = Decimal("0")
    usage_pct: Decimal = Decimal("0")
    settings: Optional[InsuranceSettingsOut] = None


# ── Claim Document ────────────────────────────────────────────────────────────

class ClaimDocumentOut(BaseModel):
    id: int
    claim_id: int
    document_type: DocumentTypeEnum
    original_filename: str
    file_size: int
    uploaded_at: datetime

    class Config:
        from_attributes = True


# ── Insurance Claim ──────────────────────────────────────────────────────────

class ClaimCreate(BaseModel):
    employee_id: int
    beneficiary_type: BeneficiaryTypeEnum
    family_member_id: Optional[int] = None
    claim_type: ClaimTypeEnum
    claim_date: date
    hospital_name: str
    diagnosis: str
    invoice_amount: Decimal = Field(gt=0)
    notes: Optional[str] = ""


class ClaimStatusUpdate(BaseModel):
    status: ClaimStatusEnum
    approved_amount: Optional[Decimal] = None
    notes: Optional[str] = ""
    rejection_reason: Optional[str] = ""


class ClaimOut(BaseModel):
    id: int
    claim_number: str
    employee_id: int
    beneficiary_type: BeneficiaryTypeEnum
    family_member_id: Optional[int] = None
    claim_type: ClaimTypeEnum
    claim_date: date
    hospital_name: str
    diagnosis: str
    invoice_amount: Decimal
    coverage_pct: Decimal
    insurance_amount: Decimal
    employee_amount: Decimal
    approved_amount: Decimal
    status: ClaimStatusEnum
    notes: str
    rejection_reason: str
    created_at: datetime
    updated_at: datetime
    employee_name: Optional[str] = None
    beneficiary_name: Optional[str] = None
    documents: List[ClaimDocumentOut] = []

    class Config:
        from_attributes = True


# ── Auth ─────────────────────────────────────────────────────────────────────

class UserCreate(BaseModel):
    username: str
    email: str
    password: str


class UserOut(BaseModel):
    id: int
    username: str
    email: str
    is_active: bool
    is_superuser: bool

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserOut


class LoginRequest(BaseModel):
    username: str
    password: str


# ── Reports ──────────────────────────────────────────────────────────────────

class ClaimTypeStat(BaseModel):
    claim_type: str
    label: str
    count: int
    total_invoice: Decimal
    total_insurance: Decimal


class MonthlyStats(BaseModel):
    month: int
    month_label: str
    count: int
    total_insurance: Decimal


class ReportSummary(BaseModel):
    year: int
    total_employees: int
    total_claims: int
    pending_claims: int
    total_invoice: Decimal
    total_insurance: Decimal
    total_employee_amount: Decimal
    by_type: List[ClaimTypeStat]
    monthly: List[MonthlyStats]


class EmployeeReport(BaseModel):
    employee_id: str
    full_name: str
    department: str
    annual_limit: Decimal
    annual_used: Decimal
    annual_remaining: Decimal
    usage_pct: Decimal
    claim_count: int
