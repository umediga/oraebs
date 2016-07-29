DROP PACKAGE BODY APPS.XXOM_CNSGN_KPOOL_INFO_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXOM_CNSGN_KPOOL_INFO_PKG" IS
/*************************************************************************************
*   PROGRAM NAME
*     XXOM_CNSGN_KPOOL_INFO_PKG.sql
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
*     1.0  21-DEC-2013 Brian Stadnik
*
* ISSUES:
* 
******************************************************************************************/

PROCEDURE INTG_SER_INFO_EXT_PRC (errbuf                 OUT VARCHAR2,
                                 retcode             OUT VARCHAR2,
                                 p_orgn_id              IN  NUMBER)

IS

   v_status          VARCHAR2(20);
   l_proc_status     VARCHAR2(1) := 'P';
   --l_proc_date     DATE := SYSDATE;
   l_to_orgn_id      NUMBER := p_orgn_id;
   lv_count          NUMBER := 0;
   
   
   -- Cursor to get the keeper pool serial details
   CURSOR keeper_pool IS
      SELECT msn.inventory_item_id,
             msn.serial_number,
             NVL (msn.attribute11, 'L') attribute11,
             msn.attribute12 attribute12
        FROM mtl_serial_numbers msn--, XXOM_SERIAL_INFO_STG xsis
       WHERE msn.current_organization_id = p_orgn_id
         AND msn.current_status = 3
      --         AND (msn.attribute12 IS NOT NULL OR msn.attribute11 IS NOT NULL)
      --         AND msn.last_update_date > NVL ( (TO_DATE (msn.attribute13, 'DD-MON-RRRR HH24:MI:SS')), msn.last_update_date - 1);--check for NOT NULL
         --AND xsis.serial_number (+) = msn.serial_number
         --AND xsis.inventory_item_id (+) = msn.inventory_item_id
               --and msn.last_update_date >= NVL ( (TO_DATE (xsis.transaction_date, 'DD-MON-RRRR HH24:MI:SS')), msn.last_update_date- 1);
         AND msn.last_update_date >= NVL ((SELECT MAX (to_date(transaction_date,'DD-MON-RRRR HH24:MI:SS'))
                                             FROM XXOM_SERIAL_INFO_STG
                                            WHERE serial_number = msn.serial_number
                                              AND inventory_item_id = msn.inventory_item_id), 
                                          msn.last_update_date - 1);

BEGIN
   apps.fnd_file.put_line (
                       fnd_file.LOG,
                       'p_orgn_id: ' || p_orgn_id
                    );
   
   FOR c1_keeper_pool IN keeper_pool LOOP
      EXIT when keeper_pool%NOTFOUND;
   
      -- Put any Validations/select queries if required here
      
      -- Inserting into staging table from cursor
   
      INSERT INTO XXOM_SERIAL_INFO_STG
         (    
            transaction_id,
            transaction_date,
            inventory_item_id,
            organization_id,
            serial_number,
            keeper_pool,
            permanent_rep,
            creation_date,
            status,
            message
         )
        VALUES
         (
            XXOM_SERIAL_INFO_STG_TRAN_SEQ.NEXTVAL,
            l_proc_date,
            c1_keeper_pool.inventory_item_id,
            p_orgn_id,
            c1_keeper_pool.serial_number,
            c1_keeper_pool.attribute11,
            c1_keeper_pool.attribute12,
            SYSDATE,
            NULL,
            NULL
         );
      lv_count := lv_count + 1;
      END LOOP;

   l_proc_status:= 'P';
   COMMIT;
   apps.fnd_file.put_line (
                           fnd_file.LOG,
                           'In lv_count > 1: ' || lv_count
                           );
   IF l_proc_status = 'P'
   THEN
      INTG_SER_INFO_EXP_PRC(l_to_orgn_id);
   END IF;

EXCEPTION
WHEN OTHERS THEN
ROLLBACK;
      fnd_file.put_line (fnd_file.LOG, 'Cannot create an Extract file.. No Data loaded into Staging table: ' || SQLERRM);
END INTG_SER_INFO_EXT_PRC;

 PROCEDURE INTG_SER_INFO_ERR_PRC (  p_msg         IN VARCHAR2,
                                 p_status      IN VARCHAR2,
                                 p_trans_id    IN NUMBER)
   IS
   BEGIN
      UPDATE   XXINTG.XXOM_SERIAL_INFO_STG
         SET   status = p_status,
               message = p_msg
       WHERE   transaction_id = p_trans_id;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Log_msg: ' || SQLERRM);
   END INTG_SER_INFO_ERR_PRC;


