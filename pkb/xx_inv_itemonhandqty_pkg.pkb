DROP PACKAGE BODY APPS.XX_INV_ITEMONHANDQTY_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_ITEMONHANDQTY_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development Team
 Creation Date  : 24-Feb-2012
 File Name      : XXINVITEMONHANDTL.pkb
 Description    : This script creates the body of the package xx_inv_itemonhandqty_pkg

COMMON GUIDELINES REGARDING EMF
-------------------------------

1. ALL LOW LEVEL EMF MESSAGES CAN BE RETAINED
2. HARD CODING OF EMF MESSAGES ARE ALLOWED IN THE CODE
3. ANY OTHER HARD CODING SHOULD BE DEALT BY CONSTANTS PACKAGE
4. EXCEPTION HANDLING SHOULD BE LEFT AS IS MOST OF THE PLACES UNLESS SPECIFIED

 Change History:

Version Date        Name        Remarks
------- ----------- ---------        ------------------------------------------------------------------------
1.0     24-Feb-2012 Mou Mukherjee        Initial development.
1.1     22-MAR-2012 Mou Mukherjee        Included the extra fields as per new data mapping
1.2     19-JUN-2013 Mou Mukherjee	 Added source_system_name - wave1
1.3     11-SEP-2013 Mou Mukherjee        Added place of origin 
1.4     27-JAN-2014 Mou Mukherjee	Populating 'Comp Source Country' in Attribute_Category field - wave1
-------------------------------------------------------------------------------------------------------------
*/

   -- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
   -- START RESTRICTIONS
   PROCEDURE set_cnv_env (
      p_batch_id        VARCHAR2,
      p_required_flag   VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_yes
   )
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      g_batch_id := p_batch_id;
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

-------------------------------------------------------------------------
-----------< mark_records_for_processing >-------------------------------
-------------------------------------------------------------------------
   PROCEDURE mark_records_for_processing (
      p_restart_flag    IN   VARCHAR2,
      p_override_flag   IN   VARCHAR2
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               '1 : '
                            || p_restart_flag
                            || ' - '
                            || xx_emf_cn_pkg.cn_all_recs
                            || ' - '
                            || p_override_flag
                            || ' - '
                            || xx_emf_cn_pkg.cn_no
                           );

      -- If the override is set records should not be purged from the pre-interface tables
      IF p_restart_flag = xx_emf_cn_pkg.cn_all_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- purge from pre-interface tables and oracle standard tables
            DELETE FROM xx_mtl_transactions_pre
                  WHERE batch_id = g_batch_id;

            UPDATE xx_mtl_transactions_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id;
         ELSE
            UPDATE xx_mtl_transactions_pre
               SET process_code = xx_emf_cn_pkg.cn_preval,
                   ERROR_CODE = xx_emf_cn_pkg.cn_success,
                   request_id = xx_emf_pkg.g_request_id
             WHERE batch_id = g_batch_id;
         END IF;

         DELETE FROM mtl_transactions_interface
               WHERE attribute1 = g_batch_id;

         DELETE FROM mtl_transaction_lots_interface
               WHERE attribute1 = g_batch_id;

         DELETE FROM mtl_serial_numbers_interface
               WHERE attribute1 = g_batch_id;
      ELSIF p_restart_flag = xx_emf_cn_pkg.cn_err_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- Update staging table
            UPDATE xx_mtl_transactions_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id
               AND (   process_code = xx_emf_cn_pkg.cn_new
                    OR (    process_code = xx_emf_cn_pkg.cn_preval
                        AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_rec_err) IN
                               (xx_emf_cn_pkg.cn_rec_warn,
                                xx_emf_cn_pkg.cn_rec_err
                               )
                       )
                   );
         END IF;

         -- Update pre-interface table
         -- Scenario 1 Pre-Validation Stage
         UPDATE xx_mtl_transactions_stg a
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new
          WHERE batch_id = g_batch_id
            AND EXISTS (
                   SELECT 1
                     FROM xx_mtl_transactions_pre
                    WHERE batch_id = g_batch_id
                      AND process_code = xx_emf_cn_pkg.cn_preval
                      AND ERROR_CODE IN
                             (xx_emf_cn_pkg.cn_null,
                              xx_emf_cn_pkg.cn_rec_warn,
                              xx_emf_cn_pkg.cn_rec_err
                             )
                      AND record_number = a.record_number);

         DELETE FROM xx_mtl_transactions_pre
               WHERE batch_id = g_batch_id
                 AND process_code = xx_emf_cn_pkg.cn_preval
                 AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_null,
                         xx_emf_cn_pkg.cn_rec_warn,
                         xx_emf_cn_pkg.cn_rec_err
                        );

         -- Scenario 2 Data Validation Stage
         UPDATE xx_mtl_transactions_pre
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_preval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_valid
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 3 Data Derivation Stage
         UPDATE xx_mtl_transactions_pre
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_derive
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_derive
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 4 Post Validation Stage
         UPDATE xx_mtl_transactions_pre
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_postval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_postval
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 5 Process Data Stage
         UPDATE xx_mtl_transactions_pre
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_postval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_process_data
            AND ERROR_CODE IN
                            (xx_emf_cn_pkg.cn_null, xx_emf_cn_pkg.cn_rec_err);
      END IF;

      COMMIT;
   END;

   -------------------------------------------------------------------------
   -----------< assign_global_var >-------------------------------
   -------------------------------------------------------------------------
   PROCEDURE assign_global_var
   IS
       -- cursor to fetch the global variables.
      CURSOR cur_get_global_var_value(p_parameter IN VARCHAR2)
      IS
      SELECT emfpp.parameter_value
        FROM xx_emf_process_setup emfps,
             xx_emf_process_parameters emfpp
       WHERE emfps.process_id=emfpp.process_id
         AND emfps.process_name=g_process_name
         AND emfpp.parameter_name=p_parameter;
      l_parameter_name   VARCHAR2(60);
      l_parameter_value  VARCHAR2(60);
   BEGIN
      --Set Process Flag
      OPEN cur_get_global_var_value('PROCESS_FLAG');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_PROCESS_FLAG := l_parameter_value;
      --Set Transaction Mode
      OPEN cur_get_global_var_value('TRANSACTION_MODE');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_TRANS_MODE := l_parameter_value;
      --Set Status Name
      OPEN cur_get_global_var_value('STATUS_NAME');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_STATUS_NAME := l_parameter_value;
      --Set Status Id
      OPEN cur_get_global_var_value('STATUS_ID');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_STATUS_ID := l_parameter_value;
      --Set Source Code
      OPEN cur_get_global_var_value('SOURCE_CODE');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_SOURCE_CODE := l_parameter_value;
      --Set Transaction source name
      OPEN cur_get_global_var_value('TRANSACTION_SOURCE_NAME');  -- 16th-AUG-12
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_TRANS_SOURCE_NAME := l_parameter_value;
      --Set Attribute Category    -- 27th-Jan-14
      OPEN cur_get_global_var_value('ATTRIBUTE_CATEGORY'); 
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_ATTRIBUTE_CAT := l_parameter_value;
      CLOSE cur_get_global_var_value;
      IF G_PROCESS_FLAG IS NULL OR  G_TRANS_MODE IS NULL OR G_STATUS_NAME IS NULL OR
	       G_STATUS_ID IS NULL OR G_SOURCE_CODE IS NULL OR G_TRANS_SOURCE_NAME IS NULL OR G_ATTRIBUTE_CAT IS NULL --16th-AUG-12
      THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                , 'Global Variables are not set properly'
                               );
      END IF;
   EXCEPTION
     WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                , 'Global Variables are not set properly'
                               );
   END assign_global_var;
-------------------------------------------------------------------------
-----------< set_stage >-------------------------------
-------------------------------------------------------------------------
   PROCEDURE set_stage (p_stage VARCHAR2)
   IS
   BEGIN
      g_stage := p_stage;
   END set_stage;

