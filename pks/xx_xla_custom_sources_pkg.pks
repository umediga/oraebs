DROP PACKAGE APPS.XX_XLA_CUSTOM_SOURCES_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_XLA_CUSTOM_SOURCES_PKG" 
AS
  FUNCTION get_item_product_line(
      p_customer_trx_id IN NUMBER ,
      p_cust_trx_line_id IN NUMBER ,
      p_iface_line_context IN VARCHAR2 ,
      p_order_type IN VARCHAR2)
    RETURN VARCHAR2;
  FUNCTION get_vendor_type(
      p_vendor_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION get_organization_id(
      p_rcv_trx_id IN NUMBER)
    RETURN NUMBER;
  FUNCTION get_rcv_acct_bal_segment(
      p_rcv_trx_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION get_destination(
      p_rcv_trx_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION get_salesrep_region(
      p_trx_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION check_expense_accruals(
      p_inv_dist_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION get_vendor_site_ic_segment(
      p_vendor_site_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION check_ppv_vendor_type(
      p_trx_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION get_vendor_site_ic(
      p_trx_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION check_ic_customer(
      p_order_line_id IN VARCHAR2)
    RETURN VARCHAR2;
  FUNCTION journal_desc(
      p_transaction_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION get_ic_customer(
      p_order_line_id IN VARCHAR2)
    RETURN VARCHAR2;
  FUNCTION get_order_type(
      p_order_line_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION get_line_type(
      p_order_line_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION get_order_type_cogs(
      p_order_line_id IN NUMBER)
    RETURN NUMBER;
  FUNCTION get_line_type_cogs(
      p_order_line_id IN NUMBER)
    RETURN NUMBER;
  FUNCTION get_ar_ic_cust_chk(
      p_acct_number IN VARCHAR2)
    RETURN VARCHAR2;
  FUNCTION get_trf_org_material_acct(
      p_transaction_id IN NUMBER)
    RETURN NUMBER;
  FUNCTION item_type(
      p_item_id IN NUMBER)
    RETURN mtl_system_items_b.item_type%type;
  FUNCTION get_trx_warehouse(
      p_customer_trx_id IN NUMBER,
      p_interface_context IN VARCHAR2)
    RETURN VARCHAR2;
  FUNCTION get_warehouse_company(
      p_customer_trx_id IN NUMBER,
      p_cust_trx_type_id IN NUMBER,
      p_interface_context IN VARCHAR2)
    RETURN VARCHAR2;
  FUNCTION get_rec_account(
      p_customer_trx_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION get_adj_trx_rec_acct(
      p_adjustment_id IN NUMBER)
    RETURN NUMBER;
  FUNCTION get_item_product_segment(
      p_item_id IN NUMBER,
      p_organization_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION get_ar_cr_ic_segment(
      p_cash_receipt_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION drop_ship_type(
      p_rcv_trx_id IN NUMBER)
    RETURN NUMBER;
  FUNCTION po_receipt_cross_ou(
      p_transaction_id IN NUMBER ,
      p_trx_source_type_id IN NUMBER ,
      p_trx_type_id IN NUMBER ,
      p_organization_id IN NUMBER ,
      p_rcv_trx_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION po_cross_ou_ic(
      p_transaction_id IN NUMBER ,
      p_trx_source_type_id IN NUMBER ,
      p_trx_type_id IN NUMBER ,
      p_organization_id IN NUMBER ,
      p_rcv_trx_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION po_cross_ou_ic_dest(
      p_transaction_id IN NUMBER ,
      p_trx_source_type_id IN NUMBER ,
      p_trx_type_id IN NUMBER ,
      p_organization_id IN NUMBER ,
      p_rcv_trx_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION is_117_approved_supp_list(
      p_item_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION get_nonrec_account(
      p_invoice_id IN NUMBER,
      p_inv_dist_id IN NUMBER,
      p_dist_acct_id IN NUMBER)
    RETURN NUMBER;
END xx_xla_custom_sources_pkg;
/
