DROP VIEW APPS.XX_BI_SALES_SHPD_ORDS;

/* Formatted on 6/6/2016 4:58:56 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_SALES_SHPD_ORDS
(
   ORDER_NUMBER,
   ORDER_TYPE,
   LINE_NUMBER,
   SHIPMENT_NUMBER,
   STATUS,
   ORDER_QUANTITY_UOM,
   ORDERED_QTY,
   INVOICE_QTY,
   FULFILLED_QTY,
   SHIPPED_QTY,
   CANCELLED_QTY,
   REQUEST_DATE,
   SCHEDULE_SHIP_DATE,
   DATE_ORDERED,
   PROMISED_DATE,
   FULFILLMENT_DATE,
   ACTUAL_SHIPMENT_DATE,
   UNIT_LIST_PRICE,
   UNIT_SELLING_PRICE,
   PRICING_QUANTITY,
   PRICING_QUANTITY_UOM,
   CUSTOMER_NUMBER,
   CUSTOMER,
   PRICE_LIST,
   SALES_PERSON,
   ORDERED_ITEM,
   SOURE_TYPE,
   FREIGHT_TERMS,
   BOOKED_FLAG,
   CANCELLED_FLAG,
   OPEN_FLAG,
   SHIPPABLE_FLAG,
   FULFILLED_FLAG,
   LINE_TYPE,
   ITEM_TYPE_CODE,
   LINE_CATEGORY_CODE,
   CUST_PO_NUMBER,
   FREIGHT_CARRIER_CODE,
   FOB_POINT_CODE,
   VISIBLE_DEMAND_FLAG,
   ORIG_SYS_DOCUMENT_REF,
   ORIG_SYS_LINE_REF,
   REFERENCE_TYPE,
   ITEM_REVISION,
   RE_SOURCE_FLAG,
   SHIPPED_INTERFACED_FLAG,
   LATEST_ACCEPTABLE_DATE,
   SCHEDULE_ARRIVAL_DATE,
   RETRUN_REASON_CODE,
   INVOICE_INTERFACE_STATUS_CODE,
   ITEM_IDENTIFIER_TYPE,
   SHIP_FROM_ORG_ID,
   ORGANIZATION_CODE,
   MINDATE,
   MAXDATE,
   DIVISION,
   PO_NUMBER,
   LINE,
   SHIPMENT_METHOD,
   SHIPMENT_PRIORITY,
   EXTENDED_PRICE,
   SHIP_TO_LOCATION
)
AS
     SELECT ooh.order_number "Order Number",
            ottt.NAME "Order type",
            ool.line_number "Line Number",
            ool.shipment_number "Shipment Number",
            ool.flow_status_code "status",
            ool.order_quantity_uom "Order Quantity UoM",
            ool.ordered_quantity "Ordered Qty",
            ool.invoiced_quantity "Invoiced Qty",
            ool.fulfilled_quantity "Fulfilled Qty",
            ool.shipped_quantity "Shipped Qty",
            ool.cancelled_quantity "Cancelled Qty",
            ool.request_date "Request Date",
            ool.schedule_ship_date "Schedule Ship Date",
            ooh.ordered_date "Date Ordered",
            ool.promise_date "Promised date",
            ool.fulfillment_date "Fulfillment date",
            ool.actual_shipment_date "Actual shipment date",
            ool.unit_list_price "Unit List Price",
            ool.unit_selling_price "Unit selling price",
            ool.pricing_quantity "Pricing Quantity",
            ool.pricing_quantity_uom "UOM",
            hzca.account_number "Customer Number",
            hp.party_name "Customer",
            qlh.NAME "Price List",
            jrs.NAME "Salesperson",
            ool.ordered_item "Ordered Item",
            ool.source_type_code "Source Type",
            ool.freight_terms_code "Freight Terms",
            ool.booked_flag "Booked Flag",
            ool.cancelled_flag "Cancelled Flag",
            ool.open_flag "Open Flag",
            ool.shippable_flag "Shippable Flag",
            ool.fulfilled_flag "Fulfilled Flag",
            ottt2.NAME "Line Type",
            ool.item_type_code "Item Type Code",
            ool.line_category_code "Line category code",
            ool.cust_po_number "Cust Po Number",
            ool.freight_carrier_code "Freight Carrier code",
            ool.fob_point_code "Fob Point code",
            ool.visible_demand_flag "Visible Demand Flag",
            ool.orig_sys_document_ref "Orig Sys Document Ref",
            ool.orig_sys_line_ref "Orig Sys Line ref",
            ool.reference_type "Reference Type",
            ool.item_revision "Item Revision",
            ool.re_source_flag "Re Source flag",
            ool.shipping_interfaced_flag "Shipped interfaced flag",
            ool.latest_acceptable_date "latest acceptable date",
            ool.schedule_arrival_date "schedule arrival date",
            ool.return_reason_code "Return reason Code",
            ool.invoice_interface_status_code "Invoice Interface status code",
            ool.item_identifier_type "Item Identifier Type",
            ool.ship_from_org_id "Ship from Org Id",
            ood.organization_code "Organization code",
            MIN (TRUNC (ool.actual_shipment_date)) mindate,
            MAX (TRUNC (ool.actual_shipment_date)) maxdate,
            (SELECT mcb.segment4
               FROM mtl_item_categories mic,
                    mtl_category_sets_tl mcst,
                    mtl_category_sets_b mcsb,
                    mtl_categories_b mcb
              WHERE     mcst.category_set_id = mcsb.category_set_id
                    AND mcst.LANGUAGE = USERENV ('LANG')
                    AND mic.category_set_id = mcsb.category_set_id
                    AND mic.category_id = mcb.category_id
                    AND mcst.category_set_name = 'Sales and Marketing'
                    AND mic.inventory_item_id = ool.inventory_item_id
                    AND mic.organization_id = ool.ship_from_org_id)
               division,
            ooh.cust_po_number "Cust PO number",
            (ool.line_number || '.' || ool.shipment_number) "Line",
            ooh.shipping_method_code "Shipping method code",
            ooh.shipment_priority_code "Shipment priority code",
            (ool.unit_selling_price * ool.pricing_quantity) "Extended Price",
            (   DECODE (hzcst.LOCATION, NULL, NULL, hzcst.LOCATION || ', ')
             || DECODE (hl.address1, NULL, NULL, hl.address1 || ', ')
             || DECODE (hl.city, NULL, NULL, hl.city || ', ')
             || DECODE (hl.state, NULL, hl.province || ', ', hl.state || ', ')
             || DECODE (hl.postal_code, NULL, NULL, hl.postal_code || ', ')
             || DECODE (hl.country, NULL, NULL, hl.country))
               "Ship to location"
       FROM apps.oe_order_headers_all ooh,
            apps.oe_order_lines_all ool,
            apps.oe_transaction_types_tl ottt,
            apps.hz_cust_accounts hzca,
            apps.hz_party_sites party_site,
            apps.hz_cust_acct_sites_all hzcs,
            apps.hz_cust_site_uses_all hzcst,
            apps.hz_parties hp,
            apps.qp_list_headers_tl qlh,
            apps.jtf_rs_salesreps jrs,
            apps.oe_transaction_types_tl ottt2,
            apps.org_organization_definitions ood,
            apps.hz_locations hl
      WHERE     ooh.header_id = ool.header_id
            AND ooh.order_type_id = ottt.transaction_type_id
            AND ottt.LANGUAGE = USERENV ('LANG')
            AND hzca.cust_account_id = hzcs.cust_account_id
            AND hzcs.cust_acct_site_id = hzcst.cust_acct_site_id
            AND hzcs.party_site_id = party_site.party_site_id
            AND hzcs.cust_acct_site_id = hzcst.cust_acct_site_id
            AND hp.party_id = hzca.party_id
            AND hzca.cust_account_id = ooh.sold_to_org_id
            --       AND hzcst.site_use_id = ooh.invoice_to_org_id
            --       AND hzcst.site_use_code = 'BILL_TO'
            AND hzcst.site_use_code = 'SHIP_TO'
            AND hzcst.site_use_id = ooh.ship_to_org_id
            AND qlh.list_header_id = ool.price_list_id
            AND qlh.LANGUAGE = USERENV ('LANG')
            AND jrs.salesrep_id = ool.salesrep_id
            AND jrs.status = 'A'
            AND ottt.LANGUAGE = ottt2.LANGUAGE
            AND ottt2.transaction_type_id = ool.line_type_id
            AND ool.ship_from_org_id = ood.organization_id
            AND hl.location_id(+) = party_site.location_id
   --and ooh.order_number=372699  --607120       --905292   --383602
   GROUP BY ooh.order_number,
            ottt.NAME,
            ool.line_number,
            ool.shipment_number,
            ool.flow_status_code,
            ool.order_quantity_uom,
            ool.ordered_quantity,
            ool.invoiced_quantity,
            ool.fulfilled_quantity,
            ool.shipped_quantity,
            ool.cancelled_quantity,
            ool.request_date,
            ool.schedule_ship_date,
            ooh.ordered_date,
            ool.promise_date,
            ool.fulfillment_date,
            ool.actual_shipment_date,
            ool.unit_list_price,
            ool.unit_selling_price,
            ool.pricing_quantity,
            ool.pricing_quantity_uom,
            hzca.account_number,
            hp.party_name,
            qlh.NAME,
            jrs.NAME,
            ool.ordered_item,
            ool.source_type_code,
            ool.freight_terms_code,
            ool.booked_flag,
            ool.cancelled_flag,
            ool.open_flag,
            ool.shippable_flag,
            ool.fulfilled_flag,
            ottt2.NAME,
            ool.item_type_code,
            ool.line_category_code,
            ool.cust_po_number,
            ool.freight_carrier_code,
            ool.fob_point_code,
            ool.visible_demand_flag,
            ool.orig_sys_document_ref,
            ool.orig_sys_line_ref,
            ool.reference_type,
            ool.item_revision,
            ool.re_source_flag,
            ool.shipping_interfaced_flag,
            ool.latest_acceptable_date,
            ool.schedule_arrival_date,
            ool.return_reason_code,
            ool.invoice_interface_status_code,
            ool.item_identifier_type,
            ool.ship_from_org_id,
            ood.organization_code,
            ool.inventory_item_id,
            ooh.cust_po_number,
            ooh.shipping_method_code,
            ooh.shipment_priority_code,
            hzcst.LOCATION,
            hl.address1,
            hl.address2,
            hl.address3,
            hl.address4,
            hl.city,
            hl.state,
            hl.province,
            hl.postal_code,
            hl.country;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_SALES_SHPD_ORDS FOR APPS.XX_BI_SALES_SHPD_ORDS;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_SALES_SHPD_ORDS FOR APPS.XX_BI_SALES_SHPD_ORDS;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_SALES_SHPD_ORDS FOR APPS.XX_BI_SALES_SHPD_ORDS;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_SALES_SHPD_ORDS FOR APPS.XX_BI_SALES_SHPD_ORDS;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_SHPD_ORDS TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_SHPD_ORDS TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_SHPD_ORDS TO XXINTG;
