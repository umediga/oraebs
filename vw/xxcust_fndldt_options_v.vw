DROP VIEW APPS.XXCUST_FNDLDT_OPTIONS_V;

/* Formatted on 6/6/2016 5:00:26 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXCUST_FNDLDT_OPTIONS_V
(
   NAME,
   USER_DEFINED_NAME,
   DESCRIPTION,
   APPLICATION_ID,
   OPTION_TYPE
)
AS
   (SELECT menu_name KEY_NM,
           user_menu_name UNAME,
           description DESCRIP,
           NULL APPLID,
           'MENU' OTYPE
      FROM fnd_menus_vl
    UNION
    SELECT responsibility_key KEY_NM,
           responsibility_name UNAME,
           description DESCRIP,
           application_id APPLID,
           'FND_RESPONSIBILITY' OTYPE
      FROM fnd_responsibility_vl
     WHERE SYSDATE BETWEEN NVL (start_date, SYSDATE)
                       AND NVL (end_date, SYSDATE)
    UNION
    SELECT concurrent_program_name KEY_NM,
           user_concurrent_program_name UNAME,
           description DESCRIP,
           application_id APPLID,
           'PROGRAM' OTYPE
      FROM fnd_concurrent_programs_vl
     WHERE enabled_flag = 'Y'
    UNION
    SELECT profile_option_name KEY_NM,
           user_profile_option_name UNAME,
           description DESCRIP,
           application_id APPLID,
           'PROFILE' OTYPE
      FROM fnd_profile_options_vl
     WHERE SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                       AND NVL (end_date_active, SYSDATE)
    UNION
    SELECT lookup_type,
           meaning,
           description,
           application_id,
           'FND_LOOKUP_TYPE'
      FROM fnd_lookup_types_vl
    UNION
    SELECT request_group_name,
           request_group_code,
           description,
           application_id,
           'REQUEST_GROUP'
      FROM fnd_request_groups
    UNION
    SELECT request_set_name,
           user_request_set_name,
           description,
           application_id,
           'REQUEST_SET'
      FROM fnd_request_sets_vl
     WHERE SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                       AND NVL (end_date_active, SYSDATE)
    UNION
    SELECT message_name,
           NULL,
           MESSAGE_TEXT,
           application_id,
           'FND_NEW_MESSAGE'
      FROM fnd_new_messages
    UNION
    SELECT form_name,
           user_form_name,
           description,
           application_id,
           'FORM'
      FROM fnd_form_vl
    UNION
    SELECT function_name,
           user_function_name,
           description,
           application_id,
           'FUNCTION'
      FROM fnd_form_functions_vl);


GRANT SELECT ON APPS.XXCUST_FNDLDT_OPTIONS_V TO INTG_XX_NONHR_RO;
