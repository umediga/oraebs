DROP PACKAGE BODY APPS.XXOM_CNSGN_ITEM_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXOM_CNSGN_ITEM_PKG" 
/*************************************************************************************
*   PROGRAM NAME
* 	XXOM_CNSGN_ITEM_PKG.sql
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
*     2.0 18-OCT-2013 Brian Stadnik
*
* ISSUES:
*  EXLUDE INSTRUMENTS FROM PRICE AND ITEM
******************************************************************************************/

IS

                                      
   PROCEDURE intg_log_message (
      p_msg        IN   VARCHAR2,
      p_status     IN   VARCHAR2
   )
   IS
   BEGIN
      NULL;
   END intg_log_message;
   
      
   PROCEDURE intg_item_translate  (errbuf                 OUT VARCHAR2,
                                   retcode                OUT VARCHAR2,
                                   p_organization_id   IN     NUMBER)
   IS
      l_filehandle   UTL_FILE.file_type;
      l_file_dir     VARCHAR2(50) := 'XXSGSFTOUT';
      l_cur_division VARCHAR2(10);
      l_record_count NUMBER := 0;

      CURSOR item_cur IS
           SELECT   transaction_id,
                    transaction_date,
                    item_number,
                    item_description,
                    inventory_item_id,
                    item_cost,
                    autorestock,
                    instrumentset,
                    item_type,
                    item_status,
                    lot_serial_control,
                    customer_ordered_flag,
                    expiration_control,
                    inventory_tracked,
                    abc_cc_class,
                    default_loan_days,
                    division,
                    product_segment,
                    brand,
                    product_class,
                    product_type,
                    sales_and_marketing_info,
                    exported_date,
                    status,
                    message,
                    SS_ITEM_MASTER_FILE_NAME,
                    asc_item_number                  
             FROM   XXOM_ITEM_MASTER_STG
            WHERE   SS_ITEM_MASTER_INTF_DATE is null
         ORDER BY   division, transaction_id;

   BEGIN

      BEGIN
         BEGIN
            SELECT   COUNT ( * )
            INTO   l_rec_cnt
            FROM   XXOM_ITEM_MASTER_STG
            WHERE  SS_ITEM_MASTER_INTF_DATE is null; 
            EXCEPTION
            WHEN OTHERS
            THEN
               l_proc_status := 'E';
               apps.fnd_file.put_line (
                  fnd_file.LOG,
                  'Unable to fetch l_rec_cnt value: ' || l_rec_cnt
               );
         END;

         IF l_rec_cnt >=0
         THEN
            BEGIN

               FOR item_rec IN item_cur
               LOOP
               
                  IF NVL(l_cur_division,'NULL') <> item_rec.division THEN
                      -- Do the close operations if we have an open file
                      IF l_cur_division IS NOT NULL THEN   
                         UTL_FILE.fflush (l_filehandle);                              
                         UTL_FILE.fclose (l_filehandle);
                         UTL_FILE.FRENAME('XXSGSFTOUT', l_fname, 'XXSGSFTOUT', l_fname1, TRUE);
                                                   
                         apps.fnd_file.put_line (fnd_file.LOG,
                                 'Number of records written to extract ' || l_fname1 || ': ' || l_record_count);
                         l_record_count := 0;
                      END IF;
                     
                      BEGIN
                      SELECT   XXOM_CNSGN_CMN_FILE_SEQ.NEXTVAL
                      INTO   l_comm_seq_no
                      FROM   DUAL;
                      EXCEPTION
                      WHEN OTHERS THEN
                         l_proc_status := 'E';
                         apps.fnd_file.put_line (
                               fnd_file.LOG,
                                 'Unable to fetch common sequence no value: ' || l_comm_seq_no
                         );
                      END;

                      BEGIN
                      SELECT   XXOM_CNSGN_ITEM_FILE_SEQ.NEXTVAL
                      INTO   l_item_seq_no
                      FROM   DUAL;
                      EXCEPTION
                      WHEN OTHERS THEN
                         l_proc_status := 'E';
                         apps.fnd_file.put_line (
                         fnd_file.LOG,
                         'Unable to fetch sequence l_item_seq_no for item extract value: '
                           || l_item_seq_no
                      );
                    END;
      
                    l_fname  := l_comm_seq_no || '_ITEM_' || l_item_seq_no || '_' || item_rec.division || '.tx1';
                    l_fname1 := l_comm_seq_no || '_ITEM_' || l_item_seq_no || '_' || item_rec.division || '.txt';


                    l_filehandle := UTL_FILE.fopen ('XXSGSFTOUT', l_fname, 'w');
                    apps.fnd_file.put_line (fnd_file.LOG,
                                 'File Name for item Extract: ' || l_fname);
                    -- l_filehandle_arch := UTL_FILE.fopen ('XXSGSFTOUTARCH', l_fname, 'w');
                     
                    l_cur_division := item_rec.division;
                     

                    UTL_FILE.PUT_LINE (
                       l_filehandle,
                           'TRANSACTION_ID'
                        || '|'
                        || 'TRANSACTION_DATE'
                        || '|'
                        || 'ITEM_NUMBER'
                        || '|'
                        || 'ITEM_DESCRIPTION'
                        || '|'
                        || 'INVENTORY_ITEM_ID'
                        || '|'
                        || 'ITEM_COST'
                        || '|'
                        || 'AUTORESTOCK'
                        || '|'
                        || 'INSTRUMENTSET'
                        || '|'
                        || 'ITEM_TYPE'
                        || '|'
                        || 'ITEM_STATUS'
                        || '|'
                        || 'LOT_SERIAL_CONTROL'
                        || '|'
                        || 'CUSTOMER_ORDERED_FLAG'
                        || '|'
                        || 'EXPIRATION_CONTROL'
                        || '|'
                        || 'INVENTORY_TRACKED'
                        || '|'
                        || 'ABC_CC_CLASS'
                        || '|'
                        || 'DEFAULT_LOAN_DAYS'
                        || '|'
                        || 'DIVISION'
                        || '|'
                        || 'BRAND'
                        || '|'
                        || 'PRODUCT_CLASS'
                        || '|'
                        || 'PRODUCT_TYPE'
                        || '|'
                        || 'SALES_AND_MARKETING_INFO'
                        || '|'
                        || 'ASCN_ITEM_NO'
                        || '|'
                     );
                  END IF;

                  l_record_count := l_record_count + 1;

                  UTL_FILE.put_line (
                     l_filehandle,
                        item_rec.transaction_id
                     || '|'
                     || item_rec.transaction_date
                     || '|'
                     || item_rec.item_number
                     || '|'
                     || item_rec.item_description
                     || '|'
                     || item_rec.inventory_item_id
                     || '|'
                     || item_rec.item_cost
                     || '|'
                     || item_rec.autorestock
                     || '|'
                     || item_rec.instrumentset
                     || '|'
                     || item_rec.item_type
                     || '|'
                     || item_rec.item_status
                     || '|'
                     || item_rec.lot_serial_control
                     || '|'
                     || item_rec.customer_ordered_flag
                     || '|'
                     || item_rec.expiration_control
                     || '|'
                     || item_rec.inventory_tracked
                     || '|'
                     || item_rec.abc_cc_class
                     || '|'
                     || item_rec.default_loan_days
                     || '|'
                     || item_rec.division
                     || '|'
                     || item_rec.brand
                     || '|'
                     || item_rec.product_class
                     || '|'
                     || item_rec.product_type
                     || '|'
                     || item_rec.sales_and_marketing_info
                     || '|'
                     || item_rec.asc_item_number
                     || '|'
                  );


                  --updating lines staging table with status and file name
                  UPDATE   XXOM_ITEM_MASTER_STG
                     SET   exported_date = l_proc_date,
                           Status = 'Exported to SS',
                           SS_ITEM_MASTER_FILE_NAME = l_fname,
                           SS_ITEM_MASTER_INTF_DATE = sysdate
                   WHERE   transaction_id = item_rec.transaction_id
                   AND     SS_ITEM_MASTER_INTF_DATE is null;
                           
               END LOOP;

               COMMIT;

               IF l_record_count > 0 THEN
                  -- Flush and close the final file
                  UTL_FILE.fflush (l_filehandle);
                  UTL_FILE.fclose (l_filehandle);
                  UTL_FILE.FRENAME('XXSGSFTOUT', l_fname, 'XXSGSFTOUT', l_fname1, TRUE);
                  apps.fnd_file.put_line (fnd_file.LOG,
                                 'Number of records written to ' || l_fname1 || ': ' || l_record_count);
               END IF;

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
   END intg_item_translate;
END XXOM_CNSGN_ITEM_PKG;
/
