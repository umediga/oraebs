DROP PACKAGE BODY APPS.INTG_HR_PF_EMPINTF_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.intg_hr_pf_empintf_pkg AS
----------------------------------------------------------------------
/*
 Created By    : Sridevi Eti
 Creation Date : 06-OCT-2014
 File Name     : intg_hr_pf_empintf_pkg.pkb
 Description   : This script creates the body of the package
                 intg_hr_pf_empintf_pkg
 Change History:
 Date           Name                  Remarks
 -----------   -------------         -----------------------------------
 06-OCT-2014   Sridevi Eti          Initial development.
 13-Jan-2015   Jaya Maran Jayaraj       Modified for ticket#12273
 */
------------------------------------------------------------------------
    g_user_id          NUMBER := FND_GLOBAL.USER_ID;
    g_login_id         NUMBER := FND_GLOBAL.LOGIN_ID;
    g_request_id       NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
    g_csv              VARCHAR2(3):='|';
    g_date          VARCHAR2(30):=to_char(sysdate,'DD-MM-YYYY');
    g_d              VARCHAR2(3):='--';

-- Procedure to Process each datafile based on file_name parameter
   PROCEDURE intg_hr_pf_employee(x_errbuff out VARCHAR2,
                                  x_retcode out NUMBER,
                                  p_eff_date IN VARCHAR2,
                                  p_file_name IN NUMBER)  IS

       l_errbuff varchar2(2000);
       l_retcode number;
       l_prog_id number;
       l_eff_date date;

       BEGIN

           IF  p_file_name = 1 THEN
              intg_hr_pf_empintf_pkg.hr_pf_per_data(l_errbuff,
                                                    l_retcode,
                                                    p_eff_date,
                                                    p_file_name);
           ELSIF  p_file_name = 2 THEN
              intg_hr_pf_empintf_pkg.hr_pf_emp_data(l_errbuff,
                                                    l_retcode,
                                                     p_eff_date,
                                                     p_file_name);
           ELSIF  p_file_name = 3 THEN
              intg_hr_pf_empintf_pkg.hr_pf_user_data(l_errbuff,
                                                    l_retcode,
                                                     p_eff_date,
                                                     p_file_name);
           ELSIF  p_file_name = 4 THEN
              intg_hr_pf_empintf_pkg.hr_pf_pos_holder_data(l_errbuff,
                                                    l_retcode,
                                                     p_eff_date,
                                                     p_file_name);
            ELSIF  p_file_name = 5 THEN
              intg_hr_pf_empintf_pkg.hr_pf_pos_hr_data(l_errbuff,
                                                     l_retcode,
                                                     p_eff_date,
                                                     p_file_name);


           ELSIF  p_file_name =7 THEN
              intg_hr_pf_empintf_pkg.hr_pf_incentive_data(l_errbuff,
                                                    l_retcode,
                                                     p_eff_date,
                                                     p_file_name);
           ELSIF  p_file_name = 8 THEN
                intg_hr_pf_empintf_pkg.hr_pf_salary_data(l_errbuff,
                                                    l_retcode,
                                                     p_eff_date,
                                                     p_file_name);

           ELSIF  p_file_name = 9 THEN
              intg_hr_pf_empintf_pkg.hr_pf_custom_data(l_errbuff,
                                                    l_retcode,
                                                     p_eff_date,
                                                     p_file_name);

           ELSE
             null;

           END IF;

             x_retcode := l_retcode;
             x_errbuff := l_errbuff;

          fnd_file.put_line (fnd_file.LOG, x_errbuff );

   EXCEPTION
      WHEN OTHERS THEN
      x_retcode := SQLCODE;
      x_errbuff := 'Error in intg_hr_pf_employee procedure' || SQLERRM;
      fnd_file.put_line (fnd_file.LOG, x_errbuff );

   END intg_hr_pf_employee;

-- Main Procedure to submit INTG PF Employee Interface program
   PROCEDURE intg_hr_pf_employee_main(x_errbuff out VARCHAR2,
                                      x_retcode out NUMBER,
                                      p_eff_date IN VARCHAR2,
                                      p_file_name IN NUMBER)  IS
       l_errbuff varchar2(2000);
       l_retcode number;
       l_prog_id number;
       l_eff_date date;


       CURSOR c1 IS SELECT a.flex_value
                    FROM fnd_flex_values a,
                         fnd_flex_value_sets b
                     WHERE  a.flex_value_set_id=b.flex_value_set_id
                     AND   b.flex_value_set_name='INTG_HR_PS_FILENAMES1';

       BEGIN

        fnd_file.put_line (fnd_file.log,'+--------------------------------------------------------------------------------+');
        fnd_file.put_line (fnd_file.log,'+-----------------------INTG PF Employee Interface-------------------------+');
        fnd_file.put_line (fnd_file.log,'Parameters Passed');
        fnd_file.put_line (fnd_file.log,'Effective Date: ' || p_eff_date);
        fnd_file.put_line (fnd_file.log,'File Name: '||p_file_name);


        l_eff_date := FND_DATE.CANONICAL_TO_DATE (p_eff_date); -- Added by Shekhar

          IF (p_file_name IS NULL) THEN

                 FOR i IN c1 LOOP
                     intg_hr_pf_employee(l_errbuff,
                                         l_retcode,
                                         l_eff_date,
                                         i.flex_value);
                  END LOOP;

            ELSE
                     intg_hr_pf_employee(l_errbuff,
                                        l_retcode,
                                        l_eff_date,
                                        p_file_name);

            END IF;
         x_retcode := l_retcode;
         x_errbuff := l_errbuff;

       EXCEPTION
       WHEN OTHERS THEN
         x_retcode := SQLCODE;
         x_errbuff := 'Error in the Main procedure' || SQLERRM;
       fnd_file.put_line (fnd_file.LOG, x_errbuff );

       END intg_hr_pf_employee_main;

-- Procedure for fetching Person data for 5_Persons file
     PROCEDURE hr_pf_per_data(x_errbuff OUT VARCHAR2,
                              x_retcode OUT NUMBER,
                              p_eff_date IN DATE,
                              p_file_name IN NUMBER) IS

    l_program_num NUMBER;
    l_succ_flag VARCHAR2(1);
    l_Phone_Label VARCHAR2(25);
    l_email_add  VARCHAR2(250);
    l_error_message VARCHAR2(2500) := '';
    l_file_name   VARCHAR2 (100) :='05_Persons';
    x_pf_error        EXCEPTION;
    x_ret_code        NUMBER    := 0;
    x_err_msg         VARCHAR2 (3000);

    CURSOR c_persons IS
            SELECT
            ppf.Person_Id,
            ppf.attribute5,
            ppf.employee_number SourceSysRefKey,
            ppf.pre_name_adjunct AristocraticPrefix,
            replace(ppf.first_name,',',' ') GivenName,
            ppf.known_as PreferredGivenName,
            replace(ppf.middle_names,',',' ') MiddleName,
            replace(ppf.last_name,',',' ') familyname,
            ppf.title,
            ppf.suffix,
            ppf.email_address  email_address,
            (SELECT phone_number  FROM apps.per_phones phon
             WHERE Phon.Parent_Id = ppf.Person_Id
             AND Phon.Parent_Table(+) = 'PER_ALL_PEOPLE_F'
             AND     Phon.Phone_Type(+) = 'W1'
             AND p_eff_date BETWEEN NVL (phon.date_from, TO_DATE ('01-JAN-1951','DD-MON-YYYY'))AND  NVL (phon.date_to,TO_DATE ('31-DEC-4712','DD-MON-YYYY')) ) phone_number -- Added by Shekhar
            FROM    apps.per_all_people_f ppf
                   ,apps.per_person_type_usages_f p1
                   ,apps.per_person_types p2
            WHERE 1=1
            AND p_eff_date BETWEEN ppf.effective_start_date AND ppf.effective_end_date
            --AND ppf.person_type_id  IN (SELECT person_type_id FROM per_person_types  WHERE user_person_type LIKE '%mployee%') -- Commented by Shekhar
           -- AND (ppf.attribute5 IS NULL OR ppf.attribute5 = 'Yes')
            AND NVL(UPPER(ppf.attribute5),'YES')!='NO' -- Added by Shekhar
            AND p_eff_date between p1.effective_start_date and p1.effective_end_date
            AND p1.person_type_id = p2.person_type_id
            AND p2.system_person_type in ('EMP')
            AND ppf.person_id = p1.person_id ;

    BEGIN
       fnd_file.put_line (fnd_file.log,'+--------------------------------------------------------------------------------+');
       fnd_file.put_line (fnd_file.log,'+-----------------------INTG PF Person Data Extract-------------------------+');
       fnd_file.put_line (fnd_file.log,'Parameters Passed');
       fnd_file.put_line (fnd_file.log,'Effective Date: '||p_eff_date);
       fnd_file.put_line (fnd_file.log,'File Name: '||l_file_name);

        l_program_num:=NULL;
        IF p_file_name=1 THEN
           DELETE FROM INTG_HR_PF_PERSONS;
           commit;

           l_program_num:=1;


            FOR rec_person IN c_persons
            LOOP
               l_succ_flag :='Y';
               l_error_message :='';


                BEGIN
                   IF rec_person.phone_number  IS NOT NULL THEN
                      l_Phone_Label :='work';
                   ELSE
                      l_Phone_Label :='';
                   END IF;

                   -- If E-mail is not an Integra E-mail Error out the record
                   IF rec_person.email_address IS NOT NULL THEN
                      IF upper(rec_person.email_address) NOT LIKE '%SEASPINE.COM%' THEN
                        l_succ_flag :='N';
                        l_error_message := ' E-mail Address is Non Integra E-mail: '|| rec_person.email_address ;
                      END IF;
                   ELSE
                       l_email_add :='';
                       l_succ_flag :='N';
                       l_error_message := l_error_message  || ' E-mail Address is NULL' ;
                   END IF;


                   BEGIN

                     INSERT INTO INTG_HR_PF_PERSONS
                      (DOCUMENTTYPE,
                      SENDERID,
                      RECEIVERID,
                      VERSION,
                      ID    ,
                      SOURCESYSREFKEY,
                      ARISTOCRATICPREFIX,
                      FORMOFADDRESS,
                      GIVENNAME,
                      PREFERREDGIVENNAME,
                      MIDDLENAME,
                      FAMILYNAME,
                      GENERATION,
                      PHONELABEL1,
                      PHONEVALUE1,
                      EMAILLABEL1,
                      EMAILVALUE1,
                      CLEARCOLLECTION,
                      PERSON_ID,
                      LAST_UPDATE_DATE,
                      LAST_UPDATED_BY,
                      LAST_UPDATE_LOGIN,
                      CREATION_DATE,
                      CREATED_BY,
                      REQUEST_ID,
                      STATUS_CODE,
                      ERROR_MESG)
                     VALUES
                     ( 'AuthoriaPersons',
                     '948439432',
                     '178675716',
                     '1.22.110200',
                      NULL,
                      rec_person.SourceSysRefKey,
                      rec_person.AristocraticPrefix,
                      rec_person.title,
                      rec_person.givenname,
                      rec_person.preferredgivenname,
                      rec_person.middlename,
                      rec_person.familyname,
                      rec_person.suffix,
                      l_Phone_Label,
                      rec_person.phone_number,
                      'business',
                      rec_person.email_address,
                      0,
                      rec_person.person_id,
                      SYSDATE,
                      g_user_id,
                      g_login_id,
                      SYSDATE,
                      g_user_id,
                      g_request_id,
                      decode(l_succ_flag,'N','E','S'),
                      l_error_message
                      );
                   COMMIT;


                   EXCEPTION
                   WHEN OTHERS THEN
                      l_succ_flag := 'N';
                      x_retcode := SQLCODE;
                      l_error_message := 'ERROR WHILE INSERTING INTO STAGING TABLE' || SQLERRM ||' FOR Person: ' ||rec_person.SourceSysRefKey ;
                      x_errbuff := l_error_message;
                      fnd_file.put_line (fnd_file.LOG, l_error_message);
                   END;

              EXCEPTION
                   WHEN OTHERS THEN
                      l_succ_flag := 'N';
                      x_retcode := SQLCODE;
                      l_error_message := 'ERROR WHILE deriving additional fields for Person record: ' ||rec_person.SourceSysRefKey ;
                      x_errbuff := l_error_message;
                      fnd_file.put_line (fnd_file.LOG, l_error_message);

              END;

          END LOOP;

         x_ret_code := NULL;
         x_err_msg := NULL;

         create_pf_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         IF x_ret_code <>0 THEN
            fnd_file.put_line (fnd_file.LOG, 'Error While Preparing the Data File: ' || l_file_name ||'Return Code: '||x_ret_code || 'Error: ' || x_err_msg);
         ELSE
            fnd_file.put_line (fnd_file.LOG, 'Data File Succesfully Placed');
         END IF;


         create_pf_err_file (p_file_name, l_file_name, x_ret_code, x_err_msg);


         create_pf_log_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         fnd_file.put_line (fnd_file.LOG, 'After Create File Proc');

         IF NVL (x_ret_code, 0) <> 0
         THEN
            RAISE x_pf_error;
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'write_org_file ->' || x_ret_code
                              );

       END IF;

    EXCEPTION
    WHEN OTHERS THEN
       l_succ_flag := 'N';
       x_retcode := SQLCODE;
       l_error_message := 'Error in the procedure While processing' || l_file_name  || SQLERRM  ;
       x_errbuff := l_error_message;
       fnd_file.put_line (fnd_file.LOG, l_error_message);

   END hr_pf_per_data;

