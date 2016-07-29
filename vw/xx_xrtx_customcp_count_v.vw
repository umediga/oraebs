DROP VIEW APPS.XX_XRTX_CUSTOMCP_COUNT_V;

/* Formatted on 6/6/2016 4:56:44 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_CUSTOMCP_COUNT_V
(
   APPLICATION_NAME,
   USER_EXECUTABLE_NAME,
   EXECUTABLE_NAME,
   EXECUTION_FILE_NAME,
   EXECUTABLE_TYPE,
   CONCURRENT_PROGRAM_NAME,
   DESCRIPTION,
   ENABLED_FLAG,
   CONCURRENT_PROGRAM_ID,
   APPLICATION_ID
)
AS
   SELECT /*- ================================================================================
          -- FILE NAME            :
          -- AUTHOR               : Wipro Technologies
          -- DATE CREATED         : 28-JAN-2012
          -- DESCRIPTION          :
          -- RICE COMPONENT ID    :
          -- R11i10 OBJECT NAME   :
          -- R12 OBJECT NAME      : XX_XRTX_CUSTOMCP_COUNT_V
          -- REVISION HISTORY     :
          -- =================================================================================
          --  Version  Person                 Date          Comments
          --  -------  --------------         -----------   ------------
          --  1.0      Anirudh Kumar          28-JAN-2013   Initial Version.
          -- =================================================================================*/
         fef.application_name,
          fef.user_executable_name,
          fef.executable_name,
          fef.execution_file_name,
          flv.meaning "EXECUTABLE_TYPE",
          fcp.concurrent_program_name,
          fcpt.description,
          fcp.enabled_flag,
          fcp.concurrent_program_id,
          fef.application_id
     FROM fnd_concurrent_programs fcp,
          fnd_executables_form_v fef,
          fnd_lookup_values flv,
          fnd_application_tl fat,
          fnd_concurrent_programs_tl fcpt
    WHERE     fcp.concurrent_program_name LIKE 'XX%'
          AND fcp.executable_id = fef.executable_id
          AND fef.executable_name LIKE 'XX%'
          AND flv.lookup_type = 'CP_EXECUTION_METHOD_CODE'
          AND flv.lookup_code = fef.execution_method_code
          AND flv.enabled_flag = 'Y'
          AND flv.LANGUAGE = 'US'
          AND fat.LANGUAGE = 'US'
          AND fcpt.LANGUAGE = 'US'
          AND fat.application_id = fcp.application_id
          --   AND fcp.application_id = fef.application_id
          AND fcpt.concurrent_program_id = fcp.concurrent_program_id;
