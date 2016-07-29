DROP PACKAGE APPS.XX_EMAIL_WRAPPER;

CREATE OR REPLACE PACKAGE APPS."XX_EMAIL_WRAPPER" 
IS
   /*******************************************************************************
   -- Created By    : IBM Development
   -- Created  on   : 30-JUL-2012
   -- File Name     : XXEMAILWRAPPER.pkb
   -- Description   : Custom Common Process to invoke send mail
   --
   --
   -- Change History:
   -- Date        Name       Ver Remarks
   -- ----------- ---------  --- ---------------------------------------------
   -- 30-Jul-2012 Dinesh     1.0  Initial Version

   *******************************************************************************/

PROCEDURE MAIN ( x_errbuf        OUT VARCHAR2
                    ,x_retcode       OUT VARCHAR2
                    );

l_last_run_date DATE;

END XX_EMAIL_WRAPPER;
/


GRANT EXECUTE ON APPS.XX_EMAIL_WRAPPER TO INTG_XX_NONHR_RO;
