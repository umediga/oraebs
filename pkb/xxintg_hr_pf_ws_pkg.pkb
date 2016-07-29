DROP PACKAGE BODY APPS.XXINTG_HR_PF_WS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xxintg_hr_pf_ws_pkg
AS
----------------------------------------------------------------------
/*
 Created By    : Shekhar Nikam
 Creation Date : 06-OCT-2014
 File Name     : xxintg_hr_pf_ws_pkg.pkb
 Description   : This script creates the body of the package
                 xxintg_hr_pf_ws_pkg
 Change History:
 Date           Name                  Remarks
 -----------   -------------         -----------------------------------
 06-OCT-2014   Shekhar Nikam          Initial development.
 */
------------------------------------------------------------------------
   x_request_id   NUMBER       := fnd_global.conc_request_id;
   g_csv          VARCHAR2 (3) := '|';

-- Main Procedure to submit INTG PF Work Structure Extract program
   PROCEDURE main (
      x_errbuff     OUT      VARCHAR2,
      x_retcode     OUT      NUMBER,
      p_eff_date    IN       VARCHAR2,
      p_file_name   IN       NUMBER
   )
   IS
      l_errbuff    VARCHAR2 (2000);
      l_retcode    NUMBER;
      l_prog_id    NUMBER;
      l_eff_date   DATE;

      CURSOR csr_lov
      IS
         SELECT a.flex_value
           FROM fnd_flex_values a, fnd_flex_value_sets b
          WHERE a.flex_value_set_id = b.flex_value_set_id
            AND b.flex_value_set_name = 'INTG_HR_WS_FILENAMES1';
   BEGIN
      fnd_file.put_line
         (fnd_file.LOG,
          '+--------------------------------------------------------------------------------+'
         );
      fnd_file.put_line
         (fnd_file.LOG,
          '+-----------------------INTG PF Work Structure Interface-------------------------+'
         );
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed');
      fnd_file.put_line (fnd_file.LOG, 'Effective Date: ' || p_eff_date);
      fnd_file.put_line (fnd_file.LOG, 'File Name: ' || p_file_name);
      l_eff_date := fnd_date.canonical_to_date (p_eff_date);

      IF (p_file_name IS NULL)
      THEN
         BEGIN
            FOR rec_lov IN csr_lov
            LOOP
               xxintg_hr_pf_ws_pkg.hr_pf_wsdata (l_errbuff,
                                                 l_retcode,
                                                 l_eff_date,
                                                 rec_lov.flex_value
                                                );
            END LOOP;
         END;
      ELSE
         xxintg_hr_pf_ws_pkg.hr_pf_wsdata (l_errbuff,
                                           l_retcode,
                                           l_eff_date,
                                           p_file_name
                                          );
      END IF;

      x_retcode := l_retcode;
      x_errbuff := l_errbuff;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := SQLCODE;
         x_errbuff := 'Error in the Main procedure' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, x_errbuff);
   END main;

-- Procedure to Process each datafile based on file_name parameter
      PROCEDURE hr_pf_wsdata(x_errbuff OUT VARCHAR2,
                                 x_retcode OUT NUMBER,
                                 p_eff_date IN DATE,
                                 p_file_name IN NUMBER) IS

          l_errbuff varchar2(2000);
          l_retcode number;
          l_prog_id number;
          l_eff_date date;

          BEGIN

              IF  p_file_name = 2 THEN
                 xxintg_hr_pf_ws_pkg.hr_pf_org_data(l_errbuff,
                                                           l_retcode,
                                                           p_eff_date,
                                                           p_file_name);
              ELSIF  p_file_name = 3 THEN
                 xxintg_hr_pf_ws_pkg.hr_pf_job_data(l_errbuff,
                                                           l_retcode,
                                                           p_eff_date,
                                                           p_file_name);

              ELSIF p_file_name = 4 THEN
                  xxintg_hr_pf_ws_pkg.hr_pf_pos_a_data(l_errbuff,
                                                           l_retcode,
                                                           p_eff_date,
                                                           p_file_name);
              ELSIF p_file_name = 5 THEN
                  xxintg_hr_pf_ws_pkg.hr_pf_pos_b_data(l_errbuff,
                                                           l_retcode,
                                                           p_eff_date,
                                                           p_file_name);

              END IF;

                x_retcode := l_retcode;
                x_errbuff := l_errbuff;

             fnd_file.put_line (fnd_file.LOG, x_errbuff );

      EXCEPTION
         WHEN OTHERS THEN
         x_retcode := SQLCODE;
         x_errbuff := 'Error in intg_hr_pf_employee procedure' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, x_errbuff );

   END hr_pf_wsdata;

