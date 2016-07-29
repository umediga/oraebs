DROP VIEW APPS.XX_BI_OE_DRT_PROD_V;

/* Formatted on 6/6/2016 4:59:23 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_OE_DRT_PROD_V
(
   ITEM_NO,
   VENDOR_NAME,
   VENDOR_NUM,
   INVOICE_NUM,
   PURCAHSE_ORDER,
   PO_DATE,
   QUANTITY_INVOICED,
   INV_DATE,
   AMOUNT,
   CURRENCY,
   VENDOR_EST,
   VENDOR_MDL,
   COO,
   HTS,
   DESCRIPTION,
   FDA_CODE,
   ILS_510K,
   WEEKNO,
   PLAN_ID
)
AS
     SELECT msi.segment1 itemno,
            aps.vendor_name,
            aps.segment1 vendor_num,
            aia.invoice_num,
            pha.segment1 purchase_order,
            pha.creation_date po_date,
            aila.quantity_invoiced,
            aila.accounting_date inv_date,
            aila.amount,
            aia.invoice_currency_code currency,
            msi.attribute25 vendor_est,
            msi.attribute23 vendor_mdl,
            msi.attribute9 coo,
            msi.attribute13 hts,
            ffvv.description,
            msi.attribute21 fda_code,
            msi.attribute20 ils_510k,
            qr.character1 weekno,
            qr.plan_id
       FROM apps.ap_invoice_lines_all aila,
            apps.mtl_system_items msi,
            apps.ap_invoices_all aia,
            apps.ap_suppliers aps,
            apps.po_headers_all pha,
            apps.fnd_flex_values_vl ffvv,
            apps.rcv_shipment_lines rsl,
            apps.rcv_shipment_headers rsh,
            apps.qa_results qr
      WHERE     aila.line_type_lookup_code = 'ITEM'
            AND aia.org_id = 82
            AND aia.vendor_id = aps.vendor_id
            AND aia.invoice_type_lookup_code = 'STANDARD'
            AND pha.po_header_id = aila.po_header_id
            AND aila.inventory_item_id = msi.inventory_item_id(+)
            AND msi.organization_id(+) = 83
            AND msi.outside_operation_flag <> 'Y'
            AND aila.invoice_id = aia.invoice_id
            AND ffvv.flex_value_set_id(+) = 1015140
            AND msi.attribute21 = ffvv.flex_value(+)
            AND aila.rcv_shipment_line_id = rsl.shipment_line_id
            AND rsl.shipment_header_id = rsh.shipment_header_id
            AND rsh.receipt_source_code = 'VENDOR'
            AND aila.po_header_id = rsl.po_header_id
            AND rsh.receipt_num = qr.character2
            AND qr.plan_id = 38109
   --and rsh.receipt_num  in (select character2
   --from apps.qa_results
   --where plan_id = 38109)*/
   ORDER BY invoice_num;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_OE_DRT_PROD_V FOR APPS.XX_BI_OE_DRT_PROD_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_OE_DRT_PROD_V TO ETLEBSUSER;
