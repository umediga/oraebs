DROP VIEW APPS.XX_ROLE_ROLELVL_RG_V;

/* Formatted on 6/6/2016 4:58:12 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_ROLE_ROLELVL_RG_V
(
   USER_ROLE_NAME,
   ROLE_KEY,
   REQUEST_GROUP_NAME
)
AS
   SELECT wr.display_name User_Role_Name,
          wr.NAME Role_Key,
          frg.request_group_name
     FROM wf_roles wr, fnd_request_groups frg, fnd_grants fg
    WHERE 1 = 1                               -- wrh.super_name=   'FND_RESP|'
               AND wr.orig_system = 'UMX' AND fg.grantee_key = wr.NAME --'UMX|INTG_WAREHOUSE_SUPERVISOR_DEOU_R'
                               --   AND fg.grantee_key= 'UMX|INTG_CE_INQ_RG_R'
           AND fg.PARAMETER1 = frg.REQUEST_GROUP_NAME;