-------------------------------------------------------------------------
-----------< update_staging_records >-------------------------------
-------------------------------------------------------------------------

   PROCEDURE update_staging_records (p_error_code VARCHAR2)
   IS
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE xx_mtl_transactions_stg
         SET process_code = g_stage,
             process_flag = G_PROCESS_FLAG,
             transaction_mode = G_TRANS_MODE,
             ERROR_CODE = DECODE (ERROR_CODE, NULL, p_error_code, ERROR_CODE),
             last_update_date = x_last_update_date,
             last_updated_by = x_last_updated_by,
             last_update_login = x_last_update_login
       WHERE batch_id = g_batch_id
         AND request_id = xx_emf_pkg.g_request_id
         AND process_code = xx_emf_cn_pkg.cn_new;

      COMMIT;
   END update_staging_records;

   -- END RESTRICTIONS
   PROCEDURE main (
      errbuf                    OUT      VARCHAR2,
      retcode                   OUT      VARCHAR2,
      p_batch_id                IN       VARCHAR2,
      p_restart_flag            IN       VARCHAR2,
      p_override_flag           IN       VARCHAR2,
      p_validate_and_load       IN       VARCHAR2,
      p_transaction_type_name   IN       VARCHAR2,
      p_transaction_date        IN       VARCHAR2
   )
   IS
      x_error_code          NUMBER                := xx_emf_cn_pkg.cn_success;
      x_pre_std_hdr_table   g_xx_inv_itemqoh_pre_tab_type;

      -- CURSOR FOR VARIOUS STAGES
      CURSOR c_xx_intg_pre_std_hdr (cp_process_status VARCHAR2)
      IS
         SELECT
		   INVENTORY_ITEM_ID
		  ,ITEM_SEGMENT1
		  ,ITEM_SEGMENT2
		  ,ITEM_SEGMENT3
		  ,ITEM_SEGMENT4
		  ,ITEM_SEGMENT5
		  ,ITEM_SEGMENT6
		  ,ITEM_SEGMENT7
		  ,ITEM_SEGMENT8
		  ,ITEM_SEGMENT9
		  ,ITEM_SEGMENT10
		  ,ITEM_SEGMENT11
		  ,ITEM_SEGMENT12
		  ,ITEM_SEGMENT13
		  ,ITEM_SEGMENT14
		  ,ITEM_SEGMENT15
		  ,ITEM_SEGMENT16
		  ,ITEM_SEGMENT17
		  ,ITEM_SEGMENT18
		  ,ITEM_SEGMENT19
		  ,ITEM_SEGMENT20
		  ,REVISION
 		  ,ORGANIZATION_ID
		  ,ORGANIZATION_NAME
		  ,TRANSACTION_QUANTITY
		  ,PRIMARY_QUANTITY
		  ,TRANSACTION_UOM
		  ,TRANSACTION_DATE
		  ,ACCT_PERIOD_ID
		  ,SUBINVENTORY_CODE
		  ,LOCATOR_ID
		  ,LOC_SEGMENT1
		  ,LOC_SEGMENT2
		  ,LOC_SEGMENT3
		  ,LOC_SEGMENT4
		  ,LOC_SEGMENT5
		  ,LOC_SEGMENT6
		  ,LOC_SEGMENT7
		  ,LOC_SEGMENT8
		  ,LOC_SEGMENT9
		  ,LOC_SEGMENT10
		  ,LOC_SEGMENT11
		  ,LOC_SEGMENT12
		  ,LOC_SEGMENT13
		  ,LOC_SEGMENT14
		  ,LOC_SEGMENT15
		  ,LOC_SEGMENT16
		  ,LOC_SEGMENT17
		  ,LOC_SEGMENT18
		  ,LOC_SEGMENT19
		  ,LOC_SEGMENT20
		  ,TRANSACTION_SOURCE_ID
		  ,DSP_SEGMENT1
		  ,DSP_SEGMENT2
		  ,DSP_SEGMENT3
		  ,DSP_SEGMENT4
		  ,DSP_SEGMENT5
		  ,DSP_SEGMENT6
		  ,DSP_SEGMENT7
		  ,DSP_SEGMENT8
		  ,DSP_SEGMENT9
		  ,DSP_SEGMENT10
		  ,DSP_SEGMENT11
		  ,DSP_SEGMENT12
		  ,DSP_SEGMENT13
		  ,DSP_SEGMENT14
		  ,DSP_SEGMENT15
		  ,DSP_SEGMENT16
		  ,DSP_SEGMENT17
		  ,DSP_SEGMENT18
		  ,DSP_SEGMENT19
		  ,DSP_SEGMENT20
		  ,DSP_SEGMENT21
		  ,DSP_SEGMENT22
		  ,DSP_SEGMENT23
		  ,DSP_SEGMENT24
		  ,DSP_SEGMENT25
		  ,DSP_SEGMENT26
		  ,DSP_SEGMENT27
		  ,DSP_SEGMENT28
		  ,DSP_SEGMENT29
		  ,DSP_SEGMENT30
		  ,TRANSACTION_SOURCE_NAME
		  ,TRANSACTION_SOURCE_TYPE_ID
		  ,TRANSACTION_ACTION_ID
		  ,TRANSACTION_TYPE_ID
		  ,REASON_ID
		  ,TRANSACTION_REFERENCE
		  ,TRANSACTION_COST
		  ,DISTRIBUTION_ACCOUNT_ID
		  ,DST_SEGMENT1
		  ,DST_SEGMENT2
		  ,DST_SEGMENT3
		  ,DST_SEGMENT4
		  ,DST_SEGMENT5
		  ,DST_SEGMENT6
		  ,DST_SEGMENT7
		  ,DST_SEGMENT8
		  ,DST_SEGMENT9
		  ,DST_SEGMENT10
		  ,DST_SEGMENT11
		  ,DST_SEGMENT12
		  ,DST_SEGMENT13
		  ,DST_SEGMENT14
		  ,DST_SEGMENT15
		  ,DST_SEGMENT16
		  ,DST_SEGMENT17
		  ,DST_SEGMENT18
		  ,DST_SEGMENT19
		  ,DST_SEGMENT20
		  ,DST_SEGMENT21
		  ,DST_SEGMENT22
		  ,DST_SEGMENT23
		  ,DST_SEGMENT24
		  ,DST_SEGMENT25
		  ,DST_SEGMENT26
		  ,DST_SEGMENT27
		  ,DST_SEGMENT28
		  ,DST_SEGMENT29
		  ,DST_SEGMENT30
		  ,REQUISITION_LINE_ID
		  ,CURRENCY_CODE
		  ,CURRENCY_CONVERSION_DATE
		  ,CURRENCY_CONVERSION_TYPE
		  ,CURRENCY_CONVERSION_RATE
		  ,USSGL_TRANSACTION_CODE
		  ,WIP_ENTITY_TYPE
		  ,SCHEDULE_ID
		  ,EMPLOYEE_CODE
		  ,DEPARTMENT_ID
		  ,SCHEDULE_UPDATE_CODE
		  ,SETUP_TEARDOWN_CODE
		  ,PRIMARY_SWITCH
		  ,MRP_CODE
		  ,OPERATION_SEQ_NUM
		  ,REPETITIVE_LINE_ID
		  ,PICKING_LINE_ID
		  ,TRX_SOURCE_LINE_ID
		  ,TRX_SOURCE_DELIVERY_ID
		  ,DEMAND_ID
		  ,CUSTOMER_SHIP_ID
		  ,LINE_ITEM_NUM
		  ,RECEIVING_DOCUMENT
		  ,RCV_TRANSACTION_ID
		  ,SHIP_TO_LOCATION_ID
		  ,ENCUMBRANCE_ACCOUNT
		  ,ENCUMBRANCE_AMOUNT
		  ,VENDOR_LOT_NUMBER
		  ,TRANSFER_SUBINVENTORY
		  ,TRANSFER_ORGANIZATION
		  ,TRANSFER_LOCATOR
		  ,XFER_LOC_SEGMENT1
		  ,XFER_LOC_SEGMENT2
		  ,XFER_LOC_SEGMENT3
		  ,XFER_LOC_SEGMENT4
		  ,XFER_LOC_SEGMENT5
		  ,XFER_LOC_SEGMENT6
		  ,XFER_LOC_SEGMENT7
		  ,XFER_LOC_SEGMENT8
		  ,XFER_LOC_SEGMENT9
		  ,XFER_LOC_SEGMENT10
		  ,XFER_LOC_SEGMENT11
		  ,XFER_LOC_SEGMENT12
		  ,XFER_LOC_SEGMENT13
		  ,XFER_LOC_SEGMENT14
		  ,XFER_LOC_SEGMENT15
		  ,XFER_LOC_SEGMENT16
		  ,XFER_LOC_SEGMENT17
		  ,XFER_LOC_SEGMENT18
		  ,XFER_LOC_SEGMENT19
		  ,XFER_LOC_SEGMENT20
		  ,SHIPMENT_NUMBER
		  ,TRANSPORTATION_COST
		  ,TRANSPORTATION_ACCOUNT
		  ,TRANSFER_COST
		  ,FREIGHT_CODE
		  ,CONTAINERS
		  ,WAYBILL_AIRBILL
		  ,EXPECTED_ARRIVAL_DATE
		  ,NEW_AVERAGE_COST
		  ,VALUE_CHANGE
		  ,PERCENTAGE_CHANGE
		  ,DEMAND_SOURCE_HEADER_ID
		  ,DEMAND_SOURCE_LINE
		  ,DEMAND_SOURCE_DELIVERY
		  ,NEGATIVE_REQ_FLAG
		  ,ERROR_EXPLANATION
		  ,SHIPPABLE_FLAG
		  ,ERROR_CODE
		  ,REQUIRED_FLAG
		  ,ATTRIBUTE_CATEGORY
		  ,ATTRIBUTE1
		  ,ATTRIBUTE2
		  ,ATTRIBUTE3
		  ,ATTRIBUTE4
		  ,ATTRIBUTE5
		  ,ATTRIBUTE6
		  ,ATTRIBUTE7
		  ,ATTRIBUTE8
		  ,ATTRIBUTE9
		  ,ATTRIBUTE10
		  ,REQUISITION_DISTRIBUTION_ID
		  ,MOVEMENT_ID
		  ,RESERVATION_QUANTITY
		  ,SHIPPED_QUANTITY
		  ,INVENTORY_ITEM
		  ,LOCATOR_NAME
		  ,TASK_ID
		  ,TO_TASK_ID
		  ,SOURCE_TASK_ID
		  ,PROJECT_ID
		  ,TO_PROJECT_ID
		  ,SOURCE_PROJECT_ID
		  ,PA_EXPENDITURE_ORG_ID
		  ,EXPENDITURE_TYPE
		  ,FINAL_COMPLETION_FLAG
		  ,TRANSFER_PERCENTAGE
		  ,TRANSACTION_SEQUENCE_ID
		  ,MATERIAL_ACCOUNT
		  ,MATERIAL_OVERHEAD_ACCOUNT
		  ,RESOURCE_ACCOUNT
		  ,OUTSIDE_PROCESSING_ACCOUNT
		  ,OVERHEAD_ACCOUNT
		  ,BOM_REVISION
		  ,ROUTING_REVISION
		  ,BOM_REVISION_DATE
		  ,ROUTING_REVISION_DATE
		  ,ALTERNATE_BOM_DESIGNATOR
		  ,ALTERNATE_ROUTING_DESIGNATOR
		  ,ACCOUNTING_CLASS
		  ,DEMAND_CLASS
		  ,PARENT_ID
		  ,SUBSTITUTION_TYPE_ID
		  ,SUBSTITUTION_ITEM_ID
		  ,SCHEDULE_GROUP
		  ,BUILD_SEQUENCE
		  ,SCHEDULE_NUMBER
		  ,SCHEDULED_FLAG
		  ,FLOW_SCHEDULE
		  ,COST_GROUP_ID
		  ,KANBAN_CARD_ID
		  ,QA_COLLECTION_ID
		  ,OVERCOMPLETION_TRANSACTION_QTY
		  ,OVERCOMPLETION_PRIMARY_QTY
		 ,OVERCOMPLETION_TRANSACTION_ID
		  ,END_ITEM_UNIT_NUMBER
		  ,SCHEDULED_PAYBACK_DATE
		  ,ORG_COST_GROUP_ID
		  ,COST_TYPE_ID
		  ,SOURCE_LOT_NUMBER
		  ,TRANSFER_COST_GROUP_ID
		  ,LPN_NUMBER
		  ,TRANSFER_LPN_ID
		  ,CONTENT_LPN_ID
		  ,XML_DOCUMENT_ID
		  ,ORGANIZATION_TYPE
		  ,TRANSFER_ORGANIZATION_TYPE
		  ,OWNING_ORGANIZATION_NAME
		  ,OWNING_TP_TYPE
		  ,XFR_OWNING_ORGANIZATION_ID
		  ,TRANSFER_OWNING_TP_TYPE
		  ,PLANNING_ORGANIZATION_ID
		  ,PLANNING_TP_TYPE
		  ,XFR_PLANNING_ORGANIZATION_ID
		  ,TRANSFER_PLANNING_TP_TYPE
		  ,SECONDARY_UOM_CODE
		  ,SECONDARY_TRANSACTION_QUANTITY
		  ,TRANSACTION_GROUP_ID
		  ,TRANSACTION_GROUP_SEQ
		  ,REPRESENTATIVE_LOT_NUMBER
		  ,TRANSACTION_BATCH_ID
		  ,TRANSACTION_BATCH_SEQ
		  ,REBUILD_ITEM_ID
		  ,REBUILD_SERIAL_NUMBER
		  ,REBUILD_ACTIVITY_ID
		  ,REBUILD_JOB_NAME
		  ,MOVE_TRANSACTION_ID
		  ,COMPLETION_TRANSACTION_ID
		  ,WIP_SUPPLY_TYPE
		  ,RELIEVE_RESERVATIONS_FLAG
		  ,RELIEVE_HIGH_LEVEL_RSV_FLAG
		  ,TRANSFER_PRICE
		  ,STATUS
		  ,REQUEST_ID
		  ,OPERATING_UNIT_NAME
		  ,LOT_NUMBER
		  ,MTLI_ORIGINATION_DATE
		  ,LOT_EXPIRATION_DATE
		  ,STATUS_ID
		  ,MTLI_TRANSACTIONS_QUANTITY
		  ,MTI_TRANSACTION_UOM
		  ,MTI_OWNING_ORGANIZATION_NAME
		  ,FM_SERIAL_NUMBER
		  ,TO_SERIAL_NUMBER
		  ,MSNI_ORIGINATION_DATE
		  ,STATUS_NAME
		  ,MTLI_PLACE_OF_ORIGIN
		  ,CREATION_DATE
		  ,CREATED_BY
		  ,LAST_UPDATE_DATE
		  ,LAST_UPDATED_BY
		  ,BATCH_ID
		  ,RECORD_NUMBER
		  ,SOURCE_SYSTEM_NAME
		  ,PROCESS_FLAG
		  ,TRANSACTION_MODE
		  ,TRANSACTION_TYPE_NAME
		  ,PROCESS_CODE
		  ,MTLI_STATUS_ID
		  ,LAST_UPDATE_LOGIN
		  ,SOURCE_CODE
		  ,SOURCE_LINE_ID
		  ,SOURCE_HEADER_ID
		  ,LPN_ID
		  ,MTI_OWNING_ORGANIZATION_ID
             FROM xx_mtl_transactions_pre hdr
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
         ORDER BY record_number;

-------------------------------------------------------------------------
-----------< update_record_status >-------------------------------
-------------------------------------------------------------------------
      PROCEDURE update_record_status (
         p_conv_pre_std_hdr_rec   IN OUT   g_xx_inv_itemqoh_pre_rec_type,
         p_error_code             IN       VARCHAR2
      )
      IS
      BEGIN
         IF p_error_code IN
                        (xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err)
         THEN
            p_conv_pre_std_hdr_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            --    p_conv_pre_std_hdr_rec.error_code := xx_inv_item_onhandval_pkg.find_max (p_error_code,
              --        NVL (p_conv_pre_std_hdr_rec.error_code,xx_emf_cn_pkg.CN_SUCCESS));
            NULL;
         END IF;

         p_conv_pre_std_hdr_rec.process_code := g_stage;
      END update_record_status;

-------------------------------------------------------------------------
-----------< mark_records_complete >-------------------------------
-------------------------------------------------------------------------
      PROCEDURE mark_records_complete (p_process_code VARCHAR2)
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         UPDATE xx_mtl_transactions_pre
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
      END mark_records_complete;

-------------------------------------------------------------------------
-----------< update_pre_interface_records >-------------------------------
-------------------------------------------------------------------------
      PROCEDURE update_pre_interface_records (
         p_cnv_pre_std_hdr_table   IN   g_xx_inv_itemqoh_pre_tab_type
      )
      IS
         x_last_update_date    DATE          := SYSDATE;
         x_last_updated_by     NUMBER        := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         x_status_name         VARCHAR2 (40) := G_STATUS_NAME;
         x_status_id           NUMBER        := G_STATUS_ID;
         x_source_code         VARCHAR2 (30) := G_SOURCE_CODE;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         FOR indx IN 1 .. p_cnv_pre_std_hdr_table.COUNT
         LOOP
            xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                'p_cnv_pre_std_hdr_table(indx).process_code '
                             || p_cnv_pre_std_hdr_table (indx).process_code
                            );
            xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                   'p_cnv_pre_std_hdr_table(indx).error_code '
                                || p_cnv_pre_std_hdr_table (indx).ERROR_CODE
                               );

            UPDATE xx_mtl_transactions_pre
               SET
                   subinventory_code = p_cnv_pre_std_hdr_table (indx).subinventory_code,
                   loc_segment1 = p_cnv_pre_std_hdr_table (indx).loc_segment1,
                   loc_segment2 = p_cnv_pre_std_hdr_table (indx).loc_segment2,
                   loc_segment3 = p_cnv_pre_std_hdr_table (indx).loc_segment3,
                   transfer_lpn_id = p_cnv_pre_std_hdr_table (indx).transfer_lpn_id,  -- Added on 09th Jan 14 for wave 1 enhancement
                   to_serial_number = p_cnv_pre_std_hdr_table (indx).to_serial_number,
                   revision = p_cnv_pre_std_hdr_table (indx).revision,
                   mtli_status_id = x_status_id,
                   transaction_uom = p_cnv_pre_std_hdr_table (indx).transaction_uom,
                   status_name = x_status_name,
                   source_code = x_source_code,
                   process_flag = p_cnv_pre_std_hdr_table (indx).process_flag,
                   inventory_item_id = p_cnv_pre_std_hdr_table (indx).inventory_item_id,
                   organization_id = p_cnv_pre_std_hdr_table (indx).organization_id,
		   mti_owning_organization_id = p_cnv_pre_std_hdr_table (indx).mti_owning_organization_id,
		   transaction_source_id = p_cnv_pre_std_hdr_table (indx).transaction_source_id, -- 16th_AUG_2012
                   transaction_type_id = p_cnv_pre_std_hdr_table (indx).transaction_type_id,
                   distribution_account_id = p_cnv_pre_std_hdr_table (indx).distribution_account_id,
                   process_code = p_cnv_pre_std_hdr_table (indx).process_code,
                   ERROR_CODE = p_cnv_pre_std_hdr_table (indx).ERROR_CODE,
                   last_update_date = x_last_update_date,
                   last_updated_by = x_last_updated_by,
                   last_update_login = x_last_update_login
             WHERE record_number = p_cnv_pre_std_hdr_table (indx).record_number;
         END LOOP;

         COMMIT;
      END update_pre_interface_records;