-- Procedure for fetching Org data for 13_14 Organizations file
   PROCEDURE hr_pf_org_data(x_errbuff out VARCHAR2,
                            x_retcode out NUMBER,
                            p_eff_date IN DATE,
                            p_file_name IN NUMBER)
   IS
      l_program_num     NUMBER;
      l_succ_flag       VARCHAR2 (1);
      l_phone_label     VARCHAR2 (25);
      l_email_add       VARCHAR2 (250);
      l_error_message   VARCHAR2 (2500) := '';
      l_inactive        VARCHAR2 (10);
      l_file_name       VARCHAR2 (100)  := '13_14_Organizations';
      l_err_file_name   VARCHAR2 (100)  := '13_14 Organizations_Err_File';
      l_log_file_name   VARCHAR2 (100)  := '13_14 Organizations_Log_File';
      x_pf_error        EXCEPTION;
      x_ret_code        NUMBER          := 0;
      x_err_msg         VARCHAR2 (3000);

      CURSOR csr_org_data
      IS
         SELECT NULL nullid, hao.organization_id,
                NVL (hao.date_to,
                     TO_DATE ('31-DEC-4712', 'DD-MON-YYYY')
                    ) date_to,
                hao.NAME,
                NVL (SUBSTR (hao.NAME,
                             (INSTR (hao.NAME, '-', 1, 1) + 1),
                               INSTR (hao.NAME, '-', 1, 2)
                             - INSTR (hao.NAME, '-', 1, 1)
                             - 1
                            ),
                     hao.NAME
                    ) short_name,
                'SEASPINE' parent_org_ssrk, 'Division' TYPE,
                NVL (SUBSTR (hao.NAME,
                             INSTR (hao.NAME, '-', 1, 2) + 1,
                               INSTR (hao.NAME, '-', 1, 3)
                             - INSTR (hao.NAME, '-', 1, 2)
                             - 1
                            ),
                     hao.NAME
                    ) code_name,
                pcak.concatenated_segments cost_code
           FROM hr_all_organization_units hao,
                pay_cost_allocation_keyflex pcak,
                hr_organization_information hoi
          WHERE hao.cost_allocation_keyflex_id = pcak.cost_allocation_keyflex_id(+)
            AND hoi.organization_id = hao.organization_id
            AND hoi.org_information_context LIKE 'CLASS'
            AND hoi.org_information1 LIKE 'HR_ORG';
   BEGIN
      fnd_file.put_line
         (fnd_file.LOG,
          '+--------------------------------------------------------------------------------+'
         );
      fnd_file.put_line
         (fnd_file.LOG,
          '+-----------------------INTG PF Work Structure Org Interface-------------------------+'
         );
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed');
      fnd_file.put_line (fnd_file.LOG, 'Effective Date: ' || p_eff_date);
      fnd_file.put_line (fnd_file.LOG, 'File Name: ' || p_file_name);
      l_program_num := NULL;


         DELETE FROM intg_hr_pf_org_data;

         COMMIT;

         FOR rec_org_data IN csr_org_data
         LOOP
            l_succ_flag := 'Y';
            l_error_message := '';

            IF rec_org_data.date_to < p_eff_date
            THEN
               l_inactive := '1';
            ELSE
               l_inactive := '0';
            END IF;

            BEGIN
               INSERT INTO intg_hr_pf_org_data
                           (documenttype, senderid,
                            receiverid, VERSION, ID,
                            sourcesysrefkey, inactive,
                            formalname, shortname,
                            parentorgsourcesysrefkey, TYPE,
                            codename, costcode,
                            error_flag, error_msg
                           )
                    VALUES ('AuthoriaOrganizations', '948439432',
                            '178675716', '1.22.110200', rec_org_data.nullid,
                            rec_org_data.organization_id, l_inactive,
                            rec_org_data.NAME, rec_org_data.short_name,
                            rec_org_data.parent_org_ssrk, rec_org_data.TYPE,
                            rec_org_data.code_name, rec_org_data.cost_code,
                            'S', l_error_message
                           );

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_succ_flag := 'N';
                  x_retcode := SQLCODE;
                  l_error_message :=
                        'ERROR WHILE INSERTING INTO STAGING TABLE'
                     || SQLERRM
                     || ' FOR Organization: '
                     || rec_org_data.NAME;
                  x_errbuff := l_error_message;
                  fnd_file.put_line (fnd_file.LOG, l_error_message);
            END;
         END LOOP;

         x_ret_code := NULL;
         x_err_msg := NULL;
         l_file_name :=
               l_file_name
            || '_'
            || x_request_id
            || '_'
            || TO_DATE (SYSDATE, 'DD-MON_YYYY')
            || '.txt';

         create_pf_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         x_ret_code := NULL;
         x_err_msg := NULL;

         l_file_name :=
               '13_14_Organizations'
            || '_'
            || 'Err'
            || '_'
            || x_request_id
            || '_'
            || TO_DATE (SYSDATE, 'DD-MON_YYYY')
            || '.csv';

         create_pf_err_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         l_file_name :=
               '13_14_Organizations'
            || '_'
            || 'Log'
            || '_'
            || x_request_id
            || '_'
            || TO_DATE (SYSDATE, 'DD-MON_YYYY')
            || '.txt';

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
      WHEN OTHERS
      THEN
         l_succ_flag := 'N';
         x_retcode := SQLCODE;
         l_error_message :=
            'Error in the procedure While processing' || p_file_name
            || SQLERRM;
         x_errbuff := l_error_message;
         fnd_file.put_line (fnd_file.LOG, l_error_message);
   END hr_pf_org_data;

-- Procedure for fetching job data for 15_Jobs file
PROCEDURE hr_pf_job_data(x_errbuff out VARCHAR2,
                                     x_retcode out NUMBER,
                                     p_eff_date IN DATE,
                                     p_file_name IN NUMBER)
   IS
      l_program_num     NUMBER;
      l_succ_flag       VARCHAR2 (1);
      l_phone_label     VARCHAR2 (25);
      l_email_add       VARCHAR2 (250);
      l_error_message   VARCHAR2 (2500) := '';
      l_inactive        VARCHAR2 (10);
      l_file_name           VARCHAR2 (100)     := '15_Jobs';
      l_err_file_name varchar2(100) :='15_Jobs_Err_File';
      l_log_file_name varchar2(100) :='15_Jobs_Log_File';
      x_pf_error        EXCEPTION;
      x_ret_code        NUMBER          := 0;
      x_err_msg         VARCHAR2 (3000);

      CURSOR csr_job_data
      IS
         select pj.job_id SourceSysRefKey,
           nvl(pj.date_to,TO_DATE ('31-DEC-4712', 'DD-MON-YYYY')) date_to,
           pj.job_id CODE,
           pj.name Description,
           hr_general.decode_lookup('US_EEO1_JOB_CATEGORIES',pj.job_information1) EEOCategory,
           decode(pj.job_information3,'EX','1','0') FLSAExempt,
           pd.segment1 JobFamily,
           pd.segment2 ManagementLevel,
           pj.name Title_Single_Value,
           'en_US' Title_Locale,
           'global_job_level' CustomName1,
           pj.attribute4 CustomValue1,
           'job_group_level' CustomName2,
           pj.Attribute3 CustomValue2
     from per_jobs pj,
     per_job_definitions pd
    where pj.job_definition_id=pd.job_definition_id;
   BEGIN
      fnd_file.put_line
         (fnd_file.LOG,
          '+--------------------------------------------------------------------------------+'
         );
      fnd_file.put_line
         (fnd_file.LOG,
          '+-----------------------INTG PF Work Structure Job Interface-------------------------+'
         );
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed');
      fnd_file.put_line (fnd_file.LOG, 'Effective Date: ' || p_eff_date);
      fnd_file.put_line (fnd_file.LOG, 'File Name: ' || p_file_name);
      l_program_num := NULL;


         DELETE FROM intg_hr_pf_job_data;

         COMMIT;

         FOR rec_job_data IN csr_job_data
         LOOP
            l_succ_flag := 'Y';
            l_error_message := '';

            IF rec_job_data.date_to < p_eff_date
            THEN
               l_inactive := '1';
            ELSE
               l_inactive := '0';
            END IF;

            BEGIN
               INSERT INTO intg_hr_pf_job_data
                           (DOCUMENTTYPE,
                            SENDERID,
                            RECEIVERID,
                            VERSION,
                            SOURCESYSREFKEY,
                            INACTIVE,
                            CODE,
                            DESCRIPTION,
                            EEOCATEGORY,
                            FLSAEXEMPT,
                            JOBFAMILY,
                            MANAGEMENTLEVEL,
                            TITLE_SINGLE_VALUE,
                            TITLE_LOCALE,
                            CUSTOMNAME1,
                            CUSTOMVALUE1,
                            CUSTOMNAME2,
                            CUSTOMVALUE2,
                            error_flag,
                            error_msg)
                    VALUES ('AuthoriaJobs',
                          '948439432',
                          '178675716',
                          '1.22.110200',
                          rec_job_data.SourceSysRefKey,
                          l_inactive,
                          rec_job_data.CODE,
                          rec_job_data.Description,
                          rec_job_data.EEOCategory,
                          rec_job_data.FLSAExempt,
                          rec_job_data.JobFamily,
                          rec_job_data.ManagementLevel,
                          rec_job_data.Title_Single_Value,
                          rec_job_data.Title_Locale,
                          rec_job_data.CustomName1,
                          rec_job_data.CustomValue1,
                          rec_job_data.CustomName2,
                          rec_job_data.CustomValue2,
                          'S',
                          l_error_message);

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_succ_flag := 'N';
                  x_retcode := SQLCODE;
                  l_error_message :=
                        'ERROR WHILE INSERTING INTO STAGING TABLE'
                     || SQLERRM
                     || ' FOR Jobs: '
                     || rec_job_data.Description;
                  x_errbuff := l_error_message;
                  fnd_file.put_line (fnd_file.LOG, l_error_message);
            END;
         END LOOP;

         x_ret_code := NULL;
         x_err_msg := NULL;
         l_file_name :=
               l_file_name
            || '_'
            || x_request_id
            || '_'
            || TO_DATE (SYSDATE, 'DD-MON_YYYY')
            || '.txt';

         create_pf_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         x_ret_code := NULL;
         x_err_msg := NULL;

         l_file_name :=
               '15_Jobs'
            || '_'
            || 'Err'
            || '_'
            || x_request_id
            || '_'
            || TO_DATE (SYSDATE, 'DD-MON_YYYY')
            || '.csv';

         create_pf_err_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         l_file_name :=
               '15_Jobs'
            || '_'
            || 'Log'
            || '_'
            || x_request_id
            || '_'
            || TO_DATE (SYSDATE, 'DD-MON_YYYY')
            || '.txt';

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
      WHEN OTHERS
      THEN
         l_succ_flag := 'N';
         x_retcode := SQLCODE;
         l_error_message :=
            'Error in the procedure While processing' || p_file_name
            || SQLERRM;
         x_errbuff := l_error_message;
         fnd_file.put_line (fnd_file.LOG, l_error_message);
   END hr_pf_job_data;

