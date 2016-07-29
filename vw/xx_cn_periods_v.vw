DROP VIEW APPS.XX_CN_PERIODS_V;

/* Formatted on 6/6/2016 4:58:47 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_CN_PERIODS_V
(
   ORG_ID,
   PERIOD_YEAR,
   START_PERIOD_ID,
   END_PERIOD_ID
)
AS
     SELECT org_id,
            period_year,
            MIN (period_id) start_period_id,
            MAX (period_id) end_period_id
       FROM cn_period_statuses_all
      WHERE     TO_NUMBER (TO_CHAR (TRUNC (SYSDATE), 'YYYY')) = period_year
            AND forecast_flag = 'N'
   GROUP BY org_id, period_year
   ORDER BY org_id;
