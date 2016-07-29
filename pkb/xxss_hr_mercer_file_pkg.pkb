DROP PACKAGE BODY APPS.XXSS_HR_MERCER_FILE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xxss_hr_mercer_file_pkg
as

/*******************************************************************
  Module Name          : xxss_hr_mercer_file_pkg
  Original Author      : Shekhar Nikam
  Description          : Procedures and functions related to SeaSpine Oracle HR-Mercer
                         outbound Interface

  Change List:
  ------------
  Name           Date        Version  Description
  -------------- ----------- -------  ------------------------------
  Shekhar Nikam  16-Jun-2015 1.0      Initial Version

*********************************************************************/

procedure process_employees (p_eff_date IN DATE,p_file_name IN VARCHAR2)
as
    cursor c_census_data
    is
    select papf.person_id
    ,papf.national_identifier
    ,papf.employee_number
    ,papf.last_name
    ,papf.first_name
    ,substr(papf.middle_names,1,1) middle_name
    ,papf.sex gender
    ,hr_general.decode_lookup('MAR_STATUS',papf.marital_status) marital_status
    ,to_char(papf.date_of_birth,'MM/DD/YYYY') date_of_birth
    ,to_char(papf.original_date_of_hire,'MM/DD/YYYY') hire_date
    ,to_char(ppos.date_start,'MM/DD/YYYY') adjusted_hire_date
    ,pa.address_line1
    ,pa.address_line2
    ,pa.town_or_city city
    ,pa.region_2 state
    ,substr(pa.postal_code,1,5) zip_code
    ,hr_general.get_phone_number(papf.person_id,
                                   'W1',
                                   p_eff_date
                                   ) work_phone
    ,nvl(hr_general.get_phone_number(papf.person_id,
                                 'H1',
                                 p_eff_date
                                 )
        ,hr_general.get_phone_number(papf.person_id,
                                 'M',
                                 p_eff_date
                                 )) home_phone
    ,hla.location_code work_location
    ,papf.email_address
    ,(SELECT hou.name
      FROM hr_organization_units_v hou
      ,hr_soft_coding_keyflex flx
      WHERE hou.attribute_category = 'US'
      AND hou.organization_id = flx.segment1
      AND flx.soft_coding_keyflex_id = paaf.soft_coding_keyflex_id) GRE
    ,haou.name hr_organizations
    ,hr_general.decode_lookup('EMP_ASSIGN_REASON',paaf.change_reason) assignment_change_reason
    ,hapf.name position
    ,ppf.payroll_name
    ,past.user_status assignment_status
    ,hr_general.decode_lookup('US_EXEMPT_NON_EXEMPT',pj.job_information3) FLSA_Code
    ,hr_general.decode_lookup('EMP_CAT',paaf.employment_category) assignment_category
    ,paaf.normal_hours working_hours
    ,ppb.pay_basis salary_basis
    ,DECODE (ppb.pay_basis,'HOURLY',ppp.proposed_salary_n * paaf.normal_hours * 52,
             'ANNUAL', ppp.proposed_salary_n) base_salary
   -- ,to_char(ppos.actual_termination_date,'DDMONYYYY') actual_termination_date
    ,to_char(ppos.actual_termination_date,'MM/DD/YYYY') actual_termination_date
    ,hr_general.decode_lookup('LEAV_REAS',ppos.leaving_reason) leaving_reason
    ,trunc(sysdate)
    ,'S'
    ,NULL
    from per_all_people_f papf
    ,per_all_assignments_f paaf
    ,per_assignment_status_types past
    ,per_addresses pa
    ,per_periods_of_service ppos
    ,hr_locations_all hla
    ,hr_all_organization_units haou
    ,hr_all_positions_f hapf
    ,per_jobs pj
    ,pay_payrolls_f ppf
    ,per_pay_bases ppb
    ,per_pay_proposals ppp
    where papf.person_id=paaf.person_id
    and papf.person_id=pa.person_id(+)
    and papf.person_id=ppos.person_id
    and paaf.ASSIGNMENT_STATUS_TYPE_ID = past.assignment_status_type_id
    and paaf.organization_id=haou.organization_id
    and paaf.location_id=hla.location_id(+)
    and paaf.position_id=hapf.position_id(+)
    and paaf.job_id=pj.job_id(+)
    and paaf.payroll_id = ppf.payroll_id(+)
    and paaf.pay_basis_id=ppb.pay_basis_id(+)
    and paaf.assignment_id=ppp.assignment_id(+)
    and ppos.period_of_service_id = (select max(period_of_service_id)
                                      from per_periods_of_service
                                      where person_id= papf.person_id
                                      and date_start <= p_eff_date
                                      )
    and (nvl(ppos.actual_termination_date,p_eff_date) between (p_eff_date)-60 AND p_eff_date
          OR (ppos.actual_termination_date > p_eff_date))
    and paaf.assignment_type = 'E'
    and paaf.primary_flag = 'Y'
    and pa.primary_flag(+) = 'Y'
    and p_eff_date between papf.effective_start_date and papf.effective_end_date
    and (p_eff_date BETWEEN paaf.effective_start_date AND paaf.effective_end_date
           OR (paaf.effective_end_date < p_eff_date
               AND paaf.effective_end_date = (SELECT MAX(asg.effective_end_date)
                                              FROM per_all_assignments_f asg
                                              WHERE asg.assignment_id = paaf.assignment_id
                                              AND   asg.period_of_service_id = paaf.period_of_service_id
                                             )
              )
          )
    and p_eff_date between hapf.effective_start_date(+) and hapf.effective_end_date(+)
    and p_eff_date between ppf.effective_start_date(+) and ppf.effective_end_date(+)
    and NVL (UPPER (papf.attribute5), 'YES') <> 'NO'
    and p_eff_date between pa.date_from(+) AND NVL (pa.date_to(+),TO_DATE('31-DEC-4712','DD-MON-YYYY'))
    and pa.country(+) = 'US'
    and hla.country = 'US'
    and ppp.approved(+) = 'Y'
    and ppp.change_date(+) <= p_eff_date
    and nvl(ppp.change_date,trunc(sysdate)) = nvl((SELECT  MAX (x.change_date)
                             FROM   apps.per_pay_proposals x
                            WHERE       x.assignment_id = ppp.assignment_id
                                    AND x.change_date <= p_eff_date
                                    AND x.approved = 'Y'),trunc(sysdate));

    x_census_data  g_census_data_tbl_type;

