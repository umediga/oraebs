DROP PACKAGE BODY APPS.XX_HR_EMP_CNV_VALIDATIONS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_EMP_CNV_VALIDATIONS_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : XXHREMPVAL.pkb
 Description   : This script creates the body of the package
                 xx_hr_emp_cnv_validations_pkg
 Change History:
 Date        Name             Ver   Remarks
 ----------- -------------    ----  -------------------------------
 14-Dec-2010 Suman Sur        1.0   Initial Development
 06-Jan-2012 Deepika Jain     1.1   Changes for Integra
 03-JUL-2012 Arjun K.         1.3   Ethnic disclosed is nullable.
 */
----------------------------------------------------------------------
----------------------------------------------------------------------
--------------------------< find_max >--------------------------
----------------------------------------------------------------------
   FUNCTION find_max (p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2)
      RETURN VARCHAR2
   IS
      x_return_value   VARCHAR2 (100);
   BEGIN
      x_return_value :=
                   xx_intg_common_pkg.find_max (p_error_code1, p_error_code2);
      RETURN x_return_value;
   END find_max;

----------------------------------------------------------------------
--------------------------< pre_validations >--------------------------
----------------------------------------------------------------------
   FUNCTION pre_validations (
      p_cnv_hdr_rec   IN OUT NOCOPY   xx_hr_emp_conversion_pkg.g_xx_hr_cnv_pre_rec_type
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

----------------------------------------------------------------------
--------------------------< data_validations >--------------------------
----------------------------------------------------------------------
   FUNCTION data_validations (
      p_cnv_hdr_rec   IN OUT NOCOPY   xx_hr_emp_conversion_pkg.g_xx_hr_cnv_pre_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER       := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER       := xx_emf_cn_pkg.cn_success;
      x_rehire_flag       VARCHAR2 (1);

      --- Local functions for all batch level validations
      --- Add as many functions as required in here

      ---------------------------------------------------------------------------
---------------------< Ethnic_origin>---------------------------------------
----------------------------------------------------------------------------
      FUNCTION set_eit_status (p_ethnic_origin IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code    NUMBER         := xx_emf_cn_pkg.cn_success;
         x_column_name   VARCHAR2 (200);
      BEGIN
         IF p_ethnic_origin IS NOT NULL
         THEN
            p_cnv_hdr_rec.eit1 := 'N';
            p_cnv_hdr_rec.eit2 := 'N';
            p_cnv_hdr_rec.eit3 := 'N';
            p_cnv_hdr_rec.eit4 := 'N';
            p_cnv_hdr_rec.eit5 := 'N';
            p_cnv_hdr_rec.eit6 := 'N';
            p_cnv_hdr_rec.eit7 := 'N';
            p_cnv_hdr_rec.eit_information_type := g_us_ethnic_origin;
            p_cnv_hdr_rec.eit_information_category := g_us_ethnic_origin;

            BEGIN
               SELECT   col.application_column_name
                   INTO x_column_name
                   FROM fnd_descr_flex_contexts_tl t,
                        fnd_descr_flex_contexts b,
                        fnd_descr_flex_col_usage_vl col
                  WHERE b.application_id = t.application_id
                    AND b.descriptive_flexfield_name =
                                                  t.descriptive_flexfield_name
                    AND b.descriptive_flex_context_code =
                                               t.descriptive_flex_context_code
                    AND b.application_id = col.application_id
                    AND b.descriptive_flexfield_name =
                                                col.descriptive_flexfield_name
                    AND b.descriptive_flex_context_code =
                                             col.descriptive_flex_context_code
                    AND b.descriptive_flex_context_code = g_us_ethnic_origin
                    AND col.end_user_column_name =
                           xx_hr_common_pkg.get_mapping_value
                                                          ('US_ETHNIC_ORIGIN',
                                                           p_ethnic_origin
                                                          )
                    AND t.LANGUAGE = USERENV ('LANG')
               ORDER BY column_seq_num;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => 'ETHORG-DV001',
                      p_error_text               => 'Ethnic Origin Not Found',
                      p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                      p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                      p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                      p_record_identifier_4      => p_ethnic_origin
                     );
                  RETURN x_error_code;
               WHEN OTHERS
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => 'ETHORG-DV001',
                      p_error_text               =>    'Ethnic Origin Invalid'
                                                    || SQLERRM,
                      p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                      p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                      p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                      p_record_identifier_4      => p_ethnic_origin
                     );
                  RETURN x_error_code;
            END;

            IF x_column_name = 'PEI_INFORMATION1'
            THEN
               p_cnv_hdr_rec.eit1 := 'Y';
            ELSIF x_column_name = 'PEI_INFORMATION2'
            THEN
               p_cnv_hdr_rec.eit2 := 'Y';
            ELSIF x_column_name = 'PEI_INFORMATION3'
            THEN
               p_cnv_hdr_rec.eit3 := 'Y';
            ELSIF x_column_name = 'PEI_INFORMATION4'
            THEN
               p_cnv_hdr_rec.eit4 := 'Y';
            ELSIF x_column_name = 'PEI_INFORMATION5'
            THEN
               p_cnv_hdr_rec.eit5 := 'Y';
            ELSIF x_column_name = 'PEI_INFORMATION6'
            THEN
               p_cnv_hdr_rec.eit6 := 'Y';
            ELSIF x_column_name = 'PEI_INFORMATION7'
            THEN
               p_cnv_hdr_rec.eit7 := 'Y';
            END IF;
         -- Commenting the ELSIF for International Employees for April 2013 release
         /*
         ELSIF     p_ethnic_origin IS NULL
               AND p_cnv_hdr_rec.user_person_type = g_emp_person_type
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'ETHORG-DV001',
                     p_error_text               => 'Ethnic Origin is NULL',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_ethnic_origin
                    );
            RETURN x_error_code;
         */
         END IF;

         RETURN x_error_code;
      END set_eit_status;

----------------------------------------------------------------------
--------------------------< is_empnum_unique >--------------------------
----------------------------------------------------------------------
      FUNCTION is_empnum_unique (
         p_emp_num               IN   VARCHAR2,
         p_business_group_name   IN   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER                    := xx_emf_cn_pkg.cn_success;
         x_emp_num      per_all_people_f.employee_number%TYPE;
      BEGIN
         SELECT DISTINCT papf.attribute1
                    INTO x_emp_num
                    FROM per_all_people_f papf, per_business_groups pbg
                   WHERE papf.business_group_id = pbg.business_group_id
                     AND papf.attribute1 = p_emp_num
                     AND UPPER (pbg.NAME) = UPPER (p_business_group_name);

-- commented for integra UPPER (xx_hr_common_pkg.get_mapping_value ('BUSINESS_GROUP',p_business_group_name));
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => 'EMPNUM-DV0001',
                      p_error_text               => 'Employee Number Already Exists',
                      p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                      p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                      p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                      p_record_identifier_4      => p_emp_num
                     );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' Employee Number: '
                               || p_emp_num
                               || ' already exists.'
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_success;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' Employee Number is unique.'
                                 );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'EMPNUM-DV0001',
                     p_error_text               => 'Employee Number: Too Many Rows',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_emp_num
                    );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     ' Employee Number: '
                                  || p_emp_num
                                  || ' too many.'
                                 );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'EMPNUM-DV0001',
                     p_error_text               =>    'Employee Number Validation Error '
                                                   || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_emp_num
                    );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Employee Number Validation Error '
                                  || SQLERRM
                                 );
            RETURN x_error_code;
      END is_empnum_unique;

