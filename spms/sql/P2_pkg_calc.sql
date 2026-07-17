--------------------------------------------------------------------------------
-- SPMS - Prompt P3 - PKG_CALC
-- منطق الحسابات (القسم 5، REQ-041/042) - كل الحسابات هنا لا في الواجهة.
--
-- القواعد:
--  * نسبة إنجاز المؤشر: LEAST(100, actual / NULLIF(target,0) * 100)
--    (حماية القسمة على صفر إلزامية).
--  * متوسط البُعد مع fallback الأوزان (AD-02):
--      كل مؤشرات البُعد لها وزن صريح  => Σ(pct×w)/Σ(w)
--      وإلا                            => AVG(pct)  (توزيع متساوٍ ضمني)
--  * نسبة الجهة: متوسط أبعادها (بنفس قاعدة الوزن على مستوى الأبعاد).
--  * التجميع المؤسسي: متوسط الجهات على مستوى الجامعة.
--  * قواعد المقارنة (REQ-042): أفضل/أقل ربع، أفضل/أضعف جهة، اتجاه الأداء.
--
-- الفترات: Q1/Q2/Q3/Q4/SEMESTER/ANNUAL - عند طلب ANNUAL ولا يوجد سجل سنوي
-- مباشر، يُحتسب الإنجاز السنوي كمجموع الأرباع المدخلة (تراكمي).
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE pkg_calc AS

    -- نسبة إنجاز مؤشر من قيمتين (النواة الحسابية)
    FUNCTION kpi_achievement_pct (
        p_actual_value  IN NUMBER,
        p_yearly_target IN NUMBER
    ) RETURN NUMBER DETERMINISTIC;

    -- الإنجاز الفعلي لعنصر خطة عن فترة (ANNUAL يجمع الأرباع إن لم يوجد سجل سنوي)
    FUNCTION item_actual (
        p_item_id     IN op_plan_items.item_id%TYPE,
        p_period_type IN achievements.period_type%TYPE
    ) RETURN NUMBER;

    -- نسبة إنجاز عنصر خطة عن فترة
    FUNCTION item_achievement_pct (
        p_item_id     IN op_plan_items.item_id%TYPE,
        p_period_type IN achievements.period_type%TYPE
    ) RETURN NUMBER;

    -- متوسط إنجاز البُعد داخل خطة تشغيلية (AD-02: موزون أو متساوٍ)
    FUNCTION dim_achievement_pct (
        p_op_plan_id  IN operational_plans.op_plan_id%TYPE,
        p_dimension_id IN dimensions.dimension_id%TYPE,
        p_period_type IN achievements.period_type%TYPE
    ) RETURN NUMBER;

    -- نسبة إنجاز الجهة: متوسط أبعادها (موزون أو متساوٍ بنفس القاعدة)
    FUNCTION unit_achievement_pct (
        p_op_plan_id  IN operational_plans.op_plan_id%TYPE,
        p_period_type IN achievements.period_type%TYPE
    ) RETURN NUMBER;

    -- التجميع المؤسسي: متوسط الجهات على مستوى الجامعة لعام جامعي
    FUNCTION institutional_pct (
        p_strategic_plan_id IN strategic_plans.plan_id%TYPE,
        p_academic_year     IN operational_plans.academic_year%TYPE,
        p_period_type       IN achievements.period_type%TYPE
    ) RETURN NUMBER;

    ----------------------------------------------------------------------------
    -- قواعد المقارنة (REQ-042)
    ----------------------------------------------------------------------------

    -- أفضل/أقل ربع لخطة تشغيلية: يعيد 'Q1'..'Q4' أو NULL إن لا بيانات
    FUNCTION best_quarter  (p_op_plan_id IN operational_plans.op_plan_id%TYPE) RETURN VARCHAR2;
    FUNCTION worst_quarter (p_op_plan_id IN operational_plans.op_plan_id%TYPE) RETURN VARCHAR2;

    -- أفضل/أضعف جهة في عام جامعي (يعيد org_unit_id أو NULL)
    FUNCTION best_unit (
        p_strategic_plan_id IN strategic_plans.plan_id%TYPE,
        p_academic_year     IN operational_plans.academic_year%TYPE,
        p_period_type       IN achievements.period_type%TYPE
    ) RETURN NUMBER;
    FUNCTION worst_unit (
        p_strategic_plan_id IN strategic_plans.plan_id%TYPE,
        p_academic_year     IN operational_plans.academic_year%TYPE,
        p_period_type       IN achievements.period_type%TYPE
    ) RETURN NUMBER;

    -- اتجاه الأداء بمقارنة الربع بالسابق: 'UP' / 'DOWN' / 'STABLE' / NULL
    FUNCTION performance_trend (
        p_op_plan_id  IN operational_plans.op_plan_id%TYPE,
        p_period_type IN achievements.period_type%TYPE   -- Q2..Q4
    ) RETURN VARCHAR2;

