DROP PACKAGE BODY APPS.XX_HR_ASG_CNV_VALIDATIONS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_ASG_CNV_VALIDATIONS_PKG" 
AS
  ----------------------------------------------------------------------
  /*
 Created By    : IBM Development
 Creation Date : 27-Dec-2007
 File Name     : XXHRASGVAL.pkb
 Description   : This script creates the body of the package
         xx_hr_asg_cnv_validations_pkg
 Change History:
 Date         Name            Remarks
 -----------  -------------   -----------------------------------
 27-Dec-2007  Rohit Jain      IBM Development
 25-Jan-2012  Deepika Jain    Modified for Integra
 09-MAY-2012  Arjun K.        IF condition added for concat segments since acct_seg9
                              is optional column
 04-JUN-2012  Arjun K.        Changed the check condition for concat segments
                              and legder/sob_name post CRP3 since it is optional
 22-JUN-2012  Arjun K.        Added get_segment5 function call for shift validation
                              during Pre-SIT
 09-NOV-2012  Arjun K.        called get_person_id function for timecard approver validation
                              post PROD.
 11-APR-2013  Jagdish B       fnd_flex_ext.get_ccid function Passded Date paramete using fnd_canonical.
 */
  --------------------------------------------------------------------------------
  ---------------------------< find_max >---------------------------------
  --------------------------------------------------------------------------------
   FUNCTION find_max (p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2)
      RETURN VARCHAR2
   IS
      x_return_value   VARCHAR2 (100);
   BEGIN
      x_return_value :=
                   xx_intg_common_pkg.find_max (p_error_code1, p_error_code2);
      RETURN x_return_value;
   END find_max;

--------------------------------------------------------------------------------
---------------------------< pre_validations >---------------------------------
--------------------------------------------------------------------------------
   FUNCTION pre_validations (
      p_cnv_hdr_rec   IN OUT NOCOPY   xx_hr_asg_conversion_pkg.g_xx_asg_cnv_pre_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Pre-Validations');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
   END pre_validations;

--------------------------------------------------------------------------------
---------------------------< data_validations >---------------------------------
--------------------------------------------------------------------------------
   FUNCTION data_validations (
      p_cnv_hdr_rec   IN OUT NOCOPY   xx_hr_asg_conversion_pkg.g_xx_asg_cnv_pre_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

      FUNCTION cmp_effdate_hiredate (
         p_effective_start_date   IN   DATE,
         p_hire_date              IN   DATE
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_effective_start_date < p_hire_date
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'p_effective_start_date < p_hire_date'
                                 );
            xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => 'EFF_DATE-DV01',
                      p_error_text               =>    'E:'
                                                    || 'Effective Date greater than Hire Date',
                      p_record_identifier_1      => p_cnv_hdr_rec.employee_number,
                      p_record_identifier_2      => p_cnv_hdr_rec.first_name,
                      p_record_identifier_3      => p_cnv_hdr_rec.last_name,
                      p_record_identifier_4      => p_cnv_hdr_rec.LOCATION,
                      p_record_identifier_5      =>    p_effective_start_date
                                                    || ' > '
                                                    || p_hire_date
                     );
         ELSE
            x_error_code := xx_emf_cn_pkg.cn_success;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => 'EFF_DATE-DV01',
                p_error_text               =>    'E:'
                                              || 'Other Error Effective Date greater than Hire Date',
                p_record_identifier_1      => p_cnv_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_hdr_rec.LOCATION,
                p_record_identifier_5      =>    p_effective_start_date
                                              || ' > '
                                              || p_hire_date
               );
            RETURN x_error_code;
      END cmp_effdate_hiredate;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Data-Validations');
      x_error_code_temp :=
         cmp_effdate_hiredate (p_cnv_hdr_rec.effective_start_date,
                               p_cnv_hdr_rec.hire_date
                              );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.propagate_error (x_error_code_temp);
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
   END data_validations;

--------------------------------------------------------------------------------
---------------------------< post_validations >---------------------------------
--------------------------------------------------------------------------------
   FUNCTION post_validations
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Post-Validations');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
   END post_validations;

