DROP PACKAGE BODY APPS.XX_HR_LRN_INT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xx_hr_lrn_int_pkg
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 06-Aug-2013
 File Name     : xx_hr_lrn_int.pkb
 Description   : This script creates the body of the package
                 xx_hr_lrn_int_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 06-Aug-2013 Renjith               Initial Version
 20-Nov-2013 Francis               Code added for CASE-3481
 10-Sep-2014 Jaya Jayaraj           Modified for ticket#8949
17-Mar-2015 Vighnesh Nayak        Modified for  ticket#013426
07-Apr-2015 Vighnesh Nayak        Modified for  ticket#013846 and 014067
09-Jun-2015 Vighnesh Nayak        Added trunc function in hr_rep , supervisor inner query against CC-015173
*/
----------------------------------------------------------------------
   x_user_id          NUMBER := FND_GLOBAL.USER_ID;
   x_login_id         NUMBER := FND_GLOBAL.LOGIN_ID;
   x_request_id       NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
   x_resp_id          NUMBER := FND_GLOBAL.RESP_ID;
   x_resp_appl_id     NUMBER := FND_GLOBAL.RESP_APPL_ID;
   x_max_request_id    NUMBER:=NULL;
  ----------------------------------------------------------------------
Function special_char_rep(p_name IN VARCHAR2) RETURN VARCHAR2 IS
x_name_char VARCHAR2(240);
BEGIN
select TRANSLATE(REPLACE(REPLACE(p_name,CHR(50054),'AE'),CHR(50086),'ae')
,CHR(50052)||
CHR(50053)|| CHR(50048)|| CHR(50049)|| CHR(50051)|| CHR(50084)|| CHR(50080)|| CHR(50081)|| CHR(50083)|| CHR(50085)|| CHR(50055)|| CHR(50087)|| CHR(50056)||
CHR(50057)|| CHR(50058)|| CHR(50059)|| CHR(50088)|| CHR(50089)|| CHR(50090)|| CHR(50091)|| CHR(50060)|| CHR(50061)|| CHR(50062)|| CHR(50063)|| CHR(50092)|| CHR(50093)|| CHR(50094)|| CHR(50095)|| CHR(50065)|| CHR(50097)|| CHR(50100)|| CHR(49850)|| CHR(50098)|| CHR(50099)|| CHR(50101)|| CHR(50102)|| CHR(50066)||  CHR(50067)|| CHR(50068)|| CHR(50069)|| CHR(50070)|| CHR(50075)|| CHR(50073)||
CHR(50074)|| CHR(50076)||
CHR(50105)|| CHR(50106)|| CHR(50107)|| CHR(50108),'AAAAAAaaaaCcEEEEeeeeIIIIiiiiNnooooooOOOOOUUUUuuuu')
INTO x_name_char
from dual;
return(x_name_char);
EXCEPTION
     WHEN OTHERS THEN
     x_name_char:=NULL;
      return(x_name_char);
END special_char_rep;

  PROCEDURE write_lrn_file( p_file_name    IN   VARCHAR2
                           ,p_email_flag   IN   VARCHAR2
                           ,x_return_code  OUT  NUMBER
                           ,x_error_msg    OUT  VARCHAR2)
  IS
    CURSOR c_lrn_file
    IS
      SELECT  distinct user_name,password,first_name,middle_names,last_name,email_address,employee_number,job_name,position_name,org_name
              ,emp_category,location_code,recent_hire_date,assign_status,supervisor_name,supervisor_email,manage_others,MANAGES_PEOPLE_WORKING_IN_CA
              ,rehire,recent_term_date,hr_rep_name,active_flag
        FROM  xx_hr_lrn_int
       WHERE  record_type=1
         AND  request_id = x_request_id;
    CURSOR   c_mail
    IS
     SELECT  description
       FROM  fnd_lookup_values_vl
      WHERE  lookup_type = 'INTG_LRN_INTERFACE_RECIPIENTS'
        AND  NVL(enabled_flag,'X')='Y'
        AND  LOOKUP_CODE=1
        AND  SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE);

     x_file_lrn_type   UTL_FILE.file_type;
     x_data_lrn_dir    VARCHAR2(80);
     x_lrn_data        VARCHAR2(4000);

     x_err_out         VARCHAR2(4000);
     x_file_name       VARCHAR2(1000) :=p_file_name;
     x_to_mail         VARCHAR2(1000);
     x_subject         VARCHAR2(60);
     x_message         VARCHAR2(60);
     x_from            VARCHAR2(60);
     x_bcc_name        VARCHAR2(60);
     x_cc_name         VARCHAR2(60);


  BEGIN

     xx_intg_common_pkg.get_process_param_value( p_process_name => 'XXHRLRNINT'
                                                ,p_param_name   => 'DATA_DIR'
                                                ,x_param_value  =>  x_data_lrn_dir);

     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'file name-> '||p_file_name);

     -- opening the file
     BEGIN
         x_file_lrn_type := UTL_FILE.fopen_nchar (x_data_lrn_dir, p_file_name, 'W', 6400);
     EXCEPTION
         WHEN UTL_FILE.invalid_path THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'Invalid Path for File :' || p_file_name;
         WHEN UTL_FILE.invalid_filehandle THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  :=  'File handle is invalid for File :' || p_file_name;
         WHEN UTL_FILE.write_error THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'Unable to write the File :' || p_file_name;
         WHEN UTL_FILE.invalid_operation THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'File could not be opened for writting:' || p_file_name;
         WHEN UTL_FILE.invalid_maxlinesize THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg  := 'File ' || p_file_name;
         WHEN UTL_FILE.access_denied THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg  := 'Access denied for File :' || p_file_name;
         WHEN OTHERS THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg   := 'File '||p_file_name ||'->'|| SQLERRM;
      END;

     FOR file_rec IN c_lrn_file LOOP
       x_lrn_data := NULL;
/*
       x_lrn_data := file_rec.user_name||'|'||file_rec.password||'|'||file_rec.first_name||'|'||file_rec.middle_names||'|'||file_rec.last_name||'|'||file_rec.email_address||'|'||file_rec.employee_number||'|'||
                     file_rec.job_name||'|'||file_rec.position_name||'|'||file_rec.org_name||'|'||file_rec.emp_category||'|'||file_rec.location_code||'|'||TO_CHAR(file_rec.recent_hire_date,'MM/DD/YYYY')||'|'||
                     file_rec.assign_status||'|'||file_rec.supervisor_name||'|'||file_rec.supervisor_email||'|'||file_rec.manage_others||'|'||file_rec.MANAGES_PEOPLE_WORKING_IN_CA||'|'||file_rec.rehire||'|'||
                     TO_CHAR(file_rec.recent_term_date,'MM/DD/YYYY')||'|'||file_rec.hr_rep_name||'|'||file_rec.active_flag||'|';
*/
       x_lrn_data := '"'||file_rec.user_name||'"'||','||'"'||file_rec.password||'"'||','||'"'||file_rec.first_name||'"'||','||'"'||file_rec.middle_names||'"'||','||'"'||file_rec.last_name||'"'||','||'"'||file_rec.email_address||'"'||','||file_rec.employee_number||','||
                     '"'||file_rec.job_name||'"'||','||'"'||file_rec.position_name||'"'||','||'"'||file_rec.org_name||'"'||','||'"'||file_rec.emp_category||'"'||','||'"'||file_rec.location_code||'"'||','||TO_CHAR(file_rec.recent_hire_date,'MM/DD/YYYY')||','||
                     '"'||file_rec.assign_status||'"'||','||'"'||file_rec.supervisor_name||'"'||','||'"'||file_rec.supervisor_email||'"'||','||'"'||file_rec.manage_others||'"'||','||'"'||file_rec.MANAGES_PEOPLE_WORKING_IN_CA||'"'||','||'"'||file_rec.rehire||'"'||','||
                     TO_CHAR(file_rec.recent_term_date,'MM/DD/YYYY')||','||'"'||file_rec.hr_rep_name||'"'||','||'"'||file_rec.active_flag||'"';

      -- UTL_FILE.PUT_LINE(x_file_lrn_type,x_lrn_data);
      UTL_FILE.PUT_LINE_NCHAR(x_file_lrn_type,x_lrn_data);
     END LOOP;

     IF UTL_FILE.IS_OPEN(x_file_lrn_type) THEN
        UTL_FILE.FCLOSE (x_file_lrn_type);
     END IF;
     IF NVL(p_email_flag,'X') = 'Y' THEN
        /*
        xx_intg_common_pkg.get_process_param_value( p_process_name => 'XXHRLRNINT'
                                                   ,p_param_name   => 'SUBJECT'
                                                   ,x_param_value  =>  x_subject);
        */
        x_subject:='LRN File';
        xx_intg_common_pkg.get_process_param_value( p_process_name => 'XXHRLRNINT'
                                                   ,p_param_name   => 'MESSAGE'
                                                   ,x_param_value  =>  x_message);

        xx_intg_common_pkg.get_process_param_value( p_process_name => 'XXHRLRNINT'
                                                   ,p_param_name   => 'FROM_EMAIL_ID'
                                                   ,x_param_value  =>  x_from);

        FOR mail_rec IN c_mail LOOP
           x_to_mail := x_to_mail ||mail_rec.description;
        END LOOP;
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'------------------- LRN File Mailing   ------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_from      -> '||x_from);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_mail   -> '||x_to_mail);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_subject   -> '||x_subject);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_message   -> '||x_message);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_dir    -> '||x_data_lrn_dir);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_file_name -> '||x_file_name);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');

        IF x_to_mail IS NOT NULL THEN
           BEGIN
             xx_intg_mail_util_pkg.send_mail_attach( p_from_name        => x_from
                                                    ,p_to_name          => x_to_mail
                                                    ,p_cc_name          => x_cc_name
                                                    ,p_bc_name          => x_bcc_name
                                                    ,p_subject          => x_subject
                                                    ,p_message          => x_message
                                                    ,p_oracle_directory => x_data_lrn_dir
                                                    ,p_binary_file      => x_file_name);
           EXCEPTION
              WHEN OTHERS THEN
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
              x_return_code := xx_emf_cn_pkg.cn_rec_warn;
              x_error_msg   := 'Error in mailing error file';
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,x_error_msg);
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
           END;
        END IF;
     END IF;
  EXCEPTION
     WHEN OTHERS THEN
      x_error_msg   := 'Procedure - write_lrn_file ->' || SQLERRM;
      x_return_code := xx_emf_cn_pkg.cn_prc_err;
  END write_lrn_file;

  ----------------------------------------------------------------------

  PROCEDURE write_err_file( p_file_name    IN   VARCHAR2
                           ,p_email_flag   IN   VARCHAR2
                           ,x_return_code  OUT  NUMBER
                           ,x_error_msg    OUT  VARCHAR2)
  IS
    CURSOR c_lrn_file
    IS
      SELECT  *
        FROM  xx_hr_lrn_int
       WHERE  record_type = 2
         AND  request_id = x_request_id;

    CURSOR   c_mail
    IS
     SELECT  description
       FROM  fnd_lookup_values_vl
      WHERE  lookup_type = 'INTG_LRN_INTERFACE_RECIPIENTS'
        AND  NVL(enabled_flag,'X')='Y'
        AND  LOOKUP_CODE=2
        AND  SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE);

     x_file_err_type   UTL_FILE.file_type;
     x_data_err_dir    VARCHAR2(80);
     x_err_data        VARCHAR2(4000);
     x_err_data_head   VARCHAR2(4000);  -- added for header
     x_err_out         VARCHAR2(4000);
     x_file_name       VARCHAR2(1000) :=p_file_name;
     x_to_mail         VARCHAR2(1000);
     x_subject         VARCHAR2(60);
     x_message         VARCHAR2(60);
     x_from            VARCHAR2(60);
     x_bcc_name        VARCHAR2(60);
     x_cc_name         VARCHAR2(60);
  BEGIN
     xx_intg_common_pkg.get_process_param_value( p_process_name => 'XXHRLRNINT'
                                                ,p_param_name   => 'DATA_DIR'
                                                ,x_param_value  =>  x_data_err_dir);

     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'file name-> '||x_file_name);

     -- opening the file
     BEGIN
         x_file_err_type := UTL_FILE.fopen_nchar (x_data_err_dir, x_file_name, 'W', 6400);
     EXCEPTION
         WHEN UTL_FILE.invalid_path THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'Invalid Path for File :' || x_file_name;
         WHEN UTL_FILE.invalid_filehandle THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  :=  'File handle is invalid for File :' || x_file_name;
         WHEN UTL_FILE.write_error THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'Unable to write the File :' || x_file_name;
         WHEN UTL_FILE.invalid_operation THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'File could not be opened for writting:' || x_file_name;
         WHEN UTL_FILE.invalid_maxlinesize THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg  := 'File ' || x_file_name;
         WHEN UTL_FILE.access_denied THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg  := 'Access denied for File :' || x_file_name;
         WHEN OTHERS THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg   := 'File '||x_file_name ||'->'|| SQLERRM;
      END;

     -- Adding Header Informaion
     x_err_data_head := 'User Name'||','||'First Name'||','||'Last Name'||','||'Email Address'||','||'Employee Number'||','||'Job Name'||','||
     'Position Name'||','||'Organization Name'||','||'Location Name'||','||'Supervisor Name'||','||'Supervisor Email'||','||'HR Rep Name';

     UTL_FILE.PUT_LINE_NCHAR(x_file_err_type,x_err_data_head);

     FOR file_rec IN c_lrn_file LOOP
