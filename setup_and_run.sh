#!/bin/bash
set -e

echo "========================================"
echo "  نظام التأمين الصحي - إعداد تلقائي"
echo "========================================"

# التحقق من Python
if ! command -v python3 &>/dev/null; then
    echo "❌ Python3 غير مثبّت. حمّله من: https://python.org"
    exit 1
fi
echo "✅ Python: $(python3 --version)"

# تثبيت المتطلبات
echo ""
echo "📦 تثبيت المتطلبات..."
pip install -r requirements.txt -q

# قاعدة البيانات
echo "🗄️  إعداد قاعدة البيانات..."
python3 manage.py migrate --run-syncdb -q

# إنشاء مستخدم إداري افتراضي
echo "👤 إنشاء مستخدم إداري..."
python3 manage.py shell -c "
from django.contrib.auth.models import User
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('تم إنشاء المستخدم: admin / admin123')
else:
    print('المستخدم admin موجود مسبقاً')
"

# بيانات تجريبية
python3 manage.py shell -c "
from insurance.models import InsuranceSettings, Employee, FamilyMember
import datetime
if not InsuranceSettings.objects.exists():
    s = InsuranceSettings.objects.create(
        name='السياسة الافتراضية',
        inpatient_coverage_pct=90, outpatient_coverage_pct=70,
        employee_annual_limit=15000, family_member_annual_limit=10000,
        max_per_claim=5000, is_active=True
    )
    e = Employee.objects.create(
        employee_id='EMP001', full_name='أحمد محمد العمري',
        national_id='1234567890', gender='M',
        date_of_birth=datetime.date(1985,5,15),
        hire_date=datetime.date(2015,1,1),
        department='تقنية المعلومات', phone='0501234567',
        insurance_settings=s
    )
    FamilyMember.objects.create(
        employee=e, full_name='نورة أحمد العمري',
        relation='spouse', date_of_birth=datetime.date(1988,3,10)
    )
    print('تم إضافة بيانات تجريبية')
"

echo ""
echo "========================================"
echo "✅ الإعداد اكتمل!"
echo ""
echo "🌐 افتح في المتصفح: http://localhost:8000"
echo "🔐 لوحة الإدارة:   http://localhost:8000/admin"
echo "    المستخدم: admin"
echo "    كلمة المرور: admin123"
echo "========================================"
echo ""
echo "▶️  لتشغيل النظام:"
echo "    python3 manage.py runserver"
echo ""
python3 manage.py runserver
