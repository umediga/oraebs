DROP VIEW APPS.XX_UMX_ROLE_RESP_PS_V;

/* Formatted on 6/6/2016 4:58:00 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_UMX_ROLE_RESP_PS_V
(
   ROLE_CATEGORY,
   USER_ROLE_NAME,
   ROLE_KEY,
   PERMISSION_SET,
   RESPONSIBILITY_NAME,
   RESP_MENU,
   REQUEST_GROUP_NAME
)
AS
   SELECT u1.category_lookup_code,
          wr.display_name user_role_name,
          wr.NAME role_key,
          fmp.menu_name permission_set,
          frtl.responsibility_name,
          fmtl.user_menu_name resp_menu,
          frg.request_group_name
     FROM fnd_responsibility fr,
          fnd_responsibility_tl frtl,
          umx_role_categories_v u1,
          fnd_application fa,
          wf_role_hierarchies wrh,
          wf_roles wr,
          fnd_request_groups frg,
          fnd_menus_tl fmtl,
          fnd_menus fmp,
          fnd_menus_tl fmpt,
          fnd_grants fg
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
          AND fr.menu_id = fmtl.menu_id
          AND fmtl.LANGUAGE = frtl.LANGUAGE
          AND fr.request_group_id = frg.request_group_id(+)
          AND wr.display_name LIKE 'INTG%' -- DE Warehouse Manager'--'INTG DE Warehouse Supervisor'
          -- AND wr.display_name LIKE 'INTG Cash Management Reports Role'
          AND wr.orig_system = 'UMX'
          ---
          AND fmp.menu_id = fmpt.menu_id
          --AND xmsro.migrated = 'N'
          AND fmpt.LANGUAGE = 'US'
          AND fmtl.LANGUAGE = 'US'
          AND fg.grantee_key(+) = wr.NAME --'UMX|INTG_WAREHOUSE_SUPERVISOR_DEOU_R'
          AND fg.menu_id = fmp.menu_id(+);
