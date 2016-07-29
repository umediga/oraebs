DROP PACKAGE APPS.XX_HR_SIT_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_SIT_CONVERSION_PKG" AS
/* $Header: XXHRSITCNV.pks 1.0.0 2012/03/07 00:00:00$ */
--=============================================================================
  -- Created By     : Arjun.K
  -- Creation Date  : 07-MAR-2012
  -- Filename       : XXHRSITCNV.pks
  -- Description    : Package specification for emloyee SIT conversion.

  -- Change History:

  -- Date          Version#    Name                Remarks
  -- -----------   --------    ---------------     ----------------------------
  -- 07-MAR-2012   1.0         Arjun.K             Initial Development.
--=============================================================================

   -- Global Variables
   G_STAGE                        VARCHAR2(2000);
   G_BATCH_ID                     VARCHAR2(200);
   G_COMP_BATCH_ID                VARCHAR2(200);
   G_VALIDATE_AND_LOAD            VARCHAR2(100) := 'VALIDATE_AND_LOAD';
   G_VALIDATE_FLAG                BOOLEAN       := TRUE;
   G_REQUEST_ID                   NUMBER        := fnd_profile.value('CONC_REQUEST_ID');
   G_USER_ID                      NUMBER        := fnd_global.user_id;
   G_RESP_ID                      NUMBER        := fnd_profile.VALUE('RESP_ID');
   G_API_NAME                     VARCHAR2(200);
   G_ACCOUNTING_FLEX              VARCHAR2 (150) := 'INTG_US_HISTORY';--'INTG_EMP_EXEMP_ASG_HIST';

   g_process_flag                 NUMBER := 1;

   TYPE g_xxhr_sit_stg_rec_type  IS RECORD
        (employee_number          VARCHAR2(150)
        ,unique_id                VARCHAR2(150)
        ,date_from                DATE
        ,date_to                  DATE
        ,location                 VARCHAR2(150)
        ,job_title                VARCHAR2(150)
        ,organization             VARCHAR2(150)
        ,supervisor_name          VARCHAR2(150)
        ,incentive_level          VARCHAR2(150)
        ,salary_basis             VARCHAR2(150)
        ,exit_reason              VARCHAR2(150)
        ,status                   VARCHAR2(150)
        ,assignment_category      VARCHAR2(150)
        ,reason                   VARCHAR2(150)
        ,business_group_id        NUMBER
        ,person_id                NUMBER
        ,id_flex_num              NUMBER
        ,batch_id                 VARCHAR2(150)
        ,record_number            NUMBER
        ,process_code             VARCHAR2(100)
        ,error_code               VARCHAR2(100)
        ,created_by               NUMBER
        ,creation_date            DATE
        ,last_update_date         DATE
        ,last_updated_by          NUMBER
        ,last_update_login        NUMBER
        ,request_id               NUMBER
        ,program_application_id   NUMBER
        ,program_id               NUMBER
        ,program_update_date      DATE
        );

   -- Employee SIT Staging Table Type
   TYPE g_xxhr_sit_stg_tab_type IS TABLE OF g_xxhr_sit_stg_rec_type
   INDEX BY BINARY_INTEGER;

   PROCEDURE main(x_errbuf              OUT   VARCHAR2
                 ,x_retcode             OUT   VARCHAR2
                 ,p_batch_id            IN    VARCHAR2
                 ,p_restart_flag        IN    VARCHAR2
                 ,p_validate_and_load   IN    VARCHAR2
                 );

END xx_hr_sit_conversion_pkg;
/