-------------------------------------------------------------------------
-----------< move_rec_pre_standard_table >-------------------------------
-------------------------------------------------------------------------
      FUNCTION move_rec_pre_standard_table
         RETURN NUMBER
      IS
         x_creation_date       DATE          := SYSDATE;
         x_created_by          NUMBER        := fnd_global.user_id;
         x_last_update_date    DATE          := SYSDATE;
         x_last_updated_by     NUMBER        := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         x_transaction_type    VARCHAR2 (40) := p_transaction_type_name;
         x_trans_date           DATE  := FND_DATE.CANONICAL_TO_DATE(p_transaction_date);  -- 28th-Oct-13
         x_trans_source         VARCHAR2 (40) := G_TRANS_SOURCE_NAME;  --16th-AUG-12
         x_error_code          NUMBER        := xx_emf_cn_pkg.cn_success;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside move_rec_pre_standard_table'
                              );

      /*   IF (x_trans_date IS NOT NULL)
         THEN
            UPDATE xx_mtl_transactions_stg
               SET transaction_date = x_trans_date
             WHERE batch_id = g_batch_id
               AND process_code = xx_emf_cn_pkg.cn_preval
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn);

            COMMIT;
         END IF; */ -- commented on 09-JAN-2013 to populate transaction date from data file

         INSERT INTO xx_mtl_transactions_pre
                          (INVENTORY_ITEM_ID
			  ,ITEM_SEGMENT1
		          ,ITEM_SEGMENT2
			  ,ITEM_SEGMENT3
			  ,ITEM_SEGMENT4
			  ,ITEM_SEGMENT5
			  ,ITEM_SEGMENT6
			  ,ITEM_SEGMENT7
			  ,ITEM_SEGMENT8
			  ,ITEM_SEGMENT9
			  ,ITEM_SEGMENT10
			  ,ITEM_SEGMENT11
			  ,ITEM_SEGMENT12
			  ,ITEM_SEGMENT13
			  ,ITEM_SEGMENT14
			  ,ITEM_SEGMENT15
			  ,ITEM_SEGMENT16
			  ,ITEM_SEGMENT17
			  ,ITEM_SEGMENT18
			  ,ITEM_SEGMENT19
			  ,ITEM_SEGMENT20
			  ,REVISION
			  ,ORGANIZATION_ID
  			  ,ORGANIZATION_NAME
			  ,TRANSACTION_QUANTITY
			  ,PRIMARY_QUANTITY
			  ,TRANSACTION_UOM
			  ,TRANSACTION_DATE
			  ,ACCT_PERIOD_ID
			  ,SUBINVENTORY_CODE
			  ,LOCATOR_ID
			  ,LOC_SEGMENT1
			  ,LOC_SEGMENT2
			  ,LOC_SEGMENT3
			  ,LOC_SEGMENT4
			  ,LOC_SEGMENT5
			  ,LOC_SEGMENT6
			  ,LOC_SEGMENT7
			  ,LOC_SEGMENT8
			  ,LOC_SEGMENT9
			  ,LOC_SEGMENT10
			  ,LOC_SEGMENT11
			  ,LOC_SEGMENT12
			  ,LOC_SEGMENT13
			  ,LOC_SEGMENT14
			  ,LOC_SEGMENT15
			  ,LOC_SEGMENT16
			  ,LOC_SEGMENT17
			  ,LOC_SEGMENT18
			  ,LOC_SEGMENT19
			  ,LOC_SEGMENT20
			  ,TRANSACTION_SOURCE_ID
			  ,DSP_SEGMENT1
			  ,DSP_SEGMENT2
			  ,DSP_SEGMENT3
			  ,DSP_SEGMENT4
			  ,DSP_SEGMENT5
			  ,DSP_SEGMENT6
			  ,DSP_SEGMENT7
			  ,DSP_SEGMENT8
			  ,DSP_SEGMENT9
			  ,DSP_SEGMENT10
			  ,DSP_SEGMENT11
			  ,DSP_SEGMENT12
			  ,DSP_SEGMENT13
			  ,DSP_SEGMENT14
			  ,DSP_SEGMENT15
			  ,DSP_SEGMENT16
			  ,DSP_SEGMENT17
			  ,DSP_SEGMENT18
			  ,DSP_SEGMENT19
			  ,DSP_SEGMENT20
			  ,DSP_SEGMENT21
			  ,DSP_SEGMENT22
			  ,DSP_SEGMENT23
			  ,DSP_SEGMENT24
			  ,DSP_SEGMENT25
			  ,DSP_SEGMENT26
			  ,DSP_SEGMENT27
			  ,DSP_SEGMENT28
			  ,DSP_SEGMENT29
			  ,DSP_SEGMENT30
			  ,TRANSACTION_SOURCE_NAME
			  ,TRANSACTION_SOURCE_TYPE_ID
			  ,TRANSACTION_ACTION_ID
			  ,TRANSACTION_TYPE_ID
			  ,REASON_ID
			  ,TRANSACTION_REFERENCE
			  ,TRANSACTION_COST
			  ,DISTRIBUTION_ACCOUNT_ID
			  ,DST_SEGMENT1
			  ,DST_SEGMENT2
			  ,DST_SEGMENT3
			  ,DST_SEGMENT4
			  ,DST_SEGMENT5
			  ,DST_SEGMENT6
			  ,DST_SEGMENT7
			  ,DST_SEGMENT8
			  ,DST_SEGMENT9
			  ,DST_SEGMENT10
			  ,DST_SEGMENT11
			  ,DST_SEGMENT12
			  ,DST_SEGMENT13
			  ,DST_SEGMENT14
			  ,DST_SEGMENT15
			  ,DST_SEGMENT16
			  ,DST_SEGMENT17
			  ,DST_SEGMENT18
			  ,DST_SEGMENT19
			  ,DST_SEGMENT20
			  ,DST_SEGMENT21
			  ,DST_SEGMENT22
			  ,DST_SEGMENT23
			  ,DST_SEGMENT24
			  ,DST_SEGMENT25
			  ,DST_SEGMENT26
			  ,DST_SEGMENT27
			  ,DST_SEGMENT28
			  ,DST_SEGMENT29
			  ,DST_SEGMENT30
			  ,REQUISITION_LINE_ID
			  ,CURRENCY_CODE
			  ,CURRENCY_CONVERSION_DATE
			  ,CURRENCY_CONVERSION_TYPE
			  ,CURRENCY_CONVERSION_RATE
			  ,USSGL_TRANSACTION_CODE
			  ,WIP_ENTITY_TYPE
			  ,SCHEDULE_ID
			  ,EMPLOYEE_CODE
			  ,DEPARTMENT_ID
			  ,SCHEDULE_UPDATE_CODE
			  ,SETUP_TEARDOWN_CODE
			  ,PRIMARY_SWITCH
			  ,MRP_CODE
			  ,OPERATION_SEQ_NUM
			  ,REPETITIVE_LINE_ID
			  ,PICKING_LINE_ID
			  ,TRX_SOURCE_LINE_ID
			  ,TRX_SOURCE_DELIVERY_ID
			  ,DEMAND_ID
			  ,CUSTOMER_SHIP_ID
			  ,LINE_ITEM_NUM
			  ,RECEIVING_DOCUMENT
			  ,RCV_TRANSACTION_ID
			  ,SHIP_TO_LOCATION_ID
			  ,ENCUMBRANCE_ACCOUNT
			  ,ENCUMBRANCE_AMOUNT
			  ,VENDOR_LOT_NUMBER
			  ,TRANSFER_SUBINVENTORY
			  ,TRANSFER_ORGANIZATION
			  ,TRANSFER_LOCATOR
			  ,XFER_LOC_SEGMENT1
			  ,XFER_LOC_SEGMENT2
			  ,XFER_LOC_SEGMENT3
			  ,XFER_LOC_SEGMENT4
			  ,XFER_LOC_SEGMENT5
			  ,XFER_LOC_SEGMENT6
			  ,XFER_LOC_SEGMENT7
			  ,XFER_LOC_SEGMENT8
			  ,XFER_LOC_SEGMENT9
			  ,XFER_LOC_SEGMENT10
			  ,XFER_LOC_SEGMENT11
			  ,XFER_LOC_SEGMENT12
			  ,XFER_LOC_SEGMENT13
			  ,XFER_LOC_SEGMENT14
			  ,XFER_LOC_SEGMENT15
			  ,XFER_LOC_SEGMENT16
			  ,XFER_LOC_SEGMENT17
			  ,XFER_LOC_SEGMENT18
			  ,XFER_LOC_SEGMENT19
			  ,XFER_LOC_SEGMENT20
			  ,SHIPMENT_NUMBER
			  ,TRANSPORTATION_COST
			  ,TRANSPORTATION_ACCOUNT
			  ,TRANSFER_COST
			  ,FREIGHT_CODE
			  ,CONTAINERS
			  ,WAYBILL_AIRBILL
			  ,EXPECTED_ARRIVAL_DATE
			  ,NEW_AVERAGE_COST
			  ,VALUE_CHANGE
			  ,PERCENTAGE_CHANGE
			  ,DEMAND_SOURCE_HEADER_ID
			  ,DEMAND_SOURCE_LINE
			  ,DEMAND_SOURCE_DELIVERY
			  ,NEGATIVE_REQ_FLAG
			  ,ERROR_EXPLANATION
			  ,SHIPPABLE_FLAG
			  ,ERROR_CODE
			  ,REQUIRED_FLAG
			  ,ATTRIBUTE_CATEGORY
			  ,ATTRIBUTE1
			  ,ATTRIBUTE2
			  ,ATTRIBUTE3
			  ,ATTRIBUTE4
			  ,ATTRIBUTE5
			  ,ATTRIBUTE6
			  ,ATTRIBUTE7
			  ,ATTRIBUTE8
			  ,ATTRIBUTE9
			  ,ATTRIBUTE10
			  ,REQUISITION_DISTRIBUTION_ID
			  ,MOVEMENT_ID
			  ,RESERVATION_QUANTITY
			  ,SHIPPED_QUANTITY
			  ,INVENTORY_ITEM
			  ,LOCATOR_NAME
			  ,TASK_ID
			  ,TO_TASK_ID
			  ,SOURCE_TASK_ID
			  ,PROJECT_ID
			  ,TO_PROJECT_ID
			  ,SOURCE_PROJECT_ID
			  ,PA_EXPENDITURE_ORG_ID
			  ,EXPENDITURE_TYPE
			  ,FINAL_COMPLETION_FLAG
			  ,TRANSFER_PERCENTAGE
			  ,TRANSACTION_SEQUENCE_ID
			  ,MATERIAL_ACCOUNT
			  ,MATERIAL_OVERHEAD_ACCOUNT
			  ,RESOURCE_ACCOUNT
			  ,OUTSIDE_PROCESSING_ACCOUNT
			  ,OVERHEAD_ACCOUNT
			  ,BOM_REVISION
			  ,ROUTING_REVISION
			  ,BOM_REVISION_DATE
			  ,ROUTING_REVISION_DATE
			  ,ALTERNATE_BOM_DESIGNATOR
			  ,ALTERNATE_ROUTING_DESIGNATOR
			  ,ACCOUNTING_CLASS
			  ,DEMAND_CLASS
			  ,PARENT_ID
			  ,SUBSTITUTION_TYPE_ID
			  ,SUBSTITUTION_ITEM_ID
			  ,SCHEDULE_GROUP
			  ,BUILD_SEQUENCE
			  ,SCHEDULE_NUMBER
			  ,SCHEDULED_FLAG
			  ,FLOW_SCHEDULE
			  ,COST_GROUP_ID
			  ,KANBAN_CARD_ID
			  ,QA_COLLECTION_ID
			  ,OVERCOMPLETION_TRANSACTION_QTY
			  ,OVERCOMPLETION_PRIMARY_QTY
			  ,OVERCOMPLETION_TRANSACTION_ID
			  ,END_ITEM_UNIT_NUMBER
			  ,SCHEDULED_PAYBACK_DATE
			  ,ORG_COST_GROUP_ID
			  ,COST_TYPE_ID
			  ,SOURCE_LOT_NUMBER
			  ,TRANSFER_COST_GROUP_ID
			  ,LPN_NUMBER
			  ,TRANSFER_LPN_ID
			  ,CONTENT_LPN_ID
			  ,XML_DOCUMENT_ID
			  ,ORGANIZATION_TYPE
			  ,TRANSFER_ORGANIZATION_TYPE
			  ,OWNING_ORGANIZATION_NAME
			  ,OWNING_TP_TYPE
			  ,XFR_OWNING_ORGANIZATION_ID
			  ,TRANSFER_OWNING_TP_TYPE
			  ,PLANNING_ORGANIZATION_ID
			  ,PLANNING_TP_TYPE
			  ,XFR_PLANNING_ORGANIZATION_ID
			  ,TRANSFER_PLANNING_TP_TYPE
			  ,SECONDARY_UOM_CODE
			  ,SECONDARY_TRANSACTION_QUANTITY
			  ,TRANSACTION_GROUP_ID
			  ,TRANSACTION_GROUP_SEQ
			  ,REPRESENTATIVE_LOT_NUMBER
			  ,TRANSACTION_BATCH_ID
			  ,TRANSACTION_BATCH_SEQ
			  ,REBUILD_ITEM_ID
			  ,REBUILD_SERIAL_NUMBER
			  ,REBUILD_ACTIVITY_ID
			  ,REBUILD_JOB_NAME
			  ,MOVE_TRANSACTION_ID
			  ,COMPLETION_TRANSACTION_ID
			  ,WIP_SUPPLY_TYPE
			  ,RELIEVE_RESERVATIONS_FLAG
			  ,RELIEVE_HIGH_LEVEL_RSV_FLAG
			  ,TRANSFER_PRICE
			  ,STATUS
			  ,REQUEST_ID
			  ,OPERATING_UNIT_NAME
			  ,LOT_NUMBER
			  ,MTLI_ORIGINATION_DATE
			  ,LOT_EXPIRATION_DATE
			  ,STATUS_ID
			  ,MTLI_TRANSACTIONS_QUANTITY
			  ,MTI_TRANSACTION_UOM
			  ,MTI_OWNING_ORGANIZATION_NAME
			  ,FM_SERIAL_NUMBER
			  ,MSNI_ORIGINATION_DATE
			  ,STATUS_NAME
			  ,MTLI_PLACE_OF_ORIGIN
			  ,CREATION_DATE
			  ,CREATED_BY
			  ,LAST_UPDATE_DATE
			  ,LAST_UPDATED_BY
			  ,BATCH_ID
			  ,RECORD_NUMBER
			  ,SOURCE_SYSTEM_NAME
			  ,PROCESS_FLAG
			  ,TRANSACTION_MODE
			  ,TRANSACTION_TYPE_NAME
			  ,PROCESS_CODE
			  ,MTLI_STATUS_ID
			  ,LAST_UPDATE_LOGIN
			  ,SOURCE_LINE_ID
			  ,SOURCE_HEADER_ID
			  )
                SELECT    INVENTORY_ITEM_ID
			  ,ITEM_SEGMENT1
		          ,ITEM_SEGMENT2
			  ,ITEM_SEGMENT3
			  ,ITEM_SEGMENT4
			  ,ITEM_SEGMENT5
			  ,ITEM_SEGMENT6
			  ,ITEM_SEGMENT7
			  ,ITEM_SEGMENT8
			  ,ITEM_SEGMENT9
			  ,ITEM_SEGMENT10
			  ,ITEM_SEGMENT11
			  ,ITEM_SEGMENT12
			  ,ITEM_SEGMENT13
			  ,ITEM_SEGMENT14
			  ,ITEM_SEGMENT15
			  ,ITEM_SEGMENT16
			  ,ITEM_SEGMENT17
			  ,ITEM_SEGMENT18
			  ,ITEM_SEGMENT19
			  ,ITEM_SEGMENT20
			  ,REVISION
			  ,ORGANIZATION_ID
  			  ,ORGANIZATION_NAME
			  ,TRANSACTION_QUANTITY
			  ,PRIMARY_QUANTITY
			  ,TRANSACTION_UOM
			  ,DECODE(x_trans_date,NULL,NVL(TRANSACTION_DATE,SYSDATE),x_trans_date) -- (28-OCT-2013) populate transaction date from parameter if null then from data file if null then sysdate 
			  ,ACCT_PERIOD_ID
			  ,SUBINVENTORY_CODE
			  ,LOCATOR_ID
			  ,LOC_SEGMENT1
			  ,LOC_SEGMENT2
			  ,LOC_SEGMENT3
			  ,LOC_SEGMENT4
			  ,LOC_SEGMENT5
			  ,LOC_SEGMENT6
			  ,LOC_SEGMENT7
			  ,LOC_SEGMENT8
			  ,LOC_SEGMENT9
			  ,LOC_SEGMENT10
			  ,LOC_SEGMENT11
			  ,LOC_SEGMENT12
			  ,LOC_SEGMENT13
			  ,LOC_SEGMENT14
			  ,LOC_SEGMENT15
			  ,LOC_SEGMENT16
			  ,LOC_SEGMENT17
			  ,LOC_SEGMENT18
			  ,LOC_SEGMENT19
			  ,LOC_SEGMENT20
			  ,TRANSACTION_SOURCE_ID
			  ,DSP_SEGMENT1
			  ,DSP_SEGMENT2
			  ,DSP_SEGMENT3
			  ,DSP_SEGMENT4
			  ,DSP_SEGMENT5
			  ,DSP_SEGMENT6
			  ,DSP_SEGMENT7
			  ,DSP_SEGMENT8
			  ,DSP_SEGMENT9
			  ,DSP_SEGMENT10
			  ,DSP_SEGMENT11
			  ,DSP_SEGMENT12
			  ,DSP_SEGMENT13
			  ,DSP_SEGMENT14
			  ,DSP_SEGMENT15
			  ,DSP_SEGMENT16
			  ,DSP_SEGMENT17
			  ,DSP_SEGMENT18
			  ,DSP_SEGMENT19
			  ,DSP_SEGMENT20
			  ,DSP_SEGMENT21
			  ,DSP_SEGMENT22
			  ,DSP_SEGMENT23
			  ,DSP_SEGMENT24
			  ,DSP_SEGMENT25
			  ,DSP_SEGMENT26
			  ,DSP_SEGMENT27
			  ,DSP_SEGMENT28
			  ,DSP_SEGMENT29
			  ,DSP_SEGMENT30
			  ,X_TRANS_SOURCE --TRANSACTION_SOURCE_NAME -- 16th_AUG-2012
			  ,TRANSACTION_SOURCE_TYPE_ID
			  ,TRANSACTION_ACTION_ID
			  ,TRANSACTION_TYPE_ID
			  ,REASON_ID
			  ,TRANSACTION_REFERENCE
			  ,TRANSACTION_COST
			  ,DISTRIBUTION_ACCOUNT_ID
			  ,DST_SEGMENT1
			  ,DST_SEGMENT2
			  ,DST_SEGMENT3
			  ,DST_SEGMENT4
			  ,DST_SEGMENT5
			  ,DST_SEGMENT6
			  ,DST_SEGMENT7
			  ,DST_SEGMENT8
			  ,DST_SEGMENT9
			  ,DST_SEGMENT10
			  ,DST_SEGMENT11
			  ,DST_SEGMENT12
			  ,DST_SEGMENT13
			  ,DST_SEGMENT14
			  ,DST_SEGMENT15
			  ,DST_SEGMENT16
			  ,DST_SEGMENT17
			  ,DST_SEGMENT18
			  ,DST_SEGMENT19
			  ,DST_SEGMENT20
			  ,DST_SEGMENT21
			  ,DST_SEGMENT22
			  ,DST_SEGMENT23
			  ,DST_SEGMENT24
			  ,DST_SEGMENT25
			  ,DST_SEGMENT26
			  ,DST_SEGMENT27
			  ,DST_SEGMENT28
			  ,DST_SEGMENT29
			  ,DST_SEGMENT30
			  ,REQUISITION_LINE_ID
			  ,CURRENCY_CODE
			  ,CURRENCY_CONVERSION_DATE
			  ,CURRENCY_CONVERSION_TYPE
			  ,CURRENCY_CONVERSION_RATE
			  ,USSGL_TRANSACTION_CODE
			  ,WIP_ENTITY_TYPE
			  ,SCHEDULE_ID
			  ,EMPLOYEE_CODE
			  ,DEPARTMENT_ID
			  ,SCHEDULE_UPDATE_CODE
			  ,SETUP_TEARDOWN_CODE
			  ,PRIMARY_SWITCH
			  ,MRP_CODE
			  ,OPERATION_SEQ_NUM
			  ,REPETITIVE_LINE_ID
			  ,PICKING_LINE_ID
			  ,TRX_SOURCE_LINE_ID
			  ,TRX_SOURCE_DELIVERY_ID
			  ,DEMAND_ID
			  ,CUSTOMER_SHIP_ID
			  ,LINE_ITEM_NUM
			  ,RECEIVING_DOCUMENT
			  ,RCV_TRANSACTION_ID
			  ,SHIP_TO_LOCATION_ID
			  ,ENCUMBRANCE_ACCOUNT
			  ,ENCUMBRANCE_AMOUNT
			  ,VENDOR_LOT_NUMBER
			  ,TRANSFER_SUBINVENTORY
			  ,TRANSFER_ORGANIZATION
			  ,TRANSFER_LOCATOR
			  ,XFER_LOC_SEGMENT1
			  ,XFER_LOC_SEGMENT2
			  ,XFER_LOC_SEGMENT3
			  ,XFER_LOC_SEGMENT4
			  ,XFER_LOC_SEGMENT5
			  ,XFER_LOC_SEGMENT6
			  ,XFER_LOC_SEGMENT7
			  ,XFER_LOC_SEGMENT8
			  ,XFER_LOC_SEGMENT9
			  ,XFER_LOC_SEGMENT10
			  ,XFER_LOC_SEGMENT11
			  ,XFER_LOC_SEGMENT12
			  ,XFER_LOC_SEGMENT13
			  ,XFER_LOC_SEGMENT14
			  ,XFER_LOC_SEGMENT15
			  ,XFER_LOC_SEGMENT16
			  ,XFER_LOC_SEGMENT17
			  ,XFER_LOC_SEGMENT18
			  ,XFER_LOC_SEGMENT19
			  ,XFER_LOC_SEGMENT20
			  ,SHIPMENT_NUMBER
			  ,TRANSPORTATION_COST
			  ,TRANSPORTATION_ACCOUNT
			  ,TRANSFER_COST
			  ,FREIGHT_CODE
			  ,CONTAINERS
			  ,WAYBILL_AIRBILL
			  ,EXPECTED_ARRIVAL_DATE
			  ,NEW_AVERAGE_COST
			  ,VALUE_CHANGE
			  ,PERCENTAGE_CHANGE
			  ,DEMAND_SOURCE_HEADER_ID
			  ,DEMAND_SOURCE_LINE
			  ,DEMAND_SOURCE_DELIVERY
			  ,NEGATIVE_REQ_FLAG
			  ,ERROR_EXPLANATION
			  ,SHIPPABLE_FLAG
			  ,ERROR_CODE
			  ,REQUIRED_FLAG
			  ,ATTRIBUTE_CATEGORY 
			  ,ATTRIBUTE1
			  ,ATTRIBUTE2
			  ,ATTRIBUTE3
			  ,ATTRIBUTE4
			  ,ATTRIBUTE5
			  ,ATTRIBUTE6
			  ,ATTRIBUTE7
			  ,ATTRIBUTE8
			  ,ATTRIBUTE9
			  ,ATTRIBUTE10
			  ,REQUISITION_DISTRIBUTION_ID
			  ,MOVEMENT_ID
			  ,RESERVATION_QUANTITY
			  ,SHIPPED_QUANTITY
			  ,INVENTORY_ITEM
			  ,LOCATOR_NAME
			  ,TASK_ID
			  ,TO_TASK_ID
			  ,SOURCE_TASK_ID
			  ,PROJECT_ID
			  ,TO_PROJECT_ID
			  ,SOURCE_PROJECT_ID
			  ,PA_EXPENDITURE_ORG_ID
			  ,EXPENDITURE_TYPE
			  ,FINAL_COMPLETION_FLAG
			  ,TRANSFER_PERCENTAGE
			  ,TRANSACTION_SEQUENCE_ID
			  ,MATERIAL_ACCOUNT
			  ,MATERIAL_OVERHEAD_ACCOUNT
			  ,RESOURCE_ACCOUNT
			  ,OUTSIDE_PROCESSING_ACCOUNT
			  ,OVERHEAD_ACCOUNT
			  ,BOM_REVISION
			  ,ROUTING_REVISION
			  ,BOM_REVISION_DATE
			  ,ROUTING_REVISION_DATE
			  ,ALTERNATE_BOM_DESIGNATOR
			  ,ALTERNATE_ROUTING_DESIGNATOR
			  ,ACCOUNTING_CLASS
			  ,DEMAND_CLASS
			  ,PARENT_ID
			  ,SUBSTITUTION_TYPE_ID
			  ,SUBSTITUTION_ITEM_ID
			  ,SCHEDULE_GROUP
			  ,BUILD_SEQUENCE
			  ,SCHEDULE_NUMBER
			  ,SCHEDULED_FLAG
			  ,FLOW_SCHEDULE
			  ,COST_GROUP_ID
			  ,KANBAN_CARD_ID
			  ,QA_COLLECTION_ID
			  ,OVERCOMPLETION_TRANSACTION_QTY
			  ,OVERCOMPLETION_PRIMARY_QTY
			  ,OVERCOMPLETION_TRANSACTION_ID
			  ,END_ITEM_UNIT_NUMBER
			  ,SCHEDULED_PAYBACK_DATE
			  ,ORG_COST_GROUP_ID
			  ,COST_TYPE_ID
			  ,SOURCE_LOT_NUMBER
			  ,TRANSFER_COST_GROUP_ID
			  ,LPN_NUMBER
			  ,TRANSFER_LPN_ID
			  ,CONTENT_LPN_ID
			  ,XML_DOCUMENT_ID
			  ,ORGANIZATION_TYPE
			  ,TRANSFER_ORGANIZATION_TYPE
			  ,OWNING_ORGANIZATION_NAME
			  ,OWNING_TP_TYPE
			  ,XFR_OWNING_ORGANIZATION_ID
			  ,TRANSFER_OWNING_TP_TYPE
			  ,PLANNING_ORGANIZATION_ID
			  ,PLANNING_TP_TYPE
			  ,XFR_PLANNING_ORGANIZATION_ID
			  ,TRANSFER_PLANNING_TP_TYPE
			  ,SECONDARY_UOM_CODE
			  ,SECONDARY_TRANSACTION_QUANTITY
			  ,TRANSACTION_GROUP_ID
			  ,TRANSACTION_GROUP_SEQ
			  ,REPRESENTATIVE_LOT_NUMBER
			  ,TRANSACTION_BATCH_ID
			  ,TRANSACTION_BATCH_SEQ
			  ,REBUILD_ITEM_ID
			  ,REBUILD_SERIAL_NUMBER
			  ,REBUILD_ACTIVITY_ID
			  ,REBUILD_JOB_NAME
			  ,MOVE_TRANSACTION_ID
			  ,COMPLETION_TRANSACTION_ID
			  ,WIP_SUPPLY_TYPE
			  ,RELIEVE_RESERVATIONS_FLAG
			  ,RELIEVE_HIGH_LEVEL_RSV_FLAG
			  ,TRANSFER_PRICE
			  ,STATUS
			  ,REQUEST_ID
			  ,OPERATING_UNIT_NAME
			  ,LOT_NUMBER
			  ,MTLI_ORIGINATION_DATE
			  ,LOT_EXPIRATION_DATE
			  ,STATUS_ID
			  ,MTLI_TRANSACTIONS_QUANTITY
			  ,MTI_TRANSACTION_UOM
			  ,MTI_OWNING_ORGANIZATION_NAME
			  ,FM_SERIAL_NUMBER
			  ,MSNI_ORIGINATION_DATE
			  ,STATUS_NAME
			  ,MTLI_PLACE_OF_ORIGIN
			  ,X_CREATION_DATE
			  ,X_CREATED_BY
			  ,X_LAST_UPDATE_DATE
			  ,X_LAST_UPDATED_BY
			  ,BATCH_ID
			  ,RECORD_NUMBER
			  ,SOURCE_SYSTEM_NAME
			  ,PROCESS_FLAG
			  ,TRANSACTION_MODE
			  ,X_TRANSACTION_TYPE
			  ,G_STAGE
			  ,MTLI_STATUS_ID
			  ,X_LAST_UPDATE_LOGIN
	                  ,XX_MTL_TRANS_SRC_LINE_ID_S.NEXTVAL
	                  ,REQUEST_ID
              FROM xx_mtl_transactions_stg
             WHERE batch_id = g_batch_id
               AND process_code = xx_emf_cn_pkg.cn_preval
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn);

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Inside move_rec_pre_standard_table : '
                               || g_batch_id
                               || ' - '
                               || xx_emf_cn_pkg.cn_preval
                               || ' - '
                               || xx_emf_pkg.g_request_id
                               || ' - '
                               || xx_emf_cn_pkg.cn_success
                               || ' - '
                               || xx_emf_cn_pkg.cn_rec_warn
                              );
         COMMIT;
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand
                             );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            RETURN x_error_code;
      END move_rec_pre_standard_table;

