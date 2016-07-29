DROP PACKAGE BODY APPS.XX_HR_APPL_CNV_VALIDATION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_APPL_CNV_VALIDATION_PKG" 
AS
--------------------------------------------------------------------------
/* $Header: XXHRAPPLCONV.pkb 1.0 2012/02/20 12:00:00 Damd noship $ */
/*
Created By    : IBM Development Team
Creation Date : 20-Feb-2012
File Name     : XXHRAPPLCONV.pkb
Description   : This script creates the body for the Applicant Conversion

Change History:

Version Date        Name                   Remarks
------- ----------- -------------------    ----------------------
1.0     20-Feb-12   IBM Development Team   Initial development.
2.0     17-Apr-2013 Dinesh           Added Manager details to applicant for HR May 2013 release
*/
--------------------------------------------------------------------------

   --**********************************************************************
   --Procedure to set environment.
   --**********************************************************************
   PROCEDURE set_cnv_env (
      p_batch_id        VARCHAR2,
      p_required_flag   VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_yes
   )
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside set_cnv_env...');
      g_batch_id := p_batch_id;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'G_BATCH_ID: ' || g_batch_id
                           );
      -- Set the environment
      x_error_code := xx_emf_pkg.set_env;

      IF NVL (p_required_flag, xx_emf_cn_pkg.cn_yes) <> xx_emf_cn_pkg.cn_no
      THEN
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE xx_emf_pkg.g_e_env_not_set;
   END set_cnv_env;

   --*********************************************************************
   --Procedure to set debug level low.
   --*********************************************************************
   PROCEDURE dbg_low (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'In xx_hr_appl_cnv_validation_pkg.'
                            || g_api_name
                            || ': '
                            || p_dbg_text
                           );
   END dbg_low;

   --**********************************************************************
   --Procedure to set debug level medium.
   --**********************************************************************
   PROCEDURE dbg_med (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'In xx_hr_appl_cnv_validation_pkg.'
                            || g_api_name
                            || ': '
                            || p_dbg_text
                           );
   END dbg_med;

   --**********************************************************************
   --Procedure to set debug level high.
   --**********************************************************************
   PROCEDURE dbg_high (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                               'In xx_hr_appl_cnv_validation_pkg.'
                            || g_api_name
                            || ': '
                            || p_dbg_text
                           );
   END dbg_high;

   --***********************************************************************
   --Procedure to count staging table record for Applicant.
   --***********************************************************************
   PROCEDURE update_record_count (pr_validate_and_load IN VARCHAR2)
   IS
      CURSOR c_get_total_cnt
      IS
         SELECT COUNT (1) total_count
           FROM xx_hr_appl_upload_stg
          WHERE batch_id = g_batch_id
                AND request_id = xx_emf_pkg.g_request_id;

      x_total_cnt        NUMBER := 0;

      CURSOR c_get_total_cnt_ph
      IS
         SELECT COUNT (1) total_count
           FROM xx_hr_phone_upload_stg
          WHERE batch_id = g_batch_id
                AND request_id = xx_emf_pkg.g_request_id;

      x_total_cnt_ph     NUMBER := 0;

      CURSOR c_get_total_cnt_rm
      IS
         SELECT COUNT (1) total_count
           FROM xx_hr_resume_upload_stg
          WHERE batch_id = g_batch_id
                AND request_id = xx_emf_pkg.g_request_id;

      x_total_cnt_rm     NUMBER := 0;

      CURSOR c_get_error_cnt
      IS
         SELECT SUM (error_count)
           FROM (SELECT COUNT (1) error_count
                   FROM xx_hr_appl_upload_stg
                  WHERE batch_id = g_batch_id
                    AND request_id = xx_emf_pkg.g_request_id
                    AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err);

      x_error_cnt        NUMBER := 0;

      CURSOR c_get_error_cnt_ph
      IS
         SELECT SUM (error_count)
           FROM (SELECT COUNT (1) error_count
                   FROM xx_hr_phone_upload_stg
                  WHERE batch_id = g_batch_id
                    AND request_id = xx_emf_pkg.g_request_id
                    AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err);

      x_error_cnt_ph     NUMBER := 0;

      CURSOR c_get_error_cnt_rm
      IS
         SELECT SUM (error_count)
           FROM (SELECT COUNT (1) error_count
                   FROM xx_hr_resume_upload_stg
                  WHERE batch_id = g_batch_id
                    AND request_id = xx_emf_pkg.g_request_id
                    AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err);

      x_error_cnt_rm     NUMBER := 0;

      CURSOR c_get_warning_cnt
      IS
         SELECT COUNT (1) warn_count
           FROM xx_hr_appl_upload_stg
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

      x_warn_cnt         NUMBER := 0;

      CURSOR c_get_warning_cnt_ph
      IS
         SELECT COUNT (1) warn_count
           FROM xx_hr_phone_upload_stg
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

      x_warn_cnt_ph      NUMBER := 0;

      CURSOR c_get_warning_cnt_rm
      IS
         SELECT COUNT (1) warn_count
           FROM xx_hr_resume_upload_stg
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

      x_warn_cnt_rm      NUMBER := 0;

      CURSOR c_get_success_cnt
      IS
         SELECT COUNT (1) success_count
           FROM xx_hr_appl_upload_stg
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND process_code = xx_emf_cn_pkg.cn_process_data
            AND ERROR_CODE = xx_emf_cn_pkg.cn_success;

      x_success_cnt      NUMBER := 0;

      CURSOR c_get_success_cnt_ph
      IS
         SELECT COUNT (1) success_count
           FROM xx_hr_phone_upload_stg
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND process_code = xx_emf_cn_pkg.cn_process_data
            AND ERROR_CODE = xx_emf_cn_pkg.cn_success;

      x_success_cnt_ph   NUMBER := 0;

      CURSOR c_get_success_cnt_rm
      IS
         SELECT COUNT (1) success_count
           FROM xx_hr_resume_upload_stg
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND process_code = xx_emf_cn_pkg.cn_process_data
            AND ERROR_CODE = xx_emf_cn_pkg.cn_success;

      x_success_cnt_rm   NUMBER := 0;

      -- Added for if p_validate_only_flag is set to VALIDATE_ONLY Starts
      CURSOR c_get_success_valid_cnt
      IS
         SELECT COUNT (1) success_count
           FROM xx_hr_appl_upload_stg
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND process_code = xx_emf_cn_pkg.cn_valid
            AND ERROR_CODE = xx_emf_cn_pkg.cn_success;

      CURSOR c_get_success_valid_cnt_ph
      IS
         SELECT COUNT (1) success_count
           FROM xx_hr_phone_upload_stg
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND process_code = xx_emf_cn_pkg.cn_valid
            AND ERROR_CODE = xx_emf_cn_pkg.cn_success;

      CURSOR c_get_success_valid_cnt_rm
      IS
         SELECT COUNT (1) success_count
           FROM xx_hr_resume_upload_stg
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND process_code = xx_emf_cn_pkg.cn_valid
            AND ERROR_CODE = xx_emf_cn_pkg.cn_success;
   -- Added for if p_validate_only_flag is set to VALIDATE_ONLY Ends
   BEGIN
      OPEN c_get_total_cnt;

      FETCH c_get_total_cnt
       INTO x_total_cnt;

      CLOSE c_get_total_cnt;

      OPEN c_get_total_cnt_ph;

      FETCH c_get_total_cnt_ph
       INTO x_total_cnt_ph;

      CLOSE c_get_total_cnt_ph;

      OPEN c_get_total_cnt_rm;

      FETCH c_get_total_cnt_rm
       INTO x_total_cnt_rm;

      CLOSE c_get_total_cnt_rm;

      x_total_cnt := x_total_cnt + x_total_cnt_ph + x_total_cnt_rm;
      dbg_low ('Applicant:'||x_total_cnt);
      dbg_low ('Phone:'||x_total_cnt_ph);
      dbg_low ('Resume:'||x_total_cnt_rm);

------------------
      OPEN c_get_error_cnt;

      FETCH c_get_error_cnt
       INTO x_error_cnt;

      CLOSE c_get_error_cnt;

      OPEN c_get_error_cnt_ph;

      FETCH c_get_error_cnt_ph
       INTO x_error_cnt_ph;

      CLOSE c_get_error_cnt_ph;

      OPEN c_get_error_cnt_rm;

      FETCH c_get_error_cnt_rm
       INTO x_error_cnt_rm;

      CLOSE c_get_error_cnt_rm;

      x_error_cnt := x_error_cnt + x_error_cnt_ph + x_error_cnt_rm;

------------------------
      OPEN c_get_warning_cnt;

      FETCH c_get_warning_cnt
       INTO x_warn_cnt;

      CLOSE c_get_warning_cnt;

      OPEN c_get_warning_cnt_ph;

      FETCH c_get_warning_cnt_ph
       INTO x_warn_cnt_ph;

      CLOSE c_get_warning_cnt_ph;

      OPEN c_get_warning_cnt_rm;

      FETCH c_get_warning_cnt_rm
       INTO x_warn_cnt_rm;

      CLOSE c_get_warning_cnt_rm;

      x_warn_cnt := x_warn_cnt + x_warn_cnt_ph + x_warn_cnt_rm;

------------------------------
      IF pr_validate_and_load = g_validate_and_load
      THEN
         OPEN c_get_success_cnt;

         FETCH c_get_success_cnt
          INTO x_success_cnt;

         CLOSE c_get_success_cnt;

         OPEN c_get_success_cnt_ph;

         FETCH c_get_success_cnt_ph
          INTO x_success_cnt_ph;

         CLOSE c_get_success_cnt_ph;

         OPEN c_get_success_cnt_rm;

         FETCH c_get_success_cnt_rm
          INTO x_success_cnt_rm;

         CLOSE c_get_success_cnt_rm;

         x_success_cnt := x_success_cnt + x_success_cnt_ph + x_success_cnt_rm;
