DROP PACKAGE BODY APPS.XX_HR_CWK_ASG_VALIDATION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_CWK_ASG_VALIDATION_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    :IBM Development
 Creation Date : 20-Jan-2011
 File Name     : XXHRCWAVAL.pkb
 Description   : This script creates the body of the package body for
                 xx_hr_cwkasg_cnv_valid_pkg
 Change History:
 Date         Name            Remarks
 -----------  ----------    -----------------------------------
 20-Jan-2011  Suman Sur       IBM Development
 25-Jan-2012  Deepika Jain    Modified for Integra
 04-JUN-2012 Arjun K.         Added validation for default expense account
                              ans sob_name/ledger post CRP3
*/ ----------------------------------------------------------------------

---------------------------< find_max >----------------------------------
-------------------------------------------------------------------------
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
   ----------------------------< pre_validations >---------------------------------
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
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
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

         BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, '1 BG');

            SELECT pbg.business_group_id
              INTO p_business_group_id
              FROM per_business_groups pbg
             WHERE UPPER (pbg.NAME) =
                      UPPER
                         (p_business_group_name)
-- commented for integraUPPER(xx_hr_common_pkg.get_mapping_value('BUSINESS_GROUP_NAME',p_business_group_name))
               AND TRUNC (SYSDATE) BETWEEN date_from AND NVL (date_to,
                                                              SYSDATE);

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, '2 BG');
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
         END;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.cn_success
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                   p_error_text               =>    'E:'
                                                 || xx_emf_cn_pkg.cn_exp_unhand,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                   p_record_identifier_5      => p_business_group_name
                  );
               RETURN x_error_code;
            ELSE
               RETURN x_error_code;
            END IF;
      END get_target_business_group_id;

      --*****************************************************************************
      --- Function to get change_reason
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
      -- Function to get_target_job_id
      -- ******************************************************************************
      FUNCTION get_target_job_id (
         p_job_name            IN              VARCHAR2,
         p_business_group_id   IN              VARCHAR2,
         p_job_id              OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         p_job_id := NULL;

         BEGIN
            IF p_job_name IS NOT NULL
            THEN
               SELECT job_id
                 INTO p_job_id
                 FROM per_jobs
                WHERE name = p_job_name
                  -- commented for integra xx_hr_common_pkg.get_mapping_value('JOB_NAME',   p_job_name)
                  AND business_group_id = p_business_group_id;
            ELSE
               --x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_job_valid,
                   p_error_text               =>    'W:'
                                                 || xx_emf_cn_pkg.cn_job_miss,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                   p_record_identifier_5      => p_job_name
                  );
            END IF;

            RETURN x_error_code;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_job_valid,
                   p_error_text               =>    'E:'
                                                 || xx_emf_cn_pkg.cn_job_toomany,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                   p_record_identifier_5      => p_job_name
                  );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_job_valid,
                   p_error_text               =>    'E:'
                                                 || xx_emf_cn_pkg.cn_job_nodata,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                   p_record_identifier_5      => p_job_name
                  );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_job_valid,
                   p_error_text               =>    'E:'
                                                 || xx_emf_cn_pkg.cn_job_invalid,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                   p_record_identifier_5      => p_job_name
                  );
         END;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.cn_success
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_job_valid,
                   p_error_text               =>    'E:'
                                                 || xx_emf_cn_pkg.cn_exp_unhand,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                   p_record_identifier_5      => p_job_name
                  );
            END IF;

            RETURN x_error_code;
      END get_target_job_id;

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

         BEGIN
            IF p_position_name IS NOT NULL
            THEN
               SELECT position_id
                 INTO p_position_id
                 FROM per_positions
                WHERE UPPER (NAME) = UPPER (p_position_name);
                -- commented for integra xx_hr_common_pkg.get_mapping_value('POSITION',   p_position_name);

               RETURN x_error_code;
            ELSE
               RETURN x_error_code;
            END IF;
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
         END;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.cn_success
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_position_valid,
                   p_error_text               =>    'W:'
                                                 || xx_emf_cn_pkg.cn_exp_unhand,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                   p_record_identifier_5      => p_position_name
                  );
               RETURN x_error_code;
            ELSE
               RETURN x_error_code;
            END IF;
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

         BEGIN
            IF p_location_name IS NOT NULL
            THEN
               SELECT location_id, country
                 INTO p_location_id, p_country_code
                 FROM hr_locations_all
                WHERE location_code =
                         p_location_name