----------------------------------------------------------------------
--------------------------< populate_nullcheck_error >----------------
----------------------------------------------------------------------
      PROCEDURE populate_nullcheck_error (p_category IN VARCHAR2)
      IS
      BEGIN
         xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => p_category,
                      p_error_text               => p_category || ' is null',
                      p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                      p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                      p_record_identifier_3      => p_cnv_hdr_rec.user_person_type
                     );
      END populate_nullcheck_error;

----------------------------------------------------------------------
--------------------------< is_value_not_null >-----------------------
----------------------------------------------------------------------
      FUNCTION is_value_not_null (
         p_cnv_hdr_rec   IN   xx_hr_emp_conversion_pkg.g_xx_hr_cnv_pre_rec_type
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside is_value_not_null'
                              );

         IF p_cnv_hdr_rec.country IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            populate_nullcheck_error (g_country_category);
         END IF;

         IF p_cnv_hdr_rec.business_group_name IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            populate_nullcheck_error (g_business_group_category);
         END IF;

         IF p_cnv_hdr_rec.user_person_type IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            populate_nullcheck_error (g_person_type_category);
         END IF;

         IF     p_cnv_hdr_rec.employee_number IS NULL
            AND p_cnv_hdr_rec.user_person_type = g_emp_person_type
            AND p_cnv_hdr_rec.country = 'US'
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            populate_nullcheck_error (g_emp_num_category);
         END IF;

         --Commented as per crp2 test on 02-MAY-2012
         --IF p_cnv_hdr_rec.first_name IS NULL THEN
         --   x_error_code := xx_emf_cn_pkg.cn_rec_err;
            --populate_nullcheck_error(g_first_name_category);
         --END IF;
         IF     p_cnv_hdr_rec.date_of_birth IS NULL
            AND p_cnv_hdr_rec.user_person_type = g_emp_person_type
         --Added as per crp2 test on 02-MAY-2012
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            populate_nullcheck_error (g_date_of_birth_category);
         END IF;

         IF     p_cnv_hdr_rec.hire_date IS NULL
            AND p_cnv_hdr_rec.user_person_type = g_emp_person_type
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            populate_nullcheck_error (g_hire_date_category);
         END IF;

         --Commented as per crp2 test on 02-MAY-2012
         --IF p_cnv_hdr_rec.email_address IS NULL THEN
         --   x_error_code := xx_emf_cn_pkg.cn_rec_err;
            --populate_nullcheck_error(g_email_address_category);
         --END IF;
         IF     p_cnv_hdr_rec.attribute1 IS NULL
            AND p_cnv_hdr_rec.user_person_type = g_emp_person_type
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            populate_nullcheck_error (g_unique_id_category);
         END IF;

         RETURN x_error_code;
      END is_value_not_null;

----------------------------------------------------------------------
--------------------------< is_last_name_not_null >--------------------------
----------------------------------------------------------------------
      FUNCTION is_last_name_not_null (p_last_name IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_last_name IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_lstnm_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_last_name_null,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_last_name
                    );
         END IF;

         RETURN x_error_code;
      END is_last_name_not_null;

----------------------------------------------------------------------
--------------------------< is_start_date_not_null >--------------------------
----------------------------------------------------------------------
      FUNCTION is_start_date_not_null (p_start_date IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_start_date IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_strdt_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_strdt_null,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_start_date
                    );
         END IF;

         RETURN x_error_code;
      END is_start_date_not_null;

     ----------------------------------------------------------------------
--------------------------< is_national_identifier_not_null >--------------------------
----------------------------------------------------------------------
      FUNCTION is_nat_identifier_not_null (p_national_identifier IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF     p_national_identifier IS NULL
            AND p_cnv_hdr_rec.user_person_type = g_emp_person_type
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'NATIDEN-DV001',
                     p_error_text               => 'National Identifier is null',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_national_identifier
                    );
         END IF;

         RETURN x_error_code;
      END is_nat_identifier_not_null;

----------------------------------------------------------------------
--------------------------< is_title_valid >--------------------------
----------------------------------------------------------------------
      FUNCTION is_title_valid (p_title IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
      BEGIN
         BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'p_title ' || p_title);

            IF p_title IS NOT NULL
            THEN
               SELECT DISTINCT lookup_code
                          INTO x_variable
                          FROM fnd_lookup_values
                         WHERE lookup_type = 'TITLE'
                           AND UPPER (lookup_code) = UPPER (p_title)
                           AND LANGUAGE = USERENV ('LANG')
                           AND SYSDATE BETWEEN NVL (start_date_active,
                                                    SYSDATE)
                                           AND NVL (end_date_active, SYSDATE);

               p_title := x_variable;
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        ' Length of x_variable '
                                     || LENGTH (x_variable)
                                     || ' '
                                     || LENGTH (p_title)
                                    );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'p_title '
                                     || p_title
                                     || ' x_variable '
                                     || x_variable
                                    );
            -- x_error_code := xx_emf_cn_pkg.cn_prc_err;
            END IF;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_title_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_title_toomany,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_title
                    );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_title_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_title_ndtfound,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_title
                    );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_title_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_title_invalid,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_title
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
                     p_category                 => xx_emf_cn_pkg.cn_title_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_title
                    );
            END IF;

            RETURN x_error_code;
      END is_title_valid;