------------------------------
      ELSE
         OPEN c_get_success_valid_cnt;

         FETCH c_get_success_valid_cnt
          INTO x_success_cnt;

         CLOSE c_get_success_valid_cnt;

         OPEN c_get_success_valid_cnt_ph;

         FETCH c_get_success_valid_cnt_ph
          INTO x_success_cnt_ph;

         CLOSE c_get_success_valid_cnt_ph;

         OPEN c_get_success_valid_cnt_rm;

         FETCH c_get_success_valid_cnt_rm
          INTO x_success_cnt_rm;

         CLOSE c_get_success_valid_cnt_rm;

         x_success_cnt := x_success_cnt + x_success_cnt_ph + x_success_cnt_rm;
      END IF;
      -----------------------
      xx_emf_pkg.update_recs_cnt (p_total_recs_cnt        => x_total_cnt,
                                  p_success_recs_cnt      => x_success_cnt,
                                  p_warning_recs_cnt      => x_warn_cnt,
                                  p_error_recs_cnt        => x_error_cnt
                                 );
   END update_record_count;

   --**********************************************************************
   --Procedure to update records for processing.
   --**********************************************************************
   PROCEDURE mark_records_for_processing (p_restart_flag IN VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      g_api_name := 'mark_records_for_processing';
      dbg_low ('Inside of mark records for processing...');

      IF p_restart_flag = xx_emf_cn_pkg.cn_all_recs
      THEN
         --------------Update Applicant Staging table-------------------------------
         UPDATE xx_hr_appl_upload_stg              -- Applicant staging table
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new,
                error_mesg = NULL
          WHERE batch_id = g_batch_id;
          --AND NVL(process_code,xx_emf_cn_pkg.CN_NEW) NOT IN(xx_emf_cn_pkg.CN_PROCESS_DATA);

         ----------------------Update Phone Staging table---------------------------------
         UPDATE xx_hr_phone_upload_stg                  -- Phone staging table
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new,
                error_mesg = NULL
          WHERE batch_id = g_batch_id;
          --AND NVL(process_code,xx_emf_cn_pkg.CN_NEW) NOT IN(xx_emf_cn_pkg.CN_PROCESS_DATA);

         ----------------------Update Resume Staging table---------------------------------
         UPDATE xx_hr_resume_upload_stg                -- Resume staging table
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new,
                error_mesg = NULL
          WHERE batch_id = g_batch_id;
          --AND NVL(process_code,xx_emf_cn_pkg.CN_NEW) NOT IN(xx_emf_cn_pkg.CN_PROCESS_DATA);
      ELSIF p_restart_flag = xx_emf_cn_pkg.cn_err_recs
      THEN
         ---------------------------------- Update applicant Staging-----------------------------------
         UPDATE xx_hr_appl_upload_stg
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new,
                error_mesg = NULL
          WHERE batch_id = g_batch_id
            AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_rec_err) IN
                   (xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err,
                    xx_emf_cn_pkg.cn_prc_err
                   );

         ---------------------------- Update phone Staging--------------------------------------------------
         UPDATE xx_hr_phone_upload_stg
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new,
                error_mesg = NULL
          WHERE batch_id = g_batch_id
            AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_rec_err) IN
                   (xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err,
                    xx_emf_cn_pkg.cn_prc_err
                   );

         ---------------------------- Update resume Staging--------------------------------------------------
         UPDATE xx_hr_resume_upload_stg
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new,
                error_mesg = NULL
          WHERE batch_id = g_batch_id
            AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_rec_err) IN
                   (xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err,
                    xx_emf_cn_pkg.cn_prc_err
                   );
      END IF;

      COMMIT;
      dbg_low ('End of mark records for processing...');
   END;

   --**********************************************************************
   --Procedure to set stage for staging table.
   --**********************************************************************
   PROCEDURE set_stage (p_stage VARCHAR2)
   IS
   BEGIN
      g_stage := p_stage;
   END set_stage;

   --**********************************************************************
   --Procedure to update staging table for Applicant.
   --**********************************************************************
   PROCEDURE update_staging_records (p_error_code VARCHAR2)
   IS
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      g_api_name := 'update_staging_records';
      dbg_low ('Inside update_staging_records...');

      UPDATE xx_hr_appl_upload_stg
         SET process_code = g_stage,
             ERROR_CODE = DECODE (ERROR_CODE, NULL, p_error_code, ERROR_CODE),
             last_update_date = x_last_update_date,
             last_updated_by = x_last_updated_by,
             last_update_login = x_last_update_login
       WHERE batch_id = g_batch_id
         AND request_id = xx_emf_pkg.g_request_id
         AND process_code = xx_emf_cn_pkg.cn_new;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         dbg_low ('Error while updating staging records status: ' || SQLERRM);
   END update_staging_records;

   --**********************************************************************
   --Procedure to update the staging table for phone records.
   --**********************************************************************
   PROCEDURE update_staging_records_ph (p_error_code VARCHAR2)
   IS
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      g_api_name := 'update_staging_records_ph';
      dbg_low ('Inside update_staging_records_ph...');

      UPDATE xx_hr_phone_upload_stg
         SET process_code = g_stage,
             ERROR_CODE = DECODE (ERROR_CODE, NULL, p_error_code, ERROR_CODE),
             last_update_date = x_last_update_date,
             last_updated_by = x_last_updated_by,
             last_update_login = x_last_update_login
       WHERE batch_id = g_batch_id
         AND request_id = xx_emf_pkg.g_request_id
         AND process_code = xx_emf_cn_pkg.cn_new;
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         dbg_low
                (   'Error while updating staging records status for phone: '
                 || SQLERRM
                );
   END update_staging_records_ph;

   --**********************************************************************
   --Procedure to update staging table for resume records.
   --**********************************************************************
   PROCEDURE update_staging_records_rm (p_error_code VARCHAR2)
   IS
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      g_api_name := 'update_staging_records_rm';
      dbg_low ('Inside update_staging_records_rm...');

      UPDATE xx_hr_resume_upload_stg
         SET process_code = g_stage,
             ERROR_CODE = DECODE (ERROR_CODE, NULL, p_error_code, ERROR_CODE),
             last_update_date = x_last_update_date,
             last_updated_by = x_last_updated_by,
             last_update_login = x_last_update_login
       WHERE batch_id = g_batch_id
         AND request_id = xx_emf_pkg.g_request_id
         AND process_code = xx_emf_cn_pkg.cn_new;
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         dbg_low
               (   'Error while updating staging records status for resume: '
                || SQLERRM
               );
   END update_staging_records_rm;

   --**********************************************************************
   --Function to Find Max.
   --**********************************************************************
   FUNCTION find_max (p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2)
      RETURN VARCHAR2
   IS
      x_return_value   VARCHAR2 (100);
   BEGIN
      x_return_value :=
                   xx_intg_common_pkg.find_max (p_error_code1, p_error_code2);
      RETURN x_return_value;
   END find_max;

   --**********************************************************************
   --Function to pre validations for Applicant.
   --**********************************************************************
   FUNCTION pre_validations_appl
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

      -- Cursor for duplicate header record
      CURSOR c_xx_applicant_dup
      IS
         SELECT        *
           FROM xx_hr_appl_upload_stg ha1
          WHERE ha1.unique_id IN (SELECT unique_id a
                                    FROM xx_hr_appl_upload_stg
                                  GROUP BY unique_id
                                  HAVING COUNT (unique_id) > 1)
         FOR UPDATE OF ha1.process_code, ha1.ERROR_CODE, ha1.error_mesg;
   BEGIN
      dbg_low ('Inside Pre-Validations for Applicant');
      --Start of the loop to print all the headers that are duplicate in the staging table
      --Comment after CRP3 on 22/05/12
      /*FOR cnt IN c_xx_applicant_dup
      LOOP
         UPDATE xx_hr_appl_upload_stg
            SET process_code = xx_emf_cn_pkg.cn_preval,
                ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
                error_mesg =
                      'Duplicate record exists in the Applicant staging table'
          WHERE CURRENT OF c_xx_applicant_dup;

         xx_emf_pkg.error
                     (xx_emf_cn_pkg.cn_low,
                      xx_emf_cn_pkg.cn_stg_apicall,
                      'Duplicate record exists in the Applicant staging table',
                      cnt.record_number,
                      cnt.last_name,
                      cnt.business_group_name,
                      'Duplicate record'
                     );
         dbg_low ('Last Name          :     ' || cnt.last_name);
         dbg_low ('Business Group Name:      ' || cnt.business_group_name);
         dbg_low ('Vacancy Number:     ' || cnt.vacancy_number);
      END LOOP;--End of LOOP to print the duplicate records in the staging table
      COMMIT;*/--Comment after CRP3 on 22/05/12
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
   END pre_validations_appl;

   --**********************************************************************
   --Function to pre validations for phone.
   --**********************************************************************
   FUNCTION pre_validations_ph
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

      -- Cursor for duplicate header record
      CURSOR c_xx_phone_dup
      IS
         SELECT        *
                  FROM xx_hr_phone_upload_stg ha1
                 WHERE ha1.unique_id IN (SELECT   unique_id a
                                             FROM xx_hr_phone_upload_stg
                                         GROUP BY unique_id, phone_type
                                           HAVING COUNT (*) > 1)
         FOR UPDATE OF ha1.process_code, ha1.ERROR_CODE, ha1.error_mesg;
   BEGIN
      dbg_low ('Inside Pre-Validations for Phone Data : Duplicate checking');
      --Start of the loop to print all the headers that are duplicate in the staging table
      dbg_low ('Following records are duplicate Phone records');

      FOR cnt IN c_xx_phone_dup
      LOOP
         UPDATE xx_hr_phone_upload_stg
            SET process_code = xx_emf_cn_pkg.cn_preval,
                ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
                error_mesg =
                          'Duplicate record exists in the phone staging table'
          WHERE CURRENT OF c_xx_phone_dup;

         xx_emf_pkg.error
                     (xx_emf_cn_pkg.cn_low,
                      xx_emf_cn_pkg.cn_stg_apicall,
                      SUBSTR (SQLERRM, 1, 1000),
                      cnt.record_number,
                      cnt.last_name,
                      cnt.business_group_name,
                      'Duplicate record exists in the Applicant staging table'
                     );
         dbg_low ('Person Last Name:     ' || cnt.last_name);
         dbg_low ('Business Group Name:  ' || cnt.business_group_name);
         dbg_low ('Phone Type:           ' || cnt.phone_type);
      END LOOP;--End of LOOP to print the duplicate records in the staging table
      COMMIT;
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
   END pre_validations_ph;

   --**********************************************************************
   --Function to pre validations for resume.
   --**********************************************************************
   FUNCTION pre_validations_rm
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

      -- Cursor for duplicate header record
      CURSOR c_xx_resume_dup
      IS
         SELECT        *
           FROM xx_hr_resume_upload_stg ha1
          WHERE ha1.unique_id IN (SELECT unique_id a
                                    FROM xx_hr_resume_upload_stg
                                GROUP BY unique_id
                                HAVING COUNT (unique_id) > 1)
         FOR UPDATE OF ha1.process_code, ha1.ERROR_CODE, ha1.error_mesg;
   BEGIN
      dbg_low ('Inside Pre-Validations for Resume Data');

      --Start of the loop to print all the headers that are duplicate in the staging table
      --Comment after CRP3 on 22/05/12
      /*FOR cnt IN c_xx_resume_dup
      LOOP
         UPDATE xx_hr_resume_upload_stg
            SET process_code = xx_emf_cn_pkg.cn_preval,
                ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
                error_mesg =
                         'Duplicate record exists in the resume staging table'
          WHERE CURRENT OF c_xx_resume_dup;

         dbg_low ('Person Last Name:     ' || cnt.last_name);
         dbg_low ('Business Group Name:  ' || cnt.business_group_name);
      END LOOP;--End of LOOP to print the duplicate records in the staging table
      COMMIT;*/--Comment after CRP3 on 22/05/12
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
   END pre_validations_rm;

   --**********************************************************************
   ----Function to validate the Applicant data.
   --**********************************************************************
   FUNCTION xx_applicant_validation (
      csr_applicant_print_rec   IN OUT   xx_hr_appl_cnv_validation_pkg.g_xx_applicant_stg_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
      l_person_id         NUMBER := NULL;
      l_person_type_id    NUMBER := NULL;
      l_vacancy_id        NUMBER := NULL;
      l_business_grp_id   NUMBER := NULL;

      --**********************************************************************
      -------Function to Validates Business Group Name.
      --**********************************************************************
      FUNCTION is_business_grp_valid (
         p_rec_number       NUMBER,
         p_last_name        VARCHAR2,
         p_business_group   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_business_group IS NULL
         THEN
            dbg_med ('Business Group Name can not be Null ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                      (p_severity                 => xx_emf_cn_pkg.cn_medium,
                       p_category                 => xx_emf_cn_pkg.cn_valid,
                       p_error_text               => 'Business Group Name can not be Null',
                       p_record_identifier_1      => p_rec_number,
                       p_record_identifier_2      => p_last_name,
                       p_record_identifier_3      => p_business_group,
                       p_record_identifier_4      => 'Applicant Data'
                      );
            RETURN x_error_code;
         ELSE
            BEGIN
               SELECT pbg.business_group_id
                 INTO l_business_grp_id
                 FROM per_business_groups pbg
                WHERE UPPER (pbg.NAME) = UPPER (p_business_group)
                  AND TRUNC (SYSDATE) BETWEEN date_from AND NVL (date_to,
                                                                 SYSDATE
                                                                );

               RETURN x_error_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  dbg_med ('Business Group Name can not be Null ');
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                         (p_severity                 => xx_emf_cn_pkg.cn_medium,
                          p_category                 => xx_emf_cn_pkg.cn_valid,
                          p_error_text               => 'Persons Last Name does not exist',
                          p_record_identifier_1      => p_rec_number,
                          p_record_identifier_2      => p_last_name,
                          p_record_identifier_3      => p_business_group,
                          p_record_identifier_4      => 'Applicant Data'
                         );
                  RETURN x_error_code;
               WHEN OTHERS
               THEN
                  dbg_med
                     ('Unexpected error while validating the Business Group Name'
                     );
                  x_error_code_temp := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_valid,
                      p_error_text               => 'Unexpected error while validating the Business Group Name',
                      p_record_identifier_1      => p_rec_number,
                      p_record_identifier_2      => p_last_name,
                      p_record_identifier_3      => p_business_group,
                      p_record_identifier_4      => 'Applicant Data'
                     );
                  RETURN x_error_code;
            END;
         END IF;
      END;

      --**********************************************************************
      -------Function to Validate Person's Name.
      --**********************************************************************
      FUNCTION is_person_valid (
         p_rec_number       NUMBER,
         p_last_name        VARCHAR2,
         p_first_name       VARCHAR2,
         p_business_group   VARCHAR2,
         p_unique_id        VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_last_name IS NULL
         THEN
            dbg_med ('Persons Last Name can not be Null ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_valid,
                         p_error_text               => 'Persons Last Name can not be Null',
                         p_record_identifier_1      => p_rec_number,
                         p_record_identifier_2      => p_last_name,
                         p_record_identifier_3      => p_business_group,
                         p_record_identifier_4      => 'Applicant Data'
                        );
            RETURN x_error_code;
         ELSE
            BEGIN
               SELECT DISTINCT person_id
                          INTO l_person_id
                          FROM per_all_people_f papf
                         WHERE attribute1 = p_unique_id;

               --UPPER(last_name) = UPPER(p_last_name)
               --AND   UPPER(first_name)= UPPER(p_first_name)
               --AND   business_group_id = l_business_grp_id;
               RETURN x_error_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  dbg_med ('Persons Last Name can not be Null ');
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                         (p_severity                 => xx_emf_cn_pkg.cn_medium,
                          p_category                 => xx_emf_cn_pkg.cn_valid,
                          p_error_text               => 'Persons Last Name does not exist',
                          p_record_identifier_1      => p_rec_number,
                          p_record_identifier_2      => p_last_name,
                          p_record_identifier_3      => p_business_group,
                          p_record_identifier_4      => 'Applicant Data'
                         );
                  RETURN x_error_code;
               WHEN OTHERS
               THEN
                  dbg_med
                        ('Unexpected error while validating the Persons Name');
                  x_error_code_temp := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_valid,
                      p_error_text               => 'Unexpected error while validating the Persons Name',
                      p_record_identifier_1      => p_rec_number,
                      p_record_identifier_2      => p_last_name,
                      p_record_identifier_3      => p_business_group,
                      p_record_identifier_4      => 'Applicant Data'
                     );
                  RETURN x_error_code;
            END;
         END IF;
      END;

      --**********************************************************************
      -----Function to Validate Person Type
      --**********************************************************************
      FUNCTION is_person_type_valid (
         p_rec_number         NUMBER,
         p_last_name          VARCHAR2,
         p_business_group     VARCHAR2,
         p_user_person_type   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_user_person_type IS NULL
         THEN
            dbg_med ('Person Type can not be Null ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                              p_category                 => xx_emf_cn_pkg.cn_valid,
                              p_error_text               => 'Person Type can not be Null;',
                              p_record_identifier_1      => p_rec_number,
                              p_record_identifier_2      => p_last_name,
                              p_record_identifier_3      => p_business_group,
                              p_record_identifier_4      => 'Applicant Data'
                             );
            RETURN x_error_code;
         ELSE
            ---
            BEGIN
               SELECT ppt.person_type_id
                 INTO l_person_type_id
                 FROM per_person_types ppt
                WHERE UPPER (user_person_type) = UPPER (p_user_person_type)
                  AND business_group_id = l_business_grp_id;

               RETURN x_error_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  dbg_med ('Invalid Person Type');
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                                   p_category                 => xx_emf_cn_pkg.cn_valid,
                                   p_error_text               => 'Invalid Person Type',
                                   p_record_identifier_1      => p_rec_number,
                                   p_record_identifier_2      => p_last_name,
                                   p_record_identifier_3      => p_business_group,
                                   p_record_identifier_4      => 'Applicant Data'
                                  );
                  RETURN x_error_code;
               WHEN OTHERS
               THEN
                  dbg_med ('Unexpected error while validaing Person Type');
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_valid,
                      p_error_text               => 'Unexpected error while validaing Person Type',
                      p_record_identifier_1      => p_rec_number,
                      p_record_identifier_2      => p_last_name,
                      p_record_identifier_3      => p_business_group,
                      p_record_identifier_4      => 'Applicant Data'
                     );
                  RETURN x_error_code;
            END;
         END IF;
      END;

      --**********************************************************************
      ---Function to Validate Vacancy Code
      --**********************************************************************
      FUNCTION is_vacancy_code_valid (
         p_rec_number       NUMBER,
         p_last_name        VARCHAR2,
         p_business_group   VARCHAR2,
         p_vacancy_code     VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_vacancy_code IS NULL
         THEN
            dbg_med ('Vacancy Code can not be Null ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                            (p_severity                 => xx_emf_cn_pkg.cn_medium,
                             p_category                 => xx_emf_cn_pkg.cn_valid,
                             p_error_text               => 'Vacancy Code can not be Null;',
                             p_record_identifier_1      => p_rec_number,
                             p_record_identifier_2      => p_last_name,
                             p_record_identifier_3      => p_business_group,
                             p_record_identifier_4      => 'Applicant Data'
                            );
            RETURN x_error_code;
         ELSE
            ---
            BEGIN
               SELECT pav.vacancy_id
                 INTO l_vacancy_id
                 FROM per_all_vacancies pav
                WHERE NAME = p_vacancy_code
                  AND business_group_id = l_business_grp_id;

               RETURN x_error_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  dbg_med ('Invalid Vacancy Code');
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                                   p_category                 => xx_emf_cn_pkg.cn_valid,
                                   p_error_text               => 'Invalid Vacancy Code',
                                   p_record_identifier_1      => p_rec_number,
                                   p_record_identifier_2      => p_last_name,
                                   p_record_identifier_3      => p_business_group,
                                   p_record_identifier_4      => 'Applicant Data'
                                  );
                  RETURN x_error_code;
               WHEN OTHERS
               THEN
                  dbg_med ('Unexpected error while validaing Vacancy Code');
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_valid,
                      p_error_text               => 'Unexpected error while validaing Vacancy Code',
                      p_record_identifier_1      => p_rec_number,
                      p_record_identifier_2      => p_last_name,
                      p_record_identifier_3      => p_business_group,
                      p_record_identifier_4      => 'Applicant Data'
                     );
                  RETURN x_error_code;
            END;
         END IF;
      END is_vacancy_code_valid;
   ----------------
   BEGIN
      g_api_name := 'xx_applicant_validation';
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Inside Data-Validations for Applicant'
                           );
      x_error_code_temp :=
         is_business_grp_valid (csr_applicant_print_rec.record_number,
                                csr_applicant_print_rec.last_name,
                                csr_applicant_print_rec.business_group_name
                               );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         is_person_valid (csr_applicant_print_rec.record_number,
                          csr_applicant_print_rec.last_name,
                          csr_applicant_print_rec.first_name,
                          csr_applicant_print_rec.business_group_name,
                          csr_applicant_print_rec.unique_id
                         );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         is_person_type_valid (csr_applicant_print_rec.record_number,
                               csr_applicant_print_rec.last_name,
                               csr_applicant_print_rec.business_group_name,
                               csr_applicant_print_rec.user_person_type
                              );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         is_vacancy_code_valid (csr_applicant_print_rec.record_number,
                                csr_applicant_print_rec.last_name,
                                csr_applicant_print_rec.business_group_name,
                                csr_applicant_print_rec.vacancy_number
                               );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      --xx_emf_pkg.propagate_error (x_error_code_temp);
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
   END xx_applicant_validation;

   --**********************************************************************
   ----Function to validate Phone data.
   --**********************************************************************
   FUNCTION xx_phone_validation (
      csr_phone_print_rec   IN OUT   xx_hr_appl_cnv_validation_pkg.g_xx_phone_stg_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER                  := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER                  := xx_emf_cn_pkg.cn_success;
      l_person_id         NUMBER                               := NULL;
      l_phone_type_code   fnd_lookup_values.lookup_code%TYPE;
      l_business_grp_id   NUMBER                               := NULL;

      --**********************************************************************
      ---Function to Validate Business Group Name
      --**********************************************************************
      FUNCTION is_business_grp_valid_ph (
         p_rec_number       NUMBER,
         p_last_name        VARCHAR2,
         p_business_group   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'p_last_name in BG' || p_last_name
                              );

         IF p_business_group IS NULL
         THEN
            dbg_med ('Business Group Name can not be Null ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                      (p_severity                 => xx_emf_cn_pkg.cn_medium,
                       p_category                 => xx_emf_cn_pkg.cn_valid,
                       p_error_text               => 'Business Group Name can not be Null',
                       p_record_identifier_1      => p_rec_number,
                       p_record_identifier_2      => p_last_name,
                       p_record_identifier_3      => p_business_group,
                       p_record_identifier_4      => 'Phone Data'
                      );
            RETURN x_error_code;
         ELSE
            BEGIN
               SELECT pbg.business_group_id
                 INTO l_business_grp_id
                 FROM per_business_groups pbg
                WHERE UPPER (pbg.NAME) = UPPER (p_business_group)
                  AND TRUNC (SYSDATE) BETWEEN date_from AND NVL (date_to,
                                                                 SYSDATE
                                                                );

               RETURN x_error_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  dbg_med ('Business Group Name can not be Null ');
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                         (p_severity                 => xx_emf_cn_pkg.cn_medium,
                          p_category                 => xx_emf_cn_pkg.cn_valid,
                          p_error_text               => 'Persons Last Name does not exist',
                          p_record_identifier_1      => p_rec_number,
                          p_record_identifier_2      => p_last_name,
                          p_record_identifier_3      => p_business_group,
                          p_record_identifier_4      => 'Phone Data'
                         );
                  RETURN x_error_code;
               WHEN OTHERS
               THEN
                  dbg_med
                     ('Unexpected error while validating the Business Group Name'
                     );
                  x_error_code_temp := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_valid,
                      p_error_text               => 'Unexpected error while validating the Business Group Name',
                      p_record_identifier_1      => p_rec_number,
                      p_record_identifier_2      => p_last_name,
                      p_record_identifier_3      => p_business_group,
                      p_record_identifier_4      => 'Phone Data'
                     );
                  RETURN x_error_code;
            END;
         END IF;
      END;

      --**********************************************************************
      ----Function to Validate Person's Name------------------------------
      --**********************************************************************
      FUNCTION is_person_valid_ph (
         p_rec_number       NUMBER,
         p_last_name        VARCHAR2,
         p_first_name       VARCHAR2,
         p_business_group   VARCHAR2,
         p_unique_id        VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         dbg_low ('p_last_name ' || p_last_name);

         IF p_last_name IS NULL
         THEN
            dbg_med ('Persons Last Name can not be Null ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_valid,
                         p_error_text               => 'Persons Last Name can not be Null',
                         p_record_identifier_1      => p_rec_number,
                         p_record_identifier_2      => p_last_name,
                         p_record_identifier_3      => p_business_group,
                         p_record_identifier_4      => 'Phone Data'
                        );
            RETURN x_error_code;
         ELSE
            BEGIN
               SELECT DISTINCT person_id
                          INTO l_person_id
                          FROM per_all_people_f papf
                         WHERE attribute1 = p_unique_id;

               --UPPER(last_name) = UPPER(p_last_name)
               --AND   UPPER(first_name)= UPPER(p_first_name)
               --AND   business_group_id = l_business_grp_id;
               RETURN x_error_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  dbg_med ('Persons Last Name can not be Null ');
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                         (p_severity                 => xx_emf_cn_pkg.cn_medium,
                          p_category                 => xx_emf_cn_pkg.cn_valid,
                          p_error_text               => 'Persons Last Name does not exist',
                          p_record_identifier_1      => p_rec_number,
                          p_record_identifier_2      => p_last_name,
                          p_record_identifier_3      => p_business_group,
                          p_record_identifier_4      => 'Phone Data'
                         );
                  RETURN x_error_code;
               WHEN OTHERS
               THEN
                  dbg_med
                        ('Unexpected error while validating the Persons Name');
                  x_error_code_temp := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_valid,
                      p_error_text               => 'Unexpected error while validating the Persons Name',
                      p_record_identifier_1      => p_rec_number,
                      p_record_identifier_2      => p_last_name,
                      p_record_identifier_3      => p_business_group,
                      p_record_identifier_4      => 'Phone Data'
                     );
                  RETURN x_error_code;
            END;
         END IF;
      END;

      --**********************************************************************
      ---Function to Validate Phone Type
      --**********************************************************************
      FUNCTION is_phone_type_valid (
         p_rec_number       NUMBER,
         p_last_name        VARCHAR2,
         p_business_group   VARCHAR2,
         p_phone_type       VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_phone_type IS NULL
         THEN
            dbg_med ('Phone Type can not be Null ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                              p_category                 => xx_emf_cn_pkg.cn_valid,
                              p_error_text               => 'Phone Type can not be Null;',
                              p_record_identifier_1      => p_rec_number,
                              p_record_identifier_2      => p_last_name,
                              p_record_identifier_3      => p_business_group,
                              p_record_identifier_4      => 'Phone Data'
                             );
            RETURN x_error_code;
         ELSE
            ---
            BEGIN
               SELECT lookup_code
                 INTO l_phone_type_code
                 FROM fnd_lookup_values
                WHERE lookup_type = 'PHONE_TYPE'
                  AND UPPER (meaning) = UPPER (p_phone_type)
                  AND enabled_flag = 'Y'
                  AND LANGUAGE = USERENV ('LANG')
                  AND view_application_id =
                                        (SELECT application_id
                                           FROM fnd_application
                                          WHERE application_short_name = 'AU');

               RETURN x_error_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  dbg_med ('Invalid Phone Type');
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                                   p_category                 => xx_emf_cn_pkg.cn_valid,
                                   p_error_text               => 'Invalid Phone Type',
                                   p_record_identifier_1      => p_rec_number,
                                   p_record_identifier_2      => p_last_name,
                                   p_record_identifier_3      => p_business_group,
                                   p_record_identifier_4      => 'Phone Data'
                                  );
                  RETURN x_error_code;
               WHEN OTHERS
               THEN
                  dbg_med ('Unexpected error while validaing Phone Type');
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_valid,
                      p_error_text               => 'Unexpected error while validaing Phone Type',
                      p_record_identifier_1      => p_rec_number,
                      p_record_identifier_2      => p_last_name,
                      p_record_identifier_3      => p_business_group,
                      p_record_identifier_4      => 'Phone Data'
                     );
                  RETURN x_error_code;
            END;
         END IF;
      END is_phone_type_valid;
