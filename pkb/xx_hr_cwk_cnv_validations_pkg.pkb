DROP PACKAGE BODY APPS.XX_HR_CWK_CNV_VALIDATIONS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_CWK_CNV_VALIDATIONS_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    :IBM Development
 Creation Date :21-DEC-2007
 File Name     :XXHRCWKVAL.pkb
 Description   : This script creates the body of the package
                 xx_hr_cwk_cnv_validations_pkg
 Change History:
 Date         Name                Remarks
 -----------  -------------       -----------------------------------
 21-DEC-2007  IBM Development     Initial development.
 06-Jan-2012  Deepika Jain        Changes for Integra
 03-JUL-2012  Arjun K.            Ethnic disclosed is nullable.
*/
----------------------------------------------------------------------
-------------------------< find_max >----------------------------
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
-------------------------< pre_validations >----------------------------
----------------------------------------------------------------------
   FUNCTION pre_validations
--   (p_cnv_hdr_rec IN OUT nocopy xx_hr_emp_conversion_pkg.g_xx_hr_cnv_pre_rec_type)
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
-------------------------< data_validations >----------------------------
----------------------------------------------------------------------
   FUNCTION data_validations (
      p_cnv_hdr_rec   IN OUT NOCOPY   xx_hr_emp_conversion_pkg.g_xx_hr_cnv_pre_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

      --- Local functions for all batch level validations

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
         END IF;

         RETURN x_error_code;
      END set_eit_status;

----------------------------------------------------------------------
--------------------------< is_cwknum_unique >--------------------------
----------------------------------------------------------------------
      FUNCTION is_cwknum_unique (
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
                    p_error_text               => 'Contingent Worker Number Already Exists',
                    p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                    p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                    p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                    p_record_identifier_4      => p_emp_num
                   );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' Contingent Worker Number: '
                               || p_emp_num
                               || ' already exists.'
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_success;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' Contingent Worker Number is unique.'
                                 );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => 'CWKNUM-DV0001',
                   p_error_text               => 'Contingent Worker Number: Too Many Rows',
                   p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                   p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                   p_record_identifier_4      => p_emp_num
                  );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     ' Contingent Worker Number: '
                                  || p_emp_num
                                  || ' too many.'
                                 );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => 'CWKNUM-DV0001',
                p_error_text               =>    'Contingent Worker Number Validation Error '
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                p_record_identifier_4      => p_emp_num
               );
            xx_emf_pkg.write_log
                              (xx_emf_cn_pkg.cn_low,
                                  'Contingent Worker Number Validation Error '
                               || SQLERRM
                              );
            RETURN x_error_code;
      END is_cwknum_unique;

----------------------------------------------------------------------
--------------------------< populate_nullcheck_error >--------------------------
----------------------------------------------------------------------
      PROCEDURE populate_nullcheck_error (p_category IN VARCHAR2)
      IS
      BEGIN
         xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => p_category,
                      p_error_text               => p_category || 'is null',
                      p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                      p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                      p_record_identifier_3      => p_cnv_hdr_rec.user_person_type
                     );
      END populate_nullcheck_error;

