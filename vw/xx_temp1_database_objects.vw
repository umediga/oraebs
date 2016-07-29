DROP VIEW APPS.XX_TEMP1_DATABASE_OBJECTS;

/* Formatted on 6/6/2016 4:58:02 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_TEMP1_DATABASE_OBJECTS
(
   OWNER,
   OBJECT_NAME,
   STATUS,
   OBJECT_TYPE,
   CREATED,
   LAST_DDL_TIME,
   TIMESTAMP
)
AS
   SELECT owner,
          object_name,
          status,
          object_type,
          created,
          last_ddl_time,
          TIMESTAMP
     FROM all_objects
    WHERE     object_name LIKE 'XX%'
          AND object_type <> 'PACKAGE BODY'
          AND object_name NOT LIKE 'XX_XRTX%'
          AND object_name <> 'XX_TEMP1_DATABASE_OBJECTS'
          AND object_name <> 'XX_TEST1'
          AND object_name <> 'XX_TEMP_CONCURRENT_PROGRAMS'
          AND object_name <> 'XX_TEMP_PROFILE'
          AND object_name <> 'XX_TEMP_PROFILE_VALUES'
          AND object_name <> 'BUSINESSUSAGE'
          AND object_name <> 'TASKTYPE'
          AND object_name <> 'XX_COA_LOAD_TABLE_P'
          AND object_name <> 'XX_COA_STRUCTURE'
          AND object_name <> 'XX_COA_USER'
          AND object_name <> 'XX_TEMP_PROGRAM_TIMINGS'
          AND object_name <> 'XX_TEMP_PROGRAM_TIMING_BUCKETS'
          AND object_name <> 'XXUSR_ACCESS_RESP_WISE_V'
          AND object_name <> 'XXUSR_ACCESS_APPL_WISE_V'
          AND object_name <> 'XX_XRTS_API_LIST_DETAILS'
          AND object_name <> 'XX_XTRX_CUST_WF_EXEC_T'
          AND object_name <> 'XX_XTRX_CUS_ALERTS_MASTER_T'
          AND object_name <> 'XX_XTRX_HOUR_USR_ANALYSIS_T'
          AND object_name <> 'XX_XTRX_HR_USR_ANALYSIS_T';