-- Procedure for fetching Employee data for 10_Employees file
    PROCEDURE hr_pf_emp_data(x_errbuff OUT VARCHAR2,
                                 x_retcode OUT NUMBER,
                                 p_eff_date IN DATE,
                                 p_file_name IN NUMBER) IS
    l_program_num NUMBER;
    l_succ_flag VARCHAR2(1);
    l_Phone_Label VARCHAR2(25);
    l_email_add  VARCHAR2(250);
    l_error_message VARCHAR2(2500) := '';

    l_file_name   VARCHAR2 (100) :='10_Employees';
    x_pf_error        EXCEPTION;
    x_ret_code        NUMBER    := 0;
    x_err_msg         VARCHAR2 (3000);
    i number(10) := 0;
    l_inact_start_date VARCHAR2(30);
    l_inact_end_date VARCHAR2(30);
   -- x_retcode VARCHAR2(10);
   -- l_error_message VARCHAR2(2000);

        CURSOR csr_active_emp
        IS
        SELECT ppos.person_id
        ,ppos.period_of_service_id
        ,papf.original_date_of_hire
        ,ppos.date_start
        ,ppos.actual_termination_date
        ,ihpp.sourcesysrefkey
        FROM per_periods_of_service ppos
        ,INTG_HR_PF_PERSONS ihpp
        ,per_all_people_f papf
        WHERE ppos.person_id=ihpp.person_id
        AND ihpp.person_id=papf.person_id
        AND ihpp.status_code = 'S'
        AND p_eff_date between papf.effective_start_date AND papf.effective_end_date
        UNION  -- This union will find all the terminated employees since last run.
        SELECT ppos.person_id
        ,ppos.period_of_service_id
        ,papf.original_date_of_hire
        ,ppos.date_start
        ,ppos.actual_termination_date
        ,papf.employee_number sourcesysrefkey
        FROM per_periods_of_service ppos
        ,per_all_people_f papf
        WHERE ppos.person_id=papf.person_id
        AND p_eff_date BETWEEN papf.effective_start_date AND papf.effective_end_date
        AND ppos.actual_termination_date IS NOT NULL
        AND ppos.actual_termination_date <= p_eff_date
        AND ppos.period_of_service_id = (SELECT MAX(p.period_of_service_id)
                                         FROM per_periods_of_service p
                                         WHERE p.person_id = papf.person_id
                                         AND date_start <= p_eff_date
                                         )
        AND EXISTS (select 1
                    from INTG_HR_PF_ACT_EMP_DATA
                    where  person_id= ppos.person_id
                    )
      ORDER BY 1,4;

      -- This cursor will get all active employees with more than 1 period of service or were sent as an active in last run
      --but they are now terminted in current run.
      CURSOR csr_inactive_rows
      IS
      SELECT DOCUMENTTYPE,
             SENDERID,
             RECEIVERID,
             VERSION,
             EMPLOYEESOURCESYSREFKEY,
             EMPLOYEEID,
             PERSONSOURCESYSREFKEY,
             STARTDATE,
             ADJUSTEDSERVICEDATE,
             EMPLOYEESTATUSSTARTDATE1,
             EMPLOYEESTATUSENDDATE1,
             EMPLOYEESTATUSTYPE1,
             EMPLOYEESTATUSPARENT1,
             PERSON_ID,
             SR_NUMBER
      FROM INTG_HR_PF_EMPLOYEES
      WHERE EMPLOYEESTATUSENDDATE1 IS NOT NULL
      AND EMPLOYEESTATUSTYPE1 = 'Active Assignment'
      AND status_code= 'S'
      ORDER BY person_id,EMPLOYEESTATUSSTARTDATE1;


    BEGIN
       fnd_file.put_line (fnd_file.log,'+--------------------------------------------------------------------------------+');
       fnd_file.put_line (fnd_file.log,'+-----------------------INTG PF Employee Data Extraction-------------------------+');
       fnd_file.put_line (fnd_file.log,'Parameters Passed');
       fnd_file.put_line (fnd_file.log,'Effective Date: '||p_eff_date);
       fnd_file.put_line (fnd_file.log,'File Name: '||p_file_name);

        l_program_num:=NULL;
        IF p_file_name=2 THEN
           DELETE FROM INTG_HR_PF_EMPLOYEES;
           commit;

           l_program_num:=2;

            FOR rec_active_emp IN csr_active_emp
                loop

                    BEGIN
                              i:= i+1;
                              INSERT INTO INTG_HR_PF_EMPLOYEES
                              (DOCUMENTTYPE,
                              SENDERID,
                              RECEIVERID,
                              VERSION,
                              ID    ,
                              EMPLOYEESOURCESYSREFKEY,
                              EMPLOYEEID,
                              PERSONSOURCESYSREFKEY,
                              STARTDATE,
                              ADJUSTEDSERVICEDATE,
                              PICTURESOURCESYSREFKEY,
                              EMPLOYEESTATUSSTARTDATE1,
                              EMPLOYEESTATUSENDDATE1,
                              EMPLOYEESTATUSTYPE1,
                              EMPLOYEESTATUSPARENT1,
                              PERSON_ID,
                              STATUS_CODE,
                              SR_NUMBER
                              )
                             VALUES
                             ( 'AuthoriaEmployees',
                             '948439432',
                             '178675716',
                             '1.22.110200',
                              NULL,
                              rec_active_emp.sourcesysrefkey,
                              rec_active_emp.sourcesysrefkey,
                              rec_active_emp.sourcesysrefkey,
                              TO_CHAR(rec_active_emp.original_date_of_hire,'YYYY-MM-DD'),
                              TO_CHAR(rec_active_emp.date_start,'YYYY-MM-DD'),
                              NULL,
                              TO_CHAR(rec_active_emp.date_start,'YYYY-MM-DD'),
                              TO_CHAR(rec_active_emp.actual_termination_date,'YYYY-MM-DD'),
                              'Active Assignment',
                              'Active',
                              rec_active_emp.person_id,
                              'S',
                              i
                              );
                           COMMIT;
                           EXCEPTION
                           WHEN OTHERS THEN
                              x_retcode := SQLCODE;
                              l_error_message := 'ERROR WHILE INSERTING INTO STAGING TABLE' || SQLERRM ||' FOR Employee: ' ||rec_active_emp.sourcesysrefkey ;
                              --x_errbuff := l_error_message;
                              fnd_file.put_line (fnd_file.LOG, l_error_message);
                           END;
                    END loop;


                  FOR rec_inactive_rows IN csr_inactive_rows
                  LOOP
                         l_inact_start_date := NULL;
                         l_inact_end_date    := NULL;
                        begin


                             BEGIN

                                 select to_char(fnd_date.canonical_to_date(EMPLOYEESTATUSENDDATE1)+1,'YYYY-MM-DD')
                                 INTO l_inact_start_date
                                 from INTG_HR_PF_EMPLOYEES
                                 where person_id=  rec_inactive_rows.person_id
                                 and sr_number = rec_inactive_rows.sr_number;
                             EXCEPTION
                                WHEN OTHERS THEN
                                     l_inact_start_date := NULL;
                             END;

                             BEGIN
                                 select to_char(fnd_date.canonical_to_date(EMPLOYEESTATUSSTARTDATE1)-1,'YYYY-MM-DD')
                                 INTO l_inact_end_date
                                 from INTG_HR_PF_EMPLOYEES
                                 where person_id= rec_inactive_rows.person_id
                                 and sr_number = rec_inactive_rows.sr_number+1;
                             EXCEPTION
                                   WHEN OTHERS THEN
                                        l_inact_end_date := NULL;
                              END;

                         END;

                          IF nvl(l_inact_end_date, to_date('31-DEC-4712','DD-MON-YYYY')) >= nvl(l_inact_start_date, to_date('01-JAN-1951','DD-MON-YYYY')) THEN
                         BEGIN

                            INSERT INTO INTG_HR_PF_EMPLOYEES
                              (DOCUMENTTYPE,
                              SENDERID,
                              RECEIVERID,
                              VERSION,
                              ID    ,
                              EMPLOYEESOURCESYSREFKEY,
                              EMPLOYEEID,
                              PERSONSOURCESYSREFKEY,
                              STARTDATE,
                              ADJUSTEDSERVICEDATE,
                              PICTURESOURCESYSREFKEY,
                              EMPLOYEESTATUSSTARTDATE1,
                              EMPLOYEESTATUSENDDATE1,
                              EMPLOYEESTATUSTYPE1,
                              EMPLOYEESTATUSPARENT1,
                              PERSON_ID,
                              STATUS_CODE
                             -- SR_NUMBER
                              )
                             VALUES
                             ( 'AuthoriaEmployees',
                             '948439432',
                             '178675716',
                             '1.22.110200',
                              NULL,
                              rec_inactive_rows.EMPLOYEESOURCESYSREFKEY,
                              rec_inactive_rows.EMPLOYEEID,
                              rec_inactive_rows.PERSONSOURCESYSREFKEY,
                              rec_inactive_rows.STARTDATE,
                              rec_inactive_rows.STARTDATE,
                              NULL,
                              l_inact_start_date,
                              l_inact_end_date,
                              'Terminated Assignment',
                              'Inactive',
                              rec_inactive_rows.person_id ,
                              'S'
                            --  i
                              );

                           COMMIT;
                           EXCEPTION
                           WHEN OTHERS THEN
                             -- l_succ_flag := 'N';
                              x_retcode := SQLCODE;
                              l_error_message := 'ERROR WHILE INSERTING TERM DATA INTO STAGING TABLE' || SQLERRM ||' FOR Employee: ' ||rec_inactive_rows.EMPLOYEESOURCESYSREFKEY ;
                              --x_errbuff := l_error_message;
                              fnd_file.put_line (fnd_file.LOG, l_error_message);

                         END;
                       END IF;

                       END loop;

                       delete from INTG_HR_PF_ACT_EMP_DATA;
                       commit;

                       BEGIN
                       -- Insert all current active employess data in below table so that this data can be used for next run
                       -- to find out the terminated employees from these active employees since last run.
                            INSERT INTO INTG_HR_PF_ACT_EMP_DATA
                            (select * from  INTG_HR_PF_EMPLOYEES
                             where EMPLOYEESTATUSTYPE1 = 'Active Assignment'
                             and EMPLOYEESTATUSENDDATE1 IS NULL
                             and status_code = 'S');
                             commit;
                       EXCEPTION
                            WHEN OTHERS THEN
                                 x_retcode := SQLCODE;
                                 l_error_message := 'ERROR WHILE INSERTING INTO INTG_HR_PF_ACT_EMP_DATA TABLE' || SQLERRM;
                                 fnd_file.put_line (fnd_file.LOG, l_error_message);
               END;

         x_ret_code := NULL;
         x_err_msg := NULL;

         create_pf_file (p_file_name, l_file_name, x_ret_code, x_err_msg);


         create_pf_err_file (p_file_name, l_file_name, x_ret_code, x_err_msg);


         create_pf_log_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         fnd_file.put_line (fnd_file.LOG, 'After Create File Proc');

         IF NVL (x_ret_code, 0) <> 0
         THEN
            RAISE x_pf_error;
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'write_org_file ->' || x_ret_code
                              );
       END IF;

    EXCEPTION
    WHEN OTHERS THEN
       l_succ_flag := 'N';
       x_retcode := SQLCODE;
       l_error_message := 'Error in the procedure While processing' || l_file_name  || SQLERRM  ;
       x_errbuff := l_error_message;
       fnd_file.put_line (fnd_file.LOG, l_error_message);


    END hr_pf_emp_data;