BEGIN
      BEGIN
         OPEN c_census_data;
         LOOP
         FETCH c_census_data
         BULK COLLECT INTO x_census_data LIMIT 1000;
         FORALL i IN 1 .. x_census_data.COUNT
            INSERT INTO xxss_hr_emp_census_stg
            VALUES x_census_data (i);
            EXIT WHEN c_census_data%NOTFOUND;
         END LOOP;
         CLOSE c_census_data;
         COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
         g_retcode := xx_emf_cn_pkg.cn_rec_err;
         g_errmsg := 'Error while bulk insert'||SQLERRM;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'retcode: ' ||g_retcode||' Error: '||g_errmsg);
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                       xx_emf_cn_pkg.cn_tech_error,
                       xx_emf_cn_pkg.cn_exp_unhand,
                          'Unexpected error while bulk insert',
                           SQLERRM);
      END;
EXCEPTION
 WHEN OTHERS THEN
         g_retcode := xx_emf_cn_pkg.cn_prc_err;
         g_errmsg := 'Error in xx_hr_process_data_stg'||SQLERRM;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'retcode: ' ||g_retcode||' Error: '||g_errmsg);
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                       xx_emf_cn_pkg.cn_tech_error,
                       xx_emf_cn_pkg.cn_exp_unhand,
                          'Unexpected error in xx_hr_process_data_stg',
                           SQLERRM);
END process_employees;

FUNCTION xx_hr_format_phone_num( p_phone_num IN VARCHAR2 )
   RETURN VARCHAR2
   IS
      x_phone_number VARCHAR2(50);
   BEGIN
      IF p_phone_num IS NOT NULL THEN
         x_phone_number := regexp_replace(p_phone_num,'[^[:alnum:]]');
         x_phone_number := SUBSTR(x_phone_number, GREATEST (-10, -length(x_phone_number)), 10);
      ELSE
         x_phone_number := NULL;
      END IF;
      RETURN x_phone_number;
      EXCEPTION
      WHEN OTHERS THEN
          x_phone_number := NULL;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Errror in xx_hr_format_phone_num: ' ||p_phone_num);
          xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                        xx_emf_cn_pkg.cn_tech_error,
                        xx_emf_cn_pkg.cn_exp_unhand,
                        'Unexpected error in xx_hr_format_phone_num',
                            SQLERRM);
          RETURN x_phone_number;
