DROP PACKAGE APPS.XXINTG_HR_DATA_CHANGE_PKG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_HR_DATA_CHANGE_PKG" 
as
---------------------------------------------------------------------
/*
 Created By    : Jaya Maran
 Creation Date : 10-Mar-2014
 File Name     : xxintg_hr_data_change_pkg
 Description   : This code is being written to find out the HR Employee assignment changes

 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 10-Mar-2014 Shekhar N             Initial Version
*/
----------------------------------------------------------------------


PROCEDURE main ( p_errbuf            OUT   VARCHAR2
                  ,p_retcode           OUT   VARCHAR2
                );
PROCEDURE debug_log(p_text IN varchar2);

PROCEDURE process_data_changes (p_filename IN VARCHAR2);
PROCEDURE insert_staging_data (P_REQUEST_ID  NUMBER
,P_PERSON_ID  NUMBER
,P_EMPLOYEE_NUMBER varchar2
,P_FULL_NAME varchar2
,P_POSITION_ID number
,P_POSITION_NAME varchar2
,P_ORGANIZATION_ID number
,P_ORGANIZATION_NAME varchar2
,P_LOCATION_ID number
,P_LOCATION_NAME VARCHAR2
,P_JOB_ID NUMBER
,P_JOB_NAME VARCHAR2
,P_COST_STRING varchar2
,P_SUPERVISOR_ID number
,P_SUPERVISOR_NAME varchar2
,P_SUPERVISOR_POSITION_ID varchar2
,P_SUPERVISOR_POSITION_NAME varchar2
,P_CHANGE_TYPE varchar2
,P_CREATED_BY number
,P_CREATION_DATE date
,P_LAST_UPDATE_DATE date
,P_LAST_UPDATED_BY number
);
end xxintg_hr_data_change_pkg;
/
