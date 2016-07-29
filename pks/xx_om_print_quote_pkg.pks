DROP PACKAGE APPS.XX_OM_PRINT_QUOTE_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OM_PRINT_QUOTE_PKG" AUTHID CURRENT_USER
----------------------------------------------------------------------
/* $Header: XXASOPRINTQOT.pks 1.0 2012/06/22 12:00:00 dparida noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 22-Jun-2012
 File Name      : XXASOPRINTQOT.pks
 Description    : This script creates the specification of the xx_om_print_quote_pkg package

 Change History:

 Version Date        Name                    Remarks
 ------- ----------- ----                    ----------------------
 1.0     22-Jun-12   IBM Development Team    Initial development.
*/
----------------------------------------------------------------------
 AS
  -- Global Variable Declaration
  -- =================================================================================
  -- Name           : xx_om_jtf_notes
  -- Description    : This Function Extract All The Notes For A Given Quote Number .
  -- Parameters description       :
  --
  -- p_quote_id  : Parameter To Quote Id (IN)
  -- ==============================================================================
  FUNCTION xx_om_jtf_notes(p_quote_id IN NUMBER) RETURN VARCHAR2;

  FUNCTION xx_aso_del_add1(p_quote_id IN NUMBER) RETURN VARCHAR2;

  FUNCTION xx_aso_del_add2(p_quote_id IN NUMBER) RETURN VARCHAR2;

  FUNCTION xx_aso_del_add3(p_quote_id IN NUMBER) RETURN VARCHAR2;

  FUNCTION xx_aso_del_add4(p_quote_id IN NUMBER) RETURN VARCHAR2;

  FUNCTION xx_aso_del_country(p_quote_id IN NUMBER) RETURN VARCHAR2;

  FUNCTION xx_aso_del_countryname(p_quote_id IN NUMBER) RETURN VARCHAR2;

  FUNCTION xx_aso_del_city(p_quote_id IN NUMBER) RETURN VARCHAR2;

  FUNCTION xx_aso_del_county(p_quote_id IN NUMBER) RETURN VARCHAR2;

  FUNCTION xx_aso_del_contactname(p_quote_id IN NUMBER) RETURN VARCHAR2;

  FUNCTION xx_aso_del_partyname(p_quote_id IN NUMBER) RETURN VARCHAR2;

  FUNCTION xx_om_cap_itm_cnt(p_quote_id IN NUMBER) RETURN NUMBER;

  FUNCTION xx_om_division_cnt(p_quote_id IN NUMBER) RETURN NUMBER;

  FUNCTION xx_om_bund_itm_price(p_quote_id IN NUMBER, p_item_id IN NUMBER)
    RETURN NUMBER;

  FUNCTION xx_om_access_itm_price(p_item_id IN NUMBER,
                                  p_org_id  IN NUMBER,
                                  p_cust_id IN NUMBER,
                                  p_hdr_id  IN NUMBER) RETURN NUMBER;

  FUNCTION xx_ava_language(p_lang_code IN VARCHAR2, p_msg_name IN VARCHAR2)
    RETURN NUMBER;

END xx_om_print_quote_pkg;
/
