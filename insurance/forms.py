from django import forms
from django.forms import inlineformset_factory
from .models import InsuranceClaim, ClaimDocument, Employee, FamilyMember


class ClaimForm(forms.ModelForm):
    class Meta:
        model = InsuranceClaim
        fields = [
            "employee", "beneficiary_type", "family_member",
            "claim_type", "claim_date", "hospital_name",
            "diagnosis", "invoice_amount", "notes",
        ]
        widgets = {
            "employee": forms.Select(attrs={"class": "form-select", "id": "id_employee"}),
            "beneficiary_type": forms.Select(attrs={"class": "form-select", "id": "id_beneficiary_type"}),
            "family_member": forms.Select(attrs={"class": "form-select", "id": "id_family_member"}),
            "claim_type": forms.Select(attrs={"class": "form-select"}),
            "claim_date": forms.DateInput(attrs={"class": "form-control", "type": "date"}),
            "hospital_name": forms.TextInput(attrs={"class": "form-control"}),
            "diagnosis": forms.Textarea(attrs={"class": "form-control", "rows": 3}),
            "invoice_amount": forms.NumberInput(attrs={"class": "form-control", "step": "0.01"}),
            "notes": forms.Textarea(attrs={"class": "form-control", "rows": 2}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["family_member"].queryset = FamilyMember.objects.none()
        self.fields["family_member"].required = False
        self.fields["notes"].required = False

        if "employee" in self.data:
            try:
                emp_id = int(self.data.get("employee"))
                self.fields["family_member"].queryset = FamilyMember.objects.filter(
                    employee_id=emp_id, is_active=True
                )
            except (ValueError, TypeError):
                pass
        elif self.instance.pk and self.instance.employee_id:
            self.fields["family_member"].queryset = FamilyMember.objects.filter(
                employee=self.instance.employee, is_active=True
            )

    def clean(self):
        cleaned = super().clean()
        beneficiary = cleaned.get("beneficiary_type")
        family_member = cleaned.get("family_member")
        if beneficiary == "family" and not family_member:
            self.add_error("family_member", "يجب تحديد فرد العائلة")
        return cleaned


class ClaimDocumentForm(forms.ModelForm):
    class Meta:
        model = ClaimDocument
        fields = ["document_type", "file", "description"]
        widgets = {
            "document_type": forms.Select(attrs={"class": "form-select"}),
            "file": forms.FileInput(attrs={"class": "form-control"}),
            "description": forms.TextInput(attrs={"class": "form-control"}),
        }


ClaimDocumentFormSet = inlineformset_factory(
    InsuranceClaim, ClaimDocument,
    form=ClaimDocumentForm,
    extra=2, can_delete=True,
    min_num=0,
)
