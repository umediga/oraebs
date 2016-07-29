DROP PACKAGE BODY APPS.XX_INV_ITEMCATASSIGN_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_ITEMCATASSIGN_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development Team
 Creation Date  : 23-MAR-2012
 File Name      : XXINVITEMCATASSIGNTL.pkb
 Description    : This script creates the body of the package xx_inv_itemcatassign_pkg

COMMON GUIDELINES REGARDING EMF
-------------------------------

1. ALL LOW LEVEL EMF MESSAGES CAN BE RETAINED
2. HARD CODING OF EMF MESSAGES ARE ALLOWED IN THE CODE
3. ANY OTHER HARD CODING SHOULD BE DEALT BY CONSTANTS PACKAGE
4. EXCEPTION HANDLING SHOULD BE LEFT AS IS MOST OF THE PLACES UNLESS SPECIFIED

 Change History:

Version Date        Name		    Remarks
------- ----------- ------------	    ---------------------------------------
1.0     28-MAR-2012 IBM Development Team    Initial development.
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

        PROCEDURE mark_records_for_processing
        (
                p_restart_flag IN VARCHAR2,
                p_override_flag IN VARCHAR2
        ) IS
                PRAGMA AUTONOMOUS_TRANSACTION;

        BEGIN

        fnd_file.PUT_LINE ( fnd_file.log, 'When Others Exception...');
                -- If the override is set records should not be purged from the pre-interface tables
                IF p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS THEN

                        IF p_override_flag = xx_emf_cn_pkg.CN_NO THEN
                                -- purge from pre-interface tables and oracle standard tables
                                DELETE FROM xx_inv_item_categories_pre
                                 WHERE batch_id = G_BATCH_ID;

                                UPDATE xx_inv_item_categories_stg
                                   SET request_id = xx_emf_pkg.G_REQUEST_ID,
                                       error_code = xx_emf_cn_pkg.CN_NULL,
                                       process_code = xx_emf_cn_pkg.CN_NEW
                                 WHERE batch_id = G_BATCH_ID;

                                 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No of Records updated for processing=>'||SQL%ROWCOUNT);
                        ELSE
                                UPDATE xx_inv_item_categories_pre
                                   SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                                       error_code = xx_emf_cn_pkg.CN_SUCCESS,
                                       request_id = xx_emf_pkg.G_REQUEST_ID
                                 WHERE batch_id = G_BATCH_ID;
                        END IF;

                        --DELETE FROM mtl_item_categories_interface
                        -- WHERE attribute1 = G_BATCH_ID;

                ELSIF p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS THEN

                        IF p_override_flag = xx_emf_cn_pkg.CN_NO THEN

                                -- Update staging table
                                UPDATE xx_inv_item_categories_stg
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
                        UPDATE xx_inv_item_categories_stg a
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_NULL,
                               process_code = xx_emf_cn_pkg.CN_NEW
                         WHERE batch_id = G_BATCH_ID
                           AND EXISTS (
                                SELECT 1
                                  FROM xx_inv_item_categories_pre
                                 WHERE batch_id = G_BATCH_ID
                                   AND process_code = xx_emf_cn_pkg.CN_PREVAL
                                   AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                                   AND record_number = a.record_number);

                        DELETE
                          FROM xx_inv_item_categories_pre
                         WHERE batch_id = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_PREVAL
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                        -- Scenario 2 Data Validation Stage
                        UPDATE xx_inv_item_categories_pre
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               process_code = xx_emf_cn_pkg.CN_PREVAL
                         WHERE batch_id = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_VALID
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                        -- Scenario 3 Data Derivation Stage
                        UPDATE xx_inv_item_categories_pre
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               process_code = xx_emf_cn_pkg.CN_DERIVE
                         WHERE batch_id = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_DERIVE
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                        -- Scenario 4 Post Validation Stage
                        UPDATE xx_inv_item_categories_pre
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               process_code = xx_emf_cn_pkg.CN_POSTVAL
                         WHERE batch_id = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_POSTVAL
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                        -- Scenario 5 Process Data Stage
                        UPDATE xx_inv_item_categories_pre
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               process_code = xx_emf_cn_pkg.CN_POSTVAL
                         WHERE batch_id = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_ERR);

                END IF;
                COMMIT;
        END;

        PROCEDURE set_stage (p_stage VARCHAR2)
        IS
        BEGIN
                G_STAGE := p_stage;
        END set_stage;

        PROCEDURE update_staging_records( p_error_code VARCHAR2) IS
                x_last_update_date       DATE := SYSDATE;
                x_last_updated_by        NUMBER := fnd_global.user_id;
                x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

                PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'update_staging_records for G_BATCH_ID='||G_BATCH_ID||' G_STAGE = '||G_STAGE);

                UPDATE xx_inv_item_categories_stg
                   SET process_code = G_STAGE,
                       error_code = DECODE ( error_code, NULL, p_error_code, error_code),
                       last_update_date = x_last_update_date,
                       last_updated_by = x_last_updated_by,
                       last_update_login = x_last_update_login
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
		p_validate_and_load IN VARCHAR2,
                p_transaction_type IN VARCHAR2
        ) IS
                x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
                x_pre_std_hdr_table G_XX_INV_ITEMCAT_PRE_TAB_TYPE;


                -- CURSOR FOR VARIOUS STAGES
                CURSOR c_xx_intg_pre_std_hdr ( cp_process_status VARCHAR2) IS
                SELECT
                      batch_id
                      ,record_number
                      ,inventory_item_number
                      ,organization_code
                      ,category_set_name
                      ,category_name
                      ,transaction_type
                      --,old_category_name
                      ,set_process_id
                      ,inventory_item_id
                      ,organization_id
                      ,category_id
                      ,category_set_id
                      --,old_category_id
                      ,process_code
                      ,error_code
                      ,request_id
                  FROM xx_inv_item_categories_pre hdr
                 WHERE batch_id = G_BATCH_ID
                   AND request_id = xx_emf_pkg.G_REQUEST_ID
                   AND process_code = cp_process_status
                   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                 ORDER BY record_number;

                PROCEDURE update_record_status (
                        p_conv_pre_std_hdr_rec  IN OUT  G_XX_INV_ITEMCAT_PRE_REC_TYPE,
                        p_error_code            IN      VARCHAR2
                )
                IS
                BEGIN

                        IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
                        THEN
                                p_conv_pre_std_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                        ELSE
                                p_conv_pre_std_hdr_rec.error_code := xx_intg_common_pkg.find_max (p_error_code, NVL (p_conv_pre_std_hdr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));
                        END IF;

                        p_conv_pre_std_hdr_rec.process_code := G_STAGE;
                END update_record_status;

                PROCEDURE mark_records_complete
                (
                        p_process_code VARCHAR2
                )
                IS
                        x_last_update_date       DATE := SYSDATE;
                        x_last_updated_by        NUMBER := fnd_global.user_id;
                        x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

                        PRAGMA AUTONOMOUS_TRANSACTION;
                BEGIN
                        UPDATE xx_inv_item_categories_pre
                           SET process_code = G_STAGE,
                               error_code = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
                               last_updated_by = x_last_updated_by,
                               last_update_date = x_last_update_date,
                               last_update_login = x_last_update_login
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
                           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

                        COMMIT;
                END mark_records_complete;

                PROCEDURE update_pre_interface_records (p_cnv_pre_std_hdr_table IN G_XX_INV_ITEMCAT_PRE_TAB_TYPE)
                IS
                        x_last_update_date      DATE := SYSDATE;
                        x_last_updated_by       NUMBER := fnd_global.user_id;
                        x_last_update_login     NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

                        PRAGMA AUTONOMOUS_TRANSACTION;
                BEGIN

                        FOR indx IN 1 .. p_cnv_pre_std_hdr_table.COUNT LOOP
                                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).process_code ' || p_cnv_pre_std_hdr_table(indx).process_code);
                                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).error_code ' || p_cnv_pre_std_hdr_table(indx).error_code);
                                UPDATE xx_inv_item_categories_pre
                                   SET  inventory_item_number = p_cnv_pre_std_hdr_table(indx).inventory_item_number,
                                        organization_code     = p_cnv_pre_std_hdr_table(indx).organization_code,
                                        category_set_name     = p_cnv_pre_std_hdr_table(indx).category_set_name,
                                        category_name         = p_cnv_pre_std_hdr_table(indx).category_name,
                                        transaction_type      = p_cnv_pre_std_hdr_table(indx).transaction_type,
                                        set_process_id        = p_cnv_pre_std_hdr_table(indx).set_process_id ,
                                        inventory_item_id     = p_cnv_pre_std_hdr_table(indx).inventory_item_id,
                                        organization_id       = p_cnv_pre_std_hdr_table(indx).organization_id,
                                        category_id           = p_cnv_pre_std_hdr_table(indx).category_id,
                                        category_set_id       = p_cnv_pre_std_hdr_table(indx).category_set_id,
                                        --old_category_name     = p_cnv_pre_std_hdr_table(indx).old_category_name,
                                        --old_category_id       = p_cnv_pre_std_hdr_table(indx).old_category_id,
                                        process_code          = p_cnv_pre_std_hdr_table(indx).process_code,
                                        error_code            = p_cnv_pre_std_hdr_table(indx).error_code,
                                        last_updated_by        = x_last_updated_by,
                                        last_update_date      = x_last_update_date,
                                        last_update_login    = x_last_update_login
                                 WHERE record_number = p_cnv_pre_std_hdr_table(indx).record_number;
                        END LOOP;

                        COMMIT;
                END update_pre_interface_records;

                FUNCTION move_rec_pre_standard_table RETURN NUMBER
                IS
                        x_creation_date         DATE := SYSDATE;
                        x_created_by            NUMBER := fnd_global.user_id;
                        x_last_update_date      DATE := SYSDATE;
                        x_last_updated_by        NUMBER := fnd_global.user_id;
                        x_last_update_login      NUMBER := fnd_profile.value(xx_emf_cn_pkg.CN_LOGIN_ID);
                       -- x_cnv_pre_std_hdr_table G_XX_INV_ITEMCAT_PRE_TAB_TYPE := G_XX_INV_ITEMCAT_PRE_TAB_TYPE();
                       -- x_cnv_pre_std_hdr_table XX_INTG_CNV_PRE_STD_TAB_TYPE := XX_INTG_CNV_PRE_STD_TAB_TYPE();


                        x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

                        PRAGMA AUTONOMOUS_TRANSACTION;

                BEGIN
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside move_rec_pre_standard_table');

                        -- CCID099 changes
                        -- Select only the appropriate columns that are required to be inserted into the
                        -- Pre-Interface Table and insert from the Staging Table
                        INSERT INTO xx_inv_item_categories_pre
                        (
                                batch_id,
                                record_number,
                                inventory_item_number,
                                organization_code,
                                category_set_name,
                                category_name,
                                transaction_type,
                                set_process_id,
                                --old_category_name,
                                process_code,           --- DO NOT CHANGE FROM THIS LINE TILL MENTIONED LINE
                                error_code,
                                request_id,
                                created_by,
                                creation_date,
                                last_updated_by,
                                last_update_date,
                                last_update_login      -- DO NOT CHANGE TO THIS LINE
                        )
                        SELECT batch_id,
                                record_number,
                                inventory_item_number,
                                organization_code,
                                category_set_name,
                                category_name,
                                decode(G_TRANSACTION_TYPE, 'CREATE / UPDATE', 'C', 'D'),
                                set_process_id,
                                --old_category_name,
                                G_STAGE,                --- DO NOT CHANGE FROM THIS LINE TILL MENTIONED LINE
                                error_code,                     --- DO NOT CHANGE THIS LINE
                                request_id,
                                x_created_by,
                                x_creation_date,
                                x_last_updated_by,
                                x_last_update_date,
                                x_last_update_login    -- DO NOT CHANGE TO THIS LINE
                          FROM xx_inv_item_categories_stg
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

                PROCEDURE mark_records_for_api_error
                (
                        p_process_code       IN VARCHAR2
                       ,p_record_number	     IN NUMBER
                )
                IS
                        x_last_update_date       DATE := SYSDATE;
                        x_last_updated_by        NUMBER := fnd_global.user_id;
                        x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
                BEGIN
                        UPDATE xx_inv_item_categories_pre
                           SET process_code = G_STAGE,
                               error_code = xx_emf_cn_pkg.CN_REC_ERR,
                               last_updated_by = x_last_updated_by,
                               last_update_date = x_last_update_date,
                               last_update_login = x_last_update_login
                         WHERE request_id      = xx_emf_pkg.G_REQUEST_ID
                           AND record_number   = p_record_number
                           AND batch_id        = G_BATCH_ID
                           AND process_code    = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
                                                           , xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE
                                                           )
                           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                           ;
                END mark_records_for_api_error;


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
		    x_batch_commit	NUMBER :=0;
		    x_multi_cat_assgn_flag  CHAR(1);

               CURSOR cur_itemcatassign
               IS
               SELECT *
                 FROM xx_inv_item_categories_pre
                     WHERE batch_id = G_BATCH_ID
                       AND request_id = xx_emf_pkg.G_REQUEST_ID
                       AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                       AND process_code = xx_emf_cn_pkg.CN_POSTVAL;
                BEGIN
                    -- CCID099 changes
                    -- Change the logic to whatever needs to be done
                    -- with valid records in the pre-interface tables
                    -- either call the appropriate API to process the data
                    -- or to insert into an interface table


                    FOR cur_rec IN cur_itemcatassign
                    LOOP
			xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'1 =>');
			x_batch_commit := x_batch_commit + 1;

                        x_category_id       := cur_rec.category_id;
                        x_category_set_id   := cur_rec.category_set_id;
                        x_inventory_item_id := cur_rec.inventory_item_id;
                        x_organization_id   := cur_rec.organization_id;
                        n_assign_exist      := 0;

			SELECT mult_item_cat_assign_flag
			  INTO x_multi_cat_assgn_flag
			  FROM mtl_category_sets
			 WHERE category_set_id = x_category_set_id;

			xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'x_multi_cat_assgn_flag =>'|| x_multi_cat_assgn_flag);

                        n_assign_exist      := xx_inv_itemcatassign_val_pkg.checkassignmentexistence
                                                                         (p_organization_id   => x_organization_id,
                                                                          p_inventory_item_id => x_inventory_item_id,
                                                                          p_category_set_id   => x_category_set_id,
                                                                          p_category_id       => x_category_id
                                                                          );

                        x_old_category_id   := xx_inv_itemcatassign_val_pkg.checksetassignment
									 (p_organization_id   => x_organization_id,
									  p_inventory_item_id => x_inventory_item_id,
									  p_category_set_id   => x_category_set_id,
									  p_category_id       => x_category_id
									  );

			xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'2 =>');


			--reset the status flag--
			v_return_status := 'S';

			FND_MSG_PUB.INITIALIZE;

			-- Adding condition for accomodating iStore and P2M processes in separate flows
			IF x_multi_cat_assgn_flag = 'Y' THEN -- For iStore

			    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'iStore Flow =>');

			   IF (x_old_category_id > 0 AND n_assign_exist = 0) AND G_TRANSACTION_TYPE = 'CREATE / UPDATE' -- Scenario of Create
			   THEN
				  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Category Assignment Found Updating =>'||x_old_category_id);

				  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'3A =>');

				  INV_ITEM_CATEGORY_PUB.Create_Category_Assignment
				  (
				    p_api_version       => x_api_version,
				    p_init_msg_list     => x_init_msg_list,
				    p_commit            => x_commit,
				    x_return_status     => v_return_status,
				    x_errorcode         => v_errorcode,
				    x_msg_count         => n_msg_count,
				    x_msg_data          => v_msg_data,
				    p_category_id       => x_category_id,
				    p_category_set_id   => x_category_set_id,
				    p_inventory_item_id => x_inventory_item_id,
				    p_organization_id   => x_organization_id
				  );

			      IF v_return_status = 'S'
			      THEN
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Category Assignment Updated => Success=>'||v_return_status);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Record Number     =>'||cur_rec.record_number);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Orgnization Name  =>'||cur_rec.organization_code);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Legacy Item Number=>'||cur_rec.inventory_item_number);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Category Set Name =>'||cur_rec.category_set_name);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'New Category Name =>'||cur_rec.category_name);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Old Category Id   =>'||x_old_category_id);
			      END IF;

			   ELSIF (n_assign_exist > 0) AND G_TRANSACTION_TYPE = 'CREATE / UPDATE'  -- Scenario of Update
			   THEN
				  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Category Assignment Found Updating =>'||x_old_category_id);

				  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'3B =>');

				  INV_ITEM_CATEGORY_PUB.Update_Category_Assignment
				  (
				    p_api_version       => x_api_version,
				    p_init_msg_list     => x_init_msg_list,
				    p_commit            => x_commit,
				    p_old_category_id   => x_old_category_id,
				    p_category_id       => x_category_id,
				    p_category_set_id   => x_category_set_id,
				    p_inventory_item_id => x_inventory_item_id,
				    p_organization_id   => x_organization_id,
				    x_return_status     => v_return_status,
				    x_errorcode         => v_errorcode,
				    x_msg_count         => n_msg_count,
				    x_msg_data          => v_msg_data
				   );

			      IF v_return_status = 'S'
			      THEN
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Category Assignment Updated => Success=>'||v_return_status);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Record Number     =>'||cur_rec.record_number);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Orgnization Name  =>'||cur_rec.organization_code);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Legacy Item Number=>'||cur_rec.inventory_item_number);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Category Set Name =>'||cur_rec.category_set_name);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'New Category Name =>'||cur_rec.category_name);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Old Category Id   =>'||x_old_category_id);
			      END IF;
			   ELSIF v_return_status = 'S' AND G_TRANSACTION_TYPE = 'CREATE / UPDATE'  -- Scenario of Create
				 AND n_assign_exist = 0 AND x_old_category_id = 0
			   THEN
				xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'4 =>');
			      INV_ITEM_CATEGORY_PUB.Create_Category_Assignment
			      (
			       p_api_version       => x_api_version,
			       p_init_msg_list     => x_init_msg_list,
			       p_commit            => x_commit,
			       x_return_status     => v_return_status,
			       x_errorcode         => v_errorcode,
			       x_msg_count         => n_msg_count,
			       x_msg_data          => v_msg_data,
			       p_category_id       => x_category_id,
			       p_category_set_id   => x_category_set_id,
			       p_inventory_item_id => x_inventory_item_id,
			       p_organization_id   => x_organization_id
			      );

			      IF v_return_status NOT IN ('E','U')
			      THEN
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Category Assignment Created => Success=>'||v_return_status);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Record Number     =>'||cur_rec.record_number);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Orgnization Name  =>'||cur_rec.organization_code);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Legacy Item Number=>'||cur_rec.inventory_item_number);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Category Set Name =>'||cur_rec.category_set_name);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Category Name     =>'||cur_rec.category_name);
			      END IF;
			   ELSIF v_return_status = 'S' AND G_TRANSACTION_TYPE = 'DELETE'  -- Scenario of Delete
				 AND x_old_category_id > 0 AND n_assign_exist > 0
			   THEN
				xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'5 =>');
			      INV_ITEM_CATEGORY_PUB.Delete_Category_Assignment
			      (
			       p_api_version       => x_api_version,
			       p_init_msg_list     => x_init_msg_list,
			       p_commit            => x_commit,
			       x_return_status     => v_return_status,
			       x_errorcode         => v_errorcode,
			       x_msg_count         => n_msg_count,
			       x_msg_data          => v_msg_data,
			       p_category_id       => x_category_id,
			       p_category_set_id   => x_category_set_id,
			       p_inventory_item_id => x_inventory_item_id,
			       p_organization_id   => x_organization_id
			      );

			      IF v_return_status NOT IN ('E','U')
			      THEN
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Category Assignment Deleted => Success=>'||v_return_status);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Record Number     =>'||cur_rec.record_number);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Orgnization Name  =>'||cur_rec.organization_code);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Legacy Item Number=>'||cur_rec.inventory_item_number);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Category Set Name =>'||cur_rec.category_set_name);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Category Name     =>'||cur_rec.category_name);
			      END IF;
			   END IF;

			   IF v_return_status IN ('E','U')
			   THEN
			       FOR i IN 1 .. n_msg_count
			       LOOP
				  fnd_msg_pub.get (p_msg_index          => i,
						   p_encoded            => 'F',
						   p_data               => v_msg_data,
						   p_msg_index_out      => l_out_index
						   );
				  xx_emf_pkg.error (p_severity             => xx_emf_cn_pkg.CN_MEDIUM
						    ,p_category            => xx_emf_cn_pkg.CN_STG_APICALL
						    ,p_error_text          => v_msg_data
						    ,p_record_identifier_1 => cur_rec.record_number
						    ,p_record_identifier_2 => cur_rec.organization_code
						    ,p_record_identifier_3 => cur_rec.inventory_item_number
						   );
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg =>'||v_msg_data);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Code =>'||v_errorcode);
			      END LOOP;
			      mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA
							,cur_rec.record_number
							);
			   ELSE
			      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Category Assignment => Success'||v_return_status);
			   END IF;

			ELSE -- For P2M track

			    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'P2M Flow =>');

			   IF (x_old_category_id > 0 AND n_assign_exist = 0)
			   THEN
				  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Category Assignment Found Updating =>'||x_old_category_id);

				  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'3 =>');

				  INV_ITEM_CATEGORY_PUB.Update_Category_Assignment
				  (
				    p_api_version       => x_api_version,
				    p_init_msg_list     => x_init_msg_list,
				    p_commit            => x_commit,
				    p_old_category_id   => x_old_category_id,
				    p_category_id       => x_category_id,
				    p_category_set_id   => x_category_set_id,
				    p_inventory_item_id => x_inventory_item_id,
				    p_organization_id   => x_organization_id,
				    x_return_status     => v_return_status,
				    x_errorcode         => v_errorcode,
				    x_msg_count         => n_msg_count,
				    x_msg_data          => v_msg_data
				   );
			      IF v_return_status = 'S'
			      THEN
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Category Assignment Updated => Success=>'||v_return_status);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Record Number     =>'||cur_rec.record_number);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Orgnization Name  =>'||cur_rec.organization_code);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Legacy Item Number=>'||cur_rec.inventory_item_number);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Category Set Name =>'||cur_rec.category_set_name);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'New Category Name =>'||cur_rec.category_name);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Old Category Id   =>'||x_old_category_id);
			      END IF;
			   ELSIF v_return_status = 'S' AND G_TRANSACTION_TYPE = 'CREATE / UPDATE'
				 AND n_assign_exist = 0 AND x_old_category_id = 0
			   THEN
				xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'4 =>');
			      INV_ITEM_CATEGORY_PUB.Create_Category_Assignment
			      (
			       p_api_version       => x_api_version,
			       p_init_msg_list     => x_init_msg_list,
			       p_commit            => x_commit,
			       x_return_status     => v_return_status,
			       x_errorcode         => v_errorcode,
			       x_msg_count         => n_msg_count,
			       x_msg_data          => v_msg_data,
			       p_category_id       => x_category_id,
			       p_category_set_id   => x_category_set_id,
			       p_inventory_item_id => x_inventory_item_id,
			       p_organization_id   => x_organization_id
			      );

			      IF v_return_status NOT IN ('E','U')
			      THEN
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Category Assignment Created => Success=>'||v_return_status);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Record Number     =>'||cur_rec.record_number);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Orgnization Name  =>'||cur_rec.organization_code);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Legacy Item Number=>'||cur_rec.inventory_item_number);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Category Set Name =>'||cur_rec.category_set_name);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Category Name     =>'||cur_rec.category_name);
			      END IF;
			   ELSIF v_return_status = 'S' AND G_TRANSACTION_TYPE = 'DELETE'
				 AND x_old_category_id > 0 AND n_assign_exist > 0
			   THEN
				xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'5 =>');
			      INV_ITEM_CATEGORY_PUB.Delete_Category_Assignment
			      (
			       p_api_version       => x_api_version,
			       p_init_msg_list     => x_init_msg_list,
			       p_commit            => x_commit,
			       x_return_status     => v_return_status,
			       x_errorcode         => v_errorcode,
			       x_msg_count         => n_msg_count,
			       x_msg_data          => v_msg_data,
			       p_category_id       => x_category_id,
			       p_category_set_id   => x_category_set_id,
			       p_inventory_item_id => x_inventory_item_id,
			       p_organization_id   => x_organization_id
			      );

			      IF v_return_status NOT IN ('E','U')
			      THEN
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Category Assignment Deleted => Success=>'||v_return_status);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Record Number     =>'||cur_rec.record_number);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Orgnization Name  =>'||cur_rec.organization_code);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Legacy Item Number=>'||cur_rec.inventory_item_number);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Category Set Name =>'||cur_rec.category_set_name);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Category Name     =>'||cur_rec.category_name);
			      END IF;

			   END IF;

			   IF v_return_status IN ('E','U')
			   THEN
			       FOR i IN 1 .. n_msg_count
			       LOOP
				  fnd_msg_pub.get (p_msg_index          => i,
						   p_encoded            => 'F',
						   p_data               => v_msg_data,
						   p_msg_index_out      => l_out_index
						   );
				  xx_emf_pkg.error (p_severity             => xx_emf_cn_pkg.CN_MEDIUM
						    ,p_category            => xx_emf_cn_pkg.CN_STG_APICALL
						    ,p_error_text          => v_msg_data
						    ,p_record_identifier_1 => cur_rec.record_number
						    ,p_record_identifier_2 => cur_rec.organization_code
						    ,p_record_identifier_3 => cur_rec.inventory_item_number
						   );
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Msg =>'||v_msg_data);
				 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Code =>'||v_errorcode);
			      END LOOP;
			      mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA
							,cur_rec.record_number
							);
			   ELSE
			      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Category Assignment => Success'||v_return_status);
			   END IF;

			END IF;


			IF x_batch_commit >= 10000 THEN -- Commit for every 10000 record as per review comment
			    COMMIT;
			END IF;
                     END LOOP;
                     COMMIT;
                    RETURN x_return_status;
                END process_data;

                PROCEDURE update_record_count
                IS

                        CURSOR c_get_total_cnt IS
                        SELECT COUNT (1) total_count
                          FROM xx_inv_item_categories_stg
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID;

                        x_total_cnt NUMBER;

                        CURSOR c_get_error_cnt IS
                        SELECT SUM(error_count)
                          FROm (SELECT COUNT (1) error_count
                          FROM xx_inv_item_categories_stg
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND error_code = xx_emf_cn_pkg.CN_REC_ERR
                        UNION ALL
                        SELECT COUNT (1) error_count
                          FROM xx_inv_item_categories_pre
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

                        x_error_cnt NUMBER;

                        CURSOR c_get_warning_cnt IS
                        SELECT COUNT (1) warn_count
                          FROM xx_inv_item_categories_pre
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

                        x_warn_cnt NUMBER;

                        CURSOR c_get_success_cnt IS
                        SELECT COUNT (1) warn_count
                          FROM xx_inv_item_categories_pre
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
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
		G_TRANSACTION_TYPE := p_transaction_type;
/*
	-- Need to maintain the version on the files.
                -- when updating the package remember to incrimint the version such that it can be checked in the log file from front end.
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,CN_XXASLCNVVL_PKS);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,CN_XXASLCNVVL_PKB);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,CN_XXASLCNVTL_PKS);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,CN_XXASLCNVTL_PKB);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,CN_XXASLCNVT1_TBL);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,CN_XXASLCNVT1_SYN);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,CN_XXASLCNVT2_TBL);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,CN_XXASLCNVT2_SYN);
*/
		fnd_file.PUT_LINE ( fnd_file.output, 'When Others Exception...0');
                -- Start CCID099 changes
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
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_validate_and_load '	|| p_validate_and_load);
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_transaction_type '	|| p_transaction_type);
                -- End CCID099 changes

                -- Call procedure to update records with the current request_id
                -- So that we can process only those records
                -- This gives a better handling of restartability
                mark_records_for_processing(p_restart_flag => p_restart_flag, p_override_flag => p_override_flag);

                -- Once the records are identified based on the input parameters
                -- Start with pre-validations
                IF NVL ( p_override_flag, xx_emf_cn_pkg.CN_NO) = xx_emf_cn_pkg.CN_NO THEN
                        -- Set the stage to Pre Validations
                        set_stage (xx_emf_cn_pkg.CN_PREVAL);

                        -- CCID099 changes
                        -- Change the validations package to the appropriate package name
                        -- Modify the parameters as required
                        -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
                        -- PRE_VALIDATIONS SHOULD BE RETAINED
                        /*x_error_code := xx_inv_itemcatassign_val_pkg.pre_validations (
                                                p_parameter_1,
                                                p_parameter_2,
                                                p_parameter_3
                                                );*/
                        x_error_code := xx_inv_itemcatassign_val_pkg.pre_validations ();
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
                                        x_error_code := xx_inv_itemcatassign_val_pkg.data_validations (
                                                                x_pre_std_hdr_table (i));
                                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_hdr_table (i).record_number|| ' is ' || x_error_code);

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
                                                xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_hdr_table (i).record_number);
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
                                        x_error_code := xx_inv_itemcatassign_val_pkg.data_derivations (
                                                                x_pre_std_hdr_table (i));
                                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_hdr_table (i).record_number|| ' is ' || x_error_code);

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
                                                xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_hdr_table (i).record_number);
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
                set_stage (xx_emf_cn_pkg.CN_POSTVAL);

                -- CCID099 changes
                -- Change the validations package to the appropriate package name
                -- Modify the parameters as required
                -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
                -- PRE_VALIDATIONS SHOULD BE RETAINED
                x_error_code := xx_inv_itemcatassign_val_pkg.post_validations ();
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
                mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);
                xx_emf_pkg.propagate_error ( x_error_code);


		-- Perform data derivations and process data only if p_validate_only_flag is set to VALIDATE_AND_LOAD
		IF p_validate_and_load = G_VALIDATE_AND_LOAD THEN
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
                        xx_emf_pkg.create_report;
                WHEN xx_emf_pkg.G_E_REC_ERROR THEN
                        retcode := xx_emf_cn_pkg.CN_REC_ERR;
                        xx_emf_pkg.create_report;
                WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
                        retcode := xx_emf_cn_pkg.CN_PRC_ERR;
                        xx_emf_pkg.create_report;
                WHEN OTHERS THEN
                        retcode := xx_emf_cn_pkg.CN_PRC_ERR;
                        xx_emf_pkg.create_report;
        END main;
END xx_inv_itemcatassign_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_ITEMCATASSIGN_PKG TO INTG_XX_NONHR_RO;