END pkg_calc;
/

CREATE OR REPLACE PACKAGE BODY pkg_calc AS

    FUNCTION kpi_achievement_pct (
        p_actual_value  IN NUMBER,
        p_yearly_target IN NUMBER
    ) RETURN NUMBER DETERMINISTIC IS
    BEGIN
        -- الصيغة المعتمدة حرفياً (القسم 5) - NULLIF يحمي من القسمة على صفر
        RETURN LEAST(100, (p_actual_value / NULLIF(p_yearly_target, 0)) * 100);
    END kpi_achievement_pct;

    ----------------------------------------------------------------------------

    FUNCTION item_actual (
        p_item_id     IN op_plan_items.item_id%TYPE,
        p_period_type IN achievements.period_type%TYPE
    ) RETURN NUMBER IS
        l_actual NUMBER;
    BEGIN
        -- آخر سجل نشط للفترة المطلوبة نفسها
        BEGIN
            SELECT actual_value
              INTO l_actual
              FROM (SELECT a.actual_value
                      FROM achievements a
                     WHERE a.op_plan_item_id = p_item_id
                       AND a.period_type     = p_period_type
                       AND a.is_active       = 1
                     ORDER BY a.created_at DESC)
             WHERE ROWNUM = 1;
            RETURN l_actual;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            NULL;
        END;

        -- ANNUAL بلا سجل سنوي مباشر: مجموع الأرباع المدخلة (تراكمي)
        IF p_period_type = 'ANNUAL' THEN
            SELECT SUM(q.actual_value)
              INTO l_actual
              FROM (SELECT a.period_type, a.actual_value,
                           ROW_NUMBER() OVER (PARTITION BY a.period_type
                                              ORDER BY a.created_at DESC) rn
                      FROM achievements a
                     WHERE a.op_plan_item_id = p_item_id
                       AND a.period_type IN ('Q1', 'Q2', 'Q3', 'Q4')
                       AND a.is_active = 1) q
             WHERE q.rn = 1;
            RETURN l_actual;
        END IF;

        RETURN NULL;
    END item_actual;

    FUNCTION item_achievement_pct (
        p_item_id     IN op_plan_items.item_id%TYPE,
        p_period_type IN achievements.period_type%TYPE
    ) RETURN NUMBER IS
        l_target op_plan_items.yearly_target%TYPE;
    BEGIN
        SELECT yearly_target INTO l_target
          FROM op_plan_items
         WHERE item_id = p_item_id;
        RETURN kpi_achievement_pct(item_actual(p_item_id, p_period_type), l_target);
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END item_achievement_pct;

    ----------------------------------------------------------------------------

    FUNCTION dim_achievement_pct (
        p_op_plan_id  IN operational_plans.op_plan_id%TYPE,
        p_dimension_id IN dimensions.dimension_id%TYPE,
        p_period_type IN achievements.period_type%TYPE
    ) RETURN NUMBER IS
        l_sum_wpct     NUMBER := 0;   -- Σ(pct×w)
        l_sum_w        NUMBER := 0;   -- Σ(w)
        l_sum_pct      NUMBER := 0;
        l_cnt          NUMBER := 0;
        l_all_explicit NUMBER := 1;
        l_pct          NUMBER;
    BEGIN
        FOR r IN (
            SELECT i.item_id, k.weight_pct, k.is_weight_explicit
              FROM op_plan_items i
              JOIN kpis k                   ON k.kpi_id = i.source_kpi_id
              JOIN sub_objectives so        ON so.sub_objective_id = k.sub_objective_id
              JOIN strategic_objectives obj ON obj.strategic_objective_id = so.strategic_objective_id
             WHERE i.op_plan_id   = p_op_plan_id
               AND obj.dimension_id = p_dimension_id
               AND i.is_active = 1 AND k.is_active = 1
        ) LOOP
            l_pct := item_achievement_pct(r.item_id, p_period_type);
            IF l_pct IS NULL THEN
                CONTINUE;   -- عنصر بلا بيانات/مستهدف لا يدخل الحساب
            END IF;
            IF r.is_weight_explicit = 0 OR r.weight_pct IS NULL THEN
                l_all_explicit := 0;   -- وجود مؤشر واحد بلا وزن صريح => fallback
            END IF;
            l_sum_wpct := l_sum_wpct + l_pct * NVL(r.weight_pct, 0);
            l_sum_w    := l_sum_w    + NVL(r.weight_pct, 0);
            l_sum_pct  := l_sum_pct  + l_pct;
            l_cnt      := l_cnt + 1;
        END LOOP;

        IF l_cnt = 0 THEN
            RETURN NULL;
        END IF;

        -- AD-02: كل المؤشرات موزونة صراحةً => موزون، وإلا => متوسط متساوٍ ضمني
        IF l_all_explicit = 1 AND l_sum_w > 0 THEN
            RETURN ROUND(l_sum_wpct / l_sum_w, 2);
        ELSE
            RETURN ROUND(l_sum_pct / l_cnt, 2);
        END IF;
    END dim_achievement_pct;

    ----------------------------------------------------------------------------

    FUNCTION unit_achievement_pct (
        p_op_plan_id  IN operational_plans.op_plan_id%TYPE,
        p_period_type IN achievements.period_type%TYPE
    ) RETURN NUMBER IS
        l_sum_wpct     NUMBER := 0;
        l_sum_w        NUMBER := 0;
        l_sum_pct      NUMBER := 0;
        l_cnt          NUMBER := 0;
        l_all_explicit NUMBER := 1;
        l_pct          NUMBER;
    BEGIN
        -- أبعاد الخطة الاستراتيجية التي لهذه الخطة التشغيلية عناصر فيها
        FOR d IN (
            SELECT DISTINCT dm.dimension_id, dm.weight_pct, dm.is_weight_explicit
              FROM op_plan_items i
              JOIN kpis k                   ON k.kpi_id = i.source_kpi_id
              JOIN sub_objectives so        ON so.sub_objective_id = k.sub_objective_id
              JOIN strategic_objectives obj ON obj.strategic_objective_id = so.strategic_objective_id
              JOIN dimensions dm            ON dm.dimension_id = obj.dimension_id
             WHERE i.op_plan_id = p_op_plan_id
               AND i.is_active = 1 AND dm.is_active = 1
        ) LOOP
            l_pct := dim_achievement_pct(p_op_plan_id, d.dimension_id, p_period_type);
            IF l_pct IS NULL THEN
                CONTINUE;
            END IF;
            IF d.is_weight_explicit = 0 OR d.weight_pct IS NULL THEN
                l_all_explicit := 0;
            END IF;
            l_sum_wpct := l_sum_wpct + l_pct * NVL(d.weight_pct, 0);
            l_sum_w    := l_sum_w    + NVL(d.weight_pct, 0);
            l_sum_pct  := l_sum_pct  + l_pct;
            l_cnt      := l_cnt + 1;
        END LOOP;

        IF l_cnt = 0 THEN
            RETURN NULL;
        END IF;

        IF l_all_explicit = 1 AND l_sum_w > 0 THEN
            RETURN ROUND(l_sum_wpct / l_sum_w, 2);
        ELSE
            RETURN ROUND(l_sum_pct / l_cnt, 2);
        END IF;
    END unit_achievement_pct;

    ----------------------------------------------------------------------------

    FUNCTION institutional_pct (
        p_strategic_plan_id IN strategic_plans.plan_id%TYPE,
        p_academic_year     IN operational_plans.academic_year%TYPE,
        p_period_type       IN achievements.period_type%TYPE
    ) RETURN NUMBER IS
        l_sum NUMBER := 0;
        l_cnt NUMBER := 0;
        l_pct NUMBER;
    BEGIN
        FOR p IN (
            SELECT op_plan_id
              FROM operational_plans
             WHERE strategic_plan_id = p_strategic_plan_id
               AND academic_year     = p_academic_year
               AND is_active = 1
        ) LOOP
            l_pct := unit_achievement_pct(p.op_plan_id, p_period_type);
            IF l_pct IS NOT NULL THEN
                l_sum := l_sum + l_pct;
                l_cnt := l_cnt + 1;
            END IF;
        END LOOP;
        IF l_cnt = 0 THEN RETURN NULL; END IF;
        RETURN ROUND(l_sum / l_cnt, 2);
    END institutional_pct;

    ----------------------------------------------------------------------------
    -- المقارنات (REQ-042)
    ----------------------------------------------------------------------------

    FUNCTION quarter_rank (
        p_op_plan_id IN operational_plans.op_plan_id%TYPE,
        p_best       IN NUMBER   -- 1 = أفضل، 0 = أقل
    ) RETURN VARCHAR2 IS
        TYPE t_q IS TABLE OF VARCHAR2(2);
        l_quarters t_q := t_q('Q1', 'Q2', 'Q3', 'Q4');
        l_pct      NUMBER;
        l_sel_pct  NUMBER;
        l_sel_q    VARCHAR2(2);
    BEGIN
        FOR i IN 1 .. l_quarters.COUNT LOOP
            l_pct := unit_achievement_pct(p_op_plan_id, l_quarters(i));
            IF l_pct IS NULL THEN
                CONTINUE;
            END IF;
            IF l_sel_pct IS NULL
               OR (p_best = 1 AND l_pct > l_sel_pct)
               OR (p_best = 0 AND l_pct < l_sel_pct) THEN
                l_sel_pct := l_pct;
                l_sel_q   := l_quarters(i);
            END IF;
        END LOOP;
        RETURN l_sel_q;
    END quarter_rank;

    FUNCTION best_quarter (p_op_plan_id IN operational_plans.op_plan_id%TYPE)
        RETURN VARCHAR2 IS
    BEGIN
        RETURN quarter_rank(p_op_plan_id, 1);
    END best_quarter;

    FUNCTION worst_quarter (p_op_plan_id IN operational_plans.op_plan_id%TYPE)
        RETURN VARCHAR2 IS
    BEGIN
        RETURN quarter_rank(p_op_plan_id, 0);
    END worst_quarter;

    FUNCTION unit_rank (
        p_strategic_plan_id IN strategic_plans.plan_id%TYPE,
        p_academic_year     IN operational_plans.academic_year%TYPE,
        p_period_type       IN achievements.period_type%TYPE,
        p_best              IN NUMBER
    ) RETURN NUMBER IS
        l_pct      NUMBER;
        l_sel_pct  NUMBER;
        l_sel_unit NUMBER;
    BEGIN
        FOR p IN (
            SELECT op_plan_id, org_unit_id
              FROM operational_plans
             WHERE strategic_plan_id = p_strategic_plan_id
               AND academic_year     = p_academic_year
               AND is_active = 1
        ) LOOP
            l_pct := unit_achievement_pct(p.op_plan_id, p_period_type);
            IF l_pct IS NULL THEN
                CONTINUE;
            END IF;
            IF l_sel_pct IS NULL
               OR (p_best = 1 AND l_pct > l_sel_pct)
               OR (p_best = 0 AND l_pct < l_sel_pct) THEN
                l_sel_pct  := l_pct;
                l_sel_unit := p.org_unit_id;
            END IF;
        END LOOP;
        RETURN l_sel_unit;
    END unit_rank;

    FUNCTION best_unit (
        p_strategic_plan_id IN strategic_plans.plan_id%TYPE,
        p_academic_year     IN operational_plans.academic_year%TYPE,
        p_period_type       IN achievements.period_type%TYPE
    ) RETURN NUMBER IS
    BEGIN
        RETURN unit_rank(p_strategic_plan_id, p_academic_year, p_period_type, 1);
    END best_unit;

    FUNCTION worst_unit (
        p_strategic_plan_id IN strategic_plans.plan_id%TYPE,
        p_academic_year     IN operational_plans.academic_year%TYPE,
        p_period_type       IN achievements.period_type%TYPE
    ) RETURN NUMBER IS
    BEGIN
        RETURN unit_rank(p_strategic_plan_id, p_academic_year, p_period_type, 0);
    END worst_unit;

    FUNCTION performance_trend (
        p_op_plan_id  IN operational_plans.op_plan_id%TYPE,
        p_period_type IN achievements.period_type%TYPE
    ) RETURN VARCHAR2 IS
        l_prev_period VARCHAR2(2);
        l_cur         NUMBER;
        l_prev        NUMBER;
    BEGIN
        l_prev_period := CASE p_period_type
                             WHEN 'Q2' THEN 'Q1'
                             WHEN 'Q3' THEN 'Q2'
                             WHEN 'Q4' THEN 'Q3'
                         END;
        IF l_prev_period IS NULL THEN
            RETURN NULL;   -- لا ربع سابق للمقارنة (Q1 أو فترة غير ربعية)
        END IF;

        l_cur  := unit_achievement_pct(p_op_plan_id, p_period_type);
        l_prev := unit_achievement_pct(p_op_plan_id, l_prev_period);
        IF l_cur IS NULL OR l_prev IS NULL THEN
            RETURN NULL;
        END IF;

        RETURN CASE
                   WHEN l_cur > l_prev THEN 'UP'      -- تصاعدي
                   WHEN l_cur < l_prev THEN 'DOWN'    -- تنازلي
                   ELSE 'STABLE'
               END;
    END performance_trend;

END pkg_calc;
/
