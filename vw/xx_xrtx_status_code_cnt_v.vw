DROP VIEW APPS.XX_XRTX_STATUS_CODE_CNT_V;

/* Formatted on 6/6/2016 4:54:07 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_STATUS_CODE_CNT_V
(
   USER_CONCURRENT_PROGRAM_NAME,
   CONCURRENT_PROGRAM_NAME,
   CONCURRENT_PROGRAM_ID,
   ACTUAL_START_DATE,
   TERMINATED,
   CANCELLED,
   WARNING,
   ERROR,
   NORMAL,
   NORMAL_1
)
AS
   SELECT b.user_concurrent_program_name,
          a.concurrent_program_name,
          a.concurrent_program_id,
          d.actual_start_date,
          CASE WHEN d.status_code = 'X' THEN 1 END "TERMINATED",
          CASE WHEN d.status_code = 'D' THEN 1 END "CANCELLED",
          CASE WHEN d.status_code = 'G' THEN 1 END "WARNING",
          CASE WHEN d.status_code = 'E' THEN 1 END "ERROR",
          CASE WHEN d.status_code = 'C' THEN 1 END "NORMAL",
          CASE WHEN d.status_code = 'I' THEN 1 END "NORMAL_1"
     FROM xx_xrtx_all_cp_t a,
          fnd_concurrent_programs_tl b,
          fnd_lookup_values c,
          fnd_concurrent_requests d
    WHERE     a.CONCURRENT_PROGRAM_ID = b.concurrent_program_id
          AND d.concurrent_program_id = b.concurrent_program_id
          AND c.lookup_code = d.status_code
          AND c.lookup_type = 'CP_STATUS_CODE'
          AND c.language = 'US'
          AND c.start_date_active IS NOT NULL;