----------------------------------------------------------------------
    --------------------------< is_value_not_null >--------------------------
    ----------------------------------------------------------------------
      FUNCTION is_value_not_null (
         p_cnv_hdr_rec   IN   xx_hr_emp_conversion_pkg.g_xx_hr_cnv_pre_rec_type
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
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

         --Commented as per crp2 test on 02-MAY-2012
         --IF p_cnv_hdr_rec.first_name IS NULL THEN
         --   x_error_code := xx_emf_cn_pkg.cn_rec_err;
            --populate_nullcheck_error(g_first_name_category);
         --END IF;
         --Commented as per crp2 test on 03-MAY-2012
         --IF p_cnv_hdr_rec.date_of_birth IS NULL
         --THEN
         --   x_error_code := xx_emf_cn_pkg.cn_rec_err;
         --   populate_nullcheck_error (g_date_of_birth_category);
         --END IF;

         IF p_cnv_hdr_rec.hire_date IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            populate_nullcheck_error (g_hire_date_category);
         END IF;

         --Commented as per crp2 test on 02-MAY-2012
         --IF p_cnv_hdr_rec.email_address IS NULL THEN
         --   x_error_code := xx_emf_cn_pkg.cn_rec_err;
            --populate_nullcheck_error(g_email_address_category);
         --END IF;
         IF p_cnv_hdr_rec.attribute1 IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            populate_nullcheck_error (g_unique_id_category);
         END IF;

         RETURN x_error_code;
      END is_value_not_null;

------------------------------------------------------
---------< is_last_name_not_null >-----------------------
-------------------------------------------------------
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

------------------------------------------------------
---------< is_start_date_not_null >-----------------------
-------------------------------------------------------
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

------------------------------------------------------------
-----------------------< get_business_group_id >--------------
------------------------------------------------------------
      FUNCTION get_business_group_id (
         p_record_number         IN              NUMBER,
         p_business_group_name   IN OUT NOCOPY   VARCHAR2,
         p_business_group_id     OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code            NUMBER         := xx_emf_cn_pkg.cn_success;
         x_bg_id                 VARCHAR2 (40);
         x_business_group_name   VARCHAR2 (100);
      BEGIN
         p_business_group_id := NULL;

         BEGIN
            IF p_business_group_name IS NOT NULL
            THEN
               SELECT pbg.business_group_id, NAME
                 INTO p_business_group_id, x_business_group_name
                 FROM per_business_groups pbg
                WHERE UPPER (pbg.NAME) = UPPER (p_business_group_name)
-- commented for integra UPPER (xx_hr_common_pkg.get_mapping_value('BUSINESS_GROUP',p_business_group_name))
                  AND TRUNC (SYSDATE) BETWEEN date_from AND NVL (date_to,
                                                                 SYSDATE
                                                                );

               p_business_group_name := x_business_group_name;

               UPDATE xx_hr_emp_pre
                  SET business_group_id = p_business_group_id,
                      business_group_name = x_business_group_name
                WHERE record_number = p_record_number;

               COMMIT;
               RETURN x_error_code;
            ELSE
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_business_grp_miss,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_business_group_name
                    );
               RETURN x_error_code;
            END IF;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_business_grp_toomany,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_business_group_name
                    );
               RETURN x_error_code;
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_busigrp_nodta_fnd,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_business_group_name
                    );
               RETURN x_error_code;
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                     p_error_text               => xx_emf_cn_pkg.cn_business_grp_invalid,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_business_group_name
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
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_business_group_name
                    );
               RETURN x_error_code;
            ELSE
               RETURN x_error_code;
            END IF;
      END get_business_group_id;