/*
       x_err_data := NULL;
       x_err_data := file_rec.user_name||'|'||file_rec.first_name||'|'||file_rec.last_name||'|'||
                 file_rec.email_address||'|'||file_rec.employee_number||'|'||file_rec.job_name||'|'||file_rec.position_name||'|'||file_rec.org_name||'|'||
                 file_rec.location_code||'|'||file_rec.supervisor_name||'|'||file_rec.supervisor_email||'|'||
                 file_rec.hr_rep_name||'|';
*/
       x_err_data := NULL;
       x_err_data := '"'||file_rec.user_name||'"'||','||'"'||file_rec.first_name||'"'||','||'"'||file_rec.last_name||'"'||','||
                 '"'||file_rec.email_address||'"'||','||file_rec.employee_number||','||'"'||file_rec.job_name||'"'||','||'"'||file_rec.position_name||'"'||','||'"'||file_rec.org_name||'"'||','||
                 '"'||file_rec.location_code||'"'||','||'"'||file_rec.supervisor_name||'"'||','||'"'||file_rec.supervisor_email||'"'||','||
                 '"'||file_rec.hr_rep_name||'"';
       UTL_FILE.PUT_LINE_NCHAR(x_file_err_type,x_err_data);
     END LOOP;

     IF UTL_FILE.IS_OPEN(x_file_err_type) THEN
        UTL_FILE.FCLOSE (x_file_err_type);
     END IF;

     IF NVL(p_email_flag,'X') = 'Y' THEN
        /*
        xx_intg_common_pkg.get_process_param_value( p_process_name => 'XXHRLRNINT'
                                                   ,p_param_name   => 'SUBJECT'
                                                   ,x_param_value  =>  x_subject);
        */
        x_subject:='LRN Exception File';
        xx_intg_common_pkg.get_process_param_value( p_process_name => 'XXHRLRNINT'
                                                   ,p_param_name   => 'MESSAGE'
                                                   ,x_param_value  =>  x_message);

       xx_intg_common_pkg.get_process_param_value( p_process_name => 'XXHRLRNINT'
                                                   ,p_param_name   => 'FROM_EMAIL_ID'
                                                   ,x_param_value  =>  x_from);


        FOR mail_rec IN c_mail LOOP
           x_to_mail := x_to_mail ||mail_rec.description;
        END LOOP;
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'------------------- LRN Exception File Mailing   ------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_from      -> '||x_from);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_mail   -> '||x_to_mail);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_subject   -> '||x_subject);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_message   -> '||x_message);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_dir    -> '||x_data_err_dir);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_file_name -> '||x_file_name);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');

        IF x_to_mail IS NOT NULL THEN
           BEGIN
             xx_intg_mail_util_pkg.send_mail_attach( p_from_name        => x_from
                                                    ,p_to_name          => x_to_mail
                                                    ,p_cc_name          => x_cc_name
                                                    ,p_bc_name          => x_bcc_name
                                                    ,p_subject          => x_subject
                                                    ,p_message          => x_message
                                                    ,p_oracle_directory => x_data_err_dir
                                                    ,p_binary_file      => x_file_name);
           EXCEPTION
              WHEN OTHERS THEN
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
              x_return_code := xx_emf_cn_pkg.cn_rec_warn;
              x_error_msg   := 'Error in mailing error file';
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,x_error_msg);
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
           END;
        END IF;
     END IF;
  EXCEPTION
     WHEN OTHERS THEN
      x_error_msg   := 'Procedure - write_err_file ->' || SQLERRM;
      x_return_code := xx_emf_cn_pkg.cn_prc_err;
  END write_err_file;

  ----------------------------------------------------------------------

PROCEDURE write_LRN_Field_Changes_file( p_file_name    IN   VARCHAR2
                           ,p_email_flag   IN   VARCHAR2
                           ,x_return_code  OUT  NUMBER
                           ,x_error_msg    OUT  VARCHAR2)
  IS
     x_file_lrn_type   UTL_FILE.file_type;
     x_data_lrn_dir    VARCHAR2(80);
     x_lrn_data        VARCHAR2(4000);
     x_field_chg_data_head   VARCHAR2(4000);  -- added for header
    CURSOR c_lrn_file
    IS
      SELECT  *
        FROM  xx_hr_lrn_int
       WHERE  record_type=1
        AND  request_id = x_request_id;

CURSOR c_filed_changed_file ( p_person_id NUMBER
                             ,p_employee_number VARCHAR2
                             ,p_user_id NUMBER)
IS
 SELECT distinct job_id,org_id,position_id,manage_others,manages_people_working_in_ca,user_name username,job_name,org_name,position_name,person_id
 from xx_hr_lrn_int
 where request_id =NVL(x_max_request_id,x_request_id)
 AND person_id=p_person_id
 AND user_id=p_user_id
 AND record_type=1
 AND employee_number = p_employee_number;

-- Added for LRN Enhancements CC008949
CURSOR c_lrn_file_user
    IS
      SELECT  user_name,first_name,last_name,email_address,person_id,employee_number,user_id
        FROM  xx_hr_lrn_int
       WHERE  request_id = x_request_id;

CURSOR c_changed_user ( p_person_id NUMBER
                             ,p_employee_number VARCHAR2
                             ,p_user_id NUMBER)
IS
 SELECT distinct user_name
 from xx_hr_lrn_int
 where request_id =NVL(x_max_request_id,x_request_id)
 AND person_id=p_person_id
 AND user_id=p_user_id
 AND record_type=1
 AND employee_number = p_employee_number;

-- Additions for LRN Enhancements CC008949 ends here

CURSOR   c_mail
    IS
     SELECT  description
       FROM  fnd_lookup_values_vl
      WHERE  lookup_type = 'INTG_LRN_INTERFACE_RECIPIENTS'
        AND  NVL(enabled_flag,'X')='Y'
        AND  LOOKUP_CODE=3
        AND  SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE);

     x_err_out         VARCHAR2(4000);
     x_file_name       VARCHAR2(1000) :=p_file_name;
     x_to_mail         VARCHAR2(1000);
     x_subject         VARCHAR2(60);
     x_message         VARCHAR2(60);
     x_from            VARCHAR2(60);
     x_bcc_name        VARCHAR2(60);
     x_cc_name         VARCHAR2(60);


  BEGIN
     IF x_max_request_id IS NOT NULL THEN
     xx_intg_common_pkg.get_process_param_value( p_process_name => 'XXHRLRNINT'
                                                ,p_param_name   => 'DATA_DIR'
                                                ,x_param_value  =>  x_data_lrn_dir);

     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'file name-> '||p_file_name);

     -- opening the file
     BEGIN
         x_file_lrn_type := UTL_FILE.fopen_nchar (x_data_lrn_dir, p_file_name, 'W', 6400);
     EXCEPTION
         WHEN UTL_FILE.invalid_path THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'Invalid Path for File :' || p_file_name;
         WHEN UTL_FILE.invalid_filehandle THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  :=  'File handle is invalid for File :' || p_file_name;
         WHEN UTL_FILE.write_error THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'Unable to write the File :' || p_file_name;
         WHEN UTL_FILE.invalid_operation THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'File could not be opened for writting:' || p_file_name;
         WHEN UTL_FILE.invalid_maxlinesize THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg  := 'File ' || p_file_name;
         WHEN UTL_FILE.access_denied THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg  := 'Access denied for File :' || p_file_name;
         WHEN OTHERS THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg   := 'File '||p_file_name ||'->'|| SQLERRM;
      END;

-- Adding Header Informaion
     x_field_chg_data_head := 'User Name'||','||'First Name'||','||'Last Name'||','||'Email Address'||','||'Field Which Changed'||','||
     'Previously Sent Value'||','||'New Sent Value';

     UTL_FILE.PUT_LINE_NCHAR(x_file_lrn_type,x_field_chg_data_head);


   FOR file_rec IN c_lrn_file LOOP
     FOR c_filed_changed_file_rec IN c_filed_changed_file(file_rec.person_id
                                                         ,file_rec.employee_number
                                                         ,file_rec.user_id
                                                         ) LOOP
       IF c_filed_changed_file_rec.job_id!=file_rec.job_id THEN
       x_lrn_data := NULL;
       x_lrn_data := '"'||file_rec.user_name||'"'||','||'"'||file_rec.first_name||'"'||','||'"'||file_rec.last_name||'"'||','||'"'||file_rec.email_address||'"'||','||'"'||'job_name'||'"'||','||'"'||
                     c_filed_changed_file_rec.job_name||'"'||','||'"'||file_rec.job_name||'"';
       UTL_FILE.PUT_LINE_NCHAR(x_file_lrn_type,x_lrn_data);
       END IF;

       IF c_filed_changed_file_rec.org_id!=file_rec.org_id THEN
       x_lrn_data := NULL;
       x_lrn_data := '"'||file_rec.user_name||'"'||','||'"'||file_rec.first_name||'"'||','||'"'||file_rec.last_name||'"'||','||'"'||file_rec.email_address||'"'||','||'"'||'org_name'||'"'||','||'"'||
                     c_filed_changed_file_rec.org_name||'"'||','||'"'||file_rec.org_name||'"';
       UTL_FILE.PUT_LINE_NCHAR(x_file_lrn_type,x_lrn_data);
       END IF;

       IF c_filed_changed_file_rec.position_id!=file_rec.position_id THEN
       x_lrn_data := NULL;
       x_lrn_data := '"'||file_rec.user_name||'"'||','||'"'||file_rec.first_name||'"'||','||'"'||file_rec.last_name||'"'||','||'"'||file_rec.email_address||'"'||','||'"'||'position_name'||'"'||','||'"'||
                     c_filed_changed_file_rec.position_name||'"'||','||'"'||file_rec.position_name||'"';
       UTL_FILE.PUT_LINE_NCHAR(x_file_lrn_type,x_lrn_data);
       END IF;

      IF c_filed_changed_file_rec.manage_others!=file_rec.manage_others THEN
       x_lrn_data := NULL;
       x_lrn_data := '"'||file_rec.user_name||'"'||','||'"'||file_rec.first_name||'"'||','||'"'||file_rec.last_name||'"'||','||'"'||file_rec.email_address||'"'||','||'"'||'manage_others'||'"'||','||'"'||
                     c_filed_changed_file_rec.manage_others||'"'||','||'"'||file_rec.manage_others||'"';
       UTL_FILE.PUT_LINE_NCHAR(x_file_lrn_type,x_lrn_data);
       END IF;
      IF c_filed_changed_file_rec.manages_people_working_in_ca!=file_rec.manages_people_working_in_ca THEN
       x_lrn_data := NULL;
       x_lrn_data := '"'||file_rec.user_name||'"'||','||'"'||file_rec.first_name||'"'||','||'"'||file_rec.last_name||'"'||','||'"'||file_rec.email_address||'"'||','||'"'||'manages_people_working_in_ca'||'"'||','||'"'||
                     c_filed_changed_file_rec.manages_people_working_in_ca||'"'||','||'"'||file_rec.manages_people_working_in_ca||'"';
       UTL_FILE.PUT_LINE_NCHAR(x_file_lrn_type,x_lrn_data);
       END IF;

       IF c_filed_changed_file_rec.username!=file_rec.user_name THEN
       x_lrn_data := NULL;
       x_lrn_data := '"'||file_rec.user_name||'"'||','||'"'||file_rec.first_name||'"'||','||'"'||file_rec.last_name||'"'||','||'"'||file_rec.email_address||'"'||','||'"'||'user_name'||'"'||','||'"'||
                     c_filed_changed_file_rec.username||'"'||','||'"'||file_rec.user_name||'"';
       UTL_FILE.PUT_LINE_NCHAR(x_file_lrn_type,x_lrn_data);
       END IF;
     END LOOP;
   END LOOP;
   -- Added for LRN Enhancements CC008949

   FOR rec_lrn_file_user in c_lrn_file_user
   LOOP
        FOR rec_changed_user IN c_changed_user(rec_lrn_file_user.person_id
                                               ,rec_lrn_file_user.employee_number
                                               ,rec_lrn_file_user.user_id
                                              )
        LOOP
             IF trim(rec_changed_user.user_name)!=trim(rec_lrn_file_user.user_name) THEN
                x_lrn_data := NULL;
                x_lrn_data := '"'||rec_lrn_file_user.user_name||'"'||','||'"'||rec_lrn_file_user.first_name||'"'||','||'"'||rec_lrn_file_user.last_name||'"'||','||'"'||rec_lrn_file_user.email_address||'"'||','||'"'||'user_name'||'"'||','||'"'||
                     rec_changed_user.user_name||'"'||','||'"'||rec_lrn_file_user.user_name||'"';
                UTL_FILE.PUT_LINE_NCHAR(x_file_lrn_type,x_lrn_data);
             END IF;
        END LOOP;
    END LOOP;
   -- Additions for LRN Enhancements CC008949 end here

     IF UTL_FILE.IS_OPEN(x_file_lrn_type) THEN
        UTL_FILE.FCLOSE (x_file_lrn_type);
     END IF;
     IF NVL(p_email_flag,'X') = 'Y' THEN
        /*
        xx_intg_common_pkg.get_process_param_value( p_process_name => 'XXHRLRNINT'
                                                   ,p_param_name   => 'SUBJECT'
                                                   ,x_param_value  =>  x_subject);
        */
        x_subject:='LRN Field Changes File';
        xx_intg_common_pkg.get_process_param_value( p_process_name => 'XXHRLRNINT'
                                                   ,p_param_name   => 'MESSAGE'
                                                   ,x_param_value  =>  x_message);

        xx_intg_common_pkg.get_process_param_value( p_process_name => 'XXHRLRNINT'
                                                   ,p_param_name   => 'FROM_EMAIL_ID'
                                                   ,x_param_value  =>  x_from);

        FOR mail_rec IN c_mail LOOP
           x_to_mail := x_to_mail ||mail_rec.description;
        END LOOP;
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------  LRN Field Changes File Mailing   ------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_from      -> '||x_from);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_mail   -> '||x_to_mail);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_subject   -> '||x_subject);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_message   -> '||x_message);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_dir    -> '||x_data_lrn_dir);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_file_name -> '||x_file_name);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');

        IF x_to_mail IS NOT NULL THEN
           BEGIN
             xx_intg_mail_util_pkg.send_mail_attach( p_from_name        => x_from
                                                    ,p_to_name          => x_to_mail
                                                    ,p_cc_name          => x_cc_name
                                                    ,p_bc_name          => x_bcc_name
                                                    ,p_subject          => x_subject
                                                    ,p_message          => x_message
                                                    ,p_oracle_directory => x_data_lrn_dir
                                                    ,p_binary_file      => x_file_name);
           EXCEPTION
              WHEN OTHERS THEN
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
              x_return_code := xx_emf_cn_pkg.cn_rec_warn;
              x_error_msg   := 'Error in mailing error file';
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,x_error_msg);
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
           END;
        END IF;
     END IF;
  END IF;
  EXCEPTION
     WHEN OTHERS THEN
      x_error_msg   := 'Procedure - write_LRN_Field_Changes_file ->' || SQLERRM;
      x_return_code := xx_emf_cn_pkg.cn_prc_err;
  END write_LRN_Field_Changes_file;
  -----------------------------------------------------------------------
