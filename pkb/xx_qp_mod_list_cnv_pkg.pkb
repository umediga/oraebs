DROP PACKAGE BODY APPS.XX_QP_MOD_LIST_CNV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_QP_MOD_LIST_CNV_PKG" AS
/*
 Created By     : IBM
 Creation Date  : 20-May-2013
 File Name      : XXQPMODLISTCNVTL.pkb
 Description    : This script creates the body of the package xx_qp_mod_list_cnv_pkg

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
1.0     20-May-2013 Debjani Roy  Initial development.
-------------------------------------------------------------------------
*/

    -- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
    -- START RESTRICTIONS
    PROCEDURE set_cnv_env ( p_batch_id VARCHAR2, p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES) IS
            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
            G_BATCH_ID := p_batch_id;
            -- Set the environment
            x_error_code := xx_emf_pkg.set_env;
            -- x_error_code := xx_emf_pkg.set_env ('XXBMCCNVTL');

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
    ) IS
            PRAGMA AUTONOMOUS_TRANSACTION;

    BEGIN
            -- If the override is set records should not be purged from the pre-interface tables
            IF p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS THEN

                    IF p_override_flag = xx_emf_cn_pkg.CN_NO THEN
                            -- purge from pre-interface tables and oracle standard tables

                            DELETE FROM xx_qp_mdpr_list_hdr_pre
                             WHERE batch_id = G_BATCH_ID;

                            DELETE FROM xx_qp_mdpr_list_lines_pre
                             WHERE batch_id = G_BATCH_ID;

                            DELETE FROM xx_qp_mdpr_list_qlf_pre
                            WHERE batch_id = G_BATCH_ID;

                            UPDATE xx_qp_mdpr_list_hdr_stg
                               SET request_id = xx_emf_pkg.G_REQUEST_ID,
                                   error_code = xx_emf_cn_pkg.CN_NULL,
                                   process_code = xx_emf_cn_pkg.CN_NEW,
                                   error_desc   = xx_emf_cn_pkg.CN_NULL
                             WHERE batch_id = G_BATCH_ID;

                            UPDATE xx_qp_mdpr_list_lines_stg
                               SET request_id = xx_emf_pkg.G_REQUEST_ID,
                                   error_code = xx_emf_cn_pkg.CN_NULL,
                                   process_code = xx_emf_cn_pkg.CN_NEW,
                                   error_desc   = xx_emf_cn_pkg.CN_NULL
                             WHERE batch_id = G_BATCH_ID;


                            UPDATE xx_qp_mdpr_list_qlf_stg
                               SET request_id = xx_emf_pkg.G_REQUEST_ID,
                                   error_code = xx_emf_cn_pkg.CN_NULL,
                                   process_code = xx_emf_cn_pkg.CN_NEW,
                                   error_desc   = xx_emf_cn_pkg.CN_NULL
                             WHERE batch_id = G_BATCH_ID;
                    ELSE
                            UPDATE xx_qp_mdpr_list_hdr_pre
                               SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                                   error_code = xx_emf_cn_pkg.CN_SUCCESS,
                                   request_id = xx_emf_pkg.G_REQUEST_ID
                             WHERE batch_id = G_BATCH_ID;

                            UPDATE xx_qp_mdpr_list_lines_pre
                               SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                                   error_code = xx_emf_cn_pkg.CN_SUCCESS,
                                   request_id = xx_emf_pkg.G_REQUEST_ID
                             WHERE batch_id = G_BATCH_ID;


                            UPDATE xx_qp_mdpr_list_qlf_pre
                               SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                                   error_code = xx_emf_cn_pkg.CN_SUCCESS,
                                   request_id = xx_emf_pkg.G_REQUEST_ID
                             WHERE batch_id = G_BATCH_ID;
                    END IF;
        /* We are using API for this conversion. so, these deletes not required*/
                   -- DELETE FROM xx_oracle_standard_table
                   --  WHERE attribute1 = G_BATCH_ID;

            ELSIF p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS THEN

                    IF p_override_flag = xx_emf_cn_pkg.CN_NO THEN

                            -- Update staging table

                            UPDATE xx_qp_mdpr_list_hdr_stg
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


                            UPDATE xx_qp_mdpr_list_lines_stg
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


                            UPDATE xx_qp_mdpr_list_qlf_stg
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

                    UPDATE xx_qp_mdpr_list_hdr_stg a
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_NULL,
                           process_code = xx_emf_cn_pkg.CN_NEW
                     WHERE batch_id = G_BATCH_ID
                       AND EXISTS (
                            SELECT 1
                              FROM xx_qp_mdpr_list_hdr_pre
                             WHERE batch_id = G_BATCH_ID
                               AND process_code = xx_emf_cn_pkg.CN_PREVAL
                               AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                               AND record_number = a.record_number);


                    UPDATE xx_qp_mdpr_list_lines_stg a
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_NULL,
                           process_code = xx_emf_cn_pkg.CN_NEW
                     WHERE batch_id = G_BATCH_ID
                       AND EXISTS (
                            SELECT 1
                              FROM xx_qp_mdpr_list_lines_pre
                             WHERE batch_id = G_BATCH_ID
                               AND process_code = xx_emf_cn_pkg.CN_PREVAL
                               AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                               AND record_number = a.record_number);



                    UPDATE xx_qp_mdpr_list_qlf_stg a
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_NULL,
                           process_code = xx_emf_cn_pkg.CN_NEW
                     WHERE batch_id = G_BATCH_ID
                       AND EXISTS (
                            SELECT 1
                              FROM xx_qp_mdpr_list_qlf_pre
                             WHERE batch_id = G_BATCH_ID
                               AND process_code = xx_emf_cn_pkg.CN_PREVAL
                               AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                               AND record_number = a.record_number);


                     DELETE
                      FROM xx_qp_mdpr_list_hdr_pre
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_PREVAL
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);


                     DELETE
                      FROM xx_qp_mdpr_list_lines_pre
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_PREVAL
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    DELETE
                      FROM xx_qp_mdpr_list_qlf_pre
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_PREVAL
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    -- Scenario 2 Data Validation Stage

                    UPDATE xx_qp_mdpr_list_hdr_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_PREVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_VALID
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);


                    UPDATE xx_qp_mdpr_list_lines_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_PREVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_VALID
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    UPDATE xx_qp_mdpr_list_qlf_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_PREVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_VALID
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    -- Scenario 3 Data Derivation Stage

                    UPDATE xx_qp_mdpr_list_hdr_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_DERIVE
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_DERIVE
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);


                    UPDATE xx_qp_mdpr_list_lines_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_DERIVE
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_DERIVE
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    UPDATE xx_qp_mdpr_list_qlf_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_DERIVE
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_DERIVE
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    -- Scenario 4 Post Validation Stage

                    UPDATE xx_qp_mdpr_list_hdr_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_POSTVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_POSTVAL
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);


                    UPDATE xx_qp_mdpr_list_lines_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_POSTVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_POSTVAL
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    UPDATE xx_qp_mdpr_list_qlf_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_POSTVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_POSTVAL
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                    -- Scenario 5 Process Data Stage

                    UPDATE xx_qp_mdpr_list_hdr_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_POSTVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_ERR);

                    UPDATE xx_qp_mdpr_list_lines_pre
                       SET request_id = xx_emf_pkg.G_REQUEST_ID,
                           error_code = xx_emf_cn_pkg.CN_SUCCESS,
                           process_code = xx_emf_cn_pkg.CN_POSTVAL
                     WHERE batch_id = G_BATCH_ID
                       AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                       AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_ERR);

                    UPDATE xx_qp_mdpr_list_qlf_pre
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

            UPDATE xx_qp_mdpr_list_hdr_stg
               SET process_code = G_STAGE,
                   error_code = DECODE ( error_code, NULL, p_error_code, error_code),
                   last_update_date = x_last_update_date,
                   last_updated_by = x_last_updated_by,
                   last_update_login = x_last_update_login
             WHERE batch_id = G_BATCH_ID
               AND request_id = xx_emf_pkg.G_REQUEST_ID
               AND process_code = xx_emf_cn_pkg.CN_NEW;


            UPDATE xx_qp_mdpr_list_lines_stg
               SET process_code = G_STAGE,
                   error_code = DECODE ( error_code, NULL, p_error_code, error_code),
                   last_update_date = x_last_update_date,
                   last_updated_by = x_last_updated_by,
                   last_update_login = x_last_update_login
             WHERE batch_id = G_BATCH_ID
               AND request_id = xx_emf_pkg.G_REQUEST_ID
               AND process_code = xx_emf_cn_pkg.CN_NEW;

            UPDATE xx_qp_mdpr_list_qlf_stg
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

   PROCEDURE mark_records_for_api_error
        (
          p_process_code          VARCHAR2
      --, p_price_list_name       VARCHAR2
        , p_orig_sys_header_ref   VARCHAR2
        , p_orig_sys_line_ref     VARCHAR2
        , p_orig_sys_qualifier_ref     VARCHAR2
        , p_msg_data              VARCHAR2
        )
        IS
                x_last_update_date       DATE := SYSDATE;
                x_last_updated_by        NUMBER := fnd_global.user_id;
                x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

                PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN

                 UPDATE xx_qp_mdpr_list_hdr_pre
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
                UPDATE xx_qp_mdpr_list_lines_pre
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
                UPDATE xx_qp_mdpr_list_qlf_pre
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
        EXCEPTION
		WHEN OTHERS THEN
			xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);

			xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in mark_records_for_api_error '||SQLERRM);
			--x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
		--RETURN x_error_code;

        END mark_records_for_api_error;



        PROCEDURE process_data_insert_mode (errbuf                 OUT VARCHAR2
                                           ,retcode                OUT  NUMBER
                                           ,p_batch_id             IN   VARCHAR2
                                           ,p_custom_batch_no      IN   NUMBER)
        IS
            x_error_code                    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
			x_init_msg_list	                VARCHAR2(10) := FND_API.G_FALSE;
			x_commit                        VARCHAR2(10) := FND_API.G_TRUE;
			x_return_status	                VARCHAR2(1)  := 'S';
			gpr_msg_count                     NUMBER       := 0;
			gpr_msg_data                      VARCHAR2(32767 );
                        gpr_msg_data2                 VARCHAR2 ( 32767 );
            x_ind                           NUMBER       := 0;
            l_return_status                 VARCHAR2(1);

            l_MODIFIER_LIST_rec               QP_Modifiers_PUB.Modifier_List_Rec_Type;
            l_MODIFIERS_tbl                   QP_Modifiers_PUB.Modifiers_Tbl_Type;
            l_PRICING_ATTR_tbl                QP_Modifiers_PUB.Pricing_Attr_Tbl_Type;
            l_x_MODIFIER_LIST_rec             QP_Modifiers_PUB.Modifier_List_Rec_Type;
            l_x_MODIFIER_LIST_val_rec         QP_Modifiers_PUB.Modifier_List_Val_Rec_Type;
            l_x_MODIFIERS_tbl                 QP_Modifiers_PUB.Modifiers_Tbl_Type;
            l_x_MODIFIERS_val_tbl             QP_Modifiers_PUB.Modifiers_Val_Tbl_Type;
            l_x_QUALIFIERS_tbl                QP_Qualifier_Rules_PUB.Qualifiers_Tbl_Type;
            l_x_QUALIFIERS_val_tbl            QP_Qualifier_Rules_PUB.Qualifiers_Val_Tbl_Type;
            l_x_PRICING_ATTR_tbl              QP_Modifiers_PUB.Pricing_Attr_Tbl_Type;
            l_x_PRICING_ATTR_val_tbl          QP_Modifiers_PUB.Pricing_Attr_Val_Tbl_Type;
            l_QUALIFIERS_tbl                  QP_Qualifier_Rules_PUB.Qualifiers_Tbl_Type;
            l_list_line_id                    qp_list_lines.list_line_id%TYPE;

            x_hdr_err_flag                  VARCHAR2(1);
            x_line_err_flag                 VARCHAR2(1);
            x_attr_err_flag                  VARCHAR2(1);
            x_qlf_err_flag                  VARCHAR2(1);
            l_list_line_exists_flag         VARCHAR2(1);
            x_qual_count                    NUMBER;

            x_sys_time                      VARCHAR2(100);

            xx_qlf_pre_tab_type               g_xx_qlf_pre_tab_type;

            CURSOR c_pre_dis_mdf IS
            SELECT --DISTINCT
                    name
                   ,currency_code
                   ,list_type_code
                   ,start_date_active
                   ,end_date_active
                   ,source_system_code
                   ,active_flag
                   ,description
                   ,comments
                   ,version_no
                   ,pte_code
                   ,automatic_flag
                   ,discount_lines_flag
                   ,freight_terms_code
                   ,gsa_indicator
                   ,rounding_factor
                   ,start_date_active_first
                   ,end_date_active_first
                   ,start_date_active_second
                   ,end_date_active_second
                   ,global_flag
                   ,org_id
                   ,orig_sys_header_ref
                   ,custom_lines_count
              FROM xx_qp_mdpr_list_hdr_pre
            WHERE batch_id          = P_BATCH_ID
              AND custom_batch_no   = p_custom_batch_no
			  --AND request_id        = xx_emf_pkg.G_REQUEST_ID
			  AND process_code      = xx_emf_cn_pkg.CN_POSTVAL
			  --AND error_code        IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN) --Warning is set for existing hdrs creating qualifiers
                          AND error_code        IN ( xx_emf_cn_pkg.CN_SUCCESS);--Take only success records

            CURSOR c_pre_std_hdr (p_orig_sys_header_ref IN xx_qp_mdpr_list_lines_stg.orig_sys_header_ref%TYPE) IS
            SELECT
                --
                -- Add Columns
                --
                  x.*
            FROM xx_qp_mdpr_list_lines_pre x
            WHERE batch_id          = P_BATCH_ID
			  --AND request_id        = xx_emf_pkg.G_REQUEST_ID
			  AND process_code      = xx_emf_cn_pkg.CN_POSTVAL
			  AND error_code        IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
              AND orig_sys_header_ref = p_orig_sys_header_ref
              AND ( list_line_type_code = 'PBH' OR
                    list_line_type_code = 'DIS' AND from_orig_sys_hdr_ref IS NULL)--rltd_modifier_grp_type IS NULL)
              ORDER BY orig_sys_line_ref
              -- In Order Not to pick up the Related Modifiers
            ;

            CURSOR c_pre_std_rltd_hdr (p_orig_sys_header_ref IN xx_qp_mdpr_list_lines_stg.orig_sys_header_ref%TYPE
                                      ,p_orig_sys_line_ref   IN xx_qp_mdpr_list_lines_stg.orig_sys_line_ref%TYPE
                                      ) IS
            SELECT
                --
                -- Add Columns
                --
			       x.*
            FROM xx_qp_mdpr_list_lines_pre x
            WHERE batch_id          = P_BATCH_ID
			  --AND request_id        = xx_emf_pkg.G_REQUEST_ID
			  AND process_code      = xx_emf_cn_pkg.CN_POSTVAL
			  AND error_code        IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
              AND orig_sys_header_ref = p_orig_sys_header_ref
              AND list_line_type_code = 'DIS' AND to_orig_sys_hdr_ref IS NOT NULL--rltd_modifier_grp_type IS NOT NULL
              --AND orig_sys_line_ref = p_orig_sys_line_ref
              AND from_orig_sys_hdr_ref = p_orig_sys_line_ref
              ORDER BY orig_sys_line_ref
              -- In Order to pick up the Related Modifiers
            ;

            -- Cursor for Qualifiers

        BEGIN

            -- CCID099 changes
            -- Change the logic to whatever needs to be done
            -- with valid records in the pre-interface tables
            -- either call the appropriate API to process the data
            -- or to insert into an interface table
            set_cnv_env ( p_batch_id => p_batch_id, p_required_flag => xx_emf_cn_pkg.cn_yes );
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside Process Data');

            FOR cur_dis_rec IN c_pre_dis_mdf LOOP
                    x_hdr_err_flag  := 'N';
                    x_line_err_flag := 'N';
                    x_attr_err_flag := 'N';
                    x_qlf_err_flag  := 'N';

                    xx_qlf_pre_tab_type.DELETE;
                    ---**********--------
                    l_MODIFIERS_tbl.DELETE;
                    l_PRICING_ATTR_tbl.DELETE;

                    l_MODIFIER_LIST_rec.list_header_id             := fnd_api.g_miss_num;
                    l_MODIFIER_LIST_rec.currency_code              := cur_dis_rec.currency_code;
                    l_MODIFIER_LIST_rec.list_type_code             := cur_dis_rec.list_type_code;
                    l_MODIFIER_LIST_rec.start_date_active          := cur_dis_rec.start_date_active;
                    l_MODIFIER_LIST_rec.end_date_active            := cur_dis_rec.end_date_active;
                    l_MODIFIER_LIST_rec.source_system_code         := cur_dis_rec.source_system_code;   --Source System Code
                    l_MODIFIER_LIST_rec.active_flag                := cur_dis_rec.active_flag;
                    l_MODIFIER_LIST_rec.name                       := cur_dis_rec.name;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating Modifier HDR '||cur_dis_rec.name);
                    l_MODIFIER_LIST_rec.description                := cur_dis_rec.description;
                    l_MODIFIER_LIST_rec.comments                   := cur_dis_rec.comments; --DROY Added on 08Aug
                    l_MODIFIER_LIST_rec.version_no                 := cur_dis_rec.version_no;
                    l_MODIFIER_LIST_rec.pte_code                   := cur_dis_rec.pte_code;
                    l_MODIFIER_LIST_rec.automatic_flag             := cur_dis_rec.automatic_flag;
                    l_MODIFIER_LIST_rec.discount_lines_flag        := cur_dis_rec.discount_lines_flag;
                    l_MODIFIER_LIST_rec.freight_terms_code         := cur_dis_rec.freight_terms_code;
                    l_MODIFIER_LIST_rec.gsa_indicator              := cur_dis_rec.gsa_indicator;
                    l_MODIFIER_LIST_rec.rounding_factor            := cur_dis_rec.rounding_factor;
                    l_MODIFIER_LIST_rec.start_date_active_first    := cur_dis_rec.start_date_active_first;
                    l_MODIFIER_LIST_rec.end_date_active_first      := cur_dis_rec.end_date_active_first;
                    l_MODIFIER_LIST_rec.start_date_active_second   := cur_dis_rec.start_date_active_second;
                    l_MODIFIER_LIST_rec.end_date_active_second     := cur_dis_rec.end_date_active_second;
                    l_MODIFIER_LIST_rec.global_flag                := 'N';--cur_dis_rec.global_flag; --As per Sri these will be loaded with 'N'
                    l_MODIFIER_LIST_rec.attribute15                := p_batch_id;
                    l_MODIFIER_LIST_rec.orig_system_header_ref        := cur_dis_rec.orig_sys_header_ref;
                     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating Modifier HDR global_flag '||cur_dis_rec.global_flag);
                    l_MODIFIER_LIST_rec.request_id               :=xx_emf_pkg.g_request_id;
                    l_MODIFIER_LIST_rec.org_id                     := cur_dis_rec.org_id;
                     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating Modifier HDR org_id '||cur_dis_rec.org_id);
                    l_MODIFIER_LIST_rec.operation                  := QP_GLOBALS.G_OPR_CREATE;

                    x_ind := 0;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Opening for loop for lines');

                FOR cur_rec IN c_pre_std_hdr(cur_dis_rec.orig_sys_header_ref) LOOP

                    BEGIN
                       SELECT TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS') INTO x_sys_time FROM DUAL;
                          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'System Time'
                                 ,p_record_identifier_1 => cur_rec.orig_sys_header_ref
                                 ,p_record_identifier_2 => 'Inside Line Loop'
                                 ,p_record_identifier_3 => x_sys_time
                                 );
                    EXCEPTION
                       WHEN OTHERS THEN
                          NULL;
                    END;

                    x_ind := x_ind + 1;

                    -- Modifier Line
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Start line assignment');

                    l_MODIFIERS_tbl(x_ind).list_line_type_code := cur_rec.list_line_type_code;
                   -- l_MODIFIERS_tbl(x_ind).orig_system_header_ref := cur_rec.orig_sys_header_ref;
                    l_MODIFIERS_tbl(x_ind).attribute10         := cur_rec.orig_sys_line_ref;
                    l_MODIFIERS_tbl(x_ind).automatic_flag:= NVL(cur_rec.automatic_flag, 'N');
                    l_MODIFIERS_tbl(x_ind).modifier_level_code := cur_rec.modifier_level_code;
                    l_MODIFIERS_tbl(x_ind).accrual_flag := NVL(cur_rec.accrual_flag, 'N');
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Line Date assignment');
                    l_MODIFIERS_tbl(x_ind).start_date_active := cur_rec.start_date_active;
                    l_MODIFIERS_tbl(x_ind).end_date_active := cur_rec.end_date_active;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'After Line Date assignment');
                    l_MODIFIERS_tbl(x_ind).arithmetic_operator := cur_rec.arithmetic_operator;
                    l_MODIFIERS_tbl(x_ind).pricing_group_sequence := cur_rec.pricing_group_sequence;
                    l_MODIFIERS_tbl(x_ind).pricing_phase_id := cur_rec.pricing_phase_id;
                    l_MODIFIERS_tbl(x_ind).price_break_type_code := cur_rec.price_break_type_code;
                    l_MODIFIERS_tbl(x_ind).qualification_ind := cur_rec.qualification_ind;
                    l_MODIFIERS_tbl(x_ind).product_precedence := NVL(cur_rec.product_precedence, xx_qp_mod_list_cnv_pkg.CN_ONE);
                    l_MODIFIERS_tbl(x_ind).operand := cur_rec.operand;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating Modifier line operand '||cur_rec.operand);
                    l_MODIFIERS_tbl(x_ind).modifier_parent_index := xx_qp_mod_list_cnv_pkg.CN_MDF_PARENT_IND;
                    l_MODIFIERS_tbl(x_ind).incompatibility_grp_code := cur_rec.incompatibility_grp_code;
                    --l_MODIFIERS_tbl(x_ind).estim_accrual_rate       := cur_rec.estim_accrual_rate;
                    l_MODIFIERS_tbl(x_ind).include_on_returns_flag  := cur_rec.include_on_returns_flag;
                    l_MODIFIERS_tbl(x_ind).override_flag            := cur_rec.override_flag ;
                    l_MODIFIERS_tbl(x_ind).print_on_invoice_flag    := cur_rec.print_on_invoice_flag ;
                    l_MODIFIERS_tbl(x_ind).operation := QP_GLOBALS.G_OPR_CREATE;

                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Attribute assignment');

                    -- Pricing Attribute for Modifier Line
                    l_PRICING_ATTR_tbl(x_ind).product_attribute_context:= cur_rec.product_attribute_context;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating Modifier attr product_attribute_context '||cur_rec.product_attribute_context);
                    l_PRICING_ATTR_tbl(x_ind).attribute10         := cur_rec.orig_sys_line_ref;
                    --l_PRICING_ATTR_tbl(x_ind).product_attribute := cur_rec.product_attribute_code;
                    l_PRICING_ATTR_tbl(x_ind).product_attribute := cur_rec.product_attribute;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating Modifier attr product_attribute '||cur_rec.product_attribute);
                    --l_PRICING_ATTR_tbl(x_ind).product_attr_value:= cur_rec.product_attr_value_code;
                    l_PRICING_ATTR_tbl(x_ind).product_attr_value:= cur_rec.product_attr_value;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating Modifier attr product_attr_value '||cur_rec.product_attr_value);
                    l_PRICING_ATTR_tbl(x_ind).pricing_attribute_context:= cur_rec.pricing_attribute_context;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating Modifier attr pricing_attribute_context '||cur_rec.pricing_attribute_context);
                    l_PRICING_ATTR_tbl(x_ind).pricing_attribute:= cur_rec.pricing_attribute;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating Modifier attr pricing_attribute '||cur_rec.pricing_attribute);
                    l_PRICING_ATTR_tbl(x_ind).pricing_attr_value_from:= cur_rec.pricing_attr_value_from;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating Modifier attr pricing_attr_value_from '||cur_rec.pricing_attr_value_from);
                    l_PRICING_ATTR_tbl(x_ind).pricing_attr_value_to := cur_rec.pricing_attr_value_to;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating Modifier attr pricing_attr_value_to '||cur_rec.pricing_attr_value_to);
                    l_PRICING_ATTR_tbl(x_ind).comparison_operator_code:= cur_rec.comparison_operator_code;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating Modifier attr comparison_operator_code '||cur_rec.comparison_operator_code);
                    l_PRICING_ATTR_tbl(x_ind).product_uom_code := cur_rec.product_uom_code;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating Modifier attr product_uom_code '||cur_rec.product_uom_code);
                    l_PRICING_ATTR_tbl(x_ind).excluder_flag := NVL(cur_rec.excluder_flag, 'N');
                    l_PRICING_ATTR_tbl(x_ind).MODIFIERS_index:= x_ind;
                    --l_PRICING_ATTR_tbl(x_ind).accumulate_flag := cur_rec.accumulate_flag; --DROY
                    l_PRICING_ATTR_tbl(x_ind).operation       := QP_GLOBALS.G_OPR_CREATE;

                    IF cur_rec.list_line_type_code = 'PBH' THEN
                        FOR cur_rec_rltd IN c_pre_std_rltd_hdr(cur_dis_rec.orig_sys_header_ref, cur_rec.orig_sys_line_ref) LOOP
                            -- For the Related Modifiers
                            x_ind := x_ind + 1;
                            l_MODIFIERS_tbl(x_ind).list_line_type_code := cur_rec_rltd.list_line_type_code;
                            l_MODIFIERS_tbl(x_ind).automatic_flag:= cur_rec_rltd.automatic_flag;
                            l_MODIFIERS_tbl(x_ind).attribute10         := cur_rec_rltd.orig_sys_line_ref;
                            l_MODIFIERS_tbl(x_ind).modifier_level_code := cur_rec_rltd.modifier_level_code;
                            l_MODIFIERS_tbl(x_ind).accrual_flag := NVL(cur_rec_rltd.accrual_flag, 'N');
                            l_MODIFIERS_tbl(x_ind).start_date_active := cur_rec_rltd.start_date_active;
                            l_MODIFIERS_tbl(x_ind).end_date_active := cur_rec_rltd.end_date_active;
                            l_MODIFIERS_tbl(x_ind).operand := cur_rec_rltd.operand;
                            l_MODIFIERS_tbl(x_ind).arithmetic_operator := cur_rec_rltd.arithmetic_operator;
                            l_MODIFIERS_tbl(x_ind).pricing_group_sequence := cur_rec_rltd.pricing_group_sequence;
                            l_MODIFIERS_tbl(x_ind).pricing_phase_id := cur_rec_rltd.pricing_phase_id;
                            l_MODIFIERS_tbl(x_ind).qualification_ind := cur_rec.qualification_ind;
                            l_MODIFIERS_tbl(x_ind).product_precedence := NVL(cur_rec_rltd.product_precedence, xx_qp_mod_list_cnv_pkg.CN_ONE);
                            l_MODIFIERS_tbl(x_ind).price_break_type_code := cur_rec_rltd.price_break_type_code;
                            l_MODIFIERS_tbl(x_ind).modifier_parent_index := xx_qp_mod_list_cnv_pkg.CN_MDF_PARENT_IND;
                            l_MODIFIERS_tbl(x_ind).rltd_modifier_grp_no := cur_rec_rltd.rltd_modifier_grp_no;
                            l_MODIFIERS_tbl(x_ind).rltd_modifier_grp_type := cur_rec_rltd.rltd_modifier_grp_type;
                            l_MODIFIERS_tbl(x_ind).incompatibility_grp_code := cur_rec.incompatibility_grp_code;
                          --  l_MODIFIERS_tbl(x_ind).estim_accrual_rate       := cur_rec.estim_accrual_rate;
                            l_MODIFIERS_tbl(x_ind).include_on_returns_flag  := cur_rec.include_on_returns_flag;
                            l_MODIFIERS_tbl(x_ind).override_flag            := cur_rec.override_flag ;
                            l_MODIFIERS_tbl(x_ind).print_on_invoice_flag    := cur_rec.print_on_invoice_flag ;
                            l_MODIFIERS_tbl(x_ind).operation := QP_GLOBALS.G_OPR_CREATE;

                            l_PRICING_ATTR_tbl(x_ind).product_attribute_context:= cur_rec_rltd.product_attribute_context;
                            l_PRICING_ATTR_tbl(x_ind).attribute10         := cur_rec_rltd.orig_sys_line_ref;
                            --l_PRICING_ATTR_tbl(x_ind).product_attribute:= cur_rec_rltd.product_attribute_code;
                            l_PRICING_ATTR_tbl(x_ind).product_attribute:= cur_rec_rltd.product_attribute;
                            l_PRICING_ATTR_tbl(x_ind).product_attr_value:= cur_rec_rltd.product_attr_value_code;
                            --l_PRICING_ATTR_tbl(x_ind).product_attr_value:= cur_rec_rltd.product_attr_value_code;
                            l_PRICING_ATTR_tbl(x_ind).pricing_attribute_context:= cur_rec_rltd.pricing_attribute_context;
                            l_PRICING_ATTR_tbl(x_ind).pricing_attribute:= cur_rec_rltd.pricing_attribute;
                            l_PRICING_ATTR_tbl(x_ind).pricing_attr_value_from:= cur_rec_rltd.pricing_attr_value_from;
                            l_PRICING_ATTR_tbl(x_ind).pricing_attr_value_to:= cur_rec_rltd.pricing_attr_value_to;
                            l_PRICING_ATTR_tbl(x_ind).comparison_operator_code:= cur_rec_rltd.comparison_operator_code;
                            l_PRICING_ATTR_tbl(x_ind).product_uom_code:= cur_rec_rltd.product_uom_code;
                            l_PRICING_ATTR_tbl(x_ind).excluder_flag:= NVL(cur_rec_rltd.excluder_flag, 'N');
                            l_PRICING_ATTR_tbl(x_ind).MODIFIERS_index:=x_ind;
                            l_PRICING_ATTR_tbl(x_ind).operation                  := QP_GLOBALS.G_OPR_CREATE;

                        END LOOP; --c_pre_std_rltd_hdr
                    END IF; -- cur_rec.list_line_type_code = 'PBH'
                    ----debjani call api if lines count is greater than 25000 to avoid memory space error-----------------


                    IF x_ind >24999 /*x_ind >5*/ AND x_ind < cur_dis_rec.custom_lines_count
                       AND cur_rec.from_orig_sys_hdr_ref IS NULL THEN
                        BEGIN
                       SELECT TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS') INTO x_sys_time FROM DUAL;
                          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'System Time'
                                 ,p_record_identifier_1 => cur_dis_rec.orig_sys_header_ref
                                 ,p_record_identifier_2 => 'Before create mod api call 25000 lines'
                                 ,p_record_identifier_3 => x_sys_time
                                 );
                    EXCEPTION
                       WHEN OTHERS THEN
                          NULL;
                    END;
                    BEGIN
                    --debjani
                    /*oe_debug_pub.initialize;
                    oe_debug_pub.setdebuglevel(5);
                    oe_debug_pub.add('Test Debug');*/
                    --debjani
                    QP_Modifiers_PUB.Process_Modifiers
                        ( p_api_version_number => xx_qp_mod_list_cnv_pkg.CN_API_VER_NO
                        , p_init_msg_list           => FND_API.G_FALSE
                        , p_return_values           => FND_API.G_FALSE
                        , p_commit                  => FND_API.G_FALSE
                        , x_return_status           => l_return_status
                        , x_msg_count               => gpr_msg_count
                        , x_msg_data                => gpr_msg_data
                        , p_MODIFIER_LIST_rec       => l_MODIFIER_LIST_rec
                        , p_MODIFIERS_tbl           => l_MODIFIERS_tbl
                        , p_QUALIFIERS_tbl          => l_QUALIFIERS_tbl
                        , p_PRICING_ATTR_tbl        => l_PRICING_ATTR_tbl
                        , x_MODIFIER_LIST_rec       => l_x_MODIFIER_LIST_rec
                        , x_MODIFIER_LIST_val_rec   => l_x_MODIFIER_LIST_val_rec
                        , x_MODIFIERS_tbl           => l_x_MODIFIERS_tbl
                        , x_MODIFIERS_val_tbl       => l_x_MODIFIERS_val_tbl
                        , x_QUALIFIERS_tbl          => l_x_QUALIFIERS_tbl
                        , x_QUALIFIERS_val_tbl      => l_x_QUALIFIERS_val_tbl
                        , x_PRICING_ATTR_tbl        => l_x_PRICING_ATTR_tbl
                        , x_PRICING_ATTR_val_tbl    => l_x_PRICING_ATTR_val_tbl
                    );
                    --debjani
                    --fnd_file.put_line(fnd_file.log,'File name '||OE_DEBUG_PUB.G_DIR||'/'||OE_DEBUG_PUB.G_FILE);

                        BEGIN

                       SELECT TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS') INTO x_sys_time FROM DUAL;
                          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'l_MODIFIER_LIST_rec.list_header_id'
                                 ,p_record_identifier_1 => l_MODIFIER_LIST_rec.list_header_id
                                 ,p_record_identifier_2 => 'Aft create mod api call 25000 lines'
                                 ,p_record_identifier_3 => x_sys_time
                                 );

                          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'l_x_MODIFIER_LIST_rec.list_header_id'
                                 ,p_record_identifier_1 => l_x_MODIFIER_LIST_rec.list_header_id
                                 ,p_record_identifier_2 => 'Aft create mod api call 25000 lines'
                                 ,p_record_identifier_3 => x_sys_time
                                 );
                    EXCEPTION
                       WHEN OTHERS THEN
                          NULL;
                    END;
                    --debjani
                    ---**********---
                    l_QUALIFIERS_tbl.DELETE;
                    IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                      FOR k IN 1 .. gpr_msg_count
                      LOOP
                         gpr_msg_data := oe_msg_pub.get ( p_msg_index => k, p_encoded => 'F' );
                         gpr_msg_data2 := gpr_msg_data2 || LTRIM ( RTRIM ( gpr_msg_data ));
                         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error Msg... =>' || gpr_msg_data );
                         fnd_file.put_line(fnd_file.log,'Error Msg Hdr... =>' || gpr_msg_data );
                      END LOOP;
                       x_hdr_err_flag  := 'Y';
                       IF l_x_MODIFIERS_tbl.count > 0 THEN
                             FOR k in 1 .. l_x_MODIFIERS_tbl.count LOOP
                                xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Looping through lines' );
                                IF l_x_MODIFIERS_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One or more Modlist Line Creation Failed' );
                                   x_line_err_flag := 'Y';

                                   mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                         -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                         , l_MODIFIER_LIST_rec.orig_system_header_ref
                                                         , l_x_MODIFIERS_tbl(k).attribute10
                                                         , NULL
                                                         , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                         );
                                END IF;

                             END LOOP;
                          END IF;

                         IF l_x_PRICING_ATTR_tbl.count > 0 THEN
                             FOR k in 1 .. l_x_PRICING_ATTR_tbl.count LOOP
                                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Looping through line attributes' );

                                IF l_x_PRICING_ATTR_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One or more Modlist Attribute Creation Failed' );
                                   x_attr_err_flag := 'Y';

                                   mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                         -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                         , l_MODIFIER_LIST_rec.orig_system_header_ref
                                                         , l_x_PRICING_ATTR_tbl(k).attribute10
                                                         , NULL
                                                         , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                         );
                                END IF;
                             END LOOP;

                          END IF;
                       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Modifier Creation => Failure ');
                       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                    ELSE
                          IF l_x_MODIFIERS_tbl.count > 0 THEN
                             FOR k in 1 .. l_x_MODIFIERS_tbl.count LOOP

                                IF l_x_MODIFIERS_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One or more Modlist Line Creation Failed' );
                                   x_line_err_flag := 'Y';

                                   mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                         -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                         , l_MODIFIER_LIST_rec.orig_system_header_ref
                                                         , l_x_MODIFIERS_tbl(k).attribute10
                                                         , NULL
                                                         , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                         );
                                END IF;

                             END LOOP;
                             IF NVL(x_line_err_flag,'X') <> 'Y' THEN
                                xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Successful Modlist Line Creation' );
                             END IF;
                          END IF;

                          IF l_x_QUALIFIERS_tbl.count > 0 THEN
                             FOR k in 1 .. l_x_QUALIFIERS_tbl.count LOOP

                                IF l_x_QUALIFIERS_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One or more Modlist Qualifier Creation Failed' );
                                   x_qlf_err_flag := 'Y';
                                END IF;

                             END LOOP;
                             IF NVL(x_qlf_err_flag,'X') <> 'Y' THEN
                                xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Successful ModList Qualifier Creation' );
                             END IF;
                          END IF;

                         IF l_x_PRICING_ATTR_tbl.count > 0 THEN
                             FOR k in 1 .. l_x_PRICING_ATTR_tbl.count LOOP

                                IF l_x_PRICING_ATTR_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One or more Modlist Attribute Creation Failed' );
                                   x_attr_err_flag := 'Y';

                                   mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                         -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                         , l_MODIFIER_LIST_rec.orig_system_header_ref
                                                         , l_x_PRICING_ATTR_tbl(k).attribute10
                                                         , NULL
                                                         , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                         );
                                END IF;
                             END LOOP;

                             IF NVL(x_attr_err_flag,'X') <> 'Y' THEN
                                xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Successful ModList Attrubute Creation' );
                             END IF;
                          END IF;

                       --COMMIT;
                       --ROLLBACK;--DROY CHANGE TO COMMIT AFTER TESTING
                       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Modifier Creation => Success'||cur_dis_rec.name  ||'-'
                                                                                               ||cur_dis_rec.list_type_code);
                    END IF;
                EXCEPTION
                WHEN FND_API.G_EXC_ERROR THEN
                    l_return_status := FND_API.G_RET_STS_ERROR;
                    ROLLBACK;
                    xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                          ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                          ,p_error_text               => gpr_msg_data
                          ,p_record_identifier_1      => cur_dis_rec.orig_sys_header_ref
                          );
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg => G_EXEC_ERROR');

                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'mark_records_for_api_error => xx_emf_cn_pkg.CN_PROCESS_DATA'||
                                                              xx_emf_cn_pkg.CN_PROCESS_DATA
                                                              ||'cur_dis_rec.name '
                                                              ||cur_dis_rec.name
                                                              ||'cur_dis_rec.list_type_code'
                                                              ||cur_dis_rec.list_type_code);

                     mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                  , cur_dis_rec.orig_sys_header_ref
                                                  , NULL
                                                   , NULL
                                                 , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                 );
                WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
                   ROLLBACK;
                   FOR k IN 1 .. gpr_msg_count LOOP
                        gpr_msg_data := oe_msg_pub.get
                                            ( p_msg_index => k
                                             ,p_encoded => 'F');
                        xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                              ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                              ,p_error_text               => gpr_msg_data
                              ,p_record_identifier_1      => cur_dis_rec.orig_sys_header_ref
                             -- ,p_record_identifier_2      => cur_dis_rec.name
                             );
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg In G_EXC_UNEXPECTED_ERROR =>'||gpr_msg_data);

                        /*mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA
                                    ,cur_dis_rec.name
                                    ,cur_dis_rec.list_type_code);   */ --commented to avoid exception
                   END LOOP;
                   mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                              , cur_dis_rec.orig_sys_header_ref
                                              , NULL
                                              , NULL
                                              , SUBSTR ( gpr_msg_data, 1, 1000 )
                                               );

                WHEN OTHERS THEN
                   ROLLBACK;
                   FOR k IN 1 .. gpr_msg_count LOOP
                        gpr_msg_data := oe_msg_pub.get
                                            ( p_msg_index => k
                                             ,p_encoded => 'F');
                        xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                              ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                              ,p_error_text               => gpr_msg_data
                              ,p_record_identifier_1      => cur_dis_rec.orig_sys_header_ref
                             -- ,p_record_identifier_2      => cur_dis_rec.name
                             );
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg =>'||gpr_msg_data);

                        mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                   , cur_dis_rec.orig_sys_header_ref
                                                   , NULL
                                                   , NULL
                                                  , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                 );

                   END LOOP;
                END;
                xx_qlf_pre_tab_type.DELETE;
                l_MODIFIERS_tbl.DELETE;
                l_PRICING_ATTR_tbl.DELETE;
                x_ind := 0;
                l_MODIFIER_LIST_rec.list_header_id := l_x_MODIFIER_LIST_rec.list_header_id;
                l_MODIFIER_LIST_rec.operation   := QP_GLOBALS.G_OPR_UPDATE;
                END IF; --IF x_ind >24999 AND x_ind < cur_dis_rec.custom_lines_count
                    ----debjani call api end to avoid memory space error--------------------------------------------------
                END LOOP; --c_pre_std_hdr

                --xx_qlf_pre_tab_type.DELETE;

                BEGIN
                       SELECT TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS') INTO x_sys_time FROM DUAL;
                          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'System Time'
                                 ,p_record_identifier_1 => cur_dis_rec.orig_sys_header_ref
                                 ,p_record_identifier_2 => 'Before create mod api call'
                                 ,p_record_identifier_3 => x_sys_time
                                 );
                    EXCEPTION
                       WHEN OTHERS THEN
                          NULL;
                    END;
                BEGIN
                    --debjani
                    /*oe_debug_pub.initialize;
                    oe_debug_pub.setdebuglevel(5);
                    oe_debug_pub.add('Test Debug');*/
                    --debjani
                    QP_Modifiers_PUB.Process_Modifiers
                        ( p_api_version_number => xx_qp_mod_list_cnv_pkg.CN_API_VER_NO
                        , p_init_msg_list           => FND_API.G_FALSE
                        , p_return_values           => FND_API.G_FALSE
                        , p_commit                  => FND_API.G_FALSE
                        , x_return_status           => l_return_status
                        , x_msg_count               => gpr_msg_count
                        , x_msg_data                => gpr_msg_data
                        , p_MODIFIER_LIST_rec       => l_MODIFIER_LIST_rec
                        , p_MODIFIERS_tbl           => l_MODIFIERS_tbl
                        , p_QUALIFIERS_tbl          => l_QUALIFIERS_tbl
                        , p_PRICING_ATTR_tbl        => l_PRICING_ATTR_tbl
                        , x_MODIFIER_LIST_rec       => l_x_MODIFIER_LIST_rec
                        , x_MODIFIER_LIST_val_rec   => l_x_MODIFIER_LIST_val_rec
                        , x_MODIFIERS_tbl           => l_x_MODIFIERS_tbl
                        , x_MODIFIERS_val_tbl       => l_x_MODIFIERS_val_tbl
                        , x_QUALIFIERS_tbl          => l_x_QUALIFIERS_tbl
                        , x_QUALIFIERS_val_tbl      => l_x_QUALIFIERS_val_tbl
                        , x_PRICING_ATTR_tbl        => l_x_PRICING_ATTR_tbl
                        , x_PRICING_ATTR_val_tbl    => l_x_PRICING_ATTR_val_tbl
                    );
                    --debjani
                    --fnd_file.put_line(fnd_file.log,'File name '||OE_DEBUG_PUB.G_DIR||'/'||OE_DEBUG_PUB.G_FILE);
                    --debjani
                    ---**********---
                    l_QUALIFIERS_tbl.DELETE;
                    IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                      FOR k IN 1 .. gpr_msg_count
                      LOOP
                         gpr_msg_data := oe_msg_pub.get ( p_msg_index => k, p_encoded => 'F' );
                         gpr_msg_data2 := gpr_msg_data2 || LTRIM ( RTRIM ( gpr_msg_data ));
                         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error Msg... =>' || gpr_msg_data );
                         fnd_file.put_line(fnd_file.log,'Error Msg Hdr... =>' || gpr_msg_data );
                      END LOOP;
                       x_hdr_err_flag  := 'Y';
                       IF l_x_MODIFIERS_tbl.count > 0 THEN
                             FOR k in 1 .. l_x_MODIFIERS_tbl.count LOOP
                                xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Looping through lines' );
                                IF l_x_MODIFIERS_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One or more Modlist Line Creation Failed' );
                                   x_line_err_flag := 'Y';

                                   mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                         -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                         , l_MODIFIER_LIST_rec.orig_system_header_ref
                                                         , l_x_MODIFIERS_tbl(k).attribute10
                                                         , NULL
                                                         , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                         );
                                END IF;

                             END LOOP;
                          END IF;

                         IF l_x_PRICING_ATTR_tbl.count > 0 THEN
                             FOR k in 1 .. l_x_PRICING_ATTR_tbl.count LOOP
                                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Looping through line attributes' );

                                IF l_x_PRICING_ATTR_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One or more Modlist Attribute Creation Failed' );
                                   x_attr_err_flag := 'Y';

                                   mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                         -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                         , l_MODIFIER_LIST_rec.orig_system_header_ref
                                                         , l_x_PRICING_ATTR_tbl(k).attribute10
                                                         , NULL
                                                         , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                         );
                                END IF;
                             END LOOP;

                          END IF;
                       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Modifier Creation => Failure ');
                       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                    ELSE
                          IF l_x_MODIFIERS_tbl.count > 0 THEN
                             FOR k in 1 .. l_x_MODIFIERS_tbl.count LOOP

                                IF l_x_MODIFIERS_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One or more Modlist Line Creation Failed' );
                                   x_line_err_flag := 'Y';

                                   mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                         -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                         , l_MODIFIER_LIST_rec.orig_system_header_ref
                                                         , l_x_MODIFIERS_tbl(k).attribute10
                                                         , NULL
                                                         , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                         );
                                END IF;

                             END LOOP;
                             IF NVL(x_line_err_flag,'X') <> 'Y' THEN
                                xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Successful Modlist Line Creation' );
                             END IF;
                          END IF;

                          IF l_x_QUALIFIERS_tbl.count > 0 THEN
                             FOR k in 1 .. l_x_QUALIFIERS_tbl.count LOOP

                                IF l_x_QUALIFIERS_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One or more Modlist Qualifier Creation Failed' );
                                   x_qlf_err_flag := 'Y';
                                END IF;

                             END LOOP;
                             IF NVL(x_qlf_err_flag,'X') <> 'Y' THEN
                                xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Successful ModList Qualifier Creation' );
                             END IF;
                          END IF;

                         IF l_x_PRICING_ATTR_tbl.count > 0 THEN
                             FOR k in 1 .. l_x_PRICING_ATTR_tbl.count LOOP

                                IF l_x_PRICING_ATTR_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One or more Modlist Attribute Creation Failed' );
                                   x_attr_err_flag := 'Y';

                                   mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                         -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                         , l_MODIFIER_LIST_rec.orig_system_header_ref
                                                         , l_x_PRICING_ATTR_tbl(k).attribute10
                                                         , NULL
                                                         , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                         );
                                END IF;
                             END LOOP;

                             IF NVL(x_attr_err_flag,'X') <> 'Y' THEN
                                xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Successful ModList Attrubute Creation' );
                             END IF;
                          END IF;

                       --COMMIT;
                       --ROLLBACK;--DROY CHANGE TO COMMIT AFTER TESTING
                       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Modifier Creation => Success'||cur_dis_rec.name  ||'-'
                                                                                               ||cur_dis_rec.list_type_code);
                    END IF;
                EXCEPTION
                WHEN FND_API.G_EXC_ERROR THEN
                    l_return_status := FND_API.G_RET_STS_ERROR;
                    ROLLBACK;
                    xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                          ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                          ,p_error_text               => gpr_msg_data
                          ,p_record_identifier_1      => cur_dis_rec.orig_sys_header_ref
                          );
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg => G_EXEC_ERROR');

                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'mark_records_for_api_error => xx_emf_cn_pkg.CN_PROCESS_DATA'||
                                                              xx_emf_cn_pkg.CN_PROCESS_DATA
                                                              ||'cur_dis_rec.name '
                                                              ||cur_dis_rec.name
                                                              ||'cur_dis_rec.list_type_code'
                                                              ||cur_dis_rec.list_type_code);

                     mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                  , cur_dis_rec.orig_sys_header_ref
                                                  , NULL
                                                   , NULL
                                                 , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                 );
                WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
                   ROLLBACK;
                   FOR k IN 1 .. gpr_msg_count LOOP
                        gpr_msg_data := oe_msg_pub.get
                                            ( p_msg_index => k
                                             ,p_encoded => 'F');
                        xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                              ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                              ,p_error_text               => gpr_msg_data
                              ,p_record_identifier_1      => cur_dis_rec.orig_sys_header_ref
                             -- ,p_record_identifier_2      => cur_dis_rec.name
                             );
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg In G_EXC_UNEXPECTED_ERROR =>'||gpr_msg_data);

                        /*mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA
                                    ,cur_dis_rec.name
                                    ,cur_dis_rec.list_type_code);   */ --commented to avoid exception
                   END LOOP;
                   mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                              , cur_dis_rec.orig_sys_header_ref
                                              , NULL
                                              , NULL
                                              , SUBSTR ( gpr_msg_data, 1, 1000 )
                                               );

                WHEN OTHERS THEN
                   ROLLBACK;
                   FOR k IN 1 .. gpr_msg_count LOOP
                        gpr_msg_data := oe_msg_pub.get
                                            ( p_msg_index => k
                                             ,p_encoded => 'F');
                        xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                              ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                              ,p_error_text               => gpr_msg_data
                              ,p_record_identifier_1      => cur_dis_rec.orig_sys_header_ref
                             -- ,p_record_identifier_2      => cur_dis_rec.name
                             );
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg =>'||gpr_msg_data);

                        mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                   , cur_dis_rec.orig_sys_header_ref
                                                   , NULL
                                                   , NULL
                                                  , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                 );

                   END LOOP;
                END;
                BEGIN
                       SELECT TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS') INTO x_sys_time FROM DUAL;
                          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'System Time'
                                 ,p_record_identifier_1 => cur_dis_rec.orig_sys_header_ref
                                 ,p_record_identifier_2 => 'After create mod API call'
                                 ,p_record_identifier_3 => x_sys_time
                                 );
                    EXCEPTION
                       WHEN OTHERS THEN
                          NULL;
                    END;

                IF x_hdr_err_flag  = 'Y'
                              OR  x_line_err_flag = 'Y'
                              OR x_attr_err_flag = 'Y'
                              OR x_qlf_err_flag = 'Y'
                              THEN
                ROLLBACK;
                   mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                              , cur_dis_rec.orig_sys_header_ref
                                              , NULL
                                              , NULL
                                              , SUBSTR ( gpr_msg_data, 1, 1000 )
                                              );

                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                           ,    'Rollback Modlist for Orig Sys:' ||cur_dis_rec.orig_sys_header_ref
                              );
                ELSE
                                   IF NVL(x_qlf_err_flag,'X') <> 'Y' THEN
                      COMMIT;
                      --ROLLBACK;

                      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                           ,    'Commit Modlist for Orig Sys:' ||cur_dis_rec.orig_sys_header_ref
                              );
                   ELSE
                      ROLLBACK;
                      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                           ,    'Rollback Modlist for Orig Sys:' ||cur_dis_rec.orig_sys_header_ref
                              );
                   END IF;
                END IF;

            END LOOP;   --c_pre_dis_mdf
        --RETURN x_error_code;

        EXCEPTION
        WHEN OTHERS THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~Error: Processing records=>'||SQLERRM);
          x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                           ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                           ,p_error_text  => 'Errors In calling API =>'||SQLERRM);
          --RETURN x_error_code;
        END process_data_insert_mode;

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
           FROM xx_qp_mdpr_list_hdr_pre xgp
         WHERE  xgp.request_id = xx_emf_pkg.g_request_id
            AND xgp.process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
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
           FROM xx_qp_mdpr_list_lines_pre xgp
         WHERE  xgp.request_id = xx_emf_pkg.g_request_id
            AND xgp.batch_id = g_batch_id
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
           FROM xx_qp_mdpr_list_qlf_pre xgp
         WHERE xgp.request_id = xx_emf_pkg.g_request_id
            AND xgp.batch_id = g_batch_id
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


    PROCEDURE main (
            errbuf OUT VARCHAR2,
            retcode OUT VARCHAR2,
            p_batch_id IN VARCHAR2,
            p_restart_flag IN VARCHAR2,
            p_override_flag IN VARCHAR2 ,
            p_validate_and_load IN VARCHAR2
    ) IS

        x_error_code NUMBER :=      xx_emf_cn_pkg.CN_SUCCESS;
        x_pre_std_hdr_mdf_table     G_XX_MDPR_HDR_PRE_TAB_TYPE;
        x_pre_std_lines_mdf_table   G_XX_MDPR_LINES_PRE_TAB_TYPE;
        x_pre_std_hdr_qlf_table     G_XX_QLF_PRE_TAB_TYPE;

        -- CURSOR FOR VARIOUS STAGES
        CURSOR c_xx_cnv_pre_std_mdf_hdr ( cp_process_status VARCHAR2) IS
        SELECT
            --
            -- Add Columns if you want
            --
              hdr.*
          FROM xx_qp_mdpr_list_hdr_pre hdr
         WHERE batch_id = G_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID
           AND process_code = cp_process_status
           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         ORDER BY record_number;

        CURSOR c_xx_cnv_pre_std_mdf_lines ( cp_process_status VARCHAR2) IS
        SELECT
            --
            -- Add Columns if you want
            --
              lines.*
          FROM xx_qp_mdpr_list_lines_pre lines
         WHERE batch_id = G_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID
           AND process_code = cp_process_status
           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         ORDER BY record_number;

        CURSOR c_xx_cnv_pre_std_qlf_hdr ( cp_process_status VARCHAR2) IS
        SELECT
            --
            -- Add Columns if you want
            --
               hdr.*
          FROM xx_qp_mdpr_list_qlf_pre hdr
         WHERE batch_id = G_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID
           AND process_code = cp_process_status
           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         ORDER BY record_number;

    /***************** For Modifier Headers **************************/
        PROCEDURE update_record_status (
                p_conv_pre_std_hdr_rec  IN OUT  xx_qp_mdpr_list_hdr_pre%ROWTYPE,
                p_error_code            IN      VARCHAR2
        )
        IS
        BEGIN
                IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
                THEN
                        p_conv_pre_std_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                ELSE
                        --p_conv_pre_std_hdr_rec.error_code := xx_emf_cn_pkg.CN_SUCCESS;
                        p_conv_pre_std_hdr_rec.error_code :=  NVL (p_error_code, xx_emf_cn_pkg.CN_REC_ERR) ;
                END IF;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~Inside update_record_status For Mdf, G_STAGE=' || G_STAGE);
                p_conv_pre_std_hdr_rec.process_code := G_STAGE;
        END update_record_status;

    /***************** For Modifier Lines **************************/
        PROCEDURE update_record_status (
                p_conv_pre_std_lines_rec  IN OUT  xx_qp_mdpr_list_lines_pre%ROWTYPE,
                p_error_code            IN      VARCHAR2
        )
        IS
        BEGIN
                IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
                THEN
                        p_conv_pre_std_lines_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                ELSE
                        p_conv_pre_std_lines_rec.error_code := xx_emf_cn_pkg.CN_SUCCESS; /*xx_asl_common_pkg.find_max (p_error_code
                                                                                                    ,NVL (p_conv_pre_std_hdr_rec.error_code
                                                                                                    , xx_emf_cn_pkg.CN_SUCCESS));*/ --DROY
                END IF;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~Inside update_record_status For Mdf, G_STAGE=' || G_STAGE);
                p_conv_pre_std_lines_rec.process_code := G_STAGE;
        END update_record_status;

    /***************** For Qualifiers **************************/
        PROCEDURE update_record_status (
                p_conv_pre_std_hdr_rec  IN OUT  xx_qp_mdpr_list_qlf_pre%ROWTYPE,
                p_error_code            IN      VARCHAR2
        )
        IS
        BEGIN
                IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
                THEN
                        p_conv_pre_std_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                ELSE
                        p_conv_pre_std_hdr_rec.error_code := xx_emf_cn_pkg.CN_SUCCESS;/*xx_asl_common_pkg.find_max (p_error_code
                                                                                        ,NVL (p_conv_pre_std_hdr_rec.error_code
                                                                                        , xx_emf_cn_pkg.CN_SUCCESS));*/ --DROY
                END IF;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~Inside update_record_status For Qlf, G_STAGE=' || G_STAGE);
                p_conv_pre_std_hdr_rec.process_code := G_STAGE;
        END update_record_status;


        PROCEDURE mark_records_complete
        (
                p_process_code VARCHAR2
        )
        IS
                x_last_update_date      DATE := SYSDATE;
                x_last_updated_by        NUMBER := fnd_global.user_id;
                x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
                PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN

                UPDATE xx_qp_mdpr_list_hdr_pre
                   SET process_code = G_STAGE,
                       error_code = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
                       last_updated_by = x_last_updated_by,
                       last_update_date = x_last_update_date,
                       last_update_login = x_last_update_login
                 WHERE batch_id = G_BATCH_ID
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
                   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~No of Records for Modifier Headers marked after '||p_process_code||' =>'||SQL%ROWCOUNT);

                UPDATE xx_qp_mdpr_list_lines_pre
                   SET process_code = G_STAGE,
                       error_code = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
                       last_updated_by = x_last_updated_by,
                       last_update_date = x_last_update_date,
                       last_update_login = x_last_update_login
                 WHERE batch_id = G_BATCH_ID
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
                   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~No of Records for Modifier Lines marked after '||p_process_code||' =>'||SQL%ROWCOUNT);

                UPDATE xx_qp_mdpr_list_qlf_pre
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


        /***************** For Modifiers **************************/
        PROCEDURE update_pre_interface_records (p_cnv_pre_std_hdr_table IN g_xx_mdpr_hdr_pre_tab_type)
        IS
                x_last_update_date      DATE := SYSDATE;
                x_last_updated_by        NUMBER := fnd_global.user_id;
                x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

                PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~UPDATE_PRE_INTERFACE_RECORDS FOR MODIFIER HDR');
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table.COUNT FOR MODIFIER HDR '||p_cnv_pre_std_hdr_table.COUNT );
                FOR indx IN 1 .. p_cnv_pre_std_hdr_table.COUNT LOOP
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).process_code ' || p_cnv_pre_std_hdr_table(indx).process_code);
--                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).error_code ' || p_cnv_pre_std_hdr_table(indx).error_code);
                        /*xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).product_attr_value ' ||
                                                                       p_cnv_pre_std_hdr_table(indx).product_attr_value);*/