-- Procedure for fetching Positions data for 17(a)_Positions file
PROCEDURE hr_pf_pos_a_data(x_errbuff out VARCHAR2,
                                     x_retcode out NUMBER,
                                     p_eff_date IN DATE,
                                     p_file_name IN NUMBER)
   IS
      l_program_num     NUMBER;
      l_succ_flag       VARCHAR2 (1);
      l_phone_label     VARCHAR2 (25);
      l_email_add       VARCHAR2 (250);
      l_error_message   VARCHAR2 (2500) := '';
      l_inactive        VARCHAR2 (10);
      l_file_name           VARCHAR2 (100)     := '17(a)_Positions';
      l_err_file_name varchar2(100) :='17(a)_Positions_Err_File';
      l_log_file_name varchar2(100) :='17(a)_Positions_Log_File';
      x_pf_error        EXCEPTION;
      x_ret_code        NUMBER          := 0;
      x_err_msg         VARCHAR2 (3000);
      l_pos_occupancy   NUMBER(10);

      CURSOR csr_pos_data
      IS
         select hapf.position_id SourceSysRefKey
     ,hapf.position_id PositionCode
     ,'Fulltime-Regular' PositionType
     ,hapf.name title
     ,'en_US' Language
     , NULL Managed_by_Position
     ,'1' NumberInOrg
     ,hapf.organization_id
     ,hapf.job_id
     ,(select hla.location_code
       from  hr_locations_all hla
       where hla.location_id=hapf.location_id) CountryCode
     from hr_all_positions_f hapf
     where not exists (select 1
                        from per_all_assignments_f paaf
                        where trunc(p_eff_date) between paaf.effective_start_date and paaf.effective_end_date
                        and paaf.position_id = hapf.position_id
                        and paaf.assignment_type = 'E'
                        )
     and trunc(p_eff_date) between hapf.effective_start_date and hapf.effective_end_date
     union
     select hapf.position_id SourceSysRefKey
     ,hapf.position_id PositionCode
     ,apps.hr_general.decode_lookup('EMP_CAT', nvl(paaf.employment_category,'FR')) PositionType
     ,hapf.name title
     ,'en_US' Language
     , xxintg_hr_pf_ws_pkg.get_sup_position(paaf.person_id,trunc(p_eff_date)) Managed_by_Position
     ,'1' NumberInOrg
     ,hapf.organization_id
     ,hapf.job_id
     ,(select hla.location_code
       from  hr_locations_all hla
       where hla.location_id=hapf.location_id) CountryCode
     from hr_all_positions_f hapf
     ,per_all_assignments_f paaf
     where paaf.position_id = hapf.position_id
     and paaf.assignment_type = 'E'
     and paaf.primary_flag = 'Y'
     and trunc(p_eff_date) between hapf.effective_start_date and hapf.effective_end_date
     and trunc(p_eff_date) between paaf.effective_start_date and paaf.effective_end_date;
   BEGIN
      fnd_file.put_line
         (fnd_file.LOG,
          '+--------------------------------------------------------------------------------+'
         );
      fnd_file.put_line
         (fnd_file.LOG,
          '+-----------------------INTG PF Work Structure Positions Interface-------------------------+'
         );
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed');
      fnd_file.put_line (fnd_file.LOG, 'Effective Date: ' || p_eff_date);
      fnd_file.put_line (fnd_file.LOG, 'File Name: ' || p_file_name);
      l_program_num := NULL;


         DELETE FROM intg_hr_pf_pos_data;

         COMMIT;

         FOR rec_pos_data IN csr_pos_data
         LOOP
            l_succ_flag := 'Y';
            l_error_message := '';

            IF rec_pos_data.CountryCode IS NULL --AND rec_pos_data.PositionCode <> 4061
            THEN
               l_succ_flag := 'N';
               l_error_message := rec_pos_data.title||' '||'does not have a location assinged';
            END IF;

            BEGIN
                select count(person_id)
        into l_pos_occupancy
        from per_all_assignments_f a
        where trunc(sysdate) between a.effective_start_date and a.effective_end_date
        and a.position_id= rec_pos_data.PositionCode
        --and a.position_id <> 4061
        and a.assignment_type = 'E'
        and a.assignment_status_type_id <> 3;

            EXCEPTION
                WHEN OTHERS THEN
                    l_pos_occupancy :=1;
             END;

             IF l_pos_occupancy > 1 THEN
                 l_succ_flag := 'N';
                 l_error_message := rec_pos_data.title||' '||'more than 1 employees have occupied this position at the same time';
             END IF;

            BEGIN
               INSERT INTO intg_hr_pf_pos_data
                           (DOCUMENTTYPE,
                            SENDERID,
                            RECEIVERID,
                            VERSION,
                            SOURCESYSREFKEY,
                            POSITIONCODE,
                            POSITIONTYPE,
                            TITLE,
                            LANGUAGE,
                            MANAGEDPOSITIONSOURCESYSREFKEY,
                            NUMBERINORG,
                            ORGSOURCESYSREFKEY,
                            JOBSOURCESYSREFKEY,
                            COUNTRYCODE,
                            error_flag,
                            error_msg)
                    VALUES ('AuthoriaPositions',
                            '948439432',
                            '178675716',
                            '1.22.110200',
                            rec_pos_data.SourceSysRefKey,
                            rec_pos_data.PositionCode,
                            rec_pos_data.PositionType,
                            rec_pos_data.title,
                            rec_pos_data.language,
                            rec_pos_data.Managed_by_Position,
                            rec_pos_data.NUMBERINORG,
                            rec_pos_data.organization_id,
                            rec_pos_data.job_id,
                            rec_pos_data.COUNTRYCODE,
                            decode(l_succ_flag,'N','E','S')
                            ,l_error_message
                           );

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_succ_flag := 'N';
                  x_retcode := SQLCODE;
                  l_error_message :=
                        'ERROR WHILE INSERTING INTO STAGING TABLE'
                     || SQLERRM
                     || ' FOR Positions: '
                     || rec_pos_data.title;
                  x_errbuff := l_error_message;
                  fnd_file.put_line (fnd_file.LOG, l_error_message);
            END;
         END LOOP;

         x_ret_code := NULL;
         x_err_msg := NULL;
         l_file_name :=
               l_file_name
            || '_'
            || x_request_id
            || '_'
            || TO_DATE (SYSDATE, 'DD-MON_YYYY')
            || '.txt';

         create_pf_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         x_ret_code := NULL;
         x_err_msg := NULL;

         l_file_name :=
               '17 Positions'
            || '_'
            || 'Err'
            || '_'
            || x_request_id
            || '_'
            || TO_DATE (SYSDATE, 'DD-MON_YYYY')
            || '.csv';

         create_pf_err_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         l_file_name :=
               '17 Positions'
            || '_'
            || 'Log'
            || '_'
            || x_request_id
            || '_'
            || TO_DATE (SYSDATE, 'DD-MON_YYYY')
            || '.txt';

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
      WHEN OTHERS
      THEN
         l_succ_flag := 'N';
         x_retcode := SQLCODE;
         l_error_message :=
            'Error in the procedure While processing' || p_file_name
            || SQLERRM;
         x_errbuff := l_error_message;
         fnd_file.put_line (fnd_file.LOG, l_error_message);
   END hr_pf_pos_a_data;