PROCEDURE write_manages_ca_file( p_file_name    IN   VARCHAR2
                           ,p_email_flag   IN   VARCHAR2
                           ,x_return_code  OUT  NUMBER
                           ,x_error_msg    OUT  VARCHAR2)
  IS
    CURSOR c_lrn_file
    IS
      SELECT  *
        FROM  xx_hr_lrn_int
       WHERE  record_type=1
         AND Manages_people_working_in_CA='Y'
         AND  request_id = x_request_id;

     x_file_lrn_type   UTL_FILE.file_type;
     x_data_lrn_dir    VARCHAR2(80);
     x_lrn_data        VARCHAR2(4000);

   CURSOR   c_mail
    IS
     SELECT  description
       FROM  fnd_lookup_values_vl
      WHERE  lookup_type = 'INTG_LRN_INTERFACE_RECIPIENTS'
        AND  NVL(enabled_flag,'X')='Y'
        AND  LOOKUP_CODE=4
        AND  SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE);

     x_err_out         VARCHAR2(4000);
     x_file_name       VARCHAR2(1000) :=p_file_name;
     x_to_mail         VARCHAR2(1000);
     x_subject         VARCHAR2(60);
     x_message         VARCHAR2(60);
     x_from            VARCHAR2(60);
     x_bcc_name        VARCHAR2(60);
     x_cc_name         VARCHAR2(60);
     x_field_ca_data_head   VARCHAR2(4000);  -- added for header
  BEGIN

     xx_intg_common_pkg.get_process_param_value( p_process_name => 'XXHRLRNINT'
                                                ,p_param_name   => 'DATA_DIR'
                                                ,x_param_value  =>  x_data_lrn_dir);

     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'file name-> '||p_file_name);

     -- opening the file
     BEGIN
         x_file_lrn_type := UTL_FILE.fopen_nchar (x_data_lrn_dir, p_file_name, 'W', 6400);
     EXCEPTION
         WHEN UTL_FILE.invalid_path THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'Invalid Path for File :' || p_file_name;
         WHEN UTL_FILE.invalid_filehandle THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  :=  'File handle is invalid for File :' || p_file_name;
         WHEN UTL_FILE.write_error THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'Unable to write the File :' || p_file_name;
         WHEN UTL_FILE.invalid_operation THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'File could not be opened for writting:' || p_file_name;
         WHEN UTL_FILE.invalid_maxlinesize THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg  := 'File ' || p_file_name;
         WHEN UTL_FILE.access_denied THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg  := 'Access denied for File :' || p_file_name;
         WHEN OTHERS THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg   := 'File '||p_file_name ||'->'|| SQLERRM;
      END;
-- Adding Header Informaion
     x_field_ca_data_head := 'User Name'||','||'First Name'||','||'Last Name'||','||'Email Address'||','||'Employee Number'||','||'Job Name'||','||
     'Position Name'||','||'Organization Name'||','||'Location Name'||','||'HR Rep Name';

     UTL_FILE.PUT_LINE_NCHAR(x_file_lrn_type,x_field_ca_data_head);


     FOR file_rec IN c_lrn_file LOOP
       x_lrn_data := NULL;
       x_lrn_data := '"'||file_rec.user_name||'"'||','||'"'||file_rec.first_name||'"'||','||'"'||file_rec.last_name||'"'||','||'"'||file_rec.email_address||'"'||','||file_rec.employee_number||','||'"'||
                     file_rec.job_name||'"'||','||'"'||file_rec.position_name||'"'||','||'"'||file_rec.org_name||'"'||','||'"'||file_rec.location_code||'"'||','||'"'||
                     file_rec.hr_rep_name||'"';
       UTL_FILE.PUT_LINE_NCHAR(x_file_lrn_type,x_lrn_data);
     END LOOP;

     IF UTL_FILE.IS_OPEN(x_file_lrn_type) THEN
        UTL_FILE.FCLOSE (x_file_lrn_type);
     END IF;
     IF NVL(p_email_flag,'X') = 'Y' THEN
/*
        xx_intg_common_pkg.get_process_param_value( p_process_name => 'XXHRLRNINT'
                                                   ,p_param_name   => 'SUBJECT'
                                                   ,x_param_value  =>  x_subject);
*/
      x_subject:='LRN Manages People Working in California File';
        xx_intg_common_pkg.get_process_param_value( p_process_name => 'XXHRLRNINT'
                                                   ,p_param_name   => 'MESSAGE'
                                                   ,x_param_value  =>  x_message);

        xx_intg_common_pkg.get_process_param_value( p_process_name => 'XXHRLRNINT'
                                                   ,p_param_name   => 'FROM_EMAIL_ID'
                                                   ,x_param_value  =>  x_from);


        FOR mail_rec IN c_mail LOOP
           x_to_mail := x_to_mail ||mail_rec.description;
        END LOOP;
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'------------------- LRN Manages CA File Mailing   ------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_from      -> '||x_from);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_mail   -> '||x_to_mail);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_subject   -> '||x_subject);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_message   -> '||x_message);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_dir    -> '||x_data_lrn_dir);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_file_name -> '||x_file_name);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');

        IF x_to_mail IS NOT NULL THEN
           BEGIN
             xx_intg_mail_util_pkg.send_mail_attach( p_from_name        => x_from
                                                    ,p_to_name          => x_to_mail
                                                    ,p_cc_name          => x_cc_name
                                                    ,p_bc_name          => x_bcc_name
                                                    ,p_subject          => x_subject
                                                    ,p_message          => x_message
                                                    ,p_oracle_directory => x_data_lrn_dir
                                                    ,p_binary_file      => x_file_name);
           EXCEPTION
              WHEN OTHERS THEN
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
              x_return_code := xx_emf_cn_pkg.cn_rec_warn;
              x_error_msg   := 'Error in mailing error file';
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,x_error_msg);
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
           END;
        END IF;
     END IF;
  EXCEPTION
     WHEN OTHERS THEN
      x_error_msg   := 'Procedure - write_manages_ca_file ->' || SQLERRM;
      x_return_code := xx_emf_cn_pkg.cn_prc_err;
  END write_manages_ca_file;

  ----------------------------------------------------------------------

  PROCEDURE main ( p_errbuf            OUT   VARCHAR2
                  ,p_retcode           OUT   VARCHAR2
                  ,p_email_flag        IN    VARCHAR2)

  IS

    CURSOR c_emp
    IS
SELECT
distinct
usr.user_id
            ,usr.user_name
            ,'welcome2' password
            ,usr.end_date
            ,papf.person_id
            ,papf.first_name
            ,papf.middle_names
            ,papf.last_name
            ,papf.email_address
            ,NVL(papf.employee_number,papf.npw_number) employee_number
            ,paaf.job_id
            ,pj.name job
            ,pjd.segment2 job_title
            ,pos.position_id
            ,pos.name position_name
            ,paaf.organization_id org_id
            ,haou.name org_name
            ,paaf.location_id
            ,loc.location_code
            ,papf.effective_start_date
            ,papf.effective_end_date
            ,paaf.employment_category employment_cat --,hlp.meaning employment_cat
            ,paaf.assignment_status_type_id assign_status_id
            ,ast.user_status assign_status
             ,(SELECT distinct person_id
                FROM per_all_people_f
               WHERE person_id = paaf.supervisor_id
                 AND trunc(SYSDATE) BETWEEN effective_start_date AND effective_end_date
                /* AND current_employee_flag     = 'Y'*/) supervisor_id -- Commented by Shekhar
                 ,(SELECT distinct full_name
                FROM per_all_people_f
               WHERE person_id = paaf.supervisor_id
                 AND trunc(SYSDATE) BETWEEN effective_start_date AND effective_end_date) supervisor_name
            ,(SELECT distinct email_address
                FROM per_all_people_f
               WHERE person_id = paaf.supervisor_id
                 AND trunc(SYSDATE) BETWEEN effective_start_date AND effective_end_date) supervisor_email_address
            ,(SELECT distinct papf2.person_id
                FROM per_all_people_f papf2,
                     per_all_assignments_f paaf1,
                     hr_all_positions_f pp1
               WHERE papf2.person_id = paaf1.person_id
                 AND paaf1.position_id = pp1.position_id(+)
                 AND trunc(SYSDATE) BETWEEN papf2.effective_start_date AND papf2.effective_end_date --trunc function in hr_rep , supervisor inner query against CC-015173
                 AND trunc(SYSDATE) BETWEEN paaf1.effective_start_date AND paaf1.effective_end_date
                 AND trunc(SYSDATE) BETWEEN pp1.effective_start_date AND pp1.effective_end_date
                 AND pp1.position_id = pp.attribute5
                 AND paaf1.assignment_type IN ('E','C')
                 AND paaf1.primary_flag    = 'Y') hr_rep_id
                  ,(SELECT distinct papf2.full_name
                 FROM per_all_people_f papf2,
                      per_all_assignments_f paaf1,
                      hr_all_positions_f pp1
                WHERE papf2.person_id = paaf1.person_id
                  AND paaf1.position_id = pp1.position_id(+)
                  AND trunc(SYSDATE) BETWEEN papf2.effective_start_date AND papf2.effective_end_date
                  AND trunc(SYSDATE) BETWEEN paaf1.effective_start_date AND paaf1.effective_end_date
                  AND trunc(SYSDATE) BETWEEN pp1.effective_start_date AND pp1.effective_end_date
                  AND pp1.position_id = pp.attribute5
                  AND paaf1.assignment_type IN ('E','C')
                  AND paaf1.primary_flag    = 'Y') hr_rep_name
                  ,'a' active
                  ,TRUNC(ppos.actual_termination_date) termination_date
                  ,pa.primary_flag
                  ,pa.style
                  ,pa.region_2
                  ,ppt.user_person_type user_person_type
                  ,papf.person_type_id
                  ,paaf.work_at_home work_at_home
