DROP PACKAGE BODY APPS.XX_HR_AUDIT_SNAP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_AUDIT_SNAP_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 08-Apr-2013
 File Name     : xx_hr_audit_snap.pkb
 Description   : This script creates the body of the package
                 xx_hr_audit_snap_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 08-Apr-2013 Renjith               Initial Version
*/
----------------------------------------------------------------------
   x_user_id          NUMBER := FND_GLOBAL.USER_ID;
   x_login_id         NUMBER := FND_GLOBAL.LOGIN_ID;
   x_request_id       NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
   x_resp_id          NUMBER := FND_GLOBAL.RESP_ID;
   x_resp_appl_id     NUMBER := FND_GLOBAL.RESP_APPL_ID;
----------------------------------------------------------------------
  PROCEDURE insert_audit_date (  p_person_id              IN NUMBER
                                ,p_table_prim_id          IN NUMBER
                                ,p_table_name             IN VARCHAR2
                                ,p_data_element           IN VARCHAR2
                                ,p_data_value_old         IN VARCHAR2
                                ,p_data_value_new         IN VARCHAR2
                                ,p_data_element_upd_date  IN DATE
                                ,p_effective_start_date   IN DATE
                                ,p_effective_end_date     IN DATE
                                ,p_creation_date          IN DATE)
  IS
    x_record_id         NUMBER := NULL;
  BEGIN
     IF p_table_prim_id IS NOT NULL THEN
         SELECT xx_hr_audit_aud_s.NEXTVAL
           INTO x_record_id
           FROM dual;

         INSERT INTO XX_HR_PAYROLL_AUD_TBL
          ( record_id
           ,person_id
           ,table_prim_id
           ,table_name
           ,data_element
           ,data_value_old
           ,data_value_new
           ,data_element_upd_date
           ,effective_start_date
           ,effective_end_date
           ,record_creation_date
           ,created_by
           ,creation_date
           ,last_update_date
           ,last_updated_by
           ,last_update_login
           ,attribute20
          )
         VALUES
          (  x_record_id                         -- record_id
            ,p_person_id                         -- person_id
            ,p_table_prim_id                     -- table_prim_id
            ,p_table_name                        -- table_name
            ,p_table_name||'.'||p_data_element   -- data_element
            ,p_data_value_old                    -- data_value_old
            ,p_data_value_new                    -- data_value_new
            ,p_data_element_upd_date             -- data_element_upd_date
            ,p_effective_start_date              -- effective_start_date
            ,p_effective_end_date                -- effective_end_date
            ,p_creation_date                     -- record_creation_date
            ,x_user_id                           -- created_by
            ,SYSDATE                             -- creation_date
            ,SYSDATE                                -- last_update_date
            ,x_user_id                           -- last_updated_by
            ,x_login_id                          -- last_update_login
            ,'S'                                 -- attribute20
           );
     END IF;
  END insert_audit_date;

  ----------------------------------------------------------------------
  PROCEDURE insert_audit (  p_person_id              IN NUMBER
                           ,p_table_prim_id          IN NUMBER
                           ,p_table_name             IN VARCHAR2
                           ,p_data_element           IN VARCHAR2
                           ,p_data_value_old         IN VARCHAR2
                           ,p_data_value_new         IN VARCHAR2)
  IS
    x_record_id         NUMBER := NULL;
  BEGIN
     IF p_table_prim_id IS NOT NULL THEN
         SELECT xx_hr_audit_aud_s.NEXTVAL
           INTO x_record_id
           FROM dual;

         INSERT INTO XX_HR_PAYROLL_AUD_TBL
          ( record_id
           ,person_id
           ,table_prim_id
           ,table_name
           ,data_element
           ,data_value_old
           ,data_value_new
           ,data_element_upd_date
           ,effective_start_date
           ,effective_end_date
           ,record_creation_date
           ,created_by
           ,creation_date
           ,last_update_date
           ,last_updated_by
           ,last_update_login
          )
         VALUES
          (  x_record_id                         -- record_id
            ,p_person_id                         -- person_id
            ,p_table_prim_id                     -- table_prim_id
            ,p_table_name                        -- table_name
            ,p_table_name||'.'||p_data_element   -- data_element
            ,p_data_value_old                    -- data_value_old
            ,p_data_value_new                    -- data_value_new
            ,NULL --p_data_element_upd_date             -- data_element_upd_date
            ,NULL --p_effective_start_date              -- effective_start_date
            ,NULL --p_effective_end_date                -- effective_end_date
            ,NULL --p_creation_date                     -- record_creation_date
            ,x_user_id                           -- created_by
            ,SYSDATE                             -- creation_date
            ,SYSDATE                             -- last_update_date
            ,x_user_id                           -- last_updated_by
            ,x_login_id                          -- last_update_login
           );
     END IF;
  END insert_audit;

  ----------------------------------------------------------------------
  PROCEDURE snap_insert( p_errbuf    OUT   VARCHAR2
                        ,p_retcode   OUT   VARCHAR2)
  IS
    CURSOR c_emp
        IS
     SELECT  papf.person_id
            ,papf.employee_number
            ,papf.last_name
            ,papf.first_name
            ,papf.middle_names
            ,papf.sex
            ,papf.title
            ,papf.date_of_birth
            ,papf.nationality
            ,papf.national_identifier
            ,papf.email_address
            ,papf.town_of_birth
            ,papf.marital_status
             -- ---------------------------
            ,paaf.location_id
            ,paaf.location_id location_id_c
            ,paaf.assignment_id
            ,paaf.soft_coding_keyflex_id  soft_coding_keyflex_id
            ,paaf.soft_coding_keyflex_id  soft_coding_keyflex_id_t
            ,paaf.soft_coding_keyflex_id  soft_coding_keyflex_id_s
            ,paaf.soft_coding_keyflex_id  soft_coding_keyflex_id_w
            ,paaf.supervisor_id supervisor_id
            ,paaf.supervisor_id supervisor_id_n
            ,paaf.organization_id
            ,paaf.default_code_comb_id default_code_comb_id
            ,paaf.default_code_comb_id default_code_comb_id_d
            ,paaf.default_code_comb_id default_code_comb_id_p
            ,paaf.default_code_comb_id default_code_comb_id_r
            ,paaf.job_id
            ,paaf.payroll_id
            ,paaf.assignment_status_type_id
            ,paaf.normal_hours
            ,paaf.pay_basis_id
            ,paaf.position_id
            ,paaf.assignment_category
            ,paaf.frequency
            ,paaf.hourly_salaried_code
            ,paaf.employment_category
       FROM  per_all_people_f papf
            ,per_all_assignments_f paaf
            ,per_person_type_usages_f pptuf
            ,per_person_types ppt
      WHERE  papf.person_id = paaf.person_id
        AND  papf.person_id = pptuf.person_id
        AND  pptuf.person_type_id = ppt.person_type_id
        AND  SYSDATE BETWEEN papf.effective_start_date  AND papf.effective_end_date
        AND  SYSDATE BETWEEN paaf.effective_start_date  AND paaf.effective_end_date
        AND  TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date AND pptuf.effective_end_date
        AND  ppt.user_person_type IN ('Employee')
        AND  NVL(papf.current_employee_flag, 'N') = 'Y'
        AND  paaf.primary_flag = 'Y'
     UNION
     SELECT  papf.person_id
            ,papf.employee_number
            ,papf.last_name
            ,papf.first_name
            ,papf.middle_names
            ,papf.sex
            ,papf.title
            ,papf.date_of_birth
            ,papf.nationality
            ,papf.national_identifier
            ,papf.email_address
            ,papf.town_of_birth
            ,papf.marital_status
             -- ---------------------------
            ,paaf.location_id
            ,paaf.location_id location_id_c
            ,paaf.assignment_id
            ,paaf.soft_coding_keyflex_id  soft_coding_keyflex_id
            ,paaf.soft_coding_keyflex_id  soft_coding_keyflex_id_t
            ,paaf.soft_coding_keyflex_id  soft_coding_keyflex_id_s
            ,paaf.soft_coding_keyflex_id  soft_coding_keyflex_id_w
            ,paaf.supervisor_id supervisor_id
            ,paaf.supervisor_id supervisor_id_n
            ,paaf.organization_id
            ,paaf.default_code_comb_id default_code_comb_id
            ,paaf.default_code_comb_id default_code_comb_id_d
            ,paaf.default_code_comb_id default_code_comb_id_p
            ,paaf.default_code_comb_id default_code_comb_id_r
            ,paaf.job_id
            ,paaf.payroll_id
            ,paaf.assignment_status_type_id
            ,paaf.normal_hours
            ,paaf.pay_basis_id
            ,paaf.position_id
            ,paaf.assignment_category
            ,paaf.frequency
            ,paaf.hourly_salaried_code
            ,paaf.employment_category
       FROM  per_all_people_f papf
            ,per_all_assignments_f paaf
            ,per_person_type_usages_f pptuf
            ,per_person_types ppt
      WHERE  papf.person_id = paaf.person_id
        AND  papf.person_id = pptuf.person_id
        AND  pptuf.person_type_id = ppt.person_type_id
        AND  SYSDATE BETWEEN papf.effective_start_date  AND papf.effective_end_date
        AND  SYSDATE BETWEEN paaf.effective_start_date  AND paaf.effective_end_date
        AND  TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date AND pptuf.effective_end_date
        AND  ppt.user_person_type IN ('Employee and Applicant','Ex-employee');


        x_stg_table                  G_XX_HR_PAYROLL_AUD_TAB_TYPE;
        x_table_name                 VARCHAR2(100);

        x_period_of_service_id       NUMBER;
        x_date_start                 xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_actual_termination_date    xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_leaving_reason             xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_adjusted_svc_date          xx_hr_payroll_aud_tbl.data_value_new%TYPE;

        x_address_id                 NUMBER;
        x_address_line1              xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_address_line2              xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_town_or_city               xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_postal_code                xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_country                    xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_region_2                   xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_adr_date_from              DATE;
        x_adr_date_to                DATE;
        x_adr_last_update_date       DATE;
        x_adr_creation_date          DATE;

        x_pay_proposal_id            NUMBER;
        x_proposed_salary_n          xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_proposed_salary_rate       xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_change_date                xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_attribute1                 xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_attribute2                 xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_proposal_reason            xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_pay_date_from              DATE;
        x_pay_date_to                DATE;
        x_pay_last_update_date       DATE;
        x_pay_creation_date          DATE;

        x_phone_id                   NUMBER;
        x_phone_number1              xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_phone_number2              xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_phone_number3              xx_hr_payroll_aud_tbl.data_value_new%TYPE;
        x_count                      NUMBER:=0;
  BEGIN
    OPEN c_emp;
    FETCH c_emp
    BULK COLLECT INTO x_stg_table LIMIT 10000;
    CLOSE c_emp;

    FOR i IN 1 .. x_stg_table.COUNT
    LOOP
      x_count := x_count + 1;
      dbms_output.put_line('Person_id -> '||x_stg_table (i).person_id);
      x_table_name:= 'PER_ALL_PEOPLE_F';
      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).person_id
                     , x_table_name
                     ,'EMPLOYEE_NUMBER'
                     , NULL
                     , x_stg_table (i).employee_number);

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).person_id
                     ,x_table_name
                     ,'LAST_NAME'
                     , NULL
                     ,x_stg_table (i).last_name);

      insert_audit (   x_stg_table (i).person_id
                     , x_stg_table (i).person_id
                     , x_table_name
                     ,'FIRST_NAME'
                     , NULL
                     , x_stg_table (i).first_name);

      insert_audit (   x_stg_table (i).person_id
                     , x_stg_table (i).person_id
                     , x_table_name
                     ,'MIDDLE_NAMES'
                     , NULL
                     , x_stg_table (i).middle_names);

      insert_audit (   x_stg_table (i).person_id
                     , x_stg_table (i).person_id
                     , x_table_name
                     ,'SEX'
                     , NULL
                     , x_stg_table (i).sex );

      insert_audit (   x_stg_table (i).person_id
                     , x_stg_table (i).person_id
                     , x_table_name
                     ,'TITLE'
                     , NULL
                     , x_stg_table (i).title);

      insert_audit (   x_stg_table (i).person_id
                     , x_stg_table (i).person_id
                     , x_table_name
                     ,'DATE_OF_BIRTH'
                     , NULL
                     , x_stg_table (i).date_of_birth);

      insert_audit (   x_stg_table (i).person_id
                     , x_stg_table (i).person_id
                     , x_table_name
                     ,'NATIONALITY'
                     , NULL
                     , x_stg_table (i).nationality);

      insert_audit (   x_stg_table (i).person_id
                     , x_stg_table (i).person_id
                     , x_table_name
                     ,'NATIONAL_IDENTIFIER'
                     , NULL
                     , x_stg_table (i).national_identifier);

      insert_audit (   x_stg_table (i).person_id
                     , x_stg_table (i).person_id
                     , x_table_name
                     ,'EMAIL_ADDRESS'
                     , NULL
                     , x_stg_table (i).email_address);

      insert_audit (   x_stg_table (i).person_id
                     , x_stg_table (i).person_id
                     , x_table_name
                     ,'TOWN_OF_BIRTH'
                     , NULL
                     , x_stg_table (i).town_of_birth );

      insert_audit (   x_stg_table (i).person_id
                     , x_stg_table (i).person_id
                     , x_table_name
                     ,'MARITAL_STATUS'
                     , NULL
                     , x_stg_table (i).marital_status);

      ---------------------------------------------------------------------------------------
      x_table_name:= 'PER_ALL_ASSIGNMENTS_F';
      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'LOCATION_ID'
                     , NULL
                     , x_stg_table (i).location_id  );

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'LOCATION_ID_C'
                     , NULL
                     , x_stg_table (i).location_id_c );

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'SOFT_CODING_KEYFLEX_ID'
                     , NULL
                     , x_stg_table (i).soft_coding_keyflex_id  );

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'SOFT_CODING_KEYFLEX_ID_T'
                     , NULL
                     , x_stg_table (i).soft_coding_keyflex_id_t );

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'SOFT_CODING_KEYFLEX_ID_S'
                     , NULL
                     , x_stg_table (i).soft_coding_keyflex_id_s );

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'SOFT_CODING_KEYFLEX_ID_W'
                     , NULL
                     , x_stg_table (i).soft_coding_keyflex_id_w);

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'SUPERVISOR_ID'
                     , NULL
                     , x_stg_table (i).supervisor_id);

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'SUPERVISOR_ID_N'
                     , NULL
                     , x_stg_table (i).supervisor_id_n);

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'ORGANIZATION_ID'
                     , NULL
                     , x_stg_table (i).organization_id);

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'DEFAULT_CODE_COMB_ID'
                     , NULL
                     , x_stg_table (i).default_code_comb_id );

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'DEFAULT_CODE_COMB_ID_D'
                     , NULL
                     , x_stg_table (i).default_code_comb_id_d );

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'DEFAULT_CODE_COMB_ID_P'
                     , NULL
                     , x_stg_table (i).default_code_comb_id_p   );

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'DEFAULT_CODE_COMB_ID_R'
                     , NULL
                     , x_stg_table (i).default_code_comb_id_r );

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'JOB_ID'
                     , NULL
                     , x_stg_table (i).job_id  );

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'PAYROLL_ID'
                     , NULL
                     , x_stg_table (i).payroll_id  );

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'ASSIGNMENT_STATUS_TYPE_ID'
                     , NULL
                     , x_stg_table (i).assignment_status_type_id );

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'NORMAL_HOURS'
                     , NULL
                     , x_stg_table (i).normal_hours );

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'PAY_BASIS_ID'
                     , NULL
                     , x_stg_table (i).pay_basis_id );

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'POSITION_ID'
                     , NULL
                     , x_stg_table (i).position_id );

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'ASSIGNMENT_CATEGORY'
                     , NULL
                     , x_stg_table (i).assignment_category );

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'FREQUENCY'
                     , NULL
                     , x_stg_table (i).frequency);

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'EMPLOYMENT_CATEGORY'
                     , NULL
                     , x_stg_table (i).employment_category);

      insert_audit (  x_stg_table (i).person_id
                     ,x_stg_table (i).assignment_id
                     , x_table_name
                     ,'HOURLY_SALARIED_CODE'
                     , NULL
                     , x_stg_table (i).hourly_salaried_code);

      ---------------------------------------------------------------------------------------
      x_date_start              := NULL;
      x_actual_termination_date := NULL;
      x_leaving_reason          := NULL;
      x_adjusted_svc_date       := NULL;
      x_period_of_service_id    := NULL;

      BEGIN
        SELECT  ser.period_of_service_id
               ,ser.date_start
               ,ser.actual_termination_date
               ,ser.leaving_reason
               ,ser.adjusted_svc_date
          INTO  x_period_of_service_id
               ,x_date_start
               ,x_actual_termination_date
               ,x_leaving_reason
               ,x_adjusted_svc_date
          FROM  per_periods_of_service ser
         WHERE  ser.person_id = x_stg_table (i).person_id;
           --AND  SYSDATE BETWEEN ser.date_start AND NVL(ser.actual_termination_date,SYSDATE+1);
      EXCEPTION WHEN OTHERS THEN
         x_date_start              := NULL;
         x_actual_termination_date := NULL;
         x_leaving_reason          := NULL;
         x_adjusted_svc_date       := NULL;
         x_period_of_service_id    := NULL;
      END;

      x_table_name:= 'PER_PERIODS_OF_SERVICE';
      insert_audit (  x_stg_table (i).person_id
                     ,x_period_of_service_id
                     , x_table_name
                     ,'DATE_START'
                     , NULL
                     , x_date_start);

      insert_audit (  x_stg_table (i).person_id
                     ,x_period_of_service_id
                     , x_table_name
                     ,'ACTUAL_TERMINATION_DATE'
                     , NULL
                     , x_actual_termination_date);

      insert_audit (  x_stg_table (i).person_id
                     ,x_period_of_service_id
                     , x_table_name
                     ,'LEAVING_REASON'
                     , NULL
                     , x_leaving_reason);

      insert_audit (  x_stg_table (i).person_id
                     ,x_period_of_service_id
                     , x_table_name
                     ,'ADJUSTED_SVC_DATE'
                     , NULL
                     , x_adjusted_svc_date);

      ---------------------------------------------------------------------------------------
      x_address_line1        := NULL;
      x_address_line2        := NULL;
      x_town_or_city         := NULL;
      x_postal_code          := NULL;
      x_country              := NULL;
      x_region_2             := NULL;
      x_address_id           := NULL;
      x_adr_date_from        := NULL;
      x_adr_date_to          := NULL;
      x_adr_last_update_date := NULL;
      x_adr_creation_date    := NULL;

      BEGIN
        SELECT  adr.address_id
               ,adr.address_line1
               ,adr.address_line2
               ,adr.town_or_city
               ,adr.postal_code
               ,adr.country
               ,adr.region_2
               ,adr.date_from
               ,adr.date_to
               ,adr.last_update_date
               ,adr.creation_date
          INTO  x_address_id
               ,x_address_line1
               ,x_address_line2
               ,x_town_or_city
               ,x_postal_code
               ,x_country
               ,x_region_2
               ,x_adr_date_from
               ,x_adr_date_to
               ,x_adr_last_update_date
               ,x_adr_creation_date
          FROM  per_addresses adr
         WHERE  adr.person_id = x_stg_table (i).person_id
           AND  adr.address_id = (SELECT  MAX(address_id)
                                    FROM  per_addresses
                                   WHERE  person_id = adr.person_id);
      EXCEPTION WHEN OTHERS THEN
          x_address_line1        := NULL;
          x_address_line2        := NULL;
          x_town_or_city         := NULL;
          x_postal_code          := NULL;
          x_country              := NULL;
          x_region_2             := NULL;
          x_address_id           := NULL;
          x_adr_date_from        := NULL;
          x_adr_date_to          := NULL;
          x_adr_last_update_date := NULL;
          x_adr_creation_date    := NULL;
      END;

      x_table_name:= 'PER_ADDRESSES';
      insert_audit_date (  x_stg_table (i).person_id
                         , x_address_id
                         , x_table_name
                         ,'ADDRESS_LINE1'
                         , NULL
                         , x_address_line1
                         , x_adr_last_update_date
                         , x_adr_date_from
                         , x_adr_date_to
                         , x_adr_creation_date);

      insert_audit_date (  x_stg_table (i).person_id
                         , x_address_id
                         , x_table_name
                         ,'ADDRESS_LINE2'
                         , NULL
                         , x_address_line2
                         , x_adr_last_update_date
                         , x_adr_date_from
                         , x_adr_date_to
                         , x_adr_creation_date);


      insert_audit_date (  x_stg_table (i).person_id
                         , x_address_id
                         , x_table_name
                         ,'TOWN_OR_CITY'
                         , NULL
                         , x_town_or_city
                         , x_adr_last_update_date
                         , x_adr_date_from
                         , x_adr_date_to
                         , x_adr_creation_date);


      insert_audit_date (  x_stg_table (i).person_id
                         , x_address_id
                         , x_table_name
                         ,'POSTAL_CODE'
                         , NULL
                         , x_postal_code
                         , x_adr_last_update_date
                         , x_adr_date_from
                         , x_adr_date_to
                         , x_adr_creation_date);


      insert_audit_date (  x_stg_table (i).person_id
                         , x_address_id
                         , x_table_name
                         ,'COUNTRY'
                         , NULL
                         , x_country
                         , x_adr_last_update_date
                         , x_adr_date_from
                         , x_adr_date_to
                         , x_adr_creation_date);


      insert_audit_date (  x_stg_table (i).person_id
                         , x_address_id
                         , x_table_name
                         ,'REGION_2'
                         , NULL
                         , x_region_2
                         , x_adr_last_update_date
                         , x_adr_date_from
                         , x_adr_date_to
                         , x_adr_creation_date);


      ---------------------------------------------------------------------------------------

      x_proposed_salary_n     := NULL;
      x_proposed_salary_rate  := NULL;
      x_change_date           := NULL;
      x_attribute1            := NULL;
      x_attribute2            := NULL;
      x_proposal_reason       := NULL;
      x_pay_proposal_id       := NULL;
      x_pay_date_from         := NULL;
      x_pay_date_to           := NULL;
      x_pay_last_update_date  := NULL;
      x_pay_creation_date     := NULL;


      BEGIN
        SELECT  pro.pay_proposal_id
               ,pro.proposed_salary_n proposed_salary_n
               ,pro.proposed_salary_n proposed_salary_rate
               ,pro.change_date
               ,pro.attribute1
               ,pro.attribute2
               ,pro.proposal_reason
               ,pro.change_date
               ,pro.date_to
               ,pro.last_update_date
               ,pro.creation_date
          INTO  x_pay_proposal_id
               ,x_proposed_salary_n
               ,x_proposed_salary_rate
               ,x_change_date
               ,x_attribute1
               ,x_attribute2
               ,x_proposal_reason
               ,x_pay_date_from
               ,x_pay_date_to
               ,x_pay_last_update_date
               ,x_pay_creation_date
          FROM  per_pay_proposals pro
         WHERE  pro.assignment_id = x_stg_table (i).assignment_id
           AND  pro.pay_proposal_id = (SELECT  MAX(pay_proposal_id)
                                         FROM  per_pay_proposals
                                        WHERE  assignment_id = pro.assignment_id);
      EXCEPTION WHEN OTHERS THEN
         x_proposed_salary_n     := NULL;
         x_proposed_salary_rate  := NULL;
         x_change_date           := NULL;
         x_attribute1            := NULL;
         x_attribute2            := NULL;
         x_proposal_reason       := NULL;
         x_pay_proposal_id       := NULL;
         x_pay_date_from         := NULL;
         x_pay_date_to           := NULL;
         x_pay_last_update_date  := NULL;
         x_pay_creation_date     := NULL;
      END;
      x_table_name:= 'PER_PAY_PROPOSALS';

      insert_audit_date (  x_stg_table (i).person_id
                         , x_pay_proposal_id
                         , x_table_name
                         ,'PROPOSED_SALARY_N'
                         , NULL
                         , x_proposed_salary_n
                         , x_pay_last_update_date
                         , x_pay_date_from
                         , x_pay_date_to
                         , x_pay_creation_date );

      insert_audit_date (  x_stg_table (i).person_id
                         , x_pay_proposal_id
                         , x_table_name
                         ,'PROPOSED_SALARY_RATE'
                         , NULL
                         , x_proposed_salary_rate
                         , x_pay_last_update_date
                         , x_pay_date_from
                         , x_pay_date_to
                         , x_pay_creation_date );

      insert_audit_date (  x_stg_table (i).person_id
                         , x_pay_proposal_id
                         , x_table_name
                         ,'CHANGE_DATE'
                         , NULL
                         , x_change_date
                         , x_pay_last_update_date
                         , x_pay_date_from
                         , x_pay_date_to
                         , x_pay_creation_date );

      insert_audit_date (  x_stg_table (i).person_id
                         , x_pay_proposal_id
                         , x_table_name
                         ,'ATTRIBUTE1'
                         , NULL
                         , x_attribute1
                         , x_pay_last_update_date
                         , x_pay_date_from
                         , x_pay_date_to
                         , x_pay_creation_date );

      insert_audit_date (  x_stg_table (i).person_id
                         , x_pay_proposal_id
                         , x_table_name
                         ,'ATTRIBUTE2'
                         , NULL
                         , x_attribute2
                         , x_pay_last_update_date
                         , x_pay_date_from
                         , x_pay_date_to
                         , x_pay_creation_date );

      insert_audit_date (  x_stg_table (i).person_id
                         , x_pay_proposal_id
                         , x_table_name
                         ,'PROPOSAL_REASON'
                         , NULL
                         , x_proposal_reason
                         , x_pay_last_update_date
                         , x_pay_date_from
                         , x_pay_date_to
                         , x_pay_creation_date );

      ---------------------------------------------------------------------------------------
      x_table_name:= 'PER_PHONES';
      x_phone_number1  := NULL;
      x_phone_number2  := NULL;
      x_phone_number3  := NULL;
      x_phone_id       := NULL;

      BEGIN
        SELECT  ph1.phone_id
               ,ph1.phone_number
               ,ph2.phone_number
               ,ph3.phone_number
          INTO  x_phone_id
               ,x_phone_number1
               ,x_phone_number2
               ,x_phone_number3
          FROM  per_phones ph1
               ,per_phones ph2
               ,per_phones ph3
         WHERE  ph1.parent_id = x_stg_table (i).person_id
           AND  ph2.parent_id = x_stg_table (i).person_id
           AND  ph3.parent_id = x_stg_table (i).person_id
           AND  ph1.phone_type = 'H1'
           AND  ph2.phone_type = 'H1'
           AND  ph3.phone_type = 'H1'
           AND  ph1.parent_table = 'PER_ALL_PEOPLE_F'
           AND  ph2.parent_table = 'PER_ALL_PEOPLE_F'
           AND  ph3.parent_table = 'PER_ALL_PEOPLE_F';
      EXCEPTION WHEN OTHERS THEN
        x_phone_number1  := NULL;
        x_phone_number2  := NULL;
        x_phone_number3  := NULL;
        x_phone_id       := NULL;
      END;
      insert_audit (   x_stg_table (i).person_id
                     , x_phone_id
                     , x_table_name
                     ,'PHONE_NUMBER1'
                     , NULL
                     , x_phone_number1);

      insert_audit (   x_stg_table (i).person_id
                     , x_phone_id
                     , x_table_name
                     ,'PHONE_NUMBER2'
                     , NULL
                     , x_phone_number2);

      insert_audit (   x_stg_table (i).person_id
                     , x_phone_id
                     , x_table_name
                     ,'PHONE_NUMBER3'
                     , NULL
                     , x_phone_number3 );
      ---------------------------------------------------------------------------------------
    END LOOP;
    IF c_emp%ISOPEN THEN
       CLOSE c_emp;
    END IF;
    COMMIT;
    FND_FILE.PUT_LINE( FND_FILE.LOG,'-------------------------------------------------------');
    FND_FILE.PUT_LINE( FND_FILE.LOG,'Employee Count     -> '||x_count);
    FND_FILE.PUT_LINE( FND_FILE.LOG,'-------------------------------------------------------');
  END snap_insert;
  ----------------------------------------------------------------------
END xx_hr_audit_snap_pkg;
/
