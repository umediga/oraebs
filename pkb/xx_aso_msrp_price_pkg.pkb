DROP PACKAGE BODY APPS.XX_ASO_MSRP_PRICE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_ASO_MSRP_PRICE_PKG" 
----------------------------------------------------------------------
/* $Header: XXASOMSRPUPD.pkb 1.0 2012/03/22 12:00:00 dparida noship $ */
/*
 Created By    : IBM Development Team
 Creation Date : 23-Mar-2012
 File Name     : XXASOMSRPUPD.pkb
 Description   : This script creates the body of the package
                 xx_aso_msrp_price_pkg
 Change History:
 Date         Name                   Remarks
 -----------  -------------          -----------------------------------
 23-Mar-2012  IBM Development Team   Initial Draft.
 20-Feb-2013  Dhiren Parida	     bug# 002004
*/
-----------------------------------------------------------------------
AS
-- =================================================================================
-- Name           : XXASO_MSRP_PRC_UPD
-- Description    : This Function Will Invoked At Form Personalization Level
--                  This will return MSRP Price for the Item Entered in Quote Line.
--                  If there is no MSRP Price for the Item then It will Return Null
-- Parameters description       :
--
-- p_header_id    : Parameter To Store Quote Header ID (IN)
-- p_item_id      : Parameter To Store Item ID (IN)
-- ==============================================================================
FUNCTION XXASO_MSRP_PRC_UPD (p_header_id      NUMBER,
                             p_item_id        NUMBER
                            ) RETURN VARCHAR2
IS
    x_currency_code     VARCHAR2(15);
    x_list_price        VARCHAR2(50);
    x_price_list_id     NUMBER;

  -- Cursor to extract currency code from quote header
  CURSOR c_currency_code_csr(cp_qt_header_id NUMBER)
    IS
      SELECT currency_code
	      FROM aso_quote_headers_all
       WHERE quote_header_id = cp_qt_header_id;

  -- Cursor to selct Price List ID
  CURSOR c_msrp_price_listid_csr(cp_curr_code VARCHAR2)
    IS
      SELECT list_header_id
        FROM qp_list_headers_all
       WHERE substr(name,6,4) = xx_emf_pkg.get_paramater_value (g_process_name,
                                                                g_pl_mid_string
                                                               )
         AND substr(name,11,3) = cp_curr_code
         AND SYSDATE BETWEEN nvl(start_date_active,SYSDATE) and nvl(end_date_active,SYSDATE) --- added for bug# 002004
         AND active_flag = 'Y';  --- added for bug# 002004


  -- Cursor to selct MSRP Price For the Item
  CURSOR c_msrp_price_csr(cp_price_list_id NUMBER,cp_curr_code VARCHAR2)
    IS
      SELECT ql.operand
        FROM qp_list_headers_all qh
            ,qp_list_lines_v ql
       WHERE qh.list_header_id = cp_price_list_id
         AND qh.list_header_id = ql.list_header_id
         AND qh.currency_code = cp_curr_code
         AND qh.active_flag = 'Y'
         AND qh.list_type_code = 'PRL'
         AND ql.list_line_type_code = 'PLL'
         AND SYSDATE BETWEEN nvl(qh.start_date_active,SYSDATE) and nvl(qh.end_date_active,SYSDATE)
         AND SYSDATE BETWEEN nvl(ql.start_date_active,SYSDATE) and nvl(ql.end_date_active,SYSDATE)
         AND ql.product_attr_value = TO_CHAR(p_item_id);

  BEGIN

     --- Fetch the Currency
     OPEN c_currency_code_csr(p_header_id);
    FETCH c_currency_code_csr
     INTO x_currency_code;
    CLOSE c_currency_code_csr;

     --- Fetch the PL ID
     OPEN c_msrp_price_listid_csr(x_currency_code);
    FETCH c_msrp_price_listid_csr
     INTO x_price_list_id;
    CLOSE c_msrp_price_listid_csr;

     --- Fetch the MSRP Price
     OPEN c_msrp_price_csr(x_price_list_id,x_currency_code);
    FETCH c_msrp_price_csr
     INTO x_list_price;
    CLOSE c_msrp_price_csr;

  RETURN x_list_price;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      x_list_price := null;
      RETURN x_list_price;
    WHEN OTHERS THEN
      x_list_price := null;
      RETURN x_list_price;
  END XXASO_MSRP_PRC_UPD;
END xx_aso_msrp_price_pkg;
/