FROM  per_all_people_f papf
            ,per_all_assignments_f paaf
            ,per_jobs pj
            ,per_job_definitions pjd
            ,fnd_user usr
            ,hr_locations loc
            ,hr_all_positions_f pp
            ,hr_all_organization_units haou
            ,per_person_type_usages_f pptuf
            ,per_person_types ppt
            --,hr_lookups hlp
            ,per_assignment_status_types_tl ast
            ,per_all_positions pos
            ,per_periods_of_service ppos
            ,PER_ADDRESSES pa
WHERE
papf.person_id = paaf.person_id
AND NVL(UPPER(papf.attribute5),'YES')!='NO'
AND  paaf.job_id = pj.job_id(+)
AND papf.person_id = usr.employee_id(+)
--AND paaf.primary_flag = 'Y'
AND paaf.location_id = loc.location_id(+)
AND paaf.position_id = pp.position_id(+)
AND pj.job_definition_id = pjd.job_definition_id(+)
AND haou.organization_id = paaf.organization_id
AND TRUNC (sysdate) BETWEEN papf.effective_start_date AND papf.effective_end_date
AND TRUNC (sysdate) BETWEEN paaf.effective_start_date AND paaf.effective_end_date
AND TRUNC (sysdate) BETWEEN pp.effective_start_date(+) AND pp.effective_end_date(+)
AND papf.person_id = pptuf.person_id
AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date AND pptuf.effective_end_date
AND ppt.person_type_id = pptuf.person_type_id
AND ppt.active_flag='Y'
AND paaf.assignment_status_type_id = ast.assignment_status_type_id
AND ast.language = USERENV ('LANG')
AND paaf.position_id = pos.position_id(+)
AND NVL(papf.attribute5,'X') <> 'N'
AND paaf.primary_flag(+) = 'Y'
AND  papf.person_id =ppos.person_id
AND ( TRUNC(ppos.actual_termination_date) >= TRUNC(sysdate) or
           TRUNC(ppos.actual_termination_date) is null
/*or TRUNC(ppos.actual_termination_date) < TRUNC(sysdate)*/
           )
AND ppos.period_of_service_id = (select max(pps.period_of_service_id) FROM per_periods_of_service pps
                                 WHERE person_id =papf.person_id AND pps.date_start <= trunc(sysdate))
and papf.person_id not in (select distinct person_id from xx_hr_lrn_int
               WHERE active_flag='D'
               AND record_type =1
               AND termination_date = nvl(ppos.actual_termination_date,to_date('31-DEC-4712','DD-MON-YYYY'))
               ) -- Added by Shekhar
AND papf.person_id =pa.person_id (+)
AND pa.primary_flag(+)='Y'
AND TRUNC (SYSDATE) BETWEEN NVL(TRUNC(pa.date_from),TRUNC(SYSDATE)) and NVL(TRUNC(pa.date_to),TRUNC(SYSDATE))
AND ppt.user_person_type  NOT IN ('Ex-contingent Worker')  -- Added by Shekhar
AND  TRUNC(SYSDATE) between pa.date_from and nvl(pa.date_to,trunc(sysdate)+1)   -- Added by Vighnesh to pick only active addresses
UNION
SELECT
distinct
            usr.user_id
            ,usr.user_name
            ,'welcome2' password
            ,usr.end_date
            ,papf.person_id
            ,papf.first_name
            ,papf.middle_names
            ,papf.last_name
            ,papf.email_address
            ,NVL(papf.employee_number,papf.npw_number) employee_number
            ,paaf.job_id
            ,pj.name job
            ,pjd.segment2 job_title
            ,pos.position_id
            ,pos.name position_name
            ,paaf.organization_id org_id
            ,haou.name org_name
            ,paaf.location_id
            ,loc.location_code
            ,papf.effective_start_date
            ,papf.effective_end_date
            ,paaf.employment_category employment_cat --,hlp.meaning employment_cat
            ,paaf.assignment_status_type_id assign_status_id
            ,ast.user_status assign_status
             ,(SELECT distinct person_id
                FROM per_all_people_f
               WHERE person_id = paaf.supervisor_id
                 AND trunc(SYSDATE) BETWEEN effective_start_date AND effective_end_date
                ) supervisor_id
                 ,(SELECT distinct full_name
                FROM per_all_people_f
               WHERE person_id = paaf.supervisor_id
                 AND trunc(SYSDATE) BETWEEN effective_start_date AND effective_end_date
                ) supervisor_name
            ,(SELECT distinct email_address
                FROM per_all_people_f
               WHERE person_id = paaf.supervisor_id
                 AND trunc(SYSDATE) BETWEEN effective_start_date AND effective_end_date
               ) supervisor_email_address
            ,(SELECT distinct papf2.person_id
                FROM per_all_people_f papf2,
                     per_all_assignments_f paaf1,
                     hr_all_positions_f pp1
               WHERE papf2.person_id = paaf1.person_id
                 AND paaf1.position_id = pp1.position_id(+)
                 AND trunc(SYSDATE) BETWEEN papf2.effective_start_date AND papf2.effective_end_date
                 AND trunc(SYSDATE) BETWEEN paaf1.effective_start_date AND paaf1.effective_end_date
                 AND trunc(SYSDATE) BETWEEN pp1.effective_start_date AND pp1.effective_end_date
                 AND pp1.position_id = pp.attribute5
                 AND paaf1.assignment_type IN ('E','C')
                 AND paaf1.primary_flag    = 'Y') hr_rep_id
                  ,(SELECT distinct papf2.full_name
                 FROM per_all_people_f papf2,
                      per_all_assignments_f paaf1,
                      hr_all_positions_f pp1
                WHERE papf2.person_id = paaf1.person_id
                  AND paaf1.position_id = pp1.position_id(+)
                  AND trunc(SYSDATE) BETWEEN papf2.effective_start_date AND papf2.effective_end_date
                  AND trunc(SYSDATE) BETWEEN paaf1.effective_start_date AND paaf1.effective_end_date
                  AND trunc(SYSDATE) BETWEEN pp1.effective_start_date AND pp1.effective_end_date
                  AND pp1.position_id = pp.attribute5
                  AND paaf1.assignment_type IN ('E','C')
                  AND paaf1.primary_flag    = 'Y') hr_rep_name
                  ,'a' active
                  ,TRUNC(ppp.actual_termination_date) termination_date
                  ,pa.primary_flag
                  ,pa.style
                  ,pa.region_2
                  ,ppt.user_person_type user_person_type
                  ,papf.person_type_id
                  ,paaf.work_at_home work_at_home
FROM  per_all_people_f papf
            ,per_all_assignments_f paaf
            ,per_jobs pj
            ,per_job_definitions pjd
            ,fnd_user usr
            ,hr_locations loc
            ,hr_all_positions_f pp
            ,hr_all_organization_units haou
            ,per_person_type_usages_f pptuf
            ,per_person_types ppt
            --,hr_lookups hlp
            ,per_assignment_status_types_tl ast
            ,per_all_positions pos
            ,per_periods_of_placement ppp
            ,PER_ADDRESSES pa
WHERE
papf.person_id = paaf.person_id
AND NVL(UPPER(papf.attribute5),'YES')!='NO'
AND  paaf.job_id = pj.job_id(+)
AND papf.person_id = usr.employee_id(+)
--AND paaf.primary_flag = 'Y'
AND paaf.location_id = loc.location_id(+)
AND paaf.position_id = pp.position_id(+)
AND pj.job_definition_id = pjd.job_definition_id(+)
AND haou.organization_id = paaf.organization_id
AND TRUNC (sysdate) BETWEEN papf.effective_start_date AND papf.effective_end_date
AND TRUNC (sysdate) BETWEEN paaf.effective_start_date AND paaf.effective_end_date
AND TRUNC (sysdate) BETWEEN pp.effective_start_date(+) AND pp.effective_end_date(+)
AND papf.person_id = pptuf.person_id
AND TRUNC (SYSDATE) BETWEEN TRUNC(pptuf.effective_start_date) AND TRUNC(pptuf.effective_end_date)
AND ppt.person_type_id = pptuf.person_type_id
AND ppt.active_flag='Y'
AND paaf.assignment_status_type_id = ast.assignment_status_type_id
AND ast.language = USERENV ('LANG')
AND paaf.position_id = pos.position_id(+)
AND NVL(papf.attribute5,'X') <> 'N'
AND paaf.primary_flag(+) = 'Y'
AND papf.person_id =ppp.person_id
AND ( TRUNC(ppp.actual_termination_date) >= TRUNC(sysdate) or
           TRUNC(ppp.actual_termination_date) is null
/*or TRUNC(ppp.actual_termination_date) < TRUNC(sysdate)*/
           )
and papf.person_id not in (select distinct person_id from xx_hr_lrn_int
               WHERE active_flag='D'
               AND record_type =1
               AND termination_date = nvl(ppp.actual_termination_date,to_date('31-DEC-4712','DD-MON-YYYY'))
               ) -- added by Shekhar
AND papf.person_id =pa.person_id (+)
AND pa.primary_flag(+)='Y'
AND TRUNC (SYSDATE) BETWEEN NVL(TRUNC(pa.date_from),TRUNC(SYSDATE)) and NVL(TRUNC(pa.date_to),TRUNC(SYSDATE))
AND ppp.period_of_placement_id = (select max(period_of_placement_id)
                                  from per_periods_of_placement ppop
                                  where ppop.person_id = papf.person_id
                                  and date_start <= trunc(sysdate)
                                  ) -- Added by Shekhar
