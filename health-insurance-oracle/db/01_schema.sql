-- =============================================================================
-- نظام إدارة التأمين الصحي للموظفين
-- Oracle Database 23c Free  |  APEX 24.x
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- جدول: إعدادات سياسة التأمين
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE hi_settings (
    settings_id       NUMBER GENERATED ALWAYS AS IDENTITY
                      CONSTRAINT pk_hi_settings PRIMARY KEY,
    settings_name     VARCHAR2(200 CHAR)  NOT NULL,
    inpatient_pct     NUMBER(5,2)  DEFAULT 90   NOT NULL,
    outpatient_pct    NUMBER(5,2)  DEFAULT 70   NOT NULL,
    emp_annual_limit  NUMBER(14,2) DEFAULT 50000 NOT NULL,
    fam_annual_limit  NUMBER(14,2) DEFAULT 30000 NOT NULL,
    max_per_claim     NUMBER(14,2) DEFAULT 15000 NOT NULL,
    is_active         NUMBER(1)    DEFAULT 1     NOT NULL,
    created_at        DATE         DEFAULT SYSDATE NOT NULL,
    created_by        VARCHAR2(100) DEFAULT SYS_CONTEXT('APEX$SESSION','APP_USER') NOT NULL,
    updated_at        DATE         DEFAULT SYSDATE NOT NULL,
    updated_by        VARCHAR2(100) DEFAULT SYS_CONTEXT('APEX$SESSION','APP_USER') NOT NULL,
    --
    CONSTRAINT chk_set_inpat   CHECK (inpatient_pct  BETWEEN 1 AND 100),
    CONSTRAINT chk_set_outpat  CHECK (outpatient_pct BETWEEN 1 AND 100),
    CONSTRAINT chk_set_active  CHECK (is_active IN (0, 1)),
    CONSTRAINT chk_set_maxclm  CHECK (max_per_claim > 0)
);

COMMENT ON TABLE  hi_settings                IS 'سياسات التأمين الصحي للشركة';
COMMENT ON COLUMN hi_settings.inpatient_pct  IS 'نسبة تغطية المريض الداخلي (رقود)';
COMMENT ON COLUMN hi_settings.outpatient_pct IS 'نسبة تغطية الطوارئ والعيادات الخارجية';
COMMENT ON COLUMN hi_settings.emp_annual_limit IS 'السقف السنوي للموظف بالريال';
COMMENT ON COLUMN hi_settings.fam_annual_limit IS 'السقف السنوي لكل فرد عائلة بالريال';
COMMENT ON COLUMN hi_settings.max_per_claim   IS 'الحد الأقصى للمطالبة الواحدة';


-- ─────────────────────────────────────────────────────────────────────────────
-- جدول: الموظفون
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE hi_employees (
    employee_id   NUMBER GENERATED ALWAYS AS IDENTITY
                  CONSTRAINT pk_hi_employees PRIMARY KEY,
    emp_number    VARCHAR2(20 CHAR)   NOT NULL CONSTRAINT uq_emp_number  UNIQUE,
    full_name     VARCHAR2(200 CHAR)  NOT NULL,
    national_id   VARCHAR2(20)        NOT NULL CONSTRAINT uq_emp_natid   UNIQUE,
    gender        VARCHAR2(1)         NOT NULL,
    birth_date    DATE                NOT NULL,
    hire_date     DATE                NOT NULL,
    department    VARCHAR2(100 CHAR),
    job_title     VARCHAR2(100 CHAR),
    phone         VARCHAR2(20),
    email         VARCHAR2(200),
    settings_id   NUMBER CONSTRAINT fk_emp_settings REFERENCES hi_settings(settings_id),
    is_active     NUMBER(1) DEFAULT 1 NOT NULL,
    created_at    DATE DEFAULT SYSDATE NOT NULL,
    created_by    VARCHAR2(100) DEFAULT SYS_CONTEXT('APEX$SESSION','APP_USER') NOT NULL,
    updated_at    DATE DEFAULT SYSDATE NOT NULL,
    updated_by    VARCHAR2(100) DEFAULT SYS_CONTEXT('APEX$SESSION','APP_USER') NOT NULL,
    --
    CONSTRAINT chk_emp_gender  CHECK (gender IN ('M', 'F')),
    CONSTRAINT chk_emp_active  CHECK (is_active IN (0, 1)),
    CONSTRAINT chk_emp_hire    CHECK (hire_date >= birth_date)
);

