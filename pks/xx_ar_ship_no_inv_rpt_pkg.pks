DROP PACKAGE APPS.XX_AR_SHIP_NO_INV_RPT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_SHIP_NO_INV_RPT_PKG" 
is
   g_operating_unit   varchar2(200);
   function get_inv_activity(p_function in varchar2)
      return varchar2;
   function get_inv_function(p_function in varchar2)
      return varchar2;
   procedure print_report;
   procedure generate_report(errcode out varchar2, return_status out varchar2, p_operating_unit in number);
end xx_ar_ship_no_inv_rpt_pkg;
/
