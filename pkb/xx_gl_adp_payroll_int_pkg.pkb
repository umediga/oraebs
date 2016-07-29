DROP PACKAGE BODY APPS.XX_GL_ADP_PAYROLL_INT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_GL_ADP_PAYROLL_INT_PKG" 
IS
   ----------------------------------------------------------------------
   /*
    Created By    : Renjith
    Creation Date :
    File Name     : XXGLADPPAYINT.pkb
    Description   : This script creates the specification of the package
                    xx_gl_adp_payroll_int_pkg
    Change History:
    Date        Name                  Remarks
    ----------- -------------         -----------------------------------
    19-JAN-2012 Renjith               Initial Version
    12-Apr-2013 Yogesh                Changed the procedure UTL_READ_INSERT_STG as per new design.
    17-Apr-2013 Yogesh                Changes for different group_id for records from different data files.
    26-Sep-2014	Vighnesh              changed as per case#10516 to fetch the name of reference4
    09-Feb-2015 Dhiren                Changed as per SFDC case #09144 : GL Accounting Period
   */
    ----------------------------------------------------------------------
    g_p_reprocess varchar2(100); --- Added on 09-Feb
    FUNCTION find_max ( p_error_code1 IN VARCHAR2,
                      p_error_code2 IN VARCHAR2) RETURN VARCHAR2
    IS
        x_return_value VARCHAR2(100);
    BEGIN
    x_return_value := XX_INTG_COMMON_PKG.find_max(p_error_code1, p_error_code2);

    RETURN x_return_value;
    END find_max;

    ----------------------------------------------------------------------

    FUNCTION next_field ( p_line_buffer     IN       VARCHAR2
                         ,p_delimiter       IN       VARCHAR2
                         ,x_last_position   IN OUT   NUMBER)
    RETURN VARCHAR2
    IS
      x_new_position     NUMBER (6)     := NULL;
      x_out_field        VARCHAR2 (20000) := NULL;
      x_delimiter        VARCHAR2 (200)  := p_delimiter;
      x_delimiter_size   NUMBER (2)     := 1;
    BEGIN

      x_new_position := INSTR (p_line_buffer, x_delimiter, x_last_position);

      IF x_new_position = 0 THEN
         x_new_position := LENGTH (p_line_buffer) + 1;
      END IF;

      x_out_field := SUBSTR (p_line_buffer, x_last_position, x_new_position - x_last_position);

      x_out_field := LTRIM (RTRIM (x_out_field));

      IF x_new_position = LENGTH (p_line_buffer) + 1 THEN
         x_last_position := 0;
      ELSE
         x_last_position := x_new_position + x_delimiter_size;
      END IF;

      RETURN x_out_field;
    EXCEPTION
       WHEN OTHERS THEN
          x_last_position := -1;
          RETURN ' Error :'||SQLERRM;
    END next_field;

    ----------------------------------------------------------------------

    FUNCTION get_emf_email_id ( p_process_name   IN       VARCHAR2,
                                x_email_id       OUT      VARCHAR2)
    RETURN NUMBER
    IS
      x_error_code   NUMBER          := xx_emf_cn_pkg.cn_success;
    BEGIN
      SELECT notification_group
        INTO x_email_id
        FROM xx_emf_process_setup
       WHERE process_name = p_process_name;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,x_email_id);
      RETURN x_error_code;
    EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,'Error In getting Email Id' || ' ' || SQLERRM);
         RETURN 2;
    END get_emf_email_id;

    ----------------------------------------------------------------------

   /* FUNCTION get_file_ftp
    RETURN NUMBER
    IS
       CURSOR  c_data_dir
       IS
       SELECT  directory_path
         FROM  all_directories
        WHERE  directory_name= g_data_dir;

      x_data_path  VARCHAR2(300);
      x_error_code   NUMBER          := xx_emf_cn_pkg.cn_success;

      x_wait_req          BOOLEAN;
      x_phase             VARCHAR2 (25);
      x_status            VARCHAR2 (25);
      x_dev_phase         VARCHAR2 (25);
      x_dev_status        VARCHAR2 (25);
      x_message           VARCHAR2 (2000);
      x_conc_id           NUMBER;
    BEGIN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside get_file_ftp');
         OPEN  c_data_dir;
         FETCH c_data_dir INTO x_data_path;
         IF c_data_dir%NOTFOUND THEN
           x_data_path := NULL;
         END IF;
         CLOSE c_data_dir;

         x_data_path := x_data_path||'/';

         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_data_path ->'||x_data_path);

         INSERT into xx_fnd_sftp_file_details
            ( x_interface_key
             ,extn_sys_short_name
             ,program_name
             ,file_name
             ,file_status
             ,trans_mode
             ,schedule_time
             ,input_directory
             ,arch_directory
             ,output_directory
             ,ftp_type
            )
         VALUES
            ( xx_emf_pkg.g_request_id
             ,'XXADPGL'               -- extn_sys_short_name
             ,'XXGLADPPAYROLL'        -- program_name
             , g_data_file_name       -- file_name
             ,'Ready'                 -- file_status
             ,'Immediate'             -- trans_mode
             , SYSDATE                -- schedule_time
             , g_ftp_data_dir_name    -- /home/hvijetha/INBOUND/
             , g_ftp_data_dir_arch    --  application arch
             , x_data_path            --  application data
             ,'INBOUND'               --  ftp_type
            );
         COMMIT;

         x_conc_id := FND_REQUEST.SUBMIT_REQUEST
                        ( application => 'XXINTG'
                         ,program     => 'CUSTOM_INBOUND_SFTP'
                         ,description => NULL
                         ,start_time  => SYSDATE
                         ,sub_request => FALSE
                         ,argument1   => 'XXGLADPPAYROLL'
                         ,argument2   => 'N');

         IF x_conc_id = 0 THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Launching FTP failed');
            x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
            RETURN x_error_code;
         ELSE
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Launching FTP success ->'||x_conc_id);
            COMMIT;
            x_wait_req := FND_CONCURRENT.WAIT_FOR_REQUEST
                              (request_id      => x_conc_id,
                               interval        => 0,
                               phase           => x_phase,
                               status          => x_status,
                               dev_phase       => x_dev_phase,
                               dev_status      => x_dev_status,
                               message         => x_message
                              );
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'x_dev_phase->'||x_dev_phase||'-'|| 'x_dev_status->'||x_dev_status);
            IF x_dev_phase = 'COMPLETE' AND x_dev_status = 'NORMAL' THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No FTP Errors');
            ELSE
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
            END IF;
          END IF;

      RETURN x_error_code;
    EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,'Error In FTP ' || ' ' || SQLERRM);
         RETURN xx_emf_cn_pkg.CN_PRC_ERR;
    END get_file_ftp;
    */
    ----------------------------------------------------------------------

    FUNCTION move_file_archive
    RETURN NUMBER
    IS
      x_error_code        NUMBER          := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER          := xx_emf_cn_pkg.cn_success;
      x_error_msg         VARCHAR2 (2000);
      x_email_id          VARCHAR2 (200);
      CURSOR c_name
      IS
      SELECT  DISTINCT file_name name
        FROM  xx_gl_adp_payroll_stg
       WHERE  request_id=FND_GLOBAL.CONC_REQUEST_ID;
    BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Moving File ->'||FND_GLOBAL.CONC_REQUEST_ID);
      BEGIN
        FOR r_name IN c_name LOOP
           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'File ->'||r_name.name);
           BEGIN
              UTL_FILE.frename ( G_DATA_DIR
                                ,r_name.name
                                ,G_ARCH_DIR
                                ,r_name.name
                                ,FALSE
                               );
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Successfully Move File :'||r_name.name);

           EXCEPTION
             WHEN OTHERS THEN
                 xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'move_file_archive ' || SQLERRM);
                 x_error_msg := 'Moving File :' || r_name.name || ' Error:' || SQLERRM;
                 x_error_code_temp := get_emf_email_id (xx_emf_pkg.g_process_name, x_email_id);
                 g_email_id := x_email_id;
                 x_error_code := find_max (x_error_code, x_error_code_temp);
                 IF x_email_id IS NOT NULL THEN
                    xx_intg_mail_util_pkg.mail ( sender     => 'ADP GL Interface'
                                                ,recipients => x_email_id
                                                ,subject    => 'Moving File Error - SQLERRM'
                                                ,message    => x_error_msg
                                               );
                 END IF;
                 x_error_code_temp:= xx_emf_cn_pkg.CN_REC_WARN;
           END;
        END LOOP;
        RETURN x_error_code;
    EXCEPTION
        WHEN OTHERS THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Error in move_file_archive ' || SQLERRM);
            x_error_msg := 'move_file_archive Error:' || SQLERRM;
            x_error_code_temp := get_emf_email_id (xx_emf_pkg.g_process_name, x_email_id);
            g_email_id := x_email_id;
            x_error_code := find_max (x_error_code, x_error_code_temp);

            IF x_email_id IS NOT NULL THEN
                    xx_intg_mail_util_pkg.mail ( sender     => 'ADP GL Interface'
                                                ,recipients => x_email_id
                                                ,subject    => 'Moving File Error - SQLERRM'
                                                ,message    => x_error_msg
                                               );
            END IF;
            x_error_code_temp:= xx_emf_cn_pkg.CN_REC_WARN;
      END;
      x_error_code := find_max (x_error_code, x_error_code_temp);
      RETURN x_error_code;
   END move_file_archive;

    ----------------------------------------------------------------------

    FUNCTION xx_global_var
    RETURN NUMBER
    IS
      x_error_code  NUMBER := xx_emf_cn_pkg.cn_success;
    BEGIN
      FOR a IN (SELECT parameter_name, parameter_value
                   FROM xx_emf_process_parameters xpp,
                        xx_emf_process_setup xps
                  WHERE 1 = 1
                    AND xps.process_id   = xpp.process_id
                    AND xps.process_name = 'XXGLADPUTL')
      LOOP
          IF a.parameter_name = 'DATA_DIR_NAME' THEN
             g_data_dir := a.parameter_value;
          ELSIF a.parameter_name = 'ARCH_DIR_NAME' THEN
             g_arch_dir := a.parameter_value;
          ELSIF a.parameter_name = 'SET_OF_BOOKS' THEN
             g_set_of_books := a.parameter_value;
          ELSIF a.parameter_name = 'CURRENCY_CONVERSION_TYPE' THEN
             g_currency_conversion_type := a.parameter_value;
          ELSIF a.parameter_name = 'JOURNAL_NAME' THEN
             g_journal_name := a.parameter_value;
          ELSIF a.parameter_name = 'JE_SOURCE_NAME' THEN
             g_je_source_name := a.parameter_value;
          ELSIF a.parameter_name = 'JE_CATEGORY_NAME' THEN
             g_je_category_name := a.parameter_value;
          ELSIF a.parameter_name = 'DATA_FILE_NAME' THEN
             g_data_file_name := a.parameter_value;
          ELSIF a.parameter_name = 'FTP_DATA_DIR_NAME' THEN
             g_ftp_data_dir_name := a.parameter_value;
          ELSIF a.parameter_name = 'FTP_DATA_DIR_ARCH' THEN
             g_ftp_data_dir_arch := a.parameter_value;
          ELSIF a.parameter_name = 'JE_CUR_CODE' THEN
             g_je_cur_code := a.parameter_value;
          END IF;
      END LOOP;

      BEGIN
        SELECT  set_of_books_id
          INTO  g_set_of_books_id
          FROM  gl_sets_of_books
         WHERE  name = g_set_of_books;
      EXCEPTION WHEN OTHERS THEN
        g_set_of_books_id := NULL;
        x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
        RETURN x_error_code;
      END;

      /*SELECT  gl_interface_control_s.nextval
        INTO  g_group_id
        FROM  DUAL;
       */ -- Commented by Yogesh,In case of multiple data files, records from each file has different group_id

      RETURN x_error_code;
    EXCEPTION
        WHEN OTHERS THEN
           x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
           RETURN x_error_code;
    END;

    ----------------------------------------------------------------------

    PROCEDURE utl_read_insert_stg( x_error_code    OUT   NUMBER
                                  ,x_error_msg     OUT   VARCHAR2)
    IS
       CURSOR  c_data_dir(p_dir VARCHAR2)
       IS
       SELECT  directory_path
         FROM  all_directories
        WHERE  directory_name= p_dir;

       CURSOR  c_arch_dir(p_dir VARCHAR2)
       IS
       SELECT  directory_path
         FROM  all_directories
        WHERE  directory_name= p_dir;

       CURSOR  c_file_list
       IS
       SELECT  name
         FROM  xxdirlist;


       x_file_type                 UTL_FILE.FILE_TYPE;
       x_line                      VARCHAR2(3000);

       x_pos                       NUMBER := 1;
       x_record_number             NUMBER := 0;
       x_insert_count              NUMBER := 0;
       x_rec_cntr                  NUMBER := 0;
       x_cntr                      NUMBER := 0;
       x_file_line                 VARCHAR2(30000);
       x_filename                  VARCHAR2(100);
       x_delimeter                 VARCHAR2(10) := ',';

       x_data_path                 VARCHAR2(300);
       x_arch_path                 VARCHAR2(300);

       x_data_rec                  G_XX_GL_ADP_PAYROLL_TAB_TYPE;
       x_file_list                 c_file_list%ROWTYPE;

       x_file                      VARCHAR2(50);
       x_file_yn_flag              VARCHAR2(1) := 'N';
       x_exists                    BOOLEAN;
       x_file_length               NUMBER;
       x_size                      NUMBER;
       x_gl_amt                    NUMBER:=0;
       x_group_id                  NUMBER; -- Added for multiple group_id, Incase if there are multiple files.
       x_skip_First_line           VARCHAR2(3):='Y';

       --- 09-Feb
       l_weeknum                   VARCHAR2(50);
       l_max_flex_value            VARCHAR2(50);
       l_max_description           VARCHAR2(50);
       l_min_flex_value            VARCHAR2(50);
       l_min_description           VARCHAR2(50);
       l_acc_per_err_msg           VARCHAR2(30000);
       l_accounting_period         VARCHAR2(50);
       l_start_date                DATE;
       l_end_date                  DATE;
       l_accounting_date           DATE;
       l_period_num                NUMBER;
       l_period_num_sysdate        NUMBER;
       l_year                      VARCHAR2(50);
       l_lookup_rec_count          NUMBER;
       l_is_num                    VARCHAR2(50);

       accounting_date_error                EXCEPTION;
       ----

    BEGIN
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside utl_read_insert_stg');
       OPEN  c_data_dir(G_DATA_DIR);
       FETCH c_data_dir INTO x_data_path;
       IF c_data_dir%NOTFOUND THEN
         x_data_path := NULL;
       END IF;
       CLOSE c_data_dir;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'utl_read_insert_stg Data Dir->'||x_data_path);

       OPEN  c_arch_dir(G_ARCH_DIR);
       FETCH c_arch_dir INTO x_arch_path;
       IF c_arch_dir%NOTFOUND THEN
         x_arch_path := NULL;
       END IF;
       CLOSE c_arch_dir;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'utl_read_insert_stg Arch Dir->'||x_arch_path);

       xxlist_directory (x_data_path);

       OPEN  c_file_list;
       FETCH c_file_list INTO x_file_list;
       IF c_file_list%NOTFOUND THEN
         null;
       END IF;
       CLOSE c_file_list;


       IF g_data_dir IS NOT NULL THEN
          dbms_output.put_line('Data Dir ->'||G_DATA_DIR);
          FOR r_file_list IN c_file_list LOOP
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'File ->'||r_file_list.name);
              x_file_yn_flag := 'N';
              BEGIN
                x_file_type := UTL_FILE.FOPEN(G_DATA_DIR, r_file_list.name, 'R');
          l_weeknum            := Null;
          l_max_flex_value     := Null;
          l_max_description    := Null;
          l_min_flex_value     := Null;
          l_min_description    := Null;
          l_acc_per_err_msg    := Null;
          l_accounting_period  := Null;
          l_accounting_date    := Null;
          l_period_num         := Null;
          l_period_num_sysdate := Null;
          l_year               := Null;
          l_lookup_rec_count   := 0;
          l_is_num             := Null;
          BEGIN
            select SUBSTR(r_file_list.name,
                          INSTR(r_file_list.name, '_', 1, 3) + 5,
                          8)
              into l_year
              from dual;
          EXCEPTION
            WHEN OTHERS THEN
              l_year := Null;
          END;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Year ->' || l_year);
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Check For Year IS NUM ->' || l_year);

          BEGIN
            SELECT xx_gl_is_num (l_year)
              INTO l_is_num
              FROM DUAL;
          END;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Check For Year IS NUM ->' || l_is_num);

          IF l_is_num = 'F'
          THEN
            l_year := Null;
            l_is_num := Null;
            BEGIN
              select SUBSTR(r_file_list.name,
                          INSTR(r_file_list.name, '_', 1, 3) + 5,
                          4)
              into l_year
              from dual;
            EXCEPTION
            WHEN OTHERS THEN
              l_year := Null;
            END;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Year ->' || l_year);
          END IF;
          BEGIN
            SELECT xx_gl_is_num (l_year)
              INTO l_is_num
              FROM DUAL;
          END;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Check For Year IS NUM ->' || l_is_num);

          IF l_year IS NOT NULL
          THEN
            BEGIN
              SELECT SUBSTR(l_year,-4)
                INTO l_year
                FROM DUAL;
            EXCEPTION
            WHEN OTHERS THEN
              l_year := Null;
            END;
          END IF;

          --- Now Check the Entry For the Above Year in the Lookup INTG_ADP_PAYWEEK_MAPPING
          l_lookup_rec_count := 0;
          BEGIN
                           select count(*)
                            into l_lookup_rec_count
	                    from fnd_flex_values_vl a, fnd_flex_value_sets b
	                   where a.flex_value_set_id = b.flex_value_set_id
	                     and b.flex_value_set_name = 'INTG_ADP_PAYWEEK_MAPPING'
	                     and a.enabled_flag = 'Y'
	                     and a.description like '%'||SUBSTR(l_year,-2)||'%'
                              OR a.description like '%'||l_year||'%';

          EXCEPTION
          WHEN OTHERS THEN
             l_lookup_rec_count := 0;
          END;

          IF l_lookup_rec_count >0
          THEN
          l_is_num := Null;
          l_weeknum := Null;
          BEGIN
            select SUBSTR(r_file_list.name,
                          INSTR(r_file_list.name, '_', 1, 2) + 1,
                          2)
              into l_weeknum
              from dual;
          EXCEPTION
            WHEN OTHERS THEN
              l_weeknum := Null;
          END;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Week Number ->' || l_weeknum);
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Check For Week IS NUM ->' || l_weeknum);

          BEGIN
            SELECT xx_gl_is_num (l_weeknum)
              INTO l_is_num
              FROM DUAL;
          END;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Check For Week IS NUM ->' || l_is_num);

          IF l_is_num = 'F'
          THEN
            l_weeknum := Null;
            l_is_num := Null;
            BEGIN
            select SUBSTR(r_file_list.name,
                          INSTR(r_file_list.name, '_', 1, 3) + 1,
                          2)
              into l_weeknum
              from dual;
            EXCEPTION
            WHEN OTHERS THEN
              l_weeknum := Null;
            END;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Week Number ->' || l_weeknum);
          END IF;

          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Check For Week IS NUM ->' || l_weeknum);

          BEGIN
            SELECT xx_gl_is_num (l_weeknum)
              INTO l_is_num
              FROM DUAL;
          END;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Check For Week IS NUM ->' || l_is_num);


          IF l_weeknum IS NOT NULL THEN
            -- Extract the Accounting Period And Accounting Date For The Week Number ----
            BEGIN
              select a.flex_value, a.description
                into l_max_flex_value, l_max_description
                from fnd_flex_values_vl a, fnd_flex_value_sets b
               where a.flex_value_set_id = b.flex_value_set_id
                 and b.flex_value_set_name = 'INTG_ADP_PAYWEEK_MAPPING'
                 and a.enabled_flag = 'Y'
                 and a.flex_value =
                     (select max(a.flex_value)
                        from fnd_flex_values_vl a, fnd_flex_value_sets b
                       where a.flex_value_set_id = b.flex_value_set_id
                         and b.flex_value_set_name =
                             'INTG_ADP_PAYWEEK_MAPPING'
                         and a.enabled_flag = 'Y'
                         and to_number(a.flex_value) <= to_number(l_weeknum));
            EXCEPTION
              WHEN OTHERS THEN
                l_max_flex_value  := Null;
                l_max_description := Null;
                --l_acc_per_err_msg := 'Payroll Period and GL_PERIOD mapping does not exist for this year. Please complete the mapping in the value set, INTG_ADP_PAYWEEK_MAPPING';
            END;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Down Period ->' || l_max_description);

            BEGIN
              select a.flex_value, a.description
                into l_min_flex_value, l_min_description
                from fnd_flex_values_vl a, fnd_flex_value_sets b
               where a.flex_value_set_id = b.flex_value_set_id
                 and b.flex_value_set_name = 'INTG_ADP_PAYWEEK_MAPPING'
                 and a.enabled_flag = 'Y'
                 and a.flex_value =
                     (select min(a.flex_value)
                        from fnd_flex_values_vl a, fnd_flex_value_sets b
                       where a.flex_value_set_id = b.flex_value_set_id
                         and b.flex_value_set_name =
                             'INTG_ADP_PAYWEEK_MAPPING'
                         and a.enabled_flag = 'Y'
                         and to_number(a.flex_value) >= to_number(l_weeknum));
            EXCEPTION
              WHEN OTHERS THEN
                l_min_flex_value  := Null;
                l_min_description := Null;
                --l_acc_per_err_msg := 'Payroll Period and GL_PERIOD mapping does not exist for this year. Please complete the mapping in the value set, INTG_ADP_PAYWEEK_MAPPING';
            END;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Up Period ->' || l_min_description);
            --- Getting the Actualy Accounting Period ---

            IF l_max_description IS NOT NULL AND
               to_number(l_max_flex_value) = to_number(l_weeknum) THEN
              l_accounting_period := l_max_description;
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                   'Accounting Period 1->' ||
                                   l_accounting_period);
            ELSIF l_min_description IS NOT NULL AND
                  to_number(l_min_flex_value) = to_number(l_weeknum) THEN
              l_accounting_period := l_min_description;
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                   'Accounting Period 2->' ||
                                   l_accounting_period);
            ELSIF to_number(l_weeknum) > NVL(l_max_flex_value, 0) AND
                  to_number(l_weeknum) < to_number(l_min_flex_value) THEN
              l_accounting_period := l_min_description;
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                   'Accounting Period 3->' ||
                                   l_accounting_period);
            END IF;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Accounting Period ->' ||
                                 l_accounting_period);
            --- Fetching the Period Start Date and End date ---
            BEGIN
              select start_date, end_date, period_num
                into l_start_date, l_end_date, l_period_num
                from gl_periods
               where period_name = l_accounting_period;
            EXCEPTION
              WHEN OTHERS THEN
                l_start_date := Null;
                l_end_date   := Null;
                l_period_num := Null;
            END;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Period Start Date ->' || l_start_date);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Period End Date ->' || l_end_date);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Period Number ->' || l_period_num);

            --- Fetching the Period Start Date and End date ---
            BEGIN
              select period_num
                into l_period_num_sysdate
                from gl_periods
               where TRUNC(SYSDATE) BETWEEN start_date AND end_date;
            EXCEPTION
              WHEN OTHERS THEN
                l_period_num_sysdate := Null;
            END;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Accounting Period on SYSDATE ->' ||
                                 l_period_num_sysdate);

            IF TRUNC(SYSDATE) BETWEEN l_start_date AND l_end_date AND
               l_period_num = l_period_num_sysdate THEN
              l_accounting_date := TRUNC(SYSDATE);
            END IF;

            IF l_period_num_sysdate < l_period_num THEN
              l_accounting_date := l_start_date;
            END IF;

            IF l_period_num < l_period_num_sysdate THEN
              l_accounting_date := l_end_date;
            END IF;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Accounting Date ->' || l_accounting_date);
          END IF;

          ELSE
            l_accounting_date := Null;

          END IF;
          -- Added by Dhiren End --

              EXCEPTION
                  WHEN UTL_FILE.invalid_path THEN
                     x_error_code := xx_emf_cn_pkg.cn_prc_err;
                     x_error_msg  := 'Invalid Path for File :' || r_file_list.name;
                  WHEN UTL_FILE.invalid_filehandle THEN
                     x_error_code := xx_emf_cn_pkg.cn_prc_err;
                     x_error_msg  :=  'File handle is invalid for File :' || r_file_list.name;
                  WHEN UTL_FILE.read_error THEN
                     x_error_code := xx_emf_cn_pkg.cn_prc_err;
                     x_error_msg  := 'Unable to read the File :' || r_file_list.name;
                  WHEN UTL_FILE.invalid_operation THEN
                     x_error_code := xx_emf_cn_pkg.cn_prc_err;
                     x_error_msg  := 'File could not be opened :' || r_file_list.name;
                     UTL_FILE.fgetattr ( G_DATA_DIR
                                        ,r_file_list.name
                                        ,x_exists
                                        ,x_file_length
                                        ,x_size);

                     IF x_exists THEN
                        x_error_msg := 'File '||r_file_list.name || 'exists ';
                     ELSE
                        x_error_code := xx_emf_cn_pkg.cn_prc_err;
                        x_error_msg  := 'File '||r_file_list.name || ' File Does not exits ';
                        x_file_yn_flag := 'Y';
                     END IF;
                  WHEN UTL_FILE.file_open THEN
                        x_error_code := xx_emf_cn_pkg.cn_prc_err;
                        x_error_msg  := 'Unable to Open File :' || r_file_list.name;
                  WHEN UTL_FILE.invalid_maxlinesize THEN
                        x_error_code := xx_emf_cn_pkg.cn_prc_err;
                        x_error_msg  := 'File ' || r_file_list.name;
                  WHEN UTL_FILE.access_denied THEN
                        x_error_code := xx_emf_cn_pkg.cn_prc_err;
                        x_error_msg  := 'Access denied for File :' || r_file_list.name;
                  WHEN OTHERS THEN
                        x_error_code := xx_emf_cn_pkg.cn_prc_err;
                        x_error_msg  := r_file_list.name || SQLERRM;
              END; -- End of File open exception
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Code->'||x_error_code||'Exits Flag-> '||x_file_yn_flag);
              IF NVL(x_error_code,0) = 0 AND NVL(x_file_yn_flag,'N') <> 'Y' THEN
                 SELECT  gl_interface_control_s.nextval
           INTO  x_group_id
                   FROM  DUAL;
                 x_skip_first_line:='Y';
                 LOOP
                    BEGIN
                       BEGIN
                         UTL_FILE.GET_LINE(x_file_type, x_line);
                       EXCEPTION WHEN NO_DATA_FOUND THEN
                         EXIT;
                       END;
                       IF x_skip_first_line = 'Y' THEN -- Added IF condition to skip reading the first line, as it contains column header.
                          x_skip_first_line:= 'N';
                       ELSE
                          x_gl_amt := 0;
                          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Line->'||x_line);
                          x_rec_cntr := x_rec_cntr + 1;
                          x_pos := 1;
                          x_cntr := x_cntr + 1;

                          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'x_cntr->'||x_cntr);
                          x_data_rec (x_cntr).record_id             := xx_gl_adppay_int_s.nextval;
                          x_data_rec (x_cntr).batch_id              := x_group_id;
                          --x_data_rec (x_cntr).user_je_category_name := next_field (x_line, x_delimeter, x_pos);
                          --x_data_rec (x_cntr).user_je_source_name   := next_field (x_line, x_delimeter, x_pos);
                          --x_data_rec (x_cntr).currency_code         := next_field (x_line, x_delimeter, x_pos);
                          --x_data_rec (x_cntr).accounting_date       := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).accounting_date       :=l_accounting_date; --- 09-Feb
                          x_data_rec (x_cntr).segment1              := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).segment2              := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).segment3              := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).segment4              := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).segment5              := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).segment6              := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).segment7              := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).segment8              := next_field (x_line, x_delimeter, x_pos);
                          --x_data_rec (x_cntr).segment9            := next_field (x_line, x_delimeter, x_pos);
                          --x_gl_amt                                := next_field (x_line, x_delimeter, x_pos);
                          x_data_rec (x_cntr).entered_dr            := NVL(next_field (x_line, x_delimeter, x_pos),0);
                          x_data_rec (x_cntr).entered_cr            := NVL(next_field (x_line, x_delimeter, x_pos),0);
                          x_data_rec (x_cntr).line_description      := next_field (x_line, x_delimeter, x_pos);

                          /*IF NVL(x_gl_amt,0) >= 0 THEN
                             x_data_rec (x_cntr).entered_dr         := NVL(x_gl_amt,0);
                          ELSE
                             x_data_rec (x_cntr).entered_cr         := ABS(NVL(x_gl_amt,0));
                          END IF;*/
                          x_data_rec (x_cntr).file_name             := r_file_list.name;
                       END IF;
                    EXCEPTION
                        WHEN UTL_FILE.invalid_filehandle THEN
                             x_error_code := xx_emf_cn_pkg.cn_prc_err;
                             x_error_msg  :=  'File handle is invalid for File :' || r_file_list.name;
                        WHEN OTHERS THEN
                             x_error_msg := x_error_msg || SQLERRM;
                             x_error_code := xx_emf_cn_pkg.cn_rec_err;
                             xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_HIGH,'Error While Reading Line ' || x_rec_cntr||SQLERRM);
                             EXIT;
                    END;
                 END LOOP;
              END IF; -- flag and error code
              UTL_FILE.fclose (x_file_type);
          END LOOP; -- file loop
       END IF; -- dir check

       FOR i IN 1 .. x_data_rec.COUNT
       LOOP
       dbms_output.put_line('Inside Insert ->'||x_data_rec (i).file_name );
         INSERT INTO XX_GL_ADP_PAYROLL_STG
          ( record_id
           ,batch_id
           ,file_name
           ,user_je_category_name
           ,user_je_source_name
           ,currency_code
           ,accounting_date
           ,segment1
           ,segment2
           ,segment3
           ,segment4
           ,segment5
           ,segment6
           ,segment7
           ,segment8
           --,segment9
           ,date_created
           ,actual_flag
           ,entered_dr
           ,entered_cr
           ,line_description
           ,journal_name
           ,status
           ,request_id
           ,process_code
           ,error_code
           ,error_message
           ,created_by
           ,creation_date
           ,last_update_date
           ,last_updated_by
           ,last_update_login)
         VALUES
          ( x_data_rec (i).record_id                   -- record_id
           ,x_data_rec (i).batch_id                    -- batch_id
           ,x_data_rec (i).file_name                   -- file_name
           ,g_je_category_name                         -- x_data_rec (i).user_je_category_name -- user_je_category_name
           ,g_je_source_name                           -- x_data_rec (i).user_je_source_name   -- user_je_source_name
           ,g_je_cur_code                              -- currency_code
           ---,sysdate                                    -- accounting_date
           ,x_data_rec (i).accounting_date             -- accounting_date   --- 09-Feb
           ,x_data_rec (i).segment1                    -- segment1
           ,x_data_rec (i).segment2                    -- segment2
           ,x_data_rec (i).segment3                    -- segment3
           ,x_data_rec (i).segment4                    -- segment4
           ,x_data_rec (i).segment5                    -- segment5
           ,x_data_rec (i).segment6                    -- segment6
           ,x_data_rec (i).segment7                    -- segment7
           ,x_data_rec (i).segment8                    -- segment8
           --,x_data_rec (i).segment9                    -- segment9
           ,SYSDATE                                    -- date_created
           ,NULL                                       -- actual_flag
           ,x_data_rec (i).entered_dr                  -- entered_dr
           ,x_data_rec (i).entered_cr                  -- entered_cr
           ,x_data_rec (i).line_description            -- line_description
           ,g_journal_name                             -- x_data_rec (i).journal_name -- journal_name
           ,NULL                                       -- status
           ,NULL                                       -- request_id
           ,NULL                                       -- process_code
           ,NULL                                       -- error_code
           ,NULL                                       -- error_message
           ,FND_GLOBAL.USER_ID                         -- created_by
           ,SYSDATE                                    -- creation_date
           ,SYSDATE                                    -- last_update_date
           ,FND_GLOBAL.USER_ID                         -- last_updated_by
           ,FND_PROFILE.VALUE (xx_emf_cn_pkg.CN_LOGIN_ID) -- last_update_login
          );
       END LOOP;
       COMMIT;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while reading File: ' ||SQLERRM);
          xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
          x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
          x_error_msg := 'Error while reading File: ' ||SQLERRM;
    END utl_read_insert_stg;

    -- --------------------------------------------------------------------- --
    -- This procedure will update the new records for processing
    PROCEDURE mark_records_for_processing( p_reprocess     IN  VARCHAR2
                                          ,p_requestid     IN  NUMBER
                                          ,p_file_name     IN  VARCHAR2
                                          ,p_restart_flag  IN  VARCHAR2)
    IS
       PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'In Calling mark_records_for_processing..');
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'mark_records_for_processing :'||xx_emf_pkg.G_REQUEST_ID||' - '||xx_emf_cn_pkg.CN_NULL||' - '||xx_emf_cn_pkg.CN_NEW);
         IF NVL(p_reprocess,'N') = 'Y' THEN
            IF p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling mark_records_for_processing..All Rec');
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'mark_records_for_processing..All Rec 1 ->'||xx_emf_pkg.G_REQUEST_ID||' - '||xx_emf_cn_pkg.CN_NULL||' - '||xx_emf_cn_pkg.CN_NEW);
               UPDATE xx_gl_adp_payroll_stg
                  SET error_code   = xx_emf_cn_pkg.CN_NULL,
                      process_code = xx_emf_cn_pkg.CN_NEW,
                      request_id   = xx_emf_pkg.G_REQUEST_ID
                WHERE request_id = p_requestid
                  AND file_name  = NVL(p_file_name,file_name);
                  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'mark_records_for_processing..All Rec 2');
            ELSIF p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling mark_records_for_processing..Error Rec');
               UPDATE xx_gl_adp_payroll_stg
                  SET error_code = xx_emf_cn_pkg.CN_NULL,
                      process_code = xx_emf_cn_pkg.CN_NEW,
                      request_id   = xx_emf_pkg.G_REQUEST_ID
                WHERE error_code IN ( xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                  AND request_id = NVL(p_requestid,request_id)
                  AND file_name  = NVL(p_file_name,file_name);
            END IF;
         ELSIF NVL(p_reprocess,'N') = 'N' THEN
             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling mark_records_for_processing with out re process');
             UPDATE xx_gl_adp_payroll_stg
               SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                   process_code = xx_emf_cn_pkg.CN_NEW
             WHERE error_code IS NULL;
         END IF;
         COMMIT;

    END mark_records_for_processing;
   -- --------------------------------------------------------------------- --
    -- Setting stage
    PROCEDURE set_stage ( p_stage VARCHAR2)
    IS
    BEGIN
       G_STAGE := p_stage;
    END set_stage;

   -- --------------------------------------------------------------------- --

   -- Cross Updating the stagin table
   PROCEDURE update_staging_records(p_error_code VARCHAR2) IS

           x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

           PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
           UPDATE  xx_gl_adp_payroll_stg
              SET  process_code = G_STAGE
                  ,error_code = p_error_code --DECODE ( error_code, NULL, p_error_code, error_code)
                  ,creation_date         = SYSDATE
                  ,created_by            = fnd_global.user_id
                  ,last_update_date      = SYSDATE
                  ,last_updated_by       = fnd_global.user_id
                  ,last_update_login     = x_last_update_login
            WHERE request_id    = xx_emf_pkg.G_REQUEST_ID
              AND process_code    = xx_emf_cn_pkg.CN_NEW;
         COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Updating STAGE status : ' ||SQLERRM);
   END update_staging_records;

   -- --------------------------------------------------------------------- --
  -- Postvalidation process if any
  FUNCTION post_validations RETURN NUMBER
  IS
     x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
     x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
  BEGIN
     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations');
     RETURN x_error_code;
  EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR THEN
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
          x_error_code := xx_emf_cn_pkg.cn_rec_err;
          RETURN x_error_code;
      WHEN OTHERS THEN
          x_error_code := xx_emf_cn_pkg.cn_rec_err;
          RETURN x_error_code;
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Completed Post-Validations');
  END post_validations;

  -- --------------------------------------------------------------------- --

   -- update_record_count
   PROCEDURE update_record_count
   IS
      CURSOR c_get_total_cnt IS
      SELECT COUNT (1) total_count
        FROM xx_gl_adp_payroll_stg
       WHERE request_id = xx_emf_pkg.G_REQUEST_ID;

      x_total_cnt NUMBER;

      CURSOR c_get_error_cnt IS
      SELECT SUM(error_count)
        FROM (
      SELECT COUNT (1) error_count
        FROM xx_gl_adp_payroll_stg
       WHERE request_id = xx_emf_pkg.G_REQUEST_ID
         AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

       x_error_cnt NUMBER;

      CURSOR c_get_warning_cnt IS
      SELECT COUNT (1) warn_count
        FROM xx_gl_adp_payroll_stg
       WHERE request_id = xx_emf_pkg.G_REQUEST_ID
         AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

       x_warn_cnt NUMBER;

      CURSOR c_get_success_cnt IS
      SELECT COUNT (1) success_count
        FROM xx_gl_adp_payroll_stg
       WHERE request_id = xx_emf_pkg.G_REQUEST_ID
         AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
         AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

      x_success_cnt NUMBER;

   BEGIN
      OPEN c_get_total_cnt;
      FETCH c_get_total_cnt INTO x_total_cnt;
      CLOSE c_get_total_cnt;

      OPEN c_get_error_cnt;
      FETCH c_get_error_cnt INTO x_error_cnt;
      CLOSE c_get_error_cnt;

      OPEN c_get_warning_cnt;
      FETCH c_get_warning_cnt INTO x_warn_cnt;
      CLOSE c_get_warning_cnt;

      OPEN c_get_success_cnt;
      FETCH c_get_success_cnt INTO x_success_cnt;
      CLOSE c_get_success_cnt;

      xx_emf_pkg.update_recs_cnt
        ( p_total_recs_cnt   => x_total_cnt,
          p_success_recs_cnt => x_success_cnt,
          p_warning_recs_cnt => x_warn_cnt,
          p_error_recs_cnt   => x_error_cnt
        );

   END update_record_count;

 -- --------------------------------------------------------------------- --

 FUNCTION pre_validations RETURN NUMBER
 IS
   x_error_code       NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   x_error_code_temp  NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
 BEGIN
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Pre-Validations');
    RETURN x_error_code;
 EXCEPTION
   WHEN xx_emf_pkg.G_E_REC_ERROR THEN
     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
     RETURN x_error_code;
   WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
     x_error_code := xx_emf_cn_pkg.cn_prc_err;
     RETURN x_error_code;
   WHEN OTHERS THEN
     x_error_code := xx_emf_cn_pkg.cn_prc_err;
     RETURN x_error_code;
     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Completed Pre-Validations');
 END pre_validations;

-- --------------------------------------------------------------------- --

 FUNCTION data_validations(p_gl_rec IN OUT g_xx_gl_adp_payroll_rec_type )
      RETURN NUMBER
 IS
     x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
     x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
     x_error_message     VARCHAR2(3000);
     x_err_mesg          VARCHAR2(3000);
     x_segments          VARCHAR(1000);
     -- --------------------------------------------------------------------- --
     -- Journal Source Validation
     FUNCTION is_source_valid ( p_je_source         IN  VARCHAR2
                               ,p_err_mesg          OUT VARCHAR2)
     RETURN NUMBER
     IS
         x_error_code          NUMBER        := xx_emf_cn_pkg.cn_success;
         x_source_name         VARCHAR2(25);
     BEGIN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Journal  Source  => '|| p_je_source);

           IF p_je_source IS NOT NULL THEN
                SELECT  je_source_name
                  INTO  x_source_name
                  FROM  gl_je_sources
                 WHERE  user_je_source_name = p_je_source;
                 --WHERE  je_source_name = p_je_source;
           ELSE
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                                ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                ,p_error_text  => 'Journal Source can not be null'
                                ,p_record_identifier_1 => p_gl_rec.user_je_category_name
                                ,p_record_identifier_2 => p_gl_rec.user_je_source_name
                                ,p_record_identifier_3 => p_gl_rec.journal_name);
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               p_err_mesg := 'Journal Source can not be null' || p_je_source;
           END IF;

           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_source_valid: Success =>'||p_je_source);
           RETURN x_error_code;

     EXCEPTION
         WHEN OTHERS THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Invalid Journal Source ' || SQLCODE);
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                               ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                               ,p_error_text  => 'Invalid Journal Source=>'|| p_je_source ||'-'||SQLERRM
                               ,p_record_identifier_1 => p_gl_rec.user_je_category_name
                               ,p_record_identifier_2 => p_gl_rec.user_je_source_name
                               ,p_record_identifier_3 => p_gl_rec.journal_name);

              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Journal Source ' || x_error_code);
              p_err_mesg := 'Invalid Journal Source';
              RETURN x_error_code;
     END is_source_valid;

    -- --------------------------------------------------------------------- --
    -- Period Validation -- 09 Feb

     FUNCTION is_period_valid ( p_file_name         IN  VARCHAR2
                               ,p_rec_id            IN  NUMBER
                               ,p_acct_date         IN  DATE
                               ,p_err_mesg          OUT VARCHAR2)
     RETURN NUMBER
     IS
         x_error_code          NUMBER        := xx_emf_cn_pkg.cn_success;
         x_period_name         VARCHAR2(15);

    l_weeknum            VARCHAR2(50);
    l_max_flex_value     VARCHAR2(50);
    l_max_description    VARCHAR2(50);
    l_min_flex_value     VARCHAR2(50);
    l_min_description    VARCHAR2(50);
    l_acc_per_err_msg    VARCHAR2(30000);
    l_accounting_period  VARCHAR2(50);
    l_start_date         DATE;
    l_end_date           DATE;
    l_accounting_date    DATE;
    l_period_num         NUMBER;
    l_period_num_sysdate NUMBER;
    l_year                      VARCHAR2(50);
    l_lookup_rec_count          NUMBER;
    l_is_num                    VARCHAR2(50);


     BEGIN

          l_weeknum            := Null;
          l_max_flex_value     := Null;
          l_max_description    := Null;
          l_min_flex_value     := Null;
          l_min_description    := Null;
          l_acc_per_err_msg    := Null;
          l_accounting_period  := Null;
          l_accounting_date    := Null;
          l_period_num         := Null;
          l_period_num_sysdate := Null;
          l_year               := Null;
          l_lookup_rec_count   := 0;
          l_is_num             := Null;

          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Reprocess Flag --> '||g_p_reprocess);

          IF p_acct_date IS NULL AND g_p_reprocess = 'Y'
          THEN

           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'InSide Accounting date Derivation And Validation ');

          /*
          BEGIN
            select SUBSTR(p_file_name,
                          INSTR(p_file_name, '_', 1, 3) + 5,
                          4)
              into l_year
              from dual;
          EXCEPTION
            WHEN OTHERS THEN
              l_year := Null;
          END;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Year ->' || l_year);
          */


          BEGIN
            select SUBSTR(p_file_name,
                          INSTR(p_file_name, '_', 1, 3) + 5,
                          8)
              into l_year
              from dual;
          EXCEPTION
            WHEN OTHERS THEN
              l_year := Null;
          END;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Year ->' || l_year);
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Check For Year IS NUM ->' || l_year);

          BEGIN
            SELECT xx_gl_is_num (l_year)
              INTO l_is_num
              FROM DUAL;
          END;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Check For Year IS NUM ->' || l_is_num);

          IF l_is_num = 'F'
          THEN
            l_year := Null;
            l_is_num := Null;
            BEGIN
              select SUBSTR(p_file_name,
                          INSTR(p_file_name, '_', 1, 3) + 5,
                          4)
              into l_year
              from dual;
            EXCEPTION
            WHEN OTHERS THEN
              l_year := Null;
            END;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Year ->' || l_year);
          END IF;
          BEGIN
            SELECT xx_gl_is_num (l_year)
              INTO l_is_num
              FROM DUAL;
          END;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Check For Year IS NUM ->' || l_is_num);

          IF l_year IS NOT NULL
          THEN
            BEGIN
              SELECT SUBSTR(l_year,-4)
                INTO l_year
                FROM DUAL;
            EXCEPTION
            WHEN OTHERS THEN
              l_year := Null;
            END;
          END IF;


          --- Now Check the Entry For the Above Year in the Lookup INTG_ADP_PAYWEEK_MAPPING
          l_lookup_rec_count := 0;
          BEGIN
                           select count(*)
                            into l_lookup_rec_count
	                    from fnd_flex_values_vl a, fnd_flex_value_sets b
	                   where a.flex_value_set_id = b.flex_value_set_id
	                     and b.flex_value_set_name = 'INTG_ADP_PAYWEEK_MAPPING'
	                     and a.enabled_flag = 'Y'
	                     and a.description like '%'||SUBSTR(l_year,-2)||'%'
                              OR a.description like '%'||l_year||'%';

          EXCEPTION
          WHEN OTHERS THEN
             l_lookup_rec_count := 0;
          END;
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'INTG_ADP_PAYWEEK_MAPPING having Record For The Above Year ->' || l_lookup_rec_count);
          IF l_lookup_rec_count >0
          THEN
          l_weeknum := Null;
          l_is_num := Null;
          /*
          BEGIN
            select SUBSTR(p_file_name,
                          INSTR(p_file_name, '_', 1, 2) + 1,
                          2)
              into l_weeknum
              from dual;
          EXCEPTION
            WHEN OTHERS THEN
              l_weeknum := Null;
          END;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Week Number ->' || l_weeknum);
          */

          BEGIN
            select SUBSTR(p_file_name,
                          INSTR(p_file_name, '_', 1, 2) + 1,
                          2)
              into l_weeknum
              from dual;
          EXCEPTION
            WHEN OTHERS THEN
              l_weeknum := Null;
          END;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Week Number ->' || l_weeknum);
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Check For Week IS NUM ->' || l_weeknum);

          BEGIN
            SELECT xx_gl_is_num (l_weeknum)
              INTO l_is_num
              FROM DUAL;
          END;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Check For Week IS NUM ->' || l_is_num);

          IF l_is_num = 'F'
          THEN
            l_weeknum := Null;
            l_is_num := Null;
            BEGIN
            select SUBSTR(p_file_name,
                          INSTR(p_file_name, '_', 1, 3) + 1,
                          2)
              into l_weeknum
              from dual;
            EXCEPTION
            WHEN OTHERS THEN
              l_weeknum := Null;
            END;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Week Number ->' || l_weeknum);
          END IF;

          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Check For Week IS NUM ->' || l_weeknum);

          BEGIN
            SELECT xx_gl_is_num (l_weeknum)
              INTO l_is_num
              FROM DUAL;
          END;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                               'Check For Week IS NUM ->' || l_is_num);


          IF l_weeknum IS NOT NULL THEN
            -- Extract the Accounting Period And Accounting Date For The Week Number ----
            BEGIN
              select a.flex_value, a.description
                into l_max_flex_value, l_max_description
                from fnd_flex_values_vl a, fnd_flex_value_sets b
               where a.flex_value_set_id = b.flex_value_set_id
                 and b.flex_value_set_name = 'INTG_ADP_PAYWEEK_MAPPING'
                 and a.enabled_flag = 'Y'
                 and a.flex_value =
                     (select max(a.flex_value)
                        from fnd_flex_values_vl a, fnd_flex_value_sets b
                       where a.flex_value_set_id = b.flex_value_set_id
                         and b.flex_value_set_name =
                             'INTG_ADP_PAYWEEK_MAPPING'
                         and a.enabled_flag = 'Y'
                         and to_number(a.flex_value) <= to_number(l_weeknum));
            EXCEPTION
              WHEN OTHERS THEN
                l_max_flex_value  := Null;
                l_max_description := Null;
            END;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Down Period ->' || l_max_description);

            BEGIN
              select a.flex_value, a.description
                into l_min_flex_value, l_min_description
                from fnd_flex_values_vl a, fnd_flex_value_sets b
               where a.flex_value_set_id = b.flex_value_set_id
                 and b.flex_value_set_name = 'INTG_ADP_PAYWEEK_MAPPING'
                 and a.enabled_flag = 'Y'
                 and a.flex_value =
                     (select min(a.flex_value)
                        from fnd_flex_values_vl a, fnd_flex_value_sets b
                       where a.flex_value_set_id = b.flex_value_set_id
                         and b.flex_value_set_name =
                             'INTG_ADP_PAYWEEK_MAPPING'
                         and a.enabled_flag = 'Y'
                         and to_number(a.flex_value) >= to_number(l_weeknum));
            EXCEPTION
              WHEN OTHERS THEN
                l_min_flex_value  := Null;
                l_min_description := Null;
            END;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Up Period ->' || l_min_description);

            --- Getting the Actualy Accounting Period ---

            IF l_max_description IS NOT NULL AND
               to_number(l_max_flex_value) = to_number(l_weeknum) THEN
              l_accounting_period := l_max_description;
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                   'Accounting Period 1->' ||
                                   l_accounting_period);
            ELSIF l_min_description IS NOT NULL AND
                  to_number(l_min_flex_value) = to_number(l_weeknum) THEN
              l_accounting_period := l_min_description;
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                   'Accounting Period 2->' ||
                                   l_accounting_period);
            ELSIF to_number(l_weeknum) > NVL(l_max_flex_value, 0) AND
                  to_number(l_weeknum) < to_number(l_min_flex_value) THEN
              l_accounting_period := l_min_description;
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                   'Accounting Period 3->' ||
                                   l_accounting_period);
            END IF;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Accounting Period ->' ||
                                 l_accounting_period);
            --- Fetching the Period Start Date and End date ---
            BEGIN
              select start_date, end_date, period_num
                into l_start_date, l_end_date, l_period_num
                from gl_periods
               where period_name = l_accounting_period;
            EXCEPTION
              WHEN OTHERS THEN
                l_start_date := Null;
                l_end_date   := Null;
                l_period_num := Null;
            END;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Period Start Date ->' || l_start_date);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Period End Date ->' || l_end_date);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Period Number ->' || l_period_num);

            --- Fetching the Period Start Date and End date ---
            BEGIN
              select period_num
                into l_period_num_sysdate
                from gl_periods
               where TRUNC(SYSDATE) BETWEEN start_date AND end_date;
            EXCEPTION
              WHEN OTHERS THEN
                l_period_num_sysdate := Null;
            END;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Accounting Period on SYSDATE ->' ||
                                 l_period_num_sysdate);

            IF TRUNC(SYSDATE) BETWEEN l_start_date AND l_end_date AND
               l_period_num = l_period_num_sysdate THEN
              l_accounting_date := TRUNC(SYSDATE);
            END IF;
            l_accounting_date := Null;
            IF l_period_num_sysdate < l_period_num THEN
              l_accounting_date := l_start_date;
            END IF;

            IF l_period_num < l_period_num_sysdate THEN
              l_accounting_date := l_end_date;
            END IF;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Accounting Date ->' || l_accounting_date);

            IF l_accounting_date IS NOT NULL
            THEN

              Update xx_gl_adp_payroll_stg
                 set accounting_date = l_accounting_date
               Where record_id = p_rec_id;
               Commit;

            END IF;

          END IF;

          ELSE
              Update xx_gl_adp_payroll_stg
                 set accounting_date = Null
               Where record_id = p_rec_id;
               Commit;
          END IF;

          -- 09-Feb End --

          END IF;

          l_accounting_date := p_acct_date;

           IF l_accounting_date IS NOT NULL THEN
              SELECT  per.period_name
                INTO  x_period_name
                FROM  gl_period_statuses_v per
                     ,fnd_application_tl   apl
               WHERE  l_accounting_date BETWEEN per.start_date AND per.end_date
                 AND  per.closing_status = 'O'
                 AND  per.set_of_books_id = g_set_of_books_id
                 AND  per.application_id  = apl.application_id
                 AND  apl.application_name  = 'General Ledger'
                 AND  apl.language = USERENV('LANG');
           ELSE
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                                ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                ,p_error_text  => 'Accounting date can not be null'
                                ,p_record_identifier_1 => p_gl_rec.user_je_category_name
                                ,p_record_identifier_2 => p_gl_rec.user_je_source_name
                                ,p_record_identifier_3 => p_gl_rec.journal_name);
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               p_err_mesg := 'Accounting date can not be null' || l_accounting_date;
           END IF;

           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_period_valid: Success =>'||l_accounting_date);
           RETURN x_error_code;

     EXCEPTION
         WHEN OTHERS THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Invalid Accounting date ' || SQLCODE);
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                               ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                               ,p_error_text  => 'Invalid Accounting date=>'|| l_accounting_date ||'-'||SQLERRM
                               ,p_record_identifier_1 => p_gl_rec.user_je_category_name
                               ,p_record_identifier_2 => p_gl_rec.user_je_source_name
                               ,p_record_identifier_3 => p_gl_rec.journal_name);

              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Accounting date ' || x_error_code);
              p_err_mesg := 'Invalid Accounting date';
              RETURN x_error_code;
     END is_period_valid;

     -- --------------------------------------------------------------------- --
     -- Journal Category Validation
     FUNCTION is_category_valid ( p_category          IN  VARCHAR2
                                 ,p_err_mesg          OUT VARCHAR2)
     RETURN NUMBER
     IS
         x_error_code          NUMBER        := xx_emf_cn_pkg.cn_success;
         x_category_name         VARCHAR2(25);
     BEGIN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Journal Category  => '|| p_category);

           IF p_category IS NOT NULL THEN
                SELECT  user_je_category_name
                  INTO  x_category_name
                  FROM  gl_je_categories
                 WHERE  user_je_category_name = p_category;
           ELSE
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                                ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                ,p_error_text  => 'Journal Category can not be null'
                                ,p_record_identifier_1 => p_gl_rec.user_je_category_name
                                ,p_record_identifier_2 => p_gl_rec.user_je_source_name
                                ,p_record_identifier_3 => p_gl_rec.journal_name);
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               p_err_mesg := 'Journal Category can not be null' || p_category;
           END IF;

           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_valid: Success =>'||p_category);
           RETURN x_error_code;

     EXCEPTION
         WHEN OTHERS THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Invalid Journal Category ' || SQLCODE);
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                               ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                               ,p_error_text  => 'Invalid Journal Category=>'|| p_category ||'-'||SQLERRM
                               ,p_record_identifier_1 => p_gl_rec.user_je_category_name
                               ,p_record_identifier_2 => p_gl_rec.user_je_source_name
                               ,p_record_identifier_3 => p_gl_rec.journal_name);

              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Journal Category ' || x_error_code);
              p_err_mesg := 'Invalid Journal Category';
              RETURN x_error_code;
     END is_category_valid;

     -- --------------------------------------------------------------------- --
     -- Currency Validation
     FUNCTION is_currency_valid ( p_currency          IN  VARCHAR2
                                 ,p_err_mesg          OUT VARCHAR2)
     RETURN NUMBER
     IS
         x_error_code          NUMBER        := xx_emf_cn_pkg.cn_success;
         x_currency_code       VARCHAR2(25);
     BEGIN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Currency  => '|| p_currency);

           IF p_currency IS NOT NULL THEN
              SELECT  currency_code
                INTO  x_currency_code
                FROM  fnd_currencies fc
               WHERE  currency_code = p_currency
                 AND  fc.enabled_flag = 'Y'
                 AND  TRUNC (SYSDATE) >= TRUNC( NVL (start_date_active, SYSDATE))
                 AND  TRUNC (SYSDATE) <= TRUNC( NVL (end_date_active, SYSDATE + 1));
           ELSE
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                                ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                ,p_error_text  => 'Currency can not be null'
                                ,p_record_identifier_1 => p_gl_rec.user_je_category_name
                                ,p_record_identifier_2 => p_gl_rec.user_je_source_name
                                ,p_record_identifier_3 => p_gl_rec.journal_name);
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               p_err_mesg := 'Currency can not be null' || p_currency;
           END IF;

           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_currency_valid: Success =>'||p_currency);
           RETURN x_error_code;

     EXCEPTION
         WHEN OTHERS THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Invalid Currency ' || SQLCODE);
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                               ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                               ,p_error_text  => 'Invalid Currency=>'|| p_currency ||'-'||SQLERRM
                               ,p_record_identifier_1 => p_gl_rec.user_je_category_name
                               ,p_record_identifier_2 => p_gl_rec.user_je_source_name
                               ,p_record_identifier_3 => p_gl_rec.journal_name);

              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Currency ' || x_error_code);
              p_err_mesg := 'Invalid Currency';
              RETURN x_error_code;
     END is_currency_valid;

     -- --------------------------------------------------------------------- --

     FUNCTION is_year_valid ( p_file_name         IN  VARCHAR2
                             ,p_err_mesg          OUT VARCHAR2)
     RETURN NUMBER
     IS
         x_error_code          NUMBER        := xx_emf_cn_pkg.cn_success;
         x_source_name         VARCHAR2(25);
         l_year                NUMBER;
         l_lookup_rec_count    NUMBER;
     BEGIN
          IF p_file_name IS NOT NULL THEN
            select SUBSTR(p_file_name,
                          INSTR(p_file_name, '_', 1, 3) + 5,
                          4)
              into l_year
              from dual;
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Year   => '|| l_year);
            IF l_year IS NOT NULL THEN
                  l_lookup_rec_count := 0;
		  BEGIN
				   select count(*)
				    into l_lookup_rec_count
				    from fnd_flex_values_vl a, fnd_flex_value_sets b
				   where a.flex_value_set_id = b.flex_value_set_id
				     and b.flex_value_set_name = 'INTG_ADP_PAYWEEK_MAPPING'
				     and a.enabled_flag = 'Y'
				     and a.description like '%'||SUBSTR(l_year,-2)||'%'
				      OR a.description like '%'||l_year||'%';

		  EXCEPTION
		  WHEN OTHERS THEN
		     l_lookup_rec_count := 0;
		  END;
            END IF;
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Record Count In Lookup For The Above Year   => '|| l_lookup_rec_count);
           ELSE
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                                ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                ,p_error_text  => 'File Name can not be null'
                                ,p_record_identifier_1 => p_gl_rec.user_je_category_name
                                ,p_record_identifier_2 => p_gl_rec.user_je_source_name
                                ,p_record_identifier_3 => p_gl_rec.journal_name);
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               p_err_mesg := 'File Name can not be null' || p_file_name;
           END IF;

           IF l_lookup_rec_count > 0 THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_year_valid: Success =>'||l_year);
              RETURN x_error_code;
           ELSE
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Payroll Period Not Defined in INTG_ADP_PAYWEEK_MAPPING For Year =>'|| l_year);
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                               ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                               ,p_error_text  => 'Payroll Period Not Defined in INTG_ADP_PAYWEEK_MAPPING For Year =>'|| l_year
                               ,p_record_identifier_1 => p_gl_rec.user_je_category_name
                               ,p_record_identifier_2 => p_gl_rec.user_je_source_name
                               ,p_record_identifier_3 => p_gl_rec.journal_name);

              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Year In File ' || x_error_code);
              p_err_mesg := 'Payroll Period Not Defined in INTG_ADP_PAYWEEK_MAPPING For Year =>'|| l_year;
              RETURN x_error_code;
           END IF;

     EXCEPTION
         WHEN OTHERS THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Payroll Period Not Defined in INTG_ADP_PAYWEEK_MAPPING For Year =>'|| l_year);
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                               ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                               ,p_error_text  => 'Payroll Period Not Defined in INTG_ADP_PAYWEEK_MAPPING For Year =>'|| l_year
                               ,p_record_identifier_1 => p_gl_rec.user_je_category_name
                               ,p_record_identifier_2 => p_gl_rec.user_je_source_name
                               ,p_record_identifier_3 => p_gl_rec.journal_name);

              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Year In File ' || x_error_code);
              p_err_mesg := 'Payroll Period Not Defined in INTG_ADP_PAYWEEK_MAPPING For Year =>'|| l_year;
              RETURN x_error_code;
     END is_year_valid;

     -- -------------------------------------------------------------------------------------------------------------------------

 BEGIN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations');

      -- Je Source validation
      x_err_mesg := NULL;
      x_error_code_temp := is_source_valid ( p_gl_rec.user_je_source_name,x_err_mesg);
      x_error_message := x_error_message ||x_err_mesg;
      x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

      -- Je Category validation
      x_err_mesg := NULL;
      x_error_code_temp := is_category_valid ( p_gl_rec.user_je_category_name,x_err_mesg);
      x_error_message := x_error_message ||x_err_mesg;
      x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

      -- Acc Date validation
      x_err_mesg := NULL;