-- Procedure for fetching User data for 11_Users file
    PROCEDURE hr_pf_user_data(x_errbuff OUT VARCHAR2,
                              x_retcode OUT NUMBER,
                              p_eff_date IN DATE,
                              p_file_name IN NUMBER) IS

    l_program_num NUMBER;
    l_succ_flag VARCHAR2(1);
    l_global_value VARCHAR2(100);
    l_global_description VARCHAR2(100);
    l_contentlocale   VARCHAR2(100);
    l_currency   VARCHAR2(100);
    l_executive_performance VARCHAR2(100);
    l_executive_compensation VARCHAR2(100);
    l_error_message VARCHAR2(2500) := '';
    l_file_name   VARCHAR2 (100) :='11_Users';
    x_pf_error        EXCEPTION;
    x_ret_code        NUMBER    := 0;
    x_err_msg         VARCHAR2 (3000);
    l_manager_performance  VARCHAR2(30);

    CURSOR c_users IS
            select ihpp.SOURCESYSREFKEY employee_number
                    ,ihpp.person_id
                    ,'0'userinactive
                    from INTG_HR_PF_PERSONS ihpp
                    where status_code = 'S'
                    UNION  -- this UNION will get all users who have been terminted since last run
                    select papf.employee_number
                        ,papf.person_id
                        ,'1' userinactive
                        from per_periods_of_service ppos
                        ,per_all_people_f papf
                        where ppos.person_id=papf.person_id
                        and p_eff_date between papf.effective_start_date and papf.effective_end_date
                        and ppos.actual_termination_date IS NOT NULL
                        and ppos.actual_termination_date <= p_eff_date
                        and ppos.period_of_service_id = (SELECT MAX(p.period_of_service_id)
                                                         FROM per_periods_of_service p
                                                         WHERE p.person_id = papf.person_id
                                                         AND date_start <= p_eff_date
                                                         )
                        and exists (select 1
                                    from INTG_HR_PF_ACT_USERS
                                    where  person_id= ppos.person_id
                    );

    BEGIN
       fnd_file.put_line (fnd_file.log,'+--------------------------------------------------------------------------------+');
       fnd_file.put_line (fnd_file.log,'+-----------------------INTG PF Users Data Extract-------------------------+');
       fnd_file.put_line (fnd_file.log,'Parameters Passed');
       fnd_file.put_line (fnd_file.log,'Effective Date: '||p_eff_date);
       fnd_file.put_line (fnd_file.log,'File Name: '||l_file_name);


       DELETE FROM INTG_HR_PF_USERS;
       commit;

         BEGIN
           SELECT global_value,global_description
           INTO l_global_value,l_global_description
           FROM  ff_globals_f
           WHERE global_name ='INTG_PF_PWD_RECOVER'
           AND p_eff_date BETWEEN effective_start_date and effective_end_date;
         EXCEPTION
         WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.LOG, 'Exception when retrieving global_value from ff_globals_f');
         END;

            FOR rec_users IN c_users
            LOOP

            BEGIN
               l_succ_flag :='Y';
               l_error_message :='';

                BEGIN
                   SELECT DECODE(COUNT(1),0,'No','Manager Performance')
                    INTO l_manager_performance
                   FROM ( select 1
                          from per_all_assignments_f paaf
                          where supervisor_id = rec_users.person_id
                          and assignment_type = 'E'
                          and Paaf.Primary_Flag = 'Y'
                          and assignment_status_type_id <> 3
                          and p_eff_date between paaf.effective_start_date and paaf.effective_end_date
                         );
                EXCEPTION
                      WHEN OTHERS THEN
                      fnd_file.put_line (fnd_file.LOG, 'Exception when retrieving currency: ' || rec_users.employee_number);
                END;

                IF l_manager_performance = 'No' THEN
                    l_manager_performance := NULL;
                END IF    ;


                BEGIN

                   SELECT nvl(meaning,'en_US') contentlocale
                   INTO l_contentlocale
                   FROM hr_locations phl,
                        fnd_lookup_values flv,
                        per_all_assignments_f paaf
                   WHERE phl.country =   flv.lookup_code
                   AND   flv.lookup_type='INTG_PF_LOCALE'
                   AND flv.language =userenv('LANG')
                   AND phl.location_id= paaf.location_id
                   AND paaf.person_id = rec_users.person_id
                   AND p_eff_date between paaf.effective_start_date and paaf.effective_end_date
                   AND paaf.assignment_type = 'E' ;
                EXCEPTION
                WHEN OTHERS THEN
                 l_contentlocale :='en_US';
                 --fnd_file.put_line (fnd_file.LOG, 'Exception when retrieving Locale for user location id: ' || rec_users.Employee_number);
                END;

                BEGIN
                    SELECT SUBSTR(name,1,3) currency
                    INTO l_currency
                    FROM per_pay_bases ppb,
                         per_all_assignments_f paaf
                    WHERE ppb.pay_basis_id=paaf.pay_basis_id
                    AND  paaf.person_id =  rec_users.person_id
                    AND  p_eff_date between paaf.effective_start_date and paaf.effective_end_date;
                EXCEPTION
                WHEN OTHERS THEN
                    fnd_file.put_line (fnd_file.LOG, 'Exception when retrieving currency: ' || rec_users.employee_number);
                END;

                BEGIN
                    -- this SQL will find out whether the person being evaluated is a HR person or not
                    SELECT DECODE(COUNT(1),0,'No','HR Business Partner Performance')
                    INTO l_executive_performance
                    FROM (select 1
                      from dual
                      where exists (select 1
                                from pay_user_column_instances_f pci
                     ,pay_user_rows_f pur
                     ,pay_user_columns puc
                     ,pay_user_tables put
                    where  pci.user_row_id = pur.user_row_id
                    AND pci.user_column_id = puc.user_column_id
                    AND puc.user_table_id = put.user_table_id
                    AND put.user_table_name = 'INTG_HR_REPORTING_ORG'
                    AND pur.row_low_range_or_name <> 'Executive'
                    AND p_eff_date between pur.effective_start_date and pur.effective_end_date
                    AND p_eff_date between pci.effective_start_date and pci.effective_end_date
                    AND pci.VALUE = rec_users.person_id)
                    and exists (select 1
                             from  hr_locations_all hla
                        ,hr_location_extra_info hlei
                        where hla.location_id=hlei.location_id
                        and hlei.lei_information1 =rec_users.person_id
                        AND hlei.information_type = 'INTG_HR_Location_Security'
                        )
                     );


                EXCEPTION
                WHEN OTHERS THEN
                    fnd_file.put_line (fnd_file.LOG, 'Exception when retrieving HR Executive for: ' || rec_users.employee_number);
                END;

                IF l_executive_performance = 'HR Business Partner Performance' THEN
                   l_executive_compensation :='HR Business Partner Compensation';
                ELSE
                   l_executive_compensation :='';
                   l_executive_performance := '';
                END IF;


                   BEGIN

                     INSERT INTO INTG_HR_PF_USERS
                      (DOCUMENTTYPE,
                      SENDERID,
                      RECEIVERID,
                      VERSION,
                      ID    ,
                      USERSOURCESYSREFKEY,
                      USERINACTIVE,
                      LOGIN,
                      PASSWORDRECOVERYPHRASE,
                      PASSWORDRECOVERYANSWER,
                      ROLE1,
                      ROLE2,
                      ROLE3,
                      ROLE4,
                      PERSONSOURCESYSREFKEY,
                      CONTENTLOCALE,
                      APPLICATIONLOCALE,
                      CURRENCY,
                      DATEANDNUMBERFORMATLOCALE,
                      PERSON_ID,
                      LAST_UPDATE_DATE,
                      LAST_UPDATED_BY,
                      LAST_UPDATE_LOGIN,
                      CREATION_DATE,
                      CREATED_BY,
                      REQUEST_ID,
                      STATUS_CODE,
                      ERROR_MESG)
                     VALUES
                     ( 'AuthoriaUsers',
                     '948439432',
                     '178675716',
                     '1.22.110200',
                      NULL,
                      rec_users.employee_number,
                      rec_users.userinactive,
                      rec_users.employee_number,
                      l_global_description,
                      l_global_value,
                      'Employee',
                      l_manager_performance ,
                      l_executive_performance,
                      l_executive_compensation,
                      rec_users.employee_number,
                      l_contentlocale,
                      l_contentlocale,
                      l_currency,
                      l_contentlocale,
                      rec_users.person_id,
                      SYSDATE,
                      g_user_id,
                      g_login_id,
                      SYSDATE,
                      g_user_id,
                      g_request_id,
                      decode(l_succ_flag,'N','E','S'),
                      l_error_message
                      );
                   COMMIT;


                   EXCEPTION
                   WHEN OTHERS THEN
                      l_succ_flag := 'N';
                      x_retcode := SQLCODE;
                      l_error_message := 'ERROR WHILE INSERTING INTO STAGING TABLE' || SQLERRM ||' FOR User: ' ||rec_users.employee_number ;
                      x_errbuff := l_error_message;
                      fnd_file.put_line (fnd_file.LOG, l_error_message);
                   END;

              EXCEPTION
                   WHEN OTHERS THEN
                      l_succ_flag := 'N';
                      x_retcode := SQLCODE;
                      l_error_message := 'ERROR WHILE deriving additional fields for User record: ' ||rec_users.employee_number ;
                      x_errbuff := l_error_message;
                      fnd_file.put_line (fnd_file.LOG, l_error_message);

              END;

          END LOOP;

          DELETE FROM INTG_HR_PF_ACT_USERS;
          COMMIT;

              BEGIN
                  -- Insert this run active user data in below table so that this table data can be used in next run
                  --to find out who has been teminated since last run
                  INSERT INTO INTG_HR_PF_ACT_USERS (select * from INTG_HR_PF_USERS
                                        where status_code= 'S'
                                        and USERINACTIVE = '0');
              EXCEPTION
                  WHEN OTHERS THEN
                       x_retcode := SQLCODE;
                l_error_message := 'ERROR WHILE INSERTING INTO INTG_HR_PF_ACT_USERS TABLE' || SQLERRM;
                        fnd_file.put_line (fnd_file.LOG, l_error_message);
           END;

         x_ret_code := NULL;
         x_err_msg := NULL;

         create_pf_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         IF x_ret_code <>0 THEN
            fnd_file.put_line (fnd_file.LOG, 'Error While Preparing the Data File: ' || l_file_name ||'Return Code: '||x_ret_code || 'Error: ' || x_err_msg);
         ELSE
            fnd_file.put_line (fnd_file.LOG, 'Data File For ' || l_file_name|| 'Succesfully Placed');
         END IF;

         x_ret_code := NULL;
         x_err_msg := NULL;
         create_pf_err_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         IF x_ret_code <>0 THEN
            fnd_file.put_line (fnd_file.LOG, 'Error While Preparing the Error File: ' || l_file_name ||'Return Code: '||x_ret_code || 'Error: ' || x_err_msg);
         ELSE
            fnd_file.put_line (fnd_file.LOG, 'Error File Succesfully Placed');
         END IF;

         x_ret_code := NULL;
         x_err_msg := NULL;
         create_pf_log_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         IF x_ret_code <>0 THEN
            fnd_file.put_line (fnd_file.LOG, 'Error While Preparing the Log File: ' || l_file_name ||'Return Code: '||x_ret_code || 'Error: ' || x_err_msg);
         ELSE
            fnd_file.put_line (fnd_file.LOG, 'Log File Succesfully Placed');
         END IF;

         fnd_file.put_line (fnd_file.LOG, 'After Create File Proc');

         IF NVL (x_ret_code, 0) <> 0
         THEN
            RAISE x_pf_error;
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'write_org_file ->' || x_ret_code
                              );

    EXCEPTION
    WHEN OTHERS THEN
       l_succ_flag := 'N';
       x_retcode := SQLCODE;
       l_error_message := 'Error in the procedure While processing' || l_file_name  || SQLERRM  ;
       x_errbuff := l_error_message;
       fnd_file.put_line (fnd_file.LOG, l_error_message);

   END hr_pf_user_data;

 -- Procedure for fetching Position Holder history Data for 18_Position Holder History file
   PROCEDURE hr_pf_pos_holder_data(x_errbuff OUT VARCHAR2,
                                 x_retcode OUT NUMBER,
                                 p_eff_date IN DATE,
                                 p_file_name IN NUMBER) IS

    l_program_num NUMBER;
    l_succ_flag VARCHAR2(1);
    l_Phone_Label VARCHAR2(25);
    l_email_add  VARCHAR2(250);
    l_error_message VARCHAR2(2500) := '';

    l_file_name   VARCHAR2 (100) :='18_Position_Holder_History';
    x_pf_error        EXCEPTION;
    x_ret_code        NUMBER    := 0;
    x_err_msg         VARCHAR2 (3000);
    l_position_id      NUMBER;
    l_person_id         NUMBER;
    l_position_occupancy NUMBER(10);

     CURSOR c_position IS
            SELECT
                PP.PERSON_ID person_id,
                PP.employee_number,
                A.POSITION_ID position_id,
                ppb.pay_basis,
                 to_char(A.EFFECTIVE_START_DATE ,'YYYY-MM-DD') start_date,
                to_char(PER_GET_ASG_POS.END_DATE (A.ASSIGNMENT_ID, A.POSITION_ID, A.EFFECTIVE_START_DATE, A.EFFECTIVE_END_DATE)+1,'YYYY-MM-DD') END_DATE
                FROM PER_ALL_PEOPLE_F PP,
                PER_ALL_ASSIGNMENTS_F A,
                PER_PERSON_TYPES PT,
                PER_ASSIGNMENT_STATUS_TYPES AST,
                apps.per_pay_bases ppb
                WHERE A.PERSON_ID = PP.PERSON_ID
                AND a.Pay_Basis_Id               = ppb.Pay_Basis_Id
                AND PP.PERSON_TYPE_ID +0 = PT.PERSON_TYPE_ID
                AND trunc(sysdate) BETWEEN PP.EFFECTIVE_START_DATE AND PP.EFFECTIVE_END_DATE
                 AND A.ASSIGNMENT_TYPE IN ('E')
                AND A.ASSIGNMENT_STATUS_TYPE_ID = AST.ASSIGNMENT_STATUS_TYPE_ID
                AND AST.PER_SYSTEM_STATUS <> 'TERM_ASSIGN'
                AND A.POSITION_ID IS NOT NULL
                AND NOT EXISTS (SELECT NULL
                                FROM PER_ALL_ASSIGNMENTS_F X
                                WHERE X.ASSIGNMENT_ID = A.ASSIGNMENT_ID
                                AND X.ASSIGNMENT_TYPE = A.ASSIGNMENT_TYPE
                                AND X.POSITION_ID = A.POSITION_ID
                                AND X.EFFECTIVE_END_DATE = A.EFFECTIVE_START_DATE - 1
                                AND X.EFFECTIVE_START_DATE < A.EFFECTIVE_START_DATE)
                and exists (select 1
                            from INTG_HR_PF_PERSONS
                            where person_id = pp.person_id
                            and status_code = 'S'
                            )
                and exists (select 1
                             from intg_hr_pf_pos_data
                             where positioncode = a.position_id
                             and error_flag='S'
                             )
                order by pp.person_id,
                a.position_id,
                ppb.pay_basis;

    BEGIN
       fnd_file.put_line (fnd_file.log,'+--------------------------------------------------------------------------------+');
       fnd_file.put_line (fnd_file.log,'+-----------------------INTG PF Postion Holder History Data Extraction-------------------------+');
       fnd_file.put_line (fnd_file.log,'Parameters Passed');
       fnd_file.put_line (fnd_file.log,'Effective Date: '||p_eff_date);
       fnd_file.put_line (fnd_file.log,'File Name: '||p_file_name);

           DELETE FROM INTG_HR_PF_POS_HOLDER_HIS;
           commit;

            FOR rec_position IN c_position
            LOOP
               l_succ_flag :='Y';
               l_error_message :='';

               BEGIN
                   SELECT person_id
                   INTO l_person_id
                   FROM INTG_HR_PF_PERSONS
                   WHERE status_code='S'
                   AND  person_id = rec_position.person_id
                   AND  sourcesysrefkey = rec_position.employee_number;


               EXCEPTION WHEN NO_DATA_FOUND THEN
                   l_succ_flag :='N';
                   l_error_message := ' Employee Number ' || rec_position.employee_number|| ' is in 5_Persons Error Log' ;
               END;

               BEGIN
                   SELECT distinct sourcesysrefkey
                   INTO l_position_id
                   FROM intg_hr_pf_pos_data
                   WHERE error_flag='S'
                   AND  sourcesysrefkey = rec_position.position_id;

               EXCEPTION WHEN NO_DATA_FOUND THEN
                   l_succ_flag :='N';
                   l_error_message := l_error_message || ' position_id ' || rec_position.position_id || ' is in 17(a)_Positions Error Log' ;
               END;


               BEGIN
               select count(assignment_id)
               into l_position_occupancy
                from per_all_assignments_f
                where trunc(sysdate) between effective_start_date and effective_end_date
                and assignment_type = 'E'
                and assignment_status_type_id<>3
                and position_id=rec_position.position_id;
               EXCEPTION
                 WHEN OTHERS THEN
                  fnd_file.put_line (fnd_file.LOG, 'Error in getting position occupancy for position ID-'||rec_position.position_id );


               END;

              -- fnd_file.put_line (fnd_file.LOG, 'before insert into employee table' );

              IF l_position_occupancy <=1 THEN

                   BEGIN

                      INSERT INTO INTG_HR_PF_POS_HOLDER_HIS
                      (DOCUMENTTYPE,
                      SENDERID,
                      RECEIVERID,
                      VERSION,
                      ID    ,
                      SOURCESYSREFKEY,
                      EMPLOYEESOURCESYSREFKEY,
                      EMPLOYEETYPE ,
                      STARTDATE,
                      ENDDATE,
                      CLEARCOLLECTION,
                      PRESERVECURRENTPOSITIONHOLDERS,
                      PERSON_ID,
                      LAST_UPDATE_DATE,
                      LAST_UPDATED_BY,
                      LAST_UPDATE_LOGIN,
                      CREATION_DATE,
                      CREATED_BY,
                      REQUEST_ID,
                      STATUS_CODE,
                      ERROR_MESG)
                     VALUES
                     ( 'AuthoriaPositionHolderHistories',
                     '948439432',
                     '178675716',
                     '1.22.110200',
                      NULL,
                      rec_position.position_id,
                      rec_position.employee_number,
                      rec_position.pay_basis,
                      rec_position.start_date,
                      rec_position.end_date,
                      0,
                      0,
                      rec_position.person_id,
                      SYSDATE,
                      g_user_id,
                      g_login_id,
                      SYSDATE,
                      g_user_id,
                      g_request_id,
                      decode(l_succ_flag,'N','E','S'),
                      l_error_message
                      );
                   COMMIT;
                   EXCEPTION
                   WHEN OTHERS THEN
                      l_succ_flag := 'N';
                      x_retcode := SQLCODE;
                      l_error_message := 'ERROR WHILE INSERTING INTO STAGING TABLE: ' || SQLERRM ||' FOR Position Hodler History for Employee: ' ||rec_position.employee_number ;
                      x_errbuff := l_error_message;
                      fnd_file.put_line (fnd_file.LOG, l_error_message);
                   END;
               END IF;

          END LOOP;

         x_ret_code := NULL;
         x_err_msg := NULL;

         create_pf_file (p_file_name, l_file_name, x_ret_code, x_err_msg);


         create_pf_err_file (p_file_name, l_file_name, x_ret_code, x_err_msg);


         create_pf_log_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         fnd_file.put_line (fnd_file.LOG, 'After Create File Proc');

         IF NVL (x_ret_code, 0) <> 0
         THEN
            RAISE x_pf_error;
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'write_org_file ->' || x_ret_code
                              );

    EXCEPTION
    WHEN OTHERS THEN
       l_succ_flag := 'N';
       x_retcode := SQLCODE;
       l_error_message := 'Error in the procedure While processing' || l_file_name  || SQLERRM  ;
       x_errbuff := l_error_message;
       fnd_file.put_line (fnd_file.LOG, l_error_message);

    END hr_pf_pos_holder_data;

 -- functionto return HR person of an Employee


FUNCTION get_hr_person(p_person_id IN NUMBER, p_eff_date IN DATE)
RETURN NUMBER
AS

CURSOR c_hr_rep(p_reporting_org IN VARCHAR2,p_location_id IN NUMBER)
IS
SELECT pci.value person_id
     from pay_user_column_instances_f pci
     ,pay_user_rows_f pur
     ,pay_user_columns puc
     ,pay_user_tables put
    WHERE  pci.user_row_id = pur.user_row_id
    AND pci.user_column_id = puc.user_column_id
    AND puc.user_table_id = put.user_table_id
    AND put.user_table_name = 'INTG_HR_REPORTING_ORG'
    AND pur.row_low_range_or_name <> 'Executive'
    AND puc.user_column_name = p_reporting_org
    AND p_eff_date between pur.effective_start_date and pur.effective_end_date
    AND p_eff_date between pci.effective_start_date and pci.effective_end_date
    --AND pci.VALUE = pp.person_id)
    and exists (select 1
         from  hr_locations_all hla
    ,hr_location_extra_info hlei
    where hla.location_id=hlei.location_id
    and hla.location_id=p_location_id
    and hlei.lei_information1 =pci.VALUE
    AND hlei.information_type = 'INTG_HR_Location_Security'
        );

CURSOR csr_emp_hier(p_person_id IN NUMBER)
IS
 SELECT     (SELECT person_id
                       FROM per_all_people_f
                      WHERE person_id = paf.person_id
                        AND p_eff_date BETWEEN effective_start_date
                                        AND effective_end_date) tree
               FROM per_all_assignments_f paf
         START WITH paf.person_id = p_person_id
                AND paf.primary_flag = 'Y'
                AND p_eff_date BETWEEN paf.effective_start_date
                                AND paf.effective_end_date
         CONNECT BY paf.person_id = PRIOR paf.supervisor_id
                AND paf.primary_flag = 'Y'
                AND p_eff_date BETWEEN paf.effective_start_date
                                AND paf.effective_end_date;


l_reporting_org VARCHAR2(200);
l_location_id NUMBER(10);
l_hr_rep_person_id NUMBER(10);
l_found_flag      VARCHAR2 (1)   := 'N';
l_hr_person_type VARCHAR2(20);
l_person_type VARCHAR2(20);
l_actual_person_id NUMBER(10);

BEGIN

     BEGIN

        l_reporting_org := xxintg_hr_get_reporting_org.get_reporting_org(p_person_id,p_eff_date);

         BEGIN
             select location_id
             into l_location_id
             from per_all_assignments_f
             where person_id=p_person_id
            and primary_flag = 'Y'
            and assignment_type = 'E'
             and p_eff_date between effective_start_date and effective_end_date;
         EXCEPTION
             when others then
             l_location_id := NULL;
             fnd_file.put_line (fnd_file.LOG, 'Exception when retrieving location in ger_hr_rep function for person id: ' || p_person_id||SQLERRM);
         END;

         l_hr_rep_person_id := NULL;

           FOR rec_hr_rep IN c_hr_rep(l_reporting_org,l_location_id)
         LOOP
             l_hr_rep_person_id :=  rec_hr_rep.person_id;

             IF l_hr_rep_person_id IS NOT NULL THEN
                EXIT;
             END IF;
         END LOOP;


         l_actual_person_id := l_hr_rep_person_id;



     EXCEPTION
             WHEN OTHERS THEN
             l_actual_person_id := NULL;
     END;
    RETURN l_actual_person_id;
END get_hr_person;

-- If the derived HR person is a Contingent worker then this function will nvaigate thr supervisor heirarchy and will
-- get the next superviosr in heirarchy who is a full time employee
FUNCTION get_next_hr_emp(p_hr_person_id IN NUMBER, p_eff_date IN DATE)
RETURN NUMBER
IS

l_found_flag      VARCHAR2 (1)   := 'N';
l_hr_person_type VARCHAR2(20);
l_person_type VARCHAR2(20);
l_actual_person_id NUMBER(10);


CURSOR csr_emp_hier(p_person_id IN NUMBER)
IS
 SELECT     (SELECT person_id
                       FROM per_all_people_f
                      WHERE person_id = paf.person_id
                        AND p_eff_date BETWEEN effective_start_date
                                        AND effective_end_date) tree
               FROM per_all_assignments_f paf
         START WITH paf.person_id = p_person_id
                AND paf.primary_flag = 'Y'
                AND p_eff_date BETWEEN paf.effective_start_date
                                AND paf.effective_end_date
         CONNECT BY paf.person_id = PRIOR paf.supervisor_id
                AND paf.primary_flag = 'Y'
                AND p_eff_date BETWEEN paf.effective_start_date
                                AND paf.effective_end_date;

cursor csr_person_type(p_person_id IN NUMBER)
is
    select ppt.system_person_type
    from per_person_types ppt
    ,per_person_type_usages_f pptuf
    ,per_all_people_f papf
    where ppt.person_type_id=pptuf.person_type_id
    and papf.person_id=pptuf.person_id
    and papf.person_id=p_person_id
    and p_eff_date between papf.effective_start_date and papf.effective_end_date
    and p_eff_date between pptuf.effective_start_date and pptuf.effective_end_date;

BEGIN
    FOR rec_emp_hier IN csr_emp_hier(p_hr_person_id)
    LOOP
        IF rec_emp_hier.tree <> p_hr_person_id THEN

            IF l_found_flag  = 'N' THEN

                OPEN csr_person_type(rec_emp_hier.tree);
                FETCH csr_person_type INTO l_hr_person_type;
                CLOSE csr_person_type;

                IF nvl(l_hr_person_type,'XXX') = 'EMP' THEN
                l_found_flag  := 'Y';
                l_actual_person_id := rec_emp_hier.tree;
                EXIT;
                END IF;
            ELSE
                EXIT;
            END IF;
        END IF;
    END LOOP;

    RETURN l_actual_person_id;
EXCEPTION
    WHEN OTHERS THEN
    l_actual_person_id := NULL;
    RETURN l_actual_person_id;
END get_next_hr_emp;