----------------------------------------------------------------------
--------------------------< is_gender_valid >--------------------------
--------< changed the p_sex parameter to IN OUT from IN >--------------
----------------------------------------------------------------------
      FUNCTION is_gender_valid (p_sex IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
      BEGIN
         BEGIN
            IF p_sex IS NOT NULL
            THEN
               -- dupatil 30Nov2007: added distinct in select, changed meaning to lookup_code
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     ' GENDER VALIDATION STARTS'
                                    );

               SELECT DISTINCT lookup_code
                          INTO x_variable
                          FROM fnd_lookup_values
                         WHERE lookup_type = 'SEX'
                           AND UPPER (meaning) = UPPER (p_sex)
-- commented for integra UPPER (xx_hr_common_pkg.get_mapping_value ('GENDER',p_sex))
                           AND LANGUAGE = USERENV ('LANG')
                           AND SYSDATE BETWEEN NVL (start_date_active,
                                                    SYSDATE)
                                           AND NVL (end_date_active, SYSDATE);

               p_sex := x_variable;
               -- added by debashis for assigning M/F to p_sex
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     ' GENDER VALIDATED '
                                    );
            ELSIF     p_sex IS NULL
                  AND p_cnv_hdr_rec.user_person_type = g_emp_person_type
            THEN                    -- changed as per crp2 test on 02-MAY-2012
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_gendr_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_gender_miss,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_sex
                    );
            END IF;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_gendr_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_gender_toomany,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_sex
                    );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_gendr_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_gender_nodtfound,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_sex
                    );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_gendr_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_gender_invalid,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_sex
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
                    (p_severity                 => xx_emf_cn_pkg.cn_high,
                     p_category                 => xx_emf_cn_pkg.cn_gendr_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_sex
                    );
            END IF;

            RETURN x_error_code;
      END is_gender_valid;

----------------------------------------------------------------------
--------------------------< is_nationality_valid >--------------------------
----------------------------------------------------------------------
      FUNCTION is_nationality_valid (p_nationality IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
      BEGIN
         BEGIN
            IF p_nationality IS NOT NULL
            THEN
               SELECT lookup_code
                 INTO x_variable
                 FROM fnd_lookup_values
                WHERE lookup_type = 'NATIONALITY'
                  AND UPPER (meaning) = UPPER (p_nationality)
-- commented for integra UPPER (xx_hr_common_pkg.get_mapping_value ('NATIONALITY',p_nationality)) -- Added by Ranjit
                  AND LANGUAGE = USERENV ('LANG')
                  AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                  AND NVL (end_date_active, SYSDATE);

               p_nationality := x_variable;
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     ' p_nationality ' || p_nationality
                                    );
            --x_error_code := xx_emf_cn_pkg.cn_prc_err;
            END IF;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_natly_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_nationality_toomany,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_nationality
                    );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_natly_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_nationality_ndtfound,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_nationality
                    );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_natly_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_nationality_invalid,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_nationality
                    );
         END;

         --
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.cn_success
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_natly_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_nationality
                    );
            END IF;

            RETURN x_error_code;
      END is_nationality_valid;

----------------------------------------------------------------------
--------------------------< is_marital_status_valid >--------------------------
----------------------------------------------------------------------
      FUNCTION is_marital_status_valid (p_marital_status IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
      BEGIN
         IF p_marital_status IS NOT NULL
         THEN
            BEGIN
               SELECT lookup_code
                 INTO p_marital_status                            --x_variable
                 FROM fnd_lookup_values
                WHERE lookup_type = 'MAR_STATUS'
                  AND UPPER (meaning) = UPPER (p_marital_status)
                  -- commented for integra = xx_hr_common_pkg.get_mapping_value('MARITAL_STATUS',p_marital_status)
                  AND LANGUAGE = USERENV ('LANG')
                  AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                  AND NVL (end_date_active, SYSDATE);
            EXCEPTION
               WHEN TOO_MANY_ROWS
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.cn_martl_valid,
                      p_error_text               => xx_emf_cn_pkg.cn_marital_toomany,
                      p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                      p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                      p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                      p_record_identifier_4      => p_marital_status
                     );
               WHEN NO_DATA_FOUND
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.cn_martl_valid,
                      p_error_text               => xx_emf_cn_pkg.cn_marital_ndtfound,
                      p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                      p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                      p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                      p_record_identifier_4      => p_marital_status
                     );
               WHEN OTHERS
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.cn_martl_valid,
                      p_error_text               => xx_emf_cn_pkg.cn_marital_invalid,
                      p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                      p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                      p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                      p_record_identifier_4      => p_marital_status
                     );
            END;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.cn_success
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_martl_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_marital_status
                    );
            END IF;

            RETURN x_error_code;
      END is_marital_status_valid;

----------------------------------------------------------------------
--------------------------< is_orig_date_correct >--------------------------
----------------------------------------------------------------------
      FUNCTION is_orig_date_correct (
         p_original_date_of_hire   IN   DATE,
         p_start_date              IN   DATE
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_original_date_of_hire > p_start_date
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_oghdt_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_origl_hiredt_invalid,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_original_date_of_hire
                    );
         END IF;

         RETURN x_error_code;
      END is_orig_date_correct;

----------------------------------------------------------------------
--------------------------< is_veteran_100_valid >-----------------
----------------------------------------------------------------------
      FUNCTION is_veteran_100_valid (p_veteran_status IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         BEGIN
            SELECT lookup_code
              INTO p_veteran_status                               --x_variable
              FROM hr_lookups
             WHERE lookup_type = 'US_VETERAN_STATUS'
               AND UPPER (meaning) = UPPER (p_veteran_status)
               AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                               AND NVL (end_date_active, SYSDATE);
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'VETERAN-DV001',
                     p_error_text               => 'VETERAN STATUS : Too Many Rows',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_veteran_status
                    );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'VETERAN-DV001',
                     p_error_text               => 'VETERAN STATUS : No Data Found',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_veteran_status
                    );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'VETERAN-DV001',
                     p_error_text               =>    'Veteran Status Invalid',
                                                   --|| SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_veteran_status
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
                     p_category                 => 'VETERAN-DV001',
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_veteran_status
                    );
            END IF;

            RETURN x_error_code;
      END is_veteran_100_valid;

      ----------------------------------------------------------------------
      --------------------------< is_veteran_100A_valid >-------------------
      ----------------------------------------------------------------------
      FUNCTION is_veteran_100a_valid (p_veteran_status IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         BEGIN
            SELECT lookup_code
              INTO p_veteran_status
              FROM hr_lookups
             WHERE lookup_type = 'US_VETERAN_STATUS_VETS100A'
               --AND UPPER (meaning) = UPPER (p_veteran_status)--Commented for crp2 test on 03-MAY-2012
               AND UPPER (meaning) = UPPER(xx_hr_common_pkg.get_mapping_value
                                        ('US_VETERAN_STATUS_VETS100A',
                                          p_veteran_status
                                            )
                                          )--Added for crp2 test on 03-MAY-2012
               AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                               AND NVL (end_date_active, SYSDATE);
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'VETERAN-DV001',
                     p_error_text               => 'VETERAN STATUS : Too Many Rows',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_veteran_status
                    );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'VETERAN-DV001',
                     p_error_text               => 'VETERAN STATUS : No Data Found',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_veteran_status
                    );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'VETERAN-DV001',
                     p_error_text               =>    'Veteran Status Invalid '
                                                   || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_veteran_status
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
                     p_category                 => 'VETERAN-DV001',
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_veteran_status
                    );
            END IF;

            RETURN x_error_code;
      END is_veteran_100a_valid;