--------------------------------------------------------------------------------
---------------------------< data_derivations >---------------------------------
--------------------------------------------------------------------------------
   FUNCTION data_derivations (
      p_cnv_pre_std_hdr_rec   IN OUT NOCOPY   xx_hr_asg_conversion_pkg.g_xx_asg_cnv_pre_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code           NUMBER         := xx_emf_cn_pkg.cn_success;
      x_error_code_temp      NUMBER         := xx_emf_cn_pkg.cn_success;
      x_country_code         VARCHAR2 (200) := NULL;
      x_position             VARCHAR2 (400);
      x_leg_seg_delimiter1   VARCHAR (1)    := '-';
      x_leg_seg_delimiter2   VARCHAR (1)    := '.';
      x_flex_code            VARCHAR2 (10);
      x_flex_num             NUMBER (10);
      x_appl_name            VARCHAR2 (10);
      x_ccid                 NUMBER (20);

-- ******************************************************************************
--                           Function to get_target_business_group_id
-- ******************************************************************************
      FUNCTION get_target_business_group_id (
         p_business_group_name   IN              VARCHAR2,
         p_business_group_id     OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_bg_id        VARCHAR2 (40);
      BEGIN
         p_business_group_id := NULL;

         SELECT pbg.business_group_id
           INTO p_business_group_id
           FROM per_business_groups pbg
          WHERE UPPER (pbg.NAME) =
                   UPPER
                      (p_business_group_name)
-- commented for integra upper(xx_hr_common_pkg.get_mapping_value('BUSINESS_GROUP',p_business_group_name))
            AND TRUNC (SYSDATE) BETWEEN date_from AND NVL (date_to, SYSDATE);

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                p_error_text               =>    'E:'
                                              || xx_emf_cn_pkg.cn_business_grp_toomany,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_business_group_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                p_error_text               =>    'E:'
                                              || xx_emf_cn_pkg.cn_busigrp_nodta_fnd,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_business_group_name
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                p_error_text               =>    'E:'
                                              || xx_emf_cn_pkg.cn_business_grp_invalid,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_business_group_name
               );
            RETURN x_error_code;
      END get_target_business_group_id;

--*****************************************************************************
--- Function to get change reason
---****************************************************************************
      FUNCTION is_change_reason_valid (p_change_reason IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER         := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (150);
      BEGIN
         BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'p_change_reason ' || p_change_reason
                                 );

            IF p_change_reason IS NOT NULL
            THEN
               SELECT lookup_code
                 INTO x_variable
                 FROM fnd_lookup_values
                WHERE UPPER (meaning) =
                                   UPPER (p_cnv_pre_std_hdr_rec.change_reason)
                  AND LANGUAGE = USERENV ('LANG')
                  AND UPPER (lookup_type) = UPPER (g_change_reason_type)
                  AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                  AND NVL (end_date_active, SYSDATE);

               p_change_reason := x_variable;
            ELSE
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
            END IF;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.cn_title_valid,
                      p_error_text               => xx_emf_cn_pkg.cn_title_toomany,
                      p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                      p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                      p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                      p_record_identifier_4      => p_change_reason
                     );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.cn_title_valid,
                      p_error_text               => xx_emf_cn_pkg.cn_title_ndtfound,
                      p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                      p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                      p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                      p_record_identifier_4      => p_change_reason
                     );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.cn_title_valid,
                      p_error_text               => xx_emf_cn_pkg.cn_title_invalid,
                      p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                      p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                      p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                      p_record_identifier_4      => p_change_reason
                     );
         END;

         RETURN x_error_code;
      END is_change_reason_valid;

-- ******************************************************************************
--                           Function to get_target_job_id
-- ******************************************************************************
      FUNCTION get_target_job_id (
         p_job_name            IN              VARCHAR2,
         p_business_group_id   IN              NUMBER,
         p_job_id              OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         x_job_id       NUMBER;
      BEGIN
         IF p_job_name IS NOT NULL
         THEN
            SELECT job_id
              INTO p_job_id
              FROM per_jobs
             WHERE UPPER (NAME) =
                      UPPER
                         (p_job_name)
 -- commented for integra xx_hr_common_pkg.get_mapping_value('JOB',p_job_name)
               AND business_group_id = p_business_group_id;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, ' FOUND JOB ID ');
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_job_valid,
                p_error_text               => 'E: Too Many Rows - Job',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_job_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_job_valid,
                p_error_text               => 'E: No Data Found - Job',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_job_name
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_job_valid,
                p_error_text               => 'E: Job' || SQLERRM,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_job_name
               );
            RETURN x_error_code;
      END get_target_job_id;

--
-- ******************************************************************************
--                           Function to get_target_grade_id
-- ******************************************************************************
      FUNCTION get_target_grade_id (
         p_grade_name          IN              VARCHAR2,
         p_business_group_id   IN              NUMBER,
         p_grade_id            OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         -- p_grade_id := NULL;
         IF p_grade_name IS NOT NULL
         THEN
            SELECT grade_id
              INTO p_grade_id
              FROM per_grades
                         --Change by rojain on 09-Jan-2008 as new mapping came
             WHERE UPPER (NAME) =
                      UPPER
                         (p_grade_name)
-- commented for integra xx_hr_common_pkg.get_mapping_value('GRADE',   p_grade_name)
               AND business_group_id = p_business_group_id;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_grade_valid,
                p_error_text               =>    'W:'
                                              || xx_emf_cn_pkg.cn_grade_toomany,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_grade_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_grade_valid,
                p_error_text               =>    'W:'
                                              || xx_emf_cn_pkg.cn_grade_nodata,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_grade_name
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_grade_valid,
                p_error_text               =>    'W:'
                                              || xx_emf_cn_pkg.cn_grade_invalid,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_grade_name
               );
            RETURN x_error_code;
      END get_target_grade_id;

-- ******************************************************************************
--                           Function to get_target_position_id
-- ******************************************************************************
      FUNCTION get_target_position_id (
         p_position_name   IN              VARCHAR2,
         p_position_id     OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         p_position_id := NULL;

         IF p_position_name IS NOT NULL
         THEN
            SELECT position_id
              INTO p_position_id
              FROM per_positions
             WHERE UPPER (NAME) = UPPER (p_position_name);
-- commented for integra xx_hr_common_pkg.get_mapping_value('POSITION',   p_position_name);
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_position_valid,
                p_error_text               =>    'W:'
                                              || xx_emf_cn_pkg.cn_position_toomany,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_position_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_position_valid,
                p_error_text               =>    'W:'
                                              || xx_emf_cn_pkg.cn_position_nodata,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_position_name
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_position_valid,
                p_error_text               =>    'W:'
                                              || xx_emf_cn_pkg.cn_position_invalid,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_position_name
               );
            RETURN x_error_code;
      END get_target_position_id;