-- Procedure for fetching Position HR relationship Data for 22_Position HR Relationship file
PROCEDURE hr_pf_pos_hr_data(x_errbuff OUT VARCHAR2,
                                 x_retcode OUT NUMBER,
                                 p_eff_date IN DATE,
                                 p_file_name IN NUMBER) IS

    l_program_num NUMBER;
    l_succ_flag VARCHAR2(1);
    l_Phone_Label VARCHAR2(25);
    l_email_add  VARCHAR2(250);
    l_error_message VARCHAR2(2500) := '';

    l_file_name   VARCHAR2 (100) :='22_Position_HR_Relationship';
    x_pf_error        EXCEPTION;
    x_ret_code        NUMBER    := 0;
    x_err_msg         VARCHAR2 (3000);
    l_position_id  NUMBER(10);
    l_hr_person_type VARCHAR2(30);
    l_next_hrper_id number(10);
    l_hr_person_id number(10);
    l_hr_position_id number(10);
    l_emp_number varchar2(30);
    l_pre_pos_id number(10) := 0;
    l_pre_hr_pos_id number(10) := 0;
    l_pre_reln_type varchar2(50) := 'XXXX';
    l_pre_hr_emp_number varchar2(30) := 'XXXX';

     CURSOR c_position IS
        select  paaf.position_id position_id
        ,'PERFORMANCE_HR' HRelationshipType
        ,paaf.person_id
        ,paaf.assignment_number
        ,hlei.lei_information1 HR_REP
        ,hla.location_code
        from per_all_assignments_f paaf
        ,hr_locations_all hla
        ,hr_location_extra_info hlei
        ,pay_user_column_instances_f pci
        ,pay_user_rows_f pur
        ,pay_user_columns puc
        ,pay_user_tables put
        where paaf.location_id=hla.location_id
        and hla.location_id=hlei.location_id
        and hlei.lei_information1 = pci.VALUE
        and pci.user_row_id = pur.user_row_id
        AND pci.user_column_id = puc.user_column_id
        AND puc.user_table_id = put.user_table_id
        AND put.user_table_name = 'INTG_HR_REPORTING_ORG'
        and  puc.user_column_name = xxintg_hr_get_reporting_org.get_reporting_org(paaf.person_id,p_eff_date)
        AND pur.row_low_range_or_name <> 'Executive'
        AND hlei.information_type = 'INTG_HR_Location_Security'
        and paaf.assignment_type in ('E')
        and paaf.primary_flag ='Y'
        and paaf.assignment_status_type_id <> 3
        and p_eff_date between paaf.effective_start_date and paaf.effective_end_date
        and p_eff_date BETWEEN pci.effective_start_date AND pci.effective_end_date
        and p_eff_date BETWEEN pur.effective_start_date AND pur.effective_end_date
      UNION
      select paaf.position_id position_id
        ,'COMPENSATION_HR' HRelationshipType
        ,paaf.person_id
        ,paaf.assignment_number
        ,hlei.lei_information1 HR_REP
        ,hla.location_code
        from per_all_assignments_f paaf
        ,hr_locations_all hla
        ,hr_location_extra_info hlei
        ,pay_user_column_instances_f pci
        ,pay_user_rows_f pur
        ,pay_user_columns puc
        ,pay_user_tables put
        where paaf.location_id=hla.location_id
        and hla.location_id=hlei.location_id
        and hlei.lei_information1 IN (select a.person_id
                                          from per_all_people_f a
                                          ,per_all_assignments_f b
                                          where a.person_id=b.person_id
                                          and b.assignment_type IN ('E','C')
                                          and b.primary_flag = 'Y'
                                          and b.assignment_status_type_id <> 3
                                          and a.employee_number IN (select lookup_code
                                                                 from fnd_lookup_values flv
                                                                 where lookup_type = 'INTG_PF_HR_REL_SUPERVISORS'
                                                                 and enabled_flag = 'Y'
                                                                 and p_eff_date between nvl(flv.start_date_active,to_date('01-JAN-1951','DD-MON-YYYY'))
                                                                        and nvl(flv.end_date_active,to_date('31-DEC-4712','DD-MON-YYYY'))
                                                                 )
                                          and p_eff_date BETWEEN a.effective_start_date AND a.effective_end_date
                                          and p_eff_date BETWEEN b.effective_start_date AND b.effective_end_date
                                          )
        and hlei.lei_information1 = pci.VALUE
        and pci.user_row_id = pur.user_row_id
        AND pci.user_column_id = puc.user_column_id
        AND puc.user_table_id = put.user_table_id
        AND put.user_table_name = 'INTG_HR_REPORTING_ORG'
        and  puc.user_column_name = xxintg_hr_get_reporting_org.get_reporting_org(paaf.person_id,trunc(sysdate))
        AND pur.row_low_range_or_name <> 'Executive'
        AND hlei.information_type = 'INTG_HR_Location_Security'
        and paaf.assignment_type in ('E')
        and paaf.primary_flag ='Y'
        and paaf.assignment_status_type_id <> 3
        and p_eff_date between paaf.effective_start_date and paaf.effective_end_date
        and p_eff_date BETWEEN pci.effective_start_date AND pci.effective_end_date
        and p_eff_date BETWEEN pur.effective_start_date AND pur.effective_end_date
      UNION
        select paaf.position_id position_id
        ,'MATRIX_MANAGER' HRelationshipType
        ,paaf.person_id
        ,paaf.assignment_number
        ,hlei.lei_information1 HR_REP
        ,hla.location_code
        from per_all_assignments_f paaf
        ,hr_locations_all hla
        ,hr_location_extra_info hlei
        ,pay_user_column_instances_f pci
        ,pay_user_rows_f pur
        ,pay_user_columns puc
        ,pay_user_tables put
        where paaf.location_id=hla.location_id
        and hla.location_id=hlei.location_id
        and hlei.lei_information1 IN (select a.person_id
                                          from per_all_people_f a
                                          ,per_all_assignments_f b
                                          where a.person_id=b.person_id
                                          and b.assignment_type IN ('E','C')
                                          and b.primary_flag = 'Y'
                                          and b.assignment_status_type_id <> 3
                                          and a.employee_number NOT IN (select lookup_code
                                                                 from fnd_lookup_values flv
                                                                 where lookup_type = 'INTG_PF_HR_REL_SUPERVISORS'
                                                                 and enabled_flag = 'Y'
                                                                 and p_eff_date between nvl(flv.start_date_active,to_date('01-JAN-1951','DD-MON-YYYY'))
                                                                        and nvl(flv.end_date_active,to_date('31-DEC-4712','DD-MON-YYYY'))
                                                                 )
                                          and p_eff_date BETWEEN a.effective_start_date AND a.effective_end_date
                                          and p_eff_date BETWEEN b.effective_start_date AND b.effective_end_date
                                          )
        and hlei.lei_information1 = pci.VALUE
        and pci.user_row_id = pur.user_row_id
        AND pci.user_column_id = puc.user_column_id
        AND puc.user_table_id = put.user_table_id
        AND put.user_table_name = 'INTG_HR_REPORTING_ORG'
        and  puc.user_column_name = xxintg_hr_get_reporting_org.get_reporting_org(paaf.person_id,p_eff_date)
        AND pur.row_low_range_or_name <> 'Executive'
        AND hlei.information_type = 'INTG_HR_Location_Security'
        and paaf.assignment_type in ('E')
        and paaf.primary_flag ='Y'
        and paaf.assignment_status_type_id <> 3
        and p_eff_date between paaf.effective_start_date and paaf.effective_end_date
        and p_eff_date BETWEEN pci.effective_start_date AND pci.effective_end_date
        and p_eff_date BETWEEN pur.effective_start_date AND pur.effective_end_date
        order by 1;

    BEGIN
       fnd_file.put_line (fnd_file.log,'+--------------------------------------------------------------------------------+');
       fnd_file.put_line (fnd_file.log,'+-----------------------INTG PF Postion HR Relationship Data Extraction-------------------------+');
       fnd_file.put_line (fnd_file.log,'Parameters Passed');
       fnd_file.put_line (fnd_file.log,'Effective Date: '||p_eff_date);
       fnd_file.put_line (fnd_file.log,'File Name: '||p_file_name);

           DELETE FROM INTG_HR_PF_POS_HR_RELSHIP;
           commit;

            FOR rec_position IN c_position
            LOOP
               l_succ_flag :='Y';
               l_error_message :='';


               BEGIN
                   SELECT distinct sourcesysrefkey
                   INTO l_position_id
                   FROM intg_hr_pf_pos_data
                   WHERE error_flag='S'
                   AND  sourcesysrefkey = rec_position.position_id
                   and rec_position.position_id IS NOT NULL;

               EXCEPTION WHEN NO_DATA_FOUND THEN
                   l_succ_flag :='N';
                   l_error_message := l_error_message || ' position_id ' || rec_position.position_id || ' is in 17(a)_Positions Error Log' ;
               END;

               IF rec_position.position_id IS NULL THEN
                    l_succ_flag :='N';
                    l_error_message := 'Person ID-'||rec_position.person_id|| ' this person does not have any position assigned';
               END IF;


                l_hr_person_id := NULL;
                l_hr_person_type := NULL;
                l_next_hrper_id := NULL;
                l_hr_position_id := NULL;
                l_emp_number := NULL;



                BEGIN
                    select ppt.system_person_type
                    into l_hr_person_type
                    from per_person_types ppt
                    ,per_person_type_usages_f pptuf
                    ,per_all_people_f papf
                    where ppt.person_type_id=pptuf.person_type_id
                    and papf.person_id=pptuf.person_id
                    and papf.person_id=rec_position.hr_rep
                    and p_eff_date between papf.effective_start_date and papf.effective_end_date
                    and p_eff_date between pptuf.effective_start_date and pptuf.effective_end_date;
                EXCEPTION
                    when others then
                    l_hr_person_type := NULL;
                END;

                -- If HR is a Conginet Worker get the Next HR person
                IF l_hr_person_type = 'CWK' THEN
                    l_next_hrper_id := get_next_hr_emp(rec_position.hr_rep,p_eff_date);
                ELSE
                    l_next_hrper_id := rec_position.hr_rep;
                END IF;

                -- Logic to derive HR postion id and Employee Number
                BEGIN
                    select paaf.position_id
                          ,papf.employee_number
                    into l_hr_position_id
                        ,l_emp_number
                    from per_all_assignments_f paaf
                        ,per_all_people_f papf
                    where paaf.person_id=papf.person_id
                    and paaf.person_id = l_next_hrper_id
                    and paaf.primary_flag = 'Y'
                    and paaf.assignment_type = 'E'
                    and paaf.assignment_status_type_id <> 3
                    and p_eff_date between papf.effective_start_date and papf.effective_end_date
                    and p_eff_date between paaf.effective_start_date and paaf.effective_end_date;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_hr_position_id := NULL;
                        l_emp_number := NULL;
                        fnd_file.put_line (fnd_file.LOG, 'Exception in getting HR Persons position and emp number-'||rec_position.person_id);
                END;

                IF  l_hr_position_id IS NULL OR l_emp_number IS NULL THEN
                    l_succ_flag :='N';
                    l_error_message := 'Could not retieve HR Reps position and employee number. Please check whether supervisor and reporting org is assgined to person ID-'||rec_position.person_id;
                END IF;


                   BEGIN

                      INSERT INTO INTG_HR_PF_POS_HR_RELSHIP
                      (DOCUMENTTYPE,
                      SENDERID,
                      RECEIVERID,
                      VERSION,
                      ID    ,
                      SOURCESYSREFKEY,
                      HRRELATIONSHIPTYPE ,
                      POSITIONSOURCESYSREFKEY ,
                      EMPLOYEESOURCESYSREFKEY,
                      CLEARCOLLECTION,
                      LAST_UPDATE_DATE,
                      LAST_UPDATED_BY,
                      LAST_UPDATE_LOGIN,
                      CREATION_DATE,
                      CREATED_BY,
                      REQUEST_ID,
                      STATUS_CODE,
                      ERROR_MESG)
                     VALUES
                     ( 'AuthoriaPositionHRRelationships',
                     '948439432',
                     '178675716',
                     '1.22.110200',
                      NULL,
                      rec_position.position_id,
                      rec_position.HRelationshipType,
                      --l_hr_position_id,
                      NULL,
                      l_emp_number,
                      1,
                      SYSDATE,
                      g_user_id,
                      g_login_id,
                      SYSDATE,
                      g_user_id,
                      g_request_id,
                      decode(l_succ_flag,'N','E','S'),
                      l_error_message
                      );
                   COMMIT;
                   EXCEPTION
                   WHEN OTHERS THEN
                      l_succ_flag := 'N';
                      x_retcode := SQLCODE;
                      l_error_message := 'ERROR WHILE INSERTING INTO STAGING TABLE: ' || SQLERRM ||' FOR Position HR for Employee: ' ||rec_position.position_id ;
                      x_errbuff := l_error_message;
                      fnd_file.put_line (fnd_file.LOG, l_error_message);
                   END;


            END LOOP;

         x_ret_code := NULL;
         x_err_msg := NULL;

         create_pf_file (p_file_name, l_file_name, x_ret_code, x_err_msg);


         create_pf_err_file (p_file_name, l_file_name, x_ret_code, x_err_msg);


         create_pf_log_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         fnd_file.put_line (fnd_file.LOG, 'After Create File Proc');

         IF NVL (x_ret_code, 0) <> 0
         THEN
            RAISE x_pf_error;
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'write_org_file ->' || x_ret_code
                              );

    EXCEPTION
    WHEN OTHERS THEN
       l_succ_flag := 'N';
       x_retcode := SQLCODE;
       l_error_message := 'Error in the procedure While processing' || l_file_name  || SQLERRM  ;
       x_errbuff := l_error_message;
       fnd_file.put_line (fnd_file.LOG, l_error_message);

    END hr_pf_pos_hr_data;


-- Procedure for fetching Incentive data for 28_EE Incentive Plan Code file
   PROCEDURE hr_pf_incentive_data(x_errbuff OUT VARCHAR2,
                                 x_retcode OUT NUMBER,
                                 p_eff_date IN DATE,
                                 p_file_name IN NUMBER) IS

    l_program_num NUMBER;
    l_succ_flag VARCHAR2(1);
    l_Phone_Label VARCHAR2(25);
    l_email_add  VARCHAR2(250);
    l_error_message VARCHAR2(2500) := '';

    l_file_name   VARCHAR2 (100) :='28_EE_Incentive_Plan_Code';
    x_pf_error        EXCEPTION;
    x_ret_code        NUMBER    := 0;
    x_err_msg         VARCHAR2 (3000);

     CURSOR c_incentive IS
           SELECT papf.employee_number,
               ppg.segment1,
               min(paaf.effective_start_date)  start_date,
               Decode(Max(Paaf.Effective_End_Date), to_Date('31-DEC-4712','DD-MON-YYYY'),'',Max(Paaf.Effective_End_Date)) end_date
        FROM   apps.per_all_people_f papf
              ,apps.per_person_type_usages_f p1
              ,apps.per_person_types p2
              ,apps.per_all_assignments_f paaf
              ,apps.pay_people_groups ppg
        WHERE 1=1
        AND p_eff_date BETWEEN papf.effective_start_date AND papf.effective_end_date
       -- AND p_eff_date BETWEEN paaf.effective_start_date AND paaf.effective_end_date
        AND NVL(UPPER(papf.attribute5),'YES')!='NO'
        AND p_eff_date between p1.effective_start_date and p1.effective_end_date
        AND Paaf.Effective_Start_Date      <= p_eff_date
        AND p1.person_type_id = p2.person_type_id
        AND p2.system_person_type in ('EMP')
        AND paaf.Assignment_type ='E'
        AND paaf.primary_flag  = 'Y'
        AND paaf.assignment_status_type_id <> 3
        AND papf.person_id = p1.person_id
        AND papf.person_id =paaf.person_id
        AND paaf.people_group_id = ppg.people_group_id
        AND ppg.segment1  IS NOT NULL
        AND ppg.enabled_flag = 'Y'
        GROUP BY paaf.assignment_id,
            Papf.Employee_Number,
            ppg.segment1;

    BEGIN
       fnd_file.put_line (fnd_file.log,'+--------------------------------------------------------------------------------+');
       fnd_file.put_line (fnd_file.log,'+-----------------------INTG PF 28_EE Incentive Plan Code Data Extraction-------------------------+');
       fnd_file.put_line (fnd_file.log,'Parameters Passed');
       fnd_file.put_line (fnd_file.log,'Effective Date: '||p_eff_date);
       fnd_file.put_line (fnd_file.log,'File Name: '||p_file_name);

           DELETE FROM INTG_HR_PF_INCENTIVE_PLAN;
           commit;
           fnd_file.put_line (fnd_file.log,'Deleted table INTG_HR_PF_INCENTIVE_PLAN');

            FOR rec_incentive IN c_incentive
            LOOP
               l_succ_flag :='Y';
               l_error_message :='';

               BEGIN
                   SELECT 'N'
                   INTO l_succ_flag
                   FROM INTG_HR_PF_PERSONS
                   WHERE status_code='E'
                  -- AND  person_id = rec_incentive.person_id
                   AND  sourcesysrefkey = rec_incentive.employee_number;

                l_error_message := ' Employee is in 5_Persons Error Log : '|| rec_incentive.employee_number ;
               EXCEPTION WHEN NO_DATA_FOUND THEN
                   l_succ_flag :='Y';
               END;

              -- fnd_file.put_line (fnd_file.LOG, 'before insert into employee table' );

                   BEGIN

                      INSERT INTO INTG_HR_PF_INCENTIVE_PLAN
                      (DOCUMENTTYPE,
                      SENDERID,
                      RECEIVERID,
                      VERSION,
                      ID    ,
                      EMPLOYEESOURCESYSREFKEY,
                      EFFECTIVEDATE,
                      PLANCODE,
                      PLANCODESOURCESYSREFKEY,
                      DESCRIPTION,
                      CATEGORY,
                      ENDDATE,
                      CLEARCOLLECTION,
                      PERSON_ID,
                      LAST_UPDATE_DATE,
                      LAST_UPDATED_BY,
                      LAST_UPDATE_LOGIN,
                      CREATION_DATE,
                      CREATED_BY,
                      REQUEST_ID,
                      STATUS_CODE,
                      ERROR_MESG)
                     VALUES
                     ( 'AuthoriaEmployeeIncentivePlanCode',
                     '948439432',
                     '178675716',
                     '1.22.110200',
                      NULL,
                      rec_incentive.employee_number,
                      rec_incentive.start_date,
                      rec_incentive.segment1,
                      NULL,
                      NULL,
                      'Incentive_Level',
                      rec_incentive.end_date,
                      1,
                      NULL,
                      SYSDATE,
                      g_user_id,
                      g_login_id,
                      SYSDATE,
                      g_user_id,
                      g_request_id,
                      decode(l_succ_flag,'N','E','S'),
                      l_error_message
                      );
                   --fnd_file.put_line (fnd_file.LOG, 'Succesfully inserted');
                   COMMIT;
                   EXCEPTION
                   WHEN OTHERS THEN
                      l_succ_flag := 'N';
                      x_retcode := SQLCODE;
                      l_error_message := 'ERROR WHILE INSERTING INTO STAGING TABLE' || SQLERRM ||' FOR : 28_EE Incentive Plan Code: ' ||rec_incentive.employee_number ;
                      x_errbuff := l_error_message;
                      fnd_file.put_line (fnd_file.LOG, l_error_message);
                   END;


          END LOOP;

         x_ret_code := NULL;
         x_err_msg := NULL;

         create_pf_file (p_file_name, l_file_name, x_ret_code, x_err_msg);


         create_pf_err_file (p_file_name, l_file_name, x_ret_code, x_err_msg);


         create_pf_log_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         fnd_file.put_line (fnd_file.LOG, 'After Create File Proc');

         IF NVL (x_ret_code, 0) <> 0
         THEN
            RAISE x_pf_error;
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'write_org_file ->' || x_ret_code
                              );

    EXCEPTION
    WHEN OTHERS THEN
       l_succ_flag := 'N';
       x_retcode := SQLCODE;
       l_error_message := 'Error in the procedure While processing' || l_file_name  || SQLERRM  ;
       x_errbuff := l_error_message;
       fnd_file.put_line (fnd_file.LOG, l_error_message);

    END hr_pf_incentive_data;

