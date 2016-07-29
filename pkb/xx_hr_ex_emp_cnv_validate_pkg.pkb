DROP PACKAGE BODY APPS.XX_HR_EX_EMP_CNV_VALIDATE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_EX_EMP_CNV_VALIDATE_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Vasavi Chaikam
 Creation Date : 09-Mar-2012
 File Name     : XX_HR_EX_EMP_VAL.pkb
 Description   : This script creates the body of the package
                 xx_hr_emp_cnv_validations_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------    -----------------------------------
 30-Oct-2007 IBM Development    Initial document.
 09-Mar-2012 Vasavi Chaikam    Changes done as per Integra
 27-Mar-2012 Vasavi             Change implemented for Final_process_date
*/
----------------------------------------------------------------------

----------------------------------------------------------------------
------------------------< find_max >------------------------
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
------------------------< pre_validations >------------------------
----------------------------------------------------------------------
   FUNCTION pre_validations
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
------------------------< data_validations >------------------------
----------------------------------------------------------------------
   FUNCTION data_validations (
      p_cnv_hdr_rec   IN OUT NOCOPY   xx_hr_ex_emp_conversion_pkg.g_xx_hr_ex_cnv_pre_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

      --- Local functions for all batch level validations
      --- Add as many functions as required in her

----------------------------------------------------------------------
------------------------< get_business_group_id >------------------------
----------------------------------------------------------------------
      FUNCTION get_business_group_id (
         p_business_group_name   IN              VARCHAR2,
         p_business_group_id     OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code            NUMBER           := xx_emf_cn_pkg.cn_success;
         x_bg_id                 VARCHAR2 (40);
         x_count                 NUMBER;
         x_business_group_name   per_business_groups.NAME%TYPE;
      BEGIN
         p_business_group_id := NULL;
         fnd_file.put_line
                  (fnd_file.LOG,
                      'Start of get_business_group_id Business Group name : '
                   || p_business_group_name
                  );

         BEGIN
            IF p_business_group_name IS NOT NULL
            THEN
               SELECT pbg.business_group_id
                 INTO p_business_group_id
                 FROM per_business_groups pbg
                WHERE UPPER (pbg.NAME) = UPPER (p_business_group_name)
                  AND TRUNC (SYSDATE) BETWEEN date_from AND NVL (date_to,
                                                                 SYSDATE
                                                                );

               RETURN x_error_code;
               fnd_file.put_line (fnd_file.LOG,
                                     'after business group id derived: '
                                  || p_business_group_id
                                 );
               xx_emf_pkg.write_log
                      (xx_emf_cn_pkg.cn_low,
                          'After deriving thebusiness group id: x_error_code '
                       || x_error_code
                      );
            ELSE
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_low,
                        p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                        p_error_text               => xx_emf_cn_pkg.cn_business_grp_miss,
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.unique_id,
                        p_record_identifier_3      => p_business_group_name
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
                       p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                       p_record_identifier_2      => p_cnv_hdr_rec.unique_id,
                       p_record_identifier_3      => p_business_group_name
                      );
               RETURN x_error_code;
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_low,
                        p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                        p_error_text               => xx_emf_cn_pkg.cn_busigrp_nodta_fnd,
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.unique_id,
                        p_record_identifier_3      => p_business_group_name
                       );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     x_error_code := xx_emf_cn_pkg.cn_rec_err;
                     xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_low,
                         p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                         p_error_text               =>    'Business Group Error '
                                                       || SQLERRM,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.unique_id,
                         p_record_identifier_3      => p_business_group_name
                        );
               END;

               RETURN x_error_code;
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                      (p_severity                 => xx_emf_cn_pkg.cn_low,
                       p_category                 => xx_emf_cn_pkg.cn_busgrp_valid,
                       p_error_text               => xx_emf_cn_pkg.cn_business_grp_invalid,
                       p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                       p_record_identifier_2      => p_cnv_hdr_rec.unique_id,
                       p_record_identifier_3      => p_business_group_name
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
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.unique_id,
                        p_record_identifier_3      => p_business_group_name
                       );
               RETURN x_error_code;
            ELSE
               RETURN x_error_code;
            END IF;
      END get_business_group_id;

