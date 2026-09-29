-- =============================================================================
-- إنشاء Workspace وSchema وتطبيق APEX
-- يُشغَّل مرة واحدة بعد تشغيل Docker
-- تسجيل دخول كـ SYS AS SYSDBA
-- =============================================================================

-- 1. إنشاء المستخدم (Schema)
CREATE USER hi_app IDENTIFIED BY "Hi@App2026!"
    DEFAULT TABLESPACE users
    TEMPORARY TABLESPACE temp
    QUOTA UNLIMITED ON users;

GRANT CONNECT, RESOURCE, CREATE VIEW TO hi_app;
GRANT CREATE SEQUENCE, CREATE TRIGGER TO hi_app;
GRANT EXECUTE ON DBMS_CRYPTO TO hi_app;
GRANT EXECUTE ON APEX_UTIL TO hi_app;

-- 2. إنشاء Workspace في APEX
BEGIN
    APEX_INSTANCE_ADMIN.ADD_WORKSPACE(
        p_workspace_id   => 1000000,
        p_workspace      => 'INSURANCE',
        p_primary_schema => 'HI_APP'
    );
END;
/

-- 3. إنشاء مستخدم Admin في APEX
BEGIN
    APEX_UTIL.SET_WORKSPACE(p_workspace => 'INSURANCE');
    APEX_UTIL.CREATE_USER(
        p_user_name                => 'ADMIN',
        p_web_password             => 'Admin@2026!',
        p_developer_privs          => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
        p_email_address            => 'admin@insurance.local',
        p_change_password_on_first_use => 'N'
    );
END;
/

-- 4. تشغيل سكريبتات الـ Schema
@/opt/oracle/scripts/setup/01_schema.sql
@/opt/oracle/scripts/setup/02_packages.sql
@/opt/oracle/scripts/setup/03_views.sql
@/opt/oracle/scripts/setup/04_seed.sql

-- 5. استيراد تطبيق APEX
-- (يُنفَّذ من داخل APEX Application Builder > Import)
-- أو عبر: @/opt/oracle/scripts/apex/f100.sql

COMMIT;
PROMPT ✓ تم إعداد نظام التأمين الصحي بنجاح
PROMPT ✓ رابط APEX: http://localhost:8181/ords/apex
PROMPT ✓ Workspace: INSURANCE
PROMPT ✓ المستخدم: ADMIN | كلمة المرور: Admin@2026!