----------------------------------------------------------------------
 --------------------------< is_registered_flag_valid >-----------------
 ----------------------------------------------------------------------
      FUNCTION is_registered_flag_valid (p_reg_status IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         BEGIN
            SELECT lookup_code
              INTO p_reg_status                                   --x_variable
              FROM fnd_lookup_values
             WHERE lookup_type = 'REGISTERED_DISABLED'
               AND UPPER (meaning) = UPPER (p_reg_status)
-- commented for integra xx_hr_common_pkg.get_mapping_value('DISABLED',p_reg_status)
               AND LANGUAGE = USERENV ('LANG')
               AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                               AND NVL (end_date_active, SYSDATE);
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => 'REGSTAT-DV001',
                   p_error_text               => 'DISABLED REGISTERED STATUS : Too Many Rows',
                   p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                   p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                   p_record_identifier_4      => p_reg_status
                  );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => 'REGSTAT-DV001',
                   p_error_text               => 'DISABLED REGISTERED STATUS : No Data Found',
                   p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                   p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                   p_record_identifier_4      => p_reg_status
                  );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'REGSTAT-DV001',
                     p_error_text               =>    'DISABLED REGISTERED STATUS'
                                                   || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_reg_status
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
                     p_category                 => 'REGSTAT-DV001',
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_reg_status
                    );
            END IF;

            RETURN x_error_code;
      END is_registered_flag_valid;

  ----------------------------------------------------------------
--------------------------< is_ethnic_origin_valid >-----------------
----------------------------------------------------------------
      FUNCTION is_ethnic_origin_valid (p_ethnic_origin IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code      NUMBER         := xx_emf_cn_pkg.cn_success;
         x_ethinc_origin   VARCHAR2 (150) := NULL;
      BEGIN
         BEGIN
            IF p_ethnic_origin IS NOT NULL
            THEN
               SELECT lookup_code
                 INTO x_ethinc_origin
                 FROM fnd_lookup_values
                WHERE lookup_type = 'US_ETHNIC_GROUP'
                  AND LANGUAGE = USERENV ('LANG')
                  AND UPPER (meaning) = UPPER (p_ethnic_origin)
                  AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                  AND NVL (end_date_active, SYSDATE);

               p_ethnic_origin := x_ethinc_origin;
            ELSIF     p_cnv_hdr_rec.country = 'US'
                  AND p_cnv_hdr_rec.user_person_type = g_emp_person_type
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'ETHNICORIGIN-DV001',
                     p_error_text               => 'Ethnic Origin is null',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_ethnic_origin
                    );
            END IF;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'ETHNICORIGIN-DV001',
                     p_error_text               => 'Ethnic Origin : Too Many Rows',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_ethnic_origin
                    );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'ETHNICORIGIN-DV001',
                     p_error_text               => 'Ethnic Origin : No Data Found',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_ethnic_origin
                    );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'ETHNICORIGIN-DV001',
                     p_error_text               => 'Ethnic Origin ' || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_ethnic_origin
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
                     p_category                 => 'ETHNICORIGIN-DV001',
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_ethnic_origin
                    );
            END IF;

            RETURN x_error_code;
      END is_ethnic_origin_valid;

----------------------------------------------------------------
--------------------------< is_new_hire_valid >-----------------
----------------------------------------------------------------
      FUNCTION is_new_hire_valid (p_new_hire IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         BEGIN
            IF p_new_hire IS NOT NULL
            THEN
               SELECT lookup_code
                 INTO p_new_hire                                  --x_variable
                 FROM fnd_lookup_values
                WHERE lookup_type = 'US_NEW_HIRE_STATUS'
                  AND UPPER (meaning) = UPPER (p_new_hire)
-- commented for integra xx_hr_common_pkg.get_mapping_value('NEW_HIRE_REP',p_new_hire)
                  AND LANGUAGE = USERENV ('LANG')
                  AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                  AND NVL (end_date_active, SYSDATE);
            ELSIF p_cnv_hdr_rec.country = 'US'
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'NEWHIRE-DV001',
                     p_error_text               => 'New Hire is null',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_new_hire
                    );
            END IF;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'NEWHIRE-DV001',
                     p_error_text               => 'NEW HIRE : Too Many Rows',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_new_hire
                    );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'NEWHIRE-DV001',
                     p_error_text               => 'NEW HIRE : No Data Found',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_new_hire
                    );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'NEWHIRE-DV001',
                     p_error_text               => 'NEW HIRE ' || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_new_hire
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
                     p_category                 => 'NEWHIRE-DV001',
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_new_hire
                    );
            END IF;

            RETURN x_error_code;
      END is_new_hire_valid;

----------------------------------------------------------------------
--------------------------< is_i9_status_valid >----------------------
----------------------------------------------------------------------
      FUNCTION is_i9_status_valid (p_i9_status IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         BEGIN
            IF p_i9_status IS NOT NULL
            THEN
               SELECT lookup_code
                 INTO p_i9_status                                 --x_variable
                 FROM fnd_lookup_values
                WHERE lookup_type = 'PER_US_I9_STATE'
                  AND UPPER (meaning) = UPPER (p_i9_status)
-- commented for integra xx_hr_common_pkg.get_mapping_value('I9_STATUS',p_i9_status)
                  AND LANGUAGE = USERENV ('LANG')
                  AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                  AND NVL (end_date_active, SYSDATE);
            /* ELSEIF Commented for loading international employees in Aril 2013 release
            ELSIF p_cnv_hdr_rec.country = 'US' AND p_cnv_hdr_rec.user_person_type = g_emp_person_type
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'I9STATUS-DV001',
                     p_error_text               => 'I9 STATUS is null',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_i9_status
                    );
            */
            
            END IF;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'I9STATUS-DV001',
                     p_error_text               => 'I9 STATUS : Too Many Rows',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_i9_status
                    );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'I9STATUS-DV001',
                     p_error_text               => 'I9 STATUS : No Data Found',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_i9_status
                    );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'I9STATUS-DV001',
                     p_error_text               => 'I9 STATUS ' || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_i9_status
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
                     p_category                 => 'I9STATUS-DV001',
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_i9_status
                    );
            END IF;

            RETURN x_error_code;
      END is_i9_status_valid;