----------------------------------------------------------------------
----------------< is_actual_termination_date >------------------------
----------------------------------------------------------------------
      FUNCTION is_actual_termination_date (p_actual_termination_date IN DATE)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_actual_termination_date IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_low,
                        p_category                 => 'Actual_Term_Date',
                        p_error_text               => 'Actual Termination Date is NULL',
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.unique_id,
                        p_record_identifier_3      => p_actual_termination_date
                       );
         END IF;

         RETURN x_error_code;
      END is_actual_termination_date;

----------------------------------------------------------------------
----------------< is_final_process_date >------------------------
----------------------------------------------------------------------
      FUNCTION is_final_process_date(p_final_process_date IN DATE)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_final_process_date IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_low,
                        p_category                 => 'Final_process_date',
                        p_error_text               => 'Final Process Date is NULL',
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.unique_id,
                        p_record_identifier_3      => p_final_process_date
                       );
         END IF;

         RETURN x_error_code;
      END is_final_process_date;


----------------------------------------------------------------------
----------------< is_person_type >------------------------
----------------------------------------------------------------------
      FUNCTION is_person_type (p_person_type IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_person_type IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_low,
                        p_category                 => 'Person_type',
                        p_error_text               => 'person type is NULL',
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.unique_id,
                        p_record_identifier_3      => p_person_type
                       );
         END IF;

         RETURN x_error_code;
      END is_person_type;

----------------------------------------------------------------------
----------------< is_employee_number >------------------------
----------------------------------------------------------------------
      FUNCTION is_employee_number (p_employee_number IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_employee_number IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_low,
                        p_category                 => 'Employee_number',
                        p_error_text               => 'Employee Number is NULL',
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.unique_id,
                        p_record_identifier_3      => p_employee_number
                       );
         END IF;

         RETURN x_error_code;
      END is_employee_number;

----------------------------------------------------------------------
----------------< is_unique_id >------------------------
----------------------------------------------------------------------
      FUNCTION is_unique_id (p_unique_id IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_unique_id IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_low,
                        p_category                 => 'unique_id',
                        p_error_text               => 'unique_id is NULL',
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.unique_id,
                        p_record_identifier_3      => p_unique_id
                       );
         END IF;

         RETURN x_error_code;
      END is_unique_id;

----------------------------------------------------------------------
----------------< is_last_name >------------------------
----------------------------------------------------------------------
      FUNCTION is_last_name (p_last_name IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_last_name IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_low,
                        p_category                 => 'last_name',
                        p_error_text               => 'last_name is NULL',
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.unique_id,
                        p_record_identifier_3      => p_last_name
                       );
         END IF;

         RETURN x_error_code;
      END is_last_name;

----------------------------------------------------------------------
----------------< is_leaving_reason >------------------------
----------------------------------------------------------------------
      FUNCTION is_leaving_reason (p_leaving_reason IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_leaving_reason IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_low,
                        p_category                 => 'leaving_reason',
                        p_error_text               => 'leaving_reason is NULL',
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.unique_id,
                        p_record_identifier_3      => p_leaving_reason
                       );
         END IF;

         RETURN x_error_code;
      END is_leaving_reason;

----------------------------------------------------------------------
----------------< is_user_person_type >------------------------
----------------------------------------------------------------------
      FUNCTION is_user_person_type (p_user_person_type IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_user_person_type IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_low,
                        p_category                 => 'user_person_type',
                        p_error_text               => 'user_person_type is NULL',
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.unique_id,
                        p_record_identifier_3      => p_user_person_type
                       );
         END IF;

         RETURN x_error_code;
      END is_user_person_type;