--                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).product_attribute ' ||
                                                                      -- p_cnv_pre_std_hdr_table(indx).product_attribute);
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).record_number ' || p_cnv_pre_std_hdr_table(indx).record_number);

                        UPDATE xx_qp_mdpr_list_hdr_pre
                           SET
                            active_flag	=	p_cnv_pre_std_hdr_table(indx).active_flag ,
                            list_type_code	=	p_cnv_pre_std_hdr_table(indx).list_type_code ,
                            --list_type	=	p_cnv_pre_std_hdr_table(indx).list_type ,
                            name	=	p_cnv_pre_std_hdr_table(indx).name ,
                            description	=	p_cnv_pre_std_hdr_table(indx).description ,
                            version_no	=	p_cnv_pre_std_hdr_table(indx).version_no ,
                            discount_lines_flag	=	p_cnv_pre_std_hdr_table(indx).discount_lines_flag ,
                            global_flag	=	p_cnv_pre_std_hdr_table(indx).global_flag ,
                            start_date_active	=	p_cnv_pre_std_hdr_table(indx).start_date_active ,
                            end_date_active	=	p_cnv_pre_std_hdr_table(indx).end_date_active ,
                            currency_code	=	p_cnv_pre_std_hdr_table(indx).currency_code ,
                            freight_terms_code	=	p_cnv_pre_std_hdr_table(indx).freight_terms_code ,
                            rounding_factor	=	p_cnv_pre_std_hdr_table(indx).rounding_factor ,
                            gsa_indicator	=	p_cnv_pre_std_hdr_table(indx).gsa_indicator ,
                            automatic_flag	=	p_cnv_pre_std_hdr_table(indx).automatic_flag ,
                            source_system_code	=	p_cnv_pre_std_hdr_table(indx).source_system_code ,
                            source_system_name	=	p_cnv_pre_std_hdr_table(indx).source_system_name ,
                            pte_code	=	p_cnv_pre_std_hdr_table(indx).pte_code ,
                            orig_org_name	=	p_cnv_pre_std_hdr_table(indx).orig_org_name ,
                            org_id	=	p_cnv_pre_std_hdr_table(indx).org_id ,
                            --pte	=	p_cnv_pre_std_hdr_table(indx).pte ,
                            comments	=	p_cnv_pre_std_hdr_table(indx).comments ,
                            /*context	=	p_cnv_pre_std_hdr_table(indx).context ,
                            modifier_no	=	p_cnv_pre_std_hdr_table(indx).modifier_no ,
                            start_date_active_first	=	p_cnv_pre_std_hdr_table(indx).start_date_active_first ,
                            end_date_active_first	=	p_cnv_pre_std_hdr_table(indx).end_date_active_first ,
                            start_date_active_second	=	p_cnv_pre_std_hdr_table(indx).start_date_active_second ,
                            end_date_active_second	=	p_cnv_pre_std_hdr_table(indx).end_date_active_second ,
                            arithmetic_operator	=	p_cnv_pre_std_hdr_table(indx).arithmetic_operator ,
                            arithmetic_operator_desc	=	p_cnv_pre_std_hdr_table(indx).arithmetic_operator_desc ,
                            orig_org_name	=	p_cnv_pre_std_hdr_table(indx).orig_org_name ,
                            org_id	=	p_cnv_pre_std_hdr_table(indx).org_id ,
                            organization_name	=	p_cnv_pre_std_hdr_table(indx).organization_name ,
                            --delete_flag	=	p_cnv_pre_std_hdr_table(indx).delete_flag ,
                            -- lock_flag	=	p_cnv_pre_std_hdr_table(indx).lock_flag ,
                            -- attribute_status	=	p_cnv_pre_std_hdr_table(indx).attribute_status ,
                            /*charge_type_code	=	p_cnv_pre_std_hdr_table(indx).charge_type_code ,
                            effective_period_uom	=	p_cnv_pre_std_hdr_table(indx).effective_period_uom ,
                            expiration_date	=	p_cnv_pre_std_hdr_table(indx).expiration_date ,
                            expiration_period_start_date	=	p_cnv_pre_std_hdr_table(indx).expiration_period_start_date ,
                            expiration_period_uom	=	p_cnv_pre_std_hdr_table(indx).expiration_period_uom ,
                            net_amount_flag	=	p_cnv_pre_std_hdr_table(indx).net_amount_flag ,
                            number_expiration_periods	=	p_cnv_pre_std_hdr_table(indx).number_expiration_periods ,
                            override_flag	=	p_cnv_pre_std_hdr_table(indx).override_flag ,
                            primary_uom_flag	=	p_cnv_pre_std_hdr_table(indx).primary_uom_flag ,
                            proration_type_code	=	p_cnv_pre_std_hdr_table(indx).proration_type_code ,
                            qualification_ind	=	p_cnv_pre_std_hdr_table(indx).qualification_ind ,
                            reprice_flag	=	p_cnv_pre_std_hdr_table(indx).reprice_flag ,
                            revision	=	p_cnv_pre_std_hdr_table(indx).revision ,
                            revision_date	=	p_cnv_pre_std_hdr_table(indx).revision_date ,
                            revision_reason_code	=	p_cnv_pre_std_hdr_table(indx).revision_reason_code ,
                            substitution_attribute	=	p_cnv_pre_std_hdr_table(indx).substitution_attribute ,
                            substitution_context	=	p_cnv_pre_std_hdr_table(indx).substitution_context ,
                            substitution_value	=	p_cnv_pre_std_hdr_table(indx).substitution_value ,
                            list_line_type	=	p_cnv_pre_std_hdr_table(indx).list_line_type ,
                            list_line_type_code	=	p_cnv_pre_std_hdr_table(indx).list_line_type_code ,
                            start_date_active	=	p_cnv_pre_std_hdr_table(indx).start_date_active ,
                            end_date_active	=	p_cnv_pre_std_hdr_table(indx).end_date_active ,
                            accrual_flag	=	p_cnv_pre_std_hdr_table(indx).accrual_flag ,
                            modifier_level	=	p_cnv_pre_std_hdr_table(indx).modifier_level ,
                            modifier_level_code	=	p_cnv_pre_std_hdr_table(indx).modifier_level_code ,
                            pricing_group_sequence	=	p_cnv_pre_std_hdr_table(indx).pricing_group_sequence ,
                            pricing_grp_seq_name	=	p_cnv_pre_std_hdr_table(indx).pricing_grp_seq_name ,
                            pricing_phase_name	=	p_cnv_pre_std_hdr_table(indx).pricing_phase_name ,
                            pricing_phase_id	=	p_cnv_pre_std_hdr_table(indx).pricing_phase_id ,
                            product_precedence	=	p_cnv_pre_std_hdr_table(indx).product_precedence ,
                            price_break_type	=	p_cnv_pre_std_hdr_table(indx).price_break_type ,
                            price_break_type_code	=	p_cnv_pre_std_hdr_table(indx).price_break_type_code ,
                            modifier_parent_index	=	p_cnv_pre_std_hdr_table(indx).modifier_parent_index ,
                            operand	=	p_cnv_pre_std_hdr_table(indx).operand ,
                            rltd_modifier_grp_no	=	p_cnv_pre_std_hdr_table(indx).rltd_modifier_grp_no ,
                            rltd_modifier_grp_type	=	p_cnv_pre_std_hdr_table(indx).rltd_modifier_grp_type ,
                            --accumulate_flag	=	p_cnv_pre_std_hdr_table(indx).accumulate_flag , --DROY
                            --pricing_attr_context_desc	=	p_cnv_pre_std_hdr_table(indx).pricing_attr_context_desc ,
                            pricing_attribute_context	=	p_cnv_pre_std_hdr_table(indx).pricing_attribute_context ,
                            --product_attr_context_desc	=	p_cnv_pre_std_hdr_table(indx).product_attr_context_desc ,
                            product_attribute_context	=	p_cnv_pre_std_hdr_table(indx).product_attribute_context ,
                            product_attribute	=	p_cnv_pre_std_hdr_table(indx).product_attribute ,
                            product_attribute_code	=	p_cnv_pre_std_hdr_table(indx).product_attribute_code ,
                            pricing_attribute	=	p_cnv_pre_std_hdr_table(indx).pricing_attribute ,
                            pricing_attribute_name	=	p_cnv_pre_std_hdr_table(indx).pricing_attribute_name ,
                            product_uom_code	=	p_cnv_pre_std_hdr_table(indx).product_uom_code ,
                            product_uom_desc	=	p_cnv_pre_std_hdr_table(indx).product_uom_desc ,
                            product_attr_value	=	p_cnv_pre_std_hdr_table(indx).product_attr_value ,
                            product_attr_value_code	=	p_cnv_pre_std_hdr_table(indx).product_attr_value_code ,
                            pricing_attr_value_from	=	p_cnv_pre_std_hdr_table(indx).pricing_attr_value_from ,
                            pricing_attr_value_to	=	p_cnv_pre_std_hdr_table(indx).pricing_attr_value_to ,
                            comparison_operator_code	=	p_cnv_pre_std_hdr_table(indx).comparison_operator_code ,
                            excluder_flag	=	p_cnv_pre_std_hdr_table(indx).excluder_flag ,
                            modifiers_index	=	p_cnv_pre_std_hdr_table(indx).modifiers_index ,
                            volume_type	=	p_cnv_pre_std_hdr_table(indx).volume_type ,*/
                            --header_record_number	=	p_cnv_pre_std_hdr_table(indx).header_record_number ,
                            --line_record_number	=	p_cnv_pre_std_hdr_table(indx).line_record_number ,
                            --interface_action_code	=	p_cnv_pre_std_hdr_table(indx).interface_action_code ,
                            --process_flag	=	p_cnv_pre_std_hdr_table(indx).process_flag ,
                            --process_status_flag	=	p_cnv_pre_std_hdr_table(indx).process_status_flag ,*/ --DROY
                            --batch_id	=	p_cnv_pre_std_hdr_table(indx).batch_id ,
                            created_by	=	p_cnv_pre_std_hdr_table(indx).created_by ,
                            creation_date	=	p_cnv_pre_std_hdr_table(indx).creation_date ,
                            request_id	=	p_cnv_pre_std_hdr_table(indx).request_id ,
                            process_code	=	p_cnv_pre_std_hdr_table(indx).process_code ,
                            error_code	=	p_cnv_pre_std_hdr_table(indx).error_code ,
                            error_desc	=	p_cnv_pre_std_hdr_table(indx).error_desc ,
                            --src_file_name	=	p_cnv_pre_std_hdr_table(indx).src_file_name ,
                            --record_number	=	p_cnv_pre_std_hdr_table(indx).record_number ,
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

        /***************** For Modifier Lines **************************/
        PROCEDURE update_pre_interface_records (p_cnv_pre_std_lines_table IN g_xx_mdpr_lines_pre_tab_type)
        IS
                x_last_update_date      DATE := SYSDATE;
                x_last_updated_by        NUMBER := fnd_global.user_id;
                x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

                PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~UPDATE_PRE_INTERFACE_RECORDS FOR MODIFIER LINES');
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_lines_table.COUNT FOR MODIFIER LINES'||p_cnv_pre_std_lines_table.COUNT );
                FOR indx IN 1 .. p_cnv_pre_std_lines_table.COUNT LOOP
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_lines_table(indx).process_code ' || p_cnv_pre_std_lines_table(indx).process_code);
--                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_lines_table(indx).error_code ' || p_cnv_pre_std_lines_table(indx).error_code);
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_lines_table(indx).product_attr_value ' ||
                                                                       p_cnv_pre_std_lines_table(indx).product_attr_value);
