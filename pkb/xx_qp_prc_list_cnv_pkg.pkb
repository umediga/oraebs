DROP PACKAGE BODY APPS.XX_QP_PRC_LIST_CNV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_QP_PRC_LIST_CNV_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : Debjani Roy
 Creation Date  : 24-MAY-2013
 File Name      : XXQPPRICELISTCNVTL.pkb
 Description    : This script creates the body of the package xx_qp_prc_list_cnv_pkg

----------------------------*------------------------------------------------------------------
-- Conversion Checklist ID  *  Change Required By Developer                                  --
----------------------------*------------------------------------------------------------------
-- CCID004                  *  Change the package name in line number 9 and 90 of this file  --
----------------------------*------------------------------------------------------------------
-- CCID005                  *  Change the columns in Type defnitions line 40, 56             --
----------------------------*------------------------------------------------------------------
-- CCID006                  *  Modify the parameters to procedure main line 79               --
--                          *  Retain p_batch_id, p_restart_flag, p_override_flag            --
----------------------------*------------------------------------------------------------------

 Change History:

Version Date        Name               Remarks
------- ----------- ----               -------------------------------
1.0     24-MAY-2013   Debjani Roy       Initial development.
*/
----------------------------------------------------------------------

   -- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
   -- START RESTRICTIONS

   ---------**********************----------
      x_total_record        NUMBER := 0 ;
      x_success_record      NUMBER := 0 ;
      x_success_header      NUMBER := 0 ;
      x_total_header        NUMBER := 0 ;
      x_error_record        NUMBER := 0 ;
      x_grp_total           NUMBER := 0 ;
      x_grp_success         NUMBER := 0 ;
      x_grp_error           NUMBER := 0 ;

   PROCEDURE set_cnv_env (
      p_batch_id        VARCHAR2
    , p_required_flag   VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_yes
   )
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      g_batch_id := p_batch_id;
      -- Set the environment
      x_error_code := xx_emf_pkg.set_env;
      ---DROY DELETE----------
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After setting env :'||x_error_code );
      ---DROY DELETE----------
      IF NVL ( p_required_flag, xx_emf_cn_pkg.cn_yes ) <> xx_emf_cn_pkg.cn_no
      THEN
         xx_emf_pkg.propagate_error ( x_error_code );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE xx_emf_pkg.g_e_env_not_set;
   END set_cnv_env;

   PROCEDURE mark_records_for_processing (
      p_restart_flag    IN   VARCHAR2
    , p_override_flag   IN   VARCHAR2
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      -- If the override is set records should not be purged from the pre-interface tables
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'mark_records_for_processing' );

      IF p_restart_flag = xx_emf_cn_pkg.cn_all_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- purge from pre-interface tables and oracle standard tables
                             DELETE FROM xx_qp_pr_list_hdr_pre
                             WHERE batch_id = G_BATCH_ID;

                            DELETE FROM xx_qp_pr_list_lines_pre
                             WHERE batch_id = G_BATCH_ID;

                            DELETE FROM xx_qp_pr_list_qlf_pre
                            WHERE batch_id = G_BATCH_ID;

                            UPDATE xx_qp_pr_list_hdr_stg
                               SET request_id = xx_emf_pkg.G_REQUEST_ID,
                                   error_code = xx_emf_cn_pkg.CN_NULL,
                                   process_code = xx_emf_cn_pkg.CN_NEW
                             WHERE batch_id = G_BATCH_ID;

                            UPDATE xx_qp_pr_list_lines_stg
                               SET request_id = xx_emf_pkg.G_REQUEST_ID,
                                   error_code = xx_emf_cn_pkg.CN_NULL,
                                   process_code = xx_emf_cn_pkg.CN_NEW
                             WHERE batch_id = G_BATCH_ID;


                            UPDATE xx_qp_pr_list_qlf_stg
                               SET request_id = xx_emf_pkg.G_REQUEST_ID,
                                   error_code = xx_emf_cn_pkg.CN_NULL,
                                   process_code = xx_emf_cn_pkg.CN_NEW
                             WHERE batch_id = G_BATCH_ID;
         ELSE
                            UPDATE xx_qp_pr_list_hdr_pre
                               SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                                   error_code = xx_emf_cn_pkg.CN_SUCCESS,
                                   request_id = xx_emf_pkg.G_REQUEST_ID
                             WHERE batch_id = G_BATCH_ID;

                            UPDATE xx_qp_pr_list_lines_pre
                               SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                                   error_code = xx_emf_cn_pkg.CN_SUCCESS,
                                   request_id = xx_emf_pkg.G_REQUEST_ID
                             WHERE batch_id = G_BATCH_ID;


                            UPDATE xx_qp_pr_list_qlf_pre
                               SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                                   error_code = xx_emf_cn_pkg.CN_SUCCESS,
                                   request_id = xx_emf_pkg.G_REQUEST_ID
                             WHERE batch_id = G_BATCH_ID;
         END IF;




      ELSIF p_restart_flag = xx_emf_cn_pkg.cn_err_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- Update staging table
                               UPDATE xx_qp_pr_list_hdr_stg
                               SET request_id = xx_emf_pkg.G_REQUEST_ID,
                                   error_code = xx_emf_cn_pkg.CN_NULL,
                                   process_code = xx_emf_cn_pkg.CN_NEW
                             WHERE batch_id = G_BATCH_ID
                               AND (
                                            process_code = xx_emf_cn_pkg.CN_NEW
                                            OR (
                                                    process_code = xx_emf_cn_pkg.CN_PREVAL
                                                    AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
                                                    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                                                )
                                    );


                            UPDATE xx_qp_pr_list_lines_stg
                               SET request_id = xx_emf_pkg.G_REQUEST_ID,
                                   error_code = xx_emf_cn_pkg.CN_NULL,
                                   process_code = xx_emf_cn_pkg.CN_NEW
                             WHERE batch_id = G_BATCH_ID
                               AND (
                                            process_code = xx_emf_cn_pkg.CN_NEW
                                            OR (
                                                    process_code = xx_emf_cn_pkg.CN_PREVAL
                                                    AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
                                                    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                                                )
                                    );


                            UPDATE xx_qp_pr_list_qlf_stg
                               SET request_id = xx_emf_pkg.G_REQUEST_ID,
                                   error_code = xx_emf_cn_pkg.CN_NULL,
                                   process_code = xx_emf_cn_pkg.CN_NEW
                             WHERE batch_id = G_BATCH_ID
                               AND (
                                            process_code = xx_emf_cn_pkg.CN_NEW
                                            OR (
                                                    process_code = xx_emf_cn_pkg.CN_PREVAL
                                                    AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
                                                    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                                                )
                                    );
         END IF;

         -- Update pre-interface table
         -- Scenario 1 Pre-Validation Stage
         UPDATE xx_qp_pr_list_hdr_stg a
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_NULL,
                           process_code = xx_emf_cn_pkg.CN_NEW
                     WHERE batch_id = G_BATCH_ID
                       AND EXISTS (
                            SELECT 1
                              FROM xx_qp_pr_list_hdr_pre
                             WHERE batch_id = G_BATCH_ID
                               AND process_code = xx_emf_cn_pkg.CN_PREVAL
                               AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                               AND record_number = a.record_number);


                    UPDATE xx_qp_pr_list_lines_stg a
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_NULL,
                           process_code = xx_emf_cn_pkg.CN_NEW
                     WHERE batch_id = G_BATCH_ID
                       AND EXISTS (
                            SELECT 1
                              FROM xx_qp_pr_list_lines_pre
                             WHERE batch_id = G_BATCH_ID
                               AND process_code = xx_emf_cn_pkg.CN_PREVAL
                               AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                               AND record_number = a.record_number);



                    UPDATE xx_qp_pr_list_qlf_stg a
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_NULL,
                           process_code = xx_emf_cn_pkg.CN_NEW
                     WHERE batch_id = G_BATCH_ID
                       AND EXISTS (
                            SELECT 1
                              FROM xx_qp_pr_list_qlf_pre
                             WHERE batch_id = G_BATCH_ID
                               AND process_code = xx_emf_cn_pkg.CN_PREVAL
                               AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                               AND record_number = a.record_number);


                     DELETE
                      FROM xx_qp_pr_list_hdr_pre
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_PREVAL
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);


                     DELETE
                      FROM xx_qp_pr_list_lines_pre
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_PREVAL
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    DELETE
                      FROM xx_qp_pr_list_qlf_pre
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_PREVAL
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    -- Scenario 2 Data Validation Stage

                    UPDATE xx_qp_pr_list_hdr_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_PREVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_VALID
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);


                    UPDATE xx_qp_pr_list_lines_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_PREVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_VALID
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    UPDATE xx_qp_pr_list_qlf_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_PREVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_VALID
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    -- Scenario 3 Data Derivation Stage

                    UPDATE xx_qp_pr_list_hdr_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_DERIVE
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_DERIVE
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);


                    UPDATE xx_qp_pr_list_lines_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_DERIVE
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_DERIVE
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    UPDATE xx_qp_pr_list_qlf_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_DERIVE
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_DERIVE
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    -- Scenario 4 Post Validation Stage

                    UPDATE xx_qp_pr_list_hdr_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_POSTVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_POSTVAL
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);


                    UPDATE xx_qp_pr_list_lines_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_POSTVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_POSTVAL
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    UPDATE xx_qp_pr_list_qlf_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_POSTVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_POSTVAL
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    -- Scenario 5 Process Data Stage

                    UPDATE xx_qp_pr_list_hdr_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_POSTVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_ERR);

                    UPDATE xx_qp_pr_list_lines_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_POSTVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_ERR);

                    UPDATE xx_qp_pr_list_qlf_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_POSTVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_ERR);
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Mark Records for Processing Error=>'||SQLERRM);
   END;

   PROCEDURE set_stage (
      p_stage   VARCHAR2
   )
   IS
   BEGIN
      g_stage := p_stage;
   END set_stage;

   PROCEDURE update_staging_records (
      p_error_code   VARCHAR2
   )
   IS
      x_last_update_date     DATE   := SYSDATE;
      x_last_updated_by       NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER := fnd_profile.VALUE ( xx_emf_cn_pkg.cn_login_id );
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~Inside Update Staging');
               UPDATE xx_qp_pr_list_hdr_stg
               SET process_code = G_STAGE,
                   error_code = DECODE ( error_code, NULL, p_error_code, error_code),
                   last_update_date = x_last_update_date,
                   last_updated_by = x_last_updated_by,
                   last_update_login = x_last_update_login
             WHERE batch_id = G_BATCH_ID
               AND request_id = xx_emf_pkg.G_REQUEST_ID
               AND process_code = xx_emf_cn_pkg.CN_NEW;


            UPDATE xx_qp_pr_list_lines_stg
               SET process_code = G_STAGE,
                   error_code = DECODE ( error_code, NULL, p_error_code, error_code),
                   last_update_date = x_last_update_date,
                   last_updated_by = x_last_updated_by,
                   last_update_login = x_last_update_login
             WHERE batch_id = G_BATCH_ID
               AND request_id = xx_emf_pkg.G_REQUEST_ID
               AND process_code = xx_emf_cn_pkg.CN_NEW;

            UPDATE xx_qp_pr_list_qlf_stg
               SET process_code = G_STAGE,
                   error_code = DECODE ( error_code, NULL, p_error_code, error_code),
                   last_update_date = x_last_update_date,
                   last_updated_by = x_last_updated_by,
                   last_update_login = x_last_update_login
             WHERE batch_id = G_BATCH_ID
               AND request_id = xx_emf_pkg.G_REQUEST_ID
               AND process_code = xx_emf_cn_pkg.CN_NEW;


      COMMIT;
   END update_staging_records;

