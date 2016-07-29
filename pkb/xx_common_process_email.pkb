DROP PACKAGE BODY APPS.XX_COMMON_PROCESS_EMAIL;

CREATE OR REPLACE PACKAGE BODY APPS."XX_COMMON_PROCESS_EMAIL" 
IS
   /*******************************************************************************
   -- Created By    : IBM Development
   -- Created  on   : 07-MAR-2012
   -- File Name     : XXCOMMONPROCESSEMAIL.pkb
   -- Description   : Custom Common Process to Send email for each custom process
   --
   --
   -- Change History:
   -- Date        Name       Ver Remarks
   -- ----------- ---------  --- ---------------------------------------------
   -- 07-MAR-2012 IBM Development  1.0  Initial Version

   *******************************************************************************/
   --

   g_session_id   number := xx_emf_debug_trace_s.NEXTVAL;
   g_debug_id     number;
   g_request_id   number;

   -- Function to get the concurrent program's log and output links
   FUNCTION XX_LINK_OUTPUTLOG (p_request_id   IN     NUMBER,
                               x_log_url         OUT VARCHAR2,
                               x_out_url         OUT VARCHAR2)
      RETURN VARCHAR2
   IS
      CURSOR gwyid_cur
      IS
         SELECT   profile_option_value
           FROM   fnd_profile_options o, fnd_profile_option_values ov
          WHERE       profile_option_name = 'GWYUID'
                  AND o.application_id = ov.application_id
                  AND o.profile_option_id = ov.profile_option_id;

      CURSOR two_task_cur
      IS
         SELECT   profile_option_value
           FROM   fnd_profile_options o, fnd_profile_option_values ov
          WHERE       profile_option_name = 'TWO_TASK'
                  AND o.application_id = ov.application_id
                  AND o.profile_option_id = ov.profile_option_id;

      l_request_id   NUMBER := 2237497;
      l_two_task     VARCHAR2 (256);
      l_gwyuid       VARCHAR2 (256);
      v_out_url      VARCHAR2 (1024);
      v_log_url      VARCHAR2 (1024);
      l_stauts       VARCHAR2 (1) := 'S';
   BEGIN
      l_request_id := p_request_id;

      OPEN gwyid_cur;

      FETCH gwyid_cur INTO   l_gwyuid;

      IF gwyid_cur%NOTFOUND
      THEN
         l_stauts := 'E';
         put_line ('Profile Option GWYUID is Missing');
      END IF;

      CLOSE gwyid_cur;

      OPEN two_task_cur;

      FETCH two_task_cur INTO   l_two_task;

      IF two_task_cur%NOTFOUND
      THEN
         l_stauts := 'E';
        --##  put_line ('Profile Option TWO_TASK Missing');
      END IF;

      x_out_url :=
         fnd_webfile.get_url (file_type     => fnd_webfile.request_out,
                              id            => l_request_id,
                              gwyuid        => l_gwyuid,
                              two_task      => l_two_task,
                              expire_time   => 100      -- minutes, security!.
                                                  );

      x_log_url :=
         fnd_webfile.get_url (file_type     => fnd_webfile.request_log,
                              id            => l_request_id,
                              gwyuid        => l_gwyuid,
                              two_task      => l_two_task,
                              expire_time   => 100      -- minutes, security!.
                                                  );

      --put_line( 'x_log_url '||x_log_url);
      --put_line( 'x_ou_url '||x_out_url);
      RETURN l_stauts;
   END XX_LINK_OUTPUTLOG;

   ---

   --- Get email address from process setup form
   FUNCTION EMAIL (p_process_name IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_email_address   xx_emf_process_setup.notification_group%TYPE;
   BEGIN
      SELECT   notification_group
        INTO   l_email_address
        FROM   xx_emf_process_setup
       WHERE   process_name = p_process_name;

      RETURN l_email_address;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
      WHEN OTHERS
      THEN
          put_line ('Process ' || p_process_name || ' Not Defined in PS Form ');
         RETURN 'ERR-EMAIL';
   END EMAIL;

   ---

   --- Procedure to get the concurrent Progream name
   FUNCTION CONC_NAME (p_request_Id   IN     VARCHAR2,
                       x_conc_name       OUT VARCHAR2,
                       x_user            OUT VARCHAR2)
      RETURN VARCHAR2
   IS
      CURSOR request_cur
      IS
         SELECT   requested_by, concurrent_program_id
           FROM   fnd_concurrent_requests
          WHERE   request_id = p_request_Id;

      --l_conc_name     fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
      --l_user_name     fnd_user.user_name%TYPE;

      request_rec   request_cur%ROWTYPE;
   BEGIN
      OPEN request_cur;

      FETCH request_cur INTO   request_rec;

      IF request_cur%NOTFOUND
      THEN
        --##  put_line ('Request Id ' || p_request_id || ' does not exists ');
         x_conc_name := 'ERR-Concname';
         x_user := 'ERR-User';
        --##  put_line (' Request id not found ' || p_request_id);

         CLOSE request_cur;

         RETURN 'E';
      END IF;

      CLOSE request_cur;

      SELECT   user_name
        INTO   x_user
        FROM   fnd_user
       WHERE   user_id = request_rec.requested_by;

      SELECT   user_concurrent_program_name
        INTO   x_conc_name
        FROM   fnd_concurrent_programs_vl
       WHERE   concurrent_program_id = request_rec.concurrent_program_id;

      -- AND Language ='US';

      RETURN 'S';
   EXCEPTION
      WHEN OTHERS
      THEN
          put_line ('Request Id ' || p_request_id || ' Does not Exists ');
         RETURN 'ERR-NAME';
   END CONC_NAME;

   ---
   FUNCTION EMAIL_CHECK (EMAIL_ID VARCHAR2)
      RETURN NUMBER
   AS
      --PARAGMA AUTONOMOUS_TRANSACTION;
      VALID   NUMBER;
   BEGIN
      SELECT   1
        INTO   VALID
        FROM   (SELECT   EMAIL_ID FROM DUAL)
       WHERE   REGEXP_LIKE (EMAIL_ID, '.*\@.*\..*');

      IF VALID = 1
      THEN
        --##  put_line ('EMAIL ID ' || EMAIL_ID || ' IS  VALID');
         RETURN 1;
      ELSE
         --PUT_LINE('EMAIL ID ' || EMAIL_ID || ' IS NOT VALID');
         RETURN 0;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
          put_line ('EMAIL ID ' || EMAIL_ID || ' IS NOT VALID');
         RETURN 0;
      WHEN OTHERS
      THEN
          put_line ('EMAIL ID ' || EMAIL_ID || ' IS NOT VALID');
         RETURN 0;
   END;

   -- Procedure to send email
   PROCEDURE NOTIFY_USER (p_request_id IN NUMBER)    --,x_status OUT VARCHAR2)
   IS
      CURSOR get_psf_params                  --(p_wms_system_name IN VARCHAR2)
      IS
         SELECT   parameter_name,
                  epp.parameter_value,
                  eps.process_type,
                  eps.process_name
           FROM   xxintg.xx_emf_process_setup eps,
                  xxintg.xx_emf_process_parameters epp,
                  apps.fnd_concurrent_requests fcr,
                  apps.fnd_concurrent_programs fcp,
                  apps.fnd_user fu
	  WHERE   fcr.concurrent_program_id = fcp.concurrent_program_id
                  AND fcp.concurrent_program_name = eps.process_name
		  AND fcr.requested_by = fu.user_id
                  AND eps.process_id = epp.process_id
                  AND fcr.request_id = p_request_id;

      CURSOR get_email_from_dl (p_dl IN VARCHAR2) IS
      SELECT meaning
        FROM
          (SELECT meaning
             FROM fnd_lookup_values
            WHERE lookup_type = upper(p_dl)
              AND language = userenv('LANG')
            UNION
           SELECT DECODE(COUNT(1),0, p_dl,null) meaning
             FROM fnd_lookup_values
            WHERE lookup_type =upper(p_dl)
              AND language = userenv('LANG'))
            WHERE meaning is not null;

      CURSOR get_email (
         p_email   IN            VARCHAR2
      )
      IS
         WITH data
                AS (    SELECT   SUBSTR (csv, INSTR (csv,
                                                     ',',
                                                     1,
                                                     LEVEL)
                                              + 1,   INSTR (csv,
                                                            ',',
                                                            1,
                                                            LEVEL + 1)
                                                   - INSTR (csv,
                                                            ',',
                                                            1,
                                                            LEVEL)
                                                   - 1)
                                    token
                          FROM   (SELECT   ',' || p_email || ',' csv
                                    FROM   SYS.DUAL)
                    CONNECT BY   LEVEL <
                                      LENGTH (p_email)
                                    - LENGTH (REPLACE (p_email, ',', ''))
                                    + 2)
         SELECT   token
           FROM   data;

      l_log_stauts          VARCHAR2 (20);
      l_out_link            VARCHAR2 (200);
      l_log_link            VARCHAR2 (200);
      l_email               VARCHAR2 (2000);
      l_email_wms           VARCHAR2 (2000);
      l_conc_name           VARCHAR2 (120);
      l_user_name           VARCHAR2 (120);
      l_tst                 VARCHAR2 (120);
      j                     NUMBER;
      l_database            v$database.name%TYPE;
      l_count_record        NUMBER;
      l_no_of_rec_process   VARCHAR2(100);
      l_set_env_code        NUMBER;
      l_process_name        VARCHAR2 (200);
      l_param_tab           Argtbl;
      l_send_email_flag     VARCHAR2 (1) := 'N';
      l_send_email_on_wrn   VARCHAR2 (1) := 'N';
      l_send_email_on_err   VARCHAR2 (1) := 'N';
      l_param_txt           VARCHAR2 (2000);
      l_stm                 VARCHAR2 (2000);
      l_argument_text       fnd_concurrent_requests.argument_text%TYPE;
      l_wms_system_name     xx_emf_process_parameters.parameter_name%TYPE;
      l_table_name          VARCHAR2 (200);
      l_column_name         VARCHAR2 (200) := 'REQUEST_ID';
      l_process_type        VARCHAR2 (200);
      l_g2000_flag          VARCHAR2 (1) := 'N';
      l_casestack_flag      VARCHAR2 (1) := 'N';
      l_cadence_flag        VARCHAR2 (1) := 'N';
      x_status              VARCHAR2 (200);
      x_request_id          NUMBER;
      l_valid_email         NUMBER := 0;
      sleep                 BOOLEAN;
      v_status_code         VARCHAR2 (100);
      v_sleep_time          NUMBER := 0;
      l_status_code         VARCHAR2 (2);
   BEGIN
      g_request_id := p_request_id;
      x_status := 'S';
      j := 0;

      dbms_output.put_line('123');
      put_line ('Entering Notify User Request_id : ' || p_request_id);

      -- Get concurrent request arguments
      SELECT   argument_text
        INTO   l_argument_text
        FROM   fnd_concurrent_requests
       WHERE   request_id = p_request_id;


      --  Get process setup forms parameters
      FOR rec_psf_params IN get_psf_params
      LOOP
         l_process_type := rec_psf_params.process_type;
         l_process_name := rec_psf_params.process_name;


         IF l_process_type = 'INTERFACE'
         THEN
            IF rec_psf_params.parameter_name = 'TABLE_NAME'
            THEN
               l_table_name := rec_psf_params.parameter_value;
            ELSIF rec_psf_params.parameter_name = 'COLUMN_NAME'
            THEN
               l_column_name := rec_psf_params.parameter_value;
            END IF;
         END IF;


         IF INSTR (UPPER (rec_psf_params.parameter_name),
                   'SEND_EMAIL_ON_ERROR') > 0
         THEN
            l_send_email_on_err := 'Y';
            l_email_wms := rec_psf_params.parameter_value;
         END IF;

         IF INSTR (UPPER (rec_psf_params.parameter_name),
                   'SEND_EMAIL_ON_WARNING') > 0
         THEN
            l_send_email_on_wrn := 'Y';
            l_email_wms := rec_psf_params.parameter_value;
         END IF;

         IF UPPER (rec_psf_params.parameter_name)= 'SEND_EMAIL'
         THEN
            l_send_email_flag := 'Y';
            l_email_wms := rec_psf_params.parameter_value;
         END IF;

      END LOOP;


      -- Get User parameters
      USER_PARAM (p_request_id   => p_request_id,
                  x_praram       => l_param_tab,
                  j              => j,
                  x_request_id   => x_request_id);

      -- For Interfaces
      IF l_process_type = 'INTERFACE'
      THEN
         IF x_request_id IS NULL
         THEN
            x_request_id := p_request_id;
         END IF;

         BEGIN
           --##  put_line ('Execute dynamic query for interfaces');
            l_stm :=
                  'SELECT count(*)  FROM '
               || l_table_name
               || ' WHERE '
               || l_column_name
               || ' = '
               || x_request_id;

           --##  put_line ('Query - ' || l_stm);

            EXECUTE IMMEDIATE l_stm INTO   l_count_record;
         EXCEPTION
            WHEN OTHERS
            THEN
                put_line('Error while executing dynamic query for interfaces' || SQLERRM);
               x_status := 'E';
	       l_count_record := 0;
         END;

         IF l_count_record > 0
         THEN
            l_send_email_flag := 'Y';
	    l_no_of_rec_process := 'Total number of records processed : ' || l_count_record;
         ELSE
            l_send_email_flag := 'N';
           --##  put_line('Processing ends for interface as no rows exist for request id : '     || p_request_id);
         END IF;
      END IF;
      ------- Interface logic ends



      IF    l_send_email_flag = 'Y'
         OR l_send_email_on_err = 'Y'
         OR l_send_email_on_wrn = 'Y'
      THEN
         put_line ('Preparing to send Email'||l_email);
         l_email := EMAIL (l_process_name);
        --##  put_line ('l_email_wms after EMAIL  ' || l_email_wms);


         IF l_email_wms IS NOT NULL
         THEN
            IF l_email IS NOT NULL
            THEN
               l_email := l_email || ', ' || l_email_wms;
            ELSE
               l_email := l_email_wms;
            END IF;
         END IF;

         put_line ('Mail to be sent to '||l_email);


         l_tst :=
            CONC_NAME (p_request_Id   => p_request_id,
                       x_conc_name    => l_conc_name,
                       x_user         => l_user_name);


         SELECT   name INTO l_database FROM v$database;


         --- Check if the error has completed in error or warning
         sleep := TRUE;
         v_sleep_time := 0;
         v_status_code := NULL;

         WHILE (sleep)
         LOOP
            BEGIN
               SELECT   DECODE (status_code,
                                'E',
                                'with ERROR',
                                'G',
                                'with WARNING',
                                'C',
                                'NORMAL')
                 INTO   v_status_code
                 FROM   fnd_concurrent_requests
                WHERE   status_code IN ('E', 'C', 'G')
                        AND request_id = p_request_id;


            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                   put_line('Program still not completed in Normal, Warning or Error');
               WHEN OTHERS
               THEN
                   put_line (SQLERRM);
            END;


            IF v_status_code IS NOT NULL
            THEN
               sleep := FALSE;
               v_status_code :=
                     'The Concurrent Program has completed '
                  || v_status_code
                  || '.';

            ELSE
               DBMS_LOCK.SLEEP (30);

               SELECT   status_code
                 INTO   l_status_code
                 FROM   fnd_concurrent_requests
                WHERE   request_id = p_request_id;


               v_sleep_time := v_sleep_time + 30;

            END IF;
         END LOOP;


         IF l_send_email_flag <> 'Y'
         THEN
            IF l_send_email_on_wrn = 'Y'
            THEN
               IF l_send_email_on_err = 'Y'
               THEN
                  IF INSTR (UPPER (v_status_code), 'ERROR') = 0
                     AND INSTR (UPPER (v_status_code), 'WARNING') = 0
                  THEN
                     l_email := NULL;
                  END IF;
               ELSE
                  IF INSTR (UPPER (v_status_code), 'WARNING') = 0
                  THEN
                     l_email := NULL;
                  END IF;
               END IF;
            ELSE
               IF l_send_email_on_err = 'Y'
               THEN
                  IF INSTR (UPPER (v_status_code), 'ERROR') = 0
                  THEN
                     l_email := NULL;
                  END IF;
               ELSE
                  l_email := NULL;
               END IF;
            END IF;
         END IF;


         IF l_email IS NOT NULL
         THEN
            FOR rec_email IN get_email (l_email)
            LOOP
	       FOR rec_email_from_dl IN get_email_from_dl(rec_email.token) LOOP
                   l_log_stauts :=
                      XX_LINK_OUTPUTLOG (p_request_id   => p_request_id,
                                         x_log_url      => l_log_link,
                                         x_out_url      => l_out_link);

                  --##  put_line ('l_log_link ' || l_log_link);
                  --##  put_line ('l_out_link ' || l_out_link);

                   l_valid_email := EMAIL_CHECK (rec_email.token);

                   --put_line('Is '||rec_email.token||' email valid:  '||l_valid_email);

                   IF l_valid_email = 1 THEN
	            BEGIN
                      xx_intg_mail_util_pkg.mail (
                         l_database||'@integralife.com',
                         rec_email_from_dl.meaning              ,
                         'Req. ID -' || p_request_id || ' ' || l_conc_name,
                            'Hello,'
                         || CHR (10)
                         || CHR (10)
                         || 'Request id   : '
                         || p_request_id
                         || CHR (10)
                         || 'Submitted by : '
                         || l_user_name
                         || CHR (10)
                         || CHR (10)
                         || 'Program Name : '
                         || l_conc_name
                         || CHR (10)
                         || 'Output Link  : '
                         || l_out_link
                         || CHR (10)
                         || 'Log Link     : '
                         || l_log_link
                         || CHR (10)
                         || CHR (10)
                         || v_status_code
                         || CHR (10)
                         || 'Parameters '
                         || CHR (10)
                         || l_param_txt
                         || CHR (10)
		         || l_no_of_rec_process
                         || CHR (10)
                         || CHR (10)
                         || '**** This is a system generated mail. Please do not reply ***'
                      );
                      EXCEPTION
                        WHEN OTHERS
                            THEN
                            put_line ('Error while calling xx_intg_mail_util_pkg.mail  ' ||SQLERRM);

                      END;
                      put_line ('Mail sent to: ' || rec_email.token);
                   END IF;
	       END LOOP;
            END LOOP;
         END IF;
      END IF;                                                   --  send email
   --

   EXCEPTION
      WHEN OTHERS
      THEN
         put_line ('Request Id ' || p_request_id || ' Does not Exists ');
         put_line (' Notify User Exception ' || SQLERRM);
         x_status := 'E';
   END NOTIFY_USER;

   /* Procedure to get the arguments*/
   PROCEDURE USER_PARAM (p_request_id   IN     NUMBER,
                         x_praram          OUT ARGTBL,
                         j                 OUT NUMBER,
                         x_request_id      OUT number)
   IS
      CURSOR Passed_Arg_Cur
      IS
         SELECT   fcr.concurrent_program_id,
                  fcp.concurrent_program_name AS conc_short_name,
                  fcr.argument1,
                  fcr.argument2,
                  fcr.argument3,
                  fcr.argument4,
                  fcr.argument5,
                  fcr.argument6,
                  fcr.argument7,
                  fcr.argument8,
                  fcr.argument9,
                  fcr.argument10,
                  fcr.argument11,
                  fcr.argument12,
                  fcr.argument13,
                  fcr.argument14,
                  fcr.argument15,
                  fcr.argument16,
                  fcr.argument17,
                  fcr.argument18,
                  fcr.argument19,
                  fcr.argument20
           FROM   fnd_concurrent_requests fcr, fnd_concurrent_programs_vl fcp
          WHERE   fcr.concurrent_program_id = fcp.concurrent_program_id
                  AND request_id = p_request_id;

      CURSOR Defined_Arg_CUR (p_program_name VARCHAR2)
      IS
           SELECT   form_left_prompt,
                    application_column_name AS appl_col,
                    display_flag,
                    descriptive_flexfield_name
             FROM   FND_DESCR_FLEX_COL_USAGE_VL a
            WHERE   descriptive_flexfield_name = '$SRS$.' || p_program_name --like '%.XXWSHTRIPINT%'
         --      and display_flag ='Y'
         ORDER BY   column_seq_num;

      Passed_Arg_Rec   Passed_Arg_Cur%ROWTYPE;
      l_stm            VARCHAR2 (2000);
      abc              varchar2 (100);
   BEGIN
      j := 0;
      x_praram := ARGTBL ();

      OPEN Passed_Arg_Cur;

      FETCH Passed_Arg_Cur INTO   Passed_Arg_Rec;

      CLOSE Passed_Arg_Cur;

      FOR I
      IN Defined_Arg_CUR (p_program_name => Passed_Arg_Rec.conc_short_name)
      LOOP
         j := j + 1;
         x_praram.EXTEND (j);

         IF INSTR (UPPER (i.form_left_prompt), 'REQUEST') > 0
         THEN
            BEGIN
              --##  put_line ('Execute dynamic query to get parent request id');
               l_stm :=
                  'SELECT to_number(argument' || j
                  || ') FROM fnd_concurrent_requests fcr, fnd_concurrent_programs_vl fcp
                   WHERE  fcr.concurrent_program_id = fcp.concurrent_program_id
                     AND  request_id = '
                  || p_request_id;

              --##  put_line ('Query - ' || l_stm);

               EXECUTE IMMEDIATE l_stm INTO   x_request_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  put_line('Error while executing dynamic query to get parent request id'
                           || SQLERRM);
            END;
         END IF;

         IF i.display_flag = 'Y'
         THEN
            CASE
               WHEN J = 1
               THEN
                  x_praram (j).arg1 :=
                        RPAD (i.form_left_prompt, 20)
                     || ' = '
                     || Passed_Arg_Rec.argument1
                     || CHR (10);
               WHEN J = 2
               THEN
                  x_praram (j).arg1 :=
                        RPAD (i.form_left_prompt, 20)
                     || ' = '
                     || Passed_Arg_Rec.argument2
                     || CHR (10);
               WHEN J = 3
               THEN
                  x_praram (j).arg1 :=
                        RPAD (i.form_left_prompt, 20)
                     || ' = '
                     || Passed_Arg_Rec.argument3
                     || CHR (10);
               WHEN J = 4
               THEN
                  x_praram (j).arg1 :=
                        RPAD (i.form_left_prompt, 20)
                     || ' = '
                     || Passed_Arg_Rec.argument4
                     || CHR (10);
               WHEN J = 5
               THEN
                  x_praram (j).arg1 :=
                        RPAD (i.form_left_prompt, 20)
                     || ' = '
                     || Passed_Arg_Rec.argument5
                     || CHR (10);
               WHEN J = 6
               THEN
                  x_praram (j).arg1 :=
                        RPAD (i.form_left_prompt, 20)
                     || ' = '
                     || Passed_Arg_Rec.argument6
                     || CHR (10);
               WHEN J = 7
               THEN
                  x_praram (j).arg1 :=
                        RPAD (i.form_left_prompt, 20)
                     || ' = '
                     || Passed_Arg_Rec.argument7
                     || CHR (10);
               WHEN J = 8
               THEN
                  x_praram (j).arg1 :=
                        RPAD (i.form_left_prompt, 20)
                     || ' = '
                     || Passed_Arg_Rec.argument8
                     || CHR (10);
               WHEN J = 9
               THEN
                  x_praram (j).arg1 :=
                        RPAD (i.form_left_prompt, 20)
                     || ' = '
                     || Passed_Arg_Rec.argument9
                     || CHR (10);
               WHEN J = 10
               THEN
                  x_praram (j).arg1 :=
                        RPAD (i.form_left_prompt, 20)
                     || ' = '
                     || Passed_Arg_Rec.argument10
                     || CHR (10);
               WHEN J = 11
               THEN
                  x_praram (j).arg1 :=
                        RPAD (i.form_left_prompt, 20)
                     || ' = '
                     || Passed_Arg_Rec.argument11
                     || CHR (10);
               WHEN J = 12
               THEN
                  x_praram (j).arg1 :=
                        RPAD (i.form_left_prompt, 20)
                     || ' = '
                     || Passed_Arg_Rec.argument12
                     || CHR (10);
               WHEN J = 13
               THEN
                  x_praram (j).arg1 :=
                        RPAD (i.form_left_prompt, 20)
                     || ' = '
                     || Passed_Arg_Rec.argument13
                     || CHR (10);
               WHEN J = 14
               THEN
                  x_praram (j).arg1 :=
                        RPAD (i.form_left_prompt, 20)
                     || ' = '
                     || Passed_Arg_Rec.argument14
                     || CHR (10);
               WHEN J = 15
               THEN
                  x_praram (j).arg1 :=
                        RPAD (i.form_left_prompt, 20)
                     || ' = '
                     || Passed_Arg_Rec.argument15
                     || CHR (10);
               WHEN J = 16
               THEN
                  x_praram (j).arg1 :=
                        RPAD (i.form_left_prompt, 20)
                     || ' = '
                     || Passed_Arg_Rec.argument16
                     || CHR (10);
            END CASE;
         END IF;

        --##  put_line ('J: ' || j || ' , ' || x_praram (j).arg1);
      END LOOP;

     --##  put_line ('x_request_id : ' || x_request_id);
     --##  put_line ('Array Count ' || x_praram.COUNT);
   EXCEPTION
      WHEN OTHERS
      THEN
         put_line ('Unhandled Exception within USER_PARAM ' || SQLERRM);
         put_line (' USER_PARAM ' || SQLERRM);
   END USER_PARAM;

   --

   /*
                   ** put_line - Put (write) a line of text to file
    **
    ** IN
    **   WHICH - Log - FND_FILE.LOG
    **   BUFF - Text to write
    ** EXCEPTIONS
    **   utl_file.invalid_path       - file location or name was invalid
    **   utl_file.invalid_mode       - the open_mode string was invalid
    **   utl_file.invalid_filehandle - file handle is invalid
    **   utl_file.invalid_operation  - file is not open for writing/appending
    **   utl_file.write_error        - OS error occured during write operation
    */
   PROCEDURE put_line (                                     --WHICH in number,
                       BUFF IN varchar2)
   IS
      temp_file    varchar2 (255);                        -- used for messages
      user_error   varchar2 (255);           -- to store translated file_error
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      -- BUFF := 'In XX_COMMON_PROCESS_EMAIL: ' || BUFF;
      g_debug_id := NVL (g_debug_id, 0) + 1;

      INSERT INTO xx_emf_debug_trace (session_id,
                                      debug_id,
                                      debug_level,
                                      debug_text,
                                      request_id,
                                      process_name,
                                      process_id,
                                      created_by_user,
                                      created_by,
                                      creation_date,
                                      last_updated_by,
                                      last_update_date,
                                      last_update_login,
                                      attribute1)
        VALUES   (g_session_id,
                  g_debug_id,
                  1,
                  BUFF,
                  -999999,
                  'XX_COMMON_PROCESS_EMAIL',
                  -1,
                  -1,
                  -1,
                  SYSDATE,
                  -1,
                  SYSDATE,
                  -1,
                  g_request_id);

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         INSERT INTO xx_emf_debug_trace (debug_text)
           VALUES   ('Error in putline');

         COMMIT;
   END put_line;
/* End of Package*/
END XX_COMMON_PROCESS_EMAIL;
/


GRANT EXECUTE ON APPS.XX_COMMON_PROCESS_EMAIL TO INTG_XX_NONHR_RO;