-- Procedure for fetching Positions data for 17(b)_Positions file
 PROCEDURE hr_pf_pos_b_data(x_errbuff out VARCHAR2,
                                     x_retcode out NUMBER,
                                     p_eff_date IN DATE,
                                     p_file_name IN NUMBER)
  as

      l_program_num     NUMBER;
      l_succ_flag       VARCHAR2 (1);
      l_phone_label     VARCHAR2 (25);
      l_email_add       VARCHAR2 (250);
      l_error_message   VARCHAR2 (2500) := '';
      l_inactive        VARCHAR2 (10);
      l_file_name           VARCHAR2 (100)     := '17(b)_Positions';
      l_err_file_name varchar2(100) :='17(b)_Positions_Err_File';
      l_log_file_name varchar2(100) :='17(b)_Positions_Log_File';
      x_pf_error        EXCEPTION;
      x_ret_code        NUMBER          := 0;
      x_err_msg         VARCHAR2 (3000);

  begin
         x_ret_code := NULL;
         x_err_msg := NULL;

         l_file_name :=
               l_file_name
            || '_'
            || x_request_id
            || '_'
            || TO_DATE (SYSDATE, 'DD-MON_YYYY')
            || '.txt';

         create_pf_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         x_ret_code := NULL;
         x_err_msg := NULL;

     /*    l_file_name :=
               '17(b)_Positions'
            || '_'
            || 'Err'
            || '_'
            || x_request_id
            || '_'
            || TO_DATE (SYSDATE, 'DD-MON_YYYY')
            || '.csv';

       create_pf_err_file (p_file_name, l_file_name, x_ret_code, x_err_msg);

         l_file_name :=
               '17(b)_Positions'
            || '_'
            || 'Log'
            || '_'
            || x_request_id
            || '_'
            || TO_DATE (SYSDATE, 'DD-MON_YYYY')
            || '.txt';

         create_pf_log_file (p_file_name, l_file_name, x_ret_code, x_err_msg);*/

         fnd_file.put_line (fnd_file.LOG, 'After Create File Proc');

         IF NVL (x_ret_code, 0) <> 0
         THEN
            RAISE x_pf_error;
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'write_org_file ->' || x_ret_code
                              );
   EXCEPTION
      WHEN OTHERS
      THEN
         l_succ_flag := 'N';
         x_retcode := SQLCODE;
         l_error_message :=
            'Error in the procedure While processing' || p_file_name
            || SQLERRM;
         x_errbuff := l_error_message;
         fnd_file.put_line (fnd_file.LOG, l_error_message);


  end hr_pf_pos_b_data;