-------------------------------------------------------------------------
-----------< mark_records_for_api_error >-------------------------------
-------------------------------------------------------------------------
   PROCEDURE mark_records_for_api_error (
      p_process_code          VARCHAR2
    --, p_price_list_name       VARCHAR2
    , p_orig_sys_header_ref   VARCHAR2
    , p_orig_sys_line_ref     VARCHAR2
    , p_orig_sys_qualifier_ref     VARCHAR2
    , p_msg_data              VARCHAR2
   )
   IS
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER := fnd_profile.VALUE ( xx_emf_cn_pkg.cn_login_id );

      CURSOR cur_print_hdr_err_records
      IS
         SELECT xgp.record_number
              --, xgp.name
              , xgp.orig_sys_header_ref
              --, orig_sys_line_ref
           FROM xx_qp_pr_list_hdr_pre xgp
          --,xx_qp_price_list_stg xgs
         WHERE  /*xgp.NAME = p_price_list_name
            AND */xgp.request_id = xx_emf_pkg.g_request_id
            AND xgp.process_code = g_stage
            AND xgp.orig_sys_header_ref = p_orig_sys_header_ref
            AND xgp.batch_id = g_batch_id
            AND error_code = xx_emf_cn_pkg.CN_REC_ERR
      ;


      CURSOR cur_print_lines_err_records
      IS
         SELECT xgp.record_number
              --, xgp.name
              , xgp.orig_sys_header_ref
              , orig_sys_line_ref
              , orig_sys_pricing_attr_ref
           FROM xx_qp_pr_list_lines_pre xgp
          --,xx_qp_price_list_stg xgs
         WHERE  /*xgp.NAME = p_price_list_name
            AND*/ xgp.request_id = xx_emf_pkg.g_request_id
            AND xgp.process_code = g_stage
            AND xgp.orig_sys_line_ref = p_orig_sys_header_ref
            AND xgp.batch_id = g_batch_id
            AND error_code = xx_emf_cn_pkg.CN_REC_ERR
      ;

    CURSOR cur_print_qlf_err_records
      IS
         SELECT xgp.record_number
              --, xgp.name
              , xgp.orig_sys_header_ref
              , orig_sys_line_ref
              , orig_sys_qualifier_ref
           FROM xx_qp_pr_list_qlf_pre xgp
          --,xx_qp_price_list_stg xgs
         WHERE /* xgp.NAME = p_price_list_name
            AND*/ xgp.request_id = xx_emf_pkg.g_request_id
            AND xgp.process_code = g_stage
            AND xgp.orig_sys_header_ref = p_orig_sys_header_ref
            AND xgp.batch_id = g_batch_id
            AND error_code = xx_emf_cn_pkg.CN_REC_ERR
      ;

      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN

                   UPDATE xx_qp_pr_list_hdr_pre
                   SET process_code = xx_emf_cn_pkg.CN_PROCESS_DATA,
                       error_code = xx_emf_cn_pkg.CN_REC_ERR,
                       error_desc  = SUBSTR(p_msg_data,1,1000) ,
                       last_updated_by = x_last_updated_by,
                       last_update_date = x_last_update_date,
                       last_update_login = x_last_update_login
                 WHERE batch_id        = G_BATCH_ID
                   --AND request_id      = xx_emf_pkg.G_REQUEST_ID
                   AND orig_sys_header_ref  = p_orig_sys_header_ref
                   --AND list_type_code  = p_list_type_code
                   AND process_code      = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
                                                   , xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE
                                                   )
                   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                   ;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~No of Records in Price List Hdr Table marked with API Error=>'||SQL%ROWCOUNT);

                IF p_orig_sys_line_ref IS NOT NULL THEN
                UPDATE xx_qp_pr_list_lines_pre
                   SET process_code = xx_emf_cn_pkg.CN_PROCESS_DATA,
                       error_code = xx_emf_cn_pkg.CN_REC_ERR,
                       error_desc  = SUBSTR(p_msg_data,1,1000) ,
                       last_updated_by = x_last_updated_by,
                       last_update_date = x_last_update_date,
                       last_update_login = x_last_update_login
                 WHERE batch_id        = G_BATCH_ID
                   AND/* request_id      = xx_emf_pkg.G_REQUEST_ID
                   AND */orig_sys_header_ref  = p_orig_sys_header_ref
                   AND orig_sys_line_ref  = p_orig_sys_line_ref
                   AND process_code      = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
                                                   , xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE
                                                   )
                   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                   ;
                  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~No of Records in Price List Lines Table marked with API Error=>'||SQL%ROWCOUNT);
                  END IF;



                IF p_orig_sys_qualifier_ref IS NOT NULL THEN
                UPDATE xx_qp_pr_list_qlf_pre
                   SET process_code = xx_emf_cn_pkg.CN_PROCESS_DATA,
                       error_code = xx_emf_cn_pkg.CN_REC_ERR,
                       error_desc  = SUBSTR(p_msg_data,1,1000) ,
                       last_updated_by = x_last_updated_by,
                       last_update_date = x_last_update_date,
                       last_update_login = x_last_update_login
                 WHERE batch_id        = G_BATCH_ID
                   --AND request_id      = xx_emf_pkg.G_REQUEST_ID
                   AND orig_sys_header_ref  = p_orig_sys_header_ref
                   AND orig_sys_qualifier_ref  = p_orig_sys_qualifier_ref
                   AND process_code      = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
                                                   , xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE
                                                   )
                   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                   ;
                  END IF;
                   COMMIT;
   END mark_records_for_api_error;

   PROCEDURE create_records_for_api_error
   IS
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER := fnd_profile.VALUE ( xx_emf_cn_pkg.cn_login_id );

      CURSOR cur_print_hdr_err_records
      IS
         SELECT xgp.record_number
              --, xgp.name
              , xgp.orig_sys_header_ref
              , error_desc
           FROM xx_qp_pr_list_hdr_pre xgp
         WHERE  /*xgp.request_id = xx_emf_pkg.g_request_id
            AND xgp.process_code = DECODE (g_stage, xx_emf_cn_pkg.CN_PROCESS_DATA
                                                   , xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE
                                                   )
            AND*/ xgp.process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
            --AND xgp.custom_batch_no = p_custom_batch_no
            AND xgp.batch_id = g_batch_id
            AND error_code IN (xx_emf_cn_pkg.CN_REC_ERR)
      ;


      CURSOR cur_print_lines_err_records
      IS
         SELECT xgp.record_number
              --, xgp.name
              , xgp.orig_sys_header_ref
              , orig_sys_line_ref
              , orig_sys_pricing_attr_ref
              , error_desc
           FROM xx_qp_pr_list_lines_pre xgp
         WHERE  /*xgp.request_id = xx_emf_pkg.g_request_id
            AND*/ xgp.batch_id = g_batch_id
            /*AND xgp.process_code = DECODE (g_stage, xx_emf_cn_pkg.CN_PROCESS_DATA
                                                   , xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE
                                                   )*/
            AND xgp.process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
            AND error_code IN (xx_emf_cn_pkg.CN_REC_ERR)
      ;

    CURSOR cur_print_qlf_err_records
      IS
         SELECT xgp.record_number
              --, xgp.name
              , xgp.orig_sys_header_ref
              , orig_sys_line_ref
              , orig_sys_qualifier_ref
              , error_desc
           FROM xx_qp_pr_list_qlf_pre xgp
         WHERE /*xgp.request_id = xx_emf_pkg.g_request_id
            AND*/ xgp.batch_id = g_batch_id
            /*AND xgp.process_code = DECODE (g_stage, xx_emf_cn_pkg.CN_PROCESS_DATA
                                                   , xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE
                                                   )*/
            AND xgp.process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
            AND error_code IN (xx_emf_cn_pkg.CN_REC_ERR)
      ;

      --PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      FOR cur_rec IN cur_print_hdr_err_records
      LOOP
         xx_emf_pkg.error ( p_severity                 => xx_emf_cn_pkg.cn_medium
                          , p_category                 => xx_emf_cn_pkg.cn_stg_apicall
                          , p_error_text               => cur_rec.error_desc
                         ,p_record_identifier_1 => cur_rec.record_number
                     ,p_record_identifier_2 => cur_rec.orig_sys_header_ref
                    -- ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                   --  ,p_orig_sys_pricing_attr_ref  => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                          );
      END LOOP;

      FOR cur_rec IN cur_print_lines_err_records
      LOOP
         xx_emf_pkg.error ( p_severity                 => xx_emf_cn_pkg.cn_medium
                          , p_category                 => xx_emf_cn_pkg.cn_stg_apicall
                          , p_error_text               => cur_rec.error_desc
                         ,p_record_identifier_1 => cur_rec.record_number
                     ,p_record_identifier_2 => cur_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => cur_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => cur_rec.orig_sys_pricing_attr_ref
                    -- ,p_orig_sys_pricing_attr_ref  => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                          );
      END LOOP;

      FOR cur_rec IN cur_print_qlf_err_records
      LOOP
         xx_emf_pkg.error ( p_severity                 => xx_emf_cn_pkg.cn_medium
                          , p_category                 => xx_emf_cn_pkg.cn_stg_apicall
                          , p_error_text               => cur_rec.error_desc
                         ,p_record_identifier_1 => cur_rec.record_number
                     ,p_record_identifier_2 => cur_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => cur_rec.orig_sys_line_ref
                    -- ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => cur_rec.orig_sys_Qualifier_ref
                          );
      END LOOP;
   END create_records_for_api_error;


   PROCEDURE process_data_insert_mode (
     errbuf                 OUT VARCHAR2
    ,retcode                OUT  NUMBER
    ,p_batch_id             IN   VARCHAR2
    ,p_custom_batch_no      IN   NUMBER
   )
     -- RETURN NUMBER
   IS


      CURSOR csr_list_headers (
         cp_custom_batch_no   NUMBER
      )
      IS
         SELECT /*DISTINCT*/ orig_sys_header_ref
                       , list_type_code
                       , NAME
                      -- , list_header_id
                       , description
                       , currency_code
                       , active_flag
                     --  , currency_header_id
                       , trunc(TO_DATE(start_date_active)) start_date_active
                       , trunc(TO_DATE(end_date_active)) end_date_active
                       , NULL
                       , freight_terms_code
                       , automatic_flag
                       , comments
                       , pte_code
                       , 'US'   /*source_lang*/
                      -- , LANGUAGE
                      /* , hdr_attribute1
                       , hdr_attribute2
                       , hdr_attribute3
                       , hdr_attribute4
                       , hdr_attribute5
                       , hdr_attribute_status*/
                       , global_flag
                       , org_id
                      -- , CONTEXT
                      -- , delete_flag
                      -- , list_source_code
                      -- , lock_flag
                       , mobile_download
                       , DECODE ( rounding_factor, NULL, -2, rounding_factor ) rounding_factor
                       , source_system_code
                       , version_no
                       --,cust_account_id
         --,               interface_action_code   --'INSERT'
                    --   , process_flag   --'Y'
                    --   , process_status_flag   --'P'
                       , created_by
                       , trunc(creation_date)  creation_date
                       , trunc(last_update_date) last_update_date
                       , last_updated_by
                       , last_update_login
                       ,process_code
                       ,custom_lines_count
                    FROM xx_qp_pr_list_hdr_pre
                   WHERE batch_id = p_batch_id
                     --AND request_id = xx_emf_pkg.g_request_id
                     AND custom_batch_no = cp_custom_batch_no
                     --AND orig_sys_header_ref = cp_orig_sys_header_ref
                     AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success)--, xx_emf_cn_pkg.cn_rec_warn ) --warning for loading only qualifiers
                     AND process_code = xx_emf_cn_pkg.cn_postval
                     --AND custom_batch_status IS NOT NULL
                     ORDER BY custom_batch_no,custom_subbatch_no;

      CURSOR csr_list_lines_group (
         cp_orig_sys_header_ref             VARCHAR2
      )
      IS
         SELECT DISTINCT orig_sys_line_ref,
                         orig_sys_header_ref
                    --INTO l_orig_sys_line_ref
         FROM            xx_qp_pr_list_lines_pre
                   WHERE batch_id = p_batch_id
                     --AND request_id = xx_emf_pkg.g_request_id
                     AND orig_sys_header_ref = cp_orig_sys_header_ref
                     /*AND CASE
                            WHEN list_header_id IS NULL
                            AND NAME = cp_name
                               THEN 'okay'
                            WHEN list_header_id = cp_list_header_id
                            AND list_header_id IS NOT NULL
                               THEN 'okay'
                         END = 'okay'*/
                     AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
                     AND process_code = xx_emf_cn_pkg.cn_postval
                     ORDER BY /*name,*/orig_sys_line_ref;

      CURSOR csr_list_lines (
         /*cp_list_header_id      NUMBER
       , cp_name                VARCHAR2
       , */cp_orig_sys_line_ref   VARCHAR2
      )
      IS
         SELECT DISTINCT orig_sys_line_ref
                       , orig_sys_header_ref
                      -- , name
                      -- , list_header_id
                       , list_line_type_code
                       , trunc(start_date_active) start_date_active
                       , trunc(end_date_active) end_date_active
                       , arithmetic_operator
                       , operand
                       , primary_uom_flag
                       , TO_NUMBER ( product_precedence ) product_precedence
                       --, orig_sys_pricing_attr_ref --DROY
                       , product_attribute_context
                       , product_attribute_code
                       , product_attribute
                       , product_attr_value
                       , product_uom_code
                       , pricing_attribute_context
                       , incompatibility_grp_code
                       , qualification_ind
                       , accumulate_flag
                      -- , pricing_attr_code  --DROY
                       , pricing_attribute
                       , pricing_attr_value_from
                       , pricing_attr_value_to
                       , comparison_operator_code
                     --  , interface_action_code   --'INSERT'
                     --  , process_flag   --'Y'
                     --  , process_status_flag   --'P'
                       , created_by
                       , creation_date
                       , last_update_date
                       , last_updated_by
                       , last_update_login
                       , record_number
                       , from_orig_sys_hdr_ref
                       , to_orig_sys_hdr_ref
                       , price_break_header_ref
                       , price_break_type_code
                       , ( CASE
                              WHEN list_line_type_code = 'PLL'
                              AND price_break_type_code = 'POINT'
                                 THEN 'PRICE BREAK'
                              ELSE ''
                           END
                         ) rltd_modifier_grp_type
                    FROM xx_qp_pr_list_lines_pre
                   WHERE batch_id = p_batch_id
                     --AND request_id = xx_emf_pkg.g_request_id
                     AND orig_sys_header_ref = cp_orig_sys_line_ref
                     /*AND CASE
                            WHEN list_header_id IS NULL
                            AND NAME = cp_name
                               THEN 'okay'
                            WHEN list_header_id = cp_list_header_id
                            AND list_header_id IS NOT NULL
                               THEN 'okay'
                         END = 'okay' */
                     AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
                     AND process_code = xx_emf_cn_pkg.cn_postval
                ORDER BY /*name,*/price_break_type_code,NVL(from_orig_sys_hdr_ref,orig_sys_line_ref)
                                 ,NVL(to_orig_sys_hdr_ref,orig_sys_line_ref)
                                 ,list_line_type_code
                                 ,pricing_attr_value_from;

                --DROY ADD QUALIFIERS


      CURSOR csr_list_attrs (
         cp_orig_sys_header_ref  VARCHAR2
       , cp_orig_sys_line_ref    VARCHAR2
      )
      IS
         SELECT DISTINCT /*orig_sys_pricing_attr_ref --DROY
                       , */orig_sys_line_ref
                       , orig_sys_header_ref
                      -- , list_header_id
                       , product_attribute_context
                       , product_attribute_code
                       , product_attribute
                       , product_attr_value
                       , product_uom_code
                       , pricing_attribute_context
                      -- , pricing_attr_code --DROY
                       , pricing_attribute
                       , pricing_attr_value_from
                       , pricing_attr_value_to
                       , comparison_operator_code
                       , created_by
                       , creation_date
                       , last_update_date
                       , last_updated_by
                       , last_update_login
                       , record_number
                    FROM xx_qp_pr_list_lines_pre
                   WHERE batch_id = g_batch_id
                     AND orig_sys_header_ref = cp_orig_sys_header_ref
                     --AND price_break_type_code IS NULL
                     --AND pricing_attr_code IS NOT NULL --DROY
                     AND pricing_attribute IS NOT NULL  --DROY
                     --AND product_attribute_code = cp_product_attr_code
                     --AND product_attr_value = cp_product_attr_value
                     --AND NVL ( operand, 1 ) = NVL ( cp_operand, 1 )
                     AND orig_sys_line_ref = cp_orig_sys_line_ref
                     --AND request_id = xx_emf_pkg.g_request_id
                     AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
                     AND process_code = xx_emf_cn_pkg.cn_postval
                --ORDER BY orig_sys_line_ref, record_number
                ;





      TYPE xx_qp_hdrs_tbl IS TABLE OF csr_list_headers%ROWTYPE
         INDEX BY BINARY_INTEGER;

      xx_qp_hdrs_tbl_type           xx_qp_hdrs_tbl;

      TYPE xx_qp_lines_tbl IS TABLE OF csr_list_lines%ROWTYPE
         INDEX BY BINARY_INTEGER;

      xx_qp_lines_tbl_type          xx_qp_lines_tbl;

      TYPE xx_qp_attrs_tbl IS TABLE OF csr_list_attrs%ROWTYPE
         INDEX BY BINARY_INTEGER;

      xx_qp_attrs_tbl_type          xx_qp_attrs_tbl;


      /*TYPE xx_qp_qlf_tbl IS TABLE OF c_pre_std_qlf_hdr%ROWTYPE
         INDEX BY BINARY_INTEGER;

      xx_qp_qlf_tbl_type    xx_qp_QLF_tbl;*/

      xx_qlf_pre_tab_type               G_XX_QP_PL_QLF_PRE_TAB_TYPE;


      i                             NUMBER;
      j                             NUMBER;
      k                             NUMBER;
      l_list_header_id              NUMBER;
      l_list_line_count             NUMBER;
      l_list_attr_count             NUMBER;
      b_list_line_count             NUMBER;
      b_list_attr_count             NUMBER;
      --xx_qp_attr_tbl_type           xx_qp_attrs_tbl;
      x_error_code                  NUMBER                                              := xx_emf_cn_pkg.cn_success;
      x_return_status               VARCHAR2 ( 15 )                                     := xx_emf_cn_pkg.cn_success;
      gpr_return_status             VARCHAR2 ( 1 )                                      := NULL;
      gpr_msg_count                 NUMBER                                              := 0;
      gpr_msg_data                  VARCHAR2 ( 32767 );
      gpr_msg_data2                 VARCHAR2 ( 32767 );
      l_attr_bulk_index             NUMBER                                              := 0;
      l_pricing_attr_index          NUMBER                                              := 1;
      l_line_bulk_index             NUMBER                                              := 0;
      l_lpr_line_index              NUMBER                                              := 0;
      x_hdr_limit                   NUMBER                                              := 1000;
      x_line_limit                  NUMBER                                              := 1000;
      x_attr_limit                  NUMBER                                              := 1000;
      l_orig_sys_header_ref         VARCHAR2 ( 50 )                                     := '';
      l_orig_sys_line_ref           VARCHAR2 ( 50 )                                     := '';
      l_price_break_index           NUMBER                                              := 0;
      x_qp_profile                  VARCHAR2(10);
      gpr_price_list_rec            qp_price_list_pub.price_list_rec_type;
      gpr_price_list_val_rec        qp_price_list_pub.price_list_val_rec_type;
      gpr_price_list_line_tbl       qp_price_list_pub.price_list_line_tbl_type;
      gpr_price_list_line_val_tbl   qp_price_list_pub.price_list_line_val_tbl_type;
      gpr_qualifiers_tbl            qp_qualifier_rules_pub.qualifiers_tbl_type;
      gpr_qualifiers_val_tbl        qp_qualifier_rules_pub.qualifiers_val_tbl_type;
      gpr_pricing_attr_tbl          qp_price_list_pub.pricing_attr_tbl_type;
      gpr_pricing_attr_val_tbl      qp_price_list_pub.pricing_attr_val_tbl_type;
      ppr_price_list_rec            qp_price_list_pub.price_list_rec_type;
      ppr_price_list_val_rec        qp_price_list_pub.price_list_val_rec_type;
      ppr_price_list_line_tbl       qp_price_list_pub.price_list_line_tbl_type;
      ppr_price_list_line_val_tbl   qp_price_list_pub.price_list_line_val_tbl_type;
      ppr_qualifier_rules_rec       qp_qualifier_rules_pub.qualifier_rules_rec_type;
      ppr_qualifier_rules_val_rec   qp_qualifier_rules_pub.qualifier_rules_val_rec_type;
      ppr_qualifiers_tbl            qp_qualifier_rules_pub.qualifiers_tbl_type;
      ppr_qualifiers_val_tbl        qp_qualifier_rules_pub.qualifiers_val_tbl_type;
      ppr_pricing_attr_tbl          qp_price_list_pub.pricing_attr_tbl_type;
      ppr_pricing_attr_val_tbl      qp_price_list_pub.pricing_attr_val_tbl_type;

      l_sec_pl_exists                 VARCHAR2(1);
      x_hdr_err_flag                  VARCHAR2(1);
      x_line_err_flag                 VARCHAR2(1);
      x_attr_err_flag                  VARCHAR2(1);
      x_qlf_err_flag                  VARCHAR2(1);
      x_sec_err_flag                  VARCHAR2(1);


      ------sec pricelist------------------------------------------------------
      --************ added variable to count total,success and errro *******--------
      x_success_temp     NUMBER;
      X_DTL_ATTRIBUTE    VARCHAR2(100);

   BEGIN
        set_cnv_env ( p_batch_id => p_batch_id, p_required_flag => xx_emf_cn_pkg.cn_yes );
     -- LOOP
         --  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Processing a new set of Primary Price List- Current Time: '|| TO_CHAR (SYSDATE, 'DD-MON-YYYY  HH:MI:SS ');

         --Select the price lists header data from pre tables
         --xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'passing parameter p_name' || p_name );


         --Debjani delete comments later-------------------------------------------
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Process Data data : request_id :'||xx_emf_pkg.g_request_id);

         OPEN csr_list_headers ( p_custom_batch_no );

         FETCH csr_list_headers
         BULK COLLECT INTO xx_qp_hdrs_tbl_type LIMIT x_hdr_limit;

         CLOSE csr_list_headers;

         IF xx_qp_hdrs_tbl_type.COUNT = 0
         THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'No more Primary Price lists to import in insert mode' );
            fnd_file.put_line(fnd_file.log,'Batch id ' || p_batch_id );
            fnd_file.put_line(fnd_file.log,'Batch no ' || p_custom_batch_no );
           -- EXIT;
         ELSE
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'header CNT ' || xx_qp_hdrs_tbl_type.COUNT );
            fnd_file.put_line(fnd_file.log,'header CNT ' || xx_qp_hdrs_tbl_type.COUNT );

            FOR l_header_index IN xx_qp_hdrs_tbl_type.FIRST .. xx_qp_hdrs_tbl_type.LAST
            LOOP
               l_line_bulk_index := 0;
               l_attr_bulk_index := 0;
               gpr_price_list_line_tbl.DELETE;
               gpr_pricing_attr_tbl.DELETE;
               l_pricing_attr_index := 0;

               x_hdr_err_flag  := 'N' ;
               x_line_err_flag := 'N' ;
               x_attr_err_flag := 'N' ;
               x_qlf_err_flag  := 'N' ;
               x_sec_err_flag  := 'N' ;


               x_qp_profile := fnd_profile.value('QP_SOURCE_SYSTEM_CODE'); -- added to fetch the value from responsibility level

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Process Data in Insert Mode' );
               fnd_file.put_line(fnd_file.log, 'Process Code '||xx_qp_hdrs_tbl_type ( l_header_index ).process_code );
               gpr_price_list_rec.list_header_id := fnd_api.g_miss_num;
               l_orig_sys_header_ref :=  xx_qp_hdrs_tbl_type ( l_header_index ).orig_sys_header_ref; --DROY added
               gpr_price_list_rec.automatic_flag := xx_qp_hdrs_tbl_type ( l_header_index ).automatic_flag;
               gpr_price_list_rec.currency_code := xx_qp_hdrs_tbl_type ( l_header_index ).currency_code;
               --gpr_price_list_rec.currency_header_id := xx_qp_hdrs_tbl_type ( l_header_index ).currency_header_id;
               --gpr_price_list_rec.currency_header_id := 3; --DROY DEBUGGING IF THIS IS REQUIRED
               gpr_price_list_rec.end_date_active := xx_qp_hdrs_tbl_type ( l_header_index ).end_date_active;
               gpr_price_list_rec.freight_terms_code := xx_qp_hdrs_tbl_type ( l_header_index ).freight_terms_code;
               gpr_price_list_rec.global_flag := xx_qp_hdrs_tbl_type ( l_header_index ).global_flag;
               gpr_price_list_rec.org_id := xx_qp_hdrs_tbl_type ( l_header_index ).org_id; --org_id is introduced
               gpr_price_list_rec.gsa_indicator := '';
               gpr_price_list_rec.list_type_code := xx_qp_hdrs_tbl_type ( l_header_index ).list_type_code;
               gpr_price_list_rec.orig_system_header_ref := l_orig_sys_header_ref;
               --gpr_price_list_rec.source_system_code :=xx_qp_hdrs_tbl_type ( l_header_index ).source_system_code;--data file value fetced
               --gpr_price_list_rec.pte_code :=xx_qp_hdrs_tbl_type ( l_header_index ).pte_code;--data file value fetced
               --gpr_price_list_rec.source_system_code := 'QP';
               gpr_price_list_rec.source_system_code := x_qp_profile ;
               gpr_price_list_rec.pte_code := xx_qp_hdrs_tbl_type ( l_header_index ).pte_code;
               gpr_price_list_rec.ship_method_code := '';
               gpr_price_list_rec.start_date_active := xx_qp_hdrs_tbl_type ( l_header_index ).start_date_active;
               gpr_price_list_rec.operation := qp_globals.g_opr_create;
               gpr_price_list_rec.NAME := xx_qp_hdrs_tbl_type ( l_header_index ).NAME;
               gpr_price_list_rec.description := xx_qp_hdrs_tbl_type ( l_header_index ).description;
               gpr_price_list_rec.comments := xx_qp_hdrs_tbl_type ( l_header_index ).comments;
               gpr_price_list_rec.active_flag := 'Y';
               gpr_price_list_rec.request_id :=xx_emf_pkg.g_request_id;
               gpr_price_list_rec.ATTRIBUTE15 :=g_batch_id;


               --Creating Price List Header

               BEGIN
                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Calling api to create pricelist ' );
                   fnd_file.put_line(fnd_file.log,'Calling api to create pricelist ' );
                   fnd_msg_pub.initialize;
                   BEGIN
                       qp_price_list_pub.process_price_list ( p_api_version_number           => 1
                                                            , p_init_msg_list                => fnd_api.g_true
                                                            , p_return_values                => fnd_api.g_false
                                                            , p_commit                       => fnd_api.g_false
                                                            , x_return_status                => gpr_return_status
                                                            , x_msg_count                    => gpr_msg_count
                                                            , x_msg_data                     => gpr_msg_data
                                                            , p_price_list_rec               => gpr_price_list_rec
                                                            , p_price_list_line_tbl          => gpr_price_list_line_tbl
                                                            , p_qualifiers_tbl               => gpr_qualifiers_tbl
                                                            , p_pricing_attr_tbl             => gpr_pricing_attr_tbl
                                                            , x_price_list_rec               => ppr_price_list_rec
                                                            , x_price_list_val_rec           => ppr_price_list_val_rec
                                                            , x_price_list_line_tbl          => ppr_price_list_line_tbl
                                                            , x_price_list_line_val_tbl      => ppr_price_list_line_val_tbl
                                                            , x_qualifiers_tbl               => ppr_qualifiers_tbl
                                                            , x_qualifiers_val_tbl           => ppr_qualifiers_val_tbl
                                                            , x_pricing_attr_tbl             => ppr_pricing_attr_tbl
                                                            , x_pricing_attr_val_tbl         => ppr_pricing_attr_val_tbl
                                                            );
                   EXCEPTION
                      WHEN OTHERS THEN
                      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error inHeader API ');
                   END;
                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Return Status ' || gpr_return_status );

                   IF gpr_return_status IN ( 'E', 'U' )
                   THEN
                      ---*********----------
                      gpr_msg_data  := '';
                      gpr_msg_data2 := '';
                      --x_grp_error   := x_grp_error + 1;
                      --x_error_record:= x_error_record + 1;
                      ---*********----------
                      fnd_file.put_line(fnd_file.log,'Error Msg Hdr... =>' || gpr_msg_data );

                      FOR k IN 1 .. gpr_msg_count
                      LOOP
                         gpr_msg_data := oe_msg_pub.get ( p_msg_index => k, p_encoded => 'F' );
                         gpr_msg_data2 := gpr_msg_data2 || LTRIM ( RTRIM ( gpr_msg_data ));
                         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error Msg... =>' || gpr_msg_data );
                         fnd_file.put_line(fnd_file.log,'Error Msg Hdr... =>' || gpr_msg_data );
                      END LOOP;

                      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error Msg..... =>' || gpr_msg_data2 );
                      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                      ROLLBACK;
                      xx_emf_pkg.error ( p_severity                 => xx_emf_cn_pkg.cn_medium
                                       , p_category                 => xx_emf_cn_pkg.cn_stg_apicall
                                       , p_error_text               => gpr_msg_data2
                                --       , p_record_identifier_1      => xx_qp_hdrs_tbl_type ( l_header_index ).NAME
                                       , p_record_identifier_2      => l_orig_sys_header_ref
                                       --, p_record_identifier_3      => cur_rec.orig_sys_line_ref
                                       );
                      mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                -- , xx_qp_hdrs_tbl_type ( l_header_index ).NAME
                                                 , l_orig_sys_header_ref
                                               --  , cur_rec.orig_sys_line_ref
                                                   , NULL
                                                   , NULL
                                                 , SUBSTR ( gpr_msg_data2, 1, 1000 )
                                                 );
                     x_hdr_err_flag := 'Y';
                     -- ROLLBACK;
                   ELSE
                      fnd_file.put_line(fnd_file.log,'Header Success' );
                      l_list_header_id := NULL;
                      SELECT a.list_header_id
                      INTO l_list_header_id
                      FROM qp_list_headers_b a, qp_list_headers_tl b
                      where
                      a.list_header_id=b.list_header_id
                      and b.name=xx_qp_hdrs_tbl_type ( l_header_index ).NAME
                      AND a.list_type_code = 'PRL'
                      and language=USERENV('LANG')
                      ;
                      ----uncommented by  to get list header id of newly created QP--
                      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'l_list_header_id'||l_list_header_id);


                      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                           ,    'Price List Creation => Success For Price List'
                                             || xx_qp_hdrs_tbl_type ( l_header_index ).NAME
                                             || '-'
                                             || l_orig_sys_header_ref
                                             --|| ' l_orig_sys_line_ref '
                                             --|| cur_rec.orig_sys_line_ref
                                           );
                      ----------********************-------------
                         x_success_header := x_success_header + 1;