--      x_error_code_temp := is_period_valid ( p_gl_rec.accounting_date,p_gl_rec.record_id,x_err_mesg);
      x_error_code_temp := is_period_valid ( p_gl_rec.file_name,p_gl_rec.record_id,p_gl_rec.accounting_date,x_err_mesg);  --- 09 Feb
      x_error_message := x_error_message ||x_err_mesg;
      x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

      -- Currency validation
      x_err_mesg := NULL;
      x_error_code_temp := is_currency_valid ( p_gl_rec.currency_code,x_err_mesg);
      x_error_message := x_error_message ||x_err_mesg;
      x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

      -- Year validation  --- 09 Feb
      x_err_mesg := NULL;
      x_error_code_temp := is_year_valid ( p_gl_rec.file_name,x_err_mesg);
      x_error_message := x_error_message ||x_err_mesg;
      x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

      -- cross update the error mesages to record
      p_gl_rec.error_message := SUBSTR(x_error_message,1,3000);

     RETURN x_error_code;
 EXCEPTION
    WHEN xx_emf_pkg.G_E_REC_ERROR THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
    WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
    WHEN OTHERS THEN
          x_error_code := xx_emf_cn_pkg.cn_rec_err;
          RETURN x_error_code;
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Completed Data-Validations');
  END data_validations;
