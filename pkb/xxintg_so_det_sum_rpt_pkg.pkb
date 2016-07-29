DROP PACKAGE BODY APPS.XXINTG_SO_DET_SUM_RPT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.XXINTG_SO_DET_SUM_RPT_PKG
AS
  /******************************************************************************
  -- Filename:  XXINTG_SO_DET_SUM_RPT_PKG
  -- RICEW Object id : O2C-RPT_EXT_188
  -- Purpose :  Package Specification for Sales Order Det/Sum Report
  --
  -- Usage: Report ( Type PL/SQL Procedure)
  -- Caution:
  -- Copyright (c) IBM
  -- All rights reserved.
  -- Ver  Date         Author             Modification
  -- ---- -----------  ------------------ --------------------------------------
  -- 1.0  30-Oct-2014  Shiny George       Created
  -- 2.0  30-Jun-2015  Basha              Added bulk collect and for all statements in the code
  -- 3.0  11-Aug-2015  Prasanna/Raviteja  Modified for the update statement for Case# 4675, 4683
  -- 4.0  19-JAN-2016  Vinod Pillai       Modified an update statement to improve performace Case# 9030
  --                                      Added to_char to order number and line number in where clause
  --                                      so that index is used
  ******************************************************************************/
PROCEDURE XXINTG_SO_DET_SUM_RPT_PROC(
    errbuf OUT VARCHAR2,
    retcode OUT VARCHAR2,
    P_ORDER_TYPE_ID       IN VARCHAR2,
    P_CREATED_BY          IN VARCHAR2,
    P_DIVISION            IN VARCHAR2,
    P_SHIP_TO_CUSTOMER_ID IN NUMBER,
    P_STATE               IN VARCHAR2,
    P_COUNTRY             IN VARCHAR2,
    P_LINE_STATUS         IN VARCHAR2,
    P_FROM_ORDERED_DATE   IN DATE,
    P_TO_ORDERED_DATE     IN DATE )
IS
  l_trx_number ra_customer_trx_all.trx_number%TYPE;
  l_revenue_amount ra_customer_trx_lines_all.revenue_amount%TYPE;
  l_trx_date ra_customer_trx_all.trx_date%TYPE;
  L_CCODE XXOM_SALES_MARKETING_SET_V.PRODUCT_CLASS%TYPE;
  l_product_class fnd_flex_values_vl.description%TYPE;
  l_dcode xxom_sales_marketing_set_v.product_type%TYPE;
  l_product_type fnd_flex_values_vl.description%TYPE;
  l_delivery_detail_id wsh_delivery_details.delivery_detail_id%TYPE;
  l_released_status wsh_delivery_details.released_status%TYPE;
  l_oe_interfaced_flag wsh_delivery_details.oe_interfaced_flag%TYPE;
  l_inv_interfaced_flag wsh_delivery_details.inv_interfaced_flag%TYPE;
  l_shipped_quantity wsh_delivery_details.shipped_quantity%type;
  l_division xxom_sales_marketing_set_v.snm_division%TYPE;
  --l_salesrep              VARCHAR2(240);
  l_territory VARCHAR2(240);
  l_region    VARCHAR2(240);
  f_count     NUMBER;
  l_error     NUMBER :=0;
  /* mo global
  x_user_id          NUMBER       := fnd_global.user_id;
  x_resp_id          NUMBER       := fnd_global.resp_id;
  x_resp_appl_id     NUMBER       := fnd_global.resp_appl_id;
  x_org_id number := MO_GLOBAL.get_current_org_id;*/