----------------------------------------------------------------------
----------------< is_term_user_status >------------------------
----------------------------------------------------------------------
      FUNCTION is_term_user_status (p_term_user_status IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_term_user_status IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_low,
                        p_category                 => 'term_user_status ',
                        p_error_text               => 'term_user_status is NULL',
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.unique_id,
                        p_record_identifier_3      => p_term_user_status
                       );
         END IF;

         RETURN x_error_code;
      END is_term_user_status;
      --- Start of the main function perform_batch_validations
      --- This will only have calls to the individual functions.
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Data-Validations');

      x_error_code_temp :=
         get_business_group_id (p_cnv_hdr_rec.business_group_name,
                                p_cnv_hdr_rec.business_group_id
                               );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'After get_business_group_id: x_error_code '
                            || x_error_code
                           );

      x_error_code_temp :=
            is_actual_termination_date (p_cnv_hdr_rec.actual_termination_date);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
                         (xx_emf_cn_pkg.cn_low,
                             'After is_actual_termination_date: x_error_code '
                          || x_error_code
                         );

      x_error_code_temp :=
                  is_final_process_date (p_cnv_hdr_rec.final_process_date);
      x_error_code := find_max (x_error_code, x_error_code_temp);

      x_error_code_temp := is_last_name (p_cnv_hdr_rec.last_name);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'After is_last_name: x_error_code '
                            || x_error_code
                           );

      x_error_code_temp := is_person_type (p_cnv_hdr_rec.person_type);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'After is_person_type: x_error_code '
                            || x_error_code
                           );

      x_error_code_temp := is_employee_number (p_cnv_hdr_rec.employee_number);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'After is_employee_number: x_error_code '
                            || x_error_code
                           );

      x_error_code_temp := is_unique_id (p_cnv_hdr_rec.unique_id);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'After is_unique_id: x_error_code '
                            || x_error_code
                           );

      x_error_code_temp := is_leaving_reason (p_cnv_hdr_rec.leaving_reason);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'After is_leaving_reason: x_error_code '
                            || x_error_code
                           );

      x_error_code_temp :=
                          is_user_person_type (p_cnv_hdr_rec.user_person_type);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'After is_user_person_type: x_error_code '
                            || x_error_code
                           );

      x_error_code_temp :=
                          is_term_user_status (p_cnv_hdr_rec.term_user_status);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'After is_term_user_status: x_error_code '
                            || x_error_code
                           );

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
------------------------< post_validations >------------------------
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
------------------------< data_derivations >------------------------
----------------------------------------------------------------------
   FUNCTION data_derivations (
      p_cnv_pre_std_hdr_rec   IN OUT NOCOPY   xx_hr_ex_emp_conversion_pkg.g_xx_hr_ex_cnv_pre_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

----------------------------------------------------------------------
------------------------< get_reason_code >------------------------
----------------------------------------------------------------------
      FUNCTION get_reason_code (
         p_leaving_reason        IN              VARCHAR2,
         p_leaving_reason_code   OUT NOCOPY      VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code           NUMBER         := xx_emf_cn_pkg.cn_success;
         x_bg_id                VARCHAR2 (40);
      BEGIN

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' g_lookup_type ' || g_lookup_type
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' p_leaving_reason '
                               || p_leaving_reason
                              );

         SELECT lookup_code
           INTO p_leaving_reason_code
           FROM hr_lookups
          WHERE lookup_type = g_lookup_type
            AND TRIM (UPPER (meaning)) = TRIM (UPPER (p_leaving_reason))
            AND enabled_flag = g_yes
            AND trunc(SYSDATE) BETWEEN trunc(NVL(start_date_active,SYSDATE-1))
                                   AND trunc(NVL(end_date_active,SYSDATE+1));

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' p_leaving_reason_code '
                               || p_leaving_reason_code
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_lerresc_too,
                p_error_text               => xx_emf_cn_pkg.cn_lerrest_too,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.unique_id,
                p_record_identifier_3      => p_leaving_reason
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_lerresc_no,
                p_error_text               => xx_emf_cn_pkg.cn_lerrest_no,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.unique_id
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_lerresc_ivd,
                p_error_text               => xx_emf_cn_pkg.cn_lerrest_ivd,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.unique_id
               );
            RETURN x_error_code;
      END get_reason_code;

