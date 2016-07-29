DROP PACKAGE BODY APPS.XX_ONT_CUSTITEMORDER_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_ONT_CUSTITEMORDER_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development Team
 Creation Date  : 30-AUG-2013
 File Name      : XXONTITEMORDERTL.pkb
 Description    : This script creates the body of the package xx_ont_itemord_pkg

COMMON GUIDELINES REGARDING EMF
-------------------------------

1. ALL LOW LEVEL EMF MESSAGES CAN BE RETAINED
2. HARD CODING OF EMF MESSAGES ARE ALLOWED IN THE CODE
3. ANY OTHER HARD CODING SHOULD BE DEALT BY CONSTANTS PACKAGE
4. EXCEPTION HANDLING SHOULD BE LEFT AS IS MOST OF THE PLACES UNLESS SPECIFIED

 Change History:

Version Date        Name            Remarks
------- ----------- ------------        ---------------------------------------
1.0     30-AUG-2013 Mou Mukherjee    Initial development.
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
                fnd_file.PUT_LINE ( fnd_file.output, 'When Others Exception...');
                        --RAISE xx_emf_pkg.G_E_ENV_NOT_SET;
        END set_cnv_env;

-------------------------------------------------------------------------
-----------< mark_records_for_processing >-------------------------------
-------------------------------------------------------------------------

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
                                DELETE FROM xx_ont_item_order_pre
                                 WHERE batch_id = G_BATCH_ID;

                                UPDATE xx_ont_item_order_stg
                                   SET request_id = xx_emf_pkg.G_REQUEST_ID,
                                       error_code = xx_emf_cn_pkg.CN_NULL,
                                       process_code = xx_emf_cn_pkg.CN_NEW
                                 WHERE batch_id = G_BATCH_ID;

                                 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No of Records updated for processing=>'||SQL%ROWCOUNT);
                        ELSE
                                UPDATE xx_ont_item_order_pre
                                   SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                                       error_code = xx_emf_cn_pkg.CN_SUCCESS,
                                       request_id = xx_emf_pkg.G_REQUEST_ID
                                 WHERE batch_id = G_BATCH_ID;
                        END IF;

                ELSIF p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS THEN

                        IF p_override_flag = xx_emf_cn_pkg.CN_NO THEN

                                -- Update staging table
                                UPDATE xx_ont_item_order_stg
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
                        UPDATE xx_ont_item_order_stg a
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_NULL,
                               process_code = xx_emf_cn_pkg.CN_NEW
                         WHERE batch_id = G_BATCH_ID
                           AND EXISTS (
                                SELECT 1
                                  FROM xx_ont_item_order_pre
                                 WHERE batch_id = G_BATCH_ID
                                   AND process_code = xx_emf_cn_pkg.CN_PREVAL
                                   AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                                   AND sequence_num = a.sequence_num);

                        DELETE
                          FROM xx_ont_item_order_pre
                         WHERE batch_id = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_PREVAL
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                        -- Scenario 2 Data Validation Stage
                        UPDATE xx_ont_item_order_pre
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               process_code = xx_emf_cn_pkg.CN_PREVAL
                         WHERE batch_id = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_VALID
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                        -- Scenario 3 Data Derivation Stage
                        UPDATE xx_ont_item_order_pre
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               process_code = xx_emf_cn_pkg.CN_DERIVE
                         WHERE batch_id = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_DERIVE
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                        -- Scenario 4 Post Validation Stage
                        UPDATE xx_ont_item_order_pre
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               process_code = xx_emf_cn_pkg.CN_POSTVAL
                         WHERE batch_id = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_POSTVAL
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                        -- Scenario 5 Process Data Stage
                        UPDATE xx_ont_item_order_pre
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               process_code = xx_emf_cn_pkg.CN_POSTVAL
                         WHERE batch_id = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_ERR);

                END IF;
                COMMIT;
        END;

-------------------------------------------------------------------------
-----------< set_stage >-------------------------------
-------------------------------------------------------------------------

        PROCEDURE set_stage (p_stage VARCHAR2)
        IS
        BEGIN
                G_STAGE := p_stage;
        END set_stage;

