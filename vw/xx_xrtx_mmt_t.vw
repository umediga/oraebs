DROP VIEW APPS.XX_XRTX_MMT_T;

/* Formatted on 6/6/2016 4:56:39 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_MMT_T
(
   TRANSACTION_DATE,
   TRANSACTION_TYPE_ID,
   TRANSACTION_ACTION_ID,
   TRANSACTION_SOURCE_TYPE_ID,
   ORGANIZATION_ID
)
AS
   SELECT transaction_date,
          transaction_type_id,
          transaction_action_id,
          transaction_source_type_id,
          organization_id
     FROM mtl_material_transactions mmt
    WHERE transaction_date BETWEEN TO_DATE (
                                      CONCAT (
                                         '01-JAN-',
                                         (TO_CHAR (SYSDATE, 'YYYY') - 3)),
                                      'DD-MON-YYYY')
                               AND SYSDATE;
