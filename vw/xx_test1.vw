DROP VIEW APPS.XX_TEST1;

/* Formatted on 6/6/2016 4:58:01 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_TEST1
(
   "SCHEMA",
   C_INDEX,
   C_FUNCTION,
   C_MV,
   C_TABLE,
   C_PRG,
   C_PROC,
   C_SYN,
   C_VIEW,
   C_SEQUENCE,
   C_TRIGGER,
   OBJECT_TYPE
)
AS
   SELECT /*- ================================================================================
          -- FILE NAME            :
          -- AUTHOR               : Wipro Technologies
          -- DATE CREATED         : 08-NOV-2012
          -- DESCRIPTION          :
          -- RICE COMPONENT ID    :
          -- R11i10 OBJECT NAME   :
          -- R12 OBJECT NAME      : XX_TEST1
          -- REVISION HISTORY     :
          -- =================================================================================
          --  Version  Person                 Date          Comments
          --  -------  --------------         -----------   ------------
          --  1.0      Anirudh Kumar          28-JAN-2013   Initial Version.
          -- =================================================================================*/
         owner schema,
          DECODE (object_type, 'INDEX', 1) "C_INDEX",
          DECODE (object_type, 'FUNCTION', 1) "C_FUNCTION",
          DECODE (object_type, 'MATERIALIZED VIEW', 1) "C_MV",
          DECODE (object_type, 'TABLE', 1) "C_TABLE",
          DECODE (object_type, 'PACKAGE', 1) "C_PRG",
          DECODE (object_type, 'PROCEDURE', 1) "C_PROC",
          DECODE (object_type, 'SYNONYM', 1) "C_SYN",
          DECODE (object_type, 'VIEW', 1) "C_VIEW",
          DECODE (object_type, 'SEQUENCE', 1) "C_SEQUENCE",
          DECODE (object_type, 'TRIGGER', 1) "C_TRIGGER",
          object_type
     FROM xx_temp1_database_objects;
