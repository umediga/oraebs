DROP PACKAGE APPS.XX_AP_DEBIT_MEMO_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AP_DEBIT_MEMO_PKG" 
as
   g_language         varchar2(100);
   g_vendor_id        number;
   g_invoice_type     varchar2(100);
   g_invoice_id       number;
   g_start_date       date;
   g_end_date         date;
   g_supp_site_lang   varchar2(100);
   g_operating_unit   number;
   procedure debug(p_type in number, p_msg in varchar2);
   procedure print_xml_element(p_field in varchar2, p_value in varchar2);
   procedure print_xml_element(p_field in varchar2, p_value in number);
   procedure print_xml_element(p_field in varchar2, p_value in date);
   function get_msg_value(p_msg_name in varchar2, p_language in varchar2)
      return varchar2;
   function print_labels
      return number;
   function getvendoraddressline1(p_vendor_site_id in number)
      return varchar2;
   function getphone(p_agent_id in number)
      return varchar2;
   function getlocationinfo(p_location_id in number, p_type in varchar2, p_le_id in number default null)
      return number;
   procedure get_tax(p_invoice_id in number, x_tax_rate out number, x_tax_amount out number);
   function get_tax_profile(p_party_id in number, p_party_type in varchar2)
      return varchar2;
   procedure print_invoice_lines(p_invoice_id in number);
   function get_inv_num(p_po_header_id in number,p_rcv_trx_id in number)
      return varchar2;
   procedure get_po_info(p_invoice_id in number);
   function get_language_predicate
      return varchar2;
   procedure print_report(xerrbuf                  out varchar2,
                          xretcode                 out varchar2,
                          p_operating_unit      in     number,
                          p_vendor_id           in     number,
                          p_invoice_type        in     varchar2,
                          p_invoice_id          in     number,
                          p_invoice_date_from   in     varchar2,
                          p_invoice_date_to     in     varchar2,
                          p_language            in     varchar2);
   function get_scar_number(p_invoice_id in number)
      return varchar2;
end;
/
