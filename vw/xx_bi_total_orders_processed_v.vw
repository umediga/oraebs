DROP VIEW APPS.XX_BI_TOTAL_ORDERS_PROCESSED_V;

/* Formatted on 6/6/2016 4:58:53 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_TOTAL_ORDERS_PROCESSED_V
(
   OPERATING_UNIT,
   DIVISION,
   STATUS,
   NO_OF_ORDERS
)
AS
     SELECT hou.name,
            div.division,
            ooha.flow_status_code,
            COUNT (DISTINCT ooha.header_id)
       FROM oe_order_headers_all ooha,
            oe_order_lines_all oola,
            hr_operating_units hou,
            (SELECT ooha2.header_id HEADER_ID,
                    oola2.line_id LINE_ID,
                    DECODE (
                       (SELECT COUNT (DISTINCT mcb1.segment4)
                          FROM mtl_item_categories mic1,
                               mtl_category_sets_tl mcst1,
                               mtl_category_sets_b mcsb1,
                               mtl_categories_b mcb1,
                               oe_order_headers_all ooha1,
                               oe_order_lines_all oola1
                         WHERE     mcst1.category_set_id =
                                      mcsb1.category_set_id
                               AND mcst1.language = USERENV ('LANG')
                               AND mic1.category_set_id = mcsb1.category_set_id
                               AND mic1.category_id = mcb1.category_id
                               AND mcst1.category_set_name =
                                      'Sales and Marketing'
                               AND mic1.inventory_item_id =
                                      oola1.inventory_item_id
                               AND mic1.organization_id =
                                      oola1.ship_from_org_id
                               AND oola1.header_id = ooha1.header_id
                               AND ooha1.header_id = ooha2.header_id),
                       1, mcb2.segment4,
                       'MULTIDIVISION')
                       DIVISION
               FROM mtl_item_categories mic2,
                    mtl_category_sets_tl mcst2,
                    mtl_category_sets_b mcsb2,
                    mtl_categories_b mcb2,
                    oe_order_headers_all ooha2,
                    oe_order_lines_all oola2
              WHERE     mcst2.category_set_id = mcsb2.category_set_id
                    AND mcst2.language = USERENV ('LANG')
                    AND mic2.category_set_id = mcsb2.category_set_id
                    AND mic2.category_id = mcb2.category_id
                    AND mcst2.category_set_name = 'Sales and Marketing'
                    AND mic2.inventory_item_id = oola2.inventory_item_id
                    AND mic2.organization_id = oola2.ship_from_org_id
                    AND ooha2.header_id = oola2.header_id) div
      WHERE     ooha.header_id = oola.header_id
            AND ooha.org_id = hou.organization_id
            AND ooha.header_id = div.header_id
            AND oola.line_id = div.line_id
   GROUP BY hou.name, div.division, ooha.flow_status_code;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_TOTAL_ORDERS_PROCESSED_V FOR APPS.XX_BI_TOTAL_ORDERS_PROCESSED_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_TOTAL_ORDERS_PROCESSED_V FOR APPS.XX_BI_TOTAL_ORDERS_PROCESSED_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_TOTAL_ORDERS_PROCESSED_V FOR APPS.XX_BI_TOTAL_ORDERS_PROCESSED_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_TOTAL_ORDERS_PROCESSED_V FOR APPS.XX_BI_TOTAL_ORDERS_PROCESSED_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_TOTAL_ORDERS_PROCESSED_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_TOTAL_ORDERS_PROCESSED_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_TOTAL_ORDERS_PROCESSED_V TO XXINTG;
