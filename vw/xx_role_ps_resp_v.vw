DROP VIEW APPS.XX_ROLE_PS_RESP_V;

/* Formatted on 6/6/2016 4:58:13 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_ROLE_PS_RESP_V
(
   USER_ROLE_NAME,
   ROLE_KEY,
   PERMISSION_SET,
   RESPONSIBILITY_NAME,
   RESP_MENU
)
AS
     SELECT wr.display_name User_Role_Name,
            wr.NAME Role_Key,
            fmp.menu_name Permission_set,
            frtl.responsibility_name,
            fmtl.user_menu_name Resp_Menu           --, frg.request_group_name
       FROM fnd_responsibility fr,
            fnd_responsibility_tl frtl,
            fnd_application fa,
            wf_role_hierarchies wrh,
            wf_roles wr,
            --   fnd_request_groups frg,
            fnd_menus_tl fmtl,
            fnd_menus fmp,
            fnd_menus_tl fmpt,
            fnd_grants fg
      WHERE     wrh.super_name =
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
            AND fmtl.LANGUAGE = frtl.language
            -- AND fr.request_group_id = frg.request_group_id
            --AND wr.display_name LIKE 'INTG%'-- DE Warehouse Manager'--'INTG DE Warehouse Supervisor'
            -- AND wr.display_name LIKE 'INTG Cash Management Reports Role'
            AND wr.orig_system = 'UMX'
            AND fmp.menu_id = fmpt.menu_id
            --AND xmsro.migrated = 'N'
            AND fmpt.language = 'US'
            AND fmtl.language = 'US'
            AND fg.grantee_key = wr.NAME --'UMX|INTG_WAREHOUSE_SUPERVISOR_DEOU_R'
            --   AND fg.grantee_key= 'UMX|INTG_FINANCE_ADMIN_FAPA_BGG_R'
            AND fg.menu_id = fmp.menu_id
   ORDER BY wr.NAME, wr.display_name, RESPONSIBILITY_NAME;
