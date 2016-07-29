DROP VIEW APPS.XX_INTG_PERIOD_STATUS_V;

/* Formatted on 6/6/2016 4:58:25 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_INTG_PERIOD_STATUS_V
(
   PERIOD_NAME,
   PERIOD_YEAR,
   PERIOD_NUM,
   START_DATE
)
AS
     SELECT DISTINCT gl.period_name,
                     gl.period_year,
                     gl.period_num,
                     gl.start_date
       FROM gl_period_statuses gl, ar_system_parameters ar
      WHERE     gl.set_of_books_id = ar.set_of_books_id(+)
            AND gl.application_id = 222
            AND gl.closing_status IN ('C', 'O', 'P')
   ORDER BY gl.period_year, gl.period_num;
