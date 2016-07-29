DROP VIEW APPS.XX_BI_P2M_OPEN_ORD_V;

/* Formatted on 6/6/2016 4:59:08 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_P2M_OPEN_ORD_V
(
   ORGANIZATION,
   CUSTOMER_NUMBER,
   ITEM_NUMBER,
   ITEM_DESCRIPTION,
   ORDERED_QUANTITY,
   UNIT_LIST_PRICE,
   TOTAL_LINE_PRICE,
   CUSTOMER_NAME,
   REQUEST_DATE,
   SCHEDULED_SHIP_DATE,
   LINE_TYPE,
   PRICE_LIST,
   ORDER_STATUS,
   LINE_STATUS,
   ORDER_NUMBER,
   ORDER_TYPE,
   ORDER_CATEGORY,
   SHIPMENT_PRIORITY
)
AS
   SELECT ood.organization_code ORGANIZATION,
          hcaa.account_number,
          msi.segment1 item_number,
          msi.description item_description,
          oola.ordered_quantity ordered_quantity,
          oola.unit_list_price unit_list_price,
          (oola.unit_selling_price * oola.ordered_quantity) total_line_price,
          hp.party_name customer_name,
          oola.request_date request_date,
          oola.schedule_ship_date scheduled_ship_date,
          otta.description line_type,
          qlh.NAME price_list,
          ooha.flow_status_code order_status,
          oola.flow_status_code line_status,
          ooha.order_number,
          otta.NAME order_type,
          b.order_category_code,
          flvv.meaning shipment_priority
     FROM oe_order_lines_all oola,
          mtl_system_items_b msi,
          org_organization_definitions ood,
          apps.qp_list_headers qlh,
          hz_parties hp,
          hz_cust_accounts_all hcaa,
          oe_order_headers_all ooha,
          oe_transaction_types_tl otta,
          oe_transaction_types_all b,
          fnd_lookup_values_vl flvv
    WHERE     msi.inventory_item_id = oola.inventory_item_id
          AND msi.organization_id = oola.ship_from_org_id
          AND ood.organization_id = oola.ship_from_org_id
          AND qlh.list_header_id = oola.price_list_id
          AND oola.sold_to_org_id = hcaa.cust_account_id
          AND hp.party_id = hcaa.party_id
          AND ooha.header_id = oola.header_id
          AND otta.transaction_type_id = oola.line_type_id
          AND otta.LANGUAGE = 'US'
          AND oola.open_flag = 'Y'
          AND b.transaction_type_id = otta.transaction_type_id
          AND otta.LANGUAGE = USERENV ('LANG')
          AND b.order_category_code != 'RETURN'
          AND oola.shipment_priority_code = flvv.lookup_code
          AND flvv.lookup_type = 'SHIPMENT_PRIORITY'
   UNION
   SELECT ood.organization_code ORGANIZATION,
          hcaa.account_number,
          msi.segment1 item_number,
          msi.description item_description,
          oola.ordered_quantity * -1 ordered_quantity,
          oola.unit_list_price unit_list_price,
          (oola.unit_selling_price * (oola.ordered_quantity * -1))
             total_line_price,
          hp.party_name customer_name,
          oola.request_date request_date,
          oola.schedule_ship_date scheduled_ship_date,
          otta.description line_type,
          qlh.NAME price_list,
          ooha.flow_status_code order_status,
          oola.flow_status_code line_status,
          ooha.order_number,
          otta.NAME order_type,
          b.order_category_code,
          flvv.meaning shipment_priority
     FROM oe_order_lines_all oola,
          mtl_system_items_b msi,
          org_organization_definitions ood,
          apps.qp_list_headers qlh,
          hz_parties hp,
          hz_cust_accounts_all hcaa,
          oe_order_headers_all ooha,
          oe_transaction_types_tl otta,
          oe_transaction_types_all b,
          fnd_lookup_values_vl flvv
    WHERE     msi.inventory_item_id = oola.inventory_item_id
          AND msi.organization_id = oola.ship_from_org_id
          AND ood.organization_id = oola.ship_from_org_id
          AND qlh.list_header_id = oola.price_list_id
          AND oola.sold_to_org_id = hcaa.cust_account_id
          AND hp.party_id = hcaa.party_id
          AND ooha.header_id = oola.header_id
          AND otta.transaction_type_id = oola.line_type_id
          AND otta.LANGUAGE = 'US'
          AND oola.open_flag = 'Y'
          AND b.transaction_type_id = otta.transaction_type_id
          AND otta.LANGUAGE = USERENV ('LANG')
          AND b.order_category_code = 'RETURN'
          AND oola.shipment_priority_code = flvv.lookup_code
          AND flvv.lookup_type = 'SHIPMENT_PRIORITY';


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_P2M_OPEN_ORD_V FOR APPS.XX_BI_P2M_OPEN_ORD_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_P2M_OPEN_ORD_V FOR APPS.XX_BI_P2M_OPEN_ORD_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_P2M_OPEN_ORD_V FOR APPS.XX_BI_P2M_OPEN_ORD_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_P2M_OPEN_ORD_V FOR APPS.XX_BI_P2M_OPEN_ORD_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_P2M_OPEN_ORD_V TO ETLEBSUSER;
