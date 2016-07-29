DROP PACKAGE APPS.XX_OM_ADMIN_FEES_CAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OM_ADMIN_FEES_CAL_PKG" AS
G_PRICE_LIST_ID          NUMBER;
FUNCTION XX_START_DATE(p_cust_acc_id NUMBER)
RETURN DATE;
FUNCTION XX_EXPIRATION_DATE(p_cust_acc_id NUMBER)
RETURN DATE;
FUNCTION XX_LIST_PRICE_CAL(p_header_id NUMBER ,p_line_id NUMBER, p_price_list_id NUMBER, p_in_price_list VARCHAR2, p_inv_item_id NUMBER)
RETURN NUMBER;
FUNCTION XX_GPO_PRICE_LIST
RETURN VARCHAR2;
FUNCTION XX_GPO_LIST_PRICE(p_header_id NUMBER,p_line_id NUMBER, p_price_list_id NUMBER,p_inv_item_id NUMBER)
RETURN NUMBER;
FUNCTION XX_DISCOUNT_CAL(p_header_id NUMBER ,p_line_id NUMBER, p_price_list_id NUMBER, p_in_price_list VARCHAR2)
RETURN NUMBER;
FUNCTION XX_PERCENTAGE
RETURN VARCHAR;
FUNCTION XX_DIVISION
RETURN VARCHAR;
FUNCTION XX_CONTRACT_NUMBER
RETURN VARCHAR2;
FUNCTION XX_ADMIN_FEE_PAYMENT
RETURN VARCHAR;
FUNCTION XX_GPO_IDN_NAME(p_price_list_id NUMBER)
RETURN VARCHAR2;
FUNCTION XX_GPO_ENTITY_CODE(p_gpo VARCHAR2, p_site_id NUMBER)
RETURN VARCHAR;
FUNCTION XX_GPO_PARTY_NAME(p_price_list_id NUMBER)
RETURN VARCHAR2;
FUNCTION XX_LINE_PRICE_LIST(p_price_list_id NUMBER)
RETURN VARCHAR2;
FUNCTION XX_PRICE_LIST_CHK(p_cust_site_use_id NUMBER, p_cust_acc_id NUMBER, p_attr4 VARCHAR2, p_attr7 VARCHAR2,p_attr3 VARCHAR2,
                            p_attr11 VARCHAR2,p_inv_id NUMBER)
RETURN VARCHAR2;
FUNCTION XX_PRICE_LIST_QUAL_CHK(p_cust_acc_id NUMBER , p_attr4 VARCHAR2, p_attr7 VARCHAR2,p_attr3 VARCHAR2,p_attr11 VARCHAR2,p_inv_id NUMBER,p_ord_item VARCHAR2)
RETURN VARCHAR2;
FUNCTION XX_PRICE_LIST_PROD_CHK(p_inv_id NUMBER ,p_price_list_id NUMBER)
RETURN VARCHAR2;
FUNCTION  XX_MOD_PROD_CHK(p_ord_item VARCHAR2 ,p_price_list_id NUMBER)
RETURN VARCHAR2;
END;
/
