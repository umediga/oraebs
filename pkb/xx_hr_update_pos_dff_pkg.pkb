DROP PACKAGE BODY APPS.XX_HR_UPDATE_POS_DFF_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_UPDATE_POS_DFF_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : VASAVI
 Creation Date : 02-apr-2012
 File Name     : XX_HR_UPDATE_POS_DFF.pkb
 Description   : This script creates the specification of the package
                 XX_HR_UPDATE_POS_DFF_PKG
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 02-Apr-2012 Vasavi               Initial Version
 01-Aug-2012 Vasavi               Removed the utl_read_insert_stg proc and related sub procedures
*/
 ----------------------------------------------------------------------

   -----------------------------------------------------------
-------------find_max---------------------------------------
------------------------------------------------------------
   FUNCTION find_max (p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2)
      RETURN VARCHAR2
   IS
      x_return_value   VARCHAR2 (100);
   BEGIN
      x_return_value :=
                   xx_intg_common_pkg.find_max (p_error_code1, p_error_code2);
      RETURN x_return_value;
   END find_max;

-- --------------------------------------------------------------------- --
-- This procedure will update the new records for processing
-----------------------------------------------------------
-------------mark_records_for_processing-------------------
------------------------------------------------------------
   PROCEDURE mark_records_for_processing (
      p_reprocess        IN   VARCHAR2,
      p_requestid        IN   NUMBER,
      --p_file_name        IN   VARCHAR2, --commented by vasavi aug 01 2012
      p_restart_flag     IN   VARCHAR2,
      p_business_group   IN   VARCHAR2
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'In Calling mark_records_for_processing..'
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'mark_records_for_processing :'
                            || xx_emf_pkg.g_request_id
                            || ' - '
                            || xx_emf_cn_pkg.cn_null
                            || ' - '
                            || xx_emf_cn_pkg.cn_new
                           );

      IF NVL (p_reprocess, 'N') = 'Y'
      THEN
         IF p_restart_flag = xx_emf_cn_pkg.cn_all_recs
         THEN
            xx_emf_pkg.write_log
                              (xx_emf_cn_pkg.cn_low,
                               'Calling mark_records_for_processing..All Rec'
                              );
            xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                   'mark_records_for_processing..All Rec 1 ->'
                                || xx_emf_pkg.g_request_id
                                || ' - '
                                || xx_emf_cn_pkg.cn_null
                                || ' - '
                                || xx_emf_cn_pkg.cn_new
                               );

            UPDATE xx_hr_update_position_dff_stg
               SET ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new,
                   request_id = xx_emf_pkg.g_request_id
             WHERE request_id = NVL (p_requestid, request_id)
--               AND file_name = NVL (p_file_name, file_name) --commented by vasavi aug 01 2012
               AND business_group = p_business_group;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'mark_records_for_processing..All Rec 2'
                                 );
         ELSIF p_restart_flag = xx_emf_cn_pkg.cn_err_recs
         THEN
            xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                             'Calling mark_records_for_processing..Error Rec'
                            );

            UPDATE xx_hr_update_position_dff_stg
               SET ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new,
                   request_id = xx_emf_pkg.g_request_id
             WHERE ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_rec_warn, xx_emf_cn_pkg.cn_rec_err)
               AND request_id = NVL (p_requestid, request_id)
--               AND file_name = NVL (p_file_name, file_name) --commented by vasavi aug 01 2012
               AND business_group = p_business_group;
         END IF;
      ELSIF NVL (p_reprocess, 'N') = 'N'
      THEN
         xx_emf_pkg.write_log
                   (xx_emf_cn_pkg.cn_low,
                    'Calling mark_records_for_processing with out re process'
                   );

         UPDATE xx_hr_update_position_dff_stg
            SET request_id = xx_emf_pkg.g_request_id,
                process_code = xx_emf_cn_pkg.cn_new
          WHERE ERROR_CODE IS NULL AND business_group = p_business_group;
      END IF;

      COMMIT;
   END mark_records_for_processing;

-----------------------------------------------------------
    -------------set_stage-------------------
------------------------------------------------------------
   PROCEDURE set_stage (p_stage VARCHAR2)
   IS
   BEGIN
      g_stage := p_stage;
   END set_stage;