PROCEDURE INTG_SER_INFO_EXP_PRC(l_to_orgn_id  NUMBER)
   -------------------------------------------------------------------------------------------------------------|
   --|   This Procedure(INTG_SER_INFO_EXP_PRC ) will create the data files from staging tables           |
   --|   XXOM_SERIAL_INFO_STG and Update staging table with the export date and file name to mark the record    |
   --|   as processed.                                                                                          |
   -------------------------------------------------------------------------------------------------------------|

IS


   l_batch_no           NUMBER;
   l_comm_seq_no        NUMBER;
   l_errmsg             VARCHAR2(1000);
   
   l_file_handle        UTL_FILE.file_type;
   l_file_handle_arch   UTL_FILE.file_type;
   l_file_dir           VARCHAR2(100) := 'XXSGSFTOUT';
   l_file_path          VARCHAR2(500);
   l_file_name          VARCHAR2 (50);
   l_file_name1         VARCHAR2 (50);
   
   l_division           VARCHAR2 (50);  
   e_validation_err     EXCEPTION;
      
   CURSOR c_div
   IS
      SELECT distinct nvl(xsms.snm_division, 'nodiv') snm_division
        FROM XXOM_SERIAL_INFO_STG xsis,  
             XXOM_SALES_MARKETING_SET_V xsms
       WHERE SS_KPOOL_INTF_DATE IS NULL
         AND xsis.inventory_item_id = xsms.inventory_item_id (+) 
         AND xsis.organization_id = xsms.organization_id (+)
       ORDER BY snm_division;

   CURSOR c1(cp_division IN VARCHAR2)
   IS
      SELECT transaction_id,
             transaction_date,
             xsis.inventory_item_id,
             serial_number,
             xsis.organization_id,
             keeper_pool,
             permanent_rep
        FROM XXOM_SERIAL_INFO_STG xsis,  
             XXOM_SALES_MARKETING_SET_V xsms
       WHERE SS_KPOOL_INTF_DATE is null
         AND xsis.inventory_item_id = xsms.inventory_item_id (+) 
         and xsis.organization_id = xsms.organization_id (+)
         and nvl(xsms.snm_division, 'nodiv') = cp_division
       ORDER BY transaction_id;

   BEGIN

      apps.fnd_file.put_line (fnd_file.LOG, 'In procedure INTG_SER_INFO_EXP_PRC');

      FOR r_div in c_div LOOP
         l_division := r_div.snm_division;
       
