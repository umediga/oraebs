DROP PACKAGE BODY APPS.XX_PO_RCV_INSP;

CREATE OR REPLACE PACKAGE BODY APPS."XX_PO_RCV_INSP" 
  ----------------------------------------------------------------------
  /* $Header: XXPORCVINSPPKG.pks 1.0 2012/02/08 12:00:00 schakraborty noship $ */
  /*
  Created By     : IBM Development Team
  Creation Date  : 06-May-2012
  File Name      : XXPORCVINSPPKG.pks
  Description    : This script creates the body of the XX_PO_RCV_INSP package
  Change History:
  Version Date        Name                    Remarks
  ------- ----------- ----                    ----------------------
  1.0     06-May-2012   IBM Development Team    Initial development.
  */
  ----------------------------------------------------------------------
AS
-- This Function is used to set Order by Lexical for Data template of INTG Receiving Inspection Status Report--
FUNCTION AFTERPFORM(
    x_order_by     IN VARCHAR2,
    x_organization IN VARCHAR2)
  RETURN BOOLEAN
IS
BEGIN
  BEGIN
    SELECT organization_id
    INTO G_ORG_ID
    FROM org_organization_definitions
    WHERE organization_code=X_ORGANIZATION;
  EXCEPTION
  WHEN OTHERS THEN
    G_ORG_ID:=NULL;
  END;
  BEGIN
    SELECT organization_code
      ||' - '
      ||organization_name
    INTO G_ORG
    FROM org_organization_definitions
    WHERE organization_code=X_ORGANIZATION;
  EXCEPTION
  WHEN OTHERS THEN
    G_ORG_ID:=NULL;
  END;
  IF x_order_by ='Transaction Type' THEN
    G_ORDER_BY := '1';
  END IF;
  IF x_order_by ='Order' THEN
    G_ORDER_BY := '6';
  END IF;
  IF x_order_by ='Date' THEN
    G_ORDER_BY := '8';
  END IF;
  COMMIT;
  RETURN(TRUE);
END;
END xx_po_rcv_insp;
/