-----------------------------------------------------------
-------------update_staging_records-------------------
------------------------------------------------------------

   -- Cross Updating the stagin table
   PROCEDURE update_staging_records (
      p_error_code            VARCHAR2,
      p_business_group   IN   VARCHAR2
   )
   IS
      x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE xx_hr_update_position_dff_stg
         SET process_code = g_stage,
             ERROR_CODE = p_error_code
                                      --DECODE ( error_code, NULL, p_error_code, error_code)
      ,
             creation_date = SYSDATE,
             created_by = fnd_global.user_id,
             last_update_date = SYSDATE,
             last_updated_by = fnd_global.user_id,
             last_update_login = x_last_update_login
       WHERE request_id = xx_emf_pkg.g_request_id
         AND process_code = xx_emf_cn_pkg.cn_new
         AND business_group = p_business_group;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Error while Updating STAGE status : '
                               || SQLERRM
                              );
   END update_staging_records;

-----------------------------------------------------------
-------------post_validations-------------------
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
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Completed Post-Validations'
                              );
   END post_validations;

-----------------------------------------------------------
-------------update_record_count-------------------
------------------------------------------------------------
   PROCEDURE update_record_count
   IS
      CURSOR c_get_total_cnt
      IS
         SELECT COUNT (1) total_count
           FROM xx_hr_update_position_dff_stg
          WHERE request_id = xx_emf_pkg.g_request_id;

      x_total_cnt     NUMBER;

      CURSOR c_get_error_cnt
      IS
         SELECT SUM (error_count)
           FROM (SELECT COUNT (1) error_count
                   FROM xx_hr_update_position_dff_stg
                  WHERE request_id = xx_emf_pkg.g_request_id
                    AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err);

      x_error_cnt     NUMBER;

      CURSOR c_get_warning_cnt
      IS
         SELECT COUNT (1) warn_count
           FROM xx_hr_update_position_dff_stg
          WHERE request_id = xx_emf_pkg.g_request_id
            AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

      x_warn_cnt      NUMBER;

      CURSOR c_get_success_cnt
      IS
         SELECT COUNT (1) success_count
           FROM xx_hr_update_position_dff_stg
          WHERE request_id = xx_emf_pkg.g_request_id
            AND process_code = xx_emf_cn_pkg.cn_process_data
            AND ERROR_CODE = xx_emf_cn_pkg.cn_success;

      x_success_cnt   NUMBER;
   BEGIN
      OPEN c_get_total_cnt;

      FETCH c_get_total_cnt
       INTO x_total_cnt;

      CLOSE c_get_total_cnt;

      OPEN c_get_error_cnt;

      FETCH c_get_error_cnt
       INTO x_error_cnt;

      CLOSE c_get_error_cnt;

      OPEN c_get_warning_cnt;

      FETCH c_get_warning_cnt
       INTO x_warn_cnt;

      CLOSE c_get_warning_cnt;

      OPEN c_get_success_cnt;

      FETCH c_get_success_cnt
       INTO x_success_cnt;

      CLOSE c_get_success_cnt;

      xx_emf_pkg.update_recs_cnt (p_total_recs_cnt        => x_total_cnt,
                                  p_success_recs_cnt      => x_success_cnt,
                                  p_warning_recs_cnt      => x_warn_cnt,
                                  p_error_recs_cnt        => x_error_cnt
                                 );
   END update_record_count;

-----------------------------------------------------------
-------------pre_validations-------------------
------------------------------------------------------------
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
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Completed Pre-Validations'
                              );
   END pre_validations;

