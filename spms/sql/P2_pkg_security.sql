--------------------------------------------------------------------------------
-- SPMS - Prompt P2/P4 - PKG_SECURITY
-- الأمن والصلاحيات (القسم 6): سياق المستخدم، RBAC، عزل الجهات (REQ-052)،
-- وتسجيل التدقيق (REQ-054).
--
-- ملاحظة تنفيذية: على apex.oracle.com لا تتوفر صلاحية CREATE CONTEXT أو VPD،
-- لذا يُنفَّذ العزل عبر دالة سياق داخل الحزمة (current_user_scope /
-- is_unit_in_scope) تُضاف كشرط في كل view/استعلام، كما نصّ القسم 6.2.
--
-- الاستخدام من APEX: في Initialization PL/SQL Code للتطبيق:
--     pkg_security.set_current_user(:APP_USER);
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE pkg_security AS

    -- ضبط سياق الجلسة من اسم المستخدم (يُستدعى مطلع كل جلسة/صفحة)
    PROCEDURE set_current_user (p_username IN users.username%TYPE);

    -- سياق المستخدم الحالي
    FUNCTION current_user_id    RETURN NUMBER;
    FUNCTION current_user_scope RETURN NUMBER;   -- جهة المستخدم الحالية (org_unit_id)

    -- RBAC
    FUNCTION has_role       (p_role_code       IN roles.role_code%TYPE)             RETURN NUMBER;
    FUNCTION has_permission (p_permission_code IN permissions.permission_code%TYPE) RETURN NUMBER;

    -- عزل الجهات (REQ-052): هل الجهة ضمن نطاق المستخدم الحالي (جهته وفروعها)؟
    -- تُستخدم كشرط في كل استعلام بيانات: WHERE pkg_security.is_unit_in_scope(t.org_unit_id) = 1
    FUNCTION is_unit_in_scope (p_org_unit_id IN org_units.org_unit_id%TYPE) RETURN NUMBER;

    -- سجل التدقيق (REQ-054) - إدراج مستقل عن معاملة الاستدعاء
    PROCEDURE log_action (
        p_action_type IN audit_log.action_type%TYPE,
        p_entity_name IN audit_log.entity_name%TYPE,
        p_entity_id   IN audit_log.entity_id%TYPE   DEFAULT NULL,
        p_old_value   IN CLOB                        DEFAULT NULL,
        p_new_value   IN CLOB                        DEFAULT NULL,
        p_ip_address  IN audit_log.ip_address%TYPE  DEFAULT NULL
    );

    -- إعادة تعيين السياق (نهاية الجلسة / الاختبارات)
    PROCEDURE clear_context;

END pkg_security;
/

CREATE OR REPLACE PACKAGE BODY pkg_security AS

    g_user_id     users.user_id%TYPE;
    g_org_unit_id users.org_unit_id%TYPE;
    g_is_admin    NUMBER(1) := 0;

    PROCEDURE set_current_user (p_username IN users.username%TYPE) IS
    BEGIN
        SELECT u.user_id, u.org_unit_id
          INTO g_user_id, g_org_unit_id
          FROM users u
         WHERE u.username  = p_username
           AND u.status    = 'ACTIVE'
           AND u.is_active = 1;

        SELECT COUNT(*)
          INTO g_is_admin
          FROM user_roles ur
          JOIN roles r ON r.role_id = ur.role_id
         WHERE ur.user_id = g_user_id
           AND r.role_code = 'SYS_ADMIN'
           AND r.is_active = 1;
        g_is_admin := LEAST(g_is_admin, 1);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            clear_context;
            RAISE_APPLICATION_ERROR(-20050,
                'SEC-001: المستخدم غير موجود أو غير نشط: ' || p_username);
    END set_current_user;

    FUNCTION current_user_id RETURN NUMBER IS
    BEGIN
        RETURN g_user_id;
    END current_user_id;

    FUNCTION current_user_scope RETURN NUMBER IS
    BEGIN
        RETURN g_org_unit_id;
    END current_user_scope;

    FUNCTION has_role (p_role_code IN roles.role_code%TYPE) RETURN NUMBER IS
        l_cnt NUMBER;
    BEGIN
        IF g_user_id IS NULL THEN RETURN 0; END IF;
        SELECT COUNT(*)
          INTO l_cnt
          FROM user_roles ur
          JOIN roles r ON r.role_id = ur.role_id
         WHERE ur.user_id = g_user_id
           AND r.role_code = p_role_code
           AND r.is_active = 1;
        RETURN LEAST(l_cnt, 1);
    END has_role;

    FUNCTION has_permission (p_permission_code IN permissions.permission_code%TYPE)
        RETURN NUMBER IS
        l_cnt NUMBER;
    BEGIN
        IF g_user_id IS NULL THEN RETURN 0; END IF;
        IF g_is_admin = 1 THEN RETURN 1; END IF;   -- مدير النظام يملك كل الصلاحيات
        SELECT COUNT(*)
          INTO l_cnt
          FROM user_roles ur
          JOIN role_permissions rp ON rp.role_id = ur.role_id
          JOIN permissions p       ON p.permission_id = rp.permission_id
         WHERE ur.user_id = g_user_id
           AND p.permission_code = p_permission_code
           AND p.is_active = 1;
        RETURN LEAST(l_cnt, 1);
    END has_permission;

    FUNCTION is_unit_in_scope (p_org_unit_id IN org_units.org_unit_id%TYPE)
        RETURN NUMBER IS
        l_cnt NUMBER;
    BEGIN
        IF p_org_unit_id IS NULL OR g_user_id IS NULL THEN RETURN 0; END IF;
        IF g_is_admin = 1 THEN RETURN 1; END IF;   -- نطاق مدير النظام: الكل
        -- الجهة ضمن النطاق إذا كانت جهة المستخدم نفسها أو أحد فروعها
        SELECT COUNT(*)
          INTO l_cnt
          FROM org_units o
         WHERE o.org_unit_id = p_org_unit_id
         START WITH o.org_unit_id = g_org_unit_id
         CONNECT BY PRIOR o.org_unit_id = o.parent_id;
        RETURN LEAST(l_cnt, 1);
    END is_unit_in_scope;

    PROCEDURE log_action (
        p_action_type IN audit_log.action_type%TYPE,
        p_entity_name IN audit_log.entity_name%TYPE,
        p_entity_id   IN audit_log.entity_id%TYPE   DEFAULT NULL,
        p_old_value   IN CLOB                        DEFAULT NULL,
        p_new_value   IN CLOB                        DEFAULT NULL,
        p_ip_address  IN audit_log.ip_address%TYPE  DEFAULT NULL
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;   -- يبقى السجل حتى لو تراجعت المعاملة الأم
    BEGIN
        INSERT INTO audit_log
            (user_id, org_unit_id, action_type, entity_name, entity_id,
             old_value, new_value, ip_address)
        VALUES
            (g_user_id, g_org_unit_id, p_action_type, p_entity_name, p_entity_id,
             p_old_value, p_new_value,
             NVL(p_ip_address, SYS_CONTEXT('USERENV', 'IP_ADDRESS')));
        COMMIT;
    END log_action;

    PROCEDURE clear_context IS
    BEGIN
        g_user_id     := NULL;
        g_org_unit_id := NULL;
        g_is_admin    := 0;
    END clear_context;

END pkg_security;
/
