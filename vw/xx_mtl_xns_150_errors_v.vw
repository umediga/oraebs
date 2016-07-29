DROP VIEW APPS.XX_MTL_XNS_150_ERRORS_V;

/* Formatted on 6/6/2016 4:58:24 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_MTL_XNS_150_ERRORS_V
(
   TRANSACTION_TYPE_NAME,
   ERROR_EXPLANATION,
   RECORD_COUNT
)
AS
     SELECT b.TRANSACTION_TYPE_NAME,
            error_explanation,
            COUNT (a.transaction_interface_id) record_count
       FROM mtl_transactions_interface a, mtl_transaction_types b --, oe_order_headers_all c, oe_order_lines_all d
      WHERE     (transfer_organization = 2103 OR organization_id = 2103)
            AND a.TRANSACTION_TYPE_ID = b.transaction_type_id(+)
   GROUP BY b.TRANSACTION_TYPE_NAME, error_explanation
   ORDER BY COUNT (a.transaction_interface_id) DESC;