----------------------------------------------------------------------
------------------------< get_person_type_id >------------------------
----------------------------------------------------------------------
      FUNCTION get_person_type_id (
         p_person_type         IN              VARCHAR2,
         p_business_group_id   IN              NUMBER,
         p_person_type_id      OUT NOCOPY      VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_bg_id        VARCHAR2 (40);

      BEGIN

         SELECT person_type_id
           INTO p_person_type_id
           FROM per_person_types
          WHERE business_group_id = p_business_group_id
            AND default_flag = g_yes
            AND active_flag = g_yes
            AND UPPER(system_person_type) = UPPER(g_person_type);

         RETURN x_error_code;
      EXCEPTION
      WHEN TOO_MANY_ROWS
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.CN_PERSON_TYPE_TOOMANY,
                      p_error_text               => xx_emf_cn_pkg.CN_PERSON_TYPE_TOOMANY,
                      p_record_identifier_1      => p_cnv_pre_std_hdr_rec.record_number,
                      p_record_identifier_2      => p_cnv_pre_std_hdr_rec.unique_id,
                      p_record_identifier_3      => p_person_type
                     );
                  RETURN x_error_code;
               WHEN NO_DATA_FOUND
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.CN_PERSON_TYPE_NODTA_FND,
                      p_error_text               => xx_emf_cn_pkg.CN_PERSON_TYPE_NODTA_FND,
                      p_record_identifier_1      => p_cnv_pre_std_hdr_rec.record_number,
                      p_record_identifier_2      => p_cnv_pre_std_hdr_rec.unique_id
                     );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.cn_pertypec_ivd,
                p_error_text               => 'Invalid Person type id',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.unique_id
               );
            RETURN x_error_code;
      END get_person_type_id;

----------------------------------------------------------------------
------------------------< get_assignment_status_type_id >------------------------
----------------------------------------------------------------------
      FUNCTION get_assignment_status_type_id (
         p_user_term_status            IN              VARCHAR2,
         p_assignment_status_type_id   OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         SELECT assignment_status_type_id
           INTO p_assignment_status_type_id
           FROM per_assignment_status_types
          WHERE UPPER (user_status) = UPPER (p_user_term_status)
            AND default_flag = g_yes
            AND active_flag = g_yes;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'inside  get_assignment_status_type_id:'
                               || p_assignment_status_type_id
                              );
         RETURN x_error_code;
      EXCEPTION
      WHEN TOO_MANY_ROWS
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.CN_ASSIGNMENT_STATUS_TOMNY,
                      p_error_text               => xx_emf_cn_pkg.CN_ASSIGNMENT_STATUS_TOMNY,
                      p_record_identifier_1      => p_cnv_pre_std_hdr_rec.record_number,
                      p_record_identifier_2      => p_cnv_pre_std_hdr_rec.unique_id,
                      p_record_identifier_3      => p_user_term_status
                     );
                  RETURN x_error_code;
               WHEN NO_DATA_FOUND
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.CN_ASSIGNMENT_STATUS_NODATA,
                      p_error_text               => xx_emf_cn_pkg.CN_ASSIGNMENT_STATUS_NODATA,
                      p_record_identifier_1      => p_cnv_pre_std_hdr_rec.record_number,
                      p_record_identifier_2      => p_cnv_pre_std_hdr_rec.unique_id
                     );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.CN_ASSIGNMNT_ID_ID_VALID,
                p_error_text               =>    'Invalid assignment status type id'
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.unique_id
               );
            RETURN x_error_code;
      END get_assignment_status_type_id;

