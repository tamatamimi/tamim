import datetime
from decimal import Decimal
from sqlalchemy import (
    Column, Integer, String, Boolean, Date, DateTime,
    Numeric, Text, ForeignKey, Enum as SAEnum
)
from sqlalchemy.orm import relationship
from app.database import Base
import enum


class GenderEnum(str, enum.Enum):
    male = "M"
    female = "F"


class RelationEnum(str, enum.Enum):
    spouse = "spouse"
    son = "son"
    daughter = "daughter"
    father = "father"
    mother = "mother"
    other = "other"


class ClaimTypeEnum(str, enum.Enum):
    inpatient = "inpatient"
    outpatient = "outpatient"
    emergency = "emergency"


class BeneficiaryTypeEnum(str, enum.Enum):
    employee = "employee"
    family = "family"


class ClaimStatusEnum(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    partially_approved = "partially_approved"
    rejected = "rejected"
    paid = "paid"


class DocumentTypeEnum(str, enum.Enum):
    invoice = "invoice"
    doctor_request = "doctor_request"
    prescription = "prescription"
    lab_result = "lab_result"
    xray = "xray"
    discharge_summary = "discharge_summary"
    other = "other"


class InsuranceSettings(Base):
    __tablename__ = "insurance_settings"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    inpatient_pct = Column(Numeric(5, 2), default=90.00, nullable=False)
    outpatient_pct = Column(Numeric(5, 2), default=70.00, nullable=False)
    employee_annual_limit = Column(Numeric(12, 2), default=15000.00, nullable=False)
    family_annual_limit = Column(Numeric(12, 2), default=10000.00, nullable=False)
    max_per_claim = Column(Numeric(12, 2), default=5000.00, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    employees = relationship("Employee", back_populates="settings")


class Employee(Base):
    __tablename__ = "employees"

    id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(String(50), unique=True, nullable=False, index=True)
    full_name = Column(String(200), nullable=False)
    national_id = Column(String(20), unique=True, nullable=False)
    gender = Column(SAEnum(GenderEnum), nullable=False)
    date_of_birth = Column(Date, nullable=False)
    hire_date = Column(Date, nullable=False)
    department = Column(String(200), default="")
    job_title = Column(String(200), default="")
    phone = Column(String(20), default="")
    email = Column(String(200), default="")
    is_active = Column(Boolean, default=True)
    settings_id = Column(Integer, ForeignKey("insurance_settings.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    settings = relationship("InsuranceSettings", back_populates="employees")
    family_members = relationship("FamilyMember", back_populates="employee", cascade="all, delete-orphan")
    claims = relationship("InsuranceClaim", back_populates="employee")


class FamilyMember(Base):
    __tablename__ = "family_members"

    id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(Integer, ForeignKey("employees.id"), nullable=False)
    full_name = Column(String(200), nullable=False)
    national_id = Column(String(20), default="")
    relation = Column(SAEnum(RelationEnum), nullable=False)
    date_of_birth = Column(Date, nullable=False)
    is_active = Column(Boolean, default=True)

    employee = relationship("Employee", back_populates="family_members")
    claims = relationship("InsuranceClaim", back_populates="family_member")


class InsuranceClaim(Base):
    __tablename__ = "insurance_claims"

    id = Column(Integer, primary_key=True, index=True)
    claim_number = Column(String(50), unique=True, nullable=False, index=True)
    employee_id = Column(Integer, ForeignKey("employees.id"), nullable=False)
    beneficiary_type = Column(SAEnum(BeneficiaryTypeEnum), nullable=False)
    family_member_id = Column(Integer, ForeignKey("family_members.id"), nullable=True)
    claim_type = Column(SAEnum(ClaimTypeEnum), nullable=False)
    claim_date = Column(Date, nullable=False)
    hospital_name = Column(String(300), nullable=False)
    diagnosis = Column(Text, nullable=False)
    invoice_amount = Column(Numeric(12, 2), nullable=False)
    coverage_pct = Column(Numeric(5, 2), default=0)
    insurance_amount = Column(Numeric(12, 2), default=0)
    employee_amount = Column(Numeric(12, 2), default=0)
    approved_amount = Column(Numeric(12, 2), default=0)
    status = Column(SAEnum(ClaimStatusEnum), default=ClaimStatusEnum.pending)
    notes = Column(Text, default="")
    rejection_reason = Column(Text, default="")
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    employee = relationship("Employee", back_populates="claims")
    family_member = relationship("FamilyMember", back_populates="claims")
    documents = relationship("ClaimDocument", back_populates="claim", cascade="all, delete-orphan")


class ClaimDocument(Base):
    __tablename__ = "claim_documents"

    id = Column(Integer, primary_key=True, index=True)
    claim_id = Column(Integer, ForeignKey("insurance_claims.id"), nullable=False)
    document_type = Column(SAEnum(DocumentTypeEnum), nullable=False)
    file_path = Column(String(500), nullable=False)
    original_filename = Column(String(300), nullable=False)
    file_size = Column(Integer, default=0)
    uploaded_at = Column(DateTime, default=datetime.datetime.utcnow)

    claim = relationship("InsuranceClaim", back_populates="documents")


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(100), unique=True, nullable=False)
    email = Column(String(200), unique=True, nullable=False)
    hashed_password = Column(String(300), nullable=False)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