AND ppt.user_person_type  NOT IN ('Ex-employee') -- Added by Shekhar
AND  TRUNC(SYSDATE) between pa.date_from and nvl(pa.date_to,trunc(sysdate)+1)   -- Added by Vighnesh to pick only active addresses
UNION
SELECT
distinct
usr.user_id
            ,usr.user_name
            ,'welcome2' password
            ,usr.end_date
            ,papf.person_id
            ,papf.first_name
            ,papf.middle_names
            ,papf.last_name
            ,papf.email_address
            ,NVL(papf.employee_number,papf.npw_number) employee_number
            ,paaf.job_id
            ,pj.name job
            ,pjd.segment2 job_title
            ,pos.position_id
            ,pos.name position_name
            ,paaf.organization_id org_id
            ,haou.name org_name
            ,paaf.location_id
            ,loc.location_code
            ,papf.effective_start_date
            ,papf.effective_end_date
            ,paaf.employment_category employment_cat --,hlp.meaning employment_cat
            ,paaf.assignment_status_type_id assign_status_id
            ,ast.user_status assign_status
             ,(SELECT distinct person_id
                FROM per_all_people_f
               WHERE person_id = paaf.supervisor_id
                 AND trunc(SYSDATE) BETWEEN effective_start_date AND effective_end_date) supervisor_id
                 ,(SELECT distinct full_name
                FROM per_all_people_f
               WHERE person_id = paaf.supervisor_id
                 AND trunc(SYSDATE) BETWEEN effective_start_date AND effective_end_date) supervisor_name
            ,(SELECT distinct email_address
                FROM per_all_people_f
               WHERE person_id = paaf.supervisor_id
                 AND trunc(SYSDATE) BETWEEN effective_start_date AND effective_end_date) supervisor_email_address
            ,(SELECT distinct papf2.person_id
                FROM per_all_people_f papf2,
                     per_all_assignments_f paaf1,
                     hr_all_positions_f pp1
               WHERE papf2.person_id = paaf1.person_id
                 AND paaf1.position_id = pp1.position_id(+)
                 AND trunc(SYSDATE) BETWEEN papf2.effective_start_date AND papf2.effective_end_date
                 AND trunc(SYSDATE) BETWEEN paaf1.effective_start_date AND paaf1.effective_end_date
                 AND trunc(SYSDATE) BETWEEN pp1.effective_start_date AND pp1.effective_end_date
                 AND pp1.position_id = pp.attribute5
                 AND paaf1.assignment_type IN ('E','C')
                 AND paaf1.primary_flag    = 'Y') hr_rep_id
                  ,(SELECT distinct papf2.full_name
                 FROM per_all_people_f papf2,
                      per_all_assignments_f paaf1,
                      hr_all_positions_f pp1
                WHERE papf2.person_id = paaf1.person_id
                  AND paaf1.position_id = pp1.position_id(+)
                  AND trunc(SYSDATE) BETWEEN papf2.effective_start_date AND papf2.effective_end_date
                  AND trunc(SYSDATE) BETWEEN paaf1.effective_start_date AND paaf1.effective_end_date
                  AND trunc(SYSDATE) BETWEEN pp1.effective_start_date AND pp1.effective_end_date
                  AND pp1.position_id = pp.attribute5
                  AND paaf1.assignment_type IN ('E','C')
                  AND paaf1.primary_flag    = 'Y') hr_rep_name
                  ,'a' active
                  ,TRUNC(ppos.actual_termination_date) termination_date
                  ,pa.primary_flag
                  ,pa.style
                  ,pa.region_2
                  ,ppt.user_person_type user_person_type
                  ,papf.person_type_id
                  ,paaf.work_at_home work_at_home
FROM  per_all_people_f papf
            ,per_all_assignments_f paaf
            ,per_jobs pj
            ,per_job_definitions pjd
            ,fnd_user usr
            ,hr_locations loc
            ,hr_all_positions_f pp
            ,hr_all_organization_units haou
            ,per_person_type_usages_f pptuf
            ,per_person_types ppt
            --,hr_lookups hlp
            ,per_assignment_status_types_tl ast
            ,per_all_positions pos
            ,per_periods_of_service ppos
            ,PER_ADDRESSES pa
WHERE
papf.person_id in (select distinct person_id from xx_hr_lrn_int
               where request_id =x_max_request_id
               AND active_flag='A'
               AND record_type =1)
AND papf.person_id = paaf.person_id
AND NVL(UPPER(papf.attribute5),'YES')!='NO'
AND  paaf.job_id = pj.job_id(+)
AND papf.person_id = usr.employee_id(+)
--AND paaf.primary_flag = 'Y'
AND paaf.location_id = loc.location_id(+)
AND paaf.position_id = pp.position_id(+)
AND pj.job_definition_id = pjd.job_definition_id(+)
AND haou.organization_id = paaf.organization_id
AND TRUNC (sysdate) BETWEEN papf.effective_start_date AND papf.effective_end_date
--AND TRUNC (sysdate) BETWEEN paaf.effective_start_date AND paaf.effective_end_date  Commented by Shekhar
AND (trunc(SYSDATE) BETWEEN paaf.effective_start_date AND paaf.effective_end_date
       OR (paaf.effective_end_date < trunc(SYSDATE)
           AND paaf.effective_end_date = (SELECT MAX(asg.effective_end_date)
                                          FROM per_all_assignments_f asg
                                          WHERE asg.assignment_id = paaf.assignment_id
                                          AND   asg.period_of_service_id = paaf.period_of_service_id
                                         )
          )
      )  -- Added by Shekhar
AND TRUNC (sysdate) BETWEEN pp.effective_start_date(+) AND pp.effective_end_date(+)
AND papf.person_id = pptuf.person_id
AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date AND pptuf.effective_end_date
AND ppt.person_type_id = pptuf.person_type_id
AND ppt.active_flag='Y'
AND paaf.assignment_status_type_id = ast.assignment_status_type_id
AND ast.language = USERENV ('LANG')
AND paaf.position_id = pos.position_id(+)
AND NVL(papf.attribute5,'X') <> 'N'
AND paaf.primary_flag(+) = 'Y'
AND  papf.person_id =ppos.person_id
AND TRUNC(ppos.actual_termination_date) < TRUNC(sysdate)
AND ppos.period_of_service_id = (select max(pps.period_of_service_id) FROM per_periods_of_service pps
                                 WHERE person_id =papf.person_id AND pps.date_start <= trunc(sysdate))
AND papf.person_id =pa.person_id (+)
AND pa.primary_flag(+)='Y'
AND TRUNC (SYSDATE) BETWEEN NVL(TRUNC(pa.date_from),TRUNC(SYSDATE)) and NVL(TRUNC(pa.date_to),TRUNC(SYSDATE))
AND ppt.user_person_type  NOT IN ('Ex-contingent Worker') -- Added by Shekhar
AND not exists (select 1
                from per_all_people_f papf1
                ,per_all_assignments_f paaf1
                ,per_person_types ppt2
                ,per_person_type_usages_f pptuf2
                where papf1.person_id = paaf1.person_id
                and papf1.person_id = papf.person_id
                and ppt2.person_type_id = pptuf2.person_type_id
                and pptuf2.person_id = papf1.person_id
                and paaf1.assignment_type in ('E','C')
                and trunc(sysdate) between papf1.effective_start_date and papf1.effective_end_date
                and trunc(sysdate) between paaf1.effective_start_date and paaf1.effective_end_date
                and trunc(sysdate) between pptuf2.effective_start_date and pptuf2.effective_end_date
                and ppt2.system_person_type in ('CWK','EMP','EMP_APL')
               )
and not exists(select 1
                from per_periods_of_placement
                where person_id = papf.person_id
                and trunc(actual_termination_date) > trunc(ppos.actual_termination_date)
                and period_of_placement_id = (select max(period_of_placement_id)
                                            from per_periods_of_placement ppopt
                                            where ppopt.person_id = papf.person_id
                                            and date_start <= trunc(sysdate)
                                            )
               )                -- Added by Shekhar
 AND  TRUNC(SYSDATE) between pa.date_from and nvl(pa.date_to,trunc(sysdate)+1)   -- Added by Vighnesh to pick only active addresses
UNION
SELECT
distinct
            usr.user_id
            ,usr.user_name
            ,'welcome2' password
            ,usr.end_date
            ,papf.person_id
            ,papf.first_name
            ,papf.middle_names
            ,papf.last_name
            ,papf.email_address
            ,NVL(papf.employee_number,papf.npw_number) employee_number
            ,paaf.job_id
            ,pj.name job
            ,pjd.segment2 job_title
            ,pos.position_id
            ,pos.name position_name
            ,paaf.organization_id org_id
            ,haou.name org_name
            ,paaf.location_id
            ,loc.location_code
            ,papf.effective_start_date
            ,papf.effective_end_date
            ,paaf.employment_category employment_cat --,hlp.meaning employment_cat
            ,paaf.assignment_status_type_id assign_status_id
            ,ast.user_status assign_status
             ,(SELECT distinct person_id
                FROM per_all_people_f
               WHERE person_id = paaf.supervisor_id
                 AND trunc(SYSDATE) BETWEEN effective_start_date AND effective_end_date
                ) supervisor_id
                 ,(SELECT distinct full_name
                FROM per_all_people_f
               WHERE person_id = paaf.supervisor_id
                 AND trunc(SYSDATE) BETWEEN effective_start_date AND effective_end_date
                ) supervisor_name
            ,(SELECT distinct email_address
                FROM per_all_people_f
               WHERE person_id = paaf.supervisor_id
                 AND trunc(SYSDATE) BETWEEN effective_start_date AND effective_end_date
               ) supervisor_email_address
            ,(SELECT distinct papf2.person_id
                FROM per_all_people_f papf2,
                     per_all_assignments_f paaf1,
                     hr_all_positions_f pp1
               WHERE papf2.person_id = paaf1.person_id
                 AND paaf1.position_id = pp1.position_id(+)
                 AND trunc(SYSDATE) BETWEEN papf2.effective_start_date AND papf2.effective_end_date
                 AND trunc(SYSDATE) BETWEEN paaf1.effective_start_date AND paaf1.effective_end_date
                 AND trunc(SYSDATE) BETWEEN pp1.effective_start_date AND pp1.effective_end_date
                 AND pp1.position_id = pp.attribute5
                 AND paaf1.assignment_type IN ('E','C')
                 AND paaf1.primary_flag    = 'Y') hr_rep_id
                  ,(SELECT distinct papf2.full_name
                 FROM per_all_people_f papf2,
                      per_all_assignments_f paaf1,
                      hr_all_positions_f pp1
                WHERE papf2.person_id = paaf1.person_id
                  AND paaf1.position_id = pp1.position_id(+)
                  AND trunc(SYSDATE) BETWEEN papf2.effective_start_date AND papf2.effective_end_date
                  AND trunc(SYSDATE) BETWEEN paaf1.effective_start_date AND paaf1.effective_end_date
                  AND trunc(SYSDATE) BETWEEN pp1.effective_start_date AND pp1.effective_end_date
                  AND pp1.position_id = pp.attribute5
                  AND paaf1.assignment_type IN ('E','C')
                  AND paaf1.primary_flag    = 'Y') hr_rep_name
                  ,'a' active
                  ,TRUNC(ppp.actual_termination_date) termination_date
                  ,pa.primary_flag
                  ,pa.style
                  ,pa.region_2
                  ,ppt.user_person_type user_person_type
                  ,papf.person_type_id
                  ,paaf.work_at_home work_at_home
FROM  per_all_people_f papf
            ,per_all_assignments_f paaf
            ,per_jobs pj
            ,per_job_definitions pjd
            ,fnd_user usr
            ,hr_locations loc
            ,hr_all_positions_f pp
            ,hr_all_organization_units haou
            ,per_person_type_usages_f pptuf
            ,per_person_types ppt
            --,hr_lookups hlp
            ,per_assignment_status_types_tl ast
            ,per_all_positions pos
            ,per_periods_of_placement ppp
            ,PER_ADDRESSES pa
WHERE
papf.person_id in (select distinct person_id from xx_hr_lrn_int
               where request_id =x_max_request_id
               AND active_flag='A'
               AND record_type =1)
AND papf.person_id = paaf.person_id
AND NVL(UPPER(papf.attribute5),'YES')!='NO'
AND  paaf.job_id = pj.job_id(+)
AND papf.person_id = usr.employee_id(+)
--AND paaf.primary_flag = 'Y'
AND paaf.location_id = loc.location_id(+)
AND paaf.position_id = pp.position_id(+)
AND pj.job_definition_id = pjd.job_definition_id(+)
AND haou.organization_id = paaf.organization_id
AND TRUNC (sysdate) BETWEEN papf.effective_start_date AND papf.effective_end_date
--AND TRUNC (sysdate) BETWEEN paaf.effective_start_date AND paaf.effective_end_date  Commented by Shekhar
AND (trunc(SYSDATE) BETWEEN paaf.effective_start_date AND paaf.effective_end_date
       OR (paaf.effective_end_date < trunc(SYSDATE)
           AND paaf.effective_end_date = (SELECT MAX(asg.effective_end_date)
                                          FROM per_all_assignments_f asg
                                          WHERE asg.assignment_id = paaf.assignment_id
                                         )
          )
      )  -- Added by Shekhar
AND TRUNC (sysdate) BETWEEN pp.effective_start_date(+) AND pp.effective_end_date(+)
AND papf.person_id = pptuf.person_id
AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date AND pptuf.effective_end_date
AND ppt.person_type_id = pptuf.person_type_id
AND ppt.active_flag='Y'
AND paaf.assignment_status_type_id = ast.assignment_status_type_id
AND ast.language = USERENV ('LANG')
AND paaf.position_id = pos.position_id(+)
AND NVL(papf.attribute5,'X') <> 'N'
AND paaf.primary_flag(+) = 'Y'
AND papf.person_id =ppp.person_id
AND TRUNC(ppp.actual_termination_date) < TRUNC(sysdate)
AND papf.person_id =pa.person_id (+)
AND pa.primary_flag(+)='Y'
AND TRUNC (SYSDATE) BETWEEN NVL(TRUNC(pa.date_from),TRUNC(SYSDATE)) and NVL(TRUNC(pa.date_to),TRUNC(SYSDATE))
AND ppp.period_of_placement_id = (select max(period_of_placement_id)
                                  from per_periods_of_placement ppop
                                  where ppop.person_id = papf.person_id
                                  and date_start <= trunc(sysdate)
                                  ) -- Added by Shekhar
