DROP PACKAGE APPS.XX_QP_MASS_PRICE_LIST_EXT_PKG;

CREATE OR REPLACE PACKAGE APPS.xx_qp_mass_price_list_ext_pkg AUTHID CURRENT_USER AS
  ----------------------------------------------------------------------
  /*
   Created By     : IBM Development Team
   Creation Date  : 17-Sep-2013
   File Name      : XXQPMASSPRICELISTEXT.pks
   Description    : This script creates the body of the package xx_qp_mass_price_list_ext_pkg


  Change History:

  Version Date          Name                       Remarks
  ------- -----------   --------                   -------------------------------
  1.0     20-Sep-2013   IBM Development Team       Initial development.
  */
  ----------------------------------------------------------------------
  --Global Variables
  G_ACTIVE_FLAG          VARCHAR2(1) := 'Y';
  G_GLOBAL_FLAG          VARCHAR2(1) := 'N';
  G_AUTOMATIC_FLAG       VARCHAR2(1) := 'Y';
  G_PRIMARY_UOM_FLAG     VARCHAR2(1) := 'N';
  G_LIST_TYPE_CODE       VARCHAR2(3) := 'PRL';
  G_PROCESS_NAME         VARCHAR2(30) := 'XXQPPRICELISTEXT';
  G_CURRENCY_HEADER      VARCHAR2(40) := NULL;
  G_SOURCE_SYSTEM        VARCHAR2(5) := 'QP';
  G_MOBILE_DOWNLOAD      VARCHAR2(1) := 'N';
  G_PRODUCT_ATTR_CONTEXT VARCHAR2(10) := 'ITEM';
  G_PRODUCT_ATTR_CODE    VARCHAR2(30) := 'ITEM NUMBER';
  G_LIST_LINE_TYPE       VARCHAR2(10) := 'PLL';
  --G_ARITHMETIC_OPERATOR  VARCHAR2(30) := 'UNIT_PRICE';
  g_list_line_type_mod    VARCHAR2(10) := 'DIS';
  g_modifier_level_code   VARCHAR2(10) := 'LINE';
  G_QP_LINE_DFF_CONTEXT  VARCHAR2(30) := 'Price Protection';
  G_CAT_SET_NAME         VARCHAR2(30) := NULL;
  G_ASO_HDR_DFF_CONTEXT  VARCHAR2(30) := NULL;
  G_JTF_TERR_SOURCE      VARCHAR2(30) := NULL;
  G_PRODUCT_PRECEDENCE   NUMBER := 220;
  G_APPLY_TO_ALL_SHIP_TO VARCHAR2(1) := 'N';
  --Procedures
  FUNCTION update_price_list(p_list_type          IN VARCHAR2,  --new
                             p_list_name          IN VARCHAR2,
                             p_product_attribute  IN VARCHAR2, --new
                             p_product_value      IN VARCHAR2, --mod
                             p_appl_method        IN VARCHAR2, --new
                             p_price              IN VARCHAR2,
                             p_start_date         IN DATE,
                             p_end_date           IN DATE,
                             p_precedence         IN VARCHAR2,
                             p_price_protect_flag IN VARCHAR2,
                             p_record_type        IN VARCHAR2,  --new
                             p_uom                IN VARCHAR2,
                             p_pricing_phase_id   IN NUMBER
                            ) RETURN VARCHAR;


END xx_qp_mass_price_list_ext_pkg;
/