-----------------------------------------------------------
-------------data_validations-------------------
------------------------------------------------------------
   FUNCTION data_validations (
      p_update_pos_rec   IN OUT   g_xx_hr_update_posdff_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER          := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER          := xx_emf_cn_pkg.cn_success;
      x_error_message     VARCHAR2 (3000);
      x_err_mesg          VARCHAR2 (3000);
      x_segments          VARCHAR (1000);

--------------------------------------------------------------------------
-- Effective Date Validation
--------------------------------------------------------------------------
      FUNCTION is_effective_date (
         p_effective_date   IN       DATE,
         p_position_name    IN VARCHAR2,
         p_err_mesg         OUT      VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         x_effective_date hr_all_positions_f.EFFECTIVE_START_DATE%TYPE;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Effective Date  => ' || p_effective_date
                              );
        BEGIN

        SELECT EFFECTIVE_START_DATE into
        x_effective_date
        FROM hr_all_positions_f
        WHERE name=p_position_name
        AND EFFECTIVE_END_DATE=to_date('12/31/4712','mm/dd/yyyy');

       IF p_effective_date IS NULL
         THEN
            xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_low,
                    p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                    p_error_text               => 'Effective Date can not be null',
                    p_record_identifier_1      => p_update_pos_rec.business_group,
                    p_record_identifier_2      => p_update_pos_rec.position_name,
                    p_record_identifier_3      => p_update_pos_rec.effective_date
                   );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            p_err_mesg := 'Effective Date can not be null' || p_effective_date;

            ELSIF p_effective_date < x_effective_date THEN

            xx_emf_pkg.error
	                       (p_severity                 => xx_emf_cn_pkg.cn_low,
	                        p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
	                        p_error_text               => 'Effective Date is prior to the effective date of the position ',
	                        p_record_identifier_1      => p_update_pos_rec.business_group,
	                        p_record_identifier_2      => p_update_pos_rec.position_name,
	                        p_record_identifier_3      => p_update_pos_rec.effective_date
	                       );
	                x_error_code := xx_emf_cn_pkg.cn_rec_err;
	                p_err_mesg := 'Effective Date is prior to the effective date of the position ' || p_effective_date;


         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'is_effective_date: Success =>'
                               || p_effective_date
                              );

          END;
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid effective date' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid effectivedate=>'
                                                   || p_effective_date
                                                   || '-'
                                                   || SQLERRM,
                     p_record_identifier_1      => p_update_pos_rec.business_group,
                     p_record_identifier_2      => p_update_pos_rec.position_name,
                     p_record_identifier_3      => p_update_pos_rec.effective_date
                    );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE Effective Date '
                                  || x_error_code
                                 );
            p_err_mesg := 'Invalid Effective Date';
            RETURN x_error_code;
      END is_effective_date;

-- --------------------------------------------------------------------- --
-- Business Group Name Validation
----------------------------------------------------------------------------
      FUNCTION is_business_group (
         p_business_group      IN       VARCHAR2,
         p_err_mesg            OUT      VARCHAR2,
         p_business_group_id   OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      --x_period_name         VARCHAR2(15);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'business_group  => ' || p_business_group
                              );

         IF p_business_group IS NOT NULL
         THEN
            SELECT business_group_id
              INTO p_business_group_id
              FROM per_business_groups
             WHERE NAME = p_business_group;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'business_group_id =>'
                                  || p_business_group_id
                                 );
         ELSE
            xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_low,
                    p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                    p_error_text               => 'business group name can not be null',
                    p_record_identifier_1      => p_update_pos_rec.business_group,
                    p_record_identifier_2      => p_update_pos_rec.position_name,
                    p_record_identifier_3      => p_update_pos_rec.business_group
                   );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            p_err_mesg :=
                    'business group name  can not be null' || p_business_group;
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'is_business_group : Success =>'
                               || p_business_group
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid business group name ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid business group name =>'
                                                   || p_business_group
                                                   || '-'
                                                   || SQLERRM,
                     p_record_identifier_1      => p_update_pos_rec.business_group,
                     p_record_identifier_2      => p_update_pos_rec.position_name,
                     p_record_identifier_3      => p_update_pos_rec.business_group
                    );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE Business Group name '
                                  || x_error_code
                                 );
            p_err_mesg := 'Invalid business group name';
            RETURN x_error_code;
      END is_business_group;

