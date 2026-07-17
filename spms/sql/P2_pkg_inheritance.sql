--------------------------------------------------------------------------------
-- SPMS - Prompt P2 - PKG_INHERITANCE
-- منطق الوراثة الهرمية (القسم 4، REQ-002/020..022) + إدارة التأريخ الفعّال (AD-01).
--
-- المبدأ: خطة كل مستوى تُشتق من المستوى الأعلى مباشرةً (لا من الجذر)،
-- وتُنسخ مرجعيات العناصر (source_kpi_id) لا البيانات نفسها؛ الجهة تملأ
-- المستهدف السنوي وتعدّل الجهة المسؤولة فقط (RULE - القسم 3.3).
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE pkg_inheritance AS

    -- دالة التحقق من علاقة الأبوة المباشرة في ORG_UNITS (يطلبها Prompt P2 نصاً)
    FUNCTION is_direct_child (
        p_parent_unit_id IN org_units.org_unit_id%TYPE,
        p_child_unit_id  IN org_units.org_unit_id%TYPE
    ) RETURN NUMBER;   -- 1 = ابن مباشر، 0 = غير ذلك

    -- إنشاء خطة الجذر (رئاسة الجامعة) من الخطة الاستراتيجية المعتمدة:
    -- تثبيت الإصدار الحالي ونسخ مرجعيات كل مؤشرات الخطة كعناصر.
    PROCEDURE create_root_plan (
        p_strategic_plan_id IN strategic_plans.plan_id%TYPE,
        p_org_unit_id       IN org_units.org_unit_id%TYPE,
        p_academic_year     IN operational_plans.academic_year%TYPE,
        o_op_plan_id        OUT operational_plans.op_plan_id%TYPE
    );

    -- الإجراء المحوري (القسم 4 بالضبط): اشتقاق خطة جهة من خطة الجهة الأعلى مباشرة
    PROCEDURE derive_plan (
        p_parent_op_plan_id IN operational_plans.op_plan_id%TYPE,
        p_target_org_unit_id IN org_units.org_unit_id%TYPE,
        p_academic_year     IN operational_plans.academic_year%TYPE,
        o_op_plan_id        OUT operational_plans.op_plan_id%TYPE
    );

    ----------------------------------------------------------------------------
    -- إدارة التأريخ الفعّال (AD-01): تعديل الخطة الاستراتيجية بعد الاعتماد
    -- يُنشئ إصداراً جديداً ولا يمسّ الإصدارات المثبّتة في الخطط التشغيلية.
    ----------------------------------------------------------------------------

    FUNCTION get_current_version (p_plan_id IN strategic_plans.plan_id%TYPE)
        RETURN NUMBER;

    -- بدء إصدار جديد للخطة (بعد اعتمادها): يرفع version_no ويضبط effective_from
    -- ويعيد الحالة إلى DRAFT حتى يُعتمد الإصدار الجديد. الخطط التشغيلية القائمة
    -- تبقى مرتبطة برقم الإصدار المثبّت لديها (strategic_plan_version) ولا تتأثر.
    PROCEDURE start_new_version (
        p_plan_id        IN strategic_plans.plan_id%TYPE,
        p_effective_from IN DATE DEFAULT TRUNC(SYSDATE)
    );

    -- اعتماد الإصدار الحالي للخطة الاستراتيجية
    PROCEDURE approve_version (p_plan_id IN strategic_plans.plan_id%TYPE);

END pkg_inheritance;
/

