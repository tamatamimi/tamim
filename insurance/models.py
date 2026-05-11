from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from decimal import Decimal


class InsuranceSettings(models.Model):
    """إعدادات نظام التأمين الصحي"""
    name = models.CharField(max_length=200, verbose_name="اسم السياسة")

    # نسب التغطية
    inpatient_coverage_pct = models.DecimalField(
        max_digits=5, decimal_places=2, default=90.00,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        verbose_name="نسبة تغطية المريض الداخلي (%)"
    )
    outpatient_coverage_pct = models.DecimalField(
        max_digits=5, decimal_places=2, default=70.00,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        verbose_name="نسبة تغطية الطوارئ والعيادات الخارجية (%)"
    )

    # الأسقف السنوية للموظف
    employee_annual_limit = models.DecimalField(
        max_digits=12, decimal_places=2, default=10000.00,
        validators=[MinValueValidator(0)],
        verbose_name="السقف السنوي للموظف (ريال)"
    )

    # الأسقف السنوية لأفراد العائلة
    family_member_annual_limit = models.DecimalField(
        max_digits=12, decimal_places=2, default=7000.00,
        validators=[MinValueValidator(0)],
        verbose_name="السقف السنوي لكل فرد من العائلة (ريال)"
    )

    # الحد الأقصى لكل مطالبة
    max_per_claim = models.DecimalField(
        max_digits=12, decimal_places=2, default=5000.00,
        validators=[MinValueValidator(0)],
        verbose_name="الحد الأقصى للمطالبة الواحدة (ريال)"
    )

    is_active = models.BooleanField(default=True, verbose_name="نشط")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "إعدادات التأمين"
        verbose_name_plural = "إعدادات التأمين"

    def __str__(self):
        return self.name

    @classmethod
    def get_active(cls):
        return cls.objects.filter(is_active=True).first()


class Employee(models.Model):
    """بيانات الموظف"""
    GENDER_CHOICES = [("M", "ذكر"), ("F", "أنثى")]

    employee_id = models.CharField(max_length=50, unique=True, verbose_name="رقم الموظف")
    full_name = models.CharField(max_length=200, verbose_name="الاسم الكامل")
    national_id = models.CharField(max_length=20, unique=True, verbose_name="رقم الهوية")
    gender = models.CharField(max_length=1, choices=GENDER_CHOICES, verbose_name="الجنس")
    date_of_birth = models.DateField(verbose_name="تاريخ الميلاد")
    hire_date = models.DateField(verbose_name="تاريخ التوظيف")
    department = models.CharField(max_length=200, verbose_name="القسم", blank=True)
    job_title = models.CharField(max_length=200, verbose_name="المسمى الوظيفي", blank=True)
    phone = models.CharField(max_length=20, verbose_name="رقم الجوال", blank=True)
    email = models.EmailField(verbose_name="البريد الإلكتروني", blank=True)
    is_active = models.BooleanField(default=True, verbose_name="نشط")
    insurance_settings = models.ForeignKey(
        InsuranceSettings, on_delete=models.SET_NULL, null=True, blank=True,
        verbose_name="سياسة التأمين"
    )

    class Meta:
        verbose_name = "موظف"
        verbose_name_plural = "الموظفون"
        ordering = ["full_name"]

    def __str__(self):
        return f"{self.full_name} ({self.employee_id})"

    def get_settings(self):
        return self.insurance_settings or InsuranceSettings.get_active()

    def get_annual_used(self, year):
        return self.claims.filter(
            claim_date__year=year,
            status__in=["approved", "paid"],
            beneficiary_type="employee"
        ).aggregate(total=models.Sum("approved_amount"))["total"] or Decimal("0")

    def get_annual_remaining(self, year):
        settings = self.get_settings()
        if not settings:
            return Decimal("0")
        used = self.get_annual_used(year)
        return max(settings.employee_annual_limit - used, Decimal("0"))


class FamilyMember(models.Model):
    """أفراد عائلة الموظف"""
    RELATION_CHOICES = [
        ("spouse", "زوج/زوجة"),
        ("son", "ابن"),
        ("daughter", "ابنة"),
        ("father", "والد"),
        ("mother", "والدة"),
        ("other", "أخرى"),
    ]

    employee = models.ForeignKey(
        Employee, on_delete=models.CASCADE,
        related_name="family_members", verbose_name="الموظف"
    )
    full_name = models.CharField(max_length=200, verbose_name="الاسم الكامل")
    national_id = models.CharField(max_length=20, blank=True, verbose_name="رقم الهوية")
    relation = models.CharField(max_length=20, choices=RELATION_CHOICES, verbose_name="صلة القرابة")
    date_of_birth = models.DateField(verbose_name="تاريخ الميلاد")
    is_active = models.BooleanField(default=True, verbose_name="نشط")

    class Meta:
        verbose_name = "فرد العائلة"
        verbose_name_plural = "أفراد العائلة"

    def __str__(self):
        return f"{self.full_name} ({self.get_relation_display()}) - {self.employee.full_name}"

    def get_annual_used(self, year):
        return InsuranceClaim.objects.filter(
            employee=self.employee,
            family_member=self,
            claim_date__year=year,
            status__in=["approved", "paid"],
        ).aggregate(total=models.Sum("approved_amount"))["total"] or Decimal("0")

    def get_annual_remaining(self, year):
        settings = self.employee.get_settings()
        if not settings:
            return Decimal("0")
        used = self.get_annual_used(year)
        return max(settings.family_member_annual_limit - used, Decimal("0"))


