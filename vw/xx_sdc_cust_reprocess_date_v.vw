DROP VIEW APPS.XX_SDC_CUST_REPROCESS_DATE_V;

/* Formatted on 6/6/2016 4:58:10 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_SDC_CUST_REPROCESS_DATE_V
(
   CREATION_DATE
)
AS
   SELECT TO_CHAR (creation_date, 'DD-MON-YYYY') creation_date
     FROM (  SELECT DISTINCT TRUNC (creation_date) creation_date
               FROM xx_sdc_customer_publish_stg
              WHERE NVL (status, 'NEW') <> 'SUCCESS'
           ORDER BY creation_date DESC);
