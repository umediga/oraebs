DROP PACKAGE APPS.XX_AP_SER_HOLDS_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AP_SER_HOLDS_PKG" as
  function check_po_has_svc_line_with_req(p_po_header_id in number)
    return boolean;

  function get_inv_matched_status(p_invoice_id in number)
    return boolean;

  procedure process_service_holds(p_invoice_id in number);

  function get_default_approver
    return number;
end xx_ap_ser_holds_pkg;
/
