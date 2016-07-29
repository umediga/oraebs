DROP PACKAGE APPS.XXINTG_HR_POS_HIERARCHY_PKG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_HR_POS_HIERARCHY_PKG" 
IS
   PROCEDURE debug_log (p_text IN VARCHAR2);

   

   PROCEDURE insert_staging_data (P_REQUEST_ID                  NUMBER,
                                  P_PERSON_ID                   NUMBER,
                                  P_EMPLOYEE_NUMBER             VARCHAR2,
                                  P_FULL_NAME                   VARCHAR2,
                                  P_POSITION_ID                 NUMBER,
                                  P_POSITION_NAME               VARCHAR2,
                                  P_ORGANIZATION_ID             NUMBER,
                                  P_ORGANIZATION_NAME           VARCHAR2,
                                  P_COST_STRING                 VARCHAR2,
                                  P_SUPERVISOR_ID               NUMBER,
                                  P_SUPERVISOR_NAME             VARCHAR2,
                                  P_SUPERVISOR_POSITION_ID      VARCHAR2,
                                  P_SUPERVISOR_POSITION_NAME    VARCHAR2,
                                  P_CHANGE_TYPE                 VARCHAR2,
                                  P_CREATED_BY                  NUMBER,
                                  P_CREATION_DATE               DATE,
                                  P_LAST_UPDATE_DATE            DATE,
                                  P_LAST_UPDATED_BY             NUMBER);
                                  
  PROCEDURE process_data_changes;                                

   PROCEDURE CREATE_POS_HIER_PROC (p_parent_pos VARCHAR2, p_sub_pos VARCHAR2,FLAG OUT VARCHAR2);

   PROCEDURE UPDATE_SUP_POS_CHANGED (
      P_NEW_PARENT_POSITION_NAME     VARCHAR2,
      P_SUBORDINATE_POSITION_NAME    VARCHAR2,FLAG OUT VARCHAR2);
      
 PROCEDURE XX_GEN_XLS_SUP;

 FUNCTION NUM_OF_SUB( p_emp_number varchar2) return number;
  
   PROCEDURE main (p_errbuf OUT VARCHAR2, P_RETCODE OUT VARCHAR2);
   

END; 
/
