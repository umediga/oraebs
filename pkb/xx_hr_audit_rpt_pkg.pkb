DROP PACKAGE BODY APPS.XX_HR_AUDIT_RPT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_AUDIT_RPT_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 08-Apr-2013
 File Name     : xx_hr_audit_rpt.pkb
 Description   : This script creates the body of the package
                 xx_hr_audit_rpt_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 08-Apr-2013 Renjith               Initial Version
 12-Sep-2013 Shekhar N             CC#3874 Updated to exclude the assignment and salary records
                                   having assignment type 'A' or 'O'. This update is in report_check
                                   PROC.
*/
----------------------------------------------------------------------
   x_user_id          NUMBER := FND_GLOBAL.USER_ID;
   x_login_id         NUMBER := FND_GLOBAL.LOGIN_ID;
   x_request_id       NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
   x_resp_id          NUMBER := FND_GLOBAL.RESP_ID;
   x_resp_appl_id     NUMBER := FND_GLOBAL.RESP_APPL_ID;
   x_lookup           VARCHAR2(100) := 'XX_PAYROLL_AUDIT_OTHERS';
  ----------------------------------------------------------------------
  PROCEDURE report_insert ( p_person_id           IN  NUMBER
                           ,p_field_changed       IN  VARCHAR2
                           ,p_previous_value      IN  VARCHAR2
                           ,p_new_value           IN  VARCHAR2
                           ,p_last_updated_date   IN  DATE
                           ,p_effective_date      IN  DATE
                           ,p_country             IN  VARCHAR2
                           ,p_gre                 IN  VARCHAR2
                           ,p_payroll_id          IN  NUMBER
                           ,p_run_type            IN  VARCHAR2
                           ,p_date_from           IN  VARCHAR2
                           ,p_date_to             IN  VARCHAR2
                          )

  IS
     x_record_id            NUMBER;
     x_employee_number      VARCHAR2(30);
     x_last_name            VARCHAR2(150);
     x_first_name           VARCHAR2(150);
     x_prior_report_key     VARCHAR2(2000);
     x_gre                  VARCHAR2(150);
     x_gre_id               NUMBER;
     x_payroll_name         VARCHAR2(80);
     x_location_id          VARCHAR2(60);
  BEGIN
     SELECT xx_hr_audit_aud_s.NEXTVAL
       INTO x_record_id
       FROM dual;
     BEGIN
       SELECT  papf.employee_number
              ,papf.last_name
              ,papf.first_name
              ,paaf.soft_coding_keyflex_id
              ,loc.location_id
         INTO  x_employee_number
              ,x_last_name
              ,x_first_name
              ,x_gre_id
              ,x_location_id
         FROM  per_all_people_f papf
              ,per_all_assignments_f paaf
              ,hr_locations loc
              ,hr_soft_coding_keyflex flx
              ,hr_all_organization_units_tl org
              ,pay_payrolls_f pay
        WHERE  papf.person_id = paaf.person_id
          AND  paaf.location_id = loc.location_id(+)
          AND  papf.person_id =  p_person_id
          AND  paaf.soft_coding_keyflex_id = flx.soft_coding_keyflex_id(+)
          AND  flx.segment1   = org.organization_id
          AND  org.language   = USERENV ('LANG')
          AND  paaf.payroll_id = pay.payroll_id(+)
          AND  SYSDATE BETWEEN papf.effective_start_date  AND papf.effective_end_date
          AND  ROWNUM = 1;
          --AND  SYSDATE BETWEEN paaf.effective_start_date  AND paaf.effective_end_date;
     EXCEPTION
        WHEN OTHERS THEN
       x_employee_number := NULL;
       x_last_name       := NULL;
       x_first_name      := NULL;
     END;

     BEGIN
       SELECT  pay.payroll_name
         INTO  x_payroll_name
         FROM  pay_payrolls_f pay
        WHERE  pay.payroll_id = p_payroll_id;
     EXCEPTION
        WHEN OTHERS THEN
          x_payroll_name  := NULL;
     END;

     IF p_gre IS NOT NULL THEN
       x_gre := ' - '||p_gre;
     END IF;

     IF p_payroll_id IS NOT NULL THEN
       x_payroll_name := ' - '||x_payroll_name;
     END IF;

     x_prior_report_key := p_country ||x_gre||x_payroll_name||' - '||p_date_from||' - '||p_date_to;

     IF x_employee_number IS NOT NULL THEN
        INSERT INTO XX_HR_AUDIT_RPT
            ( record_id
             ,request_id
             ,person_id
             ,employee_number
             ,last_name
             ,first_name
             ,field_changed
             ,previous_value
             ,new_value
             ,last_updated_date
             ,effective_date
             ,run_type
             ,prior_report_key
             ,location_id
             ,country
             ,gre_id
             ,date_from
             ,date_to
             ,payroll_id
             ,created_by
             ,creation_date
             ,last_update_date
             ,last_updated_by
             ,last_update_login
            )
        VALUES
            ( x_record_id            --record_id
             ,x_request_id           --request_id
             ,p_person_id            --person_id
             ,x_employee_number      --employee_number
             ,x_last_name            --last_name
             ,x_first_name           --first_name
             ,p_field_changed        --field_changed
             ,p_previous_value       --previous_value
             ,p_new_value            --new_value
             ,p_last_updated_date    --last_updated_date
             ,p_effective_date       --effective_date
             ,p_run_type             --run_type
             ,x_prior_report_key     --prior_report_key
             ,x_location_id          --location_id
             ,p_country              --country
             ,x_gre_id               --gre_id
             ,p_date_from            --date_from
             ,p_date_to              --date_to
             ,p_payroll_id           --payroll_id
             ,x_user_id              --created_by
             ,SYSDATE                --creation_date
             ,SYSDATE                --last_update_date
             ,x_user_id              --last_updated_by
             ,x_login_id             --last_update_login
            );
     END IF;
  EXCEPTION
     WHEN OTHERS THEN
     NULL;
  END report_insert;

  ----------------------------------------------------------------------

  PROCEDURE report_check  ( p_person_id           IN  NUMBER
                           ,p_data_element        IN  VARCHAR2
                           ,p_country             IN  VARCHAR2
                           ,p_gre                 IN  VARCHAR2
                           ,p_payroll_id          IN  NUMBER
                           ,p_run_type            IN  VARCHAR2
                           ,p_date_from           IN  VARCHAR2
                           ,p_date_to             IN  VARCHAR2
                          )

  IS
     CURSOR c_audit_g( p_person_id      NUMBER
                      ,p_data_element   VARCHAR2
                      ,p_lookup         VARCHAR2)
     IS
     SELECT  aud.*
       FROM  xx_hr_payroll_aud_tbl aud
      WHERE  aud.data_element = p_data_element
        AND  aud.person_id    = p_person_id
        -- CC3874 changes start here. This has been added to exclude the records having assignment type 'A' or 'O'
        AND  aud.table_prim_id NOT IN (select assignment_id
                        from per_all_assignments_f
                        where assignment_id=aud.table_prim_id
                        and aud.table_name like 'PER_ALL_ASSIGNMENTS_F'
                        and assignment_type in ('A','O')
                        and trunc(sysdate) between effective_start_date and effective_end_date
                        )
        AND aud.table_prim_id NOT IN (select ppp.pay_proposal_id
                        from per_all_assignments_f paaf,
                        per_pay_proposals ppp
                        where ppp.pay_proposal_id=aud.table_prim_id
                        and paaf.assignment_id=ppp.assignment_id
                        and aud.table_name like 'PER_PAY_PROPOSALS'
                        and paaf.assignment_type in ('A','O')
                        and trunc(sysdate) between paaf.effective_start_date and paaf.effective_end_date
                        )
          -- CC3874 changes end here.
        AND  GREATEST(aud.data_element_upd_date,NVL(aud.effective_start_date,SYSDATE-100)) = (SELECT  MAX(GREATEST(aut.data_element_upd_date,NVL(aut.effective_start_date,SYSDATE-100)))
                                                                               FROM  xx_hr_payroll_aud_tbl aut
                                                                              WHERE  aut.data_element = aud.data_element
                                                                                AND  aut.person_id    = aud.person_id
                                                                                AND  GREATEST(aut.data_element_upd_date,NVL(aut.effective_start_date,SYSDATE-100))
                                                                                     BETWEEN p_date_from AND p_date_to)
        AND aud.record_id = (SELECT  MAX(record_id)
                               FROM  xx_hr_payroll_aud_tbl aut
                              WHERE  aut.data_element = aud.data_element
                                AND  aut.person_id    = aud.person_id
                                AND  GREATEST(aut.data_element_upd_date,NVL(aut.effective_start_date,SYSDATE-100))
                                     BETWEEN p_date_from AND p_date_to)
        AND EXISTS (SELECT  meaning
                      FROM  fnd_lookup_values_vl
                     WHERE  lookup_type = p_lookup --'XX_PAYROLL_AUDIT_REPORT'
                       AND  NVL(enabled_flag,'X')='Y'
                       AND  SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE)
                       AND  aud.data_element = meaning);

     CURSOR c_audit_l( p_person_id      NUMBER
                      ,p_data_element   VARCHAR2
                      ,p_lookup         VARCHAR2)
     IS
     SELECT  aud.*
       FROM  xx_hr_payroll_aud_tbl aud
      WHERE  aud.data_element = p_data_element
        AND  aud.person_id    = p_person_id
         -- CC3874 changes start here. This has been added to exclude the records having assignment type A or O
        AND  aud.table_prim_id NOT IN (select assignment_id
                        from per_all_assignments_f
                        where assignment_id=aud.table_prim_id
                        and aud.table_name like 'PER_ALL_ASSIGNMENTS_F'
                        and assignment_type in ('A','O')
                        and trunc(sysdate) between p_date_from AND p_date_to
                        )
        AND aud.table_prim_id NOT IN (select ppp.pay_proposal_id
                        from per_all_assignments_f paaf,
                        per_pay_proposals ppp
                        where ppp.pay_proposal_id=aud.table_prim_id
                        and paaf.assignment_id=ppp.assignment_id
                        and aud.table_name like 'PER_PAY_PROPOSALS'
                        and paaf.assignment_type in ('A','O')
                        and trunc(sysdate) between paaf.effective_start_date and paaf.effective_end_date
                        )
         -- CC3874 changes end here.
        AND  GREATEST(aud.data_element_upd_date,NVL(aud.effective_start_date,SYSDATE-100)) = (SELECT  MIN(GREATEST(aut.data_element_upd_date,NVL(aut.effective_start_date,SYSDATE-100)))
                                                                               FROM  xx_hr_payroll_aud_tbl aut
                                                                              WHERE  aut.data_element = aud.data_element
                                                                                AND  aut.person_id    = aud.person_id
                                                                                AND  GREATEST(aut.data_element_upd_date,NVL(aut.effective_start_date,SYSDATE-100))
                                                                                     BETWEEN p_date_from AND p_date_to)
        AND aud.record_id = (SELECT  MIN(record_id)
                               FROM  xx_hr_payroll_aud_tbl aut
                              WHERE  aut.data_element = aud.data_element
                                AND  aut.person_id    = aud.person_id
                                AND  GREATEST(aut.data_element_upd_date,NVL(aut.effective_start_date,SYSDATE-100))
                                     BETWEEN p_date_from AND p_date_to)
        AND EXISTS (SELECT  meaning
                      FROM  fnd_lookup_values_vl
                     WHERE  lookup_type = p_lookup
                       AND  NVL(enabled_flag,'X')='Y'
                       AND  SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE)
                       AND  aud.data_element = meaning);

       x_ldata_value_new    VARCHAR2(200):=NULL;
       x_hdata_value_old    VARCHAR2(200):=NULL;
       x_rec_count          NUMBER       := 0;
       --x_lookup             VARCHAR2(100);
  BEGIN

     SELECT  COUNT(*)
       INTO  x_rec_count
       FROM  xx_hr_payroll_aud_tbl
      WHERE  data_element = p_data_element
        AND  person_id    = p_person_id
        AND  GREATEST(data_element_upd_date,NVL(effective_start_date,SYSDATE-100)) BETWEEN p_date_from AND p_date_to;

        --FND_FILE.PUT_LINE( FND_FILE.LOG,'-------------------------------------------------------');
        --FND_FILE.PUT_LINE( FND_FILE.LOG,'report_check');
        --FND_FILE.PUT_LINE( FND_FILE.LOG,'count->'||x_rec_count);

         FOR audit_l_rec IN c_audit_l (p_person_id,p_data_element,x_lookup) LOOP
               --INSERT INTO TEST_HR VALUES (3,p_person_id,'INSIDE MIN','x_rec_count->'||x_rec_count,'-------------','-------------');
               IF audit_l_rec.record_creation_date BETWEEN p_date_from AND p_date_to AND NVL(x_rec_count,0) = 1 THEN
                  IF NVL(x_rec_count,0) = 1 AND NVL(audit_l_rec.attribute20,'X') <> 'S' THEN
                    report_insert ( p_person_id           => audit_l_rec.person_id
                                   ,p_field_changed       => p_data_element
                                   --,p_previous_value      => NULL
                                   ,p_previous_value      => audit_l_rec.data_value_old
                                   ,p_new_value           => audit_l_rec.data_value_new
                                   ,p_last_updated_date   => audit_l_rec.data_element_upd_date
                                   ,p_effective_date      => audit_l_rec.effective_start_date
                                   ,p_country             => p_country
                                   ,p_gre                 => p_gre
                                   ,p_payroll_id          => p_payroll_id
                                   ,p_run_type            => p_run_type
                                   ,p_date_from           => p_date_from
                                   ,p_date_to             => p_date_to
                                  );
                     --INSERT INTO TEST_HR VALUES (4,audit_l_rec.person_id,'MIN NEW',p_data_element,audit_l_rec.data_value_old,audit_l_rec.data_value_new);
                  ELSE
                    x_ldata_value_new := audit_l_rec.data_value_new;
                    --INSERT INTO TEST_HR VALUES (5,audit_l_rec.person_id,'MIN OLD',p_data_element,audit_l_rec.data_value_old,x_ldata_value_new);
                  END IF;
               ELSE
                 x_ldata_value_new := audit_l_rec.data_value_new;
                 IF NVL(x_rec_count,0) = 1 AND NVL(audit_l_rec.attribute20,'X') <> 'S' THEN
                 -- Change
                    report_insert ( p_person_id           => audit_l_rec.person_id
                                   ,p_field_changed       => p_data_element
                                   ,p_previous_value      => audit_l_rec.data_value_old
                                   ,p_new_value           => audit_l_rec.data_value_new
                                   ,p_last_updated_date   => audit_l_rec.data_element_upd_date
                                   ,p_effective_date      => audit_l_rec.effective_start_date
                                   ,p_country             => p_country
                                   ,p_gre                 => p_gre
                                   ,p_payroll_id          => p_payroll_id
                                   ,p_run_type            => p_run_type
                                   ,p_date_from           => p_date_from
                                   ,p_date_to             => p_date_to
                                  );
                     --INSERT INTO TEST_HR VALUES (6,audit_l_rec.person_id,'MIN',p_data_element,audit_l_rec.data_value_old,audit_l_rec.data_value_new);
                 END IF;
                   --INSERT INTO TEST_HR VALUES (7,audit_l_rec.person_id,'MIN OLD',p_data_element,audit_l_rec.data_value_old,x_ldata_value_new);
               END IF;
         END LOOP;

         IF NVL(x_rec_count,0) > 1 THEN
            FOR audit_g_rec IN c_audit_g (p_person_id,p_data_element,x_lookup) LOOP
               --INSERT INTO TEST_HR VALUES (8,p_person_id,'INSIDE MAX','x_rec_count->'||x_rec_count,'-------------','-------------');
               IF audit_g_rec.data_value_old IS NULL AND x_ldata_value_new IS NOT NULL THEN
                 x_hdata_value_old := x_ldata_value_new;
               ELSE
                 x_hdata_value_old := audit_g_rec.data_value_old;
               END IF;
               IF x_hdata_value_old = audit_g_rec.data_value_new THEN
                  x_hdata_value_old := NULL;
               END IF;
               report_insert ( p_person_id           => audit_g_rec.person_id
                              ,p_field_changed       => p_data_element
                              ,p_previous_value      => x_hdata_value_old
                              ,p_new_value           => audit_g_rec.data_value_new
                              ,p_last_updated_date   => audit_g_rec.data_element_upd_date
                              ,p_effective_date      => audit_g_rec.effective_start_date
                              ,p_country             => p_country
                              ,p_gre                 => p_gre
                              ,p_payroll_id          => p_payroll_id
                              ,p_run_type            => p_run_type
                              ,p_date_from           => p_date_from
                              ,p_date_to             => p_date_to
                             );
               --INSERT INTO TEST_HR VALUES (9,audit_g_rec.person_id,'MAX',p_data_element,x_hdata_value_old,audit_g_rec.data_value_new);
            END LOOP;
          END IF;
  EXCEPTION
       WHEN OTHERS THEN
       NULL;
  END report_check;
  ----------------------------------------------------------------------
  PROCEDURE report_language ( p_user_id IN    NUMBER
                             ,x_lang    OUT   VARCHAR2
                             ,x_ter     OUT   VARCHAR2)
  IS
    x_role_lang  VARCHAR2(40);
  BEGIN
     BEGIN
       SELECT  wf.language
         INTO  x_role_lang
         FROM  wf_local_roles wf
              ,fnd_user fd
        WHERE  wf.name = fd.user_name
          AND  fd.user_id = p_user_id;
     EXCEPTION
       WHEN OTHERS THEN
         x_role_lang := 'AMERICAN';
     END;

     BEGIN
       SELECT LOWER (iso_language)
             ,iso_territory
         INTO x_lang
             ,x_ter
         FROM fnd_languages
        WHERE UPPER(nls_language) = UPPER (x_role_lang);
     EXCEPTION
       WHEN OTHERS THEN
         x_lang := 'en';
         x_ter  := 'US';
     END;
  EXCEPTION
      WHEN OTHERS THEN
         x_lang := 'en';
         x_ter  := 'US';
  END report_language;
  ----------------------------------------------------------------------

  PROCEDURE audit_report ( p_errbuf         OUT   VARCHAR2
                          ,p_retcode        OUT   VARCHAR2
                          ,p_country        IN    VARCHAR2
                          ,p_dummy3         IN    VARCHAR2
                          ,p_dummy4         IN    VARCHAR2
                          ,p_report_type    IN    VARCHAR2
                          ,p_dummy1         IN    VARCHAR2
                          ,p_dummy5         IN    VARCHAR2
                          ,p_prequest_id    IN    NUMBER
                          ,p_dummy2         IN    VARCHAR2
                          ,p_gre            IN    VARCHAR2
                          ,p_payroll_id     IN    NUMBER
                          ,p_run_type       IN    VARCHAR2
                          ,p_date_from      IN    VARCHAR2
                          ,p_date_to        IN    VARCHAR2
                         )
  IS

    x_date_from        VARCHAR2(20);
    x_date_to          VARCHAR2(20);

    x_application      VARCHAR2(10) := 'XXINTG';
    x_program_name     VARCHAR2(20) := 'XXHRPAYAUDITRPT';
    x_program_desc     VARCHAR2(50) := 'INTG Payroll Audit Report';
    x_phase            VARCHAR2(2000);
    x_status           VARCHAR2(80);
    x_devphase         VARCHAR2(80);
    x_devstatus        VARCHAR2(80);
    x_message          VARCHAR2(2000);
    x_check            BOOLEAN;
    x_reqid            NUMBER;

    x_country          VARCHAR2(100);
    --x_lookup           VARCHAR2(100);
    x_org_req_id       NUMBER;

    x_layout_status    BOOLEAN := FALSE;
    x_ter              fnd_languages.iso_territory%TYPE := 'US';
    x_lang             fnd_languages.iso_language%TYPE := 'en';

    CURSOR c_emp_main
    IS
    SELECT  DISTINCT papf.person_id
      FROM  per_all_people_f papf
           ,per_all_assignments_f paaf
           ,hr_locations loc
           ,hr_organization_units org
           ,hr_soft_coding_keyflex flx
           ,hr_all_organization_units_tl orgt
           ,per_person_type_usages_f pptuf
           ,per_person_types ppt
     WHERE  papf.person_id = paaf.person_id
       AND  paaf.location_id = loc.location_id(+)
       AND  paaf.organization_id = org.organization_id
       AND  paaf.soft_coding_keyflex_id = flx.soft_coding_keyflex_id(+)
       AND  flx.segment1  = orgt.organization_id
       AND  orgt.language = USERENV ('LANG')
       AND  papf.person_id = pptuf.person_id
       AND  pptuf.person_type_id = ppt.person_type_id
       AND  TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date AND pptuf.effective_end_date
       AND  ppt.user_person_type IN ('Employee','Employee and Applicant','Ex-employee')
       AND  loc.country   = p_country
       AND  NVL(orgt.name,'X') = NVL(p_gre,NVL(orgt.name,'X'))
       AND  NVL(paaf.payroll_id,0) = NVL(p_payroll_id,NVL(paaf.payroll_id,0))
       AND  DECODE(hr_security.view_all, 'Y', 'TRUE', hr_security.show_record('HR_ALL_ORGANIZATION_UNITS',org.organization_id, 'Y')) = 'TRUE'
       AND  DECODE(hr_security.view_all, 'Y', 'TRUE', hr_security.show_record('PER_ALL_ASSIGNMENTS_F',paaf.assignment_id, papf.person_id, paaf.assignment_type, 'Y')) = 'TRUE'
       AND  EXISTS (SELECT aud.person_id
                      FROM xx_hr_payroll_aud_tbl aud
                     WHERE aud.person_id = papf.person_id
                       --AND GREATEST(aud.data_element_upd_date,aud.effective_start_date) BETWEEN x_date_from AND x_date_to
                       AND GREATEST(aud.data_element_upd_date,NVL(aud.effective_start_date,SYSDATE-100)) BETWEEN x_date_from AND x_date_to
                  );

  BEGIN
     FND_FILE.PUT_LINE( FND_FILE.LOG,'-------------------------------------------------------');
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_country        ->'||p_country);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_report_type    ->'||p_report_type);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_prequest_id    ->'||p_prequest_id);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_gre            ->'||p_gre);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_payroll_id     ->'||p_payroll_id);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_run_type       ->'||p_run_type);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_date_from      ->'||p_date_from);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_date_to        ->'||p_date_to);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'-------------------------------------------------------');

     xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXHRAUDITPRGM'
                                                ,p_param_name      => p_country
                                                ,x_param_value     => x_lookup);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'Country Lookup   ->'|| x_lookup);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'-------------------------------------------------------');
     IF x_lookup IS NULL THEN
        x_lookup := 'XX_PAYROLL_AUDIT_OTHERS';
     END IF;

     IF NVL(p_report_type,'X') = 'N' THEN
        x_org_req_id := x_request_id;

        --x_date_from := TO_CHAR(TRUNC(TO_DATE(p_date_from,'YYYY-MM-DD HH24:MI:SS')),'DD-MON-YYYY');
        --x_date_to   := TO_CHAR(TRUNC(TO_DATE(p_date_to,'YYYY-MM-DD HH24:MI:SS')),'DD-MON-YYYY');

        x_date_from := p_date_from;
        x_date_to   := p_date_to;

        --FND_FILE.PUT_LINE( FND_FILE.LOG,'x_date_from      ->'|| x_date_from);
        --FND_FILE.PUT_LINE( FND_FILE.LOG,'x_date_to        ->'|| x_date_to);
        --FND_FILE.PUT_LINE( FND_FILE.LOG,'-------------------------------------------------------');

        FOR emp_main_rec IN c_emp_main LOOP
            FND_FILE.PUT_LINE( FND_FILE.LOG,'audit_report');
            FND_FILE.PUT_LINE( FND_FILE.LOG,'-------------------------------------------------------');
            FND_FILE.PUT_LINE( FND_FILE.LOG,'person_id      ->'|| emp_main_rec.person_id);

            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_PEOPLE_F.EMPLOYEE_NUMBER'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                           );

            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_PEOPLE_F.LAST_NAME'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_PEOPLE_F.FIRST_NAME'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );

            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_PEOPLE_F.MIDDLE_NAMES'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );

            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_PEOPLE_F.SEX'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );

            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_PEOPLE_F.TITLE'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );

            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_PEOPLE_F.DATE_OF_BIRTH'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );

            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_PEOPLE_F.NATIONALITY'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );

            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_PEOPLE_F.NATIONAL_IDENTIFIER'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );

            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_PEOPLE_F.EMAIL_ADDRESS'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );

            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_PEOPLE_F.TOWN_OF_BIRTH'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_PEOPLE_F.MARITAL_STATUS'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            -- ---------------------------------------------------------------------

            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.LOCATION_ID'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.LOCATION_ID_C'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.SOFT_CODING_KEYFLEX_ID'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                         );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.SOFT_CODING_KEYFLEX_ID_T'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                         );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.SOFT_CODING_KEYFLEX_ID_S'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                         );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.SOFT_CODING_KEYFLEX_ID_W'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                         );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.SUPERVISOR_ID'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.SUPERVISOR_ID_N'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.ORGANIZATION_ID'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.DEFAULT_CODE_COMB_ID'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.DEFAULT_CODE_COMB_ID_D'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.DEFAULT_CODE_COMB_ID_P'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.DEFAULT_CODE_COMB_ID_R'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );

            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.JOB_ID'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.PAYROLL_ID'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.ASSIGNMENT_STATUS_TYPE_ID'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.NORMAL_HOURS'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.PAY_BASIS_ID'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.POSITION_ID'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.ASSIGNMENT_CATEGORY'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.FREQUENCY'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.HOURLY_SALARIED_CODE'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ALL_ASSIGNMENTS_F.EMPLOYMENT_CATEGORY'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            -- ---------------------------------------------------------------------
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ADDRESSES.ADDRESS_LINE1'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ADDRESSES.ADDRESS_LINE2'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ADDRESSES.TOWN_OR_CITY'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ADDRESSES.POSTAL_CODE'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ADDRESSES.COUNTRY'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_ADDRESSES.REGION_2'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            -- ---------------------------------------------------------------------
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_PAY_PROPOSALS.PROPOSED_SALARY_N'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_PAY_PROPOSALS.PROPOSED_SALARY_RATE'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_PAY_PROPOSALS.CHANGE_DATE'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_PAY_PROPOSALS.ATTRIBUTE1'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_PAY_PROPOSALS.ATTRIBUTE2'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_PAY_PROPOSALS.PROPOSAL_REASON'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            -- ---------------------------------------------------------------------
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_PHONES.PHONE_NUMBER1'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_PHONES.PHONE_NUMBER2'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_PHONES.PHONE_NUMBER3'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            -- ---------------------------------------------------------------------
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_PERIODS_OF_SERVICE.DATE_START'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_PERIODS_OF_SERVICE.ACTUAL_TERMINATION_DATE'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_PERIODS_OF_SERVICE.LEAVING_REASON'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
            report_check  ( p_person_id      => emp_main_rec.person_id
                           ,p_data_element   => 'PER_PERIODS_OF_SERVICE.ADJUSTED_SVC_DATE'
                           ,p_country        => p_country
                           ,p_gre            => p_gre
                           ,p_payroll_id     => p_payroll_id
                           ,p_run_type       => p_run_type
                           ,p_date_from      => x_date_from
                           ,p_date_to        => x_date_to
                          );
           -- ---------------------------------------------------------------------

        END LOOP;
        COMMIT;
     ELSE
        x_org_req_id := p_prequest_id;
     END IF; -- run type

     FND_GLOBAL.APPS_INITIALIZE(  x_user_id        --User id
                                 ,x_resp_id        --responsibility_id
                                 ,x_resp_appl_id); --application_id

     report_language ( x_user_id,x_lang,x_ter);

     FND_FILE.PUT_LINE( FND_FILE.LOG,'Language         ->'|| x_lang);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'Territory        ->'|| x_ter);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'-------------------------------------------------------');

     x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name =>  x_application
                                                ,template_code      => 'XXHRPAYAUDITRPT'
                                                ,template_language  =>  x_lang
                                                ,template_territory =>  x_ter
                                                ,output_format      => 'EXCEL');

     x_reqid := FND_REQUEST.SUBMIT_REQUEST( application     => x_application
                                           ,program         => x_program_name
                                           ,description     => x_program_desc
                                           ,start_time      => SYSDATE
                                           ,sub_request     => FALSE
                                           ,argument1       => x_org_req_id
                                           ,argument2       => p_country
                                           ,argument3       => p_report_type
                                           ,argument4       => p_gre
                                           ,argument5       => p_payroll_id
                                           ,argument6       => p_run_type
                                           ,argument7       => p_date_from
                                           ,argument8       => p_date_to
                                           );
     COMMIT;

     IF NVL(p_run_type,'X') = 'D' THEN
        x_check:=fnd_concurrent.wait_for_request(x_reqid,1,0,x_phase,x_status,x_devphase,x_devstatus,x_message);
        DELETE FROM XX_HR_AUDIT_RPT
              WHERE request_id = x_request_id;
        COMMIT;
     END IF;

  END audit_report;
  ----------------------------------------------------------------------
END xx_hr_audit_rpt_pkg;
/
