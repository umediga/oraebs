DROP VIEW APPS.XXOIC_PAY_RUN_V;

/* Formatted on 6/6/2016 5:00:08 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXOIC_PAY_RUN_V
(
   NAME,
   PAYRUN_ID,
   CREATION_DATE
)
AS
     SELECT name, payrun_id, creation_date
       FROM cn_payruns
   ORDER BY creation_date DESC;