----------------------------------------------------------------------
--------------------------< is_language_valid >----------------------
----------------------------------------------------------------------
      FUNCTION is_language_valid (p_language IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         BEGIN
            SELECT language_code
              INTO p_language                                     --x_variable
              FROM fnd_languages_vl
             WHERE UPPER (nls_language) = UPPER (p_language);
-- commented for integra UPPER(xx_hr_common_pkg.get_mapping_value('CORRESP_LANGUAGE',p_language));
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'LANGUAGE-DV001',
                     p_error_text               => 'LANGUAGE : Too Many Rows',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_language
                    );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'LANGUAGE-DV001',
                     p_error_text               => 'LANGUAGE : No Data Found',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_language
                    );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'LANGUAGE-DV001',
                     p_error_text               => 'LANGUAGE ' || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_language
                    );
         END;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.cn_success
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'LANGUAGE-DV001',
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_language
                    );
            END IF;

            RETURN x_error_code;
      END is_language_valid;

----------------------------------------------------------------------
--------------------------< is_empnum_manual_generation >-------------
----------------------------------------------------------------------
      FUNCTION is_empnum_manual_generation (
         p_name          IN   VARCHAR2,
         p_country       IN   VARCHAR2,
         p_person_type   IN   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER                    := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
         p_method       per_business_groups.method_of_generation_emp_num%TYPE;
      BEGIN
         BEGIN
            IF p_name IS NOT NULL AND p_country IS NOT NULL
            THEN
               --Commented for Integra IF xx_hr_common_pkg.get_mapping_value ('PERSON_TYPE',p_person_type) = 'Employee' THEN
               IF UPPER (p_person_type) = 'EMPLOYEE'
               THEN
                  SELECT method_of_generation_emp_num
                    INTO p_method
                    FROM per_business_groups pbg
                   --WHERE UPPER (pbg.name) = UPPER (xx_hr_common_pkg.get_mapping_value ('BUSINESS_GROUP',p_name)) -- commented by deepika
                  WHERE  UPPER (pbg.NAME) = UPPER (p_name) -- added by deepika
                     AND TRUNC (SYSDATE) BETWEEN date_from
                                             AND NVL (date_to, SYSDATE)
                     AND enabled_flag = 'Y';

                  -- p_method : M (Manual)  A (Automatic)
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        ' P_METHOD ' || p_method
                                       );
               --Commented for Integra ELSIF xx_hr_common_pkg.get_mapping_value ('PERSON_TYPE',p_person_type) = 'Candidate' THEN
               ELSIF UPPER (p_person_type) = 'CANDIDATE'
               THEN
                  SELECT method_of_generation_apl_num
                    INTO p_method
                    FROM per_business_groups pbg
                   --WHERE UPPER (pbg.name) = UPPER (xx_hr_common_pkg.get_mapping_value ('BUSINESS_GROUP',p_name)) -- commented by deepika
                  WHERE  UPPER (pbg.NAME) = UPPER (p_name) -- added by deepika
                     AND TRUNC (SYSDATE) BETWEEN date_from
                                             AND NVL (date_to, SYSDATE)
                     AND enabled_flag = 'Y';
               -- p_method : M (Manual)  A (Automatic)
               END IF;

               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     ' P_METHOD ' || p_method
                                    );

               IF     p_country = 'US'
                  AND p_method = 'M'
                  AND p_person_type = 'Employee'
               THEN      -- changed from M to A (emp num generation Automatic)
                  RETURN x_error_code;
               ELSIF p_method = 'A'
               THEN
                  RETURN x_error_code;
               ELSE
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.cn_emgen_valid,
                      p_error_text               => xx_emf_cn_pkg.cn_autemp_gen_noallow,
                      p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                      p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                      p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                      p_record_identifier_4      => p_method
                     );
               END IF;                                              --P_METHOD
            ELSE                               -- P_NAME and p_country IS NULL
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_emgen_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_business_grp_null,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_method
                    );
            END IF;                                                  -- P_NAME
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_emgen_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_autoemp_gen_toomany,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_method
                    );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_emgen_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_business_grp_invalid,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_method
                    );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_emgen_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_autoemp_gen_invalid,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_method
                    );
         END;                                             -- Second Begin -END

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.cn_success
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_emgen_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_method
                    );
            END IF;

            RETURN x_error_code;
      END is_empnum_manual_generation;

----------------------------------------------------------------------
-------------------< is_ethnic_disclosed_valid >----------------------
----------------------------------------------------------------------
      FUNCTION is_ethnic_disclosed_valid (
         p_ethnic_status   IN OUT NOCOPY   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         BEGIN
            IF p_ethnic_status IS NOT NULL
            THEN
               SELECT lookup_code
                 INTO p_ethnic_status                             --x_variable
                 FROM hr_lookups
                WHERE lookup_type = 'US_ETHNIC_DISCLOSURE'
                  AND UPPER (meaning) = UPPER (p_ethnic_status)
-- commented for integra UPPER (xx_hr_common_pkg.get_mapping_value ('ETHNICITY_DISCLOSED',p_ethnic_status))
                  AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                  AND NVL (end_date_active, SYSDATE);
             --Commented during SIT since its non mandatory on 03-JUL-2012
            /*ELSIF p_cnv_hdr_rec.country = 'US'
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'ETNHICSTATUS-DV001',
                     p_error_text               => 'Ethnicity disclosed is null',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_ethnic_status
                    );*/
            END IF;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'ETNHICSTATUS-DV001',
                     p_error_text               => 'ETHIC STATUS : Too Many Rows',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_ethnic_status
                    );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'ETNHICSTATUS-DV001',
                     p_error_text               => 'ETHNIC STATUS : No Data Found',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_ethnic_status
                    );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'ETHNICSTATUS-DV001',
                     p_error_text               => 'ETHNIC STATUS ' || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_ethnic_status
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
                     p_category                 => 'ETHNICSTATUS-DV001',
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_ethnic_status
                    );
            END IF;

            RETURN x_error_code;
      END is_ethnic_disclosed_valid;

     ----------------------------------------------------------------------