-----------------------------------------------------------------------
-- Position Validation
----------------------------------------------------------------------------
      FUNCTION is_position_valid (
         p_position_name           IN       VARCHAR2,
         p_err_mesg                OUT      VARCHAR2,
         p_position_id             OUT      NUMBER,
         p_position_def_id         OUT      NUMBER,
         p_object_version_number   OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code      NUMBER        := xx_emf_cn_pkg.cn_success;
         x_category_name   VARCHAR2 (25);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'position_name  => ' || p_position_name
                              );

         IF p_position_name IS NOT NULL
         THEN
            SELECT DISTINCT hp.position_id, hp.position_definition_id,
                            hp.object_version_number
                       INTO p_position_id, p_position_def_id,
                            p_object_version_number
                       FROM hr_all_positions_f hp,
                            per_position_definitions pp
                      WHERE hp.NAME = p_position_name
                        AND hp.position_definition_id =
                                                     pp.position_definition_id
                   AND effective_end_date = to_date('12/31/4712','MM/DD/YYYY');

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'position_id =>' || p_position_id
                                 );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'position_def_id =>' || p_position_def_id
                                 );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'object_version_number =>'
                                  || p_object_version_number
                                 );
         ELSE
            xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_low,
                    p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                    p_error_text               => 'position_name can not be null',
                    p_record_identifier_1      => p_update_pos_rec.business_group,
                    p_record_identifier_2      => p_update_pos_rec.position_name,
                    p_record_identifier_3      => p_update_pos_rec.position_name
                   );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            p_err_mesg := 'position_name can not be null' || p_position_name;
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'is_position_valid: Success =>'
                               || p_position_name
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid position_name ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid position_name=>'
                                                   || p_position_name
                                                   || '-'
                                                   || SQLERRM,
                     p_record_identifier_1      => p_update_pos_rec.business_group,
                     p_record_identifier_2      => p_update_pos_rec.position_name,
                     p_record_identifier_3      => p_update_pos_rec.position_name
                    );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'X_ERROR_CODE position_name' || x_error_code
                                 );
            p_err_mesg := 'Invalid position_name';
            RETURN x_error_code;
      END is_position_valid;

-------------------------------------------------------------------------
-- HR rep position Validation
--------------------------------------------------------------------------
      FUNCTION is_hr_rep_position (
         p_hr_rep_position   IN       VARCHAR2,
         p_err_mesg          OUT      VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         x_count        NUMBER := 0;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'hr_rep_position=> ' || p_hr_rep_position
                              );

         BEGIN
            SELECT COUNT (NAME)
              INTO x_count
              FROM per_positions
             WHERE NAME = p_hr_rep_position;

            IF x_count = 0
            THEN
               xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_low,
                    p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                    p_error_text               => 'hr_rep/dir_position is not valid',
                    p_record_identifier_1      => p_update_pos_rec.business_group,
                    p_record_identifier_2      => p_update_pos_rec.position_name,
                    p_record_identifier_3      => p_update_pos_rec.hr_rep_position
                   );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               p_err_mesg :=
                         'hr_rep_position is not defined' || p_hr_rep_position;
            END IF;
         END;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'is_hr_rep_position: Success =>'
                               || p_hr_rep_position
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid hr_rep_position' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid hr_rep_position=>'
                                                   || p_hr_rep_position
                                                   || '-'
                                                   || SQLERRM,
                     p_record_identifier_1      => p_update_pos_rec.business_group,
                     p_record_identifier_2      => p_update_pos_rec.position_name,
                     p_record_identifier_3      => p_update_pos_rec.hr_rep_position
                    );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE hr_rep_position '
                                  || x_error_code
                                 );
            p_err_mesg := 'Invalid hr_rep_position';
            RETURN x_error_code;
      END is_hr_rep_position;
------------------------------------------------
-- Main begins
---------------------------------------------------
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Data-Validations');
      -- effective date validation
      x_err_mesg := NULL;
      x_error_code_temp :=
              is_effective_date (p_update_pos_rec.effective_date,p_update_pos_rec.position_name,x_err_mesg);
      x_error_message := x_error_message || x_err_mesg;
      x_error_code := find_max (x_error_code, x_error_code_temp);
      -- business group validation
      x_err_mesg := NULL;
      x_error_code_temp :=
         is_business_group (p_update_pos_rec.business_group,
                            x_err_mesg,
                            p_update_pos_rec.business_group_id
                           );
      x_error_message := x_error_message || x_err_mesg;
      x_error_code := find_max (x_error_code, x_error_code_temp);
      -- position name validation
      x_err_mesg := NULL;
      x_error_code_temp :=
         is_position_valid (p_update_pos_rec.position_name,
                            x_err_mesg,
                            p_update_pos_rec.position_id,
                            p_update_pos_rec.position_definition_id,
                            p_update_pos_rec.object_version_number
                           );
      x_error_message := x_error_message || x_err_mesg;
      x_error_code := find_max (x_error_code, x_error_code_temp);

      -- hr rep position validation
      IF p_update_pos_rec.hr_rep_position IS NOT NULL
      THEN
         x_err_mesg := NULL;
         x_error_code_temp :=
            is_hr_rep_position (p_update_pos_rec.hr_rep_position, x_err_mesg);
         x_error_message := x_error_message || x_err_mesg;
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      -- hr dir position validation
      IF p_update_pos_rec.hr_dir_position IS NOT NULL
      THEN
         x_err_mesg := NULL;
         x_error_code_temp :=
            is_hr_rep_position (p_update_pos_rec.hr_dir_position, x_err_mesg);
         x_error_message := x_error_message || x_err_mesg;
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      -- cross update the error mesages to record
      p_update_pos_rec.error_message := SUBSTR (x_error_message, 1, 3000);
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Completed Data-Validations'
                              );
   END data_validations;

