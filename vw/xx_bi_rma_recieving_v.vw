DROP VIEW APPS.XX_BI_RMA_RECIEVING_V;

/* Formatted on 6/6/2016 4:59:00 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_RMA_RECIEVING_V
(
   OPERATING_UNIT,
   INVENTORY_ORGANIZATION_CODE,
   INVENTORY_ORGANIZATION,
   DIVISION,
   PERIOD,
   RMA_NUMBER,
   RECEIPT_NUMBER,
   RECEIVER_NAME,
   RECEIPT_DATE,
   ITEM_NUMBER,
   ITEM_DESCRIPTION,
   CATEGORY,
   ORDERED_QTY,
   UOM,
   RECEIVED_QTY,
   LOT_NUMBER,
   SERIAL_NUMBER,
   QUANTITY,
   LOT_EXPIRATION_DATE
)
AS
   SELECT hou.name,
          ood.ORGANIZATION_CODE,
          ood.organization_name,
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
                  AND mic.organization_id = msib.organization_id)
             DIVISION,
          TO_CHAR (RCT.TRANSACTION_DATE, 'MON-YYYY'),
          ooha.order_number,
          rsh.receipt_num,
          (SELECT pl.full_name
             FROM per_people_f pl
            WHERE     pl.PERSON_ID(+) = rct.employee_id
                  AND TRUNC (SYSDATE) BETWEEN NVL (pl.EFFECTIVE_START_DATE,
                                                   TRUNC (SYSDATE - 1))
                                          AND NVL (pl.EFFECTIVE_END_DATE,
                                                   TRUNC (SYSDATE + 1)))
             RECEIVER_NAME,
          rct.transaction_date,
          msib.segment1,
          msib.description,
          (SELECT    mcb.segment4
                  || '.'
                  || mcb.segment10
                  || '.'
                  || mcb.segment6
                  || '.'
                  || mcb.segment8
                  || '.'
                  || mcb.segment9
                  || '.'
                  || mcb.segment7
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
                  AND mic.organization_id = msib.organization_id)
             CATEGORY_DETAILS,
          oola.ordered_quantity,
          rsl.unit_of_measure,
          rct.quantity,                      --rsl.quantity_received,--UAT BUG
          rlt.lot_num,
          a.serial_numbers,
          rct.quantity,
          (SELECT mln.expiration_date
             FROM mtl_lot_numbers mln
            WHERE     mln.lot_number = rlt.lot_num
                  AND mln.inventory_item_id = oola.inventory_item_id
                  AND mln.organization_id = oola.ship_from_org_id)
             expiration_date
     FROM oe_order_headers_all ooha,
          oe_order_lines_all oola,
          rcv_transactions rct,
          rcv_shipment_lines rsl,
          rcv_shipment_headers rsh,
          hr_operating_units hou,
          org_organization_definitions ood,
          mtl_system_items_b msib,
          rcv_lot_transactions rlt,
          (  SELECT rst.shipment_line_id,
                    rst.transaction_id,
                    LISTAGG (rst.serial_num, ',')
                       WITHIN GROUP (ORDER BY rst.serial_num)
                       AS SERIAL_NUMBERS
               FROM rcv_serial_transactions rst
           GROUP BY rst.shipment_line_id, rst.transaction_id) a
    WHERE     rct.source_document_code = 'RMA'
          AND rct.destination_type_code = 'RECEIVING'
          AND rct.transaction_type = 'RECEIVE'
          AND ooha.header_id = oola.header_id
          AND ooha.org_id = oola.org_id
          AND ooha.header_id = rct.oe_order_header_id
          AND oola.line_ID = rct.oe_order_line_id
          AND rct.shipment_line_id = rsl.shipment_line_id
          AND rsl.shipment_header_id = rsh.shipment_header_id
          AND ooha.header_id = rsl.oe_order_header_id
          AND oola.line_id = rsl.oe_order_line_id
          AND ooha.org_id = hou.organization_id
          AND oola.ship_from_org_id = ood.organization_id
          AND oola.inventory_item_id = msib.inventory_item_id
          AND oola.ship_from_org_id = msib.organization_id
          AND rct.shipment_line_id = rlt.shipment_line_id(+)
          AND rct.transaction_id = rlt.source_transaction_id(+)
          AND rct.shipment_line_id = a.shipment_line_id(+)
          AND rct.transaction_id = a.transaction_id(+);


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_RMA_RECIEVING_V FOR APPS.XX_BI_RMA_RECIEVING_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_RMA_RECIEVING_V FOR APPS.XX_BI_RMA_RECIEVING_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_RMA_RECIEVING_V FOR APPS.XX_BI_RMA_RECIEVING_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_RMA_RECIEVING_V FOR APPS.XX_BI_RMA_RECIEVING_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_RMA_RECIEVING_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_RMA_RECIEVING_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_RMA_RECIEVING_V TO XXINTG;
