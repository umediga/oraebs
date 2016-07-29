DROP PACKAGE BODY APPS.XX_EMAIL_WRAPPER;

CREATE OR REPLACE PACKAGE BODY APPS."XX_EMAIL_WRAPPER" 
IS
   /*******************************************************************************
   -- Created By    : IBM Development
   -- Created  on   : 30-JUL-2012
   -- File Name     : XXEMAILWRAPPER.pkb
   -- Description   : Custom Common Process to invoke send mail for all completed programs
   --                 which are also defined in process setup form
   --
   -- Change History:
   -- Date        Name       Ver Remarks
   -- ----------- ---------  --- ---------------------------------------------
   -- 30-Jul-2012 Dinesh     1.0  Initial Version

   *******************************************************************************/


PROCEDURE MAIN (x_errbuf OUT VARCHAR2,
                x_retcode OUT VARCHAR2)


IS

 	l_last_run_date DATE;

	CURSOR get_completed_progs(pi_last_run_date DATE)
	IS
         	SELECT   distinct fcr.request_id
	          FROM   xxintg.xx_emf_process_setup eps,
	                   apps.fnd_concurrent_requests fcr,
	                   apps.fnd_concurrent_programs fcp
	 	  WHERE   fcr.concurrent_program_id = fcp.concurrent_program_id
	            AND   fcp.concurrent_program_name = eps.process_name
                    AND   fcr.phase_code = 'C'
                    AND   fcr.request_date > pi_last_run_date;

BEGIN

	      SELECT   NVL(max(fcr.request_date),sysdate-1)
	        INTO   l_last_run_date
	      	FROM   apps.fnd_concurrent_requests fcr,
	      	       apps.fnd_concurrent_programs fcp
	       WHERE   fcr.concurrent_program_id = fcp.concurrent_program_id
	      	 AND   fcp.concurrent_program_name = 'XXEMAILWRAPPER'
                 AND   fcr.phase_code = 'C';

	      FOR rec_completed_progs IN get_completed_progs(l_last_run_date)
      	      LOOP
			FND_FILE.put_line(FND_FILE.output,'REQUEST IDs PROCESSED');
			FND_FILE.put_line(FND_FILE.output,rec_completed_progs.request_id);
			dbms_output.put_line('REQUEST IDs PROCESSED');
			dbms_output.put_line(rec_completed_progs.request_id);
			XX_COMMON_PROCESS_EMAIL.NOTIFY_USER(rec_completed_progs.request_id);

	      END LOOP;

END;

END XX_EMAIL_WRAPPER;
/


GRANT EXECUTE ON APPS.XX_EMAIL_WRAPPER TO INTG_XX_NONHR_RO;