CREATE OR REPLACE PACKAGE BODY pkg_inheritance AS

    FUNCTION is_direct_child (
        p_parent_unit_id IN org_units.org_unit_id%TYPE,
        p_child_unit_id  IN org_units.org_unit_id%TYPE
    ) RETURN NUMBER IS
        l_cnt NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO l_cnt
          FROM org_units o
         WHERE o.org_unit_id = p_child_unit_id
           AND o.parent_id   = p_parent_unit_id
           AND o.is_active   = 1;
        RETURN LEAST(l_cnt, 1);
    END is_direct_child;

    ----------------------------------------------------------------------------

    PROCEDURE create_root_plan (
        p_strategic_plan_id IN strategic_plans.plan_id%TYPE,
        p_org_unit_id       IN org_units.org_unit_id%TYPE,
        p_academic_year     IN operational_plans.academic_year%TYPE,
        o_op_plan_id        OUT operational_plans.op_plan_id%TYPE
    ) IS
        l_plan strategic_plans%ROWTYPE;
    BEGIN
        BEGIN
            SELECT * INTO l_plan
              FROM strategic_plans
             WHERE plan_id = p_strategic_plan_id AND is_active = 1;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010,
                'INH-001: الخطة الاستراتيجية غير موجودة: ' || p_strategic_plan_id);
        END;

        -- قاعدة سلامة: لا اشتقاق إلا من خطة استراتيجية معتمدة
        IF l_plan.status <> 'APPROVED' THEN
            RAISE_APPLICATION_ERROR(-20011,
                'INH-002: لا يمكن إنشاء خطة تشغيلية من خطة استراتيجية غير معتمدة (الحالة: '
                || l_plan.status || ')');
        END IF;

        INSERT INTO operational_plans
            (strategic_plan_id, strategic_plan_version, org_unit_id,
             academic_year, parent_op_plan_id, status,
             created_by)
        VALUES
            (p_strategic_plan_id, l_plan.version_no, p_org_unit_id,   -- تثبيت الإصدار (AD-01)
             p_academic_year, NULL, 'DRAFT',
             pkg_security.current_user_id)
        RETURNING op_plan_id INTO o_op_plan_id;

        -- نسخ مرجعيات كل مؤشرات الخطة (لا بياناتها) - المستهدف يملؤه المستخدم
        INSERT INTO op_plan_items
            (op_plan_id, source_kpi_id, yearly_target, responsible_unit_id,
             is_locally_added, created_by)
        SELECT o_op_plan_id, k.kpi_id, NULL, p_org_unit_id, 0,
               pkg_security.current_user_id
          FROM kpis k
          JOIN sub_objectives so        ON so.sub_objective_id = k.sub_objective_id
          JOIN strategic_objectives obj ON obj.strategic_objective_id = so.strategic_objective_id
          JOIN dimensions d             ON d.dimension_id = obj.dimension_id
         WHERE d.plan_id = p_strategic_plan_id
           AND k.is_active = 1 AND so.is_active = 1
           AND obj.is_active = 1 AND d.is_active = 1;

        pkg_security.log_action('CREATE', 'OPERATIONAL_PLANS', o_op_plan_id,
            NULL,
            '{"action":"create_root_plan","strategic_plan_id":' || p_strategic_plan_id
            || ',"version":' || l_plan.version_no
            || ',"org_unit_id":' || p_org_unit_id
            || ',"academic_year":"' || p_academic_year || '"}');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20012,
                'INH-003: توجد خطة تشغيلية لهذه الجهة عن نفس العام الجامعي مسبقاً');
    END create_root_plan;

    ----------------------------------------------------------------------------
    -- derive_plan - منطق القسم 4 حرفياً:
    -- 1. تحقّق أن target_org_unit ابن مباشر لجهة parent_op_plan.
    -- 2. أنشئ OPERATIONAL_PLANS جديداً بـ parent_op_plan_id = المصدر
    --    و strategic_plan_version = نفس إصدار الأصل (تثبيت).
    -- 3. انسخ مرجعيات OP_PLAN_ITEMS من الأصل (source_kpi_id)
    --    مع yearly_target = NULL (الجهة تملؤه)، is_locally_added = 0.
    -- 4. سجّل العملية في AUDIT_LOG.
    ----------------------------------------------------------------------------
    PROCEDURE derive_plan (
        p_parent_op_plan_id IN operational_plans.op_plan_id%TYPE,
        p_target_org_unit_id IN org_units.org_unit_id%TYPE,
        p_academic_year     IN operational_plans.academic_year%TYPE,
        o_op_plan_id        OUT operational_plans.op_plan_id%TYPE
    ) IS
        l_parent operational_plans%ROWTYPE;
    BEGIN
        BEGIN
            SELECT * INTO l_parent
              FROM operational_plans
             WHERE op_plan_id = p_parent_op_plan_id AND is_active = 1;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20020,
                'INH-010: الخطة التشغيلية الأصل غير موجودة: ' || p_parent_op_plan_id);
        END;

        -- (1) علاقة الأبوة المباشرة في الهيكل التنظيمي
        IF is_direct_child(l_parent.org_unit_id, p_target_org_unit_id) = 0 THEN
            RAISE_APPLICATION_ERROR(-20021,
                'INH-011: الجهة المستهدفة (' || p_target_org_unit_id
                || ') ليست ابناً مباشراً لجهة الخطة الأصل ('
                || l_parent.org_unit_id || ') - الاشتقاق من المستوى الأعلى مباشرة فقط');
        END IF;

        -- قاعدة سلامة (REQ): لا يُشتق من خطة أصل غير معتمدة
        -- (مثال الوثيقة: لا يُسمح باشتقاق قسم علمي إلا بعد اعتماد خطة الكلية الأم)
        IF l_parent.status <> 'APPROVED' THEN
            RAISE_APPLICATION_ERROR(-20022,
                'INH-012: لا يمكن الاشتقاق قبل اعتماد خطة الجهة الأم (الحالة: '
                || l_parent.status || ')');
        END IF;

        -- (2) الخطة الجديدة - بتثبيت نفس إصدار الأصل (AD-01)
        INSERT INTO operational_plans
            (strategic_plan_id, strategic_plan_version, org_unit_id,
             academic_year, parent_op_plan_id, status, created_by)
        VALUES
            (l_parent.strategic_plan_id, l_parent.strategic_plan_version,
             p_target_org_unit_id, p_academic_year, p_parent_op_plan_id,
             'DRAFT', pkg_security.current_user_id)
        RETURNING op_plan_id INTO o_op_plan_id;

        -- (3) نسخ مرجعيات العناصر من الأصل - المستهدف فارغ تملؤه الجهة
        INSERT INTO op_plan_items
            (op_plan_id, source_kpi_id, yearly_target, responsible_unit_id,
             is_locally_added, created_by)
        SELECT o_op_plan_id, i.source_kpi_id, NULL, p_target_org_unit_id, 0,
               pkg_security.current_user_id
          FROM op_plan_items i
         WHERE i.op_plan_id = p_parent_op_plan_id
           AND i.is_active = 1;

        -- (4) التسجيل في سجل التدقيق
        pkg_security.log_action('CREATE', 'OPERATIONAL_PLANS', o_op_plan_id,
            NULL,
            '{"action":"derive_plan","parent_op_plan_id":' || p_parent_op_plan_id
            || ',"target_org_unit_id":' || p_target_org_unit_id
            || ',"pinned_version":' || l_parent.strategic_plan_version
            || ',"academic_year":"' || p_academic_year || '"}');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20023,
                'INH-013: توجد خطة تشغيلية لهذه الجهة عن نفس العام الجامعي مسبقاً');
    END derive_plan;

    ----------------------------------------------------------------------------
    -- التأريخ الفعّال (AD-01)
    ----------------------------------------------------------------------------

    FUNCTION get_current_version (p_plan_id IN strategic_plans.plan_id%TYPE)
        RETURN NUMBER IS
        l_ver NUMBER;
    BEGIN
        SELECT version_no INTO l_ver
          FROM strategic_plans
         WHERE plan_id = p_plan_id AND is_active = 1;
        RETURN l_ver;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END get_current_version;

    PROCEDURE start_new_version (
        p_plan_id        IN strategic_plans.plan_id%TYPE,
        p_effective_from IN DATE DEFAULT TRUNC(SYSDATE)
    ) IS
        l_plan strategic_plans%ROWTYPE;
    BEGIN
        BEGIN
            SELECT * INTO l_plan
              FROM strategic_plans
             WHERE plan_id = p_plan_id AND is_active = 1
               FOR UPDATE;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20030,
                'INH-020: الخطة الاستراتيجية غير موجودة: ' || p_plan_id);
        END;

        -- إصدار جديد لا يُفتح إلا فوق إصدار معتمد؛ المسودة تُعدَّل مباشرة بلا إصدار
        IF l_plan.status <> 'APPROVED' THEN
            RAISE_APPLICATION_ERROR(-20031,
                'INH-021: الإصدار الحالي غير معتمد (الحالة: ' || l_plan.status
                || ') - عدّل المسودة مباشرة دون فتح إصدار جديد');
        END IF;

        -- الخطط التشغيلية القائمة تحتفظ برقم الإصدار المثبّت لديها ولا تُمسّ (AD-01)
        UPDATE strategic_plans
           SET version_no     = version_no + 1,
               effective_from = p_effective_from,
               status         = 'DRAFT',          -- الإصدار الجديد يحتاج اعتماداً
               updated_by     = pkg_security.current_user_id,
               updated_at     = SYSTIMESTAMP
         WHERE plan_id = p_plan_id;

        pkg_security.log_action('UPDATE', 'STRATEGIC_PLANS', p_plan_id,
            '{"version_no":' || l_plan.version_no || ',"status":"APPROVED"}',
            '{"version_no":' || (l_plan.version_no + 1)
            || ',"status":"DRAFT","effective_from":"'
            || TO_CHAR(p_effective_from, 'YYYY-MM-DD') || '"}');
    END start_new_version;

    PROCEDURE approve_version (p_plan_id IN strategic_plans.plan_id%TYPE) IS
        l_old_status strategic_plans.status%TYPE;
        l_ver        strategic_plans.version_no%TYPE;
    BEGIN
        BEGIN
            SELECT status, version_no INTO l_old_status, l_ver
              FROM strategic_plans
             WHERE plan_id = p_plan_id AND is_active = 1
               FOR UPDATE;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20032,
                'INH-022: الخطة الاستراتيجية غير موجودة: ' || p_plan_id);
        END;

        IF l_old_status = 'APPROVED' THEN
            RAISE_APPLICATION_ERROR(-20033, 'INH-023: الإصدار الحالي معتمد مسبقاً');
        END IF;

        UPDATE strategic_plans
           SET status     = 'APPROVED',
               updated_by = pkg_security.current_user_id,
               updated_at = SYSTIMESTAMP
         WHERE plan_id = p_plan_id;

        pkg_security.log_action('APPROVE', 'STRATEGIC_PLANS', p_plan_id,
            '{"status":"' || l_old_status || '","version_no":' || l_ver || '}',
            '{"status":"APPROVED","version_no":' || l_ver || '}');
    END approve_version;

END pkg_inheritance;
/
