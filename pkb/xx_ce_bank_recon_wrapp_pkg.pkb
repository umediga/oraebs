DROP PACKAGE BODY APPS.XX_CE_BANK_RECON_WRAPP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_CE_BANK_RECON_WRAPP_PKG" 
  ----------------------------------------------------------------------
  /* $Header: xxcebankreconwrapp.pkb 1.0 2012/02/08 12:00:00 schakraborty noship $ */
  /*
  Created By     : IBM Development Team
  Creation Date  : 22-Apr-2012
  File Name      : xxcebankreconwrapp.pkb
  Description    : This script creates the specification of the xx_ce_bank_recon_wrapp_pkg package
  Change History:
  Version Date        Name                                            Remarks
  ------- ----------- ----                                           ----------------------
  1.0     22-Apr-12   IBM Development Team (Sayan Chakraborty)       Initial development.
  1.1     06-Jul-12   IBM Development Team (Kunal Seal)              Change.
  1.2     28-Mar-14   IBM Development Team                           Change for invoice no issue.
  */
  /*----------------------------------------------------------------------*/
AS
  /*----------------------------------------------------------------------*/
  /*--- Cursor Declaration     N/A                                           */
  /*----------------------------------------------------------------------*/
  /*----------------------Env Set-----------------------*/
PROCEDURE xx_ce_bank_recon_wrapper(
    p_errbuf OUT VARCHAR2,
    p_retcode OUT VARCHAR2,
    x_file_name        IN VARCHAR2,
    p_source_directory IN VARCHAR2 -- added 06-Jul-2012
  )
IS
  /*--- Variable Declaration */
  x_error_code NUMBER;
  x_request_id NUMBER;
  x_total_cnt  NUMBER;
BEGIN
  /* Submit First Concurrent Program */
  /*----------------------------------------------------------------------*/
  x_request_id := fnd_global.conc_request_id;
  FND_FILE.PUT_LINE ( FND_FILE.LOG, 'Retreiving Wrapper program request id: ' || x_request_id );
  /*----------------------------------------------------------------------*/
  IF (xx_ce_initiate (x_file_name, p_source_directory) <> TRUE) THEN
    FND_FILE.PUT_LINE (FND_FILE.LOG, G_ERRBUF);
    COMMIT;
    p_errbuf  := G_ERRBUF;
    p_retcode := 2;
    RAISE E_FATAL_ERROR;
  END IF;
EXCEPTION
WHEN E_FATAL_ERROR THEN
  p_errbuf  := 'Bank reconciliation Failed at wrapper program level';
  p_retcode := 2;
WHEN OTHERS THEN
  p_errbuf  := 'Bank reconciliation Failed at wrapper program level';
  p_retcode := 2;
END xx_ce_bank_recon_wrapper;
/*----------------------------------------------------------------------*/
/*--- This function is to initiate First Concurrent Program             */
/*----------------------------------------------------------------------*/
FUNCTION xx_ce_initiate(
    p_data_filename    IN VARCHAR2,
    p_source_directory IN VARCHAR2)
  RETURN BOOLEAN
IS
  /* --- Variable Declaration  */
  x_submit_req_id   NUMBER;
  x_submit_req_id2  NUMBER;
  x_conc_request_id NUMBER;
  x_error_code      NUMBER;
  x_identifier1     VARCHAR2 (100);
  x_identifier2     VARCHAR2 (100);
  x_identifier3     VARCHAR2 (100);
  x_identifier4     VARCHAR2 (100);
  X_COUNT1          NUMBER        := 0;
  x_level1          VARCHAR2 (10) := 0;
  x_launch1         VARCHAR2 (1);
  x_sysdate         VARCHAR2 (30) := TO_CHAR (SYSDATE, 'yyyy/mm/dd hh:mm:ss') ;
  -- Added by Kunal 06-Jul-2012
  x_phase      VARCHAR2 (100);
  x_status     VARCHAR2 (100);
  x_dev_phase  VARCHAR2 (100);
  x_dev_status VARCHAR2 (100);
  X_MSG        VARCHAR2 (1000);
  X_MAP_ID     NUMBER;
  /*----------------------------------------------------------------------*/
