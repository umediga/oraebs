DROP VIEW APPS.XX_TEMP_PROGRAM_TIMINGS;

/* Formatted on 6/6/2016 4:58:02 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_TEMP_PROGRAM_TIMINGS
(
   APPLICATION_NAME,
   CONCURRENT_PROGRAM_NAME,
   CONCURRENT_PROGRAM_ID,
   EXECUTABLE_TYPE,
   ACTUAL_COMPLETION_DATE,
   ACTUAL_START_DATE,
   TIME_TAKEN,
   BUCKET
)
AS
     SELECT /*- ================================================================================
            -- FILE NAME            :
            -- AUTHOR               : Wipro Technologies
            -- DATE CREATED         : 28-JAN-2012
            -- DESCRIPTION          :
            -- RICE COMPONENT ID    :
            -- R11i10 OBJECT NAME   :
            -- R12 OBJECT NAME      : XX_XRTX_CUSTOMDB_V
            -- REVISION HISTORY     :
            -- =================================================================================
            --  Version  Person                 Date          Comments
            --  -------  --------------         -----------   ------------
            --  1.0      Anirudh Kumar          28-JAN-2013   Initial Version.
            -- =================================================================================*/
           xtcp.application_name,
            xtcp.concurrent_program_name,
            xtcp.CONCURRENT_PROGRAM_ID,
            xtcp.executable_type,
            fcr.actual_completion_date,
            fcr.actual_start_date,
            ROUND (
               (fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60,
               2)
               TIME_TAKEN,
            ROUND (
               (fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60)
               BUCKET
       FROM fnd_concurrent_requests fcr, xx_temp_concurrent_programs xtcp
      WHERE     actual_completion_date IS NOT NULL
            AND actual_start_date IS NOT NULL
            AND fcr.concurrent_program_id = xtcp.concurrent_program_id
   ORDER BY 3 DESC;