--                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_lines_table(indx).product_attribute ' ||
                                                                      -- p_cnv_pre_std_lines_table(indx).product_attribute);
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_lines_table(indx).record_number ' || p_cnv_pre_std_lines_table(indx).record_number);

                        UPDATE xx_qp_mdpr_list_lines_pre
                           SET
                            /*active_flag	=	p_cnv_pre_std_lines_table(indx).active_flag ,
                            list_type_code	=	p_cnv_pre_std_lines_table(indx).list_type_code ,
                            list_type	=	p_cnv_pre_std_lines_table(indx).list_type ,
                            name	=	p_cnv_pre_std_lines_table(indx).name ,
                            description	=	p_cnv_pre_std_lines_table(indx).description ,
                            version_no	=	p_cnv_pre_std_lines_table(indx).version_no ,
                            discount_lines_flag	=	p_cnv_pre_std_lines_table(indx).discount_lines_flag ,
                            global_flag	=	p_cnv_pre_std_lines_table(indx).global_flag ,
                            start_date_active_hdr	=	p_cnv_pre_std_lines_table(indx).start_date_active_hdr ,
                            end_date_active_hdr	=	p_cnv_pre_std_lines_table(indx).end_date_active_hdr ,
                            currency_code	=	p_cnv_pre_std_lines_table(indx).currency_code ,
                            freight_terms_code	=	p_cnv_pre_std_lines_table(indx).freight_terms_code ,
                            rounding_factor	=	p_cnv_pre_std_lines_table(indx).rounding_factor ,
                            gsa_indicator	=	p_cnv_pre_std_lines_table(indx).gsa_indicator ,
                            automatic_flag	=	p_cnv_pre_std_lines_table(indx).automatic_flag ,
                            source_system_code	=	p_cnv_pre_std_lines_table(indx).source_system_code ,
                            -- source_system	=	p_cnv_pre_std_lines_table(indx).source_system ,
                            pte_code	=	p_cnv_pre_std_lines_table(indx).pte_code ,
                            -- pte	=	p_cnv_pre_std_lines_table(indx).pte ,
                            comments	=	p_cnv_pre_std_lines_table(indx).comments ,
                            context	=	p_cnv_pre_std_lines_table(indx).context ,*/
                            orig_sys_line_ref	=	p_cnv_pre_std_lines_table(indx).orig_sys_line_ref ,
                            /*start_date_active_first	=	p_cnv_pre_std_lines_table(indx).start_date_active_first ,
                            end_date_active_first	=	p_cnv_pre_std_lines_table(indx).end_date_active_first ,
                            start_date_active_second	=	p_cnv_pre_std_lines_table(indx).start_date_active_second ,
                            end_date_active_second	=	p_cnv_pre_std_lines_table(indx).end_date_active_second ,*/
                            arithmetic_operator	=	p_cnv_pre_std_lines_table(indx).arithmetic_operator ,
                            --arithmetic_operator_desc	=	p_cnv_pre_std_lines_table(indx).arithmetic_operator_desc ,
                            --ou_name	=	p_cnv_pre_std_lines_table(indx).ou_name ,
                            --org_id	=	p_cnv_pre_std_lines_table(indx).org_id ,
                            organization_name	=	p_cnv_pre_std_lines_table(indx).organization_name ,
                            --delete_flag	=	p_cnv_pre_std_lines_table(indx).delete_flag ,
                            -- lock_flag	=	p_cnv_pre_std_lines_table(indx).lock_flag ,
                            -- attribute_status	=	p_cnv_pre_std_lines_table(indx).attribute_status ,
                            charge_type_code	=	p_cnv_pre_std_lines_table(indx).charge_type_code ,
                            effective_period_uom	=	p_cnv_pre_std_lines_table(indx).effective_period_uom ,
                            expiration_date	=	p_cnv_pre_std_lines_table(indx).expiration_date ,
                            expiration_period_start_date	=	p_cnv_pre_std_lines_table(indx).expiration_period_start_date ,
                            expiration_period_uom	=	p_cnv_pre_std_lines_table(indx).expiration_period_uom ,
                            net_amount_flag	=	p_cnv_pre_std_lines_table(indx).net_amount_flag ,
                            number_expiration_periods	=	p_cnv_pre_std_lines_table(indx).number_expiration_periods ,
                            override_flag	=	p_cnv_pre_std_lines_table(indx).override_flag ,
                            primary_uom_flag	=	p_cnv_pre_std_lines_table(indx).primary_uom_flag ,
                            proration_type_code	=	p_cnv_pre_std_lines_table(indx).proration_type_code ,
                            qualification_ind	=	p_cnv_pre_std_lines_table(indx).qualification_ind ,
                            reprice_flag	=	p_cnv_pre_std_lines_table(indx).reprice_flag ,
                            revision	=	p_cnv_pre_std_lines_table(indx).revision ,
                            revision_date	=	p_cnv_pre_std_lines_table(indx).revision_date ,
                            revision_reason_code	=	p_cnv_pre_std_lines_table(indx).revision_reason_code ,
                            substitution_attribute	=	p_cnv_pre_std_lines_table(indx).substitution_attribute ,
                            substitution_context	=	p_cnv_pre_std_lines_table(indx).substitution_context ,
                            substitution_value	=	p_cnv_pre_std_lines_table(indx).substitution_value ,
                            -- list_line_type	=	p_cnv_pre_std_lines_table(indx).list_line_type ,
                            list_line_type_code	=	p_cnv_pre_std_lines_table(indx).list_line_type_code ,
                            start_date_active	=	p_cnv_pre_std_lines_table(indx).start_date_active ,
                            end_date_active	=	p_cnv_pre_std_lines_table(indx).end_date_active ,
                            accrual_flag	=	p_cnv_pre_std_lines_table(indx).accrual_flag ,
                            -- modifier_level	=	p_cnv_pre_std_lines_table(indx).modifier_level ,
                            modifier_level_code	=	p_cnv_pre_std_lines_table(indx).modifier_level_code ,
                            pricing_group_sequence	=	p_cnv_pre_std_lines_table(indx).pricing_group_sequence ,
                            --pricing_grp_seq_name	=	p_cnv_pre_std_lines_table(indx).pricing_grp_seq_name ,
                            pricing_phase_name	=	p_cnv_pre_std_lines_table(indx).pricing_phase_name ,
                            pricing_phase_id	=	p_cnv_pre_std_lines_table(indx).pricing_phase_id ,
                            product_precedence	=	p_cnv_pre_std_lines_table(indx).product_precedence ,
                            --price_break_type	=	p_cnv_pre_std_lines_table(indx).price_break_type ,
                            price_break_type_code	=	p_cnv_pre_std_lines_table(indx).price_break_type_code ,
                            modifier_parent_index	=	p_cnv_pre_std_lines_table(indx).modifier_parent_index ,
                            operand	=	p_cnv_pre_std_lines_table(indx).operand ,
                            rltd_modifier_grp_no	=	p_cnv_pre_std_lines_table(indx).rltd_modifier_grp_no ,
                            rltd_modifier_grp_type	=	p_cnv_pre_std_lines_table(indx).rltd_modifier_grp_type ,
                            --accumulate_flag	=	p_cnv_pre_std_lines_table(indx).accumulate_flag ,
                            --pricing_attr_context_desc	=	p_cnv_pre_std_lines_table(indx).pricing_attr_context_desc ,
                            pricing_attribute_context	=	p_cnv_pre_std_lines_table(indx).pricing_attribute_context ,
                            --product_attr_context_desc	=	p_cnv_pre_std_lines_table(indx).product_attr_context_desc ,
                            product_attribute_context	=	p_cnv_pre_std_lines_table(indx).product_attribute_context ,
                            product_attribute	=	p_cnv_pre_std_lines_table(indx).product_attribute ,
                            product_attribute_code	=	p_cnv_pre_std_lines_table(indx).product_attribute_code ,
                            pricing_attribute	=	p_cnv_pre_std_lines_table(indx).pricing_attribute ,
                            pricing_attribute_name	=	p_cnv_pre_std_lines_table(indx).pricing_attribute_name ,
                            product_uom_code	=	p_cnv_pre_std_lines_table(indx).product_uom_code ,
                            product_uom_desc	=	p_cnv_pre_std_lines_table(indx).product_uom_desc ,
                            product_attr_value	=	p_cnv_pre_std_lines_table(indx).product_attr_value ,
                            product_attr_value_code	=	p_cnv_pre_std_lines_table(indx).product_attr_value_code ,
                            pricing_attr_value_from	=	p_cnv_pre_std_lines_table(indx).pricing_attr_value_from ,
                            pricing_attr_value_to	=	p_cnv_pre_std_lines_table(indx).pricing_attr_value_to ,
                            comparison_operator_code	=	p_cnv_pre_std_lines_table(indx).comparison_operator_code ,
                            excluder_flag	=	p_cnv_pre_std_lines_table(indx).excluder_flag ,
                            modifiers_index	=	p_cnv_pre_std_lines_table(indx).modifiers_index ,
                            volume_type	=	p_cnv_pre_std_lines_table(indx).volume_type ,
                            --header_record_number	=	p_cnv_pre_std_lines_table(indx).header_record_number ,
                            --line_record_number	=	p_cnv_pre_std_lines_table(indx).line_record_number ,
                            --interface_action_code	=	p_cnv_pre_std_lines_table(indx).interface_action_code ,
                            --process_flag	=	p_cnv_pre_std_lines_table(indx).process_flag ,
                            --process_status_flag	=	p_cnv_pre_std_lines_table(indx).process_status_flag ,
                            --batch_id	=	p_cnv_pre_std_lines_table(indx).batch_id ,
                            created_by	=	p_cnv_pre_std_lines_table(indx).created_by ,
                            creation_date	=	p_cnv_pre_std_lines_table(indx).creation_date ,
                            request_id	=	p_cnv_pre_std_lines_table(indx).request_id ,
                            process_code	=	p_cnv_pre_std_lines_table(indx).process_code ,
                            error_code	=	p_cnv_pre_std_lines_table(indx).error_code ,
                            error_desc	=	p_cnv_pre_std_lines_table(indx).error_desc ,
                            --src_file_name	=	p_cnv_pre_std_lines_table(indx).src_file_name ,
                            --record_number	=	p_cnv_pre_std_lines_table(indx).record_number ,
                            last_updated_by     = x_last_updated_by,
                            last_update_date   = x_last_update_date,
                            last_update_login = x_last_update_login
                         WHERE
                         record_number = p_cnv_pre_std_lines_table(indx).record_number
                         --header_record_number = p_cnv_pre_std_lines_table(indx).header_record_number
                         AND batch_id=G_BATCH_ID;

                END LOOP;

                COMMIT;
        END update_pre_interface_records;


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
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).process_code ' || p_cnv_pre_std_hdr_table(indx).process_code);
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).record_number ' || p_cnv_pre_std_hdr_table(indx).record_number);

                        UPDATE xx_qp_mdpr_list_qlf_pre
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

        FUNCTION move_rec_pre_standard_table RETURN NUMBER
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
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Insert into xx_qp_mdpr_list_hdr_pre ');
                INSERT INTO xx_qp_mdpr_list_hdr_pre
                (
                        active_flag	,
                        list_type_code	,
                        -- list_type	,
                        name	,
                        description	,
                        version_no	,
                        discount_lines_flag	,
                        global_flag	,
                        start_date_active	,
                        end_date_active	,
                        currency_code	,
                        freight_terms_code	,
                        rounding_factor	,
                        gsa_indicator	,
                        automatic_flag	,
                        source_system_code	,
                        -- source_system	,
                        pte_code	,
                        -- pte	,
                        comments	,
                        orig_sys_header_ref	,
                        orig_org_name	,
                        /*context	,
                        modifier_no	,
                        start_date_active_first	,
                        end_date_active_first	,
                        start_date_active_second	,
                        end_date_active_second	,
                        arithmetic_operator	,
                        arithmetic_operator_desc	,
                        orig_org_name	,
                        org_id	,
                        organization_name	,
                        delete_flag	,
                        lock_flag	,
                        attribute_status	,
                        charge_type_code	,
                        effective_period_uom	,
                        expiration_date	,
                        expiration_period_start_date	,
                        expiration_period_uom	,
                        net_amount_flag	,
                        number_expiration_periods	,
                        override_flag	,
                        primary_uom_flag	,
                        proration_type_code	,
                        qualification_ind	,
                        reprice_flag	,
                        revision	,
                        revision_date	,
                        revision_reason_code	,
                        substitution_attribute	,
                        substitution_context	,
                        substitution_value	,
                        --substitution_context1	,
                        --substitution_value1	,
                        -- list_line_type	,
                        list_line_type_code	,
                        start_date_active	,
                        end_date_active	,
                        accrual_flag	,
                        -- modifier_level	,
                        modifier_level_code	,
                        pricing_group_sequence	,
                        pricing_grp_seq_name	,
                        pricing_phase_name	,
                        pricing_phase_id	,
                        product_precedence	,
                        price_break_type	,
                        price_break_type_code	,
                        modifier_parent_index	,
                        operand	,
                        rltd_modifier_grp_no	,
                        rltd_modifier_grp_type	,
                        -- accumulate_flag	,
                        --pricing_attr_context_desc	,
                        pricing_attribute_context	,
                        -- product_attr_context_desc	,
                        product_attribute_context	,
                        product_attribute	,
                        product_attribute_code	,
                        pricing_attribute	,
                        pricing_attribute_name	,
                        product_uom_code	,
                        product_uom_desc	,
                        product_attr_value	,
                        product_attr_value_code	,
                        pricing_attr_value_from	,
                        pricing_attr_value_to	,
                        comparison_operator_code	,
                        excluder_flag	,
                        modifiers_index	,
                        volume_type	,           */
                        -- header_record_number	,
                        -- line_record_number	,
                        -- interface_action_code	,
                        -- process_flag	,
                        -- process_status_flag	,
                        batch_id	,
                        error_desc	,
                        src_file_name	,
                        record_number	,
        ----
        -- Place Columns
        ---
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
                        active_flag	,
                        list_type_code	,
                        -- list_type	,
                        name	,
                        description	,
                        version_no	,
                        discount_lines_flag	,
                        global_flag	,
                        trunc(start_date_active)	,
                        trunc(end_date_active)	,
                        currency_code	,
                        freight_terms_code	,
                        rounding_factor	,
                        gsa_indicator	,
                        automatic_flag	,
                        source_system_code	,
                        -- source_system	,
                        pte_code	,
                        -- pte	,
                        comments	,
                        orig_sys_header_ref	,
                        orig_org_name	,
                        /*context	,
                        modifier_no	,
                        trunc(start_date_active_first)	,
                        trunc(end_date_active_first)	,
                        start_date_active_second	,
                        end_date_active_second	,
                        arithmetic_operator	,
                        arithmetic_operator_desc	,
                        orig_org_name	,
                        org_id	,
                        organization_name	,
                        delete_flag	,
                        lock_flag	,
                        attribute_status	,
                        charge_type_code	,
                        effective_period_uom	,
                        expiration_date	,
                        expiration_period_start_date	,
                        expiration_period_uom	,
                        net_amount_flag	,
                        number_expiration_periods	,
                        override_flag	,
                        primary_uom_flag	,
                        proration_type_code	,
                        qualification_ind	,
                        reprice_flag	,
                        revision	,
                        revision_date	,
                        revision_reason_code	,
                        substitution_attribute	,
                        substitution_context	,
                        substitution_value	,
                        --substitution_context1	,
                        --substitution_value1	,
                        list_line_type	,
                        list_line_type_code	,
                        trunc(start_date_active)	,
                        trunc(end_date_active)	,
                        accrual_flag	,
                        modifier_level	,
                        modifier_level_code	,
                        pricing_group_sequence	,
                        pricing_grp_seq_name	,
                        pricing_phase_name	,
                        pricing_phase_id	,
                        product_precedence	,
                        price_break_type	,
                        price_break_type_code	,
                        modifier_parent_index	,
                        operand	,
                        rltd_modifier_grp_no	,
                        rltd_modifier_grp_type	,
                        -- accumulate_flag	,
                        --pricing_attr_context_desc	,
                        pricing_attribute_context	,
                        -- product_attr_context_desc	,
                        product_attribute_context	,
                        product_attribute	,
                        product_attribute_code	,
                        pricing_attribute	,
                        pricing_attribute_name	,
                        product_uom_code	,
                        product_uom_desc	,
                        product_attr_value	,
                        product_attr_value_code	,
                        pricing_attr_value_from	,
                        pricing_attr_value_to	,
                        comparison_operator_code	,
                        excluder_flag	,
                        modifiers_index	,
                        volume_type	,                  */
                        -- header_record_number	,
                        -- line_record_number	,
                        -- interface_action_code	,
                        -- process_flag	,
                        -- process_status_flag	,
                        batch_id	,
                        error_desc	,
                        src_file_name	,
                        record_number,
                        G_STAGE,                --- DO NOT CHANGE FROM THIS LINE TILL MENTIONED LINE
                        error_code,                     --- DO NOT CHANGE THIS LINE
                        request_id,
                        x_created_by,
                        x_creation_date,
                        x_last_updated_by,
                        x_last_update_date,
                        x_last_update_login    -- DO NOT CHANGE TO THIS LINE
                  FROM xx_qp_mdpr_list_hdr_stg
                 WHERE BATCH_ID = G_BATCH_ID
                   AND process_code = xx_emf_cn_pkg.CN_PREVAL
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                   AND DESELECT_FLAG IS NULL;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Insert into xx_qp_mdpr_list_hdr_pre before commit');
                COMMIT;
                EXCEPTION
                WHEN OTHERS THEN
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in insertion xx_qp_mdpr_list_hdr_pre '||SQLERRM);
			xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
			x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
                        RETURN x_error_code;
                END;




                BEGIN
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Insert into xx_qp_mdpr_list_lines_pre ');
                INSERT INTO xx_qp_mdpr_list_lines_pre
                (
                        active_flag	,
                        automatic_flag  ,
                        /*list_type_code	,
                        list_type	,
                        name	,
                        description	,
                        version_no	,
                        discount_lines_flag	,
                        global_flag	,
                        start_date_active_hdr	,
                        end_date_active_hdr	,
                        currency_code	,
                        freight_terms_code	,
                        rounding_factor	,
                        gsa_indicator	,
                        automatic_flag	,
                        source_system_code	,
                        -- source_system	,
                        pte_code	,
                        -- pte	,
                        comments	, */
                        context	,
                        orig_sys_header_ref	,
                        orig_sys_line_ref	,
                        /*start_date_active_first	,
                        end_date_active_first	,
                        start_date_active_second	,
                        end_date_active_second	,*/ --DROY uncomment these cols at header
                        arithmetic_operator	,
                        -- arithmetic_operator_desc	,
                        --orig_org_name	,
                        --org_id	,
                        organization_name	,
                        --delete_flag	,
                        -- lock_flag	,
                        -- attribute_status	,
                        charge_type_code	,
                        effective_period_uom	,
                        expiration_date	,
                        expiration_period_start_date	,
                        expiration_period_uom	,
                        net_amount_flag	,
                        number_expiration_periods	,
                        override_flag	,
                        primary_uom_flag	,
                        proration_type_code	,
                        qualification_ind	,
                        reprice_flag	,
                        revision	,
                        revision_date	,
                        revision_reason_code	,
                        substitution_attribute	,
                        substitution_context	,
                        substitution_value	,
                        --substitution_context1	,
                        --substitution_value1	,
                        -- list_line_type	,
                        list_line_type_code	,
                        start_date_active	,
                        end_date_active	,
                        accrual_flag	,
                        -- modifier_level	,
                        modifier_level_code	,
                        pricing_group_sequence	,
                        -- pricing_grp_seq_name	,
                        pricing_phase_name	,
                        pricing_phase_id	,
                        product_precedence	,
                        -- price_break_type	,
                        price_break_type_code	,
                        modifier_parent_index	,
                        operand	,
                        rltd_modifier_grp_no	,
                        rltd_modifier_grp_type	,
                        -- accumulate_flag	,
                        --pricing_attr_context_desc	,
                        pricing_attribute_context	,
                        -- product_attr_context_desc	,
                        product_attribute_context	,
                        product_attribute	,
                        product_attribute_code	,
                        pricing_attribute	,
                        pricing_attribute_name	,
                        product_uom_code	,
                        product_uom_desc	,
                        product_attr_value	,
                        product_attr_value_code	,
                        pricing_attr_value_from	,
                        pricing_attr_value_to	,
                        comparison_operator_code	,
                        excluder_flag	,
                        modifiers_index	,
                        volume_type	,
                        -- header_record_number	,
                        -- line_record_number	,
                        -- interface_action_code	,
                        -- process_flag	,
                        -- process_status_flag	,
                        batch_id	,
                        error_desc	,
                        src_file_name	,
                        record_number	,
                        incompatibility_grp_code,
                        estim_accrual_rate,
                        include_on_returns_flag,
                        print_on_invoice_flag,
        ----
        -- Place Columns
        ---
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
                        active_flag	,
                        automatic_flag  ,
                        /*list_type_code	,
                        list_type	,
                        name	,
                        description	,
                        version_no	,
                        discount_lines_flag	,
                        global_flag	,
                        trunc(start_date_active_hdr)	,
                        trunc(end_date_active_hdr)	,
                        currency_code	,
                        freight_terms_code	,
                        rounding_factor	,
                        gsa_indicator	,
                        automatic_flag	,
                        source_system_code	,
                        -- source_system	,
                        pte_code	,
                        -- pte	,
                        comments	,         */
                        context	,
                        orig_sys_header_ref	,
                        orig_sys_line_ref	,
                        /*trunc(start_date_active_first)	,
                        trunc(end_date_active_first)	,
                        start_date_active_second	,
                        end_date_active_second	,     */ --DROY uncomment these cols at header
                        arithmetic_operator	,
                        -- arithmetic_operator_desc	,
                        --orig_org_name	,
                        --org_id	,
                        organization_name	,
                        --delete_flag	,
                        -- lock_flag	,
                        -- attribute_status	,
                        charge_type_code	,
                        effective_period_uom	,
                        expiration_date	,
                        expiration_period_start_date	,
                        expiration_period_uom	,
                        net_amount_flag	,
                        number_expiration_periods	,
                        override_flag	,
                        primary_uom_flag	,
                        proration_type_code	,
                        qualification_ind	,
                        reprice_flag	,
                        revision	,
                        revision_date	,
                        revision_reason_code	,
                        substitution_attribute	,
                        substitution_context	,
                        substitution_value	,
                        --substitution_context1	,
                        --substitution_value1	,
                        -- list_line_type	,
                        list_line_type_code	,
                        trunc(start_date_active)	,
                        trunc(end_date_active)	,
                        accrual_flag	,
                        -- modifier_level	,
                        modifier_level_code	,
                        pricing_group_sequence	,
                        -- pricing_grp_seq_name	,
                        pricing_phase_name	,
                        pricing_phase_id	,
                        product_precedence	,
                        -- price_break_type	,
                        price_break_type_code	,
                        modifier_parent_index	,
                        operand	,
                        rltd_modifier_grp_no	,
                        rltd_modifier_grp_type	,
                        -- accumulate_flag	,
                        --pricing_attr_context_desc	,
                        pricing_attribute_context	,
                        -- product_attr_context_desc	,
                        product_attribute_context	,
                        product_attribute	,
                        product_attribute_code	,
                        pricing_attribute	,
                        pricing_attribute_name	,
                        product_uom_code	,
                        product_uom_desc	,
                        product_attr_value	,
                        product_attr_value_code	,
                        pricing_attr_value_from	,
                        pricing_attr_value_to	,
                        comparison_operator_code	,
                        excluder_flag	,
                        modifiers_index	,
                        volume_type	,
                        -- header_record_number	,
                        -- line_record_number	,
                        -- interface_action_code	,
                        -- process_flag	,
                        -- process_status_flag	,
                        batch_id	,
                        error_desc	,
                        src_file_name	,
                        record_number,
                        incompatibility_grp_code,
                        estim_accrual_rate,
                        include_on_returns_flag,
                        print_on_invoice_flag,
                        G_STAGE,                --- DO NOT CHANGE FROM THIS LINE TILL MENTIONED LINE
                        error_code,                     --- DO NOT CHANGE THIS LINE
                        request_id,
                        x_created_by,
                        x_creation_date,
                        x_last_updated_by,
                        x_last_update_date,
                        x_last_update_login    -- DO NOT CHANGE TO THIS LINE
                  FROM xx_qp_mdpr_list_lines_stg
                 WHERE BATCH_ID = G_BATCH_ID
                   AND process_code = xx_emf_cn_pkg.CN_PREVAL
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                   AND DESELECT_FLAG IS NULL;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Insert into xx_qp_mdpr_list_lines_pre before commit');
                COMMIT;
                EXCEPTION
                WHEN OTHERS THEN
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in insertion xx_qp_mdpr_list_lines_pre '||SQLERRM);
			xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
			x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
                        RETURN x_error_code;
                END;

                BEGIN
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Insert into xx_qp_mdpr_list_qlf_pre');
                INSERT INTO xx_qp_mdpr_list_qlf_pre
                (
                        --modifier_name	,
                        --list_type_code	,
                        comparison_operator_code	,
                        orig_sys_header_ref ,
                        orig_sys_line_ref ,
                        orig_sys_qualifier_ref ,
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
                        --modifier_name	,
                        --list_type_code	,
                        comparison_operator_code	,

orig_sys_header_ref ,
                        orig_sys_line_ref ,
                        orig_sys_qualifier_ref ,
                        --comparison_operator_desc	,
                        qualifier_context	,
                        -- qualifier_context_desc	,
                        qualifier_attribute	,
                        --qualifier_attribute_code	,
                        qualifier_grouping_no	,
                        qualifier_attr_value	,
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
                        x_last_updated_by,
                        x_last_update_date,
                        x_last_update_login    -- DO NOT CHANGE TO THIS LINE
                  FROM xx_qp_mdpr_list_qlf_stg
                 WHERE BATCH_ID = G_BATCH_ID
                   AND process_code = xx_emf_cn_pkg.CN_PREVAL
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                   AND DESELECT_FLAG IS NULL;

                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Insert into xx_qp_mdpr_list_qlf_pre before commit');

                   COMMIT;
                   EXCEPTION
		   WHEN OTHERS THEN
			   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in insertion xx_qp_mdpr_list_qlf_pre '||SQLERRM);
			   xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
			   x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
			   RETURN x_error_code;
                   END;

                   /*select request_id into l_request_id
                  FROM xx_qp_mdpr_list_qlf_stg
                 WHERE BATCH_ID = G_BATCH_ID
                   AND process_code = xx_emf_cn_pkg.CN_PREVAL
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Insert into xx_qp_mdpr_list_qlf_pre before commit');
                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'l_request_id=' || l_request_id); */

--                INSERT INTO xx_qp_mdpr_list_lines_pre
--                SELECT *
--                  FROM xx_qp_mdpr_list_lines_stg
--                 WHERE BATCH_ID = G_BATCH_ID
--                   AND process_code = xx_emf_cn_pkg.CN_PREVAL
--                   AND request_id = xx_emf_pkg.G_REQUEST_ID
--                   AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);
--
--                INSERT INTO xx_qp_mdpr_list_qlf_pre
--                SELECT *
--                  FROM xx_qp_mdpr_list_qlf_stg
--                 WHERE BATCH_ID = G_BATCH_ID
--                   AND process_code = xx_emf_cn_pkg.CN_PREVAL
--                   AND request_id = xx_emf_pkg.G_REQUEST_ID
--                   AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

                --COMMIT;

                RETURN x_error_code;
        EXCEPTION
                WHEN OTHERS THEN
                        xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);

                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in move_rec_pre_standard_table '||SQLERRM);
                        x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
                        RETURN x_error_code;
        END move_rec_pre_standard_table;

        PROCEDURE mark_duplicate_combination
        IS
          /*x_last_update_date     DATE   := SYSDATE;
            x_last_update_by       NUMBER := fnd_global.user_id;
            x_last_updated_login   NUMBER := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
           */

            CURSOR c_xx_error_mdf_hdr_rec
            IS
            SELECT record_number
                  ,orig_sys_header_ref
                  ,list_type_code
             FROM xx_qp_mdpr_list_hdr_pre
             WHERE error_code   = xx_emf_cn_pkg.CN_REC_ERR
              -- AND process_code = xx_emf_cn_pkg.CN_STG_DATAVAL
               AND process_code = xx_emf_cn_pkg.CN_VALID
               AND batch_id     = g_batch_id
               AND request_id   = xx_emf_pkg.G_REQUEST_ID
             ;

            CURSOR c_xx_error_mdf_lines_rec
            IS
            SELECT record_number
                  ,orig_sys_header_ref
                  ,orig_sys_line_ref
                  ,orig_sys_pricing_attr_ref
                  ,list_line_type_code
                  ,pricing_phase_name
              FROM xx_qp_mdpr_list_lines_pre
             WHERE error_code   = xx_emf_cn_pkg.CN_REC_ERR
              -- AND process_code = xx_emf_cn_pkg.CN_STG_DATAVAL
               --AND orig_sys_hdr_ref = <orig_sys_hdr_ref> DROY
               AND process_code = xx_emf_cn_pkg.CN_VALID
               AND batch_id     = g_batch_id
               AND request_id   = xx_emf_pkg.G_REQUEST_ID
             ;

            CURSOR c_xx_error_qlf_rec
            IS
            SELECT record_number
                  --,modifier_name --DROY
                   ,NULL --DROY
                  ,orig_sys_header_ref
                  ,orig_sys_line_ref
                  ,orig_sys_qualifier_ref
                  ,qualifier_context
                  --,qualifier_attribute
              FROM xx_qp_mdpr_list_qlf_pre
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

           UPDATE xx_qp_mdpr_list_hdr_pre
              SET error_code   = xx_emf_cn_pkg.CN_REC_ERR,
                  --process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
                  process_code = xx_emf_cn_pkg.CN_VALID,
                  error_desc   = 'Duplicate Modifier Hdr List'
            WHERE
                rowid IN (SELECT "rowid" FROM
                          (SELECT "rowid", rank_n FROM
                           (SELECT ROW_NUMBER()
                                   OVER (PARTITION BY
                                           name,list_type_code
                                           ORDER BY ROWID
                                        ) rank_n
                                   , rowid as "rowid"
                              FROM xx_qp_mdpr_list_hdr_pre
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

            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, '~Duplicate:Number of Duplicate Modifier List Header ->' || SQL%ROWCOUNT);


           UPDATE xx_qp_mdpr_list_lines_pre
              SET error_code   = xx_emf_cn_pkg.CN_REC_ERR,
                  --process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
                  process_code = xx_emf_cn_pkg.CN_VALID,
                  error_desc   = 'Duplicate Modifier List'
            WHERE
                rowid IN (SELECT "rowid" FROM
                          (SELECT "rowid", rank_n FROM
                           (SELECT ROW_NUMBER()
                                   OVER (PARTITION BY
                                           orig_sys_header_ref
                                          ,list_line_type_code, pricing_phase_name
                                          ,product_attribute, product_attr_value
                                          ,start_date_active,end_date_active
                                           ORDER BY ROWID
                                        ) rank_n
                                   , rowid as "rowid"
                              FROM xx_qp_mdpr_list_lines_pre
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

            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, '~Duplicate:Number of Duplicate Modifier List Line ->' || SQL%ROWCOUNT);

           UPDATE xx_qp_mdpr_list_qlf_pre
              SET error_code   = xx_emf_cn_pkg.CN_REC_ERR,
                  --process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
                  process_code = xx_emf_cn_pkg.CN_VALID,
                  error_desc   = 'Duplicate Qualifier on Modifier'
            WHERE
                rowid IN (SELECT "rowid" FROM
                          (SELECT "rowid", rank_n FROM
                           (SELECT ROW_NUMBER()
                                   OVER (PARTITION BY
                                           orig_sys_header_ref,qualifier_context
                                          ,qualifier_attribute
                                           ORDER BY ROWID
                                        ) rank_n
                                   , rowid as "rowid"
                              FROM xx_qp_mdpr_list_qlf_pre
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

            FOR cur_rec IN c_xx_error_mdf_hdr_rec LOOP
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                                ,p_error_text  => 'Duplicate Modifier List Header'
                                ,p_record_identifier_1 => cur_rec.record_number
                     ,p_record_identifier_2 => cur_rec.orig_sys_header_ref
                    -- ,p_record_identifier_3 => cur_rec.orig_sys_line_ref
                    -- ,p_record_identifier_4 => cur_rec.orig_sys_pricing_attr_ref
                    -- ,p_record_identifier_5 => cur_rec.orig_sys_qualifier_ref
                               );
            END LOOP;

            FOR cur_rec IN c_xx_error_mdf_lines_rec LOOP
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                                ,p_error_text  => 'Duplicate Modifier List Lines'
                                ,p_record_identifier_1 => cur_rec.record_number
                     ,p_record_identifier_2 => cur_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => cur_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => cur_rec.orig_sys_pricing_attr_ref
                    -- ,p_record_identifier_5 => cur_rec.orig_sys_qualifier_ref
                               );
            END LOOP;

            FOR cur_rec IN c_xx_error_qlf_rec LOOP
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                                ,p_error_text  => 'Duplicate Qualifiers on Modifier'
                                ,p_record_identifier_1 => cur_rec.record_number
                     ,p_record_identifier_2 => cur_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => cur_rec.orig_sys_line_ref
                    -- ,p_record_identifier_4 => cur_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5 => cur_rec.orig_sys_qualifier_ref
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


        FUNCTION process_data
         RETURN NUMBER
      IS
         CURSOR c_header
         IS
            SELECT DISTINCT custom_batch_no
                       FROM xx_qp_mdpr_list_hdr_pre
                      WHERE batch_id = g_batch_id
                        AND request_id = xx_emf_pkg.g_request_id
                        --AND list_header_id IS NOT NULL
                        AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success)--, xx_emf_cn_pkg.cn_rec_warn )--leave out warning to load qlf only
                        AND process_code = xx_emf_cn_pkg.cn_postval
                        ORDER BY custom_batch_no;

         CURSOR c_mod_hdr_qlf_exists IS
         SELECT
			       x.*
            FROM xx_qp_mdpr_list_hdr_pre x
            WHERE batch_id          = g_batch_id
              AND request_id        = xx_emf_pkg.G_REQUEST_ID
	      AND process_code      = xx_emf_cn_pkg.CN_POSTVAL
	      AND error_code        IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
              AND EXISTS (SELECT 1
                            FROM xx_qp_mdpr_list_qlf_pre q
                           WHERE q.orig_sys_header_ref = x.orig_sys_header_ref
                            AND  q.batch_id = x.batch_id
                            AND process_code      = xx_emf_cn_pkg.CN_POSTVAL
			    AND error_code        IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                          )
            ;

         CURSOR c_pre_std_qlf_hdr  (p_orig_sys_header_ref   IN xx_qp_mdpr_list_lines_stg.orig_sys_header_ref%TYPE
                                      ) IS
            SELECT
                --
                -- Add Columns
                --
			       x.*
            FROM xx_qp_mdpr_list_qlf_pre x
            WHERE batch_id          = P_BATCH_ID
			 -- AND request_id        = xx_emf_pkg.G_REQUEST_ID
			  AND process_code      = xx_emf_cn_pkg.CN_POSTVAL
			  AND error_code        IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
              AND orig_sys_header_ref = p_orig_sys_header_ref
              --AND (orig_sys_line_ref = p_orig_sys_line_ref OR orig_sys_line_ref IS NULL)
            ;

         CURSOR c_list_header_id(p_name IN VARCHAR2
                                ) IS
         SELECT list_header_id
                      FROM qp_list_headers
                       WHERE name= p_name
                        AND list_type_code <> 'PRL'
                        ORDER by creation_date desc;

            CURSOR c_mod_price_list (p_list_id IN VARCHAR2) IS
          SELECT list_header_id
          FROM qp_list_headers qlh
          WHERE list_type_code = 'PRL'
            AND  qlh.orig_system_header_ref = p_list_id
            ORDER BY creation_date desc;


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
         x_total_header        NUMBER;
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
         -------------qual variable declaration
         gpr_msg_count                     NUMBER       := 0;
	 gpr_msg_data                      VARCHAR2(32767 );
         gpr_msg_data2                      VARCHAR2(32767 );
         l_return_status                 VARCHAR2(1);

         x_stg_qlf_count                 NUMBER := 0;
         x_tab_qlf_count                 NUMBER := 0;

            l_MODIFIER_LIST_rec               QP_Modifiers_PUB.Modifier_List_Rec_Type;
            l_MODIFIERS_tbl                   QP_Modifiers_PUB.Modifiers_Tbl_Type;
            l_PRICING_ATTR_tbl                QP_Modifiers_PUB.Pricing_Attr_Tbl_Type;
            l_x_MODIFIER_LIST_rec             QP_Modifiers_PUB.Modifier_List_Rec_Type;
            l_x_MODIFIER_LIST_val_rec         QP_Modifiers_PUB.Modifier_List_Val_Rec_Type;
            l_x_MODIFIERS_tbl                 QP_Modifiers_PUB.Modifiers_Tbl_Type;
            l_x_MODIFIERS_val_tbl             QP_Modifiers_PUB.Modifiers_Val_Tbl_Type;
            l_x_QUALIFIERS_tbl                QP_Qualifier_Rules_PUB.Qualifiers_Tbl_Type;
            l_x_QUALIFIERS_val_tbl            QP_Qualifier_Rules_PUB.Qualifiers_Val_Tbl_Type;
            l_x_PRICING_ATTR_tbl              QP_Modifiers_PUB.Pricing_Attr_Tbl_Type;
            l_x_PRICING_ATTR_val_tbl          QP_Modifiers_PUB.Pricing_Attr_Val_Tbl_Type;
            l_QUALIFIERS_tbl                  QP_Qualifier_Rules_PUB.Qualifiers_Tbl_Type;
            l_list_line_id                    qp_list_lines.list_line_id%TYPE;

            x_hdr_err_flag                  VARCHAR2(1);
            x_line_err_flag                 VARCHAR2(1);
            x_attr_err_flag                  VARCHAR2(1);
            x_qlf_err_flag                  VARCHAR2(1);
            l_list_line_exists_flag         VARCHAR2(1);
            x_qual_count                    NUMBER;

            x_sys_time                      VARCHAR2(100);
            i                               NUMBER;
            e_no_header_found EXCEPTION;
         --------------------------------------
      BEGIN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'INSIDE PROCESS_DATA' );

         x_no_of_conc_batch := TO_NUMBER(xx_emf_pkg.get_paramater_value ('XXQPMODLISTCNV', 'PARALLEL_PROCESS'));
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Parallel Process :'||x_no_of_conc_batch );


         FOR hdr_rec IN c_header
         LOOP
             x_call_status := FALSE;
             IF hdr_rec.custom_batch_no <= x_no_of_conc_batch THEN
             --IF hdr_rec.custom_batch_no = 10 THEN
                x_index := x_index + 1;
                x_req_id := fnd_request.submit_request
                                         (application      => 'XXINTG',
                                          program          => 'XXQPMODLISTCNVSUBMIT',
                                          argument1        => g_batch_id, --Batch Id
                                          argument2        => hdr_rec.custom_batch_no
                                         );



                UPDATE xx_qp_mdpr_list_hdr_pre
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
                                       program          => 'XXQPMODLISTCNVSUBMIT',
                                       argument1        => g_batch_id, --Batch Id
                                       argument2        => hdr_rec.custom_batch_no
                                      );
                         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'INSIDE HEADER PROCESS_DATA' );

                         UPDATE xx_qp_mdpr_list_hdr_pre
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


         --Wait for all the child programs to finish
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
         --create_records_for_api_error ;

         BEGIN
            ------------Qualifier Start----------------------------------------------
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Checking Qualifier records to be created');
                FOR rec_mod_hdr_qlf_exists IN c_mod_hdr_qlf_exists LOOP
                   BEGIN
                      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'In qualifier exists loop' );
                   BEGIN
                      OPEN  c_list_header_id(rec_mod_hdr_qlf_exists.name
                                            );
                      FETCH c_list_header_id
                      INTO l_MODIFIER_LIST_rec.list_header_id ;
                      CLOSE c_list_header_id;

                      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Fetched modifier list header id = '||l_MODIFIER_LIST_rec.list_header_id );
                      IF l_MODIFIER_LIST_rec.list_header_id  IS NULL THEN
                         RAISE e_no_header_found;
                      END IF;
                   EXCEPTION
                      WHEN OTHERS THEN
                         xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                                            ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                                            ,p_error_text               => gpr_msg_data
                                            ,p_record_identifier_1      => rec_mod_hdr_qlf_exists.orig_sys_header_ref
                                           -- ,p_record_identifier_2      => rec_pre_std_qlf_hdr.name
                                           );
                                      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg =>'||gpr_msg_data);

                                      mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                                 , rec_mod_hdr_qlf_exists.orig_sys_header_ref
                                                                 , NULL
                                                                 , NULL
                                                                , 'When othes in main'
                                                               );
                   END ;
                   --l_MODIFIER_LIST_rec.list_header_id              := rec_mod_hdr_qlf_exists.list_header_id;
                   l_MODIFIER_LIST_rec.operation                  := QP_GLOBALS.G_OPR_UPDATE;
                   DECLARE
                      l_MODIFIERS_tbl                   QP_Modifiers_PUB.Modifiers_Tbl_Type;
                      l_PRICING_ATTR_tbl                QP_Modifiers_PUB.Pricing_Attr_Tbl_Type;
                      l_x_MODIFIER_LIST_rec             QP_Modifiers_PUB.Modifier_List_Rec_Type;
                      l_x_MODIFIER_LIST_val_rec         QP_Modifiers_PUB.Modifier_List_Val_Rec_Type;
                      l_x_MODIFIERS_tbl                 QP_Modifiers_PUB.Modifiers_Tbl_Type;
                      l_x_MODIFIERS_val_tbl             QP_Modifiers_PUB.Modifiers_Val_Tbl_Type;
                      l_x_QUALIFIERS_tbl                QP_Qualifier_Rules_PUB.Qualifiers_Tbl_Type;
                      l_x_QUALIFIERS_val_tbl            QP_Qualifier_Rules_PUB.Qualifiers_Val_Tbl_Type;
                      l_x_PRICING_ATTR_tbl              QP_Modifiers_PUB.Pricing_Attr_Tbl_Type;
                      l_x_PRICING_ATTR_val_tbl          QP_Modifiers_PUB.Pricing_Attr_Val_Tbl_Type;
                      l_QUALIFIERS_tbl                  QP_Qualifier_Rules_PUB.Qualifiers_Tbl_Type;


                   BEGIN
                      l_return_status := FND_API.G_RET_STS_SUCCESS;
                      gpr_msg_data  := NULL;
                      x_qlf_err_flag  := 'N';
                      l_list_line_id    :=                NULL;
                      i := 0;
                      oe_msg_pub.initialize;

                      FOR rec_pre_std_qlf_hdr IN c_pre_std_qlf_hdr(rec_mod_hdr_qlf_exists.orig_sys_header_ref) LOOP

               --          l_list_line_exists_flag := 'Y';
                         DECLARE
                         l_MODIFIERS_tbl                   QP_Modifiers_PUB.Modifiers_Tbl_Type;
                         l_PRICING_ATTR_tbl                QP_Modifiers_PUB.Pricing_Attr_Tbl_Type;
                         l_x_MODIFIER_LIST_rec             QP_Modifiers_PUB.Modifier_List_Rec_Type;
                         l_x_MODIFIER_LIST_val_rec         QP_Modifiers_PUB.Modifier_List_Val_Rec_Type;
                         l_x_MODIFIERS_tbl                 QP_Modifiers_PUB.Modifiers_Tbl_Type;
                         l_x_MODIFIERS_val_tbl             QP_Modifiers_PUB.Modifiers_Val_Tbl_Type;
                         l_x_QUALIFIERS_tbl                QP_Qualifier_Rules_PUB.Qualifiers_Tbl_Type;
                         l_x_QUALIFIERS_val_tbl            QP_Qualifier_Rules_PUB.Qualifiers_Val_Tbl_Type;
                         l_x_PRICING_ATTR_tbl              QP_Modifiers_PUB.Pricing_Attr_Tbl_Type;
                         l_x_PRICING_ATTR_val_tbl          QP_Modifiers_PUB.Pricing_Attr_Val_Tbl_Type;
                         l_QUALIFIERS_tbl                  QP_Qualifier_Rules_PUB.Qualifiers_Tbl_Type;
                         BEGIN
                            i := 1;
                            gpr_msg_data  := NULL;
                            x_qlf_err_flag  := 'N';
                            l_list_line_id    :=  NULL;
                         END;

                         IF (rec_pre_std_qlf_hdr.orig_sys_line_ref IS NOT NULL
                             AND rec_pre_std_qlf_hdr.orig_sys_line_ref <> -1) THEN
                            BEGIN
                               SELECT list_line_id
                               INTO   l_list_line_id
                               FROM  qp_list_lines
                               WHERE list_header_id = l_MODIFIER_LIST_rec.list_header_id
                                 AND attribute10   = rec_pre_std_qlf_hdr.orig_sys_line_ref;

                               l_QUALIFIERS_tbl(i).list_header_id  := l_MODIFIER_LIST_rec.list_header_id;
                               l_QUALIFIERS_tbl(i).list_line_id    := l_list_line_id;
                            EXCEPTION
                               WHEN NO_DATA_FOUND THEN
 --                                 l_list_line_exists_flag := 'N';
                                    null;

                               WHEN OTHERS THEN
