DROP VIEW APPS.XX_BI_OE_ODR_LN_V;

/* Formatted on 6/6/2016 4:59:19 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_OE_ODR_LN_V
(
   ACCOUNTING_RULE_DURATION,
   ACTUAL_ARRIVAL_DATE,
   ACTUAL_SHIPMENT_DATE,
   AGREEMENT,
   CHANGE_SEQUENCE,
   COMPONENT_CODE,
   COMPONENT_NUMBER,
   CONFIG_DISPLAY_SEQUENCE,
   CONFIG_REV_NBR,
   CUSTOMER,
   CUSTOMER_DOCK_CODE,
   CUSTOMER_JOB,
   CUSTOMER_LINE_NUMBER,
   CUSTOMER_NUMBER,
   CUSTOMER_PRODUCTION_LINE,
   CUSTOMER_SHIPMENT_NUMBER,
   CUST_MODEL_SERIAL_NUMBER,
   CUST_PO_NUMBER,
   CUST_PRODUCTION_SEQ_NUM,
   DEMAND_BUCKET_TYPE_CODE,
   DEMAND_CLASS_CODE,
   EARLIEST_ACCEPTABLE_DATE,
   END_ITEM_UNIT_NUMBER,
   EXPLOSION_DATE,
   FIRST_ACK_CODE,
   FIRST_ACK_DATE,
   FOB_POINT_CODE,
   FREIGHT_CARRIER_CODE,
   FULFILLMENT_DATE,
   FULFILLMENT_METHOD_CODE,
   INVOICE_INTERFACE_STATUS_CODE,
   ITEM_IDENTIFIER_TYPE,
   ITEM_REVISION,
   ITEM_SUBSTITUTION_TYPE_CODE,
   ITEM_TYPE_CODE,
   LAST_ACK_CODE,
   LAST_ACK_DATE,
   LATEST_ACCEPTABLE_DATE,
   LATE_DEMAND_PENALTY_FACTOR,
   LINE_CATEGORY_CODE,
   LINE_NUMBER,
   LINE_TYPE,
   MODEL_GROUP_NUMBER,
   OPTION_NUMBER,
   ORDERED_ITEM,
   ORDERED_QUANTITY_UOM,
   ORDERED_QUANTITY_UOM2,
   ORIGINAL_ITEM_IDENTIFIER_TYPE,
   ORIGINAL_ORDERED_ITEM,
   ORIG_SYS_DOCUMENT_REF,
   ORIG_SYS_LINE_REF,
   ORIG_SYS_SHIPMENT_REF,
   OVERRIDE_ATP_DATE_CODE,
   PACKING_INSTRUCTIONS,
   PLANNING_PRIORITY,
   PREFERRED_GRADE,
   PRICE_LIST,
   PRICE_REQUEST_CODE,
   PRICING_DATE,
   PRICING_QUANTITY_UOM,
   PROMISE_DATE,
   REFERENCE_TYPE,
   REQUEST_DATE,
   RETURN_REASON_CODE,
   RLA_SCHEDULE_TYPE_CODE,
   SALESPERSON,
   SCHEDULE_ARRIVAL_DATE,
   SCHEDULE_SHIP_DATE,
   SCHEDULE_STATUS,
   SERVICE_END_DATE,
   SERVICE_NUMBER,
   SERVICE_PERIOD,
   SERVICE_START_DATE,
   SERVICE_TXN_COMMENTS,
   SERVICE_TXN_REASON_CODE,
   SHIPMENT_NUMBER,
   SHIPPING_INSTRUCTIONS,
   SHIPPING_QUANTITY_UOM,
   SHIPPING_QUANTITY_UOM2,
   SHIP_FROM_ORG_ID,
   SORT_ORDER,
   SPLIT_BY,
   SUBINVENTORY,
   TAX_CODE,
   TAX_DATE,
   TAX_EXEMPT_FLAG,
   TAX_EXEMPT_NUMBER,
   TAX_EXEMPT_REASON_CODE,
   UPGRADED_FLAG,
   ACTUAL_SHIPMENT_DATE_DAY,
   ACTUAL_SHIPMENT_DATE_MONTH,
   ACTUAL_SHIPMENT_DATE_QUARTER,
   ACTUAL_SHIPMENT_DATE_YEAR,
   FULFILLMENT_DATE_DAY,
   FULFILLMENT_DATE_MONTH,
   FULFILLMENT_DATE_QUARTER,
   FULFILLMENT_DATE_YEAR,
   PRICING_DATE_DAY,
   PRICING_DATE_MONTH,
   PRICING_DATE_QUARTER,
   PRICING_DATE_YEAR,
   PROMISE_DATE_DAY,
   PROMISE_DATE_MONTH,
   PROMISE_DATE_QUARTER,
   PROMISE_DATE_YEAR,
   REQUEST_DATE_DAY,
   REQUEST_DATE_MONTH,
   REQUEST_DATE_QUARTER,
   REQUEST_DATE_YEAR,
   SCHEDULE_SHIP_DATE_DAY,
   SCHEDULE_SHIP_DATE_MONTH,
   SCHEDULE_SHIP_DATE_QUARTER,
   SCHEDULE_SHIP_DATE_YEAR,
   STATUS,
   CALCULATE_PRICE_FLAG,
   SOURCE_TYPE,
   SHIPMENT_PRIORITY,
   FREIGHT_TERMS,
   BOOKED_FLAG,
   CANCELLED_FLAG,
   OPEN_FLAG,
   SHIPPABLE_FLAG,
   FULFILLED_FLAG,
   RETURN_REFERENCE_TYPE,
   RETURN_ORDER_2,
   RETURN_LINE_2,
   RETURN_PO_3,
   RETURN_LINE_3,
   RETURN_INVOICE_4,
   RETURN_LINE_4,
   RETURN_ITEM_5,
   RETURN_SERIAL_5,
   SHIPPING_METHOD,
   TAX_POINT,
   OPTION_FLAG,
   DEP_PLAN_REQUIRED_FLAG,
   VISIBLE_DEMAND_FLAG,
   SHIP_MODEL_COMPLETE_FLAG,
   RE_SOURCE_FLAG,
   AUTHORIZED_TO_SHIP_FLAG,
   OVER_SHIP_REASON,
   OVER_SHIP_RESOLVED_FLAG,
   SHIPPING_INTERFACED_FLAG,
   SERVICE_COTERMINATE_FLAG,
   SERVICE_REFERENCE_TYPE,
   MODEL_REMNANT_FLAG,
   UNIT_SELLING_PRICE_PER_PQTY,
   MFG_LEAD_TIME,
   CUSTOMER_ITEM_NET_PRICE,
   REVENUE_AMOUNT,
   UNIT_PERCENT_BASE_PRICE,
   UNIT_SELLING_PERCENT,
   UNIT_LIST_PERCENT,
   AUTO_SELECTED_QUANTITY,
   TAX_RATE,
   SHIP_TOLERANCE_BELOW,
   SHIP_TOLERANCE_ABOVE,
   DELIVER_LEAD_TIME,
   SHIPPING_QUANTITY,
   SERVICE_DURATION,
   FULFILLED_QUANTITY2,
   FULFILLED_QUANTITY,
   SHIPPED_QUANTITY2,
   SHIPPED_QUANTITY,
   TAX_VALUE,
   SHIPPING_QUANTITY2,
   PRICING_QUANTITY,
   UNIT_LIST_PRICE,
   CANCELLED_QUANTITY2,
   CANCELLED_QUANTITY,
   UNIT_SELLING_PRICE,
   INVOICED_QUANTITY,
   ORDERED_QUANTITY2,
   ORDERED_QUANTITY
)
AS
   SELECT LINE.ACCOUNTING_RULE_DURATION,
          LINE.ACTUAL_ARRIVAL_DATE,
          LINE.ACTUAL_SHIPMENT_DATE,
          AGREE.NAME,
          LINE.CHANGE_SEQUENCE,
          LINE.COMPONENT_CODE,
          LINE.COMPONENT_NUMBER,
          LINE.CONFIG_DISPLAY_SEQUENCE,
          LINE.CONFIG_REV_NBR,
          SUBSTRB (PARTY.PARTY_NAME, 1, 50) CUSTOMER,
          LINE.CUSTOMER_DOCK_CODE,
          LINE.CUSTOMER_JOB,
          LINE.CUSTOMER_LINE_NUMBER,
          CUST_ACCT.ACCOUNT_NUMBER CUSTOMER_NUMBER,
          LINE.CUSTOMER_PRODUCTION_LINE,
          LINE.CUSTOMER_SHIPMENT_NUMBER,
          LINE.CUST_MODEL_SERIAL_NUMBER,
          LINE.CUST_PO_NUMBER,
          LINE.CUST_PRODUCTION_SEQ_NUM,
          LINE.DEMAND_BUCKET_TYPE_CODE,
          LINE.DEMAND_CLASS_CODE,
          LINE.EARLIEST_ACCEPTABLE_DATE,
          LINE.END_ITEM_UNIT_NUMBER,
          LINE.EXPLOSION_DATE,
          LINE.FIRST_ACK_CODE,
          LINE.FIRST_ACK_DATE,
          LINE.FOB_POINT_CODE,
          LINE.FREIGHT_CARRIER_CODE,
          LINE.FULFILLMENT_DATE,
          LINE.FULFILLMENT_METHOD_CODE,
          LINE.INVOICE_INTERFACE_STATUS_CODE,
          LINE.ITEM_IDENTIFIER_TYPE,
          LINE.ITEM_REVISION,
          LINE.ITEM_SUBSTITUTION_TYPE_CODE,
          LINE.ITEM_TYPE_CODE,
          LINE.LAST_ACK_CODE,
          LINE.LAST_ACK_DATE,
          LINE.LATEST_ACCEPTABLE_DATE,
          LINE.LATE_DEMAND_PENALTY_FACTOR,
          LINE.LINE_CATEGORY_CODE,
          LINE.LINE_NUMBER,
          LT.NAME,
          LINE.MODEL_GROUP_NUMBER,
          LINE.OPTION_NUMBER,
          ITEMS.CONCATENATED_SEGMENTS,
          UOM.UNIT_OF_MEASURE,
          UOM2.UNIT_OF_MEASURE,
          LINE.ORIGINAL_ITEM_IDENTIFIER_TYPE,
          LINE.ORIGINAL_ORDERED_ITEM,
          LINE.ORIG_SYS_DOCUMENT_REF,
          LINE.ORIG_SYS_LINE_REF,
          LINE.ORIG_SYS_SHIPMENT_REF,
          LINE.OVERRIDE_ATP_DATE_CODE,
          LINE.PACKING_INSTRUCTIONS,
          LINE.PLANNING_PRIORITY,
          LINE.PREFERRED_GRADE,
          PL.NAME,
          LINE.PRICE_REQUEST_CODE,
          LINE.PRICING_DATE,
          UOM1.UNIT_OF_MEASURE,
          LINE.PROMISE_DATE,
          LINE.REFERENCE_TYPE,
          LINE.REQUEST_DATE,
          LINE.RETURN_REASON_CODE,
          LINE.RLA_SCHEDULE_TYPE_CODE,
          OE_BIS_SALESPERSON.GET_SALESPERSON_NAME (LINE.SALESREP_ID)
             SALESPERSON,
          LINE.SCHEDULE_ARRIVAL_DATE,
          LINE.SCHEDULE_SHIP_DATE,
          LINE.SCHEDULE_STATUS_CODE,
          LINE.SERVICE_END_DATE,
          LINE.SERVICE_NUMBER,
          LINE.SERVICE_PERIOD,
          LINE.SERVICE_START_DATE,
          LINE.SERVICE_TXN_COMMENTS,
          LINE.SERVICE_TXN_REASON_CODE,
          LINE.SHIPMENT_NUMBER,
          LINE.SHIPPING_INSTRUCTIONS,
          LINE.SHIPPING_QUANTITY_UOM,
          UOM3.UNIT_OF_MEASURE,
          LINE.SHIP_FROM_ORG_ID,
          LINE.SORT_ORDER,
          LINE.SPLIT_BY,
          LINE.SUBINVENTORY,
          LINE.TAX_CODE,
          LINE.TAX_DATE,
          LINE.TAX_EXEMPT_FLAG,
          LINE.TAX_EXEMPT_NUMBER,
          LINE.TAX_EXEMPT_REASON_CODE,
          LINE.UPGRADED_FLAG,
          (DECODE (
              LINE.ACTUAL_SHIPMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (LINE.ACTUAL_SHIPMENT_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             ACTUAL_SHIPMENT_DATE_DAY,
          (DECODE (
              LINE.ACTUAL_SHIPMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (LINE.ACTUAL_SHIPMENT_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             ACTUAL_SHIPMENT_DATE_MONTH,
          (DECODE (
              LINE.ACTUAL_SHIPMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (LINE.ACTUAL_SHIPMENT_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             ACTUAL_SHIPMENT_DATE_QUARTER,
          (DECODE (
              LINE.ACTUAL_SHIPMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (LINE.ACTUAL_SHIPMENT_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             ACTUAL_SHIPMENT_DATE_YEAR,
          (DECODE (
              LINE.FULFILLMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (LINE.FULFILLMENT_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             FULFILLMENT_DATE_DAY,
          (DECODE (
              LINE.FULFILLMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (LINE.FULFILLMENT_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             FULFILLMENT_DATE_MONTH,
          (DECODE (
              LINE.FULFILLMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LINE.FULFILLMENT_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             FULFILLMENT_DATE_QUARTER,
          (DECODE (
              LINE.FULFILLMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (LINE.FULFILLMENT_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             FULFILLMENT_DATE_YEAR,
          (DECODE (
              LINE.PRICING_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LINE.PRICING_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             PRICING_DATE_DAY,
          (DECODE (
              LINE.PRICING_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LINE.PRICING_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             PRICING_DATE_MONTH,
          (DECODE (
              LINE.PRICING_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LINE.PRICING_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             PRICING_DATE_QUARTER,
          (DECODE (
              LINE.PRICING_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LINE.PRICING_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             PRICING_DATE_YEAR,
          (DECODE (
              LINE.PROMISE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LINE.PROMISE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             PROMISE_DATE_DAY,
          (DECODE (
              LINE.PROMISE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LINE.PROMISE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             PROMISE_DATE_MONTH,
          (DECODE (
              LINE.PROMISE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LINE.PROMISE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             PROMISE_DATE_QUARTER,
          (DECODE (
              LINE.PROMISE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LINE.PROMISE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             PROMISE_DATE_YEAR,
          (DECODE (
              LINE.REQUEST_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LINE.REQUEST_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             REQUEST_DATE_DAY,
          (DECODE (
              LINE.REQUEST_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LINE.REQUEST_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             REQUEST_DATE_MONTH,
          (DECODE (
              LINE.REQUEST_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LINE.REQUEST_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             REQUEST_DATE_QUARTER,
          (DECODE (
              LINE.REQUEST_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LINE.REQUEST_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             REQUEST_DATE_YEAR,
          (DECODE (
              LINE.SCHEDULE_SHIP_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (LINE.SCHEDULE_SHIP_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             SCHEDULE_SHIP_DATE_DAY,
          (DECODE (
              LINE.SCHEDULE_SHIP_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (LINE.SCHEDULE_SHIP_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             SCHEDULE_SHIP_DATE_MONTH,
          (DECODE (
              LINE.SCHEDULE_SHIP_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (LINE.SCHEDULE_SHIP_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             SCHEDULE_SHIP_DATE_QUARTER,
          (DECODE (
              LINE.SCHEDULE_SHIP_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (LINE.SCHEDULE_SHIP_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             SCHEDULE_SHIP_DATE_YEAR,
          DECODE (
             LINE.FLOW_STATUS_CODE,
             'AWAITING_EXPORT_SCREENING', 'Awaiting Export Screening',
             'AWAITING_FULFILLMENT', 'Awaiting Fulfillment',
             'AWAITING_RECEIPT', 'Awaiting Receipt',
             'AWAITING_RETURN', 'Awaiting Return',
             'AWAITING_RETURN_DISPOSITION', 'Awaiting Return Disposition',
             'AWAITING_SHIPPING', 'Awaiting Shipping',
             'BILLING_FAILED', 'Third Party Billing Failed',
             'BILLING_REQUEST', 'Third Party Billing Requested',
             'BILLING_SUCCESS', 'Third Party Billing Succeeded',
             'BOM_AND_RTG_CREATED', 'BOM and Routing Created',
             'BOOKED', 'Booked',
             'CANCELLED', 'Cancelled',
             'CLOSED', 'Closed',
             'ENTERED', 'Entered',
             'EXPORT_SCREENING_COMPLETED', 'Completed Export Screening',
             'EXPORT_SCREENING_DATA_ERROR', 'Data Error Export Screening',
             'FULFILLED', 'Fulfilled',
             'INVENTORY_INTERFACED', 'Inventory Interfaced',
             'INVOICED', 'Interfaced to Receivables',
             'INVOICED_PARTIAL', 'Partially Interfaced to Receivables',
             'ITEM_CREATED', 'Config Item Created',
             'PICKED', 'Picked',
             'PICKED_PARTIAL', 'Picked Partial',
             'PO_CREATED', 'PO-Created',
             'PO_PARTIAL', 'PO-Partial',
             'PO_RECEIVED', 'PO-Received',
             'PO_REQ_CREATED', 'PO-ReqCreated',
             'PO_REQ_REQUESTED', 'PO-ReqRequested',
             'PREPROVISION', 'Preprovision',
             'PRE_PROV_FAILED', 'Preprovision Failed',
             'PRE_PROV_REQUEST', 'Preprovision Requested',
             'PRE_PROV_SUCCESS', 'Preprovision Succeeded',
             'PRODUCTION_COMPLETE', 'Production Complete',
             'PRODUCTION_ELIGIBLE', 'Production Eligible',
             'PRODUCTION_OPEN', 'Production Open',
             'PRODUCTION_PARTIAL', 'Production Partial',
             'PROV_FAILED', 'Provisioning in Error',
             'PROV_FAILED_UPDATE_TXN', 'Provisioning Failed to update Transaction Details',
             'PROV_REJECTED', 'Provisioning Rejected',
             'PROV_REQUEST', 'Provisioning Requested',
             'PROV_SUCCESS', 'Provisioning Successful',
             'RELEASED_TO_WAREHOUSE', 'Released to Warehouse',
             'RETURNED', 'Returned',
             'SCHEDULED', 'Scheduled',
             'SHIPPED', 'Shipped',
             NULL),
          DECODE (LINE.CALCULATE_PRICE_FLAG,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (LINE.SOURCE_TYPE_CODE,
                  'EXTERNAL', 'External',
                  'INTERNAL', 'Internal',
                  NULL),
          DECODE (LINE.SHIPMENT_PRIORITY_CODE,
                  'High', 'High Priority',
                  'Standard', 'Standard Priority',
                  NULL),
          DECODE (LINE.FREIGHT_TERMS_CODE,
                  'COLLECT', 'Collect',
                  'DUECOST', 'Prepay and Add with cost conversion',
                  'Due', 'Prepay and Add',
                  'Paid', 'Prepaid',
                  'TBD', 'To Be Determined',
                  'THIRD_PARTY', 'Third Party Billing',
                  NULL),
          DECODE (LINE.BOOKED_FLAG,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (LINE.CANCELLED_FLAG,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (LINE.OPEN_FLAG,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (LINE.SHIPPABLE_FLAG,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (LINE.FULFILLED_FLAG,  'N', 'No',  'Y', 'Yes',  NULL),
          LINE.RETURN_CONTEXT,
          LINE.RETURN_ATTRIBUTE1,
          LINE.RETURN_ATTRIBUTE2,
          LINE.RETURN_ATTRIBUTE1,
          LINE.RETURN_ATTRIBUTE2,
          LINE.RETURN_ATTRIBUTE1,
          LINE.RETURN_ATTRIBUTE2,
          LINE.RETURN_ATTRIBUTE1,
          LINE.RETURN_ATTRIBUTE2,
          DECODE (LINE.SHIPPING_METHOD_CODE,
                  'DEL', 'Delivery',
                  'PS', 'Pick Slip',
                  NULL),
          DECODE (LINE.TAX_POINT_CODE, 'INVOICE', 'AT INVOICING', NULL),
          DECODE (LINE.OPTION_FLAG,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (LINE.DEP_PLAN_REQUIRED_FLAG,
                  'N', 'No',
                  'Y', 'Yes',
                  NULL),
          DECODE (LINE.VISIBLE_DEMAND_FLAG,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (LINE.SHIP_MODEL_COMPLETE_FLAG,
                  'N', 'No',
                  'Y', 'Yes',
                  NULL),
          DECODE (LINE.RE_SOURCE_FLAG,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (LINE.AUTHORIZED_TO_SHIP_FLAG,
                  'N', 'No',
                  'Y', 'Yes',
                  NULL),
          DECODE (
             LINE.OVER_SHIP_REASON_CODE,
             'CUST_APPROVAL', 'Customer Approved Shipping Over TOlerance',
             'PACK_RESTRICT', 'Packaging Restrictions',
             'SHIP_ERROR', 'Shipment Error',
             'SHIP_OVERAGE', 'Shipper Overage',
             NULL),
          DECODE (LINE.OVER_SHIP_RESOLVED_FLAG,
                  'N', 'No',
                  'Y', 'Yes',
                  NULL),
          DECODE (LINE.SHIPPING_INTERFACED_FLAG,
                  'N', 'No',
                  'Y', 'Yes',
                  NULL),
          DECODE (LINE.SERVICE_COTERMINATE_FLAG,
                  'N', 'No',
                  'Y', 'Yes',
                  NULL),
          DECODE (LINE.SERVICE_REFERENCE_TYPE_CODE,
                  'CUSTOMER_PRODUCT', 'Customer Product',
                  'ORDER', 'Order',
                  NULL),
          DECODE (LINE.MODEL_REMNANT_FLAG,  'N', 'No',  'Y', 'Yes',  NULL),
          LINE.UNIT_SELLING_PRICE_PER_PQTY,
          LINE.MFG_LEAD_TIME,
          LINE.CUSTOMER_ITEM_NET_PRICE,
          LINE.REVENUE_AMOUNT,
          LINE.UNIT_PERCENT_BASE_PRICE,
          LINE.UNIT_SELLING_PERCENT,
          LINE.UNIT_LIST_PERCENT,
          LINE.AUTO_SELECTED_QUANTITY,
          LINE.TAX_RATE,
          LINE.SHIP_TOLERANCE_BELOW,
          LINE.SHIP_TOLERANCE_ABOVE,
          LINE.DELIVERY_LEAD_TIME,
          LINE.SHIPPING_QUANTITY,
          LINE.SERVICE_DURATION,
          LINE.FULFILLED_QUANTITY2,
          LINE.FULFILLED_QUANTITY,
          LINE.SHIPPED_QUANTITY2,
          LINE.SHIPPED_QUANTITY,
          LINE.TAX_VALUE TAX_VALUE,
          LINE.SHIPPING_QUANTITY2,
          LINE.PRICING_QUANTITY,
          LINE.UNIT_LIST_PRICE,
          LINE.CANCELLED_QUANTITY2,
          LINE.CANCELLED_QUANTITY,
          LINE.UNIT_SELLING_PRICE,
          LINE.INVOICED_QUANTITY,
          LINE.ORDERED_QUANTITY2,
          LINE.ORDERED_QUANTITY
     FROM HZ_PARTIES PARTY,
          HZ_CUST_ACCOUNTS CUST_ACCT,
          OE_ORDER_LINES_ALL LINE,
          OE_AGREEMENTS AGREE,
          OE_TRANSACTION_TYPES_TL lt,
          QP_LIST_HEADERS_TL PL,
          MTL_SYSTEM_ITEMS_VL ITEMS,
          MTL_UNITS_OF_MEASURE_TL UOM,
          MTL_UNITS_OF_MEASURE_TL UOM1,
          MTL_UNITS_OF_MEASURE_TL UOM2,
          MTL_UNITS_OF_MEASURE_TL UOM3
    WHERE     LINE.line_type_id = lt.transaction_type_id
          AND lt.language = USERENV ('LANG')
          AND LINE.agreement_id = agree.agreement_id(+)
          AND LINE.price_list_id = pl.list_header_id(+)
          AND pl.language(+) = USERENV ('LANG')
          AND LINE.sold_to_org_id = cust_acct.cust_account_id(+)
          AND PARTY.party_id(+) = cust_acct.party_id
          AND LINE.inventory_item_id = items.inventory_item_id(+)
          -- AND items.organization_id =
          --oe_sys_parameters.value('MASTER_ORGANIZATION_ID')
          AND LINE.order_quantity_uom = uom.uom_code(+)
          AND UOM.language(+) = USERENV ('LANG')
          AND LINE.ordered_quantity_uom2 = uom2.uom_code(+)
          AND UOM2.language(+) = USERENV ('LANG')
          AND LINE.pricing_quantity_uom = uom1.uom_code(+)
          AND UOM1.language(+) = USERENV ('LANG')
          AND LINE.shipping_quantity_uom2 = uom3.uom_code(+)
          AND UOM3.language(+) = USERENV ('LANG');


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_OE_ODR_LN_V FOR APPS.XX_BI_OE_ODR_LN_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_OE_ODR_LN_V FOR APPS.XX_BI_OE_ODR_LN_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_OE_ODR_LN_V FOR APPS.XX_BI_OE_ODR_LN_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_OE_ODR_LN_V FOR APPS.XX_BI_OE_ODR_LN_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_ODR_LN_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_ODR_LN_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_ODR_LN_V TO XXINTG;