------------------------------------------------------
-------------< is_title_valid >---------------------------
-------------------------------------------------------
      FUNCTION is_title_valid (p_title IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
      BEGIN
         BEGIN
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

------------------------------------------------------
-------------< is_gender_valid >---------------------------
-------------------------------------------------------
      FUNCTION is_gender_valid (p_sex IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
      BEGIN
         IF p_sex IS NOT NULL THEN
         BEGIN
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

------------------------------------------------------
-------------< is_nationality_valid >-------------------
-------------------------------------------------------
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
-- commented for integra UPPER(xx_hr_common_pkg.get_mapping_value('NATIONALITY',p_nationality))
                  AND LANGUAGE = USERENV ('LANG')
                  AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                  AND NVL (end_date_active, SYSDATE);

               p_nationality := x_variable;
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

------------------------------------------------------
-------------< is_marital_status_valid >-------------------
-------------------------------------------------------
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
                 INTO x_variable
                 FROM fnd_lookup_values
                WHERE lookup_type = 'MAR_STATUS'
                  AND UPPER (meaning) = UPPER (p_marital_status)
-- commented for integra UPPER(xx_hr_common_pkg.get_mapping_value('MARITAL_STATUS',p_marital_status))
                  AND LANGUAGE = USERENV ('LANG')
                  AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                  AND NVL (end_date_active, SYSDATE);

               p_marital_status := x_variable;
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

------------------------------------------------------
-------------< is_orig_date_correct >-------------------
-------------------------------------------------------
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
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'In valid Orig Date');
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
    --------------------------< is_country_valid >-----------------
    ----------------------------------------------------------------------
      FUNCTION is_country_valid (p_source IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         BEGIN
            SELECT lookup_code
              INTO p_source                                       --x_variable
              FROM fnd_lookup_values
             WHERE lookup_type = 'COUNTRY'
               AND UPPER (meaning) = UPPER (p_source)
-- commented for integra xx_hr_common_pkg.get_mapping_value('COUNTRY',p_source)
               AND LANGUAGE = USERENV ('LANG')
               AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                               AND NVL (end_date_active, SYSDATE);
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'COUNTRY-DV001',
                     p_error_text               => 'COUNTRY : Too Many Rows',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_source
                    );
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'COUNTRY-DV001',
                     p_error_text               => 'COUNTRY : No Data Found',
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_source
                    );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'COUNTRY-DV001',
                     p_error_text               =>    'Country Invalid '
                                                   || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_source
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
                     p_category                 => 'COUNTRY-DV001',
                     p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                     p_record_identifier_1      => p_cnv_hdr_rec.attribute1,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_source
                    );
            END IF;

            RETURN x_error_code;
      END is_country_valid;

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
--------------------------< is_new_hire_valid >-----------------
----------------------------------------------------------------
      FUNCTION is_new_hire_valid (p_new_hire IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         BEGIN
            SELECT lookup_code
              INTO p_new_hire                                     --x_variable
              FROM fnd_lookup_values
             WHERE lookup_type = 'US_NEW_HIRE_STATUS'
               AND UPPER (meaning) = UPPER (p_new_hire)
-- commented for integra xx_hr_common_pkg.get_mapping_value('NEW_HIRE_REP',p_new_hire)
               AND LANGUAGE = USERENV ('LANG')
               AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                               AND NVL (end_date_active, SYSDATE);
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
            SELECT lookup_code
              INTO x_ethinc_origin
              FROM fnd_lookup_values
             WHERE lookup_type = 'US_ETHNIC_GROUP'
               AND LANGUAGE = USERENV ('LANG')
               AND UPPER (meaning) = UPPER (p_ethnic_origin)
               AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                               AND NVL (end_date_active, SYSDATE);

            p_ethnic_origin := x_ethinc_origin;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_low,
                     p_category                 => 'ETHNICORIGIN-DV001',
                     p_error_text               => 'Ethnic Origin : Too Many Rows',
                     p_record_identifier_1      => p_cnv_hdr_rec.employee_number,
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
                     p_record_identifier_1      => p_cnv_hdr_rec.employee_number,
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
                     p_record_identifier_1      => p_cnv_hdr_rec.employee_number,
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
                     p_record_identifier_1      => p_cnv_hdr_rec.employee_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_ethnic_origin
                    );
            END IF;

            RETURN x_error_code;
      END is_ethnic_origin_valid;

