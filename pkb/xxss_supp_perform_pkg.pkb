DROP PACKAGE BODY APPS.XXSS_SUPP_PERFORM_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.XXSS_SUPP_PERFORM_PKG
AS
  /* *************************************************************************
  Package              : XXSS_SUPP_PERFORM_PKG
  Description          : This package is used for SeaSpine Oracle Supplier Performance Report
  Change List:
  ------------
  Name            Date        Version  Description
  --------------  ----------- -------  ------------------------------
  Ravisankar Ram  05-Feb-2016  1.0      Initial Version
 ***************************************************************************/

FUNCTION beforeReport
  RETURN boolean
IS
  ld_on_time_date DATE;
  lc_status varchar2(100);
  lb_flag boolean;

BEGIN

 XXSS_SUPP_PERFORM_PKG.xx_populate_transactions(
PN_SUPPLIER_ID
, PN_ORGANIZATION_ID
, PD_START_DATE
, PD_END_DATE
, lc_status
);

IF (lc_status = 'SUCCESS')
THEN
  lb_flag := true;
else
  lb_flag := false;
END IF;

RETURN lb_flag;
EXCEPTION
WHEN OTHERS THEN
FND_FILE.PUT_LINE(FND_FILE.LOG,'Error:'||SQLERRM);
  RETURN FALSE;
END beforeReport;

