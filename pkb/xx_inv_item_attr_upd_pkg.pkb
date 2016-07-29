DROP PACKAGE BODY APPS.XX_INV_ITEM_ATTR_UPD_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xx_inv_item_attr_upd_pkg AS
/* $Header: XXINVITEMATTRUPDEXT.pkb 1.0.0 2012/05/04 00:00:00 ibm noship $ */
--==================================================================================
  -- Created By     : Partha S Mohanty
  -- Creation Date  : 2012/05/04
  -- Filename       : XXINVITEMATTRUPDEXT.pkb
  -- Description    : Package body for Item attributes update

  -- Change History:

  -- Date        Version#    Name                Remarks
  -- ----------- --------    ---------------     ------------------------------------
  -- 04-May-2012   1.0       Partha S Mohanty    Initial development.
  -- 31-Mar-2015   1.1       Dharanidharan       Code Changes for FS4.0
--====================================================================================
   --Main Procedure Section
   -------------------------------------------------------------------------------------------------------------------------
   g_request_id NUMBER := fnd_profile.VALUE('CONC_REQUEST_ID');

   g_user_id NUMBER := fnd_global.user_id; --fnd_profile.VALUE('USER_ID');

   g_resp_id NUMBER := fnd_profile.VALUE('RESP_ID');

   g_req_id_mast     NUMBER; -- Change on 11-OCT-2012

   g_req_id_org      NUMBER; -- Change on 11-OCT-2012

   g_req_id_assign   NUMBER; -- Change on 11-OCT-2012
------------------< set_cnv_env >-----------------------------------------------
--------------------------------------------------------------------------------
    PROCEDURE set_cnv_env (p_batch_id      VARCHAR2
                          ,p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES
                          ,p_batch_flag    VARCHAR2
                          ) IS
    	x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
    	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside set_cnv_env...');
    	IF p_batch_flag = 'ITEM_MAST' THEN
    		G_MAST_BATCH_ID	  := p_batch_id;
    		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_MAST_BATCH_ID: '||G_MAST_BATCH_ID );
    	ELSIF p_batch_flag = 'ITEM_ORG' THEN
    		G_ORG_BATCH_ID   := p_batch_id;
    		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_ORG_BATCH_ID: '||G_ORG_BATCH_ID );
      ELSIF p_batch_flag = 'ITEM_ASSGN' THEN
    		G_ASSGN_BATCH_ID   := p_batch_id;
    		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_ASSGN_BATCH_ID: '||G_ORG_BATCH_ID );
    	END IF;

    	-- Set the environment
    	x_error_code := xx_emf_pkg.set_env;
    	IF NVL (p_required_flag, xx_emf_cn_pkg.CN_YES) <> xx_emf_cn_pkg.CN_NO THEN
    		xx_emf_pkg.propagate_error(x_error_code);
    	END IF;
    EXCEPTION
    	WHEN OTHERS THEN
    		RAISE xx_emf_pkg.G_E_ENV_NOT_SET;
    END set_cnv_env;

   PROCEDURE dbg_low (p_dbg_text varchar2)
      IS
      BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low
                                , 'In xx_inv_item_attr_upd_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_low;

    PROCEDURE dbg_med (p_dbg_text varchar2)
      IS
      BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium
                                , 'In xx_inv_item_attr_upd_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_med;

   PROCEDURE dbg_high (p_dbg_text varchar2)
      IS
      BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high
                                , 'In xx_inv_item_attr_upd_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_high;

-- create_for_assignment
   PROCEDURE create_table_for_assignment
   IS
    	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
    	-- If the override is set records should not be purged from the pre-interface tables
      g_api_name := 'create_tabble_for_assignment';
    	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside of mark create_tabble_for_assignment...');


    	INSERT INTO xx_item_org_assign_stg(ITEM_NUMBER,
                                         ORGANIZATION_CODE,
                                         BATCH_ID,
                                         RECORD_NUMBER,
                                         REQUEST_ID,
                                         error_code,
                                         process_code,
                                         error_mesg
                                         )
                              SELECT ITEM_NUMBER,
                                     ORGANIZATION_CODE,
                                     BATCH_ID,
                                     RECORD_NUMBER,
                                     REQUEST_ID,
                                     error_code,
                                     process_code,
                                     error_mesg
                                     FROM xx_item_org_attr_upd_stg
                                   WHERE batch_id = G_ORG_BATCH_ID
                                     AND request_id = xx_emf_pkg.G_REQUEST_ID;
    			                         --  AND error_code = xx_emf_cn_pkg.CN_NULL
    			                         --  AND process_code = xx_emf_cn_pkg.CN_NEW;

       COMMIT;
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'End of mark create_tabble_for_assignment...');
    EXCEPTION
        WHEN OTHERS THEN
	        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while mark create_tabble_for_assignments: '||SQLERRM);
    END create_table_for_assignment;

------------------< mark_records_for_processing >-------------------------------
--------------------------------------------------------------------------------

    PROCEDURE mark_records_for_processing (p_restart_flag  IN VARCHAR2,
                                           p_mast_attr     IN VARCHAR2,
                                           p_org_attr 	   IN VARCHAR2,
                                           p_org_assgn     IN VARCHAR2
                                          ) IS
    	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
    	-- If the override is set records should not be purged from the pre-interface tables
      g_api_name := 'mark_records_for_processing';
    	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside of mark records for processing...');

    	IF p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS THEN

    		IF UPPER(TRIM(p_mast_attr)) = G_YES THEN
        	UPDATE xx_item_mast_attr_upd_stg
    			   SET request_id = xx_emf_pkg.G_REQUEST_ID,
    			       error_code = xx_emf_cn_pkg.CN_NULL,
    			       process_code = xx_emf_cn_pkg.CN_NEW,
                 error_mesg = NULL
    			 WHERE batch_id = G_MAST_BATCH_ID;
         END IF;

    		IF (UPPER(TRIM(p_org_attr)) = G_YES OR UPPER(TRIM(p_org_assgn)) = G_YES) THEN
        	UPDATE xx_item_org_attr_upd_stg
    			   SET request_id = xx_emf_pkg.G_REQUEST_ID,
    			       error_code = xx_emf_cn_pkg.CN_NULL,
    			       process_code = xx_emf_cn_pkg.CN_NEW,
                 error_mesg = NULL
    			 WHERE batch_id = G_ORG_BATCH_ID;
         END IF;
           /*UPDATE xx_item_org_assign_stg
    			   SET request_id = xx_emf_pkg.G_REQUEST_ID,
    			       error_code = xx_emf_cn_pkg.CN_NULL,
    			       process_code = xx_emf_cn_pkg.CN_NEW,
                 error_mesg = NULL
    			 WHERE batch_id = G_ASSGN_BATCH_ID;*/


         -- DELETE FROM mtl_system_items_interface
         --              WHERE attribute30 = G_MAST_BATCH_ID;

         -- DELETE FROM mtl_system_items_interface
         --              WHERE attribute29 = G_ORG_BATCH_ID;

         -- DELETE FROM mtl_system_items_interface
         --              WHERE attribute28 = G_ASSGN_BATCH_ID;

          DELETE FROM xx_item_org_assign_stg;
          DELETE FROM mtl_interface_errors;
          DELETE FROM mtl_item_revisions_interface;
          DELETE FROM mtl_system_items_interface;

    	ELSIF p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS THEN
    			-- Update Item master  Staging
    		IF UPPER(TRIM(p_mast_attr)) = G_YES THEN
        	UPDATE xx_item_mast_attr_upd_stg
    			   SET request_id = xx_emf_pkg.G_REQUEST_ID,
    			       error_code = xx_emf_cn_pkg.CN_NULL,
    			       process_code = xx_emf_cn_pkg.CN_NEW,
                 error_mesg = NULL
    			 WHERE batch_id = G_MAST_BATCH_ID
    			   AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
    				       xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR);
        END IF;
    			-- Update Item Organization Staging
        IF (UPPER(TRIM(p_org_attr)) = G_YES OR UPPER(TRIM(p_org_assgn)) = G_YES) THEN
    			UPDATE xx_item_org_attr_upd_stg
    			   SET request_id   = xx_emf_pkg.G_REQUEST_ID,
    			       error_code   = xx_emf_cn_pkg.CN_NULL,
    			       process_code = xx_emf_cn_pkg.CN_NEW,
                 error_mesg = NULL
    			 WHERE batch_id = G_ORG_BATCH_ID
    			   AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
    				       xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR);
         END IF;
          -- Item Assignment
          /* UPDATE xx_item_org_assign_stg
    			   SET request_id   = xx_emf_pkg.G_REQUEST_ID,
    			       error_code   = xx_emf_cn_pkg.CN_NULL,
    			       process_code = xx_emf_cn_pkg.CN_NEW,
                 error_mesg = NULL
    			 WHERE batch_id = G_ASSGN_BATCH_ID
    			   AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
    				       xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR); */

         -- DELETE FROM mtl_system_items_interface
         --              WHERE attribute30 = G_MAST_BATCH_ID;

         -- DELETE FROM mtl_system_items_interface
         --              WHERE attribute29 = G_ORG_BATCH_ID;

         -- DELETE FROM mtl_system_items_interface
         --             WHERE attribute28 = G_ASSGN_BATCH_ID;

          DELETE FROM mtl_system_items_interface;
          DELETE FROM xx_item_org_assign_stg;
          DELETE FROM mtl_interface_errors;
          DELETE FROM mtl_item_revisions_interface;

          END IF;
          COMMIT;
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'End of mark records for processing...');
    EXCEPTION
        WHEN OTHERS THEN
	     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while updating staging records status: '||SQLERRM);
    END;

    --------------------------------------------------------------------------------
    -----------------< set_stage >--------------------------------------------------
    --------------------------------------------------------------------------------

    PROCEDURE set_stage (p_stage VARCHAR2)
    IS
    BEGIN
    	G_STAGE := p_stage;
    END set_stage;




-----------------< update_staging_records >-------------------------------------
--------------------------------------------------------------------------------

PROCEDURE update_staging_records( p_error_code VARCHAR2
                                , p_level VARCHAR2) IS

	x_last_update_date     DATE   := SYSDATE;
	x_last_updated_by      NUMBER := fnd_global.user_id;
	x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
 g_api_name := 'update_staging_records';
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside update_staging_records...'||p_level);

	IF p_level = 'ITEM_MAST' THEN
	UPDATE xx_item_mast_attr_upd_stg		--Header
	   SET process_code = G_STAGE,
	       error_code = DECODE ( error_code, NULL, p_error_code, error_code),
	       last_update_date = x_last_update_date,
	       last_updated_by   = x_last_updated_by,
	       last_update_login = x_last_update_login,
         record_number = xx_item_mast_attr_upd_stg_s.nextval
	 WHERE batch_id		= G_MAST_BATCH_ID
	   AND request_id	= xx_emf_pkg.G_REQUEST_ID
	   AND process_code	= xx_emf_cn_pkg.CN_NEW;
	END IF;

  IF p_level = 'ITEM_ORG' THEN
        UPDATE xx_item_org_attr_upd_stg		--Component
	   SET process_code = G_STAGE,
	       error_code = DECODE ( error_code, NULL, p_error_code, error_code),
	       last_update_date = x_last_update_date,
	       last_updated_by   = x_last_updated_by,
	       last_update_login = x_last_update_login,
         record_number = xx_item_org_attr_upd_stg_s.nextval
	 WHERE batch_id		= G_ORG_BATCH_ID
	   AND request_id	= xx_emf_pkg.G_REQUEST_ID
	   AND process_code	= xx_emf_cn_pkg.CN_NEW;
	END IF;

  IF p_level = 'ITEM_ASSGN' THEN
        UPDATE xx_item_org_assign_stg		--Component
	   SET process_code = G_STAGE,
	       error_code = DECODE ( error_code, NULL, p_error_code, error_code),
	       last_update_date = x_last_update_date,
	       last_updated_by   = x_last_updated_by,
	       last_update_login = x_last_update_login
         --record_number = xx_item_org_attr_upd_stg_s.nextval
	 WHERE batch_id		= G_ASSGN_BATCH_ID
	   AND request_id	= xx_emf_pkg.G_REQUEST_ID
	   AND process_code	= xx_emf_cn_pkg.CN_NEW;
	END IF;
	COMMIT;
 EXCEPTION
        WHEN OTHERS THEN
	     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while updating staging records status: '||SQLERRM);

END update_staging_records;

--**********************************************************************
  --Function to Find Max.