----------------< is_termination_date_null >------------------------
----------------------------------------------------------------------
      FUNCTION is_termination_date_null (
         p_actual_termination_date   IN   DATE,
         p_employee_number           IN   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         l_count        NUMBER := 0;
      BEGIN
         IF p_actual_termination_date IS NULL
         THEN
            -- since data file has 2 records for re-hire cases, need to check if the other record for the employee has termination details populated
            SELECT COUNT (1)
              INTO l_count
              FROM xx_hr_emp_pre
             WHERE employee_number = p_employee_number
               AND termination_date IS NOT NULL;

            IF l_count = 0
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'Actual_Term_Date',
                     p_error_text               => 'Actual Termination Date is NULL',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_actual_termination_date
                    );
            END IF;
         END IF;

         RETURN x_error_code;
      END is_termination_date_null;

            ----------------------------------------------------------------------
----------------< is_final_proc_date_null >------------------------
----------------------------------------------------------------------
      FUNCTION is_final_proc_date_null (
         p_final_proc_date   IN   DATE,
         p_employee_number   IN   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         l_count        NUMBER := 0;
      BEGIN
         IF p_final_proc_date IS NULL
         THEN
            -- since data file has 2 records for re-hire cases, need to check if the other record for the employee has termination details populated
            SELECT COUNT (1)
              INTO l_count
              FROM xx_hr_emp_pre
             WHERE employee_number = p_employee_number
               AND final_processing_date IS NOT NULL;

            IF l_count = 0
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'FINAL_PROC_DATE',
                     p_error_text               => 'Final Processing Date is NULL',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_final_proc_date
                    );
            END IF;
         END IF;

         RETURN x_error_code;
      END is_final_proc_date_null;

        ----------------------------------------------------------------------
----------------< is_termination_reason_valid >------------------------
----------------------------------------------------------------------
      FUNCTION is_termination_reason_valid (
         p_termination_reason   IN OUT   VARCHAR,
         p_employee_number      IN       VARCHAR
      )
         RETURN NUMBER
      IS
         x_error_code           NUMBER         := xx_emf_cn_pkg.cn_success;
         x_termination_reason   VARCHAR2 (100);
         l_count                NUMBER         := 0;
      BEGIN
         IF p_termination_reason IS NULL
         THEN
            -- since data file has 2 records for re-hire cases, need to check if the other record for the employee has termination details populated
            SELECT COUNT (1)
              INTO l_count
              FROM xx_hr_emp_pre
             WHERE employee_number = p_employee_number
               AND termination_reason IS NOT NULL;

            IF l_count = 0
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'Termination_Reason',
                     p_error_text               => 'Termination Reason is NULL',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_termination_reason
                    );
            END IF;
         ELSE
            BEGIN
               SELECT lookup_code
                 INTO x_termination_reason
                 FROM hr_lookups
                WHERE lookup_type = 'LEAV_REAS'
                  AND UPPER (meaning) = UPPER (p_termination_reason)
                  AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                  AND NVL (end_date_active, SYSDATE);

               p_termination_reason := x_termination_reason;
            EXCEPTION
               WHEN TOO_MANY_ROWS
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => 'TERMREASON-DV001',
                      p_error_text               => 'Termination Reason : Too Many Rows',
                      p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                      p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                      p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                      p_record_identifier_4      => p_termination_reason
                     );
               WHEN NO_DATA_FOUND
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => 'TERMREASON-DV001',
                      p_error_text               => 'Termination Reason : No Data Found',
                      p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                      p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                      p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                      p_record_identifier_4      => p_termination_reason
                     );
               WHEN OTHERS
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => 'TERMREASON-DV001',
                      p_error_text               =>    'Termination Reason '
                                                    || SQLERRM,
                      p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                      p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                      p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                      p_record_identifier_4      => p_termination_reason
                     );
            END;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.cn_success
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'TERMREASON-DV001',
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_termination_reason
                    );
            END IF;

            RETURN x_error_code;
      END is_termination_reason_valid;

        ----------------------------------------------------------------------
----------------< is_rehire_rec_present >------------------------
----------------------------------------------------------------------
      FUNCTION is_rehire_rec_present (p_unique_id IN VARCHAR)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         l_count        NUMBER := 0;
      BEGIN
         IF p_unique_id IS NOT NULL
         THEN
            -- check if 2 records are present in the data file for this unique id. This is required in re-hire cases
            SELECT COUNT (1)
              INTO l_count
              FROM xx_hr_emp_pre
             WHERE attribute1 = p_unique_id;

            xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                                 'The count of records for this unique id is '
                              || l_count
                             );

            IF l_count <> 2
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'REHIRE-DV001',
                     p_error_text               => 'Number of re-hire records incorrect',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_cnv_hdr_rec.employee_number
                    );
            END IF;
         ELSE
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'REHIRE-DV001',
                     p_error_text               => 'Unique id is null',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_cnv_hdr_rec.employee_number
                    );
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'REHIRE-DV001',
                     p_error_text               => 'Number of re-hire records incorrect',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_cnv_hdr_rec.employee_number
                    );
            RETURN x_error_code;
      END is_rehire_rec_present;

--------------------------------------------------------------------------
--------------------------< get_person_type >--------------------------
--------------------------------------------------------------------------
      FUNCTION get_person_type (
         p_record_number      IN   NUMBER,
         p_user_person_type   IN   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code    NUMBER         := xx_emf_cn_pkg.cn_success;
         x_variable      VARCHAR2 (40);
         x_person_type   VARCHAR2 (100);
      BEGIN
         BEGIN
            IF p_user_person_type IS NOT NULL
            THEN
               SELECT new_value1
                 INTO x_person_type
                 FROM xx_hr_mapping
                WHERE mapping_type = 'PERSON_TYPE'
                  AND UPPER (old_value1) = UPPER (p_user_person_type)
                  AND active_flag = 'Y';

               UPDATE xx_hr_emp_pre
                  SET user_person_type = x_person_type
                WHERE record_number = p_record_number;

               COMMIT;
            END IF;                                      -- p_user_person_type
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_person_type_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_person_type_toomany,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_user_person_type
                    );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_person_type_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_person_type_nodta_fnd,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_user_person_type
                    );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_person_type_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_person_type_invalid,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_user_person_type
                    );
         END;                                             -- Second Begin -END

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.cn_success
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_person_type_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_user_person_type
                    );
            END IF;

            RETURN x_error_code;
      END get_person_type;