----------------------------------------------------------------------
--------------------------< is_i9_status_valid >----------------------
----------------------------------------------------------------------
      FUNCTION is_i9_status_valid (p_i9_status IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         BEGIN
            SELECT lookup_code
              INTO p_i9_status                                    --x_variable
              FROM fnd_lookup_values
             WHERE lookup_type = 'PER_US_I9_STATE'
               AND UPPER (meaning) = UPPER (p_i9_status)
-- commented for integra xx_hr_common_pkg.get_mapping_value('I9_STATUS',p_i9_status)
               AND LANGUAGE = USERENV ('LANG')
               AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                               AND NVL (end_date_active, SYSDATE);
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
            SELECT lookup_code
              INTO p_language                                     --x_variable
              FROM fnd_lookup_values
             WHERE lookup_type = 'LANGUAGE'
               AND UPPER (meaning) = UPPER (p_language)
-- commented for integra xx_hr_common_pkg.get_mapping_value('CORRESP_LANG',p_language)
               AND LANGUAGE = USERENV ('LANG')
               AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                               AND NVL (end_date_active, SYSDATE)
               AND ROWNUM = 1;
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

         RETURN x_error_code;
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

------------------------------------------------------
-------------< is_empnum_manual_generation >--------------
-------------------------------------------------------
      FUNCTION is_empnum_manual_generation (p_name IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER                    := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
         p_method       per_business_groups.method_of_generation_emp_num%TYPE;
      BEGIN
         BEGIN
            IF p_name IS NOT NULL
            THEN
               SELECT method_of_generation_cwk_num
                 INTO p_method
                 FROM per_business_groups pbg
                WHERE UPPER (pbg.NAME) = UPPER (p_name)
                  AND TRUNC (SYSDATE) BETWEEN date_from AND NVL (date_to,
                                                                 SYSDATE
                                                                )
                  AND enabled_flag = 'Y';

               -- p_method : M (Manual)  A (Automatic)
               IF p_method = 'A'
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
            ELSE                                             -- P_NAME IS NULL
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
            SELECT lookup_code
              INTO p_ethnic_status                                --x_variable
              FROM hr_lookups
             WHERE lookup_type = 'US_ETHNIC_DISCLOSURE'
               AND UPPER (meaning) = UPPER (p_ethnic_status)
-- commented for integra UPPER (xx_hr_common_pkg.get_mapping_value ('ETHNIC_DISCLOSED',p_ethnic_status))
               AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                               AND NVL (end_date_active, SYSDATE);
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
                     p_record_identifier_1      => p_cnv_hdr_rec.employee_number,
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
                     p_record_identifier_1      => p_cnv_hdr_rec.employee_number,
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
                     p_record_identifier_1      => p_cnv_hdr_rec.employee_number,
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
                     p_record_identifier_1      => p_cnv_hdr_rec.employee_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_veteran_status
                    );
            END IF;

            RETURN x_error_code;
      END is_veteran_100_valid;

       ----------------------------------------------------------------------
--------------------------< is_veteran_100A_valid >-----------------
----------------------------------------------------------------------
      FUNCTION is_veteran_100a_valid (p_veteran_status IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         BEGIN
            SELECT lookup_code
              INTO p_veteran_status                               --x_variable
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
                     p_record_identifier_1      => p_cnv_hdr_rec.employee_number,
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
                     p_record_identifier_1      => p_cnv_hdr_rec.employee_number,
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
                     p_record_identifier_1      => p_cnv_hdr_rec.employee_number,
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
                     p_record_identifier_1      => p_cnv_hdr_rec.employee_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_3      => p_cnv_hdr_rec.user_person_type,
                     p_record_identifier_4      => p_veteran_status
                    );
            END IF;

            RETURN x_error_code;
      END is_veteran_100a_valid;
   --- Start of the main function perform_batch_validations
   --- This will only have calls to the individual functions.
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Data-Validations');
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'is_cwknum_unique');
      x_error_code_temp :=
         is_cwknum_unique (p_cnv_hdr_rec.attribute1,
                           p_cnv_hdr_rec.business_group_name
                          );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp := is_value_not_null (p_cnv_hdr_rec);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp := is_last_name_not_null (p_cnv_hdr_rec.last_name);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp := is_start_date_not_null (p_cnv_hdr_rec.hire_date);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code :=
         get_business_group_id (p_cnv_hdr_rec.record_number,
                                p_cnv_hdr_rec.business_group_name,
                                p_cnv_hdr_rec.business_group_id
                               );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp := is_title_valid (p_cnv_hdr_rec.title);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp := is_gender_valid (p_cnv_hdr_rec.sex);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp := is_nationality_valid (p_cnv_hdr_rec.nationality);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp := set_eit_status (p_cnv_hdr_rec.ethnic_origin);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
                        is_marital_status_valid (p_cnv_hdr_rec.marital_status);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         is_orig_date_correct (p_cnv_hdr_rec.original_date_of_hire,
                               p_cnv_hdr_rec.hire_date
                              );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
               is_empnum_manual_generation (p_cnv_hdr_rec.business_group_name);
      x_error_code := find_max (x_error_code, x_error_code_temp);

       /*IF p_cnv_hdr_rec.veteran_status IS NOT NULL THEN
         x_error_code_temp := is_veteran_status_valid(p_cnv_hdr_rec.veteran_status);
         x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );
      END IF;*/  --commented for integra

      /* IF p_cnv_hdr_rec.source IS NOT NULL THEN
         x_error_code_temp := is_country_valid(p_cnv_hdr_rec.source);
         x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );
      END IF; */
      IF p_cnv_hdr_rec.registered_disabled_flag IS NOT NULL
      THEN
         x_error_code_temp :=
            is_registered_flag_valid (p_cnv_hdr_rec.registered_disabled_flag);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.ethnic_origin IS NOT NULL
      THEN
         x_error_code_temp :=
                         is_ethnic_origin_valid (p_cnv_hdr_rec.ethnic_origin);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.i9_status IS NOT NULL
      THEN
         x_error_code_temp := is_i9_status_valid (p_cnv_hdr_rec.i9_status);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      --Commented during SIT since its non mandatory on 03-JUL-2012
      --IF p_cnv_hdr_rec.ethnicity_disclosed IS NOT NULL
      --THEN
      --   x_error_code_temp :=
      --          is_ethnic_disclosed_valid (p_cnv_hdr_rec.ethnicity_disclosed);
      --   x_error_code := find_max (x_error_code, x_error_code_temp);
      --END IF;

      IF p_cnv_hdr_rec.new_hire_status IS NOT NULL
      THEN
         x_error_code_temp :=
                            is_new_hire_valid (p_cnv_hdr_rec.new_hire_status);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.correspondence_language IS NOT NULL
      THEN
         x_error_code_temp :=
                    is_language_valid (p_cnv_hdr_rec.correspondence_language);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      -- additions for integra - start
      IF p_cnv_hdr_rec.vets_100 IS NOT NULL
      THEN
         x_error_code_temp := is_veteran_100_valid (p_cnv_hdr_rec.vets_100);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.vets_100a IS NOT NULL
      THEN
         x_error_code_temp := is_veteran_100a_valid (p_cnv_hdr_rec.vets_100a);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      -- additions for integra - end
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