-----------------------------------------------------------
-------------main_prc-------------------
-----------------------------------------------------------
   PROCEDURE main_prc(
      p_errbuf           OUT      VARCHAR2,
      p_retcode          OUT      VARCHAR2,
      p_business_group   IN       VARCHAR2,
      p_reprocess        IN       VARCHAR2,
      p_dummy            IN       VARCHAR2,
      p_requestid        IN       NUMBER,
    --  p_file_name        IN       VARCHAR2,
      p_restart_flag     IN       VARCHAR2
   )
   IS
      CURSOR c_xx_update_pos_dff_stg (
         cp_process_code     VARCHAR2,
         cp_business_group   VARCHAR2
      )
      IS
         SELECT *
           FROM xx_hr_update_position_dff_stg
          WHERE request_id = xx_emf_pkg.g_request_id
            AND process_code = cp_process_code
            AND business_group = cp_business_group
            AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn);

      x_error_code        VARCHAR2 (1)             := xx_emf_cn_pkg.cn_success;
      x_stg_table         g_xx_hr_update_posdff_tab_type;
      x_error_msg_temp    VARCHAR2 (3000);
      x_error_code_temp   NUMBER                   := xx_emf_cn_pkg.cn_success;
      x_cst_error         EXCEPTION;
      x_error_msg         VARCHAR2 (3000);

-- --------------------------------------------------------------------- --
--update_record_status
---------------------------------------------------------------------------
      PROCEDURE update_record_status (
         p_update_pos_rec   IN OUT   g_xx_hr_update_posdff_rec_type,
         p_error_code       IN       VARCHAR2
      )
      IS
      BEGIN
         IF p_error_code IN
                        (xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err)
         THEN
            p_update_pos_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            p_update_pos_rec.ERROR_CODE :=
               find_max (p_error_code,
                         NVL (p_update_pos_rec.ERROR_CODE,
                              xx_emf_cn_pkg.cn_success
                             )
                        );
         END IF;

         p_update_pos_rec.process_code := g_stage;
      END update_record_status;

-- --------------------------------------------------------------------- --
-- Initalizating the staging recods
--------------------------------------------------------------------------
      PROCEDURE update_int_records (
         p_update_pos_rec   IN   g_xx_hr_update_posdff_tab_type
      )
      IS
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      BEGIN
         FOR indx IN 1 .. p_update_pos_rec.COUNT
         LOOP
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'UPDATE_INT_RECORDS ');
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Process_code     ->'
                                  || p_update_pos_rec (indx).process_code
                                 );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Error_code       ->'
                                  || p_update_pos_rec (indx).ERROR_CODE
                                 );

            UPDATE xx_hr_update_position_dff_stg
               SET business_group_id =
                                     p_update_pos_rec (indx).business_group_id,
                   position_id = p_update_pos_rec (indx).position_id,
                   position_definition_id =
                                p_update_pos_rec (indx).position_definition_id,
                   object_version_number =
                                 p_update_pos_rec (indx).object_version_number,
                   creation_date = SYSDATE,
                   created_by = fnd_global.user_id,
                   process_code = g_stage,
                   ERROR_CODE = p_update_pos_rec (indx).ERROR_CODE,
                   error_message = p_update_pos_rec (indx).error_message,
                   request_id = p_update_pos_rec (indx).request_id,
                   last_updated_by = fnd_global.user_id,
                   last_update_date = SYSDATE,
                   last_update_login = x_last_update_login
             WHERE record_id = p_update_pos_rec (indx).record_id
               AND business_group = p_business_group;
         END LOOP;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Error in update_int_records' || SQLERRM
                                 );
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand
                             );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
      END update_int_records;

-- --------------------------------------------------------------------- --
-- call API
-------------------------------------------------------------------------

      ----------------------------------------------------------------------