class InsuranceClaim(models.Model):
    """مطالبة التأمين الصحي"""

    CLAIM_TYPE_CHOICES = [
        ("inpatient", "مريض داخلي (رقود)"),
        ("outpatient", "عيادات خارجية"),
        ("emergency", "طوارئ"),
    ]

    BENEFICIARY_TYPE_CHOICES = [
        ("employee", "الموظف"),
        ("family", "فرد من العائلة"),
    ]

    STATUS_CHOICES = [
        ("pending", "قيد المراجعة"),
        ("approved", "مقبولة"),
        ("partially_approved", "مقبولة جزئياً"),
        ("rejected", "مرفوضة"),
        ("paid", "مدفوعة"),
    ]

    claim_number = models.CharField(max_length=50, unique=True, verbose_name="رقم المطالبة")
    employee = models.ForeignKey(
        Employee, on_delete=models.CASCADE,
        related_name="claims", verbose_name="الموظف"
    )
    beneficiary_type = models.CharField(
        max_length=10, choices=BENEFICIARY_TYPE_CHOICES,
        verbose_name="المستفيد"
    )
    family_member = models.ForeignKey(
        FamilyMember, on_delete=models.SET_NULL, null=True, blank=True,
        verbose_name="فرد العائلة"
    )

    claim_type = models.CharField(
        max_length=20, choices=CLAIM_TYPE_CHOICES,
        verbose_name="نوع المطالبة"
    )
    claim_date = models.DateField(verbose_name="تاريخ الخدمة الطبية")
    submission_date = models.DateField(auto_now_add=True, verbose_name="تاريخ التقديم")
    hospital_name = models.CharField(max_length=300, verbose_name="اسم المستشفى / العيادة")
    diagnosis = models.TextField(verbose_name="التشخيص / السبب الطبي")

    invoice_amount = models.DecimalField(
        max_digits=12, decimal_places=2,
        validators=[MinValueValidator(Decimal("0.01"))],
        verbose_name="قيمة الفاتورة (ريال)"
    )

    coverage_percentage = models.DecimalField(
        max_digits=5, decimal_places=2,
        verbose_name="نسبة التغطية (%)", editable=False, default=0
    )
    insurance_amount = models.DecimalField(
        max_digits=12, decimal_places=2,
        verbose_name="مبلغ التأمين (ريال)", editable=False, default=0
    )
    employee_amount = models.DecimalField(
        max_digits=12, decimal_places=2,
        verbose_name="مبلغ تحمل الموظف (ريال)", editable=False, default=0
    )
    approved_amount = models.DecimalField(
        max_digits=12, decimal_places=2, default=0,
        verbose_name="المبلغ المعتمد (ريال)"
    )

    status = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default="pending",
        verbose_name="الحالة"
    )
    notes = models.TextField(blank=True, verbose_name="ملاحظات")
    rejection_reason = models.TextField(blank=True, verbose_name="سبب الرفض")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "مطالبة تأمين"
        verbose_name_plural = "مطالبات التأمين"
        ordering = ["-submission_date"]

    def __str__(self):
        return f"{self.claim_number} - {self.employee.full_name}"

    def calculate_coverage(self):
        settings = self.employee.get_settings()
        if not settings:
            return

        if self.claim_type == "inpatient":
            pct = settings.inpatient_coverage_pct
        else:
            pct = settings.outpatient_coverage_pct

        invoice = min(self.invoice_amount, settings.max_per_claim)

        year = self.claim_date.year
        if self.beneficiary_type == "employee":
            remaining_limit = self.employee.get_annual_remaining(year)
        else:
            remaining_limit = self.family_member.get_annual_remaining(year) if self.family_member else Decimal("0")

        insurance = (invoice * pct / Decimal("100")).quantize(Decimal("0.01"))
        insurance = min(insurance, remaining_limit)

        self.coverage_percentage = pct
        self.insurance_amount = insurance
        self.employee_amount = (self.invoice_amount - insurance).quantize(Decimal("0.01"))
        if self.status == "pending":
            self.approved_amount = insurance

    def save(self, *args, **kwargs):
        if not self.claim_number:
            import datetime
            last = InsuranceClaim.objects.order_by("-id").first()
            seq = (last.id + 1) if last else 1
            self.claim_number = f"CLM-{datetime.date.today().year}-{seq:05d}"
        self.calculate_coverage()
        super().save(*args, **kwargs)

    @property
    def beneficiary_name(self):
        if self.beneficiary_type == "employee":
            return self.employee.full_name
        return self.family_member.full_name if self.family_member else "-"


class ClaimDocument(models.Model):
    """المستندات المرفقة بالمطالبة"""

    DOCUMENT_TYPE_CHOICES = [
        ("invoice", "فاتورة طبية"),
        ("doctor_request", "طلب طبيب"),
        ("prescription", "وصفة طبية"),
        ("lab_result", "نتيجة مختبر"),
        ("xray", "أشعة"),
        ("discharge_summary", "ملخص خروج"),
        ("other", "أخرى"),
    ]

    claim = models.ForeignKey(
        InsuranceClaim, on_delete=models.CASCADE,
        related_name="documents", verbose_name="المطالبة"
    )
    document_type = models.CharField(
        max_length=30, choices=DOCUMENT_TYPE_CHOICES,
        verbose_name="نوع المستند"
    )
    file = models.FileField(upload_to="claims/%Y/%m/", verbose_name="الملف")
    description = models.CharField(max_length=300, blank=True, verbose_name="وصف")
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "مستند"
        verbose_name_plural = "المستندات"

    def __str__(self):
        return f"{self.get_document_type_display()} - {self.claim.claim_number}"