----------------------------------------------------------------------
--- Start of the main function perform_batch_validations
--- This will only have calls to the individual functions.
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Data-Validations');
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'is_empnum_unique');
      x_error_code_temp :=
         is_empnum_unique (p_cnv_hdr_rec.attribute1,
                           p_cnv_hdr_rec.business_group_name
                          );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp := set_eit_status (p_cnv_hdr_rec.ethnic_origin);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      /*xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'The user person type before data derivations is '||p_cnv_pre_std_hdr_rec.user_person_type);
      --Commented for integra mapping not required
      --x_error_code_temp := get_person_type(p_cnv_pre_std_hdr_rec.record_number
                                                  ,p_cnv_pre_std_hdr_rec.user_person_type
                                                  );
          --x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'The user person type after data derivations is '||p_cnv_pre_std_hdr_rec.user_person_type);*/
      x_error_code_temp := is_value_not_null (p_cnv_hdr_rec);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
                         (xx_emf_cn_pkg.cn_low,
                             'x_error_code from is_value_not_null function is'
                          || x_error_code
                         );
      x_error_code_temp := is_last_name_not_null (p_cnv_hdr_rec.last_name);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
                     (xx_emf_cn_pkg.cn_low,
                         'x_error_code from is_last_name_not_null function is'
                      || x_error_code
                     );
      x_error_code_temp := is_start_date_not_null (p_cnv_hdr_rec.hire_date);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                        'x_error_code from is_start_date_not_null function is'
                     || x_error_code
                    );
      x_error_code_temp :=
                is_nat_identifier_not_null (p_cnv_hdr_rec.national_identifier);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
                (xx_emf_cn_pkg.cn_low,
                    'x_error_code from is_nat_identifier_not_null function is'
                 || x_error_code
                );
      x_error_code_temp := is_title_valid (p_cnv_hdr_rec.title);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp := is_gender_valid (p_cnv_hdr_rec.sex);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp := is_nationality_valid (p_cnv_hdr_rec.nationality);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
                      (xx_emf_cn_pkg.cn_low,
                          'x_error_code from is_nationality_valid function is'
                       || x_error_code
                      );
      x_error_code_temp :=
                        is_marital_status_valid (p_cnv_hdr_rec.marital_status);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
                   (xx_emf_cn_pkg.cn_low,
                       'x_error_code from is_marital_status_valid function is'
                    || x_error_code
                   );
      x_error_code_temp :=
         is_empnum_manual_generation (p_cnv_hdr_rec.business_group_name,
                                      p_cnv_hdr_rec.country,
                                      p_cnv_hdr_rec.user_person_type
                                     );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
               (xx_emf_cn_pkg.cn_low,
                   'x_error_code from is_empnum_manual_generation function is'
                || x_error_code
               );

      -- additions for integra - start
      IF p_cnv_hdr_rec.vets_100 IS NOT NULL
      THEN
         x_error_code_temp := is_veteran_100_valid (p_cnv_hdr_rec.vets_100);
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                     (xx_emf_cn_pkg.cn_low,
                         'x_error_code from is_veteran_100_valid function is'
                      || x_error_code
                     );
      END IF;

      IF p_cnv_hdr_rec.vets_100a IS NOT NULL
      THEN
         x_error_code_temp := is_veteran_100a_valid (p_cnv_hdr_rec.vets_100a);
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                        'x_error_code from is_veteran_100a_valid function is'
                     || x_error_code
                    );
      END IF;

      -- additions for integra - end
      IF p_cnv_hdr_rec.registered_disabled_flag IS NOT NULL
      THEN
         x_error_code_temp :=
            is_registered_flag_valid (p_cnv_hdr_rec.registered_disabled_flag);
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                 (xx_emf_cn_pkg.cn_low,
                     'x_error_code from is_registered_flag_valid function is'
                  || x_error_code
                 );
      END IF;

      x_error_code_temp :=
                 is_ethnic_disclosed_valid (p_cnv_hdr_rec.ethnicity_disclosed);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
                 (xx_emf_cn_pkg.cn_low,
                     'x_error_code from is_ethnic_disclosed_valid function is'
                  || x_error_code
                 );
      --x_error_code_temp :=
      --                    is_ethnic_origin_valid (p_cnv_hdr_rec.ethnic_origin);
      --x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp := is_i9_status_valid (p_cnv_hdr_rec.i9_status);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                            'x_error_code from is_i9_status_valid function is'
                         || x_error_code
                        );
      x_error_code_temp := is_new_hire_valid (p_cnv_hdr_rec.new_hire_status);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
                         (xx_emf_cn_pkg.cn_low,
                             'x_error_code from is_new_hire_valid function is'
                          || x_error_code
                         );

      IF p_cnv_hdr_rec.correspondence_language IS NOT NULL
      THEN
         x_error_code_temp :=
                    is_language_valid (p_cnv_hdr_rec.correspondence_language);
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                            'x_error_code from is_language_valid function is'
                         || x_error_code
                        );
      END IF;

      --Perform validations for re-hire cases
      SELECT DECODE (p_cnv_hdr_rec.rehire_flag, 'Yes', 'Y', 'Y', 'Y', 'N')
        INTO x_rehire_flag
        FROM DUAL;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'The error code before rehire validations is '
                            || x_error_code
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'x_rehire_flag in validation pkg is '
                            || x_rehire_flag
                           );

      IF     x_rehire_flag = 'Y'
         AND p_cnv_hdr_rec.user_person_type = g_emp_person_type
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Start validations for rehires'
                              );
         x_error_code_temp :=
            is_termination_date_null (p_cnv_hdr_rec.termination_date,
                                      p_cnv_hdr_rec.employee_number
                                     );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         x_error_code_temp :=
            is_final_proc_date_null (p_cnv_hdr_rec.final_processing_date,
                                     p_cnv_hdr_rec.employee_number
                                    );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         x_error_code_temp :=
            is_termination_reason_valid (p_cnv_hdr_rec.termination_reason,
                                         p_cnv_hdr_rec.employee_number
                                        );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         x_error_code_temp := is_rehire_rec_present (p_cnv_hdr_rec.attribute1);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

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

----------------------------------------------------------------------
--------------------------< post_validations >--------------------------
----------------------------------------------------------------------
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