-------------------------------------------------------------------------
-----------< update_staging_records >-------------------------------
-------------------------------------------------------------------------

        PROCEDURE update_staging_records( p_error_code VARCHAR2) IS
                x_last_update_date       DATE := SYSDATE;
                x_last_updated_by        NUMBER := fnd_global.user_id;
               -- x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

                PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'update_staging_records for G_BATCH_ID='||G_BATCH_ID||' G_STAGE = '||G_STAGE);

                UPDATE xx_ont_item_order_stg
                   SET process_code = G_STAGE,
                       error_code = DECODE ( error_code, NULL, p_error_code, error_code),
                       last_update_date = x_last_update_date,
                       last_updated_by = x_last_updated_by
                      -- last_update_login = x_last_update_login
                 WHERE batch_id = G_BATCH_ID
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   AND process_code = xx_emf_cn_pkg.CN_NEW;

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No of Records updated=>'||SQL%ROWCOUNT);

                COMMIT;
        END update_staging_records;
        -- END RESTRICTIONS

        PROCEDURE main (
                errbuf OUT VARCHAR2,
                retcode OUT VARCHAR2,
                p_batch_id IN VARCHAR2,
                p_restart_flag IN VARCHAR2,
                p_override_flag IN VARCHAR2,
        p_validate_and_load IN VARCHAR2
        ) IS
                x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
                x_pre_std_hdr_table G_XX_ITEMORDER_PRE_TAB_TYPE;


                -- CURSOR FOR VARIOUS STAGES
                CURSOR c_xx_intg_pre_std_hdr ( cp_process_status VARCHAR2) IS
                SELECT    *
                  FROM xx_ont_item_order_pre
                 WHERE batch_id = G_BATCH_ID
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   AND process_code = cp_process_status
                   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                 ORDER BY sequence_num;


-------------------------------------------------------------------------
-----------< update_record_status >-------------------------------
-------------------------------------------------------------------------

                PROCEDURE update_record_status (
                        p_conv_pre_std_hdr_rec  IN OUT  G_XX_ITEMORDER_PRE_REC_TYPE,
                        p_error_code            IN      VARCHAR2
                )
                IS
                BEGIN

                        IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
                        THEN
                            p_conv_pre_std_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                        ELSE
                           -- p_conv_pre_std_hdr_rec.error_code := xx_intg_common_pkg.find_max (p_error_code, NVL (p_conv_pre_std_hdr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));
               NULL;
                        END IF;

                        p_conv_pre_std_hdr_rec.process_code := G_STAGE;
                END update_record_status;

-------------------------------------------------------------------------
-----------< mark_records_complete >-------------------------------
-------------------------------------------------------------------------

                PROCEDURE mark_records_complete
                (
                        p_process_code VARCHAR2
                )
                IS
                        x_last_update_date       DATE := SYSDATE;
                        x_last_updated_by        NUMBER := fnd_global.user_id;
                       -- x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

                        PRAGMA AUTONOMOUS_TRANSACTION;
                BEGIN
                        UPDATE xx_ont_item_order_pre
                           SET process_code = G_STAGE,
                               error_code = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
                               last_updated_by = x_last_updated_by,
                               last_update_date = x_last_update_date
                            --   last_update_login = x_last_update_login
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
                           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

                        COMMIT;
                END mark_records_complete;

