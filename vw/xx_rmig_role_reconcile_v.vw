DROP VIEW APPS.XX_RMIG_ROLE_RECONCILE_V;

/* Formatted on 6/6/2016 4:58:13 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_RMIG_ROLE_RECONCILE_V
(
   ROLE_CATEGORY,
   USER_ROLE_NAME,
   RESPONSIBILITY_NAME,
   RESPONSIBILITY_KEY,
   USER_MENU_NAME,
   REQUEST_GROUP_NAME
)
AS
     SELECT DISTINCT role_category,
                     user_role_name,
                     d.RESPONSIBILITY_NAME,
                     d.RESPONSIBILITY_KEY,
                     b.USER_MENU_NAME,
                     c.REQUEST_GROUP_NAME
       FROM XX_UMX_ROLE_RESP_V a,
            fnd_menus_vl b,
            fnd_request_groups c,
            fnd_responsibility_vl d,
            XX_RMIG_PROD_ROLE_LIST e
      WHERE     1 = 1
            AND a.RESPONSIBILITY_NAME = d.RESPONSIBILITY_NAME
            AND a.USER_ROLE_NAME = e.ROLE_NAME
            AND d.MENU_ID = b.MENU_ID(+)
            AND a.REQUEST_GROP_ID = c.REQUEST_GROUP_ID(+)
   ORDER BY 1;


GRANT SELECT ON APPS.XX_RMIG_ROLE_RECONCILE_V TO XXAPPSREAD;
