DROP VIEW APPS.XX_WSH_ORDERS_WS_V;

/* Formatted on 6/6/2016 4:57:57 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_WSH_ORDERS_WS_V
(
   PUBLISH_BATCH_ID,
   DELIVERY_ID,
   CONTAINER_INSTANCE_ID,
   ORDER_HEADER_ID,
   SOURCE_CODE,
   SALES_ORDER_NUMBER,
   SALES_ORDER_DATE,
   ORDER_TYPE_INT,
   ORDER_CATEGORY_CODE,
   CUSTOMER_REQUEST_DATE,
   ORDER_DATE_TYPE_CODE,
   PARTIAL_SHIPMENTS_ALLOWED,
   FOB_PAYMENT_METHOD_CODE_INT,
   TAX_EXEMPT_FLAG,
   TAX_EXEMPT_NUMBER,
   TAX_EXEMPT_REASON_CODE_INT,
   CURRENCY_CONVERSION_TYPE_CODE,
   CURRENCY_CONVERSION_DATE,
   CURRENCY_CONVERSION_RATE,
   PAYMENT_AMOUNT,
   ORDER_HEADER_CONTEXT,
   ORDER_HEADER_ATTRIBUTE1,
   ORDER_HEADER_ATTRIBUTE2,
   ORDER_HEADER_ATTRIBUTE3,
   ORDER_HEADER_ATTRIBUTE4,
   ORDER_HEADER_ATTRIBUTE5,
   ORDER_HEADER_ATTRIBUTE6,
   ORDER_HEADER_ATTRIBUTE7,
   ORDER_HEADER_ATTRIBUTE8,
   ORDER_HEADER_ATTRIBUTE9,
   ORDER_HEADER_ATTRIBUTE10,
   ORDER_HEADER_ATTRIBUTE11,
   ORDER_HEADER_ATTRIBUTE12,
   ORDER_HEADER_ATTRIBUTE13,
   ORDER_HEADER_ATTRIBUTE14,
   ORDER_HEADER_ATTRIBUTE15,
   ORDER_HEADER_TP_CONTEXT,
   PURCHASE_ORDER_NUMBER,
   FOB_POINT_CODE_INT,
   FREIGHT_TERMS_CODE_INT,
   TRANSACTIONAL_CURRENCY_CODE,
   ORIG_SYS_DOCUMENT_REF,
   RELEASE_NUMBER,
   ADDITIONAL_ATTRIBUTE1,
   ADDITIONAL_ATTRIBUTE2,
   ADDITIONAL_ATTRIBUTE3,
   ADDITIONAL_ATTRIBUTE4,
   ADDITIONAL_ATTRIBUTE5
)
AS
   SELECT DISTINCT NULL publish_batch_id,
                   wda.delivery_id delivery_id --, wda.parent_delivery_detail_id container_instance_id
                                              ,
                   wda.delivery_id container_instance_id -- Modified on 2013-02-06 for Salesforce Case# 001808
                                                        ,
                   wdd.source_header_id order_header_id,
                   wdd.source_code source_code,
                   TO_CHAR (oeh.order_number) sales_order_number,
                   oeh.ordered_date sales_order_date,
                   oet.NAME order_type_int,
                   oeh.order_category_code order_category_code,
                   oeh.request_date customer_request_date,
                   oeh.order_date_type_code order_date_type_code,
                   oeh.partial_shipments_allowed partial_shipments_allowed,
                   oeh.payment_type_code fob_payment_method_code_int,
                   oeh.tax_exempt_flag tax_exempt_flag,
                   oeh.tax_exempt_number tax_exempt_number,
                   oeh.tax_exempt_reason_code tax_exempt_reason_code_int,
                   oeh.conversion_type_code currency_conversion_type_code,
                   oeh.conversion_rate_date currency_conversion_date,
                   oeh.conversion_rate currency_conversion_rate,
                   oeh.payment_amount payment_amount,
                   oeh.CONTEXT order_header_context,
                   oeh.attribute1 order_header_attribute1,
                   oeh.attribute2 order_header_attribute2,
                   oeh.attribute3 order_header_attribute3,
                   oeh.attribute4 order_header_attribute4,
                   oeh.attribute5 order_header_attribute5,
                   oeh.attribute6 order_header_attribute6,
                   oeh.attribute7 order_header_attribute7,
                   oeh.attribute8 order_header_attribute8,
                   oeh.attribute9 order_header_attribute9,
                   oeh.attribute10 order_header_attribute10,
                   oeh.attribute11 order_header_attribute11,
                   oeh.attribute12 order_header_attribute12,
                   oeh.attribute13 order_header_attribute13,
                   oeh.attribute14 order_header_attribute14,
                   oeh.attribute15 order_header_attribute15,
                   oeh.tp_context order_header_tp_context,
                   oeh.cust_po_number purchase_order_number,
                   oeh.fob_point_code fob_point_code_int,
                   oeh.freight_terms_code freight_terms_code_int,
                   oeh.transactional_curr_code transactional_currency_code,
                   oeh.orig_sys_document_ref orig_sys_document_ref --, decode (orig_sys_document_ref, (select orig_sys_document_ref from dual
 --  where orig_sys_document_ref like '%GXS%'), substr(orig_sys_document_ref, -11), NULL) orig_sys_document_ref
                   ,
                   oeh.tp_attribute7 release_number,
                   NULL additional_attribute1,
                   NULL additional_attribute2,
                   NULL additional_attribute3,
                   NULL additional_attribute4,
                   NULL additional_attribute5
     FROM wsh_delivery_assignments_v wda,
          wsh_delivery_details wdd,
          oe_order_headers_all oeh,
          oe_order_sources oos,
          oe_transaction_types_tl oet
    WHERE     wda.delivery_detail_id = wdd.delivery_detail_id
          AND wdd.container_flag = 'N'
          AND NVL (wdd.shipped_quantity, 0) > 0
          AND wda.delivery_id IS NOT NULL
          AND wdd.source_code = 'OE'
          AND wdd.source_header_id = oeh.header_id
          AND oeh.order_type_id = oet.transaction_type_id
          AND oeh.order_source_id = oos.order_source_id
          AND oos.name = ANY ('EDIGHX', 'EDIGXS')
          AND oet.LANGUAGE = USERENV ('LANG');


GRANT SELECT ON APPS.XX_WSH_ORDERS_WS_V TO XXAPPSREAD;
