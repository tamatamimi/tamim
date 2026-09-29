-- =============================================================================
-- APEX 24.x  |  Application 100 — نظام التأمين الصحي للموظفين
-- استيراد كامل — يُشغَّل عبر: sqlplus > @f100.sql
-- أو يُرفع من: App Builder > Import > Application Export
-- =============================================================================
prompt --application/set_environment
set define off verify off feedback off timing off

begin
  wwv_flow_imp.import_begin(
    p_version_yyyy_mm_dd => '2024.05.31',
    p_release            => '24.1.0',
    p_default_workspace_id => 1000000,
    p_default_application_id => 100,
    p_default_owner      => 'HI_APP'
  );
end;
/

-- =============================================================================
-- Application Header
-- =============================================================================
prompt APPLICATION 100

begin
  wwv_flow_imp.create_flow(
    p_id                         => 100,
    p_owner                      => 'HI_APP',
    p_name                       => 'نظام التأمين الصحي للموظفين',
    p_alias                      => 'HEALTH-INSURANCE',
    p_application_group          => null,
    p_status                     => 'AVAILABLE',
    p_direction_right_to_left    => 'Y',
    p_flow_language              => 'ar',
    p_date_format                => 'YYYY/MM/DD',
    p_date_time_format           => 'YYYY/MM/DD HH24:MI',
    p_timestamp_format           => 'YYYY/MM/DD HH24:MI:SS',
    p_version_str                => '1.0.0',
    p_ui_type_name               => 'DESKTOP',
    p_theme_id                   => 42,  -- Universal Theme
    p_page_view_logging          => 'YES',
    p_error_handling_function    => null,
    p_file_prefix                => '#APP_FILES#',
    p_print_server_type          => 'NATIVE',
    p_flow_image_prefix          => '#APP_IMAGES#'
  );
end;
/


-- =============================================================================
-- Authentication Scheme — APEX Accounts
-- =============================================================================
begin
  wwv_flow_imp_shared.create_authentication(
    p_id                         => 1000,
    p_name                       => 'APEX Authentication',
    p_scheme_type                => 'NATIVE_APEX_ACCOUNTS',
    p_invalid_session_type       => 'LOGIN',
    p_use_secure_cookie_yn       => 'N',
    p_ras_mode                   => 0
  );
end;
/


-- =============================================================================
-- Authorization Schemes
-- =============================================================================
begin
  wwv_flow_imp_shared.create_authorization_scheme(
    p_id               => 100,
    p_name             => 'Must Be Admin',
    p_scheme_type      => 'NATIVE_IS_IN_GROUP',
    p_attribute_01     => 'Administrators',
    p_error_message    => 'غير مصرح لك بالوصول إلى هذه الصفحة'
  );
end;
/


-- =============================================================================
-- LOV مشتركة (Shared Lists of Values)
-- =============================================================================

-- أنواع المطالبات
begin
  wwv_flow_imp_shared.create_list_of_values(
    p_id            => 200,
    p_lov_name      => 'LOV_CLAIM_TYPE',
    p_lov_disp_seq  => 1,
    p_lov_type      => 'STATIC'
  );
  wwv_flow_imp_shared.create_static_lov_data(p_lov_id => 200, p_lov_disp_sequence => 1, p_lov_disp_value => 'مريض داخلي (رقود) 90%',  p_lov_return_value => 'INPATIENT');
  wwv_flow_imp_shared.create_static_lov_data(p_lov_id => 200, p_lov_disp_sequence => 2, p_lov_disp_value => 'عيادات خارجية 70%',      p_lov_return_value => 'OUTPATIENT');
  wwv_flow_imp_shared.create_static_lov_data(p_lov_id => 200, p_lov_disp_sequence => 3, p_lov_disp_value => 'طوارئ 70%',              p_lov_return_value => 'EMERGENCY');
end;
/

-- حالات المطالبة
begin
  wwv_flow_imp_shared.create_list_of_values(
    p_id           => 201,
    p_lov_name     => 'LOV_CLAIM_STATUS',
    p_lov_type     => 'STATIC'
  );
  wwv_flow_imp_shared.create_static_lov_data(p_lov_id => 201, p_lov_disp_sequence => 1, p_lov_disp_value => 'قيد المراجعة', p_lov_return_value => 'PENDING');
  wwv_flow_imp_shared.create_static_lov_data(p_lov_id => 201, p_lov_disp_sequence => 2, p_lov_disp_value => 'مقبولة',       p_lov_return_value => 'APPROVED');
  wwv_flow_imp_shared.create_static_lov_data(p_lov_id => 201, p_lov_disp_sequence => 3, p_lov_disp_value => 'جزئية',        p_lov_return_value => 'PARTIAL');
  wwv_flow_imp_shared.create_static_lov_data(p_lov_id => 201, p_lov_disp_sequence => 4, p_lov_disp_value => 'مرفوضة',       p_lov_return_value => 'REJECTED');
  wwv_flow_imp_shared.create_static_lov_data(p_lov_id => 201, p_lov_disp_sequence => 5, p_lov_disp_value => 'مدفوعة',       p_lov_return_value => 'PAID');
end;
/

-- صلة القرابة
begin
  wwv_flow_imp_shared.create_list_of_values(
    p_id           => 202,
    p_lov_name     => 'LOV_RELATION',
    p_lov_type     => 'STATIC'
  );
  wwv_flow_imp_shared.create_static_lov_data(p_lov_id => 202, p_lov_disp_sequence => 1, p_lov_disp_value => 'زوج/زوجة', p_lov_return_value => 'SPOUSE');
  wwv_flow_imp_shared.create_static_lov_data(p_lov_id => 202, p_lov_disp_sequence => 2, p_lov_disp_value => 'ابن',       p_lov_return_value => 'SON');
  wwv_flow_imp_shared.create_static_lov_data(p_lov_id => 202, p_lov_disp_sequence => 3, p_lov_disp_value => 'ابنة',      p_lov_return_value => 'DAUGHTER');
  wwv_flow_imp_shared.create_static_lov_data(p_lov_id => 202, p_lov_disp_sequence => 4, p_lov_disp_value => 'والد',      p_lov_return_value => 'FATHER');
  wwv_flow_imp_shared.create_static_lov_data(p_lov_id => 202, p_lov_disp_sequence => 5, p_lov_disp_value => 'والدة',     p_lov_return_value => 'MOTHER');
  wwv_flow_imp_shared.create_static_lov_data(p_lov_id => 202, p_lov_disp_sequence => 6, p_lov_disp_value => 'أخرى',      p_lov_return_value => 'OTHER');
end;
/

-- الموظفون (ديناميكي)
begin
  wwv_flow_imp_shared.create_list_of_values(
    p_id           => 210,
    p_lov_name     => 'LOV_EMPLOYEES',
    p_lov_type     => 'SQL_QUERY',
    p_lov_query    => 'SELECT full_name || '' ('' || emp_number || '')'' d, employee_id r FROM hi_employees WHERE is_active=1 ORDER BY full_name'
  );
end;
/


-- =============================================================================
-- Page 0 — Global Page
-- =============================================================================
begin
  wwv_flow_imp.create_page(
    p_id   => 0,
    p_name => 'Global Page'
  );
end;
/


-- =============================================================================
-- Page 1 — لوحة التحكم (Dashboard)
-- =============================================================================
prompt --application/pages/page_00001
begin
  wwv_flow_imp.create_page(
    p_id                   => 1,
    p_name                 => 'لوحة التحكم',
    p_alias                => 'DASHBOARD',
    p_step_title           => 'لوحة التحكم - التأمين الصحي',
    p_reload_on_submit     => 'A',
    p_warn_on_unsaved_changes => 'N',
    p_autocomplete_on_off  => 'OFF'
  );
end;
/

