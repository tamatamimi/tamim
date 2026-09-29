-- =============================================================================
-- بيانات أولية تجريبية
-- =============================================================================

-- إعدادات التأمين الافتراضية
INSERT INTO hi_settings (
    settings_name, inpatient_pct, outpatient_pct,
    emp_annual_limit, fam_annual_limit, max_per_claim, is_active
) VALUES (
    'الخطة التأمينية الافتراضية 2026',
    90, 70, 50000, 30000, 15000, 1
);

-- موظف 1
INSERT INTO hi_employees (
    emp_number, full_name, national_id, gender, birth_date, hire_date,
    department, job_title, phone, email, settings_id
) VALUES (
    'EMP-001', 'أحمد محمد العمري', '1234567890', 'M',
    DATE '1985-03-15', DATE '2015-06-01',
    'تقنية المعلومات', 'مطور برمجيات أول',
    '0501234567', 'ahmed@company.com',
    (SELECT settings_id FROM hi_settings WHERE is_active = 1 AND ROWNUM = 1)
);

-- عائلة الموظف 1
INSERT INTO hi_family_members (employee_id, full_name, national_id, relation, birth_date)
VALUES ((SELECT employee_id FROM hi_employees WHERE emp_number='EMP-001'),
        'سارة أحمد العمري', '2345678901', 'SPOUSE', DATE '1988-07-20');

INSERT INTO hi_family_members (employee_id, full_name, relation, birth_date)
VALUES ((SELECT employee_id FROM hi_employees WHERE emp_number='EMP-001'),
        'محمد أحمد العمري', 'SON', DATE '2012-04-10');

-- موظف 2
INSERT INTO hi_employees (
    emp_number, full_name, national_id, gender, birth_date, hire_date,
    department, job_title, phone, email, settings_id
) VALUES (
    'EMP-002', 'فاطمة خالد الزهراني', '3456789012', 'F',
    DATE '1990-11-05', DATE '2018-09-15',
    'الموارد البشرية', 'مختصة موارد بشرية',
    '0557654321', 'fatima@company.com',
    (SELECT settings_id FROM hi_settings WHERE is_active = 1 AND ROWNUM = 1)
);

INSERT INTO hi_family_members (employee_id, full_name, national_id, relation, birth_date)
VALUES ((SELECT employee_id FROM hi_employees WHERE emp_number='EMP-002'),
        'خالد عبدالله الزهراني', '4567890123', 'FATHER', DATE '1958-02-28');

-- موظف 3
INSERT INTO hi_employees (
    emp_number, full_name, national_id, gender, birth_date, hire_date,
    department, job_title, phone, email, settings_id
) VALUES (
    'EMP-003', 'عمر سعد القحطاني', '5678901234', 'M',
    DATE '1982-06-22', DATE '2010-03-01',
    'المالية', 'مدير حسابات',
    '0533445566', 'omar@company.com',
    (SELECT settings_id FROM hi_settings WHERE is_active = 1 AND ROWNUM = 1)
);

INSERT INTO hi_family_members (employee_id, full_name, relation, birth_date)
VALUES ((SELECT employee_id FROM hi_employees WHERE emp_number='EMP-003'),
        'نورة عمر القحطاني', 'SPOUSE', DATE '1985-09-14');
INSERT INTO hi_family_members (employee_id, full_name, relation, birth_date)
VALUES ((SELECT employee_id FROM hi_employees WHERE emp_number='EMP-003'),
        'سعد عمر القحطاني', 'SON', DATE '2010-01-20');
INSERT INTO hi_family_members (employee_id, full_name, relation, birth_date)
VALUES ((SELECT employee_id FROM hi_employees WHERE emp_number='EMP-003'),
        'لينا عمر القحطاني', 'DAUGHTER', DATE '2013-05-07');