END xx_hr_format_phone_num;

PROCEDURE xx_hr_get_process_param_val( p_file_prefix OUT VARCHAR2,
                                          p_file        OUT VARCHAR2,
                                          p_utl_dir     OUT VARCHAR2,
                                          p_file_ext    OUT VARCHAR2
                                        )
   IS
      x_process_name VARCHAR2(25) := 'XXHRSSMRCRINTF';
   BEGIN
      --Fetch File Pre fix value from process setup
      xx_intg_common_pkg.get_process_param_value( x_process_name,
                                                 'FILE_PREFIX',
                                                  p_file_prefix
                                                );
      --Fetch File name value from process setup
      xx_intg_common_pkg.get_process_param_value( x_process_name,
                                                 'FILE_NAME',
                                                  p_file
                                                );
      --Fetch utl directory value from process setup
      xx_intg_common_pkg.get_process_param_value( x_process_name,
                                                 'UTL_DIRECTORY',
                                                  p_utl_dir
                                                );
      --Fetch File extension value from process setup
      xx_intg_common_pkg.get_process_param_value( x_process_name,
                                                 'FILE_EXTENSION',
                                                  p_file_ext
                                                );

      EXCEPTION
         WHEN OTHERS THEN
         g_retcode := xx_emf_cn_pkg.cn_prc_err;
         g_errmsg := 'Error in xx_hr_get_process_param_val'||SQLERRM;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'retcode: ' ||g_retcode||' Error: '||g_errmsg);
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand,
                              'Unexpected error in xx_hr_get_process_param_val',
                              SQLERRM
                             );
END xx_hr_get_process_param_val;

FUNCTION translate_leaving_reason(p_leaving_reason VARCHAR2)
return varchar2
as

v_translated_value varchar2(100);

BEGIN
        BEGIN
            select hl.description
            into v_translated_value
            from hr_lookups hl
            where lookup_type = 'INTG_SS_MRCR_LEAV_REASON_LKP'
            and meaning = p_leaving_reason
            and trunc(sysdate) between nvl(hl.start_date_active,to_date('01-JAN-1951','DD-MON-YYYY'))
                and nvl(hl.end_date_active,to_date('31-DEC-4712','DD-MON-YYYY'));

            RETURN v_translated_value;

        EXCEPTION WHEN OTHERS THEN
          v_translated_value := NULL;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Errror in translate_leaving_reason: ' ||p_leaving_reason);
          xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                        xx_emf_cn_pkg.cn_tech_error,
                        xx_emf_cn_pkg.cn_exp_unhand,
                        'Unexpected error in translate_leaving_reason',
                            SQLERRM);
          RETURN v_translated_value;
        END;
END translate_leaving_reason;

PROCEDURE generate_file (p_file_name  IN VARCHAR2,p_data_dir   IN VARCHAR2)
as
   cursor c_file_data
   is
   select national_identifier
   ,employee_number
   ,last_name
   ,first_name
   ,middle_name
   ,gender
   ,marital_status
   ,date_of_birth
   ,hire_date
   ,ADJUSTED_HIRE_DATE
   ,ADDRESS_LINE1
   ,ADDRESS_LINE2
   ,city
   ,state
   ,zip_code
   ,work_phone
   ,home_phone
   ,WORK_LOCATION
   ,EMAIL_ADDRESS
   ,GRE
   ,HR_ORGANIZATIONS
   ,ASSIGNMENT_CHANGE_REASON
   ,POSITION
   ,PAYROLL_NAME
   ,ASSIGNMENT_STATUS
   ,FLSA_CODE
   ,ASSIGNMENT_CATEGORY
   ,WORKING_HOURS
   ,SALARY_BASIS
   ,round(BASE_SALARY,2) base_salary
   ,ACTUAL_TERMINATION_DATE
   ,LEAVING_REASON
   from xxss_hr_emp_census_stg;

 x_file_type   UTL_FILE.file_type;
 x_data_dir    VARCHAR2(80);
 x_file_data   VARCHAR2(4000);

 x_err_out         VARCHAR2(4000);
 x_file_name       VARCHAR2(1000);
 x_to_mail         VARCHAR2(1000);
 x_subject         VARCHAR2(60);
 x_message         VARCHAR2(60);
 x_from            VARCHAR2(60);
 x_bcc_name        VARCHAR2(60);
 x_cc_name         VARCHAR2(60);
 x_return_code     NUMBER := 0;
 x_error_msg       VARCHAR2(2000);
 v_work_phone      VARCHAR2(50);
 v_home_phone      VARCHAR2(50);
 v_leaving_reason  VARCHAR2(100);
 x_data_head       VARCHAR2(4000);