--**********************************************************************

  FUNCTION find_max (
      p_error_code1 IN VARCHAR2,
      p_error_code2 IN VARCHAR2
       )
    RETURN VARCHAR2
   IS
      x_return_value VARCHAR2(100);
   BEGIN
      x_return_value := xx_intg_common_pkg.find_max(p_error_code1, p_error_code2);

    RETURN x_return_value;
  END find_max;

   -- pre_validations

   FUNCTION pre_validations
       RETURN NUMBER
    IS
     x_error_code    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
     x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

   BEGIN
       xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Inside Pre-Validations ');
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


    FUNCTION item_mast_attr_validations(p_item_mast_attr_rec IN OUT xx_inv_item_attr_upd_pkg.G_XX_ITEM_MAST_STG_REC_TYPE
                          ) RETURN NUMBER
     IS
    --------------------------------------------------------------------------------------
    -- Created By                 : Partha S Mohanty
    -- Creation Date              : 10-APR-2012
    -- Description                : Validate staging table values and derive corresponding value in Oracle

    -- Parameters description:

    -- @param1         :p_item_mast_attr_rec(IN OUT)
   -----------------------------------------------------------------------------------------
      x_organization_id    NUMBER := NULL;
      x_org_code           VARCHAR2(50):= NULL;
      x_inv_item_id        NUMBER := NULL;
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

      FUNCTION is_organization_valid(p_org_code OUT VARCHAR2,p_org_id OUT NUMBER)
           RETURN number
           IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive organization_id and organization_code
       --@param1 -- p_org_code(OUT)
		   --@param2 -- p_org_id(OUT)
		   -------------------------------------------------------------------------
           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

       BEGIN
          x_organization_id := fnd_profile.value('MSD_MASTER_ORG');

          SELECT organization_code
            INTO x_org_code
           FROM mtl_parameters
          WHERE organization_id = x_organization_id;

           p_org_id := x_organization_id;
           p_org_code := x_org_code;
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Organization Code derive ' || x_organization_id||'::'||x_org_code);
           RETURN x_error_code;

       EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Organization Code derive ' || SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_VALID
                  ,p_error_text  => 'Error in Organization Code derive =>'||SQLERRM
                  ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                  ,p_record_identifier_2 => x_org_code
                  ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                  ,p_record_identifier_4 => 'MAST_ATTR'
                  );
        RETURN x_error_code;
       END is_organization_valid;

       FUNCTION is_item_number_valid(p_item_number VARCHAR2,p_item_inv_id OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive item_id
		   --@param1 -- p_item_number
		   --@param2 -- p_item_inv_id(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
          IF p_item_number IS NULL THEN
                dbg_med('Item Number can not be Null ');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Item Number can not be Null;'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );

              return x_error_code;
         ELSE
            ---
              BEGIN
                 SELECT a.inventory_item_id
                  INTO x_inv_item_id
                 FROM mtl_system_items_b a
                  WHERE a.segment1 = UPPER(TRIM(p_item_number))
                     AND a.organization_id = x_organization_id;

                  p_item_inv_id :=  x_inv_item_id;

                  RETURN  x_error_code;
               EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid Item Number');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid Item Number'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing Item Number');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing Item Number'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                  RETURN  x_error_code;
              END ;
          END IF;
       END is_item_number_valid;

      FUNCTION is_atp_rule_valid(p_atp_rule VARCHAR2,p_atp_rule_id OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive atp_rule_id
		   --@param1 -- p_atp_rule
		   --@param2 -- p_atp_rule_id(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_rule_id  NUMBER := NULL;
       BEGIN
          IF p_atp_rule IS NULL THEN
              return x_error_code;
         ELSE
              BEGIN
                 SELECT a.rule_id
                  INTO x_rule_id
                 FROM mtl_atp_rules a
                  WHERE UPPER(trim(a.rule_name)) = UPPER(trim(p_atp_rule));

                  p_atp_rule_id :=  x_rule_id;

                  RETURN  x_error_code;
               EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid ATP Rule');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid ATP Rule'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing ATP Rule');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing ATP Rule'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                  RETURN  x_error_code;
              END ;
          END IF;
       END is_atp_rule_valid;

     FUNCTION is_check_atp_valid(p_check_atp VARCHAR2,p_atp_flag OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive atp_flag
		   --@param1 -- p_ceck_atp
		   --@param2 -- p_atp_flag(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_atp_flag VARCHAR2(1) := NULL;
       BEGIN
          IF p_check_atp IS NOT NULL THEN
                 IF UPPER(trim(p_check_atp)) = 'NONE' THEN
                     x_atp_flag := 'N';
                 ELSIF UPPER(trim(p_check_atp)) = 'MATERIAL ONLY' THEN
                     x_atp_flag := 'Y';
                 ELSIF UPPER(trim(p_check_atp)) = 'RESOURCE ONLY' THEN
                     x_atp_flag := 'R';
                 ELSIF UPPER(trim(p_check_atp)) = 'MATERIAL AND RESOURCE' THEN
                     x_atp_flag := 'C';
                 ELSE
                     dbg_med('Invalid Check_ATP Flag');
                     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid Check_ATP Flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                END IF;
            END IF;
            p_atp_flag := x_atp_flag;
            RETURN  x_error_code;
       EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing Check_ATP Flag');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing Check_ATP Flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                  RETURN  x_error_code;
       END is_check_atp_valid;

       FUNCTION is_collateral_item_valid(p_collateral_item VARCHAR2,p_collateral_flag OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive collateral_flag
		   --@param1 -- p_collateral_item
		   --@param2 -- p_collateral_flag(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_collateral_flag  VARCHAR2(1) := NULL;
       BEGIN
         IF p_collateral_item IS NOT NULL THEN
              IF UPPER(trim(p_collateral_item)) IN ('YES','Y') THEN
                     x_collateral_flag := 'Y';
              ELSIF UPPER(trim(p_collateral_item)) IN ('NO','N') THEN
                     x_collateral_flag := 'N';
              ELSE
                     dbg_med('Invalid Collateral flag');
                     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid Collateral flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
               END IF;
          END IF;
          p_collateral_flag := x_collateral_flag;
          RETURN  x_error_code;
        EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing Collateral flag');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing Collateral flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                  RETURN  x_error_code;
       END is_collateral_item_valid;

       FUNCTION is_container_item_valid(p_container_item VARCHAR2,p_container_item_flag OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive container_item_flag
		   --@param1 -- p_container_item
		   --@param2 -- p_container_item_flag(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_container_item_flag  VARCHAR2(1) := NULL;
       BEGIN
         IF p_container_item IS NOT NULL THEN
              IF UPPER(trim(p_container_item)) IN ('YES','Y') THEN
                     x_container_item_flag := 'Y';
              ELSIF UPPER(trim(p_container_item)) IN ('NO','N') THEN
                     x_container_item_flag := 'N';
              ELSE
                     dbg_med('Invalid Container');
                     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid Container'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
               END IF;
          END IF;
          p_container_item_flag := x_container_item_flag;
          RETURN  x_error_code;
       EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing Container');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing Container'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                  RETURN  x_error_code;
       END is_container_item_valid;

      FUNCTION is_lot_status_valid(p_lot_status_enabled IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive lot_status_enabled
		   --@param1 -- p_lot_status_enabled(IN OUT)
		   --@param2 --
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_lot_status_enabled  VARCHAR2(1) := NULL;
       BEGIN
         IF p_lot_status_enabled IS NOT NULL THEN
              IF UPPER(trim(p_lot_status_enabled)) IN('Y','YES') THEN
                    x_lot_status_enabled := 'Y';
              ELSIF UPPER(trim(p_lot_status_enabled)) IN('N','NO') THEN
                    x_lot_status_enabled := 'N';
              ELSE
                     dbg_med('Invalid lot_status_enabled');
                     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid lot_status_enabled'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
               END IF;
          END IF;
          p_lot_status_enabled := x_lot_status_enabled;
          RETURN  x_error_code;
       EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing lot_status_enabled');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing lot_status_enabled'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                  RETURN  x_error_code;
       END is_lot_status_valid;

       FUNCTION is_default_lot_status_valid(p_default_lot_status VARCHAR2,
                                            p_default_lot_status_id OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive default_lot_status_id
		   --@param1 -- p_default_lot_status(IN)
       --@param2 -- p_default_lot_status_id(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_status_id  NUMBER := NULL;
        BEGIN
          IF  p_default_lot_status IS NOT NULL THEN
              SELECT status_id INTO x_status_id
                 FROM  mtl_material_statuses_vl
                WHERE  lot_control = 1
                 AND  enabled_flag = 1
                 AND UPPER(trim(status_code)) = UPPER(trim(p_default_lot_status));
           END IF;
                p_default_lot_status_id := x_status_id;
                RETURN  x_error_code;
         EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid default_lot_status');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid default_lot_status'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                   RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing default_lot_status');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing default_lot_status'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );

                 RETURN  x_error_code;
       END is_default_lot_status_valid;

       FUNCTION is_serial_status_valid(p_serial_status_enabled IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive serial_status_enabled
		   --@param1 -- p_lot_status_enabled(IN OUT)
		   --@param2 --
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_serial_status_enabled  VARCHAR2(1):= NULL;
       BEGIN
         IF p_serial_status_enabled IS NOT NULL THEN

              IF UPPER(trim(p_serial_status_enabled)) IN('Y','YES') THEN
                  x_serial_status_enabled := 'Y';
              ELSIF UPPER(trim(p_serial_status_enabled)) IN('N','NO') THEN
                  x_serial_status_enabled := 'N';
              ELSE
                     dbg_med('Invalid serial_status_enabled');
                     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid serial_status_enabled'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
               END IF;
          END IF;
          p_serial_status_enabled := x_serial_status_enabled;
          RETURN  x_error_code;
       EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing serial_status_enabled');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing serial_status_enabled'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                  RETURN  x_error_code;
       END is_serial_status_valid;

       FUNCTION is_default_serial_status_valid(p_default_serial_status     IN  VARCHAR2,
                                               p_default_serial_status_id  OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive ddefault_serial_status_id
		   -- @param1 -- p_default_serial_status(IN)
       -- @param2 -- p_default_serial_status_id(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_status_id  NUMBER := NULL;
       BEGIN
         IF p_default_serial_status IS NOT NULL THEN
              SELECT status_id INTO x_status_id
                 FROM  mtl_material_statuses_vl
                WHERE  serial_control = 1
                  AND  enabled_flag = 1
                  AND  UPPER(trim(status_code)) = UPPER(trim(p_default_serial_status));
           END IF;
                p_default_serial_status_id := x_status_id;
                RETURN  x_error_code;

         EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid default_serial_status');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid default_serial_status'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                   RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing default_serial_status');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing default_serial_status'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_default_serial_status_valid;

       FUNCTION is_default_shipping_org_valid(p_default_shipping_orgn IN  VARCHAR2,
                                              p_default_shipping_org  OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive default_shipping_org
		   -- @param1 -- p_default_shipping_orgn(IN)
       -- @param2 -- p_default_shipping_org(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_org_id  NUMBER := NULL;
       BEGIN
         IF p_default_shipping_orgn IS NOT NULL THEN
              select mp.organization_id INTO x_org_id
               from hr_organization_units hou
                    ,mtl_parameters mp
              where mp.organization_id = hou.organization_id
                and nvl(hou.date_to, sysdate+1) > sysdate
                and UPPER(trim(hou.name)) = UPPER(trim(p_default_shipping_orgn));
           END IF;
                p_default_shipping_org := x_org_id;
                 RETURN  x_error_code;
         EXCEPTION
              WHEN no_data_found THEN
                  dbg_med('Invalid default_shipping_org');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid default_shipping_org'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                    RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing default_shipping_org');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing default_shipping_org'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                   RETURN  x_error_code;
       END is_default_shipping_org_valid;

      FUNCTION is_dimension_uom_code_valid(p_dimension_uom IN  VARCHAR2,
                                           p_dimension_uom_code  OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive dimension_uom
		   -- @param1 -- p_dimension_uom(IN)
       -- @param2 -- p_dimension_uom_code(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_dimension_uom_code  VARCHAR2(3) := NULL;
       BEGIN
          IF p_dimension_uom IS NOT NULL THEN
              select  distinct  uom.uom_code INTO x_dimension_uom_code
                  from  mtl_uom_conversions      conv
                        , mtl_units_of_measure_vl  uom
               where uom.unit_of_measure = conv.unit_of_measure
                  and  conv.inventory_item_id = 0
                  and  nvl(uom.disable_date, sysdate+1) > sysdate
                  and  nvl(conv.disable_date, sysdate+1) > sysdate
                  and  UPPER(trim(uom.unit_of_measure_tl)) = UPPER(trim(p_dimension_uom));
            END IF;
                p_dimension_uom_code := x_dimension_uom_code;
                 RETURN  x_error_code;
         EXCEPTION
             WHEN no_data_found THEN
                  dbg_med('Invalid dimension_uom_code');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid dimension_uom_code'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing dimension_uom_code');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing dimension_uom_code'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
          RETURN  x_error_code;
       END is_dimension_uom_code_valid;

       FUNCTION is_hazard_class_code_valid(p_hazard_class IN  VARCHAR2,
                                           p_hazard_class_id  OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive hazard_class
		   -- @param1 -- p_hazard_class(IN)
       -- @param2 -- p_hazard_class_id(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_hazard_class_id  NUMBER := NULL;
       BEGIN
           IF p_hazard_class IS NOT NULL THEN
              SELECT hazard_class_id INTO x_hazard_class_id
                 FROM po_hazard_classes
               WHERE sysdate < nvl(inactive_date, sysdate+1)
                  AND  trim(hazard_class) = trim(p_hazard_class);
           END IF;
                p_hazard_class_id := x_hazard_class_id;
                RETURN  x_error_code;
        EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid hazard_class');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid hazard_class'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing hazard_class');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing hazard_class'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_hazard_class_code_valid;

      FUNCTION is_height_valid(p_height NUMBER,p_unit_height OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive unit_height
       -- @param1 -- p_height(IN)
		   -- @param2 -- p_unit_height(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
         IF p_height IS NOT NULL THEN
             p_unit_height := p_height;
         END IF;
         RETURN  x_error_code;
       EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating unit_height');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating unit_height'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
       END is_height_valid;

      FUNCTION is_length_valid(p_length NUMBER,p_unit_length OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive unit_height
       -- @param1 -- p_length(IN)
		   -- @param2 -- p_unit_length(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
         IF p_length IS NOT NULL THEN
             p_unit_length := p_length;
         END IF;
         RETURN  x_error_code;
       EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating unit_length');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating unit_length'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
       END is_length_valid;

       FUNCTION is_installed_base_valid(p_installed_base IN  VARCHAR2,p_trackable_flag IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive installed_base
		   -- @param1 -- p_installed_base(IN)
		   -- @param2 -- p_trackable_flag(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_installed_base  VARCHAR2(1) := NULL;
       BEGIN
         IF UPPER(trim(p_installed_base)) IN ('NO','N') THEN
              x_installed_base := NULL;
         ELSIF trim(p_installed_base) IS  NULL THEN
              x_installed_base := NULL;
         ELSIF UPPER(trim(p_installed_base)) IN ('YES','Y') THEN
              x_installed_base :='Y';
         ELSE
           dbg_med('Invalid Track_in_Installed_Base');
           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
           xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid Track_in_Installed_Base'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
          END IF;
          p_trackable_flag := x_installed_base;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating Track_in_Installed_Base');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating Track_in_Installed_Base'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_installed_base_valid;

       FUNCTION is_item_instance_class_valid(p_item_instance_class IN  VARCHAR2,p_ib_item_instance_class OUT  VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive installed_base
		   -- @param1 -- p_item_instance_class(IN)
		   -- @param2 -- p_ib_item_instance_class(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_ib_item_instance_class  VARCHAR2(30) := NULL;
       BEGIN
            IF p_item_instance_class IS NOT NULL THEN
                SELECT lookup_code INTO x_ib_item_instance_class
                 FROM fnd_lookup_types a,
                     fnd_lookup_values b
                WHERE a.lookup_type=b.lookup_type
                 AND a.lookup_type like  'CSI_ITEM_CLASS'
                 AND language=UserEnv('LANG')
                 AND UPPER(trim(meaning))=UPPER(TRIM(p_item_instance_class));
             END IF;
             p_ib_item_instance_class :=  x_ib_item_instance_class;
             RETURN  x_error_code;
        EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid item_instance_class');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid item_instance_class'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                   RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating item_instance_class');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating item_instance_class'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                         );
                   RETURN  x_error_code;
        END is_item_instance_class_valid;

       FUNCTION is_lot_control_code_valid(p_lot_control IN VARCHAR2,p_lot_control_code OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive lot_control_code
		   --@param1 -- p_lot_control(IN)
		   --@param2 -- p_lot_control_code(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_lot_control_code  NUMBER := NULL;
       BEGIN
         IF p_lot_control IS NOT NULL THEN
            IF UPPER(trim(p_lot_control)) = 'NO CONTROL' THEN
               x_lot_control_code := 1;
            ELSIF UPPER(trim(p_lot_control)) = 'FULL CONTROL' THEN
               x_lot_control_code := 2;
            ELSE
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_VALID
              ,p_error_text  => 'Invalid lot_control'
              ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
              ,p_record_identifier_2 => x_org_code
              ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
              ,p_record_identifier_4 => 'MAST_ATTR'
              );
            END IF;
          END IF;
          p_lot_control_code := x_lot_control_code;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating lot_control');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating lot_control'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_lot_control_code_valid;

     FUNCTION is_lot_expiration_valid(p_lot_expiration IN VARCHAR2,p_shelf_life_code OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive shelf_life_code
		   --@param1 -- p_lot_expiration(IN)
		   --@param2 -- p_shelf_life_code(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_shelf_life_code  NUMBER := NULL;
       BEGIN
         IF p_lot_expiration IS NOT NULL THEN
            IF UPPER(trim(p_lot_expiration)) = 'NO CONTROL' THEN
               x_shelf_life_code := 1;
            ELSIF UPPER(trim(p_lot_expiration)) = 'SHELF LIFE DAYS' THEN
               x_shelf_life_code := 2;
            ELSIF UPPER(trim(p_lot_expiration)) = 'USER-DEFINED' THEN
               x_shelf_life_code := 4;
            ELSE
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_VALID
              ,p_error_text  => 'Invalid lot_expiration'
              ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
              ,p_record_identifier_2 => x_org_code
              ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
              ,p_record_identifier_4 => 'MAST_ATTR'
              );

            END IF;
         END IF;
         p_shelf_life_code := x_shelf_life_code;
         RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating lot_expiration');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating lot_expiration'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_lot_expiration_valid;

       FUNCTION is_orderable_on_web_valid(p_orderable_on_the_web VARCHAR2,p_orderable_on_web_flag IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive orderable_on_web_flag
		   --@param1 -- p_orderable_on_the_web(IN )
		   --@param2 -- p_orderable_on_web_flag(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_orderable_on_web  VARCHAR2(1) := NULL;
       BEGIN
         IF p_orderable_on_the_web IS NOT NULL THEN
            IF UPPER(trim(p_orderable_on_the_web)) IN ('YES','Y') THEN
               x_orderable_on_web := 'Y';
            ELSIF UPPER(trim(p_orderable_on_the_web)) IN ('NO','N') THEN
               x_orderable_on_web := NULL;
            ELSE
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_VALID
              ,p_error_text  => 'Invalid orderable_on_web_flag'
              ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
              ,p_record_identifier_2 => x_org_code
              ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
              ,p_record_identifier_4 => 'MAST_ATTR'
              );
            END IF;
          END IF;
          p_orderable_on_web_flag := x_orderable_on_web;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating orderable_on_web_flag');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating orderable_on_web_flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_orderable_on_web_valid;

       FUNCTION is_outside_process_item_valid(p_outside_processing_item IN VARCHAR2,p_outside_operation_flag OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive outside_processing_item
		   --@param1 -- p_outside_processing_item(IN)
		   --@param2 -- p_outside_operation_flag(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_outside_operation_flag  VARCHAR2(1) := NULL;
       BEGIN
         IF p_outside_processing_item IS NOT NULL THEN
            IF UPPER(trim(p_outside_processing_item))IN('YES','Y') THEN
               x_outside_operation_flag := 'Y';
            ELSIF UPPER(trim(p_outside_processing_item))IN('NO','N') THEN
               x_outside_operation_flag := 'N';
            ELSE
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_VALID
              ,p_error_text  => 'Invalid outside_processing_item'
              ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
              ,p_record_identifier_2 => x_org_code
              ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
              ,p_record_identifier_4 => 'MAST_ATTR'
              );
            END IF;
          END IF;
          p_outside_operation_flag := x_outside_operation_flag;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating outside_processing_item');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating outside_processing_item'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_outside_process_item_valid;

       FUNCTION is_outsid_proc_unit_typ_valid(p_outside_process_unit_type IN VARCHAR2,p_outside_operation_uom_type OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive outside_operation_uom_type
		   -- @param1 -- p_outside_process_unit_type(IN)
		   -- @param2 -- p_outside_operation_uom_type(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_outside_oper_unit_type  VARCHAR2(25) := NULL;
        BEGIN
         IF p_outside_process_unit_type IS NOT NULL THEN
            IF UPPER(trim(p_outside_process_unit_type)) = 'ASSEMBLY' THEN
               x_outside_oper_unit_type := 'ASSEMBLY';
            ELSIF UPPER(trim(p_outside_process_unit_type)) = 'RESOURCE' THEN
               x_outside_oper_unit_type := 'RESOURCE';
            ELSE
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_VALID
              ,p_error_text  => 'Invalid outside_process_unit_type'
              ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
              ,p_record_identifier_2 => x_org_code
              ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
              ,p_record_identifier_4 => 'MAST_ATTR'
              );
            END IF;
          END IF;
          p_outside_operation_uom_type := x_outside_oper_unit_type;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating outside_process_unit_type');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating outside_process_unit_type'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_outsid_proc_unit_typ_valid;

     FUNCTION is_serial_number_gen_valid(p_serial_number_gen IN VARCHAR2,p_serial_number_ctl_code OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive serial_number_control_code
		   -- @param1 -- p_serial_number_gen(IN)
		   -- @param2 -- p_serial_number_ctl_code(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_serial_number_ctl_code  NUMBER := NULL;
        BEGIN
         IF p_serial_number_gen IS NOT NULL THEN
            IF UPPER(trim(p_serial_number_gen)) = 'NO CONTROL' THEN
               x_serial_number_ctl_code := 1;
            ELSIF UPPER(trim(p_serial_number_gen)) = 'PREDEFINED' THEN
               x_serial_number_ctl_code := 2;
            ELSIF UPPER(trim(p_serial_number_gen)) = 'AT RECEIPT' THEN
               x_serial_number_ctl_code := 5;
            ELSIF UPPER(trim(p_serial_number_gen)) = 'AT SALES ORDER ISSUE' THEN
               x_serial_number_ctl_code := 6;
            ELSE
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_VALID
              ,p_error_text  => 'Invalid serial_number_generation'
              ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
              ,p_record_identifier_2 => x_org_code
              ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
              ,p_record_identifier_4 => 'MAST_ATTR'
              );
            END IF;
          END IF;
          p_serial_number_ctl_code := x_serial_number_ctl_code;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating serial_number_generation');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating serial_number_generation'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_serial_number_gen_valid;

      FUNCTION is_volume_uom_code_valid(p_volume_uom IN  VARCHAR2,
                                           p_volume_uom_code  OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive volume_uom_code
		   -- @param1 -- p_volume_uom(IN)
       -- @param2 -- p_volume_uom_code(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_volume_uom_code  VARCHAR2(3) := NULL;
       BEGIN
         IF p_volume_uom IS NOT NULL THEN
              select  distinct  uom.uom_code INTO x_volume_uom_code
                  from  mtl_uom_conversions      conv
                        , mtl_units_of_measure_vl  uom
               where uom.unit_of_measure = conv.unit_of_measure
                  and  conv.inventory_item_id = 0
                  and  nvl(uom.disable_date, sysdate+1) > sysdate
                  and  nvl(conv.disable_date, sysdate+1) > sysdate
                  and  UPPER(trim(uom.unit_of_measure_tl)) = UPPER(trim(p_volume_uom));
          END IF;
                p_volume_uom_code := x_volume_uom_code;
                RETURN  x_error_code;
         EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid volume_uom_code');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid volume_uom_code'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                   RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing volume_uom_code');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing volume_uom_code'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                  RETURN  x_error_code;
       END is_volume_uom_code_valid;


       FUNCTION is_weight_uom_code_valid(p_weight_uom   IN  VARCHAR2,
                                           p_weight_uom_code  OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive weight_uom_code
		   -- @param1 -- p_weight_uom(IN)
       -- @param2 -- p_weight_uom_code(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_weight_uom_code  VARCHAR2(3) := NULL;
       BEGIN
         IF p_weight_uom IS NOT NULL THEN

              select  distinct  uom.uom_code INTO x_weight_uom_code
                  from  mtl_uom_conversions      conv
                        , mtl_units_of_measure_vl  uom
               where uom.unit_of_measure = conv.unit_of_measure
                  and  conv.inventory_item_id = 0
                  and  nvl(uom.disable_date, sysdate+1) > sysdate
                  and  nvl(conv.disable_date, sysdate+1) > sysdate
                  and  UPPER(trim(uom.unit_of_measure_tl)) = UPPER(trim(p_weight_uom));
           END IF;
               p_weight_uom_code := x_weight_uom_code;
               RETURN  x_error_code;
          EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid weight_uom_code');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid weight_uom_code'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing weight_uom_code');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing weight_uom_code'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );

               RETURN  x_error_code;
       END is_weight_uom_code_valid;


       FUNCTION is_use_apprvd_suppl_valid(p_use_appr_suppl IN  VARCHAR2,p_must_use_appr_vendor_flag OUT  VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate anfd derive must_use_approved_vendor_flag
		   -- @param1 -- p_use_appr_suppl(IN)
       -- @param2 -- p_must_use_appr_vendor_flag(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_must_use_appr_vendor_flag  VARCHAR2(1):= NULL;
       BEGIN
         IF p_use_appr_suppl IS NOT NULL THEN
            IF UPPER(trim(p_use_appr_suppl)) IN ('YES','Y')  THEN
               x_must_use_appr_vendor_flag:= 'Y';
            ELSIF UPPER(trim(p_use_appr_suppl)) IN ('NO','N')  THEN
               x_must_use_appr_vendor_flag:= 'N';
            ELSE
                  dbg_med('Invalid use_approved_supplier');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid use_approved_supplier'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                         );
             END IF;
          END IF;
          p_must_use_appr_vendor_flag := x_must_use_appr_vendor_flag;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating use_approved_supplier');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating use_approved_supplier'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_use_apprvd_suppl_valid;

       FUNCTION is_vehicle_valid(p_vehicle IN  VARCHAR2,p_vehicle_item_flag OUT  VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate anfd derive vehicle_flag
		   -- @param1 -- p_vehicle(IN)
       -- @param2 -- p_vehicle_item_flag(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_vehicle_item_flag VARCHAR2(1) := NULL;
       BEGIN
         IF p_vehicle IS NOT NULL THEN
            IF UPPER(trim(p_vehicle))  IN ('YES','Y') THEN
               x_vehicle_item_flag:= 'Y';
            ELSIF UPPER(trim(p_vehicle))  IN ('NO','N') THEN
               x_vehicle_item_flag:= 'N';
            ELSE
                  dbg_med('Invalid vehicle_flag');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid vehicle_flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                         );
             END IF;
          END IF;
          p_vehicle_item_flag :=  x_vehicle_item_flag;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating vehicle_flag');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating vehicle_flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_vehicle_valid;

       FUNCTION is_web_status_valid(p_web_status IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate anfd derive web_status
		   -- @param1 -- p_web_status(IN OUT)
       -- @param2 --
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_web_status VARCHAR2(30):= NULL;
       BEGIN
         IF p_web_status IS NOT NULL THEN
             SELECT  lookup_code INTO x_web_status
               FROM  fnd_lookup_values_vl
              WHERE lookup_type = 'IBE_ITEM_STATUS'
                AND enabled_flag = 'Y'
                AND UPPER(trim(meaning)) = UPPER(trim(p_web_status));
         END iF;
             p_web_status := x_web_status;
             RETURN  x_error_code;
    EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  dbg_med('Invalid web_status');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid web_status'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                         );
                 RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error in validating web_status');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating web_status'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                         );
                  RETURN  x_error_code;
       END is_web_status_valid;

       FUNCTION is_lot_divisible_valid(p_lot_divisible IN VARCHAR2,p_lot_divisible_flag OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive lot_status_enabled
		   --@param1 -- p_lot_divisible(IN)
		   --@param2 -- lot_divisible_flag(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_lot_divisible_flag  VARCHAR2(1) := NULL;
       BEGIN
         IF p_lot_divisible IS NOT NULL THEN
              IF UPPER(trim(p_lot_divisible)) IN('Y','YES') THEN
                    x_lot_divisible_flag := 'Y';
              ELSIF UPPER(trim(p_lot_divisible)) IN('N','NO') THEN
                    x_lot_divisible_flag := 'N';
              ELSE
                     dbg_med('Invalid lot_divisible');
                     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid lot_divisible'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
               END IF;
          END IF;
          p_lot_divisible_flag := x_lot_divisible_flag;
          RETURN  x_error_code;
       EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing lot_divisible');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing lot_divisible'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                  RETURN  x_error_code;
       END is_lot_divisible_valid;

       --- Wave1 validations
       FUNCTION is_buyer_valid(p_buyer VARCHAR2,p_buyer_id OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive buyer_id
       -- @param1 -- p_buyer(IN)
		   -- @param2 -- p_buyer_id(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_buyer_id NUMBER := NULL;
       BEGIN
         IF p_buyer IS NOT NULL THEN
             SELECT ppf.person_id INTO x_buyer_id
                  FROM per_people_f ppf, po_agents poa, per_business_groups_perf pb
                WHERE ppf.person_id = poa.agent_id
                 AND ppf.business_group_id = pb.business_group_id
                 AND SYSDATE BETWEEN NVL(poa.start_date_active, SYSDATE-1)
                 AND NVL(poa.end_date_active,SYSDATE+1)
                 AND TRUNC(SYSDATE) BETWEEN ppf.effective_start_date
                 AND ppf.effective_end_date
                 AND NVL(ppf.current_employee_flag,'N') = 'Y'
                 AND UPPER(ppf.full_name)=UPPER(TRIM(p_buyer));
          END IF;
          p_buyer_id :=  x_buyer_id;
          RETURN  x_error_code;
        EXCEPTION
              WHEN no_data_found THEN
                  dbg_med('buyer does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'buyer does not exist'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                  RETURN  x_error_code;
              WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the buyer');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the buyer'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                  RETURN  x_error_code;
       END is_buyer_valid;

       FUNCTION is_list_price_valid(p_list_price NUMBER,p_list_price_per_unit OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive list_price
       -- @param1 -- p_list_price(IN)
		   -- @param2 -- p_list_price_per_unit(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

       BEGIN
         IF p_list_price IS NOT NULL THEN
             p_list_price_per_unit := p_list_price;
         END IF;
         RETURN  x_error_code;
       EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating list_price');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating list_price'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
       END is_list_price_valid;

       FUNCTION is_receipt_routing_valid(p_receipt_routing VARCHAR2,p_receiv_routing_id OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive equipment_type
       -- @param1 -- p_equipment(IN)
		   -- @param2 -- p_equipment_type(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_receiv_routing_id NUMBER := NULL;
       BEGIN
         IF p_receipt_routing IS NOT NULL THEN
             IF UPPER(TRIM(p_receipt_routing)) IN ('STANDARD') THEN
                x_receiv_routing_id := 1;
             ELSIF UPPER(TRIM(p_receipt_routing)) IN ('INSPECTION') THEN
                x_receiv_routing_id := 2;
             ELSIF UPPER(TRIM(p_receipt_routing)) IN ('DIRECT') THEN
                x_receiv_routing_id := 3;
             ELSE
                dbg_med('Invalid receipt_routing');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid receipt_routing'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
             END IF;
         END IF;
         p_receiv_routing_id := x_receiv_routing_id;
         RETURN  x_error_code;
        EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing receipt_routing');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing receipt_routing'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                  RETURN  x_error_code;
       END is_receipt_routing_valid;


       FUNCTION is_item_status_valid(p_item_status          IN VARCHAR2
                                    ,p_inv_item_status_code OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate item_status
		   --@param1 -- p_item_status(IN)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_inv_item_status_code  VARCHAR2(10) := NULL;
       BEGIN
         IF p_item_status IS NOT NULL THEN
              SELECT  inventory_item_status_code INTO x_inv_item_status_code
               from mtl_item_status
                where nvl(disable_date, sysdate+1) > sysdate
                 and  inventory_item_status_code <> 'Pending'
                 and  UPPER(trim(inventory_item_status_code)) = UPPER(trim(p_item_status));
          END iF;
             p_inv_item_status_code := x_inv_item_status_code;
             RETURN  x_error_code;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  dbg_med('Invalid item_status');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid item_status'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                         );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error in validating item_status');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating item_status'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                         );
                  RETURN  x_error_code;
       END is_item_status_valid;

       FUNCTION is_item_type_valid  (p_item_type          IN VARCHAR2
                                    ,p_item_type_orig     OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate item_status
		   --@param1 -- p_item_status(IN)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_item_type  VARCHAR2(30) := NULL;
       BEGIN
         IF p_item_type IS NOT NULL THEN
              select lookup_code INTO x_item_type
                 from fnd_common_lookups
                       where lookup_type = 'ITEM_TYPE'
                        and enabled_flag = 'Y'
                         and sysdate between nvl(start_date_active, sysdate) and nvl(end_date_active, sysdate)
                          and upper(meaning) = upper(p_item_type);
          END iF;
             p_item_type_orig := x_item_type;
             RETURN  x_error_code;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  dbg_med('Invalid item_type');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid item_type'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                         );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error in validating Invalid item_type');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating Invalid item_type'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                         );
                  RETURN  x_error_code;
       END is_item_type_valid;


       FUNCTION is_cust_order_flag_valid(p_cust_order_flag IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate anfd derive is_cust_order_flag_valid
		   -- @param1 -- p_cust_order_flag(IN OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
         IF p_cust_order_flag IS NOT NULL THEN
            IF UPPER(trim(p_cust_order_flag))    ='Y'  THEN
               p_cust_order_flag:= 'Y';
            ELSIF UPPER(trim(p_cust_order_flag)) ='N'  THEN
               p_cust_order_flag:= 'N';
            ELSE
                  dbg_med('Invalid customer_order_flag');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid customer_order_flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                         );
             END IF;
          END IF;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating customer_order_flag');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating customer_order_flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_cust_order_flag_valid;


       FUNCTION is_cust_ord_enable_flag_valid(p_cust_order_enable_flag IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive cust_ord_enable_flag
		   -- @param1 -- p_cust_order_enable_flag(IN OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
         IF p_cust_order_enable_flag IS NOT NULL THEN
            IF UPPER(trim(p_cust_order_enable_flag))    ='Y'  THEN
               p_cust_order_enable_flag:= 'Y';
            ELSIF UPPER(trim(p_cust_order_enable_flag)) ='N'  THEN
               p_cust_order_enable_flag:= 'N';
            ELSE
                  dbg_med('Invalid customer_order_enable_flag');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid customer_order_enable_flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                         );
             END IF;
          END IF;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating customer_order_enable_flag');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating customer_order_enable_flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_cust_ord_enable_flag_valid;

       FUNCTION is_pur_enabled_flag_valid(p_pur_enabled_flag IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive purchasing_enabled_flag
		   -- @param1 -- p_pur_enabled_flag(IN OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
         IF p_pur_enabled_flag IS NOT NULL THEN
            IF UPPER(trim(p_pur_enabled_flag))    ='Y'  THEN
               p_pur_enabled_flag:= 'Y';
            ELSIF UPPER(trim(p_pur_enabled_flag)) ='N'  THEN
               p_pur_enabled_flag:= 'N';
            ELSE
                  dbg_med('Invalid purchasing_enabled_flag');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid purchasing_enabled_flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                         );
             END IF;
          END IF;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating purchasing_enabled_flag');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating purchasing_enabled_flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_pur_enabled_flag_valid;

       FUNCTION is_pur_item_flag_valid(p_pur_item_flag IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive purchasing_item_flag
		   -- @param1 -- p_pur_item_flag(IN OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
         IF p_pur_item_flag IS NOT NULL THEN
            IF UPPER(trim(p_pur_item_flag))    ='Y'  THEN
               p_pur_item_flag:= 'Y';
            ELSIF UPPER(trim(p_pur_item_flag)) ='N'  THEN
               p_pur_item_flag:= 'N';
            ELSE
                  dbg_med('Invalid purchasing_item_flag');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid purchasing_item_flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                         );
             END IF;
          END IF;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating purchasing_item_flag');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating purchasing_item_flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_pur_item_flag_valid;

       FUNCTION is_assemble_to_order_valid(p_replenish_to_order_flag IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive assemble_to_order
		   -- @param1 -- p_assemble_to_order_flag(IN OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
         IF p_replenish_to_order_flag IS NOT NULL THEN
            IF UPPER(trim(p_replenish_to_order_flag))    ='Y'  THEN
               p_replenish_to_order_flag:= 'Y';
            ELSIF UPPER(trim(p_replenish_to_order_flag)) ='N'  THEN
               p_replenish_to_order_flag:= 'N';
            ELSE
                  dbg_med('Invalid replenish_to_order_flag');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid replenish_to_order_flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                         );
             END IF;
          END IF;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating replenish_to_order_flag');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating replenish_to_order_flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_assemble_to_order_valid;

       FUNCTION is_build_in_wip_flag_valid(p_build_in_wip_flag IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive build_in_wip_flag
		   -- @param1 -- p_build_in_wip_flag(IN OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
         IF p_build_in_wip_flag IS NOT NULL THEN
            IF UPPER(trim(p_build_in_wip_flag))    ='Y'  THEN
               p_build_in_wip_flag:= 'Y';
            ELSIF UPPER(trim(p_build_in_wip_flag)) ='N'  THEN
               p_build_in_wip_flag:= 'N';
            ELSE
                  dbg_med('Invalid build_in_wip_flag');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid build_in_wip_flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                         );
             END IF;
          END IF;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating build_in_wip_flag');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating build_in_wip_flag'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_build_in_wip_flag_valid;

       FUNCTION is_wip_supply_type_valid(p_wip_supply_type IN VARCHAR2,p_wip_supply_type_orig IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive build_in_wip_flag
		   -- @param1 -- p_build_in_wip_flag(IN OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_wip_supply_type NUMBER := NULL;
       BEGIN
         IF p_wip_supply_type IS NOT NULL THEN
            IF UPPER(trim(p_wip_supply_type))    ='PUSH'  THEN
               x_wip_supply_type:= 1;
            ELSIF UPPER(trim(p_wip_supply_type)) ='ASSEMBLY PULL'  THEN
               x_wip_supply_type:= 2;
            ELSIF UPPER(trim(p_wip_supply_type)) ='OPERATION PULL'  THEN
               x_wip_supply_type:= 3;
            ELSIF UPPER(trim(p_wip_supply_type)) ='BULK'  THEN
               x_wip_supply_type:= 4;
            ELSIF UPPER(trim(p_wip_supply_type)) ='SUPPLIER'  THEN
               x_wip_supply_type:= 5;
            ELSIF UPPER(trim(p_wip_supply_type)) ='PHANTOM'  THEN
               x_wip_supply_type:= 6;
            ELSE
                  dbg_med('Invalid wip_supply_type');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid wip_supply_type'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                         );
                    RETURN  x_error_code;
             END IF;
          END IF;
          p_wip_supply_type_orig := x_wip_supply_type;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating wip_supply_type');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating wip_supply_type'
                         ,p_record_identifier_1 => p_item_mast_attr_rec.record_number
                         ,p_record_identifier_2 => x_org_code
                         ,p_record_identifier_3 => p_item_mast_attr_rec.item_number
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
                 RETURN  x_error_code;
       END is_wip_supply_type_valid;

       -- End wave1 validations
     BEGIN
       g_api_name := 'item_mast_attr_validations';
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Item Master Attribute Data-Validations');
       x_error_code_temp := is_organization_valid(p_item_mast_attr_rec.organization_code,
                                                  p_item_mast_attr_rec.organization_id
		                                             );
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_item_number_valid(p_item_mast_attr_rec.item_number,
		                                             p_item_mast_attr_rec.inventory_item_id);
	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);


        x_error_code_temp := is_atp_rule_valid(p_item_mast_attr_rec.atp_rule,
                                            p_item_mast_attr_rec.atp_rule_id);

	      x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);


       x_error_code_temp := is_check_atp_valid(p_item_mast_attr_rec.check_atp,
                                               p_item_mast_attr_rec.atp_flag);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_collateral_item_valid(p_item_mast_attr_rec.collateral_item,
                                               p_item_mast_attr_rec.collateral_flag);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_container_item_valid(p_item_mast_attr_rec.container,
                                               p_item_mast_attr_rec.container_item_flag);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_lot_status_valid(p_item_mast_attr_rec.lot_status_enabled);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_default_lot_status_valid(p_item_mast_attr_rec.default_lot_status,
                                                        p_item_mast_attr_rec.default_lot_status_id);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_serial_status_valid(p_item_mast_attr_rec.serial_status_enabled);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_default_serial_status_valid(p_item_mast_attr_rec.default_serial_status,
                                                           p_item_mast_attr_rec.default_serial_status_id);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_default_shipping_org_valid(p_item_mast_attr_rec.default_shipping_organization,
                                                        p_item_mast_attr_rec.default_shipping_org);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_dimension_uom_code_valid(p_item_mast_attr_rec.dimension_unit_of_measure,
                                                          p_item_mast_attr_rec.dimension_uom_code);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_hazard_class_code_valid(p_item_mast_attr_rec.hazard_class,
                                                          p_item_mast_attr_rec.hazard_class_id);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_height_valid(p_item_mast_attr_rec.height,
                                                          p_item_mast_attr_rec.unit_height);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_length_valid(p_item_mast_attr_rec.length,
                                                          p_item_mast_attr_rec.unit_length);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_installed_base_valid(p_item_mast_attr_rec.track_in_installed_base
                                                    ,p_item_mast_attr_rec.comms_nl_trackable_flag);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_item_instance_class_valid(p_item_mast_attr_rec.item_instance_class
                                                    ,p_item_mast_attr_rec.ib_item_instance_class);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);


       x_error_code_temp := is_lot_control_code_valid(p_item_mast_attr_rec.lot_control
                                                    ,p_item_mast_attr_rec.lot_control_code); -- Also used in wave1

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_lot_expiration_valid(p_item_mast_attr_rec.lot_expiration
                                                    ,p_item_mast_attr_rec.shelf_life_code); -- Also used in wave1

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_orderable_on_web_valid( p_item_mast_attr_rec.orderable_on_the_web
                                                      ,p_item_mast_attr_rec.orderable_on_web_flag);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);


       x_error_code_temp := is_outside_process_item_valid(p_item_mast_attr_rec.outside_processing_item,
                                                         p_item_mast_attr_rec.outside_operation_flag);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_outsid_proc_unit_typ_valid(p_item_mast_attr_rec.outside_processing_unit_type,
                                                         p_item_mast_attr_rec.outside_operation_uom_type);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_serial_number_gen_valid(p_item_mast_attr_rec.serial_number_generation,
                                                         p_item_mast_attr_rec.serial_number_control_code); -- Also used in wave1

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_volume_uom_code_valid(p_item_mast_attr_rec.volume_unit_of_measure,
                                                          p_item_mast_attr_rec.volume_uom_code);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);


       x_error_code_temp := is_weight_uom_code_valid(p_item_mast_attr_rec.weight_unit_of_measure,
                                                          p_item_mast_attr_rec.weight_uom_code);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);


       x_error_code_temp := is_use_apprvd_suppl_valid(p_item_mast_attr_rec.use_approved_supplier,
                                                          p_item_mast_attr_rec.must_use_approved_vendor_flag);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_vehicle_valid(p_item_mast_attr_rec.vehicle,
                                                          p_item_mast_attr_rec.vehicle_item_flag);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_web_status_valid(p_item_mast_attr_rec.web_status);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_lot_divisible_valid(p_item_mast_attr_rec.lot_divisible
                                                    ,p_item_mast_attr_rec.lot_divisible_flag);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       -- New Validations for wave1
       x_error_code_temp := is_buyer_valid(p_item_mast_attr_rec.buyer,
                                                 p_item_mast_attr_rec.buyer_id);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_list_price_valid(p_item_mast_attr_rec.list_price,
                                                       p_item_mast_attr_rec.list_price_per_unit);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_receipt_routing_valid(p_item_mast_attr_rec.receipt_routing,
                                                 p_item_mast_attr_rec.receiving_routing_id);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_item_status_valid(p_item_mast_attr_rec.inventory_item_status_code
                                                 ,p_item_mast_attr_rec.inv_item_status_code_orig);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

      x_error_code_temp := is_item_type_valid(p_item_mast_attr_rec.item_type
                                                 ,p_item_mast_attr_rec.item_type_orig);


       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_cust_order_flag_valid(p_item_mast_attr_rec.customer_order_flag);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_cust_ord_enable_flag_valid(p_item_mast_attr_rec.customer_order_enabled_flag);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_pur_enabled_flag_valid(p_item_mast_attr_rec.purchasing_enabled_flag);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_pur_item_flag_valid(p_item_mast_attr_rec.purchasing_item_flag);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_assemble_to_order_valid(p_item_mast_attr_rec.replenish_to_order_flag);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

        x_error_code_temp := is_build_in_wip_flag_valid(p_item_mast_attr_rec.build_in_wip_flag);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_wip_supply_type_valid(p_item_mast_attr_rec.wip_supply_type
                                                    ,p_item_mast_attr_rec.wip_supply_type_orig);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       -- End New Validations for wave1

       xx_emf_pkg.propagate_error ( x_error_code_temp);

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

   END item_mast_attr_validations;


  FUNCTION item_mast_attr_derivations(p_item_mast_attr_rec IN OUT xx_inv_item_attr_upd_pkg.G_XX_ITEM_MAST_STG_REC_TYPE
                          ) RETURN NUMBER
     IS
     --------------------------------------------------------------------------------------
    -- Created By                 : Partha S Mohanty
    -- Creation Date              : 25-APR-2012
    -- Description                : Derive corresponding values in Oracle

    -- Parameters description:

    -- @param1         :p_item_mast_attr_rec(IN OUT)
   -----------------------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN

            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Derivation');

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
   END item_mast_attr_derivations;

  -- post Validation
  FUNCTION post_validations
   RETURN NUMBER
        IS
    --------------------------------------------------------------------------------------
    -- Created By                 : Partha S Mohanty
    -- Creation Date              : 25-APR-2012
    -- Description                : Psot validation processes

    -- Parameters description:

    -- @param1         :
   -----------------------------------------------------------------------------------------
		x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         BEGIN

            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside post_validations');

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
	  END post_validations;

    FUNCTION item_assgn_validations(p_item_org_assgn_rec IN OUT xx_inv_item_attr_upd_pkg.G_XX_ITEM_ASSGN_STG_REC_TYPE
                          ) RETURN NUMBER
     IS
    --------------------------------------------------------------------------------------
    -- Created By                 : Partha S Mohanty
    -- Creation Date              : 25-APR-2012
    -- Description                : Validate staging table values and derive corresponding value in Oracle

    -- Parameters description:

    -- @param1         :p_item_org_attr_rec(IN OUT)
   -----------------------------------------------------------------------------------------
      x_invorg_id          NUMBER := NULL;
      x_source_org_id      NUMBER := NULL;
      x_inv_item_id        NUMBER := NULL;
      x_org_code           VARCHAR2(3):= NULL;
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;


       FUNCTION is_org_code_valid(p_org_code VARCHAR2,p_org_id OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive organization_id and organization_code
       -- @param1 -- p_org_code(OUT)
		   -- @param2 -- p_org_id(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         begin
          IF p_org_code IS NULL THEN
                dbg_med('Organization Code can not be Null in Organization_Assignment');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Organization Code can not be Null in Organization_Assignment'
                         ,p_record_identifier_1 => p_item_org_assgn_rec.record_number
                         ,p_record_identifier_2 => p_item_org_assgn_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_assgn_rec.item_number
                         ,p_record_identifier_4 => 'ASSGN_ORG'
                        );

              return x_error_code;
          ELSE
           BEGIN
               /*x_org_code := xx_intg_common_pkg.get_mapping_value(p_mapping_type =>'ORGANIZATION_CODE'
                                  ,p_source      =>NULL
                                  ,p_old_value1   =>trim(p_org_code)
                                  ,p_old_value2   =>'XXINTGBOMCONV'
                                  ,p_date_effective => sysdate
                                  );
               dbg_low('Mapped Organization Code in Organization_Assignment: '||x_org_code);*/
               SELECT mp.organization_id
                 INTO x_invorg_id
                 FROM mtl_parameters mp
                WHERE mp.organization_code = p_org_code;
                p_org_id := x_invorg_id;
                RETURN  x_error_code;
             EXCEPTION
               WHEN no_data_found THEN
                  dbg_med('Organization Code does not exist in Organization_Assignment');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Organization Code does not exist in Organization_Assignment'
                         ,p_record_identifier_1 => p_item_org_assgn_rec.record_number
                         ,p_record_identifier_2 => p_item_org_assgn_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_assgn_rec.item_number
                         ,p_record_identifier_4 => 'ASSGN_ORG'
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the Organization Code in Organization_Assignment');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Organization Code in Organization_Assignment'
                         ,p_record_identifier_1 => p_item_org_assgn_rec.record_number
                         ,p_record_identifier_2 => p_item_org_assgn_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_assgn_rec.item_number
                         ,p_record_identifier_4 => 'ASSGN_ORG'
                        );
                RETURN  x_error_code;
             END;
         END IF;
      END is_org_code_valid;

      FUNCTION is_item_number_valid(p_item_number VARCHAR2,p_item_inv_id OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive item_id
		   --@param1 -- p_item_number
		   --@param2 -- p_item_inv_id(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
          IF p_item_number IS NULL THEN
                dbg_med('Item Number can not be Null in Organization_Assignment');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Item Number can not be Null in Organization_Assignment'
                         ,p_record_identifier_1 => p_item_org_assgn_rec.record_number
                         ,p_record_identifier_2 => p_item_org_assgn_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_assgn_rec.item_number
                         ,p_record_identifier_4 => 'ASSGN_ORG'
                        );

              return x_error_code;
         ELSE
            ---
              BEGIN
                 SELECT a.inventory_item_id
                  INTO x_inv_item_id
                 FROM mtl_system_items_b a
                  WHERE a.segment1 = UPPER(TRIM(p_item_number))
                     AND a.organization_id = fnd_profile.value('MSD_MASTER_ORG'); --x_invorg_id;

                  p_item_inv_id :=  x_inv_item_id;

                  RETURN  x_error_code;
               EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid Item Number in Organization_Assignment');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid Item Number in Organization_Assignment'
                         ,p_record_identifier_1 => p_item_org_assgn_rec.record_number
                         ,p_record_identifier_2 => p_item_org_assgn_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_assgn_rec.item_number
                         ,p_record_identifier_4 => 'ASSGN_ORG'
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing Item Number');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing Item Number in Organization_Assignment'
                         ,p_record_identifier_1 => p_item_org_assgn_rec.record_number
                         ,p_record_identifier_2 => p_item_org_assgn_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_assgn_rec.item_number
                         ,p_record_identifier_4 => 'ASSGN_ORG'
                        );
                  RETURN  x_error_code;
              END ;
          END IF;
       END is_item_number_valid;
    BEGIN
       g_api_name := 'item_assgn_validations';

       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Item Organization Assignment validations');
       x_error_code_temp := is_org_code_valid(p_item_org_assgn_rec.organization_code,
                                              p_item_org_assgn_rec.organization_id);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_item_number_valid(p_item_org_assgn_rec.item_number,
                                              p_item_org_assgn_rec.inventory_item_id);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       xx_emf_pkg.propagate_error ( x_error_code_temp);

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
   END item_assgn_validations;

   FUNCTION item_assgn_derivations(p_item_org_assgn_rec IN OUT xx_inv_item_attr_upd_pkg.G_XX_ITEM_ASSGN_STG_REC_TYPE
                          ) RETURN NUMBER
       IS
    --------------------------------------------------------------------------------------
    -- Created By                 : Partha S Mohanty
    -- Creation Date              : 25-APR-2012
    -- Description                : Derive corresponding values in Oracle

    -- Parameters description:

    -- @param1         :p_item_org_assgn_rec(IN OUT)
   -----------------------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN

            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Assignment Data-Derivation');

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
   END item_assgn_derivations;


    FUNCTION item_org_attr_validations(p_item_org_attr_rec IN OUT xx_inv_item_attr_upd_pkg.G_XX_ITEM_ORG_STG_REC_TYPE
                          ) RETURN NUMBER
     IS
    --------------------------------------------------------------------------------------
    -- Created By                 : Partha S Mohanty
    -- Creation Date              : 25-APR-2012
    -- Description                : Validate staging table values and derive corresponding value in Oracle

    -- Parameters description:

    -- @param1         :p_item_org_attr_rec(IN OUT)
   -----------------------------------------------------------------------------------------
      x_invorg_id          NUMBER := NULL;
      x_source_org_id      NUMBER := NULL;
      x_inv_item_id        NUMBER := NULL;
      x_org_code           VARCHAR2(3):= NULL;
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;


       FUNCTION is_org_code_valid(p_org_code VARCHAR2,p_org_id OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive organization_id and organization_code
       -- @param1 -- p_org_code(OUT)
		   -- @param2 -- p_org_id(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         begin
          IF p_org_code IS NULL THEN
                dbg_med('Organization Code can not be Null ');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Organization Code can not be Null'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );

              return x_error_code;
          ELSE
           BEGIN
               /*x_org_code := xx_intg_common_pkg.get_mapping_value(p_mapping_type =>'ORGANIZATION_CODE'
                                  ,p_source      =>NULL
                                  ,p_old_value1   =>trim(p_org_code)
                                  ,p_old_value2   =>'XXINTGBOMCONV'
                                  ,p_date_effective => sysdate
                                  );
               dbg_low('Mapped Organization Code : '||x_org_code);*/
               SELECT mp.organization_id
                 INTO x_invorg_id
                 FROM mtl_parameters mp
                WHERE mp.organization_code = p_org_code;
                p_org_id := x_invorg_id;
                RETURN  x_error_code;
             EXCEPTION
               WHEN no_data_found THEN
                  dbg_med('Organization Code does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Organization Code does not exist'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the Organization Code');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Organization Code'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                RETURN  x_error_code;
             END;
         END IF;
      END is_org_code_valid;

      FUNCTION is_item_number_valid(p_item_number VARCHAR2,p_item_inv_id OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive item_id
		   --@param1 -- p_item_number
		   --@param2 -- p_item_inv_id(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
          IF p_item_number IS NULL THEN
                dbg_med('Item Number can not be Null ');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Item Number can not be Null;'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );

              return x_error_code;
         ELSE
            ---
              BEGIN
                 SELECT a.inventory_item_id
                  INTO x_inv_item_id
                 FROM mtl_system_items_b a
                  WHERE a.segment1 = UPPER(TRIM(p_item_number))
                     AND a.organization_id = fnd_profile.value('MSD_MASTER_ORG'); --;

                  p_item_inv_id :=  x_inv_item_id;

                  RETURN  x_error_code;
               EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid Item Number');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid Item Number'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing Item Number');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing Item Number'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
              END ;
          END IF;
       END is_item_number_valid;




      FUNCTION is_asset_category_valid(p_asset_category VARCHAR2,p_asset_category_id OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive asset_category_id
       -- @param1 -- p_asset_category(IN)
		   -- @param2 -- p_asset_category_id(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_category_id NUMBER := NULL;
       BEGIN
         IF p_asset_category IS NOT NULL THEN
           BEGIN
               SELECT category_id INTO x_category_id
                 FROM fa_categories_b
                WHERE upper(segment1)||'.'||(segment2) = UPPER(p_asset_category);
                 p_asset_category_id := x_category_id;
                 RETURN  x_error_code;
           EXCEPTION
             WHEN no_data_found THEN
                  dbg_med('Asset Category does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Asset Category does not exist'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
             WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the Asset Category');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Asset Category'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
           END;
         END IF;
         RETURN  x_error_code;
      END is_asset_category_valid;

      FUNCTION is_calculate_atp_valid(p_calculate_atp VARCHAR2,p_calculate_atp_flag OUT VARCHAR2)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive mrp_calculate_atp_flag
       -- @param1 -- p_calculate_atp(IN)
		   -- @param2 -- p_calculate_atp_flag(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_calculate_atp_flag VARCHAR2(1) := NULL;
       BEGIN
         IF p_calculate_atp IS NOT NULL THEN
             IF UPPER(TRIM(p_calculate_atp)) IN ('YES','Y') THEN
                x_calculate_atp_flag := 'Y';
             ELSIF UPPER(TRIM(p_calculate_atp)) IN ('NO','N') THEN
                x_calculate_atp_flag := 'N';
             ELSE
                dbg_med('Invalid calculate_atp');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid calculate_atp'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
             END IF;
         END IF;
         p_calculate_atp_flag := x_calculate_atp_flag;
         RETURN  x_error_code;
        EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing calculate_atp');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing calculate_atp'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_calculate_atp_valid;

      FUNCTION is_container_type_valid(p_container_type VARCHAR2,p_container_type_code OUT VARCHAR2)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive container_type_code
       -- @param1 -- p_container_type(IN)
		   -- @param2 -- is_container_type_valid(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_container_type_code VARCHAR2(30) := NULL;
       BEGIN
         IF p_container_type IS NOT NULL THEN
             SELECT lookup_code INTO x_container_type_code
                FROM fnd_common_lookups
              WHERE lookup_type = 'CONTAINER_TYPE'
                AND enabled_flag = 'Y'
                AND sysdate between nvl(start_date_active, sysdate)
                AND nvl(end_date_active, sysdate)
                AND UPPER(meaning)=UPPER(TRIM(p_container_type));

          END IF;
              p_container_type_code := x_container_type_code;
              RETURN x_error_code;

        EXCEPTION
             WHEN no_data_found THEN
                  dbg_med('container_type does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'container_type does not exist'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
             WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the container_type');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the container_type'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_container_type_valid;

       FUNCTION is_create_fixed_asset_valid(p_create_fixed_asset VARCHAR2,p_asset_creation_code OUT VARCHAR2)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive asset_creation_code
       -- @param1 -- p_create_fixed_asset(IN)
		   -- @param2 -- p_asset_creation_code(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_asset_creation_code VARCHAR2(30) := NULL;
       BEGIN
         IF p_create_fixed_asset IS NOT NULL THEN
             IF UPPER(TRIM(p_create_fixed_asset)) IN ('YES','Y') THEN
                x_asset_creation_code := '1';
             ELSIF UPPER(TRIM(p_create_fixed_asset)) IN ('NO','N') THEN
                x_asset_creation_code := '0';
             ELSE
                dbg_med('Invalid create_fixed_asset');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid create_fixed_asset'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
             END IF;
         END IF;
         p_asset_creation_code := x_asset_creation_code;
         RETURN  x_error_code;
        EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating create_fixed_asset');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating create_fixed_asset'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_create_fixed_asset_valid;


       FUNCTION is_demand_time_fence_valid(p_demand_time_fence VARCHAR2,p_demand_time_fence_code OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive demand_time_fence_code
       -- @param1 -- p_demand_time_fence(IN)
		   -- @param2 -- p_demand_time_fence_code(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_demand_time_fence_code NUMBER := NULL;
       BEGIN
         IF p_demand_time_fence IS NOT NULL THEN
             IF UPPER(TRIM(p_demand_time_fence)) = 'CUMULATIVE MFG. LEAD TIME' THEN
                x_demand_time_fence_code := 2;
             ELSIF UPPER(TRIM(p_demand_time_fence)) = 'CUMULATIVE TOTAL LEAD TIME' THEN
                x_demand_time_fence_code := 1;
             ELSIF UPPER(TRIM(p_demand_time_fence)) = 'TOTAL LEAD TIME' THEN
                x_demand_time_fence_code := 3;
             ELSIF UPPER(TRIM(p_demand_time_fence)) = 'USER-DEFINED' THEN
                x_demand_time_fence_code := 4;
             ELSE
                dbg_med('Invalid demand_time_fence');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid demand_time_fence'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
             END IF;
         END IF;
         p_demand_time_fence_code := x_demand_time_fence_code;
         RETURN  x_error_code;
        EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating demand_time_fence');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating demand_time_fence'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_demand_time_fence_valid;


       FUNCTION is_equipment_valid(p_equipment VARCHAR2,p_equipment_type OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive equipment_type
       -- @param1 -- p_equipment(IN)
		   -- @param2 -- p_equipment_type(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_equipment_type NUMBER := NULL;
       BEGIN
         IF p_equipment IS NOT NULL THEN
             IF UPPER(TRIM(p_equipment)) IN ('YES','Y') THEN
                x_equipment_type := 1;
             ELSIF UPPER(TRIM(p_equipment)) IN ('NO','N') THEN
                x_equipment_type := 2;
             ELSE
                dbg_med('Invalid equipment');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid equipment'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
             END IF;
         END IF;
         p_equipment_type := x_equipment_type;
         RETURN  x_error_code;
        EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing demand_time_fence');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing demand_time_fence'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_equipment_valid;

      FUNCTION is_exclude_from_budget_valid(p_exclude_from_budget VARCHAR2,p_exclude_from_budget_flag OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive equipment_type
       -- @param1 -- p_equipment(IN)
		   -- @param2 -- p_equipment_type(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_exclude_from_budget_flag NUMBER := NULL;
       BEGIN
         IF p_exclude_from_budget IS NOT NULL THEN
             IF UPPER(TRIM(p_exclude_from_budget)) IN ('YES','Y') THEN
                x_exclude_from_budget_flag := 1;
             ELSIF UPPER(TRIM(p_exclude_from_budget)) IN ('NO','N') THEN
                x_exclude_from_budget_flag := 2;
             ELSE
                dbg_med('Invalid exclude_from_budget');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid exclude_from_budget'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
             END IF;
         END IF;
         p_exclude_from_budget_flag := x_exclude_from_budget_flag;
         RETURN  x_error_code;
        EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing exclude_from_budget');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing exclude_from_budget'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_exclude_from_budget_valid;

      FUNCTION is_input_tax_class_code_valid(p_input_tax_class_code VARCHAR2,p_purchasing_tax_code OUT VARCHAR2)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive purchasing_tax_code
       -- @param1 -- p_input_tax_class_code(IN)
		   -- @param2 -- p_purchasing_tax_code(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_purchasing_tax_code VARCHAR2(50) := NULL;
       BEGIN
          IF p_input_tax_class_code IS NOT NULL THEN
               SELECT DISTINCT lk.Lookup_Code INTO  x_purchasing_tax_code
                 FROM zx_input_classifications_v lk
                WHERE nvl(lk.tax_type,'X') not in ('AWT','OFFSET')
                 AND   lk.enabled_flag = 'Y'
                 AND   sysdate between start_date_active and nvl(end_date_active,sysdate)
                 AND   ORG_ID IN (-99, (select operating_unit from org_organization_definitions
		                                       WHERE organization_id = x_invorg_id))
                 AND  upper(trim(lk.Lookup_Code)) =  upper(trim(p_input_tax_class_code));
            END IF;
                 p_purchasing_tax_code := x_purchasing_tax_code;
                 RETURN  x_error_code;
           EXCEPTION
             WHEN no_data_found THEN
                  dbg_med('input_tax_classification_code does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'input_tax_classification_code does not exist'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
             WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the input_tax_classification_code');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the input_tax_classification_code'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
      END is_input_tax_class_code_valid;

      FUNCTION is_inv_planning_method_valid(p_inv_planning_method VARCHAR2,p_inventory_planning_code OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive inventory_planning_code
       -- @param1 -- p_inv_planning_method(IN)
		   -- @param2 -- p_inventory_planning_code(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_inventory_planning_code NUMBER := NULL;
       BEGIN
         IF p_inv_planning_method IS NOT NULL THEN
             IF UPPER(TRIM(p_inv_planning_method)) = 'NOT PLANNED' THEN
                x_inventory_planning_code := 6;
             ELSIF UPPER(TRIM(p_inv_planning_method)) = 'MIN-MAX' THEN
                x_inventory_planning_code := 2;
             ELSIF UPPER(TRIM(p_inv_planning_method)) = 'REORDER POINT' THEN
                x_inventory_planning_code := 1;
             ELSIF UPPER(TRIM(p_inv_planning_method)) = 'VENDOR MANAGED' THEN
                x_inventory_planning_code := 7;
             ELSE
                dbg_med('Invalid inventory_planning_method');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid inventory_planning_method'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
             END IF;
         END IF;
         p_inventory_planning_code := x_inventory_planning_code;
         RETURN  x_error_code;
        EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing inventory_planning_method');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing inventory_planning_method'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_inv_planning_method_valid;

       FUNCTION is_list_price_valid(p_list_price NUMBER,p_list_price_per_unit OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive list_price
       -- @param1 -- p_list_price(IN)
		   -- @param2 -- p_list_price_per_unit(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

       BEGIN
         IF p_list_price IS NOT NULL THEN
             p_list_price_per_unit := p_list_price;
         END IF;
         RETURN  x_error_code;
       EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating list_price');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating list_price'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
       END is_list_price_valid;



       FUNCTION is_make_or_buy_valid(p_make_or_buy VARCHAR2,p_planning_make_buy_code OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive planning_make_buy_code
       -- @param1 -- p_make_or_buy(IN)
		   -- @param2 -- p_planning_make_buy_code(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_planning_make_buy_code NUMBER := NULL;
       BEGIN
         IF p_make_or_buy IS NOT NULL THEN
             IF UPPER(TRIM(p_make_or_buy)) = 'MAKE' THEN
                x_planning_make_buy_code := 1;
             ELSIF UPPER(TRIM(p_make_or_buy)) = 'BUY' THEN
                x_planning_make_buy_code := 2;
             ELSE
                dbg_med('Invalid make_or_buy');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid make_or_buy'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
             END IF;
         END IF;
         p_planning_make_buy_code := x_planning_make_buy_code;
         RETURN  x_error_code;
        EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing make_or_buy');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing make_or_buy'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_make_or_buy_valid;

      FUNCTION is_min_max_maximum_qty_valid(p_min_max_maximum_qty NUMBER,p_max_minmax_quantity OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive max_minmax_quantity
       -- @param1 -- p_min_max_maximum_qty(IN)
		   -- @param2 -- p_max_minmax_quantity(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

       BEGIN
         IF p_min_max_maximum_qty IS NOT NULL THEN
             p_max_minmax_quantity := p_min_max_maximum_qty;
         END IF;
         RETURN  x_error_code;
       EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating max_minmax_quantity');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating max_minmax_quantity'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
       END is_min_max_maximum_qty_valid;

       FUNCTION is_min_max_minimum_qty_valid(p_min_max_minimum_qty NUMBER,p_min_minmax_quantity OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive min_minmax_quantity
       -- @param1 -- p_min_max_minimum_qty(IN)
		   -- @param2 -- p_min_minmax_quantity(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

       BEGIN
         IF p_min_max_minimum_qty IS NOT NULL THEN
             p_min_minmax_quantity := p_min_max_minimum_qty;
         END IF;
         RETURN  x_error_code;
       EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating min_minmax_quantity');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating min_minmax_quantity'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_min_max_minimum_qty_valid;

       FUNCTION is_om_indivisible_valid(p_om_indivisible VARCHAR2,p_indivisible_flag OUT VARCHAR2)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive indivisible_flag
       -- @param1 -- p_om_indivisible(IN)
		   -- @param2 -- p_indivisible_flag(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_indivisible_flag  VARCHAR2(1) := NULL;
       BEGIN
         IF p_om_indivisible IS NOT NULL THEN
             IF UPPER(TRIM(p_om_indivisible)) IN ('YES','Y') THEN
                x_indivisible_flag := 'Y';
             ELSIF UPPER(TRIM(p_om_indivisible)) IN ('NO','N') THEN
                x_indivisible_flag := NULL;
             ELSE
                dbg_med('Invalid om_indivisible');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid om_indivisible'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
             END IF;
         END IF;
         p_indivisible_flag := x_indivisible_flag;
         RETURN  x_error_code;
       EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating om_indivisible');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating om_indivisible'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_om_indivisible_valid;

       FUNCTION is_planned_inv_point_valid(p_planned_inv_point VARCHAR2,p_planned_inv_point_flag OUT VARCHAR2)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive planned_inventory_point_flag
       -- @param1 -- p_planned_inv_point(IN)
		   -- @param2 -- p_planned_inv_point_flag(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_planned_inv_point_flag  VARCHAR2(1) := NULL;
       BEGIN
         IF p_planned_inv_point IS NOT NULL THEN
             IF UPPER(TRIM(p_planned_inv_point)) IN ('YES','Y') THEN
                x_planned_inv_point_flag := 'Y';
             ELSIF UPPER(TRIM(p_planned_inv_point)) IN ('NO','N') THEN
                x_planned_inv_point_flag := NULL;
             ELSE
                dbg_med('Invalid planned_inventory_point');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid planned_inventory_point'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
             END IF;
         END IF;
         p_planned_inv_point_flag := x_planned_inv_point_flag;
         RETURN  x_error_code;
       EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating planned_inventory_point');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating planned_inventory_point'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_planned_inv_point_valid;

      FUNCTION is_planner_valid(p_planner VARCHAR2,p_planner_code OUT VARCHAR2)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive planner_code
       -- @param1 -- p_planner(IN)
		   -- @param2 -- p_planner_code(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_planner_code  VARCHAR2(10) := NULL;
       BEGIN
         IF p_planner IS NOT NULL THEN
             SELECT planner_code  INTO x_planner_code
                FROM mtl_planners
             WHERE nvl(disable_date, sysdate+1) > sysdate
               AND organization_id = x_invorg_id
               AND UPPER(TRIM(planner_code))=UPPER(TRIM(p_planner));
          END IF;
          p_planner_code :=  x_planner_code;
          RETURN  x_error_code;
        EXCEPTION
              WHEN no_data_found THEN
                  dbg_med('planner_code does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'planner_code does not exist'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
              WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the planner_code');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the planner_code'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_planner_valid;

       FUNCTION is_planning_time_fence_valid(p_planning_time_fence VARCHAR2,p_planning_time_fence_code OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive planning_time_fence_code
       -- @param1 -- p_planning_time_fence(IN)
		   -- @param2 -- p_planning_time_fence_code(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_planning_time_fence_code NUMBER := NULL;
       BEGIN
         IF p_planning_time_fence IS NOT NULL THEN
             IF UPPER(TRIM(p_planning_time_fence)) = 'CUMULATIVE TOTAL LEAD TIME' THEN
                x_planning_time_fence_code := 1;
             ELSIF UPPER(TRIM(p_planning_time_fence)) = 'CUMULATIVE MFG. LEAD TIME' THEN
                x_planning_time_fence_code := 2;
             ELSIF UPPER(TRIM(p_planning_time_fence)) = 'TOTAL LEAD TIME' THEN
                x_planning_time_fence_code := 3;
             ELSIF UPPER(TRIM(p_planning_time_fence)) = 'USER-DEFINED' THEN
                x_planning_time_fence_code := 4;
             ELSE
                dbg_med('Invalid planning_time_fence');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid planning_time_fence'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
             END IF;
         END IF;
         p_planning_time_fence_code := x_planning_time_fence_code;
         RETURN  x_error_code;
       EXCEPTION
         WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the planning_time_fence');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the planning_time_fence'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_planning_time_fence_valid;

       FUNCTION is_processing_lead_time_valid(p_processing_lead_time NUMBER,p_full_lead_time OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive processing_lead_time
       -- @param1 -- p_processing_lead_time(IN)
		   -- @param2 -- p_full_lead_time(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

       BEGIN
         IF p_processing_lead_time IS NOT NULL THEN
             p_full_lead_time := p_processing_lead_time;
         END IF;
         RETURN  x_error_code;
       EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating processing_lead_time');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating processing_lead_time'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
       END is_processing_lead_time_valid;

       FUNCTION is_release_time_fence_valid(p_release_time_fence VARCHAR2,p_release_time_fence_code OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive release_time_fence_code
       -- @param1 -- p_release_time_fence(IN)
		   -- @param2 -- p_release_time_fence_code(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_release_time_fence_code NUMBER := NULL;
       BEGIN
         IF p_release_time_fence IS NOT NULL THEN
             IF UPPER(TRIM(p_release_time_fence)) = 'CUMULATIVE TOTAL LEAD TIME' THEN
                x_release_time_fence_code := 1;
             ELSIF UPPER(TRIM(p_release_time_fence)) = 'CUMULATIVE MFG. LEAD TIME' THEN
                x_release_time_fence_code := 2;
             ELSIF UPPER(TRIM(p_release_time_fence)) = 'TOTAL LEAD TIME' THEN
                x_release_time_fence_code := 3;
             ELSIF UPPER(TRIM(p_release_time_fence)) = 'USER-DEFINED' THEN
                x_release_time_fence_code := 4;
             ELSIF UPPER(TRIM(p_release_time_fence)) = 'DO NOT AUTORELEASE' THEN
                x_release_time_fence_code := 5;
             ELSIF UPPER(TRIM(p_release_time_fence)) = 'KANBAN ITEM (DO NOT RELEASE)' THEN
                x_release_time_fence_code := 6;
             ELSIF UPPER(TRIM(p_release_time_fence)) = 'DO NOT RELEASE (AUTO OR MANUAL)' THEN
                x_release_time_fence_code := 7;
             ELSE
                dbg_med('Invalid release_time_fence');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid release_time_fence'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
             END IF;
         END IF;
         p_release_time_fence_code := x_release_time_fence_code;
         RETURN  x_error_code;
       EXCEPTION
         WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the release_time_fence');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the release_time_fence'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_release_time_fence_valid;


       FUNCTION is_source_org_valid(p_source_org VARCHAR2,p_source_org_id OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive source_organization_id
       -- @param1 -- p_source_org(IN)
		   -- @param2 -- p_source_org_id(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         -- x_source_org_id NUMBER := NULL;
       BEGIN
         IF p_source_org IS NOT NULL THEN
             SELECT ood.organization_id INTO x_source_org_id
                FROM org_organization_definitions ood
              WHERE UPPER(TRIM(ood.organization_code))=UPPER(TRIM(p_source_org));
          END IF;
          p_source_org_id :=  x_source_org_id;
          RETURN  x_error_code;
        EXCEPTION
              WHEN no_data_found THEN
                  dbg_med('source_organization does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'source_organization does not exist'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
              WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the source_organization');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the source_organization'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_source_org_valid;

       FUNCTION is_source_subinventory_valid(p_source_subinventory VARCHAR2)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and source_subinventory
       -- @param1 -- p_source_org(IN)
		   -- @param2 -- p_source_org_id(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_secondary_inventory_name VARCHAR2(10) := NULL;
       BEGIN
         IF p_source_subinventory IS NOT NULL THEN

            SELECT secondary_inventory_name INTO x_secondary_inventory_name
              FROM mtl_secondary_inventories
             WHERE nvl(disable_date, sysdate+1) > sysdate
               AND organization_id = x_source_org_id
               AND UPPER(TRIM(secondary_inventory_name))=UPPER(TRIM(p_source_subinventory));
          END IF;
          RETURN  x_error_code;
        EXCEPTION
              WHEN no_data_found THEN
                  dbg_med('source_subinventory does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'source_subinventory does not exist'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
              WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the source_subinventory');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the source_subinventory'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_source_subinventory_valid;

       FUNCTION is_source_type_valid(p_source_type VARCHAR2,p_source_type_code OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive source_type
       -- @param1 -- p_source_type(IN)
		   -- @param2 -- p_source_type_code(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_source_type_code NUMBER := NULL;
       BEGIN
         IF p_source_type IS NOT NULL THEN
              SELECT lookup_code INTO  x_source_type_code
                from mfg_lookups
                where lookup_type = 'MTL_SOURCE_TYPES'
                AND UPPER(TRIM(meaning))=UPPER(TRIM(p_source_type));
          END IF;
          p_source_type_code :=  x_source_type_code;
          RETURN  x_error_code;
        EXCEPTION
              WHEN no_data_found THEN
                  dbg_med('source_type does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'source_type does not exist'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
              WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the source_type');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the source_type'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_source_type_valid;

       FUNCTION is_substitution_window_valid(p_substitution_window VARCHAR2,p_substitution_window_code OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive substitution_window
       -- @param1 -- p_substitution_window(IN)
		   -- @param2 -- p_substitution_window_code(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_substitution_window_code NUMBER := NULL;
       BEGIN
         IF p_substitution_window IS NOT NULL THEN
             IF UPPER(TRIM(p_substitution_window)) = 'CUMULATIVE TOTAL LEAD TIME' THEN
                x_substitution_window_code := 1;
             ELSIF UPPER(TRIM(p_substitution_window)) = 'CUMULATIVE MFG. LEAD TIME' THEN
                x_substitution_window_code := 2;
             ELSIF UPPER(TRIM(p_substitution_window)) = 'TOTAL LEAD TIME' THEN
                x_substitution_window_code := 3;
             ELSIF UPPER(TRIM(p_substitution_window)) = 'USER-DEFINED' THEN
                x_substitution_window_code := 4;
             ELSE
                dbg_med('Invalid substitution_window');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid substitution_window'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
             END IF;
         END IF;
         p_substitution_window_code := x_substitution_window_code;
         RETURN  x_error_code;
       EXCEPTION
         WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the substitution_window');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the substitution_window'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_substitution_window_valid;

       FUNCTION is_taxable_valid(p_taxable VARCHAR2,p_taxable_flag OUT VARCHAR2)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive taxable_flag
       -- @param1 -- p_taxable(IN)
		   -- @param2 -- p_taxable_flag(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_taxable_flag  VARCHAR2(1) := NULL;
       BEGIN
         IF p_taxable IS NOT NULL THEN
             IF UPPER(TRIM(p_taxable)) IN ('YES','Y') THEN
                x_taxable_flag := 'Y';
             ELSIF UPPER(TRIM(p_taxable)) IN ('NO','N') THEN
                x_taxable_flag := 'N';
             ELSE
                dbg_med('Invalid taxable');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid taxable'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
             END IF;
         END IF;
         p_taxable_flag := x_taxable_flag;
         RETURN  x_error_code;
       EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating taxable');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating taxable'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_taxable_valid;

       FUNCTION is_sales_account_valid(p_sales_account VARCHAR2,p_sales_account_ccid OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and sales_account_ccid
       -- @param1 -- p_sales_account(IN)
		   -- @param2 -- p_sales_account_ccid(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_sales_account_ccid NUMBER := NULL;
       BEGIN
         IF p_sales_account IS NOT NULL THEN
              SELECT code_combination_id INTO x_sales_account_ccid
               from gl_code_combinations
               where trim(segment1||'-'||segment2||'-'||segment3||'-'||segment4||'-'||segment5||'-'||segment6||'-'||segment7||'-'||segment8||'-'||segment9) = trim(p_sales_account);
          END IF;
          p_sales_account_ccid :=  x_sales_account_ccid;
          RETURN  x_error_code;
        EXCEPTION
              WHEN no_data_found THEN
                  dbg_med('sales_account does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'sales_account does not exist'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
              WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the sales_account');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the sales_account'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_sales_account_valid;

       FUNCTION is_expense_account_valid(p_expense_account VARCHAR2,p_expense_account_ccid OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and expense_account_ccid
       -- @param1 -- p_expense_account(IN)
		   -- @param2 -- p_expense_account_ccid(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_expense_account_ccid NUMBER := NULL;
       BEGIN
         IF p_expense_account IS NOT NULL THEN
              SELECT code_combination_id INTO x_expense_account_ccid
               from gl_code_combinations
               where trim(segment1||'-'||segment2||'-'||segment3||'-'||segment4||'-'||segment5||'-'||segment6||'-'||segment7||'-'||segment8||'-'||segment9) = trim(p_expense_account);
          END IF;
          p_expense_account_ccid :=  x_expense_account_ccid;
          RETURN  x_error_code;
        EXCEPTION
              WHEN no_data_found THEN
                  dbg_med('expense_account does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'expense_account does not exist'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
              WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the expense_account');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the expense_account'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_expense_account_valid;

       --=================
       FUNCTION is_receipt_routing_valid(p_receipt_routing VARCHAR2,p_receiv_routing_id OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive equipment_type
       -- @param1 -- p_equipment(IN)
		   -- @param2 -- p_equipment_type(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_receiv_routing_id NUMBER := NULL;
       BEGIN
         IF p_receipt_routing IS NOT NULL THEN
             IF UPPER(TRIM(p_receipt_routing)) IN ('STANDARD') THEN
                x_receiv_routing_id := 1;
             ELSIF UPPER(TRIM(p_receipt_routing)) IN ('INSPECTION') THEN
                x_receiv_routing_id := 2;
             ELSIF UPPER(TRIM(p_receipt_routing)) IN ('DIRECT') THEN
                x_receiv_routing_id := 3;
             ELSE
                dbg_med('Invalid receipt_routing');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid receipt_routing'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
             END IF;
         END IF;
         p_receiv_routing_id := x_receiv_routing_id;
         RETURN  x_error_code;
        EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing receipt_routing');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing receipt_routing'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_receipt_routing_valid;

       FUNCTION is_outside_proc_item_valid(p_outside_proc_item IN VARCHAR2,p_outside_oper_flag OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive is_outside_proc_item_valid
		   --@param1 -- p_outside_proc_item(IN)
		   --@param2 -- p_outside_oper_flag(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_outside_oper_flag  VARCHAR2(1) := NULL;
       BEGIN
         IF p_outside_proc_item IS NOT NULL THEN
              IF UPPER(trim(p_outside_proc_item)) IN('Y','YES') THEN
                    x_outside_oper_flag := 'Y';
              ELSIF UPPER(trim(p_outside_proc_item)) IN('N','NO') THEN
                    x_outside_oper_flag := 'N';
              ELSE
                     dbg_med('Invalid outside_processing_item');
                     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid outside_processing_item'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
               END IF;
          END IF;
          p_outside_oper_flag := x_outside_oper_flag;
          RETURN  x_error_code;
       EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing outside_processing_item');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing outside_processing_item'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_outside_proc_item_valid;

       FUNCTION is_outsid_proc_unit_typ_valid(p_outside_process_unit_type IN VARCHAR2,p_outside_operation_uom_type OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive outside_operation_uom_type
		   -- @param1 -- p_outside_process_unit_type(IN)
		   -- @param2 -- p_outside_operation_uom_type(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_outside_oper_unit_type  VARCHAR2(25) := NULL;
        BEGIN
         IF p_outside_process_unit_type IS NOT NULL THEN
            IF UPPER(trim(p_outside_process_unit_type)) = 'ASSEMBLY' THEN
               x_outside_oper_unit_type := 'ASSEMBLY';
            ELSIF UPPER(trim(p_outside_process_unit_type)) = 'RESOURCE' THEN
               x_outside_oper_unit_type := 'RESOURCE';
            ELSE
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_VALID
              ,p_error_text  => 'Invalid outside_process_unit_type for organization attribute'
              ,p_record_identifier_1 => p_item_org_attr_rec.record_number
              ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
              ,p_record_identifier_3 => p_item_org_attr_rec.item_number
              ,p_record_identifier_4 => 'ORG_ATTR'
              );
            END IF;
          END IF;
          p_outside_operation_uom_type := x_outside_oper_unit_type;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating outside_process_unit_type for organization attribute');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating outside_process_unit_type for organization attribute'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_outsid_proc_unit_typ_valid;

       FUNCTION is_buyer_valid(p_buyer VARCHAR2,p_buyer_id OUT NUMBER)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive buyer_id
       -- @param1 -- p_buyer(IN)
		   -- @param2 -- p_buyer_id(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_buyer_id NUMBER := NULL;
       BEGIN
         IF p_buyer IS NOT NULL THEN
             SELECT ppf.person_id INTO x_buyer_id
                  FROM per_people_f ppf, po_agents poa, per_business_groups_perf pb
                WHERE ppf.person_id = poa.agent_id
                 AND ppf.business_group_id = pb.business_group_id
                 AND SYSDATE BETWEEN NVL(poa.start_date_active, SYSDATE-1)
                 AND NVL(poa.end_date_active,SYSDATE+1)
                 AND TRUNC(SYSDATE) BETWEEN ppf.effective_start_date
                 AND ppf.effective_end_date
                 AND NVL(ppf.current_employee_flag,'N') = 'Y'
                 AND UPPER(ppf.full_name)=UPPER(TRIM(p_buyer));
          END IF;
          p_buyer_id :=  x_buyer_id;
          RETURN  x_error_code;
        EXCEPTION
              WHEN no_data_found THEN
                  dbg_med('buyer does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'buyer does not exist'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
              WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the buyer');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the buyer'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_buyer_valid;

       --- Wave1 validations
       FUNCTION is_atp_rule_valid(p_atp_rule VARCHAR2,p_atp_rule_id OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive atp_rule_id
		   --@param1 -- p_atp_rule
		   --@param2 -- p_atp_rule_id(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_rule_id  NUMBER := NULL;
       BEGIN
          IF p_atp_rule IS NULL THEN
              return x_error_code;
         ELSE
              BEGIN
                 SELECT a.rule_id
                  INTO x_rule_id
                 FROM mtl_atp_rules a
                  WHERE UPPER(trim(a.rule_name)) = UPPER(trim(p_atp_rule));

                  p_atp_rule_id :=  x_rule_id;

                  RETURN  x_error_code;
               EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid ATP Rule');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid ATP Rule'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing ATP Rule');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing ATP Rule'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
              END ;
          END IF;
       END is_atp_rule_valid;

       FUNCTION is_def_shipping_org_valid(p_default_ship_org VARCHAR2,
                                          p_default_ship_org_orig OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive default_lot_status_id
		   --@param1 -- p_default_lot_status(IN)
       --@param2 -- p_default_lot_status_id(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_organization_id  NUMBER := NULL;
        BEGIN
          IF  p_default_ship_org IS NOT NULL THEN
              select mp.organization_id INTO x_organization_id
              from hr_organization_units hou
                    ,mtl_parameters mp
              where mp.organization_id = hou.organization_id
                    and nvl(hou.date_to, sysdate+1) > sysdate
                    and UPPER(TRIM(hou.name)) = UPPER(TRIM(p_default_ship_org));
           END IF;
                p_default_ship_org_orig := x_organization_id;
                RETURN  x_error_code;
         EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid default_shipping_org');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid default_shipping_org'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                   RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing default_shipping_org');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing default_shipping_org'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );

                 RETURN  x_error_code;
       END is_def_shipping_org_valid;

       FUNCTION is_atp_components_valid(p_atp_components VARCHAR2,p_atp_components_flag OUT VARCHAR2)
       RETURN number
       IS
       ------------------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive equipment_type
       -- @param1 -- p_equipment(IN)
		   -- @param2 -- p_equipment_type(OUT)
		   -------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_atp_components_flag VARCHAR2(1) := NULL;
       BEGIN
         IF p_atp_components IS NOT NULL THEN
             IF UPPER(TRIM(p_atp_components)) IN ('NONE') THEN
                x_atp_components_flag := 'N';
             ELSIF UPPER(TRIM(p_atp_components)) IN ('MATERIAL ONLY') THEN
                x_atp_components_flag := 'Y';
             ELSIF UPPER(TRIM(p_atp_components)) IN ('RESOURCE ONLY') THEN
                x_atp_components_flag := 'R';
             ELSIF UPPER(TRIM(p_atp_components)) IN ('MATERIAL AND RESOURCE') THEN
                x_atp_components_flag := 'C';
             ELSE
                dbg_med('Invalid atp_components_flag');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid atp_components_flag'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
             END IF;
         END IF;
         p_atp_components_flag := x_atp_components_flag;
         RETURN  x_error_code;
        EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing atp_components_flag');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing atp_components_flag'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_atp_components_valid;

       FUNCTION is_lot_control_code_valid(p_lot_control IN VARCHAR2,p_lot_control_code OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive lot_control_code
		   --@param1 -- p_lot_control(IN)
		   --@param2 -- p_lot_control_code(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_lot_control_code  NUMBER := NULL;
       BEGIN
         IF p_lot_control IS NOT NULL THEN
            IF UPPER(trim(p_lot_control)) = 'NO CONTROL' THEN
               x_lot_control_code := 1;
            ELSIF UPPER(trim(p_lot_control)) = 'FULL CONTROL' THEN
               x_lot_control_code := 2;
            ELSE
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_VALID
              ,p_error_text  => 'Invalid lot_control'
              ,p_record_identifier_1 => p_item_org_attr_rec.record_number
              ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
              ,p_record_identifier_3 => p_item_org_attr_rec.item_number
              ,p_record_identifier_4 => 'ORG_ATTR'
              );
            END IF;
          END IF;
          p_lot_control_code := x_lot_control_code;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating lot_control');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating lot_control'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_lot_control_code_valid;

     FUNCTION is_lot_expiration_valid(p_lot_expiration IN VARCHAR2,p_shelf_life_code OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive shelf_life_code
		   --@param1 -- p_lot_expiration(IN)
		   --@param2 -- p_shelf_life_code(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_shelf_life_code  NUMBER := NULL;
       BEGIN
         IF p_lot_expiration IS NOT NULL THEN
            IF UPPER(trim(p_lot_expiration)) = 'NO CONTROL' THEN
               x_shelf_life_code := 1;
            ELSIF UPPER(trim(p_lot_expiration)) = 'SHELF LIFE DAYS' THEN
               x_shelf_life_code := 2;
            ELSIF UPPER(trim(p_lot_expiration)) = 'USER-DEFINED' THEN
               x_shelf_life_code := 4;
            ELSE
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_VALID
              ,p_error_text  => 'Invalid lot_expiration'
              ,p_record_identifier_1 => p_item_org_attr_rec.record_number
              ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
              ,p_record_identifier_3 => p_item_org_attr_rec.item_number
              ,p_record_identifier_4 => 'ORG_ATTR'
              );

            END IF;
         END IF;
         p_shelf_life_code := x_shelf_life_code;
         RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating lot_expiration');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating lot_expiration'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_lot_expiration_valid;

       FUNCTION is_reservable_valid(p_reservable IN VARCHAR2,p_reservable_type OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive cust_ord_enable_flag
		   -- @param1 -- p_cust_order_enable_flag(IN OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
         IF p_reservable IS NOT NULL THEN
            IF UPPER(trim(p_reservable))  IN ('Y','1') THEN
               p_reservable_type:= 1;
            ELSIF UPPER(trim(p_reservable)) IN ('N','2')  THEN
               p_reservable_type:= 2;
            ELSE
                  dbg_med('Invalid reservable_type');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid reservable_type'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                         );
             END IF;
          END IF;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating reservable_type');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating reservable_type'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_reservable_valid;

       FUNCTION is_default_lot_status_valid(p_default_lot_status VARCHAR2,
                                            p_default_lot_status_id OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive default_lot_status_id
		   --@param1 -- p_default_lot_status(IN)
       --@param2 -- p_default_lot_status_id(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_status_id  NUMBER := NULL;
        BEGIN
          IF  p_default_lot_status IS NOT NULL THEN
              SELECT status_id INTO x_status_id
                 FROM  mtl_material_statuses_vl
                WHERE  lot_control = 1
                 AND  enabled_flag = 1
                 AND UPPER(trim(status_code)) = UPPER(trim(p_default_lot_status));
           END IF;
                p_default_lot_status_id := x_status_id;
                RETURN  x_error_code;
         EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid default_lot_status');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid default_lot_status'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                   RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing default_lot_status');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing default_lot_status'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );

                 RETURN  x_error_code;
       END is_default_lot_status_valid;

       FUNCTION is_check_atp_valid(p_check_atp VARCHAR2,p_atp_flag OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive atp_flag
		   --@param1 -- p_ceck_atp
		   --@param2 -- p_atp_flag(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_atp_flag VARCHAR2(1) := NULL;
       BEGIN
          IF p_check_atp IS NOT NULL THEN
                 IF UPPER(trim(p_check_atp)) = 'NONE' THEN
                     x_atp_flag := 'N';
                 ELSIF UPPER(trim(p_check_atp)) = 'MATERIAL ONLY' THEN
                     x_atp_flag := 'Y';
                 ELSIF UPPER(trim(p_check_atp)) = 'RESOURCE ONLY' THEN
                     x_atp_flag := 'R';
                 ELSIF UPPER(trim(p_check_atp)) = 'MATERIAL AND RESOURCE' THEN
                     x_atp_flag := 'C';
                 ELSE
                     dbg_med('Invalid Check_ATP Flag');
                     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid Check_ATP Flag'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                END IF;
            END IF;
            p_atp_flag := x_atp_flag;
            RETURN  x_error_code;
       EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing Check_ATP Flag');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing Check_ATP Flag'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                  RETURN  x_error_code;
       END is_check_atp_valid;

       FUNCTION is_serial_number_gen_valid(p_serial_number_gen IN VARCHAR2,p_serial_number_ctl_code OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive serial_number_control_code
		   -- @param1 -- p_serial_number_gen(IN)
		   -- @param2 -- p_serial_number_ctl_code(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_serial_number_ctl_code  NUMBER := NULL;
        BEGIN
         IF p_serial_number_gen IS NOT NULL THEN
            IF UPPER(trim(p_serial_number_gen)) = 'NO CONTROL' THEN
               x_serial_number_ctl_code := 1;
            ELSIF UPPER(trim(p_serial_number_gen)) = 'PREDEFINED' THEN
               x_serial_number_ctl_code := 2;
            ELSIF UPPER(trim(p_serial_number_gen)) = 'AT RECEIPT' THEN
               x_serial_number_ctl_code := 5;
            ELSIF UPPER(trim(p_serial_number_gen)) = 'AT SALES ORDER ISSUE' THEN
               x_serial_number_ctl_code := 6;
            ELSE
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_VALID
              ,p_error_text  => 'Invalid serial_number_generation'
              ,p_record_identifier_1 => p_item_org_attr_rec.record_number
              ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
              ,p_record_identifier_3 => p_item_org_attr_rec.item_number
              ,p_record_identifier_4 => 'ORG_ATTR'
              );
            END IF;
          END IF;
          p_serial_number_ctl_code := x_serial_number_ctl_code;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating serial_number_generation');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating serial_number_generation'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_serial_number_gen_valid;

       FUNCTION is_default_serial_status_valid(p_default_serial_status     IN  VARCHAR2,
                                               p_default_serial_status_id  OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive ddefault_serial_status_id
		   -- @param1 -- p_default_serial_status(IN)
       -- @param2 -- p_default_serial_status_id(OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_status_id  NUMBER := NULL;
       BEGIN
         IF p_default_serial_status IS NOT NULL THEN
              SELECT status_id INTO x_status_id
                 FROM  mtl_material_statuses_vl
                WHERE  serial_control = 1
                  AND  enabled_flag = 1
                  AND  UPPER(trim(status_code)) = UPPER(trim(p_default_serial_status));
           END IF;
                p_default_serial_status_id := x_status_id;
                RETURN  x_error_code;

         EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid default_serial_status');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid default_serial_status'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                   RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing default_serial_status');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing default_serial_status'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_default_serial_status_valid;

       FUNCTION is_ret_inspec_valid(p_ret_inspec IN VARCHAR2,p_ret_inspec_req OUT NUMBER)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive cust_ord_enable_flag
		   -- @param1 -- p_cust_order_enable_flag(IN OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
         IF p_ret_inspec IS NOT NULL THEN
            IF UPPER(trim(p_ret_inspec))  IN ('Y','1') THEN
               p_ret_inspec_req:= 1;
            ELSIF UPPER(trim(p_ret_inspec)) IN ('N','2')  THEN
               p_ret_inspec_req:= 2;
            ELSE
                  dbg_med('Invalid RETURN_INSPECTION_REQUIREMENT');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid RETURN_INSPECTION_REQUIREMENT'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                         );
             END IF;
          END IF;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating RETURN_INSPECTION_REQUIREMENT');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating RETURN_INSPECTION_REQUIREMENT'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_ret_inspec_valid;


       FUNCTION is_item_status_valid(p_item_status          IN VARCHAR2
                                    ,p_inv_item_status_code OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate item_status
		   --@param1 -- p_item_status(IN)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_inv_item_status_code  VARCHAR2(10) := NULL;
       BEGIN
         IF p_item_status IS NOT NULL THEN
              SELECT  inventory_item_status_code INTO x_inv_item_status_code
               from mtl_item_status
                where nvl(disable_date, sysdate+1) > sysdate
                 and  inventory_item_status_code <> 'Pending'
                 and  UPPER(trim(inventory_item_status_code)) = UPPER(trim(p_item_status));
          END iF;
             p_inv_item_status_code := x_inv_item_status_code;
             RETURN  x_error_code;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  dbg_med('Invalid item_status');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid item_status'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                         );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error in validating item_status');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating item_status'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                         );
                  RETURN  x_error_code;
       END is_item_status_valid;

       FUNCTION is_cust_order_flag_valid(p_cust_order_flag IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate anfd derive is_cust_order_flag_valid
		   -- @param1 -- p_cust_order_flag(IN OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
         IF p_cust_order_flag IS NOT NULL THEN
            IF UPPER(trim(p_cust_order_flag))    ='Y'  THEN
               p_cust_order_flag:= 'Y';
            ELSIF UPPER(trim(p_cust_order_flag)) ='N'  THEN
               p_cust_order_flag:= 'N';
            ELSE
                  dbg_med('Invalid customer_order_flag');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid customer_order_flag'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                         );
             END IF;
          END IF;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating customer_order_flag');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating customer_order_flag'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_cust_order_flag_valid;


       FUNCTION is_cust_ord_enable_flag_valid(p_cust_order_enable_flag IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive cust_ord_enable_flag
		   -- @param1 -- p_cust_order_enable_flag(IN OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
         IF p_cust_order_enable_flag IS NOT NULL THEN
            IF UPPER(trim(p_cust_order_enable_flag))    ='Y'  THEN
               p_cust_order_enable_flag:= 'Y';
            ELSIF UPPER(trim(p_cust_order_enable_flag)) ='N'  THEN
               p_cust_order_enable_flag:= 'N';
            ELSE
                  dbg_med('Invalid customer_order_enable_flag');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid customer_order_enable_flag'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                         );
             END IF;
          END IF;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating customer_order_enable_flag');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating customer_order_enable_flag'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_cust_ord_enable_flag_valid;

       FUNCTION is_pur_enabled_flag_valid(p_pur_enabled_flag IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive purchasing_enabled_flag
		   -- @param1 -- p_pur_enabled_flag(IN OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
         IF p_pur_enabled_flag IS NOT NULL THEN
            IF UPPER(trim(p_pur_enabled_flag))    ='Y'  THEN
               p_pur_enabled_flag:= 'Y';
            ELSIF UPPER(trim(p_pur_enabled_flag)) ='N'  THEN
               p_pur_enabled_flag:= 'N';
            ELSE
                  dbg_med('Invalid purchasing_enabled_flag');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid purchasing_enabled_flag'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                         );
             END IF;
          END IF;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating purchasing_enabled_flag');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating purchasing_enabled_flag'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_pur_enabled_flag_valid;

       FUNCTION is_pur_item_flag_valid(p_pur_item_flag IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive purchasing_item_flag
		   -- @param1 -- p_pur_item_flag(IN OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
         IF p_pur_item_flag IS NOT NULL THEN
            IF UPPER(trim(p_pur_item_flag))    ='Y'  THEN
               p_pur_item_flag:= 'Y';
            ELSIF UPPER(trim(p_pur_item_flag)) ='N'  THEN
               p_pur_item_flag:= 'N';
            ELSE
                  dbg_med('Invalid purchasing_item_flag');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid purchasing_item_flag'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                         );
             END IF;
          END IF;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating purchasing_item_flag');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating purchasing_item_flag'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_pur_item_flag_valid;

       FUNCTION is_build_in_wip_flag_valid(p_build_in_wip_flag IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive build_in_wip_flag
		   -- @param1 -- p_build_in_wip_flag(IN OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       BEGIN
         IF p_build_in_wip_flag IS NOT NULL THEN
            IF UPPER(trim(p_build_in_wip_flag))    ='Y'  THEN
               p_build_in_wip_flag:= 'Y';
            ELSIF UPPER(trim(p_build_in_wip_flag)) ='N'  THEN
               p_build_in_wip_flag:= 'N';
            ELSE
                  dbg_med('Invalid build_in_wip_flag');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid build_in_wip_flag'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                         );
             END IF;
          END IF;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating build_in_wip_flag');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating build_in_wip_flag'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_build_in_wip_flag_valid;

       -- is_wip_supply_type_valid

       FUNCTION is_wip_supply_type_valid(p_wip_supply_type IN VARCHAR2,p_wip_supply_type_orig IN OUT VARCHAR2)
           RETURN number
        IS
       ----------------------------------------------------------------
		   -- Created By       : Partha S Mohanty
       -- Description      : Function to validate and derive build_in_wip_flag
		   -- @param1 -- p_build_in_wip_flag(IN OUT)
		   ----------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_wip_supply_type NUMBER := NULL;
       BEGIN
         IF p_wip_supply_type IS NOT NULL THEN
            IF UPPER(trim(p_wip_supply_type))    ='PUSH'  THEN
               x_wip_supply_type:= 1;
            ELSIF UPPER(trim(p_wip_supply_type)) ='ASSEMBLY PULL'  THEN
               x_wip_supply_type:= 2;
            ELSIF UPPER(trim(p_wip_supply_type)) ='OPERATION PULL'  THEN
               x_wip_supply_type:= 3;
            ELSIF UPPER(trim(p_wip_supply_type)) ='BULK'  THEN
               x_wip_supply_type:= 4;
            ELSIF UPPER(trim(p_wip_supply_type)) ='SUPPLIER'  THEN
               x_wip_supply_type:= 5;
            ELSIF UPPER(trim(p_wip_supply_type)) ='PHANTOM'  THEN
               x_wip_supply_type:= 6;
            ELSE
                  dbg_med('Invalid wip_supply_type');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid wip_supply_type'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                         );
                  RETURN  x_error_code;
             END IF;
          END IF;
          p_wip_supply_type_orig := x_wip_supply_type;
          RETURN  x_error_code;
        EXCEPTION
         WHEN OTHERS THEN
                dbg_med('Unexpected error in validating wip_supply_type');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error in validating wip_supply_type'
                         ,p_record_identifier_1 => p_item_org_attr_rec.record_number
                         ,p_record_identifier_2 => p_item_org_attr_rec.organization_code
                         ,p_record_identifier_3 => p_item_org_attr_rec.item_number
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
                 RETURN  x_error_code;
       END is_wip_supply_type_valid;


       -- End wave1 validations

    BEGIN
       g_api_name := 'item_org_attr_validations';

       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Item Organization Attribute validations');
       x_error_code_temp := is_org_code_valid(p_item_org_attr_rec.organization_code,
                                              p_item_org_attr_rec.organization_id);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_item_number_valid(p_item_org_attr_rec.item_number,
                                              p_item_org_attr_rec.inventory_item_id);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_asset_category_valid(p_item_org_attr_rec.asset_category,
                                                  p_item_org_attr_rec.asset_category_id);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_calculate_atp_valid(p_item_org_attr_rec.calculate_atp,
                                                  p_item_org_attr_rec.mrp_calculate_atp_flag);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_container_type_valid(p_item_org_attr_rec.container_type,
                                                  p_item_org_attr_rec.container_type_code);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_create_fixed_asset_valid(p_item_org_attr_rec.create_fixed_asset,
                                                       p_item_org_attr_rec.asset_creation_code);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_demand_time_fence_valid(p_item_org_attr_rec.demand_time_fence,
                                                       p_item_org_attr_rec.demand_time_fence_code);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_equipment_valid(p_item_org_attr_rec.equipment,
                                                       p_item_org_attr_rec.equipment_type);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_exclude_from_budget_valid(p_item_org_attr_rec.exclude_from_budget,
                                                       p_item_org_attr_rec.exclude_from_budget_flag);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_input_tax_class_code_valid(p_item_org_attr_rec.input_tax_classification_code,
                                                       p_item_org_attr_rec.purchasing_tax_code);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);


       x_error_code_temp := is_inv_planning_method_valid(p_item_org_attr_rec.inventory_planning_method,
                                                       p_item_org_attr_rec.inventory_planning_code);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_list_price_valid(p_item_org_attr_rec.list_price,
                                                       p_item_org_attr_rec.list_price_per_unit);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_make_or_buy_valid(p_item_org_attr_rec.make_or_buy,
                                                       p_item_org_attr_rec.planning_make_buy_code);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_min_max_maximum_qty_valid(p_item_org_attr_rec.min_max_maximum_quantity,
                                                       p_item_org_attr_rec.max_minmax_quantity);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_min_max_minimum_qty_valid(p_item_org_attr_rec.min_max_minimum_quantity,
                                                       p_item_org_attr_rec.min_minmax_quantity);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_om_indivisible_valid(p_item_org_attr_rec.om_indivisible,
                                                       p_item_org_attr_rec.indivisible_flag);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_planned_inv_point_valid(p_item_org_attr_rec.planned_inventory_point,
                                                       p_item_org_attr_rec.planned_inv_point_flag);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_planner_valid(p_item_org_attr_rec.planner,
                                             p_item_org_attr_rec.planner_code);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_planning_time_fence_valid(p_item_org_attr_rec.planning_time_fence,
                                                         p_item_org_attr_rec.planning_time_fence_code);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_processing_lead_time_valid(p_item_org_attr_rec.processing_lead_time,
                                                          p_item_org_attr_rec.full_lead_time);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_release_time_fence_valid(p_item_org_attr_rec.release_time_fence,
                                                         p_item_org_attr_rec.release_time_fence_code);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_source_org_valid(p_item_org_attr_rec.source_organization,
                                                         p_item_org_attr_rec.source_organization_id);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_source_subinventory_valid(p_item_org_attr_rec.source_subinventory);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_source_type_valid(p_item_org_attr_rec.source_type,
                                                 p_item_org_attr_rec.source_type_code);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_substitution_window_valid(p_item_org_attr_rec.substitution_window,
                                                 p_item_org_attr_rec.substitution_window_code);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_taxable_valid(p_item_org_attr_rec.taxable,
                                                 p_item_org_attr_rec.taxable_flag);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_sales_account_valid(p_item_org_attr_rec.sales_account,
                                                 p_item_org_attr_rec.sales_account_ccid);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_expense_account_valid(p_item_org_attr_rec.expense_account,
                                                 p_item_org_attr_rec.expense_account_ccid);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_receipt_routing_valid(p_item_org_attr_rec.receipt_routing,
                                                 p_item_org_attr_rec.receiving_routing_id);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_outside_proc_item_valid(p_item_org_attr_rec.outside_processing_item,
                                                 p_item_org_attr_rec.outside_operation_flag);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

     --  x_error_code_temp := is_outside_opr_uom_type_valid(p_item_org_attr_rec.outside_operation_uom_type);

     --  x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

      x_error_code_temp := is_outsid_proc_unit_typ_valid(p_item_org_attr_rec.outside_processing_unit_type,
                                                         p_item_org_attr_rec.outside_operation_uom_type);

       x_error_code_temp := is_buyer_valid(p_item_org_attr_rec.buyer,
                                                 p_item_org_attr_rec.buyer_id);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       -- New Validations for wave1
       x_error_code_temp := is_atp_rule_valid(p_item_org_attr_rec.atp_rule,
                                            p_item_org_attr_rec.atp_rule_id);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_def_shipping_org_valid(p_item_org_attr_rec.default_shipping_org,
                                            p_item_org_attr_rec.default_shipping_org_orig);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_atp_components_valid(p_item_org_attr_rec.atp_components_flag,
                                            p_item_org_attr_rec.atp_components_flag_orig);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_lot_control_code_valid(p_item_org_attr_rec.lot_control_code
                                                    ,p_item_org_attr_rec.lot_control_code_orig); -- Also used in wave1

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_lot_expiration_valid(p_item_org_attr_rec.shelf_life_code
                                                    ,p_item_org_attr_rec.shelf_life_code_orig); -- Also used in wave1
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_reservable_valid(p_item_org_attr_rec.reservable_type
                                                    ,p_item_org_attr_rec.reservable_type_orig); -- Also used in wave1
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_default_lot_status_valid(p_item_org_attr_rec.default_lot_status
                                                    ,p_item_org_attr_rec.default_lot_status_id); -- Also used in wave1
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_item_status_valid(p_item_org_attr_rec.inventory_item_status_code
                                                 ,p_item_org_attr_rec.inv_item_status_code_orig);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_serial_number_gen_valid(p_item_org_attr_rec.serial_number_control_code,
                                                         p_item_org_attr_rec.serial_number_ctrl_code_orig); -- Also used in wave1

       x_error_code_temp := is_default_serial_status_valid(p_item_org_attr_rec.default_serial_status,
                                                           p_item_org_attr_rec.default_serial_status_id);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_ret_inspec_valid(p_item_org_attr_rec.return_inspection_requirement,
                                                p_item_org_attr_rec.return_inspect_req_orig);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_check_atp_valid(p_item_org_attr_rec.atp_flag,
                                               p_item_org_attr_rec.atp_flag_orig);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_cust_order_flag_valid(p_item_org_attr_rec.customer_order_flag);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_cust_ord_enable_flag_valid(p_item_org_attr_rec.customer_order_enabled_flag);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_pur_enabled_flag_valid(p_item_org_attr_rec.purchasing_enabled_flag);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_pur_item_flag_valid(p_item_org_attr_rec.purchasing_item_flag);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_build_in_wip_flag_valid(p_item_org_attr_rec.build_in_wip_flag);

       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_wip_supply_type_valid(p_item_org_attr_rec.wip_supply_type
                                                    ,p_item_org_attr_rec.wip_supply_type_orig);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       -- End New Validations for wave1

       xx_emf_pkg.propagate_error ( x_error_code_temp);

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
   END item_org_attr_validations;



  FUNCTION item_org_attr_derivations(p_item_org_attr_rec IN OUT xx_inv_item_attr_upd_pkg.G_XX_ITEM_ORG_STG_REC_TYPE
                          ) RETURN NUMBER
       IS
    --------------------------------------------------------------------------------------
    -- Created By                 : Partha S Mohanty
    -- Creation Date              : 25-APR-2012
    -- Description                : Derive corresponding value in Oracle

    -- Parameters description:

    -- @param1         :p_item_org_attr_rec(IN OUT)
   -----------------------------------------------------------------------------------------
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN

            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Derivation');

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
   END item_org_attr_derivations;

   -- update_hdr_record_count
  PROCEDURE print_detail_record_count(pr_validate_and_load IN VARCHAR2)
	IS
  --------------------------------------------------------------------------------------
    -- Created By                 : Partha S Mohanty
    -- Creation Date              : 10-APR-2012
    -- Description                : Print error and success record count in output file Body

    -- Parameters description:

    -- @param1         :pr_validate_and_load(IN)
   -----------------------------------------------------------------------------------------
		x_total_cnt_mast      NUMBER:=0;
    x_error_cnt_mast      NUMBER:= 0;
    x_warn_cnt_mast       NUMBER:=0;
    x_success_cnt_mast    NUMBER:=0;

    x_total_cnt_org       NUMBER:=0;
    x_error_cnt_org       NUMBER:= 0;
    x_warn_cnt_org        NUMBER:=0;
    x_success_cnt_org     NUMBER:=0;

    x_total_cnt_assgn     NUMBER:=0;
    x_error_cnt_assgn     NUMBER:= 0;
    x_warn_cnt_assgn      NUMBER:=0;
    x_success_cnt_assgn   NUMBER:=0;

    -- master
    CURSOR c_get_total_cnt_mast IS
		SELECT COUNT (1) total_count
		  FROM xx_item_mast_attr_upd_stg
		 WHERE batch_id = G_MAST_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID;

		CURSOR c_get_error_cnt_mast IS
			SELECT COUNT (1) error_count
			  FROM xx_item_mast_attr_upd_stg
			 WHERE batch_id   = G_MAST_BATCH_ID
			   AND request_id = xx_emf_pkg.G_REQUEST_ID
			   AND error_code = xx_emf_cn_pkg.CN_REC_ERR;

		CURSOR c_get_warning_cnt_mast IS
		SELECT COUNT (1) warn_count
		  FROM xx_item_mast_attr_upd_stg
		 WHERE batch_id = G_MAST_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

		CURSOR c_get_success_cnt_mast IS
		SELECT COUNT (1) success_count
		  FROM xx_item_mast_attr_upd_stg
		 WHERE batch_id = G_MAST_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
		   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

   -- Added for if p_validate_only_flag is set to VALIDATE_ONLY Starts
    CURSOR c_get_suc_valid_cnt_mast IS
    SELECT COUNT (1) success_count
		  FROM xx_item_mast_attr_upd_stg
		 WHERE batch_id = G_MAST_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND process_code = xx_emf_cn_pkg.CN_POSTVAL
		   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

   -- Added for if p_validate_only_flag is set to VALIDATE_ONLY Ends


    -- Org
    CURSOR c_get_total_cnt_org IS
		SELECT COUNT (1) total_count
		  FROM xx_item_org_attr_upd_stg
		 WHERE batch_id = G_ORG_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID;

		CURSOR c_get_error_cnt_org IS
			SELECT COUNT (1) error_count
			  FROM xx_item_org_attr_upd_stg
			 WHERE batch_id   = G_ORG_BATCH_ID
			   AND request_id = xx_emf_pkg.G_REQUEST_ID
			   AND error_code = xx_emf_cn_pkg.CN_REC_ERR;

		CURSOR c_get_warning_cnt_org IS
		SELECT COUNT (1) warn_count
		  FROM xx_item_org_attr_upd_stg
		 WHERE batch_id = G_ORG_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

		CURSOR c_get_success_cnt_org IS
		SELECT COUNT (1) success_count
		  FROM xx_item_org_attr_upd_stg
		 WHERE batch_id = G_ORG_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
		   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

     -- Added for if p_validate_only_flag is set to VALIDATE_ONLY Starts
    CURSOR c_get_suc_valid_cnt_org IS
    SELECT COUNT (1) success_count
		  FROM xx_item_org_attr_upd_stg
		 WHERE batch_id = G_ORG_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND process_code = xx_emf_cn_pkg.CN_POSTVAL
		   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

   -- Added for if p_validate_only_flag is set to VALIDATE_ONLY Ends

   -- Assign
    CURSOR c_get_total_cnt_assgn IS
		SELECT COUNT (1) total_count
		  FROM xx_item_org_assign_stg
		 WHERE batch_id = G_ASSGN_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID;

		CURSOR c_get_error_cnt_assgn IS
			SELECT COUNT (1) error_count
			  FROM xx_item_org_assign_stg
			 WHERE batch_id   = G_ASSGN_BATCH_ID
			   AND request_id = xx_emf_pkg.G_REQUEST_ID
			   AND error_code = xx_emf_cn_pkg.CN_REC_ERR;

		CURSOR c_get_warning_cnt_assgn IS
		SELECT COUNT (1) warn_count
		  FROM xx_item_org_assign_stg
		 WHERE batch_id = G_ASSGN_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

		CURSOR c_get_success_cnt_assgn IS
		SELECT COUNT (1) success_count
		  FROM xx_item_org_assign_stg
		 WHERE batch_id = G_ASSGN_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
		   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

    -- Added for if p_validate_only_flag is set to VALIDATE_ONLY Starts
    CURSOR c_get_suc_valid_cnt_assgn IS
    SELECT COUNT (1) success_count
		  FROM xx_item_org_assign_stg
		 WHERE batch_id = G_ASSGN_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND process_code = xx_emf_cn_pkg.CN_POSTVAL
		   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

   -- Added for if p_validate_only_flag is set to VALIDATE_ONLY Ends


	BEGIN

    x_total_cnt_mast      :=0;
    x_error_cnt_mast      :=0;
    x_warn_cnt_mast       :=0;
    x_success_cnt_mast    :=0;

    x_total_cnt_org       :=0;
    x_error_cnt_org       :=0;
    x_warn_cnt_org        :=0;
    x_success_cnt_org     :=0;

    x_total_cnt_assgn     :=0;
    x_error_cnt_assgn     :=0;
    x_warn_cnt_assgn      :=0;
    x_success_cnt_assgn   :=0;
    -- Master
		OPEN c_get_total_cnt_mast;
		FETCH c_get_total_cnt_mast INTO x_total_cnt_mast;
		CLOSE c_get_total_cnt_mast;

		OPEN c_get_error_cnt_mast;
		FETCH c_get_error_cnt_mast INTO x_error_cnt_mast;
		CLOSE c_get_error_cnt_mast;

		OPEN c_get_warning_cnt_mast;
		FETCH c_get_warning_cnt_mast INTO x_warn_cnt_mast;
		CLOSE c_get_warning_cnt_mast;

		IF pr_validate_and_load = g_validate_and_load THEN
       OPEN c_get_success_cnt_mast;
		   FETCH c_get_success_cnt_mast INTO x_success_cnt_mast;
		   CLOSE c_get_success_cnt_mast;
    ELSE
       OPEN c_get_suc_valid_cnt_mast;
		   FETCH c_get_suc_valid_cnt_mast INTO x_success_cnt_mast;
		   CLOSE c_get_suc_valid_cnt_mast;
		END IF;

	  -- Org
		OPEN c_get_total_cnt_org;
		FETCH c_get_total_cnt_org INTO x_total_cnt_org;
		CLOSE c_get_total_cnt_org;

		OPEN c_get_error_cnt_org;
		FETCH c_get_error_cnt_org INTO x_error_cnt_org;
		CLOSE c_get_error_cnt_org;

		OPEN c_get_warning_cnt_org;
		FETCH c_get_warning_cnt_org INTO x_warn_cnt_org;
		CLOSE c_get_warning_cnt_org;

		IF pr_validate_and_load = g_validate_and_load THEN
       OPEN c_get_success_cnt_org;
		   FETCH c_get_success_cnt_org INTO x_success_cnt_org;
		   CLOSE c_get_success_cnt_org;
    ELSE
       OPEN c_get_suc_valid_cnt_org;
		   FETCH c_get_suc_valid_cnt_org INTO x_success_cnt_org;
		   CLOSE c_get_suc_valid_cnt_org;
		END IF;

    -- Assign
		OPEN c_get_total_cnt_assgn;
		FETCH c_get_total_cnt_assgn INTO x_total_cnt_assgn;
		CLOSE c_get_total_cnt_assgn;

		OPEN c_get_error_cnt_assgn;
		FETCH c_get_error_cnt_assgn INTO x_error_cnt_assgn;
		CLOSE c_get_error_cnt_assgn;

		OPEN c_get_warning_cnt_assgn;
		FETCH c_get_warning_cnt_assgn INTO x_warn_cnt_assgn;
		CLOSE c_get_warning_cnt_assgn;

		IF pr_validate_and_load = g_validate_and_load THEN
       OPEN c_get_success_cnt_assgn;
		   FETCH c_get_success_cnt_assgn INTO x_success_cnt_assgn;
		   CLOSE c_get_success_cnt_assgn;
    ELSE
       OPEN c_get_suc_valid_cnt_assgn;
		   FETCH c_get_suc_valid_cnt_assgn INTO x_success_cnt_assgn;
		   CLOSE c_get_suc_valid_cnt_assgn;
		END IF;

    -- Print header
     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  ' '
                      ,p_error_text  => '----------*--------------*--------------*----------------*---------------*----------------*-------------*---------------*-------------------'
                      ,p_record_identifier_1 => ' '
                      );

      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  ' '
                      ,p_error_text  => 'Total Record count for this program is based on  Master Attribute records and  Organization Attribute records only.'
                      ,p_record_identifier_1 => ' '
                      );
     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  ' '
                      ,p_error_text  => 'Organization Assignment records are diplayed only for sake of good understanding.'
                      ,p_record_identifier_1 => ' '
                      );

      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  ' '
                      ,p_error_text  => '----------*--------------*--------------*----------------*---------------*----------------*-------------*---------------*-------------------'
                      ,p_record_identifier_1 => ' '
                      );
    -- print Master
    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  'REC_COUNT'
                      ,p_error_text  => 'Total Master Attribute Record :'||x_total_cnt_mast
                      ,p_record_identifier_1 => 'MAST_ATTR'
                      );
    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  'REC_COUNT'
                      ,p_error_text  => 'Total Master Attribute Error Record :'||x_error_cnt_mast
                      ,p_record_identifier_1 => 'MAST_ATTR'
                      );
    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  'REC_COUNT'
                      ,p_error_text  => 'Total Master Attribute Warning Record :'||x_warn_cnt_mast
                      ,p_record_identifier_1 => 'MAST_ATTR'
                      );
    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  'REC_COUNT'
                      ,p_error_text  => 'Total Master Attribute Success Record :'||x_success_cnt_mast
                      ,p_record_identifier_1 => 'MAST_ATTR'
                      );

    -- print Org
    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  'REC_COUNT'
                      ,p_error_text  => 'Total Organization Attribute Record :'||x_total_cnt_org
                      ,p_record_identifier_1 => 'ORG_ATTR'
                      );
    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  'REC_COUNT'
                      ,p_error_text  => 'Total Organization Attribute Error Record :'||x_error_cnt_org
                      ,p_record_identifier_1 => 'ORG_ATTR'
                      );
    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  'REC_COUNT'
                      ,p_error_text  => 'Total Organization Attribute Warning Record :'||x_warn_cnt_org
                      ,p_record_identifier_1 => 'ORG_ATTR'
                      );
    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  'REC_COUNT'
                      ,p_error_text  => 'Total Organization Attribute Success Record :'||x_success_cnt_org
                      ,p_record_identifier_1 => 'ORG_ATTR'
                      );

    -- print Assiginment
    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  'REC_COUNT'
                      ,p_error_text  => 'Total Organization Assignment Record :'||x_total_cnt_assgn
                      ,p_record_identifier_1 => 'ASSGN_ORG'
                      );
    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  'REC_COUNT'
                      ,p_error_text  => 'Total Organization Assignment Error Record :'||x_error_cnt_assgn
                      ,p_record_identifier_1 => 'ASSGN_ORG'
                      );
    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  'REC_COUNT'
                      ,p_error_text  => 'Total Organization Assignment Warning Record :'||x_warn_cnt_assgn
                      ,p_record_identifier_1 => 'ASSGN_ORG'
                      );
    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  'REC_COUNT'
                      ,p_error_text  => 'Total Organization Assignment Success Record :'||x_success_cnt_assgn
                      ,p_record_identifier_1 => 'ASSGN_ORG'
                      );
   EXCEPTION
    WHEN OTHERS THEN
	     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while printing record count: '||SQLERRM);

	END print_detail_record_count;


  PROCEDURE update_record_count(pr_validate_and_load IN VARCHAR2)
	IS
  --------------------------------------------------------------------------------------
    -- Created By                 : Partha S Mohanty
    -- Creation Date              : 10-APR-2012
    -- Description                : Print error and success record count in EMF output file

    -- Parameters description:

    -- @param1         :pr_validate_and_load(IN)
   -----------------------------------------------------------------------------------------
		CURSOR c_get_total_cnt IS
     SELECT SUM(total_count)
		  FROM (
     SELECT COUNT (1) total_count
		   FROM xx_item_mast_attr_upd_stg
		  WHERE batch_id = G_MAST_BATCH_ID
		    AND request_id = xx_emf_pkg.G_REQUEST_ID
      UNION ALL
         SELECT COUNT (1) total_count
			  FROM xx_item_org_attr_upd_stg
			 WHERE batch_id   = G_ORG_BATCH_ID
			   AND request_id = xx_emf_pkg.G_REQUEST_ID
       );

		x_total_cnt NUMBER;

		CURSOR c_get_error_cnt IS
		 SELECT SUM(error_count)
		  FROM (
			SELECT COUNT (1) error_count
			  FROM xx_item_mast_attr_upd_stg
			 WHERE batch_id   = G_MAST_BATCH_ID
			   AND request_id = xx_emf_pkg.G_REQUEST_ID
			   AND error_code = xx_emf_cn_pkg.CN_REC_ERR
       UNION ALL
         SELECT COUNT (1) error_count
			  FROM xx_item_org_attr_upd_stg
			 WHERE batch_id   = G_ORG_BATCH_ID
			   AND request_id = xx_emf_pkg.G_REQUEST_ID
			   AND error_code = xx_emf_cn_pkg.CN_REC_ERR
          );

		x_error_cnt NUMBER;

		CURSOR c_get_warning_cnt IS
     SELECT SUM(warn_count)
		  FROM (
		  SELECT COUNT (1) warn_count
		    FROM xx_item_mast_attr_upd_stg
		   WHERE batch_id = G_MAST_BATCH_ID
		    AND request_id = xx_emf_pkg.G_REQUEST_ID
		    AND error_code = xx_emf_cn_pkg.CN_REC_WARN
      UNION ALL
         SELECT COUNT (1) warn_count
			  FROM xx_item_org_attr_upd_stg
			 WHERE batch_id   = G_ORG_BATCH_ID
			   AND request_id = xx_emf_pkg.G_REQUEST_ID
			   AND error_code = xx_emf_cn_pkg.CN_REC_WARN
        );

		x_warn_cnt NUMBER;

		CURSOR c_get_success_cnt IS
    SELECT SUM(success_count)
		  FROM (
		SELECT COUNT (1) success_count
		  FROM xx_item_mast_attr_upd_stg
		 WHERE batch_id = G_MAST_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
		   AND error_code = xx_emf_cn_pkg.CN_SUCCESS
      UNION ALL
         SELECT COUNT (1) success_count
			  FROM xx_item_org_attr_upd_stg
			 WHERE batch_id   = G_ORG_BATCH_ID
			   AND request_id = xx_emf_pkg.G_REQUEST_ID
			   AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
		     AND error_code = xx_emf_cn_pkg.CN_SUCCESS
       );

		x_success_cnt NUMBER;

    -- Added for if p_validate_only_flag is set to VALIDATE_ONLY Starts
    CURSOR c_get_success_valid_cnt IS
    SELECT SUM(success_count)
		  FROM (
    SELECT COUNT (1) success_count
		  FROM xx_item_mast_attr_upd_stg
		 WHERE batch_id = G_MAST_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND process_code = xx_emf_cn_pkg.CN_POSTVAL
		   AND error_code = xx_emf_cn_pkg.CN_SUCCESS
      UNION ALL
         SELECT COUNT (1) success_count
			  FROM xx_item_org_attr_upd_stg
			 WHERE batch_id   = G_ORG_BATCH_ID
			   AND request_id = xx_emf_pkg.G_REQUEST_ID
			   AND process_code = xx_emf_cn_pkg.CN_POSTVAL
		     AND error_code = xx_emf_cn_pkg.CN_SUCCESS
       );
   -- Added for if p_validate_only_flag is set to VALIDATE_ONLY Ends

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

		IF pr_validate_and_load = g_validate_and_load THEN
       OPEN c_get_success_cnt;
		   FETCH c_get_success_cnt INTO x_success_cnt;
		   CLOSE c_get_success_cnt;
    ELSE
       OPEN c_get_success_valid_cnt;
		   FETCH c_get_success_valid_cnt INTO x_success_cnt;
		   CLOSE c_get_success_valid_cnt;
		END IF;

		xx_emf_pkg.update_recs_cnt
		(
		    p_total_recs_cnt   => x_total_cnt,
		    p_success_recs_cnt => x_success_cnt,
		    p_warning_recs_cnt => x_warn_cnt,
		    p_error_recs_cnt   => x_error_cnt
		);

   EXCEPTION
     WHEN OTHERS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in  update_record_counts: '||SQLERRM);
	END update_record_count;





   PROCEDURE main( errbuf   OUT VARCHAR2
                                ,retcode  OUT VARCHAR2
                                ,p_batch_id      IN  VARCHAR2
                                ,p_org_batch_id	IN VARCHAR2
                                ,p_restart_flag  IN  VARCHAR2
                                ,p_validate_and_load     IN VARCHAR2
                                ,p_mast_attr_update     IN VARCHAR2
                                ,p_item_assign          IN VARCHAR2
                                ,p_org_attr_update      IN VARCHAR2
                ) IS
   --------------------------------------------------------------------------------------
   -- Created By                 : Partha S Mohanty
   -- Creation Date              : 10-APR-2012
   -- Description                : This is The MAIN Procedure is used to call the required function and procedures
   --                              run the API for loading data into the final Oracle apps base tables

   -- Parameters description:

   -- p_batch_id                 : Master attribute batch id(IN)
   -- p_org_batch_id             : Organization Attribute update batch id(IN)
   -- p_restart_flag             : retart flag(IN)
   -- p_validate_and_load        : validate_and_load only(IN)
   -- errbuf                     : return error message(OUT)
   -- retcode                    : return error code(OUT)
   -----------------------------------------------------------------------------------------

      x_error_code          NUMBER                := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp     NUMBER                := xx_emf_cn_pkg.CN_SUCCESS;

      x_inv_item_mast_table           g_xx_item_mast_tab_type;
      x_inv_item_org_table            g_xx_item_org_tab_type;
      x_inv_item_assgn_table          g_xx_item_assgn_tab_type;
      -- Item Master Cursor
        CURSOR c_xx_inv_item_mast ( cp_process_status VARCHAR2)
        IS
         SELECT *
           FROM xx_item_mast_attr_upd_stg
         WHERE batch_id     = G_MAST_BATCH_ID
           AND request_id   = xx_emf_pkg.G_REQUEST_ID
           AND process_code = cp_process_status
           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         ORDER BY record_number;

     -- Item organization Cursor
     CURSOR c_xx_inv_item_org( cp_process_status VARCHAR2)  IS
         SELECT *
               FROM xx_item_org_attr_upd_stg
           WHERE batch_id     = G_ORG_BATCH_ID
           AND request_id   = xx_emf_pkg.G_REQUEST_ID
           AND process_code = cp_process_status
           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         ORDER BY record_number;

    -- Item Assign Cursor
     CURSOR c_xx_inv_item_assgn( cp_process_status VARCHAR2)  IS
         SELECT *
               FROM xx_item_org_assign_stg
           WHERE batch_id     = G_ASSGN_BATCH_ID
           AND request_id   = xx_emf_pkg.G_REQUEST_ID
           AND process_code = cp_process_status
           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         ORDER BY record_number;


     PROCEDURE update_mast_attr_rec_status (
    		p_mast_attr_rec  IN OUT  G_XX_ITEM_MAST_STG_REC_TYPE,
    		p_error_code            IN      VARCHAR2
    	       ) IS
       --------------------------------------------------------------------------------------
      -- Created By                 : Partha S Mohanty
      -- Creation Date              : 10-APR-2012
      -- Description                : Update error code for Master attribute table

      -- Parameters description:

      -- @param1         :p_mast_attr_rec(IN OUT)
      -- @param2         :p_error_code(IN)
       -----------------------------------------------------------------------------------------
           BEGIN
        g_api_name := 'main.update_mast_attr_rec_status';
    		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update record status...');

    		IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
    		THEN
    			p_mast_attr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
    		ELSE
    			p_mast_attr_rec.error_code := xx_intg_common_pkg.find_max(p_error_code, NVL (p_mast_attr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));

    		END IF;
    		p_mast_attr_rec.process_code := G_STAGE;

    	END update_mast_attr_rec_status;

   PROCEDURE update_assgn_attr_rec_status (
    		p_assgn_attr_rec  IN OUT  G_XX_ITEM_ASSGN_STG_REC_TYPE,
    		p_error_code            IN      VARCHAR2
    	       ) IS
      --------------------------------------------------------------------------------------
      -- Created By                 : Partha S Mohanty
      -- Creation Date              : 10-APR-2012
      -- Description                : Update error code for Oraganization Assignment

      -- Parameters description:

      -- @param1         :p_assgn_attr_rec(IN OUT)
      -- @param2         :p_error_code(IN)
       -----------------------------------------------------------------------------------------
           BEGIN
        g_api_name := 'main.update_assgn_attr_rec_status';
    		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update record status...');

    		IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
    		THEN
    			p_assgn_attr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
    		ELSE
    			p_assgn_attr_rec.error_code := xx_intg_common_pkg.find_max(p_error_code, NVL (p_assgn_attr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));

    		END IF;
    		p_assgn_attr_rec.process_code := G_STAGE;

    	END update_assgn_attr_rec_status;

   PROCEDURE update_org_attr_rec_status (
		p_org_attr_rec  IN OUT  G_XX_ITEM_ORG_STG_REC_TYPE,
		p_error_code             IN      VARCHAR2
	       ) IS
     --------------------------------------------------------------------------------------
      -- Created By                 : Partha S Mohanty
      -- Creation Date              : 10-APR-2012
      -- Description                : Update error code for Organization attribute table

      -- Parameters description:

      -- @param1         :p_org_attr_rec(IN OUT)
      -- @param2         :p_error_code(IN)
       -----------------------------------------------------------------------------------------
	 BEGIN
	       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update line record status...');
	       g_api_name := 'main.update_org_attr_rec_status';
	       IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
	       THEN
			      p_org_attr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
	       ELSE
			      p_org_attr_rec.error_code := xx_intg_common_pkg.find_max(p_error_code, NVL (p_org_attr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));
	       END IF;
	       p_org_attr_rec.process_code := G_STAGE;

	 END update_org_attr_rec_status;

  PROCEDURE update_item_mast_attr_records (p_item_mast_attr_table IN g_xx_item_mast_tab_type)
            IS
   --------------------------------------------------------------------------------------
   -- Created By                 : Partha S Mohanty
   -- Creation Date              : 10-APR-2012
   -- Description                : Update xx_item_mast_attr_upd_stg tale

   -- Parameters description:
   --@param1                -- p_item_mast_attr_table(IN)
   -----------------------------------------------------------------------------------------
            x_last_update_date      DATE := SYSDATE;
            x_last_updated_by       NUMBER := fnd_global.user_id;
            x_last_update_login     NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

            PRAGMA AUTONOMOUS_TRANSACTION;
       BEGIN
           g_api_name := 'main.update_item_mast_attr_records';
           fnd_file.put_line(fnd_file.log,'Inside update of master attribute records...');
            FOR indx IN 1 .. p_item_mast_attr_table.COUNT LOOP
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_item_mast_attr_table(indx).process_code ' || p_item_mast_attr_table(indx).process_code);
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_item_mast_attr_table(indx).error_code ' || p_item_mast_attr_table(indx).error_code);

               UPDATE xx_item_mast_attr_upd_stg
                  SET  item_number                                = p_item_mast_attr_table(indx).item_number,
                    atp_rule                                     	= p_item_mast_attr_table(indx).atp_rule,
                    check_atp                                    	= p_item_mast_attr_table(indx).check_atp,
                    collateral_item                              	= p_item_mast_attr_table(indx).collateral_item,
                    container                                    	= p_item_mast_attr_table(indx).container,
                    default_lot_status                           	= p_item_mast_attr_table(indx).default_lot_status,
                    default_serial_status                        	= p_item_mast_attr_table(indx).default_serial_status,
                    default_shipping_organization                	= p_item_mast_attr_table(indx).default_shipping_organization,
                    dimension_unit_of_measure                    	= p_item_mast_attr_table(indx).dimension_unit_of_measure,
                    hazard_class                                 	= p_item_mast_attr_table(indx).hazard_class,
                    height                                       	= p_item_mast_attr_table(indx).height,
                    item_instance_class                          	= p_item_mast_attr_table(indx).item_instance_class,
                    length                                       	= p_item_mast_attr_table(indx).length,
                    long_description                             	= p_item_mast_attr_table(indx).long_description,
                    lot_status_enabled                           	= p_item_mast_attr_table(indx).lot_status_enabled,
                    minimum_license_quantity                     	= p_item_mast_attr_table(indx).minimum_license_quantity,
                    orderable_on_the_web                         	= p_item_mast_attr_table(indx).orderable_on_the_web,
                    outside_processing_item                      	= p_item_mast_attr_table(indx).outside_processing_item,
                    outside_processing_unit_type                 	= p_item_mast_attr_table(indx).outside_processing_unit_type,
                    serial_status_enabled                        	= p_item_mast_attr_table(indx).serial_status_enabled,
                    track_in_installed_base                      	= p_item_mast_attr_table(indx).track_in_installed_base,
                    unit_volume                                  	= p_item_mast_attr_table(indx).unit_volume,
                    unit_weight                                  	= p_item_mast_attr_table(indx).unit_weight,
                    use_approved_supplier                        	= p_item_mast_attr_table(indx).use_approved_supplier,
                    vehicle                                      	= p_item_mast_attr_table(indx).vehicle,
                    volume_unit_of_measure                       	= p_item_mast_attr_table(indx).volume_unit_of_measure,
                    web_status                                   	= p_item_mast_attr_table(indx).web_status,
                    weight_unit_of_measure                       	= p_item_mast_attr_table(indx).weight_unit_of_measure,
                    unit_width                                   	= p_item_mast_attr_table(indx).unit_width,
                    global_attribute_category                    	= p_item_mast_attr_table(indx).global_attribute_category,
                    global_attribute1                            	= p_item_mast_attr_table(indx).global_attribute1,
                    global_attribute2                            	= p_item_mast_attr_table(indx).global_attribute2,
                    global_attribute3                            	= p_item_mast_attr_table(indx).global_attribute3,
                    global_attribute4                            	= p_item_mast_attr_table(indx).global_attribute4,
                    global_attribute5                            	= p_item_mast_attr_table(indx).global_attribute5,
                    global_attribute6                            	= p_item_mast_attr_table(indx).global_attribute6,
                    global_attribute7                            	= p_item_mast_attr_table(indx).global_attribute7,
                    global_attribute8                            	= p_item_mast_attr_table(indx).global_attribute8,
                    global_attribute9                            	= p_item_mast_attr_table(indx).global_attribute9,
                    global_attribute10                           	= p_item_mast_attr_table(indx).global_attribute10,
                    global_attribute11                           	= p_item_mast_attr_table(indx).global_attribute11,
                    global_attribute12                           	= p_item_mast_attr_table(indx).global_attribute12,
                    global_attribute13                           	= p_item_mast_attr_table(indx).global_attribute13,
                    global_attribute14                           	= p_item_mast_attr_table(indx).global_attribute14,
                    global_attribute15                           	= p_item_mast_attr_table(indx).global_attribute15,
                    global_attribute16                           	= p_item_mast_attr_table(indx).global_attribute16,
                    global_attribute17                           	= p_item_mast_attr_table(indx).global_attribute17,
                    global_attribute18                           	= p_item_mast_attr_table(indx).global_attribute18,
                    global_attribute19                           	= p_item_mast_attr_table(indx).global_attribute19,
                    global_attribute20                           	= p_item_mast_attr_table(indx).global_attribute20,
                    attribute_category                           	= p_item_mast_attr_table(indx).attribute_category,
                    attribute1                                   	= p_item_mast_attr_table(indx).attribute1,
                    attribute2                                   	= p_item_mast_attr_table(indx).attribute2,
                    attribute3                                   	= p_item_mast_attr_table(indx).attribute3,
                    attribute4                                   	= p_item_mast_attr_table(indx).attribute4,
                    attribute5                                   	= p_item_mast_attr_table(indx).attribute5,
                    attribute6                                   	= p_item_mast_attr_table(indx).attribute6,
                    attribute7                                   	= p_item_mast_attr_table(indx).attribute7,
                    attribute8                                   	= p_item_mast_attr_table(indx).attribute8,
                    attribute9                                   	= p_item_mast_attr_table(indx).attribute9,
                    attribute10                                  	= p_item_mast_attr_table(indx).attribute10,
                    attribute11                                  	= p_item_mast_attr_table(indx).attribute11,
                    attribute12                                  	= p_item_mast_attr_table(indx).attribute12,
                    attribute13                                  	= p_item_mast_attr_table(indx).attribute13,
                    attribute14                                  	= p_item_mast_attr_table(indx).attribute14,
                    attribute15                                  	= p_item_mast_attr_table(indx).attribute15,
                    attribute16                                  	= p_item_mast_attr_table(indx).attribute16,
                    attribute17                                  	= p_item_mast_attr_table(indx).attribute17,
                    attribute18                                  	= p_item_mast_attr_table(indx).attribute18,
                    attribute19                                  	= p_item_mast_attr_table(indx).attribute19,
                    attribute20                                  	= p_item_mast_attr_table(indx).attribute20,
                    attribute21                                  	= p_item_mast_attr_table(indx).attribute21,
                    attribute22                                  	= p_item_mast_attr_table(indx).attribute22,
                    attribute23                                  	= p_item_mast_attr_table(indx).attribute23,
                    attribute24                                  	= p_item_mast_attr_table(indx).attribute24,
                    attribute25                                  	= p_item_mast_attr_table(indx).attribute25,
                    attribute26                                  	= p_item_mast_attr_table(indx).attribute26,
                    attribute27                                  	= p_item_mast_attr_table(indx).attribute27,
                    attribute28                                  	= p_item_mast_attr_table(indx).attribute28,
                    attribute29                                  	= p_item_mast_attr_table(indx).attribute29,
                    attribute30                                  	= p_item_mast_attr_table(indx).attribute30,
                    lot_divisible                                	= p_item_mast_attr_table(indx).lot_divisible,
                    inventory_item_status_code                   	= p_item_mast_attr_table(indx).inventory_item_status_code,
                    lot_control                                  	= p_item_mast_attr_table(indx).lot_control,
                    lot_expiration                               	= p_item_mast_attr_table(indx).lot_expiration,
                    shelf_life_days                              	= p_item_mast_attr_table(indx).shelf_life_days,
                    serial_number_generation                     	= p_item_mast_attr_table(indx).serial_number_generation,
                    purchasing_enabled_flag                      	= p_item_mast_attr_table(indx).purchasing_enabled_flag,
                    replenish_to_order_flag                       = p_item_mast_attr_table(indx).replenish_to_order_flag,
                    build_in_wip_flag                            	= p_item_mast_attr_table(indx).build_in_wip_flag,
                    buyer                                        	= p_item_mast_attr_table(indx).buyer,
                    list_price                                   	= p_item_mast_attr_table(indx).list_price,
                    receipt_routing                              	= p_item_mast_attr_table(indx).receipt_routing,
                    item_type                                    	= p_item_mast_attr_table(indx).item_type,
                    postprocessing_lead_time                     	= p_item_mast_attr_table(indx).postprocessing_lead_time,
                    preprocessing_lead_time                      	= p_item_mast_attr_table(indx).preprocessing_lead_time,
                    full_lead_time                               	= p_item_mast_attr_table(indx).full_lead_time,
                    eng_item_flag                                	= UPPER(TRIM(p_item_mast_attr_table(indx).eng_item_flag)),
                    purchasing_item_flag                         	= p_item_mast_attr_table(indx).purchasing_item_flag,
                    customer_order_flag                          	= p_item_mast_attr_table(indx).customer_order_flag,
                    customer_order_enabled_flag                  	= UPPER(TRIM(p_item_mast_attr_table(indx).customer_order_enabled_flag)),
                    inventory_item_id                            	= p_item_mast_attr_table(indx).inventory_item_id,
                    atp_rule_id                                  	= p_item_mast_attr_table(indx).atp_rule_id,
                    default_lot_status_id                        	= p_item_mast_attr_table(indx).default_lot_status_id,
                    default_serial_status_id                     	= p_item_mast_attr_table(indx).default_serial_status_id,
                    dimension_uom_code                           	= p_item_mast_attr_table(indx).dimension_uom_code,
                    hazard_class_id                              	= p_item_mast_attr_table(indx).hazard_class_id,
                    ib_item_instance_class                       	= p_item_mast_attr_table(indx).ib_item_instance_class,
                    comms_nl_trackable_flag                      	= p_item_mast_attr_table(indx).comms_nl_trackable_flag,
                    must_use_approved_vendor_flag                	= p_item_mast_attr_table(indx).must_use_approved_vendor_flag,
                    outside_operation_flag                       	= p_item_mast_attr_table(indx).outside_operation_flag,
                    outside_operation_uom_type                   	= p_item_mast_attr_table(indx).outside_operation_uom_type,
                    collateral_flag                              	= p_item_mast_attr_table(indx).collateral_flag,
                    container_item_flag                          	= p_item_mast_attr_table(indx).container_item_flag,
                    atp_flag                                     	= p_item_mast_attr_table(indx).atp_flag,
                    vehicle_item_flag                            	= p_item_mast_attr_table(indx).vehicle_item_flag,
                    weight_uom_code                              	= p_item_mast_attr_table(indx).weight_uom_code,
                    default_shipping_org                         	= p_item_mast_attr_table(indx).default_shipping_org,
                    unit_height                                  	= p_item_mast_attr_table(indx).unit_height,
                    unit_length                                  	= p_item_mast_attr_table(indx).unit_length,
                    orderable_on_web_flag                        	= p_item_mast_attr_table(indx).orderable_on_web_flag,
                    lot_divisible_flag                           	= p_item_mast_attr_table(indx).lot_divisible_flag,
                    organization_code                            	= p_item_mast_attr_table(indx).organization_code,
                    inv_item_status_code_orig                   	= p_item_mast_attr_table(indx).inv_item_status_code_orig,
                    lot_control_code                             	= p_item_mast_attr_table(indx).lot_control_code,
                    shelf_life_code                              	= p_item_mast_attr_table(indx).shelf_life_code,
                    serial_number_control_code                   	= p_item_mast_attr_table(indx).serial_number_control_code,
                    buyer_id                                     	= p_item_mast_attr_table(indx).buyer_id,
                    list_price_per_unit                          	= p_item_mast_attr_table(indx).list_price_per_unit,
                    receiving_routing_id                         	= p_item_mast_attr_table(indx).receiving_routing_id,
                    item_type_orig                               	= p_item_mast_attr_table(indx).item_type_orig,
                    volume_uom_code                              	= p_item_mast_attr_table(indx).volume_uom_code,
                    organization_id                              	= p_item_mast_attr_table(indx).organization_id,
                    wip_supply_type                               = p_item_mast_attr_table(indx).wip_supply_type,
                    wip_supply_type_orig                          = p_item_mast_attr_table(indx).wip_supply_type_orig,
                    process_flag                                 	= p_item_mast_attr_table(indx).process_flag,
                    transaction_type                             	= p_item_mast_attr_table(indx).transaction_type,
                    set_process_id                               	= p_item_mast_attr_table(indx).set_process_id,
                    created_by											              = p_item_mast_attr_table(indx).created_by,
                    creation_date										              = x_last_update_date, --p_item_mast_attr_table(indx).creation_date,
                    last_updated_by									              = x_last_updated_by,  --p_item_mast_attr_table(indx).last_updated_by,
                    last_update_date								              = p_item_mast_attr_table(indx).last_update_date,
                    last_update_login								              = x_last_update_login,
                    request_id                                   	= p_item_mast_attr_table(indx).request_id,
                    process_code                                 	= p_item_mast_attr_table(indx).process_code,
                    error_code                                   	= p_item_mast_attr_table(indx).error_code,
                    error_mesg                                   	= p_item_mast_attr_table(indx).error_mesg,
                    source_system_name                           	= p_item_mast_attr_table(indx).source_system_name
                    --record_number                                	= p_item_mast_attr_table(indx).record_number,
                    --batch_id                                     	= p_item_mast_attr_table(indx).batch_id,
                WHERE record_number = p_item_mast_attr_table(indx).record_number
                           AND   BATCH_ID = G_MAST_BATCH_ID;

            END LOOP;

            COMMIT;
    EXCEPTION
     WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'ERROR in updating staging table xx_item_mast_attr_upd_stg...'||SQLERRM);

    END update_item_mast_attr_records;

   PROCEDURE update_item_assgn_attr_record (p_item_assgn_attr_table IN g_xx_item_assgn_tab_type)
            IS
   --------------------------------------------------------------------------------------
   -- Created By                 : Partha S Mohanty
   -- Creation Date              : 10-APR-2012
   -- Description                : Update xx_item_mast_attr_upd_stg table

   -- Parameters description:
   --@param1                -- p_item_assgn_attr_table(IN)
   -----------------------------------------------------------------------------------------
            x_last_update_date      DATE := SYSDATE;
            x_last_updated_by       NUMBER := fnd_global.user_id;
            x_last_update_login     NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

            PRAGMA AUTONOMOUS_TRANSACTION;
       BEGIN
           g_api_name := 'main.update_item_mast_attr_records';
           fnd_file.put_line(fnd_file.log,'Inside update of master attribute records...');
            FOR indx IN 1 .. p_item_assgn_attr_table.COUNT LOOP
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_item_assgn_attr_table(indx).process_code ' || p_item_assgn_attr_table(indx).process_code);
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_item_assgn_attr_table(indx).error_code ' || p_item_assgn_attr_table(indx).error_code);

                   UPDATE xx_item_org_assign_stg
                    SET item_number											= p_item_assgn_attr_table(indx).item_number,
                        organization_code               = p_item_assgn_attr_table(indx).organization_code,
                        attribute28											= p_item_assgn_attr_table(indx).attribute28, --p_item_assgn_attr_table(indx).batch_id, change on 11-OCT-2012
                        inventory_item_id               = p_item_assgn_attr_table(indx).inventory_item_id,
                        organization_id									= p_item_assgn_attr_table(indx).organization_id,
                        process_flag										= p_item_assgn_attr_table(indx).process_flag,
                        transaction_type								= p_item_assgn_attr_table(indx).transaction_type,
                        set_process_id									= p_item_assgn_attr_table(indx).set_process_id,
                        created_by											= p_item_assgn_attr_table(indx).created_by,
                        creation_date										= x_last_update_date, --p_item_assgn_attr_table(indx).creation_date,
                        last_updated_by									= x_last_updated_by,  --p_item_assgn_attr_table(indx).last_updated_by,
                        last_update_date								= p_item_assgn_attr_table(indx).last_update_date,
                        last_update_login								= x_last_update_login, --p_item_assgn_attr_table(indx).last_update_login,
                        process_code										= p_item_assgn_attr_table(indx).process_code,
                        error_code											= p_item_assgn_attr_table(indx).error_code,
                        error_mesg											= p_item_assgn_attr_table(indx).error_mesg
                      --  record_number										= p_item_assgn_attr_table(indx).record_number,
                      --  batch_id												= p_item_assgn_attr_table(indx).batch_id,
                    WHERE record_number = p_item_assgn_attr_table(indx).record_number
                           AND   BATCH_ID = G_ASSGN_BATCH_ID;
            END LOOP;

            COMMIT;
    EXCEPTION
     WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'ERROR in updating staging table xx_item_org_assign_stg...'||SQLERRM);

    END update_item_assgn_attr_record;

   PROCEDURE update_item_org_attr_records (p_item_org_attr_table IN g_xx_item_org_tab_type)
	  IS

   --------------------------------------------------------------------------------------
   -- Created By                 : Partha S Mohanty
   -- Creation Date              : 10-APR-2012
   -- Description                : Update xx_item_org_attr_upd_stg table

   -- Parameters description:
   --@param1                 -- p_item_org_attr_table(IN)
   -----------------------------------------------------------------------------------------
		x_last_update_date     DATE   := SYSDATE;
		x_last_updated_by      NUMBER := fnd_global.user_id;
		x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

	        PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
    g_api_name := 'main.update_item_org_attr_records';
    fnd_file.put_line(fnd_file.log,'Inside update of org attribute records...');
    FOR indx IN 1 .. p_item_org_attr_table.COUNT
    LOOP
   	 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_item_org_attr_table(indx).process_code ' || p_item_org_attr_table(indx).process_code);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_item_org_attr_table(indx).error_code ' || p_item_org_attr_table(indx).error_code);


      UPDATE xx_item_org_attr_upd_stg
			 SET item_number                                  	= p_item_org_attr_table(indx).item_number,
          organization_code                            	= p_item_org_attr_table(indx).organization_code,
          asset_category                               	= p_item_org_attr_table(indx).asset_category,
          calculate_atp                                	= p_item_org_attr_table(indx).calculate_atp,
          container_type                               	= p_item_org_attr_table(indx).container_type,
          create_fixed_asset                           	= p_item_org_attr_table(indx).create_fixed_asset,
          demand_time_fence                            	= p_item_org_attr_table(indx).demand_time_fence,
          demand_time_fence_days                       	= p_item_org_attr_table(indx).demand_time_fence_days,
          equipment                                    	= p_item_org_attr_table(indx).equipment,
          exclude_from_budget                          	= p_item_org_attr_table(indx).exclude_from_budget,
          expense_account                              	= p_item_org_attr_table(indx).expense_account,
          fixed_days_supply                            	= p_item_org_attr_table(indx).fixed_days_supply,
          fixed_lead_time                              	= p_item_org_attr_table(indx).fixed_lead_time,
          fixed_lot_multiplier                         	= p_item_org_attr_table(indx).fixed_lot_multiplier,
          fixed_order_quantity                         	= p_item_org_attr_table(indx).fixed_order_quantity,
          input_tax_classification_code                	= p_item_org_attr_table(indx).input_tax_classification_code,
          internal_volume                              	= p_item_org_attr_table(indx).internal_volume,
          inventory_planning_method                    	= p_item_org_attr_table(indx).inventory_planning_method,
          list_price                                   	= p_item_org_attr_table(indx).list_price,
          make_or_buy                                  	= p_item_org_attr_table(indx).make_or_buy,
          maximum_load_weight                          	= p_item_org_attr_table(indx).maximum_load_weight,
          maximum_order_quantity                       	= p_item_org_attr_table(indx).maximum_order_quantity,
          minimum_fill_percent                         	= p_item_org_attr_table(indx).minimum_fill_percent,
          minimum_order_quantity                       	= p_item_org_attr_table(indx).minimum_order_quantity,
          min_max_maximum_quantity                     	= p_item_org_attr_table(indx).min_max_maximum_quantity,
          min_max_minimum_quantity                     	= p_item_org_attr_table(indx).min_max_minimum_quantity,
          om_indivisible                               	= p_item_org_attr_table(indx).om_indivisible,
          planned_inventory_point                      	= p_item_org_attr_table(indx).planned_inventory_point,
          planner                                      	= p_item_org_attr_table(indx).planner,
          planning_time_fence                          	= p_item_org_attr_table(indx).planning_time_fence,
          planning_time_fence_days                     	= p_item_org_attr_table(indx).planning_time_fence_days,
          postprocessing_lead_time                     	= p_item_org_attr_table(indx).postprocessing_lead_time,
          preprocessing_lead_time                      	= p_item_org_attr_table(indx).preprocessing_lead_time,
          processing_lead_time                         	= p_item_org_attr_table(indx).processing_lead_time,
          release_time_fence                           	= p_item_org_attr_table(indx).release_time_fence,
          release_time_fence_days                      	= p_item_org_attr_table(indx).release_time_fence_days,
          sales_account                                	= p_item_org_attr_table(indx).sales_account,
          source_organization                          	= p_item_org_attr_table(indx).source_organization,
          source_subinventory                          	= p_item_org_attr_table(indx).source_subinventory,
          source_type                                  	= p_item_org_attr_table(indx).source_type,
          substitution_window                          	= p_item_org_attr_table(indx).substitution_window,
          substitution_windows_days                    	= p_item_org_attr_table(indx).substitution_windows_days,
          taxable                                      	= p_item_org_attr_table(indx).taxable,
          receipt_routing                              	= p_item_org_attr_table(indx).receipt_routing,
          outside_processing_item                      	= p_item_org_attr_table(indx).outside_processing_item,
          outside_processing_unit_type                 	= p_item_org_attr_table(indx).outside_processing_unit_type,
          buyer                                        	= p_item_org_attr_table(indx).buyer,
          attribute29                                  	= p_item_org_attr_table(indx).attribute29,
          customer_order_flag                          	= p_item_org_attr_table(indx).customer_order_flag,
          purchasing_item_flag                         	= p_item_org_attr_table(indx).purchasing_item_flag,
          build_in_wip_flag                            	= p_item_org_attr_table(indx).build_in_wip_flag,
          planning_exception_set                       	= trim(p_item_org_attr_table(indx).planning_exception_set),
          atp_flag                                     	= p_item_org_attr_table(indx).atp_flag,
          atp_rule                                     	= p_item_org_attr_table(indx).atp_rule,
          atp_components_flag                          	= p_item_org_attr_table(indx).atp_components_flag,
          ship_model_complete_flag                     	= UPPER(trim(p_item_org_attr_table(indx).ship_model_complete_flag)),
          pick_components_flag                         	= UPPER(trim(p_item_org_attr_table(indx).pick_components_flag)),
          default_shipping_org                         	= p_item_org_attr_table(indx).default_shipping_org,
          inventory_item_status_code                   	= p_item_org_attr_table(indx).inventory_item_status_code,
          inventory_item_flag                          	= UPPER(trim(p_item_org_attr_table(indx).inventory_item_flag)),
          stock_enabled_flag                           	= UPPER(trim(p_item_org_attr_table(indx).stock_enabled_flag)),
          mtl_transactions_enabled_flag                	= UPPER(trim(p_item_org_attr_table(indx).mtl_transactions_enabled_flag)),
          lot_control_code                             	= p_item_org_attr_table(indx).lot_control_code,
          auto_lot_alpha_prefix                        	= trim(p_item_org_attr_table(indx).auto_lot_alpha_prefix),
          start_auto_lot_number                        	= p_item_org_attr_table(indx).start_auto_lot_number,
          shelf_life_code                              	= p_item_org_attr_table(indx).shelf_life_code,
          shelf_life_days                              	= p_item_org_attr_table(indx).shelf_life_days,
          reservable_type                              	= p_item_org_attr_table(indx).reservable_type,
          lot_status_enabled                           	= UPPER(TRIM(p_item_org_attr_table(indx).lot_status_enabled)),
          default_lot_status                           	= p_item_org_attr_table(indx).default_lot_status,
          lot_divisible_flag                           	= UPPER(TRIM(p_item_org_attr_table(indx).lot_divisible_flag)),
          lot_split_enabled                            	= UPPER(TRIM(p_item_org_attr_table(indx).lot_split_enabled)),
          lot_merge_enabled                            	= UPPER(TRIM(p_item_org_attr_table(indx).lot_merge_enabled)),
          LOT_TRANSLATE_ENABLED                         = UPPER(TRIM(p_item_org_attr_table(indx).LOT_TRANSLATE_ENABLED)),   --Added on 31-Mar-2015 for FS V4.0
          LOT_SUBSTITUTION_ENABLED                      = UPPER(TRIM(p_item_org_attr_table(indx).LOT_SUBSTITUTION_ENABLED)), --Added on 31-Mar-2015 for FS V4.0
          serial_number_control_code                   	= p_item_org_attr_table(indx).serial_number_control_code,
          auto_serial_alpha_prefix                     	= trim(p_item_org_attr_table(indx).auto_serial_alpha_prefix),
          start_auto_serial_number                     	= p_item_org_attr_table(indx).start_auto_serial_number,
          serial_status_enabled                        	= UPPER(TRIM(p_item_org_attr_table(indx).serial_status_enabled)),
          default_serial_status                        	= p_item_org_attr_table(indx).default_serial_status,
          default_so_source_type                       	= UPPER(TRIM(p_item_org_attr_table(indx).default_so_source_type)),
          returnable_flag                              	= UPPER(TRIM(p_item_org_attr_table(indx).returnable_flag)),
          return_inspection_requirement                	= p_item_org_attr_table(indx).return_inspection_requirement,
          bulk_picked_flag                             	= UPPER(TRIM(p_item_org_attr_table(indx).bulk_picked_flag)),
          bom_enabled_flag                             	= UPPER(TRIM(p_item_org_attr_table(indx).bom_enabled_flag)),
          purchasing_enabled_flag                      	= UPPER(TRIM(p_item_org_attr_table(indx).purchasing_enabled_flag)),
          customer_order_enabled_flag                  	= UPPER(TRIM(p_item_org_attr_table(indx).customer_order_enabled_flag)),
          replenish_to_order_flag                      	= UPPER(TRIM(p_item_org_attr_table(indx).replenish_to_order_flag)),
          inventory_item_id                            	= p_item_org_attr_table(indx).inventory_item_id,
          asset_category_id                            	= p_item_org_attr_table(indx).asset_category_id,
          mrp_calculate_atp_flag                       	= p_item_org_attr_table(indx).mrp_calculate_atp_flag,
          container_type_code                          	= p_item_org_attr_table(indx).container_type_code,
          asset_creation_code                          	= p_item_org_attr_table(indx).asset_creation_code,
          demand_time_fence_code                       	= p_item_org_attr_table(indx).demand_time_fence_code,
          equipment_type                               	= p_item_org_attr_table(indx).equipment_type,
          exclude_from_budget_flag                     	= p_item_org_attr_table(indx).exclude_from_budget_flag,
          expense_account_ccid                         	= p_item_org_attr_table(indx).expense_account_ccid,
          purchasing_tax_code                          	= p_item_org_attr_table(indx).purchasing_tax_code,
          inventory_planning_code                      	= p_item_org_attr_table(indx).inventory_planning_code,
          planning_make_buy_code                       	= p_item_org_attr_table(indx).planning_make_buy_code,
          indivisible_flag                             	= p_item_org_attr_table(indx).indivisible_flag,
          planned_inv_point_flag                       	= p_item_org_attr_table(indx).planned_inv_point_flag,
          planner_code                                 	= p_item_org_attr_table(indx).planner_code,
          planning_time_fence_code                     	= p_item_org_attr_table(indx).planning_time_fence_code,
          full_lead_time                               	= p_item_org_attr_table(indx).full_lead_time,
          release_time_fence_code                      	= p_item_org_attr_table(indx).release_time_fence_code,
          sales_account_ccid                           	= p_item_org_attr_table(indx).sales_account_ccid,
          source_organization_id                       	= p_item_org_attr_table(indx).source_organization_id,
          source_type_code                             	= p_item_org_attr_table(indx).source_type_code,
          max_minmax_quantity                          	= p_item_org_attr_table(indx).max_minmax_quantity,
          min_minmax_quantity                          	= p_item_org_attr_table(indx).min_minmax_quantity,
          list_price_per_unit                          	= p_item_org_attr_table(indx).list_price_per_unit,
          taxable_flag                                 	= p_item_org_attr_table(indx).taxable_flag,
          receiving_routing_id                         	= p_item_org_attr_table(indx).receiving_routing_id,
          outside_operation_flag                       	= p_item_org_attr_table(indx).outside_operation_flag,
          outside_operation_uom_type                   	= p_item_org_attr_table(indx).outside_operation_uom_type,
          buyer_id                                     	= p_item_org_attr_table(indx).buyer_id,
          shelf_life_code_orig                         	= p_item_org_attr_table(indx).shelf_life_code_orig,
          atp_flag_orig                                	= p_item_org_attr_table(indx).atp_flag_orig,
          atp_rule_id                                  	= p_item_org_attr_table(indx).atp_rule_id,
          atp_components_flag_orig                     	= p_item_org_attr_table(indx).atp_components_flag_orig,
          default_shipping_org_orig                    	= p_item_org_attr_table(indx).default_shipping_org_orig,
          inv_item_status_code_orig                    	= p_item_org_attr_table(indx).inv_item_status_code_orig,
          lot_control_code_orig                        	= p_item_org_attr_table(indx).lot_control_code_orig,
          reservable_type_orig                         	= p_item_org_attr_table(indx).reservable_type_orig,
          default_lot_status_id                        	= p_item_org_attr_table(indx).default_lot_status_id,
          serial_number_ctrl_code_orig                 	= p_item_org_attr_table(indx).serial_number_ctrl_code_orig,
          default_serial_status_id                     	= p_item_org_attr_table(indx).default_serial_status_id,
          return_inspect_req_orig                      	= p_item_org_attr_table(indx).return_inspect_req_orig,
          substitution_window_code                     	= p_item_org_attr_table(indx).substitution_window_code,
          wip_supply_type                               = p_item_org_attr_table(indx).wip_supply_type,
          wip_supply_type_orig                          = p_item_org_attr_table(indx).wip_supply_type_orig,
          organization_id                              	= p_item_org_attr_table(indx).organization_id,
          process_flag                                 	= p_item_org_attr_table(indx).process_flag,
          transaction_type                             	= p_item_org_attr_table(indx).transaction_type,
          set_process_id                               	= p_item_org_attr_table(indx).set_process_id,
          created_by                                   	= p_item_org_attr_table(indx).created_by,
          creation_date                                	= p_item_org_attr_table(indx).creation_date,
          last_updated_by										            = x_last_updated_by,   -- p_item_org_attr_table(indx).last_updated_by,
          last_update_date									            = x_last_update_date,  -- p_item_org_attr_table(indx).last_update_date,
          last_update_login									            = x_last_update_login, -- p_item_org_attr_table(indx).last_update_login,
          request_id                                   	= p_item_org_attr_table(indx).request_id,
          process_code                                 	= p_item_org_attr_table(indx).process_code,
          error_code                                   	= p_item_org_attr_table(indx).error_code,
          error_mesg                                   	= p_item_org_attr_table(indx).error_mesg,
          source_system_name                           	= p_item_org_attr_table(indx).source_system_name
          --record_number                                	= p_item_org_attr_table(indx).record_number,
          --batch_id                                     	= p_item_org_attr_table(indx).batch_id,
        WHERE record_number		                          =	p_item_org_attr_table(indx).record_number
		      AND BATCH_ID = G_ORG_BATCH_ID;
		END LOOP;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'ERROR in updating staging table xx_item_org_attr_upd_stg...'||SQLERRM);

	END update_item_org_attr_records;

    -- mark_records_complete
    PROCEDURE mark_records_complete (
		        p_process_code	VARCHAR2,
	          p_level		VARCHAR2
	           ) IS
    --------------------------------------------------------------------------------------
    -- Created By                 : Partha S Mohanty
    -- Creation Date              : 10-APR-2012
    -- Description                : Marks all processed record as complete and update status

    -- Parameters description:

    -- @param1         :p_process_code(IN)
    -- @param2         :p_level(IN)
   -----------------------------------------------------------------------------------------
		x_last_update_date       DATE   := SYSDATE;
		x_last_updated_by        NUMBER := fnd_global.user_id;
		x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

		PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of mark records complete...');
    g_api_name := 'main.mark_records_complete';
		IF p_level = 'ITEM_MAST' THEN

		   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside mark_records_complete :: p_level: '||p_level);

			UPDATE xx_item_mast_attr_upd_stg
			   SET process_code      = G_STAGE,
			       error_code        = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
			       last_updated_by   = x_last_updated_by,
			       last_update_date  = x_last_update_date,
			       last_update_login = x_last_update_login
			 WHERE batch_id     = G_MAST_BATCH_ID
			   AND request_id   = xx_emf_pkg.G_REQUEST_ID
			   AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
			   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

		ELSIF p_level = 'ITEM_ORG' THEN

		    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside mark_records_complete :: p_level: '||p_level);

			UPDATE xx_item_org_attr_upd_stg
			   SET process_code      = G_STAGE,
			       error_code        = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
			       last_updated_by   = x_last_updated_by,
			       last_update_date  = x_last_update_date,
			       last_update_login = x_last_update_login
			 WHERE batch_id     = G_ORG_BATCH_ID
			   AND request_id   = xx_emf_pkg.G_REQUEST_ID
			   AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
			   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

		ELSIF p_level = 'ITEM_ASSGN' THEN

		    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside mark_records_complete :: p_level: '||p_level);

			UPDATE xx_item_org_assign_stg
			   SET process_code      = G_STAGE,
			       error_code        = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
			       last_updated_by   = x_last_updated_by,
			       last_update_date  = x_last_update_date,
			       last_update_login = x_last_update_login
			 WHERE batch_id     = G_ASSGN_BATCH_ID
			   AND request_id   = xx_emf_pkg.G_REQUEST_ID
			   AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
			   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);
		END IF;


		COMMIT;

	EXCEPTION
		WHEN OTHERS THEN
	            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in Update of mark_records_complete '||SQLERRM);
	END mark_records_complete;

  -- mark_records_for_api_error
  PROCEDURE mark_records_for_api_error(p_process_code IN VARCHAR2,p_level VARCHAR2)
	IS
		--------------------------------------------------------------------------------------
   -- Created By                 : Partha S Mohanty
   -- Creation Date              : 10-APR-2012
   -- Description                : Used for marking staging table records with error for interface error records

   -- Parameters description:

   -- p_process_code             : process_code(IN)
   -- p_level                    : Master attribute or Organization attribute(IN)
   -----------------------------------------------------------------------------------------

      x_last_update_date       DATE := SYSDATE;
			x_last_updated_by        NUMBER := fnd_global.user_id;
			x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
      x_record_count           NUMBER := 0;
			PRAGMA AUTONOMOUS_TRANSACTION;
		BEGIN
		   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside Mark Record for API Error');

      IF  p_level = 'ITEM_MAST' THEN
		   UPDATE xx_item_mast_attr_upd_stg xima
		     SET process_code = G_STAGE,
		         error_code   = xx_emf_cn_pkg.CN_REC_ERR,
             error_mesg   ='INTERFACE Error : Errored out inside MTL_SYSTEM_ITEMS_INTERFACE',
		         last_updated_by   = x_last_updated_by,
		         last_update_date  = x_last_update_date,
		         last_update_login = x_last_update_login
		   WHERE batch_id    = G_MAST_BATCH_ID
		     AND process_code  = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
		                                , xx_emf_cn_pkg.CN_POSTVAL
		                                , xx_emf_cn_pkg.CN_DERIVE
		                                )
		     AND error_code    IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
		     AND Exists (SELECT 1
		                   FROM mtl_system_items_interface msi
		                   WHERE 1=1
		                    -- AND msi.item_number       = xima.item_number
                        AND msi.organization_id   = xima.organization_id
                        AND msi.inventory_item_id = xima.inventory_item_id
                        -- AND msi.ATTRIBUTE30 = xima.batch_id  -- change on 11-OCT-2012
                        AND msi.request_id = g_req_id_mast      -- change on 11-OCT-2012
                        AND xima.batch_id = G_MAST_BATCH_ID
		                    AND msi.process_flag <> 7
		                 );

		   x_record_count := SQL%ROWCOUNT;
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No of Master Attribute Record Marked with API Error=>'||x_record_count);
		   COMMIT;
      END IF;
       -- update component records
       x_record_count := 0;

       IF  p_level = 'ITEM_ORG' THEN

        UPDATE xx_item_org_attr_upd_stg xioa
		     SET process_code = G_STAGE,
		         error_code   = xx_emf_cn_pkg.CN_REC_ERR,
             error_mesg   ='INTERFACE Error : Errored out inside MTL_SYSTEM_ITEMS_INTERFACE',
		         last_updated_by   = x_last_updated_by,
		         last_update_date  = x_last_update_date,
		         last_update_login = x_last_update_login
		     WHERE batch_id    = G_ORG_BATCH_ID
		       AND process_code  = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
		                                , xx_emf_cn_pkg.CN_POSTVAL
		                                , xx_emf_cn_pkg.CN_DERIVE
		                                )
		       AND error_code    IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
		       AND Exists (SELECT 1
		                   FROM mtl_system_items_interface msi
		                   WHERE 1=1
		                   -- AND msi.item_number       = xioa.item_number
                        AND msi.organization_id   = xioa.organization_id
                        AND msi.inventory_item_id = xioa.inventory_item_id
                       -- AND msi.ATTRIBUTE29 = xioa.batch_id      -- change on 11-OCT-2012
                        AND msi.request_id = g_req_id_org          -- change on 11-OCT-2012
                        AND xioa.batch_id = G_ORG_BATCH_ID
		                    AND msi.process_flag <> 7
		                 );

		   x_record_count := SQL%ROWCOUNT;
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No of Oganization Attribute Record Marked with API Error=>'||x_record_count);
       COMMIT;
     END IF;


     -- Organization Assignment records
       x_record_count := 0;

       IF  p_level = 'ITEM_ASSGN' THEN

        UPDATE xx_item_org_assign_stg xioa
		     SET process_code = G_STAGE,
		         error_code   = xx_emf_cn_pkg.CN_REC_ERR,
             error_mesg   ='INTERFACE Error : Errored out inside MTL_SYSTEM_ITEMS_INTERFACE',
		         last_updated_by   = x_last_updated_by,
		         last_update_date  = x_last_update_date,
		         last_update_login = x_last_update_login
		     WHERE batch_id    = G_ASSGN_BATCH_ID
		       AND process_code  = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
		                                , xx_emf_cn_pkg.CN_POSTVAL
		                                , xx_emf_cn_pkg.CN_DERIVE
		                                )
		       AND error_code    IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
		       AND Exists (SELECT 1
		                   FROM mtl_system_items_interface msi
		                   WHERE 1=1
		                    --AND msi.item_number       = xioa.item_number
                        AND msi.organization_id   = xioa.organization_id
                        AND msi.inventory_item_id = xioa.inventory_item_id
                       -- AND msi.ATTRIBUTE28 = xioa.batch_id  -- change on 11-OCT-2012
                        AND msi.request_id = g_req_id_assign   -- change on 11-OCT-2012
                        AND xioa.batch_id = G_ASSGN_BATCH_ID
		                    AND msi.process_flag <> 7
		                 );

		   x_record_count := SQL%ROWCOUNT;
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No of Oganization Assignment Record Marked with API Error=>'||x_record_count);
       COMMIT;
     END IF;

    EXCEPTION
     WHEN OTHERS THEN
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in Updating Staging tables with Error from Interface table');
		END mark_records_for_api_error;


   --print_records_with_api_error
    PROCEDURE print_records_with_api_error(p_level VARCHAR2)
  		IS
    --------------------------------------------------------------------------------------
   -- Created By                 : Partha S Mohanty
   -- Creation Date              : 10-APR-2012
   -- Description                : Print the error message for erronious records in interface

   -- Parameters description:
   -----------------------------------------------------------------------------------------
     CURSOR cur_print_error_mast_records
     IS
     SELECT  mti.segment1 item_segment1
            ,mp.organization_code
            ,trim(translate(mie.message_name||':'||mie.error_message,CHR(13)||CHR(10)||CHR(9),'   ')) error_message
            ,mie.column_name
            ,xima.record_number
      FROM mtl_system_items_interface mti
          ,mtl_interface_errors mie
          ,mtl_parameters mp
          ,xx_item_mast_attr_upd_stg xima
      WHERE mti.set_process_id    = g_set_process_id
        AND mti.transaction_id    = mie.transaction_id
        AND mti.request_id        = mie.request_id
        AND mti.organization_id   = mie.organization_id
        AND mti.organization_id   = mp.organization_id
        AND xima.organization_id = mti.organization_id
        AND xima.inventory_item_id = mti.inventory_item_id
       -- AND mti.ATTRIBUTE30 = xima.batch_id  -- change on 11-OCT-2012
        AND mti.request_id = g_req_id_mast      -- change on 11-OCT-2012
        AND xima.batch_id = G_MAST_BATCH_ID
        AND mie.error_message     IS NOT NULL;

     CURSOR cur_print_error_org_records
     IS
     SELECT  mti.segment1 item_segment1
            ,mp.organization_code
            ,trim(translate(mie.message_name||':'||mie.error_message,CHR(13)||CHR(10)||CHR(9),'   ')) error_message
            ,mie.column_name
            ,xioa.record_number
      FROM mtl_system_items_interface mti
          ,mtl_interface_errors mie
          ,mtl_parameters mp
          ,xx_item_org_attr_upd_stg xioa
      WHERE mti.set_process_id    = g_set_process_id_org
        AND mti.transaction_id    = mie.transaction_id
        AND mti.request_id        = mie.request_id
        AND mti.organization_id   = mie.organization_id
        AND mti.organization_id   = mp.organization_id
        AND xioa.organization_id = mti.organization_id
        AND xioa.inventory_item_id = mti.inventory_item_id
       -- AND mti.ATTRIBUTE29 = xioa.batch_id   -- change on 11-OCT-2012
        AND mti.request_id = g_req_id_org  -- change on 11-OCT-2012
        AND xioa.batch_id = G_ORG_BATCH_ID
        AND mie.error_message     IS NOT NULL;

    CURSOR cur_print_error_assgn_records
     IS
     SELECT  mti.segment1 item_segment1
            ,mp.organization_code
            ,trim(translate(mie.message_name||':'||mie.error_message,CHR(13)||CHR(10)||CHR(9),'   ')) error_message
            ,mie.column_name
            ,xioa.record_number
      FROM mtl_system_items_interface mti
          ,mtl_interface_errors mie
          ,mtl_parameters mp
          ,xx_item_org_assign_stg xioa
      WHERE mti.set_process_id    = g_set_process_id_assgn
        AND mti.transaction_id    = mie.transaction_id
        AND mti.request_id        = mie.request_id
        AND mti.organization_id   = mie.organization_id
        AND mti.organization_id   = mp.organization_id
        AND xioa.organization_id = mti.organization_id
        AND xioa.inventory_item_id = mti.inventory_item_id
        --AND mti.ATTRIBUTE28 = xioa.batch_id  -- change on 11-OCT-2012
        AND mti.request_id = g_req_id_assign   -- change on 11-OCT-2012
        AND xioa.batch_id = G_ASSGN_BATCH_ID
        AND mie.error_message     IS NOT NULL;


      BEGIN
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside print_records_with_api_error');

      IF  p_level = 'ITEM_MAST' THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside print_records_with_api_error for Master Organization');
        FOR cur_rec IN cur_print_error_mast_records
        LOOP
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~ERROR_CODE:'||cur_rec.column_name);
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~ERROR_MESSAGE:'||cur_rec.error_message);
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                         ,p_category    => xx_emf_cn_pkg.CN_STG_APICALL
                         ,p_error_text  => cur_rec.error_message
                         ,p_record_identifier_1 => cur_rec.record_number
                         ,p_record_identifier_2 => cur_rec.organization_code
                         ,p_record_identifier_3 => cur_rec.item_segment1
                         ,p_record_identifier_4 => 'MAST_ATTR'
                        );
         END LOOP;
      END IF;

      IF  p_level = 'ITEM_ORG' THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside print_records_with_api_error for Organization');
        FOR cur_rec IN cur_print_error_org_records
        LOOP
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~ERROR_CODE:'||cur_rec.column_name);
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~ERROR_MESSAGE:'||cur_rec.error_message);
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                         ,p_category    => xx_emf_cn_pkg.CN_STG_APICALL
                         ,p_error_text  => cur_rec.error_message
                         ,p_record_identifier_1 => cur_rec.record_number
                         ,p_record_identifier_2 => cur_rec.organization_code
                         ,p_record_identifier_3 => cur_rec.item_segment1
                         ,p_record_identifier_4 => 'ORG_ATTR'
                        );
         END LOOP;
      END IF;

      IF  p_level = 'ITEM_ASSGN' THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside print_records_with_api_error for Organization Assignment');
        FOR cur_rec IN cur_print_error_assgn_records
        LOOP
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~ERROR_CODE:'||cur_rec.column_name);
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~ERROR_MESSAGE:'||cur_rec.error_message);
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                         ,p_category    => xx_emf_cn_pkg.CN_STG_APICALL
                         ,p_error_text  => cur_rec.error_message
                         ,p_record_identifier_1 => cur_rec.record_number
                         ,p_record_identifier_2 => cur_rec.organization_code
                         ,p_record_identifier_3 => cur_rec.item_segment1
                         ,p_record_identifier_4 => 'ASSGN_ORG'
                        );
         END LOOP;
      END IF;
   EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in print_records_with_api_error'||SQLERRM);
  	END print_records_with_api_error;

  FUNCTION process_master_attibute
    RETURN NUMBER
	 IS
   --------------------------------------------------------------------------------------
   -- Created By                 : Partha S Mohanty
   -- Creation Date              : 10-APR-2012
   -- Description                : This function is used to insert records in mtl_system_items_interface table
   --                              run the Item Open Interface in Update Mode

   -- Parameters description:

   -- return NUMBER
   -----------------------------------------------------------------------------------------
		x_return_status       VARCHAR2(15)  := xx_emf_cn_pkg.CN_SUCCESS;
    x_last_update_login   NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
    x_commit_mast         NUMBER :=0;
    x_commit_sequence     NUMBER := 10000;
    x_req_return_status   BOOLEAN;
    x_req_id              NUMBER;
    x_dev_phase           VARCHAR2(20);
    x_phase               VARCHAR2(20);
    x_dev_status          VARCHAR2(20);
    x_status              VARCHAR2(20);
    x_message             VARCHAR2(100);
    x_organization_id     NUMBER;
    x_org_err_code        VARCHAR2(30);
    x_org_err_msg         VARCHAR2(200);
    l_cnt                 NUMBER;

      CURSOR c_get_organization
      IS
      SELECT distinct organization_id
        FROM mtl_system_items_interface
       WHERE set_process_id = g_set_process_id
       ORDER by organization_id ;

      --cursor to insert into ITEM interface table
      CURSOR c_xx_item_mast_attr_upld(cp_process_status VARCHAR2) IS
         SELECT *
           FROM xx_item_mast_attr_upd_stg
           WHERE batch_id     = G_MAST_BATCH_ID
		         AND request_id   = xx_emf_pkg.G_REQUEST_ID
		         AND process_code = cp_process_status
		         AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
		        ORDER BY record_number;
   BEGIN
      g_api_name := 'main.process_master_attibute';
      dbg_med('Inside process_master_attibute');

      --Get the set_process_id to group the extension runs

      BEGIN
         SELECT xx_inv_mtl_set_process_id_s.NEXTVAL
           INTO   G_SET_PROCESS_ID
         FROM   dual;
      EXCEPTION
       WHEN OTHERS THEN
           dbg_low('Unable to derive set_process_id'||SQLCODE||':'||SQLERRM);
      END;

      xx_emf_pkg.write_log (XX_EMF_CN_PKG.cn_low,'Find Commmit_sequence');
      BEGIN
          SELECT parameter_value into x_commit_sequence
             FROM  XX_EMF_PROCESS_PARAMETERS xepr,
                  XX_EMF_PROCESS_SETUP xeps
            WHERE xepr.process_id=xeps.process_id
            AND xepr.parameter_name = 'commit_sequence'
            AND xeps.process_name = G_PROCESS_NAME;
       EXCEPTION
          WHEN OTHERS THEN
              xx_emf_pkg.write_log (XX_EMF_CN_PKG.cn_low,'Unable to derive Commmit_sequence, so default 10000 used');
       END;

      FOR c_xx_item_mast_attr_rec IN c_xx_item_mast_attr_upld(xx_emf_cn_pkg.CN_POSTVAL)
      LOOP
          x_commit_mast := x_commit_mast + 1;
         BEGIN
            INSERT INTO mtl_system_items_interface
               (
                inventory_item_id,
                atp_rule_id,
                atp_flag,
                collateral_flag,
                container_item_flag,
                default_lot_status_id,
                default_serial_status_id,
                default_shipping_org,
                dimension_uom_code,
                hazard_class_id,
                unit_height,
                ib_item_instance_class,
                unit_length,
                long_description,
                lot_control_code,     -- Also in Wave1
                shelf_life_code,      -- Also in Wave1
                lot_status_enabled,
                minimum_license_quantity,
                orderable_on_web_flag,
                outside_operation_flag,
                outside_operation_uom_type,
                serial_number_control_code, -- Also in Wave1
                serial_status_enabled,
                shelf_life_days,            -- Also in Wave1
                comms_nl_trackable_flag,
                unit_volume,
                unit_weight,
                must_use_approved_vendor_flag,
                vehicle_item_flag,
                volume_uom_code,
                web_status,
                weight_uom_code,
                unit_width,
                global_attribute_category,
                global_attribute1,
                global_attribute2,
                global_attribute3,
                global_attribute4,
                global_attribute5,
                global_attribute6,
                global_attribute7,
                global_attribute8,
                global_attribute9,
                global_attribute10,
                global_attribute11,
                global_attribute12,
                global_attribute13,
                global_attribute14,
                global_attribute15,
                global_attribute16,
                global_attribute17,
                global_attribute18,
                global_attribute19,
                global_attribute20,
                attribute_category,
                attribute1,
                attribute2,
                attribute3,
                attribute4,
                attribute5,
                attribute6,
                attribute7,
                attribute8,
                attribute9,
                attribute10,
                attribute11,
                attribute12,
                attribute13,
                attribute14,
                attribute15,
                attribute16,
                attribute17,
                attribute18,
                attribute19,
                attribute20,
                attribute21,
                attribute22,
                attribute23,
                attribute24,
                attribute25,
                attribute26,
                attribute27,
             --   attribute28,       --change on 11-OCT-2012
             --   attribute29,       --change on 11-OCT-2012
             --   attribute30,       --change on 11-OCT-2012
                lot_divisible_flag,  -- added on 17_jul_2012 for fs1.1
                --- Required column
                organization_id,
                process_flag,
                transaction_type,
                set_process_id,
                -- Wave1
                inventory_item_status_code,
                purchasing_enabled_flag,
                replenish_to_order_flag,
                build_in_wip_flag,
                buyer_id,
                list_price_per_unit,
                receiving_routing_id,
                item_type,
                postprocessing_lead_time,
                preprocessing_lead_time,
                full_lead_time,
                eng_item_flag,
                purchasing_item_flag,
                customer_order_flag,
                customer_order_enabled_flag,
                wip_supply_type,
                --Wave2
                serviceable_product_flag,
                serv_req_enabled_code,
                serv_billing_enabled_flag,
                material_billable_flag,
                -- who
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login
                )
            VALUES
               (c_xx_item_mast_attr_rec.inventory_item_id, -- derived from segment1
                c_xx_item_mast_attr_rec.atp_rule_id,
                c_xx_item_mast_attr_rec.atp_flag,
                c_xx_item_mast_attr_rec.collateral_flag,
                c_xx_item_mast_attr_rec.container_item_flag,
                c_xx_item_mast_attr_rec.default_lot_status_id,
                c_xx_item_mast_attr_rec.default_serial_status_id,
                c_xx_item_mast_attr_rec.default_shipping_org,
                c_xx_item_mast_attr_rec.dimension_uom_code,
                c_xx_item_mast_attr_rec.hazard_class_id,
                c_xx_item_mast_attr_rec.unit_height,
                c_xx_item_mast_attr_rec.ib_item_instance_class,
                c_xx_item_mast_attr_rec.unit_length,
                c_xx_item_mast_attr_rec.long_description,
                c_xx_item_mast_attr_rec.lot_control_code,  -- Also in Wave1
                c_xx_item_mast_attr_rec.shelf_life_code,   -- Also in Wave1
                c_xx_item_mast_attr_rec.lot_status_enabled,
                c_xx_item_mast_attr_rec.minimum_license_quantity,
                c_xx_item_mast_attr_rec.orderable_on_web_flag,
                c_xx_item_mast_attr_rec.outside_operation_flag,
                c_xx_item_mast_attr_rec.outside_operation_uom_type,
                c_xx_item_mast_attr_rec.serial_number_control_code, -- Also in Wave1
                c_xx_item_mast_attr_rec.serial_status_enabled,
                c_xx_item_mast_attr_rec.shelf_life_days,            -- Also in Wave1
                DECODE(c_xx_item_mast_attr_rec.serviceable_product_flag,'Y','Y',c_xx_item_mast_attr_rec.comms_nl_trackable_flag), -- Wave2 Validation
                c_xx_item_mast_attr_rec.unit_volume,
                c_xx_item_mast_attr_rec.unit_weight,
                c_xx_item_mast_attr_rec.must_use_approved_vendor_flag,
                c_xx_item_mast_attr_rec.vehicle_item_flag,
                c_xx_item_mast_attr_rec.volume_uom_code,
                c_xx_item_mast_attr_rec.web_status,
                c_xx_item_mast_attr_rec.weight_uom_code,
                c_xx_item_mast_attr_rec.unit_width,
                c_xx_item_mast_attr_rec.global_attribute_category,
                c_xx_item_mast_attr_rec.global_attribute1,
                c_xx_item_mast_attr_rec.global_attribute2,
                c_xx_item_mast_attr_rec.global_attribute3,
                c_xx_item_mast_attr_rec.global_attribute4,
                c_xx_item_mast_attr_rec.global_attribute5,
                c_xx_item_mast_attr_rec.global_attribute6,
                c_xx_item_mast_attr_rec.global_attribute7,
                c_xx_item_mast_attr_rec.global_attribute8,
                c_xx_item_mast_attr_rec.global_attribute9,
                c_xx_item_mast_attr_rec.global_attribute10,
                c_xx_item_mast_attr_rec.global_attribute11,
                c_xx_item_mast_attr_rec.global_attribute12,
                c_xx_item_mast_attr_rec.global_attribute13,
                c_xx_item_mast_attr_rec.global_attribute14,
                c_xx_item_mast_attr_rec.global_attribute15,
                c_xx_item_mast_attr_rec.global_attribute16,
                c_xx_item_mast_attr_rec.global_attribute17,
                c_xx_item_mast_attr_rec.global_attribute18,
                c_xx_item_mast_attr_rec.global_attribute19,
                c_xx_item_mast_attr_rec.global_attribute20,
                c_xx_item_mast_attr_rec.attribute_category,
                c_xx_item_mast_attr_rec.attribute1,
                c_xx_item_mast_attr_rec.attribute2,
                c_xx_item_mast_attr_rec.attribute3,
                c_xx_item_mast_attr_rec.attribute4,
                c_xx_item_mast_attr_rec.attribute5,
                c_xx_item_mast_attr_rec.attribute6,
                c_xx_item_mast_attr_rec.attribute7,
                c_xx_item_mast_attr_rec.attribute8,
                c_xx_item_mast_attr_rec.attribute9,
                c_xx_item_mast_attr_rec.attribute10,
                c_xx_item_mast_attr_rec.attribute11,
                c_xx_item_mast_attr_rec.attribute12,
                c_xx_item_mast_attr_rec.attribute13,
                c_xx_item_mast_attr_rec.attribute14,
                c_xx_item_mast_attr_rec.attribute15,
                c_xx_item_mast_attr_rec.attribute16,
                c_xx_item_mast_attr_rec.attribute17,
                c_xx_item_mast_attr_rec.attribute18,
                c_xx_item_mast_attr_rec.attribute19,
                c_xx_item_mast_attr_rec.attribute20,
                c_xx_item_mast_attr_rec.attribute21,
                c_xx_item_mast_attr_rec.attribute22,
                c_xx_item_mast_attr_rec.attribute23,
                c_xx_item_mast_attr_rec.attribute24,
                c_xx_item_mast_attr_rec.attribute25,
                c_xx_item_mast_attr_rec.attribute26,
                c_xx_item_mast_attr_rec.attribute27,
               -- c_xx_item_mast_attr_rec.attribute28,--change on 11-OCT-2012
               -- c_xx_item_mast_attr_rec.attribute29, --change on 11-OCT-2012
               -- c_xx_item_mast_attr_rec.attribute30, -- c_xx_item_mast_attr_rec.batch_id  --change on 11-OCT-2012
                c_xx_item_mast_attr_rec.lot_divisible_flag, -- added on 17_jul_2012 for fs1.1
                --- Required columns
                c_xx_item_mast_attr_rec.organization_id,
                G_PROCESS_FLAG,    --process_flag,
                G_TRANS_TYPE_MAST, --transaction_type,
                G_SET_PROCESS_ID,  --set_process_id,
                -- Wave1
                c_xx_item_mast_attr_rec.inv_item_status_code_orig,
                c_xx_item_mast_attr_rec.purchasing_enabled_flag,
                c_xx_item_mast_attr_rec.replenish_to_order_flag,
                c_xx_item_mast_attr_rec.build_in_wip_flag,
                c_xx_item_mast_attr_rec.buyer_id,
                c_xx_item_mast_attr_rec.list_price_per_unit,
                c_xx_item_mast_attr_rec.receiving_routing_id,
                c_xx_item_mast_attr_rec.item_type_orig,
                c_xx_item_mast_attr_rec.postprocessing_lead_time,
                c_xx_item_mast_attr_rec.preprocessing_lead_time,
                c_xx_item_mast_attr_rec.full_lead_time,
                c_xx_item_mast_attr_rec.eng_item_flag,
                c_xx_item_mast_attr_rec.purchasing_item_flag,
                c_xx_item_mast_attr_rec.customer_order_flag,
                c_xx_item_mast_attr_rec.customer_order_enabled_flag,
                c_xx_item_mast_attr_rec.wip_supply_type_orig,
                --Wave2
                c_xx_item_mast_attr_rec.serviceable_product_flag,
                c_xx_item_mast_attr_rec.serv_req_enabled_code,
                c_xx_item_mast_attr_rec.serv_billing_enabled_flag,
                c_xx_item_mast_attr_rec.material_billable_flag,
                -- who coumns
                g_user_id,   -- created_by,
                SYSDATE,     -- creation_date,
                g_user_id,   -- last_updated_by,
                SYSDATE,     --last_update_date,
                x_last_update_login    --last_update_login
               );
          END;
          IF x_commit_mast >= x_commit_sequence THEN -- Commit for every 10000 record as per review comment
                 commit;
          END IF;
      END LOOP;
      commit;

     FOR cur_rec IN c_get_organization
     LOOP
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Open Interface Submit =>BEFORE');
       -- Change on 11-OCT-2012
       g_req_id_mast :=FND_REQUEST.SUBMIT_REQUEST (application =>'INV'
                                            ,program => 'INCOIN'
                                            ,description => 'Item Open Interface'
                                            ,argument1 => cur_rec.organization_id
                                            ,argument2 => 2
                                            ,argument3 => 1
                                            ,argument4 => 1
                                            ,argument5 => 1 --2
                                            ,argument6 => g_set_process_id
                                            ,argument7 => 2  --Update Items
                                            ,argument8 => 2  --Gather statistics = No
                                            );
       COMMIT;
       IF g_req_id_mast > 0 THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Open Interface Submited for Master attribute Updatation =>SUCCESS'||' request_id :'||g_req_id_mast);
          x_req_return_status := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id      => g_req_id_mast,
                                                                 INTERVAL        => 10,
                                                                 max_wait        => 0,
                                                                 phase           => x_phase,
                                                                 status          => x_status,
                                                                 dev_phase       => x_dev_phase,
                                                                 dev_status      => x_dev_status,
                                                                 message         => x_message
                                                                 );
         IF x_req_return_status = TRUE THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Open Interface Submited for Master attribute Updatation Completed =>'||x_dev_status);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Organization_id =>'||cur_rec.organization_id);
            --mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA,'ITEM_MAST');
            -- Print the records with API Error
            -- print_records_with_api_error('ITEM_MAST');
            x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
          END IF;
        ELSE
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in Item Open Interface for Master attribute Updatation Submit');
          x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
                           ,p_category    =>      xx_emf_cn_pkg.CN_STG_APICALL
                           ,p_error_text  => 'Error in Item Open Interface for Master attribute Updatation Submit'
                           ,p_record_identifier_1 => 'Process level error : Exiting'
                           );
         END IF;
      END LOOP;
        mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA,'ITEM_MAST');
        -- Print the records with API Error
        print_records_with_api_error('ITEM_MAST');

      RETURN x_return_status;
	       EXCEPTION
		       WHEN OTHERS THEN
			       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while inserting into Standard Interface Tables: ' ||SQLERRM);
			       xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
			       x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
			       RETURN x_error_code;

   END process_master_attibute;

   -- Organization Assdignment

   FUNCTION process_org_assignment
    RETURN NUMBER
	 IS
   --------------------------------------------------------------------------------------
   -- Created By                 : Partha S Mohanty
   -- Creation Date              : 10-APR-2012
   -- Description                : This function is used to insert records in mtl_system_items_interface table
   --                              run the Item Open Interface in Update Mode

   -- Parameters description:

   -- return NUMBER
   -----------------------------------------------------------------------------------------
		x_return_status       VARCHAR2(15)  := xx_emf_cn_pkg.CN_SUCCESS;
    x_last_update_login   NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
    x_commit_mast         NUMBER :=0;
    x_commit_sequence     NUMBER := 10000;
    x_req_return_status   BOOLEAN;
    x_req_id              NUMBER;
    x_dev_phase           VARCHAR2(20);
    x_phase               VARCHAR2(20);
    x_dev_status          VARCHAR2(20);
    x_status              VARCHAR2(20);
    x_message             VARCHAR2(100);
    x_organization_id     NUMBER;
    x_org_err_code        VARCHAR2(30);
    x_org_err_msg         VARCHAR2(200);
    l_cnt                 NUMBER;

      CURSOR c_get_organization
      IS
      SELECT distinct organization_id
        FROM mtl_system_items_interface
       WHERE set_process_id = g_set_process_id_assgn
       ORDER by organization_id ;

      --cursor to insert into ITEM interface table
      CURSOR c_xx_item_org_assgn_upld(cp_process_status VARCHAR2) IS
         SELECT *
           FROM xx_item_org_assign_stg
           WHERE batch_id     = G_ASSGN_BATCH_ID
		         AND request_id   = xx_emf_pkg.G_REQUEST_ID
		         AND process_code = cp_process_status
		         AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
		        ORDER BY record_number;
   BEGIN
      g_api_name := 'main.process_org_assignment';
      dbg_med('Inside process_org_assignment');

      --Get the set_process_id to group the extension runs

      BEGIN
         SELECT xx_inv_mtl_set_process_id_s.NEXTVAL
           INTO   G_SET_PROCESS_ID_ASSGN
         FROM   dual;
      EXCEPTION
       WHEN OTHERS THEN
           dbg_low('Unable to derive set_process_id'||SQLCODE||':'||SQLERRM);
      END;

      xx_emf_pkg.write_log (XX_EMF_CN_PKG.cn_low,'Find Commmit_sequence');
      BEGIN
          SELECT parameter_value into x_commit_sequence
             FROM  XX_EMF_PROCESS_PARAMETERS xepr,
                  XX_EMF_PROCESS_SETUP xeps
            WHERE xepr.process_id=xeps.process_id
            AND xepr.parameter_name = 'commit_sequence'
            AND xeps.process_name = G_PROCESS_NAME;
       EXCEPTION
          WHEN OTHERS THEN
              xx_emf_pkg.write_log (XX_EMF_CN_PKG.cn_low,'Unable to derive Commmit_sequence, so default 10000 used');
       END;

      FOR c_xx_item_assgn_rec IN c_xx_item_org_assgn_upld(xx_emf_cn_pkg.CN_POSTVAL)
      LOOP
          x_commit_mast := x_commit_mast + 1;
         BEGIN
            INSERT INTO mtl_system_items_interface
               (
                inventory_item_id,
              --  attribute28,     --change on 11-OCT-2012
                --- Required column
                organization_id,
                process_flag,
                transaction_type,
                set_process_id,
                -- who
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login
                )
            VALUES
               (c_xx_item_assgn_rec.inventory_item_id, -- derived from segment1
               -- c_xx_item_assgn_rec.attribute28, -- c_xx_item_assgn_rec.batch_id  --change on 11-OCT-2012
                --- Required columns
                c_xx_item_assgn_rec.organization_id,
                G_PROCESS_FLAG,    --process_flag,
                G_TRANS_TYPE_ASSGN, --transaction_type,
                G_SET_PROCESS_ID_ASSGN,  --set_process_id,
                -- who coumns
                g_user_id,   -- created_by,
                SYSDATE,     -- creation_date,
                g_user_id,   -- last_updated_by,
                SYSDATE,     --last_update_date,
                x_last_update_login    --last_update_login
               );
          END;
          IF x_commit_mast >= x_commit_sequence THEN -- Commit for every 10000 record as per review comment
                 commit;
          END IF;
      END LOOP;
      commit;

     FOR cur_rec IN c_get_organization
     LOOP
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Open Interface Submit =>BEFORE');
       -- Change on 11-OCT-2012
       g_req_id_assign :=FND_REQUEST.SUBMIT_REQUEST (application =>'INV'
                                            ,program => 'INCOIN'
                                            ,description => 'Item Open Interface'
                                            ,argument1 => cur_rec.organization_id
                                            ,argument2 => 2
                                            ,argument3 => 1
                                            ,argument4 => 1
                                            ,argument5 => 1 --2
                                            ,argument6 => g_set_process_id_assgn
                                            ,argument7 => 1  --Create Items
                                            ,argument8 => 2  --Gather statistics = No
                                            );
       COMMIT;
       IF g_req_id_assign > 0 THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Open Interface Submited for Organization Assignment =>SUCCESS' ||' request_id :'||g_req_id_assign);
          x_req_return_status := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id      => g_req_id_assign,
                                                                 INTERVAL        => 10,
                                                                 max_wait        => 0,
                                                                 phase           => x_phase,
                                                                 status          => x_status,
                                                                 dev_phase       => x_dev_phase,
                                                                 dev_status      => x_dev_status,
                                                                 message         => x_message
                                                                 );
         IF x_req_return_status = TRUE THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Open Interface Submited for Organization Assignment Completed =>'||x_dev_status);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Organization_id =>'||cur_rec.organization_id);
            --mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA,'ITEM_ASSGN');
            -- Print the records with API Error
            -- print_records_with_api_error('ITEM_ASSGN');
            x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
          END IF;
        ELSE
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in Item Open Interface for Organization Assignment Submit');
          x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
                           ,p_category    =>      xx_emf_cn_pkg.CN_STG_APICALL
                           ,p_error_text  => 'Error in Item Open Interface for Organization Assignment Submit'
                           ,p_record_identifier_1 => 'Process level error : Exiting'
                           );
         END IF;
      END LOOP;
           -- Print the records with API Error
            mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA,'ITEM_ASSGN');
            print_records_with_api_error('ITEM_ASSGN');

      RETURN x_return_status;
	       EXCEPTION
		       WHEN OTHERS THEN
			       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while inserting into Standard Interface Tables: ' ||SQLERRM);
			       xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
			       x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
			       RETURN x_error_code;

   END process_org_assignment;


   FUNCTION update_item_attr_table(p_item_assgn VARCHAR2,
                                   p_org_attr_upd VARCHAR2)
    RETURN NUMBER
   IS
   PRAGMA AUTONOMOUS_TRANSACTION;
   --------------------------------------------------------------------------------------
   -- Created By                 : Partha S Mohanty
   -- Creation Date              : 10-APR-2012
   -- Description                : This function is used to update  records in xx_item_org_attr_upd_stg table
   --                              for error records in xx_item_org_assign_stg table

   -- Parameters description:

   -- return NUMBER
   -----------------------------------------------------------------------------------------
     x_error_code       VARCHAR2(15)  := xx_emf_cn_pkg.CN_SUCCESS;

     CURSOR xx_item_org_assign_error IS
       SELECT * FROM xx_item_org_assign_stg
         WHERE error_code IN(xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR);

     CURSOR xx_item_org_assign_proccessed IS
       SELECT * FROM xx_item_org_assign_stg;

   BEGIN

      x_inv_item_assgn_table.DELETE;
      IF ( UPPER(TRIM(p_item_assgn)) = g_yes  AND UPPER(TRIM(p_org_attr_upd)) = g_yes) THEN

        OPEN xx_item_org_assign_error;
	      LOOP
	       	FETCH xx_item_org_assign_error
		           BULK COLLECT INTO x_inv_item_assgn_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

		       FOR i IN 1 .. x_inv_item_assgn_table.COUNT
		       LOOP

               UPDATE xx_item_org_attr_upd_stg
                 SET error_code = x_inv_item_assgn_table(i).error_code,
    			           process_code = x_inv_item_assgn_table(i).process_code,
                     error_mesg = x_inv_item_assgn_table(i).error_mesg
                 WHERE  BATCH_ID =  x_inv_item_assgn_table(i).batch_id
                    AND record_number =  x_inv_item_assgn_table(i).record_number
                    AND request_id = x_inv_item_assgn_table(i).request_id;

            END LOOP;
            x_inv_item_assgn_table.DELETE;
            EXIT WHEN xx_item_org_assign_error%NOTFOUND;
         END LOOP;
         IF xx_item_org_assign_error%ISOPEN THEN
            CLOSE xx_item_org_assign_error;
         END IF;
      END IF;

      IF ( UPPER(TRIM(p_item_assgn)) = g_yes  AND UPPER(TRIM(p_org_attr_upd)) = g_no) THEN

         OPEN xx_item_org_assign_proccessed;
	       LOOP
	       	 FETCH xx_item_org_assign_proccessed
		           BULK COLLECT INTO x_inv_item_assgn_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

		        FOR i IN 1 .. x_inv_item_assgn_table.COUNT
		        LOOP

                UPDATE xx_item_org_attr_upd_stg
                  SET error_code = x_inv_item_assgn_table(i).error_code,
    			            process_code = x_inv_item_assgn_table(i).process_code,
                      error_mesg = x_inv_item_assgn_table(i).error_mesg
                 WHERE  BATCH_ID =  x_inv_item_assgn_table(i).batch_id
                    AND record_number =  x_inv_item_assgn_table(i).record_number
                    AND request_id = x_inv_item_assgn_table(i).request_id;

            END LOOP;
            x_inv_item_assgn_table.DELETE;
            EXIT WHEN xx_item_org_assign_proccessed%NOTFOUND;
         END LOOP;
         IF xx_item_org_assign_proccessed%ISOPEN THEN
            CLOSE xx_item_org_assign_proccessed;
         END IF;
      END IF;
      COMMIT;

      RETURN x_error_code;
    EXCEPTION
        WHEN OTHERS THEN
	        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while updating xx_item_org_attr_upd_stg: ' ||SQLERRM);
			    xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
			    x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
			    RETURN x_error_code;
   END update_item_attr_table;


   FUNCTION process_org_attibute
    RETURN NUMBER
	 IS
   --------------------------------------------------------------------------------------
   -- Created By                 : Partha S Mohanty
   -- Creation Date              : 10-APR-2012
   -- Description                : This function is used to insert records in mtl_system_items_interface table
   --                              run the Item Open Interface in CREATE Mode

   -- Parameters description:

   -- return NUMBER
   -----------------------------------------------------------------------------------------
		x_return_status       VARCHAR2(15)  := xx_emf_cn_pkg.CN_SUCCESS;
    x_last_update_login   NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
    x_commit_org           NUMBER :=0;
    x_commit_sequence     NUMBER := 10000;
    x_req_return_status   BOOLEAN;
    x_req_id              NUMBER;
    x_dev_phase           VARCHAR2(20);
    x_phase               VARCHAR2(20);
    x_dev_status          VARCHAR2(20);
    x_status              VARCHAR2(20);
    x_message             VARCHAR2(100);
    x_organization_id     NUMBER;
    x_org_err_code        VARCHAR2(30);
    x_org_err_msg         VARCHAR2(200);
    l_cnt                 NUMBER;

      CURSOR c_get_organization
      IS
      SELECT distinct organization_id
        FROM mtl_system_items_interface
       WHERE set_process_id = g_set_process_id_org
       ORDER by organization_id ;

      CURSOR c_xx_item_org_attr_upld(cp_process_status VARCHAR2) IS
         SELECT *
           FROM xx_item_org_attr_upd_stg
           WHERE batch_id     = G_ORG_BATCH_ID
		         AND request_id   = xx_emf_pkg.G_REQUEST_ID
		         AND process_code = cp_process_status
		         AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
		        ORDER BY record_number;
   BEGIN
      g_api_name := 'main.process_org_attibute';
      dbg_med('Inside process_org_attibute');

      --Get the set_process_id to group the extension runs

      BEGIN
         SELECT xx_inv_mtl_set_process_id_s.NEXTVAL
           INTO   G_SET_PROCESS_ID_ORG
         FROM   dual;
         dbg_low('Derived set_process_id'||G_SET_PROCESS_ID);
      EXCEPTION
       WHEN OTHERS THEN
           dbg_low('Unable to derive set_process_id'||SQLCODE||':'||SQLERRM);
      END;

      xx_emf_pkg.write_log (XX_EMF_CN_PKG.cn_low,'Find Commmit_sequence');
      BEGIN
          SELECT parameter_value into x_commit_sequence
             FROM  XX_EMF_PROCESS_PARAMETERS xepr,
                  XX_EMF_PROCESS_SETUP xeps
            WHERE xepr.process_id=xeps.process_id
            AND xepr.parameter_name = 'commit_sequence'
            AND xeps.process_name = G_PROCESS_NAME;
       EXCEPTION
          WHEN OTHERS THEN
              xx_emf_pkg.write_log (XX_EMF_CN_PKG.cn_low,'Unable to derive Commmit_sequence, so default 10000 used');
       END;

      FOR c_xx_item_org_attr_rec IN c_xx_item_org_attr_upld(xx_emf_cn_pkg.CN_POSTVAL)
      LOOP
          x_commit_org := x_commit_org + 1;
         BEGIN
            INSERT INTO mtl_system_items_interface
               (
                inventory_item_id,
                asset_category_id,
                mrp_calculate_atp_flag,
                container_type_code,
                asset_creation_code,
                demand_time_fence_code,
                demand_time_fence_days,
                equipment_type,
                exclude_from_budget_flag,
                expense_account,
                fixed_days_supply,
                fixed_lead_time,
                fixed_lot_multiplier,
                fixed_order_quantity,
                purchasing_tax_code,
                internal_volume,
                inventory_planning_code,
                list_price_per_unit,
                planning_make_buy_code,
                maximum_load_weight,
                maximum_order_quantity,
                minimum_fill_percent,
                minimum_order_quantity,
                max_minmax_quantity,
                min_minmax_quantity,
                indivisible_flag,
                planned_inv_point_flag,
                planner_code,
                planning_time_fence_code,
                planning_time_fence_days,
                postprocessing_lead_time,
                preprocessing_lead_time,
                full_lead_time,
                release_time_fence_code,
                release_time_fence_days,
                sales_account,
                source_organization_id,
                source_subinventory,
                source_type,
                substitution_window_code,
                substitution_window_days,
                taxable_flag,
                receiving_routing_id,        -- added on 17_jul_2012 for fs1.1
                outside_operation_flag,      -- added on 17_jul_2012 for fs1.1
                outside_operation_uom_type,  -- added on 17_jul_2012 for fs1.1
                buyer_id,                    -- added on 17_jul_2012 for fs1.1
              --  attribute29,                     --change on 11-OCT-2012
                --- Required column
                organization_id,
                process_flag,
                transaction_type,
                set_process_id,
                -- Wave1
                customer_order_flag,
                purchasing_item_flag,
                build_in_wip_flag,
                ----===
                planning_exception_set,
                atp_flag,
                atp_rule_id,
                atp_components_flag,
                ship_model_complete_flag,
                pick_components_flag,
                default_shipping_org,
                inventory_item_status_code,
                inventory_item_flag,
                stock_enabled_flag,
                mtl_transactions_enabled_flag,
                lot_control_code,
                auto_lot_alpha_prefix,
                start_auto_lot_number,
                shelf_life_code,
                shelf_life_days,
                reservable_type,
                lot_status_enabled,
                default_lot_status_id,
                lot_divisible_flag,
                lot_split_enabled,
                lot_merge_enabled,
                LOT_TRANSLATE_ENABLED,            --- Added on 31-Mar-2015 for FS V4.0
                LOT_SUBSTITUTION_ENABLED,         --- Added on 31-Mar-2015 for FS V4.0
                serial_number_control_code,
                auto_serial_alpha_prefix,
                start_auto_serial_number,
                serial_status_enabled,
                default_serial_status_id,
                default_so_source_type,
                returnable_flag,
                return_inspection_requirement,
                bulk_picked_flag,
                bom_enabled_flag,
                purchasing_enabled_flag,
                customer_order_enabled_flag,
                replenish_to_order_flag,
                wip_supply_type,
                -- who
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login
                )
            VALUES
               (c_xx_item_org_attr_rec.inventory_item_id, -- derived from segment1
                c_xx_item_org_attr_rec.asset_category_id,
                c_xx_item_org_attr_rec.mrp_calculate_atp_flag,
                c_xx_item_org_attr_rec.container_type_code,
                c_xx_item_org_attr_rec.asset_creation_code,
                c_xx_item_org_attr_rec.demand_time_fence_code,
                c_xx_item_org_attr_rec.demand_time_fence_days,
                c_xx_item_org_attr_rec.equipment_type,
                c_xx_item_org_attr_rec.exclude_from_budget_flag,
                c_xx_item_org_attr_rec.expense_account_ccid,  -- expense_account
                c_xx_item_org_attr_rec.fixed_days_supply,
                c_xx_item_org_attr_rec.fixed_lead_time,
                c_xx_item_org_attr_rec.fixed_lot_multiplier,
                c_xx_item_org_attr_rec.fixed_order_quantity,
                c_xx_item_org_attr_rec.purchasing_tax_code,
                c_xx_item_org_attr_rec.internal_volume,
                c_xx_item_org_attr_rec.inventory_planning_code,
                c_xx_item_org_attr_rec.list_price_per_unit,
                c_xx_item_org_attr_rec.planning_make_buy_code,
                c_xx_item_org_attr_rec.maximum_load_weight,
                c_xx_item_org_attr_rec.maximum_order_quantity,
                c_xx_item_org_attr_rec.minimum_fill_percent,
                c_xx_item_org_attr_rec.minimum_order_quantity,
                c_xx_item_org_attr_rec.max_minmax_quantity,
                c_xx_item_org_attr_rec.min_minmax_quantity,
                c_xx_item_org_attr_rec.indivisible_flag,
                c_xx_item_org_attr_rec.planned_inv_point_flag,
                c_xx_item_org_attr_rec.planner_code,
                c_xx_item_org_attr_rec.planning_time_fence_code,
                c_xx_item_org_attr_rec.planning_time_fence_days,
                c_xx_item_org_attr_rec.postprocessing_lead_time,
                c_xx_item_org_attr_rec.preprocessing_lead_time,
                c_xx_item_org_attr_rec.full_lead_time,
                c_xx_item_org_attr_rec.release_time_fence_code,
                c_xx_item_org_attr_rec.release_time_fence_days,
                c_xx_item_org_attr_rec.sales_account_ccid,     -- sales_account
                c_xx_item_org_attr_rec.source_organization_id,
                c_xx_item_org_attr_rec.source_subinventory,
                c_xx_item_org_attr_rec.source_type_code,      -- source_type
                c_xx_item_org_attr_rec.substitution_window_code,
                c_xx_item_org_attr_rec.substitution_windows_days,
                c_xx_item_org_attr_rec.taxable_flag,
                c_xx_item_org_attr_rec.receiving_routing_id,        -- added on 17_jul_2012 for fs1.1
                c_xx_item_org_attr_rec.outside_operation_flag,      -- added on 17_jul_2012 for fs1.1
                c_xx_item_org_attr_rec.outside_operation_uom_type,  -- added on 17_jul_2012 for fs1.1
                c_xx_item_org_attr_rec.buyer_id,                    -- added on 17_jul_2012 for fs1.1
               -- c_xx_item_org_attr_rec.attribute29, -- c_xx_item_org_attr_rec.batch_id --change on 11-OCT-2012
                --- Required columns
                c_xx_item_org_attr_rec.organization_id,
                G_PROCESS_FLAG,    --process_flag,
                G_TRANS_TYPE_ORG, --transaction_type,
                G_SET_PROCESS_ID_ORG,  --set_process_id,
                -- Wave1
                c_xx_item_org_attr_rec.customer_order_flag,
                c_xx_item_org_attr_rec.purchasing_item_flag,
                c_xx_item_org_attr_rec.build_in_wip_flag,
                --=======
                c_xx_item_org_attr_rec.planning_exception_set,
                c_xx_item_org_attr_rec.atp_flag_orig,
                c_xx_item_org_attr_rec.atp_rule_id,
                c_xx_item_org_attr_rec.atp_components_flag_orig,
                c_xx_item_org_attr_rec.ship_model_complete_flag,
                c_xx_item_org_attr_rec.pick_components_flag,
                c_xx_item_org_attr_rec.default_shipping_org_orig,
                c_xx_item_org_attr_rec.inv_item_status_code_orig,
                c_xx_item_org_attr_rec.inventory_item_flag,
                c_xx_item_org_attr_rec.stock_enabled_flag,
                c_xx_item_org_attr_rec.mtl_transactions_enabled_flag,
                c_xx_item_org_attr_rec.lot_control_code_orig,
                c_xx_item_org_attr_rec.auto_lot_alpha_prefix,
                c_xx_item_org_attr_rec.start_auto_lot_number,
                c_xx_item_org_attr_rec.shelf_life_code_orig,
                c_xx_item_org_attr_rec.shelf_life_days,
                c_xx_item_org_attr_rec.reservable_type_orig,
                c_xx_item_org_attr_rec.lot_status_enabled,
                c_xx_item_org_attr_rec.default_lot_status_id,
                c_xx_item_org_attr_rec.lot_divisible_flag,
                c_xx_item_org_attr_rec.lot_split_enabled,
                c_xx_item_org_attr_rec.lot_merge_enabled,
                c_xx_item_org_attr_rec.LOT_TRANSLATE_ENABLED,   -- Added on 31-Mar-2015 for FS V4.0
                c_xx_item_org_attr_rec.LOT_SUBSTITUTION_ENABLED, --Added on 31-Mar-2015 for FS V4.0
                c_xx_item_org_attr_rec.serial_number_ctrl_code_orig,
                c_xx_item_org_attr_rec.auto_serial_alpha_prefix,
                c_xx_item_org_attr_rec.start_auto_serial_number,
                c_xx_item_org_attr_rec.serial_status_enabled,
                c_xx_item_org_attr_rec.default_serial_status_id,
                c_xx_item_org_attr_rec.default_so_source_type,
                c_xx_item_org_attr_rec.returnable_flag,
                c_xx_item_org_attr_rec.return_inspect_req_orig,
                c_xx_item_org_attr_rec.bulk_picked_flag,
                c_xx_item_org_attr_rec.bom_enabled_flag,
                c_xx_item_org_attr_rec.purchasing_enabled_flag,
                c_xx_item_org_attr_rec.customer_order_enabled_flag,
                c_xx_item_org_attr_rec.replenish_to_order_flag,
                c_xx_item_org_attr_rec.wip_supply_type_orig,
                -- who coumns
                g_user_id,   -- created_by,
                SYSDATE,     -- creation_date,
                g_user_id,   -- last_updated_by,
                SYSDATE,     --last_update_date,
                x_last_update_login    --last_update_login
               );
          END;
          IF x_commit_org >= x_commit_sequence THEN -- Commit for every 10000 record
                 commit;
          END IF;
      END LOOP;
      commit;

     FOR cur_rec IN c_get_organization
     LOOP
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Open Interface Submit =>BEFORE');
       -- Change on 11-OCT-2012
       g_req_id_org :=FND_REQUEST.SUBMIT_REQUEST (application =>'INV'
                                            ,program => 'INCOIN'
                                            ,description => 'Item Open Interface'
                                            ,argument1 => cur_rec.organization_id
                                            ,argument2 => 2
                                            ,argument3 => 1
                                            ,argument4 => 1
                                            ,argument5 => 1 --2 -- delete processed row
                                            ,argument6 => g_set_process_id_org
                                            ,argument7 => 2  --Create Items
                                            ,argument8 => 2  --Gather statistics = No
                                            );
       COMMIT;
       IF g_req_id_org > 0 THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Open Interface Submited for Organization attribute Updatation =>SUCCESS'||' request_id :'||g_req_id_org);
          x_req_return_status := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id      => g_req_id_org,
                                                                 INTERVAL        => 10,
                                                                 max_wait        => 0,
                                                                 phase           => x_phase,
                                                                 status          => x_status,
                                                                 dev_phase       => x_dev_phase,
                                                                 dev_status      => x_dev_status,
                                                                 message         => x_message
                                                                 );
         IF x_req_return_status = TRUE THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Open Interface Submited for Organization attribute Updatation Completed =>'||x_dev_status);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Organization_id =>'||cur_rec.organization_id);
            -- mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA,'ITEM_ORG');
            -- Print the records with API Error
            -- print_records_with_api_error('ITEM_ORG');
            x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
          END IF;
        ELSE
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in Item Open Interface for Organization attribute Updatation Submit');
          x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
                           ,p_category    =>      xx_emf_cn_pkg.CN_STG_APICALL
                           ,p_error_text  => 'Error in Item Open Interface for Organization attribute Updatation Submit'
                           ,p_record_identifier_1 => 'Process level error : Exiting'
                           );
         END IF;
      END LOOP;
        mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA,'ITEM_ORG');
        -- Print the records with API Error
        print_records_with_api_error('ITEM_ORG');

      RETURN x_return_status;
	   EXCEPTION
		       WHEN OTHERS THEN
			       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while inserting into Standard Interface Tables: ' ||SQLERRM);
			       xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
			       x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
			       RETURN x_error_code;

   END process_org_attibute;

   -- Change on 11-OCT-2012
   -- delete error records from mtl_system_items_interface
   PROCEDURE delete_from_interface
   IS
   PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'delete error records from mtl_system_items_interface');
     delete from mtl_system_items_interface where request_id in(g_req_id_mast,g_req_id_org,g_req_id_assign);
     commit;
   END;

   BEGIN
      --Main Begin
      ----------------------------------------------------------------------------------------------------
      --Initialize Trace
      --Purpose : Set the program environment for Tracing
      ----------------------------------------------------------------------------------------------------

      retcode := xx_emf_cn_pkg.CN_SUCCESS;

	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Setting Environment');

	    -- Master level --

	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling ITEM_MAST Set_cnv_env');
	    set_cnv_env (p_batch_id,xx_emf_cn_pkg.CN_YES,'ITEM_MAST');

	    -- Organization level --

	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling ITEM_ORG Set_cnv_env');
	    set_cnv_env (p_org_batch_id,xx_emf_cn_pkg.CN_YES,'ITEM_ORG');

      -- Organization Assignment level --

	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling ITEM_ORG Set_cnv_env');
	    set_cnv_env (p_org_batch_id,xx_emf_cn_pkg.CN_YES,'ITEM_ASSGN');

        -- include all the parameters to the conversion main here
        -- as medium log messages
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Starting main process with the following parameters');
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_batch_id '	|| p_batch_id);
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_org_batch_id '	|| p_org_batch_id);
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_restart_flag '	|| p_restart_flag);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_validate_and_load '	|| p_validate_and_load);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_mast_attr_update '	|| p_mast_attr_update);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_item_assign '	|| p_item_assign);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_org_attr_update '	|| p_org_attr_update);
	    -- Call procedure to update records with the current request_id
	    -- So that we can process only those records
	    -- This gives a better handling of restartability
  /*  IF UPPER(trim(p_item_assign)) = g_yes THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Prepare staging table for Assignment..');
	    create_table_for_assignment;
      END IF;  */

	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling mark_records_for_processing..');
	    mark_records_for_processing(p_restart_flag => p_restart_flag,
                                  p_mast_attr => p_mast_attr_update,
                                  p_org_attr  => p_org_attr_update,
                                  p_org_assgn => p_item_assign);

       -- Set the stage to Pre Validations
		   set_stage (xx_emf_cn_pkg.CN_PREVAL);

       -- PRE_VALIDATIONS SHOULD BE RETAINED
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling xx_inv_item_attr_upd_pkg.pre_validations ..');

		x_error_code := xx_inv_item_attr_upd_pkg.pre_validations;

		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After pre-validations X_ERROR_CODE ' || X_ERROR_CODE);

      -- Update process code of staging records
		  -- Update Header and Lines Level
		  update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS,'ITEM_MAST');
		  update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS,'ITEM_ORG');

     IF UPPER(trim(p_item_assign)) = g_yes THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Prepare staging table for Assignment..');
	    create_table_for_assignment;
      update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS,'ITEM_ASSGN');
     END IF;


      xx_emf_pkg.propagate_error ( x_error_code);

    IF UPPER(trim(p_mast_attr_update)) = g_yes THEN
      -- Set the stage to data Validations
	    set_stage (xx_emf_cn_pkg.CN_VALID);

      OPEN c_xx_inv_item_mast ( xx_emf_cn_pkg.CN_PREVAL);
	     LOOP
	       	FETCH c_xx_inv_item_mast
		           BULK COLLECT INTO x_inv_item_mast_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

		   FOR i IN 1 .. x_inv_item_mast_table.COUNT
		  LOOP
			  BEGIN
				-- Perform header level Base App Validations
				      x_error_code := item_mast_attr_validations(x_inv_item_mast_table (i));
			        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_inv_item_mast_table (i).record_number|| ' is ' || x_error_code);
			       	update_mast_attr_rec_status (x_inv_item_mast_table(i), x_error_code);
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
                  update_item_mast_attr_records ( x_inv_item_mast_table);
                  RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
           WHEN OTHERS
           THEN
                  xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_inv_item_mast_table (i).record_number);
         END;

       END LOOP;

          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_inv_item_mast_table.count ' || x_inv_item_mast_table.COUNT );
          update_item_mast_attr_records( x_inv_item_mast_table);
          x_inv_item_mast_table.DELETE;

          EXIT WHEN c_xx_inv_item_mast%NOTFOUND;
      END LOOP;


      IF c_xx_inv_item_mast%ISOPEN THEN
          CLOSE c_xx_inv_item_mast;
      END IF;

    -- Once data-validations are complete the loop through the pre-interface records
    -- and perform data derivations on this table
    -- Set the stage to data derivations
    set_stage (xx_emf_cn_pkg.CN_DERIVE);

    OPEN c_xx_inv_item_mast ( xx_emf_cn_pkg.CN_VALID);
    LOOP
            FETCH c_xx_inv_item_mast
            BULK COLLECT INTO x_inv_item_mast_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

            FOR i IN 1 .. x_inv_item_mast_table.COUNT
            LOOP

                    BEGIN

                            -- Perform header level Base App Validations
                            x_error_code := item_mast_attr_derivations (x_inv_item_mast_table (i));
                            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_inv_item_mast_table (i).record_number|| ' is ' || x_error_code);
                            update_mast_attr_rec_status (x_inv_item_mast_table (i), x_error_code);
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
                                    update_item_mast_attr_records ( x_inv_item_mast_table);
                                    RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                            WHEN OTHERS
                            THEN
                                    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_inv_item_mast_table (i).record_number);
                    END;

            END LOOP;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_inv_item_mast_table.count ' || x_inv_item_mast_table.COUNT );

            update_item_mast_attr_records ( x_inv_item_mast_table);

            x_inv_item_mast_table.DELETE;

            EXIT WHEN c_xx_inv_item_mast%NOTFOUND;
    END LOOP;

    IF c_xx_inv_item_mast%ISOPEN THEN
            CLOSE c_xx_inv_item_mast;
    END IF;

    -- Set the stage to Post Validations
    set_stage (xx_emf_cn_pkg.CN_POSTVAL);
		x_error_code := post_validations ();
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
		mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL,'ITEM_MAST');
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);
    xx_emf_pkg.propagate_error ( x_error_code);
 END IF;
   --------------Organization Assignment Level Validations --------
  IF UPPER(trim(p_item_assign)) = g_yes THEN
   -- Set the stage to data Validations
	    set_stage (xx_emf_cn_pkg.CN_VALID);

      OPEN c_xx_inv_item_assgn ( xx_emf_cn_pkg.CN_PREVAL);
	     LOOP
	       	FETCH c_xx_inv_item_assgn
		           BULK COLLECT INTO x_inv_item_assgn_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

		   FOR i IN 1 .. x_inv_item_assgn_table.COUNT
		  LOOP
			  BEGIN
				-- Perform header level Base App Validations
				      x_error_code := item_assgn_validations(x_inv_item_assgn_table (i));
			        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_inv_item_assgn_table (i).record_number|| ' is ' || x_error_code);
			       	update_assgn_attr_rec_status (x_inv_item_assgn_table(i), x_error_code);
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
                  update_item_assgn_attr_record ( x_inv_item_assgn_table);
                  RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
           WHEN OTHERS
           THEN
                  xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_inv_item_assgn_table (i).record_number);
         END;

       END LOOP;

          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_inv_item_assgn_table.count ' || x_inv_item_assgn_table.COUNT );
          update_item_assgn_attr_record( x_inv_item_assgn_table);
          x_inv_item_assgn_table.DELETE;

          EXIT WHEN c_xx_inv_item_assgn%NOTFOUND;
      END LOOP;


      IF c_xx_inv_item_assgn%ISOPEN THEN
          CLOSE c_xx_inv_item_assgn;
      END IF;

    -- Once data-validations are complete the loop through the pre-interface records
    -- and perform data derivations on this table
    -- Set the stage to data derivations
    set_stage (xx_emf_cn_pkg.CN_DERIVE);

    OPEN c_xx_inv_item_assgn ( xx_emf_cn_pkg.CN_VALID);
    LOOP
            FETCH c_xx_inv_item_assgn
            BULK COLLECT INTO x_inv_item_assgn_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

            FOR i IN 1 .. x_inv_item_assgn_table.COUNT
            LOOP

                    BEGIN

                            -- Perform header level Base App Validations
                            x_error_code := item_assgn_derivations (x_inv_item_assgn_table (i));
                            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_inv_item_assgn_table (i).record_number|| ' is ' || x_error_code);
                            update_assgn_attr_rec_status (x_inv_item_assgn_table (i), x_error_code);
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
                                    update_item_assgn_attr_record ( x_inv_item_assgn_table);
                                    RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                            WHEN OTHERS
                            THEN
                                    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_inv_item_mast_table (i).record_number);
                    END;

            END LOOP;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_inv_item_assgn_table.count ' || x_inv_item_assgn_table.COUNT );

            update_item_assgn_attr_record (x_inv_item_assgn_table);

            x_inv_item_assgn_table.DELETE;

            EXIT WHEN c_xx_inv_item_assgn%NOTFOUND;
    END LOOP;

    IF c_xx_inv_item_assgn%ISOPEN THEN
            CLOSE c_xx_inv_item_assgn;
    END IF;

    -- Set the stage to Post Validations
    set_stage (xx_emf_cn_pkg.CN_POSTVAL);
		x_error_code := post_validations ();
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
		mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL,'ITEM_ASSGN');
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);
    xx_emf_pkg.propagate_error ( x_error_code);

  END IF;  -- for Assignment
    -------- Organization  Level Validation ---------------------------------------------------------------------------

	-- Set the stage to data Validations
 IF UPPER(trim(p_org_attr_update)) = g_yes THEN
	set_stage (xx_emf_cn_pkg.CN_VALID);

	OPEN c_xx_inv_item_org (xx_emf_cn_pkg.CN_PREVAL);
	LOOP
	       	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'In the Organization level records loop');

	       	FETCH c_xx_inv_item_org
		         BULK COLLECT INTO x_inv_item_org_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

		FOR i IN 1 .. x_inv_item_org_table.COUNT
		LOOP
			BEGIN
			       -- Perform Line level Base App Validations
			       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling Data Validations for Organization Level');
			       x_error_code := item_org_attr_validations(x_inv_item_org_table(i));
			       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_inv_item_org_table(i).record_number|| ' is ' || x_error_code);
			       update_org_attr_rec_status (x_inv_item_org_table(i), x_error_code);
			       xx_emf_pkg.propagate_error (x_error_code);

			EXCEPTION
				-- If HIGH error then it will be propagated to the next level
				-- IF the process has to continue maintain it as a medium severity
				WHEN xx_emf_pkg.G_E_REC_ERROR
				THEN
					xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Item Organization Level '||xx_emf_cn_pkg.CN_REC_ERR);

				WHEN xx_emf_pkg.G_E_PRC_ERROR
				THEN
					xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Item Organization Level - Process Level Error in Data Validations');

					update_item_org_attr_records ( x_inv_item_org_table);

					RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);

				WHEN OTHERS
				THEN
					xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_inv_item_org_table (i).record_number);
			END;
		END LOOP;

		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_bom_comp_table.count ' || x_inv_item_org_table.COUNT );

		update_item_org_attr_records ( x_inv_item_org_table);

		x_inv_item_org_table.DELETE;

		EXIT WHEN c_xx_inv_item_org%NOTFOUND;
	END LOOP;

  IF c_xx_inv_item_org%ISOPEN THEN
          CLOSE c_xx_inv_item_org;
  END IF;

  -- Set the stage to data derivations
    set_stage (xx_emf_cn_pkg.CN_DERIVE);

    OPEN c_xx_inv_item_org ( xx_emf_cn_pkg.CN_VALID);
    LOOP
            FETCH c_xx_inv_item_org
            BULK COLLECT INTO x_inv_item_org_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

            FOR i IN 1 .. x_inv_item_org_table.COUNT
            LOOP

                    BEGIN
                            -- Perform header level Base App Validations
                            x_error_code :=item_org_attr_derivations (x_inv_item_org_table (i));
                            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_inv_item_org_table (i).record_number|| ' is ' || x_error_code);
                            update_org_attr_rec_status (x_inv_item_org_table (i), x_error_code);
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
                                    update_item_org_attr_records ( x_inv_item_org_table);
                                    RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                            WHEN OTHERS
                            THEN
                                    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_inv_item_org_table(i).record_number);
                    END;

            END LOOP;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_bom_hdr_table.count ' || x_inv_item_org_table.COUNT );

            update_item_org_attr_records ( x_inv_item_org_table);

            x_inv_item_org_table.DELETE;

            EXIT WHEN c_xx_inv_item_org%NOTFOUND;
    END LOOP;

    IF c_xx_inv_item_org%ISOPEN THEN
            CLOSE c_xx_inv_item_org;
    END IF;

   -- Set the stage to Post Validations
   set_stage (xx_emf_cn_pkg.CN_POSTVAL);

                -- Change the validations package to the appropriate package name
                -- Modify the parameters as required
                -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
                -- PRE_VALIDATIONS SHOULD BE RETAINED

		x_error_code := post_validations ();
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
		mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL,'ITEM_ORG');
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);
    xx_emf_pkg.propagate_error ( x_error_code);
  END IF; -- orgt update

    IF p_validate_and_load = g_validate_and_load THEN
         -- Set the stage to Process
    	   set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Before process_data');

      IF UPPER(trim(p_mast_attr_update)) = g_yes THEN
    	   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Before updating master attributes');
    	   x_error_code := process_master_attibute;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After updating master attribute: x_error_code :'||x_error_code);

         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After process_data master attribute');
         mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA,'ITEM_MAST');
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After Process master attribute mark_records_complete x_error_code'||x_error_code);
      END IF;

      IF UPPER(trim(p_item_assign)) = g_yes THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Before  organization Assignment');
    	   x_error_code := process_org_assignment;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After organization Assignment: x_error_code :'||x_error_code);

         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After process_data organization Assignment');
         mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA,'ITEM_ASSGN');
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After Process organization Assignment mark_records_complete x_error_code'||x_error_code);

        -- Update same records in Item_atribute stagin table
        -- x_error_code := update_item_attr_table(p_item_assign,p_org_attr_update);  --- commented on 11-JUN-2013
       END IF;

       IF UPPER(trim(p_org_attr_update)) = g_yes THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Before updating organization attributes');
    	   x_error_code := process_org_attibute;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After updating organization attribute: x_error_code :'||x_error_code);

         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After process_data organization attributes');
         mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA,'ITEM_ORG');
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After Process organization attributes mark_records_complete x_error_code'||x_error_code);
       END IF;

    	   xx_emf_pkg.propagate_error ( x_error_code);
	   END IF;
       print_detail_record_count(p_validate_and_load);
       update_record_count(p_validate_and_load);
	     xx_emf_pkg.create_report;
       --delete_from_interface;
EXCEPTION
	WHEN xx_emf_pkg.G_E_ENV_NOT_SET THEN
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Checking if this is OK');
		fnd_file.put_line ( fnd_file.output, xx_emf_pkg.CN_ENV_NOT_SET);
		retcode := xx_emf_cn_pkg.CN_REC_ERR;
	        xx_emf_pkg.create_report;
          --delete_from_interface;
	WHEN xx_emf_pkg.G_E_REC_ERROR THEN
		retcode := xx_emf_cn_pkg.CN_REC_ERR;
	        xx_emf_pkg.create_report;
          --delete_from_interface;
	WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
		retcode := xx_emf_cn_pkg.CN_PRC_ERR;
	        xx_emf_pkg.create_report;
          --delete_from_interface;
	WHEN OTHERS THEN
		retcode := xx_emf_cn_pkg.CN_PRC_ERR;
		xx_emf_pkg.create_report;
    --delete_from_interface;
 END main;

END xx_inv_item_attr_upd_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_ITEM_ATTR_UPD_PKG TO INTG_XX_NONHR_RO;