--------------------------< process_data >--------------------------
----------------------------------------------------------------------
      FUNCTION process_data (
         p_parameter_1   IN   VARCHAR2,
         p_parameter_2   IN   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_return_status                  VARCHAR2 (15)
                                                  := xx_emf_cn_pkg.cn_success;

         CURSOR xx_update_pos
         IS
            SELECT *
              FROM xx_hr_update_position_dff_stg
             WHERE ERROR_CODE IN
                       (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
               AND process_code = xx_emf_cn_pkg.cn_postval
               AND request_id = xx_emf_pkg.g_request_id
               AND business_group = p_business_group;

         x_effective_start_date           DATE;
         x_effective_end_date             DATE;
         x_validate_flag                  BOOLEAN                     := FALSE;
         l_sqlerrm                        VARCHAR2 (2000);
         x_sqlerrm                        VARCHAR2 (2000);
         x_effective_date                 DATE                      := SYSDATE;
         x_position_id                    hr_all_positions_f.position_id%TYPE;
         x_position_def_id                hr_all_positions_f.position_definition_id%TYPE;
         x_object_version_number          NUMBER;
         x_valid_grades_changed_warning   BOOLEAN;
         X_POSITION_NAME                  HR_ALL_POSITIONS_F.NAME%TYPE;
         X_HR_DIR_POSITION_ID  HR_ALL_POSITIONS_F.POSITION_ID%TYPE;
          X_hr_rep_position_ID  HR_ALL_POSITIONS_F.POSITION_ID%TYPE;

      BEGIN
         -- Change the logic to whatever needs to be done
         -- either call the appropriate API to process the data
         -- or to insert into an interface table.
         FOR xx_update_rec IN xx_update_pos
         LOOP
            x_object_version_number := xx_update_rec.object_version_number;
            x_position_def_id := xx_update_rec.position_definition_id;
            X_POSITION_NAME := XX_UPDATE_REC.POSITION_NAME;

----------------------------------------------------------------------
--------------------------< Getting hr_rep_position id >--------------------------
----------------------------------------------------------------------
             BEGIN
                SELECT POSITION_ID
                INTO X_hr_rep_position_id
                FROM PER_POSITIONS
                WHERE NAME = xx_update_rec.hr_rep_position;
            EXCEPTION
            WHEN OTHERS THEN
              XX_EMF_PKG.WRITE_LOG (XX_EMF_CN_PKG.CN_LOW, 'Error in hr_rep_position_ID ' || SQLERRM );
              xx_emf_pkg.error (xx_emf_cn_pkg.cn_low, xx_emf_cn_pkg.cn_tech_error, xx_emf_cn_pkg.cn_exp_unhand );
              x_error_code := xx_emf_cn_pkg.cn_prc_err;
            END;
----------------------------------------------------------------------
--------------------------< Getting hr_dir_position id >--------------------------
----------------------------------------------------------------------
           BEGIN
            SELECT POSITION_ID
            INTO X_HR_DIR_POSITION_ID
            FROM PER_POSITIONS
            WHERE NAME = xx_update_rec.hr_dir_position;
          EXCEPTION
          WHEN OTHERS THEN
            XX_EMF_PKG.WRITE_LOG (XX_EMF_CN_PKG.CN_LOW, 'Error in HR_DIR_POSITION_ID ' || SQLERRM );
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_low, xx_emf_cn_pkg.cn_tech_error, xx_emf_cn_pkg.cn_exp_unhand );
            X_ERROR_CODE := XX_EMF_CN_PKG.CN_PRC_ERR;
          END;

----------------------------------------------------------------------
--------------------------< Calling API >--------------------------
----------------------------------------------------------------------
            IF xx_update_rec.position_name IS NOT NULL
            THEN
               BEGIN
                  hr_position_api.update_position
                     (p_validate                          => x_validate_flag,
                      p_position_id                       => xx_update_rec.position_id,
                      p_effective_start_date              => x_effective_start_date,
                      p_effective_end_date                => x_effective_end_date,
                      p_position_definition_id            => x_position_def_id,
                      p_valid_grades_changed_warning      => x_valid_grades_changed_warning,
                      p_name                              => x_position_name,
                      p_attribute1                        => NULL,
                      p_attribute2                        => NULL,
                      p_attribute3                        => NULL,
                      p_attribute4                        => NULL,
                      P_ATTRIBUTE5                        => x_hr_rep_position_id,
                      p_attribute6                        => x_hr_dir_position_id,
                      p_object_version_number             => x_object_version_number,
                      p_effective_date                    => xx_update_rec.effective_date,
                      p_datetrack_mode                    => 'CORRECTION'
                     );
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'API hr_position_api.update_position'
                                       );
