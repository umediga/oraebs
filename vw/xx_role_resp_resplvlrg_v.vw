DROP VIEW APPS.XX_ROLE_RESP_RESPLVLRG_V;

/* Formatted on 6/6/2016 4:58:13 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_ROLE_RESP_RESPLVLRG_V
(
   REQUEST_GROUP_NAME,
   RESPONSIBILITY_NAME,
   USER_ROLE_NAME,
   ROLE_KEY
)
AS
   SELECT frg.REQUEST_GROUP_NAME,
          frtl.responsibility_name,
          wr.display_name User_Role_Name,
          wr.NAME Role_Key
     --wr.display_name User_Role_Name, wr.NAME Role_Key,fmp.menu_name Permission_set, frtl.responsibility_name,
     --       fmtl.user_menu_name Resp_Menu, frg.request_group_name
     FROM fnd_responsibility fr,
          fnd_responsibility_tl frtl,
          fnd_application fa,
          wf_role_hierarchies wrh,
          wf_roles wr,
          fnd_request_groups frg
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
          AND fr.request_group_id = frg.request_group_id(+)
          --   AND wr.display_name LIKE 'INTG%'-- DE Warehouse Manager'--'INTG DE Warehouse Supervisor'
          --   AND wr.display_name LIKE 'INTG US IO 104 Warehouse Manager'
          AND wr.orig_system = 'UMX';
