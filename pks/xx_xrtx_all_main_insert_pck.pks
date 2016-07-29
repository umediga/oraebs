DROP PACKAGE APPS.XX_XRTX_ALL_MAIN_INSERT_PCK;

CREATE OR REPLACE PACKAGE APPS."XX_XRTX_ALL_MAIN_INSERT_PCK" 
AS
   PROCEDURE xx_xrtx_main_insert_p;

   PROCEDURE xx_xrtx_om_sys_param_p;

   PROCEDURE xx_xrtx_org_table_p;

   PROCEDURE xx_org_structure_user_p;

   PROCEDURE xx_org_structure_user_p1;

   PROCEDURE xx_org_structure_user_p2;

   PROCEDURE xx_org_structure_user_p3;

   PROCEDURE xx_org_structure_user_p4;

   PROCEDURE xx_org_structure_user_p5;

   PROCEDURE xx_xrtx_all_tables_data_pro;

   PROCEDURE xx_coa_load_table_p;

   PROCEDURE xx_coa_user;

   PROCEDURE xx_xrtx_load_table_p;

   PROCEDURE xx_xrtx_qual_p;

   PROCEDURE XX_XRTX_API_LIST_DET_P;


function xx_master_all (p_org_id number) return number;

function xx_master_manual (p_org_id number) return number;

function xx_master_intf (p_org_id number) return number;

END xx_xrtx_all_main_insert_pck;
/