-- Procedure for creating data file
  PROCEDURE create_pf_file (
      p_file_number   IN       VARCHAR2,
      p_file_name     IN       VARCHAR2,
      x_return_code   OUT      NUMBER,
      x_error_msg     OUT      VARCHAR2
   )
   IS
      CURSOR c_write_org_data
      IS
         SELECT    documenttype
                || g_csv
                || senderid
                || g_csv
                || receiverid
                || g_csv
                || VERSION
                || g_csv
                || ID
                || g_csv
                || sourcesysrefkey
                || g_csv
                || inactive
                || g_csv
                || formalname
                || g_csv
                || shortname
                || g_csv
                || parentorgsourcesysrefkey
                || g_csv
                || TYPE
                || g_csv
                || codename
                || g_csv
                || costcode
                || g_csv
                || mailingaddressline1
                || g_csv
                || mailingaddressline2
                || g_csv
                || mailingaddressline3
                || g_csv
                || streetname
                || g_csv
                || buildingnumber
                || g_csv
                || postofficebox
                || g_csv
                || unit
                || g_csv
                || municipality
                || g_csv
                || region
                || g_csv
                || countrycode
                || g_csv
                || postalcode
                || g_csv
                || recipientaristocraticprefix
                || g_csv
                || recipientformofaddress
                || g_csv
                || recipientgivenname
                || g_csv
                || recipientpreferredgivenname
                || g_csv
                || recipientmiddlename
                || g_csv
                || recipientfamilyname
                || g_csv
                || recipientextraname
                || g_csv
                || recipientgeneration
                || g_csv
                || recipientlegalname
                || g_csv
                || recipientmaidenname
                || g_csv
                || recipientadditionaltext
                || g_csv
                || recipientorganizationname
                || g_csv
                || physicaladdressline1
                || g_csv
                || physicaladdressline2
                || g_csv
                || physicaladdressline3
                || g_csv
                || streetname1
                || g_csv
                || buildingnumber1
                || g_csv
                || postofficebox1
                || g_csv
                || unit1
                || g_csv
                || municipality1
                || g_csv
                || region1
                || g_csv
                || countrycode1
                || g_csv
                || postalcode1
                || g_csv
                || recipientaristocraticprefix1
                || g_csv
                || recipientformofaddress1
                || g_csv
                || recipientgivenname1
                || g_csv
                || recipientpreferredgivenname1
                || g_csv
                || recipientmiddlename1
                || g_csv
                || recipientfamilyname1
                || g_csv
                || recipientextraname1
                || g_csv
                || recipientgeneration1
                || g_csv
                || recipientlegalname1
                || g_csv
                || recipientmaidenname1
                || g_csv
                || recipientadditionaltext1
                || g_csv
                || recipientorganizationname1
                || g_csv
                || customname1
                || g_csv
                || custombody1
                || g_csv
                || customname2
                || g_csv
                || custombody2
                || g_csv
                || customname3
                || g_csv
                || custombody3
                || g_csv
                || customname4
                || g_csv
                || custombody4
                || g_csv
                || customname5
                || g_csv
                || custombody5
                || g_csv
                || customname6
                || g_csv
                || custombody6
                || g_csv
                || customname7
                || g_csv
                || custombody7
                || g_csv
                || customname8
                || g_csv
                || custombody8
                || g_csv
                || customname9
                || g_csv
                || custombody9
                || g_csv
                || customname10
                || g_csv
                || custombody10
                || g_csv
                || diversityorganization
                || g_csv
                || latitude
                || g_csv
                || longitude
                || g_csv rec
           FROM intg_hr_pf_org_data
          WHERE error_flag = 'S';

      CURSOR c_write_job_data
      IS
         SELECT documenttype||g_csv||
                   senderid||g_csv||
                   receiverid||g_csv||
                   version||g_csv||
                   id||g_csv||
                   sourcesysrefkey||g_csv||
                   inactive||g_csv||
                   code||g_csv||
                   description||g_csv||
                   eeocategory||g_csv||
                   flsaexempt||g_csv||
                   jobfamily||g_csv||
                   managementlevel||g_csv||
                   referralbonus||g_csv||
                   salarygradessrk||g_csv||
                   segment||g_csv||
                   TITLE_I18NKEY||g_csv||
                   title_single_value||g_csv||
                   title_locale||g_csv||
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
                   slateable||g_csv||
                   jobfunction||g_csv||
                   agencysourced||g_csv||
                   collegesourced||g_csv||
                   recommendedsalarypercentile||g_csv||
                   emergencyhirelist||g_csv||
                   promotionrank||g_csv||
                   promotioncategory||g_csv||
                   grade||g_csv||
                   diversityjobgroupcode||g_csv||
                   diversityjobgroupdisplaytext||g_csv rec
             FROM intg_hr_pf_job_data
             WHERE error_flag = 'S';

      CURSOR c_write_pos_a_data
      IS
      select documenttype||g_csv||
                          senderid||g_csv||
                          receiverid||g_csv||
                          version||g_csv||
                          id||g_csv||
                          sourcesysrefkey||g_csv||
                          positioncode||g_csv||
                          positiontype||g_csv||
                          title||g_csv||
                          language||g_csv||
                          budgeted||g_csv||
                          costcode||g_csv||
                          to_char(effectivedate,'YYYY-MM-DD')||g_csv||
                          to_char(enddate,'YYYY-MM-DD')||g_csv||
                          NULL||g_csv||
                          numberinorg||g_csv||
                          orgsourcesysrefkey||g_csv||
                          orgrollupsourcesysrefkey1||g_csv||
                          orgrollupsourcesysrefkey2||g_csv||
                          orgrollupsourcesysrefkey3||g_csv||
                          orgrollupsourcesysrefkey4||g_csv||
                          orgrollupsourcesysrefkey5||g_csv||
                          jobsourcesysrefkey||g_csv||
                          salarygradesourcesysrefkey||g_csv||
                          to_char(startdate,'YYYY-MM-DD')||g_csv||
                          workschedule||g_csv||
                          recruiter1sourcesysrefkey||g_csv||
                          recruiter2sourcesysrefkey||g_csv||
                          recruiter3sourcesysrefkey||g_csv||
                          recruiter4sourcesysrefkey||g_csv||
                          recruiter5sourcesysrefkey||g_csv||
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
                          customname1||g_csv||
                          custombody1||g_csv||
                          customname2||g_csv||
                          custombody2||g_csv||
                          customname3||g_csv||
                          custombody3||g_csv||
                          customname4||g_csv||
                          custombody4||g_csv||
                          customname5||g_csv||
                          custombody5||g_csv||
                          customname6||g_csv||
                          custombody6||g_csv||
                          customname7||g_csv||
                          custombody7||g_csv||
                          customname8||g_csv||
                          custombody8||g_csv||
                          customname9||g_csv||
                          custombody9||g_csv||
                          customname10||g_csv||
                          custombody10||g_csv||
                          slateable||g_csv||
                          geographicorganizationssrk||g_csv  rec
           from   intg_hr_pf_pos_data
           where error_flag = 'S';

           CURSOR c_write_pos_b_data
             IS
             select documenttype||g_csv||
                                 senderid||g_csv||
                                 receiverid||g_csv||
                                 version||g_csv||
                                 id||g_csv||
                                 sourcesysrefkey||g_csv||
                                 positioncode||g_csv||
                                 positiontype||g_csv||
                                 title||g_csv||
                                 language||g_csv||
                                 budgeted||g_csv||
                                 costcode||g_csv||
                                 to_char(effectivedate,'YYYY-MM-DD')||g_csv||
                                 to_char(enddate,'YYYY-MM-DD')||g_csv||
                                 managedpositionsourcesysrefkey||g_csv||
                                 numberinorg||g_csv||
                                 orgsourcesysrefkey||g_csv||
                                 orgrollupsourcesysrefkey1||g_csv||
                                 orgrollupsourcesysrefkey2||g_csv||
                                 orgrollupsourcesysrefkey3||g_csv||
                                 orgrollupsourcesysrefkey4||g_csv||
                                 orgrollupsourcesysrefkey5||g_csv||
                                 jobsourcesysrefkey||g_csv||
                                 salarygradesourcesysrefkey||g_csv||
                                 to_char(startdate,'YYYY-MM-DD')||g_csv||
                                 workschedule||g_csv||
                                 recruiter1sourcesysrefkey||g_csv||
                                 recruiter2sourcesysrefkey||g_csv||
                                 recruiter3sourcesysrefkey||g_csv||
                                 recruiter4sourcesysrefkey||g_csv||
                                 recruiter5sourcesysrefkey||g_csv||
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
                                 customname1||g_csv||
                                 custombody1||g_csv||
                                 customname2||g_csv||
                                 custombody2||g_csv||
                                 customname3||g_csv||
                                 custombody3||g_csv||
                                 customname4||g_csv||
                                 custombody4||g_csv||
                                 customname5||g_csv||
                                 custombody5||g_csv||
                                 customname6||g_csv||
                                 custombody6||g_csv||
                                 customname7||g_csv||
                                 custombody7||g_csv||
                                 customname8||g_csv||
                                 custombody8||g_csv||
                                 customname9||g_csv||
                                 custombody9||g_csv||
                                 customname10||g_csv||
                                 custombody10||g_csv||
                                 slateable||g_csv||
                                 geographicorganizationssrk||g_csv  rec
                  from   intg_hr_pf_pos_data
                     where error_flag = 'S';


      x_file_pf_type   UTL_FILE.file_type;
      x_data_pf_dir    VARCHAR2 (80);
      x_pf_org_data    VARCHAR2 (4000);
      x_pf_job_data    VARCHAR2 (4000);
      x_pf_pos_a_data  VARCHAR2 (4000);
      x_pf_pos_b_data  VARCHAR2 (4000);
      x_err_out        VARCHAR2 (4000);
      x_file_name      VARCHAR2 (1000)    := p_file_name;
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
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'file name-> ' || p_file_name
                           );

      -- opening the file
      BEGIN
         x_file_pf_type :=
                 UTL_FILE.fopen_nchar (x_data_pf_dir, p_file_name, 'W', 6400);
      EXCEPTION
         WHEN UTL_FILE.invalid_path
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'Invalid Path for File :' || p_file_name;
         WHEN UTL_FILE.invalid_filehandle
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'File handle is invalid for File :' || p_file_name;
         WHEN UTL_FILE.write_error
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'Unable to write the File :' || p_file_name;
         WHEN UTL_FILE.invalid_operation
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg :=
                      'File could not be opened for writting:' || p_file_name;
         WHEN UTL_FILE.invalid_maxlinesize
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'File ' || p_file_name;
         WHEN UTL_FILE.access_denied
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'Access denied for File :' || p_file_name;
         WHEN OTHERS
         THEN
            x_return_code := xx_emf_cn_pkg.cn_prc_err;
            x_error_msg := 'File ' || p_file_name || '->' || SQLERRM;
      END;

      IF p_file_number = 2
      THEN
         FOR rec_write_org_data IN c_write_org_data
         LOOP
            x_pf_org_data := NULL;
            x_pf_org_data := rec_write_org_data.rec;
            -- UTL_FILE.PUT_LINE(x_file_lrn_type,x_lrn_data);
            UTL_FILE.put_line_nchar (x_file_pf_type, x_pf_org_data);
         END LOOP;

         IF UTL_FILE.is_open (x_file_pf_type)
         THEN
            UTL_FILE.fclose (x_file_pf_type);
         END IF;
       ELSIF p_file_number = 3
               THEN
                 FOR rec_write_job_data IN c_write_job_data
                 LOOP
                    x_pf_job_data := NULL;
                    x_pf_job_data := rec_write_job_data.rec;
                    -- UTL_FILE.PUT_LINE(x_file_lrn_type,x_lrn_data);
                    UTL_FILE.put_line_nchar (x_file_pf_type, x_pf_job_data);
                 END LOOP;

                 IF UTL_FILE.is_open (x_file_pf_type)
                 THEN
                    UTL_FILE.fclose (x_file_pf_type);
                 END IF;
       ELSIF p_file_number = 4
               THEN
                 FOR rec_write_pos_a_data IN c_write_pos_a_data
                 LOOP
                    x_pf_pos_a_data := NULL;
                    x_pf_pos_a_data := rec_write_pos_a_data.rec;
                    UTL_FILE.put_line_nchar (x_file_pf_type, x_pf_pos_a_data);
                 END LOOP;

                 IF UTL_FILE.is_open (x_file_pf_type)
                 THEN
                    UTL_FILE.fclose (x_file_pf_type);
                 END IF;
        ELSIF p_file_number = 5
               THEN
                 FOR rec_write_pos_b_data IN c_write_pos_b_data
                 LOOP
                    x_pf_pos_b_data := NULL;
                    x_pf_pos_b_data := rec_write_pos_b_data.rec;
                    UTL_FILE.put_line_nchar (x_file_pf_type, x_pf_pos_b_data);
                 END LOOP;

                 IF UTL_FILE.is_open (x_file_pf_type)
                 THEN
                    UTL_FILE.fclose (x_file_pf_type);
                 END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_error_msg := 'Procedure - write_pf_file ->' || SQLERRM;
         x_return_code := xx_emf_cn_pkg.cn_prc_err;
   END create_pf_file;