-------------------------------------------------------------------------
-----------< mark_records_for_api_error >-------------------------------
-------------------------------------------------------------------------
      PROCEDURE mark_records_for_api_error (p_process_code VARCHAR2)
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         x_record_count        NUMBER;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside Mark Record for API Error'
                              );

         UPDATE xx_mtl_transactions_pre xmtp
            SET process_code = g_stage,
                ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
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
            AND EXISTS (
                   SELECT 1
                     FROM mtl_transactions_interface mti
                    WHERE mti.source_header_id = xx_emf_pkg.g_request_id
                      AND mti.source_line_id = xmtp.source_line_id
                      AND mti.ERROR_CODE IS NOT NULL);

         x_record_count := SQL%ROWCOUNT;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'No of Record Marked with API Error=>'
                               || x_record_count
                              );
         COMMIT;
      END mark_records_for_api_error;

-------------------------------------------------------------------------
-----------< print_records_with_api_error >-------------------------------
-------------------------------------------------------------------------
      PROCEDURE print_records_with_api_error
      IS
         -- Cursor to select records with API error
         CURSOR cur_print_error_records
         IS
            SELECT mti.source_line_id, mp.organization_code,
                   mti.item_segment1, mti.ERROR_CODE, mti.error_explanation,
                   xmt.record_number
              FROM mtl_transactions_interface mti,
                   mtl_parameters mp,
                   xx_mtl_transactions_pre xmt
             WHERE mti.source_header_id = xx_emf_pkg.g_request_id
               AND mti.organization_id = mp.organization_id
               AND xmt.source_line_id = mti.source_line_id
               AND mti.ERROR_CODE IS NOT NULL;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside print_records_with_api_error'
                              );

         FOR cur_rec IN cur_print_error_records
         LOOP
            xx_emf_pkg.error
                         (p_severity                 => xx_emf_cn_pkg.cn_low,
                          p_category                 => xx_emf_cn_pkg.cn_stg_apicall,
                          p_error_text               =>    cur_rec.ERROR_CODE
                                                        || '-'
                                                        || cur_rec.error_explanation,
                          p_record_identifier_1      => cur_rec.record_number,
                          p_record_identifier_2      => cur_rec.organization_code,
                          p_record_identifier_3      => cur_rec.item_segment1
                         );
         END LOOP;
      END print_records_with_api_error;