-- commented for integra xx_hr_common_pkg.get_mapping_value('LOCATION_CODE',   p_location_name)
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
         END;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.cn_success
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_location_valid,
                   p_error_text               =>    'W:'
                                                 || xx_emf_cn_pkg.cn_exp_unhand,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                   p_record_identifier_5      => p_location_name
                  );
            END IF;

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
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         p_asg_status_type_id := NULL;

         BEGIN
            IF p_asg_status IS NOT NULL
            THEN
               SELECT assignment_status_type_id
                 INTO p_asg_status_type_id
                 FROM per_assignment_status_types
                WHERE UPPER (user_status) = UPPER (p_asg_status);

               RETURN x_error_code;
            END IF;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_assignment_status_valid,
                   p_error_text               =>    'E:'
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
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_assignment_status_valid,
                   p_error_text               =>    'E:'
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
                   p_error_text               =>    'E:'
                                                 || xx_emf_cn_pkg.cn_assignment_status_invalid,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                   p_record_identifier_5      => p_asg_status
                  );
               RETURN x_error_code;
         END;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.cn_success
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_assignment_status_valid,
                   p_error_text               =>    'E:'
                                                 || xx_emf_cn_pkg.cn_exp_unhand,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                   p_record_identifier_5      => p_asg_status
                  );
               RETURN x_error_code;
            ELSE
               RETURN x_error_code;
            END IF;
      END get_target_assign_status_id;

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

         BEGIN
            IF p_org_name IS NOT NULL
            THEN
               SELECT organization_id
                 INTO p_organization_id
                 FROM hr_all_organization_units
                WHERE  name = p_org_name
                  AND business_group_id = p_business_group_id;
            ELSE
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
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
         END;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.cn_success
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_organization_valid,
                   p_error_text               =>    'E:'
                                                 || xx_emf_cn_pkg.cn_exp_unhand,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                   p_record_identifier_5      => p_org_name
                  );
            END IF;

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
      --                           Function to Get Target Suepervisor Id
      -- ******************************************************************************
      FUNCTION get_target_supervisor_id (
         p_unique_id       IN              VARCHAR2,
         p_supervisor_id   OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_bg_id        VARCHAR2 (40);
      BEGIN
         p_supervisor_id := NULL;

         BEGIN
            IF (p_unique_id IS NOT NULL)
            THEN
               BEGIN
                  SELECT ppf.person_id
                    INTO p_supervisor_id
                    FROM per_all_people_f ppf
                   WHERE attribute1 = p_unique_id
                     AND TRUNC (SYSDATE) BETWEEN ppf.effective_start_date
                                             AND ppf.effective_end_date
                     AND ROWNUM = 1;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     x_error_code := xx_emf_cn_pkg.cn_rec_err;
                     p_supervisor_id := NULL;
                     xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_low,
                         p_category                 => xx_emf_cn_pkg.cn_supervisor_valid,
                         p_error_text               =>    'W:'
                                                       || 'The supervisor should be an employee',
                         p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                         p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                         p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                         p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                         p_record_identifier_5      => p_unique_id
                        );
               END;
            ELSE
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_supervisor_valid,
                   p_error_text               =>    'W:'
                                                 || xx_emf_cn_pkg.cn_supervisor_miss,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                   p_record_identifier_5      => p_unique_id
                  );
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
                   p_record_identifier_5      => p_unique_id
                  );
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
                   p_record_identifier_5      => p_unique_id
                  );
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
                   p_record_identifier_5      => p_unique_id
                  );
         END;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.cn_success
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_supervisor_valid,
                   p_error_text               =>    'W:'
                                                 || xx_emf_cn_pkg.cn_exp_unhand,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                   p_record_identifier_5      => p_unique_id
                  );
            END IF;

            RETURN x_error_code;
      END get_target_supervisor_id;

      -- ******************************************************************************
      --                           Function to get_asg_catg
      -- ******************************************************************************
      FUNCTION get_asg_catg (p_asg_catg IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_asg_catg     VARCHAR2 (30);
      BEGIN
         BEGIN
            IF p_asg_catg IS NOT NULL
            THEN
               SELECT lookup_code
                 INTO x_asg_catg
                 FROM fnd_lookup_values
                WHERE meaning = p_asg_catg
--  commented by integra trim(xx_hr_common_pkg.get_mapping_value('ASSIGNMENT_CATEGORY',  p_asg_catg))
                  AND lookup_type = 'CWK_ASG_CATEGORY'
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
         END;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.cn_success
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => 'ASGCATG-DV01',
                   p_error_text               =>    'E:'
                                                 || xx_emf_cn_pkg.cn_exp_unhand,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.employee_number,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.first_name,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.last_name,
                   p_record_identifier_4      => p_cnv_pre_std_hdr_rec.LOCATION,
                   p_record_identifier_5      => p_asg_catg
                  );
               RETURN x_error_code;
            ELSE
               RETURN x_error_code;
            END IF;
      END get_asg_catg;
      -----------------------------------------------------------------------------
   BEGIN
      x_error_code := xx_emf_cn_pkg.cn_success;
      x_error_code_temp :=
         get_target_business_group_id
                                  (p_cnv_pre_std_hdr_rec.business_group_name,
                                   p_cnv_pre_std_hdr_rec.business_group_id
                                  );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_country_code := NULL;
      ------------------------------------------------------------------------------------------------------------------------------
      /*x_error_code_temp := get_target_person_id(p_cnv_pre_std_hdr_rec.person_unique_id
                                            ,   p_cnv_pre_std_hdr_rec.business_group_id
                                            ,   p_cnv_pre_std_hdr_rec.person_id);

      x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );*/
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

      ------------------------------------------------------------------------------------------------------------------------------
      x_error_code_temp :=
         get_target_supervisor_id (p_cnv_pre_std_hdr_rec.supervisor_unique_id,
                                   p_cnv_pre_std_hdr_rec.supervisor_id
                                  );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      ------------------------------------------------------------------------------------------------------------------------------
      x_error_code_temp :=
                  is_change_reason_valid (p_cnv_pre_std_hdr_rec.change_reason);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Change Reason Derived');
      ------------------------------------------------------------------------------------------------------------------------
      x_error_code_temp :=
         get_target_job_id (p_cnv_pre_std_hdr_rec.job_name,
                            p_cnv_pre_std_hdr_rec.business_group_id,
                            p_cnv_pre_std_hdr_rec.job_id
                           );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' Position ' || p_cnv_pre_std_hdr_rec.pos_title
                           );
      x_error_code_temp :=
         get_target_position_id
                     (p_position_name      => p_cnv_pre_std_hdr_rec.pos_title
                                                                         -- IN
                                                                             ,
                      p_position_id        => p_cnv_pre_std_hdr_rec.position_id
                     );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      ------------------------------------------------------------------------------------------------------------------------------
      --x_error_code_temp := get_target_grade_id(p_cnv_pre_std_hdr_rec.grade_name,   p_cnv_pre_std_hdr_rec.grade_id);
      ------------------------------------------------------------------------------------------------------------------------------
      -- commenting position as position should not be converted
      -- x_error_code_temp := get_target_position_id(p_cnv_pre_std_hdr_rec.POSITION,   p_cnv_pre_std_hdr_rec.position_id);
      ------------------------------------------------------------------------------------------------------------------------------
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
      ------------------------------------------------------------------------------------------------------------------------------
      x_error_code_temp :=
         get_target_assign_status_id
                              (p_cnv_pre_std_hdr_rec.assignment_status,
                               p_cnv_pre_std_hdr_rec.assignment_status_type_id
                              );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      ------------------------------------------------------------------------------------------------------------------------------
      --x_error_code_temp := get_target_salary_basis_id(p_cnv_pre_std_hdr_rec.salary_basis,   p_cnv_pre_std_hdr_rec.pay_basis_id);
      ------------------------------------------------------------------------------------------------------------------------------
      --x_error_code_temp := get_target_payroll_id(p_cnv_pre_std_hdr_rec.payroll_name,   p_cnv_pre_std_hdr_rec.payroll_id);
      ------------------------------------------------------------------------------------------------------------------------------
      --x_error_code_temp := get_target_organization_id(p_cnv_pre_std_hdr_rec.organization,   p_cnv_pre_std_hdr_rec.organization_id);
      x_error_code_temp :=
         get_target_organization_id
             (p_org_name               => p_cnv_pre_std_hdr_rec.ORGANIZATION
                                                                         -- in
                                                                            ,
              p_country_code           => x_country_code                 -- in
                                                        ,
              p_business_group_id      => p_cnv_pre_std_hdr_rec.business_group_id,
              p_organization_id        => p_cnv_pre_std_hdr_rec.organization_id
                                                                        -- out
             );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      ------------------------------------------------------------------------------------------------------------------------------
    /*x_error_code_temp := get_target_tax_unit_id(p_cnv_pre_std_hdr_rec.gre_name,   p_cnv_pre_std_hdr_rec.tax_unit_id);
     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );*/
      ------------------------------------------------------------------------------------------------------------------------------
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
      ------------------------------------------------------------------------------------------------------------------------------
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
    -- additions for integra - end
    ------------------------------------------------------------------------------------------------------------------------------
    -- Added post CRP3 04-JUN-2012
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
      END IF;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' Get Account ' || p_cnv_pre_std_hdr_rec.sob_name
                           );
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
            THEN
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
            END IF;

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
      -- Added post CRP3 04-JUN-2012
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'x_error_code final:' || x_error_code
                           );
      p_cnv_pre_std_hdr_rec.ERROR_CODE := x_error_code;
      RETURN x_error_code;
   END data_derivations;
END xx_hr_cwk_asg_validation_pkg; 
/
