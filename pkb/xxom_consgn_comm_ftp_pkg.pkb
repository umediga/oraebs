DROP PACKAGE BODY APPS.XXOM_CONSGN_COMM_FTP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXOM_CONSGN_COMM_FTP_PKG" 
AS
   PROCEDURE gen_conf_file (p_file_name IN VARCHAR, p_data_dir VARCHAR2, p_arch_dir VARCHAR2)
   IS
      l_file_name       VARCHAR2 (200)     := p_file_name;
      l_file            UTL_FILE.file_type;
      l_file_path       VARCHAR2 (200)     := p_data_dir;                                           -- 'XXSGSFTOUT'; --
      l_arch_path       VARCHAR2 (200)     := p_arch_dir;                                             -- XXSGSFTARCH --
      l_ftp_seq         NUMBER;
      x_conc_req_id     NUMBER;
      x_error_message   VARCHAR2 (2000);
   BEGIN
      l_ftp_seq                  := -1;
      x_error_message            := NULL;
      x_conc_req_id              := 0;

      INSERT INTO xx_debug
           VALUES ('CONSGN_FTP',
                   '-- Gen Conf File --'
                  );

      l_file                     := UTL_FILE.fopen (l_file_path, l_file_name, 'W');
      UTL_FILE.put_line (l_file, 'INTEGRA');
      UTL_FILE.fclose (l_file);

      INSERT INTO xx_debug
           VALUES ('CONSGN_FTP',
                   'Conf File Creation Complete'
                  );

      add_new_file (l_file_name);
      ftp_data_file;
      COMMIT;
   EXCEPTION
      WHEN UTL_FILE.invalid_path
      THEN
         x_error_message            := 'The directory path : "' || l_file_path || '" does not exist. Please check it.';

         INSERT INTO xx_debug
              VALUES ('CONSGN_FTP',
                      'Error:' || x_error_message
                     );
      WHEN UTL_FILE.invalid_filehandle
      THEN
         x_error_message            := 'Not a Valid File Handle';

         INSERT INTO xx_debug
              VALUES ('CONSGN_FTP',
                      'Error:' || x_error_message
                     );
      WHEN UTL_FILE.invalid_operation
      THEN
         UTL_FILE.fclose (l_file);
         x_error_message            := 'File Is Not Open For Writing/Appending';

         INSERT INTO xx_debug
              VALUES ('CONSGN_FTP',
                      'Error:' || x_error_message
                     );
      WHEN UTL_FILE.write_error
      THEN
         UTL_FILE.fclose (l_file);
         x_error_message            := 'OS error occured during write operation';

         INSERT INTO xx_debug
              VALUES ('CONSGN_FTP',
                      'Error:' || x_error_message
                     );
      WHEN OTHERS
      THEN
         x_error_message            := 'ERROR IN xxom_consgn_comm_ftp_pkg.gen_conf_file:  ' || SUBSTR (SQLERRM, 1, 250);

         INSERT INTO xx_debug
              VALUES ('CONSGN_FTP',
                      'Error:' || x_error_message
                     );
   END gen_conf_file;

   PROCEDURE ftp_data_file
   IS
      x_conc_req_id   NUMBER;
      l_user_id     NUMBER := FND_GLOBAL.USER_ID;
      l_resp_id     NUMBER := FND_GLOBAL.RESP_ID;
      l_resp_appl_id     NUMBER := FND_GLOBAL.RESP_APPL_ID;
   BEGIN
      IF (l_user_id = -1) THEN 
        fnd_global.apps_initialize (0, 20420, 1, 0, -1);    --> Run as Sysadmin -- 
      ELSE
        fnd_global.apps_initialize (l_user_id, l_resp_id, l_resp_appl_id, 0, -1);
      END IF;
      
      INSERT INTO xx_debug
              VALUES ('CONSGN_FTP',
                      'Calling common FTP Concurrent Program'
                     );

      BEGIN
         x_conc_req_id              :=
            fnd_request.submit_request (application      => 'XXINTG',
                                        program          => 'XXINTGFTPFILES',
                                        description      => NULL,
                                        start_time       => SYSDATE,
                                        sub_request      => FALSE,
                                        argument1        => 'Ready'
                                       );
         COMMIT;

         INSERT INTO xx_debug
              VALUES ('CONSGN_FTP',
                      'Conc Req Id' || x_conc_req_id
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            INSERT INTO xx_debug
                 VALUES ('CONSGN_FTP',
                         'Cannot Fire Concurrent' || x_conc_req_id
                        );
      END;
   END ftp_data_file;

   PROCEDURE add_new_file (p_file_name IN VARCHAR)
   IS
      l_ftp_seq            NUMBER;
      l_file_name          VARCHAR2 (200)  := p_file_name;
      l_dest_server_path   VARCHAR2 (200);
      l_abs_file_path      VARCHAR2 (200);
      l_abs_arch_path      VARCHAR2 (200);
      x_error_message      VARCHAR2 (2000);
   BEGIN
      SELECT xxom_consgn_ftp_seq_s.NEXTVAL
        INTO l_ftp_seq
        FROM DUAL;

      BEGIN
         SELECT directory_path || '/'
           INTO l_abs_file_path
           FROM all_directories
          WHERE directory_name = 'XXSGSFTOUT';                                                  --like 'XXSGSFT%'--OUT';

         INSERT INTO xx_debug
              VALUES ('CONSGN_FTP',
                      'l_abs_file_path ' || l_abs_file_path
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_message            := 'Data Directory Not Defined ..XXSGSFTOUT';

            INSERT INTO xx_debug
                 VALUES ('CONSGN_FTP',
                         x_error_message
                        );

            RAISE;
      END;

--------------------------
-- Get archive DIR --
---------------------------
      BEGIN
         SELECT directory_path || '/'
           INTO l_abs_arch_path
           FROM all_directories
          WHERE directory_name = 'XXSGSFTARCH';                                                          --'XXSGSFTOUT';

         INSERT INTO xx_debug
              VALUES ('CONSGN_FTP',
                      'l_abs_arch_path ' || l_abs_arch_path
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_message            := 'Arch Directory Not Defined ..XXSGSFTARCH';
      END;

      ----------------------------------
-- Get Destination Server Dir --
----------------------------------
      BEGIN
         SELECT default_directory
           INTO l_dest_server_path
           FROM xx_fnd_sftp_server_details
          WHERE extn_sys_short_name = 'XXCONSGNFTP';                                                     --'XXSGSFTOUT';

         INSERT INTO xx_debug
              VALUES ('CONSGN_FTP',
                      'l_dest_server_path ' || l_dest_server_path
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_message            := 'Dest Server Path Not Defined ..' || l_dest_server_path;

            INSERT INTO xx_debug
                 VALUES ('CONSGN_FTP',
                         x_error_message
                        );

            RAISE;
      END;

      INSERT INTO xx_fnd_sftp_file_details
                  (x_interface_key,
                   extn_sys_short_name,
                   program_name,
                   file_name,
                   last_update_date,
                   last_updated_by,
                   creation_date,
                   created_by,
                   last_update_login,
                   file_status,
                   trans_mode,
                   schedule_time,
                   input_directory,
                   arch_directory,
                   output_directory,
                   ftp_type,
                   user_email_address,
                   is_format
                  )
           VALUES (l_ftp_seq,
                   'XXCONSGNFTP',
                   'XXCONSGNFTP',
                   l_file_name,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   'Ready',
                   NULL,
                   SYSDATE,
                   l_abs_file_path,
                   l_abs_arch_path,
                   l_dest_server_path,
                   'OUTBOUND',
                   NULL,
                   NULL
                  );

      COMMIT;
   END add_new_file;
END xxom_consgn_comm_ftp_pkg; 
/
