DROP PROCEDURE APPS.XXLIST_DIRECTORY;

CREATE OR REPLACE PROCEDURE APPS."XXLIST_DIRECTORY" ( directory IN VARCHAR2 )
 AS language JAVA
 name 'XXDirList.GetList( java.lang.String )';
/


GRANT EXECUTE ON APPS.XXLIST_DIRECTORY TO INTG_XX_NONHR_RO;
