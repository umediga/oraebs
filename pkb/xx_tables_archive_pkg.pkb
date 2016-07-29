DROP PACKAGE BODY APPS.XX_TABLES_ARCHIVE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_TABLES_ARCHIVE_PKG" 
--------------------------------------------------------------------------------
/* $Header: XXTBLAR.pkb 2012/12/16 00:00:00 dsengupta noship $ */
/*
Created By   : IBM Development Team
Creation Date: 16-Dec-11
File Name    : XXTBLAR.pkb
Description  : Point to point interface Tables Archive Package developed as part
of Interface Template for Integra Delphi R12 Implementation Project.
Change History:
Date                Name   Remarks
---------           ----------  -----------------------------------------
16-Dec-11           IBM Development Team Initial Development
*/
--------------------------------------------------------------------------------
AS
   ---------------------------------Global variables declaration--------------------------------
   g_created_by         NUMBER := fnd_global.user_id;
   g_last_update_by     NUMBER := fnd_global.user_id;
   g_last_updated_login NUMBER
         := fnd_profile.VALUE (xx_emf_cn_pkg.CN_LOGIN_ID) ;
   g_last_update_date   DATE := SYSDATE;
   invalid_identifier EXCEPTION;
   PRAGMA EXCEPTION_INIT (invalid_identifier, -904);

   /****************************************Procedure to archive tables************************/
   /****************************************Purge data from archive tables*********************/
   PROCEDURE purge_archived_data
   IS
      CURSOR c_archive_dtls
      IS
         SELECT   lookup_type,
                  LOOKUP_CODE,
                  meaning,
                  description,
                  tag
           FROM   fnd_lookup_values_vl
          WHERE       lookup_type = 'XX_TABLE_ARCHIVE_DTLS'
                  AND enabled_flag = 'Y'
                  AND NVL (end_date_active, SYSDATE) >= SYSDATE;

      CURSOR c_table_cols (cp_table_name IN VARCHAR2)
      IS
         SELECT   column_name
           FROM   all_tab_columns
          WHERE   table_name = cp_table_name;

      x_stmt               VARCHAR2 (4000);
      x_stmt1              VARCHAR2 (4000);
      x_stmt_arch          VARCHAR2 (4000);
      x_columns            VARCHAR2 (2000);
      x_totarchive         NUMBER := 0;
      x_totcustdelete      NUMBER := 0;
      x_totarchivedelete   NUMBER := 0;
   BEGIN
      ------ Print Header ----------
      FND_FILE.PUT_LINE (
         fnd_file.OUTPUT,
         rpad('Table Name',40,' ')||rpad('Archive Table',40,' ')||rpad('Records Deleted',20,' ')||rpad('Records Archived',20,' ')||rpad('Records Purged',20,' ')
      );
      FND_FILE.PUT_LINE (
         fnd_file.OUTPUT,
         rpad('-',140,'-')
      );

      FOR rec_table IN c_archive_dtls
      LOOP
         x_totarchive := 0;
         x_totcustdelete := 0;
         x_totarchivedelete := 0;
         IF rec_table.lookup_code != rec_table.meaning
         THEN
            x_columns := NULL;

            FOR rec_table_cols IN c_table_cols (rec_table.meaning)
            LOOP
               x_columns := x_columns || rec_table_cols.column_name || ',';
            END LOOP;

            x_columns := SUBSTR (x_columns, 1, (LENGTH (x_columns) - 1));
            x_stmt :=
                  'insert into '
               || rec_table.meaning
               || '('
               || x_columns
               || ')'
               || 'Select '
               || x_columns
               || ' from '
               || rec_table.lookup_code
               || ' a WHERE trunc(a.creation_date)     < trunc(sysdate - '
               || TO_NUMBER (rec_table.description)
               || ')        OR    trunc(a.last_update_date)  < trunc(sysdate - '
               || TO_NUMBER (rec_table.description)
               || ')';

            IF rec_table.TAG IS NOT NULL
            THEN
               x_stmt_arch :=
                  'Delete from ' || rec_table.meaning
                  || '  a where trunc(a.creation_date)     < trunc(sysdate - '
                  || TO_NUMBER (rec_table.TAG)
                  || ')  OR trunc(a.last_update_date)  < trunc(sysdate - '
                  || TO_NUMBER (rec_table.TAG)
                  || ') ';
               xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, X_STMT_ARCH);

               EXECUTE IMMEDIATE x_stmt_arch;

               x_totarchivedelete := sql%ROWCOUNT;
            END IF;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, x_stmt);

            EXECUTE IMMEDIATE x_stmt;

            x_totarchive := sql%ROWCOUNT;
         END IF;

         x_stmt1 :=
               'Delete from '
            || rec_table.lookup_code
            || '  a where trunc(a.creation_date)     < trunc(sysdate - '
            || TO_NUMBER (rec_table.description)
            || ')  OR    trunc(a.last_update_date)  < trunc(sysdate - '
            || TO_NUMBER (rec_table.description)
            || ') ';
         xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, x_stmt);

         EXECUTE IMMEDIATE x_stmt1;

         x_totcustdelete := sql%ROWCOUNT;
         XX_EMF_PKG.WRITE_LOG (
            XX_EMF_CN_PKG.CN_MEDIUM,
            'Records deleted from' || rec_table.LOOKUP_CODE
         );
         FND_FILE.PUT_LINE (
            FND_FILE.OUTPUT,
               rpad(rec_table.LOOKUP_CODE,40,' ')
            || rpad(rec_table.MEANING,40,' ')
            || rpad(x_totcustdelete,20,' ')
            || rpad(x_totarchive,20,' ')
            || rpad(x_totarchivedelete,20,' ')
         );
      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.error (
            xx_emf_cn_pkg.CN_High,
            'Technical',
               'Error in Tables archive process : Error Code: '
            || SQLCODE
            || ':'
            || SQLERRM,
            '',
            '',
            '',
            '',
            ''
         );
   END purge_archived_data;

   /***************************************Main Function**************************************/
   PROCEDURE Main (o_errbuf OUT VARCHAR2, o_retcode OUT NUMBER)
   IS
      x_emf_env_value   NUMBER;
      E_ENV_SETUP EXCEPTION;
   BEGIN
      -- Set the EMF environment
      x_emf_env_value := xx_emf_pkg.set_env;

      IF x_emf_env_value > 0
      THEN
         RAISE E_ENV_SETUP;
      END IF;

      -- Archive data to backup tables
      -- archive_custom_tables; Commented out
      -- Purge data from base and archive tables
      purge_archived_data;
      COMMIT;
   EXCEPTION
      WHEN E_ENV_SETUP
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Error in EMF Environment setup');
         xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                               'Error in EMF Environment setup');
      WHEN OTHERS
      THEN
         xx_emf_pkg.error (
            xx_emf_cn_pkg.CN_High,
            'Technical',
               'Error in Tables purge process : Error Code: '
            || SQLCODE
            || ':'
            || SQLERRM,
            '',
            '',
            '',
            '',
            ''
         );
         ROLLBACK;
   END MAIN;
END XX_TABLES_ARCHIVE_PKG;
/


GRANT EXECUTE ON APPS.XX_TABLES_ARCHIVE_PKG TO INTG_XX_NONHR_RO;