-- بطاقة: إجمالي الموظفين
begin
  wwv_flow_imp.create_report_region(
    p_id                       => 1001,
    p_flow_id                  => 100,
    p_page_id                  => 1,
    p_name                     => 'إحصائيات العام الحالي',
    p_template                 => 'Cards',
    p_display_sequence         => 10,
    p_include_in_reg_disp_sel  => 'Y',
    p_region_template_options  => '#DEFAULT#:t-Cards--3cols:t-Cards--featured:t-Cards--animColorFill',
    p_query_type               => 'SQL',
    p_query                    => q'[
SELECT
  'الموظفون النشطون'   AS card_title,
  total_employees      AS card_text,
  'icon-people'        AS card_icon,
  'u-color-7'          AS card_color,
  null                 AS card_link
FROM v_dashboard
UNION ALL
SELECT
  'إجمالي المطالبات',
  TO_CHAR(total_claims),
  'icon-document',
  'u-color-16',
  'f?p=&APP_ID.:3:&SESSION.::NO::'
FROM v_dashboard
UNION ALL
SELECT
  'قيد المراجعة',
  TO_CHAR(pending_claims),
  'icon-clock',
  'u-color-21',
  'f?p=&APP_ID.:3:&SESSION.::NO:RP,P3_STATUS:PENDING'
FROM v_dashboard
UNION ALL
SELECT
  'إجمالي التأمين المصروف',
  TO_CHAR(total_insurance, 'FM999,999,990.00') || ' ريال',
  'icon-currency',
  'u-color-20',
  null
FROM v_dashboard]',
    p_prn_output               => 'N'
  );
  -- Columns mapping for Cards region
  wwv_flow_imp.create_report_columns(
    p_id => 10010, p_region_id => 1001, p_flow_id => 100,
    p_query_column_id => 1, p_column_alias => 'CARD_TITLE',
    p_column_display_sequence => 1, p_column_heading => 'العنوان',
    p_use_as_row_header => 'Y'
  );
  wwv_flow_imp.create_report_columns(
    p_id => 10011, p_region_id => 1001, p_flow_id => 100,
    p_query_column_id => 2, p_column_alias => 'CARD_TEXT',
    p_column_display_sequence => 2, p_column_heading => 'القيمة'
  );
  wwv_flow_imp.create_report_columns(
    p_id => 10012, p_region_id => 1001, p_flow_id => 100,
    p_query_column_id => 3, p_column_alias => 'CARD_ICON',
    p_column_display_sequence => 3, p_column_heading => 'أيقونة',
    p_hidden_column => 'Y'
  );
  wwv_flow_imp.create_report_columns(
    p_id => 10013, p_region_id => 1001, p_flow_id => 100,
    p_query_column_id => 4, p_column_alias => 'CARD_COLOR',
    p_column_display_sequence => 4, p_column_heading => 'لون',
    p_hidden_column => 'Y'
  );
  wwv_flow_imp.create_report_columns(
    p_id => 10014, p_region_id => 1001, p_flow_id => 100,
    p_query_column_id => 5, p_column_alias => 'CARD_LINK',
    p_column_display_sequence => 5, p_column_heading => 'رابط',
    p_hidden_column => 'Y'
  );
end;
/

-- مخطط: التأمين المصروف شهرياً
begin
  wwv_flow_imp.create_region(
    p_id                     => 1002,
    p_flow_id                => 100,
    p_page_id                => 1,
    p_name                   => 'الاستخدام الشهري للتأمين',
    p_template               => 'Standard',
    p_display_sequence       => 20,
    p_region_template_options => '#DEFAULT#:t-Region--noPadding',
    p_component_template_options => '#DEFAULT#'
  );
  wwv_flow_imp.create_jet_chart(
    p_id                       => 10020,
    p_region_id                => 1002,
    p_chart_type               => 'bar',
    p_orientation              => 'vertical',
    p_chart_title              => null,
    p_height                   => '320'
  );
  wwv_flow_imp.create_jet_chart_series(
    p_id                       => 10021,
    p_chart_id                 => 10020,
    p_data_query               => q'[
SELECT month_label AS label,
       total_insurance AS value,
       total_invoice   AS value2
FROM v_monthly_chart
WHERE chart_year = EXTRACT(YEAR FROM SYSDATE)
ORDER BY chart_month]',
    p_series_name              => 'التأمين المصروف',
    p_items_value_column_name  => 'VALUE',
    p_items_label_column_name  => 'LABEL',
    p_color                    => '#3b82f6',
    p_line_type                => 'auto',
    p_marker_rendered          => 'auto',
    p_assigned_to_y2           => 'off'
  );
  wwv_flow_imp.create_jet_chart_series(
    p_id                       => 10022,
    p_chart_id                 => 10020,
    p_data_query               => q'[
SELECT month_label AS label,
       total_invoice AS value
FROM v_monthly_chart
WHERE chart_year = EXTRACT(YEAR FROM SYSDATE)
ORDER BY chart_month]',
    p_series_name              => 'إجمالي الفواتير',
    p_items_value_column_name  => 'VALUE',
    p_items_label_column_name  => 'LABEL',
    p_color                    => '#94a3b8',
    p_assigned_to_y2           => 'off'
  );
end;
/


-- =============================================================================
-- Page 2 — الموظفون (Interactive Report)
-- =============================================================================
prompt --application/pages/page_00002
begin
  wwv_flow_imp.create_page(
    p_id               => 2,
    p_name             => 'الموظفون',
    p_alias            => 'EMPLOYEES',
    p_step_title       => 'قائمة الموظفين'
  );
end;
/

-- زر الإضافة
begin
  wwv_flow_imp.create_page_button(
    p_id                  => 2000,
    p_flow_id             => 100,
    p_flow_step_id        => 2,
    p_button_sequence     => 10,
    p_button_plug_id      => null,
    p_button_name         => 'CREATE',
    p_button_action       => 'REDIRECT_PAGE',
    p_button_template_options => '#DEFAULT#',
    p_button_image_alt    => 'إضافة موظف',
    p_button_position     => 'ABOVE_BOX',
    p_button_redirect_url => 'f?p=&APP_ID.:22:&SESSION.::NO:22:P22_EMPLOYEE_ID:',
    p_icon_css_classes    => 'fa-plus',
    p_button_css_classes  => 't-Button--hot'
  );
end;
/

-- Interactive Report
begin
  wwv_flow_imp.create_report_region(
    p_id                      => 2001,
    p_flow_id                 => 100,
    p_page_id                 => 2,
    p_name                    => 'قائمة الموظفين',
    p_template                => 'Interactive Report',
    p_display_sequence        => 10,
    p_include_in_reg_disp_sel => 'Y',
    p_query_type              => 'SQL',
    p_query                   => q'[
SELECT
    e.employee_id,
    e.emp_number,
    e.full_name,
    CASE e.gender WHEN 'M' THEN 'ذكر' ELSE 'أنثى' END AS gender_ar,
    e.department,
    e.job_title,
    e.phone,
    e.email,
    TO_CHAR(e.hire_date, 'YYYY/MM/DD') AS hire_date,
    s.annual_used,
    s.emp_annual_limit,
    s.annual_remaining,
    s.usage_pct || '%' AS usage_pct_display,
    s.claims_count,
    s.family_count,
    CASE e.is_active WHEN 1 THEN '<span class="u-success-text">نشط</span>'
                     ELSE '<span class="u-danger-text">غير نشط</span>'
    END AS status_html,
    '<a href="f?p=&APP_ID.:21:&SESSION.::NO:21:P21_EMPLOYEE_ID:' || e.employee_id ||
    '" class="t-Button t-Button--small t-Button--noUI">تفاصيل</a>' AS detail_link
FROM v_employee_stats s
JOIN hi_employees e ON e.employee_id = s.employee_id]',
    p_ajax_enabled            => 'Y',
    p_lazy_loading            => false,
    p_region_template_options => '#DEFAULT#:t-IRR-region--noBorderTop'
  );
end;
/


