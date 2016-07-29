DROP PACKAGE APPS.XXQP_CATGY_SEGMENT;

CREATE OR REPLACE PACKAGE APPS."XXQP_CATGY_SEGMENT" 
/*
Description : This package is developed to be used as a Pricing attribute helper.
This package has 2 functions to fetch any of the item category segments.
One package is to fetch the data in the context of Order Management. Another one in the context of Quoting module
Developed by : Krishna Ayalavarapu on 12/5/2013
*/    
AS
  FUNCTION GET_SEGMENT_VALUE(
      P_CATGY_SET_NAME    VARCHAR2,
      P_SEGMENT_NO        VARCHAR2,
      P_INVENTORY_ITEM_ID NUMBER,
      P_ORGANIZATION_ID   NUMBER)
    RETURN VARCHAR2;
  FUNCTION GET_VALUE_FOR_OM(
      P_CATGY_SET_NAME VARCHAR2,
      P_SEGMENT_NO     VARCHAR2,
      P_line_record IN oe_order_pub.g_line%type)
    RETURN VARCHAR2;
  FUNCTION GET_VALUE_FOR_ASO(
      P_CATGY_SET_NAME VARCHAR2,
      P_SEGMENT_NO     VARCHAR2,
      P_line_record IN ASO_PRICING_INT.G_LINE_REC%type)
    RETURN VARCHAR2;
    FUNCTION get_Ship_to_cust_account_id(p_line_rec OE_ORDER_PUB.G_LINE%type) RETURN NUMBER;
    Function get_nationality(p_line_rec OE_ORDER_PUB.G_LINE%type) return varchar2;
    FUNCTION get_division(p_header_id IN number) RETURN CHAR ;
    FUNCTION get_sub_division(p_header_id IN number) RETURN CHAR;
    FUNCTION GET_VALUE_FOR_OM_HDR(
    P_CATGY_SET_NAME VARCHAR2,
    P_SEGMENT_NO     VARCHAR2,
    P_HDR_RECORD IN OE_ORDER_PUB.G_HDR%type)
  RETURN VARCHAR2;
    FUNCTION get_Ship_to_cust_account_id(p_header_id IN NUMBER) RETURN NUMBER;
    Function get_nationality(p_header_id in number) return varchar2;

END XXQP_CATGY_SEGMENT; 
/