------------------------------------------------------------------------------------------------------------------------------------------------------------
  -- --------------------------------------------------------------------- --

  PROCEDURE main_prc ( p_errbuf        OUT VARCHAR2
                      ,p_retcode       OUT VARCHAR2
                      ,p_reprocess     IN  VARCHAR2
                      ,p_dummy         IN  VARCHAR2
                      ,p_requestid     IN  NUMBER
                      ,p_file_name     IN  VARCHAR2
                      ,p_restart_flag  IN  VARCHAR2
                     )
  IS

       CURSOR c_xx_gl_adp_payroll_stg ( cp_process_code VARCHAR2) IS
       SELECT *
         FROM xx_gl_adp_payroll_stg
        WHERE request_id   = xx_emf_pkg.G_REQUEST_ID
          AND process_code = cp_process_code
          AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

       --- 09 Feb
       CURSOR c_err_email_ids
       IS
	SELECT parameter_value
	  FROM xx_emf_process_parameters xpp,
	       xx_emf_process_setup xps
	 WHERE 1 = 1
	   AND xps.process_id   = xpp.process_id
	   AND xps.process_name = 'XXGLADPUTL'
	   AND parameter_name like 'ERR_EMAIL_%';

        x_error_code VARCHAR2(1)   := xx_emf_cn_pkg.CN_SUCCESS;
        x_stg_table                g_xx_gl_adp_payroll_tab_type;
        x_error_msg_temp           VARCHAR2 (3000);
        x_error_code_temp          NUMBER              := xx_emf_cn_pkg.cn_success;
        x_cst_error                EXCEPTION;
        x_error_msg                VARCHAR2 (3000);
        x_email_body_msg           VARCHAR2 (3000);
        g_gl_imp_req_id            VARCHAR2 (3000);
        g_err_email_ids            VARCHAR2 (3000);

        -- --------------------------------------------------------------------- --

        PROCEDURE update_record_status ( p_gl_rec       IN OUT  G_XX_GL_ADP_PAYROLL_REC_TYPE,
                                         p_error_code   IN      VARCHAR2)
        IS
        BEGIN
                IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
                THEN
                    p_gl_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                ELSE
                    p_gl_rec.error_code := find_max(p_error_code, NVL (p_gl_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));

                END IF;
                p_gl_rec.process_code := G_STAGE;

        END update_record_status;

        -- --------------------------------------------------------------------- --
        -- Initalizating the staging recods
        PROCEDURE update_int_records ( p_gl_rec  IN g_xx_gl_adp_payroll_tab_type)
        IS
           x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
        BEGIN
             FOR indx IN 1 .. p_gl_rec.COUNT LOOP
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'UPDATE_INT_RECORDS ');

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Process_code     ->' || p_gl_rec(indx).process_code);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error_code       ->' || p_gl_rec(indx).error_code);


                UPDATE xx_gl_adp_payroll_stg
                   SET   creation_date         = SYSDATE
                        ,created_by            = FND_GLOBAL.USER_ID
                        ,process_code          = G_STAGE
                        ,error_code            = p_gl_rec(indx).error_code
                        ,error_message         = p_gl_rec(indx).error_message
                        ,request_id            = p_gl_rec(indx).request_id
                        ,last_updated_by       = FND_GLOBAL.USER_ID
                        ,last_update_date      = SYSDATE
                        ,last_update_login     = x_last_update_login
                 WHERE record_id = p_gl_rec(indx).record_id;

             END LOOP;

            COMMIT;
        EXCEPTION
          WHEN OTHERS THEN
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in update_int_records' ||SQLERRM);
              xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
              x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
        END update_int_records;

        -- --------------------------------------------------------------------- --
        -- Inserting to interface table
        FUNCTION xx_gl_interface  RETURN NUMBER
        IS
            v_segment            VARCHAR2(10);
            v_date_created       date;
            x_return_status       VARCHAR2(15) := xx_emf_cn_pkg.CN_SUCCESS;

          CURSOR c_gl_upload(cp_process_code VARCHAR2) IS
           SELECT *
             FROM xx_gl_adp_payroll_stg bis
            WHERE request_id   = xx_emf_pkg.G_REQUEST_ID
              AND process_code = cp_process_code
              AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
          ORDER BY record_id;

        BEGIN
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'In side GL Interface Insert ');
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,' request_id ->'||xx_emf_pkg.G_REQUEST_ID);
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,' process_code ->'||xx_emf_cn_pkg.CN_POSTVAL);

           FOR gl_upload_rec IN c_gl_upload(xx_emf_cn_pkg.CN_POSTVAL)
           LOOP
             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside Interface Insert');

             Begin                                                                             ----Added By Sumanth as part of 5016#
            SELECT DISTINCT segment1,TRUNC(date_created) into v_segment,v_date_created
             FROM xx_gl_adp_payroll_stg bis
            WHERE request_id   = xx_emf_pkg.G_REQUEST_ID
			  AND batch_id =  gl_upload_rec.batch_id  --- Added for batch id in a file as per ticket case#10516
              AND process_code = xx_emf_cn_pkg.CN_POSTVAL
              AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
              AND Segment1 <> '101';
              EXCEPTION
              WHEN NO_DATA_FOUND THEN
               v_segment := '101';
                v_date_created := gl_upload_rec.date_created;
              WHEN TOO_MANY_ROWS THEN
                v_segment := null;
                v_date_created := gl_upload_rec.date_created;
              WHEN OTHERS THEN
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while inserting into Standard Interface Tables: ' ||SQLERRM);
              xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
              x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
              RETURN x_error_code;
                END;

             BEGIN
                INSERT INTO GL_INTERFACE(
                             status
                           , set_of_books_id
                           , accounting_date
                           , currency_code
                           , date_created
                           , created_by
                           , actual_flag
                           , user_je_category_name
                           , user_je_source_name
                           , currency_conversion_date
                           , encumbrance_type_id
                           , budget_version_id
                           , user_currency_conversion_type
                           , currency_conversion_rate
                           , segment1
                           , segment2
                           , segment3
                           , segment4
                           , segment5
                           , segment6
                           , segment7
                           , segment8
                           , segment9
                           , segment10
                           , entered_dr
                           , entered_cr
                           , accounted_dr
                           , accounted_cr
                           , transaction_date
                           , reference1
                           , reference2
                           , reference3
                           , reference4
                           , reference5
                           , reference6
                           , reference7
                           , reference8
                           , reference9
                           , reference10
                           , je_batch_id
                           , period_name
                           , je_header_id
                           , je_line_num
                           , chart_of_accounts_id
                           , functional_currency_code
                           , code_combination_id
                           , date_created_in_gl
                           , warning_code
                           , status_description
                           , stat_amount
                           , group_id
                           , request_id
                           , subledger_doc_sequence_id
                           , subledger_doc_sequence_value
                           , attribute1
                           , attribute2
                           , attribute3
                           , attribute4
                           , attribute5
                           , attribute6
                           , attribute7
                           , attribute8
                           , attribute9
                           , attribute10
                           , attribute11
                           , attribute12
                           , attribute13
                           , attribute14
                           , attribute15
                           , attribute16
                           , attribute17
                           , attribute18
                           , attribute19
                           , attribute20
                           , context
                           , context2
                           , invoice_date
                           , tax_code
                           , invoice_identifier
                           , invoice_amount
                           , context3
                           , ussgl_transaction_code
                           , descr_flex_error_message
                           , jgzz_recon_ref
                           , average_journal_flag
                           , originating_bal_seg_value
                           , gl_sl_link_id
                           , gl_sl_link_table
                           , reference_date
                           )
                VALUES
                           (
                             'NEW'                                       --status
                           , g_set_of_books_id                           --set_of_books_id
                           , gl_upload_rec.accounting_date               --accounting_date
                           , gl_upload_rec.currency_code                 --currency_code
                           , gl_upload_rec.accounting_date               --date_created
                           , FND_GLOBAL.USER_ID                          --created_by
                           , 'A'                                         --actual_flag
                           , gl_upload_rec.user_je_category_name         --user_je_category_name
                           , gl_upload_rec.user_je_source_name           --user_je_source_name
                           , SYSDATE                                     --currency_conversion_date
                           , NULL                                        --encumbrance_type_id
                           , NULL                                        --budget_version_id
                           , g_currency_conversion_type                  --user_currency_conversion_type
                           , NULL                                        --currency_conversion_rate
                           , gl_upload_rec.segment1                      --segment1
                           , gl_upload_rec.segment2                      --segment2
                           , gl_upload_rec.segment3                      --segment3
                           , gl_upload_rec.segment4                      --segment4
                           , gl_upload_rec.segment5                      --segment5
                           , gl_upload_rec.segment6                      --segment6
                           , gl_upload_rec.segment7                      --segment7
                           , gl_upload_rec.segment8                      --segment8
                           , NULL                                         --, gl_upload_rec.segment9                      --segment9
                           , NULL                                        --segment10
                           , gl_upload_rec.entered_dr                    --entered_dr
                           , gl_upload_rec.entered_cr                    --entered_cr
                           , NULL                                        --accounted_dr
                           , NULL                                        --accounted_cr
                           , SYSDATE                                     --transaction_date
                           , NULL                                        --reference1
                           , NULL                                        --reference2
                           , NULL                                        --reference3
                           , v_segment||'_'||v_date_created              --reference4                              ----Added By Sumanth as part of 5016#
                           , NULL                                        --reference5
                           , NULL                                        --reference6
                           , NULL                                        --reference7
                           , NULL                                        --reference8
                           , NULL                                        --reference9
                           , gl_upload_rec.line_description              --reference10
                           , NULL                  --je_batch_id
                           , NULL                  --period_name
                           , NULL                  --je_header_id
                           , NULL                  --je_line_num
                           , NULL                  --chart_of_accounts_id
                           , NULL                  --functional_currency_code
                           , NULL                  --code_combination_id
                           , NULL                  --date_created_in_gl
                           , NULL                  --warning_code
                           , NULL                  --status_description
                           , NULL                  --stat_amount
                           , gl_upload_rec.batch_id--group_id
                           , NULL                  --request_id
                           , NULL                  --subledger_doc_sequence_id
                           , NULL                  --subledger_doc_sequence_value
                           , NULL                  --attribute1
                           , NULL                  --attribute2
                           , NULL                  --attribute3
                           , NULL                  --attribute4
                           , NULL                  --attribute5
                           , NULL                  --attribute6
                           , NULL                  --attribute7
                           , NULL                  --attribute8
                           , NULL                  --attribute9
                           , NULL                  --attribute10
                           , NULL                  --attribute11
                           , NULL                  --attribute12
                           , NULL                  --attribute13
                           , NULL                  --attribute14
                           , NULL                  --attribute15
                           , NULL                  --attribute16
                           , NULL                  --attribute17
                           , NULL                  --attribute18
                           , NULL                  --attribute19
                           , gl_upload_rec.record_id--attribute20
                           , NULL                  --context
                           , NULL                  --context2
                           , NULL                  --invoice_date
                           , NULL                  --tax_code
                           , NULL                  --invoice_identifier
                           , NULL                  --invoice_amount
                           , NULL                  --context3
                           , NULL                  --ussgl_transaction_code
                           , NULL                  --descr_flex_error_message
                           , NULL                  --jgzz_recon_ref
                           , NULL                  --average_journal_flag
                           , NULL                  --originating_bal_seg_value
                           , NULL                  --gl_sl_link_id
                           , NULL                  --gl_sl_link_table
                           , NULL                  --reference_date
                           );

             END;
           END LOOP;
           COMMIT;
           RETURN x_return_status;
        EXCEPTION
          WHEN OTHERS THEN
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while inserting into Standard Interface Tables: ' ||SQLERRM);
              xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
              x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
              RETURN x_error_code;
        END xx_gl_interface;

        -- --------------------------------------------------------------------- --

        FUNCTION error_gl_import
        RETURN NUMBER
        IS
          CURSOR c_err
          IS
          SELECT  *
        FROM  gl_interface
       WHERE  group_id in (SELECT distinct batch_id
                             FROM xx_gl_adp_payroll_stg
                            WHERE request_id=FND_GLOBAL.CONC_REQUEST_ID )--= g_group_id
             AND  status <> 'NEW';

          x_return_status       VARCHAR2(15) := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'In side error_gl_import');
           FOR r_err IN c_err LOOP
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'In side error_gl_import loop ->'||TO_NUMBER(r_err.attribute20));
                 UPDATE  xx_gl_adp_payroll_stg
                    SET  process_code  = xx_emf_cn_pkg.CN_POSTVAL
                        ,error_code    = xx_emf_cn_pkg.CN_REC_ERR
                        ,error_message = r_err.status||' - '||NVL(r_err.status_description,'Interface Errors')
                  WHERE  record_id     = TO_NUMBER(r_err.attribute20)
                  AND request_id       = NVL(p_requestid,request_id)
                  AND file_name        = NVL(p_file_name,file_name);

                  xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW,
                                   xx_emf_cn_pkg.CN_STG_DATAVAL,
                                   r_err.status||' - '||NVL(r_err.status_description,'Interface Errors'),
                                   r_err.user_je_category_name,
                                   r_err.user_je_source_name,
                                   r_err.reference10);
           END LOOP;
           COMMIT;
           RETURN x_return_status;
        EXCEPTION
          WHEN OTHERS THEN
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while fetching GL Interface erros: ' ||SQLERRM);
              xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
              x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
              RETURN x_error_code;
        END error_gl_import;
        -- --------------------------------------------------------------------- --

        FUNCTION run_gl_import
        RETURN NUMBER
        IS
          CURSOR c_distinct_group_id
          IS
          SELECT  distinct batch_id
        FROM  XX_GL_ADP_PAYROLL_STG
       WHERE  request_id=FND_GLOBAL.CONC_REQUEST_ID;

        CURSOR c_err_email_ids
        IS
      	SELECT parameter_value
      	  FROM xx_emf_process_parameters xpp,
      	       xx_emf_process_setup xps
      	 WHERE 1 = 1
      	   AND xps.process_id   = xpp.process_id
      	   AND xps.process_name = 'XXGLADPUTL'
      	   AND parameter_name like 'ERR_EMAIL_%';

           x_error_code        NUMBER          := xx_emf_cn_pkg.cn_success;
           x_interface_run_id  NUMBER;
           x_conc_id           NUMBER;
           x_group_id          NUMBER;
           x_data_set_id       NUMBER;
           x_rec_cnt           NUMBER := 0;

           x_wait_req          BOOLEAN;
           x_phase             VARCHAR2 (25);
           x_status            VARCHAR2 (25);
           x_dev_phase         VARCHAR2 (25);
           x_dev_status        VARCHAR2 (25);
           x_message           VARCHAR2 (2000);
           x_null_group_id     NUMBER:=NULL;
        BEGIN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Starting Launching GL Import');
            SELECT gl_journal_import_s.nextval
              INTO x_interface_run_id
              FROM DUAL;

            BEGIN
               SELECT  access_set_id
                 INTO  x_data_set_id
                 FROM  gl_access_set_ledgers
                WHERE  ledger_id = g_set_of_books_id
                  AND  ROWNUM = 1;
            EXCEPTION WHEN OTHERS THEN
               x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
               RETURN x_error_code;
            END;

            SELECT  COUNT(*)
              INTO  x_rec_cnt
              FROM  gl_interface
             WHERE  group_id  in (SELECT distinct batch_id
                                FROM xx_gl_adp_payroll_stg
                               WHERE request_id=FND_GLOBAL.CONC_REQUEST_ID );
            g_gl_imp_req_id := Null;
            IF NVL(x_rec_cnt,0) > 0 THEN
               FOR r_distinct_group_id IN c_distinct_group_id LOOP
                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'GL Import'||g_set_of_books_id||'-'||x_data_set_id);
                   gl_journal_import_pkg.populate_interface_control
                                 ( user_je_source_name => g_je_source_name
                                  ,group_id            => r_distinct_group_id.batch_id--x_null_group_id--      --Added for multiple group_id,GL Import will be submitted will Source only.
                                  ,set_of_books_id     => g_set_of_books_id
                                  ,interface_run_id    => x_interface_run_id);

                   x_conc_id := FND_REQUEST.SUBMIT_REQUEST
                                     ( application => 'SQLGL'
                                      ,program     => 'GLLEZL'
                                      ,description => NULL
                                      ,start_time  => SYSDATE
                                      ,sub_request => FALSE
                                      ,argument1   => x_interface_run_id
                                      ,argument2   => x_data_set_id
                                      ,argument3   => 'N'
                                      ,argument4   => NULL
                                      ,argument5   => NULL
                                      ,argument6   => 'N'
                                      ,argument7   => 'W'
                                      ,argument8   => 'Y');

                   IF x_conc_id = 0 THEN
                      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Launching GL Import failed');
                      x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
                      --RETURN x_error_code;
                   ELSE
                      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Launching GL Import success ->'||x_conc_id);
                      COMMIT;
                      g_gl_imp_req_id := g_gl_imp_req_id||' , '||x_conc_id;
                      x_wait_req := FND_CONCURRENT.WAIT_FOR_REQUEST
                                                (request_id      => x_conc_id,
                                                 interval        => 0,
                                                 phase           => x_phase,
                                                 status          => x_status,
                                                 dev_phase       => x_dev_phase,
                                                 dev_status      => x_dev_status,
                                                 message         => x_message
                                                );
                      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'x_dev_phase->'||x_dev_phase||'-'|| 'x_dev_status->'||x_dev_status);
                      IF x_dev_phase = 'COMPLETE' AND x_dev_status = 'NORMAL' THEN
                         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No Interface Errors');
                      ELSE
                         x_error_code := error_gl_import;
                         /*Copy the Email Logic Here to Send Email If any gl import ends in Error or Warning */  --- 09 Feb
                             g_gl_imp_req_id := x_conc_id;
                    	       x_email_body_msg:=xx_intg_common_pkg.set_token_message( p_message_name  => 'XXGL_ADP_INTERFACE_MSG'
                    								                                                ,p_token_value1  => xx_emf_pkg.G_REQUEST_ID
                     								                                                ,p_token_value2  => g_gl_imp_req_id
                    								                                                ,p_no_of_tokens  => 2
                    								                                                );
                                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'x_email_body_msg x_cst_error --> '||x_email_body_msg);
                                   FOR rec_err_email_ids IN c_err_email_ids
                                   LOOP
                                   xx_intg_mail_util_pkg.mail ( sender     => 'ADP GL Interface'
                    					                                 ,recipients => rec_err_email_ids.parameter_value --- g_err_email_ids  ---'wfore01@integralife.com'   ----
                    					                                 ,subject    => 'INTG ADP GL Interface program Completed in error/warning'
                    					                                 ,message    => x_email_body_msg
                    				                                 	);
                                   END LOOP;

                      END IF;
                      --RETURN x_error_code;
                   END IF;
               END LOOP;
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'End Launching GL Import');
             END IF;
             RETURN x_error_code;
        EXCEPTION
          WHEN OTHERS THEN
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while running GL Import: ' ||SQLERRM);
              xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
              x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
              RETURN x_error_code;
        END run_gl_import;

        -- --------------------------------------------------------------------- --
        -- mark_records_complete
        PROCEDURE mark_records_complete (p_process_code    VARCHAR2)
        IS
           x_last_update_date       DATE   := SYSDATE;
           x_last_updated_by        NUMBER := fnd_global.user_id;
           x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
           PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of mark records complete...');
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside mark_records_complete');

           UPDATE xx_gl_adp_payroll_stg    --Header
              SET process_code      = G_STAGE,
                  error_code        = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
                  last_updated_by   = x_last_updated_by,
                  last_update_date  = x_last_update_date,
                  last_update_login = x_last_update_login
            WHERE request_id   = xx_emf_pkg.G_REQUEST_ID
              AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
              AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);
           COMMIT;

         EXCEPTION
            WHEN OTHERS THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in Update of mark_records_complete '||SQLERRM);
         END mark_records_complete;

 -- --------------------------------------------------------------------- --

    BEGIN
       p_retcode := xx_emf_cn_pkg.CN_SUCCESS;
       g_p_reprocess := p_reprocess;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Before Setting Environment');

       -- Emf Env initialization
       x_error_code := xx_emf_pkg.set_env;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Starting main process with the following parameters');

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_reprocess    '    || p_reprocess);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_requestid    '    || p_requestid);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_file_name    '    || p_file_name);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_restart_flag '    || p_restart_flag);

       -- ------------------------------------ --
       -- Setting Global Variables
       x_error_code := xx_global_var;
       -- ------------------------------------ --
       IF NVL(p_reprocess,'N') = 'N' THEN

          --x_error_code :=  get_file_ftp;
          --IF x_error_code != xx_emf_cn_pkg.cn_success THEN
          --   RAISE x_cst_error;
          --END IF;

          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Start Calling utl_read_insert_stg..');

          utl_read_insert_stg( x_error_code_temp ,x_error_msg_temp);

          IF x_error_code != xx_emf_cn_pkg.cn_success THEN
             RAISE x_cst_error;
          END IF;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'End Calling utl_read_insert_stg..');
       END IF;
       -- ------------------------------------ --

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Start Calling mark_records_for_processing..');

       mark_records_for_processing( p_reprocess    => p_reprocess
                                   ,p_requestid    => p_requestid
                                   ,p_file_name    => p_file_name
                                   ,p_restart_flag => p_restart_flag);

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'End Calling mark_records_for_processing..');

       -- ------------------------------------ --

       -- Set the stage to Pre Validations
       set_stage (xx_emf_cn_pkg.CN_PREVAL);

       -- ------------------------------------ --
       -- Cross updating staging table
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Start Calling update_staging_records..');
       update_staging_records (xx_emf_cn_pkg.CN_SUCCESS);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'End Calling update_staging_records..');
       -- ------------------------------------ --

       xx_emf_pkg.propagate_error ( x_error_code);
       --- 09 Feb
       g_err_email_ids := Null;
       FOR rec_err_email_ids IN c_err_email_ids
       LOOP
         g_err_email_ids := g_err_email_ids||','||rec_err_email_ids.parameter_value;
       END LOOP;
       g_err_email_ids := SUBSTR(g_err_email_ids,2,length(g_err_email_ids));
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Send Error Email To --->'||g_err_email_ids);
       --- 09 Feb Ends ---
       -- Set the stage to data Validations
       set_stage (xx_emf_cn_pkg.CN_VALID);

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'FLAGS -->'||'Req->'||xx_emf_pkg.G_REQUEST_ID||' - '||'cp_process_code ->'||xx_emf_cn_pkg.CN_PREVAL||' - '||xx_emf_cn_pkg.CN_SUCCESS||' - '||xx_emf_cn_pkg.CN_REC_WARN);

       OPEN c_xx_gl_adp_payroll_stg ( xx_emf_cn_pkg.CN_PREVAL);
       LOOP
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'In the interface records loop');

           FETCH c_xx_gl_adp_payroll_stg
           BULK COLLECT INTO x_stg_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_stg_table.count 1->' || x_stg_table.COUNT );

           FOR i IN 1 .. x_stg_table.COUNT
           LOOP
                BEGIN
                   x_error_code := data_validations (x_stg_table (i));
                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'After Data Validations ... x_error_code : '||x_error_code||'-'||x_stg_table.COUNT);

                   update_record_status (x_stg_table (i), x_error_code);

                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,  'After update_record_status ...');
                   xx_emf_pkg.propagate_error (x_error_code);

                   -- Set the stage to Post Validations
                   set_stage (xx_emf_cn_pkg.CN_POSTVAL);
                   update_staging_records (xx_emf_cn_pkg.CN_SUCCESS);
                EXCEPTION
                   WHEN xx_emf_pkg.G_E_REC_ERROR THEN
                           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.CN_REC_ERR);
                   WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
                           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Process Level Error in Data Validations');
                           RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                   WHEN OTHERS THEN
                           xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_stg_table (i).record_id);
                END;
             END LOOP;

             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_stg_table.count 2->' || x_stg_table.COUNT );
             update_int_records( x_stg_table);
             x_stg_table.DELETE;

             EXIT WHEN c_xx_gl_adp_payroll_stg%NOTFOUND;
       END LOOP;

       IF c_xx_gl_adp_payroll_stg%ISOPEN THEN
          CLOSE c_xx_gl_adp_payroll_stg;
       END IF;

       -- Set the stage to Post Validations
       set_stage (xx_emf_cn_pkg.CN_POSTVAL);
       x_error_code := post_validations ();

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
       mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);

       xx_emf_pkg.propagate_error ( x_error_code);

       --- Copmmented By Dhiren For Testing
       -- ------------------------------------ --
       -- to interface table
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'To GL Interface');
       x_error_code := xx_gl_interface;
       IF x_error_code != xx_emf_cn_pkg.cn_success THEN
          RAISE x_cst_error;
       END IF;
       -- ------------------------------------ --

       -- ------------------------------------ --
       -- Invoking GL Import
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Invoking GL Import');
       x_error_code := run_gl_import;
       IF x_error_code != xx_emf_cn_pkg.cn_success THEN
          RAISE x_cst_error;
       END IF;
       -- ------------------------------------ --

       -- Set the stage to Process Data
       set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);

       -- ------------------------------------ --
       mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After Process Data mark_records_complete x_error_code'||x_error_code);
       -- ------------------------------------ --

       -- ------------------------------------ --
       -- Archiving the files
       x_error_code :=move_file_archive;
       IF x_error_code != xx_emf_cn_pkg.cn_success THEN
          RAISE x_cst_error;
       END IF;
       -- ------------------------------------ --


       -- Emf error propagate
       xx_emf_pkg.propagate_error ( x_error_code);

       -- update record count
       update_record_count;

       -- emf report
       xx_emf_pkg.create_report;