-- Procedure for creating and mailing Error file
   PROCEDURE create_pf_err_file (
       p_file_number   IN       VARCHAR2,
       p_file_name     IN       VARCHAR2,
       x_return_code   OUT      NUMBER,
       x_error_msg     OUT      VARCHAR2
    )
    IS
       CURSOR c_write_err_org_data
       IS
          SELECT formalname, error_msg
            FROM intg_hr_pf_org_data
           WHERE error_flag = 'E';

       CURSOR c_write_err_job_data
       IS
          SELECT description, error_msg
            FROM intg_hr_pf_job_data
           WHERE error_flag = 'E';

        CURSOR c_write_err_pos_data
       IS
          SELECT distinct title, error_msg
            FROM intg_hr_pf_pos_data
           WHERE error_flag = 'E';

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
       x_pf_org_log_data   VARCHAR2 (4000);
       x_pf_org_err_data   VARCHAR2 (4000);
       x_pf_job_err_data   VARCHAR2 (4000);
       x_pf_pos_err_data   VARCHAR2 (4000);
       x_err_data_head     VARCHAR2 (4000);                 -- added for header
       x_err_out           VARCHAR2 (4000);
       x_file_name         VARCHAR2 (1000)    := p_file_name;
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
       l_file_name_str     VARCHAR2 (150)
                                        := 'File Name' || CHR (9)
                                           || p_file_name;
       l_requestid_str     VARCHAR2 (150)
                                      := 'Request ID' || CHR (9)
                                         || x_request_id;
       l_tot_rec_str       VARCHAR2 (200);
       l_suc_rec_str       VARCHAR2 (200);
       l_err_rec_str       VARCHAR2 (200);
    BEGIN
       xx_intg_common_pkg.get_process_param_value
                                             (p_process_name      => 'XXINTGPFWSE',
                                              p_param_name        => 'ERROR_DIR',
                                              x_param_value       => x_err_pf_dir
                                             );
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                             'file name-> ' || p_file_name
                            );

       -- opening the error file
       BEGIN
          x_file_err_type :=
                   UTL_FILE.fopen_nchar (x_err_pf_dir, p_file_name, 'W', 6400);
       EXCEPTION
          WHEN UTL_FILE.invalid_path
          THEN
             x_return_code := xx_emf_cn_pkg.cn_prc_err;
             x_error_msg := 'Invalid Path for File :' || p_file_name;
          WHEN UTL_FILE.invalid_filehandle
          THEN
             x_return_code := xx_emf_cn_pkg.cn_prc_err;
             x_error_msg := 'File handle is invalid for File :' || p_file_name;
          WHEN UTL_FILE.write_error
          THEN
             x_return_code := xx_emf_cn_pkg.cn_prc_err;
             x_error_msg := 'Unable to write the File :' || p_file_name;
          WHEN UTL_FILE.invalid_operation
          THEN
             x_return_code := xx_emf_cn_pkg.cn_prc_err;
             x_error_msg :=
                       'File could not be opened for writting:' || p_file_name;
          WHEN UTL_FILE.invalid_maxlinesize
          THEN
             x_return_code := xx_emf_cn_pkg.cn_prc_err;
             x_error_msg := 'File ' || p_file_name;
          WHEN UTL_FILE.access_denied
          THEN
             x_return_code := xx_emf_cn_pkg.cn_prc_err;
             x_error_msg := 'Access denied for File :' || p_file_name;
          WHEN OTHERS
          THEN
             x_return_code := xx_emf_cn_pkg.cn_prc_err;
             x_error_msg := 'File ' || p_file_name || '->' || SQLERRM;
       END;

       IF p_file_number = 2
       THEN
          x_err_data_head := 'Organization Name' || ',' || 'Error Description';
          UTL_FILE.put_line_nchar (x_file_err_type, x_err_data_head);

          FOR rec_write_err_org_data IN c_write_err_org_data
          LOOP
             x_pf_org_err_data := NULL;
             x_pf_org_err_data :=
                   '"'
                || rec_write_err_org_data.formalname
                || '"'
                || ','
                || '"'
                || rec_write_err_org_data.error_msg
                || '"';
             UTL_FILE.put_line_nchar (x_file_err_type, x_pf_org_err_data);
          END LOOP;

          IF UTL_FILE.is_open (x_file_err_type)
          THEN
             UTL_FILE.fclose (x_file_err_type);
          END IF;

          x_subject := 'PeopleFluent Organizations Error File';
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
              '------------------- PF Organizations Exception File Mailing   ------------------------'
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
              -- calling send mail program
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
       ELSIF p_file_number = 3
       THEN
          x_err_data_head := NULL;
          x_err_data_head := 'Job Name' || ',' || 'Error Description';
          UTL_FILE.put_line_nchar (x_file_err_type, x_err_data_head);

          FOR rec_write_err_job_data IN c_write_err_job_data
          LOOP
             x_pf_job_err_data := NULL;
             x_pf_job_err_data :=
                   '"'
                || rec_write_err_job_data.description
                || '"'
                || ','
                || '"'
                || rec_write_err_job_data.error_msg
                || '"';
             UTL_FILE.put_line_nchar (x_file_err_type, x_pf_job_err_data);
          END LOOP;

          IF UTL_FILE.is_open (x_file_err_type)
          THEN
             UTL_FILE.fclose (x_file_err_type);
          END IF;

          x_subject := 'PeopleFluent Jobs Error File';
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
              '------------------- PF Jobs Exception File Mailing   ------------------------'
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

             -- calling send mail program
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
        ELSIF p_file_number = 4
       THEN
          x_err_data_head := NULL;
          x_err_data_head := 'Position Name' || ',' || 'Error Description';
          UTL_FILE.put_line_nchar (x_file_err_type, x_err_data_head);

          FOR rec_write_err_pos_data IN c_write_err_pos_data
          LOOP
             x_pf_pos_err_data := NULL;
             x_pf_pos_err_data :=
                   '"'
                || rec_write_err_pos_data.title
                || '"'
                || ','
                || '"'
                || rec_write_err_pos_data.error_msg
                || '"';
             UTL_FILE.put_line_nchar (x_file_err_type, x_pf_pos_err_data);
          END LOOP;

          IF UTL_FILE.is_open (x_file_err_type)
          THEN
             UTL_FILE.fclose (x_file_err_type);
          END IF;

          x_subject := 'PeopleFluent Positions Error File';


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
              '------------------- PF Positions Exception File Mailing   ------------------------'
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
                -- calling send mail program
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

       END IF;
    EXCEPTION
       WHEN OTHERS
       THEN
          x_error_msg := 'Procedure - write_pf_file ->' || SQLERRM;
          x_return_code := xx_emf_cn_pkg.cn_prc_err;
   END create_pf_err_file;