/*******************************************/
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     x_sqlerrm := SUBSTR (SQLERRM, 1, 800);
                     x_error_code := xx_emf_cn_pkg.cn_rec_err;
                     xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_tech_error,
                         p_error_text               => x_sqlerrm,
                         p_record_identifier_1      => xx_update_rec.business_group,
                         p_record_identifier_2      => xx_update_rec.position_name,
                         p_record_identifier_3      => 'UPDATE POSITION API'
                        );

                     UPDATE xx_hr_update_position_dff_stg
                        SET ERROR_CODE = x_error_code,
                            process_code = xx_emf_cn_pkg.cn_process_data
                      WHERE record_id = xx_update_rec.record_id
                        AND request_id = xx_update_rec.request_id;

                     COMMIT;
               END;
            END IF;

            COMMIT;
         END LOOP;

         RETURN x_return_status;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_sqlerrm := SQLERRM;
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_high,
                              xx_emf_cn_pkg.cn_tech_error,
                              l_sqlerrm
                             );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            RETURN x_error_code;
      END process_data;

 -----------------------------------------------------------
-------------mark_records_complete-------------------
------------------------------------------------------------
      PROCEDURE mark_records_complete (p_process_code VARCHAR2)
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside of mark records complete...'
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside mark_records_complete'
                              );

         UPDATE xx_hr_update_position_dff_stg                         --Header
            SET process_code = g_stage,
                ERROR_CODE = NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success),
                last_updated_by = x_last_updated_by,
                last_update_date = x_last_update_date,
                last_update_login = x_last_update_login
          WHERE request_id = xx_emf_pkg.g_request_id
            AND process_code =
                   DECODE (p_process_code,
                           xx_emf_cn_pkg.cn_process_data, xx_emf_cn_pkg.cn_postval,
                           xx_emf_cn_pkg.cn_derive
                          )
            AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
            AND business_group = p_business_group;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log
                              (xx_emf_cn_pkg.cn_low,
                                  'Error in Update of mark_records_complete '
                               || SQLERRM
                              );
      END mark_records_complete;
--     --------------------------------------------------------------------- --
       --calling functions main----------
       ------------------------------------------
   BEGIN
      p_retcode := xx_emf_cn_pkg.cn_success;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Before Setting Environment'
                           );
      -- Emf Env initialization
      x_error_code := xx_emf_pkg.set_env;
      xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_medium,
                         'Starting main process with the following parameters'
                        );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_reprocess    ' || p_reprocess
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_requestid    ' || p_requestid
                           );
      /*xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_file_name    ' || p_file_name
                           );*/
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_restart_flag ' || p_restart_flag
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'Main:Param - p_business_group '
                            || p_business_group
                           );
       -- ------------------------------------ --
       -- Setting Global Variables
--       x_error_code := xx_global_var;
       -- ------------------------------------ --
   -- ------------------------------------ --
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Start Calling mark_records_for_processing..'
                           );
      mark_records_for_processing (p_reprocess           => p_reprocess,
                                   p_requestid           => p_requestid,
                             --    p_file_name           => p_file_name,
                                   p_restart_flag        => p_restart_flag,
                                   p_business_group      => p_business_group
                                  );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'End Calling mark_records_for_processing..'
                           );
-- ------------------------------------ --

      -- Set the stage to Pre Validations
      set_stage (xx_emf_cn_pkg.cn_preval);
-- ------------------------------------ --
-- Cross updating staging table
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Start Calling update_staging_records..'
                           );
      update_staging_records (xx_emf_cn_pkg.cn_success, p_business_group);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'End Calling update_staging_records..'
                           );
