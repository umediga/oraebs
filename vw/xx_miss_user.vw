DROP VIEW APPS.XX_MISS_USER;

/* Formatted on 6/6/2016 4:58:25 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_MISS_USER
(
   USER_NAME
)
AS
   SELECT DISTINCT UPPER (a.user_name) user_name
     FROM XX_USER_ROLE_ASG a
   MINUS
   SELECT DISTINCT b.user_name
     FROM XX_USER_ROLE_ASG a, fnd_user b
    WHERE UPPER (a.user_name) = UPPER (b.user_name);
