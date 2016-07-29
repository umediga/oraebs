DROP VIEW APPS.XX_UMX_ROLE_RESP_V;

/* Formatted on 6/6/2016 4:58:00 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_UMX_ROLE_RESP_V
(
   ROLE_CATEGORY,
   USER_ROLE_NAME,
   ROLE_KEY,
   RESPONSIBILITY_NAME,
   REQUEST_GROP_ID
)
AS
   SELECT u1.category_lookup_code role_category,
          wr.display_name user_role_name,
          wr.NAME role_key,
          frtl.responsibility_name,
          fr.REQUEST_GROUP_ID
     FROM fnd_responsibility fr,
          fnd_responsibility_tl frtl,
          umx_role_categories_v u1,
          fnd_application fa,
          wf_role_hierarchies wrh,
          wf_roles wr
    --            fnd_request_groups frg,
    --          fnd_menus_tl fmtl,
    --        fnd_menus fmp,
    --      fnd_menus_tl fmpt,
    --    fnd_grants fg
    WHERE     u1.wf_role_name = wr.NAME
          AND wrh.super_name =
                    'FND_RESP|'
                 || fa.application_short_name
                 || '|'
                 || fr.responsibility_key
                 || '|STANDARD'
          AND fa.application_id = fr.application_id
          AND enabled_flag = 'Y'
          AND fr.responsibility_id = frtl.responsibility_id
          AND frtl.LANGUAGE = 'US'
          AND wr.NAME = wrh.sub_name
          AND wr.display_name LIKE 'INTG%' -- DE Warehouse Manager'--'INTG DE Warehouse Supervisor'
          AND wr.orig_system = 'UMX';


GRANT SELECT ON APPS.XX_UMX_ROLE_RESP_V TO XXAPPSREAD;