-- =============================================================================
-- Page 21 — تفاصيل الموظف
-- =============================================================================
prompt --application/pages/page_00021
begin
  wwv_flow_imp.create_page(
    p_id               => 21,
    p_name             => 'تفاصيل الموظف',
    p_alias            => 'EMPLOYEE-DETAIL',
    p_step_title       => 'تفاصيل الموظف'
  );
  wwv_flow_imp.create_page_item(
    p_id                       => 21000,
    p_flow_id                  => 100,
    p_flow_step_id             => 21,
    p_name                     => 'P21_EMPLOYEE_ID',
    p_item_sequence            => 10,
    p_item_plug_id             => null,
    p_display_as               => 'NATIVE_HIDDEN',
    p_attribute_01             => 'Y'
  );
end;
/

-- بطاقة بيانات الموظف
begin
  wwv_flow_imp.create_region(
    p_id                    => 21001,
    p_flow_id               => 100,
    p_page_id               => 21,
    p_name                  => 'بيانات الموظف',
    p_template              => 'Standard',
    p_display_sequence      => 10,
    p_region_template_options => '#DEFAULT#:t-Region--scrollBody',
    p_query_type            => 'SQL',
    p_region_source         => q'[
SELECT
    e.emp_number, e.full_name,
    CASE e.gender WHEN 'M' THEN 'ذكر' ELSE 'أنثى' END AS gender_ar,
    TO_CHAR(e.birth_date,'YYYY/MM/DD') AS birth_date,
    TO_CHAR(e.hire_date, 'YYYY/MM/DD') AS hire_date,
    e.department, e.job_title, e.phone, e.email,
    s.emp_annual_limit, s.annual_used, s.annual_remaining, s.usage_pct,
    s.inpatient_pct, s.outpatient_pct
FROM v_employee_stats s
JOIN hi_employees e ON e.employee_id = s.employee_id
WHERE e.employee_id = :P21_EMPLOYEE_ID]'
  );
end;
/

-- تقرير المطالبات للموظف
begin
  wwv_flow_imp.create_report_region(
    p_id                      => 21002,
    p_flow_id                 => 100,
    p_page_id                 => 21,
    p_name                    => 'مطالبات الموظف',
    p_template                => 'Interactive Report',
    p_display_sequence        => 20,
    p_query_type              => 'SQL',
    p_query                   => q'[
SELECT
    c.claim_number,
    c.beneficiary_name,
    c.claim_type_ar,
    c.claim_date,
    c.hospital_name,
    c.invoice_amount,
    c.coverage_pct || '%' AS coverage_pct,
    c.insurance_amount,
    c.employee_amount,
    c.status_ar,
    '<a href="f?p=&APP_ID.:32:&SESSION.::NO:32:P32_CLAIM_ID:' || c.claim_id ||
    '" class="t-Button t-Button--small">تفاصيل</a>' AS detail_link
FROM v_claims c
WHERE c.employee_id = :P21_EMPLOYEE_ID
ORDER BY c.claim_date DESC]'
  );
end;
/

-- تقرير أفراد العائلة
begin
  wwv_flow_imp.create_report_region(
    p_id                      => 21003,
    p_flow_id                 => 100,
    p_page_id                 => 21,
    p_name                    => 'أفراد العائلة',
    p_template                => 'Standard',
    p_display_sequence        => 30,
    p_query_type              => 'SQL',
    p_query                   => q'[
SELECT
    fs.member_name,
    fs.relation_ar,
    TO_CHAR(fs.birth_date,'YYYY/MM/DD') AS birth_date,
    fs.fam_annual_limit,
    fs.annual_used,
    fs.annual_remaining,
    fs.claims_count
FROM v_family_stats fs
WHERE fs.employee_id = :P21_EMPLOYEE_ID
  AND fs.is_active   = 1
ORDER BY fs.member_name]'
  );
end;
/


-- =============================================================================
-- Page 22 — نموذج الموظف (إضافة / تعديل)
-- =============================================================================
prompt --application/pages/page_00022
begin
  wwv_flow_imp.create_page(
    p_id               => 22,
    p_name             => 'نموذج الموظف',
    p_alias            => 'EMPLOYEE-FORM',
    p_step_title       => 'إضافة / تعديل موظف'
  );
end;
/

