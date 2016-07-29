DROP PACKAGE APPS.XX_ITM_PRICE_PKG;

CREATE OR REPLACE PACKAGE APPS.xx_itm_price_pkg AS
--------------------------------------------------------------------------------------
/*
 Created By    : Deepti Gaur
 Creation Date : 12-FEB-2015
 File Name     : XXINTGITMPRC.pks
 Description   : This Package calls the Pricing Engine API to calculate
                 the Unit Price,Unit List Price and Effective Untill Date

 Change History:

 Date        Name          Remarks
 ----------- -----------   ---------------------------------------
 10-FEB-2015   IBM Development    Initial development
 */
--------------------------------------------------------------------------------------



    PROCEDURE xx_itm_price(p_item_id IN NUMBER,p_org_id  IN NUMBER, p_cust_id IN NUMBER,
                          p_curr_code IN VARCHAR2,P_PRICING_DATE IN VARCHAR2,p_currency OUT VARCHAR2,
                          p_unit_price OUT NUMBER,p_adjusted_Price OUT NUMBER,p_effective_date OUT DATE) ;

    PROCEDURE find_the_best_date(in_compare_date IN DATE, effective_until OUT DATE);

    g_effective_until DATE;

 END xx_itm_price_pkg;
/