BEGIN
     x_file_name := p_file_name;
     x_data_dir  :=p_data_dir;

    -- opening the file
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'file name: '||x_file_name);
         x_file_type := UTL_FILE.fopen_nchar (x_data_dir, x_file_name, 'W', 6400);
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
                  x_error_msg   := x_file_name || SQLERRM;
      END;

      g_retcode := x_return_code;
      g_errmsg := x_error_msg;

     IF NVL(x_return_code,0) = 0 THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'file opened');

         x_data_head := 'Social Security Number'||','||'Employee Number'||','||'Last Name'||','||'First Name'||','||'Middle Initial'||','||'Gender'||','||
                        'Marital Status'||','||'Date of Birth'||','||'Hire Date'||','||'Adjusted Hire Date'||','||'Address1'||','||'Address2'||','||'City'||','||
                        'State'||','||'Zip'||','||'Work Phone'||','||'Home Phone'||','||'Work Location'||','||'Email Address-Work'||','||'GRE(Payroll Company)'||','||
                        'HR Organization'||','||'Assignment Change Reason'||','||'Position'||','||'Payroll Name'||','||'Assignment Status'||','||'FLSA Code'||','||
                        'Assignment Category'||','||'Working Hours'||','||'Salary Basis'||','||'Annualized Salary'||','||'Termination Date'||','||'Termination Reason';


         UTL_FILE.PUT_LINE_NCHAR(x_file_type,x_data_head);


         FOR r_file_data in c_file_data
         LOOP
            v_work_phone := NULL;
            v_home_phone := NULL;
            v_leaving_reason := NULL;
            x_file_data := NULL;

            v_work_phone := xxss_hr_mercer_file_pkg.xx_hr_format_phone_num(r_file_data.work_phone);
            v_home_phone := xxss_hr_mercer_file_pkg.xx_hr_format_phone_num(r_file_data.home_phone);

            IF r_file_data.LEAVING_REASON is not null then
                v_leaving_reason := xxss_hr_mercer_file_pkg.translate_leaving_reason(r_file_data.LEAVING_REASON);
            ELSE
                v_leaving_reason := r_file_data.LEAVING_REASON;
            END IF;

            x_file_data :='"'||r_file_data.national_identifier||'"'||','
            ||'"'||r_file_data.employee_number||'"'||','
            ||'"'||r_file_data.last_name||'"'||','
            ||'"'||r_file_data.first_name||'"'||','
            ||'"'||r_file_data.middle_name||'"'||','
            ||'"'||r_file_data.gender||'"'||','
            ||'"'||r_file_data.marital_status||'"'||','
            ||'"'||r_file_data.date_of_birth||'"'||','
            ||'"'||r_file_data.hire_date||'"'||','
            ||'"'||r_file_data.ADJUSTED_HIRE_DATE||'"'||','
            ||'"'||r_file_data.ADDRESS_LINE1||'"'||','
            ||'"'||r_file_data.ADDRESS_LINE2||'"'||','
            ||'"'||r_file_data.city||'"'||','
            ||'"'||r_file_data.state||'"'||','
            ||'"'||r_file_data.zip_code||'"'||','
            ||'"'||v_work_phone||'"'||','
            ||'"'||v_home_phone||'"'||','
            ||'"'||r_file_data.WORK_LOCATION||'"'||','
            ||'"'||r_file_data.EMAIL_ADDRESS||'"'||','
            ||'"'||r_file_data.GRE||'"'||','
            ||'"'||r_file_data.HR_ORGANIZATIONS||'"'||','
            ||'"'||r_file_data.ASSIGNMENT_CHANGE_REASON||'"'||','
            ||'"'||r_file_data.POSITION||'"'||','
            ||'"'||r_file_data.PAYROLL_NAME||'"'||','
            ||'"'||r_file_data.ASSIGNMENT_STATUS||'"'||','
            ||'"'||r_file_data.FLSA_CODE||'"'||','
            ||'"'||r_file_data.ASSIGNMENT_CATEGORY||'"'||','
            ||'"'||r_file_data.WORKING_HOURS||'"'||','
            ||'"'||r_file_data.salary_basis||'"'||','
            ||'"'||r_file_data.base_salary||'"'||','
            ||'"'||r_file_data.ACTUAL_TERMINATION_DATE||'"'||','
            ||'"'||v_leaving_reason||'"';

            UTL_FILE.PUT_LINE_NCHAR(x_file_type,x_file_data);

         END LOOP;

         IF UTL_FILE.IS_OPEN(x_file_type) THEN
             UTL_FILE.FCLOSE (x_file_type);
         END IF;

     END IF;

   EXCEPTION
      WHEN OTHERS THEN
         g_retcode := xx_emf_cn_pkg.cn_prc_err;
         g_errmsg := 'Error in xx_hr_file_generation'||SQLERRM;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'retcode: ' ||g_retcode||' Error: '||g_errmsg);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Writing File: ' ||SQLERRM);
         xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW,
                          xx_emf_cn_pkg.CN_TECH_ERROR,
                          xx_emf_cn_pkg.CN_EXP_UNHAND,
                          'Unexpected error in xx_hr_file_generation',
                           SQLERRM);
         UTL_FILE.fclose(x_file_type);

   END generate_file;


