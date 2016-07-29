DROP VIEW APPS.XX_XRTX_SOURCE_DAILY_V;

/* Formatted on 6/6/2016 4:54:11 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_SOURCE_DAILY_V
(
   TRANSACTION_DAY,
   SOURCE_TYPE,
   ORG_NAME,
   YEAR,
   SOURCE_TYPE_COUNT
)
AS
     SELECT TO_NUMBER (TO_CHAR (transaction_date, 'D')) transaction_day,
            mtst.transaction_source_type_name source_type,
            ood.ORGANIZATION_NAME ORG_NAME,
            TO_CHAR (mmt.transaction_date, 'YYYY') YEAR,
            COUNT (mmt.TRANSACTION_SOURCE_TYPE_ID) source_type_count
       FROM xx_xrtx_mmt_t mmt,
            MTL_TXN_SOURCE_TYPES mtst,
            org_organization_definitions ood
      WHERE     mmt.transaction_date BETWEEN TO_DATE (
                                                CONCAT (
                                                   '01-JAN-',
                                                   (  TO_CHAR (SYSDATE, 'YYYY')
                                                    - 3)),
                                                'DD-MON-YYYY')
                                         AND SYSDATE
            AND mmt.organization_id = ood.organization_id
            AND mmt.transaction_source_type_id =
                   mtst.TRANSACTION_SOURCE_TYPE_ID
   GROUP BY TO_CHAR (transaction_date, 'D'),
            mtst.transaction_source_type_name,
            ood.ORGANIZATION_NAME,
            TO_CHAR (mmt.transaction_date, 'YYYY');