-- Procedure for fetching Salary History data for 36_EE Salary History file
    PROCEDURE hr_pf_salary_data(x_errbuff OUT VARCHAR2,
                                 x_retcode OUT NUMBER,
                                 p_eff_date IN DATE,
                                 p_file_name IN NUMBER) IS

    l_program_num NUMBER;
    l_succ_flag VARCHAR2(1);
    l_Phone_Label VARCHAR2(25);
    l_email_add  VARCHAR2(250);
    l_error_message VARCHAR2(2500) := '';

    l_file_name   VARCHAR2 (100) :='36_EE_Salary_History';
    x_pf_error        EXCEPTION;
    x_ret_code        NUMBER    := 0;
    x_err_msg         VARCHAR2 (3000);
    l_person_id   NUMBER;
    l_percent_inc  NUMBER(15,6);
    l_increase_amount NUMBER(15,6) :=0;
    l_increase_amount_c  NUMBER(15,6) :=0;
    j NUMBER;

     CURSOR c_salary IS
            SELECT
            papf.person_id,
            papf.employee_number,
            paaf.assignment_id,
            paaf.position_id,
            paaf.effective_start_date,
            paaf.effective_end_date,
            ppp.pay_proposal_id,
            ppp.Change_Date change_date,
            TO_CHAR(ppp.Change_Date, 'YYYY') change_year,
            ppp.Proposal_Reason,
            ppp.Proposed_Salary_N proposed_salary,
            petf.Input_Currency_Code currency,
            ppb.pay_annualization_factor pay_type_fact,
            hr_general.decode_lookup('INTG_PF_ORA_PAY_BASIS_CONV',ppb.pay_annualization_factor) pay_type,
            (SELECT ppp1.Proposed_Salary_N
             FROM  apps.per_pay_proposals ppp1,
                   apps.per_all_assignments_f paaf1
             WHERE 1                 =1
             AND paaf1.Assignment_Id = Ppp1.Assignment_Id
             AND TRUNC(Ppp1.Change_Date)BETWEEN paaf1.Effective_Start_Date AND paaf1.Effective_End_Date
             AND paaf1.Assignment_Type = 'E'
             AND paaf1.Primary_Flag    = 'Y'
             AND Ppp1.Approved         = 'Y'
             AND paaf1.Person_Id       = paaf.Person_Id
             AND ppp1.Change_DATE      =
              (SELECT MAX(ppp2.Change_Date)
              FROM Apps.Per_Pay_Proposals ppp2,
                Apps.Per_All_Assignments_F paaf2
              WHERE 1                 =1
              AND paaf2.Assignment_Id = Ppp2.Assignment_Id
              AND TRUNC(Ppp2.Change_Date)BETWEEN paaf2.Effective_Start_Date AND paaf2.Effective_End_Date
              AND paaf2.Assignment_Type = 'E'
              AND Paaf2.Primary_Flag    = 'Y'
              AND ppp2.Approved         = 'Y'
              AND paaf2.Person_Id       = Paaf1.Person_Id
              AND ppp2.Change_Date      < ppp.Change_Date
              )
            ) Previous_Salary
            FROM apps.per_all_people_f papf
                ,apps.per_all_assignments_f paaf
                ,apps.Per_Pay_Proposals ppp
                ,apps.Per_pay_bases ppb
                ,apps.pay_element_types_f petf
                ,apps.pay_input_values_f pivf
                ,apps.per_person_type_usages_f p1
                ,apps.per_person_types p2
            WHERE  papf.person_id    = paaf.person_id
            AND   ppp.Assignment_Id  = paaf. Assignment_Id
            AND   paaf.Pay_Basis_Id  = ppb.Pay_Basis_Id
            AND   ppb.input_value_id   = pivf.input_value_id
            AND   pivf.element_type_id = petf.element_type_id
            AND NVL(UPPER(papf.attribute5),'YES')!='NO'
            AND papf.current_employee_flag = 'Y'
            AND p_eff_date BETWEEN papf.effective_start_date AND papf.effective_end_date
         --   AND :p_eff_date BETWEEN paaf.effective_start_date AND paaf.effective_end_date
            AND p_eff_date BETWEEN p1.effective_start_date AND p1.effective_end_date
            AND TRUNC(ppp.Change_Date)BETWEEN paaf.effective_start_date AND paaf.effective_end_date
            AND p1.person_type_id = p2.person_type_id
            AND p2.system_person_type in ('EMP')
            AND papf.person_id = p1.person_id
            AND paaf.primary_flag = 'Y'
            AND paaf.assignment_type = 'E'
            AND paaf.assignment_status_type_id <> 3
            AND ppp.Approved         = 'Y'
            AND ppp.Change_Date <= p_eff_date
            order by papf.person_id    ;

           CURSOR c_pay_comp(p_proposal_id NUMBER) IS
           SELECT ppc.component_reason,
                  ppc.change_amount_n,
                  ppc.change_percentage,
                  ppp.change_date,
                  ppp.proposed_salary_n
           FROM per_pay_proposal_components ppc,
                       per_pay_proposals ppp
           WHERE   ppp.pay_proposal_id = ppc.pay_proposal_id
           AND  ppp.pay_proposal_id = p_proposal_id ;

           rec_pay_comp   c_pay_comp%ROWTYPE;

           TYPE tab_comptype IS TABLE OF c_pay_comp%ROWTYPE
           INDEX BY BINARY_INTEGER;

           comp_tab tab_comptype;

    BEGIN
       fnd_file.put_line (fnd_file.log,'+--------------------------------------------------------------------------------+');
       fnd_file.put_line (fnd_file.log,'+-----------------------INTG PF 36_EE Salary History Data Extraction-------------------------+');
       fnd_file.put_line (fnd_file.log,'Parameters Passed');
       fnd_file.put_line (fnd_file.log,'Effective Date: '||p_eff_date);
       fnd_file.put_line (fnd_file.log,'File Name: '||p_file_name);

           DELETE FROM INTG_HR_PF_EE_SAL_HIS;
           commit;
           fnd_file.put_line (fnd_file.log,'Deleted table INTG_HR_PF_EE_SAL_HIS');

            FOR rec_salary IN c_salary
            LOOP
               l_succ_flag :='Y';
               l_error_message :='';
               l_increase_amount := NULL;
               l_increase_amount_c := NULL;
               l_percent_inc:= NULL;

               BEGIN
                   SELECT distinct person_id
                   INTO l_person_id
                   FROM INTG_HR_PF_PERSONS
                   WHERE status_code='S'
                   AND  person_id = rec_salary.person_id
                   AND  sourcesysrefkey = rec_salary.employee_number;

               EXCEPTION WHEN NO_DATA_FOUND THEN
                   l_succ_flag :='N';
                   l_error_message := ' Employee is in 5_Persons Error Log : '|| rec_salary.employee_number ;
               END;

              -- fnd_file.put_line (fnd_file.log,'rec_salary.proposed_salary' || rec_salary.proposed_salary);

               l_increase_amount := nvl((rec_salary.proposed_salary - rec_salary.previous_salary),0);

               l_increase_amount_c := nvl((rec_salary.proposed_salary - nvl(rec_salary.previous_salary,0)),0); --Added to to match with what was sent last year

               IF rec_salary.previous_salary = 0 OR rec_salary.previous_salary IS NULL THEN
                l_percent_inc := 0;
               ELSE
                l_percent_inc := ROUND(nvl(l_increase_amount/rec_salary.previous_salary,0),6) ;
               END IF;



                 FOR i in 1..10 LOOP
                    comp_tab(i).component_reason := NULL;
                    comp_tab(i).change_amount_n := NULL;
                    comp_tab(i).change_percentage := NULL;
                  END LOOP;

                  j := 1;
                  FOR rec_pay_comp IN c_pay_comp(rec_salary.pay_proposal_id)
                  LOOP

                            comp_tab(j).component_reason := rec_pay_comp.component_reason;
                            comp_tab(j).change_amount_n := NVL(rec_pay_comp.change_amount_n,0);
                            comp_tab(j).change_percentage := NVL(rec_pay_comp.change_percentage,0)/100; -- Added to to match with what was sent last year
                            j := j+1 ;

                  END LOOP;


                   BEGIN

                      INSERT INTO INTG_HR_PF_EE_SAL_HIS
                      (
                        DocumentType,
                        SenderId,
                        ReceiverId,
                        Version,
                        Id,
                        EmployeeSourceSysRefKey,
                        SalaryHistorySourceSysRefKey,
                        EffectiveDate,
                        PlanYear,
                        CurrencyCode,
                        SalaryRate,
                        IncreaseAmount,
                        SalaryPeriodType,
                        LumpSum,
                        ProrationFactor,
                        FTE,
                        Grade,
                        GradeStructure,
                        GradeSetName,
                        MarketStructure,
                        MarketSetName,
                        IncreasePercentage,
                        SalaryGradeSSRK,
                        SalaryIncDetail1IncPercentage,
                        SalaryIncDetail1Increason,
                        SalaryIncDetail1IncAmt,
                        SalaryIncDetail1CPDSeqNumber,
                        SalaryIncDet1CPDDefaultIncAmt,
                        SalaryIncDetail2IncPercentage,
                        SalaryIncDetail2Increason,
                        SalaryIncDetail2IncAmt,
                        SalaryIncDetail2CPDSeqNumber,
                        SalaryIncDet2CPDDefaultIncAmt ,
                        SalaryIncDetail3IncPercentage,
                        SalaryIncDetail3Increason ,
                        SalaryIncDetail3IncAmt,
                        SalaryIncDetail3CPDSeqNumber,
                        SalaryIncDet3CPDDefaultIncAmt ,
                        SalaryIncDetail4IncPercentage,
                        SalaryIncDetail4Increason ,
                        SalaryIncDetail4IncAmt,
                        SalaryIncDetail4CPDSeqNumber,
                        SalaryIncDet4CPDDefaultIncAmt ,
                        CPDExchangeRate,
                        CPDSalaryPlanId,
                        CPDDefaultAmt,
                        CPDDefaultIncreaseAmt,
                        ClearCollection,
                        SalaryIncDetail5IncPercentage,
                        SalaryIncDetail5Increason ,
                        SalaryIncDetail5IncAmt,
                        SalaryIncDetail5CPDSeqNumber,
                        SalaryIncDet5CPDDefaultIncAmt ,
                        SalaryIncDetail6IncPercentage,
                        SalaryIncDetail6Increason ,
                        SalaryIncDetail6IncAmt,
                        SalaryIncDetail6CPDSeqNumber,
                        SalaryIncDet6CPDDefaultIncAmt ,
                        SalaryIncDetail7IncPercentage,
                        SalaryIncDetail7Increason ,
                        SalaryIncDetail7IncAmt,
                        SalaryIncDetail7CPDSeqNumber,
                        SalaryIncDet7CPDDefaultIncAmt ,
                        SalaryIncDetail8IncPercentage,
                        SalaryIncDetail8Increason ,
                        SalaryIncDetail8IncAmt,
                        SalaryIncDet8CPDSeqNumber,
                        SalaryIncDet8CPDDefaultIncAmt ,
                        SalaryIncDetail9IncPercentage,
                        SalaryIncDetail9Increason ,
                        SalaryIncDetail9IncAmt,
                        SalaryIncDetail9CPDSeqNumber,
                        SalaryIncDet9CPDDefaultIncAmt,
                        SalaryIncDetail10IncPercentage,
                        SalaryIncDetail10Increason ,
                        SalaryIncDetail10IncAmt,
                        SalaryIncDetail10CPDSeqNumber,
                        SalaryIncDet10CPDDefaultIncAmt,
                        EndDate,
                        person_id,
                        pay_proposal_id,
                        last_update_date,
                        last_updated_by,
                        last_update_login,
                        creation_date,
                        created_by,
                        request_id,
                        status_code,
                        error_mesg)
                     VALUES
                     ( 'AuthoriaEmployeeSalaryHistories',
                     '948439432',
                     '178675716',
                     '1.22.110200',
                      NULL,
                      rec_salary.employee_number,
                      NULL,
                      rec_salary.change_date,
                      rec_salary.change_year,
                      rec_salary.currency,
                      rec_salary.proposed_salary,
                      l_increase_amount,
                      rec_salary.pay_type,
                      0,
                      NULL,
                      1,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      l_percent_inc,
                      NULL,
                      nvl(comp_tab(1).change_percentage,l_percent_inc),
                      nvl(nvl(comp_tab(1).component_reason,rec_salary.Proposal_reason),'OTH'),
                      nvl(comp_tab(1).change_amount_n,l_increase_amount_c),
                      '1',
                      NULL,
                      comp_tab(2).change_percentage,
                      comp_tab(2).component_reason,
                      comp_tab(2).change_amount_n,
                      NULL,
                      NULL,
                      comp_tab(3).change_percentage,
                      comp_tab(3).component_reason,
                      comp_tab(3).change_amount_n,
                      NULL,
                      NULL,
                      comp_tab(4).change_percentage,
                      comp_tab(4).component_reason,
                      comp_tab(4).change_amount_n,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      1,
                      comp_tab(5).change_percentage,
                      comp_tab(5).component_reason,
                      comp_tab(5).change_amount_n,
                      NULL,
                      NULL,
                      comp_tab(6).change_percentage,
                      comp_tab(6).component_reason,
                      comp_tab(6).change_amount_n,
                      NULL,
                      NULL,
                      comp_tab(7).change_percentage,
                      comp_tab(7).component_reason,
                      comp_tab(7).change_amount_n,
                      NULL,
                      NULL,
                      comp_tab(8).change_percentage,
                      comp_tab(8).component_reason,
                      comp_tab(8).change_amount_n,
                      NULL,
                      NULL,
                      comp_tab(9).change_percentage,
                      comp_tab(9).component_reason,
                      comp_tab(9).change_amount_n,
                      NULL,
                      NULL,
                      comp_tab(10).change_percentage,
                      comp_tab(10).component_reason,
                      comp_tab(10).change_amount_n,
                      NULL,
                      NULL,
                      NULL,
                      rec_salary.person_id,
                      rec_salary.pay_proposal_id,
                      SYSDATE,
                      g_user_id,
                      g_login_id,
                      SYSDATE,
                      g_user_id,
                      g_request_id,
                      decode(l_succ_flag,'N','E','S'),
                      l_error_message
                      );

                --   fnd_file.put_line (fnd_file.LOG, 'Succesfully inserted');
                   COMMIT;
                   EXCEPTION
                   WHEN OTHERS THEN
                      l_succ_flag := 'N';
                      x_retcode := SQLCODE;
                      l_error_message := 'ERROR WHILE INSERTING INTO STAGING TABLE' || SQLERRM ||' FOR : 36_EE Salary History: ' ||rec_salary.employee_number ;
                      x_errbuff := l_error_message;
                      fnd_file.put_line (fnd_file.LOG, l_error_message);
                   END;


          END LOOP;

         x_ret_code := NULL;
         x_err_msg := NULL;

          create_pf_file (p_file_name, l_file_name, x_ret_code, x_err_msg);


         create_pf_err_file (p_file_name, l_file_name, x_ret_code, x_err_msg);


        create_pf_log_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         fnd_file.put_line (fnd_file.LOG, 'After Create File Proc');

         IF NVL (x_ret_code, 0) <> 0
         THEN
            RAISE x_pf_error;
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'write_org_file ->' || x_ret_code
                              );

    EXCEPTION
    WHEN OTHERS THEN
       l_succ_flag := 'N';
       x_retcode := SQLCODE;
       l_error_message := 'Error in the procedure While processing' || l_file_name  || SQLERRM  ;
       x_errbuff := l_error_message;
       fnd_file.put_line (fnd_file.LOG, l_error_message);

    END hr_pf_salary_data;

