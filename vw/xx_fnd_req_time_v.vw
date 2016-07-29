DROP VIEW APPS.XX_FND_REQ_TIME_V;

/* Formatted on 6/6/2016 4:58:39 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_FND_REQ_TIME_V
(
   REQUEST_ID,
   EXEC_TIME_IN_MINUTES,
   START_DATE,
   CONC_PROG,
   USER_CONC_PROG
)
AS
     SELECT fcr.request_id request_id,
            TRUNC (
                 (  (fcr.actual_completion_date - fcr.actual_start_date)
                  / (1 / 24))
               * 60)
               exec_time_in_minutes,
            fcr.actual_start_date start_date,
            fcp.concurrent_program_name conc_prog,
            fcpt.user_concurrent_program_name user_conc_prog
       FROM apps.fnd_concurrent_programs fcp,
            apps.fnd_concurrent_programs_tl fcpt,
            apps.fnd_concurrent_requests fcr
      WHERE     TRUNC (
                     (  (fcr.actual_completion_date - fcr.actual_start_date)
                      / (1 / 24))
                   * 60) > 5
            AND fcr.concurrent_program_id = fcp.concurrent_program_id
            AND fcr.program_application_id = fcp.application_id
            AND fcr.concurrent_program_id = fcpt.concurrent_program_id
            AND fcr.program_application_id = fcpt.application_id
            AND fcpt.LANGUAGE = USERENV ('Lang')
            --and fcpt.user_concurrent_program_name like 'INTG%'
            AND fcr.actual_start_date >= SYSDATE - 3
            AND fcr.status_code = 'C'
            AND fcr.phase_code = 'C'
   ORDER BY TRUNC (
                 (  (fcr.actual_completion_date - fcr.actual_start_date)
                  / (1 / 24))
               * 60) DESC;