BEGIN
  -- Commented to pass the directory name as parameter
  BEGIN
    SELECT MAP_ID
    INTO X_MAP_ID
    FROM XX_EMF_PROCESS_PARAMETERS xepp,
      xx_emf_process_setup xeps,
      CE_BANK_STMT_INT_MAP cbsi
    WHERE XEPP.PROCESS_ID = XEPS.PROCESS_ID
    AND cbsi.format_name  = parameter_value
    AND XEPS.PROCESS_NAME = 'XXCEBANKRECONWRAPP'
    AND parameter_name    = 'FORMAT_NAME';
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE (FND_FILE.log, 'Error getting data file path');
    X_MAP_ID := -1;
  END;
  IF X_MAP_ID       != -1 THEN
    x_identifier1 := p_source_directory;
    FND_FILE.PUT_LINE (FND_FILE.LOG, x_identifier1);
    x_submit_req_id := FND_REQUEST.SUBMIT_REQUEST (application => 'CE', program => 'CESQLLDR', description => NULL, start_time => NULL, sub_request => NULL, argument1 => 'ZALL' --'LOAD'
    , argument2 => X_MAP_ID, argument3 => p_data_filename, argument4 => x_identifier1, argument5 => '', argument6 => '', argument7 => x_sysdate, argument8 => '', argument9 => '', argument10 => '', argument11 => '', argument12 => 'y', argument13 => '', argument14 => '');
    COMMIT;
    G_REQUEST_ID := x_submit_req_id;
    FND_FILE.PUT_LINE (FND_FILE.log, 'Request id is: ' || G_REQUEST_ID);
    /*----------------------------------------------------------------------*/
    /*----------------------------------------------------------------------*/
    IF x_submit_req_id IS NOT NULL THEN
      -- Wait for the SQL Loader program to complete
      IF (FND_CONCURRENT.WAIT_FOR_REQUEST (REQUEST_ID => G_REQUEST_ID, INTERVAL => 10, MAX_WAIT => 360, PHASE => x_phase, STATUS => x_status, DEV_PHASE => x_dev_phase, DEV_STATUS => x_dev_status, MESSAGE => x_msg)) THEN
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Dev Phase : '||x_dev_phase);
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Dev Status : '||x_dev_status);
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Phase : '||x_phase);
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Status : '||x_status);
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Message : '||x_msg);
        BEGIN
          SELECT directory_path
            ||'/'
          INTO x_identifier3
          FROM all_directories
          WHERE directory_name = upper(xx_emf_pkg.get_paramater_value('XXCEBANKRECONWRAPP','archive_dir'));
        EXCEPTION
        WHEN OTHERS THEN
          FND_FILE.PUT_LINE ( FND_FILE.LOG, 'Error getting directory for archive file' );
        END;
        BEGIN
          SELECT parameter_value
          INTO x_identifier4
          FROM XX_EMF_PROCESS_PARAMETERS xepp,
            xx_emf_process_setup xeps
          WHERE xepp.process_id = xeps.process_id
          AND xeps.process_name = 'XXINTGFILEMOV'
          AND parameter_name    = 'IDENTIFIER2';
        EXCEPTION
        WHEN OTHERS THEN
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error getting file movement mode');
        END;
        /*---------------------------------*/
        /*--------Calling the Common File movement program---------*/
        x_conc_request_id := fnd_request.submit_request (application => 'XXINTG', program => 'XXINTGFILEMOV', sub_request => FALSE, argument1 => p_data_filename, argument2 => x_identifier1||'/', argument3 => x_identifier3, argument4 => x_identifier4);
        --RETURN (TRUE);
      ELSE
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Archive Program not submitted');
      END IF;
    END IF;
  ELSE
    FND_FILE.PUT_LINE (FND_FILE.LOG, ' Mapping not defined in EMF');
  END IF;
  FND_FILE.PUT_LINE (FND_FILE.LOG, 'End of program');
  RETURN (TRUE);
EXCEPTION
WHEN OTHERS THEN
  G_ERRBUF  := SQLCODE || ', ' || SQLERRM;
  G_RETCODE := '2';
  RETURN (FALSE);
END xx_ce_initiate;
end XX_CE_BANK_RECON_WRAPP_PKG;
/
