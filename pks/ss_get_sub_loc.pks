DROP PACKAGE APPS.SS_GET_SUB_LOC;

CREATE OR REPLACE PACKAGE APPS.SS_GET_SUB_LOC
AS
  /*******************************************************************************************
  *******************************************************************************************
  PROJECT       :        Sea Spine
  PACKAGE NAME  :        SS_GET_SUB_LOC
  PURPOSE       :
  REVISIONS     :
  Ver        Date        Author            Company            Description
  ---------  ----------  ---------------   ----------
  ---------  ----------  ---------------
  1.0       14/12/14     Kannan Mariappan   Gaea Technologies   1. Created the Package
  ***********************************************************************************************
  **********************************************************************************************/
  FUNCTION GET_SUB(
      P_INVENTORY_ITEM_ID     IN NUMBER,
      P_ORGANIZATION_ID       IN NUMBER,
      P_LOCATOR_ID            IN NUMBER,
      p_transaction_source_id IN NUMBER,
      p_source_line_id        IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION GET_LOC(
      P_INVENTORY_ITEM_ID     IN NUMBER,
      P_ORGANIZATION_ID       IN NUMBER,
      P_LOCATOR_ID            IN NUMBER,
      p_transaction_source_id IN NUMBER,
      p_source_line_id        IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION GET_SUB_DESC(
      P_SUB_INV         IN VARCHAR2,
      P_ORGANIZATION_ID IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION GET_SERIAL_NUM(
      P_LOT_CODE        IN NUMBER,
      P_TRANSACTION_ID  IN NUMBER,
      P_ORGANIZATION_ID IN NUMBER,
      P_SERIAL_TRAN_ID  IN NUMBER)
    RETURN VARCHAR2;
  FUNCTION GET_SURGEON_KPI(
      P_ATTRIBUTE8 IN VARCHAR2)
    RETURN VARCHAR2;
  FUNCTION GET_SURGEON_NAME(
      P_ATTRIBUTE8 IN VARCHAR2)
    RETURN VARCHAR2;
END SS_GET_SUB_LOC;
/