procedure xx_populate_transactions(
  PN_SUPPLIER_ID IN NUMBER
, PN_ORGANIZATION_ID IN NUMBER
, PD_START_DATE IN DATE
, PD_END_DATE IN DATE
, xc_status OUT NOCOPY VARCHAR2
)
IS
BEGIN

  IF PN_SUPPLIER_ID IS NOT NULL THEN
    BEGIN
      SELECT vendor_name
      INTO gc_supplier_name
      FROM ap_suppliers
      WHERE vendor_id = PN_SUPPLIER_ID;
    EXCEPTION
    WHEN OTHERS THEN
      gc_supplier_name := NULL;
    END;
  END IF;
  IF PN_ORGANIZATION_ID IS NOT NULL THEN
    BEGIN
      SELECT organization_code
      INTO gc_org_code
      FROM org_organization_definitions
      WHERE organization_id = PN_ORGANIZATION_ID;
      EXCEPTION
    WHEN OTHERS THEN
      gc_org_code := NULL;
    END;
  END IF;
  --inserting all records
  INSERT
  INTO XX_SUPPLIER_PERFORMANCE
    (
      TRANSACTION_ID ,
      REQUEST_ID ,
      TRANSACTION_TYPE ,
      TRANSACTION_DATE ,
      QUANTITY ,
      SHIPMENT_HEADER_ID ,
      SHIPMENT_LINE_ID ,
      PO_HEADER_ID ,
      PO_RELEASE_ID ,
      PO_LINE_ID ,
      PO_LINE_LOCATION_ID,
      PO_DISTRIBUTION_ID ,
      PO_REVISION_NUM ,
      REQUISITION_LINE_ID,
      ROUTING_HEADER_ID ,
      ROUTING_STEP_ID ,
      VENDOR_ID ,
      ATTRIBUTE_CATEGORY ,
      ORGANIZATION_ID ,
      QUANTITY_ORDERED ,
      QUANTITY_RECEIVED,
      RECEIVED_DATE,
      ORGINAL_PO_QUANTITY,
      ORGANIZATION_CODE,
      SUPPLIER_NAME,
      PO_LINE_NUMBER,
      ITEM_NAME,
      ITEM_DESCRIPTION,
      INVENTORY_ITEM_ID,
      UNIT_OF_MEASURE ,
      RECEIPT_NUM,
      PROMISED_DATE,
      NEED_BY_DATE,
      lots_on_time,
      lot_completness,
      stage,
      LAST_UPDATE_DATE,
      LAST_UPDATED_BY,
      CREATION_DATE,
      CREATED_BY,
      LAST_UPDATE_LOGIN
    )
  SELECT RT.TRANSACTION_ID ,
    gc_request_id REQUEST_ID ,
    RT.TRANSACTION_TYPE ,
    RT.TRANSACTION_DATE ,
    RT.QUANTITY ,
    RT.SHIPMENT_HEADER_ID ,
    RT.SHIPMENT_LINE_ID ,
    RT.PO_HEADER_ID ,
    RT.PO_RELEASE_ID ,
    RT.PO_LINE_ID ,
    RT.PO_LINE_LOCATION_ID,
    RT.PO_DISTRIBUTION_ID ,
    RT.PO_REVISION_NUM ,
    RT.REQUISITION_LINE_ID,
    RT.ROUTING_HEADER_ID ,
    RT.ROUTING_STEP_ID ,
    RT.VENDOR_ID ,
    RT.ATTRIBUTE_CATEGORY ,
    RT.ORGANIZATION_ID ,
    PLLA.QUANTITY QUANTITY_ORDERED ,
    RSL.QUANTITY_RECEIVED,
    RSH.CREATION_DATE RECEIVED_DATE,
    PLA.quantity ORGINAL_PO_QUANTITY,
    OOD.ORGANIZATION_CODE,
    AP.VENDOR_NAME SUPPLIER_NAME,
    RT.PO_LINE_ID PO_LINE_NUMBER,
    MSIB.segment1 ITEM_NAME,
    RSL.ITEM_DESCRIPTION ,
    MSIB.INVENTORY_ITEM_ID,
    RT.UNIT_OF_MEASURE UOM,
    RSH.RECEIPT_NUM,
    PLLA.PROMISED_DATE,
    PLLA.NEED_BY_DATE,
    DECODE( RT.TRANSACTION_TYPE , 'ACCEPT' ,(XXSS_SUPP_PERFORM_PKG.is_lot_on_time( RT.ORGANIZATION_ID , PLLA.PROMISED_DATE , PLLA.NEED_BY_DATE , RSH.CREATION_DATE )),'N') lots_on_time ,
    DECODE( RT.TRANSACTION_TYPE , 'ACCEPT' ,( XXSS_SUPP_PERFORM_PKG.is_lot_complete( RSL.QUANTITY_RECEIVED , PLLA.QUANTITY )), 'N') lot_completness ,
    1 stage,
    SYSDATE LAST_UPDATE_DATE,
    NVL(FND_GLOBAL.USER_ID,-2) LAST_UPDATED_BY,
    SYSDATE CREATION_DATE,
    NVL(FND_GLOBAL.USER_ID,-2) CREATED_BY,
    NVL(FND_GLOBAL.USER_ID,-2) LAST_UPDATE_LOGIN
  FROM RCV_TRANSACTIONS RT,
    RCV_SHIPMENT_LINES RSL,
    RCV_SHIPMENT_HEADERS RSH,
    PO_LINES_ALL PLA,
    PO_LINE_LOCATIONS_ALL PLLA,
    AP_SUPPLIERS AP,
    MTL_SYSTEM_ITEMS_B MSIB,
    ORG_ORGANIZATION_DEFINITIONS OOD
  WHERE RT.SHIPMENT_LINE_ID       = RSL.SHIPMENT_LINE_ID
  AND RSL.SHIPMENT_HEADER_ID      = RSH.SHIPMENT_HEADER_ID
  AND RT.SHIPMENT_HEADER_ID       = RSH.SHIPMENT_HEADER_ID
  AND PLA.PO_LINE_ID              = RT.PO_LINE_ID
  AND RT.PO_LINE_LOCATION_ID      = PLLA.LINE_LOCATION_ID
  AND PLLA.RECEIVING_ROUTING_ID   = 2
  AND AP.VENDOR_ID                = RT.VENDOR_ID
  AND MSIB.INVENTORY_ITEM_ID      = RSL.ITEM_ID
  AND MSIB.ORGANIZATION_ID        = RT.ORGANIZATION_ID
  AND OOD.ORGANIZATION_ID         = RSL.TO_ORGANIZATION_ID
  AND RT.TRANSACTION_TYPE        IN ( 'ACCEPT' ,'REJECT')
  AND RT.vendor_id                = NVL(PN_SUPPLIER_ID,RT.vendor_id)
  AND TRUNC(RT.TRANSACTION_DATE) >= TRUNC(PD_START_DATE)
  AND TRUNC(RT.TRANSACTION_DATE) <= TRUNC(PD_END_DATE)
  AND RT.ORGANIZATION_ID          = NVL(PN_ORGANIZATION_ID,RT.ORGANIZATION_ID );
   --AND RT.VENDOR_ID = pn_vendor_id;

  INSERT
  INTO XX_SUPPLIER_PERFORMANCE
    (
      vendor_id ,
      SUPPLIER_NAME ,
      REQUEST_ID ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CREATION_DATE ,
      CREATED_BY ,
      LAST_UPDATE_LOGIN ,
      stage ,
      no_txn_found
    )
	SELECT vendor_id ,
		   vendor_name ,
		   gc_request_id REQUEST_ID,
		   SYSDATE ,
		   NVL(FND_GLOBAL.USER_ID,-2) ,
		   SYSDATE ,
		   NVL(FND_GLOBAL.USER_ID,-2) ,
		   NVL(FND_GLOBAL.USER_ID,-2) ,
			1 ,
		   'Y'
	FROM ap_suppliers APS
	WHERE TRUNC(NVL(end_date_active,PD_START_DATE)) >= TRUNC(PD_START_DATE)
	AND TRUNC(NVL(end_date_active,PD_END_DATE))     <= TRUNC(PD_END_DATE)
	-- New Changes 11-02-2016
	AND APS.vendor_id                = NVL(PN_SUPPLIER_ID,APS.vendor_id)
	-- New Changes 11-02-2016
	AND NOT EXISTS
    (SELECT 1
	FROM XX_SUPPLIER_PERFORMANCE CUST
    WHERE   CUST.vendor_id = APS.vendor_id
		AND request_id       = gc_request_id
    );
	xc_status :=  'SUCCESS';
EXCEPTION
  WHEN OTHERS THEN
  xc_status := 'FAILED' || SQLERRM;
END xx_populate_transactions;