------------------------------------------------------------
-----------------------< post_validations >--------------
------------------------------------------------------------
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

------------------------------------------------------------
-----------------------< data_derivations >--------------
------------------------------------------------------------
   FUNCTION data_derivations (
      p_cnv_pre_std_hdr_rec   IN OUT NOCOPY   xx_hr_emp_conversion_pkg.g_xx_hr_cnv_pre_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

-- ******************************************************************************
--                           Function to get_target_job_id
-- ******************************************************************************
      FUNCTION get_person_type_id (
         p_user_person_type    IN OUT NOCOPY   VARCHAR2,
         p_person_type_id      OUT NOCOPY      NUMBER,
         p_business_group_id   IN              NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         p_person_type_id := NULL;

         BEGIN
            IF p_user_person_type IS NOT NULL
            THEN
               SELECT person_type_id, user_person_type
                 INTO p_person_type_id, p_user_person_type
                 FROM per_person_types
                WHERE user_person_type = p_user_person_type
-- commented for integra xx_hr_common_pkg.get_mapping_value('PERSON_TYPE',p_user_person_type)
                  AND business_group_id = p_business_group_id;

               RETURN x_error_code;
            ELSE
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => 'PRSTYP-DV01',
                   p_error_text               => 'User person type is null',
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                   p_record_identifier_4      => p_user_person_type
                  );
               RETURN x_error_code;
            END IF;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => 'PRSTYP-DV01',
                   p_error_text               => 'Multiple person types found',
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                   p_record_identifier_4      => p_user_person_type
                  );
               RETURN x_error_code;
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => 'PRSTYP-DV01',
                   p_error_text               => 'User person type not found',
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                   p_record_identifier_4      => p_user_person_type
                  );
               RETURN x_error_code;
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => 'PRSTYP-DV01',
                   p_error_text               => 'User person type is invalid',
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                   p_record_identifier_4      => p_user_person_type
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
                   p_category                 => 'PRSTYP-DV01',
                   p_error_text               => 'User person type is invalid',
                   p_record_identifier_1      => p_cnv_pre_std_hdr_rec.attribute1,
                   p_record_identifier_2      => p_cnv_pre_std_hdr_rec.record_number,
                   p_record_identifier_3      => p_cnv_pre_std_hdr_rec.user_person_type,
                   p_record_identifier_4      => p_user_person_type
                  );
               RETURN x_error_code;
            ELSE
               RETURN x_error_code;
            END IF;
      END get_person_type_id;

      ------------------------------------------------------------
      ----------------------------- get_country_code--------------
      ------------------------------------------------------------
      FUNCTION get_country_code (p_country IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
      BEGIN
         SELECT territory_code
           INTO p_country
           FROM fnd_territories_vl
          WHERE UPPER (territory_short_name) = UPPER (p_country);

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
----------------------------------------------------------------------
   BEGIN
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                            'The user person type after data derivations is '
                         || p_cnv_pre_std_hdr_rec.user_person_type
                        );
      x_error_code :=
         get_person_type_id (p_cnv_pre_std_hdr_rec.user_person_type,
                             p_cnv_pre_std_hdr_rec.person_type_id,
                             p_cnv_pre_std_hdr_rec.business_group_id
                            );

      --  x_error_code := xx_emf_cn_pkg.cn_success ;
      IF p_cnv_pre_std_hdr_rec.country_of_birth IS NOT NULL
      THEN
         x_error_code_temp :=
                    get_country_code (p_cnv_pre_std_hdr_rec.country_of_birth);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      --xx_emf_pkg.propagate_error (x_error_code_temp);
      RETURN x_error_code;
   END data_derivations;

