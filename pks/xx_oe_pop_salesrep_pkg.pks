DROP PACKAGE APPS.XX_OE_POP_SALESREP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OE_POP_SALESREP_PKG" AUTHID CURRENT_USER
----------------------------------------------------------------------
/* $Header: XXOESALESREPNAME.pks 1.0 2014/10/20 12:00:00 dparida noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 20-Oct-2014
 File Name      : XXOESALESREPNAME.pks
 Description    : This script creates the specification of the xx_oe_pop_salesrep_pkg package

 Change History:

 Version Date        Name                    Remarks
 ------- ----------- ----                    ----------------------
 1.0     20-Oct-2014 IBM Development Team    Initial development.
*/
----------------------------------------------------------------------
 AS
  -- =================================================================================
  -- These Global Variables are used to extract value from the process setup form
  -- =================================================================================

  -- =================================================================================
  -- Name           : xx_find_territories
  -- Description    : Procedure To Get Territory based upon different transaction qualifiers.
  -- Parameters description       :
  --
  -- No user parameter
  -- ==================================================================================
PROCEDURE xx_find_territories(
    p_country             VARCHAR2 ,
    p_customer_name_range VARCHAR2 ,
    p_customer_id         NUMBER ,
    p_site_number         NUMBER,
    p_division            VARCHAR2,
    p_sub_division        VARCHAR2,
    p_dcode               VARCHAR2,
    p_surgeon_name        VARCHAR2,
    p_cust_account        VARCHAR2 ,
    p_county              VARCHAR2,
    p_postal_code         VARCHAR2,
    p_province            VARCHAR2,
    p_state               VARCHAR2,
    o_terr_id OUT NUMBER ,
    o_status OUT VARCHAR2 ,
    o_error_message OUT VARCHAR2 );

  -- =================================================================================
  -- Name           : xx_ins_sales_credit_record
  -- Description    : Procedure To Fetch All Sales Rep For a Given Item and Customer Combination.
  -- Parameters description       :
  --
  -- No user parameter
  -- ==================================================================================
PROCEDURE xx_ins_sales_credit_record(
    p_line_scredit_tbl IN OUT oe_order_pub.line_scredit_tbl_type ,
    p_org_id          IN NUMBER ,
    o_return_status OUT VARCHAR2 ,
    o_return_message OUT VARCHAR2 );

  -- =================================================================================
  -- Name           : xx_oe_get_sales_rep_detail
  -- Description    : Function To Call the above two procedure to get the Salesrep detail
  --                  and insert the details to the table.
  -- Parameters description       :
  --
  -- No user parameter
  -- ==================================================================================
FUNCTION xx_oe_get_sales_rep_detail(
      p_inventory_item_id number,
      p_customer_id number,
      p_org_id number,
      p_ship_to_org_id number)
return varchar2;

END xx_oe_pop_salesrep_pkg;
/
