DROP VIEW APPS.XX_FND_USER_ADMIN_ROLE_V;

/* Formatted on 6/6/2016 4:58:38 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_FND_USER_ADMIN_ROLE_V
(
   USER_NAME,
   ROLE_NAME,
   STATUS_CODE,
   DISPLAY_NAME
)
AS
   SELECT a.user_name,
          a.role_name,
          a.status_code,
          a.display_name
     FROM umx_role_assignments_v a, fnd_user b
    WHERE     a.display_name = 'INTG User Admin'
          AND a.status_code = 'APPROVED'
          AND a.user_name = b.user_name
          AND NVL (b.end_date, SYSDATE + 1) >= SYSDATE;


GRANT SELECT ON APPS.XX_FND_USER_ADMIN_ROLE_V TO XXAPPSREAD;