CREATE INDEX idx_emp_settings ON hi_employees(settings_id);
CREATE INDEX idx_emp_active   ON hi_employees(is_active);

COMMENT ON TABLE  hi_employees            IS 'بيانات الموظفين المشمولين بالتأمين';
COMMENT ON COLUMN hi_employees.gender     IS 'M=ذكر، F=أنثى';


-- ─────────────────────────────────────────────────────────────────────────────
-- جدول: أفراد عائلة الموظف
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE hi_family_members (
    member_id    NUMBER GENERATED ALWAYS AS IDENTITY
                 CONSTRAINT pk_hi_family PRIMARY KEY,
    employee_id  NUMBER NOT NULL
                 CONSTRAINT fk_fam_emp REFERENCES hi_employees(employee_id) ON DELETE CASCADE,
    full_name    VARCHAR2(200 CHAR) NOT NULL,
    national_id  VARCHAR2(20),
    relation     VARCHAR2(20)       NOT NULL,
    birth_date   DATE               NOT NULL,
    is_active    NUMBER(1) DEFAULT 1 NOT NULL,
    created_at   DATE DEFAULT SYSDATE NOT NULL,
    created_by   VARCHAR2(100) DEFAULT SYS_CONTEXT('APEX$SESSION','APP_USER') NOT NULL,
    --
    CONSTRAINT chk_fam_relation CHECK (relation IN ('SPOUSE','SON','DAUGHTER','FATHER','MOTHER','OTHER')),
    CONSTRAINT chk_fam_active   CHECK (is_active IN (0, 1))
);

CREATE INDEX idx_fam_employee ON hi_family_members(employee_id);

COMMENT ON COLUMN hi_family_members.relation IS 'صلة القرابة: SPOUSE/SON/DAUGHTER/FATHER/MOTHER/OTHER';


-- ─────────────────────────────────────────────────────────────────────────────
-- جدول: المطالبات التأمينية
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE hi_claims (
    claim_id          NUMBER GENERATED ALWAYS AS IDENTITY
                      CONSTRAINT pk_hi_claims PRIMARY KEY,
    claim_number      VARCHAR2(25)        NOT NULL CONSTRAINT uq_claim_number UNIQUE,
    employee_id       NUMBER              NOT NULL
                      CONSTRAINT fk_claim_emp REFERENCES hi_employees(employee_id),
    member_id         NUMBER
                      CONSTRAINT fk_claim_member REFERENCES hi_family_members(member_id),
    beneficiary_type  VARCHAR2(10)        NOT NULL,
    claim_type        VARCHAR2(15)        NOT NULL,
    claim_date        DATE                NOT NULL,
    hospital_name     VARCHAR2(200 CHAR)  NOT NULL,
    diagnosis         VARCHAR2(4000 CHAR) NOT NULL,
    invoice_amount    NUMBER(14,2)        NOT NULL,
    coverage_pct      NUMBER(5,2)         NOT NULL,
    insurance_amount  NUMBER(14,2)        NOT NULL,
    employee_amount   NUMBER(14,2)        NOT NULL,
    approved_amount   NUMBER(14,2)        DEFAULT 0,
    claim_status      VARCHAR2(20)        DEFAULT 'PENDING' NOT NULL,
    notes             VARCHAR2(4000 CHAR),
    rejection_reason  VARCHAR2(4000 CHAR),
    reviewed_by       VARCHAR2(100),
    reviewed_at       DATE,
    created_at        DATE DEFAULT SYSDATE NOT NULL,
    created_by        VARCHAR2(100) DEFAULT SYS_CONTEXT('APEX$SESSION','APP_USER') NOT NULL,
    updated_at        DATE DEFAULT SYSDATE NOT NULL,
    updated_by        VARCHAR2(100) DEFAULT SYS_CONTEXT('APEX$SESSION','APP_USER') NOT NULL,
    --
    CONSTRAINT chk_clm_bentype CHECK (beneficiary_type IN ('EMPLOYEE','FAMILY')),
    CONSTRAINT chk_clm_type    CHECK (claim_type IN ('INPATIENT','OUTPATIENT','EMERGENCY')),
    CONSTRAINT chk_clm_status  CHECK (claim_status IN ('PENDING','APPROVED','PARTIAL','REJECTED','PAID')),
    CONSTRAINT chk_clm_invoice CHECK (invoice_amount > 0),
    CONSTRAINT chk_clm_pct     CHECK (coverage_pct BETWEEN 0 AND 100),
    CONSTRAINT chk_clm_family  CHECK (
        (beneficiary_type = 'EMPLOYEE' AND member_id IS NULL) OR
        (beneficiary_type = 'FAMILY'   AND member_id IS NOT NULL)
    )
);