-------------------------------------------------------------------------
-----------< update_pre_interface_records >-------------------------------
-------------------------------------------------------------------------

                PROCEDURE update_pre_interface_records (p_cnv_pre_std_hdr_table IN G_XX_ITEMORDER_PRE_TAB_TYPE)
                IS
                        x_last_update_date      DATE := SYSDATE;
                        x_last_updated_by       NUMBER := fnd_global.user_id;
                      --  x_last_update_login     NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

                        PRAGMA AUTONOMOUS_TRANSACTION;
                BEGIN

                        FOR indx IN 1 .. p_cnv_pre_std_hdr_table.COUNT LOOP
                                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).process_code ' || p_cnv_pre_std_hdr_table(indx).process_code);
                                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).error_code ' || p_cnv_pre_std_hdr_table(indx).error_code);
                                UPDATE xx_ont_item_order_pre
                                   SET  criteria        = p_cnv_pre_std_hdr_table(indx).criteria,
                                        item_number        = p_cnv_pre_std_hdr_table(indx).item_number,
                                        inventory_item_id    = p_cnv_pre_std_hdr_table(indx).inventory_item_id,
                                        CAT_SEG1        = p_cnv_pre_std_hdr_table(indx).CAT_SEG1,
                    CAT_SEG2        = p_cnv_pre_std_hdr_table(indx).CAT_SEG2,
                    CAT_SEG3        = p_cnv_pre_std_hdr_table(indx).CAT_SEG3,
                    CAT_SEG4        = p_cnv_pre_std_hdr_table(indx).CAT_SEG4,
                    CAT_SEG5        = p_cnv_pre_std_hdr_table(indx).CAT_SEG5,
                    CAT_SEG6        = p_cnv_pre_std_hdr_table(indx).CAT_SEG6,
                                        rule_level        = p_cnv_pre_std_hdr_table(indx).rule_level,
                                        rule_level_value    = p_cnv_pre_std_hdr_table(indx).rule_level_value,
                    customer_id             = p_cnv_pre_std_hdr_table(indx).customer_id,
                    customer_class_id       = p_cnv_pre_std_hdr_table(indx).customer_class_id,
                    end_customer_id         = p_cnv_pre_std_hdr_table(indx).end_customer_id,
                    customer_category_code  = p_cnv_pre_std_hdr_table(indx).customer_category_code,
                    customer_class_code     = p_cnv_pre_std_hdr_table(indx).customer_class_code,
                    order_type_id           = p_cnv_pre_std_hdr_table(indx).order_type_id,
                    sales_channel_code      = p_cnv_pre_std_hdr_table(indx).sales_channel_code,
                    sales_person_id         = p_cnv_pre_std_hdr_table(indx).sales_person_id,
                    ship_to_location_id     = p_cnv_pre_std_hdr_table(indx).ship_to_location_id,
                    bill_to_location_id     = p_cnv_pre_std_hdr_table(indx).bill_to_location_id,
                    deliver_to_location_id  = p_cnv_pre_std_hdr_table(indx).deliver_to_location_id,
                    region_id               = p_cnv_pre_std_hdr_table(indx).region_id,
                    source_inv_code         = p_cnv_pre_std_hdr_table(indx).source_inv_code,
                    start_date              = p_cnv_pre_std_hdr_table(indx).start_date,
                    end_date                = p_cnv_pre_std_hdr_table(indx).end_date,
                    restriction_type        = p_cnv_pre_std_hdr_table(indx).restriction_type,
                    registration_num        = p_cnv_pre_std_hdr_table(indx).registration_num,
                                        note                    = p_cnv_pre_std_hdr_table(indx).note,
                    batch_id                = p_cnv_pre_std_hdr_table(indx).batch_id,
                    sequence_num            = p_cnv_pre_std_hdr_table(indx).sequence_num,
                                        process_code        = p_cnv_pre_std_hdr_table(indx).process_code,
                                        error_code        = p_cnv_pre_std_hdr_table(indx).error_code,
                                        last_updated_by        = x_last_updated_by,
                                        last_update_date    = x_last_update_date
                                 where sequence_num = p_cnv_pre_std_hdr_table(indx).sequence_num
                                   and (item_number = p_cnv_pre_std_hdr_table(indx).item_number
                          or (NVL(CAT_SEG1,1)          = NVL(p_cnv_pre_std_hdr_table(indx).CAT_SEG1,1)
                          and NVL(CAT_SEG2,1)        = NVL(p_cnv_pre_std_hdr_table(indx).CAT_SEG2,1)
                      and NVL(CAT_SEG3,1)        = NVL(p_cnv_pre_std_hdr_table(indx).CAT_SEG3,1)
                      and NVL(CAT_SEG4,1)        = NVL(p_cnv_pre_std_hdr_table(indx).CAT_SEG4,1)
                      and NVL(CAT_SEG5,1)        = NVL(p_cnv_pre_std_hdr_table(indx).CAT_SEG5,1)
                      and NVL(CAT_SEG6,1)        = NVL(p_cnv_pre_std_hdr_table(indx).CAT_SEG6,1)
                      and item_number IS NULL))
                   AND batch_id      = g_batch_id;
                        END LOOP;

                        COMMIT;
                END update_pre_interface_records;

