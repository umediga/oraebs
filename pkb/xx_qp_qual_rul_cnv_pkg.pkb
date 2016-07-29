DROP PACKAGE BODY APPS.XX_QP_QUAL_RUL_CNV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_QP_QUAL_RUL_CNV_PKG" AS
/*
 Created By     : Debjani Roy
 Creation Date  : 11-Jun-2013
 File Name      : XXQPPRCQUALTL.pkb
 Description    : This script creates the body of the package xx_price_list_qualifier_pkg

----------------------------*------------------------------------------------------------------
-- Conversion Checklist ID  *  Change Required By Developer                                  --
----------------------------*------------------------------------------------------------------

----------------------------*------------------------------------------------------------------

COMMON GUIDELINES REGARDING EMF
-------------------------------

1. ALL LOW LEVEL EMF MESSAGES CAN BE RETAINED
2. HARD CODING OF EMF MESSAGES ARE ALLOWED IN THE CODE
3. ANY OTHER HARD CODING SHOULD BE DEALT BY CONSTANTS PACKAGE
4. EXCEPTION HANDLING SHOULD BE LEFT AS IS MOST OF THE PLACES UNLESS SPECIFIED

 Change History:

Version Date        Name                  Remarks
------- ----------- ---------            ---------------------------------------
1.0     11-Jun-2013 Debjani Roy  Initial development.
-------------------------------------------------------------------------
*/
    x_sec_total_count                     NUMBER :=0;
    x_sec_success_count                   NUMBER :=0;
    x_sec_error_count                     NUMBER :=0;
    -- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
    -- START RESTRICTIONS
    PROCEDURE set_cnv_env ( p_batch_id VARCHAR2,
                            p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES)
    IS
            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
            G_BATCH_ID := p_batch_id;
            -- Set the environment
            x_error_code := xx_emf_pkg.set_env;
            --x_error_code := xx_emf_pkg.set_env ('XXQPPRCQUAL');

            IF NVL (p_required_flag, xx_emf_cn_pkg.CN_YES) <> xx_emf_cn_pkg.CN_NO THEN
                    xx_emf_pkg.propagate_error(x_error_code);
            END IF;
    EXCEPTION
            WHEN OTHERS THEN
                    RAISE xx_emf_pkg.G_E_ENV_NOT_SET;
    END set_cnv_env;

    PROCEDURE mark_records_for_processing
    (
            p_restart_flag IN VARCHAR2,
            p_override_flag IN VARCHAR2
    )
    IS
            PRAGMA AUTONOMOUS_TRANSACTION;

    BEGIN
            -- If the override is set records should not be purged from the pre-interface tables
            IF p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS
            THEN

               IF p_override_flag = xx_emf_cn_pkg.CN_NO
               THEN
                  -- purge from pre-interface tables and oracle standard tables
                   DELETE
                       FROM XX_QP_RULES_QLF_PRE
                      WHERE batch_id = G_BATCH_ID;

                           UPDATE XX_QP_RULES_QLF_STG
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_NULL,
                               process_code = xx_emf_cn_pkg.CN_NEW
                         WHERE batch_id = G_BATCH_ID;

               ELSE

                           UPDATE XX_QP_RULES_QLF_PRE
                           SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               request_id = xx_emf_pkg.G_REQUEST_ID
                         WHERE batch_id = G_BATCH_ID;

               END IF;
        /* We are using API for this conversion. so, these deletes not required*/
                   -- DELETE FROM xx_oracle_standard_table
                   --  WHERE attribute1 = G_BATCH_ID;

            ELSIF p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS
               THEN
                  IF p_override_flag = xx_emf_cn_pkg.CN_NO
                  THEN
                            -- Update staging table
                     UPDATE XX_QP_RULES_QLF_STG
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_NULL,
                               process_code = xx_emf_cn_pkg.CN_NEW
                         WHERE batch_id = G_BATCH_ID
                           AND (process_code = xx_emf_cn_pkg.CN_NEW
                                OR (process_code = xx_emf_cn_pkg.CN_PREVAL
                                    AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
                                    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                                    )
                                );
                  END IF;

                    -- Update pre-interface table
                    -- Scenario 1 Pre-Validation Stage
                  UPDATE XX_QP_RULES_QLF_STG a
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_NULL,
                           process_code = xx_emf_cn_pkg.CN_NEW
                     WHERE batch_id = G_BATCH_ID
                       AND EXISTS (
                            SELECT 1
                              FROM XX_QP_RULES_QLF_PRE
                             WHERE batch_id = G_BATCH_ID
                               AND process_code = xx_emf_cn_pkg.CN_PREVAL
                               AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                               AND record_number = a.record_number);
                  DELETE
                      FROM XX_QP_RULES_QLF_PRE
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_PREVAL
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    -- Scenario 2 Data Validation Stage
                  UPDATE XX_QP_RULES_QLF_PRE
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_PREVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_VALID
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    -- Scenario 3 Data Derivation Stage
                  UPDATE XX_QP_RULES_QLF_PRE
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_DERIVE
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_DERIVE
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    -- Scenario 4 Post Validation Stage
                  UPDATE XX_QP_RULES_QLF_PRE
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_POSTVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_POSTVAL
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    -- Scenario 5 Process Data Stage
                  UPDATE XX_QP_RULES_QLF_PRE
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_POSTVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_ERR);

            END IF;
            COMMIT;
    END mark_records_for_processing;

    PROCEDURE set_stage (p_stage VARCHAR2)
    IS
    BEGIN
            G_STAGE := p_stage;
    END set_stage;

    PROCEDURE update_staging_records( p_error_code VARCHAR2) IS
            x_last_update_date      DATE := SYSDATE;
            x_last_updated_by        NUMBER := fnd_global.user_id;
            x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

            PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN

        UPDATE XX_QP_RULES_QLF_STG
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
    -- END RESTRICTIONS

    PROCEDURE main (
            errbuf OUT VARCHAR2,
            retcode OUT VARCHAR2,
            p_batch_id IN VARCHAR2,
            p_restart_flag IN VARCHAR2,
            p_override_flag IN VARCHAR2,
            p_validate_and_load    IN VARCHAR2
    ) IS

        x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        --x_pre_std_hdr_sec_table     g_xx_sec_prc_pre_tab_type;
        x_pre_std_hdr_qlf_table     g_xx_qlf_pre_tab_type;

        -- CURSOR FOR VARIOUS STAGES

        CURSOR c_xx_cnv_pre_std_qlf_hdr ( cp_process_status VARCHAR2) IS
        SELECT
            --
            -- Add Columns if you want
            --
               hdr.*
          FROM XX_QP_RULES_QLF_PRE hdr
         WHERE batch_id = G_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID
           AND process_code = cp_process_status
           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         ORDER BY record_number;

        /***************** For Qualifiers **************************/
        PROCEDURE update_record_status (
                p_conv_pre_std_hdr_rec  IN OUT  XX_QP_RULES_QLF_PRE%ROWTYPE,
                p_error_code            IN      VARCHAR2
        )
        IS
        BEGIN

                IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
                THEN
                        p_conv_pre_std_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                ELSE
                        p_conv_pre_std_hdr_rec.error_code := xx_qp_qual_rul_val_pkg.find_max (p_error_code
                                                                                        ,NVL (p_conv_pre_std_hdr_rec.error_code
                                                                                        , xx_emf_cn_pkg.CN_SUCCESS));
                END IF;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~Inside update_record_status For Qlf, G_STAGE=' || G_STAGE);
                p_conv_pre_std_hdr_rec.process_code := G_STAGE;

        END update_record_status;



    PROCEDURE mark_records_for_qual_api_err
            (
                    p_process_code       IN VARCHAR2
                   ,p_err_message               IN VARCHAR2
                   ,p_orig_sys_qlf_rule_ref      IN NUMBER --DROY CHANGE ACCORDINGLY
            )
            IS
                    x_last_update_date       DATE := SYSDATE;
                    x_last_updated_by        NUMBER := fnd_global.user_id;
                    x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

                    PRAGMA AUTONOMOUS_TRANSACTION;
            BEGIN
                    UPDATE XX_QP_RULES_QLF_PRE
                       SET process_code = G_STAGE,
                           error_code = xx_emf_cn_pkg.CN_REC_ERR,
                           error_desc = p_err_message,
                           last_updated_by = x_last_updated_by,
                           last_update_date = x_last_update_date,
                           last_update_login = x_last_update_login
                     WHERE batch_id        = G_BATCH_ID
                       AND request_id      = xx_emf_pkg.G_REQUEST_ID
                       --AND price_list_name             = p_name
                       --AND list_header_id  = p_list_header_id --DROY
                       AND orig_sys_qualifier_rule_ref = p_orig_sys_qlf_rule_ref
                       AND process_code      = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
                                                       , xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE
                                                       )
                       AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                       ;

                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~No of Records in Qualifier table marked with API Error=>'||SQL%ROWCOUNT);

                    /*UPDATE XX_QP_RULES_QLF_PRE
                       SET process_code = G_STAGE,
                           error_code = xx_emf_cn_pkg.CN_REC_ERR,
                           last_updated_by = x_last_updated_by,
                           last_update_date = x_last_update_date,
                           last_update_login = x_last_update_login
                     WHERE batch_id        = G_BATCH_ID
                       AND request_id      = xx_emf_pkg.G_REQUEST_ID
                       AND modifier_name   = p_mdf_name
                       AND list_type_code  = p_list_type_code
                       AND process_code      = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
                                                       , xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE
                                                       )
                       AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                       ;

                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~No of Records in Qualifier Table marked with API Error=>'||SQL%ROWCOUNT);
                    */
                    COMMIT;
            EXCEPTION
            WHEN OTHERS THEN
                xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in mark_records_for_api_error '||SQLERRM);
                --x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
            --RETURN x_error_code;

        END mark_records_for_qual_api_err;



        PROCEDURE mark_records_complete
        (
                p_process_code IN VARCHAR2

        )
        IS
                x_last_update_date      DATE := SYSDATE;
                x_last_updated_by        NUMBER := fnd_global.user_id;
                x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
                PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN


                UPDATE XX_QP_RULES_QLF_PRE
                   SET process_code = G_STAGE,
                       error_code = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
                       last_updated_by = x_last_updated_by,
                       last_update_date = x_last_update_date,
                       last_update_login = x_last_update_login
                 WHERE batch_id = G_BATCH_ID
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
                   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~No of Records for Qualifiers marked after '||p_process_code||' =>'||SQL%ROWCOUNT);

             COMMIT;
        END mark_records_complete;



        /***************** For Qualifiers **************************/
        PROCEDURE update_pre_interface_records (p_cnv_pre_std_hdr_table IN g_xx_qlf_pre_tab_type)
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
                        --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).process_code ' || p_cnv_pre_std_hdr_table(indx).process_code);
                        --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).record_number ' || p_cnv_pre_std_hdr_table(indx).record_number);

                        UPDATE XX_QP_RULES_QLF_PRE
                           SET
                                --PRICE_LIST_NAME            =    p_cnv_pre_std_hdr_table(indx).PRICE_LIST_NAME    ,
                                LIST_HEADER_ID            =    p_cnv_pre_std_hdr_table(indx).LIST_HEADER_ID    ,
                                COMPARISON_OPERATOR_CODE    =    p_cnv_pre_std_hdr_table(indx).COMPARISON_OPERATOR_CODE    ,
                             --   comparison_operator_desc    =    p_cnv_pre_std_hdr_table(indx).comparison_operator_desc    ,
                                qualifier_context        =    p_cnv_pre_std_hdr_table(indx).qualifier_context    ,
                             --   qualifier_context_desc        =    p_cnv_pre_std_hdr_table(indx).qualifier_context_desc    ,
                                qualifier_attribute        =    p_cnv_pre_std_hdr_table(indx).qualifier_attribute    ,
                                qualifier_attribute_code    =    p_cnv_pre_std_hdr_table(indx).qualifier_attribute_code    ,
                                qualifier_grouping_no        =    p_cnv_pre_std_hdr_table(indx).qualifier_grouping_no    ,
                                qualifier_attr_value        =    p_cnv_pre_std_hdr_table(indx).qualifier_attr_value    ,
                                qualifier_attr_value_disp   =    p_cnv_pre_std_hdr_table(indx).qualifier_attr_value_disp    ,
                                qualifier_precedence        =    p_cnv_pre_std_hdr_table(indx).qualifier_precedence    ,
                                excluder_flag            =    p_cnv_pre_std_hdr_table(indx).excluder_flag    ,
                                qualifier_attr_value_to        =    p_cnv_pre_std_hdr_table(indx).qualifier_attr_value_to    ,
                                start_date_active        =    p_cnv_pre_std_hdr_table(indx).start_date_active    ,
                                end_date_active            =    p_cnv_pre_std_hdr_table(indx).end_date_active    ,
                                context                =    p_cnv_pre_std_hdr_table(indx).context    ,
                          --      process_type            =    p_cnv_pre_std_hdr_table(indx).process_type    ,
                            --    lock_flag            =    p_cnv_pre_std_hdr_table(indx).lock_flag    ,
                             --   delete_flag            =    p_cnv_pre_std_hdr_table(indx).delete_flag    ,
                            --    price_list_line_index        =    p_cnv_pre_std_hdr_table(indx).price_list_line_index    ,
                            --    product_attr_val_disp        =    p_cnv_pre_std_hdr_table(indx).product_attr_val_disp    ,
                            --    pricing_attr_code        =    p_cnv_pre_std_hdr_table(indx).pricing_attr_code    , --DROY
                            --    pricing_attr_value_from_disp    =    p_cnv_pre_std_hdr_table(indx).pricing_attr_value_from_disp    ,
                            --    pricing_attr_value_to_disp    =    p_cnv_pre_std_hdr_table(indx).pricing_attr_value_to_disp    ,
                            --    attribute_status        =    p_cnv_pre_std_hdr_table(indx).attribute_status    ,
                                --interface_action_code        =    p_cnv_pre_std_hdr_table(indx).interface_action_code    ,
                            --    process_flag            =    p_cnv_pre_std_hdr_table(indx).process_flag    ,
                            --    process_status_flag        =    p_cnv_pre_std_hdr_table(indx).process_status_flag    ,
                                batch_id            =    p_cnv_pre_std_hdr_table(indx).batch_id    ,
                                created_by            =    p_cnv_pre_std_hdr_table(indx).created_by    ,
                                creation_date            =    p_cnv_pre_std_hdr_table(indx).creation_date    ,
                                request_id            =    p_cnv_pre_std_hdr_table(indx).request_id    ,
                                process_code            =    p_cnv_pre_std_hdr_table(indx).process_code    ,
                                error_code            =    p_cnv_pre_std_hdr_table(indx).error_code    ,
                            --    error_desc            =    p_cnv_pre_std_hdr_table(indx).error_desc    ,
                           --     src_file_name            =    p_cnv_pre_std_hdr_table(indx).src_file_name    ,
                                record_number            =    p_cnv_pre_std_hdr_table(indx).record_number    ,
                            --    header_record_number        =    p_cnv_pre_std_hdr_table(indx).header_record_number    ,
                             --   line_record_number        =    p_cnv_pre_std_hdr_table(indx).line_record_number    , --droy
                             --   qlfr_attr_value_to_desc        =    p_cnv_pre_std_hdr_table(indx).qlfr_attr_value_to_desc    ,
                             --   qlfr_attr_value_code        =    p_cnv_pre_std_hdr_table(indx).qlfr_attr_value_code    , --DROY
                                last_updated_by             =     x_last_updated_by,
                                last_update_date           =     x_last_update_date,
                                last_update_login         =     x_last_update_login
                         WHERE
                         record_number = p_cnv_pre_std_hdr_table(indx).record_number
                         --header_record_number = p_cnv_pre_std_hdr_table(indx).header_record_number
                         AND batch_id=G_BATCH_ID;

                END LOOP;

                COMMIT;
        END update_pre_interface_records;

        FUNCTION move_rec_pre_standard_table
        RETURN NUMBER
        IS
                x_creation_date         DATE := SYSDATE;
                x_created_by            NUMBER := fnd_global.user_id;
                x_last_update_date      DATE := SYSDATE;
                x_last_updated_by        NUMBER := fnd_global.user_id;
                x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

                x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

                l_request_id NUMBER := 0;

                PRAGMA AUTONOMOUS_TRANSACTION;

        BEGIN
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside move_rec_pre_standard_table');

                -- Select only the appropriate columns that are required to be inserted into the
                -- Pre-Interface Table and insert from the Staging Table
  BEGIN
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Insert into XX_QP_RULES_QLF_PRE');
                INSERT INTO XX_QP_RULES_QLF_PRE
                (
                    /*PRICE_LIST_NAME
                   ,*/COMPARISON_OPERATOR_CODE
                   ,orig_sys_qualifier_rule_ref
                   ,orig_sys_qualifier_ref
                   ,description
                   ,qualifier_name
                   ,QUALIFIER_CONTEXT
                   ,QUALIFIER_ATTRIBUTE
                   ,QUALIFIER_GROUPING_NO
                   ,QUALIFIER_ATTR_VALUE
                   ,QUALIFIER_ATTR_VALUE_DISP
                   ,QUALIFIER_PRECEDENCE
                   ,QUALIFIER_ATTR_VALUE_TO
                   ,START_DATE_ACTIVE
                   ,END_DATE_ACTIVE
                   ,CONTEXT
                 --  ,PROCESS_TYPE
                --   ,LOCK_FLAG
                --   ,DELETE_FLAG
                --   ,PRICE_LIST_LINE_INDEX
                --   ,PRODUCT_ATTR_VAL_DISP
                --   ,PRICING_ATTR_CODE --DROY
                 --  ,PRICING_ATTR_VALUE_FROM_DISP
                 --  ,PRICING_ATTR_VALUE_TO_DISP
                 --  ,ATTRIBUTE_STATUS
                   --,INTERFACE_ACTION_CODE
                 --  ,PROCESS_FLAG
                 --  ,PROCESS_STATUS_FLAG
                   ,BATCH_ID
                 --  ,SRC_FILE_NAME
                 --  ,HEADER_RECORD_NUMBER
                 --  ,LINE_RECORD_NUMBER --droy
                   ,active_flag
                   ,REQUEST_ID
                   ,PROCESS_CODE
                   ,ERROR_CODE
                   ,RECORD_NUMBER
                   ,CREATED_BY
                   ,CREATION_DATE
                   ,LAST_UPDATED_BY
                   ,LAST_UPDATE_LOGIN
                   ,LAST_UPDATE_DATE
                )
                SELECT
                        /* PRICE_LIST_NAME
                        ,*/COMPARISON_OPERATOR_CODE
                        ,orig_sys_qualifier_rule_ref
                        ,orig_sys_qualifier_ref
                        ,description
                        ,qualifier_name
                        ,QUALIFIER_CONTEXT
                        ,QUALIFIER_ATTRIBUTE
                        ,QUALIFIER_GROUPING_NO
                        ,QUALIFIER_ATTR_VALUE
                        ,QUALIFIER_ATTR_VALUE_DISP
                        ,QUALIFIER_PRECEDENCE
                        ,QUALIFIER_ATTR_VALUE_TO
                        ,START_DATE_ACTIVE
                        ,END_DATE_ACTIVE
                        ,CONTEXT
                    --    ,PROCESS_TYPE
                     --   ,LOCK_FLAG
                     --   ,DELETE_FLAG
                     --   ,PRICE_LIST_LINE_INDEX
                   --     ,PRODUCT_ATTR_VAL_DISP
                   --     ,PRICING_ATTR_CODE --
                   --     ,PRICING_ATTR_VALUE_FROM_DISP
                   --     ,PRICING_ATTR_VALUE_TO_DISP
                   --     ,ATTRIBUTE_STATUS
                       -- ,INTERFACE_ACTION_CODE
                     --   ,PROCESS_FLAG
                     --   ,PROCESS_STATUS_FLAG
                        ,BATCH_ID
                     --   ,SRC_FILE_NAME
                     --   ,HEADER_RECORD_NUMBER
                     --   ,LINE_RECORD_NUMBER --droy
                        ,active_flag
                        ,REQUEST_ID
                        ,G_STAGE
                        ,ERROR_CODE
                        ,RECORD_NUMBER
                    --    ,TO_NUMBER(HEADER_RECORD_NUMBER)
                        ,x_created_by
                        ,x_creation_date
                        ,x_last_updated_by
                        ,x_last_update_login
                        ,x_last_update_date
                  FROM XX_QP_RULES_QLF_STG
                 WHERE BATCH_ID = G_BATCH_ID
                   AND process_code = xx_emf_cn_pkg.CN_PREVAL
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   AND DESELECT_FLAG IS NULL
                   AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);
                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Insert into XX_QP_RULES_QLF_PRE before commit');
                   COMMIT;
                   EXCEPTION
           WHEN OTHERS THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in insertion XX_QP_RULES_QLF_PRE '||SQLERRM);
               xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
               x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
               RETURN x_error_code;
                   END;

                   /*select request_id into l_request_id
                  FROM XX_QP_RULES_QLF_STG
                 WHERE BATCH_ID = G_BATCH_ID
                   AND process_code = xx_emf_cn_pkg.CN_PREVAL
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Insert into XX_QP_RULES_QLF_PRE before commit');
                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'l_request_id=' || l_request_id); */


                --COMMIT;

                RETURN x_error_code;
        EXCEPTION
                WHEN OTHERS THEN
                        xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);

                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in move_rec_pre_standard_table '||SQLERRM);
                        x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
                        RETURN x_error_code;
        END move_rec_pre_standard_table;

     /*   PROCEDURE mark_duplicate_combination
        IS



            CURSOR c_xx_error_qlf_rec
            IS
            SELECT record_number
                  ,modifier_name
                  ,qualifier_context
                  ,qualifier_attribute
                  ,orig_sys_qualifier_ref
                  ,orig_sys_qualifier_rule_ref
              FROM XX_QP_RULES_QLF_PRE
             WHERE error_code   = xx_emf_cn_pkg.CN_REC_ERR
               --AND process_code = xx_emf_cn_pkg.CN_STG_DATAVAL
               AND process_code = xx_emf_cn_pkg.CN_VALID
               AND batch_id     = g_batch_id
               AND request_id   = xx_emf_pkg.G_REQUEST_ID
             ;

            PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, '~Duplicate:Marking for batch:' || g_batch_id||'-'||xx_emf_pkg.G_REQUEST_ID);

            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, '~Duplicate:Number of Record updated 1:' || SQL%ROWCOUNT);
            COMMIT;

            UPDATE XX_QP_RULES_QLF_PRE
              SET error_code   = xx_emf_cn_pkg.CN_REC_ERR,
                  --process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
                  process_code = xx_emf_cn_pkg.CN_VALID,
                  error_desc   = 'Duplicate Qualifier on Modifier'
            WHERE
                rowid IN (SELECT "rowid" FROM
                          (SELECT "rowid", rank_n FROM
                           (SELECT ROW_NUMBER()
                                   OVER (PARTITION BY
                                           modifier_name,qualifier_context
                                          ,qualifier_attribute
                                           ORDER BY ROWID
                                        ) rank_n
                                   , rowid as "rowid"
                              FROM XX_QP_RULES_QLF_PRE
                             WHERE 1=1
                               AND batch_id   = G_BATCH_ID
                               AND request_id = xx_emf_pkg.G_REQUEST_ID
                               AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                              )
                            )
                          WHERE rank_n > 1
                         )
             AND batch_id   = g_batch_id
             AND request_id = xx_emf_pkg.G_REQUEST_ID
            ;

            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, '~Duplicate:Number of Record updated 2: ' || SQL%ROWCOUNT);
            COMMIT;

            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, '~Duplicate:Number of Duplicate Qualifier ->' || SQL%ROWCOUNT);

            FOR cur_rec IN c_xx_error_qlf_rec LOOP
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                                ,p_error_text  => 'Duplicate Qualifiers on Modifier'
   ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_rule_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     );
            END LOOP;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in duplicate Modifier Validation ' || SQLCODE);
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                                ,p_error_text  => 'Errors in duplicate Modifier Validation=>'||SQLERRM
                                 );
        END mark_duplicate_combination;
        */


        FUNCTION process_data_qualifier RETURN NUMBER
            IS
            x_error_code                    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
            x_init_msg_list                VARCHAR2(10) := FND_API.G_FALSE;
            x_commit                        VARCHAR2(10) := FND_API.G_TRUE;
            x_return_status                VARCHAR2(1)  := 'S';
            l_msg_count                     NUMBER       := 0;
            l_msg_data                      VARCHAR2(2000);
                x_ind                           NUMBER       := 0;
                i                               NUMBER      ;
                l_return_status                 VARCHAR2(1);


             l_price_list_rec             QP_PRICE_LIST_PUB.Price_List_Rec_Type;
             l_price_list_val_rec         QP_PRICE_LIST_PUB.Price_List_Val_Rec_Type;
             l_price_list_line_tbl         QP_PRICE_LIST_PUB.Price_List_Line_Tbl_Type;
             l_price_list_line_val_tbl         QP_PRICE_LIST_PUB.Price_List_Line_Val_Tbl_Type;
             l_qualifiers_tbl             QP_Qualifier_Rules_Pub.Qualifiers_Tbl_Type;
             l_qualifiers_val_tbl         QP_Qualifier_Rules_Pub.Qualifiers_Val_Tbl_Type;
             l_pricing_attr_tbl         QP_PRICE_LIST_PUB.Pricing_Attr_Tbl_Type;
             l_pricing_attr_val_tbl         QP_PRICE_LIST_PUB.Pricing_Attr_Val_Tbl_Type;
             ppr_price_list_rec         QP_PRICE_LIST_PUB.Price_List_Rec_Type;
             ppr_price_list_val_rec         QP_PRICE_LIST_PUB.Price_List_Val_Rec_Type;
             ppr_price_list_line_tbl         QP_PRICE_LIST_PUB.Price_List_Line_Tbl_Type;
             ppr_price_list_line_val_tbl     QP_PRICE_LIST_PUB.Price_List_Line_Val_Tbl_Type;
             ppr_qualifier_rules_rec          QP_Qualifier_Rules_Pub.Qualifier_Rules_Rec_Type;
             ppr_qualifier_rules_val_rec      QP_Qualifier_Rules_Pub.Qualifier_Rules_Val_Rec_Type;
             ppr_qualifiers_tbl         QP_Qualifier_Rules_Pub.Qualifiers_Tbl_Type;
             ppr_qualifiers_val_tbl         QP_Qualifier_Rules_Pub.Qualifiers_Val_Tbl_Type;
             ppr_pricing_attr_tbl         QP_PRICE_LIST_PUB.Pricing_Attr_Tbl_Type;
              ppr_pricing_attr_val_tbl         QP_PRICE_LIST_PUB.Pricing_Attr_Val_Tbl_Type;
             l_qualifier_rules_rec       qp_qualifier_rules_pub.Qualifier_Rules_Rec_Type;
             l_qualifier_rules_val_rec   qp_qualifier_rules_pub.Qualifier_Rules_Val_Rec_Type;

                 --xx_qlf_pre_tab_type               g_xx_qlf_pre_tab_type;

                CURSOR c_pre_list IS
                SELECT DISTINCT
                       --PRICE_LIST_NAME,
                       qualifier_name,
                       description,
                       orig_sys_qualifier_rule_ref,
                       batch_id,
                       request_id
                FROM XX_QP_RULES_QLF_PRE
                WHERE batch_id          = G_BATCH_ID
            AND request_id        = xx_emf_pkg.G_REQUEST_ID
            AND process_code      = xx_emf_cn_pkg.CN_POSTVAL
            AND error_code        IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);


                CURSOR c_pre_qual_prc (cp_orig_sys_qual_rule_ref VARCHAR2)IS
                SELECT DISTINCT
                        --PRICE_LIST_NAME,
                        LIST_HEADER_ID,
                        COMPARISON_OPERATOR_CODE,
                        QUALIFIER_CONTEXT,
                        QUALIFIER_ATTRIBUTE,
                        START_DATE_ACTIVE,
                        END_DATE_ACTIVE,
                        --QUALIFIER_ATTRIBUTE_CODE,
                        QUALIFIER_ATTR_VALUE,
                        qualifier_attr_value_to,
                        --QLFR_ATTR_VALUE_CODE,
                        QUALIFIER_PRECEDENCE,
                        QUALIFIER_GROUPING_NO,
                        EXCLUDER_FLAG,
                        REQUEST_ID,
                        orig_sys_qualifier_ref,
                        orig_sys_qualifier_rule_ref,
                        batch_id,
                        record_number,
                        created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                        last_update_login
                  FROM XX_QP_RULES_QLF_PRE
                WHERE batch_id          = G_BATCH_ID
                    AND orig_sys_qualifier_rule_ref  = cp_orig_sys_qual_rule_ref
            AND request_id        = xx_emf_pkg.G_REQUEST_ID
            AND process_code      = xx_emf_cn_pkg.CN_POSTVAL
            AND error_code        IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

            TYPE xx_qp_qual_tbl IS TABLE OF c_pre_qual_prc%ROWTYPE
        INDEX BY BINARY_INTEGER;

        xx_qlf_pre_tab_type           xx_qp_qual_tbl;


            BEGIN

                -- CCID099 changes
                -- Change the logic to whatever needs to be done
                -- with valid records in the pre-interface tables
                -- either call the appropriate API to process the data
                -- or to insert into an interface table
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside Process Data For attaching Qualifier');

            FOR cur_list_rec IN c_pre_list LOOP
            i  := 0;
            xx_qlf_pre_tab_type.DELETE;
            --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'attaching Qualifier: cur_list_rec.list_header_id'||cur_list_rec.list_header_id);
            DECLARE
               l_qualifier_rules_rec qp_qualifier_rules_pub.Qualifier_Rules_Rec_Type;
               l_qualifiers_tbl      QP_Qualifier_Rules_Pub.Qualifiers_Tbl_Type;
               xx_qlf_pre_tab_type   xx_qp_qual_tbl;
            BEGIN
               l_qualifier_rules_rec.qualifier_rule_id := FND_API.G_MISS_NUM;
            l_qualifier_rules_rec.name := cur_list_rec.qualifier_name;
            l_qualifier_rules_rec.description := cur_list_rec.description;
            l_qualifier_rules_rec.attribute15 := cur_list_rec.batch_id; --Added on 4July
            l_qualifier_rules_rec.attribute10 := cur_list_rec.orig_sys_qualifier_rule_ref;
            l_qualifier_rules_rec.request_id  := cur_list_rec.request_id;
            l_qualifier_rules_rec.operation := QP_GLOBALS.G_OPR_CREATE;

            OPEN c_pre_qual_prc ( cur_list_rec.orig_sys_qualifier_rule_ref);
            FETCH c_pre_qual_prc BULK COLLECT INTO xx_qlf_pre_tab_type;
            IF c_pre_qual_prc%ISOPEN THEN
               CLOSE c_pre_qual_prc;
            END IF;
             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'attaching Qualifier: xx_qlf_pre_tab_type.COUNT'||xx_qlf_pre_tab_type.COUNT);
             FOR i IN 1..xx_qlf_pre_tab_type.COUNT LOOP
             --xx_qlf_pre_tab_type.DELETE;
                --i:=i+1;
                --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'xx_qlf_pre_tab_type(i).list_header_id'||xx_qlf_pre_tab_type(i).list_header_id);
                --l_qualifiers_tbl(i).list_header_id := xx_qlf_pre_tab_type(i).list_header_id;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'xx_qlf_pre_tab_type(i).qualifier_context'||xx_qlf_pre_tab_type(i).qualifier_context);
                l_qualifiers_tbl(i).qualifier_context := xx_qlf_pre_tab_type(i).qualifier_context;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'xx_qlf_pre_tab_type(i).qualifier_attribute'||xx_qlf_pre_tab_type(i).qualifier_attribute);
                l_qualifiers_tbl(i).qualifier_attribute := xx_qlf_pre_tab_type(i).qualifier_attribute;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'xx_qlf_pre_tab_type(i).qualifier_attr_value'||xx_qlf_pre_tab_type(i).qualifier_attr_value);
                l_qualifiers_tbl(i).qualifier_attr_value := xx_qlf_pre_tab_type(i).qualifier_attr_value;
                l_qualifiers_tbl(i).qualifier_attr_value_to := xx_qlf_pre_tab_type(i).qualifier_attr_value_to;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'xx_qlf_pre_tab_type(i).comparison_operator_code'||xx_qlf_pre_tab_type(i).comparison_operator_code);
                l_qualifiers_tbl(i).comparison_operator_code := xx_qlf_pre_tab_type(i).comparison_operator_code;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'xx_qlf_pre_tab_type(i).qualifier_precedence'||xx_qlf_pre_tab_type(i).qualifier_precedence);
                l_qualifiers_tbl(i).qualifier_precedence := xx_qlf_pre_tab_type(i).qualifier_precedence;
                l_qualifiers_tbl(i).qualifier_grouping_no := xx_qlf_pre_tab_type(i).qualifier_grouping_no;
                l_qualifiers_tbl(i).start_date_active     := xx_qlf_pre_tab_type(i).start_date_active;
                l_qualifiers_tbl(i).end_date_active     := xx_qlf_pre_tab_type(i).end_date_active;
        l_qualifiers_tbl(i).operation := QP_GLOBALS.G_OPR_CREATE;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'xx_qlf_pre_tab_type(i).request_id'||xx_qlf_pre_tab_type(i).request_id);
        l_qualifiers_tbl(i).request_id := xx_qlf_pre_tab_type(i).request_id;
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'xx_qlf_pre_tab_type(i).record_number'||xx_qlf_pre_tab_type(i).record_number);
        --l_qualifiers_tbl(i).attribute10 := xx_qlf_pre_tab_type(i).record_number;
        --Added by -- -- batch id is also stored at attribute15
        l_qualifiers_tbl(i).attribute15 := xx_qlf_pre_tab_type(i).batch_id;--Added on 4July
        l_qualifiers_tbl(i).attribute10 := xx_qlf_pre_tab_type(i).orig_sys_qualifier_ref;
        l_qualifiers_tbl(i).excluder_flag := NVL(xx_qlf_pre_tab_type (i).excluder_flag,'N');
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'xx_qlf_pre_tab_type(i).excluder_flag'||xx_qlf_pre_tab_type(i).excluder_flag);


        END LOOP;  --c_pre_qual_prc
        BEGIN
                -- added by to get the actaul number of API error and display
                l_msg_count :=0;
                FND_MSG_PUB.initialize;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Msg_count value after initilize'||l_msg_count);

                        QP_QUALIFIER_RULES_PUB.Process_Qualifier_Rules
                (   p_api_version_number            => 1
                ,   p_init_msg_list                 => FND_API.G_FALSE
                ,   p_return_values                 => FND_API.G_FALSE
                ,   p_commit                        => FND_API.G_FALSE
                ,   x_return_status                 => l_return_status
                ,   x_msg_count                     => l_msg_count
                ,   x_msg_data                      => l_msg_data
                ,   p_QUALIFIER_RULES_rec          => l_qualifier_rules_rec
                ,   p_QUALIFIER_RULES_val_rec      => l_qualifier_rules_val_rec
                ,   p_qualifiers_tbl                => l_qualifiers_tbl
                ,   x_qualifier_rules_rec           => ppr_qualifier_rules_rec
                ,   x_qualifier_rules_val_rec       => ppr_qualifier_rules_val_rec
                ,   x_qualifiers_tbl                => ppr_qualifiers_tbl
                ,   x_qualifiers_val_tbl            => ppr_qualifiers_val_tbl
              );

                        IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Price List Qualifier => Failure '||l_msg_count);
                           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                        ELSE
                           COMMIT;
                           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Qualifier Creation => Success');--||cur_list_rec.orig_sys_qualifier_rule_ref );-- ||'-' --DROY
                                                                                                   -- ||cur_list_rec.list_header_id);
                        END IF;
                    EXCEPTION
                    WHEN FND_API.G_EXC_ERROR THEN
                        l_return_status := FND_API.G_RET_STS_ERROR;
                        ROLLBACK;
                        xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                              ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                              ,p_error_text               => l_msg_data
                             -- ,p_record_identifier_1      => cur_list_rec.list_header_id
                              ,p_record_identifier_2      => cur_list_rec.orig_sys_qualifier_rule_ref
                                );
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg => G_EXEC_ERROR'||l_msg_count);


                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'mark_records_for_api_error => xx_emf_cn_pkg.CN_PROCESS_DATA'||
                                                                  xx_emf_cn_pkg.CN_PROCESS_DATA
                                                             --     ||'cur_list_rec.price_list_name '
                                                             --     ||cur_list_rec.price_list_name
                                                                  --||'cur_list_rec.list_header_id'
                                                                  --||cur_list_rec.list_header_id
                                                                  );
                        FOR k IN 1 .. l_msg_count LOOP
                            l_msg_data := oe_msg_pub.get
                                                ( p_msg_index => k
                                                 ,p_encoded => 'F');
                            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Count In G_EXC_UNEXPECTED_ERROR =>'||l_msg_data);
                            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg In G_EXC_UNEXPECTED_ERROR =>'||l_msg_count);

                            /*mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA
                                        ,cur_sec_rec.name
                                        ,cur_sec_rec.list_type_code);   */ --commented to avoid exception
                       END LOOP;

                        mark_records_for_qual_api_err(xx_emf_cn_pkg.CN_PROCESS_DATA
                                    ,l_msg_data
                                    ,l_qualifier_rules_rec.attribute10
                                    );
                    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
                       ROLLBACK;
                       FOR k IN 1 .. l_msg_count LOOP
                            l_msg_data := oe_msg_pub.get
                                                ( p_msg_index => k
                                                 ,p_encoded => 'F');
                            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Count In G_EXC_UNEXPECTED_ERROR =>'||l_msg_data);
                            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg In G_EXC_UNEXPECTED_ERROR =>'||l_msg_count);

                            /*mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA
                                        ,cur_sec_rec.name
                                        ,cur_sec_rec.list_type_code);   */ --commented to avoid exception
                       END LOOP;
                       xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
		                                         ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
		                                         ,p_error_text               => l_msg_data
		                                      --   ,p_record_identifier_1      => cur_list_rec.list_header_id
                                                      --   ,p_record_identifier_2      => cur_list_rec.orig_sys_qualifier_rule_ref
                                        );
                       mark_records_for_qual_api_err(xx_emf_cn_pkg.CN_PROCESS_DATA
                                                    ,l_msg_data
                                                    ,l_qualifier_rules_rec.attribute10
                                                    );
                    WHEN OTHERS THEN
                       ROLLBACK;
                       FOR k IN 1 .. l_msg_count LOOP
                            l_msg_data := oe_msg_pub.get
                                                ( p_msg_index => k
                                                 ,p_encoded => 'F');
                            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg =>'||l_msg_data);
                            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error count =>'||l_msg_count);

                       END LOOP;
                       xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
		                                         ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
		                                         ,p_error_text               => l_msg_data
		                                        -- ,p_record_identifier_1      => cur_list_rec.list_header_id
                                                       --  ,p_record_identifier_2      => cur_list_rec.orig_sys_qualifier_rule
                                        );
                       mark_records_for_qual_api_err(xx_emf_cn_pkg.CN_PROCESS_DATA
                                                    ,l_msg_data
                                                    ,l_qualifier_rules_rec.attribute10
                                                   );
                    END;
            EXCEPTION
               WHEN OTHERS THEN
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Qualifier Error: When others exception=>'||SQLERRM);
              x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                               ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                               ,p_error_text  => 'Errors In calling API =>'||SQLERRM);
            END;

            END LOOP;   --c_pre_list
            RETURN x_error_code;

            EXCEPTION
            WHEN OTHERS THEN
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Qualifier Error: Processing records=>'||SQLERRM);
              x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                               ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                               ,p_error_text  => 'Errors In calling API =>'||SQLERRM);
              RETURN x_error_code;
            END process_data_qualifier;


        /***** Not Required Separately for Qualifiers **********/
        PROCEDURE update_record_count
        IS


                x_total_cnt_sec NUMBER;

                CURSOR c_get_total_cnt_qual IS
        SELECT COUNT (1) total_count
          FROM XX_QP_RULES_QLF_STG
         WHERE batch_id = G_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID
           ;

                x_total_cnt_qual NUMBER;



                x_error_cnt_sec NUMBER;

                CURSOR c_get_error_cnt_qual IS
            SELECT SUM(error_count) err_cnt
              FROM (
            SELECT COUNT (1) error_count
              FROM XX_QP_RULES_QLF_STG
             WHERE batch_id = G_BATCH_ID
               AND request_id = xx_emf_pkg.G_REQUEST_ID
               AND error_code = xx_emf_cn_pkg.CN_REC_ERR
            UNION ALL
            SELECT COUNT (1) error_count
              FROM XX_QP_RULES_QLF_PRE
             WHERE batch_id = G_BATCH_ID
               AND request_id = xx_emf_pkg.G_REQUEST_ID
               AND error_code = xx_emf_cn_pkg.CN_REC_ERR
               );

                x_error_cnt_qual NUMBER;

                x_warn_cnt_sec NUMBER;

                CURSOR c_get_warning_cnt_qual IS
        SELECT COUNT (1) warn_count
          FROM XX_QP_RULES_QLF_PRE
         WHERE batch_id = G_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID
           AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

                x_warn_cnt_qual NUMBER;



                CURSOR c_get_success_cnt_qual IS
        SELECT COUNT (1) warn_count
          FROM XX_QP_RULES_QLF_PRE
         WHERE batch_id = G_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID
           AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
           AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

                x_success_cnt_qual NUMBER;

        BEGIN



                OPEN c_get_total_cnt_qual;
        FETCH c_get_total_cnt_qual INTO x_total_cnt_qual;
        CLOSE c_get_total_cnt_qual;

        OPEN c_get_error_cnt_qual;
        FETCH c_get_error_cnt_qual INTO x_error_cnt_qual;
        CLOSE c_get_error_cnt_qual;

        OPEN c_get_warning_cnt_qual;
        FETCH c_get_warning_cnt_qual INTO x_warn_cnt_qual;
        CLOSE c_get_warning_cnt_qual;

        OPEN c_get_success_cnt_qual;
        FETCH c_get_success_cnt_qual INTO x_success_cnt_qual;
        CLOSE c_get_success_cnt_qual;

        xx_emf_pkg.update_recs_cnt
        (
            p_total_recs_cnt => x_total_cnt_qual,
            p_success_recs_cnt => x_success_cnt_qual,
            p_warning_recs_cnt => x_warn_cnt_qual,
            p_error_recs_cnt => x_error_cnt_qual
                );




        END update_record_count;


    BEGIN

        retcode := xx_emf_cn_pkg.CN_SUCCESS;

        -- Set environment for EMF (Error Management Framework)
        -- If you want the process to continue even after the emf env not being set
        -- you must make p_required_flag from CN_YES to CN_NO
        -- If you do not pass proper value then it will be considered as CN_YES
        set_cnv_env (p_batch_id => p_batch_id, p_required_flag => xx_emf_cn_pkg.CN_YES);

        -- include all the parameters to the conversion main here
        -- as medium log messages
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Starting main process with the following parameters');
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_batch_id ' ||  p_batch_id);
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_restart_flag ' ||  p_restart_flag);
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_override_flag ' || p_override_flag);

        -- Call procedure to update records with the current request_id
        -- So that we can process only those records
        -- This gives a better handling of restartability
        mark_records_for_processing(p_restart_flag => p_restart_flag, p_override_flag => p_override_flag/*, p_prog=>p_prog*/);

        -- Once the records are identified based on the input parameters
        -- Start with pre-validations
        IF NVL ( p_override_flag, xx_emf_cn_pkg.CN_NO) = xx_emf_cn_pkg.CN_NO THEN
                -- Set the stage to Pre Validations
                set_stage (xx_emf_cn_pkg.CN_PREVAL);

                -- Change the validations package to the appropriate package name
                -- Modify the parameters as required
                -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
                -- PRE_VALIDATIONS SHOULD BE RETAINED
                x_error_code := xx_qp_qual_rul_val_pkg.pre_validations (p_batch_id);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After pre-validations X_ERROR_CODE ' || X_ERROR_CODE);

                -- Update process code of staging records
                -- Also move the successful records to pre-interface tables
                COMMIT;
                update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS);
                xx_emf_pkg.propagate_error ( x_error_code);
                x_error_code := move_rec_pre_standard_table;
                xx_emf_pkg.propagate_error ( x_error_code);

                --Marked the Duplicate combinations of ITEM and Organization
                --mark_duplicate_combination;
        END IF;

        -- Once pre-validations are complete the loop through the pre-interface records
        -- and perform data validations on this table
        -- Set the stage to data Validations
        set_stage (xx_emf_cn_pkg.CN_VALID);
        -- Loop For Qualifier - Data Validation
            OPEN c_xx_cnv_pre_std_qlf_hdr ( xx_emf_cn_pkg.CN_PREVAL);
            LOOP
                FETCH c_xx_cnv_pre_std_qlf_hdr
                BULK COLLECT INTO x_pre_std_hdr_qlf_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

                FOR i IN 1 .. x_pre_std_hdr_qlf_table.COUNT
                LOOP

                        BEGIN
                                -- Perform header level Base App Validations
                                x_error_code := xx_qp_qual_rul_val_pkg.data_validations (
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



        -- Once data-validations are complete the loop through the pre-interface records
        -- and perform data derivations on this table
        -- Set the stage to data derivations

        set_stage (xx_emf_cn_pkg.CN_DERIVE);
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
                                x_error_code := xx_qp_qual_rul_val_pkg.data_derivations (
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
                                        xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_hdr_qlf_table (i).record_number);
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

        -- Set the stage to Pre Validations
        set_stage (xx_emf_cn_pkg.CN_POSTVAL);

        -- CCID099 changes
        -- Change the validations package to the appropriate package name
        -- Modify the parameters as required
        -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
        -- PRE_VALIDATIONS SHOULD BE RETAINED
        x_error_code := xx_qp_qual_rul_val_pkg.post_validations(G_BATCH_ID/*,p_prog*/);
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
        mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL/*,p_prog*/);
        xx_emf_pkg.propagate_error ( x_error_code);

        IF p_validate_and_load = g_validate_and_load THEN --added for Validate flag

        -- Set the stage to Pre Validations
        set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);

        /***** Write Code for Process Data ******/
        x_error_code := process_data_qualifier ();

        mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA/*,p_prog*/);
        xx_emf_pkg.propagate_error ( x_error_code);
        END IF; -- For validate only flag check


        update_record_count;
        xx_emf_pkg.create_report;


    EXCEPTION
            WHEN xx_emf_pkg.G_E_ENV_NOT_SET THEN
                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Checking if this is OK');

                    fnd_file.PUT_LINE ( fnd_file.output, xx_emf_pkg.CN_ENV_NOT_SET);
                    dbms_output.PUT_LINE ( xx_emf_pkg.CN_ENV_NOT_SET);
                    retcode := xx_emf_cn_pkg.CN_REC_ERR;
                    update_record_count;--(p_prog);
                    xx_emf_pkg.create_report;
            WHEN xx_emf_pkg.G_E_REC_ERROR THEN
                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'xx_emf_pkg.G_E_REC_ERROR'||SQLERRM);

                    retcode := xx_emf_cn_pkg.CN_REC_ERR;
                    update_record_count;--(p_prog);
                    xx_emf_pkg.create_report;
            WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'xx_emf_pkg.G_E_PRC_ERROR=>'||SQLERRM);
                    retcode := xx_emf_cn_pkg.CN_PRC_ERR;
                    update_record_count;--(p_prog);
                    xx_emf_pkg.create_report;
            WHEN OTHERS THEN
                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'OTHERS=>'||SQLERRM);
                    retcode := xx_emf_cn_pkg.CN_PRC_ERR;
                    update_record_count;--(p_prog);
                    xx_emf_pkg.create_report;

    END main;

END xx_qp_qual_rul_cnv_pkg;
/
