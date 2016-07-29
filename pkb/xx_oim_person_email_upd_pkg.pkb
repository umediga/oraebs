DROP PACKAGE BODY APPS.XX_OIM_PERSON_EMAIL_UPD_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OIM_PERSON_EMAIL_UPD_PKG" 
AS
----------------------------------------------------------------------
/* $Header: xxoimpersonemailupd.pkb 1.0 2013/19/11 12:00:00 jbhosale noship $ */
/*
Created By     : INTEGRA Development Team
Creation Date  : 19-OCT-2013
File Name      : xxoimpersonemailupd.pkb
Description    : This script is used to Update Integra Email Address on person record by OIM
 (Oracle Identity management) once exchange account is provisioned.
Change History:
Version Date        Name                           Remarks
------- ----------- ------------------------      ----------------------
1.0     19-NOV-2013   INTEGRA Development Team    Initial development.
1.1     03-DEC-2013   Jagdish Bhosale             Added Output parameter for status.
1.2     05-DEC-2013   Jagdish Bhosale             Bug: Email Update was not happening for CWK added NPW_NUMBER.
                                                  and API Related changes.
1.3     20-MAy-2014   Jagdish Bhosale             Excluded Ex employee and Ex Applicatnt type from selection criteria.
*/
/*----------------------------------------------------------------------*/
   PROCEDURE update_email (
      p_employee_number   IN       VARCHAR,
      p_email_address     IN       VARCHAR,
      p_status            OUT      VARCHAR
   )
   IS
      CURSOR get_emp_dtls
      IS
      SELECT full_name, a.person_id,
                decode(b.system_person_type,'CWK',a.npw_number,'EMP',a.employee_number,a.employee_number) employee_number,
                a.object_version_number, email_address, a.effective_start_date,
                c.person_type_id,
                b.system_person_type person_type
           FROM per_all_people_f a,per_person_types b, per_person_type_usages_f c        --where full_name like 'Bhosale%Jag%'
          WHERE 1=1
          AND c.person_type_id = b.person_type_id
          AND a.person_id = c.person_id 
          AND b.system_person_type NOT LIKE 'EX%'
          AND a.effective_start_date between c.effective_start_date and c.effective_end_date -- 03/12/  --
         -- AND sysdate between a.effective_start_date and a.effective_end_date  -- 03/12 --
          AND decode(b.system_person_type,'CWK',a.npw_number,'EMP',a.employee_number,a.employee_number) = p_employee_number
          AND a.effective_start_date IN (
                    SELECT MAX (a1.effective_start_date)
                      FROM per_all_people_f a1,per_person_types b1, per_person_type_usages_f c1
                     WHERE c1.person_type_id = b1.person_type_id
                     AND a1.person_id = c1.person_id
                     AND a1.person_id = a.person_id
                     AND b1.system_person_type = b.system_person_type
                     AND c1.effective_start_date = (select max(c2.effective_start_date) from per_person_type_usages_f c2
                     where person_id = c1.person_id));



-- -----------------------      
-- Local Variables
-- -----------------------
      l_email_address               VARCHAR2 (100)          := p_email_address;
      ln_object_version_number      per_all_people_f.object_version_number%TYPE;
      lc_employee_number            per_all_people_f.employee_number%TYPE;
      l_person_id                   per_all_people_f.person_id%TYPE;
      lc_dt_ud_mode                 VARCHAR2 (100)                     := NULL;
-- ---------------------------------------------------------------
-- Out Variables for Find Date Track Mode API
-- ----------------------------------------------------------------
      lb_correction                 BOOLEAN;
      lb_update                     BOOLEAN;
      lb_update_override            BOOLEAN;
      lb_update_change_insert       BOOLEAN;
-- -----------------------------------------------------------
-- Out Variables for Update Employee API
-- -----------------------------------------------------------
      ld_effective_start_date       DATE;
      ld_effective_end_date         DATE;
      lc_full_name                  per_all_people_f.full_name%TYPE;
      ln_comment_id                 per_all_people_f.comment_id%TYPE;
      lb_name_combination_warning   BOOLEAN;
      lb_assign_payroll_warning     BOOLEAN;
      lb_orig_hire_warning          BOOLEAN;
      l_sqlerrm                     VARCHAR2 (1000);
      lc_effective_date             per_all_people_f.effective_start_date%TYPE;
      lc_person_type                VARCHAR2 (10);
   BEGIN
      FOR i IN get_emp_dtls
      LOOP
         ln_object_version_number := i.object_version_number;
         lc_employee_number := i.employee_number;
         l_person_id := i.person_id;
         lc_full_name := i.full_name;
         lc_effective_date := i.effective_start_date;
                              -- Added by Jagdish for future Dated Employees.
         lc_person_type := i.person_type;
     -- END LOOP;

      lc_dt_ud_mode := 'CORRECTION';
--        lc_dt_ud_mode := 'UPDATE';

-- ---------------------------------
-- Update Employee API.
-- ---------------------------------
      BEGIN
         -- Verify EMP OR CWK --
         IF (lc_person_type = 'CWK')
         THEN
            lc_employee_number := NULL;
         END IF;

         hr_person_api.update_person
                   (                         -- Input Data Elements
                                             -- ------------------------------
                    -- p_effective_date                              => TO_DATE(SYSDATE),
                    p_effective_date                => TO_DATE (lc_effective_date),
                    p_datetrack_update_mode         => lc_dt_ud_mode,
                    p_person_id                     => l_person_id,
                    p_email_address                 => l_email_address,
-- p_npw_number                    => lc_employee_number,
 --------------------------------------
     -- Output Data Elements
 -- ----------------------------------
                    p_employee_number               => lc_employee_number,
                    p_object_version_number         => ln_object_version_number,
                    p_effective_start_date          => ld_effective_start_date,
                    p_effective_end_date            => ld_effective_end_date,
                    p_full_name                     => lc_full_name,
                    p_comment_id                    => ln_comment_id,
                    p_name_combination_warning      => lb_name_combination_warning,
                    p_assign_payroll_warning        => lb_assign_payroll_warning,
                    p_orig_hire_warning             => lb_orig_hire_warning
                   );
         p_status := 'SUCCESS';
      EXCEPTION
         WHEN OTHERS
         THEN
            p_status := 'FAIL';
            l_sqlerrm := SUBSTR (SQLERRM, 1, 800);
            DBMS_OUTPUT.put_line (SQLERRM);
            COMMIT;
      END;
      
  END LOOP;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_status := 'FAIL';
         DBMS_OUTPUT.put_line (SQLERRM);
   END update_email;
END xx_oim_person_email_upd_pkg; 
/