-- ******************************************************************************
--                           Function to get_target_location_id
-- ******************************************************************************
      FUNCTION get_target_location_id (
         p_location_name   IN              VARCHAR2,
         p_location_id     OUT NOCOPY      NUMBER,
         p_country_code    OUT NOCOPY      VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         p_location_id := NULL;

         IF p_location_name IS NOT NULL
         THEN
            SELECT location_id, country
              INTO p_location_id, p_country_code
              FROM hr_locations_all
             WHERE TRIM (UPPER (location_code)) =
                      TRIM
                         (UPPER (p_location_name))
-- commented for integra TRIM(UPPER(xx_hr_common_pkg.get_mapping_value('LOCATION',   p_location_name)))
               AND ROWNUM = 1;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_location_valid,
                p_error_text               =>    'W:'
                                              || xx_emf_cn_pkg.cn_location_toomany,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_location_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_location_valid,
                p_error_text               =>    'W:'
                                              || xx_emf_cn_pkg.cn_location_nodata,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_location_name
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_location_valid,
                p_error_text               =>    'W:'
                                              || xx_emf_cn_pkg.cn_location_invalid,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_location_name
               );
            RETURN x_error_code;
      END get_target_location_id;

-- ******************************************************************************
--                           Function to get_target_assignment_status_id
-- ******************************************************************************
      FUNCTION get_target_assign_status_id (
         p_asg_status           IN              VARCHAR2,
         p_asg_status_type_id   OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_asg_status   VARCHAR2 (80) := NULL;
      BEGIN
         p_asg_status_type_id := NULL;

         IF p_asg_status IS NOT NULL
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  '  ASSIGNMENT STATUS NOT NULL'
                                 );

            BEGIN
               SELECT assignment_status_type_id
                 INTO p_asg_status_type_id
                 FROM per_assignment_status_types
                WHERE UPPER (user_status) =
                         UPPER
                            (p_asg_status)
-- commented for integra UPPER(xx_hr_common_pkg.get_mapping_value('ASSIGNMENT_STATUS',p_asg_status))
                  AND active_flag = 'Y';

               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     '  ASSIGNMENT STATUS NOT NULL'
                                    );
            EXCEPTION
               WHEN TOO_MANY_ROWS
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.cn_assignment_status_valid,
                      p_error_text               =>    'W:'
                                                    || xx_emf_cn_pkg.cn_assignment_status_tomny,
                      p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                      p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                      p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                      p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                      p_record_identifier_5      => p_asg_status
                     );
                  RETURN x_error_code;
               WHEN NO_DATA_FOUND
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        '  ASSIGNMENT STATUS NOT FOUND'
                                       );
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.cn_assignment_status_valid,
                      p_error_text               =>    'W:'
                                                    || xx_emf_cn_pkg.cn_assignment_status_nodata,
                      p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                      p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                      p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                      p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                      p_record_identifier_5      => p_asg_status
                     );
                  RETURN x_error_code;
               WHEN OTHERS
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.cn_assignment_status_valid,
                      p_error_text               =>    'W:'
                                                    || xx_emf_cn_pkg.cn_assignment_status_invalid,
                      p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                      p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                      p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                      p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                      p_record_identifier_5      => p_asg_status
                     );
                  RETURN x_error_code;
            END;
         ELSE
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_assignment_status_valid,
                p_error_text               =>    'W:'
                                              || xx_emf_cn_pkg.cn_assignment_status_miss,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_asg_status
               );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  '  ASSIGNMENT STATUS NULL'
                                 );
         END IF;

         RETURN x_error_code;
      END get_target_assign_status_id;

-- ******************************************************************************
--                           Function to get_target_salary_basis_id
-- ******************************************************************************
      FUNCTION get_target_salary_basis_id (
         p_pay_name            IN              VARCHAR2,
         p_business_group_id   IN              NUMBER,
         p_pay_basis_id        OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         p_pay_basis_id := NULL;

         IF p_pay_name IS NOT NULL
         THEN
            SELECT pay_basis_id
              INTO p_pay_basis_id
              FROM per_pay_bases
                         --Change by rojain on 09-Jan-2008 as new mapping came
             WHERE UPPER (NAME) =
                      UPPER
                         (p_pay_name)
-- commented for integra xx_hr_common_pkg.get_mapping_value('PAY_BASIS',   p_pay_name)
               AND business_group_id = p_business_group_id;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_salary_basis_valid,
                p_error_text               =>    'W:'
                                              || xx_emf_cn_pkg.cn_salary_basis_id_toomany,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_pay_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_salary_basis_valid,
                p_error_text               =>    'W:'
                                              || xx_emf_cn_pkg.cn_salary_basis_id_nodata,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_pay_name
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_salary_basis_valid,
                p_error_text               =>    'W:'
                                              || xx_emf_cn_pkg.cn_salary_basis_id_invalid,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_pay_name
               );
            RETURN x_error_code;
      END get_target_salary_basis_id;

-- ******************************************************************************
--                           Function to get_target_payroll_id
-- ******************************************************************************
      FUNCTION get_target_payroll_id (
         p_payroll_name   IN              VARCHAR2,
         p_person_id      IN              NUMBER,
         p_bus_grp_id     IN              NUMBER,
         p_payroll_id     OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         x_address_id   NUMBER := NULL;
      BEGIN
         p_payroll_id := NULL;

         IF p_payroll_name IS NOT NULL
         THEN
            SELECT payroll_id
              INTO p_payroll_id
              FROM pay_all_payrolls_f
             WHERE UPPER (payroll_name) =
                      UPPER
                         (p_payroll_name)
-- commented for integra xx_hr_common_pkg.get_mapping_value('PAYROLL_NAME',   p_payroll_name)
               AND business_group_id = p_bus_grp_id
               AND EXISTS (
                      SELECT 1
                        FROM per_addresses
                       WHERE person_id = p_person_id
                         AND primary_flag = 'Y'
                         AND business_group_id = p_bus_grp_id);
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_payroll_valid,
                p_error_text               =>    'E:'
                                              || xx_emf_cn_pkg.cn_payroll_id_toomany,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_payroll_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_payroll_valid,
                p_error_text               =>    'E:'
                                              || xx_emf_cn_pkg.cn_payroll_id_nodata,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_payroll_name
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_payroll_valid,
                p_error_text               =>    'E:'
                                              || xx_emf_cn_pkg.cn_payroll_id_invalid,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_payroll_name
               );
            RETURN x_error_code;
      END get_target_payroll_id;