--                         x_grp_success    := x_grp_success + 1;
                      ----------********************-------------

                   END IF;

               EXCEPTION
                  WHEN fnd_api.g_exc_unexpected_error
                  THEN
                     gpr_return_status := fnd_api.g_ret_sts_unexp_error;

                     FOR i IN 1 .. gpr_msg_count
                     LOOP
                        oe_msg_pub.get ( p_msg_index          => i
                                       , p_encoded            => fnd_api.g_false
                                       , p_data               => gpr_msg_data
                                       , p_msg_index_out      => gpr_msg_count
                                       );
                     END LOOP;
                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Err Msg ' || gpr_msg_data );
                     xx_emf_pkg.error (p_severity            => xx_emf_cn_pkg.CN_MEDIUM
                                ,p_category            => xx_emf_cn_pkg.CN_STG_APICALL
                                ,p_error_text          => gpr_msg_data2
                            --    ,p_record_identifier_1 => xx_qp_hdrs_tbl_type (l_header_index).NAME
                                ,p_record_identifier_2 => l_orig_sys_header_ref
                               -- ,p_record_identifier_3 => cur_rec.orig_sys_line_ref
                      );
                  --Update the inerface table with 'ERROR" status. Reprocess program will change the flag to Y
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  ROLLBACK;
               END;


               ---End Of Creating Price List Header


               --END IF; --droy uncomment afterwards --DROY DELETE IF PART


               DECLARE

                  gpr_price_list_rec            qp_price_list_pub.price_list_rec_type;
                  gpr_price_list_val_rec        qp_price_list_pub.price_list_val_rec_type;
                  gpr_price_list_line_tbl       qp_price_list_pub.price_list_line_tbl_type;
                  gpr_price_list_line_val_tbl   qp_price_list_pub.price_list_line_val_tbl_type;
                  gpr_qualifiers_tbl            qp_qualifier_rules_pub.qualifiers_tbl_type;
                  gpr_qualifiers_val_tbl        qp_qualifier_rules_pub.qualifiers_val_tbl_type;
                  gpr_pricing_attr_tbl          qp_price_list_pub.pricing_attr_tbl_type;
                  gpr_pricing_attr_val_tbl      qp_price_list_pub.pricing_attr_val_tbl_type;
                  ppr_price_list_rec            qp_price_list_pub.price_list_rec_type;
                  ppr_price_list_val_rec        qp_price_list_pub.price_list_val_rec_type;
                  ppr_price_list_line_tbl       qp_price_list_pub.price_list_line_tbl_type;
                  ppr_price_list_line_val_tbl   qp_price_list_pub.price_list_line_val_tbl_type;
                  ppr_qualifier_rules_rec       qp_qualifier_rules_pub.qualifier_rules_rec_type;
                  ppr_qualifier_rules_val_rec   qp_qualifier_rules_pub.qualifier_rules_val_rec_type;
                  ppr_qualifiers_tbl            qp_qualifier_rules_pub.qualifiers_tbl_type;
                  ppr_qualifiers_val_tbl        qp_qualifier_rules_pub.qualifiers_val_tbl_type;
                  ppr_pricing_attr_tbl          qp_price_list_pub.pricing_attr_tbl_type;
                  ppr_pricing_attr_val_tbl      qp_price_list_pub.pricing_attr_val_tbl_type;


                  BEGIN



                     --Process the logical group of line records for the price list header
                     IF l_list_header_id IS NOT NULL AND xx_qp_hdrs_tbl_type ( l_header_index ).custom_lines_count >0
                     THEN
                     --xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Inside Line Level IF condition'||p_header_line );
                     /*FOR cur_rec IN csr_list_lines_group ( nvl(l_list_header_id, xx_qp_hdrs_tbl_type ( l_header_index ).list_header_id)
                                                         ,xx_qp_hdrs_tbl_type ( l_header_index ).orig_sys_header_ref
                                                         )
                     LOOP
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                             ,    'Entering loop debug Deb'
                                             );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                             ,    'Deb Rowcount - '||csr_list_lines_group%ROWCOUNT
                                             );
                     */
                        --FETCH csr_list_lines_group INTO l_orig_sys_line_ref;
                        --CLOSE csr_list_lines_group;
                          -- Set the Price List line data
                          --Selecting line data
                           ----------********************-------------
                           x_total_record := x_total_record + 1;
                           ----------********************-------------


                        l_pricing_attr_index :=0;
                        l_list_line_count    :=0;
                        l_list_attr_count    :=0;
                        b_list_line_count    :=0;
                        b_list_attr_count    :=0;
                        /*xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                             ,    'IN csr_list_lines_group LOOP: l_orig_sys_line_ref '
                                               || cur_rec.orig_sys_line_ref
                                               ||' list_header_id '
                                               --|| xx_qp_hdrs_tbl_type ( l_header_index ).list_header_id
                                               ||' NAME '
                                               || xx_qp_hdrs_tbl_type ( l_header_index ).NAME
                                             );*/

                        x_line_limit := xx_qp_hdrs_tbl_type ( l_header_index ).custom_lines_count;


                        OPEN csr_list_lines (  xx_qp_hdrs_tbl_type ( l_header_index ).orig_sys_header_ref
                                             );

                          --xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Loop count xyx'||cur_rec.orig_sys_line_ref);
                        FETCH csr_list_lines
                        BULK COLLECT INTO xx_qp_lines_tbl_type;-- LIMIT x_line_limit;

                        CLOSE csr_list_lines;
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low  ,    'Test3delete' );
                        ------------*********************-----------------------
                        x_grp_total    := x_grp_total + xx_qp_lines_tbl_type.COUNT;
                        x_success_temp :=0;
                        x_success_temp := xx_qp_lines_tbl_type.COUNT;
                        ------------*********************-----------------------


                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1');
                        IF xx_qp_lines_tbl_type.COUNT > 0
                        THEN
                            l_pricing_attr_index :=0;
                            l_list_line_count    :=0;
                            l_list_attr_count    :=0;
                            b_list_line_count    :=0;
                            b_list_attr_count    :=0;
                            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                                 ,    'Fetching Price List lines at a time '
                                                   || xx_qp_lines_tbl_type.COUNT
                                                   || ' records'
                                                 );

                            --Process
                            /*FOR i IN xx_qp_lines_tbl_type.FIRST .. xx_qp_lines_tbl_type.LAST-1
                            LOOP*/
                            FOR i IN 1 .. xx_qp_lines_tbl_type.COUNT
                            LOOP



                               l_lpr_line_index := i;   -- + l_line_bulk_index;
                               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                                    ,    'l_lpr_line_index>>'
                                                      || l_lpr_line_index
                                                      || ' i>>'
                                                      || i
                                                      || ' l_line_bulk_index>>'
                                                      || l_line_bulk_index
                                                    );
                               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                                    ,    'From LINE Cursor:::product_attribute_context '
                                                      || xx_qp_lines_tbl_type ( i ).product_attribute_context
                                                      || ' product_attribute  '
                                                      || xx_qp_lines_tbl_type ( i ).product_attribute
                                                      || ' product_attr_value '
                                                      || xx_qp_lines_tbl_type ( i ).product_attr_value
                                                      || ' product_uom_code   '
                                                      || xx_qp_lines_tbl_type ( i ).product_uom_code
                                                    );
                               ----
                               -- Need to flush before assign--
                               --gpr_price_list_line_tbl.DELETE;
                               gpr_price_list_line_tbl ( l_lpr_line_index ).list_header_id := l_list_header_id;
                                              --nvl(l_list_header_id, xx_qp_hdrs_tbl_type ( l_header_index ).list_header_id); --DROY EXAMINE
                               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.1');


                               IF ( xx_qp_lines_tbl_type ( i ).price_break_type_code IN ( 'POINT', 'RANGE' ))
                               THEN
                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'When price break type code POINT or RANGE' );

                                  IF ( xx_qp_lines_tbl_type ( i ).list_line_type_code = 'PBH' )
                                  THEN
                                     l_price_break_index := i;
                                  END IF;

                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                                       ,    'l_lpr_line_index>>'
                                                         || l_lpr_line_index
                                                         || ' i>>'
                                                         || i
                                                         || ' record number >>'
                                                         || xx_qp_lines_tbl_type ( i ).record_number
                                                       );

                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                                          ,    'l_lpr_line_index>>'
                                                            || l_lpr_line_index
                                                            || ' i>>'
                                                            || i
                                                            || ' record number >>'
                                                            || xx_qp_lines_tbl_type ( i ).record_number
                                                          );
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                                          ,    'l_pricing_attr_index>>'
                                                            || l_pricing_attr_index
                                                            || ' k>>'
                                                            || k
                                                            || ' l_pricing_attr_index>>'
                                                            || l_pricing_attr_index
                                                          );
                                     gpr_price_list_line_tbl ( l_lpr_line_index ).list_line_id := fnd_api.g_miss_num;
                                     gpr_price_list_line_tbl ( l_lpr_line_index ).arithmetic_operator :=
                                                                              xx_qp_lines_tbl_type ( i ).arithmetic_operator;
                                     --gpr_price_list_line_tbl ( l_lpr_line_index ).attribute10:= xx_qp_lines_tbl_type ( i ).record_number;
                                     gpr_price_list_line_tbl ( l_lpr_line_index ).attribute10 := xx_qp_lines_tbl_type ( i ).orig_sys_line_ref;

                                     gpr_price_list_line_tbl( l_lpr_line_index ).request_id :=xx_emf_pkg.g_request_id;

                                     gpr_price_list_line_tbl( l_lpr_line_index ).ATTRIBUTE15 :=g_batch_id;


                                     gpr_price_list_line_tbl ( l_lpr_line_index ).end_date_active :=
                                                                              xx_qp_lines_tbl_type ( i ).end_date_active;
                                     gpr_price_list_line_tbl ( l_lpr_line_index ).start_date_active :=
                                                                            xx_qp_lines_tbl_type ( i ).start_date_active;
                                     gpr_price_list_line_tbl ( l_lpr_line_index ).list_line_type_code :=
                                                                              xx_qp_lines_tbl_type ( i ).list_line_type_code;

                                     /*IF(xx_qp_lines_tbl_type ( i ).list_line_type_code='PBH') THEN
                                       l_price_break_index:=i;
                                     END IF;*/
                                     IF ( xx_qp_lines_tbl_type ( i ).rltd_modifier_grp_type = 'PRICE BREAK' )
                                     THEN
                                        gpr_price_list_line_tbl ( l_lpr_line_index ).price_break_header_index :=
                                                                                                        l_price_break_index;

                                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'price_break_header_index'||
                                                            gpr_price_list_line_tbl ( l_lpr_line_index ).price_break_header_index);
                                     ELSE
                                        gpr_price_list_line_tbl ( l_lpr_line_index ).price_break_header_index := '';
                                     END IF;

                                     gpr_price_list_line_tbl ( l_lpr_line_index ).operand :=
                                                                                          xx_qp_lines_tbl_type ( i ).operand;
                                     gpr_price_list_line_tbl ( l_lpr_line_index ).price_break_type_code :=
                                                                            xx_qp_lines_tbl_type ( i ).price_break_type_code;
                                     gpr_price_list_line_tbl ( l_lpr_line_index ).rltd_modifier_grp_type :=
                                                                           xx_qp_lines_tbl_type ( i ).rltd_modifier_grp_type;
                                     gpr_price_list_line_tbl ( l_lpr_line_index ).rltd_modifier_group_no := 1;
                                     gpr_price_list_line_tbl ( l_lpr_line_index ).product_precedence :=
                                                                               xx_qp_lines_tbl_type ( i ).product_precedence;
                                     /*gpr_price_list_line_tbl ( l_lpr_line_index ).incompatibility_grp_code :=
                                                                               xx_qp_lines_tbl_type ( i ).incompatibility_grp_code;
                                     gpr_price_list_line_tbl ( l_lpr_line_index ).qualification_ind :=
                                                                               xx_qp_lines_tbl_type ( i ).qualification_ind;*/
                                     --  Primary UOM flag need to check , when there is value on that column--
                                     gpr_price_list_line_tbl ( l_lpr_line_index ).primary_uom_flag := xx_qp_lines_tbl_type ( i ).primary_uom_flag;
                                     gpr_price_list_line_tbl ( l_lpr_line_index ).operation := qp_globals.g_opr_create;
                                     ------
                                     l_pricing_attr_index := l_pricing_attr_index + 1;

                                     gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attribute_id :=
                                                                                                          fnd_api.g_miss_num;
                                     gpr_pricing_attr_tbl ( l_pricing_attr_index ).excluder_flag := 'N';
                                     gpr_pricing_attr_tbl ( l_pricing_attr_index ).list_line_id := fnd_api.g_miss_num;
                                     gpr_pricing_attr_tbl ( l_pricing_attr_index ).price_list_line_index := l_lpr_line_index;
                                      /* to identify the attrbute which goes into tbl*/
                                     gpr_pricing_attr_tbl ( l_pricing_attr_index ).attribute10 := xx_qp_lines_tbl_type ( i ).orig_sys_line_ref;
                                     gpr_pricing_attr_tbl( l_pricing_attr_index ).request_id :=xx_emf_pkg.g_request_id;
                                     gpr_pricing_attr_tbl( l_pricing_attr_index ).ATTRIBUTE15 :=g_batch_id;
                                     gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attribute :=
                                                                                xx_qp_lines_tbl_type ( i ).pricing_attribute;
                                     gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attribute_context :=
                                                                        xx_qp_lines_tbl_type ( i ).pricing_attribute_context;
                                     gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attr_value_from :=
                                                                          UPPER(xx_qp_lines_tbl_type ( i ).pricing_attr_value_from);
                                     gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attr_value_to :=
                                                                            xx_qp_lines_tbl_type ( i ).pricing_attr_value_to;
                                     gpr_pricing_attr_tbl ( l_pricing_attr_index ).comparison_operator_code :=
                                                                         xx_qp_lines_tbl_type ( i ).comparison_operator_code;
                                     gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attribute :=
                                                                                xx_qp_lines_tbl_type ( i ).product_attribute;
                                     gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attribute_context :=
                                                                        xx_qp_lines_tbl_type ( i ).product_attribute_context;
                                     gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attr_value :=
                                                                               xx_qp_lines_tbl_type ( i ).product_attr_value;
                                     gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_uom_code :=
                                                                                 xx_qp_lines_tbl_type ( i ).product_uom_code;
                                     gpr_pricing_attr_tbl ( l_pricing_attr_index ).operation := qp_globals.g_opr_create;
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.4.4');

                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'pricing_attribute_id'||
                                                            gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attribute_id);
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'list_line_id'||
                                                            gpr_pricing_attr_tbl ( l_pricing_attr_index ).list_line_id);
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'operation'||
                                                            gpr_pricing_attr_tbl ( l_pricing_attr_index ).operation);
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'price_list_line_index'||
                                                            gpr_pricing_attr_tbl ( l_pricing_attr_index ).price_list_line_index);
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'pricing_attribute'||
                                                            gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attribute);
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'pricing_attribute_context'||
                                                            gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attribute_context);
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'pricing_attr_value_from'||
                                                            gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attr_value_from);
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'pricing_attr_value_to'||
                                                            gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attr_value_to);
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'comparison_operator_code'||
                                                            gpr_pricing_attr_tbl ( l_pricing_attr_index ).comparison_operator_code);
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'product_attribute'||
                                                            gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attribute);
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'product_attribute_context'||
                                                            gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attribute_context);
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'product_attr_value'||
                                                            gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attr_value);
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'product_uom_code'||
                                                            gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_uom_code);
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'price_break_header_index'||
                                                            gpr_price_list_line_tbl ( l_lpr_line_index ).price_break_header_index);
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'test 2....' );
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'l_pricing_attr_index'|| l_pricing_attr_index);

                               ELSE
                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                                       ,    'entering else part....l_lpr_line_index '
                                                         || l_lpr_line_index
                                                         || 'l_pricing_attr_index '
                                                         || l_pricing_attr_index
                                                         || ' i '
                                                         || i
                                                       );
                                  l_pricing_attr_index := l_pricing_attr_index + 1; -- commented to initialize 0
                                  gpr_price_list_line_tbl ( l_lpr_line_index ).list_line_id := fnd_api.g_miss_num;
                                  gpr_price_list_line_tbl ( l_lpr_line_index ).list_header_id := l_list_header_id;
                                  gpr_price_list_line_tbl ( l_lpr_line_index ).arithmetic_operator :=
                                                                              xx_qp_lines_tbl_type ( i ).arithmetic_operator;
                                  --gpr_price_list_line_tbl ( l_lpr_line_index ).attribute10                 := xx_qp_lines_tbl_type ( i ).record_number;
                                  gpr_price_list_line_tbl ( l_lpr_line_index ).attribute10 := xx_qp_lines_tbl_type ( i ).orig_sys_line_ref;
                                  gpr_price_list_line_tbl( l_lpr_line_index ).ATTRIBUTE15 :=g_batch_id;
                                  gpr_price_list_line_tbl( l_lpr_line_index ).request_id :=xx_emf_pkg.g_request_id;
                                  gpr_price_list_line_tbl ( l_lpr_line_index ).end_date_active :=
                                                                              xx_qp_lines_tbl_type ( i ).end_date_active;
                                  gpr_price_list_line_tbl ( l_lpr_line_index ).start_date_active :=
                                                                            xx_qp_lines_tbl_type ( i ).start_date_active;
                                  gpr_price_list_line_tbl ( l_lpr_line_index ).product_precedence :=
                                                                               xx_qp_lines_tbl_type ( i ).product_precedence; --Added on 19 July
                                  gpr_price_list_line_tbl ( l_lpr_line_index ).primary_uom_flag :=
                                                                               xx_qp_lines_tbl_type ( i ).primary_uom_flag; --Added on 19 July
                                  /*gpr_price_list_line_tbl ( l_lpr_line_index ).incompatibility_grp_code :=
                                                                               xx_qp_lines_tbl_type ( i ).incompatibility_grp_code;
                                  gpr_price_list_line_tbl ( l_lpr_line_index ).accumulate_flag :=
                                                                               xx_qp_lines_tbl_type ( i ).accumulate_flag;
                                  gpr_price_list_line_tbl ( l_lpr_line_index ).qualification_ind :=
                                                                               xx_qp_lines_tbl_type ( i ).qualification_ind;*/
                                  gpr_price_list_line_tbl ( l_lpr_line_index ).list_line_type_code :=
                                                                              xx_qp_lines_tbl_type ( i ).list_line_type_code;
                                  gpr_price_list_line_tbl ( l_lpr_line_index ).list_price :=
                                                                                          xx_qp_lines_tbl_type ( i ).operand;
                                  gpr_price_list_line_tbl ( l_lpr_line_index ).operand := xx_qp_lines_tbl_type ( i ).operand;
                                  gpr_price_list_line_tbl ( l_lpr_line_index ).price_break_type_code :=
                                                                            xx_qp_lines_tbl_type ( i ).price_break_type_code;
                                  gpr_price_list_line_tbl ( l_lpr_line_index ).operation := qp_globals.g_opr_create;

                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.4.6');

                                  gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attribute_id := fnd_api.g_miss_num;
                                  gpr_pricing_attr_tbl ( l_pricing_attr_index ).list_line_id := fnd_api.g_miss_num;
                                  /* to identify the attrbute which goes into tbl*/
                                  gpr_pricing_attr_tbl ( l_pricing_attr_index ).attribute10 := xx_qp_lines_tbl_type ( i ).orig_sys_line_ref;
                                  gpr_pricing_attr_tbl( l_pricing_attr_index ).request_id :=xx_emf_pkg.g_request_id;
                                  gpr_pricing_attr_tbl( l_pricing_attr_index ).ATTRIBUTE15 :=g_batch_id;
                                  gpr_pricing_attr_tbl ( l_pricing_attr_index ).operation := qp_globals.g_opr_create;
                                  gpr_pricing_attr_tbl ( l_pricing_attr_index ).price_list_line_index := l_lpr_line_index;
                                  gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attribute :=
                                                                                xx_qp_lines_tbl_type ( i ).pricing_attribute;
                                  gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attribute_context :=
                                                                        xx_qp_lines_tbl_type ( i ).pricing_attribute_context;
                                  gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attr_value_from :=
                                                                          UPPER(xx_qp_lines_tbl_type ( i ).pricing_attr_value_from);
                                  gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attr_value_to :=
                                                                            xx_qp_lines_tbl_type ( i ).pricing_attr_value_to;
                                  gpr_pricing_attr_tbl ( l_pricing_attr_index ).comparison_operator_code :=
                                                                         xx_qp_lines_tbl_type ( i ).comparison_operator_code;
                                  gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attribute :=
                                                                                xx_qp_lines_tbl_type ( i ).product_attribute;
                                  gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attribute_context :=
                                                                        xx_qp_lines_tbl_type ( i ).product_attribute_context;
                                  gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attr_value :=
                                                                               xx_qp_lines_tbl_type ( i ).product_attr_value;
                                  gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_uom_code :=
                                                                                 xx_qp_lines_tbl_type ( i ).product_uom_code;


                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'l_pricing_attr_index'|| l_pricing_attr_index);
                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'pricing_attribute_id'||
                                                         gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attribute_id);
                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'list_line_id'||
                                                         gpr_pricing_attr_tbl ( l_pricing_attr_index ).list_line_id);
                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'operation'||
                                                         gpr_pricing_attr_tbl ( l_pricing_attr_index ).operation);
                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'price_list_line_index'||
                                                         gpr_pricing_attr_tbl ( l_pricing_attr_index ).price_list_line_index);
                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'pricing_attribute'||
                                                         gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attribute);
                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'pricing_attribute_context'||
                                                         gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attribute_context);
                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'pricing_attr_value_from'||
                                                         gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attr_value_from);
                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'pricing_attr_value_to'||
                                                         gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attr_value_to);
                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'comparison_operator_code'||
                                                         gpr_pricing_attr_tbl ( l_pricing_attr_index ).comparison_operator_code);
                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'product_attribute'||
                                                         gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attribute);
                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'product_attribute_context'||
                                                         gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attribute_context);
                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'product_attr_value'||
                                                         gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attr_value);
                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'product_uom_code'||
                                                         gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_uom_code);
                                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'test 4....' );

                               END IF;

                               l_list_line_count    :=l_lpr_line_index;
                               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'inside line loop>>l_list_line_count '||l_list_line_count );
                               l_list_attr_count    :=l_pricing_attr_index;
                               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'inside line loop>>l_pricing_attr_index '||l_pricing_attr_index );
                               END LOOP;   --end of line loop
                               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'lINE lOOP COMPLETE' );
                        /*ELSE
                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'No lines to fetch' );
                           EXIT; */
                        END IF;

                        --l_line_bulk_index := l_line_bulk_index + 1000;
                        -- Line attributes data selection end


                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After Line loop chk qualifier' );
                        --xx_qlf_pre_tab_type.DELETE;

                        /*oe_debug_pub.initialize;

                        oe_debug_pub.setdebuglevel(5);

                        oe_debug_pub.add('Add your debug message here');*/


                        IF gpr_price_list_line_tbl.COUNT > 0
                        THEN
                        BEGIN
                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Calling api to create pricelist Line' );
                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'IN API CALL l_list_line_count'||l_lpr_line_index );
                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'IN API CALL l_pricing_attr_index'||l_pricing_attr_index );
                           fnd_msg_pub.initialize;
                           BEGIN
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.5');
                              qp_price_list_pub.process_price_list ( p_api_version_number           => 1
                                                                   , p_init_msg_list                => fnd_api.g_true
                                                                   , p_return_values                => fnd_api.g_false
                                                                   , p_commit                       => fnd_api.g_false
                                                                   , x_return_status                => gpr_return_status
                                                                   , x_msg_count                    => gpr_msg_count
                                                                   , x_msg_data                     => gpr_msg_data
                                                                   , p_price_list_rec               => gpr_price_list_rec
                                                                   , p_price_list_line_tbl          => gpr_price_list_line_tbl
                                                                   , p_qualifiers_tbl               => gpr_qualifiers_tbl
                                                                   , p_pricing_attr_tbl             => gpr_pricing_attr_tbl
                                                                   , x_price_list_rec               => ppr_price_list_rec
                                                                   , x_price_list_val_rec           => ppr_price_list_val_rec
                                                                   , x_price_list_line_tbl          => ppr_price_list_line_tbl
                                                                   , x_price_list_line_val_tbl      => ppr_price_list_line_val_tbl
                                                                   , x_qualifiers_tbl               => ppr_qualifiers_tbl
                                                                   , x_qualifiers_val_tbl           => ppr_qualifiers_val_tbl
                                                                   , x_pricing_attr_tbl             => ppr_pricing_attr_tbl
                                                                   , x_pricing_attr_val_tbl         => ppr_pricing_attr_val_tbl
                                                                  );
                              -- Need to flush before assign--
                              gpr_price_list_line_tbl.DELETE;
                              gpr_pricing_attr_tbl.DELETE;

                           EXCEPTION
                              WHEN OTHERS THEN
                              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                              ROLLBACK;
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error in Line API ');
                           END;
                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'API Return Status ' || gpr_return_status );

                           IF gpr_return_status IN ( 'E', 'U' )
                           THEN
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.6');
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error Status ' || gpr_return_status );

                              ---*********----------
                                gpr_msg_data  := '';
                                gpr_msg_data2 := '';
                                x_grp_error   := x_grp_error + x_success_temp;
                                x_error_record:= x_error_record + 1;
                              ---*********----------

                              FOR k IN 1 .. gpr_msg_count
                              LOOP
                                 gpr_msg_data := substr(oe_msg_pub.get ( p_msg_index => k, p_encoded => 'F' ),1,160);
                                 gpr_msg_data2 := substr(gpr_msg_data2 || LTRIM ( RTRIM ( gpr_msg_data )),1,200);
                                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error Msg... =>' || gpr_msg_data );
                                 fnd_file.put_line(fnd_file.log,'Error Msg... =>' || gpr_msg_data );
                              END LOOP;

                              mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                         -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                         , l_orig_sys_header_ref
                                                         , NULL
                                                         , NULL
                                                         , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                         );

                              --xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error Msg..... =>' || gpr_msg_data2 );
                              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                              --ROLLBACK;--debdan
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.6.0');
                              xx_emf_pkg.error ( p_severity                 => xx_emf_cn_pkg.cn_medium
                                               , p_category                 => xx_emf_cn_pkg.cn_stg_apicall
                                               --, p_error_text               => gpr_msg_data2
                                               , p_error_text               =>gpr_msg_data
                                              -- , p_record_identifier_1      => cur_rec.name--xx_qp_hdrs_tbl_type ( l_header_index ).NAME --DROY MESSAGE UNIFORMITY
                                               , p_record_identifier_2      => l_orig_sys_header_ref
                                               , p_record_identifier_3      => xx_qp_lines_tbl_type (l_lpr_line_index).orig_sys_line_ref
                                               );
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.6.1');
                              IF ppr_price_list_line_tbl.count > 0 THEN
                                 FOR k in 1 .. ppr_price_list_line_tbl.count LOOP

                                    IF ppr_price_list_line_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                       xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One or more Pricelist Line Creation Failed' );
                                       mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                         -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                         , l_orig_sys_header_ref
                                                         , xx_qp_lines_tbl_type (k).orig_sys_line_ref
                                                         , NULL
                                                         , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                         );
                                       x_line_err_flag := 'Y';
                                    END IF;

                                 END LOOP;
                                 IF NVL(x_line_err_flag,'X') <> 'Y' THEN
                                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Successful Pricelist Line Creation' );
                                 END IF;
                              END IF;

                              IF ppr_pricing_attr_tbl.count > 0 THEN
                                  FOR k in 1 .. ppr_pricing_attr_tbl.count LOOP

                                     IF ppr_pricing_attr_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One or more Pricelist Attribute Creation Failed' );
                                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'k '||k );
                                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'ppr_pricing_attr_tbl (k).attribute10 '||ppr_pricing_attr_tbl (k).attribute10 );
                                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'l_orig_sys_header_ref '||l_orig_sys_header_ref );
                                        mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                         -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                         , l_orig_sys_header_ref
                                                         , ppr_pricing_attr_tbl (k).attribute10
                                                         , NULL
                                                         , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                         );
                                        x_attr_err_flag := 'Y';
                                     END IF;
                                  END LOOP;

                                  IF NVL(x_attr_err_flag,'X') <> 'Y' THEN
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Successful PriceList Attrubute Creation' );
                                  END IF;
                              END IF;

                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.7');
                              x_line_err_flag := 'Y';
                           ELSE
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.8');
                              --fnd_file.put_line(fnd_file.log,'Success');
                              --COMMIT;--DROY UNCOMMENT LATER ON
                              --COMMIT;
                              --ROLLBACK;
                              IF ppr_price_list_line_tbl.count > 0 THEN
                                 FOR k in 1 .. ppr_price_list_line_tbl.count LOOP

                                    IF ppr_price_list_line_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                       xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One or more Pricelist Line Creation Failed' );
                                       mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                         -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                         , l_orig_sys_header_ref
                                                         , xx_qp_lines_tbl_type (k).orig_sys_line_ref
                                                         , NULL
                                                         , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                         );
                                       x_line_err_flag := 'Y';
                                    END IF;

                                 END LOOP;
                                 IF NVL(x_line_err_flag,'X') <> 'Y' THEN
                                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Successful Pricelist Line Creation' );
                                 END IF;
                              END IF;

                              IF ppr_qualifiers_tbl.count > 0 THEN
                                 FOR k in 1 .. ppr_qualifiers_tbl.count LOOP

                                    IF ppr_qualifiers_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                       xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One or more Pricelist Qualifier Creation Failed' );
                                       x_qlf_err_flag := 'Y';
                                    END IF;

                                 END LOOP;
                                 IF NVL(x_qlf_err_flag,'X') <> 'Y' THEN
                                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Successful PriceList Qualifier Creation' );
                                 END IF;
                              END IF;

                              IF ppr_pricing_attr_tbl.count > 0 THEN
                                  FOR k in 1 .. ppr_pricing_attr_tbl.count LOOP

                                     IF ppr_pricing_attr_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One or more Pricelist Attribute Creation Failed' );
                                        mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                         -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                         , l_orig_sys_header_ref
                                                         , xx_qp_lines_tbl_type (k).orig_sys_line_ref
                                                         , NULL
                                                         , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                         );
                                        x_attr_err_flag := 'Y';
                                     END IF;
                                  END LOOP;

                                  IF NVL(x_attr_err_flag,'X') <> 'Y' THEN
                                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Successful PriceList Attrubute Creation' );
                                  END IF;
                              END IF;

                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.201');


                              /*UPDATE xx_qp_price_list_pre --DROY ADD LINES
			                        SET process_code = xx_emf_cn_pkg.cn_process_data
			                            , error_code = xx_emf_cn_pkg.cn_success
			                        WHERE 1 = 1
			                          AND request_id = xx_emf_pkg.g_request_id
			                          AND process_code IN (xx_emf_cn_pkg.cn_process_data,xx_emf_cn_pkg.cn_postval)
			                          AND error_code IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
			                          AND name = xx_qp_hdrs_tbl_type ( l_header_index ).NAME
                                                  AND orig_sys_line_ref = cur_rec.orig_sys_line_ref;*/ --DROY
                                        -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'Update Pre table After Success'||cur_rec.orig_sys_line_ref);



                           END IF;
                           --Update the interface table with 'COMPLETE" status
                        EXCEPTION
                           WHEN fnd_api.g_exc_unexpected_error
                           THEN
                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.10');
                              gpr_return_status := fnd_api.g_ret_sts_unexp_error;
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                                ,    'Err Msg For unexpected_error'||gpr_return_status
                                   );

                              /*FOR i IN 1 .. gpr_msg_count
                              LOOP
                                 oe_msg_pub.get ( p_msg_index          => i
                                                , p_encoded            => fnd_api.g_false
                                                , p_data               => gpr_msg_data
                                                , p_msg_index_out      => gpr_msg_count
                                                );
                              END LOOP;
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Err Msg ' || gpr_msg_data );
                              xx_emf_pkg.error   (p_severity            => xx_emf_cn_pkg.CN_MEDIUM
                             ,p_category            => xx_emf_cn_pkg.CN_STG_APICALL
                             ,p_error_text          => gpr_msg_data2
                            -- ,p_record_identifier_1 => xx_qp_hdrs_tbl_type (l_header_index).name
                             ,p_record_identifier_2 => l_orig_sys_header_ref
                             ,p_record_identifier_3 => xx_qp_lines_tbl_type ( i ).orig_sys_line_ref
                               );*/
                           --Update the inerface table with 'ERROR" status. Reprocess program will change the flag to Y
                            WHEN Others
                           THEN
                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'Others errpr DEBUG MESSAGE 1.101');
                              --gpr_return_status := fnd_api.g_ret_sts_unexp_error;
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                                ,    'Err Msg For unexpected_error'||sqlerrm
                                   );
                           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                           --ROLLBACK;
                        END;
                        END IF ;--IF gpr_price_list_line_tbl.COUNT > 0
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.202');
                        -- one List Line group completed
                     --END LOOP;
                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.203');
                     --COMMIT;
                END IF;--DROY CHK IF FOR COMMENTS
                -- End if p_header_line = 'Y' ----
               END;
               IF x_hdr_err_flag  = 'Y'
                OR  x_line_err_flag = 'Y'
                OR x_attr_err_flag = 'Y'
                OR x_qlf_err_flag = 'Y'
                OR x_sec_err_flag = 'Y' THEN

                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                   ,    'x_hdr_err_flag:' ||x_hdr_err_flag
                      );
                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                   ,    'x_line_err_flag:' ||x_line_err_flag
                      );
                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                   ,    'x_attr_err_flag:' ||x_attr_err_flag
                      );
                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                   ,    'x_qlf_err_flag:' ||x_qlf_err_flag
                      );

                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                   ,    'x_sec_err_flag:' ||x_sec_err_flag
                      );

                  ROLLBACK;
                  /*mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                              -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                               , l_orig_sys_header_ref
                                              -- , cur_rec.orig_sys_line_ref
                                               --, SUBSTR ( gpr_msg_data2, 1, 1000 )
                                               , SUBSTR ( gpr_msg_data, 1, 1000 )
                                               );*/
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                   ,    'Rollback Pricelist for Orig Sys:' ||l_orig_sys_header_ref
                      );
               ELSE
                  COMMIT;
                  --ROLLBACK;
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                           ,    'Commit Pricelist for Orig Sys:' ||l_orig_sys_header_ref
                              );
               END IF;
               --One price list header completed. Fetch the next one


            END LOOP; --FOR l_header_index IN xx_qp_hdrs_tbl_type.FIRST .. xx_qp_hdrs_tbl_type.LAST
         END IF; --IF xx_qp_hdrs_tbl_type.COUNT = 0
         --RETURN x_error_code;
         /*  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                              ,    'Processing Completed for current set of Primary Price List, Current Time:'
                                || TO_CHAR ( SYSDATE, 'DD-MON-YYYY  HH:MI:SS' )
                              );
        -- Save all changes..COMMIT is used to increase performence and reduce snapshot related error
        --COMMIT;*/
       -- END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                              , 'Unexpected error occured in Child Primary Price List API Program  ' || SQLCODE
                                || SQLERRM
                              );
         ROLLBACK;
         --RETURN x_error_code;
   END process_data_insert_mode;

   FUNCTION process_data_update_mode (
      /*p_header_line      IN   VARCHAR2
     ,*/p_list_header_id   IN   NUMBER
   )
      RETURN NUMBER
   IS
      x_error_code   NUMBER := 0;
   BEGIN
      RETURN x_error_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN x_error_code;
   END process_data_update_mode;

   -- END RESTRICTIONS
   PROCEDURE main (
      errbuf                  OUT      VARCHAR2
    , retcode                 OUT      VARCHAR2
    , p_batch_id              IN       VARCHAR2
    , p_restart_flag          IN       VARCHAR2
    , p_override_flag         IN       VARCHAR2
    , p_validate_and_load     IN       VARCHAR2
   )
   IS
      x_error_code          NUMBER                  := xx_emf_cn_pkg.cn_success;
      x_error_code_temp     NUMBER                  := xx_emf_cn_pkg.cn_success;
      x_pre_std_hdr_table   G_XX_QP_PL_HDR_PRE_TAB_TYPE;
      x_pre_std_lines_table   G_XX_QP_PL_LINES_PRE_TAB_TYPE;
      x_pre_std_hdr_qlf_table G_XX_QP_PL_QLF_PRE_TAB_TYPE;


      -- CURSOR FOR VARIOUS STAGES
      CURSOR c_xx_asl_pre_std_hdr (
         cp_process_status   VARCHAR2
      )
      IS
         SELECT   *
             FROM xx_qp_pr_list_hdr_pre hdr
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
         ORDER BY record_number;

     -- CURSOR FOR VARIOUS STAGES
      CURSOR c_xx_asl_pre_std_lines (
         cp_process_status   VARCHAR2
      )
      IS
         SELECT   *
             FROM xx_qp_pr_list_lines_pre lines
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
         ORDER BY record_number;

      CURSOR c_xx_cnv_pre_std_qlf_hdr ( cp_process_status VARCHAR2) IS
        SELECT
            --
            -- Add Columns if you want
            --
               hdr.*
          FROM xx_qp_pr_list_qlf_pre hdr
         WHERE batch_id = G_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID
           AND process_code = cp_process_status
           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         ORDER BY record_number;



      PROCEDURE update_record_status (
         p_conv_pre_std_hdr_rec   IN OUT   G_XX_QP_PL_HDR_PRE_REC_TYPE%ROWTYPE
       , p_error_code             IN       VARCHAR2
      )
      IS
      BEGIN
         IF p_error_code IN ( xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err )
         THEN
            p_conv_pre_std_hdr_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            p_conv_pre_std_hdr_rec.ERROR_CODE :=
               xx_qp_prc_list_cnv_val_pkg.find_max ( p_error_code
                                                     , NVL ( p_conv_pre_std_hdr_rec.ERROR_CODE
                                                           , xx_emf_cn_pkg.cn_success )
                                                     );
         END IF;

         p_conv_pre_std_hdr_rec.process_code := g_stage;
      END update_record_status;

      PROCEDURE update_record_status (
         p_conv_pre_std_lines_rec   IN OUT   G_XX_QP_PL_LINES_PRE_REC_TYPE%ROWTYPE
       , p_error_code             IN       VARCHAR2
      )
      IS
      BEGIN
         IF p_error_code IN ( xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err )
         THEN
            p_conv_pre_std_lines_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            p_conv_pre_std_lines_rec.ERROR_CODE :=
               xx_qp_prc_list_cnv_val_pkg.find_max ( p_error_code
                                                     , NVL ( p_conv_pre_std_lines_rec.ERROR_CODE
                                                           , xx_emf_cn_pkg.cn_success )
                                                     );
         END IF;

         p_conv_pre_std_lines_rec.process_code := g_stage;
      END update_record_status;

      /***************** For Qualifiers **************************/
        PROCEDURE update_record_status (
                p_conv_pre_std_hdr_rec  IN OUT  G_XX_QP_PL_QLF_PRE_REC_TYPE%ROWTYPE,
                p_error_code            IN      VARCHAR2
        )
        IS
        BEGIN
                IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
                THEN
                        p_conv_pre_std_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                ELSE
                        p_conv_pre_std_hdr_rec.ERROR_CODE :=
                        xx_qp_prc_list_cnv_val_pkg.find_max ( p_error_code
                                                     , NVL ( p_conv_pre_std_hdr_rec.ERROR_CODE
                                                           , xx_emf_cn_pkg.cn_success )
                                                     );
                END IF;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~Inside update_record_status For Qlf, G_STAGE=' || G_STAGE);
                p_conv_pre_std_hdr_rec.process_code := G_STAGE;
        END update_record_status;



      PROCEDURE mark_records_complete (
         p_process_code   VARCHAR2
      )
      IS
         x_last_update_date     DATE   := SYSDATE;
         x_last_update_by       NUMBER := fnd_global.user_id;
         x_last_updated_login   NUMBER := fnd_profile.VALUE ( xx_emf_cn_pkg.cn_login_id );
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         UPDATE xx_qp_pr_list_hdr_pre
            SET process_code = g_stage
              , ERROR_CODE = NVL ( ERROR_CODE, xx_emf_cn_pkg.cn_success )
              , last_updated_by = x_last_update_by
              , last_update_date = x_last_update_date
              , last_update_login = x_last_updated_login
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND process_code =
                   DECODE ( p_process_code
                          , xx_emf_cn_pkg.cn_process_data, xx_emf_cn_pkg.cn_postval
                          , xx_emf_cn_pkg.cn_derive
                          )
            AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn );


            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'No of Records Updated in PRC header=>' || g_stage||SQL%ROWCOUNT );

          UPDATE xx_qp_pr_list_lines_pre
            SET process_code = g_stage
              , ERROR_CODE = NVL ( ERROR_CODE, xx_emf_cn_pkg.cn_success )
              , last_updated_by = x_last_update_by
              , last_update_date = x_last_update_date
              , last_update_login = x_last_updated_login
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND process_code =
                   DECODE ( p_process_code
                          , xx_emf_cn_pkg.cn_process_data, xx_emf_cn_pkg.cn_postval
                          , xx_emf_cn_pkg.cn_derive
                          )
            AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn );

          xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'No of Records Updated in Lines Pre=>' || g_stage||SQL%ROWCOUNT );

           UPDATE xx_qp_pr_list_qlf_pre
                   SET process_code = G_STAGE,
                       error_code = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
                       last_updated_by = x_last_update_by,
                       last_update_date = x_last_update_date,
                       last_update_login = x_last_updated_login
                 WHERE batch_id = G_BATCH_ID
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
                   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

          xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'No of Records Updated in Qlf Pre=>' || g_stage||SQL%ROWCOUNT );




         COMMIT;
      END mark_records_complete;

      PROCEDURE update_pre_interface_records (
         p_cnv_pre_std_hdr_table   IN   G_XX_QP_PL_HDR_PRE_TAB_TYPE
      )
      IS
         x_last_update_date     DATE   := SYSDATE;
         x_last_update_by       NUMBER := fnd_global.user_id;
         x_last_updated_login   NUMBER := fnd_profile.VALUE ( xx_emf_cn_pkg.cn_login_id );
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         FOR indx IN 1 .. p_cnv_pre_std_hdr_table.COUNT
         LOOP
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                 ,    'p_cnv_pre_std_hdr_table(indx).process_code '
                                   || p_cnv_pre_std_hdr_table ( indx ).process_code
                                   || ' for record number '
                                   || p_cnv_pre_std_hdr_table ( indx ).record_number
                                   || ' Error Code is '
                                   || p_cnv_pre_std_hdr_table ( indx ).ERROR_CODE
                                 );
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                 ,    'p_cnv_pre_std_hdr_table(indx).error_code '
                                   || p_cnv_pre_std_hdr_table ( indx ).ERROR_CODE
                                 );

            UPDATE xx_qp_pr_list_hdr_pre
               SET active_flag = p_cnv_pre_std_hdr_table ( indx ).active_flag
                /* , hdr_attribute1 = p_cnv_pre_std_hdr_table ( indx ).hdr_attribute1
                 , hdr_attribute2 = p_cnv_pre_std_hdr_table ( indx ).hdr_attribute2
                 , hdr_attribute3 = p_cnv_pre_std_hdr_table ( indx ).hdr_attribute3
                 , hdr_attribute4 = p_cnv_pre_std_hdr_table ( indx ).hdr_attribute4
                 , hdr_attribute5 = p_cnv_pre_std_hdr_table ( indx ).hdr_attribute5
                 , hdr_attribute_status = p_cnv_pre_std_hdr_table ( indx ).hdr_attribute_status*/
                 , global_flag = p_cnv_pre_std_hdr_table ( indx ).global_flag
                 , orig_org_name = p_cnv_pre_std_hdr_table ( indx ).orig_org_name
                 , org_id = p_cnv_pre_std_hdr_table ( indx ).org_id
                 , automatic_flag = p_cnv_pre_std_hdr_table ( indx ).automatic_flag
                 , comments = p_cnv_pre_std_hdr_table ( indx ).comments
                -- , CONTEXT = p_cnv_pre_std_hdr_table ( indx ).CONTEXT
                 , currency_code = p_cnv_pre_std_hdr_table ( indx ).currency_code
                -- , currency_header_id = p_cnv_pre_std_hdr_table ( indx ).currency_header_id --DROY
                -- , delete_flag = p_cnv_pre_std_hdr_table ( indx ).delete_flag
                 , description = p_cnv_pre_std_hdr_table ( indx ).description
                -- , discount_lines_flag = p_cnv_pre_std_hdr_table ( indx ).discount_lines_flag --DROY
                 , end_date_active = p_cnv_pre_std_hdr_table ( indx ).end_date_active
                -- , end_date_active_dtl = p_cnv_pre_std_hdr_table ( indx ).end_date_active_dtl
                 , freight_terms_code = p_cnv_pre_std_hdr_table ( indx ).freight_terms_code
               --  , LANGUAGE = p_cnv_pre_std_hdr_table ( indx ).LANGUAGE -- DROY
               --  , list_source_code = p_cnv_pre_std_hdr_table ( indx ).list_source_code -- DROY
                 , list_type_code = p_cnv_pre_std_hdr_table ( indx ).list_type_code
               --  , lock_flag = p_cnv_pre_std_hdr_table ( indx ).lock_flag
                 , mobile_download = p_cnv_pre_std_hdr_table ( indx ).mobile_download
                 , NAME = p_cnv_pre_std_hdr_table ( indx ).NAME
                -- , list_header_id = p_cnv_pre_std_hdr_table ( indx ).list_header_id
                 , orig_sys_header_ref = p_cnv_pre_std_hdr_table ( indx ).orig_sys_header_ref
               --  , process_type = p_cnv_pre_std_hdr_table ( indx ).process_type
                 , pte_code = p_cnv_pre_std_hdr_table ( indx ).pte_code
                 , rounding_factor = p_cnv_pre_std_hdr_table ( indx ).rounding_factor
                 , ship_method_code = p_cnv_pre_std_hdr_table ( indx ).ship_method_code
                 , source_system_code = p_cnv_pre_std_hdr_table ( indx ).source_system_code
                 , start_date_active = p_cnv_pre_std_hdr_table ( indx ).start_date_active
                 --, start_date_active_dtl = p_cnv_pre_std_hdr_table ( indx ).start_date_active_dtl
                 , terms = p_cnv_pre_std_hdr_table ( indx ).terms
                 , version_no = p_cnv_pre_std_hdr_table ( indx ).version_no
                /* , arithmetic_operator = p_cnv_pre_std_hdr_table ( indx ).arithmetic_operator
                 , list_line_no = p_cnv_pre_std_hdr_table ( indx ).list_line_no
                 , list_line_type_code = p_cnv_pre_std_hdr_table ( indx ).list_line_type_code
                 , price_break_type_code = p_cnv_pre_std_hdr_table ( indx ).price_break_type_code
                 , price_break_header_ref = p_cnv_pre_std_hdr_table ( indx ).price_break_header_ref
                 , list_price = p_cnv_pre_std_hdr_table ( indx ).list_price
                 , operand = p_cnv_pre_std_hdr_table ( indx ).operand
                 , organization_code = p_cnv_pre_std_hdr_table ( indx ).organization_code
                 , orig_sys_line_ref = p_cnv_pre_std_hdr_table ( indx ).orig_sys_line_ref
                 , price_by_formula = p_cnv_pre_std_hdr_table ( indx ).price_by_formula
                 , primary_uom_flag = p_cnv_pre_std_hdr_table ( indx ).primary_uom_flag
                 , product_precedence = p_cnv_pre_std_hdr_table ( indx ).product_precedence
                 , attr_attribute1 = p_cnv_pre_std_hdr_table ( indx ).attr_attribute1
                 , attr_attribute2 = p_cnv_pre_std_hdr_table ( indx ).attr_attribute2
                 , attr_attribute3 = p_cnv_pre_std_hdr_table ( indx ).attr_attribute3
                 , attr_attribute4 = p_cnv_pre_std_hdr_table ( indx ).attr_attribute4
                 , attr_attribute5 = p_cnv_pre_std_hdr_table ( indx ).attr_attribute5
                 , attr_attribute_status = p_cnv_pre_std_hdr_table ( indx ).attr_attribute_status
                 , orig_sys_pricing_attr_ref = p_cnv_pre_std_hdr_table ( indx ).orig_sys_pricing_attr_ref
                 , pricing_attribute_context = p_cnv_pre_std_hdr_table ( indx ).pricing_attribute_context
                -- , pricing_attr_code = p_cnv_pre_std_hdr_table ( indx ).pricing_attr_code --DROY
                 , pricing_attribute = p_cnv_pre_std_hdr_table ( indx ).pricing_attribute
                 , pricing_attr_value_from = UPPER(p_cnv_pre_std_hdr_table ( indx ).pricing_attr_value_from)
                 , pricing_attr_value_to = p_cnv_pre_std_hdr_table ( indx ).pricing_attr_value_to
                 , product_attribute_context = p_cnv_pre_std_hdr_table ( indx ).product_attribute_context
                 , product_attr_code = p_cnv_pre_std_hdr_table ( indx ).product_attr_code
                 , product_attribute = p_cnv_pre_std_hdr_table ( indx ).product_attribute
                 , product_attr_value = p_cnv_pre_std_hdr_table ( indx ).product_attr_value
                 , product_uom_code = p_cnv_pre_std_hdr_table ( indx ).product_uom_code
                 , comparison_operator_code = p_cnv_pre_std_hdr_table ( indx ).comparison_operator_code
                 , excluder_flag = p_cnv_pre_std_hdr_table ( indx ).excluder_flag
                 , secondary_price_list_name = p_cnv_pre_std_hdr_table ( indx ).secondary_price_list_name
                 , customer_name = p_cnv_pre_std_hdr_table ( indx ).customer_name
                 , parent_list_header_id = p_cnv_pre_std_hdr_table ( indx ).parent_list_header_id
                 , cust_account_id = p_cnv_pre_std_hdr_table ( indx ).cust_account_id
                 , qualifier_context = p_cnv_pre_std_hdr_table ( indx ).qualifier_context
                 , qualifier_attribute_code = p_cnv_pre_std_hdr_table ( indx ).qualifier_attribute_code
                 , process_flag = p_cnv_pre_std_hdr_table ( indx ).process_flag
                 , process_status_flag = p_cnv_pre_std_hdr_table ( indx ).process_status_flag*/
                 , process_code = p_cnv_pre_std_hdr_table ( indx ).process_code
                 , ERROR_CODE = p_cnv_pre_std_hdr_table ( indx ).ERROR_CODE
                 , last_updated_by = x_last_update_by
                 , last_update_date = x_last_update_date
                 , last_update_login = x_last_updated_login
             WHERE record_number = p_cnv_pre_std_hdr_table ( indx ).record_number
              AND  batch_id      = g_batch_id;
         END LOOP;

         COMMIT;
      END update_pre_interface_records;