----------------
   BEGIN
      g_api_name := 'xx_phone_validation';
      dbg_low ('Inside Data-Validations for Phone');
      dbg_low ('csr_phone_print_rec.last_name'
               || csr_phone_print_rec.last_name
              );
      dbg_low (   'csr_phone_print_rec.business_group_name'
               || csr_phone_print_rec.business_group_name
              );
      x_error_code_temp :=
         is_business_grp_valid_ph (csr_phone_print_rec.record_number,
                                   csr_phone_print_rec.last_name,
                                   csr_phone_print_rec.business_group_name
                                  );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         is_person_valid_ph (csr_phone_print_rec.record_number,
                             csr_phone_print_rec.last_name,
                             csr_phone_print_rec.first_name,
                             csr_phone_print_rec.business_group_name,
                             csr_phone_print_rec.unique_id
                            );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         is_phone_type_valid (csr_phone_print_rec.record_number,
                              csr_phone_print_rec.last_name,
                              csr_phone_print_rec.business_group_name,
                              csr_phone_print_rec.phone_type
                             );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      --xx_emf_pkg.propagate_error (x_error_code_temp);
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
   END xx_phone_validation;

   --**********************************************************************
   --Function to validate Resume Data
   --**********************************************************************
   FUNCTION xx_resume_validation (
      csr_resume_print_rec   IN OUT   xx_hr_appl_cnv_validation_pkg.g_xx_resume_stg_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
      l_person_id         NUMBER := NULL;
      l_business_grp_id   NUMBER := NULL;

      --**********************************************************************
      ----Function Validate Business Group Name------------------------------
      --**********************************************************************
      FUNCTION is_business_grp_valid_rm (
         p_rec_number       NUMBER,
         p_last_name        VARCHAR2,
         p_business_group   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         dbg_low ('p_last_name in BG' || p_last_name);

         IF p_business_group IS NULL
         THEN
            dbg_med ('Business Group Name cannot be Null ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                      (p_severity                 => xx_emf_cn_pkg.cn_medium,
                       p_category                 => xx_emf_cn_pkg.cn_valid,
                       p_error_text               => 'Business Group Name cannot be Null',
                       p_record_identifier_1      => p_rec_number,
                       p_record_identifier_2      => p_last_name,
                       p_record_identifier_3      => p_business_group,
                       p_record_identifier_4      => 'Resume Data'
                      );
            RETURN x_error_code;
         ELSE
            BEGIN
               SELECT pbg.business_group_id
                 INTO l_business_grp_id
                 FROM per_business_groups pbg
                WHERE UPPER (pbg.NAME) = UPPER (p_business_group)
                  AND TRUNC (SYSDATE) BETWEEN date_from AND NVL (date_to,
                                                                 SYSDATE
                                                                );

               RETURN x_error_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  dbg_med ('Business Group Name not Valid ');
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                         (p_severity                 => xx_emf_cn_pkg.cn_medium,
                          p_category                 => xx_emf_cn_pkg.cn_valid,
                          p_error_text               => 'Business Group Name not Valid',
                          p_record_identifier_1      => p_rec_number,
                          p_record_identifier_2      => p_last_name,
                          p_record_identifier_3      => p_business_group,
                          p_record_identifier_4      => 'Resume Data'
                         );
                  RETURN x_error_code;
               WHEN OTHERS
               THEN
                  dbg_med
                     ('Unexpected error while validating the Business Group Name'
                     );
                  x_error_code_temp := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_valid,
                      p_error_text               => 'Unexpected error while validating the Business Group Name',
                      p_record_identifier_1      => p_rec_number,
                      p_record_identifier_2      => p_last_name,
                      p_record_identifier_3      => p_business_group,
                      p_record_identifier_4      => 'Resume Data'
                     );
                  RETURN x_error_code;
            END;
         END IF;
      END;

      --**********************************************************************
      -------Function Validate Person's Name------------------------------
      --**********************************************************************
      FUNCTION is_person_valid_rm (
         p_rec_number       NUMBER,
         p_last_name        VARCHAR2,
         p_first_name       VARCHAR2,
         p_business_group   VARCHAR2,
         p_unique_id        VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         dbg_low ('p_last_name ' || p_last_name);

         IF p_last_name IS NULL
         THEN
            dbg_med ('Persons Last Name cannot be Null ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_valid,
                         p_error_text               => 'Person Last Name cannot be Null',
                         p_record_identifier_1      => p_rec_number,
                         p_record_identifier_2      => p_last_name,
                         p_record_identifier_3      => p_business_group,
                         p_record_identifier_4      => 'Resume Data'
                        );
            RETURN x_error_code;
         ELSE
            BEGIN
               SELECT DISTINCT person_id
                          INTO l_person_id
                          FROM per_all_people_f papf
                         WHERE attribute1 = p_unique_id;
               RETURN x_error_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  dbg_med ('Persons Last Name can not be Null ');
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                         (p_severity                 => xx_emf_cn_pkg.cn_medium,
                          p_category                 => xx_emf_cn_pkg.cn_valid,
                          p_error_text               => 'Person does not exist',
                          p_record_identifier_1      => p_rec_number,
                          p_record_identifier_2      => p_last_name,
                          p_record_identifier_3      => p_business_group,
                          p_record_identifier_4      => 'Resume Data'
                         );
                  RETURN x_error_code;
               WHEN OTHERS
               THEN
                  dbg_med
                        ('Unexpected error while validating the Persons Name');
                  x_error_code_temp := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_valid,
                      p_error_text               => 'Unexpected error while validating the Person',
                      p_record_identifier_1      => p_rec_number,
                      p_record_identifier_2      => p_last_name,
                      p_record_identifier_3      => p_business_group,
                      p_record_identifier_4      => 'Resume Data'
                     );
                  RETURN x_error_code;
            END;
         END IF;
      END;
----------------
   BEGIN
      g_api_name := 'xx_resume_validation';
      dbg_low ('Inside Data-Validations for Resume');
      dbg_low (   'csr_resume_print_rec.last_name'
               || csr_resume_print_rec.last_name
              );
      dbg_low (   'csr_resume_print_rec.business_group_name'
               || csr_resume_print_rec.business_group_name
              );
      x_error_code_temp :=
         is_business_grp_valid_rm (csr_resume_print_rec.record_number,
                                   csr_resume_print_rec.last_name,
                                   csr_resume_print_rec.business_group_name
                                  );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         is_person_valid_rm (csr_resume_print_rec.record_number,
                             csr_resume_print_rec.last_name,
                             csr_resume_print_rec.first_name,
                             csr_resume_print_rec.business_group_name,
                             csr_resume_print_rec.unique_id
                            );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      -- xx_emf_pkg.propagate_error (x_error_code_temp);
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
   END xx_resume_validation;

   --**********************************************************************
   ------Function for Applicant Derivations
   --**********************************************************************
   FUNCTION xx_applicant_data_derivations (
      csr_applicant_print_rec   IN OUT   xx_hr_appl_cnv_validation_pkg.g_xx_applicant_stg_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code                  NUMBER        := xx_emf_cn_pkg.cn_success;
      x_error_code_temp             NUMBER        := xx_emf_cn_pkg.cn_success;
      l_business_group_id           NUMBER                            := NULL;
      l_person_id                   NUMBER                            := NULL;
      -- Added manager id for Hr May 2013 release
      l_manager_id                  NUMBER                            :=NULL;
      
      l_object_version_number       per_all_people_f.object_version_number%TYPE
                                                                      := NULL;
      l_vacancy_id                  NUMBER                            := NULL;
      l_person_type_id              NUMBER                            := NULL;
      l_assignment_status_type_id   NUMBER                            := NULL;
      --l_referred_by_id     NUMBER:=NULL;
      l_recruiter_by_id             NUMBER                            := NULL;
      l_source_type                 fnd_lookup_values.lookup_code%TYPE;

      --**********************************************************************
      --------Function to Derive business_group_id---------------------
      --**********************************************************************
      FUNCTION get_target_business_group_id (
         p_rec_number                NUMBER,
         p_last_name                 VARCHAR2,
         p_business_group            VARCHAR2,
         p_business_group_id   OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         p_business_group_id := NULL;

         SELECT pbg.business_group_id
           INTO l_business_group_id
           FROM per_business_groups pbg
          WHERE UPPER (pbg.NAME) = UPPER (p_business_group)
            AND TRUNC (SYSDATE) BETWEEN date_from AND NVL (date_to, SYSDATE);

         p_business_group_id := l_business_group_id;
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dbg_med ('Business Group does not exist ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                            (p_severity                 => xx_emf_cn_pkg.cn_medium,
                             p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                             p_error_text               => 'Business Group does not exist',
                             p_record_identifier_1      => p_rec_number,
                             p_record_identifier_2      => p_last_name,
                             p_record_identifier_3      => p_business_group,
                             p_record_identifier_4      => 'Applicant Data'
                            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            dbg_med ('Unexpected error while deriving the Business Group');
            x_error_code_temp := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               => 'Unexpected error while deriving the Business Group',
                p_record_identifier_1      => p_rec_number,
                p_record_identifier_2      => p_last_name,
                p_record_identifier_3      => p_business_group,
                p_record_identifier_4      => 'Applicant Data'
               );
            RETURN x_error_code;
      END get_target_business_group_id;

      --**********************************************************************
      ----Function to Derive person_id--------------------------------------
      --**********************************************************************
      FUNCTION get_target_person_id (
         p_rec_number             NUMBER,
         p_last_name              VARCHAR2,
         p_business_group         VARCHAR2,
         p_first_name             VARCHAR2,
         p_unique_id              VARCHAR2,
         p_person_id        OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         SELECT DISTINCT person_id
                    INTO l_person_id
                    FROM per_all_people_f papf
                    -- Modified by Aabhas on 6th May 2013 
                   WHERE UPPER (nvl(last_name,'A')) = UPPER (nvl(p_last_name,UPPER (nvl(last_name,'A'))))
                     AND UPPER (nvl(first_name,'A')) = UPPER (nvl(p_first_name,UPPER (nvl(first_name,'A'))))
                     AND attribute1 = p_unique_id
                     AND business_group_id = l_business_group_id;

         p_person_id := l_person_id;
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dbg_med ('Unable to derive Person id');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                              p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                              p_error_text               => 'Unable to derive Person id',
                              p_record_identifier_1      => p_rec_number,
                              p_record_identifier_2      => p_last_name,
                              p_record_identifier_3      => p_business_group,
                              p_record_identifier_4      => 'Applicant Data'
                             );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            dbg_med ('Unexpected error while deriving Person id');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                (p_severity                 => xx_emf_cn_pkg.cn_medium,
                 p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                 p_error_text               => 'Unexpected error while deriving Person id',
                 p_record_identifier_1      => p_rec_number,
                 p_record_identifier_2      => p_last_name,
                 p_record_identifier_3      => p_business_group,
                 p_record_identifier_4      => 'Applicant Data'
                );
            RETURN x_error_code;
      END get_target_person_id;

      --**********************************************************************
      ----Function to Manager person_id--------------------------------------
      -- Added for May 2013 HR release ---
      --**********************************************************************
      FUNCTION get_manager_person_id (
         p_rec_number             NUMBER,
         p_last_name              VARCHAR2,
         p_business_group         VARCHAR2,
         p_first_name             VARCHAR2,
         p_mgr_unique_id              VARCHAR2,
         p_mgr_person_id        OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         SELECT DISTINCT person_id
                    INTO l_manager_id
                    FROM per_all_people_f papf
                    -- Modified by Aabhas on 6th May 2013 Since we just need to fetch the manage id based on Unique ID 
                   WHERE --UPPER (last_name) = UPPER (p_last_name)
                     --AND UPPER (first_name) = UPPER (p_first_name)
                      attribute1 = p_mgr_unique_id
                     AND business_group_id = l_business_group_id;

         p_mgr_person_id := l_manager_id;
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dbg_med ('Unable to derive manager id');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                              p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                              p_error_text               => 'Unable to derive manager id',
                              p_record_identifier_1      => p_rec_number,
                              p_record_identifier_2      => p_last_name,
                              p_record_identifier_3      => p_business_group,
                              p_record_identifier_4      => 'Applicant Data'
                             );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            dbg_med ('Unexpected error while deriving manager id');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                (p_severity                 => xx_emf_cn_pkg.cn_medium,
                 p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                 p_error_text               => 'Unexpected error while deriving manager id',
                 p_record_identifier_1      => p_rec_number,
                 p_record_identifier_2      => p_last_name,
                 p_record_identifier_3      => p_business_group,
                 p_record_identifier_4      => 'Applicant Data'
                );
            RETURN x_error_code;
      END get_manager_person_id;

      --**********************************************************************
      ------Function to Derive object_version_number------------------
      --**********************************************************************
      FUNCTION get_target_object_ver_number (
         p_rec_number                    NUMBER,
         p_last_name                     VARCHAR2,
         p_business_group                VARCHAR2,
         p_application_date              DATE,
         p_object_version_number   OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         SELECT papf.object_version_number
           INTO l_object_version_number
           FROM per_all_people_f papf
          WHERE papf.person_id = l_person_id
            AND NVL (p_application_date, SYSDATE)
                   BETWEEN papf.effective_start_date
                       AND papf.effective_end_date
            AND papf.business_group_id = l_business_group_id;

         p_object_version_number := l_object_version_number;
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dbg_med ('Unable to derive object version number');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
                    p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                    p_error_text               => 'Unable to derive object version number',
                    p_record_identifier_1      => p_rec_number,
                    p_record_identifier_2      => p_last_name,
                    p_record_identifier_3      => p_business_group,
                    p_record_identifier_4      => 'Applicant Data'
                   );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            dbg_med ('Unexpected error while deriving object version number');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               => 'Unexpected error while deriving object version number',
                p_record_identifier_1      => p_rec_number,
                p_record_identifier_2      => p_last_name,
                p_record_identifier_3      => p_business_group,
                p_record_identifier_4      => 'Applicant Data'
               );
            RETURN x_error_code;
      END get_target_object_ver_number;

      --**********************************************************************
      -------Function to Derive vacancy_id------------------------------------
      --**********************************************************************
      FUNCTION get_target_vacancy_id (
         p_rec_number             NUMBER,
         p_last_name              VARCHAR2,
         p_business_group         VARCHAR2,
         p_vacancy_code           VARCHAR2,
         p_vacancy_id       OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         SELECT pav.vacancy_id
           INTO l_vacancy_id
           FROM per_all_vacancies pav
          WHERE NAME = p_vacancy_code
            AND business_group_id = l_business_group_id;

         p_vacancy_id := l_vacancy_id;
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dbg_med ('Unable to derive Vacancy id ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                              p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                              p_error_text               => 'Unable to derive Vacancy id ',
                              p_record_identifier_1      => p_rec_number,
                              p_record_identifier_2      => p_last_name,
                              p_record_identifier_3      => p_business_group,
                              p_record_identifier_4      => 'Applicant Data'
                             );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            dbg_med (' Unexpected error while deriving the Vacancy Id ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               => 'Unexpected error while deriving the Vacancy Id ',
                p_record_identifier_1      => p_rec_number,
                p_record_identifier_2      => p_last_name,
                p_record_identifier_3      => p_business_group,
                p_record_identifier_4      => 'Applicant Data'
               );
            RETURN x_error_code;
      END get_target_vacancy_id;

      --**********************************************************************
      -----Function to Derive person_type_id------------------------------------
      --**********************************************************************
      FUNCTION get_target_person_type_id (
         p_rec_number               NUMBER,
         p_last_name                VARCHAR2,
         p_business_group           VARCHAR2,
         p_user_person_type         VARCHAR2,
         p_person_type_id     OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         SELECT ppt.person_type_id
           INTO l_person_type_id
           FROM per_person_types ppt
          WHERE UPPER (user_person_type) = UPPER (p_user_person_type)
            AND business_group_id = l_business_group_id;

         p_person_type_id := l_person_type_id;
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dbg_med ('Unable to derive Person Type Id ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                          (p_severity                 => xx_emf_cn_pkg.cn_medium,
                           p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                           p_error_text               => 'Unable to derive Person Type Id',
                           p_record_identifier_1      => p_rec_number,
                           p_record_identifier_2      => p_last_name,
                           p_record_identifier_3      => p_business_group,
                           p_record_identifier_4      => 'Applicant Data'
                          );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            dbg_med (' Unexpected error while deriving the Person Type Id ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               => 'Unexpected error while deriving the Person Type Id ',
                p_record_identifier_1      => p_rec_number,
                p_record_identifier_2      => p_last_name,
                p_record_identifier_3      => p_business_group,
                p_record_identifier_4      => 'Applicant Data'
               );
            RETURN x_error_code;
      END get_target_person_type_id;

      --**********************************************************************
      ------Function to Derive assign_status_id-------------------------------
      --**********************************************************************
      FUNCTION get_target_assign_status_id (
         p_rec_number                        NUMBER,
         p_last_name                         VARCHAR2,
         p_business_group                    VARCHAR2,
         p_applicant_status                  VARCHAR2,
         p_assignment_status_type_id   OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         SELECT assignment_status_type_id
           INTO l_assignment_status_type_id
           FROM (SELECT pastt.assignment_status_type_id
                   FROM per_assignment_status_types_tl pastt
                  WHERE UPPER (user_status) = UPPER (p_applicant_status)
                 UNION
                 SELECT st.assignment_status_type_id
                   FROM per_ass_status_type_amends_tl pas,
                        per_ass_status_type_amends st
                  WHERE st.ass_status_type_amend_id = pas.ass_status_type_amend_id(+)
                    AND UPPER (pas.user_status) = UPPER (p_applicant_status));

         --AND   business_group_id = l_business_group_id;
         p_assignment_status_type_id := l_assignment_status_type_id;
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dbg_med ('Applicant Status does not exist ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                     p_error_text               => 'Unable to derive Assignment Status Id',
                     p_record_identifier_1      => p_rec_number,
                     p_record_identifier_2      => p_last_name,
                     p_record_identifier_3      => p_business_group,
                     p_record_identifier_4      => 'Applicant Data'
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            dbg_med
                (' Unexpected error while deriving the Assignment Status Id ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               => 'Unexpected error while deriving the Assignment Status Id ',
                p_record_identifier_1      => p_rec_number,
                p_record_identifier_2      => p_last_name,
                p_record_identifier_3      => p_business_group,
                p_record_identifier_4      => 'Applicant Data'
               );
            RETURN x_error_code;
      END get_target_assign_status_id;

      --**********************************************************************
      ----Function to Derive Recruiter by id----------------------------------
      --**********************************************************************
      FUNCTION get_target_recruiter_by_id (
         p_rec_number              NUMBER,
         p_last_name               VARCHAR2,
         p_business_group          VARCHAR2,
         p_recruiter_by            VARCHAR2,
         p_recruiter_by_id   OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_recruiter_by IS NULL
         THEN
            p_recruiter_by_id := NULL;
            dbg_low ('p_recruiter_by is Null');
         ELSE
            SELECT DISTINCT person_id
                       INTO l_recruiter_by_id
                       FROM per_all_people_f papf
                      WHERE attribute1 = p_recruiter_by;

            p_recruiter_by_id := l_recruiter_by_id;
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Inside get_target_recruiter_by_id'
                               || p_recruiter_by_id
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dbg_med ('Unable to derive Recruiter id');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                            (p_severity                 => xx_emf_cn_pkg.cn_medium,
                             p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                             p_error_text               => 'Unable to derive Recruiter id',
                             p_record_identifier_1      => p_rec_number,
                             p_record_identifier_2      => p_last_name,
                             p_record_identifier_3      => p_business_group,
                             p_record_identifier_4      => 'Applicant Data'
                            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            dbg_med ('Unexpected error while deriving Recruiter id');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               => 'Unexpected error while deriving Recruiter id',
                p_record_identifier_1      => p_rec_number,
                p_record_identifier_2      => p_last_name,
                p_record_identifier_3      => p_business_group,
                p_record_identifier_4      => 'Applicant Data'
               );
            RETURN x_error_code;
      END get_target_recruiter_by_id;

      --**********************************************************************
      -----Function to Derive source_type------------------------------------
      --**********************************************************************
      FUNCTION get_target_source_type (
         p_rec_number               NUMBER,
         p_last_name                VARCHAR2,
         p_business_group           VARCHAR2,
         p_applicant_source         VARCHAR2,
         p_source_type        OUT   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_applicant_source IS NULL
         THEN
            p_source_type := NULL;
            dbg_low ('Source Type is Null');
         ELSE
            SELECT lookup_code
              INTO l_source_type
              FROM fnd_lookup_values
             WHERE lookup_type = 'REC_TYPE'
               AND UPPER (meaning) = UPPER (p_applicant_source)
               AND enabled_flag = 'Y'
               AND LANGUAGE = USERENV ('LANG');

            p_source_type := l_source_type;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dbg_med ('Unable to derive Source Type ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                              p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                              p_error_text               => 'Unable to derive Source Type',
                              p_record_identifier_1      => p_rec_number,
                              p_record_identifier_2      => p_last_name,
                              p_record_identifier_3      => p_business_group,
                              p_record_identifier_4      => 'Applicant Data'
                             );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            dbg_med (' Unexpected error while deriving the Source Type ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               => 'Unexpected error while deriving the Source Type ',
                p_record_identifier_1      => p_rec_number,
                p_record_identifier_2      => p_last_name,
                p_record_identifier_3      => p_business_group,
                p_record_identifier_4      => 'Applicant Data'
               );
            RETURN x_error_code;
      END get_target_source_type;
----------------------------------------------------------------------------------------------------------
   BEGIN
      g_api_name := 'xx_applicant_data_derivations';
      --get the organization_id
      dbg_low ('Inside Data-Derivations for Applicant');
      x_error_code_temp :=
         get_target_business_group_id
                                (csr_applicant_print_rec.record_number,
                                 csr_applicant_print_rec.last_name,
                                 csr_applicant_print_rec.business_group_name,
                                 csr_applicant_print_rec.business_group_id
                                );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         get_target_person_id (csr_applicant_print_rec.record_number,
                               csr_applicant_print_rec.last_name,
                               csr_applicant_print_rec.business_group_name,
                               csr_applicant_print_rec.first_name,
                               csr_applicant_print_rec.unique_id,
                               csr_applicant_print_rec.person_id
                              );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      
      --- Added for HR May 2013 release
      x_error_code_temp :=
               get_manager_person_id (csr_applicant_print_rec.record_number,
                                     csr_applicant_print_rec.last_name,
                                     csr_applicant_print_rec.business_group_name,
                                     csr_applicant_print_rec.first_name,
                                     csr_applicant_print_rec.manager_unique_id,
                                     csr_applicant_print_rec.manager_person_id
                                    );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      ---------
      x_error_code_temp :=
         get_target_object_ver_number
                            (csr_applicant_print_rec.record_number,
                             csr_applicant_print_rec.last_name,
                             csr_applicant_print_rec.business_group_name,
                             csr_applicant_print_rec.application_date,
                             csr_applicant_print_rec.per_object_version_number
                            );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         get_target_vacancy_id (csr_applicant_print_rec.record_number,
                                csr_applicant_print_rec.last_name,
                                csr_applicant_print_rec.business_group_name,
                                csr_applicant_print_rec.vacancy_number,
                                csr_applicant_print_rec.vacancy_id
                               );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         get_target_person_type_id
                                 (csr_applicant_print_rec.record_number,
                                  csr_applicant_print_rec.last_name,
                                  csr_applicant_print_rec.business_group_name,
                                  g_applicant_person_type,
                                  csr_applicant_print_rec.person_type_id
                                 );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         get_target_assign_status_id
                            (csr_applicant_print_rec.record_number,
                             csr_applicant_print_rec.last_name,
                             csr_applicant_print_rec.business_group_name,
                             csr_applicant_print_rec.applicant_status,
                             csr_applicant_print_rec.assignment_status_type_id
                            );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         get_target_recruiter_by_id
                                 (csr_applicant_print_rec.record_number,
                                  csr_applicant_print_rec.last_name,
                                  csr_applicant_print_rec.business_group_name,
                                  csr_applicant_print_rec.recruiter,
                                  csr_applicant_print_rec.recruiter_id
                                 );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         get_target_source_type (csr_applicant_print_rec.record_number,
                                 csr_applicant_print_rec.last_name,
                                 csr_applicant_print_rec.business_group_name,
                                 csr_applicant_print_rec.applicant_source,
                                 csr_applicant_print_rec.source_type
                                );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      --xx_emf_pkg.propagate_error ( x_error_code_temp );
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
   END xx_applicant_data_derivations;

   --**********************************************************************
   --------Function for Phone Derivations
   --**********************************************************************
   FUNCTION xx_phone_data_derivations (
      csr_phone_print_rec   IN OUT   xx_hr_appl_cnv_validation_pkg.g_xx_phone_stg_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code          NUMBER                := xx_emf_cn_pkg.cn_success;
      x_error_code_temp     NUMBER                := xx_emf_cn_pkg.cn_success;
      l_business_group_id   NUMBER                               := NULL;
      l_person_id           NUMBER                               := NULL;
      l_phone_type_code     fnd_lookup_values.lookup_code%TYPE;

      --**********************************************************************
      ------Function to Derive business_group_id---------------------
      --**********************************************************************
      FUNCTION get_target_business_group_id (
         p_rec_number                NUMBER,
         p_last_name                 VARCHAR2,
         p_business_group            VARCHAR2,
         p_business_group_id   OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         p_business_group_id := NULL;

         SELECT pbg.business_group_id
           INTO l_business_group_id
           FROM per_business_groups pbg
          WHERE UPPER (pbg.NAME) = UPPER (p_business_group)
            AND TRUNC (SYSDATE) BETWEEN date_from AND NVL (date_to, SYSDATE);

         p_business_group_id := l_business_group_id;
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dbg_med ('Business Group does not exist ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                            (p_severity                 => xx_emf_cn_pkg.cn_medium,
                             p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                             p_error_text               => 'Business Group does not exist',
                             p_record_identifier_1      => p_rec_number,
                             p_record_identifier_2      => p_last_name,
                             p_record_identifier_3      => p_business_group,
                             p_record_identifier_4      => 'Phone Data'
                            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            dbg_med ('Unexpected error while deriving the Business Group');
            x_error_code_temp := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               => 'Unexpected error while deriving the Business Group',
                p_record_identifier_1      => p_rec_number,
                p_record_identifier_2      => p_last_name,
                p_record_identifier_3      => p_business_group,
                p_record_identifier_4      => 'Phone Data'
               );
            RETURN x_error_code;
      END get_target_business_group_id;

      --**********************************************************************
      ------Function to Derive person_id--------------------------------------
      --**********************************************************************
      FUNCTION get_target_person_id (
         p_rec_number             NUMBER,
         p_last_name              VARCHAR2,
         p_business_group         VARCHAR2,
         p_first_name             VARCHAR2,
         p_unique_id              VARCHAR2,
         p_person_id        OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         dbg_low ('Inside get_target_person_id for Phone' || p_last_name);

         SELECT DISTINCT person_id
                    INTO l_person_id
                    FROM per_all_people_f papf
                    -- Modified by Aabhas on 6th May 2013 
                   WHERE UPPER (nvl(last_name,'A')) = UPPER (nvl(p_last_name,UPPER (nvl(last_name,'A'))))
                     AND UPPER (nvl(first_name,'A')) = UPPER (nvl(p_first_name,UPPER (nvl(first_name,'A'))))
                     AND attribute1 = p_unique_id
                     AND business_group_id = l_business_group_id;

         p_person_id := l_person_id;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'p_person_id' || p_person_id
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dbg_med ('Unable to derive Person id');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                              p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                              p_error_text               => 'Unable to derive Person id',
                              p_record_identifier_1      => p_rec_number,
                              p_record_identifier_2      => p_last_name,
                              p_record_identifier_3      => p_business_group,
                              p_record_identifier_4      => 'Phone Data'
                             );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            dbg_med ('Unexpected error while deriving Person id');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                (p_severity                 => xx_emf_cn_pkg.cn_medium,
                 p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                 p_error_text               => 'Unexpected error while deriving Person id',
                 p_record_identifier_1      => p_rec_number,
                 p_record_identifier_2      => p_last_name,
                 p_record_identifier_3      => p_business_group,
                 p_record_identifier_4      => 'Phone Data'
                );
            RETURN x_error_code;
      END get_target_person_id;

      --**********************************************************************
      ------Function to Derive ph_type_code------------------------------------
      --**********************************************************************
      FUNCTION get_target_ph_type_code (
         p_rec_number              NUMBER,
         p_last_name               VARCHAR2,
         p_business_group          VARCHAR2,
         p_phone_type              VARCHAR2,
         p_phone_type_code   OUT   VARCHAR2
      )
         RETURN VARCHAR2
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         SELECT lookup_code
           INTO l_phone_type_code
           FROM fnd_lookup_values
          WHERE lookup_type = 'PHONE_TYPE'
            AND UPPER (meaning) = UPPER (p_phone_type)
            AND enabled_flag = 'Y'
            AND LANGUAGE = USERENV ('LANG')
            AND view_application_id = (SELECT application_id
                                         FROM fnd_application
                                        WHERE application_short_name = 'AU');

         p_phone_type_code := l_phone_type_code;
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dbg_med ('Unable to derive Phone Type Code ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                         p_error_text               => 'Unable to derive Phone Type Code ',
                         p_record_identifier_1      => p_rec_number,
                         p_record_identifier_2      => p_last_name,
                         p_record_identifier_3      => p_business_group,
                         p_record_identifier_4      => 'Phone Data'
                        );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            dbg_med (' Unexpected error while deriving the Phone Type Code ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               => 'Unexpected error while deriving the Phone Type Code ',
                p_record_identifier_1      => p_rec_number,
                p_record_identifier_2      => p_last_name,
                p_record_identifier_3      => p_business_group,
                p_record_identifier_4      => 'Phone Data'
               );
            RETURN x_error_code;
      END get_target_ph_type_code;
-----------------------------------
   BEGIN
      g_api_name := 'xx_phone_data_derivations';
      --get the organization_id
      dbg_low ('Inside Data-Derivations for Phone');
      x_error_code_temp :=
         get_target_business_group_id
                                    (csr_phone_print_rec.record_number,
                                     csr_phone_print_rec.last_name,
                                     csr_phone_print_rec.business_group_name,
                                     csr_phone_print_rec.business_group_id
                                    );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         get_target_person_id (csr_phone_print_rec.record_number,
                               csr_phone_print_rec.last_name,
                               csr_phone_print_rec.business_group_name,
                               csr_phone_print_rec.first_name,
                               csr_phone_print_rec.unique_id,
                               csr_phone_print_rec.person_id
                              );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         get_target_ph_type_code (csr_phone_print_rec.record_number,
                                  csr_phone_print_rec.last_name,
                                  csr_phone_print_rec.business_group_name,
                                  csr_phone_print_rec.phone_type,
                                  csr_phone_print_rec.phone_type_code
                                 );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      --xx_emf_pkg.propagate_error ( x_error_code_temp );
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
   END xx_phone_data_derivations;

   --**********************************************************************
   ---------Function for Resume Derivations
   --**********************************************************************
   FUNCTION xx_resume_data_derivations (
      csr_resume_print_rec   IN OUT   xx_hr_appl_cnv_validation_pkg.g_xx_resume_stg_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code          NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp     NUMBER := xx_emf_cn_pkg.cn_success;
      l_business_group_id   NUMBER := NULL;
      l_person_id           NUMBER := NULL;

      --**********************************************************************
      ----Function to Derive business_group_id------------------------------
      --**********************************************************************
      FUNCTION get_target_business_group_id (
         p_rec_number                NUMBER,
         p_last_name                 VARCHAR2,
         p_business_group            VARCHAR2,
         p_business_group_id   OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         p_business_group_id := NULL;

         SELECT pbg.business_group_id
           INTO l_business_group_id
           FROM per_business_groups pbg
          WHERE UPPER (pbg.NAME) = UPPER (p_business_group)
            AND TRUNC (SYSDATE) BETWEEN date_from AND NVL (date_to, SYSDATE);

         p_business_group_id := l_business_group_id;
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dbg_med ('Business Group does not exist ');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                            (p_severity                 => xx_emf_cn_pkg.cn_medium,
                             p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                             p_error_text               => 'Business Group does not exist',
                             p_record_identifier_1      => p_rec_number,
                             p_record_identifier_2      => p_last_name,
                             p_record_identifier_3      => p_business_group,
                             p_record_identifier_4      => 'Resume Data'
                            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            dbg_med ('Unexpected error while deriving the Business Group');
            x_error_code_temp := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               => 'Unexpected error while deriving the Business Group',
                p_record_identifier_1      => p_rec_number,
                p_record_identifier_2      => p_last_name,
                p_record_identifier_3      => p_business_group,
                p_record_identifier_4      => 'Resume Data'
               );
            RETURN x_error_code;
      END get_target_business_group_id;

      --**********************************************************************
      -------Function to Derive person_id--------------------------------------
      --**********************************************************************
      FUNCTION get_target_person_id (
         p_rec_number             NUMBER,
         p_last_name              VARCHAR2,
         p_business_group         VARCHAR2,
         p_first_name             VARCHAR2,
         p_unique_id              VARCHAR2,
         p_person_id        OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         dbg_low ('Inside get_target_person_id for Phone' || p_last_name);

         SELECT DISTINCT person_id
                    INTO l_person_id
                    FROM per_all_people_f papf
                   -- Modified by Aabhas on 6th May 2013 
                   WHERE UPPER (nvl(last_name,'A')) = UPPER (nvl(p_last_name,UPPER (nvl(last_name,'A'))))
                     AND UPPER (nvl(first_name,'A')) = UPPER (nvl(p_first_name,UPPER (nvl(first_name,'A'))))
                     AND attribute1 = p_unique_id
                     AND business_group_id = l_business_group_id;

         p_person_id := l_person_id;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'p_person_id' || p_person_id
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dbg_med ('Unable to derive Person id');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                              p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                              p_error_text               => 'Unable to derive Person id',
                              p_record_identifier_1      => p_rec_number,
                              p_record_identifier_2      => p_last_name,
                              p_record_identifier_3      => p_business_group,
                              p_record_identifier_4      => 'Resume Data'
                             );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            dbg_med ('Unexpected error while deriving Person id');
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                (p_severity                 => xx_emf_cn_pkg.cn_medium,
                 p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                 p_error_text               => 'Unexpected error while deriving Person id',
                 p_record_identifier_1      => p_rec_number,
                 p_record_identifier_2      => p_last_name,
                 p_record_identifier_3      => p_business_group,
                 p_record_identifier_4      => 'Resume Data'
                );
            RETURN x_error_code;
      END get_target_person_id;
-----------------------------------
   BEGIN
      g_api_name := 'xx_resume_data_derivations';
      --get the organization_id
      dbg_low ('Inside Data-Derivations for Resume');
      x_error_code_temp :=
         get_target_business_group_id
                                   (csr_resume_print_rec.record_number,
                                    csr_resume_print_rec.last_name,
                                    csr_resume_print_rec.business_group_name,
                                    csr_resume_print_rec.business_group_id
                                   );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         get_target_person_id (csr_resume_print_rec.record_number,
                               csr_resume_print_rec.last_name,
                               csr_resume_print_rec.business_group_name,
                               csr_resume_print_rec.first_name,
                               csr_resume_print_rec.unique_id,
                               csr_resume_print_rec.person_id
                              );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      --xx_emf_pkg.propagate_error ( x_error_code_temp );
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
   END xx_resume_data_derivations;

   --**********************************************************************
   --------Function for post validation-----------------------------------
   --**********************************************************************
   FUNCTION post_validations_applicant
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      g_api_name := 'main.post_validations';
      dbg_low ('Inside Post-Validations for Applicant');
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
                               'Completed Post-Validations'
                              );
   END post_validations_applicant;

   --**********************************************************************
   -------Function to post validation for phone---------------------------
   --**********************************************************************
   FUNCTION post_validations_phone
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      g_api_name := 'main.post_validations_phone';
      dbg_low ('Inside Post-Validations for Phone');
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
                               'Completed Post-Validations for Phone'
                              );
   END post_validations_phone;

   --**********************************************************************
   -----Function to post validation for resume------------------------------
   --**********************************************************************
   FUNCTION post_validations_resume
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      g_api_name := 'main.post_validations_resume';
      dbg_low ('Inside Post-Validations for resume');
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
                               'Completed Post-Validations for resume'
                              );
   END post_validations_resume;

   --**********************************************************************
   -----Function to call Applicant API.
   --**********************************************************************
   FUNCTION xx_create_appl_by_api (
      csr_applicant_print_rec   IN OUT   xx_hr_appl_cnv_validation_pkg.g_xx_applicant_stg_rec_type
   )
      RETURN NUMBER
   IS
      --Variable Declaration
      x_error_code                   NUMBER       := xx_emf_cn_pkg.cn_success;
      x_error_code_temp              NUMBER       := xx_emf_cn_pkg.cn_success;
      l_application_id               per_applications.application_id%TYPE;
      l_assignment_id                per_assignments_f.assignment_id%TYPE;
      l_assignment_sequence          per_assignments_f.assignment_sequence%TYPE;
      l_apl_object_version_number    per_applications.object_version_number%TYPE;
      l_asg_object_version_number    per_all_assignments_f.object_version_number%TYPE;
      l_per_effective_start_date     per_all_people_f.effective_start_date%TYPE;
      l_per_effective_end_date       per_all_people_f.effective_end_date%TYPE;
      l_appl_override_warning        BOOLEAN;
      l_applicant_number             VARCHAR2 (50)                    := NULL;
      l_cagr_grade_def_id            NUMBER;
      l_cagr_concatenated_segments   VARCHAR2 (30);
      l_group_name                   VARCHAR2 (30);
      l_comment_id                   NUMBER;
      l_people_group_id              NUMBER;
      l_soft_coding_keyflex_id       NUMBER;
      l_object_version_number        NUMBER;
      l_effective_start_date         DATE;
      l_effective_end_date           DATE;
      l_concatenated_segments        VARCHAR2 (30);
   BEGIN
      g_api_name := 'xx_create_appl_by_api';
      dbg_low ('Inside xx_create_appl_by_api By API');

      --------Derive referred_by_id--------------------
      IF csr_applicant_print_rec.referred_by IS NOT NULL
      THEN
         dbg_low ('referred_by IS NOT NULL');

         BEGIN
            SELECT DISTINCT person_id
                       INTO csr_applicant_print_rec.referred_by_id
                       FROM per_all_people_f
                      WHERE attribute1 = csr_applicant_print_rec.referred_by;

            dbg_low (   'referred_by_id:'
                     || csr_applicant_print_rec.referred_by_id
                    );
         EXCEPTION
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log
                                 (xx_emf_cn_pkg.cn_low,
                                     'Error while deriving referred_by_id : '
                                  || SQLERRM
                                 );
         END;
      ELSE
         dbg_low ('referred_by IS NULL');
         csr_applicant_print_rec.referred_by_id := NULL;
      END IF;

      -----------Calll API-----------------
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Before Proccessing API : '
                               || csr_applicant_print_rec.person_id
                              );
         xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                                 'csr_applicant_print_rec.application_date : '
                              || csr_applicant_print_rec.application_date
                             );
         
         hr_applicant_api.apply_for_job_anytime
                           (g_validate_flag_for_api,
                            csr_applicant_print_rec.application_date,
                            csr_applicant_print_rec.person_id,
                            l_applicant_number,
                            csr_applicant_print_rec.per_object_version_number,
                            csr_applicant_print_rec.vacancy_id,
                            csr_applicant_print_rec.person_type_id,
                            csr_applicant_print_rec.assignment_status_type_id,
                            l_application_id,
                            l_assignment_id,
                            l_apl_object_version_number,
                            l_asg_object_version_number,
                            l_assignment_sequence,
                            l_per_effective_start_date,
                            l_per_effective_end_date,
                            l_appl_override_warning
                           );
         COMMIT;
         
         dbg_low (   'After Proccessing API : '
                  || csr_applicant_print_rec.person_id
                 );
                 
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'l_applicant_number : ' || l_applicant_number
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'l_assignment_id : ' || l_assignment_id
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'l_per_effective_start_date : '
                               || l_per_effective_start_date
                              );        
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Error Proccessing API : ' || SQLERRM
                                 );
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                              xx_emf_cn_pkg.cn_stg_apicall,
                              SUBSTR (SQLERRM, 1, 1000),
                              csr_applicant_print_rec.record_number,
                              csr_applicant_print_rec.last_name,
                              csr_applicant_print_rec.business_group_name,
                              'Applicant Data'
                             );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            RETURN x_error_code;
      END;

      ----------------------------Call Applicant Assignment API------------------------------------
     IF g_validate_flag_for_api = FALSE --------- Added for Wave 1
     THEN
  
      BEGIN
         dbg_low
             (   'Before Proccessing hr_assignment_api.update_apl_asg API : '
              || csr_applicant_print_rec.person_id
             );
         hr_assignment_api.update_apl_asg
            (p_validate                        => g_validate_flag_for_api,
             p_effective_date                  => csr_applicant_print_rec.application_date
                                                              ---'01-JAN-2012'
                                                                                          ,
             p_datetrack_update_mode           => 'CORRECTION',
             p_assignment_id                   => l_assignment_id      ---1418
                                                                 ,
             p_object_version_number           => l_asg_object_version_number,
             p_recruiter_id                    => csr_applicant_print_rec.recruiter_id,
             p_person_referred_by_id           => csr_applicant_print_rec.referred_by_id
                                                                       ---1441
             
             -- Adding supervisor id for manager details for HR May 2013 release
             ,p_supervisor_id                   =>  csr_applicant_print_rec.manager_person_id,
             
             p_application_id                  => l_application_id    ---15068
                                                                  ,
             p_source_type                     => csr_applicant_print_rec.source_type
                                                                       ---'ER'
                                                                                     ,
             p_concatenated_segments           => l_concatenated_segments,
             p_cagr_grade_def_id               => l_cagr_grade_def_id,
             p_cagr_concatenated_segments      => l_cagr_concatenated_segments,
             p_group_name                      => l_group_name,
             p_comment_id                      => l_comment_id,
             p_people_group_id                 => l_people_group_id,
             p_soft_coding_keyflex_id          => l_soft_coding_keyflex_id,
             p_effective_start_date            => l_effective_start_date,
             p_effective_end_date              => l_effective_end_date
            );
         COMMIT;
         dbg_low
               (   'After Proccessing hr_assignment_api.update_apl_asg API : '
                || csr_applicant_print_rec.person_id
               );
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log
               (xx_emf_cn_pkg.cn_low,
                   'Error Proccessing hr_assignment_api.update_apl_asg API : '
                || SQLERRM
               );
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                              xx_emf_cn_pkg.cn_stg_apicall,
                              SUBSTR (SQLERRM, 1, 1000),
                              csr_applicant_print_rec.record_number,
                              csr_applicant_print_rec.last_name,
                              csr_applicant_print_rec.business_group_name,
                              'Applicant Data'
                             );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            RETURN x_error_code;
        
      END;
      
      END IF; --- Added for Wave 1
      ---------------------------------------------------------------------------------------------
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Error 1: ' || SQLERRM);
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Error 2: ' || SQLERRM);
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log
            (xx_emf_cn_pkg.cn_low,
                'Error Proccessing the API hr_applicant_api.apply_for_job_anytime: '
             || SQLERRM
            );
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                           xx_emf_cn_pkg.cn_stg_apicall,
                           SUBSTR (SQLERRM, 1, 1000),
                           csr_applicant_print_rec.record_number,
                           csr_applicant_print_rec.last_name,
                           csr_applicant_print_rec.business_group_name,
                           'Applicant Data'
                          );
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
   END xx_create_appl_by_api;

   --**********************************************************************
   ----Function to call API to create phone data.
   --**********************************************************************
   FUNCTION xx_create_phone_by_api (
      csr_phone_print_rec   IN OUT   xx_hr_appl_cnv_validation_pkg.g_xx_phone_stg_rec_type
   )
      RETURN NUMBER
   IS
      --Variable Declaration
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
      l_phn_id            NUMBER := 0;
      --l_per_object_version_number NUMBER :=0;
      --l_phone_id                  NUMBER :=0;
   BEGIN
      g_api_name := 'xx_create_phone_by_api';
      dbg_low ('Inside xx_create_phone_by_api By API');
      -- Added by Aabhas on 6th May 2013 to check for duplicate phone number . 
      BEGIN 
      select phone_id,OBJECT_VERSION_NUMBER
      into csr_phone_print_rec.phone_id,csr_phone_print_rec.per_object_version_number
      from per_phones
      where parent_table = 'PER_ALL_PEOPLE_F'
      and parent_id = csr_phone_print_rec.person_id
      and PHONE_NUMBER = csr_phone_print_rec.phone_number
      and PHONE_TYPE = csr_phone_print_rec.phone_type_code;
      
      EXCEPTION 
      WHEN TOO_MANY_ROWS THEN 
        select min(phone_id),OBJECT_VERSION_NUMBER
        into csr_phone_print_rec.phone_id,csr_phone_print_rec.per_object_version_number
        from per_phones
        where parent_table = 'PER_ALL_PEOPLE_F'
        and parent_id = csr_phone_print_rec.person_id
        and PHONE_NUMBER = csr_phone_print_rec.phone_number
        and PHONE_TYPE = csr_phone_print_rec.phone_type_code
        group by OBJECT_VERSION_NUMBER;  
      WHEN NO_DATA_FOUND THEN
        csr_phone_print_rec.phone_id := NULL;
        csr_phone_print_rec.per_object_version_number := NULL;
      WHEN OTHERS THEN 
        csr_phone_print_rec.phone_id := NULL;
        csr_phone_print_rec.per_object_version_number := NULL;
      END;
      
      -- Check if the number already exist then do not call the API  
      IF csr_phone_print_rec.phone_id IS NULL THEN 
      -----------Calll API-----------------
      BEGIN
         dbg_low (   'Before Proccessing API for Phone : '
                  || csr_phone_print_rec.person_id
                 );
         hr_phone_api.create_phone
            (p_date_from                  => csr_phone_print_rec.phone_effective_date,
             p_phone_type                 => csr_phone_print_rec.phone_type_code,
             p_phone_number               => csr_phone_print_rec.phone_number,
             p_effective_date             => csr_phone_print_rec.phone_effective_date,
             p_parent_id                  => csr_phone_print_rec.person_id,
             p_parent_table               => 'PER_ALL_PEOPLE_F',
             p_validate                   => g_validate_flag_for_api,
             p_object_version_number      => csr_phone_print_rec.per_object_version_number,
             p_phone_id                   => csr_phone_print_rec.phone_id
            );
         COMMIT;
         dbg_low (   'After Proccessing API for phone : '
                 -- || csr_phone_print_rec.person_id
                 -- Modified by Aabhas on 6th May 2013 
                 ||csr_phone_print_rec.phone_id
                 );     
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Error Proccessing API for phone : '
                                  || SQLERRM
                                 );
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                              xx_emf_cn_pkg.cn_stg_apicall,
                              SUBSTR (SQLERRM, 1, 100),
                              csr_phone_print_rec.record_number,
                              csr_phone_print_rec.last_name,
                              csr_phone_print_rec.business_group_name,
                              'Phone Data'
                             );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            RETURN x_error_code;
      END;
      END IF;
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Error 1: ' || SQLERRM);
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Error 2: ' || SQLERRM);
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log
                  (xx_emf_cn_pkg.cn_low,
                      'Error Proccessing the API hr_phone_api.create_phone: '
                   || SQLERRM
                  );
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                           xx_emf_cn_pkg.cn_stg_apicall,
                           SUBSTR (SQLERRM, 1, 100),
                           csr_phone_print_rec.record_number,
                           csr_phone_print_rec.last_name,
                           csr_phone_print_rec.business_group_name,
                           'Phone Data'
                          );
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
   END xx_create_phone_by_api;

   --**********************************************************************
   -----Function to call API to upload resume data.
   --**********************************************************************
   FUNCTION xx_create_resume_by_api (
      csr_resume_print_rec   IN OUT   xx_hr_appl_cnv_validation_pkg.g_xx_resume_stg_rec_type
   )
      RETURN NUMBER
   IS
      --Variable Declaration
      x_error_code              NUMBER          := xx_emf_cn_pkg.cn_success;
      x_error_code_temp         NUMBER          := xx_emf_cn_pkg.cn_success;
      l_document_id             NUMBER          := 0;
      l_mime_type               VARCHAR2 (1000) := 'application/msword';
      l_object_version_number   NUMBER;
      l_assignment_id           NUMBER;
      l_file_on_os              BFILE;
      l_temp_blob               BLOB;
   BEGIN
      g_api_name := 'xx_create_resume_by_api';
      dbg_low ('Inside xx_create_resume_by_api By API');

      -----------Calll API-----------------
      BEGIN
         dbg_low (   'Before Proccessing API for Resume : '
                  || csr_resume_print_rec.person_id
                 );
         irc_document_api.create_document
                                (g_validate_flag_for_api,
                                 csr_resume_print_rec.document_effective_date,
                                 UPPER (csr_resume_print_rec.document_type),
                                 csr_resume_print_rec.person_id,
                                 l_mime_type,
                                 l_assignment_id,
                                 csr_resume_print_rec.document_file_name,
                                 csr_resume_print_rec.document_description,
                                 NULL,
                                 csr_resume_print_rec.document_id,
                                 csr_resume_print_rec.object_version_number
                                );
         COMMIT;
         dbg_low (   'After Proccessing API for resume : '
                  || csr_resume_print_rec.document_id
                 );
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Error Proccessing API for resume : '
                                  || SQLERRM
                                 );
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                              xx_emf_cn_pkg.cn_stg_apicall,
                              SUBSTR (SQLERRM, 1, 1000),
                              csr_resume_print_rec.record_number,
                              csr_resume_print_rec.last_name,
                              csr_resume_print_rec.business_group_name,
                              'Resume Data'
                             );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            RETURN x_error_code;
      END;

      ------
      irc_document_api.process_document (csr_resume_print_rec.document_id);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'After irc_document_api.process_document : '
                            || csr_resume_print_rec.document_id
                           );
      /*BEGIN
      EXECUTE IMMEDIATE('CREATE OR REPLACE DIRECTORY RESUME_IN1 AS '''||csr_resume_print_rec.document_location||'''');
      EXCEPTION
       WHEN OTHERS THEN
             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while EXECUTE IMMEDIATE : ' ||SQLERRM);
             xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      END;*/
      
      IF l_file_on_os IS NOT NULL
      THEN
          DBMS_LOB.fileclose (l_file_on_os);   
      END IF;
      
      dbg_low (   'document_file_name : '
               || csr_resume_print_rec.document_file_name
              );
      l_file_on_os :=
         BFILENAME ('XXINTG_RESUME_IN',
                    csr_resume_print_rec.document_file_name
                   );
      DBMS_LOB.fileopen (l_file_on_os, DBMS_LOB.file_readonly);

      --------
      BEGIN
         SELECT     binary_doc
               INTO l_temp_blob
               FROM irc_documents
              WHERE document_id = csr_resume_print_rec.document_id
         FOR UPDATE;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                'Error while select binary_doc for resume : '
                             || SQLERRM
                            );
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand,
                              csr_resume_print_rec.record_number,
                              csr_resume_print_rec.last_name,
                              csr_resume_print_rec.business_group_name,
                              'Resume Data'
                             );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            DBMS_LOB.fileclose (l_file_on_os); 
            commit;
            RETURN x_error_code;
      END;
      ----------------
      DBMS_LOB.loadfromfile (l_temp_blob,
                             l_file_on_os,
                             DBMS_LOB.getlength (l_file_on_os)
                            );
      DBMS_LOB.fileclose (l_file_on_os);
      COMMIT;
      irc_document_api.process_document (csr_resume_print_rec.document_id);
      dbg_low (   'After irc_document_api.process_document : '
               || csr_resume_print_rec.person_id
              );
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Error 1: ' || SQLERRM);
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         -- Added by Aabhas on 6th May
         DBMS_LOB.fileclose (l_file_on_os);
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Error 2: ' || SQLERRM);
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         -- Added by Aabhas on 6th May
         DBMS_LOB.fileclose (l_file_on_os);
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log
            (xx_emf_cn_pkg.cn_low,
                'Error Proccessing the API irc_document_api.CREATE_DOCUMENT : '
             || SQLERRM
            );
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                           xx_emf_cn_pkg.cn_stg_apicall,
                           SUBSTR (SQLERRM, 1, 1000),
                           csr_resume_print_rec.record_number,
                           csr_resume_print_rec.last_name,
                           csr_resume_print_rec.business_group_name,
                           'Resume Data'
                          );
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         -- Added by Aabhas on 6th May
         DBMS_LOB.fileclose (l_file_on_os);
         RETURN x_error_code;
   END xx_create_resume_by_api;

   --**********************************************************************
   --------Main Procedure-----------------------------------------------
   --**********************************************************************
   PROCEDURE main (
      x_errbuf              OUT      VARCHAR2,
      x_retcode             OUT      VARCHAR2,
      p_batch_id            IN       VARCHAR2,
      p_restart_flag        IN       VARCHAR2,
      p_validate_and_load   IN       VARCHAR2
   )
   IS
      --------------------------------------------------------------------------------------------------------
      -- Private Variable Declaration Section
      --------------------------------------------------------------------------------------------------------
      --Stop the program with EMF error header insertion fails
      l_process_status    NUMBER;
      x_error_code        NUMBER                  := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER                  := xx_emf_cn_pkg.cn_success;
      x_applicant_table   g_xx_applicant_tab_type;
      x_phone_table       g_xx_phone_tab_type;
      x_resume_table      g_xx_resume_tab_type;

      CURSOR c_xx_applicant (cp_process_status VARCHAR2)
      IS
         SELECT   *
             FROM xx_hr_appl_upload_stg
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
         ORDER BY record_number;

      CURSOR c_xx_phone (cp_process_status VARCHAR2)
      IS
         SELECT   *
             FROM xx_hr_phone_upload_stg
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
         ORDER BY record_number;

      CURSOR c_xx_resume (cp_process_status VARCHAR2)
      IS
         SELECT   *
             FROM xx_hr_resume_upload_stg
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
         ORDER BY record_number;

      --**********************************************************************
      -----Procedure to update error record status----------------------------
      --**********************************************************************
      PROCEDURE update_record_status (
         p_conv_hdr_rec   IN OUT   g_xx_applicant_stg_rec_type,
         p_error_code     IN       VARCHAR2
      )
      IS
      BEGIN
         g_api_name := 'main.update_record_status';
         dbg_low ('Inside of update record status...');

         IF p_error_code IN
                        (xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err)
         THEN
            p_conv_hdr_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            p_conv_hdr_rec.ERROR_CODE :=
               xx_intg_common_pkg.find_max (p_error_code,
                                            NVL (p_conv_hdr_rec.ERROR_CODE,
                                                 xx_emf_cn_pkg.cn_success
                                                )
                                           );
         END IF;

         p_conv_hdr_rec.process_code := g_stage;
      END update_record_status;

      --**********************************************************************
      ---Procedure to update error record status for phone--------------------
      --**********************************************************************
      PROCEDURE update_record_status_ph (
         p_conv_hdr_rec   IN OUT   g_xx_phone_stg_rec_type,
         p_error_code     IN       VARCHAR2
      )
      IS
      BEGIN
         g_api_name := 'main.update_record_status_ph';
         dbg_low ('Inside of update record status...');

         IF p_error_code IN
                        (xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err)
         THEN
            p_conv_hdr_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            p_conv_hdr_rec.ERROR_CODE :=
               xx_intg_common_pkg.find_max (p_error_code,
                                            NVL (p_conv_hdr_rec.ERROR_CODE,
                                                 xx_emf_cn_pkg.cn_success
                                                )
                                           );
         END IF;

         p_conv_hdr_rec.process_code := g_stage;
      END update_record_status_ph;

