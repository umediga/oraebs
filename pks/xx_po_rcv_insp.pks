DROP PACKAGE APPS.XX_PO_RCV_INSP;

CREATE OR REPLACE PACKAGE APPS."XX_PO_RCV_INSP" 
  ----------------------------------------------------------------------
  /* $Header: XXPORCVINSPPKG.pks 1.0 2012/02/08 12:00:00 schakraborty noship $ */
  /*
  Created By     : IBM Development Team
  Creation Date  : 06-May-2012
  File Name      : XXPORCVINSPPKG.pks
  Description    : This script creates the specification of the XX_PO_RCV_INSP package
  Change History:
  Version Date        Name                    Remarks
  ------- ----------- ----                    ----------------------
  1.0     06-May-2012   IBM Development Team    Initial development.
  */
  ----------------------------------------------------------------------
AUTHID CURRENT_USER AS
    X_ORGANIZATION VARCHAR2(1000);
    G_ORG VARCHAR2(1000);
    G_ORG_ID NUMBER;
    G_TRANSACTION_TYPE_FROM VARCHAR2(1000);
    G_TRANSACTION_TYPE_TO VARCHAR2(1000);
    G_TRANSACTION_DATE_FROM VARCHAR2(1000);
    G_TRANSACTION_DATE_TO VARCHAR2(1000);
    G_ORDER_FROM          VARCHAR2(1000);
    G_ORDER_TO          VARCHAR2(1000);
    G_FROM_INSPECTION_STATUS_CODE VARCHAR2(1000);
    G_TO_INSPECTION_STATUS_CODE VARCHAR2(1000);
    G_ITEM_FROM   VARCHAR2(1000);
    G_ITEM_TO     VARCHAR2(1000);
    X_ORDER_BY VARCHAR2(1000);
    G_ORDER_BY VARCHAR2(1000);
  /*  ---------------------------------------------------------------------- */
  /* --- This function is to initiate Global variable for data template      */
  /*  ---------------------------------------------------------------------- */
  FUNCTION AFTERPFORM(x_order_by IN VARCHAR2,x_organization IN VARCHAR2) RETURN BOOLEAN;
end xx_po_rcv_insp;
/