-- Procedure for creating log file
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
       x_file_name         VARCHAR2 (1000)    := p_file_name;
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
       l_file_name_str     VARCHAR2 (150)
          :=    'File Name'
             || CHR (9)
             || '13_14 Organizations'
             || '_'
             || x_request_id
             || '_'
             || TO_DATE (SYSDATE, 'DD-MON_YYYY')
             || '.txt';

        l_file_name_str1     VARCHAR2 (150)
          :=    'File Name'
             || CHR (9)
             || '15 Jobs'
             || '_'
             || x_request_id
             || '_'
             || TO_DATE (SYSDATE, 'DD-MON_YYYY')
             || '.txt';

         l_file_name_str2     VARCHAR2 (150)
               :=    'File Name'
                  || CHR (9)
                  || '17 Positions'
                  || '_'
                  || x_request_id
                  || '_'
                  || TO_DATE (SYSDATE, 'DD-MON_YYYY')
                  || '.txt';


       l_requestid_str     VARCHAR2 (150)
                                      := 'Request ID' || CHR (9)
                                         || x_request_id;
       l_tot_rec_str       VARCHAR2 (200);
       l_suc_rec_str       VARCHAR2 (200);
       l_err_rec_str       VARCHAR2 (200);
       --   l_utl_dat_path  varchar2(150):='XXPPLFLWSDAT';
       l_utl_err_path      VARCHAR2 (150)     := 'XXPPLFLERR';
       l_utl_log_path      VARCHAR2 (150)     := 'XXPPLFLLOG';
    BEGIN
       xx_intg_common_pkg.get_process_param_value
                                             (p_process_name      => 'XXINTGPFWSE',
                                              p_param_name        => 'LOG_DIR',
                                              x_param_value       => x_log_pf_dir
                                             );
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                             'file name-> ' || p_file_name
                            );

       -- opening the error file
       BEGIN
          x_file_log_type :=
                         UTL_FILE.fopen (x_log_pf_dir, p_file_name, 'W', 6400);
       EXCEPTION
          WHEN UTL_FILE.invalid_path
          THEN
             x_return_code := xx_emf_cn_pkg.cn_prc_err;
             x_error_msg := 'Invalid Path for File :' || p_file_name;
          WHEN UTL_FILE.invalid_filehandle
          THEN
             x_return_code := xx_emf_cn_pkg.cn_prc_err;
             x_error_msg := 'File handle is invalid for File :' || p_file_name;
          WHEN UTL_FILE.write_error
          THEN
             x_return_code := xx_emf_cn_pkg.cn_prc_err;
             x_error_msg := 'Unable to write the File :' || p_file_name;
          WHEN UTL_FILE.invalid_operation
          THEN
             x_return_code := xx_emf_cn_pkg.cn_prc_err;
             x_error_msg :=
                       'File could not be opened for writting:' || p_file_name;
          WHEN UTL_FILE.invalid_maxlinesize
          THEN
             x_return_code := xx_emf_cn_pkg.cn_prc_err;
             x_error_msg := 'File ' || p_file_name;
          WHEN UTL_FILE.access_denied
          THEN
             x_return_code := xx_emf_cn_pkg.cn_prc_err;
             x_error_msg := 'Access denied for File :' || p_file_name;
          WHEN OTHERS
          THEN
             x_return_code := xx_emf_cn_pkg.cn_prc_err;
             x_error_msg := 'File ' || p_file_name || '->' || SQLERRM;
       END;

       IF p_file_number = 2
       THEN
          BEGIN
             SELECT COUNT (*)
               INTO l_total_count
               FROM intg_hr_pf_org_data;
          EXCEPTION
             WHEN OTHERS
             THEN
                l_total_count := 0;
          END;

          l_tot_rec_str := 'Total No. of Records' || CHR (9) || l_total_count;

          BEGIN
             SELECT COUNT (*)
               INTO l_success_count
               FROM intg_hr_pf_org_data
              WHERE error_flag = 'S';
          EXCEPTION
             WHEN OTHERS
             THEN
                l_success_count := 0;
          END;

          l_suc_rec_str :=
                    'Total No. of Success Records' || CHR (9)
                    || l_success_count;

          BEGIN
             SELECT COUNT (*)
               INTO l_failed_count
               FROM intg_hr_pf_org_data
              WHERE error_flag = 'E';
          EXCEPTION
             WHEN OTHERS
             THEN
                l_failed_count := 0;
          END;

          l_err_rec_str :=
                      'Total No. of Failed Records' || CHR (9)
                      || l_failed_count;
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

       ELSIF p_file_number = 4
       THEN
          BEGIN
             l_total_count := 0;
             SELECT COUNT (*)
               INTO l_total_count
               FROM intg_hr_pf_pos_data;
          EXCEPTION
             WHEN OTHERS
             THEN
                l_total_count := 0;
          END;

          l_tot_rec_str := 'Total No. of Records' || CHR (9) || l_total_count;

          BEGIN
            l_success_count := 0;
             SELECT COUNT (*)
               INTO l_success_count
               FROM intg_hr_pf_pos_data
              WHERE error_flag = 'S';
          EXCEPTION
             WHEN OTHERS
             THEN
                l_success_count := 0;
          END;

          l_suc_rec_str :=
                    'Total No. of Success Records' || CHR (9)
                    || l_success_count;

          BEGIN
             l_failed_count := 0;
             SELECT COUNT (*)
               INTO l_failed_count
               FROM intg_hr_pf_pos_data
              WHERE error_flag = 'E';
          EXCEPTION
             WHEN OTHERS
             THEN
                l_failed_count := 0;
          END;

          l_err_rec_str :=
                      'Total No. of Failed Records' || CHR (9)
                      || l_failed_count;
          UTL_FILE.new_line (x_file_log_type, 1);
          UTL_FILE.put_line (x_file_log_type, l_date_str);
          UTL_FILE.new_line (x_file_log_type, 1);
          UTL_FILE.put_line (x_file_log_type, l_file_name_str2);
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

       ELSIF p_file_number = 3
       THEN
          BEGIN
             l_total_count := 0;
             SELECT COUNT (*)
               INTO l_total_count
               FROM intg_hr_pf_job_data;
          EXCEPTION
             WHEN OTHERS
             THEN
                l_total_count := 0;
          END;

          l_tot_rec_str := 'Total No. of Records' || CHR (9) || l_total_count;

          BEGIN
            l_success_count := 0;
             SELECT COUNT (*)
               INTO l_success_count
               FROM intg_hr_pf_job_data
              WHERE error_flag = 'S';
          EXCEPTION
             WHEN OTHERS
             THEN
                l_success_count := 0;
          END;

          l_suc_rec_str :=
                    'Total No. of Success Records' || CHR (9)
                    || l_success_count;

          BEGIN
             l_failed_count := 0;
             SELECT COUNT (*)
               INTO l_failed_count
               FROM intg_hr_pf_job_data
              WHERE error_flag = 'E';
          EXCEPTION
             WHEN OTHERS
             THEN
                l_failed_count := 0;
          END;

          l_err_rec_str :=
                      'Total No. of Failed Records' || CHR (9)
                      || l_failed_count;
          UTL_FILE.new_line (x_file_log_type, 1);
          UTL_FILE.put_line (x_file_log_type, l_date_str);
          UTL_FILE.new_line (x_file_log_type, 1);
          UTL_FILE.put_line (x_file_log_type, l_file_name_str1);
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
       END IF;
    EXCEPTION
       WHEN OTHERS
       THEN
          x_error_msg := 'Procedure - write_pf_file ->' || SQLERRM;
          x_return_code := xx_emf_cn_pkg.cn_prc_err;
   END create_pf_log_file;

