from django.urls import path
from . import views

urlpatterns = [
    path("", views.dashboard, name="dashboard"),
    path("employees/", views.employee_list, name="employee_list"),
    path("employees/<int:pk>/", views.employee_detail, name="employee_detail"),
    path("claims/", views.claim_list, name="claim_list"),
    path("claims/new/", views.claim_new, name="claim_new"),
    path("claims/<int:pk>/", views.claim_detail, name="claim_detail"),
    path("claims/<int:pk>/status/", views.claim_update_status, name="claim_update_status"),
    path("reports/", views.reports, name="reports"),
    path("api/family-members/", views.get_family_members, name="get_family_members"),
]