-- مطالبات تجريبية
DECLARE
    v_emp1  NUMBER := (SELECT employee_id FROM hi_employees WHERE emp_number='EMP-001');
    v_emp2  NUMBER := (SELECT employee_id FROM hi_employees WHERE emp_number='EMP-002');
    v_emp3  NUMBER := (SELECT employee_id FROM hi_employees WHERE emp_number='EMP-003');
    v_mem1  NUMBER := (SELECT member_id FROM hi_family_members WHERE full_name='سارة أحمد العمري');
    v_clm_id    NUMBER;
    v_clm_num   VARCHAR2(25);
BEGIN
    -- مطالبة 1: موظف 1، رقود، مقبولة
    pkg_insurance.submit_claim(
        p_employee_id      => v_emp1,
        p_member_id        => NULL,
        p_beneficiary_type => 'EMPLOYEE',
        p_claim_type       => 'INPATIENT',
        p_claim_date       => DATE '2026-02-10',
        p_hospital_name    => 'مستشفى الحمادي',
        p_diagnosis        => 'استئصال الزائدة الدودية',
        p_invoice_amount   => 12000,
        p_notes            => NULL,
        p_claim_id         => v_clm_id,
        p_claim_number     => v_clm_num
    );
    pkg_insurance.review_claim(v_clm_id, 'APPROVED');

    -- مطالبة 2: موظف 1 - زوجة، عيادات خارجية، قيد المراجعة
    pkg_insurance.submit_claim(
        p_employee_id      => v_emp1,
        p_member_id        => v_mem1,
        p_beneficiary_type => 'FAMILY',
        p_claim_type       => 'OUTPATIENT',
        p_claim_date       => DATE '2026-04-18',
        p_hospital_name    => 'عيادة النخبة الطبية',
        p_diagnosis        => 'مراجعة دورية - ضغط الدم',
        p_invoice_amount   => 850,
        p_notes            => NULL,
        p_claim_id         => v_clm_id,
        p_claim_number     => v_clm_num
    );

    -- مطالبة 3: موظف 2، طوارئ، مدفوعة
    pkg_insurance.submit_claim(
        p_employee_id      => v_emp2,
        p_member_id        => NULL,
        p_beneficiary_type => 'EMPLOYEE',
        p_claim_type       => 'EMERGENCY',
        p_claim_date       => DATE '2026-01-25',
        p_hospital_name    => 'مستشفى المملكة',
        p_diagnosis        => 'كسر في الساعد الأيمن',
        p_invoice_amount   => 5500,
        p_claim_id         => v_clm_id,
        p_claim_number     => v_clm_num
    );
    pkg_insurance.review_claim(v_clm_id, 'APPROVED');
    pkg_insurance.review_claim(v_clm_id, 'PAID');

    -- مطالبة 4: موظف 3، رقود، مرفوضة
    pkg_insurance.submit_claim(
        p_employee_id      => v_emp3,
        p_member_id        => NULL,
        p_beneficiary_type => 'EMPLOYEE',
        p_claim_type       => 'INPATIENT',
        p_claim_date       => DATE '2026-03-05',
        p_hospital_name    => 'مستشفى الملك فيصل',
        p_diagnosis        => 'عملية تجميل',
        p_invoice_amount   => 8000,
        p_claim_id         => v_clm_id,
        p_claim_number     => v_clm_num
    );
    pkg_insurance.review_claim(
        v_clm_id, 'REJECTED',
        p_rejection_reason => 'العملية تجميلية وغير مشمولة بالبوليصة'
    );

    -- مطالبة 5: موظف 3، عيادات خارجية، قيد المراجعة
    pkg_insurance.submit_claim(
        p_employee_id      => v_emp3,
        p_member_id        => NULL,
        p_beneficiary_type => 'EMPLOYEE',
        p_claim_type       => 'OUTPATIENT',
        p_claim_date       => DATE '2026-06-12',
        p_hospital_name    => 'مركز ابن سينا الطبي',
        p_diagnosis        => 'مراجعة طب عيون - نظارات طبية',
        p_invoice_amount   => 1200,
        p_claim_id         => v_clm_id,
        p_claim_number     => v_clm_num
    );
END;
/

COMMIT;
