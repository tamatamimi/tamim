from django.contrib import admin
from django.utils.html import format_html
from .models import InsuranceSettings, Employee, FamilyMember, InsuranceClaim, ClaimDocument


@admin.register(InsuranceSettings)
class InsuranceSettingsAdmin(admin.ModelAdmin):
    list_display = ["name", "inpatient_coverage_pct", "outpatient_coverage_pct",
                    "employee_annual_limit", "family_member_annual_limit", "is_active"]
    list_editable = ["is_active"]


class FamilyMemberInline(admin.TabularInline):
    model = FamilyMember
    extra = 0
    fields = ["full_name", "relation", "date_of_birth", "national_id", "is_active"]


@admin.register(Employee)
class EmployeeAdmin(admin.ModelAdmin):
    list_display = ["employee_id", "full_name", "department", "job_title", "phone", "is_active"]
    list_filter = ["department", "is_active", "gender"]
    search_fields = ["full_name", "employee_id", "national_id"]
    inlines = [FamilyMemberInline]


class ClaimDocumentInline(admin.TabularInline):
    model = ClaimDocument
    extra = 0
    fields = ["document_type", "file", "description"]


@admin.register(InsuranceClaim)
class InsuranceClaimAdmin(admin.ModelAdmin):
    list_display = [
        "claim_number", "employee", "beneficiary_type", "claim_type",
        "claim_date", "invoice_amount", "coverage_badge", "insurance_amount",
        "approved_amount", "status_badge"
    ]
    list_filter = ["status", "claim_type", "beneficiary_type", "claim_date"]
    search_fields = ["claim_number", "employee__full_name", "employee__employee_id"]
    readonly_fields = ["claim_number", "coverage_percentage", "insurance_amount", "employee_amount"]
    inlines = [ClaimDocumentInline]
    date_hierarchy = "claim_date"

    fieldsets = [
        ("معلومات المطالبة", {
            "fields": ["claim_number", "employee", "beneficiary_type", "family_member"]
        }),
        ("التفاصيل الطبية", {
            "fields": ["claim_type", "claim_date", "hospital_name", "diagnosis", "invoice_amount"]
        }),
        ("التغطية التأمينية (محسوبة تلقائياً)", {
            "fields": ["coverage_percentage", "insurance_amount", "employee_amount", "approved_amount"],
            "classes": ["collapse"]
        }),
        ("الحالة", {
            "fields": ["status", "notes", "rejection_reason"]
        }),
    ]

    def coverage_badge(self, obj):
        color = "green" if obj.claim_type == "inpatient" else "orange"
        return format_html(
            '<span style="color:{}; font-weight:bold;">{}%</span>',
            color, obj.coverage_percentage
        )
    coverage_badge.short_description = "نسبة التغطية"

    def status_badge(self, obj):
        colors = {
            "pending": "#f0ad4e",
            "approved": "#5cb85c",
            "partially_approved": "#5bc0de",
            "rejected": "#d9534f",
            "paid": "#337ab7",
        }
        color = colors.get(obj.status, "#777")
        return format_html(
            '<span style="background:{};color:white;padding:2px 8px;border-radius:4px;">{}</span>',
            color, obj.get_status_display()
        )
    status_badge.short_description = "الحالة"
