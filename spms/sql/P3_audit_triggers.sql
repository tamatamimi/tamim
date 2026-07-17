--------------------------------------------------------------------------------
-- SPMS - Prompt P3 - AUDIT_LOG triggers/hooks
-- ملء سجل التدقيق تلقائياً (القسم 6.3، REQ-054).
--
-- التغطية الإلزامية بنص الوثيقة:
--   * اعتماد الخطط/التقارير      => triggers على strategic_plans/operational_plans/achievements
--   * تعديل المستخدمين           => trigger على users
--   * إدخال/تعديل البيانات        => triggers على op_plan_items/kpi_yearly_targets/achievements
--
-- القواعد:
--   * INSERT                                   => CREATE
--   * UPDATE يطفئ is_active (1 -> 0)           => DELETE  (soft-delete AD-06)
--   * UPDATE يحوّل الحالة إلى APPROVED
--     أو يملأ approved_by                       => APPROVE
--   * غير ذلك                                  => UPDATE
--
-- الكتابة تتم عبر pkg_security.log_action (معاملة مستقلة) فيُلتقط سياق
-- المستخدم الحالي إن كان مضبوطاً. تسجيل LOGIN/LOGOUT يُستدعى من هوك
-- المصادقة في تطبيق APEX (المرحلة P4) وليس من قاعدة البيانات.
--
-- ملاحظة: حزم الأعمال (PKG_INHERITANCE) تسجّل أيضاً أحداثها الدلالية
-- (derive_plan/new_version)؛ الـ triggers هنا تسجّل تغيّر الصفوف نفسها -
-- المساران متكاملان لا متعارضان.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- USERS: تعديل المستخدمين (إلزامي)
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_users_audit
AFTER INSERT OR UPDATE ON users
FOR EACH ROW
DECLARE
    l_action audit_log.action_type%TYPE;
    l_old    CLOB;
    l_new    CLOB;
BEGIN
    IF INSERTING THEN
        l_action := 'CREATE';
    ELSIF :OLD.is_active = 1 AND :NEW.is_active = 0 THEN
        l_action := 'DELETE';
    ELSE
        l_action := 'UPDATE';
    END IF;

    IF UPDATING THEN
        l_old := JSON_OBJECT(
            'username'    VALUE :OLD.username,
            'full_name'   VALUE :OLD.full_name,
            'email'       VALUE :OLD.email,
            'org_unit_id' VALUE :OLD.org_unit_id,
            'status'      VALUE :OLD.status,
            'is_active'   VALUE :OLD.is_active);
    END IF;
    l_new := JSON_OBJECT(
        'username'    VALUE :NEW.username,
        'full_name'   VALUE :NEW.full_name,
        'email'       VALUE :NEW.email,
        'org_unit_id' VALUE :NEW.org_unit_id,
        'status'      VALUE :NEW.status,
        'is_active'   VALUE :NEW.is_active);

    pkg_security.log_action(l_action, 'USERS', :NEW.user_id, l_old, l_new);
END;
/

--------------------------------------------------------------------------------
-- STRATEGIC_PLANS: اعتماد الخطة الاستراتيجية وإصداراتها
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_strategic_plans_audit
AFTER INSERT OR UPDATE ON strategic_plans
FOR EACH ROW
DECLARE
    l_action audit_log.action_type%TYPE;
    l_old    CLOB;
    l_new    CLOB;
BEGIN
    IF INSERTING THEN
        l_action := 'CREATE';
    ELSIF :OLD.is_active = 1 AND :NEW.is_active = 0 THEN
        l_action := 'DELETE';
    ELSIF :OLD.status <> 'APPROVED' AND :NEW.status = 'APPROVED' THEN
        l_action := 'APPROVE';
    ELSE
        l_action := 'UPDATE';
    END IF;

    IF UPDATING THEN
        l_old := JSON_OBJECT(
            'title_ar'       VALUE :OLD.title_ar,
            'status'         VALUE :OLD.status,
            'version_no'     VALUE :OLD.version_no,
            'effective_from' VALUE TO_CHAR(:OLD.effective_from, 'YYYY-MM-DD'),
            'is_active'      VALUE :OLD.is_active);
    END IF;
    l_new := JSON_OBJECT(
        'title_ar'       VALUE :NEW.title_ar,
        'status'         VALUE :NEW.status,
        'version_no'     VALUE :NEW.version_no,
        'effective_from' VALUE TO_CHAR(:NEW.effective_from, 'YYYY-MM-DD'),
        'is_active'      VALUE :NEW.is_active);

    pkg_security.log_action(l_action, 'STRATEGIC_PLANS', :NEW.plan_id, l_old, l_new);
END;
/

--------------------------------------------------------------------------------
-- OPERATIONAL_PLANS: إنشاء/اعتماد الخطط التشغيلية
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_operational_plans_audit
AFTER INSERT OR UPDATE ON operational_plans
FOR EACH ROW
DECLARE
    l_action audit_log.action_type%TYPE;
    l_old    CLOB;
    l_new    CLOB;