TYPE XXINTG_SO_DET_SUM_TEMP_REC
IS
  RECORD
  (
    HEADER_ID OE_ORDER_HEADERS.HEADER_ID%TYPE,
    ORDER_NUMBER OE_ORDER_HEADERS.ORDER_NUMBER%TYPE,
    ORDERED_DATE OE_ORDER_HEADERS.ORDERED_DATE%TYPE,
    CREATED_BY FND_USER.USER_NAME%TYPE,
    ORDER_SOURCE OE_ORDER_SOURCES_115.NAME%TYPE,
    ORDER_STATUS OE_ORDER_HEADERS.FLOW_STATUS_CODE%TYPE,
    CUST_PO_NUMBER OE_ORDER_HEADERS.CUST_PO_NUMBER%TYPE,
    ORDER_TYPE OE_ORDER_TYPES_115_ALL.NAME%TYPE,
    HEADER_CONTEXT OE_ORDER_HEADERS.CONTEXT%TYPE,
    ORGANIZATION_CODE ORG_ORGANIZATION_DEFINITIONS.ORGANIZATION_CODE%TYPE,
    ORIG_SYS_DOC_REF OE_ORDER_HEADERS.ORIG_SYS_DOCUMENT_REF%TYPE ,
    CASE_NO OE_ORDER_HEADERS.ORIG_SYS_DOCUMENT_REF%TYPE ,
    DIV OE_ORDER_HEADERS.ORIG_SYS_DOCUMENT_REF%TYPE ,
    LINE_ID OE_ORDER_LINES.LINE_ID%TYPE,
    ORDERED_ITEM OE_ORDER_LINES.ORDERED_ITEM%TYPE,
    ORDERED_QUANTITY OE_ORDER_LINES.ORDERED_QUANTITY%TYPE,
    UNIT_SELLING_PRICE OE_ORDER_LINES.UNIT_SELLING_PRICE%TYPE,
    EXT_PRICE OE_ORDER_LINES.ORDERED_QUANTITY%TYPE,
    LINE_STATUS OE_ORDER_LINES.FLOW_STATUS_CODE%TYPE,
    ITEM_DESCRIPTION MTL_SYSTEM_ITEMS.DESCRIPTION%TYPE,
    INVENTORY_ITEM_ID OE_ORDER_LINES.INVENTORY_ITEM_ID%TYPE ,
    SHIP_FROM_ORG_ID OE_ORDER_LINES.SHIP_FROM_ORG_ID%TYPE,
    LINE_SUBINVENTORY OE_ORDER_LINES.SUBINVENTORY%TYPE,
    LINE_LPN OE_ORDER_LINES.ATTRIBUTE1%TYPE,
    LINE_LOT_NUMBER OE_ORDER_LINES.ATTRIBUTE2%TYPE,
    LOT_NUMBER MTL_RESERVATIONS.LOT_NUMBER%TYPE ,
    SERIAL_NUMBER MTL_RESERVATIONS.SERIAL_NUMBER%TYPE,
    SUBINVENTORY_CODE MTL_RESERVATIONS.SUBINVENTORY_CODE%TYPE,
    LOCATOR MTL_ITEM_LOCATIONS.DESCRIPTION%TYPE,
    SERIAL_RESERVATION_QUANTITY MTL_RESERVATIONS.SERIAL_RESERVATION_QUANTITY%TYPE,
    LICENSE_PLATE_NUMBER WMS_LICENSE_PLATE_NUMBERS.LICENSE_PLATE_NUMBER%TYPE,
    HEADER_HOLD_NAME VARCHAR2(2000),--OE_HOLD_DEFINITIONS.NAME%TYPE,
    LINE_HOLD_NAME   VARCHAR2(2000),--OE_HOLD_DEFINITIONS.NAME%TYPE,
    SOLD_TO_ORG_ID OE_ORDER_HEADERS.SOLD_TO_ORG_ID%TYPE,
    SOLD_TO_ACCOUNT_NUMBER HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE,
    SOLD_TO_ACCOUNT_NAME HZ_CUST_ACCOUNTS.ACCOUNT_NAME%TYPE,
    SOLD_TO_COUNTRY HZ_LOCATIONS.COUNTRY%TYPE,
    SOLD_TO_STATE HZ_LOCATIONS.STATE%TYPE,
    SHIP_TO_ACCOUNT_NUMBER HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE,
    SHIP_TO_ACCOUNT_NAME HZ_CUST_ACCOUNTS.ACCOUNT_NAME%TYPE,
    SHIP_TO_ADDRESS HZ_LOCATIONS.ADDRESS1%TYPE,
    SHIP_TO_CITY HZ_LOCATIONS.CITY%TYPE,
    SHIP_TO_STATE HZ_LOCATIONS.STATE%TYPE,
    POSTAL_CODE HZ_LOCATIONS.POSTAL_CODE%TYPE,
    COUNTRY HZ_LOCATIONS.COUNTRY%TYPE,
    PARTY_SITE_NUMBER HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE,
    SURGEON_NAME XXINTG_HCP_INT_MAIN.DOCTORS_LAST_NAME%TYPE,
    SURGERY_DATE OE_ORDER_HEADERS.ATTRIBUTE8%TYPE ,
    PATIENT_ID OE_ORDER_HEADERS.ATTRIBUTE13%TYPE ,
    TERRITORY OE_SALES_CREDITS.ATTRIBUTE1%TYPE,
    REGION OE_SALES_CREDITS.ATTRIBUTE1%TYPE,
    SALESREP JTF_RS_SALESREPS.NAME%TYPE,
    RECORD_NUMBER JTF_RS_SALESREPS.NAME%TYPE);
TYPE XXINTG_SO_DET_SUM_TEMP_T1
IS
  TABLE OF XXINTG_SO_DET_SUM_TEMP_REC;
  l_XXINTG_SO_DET XXINTG_SO_DET_SUM_TEMP_T1;
