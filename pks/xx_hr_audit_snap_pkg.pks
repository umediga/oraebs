DROP PACKAGE APPS.XX_HR_AUDIT_SNAP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_AUDIT_SNAP_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 08-Apr-2013
 File Name     : xx_hr_audit_snap.pks
 Description   : This script creates the specification of the package
                 xx_hr_audit_snap_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 08-Apr-2013 Renjith               Initial Version
*/
----------------------------------------------------------------------
TYPE G_XX_HR_PAYROLL_AUD_REC_TYPE IS RECORD
( PERSON_ID                  NUMBER,
  EMPLOYEE_NUMBER            VARCHAR2(30),
  LAST_NAME                  VARCHAR2(150),
  FIRST_NAME                 VARCHAR2(150),
  MIDDLE_NAMES               VARCHAR2(60),
  SEX                        VARCHAR2(30),
  TITLE                      VARCHAR2(30),
  DATE_OF_BIRTH              DATE,
  NATIONALITY                VARCHAR2(30),
  NATIONAL_IDENTIFIER        VARCHAR2(30),
  EMAIL_ADDRESS              VARCHAR2(240),
  TOWN_OF_BIRTH              VARCHAR2(90),
  MARITAL_STATUS             VARCHAR2(30),
  LOCATION_ID                NUMBER,
  LOCATION_ID_C              NUMBER,
  ASSIGNMENT_ID              NUMBER,
  SOFT_CODING_KEYFLEX_ID     NUMBER,
  SOFT_CODING_KEYFLEX_ID_T   NUMBER,
  SOFT_CODING_KEYFLEX_ID_S   NUMBER,
  SOFT_CODING_KEYFLEX_ID_W   NUMBER,
  SUPERVISOR_ID              NUMBER,
  SUPERVISOR_ID_N            NUMBER,
  ORGANIZATION_ID            NUMBER,
  DEFAULT_CODE_COMB_ID       NUMBER,
  DEFAULT_CODE_COMB_ID_D     NUMBER,
  DEFAULT_CODE_COMB_ID_P     NUMBER,
  DEFAULT_CODE_COMB_ID_R     NUMBER,
  JOB_ID                     NUMBER,
  PAYROLL_ID                 NUMBER,
  ASSIGNMENT_STATUS_TYPE_ID  NUMBER,
  NORMAL_HOURS               NUMBER,
  PAY_BASIS_ID               NUMBER,
  POSITION_ID                NUMBER,
  ASSIGNMENT_CATEGORY        VARCHAR2(30),
  FREQUENCY                  VARCHAR2(30),
  HOURLY_SALARIED_CODE       VARCHAR2(30),
  EMPLOYMENT_CATEGORY        VARCHAR2(30)
);


TYPE G_XX_HR_PAYROLL_AUD_TAB_TYPE IS TABLE OF G_XX_HR_PAYROLL_AUD_REC_TYPE
INDEX BY BINARY_INTEGER;

PROCEDURE snap_insert( p_errbuf    OUT   VARCHAR2
                      ,p_retcode   OUT   VARCHAR2);

END xx_hr_audit_snap_pkg;
/
