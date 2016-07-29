DROP PACKAGE APPS.XX_HR_ASG_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_ASG_CONVERSION_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    :IBM Dev
 Creation Date :30-Dec-2011
 File Name     : XXHRASGCNV.pks
 Description   : This script creates the specification of the package
                 xx_hr_asg_conversion_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 30-Dec-2011 IBM Development       Initial Development
 25-Jan-2012  Deepika Jain    Modified for Integra
 10-APR-2013  Jagdish Bhosale  TYPE g_xx_asg_cnv_pre_rec_type changed; job_name and pos_title width changed to 200.
*/
----------------------------------------------------------------------
   g_stage               VARCHAR2 (2000);
   g_batch_id            VARCHAR2 (200);
   l_sqlerrm             VARCHAR2 (2000);
   -- Added for Integra
   g_emp_person_type     VARCHAR2 (100)  := 'Employee';
   g_cwk_person_type     VARCHAR2 (100)  := 'Contingent Worker';
   g_validate_and_load   VARCHAR2 (100)  := 'VALIDATE_AND_LOAD';
   g_validate_flag       BOOLEAN         := TRUE;

   TYPE g_xx_asg_cnv_pre_rec_type IS RECORD (
      business_group_name              VARCHAR2 (240),
      employee_number                  VARCHAR2 (100),                      --
      first_name                       VARCHAR2 (240),                      --
      last_name                        VARCHAR2 (240),                      --
      hire_date                        DATE,                                --
      assignment_number                VARCHAR2 (30),                       --
      assignment_status                VARCHAR2 (100),                      --
      country                          VARCHAR2 (100),   -- added for integra
      primary_flag                     VARCHAR2 (30),                       --
      assignment_category              VARCHAR2 (30),                       --
      ORGANIZATION                     VARCHAR2 (100),                      --
      LOCATION                         VARCHAR2 (100),                      --
      work_at_home                     VARCHAR2 (30),                       --
      person_type                      VARCHAR2 (240),                      --
      manager_flag                     VARCHAR2 (30),                       --
      normal_hours                     NUMBER (22, 3),                      --
      hourly_salaried_code             VARCHAR2 (30),                       --
      salary_basis                     VARCHAR2 (100),                      --
      payroll_name                     VARCHAR2 (100),                      --
      job_name                         VARCHAR2 (200),                      --
      pos_title                        VARCHAR2 (200),
      grade_name                       VARCHAR2 (100),                      --
      supervisor_unique_id             VARCHAR2 (100),                      --
      supervisor_number                VARCHAR2 (100),                      --
      supervisor_first_name            VARCHAR2 (100),                      --
      supervisor_last_name             VARCHAR2 (100),                      --
      effective_start_date             DATE,
      --          need to have it ( use actual start date)
      sob_name                         VARCHAR2 (30),             -- SOB Name
      acct_seg1                        VARCHAR2 (30),         -- Account Seg1
      acct_seg2                        VARCHAR2 (30),         -- Account Seg2
      acct_seg3                        VARCHAR2 (30),         -- Account Seg3
      acct_seg4                        VARCHAR2 (30),         -- Account Seg4
      acct_seg5                        VARCHAR2 (30),         -- Account Seg5
      acct_seg6                        VARCHAR2 (30),         -- Account Seg6
      acct_seg7                        VARCHAR2 (30),         -- Account Seg7
      acct_seg8                        VARCHAR2 (30),
      -- Account Seg8 -- added for integra
      acct_seg9                        VARCHAR2 (30),
      -- Account Seg9 -- added for integra
      SOURCE                           VARCHAR2 (30),               -- Source
      change_reason                    VARCHAR2 (30),                       --
      date_probation_end               DATE,                                --
      frequency                        VARCHAR2 (30),                       --
      internal_address_line            VARCHAR2 (80),                       --
      perf_review_period               NUMBER (15, 0),                      --
      perf_review_period_frequency     VARCHAR2 (30),                       --
      probation_period                 NUMBER,
                        --VARCHAR2(100)               --Changed for Mock CONV
      probation_unit                   VARCHAR2 (30),                       --
      sal_review_period                NUMBER (15, 0),                      --
      sal_review_period_frequency      VARCHAR2 (30),                       --
      source_type                      VARCHAR2 (30),                       --
      time_normal_finish               VARCHAR2 (5),                        --
      time_normal_start                VARCHAR2 (5),                        --
      bargaining_unit_code             VARCHAR2 (30),                       --
      labour_union_member_flag         VARCHAR2 (30),                       --
      ass_attribute_category           VARCHAR2 (30),                       --
      ass_attribute1                   VARCHAR2 (150),                      --
      ass_attribute2                   VARCHAR2 (150),                      --
      ass_attribute3                   VARCHAR2 (150),                      --
      ass_attribute4                   VARCHAR2 (150),                      --
      ass_attribute5                   VARCHAR2 (150),                      --
      ass_attribute6                   VARCHAR2 (150),                      --
      ass_attribute7                   VARCHAR2 (150),                      --
      ass_attribute8                   VARCHAR2 (150),                      --
      ass_attribute9                   VARCHAR2 (150),                      --
      ass_attribute10                  VARCHAR2 (150),                      --
      notice_period                    NUMBER (10, 0),                      --
      notice_period_uom                VARCHAR2 (30),                       --
      employee_category                VARCHAR2 (30),                       --
      job_post_source_name             VARCHAR2 (240),                      --
      period_of_placement_date_start   DATE,                                --
      vendor_employee_number           VARCHAR2 (30),                       --
      vendor_assignment_number         VARCHAR2 (30),                       --
      project_title                    VARCHAR2 (30),                       --
      applicant_rank                   NUMBER,                              --
      segment1                         VARCHAR2 (150),   -- Added for Integra
      segment2                         VARCHAR2 (150),   -- Added for Integra
      segment3                         VARCHAR2 (150),   -- Added for Integra
      segment4                         VARCHAR2 (150),   -- Added for Integra
      segment5                         VARCHAR2 (150),   -- Added for Integra
      segment6                         VARCHAR2 (150),   -- Added for Integra
      segment7                         VARCHAR2 (150),   -- Added for Integra
      segment8                         VARCHAR2 (150),   -- Added for Integra
      segment9                         VARCHAR2 (150),   -- Added for Integra
      segment10                        VARCHAR2 (150),   -- Added for Integra
      actual_start_date                DATE,             -- Added for Integra
      person_unique_id                 VARCHAR2 (30),    -- Added for Integra
      full_name                        VARCHAR2 (240),                      --
      assignment_type                  VARCHAR2 (1),                        --
      assignment_sequence              NUMBER (15, 0),                      --
      establishment                    VARCHAR2 (150),   -- Added for Integra
      contract                         VARCHAR2 (150),   -- Added for Integra
      vacancy_name                     VARCHAR2 (150),   -- Added for Integra
      eit_information_type             VARCHAR2 (150),   -- Added for Integra
      eit_information_category         VARCHAR2 (150),   -- Added for Integra
      eit1                             VARCHAR2 (150),   -- Added for Integra
      eit2                             VARCHAR2 (150),   -- Added for Integra
      eit3                             VARCHAR2 (150),   -- Added for Integra
      eit4                             VARCHAR2 (150),   -- Added for Integra
      eit5                             VARCHAR2 (150),   -- Added for Integra
      eit6                             VARCHAR2 (150),   -- Added for Integra
      eit7                             VARCHAR2 (150),   -- Added for Integra
      eit8                             VARCHAR2 (150),   -- Added for Integra
      eit9                             VARCHAR2 (150),   -- Added for Integra
      eit10                            VARCHAR2 (150),   -- Added for Integra
      gov_rep_entity                   VARCHAR2 (150),   -- Added for Integra
      timecard_approver_us             VARCHAR2 (150),   -- Added for Integra
      timecard_required_us             VARCHAR2 (150),   -- Added for Integra
      work_schedule_us                 VARCHAR2 (150),   -- Added for Integra
      shift_us                         VARCHAR2 (150),   -- Added for Integra
      spouse_salary                    VARCHAR2 (150),   -- Added for Integra
      legal_rep                        VARCHAR2 (150),   -- Added for Integra
      worker_comp_override_code        VARCHAR2 (150),   -- Added for Integra
      reporting_estab                  VARCHAR2 (150),   -- Added for Integra
      seasonal_worker_us               VARCHAR2 (150),   -- Added for Integra
      corp_officer_ind                 VARCHAR2 (150),   -- Added for Integra
      corp_officer_code                VARCHAR2 (150),   -- Added for Integra
      area_code                        VARCHAR2 (150),   -- Added for Integra
      occupational_code                VARCHAR2 (150),   -- Added for Integra
      wage_plan_code                   VARCHAR2 (150),   -- Added for Integra
      seasonal_code                    VARCHAR2 (150),   -- Added for Integra
      tax_loc                          VARCHAR2 (150),   -- Added for Integra
      probationary_code                VARCHAR2 (150),   -- Added for Integra
      pvt_disability_plan_id           VARCHAR2 (150),   -- Added for Integra
      family_leave_ins_plan_id         VARCHAR2 (150),   -- Added for Integra
      alpha_ind_class_code             VARCHAR2 (150),   -- Added for Integra
      employer_paye_ref_gb             VARCHAR2 (150),   -- Added for Integra
      unique_id_gb                     VARCHAR2 (150),   -- Added for Integra
      econ                             VARCHAR2 (150),   -- Added for Integra
      max_hol_per_adv                  VARCHAR2 (150),   -- Added for Integra
      bacs_pay_rule                    VARCHAR2 (150),   -- Added for Integra
      smp_recovered                    VARCHAR2 (150),   -- Added for Integra
      smp_compensation                 VARCHAR2 (150),   -- Added for Integra
      ssp_recovered                    VARCHAR2 (150),   -- Added for Integra
      sap_recovered                    VARCHAR2 (150),   -- Added for Integra
      sap_compensation                 VARCHAR2 (150),   -- Added for Integra
      spp_recovered                    VARCHAR2 (150),   -- Added for Integra
      spp_compensation                 VARCHAR2 (150),   -- Added for Integra
      govt_rep_entity_t4_rl1           VARCHAR2 (150),   -- Added for Integra
      govt_rep_entity_t4a_rl1          VARCHAR2 (150),   -- Added for Integra
      govt_rep_entity_t4_rl2           VARCHAR2 (150),   -- Added for Integra
      timecard_approver_ca             VARCHAR2 (150),   -- Added for Integra
      timecard_required_ca             VARCHAR2 (150),   -- Added for Integra
      work_schedule_ca                 VARCHAR2 (150),   -- Added for Integra
      shift_ca                         VARCHAR2 (150),   -- Added for Integra
      naic_override_code               VARCHAR2 (150),   -- Added for Integra
      seasonal_worker_ca               VARCHAR2 (150),   -- Added for Integra
      officer_code                     VARCHAR2 (150),   -- Added for Integra
      work_comp_acct_num_override      VARCHAR2 (150),   -- Added for Integra
      work_comp_rate_code_override     VARCHAR2 (150),   -- Added for Integra
      tax_district_ref                 VARCHAR2 (150),   -- Added for Integra
      ie_paypath_info                  VARCHAR2 (150),   -- Added for Integra
      employer_paye_ref_ie             VARCHAR2 (150),   -- Added for Integra
      legal_employer_ie                VARCHAR2 (150),   -- Added for Integra
      govt_rep_entity_mx               VARCHAR2 (150),   -- Added for Integra
      timecard_approver_mx             VARCHAR2 (150),   -- Added for Integra
      timecard_required_mx             VARCHAR2 (150),   -- Added for Integra
      work_schedule_mx                 VARCHAR2 (150),   -- Added for Integra
      govt_emp_sector                  VARCHAR2 (150),   -- Added for Integra
      soc_sec_sal_type                 VARCHAR2 (150),   -- Added for Integra
      ss_rehire_rep                    VARCHAR2 (150),   -- Added for Integra
      comp_subsidy_emp                 VARCHAR2 (150),   -- Added for Integra
      reg_employer                     VARCHAR2 (150),   -- Added for Integra
      holiday_anniv_date               VARCHAR2 (150),   -- Added for Integra
      legal_employer_au                VARCHAR2 (150),   -- Added for Integra
      incl_leave_loading               VARCHAR2 (150),   -- Added for Integra
      grp_cert_issue_date              VARCHAR2 (150),   -- Added for Integra
      hours_sgc_calc                   VARCHAR2 (150),   -- Added for Integra
      emp_coding                       VARCHAR2 (150),   -- Added for Integra
      work_schedule_be                 VARCHAR2 (150),   -- Added for Integra
      start_reason_be                  VARCHAR2 (150),   -- Added for Integra
      end_reason_be                    VARCHAR2 (150),   -- Added for Integra
      emp_type_be                      VARCHAR2 (150),   -- Added for Integra
      EXEMPT                           VARCHAR2 (150),   -- Added for Integra
      liab_ins_provider                VARCHAR2 (150),   -- Added for Integra
      class_of_risk                    VARCHAR2 (150),   -- Added for Integra
      emp_cat_fr                       VARCHAR2 (150),   -- Added for Integra
      start_reason_fr                  VARCHAR2 (150),   -- Added for Integra
      end_reason_fr                    VARCHAR2 (150),   -- Added for Integra
      work_pattern                     VARCHAR2 (150),   -- Added for Integra
      urssaf_code                      VARCHAR2 (150),   -- Added for Integra
      corps                            VARCHAR2 (150),   -- Added for Integra
      stat_position                    VARCHAR2 (150),   -- Added for Integra
      physical_share                   VARCHAR2 (150),   -- Added for Integra
      pub_sector_emp_type              VARCHAR2 (150),   -- Added for Integra
      work_pattern_start_day           VARCHAR2 (150),   -- Added for Integra
      work_days_per_yr                 VARCHAR2 (150),   -- Added for Integra
      detache_status                   VARCHAR2 (150),   -- Added for Integra
      address_abroad                   VARCHAR2 (150),   -- Added for Integra
      border_worker                    VARCHAR2 (150),   -- Added for Integra
      prof_status                      VARCHAR2 (150),   -- Added for Integra
      reason_non_titulaire             VARCHAR2 (150),   -- Added for Integra
      reason_part_time                 VARCHAR2 (150),   -- Added for Integra
      comments_fr                      VARCHAR2 (150),   -- Added for Integra
      identifier_fr                    VARCHAR2 (150),   -- Added for Integra
      affectation_type                 VARCHAR2 (150),   -- Added for Integra
      percent_affected                 VARCHAR2 (150),   -- Added for Integra
      admin_career_id                  VARCHAR2 (150),   -- Added for Integra
      primary_affectation              VARCHAR2 (150),   -- Added for Integra
      grouping_emp_name                VARCHAR2 (150),   -- Added for Integra
      assignment_id                    NUMBER (10, 0),
      business_group_id                NUMBER (15, 0),
      recruiter_id                     NUMBER (10, 0),            -- not used
      grade_id                         NUMBER (15, 0),
      position_id                      NUMBER (15, 0),
      job_id                           NUMBER (15, 0),
      assignment_status_type_id        NUMBER (9, 0),
      payroll_id                       NUMBER (9, 0),
      location_id                      NUMBER (15, 0),
      person_referred_by_id            NUMBER (10, 0),            -- not used
      supervisor_id                    NUMBER (10, 0),
      special_ceiling_step_id          NUMBER (15, 0),            -- not used
      person_id                        NUMBER (10, 0),
      recruitment_activity_id          NUMBER (15, 0),            -- not used
      source_organization_id           NUMBER (15, 0),            -- not used
      organization_id                  NUMBER (15, 0),
      people_group_id                  NUMBER (15, 0),            -- not used
      soft_coding_keyflex_id           NUMBER (15, 0),
      vacancy_id                       NUMBER (15, 0),            -- not used
      pay_basis_id                     NUMBER (9, 0),
      application_id                   NUMBER (15, 0),
      comment_id                       NUMBER (15, 0),            -- not used
      default_code_comb_id             NUMBER (15, 0),
      employment_category              VARCHAR2 (90),
      period_of_service_id             NUMBER (15, 0),            -- not used
      asg_request_id                   NUMBER (15, 0),
      contract_id                      NUMBER (9, 0),
      collective_agreement_id          NUMBER (9, 0),
      cagr_id_flex_num                 NUMBER (15, 0),
      cagr_grade_def_id                NUMBER (15, 0),
      establishment_id                 NUMBER (15, 0),
      vendor_id                        NUMBER (15, 0),
      grade_ladder_pgm_id              NUMBER (15, 0),
      supervisor_assignment_id         NUMBER (15, 0),
      extracted_person_id              NUMBER,
      extracted_assignment_id          NUMBER,
      pos_code                         VARCHAR2 (100),
      supervisor_start_date            DATE,
      tax_unit_id                      NUMBER,
      npw_number                       VARCHAR2 (30),         -- CWK specific
      concat_segs                      VARCHAR2 (500),
      -- Concatenated Segments
      set_of_books_id                  NUMBER,
      posting_content_id               NUMBER (15, 0),
      hr_rep_id                        NUMBER,           -- added for integra
      hr_director_id                   NUMBER,           -- added for integra
      batch_id                         VARCHAR2 (200),                      --
      process_code                     VARCHAR2 (100),                      --
      ERROR_CODE                       VARCHAR2 (100),                      --
      request_id                       NUMBER (15, 0),                      --
      object_version_number            NUMBER,
      last_update_date                 DATE,                                --
      last_updated_by                  NUMBER (15, 0),                      --
      last_update_login                NUMBER (15, 0),                      --
      created_by                       NUMBER (15, 0),                      --
      creation_date                    DATE,                                --
      record_number                    NUMBER,                              --
      program_application_id           NUMBER (15, 0),                      --
      program_id                       NUMBER (15, 0),                      --
      program_update_date              DATE
   );

   TYPE g_xx_asg_cnv_pre_tab_type IS TABLE OF g_xx_asg_cnv_pre_rec_type
      INDEX BY BINARY_INTEGER;

   PROCEDURE main (
      errbuf                OUT NOCOPY      VARCHAR2,
      retcode               OUT NOCOPY      VARCHAR2,
      p_batch_id            IN              VARCHAR2,
      p_restart_flag        IN              VARCHAR2,
      p_override_flag       IN              VARCHAR2,
      p_validate_and_load   IN              VARCHAR2
   );

   FUNCTION get_org_mapping_value (
      p_mapping_type   IN   VARCHAR2,
      p_old_value      IN   VARCHAR2,
      p_attribute1     IN   VARCHAR2 DEFAULT NULL,
      p_attribute2     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2;
END xx_hr_asg_conversion_pkg; 
/
