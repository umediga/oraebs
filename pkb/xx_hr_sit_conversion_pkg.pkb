DROP PACKAGE BODY APPS.XX_HR_SIT_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_SIT_CONVERSION_PKG" AS
/* $Header: XXHRSITCNV.pks 1.0.0 2012/03/07 00:00:00$ */
--=============================================================================
  -- Created By     : Arjun.K
  -- Creation Date  : 07-MAR-2012
  -- Filename       : XXHRSITCNV.pkb
  -- Description    : Package specification for emloyee SIT conversion.

  -- Change History:

  -- Date          Version#    Name                Remarks
  -- -----------   --------    ---------------     ----------------------------
  -- 07-MAR-2012   1.0         Arjun.K             Initial Development.
--=============================================================================

   ----------------------------------------------------------------------------
   ----------------------------< set_cnv_env >---------------------------------
   ----------------------------------------------------------------------------
   PROCEDURE set_cnv_env (p_batch_id      VARCHAR2
                         ,p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES
                         )
   IS
      x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside set_cnv_env...');
      G_BATCH_ID       := p_batch_id;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_BATCH_ID: '||G_BATCH_ID );

      -- Set the environment
      x_error_code := xx_emf_pkg.set_env;
      IF NVL (p_required_flag, xx_emf_cn_pkg.CN_YES) <> xx_emf_cn_pkg.CN_NO THEN
         xx_emf_pkg.propagate_error(x_error_code);
      END IF;
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'End of mark set_cnv_env.');
   EXCEPTION
      WHEN OTHERS THEN
         RAISE xx_emf_pkg.G_E_ENV_NOT_SET;
   END set_cnv_env;

   ----------------------------------------------------------------------------
   -------------------------------< dbg_low >----------------------------------
   ----------------------------------------------------------------------------
   PROCEDURE dbg_low (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low
                            ,g_api_name
                            || ': '||
                            p_dbg_text
                           );
   END dbg_low;

   ----------------------------------------------------------------------------
   -------------------------------< dbg_med >----------------------------------
   ----------------------------------------------------------------------------
   PROCEDURE dbg_med (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium
                            ,g_api_name
                            || ' : '||
                            p_dbg_text
                           );
   END dbg_med;

   ----------------------------------------------------------------------------
   -------------------------------< dbg_high >---------------------------------
   ----------------------------------------------------------------------------
   PROCEDURE dbg_high (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high
                            ,g_api_name
                            || ' : '||
                            p_dbg_text
                           );
   END dbg_high;

   ----------------------------------------------------------------------------
   ---------------------< mark_records_for_processing >------------------------
   ----------------------------------------------------------------------------
   PROCEDURE mark_records_for_processing (p_restart_flag  IN VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      g_api_name := 'mark_records_for_processing';
      dbg_low('Inside of mark records for processing...');
      IF p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS THEN
         UPDATE xx_hr_sit_stg -- Employee SIT Staging Table
            SET request_id = xx_emf_pkg.G_REQUEST_ID,
                error_code = xx_emf_cn_pkg.CN_NULL,
                process_code = xx_emf_cn_pkg.CN_NEW
          WHERE batch_id = G_BATCH_ID;
            --AND NVL(process_code,xx_emf_cn_pkg.CN_NEW) NOT IN(xx_emf_cn_pkg.CN_PROCESS_DATA);
      ELSIF p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS THEN
         UPDATE xx_hr_sit_stg
            SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                error_code   = xx_emf_cn_pkg.CN_NULL,
                process_code = xx_emf_cn_pkg.CN_NEW
          WHERE batch_id = G_BATCH_ID
            AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN
                (xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR);
      END IF;
      COMMIT;
      dbg_low('End of mark records for processing.');
   END mark_records_for_processing;

   ----------------------------------------------------------------------------
   ------------------------------< set_stage >---------------------------------
   ----------------------------------------------------------------------------
    PROCEDURE set_stage (p_stage VARCHAR2)
    IS
    BEGIN
       G_STAGE := p_stage;
    END set_stage;

   ----------------------------------------------------------------------------
   ------------------------< update_staging_records >--------------------------
   ----------------------------------------------------------------------------
   PROCEDURE update_staging_records( p_error_code VARCHAR2)
   IS
      x_last_update_date     DATE   := SYSDATE;
      x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      g_api_name := 'update_staging_records';
      dbg_low('Inside update_staging_records...');

      UPDATE xx_hr_sit_stg
         SET process_code = G_STAGE,
             error_code = DECODE ( error_code, NULL, p_error_code, error_code),
             last_update_date = x_last_update_date,
             last_updated_by   = G_USER_ID,
             last_update_login = x_last_update_login -- In template please make change
       WHERE batch_id = G_BATCH_ID
         AND request_id = xx_emf_pkg.G_REQUEST_ID
         AND process_code = xx_emf_cn_pkg.CN_NEW;-- To dynamically change process at different stages (pre-val/data-deri)

      COMMIT;
      dbg_low('End of update staging records.');
   EXCEPTION
      WHEN OTHERS THEN
         dbg_low('Error while updating staging records status: '||SQLERRM);
   END update_staging_records;

   ----------------------------------------------------------------------------
   -------------------------------< find_max >---------------------------------
   ----------------------------------------------------------------------------
   FUNCTION find_max (p_error_code1 IN VARCHAR2,
                      p_error_code2 IN VARCHAR2
                     )
   RETURN VARCHAR2
   IS
      x_return_value VARCHAR2(100);
   BEGIN
      x_return_value := xx_intg_common_pkg.find_max(p_error_code1, p_error_code2);
    RETURN x_return_value;
   END find_max;

   ----------------------------------------------------------------------------
   ----------------------------< pre_validations >-----------------------------
   ----------------------------------------------------------------------------
   FUNCTION pre_validations
   RETURN NUMBER
   IS
      x_error_code      NUMBER   := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp NUMBER   := xx_emf_cn_pkg.CN_SUCCESS;
      x_flex_num        NUMBER;
   BEGIN
      g_api_name := 'pre_validations';
      dbg_low('Inside pre_validations');
      BEGIN
         SELECT b.id_flex_num
           INTO x_flex_num
           FROM fnd_id_flex_structures b
          WHERE b.enabled_flag = 'Y'
            AND UPPER(b.id_flex_structure_code) = UPPER(g_accounting_flex)
            AND b.dynamic_inserts_allowed_flag='Y';
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         dbg_low('Flex Structure not found');
      WHEN OTHERS THEN
         dbg_low('Error while fetching flex structure'||SQLERRM);
      END;

      IF x_flex_num IS NOT NULL THEN
         dbg_low('Flex Structure:'||x_flex_num);
         UPDATE xx_hr_sit_stg
            SET id_flex_num = x_flex_num
          WHERE batch_id = G_BATCH_ID
            AND request_id = xx_emf_pkg.G_REQUEST_ID;
         COMMIT;
      ELSE
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         xx_emf_pkg.error (p_severity             => xx_emf_cn_pkg.CN_HIGH
                           ,p_category            => xx_emf_cn_pkg.CN_PREVAL
                           ,p_error_text          => 'Flex Structure '||g_accounting_flex||' not found'
                           ,p_record_identifier_4 => xx_emf_cn_pkg.CN_ALL_RECS
                          );
      END IF;
      dbg_low('End of pre validations.');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
   END pre_validations;

   ----------------------------------------------------------------------------
   ----------------------------< data_validations >----------------------------
   ----------------------------------------------------------------------------
   FUNCTION data_validations(csr_sit_stg_rec IN OUT xx_hr_sit_conversion_pkg.G_XXHR_SIT_STG_REC_TYPE)
   RETURN NUMBER
   IS
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
      g_api_name := 'data_validations';
      dbg_low('Inside data_validations');
      dbg_low('End of data validations.');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
   END data_validations;

   ----------------------------------------------------------------------------
   ----------------------------< data_derivations >----------------------------
   ----------------------------------------------------------------------------
   FUNCTION data_derivations(csr_sit_stg_rec IN OUT xx_hr_sit_conversion_pkg.G_XXHR_SIT_STG_REC_TYPE)
   RETURN NUMBER
   IS
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      ----------------------------------------------------------------------------
      ------------------------< get_target_person_bg_id >-------------------------
      ----------------------------------------------------------------------------
      FUNCTION get_target_person_bg_id(p_unique_id           IN          VARCHAR2
                                      ,p_business_group_id   OUT         NUMBER
                                      ,p_person_id           OUT NOCOPY  NUMBER
                                      )
      RETURN NUMBER
      IS
         x_error_code NUMBER := xx_emf_cn_pkg.cn_success;

         CURSOR c_person_details(p_unique_id   IN VARCHAR2)
         IS
         SELECT papf.person_id
               ,papf.business_group_id
           FROM per_all_people_f papf
          WHERE papf.attribute1 = p_unique_id
            AND TRUNC(SYSDATE) BETWEEN papf.effective_start_date AND papf.effective_end_date
          ORDER BY papf.effective_start_date;
      BEGIN
        p_person_id := NULL;
        IF p_unique_id IS NOT NULL THEN
           FOR r_person_details IN c_person_details(p_unique_id)
           LOOP
              p_person_id := r_person_details.person_id;
              p_business_group_id := r_person_details.business_group_id;
           END LOOP;
        ELSE
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
        END IF;
        RETURN x_error_code;
      EXCEPTION
         WHEN too_many_rows THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            RETURN x_error_code;
         WHEN no_data_found THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            RETURN x_error_code;
         WHEN others THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            RETURN x_error_code;
      END get_target_person_bg_id;

   BEGIN
      g_api_name := 'data_derivations';
      dbg_low('Inside data_derivations');
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Derivations');

      -- To derive to person ID and business group ID
      x_error_code_temp := get_target_person_bg_id(csr_sit_stg_rec.unique_id
                                                  ,csr_sit_stg_rec.business_group_id
                                                  ,csr_sit_stg_rec.person_id
                                                  );
      x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );

      IF csr_sit_stg_rec.person_id IS NULL THEN
         dbg_low('Person ID and Business Group ID not Derived');
         xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                          p_category => xx_emf_cn_pkg.cn_person_valid,
                          p_error_text => 'E:'||xx_emf_cn_pkg.CN_PERSON_NODATA,
                          p_record_identifier_1 => csr_sit_stg_rec.unique_id,
                          p_record_identifier_2 => csr_sit_stg_rec.date_from,
                          p_record_identifier_3 => csr_sit_stg_rec.date_to
                         );
      ELSE
         dbg_low('Person ID and Business Group ID Derived');
      END IF;
      dbg_low('End of data derivations.');
      RETURN x_error_code;
   EXCEPTION
   WHEN xx_emf_pkg.G_E_REC_ERROR THEN
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      RETURN x_error_code;
   WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
      x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
      RETURN x_error_code;
   WHEN OTHERS THEN
      x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
      RETURN x_error_code;
   END data_derivations;

   --------------------------------------------------------------------------------
   ---------------------------< post_validations >---------------------------------
   --------------------------------------------------------------------------------
   FUNCTION post_validations
   RETURN NUMBER
   IS
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
      g_api_name := 'post_validations';
      dbg_low('Inside post_validations');
      dbg_low('End of post validations.');
      RETURN x_error_code;
   EXCEPTION
   WHEN xx_emf_pkg.g_e_rec_error THEN
      x_error_code := xx_emf_cn_pkg.cn_rec_err;
      RETURN x_error_code;
   WHEN xx_emf_pkg.g_e_prc_error THEN
      x_error_code := xx_emf_cn_pkg.cn_prc_err;
      RETURN x_error_code;
   WHEN others THEN
      x_error_code := xx_emf_cn_pkg.cn_prc_err;
      RETURN x_error_code;
   END post_validations;

   --------------------------------------------------------------------------------
   --------------------------< update_record_count >-------------------------------
   --------------------------------------------------------------------------------
   PROCEDURE update_record_count
   IS
      CURSOR c_get_total_cnt
      IS
         SELECT COUNT (1) total_count
           FROM xx_hr_sit_stg
          WHERE batch_id = G_BATCH_ID
            AND request_id = xx_emf_pkg.G_REQUEST_ID;

      x_total_cnt NUMBER;

      CURSOR c_get_error_cnt
      IS
         SELECT SUM(error_count)
           FROM (
               SELECT COUNT (1) error_count
                 FROM xx_hr_sit_stg
                WHERE batch_id   = G_BATCH_ID
                  AND request_id = xx_emf_pkg.G_REQUEST_ID
                  AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

      x_error_cnt NUMBER;

      CURSOR c_get_warning_cnt
      IS
         SELECT COUNT (1) warn_count
           FROM xx_hr_sit_stg
          WHERE batch_id = G_BATCH_ID
            AND request_id = xx_emf_pkg.G_REQUEST_ID
            AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

      x_warn_cnt NUMBER;

      CURSOR c_get_success_cnt (c_validate NUMBER)
      IS
         SELECT COUNT (1) success_count
           FROM xx_hr_sit_stg
          WHERE batch_id = G_BATCH_ID
            AND request_id = xx_emf_pkg.G_REQUEST_ID
            AND process_code = decode(c_validate,1,process_code,xx_emf_cn_pkg.CN_PROCESS_DATA)
            AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

      x_success_cnt NUMBER;
      x_validate    NUMBER;

   BEGIN

      IF g_validate_flag = TRUE THEN
         x_validate := 1;
      ELSE
         x_validate := 0;
      END IF;

      OPEN c_get_total_cnt;
      FETCH c_get_total_cnt INTO x_total_cnt;
      CLOSE c_get_total_cnt;
      dbg_low('x_total_cnt:'||x_total_cnt);

      OPEN c_get_error_cnt;
      FETCH c_get_error_cnt INTO x_error_cnt;
      CLOSE c_get_error_cnt;
      dbg_low('x_error_cnt:'||x_error_cnt);

      OPEN c_get_warning_cnt;
      FETCH c_get_warning_cnt INTO x_warn_cnt;
      CLOSE c_get_warning_cnt;
      dbg_low('x_warn_cnt:'||x_warn_cnt);

      OPEN c_get_success_cnt(x_validate);
      FETCH c_get_success_cnt INTO x_success_cnt;
      CLOSE c_get_success_cnt;
      dbg_low('x_success_cnt:'||x_success_cnt);

      xx_emf_pkg.update_recs_cnt
      (p_total_recs_cnt   => x_total_cnt
      ,p_success_recs_cnt => x_success_cnt
      ,p_warning_recs_cnt => x_warn_cnt
      ,p_error_recs_cnt   => x_error_cnt
      );
   END update_record_count;

   /*------------------------------------------------------------------------------
   Procedure Name   :   main
   Parameters       :   x_errbuf                  OUT VARCHAR2
                        x_retcode                 OUT VARCHAR2
                        p_batch_id                IN  VARCHAR2
                        p_restart_flag            IN  VARCHAR2
                        p_validate_and_load       IN  VARCHAR2
   Purpose          :   This is the main procedure which subsequently calls
                        all other procedure.
   ------------------------------------------------------------------------------*/
   PROCEDURE main(x_errbuf             OUT VARCHAR2
                 ,x_retcode            OUT VARCHAR2
                 ,p_batch_id           IN  VARCHAR2
                 ,p_restart_flag       IN  VARCHAR2
                 ,p_validate_and_load  IN  VARCHAR2
                 )
   IS
      x_error_code          NUMBER          := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp     NUMBER          := xx_emf_cn_pkg.CN_SUCCESS;
      x_sitstg_table        G_XXHR_SIT_STG_TAB_TYPE;
      x_sqlerrm             VARCHAR2(2000);

      CURSOR c_xx_sitstg ( cp_process_status VARCHAR2)
      IS
         SELECT *
           FROM xx_hr_sit_stg
          WHERE batch_id     = G_BATCH_ID
            AND request_id   = xx_emf_pkg.G_REQUEST_ID
            AND process_code = cp_process_status
            AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
          ORDER BY record_number;

      ----------------------------------------------------------------------------
      --------------------------< update_record_status >--------------------------
      ----------------------------------------------------------------------------
      PROCEDURE update_record_status (p_conv_hdr_rec  IN OUT  G_XXHR_SIT_STG_REC_TYPE,
                                      p_error_code    IN      VARCHAR2
                                     )
      IS
      BEGIN
         g_api_name := 'main.update_record_status';
         dbg_low('Inside update_record_status...');
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update record status...');
         IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
         THEN
            p_conv_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
         ELSE
            p_conv_hdr_rec.error_code := xx_intg_common_pkg.find_max(p_error_code,
                                         NVL (p_conv_hdr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));
         END IF;
         p_conv_hdr_rec.process_code := G_STAGE;
         dbg_low('End of update record status.');
      END update_record_status;

      ----------------------------------------------------------------------------
      ---------------------------< update_stg_records >---------------------------
      ----------------------------------------------------------------------------
      PROCEDURE update_stg_records (p_sitstg_table IN g_xxhr_sit_stg_tab_type)
      IS
         x_last_update_date         DATE   := SYSDATE;
         x_last_updated_by          NUMBER := fnd_global.user_id;
         x_last_update_login        NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
         x_program_application_id   NUMBER := fnd_global.prog_appl_id;
         x_program_id               NUMBER := fnd_global.conc_program_id;
         x_program_update_date      DATE   := SYSDATE;
         indx                    NUMBER;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         g_api_name := 'main.update_stg_records';
         dbg_low('Inside update_stg_records...');
         FOR indx IN 1 .. p_sitstg_table.COUNT LOOP
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_sitstg_table(indx).process_code ' || p_sitstg_table(indx).process_code);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_sitstg_table(indx).error_code ' || p_sitstg_table(indx).error_code);

            UPDATE xx_hr_sit_stg
               SET employee_number         = p_sitstg_table(indx).employee_number
                  ,unique_id               = p_sitstg_table(indx).unique_id
                  ,date_from               = p_sitstg_table(indx).date_from
                  ,date_to                 = p_sitstg_table(indx).date_to
                  ,location                = p_sitstg_table(indx).location
                  ,job_title               = p_sitstg_table(indx).job_title
                  ,organization            = p_sitstg_table(indx).organization
                  ,supervisor_name         = p_sitstg_table(indx).supervisor_name
                  ,incentive_level         = p_sitstg_table(indx).incentive_level
                  ,salary_basis            = p_sitstg_table(indx).salary_basis
                  ,exit_reason             = p_sitstg_table(indx).exit_reason
                  ,status                  = p_sitstg_table(indx).status
                  ,assignment_category     = p_sitstg_table(indx).assignment_category
                  ,reason                  = p_sitstg_table(indx).reason
                  ,business_group_id       = p_sitstg_table(indx).business_group_id
                  ,person_id               = p_sitstg_table(indx).person_id
                  ,id_flex_num             = p_sitstg_table(indx).id_flex_num
                  ,process_code            = p_sitstg_table(indx).process_code
                  ,error_code              = p_sitstg_table(indx).error_code
                  ,created_by              = p_sitstg_table(indx).created_by
                  ,creation_date           = p_sitstg_table(indx).creation_date
                  ,last_update_date        = x_last_update_date
                  ,last_updated_by         = x_last_updated_by
                  ,last_update_login       = x_last_update_login
                  ,request_id              = p_sitstg_table(indx).request_id
                  ,program_application_id  = x_program_application_id
                  ,program_id              = x_program_id
                  ,program_update_date     = x_program_update_date
             WHERE record_number = p_sitstg_table(indx).record_number
               AND batch_id      = p_sitstg_table(indx).batch_id;
         END LOOP;
         COMMIT;
         dbg_low('End of update stg records.');
      END update_stg_records;

      -------------------------------------------------------------------------
      --------------------------< process_data >-------------------------------
      -------------------------------------------------------------------------
      FUNCTION process_data
      RETURN NUMBER
      IS
         x_return_status VARCHAR2(15) := xx_emf_cn_pkg.CN_SUCCESS;

         CURSOR xx_sitstg_cur
         IS
         SELECT *
           FROM xx_hr_sit_stg
          WHERE 1 = 1
            AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS,xx_emf_cn_pkg.CN_REC_WARN)
            AND batch_id     = G_BATCH_ID
          ORDER BY date_from;

      x_analysis_criteria_id            NUMBER;
      x_person_analysis_id              NUMBER;
      x_pea_object_version_number       NUMBER;

      BEGIN
         -- Change the logic to whatever needs to be done
         -- with valid records in the pre-interface tables
         -- either call the appropriate API to process the data
         -- or to insert into an interface table.
         FOR xx_sitstg_rec IN xx_sitstg_cur
         LOOP
            BEGIN
               x_analysis_criteria_id       := NULL;
               x_person_analysis_id         := NULL;
               x_pea_object_version_number  := NULL;
               HR_SIT_API.create_sit
                         (p_validate                  => g_validate_flag
                         ,p_person_id                 => xx_sitstg_rec.person_id
                         ,p_business_group_id         => xx_sitstg_rec.business_group_id
                         ,p_id_flex_num               => xx_sitstg_rec.id_flex_num
                         ,p_effective_date            => SYSDATE
                         ,p_comments                  => NULL
                         ,p_date_from                 => xx_sitstg_rec.date_from
                         ,p_date_to                   => xx_sitstg_rec.date_to
                         ,p_request_id                => xx_sitstg_rec.request_id
                         ,p_program_application_id    => xx_sitstg_rec.program_application_id
                         ,p_program_id                => xx_sitstg_rec.program_id
                         ,p_program_update_date       => xx_sitstg_rec.program_update_date
                         ,p_attribute_category        => NULL
                         ,p_attribute1                => NULL
                         ,p_attribute2                => NULL
                         ,p_attribute3                => NULL
                         ,p_attribute4                => NULL
                         ,p_attribute5                => NULL
                         ,p_attribute6                => NULL
                         ,p_attribute7                => NULL
                         ,p_attribute8                => NULL
                         ,p_attribute9                => NULL
                         ,p_attribute10               => NULL
                         ,p_attribute11               => NULL
                         ,p_attribute12               => NULL
                         ,p_attribute13               => NULL
                         ,p_attribute14               => NULL
                         ,p_attribute15               => NULL
                         ,p_attribute16               => NULL
                         ,p_attribute17               => NULL
                         ,p_attribute18               => NULL
                         ,p_attribute19               => NULL
                         ,p_attribute20               => NULL
                         ,p_segment1                  => xx_sitstg_rec.location
                         ,p_segment2                  => xx_sitstg_rec.job_title
                         ,p_segment3                  => xx_sitstg_rec.organization
                         ,p_segment4                  => xx_sitstg_rec.supervisor_name
                         ,p_segment5                  => xx_sitstg_rec.incentive_level
                         ,p_segment6                  => NULL
                         ,p_segment7                  => xx_sitstg_rec.salary_basis
                         ,p_segment8                  => NULL
                         ,p_segment9                  => xx_sitstg_rec.exit_reason
                         ,p_segment10                 => xx_sitstg_rec.status
                         ,p_segment11                 => xx_sitstg_rec.assignment_category
                         ,p_segment12                 => xx_sitstg_rec.reason
                         ,p_segment13                 => NULL
                         ,p_segment14                 => NULL
                         ,p_segment15                 => NULL
                         ,p_segment16                 => NULL
                         ,p_segment17                 => NULL
                         ,p_segment18                 => NULL
                         ,p_segment19                 => NULL
                         ,p_segment20                 => NULL
                         ,p_segment21                 => NULL
                         ,p_segment22                 => NULL
                         ,p_segment23                 => NULL
                         ,p_segment24                 => NULL
                         ,p_segment25                 => NULL
                         ,p_segment26                 => NULL
                         ,p_segment27                 => NULL
                         ,p_segment28                 => NULL
                         ,p_segment29                 => NULL
                         ,p_segment30                 => NULL
                         --,p_concat_segments           => NULL
                         ,p_analysis_criteria_id      => x_analysis_criteria_id
                         ,p_person_analysis_id        => x_person_analysis_id
                         ,p_pea_object_version_number => x_pea_object_version_number
                         );
               COMMIT;
            EXCEPTION
               WHEN OTHERS THEN
                  x_sqlerrm := substr(sqlerrm,1,800);
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.CN_MEDIUM
                                   ,p_category            =>   xx_emf_cn_pkg.CN_TECH_ERROR
                                   ,p_error_text          =>   x_sqlerrm
                                   ,p_record_identifier_1 =>   xx_sitstg_rec.unique_id
                                   ,p_record_identifier_2 =>   xx_sitstg_rec.date_from
                                   ,p_record_identifier_3 =>   xx_sitstg_rec.date_to
                                   );
                  UPDATE xx_hr_sit_stg
                     SET error_code         = x_error_code
                        ,process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                   WHERE batch_id           = G_BATCH_ID
                     AND record_number      = xx_sitstg_rec.record_number;
                   COMMIT;
            END;
            COMMIT;
         END LOOP;
         RETURN x_return_status;
      EXCEPTION
            WHEN OTHERS THEN
              x_sqlerrm := sqlerrm;
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity             => xx_emf_cn_pkg.CN_HIGH
                                ,p_category            => xx_emf_cn_pkg.CN_TECH_ERROR
                                ,p_error_text          => x_sqlerrm
                                ,p_record_identifier_4 => 'Process create SIT'
                               );
              RETURN x_error_code;
      END process_data;

      -- mark_records_complete
      PROCEDURE mark_records_complete (p_process_code           VARCHAR2)
      IS
         x_last_update_date       DATE   := SYSDATE;
         x_last_updated_by        NUMBER := fnd_global.user_id;
         x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         g_api_name := 'main.mark_records_complete';
         dbg_low('Inside mark_records_complete...');

         UPDATE xx_hr_sit_stg
            SET process_code      = G_STAGE,
                error_code        = NVL (error_code, xx_emf_cn_pkg.CN_SUCCESS),
                last_updated_by   = x_last_updated_by,
                last_update_date  = x_last_update_date,
                last_update_login = x_last_update_login
          WHERE batch_id     = G_BATCH_ID
            AND request_id   = xx_emf_pkg.G_REQUEST_ID
            AND process_code = DECODE (p_process_code
                                      ,xx_emf_cn_pkg.CN_PROCESS_DATA
                                      ,xx_emf_cn_pkg.CN_POSTVAL
                                      ,xx_emf_cn_pkg.CN_DERIVE)
            AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);
         COMMIT;
         dbg_low('End of mark records complete.');
      EXCEPTION
      WHEN OTHERS THEN
         dbg_low('Error in Update of mark records complete: '||SQLERRM);
      END mark_records_complete;
   BEGIN
      --Main Begin
      /*------------------------------------------------------------------------------
         --Initialize Trace
         --Purpose : Set the program environment for Tracing
      ------------------------------------------------------------------------------*/
      g_api_name := 'Main';
      x_retcode := xx_emf_cn_pkg.CN_SUCCESS;
      dbg_low('Before Setting Environment');

      -- Set Env --
      dbg_low('Calling set_cnv_env..');
      set_cnv_env (p_batch_id,xx_emf_cn_pkg.CN_YES);

      -- Include all the parameters to the conversion main here
      -- as medium log messages
      dbg_med('Starting main process with the following parameters');
      dbg_med('Param - p_batch_id          '|| p_batch_id);
      dbg_med('Param - p_restart_flag      '|| p_restart_flag);
      dbg_med('Param - p_validate_and_load '|| p_validate_and_load);
      --Popluate the global variable for validate flag
      IF p_validate_and_load = g_validate_and_load THEN
         g_validate_flag := FALSE;
         --dbg_med('Param - g_validate_flag '|| g_validate_flag);
      ELSE
         g_validate_flag := TRUE;
         --dbg_med('Param - g_validate_flag '|| g_validate_flag);
      END IF;

      -- Call procedure to update records with the current request_id
      -- so that we can process only those records
      -- This gives a better handling of restarting
      dbg_low('Calling mark_records_for_processing..');
      mark_records_for_processing(p_restart_flag => p_restart_flag);

      -- Set the stage to Pre Validations
      set_stage (xx_emf_cn_pkg.CN_PREVAL);

      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
      -- PRE_VALIDATIONS SHOULD BE RETAINED
      dbg_low('Calling pre_validations ..');
      x_error_code := pre_validations();
      dbg_med('After pre-validations X_ERROR_CODE : ' || X_ERROR_CODE);
      -- Update process code of staging records
      -- Update Header and Lines Level
      update_staging_records (x_error_code);
      xx_emf_pkg.propagate_error (x_error_code);

      dbg_low(G_REQUEST_ID || ' : Before Data Validations');
      -- Once pre-validations are complete loop through the pre-interface records
      -- and perform data validation on this table

      -- Set the stage to data Validations
      set_stage (xx_emf_cn_pkg.CN_VALID);

      OPEN c_xx_sitstg ( xx_emf_cn_pkg.CN_PREVAL);
      LOOP
      FETCH c_xx_sitstg
      BULK COLLECT INTO x_sitstg_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;
         FOR i IN 1 .. x_sitstg_table.COUNT
         LOOP
            BEGIN
               -- Perform Base App Validations
               x_error_code := data_validations(x_sitstg_table (i));
               dbg_low('x_error_code for '|| x_sitstg_table (i).record_number|| ' is ' || x_error_code);
               update_record_status (x_sitstg_table (i), x_error_code);
               xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
              -- If HIGH error then it will be propagated to the next level
              -- IF the process has to continue maintain it as a medium severity
              WHEN xx_emf_pkg.G_E_REC_ERROR THEN
                 dbg_high(xx_emf_cn_pkg.CN_REC_ERR);
              WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
                 dbg_high('Process Level Error in Data Validations');
                 update_stg_records (x_sitstg_table);
                 RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
              WHEN OTHERS THEN
                 xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM
                                 ,xx_emf_cn_pkg.CN_TECH_ERROR
                                 ,xx_emf_cn_pkg.CN_EXP_UNHAND
                                 ,x_sitstg_table (i).record_number);
            END;
         END LOOP;
         dbg_low('x_sitstg_table.count ' || x_sitstg_table.COUNT );
         update_stg_records( x_sitstg_table);
         x_sitstg_table.DELETE;
         EXIT WHEN c_xx_sitstg%NOTFOUND;
      END LOOP;

      IF c_xx_sitstg%ISOPEN THEN
          CLOSE c_xx_sitstg;
      END IF;

      dbg_low(G_REQUEST_ID || ' : Before Data Derivations');
      -- Once data-validations are complete loop through the pre-interface records
      -- and perform data derivations on this table

      -- Set the stage to data derivations
      set_stage (xx_emf_cn_pkg.CN_DERIVE);
      OPEN c_xx_sitstg ( xx_emf_cn_pkg.CN_VALID);
      LOOP
      FETCH c_xx_sitstg
      BULK COLLECT INTO x_sitstg_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;
         FOR i IN 1 .. x_sitstg_table.COUNT
         LOOP
            BEGIN
               -- Perform Base App Dervations
               x_error_code := data_derivations(x_sitstg_table (i));
               dbg_low('x_error_code for '|| x_sitstg_table (i).record_number|| ' is ' || x_error_code);
               update_record_status (x_sitstg_table (i), x_error_code);
               xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
              -- If HIGH error then it will be propagated to the next level
              -- IF the process has to continue maintain it as a medium severity
              WHEN xx_emf_pkg.G_E_REC_ERROR THEN
                 dbg_high(xx_emf_cn_pkg.CN_REC_ERR);
              WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
                 dbg_high('Process Level Error in Data Derivations');
                 update_stg_records (x_sitstg_table);
                 RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
              WHEN OTHERS THEN
                 xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM
                                 ,xx_emf_cn_pkg.CN_TECH_ERROR
                                 ,xx_emf_cn_pkg.CN_EXP_UNHAND
                                 ,x_sitstg_table (i).record_number);
            END;
         END LOOP;
         dbg_low('x_sitstg_table.count ' || x_sitstg_table.COUNT );
         update_stg_records( x_sitstg_table);
         x_sitstg_table.DELETE;
         EXIT WHEN c_xx_sitstg%NOTFOUND;
      END LOOP;

      IF c_xx_sitstg%ISOPEN THEN
          CLOSE c_xx_sitstg;
      END IF;

      -- Set the stage to Post Validations
      set_stage (xx_emf_cn_pkg.CN_POSTVAL);

      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
      -- PRE_VALIDATIONS SHOULD BE RETAINED
      dbg_low('Calling post_validations ..');
      x_error_code := post_validations();
      dbg_med('After post-validations X_ERROR_CODE : ' || X_ERROR_CODE);
      -- Update mark records complete for staging records
      mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL);
      dbg_med('After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);
      xx_emf_pkg.propagate_error (x_error_code);

      -- Set the stage to Process
      set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);

      dbg_low('Calling process_data');
      x_error_code := process_data();
      dbg_med('After post-process_data X_ERROR_CODE : ' || X_ERROR_CODE);
      mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA);
      dbg_med('After mark_records_complete X_ERROR_CODE'||X_ERROR_CODE);
      xx_emf_pkg.propagate_error ( x_error_code);

      update_record_count;
      xx_emf_pkg.create_report;

   EXCEPTION
      WHEN xx_emf_pkg.G_E_ENV_NOT_SET THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Checking for G_E_ENV_NOT_SET');
         fnd_file.put_line ( fnd_file.output, xx_emf_pkg.CN_ENV_NOT_SET);
         x_retcode := xx_emf_cn_pkg.CN_REC_ERR;
         update_record_count;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.G_E_REC_ERROR THEN
         x_retcode := xx_emf_cn_pkg.CN_REC_ERR;
         update_record_count;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
         x_retcode := xx_emf_cn_pkg.CN_PRC_ERR;
         update_record_count;
         xx_emf_pkg.create_report;
      WHEN OTHERS THEN
         x_retcode := xx_emf_cn_pkg.CN_PRC_ERR;
         update_record_count;
         xx_emf_pkg.create_report;
   END main;
END xx_hr_sit_conversion_pkg;
/