CREATE INDEX idx_clm_employee    ON hi_claims(employee_id);
CREATE INDEX idx_clm_member      ON hi_claims(member_id);
CREATE INDEX idx_clm_status      ON hi_claims(claim_status);
CREATE INDEX idx_clm_date        ON hi_claims(claim_date);
CREATE INDEX idx_clm_year        ON hi_claims(EXTRACT(YEAR FROM claim_date));

COMMENT ON TABLE  hi_claims               IS 'مطالبات التأمين الصحي';
COMMENT ON COLUMN hi_claims.claim_status  IS 'PENDING/APPROVED/PARTIAL/REJECTED/PAID';


-- ─────────────────────────────────────────────────────────────────────────────
-- جدول: مستندات المطالبة (BLOB في قاعدة البيانات)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE hi_documents (
    document_id   NUMBER GENERATED ALWAYS AS IDENTITY
                  CONSTRAINT pk_hi_docs PRIMARY KEY,
    claim_id      NUMBER       NOT NULL
                  CONSTRAINT fk_doc_claim REFERENCES hi_claims(claim_id) ON DELETE CASCADE,
    doc_type      VARCHAR2(20) NOT NULL,
    filename      VARCHAR2(500 CHAR) NOT NULL,
    file_content  BLOB,
    mime_type     VARCHAR2(100),
    file_size     NUMBER,
    uploaded_at   DATE DEFAULT SYSDATE NOT NULL,
    uploaded_by   VARCHAR2(100) DEFAULT SYS_CONTEXT('APEX$SESSION','APP_USER') NOT NULL,
    --
    CONSTRAINT chk_doc_type CHECK (doc_type IN (
        'INVOICE','DOCTOR_REQUEST','PRESCRIPTION',
        'LAB_RESULT','XRAY','DISCHARGE','OTHER'
    ))
);

CREATE INDEX idx_doc_claim ON hi_documents(claim_id);

-- SecureFile LOB for efficient storage
ALTER TABLE hi_documents MODIFY (file_content BLOB) LOB (file_content) STORE AS SECUREFILE;

COMMENT ON TABLE  hi_documents IS 'المستندات المرفقة بالمطالبات (فواتير، طلبات طبيب، أشعة...)';


-- ─────────────────────────────────────────────────────────────────────────────
-- Triggers: تحديث تلقائي لحقلَي updated_at / updated_by
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_hi_settings_aud
    BEFORE UPDATE ON hi_settings
    FOR EACH ROW
BEGIN
    :NEW.updated_at := SYSDATE;
    :NEW.updated_by := NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER);
END;
/

CREATE OR REPLACE TRIGGER trg_hi_employees_aud
    BEFORE UPDATE ON hi_employees
    FOR EACH ROW
BEGIN
    :NEW.updated_at := SYSDATE;
    :NEW.updated_by := NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER);
END;
/

CREATE OR REPLACE TRIGGER trg_hi_claims_aud
    BEFORE UPDATE ON hi_claims
    FOR EACH ROW
BEGIN
    :NEW.updated_at := SYSDATE;
    :NEW.updated_by := NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER);
    -- عند المراجعة نحفظ المراجع وتوقيت المراجعة
    IF :NEW.claim_status != :OLD.claim_status AND :NEW.claim_status IN ('APPROVED','PARTIAL','REJECTED') THEN
        :NEW.reviewed_by := NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER);
        :NEW.reviewed_at := SYSDATE;
    END IF;
END;
/