-- Procedure to fetch Custom data for 66_Custom Fields Persons file

    PROCEDURE hr_pf_custom_data(x_errbuff OUT VARCHAR2,
                                 x_retcode OUT NUMBER,
                                 p_eff_date IN DATE,
                                 p_file_name IN NUMBER) IS

    l_program_num NUMBER;
    l_succ_flag VARCHAR2(1);
    l_Phone_Label VARCHAR2(25);
    l_email_add  VARCHAR2(250);
    l_error_message VARCHAR2(2500) := '';
    l_reporting_org  VARCHAR2(250);
    l_file_name   VARCHAR2 (100) :='66_Custom_Fields_Persons';
    x_pf_error        EXCEPTION;
    x_ret_code        NUMBER    := 0;
    x_err_msg         VARCHAR2 (3000);

     CURSOR c_custom IS
            SELECT
                papf.person_id,
                papf.employee_number,
                paaf.position_id,
                paaf.location_id,
                --hl.country,
                ftl.territory_short_name country,
                Xxintg_Hr_Get_Reporting_Org.Get_Reporting_Org(paaf.person_id,p_eff_date) reporting_org
            FROM per_all_people_f papf
                ,per_all_assignments_f paaf
                ,hr_locations hl
                ,apps.per_person_type_usages_f p1
                ,apps.per_person_types p2
                ,apps.fnd_territories_tl ftl
            WHERE  papf.person_id=paaf.person_id
            AND  paaf.location_id=hl.location_id
            AND NVL(UPPER(papf.attribute5),'YES')!='NO'
            AND papf.current_employee_flag = 'Y'
            AND p_eff_date BETWEEN papf.effective_start_date AND papf.effective_end_date
            AND p_eff_date BETWEEN paaf.effective_start_date AND paaf.effective_end_date
            AND p_eff_date BETWEEN p1.effective_start_date AND p1.effective_end_date
            AND p1.person_type_id = p2.person_type_id
            AND p2.system_person_type in ('EMP')
            AND papf.person_id = p1.person_id
            AND paaf.primary_flag = 'Y'
            AND paaf.assignment_type = 'E'
            AND paaf.assignment_status_type_id <> 3
            AND hl.country = ftl.territory_code
            and ftl.language = 'US' ;


    BEGIN
       fnd_file.put_line (fnd_file.log,'+--------------------------------------------------------------------------------+');
       fnd_file.put_line (fnd_file.log,'+-----------------------INTG PF 66_Custom Fields Persons Extraction-------------------------+');
       fnd_file.put_line (fnd_file.log,'Parameters Passed');
       fnd_file.put_line (fnd_file.log,'Effective Date: '||p_eff_date);
       fnd_file.put_line (fnd_file.log,'File Name: '||p_file_name);


           DELETE FROM INTG_HR_PF_CUSTOM_FIELDS;
           commit;

            FOR rec_custom IN c_custom
            LOOP
               l_succ_flag :='Y';
               l_error_message :='';

               BEGIN
                   SELECT 'N'
                   INTO l_succ_flag
                   FROM INTG_HR_PF_PERSONS
                   WHERE status_code='E'
                   AND  person_id = rec_custom.person_id
                   AND  sourcesysrefkey = rec_custom.employee_number;

                l_error_message := ' Employee is in 5_Persons Error Log : '|| rec_custom.employee_number ;
               EXCEPTION WHEN NO_DATA_FOUND THEN
                   l_succ_flag :='Y';
               END;


                   BEGIN

                      INSERT INTO INTG_HR_PF_CUSTOM_FIELDS
                      (DOCUMENTTYPE,
                      SENDERID,
                      RECEIVERID,
                      VERSION,
                      ID,
                      PERSONSOURCESYSREFKEY,
                      CUSTOMNAME1,
                      CUSTOMVALUE1,
                      CUSTOMNAME2,
                      CUSTOMVALUE2,
                      PERSON_ID,
                      LAST_UPDATE_DATE,
                      LAST_UPDATED_BY,
                      LAST_UPDATE_LOGIN,
                      CREATION_DATE,
                      CREATED_BY,
                      REQUEST_ID,
                      STATUS_CODE,
                      ERROR_MESG)
                     VALUES
                     ('CustomFieldsPersons',
                     '948439432',
                     '178675716',
                     '1.22.110200',
                      NULL,
                      rec_custom.employee_number,
                      'reporting_org',
                      rec_custom.reporting_org,
                      'Country',
                      rec_custom.country,
                      rec_custom.person_id,
                      SYSDATE,
                      g_user_id,
                      g_login_id,
                      SYSDATE,
                      g_user_id,
                      g_request_id,
                      decode(l_succ_flag,'N','E','S'),
                      l_error_message
                      );
                   COMMIT;
                   EXCEPTION
                   WHEN OTHERS THEN
                      l_succ_flag := 'N';
                      x_retcode := SQLCODE;
                      l_error_message := 'ERROR WHILE INSERTING INTO STAGING TABLE' || SQLERRM ||' FOR 66_Custom Fields Persons: ' ||rec_custom.employee_number ;
                      x_errbuff := l_error_message;
                      fnd_file.put_line (fnd_file.LOG, l_error_message);
                   END;


          END LOOP;

         x_ret_code := NULL;
         x_err_msg := NULL;

         create_pf_file (p_file_name, l_file_name, x_ret_code, x_err_msg);


         create_pf_err_file (p_file_name, l_file_name, x_ret_code, x_err_msg);


         create_pf_log_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         fnd_file.put_line (fnd_file.LOG, 'After Create File Proc');

         IF NVL (x_ret_code, 0) <> 0
         THEN
            RAISE x_pf_error;
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'write_org_file ->' || x_ret_code
                              );

    EXCEPTION
    WHEN OTHERS THEN
       l_succ_flag := 'N';
       x_retcode := SQLCODE;
       l_error_message := 'Error in the procedure While processing' || l_file_name  || SQLERRM  ;
       x_errbuff := l_error_message;
       fnd_file.put_line (fnd_file.LOG, l_error_message);

    END hr_pf_custom_data;