-- ******************************************************************************
--                           Function to get_target_organization_id
-- ******************************************************************************
      FUNCTION get_target_organization_id (
         p_org_name            IN              VARCHAR2,
         p_country_code        IN              VARCHAR2,
         p_business_group_id   IN              NUMBER,
         p_organization_id     OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         p_organization_id := NULL;

         IF p_org_name IS NOT NULL
         THEN
            SELECT organization_id
              INTO p_organization_id
              FROM hr_all_organization_units
             WHERE UPPER (NAME) =
                      UPPER
                         (p_org_name)
-- commented for integra xx_hr_asg_conversion_pkg.get_org_mapping_value('ORGANIZATION', p_org_name, p_country_code, null)
               AND business_group_id = p_business_group_id;
         ELSE
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            p_organization_id := NULL;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_organization_valid,
                p_error_text               =>    'E:'
                                              || xx_emf_cn_pkg.cn_organization_id_miss,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_org_name
               );
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_organization_valid,
                p_error_text               =>    'E:'
                                              || xx_emf_cn_pkg.cn_organization_id_toomany,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_org_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_organization_valid,
                p_error_text               =>    'E:'
                                              || xx_emf_cn_pkg.cn_organization_id_nodata,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_org_name
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_organization_valid,
                p_error_text               =>    'E:'
                                              || xx_emf_cn_pkg.cn_organization_id_invalid,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_org_name
               );
            RETURN x_error_code;
      END get_target_organization_id;