-------------------------------------------------------------------------
-----------< process_data >-------------------------------
-------------------------------------------------------------------------
      FUNCTION process_data
         RETURN NUMBER
      IS
         x_error_code                 NUMBER      := xx_emf_cn_pkg.cn_success;
         x_transaction_interface_id   NUMBER;
         x_record_count               NUMBER          := 0;
         x_txns_header_id             NUMBER          := 0;
         x_req_id                     NUMBER          := 0;
         x_phase                      VARCHAR2 (100);
         x_status                     VARCHAR2 (100);
         x_dev_phase                  VARCHAR2 (100);
         x_dev_status                 VARCHAR2 (100);
         x_message                    VARCHAR2 (2000);
         x_req_return_status          BOOLEAN         := FALSE;
         l_tran_temp_id               NUMBER;
 	 x_attribute_cat              VARCHAR2(100) := G_ATTRIBUTE_CAT; -- 27th-Jan-14


         -- cursor to select data from pre interface table
         CURSOR cur_itemonhand_qty
         IS
            SELECT *
              FROM xx_mtl_transactions_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
               AND process_code = xx_emf_cn_pkg.cn_postval;

         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Inside Process Data - '
                               || g_batch_id
                               || ' - '
                               || xx_emf_pkg.g_request_id
                               || ' - '
                               || xx_emf_cn_pkg.cn_success
                               || ' - '
                               || xx_emf_cn_pkg.cn_rec_warn
                               || ' - '
                               || xx_emf_cn_pkg.cn_postval
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Process Data');

         FOR cur_rec IN cur_itemonhand_qty
         LOOP
            x_record_count := x_record_count + 1;
            x_txns_header_id := cur_rec.request_id;

            SELECT apps.mtl_material_transactions_s.NEXTVAL
              INTO x_transaction_interface_id
              FROM DUAL;
              
            IF   cur_rec.lot_number IS NOT NULL  AND cur_rec.fm_serial_number IS NOT NULL  
            THEN
                l_tran_temp_id := x_transaction_interface_id;
            ELSE
                l_tran_temp_id := NULL;
            END IF;
            

            IF cur_rec.lot_number IS NOT NULL 
            THEN
               INSERT INTO mtl_transaction_lots_interface
                           (transaction_interface_id
			    ,source_code
                            ,source_line_id
                            ,SERIAL_TRANSACTION_TEMP_ID			   
			    ,last_update_date
                            ,last_updated_by
			    ,creation_date
                            ,created_by
                            ,lot_number
                            ,transaction_quantity
                            ,lot_expiration_date
			    ,status_id
                            ,process_flag
			    ,attribute15
			    ,origination_date
			    ,LOT_ATTRIBUTE_CATEGORY  -- 27th-Jan-14 - wave1
			    ,place_of_origin
                          )
                    VALUES (x_transaction_interface_id
		            ,cur_rec.source_code
                            ,cur_rec.source_line_id
                            ,l_tran_temp_id
			    ,SYSDATE
			    ,fnd_profile.VALUE ('USER_ID')
			    ,SYSDATE
                            ,fnd_profile.VALUE ('USER_ID')
                            ,cur_rec.lot_number
                            ,cur_rec.mtli_transactions_quantity
                            ,cur_rec.lot_expiration_date
			    ,cur_rec.mtli_status_id
                            ,cur_rec.process_flag
			    ,cur_rec.batch_id
			    ,cur_rec.mtli_origination_date
    			    ,DECODE(cur_rec.mtli_place_of_origin,NULL,NULL,x_attribute_cat)  -- 27th-Jan-14 - wave1
			    ,cur_rec.mtli_place_of_origin
                           );
            END IF;

            IF cur_rec.fm_serial_number IS NOT NULL 
            THEN
               INSERT INTO mtl_serial_numbers_interface
                           (transaction_interface_id
			   ,source_code
                           ,source_line_id
                           ,fm_serial_number
                           ,to_serial_number
			   ,status_name
                           ,last_update_date
			   ,last_updated_by
                           ,creation_date
			   ,created_by
                           ,process_flag
			   ,attribute15
			   ,origination_date
                           )
                    VALUES (x_transaction_interface_id
		            ,cur_rec.source_code
			    ,cur_rec.source_line_id
                            ,cur_rec.fm_serial_number
                            ,cur_rec.to_serial_number
			    ,cur_rec.status_name
                            ,SYSDATE
			    ,fnd_profile.VALUE ('USER_ID')
                            ,SYSDATE
			    ,fnd_profile.VALUE ('USER_ID')
                            ,cur_rec.process_flag
			    ,cur_rec.batch_id
			    ,cur_rec.msni_origination_date
                           );
            END IF;
            

            INSERT INTO mtl_transactions_interface
                (  INVENTORY_ITEM_ID
		  ,ITEM_SEGMENT1
		  ,ITEM_SEGMENT2
		  ,ITEM_SEGMENT3
		  ,ITEM_SEGMENT4
		  ,ITEM_SEGMENT5
		  ,ITEM_SEGMENT6
		  ,ITEM_SEGMENT7
		  ,ITEM_SEGMENT8
		  ,ITEM_SEGMENT9
		  ,ITEM_SEGMENT10
		  ,ITEM_SEGMENT11
		  ,ITEM_SEGMENT12
		  ,ITEM_SEGMENT13
		  ,ITEM_SEGMENT14
		  ,ITEM_SEGMENT15
		  ,ITEM_SEGMENT16
		  ,ITEM_SEGMENT17
		  ,ITEM_SEGMENT18
		  ,ITEM_SEGMENT19
		  ,ITEM_SEGMENT20
		  ,REVISION
		  ,ORGANIZATION_ID
		  ,TRANSACTION_QUANTITY
		  ,PRIMARY_QUANTITY
		  ,TRANSACTION_UOM
		  ,TRANSACTION_DATE
		  ,ACCT_PERIOD_ID
		  ,SUBINVENTORY_CODE
		  ,LOCATOR_ID
		  ,LOC_SEGMENT1
		  ,LOC_SEGMENT2
		  ,LOC_SEGMENT3
		  ,LOC_SEGMENT4
		  ,LOC_SEGMENT5
		  ,LOC_SEGMENT6
		  ,LOC_SEGMENT7
		  ,LOC_SEGMENT8
		  ,LOC_SEGMENT9
		  ,LOC_SEGMENT10
		  ,LOC_SEGMENT11
		  ,LOC_SEGMENT12
		  ,LOC_SEGMENT13
		  ,LOC_SEGMENT14
		  ,LOC_SEGMENT15
		  ,LOC_SEGMENT16
		  ,LOC_SEGMENT17
		  ,LOC_SEGMENT18
		  ,LOC_SEGMENT19
		  ,LOC_SEGMENT20
		  ,TRANSACTION_SOURCE_ID
		  ,DSP_SEGMENT1
		  ,DSP_SEGMENT2
		  ,DSP_SEGMENT3
		  ,DSP_SEGMENT4
		  ,DSP_SEGMENT5
		  ,DSP_SEGMENT6
		  ,DSP_SEGMENT7
		  ,DSP_SEGMENT8
		  ,DSP_SEGMENT9
		  ,DSP_SEGMENT10
		  ,DSP_SEGMENT11
		  ,DSP_SEGMENT12
		  ,DSP_SEGMENT13
		  ,DSP_SEGMENT14
		  ,DSP_SEGMENT15
		  ,DSP_SEGMENT16
		  ,DSP_SEGMENT17
		  ,DSP_SEGMENT18
		  ,DSP_SEGMENT19
		  ,DSP_SEGMENT20
		  ,DSP_SEGMENT21
		  ,DSP_SEGMENT22
		  ,DSP_SEGMENT23
		  ,DSP_SEGMENT24
		  ,DSP_SEGMENT25
		  ,DSP_SEGMENT26
		  ,DSP_SEGMENT27
		  ,DSP_SEGMENT28
		  ,DSP_SEGMENT29
		  ,DSP_SEGMENT30
		  ,TRANSACTION_SOURCE_NAME
		  ,TRANSACTION_SOURCE_TYPE_ID
		  ,TRANSACTION_ACTION_ID
		  ,TRANSACTION_TYPE_ID
		  ,REASON_ID
		  ,TRANSACTION_REFERENCE
		  ,TRANSACTION_COST
		  ,DISTRIBUTION_ACCOUNT_ID
		  ,DST_SEGMENT1
		  ,DST_SEGMENT2
		  ,DST_SEGMENT3
		  ,DST_SEGMENT4
		  ,DST_SEGMENT5
		  ,DST_SEGMENT6
		  ,DST_SEGMENT7
		  ,DST_SEGMENT8
		  ,DST_SEGMENT9
		  ,DST_SEGMENT10
		  ,DST_SEGMENT11
		  ,DST_SEGMENT12
		  ,DST_SEGMENT13
		  ,DST_SEGMENT14
		  ,DST_SEGMENT15
		  ,DST_SEGMENT16
		  ,DST_SEGMENT17
		  ,DST_SEGMENT18
		  ,DST_SEGMENT19
		  ,DST_SEGMENT20
		  ,DST_SEGMENT21
		  ,DST_SEGMENT22
		  ,DST_SEGMENT23
		  ,DST_SEGMENT24
		  ,DST_SEGMENT25
		  ,DST_SEGMENT26
		  ,DST_SEGMENT27
		  ,DST_SEGMENT28
		  ,DST_SEGMENT29
		  ,DST_SEGMENT30
		  ,REQUISITION_LINE_ID
		  ,CURRENCY_CODE
		  ,CURRENCY_CONVERSION_DATE
		  ,CURRENCY_CONVERSION_TYPE
		  ,CURRENCY_CONVERSION_RATE
		  ,USSGL_TRANSACTION_CODE
		  ,WIP_ENTITY_TYPE
		  ,SCHEDULE_ID
		  ,EMPLOYEE_CODE
		  ,DEPARTMENT_ID
		  ,SCHEDULE_UPDATE_CODE
		  ,SETUP_TEARDOWN_CODE
		  ,PRIMARY_SWITCH
		  ,MRP_CODE
		  ,OPERATION_SEQ_NUM
		  ,REPETITIVE_LINE_ID
		  ,PICKING_LINE_ID
		  ,TRX_SOURCE_LINE_ID
		  ,TRX_SOURCE_DELIVERY_ID
		  ,DEMAND_ID
		  ,CUSTOMER_SHIP_ID
		  ,LINE_ITEM_NUM
		  ,RECEIVING_DOCUMENT
		  ,RCV_TRANSACTION_ID
		  ,SHIP_TO_LOCATION_ID
		  ,ENCUMBRANCE_ACCOUNT
		  ,ENCUMBRANCE_AMOUNT
		  ,VENDOR_LOT_NUMBER
		  ,TRANSFER_SUBINVENTORY
		  ,TRANSFER_ORGANIZATION
		  ,TRANSFER_LOCATOR
		  ,XFER_LOC_SEGMENT1
		  ,XFER_LOC_SEGMENT2
		  ,XFER_LOC_SEGMENT3
		  ,XFER_LOC_SEGMENT4
		  ,XFER_LOC_SEGMENT5
		  ,XFER_LOC_SEGMENT6
		  ,XFER_LOC_SEGMENT7
		  ,XFER_LOC_SEGMENT8
		  ,XFER_LOC_SEGMENT9
		  ,XFER_LOC_SEGMENT10
		  ,XFER_LOC_SEGMENT11
		  ,XFER_LOC_SEGMENT12
		  ,XFER_LOC_SEGMENT13
		  ,XFER_LOC_SEGMENT14
		  ,XFER_LOC_SEGMENT15
		  ,XFER_LOC_SEGMENT16
		  ,XFER_LOC_SEGMENT17
		  ,XFER_LOC_SEGMENT18
		  ,XFER_LOC_SEGMENT19
		  ,XFER_LOC_SEGMENT20
		  ,SHIPMENT_NUMBER
		  ,TRANSPORTATION_COST
		  ,TRANSPORTATION_ACCOUNT
		  ,TRANSFER_COST
		  ,FREIGHT_CODE
		  ,CONTAINERS
		  ,WAYBILL_AIRBILL
		  ,EXPECTED_ARRIVAL_DATE
		  ,NEW_AVERAGE_COST
		  ,VALUE_CHANGE
		  ,PERCENTAGE_CHANGE
		  ,DEMAND_SOURCE_HEADER_ID
		  ,DEMAND_SOURCE_LINE
		  ,DEMAND_SOURCE_DELIVERY
		  ,NEGATIVE_REQ_FLAG
		  ,ERROR_EXPLANATION
		  ,SHIPPABLE_FLAG
		  ,ERROR_CODE
		  ,REQUIRED_FLAG
		  ,ATTRIBUTE_CATEGORY
		  ,ATTRIBUTE1
		  ,ATTRIBUTE2
		  ,ATTRIBUTE3
		  ,ATTRIBUTE4
		  ,ATTRIBUTE5
		  ,ATTRIBUTE6
		  ,ATTRIBUTE7
		  ,ATTRIBUTE8
		  ,ATTRIBUTE9
		  ,ATTRIBUTE10
		  ,REQUISITION_DISTRIBUTION_ID
		  ,MOVEMENT_ID
		  ,RESERVATION_QUANTITY
		  ,SHIPPED_QUANTITY
		  ,INVENTORY_ITEM
		  ,LOCATOR_NAME
		  ,TASK_ID
		  ,TO_TASK_ID
		  ,SOURCE_TASK_ID
		  ,PROJECT_ID
		  ,TO_PROJECT_ID
		  ,SOURCE_PROJECT_ID
		  ,PA_EXPENDITURE_ORG_ID
		  ,EXPENDITURE_TYPE
		  ,FINAL_COMPLETION_FLAG
		  ,TRANSFER_PERCENTAGE
		  ,TRANSACTION_SEQUENCE_ID
		  ,MATERIAL_ACCOUNT
		  ,MATERIAL_OVERHEAD_ACCOUNT
		  ,RESOURCE_ACCOUNT
		  ,OUTSIDE_PROCESSING_ACCOUNT
		  ,OVERHEAD_ACCOUNT
		  ,BOM_REVISION
		  ,ROUTING_REVISION
		  ,BOM_REVISION_DATE
		  ,ROUTING_REVISION_DATE
		  ,ALTERNATE_BOM_DESIGNATOR
		  ,ALTERNATE_ROUTING_DESIGNATOR
		  ,ACCOUNTING_CLASS
		  ,DEMAND_CLASS
		  ,PARENT_ID
		  ,SUBSTITUTION_TYPE_ID
		  ,SUBSTITUTION_ITEM_ID
		  ,SCHEDULE_GROUP
		  ,BUILD_SEQUENCE
		  ,SCHEDULE_NUMBER
		  ,SCHEDULED_FLAG
		  ,FLOW_SCHEDULE
		  ,COST_GROUP_ID
		  ,KANBAN_CARD_ID
		  ,QA_COLLECTION_ID
		  ,OVERCOMPLETION_TRANSACTION_QTY
		  ,OVERCOMPLETION_PRIMARY_QTY
		  ,OVERCOMPLETION_TRANSACTION_ID
		  ,END_ITEM_UNIT_NUMBER
		  ,SCHEDULED_PAYBACK_DATE
		  ,ORG_COST_GROUP_ID
		  ,COST_TYPE_ID
		  ,SOURCE_LOT_NUMBER
		  ,TRANSFER_COST_GROUP_ID
		  ,LPN_ID
		  ,TRANSFER_LPN_ID
		  ,CONTENT_LPN_ID
		  ,XML_DOCUMENT_ID
		  ,ORGANIZATION_TYPE
		  ,TRANSFER_ORGANIZATION_TYPE
		  ,OWNING_ORGANIZATION_ID
		  ,OWNING_TP_TYPE
		  ,XFR_OWNING_ORGANIZATION_ID
		  ,TRANSFER_OWNING_TP_TYPE
		  ,PLANNING_ORGANIZATION_ID
		  ,PLANNING_TP_TYPE
		  ,XFR_PLANNING_ORGANIZATION_ID
		  ,TRANSFER_PLANNING_TP_TYPE
		  ,SECONDARY_UOM_CODE
		  ,SECONDARY_TRANSACTION_QUANTITY
		  ,TRANSACTION_GROUP_ID
		  ,TRANSACTION_GROUP_SEQ
		  ,REPRESENTATIVE_LOT_NUMBER
		  ,TRANSACTION_BATCH_ID
		  ,TRANSACTION_BATCH_SEQ
		  ,REBUILD_ITEM_ID
		  ,REBUILD_SERIAL_NUMBER
		  ,REBUILD_ACTIVITY_ID
		  ,REBUILD_JOB_NAME
		  ,MOVE_TRANSACTION_ID
		  ,COMPLETION_TRANSACTION_ID
		  ,WIP_SUPPLY_TYPE
		  ,RELIEVE_RESERVATIONS_FLAG
		  ,RELIEVE_HIGH_LEVEL_RSV_FLAG
		  ,TRANSFER_PRICE
		  ,CREATION_DATE
		  ,CREATED_BY
		  ,LAST_UPDATE_DATE
		  ,LAST_UPDATED_BY
		  ,ATTRIBUTE15
		  ,PROCESS_FLAG
		  ,TRANSACTION_MODE
		  ,LAST_UPDATE_LOGIN
		  ,SOURCE_CODE
		  ,SOURCE_LINE_ID
		  ,SOURCE_HEADER_ID
		  ,TRANSACTION_INTERFACE_ID
		  ,TRANSACTION_HEADER_ID
		)
	  VALUES (cur_rec.INVENTORY_ITEM_ID
		  ,cur_rec.ITEM_SEGMENT1
		  ,cur_rec.ITEM_SEGMENT2
		  ,cur_rec.ITEM_SEGMENT3
		  ,cur_rec.ITEM_SEGMENT4
		  ,cur_rec.ITEM_SEGMENT5
		  ,cur_rec.ITEM_SEGMENT6
		  ,cur_rec.ITEM_SEGMENT7
		  ,cur_rec.ITEM_SEGMENT8
		  ,cur_rec.ITEM_SEGMENT9
		  ,cur_rec.ITEM_SEGMENT10
		  ,cur_rec.ITEM_SEGMENT11
		  ,cur_rec.ITEM_SEGMENT12
		  ,cur_rec.ITEM_SEGMENT13
		  ,cur_rec.ITEM_SEGMENT14
		  ,cur_rec.ITEM_SEGMENT15
		  ,cur_rec.ITEM_SEGMENT16
		  ,cur_rec.ITEM_SEGMENT17
		  ,cur_rec.ITEM_SEGMENT18
		  ,cur_rec.ITEM_SEGMENT19
		  ,cur_rec.ITEM_SEGMENT20
		  ,cur_rec.REVISION
		  ,cur_rec.ORGANIZATION_ID
		  ,cur_rec.TRANSACTION_QUANTITY
		  ,cur_rec.PRIMARY_QUANTITY
		  ,cur_rec.TRANSACTION_UOM
		  ,cur_rec.TRANSACTION_DATE
		  ,cur_rec.ACCT_PERIOD_ID
		  ,cur_rec.SUBINVENTORY_CODE
		  ,cur_rec.LOCATOR_ID
		  ,cur_rec.LOC_SEGMENT1
		  ,cur_rec.LOC_SEGMENT2
		  ,cur_rec.LOC_SEGMENT3
		  ,cur_rec.LOC_SEGMENT4
		  ,cur_rec.LOC_SEGMENT5
		  ,cur_rec.LOC_SEGMENT6
		  ,cur_rec.LOC_SEGMENT7
		  ,cur_rec.LOC_SEGMENT8
		  ,cur_rec.LOC_SEGMENT9
		  ,cur_rec.LOC_SEGMENT10
		  ,cur_rec.LOC_SEGMENT11
		  ,cur_rec.LOC_SEGMENT12
		  ,cur_rec.LOC_SEGMENT13
		  ,cur_rec.LOC_SEGMENT14
		  ,cur_rec.LOC_SEGMENT15
		  ,cur_rec.LOC_SEGMENT16
		  ,cur_rec.LOC_SEGMENT17
		  ,cur_rec.LOC_SEGMENT18
		  ,cur_rec.LOC_SEGMENT19
		  ,cur_rec.LOC_SEGMENT20
		  ,cur_rec.TRANSACTION_SOURCE_ID
		  ,cur_rec.DSP_SEGMENT1
		  ,cur_rec.DSP_SEGMENT2
		  ,cur_rec.DSP_SEGMENT3
		  ,cur_rec.DSP_SEGMENT4
		  ,cur_rec.DSP_SEGMENT5
		  ,cur_rec.DSP_SEGMENT6
		  ,cur_rec.DSP_SEGMENT7
		  ,cur_rec.DSP_SEGMENT8
		  ,cur_rec.DSP_SEGMENT9
		  ,cur_rec.DSP_SEGMENT10
		  ,cur_rec.DSP_SEGMENT11
		  ,cur_rec.DSP_SEGMENT12
		  ,cur_rec.DSP_SEGMENT13
		  ,cur_rec.DSP_SEGMENT14
		  ,cur_rec.DSP_SEGMENT15
		  ,cur_rec.DSP_SEGMENT16
		  ,cur_rec.DSP_SEGMENT17
		  ,cur_rec.DSP_SEGMENT18
		  ,cur_rec.DSP_SEGMENT19
		  ,cur_rec.DSP_SEGMENT20
		  ,cur_rec.DSP_SEGMENT21
		  ,cur_rec.DSP_SEGMENT22
		  ,cur_rec.DSP_SEGMENT23
		  ,cur_rec.DSP_SEGMENT24
		  ,cur_rec.DSP_SEGMENT25
		  ,cur_rec.DSP_SEGMENT26
		  ,cur_rec.DSP_SEGMENT27
		  ,cur_rec.DSP_SEGMENT28
		  ,cur_rec.DSP_SEGMENT29
		  ,cur_rec.DSP_SEGMENT30
		  ,cur_rec.TRANSACTION_SOURCE_NAME
		  ,cur_rec.TRANSACTION_SOURCE_TYPE_ID
		  ,cur_rec.TRANSACTION_ACTION_ID
		  ,cur_rec.TRANSACTION_TYPE_ID
		  ,cur_rec.REASON_ID
		  ,cur_rec.TRANSACTION_REFERENCE
		  ,cur_rec.TRANSACTION_COST
		  ,cur_rec.DISTRIBUTION_ACCOUNT_ID
		  ,cur_rec.DST_SEGMENT1
		  ,cur_rec.DST_SEGMENT2
		  ,cur_rec.DST_SEGMENT3
		  ,cur_rec.DST_SEGMENT4
		  ,cur_rec.DST_SEGMENT5
		  ,cur_rec.DST_SEGMENT6
		  ,cur_rec.DST_SEGMENT7
		  ,cur_rec.DST_SEGMENT8
		  ,cur_rec.DST_SEGMENT9
		  ,cur_rec.DST_SEGMENT10
		  ,cur_rec.DST_SEGMENT11
		  ,cur_rec.DST_SEGMENT12
		  ,cur_rec.DST_SEGMENT13
		  ,cur_rec.DST_SEGMENT14
		  ,cur_rec.DST_SEGMENT15
		  ,cur_rec.DST_SEGMENT16
		  ,cur_rec.DST_SEGMENT17
		  ,cur_rec.DST_SEGMENT18
		  ,cur_rec.DST_SEGMENT19
		  ,cur_rec.DST_SEGMENT20
		  ,cur_rec.DST_SEGMENT21
		  ,cur_rec.DST_SEGMENT22
		  ,cur_rec.DST_SEGMENT23
		  ,cur_rec.DST_SEGMENT24
		  ,cur_rec.DST_SEGMENT25
		  ,cur_rec.DST_SEGMENT26
		  ,cur_rec.DST_SEGMENT27
		  ,cur_rec.DST_SEGMENT28
		  ,cur_rec.DST_SEGMENT29
		  ,cur_rec.DST_SEGMENT30
		  ,cur_rec.REQUISITION_LINE_ID
		  ,cur_rec.CURRENCY_CODE
		  ,cur_rec.CURRENCY_CONVERSION_DATE
		  ,cur_rec.CURRENCY_CONVERSION_TYPE
		  ,cur_rec.CURRENCY_CONVERSION_RATE
		  ,cur_rec.USSGL_TRANSACTION_CODE
		  ,cur_rec.WIP_ENTITY_TYPE
		  ,cur_rec.SCHEDULE_ID
		  ,cur_rec.EMPLOYEE_CODE
		  ,cur_rec.DEPARTMENT_ID
		  ,cur_rec.SCHEDULE_UPDATE_CODE
		  ,cur_rec.SETUP_TEARDOWN_CODE
		  ,cur_rec.PRIMARY_SWITCH
		  ,cur_rec.MRP_CODE
		  ,cur_rec.OPERATION_SEQ_NUM
		  ,cur_rec.REPETITIVE_LINE_ID
		  ,cur_rec.PICKING_LINE_ID
		  ,cur_rec.TRX_SOURCE_LINE_ID
		  ,cur_rec.TRX_SOURCE_DELIVERY_ID
		  ,cur_rec.DEMAND_ID
		  ,cur_rec.CUSTOMER_SHIP_ID
		  ,cur_rec.LINE_ITEM_NUM
		  ,cur_rec.RECEIVING_DOCUMENT
		  ,cur_rec.RCV_TRANSACTION_ID
		  ,cur_rec.SHIP_TO_LOCATION_ID
		  ,cur_rec.ENCUMBRANCE_ACCOUNT
		  ,cur_rec.ENCUMBRANCE_AMOUNT
		  ,cur_rec.VENDOR_LOT_NUMBER
		  ,cur_rec.TRANSFER_SUBINVENTORY
		  ,cur_rec.TRANSFER_ORGANIZATION
		  ,cur_rec.TRANSFER_LOCATOR
		  ,cur_rec.XFER_LOC_SEGMENT1
		  ,cur_rec.XFER_LOC_SEGMENT2
		  ,cur_rec.XFER_LOC_SEGMENT3
		  ,cur_rec.XFER_LOC_SEGMENT4
		  ,cur_rec.XFER_LOC_SEGMENT5
		  ,cur_rec.XFER_LOC_SEGMENT6
		  ,cur_rec.XFER_LOC_SEGMENT7
		  ,cur_rec.XFER_LOC_SEGMENT8
		  ,cur_rec.XFER_LOC_SEGMENT9
		  ,cur_rec.XFER_LOC_SEGMENT10
		  ,cur_rec.XFER_LOC_SEGMENT11
		  ,cur_rec.XFER_LOC_SEGMENT12
		  ,cur_rec.XFER_LOC_SEGMENT13
		  ,cur_rec.XFER_LOC_SEGMENT14
		  ,cur_rec.XFER_LOC_SEGMENT15
		  ,cur_rec.XFER_LOC_SEGMENT16
		  ,cur_rec.XFER_LOC_SEGMENT17
		  ,cur_rec.XFER_LOC_SEGMENT18
		  ,cur_rec.XFER_LOC_SEGMENT19
		  ,cur_rec.XFER_LOC_SEGMENT20
		  ,cur_rec.SHIPMENT_NUMBER
		  ,cur_rec.TRANSPORTATION_COST
		  ,cur_rec.TRANSPORTATION_ACCOUNT
		  ,cur_rec.TRANSFER_COST
		  ,cur_rec.FREIGHT_CODE
		  ,cur_rec.CONTAINERS
		  ,cur_rec.WAYBILL_AIRBILL
		  ,cur_rec.EXPECTED_ARRIVAL_DATE
		  ,cur_rec.NEW_AVERAGE_COST
		  ,cur_rec.VALUE_CHANGE
		  ,cur_rec.PERCENTAGE_CHANGE
		  ,cur_rec.DEMAND_SOURCE_HEADER_ID
		  ,cur_rec.DEMAND_SOURCE_LINE
		  ,cur_rec.DEMAND_SOURCE_DELIVERY
		  ,cur_rec.NEGATIVE_REQ_FLAG
		  ,cur_rec.ERROR_EXPLANATION
		  ,cur_rec.SHIPPABLE_FLAG
		  ,cur_rec.ERROR_CODE
		  ,cur_rec.REQUIRED_FLAG
		  ,cur_rec.ATTRIBUTE_CATEGORY
		  ,cur_rec.ATTRIBUTE1
		  ,cur_rec.ATTRIBUTE2
		  ,cur_rec.ATTRIBUTE3
		  ,cur_rec.ATTRIBUTE4
		  ,cur_rec.ATTRIBUTE5
		  ,cur_rec.ATTRIBUTE6
		  ,cur_rec.ATTRIBUTE7
		  ,cur_rec.ATTRIBUTE8
		  ,cur_rec.ATTRIBUTE9
		  ,cur_rec.ATTRIBUTE10
		  ,cur_rec.REQUISITION_DISTRIBUTION_ID
		  ,cur_rec.MOVEMENT_ID
		  ,cur_rec.RESERVATION_QUANTITY
		  ,cur_rec.SHIPPED_QUANTITY
		  ,cur_rec.INVENTORY_ITEM
		  ,cur_rec.LOCATOR_NAME
		  ,cur_rec.TASK_ID
		  ,cur_rec.TO_TASK_ID
		  ,cur_rec.SOURCE_TASK_ID
		  ,cur_rec.PROJECT_ID
		  ,cur_rec.TO_PROJECT_ID
		  ,cur_rec.SOURCE_PROJECT_ID
		  ,cur_rec.PA_EXPENDITURE_ORG_ID
		  ,cur_rec.EXPENDITURE_TYPE
		  ,cur_rec.FINAL_COMPLETION_FLAG
		  ,cur_rec.TRANSFER_PERCENTAGE
		  ,cur_rec.TRANSACTION_SEQUENCE_ID
		  ,cur_rec.MATERIAL_ACCOUNT
		  ,cur_rec.MATERIAL_OVERHEAD_ACCOUNT
		  ,cur_rec.RESOURCE_ACCOUNT
		  ,cur_rec.OUTSIDE_PROCESSING_ACCOUNT
		  ,cur_rec.OVERHEAD_ACCOUNT
		  ,cur_rec.BOM_REVISION
		  ,cur_rec.ROUTING_REVISION
		  ,cur_rec.BOM_REVISION_DATE
		  ,cur_rec.ROUTING_REVISION_DATE
		  ,cur_rec.ALTERNATE_BOM_DESIGNATOR
		  ,cur_rec.ALTERNATE_ROUTING_DESIGNATOR
		  ,cur_rec.ACCOUNTING_CLASS
		  ,cur_rec.DEMAND_CLASS
		  ,cur_rec.PARENT_ID
		  ,cur_rec.SUBSTITUTION_TYPE_ID
		  ,cur_rec.SUBSTITUTION_ITEM_ID
		  ,cur_rec.SCHEDULE_GROUP
		  ,cur_rec.BUILD_SEQUENCE
		  ,cur_rec.SCHEDULE_NUMBER
		  ,cur_rec.SCHEDULED_FLAG
		  ,cur_rec.FLOW_SCHEDULE
		  ,cur_rec.COST_GROUP_ID
		  ,cur_rec.KANBAN_CARD_ID
		  ,cur_rec.QA_COLLECTION_ID
		  ,cur_rec.OVERCOMPLETION_TRANSACTION_QTY
		  ,cur_rec.OVERCOMPLETION_PRIMARY_QTY
                  ,cur_rec.OVERCOMPLETION_TRANSACTION_ID
		  ,cur_rec.END_ITEM_UNIT_NUMBER
		  ,cur_rec.SCHEDULED_PAYBACK_DATE
		  ,cur_rec.ORG_COST_GROUP_ID
		  ,cur_rec.COST_TYPE_ID
		  ,cur_rec.SOURCE_LOT_NUMBER
		  ,cur_rec.TRANSFER_COST_GROUP_ID
		  ,cur_rec.LPN_ID
		  ,cur_rec.TRANSFER_LPN_ID
		  ,cur_rec.CONTENT_LPN_ID
		  ,cur_rec.XML_DOCUMENT_ID
		  ,cur_rec.ORGANIZATION_TYPE
		  ,cur_rec.TRANSFER_ORGANIZATION_TYPE
		  ,cur_rec.MTI_OWNING_ORGANIZATION_ID
		  ,cur_rec.OWNING_TP_TYPE
		  ,cur_rec.XFR_OWNING_ORGANIZATION_ID
		  ,cur_rec.TRANSFER_OWNING_TP_TYPE
		  ,cur_rec.PLANNING_ORGANIZATION_ID
		  ,cur_rec.PLANNING_TP_TYPE
		  ,cur_rec.XFR_PLANNING_ORGANIZATION_ID
		  ,cur_rec.TRANSFER_PLANNING_TP_TYPE
		  ,cur_rec.SECONDARY_UOM_CODE
		  ,cur_rec.SECONDARY_TRANSACTION_QUANTITY
		  ,cur_rec.TRANSACTION_GROUP_ID
		  ,cur_rec.TRANSACTION_GROUP_SEQ
		  ,cur_rec.REPRESENTATIVE_LOT_NUMBER
		  ,cur_rec.TRANSACTION_BATCH_ID
		  ,cur_rec.TRANSACTION_BATCH_SEQ
		  ,cur_rec.REBUILD_ITEM_ID
		  ,cur_rec.REBUILD_SERIAL_NUMBER
		  ,cur_rec.REBUILD_ACTIVITY_ID
		  ,cur_rec.REBUILD_JOB_NAME
		  ,cur_rec.MOVE_TRANSACTION_ID
		  ,cur_rec.COMPLETION_TRANSACTION_ID
		  ,cur_rec.WIP_SUPPLY_TYPE
		  ,cur_rec.RELIEVE_RESERVATIONS_FLAG
		  ,cur_rec.RELIEVE_HIGH_LEVEL_RSV_FLAG
		  ,cur_rec.TRANSFER_PRICE
		  ,cur_rec.CREATION_DATE
		  ,cur_rec.CREATED_BY
		  ,cur_rec.LAST_UPDATE_DATE
		  ,cur_rec.LAST_UPDATED_BY
		  ,cur_rec.BATCH_ID
		  ,cur_rec.PROCESS_FLAG
		  ,cur_rec.TRANSACTION_MODE
		  ,cur_rec.LAST_UPDATE_LOGIN
		  ,cur_rec.SOURCE_CODE
		  ,cur_rec.SOURCE_LINE_ID
		  ,cur_rec.SOURCE_HEADER_ID
		  ,X_TRANSACTION_INTERFACE_ID
		  ,cur_rec.REQUEST_ID
		  );
         END LOOP;

         xx_emf_pkg.write_log
               (xx_emf_cn_pkg.cn_low,
                   'No of Records Uploaded into MTL_TRANSACTIONS_INTERFACE =>'
                || x_record_count
               );
         COMMIT;

        -- Commented as Schedulled Program to be submitted manually.
        /* IF x_record_count > 0
         THEN
            --SUBMIT the Inventory Transaction Worker to process the record--
            x_req_id := fnd_request.submit_request
                       ('INV'                                   -- application name
                        ,'INCTCW'                               -- concurrent program short name
                        ,''                                     -- description
                        ,NULL                                   -- start time
                        ,FALSE                                  -- sub_program Call
                        ,x_txns_header_id                       -- 1st parameter : transaction header id
                        ,1                                      -- 2nd parameter '1' :MTL_TRANSACTIONS_INTERFACE, '2' : MTL_MATERIAL_TRANSACTIONS_TEMP)
                        ,''                                     -- 3rd parameter source_header_id
                        ,''                                     -- 4th parameter : source code
                        ,CHR (0)                                -- parameter input end Mark
                       );
            COMMIT;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Req id for Transaction Worker Submit =>'
                                  || x_req_id
                                 );

            IF x_req_id > 0
            THEN
               xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                              'Inventory Transaction Worker Submit =>SUCCESS'
                             );
               x_req_return_status :=
                  fnd_concurrent.wait_for_request (request_id      => x_req_id,
                                                   INTERVAL        => 10,
                                                   max_wait        => 600,
                                                   phase           => x_phase,
                                                   status          => x_status,
                                                   dev_phase       => x_dev_phase,
                                                   dev_status      => x_dev_status,
                                                   MESSAGE         => x_message
                                                  );

               IF x_req_return_status = TRUE
               THEN
                  xx_emf_pkg.write_log
                              (xx_emf_cn_pkg.cn_low,
                                  'Inventory Transaction Worker Completed =>'
                               || x_dev_status
                              );
                  mark_records_for_api_error (xx_emf_cn_pkg.cn_process_data);
                  -- Print the records with API Error
                  print_records_with_api_error;
                  x_error_code := xx_emf_cn_pkg.cn_success;
               END IF;
            ELSE
               xx_emf_pkg.write_log
                              (xx_emf_cn_pkg.cn_low,
                               'Error in Inventory Transaction Worker Submit'
                              );
               x_error_code := xx_emf_cn_pkg.cn_prc_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_high,
                   p_category                 => xx_emf_cn_pkg.cn_stg_apicall,
                   p_error_text               => 'Error in Inventory Transaction Worker Submit',
                   p_record_identifier_1      => 'Process level error : Exiting'
                  );
            END IF;
         END IF;    */