-- ------------------------------------ --
      xx_emf_pkg.propagate_error (x_error_code);
      -- Set the stage to data Validations
      set_stage (xx_emf_cn_pkg.cn_valid);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'FLAGS -->'
                            || 'Req->'
                            || xx_emf_pkg.g_request_id
                            || ' - '
                            || 'cp_process_code ->'
                            || xx_emf_cn_pkg.cn_preval
                            || ' - '
                            || xx_emf_cn_pkg.cn_success
                            || ' - '
                            || xx_emf_cn_pkg.cn_rec_warn
                           );

      OPEN c_xx_update_pos_dff_stg (xx_emf_cn_pkg.cn_preval, p_business_group);

      LOOP
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'In the records loop');

         FETCH c_xx_update_pos_dff_stg
         BULK COLLECT INTO x_stg_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'x_stg_table.count 1->' || x_stg_table.COUNT
                              );

         FOR i IN 1 .. x_stg_table.COUNT
         LOOP
            BEGIN
               x_error_code := data_validations (x_stg_table (i));
               xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                                 'After Data Validations ... x_error_code : '
                              || x_error_code
                              || '-'
                              || x_stg_table.COUNT
                             );
               update_record_status (x_stg_table (i), x_error_code);
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'After update_record_status ...'
                                    );
               xx_emf_pkg.propagate_error (x_error_code);
               -- Set the stage to Post Validations
               set_stage (xx_emf_cn_pkg.cn_postval);
            EXCEPTION
               WHEN xx_emf_pkg.g_e_rec_error
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                        xx_emf_cn_pkg.cn_rec_err
                                       );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
                  xx_emf_pkg.write_log
                                   (xx_emf_cn_pkg.cn_high,
                                    'Process Level Error in Data Validations'
                                   );
                  raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
               WHEN OTHERS
               THEN
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    xx_emf_cn_pkg.cn_exp_unhand,
                                    x_stg_table (i).record_id
                                   );
            END;
         END LOOP;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'x_stg_table.count 2->' || x_stg_table.COUNT
                              );
         update_int_records (x_stg_table);
         update_staging_records (xx_emf_cn_pkg.cn_success, p_business_group);
         x_stg_table.DELETE;
         EXIT WHEN c_xx_update_pos_dff_stg%NOTFOUND;
      END LOOP;

      IF c_xx_update_pos_dff_stg%ISOPEN
      THEN
         CLOSE c_xx_update_pos_dff_stg;
      END IF;

      -- Set the stage to Post Validations
      set_stage (xx_emf_cn_pkg.cn_postval);
      x_error_code := post_validations ();
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'After post-validations X_ERROR_CODE '
                            || x_error_code
                           );
      mark_records_complete (xx_emf_cn_pkg.cn_postval);
      xx_emf_pkg.write_log
              (xx_emf_cn_pkg.cn_medium,
                  'After mark_records_complete post-validations X_ERROR_CODE '
               || x_error_code
              );
      xx_emf_pkg.propagate_error (x_error_code);
-- ------------------------------------ --

      -- Set the stage to Process Data
      set_stage (xx_emf_cn_pkg.cn_process_data);
-- ------------------------------------ --
      x_error_code := process_data (NULL, NULL);
      mark_records_complete (xx_emf_cn_pkg.cn_process_data);
      xx_emf_pkg.write_log
                   (xx_emf_cn_pkg.cn_medium,
                       'After Process Data mark_records_complete x_error_code'
                    || x_error_code
                   );
-- ------------------------------------ --

      -- ------------------------------------ --
-- Archiving the files
--      x_error_code := move_file_archive;
-- ------------------------------------ --

      -- Emf error propagate
      xx_emf_pkg.propagate_error (x_error_code);
      -- update record count
      update_record_count;
      -- emf report
      xx_emf_pkg.create_report;

   EXCEPTION
      WHEN x_cst_error
      THEN
         p_retcode := x_error_code;
         p_errbuf :=
                    x_error_msg_temp || ' ' || x_error_msg || '  ' || SQLERRM;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                  ' Error ='
                               || x_error_msg_temp
                               || ' '
                               || x_error_msg
                               || ' x_error_code = '
                               || x_error_code
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'SQLERRM = ' || SQLERRM);
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                  ' Main Exception :'
                               || x_error_msg
                               || ' x_error_code = '
                               || x_error_code
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'SQLERRM = ' || SQLERRM);
         p_retcode := x_error_code;
         p_errbuf := x_error_msg || SQLERRM;
         xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                           p_category                 => xx_emf_cn_pkg.cn_tech_error,
                           p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                           p_record_identifier_1      => SQLCODE,
                           p_record_identifier_2      => SQLERRM
                          );
         xx_emf_pkg.create_report;
   END main_prc;
-- --------------------------------------------------------------------- --
END xx_hr_update_pos_dff_pkg;
/