----------------------------------------------------------------------
--------------------------<  get_ids  >--------------------------
----------------------------------------------------------------------
      FUNCTION get_ids (
         p_business_group_id       IN              NUMBER,
         p_unique_id               IN              VARCHAR2,
         p_object_version_number   OUT NOCOPY      NUMBER,
         p_period_of_service_id    OUT NOCOPY      NUMBER,
         p_person_id               OUT NOCOPY      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code              NUMBER := xx_emf_cn_pkg.cn_success;
         x_object_version_number   NUMBER;
         x_period_of_service_id    NUMBER;
         x_person_id               NUMBER;
         x_date_start              DATE;
      BEGIN
         IF p_unique_id IS NOT NULL
         THEN
            SELECT pps.period_of_service_id, pps.object_version_number
              INTO x_period_of_service_id, x_object_version_number
              FROM per_periods_of_service pps, per_all_people_f papf
             WHERE pps.person_id = papf.person_id
               AND papf.attribute1 = p_unique_id
               AND papf.business_group_id = p_business_group_id
               AND TRUNC (pps.date_start) BETWEEN TRUNC(papf.effective_start_date)
                                              AND TRUNC(papf.effective_end_date)
               AND pps.actual_termination_date IS NULL;
         END IF;

         p_object_version_number := x_object_version_number;
         p_period_of_service_id := x_period_of_service_id;
         p_person_id := x_person_id;

         RETURN x_error_code;
      EXCEPTION
      WHEN TOO_MANY_ROWS
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.CN_TOO_MANY,
                      p_error_text               => xx_emf_cn_pkg.CN_TOO_MANY,
                      p_record_identifier_1      => p_cnv_pre_std_hdr_rec.record_number,
                      p_record_identifier_2      => p_cnv_pre_std_hdr_rec.unique_id,
                      p_record_identifier_3      => p_unique_id
                     );
                  RETURN x_error_code;
               WHEN NO_DATA_FOUND
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.CN_NO_DATA,
                      p_error_text               => xx_emf_cn_pkg.CN_NO_DATA,
                      p_record_identifier_1      => p_cnv_pre_std_hdr_rec.record_number,
                      p_record_identifier_2      => p_cnv_pre_std_hdr_rec.unique_id
                     );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_low,
                p_category                 => xx_emf_cn_pkg.CN_EMPNUM_VALID,
                p_error_text               => 'Invalid Employee or Employee is already terminated',
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.unique_id
               );
            RETURN x_error_code;
      END get_ids;
----------------------------------------------------------------------------
   BEGIN
      x_error_code_temp :=
         get_reason_code (p_cnv_pre_std_hdr_rec.leaving_reason,
                          p_cnv_pre_std_hdr_rec.leaving_reason_code
                         );
      x_error_code := find_max (x_error_code, x_error_code_temp);

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'After  get_reason code:' || x_error_code
                           );

      x_error_code_temp :=
         get_person_type_id (p_cnv_pre_std_hdr_rec.user_person_type,
                             p_cnv_pre_std_hdr_rec.business_group_id,
                             p_cnv_pre_std_hdr_rec.person_type_id
                            );
      x_error_code := find_max (x_error_code, x_error_code_temp);

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'After  get_person_type_id:' || x_error_code
                           );

      x_error_code_temp :=
         get_assignment_status_type_id
                              (p_cnv_pre_std_hdr_rec.term_user_status,
                               p_cnv_pre_std_hdr_rec.assignment_status_type_id
                              );
      x_error_code := find_max (x_error_code, x_error_code_temp);

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'TERM_USER_STATUS_id'
                            || p_cnv_pre_std_hdr_rec.assignment_status_type_id
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'After  get_assignment_status_type_id:'
                            || x_error_code
                           );

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'p_cnv_pre_std_hdr_rec.employee_number:'
                            || p_cnv_pre_std_hdr_rec.unique_id
                           );
      x_error_code_temp :=
         get_ids (p_cnv_pre_std_hdr_rec.business_group_id,
                  p_cnv_pre_std_hdr_rec.unique_id,
                  p_cnv_pre_std_hdr_rec.object_version_number,
                  p_cnv_pre_std_hdr_rec.period_of_service_id,
                  p_cnv_pre_std_hdr_rec.person_id
                 );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'After  get_ids:' || x_error_code
                           );
      x_error_code := find_max (x_error_code, x_error_code_temp);


      RETURN x_error_code;
   END data_derivations;
END xx_hr_ex_emp_cnv_validate_pkg;
/