AND ppt.user_person_type  NOT IN ('Ex-employee','Employee') -- Added by Shekhar
AND not exists (select 1
                from per_all_people_f papf1
                ,per_all_assignments_f paaf1
                ,per_person_types ppt2
                ,per_person_type_usages_f pptuf2
                where papf1.person_id = paaf1.person_id
                and papf1.person_id = papf.person_id
                and ppt2.person_type_id = pptuf2.person_type_id
                and pptuf2.person_id = papf1.person_id
                and paaf1.assignment_type in ('E','C')
                and trunc(sysdate) between papf1.effective_start_date and papf1.effective_end_date
                and trunc(sysdate) between paaf1.effective_start_date and paaf1.effective_end_date
                and trunc(sysdate) between pptuf2.effective_start_date and pptuf2.effective_end_date
                and ppt2.system_person_type in ('EMP','EMP_APL')
               )
AND  TRUNC(SYSDATE) between pa.date_from and nvl(pa.date_to,trunc(sysdate)+1)   -- Added by Vighnesh to pick only active addresses
and not exists(select 1
                from per_periods_of_service
                where person_id = papf.person_id
                and trunc(actual_termination_date) > trunc(ppp.actual_termination_date)
                and period_of_service_id = (select max(period_of_service_id)
                                            from per_periods_of_service ppost
                                            where ppost.person_id = papf.person_id
                                            and date_start <= trunc(sysdate)
                                            )
               );  -- added by Shekhar

      x_record_id          NUMBER;
      x_recent_hire_date   DATE;
      x_manage_others      VARCHAR2(1);
      x_rehire             VARCHAR2(1);
      x_recent_term_date   DATE;
      x_error_code         NUMBER;
      x_error_message      VARCHAR2(4000);
      x_ret_code           NUMBER :=0;
      x_err_msg            VARCHAR2(3000);
      x_manage_count       NUMBER;
      x_rehire_count       NUMBER;
      x_efile_error        EXCEPTION;
      x_lrn_error          EXCEPTION;
      x_date_from          VARCHAR2(20);
      x_file_name          VARCHAR2(300);
      x_file_prefix        VARCHAR2(20);
      x_record_type        NUMBER;
      x_employment_cat     VARCHAR2(80);
      x_supervisor_term_date  DATE;
      x_supervisor_name    VARCHAR2(240);
      x_supervisor_email_address VARCHAR2(240);
      x_ative_flag         VARCHAR2(1);
      x_manages_wk_loc_usca_count NUMBER;
      x_manages_ca_count  NUMBER;
      x_manages_ca_flag   VARCHAR2(1);
      x_manages_ca_loc_count NUMBER;
      x_insert_count       NUMBER;
      x_manages_wkathome_count NUMBER;
      x_term_count  NUMBER;
      x_user_count NUMBER;
      x_excep_count NUMBER;
      l_username VARCHAR2(100);
  BEGIN
     BEGIN
       SELECT MAX(request_id) INTO x_max_request_id FROM xx_hr_lrn_int;
     EXCEPTION
     WHEN OTHERS THEN
     x_max_request_id:=NULL;
     END;
     x_error_code := xx_emf_pkg.set_env;
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Set EMF Env x_error_code: '||x_error_code);
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------  Parameters -----------------------');
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'p_email_flag   ->'||p_email_flag);
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'x_max_request_id   ->'||x_max_request_id);
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');

     x_date_from := TO_CHAR(TRUNC(TO_DATE(SYSDATE,'YYYY-MM-DD HH24:MI:SS')),'DD-MON-YYYY');

     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'x_date_from      ->'|| x_date_from);

     FOR emp_rec IN c_emp
     LOOP
       x_record_type      :=1;
       x_recent_hire_date := NULL;
       x_manage_others    := NULL;
       x_rehire           := NULL;
       x_recent_term_date := NULL;
       x_error_code       := NULL;
       x_error_message    := NULL;

       BEGIN
         SELECT date_start
           INTO x_recent_hire_date
           FROM per_periods_of_service
          WHERE person_id = emp_rec.person_id
            AND period_of_service_id = (SELECT MAX(p.period_of_service_id)
                                          FROM per_periods_of_service p
                                         WHERE p.person_id = emp_rec.person_id
                                         and date_start <= trunc(sysdate)); -- last condition added by shekhar
       EXCEPTION WHEN OTHERS THEN
         x_recent_hire_date := NULL;
       END;
       IF x_recent_hire_date IS NULL THEN
       BEGIN
         SELECT max(date_start)
           INTO x_recent_hire_date
           FROM PER_PERIODS_OF_PLACEMENT
          WHERE person_id = emp_rec.person_id
          and date_start <= trunc(sysdate); -- last condition added by shekhar
       EXCEPTION WHEN OTHERS THEN
         x_recent_hire_date := NULL;
       END;
       END IF;

       x_manage_count := 0;
       SELECT  COUNT(*)
         INTO  x_manage_count
         FROM  per_all_assignments_f
        WHERE  supervisor_id  = emp_rec.person_id
          AND  TRUNC(SYSDATE) BETWEEN NVL(effective_start_date,TRUNC(SYSDATE)) AND NVL(effective_end_date,TRUNC(SYSDATE))
          AND assignment_type in ('E','C');

       IF NVL(x_manage_count,0) > 0 THEN
          x_manage_others := 'Y';
       ELSE
          x_manage_others := 'N';
       END IF;

       IF x_manage_others = 'Y' THEN -- Manages CA starts

       x_manages_wk_loc_usca_count:=0;
       BEGIN
         SELECT  COUNT(*)
         INTO x_manages_wk_loc_usca_count
         FROM  per_all_assignments_f paaf,
               hr_locations loc
         WHERE  paaf.supervisor_id  = emp_rec.person_id
         AND    TRUNC(SYSDATE) BETWEEN NVL(paaf.effective_start_date,TRUNC(SYSDATE)) AND NVL(paaf.effective_end_date,TRUNC(SYSDATE))
         AND   loc.location_id=paaf.location_id
                  AND  paaf.assignment_type in ('E','C') -- Added for ticket #014067
         --AND UPPER(loc.location_code) like UPPER('US%CA%');
         AND   UPPER(loc.region_2) = 'CA';
       EXCEPTION
       WHEN OTHERS THEN
       x_manages_wk_loc_usca_count:=0;
       END;

       x_manages_ca_count:=0;
       BEGIN
         SELECT  COUNT(*)
         INTO x_manages_ca_count
         FROM  per_all_assignments_f paaf,
               PER_ADDRESSES pa
        WHERE  paaf.supervisor_id  = emp_rec.person_id
          AND  TRUNC(SYSDATE) BETWEEN NVL(paaf.effective_start_date,TRUNC(SYSDATE)) AND NVL(paaf.effective_end_date,TRUNC(SYSDATE))
          AND paaf.person_id =pa.person_id
          AND  TRUNC(SYSDATE) between pa.date_from and nvl(pa.date_to,trunc(sysdate)+1)   -- Added by Vighnesh to pick only active addresses
          AND  paaf.assignment_type in ('E','C') -- Added for ticket #014067
          and pa.style='US'
          and pa.region_2='CA'
          AND pa.primary_flag='Y';
       EXCEPTION
       WHEN OTHERS THEN
       x_manages_ca_count:=0;
       END;

       x_manages_ca_loc_count:=0;
       BEGIN
         SELECT  COUNT(*)
         INTO x_manages_ca_loc_count
         FROM  per_all_assignments_f paaf,
               hr_locations loc
         WHERE  paaf.supervisor_id  = emp_rec.person_id
         AND    TRUNC(SYSDATE) BETWEEN NVL(paaf.effective_start_date,TRUNC(SYSDATE)) AND NVL(paaf.effective_end_date,TRUNC(SYSDATE))
         AND  paaf.assignment_type in ('E','C') -- Added for ticket #014067
         AND   loc.location_id=paaf.location_id
         AND UPPER(loc.location_code) like UPPER('US-xx-xx-NA-Home%Office');
       EXCEPTION
       WHEN OTHERS THEN
       x_manages_ca_loc_count:=0;
       END;

        x_manages_wkathome_count:=0;
       BEGIN
         SELECT  COUNT(*)
         INTO x_manages_wkathome_count
         FROM  per_all_assignments_f paaf
         WHERE  paaf.supervisor_id  = emp_rec.person_id
         AND  paaf.assignment_type in ('E','C') -- Added for ticket #014067
         AND    TRUNC(SYSDATE) BETWEEN NVL(paaf.effective_start_date,TRUNC(SYSDATE)) AND NVL(paaf.effective_end_date,TRUNC(SYSDATE))
         AND   UPPER(paaf.work_at_home)='Y';
       EXCEPTION
       WHEN OTHERS THEN
       x_manages_wkathome_count:=0;
       END;

         x_manages_ca_flag:='N';

         IF x_manages_wk_loc_usca_count > 0 THEN
           x_manages_ca_flag:='Y';
         ELSIF x_manages_ca_loc_count > 0 AND x_manages_ca_count > 0 THEN
           x_manages_ca_flag:='Y';
         ELSIF x_manages_wkathome_count > 0 AND x_manages_ca_count > 0 THEN
           x_manages_ca_flag:='Y';
         ELSE
          x_manages_ca_flag:='N';
         END IF;

       ELSE
          x_manages_ca_flag:='N';
       END IF; -- Manage CA ends

       x_rehire_count :=0;
       SELECT COUNT(*)
         INTO x_rehire_count
         FROM per_periods_of_service
        WHERE person_id = emp_rec.person_id;

       IF x_rehire_count > 1 THEN
          x_rehire := 'Y';
       ELSE
          x_rehire := 'N';
       END IF;

       x_recent_term_date:=NULL;
       IF x_rehire = 'Y' THEN
       BEGIN
         SELECT actual_termination_date
           INTO x_recent_term_date
           FROM per_periods_of_service
          WHERE person_id = emp_rec.person_id
            AND actual_termination_date IS NOT NULL
            AND period_of_service_id = (SELECT MAX(p.period_of_service_id)
                                          FROM per_periods_of_service p
                                         WHERE p.person_id = emp_rec.person_id
                                           AND p.actual_termination_date IS NOT NULL
                                           and date_start <= trunc(sysdate)); -- last condition added by shekhar
       EXCEPTION WHEN OTHERS THEN
         x_recent_term_date := NULL;
       END;
       ELSE
       x_recent_term_date:=NULL;
       END IF;

       --If supervisor is terminated
       x_supervisor_term_date:=NULL;
       BEGIN
         SELECT TRUNC(actual_termination_date)
           INTO x_supervisor_term_date
           FROM per_periods_of_service
          WHERE person_id = emp_rec.supervisor_id
            AND period_of_service_id = (SELECT MAX(p.period_of_service_id)
                                          FROM per_periods_of_service p
                                         WHERE p.person_id = emp_rec.supervisor_id
                                           );
       EXCEPTION WHEN OTHERS THEN
         x_supervisor_term_date := NULL;
       END;

        -- IF TRUNC(x_supervisor_term_date) <= TRUNC(SYSDATE) THEN -- commented for Ticket #013846
       IF TRUNC(x_supervisor_term_date) <= TRUNC(SYSDATE-1) THEN -- Added for Ticket #013846 to resolve supervisor name blank who terminated on the same day of report run.
          x_supervisor_name:=NULL;
          x_supervisor_email_address:=NULL;
       ELSE
          x_supervisor_name:=emp_rec.supervisor_name;
          x_supervisor_email_address:=emp_rec.supervisor_email_address;
       END IF;

       x_rehire_count :=0;
       SELECT COUNT(*)
         INTO x_rehire_count
         FROM per_periods_of_service
        WHERE person_id = emp_rec.person_id;

       IF x_rehire_count > 1 THEN
          x_rehire := 'Y';
       ELSE
          x_rehire := 'N';
       END IF;

       IF emp_rec.user_name IS NULL THEN
          x_record_type:=2;
          x_error_code := 2;
          x_error_message := x_error_message ||'-'||'User Id is Null';
       END IF;

       -- Added for LRN Enhancement CC008949
       l_username := NULL;
       BEGIN
        SELECT distinct user_name username
        INTO l_username
        from xx_hr_lrn_int
        where request_id =NVL(x_max_request_id,x_request_id)
        AND person_id=emp_rec.person_id
        AND user_id=emp_rec.user_id
        AND record_type = 1;
       EXCEPTION
         WHEN OTHERS THEN
            l_username := emp_rec.user_name;
       END;

       IF nvl(trim(replace(l_username,' ',NULL)),'XXX') <> nvl(trim(replace(emp_rec.user_name,' ',NULL)),'XXX') THEN
             x_record_type:=2;
             x_error_code := 2;
             x_error_message := x_error_message ||'-'||'User Name has been changed since last run';
       END IF;

       -- Addion for LRN Enhancement CC008949 ends here

       IF emp_rec.end_date IS NOT NULL THEN
           --IF emp_rec.end_date > x_date_from THEN  -- commented for ticket#013426 since the x_date_from is char variable and comparision wont work.
          IF trunc(emp_rec.end_date) > trunc(sysdate) THEN
             x_error_code := 2;
             x_error_message := x_error_message ||'-'||'User Id expired';
          END IF;
       END IF;
       IF emp_rec.job IS NULL THEN
          x_record_type:=2;
          x_error_code := 2;
          x_error_message := x_error_message ||'-'||'Job is Null';
       END IF;

       IF emp_rec.position_name IS NULL THEN
          x_record_type:=2;
          x_error_code := 2;
          x_error_message := x_error_message ||'-'||'Position Name is Null';
       END IF;

       IF emp_rec.org_id IS NULL THEN
          x_record_type:=2;
          x_error_code := 2;
          x_error_message := x_error_message ||'-'||'Org Id is Null';
       END IF;

       IF emp_rec.org_name IS NULL THEN
          x_record_type:=2;
          x_error_code := 2;
          x_error_message := x_error_message ||'-'||'Org Name is Null';
       END IF;

       IF emp_rec.location_id IS NULL THEN
          x_record_type:=2;
          x_error_code := 2;
          x_error_message := x_error_message ||'-'||'Location is Null';
       END IF;

       IF emp_rec.user_name like '%@%' THEN
          x_record_type:=2;
          x_error_code := 2;
          x_error_message := x_error_message ||'-'||'User name with @';
       ELSE
          x_user_count:=0;
          BEGIN
          select count(*)
          INTO   x_user_count
          from fnd_user where employee_id=emp_rec.person_id
          and user_name not like '%@%';
          EXCEPTION
          WHEN OTHERS THEN
           x_user_count:=0;
          END;
       END IF;

       BEGIN
       x_employment_cat:=NULL;
       SELECT meaning INTO x_employment_cat FROM hr_lookups
       WHERE lookup_code =emp_rec.employment_cat and lookup_type='EMP_CAT' and enabled_flag='Y'
       AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active,TRUNC(SYSDATE)) and NVL(end_date_active,TRUNC(SYSDATE));
       EXCEPTION
       WHEN OTHERS THEN
       x_employment_cat:=NULL;
       END;

       x_ative_flag:=NULL;
       x_term_count :=0;
       IF emp_rec.termination_date IS NOT NULL THEN
          IF TRUNC(emp_rec.termination_date)< TRUNC(sysdate+14)  AND TRUNC(emp_rec.termination_date)>= TRUNC(sysdate) THEN
            --x_ative_flag:='D';
           x_term_count:=0;
             BEGIN
               SELECT count(*) INTO x_term_count
               from xx_hr_lrn_int
               where request_id =x_max_request_id
               and person_id =emp_rec.person_id
               AND user_id=emp_rec.user_id
               AND active_flag='D'
               AND record_type =1;
              EXCEPTION
                when others then
                x_term_count:=0;
              END;
              IF x_term_count = 0 THEN
              x_ative_flag:='D';
              END IF;
          ELSIF TRUNC(emp_rec.termination_date)< TRUNC(sysdate) THEN
             x_term_count:=0;
             BEGIN
               SELECT count(*) INTO x_term_count
               from xx_hr_lrn_int
               where request_id =x_max_request_id
               and person_id =emp_rec.person_id
               AND user_id=emp_rec.user_id
               AND active_flag='D'
               AND record_type =1;
              EXCEPTION
                when others then
                x_term_count:=0;
              END;
              IF x_term_count =0 THEN
              x_ative_flag:='D';
              END IF;
          ELSE
            x_ative_flag:='A';
          END IF;
       ELSE
         x_ative_flag:='A';
       END IF;

       x_insert_count:=0;
       BEGIN
       SELECT  count(*)
       INTO x_insert_count
       FROM pay_user_column_instances_f pci
           ,pay_user_rows_f pur
           ,pay_user_columns_v puc
           ,pay_user_tables_v put
       WHERE pci.user_row_id = pur.user_row_id
       AND pci.user_column_id = puc.user_column_id
       AND puc.user_table_id = put.user_table_id
       AND put.user_table_name = 'INTG_LOC_PERSON_TYPE_SETUP'
       AND TRUNC (SYSDATE) BETWEEN pci.effective_start_date AND pci.effective_end_date
       AND TRUNC (SYSDATE) BETWEEN pur.effective_start_date AND pur.effective_end_date
       AND pur.row_low_range_or_name = to_char(emp_rec.location_id)
       AND UPPER(puc.user_column_name) =UPPER(emp_rec.user_person_type)
       AND UPPER(pci.VALUE)  ='YES'
       ORDER BY 1;
       EXCEPTION
       WHEN OTHERS THEN
       x_insert_count:=0;
       END;

   IF x_insert_count >=1 AND x_term_count =0 THEN

       SELECT xx_hr_lrn_int_s.NEXTVAL
         INTO x_record_id
         FROM dual;

       IF x_record_type =1 THEN

       INSERT INTO xx_hr_lrn_int
       ( record_id
        ,record_type
        ,request_id
        ,user_id
        ,user_name
        ,password
        ,person_id
        ,effective_start_date
        ,effective_end_date
        ,last_name
        ,first_name
        ,middle_names
        ,email_address
        ,employee_number
        ,job_id
        ,job_name
        ,position_id
        ,position_name
        ,org_id
        ,org_name
        ,emp_category
        ,location_id
        ,location_code
        ,recent_hire_date
        ,assign_status_id
        ,assign_status
        ,supervisor_id
        ,supervisor_name
        ,supervisor_email
        ,manage_others
        ,rehire
        ,Manages_people_working_in_CA
        ,recent_term_date
        ,hr_rep_id
        ,hr_rep_name
        ,active_flag
        ,effective_date
        ,file_name
        ,termination_date
        ,error_code
        ,error_message
        ,created_by
        ,creation_date
        ,last_update_date
        ,last_updated_by
        ,last_update_login
       ) VALUES
      ( x_record_id                      --record_id
       ,x_record_type                    --x_record_type
       ,x_request_id                     --request_id
       ,emp_rec.user_id                  --user_id
       --,REPLACE(special_char_rep(emp_rec.user_name),' ',NULL)                --user_name
       ,REPLACE(emp_rec.user_name,' ',NULL)                --user_name
       ,emp_rec.password                 --password
       ,emp_rec.person_id                --person_id
       ,emp_rec.effective_start_date     --effective_start_date
       ,emp_rec.effective_end_date       --effective_end_date
       --,special_char_rep(emp_rec.last_name)                --last_name
       ,emp_rec.last_name                --last_name
       --,special_char_rep(emp_rec.first_name)               --first_name
       ,emp_rec.first_name
       --,special_char_rep(emp_rec.middle_names)             --middle_names
       ,emp_rec.middle_names
       --,special_char_rep(emp_rec.email_address)            --email_address
       ,emp_rec.email_address
       ,emp_rec.employee_number          --employee_number
       ,emp_rec.job_id                   --job_id
       ,emp_rec.job                      --job_name
       ,emp_rec.position_id              --position_id
       ,emp_rec.position_name            --position_name
       ,emp_rec.org_id                   --org_id
       ,emp_rec.org_name                 --org_name
       ,x_employment_cat                 --emp_category
       ,emp_rec.location_id              --location_id
       ,emp_rec.location_code            --location_code
       ,x_recent_hire_date               --recent_hire_date
       ,emp_rec.assign_status_id         --assign_status_id
       ,emp_rec.assign_status            --assign_status
       ,emp_rec.supervisor_id            --supervisor_id
       --,special_char_rep(x_supervisor_name)          --supervisor_name
       ,x_supervisor_name
       --,special_char_rep(x_supervisor_email_address) --supervisor_email
       ,x_supervisor_email_address
       ,x_manage_others                  --manage_others
       ,x_rehire                         --rehire
       ,x_manages_ca_flag
       ,x_recent_term_date               --recent_term_date
       ,emp_rec.hr_rep_id                --hr_rep_id
       --,special_char_rep(emp_rec.hr_rep_name)              --hr_rep_name
       ,emp_rec.hr_rep_name
       ,x_ative_flag                   --active_flag
       ,x_date_from                      --effective_date
       ,x_file_name                      --file_name
       ,emp_rec.termination_date         --termination_date
       ,NVL(x_error_code,0)              --error_code
       ,x_error_message                  --error_message
       ,x_user_id                        --created_by
       ,SYSDATE                          --creation_date
       ,SYSDATE                          --last_update_date
       ,x_user_id                        --last_updated_by
       ,x_login_id                       --last_update_login
       );

       ELSIF x_record_type =2 THEN

       INSERT INTO xx_hr_lrn_int
       ( record_id
        ,record_type
        ,request_id
        ,user_id
        ,user_name
        ,password
        ,person_id
        ,effective_start_date
        ,effective_end_date
        ,last_name
        ,first_name
        ,middle_names
        ,email_address
        ,employee_number
        ,job_id
        ,job_name
        ,position_id
        ,position_name
        ,org_id
        ,org_name
        ,emp_category
        ,location_id
        ,location_code
        ,recent_hire_date
        ,assign_status_id
        ,assign_status
        ,supervisor_id
        ,supervisor_name
        ,supervisor_email
        ,manage_others
        ,rehire
        ,Manages_people_working_in_CA
        ,recent_term_date
        ,hr_rep_id
        ,hr_rep_name
        ,active_flag
        ,effective_date
        ,file_name
        ,termination_date
        ,error_code
        ,error_message
        ,created_by
        ,creation_date
        ,last_update_date
        ,last_updated_by
        ,last_update_login
       ) VALUES
      ( x_record_id                      --record_id
       ,x_record_type                    --x_record_type
       ,x_request_id                     --request_id
       ,emp_rec.user_id                  --user_id
       --,REPLACE(special_char_rep(emp_rec.user_name),' ',NULL)                --user_name
       ,REPLACE(emp_rec.user_name,' ',NULL)                --user_name
       ,emp_rec.password                 --password
       ,emp_rec.person_id                --person_id
       ,emp_rec.effective_start_date     --effective_start_date
       ,emp_rec.effective_end_date       --effective_end_date
       --,special_char_rep(emp_rec.last_name)                --last_name
       ,emp_rec.last_name
       --,special_char_rep(emp_rec.first_name)               --first_name
       ,emp_rec.first_name
       --,special_char_rep(emp_rec.middle_names)             --middle_names
       ,emp_rec.middle_names
       --,special_char_rep(emp_rec.email_address)            --email_address
       ,emp_rec.email_address
       ,emp_rec.employee_number          --employee_number
       ,emp_rec.job_id                   --job_id
       ,emp_rec.job                      --job_name
       ,emp_rec.position_id              --position_id
       ,emp_rec.position_name            --position_name
       ,emp_rec.org_id                   --org_id
       ,emp_rec.org_name                 --org_name
       ,x_employment_cat                 --emp_category
       ,emp_rec.location_id              --location_id
       ,emp_rec.location_code            --location_code
       ,x_recent_hire_date               --recent_hire_date
       ,emp_rec.assign_status_id         --assign_status_id
       ,emp_rec.assign_status            --assign_status
       ,emp_rec.supervisor_id            --supervisor_id
       --,special_char_rep(x_supervisor_name)          --supervisor_name
       ,x_supervisor_name
       --,special_char_rep(x_supervisor_email_address) --supervisor_email
       ,x_supervisor_email_address
       ,x_manage_others                  --manage_others
       ,x_rehire                         --rehire
       ,x_manages_ca_flag
       ,x_recent_term_date               --recent_term_date
       ,emp_rec.hr_rep_id                --hr_rep_id
       --,special_char_rep(emp_rec.hr_rep_name)              --hr_rep_name
       ,emp_rec.hr_rep_name
       ,x_ative_flag                     --active_flag
       ,x_date_from                      --effective_date
       ,x_file_name                      --file_name
       ,emp_rec.termination_date         --termination_date
       ,NVL(x_error_code,0)              --error_code
       ,x_error_message                  --error_message
       ,x_user_id                        --created_by
       ,SYSDATE                          --creation_date
       ,SYSDATE                          --last_update_date
       ,x_user_id                        --last_updated_by
       ,x_login_id                       --last_update_login
       );
       END IF;

       IF x_supervisor_name IS NULL  OR emp_rec.hr_rep_name IS NULL THEN
           x_excep_count:=0;
           BEGIN
           SELECT count(*) INTO x_excep_count
           from xx_hr_lrn_int
           where request_id =x_request_id
           AND person_id=emp_rec.person_id
           AND user_id=emp_rec.user_id
           AND record_type=2
           AND employee_number =emp_rec.employee_number;
           EXCEPTION
           WHEN OTHERS THEN
           x_excep_count:=0;
           END;
          IF x_excep_count=0 THEN
              SELECT xx_hr_lrn_int_s.NEXTVAL
              INTO x_record_id
              FROM dual;
       INSERT INTO xx_hr_lrn_int
       ( record_id
        ,record_type
        ,request_id
        ,user_id
        ,user_name
        ,password
        ,person_id
        ,effective_start_date
        ,effective_end_date
        ,last_name
        ,first_name
        ,middle_names
        ,email_address
        ,employee_number
        ,job_id
        ,job_name
        ,position_id
        ,position_name
        ,org_id
        ,org_name
        ,emp_category
        ,location_id
        ,location_code
        ,recent_hire_date
        ,assign_status_id
        ,assign_status
        ,supervisor_id
        ,supervisor_name
        ,supervisor_email
        ,manage_others
        ,rehire
        ,Manages_people_working_in_CA
        ,recent_term_date
        ,hr_rep_id
        ,hr_rep_name
        ,active_flag
        ,effective_date
        ,file_name
        ,termination_date
        ,error_code
        ,error_message
        ,created_by
        ,creation_date
        ,last_update_date
        ,last_updated_by
        ,last_update_login
       ) VALUES
      ( x_record_id                      --record_id
       ,2                                --x_record_type
       ,x_request_id                     --request_id
       ,emp_rec.user_id                  --user_id
       --,REPLACE(special_char_rep(emp_rec.user_name),' ',NULL)                --user_name
       ,REPLACE(emp_rec.user_name,' ',NULL)                --user_name
       ,emp_rec.password                 --password
       ,emp_rec.person_id                --person_id
       ,emp_rec.effective_start_date     --effective_start_date
       ,emp_rec.effective_end_date       --effective_end_date
       --,special_char_rep(emp_rec.last_name)                --last_name
       ,emp_rec.last_name
       --,special_char_rep(emp_rec.first_name)               --first_name
       ,emp_rec.first_name
       --,special_char_rep(emp_rec.middle_names)             --middle_names
       ,emp_rec.middle_names
       --,special_char_rep(emp_rec.email_address)            --email_address
       ,emp_rec.email_address
       ,emp_rec.employee_number          --employee_number
       ,emp_rec.job_id                   --job_id
       ,emp_rec.job                      --job_name
       ,emp_rec.position_id              --position_id
       ,emp_rec.position_name            --position_name
       ,emp_rec.org_id                   --org_id
       ,emp_rec.org_name                 --org_name
       ,x_employment_cat                 --emp_category
       ,emp_rec.location_id              --location_id
       ,emp_rec.location_code            --location_code
       ,x_recent_hire_date               --recent_hire_date
       ,emp_rec.assign_status_id         --assign_status_id
       ,emp_rec.assign_status            --assign_status
       ,emp_rec.supervisor_id            --supervisor_id
       --,special_char_rep(x_supervisor_name)          --supervisor_name
       ,x_supervisor_name
       --,special_char_rep(x_supervisor_email_address) --supervisor_email
       ,x_supervisor_email_address
       ,x_manage_others                  --manage_others
       ,x_rehire                         --rehire
       ,x_manages_ca_flag
       ,x_recent_term_date               --recent_term_date
       ,emp_rec.hr_rep_id                --hr_rep_id
       --,special_char_rep(emp_rec.hr_rep_name)              --hr_rep_name
       ,emp_rec.hr_rep_name
       ,x_ative_flag                     --active_flag
       ,x_date_from                      --effective_date
       ,x_file_name                      --file_name
       ,emp_rec.termination_date         --termination_date
       ,NVL(x_error_code,0)              --error_code
       ,x_error_message                  --error_message
       ,x_user_id                        --created_by
       ,SYSDATE                          --creation_date
       ,SYSDATE                          --last_update_date
       ,x_user_id                        --last_updated_by
       ,x_login_id                       --last_update_login
       );
          END IF;
       END IF;

       IF x_user_count >1 THEN
           x_error_message := x_error_message ||'-'||'Dublicate User Name';
           x_excep_count:=0;
           BEGIN
           SELECT count(*) INTO x_excep_count
           from xx_hr_lrn_int
           where request_id =x_request_id
           AND person_id=emp_rec.person_id
           AND user_id=emp_rec.user_id
           AND record_type=2
           AND employee_number =emp_rec.employee_number;
           EXCEPTION
           WHEN OTHERS THEN
           x_excep_count:=0;
           END;
        IF x_excep_count=0 THEN
         SELECT xx_hr_lrn_int_s.NEXTVAL
         INTO x_record_id
         FROM dual;

          INSERT INTO xx_hr_lrn_int
       ( record_id
        ,record_type
        ,request_id
        ,user_id
        ,user_name
        ,password
        ,person_id
        ,effective_start_date
        ,effective_end_date
        ,last_name
        ,first_name
        ,middle_names
        ,email_address
        ,employee_number
        ,job_id
        ,job_name
        ,position_id
        ,position_name
        ,org_id
        ,org_name
        ,emp_category
        ,location_id
        ,location_code
        ,recent_hire_date
        ,assign_status_id
        ,assign_status
        ,supervisor_id
        ,supervisor_name
        ,supervisor_email
        ,manage_others
        ,rehire
        ,Manages_people_working_in_CA
        ,recent_term_date
        ,hr_rep_id
        ,hr_rep_name
        ,active_flag
        ,effective_date
        ,file_name
        ,termination_date
        ,error_code
        ,error_message
        ,created_by
        ,creation_date
        ,last_update_date
        ,last_updated_by
        ,last_update_login
       ) VALUES
      ( x_record_id                      --record_id
       ,2                                --x_record_type
       ,x_request_id                     --request_id
       ,emp_rec.user_id                  --user_id
       --,REPLACE(special_char_rep(emp_rec.user_name),' ',NULL)                --user_name
       ,REPLACE(emp_rec.user_name,' ',NULL)                --user_name
       ,emp_rec.password                 --password
       ,emp_rec.person_id                --person_id
       ,emp_rec.effective_start_date     --effective_start_date
       ,emp_rec.effective_end_date       --effective_end_date
       --,special_char_rep(emp_rec.last_name)                --last_name
       ,emp_rec.last_name
       --,special_char_rep(emp_rec.first_name)               --first_name
       ,emp_rec.first_name
       --,special_char_rep(emp_rec.middle_names)             --middle_names
       ,emp_rec.middle_names
       --,special_char_rep(emp_rec.email_address)            --email_address
       ,emp_rec.email_address
       ,emp_rec.employee_number          --employee_number
       ,emp_rec.job_id                   --job_id
       ,emp_rec.job                      --job_name
       ,emp_rec.position_id              --position_id
       ,emp_rec.position_name            --position_name
       ,emp_rec.org_id                   --org_id
       ,emp_rec.org_name                 --org_name
       ,x_employment_cat                 --emp_category
       ,emp_rec.location_id              --location_id
       ,emp_rec.location_code            --location_code
       ,x_recent_hire_date               --recent_hire_date
       ,emp_rec.assign_status_id         --assign_status_id
       ,emp_rec.assign_status            --assign_status
       ,emp_rec.supervisor_id            --supervisor_id
       --,special_char_rep(x_supervisor_name)          --supervisor_name
       ,x_supervisor_name
       --,special_char_rep(x_supervisor_email_address) --supervisor_email
       ,x_supervisor_email_address
       ,x_manage_others                  --manage_others
       ,x_rehire                         --rehire
       ,x_manages_ca_flag
       ,x_recent_term_date               --recent_term_date
       ,emp_rec.hr_rep_id                --hr_rep_id
       --,special_char_rep(emp_rec.hr_rep_name)              --hr_rep_name
       ,emp_rec.hr_rep_name
       ,x_ative_flag                     --active_flag
       ,x_date_from                      --effective_date
       ,x_file_name                      --file_name
       ,emp_rec.termination_date         --termination_date
       ,NVL(x_error_code,0)              --error_code
       ,x_error_message                  --error_message
       ,x_user_id                        --created_by
       ,SYSDATE                          --creation_date
       ,SYSDATE                          --last_update_date
       ,x_user_id                        --last_updated_by
       ,x_login_id                       --last_update_login
       );
       END IF;
       END IF;
  END IF;
     COMMIT;
     END LOOP;

     /*
     xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXHRLRNINT'
                                                ,p_param_name      => 'FILE_PREFIX'
                                                ,x_param_value     =>  x_file_prefix);

     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'file prefix ->'||x_file_prefix);
*/
     /*
     IF x_file_prefix <> '-' THEN
        x_file_name := x_file_prefix||p_file_name;
     ELSE
        x_file_name := p_file_name;
     END IF;
     */

     select 'UPADM'||TO_CHAR(SYSDATE,'MMDDYY')||'.csv' INTO x_file_name from dual;
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'To write_lrn_file name ->'||x_file_name);

     x_ret_code := NULL;
     x_err_msg  := NULL;
     write_lrn_file( p_file_name    => x_file_name
                    ,p_email_flag   => p_email_flag
                    ,x_return_code  => x_ret_code
                    ,x_error_msg    => x_err_msg);

     IF NVL(x_ret_code,0) <> 0 THEN
        RAISE x_lrn_error;
     END IF;
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'write_lrn_file ->'||x_ret_code);

     select 'LRNEXCEPTION'||to_char(sysdate,'MONDDYY')||'.csv' INTO x_file_name from dual;
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'To write_err_file name ->'||x_file_name);

     x_ret_code := NULL;
     x_err_msg  := NULL;
     write_err_file( p_file_name    => x_file_name
                    ,p_email_flag   => p_email_flag
                    ,x_return_code  => x_ret_code
                    ,x_error_msg    => x_err_msg);

     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'write_err_file ->'||x_ret_code);

     IF NVL(x_ret_code,0) <> 0 THEN
        RAISE x_efile_error;
     END IF;

    select 'LRNFIELDCHANGES'||to_char(sysdate,'MONDDYY')||'.csv' INTO x_file_name from dual;
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'To write_manages_ca_file name ->'||x_file_name);

     x_ret_code := NULL;
     x_err_msg  := NULL;
     write_LRN_Field_Changes_file( p_file_name    => x_file_name
                    ,p_email_flag   => p_email_flag
                    ,x_return_code  => x_ret_code
                    ,x_error_msg    => x_err_msg);

     IF NVL(x_ret_code,0) <> 0 THEN
        RAISE x_lrn_error;
     END IF;
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'write_LRN_Field_Changes_file ->'||x_ret_code);

     select 'LRNMANAGESCA'||to_char(sysdate,'MONDDYY')||'.csv' INTO x_file_name from dual;
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'To write_manages_ca_file name ->'||x_file_name);

     x_ret_code := NULL;
     x_err_msg  := NULL;
     write_manages_ca_file( p_file_name    => x_file_name
                    ,p_email_flag   => p_email_flag
                    ,x_return_code  => x_ret_code
                    ,x_error_msg    => x_err_msg);

     IF NVL(x_ret_code,0) <> 0 THEN
        RAISE x_lrn_error;
     END IF;
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'write_manages_ca_file ->'||x_ret_code);

  EXCEPTION
     WHEN x_lrn_error THEN
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in LRN File Writing ->'||x_err_msg);
        p_retcode := 2;
     WHEN x_efile_error THEN
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in Error File Writing ->'||x_err_msg);
        p_retcode := 2;
     WHEN OTHERS THEN
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,SQLERRM);
       p_retcode := 2;
  END main;
  ----------------------------------------------------------------------
END xx_hr_lrn_int_pkg; 
/