---------------------------------------------------------------------------------------------------

   -- This following function is not a part of any process status of the EMF. This does NOT fall under data validation, data deriveation, pre-val or post-val.
   -- This is independent functional called before the API for CWK is invoked to find the user person type id

   -- The reason for this is that any contingent worker should be created with a person type as the exact value being
   -- passed in data file eg. Independent Contractor, Consultant, Agency Temp etc.
   -- and the code had initially changed it to 'Contingent Worker' for validation purposes and respective API invocation.
   FUNCTION get_cwk_orig_per_type_id (
      p_record_number       IN   NUMBER,
      p_batch_id            IN   VARCHAR2,
      p_business_group_id   IN   NUMBER
   )
      RETURN NUMBER
   IS
      x_person_type_id       NUMBER;
      x_system_person_type   VARCHAR2 (5) := 'CWK';
      x_active_flag          VARCHAR2 (1) := 'Y';
   BEGIN
      SELECT person_type_id
        INTO x_person_type_id
        FROM per_person_types
       WHERE UPPER (user_person_type) =
                (SELECT UPPER (user_person_type)
                   FROM xx_hr_emp_stg
                  WHERE record_number = p_record_number
                    AND batch_id = p_batch_id)
         AND business_group_id = p_business_group_id
         AND system_person_type = x_system_person_type
         AND active_flag = x_active_flag;

      RETURN x_person_type_id;
   EXCEPTION
      --- The following exceptions will not raise any issues apart from setting the values as the API will error the record out in case of
      --- null person type id. The reason for this is that any contingent worker should be created with a person type as the exact value being
      --- passed in data file eg. Independent Contractor, Consultant, Agency Temp etc.
      WHEN TOO_MANY_ROWS
      THEN
         x_person_type_id := NULL;
         RETURN x_person_type_id;
      WHEN NO_DATA_FOUND
      THEN
         x_person_type_id := NULL;
         RETURN x_person_type_id;
      WHEN OTHERS
      THEN
         x_person_type_id := NULL;
         RETURN x_person_type_id;
   END get_cwk_orig_per_type_id;
-- END Code validation added to pick the person type id of the exact user person type provided in data file
END xx_hr_cwk_cnv_validations_pkg;
/
