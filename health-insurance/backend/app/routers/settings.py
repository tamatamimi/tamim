from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.models.models import InsuranceSettings
from app.schemas.schemas import InsuranceSettingsCreate, InsuranceSettingsUpdate, InsuranceSettingsOut

router = APIRouter(prefix="/api/settings", tags=["settings"])


@router.get("", response_model=List[InsuranceSettingsOut])
def list_settings(db: Session = Depends(get_db)):
    return db.query(InsuranceSettings).all()


@router.get("/active", response_model=InsuranceSettingsOut)
def get_active(db: Session = Depends(get_db)):
    s = db.query(InsuranceSettings).filter(InsuranceSettings.is_active == True).first()
    if not s:
        raise HTTPException(404, "لا توجد سياسة تأمين نشطة")
    return s


@router.post("", response_model=InsuranceSettingsOut)
def create_settings(data: InsuranceSettingsCreate, db: Session = Depends(get_db)):
    s = InsuranceSettings(**data.model_dump())
    db.add(s)
    db.commit()
    db.refresh(s)
    return s


@router.put("/{id}", response_model=InsuranceSettingsOut)
def update_settings(id: int, data: InsuranceSettingsUpdate, db: Session = Depends(get_db)):
    s = db.query(InsuranceSettings).filter(InsuranceSettings.id == id).first()
    if not s:
        raise HTTPException(404, "السياسة غير موجودة")
    for k, v in data.model_dump().items():
        setattr(s, k, v)
    db.commit()
    db.refresh(s)
    return s
