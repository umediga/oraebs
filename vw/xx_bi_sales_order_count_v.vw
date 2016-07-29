DROP VIEW APPS.XX_BI_SALES_ORDER_COUNT_V;

/* Formatted on 6/6/2016 4:58:57 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_SALES_ORDER_COUNT_V
(
   LINE_NUMBER,
   ORDER_NUMBER,
   ORDER_TYPE,
   SALES_CHANNEL,
   DATE_ORDERED,
   DIVISION
)
AS
     SELECT ola.line_number LINE_NUMBER,
            oha.order_number ORDER_NUMBER,
            ottt.name ORDER_TYPE,
            oha.sales_channel_code SALES_CHANNEL,
            TRUNC (oha.ordered_date) DATE_ORDERED,
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
                    AND mic.inventory_item_id = ola.inventory_item_id
                    AND mic.organization_id = ola.ship_from_org_id)
               DIVISION
       FROM oe_order_headers_all oha,
            oe_order_lines_all ola,
            oe_transaction_types_all otta,
            oe_transaction_types_tl ottt
      WHERE     oha.header_id = ola.header_id
            AND oha.order_type_id = otta.transaction_type_id
            AND otta.transaction_type_id = ottt.transaction_type_id
            AND ottt.language = USERENV ('LANG')
   ORDER BY oha.order_number, ola.line_number;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_SALES_ORDER_COUNT_V FOR APPS.XX_BI_SALES_ORDER_COUNT_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_SALES_ORDER_COUNT_V FOR APPS.XX_BI_SALES_ORDER_COUNT_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_SALES_ORDER_COUNT_V FOR APPS.XX_BI_SALES_ORDER_COUNT_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_SALES_ORDER_COUNT_V FOR APPS.XX_BI_SALES_ORDER_COUNT_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_ORDER_COUNT_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_ORDER_COUNT_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_ORDER_COUNT_V TO XXINTG;