PROCEDURE send_email(p_file_name IN VARCHAR2
                           ,p_data_dir   IN VARCHAR2
                           ,x_return_code  OUT  NUMBER
                           ,x_error_msg    OUT  VARCHAR2)
    IS

        CURSOR   c_mail
    IS
     SELECT  description
       FROM  fnd_lookup_values_vl
      WHERE  lookup_type = 'INTG_MERCER_FILE_EMAIL_LKP'
        AND  NVL(enabled_flag,'X')='Y'
        AND  LOOKUP_CODE=1
        AND  trunc(SYSDATE) BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE);

     x_to_mail         VARCHAR2(1000);
     x_subject         VARCHAR2(60);
     x_message         VARCHAR2(60);
     x_from            VARCHAR2(60);
     x_bcc_name        VARCHAR2(60);
     x_cc_name         VARCHAR2(60);

BEGIN
        x_subject:='Benefits File';
        x_message := 'Please find attached the Benefits file';
        x_from := 'SeaSpine@seaspine.com';


        FOR mail_rec IN c_mail LOOP
           x_to_mail := x_to_mail ||mail_rec.description;
        END LOOP;
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'------------------- Benefits File Mailing   ------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_from      -> '||x_from);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_mail   -> '||x_to_mail);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_subject   -> '||x_subject);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_message   -> '||x_message);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_dir    -> '||p_data_dir);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_file_name -> '||p_file_name);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');


        IF x_to_mail IS NOT NULL THEN
           BEGIN
             xx_intg_mail_util_pkg.send_mail_attach( p_from_name        => x_from
                                                    ,p_to_name          => x_to_mail
                                                    ,p_cc_name          => x_cc_name
                                                    ,p_bc_name          => x_bcc_name
                                                    ,p_subject          => x_subject
                                                    ,p_message          => x_message
                                                    ,p_oracle_directory => p_data_dir
                                                    ,p_binary_file      => p_file_name);
           EXCEPTION
              WHEN OTHERS THEN
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
              x_return_code := xx_emf_cn_pkg.cn_rec_warn;
              x_error_msg   := 'Error in mailing error file';
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,x_error_msg);
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
           END;
        END IF;

        EXCEPTION
            WHEN OTHERS THEN
                 x_error_msg   := 'Procedure - write_lrn_file ->' || SQLERRM;
                 x_return_code := xx_emf_cn_pkg.cn_prc_err;
END send_email;

PROCEDURE truncate_table (p_table_name IN VARCHAR2)
   IS
      l_sql     VARCHAR2 (1000);
      l_owner   dba_tables.owner%TYPE;

      CURSOR c_owner
      IS
         SELECT   owner
           FROM   dba_tables
          WHERE   table_name = p_table_name;
