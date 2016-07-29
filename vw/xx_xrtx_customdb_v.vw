DROP VIEW APPS.XX_XRTX_CUSTOMDB_V;

/* Formatted on 6/6/2016 4:56:43 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_CUSTOMDB_V
(
   APPLICATION,
   OBJECT_NAME,
   STATUS,
   OBJECT_TYPE,
   CREATED,
   LAST_DDL_TIME,
   TIMESTAMP
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
           owner AS "APPLICATION",
            object_name,
            status,
            object_type,
            created,
            last_ddl_time,
            timestamp
       FROM all_objects
      WHERE object_name LIKE 'XX%' AND object_type <> 'PACKAGE BODY'
   ORDER BY 1, 2, 4;
