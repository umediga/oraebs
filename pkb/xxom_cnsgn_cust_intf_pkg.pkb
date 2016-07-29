DROP PACKAGE BODY APPS.XXOM_CNSGN_CUST_INTF_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXOM_CNSGN_CUST_INTF_PKG"
IS
/*************************************************************************************
*   PROGRAM NAME
*     XXOM_CNSGN_CUST_INTF_PKG.sql
*
*   DESCRIPTION
*
*   USAGE
*
*    PARAMETERS
*    ==========
*    NAME                    DESCRIPTION
*    ----------------      ------------------------------------------------------
*
*   DEPENDENCIES
*
*   CALLED BY
*
*   HISTORY
*   =======
*
* VERSION    DATE        AUTHOR(S)      DESCRIPTION
* ------- ----------- ---------------     ---------------------------------------------------
*     1.0 18-OCT-2013 Brian Stadnik
*
* ISSUES:
*
******************************************************************************************/
   PROCEDURE intg_log_message (
      p_msg        IN   VARCHAR2
   )
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, TO_CHAR (SYSDATE, 'DD-MON-YY HH24:MI:SS') || ' ' || p_msg);
      --During debugging, also use DBMS_OUTPUT.PUT_LINE
      dbms_output.put_line (TO_CHAR (SYSDATE, 'DD-MON-YY HH24:MI:SS') || ' ' || p_msg);
   EXCEPTION
      WHEN OTHERS
      THEN
         dbms_output.put_line('Log_msg: ' || SQLERRM); -- bxs fnd_file.put_line (fnd_file.LOG, 'Log_msg: ' || SQLERRM);
   END intg_log_message;

   --Why is this in the package spec?  Is it ever called from outside this package?  This overload is now just a pass through to the real log_message procedure.
   PROCEDURE intg_log_message (
      p_msg        IN   VARCHAR2,
      p_status     IN   VARCHAR2
   )
   IS
   BEGIN
      intg_log_message (p_status || ': ' || p_msg);
   END intg_log_message;

   --This is never called.
   PROCEDURE update_status (
      p_msg        IN   VARCHAR2,
      p_status     IN   VARCHAR2,
      p_trans_id   IN   NUMBER
   )
   IS
   BEGIN
      UPDATE XXOM_CUST_ADDR_STG
         SET status = p_status,
             MESSAGE = p_msg
       WHERE transaction_id = p_trans_id;

      --COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         intg_log_message('Exception in update_status: ' || SQLERRM); -- bxs fnd_file.put_line (fnd_file.LOG, 'Log_msg: ' || SQLERRM);
         RAISE;
   END update_status;

   PROCEDURE intg_customer_translate
   (errbuf       OUT NOCOPY VARCHAR2,
    retcode      OUT NOCOPY NUMBER)
  -------------------------------------------------------------------------------------------------------------
  --   This Procedure(intg_customer_translate ) will create the data files from staging tables
  --   XXOM_CUST_ADDR_STG
  -------------------------------------------------------------------------------------------------------------
   IS
      l_batch_no      NUMBER := 0;
      l_comm_seq_no   NUMBER := 0;
      l_int_seq_no    NUMBER := 0;
      lv_count        NUMBER := 0;
      l_record_count  NUMBER := 0;
      l_errmsg        VARCHAR2 (1000);
      l_file_dir      VARCHAR2 (200);
      l_fname         VARCHAR2 (80);
      l_fname_spine   VARCHAR2 (80);
      l_fname_neuro   VARCHAR2 (80);
    --  l_fname_spine   VARCHAR2 (80);
      l_filehandle    UTL_FILE.file_type;


      CURSOR cust_addr_cur
      IS
         SELECT   transaction_id,
                  transaction_date,
                  location_name,
                  customer_number,
                  cust_address1,
                  cust_address2,
                  cust_city,
                  cust_state,
                  cust_zip,
                  cust_county,
                  cust_loc_type,
                  cust_credit_hold,
                  cust_status,
                  cust_acct_site_id,
                  party_site_number,
                  recon_terr_code,
                  neuro_terr_code,
                  old_customer_site_number,
                  spine_territory_code,
                      recon1,
                      recon2,
                  recon3,
                  gpo_pricing,
                  formal_consignment,
                  resource_id,
                  customer_type,
                  customer_use,
                  primary_flag
             FROM XXOM_CUST_ADDR_STG
             WHERE SS_CUST_ADDR_INTF_DATE is null
         ORDER BY transaction_id;
   BEGIN

      BEGIN
         SELECT XXOM_CNSGN_CMN_FILE_SEQ.NEXTVAL
           INTO l_comm_seq_no
           FROM DUAL;

         intg_log_message ('l_comm_seq_no:' || l_comm_seq_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            intg_log_message ('ERROR: Unable to fetch sequence no value for XXOM_CNSGN_CMN_FILE_SEQ: ' || l_batch_no);
            RAISE;
      END;

      BEGIN
         SELECT XXOM_CNSGN_CUST_ADDR_FILE_SEQ.NEXTVAL
           INTO l_int_seq_no
           FROM DUAL;

         intg_log_message ('l_int_seq_no:' || l_int_seq_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            intg_log_message ('ERROR: Unable to fetch sequence no value for XXOM_CNSGN_CUST_ADDR_FILE_SEQ: ' || l_batch_no);
            RAISE;
      END;

      SELECT count(*)
      INTO  l_record_count
      FROM  XXOM_CUST_ADDR_STG
      WHERE SS_CUST_ADDR_INTF_DATE is null;

      IF l_record_count > 1 THEN

          l_fname := l_comm_seq_no || '_CUST_' || l_int_seq_no || '_SPINE.tx1';

          l_fname_spine := l_comm_seq_no || '_CUST_' || l_int_seq_no || '_SPINE.txt';

          -- l_fname_spine := l_comm_seq_no || '_CUST_' || l_int_seq_no || '_SPINE.txt';
          -- l_fname_neuro := l_comm_seq_no || '_CUST_' || l_int_seq_no || '_NEURO.txt';


          intg_log_message ('opening l_fname for writing:' || l_fname);

          l_filehandle := UTL_FILE.fopen ('XXSGSFTOUT', l_fname, 'w');
          -- l_filehandle_arch := UTL_FILE.fopen ('XXSGSFTOUTARCH', l_fname, 'w');

          intg_log_message ('l_fname:' || 'File opened for writing');

          UTL_FILE.put_line (
                    l_filehandle,
                       'TRANSACTION_ID'
                    || '|'
                    || 'TRANSACTION_DATE'
                    || '|'
                    || 'LOCATION_NAME'
                    || '|'
                    || 'CUSTOMER_NUMBER'
                    || '|'
                    || 'CUST_ADDRESS1'
                    || '|'
                    || 'CUST_ADDRESS2'
                    || '|'
                    || 'CUST_CITY'
                    || '|'
                    || 'CUST_STATE'
                    || '|'
                    || 'CUST_ZIP'
                    || '|'
                    || 'CUST_COUNTY'
                    || '|'
                    || 'CUST_LOC_TYPE'
                    || '|'
                    || 'CUST_CREDIT_HOLD'
                    || '|'
                    || 'CUST_STATUS'
                    || '|'
                    || 'PARTY_SITE_NUMBER'
                    || '|'
                    || 'RECON_TERR_CODE'
                    || '|'
                    || 'NEURO_TERR_CODE'
                    || '|'
                    || 'OLD_CUSTOMER_SITE_NUMBER'
                    || '|'
                    || 'SPINE_TERR_CODE'
                    || '|'
                    || 'RECON1'
                    || '|'
                    || 'RECON2'
                    || '|'
                    || 'RECON3'
                    || '|'
                    || 'GPO_PRICING'
                    || '|'
                    || 'FORMAL_CONSIGNMENT'
                    || '|'
                    || 'RESOURCE_ID'
                    || '|'
                    || 'CUSTOMER_TYPE'
                    || '|'
                    || 'CUSTOMER_USE'
                    || '|'
                    || 'PRIMARY_FLAG'
                    || '|'

                  );

      END IF;


      FOR cust_addr_rec IN cust_addr_cur
      LOOP
         UTL_FILE.put_line (l_filehandle,
                               cust_addr_rec.transaction_id
                            || '|'
                            || cust_addr_rec.transaction_date
                            || '|'
                            || cust_addr_rec.location_name
                            || '|'
                            || cust_addr_rec.customer_number
                            || '|'
                            || cust_addr_rec.cust_address1
                            || '|'
                            || cust_addr_rec.cust_address2
                            || '|'
                            || cust_addr_rec.cust_city
                            || '|'
                            || cust_addr_rec.cust_state
                            || '|'
                            || cust_addr_rec.cust_zip
                            || '|'
                            || cust_addr_rec.cust_county
                            || '|'
                            || cust_addr_rec.cust_loc_type
                            || '|'
                            || cust_addr_rec.cust_credit_hold
                            || '|'
                            || cust_addr_rec.cust_status
                            || '|'
                            || cust_addr_rec.party_site_number
                            || '|'
                            || cust_addr_rec.recon_terr_code
                            || '|'
                            || cust_addr_rec.neuro_terr_code
                            || '|'
                            || cust_addr_rec.old_customer_site_number
                            || '|'
                            || cust_addr_rec.spine_territory_code
                            || '|'
                            || cust_addr_rec.recon1
                            || '|'
                            || cust_addr_rec.recon2
                            || '|'
                            || cust_addr_rec.recon3
                            || '|'
                            || 'N' -- 'gpo_pricing'
                            || '|'
                            || 'N' -- 'formal_consignment'
                            || '|'
                            || cust_addr_rec.resource_id
                            || '|'
                            || cust_addr_rec.customer_type
                            || '|'
                            || cust_addr_rec.customer_use
                            || '|'
                            || cust_addr_rec.primary_flag
                            || '|'
                           );
             lv_count := lv_count + 1;

                  --updating lines staging table with status and file name
                  UPDATE   apps.XXOM_CUST_ADDR_STG
                     SET   exported_date = l_proc_date,
                           status = 'Interfaced to SS',
                           ss_cust_addr_file_name = l_fname,
                           ss_cust_addr_intf_date = sysdate
                   WHERE   transaction_id = cust_addr_rec.transaction_id
                           AND ss_cust_addr_intf_date is null;

      END LOOP;

      intg_log_message ('The total records inserted into the Extract file is:' || lv_count);


     IF lv_count > 0 THEN
          intg_log_message ('TRANSFERED: File has been extracted and moved to ' || l_file_dir);

          UTL_FILE.fflush (l_filehandle);
          UTL_FILE.fclose (l_filehandle);


          -- Right now the systems are split into sepearate instances and they all need a
          -- copy of this file.  Need to work with vendor to only get one from the ftp site
          -- and change the processes on their end
          -- BXS - this actually works with only one file for RECON
          /*
          UTL_FILE.FCOPY('XXSGSFTOUT', l_fname, 'XXSGSFTOUT', l_fname_spine);
          fnd_file.put_line (fnd_file.LOG,
                                      'Copied file name for spine: ' || l_fname_spine
                                  );

          UTL_FILE.FCOPY('XXSGSFTOUT', l_fname, 'XXSGSFTOUT', l_fname_neuro);
          fnd_file.put_line (fnd_file.LOG,
                                      'File has copied for NUERO: ' || l_fname_neuro
                                  );
          */
          UTL_FILE.FRENAME('XXSGSFTOUT', l_fname, 'XXSGSFTOUT', l_fname_spine, TRUE);
          intg_log_message ('File has been copied for SPINE: ' || l_fname_spine);

          COMMIT;

          -- xxom_consgn_comm_ftp_pkg.add_new_file(l_fname_spine); -- Provide actual file name as parameter.
          -- BXS - there only needs to be one file now
          -- xxom_consgn_comm_ftp_pkg.add_new_file(l_fname_neuro); -- Provide actual file name as parameter.
          xxom_consgn_comm_ftp_pkg.add_new_file(l_fname_spine); -- Provide actual file name as parameter.

          xxom_consgn_comm_ftp_pkg.FTP_DATA_FILE;   -- This process sends actual data file to surgisoft using sFTP.
          xxom_consgn_comm_ftp_pkg.GEN_CONF_FILE('Oracle_transfer_complete.txt','XXSGSFTOUT','XXSGSFTARCH'); -- This process generates confirmation file at the end.
          xxom_consgn_comm_ftp_pkg.FTP_DATA_FILE;   -- This process sends/overwrites confirmation file to surgisoft using sFTP.

      END IF;

   EXCEPTION
      WHEN UTL_FILE.invalid_mode
      THEN
         intg_log_message ('ERROR: Invalid Mode Parameter');
      WHEN UTL_FILE.invalid_path
      THEN
         intg_log_message ('ERROR: Invalid File Location');
      WHEN UTL_FILE.invalid_filehandle
      THEN
         intg_log_message ('ERROR: Invalid Filehandle');
      WHEN UTL_FILE.invalid_operation
      THEN
         intg_log_message ('ERROR: Invalid Operation');
      WHEN UTL_FILE.read_error
      THEN
         intg_log_message ('ERROR: Read Error');
      WHEN UTL_FILE.internal_error
      THEN
         intg_log_message ('ERROR: Internal Error');
      WHEN UTL_FILE.charsetmismatch
      THEN
         intg_log_message ('ERROR: Opened With FOPEN_NCHAR But Later I/O Inconsistent');
      WHEN UTL_FILE.file_open
      THEN
         intg_log_message ('ERROR: File Already Opened');
      WHEN UTL_FILE.invalid_maxlinesize
      THEN
         intg_log_message ('ERROR: Line Size Exceeds 32K');
      WHEN UTL_FILE.invalid_filename
      THEN
         intg_log_message ('ERROR: Invalid File Name');
      WHEN UTL_FILE.access_denied
      THEN
          intg_log_message ('ERROR: File Access Denied By');
      WHEN UTL_FILE.invalid_offset
      THEN
         intg_log_message ('ERROR: FSEEK Param Less Than 0');
      WHEN OTHERS
      THEN
         intg_log_message ('ERROR: Unknown Error: ' || SQLERRM);
   END intg_customer_translate;
END XXOM_CNSGN_CUST_INTF_PKG;
/
