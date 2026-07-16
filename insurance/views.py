import datetime
from decimal import Decimal
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib import messages
from django.db.models import Sum, Count, Q
from django.http import JsonResponse
from .models import Employee, FamilyMember, InsuranceClaim, ClaimDocument, InsuranceSettings
from .forms import ClaimForm, ClaimDocumentFormSet


def dashboard(request):
    year = datetime.date.today().year
    total_employees = Employee.objects.filter(is_active=True).count()
    total_claims = InsuranceClaim.objects.filter(claim_date__year=year).count()
    pending_claims = InsuranceClaim.objects.filter(status="pending").count()

    agg = InsuranceClaim.objects.filter(
        claim_date__year=year,
        status__in=["approved", "paid"]
    ).aggregate(
        total_invoice=Sum("invoice_amount"),
        total_insurance=Sum("insurance_amount"),
        total_employee=Sum("employee_amount"),
    )

    recent_claims = InsuranceClaim.objects.select_related("employee", "family_member")[:10]

    context = {
        "year": year,
        "total_employees": total_employees,
        "total_claims": total_claims,
        "pending_claims": pending_claims,
        "total_invoice": agg["total_invoice"] or Decimal("0"),
        "total_insurance": agg["total_insurance"] or Decimal("0"),
        "total_employee": agg["total_employee"] or Decimal("0"),
        "recent_claims": recent_claims,
    }
    return render(request, "insurance/dashboard.html", context)


def employee_list(request):
    query = request.GET.get("q", "")
    employees = Employee.objects.filter(is_active=True)
    if query:
        employees = employees.filter(
            Q(full_name__icontains=query) |
            Q(employee_id__icontains=query) |
            Q(department__icontains=query)
        )
    return render(request, "insurance/employee_list.html", {"employees": employees, "query": query})


def employee_detail(request, pk):
    employee = get_object_or_404(Employee, pk=pk)
    year = int(request.GET.get("year", datetime.date.today().year))
    claims = employee.claims.filter(claim_date__year=year).select_related("family_member")
    family_members = employee.family_members.filter(is_active=True)
    settings = employee.get_settings()

    employee_used = employee.get_annual_used(year)
    employee_remaining = employee.get_annual_remaining(year)

    family_stats = []
    for member in family_members:
        family_stats.append({
            "member": member,
            "used": member.get_annual_used(year),
            "remaining": member.get_annual_remaining(year),
        })

    current_year = datetime.date.today().year
    year_options = list(range(current_year, current_year - 4, -1))
    if year not in year_options:
        year_options.append(year)
        year_options.sort(reverse=True)

    context = {
        "employee": employee,
        "claims": claims,
        "family_members": family_members,
        "settings": settings,
        "year": year,
        "year_options": year_options,
        "employee_used": employee_used,
        "employee_remaining": employee_remaining,
        "family_stats": family_stats,
    }
    return render(request, "insurance/employee_detail.html", context)


def claim_list(request):
    status_filter = request.GET.get("status", "")
    type_filter = request.GET.get("type", "")
    query = request.GET.get("q", "")

    claims = InsuranceClaim.objects.select_related("employee", "family_member")
    if status_filter:
        claims = claims.filter(status=status_filter)
    if type_filter:
        claims = claims.filter(claim_type=type_filter)
    if query:
        claims = claims.filter(
            Q(claim_number__icontains=query) |
            Q(employee__full_name__icontains=query) |
            Q(hospital_name__icontains=query)
        )

    context = {
        "claims": claims,
        "status_filter": status_filter,
        "type_filter": type_filter,
        "query": query,
        "status_choices": InsuranceClaim.STATUS_CHOICES,
        "type_choices": InsuranceClaim.CLAIM_TYPE_CHOICES,
    }
    return render(request, "insurance/claim_list.html", context)


def claim_new(request):
    if request.method == "POST":
        form = ClaimForm(request.POST)
        formset = ClaimDocumentFormSet(request.POST, request.FILES)
        if form.is_valid() and formset.is_valid():
            claim = form.save()
            formset.instance = claim
            formset.save()
            messages.success(request, f"تم تقديم المطالبة بنجاح، رقمها: {claim.claim_number}")
            return redirect("claim_detail", pk=claim.pk)
    else:
        form = ClaimForm()
        formset = ClaimDocumentFormSet()

    return render(request, "insurance/claim_form.html", {
        "form": form,
        "formset": formset,
        "title": "مطالبة جديدة",
    })


def claim_detail(request, pk):
    claim = get_object_or_404(InsuranceClaim, pk=pk)
    documents = claim.documents.all()
    return render(request, "insurance/claim_detail.html", {
        "claim": claim,
        "documents": documents,
    })


def claim_update_status(request, pk):
    claim = get_object_or_404(InsuranceClaim, pk=pk)
    if request.method == "POST":
        new_status = request.POST.get("status")
        approved_amount = request.POST.get("approved_amount")
        rejection_reason = request.POST.get("rejection_reason", "")
        notes = request.POST.get("notes", "")

        valid_statuses = [s[0] for s in InsuranceClaim.STATUS_CHOICES]
        if new_status in valid_statuses:
            claim.status = new_status
            if approved_amount:
                claim.approved_amount = Decimal(approved_amount)
            claim.rejection_reason = rejection_reason
            claim.notes = notes
            claim.save()
            messages.success(request, "تم تحديث حالة المطالبة بنجاح")
        return redirect("claim_detail", pk=pk)
    return redirect("claim_detail", pk=pk)


def get_family_members(request):
    employee_id = request.GET.get("employee_id")
    if not employee_id:
        return JsonResponse({"members": []})
    members = FamilyMember.objects.filter(employee_id=employee_id, is_active=True)
    data = [{"id": m.id, "name": str(m)} for m in members]
    return JsonResponse({"members": data})


def reports(request):
    year = int(request.GET.get("year", datetime.date.today().year))

    employees_data = []
    for emp in Employee.objects.filter(is_active=True):
        used = emp.get_annual_used(year)
        remaining = emp.get_annual_remaining(year)
        settings = emp.get_settings()
        limit = settings.employee_annual_limit if settings else Decimal("0")
        pct = (used / limit * 100).quantize(Decimal("0.1")) if limit > 0 else Decimal("0")
        employees_data.append({
            "employee": emp,
            "used": used,
            "remaining": remaining,
            "limit": limit,
            "pct": pct,
        })

    # إحصاءات عامة حسب النوع
    by_type = InsuranceClaim.objects.filter(
        claim_date__year=year, status__in=["approved", "paid"]
    ).values("claim_type").annotate(
        count=Count("id"),
        total_invoice=Sum("invoice_amount"),
        total_insurance=Sum("insurance_amount"),
    )

    context = {
        "year": year,
        "employees_data": employees_data,
        "by_type": by_type,
        "years": range(datetime.date.today().year, datetime.date.today().year - 5, -1),
    }
    return render(request, "insurance/reports.html", context)