begin
  -- بيانات الموظف
  for rec in (
    select column_name, data_type from user_tab_columns
    where table_name = 'HI_EMPLOYEES'
      and column_name in ('EMPLOYEE_ID','EMP_NUMBER','FULL_NAME','NATIONAL_ID',
                          'GENDER','BIRTH_DATE','HIRE_DATE','DEPARTMENT',
                          'JOB_TITLE','PHONE','EMAIL','IS_ACTIVE','SETTINGS_ID')
    order by column_id
  ) loop
    null; -- Page items created via App Builder in practice
  end loop;

  -- Form Region
  wwv_flow_imp.create_region(
    p_id                    => 22001,
    p_flow_id               => 100,
    p_page_id               => 22,
    p_name                  => 'بيانات الموظف',
    p_template              => 'Standard',
    p_display_sequence      => 10,
    p_region_template_options => '#DEFAULT#'
  );

  -- Items
  wwv_flow_imp.create_page_item(
    p_id => 22010, p_flow_id => 100, p_flow_step_id => 22,
    p_name => 'P22_EMPLOYEE_ID', p_item_sequence => 5,
    p_item_plug_id => 22001, p_display_as => 'NATIVE_HIDDEN',
    p_attribute_01 => 'Y'
  );
  wwv_flow_imp.create_page_item(
    p_id => 22020, p_flow_id => 100, p_flow_step_id => 22,
    p_name => 'P22_EMP_NUMBER', p_item_sequence => 10,
    p_item_plug_id => 22001, p_prompt => 'رقم الموظف',
    p_display_as => 'NATIVE_TEXT_FIELD',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_attribute_01 => 'N', p_attribute_02 => 'N'
  );
  wwv_flow_imp.create_page_item(
    p_id => 22030, p_flow_id => 100, p_flow_step_id => 22,
    p_name => 'P22_FULL_NAME', p_item_sequence => 20,
    p_item_plug_id => 22001, p_prompt => 'الاسم الكامل',
    p_display_as => 'NATIVE_TEXT_FIELD',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_attribute_01 => 'N', p_attribute_02 => 'N'
  );
  wwv_flow_imp.create_page_item(
    p_id => 22040, p_flow_id => 100, p_flow_step_id => 22,
    p_name => 'P22_NATIONAL_ID', p_item_sequence => 30,
    p_item_plug_id => 22001, p_prompt => 'رقم الهوية',
    p_display_as => 'NATIVE_TEXT_FIELD',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_attribute_01 => 'N', p_attribute_02 => 'N'
  );
  wwv_flow_imp.create_page_item(
    p_id => 22050, p_flow_id => 100, p_flow_step_id => 22,
    p_name => 'P22_GENDER', p_item_sequence => 40,
    p_item_plug_id => 22001, p_prompt => 'الجنس',
    p_display_as => 'NATIVE_SELECT_LIST',
    p_lov => 'STATIC:ذكر;M,أنثى;F',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_attribute_01 => 'NONE', p_attribute_02 => 'N'
  );
  wwv_flow_imp.create_page_item(
    p_id => 22060, p_flow_id => 100, p_flow_step_id => 22,
    p_name => 'P22_BIRTH_DATE', p_item_sequence => 50,
    p_item_plug_id => 22001, p_prompt => 'تاريخ الميلاد',
    p_display_as => 'NATIVE_DATE_PICKER_APEX',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_attribute_04 => 'button', p_attribute_05 => 'N'
  );
  wwv_flow_imp.create_page_item(
    p_id => 22070, p_flow_id => 100, p_flow_step_id => 22,
    p_name => 'P22_HIRE_DATE', p_item_sequence => 60,
    p_item_plug_id => 22001, p_prompt => 'تاريخ التعيين',
    p_display_as => 'NATIVE_DATE_PICKER_APEX',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_attribute_04 => 'button', p_attribute_05 => 'N'
  );
  wwv_flow_imp.create_page_item(
    p_id => 22080, p_flow_id => 100, p_flow_step_id => 22,
    p_name => 'P22_DEPARTMENT', p_item_sequence => 70,
    p_item_plug_id => 22001, p_prompt => 'القسم',
    p_display_as => 'NATIVE_TEXT_FIELD',
    p_field_template => 'Optional - Floating',
    p_attribute_01 => 'N', p_attribute_02 => 'N'
  );
  wwv_flow_imp.create_page_item(
    p_id => 22090, p_flow_id => 100, p_flow_step_id => 22,
    p_name => 'P22_JOB_TITLE', p_item_sequence => 80,
    p_item_plug_id => 22001, p_prompt => 'المسمى الوظيفي',
    p_display_as => 'NATIVE_TEXT_FIELD',
    p_field_template => 'Optional - Floating',
    p_attribute_01 => 'N', p_attribute_02 => 'N'
  );
  wwv_flow_imp.create_page_item(
    p_id => 22100, p_flow_id => 100, p_flow_step_id => 22,
    p_name => 'P22_PHONE', p_item_sequence => 90,
    p_item_plug_id => 22001, p_prompt => 'الجوال',
    p_display_as => 'NATIVE_TEXT_FIELD',
    p_field_template => 'Optional - Floating',
    p_attribute_01 => 'N', p_attribute_02 => 'N'
  );
  wwv_flow_imp.create_page_item(
    p_id => 22110, p_flow_id => 100, p_flow_step_id => 22,
    p_name => 'P22_EMAIL', p_item_sequence => 100,
    p_item_plug_id => 22001, p_prompt => 'البريد الإلكتروني',
    p_display_as => 'NATIVE_TEXT_FIELD',
    p_field_template => 'Optional - Floating',
    p_attribute_01 => 'N', p_attribute_02 => 'N'
  );

  -- Button: Save
  wwv_flow_imp.create_page_button(
    p_id => 22200, p_flow_id => 100, p_flow_step_id => 22,
    p_button_sequence => 20, p_button_name => 'SAVE',
    p_button_action => 'SUBMIT',
    p_button_image_alt => 'حفظ',
    p_button_position => 'BELOW_BOX',
    p_button_css_classes => 't-Button--hot',
    p_icon_css_classes => 'fa-save'
  );
  wwv_flow_imp.create_page_button(
    p_id => 22201, p_flow_id => 100, p_flow_step_id => 22,
    p_button_sequence => 30, p_button_name => 'CANCEL',
    p_button_action => 'REDIRECT_PAGE',
    p_button_image_alt => 'إلغاء',
    p_button_position => 'BELOW_BOX',
    p_button_redirect_url => 'f?p=&APP_ID.:2:&SESSION.::NO::'
  );

  -- Process: DML
  wwv_flow_imp.create_page_process(
    p_id => 22300, p_flow_id => 100, p_flow_step_id => 22,
    p_process_sequence => 10, p_process_point => 'AFTER_SUBMIT',
    p_process_type => 'NATIVE_PLSQL',
    p_process_name => 'حفظ الموظف',
    p_process_sql_clob => q'[
DECLARE
    v_id NUMBER := :P22_EMPLOYEE_ID;
    v_settings NUMBER := (SELECT MIN(settings_id) FROM hi_settings WHERE is_active=1);
BEGIN
    IF v_id IS NULL THEN
        INSERT INTO hi_employees (
            emp_number, full_name, national_id, gender,
            birth_date, hire_date, department, job_title,
            phone, email, settings_id
        ) VALUES (
            :P22_EMP_NUMBER, :P22_FULL_NAME, :P22_NATIONAL_ID, :P22_GENDER,
            TO_DATE(:P22_BIRTH_DATE,'YYYY/MM/DD'), TO_DATE(:P22_HIRE_DATE,'YYYY/MM/DD'),
            :P22_DEPARTMENT, :P22_JOB_TITLE, :P22_PHONE, :P22_EMAIL, v_settings
        );
    ELSE
        UPDATE hi_employees SET
            emp_number  = :P22_EMP_NUMBER,
            full_name   = :P22_FULL_NAME,
            national_id = :P22_NATIONAL_ID,
            gender      = :P22_GENDER,
            birth_date  = TO_DATE(:P22_BIRTH_DATE,'YYYY/MM/DD'),
            hire_date   = TO_DATE(:P22_HIRE_DATE,'YYYY/MM/DD'),
            department  = :P22_DEPARTMENT,
            job_title   = :P22_JOB_TITLE,
            phone       = :P22_PHONE,
            email       = :P22_EMAIL
        WHERE employee_id = v_id;
    END IF;
    COMMIT;
END;]',
    p_error_display_location => 'INLINE_IN_NOTIFICATION',
    p_process_success_message => 'تم الحفظ بنجاح'
  );
  wwv_flow_imp.create_page_branch(
    p_id => 22400, p_flow_id => 100, p_flow_step_id => 22,
    p_branch_action => 'f?p=&APP_ID.:2:&SESSION.::NO::',
    p_branch_point => 'AFTER_PROCESSING',
    p_branch_sequence => 10
  );
end;
/


-- =============================================================================
-- Page 3 — المطالبات (Interactive Report مع Faceted Search)
-- =============================================================================
prompt --application/pages/page_00003
begin
  wwv_flow_imp.create_page(
    p_id               => 3,
    p_name             => 'المطالبات',
    p_alias            => 'CLAIMS',
    p_step_title       => 'قائمة المطالبات التأمينية'
  );
end;
/

begin
  -- Facet Search Region
  wwv_flow_imp.create_region(
    p_id                    => 3000,
    p_flow_id               => 100,
    p_page_id               => 3,
    p_name                  => 'بحث وتصفية',
    p_template              => 'Facets',
    p_display_sequence      => 5,
    p_region_template_options => '#DEFAULT#',
    p_source_type           => 'NATIVE_FACETED_SEARCH'
  );
  wwv_flow_imp.create_facet(
    p_id              => 3001, p_region_id => 3000,
    p_name            => 'FС_STATUS',
    p_label           => 'حالة المطالبة',
    p_facet_type      => 'CHECKBOX',
    p_query_column    => 'CLAIM_STATUS',
    p_display_sequence => 10
  );
  wwv_flow_imp.create_facet(
    p_id              => 3002, p_region_id => 3000,
    p_name            => 'FC_CLAIM_TYPE',
    p_label           => 'نوع المطالبة',
    p_facet_type      => 'CHECKBOX',
    p_query_column    => 'CLAIM_TYPE',
    p_display_sequence => 20
  );
  wwv_flow_imp.create_facet(
    p_id              => 3003, p_region_id => 3000,
    p_name            => 'FC_YEAR',
    p_label           => 'السنة',
    p_facet_type      => 'SELECT_LIST',
    p_query_column    => 'CLAIM_YEAR',
    p_display_sequence => 30
  );
  wwv_flow_imp.create_facet(
    p_id              => 3004, p_region_id => 3000,
    p_name            => 'FC_DEPT',
    p_label           => 'القسم',
    p_facet_type      => 'CHECKBOX',
    p_query_column    => 'DEPARTMENT',
    p_display_sequence => 40
  );

  -- Interactive Report
  wwv_flow_imp.create_report_region(
    p_id                      => 3010,
    p_flow_id                 => 100,
    p_page_id                 => 3,
    p_name                    => 'قائمة المطالبات',
    p_template                => 'Interactive Report',
    p_display_sequence        => 10,
    p_query_type              => 'SQL',
    p_query                   => q'[
SELECT
    c.claim_id,
    c.claim_number,
    c.employee_name,
    c.department,
    c.beneficiary_name,
    c.claim_type_ar,
    c.claim_type,
    TO_CHAR(c.claim_date, 'YYYY/MM/DD') AS claim_date,
    c.hospital_name,
    c.invoice_amount,
    c.coverage_pct || '%' AS coverage_pct,
    c.insurance_amount,
    c.employee_amount,
    c.status_ar,
    c.claim_status,
    c.claim_year,
    '<span class="t-Badge t-Badge--' ||
        CASE c.claim_status
            WHEN 'PENDING'  THEN 'warning'
            WHEN 'APPROVED' THEN 'success'
            WHEN 'PARTIAL'  THEN 'info'
            WHEN 'REJECTED' THEN 'danger'
            WHEN 'PAID'     THEN 'success'
        END || '">' || c.status_ar || '</span>' AS status_badge,
    '<a href="f?p=&APP_ID.:32:&SESSION.::NO:32:P32_CLAIM_ID:' || c.claim_id ||
    '" class="t-Button t-Button--small">تفاصيل</a>' AS detail_link
FROM v_claims c
ORDER BY c.claim_date DESC, c.claim_id DESC]',
    p_ajax_enabled            => 'Y',
    p_lazy_loading            => false,
    p_region_template_options => '#DEFAULT#:t-IRR-region--noBorderTop'
  );

  -- زر مطالبة جديدة
  wwv_flow_imp.create_page_button(
    p_id => 3100, p_flow_id => 100, p_flow_step_id => 3,
    p_button_sequence => 10, p_button_name => 'NEW_CLAIM',
    p_button_action => 'REDIRECT_PAGE',
    p_button_image_alt => 'مطالبة جديدة',
    p_button_position => 'ABOVE_BOX',
    p_button_redirect_url => 'f?p=&APP_ID.:31:&SESSION.::NO:31:',
    p_icon_css_classes => 'fa-plus',
    p_button_css_classes => 't-Button--hot'
  );
