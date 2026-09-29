-- =============================================================================
-- Views مُحسَّنة لـ APEX  (Interactive Reports, Cards, Charts)
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- V_CLAIMS – المطالبات المُدمجة مع أسماء الموظفين والمستفيدين
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_claims AS
SELECT
    c.claim_id,
    c.claim_number,
    c.employee_id,
    e.emp_number,
    e.full_name                              AS employee_name,
    e.department,
    c.member_id,
    f.full_name                              AS member_name,
    c.beneficiary_type,
    NVL(f.full_name, e.full_name)            AS beneficiary_name,
    c.claim_type,
    CASE c.claim_type
        WHEN 'INPATIENT'   THEN 'مريض داخلي'
        WHEN 'OUTPATIENT'  THEN 'عيادات خارجية'
        WHEN 'EMERGENCY'   THEN 'طوارئ'
    END                                      AS claim_type_ar,
    c.claim_date,
    c.hospital_name,
    c.diagnosis,
    c.invoice_amount,
    c.coverage_pct,
    c.insurance_amount,
    c.employee_amount,
    c.approved_amount,
    c.claim_status,
    CASE c.claim_status
        WHEN 'PENDING'   THEN 'قيد المراجعة'
        WHEN 'APPROVED'  THEN 'مقبولة'
        WHEN 'PARTIAL'   THEN 'مقبولة جزئياً'
        WHEN 'REJECTED'  THEN 'مرفوضة'
        WHEN 'PAID'      THEN 'مدفوعة'
    END                                      AS status_ar,
    -- لون الشارة في APEX
    CASE c.claim_status
        WHEN 'PENDING'   THEN 'u-color-21'
        WHEN 'APPROVED'  THEN 'u-color-20'
        WHEN 'PARTIAL'   THEN 'u-color-17'
        WHEN 'REJECTED'  THEN 'u-color-2'
        WHEN 'PAID'      THEN 'u-color-18'
    END                                      AS status_badge_class,
    c.notes,
    c.rejection_reason,
    c.reviewed_by,
    c.reviewed_at,
    c.created_at,
    c.created_by,
    c.updated_at,
    EXTRACT(YEAR FROM c.claim_date)          AS claim_year,
    EXTRACT(MONTH FROM c.claim_date)         AS claim_month
FROM hi_claims c
JOIN hi_employees    e ON e.employee_id = c.employee_id
LEFT JOIN hi_family_members f ON f.member_id = c.member_id;


-- ─────────────────────────────────────────────────────────────────────────────
-- V_EMPLOYEE_STATS – إحصائيات كل موظف (للوحة التحكم والتقارير)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_employee_stats AS
SELECT
    e.employee_id,
    e.emp_number,
    e.full_name,
    e.department,
    e.job_title,
    e.gender,
    e.is_active,
    EXTRACT(YEAR FROM SYSDATE)               AS cur_year,
    s.emp_annual_limit,
    NVL((
        SELECT SUM(c.insurance_amount)
          FROM hi_claims c
         WHERE c.employee_id      = e.employee_id
           AND c.claim_status    NOT IN ('REJECTED')
           AND EXTRACT(YEAR FROM c.claim_date) = EXTRACT(YEAR FROM SYSDATE)
    ), 0)                                    AS annual_used,
    s.emp_annual_limit - NVL((
        SELECT SUM(c.insurance_amount)
          FROM hi_claims c
         WHERE c.employee_id      = e.employee_id
           AND c.claim_status    NOT IN ('REJECTED')
           AND EXTRACT(YEAR FROM c.claim_date) = EXTRACT(YEAR FROM SYSDATE)
    ), 0)                                    AS annual_remaining,
    ROUND(NVL((
        SELECT SUM(c.insurance_amount)
          FROM hi_claims c
         WHERE c.employee_id      = e.employee_id
           AND c.claim_status    NOT IN ('REJECTED')
           AND EXTRACT(YEAR FROM c.claim_date) = EXTRACT(YEAR FROM SYSDATE)
    ), 0) / NULLIF(s.emp_annual_limit, 0) * 100, 1) AS usage_pct,
    NVL((
        SELECT COUNT(*)
          FROM hi_claims c
         WHERE c.employee_id = e.employee_id
           AND EXTRACT(YEAR FROM c.claim_date) = EXTRACT(YEAR FROM SYSDATE)
    ), 0)                                    AS claims_count,
    NVL((
        SELECT COUNT(*)
          FROM hi_family_members f
         WHERE f.employee_id = e.employee_id AND f.is_active = 1
    ), 0)                                    AS family_count,
    s.inpatient_pct,
    s.outpatient_pct,
    s.max_per_claim,
    s.fam_annual_limit
