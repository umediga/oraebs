DROP PACKAGE APPS.XX_AP_UNRECORD_LIAB_RPT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AP_UNRECORD_LIAB_RPT_PKG" 
as
   procedure debug(p_type in number, p_msg in varchar2);
   procedure print_xml_element(p_field in varchar2, p_value in varchar2);
   procedure print_xml_element(p_field in varchar2, p_value in date);
   procedure print_report(errbuf             out varchar2,
                          retcode            out varchar2,
                          p_ledger_id     in     number,
                          p_period_name   in     varchar2,
                          p_show_all_dist in varchar2);
end;
/
