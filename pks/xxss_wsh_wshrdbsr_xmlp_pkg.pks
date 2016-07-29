DROP PACKAGE APPS.XXSS_WSH_WSHRDBSR_XMLP_PKG;

CREATE OR REPLACE PACKAGE APPS.XXSS_WSH_WSHRDBSR_XMLP_PKG AUTHID CURRENT_USER AS
/* $Header: WSHRDBSRS.pls 120.3 2008/02/12 13:01:27 dwkrishn noship $ */
  P_CONC_REQUEST_ID NUMBER := 0;

  P_TRANSACTION_TYPE_ID NUMBER;

  P_HEADER_ID_LOW NUMBER;

  P_HEADER_ID_HIGH NUMBER;

  P_ITEM_FLEX_CODE VARCHAR2(32767);

  P_ORGANIZATION_ID NUMBER;

  P_USER_ID VARCHAR2(100);

  LP_ITEM_FLEX_ALL_SEG_LOW VARCHAR2(600);

  LP_ITEM_FLEX_ALL_SEG_HIGH VARCHAR2(600);

  --LP_ORDER_TYPE VARCHAR2(500);
  LP_ORDER_TYPE VARCHAR2(500):=' ';

  --LP_HEADER_NUMBER VARCHAR2(500);
  LP_HEADER_NUMBER VARCHAR2(500):=' ';

  RP_USER_ID VARCHAR2(200);

  RP_ORDER_TYPE_NAME VARCHAR2(30);

  LP_ITEM_DISPLAY_VALUE VARCHAR2(200) := 'wdd.item_description';

  P_ITEM_DISPLAY VARCHAR2(2);

  LP_STRUCTURE_NUM NUMBER := 101;

  LP_MOVE_ORDER VARCHAR2(200);

  P_ORDER_NUM_HIGH NUMBER;

  P_ORDER_NUM_LOW NUMBER;

  LP_ORGANIZATION_ID VARCHAR2(100):= ' ';

  RP_REPORT_NAME VARCHAR2(240);

  RP_SUB_TITLE VARCHAR2(80);

  RP_COMPANY_NAME VARCHAR2(240);

  RP_DATA_FOUND VARCHAR2(300);

  RP_ITEM_FLEX_ALL_SEG VARCHAR2(500) := 'SI.SEGMENT1';

  RP_ORDER_RANGE VARCHAR2(40);

  RP_ORDER_BY VARCHAR2(80);

  RP_FLEX_OR_DESC VARCHAR2(80);

  RP_WAREHOUSE VARCHAR2(240);

  RP_ORDER_NUM_LOW NUMBER;

  RP_ORDER_NUM_HIGH NUMBER;

  FUNCTION BEFOREREPORT RETURN BOOLEAN;

  FUNCTION AFTERREPORT RETURN BOOLEAN;

  FUNCTION P_ORGANIZATION_IDVALIDTRIGGER RETURN BOOLEAN;

  FUNCTION P_ITEM_FLEX_CODEVALIDTRIGGER RETURN BOOLEAN;

  FUNCTION AFTERPFORM RETURN BOOLEAN;

  FUNCTION C_SET_LBLFORMULA RETURN VARCHAR2;

  FUNCTION CF_ITEM_DESCRIPTIONFORMULA(INVENTORY_ITEM_ID1 IN NUMBER
                                     ,ORGANIZATION_ID IN NUMBER
                                     ,ITEM_DESCRIPTION IN VARCHAR2) RETURN VARCHAR2;

  FUNCTION CF_BO_AMTFORMULA(BACKORDERED_QUANTITY IN NUMBER
                           ,UNIT_PRICE IN NUMBER) RETURN NUMBER;

  FUNCTION CF_SHIPPED_AMTFORMULA(CF_SHIPPED_QTY IN NUMBER
                                ,UNIT_PRICE IN NUMBER) RETURN NUMBER;

  FUNCTION CF_WAREHOUSEFORMULA(ORGANIZATION_ID_V IN NUMBER) RETURN CHAR;

  FUNCTION CF_SHIPPED_QTYFORMULA(CURRENCY_CODE_V IN VARCHAR2
                                ,ORGANIZATION_ID_V IN NUMBER
                                ,INVENTORY_ITEM_ID1 IN NUMBER
                                ,SOURCE_HEADER_NUMBER_V IN VARCHAR2
                                ,ORDER_TYPE IN VARCHAR2
                                ,REQUESTED_QUANTITY_UOM_V IN VARCHAR2
                                ,UNIT_PRICE_V IN NUMBER) RETURN NUMBER;

  FUNCTION CF_LAST_SHIPPED_DATEFORMULA(ORGANIZATION_ID IN NUMBER
                                      ,SOURCE_HEADER_NUMBER IN VARCHAR2) RETURN DATE;

  FUNCTION CF_EMAIL_ID RETURN VARCHAR2 ;

  FUNCTION CF_EMAIL_SERVER RETURN VARCHAR2 ;

  FUNCTION CF_MESSAGE RETURN VARCHAR2 ;

  FUNCTION RP_REPORT_NAME_P RETURN VARCHAR2;

  FUNCTION RP_SUB_TITLE_P RETURN VARCHAR2;

  FUNCTION RP_COMPANY_NAME_P RETURN VARCHAR2;

  FUNCTION RP_DATA_FOUND_P RETURN VARCHAR2;

  FUNCTION RP_ITEM_FLEX_ALL_SEG_P RETURN VARCHAR2;

  FUNCTION RP_ORDER_RANGE_P RETURN VARCHAR2;

  FUNCTION RP_ORDER_BY_P RETURN VARCHAR2;

  FUNCTION RP_FLEX_OR_DESC_P RETURN VARCHAR2;

  FUNCTION RP_WAREHOUSE_P RETURN VARCHAR2;

  FUNCTION RP_ORDER_NUM_LOW_P RETURN NUMBER;

  FUNCTION RP_ORDER_NUM_HIGH_P RETURN NUMBER;

  PROCEDURE SET_NAME(APPLICATION IN VARCHAR2
                    ,NAME IN VARCHAR2);

  PROCEDURE SET_TOKEN(TOKEN IN VARCHAR2
                     ,VALUE IN VARCHAR2
                     ,TRANSLATE IN BOOLEAN);

  PROCEDURE RETRIEVE(MSGOUT OUT NOCOPY VARCHAR2);

  PROCEDURE CLEAR;

  FUNCTION GET_STRING(APPIN IN VARCHAR2
                     ,NAMEIN IN VARCHAR2) RETURN VARCHAR2;

  FUNCTION GET_NUMBER(APPIN IN VARCHAR2
                     ,NAMEIN IN VARCHAR2) RETURN NUMBER;

  FUNCTION GET RETURN VARCHAR2;

  FUNCTION GET_ENCODED RETURN VARCHAR2;

  PROCEDURE PARSE_ENCODED(ENCODED_MESSAGE IN VARCHAR2
                         ,APP_SHORT_NAME OUT NOCOPY VARCHAR2
                         ,MESSAGE_NAME OUT NOCOPY VARCHAR2);

  PROCEDURE SET_ENCODED(ENCODED_MESSAGE IN VARCHAR2);

  PROCEDURE RAISE_ERROR;

END XXSS_WSH_WSHRDBSR_XMLP_PKG;
/