-- Commented as Schedulled Program to be submitted manually.
         RETURN x_error_code;
      END process_data;

-------------------------------------------------------------------------
-----------< update_record_count >-------------------------------
-------------------------------------------------------------------------
      PROCEDURE update_record_count
      IS
         -- Cursor to count the total number of records in staging table.
         CURSOR c_get_total_cnt
         IS
            SELECT COUNT (1) total_count
              FROM xx_mtl_transactions_stg
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id;

         x_total_cnt     NUMBER;

           -- cursor to count the total number of error record
         CURSOR c_get_error_cnt
         IS
            SELECT SUM (error_count)
              FROM (SELECT COUNT (1) error_count
                      FROM xx_mtl_transactions_stg
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err
                    UNION ALL
                    SELECT COUNT (1) error_count
                      FROM xx_mtl_transactions_pre
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err);

         x_error_cnt     NUMBER;

              -- cursor to count total number of warning record.
         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_mtl_transactions_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

         x_warn_cnt      NUMBER;

               -- cursor to count total number of success record.
         CURSOR c_get_success_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_mtl_transactions_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
              -- AND process_code = xx_emf_cn_pkg.cn_process_data
	      AND (p_validate_and_load= g_validate_and_load and process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                                OR 1=1 and process_code = xx_emf_cn_pkg.CN_DERIVE)
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
      END;
   BEGIN
      retcode := xx_emf_cn_pkg.cn_success;
      -- Need to maintain the version on the files.
              -- when updating the package remember to incrimint the version such that it can be checked in the log file from front end.
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxintgcnvvl_pks);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxintgcnvvl_pkb);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxintgcnvtl_pks);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxintgcnvtl_pkb);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxintgcnvt1_tbl);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxintgcnvt1_syn);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxintgcnvt2_tbl);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxintgcnvt2_syn);
      -- Set environment for EMF (Error Management Framework)
      -- If you want the process to continue even after the emf env not being set
      -- you must make p_required_flag from CN_YES to CN_NO
      -- If you do not pass proper value then it will be considered as CN_YES
      set_cnv_env (p_batch_id           => p_batch_id,
                   p_required_flag      => xx_emf_cn_pkg.cn_yes
                  );
      -- include all the parameters to the conversion main here
      -- as medium log messages
      xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_medium,
                         'Starting main process with the following parameters'
                        );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_batch_id ' || p_batch_id
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_restart_flag ' || p_restart_flag
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_override_flag ' || p_override_flag
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'Main:Param - p_validate_and_load '
                            || p_validate_and_load
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'Main:Param - p_transaction_type_name '
                            || p_transaction_type_name
                           );
      -- Call procedure to update records with the current request_id
      -- So that we can process only those records
      -- This gives a better handling of restartability
      mark_records_for_processing (p_restart_flag       => p_restart_flag,
                                   p_override_flag      => p_override_flag
                                  );

      /*Assigning Global Variables using Process Setup Paramters*/
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'Assigning Global Variables using Process Setup Paramters..');
         assign_global_var;
      -- Once the records are identified based on the input parameters
      -- Start with pre-validations
      IF NVL (p_override_flag, xx_emf_cn_pkg.cn_no) = xx_emf_cn_pkg.cn_no
      THEN
         -- Set the stage to Pre Validations
         set_stage (xx_emf_cn_pkg.cn_preval);
         x_error_code := xx_inv_item_onhandval_pkg.pre_validations;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                  'After pre-validations X_ERROR_CODE '
                               || x_error_code
                              );
         -- Update process code of staging records
         -- Also move the successful records to pre-interface tables
         update_staging_records (xx_emf_cn_pkg.cn_success);
         xx_emf_pkg.propagate_error (x_error_code);
         x_error_code := move_rec_pre_standard_table;
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;

      -- Once pre-validations are complete the loop through the pre-interface records
      -- and perform data validations on this table
      -- Set the stage to data Validations
      set_stage (xx_emf_cn_pkg.cn_valid);

      OPEN c_xx_intg_pre_std_hdr (xx_emf_cn_pkg.cn_preval);

      LOOP
         FETCH c_xx_intg_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_medium,
                             'Starting testing with the following parameters'
                            );
               -- Perform header level Base App Validations
               x_error_code :=
                  xx_inv_item_onhandval_pkg.data_validations(x_pre_std_hdr_table(i));
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'x_error_code for  '
                                     || x_pre_std_hdr_table (i).record_number
                                     || ' is '
                                     || x_error_code
                                    );
               update_record_status (x_pre_std_hdr_table (i), x_error_code);
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
                  update_pre_interface_records (x_pre_std_hdr_table);
                  raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
               WHEN OTHERS
               THEN
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    xx_emf_cn_pkg.cn_exp_unhand,
                                    x_pre_std_hdr_table (i).record_number
                                   );
            END;
         END LOOP;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'x_pre_std_hdr_table.count '
                               || x_pre_std_hdr_table.COUNT
                              );
         update_pre_interface_records (x_pre_std_hdr_table);
         x_pre_std_hdr_table.DELETE;
         EXIT WHEN c_xx_intg_pre_std_hdr%NOTFOUND;
      END LOOP;

      IF c_xx_intg_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_intg_pre_std_hdr;
      END IF;

      -- Once data-validations are complete the loop through the pre-interface records
       -- and perform data derivations on this table
       -- Set the stage to data derivations
      set_stage (xx_emf_cn_pkg.cn_derive);

      OPEN c_xx_intg_pre_std_hdr (xx_emf_cn_pkg.cn_valid);

      LOOP
         FETCH c_xx_intg_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               -- Perform header level Base App Validations
               x_error_code :=
                  xx_inv_item_onhandval_pkg.data_derivations
                                                      (x_pre_std_hdr_table (i)
                                                      );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'x_error_code for  '
                                     || x_pre_std_hdr_table (i).record_number
                                     || ' is '
                                     || x_error_code
                                    );
               update_record_status (x_pre_std_hdr_table (i), x_error_code);
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
                  update_pre_interface_records (x_pre_std_hdr_table);
                  raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
               WHEN OTHERS
               THEN
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    xx_emf_cn_pkg.cn_exp_unhand,
                                    x_pre_std_hdr_table (i).record_number
                                   );
            END;
         END LOOP;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'x_pre_std_hdr_table.count '
                               || x_pre_std_hdr_table.COUNT
                              );
         update_pre_interface_records (x_pre_std_hdr_table);
         x_pre_std_hdr_table.DELETE;
         EXIT WHEN c_xx_intg_pre_std_hdr%NOTFOUND;
      END LOOP;

      IF c_xx_intg_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_intg_pre_std_hdr;
      END IF;

