DROP PACKAGE APPS.XX_OE_ORDER_WS_IN_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OE_ORDER_WS_IN_PKG" AUTHID CURRENT_USER IS

  ----------------------------------------------------------------------------------
  /* $Header: XXOEORDERWSIN.pks 1.1 2013/05/08 12:00:00  Beda noship $ */
  /*
  Created By    : IBM Development Team
  Creation Date : 04-Apr-2012
  File Name     : XXOEORDERWSIN.pks
  Description   : This script creates the specification for the Sales Order from SOA

  Change History:

  Version Date        Name                          Remarks
  ------- ----------- -------------------           --------------------------------
  1.0     04-Apr-2012   IBM Development Team        Initial development.
  1.1     10-Oct-2013   IBM Development Team        Change for Case# 003548 and 002724
  1.1     18-Oct-2013   Bedabrata Bhattacharjee     Modification for GHX

  */
  ----------------------------------------------------------------------------------

  -- Global Variables

  G_PROCESS_NAME VARCHAR2(60) := 'XXOEORDERWSIN';

  G_ORDER_SOURCE_NAME VARCHAR2(200);

  G_SA_ORDER_TYPE VARCHAR2(200);

  G_SA_ORGANIZATION_CODE VARCHAR2(200);

  G_CN_ORDER_TYPE VARCHAR2(200);

  G_RO_SHIP_PRIORITY_CODE VARCHAR2(200);

  G_OVERNIGHT_SHIP_METHOD VARCHAR2(200);

  --G_INT_ORDER_TYPE VARCHAR2(200);

  --G_INT_ORGANIZATION_CODE VARCHAR2(200);

  G_CREATED_BY_MODULE VARCHAR2(40);

  G_GHX_FILE_TYPE VARCHAR2(200);

  G_GXS_FILE_TYPE VARCHAR2(200);

  G_GHX_REF_ID VARCHAR2(200);

  G_GHX_EDIINVALID_ITEM VARCHAR2(240);

  G_HDR_TP_CONTEXT VARCHAR2(240);

  G_SALES_CHANNEL VARCHAR2(200);

  G_TP_CONTEXT VARCHAR2(200);

  G_ISA_NO VARCHAR2(200);

   --Global variables holding transaction status messages
  G_SUCCESS_MSG VARCHAR2(10) := 'Success';
  G_FAILED_MSG VARCHAR2(10) := 'Failed';

     -- =================================================================================
  -- Record Type for Default Price List
  -- =================================================================================
  TYPE xx_price_list_rec_type IS RECORD(
    list_header_id     NUMBER,
    NAME               VARCHAR2(240),
    product_precedence NUMBER,
    order_number       NUMBER);

  -- =================================================================================
  -- Table Type By Using the Record Type for Default Price List
  -- =================================================================================
  TYPE xx_price_list_tab_type IS TABLE OF xx_price_list_rec_type INDEX BY BINARY_INTEGER;

  -- =================================================================================
  -- Declare Table type Variable
  -- =================================================================================
  p_price_list_table xx_price_list_tab_type;


  PROCEDURE xx_oe_insert(p_header    IN xx_oe_order_hdr_ws_in_typ,
                         p_line      IN xx_oe_order_line_ws_in_tabtyp,
                         p_header_id OUT NUMBER,
                         p_err_msg   OUT VARCHAR2);

  PROCEDURE xx_oe_fetch(p_header_id IN NUMBER,
                        p_header    OUT xx_oe_order_hdr_ws_in_typ,
                        p_line      OUT xx_oe_order_line_ws_in_tabtyp,
                        p_err_msg   OUT VARCHAR2);

  PROCEDURE xx_oe_create(p_oe_header IN xx_oe_order_hdr_objtyp,
                         p_oe_line   IN xx_oe_order_line_tabtyp,
                         p_oe_status OUT VARCHAR2,
                         p_err_msg   OUT VARCHAR2);

  PROCEDURE xx_oe_update(p_header_id IN NUMBER,
                         p_status    IN VARCHAR2,
                         p_err_dtls  IN VARCHAR2,
                         p_inst_id   IN VARCHAR2,
                         p_err_msg   OUT VARCHAR2);

 PROCEDURE xx_oe_error_insert(p_header_id   IN NUMBER,
                              p_line_id     IN NUMBER,
                              p_source_type IN VARCHAR2,
                              p_err_msg     IN VARCHAR2);

END xx_oe_order_ws_in_pkg;
/