/*
     -- Derive Division to be placed in file name
     DECLARE
        v_kit_item_id NUMBER;
        v_organization_id NUMBER;

     BEGIN
              SELECT  inventory_item_id, organization_id INTO v_kit_item_id, v_organization_id                     
                FROM XXOM_SERIAL_INFO_STG
               WHERE SS_KPOOL_INTF_DATE is null
                 AND ROWNUM=1;
            
              SELECT mck.segment4 snm_division   
                INTO l_division     
                FROM   mtl_item_categories mic,
                       mtl_categories_kfv mck,
                       mtl_category_sets mcs
               WHERE   mck.category_id = mic.category_id
                 AND mic.organization_id = v_organization_id 
                 AND mic.category_set_id = mcs.category_set_id
                 AND UPPER (mcs.category_set_name) = UPPER ('SALES AND MARKETING')                                           
                 AND mck.category_id = mic.category_id
                 AND INVENTORY_ITEM_ID = v_kit_item_id; 
                 
                fnd_file.put_line (fnd_file.LOG, 'l_division : ' || l_division ); 
      
      EXCEPTION
        WHEN OTHERS THEN
              fnd_file.put_line (fnd_file.LOG, 'Unable to derive parent item to determine division');
              l_division := null;
      END;
*/      


         BEGIN
            SELECT XXOM_CNSGN_CMN_FILE_SEQ.NEXTVAL
              INTO l_comm_seq_no
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS THEN
               apps.fnd_file.put_line (fnd_file.LOG, 'Unable to fetch common sequence value: ' || l_comm_seq_no);
               RAISE e_validation_err;          
         END;

         BEGIN     
            SELECT XXOM_SERIAL_INFO_STG_SEQ.NEXTVAL 
              INTO l_int_seq_no 
              FROM DUAL;         
            --fnd_file.put_line (fnd_file.LOG, 'l_int_seq_no : ' || l_int_seq_no );
         EXCEPTION
            WHEN OTHERS THEN
               apps.fnd_file.put_line ( fnd_file.LOG, 'Unable to fetch sequence l_int_seq_no value: ' || l_int_seq_no);            
               RAISE e_validation_err;          
         END;

         BEGIN
            l_file_name  := l_comm_seq_no || '_SERIAL_' || l_int_seq_no ||'_'||l_division||'.tx1';
            l_file_name1 := l_comm_seq_no || '_SERIAL_' || l_int_seq_no ||'_'||l_division||'.txt';
            
            l_file_handle      := UTL_FILE.fopen (l_file_dir, l_file_name, 'w');
            --l_file_handle_arch := UTL_FILE.fopen ('XXSGSFTOUTARCH', l_file_name, 'w');
         
            apps.fnd_file.put_line (
               fnd_file.LOG,
               'l_file_name: ' || l_file_name
               );
            
            apps.fnd_file.put_line (
               fnd_file.LOG,
               'l_int_seq_no: ' || l_int_seq_no
               );
         
         EXCEPTION
            WHEN OTHERS THEN
               apps.fnd_file.put_line (
                  fnd_file.LOG,
                  'Unable to find directory: ' || l_file_dir
                  );               
               RAISE e_validation_err; 
         END;
                         

         UTL_FILE.PUT_LINE (
                           l_file_handle,
                              'TRANSACTION_ID'
                           || '|'
                           || 'TRANSACTION_DATE'
                           || '|'
                           || 'INVENTORY_ITEM_ID'
                           || '|'
                           || 'SERIAL_NUMBER'
                           || '|'
                           || 'KEEPER_POOL'
                           || '|'
                           || 'PERMANENT_REP'
                           || '|'
                          );

         FOR c1_rec in c1(r_div.snm_division) LOOP
         --      EXIT WHEN c1%NOTFOUND;
         
            UTL_FILE.PUT_LINE (
                              l_file_handle,
                                 c1_rec.transaction_id
                              || '|'
                              || c1_rec.transaction_date
                              || '|'
                              || c1_rec.inventory_item_id
                              || '|'
                              || c1_rec.serial_number
                              || '|'
                              || c1_rec.keeper_pool
                              || '|'
                              || c1_rec.permanent_rep
                              || '|'
                              );
            
            -- UTL_FILE.fflush (l_file_handle);
            
            UPDATE XXOM_SERIAL_INFO_STG
               SET status = 'SUCCESS',
                   message = 'File has been extracted and moved to ' || l_file_dir,
                   SS_KPOOL_FILE_NAME = l_file_name,
                   SS_KPOOL_INTF_DATE = SYSDATE
             WHERE transaction_id = c1_rec.transaction_id;
         
         END LOOP;
         
         COMMIT;
         
         UTL_FILE.fflush (l_file_handle);
         UTL_FILE.fclose (l_file_handle);
         UTL_FILE.FRENAME('XXSGSFTOUT', l_file_name, 'XXSGSFTOUT', l_file_name1, TRUE);
         -- UTL_FILE.fflush (l_file_handle_arch);
         -- UTL_FILE.fclose (l_file_handle_arch);
     
      END LOOP; --Division
   
   EXCEPTION
      WHEN UTL_FILE.invalid_mode
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Invalid Mode Parameter');
        dbms_output.put_line('Invalid Mode Parameter');
      WHEN UTL_FILE.invalid_path
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Invalid File Location');
         dbms_output.put_line('Invalid File Location');
      WHEN UTL_FILE.invalid_filehandle
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Invalid Filehandle');
         dbms_output.put_line('Invalid Filehandle');
      WHEN UTL_FILE.invalid_operation
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Invalid Operation');
         dbms_output.put_line('Invalid Operation');
      WHEN UTL_FILE.read_error
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Read Error');
         dbms_output.put_line('Read Error');
      WHEN UTL_FILE.internal_error
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Internal Error');
         dbms_output.put_line('Internal Error');
      WHEN UTL_FILE.charsetmismatch
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Opened With FOPEN_NCHAR But Later I/O Inconsistent');
         dbms_output.put_line('Opened With FOPEN_NCHAR But Later I/O Inconsistent'       );
      WHEN UTL_FILE.file_open
      THEN
         fnd_file.put_line (fnd_file.LOG, 'File Already Opened');
         dbms_output.put_line('File Already Opened');
      WHEN UTL_FILE.invalid_maxlinesize
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Line Size Exceeds 32K');
         dbms_output.put_line('Line Size Exceeds 32K');
      WHEN UTL_FILE.invalid_filename
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Invalid File Name');
         dbms_output.put_line('Invalid File Name');
      WHEN UTL_FILE.access_denied
      THEN
         fnd_file.put_line (fnd_file.LOG, 'File Access Denied By');
        dbms_output.put_line('File Access Denied By');
      WHEN UTL_FILE.invalid_offset
      THEN
         fnd_file.put_line (fnd_file.LOG, 'FSEEK Param Less Than 0');
        dbms_output.put_line('FSEEK Param Less Than 0');
      WHEN e_validation_err 
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Validation Error Occured');
        dbms_output.put_line('Validation Error Occured'); 
      WHEN OTHERS
      THEN
        fnd_file.put_line (fnd_file.LOG, 'Unknown UTL_FILE Error');
         dbms_output.put_line('Unknown UTL_FILE Error');
   END INTG_SER_INFO_EXP_PRC;
END XXOM_CNSGN_KPOOL_INFO_PKG;
/
