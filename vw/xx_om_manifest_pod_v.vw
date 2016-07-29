DROP VIEW APPS.XX_OM_MANIFEST_POD_V;

/* Formatted on 6/6/2016 4:58:20 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_OM_MANIFEST_POD_V
(
   HEADER_ID,
   ORDER_NUMBER,
   ORG_ID
)
AS
     SELECT DISTINCT oeh.header_id, oeh.order_number, oeh.org_id
       FROM oe_order_headers_all oeh, oe_order_lines_all oel
      WHERE     oeh.header_id = oel.header_id
            AND oel.flow_status_code = 'POST-BILLING_ACCEPTANCE'
   ORDER BY oeh.header_id;
