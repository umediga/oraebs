DROP VIEW APPS.XX_FND_USER_ROLE_ASSG_V;

/* Formatted on 6/6/2016 4:58:38 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_FND_USER_ROLE_ASSG_V
(
   FULL_NAME,
   EMAIL_FROM_HR,
   EMAIL_FROM_FND,
   USER_NAME,
   ROLE_RESP,
   ROLE_CODE,
   ROLE_OR_RESPONSIBILITY_NAME,
   ROLE_START,
   ROLE_END,
   USER_START_DATE,
   USER_END_DATE,
   DIRECT_INDIRECT,
   SUPERVISOR
)
AS
   SELECT c.full_name,
          c.EMAIL_ADDRESS email_from_hr,
          b.EMAIL_ADDRESS email_from_fnd,
          a.user_name,
          SUBSTR (role_name, 1, 3) role_resp,
          role_name role_code,
          display_name role_or_responsibility_name,
          active_from role_start,
          active_to role_end,
          b.start_date user_start_date,
          b.end_date user_end_date,
          DECODE (detail_region_switch,
                  'AssignedIndirectCase', 'Indirect',
                  'Direct')
             direct_indirect,
          (SELECT full_name
             FROM per_people_x
            WHERE person_id IN (SELECT supervisor_id
                                  FROM PER_ASSIGNMENTS_X
                                 WHERE person_id = c.person_id))
             supervisor
     FROM apps.umx_role_assignments_v a, apps.fnd_user b, per_people_x c
    WHERE     1 = 1
          AND a.user_id = b.user_id
          AND b.employee_id = c.person_id(+)
          AND b.creation_date >= '01-JAN-2012';


GRANT SELECT ON APPS.XX_FND_USER_ROLE_ASSG_V TO XXAPPSREAD;