--**********************************************************************
-----Procedure to update record status for resume-----------------------

      --**********************************************************************
      PROCEDURE update_record_status_rm (
         p_conv_hdr_rec   IN OUT   g_xx_resume_stg_rec_type,
         p_error_code     IN       VARCHAR2
      )
      IS
      BEGIN
         g_api_name := 'main.update_record_status_rm';
         dbg_low ('Inside of update record status for resume...');

         IF p_error_code IN
                        (xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err)
         THEN
            p_conv_hdr_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            p_conv_hdr_rec.ERROR_CODE :=
               xx_intg_common_pkg.find_max (p_error_code,
                                            NVL (p_conv_hdr_rec.ERROR_CODE,
                                                 xx_emf_cn_pkg.cn_success
                                                )
                                           );
         END IF;

         p_conv_hdr_rec.process_code := g_stage;
      END update_record_status_rm;

--**********************************************************************

      -----Procedure to update staging records---------------------------------

      --**********************************************************************
      PROCEDURE update_int_records (
         p_cnv_applicant_table   IN   g_xx_applicant_tab_type
      )
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         indx                  NUMBER;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         g_api_name := 'main.update_int_records';

         FOR indx IN 1 .. p_cnv_applicant_table.COUNT
         LOOP
            dbg_low (   'p_cnv_applicant_table(indx).process_code '
                     || p_cnv_applicant_table (indx).process_code
                    );
            dbg_low (   'p_cnv_applicant_table(indx).error_code '
                     || p_cnv_applicant_table (indx).ERROR_CODE
                    );