end;
/


-- =============================================================================
-- Page 31 — نموذج مطالبة جديدة  (مع حساب تلقائي عبر Dynamic Action)
-- =============================================================================
prompt --application/pages/page_00031
begin
  wwv_flow_imp.create_page(
    p_id               => 31,
    p_name             => 'مطالبة جديدة',
    p_alias            => 'NEW-CLAIM',
    p_step_title       => 'تقديم مطالبة تأمينية جديدة'
  );
end;
/

begin
  -- Form Region
  wwv_flow_imp.create_region(
    p_id => 31001, p_flow_id => 100, p_page_id => 31,
    p_name => 'بيانات المطالبة',
    p_template => 'Standard', p_display_sequence => 10,
    p_region_template_options => '#DEFAULT#'
  );

  -- Claim form items
  wwv_flow_imp.create_page_item(
    p_id => 31010, p_flow_id => 100, p_flow_step_id => 31,
    p_name => 'P31_EMPLOYEE_ID', p_item_sequence => 10, p_item_plug_id => 31001,
    p_prompt => 'الموظف', p_display_as => 'NATIVE_SELECT_LIST',
    p_lov => 'LOV_EMPLOYEES',
    p_lov_display_null => 'YES', p_lov_null_text => '-- اختر الموظف --',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_attribute_01 => 'NONE', p_attribute_02 => 'Y'
  );
  wwv_flow_imp.create_page_item(
    p_id => 31020, p_flow_id => 100, p_flow_step_id => 31,
    p_name => 'P31_BENEFICIARY_TYPE', p_item_sequence => 20, p_item_plug_id => 31001,
    p_prompt => 'المستفيد', p_display_as => 'NATIVE_RADIOGROUP',
    p_lov => 'STATIC:الموظف نفسه;EMPLOYEE,فرد من العائلة;FAMILY',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_item_default => 'EMPLOYEE',
    p_attribute_01 => '2', p_attribute_02 => 'NONE'
  );
  wwv_flow_imp.create_page_item(
    p_id => 31025, p_flow_id => 100, p_flow_step_id => 31,
    p_name => 'P31_MEMBER_ID', p_item_sequence => 25, p_item_plug_id => 31001,
    p_prompt => 'فرد العائلة', p_display_as => 'NATIVE_SELECT_LIST',
    p_lov => q'[SELECT full_name || ' (' ||
        CASE relation WHEN 'SPOUSE' THEN 'زوج/زوجة'
                      WHEN 'SON' THEN 'ابن' WHEN 'DAUGHTER' THEN 'ابنة'
                      ELSE relation END || ')' d, member_id r
    FROM hi_family_members WHERE employee_id = :P31_EMPLOYEE_ID AND is_active=1
    ORDER BY full_name]',
    p_lov_display_null => 'YES', p_lov_null_text => '-- اختر --',
    p_field_template => 'Optional - Floating',
    p_attribute_01 => 'NONE', p_attribute_02 => 'Y'
  );
  wwv_flow_imp.create_page_item(
    p_id => 31030, p_flow_id => 100, p_flow_step_id => 31,
    p_name => 'P31_CLAIM_TYPE', p_item_sequence => 30, p_item_plug_id => 31001,
    p_prompt => 'نوع المطالبة', p_display_as => 'NATIVE_SELECT_LIST',
    p_lov => 'LOV_CLAIM_TYPE',
    p_lov_display_null => 'YES', p_lov_null_text => '-- اختر النوع --',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_attribute_01 => 'NONE', p_attribute_02 => 'Y'
  );
  wwv_flow_imp.create_page_item(
    p_id => 31040, p_flow_id => 100, p_flow_step_id => 31,
    p_name => 'P31_CLAIM_DATE', p_item_sequence => 40, p_item_plug_id => 31001,
    p_prompt => 'تاريخ الخدمة', p_display_as => 'NATIVE_DATE_PICKER_APEX',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_item_default => 'TO_CHAR(SYSDATE,''YYYY/MM/DD'')',
    p_item_default_type => 'EXPRESSION',
    p_attribute_04 => 'button', p_attribute_05 => 'N'
  );
  wwv_flow_imp.create_page_item(
    p_id => 31050, p_flow_id => 100, p_flow_step_id => 31,
    p_name => 'P31_HOSPITAL_NAME', p_item_sequence => 50, p_item_plug_id => 31001,
    p_prompt => 'اسم المستشفى / العيادة', p_display_as => 'NATIVE_TEXT_FIELD',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_attribute_01 => 'N', p_attribute_02 => 'N'
  );
  wwv_flow_imp.create_page_item(
    p_id => 31060, p_flow_id => 100, p_flow_step_id => 31,
    p_name => 'P31_DIAGNOSIS', p_item_sequence => 60, p_item_plug_id => 31001,
    p_prompt => 'التشخيص / السبب الطبي', p_display_as => 'NATIVE_TEXTAREA',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_attribute_01 => 'Y', p_attribute_02 => 'N', p_attribute_03 => '4'
  );
  wwv_flow_imp.create_page_item(
    p_id => 31070, p_flow_id => 100, p_flow_step_id => 31,
    p_name => 'P31_INVOICE_AMOUNT', p_item_sequence => 70, p_item_plug_id => 31001,
    p_prompt => 'قيمة الفاتورة (ريال)', p_display_as => 'NATIVE_NUMBER_FIELD',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_attribute_03 => 'right', p_attribute_04 => 'text'
  );
  wwv_flow_imp.create_page_item(
    p_id => 31075, p_flow_id => 100, p_flow_step_id => 31,
    p_name => 'P31_NOTES', p_item_sequence => 75, p_item_plug_id => 31001,
    p_prompt => 'ملاحظات', p_display_as => 'NATIVE_TEXTAREA',
    p_field_template => 'Optional - Floating',
    p_attribute_01 => 'Y', p_attribute_02 => 'N', p_attribute_03 => '3'
  );

  -- معاينة التغطية (قراءة فقط)
  wwv_flow_imp.create_page_item(
    p_id => 31080, p_flow_id => 100, p_flow_step_id => 31,
    p_name => 'P31_PREVIEW_PCT', p_item_sequence => 80, p_item_plug_id => 31001,
    p_prompt => 'نسبة التغطية', p_display_as => 'NATIVE_DISPLAY_ONLY',
    p_field_template => 'Optional - Floating'
  );
  wwv_flow_imp.create_page_item(
    p_id => 31090, p_flow_id => 100, p_flow_step_id => 31,
    p_name => 'P31_PREVIEW_INS', p_item_sequence => 90, p_item_plug_id => 31001,
    p_prompt => 'مبلغ التأمين (ريال)', p_display_as => 'NATIVE_DISPLAY_ONLY',
    p_field_template => 'Optional - Floating'
  );
  wwv_flow_imp.create_page_item(
    p_id => 31095, p_flow_id => 100, p_flow_step_id => 31,
    p_name => 'P31_PREVIEW_EMP', p_item_sequence => 95, p_item_plug_id => 31001,
    p_prompt => 'تحمّل الموظف (ريال)', p_display_as => 'NATIVE_DISPLAY_ONLY',
    p_field_template => 'Optional - Floating'
  );

  -- Dynamic Action: حساب التغطية عند تغيير المبلغ أو النوع
  wwv_flow_imp.create_page_da_event(
    p_id => 31200, p_flow_id => 100, p_flow_step_id => 31,
    p_name => 'حساب التغطية تلقائياً',
    p_event_sequence => 10,
    p_triggering_element_type => 'ITEM',
    p_triggering_element => 'P31_INVOICE_AMOUNT,P31_CLAIM_TYPE,P31_EMPLOYEE_ID',
    p_bind_type => 'bind',
    p_bind_event_type => 'change'
  );
  wwv_flow_imp.create_page_da_action(
    p_id => 31201, p_flow_id => 100, p_flow_step_id => 31,
    p_event_id => 31200,
    p_action_sequence => 10,
    p_execute_on_page_init => 'N',
    p_action => 'NATIVE_EXECUTE_PLSQL_CODE',
    p_attribute_01 => q'[
DECLARE
    v_res pkg_insurance.t_coverage_result;
BEGIN
    IF :P31_INVOICE_AMOUNT IS NOT NULL AND :P31_CLAIM_TYPE IS NOT NULL AND :P31_EMPLOYEE_ID IS NOT NULL THEN
        v_res := pkg_insurance.calculate_coverage(
            :P31_INVOICE_AMOUNT, :P31_CLAIM_TYPE, :P31_EMPLOYEE_ID,
            NVL(TO_DATE(:P31_CLAIM_DATE,'YYYY/MM/DD'), SYSDATE)
        );
        :P31_PREVIEW_PCT := TO_CHAR(v_res.coverage_pct) || '%';
        :P31_PREVIEW_INS := TO_CHAR(v_res.insurance_amount,'FM999,999,990.00');
        :P31_PREVIEW_EMP := TO_CHAR(v_res.employee_amount,'FM999,999,990.00');
    END IF;
END;]',
    p_attribute_02 => 'P31_INVOICE_AMOUNT,P31_CLAIM_TYPE,P31_EMPLOYEE_ID,P31_CLAIM_DATE',
    p_attribute_03 => 'P31_PREVIEW_PCT,P31_PREVIEW_INS,P31_PREVIEW_EMP',
    p_wait_for_result => 'Y'
  );

  -- Buttons
  wwv_flow_imp.create_page_button(
    p_id => 31300, p_flow_id => 100, p_flow_step_id => 31,
    p_button_sequence => 10, p_button_name => 'SUBMIT_CLAIM',
    p_button_action => 'SUBMIT',
    p_button_image_alt => 'تقديم المطالبة',
    p_button_position => 'BELOW_BOX',
    p_button_css_classes => 't-Button--hot',
    p_icon_css_classes => 'fa-check'
  );
  wwv_flow_imp.create_page_button(
    p_id => 31301, p_flow_id => 100, p_flow_step_id => 31,
    p_button_sequence => 20, p_button_name => 'CANCEL',
    p_button_action => 'REDIRECT_PAGE',
    p_button_image_alt => 'إلغاء',
    p_button_position => 'BELOW_BOX',
    p_button_redirect_url => 'f?p=&APP_ID.:3:&SESSION.::NO::'
  );

  -- Process: تقديم المطالبة
  wwv_flow_imp.create_page_process(
    p_id => 31400, p_flow_id => 100, p_flow_step_id => 31,
    p_process_sequence => 10, p_process_point => 'AFTER_SUBMIT',
    p_process_type => 'NATIVE_PLSQL',
    p_process_name => 'تقديم المطالبة',
    p_process_sql_clob => q'[
DECLARE
    v_id  NUMBER;
    v_num VARCHAR2(25);
BEGIN
    pkg_insurance.submit_claim(
        p_employee_id      => :P31_EMPLOYEE_ID,
        p_member_id        => :P31_MEMBER_ID,
        p_beneficiary_type => :P31_BENEFICIARY_TYPE,
        p_claim_type       => :P31_CLAIM_TYPE,
        p_claim_date       => TO_DATE(:P31_CLAIM_DATE, 'YYYY/MM/DD'),
        p_hospital_name    => :P31_HOSPITAL_NAME,
        p_diagnosis        => :P31_DIAGNOSIS,
        p_invoice_amount   => :P31_INVOICE_AMOUNT,
        p_notes            => :P31_NOTES,
        p_claim_id         => v_id,
        p_claim_number     => v_num
    );
    apex_util.set_session_state('P32_CLAIM_ID', v_id);
END;]',
    p_error_display_location => 'INLINE_IN_NOTIFICATION',
    p_process_success_message => 'تم تقديم المطالبة بنجاح'
  );
  wwv_flow_imp.create_page_branch(
    p_id => 31500, p_flow_id => 100, p_flow_step_id => 31,
    p_branch_action => 'f?p=&APP_ID.:32:&SESSION.::NO:32:P32_CLAIM_ID:&P32_CLAIM_ID.',
    p_branch_point => 'AFTER_PROCESSING',
    p_branch_sequence => 10
  );
