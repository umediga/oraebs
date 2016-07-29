DROP PACKAGE APPS.XX_HR_APPL_CNV_VALIDATION_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_APPL_CNV_VALIDATION_PKG" AUTHID CURRENT_USER AS

----------------------------------------------------------------------------------
/* $Header: XXHRAPPLCONV.pks 1.0 2012/02/20 12:00:00 Damd noship $ */
/*
Created By    : IBM Development Team
Creation Date : 20-Feb-2012
File Name     : XXHRAPPLCONV.pks
Description   : This script creates the specification for the Applicant Conversion

Change History:

Version Date        Name                   Remarks
------- ----------- -------------------    ----------------------
1.0     20-Feb-12   IBM Development Team   Initial development.
2.0     16-May-12   Dinesh                 Included unique Id during mock conv
3.0     17-Apr-13   Dinesh                 Included manager columns in applicant stg rec type 
                       and constant for resume bulk collect
*/
----------------------------------------------------------------------
   
   -- Global Variables
    G_STAGE        VARCHAR2(2000);
    G_BATCH_ID        VARCHAR2(200);
    G_COMP_BATCH_ID    VARCHAR2(200);
    G_VALIDATE_AND_LOAD    VARCHAR2(100) := 'VALIDATE_AND_LOAD';
    
    g_resume_bulk_limit NUMBER :=250;
    
    g_api_name        VARCHAR2(200);
    
    g_transaction_type    VARCHAR2(10) := 'CREATE';

    g_process_flag    NUMBER := 1; 
    
    g_applicant_person_type VARCHAR2(30) := 'APPLICANT';
    
    g_validate_flag_for_api BOOLEAN := TRUE;
    
  TYPE G_XX_APPLICANT_STG_REC_TYPE  IS RECORD 
    (   BATCH_ID            VARCHAR2(200),
        RECORD_NUMBER                    NUMBER ,
        UNIQUE_ID                       VARCHAR2(50),
        BUSINESS_GROUP_NAME             VARCHAR2(50),
        BUSINESS_GROUP_ID            NUMBER,
        FIRST_NAME                       VARCHAR2(100),
        MIDDLE_NAME                    VARCHAR2(50),
        LAST_NAME                        VARCHAR2(100),
        FULL_NAME                    VARCHAR2(200),
        PERSON_ID                    NUMBER,
        USER_PERSON_TYPE            VARCHAR2(30),
        PERSON_TYPE_ID                    NUMBER,
        APPLICANT_SOURCE            VARCHAR2(30),
        SOURCE_TYPE                    VARCHAR2(50),
        APPLICANT_STATUS            VARCHAR2(50),
        ASSIGNMENT_STATUS_TYPE_ID    NUMBER,
        RECRUITER                    VARCHAR2(50),
        RECRUITER_ID                    NUMBER,
        REFERRED_BY                    VARCHAR2(30),
        REFERRED_BY_ID                    NUMBER,
        VACANCY_NUMBER                    VARCHAR2(20),
        VACANCY_ID                    NUMBER,
        APPLICATION_DATE            DATE,
        PER_OBJECT_VERSION_NUMBER    NUMBER,
        PROCESS_CODE                    VARCHAR2(100),
        ERROR_CODE                      VARCHAR2(240), 
        ERROR_TYPE                        NUMBER,         
        ERROR_EXPLANATION                 VARCHAR2(240),  
        ERROR_FLAG                        VARCHAR2(1),
        ERROR_MESG                        VARCHAR2(2000),
        PROGRAM_APPLICATION_ID          NUMBER,
        PROGRAM_ID                      NUMBER,
        PROGRAM_UPDATE_DATE             DATE,
        PROCESS_FLAG                      NUMBER,
        CREATION_DATE                   DATE,
        CREATED_BY                      NUMBER,
        LAST_UPDATE_DATE                DATE,
        LAST_UPDATED_BY                 NUMBER,
        LAST_UPDATE_LOGIN               NUMBER,
        REQUEST_ID                      NUMBER     
        -- Manager details Added for May 2013 global HR release
    ,MANAGER_UNIQUE_ID               VARCHAR2(50),
        MANAGER_PERSON_ID               NUMBER
   );


  -- Applicant Staging Table Type
  TYPE g_xx_applicant_tab_type IS TABLE OF G_XX_APPLICANT_STG_REC_TYPE 
     INDEX BY BINARY_INTEGER;



   TYPE G_XX_PHONE_STG_REC_TYPE  IS RECORD 
    (   BATCH_ID            VARCHAR2(200),
        RECORD_NUMBER                    NUMBER,
        UNIQUE_ID                       VARCHAR2(50),
        BUSINESS_GROUP_NAME             VARCHAR2(50),
        BUSINESS_GROUP_ID            NUMBER,
        FIRST_NAME                       VARCHAR2(100),
        MIDDLE_NAME                    VARCHAR2(50),
        LAST_NAME                        VARCHAR2(100),
        FULL_NAME                    VARCHAR2(200),
        PERSON_ID                    NUMBER,
        PHONE_EFFECTIVE_DATE            DATE,
        PHONE_TYPE                      VARCHAR2(240),
        PHONE_TYPE_CODE                 VARCHAR2(240),
        PHONE_NUMBER                    VARCHAR2(240),
        PER_OBJECT_VERSION_NUMBER    NUMBER,
        PHONE_ID                        NUMBER,
        PROCESS_CODE                    VARCHAR2(100),
        ERROR_CODE                      VARCHAR2(240), 
        ERROR_TYPE                        NUMBER,         
        ERROR_EXPLANATION                 VARCHAR2(240),  
        ERROR_FLAG                        VARCHAR2(1),
        ERROR_MESG                        VARCHAR2(2000),
        PROGRAM_APPLICATION_ID          NUMBER,
        PROGRAM_ID                      NUMBER,
        PROGRAM_UPDATE_DATE             DATE,
        PROCESS_FLAG                      NUMBER,
        CREATION_DATE                   DATE,
        CREATED_BY                      NUMBER,
        LAST_UPDATE_DATE                DATE,
        LAST_UPDATED_BY                 NUMBER,
        LAST_UPDATE_LOGIN               NUMBER,
        REQUEST_ID                      NUMBER    
   );


  -- Phone Staging Table Type
  TYPE g_xx_phone_tab_type IS TABLE OF G_XX_PHONE_STG_REC_TYPE 
     INDEX BY BINARY_INTEGER;


  TYPE G_XX_RESUME_STG_REC_TYPE  IS RECORD 
    (   BATCH_ID            VARCHAR2(200),
        RECORD_NUMBER                    NUMBER,
        UNIQUE_ID                       VARCHAR2(50),
        BUSINESS_GROUP_NAME             VARCHAR2(50),
        BUSINESS_GROUP_ID            NUMBER,
        FIRST_NAME                       VARCHAR2(100),
        MIDDLE_NAME                    VARCHAR2(50),
        LAST_NAME                        VARCHAR2(100),
        PERSON_ID                    NUMBER,
        DOCUMENT_EFFECTIVE_DATE         DATE,
        DOCUMENT_TYPE                   VARCHAR2(240),
        DOCUMENT_ID                     NUMBER,
        DOCUMENT_FILE_NAME              VARCHAR2(1000),
        DOCUMENT_DESCRIPTION            VARCHAR2(1000),
        DOCUMENT_LOCATION               VARCHAR2(1000),
        OBJECT_VERSION_NUMBER           NUMBER,
        ASSIGNMENT_ID                   NUMBER,
        PROCESS_CODE                    VARCHAR2(100),
        ERROR_CODE                      VARCHAR2(240), 
        ERROR_TYPE                        NUMBER,         
        ERROR_EXPLANATION                 VARCHAR2(240),  
        ERROR_FLAG                        VARCHAR2(1),
        ERROR_MESG                        VARCHAR2(2000),
        PROGRAM_APPLICATION_ID          NUMBER,
        PROGRAM_ID                      NUMBER,
        PROGRAM_UPDATE_DATE             DATE,
        PROCESS_FLAG                      NUMBER,
        CREATION_DATE                   DATE,
        CREATED_BY                      NUMBER,
        LAST_UPDATE_DATE                DATE,
        LAST_UPDATED_BY                 NUMBER,
        LAST_UPDATE_LOGIN               NUMBER,
        REQUEST_ID                      NUMBER      
   );


  -- Resume Staging Table Type
  TYPE g_xx_resume_tab_type IS TABLE OF G_XX_RESUME_STG_REC_TYPE 
     INDEX BY BINARY_INTEGER;
   
      
   PROCEDURE main(x_errbuf   OUT VARCHAR2
                                ,x_retcode  OUT VARCHAR2
                                ,p_batch_id      IN  VARCHAR2
                                ,p_restart_flag   IN VARCHAR2
                                ,p_validate_and_load     IN VARCHAR2);                                                                                 
 
END xx_hr_appl_cnv_validation_pkg; 
/