----------For Pricelist Lines------------------------------------------------------------
PROCEDURE update_pre_interface_records (
         p_cnv_pre_std_hdr_table   IN   G_XX_QP_PL_LINES_PRE_TAB_TYPE
      )
      IS
         x_last_update_date     DATE   := SYSDATE;
         x_last_update_by       NUMBER := fnd_global.user_id;
         x_last_updated_login   NUMBER := fnd_profile.VALUE ( xx_emf_cn_pkg.cn_login_id );
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         FOR indx IN 1 .. p_cnv_pre_std_hdr_table.COUNT
         LOOP
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                 ,    'p_cnv_pre_std_hdr_table(indx).process_code '
                                   || p_cnv_pre_std_hdr_table ( indx ).process_code
                                   || ' for record number '
                                   || p_cnv_pre_std_hdr_table ( indx ).record_number
                                   || ' Error Code is '
                                   || p_cnv_pre_std_hdr_table ( indx ).ERROR_CODE
                                 );
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                 ,    'p_cnv_pre_std_hdr_table(indx).error_code '
                                   || p_cnv_pre_std_hdr_table ( indx ).ERROR_CODE
                                 );

            UPDATE xx_qp_pr_list_lines_pre
               SET active_flag = p_cnv_pre_std_hdr_table ( indx ).active_flag
                /* , hdr_attribute1 = p_cnv_pre_std_hdr_table ( indx ).hdr_attribute1
                 , hdr_attribute2 = p_cnv_pre_std_hdr_table ( indx ).hdr_attribute2
                 , hdr_attribute3 = p_cnv_pre_std_hdr_table ( indx ).hdr_attribute3
                 , hdr_attribute4 = p_cnv_pre_std_hdr_table ( indx ).hdr_attribute4
                 , hdr_attribute5 = p_cnv_pre_std_hdr_table ( indx ).hdr_attribute5
                 , hdr_attribute_status = p_cnv_pre_std_hdr_table ( indx ).hdr_attribute_status
                 , global_flag = p_cnv_pre_std_hdr_table ( indx ).global_flag
                 , orig_org_name = p_cnv_pre_std_hdr_table ( indx ).orig_org_name
                 , org_id = p_cnv_pre_std_hdr_table ( indx ).org_id
                 , automatic_flag = p_cnv_pre_std_hdr_table ( indx ).automatic_flag
                 , comments = p_cnv_pre_std_hdr_table ( indx ).comments*/
                -- , CONTEXT = p_cnv_pre_std_hdr_table ( indx ).CONTEXT
                -- , currency_code = p_cnv_pre_std_hdr_table ( indx ).currency_code
                -- , currency_header_id = p_cnv_pre_std_hdr_table ( indx ).currency_header_id --DROY
                -- , delete_flag = p_cnv_pre_std_hdr_table ( indx ).delete_flag
                -- , description = p_cnv_pre_std_hdr_table ( indx ).description
                -- , discount_lines_flag = p_cnv_pre_std_hdr_table ( indx ).discount_lines_flag --DROY
                 , end_date_active = p_cnv_pre_std_hdr_table ( indx ).end_date_active
                -- , end_date_active_dtl = p_cnv_pre_std_hdr_table ( indx ).end_date_active_dtl
                -- , freight_terms_code = p_cnv_pre_std_hdr_table ( indx ).freight_terms_code
               --  , LANGUAGE = p_cnv_pre_std_hdr_table ( indx ).LANGUAGE -- DROY
               --  , list_source_code = p_cnv_pre_std_hdr_table ( indx ).list_source_code -- DROY
                -- , list_type_code = p_cnv_pre_std_hdr_table ( indx ).list_type_code
               --  , lock_flag = p_cnv_pre_std_hdr_table ( indx ).lock_flag
               --  , mobile_download = p_cnv_pre_std_hdr_table ( indx ).mobile_download
               --  , NAME = p_cnv_pre_std_hdr_table ( indx ).NAME
                -- , list_header_id = p_cnv_pre_std_hdr_table ( indx ).list_header_id
                   , orig_sys_header_ref = p_cnv_pre_std_hdr_table ( indx ).orig_sys_header_ref
               --  , process_type = p_cnv_pre_std_hdr_table ( indx ).process_type
              /*   , pte_code = p_cnv_pre_std_hdr_table ( indx ).pte_code
                 , rounding_factor = p_cnv_pre_std_hdr_table ( indx ).rounding_factor
                 , ship_method_code = p_cnv_pre_std_hdr_table ( indx ).ship_method_code
                 , source_system_code = p_cnv_pre_std_hdr_table ( indx ).source_system_code*/
                 , start_date_active = p_cnv_pre_std_hdr_table ( indx ).start_date_active
                 --, start_date_active_dtl = p_cnv_pre_std_hdr_table ( indx ).start_date_active_dtl
               --  , terms = p_cnv_pre_std_hdr_table ( indx ).terms
               --  , version_no = p_cnv_pre_std_hdr_table ( indx ).version_no
                 , arithmetic_operator = p_cnv_pre_std_hdr_table ( indx ).arithmetic_operator
                -- , list_line_no = p_cnv_pre_std_hdr_table ( indx ).list_line_no --DROY MIGHT WILL BE REQD
                 , list_line_type_code = p_cnv_pre_std_hdr_table ( indx ).list_line_type_code
                 , price_break_type_code = p_cnv_pre_std_hdr_table ( indx ).price_break_type_code
                 , price_break_header_ref = p_cnv_pre_std_hdr_table ( indx ).price_break_header_ref
                 , list_price = p_cnv_pre_std_hdr_table ( indx ).list_price
                 , operand = p_cnv_pre_std_hdr_table ( indx ).operand
                 --, organization_code = p_cnv_pre_std_hdr_table ( indx ).organization_code --DROY
                 , orig_sys_line_ref = p_cnv_pre_std_hdr_table ( indx ).orig_sys_line_ref
                 , price_by_formula = p_cnv_pre_std_hdr_table ( indx ).price_by_formula
                 , primary_uom_flag = p_cnv_pre_std_hdr_table ( indx ).primary_uom_flag
                 , product_precedence = p_cnv_pre_std_hdr_table ( indx ).product_precedence
                /* , attr_attribute1 = p_cnv_pre_std_hdr_table ( indx ).attr_attribute1
                 , attr_attribute2 = p_cnv_pre_std_hdr_table ( indx ).attr_attribute2
                 , attr_attribute3 = p_cnv_pre_std_hdr_table ( indx ).attr_attribute3
                 , attr_attribute4 = p_cnv_pre_std_hdr_table ( indx ).attr_attribute4
                 , attr_attribute5 = p_cnv_pre_std_hdr_table ( indx ).attr_attribute5
                 , attr_attribute_status = p_cnv_pre_std_hdr_table ( indx ).attr_attribute_status */
                 --, orig_sys_pricing_attr_ref = p_cnv_pre_std_hdr_table ( indx ).orig_sys_pricing_attr_ref
                 , pricing_attribute_context = p_cnv_pre_std_hdr_table ( indx ).pricing_attribute_context
                -- , pricing_attr_code = p_cnv_pre_std_hdr_table ( indx ).pricing_attr_code
                 , pricing_attribute = p_cnv_pre_std_hdr_table ( indx ).pricing_attribute
                 , pricing_attr_value_from = UPPER(p_cnv_pre_std_hdr_table ( indx ).pricing_attr_value_from)
                 , pricing_attr_value_to = p_cnv_pre_std_hdr_table ( indx ).pricing_attr_value_to
                 , product_attribute_context = p_cnv_pre_std_hdr_table ( indx ).product_attribute_context
                 , product_attribute_code = p_cnv_pre_std_hdr_table ( indx ).product_attribute_code
                 , product_attribute = p_cnv_pre_std_hdr_table ( indx ).product_attribute
                 , product_attr_value = p_cnv_pre_std_hdr_table ( indx ).product_attr_value
                 , product_uom_code = p_cnv_pre_std_hdr_table ( indx ).product_uom_code
                 , comparison_operator_code = p_cnv_pre_std_hdr_table ( indx ).comparison_operator_code
                 , excluder_flag = p_cnv_pre_std_hdr_table ( indx ).excluder_flag
                -- , secondary_price_list_name = p_cnv_pre_std_hdr_table ( indx ).secondary_price_list_name --DROY NEED TO ADD
                -- , customer_name = p_cnv_pre_std_hdr_table ( indx ).customer_name
                -- , parent_list_header_id = p_cnv_pre_std_hdr_table ( indx ).parent_list_header_id
                -- , cust_account_id = p_cnv_pre_std_hdr_table ( indx ).cust_account_id
               --  , qualifier_context = p_cnv_pre_std_hdr_table ( indx ).qualifier_context --DROY DONT NEED?
               --  , qualifier_attribute_code = p_cnv_pre_std_hdr_table ( indx ).qualifier_attribute_code
              --   , process_flag = p_cnv_pre_std_hdr_table ( indx ).process_flag
               --  , process_status_flag = p_cnv_pre_std_hdr_table ( indx ).process_status_flag
                 , process_code = p_cnv_pre_std_hdr_table ( indx ).process_code
                 , ERROR_CODE = p_cnv_pre_std_hdr_table ( indx ).ERROR_CODE
                 , last_updated_by = x_last_update_by
                 , last_update_date = x_last_update_date
                 , last_update_login = x_last_updated_login
             WHERE record_number = p_cnv_pre_std_hdr_table ( indx ).record_number
              AND  batch_id      = g_batch_id;
         END LOOP;

         COMMIT;
      END update_pre_interface_records; --DROY ADD THESE  CALLS TO THE MAIN PKG