------------------------update applicant staging table with person_type_id as Applicant so that API will converts the Employee to employee.applicant, Ex Employee to exemployee.applicant and candidate to applicant----------------------------
            UPDATE xx_hr_appl_upload_stg
               SET batch_id = p_cnv_applicant_table (indx).batch_id,
                   unique_id = p_cnv_applicant_table (indx).unique_id,
                   business_group_name =
                              p_cnv_applicant_table (indx).business_group_name,
                   business_group_id =
                                p_cnv_applicant_table (indx).business_group_id,
                   first_name = p_cnv_applicant_table (indx).first_name,
                   middle_name = p_cnv_applicant_table (indx).middle_name,
                   last_name = p_cnv_applicant_table (indx).last_name,
                   full_name = p_cnv_applicant_table (indx).full_name,
                   person_id = p_cnv_applicant_table (indx).person_id,
                   user_person_type =
                                 p_cnv_applicant_table (indx).user_person_type,
                   person_type_id =
                                   p_cnv_applicant_table (indx).person_type_id,
                   applicant_source =
                                 p_cnv_applicant_table (indx).applicant_source,
                   source_type = p_cnv_applicant_table (indx).source_type,
                   applicant_status =
                                 p_cnv_applicant_table (indx).applicant_status,
                   assignment_status_type_id =
                        p_cnv_applicant_table (indx).assignment_status_type_id,
                   recruiter = p_cnv_applicant_table (indx).recruiter,
                   recruiter_id = p_cnv_applicant_table (indx).recruiter_id,
                   referred_by = p_cnv_applicant_table (indx).referred_by,
                   referred_by_id =
                                   p_cnv_applicant_table (indx).referred_by_id,
                   vacancy_number =
                                   p_cnv_applicant_table (indx).vacancy_number,
                   vacancy_id = p_cnv_applicant_table (indx).vacancy_id,
                   application_date =
                                 p_cnv_applicant_table (indx).application_date,
                   per_object_version_number =
                        p_cnv_applicant_table (indx).per_object_version_number,

                   process_code = p_cnv_applicant_table (indx).process_code,
                   ERROR_CODE = p_cnv_applicant_table (indx).ERROR_CODE,
                   ERROR_TYPE = p_cnv_applicant_table (indx).ERROR_TYPE,
                   error_explanation =
                                p_cnv_applicant_table (indx).error_explanation,
                   error_flag = p_cnv_applicant_table (indx).error_flag,
                   error_mesg = p_cnv_applicant_table (indx).error_mesg,
                   creation_date = p_cnv_applicant_table (indx).creation_date,
                   created_by = p_cnv_applicant_table (indx).created_by,
                   last_update_date =
                                 p_cnv_applicant_table (indx).last_update_date,
                   last_updated_by =
                                  p_cnv_applicant_table (indx).last_updated_by,
                   last_update_login =
                                p_cnv_applicant_table (indx).last_update_login,
                   request_id = p_cnv_applicant_table (indx).request_id,
                   program_application_id =
                           p_cnv_applicant_table (indx).program_application_id,
                   program_id = p_cnv_applicant_table (indx).program_id,
                   program_update_date =
                              p_cnv_applicant_table (indx).program_update_date,
                   process_flag = p_cnv_applicant_table (indx).process_flag
                   --- Added manager columns for HR May 2013 Release
                   ,MANAGER_UNIQUE_ID = p_cnv_applicant_table (indx).MANAGER_UNIQUE_ID,
                   MANAGER_PERSON_ID = p_cnv_applicant_table (indx).MANAGER_PERSON_ID
             WHERE record_number = p_cnv_applicant_table (indx).record_number;
         END LOOP;

         --===
         COMMIT;
      END update_int_records;

