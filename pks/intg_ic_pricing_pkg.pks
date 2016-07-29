DROP PACKAGE APPS.INTG_IC_PRICING_PKG;

CREATE OR REPLACE PACKAGE APPS."INTG_IC_PRICING_PKG" 
AS
  FUNCTION get_transfer_price(
      i_transaction_id IN NUMBER,
      i_price_list_id IN NUMBER,
      i_sell_ou_id IN NUMBER,
      i_ship_ou_id IN NUMBER,
      o_currency_code OUT nocopy VARCHAR2,
      x_return_status OUT nocopy VARCHAR2,
      x_msg_count OUT nocopy     NUMBER,
      x_msg_data OUT nocopy      VARCHAR2,
      i_order_line_id IN NUMBER DEFAULT NULL)
    RETURN NUMBER;
  FUNCTION get_int_transfer_price(
      p_transaction_id IN NUMBER,
      p_organization_id IN NUMBER,
      p_inventory_item_id IN NUMBER,
      x_return_status OUT nocopy VARCHAR2,
      x_msg_data OUT nocopy      VARCHAR2,
      x_msg_count OUT nocopy     NUMBER)
    RETURN NUMBER;
  PROCEDURE print_log(
      p_message IN VARCHAR2);
  PROCEDURE update_customer(
      p_transaction_id IN NUMBER);
  FUNCTION build_accrual_acct(
      p_dist_account IN NUMBER,
      p_liability_acct IN NUMBER,
      p_org_id IN NUMBER,
      x_dist_acct OUT NUMBER)
    RETURN NUMBER;
  PROCEDURE update_supplier(
      p_invoice_id IN NUMBER);
  PROCEDURE update_ic_accrual_acct(
      p_invoice_id IN NUMBER,
      p_cust_trx_line_id IN NUMBER);
  FUNCTION get_sequence
    RETURN NUMBER;
  FUNCTION get_profit_inv_acct(
      p_from_organization_id IN NUMBER,
      p_to_organization_id IN NUMBER)
    RETURN NUMBER;
  FUNCTION get_item_cost(
      p_inventory_item_id IN NUMBER,
      p_organization_id IN NUMBER)
    RETURN NUMBER;
  FUNCTION check_cogs_recognition(
      p_transaction_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION check_cogs_percentage(
      p_transaction_id IN NUMBER)
    RETURN NUMBER;
  FUNCTION get_profit_inv_acct(
      p_trf_organization_id IN NUMBER ,
      p_organization_id IN NUMBER ,
      p_trx_type_id IN NUMBER ,
      p_rcv_trx_id IN NUMBER)
    RETURN NUMBER;
  FUNCTION get_entered_amount(
      p_transaction_id IN NUMBER,
      p_inventory_item_Id IN NUMBER,
      p_organization_id IN NUMBER,
      p_accounting_line_type IN NUMBER,
      p_entered_amount IN NUMBER,
      p_transaction_type_Id IN NUMBER,
      p_quantity IN NUMBER,
      P_base_amount IN NUMBER,
      p_currency IN VARCHAR2,
      p_rate IN NUMBER)
    RETURN NUMBER;
  FUNCTION get_functional_currency(
      p_organization_id IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION get_functional_amount(
      p_transaction_id IN NUMBER,
      p_inventory_item_Id IN NUMBER,
      p_organization_id IN NUMBER,
      p_accounting_line_type IN NUMBER,
      p_transaction_type_Id IN NUMBER,
      p_quantity IN NUMBER,
      P_base_amount IN NUMBER)
    RETURN NUMBER;
  FUNCTION get_ppv_amt(
      p_type IN VARCHAR2,
      p_transaction_id IN NUMBER,
      p_inventory_item_Id IN NUMBER,
      p_organization_id IN NUMBER,
      p_accounting_line_type IN NUMBER,
      p_entered_amount IN NUMBER,
      p_transaction_type_Id IN NUMBER,
      p_quantity IN NUMBER,
      P_base_amount IN NUMBER,
      p_currency IN VARCHAR2,
      p_rate IN NUMBER)
    RETURN NUMBER;
END intg_ic_pricing_pkg;
/