end;
/


-- =============================================================================
-- Page 32 — تفاصيل المطالبة + مراجعتها
-- =============================================================================
prompt --application/pages/page_00032
begin
  wwv_flow_imp.create_page(
    p_id               => 32,
    p_name             => 'تفاصيل المطالبة',
    p_alias            => 'CLAIM-DETAIL',
    p_step_title       => 'تفاصيل المطالبة التأمينية'
  );
end;
/

begin
  wwv_flow_imp.create_page_item(
    p_id => 32000, p_flow_id => 100, p_flow_step_id => 32,
    p_name => 'P32_CLAIM_ID', p_item_sequence => 5,
    p_display_as => 'NATIVE_HIDDEN', p_attribute_01 => 'Y'
  );

  -- تفاصيل الفاتورة (Callout region)
  wwv_flow_imp.create_report_region(
    p_id => 32001, p_flow_id => 100, p_page_id => 32,
    p_name => 'بيانات المطالبة',
    p_template => 'Standard',
    p_display_sequence => 10,
    p_region_template_options => '#DEFAULT#:t-Region--scrollBody',
    p_query_type => 'SQL',
    p_query => q'[
SELECT
    claim_number, employee_name, beneficiary_name,
    claim_type_ar, TO_CHAR(claim_date,'YYYY/MM/DD') claim_date,
    hospital_name, diagnosis,
    TO_CHAR(invoice_amount,'FM999,999,990.00')   AS invoice_amount,
    coverage_pct || '%'                           AS coverage_pct,
    TO_CHAR(insurance_amount,'FM999,999,990.00') AS insurance_amount,
    TO_CHAR(employee_amount,'FM999,999,990.00')  AS employee_amount,
    TO_CHAR(approved_amount,'FM999,999,990.00')  AS approved_amount,
    status_ar, notes, rejection_reason,
    TO_CHAR(reviewed_at,'YYYY/MM/DD HH24:MI')    AS reviewed_at,
    reviewed_by
FROM v_claims WHERE claim_id = :P32_CLAIM_ID]'
  );

  -- Interactive Grid: المستندات
  wwv_flow_imp.create_region(
    p_id => 32002, p_flow_id => 100, p_page_id => 32,
    p_name => 'المستندات المرفقة',
    p_template => 'Standard', p_display_sequence => 20,
    p_region_template_options => '#DEFAULT#',
    p_query_type => 'SQL',
    p_region_source => q'[
SELECT
    document_id, claim_id,
    CASE doc_type
        WHEN 'INVOICE'         THEN 'فاتورة طبية'
        WHEN 'DOCTOR_REQUEST'  THEN 'طلب طبيب'
        WHEN 'PRESCRIPTION'    THEN 'وصفة طبية'
        WHEN 'LAB_RESULT'      THEN 'نتيجة مختبر'
        WHEN 'XRAY'            THEN 'أشعة'
        WHEN 'DISCHARGE'       THEN 'ملخص خروج'
        ELSE 'أخرى'
    END AS doc_type_ar,
    filename,
    TO_CHAR(file_size/1024,'FM999,990.0') || ' KB' AS file_size_kb,
    TO_CHAR(uploaded_at,'YYYY/MM/DD HH24:MI') AS uploaded_at,
    uploaded_by,
    apex_util.get_blob_file_src('P32_FILE',document_id) AS download_link
FROM hi_documents WHERE claim_id = :P32_CLAIM_ID]'
  );

  -- قسم المراجعة (Admin فقط)
  wwv_flow_imp.create_region(
    p_id => 32003, p_flow_id => 100, p_page_id => 32,
    p_name => 'مراجعة المطالبة',
    p_template => 'Standard', p_display_sequence => 30,
    p_region_template_options => '#DEFAULT#:t-Region--accent4',
    p_authorization_scheme => 100   -- Must Be Admin
  );
  wwv_flow_imp.create_page_item(
    p_id => 32010, p_flow_id => 100, p_flow_step_id => 32,
    p_name => 'P32_NEW_STATUS', p_item_sequence => 10, p_item_plug_id => 32003,
    p_prompt => 'الحالة الجديدة', p_display_as => 'NATIVE_SELECT_LIST',
    p_lov => 'LOV_CLAIM_STATUS', p_lov_display_null => 'YES',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_attribute_01 => 'NONE', p_attribute_02 => 'N'
  );
  wwv_flow_imp.create_page_item(
    p_id => 32020, p_flow_id => 100, p_flow_step_id => 32,
    p_name => 'P32_APPROVED_AMOUNT', p_item_sequence => 20, p_item_plug_id => 32003,
    p_prompt => 'المبلغ المعتمد (ريال)', p_display_as => 'NATIVE_NUMBER_FIELD',
    p_field_template => 'Optional - Floating',
    p_attribute_03 => 'right', p_attribute_04 => 'text'
  );
  wwv_flow_imp.create_page_item(
    p_id => 32030, p_flow_id => 100, p_flow_step_id => 32,
    p_name => 'P32_REVIEW_NOTES', p_item_sequence => 30, p_item_plug_id => 32003,
    p_prompt => 'ملاحظات المراجع', p_display_as => 'NATIVE_TEXTAREA',
    p_field_template => 'Optional - Floating',
    p_attribute_01 => 'Y', p_attribute_02 => 'N', p_attribute_03 => '3'
  );
  wwv_flow_imp.create_page_item(
    p_id => 32040, p_flow_id => 100, p_flow_step_id => 32,
    p_name => 'P32_REJECTION_REASON', p_item_sequence => 40, p_item_plug_id => 32003,
    p_prompt => 'سبب الرفض', p_display_as => 'NATIVE_TEXTAREA',
    p_field_template => 'Optional - Floating',
    p_attribute_01 => 'Y', p_attribute_02 => 'N', p_attribute_03 => '3'
  );

  wwv_flow_imp.create_page_button(
    p_id => 32100, p_flow_id => 100, p_flow_step_id => 32,
    p_button_sequence => 10, p_button_name => 'REVIEW',
    p_button_action => 'SUBMIT',
    p_button_image_alt => 'حفظ القرار',
    p_button_position => 'BELOW_BOX',
    p_button_css_classes => 't-Button--hot',
    p_icon_css_classes => 'fa-save',
    p_button_execute_validations => 'Y',
    p_button_plug_id => 32003
  );

  wwv_flow_imp.create_page_process(
    p_id => 32200, p_flow_id => 100, p_flow_step_id => 32,
    p_process_sequence => 10, p_process_point => 'AFTER_SUBMIT',
    p_process_type => 'NATIVE_PLSQL',
    p_process_name => 'مراجعة المطالبة',
    p_process_sql_clob => q'[
BEGIN
    pkg_insurance.review_claim(
        p_claim_id         => :P32_CLAIM_ID,
        p_new_status       => :P32_NEW_STATUS,
        p_approved_amount  => :P32_APPROVED_AMOUNT,
        p_notes            => :P32_REVIEW_NOTES,
        p_rejection_reason => :P32_REJECTION_REASON
    );
END;]',
    p_error_display_location => 'INLINE_IN_NOTIFICATION',
    p_process_success_message => 'تم حفظ قرار المراجعة'
  );
  wwv_flow_imp.create_page_branch(
    p_id => 32300, p_flow_id => 100, p_flow_step_id => 32,
    p_branch_action => 'f?p=&APP_ID.:32:&SESSION.::NO:32:P32_CLAIM_ID:&P32_CLAIM_ID.',
    p_branch_point => 'AFTER_PROCESSING', p_branch_sequence => 10
  );
