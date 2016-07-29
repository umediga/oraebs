DROP VIEW APPS.XXIEX_DOM_ORDERS_ON_HOLD_V;

/* Formatted on 6/6/2016 5:00:25 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXIEX_DOM_ORDERS_ON_HOLD_V
(
   IEU_OBJECT_FUNCTION,
   IEU_OBJECT_PARAMETERS,
   IEU_MEDIA_TYPE_UUID,
   IEU_PARAM_PK_COL,
   IEU_PARAM_PK_VALUE,
   RESOURCE_ID,
   ORDER_NUMBER,
   PARTY_NAME,
   ACCOUNT_NUMBER,
   HEADER_ID,
   ORG_ID,
   COLLECTOR_CODE,
   COLLECTOR_NAME,
   COLLECTOR_DESC,
   RESOURCE_TYPE,
   COLLECTOR_ID,
   OVERALL_CREDIT_LIMIT,
   ORDER_TOTAL,
   OPEN_ORDERS_TOTAL,
   PAYMENT_TERMS,
   AR_BALANCE,
   ORDER_TYPE,
   HOLD_AGE,
   PREPAID_HOLD_AGE,
   NET_BALANCE,
   CUST_ACCOUNT_ID,
   PARTY_ID,
   OPERATING_UNIT,
   ORDER_CURRENCY,
   SHIP_METHOD_CODE,
   CARREIER_NAME,
   SHIPMENT_PRIORIRY,
   EMERGENCY_SHIPMENT
)
AS
   SELECT /*+ FIRST_ROWS */
         objb.object_function ieu_object_function,
          objb.object_parameters ieu_object_parameters,
          '' ieu_media_type_uuid,
          'HEADER_ID' ieu_param_pk_col,
          TO_CHAR (oe.header_id) ieu_param_pk_value,
          -1 resource_id,
          order_number order_number,
          party_name party_name,
          account_number account_number,
          oe.header_id header_id,
          oe.org_id org_id,
          (SELECT MAX (full_name)
             FROM per_all_people_f per
            WHERE per.person_id = ac.employee_id)
             collector_name,
          ac.name collector_code,
          ac.description collector_desc,
          objb.object_code resource_type,
          ac.collector_id collector_id,
          oe.overall_credit_limit overall_credit_limit,
          oe.order_total order_total,
          oe.open_orders_total,
          oe.payment_terms payment_terms,
          oe.ar_balance,
          oe.order_type,
          oe.hold_age,
          oe.prepaid_hold_age,
            (NVL (ar_balance, 0) + NVL (oe.open_orders_total, 0))
          - NVL (oe.overall_credit_limit, 0),
          oe.cust_account_id,
          oe.party_id,
          oe.operating_unit,
          oe.order_currency,
          ship_method_code,
          carreier_name,
          shipment_prioriry,
          oe.emergency_shipment
     FROM jtf_objects_b objb,
          xxiex_us_orders_on_hold_v oe,
          ar_collectors ac,
          hz_customer_profiles hcp
    WHERE     ac.collector_id = hcp.collector_id
          AND hcp.cust_account_id = oe.cust_account_id
          AND hcp.site_use_id IS NULL
          AND objb.object_code(+) = 'INTGIEX_ORDER_ON_HOLD'
          AND ac.collector_id <> 1
          AND oe.country IN
                 (SELECT lookup_code
                    FROM iex_lookups_v
                   WHERE lookup_type = 'INTG_IEX_DOMESTIC_COUNTRIES')
   UNION ALL
   SELECT /*+ FIRST_ROWS */
         objb.object_function ieu_object_function,
          objb.object_parameters ieu_object_parameters,
          '' ieu_media_type_uuid,
          'HEADER_ID' ieu_param_pk_col,
          TO_CHAR (oe.header_id) ieu_param_pk_value,
          -1 resource_id,
          order_number order_number,
          party_name party_name,
          account_number account_number,
          oe.header_id header_id,
          oe.org_id org_id,
          (SELECT MAX (full_name)
             FROM per_all_people_f per
            WHERE per.person_id = ac.employee_id)
             collector_name,
          ac.name collector_code,
          ac.description collector_desc,
          objb.object_code resource_type,
          ac.collector_id collector_id,
          oe.overall_credit_limit overall_credit_limit,
          oe.order_total order_total,
          oe.open_orders_total,
          oe.payment_terms payment_terms,
          oe.ar_balance,
          oe.order_type,
          oe.hold_age,
          oe.prepaid_hold_age,
            (NVL (ar_balance, 0) + NVL (oe.open_orders_total, 0))
          - NVL (oe.overall_credit_limit, 0),
          oe.cust_account_id,
          oe.party_id,
          oe.operating_unit,
          oe.order_currency,
          ship_method_code,
          carreier_name,
          shipment_prioriry,
          oe.emergency_shipment
     FROM jtf_objects_b objb,
          xxiex_us_orders_on_hold_v oe,
          ar_collectors ac,
          hz_customer_profiles hcp
    WHERE     ac.collector_id = hcp.collector_id
          AND hcp.cust_account_id = oe.cust_account_id
          AND hcp.site_use_id IS NULL
          AND objb.object_code(+) = 'INTGIEX_ORDER_ON_HOLD'
          AND ac.collector_id = 1
          AND oe.country IN
                 (SELECT lookup_code
                    FROM iex_lookups_v
                   WHERE lookup_type = 'INTG_IEX_DOMESTIC_COUNTRIES');


CREATE OR REPLACE SYNONYM XXAPPSREAD.XXIEX_DOM_ORDERS_ON_HOLD_V FOR APPS.XXIEX_DOM_ORDERS_ON_HOLD_V;


GRANT SELECT ON APPS.XXIEX_DOM_ORDERS_ON_HOLD_V TO XXAPPSREAD;
