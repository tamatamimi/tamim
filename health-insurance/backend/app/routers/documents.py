import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import ClaimDocument, InsuranceClaim, DocumentTypeEnum
from app.schemas.schemas import ClaimDocumentOut
from app.config import settings

router = APIRouter(prefix="/api/documents", tags=["documents"])


@router.post("/upload/{claim_id}", response_model=ClaimDocumentOut, status_code=201)
async def upload_document(
    claim_id: int,
    document_type: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    claim = db.query(InsuranceClaim).filter(InsuranceClaim.id == claim_id).first()
    if not claim:
        raise HTTPException(404, "المطالبة غير موجودة")

    # Validate file
    ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else ""
    if ext not in settings.ALLOWED_EXTENSIONS:
        raise HTTPException(400, f"نوع الملف غير مسموح به. الأنواع المقبولة: {', '.join(settings.ALLOWED_EXTENSIONS)}")

    content = await file.read()
    if len(content) > settings.MAX_FILE_SIZE:
        raise HTTPException(400, "حجم الملف يتجاوز الحد المسموح به (10MB)")

    # Save file
    claim_dir = os.path.join(settings.UPLOAD_DIR, str(claim_id))
    os.makedirs(claim_dir, exist_ok=True)
    filename = f"{uuid.uuid4().hex}.{ext}"
    file_path = os.path.join(claim_dir, filename)

    with open(file_path, "wb") as f:
        f.write(content)

    doc = ClaimDocument(
        claim_id=claim_id,
        document_type=document_type,
        file_path=file_path,
        original_filename=file.filename,
        file_size=len(content),
    )
    db.add(doc)
    db.commit()
    db.refresh(doc)
    return doc


@router.get("/{id}/download")
def download_document(id: int, db: Session = Depends(get_db)):
    doc = db.query(ClaimDocument).filter(ClaimDocument.id == id).first()
    if not doc or not os.path.exists(doc.file_path):
        raise HTTPException(404, "الملف غير موجود")
    return FileResponse(doc.file_path, filename=doc.original_filename)


@router.delete("/{id}")
def delete_document(id: int, db: Session = Depends(get_db)):
    doc = db.query(ClaimDocument).filter(ClaimDocument.id == id).first()
    if not doc:
        raise HTTPException(404, "المستند غير موجود")
    if os.path.exists(doc.file_path):
        os.remove(doc.file_path)
    db.delete(doc)
    db.commit()
    return {"message": "تم حذف المستند"}
