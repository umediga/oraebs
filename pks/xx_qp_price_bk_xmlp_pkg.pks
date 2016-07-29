DROP PACKAGE APPS.XX_QP_PRICE_BK_XMLP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_QP_PRICE_BK_XMLP_PKG" AUTHID CURRENT_USER
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 26-MAR-2013
 File Name     : XXQPPRICEBKXMLP.pks
 Description   : This script creates the specification of the package
                 xx_qp_price_bk_xmlp_pkg to create code for after
                 report trigger
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 26-MAR-2013 Sharath Babu          Initial Development
*/
----------------------------------------------------------------------

    p_cust_num        VARCHAR2(30);
    p_cust_name       VARCHAR2(30);
    p_gpo_idn         VARCHAR2(240);
    p_cntrct_num      VARCHAR2(240);
    p_list_name       VARCHAR2(240);
    p_division        VARCHAR2(240);
    p_product_type    VARCHAR2(240);
    p_item_cat        VARCHAR2(240);
    p_item_num        VARCHAR2(40);
    p_prod_class      VARCHAR2(240);
    p_brand           VARCHAR2(240);
    p_show_std_cost   VARCHAR2(50);
    p_show_gmargin    VARCHAR2(50);
    p_pricing_date    VARCHAR2(50);
    p_ou_name         VARCHAR2(50);
    p_report_mode     VARCHAR2(50);

    P_CONC_REQUEST_ID  NUMBER;

    LP_WHERE           VARCHAR2(2000) := ' ';
    LP_GPO_IDN         VARCHAR2(2000) := ' ';
    LP_CNTRCT_NUM      VARCHAR2(2000) := ' ';
    LP_LIST_NAME       VARCHAR2(2000) := ' ';
    LP_DIVISION        VARCHAR2(2000) := ' ';
    LP_PRODUCT_TYPE    VARCHAR2(2000) := ' ';
    LP_ITEM_CAT_PRL    VARCHAR2(2000) := ' ';
    LP_ITEM_CAT_DLT    VARCHAR2(2000) := ' ';
    LP_ITEM_NUM_PRL    VARCHAR2(2000) := ' ';
    LP_ITEM_NUM_DLT    VARCHAR2(2000) := ' ';
    LP_OU_NAME	       VARCHAR2(2000) := ' ';
    LP_CUST_NUM        VARCHAR2(2000) := ' ';
    LP_PROD_CLASS      VARCHAR2(2000) := ' ';
    LP_BRAND           VARCHAR2(2000) := ' ';

    FUNCTION AFTERPFORM RETURN BOOLEAN;
    FUNCTION AFTERREPORT RETURN BOOLEAN;

    FUNCTION get_item_std_cost( p_inv_item_id IN NUMBER )
    RETURN NUMBER;
    FUNCTION get_gross_margin( p_price    IN NUMBER
                              ,p_std_cost IN NUMBER )
    RETURN NUMBER;

END XX_QP_PRICE_BK_XMLP_PKG;
/