FROM hi_employees e
LEFT JOIN hi_settings s ON s.settings_id = NVL(
    e.settings_id,
    (SELECT MIN(settings_id) FROM hi_settings WHERE is_active = 1)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- V_DASHBOARD – ملخص لوحة التحكم (صف واحد لكل سنة)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_dashboard AS
SELECT
    EXTRACT(YEAR FROM SYSDATE)  AS report_year,
    (SELECT COUNT(*) FROM hi_employees WHERE is_active = 1) AS total_employees,
    COUNT(c.claim_id)            AS total_claims,
    SUM(CASE WHEN c.claim_status = 'PENDING'  THEN 1 ELSE 0 END) AS pending_claims,
    SUM(CASE WHEN c.claim_status = 'APPROVED' THEN 1 ELSE 0 END) AS approved_claims,
    SUM(CASE WHEN c.claim_status = 'REJECTED' THEN 1 ELSE 0 END) AS rejected_claims,
    ROUND(NVL(SUM(c.invoice_amount),    0), 2) AS total_invoice,
    ROUND(NVL(SUM(c.insurance_amount),  0), 2) AS total_insurance,
    ROUND(NVL(SUM(c.employee_amount),   0), 2) AS total_employee_cost
FROM hi_claims c
WHERE EXTRACT(YEAR FROM c.claim_date) = EXTRACT(YEAR FROM SYSDATE);


-- ─────────────────────────────────────────────────────────────────────────────
-- V_MONTHLY_CHART – بيانات الرسم البياني الشهري (Oracle JET Chart)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_monthly_chart AS
SELECT
    EXTRACT(YEAR  FROM claim_date) AS chart_year,
    EXTRACT(MONTH FROM claim_date) AS chart_month,
    TO_CHAR(claim_date, 'Mon YYYY', 'NLS_DATE_LANGUAGE=ARABIC') AS month_label,
    COUNT(*)                       AS claim_count,
    ROUND(SUM(invoice_amount),   2) AS total_invoice,
    ROUND(SUM(insurance_amount), 2) AS total_insurance,
    ROUND(SUM(employee_amount),  2) AS total_employee_cost
FROM hi_claims
WHERE claim_status NOT IN ('REJECTED')
GROUP BY
    EXTRACT(YEAR  FROM claim_date),
    EXTRACT(MONTH FROM claim_date),
    TO_CHAR(claim_date, 'Mon YYYY', 'NLS_DATE_LANGUAGE=ARABIC')
ORDER BY chart_year, chart_month;


-- ─────────────────────────────────────────────────────────────────────────────
-- V_FAMILY_STATS – استهلاك كل فرد من أفراد العائلة
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_family_stats AS
SELECT
    f.member_id,
    f.employee_id,
    e.full_name                             AS employee_name,
    f.full_name                             AS member_name,
    f.relation,
    CASE f.relation
        WHEN 'SPOUSE'    THEN 'زوج/زوجة'
        WHEN 'SON'       THEN 'ابن'
        WHEN 'DAUGHTER'  THEN 'ابنة'
        WHEN 'FATHER'    THEN 'والد'
        WHEN 'MOTHER'    THEN 'والدة'
        ELSE 'أخرى'
    END                                     AS relation_ar,
    f.birth_date,
    f.is_active,
    s.fam_annual_limit,
    NVL((
        SELECT SUM(c.insurance_amount)
          FROM hi_claims c
         WHERE c.member_id = f.member_id
           AND c.claim_status NOT IN ('REJECTED')
           AND EXTRACT(YEAR FROM c.claim_date) = EXTRACT(YEAR FROM SYSDATE)
    ), 0)                                   AS annual_used,
    s.fam_annual_limit - NVL((
        SELECT SUM(c.insurance_amount)
          FROM hi_claims c
         WHERE c.member_id = f.member_id
           AND c.claim_status NOT IN ('REJECTED')
           AND EXTRACT(YEAR FROM c.claim_date) = EXTRACT(YEAR FROM SYSDATE)
    ), 0)                                   AS annual_remaining,
    NVL((
        SELECT COUNT(*)
          FROM hi_claims c
         WHERE c.member_id = f.member_id
           AND EXTRACT(YEAR FROM c.claim_date) = EXTRACT(YEAR FROM SYSDATE)
    ), 0)                                   AS claims_count
FROM hi_family_members f
JOIN hi_employees e ON e.employee_id = f.employee_id
LEFT JOIN hi_settings s ON s.settings_id = NVL(
    e.settings_id,
    (SELECT MIN(settings_id) FROM hi_settings WHERE is_active = 1)
);