----------------------------------------------------------------------
--------------------------< data_derivations >--------------------------
----------------------------------------------------------------------
   FUNCTION data_derivations (
      p_cnv_pre_std_hdr_rec   IN OUT NOCOPY   xx_hr_emp_conversion_pkg.g_xx_hr_cnv_pre_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

----------------------------------------------------------------------
--------------------------< get_business_group_id >--------------------------
----------------------------------------------------------------------
      FUNCTION get_business_group_id (
         p_business_group_name   IN       VARCHAR2,
         p_business_group_id     OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code            NUMBER         := xx_emf_cn_pkg.cn_success;
         x_bg_id                 VARCHAR2 (40);
         x_business_group_name   VARCHAR2 (100);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                  'Employee Number:V: Bussinee Group '
                               || p_cnv_pre_std_hdr_rec.employee_number
                               || ';'
                               || p_business_group_name
                              );

         -- p_business_group_id := null;
         BEGIN
            IF p_business_group_name IS NOT NULL
            THEN
               SELECT pbg.business_group_id
                 INTO p_business_group_id
                 FROM per_business_groups pbg
                WHERE UPPER (pbg.NAME) = UPPER (p_business_group_name)
                  --UPPER (xx_hr_common_pkg.get_mapping_value ('BUSINESS_GROUP', p_business_group_name))
                  AND TRUNC (SYSDATE) BETWEEN date_from AND NVL (date_to,
                                                                 SYSDATE
                                                                );

               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                        'Employee Number:2: Bussinee Group '
                                     || p_cnv_pre_std_hdr_rec.attribute1
                                     || ';'
                                     || p_business_group_name
                                     || ';'
                                     || p_business_group_id
                                    );
            ELSE
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                   p_error_text               => 'Business Group is null',
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                   p_record_identifier_4      => p_business_group_name
                  );
            END IF;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                   p_error_text               => xx_emf_cn_pkg.cn_business_grp_toomany,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                   p_record_identifier_4      => p_business_group_name
                  );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                   p_error_text               => xx_emf_cn_pkg.cn_busigrp_nodta_fnd,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                   p_record_identifier_4      => p_business_group_name
                  );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                   p_error_text               => xx_emf_cn_pkg.cn_business_grp_invalid,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                   p_record_identifier_4      => p_business_group_name
                  );
         END;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                p_record_identifier_4      => p_business_group_name
               );
            RETURN x_error_code;
      END get_business_group_id;

--------------------------------------------------------------------------
--------------------------< get_person_type_id >--------------------------
--------------------------------------------------------------------------
      FUNCTION get_person_type_id (
         p_name               IN              VARCHAR2,
         p_user_person_type   IN              VARCHAR2,
         p_person_type_id     OUT NOCOPY      NUMBER,
         p_record_number      IN              NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
      BEGIN
         BEGIN
            IF p_user_person_type IS NOT NULL
            THEN
               SELECT ppt.person_type_id
                 INTO p_person_type_id
                 FROM per_person_types ppt, per_business_groups pbg
                WHERE UPPER (ppt.user_person_type) =
                                                    UPPER (p_user_person_type)
-- commented for integra UPPER (xx_hr_common_pkg.get_mapping_value ('PERSON_TYPE',p_user_person_type))
                  AND ppt.business_group_id = pbg.business_group_id
                  AND UPPER (pbg.NAME) = UPPER (p_name)
-- commented for integra UPPER (xx_hr_common_pkg.get_mapping_value ('BUSINESS_GROUP', p_name))
                  AND TRUNC (SYSDATE) BETWEEN pbg.date_from
                                          AND NVL (pbg.date_to, SYSDATE)
                  AND pbg.enabled_flag = 'Y';

               UPDATE xx_hr_emp_pre
                  SET person_type_id = p_person_type_id
                WHERE record_number = p_record_number;

               COMMIT;
            END IF;                                      -- p_user_person_type
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_person_type_valid,
                   p_error_text               => xx_emf_cn_pkg.cn_person_type_toomany,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                   p_record_identifier_4      => p_user_person_type
                  );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_person_type_valid,
                   p_error_text               => xx_emf_cn_pkg.cn_person_type_nodta_fnd,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                   p_record_identifier_4      => p_user_person_type
                  );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_person_type_valid,
                   p_error_text               => xx_emf_cn_pkg.cn_person_type_invalid,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                   p_record_identifier_4      => p_user_person_type
                  );
         END;                                             -- Second Begin -END

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.cn_success
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => xx_emf_cn_pkg.cn_person_type_valid,
                   p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                   p_record_identifier_4      => p_user_person_type
                  );
            END IF;

            RETURN x_error_code;
      END get_person_type_id;

      ----------------------------- get_country_code----------------------
      FUNCTION get_country_code (p_country IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
      BEGIN
         SELECT territory_code
           INTO p_country
           FROM fnd_territories_vl
          WHERE UPPER(territory_short_name) = UPPER (p_country);

         -- commented for integra UPPER (xx_hr_common_pkg.get_mapping_value ('COUNTRY',p_country));
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => 'COUNTRY-DV001',
                p_error_text               => 'COUNRTY : Too Many Rows',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                p_record_identifier_4      => p_country
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => 'COUNTRY-DV001',
                p_error_text               => 'COUNRTY : No Data Found',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                p_record_identifier_4      => p_country
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => 'COUNTRY-DV001',
                p_error_text               => 'COUNTRY :' || SQLERRM,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                p_record_identifier_4      => p_country
               );
            RETURN x_error_code;
      END get_country_code;
----------------------------------------------
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Data-Derivations');
      x_error_code_temp :=
         get_business_group_id (p_cnv_pre_std_hdr_rec.business_group_name,
                                p_cnv_pre_std_hdr_rec.business_group_id
                               );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.propagate_error (x_error_code_temp);
      -- Commented as ansell we need to check the validation
      --x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );
      --xx_emf_pkg.propagate_error(x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'The user person type for data derivations is '
                            || p_cnv_pre_std_hdr_rec.user_person_type
                           );
      x_error_code_temp :=
         get_person_type_id (p_cnv_pre_std_hdr_rec.business_group_name,
                             p_cnv_pre_std_hdr_rec.user_person_type,
                             p_cnv_pre_std_hdr_rec.person_type_id,
                             p_cnv_pre_std_hdr_rec.record_number
                            );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
                      (xx_emf_cn_pkg.cn_low,
                          'The user person type id after data derivations id '
                       || p_cnv_pre_std_hdr_rec.person_type_id
                      );

      IF p_cnv_pre_std_hdr_rec.country_of_birth IS NOT NULL
      THEN
         x_error_code_temp :=
                    get_country_code (p_cnv_pre_std_hdr_rec.country_of_birth);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      --xx_emf_pkg.propagate_error (x_error_code_temp);
      RETURN x_error_code;
   END data_derivations;
END xx_hr_emp_cnv_validations_pkg; 
/
