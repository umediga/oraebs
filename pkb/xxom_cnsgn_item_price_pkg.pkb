DROP PACKAGE BODY APPS.XXOM_CNSGN_ITEM_PRICE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXOM_CNSGN_ITEM_PRICE_PKG" 
/*************************************************************************************
*   PROGRAM NAME
* 	XXOM_CNSGN_ITEM_PRICE_PKG.sql
*
*   DESCRIPTION
* 
*   USAGE
* 
*    PARAMETERS
*    ==========
*    NAME 	               DESCRIPTION
*    ----------------      ------------------------------------------------------
* 
*   DEPENDENCIES
*  
*   CALLED BY
* 
*   HISTORY
*   =======
*
* VERSION    DATE        AUTHOR(S)  	DESCRIPTION
* ------- ----------- --------------- 	---------------------------------------------------
*     1.0 18-OCT-2013 Brian Stadnik
*
* ISSUES:
* 
******************************************************************************************/
IS

   PROCEDURE intg_item_price_transform (
                                      errbuf              OUT VARCHAR2,
                                      retcode             OUT VARCHAR2,
                                      p_price_list        IN VARCHAR2,
                                      p_organization_id   IN NUMBER
                                      )
   IS
      l_filehandle   UTL_FILE.file_type;
      l_filehandle_arch UTL_FILE.file_type;
      
      l_cur_division VARCHAR2(10);
      l_record_count NUMBER := 0;

      CURSOR price_cur
      IS
           SELECT   transaction_id,
                    transaction_date,
                    'list price' price_type,
                    snm_division division,
                    item_name item,
                    list_price,
                    start_date,
                    end_date,
                    exported_date,
                    list_header_id,
                    list_line_id,
                    status,
                    message
           FROM   XXOM_ITEM_PRICE_STG xips, xxom_sales_marketing_set_v xsms
           WHERE  xips.ss_item_price_intf_date is null
           AND    xips.inventory_item_id = xsms.inventory_item_id
           AND    xsms.organization_id = p_organization_id
           ORDER BY division;

   BEGIN


      BEGIN
         BEGIN
         SELECT   COUNT ( * )
         INTO   l_rec_cnt
         FROM   apps.XXOM_ITEM_PRICE_STG
         WHERE   ss_item_price_intf_date is null;
         EXCEPTION
         WHEN OTHERS THEN
               l_proc_status := 'E';
               apps.fnd_file.put_line ( fnd_file.LOG,
                  'Unable to fetch l_rec_cnt value: ' || l_rec_cnt
               );
         END;


         IF l_rec_cnt > 0
         THEN
            BEGIN  

               FOR price_rec IN price_cur
               LOOP
                  IF NVL(l_cur_division,'NULL') <> price_rec.division THEN
                      -- Do the close operations if we have an open file 
                      IF l_cur_division IS NOT NULL THEN   
                         UTL_FILE.fflush (l_filehandle);                         
                         UTL_FILE.fclose (l_filehandle); 
                         UTL_FILE.FRENAME('XXSGSFTOUT', l_fname, 'XXSGSFTOUT', l_fname1, TRUE);
                                                   
                         --send the latest file to surgisoft
                         xxom_consgn_comm_ftp_pkg.add_new_file(l_fname1);
                         xxom_consgn_comm_ftp_pkg.FTP_DATA_FILE;
                                                   
                         apps.fnd_file.put_line (fnd_file.LOG,
                                 'Number of records written to item price extract ' || l_fname1 || ': ' || l_record_count);
                         l_record_count := 0;
                      END IF;
                      
                      BEGIN
                      SELECT   XXOM_CNSGN_CMN_FILE_SEQ.NEXTVAL
                      INTO   l_comm_seq_no
                      FROM   DUAL;
                      EXCEPTION
                      WHEN OTHERS THEN
                         l_proc_status := 'E';
                         apps.fnd_file.put_line ( fnd_file.LOG,
                            'Unable to fetch common sequence value: ' || l_comm_seq_no
                         );
                      END;

                      BEGIN
                      SELECT XXOM_CNSGN_PRICE_FILE_SEQ.NEXTVAL
                      INTO   l_price_seq_no
                      FROM   DUAL;
                      EXCEPTION
                      WHEN OTHERS THEN
                         l_proc_status := 'E';
                         apps.fnd_file.put_line ( fnd_file.LOG,
                              'Unable to fetch sequence l_price_seq_no for Item Pricelist extract value: '
                                || l_price_seq_no
                      );
                      END;
                      
                      l_fname := l_comm_seq_no || '_PRICE_' || l_price_seq_no || '_' || price_rec.division  || '.tx1';
                      l_fname1 := l_comm_seq_no || '_PRICE_' || l_price_seq_no || '_' || price_rec.division || '.txt';

                      apps.fnd_file.put_line ( fnd_file.LOG,
                          ' File Name for Item Pricelist Extract: ' || l_fname1
                      );
                      
                                  
                      l_filehandle := UTL_FILE.fopen ('XXSGSFTOUT', l_fname, 'w');
                      -- l_filehandle_arch := UTL_FILE.fopen ('XXSGSFTOUTARCH', l_fname, 'w');
               
                      l_cur_division := price_rec.division;
                      
                      UTL_FILE.PUT_LINE (
                          l_filehandle,
                          'TRANSACTION_ID'
                          || '|'
                          || 'TRANSACTION_DATE'
                          || '|'
                          || 'PRICE_TYPE'
                          || '|'
                          || 'ITEM'
                          || '|'
                          || 'LIST_PRICE'
                          || '|'
                          || 'START_DATE'
                          || '|'
                          || 'END_DATE'
                          || '|'
                      );
                      
                  END IF;
                  
                  l_record_count := l_record_count + 1;
               
                  UTL_FILE.put_line (
                     l_filehandle,
                        price_rec.transaction_id
                     || '|'
                     || price_rec.transaction_date
                     || '|'
                     || price_rec.price_type
                     || '|'
                     || price_rec.item
                     || '|'
                     || price_rec.list_price
                     || '|'
                     || price_rec.start_date
                     || '|'
                     || price_rec.end_date
                     || '|'
                  );

                  --updating lines staging table with status and file name
                  UPDATE   apps.XXOM_ITEM_PRICE_STG
                     SET   exported_date = l_proc_date,
                           Status = 'Interfaced to SS',
                           ss_item_price_file_name = l_fname,
                           ss_item_price_intf_date = sysdate
                   WHERE   transaction_id = price_rec.transaction_id
                           and list_header_id = price_rec.list_header_id
                           AND list_line_id = price_rec.list_line_id
                           AND ss_item_price_intf_date is null;

               END LOOP;
               COMMIT;


               IF l_record_count > 0 THEN
                  -- Flush and close the final file
                  UTL_FILE.fflush (l_filehandle);
                  UTL_FILE.fclose (l_filehandle);
                  UTL_FILE.FRENAME('XXSGSFTOUT', l_fname, 'XXSGSFTOUT', l_fname1, TRUE);
                  -- UTL_FILE.fflush (l_filehandle_arch);
                  -- UTL_FILE.fclose (l_filehandle_arch);

                  --send the latest file to surgisoft
                  xxom_consgn_comm_ftp_pkg.add_new_file(l_fname1);
                  xxom_consgn_comm_ftp_pkg.FTP_DATA_FILE;
                                                   
                  apps.fnd_file.put_line (fnd_file.LOG,
                                 'Number of records written to ' || l_fname1 || ': ' || l_record_count);
               END IF;

               --Now send the trigger file to surgisoft
               xxom_consgn_comm_ftp_pkg.GEN_CONF_FILE('Oracle_transfer_complete.txt','XXSGSFTOUT','XXSGSFTARCH'); -- This process generates confirmation file at the end.
               xxom_consgn_comm_ftp_pkg.FTP_DATA_FILE;   -- This process sends/overwrites confirmation file to surgisoft using sFTP.

            END;
         END IF;
      END;
      
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         ROLLBACK;
         apps.fnd_file.put_line (fnd_file.LOG, 'NO DATA FOUND');
         UTL_FILE.fclose_all;
      WHEN UTL_FILE.invalid_operation
      THEN
         ROLLBACK;
         apps.fnd_file.put_line (
            fnd_file.LOG,
            'File could not be opened or operated on as requested.'
         );
         UTL_FILE.fclose_all;
      WHEN UTL_FILE.invalid_path
      THEN
         ROLLBACK;
         apps.fnd_file.put_line (
            fnd_file.LOG,
            'The file location path is not a valid path or wrong file path name.'
         );
         UTL_FILE.fclose_all;
      WHEN UTL_FILE.invalid_filehandle
      THEN
         ROLLBACK;
         apps.fnd_file.put_line (
            fnd_file.LOG,
            'The file handle passed to a UTL_FILE program was invalid. Call UTL_FILE.FOPEN to obtain a valid file handle.'
         );
         UTL_FILE.fclose_all;
      WHEN UTL_FILE.invalid_mode
      THEN
         ROLLBACK;
         apps.fnd_file.put_line (
            fnd_file.LOG,
            'The value provided for the open_mode parameter in UTL_FILE.FOPEN was invalid. It should be "A," "R," or "W." '
         );
         UTL_FILE.fclose_all;
      WHEN UTL_FILE.read_error
      THEN
         ROLLBACK;
         apps.fnd_file.put_line (
            fnd_file.LOG,
            'Operating system error occurred during the read operation.'
         );
         UTL_FILE.fclose_all;
      WHEN UTL_FILE.write_error
      THEN
         ROLLBACK;
         apps.fnd_file.put_line (
            fnd_file.LOG,
            'The operating system returned an error when tried to write to the file'
         );
         UTL_FILE.fclose_all;
      WHEN UTL_FILE.internal_error
      THEN
         ROLLBACK;
         apps.fnd_file.put_line (fnd_file.LOG, 'Unspecified PL/SQL error.');
         UTL_FILE.fclose_all;
      WHEN UTL_FILE.file_open
      THEN
         ROLLBACK;
         apps.fnd_file.put_line (
            fnd_file.LOG,
            'The requested operation failed because the file is open.'
         );
         UTL_FILE.fclose_all;
      WHEN UTL_FILE.invalid_maxlinesize
      THEN
         ROLLBACK;
         apps.fnd_file.put_line (
            fnd_file.LOG,
            'The MAX_LINESIZE value for FOPEN() is invalid; it should be within the range 1 to 32767.'
         );
         UTL_FILE.fclose_all;
      WHEN UTL_FILE.invalid_filename
      THEN
         ROLLBACK;
         apps.fnd_file.put_line (fnd_file.LOG,
              'The filename parameter is invalid.');
         UTL_FILE.fclose_all;
      WHEN UTL_FILE.access_denied
      THEN
         ROLLBACK;
         apps.fnd_file.put_line (
            fnd_file.LOG,
            'Permission to access to the file location is denied.'
         );
         UTL_FILE.fclose_all;
      WHEN OTHERS
      THEN
         ROLLBACK;
         l_errmsg := SUBSTR (SQLERRM, 1, 100);
         apps.fnd_file.put_line (fnd_file.LOG, 'Error Message: ' || l_errmsg);
         UTL_FILE.fclose_all;
         dbms_output.put_line('Error Message: ' || l_errmsg);
   END intg_item_price_transform;
END XXOM_CNSGN_ITEM_PRICE_PKG;
/