---**********************************************************************

      -----Procedure to update staging records for phone-----------------------

      --**********************************************************************
      PROCEDURE update_int_records_ph (p_cnv_phone_table IN g_xx_phone_tab_type)
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         indx                  NUMBER;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         g_api_name := 'main.update_int_records_ph';

         FOR indx IN 1 .. p_cnv_phone_table.COUNT
         LOOP
            dbg_low (   'p_cnv_phone_table(indx).process_code '
                     || p_cnv_phone_table (indx).process_code
                    );
            dbg_low (   'p_cnv_phone_table(indx).error_code '
                     || p_cnv_phone_table (indx).ERROR_CODE
                    );

            UPDATE xx_hr_phone_upload_stg
               SET batch_id = p_cnv_phone_table (indx).batch_id,
                   unique_id = p_cnv_phone_table (indx).unique_id,
                   business_group_name =
                                  p_cnv_phone_table (indx).business_group_name,
                   business_group_id =
                                    p_cnv_phone_table (indx).business_group_id,
                   first_name = p_cnv_phone_table (indx).first_name,
                   middle_name = p_cnv_phone_table (indx).middle_name,
                   last_name = p_cnv_phone_table (indx).last_name,
                   full_name = p_cnv_phone_table (indx).full_name,
                   person_id = p_cnv_phone_table (indx).person_id,
                   phone_effective_date =
                                 p_cnv_phone_table (indx).phone_effective_date,
                   phone_type = p_cnv_phone_table (indx).phone_type,
                   phone_type_code = p_cnv_phone_table (indx).phone_type_code,
                   phone_number = p_cnv_phone_table (indx).phone_number,
                   per_object_version_number =
                            p_cnv_phone_table (indx).per_object_version_number,
                   phone_id = p_cnv_phone_table (indx).phone_id,
                   process_code = p_cnv_phone_table (indx).process_code,
                   ERROR_CODE = p_cnv_phone_table (indx).ERROR_CODE,
                   ERROR_TYPE = p_cnv_phone_table (indx).ERROR_TYPE,
                   error_explanation =
                                    p_cnv_phone_table (indx).error_explanation,
                   error_flag = p_cnv_phone_table (indx).error_flag,
                   error_mesg = p_cnv_phone_table (indx).error_mesg,
                   creation_date = p_cnv_phone_table (indx).creation_date,
                   created_by = p_cnv_phone_table (indx).created_by,
                   last_update_date =
                                     p_cnv_phone_table (indx).last_update_date,
                   last_updated_by = p_cnv_phone_table (indx).last_updated_by,
                   last_update_login =
                                    p_cnv_phone_table (indx).last_update_login,
                   request_id = p_cnv_phone_table (indx).request_id,
                   program_application_id =
                               p_cnv_phone_table (indx).program_application_id,
                   program_id = p_cnv_phone_table (indx).program_id,
                   program_update_date =
                                  p_cnv_phone_table (indx).program_update_date,
                   process_flag = p_cnv_phone_table (indx).process_flag
             -----record_number                 = p_cnv_phone_table(indx).record_number
            WHERE  record_number = p_cnv_phone_table (indx).record_number;
         END LOOP;

         --===
         COMMIT;
      END update_int_records_ph;

