DROP PACKAGE APPS.XX_OM_CSR_PRINT_QUOTE_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OM_CSR_PRINT_QUOTE_PKG" AUTHID CURRENT_USER
----------------------------------------------------------------------
/* $Header: XX_ONTPRINTQOT.pks 1.0 2013/10/10 12:00:00 dparida noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 10-Sep-2013
 File Name      : XX_ONTPRINTQOT.pks
 Description    : This script creates the specification of the xx_om_csr_print_quote_pkg package

 Change History:

 Version Date        Name                    Remarks
 ------- ----------- ----                    ----------------------
 1.0     10-Sep-13   IBM Development Team    Initial development.
*/
----------------------------------------------------------------------
 AS
  FUNCTION xx_om_cap_itm_cnt(p_quote_id IN NUMBER) RETURN NUMBER;

  FUNCTION xx_om_bund_itm_price(p_quote_id IN NUMBER, p_item_id IN NUMBER)
    RETURN NUMBER;

  FUNCTION xx_om_access_itm_price(p_item_id IN NUMBER,
                                  p_org_id  IN NUMBER,
                                  p_cust_id IN NUMBER,
                                  p_hdr_id  IN NUMBER) RETURN NUMBER;

END xx_om_csr_print_quote_pkg;
/