BEGIN
    IF INSERTING THEN
        l_action := 'CREATE';
    ELSIF :OLD.is_active = 1 AND :NEW.is_active = 0 THEN
        l_action := 'DELETE';
    ELSIF :OLD.status <> 'APPROVED' AND :NEW.status = 'APPROVED' THEN
        l_action := 'APPROVE';
    ELSE
        l_action := 'UPDATE';
    END IF;

    IF UPDATING THEN
        l_old := JSON_OBJECT(
            'org_unit_id'            VALUE :OLD.org_unit_id,
            'academic_year'          VALUE :OLD.academic_year,
            'status'                 VALUE :OLD.status,
            'strategic_plan_version' VALUE :OLD.strategic_plan_version,
            'is_active'              VALUE :OLD.is_active);
    END IF;
    l_new := JSON_OBJECT(
        'org_unit_id'            VALUE :NEW.org_unit_id,
        'academic_year'          VALUE :NEW.academic_year,
        'status'                 VALUE :NEW.status,
        'strategic_plan_version' VALUE :NEW.strategic_plan_version,
        'is_active'              VALUE :NEW.is_active);

    pkg_security.log_action(l_action, 'OPERATIONAL_PLANS', :NEW.op_plan_id, l_old, l_new);
END;
/

--------------------------------------------------------------------------------
-- OP_PLAN_ITEMS: تعديل بيانات عناصر الخطة (المستهدفات والمسؤوليات)
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_op_plan_items_audit
AFTER INSERT OR UPDATE ON op_plan_items
FOR EACH ROW
DECLARE
    l_action audit_log.action_type%TYPE;
    l_old    CLOB;
    l_new    CLOB;
BEGIN
    IF INSERTING THEN
        l_action := 'CREATE';
    ELSIF :OLD.is_active = 1 AND :NEW.is_active = 0 THEN
        l_action := 'DELETE';
    ELSE
        l_action := 'UPDATE';
    END IF;

    IF UPDATING THEN
        l_old := JSON_OBJECT(
            'op_plan_id'          VALUE :OLD.op_plan_id,
            'source_kpi_id'       VALUE :OLD.source_kpi_id,
            'yearly_target'       VALUE :OLD.yearly_target,
            'responsible_unit_id' VALUE :OLD.responsible_unit_id,
            'is_locally_added'    VALUE :OLD.is_locally_added,
            'is_active'           VALUE :OLD.is_active);
    END IF;
    l_new := JSON_OBJECT(
        'op_plan_id'          VALUE :NEW.op_plan_id,
        'source_kpi_id'       VALUE :NEW.source_kpi_id,
        'yearly_target'       VALUE :NEW.yearly_target,
        'responsible_unit_id' VALUE :NEW.responsible_unit_id,
        'is_locally_added'    VALUE :NEW.is_locally_added,
        'is_active'           VALUE :NEW.is_active);

    pkg_security.log_action(l_action, 'OP_PLAN_ITEMS', :NEW.item_id, l_old, l_new);
END;
/

--------------------------------------------------------------------------------
-- ACHIEVEMENTS: إدخال الإنجاز واعتماده (ملء approved_by = اعتماد)
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_achievements_audit
AFTER INSERT OR UPDATE ON achievements
FOR EACH ROW
DECLARE
    l_action audit_log.action_type%TYPE;
    l_old    CLOB;
    l_new    CLOB;
BEGIN
    IF INSERTING THEN
        l_action := 'CREATE';
    ELSIF :OLD.is_active = 1 AND :NEW.is_active = 0 THEN
        l_action := 'DELETE';
    ELSIF :OLD.approved_by IS NULL AND :NEW.approved_by IS NOT NULL THEN
        l_action := 'APPROVE';
    ELSE
        l_action := 'UPDATE';
    END IF;

    IF UPDATING THEN
        l_old := JSON_OBJECT(
            'op_plan_item_id' VALUE :OLD.op_plan_item_id,
            'period_type'     VALUE :OLD.period_type,
            'actual_value'    VALUE :OLD.actual_value,
            'reported_by'     VALUE :OLD.reported_by,
            'approved_by'     VALUE :OLD.approved_by,
            'is_active'       VALUE :OLD.is_active);
    END IF;
    l_new := JSON_OBJECT(
        'op_plan_item_id' VALUE :NEW.op_plan_item_id,
        'period_type'     VALUE :NEW.period_type,
        'actual_value'    VALUE :NEW.actual_value,
        'reported_by'     VALUE :NEW.reported_by,
        'approved_by'     VALUE :NEW.approved_by,
        'is_active'       VALUE :NEW.is_active);

    pkg_security.log_action(l_action, 'ACHIEVEMENTS', :NEW.achievement_id, l_old, l_new);
END;
/

--------------------------------------------------------------------------------
-- KPI_YEARLY_TARGETS: إدخال/تعديل المستهدفات السنوية (REQ-030)
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_kpi_yearly_targets_audit
AFTER INSERT OR UPDATE ON kpi_yearly_targets
FOR EACH ROW
DECLARE
    l_action audit_log.action_type%TYPE;
    l_old    CLOB;
    l_new    CLOB;
BEGIN
    IF INSERTING THEN
        l_action := 'CREATE';
    ELSIF :OLD.is_active = 1 AND :NEW.is_active = 0 THEN
        l_action := 'DELETE';
    ELSE
        l_action := 'UPDATE';
    END IF;

    IF UPDATING THEN
        l_old := JSON_OBJECT(
            'kpi_id'       VALUE :OLD.kpi_id,
            'target_year'  VALUE :OLD.target_year,
            'value_target' VALUE :OLD.value_target,
            'is_active'    VALUE :OLD.is_active);
    END IF;
    l_new := JSON_OBJECT(
        'kpi_id'       VALUE :NEW.kpi_id,
        'target_year'  VALUE :NEW.target_year,
        'value_target' VALUE :NEW.value_target,
        'is_active'    VALUE :NEW.is_active);

    pkg_security.log_action(l_action, 'KPI_YEARLY_TARGETS', :NEW.target_id, l_old, l_new);
END;
/
