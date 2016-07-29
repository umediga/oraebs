DROP PACKAGE APPS.XXINTG_UPDATE_EXPIRATION_DATE;

CREATE OR REPLACE PACKAGE APPS.XXINTG_UPDATE_EXPIRATION_DATE
IS
----------------------------------------------------------------------
/*
Created By : Deepti
Creation Date : 08-Apr-2015
File Name : XXUPDEXPDATE.pkb
Description : This script creates the body of the package XXINTG_UPDATE_EXPIRATION_DATE
Change History:
Version Date Name Remarks
------- ----------- -------- -------------------------------
1.0 08-Apr-2015 IBM Development Team Initial development.
*/
----------------------------------------------------------------------

PROCEDURE MAIN (
                 errbuf    out varchar2,
                 retcode   out numbeR,
                 p_job_num   IN   VARCHAR2);
END ;

/
