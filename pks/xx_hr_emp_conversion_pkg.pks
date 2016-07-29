DROP PACKAGE APPS.XX_HR_EMP_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_EMP_CONVERSION_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : XXHRMPCNV.pks
 Description   : This script creates the specification of the package
                 xx_hr_emp_conversion_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 01-Apr-2010 Suman Sur             Record Types Modified as per Ansell Requirement.
 06-Jan-2012 Deepika Jain          Changes for Integra
*/
----------------------------------------------------------------------
   g_stage                VARCHAR2 (2000);
   g_batch_id             VARCHAR2 (200);
   g_file1                VARCHAR2 (100)  := 'XXHREMPSTG.tbl';
   g_file2                VARCHAR2 (100)  := 'XXHREMPPRE.tbl';
   g_file3                VARCHAR2 (100)  := 'XXHREMPSTG.syn';
   g_file4                VARCHAR2 (100)  := 'XXHREMPPRE.syn';
   g_file5                VARCHAR2 (100)  := 'XXHREMPCNV.pks';
   g_file6                VARCHAR2 (100)  := 'XXHREMPCNV.pkb';
   g_file7                VARCHAR2 (100)  := 'XXHREMPVAL.pks';
   g_file8                VARCHAR2 (100)  := 'XXHREMPVAL.pkb';
   g_file1_ver            VARCHAR2 (100)  := '1.0';
   g_file2_ver            VARCHAR2 (100)  := '1.0';
   g_file3_ver            VARCHAR2 (100)  := '1.0';
   g_file4_ver            VARCHAR2 (100)  := '1.0';
   g_file5_ver            VARCHAR2 (100)  := '1.0';
   g_file6_ver            VARCHAR2 (100)  := '1.0';
   g_file7_ver            VARCHAR2 (100)  := '1.0';
   g_file8_ver            VARCHAR2 (100)  := '1.0';
   -- Added for Integra
   g_emp_person_type      VARCHAR2 (100)  := 'Employee';
   g_cwk_person_type      VARCHAR2 (100)  := 'Contingent Worker';
   g_cdt_person_type      VARCHAR2 (100)  := 'Candidate';
   g_validate_and_load    VARCHAR2 (100)  := 'VALIDATE_AND_LOAD';
   g_ex_emp_person_type   VARCHAR2 (100)  := 'EX_EMP';
   g_validate_flag        BOOLEAN         := TRUE;

   TYPE g_xx_hr_cnv_pre_rec_type IS RECORD (
      batch_id                        VARCHAR2 (200),
      country                         VARCHAR2 (30),      -- added by deepika
      business_group_name             VARCHAR2 (240),
      rehire_flag                     VARCHAR2 (10),       --added by deepika
      user_person_type                VARCHAR2 (80),
      employee_number                 VARCHAR2 (30),
      npw_number                      VARCHAR2 (30),
      national_identifier             VARCHAR2 (30),
      title                           VARCHAR2 (30),
      first_name                      VARCHAR2 (150),
      middle_names                    VARCHAR2 (60),
      last_name                       VARCHAR2 (150),
      full_name                       VARCHAR2 (240),
      pre_name_adjunct                VARCHAR2 (30),
      suffix                          VARCHAR2 (30),
      previous_last_name              VARCHAR2 (150),
      known_as                        VARCHAR2 (80),-- column mapped to preferred_name from data file
      sex                             VARCHAR2 (30),
      date_of_birth                   DATE,
      marital_status                  VARCHAR2 (30),
      nationality                     VARCHAR2 (30),
      town_of_birth                   VARCHAR2 (90),
      region_of_birth                 VARCHAR2 (90),
      country_of_birth                VARCHAR2 (90),
      hire_date                       DATE,
      adjusted_svc_date               DATE,
      termination_date                DATE,               -- added by deepika
      termination_reason              VARCHAR2 (150),     -- added by deepika
      final_processing_date           DATE,               -- added by deepika
      original_date_of_hire           DATE,-- column mapped to Date first hired from data file
      registered_disabled_flag        VARCHAR2 (30),
      email_address                   VARCHAR2 (240),
      mailstop                        VARCHAR2 (45),
      office_number                   VARCHAR2 (45),
      correspondence_language         VARCHAR2 (30),
      student_status                  VARCHAR2 (30),
      on_military_service             VARCHAR2 (30),
      ethnic_origin                   VARCHAR2 (200),
      i9_status                       VARCHAR2 (30),
      i9_expiration_date              VARCHAR2 (150),      --added by deepika
      vets_100                        VARCHAR2 (150),      --added by deepika
      vets_100a                       VARCHAR2 (150),      --added by deepika
      new_hire_status                 VARCHAR2 (150),      --added by deepika
      reason_for_exclusion            VARCHAR2 (150),      --added by deepika
      child_support_obligation        VARCHAR2 (150),      --added by deepika
      opted_for_medicare              VARCHAR2 (150),      --added by deepika
      ethnicity_disclosed             VARCHAR2 (150),      --added by deepika
      sex_entered_by                  VARCHAR2 (150),      --added by deepika
      ethnic_origin_entered_by        VARCHAR2 (150),      --added by deepika
      work_per_num                    VARCHAR2 (150),
      work_per_stat                   VARCHAR2 (150),
      work_per_end_dt                 VARCHAR2 (150),      --added by deepika
      rfc_id                          VARCHAR2 (100),
      federal_govt_affiliation_id     VARCHAR2 (100),
      soc_sec_id                      VARCHAR2 (100),
      mil_ser_id                      VARCHAR2 (100),
      soc_sec_med_cen                 VARCHAR2 (30),
      mat_last_name                   VARCHAR2 (150),
      maiden_name                     VARCHAR2 (150),      --added by deepika
      date_first_entry_france         VARCHAR2 (150),      --added by deepika
      military_status                 VARCHAR2 (150),      --added by deepika
      cpam_name                       VARCHAR2 (150),      --added by deepika
      level_of_education              VARCHAR2 (150),      --added by deepika
      date_last_school_certificate    VARCHAR2 (150),      --added by deepika
      school_name                     VARCHAR2 (150),      --added by deepika
      provisional_number              VARCHAR2 (150),      --added by deepika
      personal_email_id               VARCHAR2 (150),      --added by deepika
      ethnic_origin_gb                VARCHAR2 (150),      --added by deepika
      director                        VARCHAR2 (150),      --added by deepika
      pensioner                       VARCHAR2 (150),      --added by deepika
      work_per_num_gb                 VARCHAR2 (150),      --added by deepika
      additional_pensionable_years    VARCHAR2 (150),      --added by deepika
      additional_pensionable_months   VARCHAR2 (150),      --added by deepika
      additional_pensionable_days     VARCHAR2 (150),      --added by deepika
      ni_multiple_assignments         VARCHAR2 (150),      --added by deepika
      paye_agg_assignments            VARCHAR2 (150),      --added by deepika
      dss_link_letter_end_date        VARCHAR2 (150),      --added by deepika
      mother_maiden_name              VARCHAR2 (150),      --added by deepika
      ethnic_origin_ie                VARCHAR2 (150),      --added by deepika
      professional_title              VARCHAR2 (150),      --added by deepika
      hereditary_title                VARCHAR2 (150),      --added by deepika
      last_name_at_birth              VARCHAR2 (150),      --added by deepika
      hereditary_title_at_birth       VARCHAR2 (150),      --added by deepika
      prefix_at_birth                 VARCHAR2 (150),      --added by deepika
      date_of_marriage                VARCHAR2 (150),      --added by deepika
      previous_prefix                 VARCHAR2 (150),      --added by deepika
      eu_soc_insurance_num            VARCHAR2 (150),      --added by deepika
      second_nationality              VARCHAR2 (150),      --added by deepika
      prefix                          VARCHAR2 (150),      --added by deepika
      eighteen_years_below            VARCHAR2 (150),      --added by deepika
      prev_employment_end_date        VARCHAR2 (150),      --added by deepika
      child_allowance_reg             VARCHAR2 (150),      --added by deepika
      holiday_insurance_reg           VARCHAR2 (150),      --added by deepika
      pension_reg                     VARCHAR2 (150),      --added by deepika
      id_number                       VARCHAR2 (150),      --added by deepika
      school_leaver                   VARCHAR2 (150),      --added by deepika
      payroll_tax_state               VARCHAR2 (150),      --added by deepika
      exclude_from_payroll_tax        VARCHAR2 (150),      --added by deepika
      work_per_num_nz                 VARCHAR2 (150),      --added by deepika
      work_per_expiry_date            VARCHAR2 (150),      --added by deepika
      ethnic_origin_nz                VARCHAR2 (150),      --added by deepika
      tribal_group                    VARCHAR2 (150),      --added by deepika
      district_of_origin              VARCHAR2 (150),      --added by deepika
      stat_nz_emp_cat                 VARCHAR2 (150),      --added by deepika
      stat_nz_working_time            VARCHAR2 (150),      --added by deepika
      business_group_id               NUMBER,              --added by deepika
      person_type_id                  NUMBER,              --added by deepika
      person_id                       NUMBER,              --added by deepika
      global_person_id                NUMBER,              --added by deepika
      period_of_service_id            NUMBER,              --added by deepika
      object_version_number           NUMBER,              --added by deepika
      attribute_category              VARCHAR2 (30),
      attribute1                      VARCHAR2 (150),
      attribute2                      VARCHAR2 (150),
      attribute3                      VARCHAR2 (150),
      attribute4                      VARCHAR2 (150),
      attribute5                      VARCHAR2 (150),
      attribute6                      VARCHAR2 (150),
      attribute7                      VARCHAR2 (150),
      attribute8                      VARCHAR2 (150),
      attribute9                      VARCHAR2 (150),
      attribute10                     VARCHAR2 (150),
      eit_information_type            VARCHAR2 (150),      --added by deepika
      eit_information_category        VARCHAR2 (150),      --added by deepika
      eit1                            VARCHAR2 (150),      --added by deepika
      eit2                            VARCHAR2 (150),      --added by deepika
      eit3                            VARCHAR2 (150),      --added by deepika
      eit4                            VARCHAR2 (150),      --added by deepika
      eit5                            VARCHAR2 (150),      --added by deepika
      eit6                            VARCHAR2 (150),      --added by deepika
      eit7                            VARCHAR2 (150),      --added by deepika
      eit8                            VARCHAR2 (150),      --added by deepika
      record_number                   NUMBER,
      process_code                    VARCHAR2 (100),
      ERROR_CODE                      VARCHAR2 (100),
      request_id                      NUMBER (15, 0),
      last_update_date                DATE,
      last_updated_by                 NUMBER (15, 0),
      last_update_login               NUMBER (15, 0),
      created_by                      NUMBER (15, 0),
      creation_date                   DATE,
      program_application_id          NUMBER (15, 0),
      program_id                      NUMBER (15, 0),
      program_update_date             DATE
   );

   TYPE g_xx_hr_cnv_pre_tab_type IS TABLE OF g_xx_hr_cnv_pre_rec_type
      INDEX BY BINARY_INTEGER;

   PROCEDURE main (
      errbuf                OUT NOCOPY      VARCHAR2,
      retcode               OUT NOCOPY      VARCHAR2,
      p_batch_id            IN              VARCHAR2,
      p_restart_flag        IN              VARCHAR2,
      p_override_flag       IN              VARCHAR2,
      p_validate_and_load   IN              VARCHAR2
   );
END xx_hr_emp_conversion_pkg;
/
