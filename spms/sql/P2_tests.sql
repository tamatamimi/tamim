--------------------------------------------------------------------------------
-- SPMS - Prompt P3 (جزء الاختبار) - 3 وحدات اختبار PL/SQL
-- تتحقق من صحة الأرقام ببيانات معلومة قبل الاعتماد:
--   الاختبار 1: نسبة إنجاز المؤشر (حماية القسمة على صفر + سقف 100).
--   الاختبار 2: متوسط البُعد - موزون عند الأوزان الصريحة، متساوٍ عند غيابها (AD-02).
--   الاختبار 3: محرك الاشتقاق (تثبيت الإصدار، نسخ المرجعيات، رفض غير الابن المباشر)
--               + نسبة الجهة والتجميع المؤسسي.
--
-- يُشغَّل بعد P1 و P2. يزرع بيانات اختبار ثم يتراجع عنها (ROLLBACK) في النهاية -
-- لا يترك أثراً في الجداول (سجلات AUDIT_LOG المستقلة قد تبقى، وهذا مقصود).
-- شغّله في SQL Workshop مع تفعيل DBMS Output لرؤية النتائج.
--------------------------------------------------------------------------------

DECLARE
    l_failures  NUMBER := 0;
    l_tests     NUMBER := 0;

    -- بيانات الاختبار
    l_root_unit    NUMBER;
    l_college_unit NUMBER;
    l_dept_unit    NUMBER;
    l_user_id      NUMBER;
    l_plan_id      NUMBER;
    l_dim1         NUMBER;   -- أوزان صريحة
    l_dim2         NUMBER;   -- بلا أوزان (fallback)
    l_obj1         NUMBER; l_obj2 NUMBER;
    l_sub1         NUMBER; l_sub2 NUMBER;
    l_kpi1         NUMBER; l_kpi2 NUMBER; l_kpi3 NUMBER; l_kpi4 NUMBER;
    l_root_plan    NUMBER;
    l_college_plan NUMBER;
    l_num          NUMBER;
    l_str          VARCHAR2(100);

    PROCEDURE check_eq (p_name VARCHAR2, p_actual NUMBER, p_expected NUMBER) IS
    BEGIN
        l_tests := l_tests + 1;
        IF (p_actual IS NULL AND p_expected IS NULL)
           OR p_actual = p_expected THEN
            DBMS_OUTPUT.PUT_LINE('PASS: ' || p_name);
        ELSE
            l_failures := l_failures + 1;
            DBMS_OUTPUT.PUT_LINE('FAIL: ' || p_name
                || ' (المتوقع=' || NVL(TO_CHAR(p_expected), 'NULL')
                || ' الفعلي='   || NVL(TO_CHAR(p_actual),   'NULL') || ')');
        END IF;
    END;

    PROCEDURE check_eq_str (p_name VARCHAR2, p_actual VARCHAR2, p_expected VARCHAR2) IS
    BEGIN
        l_tests := l_tests + 1;
        IF (p_actual IS NULL AND p_expected IS NULL)
           OR p_actual = p_expected THEN
            DBMS_OUTPUT.PUT_LINE('PASS: ' || p_name);
        ELSE
            l_failures := l_failures + 1;
            DBMS_OUTPUT.PUT_LINE('FAIL: ' || p_name
                || ' (المتوقع=' || NVL(p_expected, 'NULL')
                || ' الفعلي='   || NVL(p_actual,   'NULL') || ')');
        END IF;
    END;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== SPMS P2 - اختبارات التحقق ===');
    pkg_security.clear_context;   -- سياق فارغ: بيانات الاختبار غير مثبَّتة بعد

    ----------------------------------------------------------------------------
    -- زرع بيانات معلومة
    ----------------------------------------------------------------------------
    INSERT INTO org_units (unit_type, name_ar, level_no)
    VALUES ('PRESIDENCY', 'اختبار - رئاسة الجامعة', 1)
    RETURNING org_unit_id INTO l_root_unit;

    INSERT INTO org_units (parent_id, unit_type, name_ar, level_no)
    VALUES (l_root_unit, 'COLLEGE', 'اختبار - كلية الهندسة', 2)
    RETURNING org_unit_id INTO l_college_unit;

    INSERT INTO org_units (parent_id, unit_type, name_ar, level_no)
    VALUES (l_college_unit, 'DEPARTMENT', 'اختبار - قسم الحاسوب', 3)
    RETURNING org_unit_id INTO l_dept_unit;

    INSERT INTO users (username, full_name, org_unit_id)
    VALUES ('TEST_SPMS_USER', 'مستخدم اختبار', l_root_unit)
    RETURNING user_id INTO l_user_id;

    INSERT INTO strategic_plans (title_ar, start_year, end_year, status, version_no, effective_from)
    VALUES ('اختبار - الخطة الاستراتيجية', 2026, 2030, 'APPROVED', 1, DATE '2026-01-01')
    RETURNING plan_id INTO l_plan_id;

    -- بُعد 1: مؤشران بوزنين صريحين 60/40
    INSERT INTO dimensions (plan_id, name_ar, weight_pct, is_weight_explicit, display_order)
    VALUES (l_plan_id, 'اختبار - التعلم والنمو', NULL, 0, 1)
    RETURNING dimension_id INTO l_dim1;
    INSERT INTO strategic_objectives (dimension_id, name_ar) VALUES (l_dim1, 'هدف 1')
    RETURNING strategic_objective_id INTO l_obj1;
    INSERT INTO sub_objectives (strategic_objective_id, name_ar) VALUES (l_obj1, 'فرعي 1')
    RETURNING sub_objective_id INTO l_sub1;
    INSERT INTO kpis (sub_objective_id, code, name_ar, target_cumulative, weight_pct, is_weight_explicit)
    VALUES (l_sub1, 'TST-0001', 'مؤشر 1', 500, 60, 1) RETURNING kpi_id INTO l_kpi1;
    INSERT INTO kpis (sub_objective_id, code, name_ar, target_cumulative, weight_pct, is_weight_explicit)
    VALUES (l_sub1, 'TST-0002', 'مؤشر 2', 500, 40, 1) RETURNING kpi_id INTO l_kpi2;

    -- بُعد 2: مؤشران بلا وزن صريح (fallback متساوٍ)
    INSERT INTO dimensions (plan_id, name_ar, weight_pct, is_weight_explicit, display_order)
    VALUES (l_plan_id, 'اختبار - العمليات الداخلية', NULL, 0, 2)
    RETURNING dimension_id INTO l_dim2;
    INSERT INTO strategic_objectives (dimension_id, name_ar) VALUES (l_dim2, 'هدف 2')
    RETURNING strategic_objective_id INTO l_obj2;
    INSERT INTO sub_objectives (strategic_objective_id, name_ar) VALUES (l_obj2, 'فرعي 2')
    RETURNING sub_objective_id INTO l_sub2;
    INSERT INTO kpis (sub_objective_id, code, name_ar, target_cumulative)
    VALUES (l_sub2, 'TST-0003', 'مؤشر 3', 500) RETURNING kpi_id INTO l_kpi3;
    INSERT INTO kpis (sub_objective_id, code, name_ar, target_cumulative)
    VALUES (l_sub2, 'TST-0004', 'مؤشر 4', 500) RETURNING kpi_id INTO l_kpi4;

    ----------------------------------------------------------------------------
    -- الاختبار 1: نسبة إنجاز المؤشر
    ----------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- الاختبار 1: kpi_achievement_pct ---');
    check_eq('50 من 100 = 50%',            pkg_calc.kpi_achievement_pct(50, 100),  50);
    check_eq('200 من 100 تُسقَّف عند 100%', pkg_calc.kpi_achievement_pct(200, 100), 100);
    check_eq('مستهدف صفر => NULL (حماية القسمة)', pkg_calc.kpi_achievement_pct(50, 0), NULL);
    check_eq('إنجاز NULL => NULL',          pkg_calc.kpi_achievement_pct(NULL, 100), NULL);

    ----------------------------------------------------------------------------
    -- تجهيز خطة الجذر وإنجازات الربع الأول بقيم معلومة
    ----------------------------------------------------------------------------
    pkg_inheritance.create_root_plan(l_plan_id, l_root_unit, '2026-2027', l_root_plan);

    -- المستهدفات السنوية: 100 لكل عنصر (تُدخل يدوياً - REQ-030)
    UPDATE op_plan_items SET yearly_target = 100
     WHERE op_plan_id = l_root_plan;

    -- إنجازات Q1: مؤشر1=50، مؤشر2=100، مؤشر3=20، مؤشر4=80
    FOR r IN (SELECT item_id, source_kpi_id FROM op_plan_items WHERE op_plan_id = l_root_plan) LOOP
        INSERT INTO achievements (op_plan_item_id, period_type, actual_value, reported_by, report_snapshot_version)
        VALUES (r.item_id, 'Q1',
                CASE r.source_kpi_id
                    WHEN l_kpi1 THEN 50 WHEN l_kpi2 THEN 100
                    WHEN l_kpi3 THEN 20 WHEN l_kpi4 THEN 80
                END,
                l_user_id, 1);
    END LOOP;

    ----------------------------------------------------------------------------
    -- الاختبار 2: متوسط البُعد (AD-02)
    ----------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- الاختبار 2: dim_achievement_pct (الأوزان) ---');
    -- بُعد 1 موزون: (50×60 + 100×40) / (60+40) = 70
    check_eq('بُعد بأوزان صريحة 60/40 => موزون = 70',
             pkg_calc.dim_achievement_pct(l_root_plan, l_dim1, 'Q1'), 70);
    -- بُعد 2 بلا أوزان: AVG(20, 80) = 50
    check_eq('بُعد بلا أوزان => متوسط متساوٍ = 50',
             pkg_calc.dim_achievement_pct(l_root_plan, l_dim2, 'Q1'), 50);

    ----------------------------------------------------------------------------
    -- الاختبار 3: الاشتقاق + نسبة الجهة والتجميع المؤسسي والمقارنات
    ----------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- الاختبار 3: الاشتقاق والتجميع ---');

    -- الاشتقاق يتطلب اعتماد خطة الأصل أولاً
    UPDATE operational_plans SET status = 'APPROVED' WHERE op_plan_id = l_root_plan;

    -- 3-أ: رفض الاشتقاق لغير الابن المباشر (القسم من الرئاسة مباشرة = خطأ INH-011)
    BEGIN
        pkg_inheritance.derive_plan(l_root_plan, l_dept_unit, '2026-2027', l_num);
        l_failures := l_failures + 1; l_tests := l_tests + 1;
        DBMS_OUTPUT.PUT_LINE('FAIL: كان يجب رفض اشتقاق القسم من الرئاسة مباشرة');
    EXCEPTION WHEN OTHERS THEN
        l_tests := l_tests + 1;
        IF SQLCODE = -20021 THEN
            DBMS_OUTPUT.PUT_LINE('PASS: رُفض الاشتقاق لغير الابن المباشر (INH-011)');
        ELSE
            l_failures := l_failures + 1;
            DBMS_OUTPUT.PUT_LINE('FAIL: خطأ غير متوقع: ' || SQLERRM);
        END IF;
    END;

    -- 3-ب: الاشتقاق الصحيح (الكلية ابن مباشر للرئاسة)
    pkg_inheritance.derive_plan(l_root_plan, l_college_unit, '2026-2027', l_college_plan);

    SELECT COUNT(*) INTO l_num FROM op_plan_items
     WHERE op_plan_id = l_college_plan AND yearly_target IS NULL AND is_locally_added = 0;
    check_eq('نُسخت 4 مرجعيات بمستهدف فارغ للجهة المشتقة', l_num, 4);

    SELECT strategic_plan_version INTO l_num
      FROM operational_plans WHERE op_plan_id = l_college_plan;
    check_eq('ثُبِّت إصدار الخطة الاستراتيجية الموروث (AD-01)', l_num, 1);

    SELECT parent_op_plan_id INTO l_num
      FROM operational_plans WHERE op_plan_id = l_college_plan;
    check_eq('ربط الخطة المشتقة بالأصل المباشر', l_num, l_root_plan);

    -- 3-ج: نسبة الجهة = متوسط البُعدين (بلا أوزان أبعاد صريحة): AVG(70, 50) = 60
    check_eq('نسبة إنجاز الجهة = 60', pkg_calc.unit_achievement_pct(l_root_plan, 'Q1'), 60);

    -- 3-د: التجميع المؤسسي: خطة الكلية بلا إنجازات => تُستبعد؛ يبقى 60
    check_eq('التجميع المؤسسي = 60 (تُستبعد الخطط بلا بيانات)',
             pkg_calc.institutional_pct(l_plan_id, '2026-2027', 'Q1'), 60);

    -- 3-هـ: المقارنات: Q2 أعلى من Q1 لعنصر واحد => أفضل ربع Q2 واتجاه صاعد
    INSERT INTO achievements (op_plan_item_id, period_type, actual_value, reported_by, report_snapshot_version)
    SELECT item_id, 'Q2', 100, l_user_id, 1
      FROM op_plan_items WHERE op_plan_id = l_root_plan;

    check_eq_str('أفضل ربع = Q2', pkg_calc.best_quarter(l_root_plan),  'Q2');
    check_eq_str('أقل ربع = Q1',  pkg_calc.worst_quarter(l_root_plan), 'Q1');
    check_eq_str('اتجاه الأداء في Q2 صاعد', pkg_calc.performance_trend(l_root_plan, 'Q2'), 'UP');
    check_eq('أفضل جهة = الرئاسة (الوحيدة ببيانات)',
             pkg_calc.best_unit(l_plan_id, '2026-2027', 'Q1'), l_root_unit);

    ----------------------------------------------------------------------------
    -- النتيجة والتنظيف
    ----------------------------------------------------------------------------
    ROLLBACK;   -- إزالة كل بيانات الاختبار

    DBMS_OUTPUT.PUT_LINE('=== النتيجة: ' || (l_tests - l_failures) || '/' || l_tests
        || ' نجح - ' || CASE WHEN l_failures = 0 THEN 'كل الاختبارات ناجحة'
                             ELSE l_failures || ' اختبار فشل' END || ' ===');
    IF l_failures > 0 THEN
        RAISE_APPLICATION_ERROR(-20099, 'فشل ' || l_failures || ' من الاختبارات');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