--**********************************************************************

      -----Procedure to update staging records for resume---------------------

      --**********************************************************************
      PROCEDURE update_int_records_rm (
         p_cnv_resume_table   IN   g_xx_resume_tab_type
      )
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         indx                  NUMBER;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         g_api_name := 'main.update_int_records_rm';

         FOR indx IN 1 .. p_cnv_resume_table.COUNT
         LOOP
            dbg_low (   'p_cnv_resume_table(indx).process_code '
                     || p_cnv_resume_table (indx).process_code
                    );
            dbg_low (   'p_cnv_resume_table(indx).error_code '
                     || p_cnv_resume_table (indx).ERROR_CODE
                    );

            UPDATE xx_hr_resume_upload_stg
               SET batch_id = p_cnv_resume_table (indx).batch_id,
                   unique_id = p_cnv_resume_table (indx).unique_id,
                   business_group_name =
                                 p_cnv_resume_table (indx).business_group_name,
                   business_group_id =
                                   p_cnv_resume_table (indx).business_group_id,
                   first_name = p_cnv_resume_table (indx).first_name,
                   middle_name = p_cnv_resume_table (indx).middle_name,
                   last_name = p_cnv_resume_table (indx).last_name,
                   person_id = p_cnv_resume_table (indx).person_id,
                   document_effective_date =
                             p_cnv_resume_table (indx).document_effective_date,
                   document_type = p_cnv_resume_table (indx).document_type,
                   document_id = p_cnv_resume_table (indx).document_id,
                   document_file_name =
                                  p_cnv_resume_table (indx).document_file_name,
                   document_description =
                                p_cnv_resume_table (indx).document_description,
                   document_location =
                                   p_cnv_resume_table (indx).document_location,
                   process_code = p_cnv_resume_table (indx).process_code,
                   ERROR_CODE = p_cnv_resume_table (indx).ERROR_CODE,
                   ERROR_TYPE = p_cnv_resume_table (indx).ERROR_TYPE,
                   error_explanation =
                                   p_cnv_resume_table (indx).error_explanation,
                   error_flag = p_cnv_resume_table (indx).error_flag,
                   error_mesg = p_cnv_resume_table (indx).error_mesg,
                   creation_date = p_cnv_resume_table (indx).creation_date,
                   created_by = p_cnv_resume_table (indx).created_by,
                   last_update_date =
                                    p_cnv_resume_table (indx).last_update_date,
                   last_updated_by = p_cnv_resume_table (indx).last_updated_by,
                   last_update_login =
                                   p_cnv_resume_table (indx).last_update_login,
                   request_id = p_cnv_resume_table (indx).request_id,
                   program_application_id =
                              p_cnv_resume_table (indx).program_application_id,
                   program_id = p_cnv_resume_table (indx).program_id,
                   program_update_date =
                                 p_cnv_resume_table (indx).program_update_date,
                   process_flag = p_cnv_resume_table (indx).process_flag
             -----record_number                 = p_cnv_resume_table(indx).record_number
            WHERE  record_number = p_cnv_resume_table (indx).record_number;
         END LOOP;

         --===
         COMMIT;
      END update_int_records_rm;

--**********************************************************************

      ------Procedure to mark records for complete---------------------------

      --**********************************************************************
      PROCEDURE mark_records_complete (p_process_code VARCHAR2)
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         dbg_low ('Inside of mark records complete...');
         g_api_name := 'main.mark_records_complete';
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside mark_records_complete'
                              );

         UPDATE xx_hr_appl_upload_stg                                 --Header
            SET process_code = g_stage,
                ERROR_CODE = NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success),
                last_updated_by = x_last_updated_by,
                last_update_date = x_last_update_date,
                last_update_login = x_last_update_login
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND process_code =
                   DECODE (p_process_code,
                           xx_emf_cn_pkg.cn_process_data, xx_emf_cn_pkg.cn_postval,
                           xx_emf_cn_pkg.cn_derive
                          )
            AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn);

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            dbg_low ('Error in Update of mark_records_complete ' || SQLERRM);
      END mark_records_complete;

--**********************************************************************

      ---Procedure to mark records complete for phone-------------------------

      --**********************************************************************
      PROCEDURE mark_records_complete_ph (p_process_code VARCHAR2)
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         dbg_low ('Inside of mark records complete for phone...');
         g_api_name := 'main.mark_records_complete';

         ---xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside mark_records_complete');
         UPDATE xx_hr_phone_upload_stg                               --Header
            SET process_code = g_stage,
                ERROR_CODE = NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success),
                last_updated_by = x_last_updated_by,
                last_update_date = x_last_update_date,
                last_update_login = x_last_update_login
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND process_code =
                   DECODE (p_process_code,
                           xx_emf_cn_pkg.cn_process_data, xx_emf_cn_pkg.cn_postval,
                           xx_emf_cn_pkg.cn_derive
                          )
            AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn);

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            dbg_low (   'Error in Update of mark_records_complete for phone '
                     || SQLERRM
                    );
      END mark_records_complete_ph;