end;
/


-- =============================================================================
-- Page 40 — التقارير (Charts + Report)
-- =============================================================================
prompt --application/pages/page_00040
begin
  wwv_flow_imp.create_page(
    p_id               => 40,
    p_name             => 'التقارير',
    p_alias            => 'REPORTS',
    p_step_title       => 'التقارير والإحصاءات'
  );
end;
/

begin
  -- مخطط دائري: توزيع المطالبات حسب النوع
  wwv_flow_imp.create_region(
    p_id => 40001, p_flow_id => 100, p_page_id => 40,
    p_name => 'توزيع المطالبات حسب النوع',
    p_template => 'Standard', p_display_sequence => 10,
    p_region_template_options => '#DEFAULT#'
  );
  wwv_flow_imp.create_jet_chart(
    p_id => 40010, p_region_id => 40001,
    p_chart_type => 'pie',
    p_height => '300'
  );
  wwv_flow_imp.create_jet_chart_series(
    p_id => 40011, p_chart_id => 40010,
    p_data_query => q'[
SELECT
    CASE claim_type WHEN 'INPATIENT' THEN 'مريض داخلي'
                    WHEN 'OUTPATIENT' THEN 'عيادات خارجية'
                    ELSE 'طوارئ' END AS label,
    COUNT(*) AS value
FROM hi_claims
WHERE EXTRACT(YEAR FROM claim_date) = EXTRACT(YEAR FROM SYSDATE)
GROUP BY claim_type]',
    p_items_value_column_name => 'VALUE',
    p_items_label_column_name => 'LABEL',
    p_series_name => 'المطالبات'
  );

  -- استهلاك الموظفين
  wwv_flow_imp.create_report_region(
    p_id => 40002, p_flow_id => 100, p_page_id => 40,
    p_name => 'استهلاك الموظفين - ' || TO_CHAR(SYSDATE,'YYYY'),
    p_template => 'Interactive Report',
    p_display_sequence => 20,
    p_query_type => 'SQL',
    p_query => q'[
SELECT
    emp_number,
    full_name,
    department,
    emp_annual_limit,
    annual_used,
    annual_remaining,
    usage_pct || '%' AS usage_pct,
    APEX_ITEM.TEXT_FROM_LOV_QUERY(
        usage_pct,
        'SELECT TO_CHAR(:1) d, TO_CHAR(:1) r FROM DUAL'
    ) AS usage_bar,
    claims_count
FROM v_employee_stats
WHERE is_active = 1
ORDER BY annual_used DESC]'
  );
end;
/