-------------------------------------------------------------------------
-----------< move_rec_pre_standard_table >-------------------------------
-------------------------------------------------------------------------

                FUNCTION move_rec_pre_standard_table RETURN NUMBER
                IS
                        x_creation_date         DATE := SYSDATE;
                        x_created_by            NUMBER := fnd_global.user_id;
                        x_last_update_date      DATE := SYSDATE;
                        x_last_updated_by        NUMBER := fnd_global.user_id;
                     --   x_last_update_login      NUMBER := fnd_profile.value(xx_emf_cn_pkg.CN_LOGIN_ID);
                       -- x_cnv_pre_std_hdr_table G_XX_ITEMORD_PRE_TAB_TYPE := G_XX_ITEMORD_PRE_TAB_TYPE();
                       -- x_cnv_pre_std_hdr_table XX_INTG_CNV_PRE_STD_TAB_TYPE := XX_INTG_CNV_PRE_STD_TAB_TYPE();


                        x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

                        PRAGMA AUTONOMOUS_TRANSACTION;

                BEGIN
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside move_rec_pre_standard_table');

                        -- Select only the appropriate columns that are required to be inserted into the
                        -- Pre-Interface Table and insert from the Staging Table
                        INSERT INTO xx_ont_item_order_pre
                        (
                            BATCH_ID,
                SEQUENCE_NUM,
                CRITERIA,
                ITEM_NUMBER,
                CAT_SEG1,
                CAT_SEG2,
                CAT_SEG3,
                CAT_SEG4,
                CAT_SEG5,
                CAT_SEG6,
                RULE_LEVEL,
                RULE_LEVEL_VALUE,
                SOURCE_INV_CODE,
                START_DATE,
                END_DATE,
                RESTRICTION_TYPE,
                REGISTRATION_NUM,
                NOTE,
                ATTRIBUTE1,
                ATTRIBUTE2,
                ATTRIBUTE3,
                ATTRIBUTE4,
                ATTRIBUTE5,
                ATTRIBUTE6,
                ATTRIBUTE7,
                ATTRIBUTE8,
                ATTRIBUTE9,
                ATTRIBUTE10,
                PROCESS_CODE,
                ERROR_CODE,
                CREATION_DATE,
                CREATED_BY,
                LAST_UPDATE_DATE,
                LAST_UPDATED_BY,
                REQUEST_ID
                        )
                        SELECT BATCH_ID,
                SEQUENCE_NUM,
                CRITERIA,
                ITEM_NUMBER,
                CAT_SEG1,
                CAT_SEG2,
                CAT_SEG3,
                CAT_SEG4,
                CAT_SEG5,
                CAT_SEG6,
                RULE_LEVEL,
                RULE_LEVEL_VALUE,
                SOURCE_INV_CODE,
                START_DATE,
                END_DATE,
                RESTRICTION_TYPE,
                REGISTRATION_NUM,
                NOTE,
                ATTRIBUTE1,
                ATTRIBUTE2,
                ATTRIBUTE3,
                ATTRIBUTE4,
                ATTRIBUTE5,
                ATTRIBUTE6,
                ATTRIBUTE7,
                ATTRIBUTE8,
                ATTRIBUTE9,
                ATTRIBUTE10,
                   G_STAGE,
                                ERROR_CODE,
                X_CREATION_DATE,
                                X_CREATED_BY,
                X_LAST_UPDATE_DATE,
                                X_LAST_UPDATED_BY,
                REQUEST_ID
                          FROM xx_ont_item_order_stg
                         WHERE BATCH_ID = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_PREVAL
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

                           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'INSERTED INTO PRE INT'||SQL%ROWCOUNT);

                        COMMIT;

                        RETURN x_error_code;

                EXCEPTION
                        WHEN OTHERS THEN
                                xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND,SQLERRM);
                                x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
                                RETURN x_error_code;
                END move_rec_pre_standard_table;

-------------------------------------------------------------------------
-----------< mark_records_for_api_error >-------------------------------
-------------------------------------------------------------------------

                PROCEDURE mark_records_for_api_error
                (
                        p_process_code       IN VARCHAR2
                       ,p_record_number         IN NUMBER
                )
                IS
                        x_last_update_date       DATE := SYSDATE;
                        x_last_updated_by        NUMBER := fnd_global.user_id;
            x_record_count        NUMBER;
                       -- x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
               PRAGMA AUTONOMOUS_TRANSACTION;
                BEGIN

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside Mark Record for API Error'
                              );
                        UPDATE xx_ont_item_order_pre
                           SET process_code = G_STAGE,
                               error_code = xx_emf_cn_pkg.CN_REC_ERR,
                               last_updated_by = x_last_updated_by,
                               last_update_date = x_last_update_date
                             --  last_update_login = x_last_update_login
                         WHERE request_id      = xx_emf_pkg.G_REQUEST_ID
                           AND sequence_num    = p_record_number
                           AND batch_id        = G_BATCH_ID
                           AND process_code    = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
                                                           , xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE
                                                           )
                           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                           ;
               x_record_count := SQL%ROWCOUNT;
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'No of Record Marked with API Error=>'
                               || x_record_count
                              );
                END mark_records_for_api_error;