/***************** For Qualifiers **************************/
        PROCEDURE update_pre_interface_records (p_cnv_pre_std_hdr_table IN G_XX_QP_PL_QLF_PRE_TAB_TYPE)
        IS
                x_last_update_date      DATE := SYSDATE;
                x_last_updated_by        NUMBER := fnd_global.user_id;
                x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

                PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~UPDATE_PRE_INTERFACE_RECORDS FOR QUALIFIER');
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table.COUNT FOR QUALIFIER '||p_cnv_pre_std_hdr_table.COUNT );
                FOR indx IN 1 .. p_cnv_pre_std_hdr_table.COUNT LOOP
--                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).process_code ' || p_cnv_pre_std_hdr_table(indx).process_code);
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).process_code ' || p_cnv_pre_std_hdr_table(indx).process_code);
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).record_number ' || p_cnv_pre_std_hdr_table(indx).record_number);

                        UPDATE xx_qp_pr_list_qlf_pre
                           SET
                                --modifier_name	=	p_cnv_pre_std_hdr_table(indx).modifier_name	,
                                --list_type_code	=	p_cnv_pre_std_hdr_table(indx).list_type_code	,
                                comparison_operator_code	=	p_cnv_pre_std_hdr_table(indx).comparison_operator_code	,
                                --comparison_operator_desc	=	p_cnv_pre_std_hdr_table(indx).comparison_operator_desc	,
                                qualifier_context	=	p_cnv_pre_std_hdr_table(indx).qualifier_context	,
                                --qualifier_context_desc	=	p_cnv_pre_std_hdr_table(indx).qualifier_context_desc	,
                                qualifier_attribute	=	p_cnv_pre_std_hdr_table(indx).qualifier_attribute	,
                                --qualifier_attribute_code	=	p_cnv_pre_std_hdr_table(indx).qualifier_attribute_code	,
                                qualifier_grouping_no	=	p_cnv_pre_std_hdr_table(indx).qualifier_grouping_no	,
                                qualifier_attr_value	=	p_cnv_pre_std_hdr_table(indx).qualifier_attr_value	,
                                qualifier_precedence	=	p_cnv_pre_std_hdr_table(indx).qualifier_precedence	,
                                --excluder_flag	=	p_cnv_pre_std_hdr_table(indx).excluder_flag	, --DROY
                                qualifier_attr_value_to	=	p_cnv_pre_std_hdr_table(indx).qualifier_attr_value_to	,
                                start_date_active	=	p_cnv_pre_std_hdr_table(indx).start_date_active	,
                                end_date_active	=	p_cnv_pre_std_hdr_table(indx).end_date_active	,
                                context	=	p_cnv_pre_std_hdr_table(indx).context	,
                                -- process_type	=	p_cnv_pre_std_hdr_table(indx).process_type	,
                                -- lock_flag	=	p_cnv_pre_std_hdr_table(indx).lock_flag	,
                                --delete_flag	=	p_cnv_pre_std_hdr_table(indx).delete_flag	,
                                price_list_line_index	=	p_cnv_pre_std_hdr_table(indx).price_list_line_index	,
                                /*product_attr_val_disp	=	p_cnv_pre_std_hdr_table(indx).product_attr_val_disp	,
                                pricing_attr_code	=	p_cnv_pre_std_hdr_table(indx).pricing_attr_code	,
                                pricing_attr_value_from_disp	=	p_cnv_pre_std_hdr_table(indx).pricing_attr_value_from_disp	,
                                pricing_attr_value_to_disp	=	p_cnv_pre_std_hdr_table(indx).pricing_attr_value_to_disp	,
                                -- attribute_status	=	p_cnv_pre_std_hdr_table(indx).attribute_status	,
                                -- interface_action_code	=	p_cnv_pre_std_hdr_table(indx).interface_action_code	,*/
                                -- process_flag	=	p_cnv_pre_std_hdr_table(indx).process_flag	,
                                -- process_status_flag	=	p_cnv_pre_std_hdr_table(indx).process_status_flag	,
                                batch_id	=	p_cnv_pre_std_hdr_table(indx).batch_id	,
                                created_by	=	p_cnv_pre_std_hdr_table(indx).created_by	,
                                creation_date	=	p_cnv_pre_std_hdr_table(indx).creation_date	,
                                request_id	=	p_cnv_pre_std_hdr_table(indx).request_id	,
                                process_code	=	p_cnv_pre_std_hdr_table(indx).process_code	,
                                error_code	=	p_cnv_pre_std_hdr_table(indx).error_code	,
                                error_desc	=	p_cnv_pre_std_hdr_table(indx).error_desc	,
                                src_file_name	=	p_cnv_pre_std_hdr_table(indx).src_file_name	,
                                record_number	=	p_cnv_pre_std_hdr_table(indx).record_number	,
                                sec_prc_list_orig_sys_hdr_ref = p_cnv_pre_std_hdr_table(indx).sec_prc_list_orig_sys_hdr_ref,
                                sec_prc_list_orig_list_id = p_cnv_pre_std_hdr_table(indx).sec_prc_list_orig_list_id,
                                -- header_record_number	=	p_cnv_pre_std_hdr_table(indx).header_record_number	,
                                -- line_record_number	=	p_cnv_pre_std_hdr_table(indx).line_record_number	,
                                --qlfr_attr_value_to_desc	=	p_cnv_pre_std_hdr_table(indx).qlfr_attr_value_to_desc	,
                                --qlfr_attr_value_code	=	p_cnv_pre_std_hdr_table(indx).qlfr_attr_value_code	,
                                last_updated_by     = x_last_updated_by,
                                last_update_date   = x_last_update_date,
                                last_update_login = x_last_update_login
                         WHERE
                         record_number = p_cnv_pre_std_hdr_table(indx).record_number
                         --header_record_number = p_cnv_pre_std_hdr_table(indx).header_record_number
                         AND batch_id=G_BATCH_ID;

                END LOOP;

                COMMIT;
        END update_pre_interface_records;