BEGIN
  --fnd_global.apps_initialize( x_user_id,x_resp_id,x_resp_appl_id);
  --fnd_request.set_org_id(x_org_id);
  fnd_file.put_line (fnd_file.LOG, '-------------------------');
  fnd_file.put_line (fnd_file.LOG, 'Program Execution Starts');
  fnd_file.put_line (fnd_file.LOG, 'Package Execution Start Time ' || TO_CHAR(sysdate,'dd-Mon-yyyy hh24:mi:ss'));
  fnd_file.put_line (fnd_file.LOG, '-------------------------');
  fnd_file.put_line (fnd_file.LOG, 'P_ORDER_TYPE_ID         : ' || P_ORDER_TYPE_ID);
  FND_FILE.PUT_LINE (FND_FILE.LOG, 'P_CREATED_BY            : ' || P_CREATED_BY);
  fnd_file.put_line (fnd_file.LOG, 'P_DIVISION              : ' || P_CREATED_BY);
  fnd_file.put_line (fnd_file.LOG, 'P_SHIP_TO_CUSTOMER_ID   : ' || P_SHIP_TO_CUSTOMER_ID);
  fnd_file.put_line (fnd_file.LOG, 'P_STATE                 : ' || P_STATE);
  fnd_file.put_line (fnd_file.LOG, 'P_COUNTRY               : ' || P_COUNTRY);
  fnd_file.put_line (fnd_file.LOG, 'P_LINE_STATUS           : ' || P_LINE_STATUS);
  IF (P_FROM_ORDERED_DATE IS NOT NULL) THEN
    fnd_file.put_line (fnd_file.LOG, 'P_FROM_ORDERED_DATE     : ' || P_FROM_ORDERED_DATE);
  END IF;
  IF (P_TO_ORDERED_DATE IS NOT NULL) THEN
    fnd_file.put_line (fnd_file.LOG, 'P_TO_ORDERED_DATE       : ' || P_TO_ORDERED_DATE);
  END IF;
  --fnd_file.put_line (fnd_file.LOG, 'P_DIVISION     : ' || P_DIVISION);
  --fnd_file.put_line (fnd_file.LOG, 'P_SALES_REP     : ' || P_SALES_REP);
  --fnd_file.put_line (fnd_file.LOG, 'P_TERRITORY      : ' || P_TERRITORY);
  --fnd_file.put_line (fnd_file.LOG, 'P_REGION        : ' || P_REGION);
  --fnd_file.put_line (fnd_file.LOG, 'P_C_CODES         : ' || P_C_CODES);
  --fnd_file.put_line (fnd_file.LOG, 'P_D_CODES    : ' || P_D_CODES);
  --fnd_file.put_line (fnd_file.LOG, 'P_HEADER_HOLD      : ' || P_HEADER_HOLD);
  --fnd_file.put_line (fnd_file.LOG, 'P_LINE_HOLD    : ' || P_LINE_HOLD);
  --fnd_file.put_line (fnd_file.LOG, 'P_RELEASE_STATUS     : ' || P_RELEASE_STATUS);
  --fnd_file.put_line (fnd_file.LOG, 'P_INVOICE_FROM_DATE     : ' || P_INVOICE_FROM_DATE);
  --fnd_file.put_line (fnd_file.LOG, 'P_INVOICE_TO_DATE     : ' || P_INVOICE_TO_DATE);
  /* Insert into temp table*/
  L_ERROR := 0;
  SELECT oeh.header_id,
    oeh.order_number,
    oeh.ordered_date,
    NVL (fu.user_name, oeh.created_by) created_by,
    oes.NAME ORDER_SOURCE,
    oeh.flow_status_code ORDER_STATUS,
    oeh.cust_po_number,
    oet.NAME ORDER_TYPE,
    oeh.CONTEXT HEADER_CONTEXT,
    org.organization_code,
    oeh.orig_sys_document_ref orig_sys_doc_ref,
    SUBSTR(oeh.orig_sys_document_ref,1,instr(oeh.orig_sys_document_ref,'-')-1) CASE_NO,
    SUBSTR(oeh.orig_sys_document_ref,9,1) DIV,
    OEL.LINE_ID,
--    OEL.ORDERED_ITEM
    NVL(
    (SELECT distinct MSI.SEGMENT1
    FROM MTL_SYSTEM_ITEMS msi,
      wsh_delivery_details WDD
    WHERE MSI.INVENTORY_ITEM_ID=WDD.INVENTORY_ITEM_ID
    AND MSI.ORGANIZATION_ID    =WDD.ORGANIZATION_ID
    AND wdd.source_line_id     =oel.line_id
    ),OEL.ORDERED_ITEM) ORDERED_ITEM,
    NVL(MR.RESERVATION_QUANTITY,OEL.ORDERED_QUANTITY) ORDERED_QUANTITY,
    oel.unit_selling_price,
    oel.ordered_quantity * oel.unit_selling_price ext_price,
    OEL.FLOW_STATUS_CODE LINE_STATUS,
