DROP VIEW APPS.XX_BI_OE_ONTIME_SHIP_PERF_V;

/* Formatted on 6/6/2016 4:59:18 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_OE_ONTIME_SHIP_PERF_V
(
   OPERATING_UNIT,
   ORG_CODE,
   ORDER_NUMBER,
   ORDERED_DATE,
   CUSTOMER_NAME,
   CUSTOMER_NUMBER,
   REQUESTED_DATE,
   PROMISED_DATE,
   ACTUAL_DELIVERY_DATE,
   VARIANCE1,
   VARIANCE2,
   FLOW_STATUS_CODE
)
AS
     SELECT ooh.org_id "OPERATING_UNIT",
            ood.organization_code,
            ooh.order_number,
            ooh.ordered_date,
            sold_to_org.NAME customer_name,
            sold_to_org.customer_number,
            NVL (ool.request_date, ooh.request_date) request_date,
            ool.promise_date,
            ool.actual_fulfillment_date "ACTUAL_DELIVERY_DATE",
            (  TRUNC (ool.actual_fulfillment_date)
             - TRUNC (NVL (ool.request_date, ooh.request_date)))
               "VARIANCE1",
            (TRUNC (ool.actual_fulfillment_date) - TRUNC (ool.promise_date))
               "VARIANCE2",
            ooh.flow_status_code
       FROM oe_order_headers_all ooh,
            oe_order_lines_all ool,
            oe_sold_to_orgs_v sold_to_org,
            org_organization_definitions ood,
            hr_operating_units hou
      WHERE     ooh.header_id = ool.header_id
            AND ooh.ship_from_org_id = ood.organization_id
            AND ooh.sold_to_org_id = sold_to_org.organization_id(+)
            AND ooh.org_id = hou.organization_id
   ORDER BY ooh.order_number;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_OE_ONTIME_SHIP_PERF_V FOR APPS.XX_BI_OE_ONTIME_SHIP_PERF_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_OE_ONTIME_SHIP_PERF_V FOR APPS.XX_BI_OE_ONTIME_SHIP_PERF_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_OE_ONTIME_SHIP_PERF_V FOR APPS.XX_BI_OE_ONTIME_SHIP_PERF_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_OE_ONTIME_SHIP_PERF_V FOR APPS.XX_BI_OE_ONTIME_SHIP_PERF_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_OE_ONTIME_SHIP_PERF_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_OE_ONTIME_SHIP_PERF_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_OE_ONTIME_SHIP_PERF_V TO XXINTG;