FUNCTION xx_get_next_workday(
    p_organization_id IN NUMBER ,
    p_from_date       IN DATE ,
    P_delay_hours     IN NUMBER)
  RETURN DATE
IS
  v_workday DATE := p_from_date;
  v_remaining_hours NUMBER;
  v_delay_hours     NUMBER := p_delay_hours;
BEGIN
  BEGIN
    SELECT ((TRUNC(v_workday + 1) - (v_workday))*24)
    INTO v_remaining_hours
    FROM DUAL;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_remaining_hours := NULL;
  WHEN TOO_MANY_ROWS THEN
    v_remaining_hours := NULL;
  END;
  BEGIN
    SELECT TRUNC(bcd1.calendar_date) + ((24 - v_remaining_hours) / 24)
    INTO v_workday
    FROM bom_calendar_dates bcd1 ,
      bom_calendar_dates bcd ,
      mtl_parameters mp
    WHERE bcd1.calendar_code  = bcd.calendar_code
    AND bcd1.exception_set_id = bcd.exception_set_id
    AND bcd1.seq_num          = bcd.next_seq_num
    AND bcd.calendar_code     = mp.calendar_code
    AND bcd.exception_set_id  = mp.calendar_exception_set_id
    AND mp.organization_id    = p_organization_id
    AND bcd.calendar_date     = TRUNC(v_workday);
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_workday := NULL;
  WHEN TOO_MANY_ROWS THEN
    v_workday := NULL;
  END;
  IF v_remaining_hours >= v_delay_hours THEN
    v_workday          := v_workday + (v_delay_hours / 24);
    v_delay_hours      := 0;
  ELSE
    v_workday     := v_workday      + (v_remaining_hours / 24);
    v_delay_hours := (v_delay_hours - v_remaining_hours);
    LOOP
      IF v_delay_hours = 0 THEN
        EXIT;
      ELSE
        IF v_delay_hours <= 24 THEN
          SELECT TRUNC(bcd1.calendar_date) + (v_delay_hours /24)
          INTO v_workday
          FROM bom_calendar_dates bcd1 ,
            bom_calendar_dates bcd ,
            mtl_parameters mp
          WHERE bcd1.calendar_code  = bcd.calendar_code
          AND bcd1.exception_set_id = bcd.exception_set_id
          AND bcd1.seq_num          = bcd.next_seq_num
          AND bcd.calendar_code     = mp.calendar_code
          AND bcd.exception_set_id  = mp.calendar_exception_set_id
          AND mp.organization_id    = p_organization_id
          AND bcd.calendar_date     = TRUNC(v_workday);
          v_delay_hours            := 0;
        ELSE
          SELECT TRUNC(bcd1.calendar_date)
          INTO v_workday
          FROM bom_calendar_dates bcd1 ,
            bom_calendar_dates bcd ,
            mtl_parameters mp
          WHERE bcd1.calendar_code  = bcd.calendar_code
          AND bcd1.exception_set_id = bcd.exception_set_id
          AND bcd1.seq_num          = bcd.next_seq_num + 1
          AND bcd.calendar_code     = mp.calendar_code
          AND bcd.exception_set_id  = mp.calendar_exception_set_id
          AND mp.organization_id    = p_organization_id
          AND bcd.calendar_date     = TRUNC(v_workday);
          v_delay_hours            := v_delay_hours - 24;
        END IF;
      END IF;
    END LOOP;
  END IF;
  RETURN v_workday;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  v_workday := NULL;
  RETURN v_workday;
WHEN TOO_MANY_ROWS THEN
  v_workday := NULL;
  RETURN v_workday;
END xx_get_next_workday;
FUNCTION is_lot_on_time(
    pn_organization_id IN NUMBER ,
    pd_promised_date   IN DATE ,
    pd_need_by_date    IN DATE ,
    pd_received_date   IN DATE )
  RETURN VARCHAR2
IS
  lc_flag VARCHAR2(100);
  ld_on_time_date DATE;
BEGIN
  ld_on_time_date := TRUNC(XXSS_SUPP_PERFORM_PKG.xx_get_next_workday(pn_organization_id,NVL(TRUNC(pd_promised_date),TRUNC(pd_need_by_date)),24*3));
 IF TRUNC(pd_received_date) <= ld_on_time_date THEN
    lc_flag                  := 'Y';
  ELSE
    lc_flag := 'N';
  END IF;
  RETURN lc_flag;
EXCEPTION
WHEN OTHERS THEN
  RETURN NULL;
END is_lot_on_time;
FUNCTION is_lot_complete(
    pn_received_quantity IN NUMBER ,
    pn_ordered_quantity  IN NUMBER )
  RETURN VARCHAR2
IS
  lc_flag VARCHAR2(100);
BEGIN
  IF pn_received_quantity >= pn_ordered_quantity THEN
    lc_flag               := 'Y';
  ELSE
    lc_flag := 'N';
  END IF;
  RETURN lc_flag;
EXCEPTION
WHEN OTHERS THEN
  RETURN NULL;
END is_lot_complete;
END XXSS_SUPP_PERFORM_PKG;
/