--    msi.description ,
   NVL(
    (SELECT distinct MSI.DESCRIPTION
    FROM MTL_SYSTEM_ITEMS msi,
      WSH_DELIVERY_DETAILS WDD
    WHERE MSI.INVENTORY_ITEM_ID=WDD.INVENTORY_ITEM_ID
    AND MSI.ORGANIZATION_ID    =WDD.ORGANIZATION_ID
    AND wdd.source_line_id     =oel.line_id
    ),OEL.ORDERED_ITEM) description,
    oel.inventory_item_id,
    oel.ship_from_org_id,
    oel.subinventory ,
    oel.attribute1 ,
    oel.attribute2 ,
    mr.lot_number,
    mr.serial_number,
    mr.subinventory_code,
    MIL.DESCRIPTION LOCATOR,
    MR.SERIAL_RESERVATION_QUANTITY,
    LPN.LICENSE_PLATE_NUMBER,
    (SELECT LISTAGG(ohdh.NAME
      || ' ('
      || hhsh.hold_comment
      || ')', ', '
      ||CHR(10)) WITHIN GROUP (
    ORDER BY ohdh.NAME)
    FROM apps.oe_order_holds_all header_hold,
      apps.oe_hold_sources_all hhsh,
      apps.oe_hold_definitions ohdh
    WHERE header_hold.header_id (+)   = oeh.header_id
    AND header_hold.line_id (+)      IS NULL
    AND header_hold.released_flag (+) = 'N'
    AND hhsh.hold_source_id (+)       = header_hold.hold_source_id
    AND ohdh.hold_id (+)              = hhsh.hold_id
    ) HEADER_HOLD_NAME,
    (SELECT LISTAGG(ohdl.NAME
      || ' ('
      || hhsl.hold_comment
      || ')', ', '
      ||CHR(10)) WITHIN GROUP (
    ORDER BY ohdl.NAME)
    FROM apps.oe_order_holds_all line_hold,
      apps.oe_hold_sources_all hhsl,
      apps.oe_hold_definitions ohdl
    WHERE line_hold.header_id (+)   = oeh.header_id
    AND line_hold.line_id (+)       = oel.line_id
    AND line_hold.released_flag (+) = 'N'
    AND hhsl.hold_source_id (+)     = line_hold.hold_source_id
    AND ohdl.hold_id (+)            = hhsl.hold_id
    ) LINE_HOLD_NAME,
    oeh.sold_to_org_id,
    hcab.account_number SOLD_TO_ACCOUNT_NUMBER,
    hcab.account_name SOLD_TO_ACCOUNT_NAME,
    --hlb.address1 SOLD_TO_ADDRESS, hlb.city SOLD_TO_CITY, hlb.state SOLD_TO_STATE, hlb.postal_code SOLD_TO_POSTAL_CODE,
    hlb.country SOLD_TO_COUNTRY,
    hlb.state SOLD_TO_STATE,
    hcas.account_number SHIP_TO_ACCOUNT_NUMBER,
    hcas.account_name SHIP_TO_ACCOUNT_NAME,
    hls.address1 SHIP_TO_ADDRESS,
    hls.city SHIP_TO_CITY,
    hls.state SHIP_TO_STATE,
    hls.postal_code SHIP_TO_POSTAL_CODE,
    hls.country SHIP_TO_COUNTRY,
    hpss.party_site_number, --- Party_site_number ( CC # 012864 : 04Feb2015)
    NVL (
    (SELECT doctors_last_name
      || ', '
      || doctors_first_name
    FROM apps.xxintg_hcp_int_main
    WHERE TO_CHAR (REC_ID) = OEH.ATTRIBUTE8
    AND active_flag        ='Y'
    ), oeh.attribute8) surgeon_name,
    oeh.attribute7 surgery_date,
    oeh.attribute13,
    (SELECT LISTAGG(sc.attribute1 , ', ') WITHIN GROUP (
    ORDER BY sc.line_id)
    FROM oe_sales_credits sc
    WHERE sc.line_id = oel.line_id
    ),
    (SELECT LISTAGG(sc.attribute1 , ', ') WITHIN GROUP (
    ORDER BY sc.line_id)
    FROM oe_sales_credits sc
    WHERE sc.line_id = oel.line_id
    ),
    (SELECT LISTAGG(NVL(jtf.NAME, res.source_name) , ', ') WITHIN GROUP (
    ORDER BY sc.line_id)
    FROM apps.oe_sales_credits sc,
      apps.jtf_rs_resource_extns res,
      apps.jtf_rs_salesreps jtf
    WHERE sc.line_id    = oel.line_id
    AND sc.salesrep_id  = jtf.salesrep_id
    AND jtf.resource_id = res.resource_id
    ),
    xx_so_det_sum_temp_rec_seq.NEXTVAL bulk collect
  INTO l_XXINTG_SO_DET
  FROM oe_order_headers oeh,
    oe_order_lines oel,
    apps.mtl_system_items msi,
    apps.org_organization_definitions org,
    oe_order_types_115_all oet,
    apps.oe_order_sources_115 oes,
    apps.mtl_reservations mr,
    apps.mtl_item_locations mil,
    apps.wms_license_plate_numbers lpn,
    --Ship To/Bill To
    apps.hz_cust_site_uses_all ship_to,
    apps.hz_cust_acct_sites_all hcass,
    apps.hz_cust_accounts hcas,
    apps.hz_party_sites hpss,
    apps.hz_locations hls,
    apps.hz_cust_site_uses_all sold_to,
    apps.hz_cust_acct_sites_all hcasb,
    apps.hz_cust_accounts hcab,
    apps.hz_party_sites hpsb,
    apps.hz_locations hlb,
    fnd_user fu
  WHERE oeh.header_id   = oel.header_id
  AND oet.order_type_id = oeh.order_type_id
  AND OET.NAME          = NVL(P_ORDER_TYPE_ID,OET.NAME)
  AND( (SELECT NVL(snm_division,'RECON')
    FROM APPS.XXOM_SALES_MARKETING_SET_V
    WHERE ORGANIZATION_ID = OEL.SHIP_FROM_ORG_ID
    AND INVENTORY_ITEM_ID = OEL.INVENTORY_ITEM_ID ))=DECODE(upper(P_DIVISION),'ALL',
    (SELECT NVL(snm_division,'RECON')
    FROM APPS.XXOM_SALES_MARKETING_SET_V
    WHERE ORGANIZATION_ID = OEL.SHIP_FROM_ORG_ID
    AND INVENTORY_ITEM_ID = OEL.INVENTORY_ITEM_ID
    ),NULL,'RECON',upper(P_DIVISION))
  AND oel.inventory_item_id         = msi.inventory_item_id (+)
  AND oel.ship_from_org_id          = msi.organization_id (+)
  AND oel.ship_from_org_id          = org.organization_id (+)
  AND oes.order_source_id (+)       = oeh.order_source_id
  AND mr.demand_source_line_id (+)  = oel.line_id
  AND mil.inventory_location_id (+) = mr.locator_id
  AND lpn.lpn_id (+)                = mr.lpn_id
    --Ship To/Bill To
  AND ship_to.site_use_id         = oel.ship_to_org_id
  AND hcass.cust_acct_site_id     = ship_to.cust_acct_site_id
  AND hcas.cust_account_id        = hcass.cust_account_id
  AND hcas.cust_account_id        = NVL(P_SHIP_TO_CUSTOMER_ID,hcas.cust_account_id )
  AND oel.flow_status_code        = NVL(P_LINE_STATUS,oel.flow_status_code)
  AND hcass.party_site_id         = hpss.party_site_id
  AND hpss.location_id            = hls.location_id
  AND sold_to.site_use_id (+)     = oeh.invoice_to_org_id
  AND hcasb.cust_acct_site_id (+) = sold_to.cust_acct_site_id
  AND hcab.cust_account_id (+)    = hcasb.cust_account_id
  AND hcasb.party_site_id         = hpsb.party_site_id (+)
  AND hpsb.location_id            = hlb.location_id (+)
  AND NVL(hls.state,'XYZ')        = NVL(P_STATE,NVL(hls.state,'XYZ'))
  AND NVL(hls.country,'XYZ')      = NVL(P_COUNTRY,NVL(hls.country,'XYZ'))
  AND oeh.created_by              = fu.user_id
  AND fu.user_id                  = NVL(
    (SELECT user_id FROM fnd_user WHERE user_name = P_CREATED_BY
    ),fu.user_id)
  AND ((P_FROM_ORDERED_DATE IS NULL) OR (TRUNC(oeh.ordered_date) >= TRUNC(P_FROM_ORDERED_DATE))) --9030
  AND ((P_TO_ORDERED_DATE IS NULL) OR (TRUNC(oeh.ordered_date) <= TRUNC(P_TO_ORDERED_DATE))) ; --9030
  FORALL i                                 IN 1..l_XXINTG_SO_DET.count
  INSERT
  INTO XXINTG_SO_DET_SUM_TEMP_TBL
    (
      header_id ,
      order_number ,
      ordered_date ,
      created_by ,
      order_source ,
      order_status ,
      cust_po_number ,
      order_type ,
      header_context ,
      organization_code,
      orig_sys_doc_ref ,
      case_no ,
      div ,
      line_id ,
      ordered_item ,
      ordered_quantity ,
      unit_selling_price ,
      ext_price ,
      line_status ,
      item_description,
      inventory_item_id ,
      ship_from_org_id,
      line_subinventory,
      line_lpn,
      line_lot_number,
      lot_number ,
      serial_number ,
      subinventory_code ,
      LOCATOR ,
      serial_reservation_quantity ,
      LICENSE_PLATE_NUMBER ,
      header_hold_name ,
      line_hold_name ,
      sold_to_org_id ,
      sold_to_account_number ,
      sold_to_account_name ,
      sold_to_country ,
      sold_to_state ,
      ship_to_account_number ,
      ship_to_account_name ,
      ship_to_address ,
      ship_to_city ,
      ship_to_state ,
      postal_code ,
      country ,
      party_site_number ,
      surgeon_name ,
      surgery_date,
      patient_id,
      territory,
      region,
      salesrep,
      record_number
    )
    VALUES
    (
      L_XXINTG_SO_DET(I).HEADER_ID,
      L_XXINTG_SO_DET(I).ORDER_NUMBER ,
      L_XXINTG_SO_DET(I).ORDERED_DATE ,
      L_XXINTG_SO_DET(I).CREATED_BY ,
      L_XXINTG_SO_DET(I).order_source ,
      L_XXINTG_SO_DET(I).ORDER_STATUS ,
      L_XXINTG_SO_DET(I).CUST_PO_NUMBER ,
      L_XXINTG_SO_DET(I).ORDER_TYPE ,
      L_XXINTG_SO_DET(I).header_context ,
      L_XXINTG_SO_DET(I).ORGANIZATION_CODE,
      L_XXINTG_SO_DET(I).orig_sys_doc_ref ,
      L_XXINTG_SO_DET(I).CASE_NO ,
      L_XXINTG_SO_DET(I).DIV ,
      L_XXINTG_SO_DET(I).LINE_ID ,
      L_XXINTG_SO_DET(I).ORDERED_ITEM ,
      L_XXINTG_SO_DET(I).ORDERED_QUANTITY ,
      L_XXINTG_SO_DET(I).unit_selling_price ,
      L_XXINTG_SO_DET(I).EXT_PRICE ,
      L_XXINTG_SO_DET(I).LINE_STATUS ,
      L_XXINTG_SO_DET(I).item_description,
      L_XXINTG_SO_DET(I).INVENTORY_ITEM_ID ,
      L_XXINTG_SO_DET(I).SHIP_FROM_ORG_ID,
      L_XXINTG_SO_DET(I).LINE_SUBINVENTORY,
      L_XXINTG_SO_DET(I).LINE_LPN,
      L_XXINTG_SO_DET(I).line_lot_number,
      L_XXINTG_SO_DET(I).LOT_NUMBER ,
      L_XXINTG_SO_DET(I).SERIAL_NUMBER ,
      L_XXINTG_SO_DET(I).SUBINVENTORY_CODE ,
      L_XXINTG_SO_DET(I).LOCATOR ,
      L_XXINTG_SO_DET(I).SERIAL_RESERVATION_QUANTITY ,
      L_XXINTG_SO_DET(I).LICENSE_PLATE_NUMBER ,
      L_XXINTG_SO_DET(I).HEADER_HOLD_NAME,
      L_XXINTG_SO_DET(I).LINE_HOLD_NAME ,
      L_XXINTG_SO_DET(I).SOLD_TO_ORG_ID ,
      L_XXINTG_SO_DET(I).SOLD_TO_ACCOUNT_NUMBER ,
      L_XXINTG_SO_DET(I).sold_to_account_name ,
      L_XXINTG_SO_DET(I).SOLD_TO_COUNTRY ,
      L_XXINTG_SO_DET(I).SOLD_TO_STATE ,
      L_XXINTG_SO_DET(I).SHIP_TO_ACCOUNT_NUMBER ,
      L_XXINTG_SO_DET(I).ship_to_account_name ,
      L_XXINTG_SO_DET(I).SHIP_TO_ADDRESS ,
      L_XXINTG_SO_DET(I).SHIP_TO_CITY ,
      L_XXINTG_SO_DET(I).SHIP_TO_STATE ,
      L_XXINTG_SO_DET(I).POSTAL_CODE ,
      L_XXINTG_SO_DET(I).COUNTRY ,
      L_XXINTG_SO_DET(I).PARTY_SITE_NUMBER ,
      L_XXINTG_SO_DET(I).SURGEON_NAME ,
      L_XXINTG_SO_DET(I).SURGERY_DATE,
      L_XXINTG_SO_DET(I).PATIENT_ID,
      L_XXINTG_SO_DET(I).TERRITORY,
      L_XXINTG_SO_DET(I).REGION,
      L_XXINTG_SO_DET(I).SALESREP,
      L_XXINTG_SO_DET(I).RECORD_NUMBER
    );
  SELECT COUNT(*) INTO f_count FROM xxintg_so_det_sum_temp_tbl;
  fnd_file.put_line (fnd_file.LOG, 'No of rows - '||f_count);
  l_error := 1;
  /* Insert End*/
  -- Update Invoice Details
  FND_FILE.PUT_LINE (FND_FILE.LOG, 'Insert Complete: ' || SQLERRM|| TO_CHAR(sysdate,'dd-Mon-yyyy hh24:mi:ss'));
  /*merge INTO xxintg_so_det_sum_temp_tbl temp USING
  (SELECT trxl.interface_line_attribute1,
  trxl.interface_line_attribute6,
  trx.trx_number ,
  trxl.revenue_amount ,
  trx.trx_date
  FROM apps.ra_customer_trx_lines_all trxl,
  apps.ra_customer_trx_all trx
  --apps.xxintg_so_det_sum_temp_tbl temp
  WHERE 1                  =1
  AND trxl.customer_trx_id = trx.customer_trx_id
  --and trxl.interface_line_attribute1 = temp.order_number
  AND trxl.interface_line_context = 'ORDER ENTRY'
  --and trxl.interface_line_attribute6 = temp.line_id
  ) rec ON (temp.order_number = rec.interface_line_attribute1 AND temp.line_id = rec.interface_line_attribute6 )
  WHEN matched THEN
  UPDATE
  SET temp.invoice_number = rec.trx_number ,
  temp.invoice_amount   = rec.revenue_amount ,
  temp.invoice_date     = rec.trx_date;*/
  UPDATE XXINTG_SO_DET_SUM_TEMP_TBL TEMP
  SET
    (
      INVOICE_NUMBER,
      INVOICE_AMOUNT,
      invoice_date
    )
    =
    (SELECT trx.trx_number ,
      trxl.revenue_amount ,
      trx.trx_date
    FROM apps.ra_customer_trx_lines_all trxl,
      apps.ra_customer_trx_all trx
      --apps.xxintg_so_det_sum_temp_tbl temp
    WHERE 1                            =1
    AND trxl.customer_trx_id           = trx.customer_trx_id
    AND TRXL.INTERFACE_LINE_CONTEXT    = 'ORDER ENTRY'
    AND trxl.interface_line_attribute1 = TO_CHAR(temp.order_number) --9030
    AND TRXL.INTERFACE_LINE_ATTRIBUTE6 = TO_CHAR(TEMP.LINE_ID)
    --AND trxl.interface_line_attribute1 = temp.order_number
    --AND TRXL.INTERFACE_LINE_ATTRIBUTE6 = TEMP.LINE_ID
    AND TRX.CREATION_DATE              =
      (SELECT MAX(trx.creation_date)
      FROM RA_CUSTOMER_TRX_LINES_ALL TRXL,
        RA_CUSTOMER_TRX_ALL TRX
      WHERE TRXL.CUSTOMER_TRX_ID        = TRX.CUSTOMER_TRX_ID
      AND TRXL.ORG_ID                   =TRX.ORG_ID
      AND TRXL.INTERFACE_LINE_CONTEXT   = 'ORDER ENTRY'
      AND TRXL.INTERFACE_LINE_ATTRIBUTE1=TO_CHAR(TEMP.ORDER_NUMBER) --9030
      AND TRXL.INTERFACE_LINE_ATTRIBUTE6=TO_CHAR(temp.line_id)
      --AND TRXL.INTERFACE_LINE_ATTRIBUTE1=TEMP.ORDER_NUMBER
      --AND TRXL.INTERFACE_LINE_ATTRIBUTE6=temp.line_id
      )
    );
  l_error :=2;
  --fnd_file.put_line (fnd_file.LOG,sqlcode|| ' 1st Update Complete: ' || SQLERRM);
  FND_FILE.PUT_LINE (FND_FILE.LOG, 'Update 1 Complete: ' || SQLERRM|| TO_CHAR(sysdate,'dd-Mon-yyyy hh24:mi:ss'));
  -- Update ccode, dcode, and division
  UPDATE xxintg_so_det_sum_temp_tbl temp
  SET
    (
      ccode,
      dcode,
      division
    )
    =
    (SELECT product_class,
      product_type,
      snm_division
    FROM apps.xxom_sales_marketing_set_v
    WHERE organization_id = temp.ship_from_org_id
    AND inventory_item_id = temp.inventory_item_id
    );
  l_error:=3;
  --fnd_file.put_line (fnd_file.LOG, '2st Update Complete: ' || SQLERRM);
  FND_FILE.PUT_LINE (FND_FILE.LOG, 'Update 2 Complete: ' || SQLERRM|| TO_CHAR(sysdate,'dd-Mon-yyyy hh24:mi:ss'));
  -- update delivery details
  UPDATE xxintg_so_det_sum_temp_tbl temp
  SET
    (
      delivery_detail_id,
      released_status,
      oe_interfaced_flag,
      inv_interfaced_flag,
      line_number
    )
    =
    (SELECT wdd.delivery_detail_id,
      wdd.released_status,
      wdd.oe_interfaced_flag,
      wdd.inv_interfaced_flag,
      wdd.source_line_number
    FROM apps.wsh_delivery_details wdd
    WHERE wdd.source_line_id = temp.line_id
    AND ROWNUM               = 1
    );
  l_error:=4;
  FND_FILE.PUT_LINE (FND_FILE.LOG, 'Update 3 Complete: ' || SQLERRM|| TO_CHAR(sysdate,'dd-Mon-yyyy hh24:mi:ss'));
  -- update line numbers for SOs
  UPDATE xxintg_so_det_sum_temp_tbl temp
  SET line_number =
    (SELECT ol.line_number
    FROM apps.oe_order_lines_all ol
    WHERE ol.line_id = temp.line_id
    )
  WHERE temp.line_number IS NULL;
  l_error                :=5;
  FND_FILE.PUT_LINE (FND_FILE.LOG, 'Update 4 Complete: ' || SQLERRM|| TO_CHAR(sysdate,'dd-Mon-yyyy hh24:mi:ss'));
  -- update product type and class
  UPDATE xxintg_so_det_sum_temp_tbl temp
  SET product_class =
    (SELECT DISTINCT v.description
    FROM fnd_flex_value_sets vs,
      fnd_flex_values_vl v
    WHERE vs.flex_value_set_name = 'INTG_PRODUCT_CLASS'
    AND vs.flex_value_set_id     = v.flex_value_set_id
    AND v.flex_value             = temp.ccode
    );
  l_error:=6;
  FND_FILE.PUT_LINE (FND_FILE.LOG, 'Update 5 Complete: ' || SQLERRM|| TO_CHAR(sysdate,'dd-Mon-yyyy hh24:mi:ss'));
  UPDATE xxintg_so_det_sum_temp_tbl temp
  SET product_type =
    (SELECT v.description
    FROM fnd_flex_value_sets vs,
      fnd_flex_values_vl v
    WHERE vs.flex_value_set_name = 'INTG_PRODUCT_TYPE'
    AND vs.flex_value_set_id     = v.flex_value_set_id
    AND v.flex_value             = temp.dcode
    AND v.parent_flex_value_low  = temp.division
    );
  l_error:=7;
  FND_FILE.PUT_LINE (FND_FILE.LOG, 'Update 6 Complete: ' || SQLERRM|| TO_CHAR(sysdate,'dd-Mon-yyyy hh24:mi:ss'));
  /*-- Update the SalesRep depending on the line status
  UPDATE xxintg_so_det_sum_temp_tbl temp
  SET salesrep = decode (  temp.line_status,'ENTERED',
  (SELECT LISTAGG(jtf.NAME , ', ') WITHIN GROUP (ORDER BY sc.line_id)
  FROM oe_sales_credits sc,jtf_rs_salesreps jtf
  WHERE sc.line_id = temp.line_id
  AND sc.salesrep_id = jtf.salesrep_id ),
  (SELECT LISTAGG(NVL(sr.NAME, res.source_name),', ') WITHIN GROUP (ORDER BY oel.line_id )
  FROM jtf_rs_salesreps sr,jtf_rs_resource_extns res,oe_order_lines_all oel,oe_order_headers_all oeh
  WHERE sr.salesrep_id = oeh.salesrep_id
  AND oeh.header_id = oel.header_id
  AND oel.header_id = temp.header_id
  and oel.line_id  = temp.line_id
  AND sr.resource_id = res.resource_id ));
  -- Update the SalesRep depending on the line status
  UPDATE xxintg_so_det_sum_temp_tbl temp
  SET salesrep = decode (  temp.line_status,'ENTERED',
  (SELECT LISTAGG(jtf.NAME , ', ') WITHIN GROUP (ORDER BY sc.line_id)
  FROM oe_sales_credits sc,jtf_rs_salesreps jtf
  WHERE sc.line_id = temp.line_id
  AND sc.salesrep_id = jtf.salesrep_id ),
  (SELECT LISTAGG(NVL(sr.NAME, res.source_name),', ') WITHIN GROUP (ORDER BY oel.line_id )
  FROM jtf_rs_salesreps sr,jtf_rs_resource_extns res,oe_order_lines_all oel
  WHERE sr.salesrep_id = oel.salesrep_id
  AND oel.header_id = temp.header_id
  AND oel.line_id  = temp.line_id
  AND sr.resource_id = res.resource_id ));
  -- Update the SalesRep depending on the line status
  UPDATE xxintg_so_det_sum_temp_tbl temp
  SET salesrep = (SELECT LISTAGG(jtf.NAME , ', ') WITHIN GROUP (ORDER BY sc.line_id)
  FROM oe_sales_credits sc,jtf_rs_salesreps jtf
  WHERE sc.line_id = temp.line_id
  AND sc.salesrep_id = jtf.salesrep_id );
  l_error:=8; */
  fnd_file.put_line (fnd_file.LOG, '-------------------------');
  fnd_file.put_line (fnd_file.LOG, 'Program Execution Completed');
  fnd_file.put_line (fnd_file.LOG, 'Package Execution End Time ' || TO_CHAR(sysdate,'dd-Mon-yyyy hh24:mi:ss'));
  FND_FILE.PUT_LINE (FND_FILE.LOG, '-------------------------');
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG, 'Package XXINTG_SO_DET_SUM_RPT_PKG in Error. Error after call(l_error): ' || l_error );
  fnd_file.put_line (fnd_file.LOG, SQLERRM);
END XXINTG_SO_DET_SUM_RPT_PROC;
END XXINTG_SO_DET_SUM_RPT_PKG;

/