-------------------------------------------------------------------------
-----------< process_data >-------------------------------
-------------------------------------------------------------------------

                FUNCTION process_data
          RETURN NUMBER
                IS
                    x_return_status VARCHAR2(15)     := xx_emf_cn_pkg.CN_SUCCESS;
                    x_api_version       NUMBER       := 1.0;
                    x_init_msg_list     VARCHAR2(10) := FND_API.G_TRUE;
                    x_commit            VARCHAR2(10) := FND_API.G_TRUE;
                    v_return_status     VARCHAR2(1)  := 'S';
                    v_errorcode         NUMBER       := 0;
                    n_msg_count         NUMBER       := 0;
                    v_msg_data          VARCHAR2(500):= 0;
                    x_category_id       NUMBER       := 0;
                    x_category_set_id   NUMBER       := 0;
                    x_inventory_item_id NUMBER       := 0;
                    x_organization_id   NUMBER       := 0;
                    x_old_category_id   NUMBER       := 0;
                    n_assign_exist      NUMBER       := 0;
                    l_out_index         NUMBER;
            l_cnt               NUMBER       :=0;
            l_cnt_item               NUMBER       :=0;
            l_cnt_cat               NUMBER       :=0;
        --    x_batch_commit    NUMBER :=0;

           CURSOR cur_itemord
           IS
           SELECT *
             FROM xx_ont_item_order_pre
             WHERE batch_id = G_BATCH_ID
               AND request_id = xx_emf_pkg.G_REQUEST_ID
               AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
               AND process_code = xx_emf_cn_pkg.CN_POSTVAL;

            PRAGMA AUTONOMOUS_TRANSACTION;

            l_orderability_id    number;

                BEGIN
                    -- Change the logic to whatever needs to be done
                    -- with valid records in the pre-interface tables
                    -- either call the appropriate API to process the data
                    -- or to insert into an interface table


                    FOR cur_rec IN cur_itemord
                    LOOP
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inserting......... =>');
            --x_batch_commit := x_batch_commit + 1;

            SELECT xxintg_ior_seq.nextval
            INTO l_orderability_id
            FROM dual;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inserting......... =>'||l_orderability_id||' - '||cur_rec.criteria ||' - '||cur_rec.inventory_item_id ||' - '||cur_rec.rule_level ||' - '|| cur_rec.created_by||' - '||cur_rec.creation_date ||' - '||cur_rec.last_updated_by ||' - '||cur_rec.last_update_date);

                select count(1)
                into l_cnt_item
                from XXINTG_ITEM_ORDERABILITY
                where SEQUENCE = cur_rec.sequence_num
                AND   ITEM_LEVEL = cur_rec.criteria
                AND   ITEM_LEVEL = 'I'
                AND   INVENTORY_ITEM_ID = cur_rec.inventory_item_id;

            select count(1)
                into l_cnt_cat
                from XXINTG_ITEM_ORDERABILITY
                where SEQUENCE = cur_rec.sequence_num
                AND   ITEM_LEVEL = cur_rec.criteria
                AND   ITEM_LEVEL = 'C'
                                AND   CAT_SEG1 = cur_rec.CAT_SEG1
                AND   CAT_SEG2 = cur_rec.CAT_SEG2
                AND   CAT_SEG3 = cur_rec.CAT_SEG3
                AND   CAT_SEG4 = cur_rec.CAT_SEG4
                AND   CAT_SEG5 = cur_rec.CAT_SEG5
                AND   CAT_SEG6 = cur_rec.CAT_SEG6;


            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'L_count......... =>'||l_cnt);
            If l_cnt_item = 0 and l_cnt_cat = 0 THEN

            INSERT INTO XXINTG_ITEM_ORDERABILITY
             (
              CUSTOM_ORD_ID,
              INV_ORG_ID,
              SEQUENCE,
              ITEM_LEVEL,
              CAT_SEG1,
              CAT_SEG2,
              CAT_SEG3,
              CAT_SEG4,
              CAT_SEG5,
              CAT_SEG6,
              INVENTORY_ITEM_ID,
              RULE_LEVEL,
              CUSTOMER_ID,
              CUSTOMER_CLASS_ID,
              END_CUSTOMER_ID,
              CUSTOMER_CATEGORY_CODE,
              CUSTOMER_CLASS_CODE,
              ORDER_TYPE_ID,
              SALES_CHANNEL_CODE,
              SALES_PERSON_ID,
              SHIP_TO_LOCATION_ID,
              BILL_TO_LOCATION_ID,
              DELIVER_TO_LOCATION_ID,
              REGION_ID,
              START_DATE,
              END_DATE,
              RESTRICTION_CODE,
              REG_NUMBER,
              NOTE,
              ATTRIBUTE_CATEGORY,
              ATTRIBUTE1,
              ATTRIBUTE2,
              ATTRIBUTE3,
              ATTRIBUTE4,
              ATTRIBUTE5,
              ATTRIBUTE6,
              ATTRIBUTE7,
              ATTRIBUTE8,
              ATTRIBUTE9,
              ATTRIBUTE10,
              CREATED_BY,
              CREATION_DATE,
              LAST_UPDATED_BY,
              LAST_UPDATE_DATE
             )
            VALUES (
              l_orderability_id,
              null,
              cur_rec.sequence_num,
              cur_rec.criteria,
              cur_rec.CAT_SEG1,
              cur_rec.CAT_SEG2,
              cur_rec.CAT_SEG3,
              cur_rec.CAT_SEG4,
              cur_rec.CAT_SEG5,
              cur_rec.CAT_SEG6,
              cur_rec.inventory_item_id,
              cur_rec.rule_level,
              cur_rec.customer_id,
              cur_rec.customer_class_id,
              cur_rec.end_customer_id,
              cur_rec.customer_category_code,
              cur_rec.customer_class_code,
              cur_rec.order_type_id,
              cur_rec.sales_channel_code,
              cur_rec.sales_person_id,
              cur_rec.ship_to_location_id,
              cur_rec.bill_to_location_id,
              cur_rec.deliver_to_location_id,
              cur_rec.region_id,
              cur_rec.start_date,
              cur_rec.end_date,
              cur_rec.restriction_type,
                          cur_rec.registration_num,
              cur_rec.note,
              null,
              cur_rec.attribute1,
              cur_rec.attribute2,
              cur_rec.attribute3,
              cur_rec.attribute4,
              cur_rec.attribute5,
              cur_rec.attribute6,
              cur_rec.attribute7,
              cur_rec.attribute8,
              cur_rec.attribute9,
              cur_rec.attribute10,
              cur_rec.created_by,
              cur_rec.creation_date,
              cur_rec.last_updated_by,
              cur_rec.last_update_date
             );

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inserting......... =>'||l_orderability_id||' - '||cur_rec.criteria ||' - '||cur_rec.inventory_item_id ||' - '||cur_rec.rule_level ||' - '||cur_rec.created_by||' - '||cur_rec.creation_date ||' - '||cur_rec.last_updated_by ||' - '||cur_rec.last_update_date);

            --IF x_batch_commit >= 10000 THEN -- Commit for every 10000 record as per review comment
            --COMMIT;
              -- END IF;
            ELSIF l_cnt_item != 0 and l_cnt_cat = 0 Then
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Updating......... =>'||l_orderability_id);
                           UPDATE XXINTG_ITEM_ORDERABILITY
               set RULE_LEVEL = cur_rec.rule_level,
              CUSTOMER_ID = cur_rec.customer_id,
              CUSTOMER_CLASS_ID =cur_rec.customer_class_id,
              END_CUSTOMER_ID = cur_rec.end_customer_id,
              CUSTOMER_CATEGORY_CODE = cur_rec.customer_category_code,
              CUSTOMER_CLASS_CODE = cur_rec.customer_class_code,
              ORDER_TYPE_ID = cur_rec.order_type_id,
              SALES_CHANNEL_CODE = cur_rec.sales_channel_code,
              SALES_PERSON_ID = cur_rec.sales_person_id,
              SHIP_TO_LOCATION_ID = cur_rec.ship_to_location_id,
              BILL_TO_LOCATION_ID = cur_rec.bill_to_location_id,
              DELIVER_TO_LOCATION_ID = cur_rec.deliver_to_location_id,
              REGION_ID = cur_rec.region_id,
              START_DATE = cur_rec.start_date,
              END_DATE = cur_rec.end_date,
              RESTRICTION_CODE = cur_rec.restriction_type,
              REG_NUMBER = cur_rec.registration_num,
              NOTE = cur_rec.note,
              ATTRIBUTE1 = cur_rec.attribute1,
              ATTRIBUTE2 = cur_rec.attribute2,
              ATTRIBUTE3 = cur_rec.attribute3,
              ATTRIBUTE4 = cur_rec.attribute4,
              ATTRIBUTE5 = cur_rec.attribute5,
              ATTRIBUTE6 = cur_rec.attribute6,
              ATTRIBUTE7 = cur_rec.attribute7,
              ATTRIBUTE8 = cur_rec.attribute8,
              ATTRIBUTE9 = cur_rec.attribute9,
              ATTRIBUTE10 = cur_rec.attribute10,
              LAST_UPDATED_BY = cur_rec.last_updated_by,
              LAST_UPDATE_DATE = cur_rec.last_update_date
              where SEQUENCE = cur_rec.sequence_num
                AND   ITEM_LEVEL = cur_rec.criteria
                AND   ITEM_LEVEL = 'I'
                AND   INVENTORY_ITEM_ID = cur_rec.inventory_item_id;

                ELSIF l_cnt_item = 0 and l_cnt_cat != 0 Then
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Updating......... =>'||l_orderability_id);
                           UPDATE XXINTG_ITEM_ORDERABILITY
               set RULE_LEVEL = cur_rec.rule_level,
              CUSTOMER_ID = cur_rec.customer_id,
              CUSTOMER_CLASS_ID =cur_rec.customer_class_id,
              END_CUSTOMER_ID = cur_rec.end_customer_id,
              CUSTOMER_CATEGORY_CODE = cur_rec.customer_category_code,
              CUSTOMER_CLASS_CODE = cur_rec.customer_class_code,
              ORDER_TYPE_ID = cur_rec.order_type_id,
              SALES_CHANNEL_CODE = cur_rec.sales_channel_code,
              SALES_PERSON_ID = cur_rec.sales_person_id,
              SHIP_TO_LOCATION_ID = cur_rec.ship_to_location_id,
              BILL_TO_LOCATION_ID = cur_rec.bill_to_location_id,
              DELIVER_TO_LOCATION_ID = cur_rec.deliver_to_location_id,
              REGION_ID = cur_rec.region_id,
              START_DATE = cur_rec.start_date,
              END_DATE = cur_rec.end_date,
              RESTRICTION_CODE = cur_rec.restriction_type,
              REG_NUMBER = cur_rec.registration_num,
              NOTE = cur_rec.note,
              ATTRIBUTE1 = cur_rec.attribute1,
              ATTRIBUTE2 = cur_rec.attribute2,
              ATTRIBUTE3 = cur_rec.attribute3,
              ATTRIBUTE4 = cur_rec.attribute4,
              ATTRIBUTE5 = cur_rec.attribute5,
              ATTRIBUTE6 = cur_rec.attribute6,
              ATTRIBUTE7 = cur_rec.attribute7,
              ATTRIBUTE8 = cur_rec.attribute8,
              ATTRIBUTE9 = cur_rec.attribute9,
              ATTRIBUTE10 = cur_rec.attribute10,
              LAST_UPDATED_BY = cur_rec.last_updated_by,
              LAST_UPDATE_DATE = cur_rec.last_update_date
              where SEQUENCE = cur_rec.sequence_num
                AND   ITEM_LEVEL = cur_rec.criteria
                AND   ITEM_LEVEL = 'C'
                                AND   CAT_SEG1 = cur_rec.CAT_SEG1
                AND   CAT_SEG2 = cur_rec.CAT_SEG2
                AND   CAT_SEG3 = cur_rec.CAT_SEG3
                AND   CAT_SEG4 = cur_rec.CAT_SEG4
                AND   CAT_SEG5 = cur_rec.CAT_SEG5
                AND   CAT_SEG6 = cur_rec.CAT_SEG6;

              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'After Updating......... =>'||l_orderability_id);
                END IF;
                     END LOOP;

             COMMIT;

                    RETURN x_return_status;
                END process_data;