/*For Email Testing

g_gl_imp_req_id := SUBSTR(g_gl_imp_req_id,3,LENGTH(g_gl_imp_req_id));
xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Email Program Starts ' );
	       x_email_body_msg:=xx_intg_common_pkg.set_token_message( p_message_name  => 'XXGL_ADP_INTERFACE_MSG'
								    ,p_token_value1  => xx_emf_pkg.G_REQUEST_ID
								    ,p_token_value2  => g_gl_imp_req_id
								    ,p_no_of_tokens  => 2
								   );
xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'x_email_body_msg --> '||x_email_body_msg);
               FOR rec_err_email_ids IN c_err_email_ids
               LOOP
               xx_intg_mail_util_pkg.mail ( sender     => 'ADP GL Interface'
					   ,recipients => rec_err_email_ids.parameter_value --- g_err_email_ids  ---'wfore01@integralife.com'   ----
					   ,subject    => 'INTG ADP GL Interface program Completed in error/warning'
					   ,message    => x_email_body_msg
					);
               END LOOP;
 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Email Program Ends ' );
*/
    EXCEPTION
        WHEN x_cst_error THEN
            p_retcode := x_error_code;
            p_errbuf := x_error_msg_temp||' '||x_error_msg ||'  '||SQLERRM;
         g_gl_imp_req_id := SUBSTR(g_gl_imp_req_id,3,LENGTH(g_gl_imp_req_id));
	       x_email_body_msg:=xx_intg_common_pkg.set_token_message( p_message_name  => 'XXGL_ADP_INTERFACE_MSG'
								    ,p_token_value1  => xx_emf_pkg.G_REQUEST_ID
								    ,p_token_value2  => g_gl_imp_req_id
								    ,p_no_of_tokens  => 2
								   );
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'x_email_body_msg x_cst_error --> '||x_email_body_msg);
               FOR rec_err_email_ids IN c_err_email_ids
               LOOP
               xx_intg_mail_util_pkg.mail ( sender     => 'ADP GL Interface'
					   ,recipients => rec_err_email_ids.parameter_value --- g_err_email_ids  ---'wfore01@integralife.com'   ----
					   ,subject    => 'INTG ADP GL Interface program Completed in error/warning'
					   ,message    => x_email_body_msg
					);
               END LOOP;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,' Error ='
                                  || x_error_msg_temp||' '||x_error_msg
                                  || ' x_error_code = '
                                  || x_error_code
                                 );

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'SQLERRM = ' || SQLERRM
                                 );

        WHEN OTHERS THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,' Main Exception :'
                                     || x_error_msg
                                     || ' x_error_code = '
                                     || x_error_code
                                    );

               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                     'SQLERRM = ' || SQLERRM
                                    );

               p_retcode := x_error_code;
               p_errbuf  := x_error_msg || SQLERRM;
         g_gl_imp_req_id := SUBSTR(g_gl_imp_req_id,3,LENGTH(g_gl_imp_req_id));
	       x_email_body_msg:=xx_intg_common_pkg.set_token_message( p_message_name  => 'XXGL_ADP_INTERFACE_MSG'
								    ,p_token_value1  => xx_emf_pkg.G_REQUEST_ID
								    ,p_token_value2  => g_gl_imp_req_id
								    ,p_no_of_tokens  => 2
								   );
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'x_email_body_msg others --> '||x_email_body_msg);
               FOR rec_err_email_ids IN c_err_email_ids
               LOOP
               xx_intg_mail_util_pkg.mail ( sender     => 'ADP GL Interface'
					   ,recipients => rec_err_email_ids.parameter_value  --- 'wfore01@integralife.com'   ---- rec_err_email_ids.parameter_value
					   ,subject    => 'INTG ADP GL Interface program Completed in error/warning'
					   ,message    => x_email_body_msg
					);
               END LOOP;
               xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                                 p_category                 => xx_emf_cn_pkg.cn_tech_error,
                                 p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                                 p_record_identifier_1      => SQLCODE,
                                 p_record_identifier_2      => SQLERRM
                                );
               xx_emf_pkg.create_report;
    END main_prc;

--- To Check Year and Week Numbers ----
FUNCTION xx_gl_is_num(n VARCHAR2)
RETURN VARCHAR2
IS
 BEGIN
   FOR V IN 1..LENGTH(n) LOOP
    IF NOT((ASCII(SUBSTR(n,v,1))>=48) AND (ASCII(SUBSTR(n,v,1))<=57)) THEN
       RETURN 'F';
    END IF;
   END LOOP;
 RETURN 'T';
END;

  -- --------------------------------------------------------------------- --
END xx_gl_adp_payroll_int_pkg;
/
