DROP VIEW APPS.XX_SFDC_ITEM_REPRO_DATE_V;

/* Formatted on 6/6/2016 4:58:04 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_SFDC_ITEM_REPRO_DATE_V
(
   REPROCESS_DATE
)
AS
     SELECT DISTINCT TRUNC (creation_date) reprocess_date
       FROM xx_sfdc_item_out_ctl
   ORDER BY reprocess_date DESC;