-- =============================================================================
-- Page 50 — الإعدادات
-- =============================================================================
prompt --application/pages/page_00050
begin
  wwv_flow_imp.create_page(
    p_id               => 50,
    p_name             => 'الإعدادات',
    p_alias            => 'SETTINGS',
    p_step_title       => 'إعدادات سياسة التأمين',
    p_authorization_scheme => 100
  );
end;
/

begin
  wwv_flow_imp.create_region(
    p_id => 50001, p_flow_id => 100, p_page_id => 50,
    p_name => 'إعدادات التأمين الصحي',
    p_template => 'Standard', p_display_sequence => 10,
    p_region_template_options => '#DEFAULT#'
  );
  wwv_flow_imp.create_page_item(
    p_id => 50010, p_flow_id => 100, p_flow_step_id => 50,
    p_name => 'P50_SETTINGS_ID', p_item_sequence => 5, p_item_plug_id => 50001,
    p_display_as => 'NATIVE_HIDDEN', p_attribute_01 => 'Y',
    p_item_default => q'[SELECT MIN(settings_id) FROM hi_settings WHERE is_active=1]',
    p_item_default_type => 'SQL_QUERY'
  );
  wwv_flow_imp.create_page_item(
    p_id => 50020, p_flow_id => 100, p_flow_step_id => 50,
    p_name => 'P50_SETTINGS_NAME', p_item_sequence => 10, p_item_plug_id => 50001,
    p_prompt => 'اسم السياسة', p_display_as => 'NATIVE_TEXT_FIELD',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_source => 'SELECT settings_name FROM hi_settings WHERE settings_id = :P50_SETTINGS_ID',
    p_source_type => 'QUERY',
    p_attribute_01 => 'N', p_attribute_02 => 'N'
  );
  wwv_flow_imp.create_page_item(
    p_id => 50030, p_flow_id => 100, p_flow_step_id => 50,
    p_name => 'P50_INPATIENT_PCT', p_item_sequence => 20, p_item_plug_id => 50001,
    p_prompt => 'نسبة تغطية المريض الداخلي (رقود) %', p_display_as => 'NATIVE_NUMBER_FIELD',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_source => 'SELECT inpatient_pct FROM hi_settings WHERE settings_id = :P50_SETTINGS_ID',
    p_source_type => 'QUERY',
    p_attribute_03 => 'right', p_attribute_04 => 'text'
  );
  wwv_flow_imp.create_page_item(
    p_id => 50040, p_flow_id => 100, p_flow_step_id => 50,
    p_name => 'P50_OUTPATIENT_PCT', p_item_sequence => 30, p_item_plug_id => 50001,
    p_prompt => 'نسبة تغطية الطوارئ والعيادات %', p_display_as => 'NATIVE_NUMBER_FIELD',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_source => 'SELECT outpatient_pct FROM hi_settings WHERE settings_id = :P50_SETTINGS_ID',
    p_source_type => 'QUERY',
    p_attribute_03 => 'right', p_attribute_04 => 'text'
  );
  wwv_flow_imp.create_page_item(
    p_id => 50050, p_flow_id => 100, p_flow_step_id => 50,
    p_name => 'P50_EMP_ANNUAL_LIMIT', p_item_sequence => 40, p_item_plug_id => 50001,
    p_prompt => 'السقف السنوي للموظف (ريال)', p_display_as => 'NATIVE_NUMBER_FIELD',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_source => 'SELECT emp_annual_limit FROM hi_settings WHERE settings_id = :P50_SETTINGS_ID',
    p_source_type => 'QUERY',
    p_attribute_03 => 'right', p_attribute_04 => 'text'
  );
  wwv_flow_imp.create_page_item(
    p_id => 50060, p_flow_id => 100, p_flow_step_id => 50,
    p_name => 'P50_FAM_ANNUAL_LIMIT', p_item_sequence => 50, p_item_plug_id => 50001,
    p_prompt => 'السقف السنوي لكل فرد عائلة (ريال)', p_display_as => 'NATIVE_NUMBER_FIELD',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_source => 'SELECT fam_annual_limit FROM hi_settings WHERE settings_id = :P50_SETTINGS_ID',
    p_source_type => 'QUERY',
    p_attribute_03 => 'right', p_attribute_04 => 'text'
  );
  wwv_flow_imp.create_page_item(
    p_id => 50070, p_flow_id => 100, p_flow_step_id => 50,
    p_name => 'P50_MAX_PER_CLAIM', p_item_sequence => 60, p_item_plug_id => 50001,
    p_prompt => 'الحد الأقصى للمطالبة الواحدة (ريال)', p_display_as => 'NATIVE_NUMBER_FIELD',
    p_field_template => 'Required - Floating', p_is_required => 'Y',
    p_source => 'SELECT max_per_claim FROM hi_settings WHERE settings_id = :P50_SETTINGS_ID',
    p_source_type => 'QUERY',
    p_attribute_03 => 'right', p_attribute_04 => 'text'
  );

  wwv_flow_imp.create_page_button(
    p_id => 50100, p_flow_id => 100, p_flow_step_id => 50,
    p_button_sequence => 10, p_button_name => 'SAVE_SETTINGS',
    p_button_action => 'SUBMIT',
    p_button_image_alt => 'حفظ الإعدادات',
    p_button_position => 'BELOW_BOX',
    p_button_css_classes => 't-Button--hot',
    p_icon_css_classes => 'fa-save'
  );

  wwv_flow_imp.create_page_process(
    p_id => 50200, p_flow_id => 100, p_flow_step_id => 50,
    p_process_sequence => 10, p_process_point => 'AFTER_SUBMIT',
    p_process_type => 'NATIVE_PLSQL',
    p_process_name => 'حفظ إعدادات التأمين',
    p_process_sql_clob => q'[
BEGIN
    UPDATE hi_settings SET
        settings_name     = :P50_SETTINGS_NAME,
        inpatient_pct     = :P50_INPATIENT_PCT,
        outpatient_pct    = :P50_OUTPATIENT_PCT,
        emp_annual_limit  = :P50_EMP_ANNUAL_LIMIT,
        fam_annual_limit  = :P50_FAM_ANNUAL_LIMIT,
        max_per_claim     = :P50_MAX_PER_CLAIM
    WHERE settings_id     = :P50_SETTINGS_ID;
    COMMIT;
END;]',
    p_error_display_location => 'INLINE_IN_NOTIFICATION',
    p_process_success_message => 'تم حفظ إعدادات التأمين بنجاح'
  );
end;
/


-- =============================================================================
-- Navigation Menu
-- =============================================================================
begin
  wwv_flow_imp_shared.create_list(
    p_id         => 500,
    p_name       => 'Desktop Navigation Menu',
    p_list_type  => 'SQL_QUERY',
    p_list_query => q'[
SELECT 10, 'لوحة التحكم', 'icon-home',          'f?p=&APP_ID.:1:&SESSION.::NO::', null, null, null, null FROM DUAL
UNION ALL
SELECT 20, 'الموظفون',   'icon-people',          'f?p=&APP_ID.:2:&SESSION.::NO::', null, null, null, null FROM DUAL
UNION ALL
SELECT 30, 'المطالبات',  'icon-document',        'f?p=&APP_ID.:3:&SESSION.::NO::', null, null, null, null FROM DUAL
UNION ALL
SELECT 35, 'مطالبة جديدة','icon-plus',           'f?p=&APP_ID.:31:&SESSION.::NO::', null, null, null, null FROM DUAL
UNION ALL
SELECT 40, 'التقارير',   'icon-bar-chart',       'f?p=&APP_ID.:40:&SESSION.::NO::', null, null, null, null FROM DUAL
UNION ALL
SELECT 50, 'الإعدادات',  'icon-gear',            'f?p=&APP_ID.:50:&SESSION.::NO::', null, null, null, null FROM DUAL]'
  );
end;
/


-- =============================================================================
-- End Import
-- =============================================================================
begin
  wwv_flow_imp.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false));
end;
/
commit;
set define on
set verify on
set feedback on
prompt  --Done: Application 100 imported
