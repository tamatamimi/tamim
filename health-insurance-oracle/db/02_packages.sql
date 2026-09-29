-- =============================================================================
-- PKG_INSURANCE  – حزمة منطق عمليات التأمين الصحي
-- =============================================================================

CREATE OR REPLACE PACKAGE pkg_insurance AS

    -- أنواع
    TYPE t_coverage_result IS RECORD (
        coverage_pct      NUMBER,
        insurance_amount  NUMBER,
        employee_amount   NUMBER
    );

    -- حساب التغطية لمطالبة جديدة
    FUNCTION  calculate_coverage (
        p_invoice_amount  IN  NUMBER,
        p_claim_type      IN  VARCHAR2,   -- INPATIENT | OUTPATIENT | EMERGENCY
        p_employee_id     IN  NUMBER,
        p_claim_date      IN  DATE DEFAULT SYSDATE
    ) RETURN t_coverage_result;

    -- إجمالي ما صُرف خلال سنة معينة (موظف أو فرد عائلة)
    FUNCTION  get_annual_used (
        p_entity_type  IN  VARCHAR2,  -- EMPLOYEE | FAMILY
        p_entity_id    IN  NUMBER,
        p_year         IN  NUMBER DEFAULT EXTRACT(YEAR FROM SYSDATE)
    ) RETURN NUMBER;

    -- توليد رقم مطالبة تسلسلي
    FUNCTION  generate_claim_number (
        p_date  IN  DATE DEFAULT SYSDATE
    ) RETURN VARCHAR2;

    -- تقديم مطالبة جديدة كاملة
    PROCEDURE submit_claim (
        p_employee_id      IN  NUMBER,
        p_member_id        IN  NUMBER   DEFAULT NULL,
        p_beneficiary_type IN  VARCHAR2,
        p_claim_type       IN  VARCHAR2,
        p_claim_date       IN  DATE,
        p_hospital_name    IN  VARCHAR2,
        p_diagnosis        IN  VARCHAR2,
        p_invoice_amount   IN  NUMBER,
        p_notes            IN  VARCHAR2 DEFAULT NULL,
        p_claim_id         OUT NUMBER,
        p_claim_number     OUT VARCHAR2
    );

    -- مراجعة المطالبة (قبول / رفض / قبول جزئي)
    PROCEDURE review_claim (
        p_claim_id         IN  NUMBER,
        p_new_status       IN  VARCHAR2,
        p_approved_amount  IN  NUMBER   DEFAULT NULL,
        p_notes            IN  VARCHAR2 DEFAULT NULL,
        p_rejection_reason IN  VARCHAR2 DEFAULT NULL
    );

END pkg_insurance;
/


