DROP VIEW APPS.XX_BI_OE_OSP_MDE_PROD_V;

/* Formatted on 6/6/2016 4:59:17 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_OE_OSP_MDE_PROD_V
(
   ITEM_NO,
   VENDOR_NAME,
   VENDOR_NUM,
   INVOICE_NUM,
   PO_NUM,
   PO_DATE,
   AMOUNT,
   QUANTITY_INVOICED,
   ACCOUNTING_DATE,
   ITEM_COMP_COST,
   ITEM_FREIGHT_COST,
   TOTAL_COST,
   USD,
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
   SELECT msii.segment1 itemno,
          aps.vendor_name,
          aps.segment1 vendor_nr,
          aia.invoice_num,
          pha.segment1 po_nr,
          pha.creation_date po_date,
          aila.amount,
          aila.quantity_invoiced,
          aila.accounting_date,
          --(aila.amount / NVL (aila.quantity_invoiced, 1))
          --(NVL2 (aila.quantity_invoiced, 1, 1) / aila.amount) UNIT_SERVICE_COST,
          cicd.usage_rate_or_amount item_comp_cost,
          cicdovd.usage_rate_or_amount item_freight_cost,
          /* we.wip_entity_name, */
          (  aila.amount
           + (cicd.usage_rate_or_amount * quantity_invoiced)
           + (cicdovd.usage_rate_or_amount * quantity_invoiced))
             total_cost,
          'USD',
          msii.attribute25 vendor_est,
          msii.attribute23 vendor_mdl,
          msii.attribute9 coo,
          msii.attribute13 hts,
          ffvv.description,
          msii.attribute21 fda_code,
          msii.attribute20 ils_510k,
          qr.character1 weekno,
          qr.plan_id
     FROM apps.ap_invoice_lines_all aila,
          apps.mtl_system_items msi,
          apps.ap_invoices_all aia,
          apps.ap_suppliers aps,
          apps.po_headers_all pha,
          apps.po_distributions_all pda,
          apps.wip_entities we,
          apps.mtl_system_items msii,
          apps.fnd_flex_values_vl ffvv,
          apps.cst_item_cost_details cicd,
          apps.cst_item_cost_details cicdovd,
          apps.qa_results qr
    WHERE     aia.vendor_id = aps.vendor_id
          AND pha.po_header_id = aila.po_header_id
          AND msii.inventory_item_id = cicd.inventory_item_id(+)
          AND cicd.inventory_item_id = cicdovd.inventory_item_id(+)
          AND cicd.cost_element_id(+) = 1
          AND cicdovd.cost_element_id(+) = 2
          AND msi.organization_id = 2098
          AND cicd.cost_type_id(+) = 1202
          AND cicdovd.cost_type_id(+) = 1202
          AND cicd.organization_id(+) = 2098
          AND cicdovd.organization_id(+) = 2098
          AND msii.organization_id = 83
          AND cicd.inventory_item_id = cicdovd.inventory_item_id(+)
          AND msii.inventory_item_id = we.primary_item_id
          AND aila.line_type_lookup_code = 'ITEM'
          AND aila.inventory_item_id = msi.inventory_item_id
          AND ffvv.flex_value_set_id = 1015140
          AND msii.attribute21 = ffvv.flex_value
          AND we.wip_entity_id = pda.wip_entity_id
          AND pda.po_distribution_id = aila.po_distribution_id
          AND aila.invoice_id = aia.invoice_id
          AND aps.vendor_id IN (89102, 76062)
          AND aila.invoice_id IN
                 (SELECT DISTINCT aia.invoice_id
                    FROM apps.ap_invoices_all aia
                   WHERE     aia.invoice_num = qr.character4
                         AND qr.plan_id = 38109);


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_OE_OSP_MDE_PROD_V FOR APPS.XX_BI_OE_OSP_MDE_PROD_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_OE_OSP_MDE_PROD_V TO ETLEBSUSER;
