DROP VIEW APPS.XX_BI_O2C_ONTIMESHIP_V;

/* Formatted on 6/6/2016 4:59:27 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_O2C_ONTIMESHIP_V
(
   ORDER_NUMBER,
   OPERATING_UNIT_ID,
   OPERATING_UNIT,
   SHIP_FROM_ORG_ID,
   WAREHOUSE_CODE,
   INVENTORY_ORGANIZATION,
   CUSTOMER_NUMBER,
   CUSTOMER,
   REQUEST_DATE,
   PROMISE_DATE,
   ACTUAL_DELIVERY_DATE,
   VARIANCE1,
   VARIANCE2
)
AS
     SELECT ooha.order_number,
            ooha.org_id operating_unit_id,
            hou.name operating_unit,
            oola.ship_from_org_id,
            ood.organization_code warehouse_code,
            ood.organization_name inventory_organization,
            hcaa.account_number customer_number,
            hcaa.account_name customer,
            oola.request_date request_date,
            oola.promise_date promise_date,
            oola.actual_shipment_date actual_delivery_date,
            ROUND (oola.actual_shipment_date - oola.request_date) variance1,
            ROUND (oola.actual_shipment_date - oola.promise_date) variance2
       FROM apps.oe_order_headers_all ooha,
            apps.oe_order_lines_all oola,
            apps.org_organization_definitions ood,
            apps.hr_operating_units hou,
            apps.hz_cust_accounts hcaa
      WHERE     1 = 1
            AND ooha.header_id = oola.header_id
            AND ooha.org_id = oola.org_id
            AND oola.ship_from_org_id = ood.organization_id
            AND ooha.org_id = hou.organization_id
            AND ooha.sold_to_org_id = hcaa.cust_account_id
   GROUP BY ooha.order_number,
            ooha.org_id,
            hou.name,
            oola.ship_from_org_id,
            ood.organization_code,
            ood.organization_name,
            hcaa.account_number,
            hcaa.account_name,
            oola.request_date,
            oola.promise_date,
            oola.actual_shipment_date,
            ROUND (oola.actual_shipment_date - oola.request_date),
            ROUND (oola.actual_shipment_date - oola.promise_date)
   ORDER BY oola.ship_from_org_id, ooha.order_number;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_O2C_ONTIMESHIP_V FOR APPS.XX_BI_O2C_ONTIMESHIP_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_O2C_ONTIMESHIP_V TO ETLEBSUSER;