-- ******************************************************************************
--                           Function to Get Target Person Id
-- ******************************************************************************
      FUNCTION get_target_person_id (
         p_unique_id           IN              VARCHAR2,
         p_business_group_id   IN              NUMBER,
         p_person_id           OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_bg_id        VARCHAR2 (40);

         CURSOR c_person_details (
            x_unique_id           IN   VARCHAR2,
            x_business_group_id   IN   VARCHAR2
         )
         IS
            SELECT   ppf.person_id
                FROM per_all_people_f ppf
               WHERE ppf.attribute1 = x_unique_id
                 AND ppf.business_group_id = x_business_group_id
                 AND TRUNC (SYSDATE) BETWEEN ppf.effective_start_date
                                         AND ppf.effective_end_date
            ORDER BY ppf.effective_start_date;
      BEGIN
         p_person_id := NULL;

         IF p_unique_id IS NOT NULL
         THEN
            FOR r_person_details IN c_person_details (p_unique_id,
                                                      p_business_group_id
                                                     )
            LOOP
               p_person_id := r_person_details.person_id;
            END LOOP;
         ELSE
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
         /*xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                          p_category => xx_emf_cn_pkg.cn_person_valid,
                          p_error_text => 'E:'||'Test',--xx_emf_cn_pkg.cn_person_miss,
              p_record_identifier_1 => p_cnv_pre_std_hdr_rec.employee_number,
              p_record_identifier_2 => p_cnv_pre_std_hdr_rec.first_name,
              p_record_identifier_3 => p_cnv_pre_std_hdr_rec.last_name,
              p_record_identifier_4 => p_cnv_pre_std_hdr_rec.location,
              p_record_identifier_5 => p_unique_id);*/
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            RETURN x_error_code;
      END get_target_person_id;

-- ******************************************************************************
--                           Function to Get Segment1 for GOV_REP_ENTITY
-- ******************************************************************************
      FUNCTION get_segment1(
         p_gre_name            IN OUT       VARCHAR2,
         p_business_group_id   IN           NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_gre_name IS NOT NULL
         THEN
            BEGIN
               SELECT haou.organization_id
                 INTO p_gre_name
                 FROM hr_all_organization_units haou
                WHERE haou.NAME = p_gre_name
                  AND haou.business_group_id = p_business_group_id
                  AND TRUNC (SYSDATE) BETWEEN haou.date_from
                                          AND NVL (date_to,
                                                   TO_DATE ('4712/12/31',
                                                            'YYYY/MM/DD'
                                                           )
                                                  );
            EXCEPTION
               WHEN TOO_MANY_ROWS
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  p_gre_name   := NULL;
                  RETURN x_error_code;
               WHEN NO_DATA_FOUND
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  p_gre_name   := NULL;
                  RETURN x_error_code;
               WHEN OTHERS
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  p_gre_name   := NULL;
                  RETURN x_error_code;
            END;
         ELSE
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            p_gre_name   := NULL;
            RETURN x_error_code;
      END get_segment1;

-- Added function during Pre-SIT for shift validation on 22-JUN-2012
-- ******************************************************************************
--                           Function to Get Segment5 for SHIFT_US
-- ******************************************************************************
      FUNCTION get_segment5 (p_shift_us           IN OUT NOCOPY   VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         BEGIN
            SELECT lookup_code
              INTO p_shift_us
          FROM hr_lookups hl
              ,fnd_application fa
         WHERE hl.lookup_type = 'US_SHIFTS'
           AND hl.enabled_flag = 'Y'
           AND fa.application_id = hl.application_id
           AND fa.application_short_name = 'PER'
               AND meaning = p_shift_us;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               p_shift_us   := NULL;
               RETURN x_error_code;
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               p_shift_us   := NULL;
               RETURN x_error_code;
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               p_shift_us   := NULL;
               RETURN x_error_code;
         END;
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            p_shift_us   := NULL;
            RETURN x_error_code;
      END get_segment5;

-- ******************************************************************************
--                           Function to Get Target Supervisor Id
-- ******************************************************************************
      FUNCTION get_target_supervisor_id (
         p_supervisor_unique_id   IN              VARCHAR2,
         p_business_group_id      IN              NUMBER,
         p_supervisor_id          OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_bg_id        VARCHAR2 (40);
      BEGIN
         p_supervisor_id := NULL;

         IF (p_supervisor_unique_id IS NOT NULL)
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' Validate Supervisor'
                                 );

            SELECT ppf.person_id
              INTO p_supervisor_id
              FROM per_all_people_f ppf
             WHERE ppf.attribute1 = p_supervisor_unique_id
               AND TRUNC (SYSDATE) BETWEEN ppf.effective_start_date
                                       AND ppf.effective_end_date;
         --AND business_group_id=p_business_group_id
         /* This business group is commented because Supervisor can be present in any business group
         As per discussion with Raj Bugga*/
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_supervisor_valid,
                p_error_text               =>    'W:'
                                              || xx_emf_cn_pkg.cn_supervisor_toomany,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_supervisor_unique_id
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_supervisor_valid,
                p_error_text               =>    'W:'
                                              || xx_emf_cn_pkg.cn_supervisor_nodata,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_supervisor_unique_id
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_supervisor_valid,
                p_error_text               =>    'W:'
                                              || xx_emf_cn_pkg.cn_supervisor_invalid,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_supervisor_unique_id
               );
            RETURN x_error_code;
      END get_target_supervisor_id;

-- ******************************************************************************
    --                           Function to get_emp_catg
    -- ******************************************************************************
      FUNCTION get_emp_catg (p_emp_catg IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_emp_catg     VARCHAR2 (30);
      BEGIN
         IF p_emp_catg IS NOT NULL
         THEN
            SELECT lookup_code
              INTO x_emp_catg
              FROM fnd_lookup_values
             WHERE meaning =
                      TRIM
                         (p_emp_catg)
-- commented for integra trim(xx_hr_common_pkg.get_mapping_value('EMP_CAT',  p_emp_catg))
               AND lookup_type = 'EMPLOYEE_CATG'
               AND LANGUAGE = USERENV ('LANG')
               AND enabled_flag = 'Y';

            p_emp_catg := x_emp_catg;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => 'EMPCATG-DV01',
                p_error_text               =>    'E:'
                                              || 'Too Many Employee Categories Found',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_emp_catg
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => 'EMPCATG-DV01',
                p_error_text               =>    'E:'
                                              || 'No Employee Category found',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_emp_catg
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => 'EMPCATG-DV01',
                p_error_text               =>    'E:'
                                              || 'Invalid Employee Category',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_emp_catg
               );
            RETURN x_error_code;
      END get_emp_catg;

-- ******************************************************************************
    --                           Function to get_asg_catg
    -- ******************************************************************************
      FUNCTION get_asg_catg (p_asg_catg IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_asg_catg     VARCHAR2 (30);
      BEGIN
         IF p_asg_catg IS NOT NULL
         THEN
            SELECT lookup_code
              INTO x_asg_catg
              FROM fnd_lookup_values
             WHERE meaning =
                      TRIM
                         (p_asg_catg)
-- commented for integra trim(xx_hr_common_pkg.get_mapping_value('ASG_CAT',  p_asg_catg))
               AND lookup_type = 'EMP_CAT'
               AND LANGUAGE = USERENV ('LANG')
               AND enabled_flag = 'Y';

            p_asg_catg := x_asg_catg;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => 'ASGCATG-DV01',
                p_error_text               =>    'E:'
                                              || 'Too Many Assignment Categories Found',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_asg_catg
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => 'ASGCATG-DV01',
                p_error_text               =>    'E:'
                                              || 'No Assignment Category found',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_asg_catg
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => 'ASGCATG-DV01',
                p_error_text               =>    'E:'
                                              || 'Invalid Assignment Category',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_asg_catg
               );
            RETURN x_error_code;
      END get_asg_catg;

-- ******************************************************************************
--                           Function to get_position_id
-- ******************************************************************************
      FUNCTION get_position_id (
         p_pos_title           IN              VARCHAR2,
         p_business_group_id   IN              NUMBER,
         p_position_id         OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_pos_title IS NOT NULL
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' Position =  ' || p_pos_title
                                 );

            SELECT position_id
              INTO p_position_id
              FROM per_positions
             WHERE UPPER (NAME) = UPPER (p_pos_title)
               /*SUBSTR(name,1,(INSTR(name,'.')-1)) = p_pos_code
               AND SUBSTR(name,(INSTR(name,'.')+1))=p_pos_title     commented for integra */
               AND business_group_id = p_business_group_id;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' Position ID =  ' || p_position_id
                                 );
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' X_ERROR_CODE =  ' || x_error_code
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => 'POS-DV01',
                p_error_text               =>    'E:'
                                              || 'Too Many Positions Found',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_pos_title
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => 'POS-DV01',
                p_error_text               => 'E:' || 'No position found',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_pos_title
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => 'POS-DV01',
                p_error_text               => 'E:' || 'Invalid Position',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_pos_title
               );
            RETURN x_error_code;
      END get_position_id;
   BEGIN
      x_error_code_temp :=
         get_target_business_group_id
                                  (p_cnv_pre_std_hdr_rec.business_group_name,
                                   p_cnv_pre_std_hdr_rec.business_group_id
                                  );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, ' Business Group Derived ');
      x_country_code := NULL;
      x_error_code_temp :=
         get_target_person_id (p_cnv_pre_std_hdr_rec.person_unique_id,
                               p_cnv_pre_std_hdr_rec.business_group_id,
                               p_cnv_pre_std_hdr_rec.person_id
                              );
      x_error_code := find_max (x_error_code, x_error_code_temp);

      IF p_cnv_pre_std_hdr_rec.person_id IS NULL
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Person ID not Derived');
         xx_emf_pkg.error
             (p_severity                 => xx_emf_cn_pkg.cn_low,
              p_category                 => xx_emf_cn_pkg.cn_person_valid,
              p_error_text               => 'E:' || 'Person is missing',
              p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
              p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
              p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
              p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
              p_record_identifier_5      => p_cnv_pre_std_hdr_rec.person_unique_id
             );
      ELSE
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Person ID Derived');
      END IF;

      x_error_code_temp :=
         get_target_supervisor_id (p_cnv_pre_std_hdr_rec.supervisor_unique_id,
                                   p_cnv_pre_std_hdr_rec.business_group_id,
                                   p_cnv_pre_std_hdr_rec.supervisor_id
                                  );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Supervisor  Derived');
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Supervisor x_error_code: ' || x_error_code
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Supervisor x_error_code_temp: '
                            || x_error_code_temp
                           );
      x_error_code_temp :=
         get_target_job_id (p_cnv_pre_std_hdr_rec.job_name,
                            p_cnv_pre_std_hdr_rec.business_group_id,
                            p_cnv_pre_std_hdr_rec.job_id
                           );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Job Derived');
      x_error_code_temp :=
                  is_change_reason_valid (p_cnv_pre_std_hdr_rec.change_reason);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Change Reason Derived');
      x_error_code_temp :=
         get_target_grade_id (p_cnv_pre_std_hdr_rec.grade_name,
                              p_cnv_pre_std_hdr_rec.business_group_id,
                              p_cnv_pre_std_hdr_rec.grade_id
                             );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Grade  Derived');
      x_error_code_temp :=
         get_target_location_id
                    (p_location_name      => p_cnv_pre_std_hdr_rec.LOCATION
                                                                         -- in
                                                                           ,
                     p_location_id        => p_cnv_pre_std_hdr_rec.location_id
                                                                        -- out
                                                                              ,
                     p_country_code       => x_country_code             -- out
                    );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, ' Location  Derived ');
      x_error_code_temp :=
         get_target_assign_status_id
                              (p_cnv_pre_std_hdr_rec.assignment_status,
                               p_cnv_pre_std_hdr_rec.assignment_status_type_id
                              );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' Assignment Status  id for '
                            || p_cnv_pre_std_hdr_rec.assignment_status
                            || 'Derived is '
                            || p_cnv_pre_std_hdr_rec.assignment_status_type_id
                           );
      x_error_code_temp :=
         get_target_salary_basis_id (p_cnv_pre_std_hdr_rec.salary_basis,
                                     p_cnv_pre_std_hdr_rec.business_group_id,
                                     p_cnv_pre_std_hdr_rec.pay_basis_id
                                    );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, ' Pay Basis Derived ');
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' Person ID '
                            || p_cnv_pre_std_hdr_rec.person_id
                            || ' Business Group ID '
                            || p_cnv_pre_std_hdr_rec.business_group_id
                           );
      x_error_code_temp :=
         get_target_payroll_id (p_cnv_pre_std_hdr_rec.payroll_name,
                                p_cnv_pre_std_hdr_rec.person_id,
                                p_cnv_pre_std_hdr_rec.business_group_id,
                                p_cnv_pre_std_hdr_rec.payroll_id
                               );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, ' Payroll  Derived ');
      x_error_code_temp :=
         get_target_organization_id
            (p_org_name               => p_cnv_pre_std_hdr_rec.ORGANIZATION
                                                                         -- in
                                                                           ,
             p_country_code           => x_country_code                  -- in
                                                       ,
             p_business_group_id      => p_cnv_pre_std_hdr_rec.business_group_id
                                                                         -- in
                                                                                ,
             p_organization_id        => p_cnv_pre_std_hdr_rec.organization_id
                                                                        -- out
            );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, ' Org  Derived ');
          /*x_error_code_temp := get_target_tax_unit_id(p_cnv_pre_std_hdr_rec.gre_name,
                                                 p_cnv_pre_std_hdr_rec.tax_unit_id); */
          --x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );
      --xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' GRE  Derived ' );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' Employee Category '
                            || p_cnv_pre_std_hdr_rec.employee_category
                           );
      x_error_code_temp :=
         get_emp_catg
               (p_emp_catg      => p_cnv_pre_std_hdr_rec.employee_category
                                                                     -- in out
                                                                          );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' Employee Category  Derived '
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' Assignment Category '
                            || p_cnv_pre_std_hdr_rec.employment_category
                           );
      x_error_code_temp :=
         get_asg_catg
             (p_asg_catg      => p_cnv_pre_std_hdr_rec.assignment_category
                                                                     -- in out
                                                                          );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' Assignment Category  Derived '
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' Position '
                            || p_cnv_pre_std_hdr_rec.pos_code
                            || ' '
                            || p_cnv_pre_std_hdr_rec.pos_title
                           );
      x_error_code_temp :=
         get_position_id
              (p_pos_title              => p_cnv_pre_std_hdr_rec.pos_title
                                                                         -- IN
                                                                          ,
               p_business_group_id      => p_cnv_pre_std_hdr_rec.business_group_id,
               p_position_id            => p_cnv_pre_std_hdr_rec.position_id
              );

      -- additions for integra - start
      IF p_cnv_pre_std_hdr_rec.ass_attribute1 IS NOT NULL
      THEN
         x_error_code_temp :=
            get_target_person_id (p_cnv_pre_std_hdr_rec.ass_attribute1,
                                  p_cnv_pre_std_hdr_rec.business_group_id,
                                  p_cnv_pre_std_hdr_rec.hr_rep_id
                                 );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'HR Rep Derived');

         IF p_cnv_pre_std_hdr_rec.hr_rep_id IS NULL
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'HR Rep Not Derived');
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_person_valid,
                p_error_text               =>    'E:'
                                              || 'HR Representative is missing',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_cnv_pre_std_hdr_rec.person_unique_id
               );
         ELSE
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'HR Rep is Derived');
         END IF;
      END IF;

      IF p_cnv_pre_std_hdr_rec.ass_attribute2 IS NOT NULL
      THEN
         x_error_code_temp :=
            get_target_person_id (p_cnv_pre_std_hdr_rec.ass_attribute2,
                                  p_cnv_pre_std_hdr_rec.business_group_id,
                                  p_cnv_pre_std_hdr_rec.hr_director_id
                                 );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'HR Director Derived');

         IF p_cnv_pre_std_hdr_rec.hr_director_id IS NULL
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'HR Director Not Derived'
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_person_valid,
                p_error_text               => 'E:' || 'HR Director is missing',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                p_record_identifier_5      => p_cnv_pre_std_hdr_rec.person_unique_id
               );
         ELSE
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'HR Director is Derived'
                                 );
         END IF;
      END IF;


      IF UPPER (p_cnv_pre_std_hdr_rec.country) = 'US'
      THEN
         --function call for gre_name
         x_error_code_temp :=
            get_segment1 (p_cnv_pre_std_hdr_rec.gov_rep_entity,
                          p_cnv_pre_std_hdr_rec.business_group_id
                         );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Govt Rep Entity is Derived'
                              );

         IF p_cnv_pre_std_hdr_rec.gov_rep_entity IS NULL
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Govt Rep Entity Not Missing/Not Derived'
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => 'GRE-DV01',
                p_error_text               =>    'E:'
                                              || 'Govt Rep Entity is Missing/Not Derived',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION
               );
         ELSE
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Govt Rep Entity is Derived'
                                 );
         END IF;

         IF p_cnv_pre_std_hdr_rec.shift_us IS NOT NULL
         THEN
            -- Added function call during Pre-SIT for shift validation on 22-JUN-2012
            --function call for shift_us
            x_error_code_temp :=
               get_segment5 (p_cnv_pre_std_hdr_rec.shift_us);
            x_error_code := find_max (x_error_code, x_error_code_temp);
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Shift(US) value is Derived'
                                 );

            IF p_cnv_pre_std_hdr_rec.shift_us IS NULL
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Shift(US) value Missing/Not Derived'
                                    );
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => 'SFT-DV02',
                   p_error_text               =>    'E:'
                                                 || 'Shift(US) value Missing/Not Derived',
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION
                  );
            END IF;
         END IF;

         IF p_cnv_pre_std_hdr_rec.timecard_approver_us IS NOT NULL
         THEN
            -- Added function call post PROD for Timecard approver validation on 09-NOV-2012
            --function call for timecard_approver_us
            x_error_code_temp :=
               get_target_person_id (p_cnv_pre_std_hdr_rec.timecard_approver_us,
                                     p_cnv_pre_std_hdr_rec.business_group_id,
                                     p_cnv_pre_std_hdr_rec.timecard_approver_us
                                    );
            x_error_code := find_max (x_error_code, x_error_code_temp);
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Timecard Approver(US) value is Derived'
                                 );

            IF p_cnv_pre_std_hdr_rec.timecard_approver_us IS NULL
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Timecard Approver(US) value Missing/Not Derived'
                                    );
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => 'TCA-DV02',
                   p_error_text               =>    'E:'
                                                 || 'Timecard Approver(US) value Missing/Not Derived',
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION
                  );
            END IF;
         END IF;

      END IF;

      -- additions for integra - end
      IF p_cnv_pre_std_hdr_rec.sob_name IS NOT NULL
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' Set Of Books '
                               || p_cnv_pre_std_hdr_rec.sob_name
                              );
         x_error_code_temp :=
            xx_intg_common_pkg.get_new_sob
                                  (p_cnv_pre_std_hdr_rec.sob_name        -- IN
                                                                 ,
                                   p_cnv_pre_std_hdr_rec.set_of_books_id
                                                                        -- OUT
                                  );
         x_error_code := find_max (x_error_code, x_error_code_temp);

         IF p_cnv_pre_std_hdr_rec.set_of_books_id IS NULL
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'SOB ID Not  Derived');
            xx_emf_pkg.error
                (p_severity                 => xx_emf_cn_pkg.cn_low,
                 p_category                 => 'SOB-DV01',
                 p_error_text               => 'E:' || 'Set Of Books Not Found',
                 p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                 p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                 p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                 p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                 p_record_identifier_5      => p_cnv_pre_std_hdr_rec.sob_name
                );
         ELSE
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'SOB ID  Derived');
         END IF;
      END IF;--Changed post CRP3 04-JUN-2012 since ledger/sob_name is optional
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' Get Account ' || p_cnv_pre_std_hdr_rec.sob_name
                           );
       --Changed post CRP3 04-JUN-2012 to check if the concat segments are null
      p_cnv_pre_std_hdr_rec.concat_segs :=
            p_cnv_pre_std_hdr_rec.acct_seg1
         || p_cnv_pre_std_hdr_rec.acct_seg2
         || p_cnv_pre_std_hdr_rec.acct_seg3
         || p_cnv_pre_std_hdr_rec.acct_seg4
         || p_cnv_pre_std_hdr_rec.acct_seg5
         || p_cnv_pre_std_hdr_rec.acct_seg6
         || p_cnv_pre_std_hdr_rec.acct_seg7
         || p_cnv_pre_std_hdr_rec.acct_seg8
         || p_cnv_pre_std_hdr_rec.acct_seg9;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            '  Account ' || p_cnv_pre_std_hdr_rec.concat_segs
                           );

      --Changed post CRP3 04-JUN-2012 to make default expense account optional
      IF p_cnv_pre_std_hdr_rec.concat_segs IS NOT NULL
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Account to be Derived for '
                               || p_cnv_pre_std_hdr_rec.concat_segs
                              );

         BEGIN
            SELECT b.id_flex_code, b.id_flex_num,
                   b.concatenated_segment_delimiter, a.application_short_name
              INTO x_flex_code, x_flex_num,
                   x_leg_seg_delimiter1, x_appl_name
              FROM fnd_id_flex_structures b, fnd_application a
             WHERE b.enabled_flag = 'Y'
               AND UPPER (b.id_flex_structure_code) =
                                                     UPPER (g_accounting_flex)
               AND b.application_id = a.application_id
               AND b.dynamic_inserts_allowed_flag = 'Y';

            IF p_cnv_pre_std_hdr_rec.acct_seg9 IS NOT NULL
            THEN                                 -- Added for CRP3 09-MAY-2012
               p_cnv_pre_std_hdr_rec.concat_segs :=
                     p_cnv_pre_std_hdr_rec.acct_seg1
                  || x_leg_seg_delimiter1
                  || p_cnv_pre_std_hdr_rec.acct_seg2
                  || x_leg_seg_delimiter1
                  || p_cnv_pre_std_hdr_rec.acct_seg3
                  || x_leg_seg_delimiter1
                  || p_cnv_pre_std_hdr_rec.acct_seg4
                  || x_leg_seg_delimiter1
                  || p_cnv_pre_std_hdr_rec.acct_seg5
                  || x_leg_seg_delimiter1
                  || p_cnv_pre_std_hdr_rec.acct_seg6
                  || x_leg_seg_delimiter1
                  || p_cnv_pre_std_hdr_rec.acct_seg7
                  || x_leg_seg_delimiter1
                  || p_cnv_pre_std_hdr_rec.acct_seg8
                  || x_leg_seg_delimiter1
                  || p_cnv_pre_std_hdr_rec.acct_seg9;
            ELSE
               p_cnv_pre_std_hdr_rec.concat_segs :=
                     p_cnv_pre_std_hdr_rec.acct_seg1
                  || x_leg_seg_delimiter1
                  || p_cnv_pre_std_hdr_rec.acct_seg2
                  || x_leg_seg_delimiter1
                  || p_cnv_pre_std_hdr_rec.acct_seg3
                  || x_leg_seg_delimiter1
                  || p_cnv_pre_std_hdr_rec.acct_seg4
                  || x_leg_seg_delimiter1
                  || p_cnv_pre_std_hdr_rec.acct_seg5
                  || x_leg_seg_delimiter1
                  || p_cnv_pre_std_hdr_rec.acct_seg6
                  || x_leg_seg_delimiter1
                  || p_cnv_pre_std_hdr_rec.acct_seg7
                  || x_leg_seg_delimiter1
                  || p_cnv_pre_std_hdr_rec.acct_seg8;
            END IF;                              -- Added for CRP3 09-MAY-2012

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'x_appl_name:' || x_appl_name
                                 );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'x_flex_code:' || x_flex_code
                                 );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'x_flex_num:' || x_flex_num
                                 );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'concat_segs:'
                                  || p_cnv_pre_std_hdr_rec.concat_segs
                                 );
            x_ccid :=
               fnd_flex_ext.get_ccid (x_appl_name,
                                      x_flex_code,
                                      x_flex_num,
                                      fnd_date.date_to_canonical(SYSDATE),  -- If existing CCID has start date this function return 0 Oracle Note ID 1275135.1 Jabhosle
                                      p_cnv_pre_std_hdr_rec.concat_segs
                                     );
            p_cnv_pre_std_hdr_rec.default_code_comb_id := x_ccid;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'x_ccid:'
                                  || p_cnv_pre_std_hdr_rec.default_code_comb_id
                                 );
            IF NVL(x_ccid,0) = 0 THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Flex Details Not Derived'
                                    );
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => 'FLEX-DV01',
                   p_error_text               => 'E:'
                                                 || 'Default Expense Account CCID not generated for : '
                                                 ||p_cnv_pre_std_hdr_rec.concat_segs
                                                 || ' Reason :'
                                                 || fnd_message.get,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                   p_record_identifier_5      => 'ACCOUNTING FLEXFIELD'
                  );
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Flex Details Not Derived'
                                    );
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => 'FLEX-DV01',
                   p_error_text               => 'E:'
                                                 || 'ACCOUNTING FLEXFIELD',
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                   p_record_identifier_5      => 'ACCOUNTING FLEXFIELD'
                  );
         END;
      END IF;

      x_error_code := find_max (x_error_code, x_error_code_temp);

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'x_error_code final:' || x_error_code
                           );
      --xx_emf_pkg.propagate_error ( x_error_code_temp );
      RETURN x_error_code;
   END data_derivations;
END xx_hr_asg_cnv_validations_pkg; 
/