-- Proecdure to create data file by UTL utility
    PROCEDURE create_pf_file (
      p_file_number   IN       VARCHAR2,
      p_file_name     IN       VARCHAR2,
      x_return_code   OUT      NUMBER,
      x_error_msg     OUT      VARCHAR2
   )
   IS
      CURSOR c_write_per_data
      IS
         SELECT   documenttype||g_csv||
                   senderid||g_csv||
                   receiverid||g_csv||
                   version||g_csv||
                   id||g_csv||
                   sourcesysrefkey||g_csv||
                   aristocraticprefix||g_csv||
                   formofaddress||g_csv||
                   givenname||g_csv||
                   preferredgivenname||g_csv||
                   middlename||g_csv||
                   familyname||g_csv||
                   extraname||g_csv||
                   generation||g_csv||
                   legalname||g_csv||
                   maidenname||g_csv||
                   phonelabel1||g_csv||
                   phonevalue1||g_csv||
                   phonelabel2||g_csv||
                   phonevalue2||g_csv||
                   phonelabel3||g_csv||
                   phonevalue3||g_csv||
                   phonelabel4||g_csv||
                   phonevalue4||g_csv||
                   phonelabel5||g_csv||
                   phonevalue5||g_csv||
                   emaillabel1||g_csv||
                   emailvalue1||g_csv||
                   emaillabel2||g_csv||
                   emailvalue2||g_csv||
                   emaillabel3||g_csv||
                   emailvalue3||g_csv||
                   websitelabel1||g_csv||
                   websitevalue1||g_csv||
                   websitelabel2||g_csv||
                   websitevalue2||g_csv||
                   websitelabel3||g_csv||
                   websitevalue3||g_csv||
                   im1||g_csv||
                   im2||g_csv||
                   im3||g_csv||
                   sms1||g_csv||
                   sms2||g_csv||
                   sms3||g_csv||
                   addresslabel||g_csv||
                   addressline1||g_csv||
                   addressline2||g_csv||
                   addressline3||g_csv||
                   streetname||g_csv||
                   buildingnumber||g_csv||
                   postofficebox||g_csv||
                   unit||g_csv||
                   municipality||g_csv||
                   region||g_csv||
                   countrycode||g_csv||
                   postalcode||g_csv||
                   recipientaristocraticprefix||g_csv||
                   recipientformofaddress||g_csv||
                   recipientgivenname||g_csv||
                   recipientpreferredgivenname||g_csv||
                   recipientmiddlename||g_csv||
                   recipientfamilyname||g_csv||
                   recipientextraname||g_csv||
                   recipientgeneration||g_csv||
                   recipientlegalname||g_csv||
                   recipientmaidenname||g_csv||
                   recipientadditionaltext||g_csv||
                   recipientorganizationname||g_csv||
                   addresslabel1||g_csv||
                   addressline11||g_csv||
                   addressline21||g_csv||
                   addressline31||g_csv||
                   streetname1||g_csv||
                   buildingnumber1||g_csv||
                   postofficebox1||g_csv||
                   unit1||g_csv||
                   municipality1||g_csv||
                   region1||g_csv||
                   countrycode1||g_csv||
                   postalcode1||g_csv||
                   recipientaristocraticprefix1||g_csv||
                   recipientformofaddress1||g_csv||
                   recipientgivenname1||g_csv||
                   recipientpreferredgivenname1||g_csv||
                   recipientmiddlename1||g_csv||
                   recipientfamilyname1||g_csv||
                   recipientextraname1||g_csv||
                   recipientgeneration1||g_csv||
                   recipientlegalname1||g_csv||
                   recipientmaidenname1||g_csv||
                   recipientadditionaltext1||g_csv||
                   recipientorganizationname1||g_csv||
                   customname1||g_csv||
                   customvalue1||g_csv||
                   customname2||g_csv||
                   customvalue2||g_csv||
                   customname3||g_csv||
                   customvalue3||g_csv||
                   customname4||g_csv||
                   customvalue4||g_csv||
                   customname5||g_csv||
                   customvalue5||g_csv||
                   customname6||g_csv||
                   customvalue6||g_csv||
                   customname7||g_csv||
                   customvalue7||g_csv||
                   customname8||g_csv||
                   customvalue8||g_csv||
                   customname9||g_csv||
                   customvalue9||g_csv||
                   customname10||g_csv||
                   customvalue10||g_csv||
                   clearcollection||g_csv rec
          FROM   intg_hr_pf_persons
          WHERE status_code ='S';

          CURSOR c_write_emp_data
          IS
          SELECT   documenttype||g_csv||
                         senderid||g_csv||
                         receiverid||g_csv||
                         version||g_csv||
                         id||g_csv||
                         EmployeeSourceSysRefKey||g_csv||
                         EmployeeId||g_csv||
                         PersonSourceSysRefKey||g_csv||
                         StartDate||g_csv||
                         AdjustedServiceDate||g_csv||
                         PictureSourceSysRefKey||g_csv||
                         EmployeeStatusStartDate1||g_csv||
                         EmployeeStatusEndDate1||g_csv||
                         EmployeeStatusType1||g_csv||
                         EmployeeStatusParent1||g_csv rec
          FROM   INTG_HR_PF_EMPLOYEES
          WHERE  status_code ='S'
          order by person_id,EmployeeStatusStartDate1;

          CURSOR c_write_usr_data
          IS
          SELECT   documenttype||g_csv||
                   senderid||g_csv||
                   receiverid||g_csv||
                   version||g_csv||
                   id||g_csv||
                   UserSourceSysRefKey||g_csv||
                   UserInactive||g_csv||
                   Login||g_csv||
                   Password||g_csv||
                   PasswordRecoveryPhrase||g_csv||
                   passwordrecoveryanswer||g_csv||
                   Role1 ||g_csv||
                   Role2 ||g_csv||
                   Role3 ||g_csv||
                   Role4 ||g_csv||
                   Role5 ||g_csv||
                   Role6 ||g_csv||
                   Role7 ||g_csv||
                   Role8 ||g_csv||
                   Role9 ||g_csv||
                   Role10||g_csv||
                   ProtectedRole1||g_csv||
                   ProtectedRole2||g_csv||
                   ProtectedRole3||g_csv||
                   ProtectedRole4||g_csv||
                   ProtectedRole5||g_csv||
                   ProtectedRole6||g_csv||
                   ProtectedRole7||g_csv||
                   ProtectedRole8||g_csv||
                   ProtectedRole9||g_csv||
                   ProtectedRole10||g_csv||
                   PersonSourceSysRefKey||g_csv||
                   CustomName1||g_csv||
                   CustomBody1||g_csv||
                   CustomName2||g_csv||
                   CustomBody2||g_csv||
                   CustomName3||g_csv||
                   CustomBody3||g_csv||
                   CustomName4||g_csv||
                   CustomBody4||g_csv||
                   CustomName5||g_csv||
                   CustomBody5||g_csv||
                   CustomName6||g_csv||
                   CustomBody6||g_csv||
                   CustomName7||g_csv||
                   CustomBody7||g_csv||
                   CustomName8||g_csv||
                   CustomBody8||g_csv||
                   CustomName9||g_csv||
                   CustomBody9||g_csv||
                   CustomName10||g_csv||
                   CustomBody10||g_csv||
                   PasswordChangeRequired||g_csv||
                   StartPage||g_csv||
                   ContentLocale||g_csv||
                   ApplicationLocale||g_csv||
                   Currency||g_csv||
                   DateAndNumberFormatLocale||g_csv||
                   DisplayTimeFormatIn24HR||g_csv  rec
          FROM   INTG_HR_PF_USERS
          WHERE  status_code ='S';

          CURSOR c_write_pos_hol_data
          IS
          select documenttype||g_csv||
                   senderid||g_csv||
                   receiverid||g_csv||
                   version||g_csv||
                   id||g_csv||
                   sourcesysrefkey||g_csv||
                   employeesourcesysrefkey||g_csv||
                   employeetype||g_csv||
                   startdate||g_csv||
                   enddate||g_csv||
                   clearcollection||g_csv||
                   preservecurrentpositionholders||g_csv rec
          FROM   INTG_HR_PF_POS_HOLDER_HIS
          WHERE  status_code ='S';

          CURSOR c_write_pos_hr_data
          IS
          SELECT   documenttype||g_csv||
                   senderid||g_csv||
                   receiverid||g_csv||
                   version||g_csv||
                   id||g_csv||
                   SourceSysRefKey||g_csv||
                   HRRelationshipType||g_csv||
                   PositionSourceSysRefKey||g_csv||
                   EmployeeSourceSysRefKey||g_csv||
                   ClearCollection||g_csv rec
          FROM   INTG_HR_PF_POS_HR_REL_V--INTG_HR_PF_POS_HR_RELSHIP
          ORDER BY SourceSysRefKey;


          CURSOR c_write_inc_data
          IS
          SELECT documenttype||g_csv||
                   senderid||g_csv||
                   receiverid||g_csv||
                   version||g_csv||
                   id||g_csv||
                   employeesourcesysrefkey||g_csv||
                   to_char(effectivedate,'YYYY-MM-DD')||g_csv||
                   plancode||g_csv||
                   plancodesourcesysrefkey||g_csv||
                   description||g_csv||
                   category||g_csv||
                   to_char(enddate,'YYYY-MM-DD')||g_csv||
                   clearcollection||g_csv rec
          FROM   INTG_HR_PF_INCENTIVE_PLAN
          WHERE  status_code ='S'
          ORDER BY employeesourcesysrefkey,effectivedate ;

         CURSOR c_write_sal_data
         IS
         SELECT    documenttype||g_csv||
                   senderid||g_csv||
                   receiverid||g_csv||
                   version||g_csv||
                   id||g_csv||
                   employeesourcesysrefkey||g_csv||
                   salaryhistorysourcesysrefkey||g_csv||
                   to_char(effectivedate,'YYYY-MM-DD')||g_csv||
                   planyear||g_csv||
                   currencycode||g_csv||
                   salaryrate||g_csv||
                   increaseamount||g_csv||
                   salaryperiodtype||g_csv||
                   lumpsum||g_csv||
                   prorationfactor||g_csv||
                   fte||g_csv||
                   grade||g_csv||
                   gradestructure||g_csv||
                   gradesetname||g_csv||
                   marketstructure||g_csv||
                   marketsetname||g_csv||
                   increasepercentage||g_csv||
                   salarygradessrk||g_csv||
                   salaryincdetail1incpercentage||g_csv||
                   salaryincdetail1increason||g_csv||
                   salaryincdetail1incamt||g_csv||
                   salaryincdetail1cpdseqnumber||g_csv||
                   salaryincdet1cpddefaultincamt||g_csv||
                   salaryincdetail2incpercentage||g_csv||
                   salaryincdetail2increason||g_csv||
                   salaryincdetail2incamt||g_csv||
                   salaryincdetail2cpdseqnumber||g_csv||
                   salaryincdet2cpddefaultincamt||g_csv||
                   salaryincdetail3incpercentage||g_csv||
                   salaryincdetail3increason||g_csv||
                   salaryincdetail3incamt||g_csv||
                   salaryincdetail3cpdseqnumber||g_csv||
                   salaryincdet3cpddefaultincamt||g_csv||
                   salaryincdetail4incpercentage||g_csv||
                   salaryincdetail4increason||g_csv||
                   salaryincdetail4incamt||g_csv||
                   salaryincdetail4cpdseqnumber||g_csv||
                   salaryincdet4cpddefaultincamt||g_csv||
                   cpdexchangerate||g_csv||
                   cpdsalaryplanid||g_csv||
                   cpddefaultamt||g_csv||
                   cpddefaultincreaseamt||g_csv||
                   clearcollection||g_csv||
                   salaryincdetail5incpercentage||g_csv||
                   salaryincdetail5increason||g_csv||
                   salaryincdetail5incamt||g_csv||
                   salaryincdetail5cpdseqnumber||g_csv||
                   salaryincdet5cpddefaultincamt||g_csv||
                   salaryincdetail6incpercentage||g_csv||
                   salaryincdetail6increason||g_csv||
                   salaryincdetail6incamt||g_csv||
                   salaryincdetail6cpdseqnumber||g_csv||
                   salaryincdet6cpddefaultincamt||g_csv||
                   salaryincdetail7incpercentage||g_csv||
                   salaryincdetail7increason||g_csv||
                   salaryincdetail7incamt||g_csv||
                   salaryincdetail7cpdseqnumber||g_csv||
                   salaryincdet7cpddefaultincamt||g_csv||
                  salaryincdetail8incpercentage||g_csv||
                  salaryincdetail8increason    ||g_csv||
                  salaryincdetail8incamt       ||g_csv||
                  salaryincdet8cpdseqnumber       ||g_csv||
                  salaryincdet8cpddefaultincamt   ||g_csv||
                  salaryincdetail9incpercentage   ||g_csv||
                  salaryincdetail9increason       ||g_csv||
                  salaryincdetail9incamt          ||g_csv||
                  salaryincdetail9cpdseqnumber    ||g_csv||
                  salaryincdet9cpddefaultincamt   ||g_csv||
                  salaryincdetail10incpercentage  ||g_csv||
                  salaryincdetail10increason      ||g_csv||
                  salaryincdetail10incamt         ||g_csv||
                  salaryincdetail10cpdseqnumber   ||g_csv||
                  salaryincdet10cpddefaultincamt||g_csv  rec
        FROM   INTG_HR_PF_EE_SAL_HIS
        WHERE  status_code ='S'
        ORDER BY EMPLOYEESOURCESYSREFKEY,
        EFFECTIVEDATE;

         CURSOR c_write_cust_data
         IS
         SELECT   documenttype||g_csv||
                   senderid||g_csv||
                   receiverid||g_csv||
                   version||g_csv||
                   id||g_csv||
                   personsourcesysrefkey||g_csv||
                   customname1||g_csv||
                   customvalue1||g_csv||
                   customname2||g_csv||
                   customvalue2||g_csv||
                   customname3||g_csv||
                   customvalue3||g_csv||
                   customname4||g_csv||
                   customvalue4||g_csv||
                   customname5||g_csv||
                   customvalue5||g_csv||
                   customname6||g_csv||
                   customvalue6||g_csv||
                   customname7||g_csv||
                   customvalue7||g_csv||
                   customname8||g_csv||
                   customvalue8||g_csv||
                   customname9||g_csv||
                   customvalue9||g_csv||
                   customname10||g_csv||
                   customvalue10||g_csv rec
          FROM   INTG_HR_PF_CUSTOM_FIELDS
          WHERE  status_code ='S';

      x_file_pf_type   UTL_FILE.file_type;
      x_data_pf_dir    VARCHAR2 (80);
      x_pf_per_data    VARCHAR2 (4000);
      x_pf_emp_data    VARCHAR2 (4000);
      x_pf_usr_data    VARCHAR2 (4000);
      x_pf_pos_hol_data VARCHAR2 (4000);
      x_pf_pos_hr_data VARCHAR2 (4000);
      x_pf_inc_data    VARCHAR2 (4000);
      x_pf_sal_data    VARCHAR2 (4000);
      x_pf_cust_data   VARCHAR2 (4000);
      x_err_out        VARCHAR2 (4000);
      x_file_name      VARCHAR2 (1000);
      x_to_mail        VARCHAR2 (1000);
      x_subject        VARCHAR2 (60);
      x_message        VARCHAR2 (60);
      x_from           VARCHAR2 (60);
      x_bcc_name       VARCHAR2 (60);
      x_cc_name        VARCHAR2 (60);

   BEGIN
      xx_intg_common_pkg.get_process_param_value
                                            (p_process_name      => 'XXINTGPFWSE',
                                             p_param_name        => 'DATA_DIR',
                                             x_param_value       => x_data_pf_dir
                                            );

      fnd_file.put_line (fnd_file.LOG, 'Directory: ' ||x_data_pf_dir);

       x_file_name :=
               p_file_name
            || '_'
            || g_request_id
            || '_'
            || TO_DATE (SYSDATE, 'DD-MON_YYYY')
            || '.txt';

      fnd_file.put_line (fnd_file.LOG, 'File Name: ' ||x_file_name);

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'file name-> ' || x_file_name
                           );

      -- opening the file
      BEGIN
         x_file_pf_type :=
                 UTL_FILE.fopen_nchar (x_data_pf_dir, x_file_name, 'W', 6400);
      EXCEPTION
         WHEN UTL_FILE.invalid_path
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'Invalid Path for File :' || x_file_name;
         WHEN UTL_FILE.invalid_filehandle
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'File handle is invalid for File :' || x_file_name;
         WHEN UTL_FILE.write_error
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'Unable to write the File :' || x_file_name;
         WHEN UTL_FILE.invalid_operation
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg :=
                      'File could not be opened for writting:' || x_file_name;
         WHEN UTL_FILE.invalid_maxlinesize
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'File ' || x_file_name;
         WHEN UTL_FILE.access_denied
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'Access denied for File :' || x_file_name;
         WHEN OTHERS
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'File ' || x_file_name || '->' || SQLERRM;
      END;

      IF p_file_number = 1 THEN
         FOR rec_write_per_data IN c_write_per_data
         LOOP
            x_pf_per_data := NULL;
            x_pf_per_data := rec_write_per_data.rec;
            UTL_FILE.put_line_nchar (x_file_pf_type, x_pf_per_data);
         END LOOP;

         IF UTL_FILE.is_open (x_file_pf_type)
         THEN
            UTL_FILE.fclose (x_file_pf_type);
         END IF;

      ELSIF p_file_number = 2
      THEN
         FOR rec_write_emp_data IN c_write_emp_data
         LOOP
            x_pf_emp_data := NULL;
            x_pf_emp_data := rec_write_emp_data.rec;
            UTL_FILE.put_line_nchar (x_file_pf_type, x_pf_emp_data);
         END LOOP;

         IF UTL_FILE.is_open (x_file_pf_type)
         THEN
            UTL_FILE.fclose (x_file_pf_type);
         END IF;

      ELSIF p_file_number = 3
      THEN
         FOR rec_write_usr_data IN c_write_usr_data
         LOOP
            x_pf_usr_data := NULL;
            x_pf_usr_data := rec_write_usr_data.rec;
            UTL_FILE.put_line_nchar (x_file_pf_type, x_pf_usr_data);
         END LOOP;

         IF UTL_FILE.is_open (x_file_pf_type)
         THEN
            UTL_FILE.fclose (x_file_pf_type);
         END IF;

      ELSIF p_file_number = 4
      THEN
         FOR rec_write_pos_hol_data IN c_write_pos_hol_data
         LOOP
            x_pf_pos_hol_data := NULL;
            x_pf_pos_hol_data := rec_write_pos_hol_data.rec;
            UTL_FILE.put_line_nchar (x_file_pf_type, x_pf_pos_hol_data);
         END LOOP;

         IF UTL_FILE.is_open (x_file_pf_type)
         THEN
            UTL_FILE.fclose (x_file_pf_type);
         END IF;

      ELSIF p_file_number = 5
      THEN
         FOR rec_write_pos_hr_data IN c_write_pos_hr_data
         LOOP
            x_pf_pos_hr_data := NULL;
            x_pf_pos_hr_data := rec_write_pos_hr_data.rec;
            UTL_FILE.put_line_nchar (x_file_pf_type, x_pf_pos_hr_data);
         END LOOP;

         IF UTL_FILE.is_open (x_file_pf_type)
         THEN
            UTL_FILE.fclose (x_file_pf_type);
         END IF;

      ELSIF p_file_number = 7
      THEN
         FOR rec_write_inc_data IN c_write_inc_data
         LOOP
            x_pf_inc_data := NULL;
            x_pf_inc_data := rec_write_inc_data.rec;
            UTL_FILE.put_line_nchar (x_file_pf_type, x_pf_inc_data);
         END LOOP;

         IF UTL_FILE.is_open (x_file_pf_type)
         THEN
            UTL_FILE.fclose (x_file_pf_type);
         END IF;
      ELSIF p_file_number = 6
      THEN
       NULL;
      ELSIF p_file_number = 8
      THEN
         FOR rec_write_sal_data IN c_write_sal_data
         LOOP
            x_pf_sal_data := NULL;
            x_pf_sal_data := rec_write_sal_data.rec;
            UTL_FILE.put_line_nchar (x_file_pf_type, x_pf_sal_data);
         END LOOP;

         IF UTL_FILE.is_open (x_file_pf_type)
         THEN
            UTL_FILE.fclose (x_file_pf_type);
         END IF;
      ELSIF p_file_number = 9
      THEN
         FOR rec_write_cust_data IN c_write_cust_data
         LOOP
            x_pf_cust_data := NULL;
            x_pf_cust_data := rec_write_cust_data.rec;
            UTL_FILE.put_line_nchar (x_file_pf_type, x_pf_cust_data);
         END LOOP;

         IF UTL_FILE.is_open (x_file_pf_type)
         THEN
            UTL_FILE.fclose (x_file_pf_type);
         END IF;
      END IF;

      IF x_return_code <>0 THEN
         fnd_file.put_line (fnd_file.LOG, 'Error While Preparing the File: ' ||p_file_name || x_error_msg);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_error_msg := 'Procedure - write_pf_file ->' || SQLERRM;
         x_return_code := xx_emf_cn_pkg.cn_prc_err;
   END create_pf_file;

 -- Procedure to Create Error File
   PROCEDURE create_pf_err_file (
      p_file_number   IN       VARCHAR2,
      p_file_name     IN       VARCHAR2,
      x_return_code   OUT      NUMBER,
      x_error_msg     OUT      VARCHAR2
   )
   IS
       CURSOR c_write_err_per_data
       IS
         SELECT sourcesysrefkey, error_mesg
         FROM intg_hr_pf_persons
         WHERE status_code = 'E';

       CURSOR c_write_err_emp_data
       IS
         SELECT employeeid, error_mesg
         FROM intg_hr_pf_employees
         WHERE status_code = 'E';

       CURSOR c_write_err_usr_data
       IS
         SELECT usersourcesysrefkey, error_mesg
         FROM intg_hr_pf_users
         WHERE status_code = 'E';

       CURSOR c_write_err_pos_his_data
       IS
         SELECT SourceSysRefKey,EmployeeSourceSysRefKey, error_mesg
         FROM intg_hr_pf_pos_holder_his
         WHERE status_code = 'E';

       CURSOR c_write_err_pos_hr_data
       IS
         SELECT SourceSysRefKey,PositionSourceSysRefKey, error_mesg
         FROM intg_hr_pf_pos_hr_relship
         WHERE status_code = 'E';

        CURSOR c_write_err_inc_data
        IS
         SELECT employeesourcesysrefkey, error_mesg
         FROM intg_hr_pf_incentive_plan
         WHERE status_code = 'E';

        CURSOR c_write_err_sal_data
        IS
         SELECT employeesourcesysrefkey, pay_proposal_id, error_mesg
         FROM intg_hr_pf_ee_sal_his
         WHERE status_code = 'E';

        CURSOR c_write_err_cust_data
        IS
         SELECT personsourcesysrefkey, error_mesg
         FROM intg_hr_pf_custom_fields
         WHERE status_code = 'E';

        CURSOR c_mail
        IS
         SELECT description
           FROM fnd_lookup_values_vl
          WHERE lookup_type = 'INTG_PF_INTERFACE_RECIPIENTS'
            AND NVL (enabled_flag, 'X') = 'Y'
            AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                            AND NVL (end_date_active, SYSDATE);

      x_file_err_type     UTL_FILE.file_type;
      x_file_log_type     UTL_FILE.file_type;
      x_err_pf_dir        VARCHAR2 (80);
      x_log_pf_dir        VARCHAR2 (80);
      x_pf_per_err_data   VARCHAR2 (4000);
      x_pf_emp_err_data   VARCHAR2 (4000);
      x_pf_usr_err_data   VARCHAR2 (4000);
      x_pf_poshol_err_data VARCHAR2 (4000);
      x_pf_poshr_err_data   VARCHAR2 (4000);
      x_pf_inc_err_data   VARCHAR2 (4000);
      x_pf_sal_err_data   VARCHAR2 (4000);
      x_pf_cust_err_data  VARCHAR2 (4000);
      x_err_data_head     VARCHAR2 (4000);
      x_err_out           VARCHAR2 (4000);
      x_file_name         VARCHAR2 (1000);
      x_to_mail           VARCHAR2 (1000);
      x_subject           VARCHAR2 (100);
      x_message           VARCHAR2 (100);
      x_from              VARCHAR2 (60);
      x_bcc_name          VARCHAR2 (60);
      x_cc_name           VARCHAR2 (60);

   BEGIN

      xx_intg_common_pkg.get_process_param_value
                                            (p_process_name      => 'XXINTGPFWSE',
                                             p_param_name        => 'ERROR_DIR',
                                             x_param_value       => x_err_pf_dir
                                            );
      fnd_file.put_line (fnd_file.LOG, 'Error Directory: ' ||x_err_pf_dir);

      x_file_name :=
               p_file_name
            || '_'
            || 'Err'
            || '_'
            || g_request_id
            || '_'
            || TO_DATE (SYSDATE, 'DD-MON_YYYY')
            || '.csv';

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'file name-> ' || x_file_name
                           );
            fnd_file.put_line (fnd_file.LOG, 'Error File Name: ' ||x_file_name);

      -- opening the error file
      BEGIN
         x_file_err_type :=
                  UTL_FILE.fopen_nchar (x_err_pf_dir, x_file_name, 'W', 6400);
      EXCEPTION
         WHEN UTL_FILE.invalid_path
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'Invalid Path for File :' || x_file_name;
         WHEN UTL_FILE.invalid_filehandle
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'File handle is invalid for File :' || x_file_name;
         WHEN UTL_FILE.write_error
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'Unable to write the File :' || x_file_name;
         WHEN UTL_FILE.invalid_operation
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg :=
                      'File could not be opened for writting:' || x_file_name;
         WHEN UTL_FILE.invalid_maxlinesize
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'File ' || x_file_name;
         WHEN UTL_FILE.access_denied
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'Access denied for File :' || x_file_name;
         WHEN OTHERS
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'File ' || x_file_name || '->' || SQLERRM;
      END;

      IF p_file_number = 1
      THEN
         x_err_data_head := 'Employee Number' || ',' || 'Error Description';
         UTL_FILE.put_line_nchar (x_file_err_type, x_err_data_head);

         FOR rec_write_err_per_data IN c_write_err_per_data
         LOOP
            x_pf_per_err_data := NULL;
            x_pf_per_err_data :=
                  '"'
               || rec_write_err_per_data.sourcesysrefkey
               || '"'
               || ','
               || '"'
               || rec_write_err_per_data.error_mesg
               || '"';
            UTL_FILE.put_line_nchar (x_file_err_type, x_pf_per_err_data);
         END LOOP;


      ELSIF p_file_number = 2
      THEN
         x_err_data_head := 'Employee Number' || ',' || 'Error Description';
         UTL_FILE.put_line_nchar (x_file_err_type, x_err_data_head);

         FOR rec_write_err_emp_data IN c_write_err_emp_data
         LOOP
            x_pf_emp_err_data := NULL;
            x_pf_emp_err_data :=
                  '"'
               || rec_write_err_emp_data.employeeid
               || '"'
               || ','
               || '"'
               || rec_write_err_emp_data.error_mesg
               || '"';
            UTL_FILE.put_line_nchar (x_file_err_type, x_pf_per_err_data);
         END LOOP;

     ELSIF p_file_number = 3
      THEN
         x_err_data_head := 'Employee Number' || ',' || 'Error Description';
         UTL_FILE.put_line_nchar (x_file_err_type, x_err_data_head);

         FOR rec_write_err_usr_data IN c_write_err_usr_data
         LOOP
            x_pf_usr_err_data := NULL;
            x_pf_usr_err_data :=
                  '"'
               || rec_write_err_usr_data.usersourcesysrefkey
               || '"'
               || ','
               || '"'
               || rec_write_err_usr_data.error_mesg
               || '"';
            UTL_FILE.put_line_nchar (x_file_err_type, x_pf_usr_err_data);
         END LOOP;
     ELSIF p_file_number = 4
      THEN
         x_err_data_head := 'Employee Number' || ',' || 'Position ID'|| ',' || 'Error Description';
         UTL_FILE.put_line_nchar (x_file_err_type, x_err_data_head);

         FOR rec_write_err_pos_his_data IN c_write_err_pos_his_data
         LOOP
            x_pf_poshol_err_data := NULL;
            x_pf_poshol_err_data :=
                  '"'
               || rec_write_err_pos_his_data.EmployeeSourceSysRefKey
               || '"'
               || ','
               || '"'
               || rec_write_err_pos_his_data.SourceSysRefKey
               || '"'
               || ','
               || '"'
               || rec_write_err_pos_his_data.error_mesg
               || '"';
            UTL_FILE.put_line_nchar (x_file_err_type, x_pf_poshol_err_data);
         END LOOP;
     ELSIF p_file_number = 5
      THEN
         x_err_data_head := 'Postion Id' || 'Position Id of HR ,' || 'Error Description';
         UTL_FILE.put_line_nchar (x_file_err_type, x_err_data_head);

         FOR rec_write_err_pos_hr_data IN c_write_err_pos_hr_data
         LOOP
            x_pf_poshr_err_data := NULL;
            x_pf_poshr_err_data :=
                  '"'
               || rec_write_err_pos_hr_data.SourceSysRefKey
               || '"'
               || ','
               || '"'
               || rec_write_err_pos_hr_data.PositionSourceSysRefKey
               || '"'
               || ','
               || '"'
               || rec_write_err_pos_hr_data.error_mesg
               || '"';
            UTL_FILE.put_line_nchar (x_file_err_type, x_pf_poshr_err_data);
         END LOOP;
     ELSIF p_file_number = 7
      THEN
         x_err_data_head := 'Employee Number' || ',' || 'Error Description';
         UTL_FILE.put_line_nchar (x_file_err_type, x_err_data_head);

         FOR rec_write_err_inc_data IN c_write_err_inc_data
         LOOP
            x_pf_inc_err_data := NULL;
            x_pf_inc_err_data :=
                  '"'
               || rec_write_err_inc_data.employeesourcesysrefkey
               || '"'
               || ','
               || '"'
               || rec_write_err_inc_data.error_mesg
               || '"';
            UTL_FILE.put_line_nchar (x_file_err_type, x_pf_inc_err_data);

         END LOOP;

     ELSIF p_file_number = 6
     THEN
        NULL;

     ELSIF p_file_number = 8
     THEN
         x_err_data_head := 'Employee Number' || ','|| 'Proposal Id' ||',' || 'Error Description';
         UTL_FILE.put_line_nchar (x_file_err_type, x_err_data_head);

         FOR rec_write_err_sal_data IN c_write_err_sal_data
         LOOP
            x_pf_sal_err_data := NULL;
            x_pf_sal_err_data :=
                  '"'
               || rec_write_err_sal_data.employeesourcesysrefkey
               || '"'
               || ','
               || '"'
               ||rec_write_err_sal_data.pay_proposal_id
               || '"'
               || ','
               || '"'
               || rec_write_err_sal_data.error_mesg
               || '"';
            UTL_FILE.put_line_nchar (x_file_err_type, x_pf_sal_err_data);
         END LOOP;
     ELSIF p_file_number = 9
     THEN
         x_err_data_head := 'Employee Number' || ',' || 'Error Description';
         UTL_FILE.put_line_nchar (x_file_err_type, x_err_data_head);

         FOR rec_write_err_cust_data IN c_write_err_cust_data
         LOOP
            x_pf_cust_err_data := NULL;
            x_pf_cust_err_data :=
                  '"'
               || rec_write_err_cust_data.personsourcesysrefkey
               || '"'
               || ','
               || '"'
               || rec_write_err_cust_data.error_mesg
               || '"';
            UTL_FILE.put_line_nchar (x_file_err_type, x_pf_cust_err_data);
         END LOOP;
     END IF;


         IF UTL_FILE.is_open (x_file_err_type)
         THEN
            UTL_FILE.fclose (x_file_err_type);
         END IF;

         x_subject := 'PeopleFluent ' || x_file_name || ' Error File';



         xx_intg_common_pkg.get_process_param_value
                                             (p_process_name      => 'XXINTGPFWSE',
                                              p_param_name        => 'MESSAGE',
                                              x_param_value       => x_message
                                             );



         xx_intg_common_pkg.get_process_param_value
                                             (p_process_name      => 'XXINTGPFWSE',
                                              p_param_name        => 'FROM_EMAIL_ID',
                                              x_param_value       => x_from
                                             );



          FOR mail_rec IN c_mail
          LOOP
             x_to_mail := x_to_mail || mail_rec.description;
          END LOOP;


         xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                     '-------------------------------------------------------'
                    );
         xx_emf_pkg.write_log
            (xx_emf_cn_pkg.cn_low,
             '------------------- PF' || x_file_name || 'Exception File Mailing'------------------------'
            );
         xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                     '-------------------------------------------------------'
                    );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'x_from      -> ' || x_from
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'x_to_mail   -> ' || x_to_mail
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'x_subject   -> ' || x_subject
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'x_message   -> ' || x_message
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'x_to_dir    -> ' || x_err_pf_dir
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'x_file_name -> ' || x_file_name
                              );
         xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                     '-------------------------------------------------------'
                    );

         IF x_to_mail IS NOT NULL
         THEN
            BEGIN

            -- Calling Send Mail proecdure
               xx_intg_mail_util_pkg.send_mail_attach
                                         (p_from_name             => x_from,
                                          p_to_name               => x_to_mail,
                                          p_cc_name               => x_cc_name,
                                          p_bc_name               => x_bcc_name,
                                          p_subject               => x_subject,
                                          p_message               => x_message,
                                          p_oracle_directory      => x_err_pf_dir,
                                          p_binary_file           => x_file_name
                                         );
            EXCEPTION
               WHEN OTHERS
               THEN
                  xx_emf_pkg.write_log
                     (xx_emf_cn_pkg.cn_low,
                      '-------------------------------------------------------'
                     );
                  x_return_code := xx_emf_cn_pkg.cn_rec_warn;
                  x_error_msg := 'Error in mailing error file';
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, x_error_msg);
                  xx_emf_pkg.write_log
                     (xx_emf_cn_pkg.cn_low,
                      '-------------------------------------------------------'
                     );
            END;
         END IF;

   EXCEPTION
      WHEN OTHERS
      THEN

         x_error_msg := 'Procedure - write_pf_file ->' || SQLERRM;
         x_return_code := xx_emf_cn_pkg.cn_prc_err;
         fnd_file.put_line (fnd_file.LOG, 'x_error_msg: ' ||x_error_msg);
   END create_pf_err_file;