/*******************Function To Line grouping*************************/

     /* FUNCTION update_line_ref
      RETURN NUMBER
      IS
               x_last_update_by          NUMBER                  := fnd_global.user_id;
               x_last_updated_login      NUMBER                  := fnd_profile.VALUE ( xx_emf_cn_pkg.cn_login_id );
               x_cnv_pre_std_hdr_table   G_XX_QP_PL_HDR_STG_TAB_TYPE;
               x_error_code              NUMBER                  := xx_emf_cn_pkg.cn_success;
      PRAGMA AUTONOMOUS_TRANSACTION;

      BEGIN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Inside update_line_ref' );

          UPDATE xx_qp_pr_list_hdr_stg --DROY ADD LINES
          SET
          orig_sys_line_ref=DECODE(list_line_type_code,'PBH',to_char(record_number)
                                     ,'PLL',DECODE(price_break_header_ref,'',
                                                   TO_CHAR(record_number),
                                                   TRUNC(price_break_header_ref))
                                      ),
          price_break_header_ref=TRUNC(price_break_header_ref)
          WHERE
          batch_id = g_batch_id
          AND process_code = xx_emf_cn_pkg.cn_preval
          AND request_id = xx_emf_pkg.g_request_id
          AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn );
      COMMIT;
               --Update the organization ID column to filter out the already loaded data
      RETURN x_error_code;
      EXCEPTION
      WHEN OTHERS
      THEN
                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                       , 'No of Records Insert into Pre-Interface 2=>' || SQL%ROWCOUNT || '-' || SQLERRM
                                       );
                  xx_emf_pkg.error ( xx_emf_cn_pkg.cn_medium, xx_emf_cn_pkg.cn_tech_error, xx_emf_cn_pkg.cn_exp_unhand );
                  x_error_code := xx_emf_cn_pkg.cn_prc_err;
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'error in updateion' || SQLERRM );
      RETURN x_error_code;

      END update_line_ref;*/--DROY EXAMINE AND UPDATE

      /*******************MOVE_REC_PRE_STANDARD_TABLE*************************/

      FUNCTION move_rec_pre_standard_table
         RETURN NUMBER
      IS
         x_creation_date           DATE                    := SYSDATE;
         x_created_by              NUMBER                  := fnd_global.user_id;
         x_last_update_date        DATE                    := SYSDATE;
         x_last_update_by          NUMBER                  := fnd_global.user_id;
         x_last_updated_login      NUMBER                  := fnd_profile.VALUE ( xx_emf_cn_pkg.cn_login_id );
         x_cnv_pre_std_hdr_table   G_XX_QP_PL_HDR_STG_TAB_TYPE;
         x_error_code              NUMBER                  := xx_emf_cn_pkg.cn_success;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Inside move_rec_pre_standard_table' );
         BEGIN
         -- CCID099 changes
         -- Select only the appropriate columns that are required to be inserted into the
         -- Pre-Interface Table and insert from the Staging Table
         INSERT INTO xx_qp_pr_list_hdr_pre
                     ( active_flag
                    /* , hdr_attribute1
                     , hdr_attribute2
                     , hdr_attribute3
                     , hdr_attribute4
                     , hdr_attribute5
                     , hdr_attribute_status*/
                     , global_flag
                     , orig_org_name
                     , automatic_flag
                     , comments
                    -- , CONTEXT
                     , currency_code
                    -- , delete_flag
                     , description
                    -- , discount_lines_flag
                     , end_date_active
                    -- , end_date_active_dtl
                     , freight_terms_code
                    -- , LANGUAGE
                    -- , list_source_code
                     ,
                       --list_type_code_text     ,
                       list_type_code
                    -- , lock_flag
                     , mobile_download
                     , NAME
                     , orig_sys_header_ref
                    -- , process_type
                     , pte_code
                     , rounding_factor
                     , ship_method_code
                     , source_system_code
                     , start_date_active
                    -- , start_date_active_dtl
                     , terms
                     , version_no
                    /* ,
                       --  arithmetic_operator_text  ,
                      ,arithmetic_operator
                     , dtl_attribute1
                     , dtl_attribute2
                     , dtl_attribute3
                     , dtl_attribute4
                     , dtl_attribute5
                     , dtl_attribute_status
                     , legacy_item_number
                     , list_line_no
                     , list_line_type_code
                     ,
                       --list_line_type_code_text  ,
                       --price_break_type_code,
                       list_price
                     , operand
                     , organization_code
                     , orig_sys_line_ref
                     , price_by_formula
                     , primary_uom_flag
                     , product_precedence
                     , attr_attribute1
                     , attr_attribute2
                     , attr_attribute3
                     , attr_attribute4
                     , attr_attribute5
                     , attr_attribute_status
                     , orig_sys_pricing_attr_ref
                     , pricing_attribute_context
                     , pricing_attr_code
                     , pricing_attr_value_from
                     , pricing_attr_value_to
                     , product_attribute_context
                     , product_attr_code
                     , product_attr_value
                     , product_uom_code
                     , comparison_operator_code
                     , excluder_flag
                     , interface_action_code
                     , process_flag
                     , process_status_flag */
                     , batch_id
                     , record_number
                     , process_code
                     , ERROR_CODE
                     , created_by
                     , creation_date
                     , last_update_date
                     , last_updated_by
                     , last_update_login
                     , request_id
                    -- , price_break_type_code
                   --  , price_break_header_ref
                   --  , secondary_price_list_name
                   --  , customer_name
                     )
            SELECT active_flag
                 /*, hdr_attribute1
                 , hdr_attribute2
                 , hdr_attribute3
                 , hdr_attribute4
                 , hdr_attribute5
                 , hdr_attribute_status*/
                 , 'N'-- hardcode as N as per Sri --global_flag
                 , orig_org_name
                 , automatic_flag
                 , comments
                -- , CONTEXT
                 , currency_code
              --   , delete_flag
                 , description
                -- , discount_lines_flag
                 , end_date_active
                -- , end_date_active_dtl
                 , freight_terms_code
               --  , LANGUAGE
               --  , list_source_code
                 , list_type_code
               --  , lock_flag
                 , mobile_download
                 , NAME
                 , orig_sys_header_ref
               --  ,
                   --NAME||'-'||XX_QP_ORIG_SYS_HEADER_REF.nextval,
              --     process_type
                 , pte_code
                 , rounding_factor
                 , ship_method_code
                 , source_system_code
                 , start_date_active
                -- , start_date_active_dtl
                 , terms
                 , version_no
                /* , arithmetic_operator
                 , dtl_attribute1
                 , dtl_attribute2
                 , dtl_attribute3
                 , dtl_attribute4
                 , dtl_attribute5
                 , dtl_attribute_status
                 , legacy_item_number
                 , list_line_no
                 , list_line_type_code
                 ,
                   --price_break_type_code,
                   list_price
                 , operand
                 , organization_code
                 , orig_sys_line_ref
                 ,
                   --'LN-'||XX_QP_ORIG_SYS_LINE_REF.nextval,
                   price_by_formula
                 , primary_uom_flag
                 , product_precedence
                 , attr_attribute1
                 , attr_attribute2
                 , attr_attribute3
                 , attr_attribute4
                 , attr_attribute5
                 , attr_attribute_status
                 , orig_sys_pricing_attr_ref
                 ,
                   --'ATTR-'||XX_QP_ORIG_SYS_ATTR_REF.nextval,
                   pricing_attribute_context
                 , pricing_attr_code
                 , pricing_attr_value_from
                 , pricing_attr_value_to
                 , product_attribute_context
                 , product_attr_code
                 , product_attr_value
                 , product_uom_code
                 , comparison_operator_code
                 , excluder_flag
                 , interface_action_code
                 , process_flag
                 , process_status_flag */
                 , batch_id
                 , record_number
                 , process_code
                 , ERROR_CODE
                 , x_created_by
                 , x_creation_date
                 , x_last_update_date
                 , x_last_update_by
                 , x_last_updated_login
                 , request_id
              --   , price_break_type_code
              --   , price_break_header_ref
              --   , secondary_price_list_name
              --   , customer_name
              FROM xx_qp_pr_list_hdr_stg
             WHERE batch_id = g_batch_id
               AND process_code = xx_emf_cn_pkg.cn_preval
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
               AND DESELECT_FLAG IS NULL;

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'No of Records Insert into Pre-Interface 1=>' || SQL%ROWCOUNT );
         COMMIT;
         EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                 , 'No of Records Insert into Pre-Interface 2=>' || SQL%ROWCOUNT || '-' || SQLERRM
                                 );
            xx_emf_pkg.error ( xx_emf_cn_pkg.cn_medium, xx_emf_cn_pkg.cn_tech_error, xx_emf_cn_pkg.cn_exp_unhand );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'error in insertion' || SQLERRM );
            RETURN x_error_code;
          END ;


         BEGIN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Inside move_rec_pre_standard_table line' );

         -- CCID099 changes
         -- Select only the appropriate columns that are required to be inserted into the
         -- Pre-Interface Table and insert from the Staging Table
         INSERT INTO xx_qp_pr_list_lines_pre
                     ( active_flag
                     ,inventory_item
                    /* , hdr_attribute1
                     , hdr_attribute2
                     , hdr_attribute3
                     , hdr_attribute4
                     , hdr_attribute5
                     , hdr_attribute_status
                     , global_flag
                     , orig_org_name
                     , automatic_flag
                     , comments
                     , CONTEXT
                     , currency_code
                     , delete_flag
                     , description
                     , discount_lines_flag */
                     , end_date_active
                    -- , end_date_active_dtl
                    -- , freight_terms_code
                    -- , LANGUAGE
                    -- , list_source_code
                   --  , list_type_code
                    -- , lock_flag
                   --  , mobile_download
                  --   , NAME
                     , orig_sys_header_ref
                    -- , process_type
                  --   , pte_code
                  --   , rounding_factor
                 --    , ship_method_code
                 --    , source_system_code
                     , start_date_active
                    -- , start_date_active_dtl
                 --    , terms
                 --    , version_no
                    /* ,
                       --  arithmetic_operator_text  ,*/
                      ,arithmetic_operator
                    -- , list_line_no
                     , list_line_type_code
                     ,
                       --list_line_type_code_text  ,
                       --price_break_type_code,
                       list_price
                     , operand
                    -- , organization_code
                     , orig_sys_line_ref
                     , price_by_formula
                     , primary_uom_flag
                     , product_precedence
                     ,incompatibility_grp_code
                     ,qualification_ind
                    /* , attr_attribute1
                     , attr_attribute2
                     , attr_attribute3
                     , attr_attribute4
                     , attr_attribute5
                     , attr_attribute_status */
                   --  , orig_sys_pricing_attr_ref
                     , pricing_attribute_context
                     , pricing_attribute
                     , pricing_attribute_name
                     , pricing_attr_value_from
                     , pricing_attr_value_to
                     , product_attribute_context
                     , product_attribute
                     , product_attribute_code
                     , product_attr_value
                     , product_uom_code
                     , comparison_operator_code
                     , excluder_flag
                     /*, interface_action_code
                     , process_flag
                     , process_status_flag */
                     , batch_id
                     , record_number
                     , process_code
                     , ERROR_CODE
                     , created_by
                     , creation_date
                     , last_update_date
                     , last_updated_by
                     , last_update_login
                     , request_id
                     , price_break_type_code
                     , price_break_header_ref
                     , from_orig_sys_hdr_ref
                     , to_orig_sys_hdr_ref
                     --, secondary_price_list_name
                   --  , customer_name
                     )
            SELECT active_flag
                 ,inventory_item
                 /*, hdr_attribute1
                 , hdr_attribute2
                 , hdr_attribute3
                 , hdr_attribute4
                 , hdr_attribute5
                 , hdr_attribute_status
                 , global_flag
                 , orig_org_name
                 , automatic_flag
                 , comments
                 , CONTEXT
                 , currency_code
                 , delete_flag
                 , description
                 , discount_lines_flag*/
                 , end_date_active
                -- , end_date_active_dtl
                -- , freight_terms_code
               --  , LANGUAGE
               --  , list_source_code
               --  , list_type_code
               --  , lock_flag
               --  , mobile_download
               --  , NAME
                 , orig_sys_header_ref
               --  ,
                   --NAME||'-'||XX_QP_ORIG_SYS_HEADER_REF.nextval,
              --     process_type
              --   , pte_code
              --   , rounding_factor
              --   , ship_method_code
              --   , source_system_code
                 , start_date_active
                -- , start_date_active_dtl
             --    , terms
             --    , version_no
                 , arithmetic_operator
                -- , list_line_no
                 , list_line_type_code
                 ,
                   --price_break_type_code,
                   list_price
                 , operand
                -- , organization_code
                 , orig_sys_line_ref
                 , price_by_formula
                 , primary_uom_flag
                 , product_precedence
                 ,incompatibility_grp_code
                 ,qualification_ind
                /* , attr_attribute1
                 , attr_attribute2
                 , attr_attribute3
                 , attr_attribute4
                 , attr_attribute5
                 , attr_attribute_status */
               --  , orig_sys_pricing_attr_ref
                 , pricing_attribute_context
                 , pricing_attribute --DROY change from attr code to attribute
                 , pricing_attribute_name
                 , pricing_attr_value_from
                 , pricing_attr_value_to
                 , product_attribute_context
                 , product_attribute
                 , product_attribute_code
                 , product_attr_value
                 , product_uom_code
                 , comparison_operator_code
                 , excluder_flag
               --  , interface_action_code
               --  , process_flag
               --  , process_status_flag
                 , batch_id
                 , record_number
                 , process_code
                 , ERROR_CODE
                 , x_created_by
                 , x_creation_date
                 , x_last_update_date
                 , x_last_update_by
                 , x_last_updated_login
                 , request_id
                 , price_break_type_code
                 , price_break_header_ref
                 , from_orig_sys_hdr_ref
                 , to_orig_sys_hdr_ref
                 --, secondary_price_list_name --DROY
              --   , customer_name
              FROM xx_qp_pr_list_lines_stg
             WHERE batch_id = g_batch_id
               AND process_code = xx_emf_cn_pkg.cn_preval
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
               AND DESELECT_FLAG IS NULL;

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'No of Records Insert into Pre-Interface 1=>' || SQL%ROWCOUNT );
         --COMMIT;
         --Update the organization ID column to filter out the already loaded data

      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                 , 'No of Records Insert into Pre-Interface 2=>' || SQL%ROWCOUNT || '-' || SQLERRM
                                 );
            xx_emf_pkg.error ( xx_emf_cn_pkg.cn_medium, xx_emf_cn_pkg.cn_tech_error, xx_emf_cn_pkg.cn_exp_unhand );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'error in insertion' || SQLERRM );
            RETURN x_error_code;
      END ;

      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After Pre Lines Insert'); --DROY DELETE LATER

      BEGIN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Inside move_rec_pre_standard_table qualifier' );

         -- CCID099 changes
         -- Select only the appropriate columns that are required to be inserted into the
         -- Pre-Interface Table and insert from the Staging Table
         INSERT INTO xx_qp_pr_list_qlf_pre
                     (
                        orig_sys_header_ref	,
                        --list_type_code	,
                        comparison_operator_code	,
                        --comparison_operator_desc	,
                        qualifier_context	,
                        -- qualifier_context_desc	,
                        qualifier_attribute	,
                        --qualifier_attribute_code	,
                        qualifier_grouping_no	,
                        qualifier_attr_value_disp	,
                        qualifier_precedence	,
                        --excluder_flag	,
                        qualifier_attr_value_to	,
                        start_date_active	,
                        end_date_active	,
                        context	,
                        -- process_type	,
                        -- lock_flag	,
                        --delete_flag	,
                        price_list_line_index	,
                        --product_attr_val_disp	,
                        --pricing_attr_code	,
                        --pricing_attr_value_from_disp	,
                        --pricing_attr_value_to_disp	,
                        -- attribute_status	,
                        -- interface_action_code	,
                        -- process_flag	,
                        -- process_status_flag	,
                        batch_id	,
                        error_desc	,
                        src_file_name	,
                        sec_prc_list_orig_sys_hdr_ref,
                        record_number	,
                        -- header_record_number	,
                        -- line_record_number	,
                        --qlfr_attr_value_code	,
                        --qlfr_attr_value_to_desc	,
                        process_code,           --- DO NOT CHANGE FROM THIS LINE TILL MENTIONED LINE
                        error_code,
                        request_id,
                        created_by,
                        creation_date,
                        last_updated_by,
                        last_update_date,
                        last_update_login      -- DO NOT CHANGE TO THIS LINE
                )
                SELECT
                        orig_sys_header_ref	,
                        --list_type_code	,
                        comparison_operator_code	,
                        --comparison_operator_desc	,
                        qualifier_context	,
                        -- qualifier_context_desc	,
                        qualifier_attribute	,
                        --qualifier_attribute_code	,
                        qualifier_grouping_no	,
                        qualifier_attr_value_disp	,
                        qualifier_precedence	,
                        --excluder_flag	, --DROY
                        qualifier_attr_value_to	,
                        trunc(start_date_active)	,
                        trunc(end_date_active)	,
                        context	,
                        -- process_type	,
                        --  lock_flag	,
                        --delete_flag	,
                        price_list_line_index	,
                        --product_attr_val_disp	,
                        --pricing_attr_code	,
                        --pricing_attr_value_from_disp	,
                        --pricing_attr_value_to_disp	,
                        -- attribute_status	,
                        -- interface_action_code	,
                        -- process_flag	,
                        -- process_status_flag	,
                        batch_id	,
                        error_desc	,
                        src_file_name	,
                        sec_prc_list_orig_sys_hdr_ref,
                        record_number,
                        --to_number(header_record_number),
                        -- header_record_number	,
                        -- line_record_number	,
                        --qlfr_attr_value_code	,
                        --qlfr_attr_value_to_desc	,
                        G_STAGE,                --- DO NOT CHANGE FROM THIS LINE TILL MENTIONED LINE
                        error_code,                     --- DO NOT CHANGE THIS LINE
                        request_id,
                        x_created_by,
                        x_creation_date,
                        x_last_update_by,
                        x_last_update_date,
                        x_last_updated_login    -- DO NOT CHANGE TO THIS LINE
                  FROM xx_qp_pr_list_qlf_stg
                 WHERE BATCH_ID = G_BATCH_ID
                   AND process_code = xx_emf_cn_pkg.CN_PREVAL
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                   AND DESELECT_FLAG IS NULL;


         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'No of Records Insert into Pre-Interface Qlf=>' || SQL%ROWCOUNT );
         --COMMIT;

         --RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                 , 'No of Records Insert into qlf Pre-Interface 2=>' || SQL%ROWCOUNT || '-' || SQLERRM
                                 );
            xx_emf_pkg.error ( xx_emf_cn_pkg.cn_medium, xx_emf_cn_pkg.cn_tech_error, xx_emf_cn_pkg.cn_exp_unhand );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'error in insertion' || SQLERRM );
            RETURN x_error_code;
      END; --DROY different begin end might have exceptions unnoticed for hdr/lines
      COMMIT;
      RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                 , 'No of Records Insert into Pre-Interface 2=>' || SQL%ROWCOUNT || '-' || SQLERRM
                                 );
            xx_emf_pkg.error ( xx_emf_cn_pkg.cn_medium, xx_emf_cn_pkg.cn_tech_error, xx_emf_cn_pkg.cn_exp_unhand );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'error in insertion' || SQLERRM );
            RETURN x_error_code;
      END move_rec_pre_standard_table;




      FUNCTION process_data
         RETURN NUMBER
      IS
         CURSOR c_header
         IS
            SELECT DISTINCT /*orig_sys_header_ref
                          , list_type_code
                          , NAME
                          , list_header_id
                           ,*/custom_batch_no
                       FROM xx_qp_pr_list_hdr_pre
                      WHERE batch_id = g_batch_id
                        AND request_id = xx_emf_pkg.g_request_id
                        --AND list_header_id IS NOT NULL
                        AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
                        AND process_code = xx_emf_cn_pkg.cn_postval
                      ORDER BY custom_batch_no;

         CURSOR c_prc_hdr_qlf_exists IS
         SELECT
			       x.*
            FROM xx_qp_pr_list_hdr_pre x
            WHERE batch_id          = g_batch_id
              AND request_id        = xx_emf_pkg.G_REQUEST_ID
	      AND process_code      = xx_emf_cn_pkg.CN_POSTVAL
	      AND error_code        IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
              AND EXISTS (SELECT 1
                            FROM xx_qp_pr_list_qlf_pre q
                           WHERE q.orig_sys_header_ref = x.orig_sys_header_ref
                            AND  q.batch_id = x.batch_id
                            AND process_code      = xx_emf_cn_pkg.CN_POSTVAL
			    AND error_code        IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                          )
            ;

          CURSOR c_pre_std_qlf_hdr  (p_orig_sys_header_ref   IN xx_qp_pr_list_lines_stg.orig_sys_header_ref%TYPE
                                     ) IS
            SELECT
                --
                -- Add Columns
                --
			       x.*

            FROM xx_qp_pr_list_qlf_pre x
            WHERE batch_id          = p_BATCH_ID
			  --AND request_id        = xx_emf_pkg.G_REQUEST_ID
			  AND process_code      = xx_emf_cn_pkg.CN_POSTVAL
			  AND error_code        IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
              AND orig_sys_header_ref = p_orig_sys_header_ref
             ;

          CURSOR c_sec_price_list (p_secondary_list_id IN VARCHAR2) IS
          SELECT list_header_id
          FROM qp_list_headers qlh
          WHERE list_type_code = 'PRL'
            AND  qlh.orig_system_header_ref = p_secondary_list_id
            ORDER BY creation_date desc;

         CURSOR c_list_header_id(p_name IN VARCHAR2
                                ) IS
         SELECT list_header_id
                      FROM qp_list_headers
                       WHERE name= p_name
                        AND list_type_code = 'PRL'
                        ORDER by creation_date desc;

         x_error_code          VARCHAR2 ( 15 )  := xx_emf_cn_pkg.cn_success;
         x_req_return_status   BOOLEAN;
         x_req_id              NUMBER;
         x_dev_phase           VARCHAR2 ( 20 );
         x_phase               VARCHAR2 ( 20 );
         x_dev_status          VARCHAR2 ( 20 );
         x_status              VARCHAR2 ( 20 );
         x_message             VARCHAR2 ( 100 );
         x_req_phase           VARCHAR2 (60);
         x_call_status         BOOLEAN         := FALSE;
         x_call_status2        BOOLEAN         := FALSE;
         x_index               NUMBER          := 0;
         TYPE t_req_id_type IS RECORD (request_id NUMBER, custom_batch_no NUMBER) ;
         TYPE t_req_id_tab_type IS TABLE OF t_req_id_type
         INDEX BY BINARY_INTEGER;
         TYPE t_status_record IS RECORD (req_com_tf BOOLEAN, req_com_sts  VARCHAR2(50));
         TYPE t_status_type IS TABLE OF t_status_record
         INDEX BY BINARY_INTEGER;
         x_no_of_conc_batch NUMBER;
         t_req_id        t_req_id_tab_type;
         t_status        t_status_type;
         x_ret_success   BOOLEAN;
         ----qualifier declaration start----------------
         ------sec pricelist------------------------------------------------------
         gpr_qualifiers_tbl            qp_qualifier_rules_pub.qualifiers_tbl_type;
         ppr_qualifier_rules_rec       qp_qualifier_rules_pub.qualifier_rules_rec_type;
         ppr_qualifier_rules_val_rec   qp_qualifier_rules_pub.qualifier_rules_val_rec_type;
         ppr_qualifiers_tbl             qp_qualifier_rules_pub.qualifiers_tbl_type;
         ppr_qualifiers_val_tbl         qp_qualifier_rules_pub.qualifiers_val_tbl_type;

         gpr_msg_count                     NUMBER       := 0;
	 gpr_msg_data                      VARCHAR2(32767 );
         gpr_msg_data2                      VARCHAR2(32767 );
         gpr_return_status                 VARCHAR2(1);
         l_list_header_id                qp_list_headers.list_header_id%TYPE;

         x_hdr_err_flag                  VARCHAR2(1);
         x_line_err_flag                 VARCHAR2(1);
         x_attr_err_flag                  VARCHAR2(1);
         x_qlf_err_flag                  VARCHAR2(1);
         l_list_line_exists_flag         VARCHAR2(1);
         x_qual_count                    NUMBER;

         i                               NUMBER;
         x_ind                           NUMBER;
         x_stg_qlf_count                 NUMBER;
         x_tab_qlf_count                 NUMBER;
         e_no_header_found EXCEPTION;
         ----qualifier declaration end -----------------

      BEGIN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'INSIDE PROCESS_DATA' );

         x_no_of_conc_batch := TO_NUMBER(xx_emf_pkg.get_paramater_value ('XXQPPRCLISTCNV', 'PARALLEL_PROCESS'));
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Parallel Process :'||x_no_of_conc_batch );


         FOR hdr_rec IN c_header
         LOOP
             x_call_status := FALSE;
             IF hdr_rec.custom_batch_no <= x_no_of_conc_batch THEN
             --IF hdr_rec.custom_batch_no = 10 THEN
                x_index := x_index + 1;
                x_req_id := fnd_request.submit_request
                                      (application      => 'XXINTG',
                                       program          => 'XXQPPRCLISTCNVSUBMIT',
                                       argument1        => g_batch_id, --Batch Id
                                       argument2        => hdr_rec.custom_batch_no
                                      );

                UPDATE xx_qp_pr_list_hdr_pre
                   SET custom_batch_request = x_req_id
                 WHERE process_code = xx_emf_cn_pkg.cn_postval
                   AND custom_batch_no = hdr_rec.custom_batch_no
                   AND batch_id = g_batch_id
                   AND request_id = xx_emf_pkg.g_request_id;
                COMMIT;
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Submitted for Custom batch :'||hdr_rec.custom_batch_no);
                t_req_id(x_index).request_id := x_req_id;
                t_req_id(x_index).custom_batch_no := hdr_rec.custom_batch_no;
             ELSE
                WHILE x_call_status = FALSE
                LOOP
                   FOR n IN 1 .. x_index
                   LOOP
                      x_ret_success := FND_CONCURRENT.GET_REQUEST_STATUS(t_req_id(n).request_id
                                                             ,NULL
                                                             ,NULL
                                                             ,x_req_phase
                                                             ,x_status
                                                             ,t_status (n).req_com_sts
                                                             ,x_dev_status
                                                             ,x_message);
                   END LOOP;

                   x_call_status2 := FALSE;
                   FOR n IN 1 .. x_index
                   LOOP

                      t_status (n).req_com_tf := FALSE;
                      IF t_status (n).req_com_sts  = 'COMPLETE' THEN
                         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One request completed' );

                         x_req_id := fnd_request.submit_request
                                      (application      => 'XXINTG',
                                       program          => 'XXQPPRCLISTCNVSUBMIT',
                                       argument1        => g_batch_id, --Batch Id
                                       argument2        => hdr_rec.custom_batch_no
                                      );
                         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'INSIDE HEADER PROCESS_DATA' );

                         UPDATE xx_qp_pr_list_hdr_pre
                            SET custom_batch_request = x_req_id
                          WHERE process_code = xx_emf_cn_pkg.cn_postval
                            AND custom_batch_no = hdr_rec.custom_batch_no
                            AND batch_id = g_batch_id
                            AND request_id = xx_emf_pkg.g_request_id;
                         COMMIT;
                         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Submitted for Custom batch Subsequent:'||hdr_rec.custom_batch_no);
                         t_req_id(n).request_id := x_req_id;
                         t_req_id(n).custom_batch_no := hdr_rec.custom_batch_no;
                         t_status (n).req_com_sts  := NULL;
                         t_status (n).req_com_tf := TRUE;

                         x_call_status2 := x_call_status2 OR t_status (n).req_com_tf;
                         EXIT;
                      END IF;
                      x_call_status2 := x_call_status2 OR t_status (n).req_com_tf;
                   END LOOP;

                   x_call_status := x_call_status2;
                END LOOP;
                --null;


                --Add condition here for monitoring last batches completing and then only ending

             END IF; --IF hdr_rec.custom_batch_no <= x_no_of_conc_batch
         END LOOP; -- FOR hdr_rec IN c_header

         x_call_status := FALSE;
         WHILE x_call_status = FALSE
         LOOP
            FOR n IN 1 .. x_index
            LOOP

               t_status (n).req_com_tf :=
                    fnd_concurrent.wait_for_request (t_req_id(n).request_id,
                                                     1,
                                                     0,
                                                     x_req_phase,
                                                     x_status,
                                                     x_dev_phase,
                                                     x_dev_status,
                                                     x_message
                                                     );

            END LOOP;
            x_call_status2 := TRUE;
            FOR n IN 1 .. x_index
            LOOP
               x_call_status2 := x_call_status2 AND t_status (n).req_com_tf;
            END LOOP;
            x_call_status := x_call_status2;
         END LOOP;

         ---Start adding Qualifiers---------------
         DECLARE
         BEGIN
            FOR rec_prc_hdr_qlf_exists IN c_prc_hdr_qlf_exists LOOP
               BEGIN

                      gpr_msg_data  := NULL;
                      x_qlf_err_flag  := 'N';
                      i := 0;
                      l_list_header_id := NULL;
                      oe_msg_pub.initialize;
                      OPEN  c_list_header_id(rec_prc_hdr_qlf_exists.name
                                            );
                      FETCH c_list_header_id
                      INTO l_list_header_id ;
                      CLOSE c_list_header_id;

                      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Fetched Price list header id = '||l_list_header_id );
                      IF l_list_header_id  IS NULL THEN
                         RAISE e_no_header_found;
                      END IF;

                  -------------------------Qualifier Start---------------------------------------------------------
                   FOR rec_pre_std_qlf_hdr IN c_pre_std_qlf_hdr(rec_prc_hdr_qlf_exists.orig_sys_header_ref) LOOP
                      DECLARE
                         gpr_qualifiers_tbl            qp_qualifier_rules_pub.qualifiers_tbl_type;
                         ppr_qualifier_rules_rec       qp_qualifier_rules_pub.qualifier_rules_rec_type;
                         ppr_qualifier_rules_val_rec   qp_qualifier_rules_pub.qualifier_rules_val_rec_type;
                         ppr_qualifiers_tbl             qp_qualifier_rules_pub.qualifiers_tbl_type;
                         ppr_qualifiers_val_tbl         qp_qualifier_rules_pub.qualifiers_val_tbl_type;
                      BEGIN

                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Fetching qualifiers' );
                        /*oe_debug_pub.initialize;

                        oe_debug_pub.setdebuglevel(5);

                        oe_debug_pub.add('Add your debug message here');*/

                           i := 1;

                           IF rec_pre_std_qlf_hdr.QUALIFIER_CONTEXT <> 'MODLIST' THEN
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Norm qualifier' );
                              --l_QUALIFIERS_tbl(i).excluder_flag := NVL(rec_pre_std_qlf_hdr.excluder_flag,'N'); --DROY
                              gpr_qualifiers_tbl(i).list_header_id := l_list_header_id;
                              gpr_qualifiers_tbl(i).comparison_operator_code := rec_pre_std_qlf_hdr.comparison_operator_code;
                              gpr_qualifiers_tbl(i).qualifier_context := rec_pre_std_qlf_hdr.qualifier_context;
                              gpr_qualifiers_tbl(i).qualifier_attribute := rec_pre_std_qlf_hdr.qualifier_attribute; --DROY
                              gpr_qualifiers_tbl(i).qualifier_attr_value := rec_pre_std_qlf_hdr.qualifier_attr_value; --droy
                              gpr_qualifiers_tbl(i).qualifier_attr_value_to := rec_pre_std_qlf_hdr.qualifier_attr_value_to;
                              gpr_qualifiers_tbl(i).qualifier_grouping_no := rec_pre_std_qlf_hdr.qualifier_grouping_no;
                              gpr_qualifiers_tbl(i).qualifier_precedence := rec_pre_std_qlf_hdr.qualifier_precedence;
                              gpr_qualifiers_tbl(i).start_date_active := rec_pre_std_qlf_hdr.start_date_active;
                              gpr_qualifiers_tbl(i).end_date_active := rec_pre_std_qlf_hdr.end_date_active;
                              gpr_qualifiers_tbl(i).attribute10 := rec_pre_std_qlf_hdr.orig_sys_qualifier_ref;
                              gpr_qualifiers_tbl(i).operation := QP_GLOBALS.G_OPR_CREATE;
                           ELSE
                              --l_sec_pl_exists := 'Y';
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Sec exists1' );
                              OPEN c_sec_price_list (rec_pre_std_qlf_hdr.qualifier_attr_value_disp);
                              FETCH c_sec_price_list
                              INTO gpr_qualifiers_tbl(i).LIST_HEADER_ID;
                              CLOSE c_sec_price_list;
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'gpr_qualifiers_tbl(i).LIST_HEADER_ID'||
                                                     gpr_qualifiers_tbl(i).LIST_HEADER_ID );
                              --gpr_qualifiers_tbl(i).LIST_HEADER_ID := rec_pre_std_qlf_hdr.sec_list_header_id;
	                            --Corresponds to list_header_id for the Secondary Price List 'Testing 1019'
                              gpr_qualifiers_tbl(i).QUALIFIER_CONTEXT := 'MODLIST';
                              gpr_qualifiers_tbl(i).QUALIFIER_ATTRIBUTE := 'QUALIFIER_ATTRIBUTE4';
			                        --Corresponds to Qualifier Attribute 'Price List'
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Sec exists1.2' );
                              gpr_qualifiers_tbl(i).QUALIFIER_ATTR_VALUE := l_list_header_id;
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Primary Pricelist gpr_qualifiers_tbl(i).QUALIFIER_ATTR_VALUE'||
                                                     gpr_qualifiers_tbl(i).QUALIFIER_ATTR_VALUE );
                              gpr_qualifiers_tbl(i).COMPARISON_OPERATOR_CODE := '=';
                              gpr_qualifiers_tbl(i).qualifier_precedence := rec_pre_std_qlf_hdr.qualifier_precedence;--Added on 22OCT as prec was not converted
                              gpr_qualifiers_tbl(i).attribute10 := rec_pre_std_qlf_hdr.orig_sys_qualifier_ref;
                              gpr_qualifiers_tbl(i).attribute15 := rec_pre_std_qlf_hdr.batch_id;
                              gpr_qualifiers_tbl(i).OPERATION := QP_GLOBALS.G_OPR_CREATE;
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Sec exists2' );
                           END IF;
                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After qualifier assignment' );



                     --   IF l_sec_pl_exists = 'Y' THEN
                           FOR x_ind IN 1..gpr_qualifiers_tbl.COUNT LOOP
                              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'gpr_qualifiers_tbl(x_ind).comparison_operator_code=' ||
                                                   gpr_qualifiers_tbl(x_ind).comparison_operator_code);
                              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'gpr_qualifiers_tbl(x_ind).qualifier_context=' ||
                                                   gpr_qualifiers_tbl(x_ind).qualifier_context);
                              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'gpr_qualifiers_tbl(x_ind).qualifier_attribute=' ||
                                                   gpr_qualifiers_tbl(x_ind).qualifier_attribute);
                              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'gpr_qualifiers_tbl(x_ind).qualifier_attr_value=' ||
                                                   gpr_qualifiers_tbl(x_ind).qualifier_attr_value);
                              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'gpr_qualifiers_tbl(x_ind).qualifier_grouping_no=' ||
                                                   gpr_qualifiers_tbl(x_ind).qualifier_grouping_no);
                              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'gpr_qualifiers_tbl(x_ind).qualifier_precedence=' ||
                                                   gpr_qualifiers_tbl(x_ind).qualifier_precedence);
                              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'gpr_qualifiers_tbl(x_ind).start_date_active=' ||
                                                   gpr_qualifiers_tbl(x_ind).start_date_active);
                              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'gpr_qualifiers_tbl(x_ind).end_date_active=' ||
                                                   gpr_qualifiers_tbl(x_ind).end_date_active);
                           END LOOP;


                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After sec pricelist assign' );
                           ---------qual add end----------------------------------------------------------------

                           BEGIN
                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Calling api to create SECONDARY pricelist ' );
                              QP_QUALIFIER_RULES_PUB.Process_Qualifier_Rules
                                       (   p_api_version_number            => 1
                                       ,   p_init_msg_list                 => FND_API.G_FALSE
                                       ,   p_return_values                 => FND_API.G_FALSE
                                       ,   p_commit                        => FND_API.G_FALSE
                                       ,   x_return_status                 => gpr_return_status
                                       ,   x_msg_count                     => gpr_msg_count
                                       ,   x_msg_data                      => gpr_msg_data
                                       ,   p_QUALIFIERS_tbl                => gpr_qualifiers_tbl
                                       ,   x_QUALIFIER_RULES_rec           => ppr_qualifier_rules_rec
                                       ,   x_QUALIFIER_RULES_val_rec       => ppr_qualifier_rules_val_rec
                                       ,   x_QUALIFIERS_tbl                => ppr_qualifiers_tbl
                                       ,   x_QUALIFIERS_val_tbl            => ppr_qualifiers_val_tbl
                                      );

                              IF gpr_return_status IN ( 'E', 'U' )
                              THEN
                                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.6');
                                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error Status ' || gpr_return_status );

                                 ---*********----------
                                 gpr_msg_data  := '';
                                 gpr_msg_data2 := '';
                                 --x_grp_error   := x_grp_error + x_success_temp;
                                 --x_error_record:= x_error_record + 1;
                                 ---*********----------

                                 FOR k IN 1 .. gpr_msg_count
                                 LOOP
                                    gpr_msg_data := substr(oe_msg_pub.get ( p_msg_index => k, p_encoded => 'F' ),1,160);
                                    gpr_msg_data2 := substr(gpr_msg_data2 || LTRIM ( RTRIM ( gpr_msg_data )),1,200);
                                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error Msg... =>' || gpr_msg_data );
                                 END LOOP;

                                 --xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error Msg..... =>' || gpr_msg_data2 );
                                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                                 --ROLLBACK;
                                 xx_emf_pkg.error ( p_severity                 => xx_emf_cn_pkg.cn_medium
                                                  , p_category                 => xx_emf_cn_pkg.cn_stg_apicall
                                                  --, p_error_text               => gpr_msg_data2
                                                  , p_error_text               =>gpr_msg_data
                                               -- , p_record_identifier_1      => cur_rec.name--xx_qp_hdrs_tbl_type ( l_header_index ).NAME --DROY MESSAGE UNIFORMITY
                                                  , p_record_identifier_2      => rec_pre_std_qlf_hdr.orig_sys_header_ref
                                                  --, p_record_identifier_2      => rec_pre_std_qlf_hdr.orig_sys_qualifier_ref
                                                  , p_record_identifier_3      => NULL
                                                  );


                                 mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                            -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                             , rec_pre_std_qlf_hdr.orig_sys_header_ref
                                                             , NULL
                                                             , rec_pre_std_qlf_hdr.orig_sys_qualifier_ref
                                                             , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                             );

                                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.7');
                                 x_qlf_err_flag := 'Y';
                                 -- ROLLBACK;

                               --    COMMIT;
                              END IF;

                              IF ppr_qualifiers_tbl.count > 0 THEN
                                    FOR k in 1 .. ppr_qualifiers_tbl.count LOOP

                                       IF ppr_qualifiers_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                          xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Qualifier Creation Failed' );
                                          x_qlf_err_flag := 'Y';
                                          mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                            -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                             , rec_pre_std_qlf_hdr.orig_sys_header_ref
                                                             , NULL
                                                             , rec_pre_std_qlf_hdr.orig_sys_qualifier_ref
                                                             , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                             );
                                       END IF;

                                    END LOOP;

                                    IF NVL(x_qlf_err_flag,'X') <> 'Y' THEN
                                       xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Successful Individual Qualifier Creation' );
                                    END IF;

                              END IF;




                           EXCEPTION
                              WHEN OTHERS THEN
                                 x_qlf_err_flag := 'Y';
                                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'When others in Qualifier Creation' );
                                 xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                                            ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                                            ,p_error_text               => gpr_msg_data
                                            ,p_record_identifier_1      => rec_prc_hdr_qlf_exists.orig_sys_header_ref
                                           -- ,p_record_identifier_2      => rec_pre_std_qlf_hdr.name
                                           );
                           END;
