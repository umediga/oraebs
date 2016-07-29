DROP VIEW APPS.XX_PL_SFDC_CONTROL_DATE_V;

/* Formatted on 6/6/2016 4:58:16 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_PL_SFDC_CONTROL_DATE_V
(
   LAST_RUN_DATE
)
AS
     SELECT DISTINCT TRUNC (last_update_date) last_run_date
       FROM xx_price_list_sfdc_control
   ORDER BY TRUNC (last_update_date);