-- Procedure to generate a alog file
   PROCEDURE create_pf_log_file (
      p_file_number   IN       VARCHAR2,
      p_file_name     IN       VARCHAR2,
      x_return_code   OUT      NUMBER,
      x_error_msg     OUT      VARCHAR2
   )
   IS
      x_file_log_type     UTL_FILE.file_type;
      x_err_pf_dir        VARCHAR2 (80);
      x_log_pf_dir        VARCHAR2 (80);
      x_pf_org_log_data   VARCHAR2 (4000);
      x_err_out           VARCHAR2 (4000);
      x_file_name         VARCHAR2 (1000);
      x_to_mail           VARCHAR2 (1000);
      x_subject           VARCHAR2 (60);
      x_message           VARCHAR2 (60);
      x_from              VARCHAR2 (60);
      x_bcc_name          VARCHAR2 (60);
      x_cc_name           VARCHAR2 (60);
      l_total_count       NUMBER (10);
      l_success_count     NUMBER (10);
      l_failed_count      NUMBER (10);
      l_date_str          VARCHAR2 (105)
                       := 'Date' || CHR (9)
                          || TO_CHAR (SYSDATE, 'DD-MM-YYYY');

      l_file_name_str     VARCHAR2 (150);
      l_requestid_str     VARCHAR2 (150)
                                     := 'Request ID' || CHR (9)
                                        || g_request_id;
      l_tot_rec_str       VARCHAR2 (200);
      l_suc_rec_str       VARCHAR2 (200);
      l_err_rec_str       VARCHAR2 (200);
      --   l_utl_dat_path  varchar2(150):='XXPPLFLWSDAT';
      l_utl_err_path      VARCHAR2 (150)     := 'XXPPLFLERR';
      l_utl_log_path      VARCHAR2 (150)     := 'XXPPLFLLOG';
   BEGIN

      x_file_name :=
               p_file_name
            || '_'
            || 'Log'
            || '_'
            || g_request_id
            || '_'
            || TO_DATE (SYSDATE, 'DD-MON_YYYY')
            || '.txt';

      xx_intg_common_pkg.get_process_param_value
                                            (p_process_name      => 'XXINTGPFWSE',
                                             p_param_name        => 'LOG_DIR',
                                             x_param_value       => x_log_pf_dir
                                            );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'file name-> ' || x_file_name
                           );

      -- opening the error file
      BEGIN
         x_file_log_type :=
                        UTL_FILE.fopen (x_log_pf_dir, x_file_name, 'W', 6400);
      EXCEPTION
         WHEN UTL_FILE.invalid_path
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'Invalid Path for File :' || x_file_name;
         WHEN UTL_FILE.invalid_filehandle
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'File handle is invalid for File :' || x_file_name;
         WHEN UTL_FILE.write_error
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'Unable to write the File :' || x_file_name;
         WHEN UTL_FILE.invalid_operation
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg :=
                      'File could not be opened for writting:' || x_file_name;
         WHEN UTL_FILE.invalid_maxlinesize
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'File ' || x_file_name;
         WHEN UTL_FILE.access_denied
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'Access denied for File :' || x_file_name;
         WHEN OTHERS
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'File ' || x_file_name || '->' || SQLERRM;
      END;

      l_file_name_str
         :=    'File Name'
            || CHR (9)
            || p_file_name
            || '_'
            || g_request_id
            || '_'
            || TO_DATE (SYSDATE, 'DD-MON_YYYY')
            || '.txt';


      IF p_file_number = 1
      THEN

               BEGIN
            SELECT COUNT (*)
              INTO l_total_count
              FROM intg_hr_pf_persons;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_total_count := 0;
         END;

         BEGIN
            SELECT COUNT (*)
              INTO l_success_count
              FROM intg_hr_pf_persons
             WHERE status_code = 'S';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_success_count := 0;
         END;


         BEGIN
            SELECT COUNT (*)
              INTO l_failed_count
              FROM intg_hr_pf_persons
             WHERE status_code = 'E';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_failed_count := 0;
         END;
      ELSIF p_file_number = 2
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO l_total_count
              FROM intg_hr_pf_employees;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_total_count := 0;
         END;

         BEGIN
            SELECT COUNT (*)
              INTO l_success_count
              FROM intg_hr_pf_employees
             WHERE status_code = 'S';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_success_count := 0;
         END;


         BEGIN
            SELECT COUNT (*)
              INTO l_failed_count
              FROM intg_hr_pf_employees
             WHERE status_code = 'E';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_failed_count := 0;
         END;

      ELSIF p_file_number = 3
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO l_total_count
              FROM intg_hr_pf_users;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_total_count := 0;
         END;

         BEGIN
            SELECT COUNT (*)
              INTO l_success_count
              FROM intg_hr_pf_users
             WHERE status_code = 'S';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_success_count := 0;
         END;


         BEGIN
            SELECT COUNT (*)
              INTO l_failed_count
              FROM intg_hr_pf_users
             WHERE status_code = 'E';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_failed_count := 0;
         END;

      ELSIF p_file_number = 4
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO l_total_count
              FROM intg_hr_pf_pos_holder_his;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_total_count := 0;
         END;

         BEGIN
            SELECT COUNT (*)
              INTO l_success_count
              FROM intg_hr_pf_pos_holder_his
             WHERE status_code = 'S';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_success_count := 0;
         END;


         BEGIN
            SELECT COUNT (*)
              INTO l_failed_count
              FROM intg_hr_pf_pos_holder_his
             WHERE status_code = 'E';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_failed_count := 0;
         END;

      ELSIF p_file_number = 5
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO l_total_count
              FROM intg_hr_pf_pos_hr_relship;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_total_count := 0;
         END;

         BEGIN
            SELECT COUNT (*)
              INTO l_success_count
              FROM intg_hr_pf_pos_hr_relship
             WHERE status_code = 'S';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_success_count := 0;
         END;


         BEGIN
            SELECT COUNT (*)
              INTO l_failed_count
              FROM intg_hr_pf_pos_hr_relship
             WHERE status_code = 'E';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_failed_count := 0;
         END;

      ELSIF p_file_number = 7
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO l_total_count
              FROM intg_hr_pf_incentive_plan;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_total_count := 0;
         END;

         BEGIN
            SELECT COUNT (*)
              INTO l_success_count
              FROM intg_hr_pf_incentive_plan
             WHERE status_code = 'S';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_success_count := 0;
         END;


         BEGIN
            SELECT COUNT (*)
              INTO l_failed_count
              FROM intg_hr_pf_incentive_plan
             WHERE status_code = 'E';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_failed_count := 0;
         END;

      ELSIF p_file_number = 8
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO l_total_count
              FROM intg_hr_pf_ee_sal_his;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_total_count := 0;
         END;

         BEGIN
            SELECT COUNT (*)
              INTO l_success_count
              FROM intg_hr_pf_ee_sal_his
             WHERE status_code = 'S';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_success_count := 0;
         END;


         BEGIN
            SELECT COUNT (*)
              INTO l_failed_count
              FROM intg_hr_pf_ee_sal_his
             WHERE status_code = 'E';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_failed_count := 0;
         END;
      ELSIF p_file_number = 9
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO l_total_count
              FROM intg_hr_pf_custom_fields;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_total_count := 0;
         END;

         BEGIN
            SELECT COUNT (*)
              INTO l_success_count
              FROM intg_hr_pf_custom_fields
             WHERE status_code = 'S';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_success_count := 0;
         END;


         BEGIN
            SELECT COUNT (*)
              INTO l_failed_count
              FROM intg_hr_pf_custom_fields
             WHERE status_code = 'E';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_failed_count := 0;
         END;
      END IF;

         l_tot_rec_str := 'Total No. of Records' || CHR (9) || l_total_count;
         l_suc_rec_str := 'Total No. of Success Records' || CHR (9)|| l_success_count;
         l_err_rec_str := 'Total No. of Failed Records' || CHR (9) || l_failed_count;


         UTL_FILE.new_line (x_file_log_type, 1);
         UTL_FILE.put_line (x_file_log_type, l_date_str);
         UTL_FILE.new_line (x_file_log_type, 1);
         UTL_FILE.put_line (x_file_log_type, l_file_name_str);
         UTL_FILE.new_line (x_file_log_type, 1);
         UTL_FILE.put_line (x_file_log_type, l_requestid_str);
         UTL_FILE.new_line (x_file_log_type, 1);
         UTL_FILE.put_line (x_file_log_type, l_tot_rec_str);
         UTL_FILE.new_line (x_file_log_type, 1);
         UTL_FILE.put_line (x_file_log_type, l_suc_rec_str);
         UTL_FILE.new_line (x_file_log_type, 1);
         UTL_FILE.put_line (x_file_log_type, l_err_rec_str);

         IF UTL_FILE.is_open (x_file_log_type)
         THEN
            UTL_FILE.fclose (x_file_log_type);
         END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_error_msg := 'Procedure - write_pf_file ->' || SQLERRM;
         x_return_code := xx_emf_cn_pkg.cn_prc_err;
   END create_pf_log_file;


END intg_hr_pf_empintf_pkg;
/
