DROP PACKAGE APPS.XX_ASO_PRICE_LIST_EXT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ASO_PRICE_LIST_EXT_PKG" AS
----------------------------------------------------------------------
/*
 Created By     : Partha
 Creation Date  : 24-JUL-2013
 File Name      : XXASOPRICELISTEXT.pks
 Description    : This script creates the specification of the package xx_aso_price_list_ext_pkg


Change History:

Version Date          Name        Remarks
------- -----------   --------    -------------------------------
1.0     24-JUL-2013   Partha       Initial development.
*/
----------------------------------------------------------------------
   --Global Variables
   G_ACTIVE_FLAG           VARCHAR2(1) := 'Y';
   G_GLOBAL_FLAG           VARCHAR2(1) := 'N';
   G_AUTOMATIC_FLAG        VARCHAR2(1) := 'Y';
   G_PRIMARY_UOM_FLAG      VARCHAR2(1) := 'Y';
   G_LIST_TYPE_CODE        VARCHAR2(3) := 'DLT';
   G_LIST_LINE_TYPE_CODE   VARCHAR2(3) := 'DIS';
   G_PROCESS_NAME          VARCHAR2(30):= 'XXASOPRICELISTEXT';
   G_CURRENCY_HEADER       VARCHAR2(40):=  NULL;
   G_SOURCE_SYSTEM         VARCHAR2(5) := 'QP';
   G_MOBILE_DOWNLOAD       VARCHAR2(1) := 'N';
   G_PRODUCT_ATTR_CONTEXT  VARCHAR2(10):= 'ITEM';
   G_PRODUCT_ATTR_CODE     VARCHAR2(30):= 'ITEM NUMBER';
   G_QP_LINE_DFF_CONTEXT   VARCHAR2(30):= NULL;
   G_CAT_SET_NAME          VARCHAR2(30):= NULL;
   G_ASO_HDR_DFF_CONTEXT   VARCHAR2(30):= NULL;
   G_JTF_TERR_SOURCE       VARCHAR2(30):= NULL;
   G_PRODUCT_PRECEDENCE    NUMBER      := 220;
   G_APPLY_TO_ALL_SHIP_TO  VARCHAR2(1) := 'N';
   G_PRODUCT_ATTRIBUTE     VARCHAR2(50):= 'PRICING_ATTRIBUTE1';
   G_QUALIFIER_ATTRIBUTE   VARCHAR2(50):= 'QUALIFIER_ATTRIBUTE11';
   G_QUALIFIER_CONTEXT     VARCHAR2(50):= 'CUSTOMER';
   G_BASIS                 VARCHAR2(50):= 'USAGE';
   G_LIMIT_LEVEL_CODE      VARCHAR2(50):= 'ACROSS_TRANSACTION';
   G_MODIFIER_LEVEL_CODE   VARCHAR2(50):= 'LINE';
   G_ARITHMETIC_OPERATOR   VARCHAR2(50):= 'NEWPRICE';
   G_QUALIFIER_ATTR_HDR    VARCHAR2(50):= 'QUALIFIER_ATTRIBUTE2';
   G_PRICE_VALUE_CHANGED   VARCHAR2(1) := 'N';

   --Procedures
   PROCEDURE create_upd_price_list(itemtype     IN       VARCHAR2,
                                   itemkey      IN       VARCHAR2,
                                   actid        IN       NUMBER,
                                   funcmode     IN       VARCHAR2,
                                   resultout    OUT NOCOPY VARCHAR2
				  );
END xx_aso_price_list_ext_pkg;
/
