DROP VIEW APPS.XX_FND_USER_ROLE_V;

/* Formatted on 6/6/2016 4:58:37 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_FND_USER_ROLE_V
(
   USER_NAME,
   RESPONSIBILITY_NAME,
   USER_ROLE_NAME,
   PASSWORD_LIFESPAN_DAYS,
   USER_START_DATE,
   USER_END_DATE,
   ROLE_START_DATE,
   ROLE_END_DATE,
   CREATION_DATE,
   LAST_UPDATE_DATE
)
AS
   SELECT b.user_name,
          c.responsibility_name,
          d.user_role_name,
          b.PASSWORD_LIFESPAN_DAYS,
          b.start_date user_start_date,
          b.end_date user_end_date,
          a.start_date role_start_date,
          a.end_date role_end_date,
          a.creation_date,
          a.last_update_date
     FROM fnd_user_resp_groups_direct a,
          fnd_user b,
          fnd_responsibility_vl c,
          xx_umx_role_resp_v d
    WHERE     a.user_id = b.user_id
          AND a.responsibility_id = c.responsibility_id
          AND b.user_name NOT LIKE '%@%'
          AND b.employee_id IS NOT NULL
          AND c.responsibility_name = d.responsibility_name
   UNION ALL
   SELECT b.user_name,
          c.responsibility_name,
          d.user_role_name,
          b.PASSWORD_LIFESPAN_DAYS,
          b.start_date,
          b.end_date,
          a.start_date,
          a.end_date,
          a.creation_date,
          a.last_update_date
     FROM fnd_user_resp_groups_indirect a,
          fnd_user b,
          fnd_responsibility_vl c,
          xx_umx_role_resp_v d
    WHERE     a.user_id = b.user_id
          AND a.responsibility_id = c.responsibility_id
          AND c.responsibility_name = d.responsibility_name
          AND b.user_name NOT LIKE '%@%'
          AND b.employee_id IS NOT NULL;


GRANT SELECT ON APPS.XX_FND_USER_ROLE_V TO XXAPPSREAD;