--                                  l_list_line_exists_flag := 'N';
                                    null;
                            END;
                         END IF;

                         IF rec_pre_std_qlf_hdr.QUALIFIER_CONTEXT = 'MODLIST' THEN
                               OPEN c_mod_price_list (rec_pre_std_qlf_hdr.qualifier_attr_value_disp);
                               FETCH c_mod_price_list
                               INTO l_QUALIFIERS_tbl(i).qualifier_attr_value;
                               CLOSE c_mod_price_list;
                              IF l_QUALIFIERS_tbl(i).qualifier_attr_value IS NULL THEN
                               mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                        , rec_pre_std_qlf_hdr.orig_sys_header_ref
                                                        , NULL
                                                        , NULL
                                                       , SUBSTR ( 'Error in Pricelist retrieval', 1, 1000 )
                                                      );
                              END IF;
                         ELSE
                              l_QUALIFIERS_tbl(i).qualifier_attr_value := rec_pre_std_qlf_hdr.qualifier_attr_value;
                         END IF;


                         --l_QUALIFIERS_tbl(i).excluder_flag := NVL(rec_pre_std_qlf_hdr.excluder_flag,'N'); --DROY
                         l_QUALIFIERS_tbl(i).comparison_operator_code := rec_pre_std_qlf_hdr.comparison_operator_code;
                         --l_QUALIFIERS_tbl(i).attribute10 := rec_pre_std_qlf_hdr.orig_sys_qualifier_ref;
                         l_QUALIFIERS_tbl(i).attribute10 := rec_pre_std_qlf_hdr.record_number;
                         l_QUALIFIERS_tbl(i).attribute15 := rec_pre_std_qlf_hdr.batch_id;
                         l_QUALIFIERS_tbl(i).qualifier_context := rec_pre_std_qlf_hdr.qualifier_context;
                         --l_QUALIFIERS_tbl(i).qualifier_attribute := rec_pre_std_qlf_hdr.qualifier_attribute_code; --DROY
                         l_QUALIFIERS_tbl(i).qualifier_attribute := rec_pre_std_qlf_hdr.qualifier_attribute; --DROY
                         --l_QUALIFIERS_tbl(i).qualifier_attr_value := rec_pre_std_qlf_hdr.qualifier_attr_value; --droy
                         l_QUALIFIERS_tbl(i).qualifier_attr_value_to := rec_pre_std_qlf_hdr.qualifier_attr_value_to; --droy
                         l_QUALIFIERS_tbl(i).qualifier_grouping_no := rec_pre_std_qlf_hdr.qualifier_grouping_no;
                         l_QUALIFIERS_tbl(i).qualifier_precedence := rec_pre_std_qlf_hdr.qualifier_precedence;
                         l_QUALIFIERS_tbl(i).start_date_active := rec_pre_std_qlf_hdr.start_date_active;
                         l_QUALIFIERS_tbl(i).end_date_active := rec_pre_std_qlf_hdr.end_date_active;
                         l_QUALIFIERS_tbl(i).operation := QP_GLOBALS.G_OPR_CREATE;

                         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'l_QUALIFIERS_tbl(i).qualifier_attribute=' || l_QUALIFIERS_tbl(i).qualifier_attribute);
                         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'l_QUALIFIERS_tbl(i).qualifier_context=' || l_QUALIFIERS_tbl(i).qualifier_context);
                         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'l_QUALIFIERS_tbl(i).qualifier_attr_value=' || l_QUALIFIERS_tbl(i).qualifier_attr_value);


                         BEGIN

                            SELECT TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS') INTO x_sys_time FROM DUAL;
                                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                          ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                          ,p_error_text  => 'System Time'
                                          ,p_record_identifier_1 => rec_pre_std_qlf_hdr.orig_sys_header_ref
                                          ,p_record_identifier_2 => 'Before Qual create API call'
                                          ,p_record_identifier_3 => x_sys_time
                                          );
                         EXCEPTION
                                WHEN OTHERS THEN
                                  NULL;
                         END;
                         BEGIN
                            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling API to create qualifiers');
                            QP_Modifiers_PUB.Process_Modifiers
                                ( p_api_version_number => xx_qp_mod_list_cnv_pkg.CN_API_VER_NO
                                   , p_init_msg_list           => FND_API.G_FALSE
                                   , p_return_values           => FND_API.G_FALSE
                                   , p_commit                  => FND_API.G_FALSE
                                   , x_return_status           => l_return_status
                                   , x_msg_count               => gpr_msg_count
                                   , x_msg_data                => gpr_msg_data
                                   , p_MODIFIER_LIST_rec       => l_MODIFIER_LIST_rec
                                   , p_MODIFIERS_tbl           => l_MODIFIERS_tbl
                                   , p_QUALIFIERS_tbl          => l_QUALIFIERS_tbl
                                   , p_PRICING_ATTR_tbl        => l_PRICING_ATTR_tbl
                                   , x_MODIFIER_LIST_rec       => l_x_MODIFIER_LIST_rec
                                   , x_MODIFIER_LIST_val_rec   => l_x_MODIFIER_LIST_val_rec
                                   , x_MODIFIERS_tbl           => l_x_MODIFIERS_tbl
                                   , x_MODIFIERS_val_tbl       => l_x_MODIFIERS_val_tbl
                                   , x_QUALIFIERS_tbl          => l_x_QUALIFIERS_tbl
                                   , x_QUALIFIERS_val_tbl      => l_x_QUALIFIERS_val_tbl
                                   , x_PRICING_ATTR_tbl        => l_x_PRICING_ATTR_tbl
                                   , x_PRICING_ATTR_val_tbl    => l_x_PRICING_ATTR_val_tbl
                               );
                               ---**********---
                            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Qualifer Creation API status=> '||l_return_status);
                            BEGIN

                              SELECT TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS') INTO x_sys_time FROM DUAL;
                                     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                            ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                            ,p_error_text  => 'System Time'
                                            ,p_record_identifier_1 => rec_pre_std_qlf_hdr.orig_sys_header_ref
                                            ,p_record_identifier_2 => 'After Qual create API call'
                                            ,p_record_identifier_3 => x_sys_time
                                            );
                            EXCEPTION
                                  WHEN OTHERS THEN
                                     NULL;
                            END;



                            BEGIN

                              SELECT TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS') INTO x_sys_time FROM DUAL;
                                    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                         ,p_error_text  => 'System Time'
                                         ,p_record_identifier_1 => rec_pre_std_qlf_hdr.orig_sys_header_ref
                                         ,p_record_identifier_2 => 'After msg Print'
                                         ,p_record_identifier_3 => x_sys_time
                                         );

                              FOR k IN 1 .. gpr_msg_count
                              LOOP
                                 gpr_msg_data := oe_msg_pub.get ( p_msg_index => k, p_encoded => 'F' );
                                 gpr_msg_data2 := gpr_msg_data2 || LTRIM ( RTRIM ( gpr_msg_data ));
                                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Msg... =>' || gpr_msg_data );
                                 fnd_file.put_line(fnd_file.log,'Msg Hdr... =>' || gpr_msg_data );
                              END LOOP;

                            EXCEPTION
                               WHEN OTHERS THEN
                                  NULL;
                            END;
                            BEGIN
                              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'List Header id=> '||l_MODIFIER_LIST_rec.list_header_id);
                               SELECT COUNT(*) INTO x_qual_count FROM QP_QUALIFIERS WHERE LIST_HEADER_ID = l_MODIFIER_LIST_rec.list_header_id;
                               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Qualifier Count=> '||x_qual_count);
                            EXCEPTION
                               WHEN OTHERS THEN
                               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'When others in created qual cnt=> '||SQLERRM);
                            END;
                            BEGIN

                              SELECT TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS') INTO x_sys_time FROM DUAL;
                                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                            ,p_error_text  => 'System Time'
                                            ,p_record_identifier_1 => rec_pre_std_qlf_hdr.orig_sys_header_ref
                                            ,p_record_identifier_2 => 'After qual count print'
                                            ,p_record_identifier_3 => x_sys_time
                                            );
                            EXCEPTION
                                  WHEN OTHERS THEN
                                     NULL;
                            END;

                            IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                               FOR k IN 1 .. gpr_msg_count
                               LOOP
                                    gpr_msg_data := oe_msg_pub.get ( p_msg_index => k, p_encoded => 'F' );
                                    gpr_msg_data2 := gpr_msg_data2 || LTRIM ( RTRIM ( gpr_msg_data ));
                                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error Msg... =>' || gpr_msg_data );
                                    fnd_file.put_line(fnd_file.log,'Error Msg Hdr... =>' || gpr_msg_data );
                                 END LOOP;
                                  x_qlf_err_flag  := 'Y';
                                  mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                                    -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                                    , rec_pre_std_qlf_hdr.orig_sys_header_ref
                                                                    , NULL
                                                                    , NULL
                                                                    , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                                    );
                                  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Qualifer for Modifier Creation => Failure ');
                                  RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                               ELSE
                                     IF l_x_QUALIFIERS_tbl.count > 0 THEN
                                        FOR k in 1 .. l_x_QUALIFIERS_tbl.count LOOP

                                           IF l_x_QUALIFIERS_tbl(k).return_status IN ( 'E', 'U' ) THEN
                                              xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'One or more Modlist Qualifier Creation Failed' );
                                              x_qlf_err_flag := 'Y';
                                              mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                                    -- , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                                    , l_x_MODIFIER_LIST_rec.orig_system_header_ref
                                                                    , NULL
                                                                    , l_x_QUALIFIERS_tbl(k).attribute10
                                                                    , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                                    );
                                           END IF;

                                        END LOOP;
                                        IF NVL(x_qlf_err_flag,'X') <> 'Y' THEN
                                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Successful ModList Qualifier Creation' );
                                        END IF;
                                     END IF;

                               END IF;
                            EXCEPTION
                              WHEN FND_API.G_EXC_ERROR THEN
                                  x_qlf_err_flag := 'Y';
                                  l_return_status := FND_API.G_RET_STS_ERROR;
                                  --ROLLBACK;
                                  xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                                        ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                                        ,p_error_text               => gpr_msg_data
                                        ,p_record_identifier_1      => rec_pre_std_qlf_hdr.orig_sys_header_ref
                                        );
                                  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg => G_EXEC_ERROR');

                                  /*xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'mark_records_for_api_error => xx_emf_cn_pkg.CN_PROCESS_DATA'||
                                                                            xx_emf_cn_pkg.CN_PROCESS_DATA
                                                                            ||'rec_pre_std_qlf_hdr.name '
                                                                            ||rec_pre_std_qlf_hdr.name
                                                                            ||'rec_pre_std_qlf_hdr.list_type_code'
                                                                            ||rec_pre_std_qlf_hdr.list_type_code);*/

                                   mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                                , rec_pre_std_qlf_hdr.orig_sys_header_ref
                                                                , NULL
                                                                 , NULL
                                                               , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                               );
                              WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
                                 x_qlf_err_flag := 'Y';
                                 --ROLLBACK;
                                 FOR k IN 1 .. gpr_msg_count LOOP
                                      gpr_msg_data := oe_msg_pub.get
                                                          ( p_msg_index => k
                                                           ,p_encoded => 'F');
                                      xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                                            ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                                            ,p_error_text               => gpr_msg_data
                                            ,p_record_identifier_1      => rec_pre_std_qlf_hdr.orig_sys_header_ref
                                           -- ,p_record_identifier_2      => rec_pre_std_qlf_hdr.name
                                           );
                                      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg In G_EXC_UNEXPECTED_ERROR =>'||gpr_msg_data);

                                      /*mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA
                                                  ,cur_dis_rec.name
                                                  ,cur_dis_rec.list_type_code);   */ --commented to avoid exception
                                 END LOOP;
                                 mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                            , rec_pre_std_qlf_hdr.orig_sys_header_ref
                                                            , NULL
                                                            , NULL
                                                            , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                             );

                              WHEN OTHERS THEN
                                 x_qlf_err_flag := 'Y';
                                 --ROLLBACK;
                                 FOR k IN 1 .. gpr_msg_count LOOP
                                      gpr_msg_data := oe_msg_pub.get
                                                          ( p_msg_index => k
                                                           ,p_encoded => 'F');
                                      xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                                            ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                                            ,p_error_text               => gpr_msg_data
                                            ,p_record_identifier_1      => rec_pre_std_qlf_hdr.orig_sys_header_ref
                                           -- ,p_record_identifier_2      => rec_pre_std_qlf_hdr.name
                                           );
                                      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg =>'||gpr_msg_data);

                                      mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                                 , rec_pre_std_qlf_hdr.orig_sys_header_ref
                                                                 , NULL
                                                                 , NULL
                                                                , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                               );

                                   END LOOP;
                            END;
                   ------------Qualifier End------------------------------------------------
                      END LOOP;---Qualifier loop end
                      IF NVL(x_qlf_err_flag,'X') <> 'Y' THEN
                           ---------------------
                           BEGIN
                                 SELECT count(1)
                                  INTO  x_stg_qlf_count
                                  FROM  xx_qp_mdpr_list_qlf_pre
                                 WHERE  orig_sys_header_ref = rec_mod_hdr_qlf_exists.orig_sys_header_ref
                                   AND  batch_id =  rec_mod_hdr_qlf_exists.batch_id;

                                 SELECT count(1)
                                  INTO  x_tab_qlf_count
                                  FROM  qp_qualifiers
                                 WHERE  list_header_id = TO_CHAR(l_MODIFIER_LIST_rec.list_header_id);


                                 IF x_stg_qlf_count <> x_tab_qlf_count THEN
                                    x_qlf_err_flag := 'Y';
                                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Qualifier count Calculation mismatch hence rolling back' );
                                    ROLLBACK;
                                 ELSE
                                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Successful ModList Qualifier Set Creation' );
                                    COMMIT;
                                 END IF;

                              EXCEPTION
                                 WHEN OTHERS THEN
                                    x_qlf_err_flag := 'Y';
                                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'When others in Qualifier count Calculation' );
                              END;
                           ---------------------
                           COMMIT;
                      ELSE
                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Rolling Back since Qualifier creation failed' );
                           ROLLBACK;
                      END IF;

                   EXCEPTION
                      WHEN OTHERS THEN
                         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'When Others 200');
                   END; --End for Qualifiers loop
                EXCEPTION
                   WHEN e_no_header_found THEN
                       xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                                            ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                                            ,p_error_text               => gpr_msg_data
                                            ,p_record_identifier_1      => rec_mod_hdr_qlf_exists.orig_sys_header_ref
                                           -- ,p_record_identifier_2      => rec_pre_std_qlf_hdr.name
                                           );
                                      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg =>'||gpr_msg_data);

                                      mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                                 , rec_mod_hdr_qlf_exists.orig_sys_header_ref
                                                                 , NULL
                                                                 , NULL
                                                                , 'No header found for qualifier creation'
                                                               );
                      WHEN OTHERS THEN
                                   xx_emf_pkg.error (p_severity      => xx_emf_cn_pkg.CN_MEDIUM
                                            ,p_category                 => xx_emf_cn_pkg.CN_STG_APICALL
                                            ,p_error_text               => gpr_msg_data
                                            ,p_record_identifier_1      => rec_mod_hdr_qlf_exists.orig_sys_header_ref
                                           -- ,p_record_identifier_2      => rec_pre_std_qlf_hdr.name
                                           );
                                      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg =>'||gpr_msg_data);

                                      mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                                 , rec_mod_hdr_qlf_exists.orig_sys_header_ref
                                                                 , NULL
                                                                 , NULL
                                                                , 'When othes in main'
                                                               );
                END;--End of each hdr begin
                END LOOP; --End for modifier header loop



         EXCEPTION
            WHEN OTHERS THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'When Others 300');
         END;------------------------------------------------------End for Modifier hdr begin

         create_records_for_api_error ;

         RETURN x_error_code;
      END process_data;


        /***** Not Required Separately for Qualifiers **********/
        PROCEDURE update_record_count
        IS

                CURSOR c_get_total_cnt IS
                SELECT COUNT (1) total_count
                  FROM xx_qp_mdpr_list_hdr_pre
                 WHERE batch_id = G_BATCH_ID
                   AND request_id = xx_emf_pkg.G_REQUEST_ID;

                x_total_cnt NUMBER;

                CURSOR c_get_error_cnt IS
                SELECT SUM(error_count)
                  FROM (
                SELECT COUNT (1) error_count
                  FROM xx_qp_mdpr_list_hdr_pre
                 WHERE batch_id = G_BATCH_ID
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   AND error_code = xx_emf_cn_pkg.CN_REC_ERR
                       );

                x_error_cnt NUMBER;

                CURSOR c_get_warning_cnt IS
                SELECT COUNT (1) warn_count
                  FROM xx_qp_mdpr_list_hdr_pre
                 WHERE batch_id = G_BATCH_ID
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

                x_warn_cnt NUMBER;

                CURSOR c_get_success_cnt IS
                SELECT COUNT (1) warn_count
                  FROM xx_qp_mdpr_list_hdr_pre
                 WHERE batch_id = G_BATCH_ID
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   --AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

                x_success_cnt NUMBER;

        BEGIN
                OPEN c_get_total_cnt;
                FETCH c_get_total_cnt INTO x_total_cnt;
                CLOSE c_get_total_cnt;

                OPEN c_get_error_cnt;
                FETCH c_get_error_cnt INTO x_error_cnt;
                CLOSE c_get_error_cnt;

                OPEN c_get_warning_cnt;
                FETCH c_get_warning_cnt INTO x_warn_cnt;
                CLOSE c_get_warning_cnt;

                OPEN c_get_success_cnt;
                FETCH c_get_success_cnt INTO x_success_cnt;
                CLOSE c_get_success_cnt;

                xx_emf_pkg.update_recs_cnt
                (
                    p_total_recs_cnt => x_total_cnt,
                    p_success_recs_cnt => x_success_cnt,
                    p_warning_recs_cnt => x_warn_cnt,
                    p_error_recs_cnt => x_error_cnt
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
        mark_records_for_processing(p_restart_flag => p_restart_flag, p_override_flag => p_override_flag);

        -- Once the records are identified based on the input parameters
        -- Start with pre-validations
        IF NVL ( p_override_flag, xx_emf_cn_pkg.CN_NO) = xx_emf_cn_pkg.CN_NO THEN
                -- Set the stage to Pre Validations
                set_stage (xx_emf_cn_pkg.CN_PREVAL);

                -- Change the validations package to the appropriate package name
                -- Modify the parameters as required
                -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
                -- PRE_VALIDATIONS SHOULD BE RETAINED
                x_error_code := xx_qp_mod_list_cnv_val_pkg.pre_validations (p_batch_id);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After pre-validations X_ERROR_CODE ' || X_ERROR_CODE);

                -- Update process code of staging records
                -- Also move the successful records to pre-interface tables
                COMMIT;
                update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS);
                xx_emf_pkg.propagate_error ( x_error_code);
                x_error_code := move_rec_pre_standard_table;
                xx_emf_pkg.propagate_error ( x_error_code);

                --Marked the Duplicate combinations of ITEM and Organization
                --mark_duplicate_combination;--DROY COMMENT THIS NOW LATER ON UNCOMMENT
        END IF;

        -- Once pre-validations are complete the loop through the pre-interface records
        -- and perform data validations on this table
        -- Set the stage to data Validations
        set_stage (xx_emf_cn_pkg.CN_VALID);

        -- Loop For Modifier - Data Validation
        OPEN c_xx_cnv_pre_std_mdf_hdr ( xx_emf_cn_pkg.CN_PREVAL);
        LOOP
                FETCH c_xx_cnv_pre_std_mdf_hdr
                BULK COLLECT INTO x_pre_std_hdr_mdf_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

                FOR i IN 1 .. x_pre_std_hdr_mdf_table.COUNT
                LOOP

                        BEGIN
                                -- Perform header level Base App Validations
                                x_error_code := xx_qp_mod_list_cnv_val_pkg.data_validations (
                                                        x_pre_std_hdr_mdf_table (i));
                                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_hdr_mdf_table (i).record_number|| ' is ' || x_error_code);

                                update_record_status (x_pre_std_hdr_mdf_table (i), x_error_code);
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
                                        update_pre_interface_records ( x_pre_std_hdr_mdf_table);
                                        RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                                WHEN OTHERS
                                THEN
                                        xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_hdr_mdf_table (i).record_number);
                        END;

                END LOOP;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_hdr_mdf_table.count ' || x_pre_std_hdr_mdf_table.COUNT );

                update_pre_interface_records ( x_pre_std_hdr_mdf_table);

                x_pre_std_hdr_mdf_table.DELETE;

                EXIT WHEN c_xx_cnv_pre_std_mdf_hdr%NOTFOUND;
        END LOOP;

        IF c_xx_cnv_pre_std_mdf_hdr%ISOPEN THEN
                CLOSE c_xx_cnv_pre_std_mdf_hdr;
        END IF;

        -- Loop For Modifier Lines- Data Validation
        /*OPEN c_xx_cnv_pre_std_mdf_lines ( xx_emf_cn_pkg.CN_PREVAL);
        LOOP
                FETCH c_xx_cnv_pre_std_mdf_lines
                BULK COLLECT INTO x_pre_std_lines_mdf_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

                FOR i IN 1 .. x_pre_std_lines_mdf_table.COUNT
                LOOP

                        BEGIN
                                -- Perform line level Base App Validations
                                x_error_code := xx_qp_mod_list_cnv_val_pkg.data_validations (
                                                        x_pre_std_lines_mdf_table (i));
                                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_lines_mdf_table (i).record_number|| ' is '
                                                    || x_error_code);

                                update_record_status (x_pre_std_lines_mdf_table (i), x_error_code);
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
                                        update_pre_interface_records ( x_pre_std_lines_mdf_table);
                                        RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                                WHEN OTHERS
                                THEN
                                        xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND
                                                         , x_pre_std_hdr_mdf_table (i).record_number);
                        END;

                END LOOP;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_lines_mdf_table.count ' || x_pre_std_lines_mdf_table.COUNT );

                update_pre_interface_records ( x_pre_std_lines_mdf_table);

                x_pre_std_lines_mdf_table.DELETE;

                EXIT WHEN c_xx_cnv_pre_std_mdf_lines%NOTFOUND;
        END LOOP;

        IF c_xx_cnv_pre_std_mdf_lines%ISOPEN THEN
                CLOSE c_xx_cnv_pre_std_mdf_lines;
        END IF;*/
        x_error_code := xx_qp_mod_list_cnv_val_pkg.data_validations (p_batch_id);
        UPDATE xx_qp_mdpr_list_lines_pre
        SET process_code  = g_stage
       WHERE (ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
             OR  process_code = xx_emf_cn_pkg.CN_STG_DATAVAL
             );
        COMMIT;



        -- Loop For Qualifier - Data Validation
        OPEN c_xx_cnv_pre_std_qlf_hdr ( xx_emf_cn_pkg.CN_PREVAL);
        LOOP
                FETCH c_xx_cnv_pre_std_qlf_hdr
                BULK COLLECT INTO x_pre_std_hdr_qlf_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

                FOR i IN 1 .. x_pre_std_hdr_qlf_table.COUNT
                LOOP

                        BEGIN
                                -- Perform header level Base App Validations
                                x_error_code := xx_qp_mod_list_cnv_val_pkg.data_validations (
                                                        x_pre_std_hdr_qlf_table (i));--DROY 29JULY UNCOMMENT
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

        -- Loop For Modifier - Data Derivation
        OPEN c_xx_cnv_pre_std_mdf_hdr ( xx_emf_cn_pkg.CN_VALID);
        LOOP
                FETCH c_xx_cnv_pre_std_mdf_hdr
                BULK COLLECT INTO x_pre_std_hdr_mdf_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_hdr_mdf_table.COUNT before data derivation '||x_pre_std_hdr_mdf_table.COUNT);
                FOR i IN 1 .. x_pre_std_hdr_mdf_table.COUNT
                LOOP

                        BEGIN

                                -- Perform header level Base App Validations
                                x_error_code := xx_qp_mod_list_cnv_val_pkg.data_derivations (
                                                        x_pre_std_hdr_mdf_table (i));
                                --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_hdr_table (i).record_number|| ' is ' || x_error_code);

                                update_record_status (x_pre_std_hdr_mdf_table (i), x_error_code);
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
                                        update_pre_interface_records ( x_pre_std_hdr_mdf_table);
                                        RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                                WHEN OTHERS
                                THEN
                                        xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_hdr_mdf_table (i).record_number);
                        END;

                END LOOP;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_hdr_mdf_table.count ' || x_pre_std_hdr_mdf_table.COUNT );

                update_pre_interface_records (x_pre_std_hdr_mdf_table);

                x_pre_std_hdr_mdf_table.DELETE;

                EXIT WHEN c_xx_cnv_pre_std_mdf_hdr%NOTFOUND;
        END LOOP;

        IF c_xx_cnv_pre_std_mdf_hdr%ISOPEN THEN
                CLOSE c_xx_cnv_pre_std_mdf_hdr;
        END IF;

        -- Loop For Modifier Lines- Data Derivation
        /*OPEN c_xx_cnv_pre_std_mdf_lines ( xx_emf_cn_pkg.CN_VALID);
        LOOP
                FETCH c_xx_cnv_pre_std_mdf_lines
                BULK COLLECT INTO x_pre_std_lines_mdf_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_lines_mdf_table.COUNT before data derivation '||x_pre_std_lines_mdf_table.COUNT);
                FOR i IN 1 .. x_pre_std_lines_mdf_table.COUNT
                LOOP

                        BEGIN

                                -- Perform header level Base App Validations
                                x_error_code := xx_qp_mod_list_cnv_val_pkg.data_derivations (
                                                        x_pre_std_lines_mdf_table (i));
                                --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_lines_table (i).record_number|| ' is ' || x_error_code);

                                update_record_status (x_pre_std_lines_mdf_table (i), x_error_code);
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
                                        update_pre_interface_records ( x_pre_std_lines_mdf_table);
                                        RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                                WHEN OTHERS
                                THEN
                                        xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR,
                                                         xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_hdr_mdf_table (i).record_number);
                        END;

                END LOOP;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_lines_mdf_table.count ' || x_pre_std_lines_mdf_table.COUNT );

                update_pre_interface_records (x_pre_std_lines_mdf_table);

                x_pre_std_lines_mdf_table.DELETE;

                EXIT WHEN c_xx_cnv_pre_std_mdf_lines%NOTFOUND;
        END LOOP;

        IF c_xx_cnv_pre_std_mdf_lines%ISOPEN THEN
                CLOSE c_xx_cnv_pre_std_mdf_lines;
        END IF;
        */
        UPDATE xx_qp_mdpr_list_lines_pre
      SET process_code  = g_stage
      WHERE (ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
             );
      COMMIT;

        -- Loop For Qualifier - Data Derivation
        /*OPEN c_xx_cnv_pre_std_qlf_hdr ( xx_emf_cn_pkg.CN_VALID);
        LOOP
                FETCH c_xx_cnv_pre_std_qlf_hdr
                BULK COLLECT INTO x_pre_std_hdr_qlf_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_hdr_qlf_table.COUNT before data derivation '||x_pre_std_hdr_qlf_table.COUNT);

                FOR i IN 1 .. x_pre_std_hdr_qlf_table.COUNT
                LOOP

                        BEGIN

                                -- Perform header level Base App Validations
                                /*x_error_code := xx_qp_mod_list_cnv_val_pkg.data_derivations (
                                                        x_pre_std_hdr_qlf_table (i));--DROY 29JULY UNCOMMENT
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
        END IF;*/

        UPDATE xx_qp_mdpr_list_qlf_pre
        SET process_code  = g_stage
        WHERE (ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
             );
        COMMIT;

        -- Set the stage to Pre Validations
        set_stage (xx_emf_cn_pkg.CN_POSTVAL);

        -- CCID099 changes
        -- Change the validations package to the appropriate package name
        -- Modify the parameters as required
        -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
        -- PRE_VALIDATIONS SHOULD BE RETAINED
        x_error_code := xx_qp_mod_list_cnv_val_pkg.post_validations(G_BATCH_ID);
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
        mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL);
        xx_emf_pkg.propagate_error ( x_error_code);

        IF p_validate_and_load = g_validate_and_load THEN

        -- Set the stage to Pre Validations
        set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);

        /***** Write Code for Process Data ******/
        x_error_code := process_data ();
        mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA);
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
                    update_record_count;
                    xx_emf_pkg.create_report;
            WHEN xx_emf_pkg.G_E_REC_ERROR THEN
                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'xx_emf_pkg.G_E_REC_ERROR'||SQLERRM);

                    retcode := xx_emf_cn_pkg.CN_REC_ERR;
                    update_record_count;
                    xx_emf_pkg.create_report;
            WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'xx_emf_pkg.G_E_PRC_ERROR=>'||SQLERRM);
                    retcode := xx_emf_cn_pkg.CN_PRC_ERR;
                    update_record_count;
                    xx_emf_pkg.create_report;
            WHEN OTHERS THEN
                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'OTHERS=>'||SQLERRM);
                    retcode := xx_emf_cn_pkg.CN_PRC_ERR;
                    update_record_count;
                    xx_emf_pkg.create_report;

    END main;

END xx_qp_mod_list_cnv_pkg ;
/