-------------------------------------------------------------------------
-----------< update_record_count >-------------------------------
-------------------------------------------------------------------------

                PROCEDURE update_record_count
                IS
                        -- Cursor to count the total number of records in staging table.
                        CURSOR c_get_total_cnt IS
                        SELECT COUNT (1) total_count
                          FROM xx_ont_item_order_stg
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID;

                        x_total_cnt NUMBER;
                         -- cursor to count the total number of error record
                        CURSOR c_get_error_cnt IS
                        SELECT SUM(error_count)
                          FROm (SELECT COUNT (1) error_count
                          FROM xx_ont_item_order_stg
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND error_code = xx_emf_cn_pkg.CN_REC_ERR
                        UNION ALL
                        SELECT COUNT (1) error_count
                          FROM xx_ont_item_order_pre
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

                        x_error_cnt NUMBER;
                        -- cursor to count total number of warning record.
                        CURSOR c_get_warning_cnt IS
                        SELECT COUNT (1) warn_count
                          FROM xx_ont_item_order_pre
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

                        x_warn_cnt NUMBER;

            -- cursor to count total number of success record.
                        CURSOR c_get_success_cnt IS
                        SELECT COUNT (1) warn_count
                          FROM xx_ont_item_order_pre
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                          -- AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
              AND (p_validate_and_load= g_validate_and_load and process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                                OR 1=1 and process_code = xx_emf_cn_pkg.CN_DERIVE)
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

                END;
        BEGIN

        retcode := xx_emf_cn_pkg.CN_SUCCESS;

        --fnd_file.PUT_LINE ( fnd_file.output, 'When Others Exception...');

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
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_validate_and_load '    || p_validate_and_load);

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

                        x_error_code := xx_ont_itemord_val_pkg.pre_validations ();
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After pre-validations X_ERROR_CODE ' || X_ERROR_CODE);

                        -- Update process code of staging records
                        -- Also move the successful records to pre-interface tables
                        update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS);
                        xx_emf_pkg.propagate_error ( x_error_code);
                        x_error_code := move_rec_pre_standard_table;
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After move_rec_pre_standard_table X_ERROR_CODE ' || X_ERROR_CODE);
                        xx_emf_pkg.propagate_error ( x_error_code);
                END IF;

                -- Once pre-validations are complete the loop through the pre-interface records
                -- and perform data validations on this table
                -- Set the stage to data Validations
                set_stage (xx_emf_cn_pkg.CN_VALID);

                OPEN c_xx_intg_pre_std_hdr ( xx_emf_cn_pkg.CN_PREVAL);
                LOOP
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Before Data Validation Loop ' || X_ERROR_CODE);

                        FETCH c_xx_intg_pre_std_hdr
                        BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;


                        FOR i IN 1 .. x_pre_std_hdr_table.COUNT
                        LOOP
                                BEGIN
                                        -- Perform header level Base App Validations
                                        x_error_code := xx_ont_custitemorder_val_pkg.data_validations (
                                                                x_pre_std_hdr_table (i));
                                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_hdr_table (i).sequence_num|| ' is ' || x_error_code);

                                        update_record_status (x_pre_std_hdr_table (i), x_error_code);
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
                                                update_pre_interface_records ( x_pre_std_hdr_table);
                                                RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                                        WHEN OTHERS
                                        THEN
                                                xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_hdr_table (i).sequence_num);
                                END;

                        END LOOP;

                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_hdr_table.count ' || x_pre_std_hdr_table.COUNT );

                        update_pre_interface_records ( x_pre_std_hdr_table);

                        x_pre_std_hdr_table.DELETE;

                        EXIT WHEN c_xx_intg_pre_std_hdr%NOTFOUND;
                END LOOP;

                IF c_xx_intg_pre_std_hdr%ISOPEN THEN
                        CLOSE c_xx_intg_pre_std_hdr;
                END IF;

                -- Once data-validations are complete the loop through the pre-interface records
                -- and perform data derivations on this table
                -- Set the stage to data derivations
                set_stage (xx_emf_cn_pkg.CN_DERIVE);

                OPEN c_xx_intg_pre_std_hdr ( xx_emf_cn_pkg.CN_VALID);
                LOOP
                        FETCH c_xx_intg_pre_std_hdr
                        BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

                        FOR i IN 1 .. x_pre_std_hdr_table.COUNT
                        LOOP
                                BEGIN
                                        -- Perform header level Base App Validations
                                        x_error_code := xx_ont_custitemorder_val_pkg.data_derivations (
                                                                x_pre_std_hdr_table (i));
                                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_hdr_table (i).sequence_num|| ' is ' || x_error_code);

                                        update_record_status (x_pre_std_hdr_table (i), x_error_code);
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
                                                update_pre_interface_records ( x_pre_std_hdr_table);
                                                RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                                        WHEN OTHERS
                                        THEN
                        xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_hdr_table (i).sequence_num);
                                END;

                        END LOOP;

                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_hdr_table.count ' || x_pre_std_hdr_table.COUNT );

                        update_pre_interface_records ( x_pre_std_hdr_table);

                        x_pre_std_hdr_table.DELETE;

                        EXIT WHEN c_xx_intg_pre_std_hdr%NOTFOUND;
                END LOOP;

                IF c_xx_intg_pre_std_hdr%ISOPEN THEN
                        CLOSE c_xx_intg_pre_std_hdr;
                END IF;

                -- Set the stage to Pre Validations
           /*     set_stage (xx_emf_cn_pkg.CN_POSTVAL);

                -- Change the validations package to the appropriate package name
                -- Modify the parameters as required
                -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
                -- PRE_VALIDATIONS SHOULD BE RETAINED
                x_error_code := xx_ont_itemord_val_pkg.post_validations ();
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
                mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);
                xx_emf_pkg.propagate_error ( x_error_code);

                  */
        -- Perform data derivations and process data only if p_validate_only_flag is set to VALIDATE_AND_LOAD
        IF p_validate_and_load = G_VALIDATE_AND_LOAD THEN

                      set_stage (xx_emf_cn_pkg.CN_POSTVAL);
                      x_error_code := xx_ont_itemord_val_pkg.post_validations ();
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
                mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);
                xx_emf_pkg.propagate_error ( x_error_code);


            -- Set the stage to Pre Validations
            set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Before Process Data');
            --x_error_code := process_data ( p_parameter_1, p_parameter_2, p_parameter_3);
            x_error_code := process_data ();
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After Process Data');
            mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After Process Data mark_records_complete x_error_code'||x_error_code);

            xx_emf_pkg.propagate_error ( x_error_code);
        END IF; --for validate only flag check

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
                        retcode := xx_emf_cn_pkg.CN_REC_ERR;
            update_record_count;
                        xx_emf_pkg.create_report;
                WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
                        retcode := xx_emf_cn_pkg.CN_PRC_ERR;
            update_record_count;
                        xx_emf_pkg.create_report;
                WHEN OTHERS THEN
                        retcode := xx_emf_cn_pkg.CN_PRC_ERR;
            update_record_count;
                        xx_emf_pkg.create_report;
        END main;
END xx_ont_custitemorder_pkg; 
/