BEGIN
      OPEN c_owner;

      FETCH c_owner INTO   l_owner;

      IF c_owner%NOTFOUND
      THEN
         CLOSE c_owner;
      ELSE
         CLOSE c_owner;
      END IF;

      l_sql := 'TRUNCATE TABLE ' || l_owner || '.' || p_table_name;

      EXECUTE IMMEDIATE l_sql;
END truncate_table;


PROCEDURE main (
                    errbuf                OUT      VARCHAR2,
                    retcode               OUT      VARCHAR2,
                    p_effec_date          IN       VARCHAR2,
                    p_file_name           IN       VARCHAR2
                   )
   IS
      x_hdr_data     VARCHAR2(32767);
      x_error_code   NUMBER;
      x_utl_dir      VARCHAR2(100);
      x_file_name    VARCHAR2(50);
      x_file         VARCHAR2(50);
      x_file_prefix  VARCHAR2(50);
      x_file_ext     VARCHAR2(10);
      x_effec_date   DATE;

      x_ret_code           NUMBER :=0;
      x_err_msg            VARCHAR2(3000);

BEGIN

     truncate_table(p_table_name   => 'XXSS_HR_EMP_CENSUS_STG');
     --Main Procedure
      BEGIN
         retcode := xx_emf_cn_pkg.cn_success;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Before Setting Environment');
         -- Set the environment
         x_error_code := xx_emf_pkg.set_env;
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE xx_emf_pkg.g_e_env_not_set;
      END;

      g_retcode := xx_emf_cn_pkg.cn_success;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'********************Program Parameters****************');
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Effective Date: '||p_effec_date);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'File Name: '||p_file_name);

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Before Call xx_hr_get_process_param_val');
      --Procedure to fetch process setup values
      xx_hr_get_process_param_val( x_file_prefix
                                  ,x_file
                                  ,x_utl_dir
                                  ,x_file_ext
                                 );
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'After Call xx_hr_get_process_param_val');
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'********************Process Setup Entries****************');
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'File Prefix: '||x_file_prefix);
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'File Name: '||x_file);
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'UTL Directory: '||x_utl_dir);
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'File Extension: '||x_file_ext);
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'******************************************************');


        --Generate file name if not provided
        IF p_file_name IS NULL THEN
           IF x_file_prefix IS NOT NULL THEN
              x_file_name := x_file||x_file_prefix||'_'||TO_CHAR(SYSDATE,'RRRRMMDDHH24MISS')||x_file_ext;
           ELSE
              x_file_name := x_file||'_'||TO_CHAR(SYSDATE,'RRRRMMDDHH24MISS')||x_file_ext;
           END IF;
        ELSE
           x_file_name := p_file_name;
        END IF;

     x_effec_date := TRUNC(TO_DATE(p_effec_date,'YYYY-MM-DD HH24:MI:SS'));

        --Call procedure to process census data
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Before Call  process_employees');

        process_employees(x_effec_date,x_file_name);

        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'After  process_employees g_retcode: '||g_retcode);

        xx_emf_pkg.propagate_error (g_retcode);

        --Call procedure to generate file
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Before Call generate_file');

        generate_file(x_file_name,x_utl_dir);

        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'After generate_file g_retcode: '||g_retcode);

        xx_emf_pkg.propagate_error (g_retcode);


     -- Send Email to benefits team

       send_email(x_file_name,x_utl_dir,x_ret_code,x_err_msg);

   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'xx_emf_pkg.cn_env_not_set: '||xx_emf_pkg.cn_env_not_set);
         retcode := xx_emf_cn_pkg.cn_rec_err;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Procedure Error:retcode: '||g_retcode||' Err Msg: '||g_errmsg);
         retcode := xx_emf_cn_pkg.cn_prc_err;
         xx_emf_pkg.create_report;
      WHEN OTHERS THEN
         retcode := xx_emf_cn_pkg.cn_prc_err;
         errbuf := SUBSTR (SQLERRM, 1, 250);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'retcode: ' ||retcode||' Error: '||errbuf);
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                           xx_emf_cn_pkg.cn_tech_error,
                           xx_emf_cn_pkg.cn_exp_unhand,
                           'Unexpected error in main',
                           SQLERRM
                          );
END main;

END xxss_hr_mercer_file_pkg;
/
