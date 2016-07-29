DROP PACKAGE APPS.XX_EAM_ASSET_GROUP_SEC_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_EAM_ASSET_GROUP_SEC_PKG" 
is
   procedure add_policy;
   procedure drop_policy;
   function vpd_eam_items(obj_schema varchar2, obj_name varchar2)
      return varchar2;
   function vpd_wo_policy(obj_schema varchar2, obj_name varchar2)
      return varchar2;
end;
/