--**********************************************************************

      ---Procedure to mark records complete for resume------------------------

      --**********************************************************************
      PROCEDURE mark_records_complete_rm (p_process_code VARCHAR2)
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         dbg_low ('Inside of mark records complete for resume...');
         g_api_name := 'main.mark_records_complete_rm';

         ---xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside mark_records_complete');
         UPDATE xx_hr_resume_upload_stg                              --Header
            SET process_code = g_stage,
                ERROR_CODE = NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success),
                last_updated_by = x_last_updated_by,
                last_update_date = x_last_update_date,
                last_update_login = x_last_update_login
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND process_code =
                   DECODE (p_process_code,
                           xx_emf_cn_pkg.cn_process_data, xx_emf_cn_pkg.cn_postval,
                           xx_emf_cn_pkg.cn_derive
                          )
            AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn);

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            dbg_low
                   (   'Error in Update of mark_records_complete for resume '
                    || SQLERRM
                   );
      END mark_records_complete_rm;
   BEGIN
      --Main Begin
      ----------------------------------------------------------------------------------------------------
      --Initialize Trace
      --Purpose : Set the program environment for Tracing
      ----------------------------------------------------------------------------------------------------
      x_retcode := xx_emf_cn_pkg.cn_success;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Before Setting Environment'
                           );
      -- Set Env --
      dbg_low ('Calling set_cnv_env');
      
      
      -- Addded for Wave 1 
            IF p_validate_and_load = 'VALIDATE_AND_LOAD'
            THEN
                g_validate_flag_for_api := FALSE; -- API will validate and update base tables if successful
            ELSE
                g_validate_flag_for_api := TRUE; -- API will only validate and not modify database
              END IF;
      
      
      set_cnv_env (p_batch_id, xx_emf_cn_pkg.cn_yes);

      -- include all the parameters to the conversion main here
      -- as medium log messages
      dbg_med ('Starting main process with the following parameters');
      dbg_med('Param - p_batch_id          '|| p_batch_id);
      dbg_med('Param - p_restart_flag      '|| p_restart_flag);
      dbg_med('Param - p_validate_and_load '|| p_validate_and_load);

      -- Call procedure to update records with the current request_id
      -- So that we can process only those records
      -- This gives a better handling of restartability
      dbg_low ('Calling mark_records_for_processing..');
      mark_records_for_processing (p_restart_flag => p_restart_flag);

      -- Set the stage to Pre Validations
      set_stage (xx_emf_cn_pkg.cn_preval);
      -- PRE_VALIDATIONS SHOULD BE RETAINED
      dbg_low('Calling xx_hr_appl_cnv_validation_pkg.pre_validations_appl ..');
      x_error_code := xx_hr_appl_cnv_validation_pkg.pre_validations_appl;
      dbg_med (   'After pre-validations for Applicant X_ERROR_CODE '
               || x_error_code
              );
      -- Update process code of staging records
      -- Update Header and Lines Level
      update_staging_records (x_error_code);
      dbg_low ('after update_staging_records ..');
      xx_emf_pkg.propagate_error (x_error_code);
      -- Set the stage to data Validations
      set_stage (xx_emf_cn_pkg.cn_valid);

      OPEN c_xx_applicant (xx_emf_cn_pkg.cn_preval);
      LOOP
         FETCH c_xx_applicant
         BULK COLLECT INTO x_applicant_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         FOR i IN 1 .. x_applicant_table.COUNT
         LOOP
            BEGIN
               -- Perform Base App Validations
               x_error_code :=
                              xx_applicant_validation (x_applicant_table (i));
               dbg_low (   'x_error_code for  '
                        || x_applicant_table (i).record_number
                        || ' is '
                        || x_error_code
                       );
               update_record_status (x_applicant_table (i), x_error_code);
               xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
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
                  update_int_records (x_applicant_table);
                  raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
               WHEN OTHERS
               THEN
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    xx_emf_cn_pkg.cn_exp_unhand,
                                    x_applicant_table (i).record_number
                                   );
            END;
         END LOOP;

         dbg_low ('x_applicant_table.count ' || x_applicant_table.COUNT);
         update_int_records (x_applicant_table);
         x_applicant_table.DELETE;
         EXIT WHEN c_xx_applicant%NOTFOUND;
      END LOOP;

      IF c_xx_applicant%ISOPEN
      THEN
         CLOSE c_xx_applicant;
      END IF;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               fnd_global.conc_request_id
                            || ' : Before Data Derivations for Applicant'
                           );

      -- Once data-validations are complete the loop through the pre-interface records
      -- and perform data derivations on this table
      -- Set the stage to data derivations

      -- Perform data derivations and process data only if p_validate_only_flag is set to VALIDATE_AND_LOAD
     -- IF p_validate_and_load = g_validate_and_load -- wave 1
     -- THEN
         set_stage (xx_emf_cn_pkg.cn_derive);

         OPEN c_xx_applicant (xx_emf_cn_pkg.cn_valid);

         LOOP
            FETCH c_xx_applicant
            BULK COLLECT INTO x_applicant_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

            FOR i IN 1 .. x_applicant_table.COUNT
            LOOP
               BEGIN
                  -- Perform Base App Validations
                  x_error_code :=
                        xx_applicant_data_derivations (x_applicant_table (i));
                  dbg_low (   'x_error_code for  '
                           || x_applicant_table (i).record_number
                           || ' is '
                           || x_error_code
                          );
                  update_record_status (x_applicant_table (i), x_error_code);
                  xx_emf_pkg.propagate_error (x_error_code);
               EXCEPTION
                  -- If HIGH error then it will be propagated to the next level
                  -- IF the process has to continue maintain it as a medium severity
                  WHEN xx_emf_pkg.g_e_rec_error
                  THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                           xx_emf_cn_pkg.cn_rec_err
                                          );
                  WHEN xx_emf_pkg.g_e_prc_error
                  THEN
                     xx_emf_pkg.write_log
                                   (xx_emf_cn_pkg.cn_high,
                                    'Process Level Error in Data derivations'
                                   );
                     update_int_records (x_applicant_table);
                     raise_application_error (-20199,
                                              xx_emf_cn_pkg.cn_prc_err);
                  WHEN OTHERS
                  THEN
                     xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                       xx_emf_cn_pkg.cn_tech_error,
                                       xx_emf_cn_pkg.cn_exp_unhand,
                                       x_applicant_table (i).record_number
                                      );
               END;
            END LOOP;

            dbg_low ('x_applicant_table.count ' || x_applicant_table.COUNT);
            update_int_records (x_applicant_table);
            x_applicant_table.DELETE;
            EXIT WHEN c_xx_applicant%NOTFOUND;
                                 --***DS: Table type variable used like cursor
         END LOOP;

         IF c_xx_applicant%ISOPEN
         THEN
            CLOSE c_xx_applicant;
         END IF;

         -- Set the stage to Post Validations
         set_stage (xx_emf_cn_pkg.cn_postval);
         -- Change the validations package to the appropriate package name
         -- Modify the parameters as required
         -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
         -- PRE_VALIDATIONS SHOULD BE RETAINED
         x_error_code := post_validations_applicant ();
         dbg_med ('After post-validations X_ERROR_CODE ' || x_error_code);
         mark_records_complete (xx_emf_cn_pkg.cn_postval);
         dbg_med
              (   'After mark_records_complete post-validations X_ERROR_CODE '
               || x_error_code
              );
         xx_emf_pkg.propagate_error (x_error_code);
         -- Set the stage to Process
         set_stage (xx_emf_cn_pkg.cn_process_data);
         dbg_med ('Before process_data');

         OPEN c_xx_applicant (xx_emf_cn_pkg.cn_postval);

         LOOP
            FETCH c_xx_applicant
            BULK COLLECT INTO x_applicant_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

            FOR i IN 1 .. x_applicant_table.COUNT
            LOOP
               BEGIN
                  -- Perform Base App Validations
                  x_error_code :=
                                xx_create_appl_by_api (x_applicant_table (i));
                                                 -------calling applicant API
                  dbg_low (   'x_error_code for  '
                           || x_applicant_table (i).record_number
                           || ' is '
                           || x_error_code
                          );
                  update_record_status (x_applicant_table (i), x_error_code);
                  xx_emf_pkg.propagate_error (x_error_code);
               EXCEPTION
                  -- If HIGH error then it will be propagated to the next level
                   -- IF the process has to continue maintain it as a medium severity
                  WHEN xx_emf_pkg.g_e_rec_error
                  THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                           xx_emf_cn_pkg.cn_rec_err
                                          );
                  WHEN xx_emf_pkg.g_e_prc_error
                  THEN
                     xx_emf_pkg.write_log
                                       (xx_emf_cn_pkg.cn_high,
                                        'Process Level Error in Data Process'
                                       );
                     update_int_records (x_applicant_table);
                     raise_application_error (-20199,
                                              xx_emf_cn_pkg.cn_prc_err);
                  WHEN OTHERS
                  THEN
                     xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                       xx_emf_cn_pkg.cn_tech_error,
                                       xx_emf_cn_pkg.cn_exp_unhand,
                                       x_applicant_table (i).record_number
                                      );
               END;
            END LOOP;

            dbg_low ('x_applican_table.count ' || x_applicant_table.COUNT);
            update_int_records (x_applicant_table);
            x_applicant_table.DELETE;
            EXIT WHEN c_xx_applicant%NOTFOUND;
         END LOOP;

         IF c_xx_applicant%ISOPEN
         THEN
            CLOSE c_xx_applicant;
         END IF;

         dbg_med ('After process_data');
         mark_records_complete (xx_emf_cn_pkg.cn_process_data);
         dbg_med (   'After Process Data mark_records_complete x_error_code'
                  || x_error_code
                 );
      --xx_emf_pkg.propagate_error ( x_error_code);
 --     END IF; -- wave 1

      ---------------------------Phone Data upload code start-------------------------

      -- Set the stage to Pre Validations
      set_stage (xx_emf_cn_pkg.cn_preval);
      -- PRE_VALIDATIONS SHOULD BE RETAINED
      dbg_low ('Calling xx_hr_appl_cnv_validation_pkg.pre_validations_ph ..');
      x_error_code := xx_hr_appl_cnv_validation_pkg.pre_validations_ph;
      dbg_med (   'After pre-validations for Phone data X_ERROR_CODE '
               || x_error_code
              );
        -- Update process code of staging records
      -- Update Header and Lines Level
      update_staging_records_ph (x_error_code);
      xx_emf_pkg.propagate_error (x_error_code);
      -- Set the stage to data Validations
      set_stage (xx_emf_cn_pkg.cn_valid);

      OPEN c_xx_phone (xx_emf_cn_pkg.cn_preval);

      LOOP
         FETCH c_xx_phone
         BULK COLLECT INTO x_phone_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         FOR i IN 1 .. x_phone_table.COUNT
         LOOP
            BEGIN
               -- Perform Base App Validations
               dbg_low ('last name' || x_phone_table (i).last_name);
               x_error_code := xx_phone_validation (x_phone_table (i));
               dbg_low (   'x_error_code for  '
                        || x_phone_table (i).record_number
                        || ' is '
                        || x_error_code
                       );
               update_record_status_ph (x_phone_table (i), x_error_code);
               xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
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
                  update_int_records_ph (x_phone_table);
                  raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
               WHEN OTHERS
               THEN
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    xx_emf_cn_pkg.cn_exp_unhand,
                                    x_phone_table (i).record_number
                                   );
            END;
         END LOOP;

         dbg_low ('x_phone_table.count ' || x_phone_table.COUNT);
         update_int_records_ph (x_phone_table);
         x_phone_table.DELETE;
         EXIT WHEN c_xx_phone%NOTFOUND;
      END LOOP;

      IF c_xx_phone%ISOPEN
      THEN
         CLOSE c_xx_phone;
      END IF;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               fnd_global.conc_request_id
                            || ' : Before Data Derivations for Phone Data'
                           );

      -- Once data-validations are complete the loop through the pre-interface records
      -- and perform data derivations on this table
      -- Set the stage to data derivations

      -- Perform data derivations and process data only if p_validate_only_flag is set to VALIDATE_AND_LOAD
      IF p_validate_and_load = g_validate_and_load 
      THEN
         set_stage (xx_emf_cn_pkg.cn_derive);

         OPEN c_xx_phone (xx_emf_cn_pkg.cn_valid);

         LOOP
            FETCH c_xx_phone
            BULK COLLECT INTO x_phone_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

            FOR i IN 1 .. x_phone_table.COUNT
            LOOP
               BEGIN
                  -- Perform Base App Validations
                  x_error_code :=
                                xx_phone_data_derivations (x_phone_table (i));
                  dbg_low (   'x_error_code for  '
                           || x_phone_table (i).record_number
                           || ' is '
                           || x_error_code
                          );
                  update_record_status_ph (x_phone_table (i), x_error_code);
                  xx_emf_pkg.propagate_error (x_error_code);
               EXCEPTION
                  -- If HIGH error then it will be propagated to the next level
                  -- IF the process has to continue maintain it as a medium severity
                  WHEN xx_emf_pkg.g_e_rec_error
                  THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                           xx_emf_cn_pkg.cn_rec_err
                                          );
                  WHEN xx_emf_pkg.g_e_prc_error
                  THEN
                     xx_emf_pkg.write_log
                                   (xx_emf_cn_pkg.cn_high,
                                    'Process Level Error in Data derivations'
                                   );
                     update_int_records_ph (x_phone_table);
                     raise_application_error (-20199,
                                              xx_emf_cn_pkg.cn_prc_err);
                  WHEN OTHERS
                  THEN
                     xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                       xx_emf_cn_pkg.cn_tech_error,
                                       xx_emf_cn_pkg.cn_exp_unhand,
                                       x_phone_table (i).record_number
                                      );
               END;
            END LOOP;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'x_phone_table.count '
                                  || x_phone_table.COUNT
                                 );
            update_int_records_ph (x_phone_table);
            x_phone_table.DELETE;
            EXIT WHEN c_xx_phone%NOTFOUND;
                                 --***DS: Table type variable used like cursor
         END LOOP;

         IF c_xx_phone%ISOPEN
         THEN
            CLOSE c_xx_phone;
         END IF;

         -- Set the stage to Post Validations
         set_stage (xx_emf_cn_pkg.cn_postval);
         -- Change the validations package to the appropriate package name
         -- Modify the parameters as required
         -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
         -- PRE_VALIDATIONS SHOULD BE RETAINED
         x_error_code := post_validations_phone ();
         dbg_med (   'After post-validations for phone X_ERROR_CODE '
                  || x_error_code
                 );
         mark_records_complete_ph (xx_emf_cn_pkg.cn_postval);
         dbg_med
            (   'After mark_records_complete post-validations for phone X_ERROR_CODE '
             || x_error_code
            );
         ---xx_emf_pkg.propagate_error ( x_error_code);

         -- Set the stage to Process
         set_stage (xx_emf_cn_pkg.cn_process_data);
         dbg_med ('Before process_data for phone');

         OPEN c_xx_phone (xx_emf_cn_pkg.cn_postval);

         LOOP
            FETCH c_xx_phone
            BULK COLLECT INTO x_phone_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

            FOR i IN 1 .. x_phone_table.COUNT
            LOOP
               BEGIN
                  -- Perform Base App Validations
                  x_error_code := xx_create_phone_by_api (x_phone_table (i));
                                                     -------calling phone API
                  dbg_low (   'x_error_code for  '
                           || x_phone_table (i).record_number
                           || ' is '
                           || x_error_code
                          );
                  update_record_status_ph (x_phone_table (i), x_error_code);
                  xx_emf_pkg.propagate_error (x_error_code);
               EXCEPTION
                  -- If HIGH error then it will be propagated to the next level
                   -- IF the process has to continue maintain it as a medium severity
                  WHEN xx_emf_pkg.g_e_rec_error
                  THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                           xx_emf_cn_pkg.cn_rec_err
                                          );
                  WHEN xx_emf_pkg.g_e_prc_error
                  THEN
                     xx_emf_pkg.write_log
                                       (xx_emf_cn_pkg.cn_high,
                                        'Process Level Error in Data Process'
                                       );
                     update_int_records_ph (x_phone_table);
                  --RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                  WHEN OTHERS
                  THEN
                     xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                       xx_emf_cn_pkg.cn_tech_error,
                                       xx_emf_cn_pkg.cn_exp_unhand,
                                       x_phone_table (i).record_number
                                      );
               END;
            END LOOP;

            dbg_low ('x_phone_table.count ' || x_phone_table.COUNT);
            update_int_records_ph (x_phone_table);
            x_phone_table.DELETE;
            EXIT WHEN c_xx_phone%NOTFOUND;
         END LOOP;

         IF c_xx_phone%ISOPEN
         THEN
            CLOSE c_xx_phone;
         END IF;

         dbg_med ('After process_data');
         mark_records_complete_ph (xx_emf_cn_pkg.cn_process_data);
         dbg_med
            (   'After Process Data mark_records_complete for phone x_error_code'
             || x_error_code
            );
      --xx_emf_pkg.propagate_error ( x_error_code);
      END IF;

 

      -----------------------------Resume Upload code start---------

      -- Set the stage to Pre Validations
      set_stage (xx_emf_cn_pkg.cn_preval);
      -- PRE_VALIDATIONS SHOULD BE RETAINED
      dbg_low ('Calling xx_hr_appl_cnv_validation_pkg.pre_validations_rm ..');
      x_error_code := xx_hr_appl_cnv_validation_pkg.pre_validations_rm;
      dbg_med('After pre-validations of Resume Data X_ERROR_CODE : ' || X_ERROR_CODE);
      -- Update process code of staging records
      -- Update Header and Lines Level
      update_staging_records_rm (x_error_code);
      xx_emf_pkg.propagate_error (x_error_code);
      -- Set the stage to data Validations
      set_stage (xx_emf_cn_pkg.cn_valid);

      OPEN c_xx_resume (xx_emf_cn_pkg.cn_preval);

      LOOP
         FETCH c_xx_resume
         BULK COLLECT INTO x_resume_table LIMIT g_resume_bulk_limit;--xx_emf_cn_pkg.cn_bulk_collect;

         FOR i IN 1 .. x_resume_table.COUNT
         LOOP
            BEGIN
               -- Perform Base App Validations
               x_error_code := xx_resume_validation (x_resume_table (i));
               dbg_low (   'x_error_code for  '
                        || x_resume_table (i).record_number
                        || ' is '
                        || x_error_code
                       );
               update_record_status_rm (x_resume_table (i), x_error_code);
               xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
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
                  update_int_records_rm (x_resume_table);
                  raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
               WHEN OTHERS
               THEN
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    xx_emf_cn_pkg.cn_exp_unhand,
                                    x_resume_table (i).record_number
                                   );
            END;
         END LOOP;

         dbg_low ('x_resume_table.count ' || x_resume_table.COUNT);
         update_int_records_rm (x_resume_table);
         x_resume_table.DELETE;
         EXIT WHEN c_xx_resume%NOTFOUND;
      END LOOP;

      IF c_xx_resume%ISOPEN
      THEN
         CLOSE c_xx_resume;
      END IF;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               fnd_global.conc_request_id
                            || ' : Before Data Derivations for Resume Data'
                           );

      -- Once data-validations are complete the loop through the pre-interface records
      -- and perform data derivations on this table
      -- Set the stage to data derivations

      -- Perform data derivations and process data only if p_validate_only_flag is set to VALIDATE_AND_LOAD
      IF p_validate_and_load = g_validate_and_load 
      THEN
         set_stage (xx_emf_cn_pkg.cn_derive);

         OPEN c_xx_resume (xx_emf_cn_pkg.cn_valid);

         LOOP
            FETCH c_xx_resume
            BULK COLLECT INTO x_resume_table LIMIT g_resume_bulk_limit;--xx_emf_cn_pkg.cn_bulk_collect;

            FOR i IN 1 .. x_resume_table.COUNT
            LOOP
               BEGIN
                  -- Perform Base App Validations
                  x_error_code :=
                              xx_resume_data_derivations (x_resume_table (i));
                  dbg_low (   'x_error_code for  '
                           || x_resume_table (i).record_number
                           || ' is '
                           || x_error_code
                          );
                  update_record_status_rm (x_resume_table (i), x_error_code);
                  xx_emf_pkg.propagate_error (x_error_code);
               EXCEPTION
                  -- If HIGH error then it will be propagated to the next level
                  -- IF the process has to continue maintain it as a medium severity
                  WHEN xx_emf_pkg.g_e_rec_error
                  THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                           xx_emf_cn_pkg.cn_rec_err
                                          );
                  WHEN xx_emf_pkg.g_e_prc_error
                  THEN
                     xx_emf_pkg.write_log
                                   (xx_emf_cn_pkg.cn_high,
                                    'Process Level Error in Data derivations'
                                   );
                     update_int_records_rm (x_resume_table);
                     raise_application_error (-20199,
                                              xx_emf_cn_pkg.cn_prc_err);
                  WHEN OTHERS
                  THEN
                     xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                       xx_emf_cn_pkg.cn_tech_error,
                                       xx_emf_cn_pkg.cn_exp_unhand,
                                       x_resume_table (i).record_number
                                      );
               END;
            END LOOP;

            dbg_low ('x_resume_table.count ' || x_resume_table.COUNT);
            update_int_records_rm (x_resume_table);
            x_resume_table.DELETE;
            EXIT WHEN c_xx_resume%NOTFOUND;
                                 --***DS: Table type variable used like cursor
         END LOOP;

         IF c_xx_resume%ISOPEN
         THEN
            CLOSE c_xx_resume;
         END IF;

         -- Set the stage to Post Validations
         set_stage (xx_emf_cn_pkg.cn_postval);
         -- Change the validations package to the appropriate package name
         -- Modify the parameters as required
         -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
         -- PRE_VALIDATIONS SHOULD BE RETAINED
         x_error_code := post_validations_resume ();
         dbg_med (   'After post-validations for resume X_ERROR_CODE '
                  || x_error_code
                 );
         mark_records_complete_rm (xx_emf_cn_pkg.cn_postval);
         dbg_med
            (   'After mark_records_complete post-validations for resume X_ERROR_CODE '
             || x_error_code
            );
         --xx_emf_pkg.propagate_error ( x_error_code);

         -- Set the stage to Process
         set_stage (xx_emf_cn_pkg.cn_process_data);
         dbg_med ('Before process_data for resume');

         OPEN c_xx_resume (xx_emf_cn_pkg.cn_postval);

         LOOP
            FETCH c_xx_resume
            BULK COLLECT INTO x_resume_table LIMIT g_resume_bulk_limit;--xx_emf_cn_pkg.cn_bulk_collect;

            FOR i IN 1 .. x_resume_table.COUNT
            LOOP
               BEGIN
                  -- Perform Base App Validations
                  x_error_code :=
                                 xx_create_resume_by_api (x_resume_table (i));
                                                     -------calling phone API
                  dbg_low (   'x_error_code for  '
                           || x_resume_table (i).record_number
                           || ' is '
                           || x_error_code
                          );
                  update_record_status_rm (x_resume_table (i), x_error_code);
                  xx_emf_pkg.propagate_error (x_error_code);
               EXCEPTION
                  -- If HIGH error then it will be propagated to the next level
                   -- IF the process has to continue maintain it as a medium severity
                  WHEN xx_emf_pkg.g_e_rec_error
                  THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                           xx_emf_cn_pkg.cn_rec_err
                                          );
                  WHEN xx_emf_pkg.g_e_prc_error
                  THEN
                     xx_emf_pkg.write_log
                                       (xx_emf_cn_pkg.cn_high,
                                        'Process Level Error in Data Process'
                                       );
                     update_int_records_rm (x_resume_table);
                     raise_application_error (-20199,
                                              xx_emf_cn_pkg.cn_prc_err);
                  WHEN OTHERS
                  THEN
                     xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                       xx_emf_cn_pkg.cn_tech_error,
                                       xx_emf_cn_pkg.cn_exp_unhand,
                                       x_resume_table (i).record_number
                                      );
               END;
            END LOOP;

            dbg_low ('x_resume_table.count ' || x_resume_table.COUNT);
            update_int_records_rm (x_resume_table);
            x_resume_table.DELETE;
            EXIT WHEN c_xx_resume%NOTFOUND;
         END LOOP;

         IF c_xx_resume%ISOPEN
         THEN
            CLOSE c_xx_resume;
         END IF;

         dbg_med ('After process_data for Resume');
         mark_records_complete_rm (xx_emf_cn_pkg.cn_process_data);
         dbg_med
            (   'After Process Data mark_records_complete for resume x_error_code'
             || x_error_code
            );
         xx_emf_pkg.propagate_error (x_error_code);
      END IF; 
      
      update_record_count (p_validate_and_load);
      xx_emf_pkg.create_report;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Checking if this is OK');
         fnd_file.put_line (fnd_file.output, xx_emf_pkg.cn_env_not_set);
         x_retcode := xx_emf_cn_pkg.cn_rec_err;
         update_record_count (p_validate_and_load);
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         dbg_low ('xx_emf_pkg.G_E_REC_ERROR');
         x_retcode := xx_emf_cn_pkg.cn_rec_err;
         update_record_count (p_validate_and_load);
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         dbg_low ('xx_emf_pkg.G_E_PRC_ERROR');
         x_retcode := xx_emf_cn_pkg.cn_prc_err;
         update_record_count (p_validate_and_load);
         xx_emf_pkg.create_report;
      WHEN OTHERS
      THEN
         dbg_low ('WHEN OTHERS' || SQLERRM);
         x_retcode := xx_emf_cn_pkg.cn_prc_err;
         update_record_count (p_validate_and_load);
         xx_emf_pkg.create_report;
   END main;
END xx_hr_appl_cnv_validation_pkg; 
/
