DROP PACKAGE BODY APPS.XX_BI_SHIP_REP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_BI_SHIP_REP_PKG" 
AS
FUNCTION get_total_by_delvery(p_src_hdr_num VARCHAR2,p_delivery_id NUMBER)
return NUMBER
IS
x_total        NUMBER:= 0;

CURSOR C_DEL_NUM(p_src_hdr_num VARCHAR2,p_delivery_id NUMBER) IS
  SELECT   SUM( (wd.SHIPPED_QUANTITY * ool.UNIT_SELLING_PRICE)) total_by_delvery
   FROM WSH_DELIVERABLES_V wd,
     OE_ORDER_HEADERS_ALL ooh,
     OE_ORDER_LINES_ALL   ool,
     ORG_ORGANIZATION_DEFINITIONS ood,
     MTL_SYSTEM_ITEMS_B  msi,
     WSH_DELIVERABLE_STOPS_V ws,
     WSH_DLVB_DLVY_V         wv,
     HZ_CUST_ACCOUNTS        hca,
     HZ_PARTIES              hp,
     HZ_LOCATIONS            hl,
     WSH_CARRIERS_V          wcv,
     OE_TRANSACTION_TYPES_TL ot

WHERE wd.SOURCE_HEADER_ID = ooh.HEADER_ID
  AND wd.SOURCE_HEADER_NUMBER = ooh.ORDER_NUMBER
  AND wd.RELEASED_STATUS_NAME = 'Shipped'
  AND ooh.HEADER_ID = ool.HEADER_ID
  AND ool.LINE_ID =  wd.SOURCE_LINE_ID
  AND ood.ORGANIZATION_ID = ool.SHIP_FROM_ORG_ID
  AND msi.ORGANIZATION_ID = ood.ORGANIZATION_ID
  AND msi.INVENTORY_ITEM_ID = wd.INVENTORY_ITEM_ID
  AND ws.DELIVERY_DETAIL_ID = wd.DELIVERY_DETAIL_ID
  AND ws.ACTIVITY_CODE = 'DO'
  AND wv.DELIVERY_ID   = wd.DELIVERY_ID
  AND wv.DELIVERY_DETAIL_ID = wd.DELIVERY_DETAIL_ID
  AND hca.cust_account_id = wd.CUSTOMER_ID
  AND hp.PARTY_ID = hca.PARTY_ID
  AND hl.LOCATION_ID = wd.SHIP_TO_LOCATION_ID
  AND wcv.CARRIER_ID = wd.CARRIER_ID
  AND ot.TRANSACTION_TYPE_ID = ooh.ORDER_TYPE_ID
  AND ot.LANGUAGE = 'US'
  AND wd.source_header_number = p_src_hdr_num
  AND wd.delivery_id = p_delivery_id;
BEGIN
   open C_DEL_NUM(p_src_hdr_num,p_delivery_id);
   fetch C_DEL_NUM into x_total;
   close C_DEL_NUM;
   return x_total;
EXCEPTION
  WHEN OTHERS THEN
     return 0;
END;

FUNCTION get_release_date(p_move_ord_line_id NUMBER,p_source_line_id NUMBER)
return DATE
 IS

 x_date DATE := NULL;

BEGIN
 begin
 select creation_date into x_date
    from MTL_TXN_REQUEST_LINES_V
     where line_id = p_move_ord_line_id;
 exception
  when others then
    x_date := NULL;
 end;
 IF x_date is not NULL then
    return x_date;
 ELSE
   begin
     select max(creation_date) into x_date
       from MTL_MATERIAL_TRANSACTIONS
       where trx_source_line_id = p_source_line_id
         AND transaction_type_id = 52       -- Sales Order Pick
         AND transaction_source_type_id = 2; -- sales order
   exception
     when others then
     x_date := NULL;
  end;
 END IF;
 return x_date;
END;

FUNCTION get_invoice_no(p_src_header_number VARCHAR2, p_org_id NUMBER)
return VARCHAR2
IS
v_trx_number VARCHAR2(100):= NULL;
BEGIN
 Select trx_number into v_trx_number
   from RA_CUSTOMER_TRX_ALL rct
   WHERE rct.interface_header_attribute1 = p_src_header_number
         AND rct.org_id = p_org_id;

   RETURN  v_trx_number;

EXCEPTION
    when others then
     v_trx_number := NULL;
     RETURN  v_trx_number;
END;

FUNCTION get_revenue_cost(p_line_id NUMBER)
return NUMBER
IS
v_rev_cost  NUMBER:= NULL;
BEGIN
 Select mta.base_transaction_value into v_rev_cost
   from MTL_MATERIAL_TRANSACTIONS mmt,
        MTL_TRANSACTION_ACCOUNTS  mta
        --CST_INV_DISTRIBUTION_V    cid
   WHERE mmt.source_line_id = p_line_id
       AND mmt.transaction_type_id = 33 -- Sales order issue
       AND mmt.transaction_source_type_id = 2 -- sales order
       AND mta.transaction_id = mmt.transaction_id
       AND mta.accounting_line_type = 36;
       --AND cid.line_type_name = 'Deferred Cost of Goods Sold';

   RETURN  v_rev_cost;

EXCEPTION
    when others then
     v_rev_cost := NULL;
     RETURN  v_rev_cost;
END;

FUNCTION get_freight_cost(p_delevery_id NUMBER)
return NUMBER
IS
v_freight_amt NUMBER := NULL;
BEGIN
  Select total_amount into v_freight_amt
    from WSH_FREIGHT_COSTS
     where delivery_id = p_delevery_id;

     RETURN  v_freight_amt;
EXCEPTION
    when others then
     v_freight_amt := NULL;
     RETURN  v_freight_amt;
END;

FUNCTION get_ship_date(p_delivery_det_id NUMBER)
return DATE
IS
x_ship_date DATE := NULL;
BEGIN
  SELECT wds.actual_departure_date INTO x_ship_date
    FROM WSH_DELIVERABLE_STOPS_V  wds
   WHERE wds.delivery_detail_id = p_delivery_det_id
     AND wds.stop_sequence_number = (select MIN(wds1.stop_sequence_number) from WSH_DELIVERABLE_STOPS_V  wds1
                                      WHERE wds1.delivery_detail_id = p_delivery_det_id);

     RETURN  x_ship_date;
EXCEPTION
    when others then
     x_ship_date := NULL;
     RETURN  x_ship_date;
END;
END XX_BI_SHIP_REP_PKG;
/