-- Functionto return Supervisor position
FUNCTION get_sup_position(p_person_id IN NUMBER, p_effective_date IN DATE)
RETURN NUMBER
IS

CURSOR csr_emp_hier
IS
 SELECT     (SELECT person_id
                       FROM per_all_people_f
                      WHERE person_id = paf.person_id
                        AND p_effective_date BETWEEN effective_start_date
                                        AND effective_end_date) tree
               FROM per_all_assignments_f paf
         START WITH paf.person_id = p_person_id
                AND paf.primary_flag = 'Y'
                AND p_effective_date BETWEEN paf.effective_start_date
                                AND paf.effective_end_date
         CONNECT BY paf.person_id = PRIOR paf.supervisor_id
                AND paf.primary_flag = 'Y'
                AND p_effective_date BETWEEN paf.effective_start_date
                                AND paf.effective_end_date;


cursor csr_get_per_type (x_person_id NUMBER)
is
select system_person_type
,paaf.position_id
from per_person_types ppt
,per_person_type_usages_f pptuf
,per_all_people_f papf
,per_all_assignments_f paaf
where papf.person_id=pptuf.person_id
and ppt.person_type_id=pptuf.person_type_id
and papf.person_id=paaf.person_id
and papf.person_id=x_person_id
and paaf.primary_flag = 'Y'
and paaf.assignment_type = 'E'
and p_effective_date between papf.effective_start_date and papf.effective_end_date
and p_effective_date between pptuf.effective_start_date and pptuf.effective_end_date
and p_effective_date between paaf.effective_start_date and paaf.effective_end_date;

l_found_flag      VARCHAR2 (1)   := 'N';
l_position_id     NUMBER(10);



begin
       for rec_emp_hier in csr_emp_hier loop

           IF rec_emp_hier.tree <> p_person_id THEN

              IF l_found_flag  = 'N' THEN

               for rec_get_per_type IN csr_get_per_type(rec_emp_hier.tree) loop

                  l_position_id := NULL;

                     IF nvl(rec_get_per_type.system_person_type,'XXX') = 'EMP' THEN
                        l_found_flag  := 'Y';
                        l_position_id := rec_get_per_type.position_id;
                        EXIT;
                     END IF;
                end loop;
              ELSE
                    EXIT;
              END IF;
           END IF;
       END LOOP;
       RETURN l_position_id;
     EXCEPTION
      WHEN OTHERS
      THEN
         l_position_id := NULL;
END get_sup_position;
END xxintg_hr_pf_ws_pkg;
/
