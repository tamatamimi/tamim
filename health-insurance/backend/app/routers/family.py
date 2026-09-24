from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import FamilyMember, Employee
from app.schemas.schemas import FamilyMemberCreate, FamilyMemberOut

router = APIRouter(prefix="/api/family", tags=["family"])


@router.post("", response_model=FamilyMemberOut, status_code=201)
def create_family_member(data: FamilyMemberCreate, db: Session = Depends(get_db)):
    emp = db.query(Employee).filter(Employee.id == data.employee_id).first()
    if not emp:
        raise HTTPException(404, "الموظف غير موجود")
    member = FamilyMember(**data.model_dump())
    db.add(member)
    db.commit()
    db.refresh(member)
    return member


@router.put("/{id}", response_model=FamilyMemberOut)
def update_family_member(id: int, data: FamilyMemberCreate, db: Session = Depends(get_db)):
    member = db.query(FamilyMember).filter(FamilyMember.id == id).first()
    if not member:
        raise HTTPException(404, "فرد العائلة غير موجود")
    for k, v in data.model_dump().items():
        setattr(member, k, v)
    db.commit()
    db.refresh(member)
    return member


@router.delete("/{id}")
def delete_family_member(id: int, db: Session = Depends(get_db)):
    member = db.query(FamilyMember).filter(FamilyMember.id == id).first()
    if not member:
        raise HTTPException(404, "فرد العائلة غير موجود")
    member.is_active = False
    db.commit()
    return {"message": "تم الحذف"}