-- Perform data derivations and process data only if p_validate_only_flag is set to VALIDATE_AND_LOAD
      IF p_validate_and_load = g_validate_and_load
      THEN
         -- Set the stage to Post Validations
         set_stage (xx_emf_cn_pkg.cn_postval);
         x_error_code := xx_inv_item_onhandval_pkg.post_validations;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                  'After post-validations X_ERROR_CODE '
                               || x_error_code
                              );
         mark_records_complete (xx_emf_cn_pkg.cn_postval);
         xx_emf_pkg.propagate_error (x_error_code);
         -- Set the stage to Process data
         set_stage (xx_emf_cn_pkg.cn_process_data);
         x_error_code := process_data;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                  'After Process Data X_ERROR_CODE '
                               || x_error_code
                              );
         mark_records_complete (xx_emf_cn_pkg.cn_process_data);
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;

      update_record_count;
      xx_emf_pkg.create_report;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Checking if this is OK');
         fnd_file.put_line (fnd_file.output, xx_emf_pkg.cn_env_not_set);
         retcode := xx_emf_cn_pkg.cn_rec_err;
         update_record_count;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         retcode := xx_emf_cn_pkg.cn_rec_err;
         update_record_count;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         retcode := xx_emf_cn_pkg.cn_prc_err;
         update_record_count;
         xx_emf_pkg.create_report;
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Unhandled Exception=>' || SQLERRM
                              );
         retcode := xx_emf_cn_pkg.cn_prc_err;
         update_record_count;
         xx_emf_pkg.create_report;
   END main;
END xx_inv_itemonhandqty_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_ITEMONHANDQTY_PKG TO INTG_XX_NONHR_RO;
