DROP VIEW APPS.XX_HALOGEN_USER_MAP;

/* Formatted on 6/6/2016 4:58:37 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_HALOGEN_USER_MAP
(
   ATTRIBUTE1,
   EMP_NUMBER_11I,
   USER_NAME,
   EMAIL_ADDRESS,
   FIRST_NAME,
   LAST_NAME,
   PASSWORD,
   HIRE_DATE,
   JOB_TITLE,
   DEPARTMENT,
   SUPERVISOR_ID,
   HR_REP,
   LOCATION_CODE,
   EMPLOYEE_NUMBER,
   COUNTRY
)
AS
   SELECT b.ATTRIBUTE1,
          SUBSTR (b.attribute1, INSTR (b.attribute1, '_') + 1) emp_number_11i,
          a."USER_NAME",
          a."EMAIL_ADDRESS",
          a."FIRST_NAME",
          a."LAST_NAME",
          a."PASSWORD",
          a."HIRE_DATE",
          a."JOB_TITLE",
          a."DEPARTMENT",
          a."SUPERVISOR_ID",
          a."HR_REP",
          a."LOCATION_CODE",
          a."EMPLOYEE_NUMBER",
          a."COUNTRY"
     FROM xx_hr_halogen_v a, per_people_x b
    WHERE a.EMPLOYEE_NUMBER = b.EMPLOYEE_NUMBER;