--                        END IF;

                     -------------------------Qualifier End-----------------------------------------------------------
                      --fnd_file.put_line(fnd_file.log,'File name '||OE_DEBUG_PUB.G_DIR||'/'||OE_DEBUG_PUB.G_FILE);
                      EXCEPTION
                         WHEN OTHERS THEN
                         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'When Others in qualifier loop :'||SQLERRM );
                         x_qlf_err_flag := 'Y';
                      END;
                   END LOOP;--end loop for rec_pre_std_qlf_hdr

                   IF NVL(x_qlf_err_flag,'X') <> 'Y' THEN

                              BEGIN
                                 SELECT count(1)
                                  INTO  x_stg_qlf_count
                                  FROM  xx_qp_pr_list_qlf_pre
                                 WHERE  orig_sys_header_ref = rec_prc_hdr_qlf_exists.orig_sys_header_ref
                                   AND  batch_id =  rec_prc_hdr_qlf_exists.batch_id;

                                 SELECT count(1)
                                  INTO  x_tab_qlf_count
                                  FROM  qp_qualifiers
                                 WHERE  qualifier_attr_value = TO_CHAR(l_list_header_id)
                                  AND   attribute15 =  rec_prc_hdr_qlf_exists.batch_id;

                                 IF x_stg_qlf_count <> x_tab_qlf_count THEN
                                    x_qlf_err_flag := 'Y';
                                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Qualifier count Calculation mismatch' );
                                    ROLLBACK;
                                 ELSE
                                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Successful Qualifier Set Creation' );
                                    COMMIT;
                                 END IF;

                              EXCEPTION
                                 WHEN OTHERS THEN
                                    x_qlf_err_flag := 'Y';
                                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'When others in Qualifier count Calculation' );
                              END;


                   ELSE
                      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Failure ModList Qualifier Set Creation - Rollback' );
                      ROLLBACK;
                   END IF;

               EXCEPTION
                  WHEN e_no_header_found THEN
                       xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                                            ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                                            ,p_error_text               => gpr_msg_data
                                            ,p_record_identifier_1      => rec_prc_hdr_qlf_exists.orig_sys_header_ref
                                           -- ,p_record_identifier_2      => rec_pre_std_qlf_hdr.name
                                           );
                                      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg =>'||gpr_msg_data);

                                      mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                                 , rec_prc_hdr_qlf_exists.orig_sys_header_ref
                                                                 , NULL
                                                                 , NULL
                                                                , 'No header found for qualifier creation'
                                                               );
                      WHEN OTHERS THEN
                         xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                                            ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                                            ,p_error_text               => gpr_msg_data
                                            ,p_record_identifier_1      => rec_prc_hdr_qlf_exists.orig_sys_header_ref
                                           -- ,p_record_identifier_2      => rec_pre_std_qlf_hdr.name
                                           );
                                      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg =>'||gpr_msg_data);

                                      mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                                 , rec_prc_hdr_qlf_exists.orig_sys_header_ref
                                                                 , NULL
                                                                 , NULL
                                                                , 'When othes in main'
                                                               );
                END ;  --End for begin after main exists for loop
            END LOOP; --for rec_prc_hdr_qlf_exists
         EXCEPTION
            WHEN OTHERS THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'When Others error '||SQLERRM);
                         xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                                            ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                                            ,p_error_text               => gpr_msg_data
                                          --  ,p_record_identifier_1      => rec_prc_hdr_qlf_exists.orig_sys_header_ref
                                           -- ,p_record_identifier_2      => rec_pre_std_qlf_hdr.name
                                           );
         END;
         ---End Adding Qualifiers-----------------

         create_records_for_api_error ;

      RETURN x_error_code;
      END process_data;

      PROCEDURE update_record_count
      IS
         CURSOR c_get_total_cnt
         IS
            SELECT SUM ( tot_count ) total_count
              FROM ( SELECT COUNT ( 1 ) tot_count
                      FROM xx_qp_pr_list_hdr_pre
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id

                    ) a;

         x_total_cnt     NUMBER;

         CURSOR c_get_error_cnt
         IS
            SELECT SUM ( a.error_count ) error_count
              FROM ( SELECT COUNT ( 1 ) error_count
                      FROM xx_qp_pr_list_hdr_pre
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err
                   ) a;

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT ( 1 ) warn_count
              FROM xx_qp_pr_list_hdr_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;


         x_warn_cnt      NUMBER;

         CURSOR c_get_success_cnt
         IS
            SELECT SUM ( a.succ_count ) succ_count
              FROM ( SELECT COUNT ( 1 ) succ_count
                      FROM xx_qp_pr_list_hdr_pre
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND process_code = xx_emf_cn_pkg.cn_process_data
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_success
                    ) a;




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

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Success count ' || (x_grp_success));
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Error count ' || (x_grp_error));
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Success count ' || (x_success_record));
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Success count header' || (x_success_header));
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error count ' || (x_error_record ));
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'x_success_cnt ' || (x_success_cnt));
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'x_error_cnt ' || (x_error_cnt));

         --count is found based on count variable changed by --

         xx_emf_pkg.update_recs_cnt ( p_total_recs_cnt        => x_total_cnt
                                    , p_success_recs_cnt      => x_success_cnt
                                    , p_warning_recs_cnt      => x_warn_cnt
                                    , p_error_recs_cnt        => x_error_cnt
                                    );
         /*
         xx_emf_pkg.update_recs_cnt ( p_total_recs_cnt        => x_total_cnt
                                    , p_success_recs_cnt      => x_grp_success
                                    , p_warning_recs_cnt      => x_warn_cnt
                                    , p_error_recs_cnt        => (x_total_cnt - x_grp_success )
                                    );   */
      END;
   --  l_max_error  VARCHAR2(10);
   BEGIN
      retcode := xx_emf_cn_pkg.cn_success;
      -- Need to maintain the version on the files.
              -- when updating the package remember to incrimint the version such that it can be checked in the log file from front end.

      /*xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxinvitemcnvvl_pks);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxinvitemcnvvl_pkb);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxinvitemcnvtl_pks);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxinvitemcnvtl_pkb);*/

      -- Start CCID099 changes
      -- Set environment for EMF (Error Management Framework)
      -- If you want the process to continue even after the emf env not being set
      -- you must make p_required_flag from CN_YES to CN_NO
      -- If you do not pass proper value then it will be considered as CN_YES
      set_cnv_env ( p_batch_id => p_batch_id, p_required_flag => xx_emf_cn_pkg.cn_yes );
      -- include all the parameters to the conversion main here
      -- as medium log messages
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'Starting main process with the following parameters' );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'Main:Param - p_batch_id ' || p_batch_id );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'Main:Param - p_restart_flag ' || p_restart_flag );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'Main:Param - p_override_flag ' || p_override_flag );
      --xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'Main:Param - p_header_line ' || p_header_line);
      -- End CCID099 changes

      -- Call procedure to update records with the current request_id
      -- So that we can process only those records
      -- This gives a better handling of restartability
      mark_records_for_processing ( p_restart_flag => p_restart_flag, p_override_flag => p_override_flag );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'Main:Param - p_override_flag ' || p_override_flag );

      -- Once the records are identified based on the input parameters
      -- Start with pre-validations
      IF NVL ( p_override_flag, xx_emf_cn_pkg.cn_no ) = xx_emf_cn_pkg.cn_no
      THEN
         -- Set the stage to Pre Validations
         set_stage ( xx_emf_cn_pkg.cn_preval );
         -- CCID099 changes
         -- Change the validations package to the appropriate package name
         -- Modify the parameters as required
         -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
         -- PRE_VALIDATIONS SHOULD BE RETAINED
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'calling pre_validations: batch_id' || p_batch_id );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'err code 1:' || x_error_code );
         x_error_code := xx_qp_prc_list_cnv_val_pkg.pre_validations ( p_batch_id );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'err code 2' || x_error_code );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'After pre-validations X_ERROR_CODE ' || x_error_code );
         -- Update process code of staging records
         -- Also move the successful records to pre-interface tables
         update_staging_records ( xx_emf_cn_pkg.cn_success );
         --xx_emf_pkg.propagate_error (x_error_code);
         --Marking duplicate records in Organization Assignment Table
         -----mark_duplicate_combination;
         /* Tempoaray Making This call Disabled*/

              --x_error_code := update_line_ref; --DROY EXMINE AND UPD CORR
              --xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'update_line_ref' || x_error_code );
              --xx_emf_pkg.propagate_error ( x_error_code );

         x_error_code := move_rec_pre_standard_table;
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'move_rec_pre_standard_table' || x_error_code );
         --xx_emf_pkg.propagate_error ( x_error_code );
         -- making logical grouping over the orig_sys_line_ref in Pre Interface table


      END IF;

 -- Once pre-validations are complete the loop through the pre-interface records
      -- and perform data validations on this table
      -- Set the stage to data Validations
        -----------------------------------------------------