CREATE OR REPLACE PACKAGE BODY pkg_insurance AS

    -- ─────────────────────────────────────────────────────────────────────────
    -- الحصول على إعدادات التأمين للموظف
    -- ─────────────────────────────────────────────────────────────────────────
    FUNCTION get_settings (p_employee_id IN NUMBER)
        RETURN hi_settings%ROWTYPE
    AS
        v_rec hi_settings%ROWTYPE;
    BEGIN
        SELECT s.*
          INTO v_rec
          FROM hi_settings s
         WHERE s.settings_id = (
               SELECT NVL(e.settings_id,
                    (SELECT MIN(settings_id) FROM hi_settings WHERE is_active = 1))
                 FROM hi_employees e
                WHERE e.employee_id = p_employee_id
               )
          AND ROWNUM = 1;
        RETURN v_rec;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            SELECT s.*
              INTO v_rec
              FROM hi_settings s
             WHERE s.is_active = 1
               AND ROWNUM = 1;
            RETURN v_rec;
    END get_settings;


    -- ─────────────────────────────────────────────────────────────────────────
    -- إجمالي التأمين المُصرف خلال سنة (موظف أو فرد عائلة)
    -- ─────────────────────────────────────────────────────────────────────────
    FUNCTION get_annual_used (
        p_entity_type  IN  VARCHAR2,
        p_entity_id    IN  NUMBER,
        p_year         IN  NUMBER DEFAULT EXTRACT(YEAR FROM SYSDATE)
    ) RETURN NUMBER
    AS
        v_used NUMBER := 0;
    BEGIN
        IF p_entity_type = 'EMPLOYEE' THEN
            SELECT NVL(SUM(c.insurance_amount), 0)
              INTO v_used
              FROM hi_claims c
             WHERE c.employee_id       = p_entity_id
               AND c.beneficiary_type  = 'EMPLOYEE'
               AND c.claim_status     NOT IN ('REJECTED')
               AND EXTRACT(YEAR FROM c.claim_date) = p_year;

        ELSIF p_entity_type = 'FAMILY' THEN
            SELECT NVL(SUM(c.insurance_amount), 0)
              INTO v_used
              FROM hi_claims c
             WHERE c.member_id         = p_entity_id
               AND c.claim_status     NOT IN ('REJECTED')
               AND EXTRACT(YEAR FROM c.claim_date) = p_year;
        END IF;

        RETURN v_used;
    END get_annual_used;


    -- ─────────────────────────────────────────────────────────────────────────
    -- توليد رقم المطالبة: CLM-YYYY-NNNNN
    -- ─────────────────────────────────────────────────────────────────────────
    FUNCTION generate_claim_number (p_date IN DATE DEFAULT SYSDATE)
        RETURN VARCHAR2
    AS
        v_year   VARCHAR2(4) := TO_CHAR(p_date, 'YYYY');
        v_seq    NUMBER;
        v_number VARCHAR2(25);
    BEGIN
        SELECT NVL(MAX(TO_NUMBER(REGEXP_SUBSTR(claim_number, '\d{5}$'))), 0) + 1
          INTO v_seq
          FROM hi_claims
         WHERE claim_number LIKE 'CLM-' || v_year || '-%';

        v_number := 'CLM-' || v_year || '-' || LPAD(v_seq, 5, '0');
        RETURN v_number;
    END generate_claim_number;


    -- ─────────────────────────────────────────────────────────────────────────
    -- حساب التغطية التأمينية
    -- ─────────────────────────────────────────────────────────────────────────
    FUNCTION calculate_coverage (
        p_invoice_amount  IN  NUMBER,
        p_claim_type      IN  VARCHAR2,
        p_employee_id     IN  NUMBER,
        p_claim_date      IN  DATE DEFAULT SYSDATE
    ) RETURN t_coverage_result
    AS
        v_settings   hi_settings%ROWTYPE;
        v_result     t_coverage_result;
        v_pct        NUMBER;
        v_capped     NUMBER;
        v_gross_ins  NUMBER;
        v_annual_limit   NUMBER;
        v_annual_used    NUMBER;
        v_remaining      NUMBER;
    BEGIN
        v_settings := get_settings(p_employee_id);

        -- نسبة التغطية حسب نوع المطالبة
        v_pct := CASE p_claim_type
                     WHEN 'INPATIENT' THEN v_settings.inpatient_pct
                     ELSE v_settings.outpatient_pct      -- OUTPATIENT + EMERGENCY
                 END;

        -- الفاتورة مقيّدة بالحد الأقصى للمطالبة
        v_capped   := LEAST(p_invoice_amount, v_settings.max_per_claim);
        v_gross_ins := ROUND(v_capped * v_pct / 100, 2);

        -- السقف السنوي للموظف
        v_annual_limit := v_settings.emp_annual_limit;
        v_annual_used  := get_annual_used(
            'EMPLOYEE', p_employee_id,
            EXTRACT(YEAR FROM p_claim_date)
        );
        v_remaining := GREATEST(v_annual_limit - v_annual_used, 0);

        -- مبلغ التأمين لا يتجاوز المتبقي من السقف
        v_result.coverage_pct     := v_pct;
        v_result.insurance_amount := ROUND(LEAST(v_gross_ins, v_remaining), 2);
        v_result.employee_amount  := ROUND(p_invoice_amount - v_result.insurance_amount, 2);

        RETURN v_result;
    END calculate_coverage;


    -- ─────────────────────────────────────────────────────────────────────────
    -- تقديم مطالبة جديدة
    -- ─────────────────────────────────────────────────────────────────────────
    PROCEDURE submit_claim (
        p_employee_id      IN  NUMBER,
        p_member_id        IN  NUMBER   DEFAULT NULL,
        p_beneficiary_type IN  VARCHAR2,
        p_claim_type       IN  VARCHAR2,
        p_claim_date       IN  DATE,
        p_hospital_name    IN  VARCHAR2,
        p_diagnosis        IN  VARCHAR2,
        p_invoice_amount   IN  NUMBER,
        p_notes            IN  VARCHAR2 DEFAULT NULL,
        p_claim_id         OUT NUMBER,
        p_claim_number     OUT VARCHAR2
    )
    AS
        v_coverage   t_coverage_result;
        v_claim_num  VARCHAR2(25);
        v_id         NUMBER;
    BEGIN
        -- حساب التغطية
        v_coverage  := calculate_coverage(p_invoice_amount, p_claim_type, p_employee_id, p_claim_date);
        v_claim_num := generate_claim_number(p_claim_date);

        INSERT INTO hi_claims (
            claim_number, employee_id, member_id, beneficiary_type,
            claim_type, claim_date, hospital_name, diagnosis,
            invoice_amount, coverage_pct, insurance_amount, employee_amount,
            approved_amount, claim_status, notes
        ) VALUES (
            v_claim_num, p_employee_id, p_member_id, p_beneficiary_type,
            p_claim_type, p_claim_date, p_hospital_name, p_diagnosis,
            p_invoice_amount, v_coverage.coverage_pct,
            v_coverage.insurance_amount, v_coverage.employee_amount,
            v_coverage.insurance_amount,  -- approved = insurance initially
            'PENDING', p_notes
        )
        RETURNING claim_id INTO v_id;

        p_claim_id     := v_id;
        p_claim_number := v_claim_num;

        COMMIT;
    END submit_claim;


    -- ─────────────────────────────────────────────────────────────────────────
    -- مراجعة المطالبة
    -- ─────────────────────────────────────────────────────────────────────────
    PROCEDURE review_claim (
        p_claim_id         IN  NUMBER,
        p_new_status       IN  VARCHAR2,
        p_approved_amount  IN  NUMBER   DEFAULT NULL,
        p_notes            IN  VARCHAR2 DEFAULT NULL,
        p_rejection_reason IN  VARCHAR2 DEFAULT NULL
    )
    AS
        v_status VARCHAR2(20) := UPPER(p_new_status);
    BEGIN
        IF v_status NOT IN ('APPROVED','PARTIAL','REJECTED','PAID') THEN
            RAISE_APPLICATION_ERROR(-20001, 'حالة غير صالحة: ' || p_new_status);
        END IF;

        UPDATE hi_claims
           SET claim_status      = v_status,
               approved_amount   = NVL(p_approved_amount, approved_amount),
               notes             = NVL(p_notes, notes),
               rejection_reason  = p_rejection_reason
         WHERE claim_id = p_claim_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'المطالبة غير موجودة: ' || p_claim_id);
        END IF;

        COMMIT;
    END review_claim;

END pkg_insurance;
/
