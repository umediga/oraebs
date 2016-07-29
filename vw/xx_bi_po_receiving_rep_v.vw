DROP VIEW APPS.XX_BI_PO_RECEIVING_REP_V;

/* Formatted on 6/6/2016 4:59:03 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_PO_RECEIVING_REP_V
(
   OPERATING_UNIT,
   INVENTORY_ORGANIZATION_CODE,
   INVENTORY_ORGANIZATION,
   DIVISION,
   PERIOD,
   PO_NUMBER,
   RECEIPT_NUMBER,
   RECEIVER_NAME,
   RECEIPT_DATE,
   ITEM_NUMBER,
   DESCRIPTION,
   CATEGORY,
   ORDERED_QTY,
   UOM,
   RECEIVED_QTY,
   LOT_NUMBER,
   QTY,
   LOT_EXPIRATION_DATE
)
AS
   SELECT hou.name,
          ood.organization_code,
          ood.ORGANIZATION_NAME,
          (SELECT mcb.segment4
             FROM mtl_item_categories mic,
                  mtl_category_sets_tl mcst,
                  mtl_category_sets_b mcsb,
                  mtl_categories_b mcb
            WHERE     mcst.category_set_id = mcsb.category_set_id
                  AND mcst.language = USERENV ('LANG')
                  AND mic.category_set_id = mcsb.category_set_id
                  AND mic.category_id = mcb.category_id
                  AND mcst.category_set_name = 'Sales and Marketing'
                  AND mic.inventory_item_id = msib.inventory_item_id
                  AND mic.organization_id = msib.organization_id),
          TO_CHAR (rt.transaction_date, 'MON-YYYY'),
             pha.segment1
          || DECODE (pra.release_num, NULL, NULL, '-' || pra.release_num),
          rsh.receipt_num,
          papf.full_name,
          --  TO_CHAR (rt.transaction_date, 'DD/MON/YYYY HH24:MI:SS'),
          rt.transaction_date,
          msib.segment1,
          msib.description,
          (SELECT mcb.segment2
             FROM mtl_item_categories mic,
                  mtl_category_sets_tl mcst,
                  mtl_category_sets_b mcsb,
                  mtl_categories_b mcb
            WHERE     mcst.category_set_id = mcsb.category_set_id
                  AND mcst.language = USERENV ('LANG')
                  AND mic.category_set_id = mcsb.category_set_id
                  AND mic.category_id = mcb.category_id
                  AND mcst.category_set_name = 'PO Item Category'
                  AND mic.inventory_item_id = msib.inventory_item_id
                  AND mic.organization_id = msib.organization_id),
          NVL (pla.quantity, plla.quantity),
          rt.unit_of_measure,
          rt.quantity,
          rlt.lot_num,
          rt.quantity,
          (SELECT mln.expiration_date
             FROM mtl_lot_numbers mln
            WHERE     mln.inventory_item_id = rsl.item_id
                  AND mln.organization_id = rt.organization_id
                  AND mln.lot_number = rlt.lot_num)
     FROM po_headers_all pha,
          po_lines_all pla,
          rcv_transactions rt,
          rcv_shipment_headers rsh,
          rcv_shipment_lines rsl,
          per_all_people_f papf,
          mtl_system_items_b msib,
          rcv_lot_transactions rlt,
          hr_operating_units hou,
          po_releases_all pra,
          org_organization_definitions ood,
          po_line_locations_all plla
    WHERE     rsh.shipment_header_id = rsl.shipment_header_id
          AND pha.po_header_id = pla.po_header_id
          AND pha.org_id = pla.org_id
          AND pha.po_header_id = rt.po_header_id
          AND pha.po_header_id = rsl.po_header_id
          AND pla.po_line_id = rt.po_line_id
          AND pla.po_line_id = rsl.po_line_id
          AND rsh.shipment_header_id = rt.shipment_header_id
          AND rsl.shipment_line_id = rt.shipment_line_id
          AND (    rt.employee_id = papf.person_id(+)
               AND TRUNC (SYSDATE) BETWEEN TRUNC (
                                              NVL (papf.effective_start_date,
                                                   SYSDATE))
                                       AND TRUNC (
                                              NVL (papf.effective_end_date,
                                                   SYSDATE)))
          AND rsl.item_id = msib.inventory_item_id
          AND rt.organization_id = msib.organization_id
          AND rt.transaction_id = rlt.transaction_id(+)
          AND hou.organization_id = pha.org_id
          AND ood.organization_id = rt.organization_id
          AND rt.po_release_id = pra.po_release_id(+)
          AND rt.po_line_location_id = plla.line_location_id
          AND rt.transaction_type = 'RECEIVE';


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_PO_RECEIVING_REP_V FOR APPS.XX_BI_PO_RECEIVING_REP_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_PO_RECEIVING_REP_V FOR APPS.XX_BI_PO_RECEIVING_REP_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_PO_RECEIVING_REP_V FOR APPS.XX_BI_PO_RECEIVING_REP_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_PO_RECEIVING_REP_V FOR APPS.XX_BI_PO_RECEIVING_REP_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_PO_RECEIVING_REP_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_PO_RECEIVING_REP_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_PO_RECEIVING_REP_V TO XXINTG;