----------( Stage 3: DATA VALIDATION)-----------------
         ------------------------------------------------------
      set_stage ( xx_emf_cn_pkg.cn_valid );

      OPEN c_xx_asl_pre_std_hdr ( xx_emf_cn_pkg.cn_preval );

      LOOP
         FETCH c_xx_asl_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'BULK COLLECT' );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                              , 'Before Loop - x_pre_std_hdr_table.count ' || x_pre_std_hdr_table.COUNT
                              );

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               /*xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                                  'item_number_genaration'
                                               || x_error_code
                              );
               item_number_genaration(x_pre_std_hdr_table (i));*/
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Before data Validation' );
               -- Perform header level Base App Validations
               /* This parameter p_header_line is added to process line level data
                If this p_header_line parameter is N then It means data has come for Header only

               */
               x_error_code := xx_qp_prc_list_cnv_val_pkg.data_validations (x_pre_std_hdr_table ( i )
                                                                             --,p_header_line
                                                                              );
              -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After data Validation'||p_header_line );
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                    ,    'x_error_code for  '
                                      || x_pre_std_hdr_table ( i ).record_number
                                      || ' is '
                                      || x_error_code
                                    );
               update_record_status ( x_pre_std_hdr_table ( i ), x_error_code );
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After Record Status : '||g_stage );
               xx_emf_pkg.propagate_error ( x_error_code );
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
               WHEN xx_emf_pkg.g_e_rec_error
               THEN
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'Record Level Error in Data Validations' );
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.cn_rec_err );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'Process Level Error in Data Validations' );
                  update_pre_interface_records ( x_pre_std_hdr_table );
                  raise_application_error ( -20199, xx_emf_cn_pkg.cn_prc_err );
               WHEN OTHERS
               THEN
                  /* Added by   when others is occur then update the status */
                  update_record_status ( x_pre_std_hdr_table ( i ), x_error_code );
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After DV Record Status : '||g_stage );
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'When Others Error in Data Validations' );
                  xx_emf_pkg.error ( xx_emf_cn_pkg.cn_medium
                                   , xx_emf_cn_pkg.cn_tech_error
                                   , xx_emf_cn_pkg.cn_exp_unhand
                                   , x_pre_std_hdr_table ( i ).record_number
                                   );
            END;
         END LOOP;

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'x_pre_std_hdr_table.count ' || x_pre_std_hdr_table.COUNT );
         update_pre_interface_records ( x_pre_std_hdr_table );
         x_pre_std_hdr_table.DELETE;
         EXIT WHEN c_xx_asl_pre_std_hdr%NOTFOUND;
      END LOOP;

      IF c_xx_asl_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_asl_pre_std_hdr;
      END IF;


      --------------------------------Data validation for lines--------DROY add for qualifier as well
     /* OPEN c_xx_asl_pre_std_lines ( xx_emf_cn_pkg.cn_preval );

      LOOP
         FETCH c_xx_asl_pre_std_lines
         BULK COLLECT INTO x_pre_std_lines_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'BULK COLLECT' );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                              , 'Before Loop - x_pre_std_lines_table.count ' || x_pre_std_lines_table.COUNT
                              );

         FOR i IN 1 .. x_pre_std_lines_table.COUNT
         LOOP
            BEGIN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                                  'item_number_genaration'
                                               || x_error_code
                              );
               item_number_genaration(x_pre_std_hdr_table (i));
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Before line data Validation' );
               -- Perform header level Base App Validations
                --This parameter p_header_line is added to process line level data
                --If this p_header_line parameter is N then It means data has come for Header only


               x_error_code := xx_qp_prc_list_cnv_val_pkg.data_validations (x_pre_std_lines_table ( i )
                                                                             --,p_header_line
                                                                              );
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After data Validation');--||p_header_line );
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                    ,    'x_error_code for  '
                                      || x_pre_std_lines_table ( i ).record_number
                                      || ' is '
                                      || x_error_code
                                    );
               update_record_status ( x_pre_std_lines_table ( i ), x_error_code );
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After Record Status : '||g_stage );
               xx_emf_pkg.propagate_error ( x_error_code );
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
               WHEN xx_emf_pkg.g_e_rec_error
               THEN
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'Record Level Error in Data Validations' );
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.cn_rec_err );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'Process Level Error in Data Validations' );
                  update_pre_interface_records ( x_pre_std_lines_table );
                  raise_application_error ( -20199, xx_emf_cn_pkg.cn_prc_err );
               WHEN OTHERS
               THEN
                  -- Added by   when others is occur then update the status
                  update_record_status ( x_pre_std_hdr_table ( i ), x_error_code );
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After DV Record Status : '||g_stage );
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'When Others Error in Data Validations' );
                  xx_emf_pkg.error ( xx_emf_cn_pkg.cn_medium
                                   , xx_emf_cn_pkg.cn_tech_error
                                   , xx_emf_cn_pkg.cn_exp_unhand
                                   , x_pre_std_hdr_table ( i ).record_number
                                   );
            END;
         END LOOP;


         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'x_pre_std_lines_table.count ' || x_pre_std_lines_table.COUNT );
         update_pre_interface_records ( x_pre_std_lines_table );
         x_pre_std_lines_table.DELETE;
         EXIT WHEN c_xx_asl_pre_std_lines%NOTFOUND;
      END LOOP;

      IF c_xx_asl_pre_std_lines%ISOPEN
      THEN
         CLOSE c_xx_asl_pre_std_lines;
      END IF;*/


 x_error_code := xx_qp_prc_list_cnv_val_pkg.data_validations (p_batch_id);
      UPDATE xx_qp_pr_list_lines_pre
      SET process_code  = g_stage
      WHERE (ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
             OR  process_code = xx_emf_cn_pkg.CN_STG_DATAVAL
             );
      COMMIT;

      ----------------------END LINE VALIDATIONS-------------------------------------------

      ------------------Start Qualifier Data Validations------------------------------------
      -- Loop For Qualifier - Data Validation
        OPEN c_xx_cnv_pre_std_qlf_hdr ( xx_emf_cn_pkg.CN_PREVAL);
        LOOP
                FETCH c_xx_cnv_pre_std_qlf_hdr
                BULK COLLECT INTO x_pre_std_hdr_qlf_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;


                FOR i IN 1 .. x_pre_std_hdr_qlf_table.COUNT
                LOOP
                        --1010
                        BEGIN
                                -- Perform header level Base App Validations
                                x_error_code := xx_qp_prc_list_cnv_val_pkg.data_validations (
                                                        x_pre_std_hdr_qlf_table (i));
                                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_hdr_qlf_table (i).record_number|| ' is ' || x_error_code);

                                update_record_status (x_pre_std_hdr_qlf_table (i), x_error_code);
                                xx_emf_pkg.propagate_error (x_error_code);
                        EXCEPTION
                                -- If HIGH error then it will be propagated to the next level
                                -- IF the process has to continue maintain it as a medium severity
                                WHEN xx_emf_pkg.G_E_REC_ERROR
                                THEN
                                        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.CN_REC_ERR);
                                WHEN xx_emf_pkg.G_E_PRC_ERROR
                                THEN
                                        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Process Level Error in Data Validations');
                                        update_pre_interface_records ( x_pre_std_hdr_qlf_table);
                                        RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                                WHEN OTHERS
                                THEN
                                        xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_hdr_qlf_table (i).record_number);
                        END;

                END LOOP;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_hdr_qlf_table.count ' || x_pre_std_hdr_qlf_table.COUNT );

                update_pre_interface_records ( x_pre_std_hdr_qlf_table);

                x_pre_std_hdr_qlf_table.DELETE;

                EXIT WHEN c_xx_cnv_pre_std_qlf_hdr%NOTFOUND;
        END LOOP;

        IF c_xx_cnv_pre_std_qlf_hdr%ISOPEN THEN
                CLOSE c_xx_cnv_pre_std_qlf_hdr;
        END IF;

      -----------------------------End Qualifier Validations------------------------------


      -- Once data-validations are complete the loop through the pre-interface records
      -- and perform data derivations on this table
      -- Set the stage to data derivations

      set_stage ( xx_emf_cn_pkg.cn_derive );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'batch_id  ' || g_batch_id || ' is ' || x_error_code );

      OPEN c_xx_asl_pre_std_hdr ( xx_emf_cn_pkg.cn_valid );

      LOOP
         FETCH c_xx_asl_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'table count  ' || x_pre_std_hdr_table.COUNT );

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               -- Perform header level Base App Validations
               x_error_code := xx_qp_prc_list_cnv_val_pkg.data_derivations ( x_pre_std_hdr_table ( i ));
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                    ,    'After data derivation x_error_code for  '
                                      || x_pre_std_hdr_table ( i ).record_number
                                      || ' is '
                                      || x_error_code
                                    );
               update_record_status ( x_pre_std_hdr_table ( i ), x_error_code );
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After DD Record Status : '||g_stage );
               xx_emf_pkg.propagate_error ( x_error_code );
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
               WHEN xx_emf_pkg.g_e_rec_error
               THEN
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'Record Level Error in Data Derivation' );
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.cn_rec_err );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'Process Level Error in Data derivations' );
                  update_pre_interface_records ( x_pre_std_hdr_table );
                  raise_application_error ( -20199, xx_emf_cn_pkg.cn_prc_err );
               WHEN OTHERS
               THEN
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'When others Error in Data Derivation' );
                  xx_emf_pkg.error ( xx_emf_cn_pkg.cn_medium
                                   , xx_emf_cn_pkg.cn_tech_error
                                   , xx_emf_cn_pkg.cn_exp_unhand
                                   , x_pre_std_hdr_table ( i ).record_number
                                   );
            END;
         END LOOP;

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'x_pre_std_hdr_table.count ' || x_pre_std_hdr_table.COUNT );
         update_pre_interface_records ( x_pre_std_hdr_table );
         x_pre_std_hdr_table.DELETE;
         EXIT WHEN c_xx_asl_pre_std_hdr%NOTFOUND;
      END LOOP;

      IF c_xx_asl_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_asl_pre_std_hdr;
      END IF;

      -----Start line data derivations-----------DROY ADD FOR QUALIFIERS--------------------

      -- Once data-validations are complete the loop through the pre-interface records
      -- and perform data derivations on this table
      -- Set the stage to data derivations
      set_stage ( xx_emf_cn_pkg.cn_derive );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'batch_id  ' || g_batch_id || ' is ' || x_error_code );

     /* OPEN c_xx_asl_pre_std_lines ( xx_emf_cn_pkg.cn_valid );

      LOOP
         FETCH c_xx_asl_pre_std_lines
         BULK COLLECT INTO x_pre_std_lines_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'table count  ' || x_pre_std_lines_table.COUNT );

         FOR i IN 1 .. x_pre_std_lines_table.COUNT
         LOOP
            BEGIN
               -- Perform line level Base App Validations
               x_error_code := xx_qp_prc_list_cnv_val_pkg.data_derivations ( x_pre_std_lines_table ( i ));
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                    ,    'After data derivation x_error_code for  '
                                      || x_pre_std_lines_table ( i ).record_number
                                      || ' is '
                                      || x_error_code
                                    );
               update_record_status ( x_pre_std_lines_table ( i ), x_error_code );
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After DD Record Status : '||g_stage );
               xx_emf_pkg.propagate_error ( x_error_code );
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
               WHEN xx_emf_pkg.g_e_rec_error
               THEN
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'Record Level Error in Data Derivation' );
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.cn_rec_err );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'Process Level Error in Data derivations' );
                  update_pre_interface_records ( x_pre_std_hdr_table );
                  raise_application_error ( -20199, xx_emf_cn_pkg.cn_prc_err );
               WHEN OTHERS
               THEN
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'When others Error in Data Derivation' );
                  xx_emf_pkg.error ( xx_emf_cn_pkg.cn_medium
                                   , xx_emf_cn_pkg.cn_tech_error
                                   , xx_emf_cn_pkg.cn_exp_unhand
                                   , x_pre_std_hdr_table ( i ).record_number
                                   );
            END;
         END LOOP;

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'x_pre_std_hdr_table.count ' || x_pre_std_lines_table.COUNT );
         update_pre_interface_records ( x_pre_std_lines_table );
         x_pre_std_lines_table.DELETE;
         EXIT WHEN c_xx_asl_pre_std_lines%NOTFOUND;
      END LOOP;

      IF c_xx_asl_pre_std_lines%ISOPEN
      THEN
         CLOSE c_xx_asl_pre_std_lines;
      END IF;*/

      UPDATE xx_qp_pr_list_lines_pre
      SET process_code  = g_stage
      WHERE (ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
             );
      COMMIT;

      -----End line data derivations ------------------------------------------------------

      -----Start Qualifier data derivations-----------------------------------------------
      -- Loop For Qualifier - Data Derivation
        OPEN c_xx_cnv_pre_std_qlf_hdr ( xx_emf_cn_pkg.CN_VALID);
        LOOP
                FETCH c_xx_cnv_pre_std_qlf_hdr
                BULK COLLECT INTO x_pre_std_hdr_qlf_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_hdr_qlf_table.COUNT before data derivation '||x_pre_std_hdr_qlf_table.COUNT);

                FOR i IN 1 .. x_pre_std_hdr_qlf_table.COUNT
                LOOP

                        BEGIN

                                -- Perform header level Base App Validations
                                x_error_code := xx_qp_prc_list_cnv_val_pkg.data_derivations (
                                                        x_pre_std_hdr_qlf_table (i));
                                --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_hdr_table (i).record_number|| ' is ' || x_error_code);

                                update_record_status (x_pre_std_hdr_qlf_table (i), x_error_code);
                                xx_emf_pkg.propagate_error (x_error_code);
                        EXCEPTION
                                -- If HIGH error then it will be propagated to the next level
                                -- IF the process has to continue maintain it as a medium severity
                                WHEN xx_emf_pkg.G_E_REC_ERROR
                                THEN
                                        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.CN_REC_ERR);
                                WHEN xx_emf_pkg.G_E_PRC_ERROR
                                THEN
                                        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Process Level Error in Data derivations');
                                        update_pre_interface_records ( x_pre_std_hdr_qlf_table);
                                        RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                                WHEN OTHERS
                                THEN
                                        xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND,
                                                         x_pre_std_hdr_qlf_table(i).record_number);
                        END;

                END LOOP;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_hdr_qlf_table.count ' || x_pre_std_hdr_qlf_table.COUNT );

                update_pre_interface_records (x_pre_std_hdr_qlf_table);

                x_pre_std_hdr_qlf_table.DELETE;

                EXIT WHEN c_xx_cnv_pre_std_qlf_hdr%NOTFOUND;
        END LOOP;

        IF c_xx_cnv_pre_std_qlf_hdr%ISOPEN THEN
                CLOSE c_xx_cnv_pre_std_qlf_hdr;
        END IF;


      -----End Qualifier data derivations-------------------------------------------------

      -- Set the stage to Post Validations
      set_stage ( xx_emf_cn_pkg.cn_postval );
      -- CCID099 changes
      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
      -- PRE_VALIDATIONS SHOULD BE RETAINED
      x_error_code := xx_qp_prc_list_cnv_val_pkg.post_validations (p_batch_id);
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After post-validations X_ERROR_CODE ' || x_error_code );
      mark_records_complete ( xx_emf_cn_pkg.cn_postval );
      ---DEB DELETE
      /*for CUR_REC in (select * FROM xx_qp_pr_list_hdr_pre) LOOP
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'pROCESS CODE INDIVIDUAL ' || cur_rec.process_code );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'error CODE INDIVIDUAL ' || cur_rec.error_code );
      END LOOP;*/
      ---DEB DELETE
      --xx_emf_pkg.propagate_error ( x_error_code );
      IF p_validate_and_load = g_validate_and_load THEN
      -- Set the stage to Process Data
      set_stage ( xx_emf_cn_pkg.cn_process_data );
      --Call Process Data
      x_error_code := process_data;
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After process data X_ERROR_CODE ' || x_error_code );
      mark_records_complete ( xx_emf_cn_pkg.cn_process_data );
      END IF; -- For validate only flag check
      --xx_emf_pkg.propagate_error ( x_error_code );
      update_record_count;
      --x_error_code:=process_data_cross_reference;
      --xx_emf_pkg.propagate_error (x_error_code);
      ---------*******************-------------------
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Total record'||x_total_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Success record'||x_success_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error record'||x_error_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Total'||x_grp_total );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Success'||x_grp_success );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Error '||x_grp_error );
      /* Report for Header Information  */
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, '*************************************************');
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Total number of Header record count : '||x_total_header );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, '*************************************************');
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, '*************************************************');
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Total number of Header record success : '||x_success_header );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, '*************************************************');

      xx_emf_pkg.create_report;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Checking if this is OK' );
         fnd_file.put_line ( fnd_file.output, xx_emf_pkg.cn_env_not_set );
         -- comment for get report by suman---------
         --retcode := xx_emf_cn_pkg.cn_rec_err;
         update_record_count;
         xx_emf_pkg.create_report;
      ---------*******************-------------------
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Total record'||x_total_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Success record'||x_success_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error record'||x_error_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Total'||x_grp_total );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Success'||x_grp_success );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Error '||x_grp_error );

      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'xyz1: ' || SQLERRM );
         retcode := xx_emf_cn_pkg.cn_rec_err;
         update_record_count;
         xx_emf_pkg.create_report;
      ---------*******************-------------------
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Total record'||x_total_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Success record'||x_success_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error record'||x_error_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Total'||x_grp_total );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Success'||x_grp_success );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Error '||x_grp_error );

      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'xyz2: ' || SQLERRM );
         retcode := xx_emf_cn_pkg.cn_prc_err;
         update_record_count;
         xx_emf_pkg.create_report;
      ---------*******************-------------------
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Total record'||x_total_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Success record'||x_success_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error record'||x_error_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Total'||x_grp_total );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Success'||x_grp_success );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Error '||x_grp_error );

      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'xyz3: ' || SQLERRM );
         retcode := xx_emf_cn_pkg.cn_prc_err;
         update_record_count;
         xx_emf_pkg.create_report;
      ---------*******************-------------------
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Total record'||x_total_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Success record'||x_success_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error record'||x_error_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Total'||x_grp_total );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Success'||x_grp_success );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Error '||x_grp_error );

   END main;
END xx_qp_prc_list_cnv_pkg;
/
