DROP PACKAGE BODY APPS.XX_BOM_RTG_CNV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xx_bom_rtg_cnv_pkg AS
  /* $Header: XXINVITEMCOSTCNV.pkb 1.0.0 2012/02/24 00:00:00 dsengupta noship $ */
--==================================================================================
  -- Created By     : Diptiman Sengupta
  -- Creation Date  : 24-FEB-2012
  -- Filename       : XXBOMRTGCNV.pkb
  -- Description    : Package body for Item Routing Import

  -- Change History:

  -- Date        Version#    Name                Remarks
  -- ----------- --------    ---------------     ------------------------------------
  -- 24-Feb-2012   1.0       Diptiman Sengupta   Initial development.
  -- 24-Jan-2014   2.0       Partha Mohanty      Changes for OSP Respource and Type
  -- 13-FEB-2014   3.0       Aabhas Bhargava     Added Check for Engineering Items
  -- 26-DEC-2014   4.0       Sharath Babu        Added new fields as per Wave2
  -- 18-FEB-2015   5.0       Sharath Babu        Added operations network as per Wave2
--====================================================================================


    ctr  number(30) := 1;
    --**********************************************************************
    --	Procedure to set environment.
    --**********************************************************************
    PROCEDURE set_cnv_env (p_batch_id      VARCHAR2
                          ,p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES
                          ) IS
    	x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
    	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside set_cnv_env...');
    	G_BATCH_ID	  := p_batch_id;
    	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_BATCH_ID: '||G_BATCH_ID );

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
                                , 'In xx_bom_rtg_cnv_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_low;

    PROCEDURE dbg_med (p_dbg_text varchar2)
    IS
    BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium
                                , 'In xx_bom_rtg_cnv_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_med;

    PROCEDURE dbg_high (p_dbg_text varchar2)
    IS
    BEGIN
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high
                                , 'In xx_bom_rtg_cnv_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_high;

    --**********************************************************************
    --	Procedure to mark records for processing.
    --**********************************************************************

    PROCEDURE mark_records_for_processing (p_restart_flag  IN VARCHAR2
                                          ) IS
    	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
    	----- All records are processed if the Restart Flag is set to All Records otherwise only Error records -----
        g_api_name := 'mark_records_for_processing';
    	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside of mark records for processing...');

    	IF p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS THEN

	--------------Update Routing Header Staging table-------------------------------
    		UPDATE xx_bom_rtg_hdr_stg
    		   SET request_id = xx_emf_pkg.G_REQUEST_ID,
    		       error_code = xx_emf_cn_pkg.CN_NULL,
    		       process_code = xx_emf_cn_pkg.CN_NEW,
		           error_mesg = NULL,
               routing_sequence_id = NULL
    		 WHERE batch_id = G_BATCH_ID;
                   --AND NVL(process_code,xx_emf_cn_pkg.CN_NEW) NOT IN(xx_emf_cn_pkg.CN_PROCESS_DATA);

                DELETE FROM bom_op_routings_interface
                 WHERE attribute11 = G_BATCH_ID;

	--------------Update Routing Operations Sequence Staging table-------------------------------
    		UPDATE xx_bom_rtg_op_stg
    		   SET request_id = xx_emf_pkg.G_REQUEST_ID,
    		       error_code = xx_emf_cn_pkg.CN_NULL,
    		       process_code1 = xx_emf_cn_pkg.CN_NEW,
		       error_mesg = NULL
    		 WHERE batch_id = G_BATCH_ID;
                   --AND NVL(process_code1,xx_emf_cn_pkg.CN_NEW) NOT IN(xx_emf_cn_pkg.CN_PROCESS_DATA);

                DELETE FROM bom_op_sequences_interface
                 WHERE attribute11 = G_BATCH_ID;
        --Added as per Wave2
	--------------Update Routing Operation Network Staging table-------------------------------
    		UPDATE xx_bom_op_network_stg
    		   SET request_id = xx_emf_pkg.G_REQUEST_ID,
    		       error_code = xx_emf_cn_pkg.CN_NULL,
    		       process_code = xx_emf_cn_pkg.CN_NEW,
		       error_mesg = NULL
    		 WHERE batch_id = G_BATCH_ID;
                   --AND NVL(process_code1,xx_emf_cn_pkg.CN_NEW) NOT IN(xx_emf_cn_pkg.CN_PROCESS_DATA);

                DELETE FROM bom_op_networks_interface
                 WHERE attribute11 = G_BATCH_ID;

	--------------Update Routing Operation Resources Staging table-------------------------------
    		UPDATE xx_bom_rtg_res_stg
    		   SET request_id = xx_emf_pkg.G_REQUEST_ID,
    		       error_code = xx_emf_cn_pkg.CN_NULL,
    		       process_code = xx_emf_cn_pkg.CN_NEW,
		       error_mesg = NULL
    		 WHERE batch_id = G_BATCH_ID;
                   --AND NVL(process_code,xx_emf_cn_pkg.CN_NEW) NOT IN(xx_emf_cn_pkg.CN_PROCESS_DATA);

                DELETE FROM bom_op_resources_interface
                 WHERE attribute11 = G_BATCH_ID;
                DELETE FROM  mtl_interface_errors;
    	ELSIF p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS THEN

	--------------Update Routing Header Staging table-------------------------------
    		UPDATE xx_bom_rtg_hdr_stg
    		   SET request_id   = xx_emf_pkg.G_REQUEST_ID,
    		       error_code   = xx_emf_cn_pkg.CN_NULL,
    		       process_code = xx_emf_cn_pkg.CN_NEW,
		           error_mesg = NULL,
               routing_sequence_id = NULL
    		 WHERE batch_id = G_BATCH_ID
    		   AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
    		       xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR);

    		DELETE FROM bom_op_routings_interface
                 WHERE attribute11 = G_BATCH_ID;

	--------------Update Routing Operations Sequence Staging table-------------------------------
    		UPDATE xx_bom_rtg_op_stg
    		   SET request_id   = xx_emf_pkg.G_REQUEST_ID,
    		       error_code   = xx_emf_cn_pkg.CN_NULL,
    		       process_code1 = xx_emf_cn_pkg.CN_NEW,
		       error_mesg = NULL
    		 WHERE batch_id = G_BATCH_ID
    		   AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
    		       xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR);

    		DELETE FROM bom_op_sequences_interface
                 WHERE attribute11 = G_BATCH_ID;

	--------------Update Routing Operation Resources Staging table-------------------------------
    		UPDATE xx_bom_rtg_res_stg
    		   SET request_id   = xx_emf_pkg.G_REQUEST_ID,
    		       error_code   = xx_emf_cn_pkg.CN_NULL,
    		       process_code = xx_emf_cn_pkg.CN_NEW,
		       error_mesg = NULL
    		 WHERE batch_id = G_BATCH_ID
    		   AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
    		       xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR);

    		DELETE FROM bom_op_resources_interface
                 WHERE attribute11 = G_BATCH_ID;
        DELETE FROM  mtl_interface_errors;
        --Added as per Wave2
	--------------Update Routing operations network Staging table-------------------------------
    		UPDATE xx_bom_op_network_stg
    		   SET request_id = xx_emf_pkg.G_REQUEST_ID,
    		       error_code = xx_emf_cn_pkg.CN_NULL,
    		       process_code = xx_emf_cn_pkg.CN_NEW,
		           error_mesg = NULL
    		 WHERE batch_id = G_BATCH_ID;
                   --AND NVL(process_code,xx_emf_cn_pkg.CN_NEW) NOT IN(xx_emf_cn_pkg.CN_PROCESS_DATA);

                DELETE FROM bom_op_networks_interface
                 WHERE attribute11 = G_BATCH_ID;
        END IF;

        COMMIT;

        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'End of mark records for processing...');
    END;

    --**********************************************************************
    --	Procedure to set stage for staging table.
    --**********************************************************************

    PROCEDURE set_stage (p_stage VARCHAR2)
    IS
    BEGIN
    	G_STAGE := p_stage;
    END set_stage;

    --**********************************************************************
    --	Procedure to update staging table for Routing Header
    --**********************************************************************

    PROCEDURE update_staging_records( p_error_code VARCHAR2, p_entity VARCHAR2) IS

	x_last_update_date     DATE   := SYSDATE;
	x_last_updated_by      NUMBER := fnd_global.user_id;
	x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
	g_api_name := 'update_staging_records';

	IF p_entity = 'RTG' THEN

    	    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside update_staging_records for Routing');
	    UPDATE xx_bom_rtg_hdr_stg
	       SET process_code = G_STAGE,
		   error_code = DECODE ( error_code, NULL, p_error_code, error_code),
		   last_update_date = x_last_update_date,
		   last_updated_by   = x_last_updated_by,
		   last_update_login = x_last_update_login
	     WHERE batch_id		= G_BATCH_ID
	       AND request_id	= xx_emf_pkg.G_REQUEST_ID
	       AND process_code	= xx_emf_cn_pkg.CN_NEW;

	ELSIF p_entity = 'OPR' THEN

	    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside update_staging_records for Operations');
	    UPDATE xx_bom_rtg_op_stg
	       SET process_code1 = G_STAGE,
		   error_code = DECODE ( error_code, NULL, p_error_code, error_code),
		   last_update_date = x_last_update_date,
		   last_updated_by   = x_last_updated_by,
		   last_update_login = x_last_update_login
	     WHERE batch_id		= G_BATCH_ID
	       AND request_id	= xx_emf_pkg.G_REQUEST_ID
	       AND process_code1 = xx_emf_cn_pkg.CN_NEW;

	ELSIF p_entity = 'RES' THEN

	    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside update_staging_records for Resources');
	    UPDATE xx_bom_rtg_res_stg
	       SET process_code = G_STAGE,
		   error_code = DECODE ( error_code, NULL, p_error_code, error_code),
		   last_update_date = x_last_update_date,
		   last_updated_by   = x_last_updated_by,
		   last_update_login = x_last_update_login
	     WHERE batch_id		= G_BATCH_ID
	       AND request_id	= xx_emf_pkg.G_REQUEST_ID
	       AND process_code	= xx_emf_cn_pkg.CN_NEW;
        --Added as per Wave2
	ELSIF p_entity = 'NTWRK' THEN

	    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside update_staging_records for network operations');
	    UPDATE xx_bom_op_network_stg
	       SET process_code = G_STAGE,
		   error_code = DECODE ( error_code, NULL, p_error_code, error_code),
		   last_update_date = x_last_update_date,
		   last_updated_by   = x_last_updated_by,
		   last_update_login = x_last_update_login
	     WHERE batch_id		= G_BATCH_ID
	       AND request_id	= xx_emf_pkg.G_REQUEST_ID
	       AND process_code	= xx_emf_cn_pkg.CN_NEW;

	END IF;

	COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
	     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while updating staging records status: '||SQLERRM);

    END update_staging_records;

    --**********************************************************************
    --	Function to Find Max
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

    --**********************************************************************
    --	Function for pre validations
    --**********************************************************************

    FUNCTION pre_validations(p_entity VARCHAR2)
    RETURN NUMBER
    IS
	x_error_code	    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

	-- Cursor for duplicate Routing record
	CURSOR c_xx_itemrtg_dup IS
	SELECT ic1.assembly_item_number
	      ,ic1.organization_code
          FROM xx_bom_rtg_hdr_stg ic1
         WHERE ic1.rowid<>(SELECT min(ic2.rowid)
          FROM xx_bom_rtg_hdr_stg ic2
         WHERE ic2.assembly_item_number = ic1.assembly_item_number
           AND ic2.organization_code = ic1.organization_code
           AND ic2.process_code = xx_emf_cn_pkg.CN_NEW
           AND ic2.batch_id	= G_BATCH_ID
            )
	   AND ic1.process_code = xx_emf_cn_pkg.CN_NEW
           AND ic1.batch_id	= G_BATCH_ID
           FOR UPDATE OF ic1.process_code
		        ,ic1.error_code
		        ,ic1.error_mesg;

	-- Cursor for duplicate Operations record
	CURSOR c_xx_rtgop_dup IS
	SELECT ic1.assembly_item_number
	      ,ic1.organization_code
	      ,ic1.department_code
          FROM xx_bom_rtg_op_stg ic1
         WHERE ic1.rowid<>(SELECT min(ic2.rowid)
          FROM xx_bom_rtg_op_stg ic2
         WHERE ic2.assembly_item_number = ic1.assembly_item_number
           AND ic2.organization_code = ic1.organization_code
	   AND ic2.department_code = ic1.department_code
	   AND ic2.operation_seq_num = ic1.operation_seq_num
           AND ic2.process_code1 = xx_emf_cn_pkg.CN_NEW
           AND ic2.batch_id	= G_BATCH_ID
            )
	   AND ic1.process_code1 = xx_emf_cn_pkg.CN_NEW
           AND ic1.batch_id	= G_BATCH_ID
           FOR UPDATE OF ic1.process_code
		        ,ic1.error_code
		        ,ic1.error_mesg;
        /**DS
	-- Cursor for duplicate Resources record
	CURSOR c_xx_rtgres_dup IS
	SELECT ic1.assembly_item_number
	      ,ic1.organization_code
	     -- ,ic1.resource_code
          FROM xx_bom_rtg_res_stg ic1
         WHERE ic1.rowid<>(SELECT min(ic2.rowid)
          FROM xx_bom_rtg_res_stg ic2
         WHERE ic2.assembly_item_number = ic1.assembly_item_number
           AND ic2.organization_code = ic1.organization_code
	   --AND ic2.resource_code = ic1.resource_code
           AND ic2.process_code = xx_emf_cn_pkg.CN_NEW
           AND ic2.batch_id	= G_BATCH_ID
            )
	   AND ic1.process_code = xx_emf_cn_pkg.CN_NEW
           AND ic1.batch_id	= G_BATCH_ID
           FOR UPDATE OF ic1.process_code
		        ,ic1.error_code
		        ,ic1.error_mesg;*/
    BEGIN

	IF p_entity = 'RTG' THEN

	    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Inside Pre-Validations for Routing Header: Duplicate checking');

	    --Start of the loop to print all the records that are duplicate in the Routing Header staging table
	    dbg_low('Following records are duplicate Routing Header records');
	    FOR cnt IN c_xx_itemrtg_dup
	    LOOP
		UPDATE xx_bom_rtg_hdr_stg
		   SET process_code = xx_emf_cn_pkg.CN_PREVAL,
		       error_code = xx_emf_cn_pkg.CN_REC_ERR
		      ,error_mesg='Duplicate record exists in the Routing Header staging table'
		 WHERE CURRENT OF c_xx_itemrtg_dup;

		dbg_low('Assembly Item Number:     '||cnt.assembly_item_number);
		dbg_low('Organization Code:      '||cnt.organization_code);

	    END LOOP;

	ELSIF p_entity = 'OPR' THEN

    	    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Inside Pre-Validations for Routing Operations Sequence: Duplicate checking');

	    --Start of the loop to print all the records that are duplicate in the Routing Operations Sequence staging table
	    dbg_low('Following records are duplicate Routing Operations Sequence records');
	    FOR cnt IN c_xx_rtgop_dup
	    LOOP
		UPDATE xx_bom_rtg_op_stg
		   SET process_code1 = xx_emf_cn_pkg.CN_PREVAL,
		       error_code = xx_emf_cn_pkg.CN_REC_ERR
		      ,error_mesg='Duplicate record exists in the Routing Operations Sequence staging table'
		 WHERE CURRENT OF c_xx_rtgop_dup;

		dbg_low('Assembly Item Number:     '||cnt.assembly_item_number);
		dbg_low('Organization Code:      '||cnt.organization_code);
		dbg_low('Department Code:      '||cnt.department_code);

	    END LOOP;

	/**DS--ELSIF p_entity = 'RES' THEN

	    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Inside Pre-Validations for Routing Operation Resources: Duplicate checking');

	    --Start of the loop to print all the records that are duplicate in the Routing Operation Resources staging table
	    dbg_low('Following records are duplicate Routing Operation Resources records');
	    FOR cnt IN c_xx_rtgres_dup
	    LOOP
		UPDATE xx_bom_rtg_res_stg
		   SET process_code = xx_emf_cn_pkg.CN_PREVAL,
		       error_code = xx_emf_cn_pkg.CN_REC_ERR
		      ,error_mesg='Duplicate record exists in the Routing Operations Resource staging table'
		 WHERE CURRENT OF c_xx_rtgres_dup;

		dbg_low('Assembly Item Number:     '||cnt.assembly_item_number);
		dbg_low('Organization Code:      '||cnt.organization_code);
		dbg_low('Resource Code:      '||cnt.resource_code);

	    END LOOP;*/

	END IF;

	COMMIT;
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

    --**********************************************************************
    --	Function to validate the Routing Header data
    --**********************************************************************

    FUNCTION xx_itemrtg_validation(csr_itemrtg_print_rec IN OUT xx_bom_rtg_cnv_pkg.G_XX_RTG_HDR_STG_REC_TYPE
                          ) RETURN NUMBER
    IS

	x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	x_invorg_id          NUMBER := NULL;
	x_item_id            NUMBER := NULL;
	x_num_dept_id        NUMBER := NULL;
	x_num_res_id         NUMBER := NULL;
	x_subinv_chk	     NUMBER := NULL;
	x_locator_chk	     NUMBER := NULL;

	-------------------------------- Validate Organization Code --------------------------------
	FUNCTION is_org_code_valid(p_rec_number NUMBER,x_org_code VARCHAR2,p_assembly_item_number VARCHAR2)
	RETURN number
	IS
	    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	BEGIN
	    IF x_org_code IS NULL THEN
		dbg_med('Organization Code can not be Null ');
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Organization Code can not be Null'
			 ,p_record_identifier_1 => p_rec_number
			 ,p_record_identifier_2 => x_org_code
			 ,p_record_identifier_3 => p_assembly_item_number
			);

		RETURN x_error_code;
	    ELSE
	     BEGIN
	       SELECT mp.organization_id
		 INTO x_invorg_id
		 FROM mtl_parameters mp
		WHERE mp.organization_code = x_org_code;
		RETURN  x_error_code;
	     EXCEPTION
	       WHEN no_data_found THEN
		  dbg_med('Organization Code does not exist(RTG_HDR) ');
		  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Organization Code does not exist(RTG_HDR)'
			 ,p_record_identifier_1 => p_rec_number
			 ,p_record_identifier_2 => x_org_code
			 ,p_record_identifier_3 => p_assembly_item_number
			);
		  RETURN  x_error_code;
	       WHEN OTHERS THEN
		  dbg_med('Unexpected error while validating the Organization Code(RTG_HDR)');
		  x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
		  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Unexpected error while validating the Organization Code(RTG_HDR)'
			 ,p_record_identifier_1 => p_rec_number
			 ,p_record_identifier_2 => x_org_code
			 ,p_record_identifier_3 => p_assembly_item_number
			);
		  RETURN  x_error_code;
	     END;
	    END IF;
	END;

	-------------------------------- Validate Item Number --------------------------------
	FUNCTION is_assembly_item_number_valid(p_rec_number NUMBER,p_org_code VARCHAR2,x_assembly_item_number VARCHAR2)
        RETURN number
        IS
           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
            IF x_assembly_item_number IS NULL THEN
                dbg_med('Item Number can not be Null(RTG_HDR) ');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Item Number can not be Null(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );

		RETURN x_error_code;
            ELSE
            ---
             BEGIN
               SELECT a.inventory_item_id
                 INTO x_item_id
                 FROM mtl_system_items_b a
                WHERE a.segment1 = x_assembly_item_number
                     AND a.organization_id = x_invorg_id
                     AND a.bom_enabled_flag = 'Y'
                     AND a.enabled_flag = 'Y';
                RETURN  x_error_code;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  dbg_med('Invalid Item Number(RTG_HDR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid Item Number(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing Item Number(RTG_HDR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing Item Number(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );
                  RETURN  x_error_code;
             END;
            END IF;
        END;

	-- is_eng_item_valid
  FUNCTION is_eng_item_valid(p_rec_number NUMBER,p_org_code VARCHAR2,p_assembly_item_number VARCHAR2, p_rtg_type in NUMBER)
        RETURN number
        IS
            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
            x_eng_item_flag VARCHAR2(1) := NULL;
        BEGIN

          SELECT eng_item_flag
                  INTO x_eng_item_flag
               FROM mtl_system_items_b
               WHERE segment1 = p_assembly_item_number
                 AND organization_id = x_invorg_id;

            IF UPPER(TRIM(x_eng_item_flag))= 'Y' and p_rtg_type <> 2 THEN
                   dbg_med('Item Is an Enginnering Item '||p_assembly_item_number|| '(RTG_HDR)');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Item Is an Enginnering Item(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                   RETURN x_error_code;
            END IF;
		        RETURN x_error_code;
          EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   dbg_med('Enginnering Item Flag does not exist (RTG_HDR)');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Enginnering Item Flag does not exist(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                   RETURN x_error_code;

               WHEN OTHERS THEN
                  dbg_med(' Unexpected error while validating the Enginnering Item(RTG_HDR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Enginnering Item(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;
        END is_eng_item_valid;


  -------------------------------- Validate Completion Subinventory --------------------------------
	FUNCTION is_subinv_valid(p_rec_number NUMBER,p_org_code VARCHAR2,p_assembly_item_number VARCHAR2,x_subinv VARCHAR2)
        RETURN number
        IS
            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

        BEGIN
            IF x_subinv IS NOT NULL THEN
             BEGIN
		 SELECT 1
		   INTO x_subinv_chk
		   FROM mtl_secondary_inventories
		  WHERE secondary_inventory_name = x_subinv
		    AND organization_id = x_invorg_id;

		  RETURN x_error_code;
             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   dbg_med('Completion Subinventory does not exist (RTG_HDR)');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Completion Subinventory does not exist(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                   RETURN x_error_code;

               WHEN OTHERS THEN
                  dbg_med(' Unexpected error while validating the Completion Subinventory(RTG_HDR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Completion Subinventory(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                    RETURN x_error_code;
             END;
            ELSE
                  dbg_med('Completion Subinventory is NULL (RTG_HDR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Completion Subinventory is NULL(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                    return x_error_code;
            END IF;
        END;

	-------------------------------- Validate Completion Locator Id --------------------------------
	FUNCTION is_locator_valid(p_rec_number NUMBER,p_org_code VARCHAR2,p_assembly_item_number VARCHAR2,x_subinv VARCHAR2, x_locator VARCHAR2)
        RETURN number
        IS
            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

           BEGIN
            IF x_locator IS NOT NULL THEN
             BEGIN
		SELECT 1
		  INTO x_locator_chk
		  FROM mtl_item_locations_kfv
		 WHERE 1=1
		   --AND inventory_location_id = x_locator /* commented during MOCK*/
		   AND concatenated_segments = x_locator /*'FG01.001.001'  added during MOCK*/
		   AND subinventory_code = x_subinv
		   AND organization_id = x_invorg_id;

		RETURN x_error_code;
             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   dbg_med('Completion Locator does not exist (RTG_HDR)');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Completion Locator does not exist(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                   RETURN x_error_code;

               WHEN OTHERS THEN
                  dbg_med(' Unexpected error while validating the Completion Locator(RTG_HDR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Completion Locator Id(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;
             END;
            ELSE
                  dbg_med('Resource Code is NULL ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Completion Locator Id is NULL(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;
            END IF;
        END;
        --Added as per Wave2
	-------------------------------- Validate Completion Locator Id --------------------------------
	FUNCTION is_cfm_rtng_flag_valid(p_rec_number           NUMBER
	                               ,p_org_code             VARCHAR2
	                               ,p_assembly_item_number VARCHAR2
	                               ,p_cfm_rtng_flag        VARCHAR2
	                               ,p_subinv               VARCHAR2
	                               ,p_locator              VARCHAR2 )
        RETURN number
        IS
           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

        BEGIN

           IF p_cfm_rtng_flag = 3 THEN
              IF p_subinv IS NULL OR p_locator IS NULL THEN
                 dbg_med('Completion Locator OR Completion Subinventory is NULL(RTG_HDR)');
                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                 xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Completion Locator OR Completion Subinventory is NULL(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;
               END IF;
            END IF;
            RETURN x_error_code;
        EXCEPTION
           WHEN OTHERS THEN
	      dbg_med(' Unexpected error while validating the Completion Locator OR Completion Subinventory');
	      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
	                            ,p_category    => xx_emf_cn_pkg.CN_VALID
	                            ,p_error_text  => 'Unexpected error while validating Completion Locator OR Completion Subinventory(RTG_HDR)'
	                            ,p_record_identifier_1 => p_rec_number
	                            ,p_record_identifier_2 => p_org_code
	                            ,p_record_identifier_3 => p_assembly_item_number
	                           );
              RETURN x_error_code;
        END is_cfm_rtng_flag_valid;

    BEGIN
	g_api_name := 'xx_itemrtg_validation';
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations for Routing Header');
	x_error_code_temp := is_org_code_valid(csr_itemrtg_print_rec.record_number,
				  csr_itemrtg_print_rec.organization_code,
				  csr_itemrtg_print_rec.assembly_item_number
					      );
	x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

	x_error_code_temp := is_assembly_item_number_valid(csr_itemrtg_print_rec.record_number,
				  csr_itemrtg_print_rec.organization_code,
				  csr_itemrtg_print_rec.assembly_item_number
					      );
	x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

  -- Addeed after MOCK CONVERSION 03-MAR-2013 -- Check for engineering item

  x_error_code_temp := is_eng_item_valid(csr_itemrtg_print_rec.record_number,
				  csr_itemrtg_print_rec.organization_code,
				  csr_itemrtg_print_rec.assembly_item_number,
          csr_itemrtg_print_rec.routing_type
					      );
	x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

  -- Addeed after MOCK CONVERSION 03-MAR-2013 END

	x_error_code_temp := is_subinv_valid(csr_itemrtg_print_rec.record_number,
				  csr_itemrtg_print_rec.organization_code,
				  csr_itemrtg_print_rec.assembly_item_number,
				  csr_itemrtg_print_rec.completion_subinventory
					      );
	x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

	x_error_code_temp := is_locator_valid(csr_itemrtg_print_rec.record_number,
				  csr_itemrtg_print_rec.organization_code,
				  csr_itemrtg_print_rec.assembly_item_number,
				  csr_itemrtg_print_rec.completion_subinventory,
				  csr_itemrtg_print_rec.completion_locator
					      );
	x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);
	--Added as per Wave2
	x_error_code_temp := is_cfm_rtng_flag_valid(csr_itemrtg_print_rec.record_number,
				  csr_itemrtg_print_rec.organization_code,
				  csr_itemrtg_print_rec.assembly_item_number,
				  csr_itemrtg_print_rec.cfm_routing_flag,
				  csr_itemrtg_print_rec.completion_subinventory,
				  csr_itemrtg_print_rec.completion_locator
					      );
	x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

	xx_emf_pkg.propagate_error (x_error_code_temp);

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
    END xx_itemrtg_validation;

    --**********************************************************************
    --	Function to validate the Routing Operations Sequence data
    --**********************************************************************

    FUNCTION xx_rtgop_validation(csr_rtgop_print_rec IN OUT xx_bom_rtg_cnv_pkg.G_XX_OP_SEQ_STG_REC_TYPE
                          ) RETURN NUMBER
    IS

	x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	x_invorg_id          NUMBER := NULL;
	x_item_id            NUMBER := NULL;
	x_num_dept_id        NUMBER := NULL;
	x_num_res_id         NUMBER := NULL;

	-------------------------------- Validate Organization Code --------------------------------
	FUNCTION is_org_code_valid(p_rec_number NUMBER,x_org_code VARCHAR2,p_assembly_item_number VARCHAR2)
	RETURN number
	IS
	    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	BEGIN
	    IF x_org_code IS NULL THEN
		dbg_med('Organization Code can not be Null (RTG_OPR)');
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Organization Code can not be Null(RTG_OPR)'
			 ,p_record_identifier_1 => p_rec_number
			 ,p_record_identifier_2 => x_org_code
			 ,p_record_identifier_3 => p_assembly_item_number
			);

		RETURN x_error_code;
	    ELSE
	     BEGIN
	       SELECT mp.organization_id
		 INTO x_invorg_id
		 FROM mtl_parameters mp
		WHERE mp.organization_code = x_org_code;
		RETURN  x_error_code;
	     EXCEPTION
	       WHEN no_data_found THEN
		  dbg_med('Organization Code does not exist (RTG_OPR)');
		  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Organization Code does not exist(RTG_OPR)'
			 ,p_record_identifier_1 => p_rec_number
			 ,p_record_identifier_2 => x_org_code
			 ,p_record_identifier_3 => p_assembly_item_number
			);
		  RETURN  x_error_code;
	       WHEN OTHERS THEN
		  dbg_med('Unexpected error while validating the Organization Code(RTG_OPR)');
		  x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
		  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Unexpected error while validating the Organization Code(RTG_OPR)'
			 ,p_record_identifier_1 => p_rec_number
			 ,p_record_identifier_2 => x_org_code
			 ,p_record_identifier_3 => p_assembly_item_number
			);
		  RETURN  x_error_code;
	     END;
	    END IF;
	END;

	-------------------------------- Validate Item Number --------------------------------
	FUNCTION is_assembly_item_number_valid(p_rec_number NUMBER,p_org_code VARCHAR2,x_assembly_item_number VARCHAR2)
        RETURN number
        IS
           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
            IF x_assembly_item_number IS NULL THEN
                dbg_med('Item Number can not be Null (RTG_OPR)');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Item Number can not be Null(RTG_OPR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );

		RETURN x_error_code;
            ELSE
            ---
             BEGIN
               SELECT a.inventory_item_id
                 INTO x_item_id
                 FROM mtl_system_items_b a
                WHERE a.segment1 = x_assembly_item_number
                     AND a.organization_id = x_invorg_id
                     AND a.bom_enabled_flag = 'Y'
                     AND a.enabled_flag = 'Y';
                RETURN  x_error_code;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  dbg_med('Invalid Item Number');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid Item Number(RTG_OPR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing Item Number(RTG_OPR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing Item Number(RTG_OPR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );
                  RETURN  x_error_code;
             END;
            END IF;
        END;

	-------------------------------- Validate Department Code --------------------------------
	FUNCTION is_dept_code_valid(p_rec_number NUMBER,p_org_code VARCHAR2,p_assembly_item_number VARCHAR2,x_department_code VARCHAR2)
        RETURN number
        IS
            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

        BEGIN
            IF x_department_code IS NOT NULL THEN
             BEGIN
		  SELECT department_id
                    INTO x_num_dept_id
                    FROM bom_departments
                   WHERE department_code = x_department_code
                     AND organization_id = x_invorg_id;

		  RETURN x_error_code;
             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   dbg_med('Department Code does not exist (RTG_OPR)');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Department Code does not exist(RTG_OPR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                   RETURN x_error_code;

               WHEN OTHERS THEN
                  dbg_med(' Unexpected error while validating the Department Code(RTG_OPR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Department Code(RTG_OPR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                    RETURN x_error_code;
             END;
            ELSE
                  dbg_med('Department Code is NULL (RTG_OPR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Department Code is NULL(RTG_OPR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                    return x_error_code;
            END IF;
        END;

    BEGIN
	g_api_name := 'xx_rtgop_validation';
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations for Routing Operation Sequence');
	x_error_code_temp := is_org_code_valid(csr_rtgop_print_rec.record_number,
				  csr_rtgop_print_rec.organization_code,
				  csr_rtgop_print_rec.assembly_item_number
					      );
	x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

	x_error_code_temp := is_assembly_item_number_valid(csr_rtgop_print_rec.record_number,
				  csr_rtgop_print_rec.organization_code,
				  csr_rtgop_print_rec.assembly_item_number
					      );
	x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

	x_error_code_temp := is_dept_code_valid(csr_rtgop_print_rec.record_number,
				  csr_rtgop_print_rec.organization_code,
				  csr_rtgop_print_rec.assembly_item_number,
				  csr_rtgop_print_rec.department_code
					      );
	x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

	xx_emf_pkg.propagate_error (x_error_code_temp);

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
    END xx_rtgop_validation;

   --Added as per Wave2 for operation network
    --**********************************************************************
    --	Function to validate the Routing Operation Networks data
    --**********************************************************************

    FUNCTION xx_rtgntwrk_validation(csr_rtgntwrk_print_rec IN OUT xx_bom_rtg_cnv_pkg.G_XX_OP_NTWRK_STG_REC_TYPE
                          ) RETURN NUMBER
    IS

	x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	x_invorg_id          NUMBER := NULL;
	x_item_id            NUMBER := NULL;
	x_num_dept_id        NUMBER := NULL;
	x_num_res_id         NUMBER := NULL;

	-------------------------------- Validate Organization Code --------------------------------
	FUNCTION is_org_code_valid( p_rec_number NUMBER
	                           ,p_org_code VARCHAR2
	                           ,p_assembly_item_number VARCHAR2
	                           ,p_org_id   OUT NUMBER)
	RETURN number
	IS
	    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	BEGIN
	    x_invorg_id := NULL;
	    IF p_org_code IS NULL THEN
		dbg_med('Organization Code can not be Null (RTG_NTWRK)');
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Organization Code can not be Null(RTG_NTWRK)'
			 ,p_record_identifier_1 => p_rec_number
			 ,p_record_identifier_2 => p_org_code
			 ,p_record_identifier_3 => p_assembly_item_number
			);

		RETURN x_error_code;
	    ELSE
	     BEGIN
	       SELECT mp.organization_id
		 INTO x_invorg_id
		 FROM mtl_parameters mp
		WHERE mp.organization_code = p_org_code;

		p_org_id := x_invorg_id;
		RETURN  x_error_code;
	     EXCEPTION
	       WHEN no_data_found THEN
		  dbg_med('Organization Code does not exist (RTG_NTWRK)');
		  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Organization Code does not exist(RTG_NTWRK)'
			 ,p_record_identifier_1 => p_rec_number
			 ,p_record_identifier_2 => p_org_code
			 ,p_record_identifier_3 => p_assembly_item_number
			);
		  RETURN  x_error_code;
	       WHEN OTHERS THEN
		  dbg_med('Unexpected error while validating the Organization Code(RTG_NTWRK)');
		  x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
		  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Unexpected error while validating the Organization Code(RTG_NTWRK)'
			 ,p_record_identifier_1 => p_rec_number
			 ,p_record_identifier_2 => p_org_code
			 ,p_record_identifier_3 => p_assembly_item_number
			);
		  RETURN  x_error_code;
	     END;
	    END IF;
	    p_org_id := x_invorg_id;
	    RETURN  x_error_code;
	EXCEPTION
	 WHEN OTHERS THEN
			  dbg_med('Unexpected error while validating the Organization Code(RTG_NTWRK)');
			  x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
			  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
				 ,p_category    => xx_emf_cn_pkg.CN_VALID
				 ,p_error_text  => 'Unexpected error while validating the Organization Code(RTG_NTWRK)'
				 ,p_record_identifier_1 => p_rec_number
				 ,p_record_identifier_2 => p_org_code
				 ,p_record_identifier_3 => p_assembly_item_number
				);
		  RETURN  x_error_code;
	END is_org_code_valid;

	-------------------------------- Validate Item Number --------------------------------
	FUNCTION is_assembly_item_number_valid(p_rec_number NUMBER
	                                      ,p_org_code VARCHAR2
	                                      ,p_assembly_item_number VARCHAR2
	                                      ,p_assembly_item_id OUT NUMBER)
        RETURN number
        IS
           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
            x_item_id := NULL;
            IF p_assembly_item_number IS NULL THEN
                dbg_med('Item Number can not be Null (RTG_NTWRK)');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Item Number can not be Null(RTG_NTWRK)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );

		RETURN x_error_code;
            ELSE
            ---
             BEGIN
               SELECT a.inventory_item_id
                 INTO x_item_id
                 FROM mtl_system_items_b a
                WHERE a.segment1 = p_assembly_item_number
                     AND a.organization_id = x_invorg_id
                     AND a.bom_enabled_flag = 'Y'
                     AND a.enabled_flag = 'Y';

                p_assembly_item_id := x_item_id;
                RETURN  x_error_code;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  dbg_med('Invalid Item Number');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid Item Number(RTG_NTWRK)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing Item Number(RTG_NTWRK)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing Item Number(RTG_NTWRK)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN  x_error_code;
             END;
            END IF;
            p_assembly_item_id := x_item_id;
            RETURN  x_error_code;
        EXCEPTION
        WHEN OTHERS THEN
	                  dbg_med('Unexpected error while validaing Item Number(RTG_NTWRK)');
	                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
	                         ,p_category    => xx_emf_cn_pkg.CN_VALID
	                         ,p_error_text  => 'Unexpected error while validaing Item Number(RTG_NTWRK)'
	                         ,p_record_identifier_1 => p_rec_number
	                         ,p_record_identifier_2 => p_org_code
	                         ,p_record_identifier_3 => p_assembly_item_number
	                        );
                  RETURN  x_error_code;
        END is_assembly_item_number_valid;

    BEGIN
	g_api_name := 'xx_rtgntwrk_validation';
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations for Routing Operation Network');
	x_error_code_temp := is_org_code_valid(csr_rtgntwrk_print_rec.record_number,
				  csr_rtgntwrk_print_rec.organization_code,
				  csr_rtgntwrk_print_rec.assembly_item_number,
				  csr_rtgntwrk_print_rec.organization_id
					      );
	x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

	x_error_code_temp := is_assembly_item_number_valid(csr_rtgntwrk_print_rec.record_number,
				  csr_rtgntwrk_print_rec.organization_code,
				  csr_rtgntwrk_print_rec.assembly_item_number,
				  csr_rtgntwrk_print_rec.assembly_item_id
					      );
	x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

	xx_emf_pkg.propagate_error (x_error_code_temp);

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
    END xx_rtgntwrk_validation;

--**********************************************************************
--  Function for Derivations for network
--**********************************************************************
   FUNCTION data_derivations_rtgntwrk (
      p_rtgntwrk_print_rec IN OUT xx_bom_rtg_cnv_pkg.G_XX_OP_NTWRK_STG_REC_TYPE
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      g_api_name := 'data_derivations';
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
   END data_derivations_rtgntwrk;

    --**********************************************************************
    --	Function to validate the Routing Operation Resources data
    --**********************************************************************

    FUNCTION xx_rtgres_validation(csr_rtgres_print_rec IN OUT xx_bom_rtg_cnv_pkg.G_XX_OP_RES_STG_REC_TYPE
                          ) RETURN NUMBER
    IS

	x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	x_invorg_id          NUMBER := NULL;
	x_item_id            NUMBER := NULL;
	x_num_res_id         NUMBER := NULL;
  x_cost_code_type     NUMBER := NULL;
	-------------------------------- Validate Organization Code --------------------------------
	FUNCTION is_org_code_valid(p_rec_number NUMBER,x_org_code VARCHAR2,p_assembly_item_number VARCHAR2)
	RETURN number
	IS
	    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	BEGIN
	    IF x_org_code IS NULL THEN
		dbg_med('Organization Code can not be Null (RTG_RES)');
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Organization Code can not be Null(RTG_RES)'
			 ,p_record_identifier_1 => p_rec_number
			 ,p_record_identifier_2 => x_org_code
			 ,p_record_identifier_3 => p_assembly_item_number
			);

		RETURN x_error_code;
	    ELSE
	     BEGIN
	       SELECT mp.organization_id
		 INTO x_invorg_id
		 FROM mtl_parameters mp
		WHERE mp.organization_code = x_org_code;
		RETURN  x_error_code;
	     EXCEPTION
	       WHEN no_data_found THEN
		  dbg_med('Organization Code does not exist(RTG_RES) ');
		  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Organization Code does not exist(RTG_RES)'
			 ,p_record_identifier_1 => p_rec_number
			 ,p_record_identifier_2 => x_org_code
			 ,p_record_identifier_3 => p_assembly_item_number
			);
		  RETURN  x_error_code;
	       WHEN OTHERS THEN
		  dbg_med('Unexpected error while validating the Organization Code(RTG_RES)');
		  x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
		  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Unexpected error while validating the Organization Code(RTG_RES)'
			 ,p_record_identifier_1 => p_rec_number
			 ,p_record_identifier_2 => x_org_code
			 ,p_record_identifier_3 => p_assembly_item_number
			);
		  RETURN  x_error_code;
	     END;
	    END IF;
	END;

	-------------------------------- Validate Item Number --------------------------------
	FUNCTION is_assembly_item_number_valid(p_rec_number NUMBER,p_org_code VARCHAR2,x_assembly_item_number VARCHAR2)
        RETURN number
        IS
           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
            IF x_assembly_item_number IS NULL THEN
                dbg_med('Item Number can not be Null (RTG_RES)');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Item Number can not be Null(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );

		RETURN x_error_code;
            ELSE
            ---
             BEGIN
               SELECT a.inventory_item_id
                 INTO x_item_id
                 FROM mtl_system_items_b a
                WHERE a.segment1 = x_assembly_item_number
                     AND a.organization_id = x_invorg_id
                     AND a.bom_enabled_flag = 'Y'
                     AND a.enabled_flag = 'Y';
                RETURN  x_error_code;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  dbg_med('Invalid Item Number(RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid Item Number(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing Item Number(RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing Item Number(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );
                  RETURN  x_error_code;
             END;
            END IF;
        END;

	-------------------------------- Validate Resource Code --------------------------------
	FUNCTION is_resource_code_valid(p_rec_number NUMBER,p_org_code VARCHAR2,p_assembly_item_number VARCHAR2
                                  ,x_resource_code VARCHAR2,p_autocharge_type IN OUT NUMBER)
        RETURN number
        IS
            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
            x_autocharge_type NUMBER := 1;
           BEGIN
            IF x_resource_code IS NOT NULL THEN
             BEGIN
               -- new code change for UATW
		           SELECT resource_id,cost_code_type
                    INTO x_num_res_id,x_cost_code_type
                    FROM bom_resources
                   WHERE resource_code = x_resource_code
                     AND organization_id = x_invorg_id;

               IF x_cost_code_type =  4 THEN -- OSP resource
                  x_autocharge_type := 4;    -- PO Move
               ELSE
                  x_autocharge_type := 1;   -- Wip Move
               END IF;
               p_autocharge_type := x_autocharge_type;
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'p_autocharge_type :'||p_autocharge_type);
		          RETURN x_error_code;
             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   dbg_med('Resource Code does not exist (RTG_RES)');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Resource Code does not exist(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                   RETURN x_error_code;

               WHEN OTHERS THEN
                  dbg_med(' Unexpected error while validating the Resource Code(RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Resource Code(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;
             END;

            ELSE
                  dbg_med('Resource Code is NULL (RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Resource Code is NULL(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;
            END IF;
        EXCEPTION
          WHEN OTHERS THEN
                  dbg_med(' Unexpected error while validating the Resource Code(RTG_RES)---');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Resource Code(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;


        END;
      -- New change for UATW
      -- is_dept_res_code_valid
      FUNCTION is_dept_res_code_valid(p_rec_number NUMBER,p_org_code VARCHAR2,p_assembly_item_number VARCHAR2
                                  ,x_resource_code VARCHAR2,p_operation_seq_num  NUMBER)
        RETURN number
        IS
            x_error_code  NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
            x_dept_res_id NUMBER := NULL;
            x_dept_code   VARCHAR2(10) := NULL;
           BEGIN
             BEGIN
               -- new code change for UATW
		           SELECT bdr.department_id INTO x_dept_res_id
                  FROM BOM_DEPARTMENT_RESOURCES_V bdr
                       ,xx_bom_rtg_op_stg xbros
                       ,xx_bom_rtg_res_stg xbrrs
                  WHERE bdr.DEPARTMENT_ID = xbros.department_id
                  AND   bdr.resource_code = x_resource_code
                  AND    bdr.ORGANIZATION_ID = x_invorg_id
                  AND    xbros.assembly_item_number = xbrrs.assembly_item_number
                  AND    xbros.operation_seq_num = xbrrs.operation_seq_num
                  AND    xbros.organization_code = xbrrs.organization_code
                  AND    xbros.batch_id = xbrrs.batch_id
                  AND    xbrrs.batch_id = G_BATCH_ID
                  AND    xbrrs.operation_seq_num = p_operation_seq_num
                  AND    xbrrs.assembly_item_number = p_assembly_item_number
                  AND    ROWNUM = 1;

               IF x_dept_res_id is NULL THEN

                  begin
                    Select department_code into x_dept_code
                     from xx_bom_rtg_op_stg xbros
                      where assembly_item_number = p_assembly_item_number
                       and  operation_seq_num = p_operation_seq_num
                       and  organization_code = p_org_code
                       and  batch_id = G_BATCH_ID
                       and    ROWNUM = 1;
                   exception
                      when others then
                       x_dept_code := NULL;
                   end;

                  dbg_med('Resource Code: does not exist in Department: (RTG_RES)');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Resource Code: does not exist in Department: (RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 =>x_resource_code||'-'||x_dept_code
                        );
                   RETURN x_error_code;
               END IF;
		          RETURN x_error_code;
             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   begin
                    Select department_code into x_dept_code
                     from xx_bom_rtg_op_stg xbros
                      where assembly_item_number = p_assembly_item_number
                       and  operation_seq_num = p_operation_seq_num
                       and  organization_code = p_org_code
                       and  batch_id = G_BATCH_ID
                       and    ROWNUM = 1;
                   exception
                      when others then
                       x_dept_code := NULL;
                   end;
                   dbg_med('Resource Code:'||x_resource_code|| ':does not exist in Department: '||x_dept_code||' :(RTG_RES)');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Resource Code: does not exist in Department: (RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 =>x_resource_code||'-'||x_dept_code

                        );
                   RETURN x_error_code;

               WHEN OTHERS THEN
                  dbg_med(' Unexpected error while validating the Resource Code in Department(RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Resource Code in Department(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;
             END;

        EXCEPTION
          WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the Resource Code in Department(RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Resource Code in Department(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;


        END;

      -- is_basis_valid
      FUNCTION is_basis_valid(p_rec_number NUMBER,p_org_code VARCHAR2,p_assembly_item_number VARCHAR2
                                  ,x_resource_code VARCHAR2,p_basis_type NUMBER)
        RETURN number
        IS
            x_error_code  NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
            x_dept_res_id NUMBER := NULL;
           BEGIN
               -- new code change for UATW
               IF x_resource_code = 'LEADTIME' AND p_basis_type = 1  THEN
                  dbg_med('BASIS_TYPE should be LOT for resource_code LEADTIME(RTG_RES)');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'BASIS_TYPE should be LOT for resource_code LEADTIME(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                   RETURN x_error_code;
               END IF;
		          RETURN x_error_code;
             EXCEPTION
               WHEN OTHERS THEN
                  dbg_med('BASIS_TYPE should be LOT for resource_code LEADTIME(RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'BASIS_TYPE should be LOT for resource_code LEADTIME(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;
        END;

      -- is_osp_valid
      FUNCTION is_osp_valid(p_rec_number NUMBER,p_org_code VARCHAR2,p_assembly_item_number VARCHAR2)
        RETURN number
        IS
            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
            x_osp_flag   VARCHAR2(1) := NULL;
           BEGIN
            IF x_cost_code_type = 4 and x_invorg_id IS NOT NULL THEN
              BEGIN
                SELECT outside_operation_flag
                  INTO x_osp_flag
                FROM apps.mtl_system_items_b
                  WHERE organization_id = x_invorg_id
                    AND segment1 = p_assembly_item_number;

              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_osp_flag: '||x_osp_flag);

              IF upper(x_osp_flag) <> 'Y' THEN
                 dbg_med('Resource is OSP resource but item is not enabled as OSP (RTG_RES)');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Resource is OSP resource but item is not enabled as OSP (RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                   RETURN x_error_code;
               END IF;
		             RETURN x_error_code;
             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   dbg_med('Resource is OSP resource but item is not enabled as OSP (RTG_RES)');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Resource is OSP resource but item is not enabled as OSP (RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                   RETURN x_error_code;

               WHEN OTHERS THEN
                  dbg_med(' Unexpected error while validating the OSP resource(RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the OSP resource(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;
             END;
           END IF;
           RETURN x_error_code;
        EXCEPTION
          WHEN OTHERS THEN
                  dbg_med(' Unexpected error while validating the OSP resource(RTG_RES)---1');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the OSP resource(RTG_RES)--1'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;
        END;

      -- is UOM valid
      FUNCTION is_uom_valid(p_rec_number NUMBER,p_org_code VARCHAR2,p_assembly_item_number VARCHAR2,
                            p_resource_code VARCHAR2,p_usage_rate_or_amount NUMBER,p_schedule_flag IN OUT NUMBER)

        RETURN number
        IS
            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
            x_uom   VARCHAR2(10) := NULL;
           BEGIN
              BEGIN
                SELECT unit_of_measure
                  INTO x_uom
                FROM bom_resources
                  WHERE organization_id = x_invorg_id
                    AND resource_code = p_resource_code;

               IF upper(trim(x_uom)) = 'HR' AND NVL(p_usage_rate_or_amount,0) > 0 THEN
                  p_schedule_flag := 1;
               ELSE
                  p_schedule_flag := 2;
               END IF;
		             RETURN x_error_code;
             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   dbg_med('Unable to derive Resource UOM (RTG_RES)');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unable to derive Resource UOM (RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                   RETURN x_error_code;

               WHEN OTHERS THEN
                  dbg_med(' Unexpected error while deriving Resource UOM (RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => ' Unexpected error while deriving Resource UOM (RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;
             END;
        END;

      -- is_opr_seq_num_valid
      FUNCTION is_opr_seq_num_valid(p_rec_number NUMBER,p_org_code VARCHAR2,
                                    p_assembly_item_number VARCHAR2,p_opr_seq_num NUMBER)
        RETURN number
        IS
            x_error_code  NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
            x_opr_seq_num NUMBER := NULL;
           BEGIN
            IF p_opr_seq_num IS NOT NULL THEN
             BEGIN
		            SELECT operation_seq_num
                    INTO x_opr_seq_num
                    FROM xx_bom_rtg_op_stg
                   WHERE operation_seq_num     = p_opr_seq_num
                     AND organization_code     = p_org_code
                     AND assembly_item_number  = p_assembly_item_number
                     AND batch_id              = G_BATCH_ID;


		               RETURN x_error_code;
             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   dbg_med('operation_seq_num does not exist (RTG_RES)');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'operation_seq_num does not exist(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                   RETURN x_error_code;

               WHEN OTHERS THEN
                  dbg_med(' Unexpected error while validating the operation_seq_num(RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the operation_seq_num(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;
             END;
            ELSE
                  dbg_med('operation_seq_num is NULL (RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'operation_seq_num is NULL(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;
            END IF;
        END;

        -- is_res_seq_num_duplicate
        FUNCTION is_res_seq_num_duplicate(p_rec_number NUMBER,p_org_code VARCHAR2,
                                    p_assembly_item_number VARCHAR2,p_opr_seq_num NUMBER,
                                    p_res_seq_num NUMBER)
        RETURN number
        IS
            x_error_code  NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
            x_tot_res_seq_num NUMBER := NULL;
           BEGIN
            IF p_res_seq_num IS NOT NULL THEN
             BEGIN
		            SELECT count(1)
                    INTO x_tot_res_seq_num
                    FROM xx_bom_rtg_res_stg
                   WHERE operation_seq_num     = p_opr_seq_num
                     AND resource_seq_num      = p_res_seq_num
                     AND assembly_item_number  = p_assembly_item_number
                     AND organization_code     = p_org_code
                     AND batch_id              = G_BATCH_ID;

                 IF x_tot_res_seq_num >1 THEN
                   dbg_med('resource_seq_num duplicated for operation_seq_num(RTG_RES)');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'resource_seq_num duplicated for operation_seq_num(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                    RETURN x_error_code;
                  END IF;
                  RETURN x_error_code;
             EXCEPTION

               WHEN OTHERS THEN
                  dbg_med(' Unexpected error while validating the is_res_seq_num_duplicate(RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the is_res_seq_num_duplicate(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;
             END;
            ELSE
                  dbg_med('resource_seq_num is NULL (RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'resource_seq_num is NULL(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN x_error_code;
            END IF;
        END;



	BEGIN
	    g_api_name := 'xx_rtgres_validation';
	    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations for Routing Operation Resources');
	    x_error_code_temp := is_org_code_valid(csr_rtgres_print_rec.record_number,
                                      csr_rtgres_print_rec.organization_code,
                                      csr_rtgres_print_rec.assembly_item_number
		                                  );
	    x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

	    x_error_code_temp := is_assembly_item_number_valid(csr_rtgres_print_rec.record_number,
                                      csr_rtgres_print_rec.organization_code,
                                      csr_rtgres_print_rec.assembly_item_number
		                                  );
	    x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

	    x_error_code_temp := is_resource_code_valid(csr_rtgres_print_rec.record_number,
                                      csr_rtgres_print_rec.organization_code,
                                      csr_rtgres_print_rec.assembly_item_number,
				                              csr_rtgres_print_rec.resource_code,
                                      csr_rtgres_print_rec.autocharge_type
		                                  );
	    x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);
      -- New for UATW

      x_error_code_temp  := is_dept_res_code_valid(csr_rtgres_print_rec.record_number,
                                                  csr_rtgres_print_rec.organization_code,
                                                  csr_rtgres_print_rec.assembly_item_number,
                                                  csr_rtgres_print_rec.resource_code,
                                                  csr_rtgres_print_rec.operation_seq_num);
      x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

      x_error_code_temp  :=  is_basis_valid(csr_rtgres_print_rec.record_number,
                                            csr_rtgres_print_rec.organization_code,
                                            csr_rtgres_print_rec.assembly_item_number,
                                            csr_rtgres_print_rec.resource_code,
                                            csr_rtgres_print_rec.basis_type);
      x_error_code       := FIND_MAX ( x_error_code, x_error_code_temp);
      /*
      x_error_code_temp  := is_osp_valid(csr_rtgres_print_rec.record_number,
                                         csr_rtgres_print_rec.organization_code,
                                         csr_rtgres_print_rec.assembly_item_number);

      x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);
      */

      x_error_code_temp  := is_uom_valid(csr_rtgres_print_rec.record_number,
                                         csr_rtgres_print_rec.organization_code,
                                         csr_rtgres_print_rec.assembly_item_number,
                                         csr_rtgres_print_rec.resource_code,
                                         csr_rtgres_print_rec.usage_rate_or_amount,
                                         csr_rtgres_print_rec.schedule_flag);

      x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

      x_error_code_temp  := is_opr_seq_num_valid(csr_rtgres_print_rec.record_number,
                                                 csr_rtgres_print_rec.organization_code,
                                                 csr_rtgres_print_rec.assembly_item_number,
                                                 csr_rtgres_print_rec.operation_seq_num);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);
       x_error_code_temp  := is_res_seq_num_duplicate(csr_rtgres_print_rec.record_number,
                                                      csr_rtgres_print_rec.organization_code,
                                                      csr_rtgres_print_rec.assembly_item_number,
                                                      csr_rtgres_print_rec.operation_seq_num,
                                                      csr_rtgres_print_rec.resource_seq_num);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);
      xx_emf_pkg.propagate_error (x_error_code_temp);

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
    END xx_rtgres_validation;

    --**********************************************************************
    --  Function for Routing Header Data Derivations
    --**********************************************************************

    FUNCTION xx_itemrtg_data_derivations(csr_itemrtg_print_rec IN OUT xx_bom_rtg_cnv_pkg.G_XX_RTG_HDR_STG_REC_TYPE
                          )
     RETURN NUMBER
     IS
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_invorg_id          NUMBER := NULL;
      x_item_id            NUMBER := NULL;
      x_resource_id        NUMBER := NULL;
      x_rtg_seq_id         NUMBER := NULL;

	-------------------------------- Derive Organization Id --------------------------------
	FUNCTION get_org_id(p_rec_number NUMBER,x_org_code VARCHAR2,p_assembly_item_number VARCHAR2,p_org_id OUT NUMBER)
           RETURN NUMBER
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
	    dbg_med('Organization Code => '||x_org_code);

	   SELECT mp.organization_id
	     INTO x_invorg_id
	     FROM mtl_parameters mp
	    WHERE mp.organization_code = x_org_code;
	    p_org_id := x_invorg_id;

	    dbg_med('Organization ID => '||p_org_id);

	    RETURN  x_error_code;
        EXCEPTION
	    WHEN no_data_found THEN
	      dbg_med('Organization Code does not exist (RTG_HDR)');
	      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		     ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
		     ,p_error_text  => 'Organization Code does not exist(RTG_HDR)'
		     ,p_record_identifier_1 => p_rec_number
		     ,p_record_identifier_2 => x_org_code
		     ,p_record_identifier_3 => p_assembly_item_number
		    );
	      RETURN  x_error_code;
	    WHEN OTHERS THEN
	      dbg_med('Unexpected error while deriving the Organization Id(RTG_HDR)');
	      x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
	      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		     ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
		     ,p_error_text  => 'Unexpected error while deriving the Organization Id(RTG_HDR)'
		     ,p_record_identifier_1 => p_rec_number
		     ,p_record_identifier_2 => x_org_code
		     ,p_record_identifier_3 => p_assembly_item_number
		    );
	      RETURN  x_error_code;
        END get_org_id;

	-------------------------------- Derive Item Id --------------------------------
	FUNCTION get_item_id(p_rec_number NUMBER,p_org_code VARCHAR2,x_assembly_item_number VARCHAR2,p_inv_item_id OUT NUMBER)
           RETURN number
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
	    dbg_med('Assembly Item Number => '||x_assembly_item_number);
	   SELECT a.inventory_item_id
	     INTO x_item_id
	     FROM mtl_system_items_b a
	    WHERE a.segment1 = x_assembly_item_number
	      AND a.organization_id = x_invorg_id
	      AND a.bom_enabled_flag = 'Y'
	      AND a.enabled_flag = 'Y';
	    p_inv_item_id := x_item_id;

	    dbg_med('Assembly Item ID => '||p_inv_item_id);

	   RETURN  x_error_code;
        EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  dbg_med('Unable to derive Assembly Item id(RTG_HDR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unable to derive Assembly Item id(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while deriving Assembly Item id(RTG_HDR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving Assembly Item id(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );
                  RETURN  x_error_code;
        END get_item_id;

	-------------------------------- Derive Locator Id --------------------------------
	FUNCTION get_locator_id(p_rec_number NUMBER,p_org_code VARCHAR2,x_assembly_item_number VARCHAR2,
									x_locator VARCHAR2, x_subinv VARCHAR2,
									p_locator_id OUT NUMBER)
           RETURN number
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	     x_locator_id NUMBER;
        BEGIN
	    dbg_med('Completion Locator => '||x_locator);

	    SELECT inventory_location_id
	      INTO x_locator_id
	      FROM mtl_item_locations_kfv
	     WHERE 1=1
	       AND concatenated_segments = x_locator  /*'FG01.001.001'  added during MOCK*/
	       AND subinventory_code = x_subinv
	       AND organization_id = (select organization_id from mtl_parameters
					where organization_code = p_org_code);
	    p_locator_id := x_locator_id;

	    dbg_med('Completion Locator id=> '||p_locator_id);

	   RETURN  x_error_code;
        EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  dbg_med('Unable to derive Completion Locator id(RTG_HDR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unable to derive Completion Locator id(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while deriving Completion Locator id(RTG_HDR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving Completion Locator id(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );
                  RETURN  x_error_code;
        END get_locator_id;

	-------------------------------- Derive Routing Sequence Id --------------------------------
	FUNCTION get_rtg_seq_id(p_rec_number NUMBER,p_org_code VARCHAR2,p_assembly_item_number VARCHAR2,p_rtg_seq_id OUT NUMBER)
           RETURN number
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
	   SELECT a.routing_sequence_id
	     INTO x_rtg_seq_id
	     FROM bom_operational_routings a
	    WHERE a.assembly_item_id = x_item_id
	      AND a.organization_id = x_invorg_id;
	    p_rtg_seq_id := x_rtg_seq_id;
	   RETURN  x_error_code;
        EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  dbg_med('Unable to derive Routing Sequence id(RTG_HDR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unable to derive Routing Sequence id(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while deriving Routing Sequence id(RTG_HDR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving Routing Sequence id(RTG_HDR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN  x_error_code;
        END get_rtg_seq_id;

    BEGIN
	g_api_name := 'xx_itemrtg_data_derivations';
	--get the organization_id
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Routing Data-Derivations');
	x_error_code_temp := get_org_id (csr_itemrtg_print_rec.record_number,
                                          csr_itemrtg_print_rec.organization_code,
                                          csr_itemrtg_print_rec.assembly_item_number,
                                          csr_itemrtg_print_rec.organization_id
		                                      );

	x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );

	x_error_code_temp := get_item_id (csr_itemrtg_print_rec.record_number,
                                          csr_itemrtg_print_rec.organization_code,
                                          csr_itemrtg_print_rec.assembly_item_number,
                                          csr_itemrtg_print_rec.assembly_item_id
		                                      );

	x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );

	x_error_code_temp := get_locator_id (csr_itemrtg_print_rec.record_number,
                                          csr_itemrtg_print_rec.organization_code,
                                          csr_itemrtg_print_rec.assembly_item_number,
					  csr_itemrtg_print_rec.completion_locator,
                                          csr_itemrtg_print_rec.completion_subinventory,
					  csr_itemrtg_print_rec.completion_locator_id
		                                      );

	x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );

	IF G_TRANSACTION_TYPE = G_TRANS_TYPE_DELETE THEN
	    x_error_code_temp := get_rtg_seq_id (csr_itemrtg_print_rec.record_number,
						csr_itemrtg_print_rec.organization_code,
						csr_itemrtg_print_rec.assembly_item_number,
						csr_itemrtg_print_rec.routing_sequence_id
		                                      );

	    x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);
	END IF;

	xx_emf_pkg.propagate_error ( x_error_code_temp );

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
    END xx_itemrtg_data_derivations;


    --**********************************************************************
    --  Function for Routing Operation Sequence Data Derivations
    --**********************************************************************

    FUNCTION xx_rtgop_data_derivations(csr_rtgop_print_rec IN OUT xx_bom_rtg_cnv_pkg.G_XX_OP_SEQ_STG_REC_TYPE
                          )
     RETURN NUMBER
     IS
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_invorg_id          NUMBER := NULL;
      x_item_id            NUMBER := NULL;
      x_dept_id            NUMBER := NULL;
      x_rtg_seq_id         NUMBER := NULL;
      x_opr_seq_id         NUMBER := NULL;

	-------------------------------- Derive Organization Id --------------------------------
	FUNCTION get_org_id(p_rec_number NUMBER,x_org_code VARCHAR2,p_assembly_item_number VARCHAR2,p_org_id OUT NUMBER)
           RETURN NUMBER
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
	   SELECT mp.organization_id
	     INTO x_invorg_id
	     FROM mtl_parameters mp
	    WHERE mp.organization_code = x_org_code;
	    p_org_id := x_invorg_id;
	    RETURN  x_error_code;
        EXCEPTION
	    WHEN no_data_found THEN
	      dbg_med('Organization Code does not exist (RTG_OPR)');
	      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		     ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
		     ,p_error_text  => 'Organization Code does not exist'
		     ,p_record_identifier_1 => p_rec_number
		     ,p_record_identifier_2 => x_org_code
		     ,p_record_identifier_3 => p_assembly_item_number
		    );
	      RETURN  x_error_code;
	    WHEN OTHERS THEN
	      dbg_med('Unexpected error while deriving the Organization Id(RTG_OPR)');
	      x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
	      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		     ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
		     ,p_error_text  => 'Unexpected error while deriving the Organization Id(RTG_OPR)'
		     ,p_record_identifier_1 => p_rec_number
		     ,p_record_identifier_2 => x_org_code
		     ,p_record_identifier_3 => p_assembly_item_number
		    );
	      RETURN  x_error_code;
        END get_org_id;

	-------------------------------- Derive Item Id --------------------------------
	FUNCTION get_item_id(p_rec_number NUMBER,p_org_code VARCHAR2,x_assembly_item_number VARCHAR2,p_inv_item_id OUT NUMBER)
           RETURN number
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
	   SELECT a.inventory_item_id
	     INTO x_item_id
	     FROM mtl_system_items_b a
	    WHERE a.segment1 = x_assembly_item_number
	      AND a.organization_id = x_invorg_id
	      AND a.bom_enabled_flag = 'Y'
	      AND a.enabled_flag = 'Y';
	    p_inv_item_id := x_item_id;
	   RETURN  x_error_code;
        EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  dbg_med('Unable to derive Assembly Item id(RTG_OPR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unable to derive Assembly Item id(RTG_OPR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while deriving Assembly Item id(RTG_OPR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving Assembly Item id(RTG_OPR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );
                  RETURN  x_error_code;
        END get_item_id;

	-------------------------------- Derive Department Id --------------------------------
        FUNCTION get_department_id(p_rec_number NUMBER,x_org_code VARCHAR2,p_assembly_item_number VARCHAR2,x_dept_code VARCHAR2,p_dept_id OUT NUMBER)
           RETURN number
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
	   SELECT   department_id
             INTO   x_dept_id
             FROM   bom_departments bd
	           ,org_organization_definitions  ood
            WHERE   bd.organization_id    = ood.organization_id
	      AND   bd.department_code    = x_dept_code
              AND   ood.organization_code = x_org_code;
           p_dept_id :=  x_dept_id;
           RETURN x_error_code;
        EXCEPTION
	    WHEN NO_DATA_FOUND THEN
	       dbg_med('Unable to derive Department Id (RTG_OPR)');
	       x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		     ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
		     ,p_error_text  => 'Unable to derive Department Id (RTG_OPR)'
		     ,p_record_identifier_1 => p_rec_number
		     ,p_record_identifier_2 => x_org_code
		     ,p_record_identifier_3 => p_assembly_item_number
		    );
	       RETURN x_error_code;

	    WHEN OTHERS THEN
	       dbg_med(' Unexpected error while deriving the Department Id (RTG_OPR)');
	       x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		     ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
		     ,p_error_text  => 'Unexpected error while deriving the Department Id (RTG_OPR)'
		     ,p_record_identifier_1 => p_rec_number
		     ,p_record_identifier_2 => x_org_code
		     ,p_record_identifier_3 => p_assembly_item_number
		    );
	       RETURN x_error_code;
        END get_department_id;

	-------------------------------- Derive Routing / Operation Sequence Id --------------------------------
	FUNCTION get_rtg_seq_id(p_rec_number NUMBER,p_org_code VARCHAR2,p_assembly_item_number VARCHAR2
									    ,p_rtg_seq_id OUT NUMBER,p_opr_seq_id OUT NUMBER)
           RETURN number
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
	   SELECT b.routing_sequence_id, b.operation_sequence_id
	     INTO x_rtg_seq_id, x_opr_seq_id
	     FROM bom_operational_routings a, bom_operation_sequences b
	    WHERE a.assembly_item_id = x_item_id
	      AND a.organization_id = x_invorg_id
	      AND a.routing_sequence_id = b.routing_sequence_id(+);
	    p_rtg_seq_id := x_rtg_seq_id;
	    p_opr_seq_id := x_opr_seq_id;
	   RETURN  x_error_code;
        EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  dbg_med('Unable to derive Routing / Operation Sequence id(RTG_OPR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unable to derive Routing / Operation Sequence id(RTG_OPR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while deriving Routing / Operation Sequence id(RTG_OPR)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving Routing / Operation Sequence id(RTG_OPR)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN  x_error_code;
        END get_rtg_seq_id;

    BEGIN
	g_api_name := 'xx_rtgop_data_derivations';
	--get the organization_id
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Operations Data-Derivations');
	x_error_code_temp := get_org_id (csr_rtgop_print_rec.record_number,
                                          csr_rtgop_print_rec.organization_code,
                                          csr_rtgop_print_rec.assembly_item_number,
                                          csr_rtgop_print_rec.organization_id
		                                      );

	x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );

	x_error_code_temp := get_item_id (csr_rtgop_print_rec.record_number,
                                          csr_rtgop_print_rec.organization_code,
                                          csr_rtgop_print_rec.assembly_item_number,
                                          csr_rtgop_print_rec.assembly_item_id
		                                      );

	x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );

	x_error_code_temp := get_department_id (csr_rtgop_print_rec.record_number,
                                             csr_rtgop_print_rec.organization_code,
                                             csr_rtgop_print_rec.assembly_item_number,
                                             csr_rtgop_print_rec.department_code,
                                             csr_rtgop_print_rec.department_id
		                                      );

	/*IF G_TRANSACTION_TYPE = G_TRANS_TYPE_DELETE THEN
	    x_error_code_temp := get_rtg_seq_id (csr_rtgop_print_rec.record_number,
						csr_rtgop_print_rec.organization_code,
						csr_rtgop_print_rec.assembly_item_number,
						csr_rtgop_print_rec.routing_sequence_id,
						csr_rtgop_print_rec.operation_sequence_id
		                                      );

	    x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);
	END IF;	*/

	x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );

	xx_emf_pkg.propagate_error ( x_error_code_temp );

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
    END xx_rtgop_data_derivations;

    --**********************************************************************
    --  Function for Routing Operation Resources Data Derivations
    --**********************************************************************

    FUNCTION xx_rtgres_data_derivations(csr_rtgres_print_rec IN OUT xx_bom_rtg_cnv_pkg.G_XX_OP_RES_STG_REC_TYPE
                          )
     RETURN NUMBER
     IS
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_invorg_id          NUMBER := NULL;
      x_item_id            NUMBER := NULL;
      x_resource_id        NUMBER := NULL;
      x_opr_seq_id	   NUMBER := NULL;

	-------------------------------- Derive Organization Id --------------------------------
	FUNCTION get_org_id(p_rec_number NUMBER,x_org_code VARCHAR2,p_assembly_item_number VARCHAR2,p_org_id OUT NUMBER)
           RETURN NUMBER
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
	   SELECT mp.organization_id
	     INTO x_invorg_id
	     FROM mtl_parameters mp
	    WHERE mp.organization_code = x_org_code;
	    p_org_id := x_invorg_id;
	    RETURN  x_error_code;
        EXCEPTION
	    WHEN no_data_found THEN
	      dbg_med('Organization Code does not exist (RTG_RES)');
	      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		     ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
		     ,p_error_text  => 'Organization Code does not exist(RTG_RES)'
		     ,p_record_identifier_1 => p_rec_number
		     ,p_record_identifier_2 => x_org_code
		     ,p_record_identifier_3 => p_assembly_item_number
		    );
	      RETURN  x_error_code;
	    WHEN OTHERS THEN
	      dbg_med('Unexpected error while deriving the Organization Id(RTG_RES)');
	      x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
	      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		     ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
		     ,p_error_text  => 'Unexpected error while deriving the Organization Id(RTG_RES)'
		     ,p_record_identifier_1 => p_rec_number
		     ,p_record_identifier_2 => x_org_code
		     ,p_record_identifier_3 => p_assembly_item_number
		    );
	      RETURN  x_error_code;
        END get_org_id;

	-------------------------------- Derive Item Id --------------------------------
	FUNCTION get_item_id(p_rec_number NUMBER,p_org_code VARCHAR2,x_assembly_item_number VARCHAR2,p_inv_item_id OUT NUMBER)
           RETURN number
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
	   SELECT a.inventory_item_id
	     INTO x_item_id
	     FROM mtl_system_items_b a
	    WHERE a.segment1 = x_assembly_item_number
	      AND a.organization_id = x_invorg_id
	      AND a.bom_enabled_flag = 'Y'
	      AND a.enabled_flag = 'Y';
	    p_inv_item_id := x_item_id;
	   RETURN  x_error_code;
        EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  dbg_med('Unable to derive Assembly Item id(RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unable to derive Assembly Item id(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while deriving Assembly Item id(RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving Assembly Item id(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => x_assembly_item_number
                        );
                  RETURN  x_error_code;
        END get_item_id;

	-------------------------------- Derive Resource Id --------------------------------
        FUNCTION get_resource_id(p_rec_number NUMBER,x_org_code VARCHAR2,p_assembly_item_number VARCHAR2,x_resource_code VARCHAR2,p_resource_id OUT NUMBER)
           RETURN number
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
	   SELECT   resource_id
             INTO   x_resource_id
             FROM   bom_resources br
	           ,org_organization_definitions  ood
            WHERE   br.organization_id    = ood.organization_id
	      AND   br.resource_code      = x_resource_code
              AND   ood.organization_code = x_org_code;
           p_resource_id :=  x_resource_id;
           RETURN x_error_code;
        EXCEPTION
	    WHEN NO_DATA_FOUND THEN
	       dbg_med('Unable to derive Resource Id (RTG_RES)');
	       x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		     ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
		     ,p_error_text  => 'Unable to derive Resource Id (RTG_RES)'
		     ,p_record_identifier_1 => p_rec_number
		     ,p_record_identifier_2 => x_org_code
		     ,p_record_identifier_3 => p_assembly_item_number
		    );
	       RETURN x_error_code;

	    WHEN OTHERS THEN
	       dbg_med(' Unexpected error while deriving the Resource Id (RTG_RES)');
	       x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		     ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
		     ,p_error_text  => 'Unexpected error while deriving the Resource Id (RTG_RES)'
		     ,p_record_identifier_1 => p_rec_number
		     ,p_record_identifier_2 => x_org_code
		     ,p_record_identifier_3 => p_assembly_item_number
		    );
	       RETURN x_error_code;
        END get_resource_id;

	-------------------------------- Derive Operation Sequence Id --------------------------------
	FUNCTION get_opr_seq_id(p_rec_number NUMBER,p_org_code VARCHAR2,p_assembly_item_number VARCHAR2,p_opr_seq_id OUT NUMBER)
           RETURN number
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
	    --dbg_med('x_item_id - '||x_item_id);
	    --dbg_med('x_invorg_id - '||x_invorg_id);

	   SELECT distinct a.operation_sequence_id
	     INTO x_opr_seq_id
	     FROM bom_operation_resources a, bom_operation_sequences b, bom_operational_routings c
	    WHERE c.assembly_item_id = x_item_id
	      AND c.organization_id = x_invorg_id
	      AND c.routing_sequence_id = b.routing_sequence_id(+)
	      AND b.operation_sequence_id = a.operation_sequence_id(+);
	    p_opr_seq_id := x_opr_seq_id;
	   RETURN  x_error_code;
        EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  dbg_med('Unable to derive Operation Sequence id(RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unable to derive Operation Sequence id(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while deriving Operation Sequence id(RTG_RES)');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving Operation Sequence id(RTG_RES)'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_assembly_item_number
                        );
                  RETURN  x_error_code;
        END get_opr_seq_id;

    BEGIN
	g_api_name := 'xx_rtgres_data_derivations';
	--get the organization_id
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Resources Data-Derivations');
	x_error_code_temp := get_org_id (csr_rtgres_print_rec.record_number,
                                          csr_rtgres_print_rec.organization_code,
                                          csr_rtgres_print_rec.assembly_item_number,
                                          csr_rtgres_print_rec.organization_id
		                                      );

	x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );

	x_error_code_temp := get_item_id (csr_rtgres_print_rec.record_number,
                                          csr_rtgres_print_rec.organization_code,
                                          csr_rtgres_print_rec.assembly_item_number,
                                          csr_rtgres_print_rec.assembly_item_id
		                                      );

	x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );

	x_error_code_temp := get_resource_id (csr_rtgres_print_rec.record_number,
                                             csr_rtgres_print_rec.organization_code,
                                             csr_rtgres_print_rec.assembly_item_number,
                                             csr_rtgres_print_rec.resource_code,
                                             csr_rtgres_print_rec.resource_id
		                                      );

	x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );

	/*IF G_TRANSACTION_TYPE = G_TRANS_TYPE_DELETE THEN
	    x_error_code_temp := get_opr_seq_id (csr_rtgres_print_rec.record_number,
						csr_rtgres_print_rec.organization_code,
						csr_rtgres_print_rec.assembly_item_number,
						csr_rtgres_print_rec.operation_sequence_id
		                                      );

	    x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);
	END IF;    */

	xx_emf_pkg.propagate_error ( x_error_code_temp );

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
    END xx_rtgres_data_derivations;

    --**********************************************************************
    --	Function for post validation
    --**********************************************************************

    FUNCTION post_validations(p_trans_type VARCHAR2, p_entity VARCHAR2)
    RETURN NUMBER
    IS
	x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
	g_api_name := 'main.post_validations';

	IF p_trans_type = G_TRANS_TYPE_CREATE THEN

	    IF p_entity = 'RTG' THEN

		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations for Routing Header');

		-- Update 'Routing Header' records with error if it is already existing in case of CREATE
		UPDATE xx_bom_rtg_hdr_stg a
		   SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
		       process_code = xx_emf_cn_pkg.CN_POSTVAL,
		       error_mesg='Record error out as this Routing Header is already existing'
		 WHERE 1 = 1
		   AND batch_id = G_BATCH_ID -- DS:17Sep12
		   AND NVL (a.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
				xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
		   AND EXISTS ( SELECT 1
				  FROM bom_operational_routings bor
				 WHERE bor.assembly_item_id = a.assembly_item_id
				   AND bor.organization_id = a.organization_id);

	    ELSIF p_entity = 'OPR' THEN

		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations for Operations');

		-- Update 'Operation Sequence' records with error if it is already existing
		UPDATE xx_bom_rtg_op_stg a
		   SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
		       process_code1 = xx_emf_cn_pkg.CN_POSTVAL,
		       error_mesg='Record error out as this Operation Sequence is already existing'
		 WHERE 1 = 1
		   AND batch_id = G_BATCH_ID -- DS:17Sep12
		   AND NVL (a.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
				xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
		   AND EXISTS ( SELECT 1
				  FROM bom_operation_sequences bos,
					bom_operational_routings bor
				 WHERE 1=1
				   AND bor.assembly_item_id = a.assembly_item_id
				   AND bor.organization_id = a.organization_id
				   AND bos.department_id = a.department_id
				   AND bos.routing_sequence_id = bor.routing_sequence_id);

	    ELSIF p_entity = 'RES' THEN

		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations for Resources');

		-- Update 'Operation Resource' records with error if it is already existing
		UPDATE xx_bom_rtg_res_stg a
		   SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
		       process_code = xx_emf_cn_pkg.CN_POSTVAL,
		       error_mesg='Record error out as this Operation Resource is already existing'
		 WHERE 1 = 1
		   AND batch_id = G_BATCH_ID -- DS:17Sep12
		   AND NVL (a.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
				xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
		   AND EXISTS ( SELECT 1
				  FROM bom_operation_resources boe,
					bom_operation_sequences bos,
					bom_operational_routings bor
				 WHERE 1 = 1
				   AND bor.assembly_item_id = a.assembly_item_id
				   AND bor.organization_id = a.organization_id
				   AND boe.resource_id = a.resource_id
				   AND bos.routing_sequence_id = bor.routing_sequence_id
				   AND boe.operation_sequence_id = bos.operation_sequence_id);
            --Added as per Wave2
	    ELSIF p_entity = 'NTWRK' THEN

		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations for Networks');

		-- Update 'Operation Network' records with error if it is already existing
		UPDATE xx_bom_op_network_stg a
		   SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
		       process_code = xx_emf_cn_pkg.CN_POSTVAL,
		       error_mesg='Record error out as this Operation Network is already existing'
		 WHERE 1 = 1
		   AND batch_id = G_BATCH_ID
		   AND NVL (a.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
				xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
		   AND EXISTS ( SELECT 1
                                  FROM bom_operation_sequences bos1,
                                       bom_operation_sequences bos2,
                                       bom_operational_routings bor,
                                       bom_operation_networks bon
                                 WHERE 1=1
                                   AND bor.assembly_item_id = a.assembly_item_id
                                   AND bor.organization_id = a.organization_id
                                   AND bos1.operation_seq_num = a.from_op_seq_id
                                   AND bos2.operation_seq_num = a.to_op_seq_id
                                   AND bos1.routing_sequence_id = bor.routing_sequence_id
                                   AND bos2.routing_sequence_id = bor.routing_sequence_id
                                   AND bon.from_op_seq_id = bos1.operation_sequence_id
                                   AND bon.to_op_seq_id = bos2.operation_sequence_id);

	    END IF;
	ELSIF p_trans_type = G_TRANS_TYPE_DELETE THEN

	    IF p_entity = 'RTG' THEN

		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations for Routing Header');

		-- Update 'Routing Header' records with error if it is already existing in case of CREATE
		UPDATE xx_bom_rtg_hdr_stg a
		   SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
		       process_code = xx_emf_cn_pkg.CN_POSTVAL,
		       error_mesg='Record error out as this Routing Header does not exist'
		 WHERE 1 = 1
		   AND batch_id = G_BATCH_ID -- DS:17Sep12
		   AND NVL (a.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
				xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
		   AND NOT EXISTS ( SELECT 1
				  FROM bom_operational_routings bor
				 WHERE bor.assembly_item_id = a.assembly_item_id
				   AND bor.organization_id = a.organization_id);

	    ELSIF p_entity = 'OPR' THEN

		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations for Operations');

		-- Update 'Operation Sequence' records with error if it is already existing
		UPDATE xx_bom_rtg_op_stg a
		   SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
		       process_code1 = xx_emf_cn_pkg.CN_POSTVAL,
		       error_mesg='Record error out as this Operation Sequence does not exist'
		 WHERE 1 = 1
		   AND batch_id = G_BATCH_ID -- DS:17Sep12
		   AND NVL (a.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
				xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
		   AND NOT EXISTS ( SELECT 1
				  FROM bom_operation_sequences bos,
					bom_operational_routings bor
				 WHERE 1=1
				   AND bor.assembly_item_id = a.assembly_item_id
				   AND bor.organization_id = a.organization_id
				   AND bos.department_id = a.department_id
				   AND bos.routing_sequence_id = bor.routing_sequence_id);

	    ELSIF p_entity = 'RES' THEN

		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations for Resources');

		-- Update 'Operation Resource' records with error if it is already existing
		UPDATE xx_bom_rtg_res_stg a
		   SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
		       process_code = xx_emf_cn_pkg.CN_POSTVAL,
		       error_mesg='Record error out as this Operation Resource does not exist'
		 WHERE 1 = 1
		   AND batch_id = G_BATCH_ID -- DS:17Sep12
		   AND NVL (a.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
				xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
		   AND NOT EXISTS ( SELECT 1
				  FROM bom_operation_resources boe,
					bom_operation_sequences bos,
					bom_operational_routings bor
				 WHERE 1 = 1
				   AND bor.assembly_item_id = a.assembly_item_id
				   AND bor.organization_id = a.organization_id
				   AND boe.resource_id = a.resource_id
				   AND bos.routing_sequence_id = bor.routing_sequence_id
				   AND boe.operation_sequence_id = bos.operation_sequence_id);
	    --Added as per Wave2
	    ELSIF p_entity = 'NTWRK' THEN

		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations for Network');

		-- Update 'Operation Network' records with error if it is already existing
		UPDATE xx_bom_op_network_stg a
		   SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
		       process_code = xx_emf_cn_pkg.CN_POSTVAL,
		       error_mesg='Record error out as this Operation Network does not exist'
		 WHERE 1 = 1
		   AND batch_id = G_BATCH_ID
		   AND NVL (a.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
				xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
		   AND NOT EXISTS ( SELECT 1
                                  FROM bom_operation_sequences bos1,
                                       bom_operation_sequences bos2,
                                       bom_operational_routings bor,
                                       bom_operation_networks bon
                                 WHERE 1=1
                                   AND bor.assembly_item_id = a.assembly_item_id
                                   AND bor.organization_id = a.organization_id
                                   AND bos1.operation_seq_num = a.from_op_seq_id
                                   AND bos2.operation_seq_num = a.to_op_seq_id
                                   AND bos1.routing_sequence_id = bor.routing_sequence_id
                                   AND bos2.routing_sequence_id = bor.routing_sequence_id
                                   AND bon.from_op_seq_id = bos1.operation_sequence_id
                                   AND bon.to_op_seq_id = bos2.operation_sequence_id);
	    END IF;
        END IF; -- p_trans_type

	IF p_entity = 'OPR' THEN

	    -- Update all Routing Header record with 'error' if one of Operations record errored out
	    UPDATE xx_bom_rtg_hdr_stg xbm
	       SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
		    process_code = xx_emf_cn_pkg.CN_POSTVAL,
		  error_mesg='Routing Header Errored out for Operations record error'
	       WHERE 1=1
	       AND batch_id = G_BATCH_ID -- DS:17Sep12
	       AND  NVL (xbm.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
						    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
	       AND (xbm.assembly_item_number,xbm.organization_code) IN (SELECT bcs.assembly_item_number,bcs.organization_code
									   FROM xx_bom_rtg_op_stg bcs
									  WHERE  bcs.assembly_item_number = xbm.assembly_item_number
									    AND  batch_id = G_BATCH_ID -- DS:17Sep12
									    AND  bcs.organization_code = xbm.organization_code
									    AND  NVL (bcs.error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
													    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
									    AND rownum = 1);

	    -- Update all Routing Operations record with 'error' if Routing Header record errored out
	    UPDATE xx_bom_rtg_op_stg bcs
	     SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
		    process_code1 = xx_emf_cn_pkg.CN_POSTVAL,
		error_mesg='Operations record Errored out for Routing Header record error'
	     WHERE 1=1
	     AND  batch_id = G_BATCH_ID -- DS:17Sep12
	     AND  NVL (bcs.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
						    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
	     AND (bcs.assembly_item_number,bcs.organization_code) IN (SELECT xbm.assembly_item_number,xbm.organization_code
									 FROM  xx_bom_rtg_hdr_stg xbm
									WHERE  xbm.assembly_item_number = bcs.assembly_item_number
									  AND  batch_id = G_BATCH_ID -- DS:17Sep12
									  AND  xbm.organization_code = bcs.organization_code
									  AND  NVL (xbm.error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
													    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR));
	ELSIF p_entity = 'RES' THEN

	    -- Update all Routing Header record with 'error' if one of Resources record errored out
	    UPDATE xx_bom_rtg_hdr_stg xbm
	       SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
		    process_code = xx_emf_cn_pkg.CN_POSTVAL,
		  error_mesg='Routing Header Errored out for Resources record error'
	       WHERE 1=1
	       AND  batch_id = G_BATCH_ID -- DS:17Sep12
	       AND  NVL (xbm.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
						    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
	       AND (xbm.assembly_item_number,xbm.organization_code) IN (SELECT bcs.assembly_item_number,bcs.organization_code
									   FROM xx_bom_rtg_res_stg bcs
									  WHERE  bcs.assembly_item_number = xbm.assembly_item_number
									    AND  batch_id = G_BATCH_ID -- DS:17Sep12
									    AND  bcs.organization_code = xbm.organization_code
									    AND  NVL (bcs.error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
													    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
									    AND rownum = 1);

	    -- Update all Routing Operations record with 'error' if one of Resources record errored out
	    UPDATE xx_bom_rtg_op_stg xbm
	       SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
		    process_code1 = xx_emf_cn_pkg.CN_POSTVAL,
		  error_mesg='Operation Errored out for Resources record error'
	       WHERE 1=1
	       AND  batch_id = G_BATCH_ID -- DS:17Sep12
	       AND  NVL (xbm.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
						    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
	       AND (xbm.assembly_item_number,xbm.organization_code) IN (SELECT bcs.assembly_item_number,bcs.organization_code
									   FROM xx_bom_rtg_res_stg bcs
									  WHERE  bcs.assembly_item_number = xbm.assembly_item_number
									    AND  batch_id = G_BATCH_ID -- DS:17Sep12
									    AND  bcs.organization_code = xbm.organization_code
									    --AND  bcs.operation_seq_num = xbm.operation_seq_num -- commented for UATW
									    AND  NVL (bcs.error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
													    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
									    AND rownum = 1);

	    -- Update all Routing Resources record with 'error' if Routing Header record errored out
	    UPDATE xx_bom_rtg_res_stg bcs
	     SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
		 process_code = xx_emf_cn_pkg.CN_POSTVAL,
		 error_mesg='Resources record Errored out for Routing Header record error'
	     WHERE 1=1
	     AND  batch_id = G_BATCH_ID -- DS:17Sep12
	     AND  NVL (bcs.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
						    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
	     AND (bcs.assembly_item_number,bcs.organization_code) IN (SELECT xbm.assembly_item_number,xbm.organization_code
									 FROM  xx_bom_rtg_hdr_stg xbm
									WHERE  xbm.assembly_item_number = bcs.assembly_item_number
									  AND  batch_id = G_BATCH_ID -- DS:17Sep12
									  AND  xbm.organization_code = bcs.organization_code
									  AND  NVL (xbm.error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
											    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR));
	--Added as per Wave2
	ELSIF p_entity = 'NTWRK' THEN

	    -- Update all Routing Header record with 'error' if one of Network record errored out
	    UPDATE xx_bom_rtg_hdr_stg xbm
	       SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
		    process_code = xx_emf_cn_pkg.CN_POSTVAL,
		  error_mesg='Routing Header Errored out for Network record error'
	       WHERE 1=1
	       AND  batch_id = G_BATCH_ID
	       AND  NVL (xbm.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
						    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
               AND cfm_routing_flag = 3
	       AND (xbm.assembly_item_number,xbm.organization_code) IN (SELECT bcs.assembly_item_number,bcs.organization_code
									   FROM xx_bom_op_network_stg bcs
									  WHERE  bcs.assembly_item_number = xbm.assembly_item_number
									    AND  batch_id = G_BATCH_ID
									    AND  bcs.organization_code = xbm.organization_code
									    AND  NVL (bcs.error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
													    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
									    AND rownum = 1);

	    -- Update all Routing Operations record with 'error' if one of Network record errored out
	    UPDATE xx_bom_rtg_op_stg xbm
	       SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
		    process_code1 = xx_emf_cn_pkg.CN_POSTVAL,
		  error_mesg='Operation Errored out for Network record error'
	       WHERE 1=1
	       AND  batch_id = G_BATCH_ID
	       AND  NVL (xbm.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
						    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
	       AND (xbm.assembly_item_number,xbm.organization_code) IN (SELECT bcs.assembly_item_number,bcs.organization_code
									   FROM xx_bom_op_network_stg bcs
									  WHERE  bcs.assembly_item_number = xbm.assembly_item_number
									    AND  batch_id = G_BATCH_ID
									    AND  bcs.organization_code = xbm.organization_code
									    --AND  bcs.operation_seq_num = xbm.operation_seq_num -- commented for UATW
									    AND  NVL (bcs.error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
													    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
									    AND rownum = 1)
              AND EXISTS (SELECT 1
			    FROM  xx_bom_rtg_hdr_stg hdr
			   WHERE  hdr.assembly_item_number = xbm.assembly_item_number
			     AND  batch_id = G_BATCH_ID
			     AND  hdr.organization_code = xbm.organization_code
			     AND  hdr.cfm_routing_flag = 3);

	    -- Update all Routing Network record with 'error' if Routing Header record errored out
	    UPDATE xx_bom_op_network_stg bcs
	     SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
		 process_code = xx_emf_cn_pkg.CN_POSTVAL,
		 error_mesg='Network record Errored out for Routing Header record error'
	     WHERE 1=1
	     AND  batch_id = G_BATCH_ID
	     AND  NVL (bcs.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
						    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
	     AND (bcs.assembly_item_number,bcs.organization_code) IN (SELECT xbm.assembly_item_number,xbm.organization_code
									 FROM  xx_bom_rtg_hdr_stg xbm
									WHERE  xbm.assembly_item_number = bcs.assembly_item_number
									  AND  batch_id = G_BATCH_ID
									  AND  xbm.organization_code = bcs.organization_code
									  AND  NVL (xbm.error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
													    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR));

	END IF;

	COMMIT;
	RETURN x_error_code;
    EXCEPTION
	WHEN xx_emf_pkg.G_E_REC_ERROR THEN
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, '8');--***DS
    	    x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	    RETURN x_error_code;
	WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, '9');--***DS
	    x_error_code := xx_emf_cn_pkg.cn_prc_err;
	    RETURN x_error_code;
	WHEN OTHERS THEN
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, '9');--***DS
	    x_error_code := xx_emf_cn_pkg.cn_prc_err;
	    RETURN x_error_code;
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Completed Routing Header Post-Validations');
    END post_validations;


  PROCEDURE print_detail_record_count(pr_validate_and_load IN VARCHAR2)
	IS
  --------------------------------------------------------------------------------------
    -- Created By                 : Partha S Mohanty
    -- Creation Date              : 10-APR-2012
    -- Description                : Print error and success record count in output file Body

    -- Parameters description:

    -- @param1         :pr_validate_and_load(IN)
   -----------------------------------------------------------------------------------------
	CURSOR c_get_total_cnt1 IS
	SELECT COUNT (1) total_count
	  FROM xx_bom_rtg_hdr_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID;

	x_total_cnt1 NUMBER;

	CURSOR c_get_total_cnt2 IS
	SELECT COUNT (1) total_count
	  FROM xx_bom_rtg_op_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID;

	x_total_cnt2 NUMBER;

	CURSOR c_get_total_cnt3 IS
	SELECT COUNT (1) total_count
	  FROM xx_bom_rtg_res_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID;

	x_total_cnt3 NUMBER;
	--Added as per Wave2
	CURSOR c_get_total_cnt4 IS
	SELECT COUNT (1) total_count
	  FROM xx_bom_op_network_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID;

	x_total_cnt4 NUMBER;

	CURSOR c_get_error_cnt1 IS
	SELECT SUM(error_count)
	  FROM (
		SELECT COUNT (1) error_count
		  FROM xx_bom_rtg_hdr_stg
		 WHERE batch_id   = G_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

	x_error_cnt1 NUMBER;

	CURSOR c_get_error_cnt2 IS
	SELECT SUM(error_count)
	  FROM (
		SELECT COUNT (1) error_count
		  FROM xx_bom_rtg_op_stg
		 WHERE batch_id   = G_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

	x_error_cnt2 NUMBER;

	CURSOR c_get_error_cnt3 IS
	SELECT SUM(error_count)
	  FROM (
		SELECT COUNT (1) error_count
		  FROM xx_bom_rtg_res_stg
		 WHERE batch_id   = G_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

	x_error_cnt3 NUMBER;
	--Added as per Wave2
	CURSOR c_get_error_cnt4 IS
	SELECT SUM(error_count)
	  FROM (
		SELECT COUNT (1) error_count
		  FROM xx_bom_op_network_stg
		 WHERE batch_id   = G_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

	x_error_cnt4 NUMBER;

	CURSOR c_get_warning_cnt1 IS
	SELECT COUNT (1) warn_count
	  FROM xx_bom_rtg_hdr_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

	x_warn_cnt1 NUMBER;

	CURSOR c_get_warning_cnt2 IS
	SELECT COUNT (1) warn_count
	  FROM xx_bom_rtg_op_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

	x_warn_cnt2 NUMBER;

	CURSOR c_get_warning_cnt3 IS
	SELECT COUNT (1) warn_count
	  FROM xx_bom_rtg_res_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

	x_warn_cnt3 NUMBER;
	--Added as per Wave2
	CURSOR c_get_warning_cnt4 IS
	SELECT COUNT (1) warn_count
	  FROM xx_bom_op_network_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

	x_warn_cnt4 NUMBER;

	CURSOR c_get_success_cnt1 IS
	SELECT COUNT (1) success_count
	  FROM xx_bom_rtg_hdr_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	x_success_cnt1 NUMBER;

	CURSOR c_get_success_cnt2 IS
	SELECT COUNT (1) success_count
	  FROM xx_bom_rtg_op_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND process_code1 = xx_emf_cn_pkg.CN_PROCESS_DATA
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	x_success_cnt2 NUMBER;

	CURSOR c_get_success_cnt3 IS
	SELECT COUNT (1) success_count
	  FROM xx_bom_rtg_res_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	x_success_cnt3 NUMBER;
	--Added as per Wave2
	CURSOR c_get_success_cnt4 IS
	SELECT COUNT (1) success_count
	  FROM xx_bom_op_network_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	x_success_cnt4 NUMBER;

	-- Added for if p_validate_only_flag is set to VALIDATE_ONLY Starts
	CURSOR c_get_success_valid_cnt1 IS
	SELECT COUNT (1) success_count
	  FROM xx_bom_rtg_hdr_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND process_code = xx_emf_cn_pkg.CN_POSTVAL
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	-- Added for if p_validate_only_flag is set to VALIDATE_ONLY Starts
	CURSOR c_get_success_valid_cnt2 IS
	SELECT COUNT (1) success_count
	  FROM xx_bom_rtg_op_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND process_code1 = xx_emf_cn_pkg.CN_POSTVAL
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	-- Added for if p_validate_only_flag is set to VALIDATE_ONLY Starts
	CURSOR c_get_success_valid_cnt3 IS
	SELECT COUNT (1) success_count
	  FROM xx_bom_rtg_res_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND process_code = xx_emf_cn_pkg.CN_POSTVAL
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	--Added as per Wave2
	CURSOR c_get_success_valid_cnt4 IS
	SELECT COUNT (1) success_count
	  FROM xx_bom_op_network_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND process_code = xx_emf_cn_pkg.CN_POSTVAL
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	x_total_cnt NUMBER;
	x_error_cnt NUMBER;
	x_warn_cnt NUMBER;
	x_success_cnt NUMBER;

    BEGIN
	OPEN c_get_total_cnt1;
	FETCH c_get_total_cnt1 INTO x_total_cnt1;
	CLOSE c_get_total_cnt1;

	OPEN c_get_total_cnt2;
	FETCH c_get_total_cnt2 INTO x_total_cnt2;
	CLOSE c_get_total_cnt2;

	OPEN c_get_total_cnt3;
	FETCH c_get_total_cnt3 INTO x_total_cnt3;
	CLOSE c_get_total_cnt3;
	--Added as per Wave2
	OPEN c_get_total_cnt4;
	FETCH c_get_total_cnt4 INTO x_total_cnt4;
	CLOSE c_get_total_cnt4;

	--x_total_cnt := x_total_cnt1 + x_total_cnt2 + x_total_cnt3;

	OPEN c_get_error_cnt1;
	FETCH c_get_error_cnt1 INTO x_error_cnt1;
	CLOSE c_get_error_cnt1;

	OPEN c_get_error_cnt2;
	FETCH c_get_error_cnt2 INTO x_error_cnt2;
	CLOSE c_get_error_cnt2;

	OPEN c_get_error_cnt3;
	FETCH c_get_error_cnt3 INTO x_error_cnt3;
	CLOSE c_get_error_cnt3;
	--Added as per Wave2
	OPEN c_get_error_cnt4;
	FETCH c_get_error_cnt4 INTO x_error_cnt4;
	CLOSE c_get_error_cnt4;

	--x_error_cnt := x_error_cnt1 + x_error_cnt2 + x_error_cnt3;

	OPEN c_get_warning_cnt1;
	FETCH c_get_warning_cnt1 INTO x_warn_cnt1;
	CLOSE c_get_warning_cnt1;

	OPEN c_get_warning_cnt2;
	FETCH c_get_warning_cnt2 INTO x_warn_cnt2;
	CLOSE c_get_warning_cnt2;

	OPEN c_get_warning_cnt3;
	FETCH c_get_warning_cnt3 INTO x_warn_cnt3;
	CLOSE c_get_warning_cnt3;
	--Added as per Wave2
	OPEN c_get_warning_cnt4;
	FETCH c_get_warning_cnt4 INTO x_warn_cnt4;
	CLOSE c_get_warning_cnt4;

	--x_warn_cnt := x_warn_cnt1 + x_warn_cnt2 + x_warn_cnt3;

	IF pr_validate_and_load = g_validate_and_load THEN
	    OPEN c_get_success_cnt1;
	    FETCH c_get_success_cnt1 INTO x_success_cnt1;
	    CLOSE c_get_success_cnt1;

	    OPEN c_get_success_cnt2;
	    FETCH c_get_success_cnt2 INTO x_success_cnt2;
	    CLOSE c_get_success_cnt2;

	    OPEN c_get_success_cnt3;
	    FETCH c_get_success_cnt3 INTO x_success_cnt3;
	    CLOSE c_get_success_cnt3;
	    --Added as per Wave2
	    OPEN c_get_success_cnt4;
	    FETCH c_get_success_cnt4 INTO x_success_cnt4;
	    CLOSE c_get_success_cnt4;
	ELSE
	    OPEN c_get_success_valid_cnt1;
	    FETCH c_get_success_valid_cnt1 INTO x_success_cnt1;
	    CLOSE c_get_success_valid_cnt1;

	    OPEN c_get_success_valid_cnt2;
	    FETCH c_get_success_valid_cnt2 INTO x_success_cnt2;
	    CLOSE c_get_success_valid_cnt2;

	    OPEN c_get_success_valid_cnt3;
	    FETCH c_get_success_valid_cnt3 INTO x_success_cnt3;
	    CLOSE c_get_success_valid_cnt3;
	    --Added as per Wave2
	    OPEN c_get_success_valid_cnt4;
	    FETCH c_get_success_valid_cnt4 INTO x_success_cnt4;
	    CLOSE c_get_success_valid_cnt4;
	END IF;

	   --x_success_cnt := x_success_cnt1 + x_success_cnt2 + x_success_cnt3;

     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  'REC_COUNT'
                      ,p_error_text  => rpad('Total Routing Header Record     :',35,' ')||rpad(x_total_cnt1,7,' ')||rpad('Error :',10,' ')||rpad(x_error_cnt1,7,' ')||rpad('Success:',10,' ')||x_success_cnt1
                      ,p_record_identifier_1 => 'RTG_HDR'
                      );

    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  'REC_COUNT'
                      ,p_error_text  => rpad('Total Routing Operations Record :',35,' ')||rpad(x_total_cnt2,7,' ')||rpad('Error :',10,' ')||rpad(x_error_cnt2,7,' ')||rpad('Success:',10,' ')||x_success_cnt2
                      ,p_record_identifier_1 => 'RTG_OPR'
                      );

    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  'REC_COUNT'
                      ,p_error_text  => rpad('Total Routing Resources Record  :',35,' ')||rpad(x_total_cnt3,7,' ')||rpad('Error :',10,' ')||rpad(x_error_cnt3,7,' ')||rpad('Success:',10,' ')||x_success_cnt3
                      ,p_record_identifier_1 => 'RTG_OPR'
                      );
    --Added as per Wave2
    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                      ,p_category    =>  'REC_COUNT'
                      ,p_error_text  => rpad('Total Operation Network Record  :',35,' ')||rpad(x_total_cnt4,7,' ')||rpad('Error :',10,' ')||rpad(x_error_cnt4,7,' ')||rpad('Success:',10,' ')||x_success_cnt4
                      ,p_record_identifier_1 => 'RTG_NTWRK'
                      );

   EXCEPTION
    WHEN OTHERS THEN
	     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while printing record count: '||SQLERRM);

	END print_detail_record_count;


    --**********************************************************************
    --	Procedure to count staging table record for Routing Headers
    --**********************************************************************

    PROCEDURE update_record_count(pr_validate_and_load IN VARCHAR2)
	IS
	CURSOR c_get_total_cnt1 IS
	SELECT COUNT (1) total_count
	  FROM xx_bom_rtg_hdr_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID;

	x_total_cnt1 NUMBER;

	CURSOR c_get_total_cnt2 IS
	SELECT COUNT (1) total_count
	  FROM xx_bom_rtg_op_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID;

	x_total_cnt2 NUMBER;

	CURSOR c_get_total_cnt3 IS
	SELECT COUNT (1) total_count
	  FROM xx_bom_rtg_res_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID;

	x_total_cnt3 NUMBER;
	--Added as per Wave2
	CURSOR c_get_total_cnt4 IS
	SELECT COUNT (1) total_count
	  FROM xx_bom_op_network_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID;

	x_total_cnt4 NUMBER;

	CURSOR c_get_error_cnt1 IS
	SELECT SUM(error_count)
	  FROM (
		SELECT COUNT (1) error_count
		  FROM xx_bom_rtg_hdr_stg
		 WHERE batch_id   = G_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

	x_error_cnt1 NUMBER;

	CURSOR c_get_error_cnt2 IS
	SELECT SUM(error_count)
	  FROM (
		SELECT COUNT (1) error_count
		  FROM xx_bom_rtg_op_stg
		 WHERE batch_id   = G_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

	x_error_cnt2 NUMBER;

	CURSOR c_get_error_cnt3 IS
	SELECT SUM(error_count)
	  FROM (
		SELECT COUNT (1) error_count
		  FROM xx_bom_rtg_res_stg
		 WHERE batch_id   = G_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

	x_error_cnt3 NUMBER;
	--Added as per Wave2
	CURSOR c_get_error_cnt4 IS
	SELECT SUM(error_count)
	  FROM (
		SELECT COUNT (1) error_count
		  FROM xx_bom_op_network_stg
		 WHERE batch_id   = G_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

	x_error_cnt4 NUMBER;

	CURSOR c_get_warning_cnt1 IS
	SELECT COUNT (1) warn_count
	  FROM xx_bom_rtg_hdr_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

	x_warn_cnt1 NUMBER;

	CURSOR c_get_warning_cnt2 IS
	SELECT COUNT (1) warn_count
	  FROM xx_bom_rtg_op_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

	x_warn_cnt2 NUMBER;

	CURSOR c_get_warning_cnt3 IS
	SELECT COUNT (1) warn_count
	  FROM xx_bom_rtg_res_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

	x_warn_cnt3 NUMBER;

        --Added as per Wave2
	CURSOR c_get_warning_cnt4 IS
	SELECT COUNT (1) warn_count
	  FROM xx_bom_op_network_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

	x_warn_cnt4 NUMBER;

	CURSOR c_get_success_cnt1 IS
	SELECT COUNT (1) success_count
	  FROM xx_bom_rtg_hdr_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	x_success_cnt1 NUMBER;

	CURSOR c_get_success_cnt2 IS
	SELECT COUNT (1) success_count
	  FROM xx_bom_rtg_op_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND process_code1 = xx_emf_cn_pkg.CN_PROCESS_DATA
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	x_success_cnt2 NUMBER;

	CURSOR c_get_success_cnt3 IS
	SELECT COUNT (1) success_count
	  FROM xx_bom_rtg_res_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	x_success_cnt3 NUMBER;
	--Added as per Wave2
	CURSOR c_get_success_cnt4 IS
	SELECT COUNT (1) success_count
	  FROM xx_bom_op_network_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	x_success_cnt4 NUMBER;

	-- Added for if p_validate_only_flag is set to VALIDATE_ONLY Starts
	CURSOR c_get_success_valid_cnt1 IS
	SELECT COUNT (1) success_count
	  FROM xx_bom_rtg_hdr_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND process_code = xx_emf_cn_pkg.CN_POSTVAL
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	-- Added for if p_validate_only_flag is set to VALIDATE_ONLY Starts
	CURSOR c_get_success_valid_cnt2 IS
	SELECT COUNT (1) success_count
	  FROM xx_bom_rtg_op_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND process_code1 = xx_emf_cn_pkg.CN_POSTVAL
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	-- Added for if p_validate_only_flag is set to VALIDATE_ONLY Starts
	CURSOR c_get_success_valid_cnt3 IS
	SELECT COUNT (1) success_count
	  FROM xx_bom_rtg_res_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND process_code = xx_emf_cn_pkg.CN_POSTVAL
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	--Added as per Wave2
	CURSOR c_get_success_valid_cnt4 IS
	SELECT COUNT (1) success_count
	  FROM xx_bom_op_network_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND process_code = xx_emf_cn_pkg.CN_POSTVAL
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	x_total_cnt NUMBER;
	x_error_cnt NUMBER;
	x_warn_cnt NUMBER;
	x_success_cnt NUMBER;

    BEGIN
	OPEN c_get_total_cnt1;
	FETCH c_get_total_cnt1 INTO x_total_cnt1;
	CLOSE c_get_total_cnt1;

	OPEN c_get_total_cnt2;
	FETCH c_get_total_cnt2 INTO x_total_cnt2;
	CLOSE c_get_total_cnt2;

	OPEN c_get_total_cnt3;
	FETCH c_get_total_cnt3 INTO x_total_cnt3;
	CLOSE c_get_total_cnt3;

	--x_total_cnt := x_total_cnt1 + x_total_cnt2 + x_total_cnt3;
	x_total_cnt := x_total_cnt1 + x_total_cnt2 + x_total_cnt3+x_total_cnt4;  --Added as per Wave2

	OPEN c_get_error_cnt1;
	FETCH c_get_error_cnt1 INTO x_error_cnt1;
	CLOSE c_get_error_cnt1;

	OPEN c_get_error_cnt2;
	FETCH c_get_error_cnt2 INTO x_error_cnt2;
	CLOSE c_get_error_cnt2;

	OPEN c_get_error_cnt3;
	FETCH c_get_error_cnt3 INTO x_error_cnt3;
	CLOSE c_get_error_cnt3;

	--x_error_cnt := x_error_cnt1 + x_error_cnt2 + x_error_cnt3;
	x_error_cnt := x_error_cnt1 + x_error_cnt2 + x_error_cnt3 + x_error_cnt4; --Added as per Wave2

	OPEN c_get_warning_cnt1;
	FETCH c_get_warning_cnt1 INTO x_warn_cnt1;
	CLOSE c_get_warning_cnt1;

	OPEN c_get_warning_cnt2;
	FETCH c_get_warning_cnt2 INTO x_warn_cnt2;
	CLOSE c_get_warning_cnt2;

	OPEN c_get_warning_cnt3;
	FETCH c_get_warning_cnt3 INTO x_warn_cnt3;
	CLOSE c_get_warning_cnt3;

	--x_warn_cnt := x_warn_cnt1 + x_warn_cnt2 + x_warn_cnt3;
	x_warn_cnt := x_warn_cnt1 + x_warn_cnt2 + x_warn_cnt3 + x_warn_cnt4;--Added as per Wave2

	IF pr_validate_and_load = g_validate_and_load THEN
	    OPEN c_get_success_cnt1;
	    FETCH c_get_success_cnt1 INTO x_success_cnt1;
	    CLOSE c_get_success_cnt1;

	    OPEN c_get_success_cnt2;
	    FETCH c_get_success_cnt2 INTO x_success_cnt2;
	    CLOSE c_get_success_cnt2;

	    OPEN c_get_success_cnt3;
	    FETCH c_get_success_cnt3 INTO x_success_cnt3;
	    CLOSE c_get_success_cnt3;
	ELSE
	    OPEN c_get_success_valid_cnt1;
	    FETCH c_get_success_valid_cnt1 INTO x_success_cnt1;
	    CLOSE c_get_success_valid_cnt1;

	    OPEN c_get_success_valid_cnt2;
	    FETCH c_get_success_valid_cnt2 INTO x_success_cnt2;
	    CLOSE c_get_success_valid_cnt2;

	    OPEN c_get_success_valid_cnt3;
	    FETCH c_get_success_valid_cnt3 INTO x_success_cnt3;
	    CLOSE c_get_success_valid_cnt3;
	END IF;

	--x_success_cnt := x_success_cnt1 + x_success_cnt2 + x_success_cnt3;
	x_success_cnt := x_success_cnt1 + x_success_cnt2 + x_success_cnt3 + x_success_cnt4;  --Added as per Wave2

	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Routing Header record processing status - ');
	xx_emf_pkg.update_recs_cnt
	(
	    p_total_recs_cnt   => x_total_cnt,
	    p_success_recs_cnt => x_success_cnt,
	    p_warning_recs_cnt => x_warn_cnt,
	    p_error_recs_cnt   => x_error_cnt
	);
    END update_record_count;

    --**********************************************************************
    --			    Main Procedure
    --**********************************************************************

    PROCEDURE main(x_errbuf   OUT VARCHAR2
		    ,x_retcode  OUT VARCHAR2
		    ,p_batch_id      IN  VARCHAR2
		    ,p_restart_flag  IN  VARCHAR2
		    ,p_validate_and_load     IN VARCHAR2
        ,p_transaction_type IN VARCHAR2
		    ) IS

    ----------------------- Private Variable Declaration Section -----------------------
    --Stop the program with EMF error header insertion fails
      l_process_status NUMBER;

      x_error_code          NUMBER                := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp     NUMBER                := xx_emf_cn_pkg.CN_SUCCESS;

      x_itemrtg_table   g_xx_rtg_hdr_tab_type;

      x_rtgop_table	g_xx_op_seq_tab_type;

      x_rtgres_table    g_xx_op_res_tab_type;

      x_rtgntwrk_table    g_xx_op_ntwrk_stg_tab_type;  --Added as per Wave2

    CURSOR c_xx_itemrtg ( cp_process_status VARCHAR2)
        IS
        SELECT *
          FROM xx_bom_rtg_hdr_stg
        WHERE batch_id     = G_BATCH_ID
          AND request_id   = xx_emf_pkg.G_REQUEST_ID
          AND process_code = cp_process_status
          AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
        ORDER BY record_number;

    CURSOR c_xx_rtgop ( cp_process_status VARCHAR2)
        IS
        SELECT *
          FROM xx_bom_rtg_op_stg
        WHERE batch_id     = G_BATCH_ID
          AND request_id   = xx_emf_pkg.G_REQUEST_ID
          AND process_code1 = cp_process_status
          AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
        ORDER BY record_number;

    CURSOR c_xx_rtgres ( cp_process_status VARCHAR2)
        IS
        SELECT *
          FROM xx_bom_rtg_res_stg
        WHERE batch_id     = G_BATCH_ID
          AND request_id   = xx_emf_pkg.G_REQUEST_ID
          AND process_code = cp_process_status
          AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
        ORDER BY record_number;

   --Added as per Wave2
    CURSOR c_xx_rtgntwrk ( cp_process_status VARCHAR2)
        IS
        SELECT *
          FROM xx_bom_op_network_stg
        WHERE batch_id     = G_BATCH_ID
          AND request_id   = xx_emf_pkg.G_REQUEST_ID
          AND process_code = cp_process_status
          AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
        ORDER BY record_number;


    --**********************************************************************
    --	Procedure to update Routing Header error record status
    --**********************************************************************

    PROCEDURE update_record_status_rtg (
	p_conv_hdr_rec  IN OUT  G_XX_RTG_HDR_STG_REC_TYPE,
	p_error_code            IN      VARCHAR2
       ) IS
    BEGIN
        g_api_name := 'main.update_record_status_rtg';
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update Routing Header record status...');

	IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
	THEN
	    p_conv_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
	ELSE
	    p_conv_hdr_rec.error_code := xx_intg_common_pkg.find_max(p_error_code, NVL (p_conv_hdr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));

	END IF;
	p_conv_hdr_rec.process_code := G_STAGE;

    END update_record_status_rtg;

    --**********************************************************************
    --	Procedure to update Operation Sequence error record status
    --**********************************************************************

    PROCEDURE update_record_status_op (
	p_conv_hdr_rec  IN OUT  G_XX_OP_SEQ_STG_REC_TYPE,
	p_error_code    IN      VARCHAR2
       ) IS
    BEGIN
        g_api_name := 'main.update_record_status_op';
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update Operation Sequence record status...');

	IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
	THEN
	    p_conv_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
	ELSE
	    p_conv_hdr_rec.error_code := xx_intg_common_pkg.find_max(p_error_code, NVL (p_conv_hdr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));

	END IF;
	p_conv_hdr_rec.process_code1 := G_STAGE;

    END update_record_status_op;

    --Added as per Wave2
    --**********************************************************************
    --	Procedure to update Operation Sequence error record status
    --**********************************************************************

    PROCEDURE update_record_status_ntwrk (
	p_conv_hdr_rec  IN OUT  G_XX_OP_NTWRK_STG_REC_TYPE,
	p_error_code    IN      VARCHAR2
       ) IS
    BEGIN
        g_api_name := 'main.update_record_status_ntwrk';
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update Operation Network record status...');

	IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
	THEN
	    p_conv_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
	ELSE
	    p_conv_hdr_rec.error_code := xx_intg_common_pkg.find_max(p_error_code, NVL (p_conv_hdr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));

	END IF;
	p_conv_hdr_rec.process_code := G_STAGE;

    END update_record_status_ntwrk;

    --**********************************************************************
    --	Procedure to update Operation Resources error record status
    --**********************************************************************

    PROCEDURE update_record_status_res (
	p_conv_hdr_rec  IN OUT  G_XX_OP_RES_STG_REC_TYPE,
	p_error_code    IN      VARCHAR2
       ) IS
    BEGIN
        g_api_name := 'main.update_record_status_res';
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update Operation Resources record status...');

	IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
	THEN
	    p_conv_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
	ELSE
	    p_conv_hdr_rec.error_code := xx_intg_common_pkg.find_max(p_error_code, NVL (p_conv_hdr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));

	END IF;
	p_conv_hdr_rec.process_code := G_STAGE;

    END update_record_status_res;

    --**********************************************************************
    --	    Procedure to update Routing Header staging records
    --**********************************************************************

    PROCEDURE update_int_records_rtg (p_cnv_itemrtg_table IN g_xx_rtg_hdr_tab_type)
	IS
	x_last_update_date      DATE := SYSDATE;
	x_last_updated_by       NUMBER := fnd_global.user_id;
	x_last_update_login     NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
	indx		    NUMBER;

	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
       g_api_name := 'main.update_int_records_rtg';

	FOR indx IN 1 .. p_cnv_itemrtg_table.COUNT LOOP

	  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_itemrtg_table(indx).process_code ' || p_cnv_itemrtg_table(indx).process_code);
	  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_itemrtg_table(indx).error_code ' || p_cnv_itemrtg_table(indx).error_code);

	UPDATE xx_bom_rtg_hdr_stg
	   SET  assembly_item_id        = p_cnv_itemrtg_table(indx).assembly_item_id,
		organization_id         = p_cnv_itemrtg_table(indx).organization_id,
		completion_locator_id   = p_cnv_itemrtg_table(indx).completion_locator_id,
		last_update_date        = p_cnv_itemrtg_table(indx).last_update_date,
		last_updated_by         = p_cnv_itemrtg_table(indx).last_updated_by,
		creation_date           = p_cnv_itemrtg_table(indx).creation_date,
		created_by              = p_cnv_itemrtg_table(indx).created_by,
		last_update_login       = p_cnv_itemrtg_table(indx).last_update_login,
		request_id              = p_cnv_itemrtg_table(indx).request_id,
		program_application_id  = p_cnv_itemrtg_table(indx).program_application_id,
		program_id              = p_cnv_itemrtg_table(indx).program_id,
		program_update_date     = p_cnv_itemrtg_table(indx).program_update_date,
		organization_code       = p_cnv_itemrtg_table(indx).organization_code,
		assembly_item_number    = p_cnv_itemrtg_table(indx).assembly_item_number,
		transaction_id          = p_cnv_itemrtg_table(indx).transaction_id,
		process_flag            = p_cnv_itemrtg_table(indx).process_flag,
		transaction_type        = p_cnv_itemrtg_table(indx).transaction_type,
		--batch_id                = p_cnv_itemrtg_table(indx).batch_id,-- DS:17Sep12
		error_code              = p_cnv_itemrtg_table(indx).error_code,
		error_type              = p_cnv_itemrtg_table(indx).error_type,
		error_explanation       = p_cnv_itemrtg_table(indx).error_explanation,
		error_flag              = p_cnv_itemrtg_table(indx).error_flag,
		process_code            = p_cnv_itemrtg_table(indx).process_code,
		error_mesg              = p_cnv_itemrtg_table(indx).error_mesg,
		attribute11		= G_BATCH_ID,
		routing_sequence_id	= p_cnv_itemrtg_table(indx).routing_sequence_id
	     WHERE record_number = p_cnv_itemrtg_table(indx).record_number
	       AND batch_id = G_BATCH_ID; -- DS:17Sep12
	END LOOP;

	COMMIT;
    END update_int_records_rtg;

    --**********************************************************************
    --	    Procedure to update Operation Sequence staging records
    --**********************************************************************

    PROCEDURE update_int_records_op (p_cnv_rtgop_table IN g_xx_op_seq_tab_type)
	IS
	x_last_update_date      DATE := SYSDATE;
	x_last_updated_by       NUMBER := fnd_global.user_id;
	x_last_update_login     NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
	indx			NUMBER;

	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
       g_api_name := 'main.update_int_records_op';

	FOR indx IN 1 .. p_cnv_rtgop_table.COUNT LOOP

	  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_rtgop_table(indx).process_code1 ' || p_cnv_rtgop_table(indx).process_code1);
	  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_rtgop_table(indx).error_code ' || p_cnv_rtgop_table(indx).error_code);

	UPDATE xx_bom_rtg_op_stg
	   SET  operation_seq_num       = p_cnv_rtgop_table(indx).operation_seq_num,
		last_update_date        = p_cnv_rtgop_table(indx).last_update_date,
		last_updated_by         = p_cnv_rtgop_table(indx).last_updated_by,
		creation_date           = p_cnv_rtgop_table(indx).creation_date,
		created_by              = p_cnv_rtgop_table(indx).created_by,
		last_update_login       = p_cnv_rtgop_table(indx).last_update_login,
		department_id           = p_cnv_rtgop_table(indx).department_id,
		operation_description   = p_cnv_rtgop_table(indx).operation_description,
		effectivity_date        = p_cnv_rtgop_table(indx).effectivity_date,
		implementation_date     = p_cnv_rtgop_table(indx).implementation_date,
		backflush_flag          = p_cnv_rtgop_table(indx).backflush_flag,
		request_id              = p_cnv_rtgop_table(indx).request_id,
		program_application_id  = p_cnv_rtgop_table(indx).program_application_id,
		program_id              = p_cnv_rtgop_table(indx).program_id,
		program_update_date     = p_cnv_rtgop_table(indx).program_update_date,
		assembly_item_id	= p_cnv_rtgop_table(indx).assembly_item_id,
		organization_id		= p_cnv_rtgop_table(indx).organization_id,
		organization_code       = p_cnv_rtgop_table(indx).organization_code,
		assembly_item_number    = p_cnv_rtgop_table(indx).assembly_item_number,
		department_code		= p_cnv_rtgop_table(indx).department_code,
		transaction_id          = p_cnv_rtgop_table(indx).transaction_id,
		process_flag            = p_cnv_rtgop_table(indx).process_flag,
		transaction_type        = p_cnv_rtgop_table(indx).transaction_type,
		--batch_id                = p_cnv_rtgop_table(indx).batch_id, -- DS:17Sep12
		error_code              = p_cnv_rtgop_table(indx).error_code,
		error_type              = p_cnv_rtgop_table(indx).error_type,
		error_explanation       = p_cnv_rtgop_table(indx).error_explanation,
		error_flag              = p_cnv_rtgop_table(indx).error_flag,
		process_code1           = p_cnv_rtgop_table(indx).process_code1,
		error_mesg              = p_cnv_rtgop_table(indx).error_mesg,
		attribute11		= G_BATCH_ID,
		routing_sequence_id	= p_cnv_rtgop_table(indx).routing_sequence_id,
		operation_sequence_id	= p_cnv_rtgop_table(indx).operation_sequence_id
	     WHERE record_number = p_cnv_rtgop_table(indx).record_number
	       AND batch_id = G_BATCH_ID; -- DS:17Sep12
	END LOOP;

	COMMIT;
    END update_int_records_op;

    --Added as per Wave2
    --**********************************************************************
    --	    Procedure to update Operation Network staging records
    --**********************************************************************

    PROCEDURE update_int_records_ntwrk (p_cnv_rtgntwrk_table IN g_xx_op_ntwrk_stg_tab_type)
	IS
	x_last_update_date      DATE := SYSDATE;
	x_last_updated_by       NUMBER := fnd_global.user_id;
	x_last_update_login     NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
	indx			NUMBER;

	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
       g_api_name := 'main.update_int_records_ntwrk';

	FOR indx IN 1 .. p_cnv_rtgntwrk_table.COUNT LOOP

	  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_rtgntwrk_table(indx).process_code ' || p_cnv_rtgntwrk_table(indx).process_code);
	  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_rtgntwrk_table(indx).error_code ' || p_cnv_rtgntwrk_table(indx).error_code);

	UPDATE xx_bom_op_network_stg
	   SET  from_op_seq_id          = p_cnv_rtgntwrk_table(indx).from_op_seq_id,
	        to_op_seq_id            = p_cnv_rtgntwrk_table(indx).to_op_seq_id,
		last_update_date        = p_cnv_rtgntwrk_table(indx).last_update_date,
		last_updated_by         = p_cnv_rtgntwrk_table(indx).last_updated_by,
		creation_date           = p_cnv_rtgntwrk_table(indx).creation_date,
		created_by              = p_cnv_rtgntwrk_table(indx).created_by,
		last_update_login       = p_cnv_rtgntwrk_table(indx).last_update_login,
		process_code            = p_cnv_rtgntwrk_table(indx).process_code,
		error_code              = p_cnv_rtgntwrk_table(indx).error_code,
		assembly_item_id	= p_cnv_rtgntwrk_table(indx).assembly_item_id,
		organization_id		= p_cnv_rtgntwrk_table(indx).organization_id,
		organization_code       = p_cnv_rtgntwrk_table(indx).organization_code,
		assembly_item_number    = p_cnv_rtgntwrk_table(indx).assembly_item_number,
		transaction_type        = p_cnv_rtgntwrk_table(indx).transaction_type,
		planning_pct            = p_cnv_rtgntwrk_table(indx).planning_pct,
		error_mesg              = p_cnv_rtgntwrk_table(indx).error_mesg,
		attribute11		= G_BATCH_ID
	     WHERE record_number = p_cnv_rtgntwrk_table(indx).record_number
	       AND batch_id = G_BATCH_ID;
	END LOOP;

	COMMIT;
    END update_int_records_ntwrk;

    --**********************************************************************
    --	    Procedure to update Operation Resources staging records
    --**********************************************************************

    PROCEDURE update_int_records_res (p_cnv_rtgres_table IN g_xx_op_res_tab_type)
	IS
	x_last_update_date      DATE := SYSDATE;
	x_last_updated_by       NUMBER := fnd_global.user_id;
	x_last_update_login     NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
	indx			NUMBER;

	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
	g_api_name := 'main.update_int_records_res';

	FOR indx IN 1 .. p_cnv_rtgres_table.COUNT LOOP

	  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_rtgres_table(indx).process_code ' || p_cnv_rtgres_table(indx).process_code);
	  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_rtgres_table(indx).error_code ' || p_cnv_rtgres_table(indx).error_code);

	UPDATE xx_bom_rtg_res_stg
	   SET  resource_seq_num	= p_cnv_rtgres_table(indx).resource_seq_num,
		resource_id		= p_cnv_rtgres_table(indx).resource_id,
		assigned_units		= p_cnv_rtgres_table(indx).assigned_units,
		usage_rate_or_amount    = p_cnv_rtgres_table(indx).usage_rate_or_amount,
		basis_type		= p_cnv_rtgres_table(indx).basis_type,
		schedule_flag		= p_cnv_rtgres_table(indx).schedule_flag,
		last_update_date        = p_cnv_rtgres_table(indx).last_update_date,
		last_updated_by         = p_cnv_rtgres_table(indx).last_updated_by,
		creation_date           = p_cnv_rtgres_table(indx).creation_date,
		created_by              = p_cnv_rtgres_table(indx).created_by,
		last_update_login       = p_cnv_rtgres_table(indx).last_update_login,
		autocharge_type         = p_cnv_rtgres_table(indx).autocharge_type,
		request_id              = p_cnv_rtgres_table(indx).request_id,
		program_application_id  = p_cnv_rtgres_table(indx).program_application_id,
		program_id              = p_cnv_rtgres_table(indx).program_id,
		program_update_date     = p_cnv_rtgres_table(indx).program_update_date,
		assembly_item_id        = p_cnv_rtgres_table(indx).assembly_item_id,
		organization_id		= p_cnv_rtgres_table(indx).organization_id,
		operation_seq_num       = p_cnv_rtgres_table(indx).operation_seq_num,
		effectivity_date	= p_cnv_rtgres_table(indx).effectivity_date,
		routing_sequence_id     = p_cnv_rtgres_table(indx).routing_sequence_id,
		organization_code	= p_cnv_rtgres_table(indx).organization_code,
		assembly_item_number    = p_cnv_rtgres_table(indx).assembly_item_number,
		resource_code           = p_cnv_rtgres_table(indx).resource_code,
		transaction_id		= p_cnv_rtgres_table(indx).transaction_id,
		process_flag            = p_cnv_rtgres_table(indx).process_flag,
		transaction_type        = p_cnv_rtgres_table(indx).transaction_type,
		--batch_id                = p_cnv_rtgres_table(indx).batch_id, -- DS:17Sep12
		error_code              = p_cnv_rtgres_table(indx).error_code,
		error_type              = p_cnv_rtgres_table(indx).error_type,
		error_explanation       = p_cnv_rtgres_table(indx).error_explanation,
		error_flag              = p_cnv_rtgres_table(indx).error_flag,
		process_code            = p_cnv_rtgres_table(indx).process_code,
		error_mesg              = p_cnv_rtgres_table(indx).error_mesg,
		attribute11		          = G_BATCH_ID,
		operation_sequence_id   = p_cnv_rtgres_table(indx).operation_sequence_id
	     WHERE record_number = p_cnv_rtgres_table(indx).record_number
	       AND batch_id = G_BATCH_ID;  -- DS:17Sep12
	END LOOP;

	COMMIT;
    END update_int_records_res;

    --**********************************************************************
    --		Procedure to mark records complete for Routing Header
    --**********************************************************************

    PROCEDURE mark_records_complete (
	p_process_code	VARCHAR2,
	p_entity	VARCHAR2
       ) IS
	x_last_update_date       DATE   := SYSDATE;
	x_last_updated_by        NUMBER := fnd_global.user_id;
	x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
	g_api_name := 'main.mark_records_complete';

	IF p_entity = 'RTG' THEN
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'10');--**DS
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of mark records complete for Routing Header...');

	    UPDATE xx_bom_rtg_hdr_stg	--Header
	       SET process_code      = G_STAGE,
		   error_code        = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
		   last_updated_by   = x_last_updated_by,
		   last_update_date  = x_last_update_date,
		   last_update_login = x_last_update_login
	     WHERE batch_id     = G_BATCH_ID
	       AND request_id   = xx_emf_pkg.G_REQUEST_ID
	       AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
	       AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

	ELSIF p_entity = 'OPR' THEN
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'20');--**DS
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of mark records complete for Operation Sequence...');

	    UPDATE xx_bom_rtg_op_stg
	       SET process_code1      = G_STAGE,
		   error_code        = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
		   last_updated_by   = x_last_updated_by,
		   last_update_date  = x_last_update_date,
		   last_update_login = x_last_update_login
	     WHERE batch_id     = G_BATCH_ID
	       AND request_id   = xx_emf_pkg.G_REQUEST_ID
	       AND process_code1 = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
	       AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

	ELSIF p_entity = 'RES' THEN
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'30');--**DS
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of mark records complete for Operation Resources...');

	    UPDATE xx_bom_rtg_res_stg
	       SET process_code      = G_STAGE,
		   error_code        = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
		   last_updated_by   = x_last_updated_by,
		   last_update_date  = x_last_update_date,
		   last_update_login = x_last_update_login
	     WHERE batch_id     = G_BATCH_ID
	       AND request_id   = xx_emf_pkg.G_REQUEST_ID
	       AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
	       AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);
	ELSIF p_entity = 'NTWRK' THEN
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of mark records complete for Operation network...');

	    UPDATE xx_bom_op_network_stg
	       SET process_code      = G_STAGE,
		   error_code        = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
		   last_updated_by   = x_last_updated_by,
		   last_update_date  = x_last_update_date,
		   last_update_login = x_last_update_login
	     WHERE batch_id     = G_BATCH_ID
	       AND request_id   = xx_emf_pkg.G_REQUEST_ID
	       AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
	       AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

	END IF;
	COMMIT;

    EXCEPTION
	    WHEN OTHERS THEN
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in Update of mark_records_complete '||SQLERRM);
    END mark_records_complete;

    --**********************************************************************
    --		Function to delete records from Routing Header Interface
    --**********************************************************************

    PROCEDURE xx_delete_grp(p_delete_group_name OUT VARCHAR2, p_description OUT VARCHAR2, p_entity IN VARCHAR2)
    IS
       x_entity_name        VARCHAR2(50):=NULL;
     BEGIN
	g_api_name := 'main.xx_delete_grp';

	IF p_entity = 'RTG' THEN

	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of delete group for Routings...');

	    -- Find delete group for Routings
     	    BEGIN
		SELECT entity_name,delete_group_name,description
		  INTO x_entity_name,p_delete_group_name,p_description
		  FROM BOM_INTERFACE_DELETE_GROUPS
		 WHERE entity_name = 'BOM_OP_ROUTINGS_INTERFACE';
	    EXCEPTION
		 WHEN OTHERS THEN
		    INSERT INTO bom_interface_delete_groups(entity_name,delete_group_name,description)
		    VALUES('BOM_OP_ROUTINGS_INTERFACE','RTGDEL','Routing Header Deletion');

		    COMMIT;
		    dbg_low('Inserting 1st row into into BOM_INTERFACE_DELETE_GROUPS Tables.');
		    p_delete_group_name := 'RTGDEL';
		    p_description := 'Routing Header Deletion';
	    END;

	 ELSIF p_entity = 'OPR' THEN

	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of delete group for Operations...');

	    -- Find delete group for Operations
	    BEGIN
		SELECT entity_name,delete_group_name,description
		  INTO x_entity_name,p_delete_group_name,p_description
		  FROM BOM_INTERFACE_DELETE_GROUPS
		 WHERE entity_name = 'BOM_OP_SEQUENCES_INTERFACE';
	     EXCEPTION
		 WHEN OTHERS THEN
		    INSERT INTO bom_interface_delete_groups(entity_name,delete_group_name,description)
		    VALUES('BOM_OP_SEQUENCES_INTERFACE','OPRDEL','Operation Deletion');

		    COMMIT;
		    dbg_low('Inserting 1st row into into BOM_INTERFACE_DELETE_GROUPS Tables.');
		    p_delete_group_name := 'OPRDEL';
		    p_description := 'Operation Deletion';
	     END;

	 ELSIF p_entity = 'RES' THEN

	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of delete group for Resources...');

	    -- Find delete group for header
	    BEGIN
		SELECT entity_name,delete_group_name,description
		  INTO x_entity_name,p_delete_group_name,p_description
		  FROM BOM_INTERFACE_DELETE_GROUPS
		 WHERE entity_name = 'BOM_OP_SEQUENCES_INTERFACE';
	    EXCEPTION
		 WHEN OTHERS THEN
		    INSERT INTO bom_interface_delete_groups(entity_name,delete_group_name,description)
		    VALUES('BOM_OP_RESOURCES_INTERFACE','RESDEL','Resource Deletion');

		    COMMIT;
		    dbg_low('Inserting 1st row into into BOM_INTERFACE_DELETE_GROUPS Tables.');
		    p_delete_group_name := 'RESDEL';
		    p_description := 'Resource Deletion';
	    END;

	 END IF;
   END xx_delete_grp;

    --**********************************************************************
    --		Function to insert records into Routing Interface
    --**********************************************************************

    FUNCTION xx_insert_interface(p_trans_type VARCHAR2, p_entity VARCHAR2)
     RETURN NUMBER
    IS
	x_return_status		VARCHAR2(15) := xx_emf_cn_pkg.CN_SUCCESS;

	x_rtg_del_grp		VARCHAR2(10)  := NULL;
	x_rtg_del_desc		VARCHAR2(240) := NULL;
	x_opr_del_grp		VARCHAR2(10)  := NULL;
	x_opr_del_desc		VARCHAR2(240) := NULL;
	x_cmmit_header		NUMBER :=0;
	x_cmmit_comp		NUMBER :=0;

	--cursor to insert into Item Routing interface table
	CURSOR c_xx_itemrtg_intupld(cp_process_status VARCHAR2) IS
         SELECT *
           FROM xx_bom_rtg_hdr_stg
          WHERE batch_id     = G_BATCH_ID
	    AND request_id   = xx_emf_pkg.G_REQUEST_ID
	    AND process_code = cp_process_status
	    AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
	  ORDER BY record_number;

	--cursor to insert into Operation interface table
	CURSOR c_xx_rtgop_intupld(cp_process_status VARCHAR2) IS
         SELECT *
           FROM xx_bom_rtg_op_stg
          WHERE batch_id     = G_BATCH_ID
	    AND request_id   = xx_emf_pkg.G_REQUEST_ID
	    AND process_code1 = cp_process_status
	    AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
	  ORDER BY record_number;

	--cursor to insert into Resource interface table
	CURSOR c_xx_rtgres_intupld(cp_process_status VARCHAR2) IS
         SELECT *
           FROM xx_bom_rtg_res_stg
          WHERE batch_id     = G_BATCH_ID
	    AND request_id   = xx_emf_pkg.G_REQUEST_ID
	    AND process_code = cp_process_status
	    AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
	  ORDER BY record_number;

	--cursor to insert into network interface table Wave2
	CURSOR c_xx_rtgntwrk_intupld(cp_process_status VARCHAR2) IS
         SELECT *
           FROM xx_bom_op_network_stg nstg
          WHERE nstg.batch_id     = G_BATCH_ID
	    AND nstg.request_id   = xx_emf_pkg.G_REQUEST_ID
	    AND nstg.process_code = cp_process_status
	    AND nstg.error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
	    AND EXISTS ( SELECT 'X'
	                   FROM xx_bom_rtg_hdr_stg hstg
	                  WHERE hstg.batch_id     = G_BATCH_ID
	                    AND hstg.assembly_item_id = nstg.assembly_item_id
	                    AND hstg.organization_id = nstg.organization_id
	                    AND hstg.cfm_routing_flag = 3
	                 )
	  ORDER BY record_number;

	  x_process_code  varchar2(30);
	  x_error_code	    number;

    BEGIN
      g_api_name := 'main.xx_insert_interface';

      x_rtg_del_grp  := NULL;
      x_rtg_del_desc := NULL;
      x_opr_del_grp  := NULL;
      x_opr_del_desc := NULL;
      g_opr_del_grp  := NULL;
      g_rtg_del_grp  := NULL;

      IF p_trans_type = g_trans_type_delete THEN
         dbg_low('Transaction type is :'||p_trans_type);
         xx_delete_grp(x_rtg_del_grp,x_rtg_del_desc, 'RTG');
         g_rtg_del_grp := x_rtg_del_grp;
         dbg_low('Routing Header delete group is: '||g_rtg_del_grp||' ,delete group desc is: '||x_rtg_del_desc);
         xx_delete_grp(x_opr_del_grp,x_opr_del_desc, 'OPR');
         g_opr_del_grp := x_opr_del_grp;
         dbg_low('Operations delete group is: '||g_opr_del_grp||' ,delete group desc is: '||x_opr_del_desc);
      END IF;

      IF p_entity = 'RTG' THEN

	  FOR c_xx_intupld_rec IN c_xx_itemrtg_intupld(xx_emf_cn_pkg.CN_POSTVAL)
	  LOOP
	      x_cmmit_header := x_cmmit_header + 1;

	      INSERT INTO bom_op_routings_interface
			    (organization_code,
			     assembly_item_number,
			     --assembly_item_id,
			     --organization_id,
			     completion_subinventory,
			     completion_locator_id,
			     --alternate_routing_designator,
			     routing_type,
			     process_flag,
			     transaction_type,
			     delete_group_name ,
			     dg_description,
			     last_update_date,
			     last_updated_by,
			     creation_date,
			     created_by,
			     attribute11,
			     routing_sequence_id,
			     cfm_routing_flag  --Added as per Wave2
			    )
		     VALUES (c_xx_intupld_rec.organization_code,
			     c_xx_intupld_rec.assembly_item_number,
			     --c_xx_intupld_rec.assembly_item_id,
			     --c_xx_intupld_rec.organization_id,
			     c_xx_intupld_rec.completion_subinventory,
			     c_xx_intupld_rec.completion_locator_id,
			     --c_xx_intupld_rec.alternate_routing_designator,
			     to_number(c_xx_intupld_rec.routing_type),
			     g_process_flag,
			     p_trans_type,
			     x_rtg_del_grp ,
			     x_rtg_del_desc,
			     c_xx_intupld_rec.last_update_date,
			     c_xx_intupld_rec.last_updated_by,
			     c_xx_intupld_rec.creation_date,
			     c_xx_intupld_rec.created_by,
			     G_BATCH_ID,
			     c_xx_intupld_rec.routing_sequence_id,
			     c_xx_intupld_rec.cfm_routing_flag
			    );

	     IF x_cmmit_header >= 10000 THEN -- Commit for every 10000 record as per review comment
		COMMIT;
	     END IF;
	  END LOOP;

      ELSIF p_entity = 'OPR' THEN

	  FOR c_xx_intupld_rec IN c_xx_rtgop_intupld(xx_emf_cn_pkg.CN_POSTVAL)
	  LOOP
	      x_cmmit_header := x_cmmit_header + 1;

	      INSERT INTO bom_op_sequences_interface
			    (assembly_item_number,
			     organization_code,
			     --alternate_routing_designator,
			     operation_seq_num,
			     --operation_code,
			     department_code,
			     --operation_type,
			     implementation_date,
			     effectivity_date,
			     --disable_date,
			     backflush_flag,
			     --minimum_transfer_quantity,
			     --count_point_type,
			     --yield,
			     --cumulative_yield,
			     --include_in_rollup,
			     operation_description,
			     process_flag,
			     transaction_type,
			     --reference_flag,
			     --attribute1,
			     --attribute2,
			     --attribute3,
			     --attribute4,
			     delete_group_name ,
			     dg_description,
			     last_update_date,
			     last_updated_by,
			     creation_date,
			     created_by,
			     attribute11,
			     routing_sequence_id,
			     operation_sequence_id,
			     yield                             --Added as per Wave2
			    ,standard_operation_id             --Added as per Wave2
			    )
		     VALUES (c_xx_intupld_rec.assembly_item_number,
			     c_xx_intupld_rec.organization_code,
			     --c_xx_intupld_rec.alternate_routing_designator,
			     c_xx_intupld_rec.operation_seq_num,
			     --c_xx_intupld_rec.operation_code,
			     c_xx_intupld_rec.department_code,
			     --c_xx_intupld_rec.operation_type,
			     c_xx_intupld_rec.implementation_date,
			     c_xx_intupld_rec.effectivity_date,
			     --c_xx_intupld_rec.disable_date,
			     c_xx_intupld_rec.backflush_flag,
			     --c_xx_intupld_rec.minimum_transfer_quantity,
			     --c_xx_intupld_rec.count_point_type,
			     --c_xx_intupld_rec.yield,
			     --c_xx_intupld_rec.cumulative_yield,
			     --c_xx_intupld_rec.include_in_rollup,
			     c_xx_intupld_rec.operation_description,
			     g_process_flag,
			     g_transaction_type,
			     --c_xx_intupld_rec.reference_flag,
			     --c_xx_intupld_rec.attribute1,
			     --c_xx_intupld_rec.attribute2,
			     --c_xx_intupld_rec.attribute3,
			     --c_xx_intupld_rec.attribute4,
			     x_opr_del_grp ,
			     x_opr_del_desc,
			     c_xx_intupld_rec.last_update_date,
			     c_xx_intupld_rec.last_updated_by,
			     c_xx_intupld_rec.creation_date,
			     c_xx_intupld_rec.created_by,
			     G_BATCH_ID,
			     c_xx_intupld_rec.routing_sequence_id,
			     c_xx_intupld_rec.operation_sequence_id,
			     c_xx_intupld_rec.yield,
			     c_xx_intupld_rec.standard_operation_id
			    );

	     IF x_cmmit_header >= 10000 THEN -- Commit for every 10000 record as per review comment
		COMMIT;
	     END IF;
	  END LOOP;

      ELSIF p_entity = 'RES' THEN

	  FOR c_xx_intupld_rec IN c_xx_rtgres_intupld(xx_emf_cn_pkg.CN_POSTVAL)
	  LOOP
    	      x_cmmit_header := x_cmmit_header + 1;

	      INSERT INTO bom_op_resources_interface
			    (organization_code,
			     assembly_item_number,
			     --alternate_routing_designator,	    --
			     operation_seq_num,
			     resource_seq_num,
			     resource_code,
			     basis_type,
			     usage_rate_or_amount,
			     assigned_units,
			     --standard_rate_flag,		    --
			     schedule_flag,
			     effectivity_date,
			     autocharge_type,
			     --resource_offset_percent,	    --
			     --principle_flag,		    --
			     process_flag,
			     transaction_type,
			     last_update_date,
			     last_updated_by,
			     creation_date,
			     created_by,
			     attribute11,
			     operation_sequence_id,
			     schedule_seq_num                         --Added as per Wave2
			    )
		     VALUES (c_xx_intupld_rec.organization_code,
			     c_xx_intupld_rec.assembly_item_number,
			     --c_xx_intupld_rec.alternate_routing_designator,	    --
			     c_xx_intupld_rec.operation_seq_num,
			     c_xx_intupld_rec.resource_seq_num,
			     c_xx_intupld_rec.resource_code,
			     c_xx_intupld_rec.basis_type,
			     c_xx_intupld_rec.usage_rate_or_amount,
			     c_xx_intupld_rec.assigned_units,
			     --c_xx_intupld_rec.standard_rate_flag,		    --
			     c_xx_intupld_rec.schedule_flag,
			     c_xx_intupld_rec.effectivity_date,
			     c_xx_intupld_rec.autocharge_type,
			     --c_xx_intupld_rec.resource_offset_percent,	    --
			     --c_xx_intupld_rec.principle_flag,		    --
			     g_process_flag,
			     g_transaction_type,
			     c_xx_intupld_rec.last_update_date,
			     c_xx_intupld_rec.last_updated_by,
			     c_xx_intupld_rec.creation_date,
			     c_xx_intupld_rec.created_by,
			     G_BATCH_ID,
			     c_xx_intupld_rec.operation_sequence_id,
			     c_xx_intupld_rec.schedule_seq_num
			    );

	     IF x_cmmit_header >= 10000 THEN -- Commit for every 10000 record as per review comment
		COMMIT;
	     END IF;
	  END LOOP;
      ELSIF p_entity = 'NTWRK' THEN  --Added as per Wave2

	  FOR r_xx_intupld_rec IN c_xx_rtgntwrk_intupld(xx_emf_cn_pkg.CN_POSTVAL)
	  LOOP
	      x_cmmit_header := x_cmmit_header + 1;

	      INSERT INTO bom_op_networks_interface
			    (
			     --FROM_OP_SEQ_ID
                            --,TO_OP_SEQ_ID
                             TRANSITION_TYPE
                            ,PLANNING_PCT
                            ,OPERATION_TYPE
                            ,LAST_UPDATE_DATE
                            ,LAST_UPDATED_BY
                            ,CREATION_DATE
                            ,CREATED_BY
                            ,LAST_UPDATE_LOGIN
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
                            ,ATTRIBUTE11
                            ,ATTRIBUTE12
                            ,ATTRIBUTE13
                            ,ATTRIBUTE14
                            ,ATTRIBUTE15
                            ,FROM_X_COORDINATE
                            ,TO_X_COORDINATE
                            ,FROM_Y_COORDINATE
                            ,TO_Y_COORDINATE
                            ,FROM_OP_SEQ_NUMBER
                            ,TO_OP_SEQ_NUMBER
                            ,FROM_START_EFFECTIVE_DATE
                            ,TO_START_EFFECTIVE_DATE
                            ,NEW_FROM_OP_SEQ_NUMBER
                            ,NEW_TO_OP_SEQ_NUMBER
                            ,NEW_FROM_START_EFFECTIVE_DATE
                            ,NEW_TO_START_EFFECTIVE_DATE
                            ,ASSEMBLY_ITEM_ID
                            ,ALTERNATE_ROUTING_DESIGNATOR
                            ,ORGANIZATION_ID
                            ,ROUTING_SEQUENCE_ID
                            ,ORGANIZATION_CODE
                            ,ASSEMBLY_ITEM_NUMBER
                            ,ORIGINAL_SYSTEM_REFERENCE
                            ,TRANSACTION_ID
                            ,PROCESS_FLAG
                            ,TRANSACTION_TYPE
			    )
		     VALUES (
		             --r_xx_intupld_rec.FROM_OP_SEQ_ID
                            --,r_xx_intupld_rec.TO_OP_SEQ_ID
                             r_xx_intupld_rec.TRANSITION_TYPE
                            ,r_xx_intupld_rec.PLANNING_PCT
                            ,r_xx_intupld_rec.OPERATION_TYPE
                            ,r_xx_intupld_rec.LAST_UPDATE_DATE
                            ,r_xx_intupld_rec.LAST_UPDATED_BY
                            ,r_xx_intupld_rec.CREATION_DATE
                            ,r_xx_intupld_rec.CREATED_BY
                            ,r_xx_intupld_rec.LAST_UPDATE_LOGIN
                            ,r_xx_intupld_rec.ATTRIBUTE_CATEGORY
                            ,r_xx_intupld_rec.ATTRIBUTE1
                            ,r_xx_intupld_rec.ATTRIBUTE2
                            ,r_xx_intupld_rec.ATTRIBUTE3
                            ,r_xx_intupld_rec.ATTRIBUTE4
                            ,r_xx_intupld_rec.ATTRIBUTE5
                            ,r_xx_intupld_rec.ATTRIBUTE6
                            ,r_xx_intupld_rec.ATTRIBUTE7
                            ,r_xx_intupld_rec.ATTRIBUTE8
                            ,r_xx_intupld_rec.ATTRIBUTE9
                            ,r_xx_intupld_rec.ATTRIBUTE10
                            ,G_BATCH_ID
                            ,r_xx_intupld_rec.ATTRIBUTE12
                            ,r_xx_intupld_rec.ATTRIBUTE13
                            ,r_xx_intupld_rec.ATTRIBUTE14
                            ,r_xx_intupld_rec.ATTRIBUTE15
                            ,r_xx_intupld_rec.FROM_X_COORDINATE
                            ,r_xx_intupld_rec.TO_X_COORDINATE
                            ,r_xx_intupld_rec.FROM_Y_COORDINATE
                            ,r_xx_intupld_rec.TO_Y_COORDINATE
                            ,r_xx_intupld_rec.FROM_OP_SEQ_ID  --FROM_OP_SEQ_NUMBER
                            ,r_xx_intupld_rec.TO_OP_SEQ_ID    --TO_OP_SEQ_NUMBER
                            ,TRUNC(SYSDATE)--,r_xx_intupld_rec.FROM_START_EFFECTIVE_DATE
                            ,TRUNC(SYSDATE)--,r_xx_intupld_rec.TO_START_EFFECTIVE_DATE
                            ,r_xx_intupld_rec.NEW_FROM_OP_SEQ_NUMBER
                            ,r_xx_intupld_rec.NEW_TO_OP_SEQ_NUMBER
                            ,r_xx_intupld_rec.NEW_FROM_START_EFFECTIVE_DATE
                            ,r_xx_intupld_rec.NEW_TO_START_EFFECTIVE_DATE
                            ,r_xx_intupld_rec.ASSEMBLY_ITEM_ID
                            ,r_xx_intupld_rec.ALTERNATE_ROUTING_DESIGNATOR
                            ,r_xx_intupld_rec.ORGANIZATION_ID
                            ,r_xx_intupld_rec.ROUTING_SEQUENCE_ID
                            ,r_xx_intupld_rec.ORGANIZATION_CODE
                            ,r_xx_intupld_rec.ASSEMBLY_ITEM_NUMBER
                            ,r_xx_intupld_rec.ORIGINAL_SYSTEM_REFERENCE
                            ,r_xx_intupld_rec.TRANSACTION_ID
                            ,g_process_flag
                            ,g_transaction_type
			    );

	     IF x_cmmit_header >= 10000 THEN -- Commit for every 10000 record as per review comment
		COMMIT;
		x_cmmit_header := 0;
	     END IF;
	  END LOOP;
	  COMMIT;
      END IF;
      RETURN x_return_status;
    EXCEPTION
	WHEN OTHERS THEN
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while inserting into Standard Interface Tables: ' ||SQLERRM);
	    xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
	    x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
	    RETURN x_error_code;
    END xx_insert_interface;

    --**********************************************************************
    --	Procedure to mark Routing Header records for interface error
    --**********************************************************************

    PROCEDURE mark_records_for_int_error(p_process_code IN VARCHAR2)
	IS
	x_last_update_date       DATE := SYSDATE;
	x_last_updated_by        NUMBER := fnd_global.user_id;
	x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
	x_record_count           NUMBER;

	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside Mark Record for Routing Header Interface Error');
       UPDATE xx_bom_rtg_hdr_stg xbr
	 SET process_code = G_STAGE,
	     error_code   = xx_emf_cn_pkg.CN_REC_ERR,
	     error_mesg   ='INTERFACE Error : Errored out inside BOM_OP_ROUTINGS_INTERFACE',
	     last_updated_by   = x_last_updated_by,
	     last_update_date  = x_last_update_date,
	     last_update_login = x_last_update_login
       WHERE batch_id    = G_BATCH_ID
	 AND process_code  = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
				    , xx_emf_cn_pkg.CN_POSTVAL
				    , xx_emf_cn_pkg.CN_DERIVE
				    )
	 AND error_code    IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
	 AND Exists (SELECT 1
		       FROM bom_op_routings_interface bri
		      WHERE 1=1
			AND bri.assembly_item_number    = xbr.assembly_item_number
			AND bri.organization_id = xbr.organization_id
			AND bri.attribute11=xbr.batch_id
			AND xbr.batch_id = G_BATCH_ID
			AND bri.process_flag <> 7
		     );

	x_record_count := SQL%ROWCOUNT;
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No of Record Marked with Routing Header Interface Error=>'||x_record_count);

	x_record_count := 0;
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside Mark Record for Operations Interface Error');
	UPDATE xx_bom_rtg_op_stg xbr
	   SET process_code = G_STAGE,
	       error_code   = xx_emf_cn_pkg.CN_REC_ERR,
	       error_mesg   ='INTERFACE Error : Errored out inside BOM_OP_SEQUENCES_INTERFACE',
	       last_updated_by   = x_last_updated_by,
	       last_update_date  = x_last_update_date,
	       last_update_login = x_last_update_login
	 WHERE batch_id    = G_BATCH_ID
	   AND process_code  = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
				    , xx_emf_cn_pkg.CN_POSTVAL
				    , xx_emf_cn_pkg.CN_DERIVE
				    )
	   AND error_code    IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
	   AND Exists (SELECT 1
		       FROM bom_op_sequences_interface bri
		      WHERE 1=1
			AND bri.assembly_item_number    = xbr.assembly_item_number
			AND bri.organization_id     = xbr.organization_id
      AND bri.operation_seq_num   = xbr.operation_seq_num
			AND bri.attribute11=xbr.batch_id
			AND xbr.batch_id = G_BATCH_ID
			AND bri.process_flag <> 7
		     );

	x_record_count := SQL%ROWCOUNT;
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No of Record Marked with Operations Interface Error=>'||x_record_count);

	x_record_count := 0;
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside Mark Record for Resources Interface Error');
	UPDATE xx_bom_rtg_res_stg xbr
	   SET process_code = G_STAGE,
	       error_code   = xx_emf_cn_pkg.CN_REC_ERR,
	       error_mesg   ='INTERFACE Error : Errored out inside BOM_OP_RESOURCES_INTERFACE',
	       last_updated_by   = x_last_updated_by,
	       last_update_date  = x_last_update_date,
	       last_update_login = x_last_update_login
	 WHERE batch_id    = G_BATCH_ID
	   AND process_code  = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
				    , xx_emf_cn_pkg.CN_POSTVAL
				    , xx_emf_cn_pkg.CN_DERIVE
				    )
	   AND error_code    IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
	   AND Exists (SELECT 1
		       FROM bom_op_resources_interface bri
		      WHERE 1=1
			AND bri.assembly_item_number    = xbr.assembly_item_number
      AND bri.resource_code = xbr.resource_code
      AND bri.resource_seq_num = xbr.resource_seq_num
      AND bri.operation_seq_num = xbr.operation_seq_num
			AND bri.organization_id = xbr.organization_id
			AND bri.attribute11=xbr.batch_id
			AND xbr.batch_id = G_BATCH_ID
			AND bri.process_flag <> 7
		     );

	x_record_count := SQL%ROWCOUNT;
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No of Record Marked with networks Interface Error=>'||x_record_count);

	--Added as per Wave2
	x_record_count := 0;
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside Mark Record for networks Interface Error');

       UPDATE xx_bom_op_network_stg xbr
	 SET process_code = G_STAGE,
	     error_code   = xx_emf_cn_pkg.CN_REC_ERR,
	     error_mesg   ='INTERFACE Error : Errored out inside BOM_OP_NETWORKS_INTERFACE',
	     last_updated_by   = x_last_updated_by,
	     last_update_date  = x_last_update_date,
	     last_update_login = x_last_update_login
       WHERE batch_id    = G_BATCH_ID
	 AND process_code  = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
				    , xx_emf_cn_pkg.CN_POSTVAL
				    , xx_emf_cn_pkg.CN_DERIVE
				    )
	 AND error_code    IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
	 AND Exists (SELECT 1
		       FROM bom_op_networks_interface bri
		      WHERE 1=1
			AND bri.assembly_item_number    = xbr.assembly_item_number
			AND bri.organization_id = xbr.organization_id
			AND bri.attribute11=xbr.batch_id
			AND xbr.batch_id = G_BATCH_ID
			AND bri.process_flag <> 7
		     );

	x_record_count := SQL%ROWCOUNT;
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No of Record Marked with networks Interface Error=>'||x_record_count);

        COMMIT;
    END mark_records_for_int_error;

    --**********************************************************************
    --	Procedure to print records with interface error
    --**********************************************************************
    PROCEDURE print_recs_with_int_error
	IS
         CURSOR cur_print_error_rtg_rec
           IS
         SELECT xbr.assembly_item_number
	       ,xbr.organization_code
	       ,xbr.error_code
	       ,trim(translate(mie.message_name||':'||mie.error_message,CHR(13)||CHR(10)||CHR(9),'   ')) error_mesg --xbr.error_mesg
	       ,xbr.record_number
	  FROM bom_op_routings_interface bri
	      ,xx_bom_rtg_hdr_stg xbr
        ,mtl_interface_errors mie
	 WHERE bri.assembly_item_number    = xbr.assembly_item_number
           AND bri.organization_id = xbr.organization_id
           AND bri.attribute11=xbr.batch_id
           AND mie.transaction_id = bri.transaction_id
           AND mie.request_id = bri.request_id
           AND xbr.batch_id = G_BATCH_ID
	   AND bri.process_flag <> 7;

         CURSOR cur_print_error_op_rec
           IS
         SELECT xbr.assembly_item_number
	       ,xbr.organization_code
	       ,xbr.error_code
	       ,trim(translate(mie.message_name||':'||mie.error_message,CHR(13)||CHR(10)||CHR(9),'   ')) error_mesg --xbr.error_mesg
	       ,xbr.record_number
	  FROM bom_op_sequences_interface bri
	      ,xx_bom_rtg_op_stg xbr
        ,mtl_interface_errors mie
	 WHERE bri.assembly_item_number    = xbr.assembly_item_number
           AND bri.organization_id = xbr.organization_id
           AND bri.operation_seq_num   = xbr.operation_seq_num
           AND mie.transaction_id = bri.transaction_id
           AND mie.request_id = bri.request_id
           AND bri.attribute11=xbr.batch_id
           AND xbr.batch_id = G_BATCH_ID
	   AND bri.process_flag <> 7;

         CURSOR cur_print_error_res_rec
           IS
         SELECT xbr.assembly_item_number
	       ,xbr.organization_code
	       ,xbr.error_code
	       ,trim(translate(mie.message_name||':'||mie.error_message,CHR(13)||CHR(10)||CHR(9),'   ')) error_mesg --,mie.error_mesg
	       ,xbr.record_number
	  FROM bom_op_resources_interface bri
	      ,xx_bom_rtg_res_stg xbr
        ,mtl_interface_errors mie
	 WHERE  bri.assembly_item_number    = xbr.assembly_item_number
      AND bri.resource_code = xbr.resource_code
      AND bri.resource_seq_num = xbr.resource_seq_num
      AND bri.operation_seq_num = xbr.operation_seq_num
			AND bri.organization_id = xbr.organization_id
      AND mie.transaction_id = bri.transaction_id
      AND mie.request_id = bri.request_id
			AND bri.attribute11=xbr.batch_id
			AND xbr.batch_id = G_BATCH_ID
			AND bri.process_flag <> 7 ;

         CURSOR cur_print_error_ntwrk_rec
           IS
         SELECT xbr.assembly_item_number
	       ,xbr.organization_code
	       ,xbr.error_code
	       ,trim(translate(mie.message_name||':'||mie.error_message,CHR(13)||CHR(10)||CHR(9),'   ')) error_mesg --,mie.error_mesg
	       ,xbr.record_number
	  FROM bom_op_networks_interface bri
	      ,xx_bom_op_network_stg xbr
        ,mtl_interface_errors mie
	 WHERE  bri.assembly_item_number    = xbr.assembly_item_number
			AND bri.organization_id = xbr.organization_id
      AND mie.transaction_id = bri.transaction_id
      AND mie.request_id = bri.request_id
			AND bri.attribute11=xbr.batch_id
			AND xbr.batch_id = G_BATCH_ID
			AND bri.process_flag <> 7 ;

    BEGIN
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside print_recs_with_int_error');
          FOR cur_rtg_rec IN cur_print_error_rtg_rec
           LOOP
	       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
				,p_category    => xx_emf_cn_pkg.CN_STG_APICALL
				,p_error_text  => cur_rtg_rec.error_code||'-'||cur_rtg_rec.error_mesg
				,p_record_identifier_1 => cur_rtg_rec.record_number
				,p_record_identifier_2 => cur_rtg_rec.organization_code
				,p_record_identifier_3 => cur_rtg_rec.assembly_item_number
				);
	   END LOOP;

          FOR cur_op_rec IN cur_print_error_op_rec
           LOOP
	       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
				,p_category    => xx_emf_cn_pkg.CN_STG_APICALL
				,p_error_text  => cur_op_rec.error_code||'-'||cur_op_rec.error_mesg
				,p_record_identifier_1 => cur_op_rec.record_number
				,p_record_identifier_2 => cur_op_rec.organization_code
				,p_record_identifier_3 => cur_op_rec.assembly_item_number
				);
	   END LOOP;

          FOR cur_res_rec IN cur_print_error_res_rec
           LOOP
	       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
				,p_category    => xx_emf_cn_pkg.CN_STG_APICALL
				,p_error_text  => cur_res_rec.error_code||'-'||cur_res_rec.error_mesg
				,p_record_identifier_1 => cur_res_rec.record_number
				,p_record_identifier_2 => cur_res_rec.organization_code
				,p_record_identifier_3 => cur_res_rec.assembly_item_number
				);
	   END LOOP;
          --Added as per Wave2
          FOR cur_res_rec IN cur_print_error_ntwrk_rec
           LOOP
	       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
				,p_category    => xx_emf_cn_pkg.CN_STG_APICALL
				,p_error_text  => cur_res_rec.error_code||'-'||cur_res_rec.error_mesg
				,p_record_identifier_1 => cur_res_rec.record_number
				,p_record_identifier_2 => cur_res_rec.organization_code
				,p_record_identifier_3 => cur_res_rec.assembly_item_number
				);
	   END LOOP;

    END print_recs_with_int_error;

    --**********************************************************************
    --	Procedure to submit Delete Item Information Interface program
    --**********************************************************************
    PROCEDURE xx_itemrtg_delete IS

        --Variable Declaration
      l_completed           BOOLEAN;
      l_phase               VARCHAR2(200);
      l_vstatus             VARCHAR2(200);
      l_dev_phase           VARCHAR2(200);
      l_dev_status          VARCHAR2(200);
      l_message             VARCHAR2(2000);
      l_standard_request_id NUMBER;
      x_del_grp_seq_id      NUMBER := NULL;
      x_del_cmpgrp_seq_id   NUMBER := NULL;

      -- Routing Header Cursor for deletion
      CURSOR c_xx_itemrtg_del ( cp_process_status VARCHAR2)
       IS
       SELECT distinct organization_id
          FROM xx_bom_rtg_hdr_stg
        WHERE batch_id     = G_BATCH_ID
          AND request_id   = xx_emf_pkg.G_REQUEST_ID
          AND process_code = cp_process_status
          AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         ORDER BY organization_id;

       -- Routing Operation Sequences for deletion
       CURSOR c_xx_rtgop_del ( cp_process_status VARCHAR2)
       IS
       SELECT distinct organization_id
          FROM xx_bom_rtg_op_stg
        WHERE batch_id     = G_BATCH_ID
          AND request_id   = xx_emf_pkg.G_REQUEST_ID
          AND process_code1 = cp_process_status
          AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         ORDER BY organization_id;


    BEGIN
      g_api_name := 'main.xx_itemrtg_delete';

      dbg_low('Inside deleting Item Routings Procedure');

      -- Deleting Item Routing Header
      dbg_low('Deletion of Item Routing Headers');

      FOR c_xx_itemrtg_del_rec IN c_xx_itemrtg_del(xx_emf_cn_pkg.CN_POSTVAL)
      LOOP
        x_del_grp_seq_id := NULL;
        BEGIN

          dbg_low('Submitting Deletion of Routing for org_id: '||c_xx_itemrtg_del_rec.organization_id);
          -- Find delete_group_sequence_id
          SELECT delete_group_sequence_id INTO x_del_grp_seq_id
            FROM BOM_DELETE_GROUPS bdg
             WHERE bdg.organization_id = c_xx_itemrtg_del_rec.organization_id
               AND delete_group_name = g_rtg_del_grp;

           dbg_low('Submitting Deletion of Routing for org_id: '||c_xx_itemrtg_del_rec.organization_id
                                 ||' Delete_group_sequence_id : '||x_del_grp_seq_id
                                 ||' Header Delete group :'|| g_rtg_del_grp);
          BEGIN
                l_standard_request_id := fnd_request.submit_request
                             (application  => 'BOM'
                              ,program     => 'BMCDEL'
                              ,description => 'Delete Item Information'
                              ,argument1   => x_del_grp_seq_id --9007
                              ,argument2   => 2 -- all_org yes = 1
                              ,argument3   => 3
                              );
		COMMIT;
		IF l_standard_request_id > 0 THEN
		    l_completed := fnd_concurrent.wait_for_request(request_id => l_standard_request_id
							      ,INTERVAL   => 30
							      ,max_wait   => 0
							      ,phase      => l_phase
							      ,status     => l_vstatus
							      ,dev_phase  => l_dev_phase
							      ,dev_status => l_dev_status
							      ,message    => l_message);
		    IF l_completed = TRUE THEN
			dbg_low('Delete Item Information Program Completed - Successfully for ORGANIZATION_ID :'||c_xx_itemrtg_del_rec.organization_id|| '=>'||l_dev_status);
		    END IF;
		ELSIF l_standard_request_id = 0 THEN
		    dbg_low('Error in submitting the Delete Item Information Program for ORGANIZATION_ID :'||c_xx_itemrtg_del_rec.organization_id);
		END IF;

          EXCEPTION
	    WHEN OTHERS THEN
	        dbg_low(SUBSTR(SQLERRM,1,255));
          END;

        END;
      END LOOP;

      mark_records_for_int_error(xx_emf_cn_pkg.CN_PROCESS_DATA);
      -- Print the records with API Error
      print_recs_with_int_error;
      x_error_code := xx_emf_cn_pkg.CN_SUCCESS;

    EXCEPTION
        WHEN OTHERS THEN
	    dbg_low('Error in Delete Item Routing Information Program'||SUBSTR(SQLERRM,1,255));
    END xx_itemrtg_delete;

    --**********************************************************************
    --	Procedure to submit Bill and Routing Interface interface program
    --**********************************************************************
    PROCEDURE xx_itemrtg_upload IS
	--Variable Declaration
	x_completed           BOOLEAN;
	x_phase               VARCHAR2(200);
	x_vstatus             VARCHAR2(200);
	x_dev_phase           VARCHAR2(200);
	x_dev_status          VARCHAR2(200);
	x_message             VARCHAR2(2000);
	x_standard_request_id NUMBER;
    BEGIN
	g_api_name := 'main.xx_itemrtg_upload';

	x_standard_request_id := fnd_request.submit_request
                             (application      => 'BOM',
                              program          => 'BMCOIN',
                              description      => 'Bill and Routing Interface',
                              argument1        => fnd_global.org_id,
                              argument2        => 1,      -- all_org yes = 1
                              argument3        => 1,      -- routing yes = 1
                              argument4        => 2,      -- bom     yes = 1
                              argument5        => 2,	  -- delete from inter yes = 1
                              argument6        => NULL
                              );
        COMMIT;
        IF x_standard_request_id > 0 THEN
            x_completed := fnd_concurrent.wait_for_request(request_id => x_standard_request_id
                                                          ,INTERVAL   => 30
                                                          ,max_wait   => 0
                                                          ,phase      => x_phase
                                                          ,status     => x_vstatus
                                                          ,dev_phase  => x_dev_phase
                                                          ,dev_status => x_dev_status
                                                          ,message    => x_message);

            IF x_completed = TRUE THEN
	      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Import Item Routing Program Completed =>'||x_dev_status);
	      mark_records_for_int_error(xx_emf_cn_pkg.CN_PROCESS_DATA);
	      -- Print the records with API Error
	      print_recs_with_int_error;
	      x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
	    END IF;
        ELSIF x_standard_request_id = 0 THEN
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Error in submitting the Import Item Routing Program');

        END IF;

    EXCEPTION
	WHEN OTHERS THEN
	    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND,SUBSTR(SQLERRM,1,255));
    END xx_itemrtg_upload;

    BEGIN
	--Main Begin
	----------------------------------------------------------------------------------------------------
	--Initialize Trace
	--Purpose : Set the program environment for Tracing
	----------------------------------------------------------------------------------------------------

	x_retcode := xx_emf_cn_pkg.CN_SUCCESS;

	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Setting Environment');
	G_TRANSACTION_TYPE := p_transaction_type;
	-- Set Env --
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling Item Routing Set_cnv_env');
	set_cnv_env (p_batch_id,xx_emf_cn_pkg.CN_YES);

        -- include all the parameters to the conversion main here
        -- as medium log messages
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Starting main process with the following parameters');
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_batch_id '	|| p_batch_id);
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_restart_flag '	|| p_restart_flag);
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_validate_and_load '	|| p_validate_and_load);
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_transaction_type '	|| p_transaction_type);

	-- Call procedure to update records with the current request_id
	-- So that we can process only those records
	-- This gives a better handling of restartability
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling mark_records_for_processing..');
	mark_records_for_processing(p_restart_flag => p_restart_flag);

	------------------------------------------------------------------------------
	--	processing for Routing Headers
	------------------------------------------------------------------------------

	-- Set the stage to Pre Validations
	set_stage (xx_emf_cn_pkg.CN_PREVAL);
	-- PRE_VALIDATIONS SHOULD BE RETAINED
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling xx_bom_rtg_cnv_pkg.pre_validations ..');

	x_error_code := xx_bom_rtg_cnv_pkg.pre_validations('RTG');

	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After pre_validations_rtg X_ERROR_CODE ' || X_ERROR_CODE);
	-- Update process code of staging records
	-- Update Header and Lines Level
	update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS, 'RTG');

	xx_emf_pkg.propagate_error ( x_error_code);

	-- Set the stage to data Validations
	set_stage (xx_emf_cn_pkg.CN_VALID);

	OPEN c_xx_itemrtg ( xx_emf_cn_pkg.CN_PREVAL);
	    LOOP
	       	FETCH c_xx_itemrtg
		    BULK COLLECT INTO x_itemrtg_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

		   FOR i IN 1 .. x_itemrtg_table.COUNT
		   LOOP
			BEGIN

			    -- Perform Base App Validations
			    x_error_code := xx_itemrtg_validation(x_itemrtg_table (i));
			    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_itemrtg_table (i).record_number|| ' is ' || x_error_code);
			    update_record_status_rtg (x_itemrtg_table (i), x_error_code);

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
				  update_int_records_rtg ( x_itemrtg_table);
				  RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
			   WHEN OTHERS
			   THEN
				  xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_itemrtg_table (i).record_number);
			END;

		   END LOOP;
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_itemrtg_table.count ' || x_itemrtg_table.COUNT );
		update_int_records_rtg( x_itemrtg_table);
		x_itemrtg_table.DELETE;

		EXIT WHEN c_xx_itemrtg%NOTFOUND;
	    END LOOP;
	IF c_xx_itemrtg%ISOPEN THEN
	    CLOSE c_xx_itemrtg;
	END IF;

	xx_emf_pkg.WRITE_LOG(xx_emf_cn_pkg.cn_low, fnd_global.conc_request_id || ' : Before Data Derivations');
	-- Once data-validations are complete the loop through the pre-interface records
	-- and perform data derivations on this table
	-- Set the stage to data derivations
	set_stage (xx_emf_cn_pkg.CN_DERIVE);
	OPEN c_xx_itemrtg ( xx_emf_cn_pkg.CN_VALID);
	LOOP
            FETCH c_xx_itemrtg
            BULK COLLECT INTO x_itemrtg_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

            FOR i IN 1 .. x_itemrtg_table.COUNT
            LOOP
		BEGIN

		    -- Perform Base App Validations
		    x_error_code := xx_itemrtg_data_derivations (x_itemrtg_table (i));
		    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_itemrtg_table (i).record_number|| ' is ' || x_error_code);

		    update_record_status_rtg (x_itemrtg_table (i), x_error_code);
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
			    update_int_records_rtg ( x_itemrtg_table);
			    RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
		    WHEN OTHERS
		    THEN
			    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_itemrtg_table (i).record_number);
		END;
            END LOOP;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_itemrtg_table.count ' || x_itemrtg_table.COUNT );

            update_int_records_rtg ( x_itemrtg_table);
            x_itemrtg_table.DELETE;

            EXIT WHEN c_xx_itemrtg%NOTFOUND;
	END LOOP;

	IF c_xx_itemrtg%ISOPEN THEN
            CLOSE c_xx_itemrtg;
	END IF;
	-- Set the stage to Post Validations
	set_stage (xx_emf_cn_pkg.CN_POSTVAL);

        -- Change the validations package to the appropriate package name
        -- Modify the parameters as required
        -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
	-- PRE_VALIDATIONS SHOULD BE RETAINED
	x_error_code := post_validations (p_transaction_type, 'RTG');
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
	mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL, 'RTG');
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete_rtg post-validations X_ERROR_CODE ' || X_ERROR_CODE);
	xx_emf_pkg.propagate_error ( x_error_code);


IF p_transaction_type = G_TRANS_TYPE_CREATE THEN -- If CREATE then validate operations and resources
	------------------------------------------------------------------------------
	--	processing for Operations Sequence
	------------------------------------------------------------------------------

	-- Set the stage to Pre Validations
	set_stage (xx_emf_cn_pkg.CN_PREVAL);
	-- PRE_VALIDATIONS SHOULD BE RETAINED
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling xx_bom_rtg_cnv_pkg.pre_validations ..');

	x_error_code := xx_bom_rtg_cnv_pkg.pre_validations('OPR');

	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After pre_validations_rtg X_ERROR_CODE ' || X_ERROR_CODE);
	-- Update process code of staging records
	-- Update Header and Lines Level
	update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS, 'OPR');

	xx_emf_pkg.propagate_error ( x_error_code);

	-- Set the stage to data Validations
	set_stage (xx_emf_cn_pkg.CN_VALID);
	OPEN c_xx_rtgop ( xx_emf_cn_pkg.CN_PREVAL);
	    LOOP
	       	FETCH c_xx_rtgop
		    BULK COLLECT INTO x_rtgop_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

		   FOR i IN 1 .. x_rtgop_table.COUNT
		   LOOP
			BEGIN
			    -- Perform Base App Validations
			    x_error_code := xx_rtgop_validation(x_rtgop_table (i));
			    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_rtgop_table (i).record_number|| ' is ' || x_error_code);
			    update_record_status_op (x_rtgop_table (i), x_error_code);

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
				  update_int_records_op ( x_rtgop_table);
				  RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
			   WHEN OTHERS
			   THEN
				  xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_rtgop_table (i).record_number);
			END;

		   END LOOP;
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_rtgop_table.count ' || x_rtgop_table.COUNT );
		update_int_records_op( x_rtgop_table);
		x_rtgop_table.DELETE;

		EXIT WHEN c_xx_rtgop%NOTFOUND;
	    END LOOP;
	IF c_xx_rtgop%ISOPEN THEN
	    CLOSE c_xx_rtgop;
	END IF;

	xx_emf_pkg.WRITE_LOG(xx_emf_cn_pkg.cn_low, fnd_global.conc_request_id || ' : Before Data Derivations');
	-- Once data-validations are complete the loop through the pre-interface records
	-- and perform data derivations on this table
	-- Set the stage to data derivations
	set_stage (xx_emf_cn_pkg.CN_DERIVE);
	OPEN c_xx_rtgop ( xx_emf_cn_pkg.CN_VALID);
	LOOP
            FETCH c_xx_rtgop
            BULK COLLECT INTO x_rtgop_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

            FOR i IN 1 .. x_rtgop_table.COUNT
            LOOP
		BEGIN

		    -- Perform Base App Validations
		    x_error_code := xx_rtgop_data_derivations (x_rtgop_table (i));
		    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_rtgop_table (i).record_number|| ' is ' || x_error_code);

		    update_record_status_op (x_rtgop_table (i), x_error_code);
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
			    update_int_records_op ( x_rtgop_table);
			    RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
		    WHEN OTHERS
		    THEN
			    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_rtgop_table (i).record_number);
		END;
            END LOOP;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_rtgop_table.count ' || x_rtgop_table.COUNT );

            update_int_records_op ( x_rtgop_table);
            x_rtgop_table.DELETE;

            EXIT WHEN c_xx_rtgop%NOTFOUND;
	END LOOP;

	IF c_xx_rtgop%ISOPEN THEN
            CLOSE c_xx_rtgop;
	END IF;
	-- Set the stage to Post Validations
	set_stage (xx_emf_cn_pkg.CN_POSTVAL);

        -- Change the validations package to the appropriate package name
        -- Modify the parameters as required
        -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
	-- PRE_VALIDATIONS SHOULD BE RETAINED
	x_error_code := post_validations (p_transaction_type, 'OPR');
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
	mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL, 'OPR');
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete_op post-validations X_ERROR_CODE ' || X_ERROR_CODE);
	xx_emf_pkg.propagate_error ( x_error_code);

    ------------------------------------------------------------------------------
    --	processing for Operation Resource
    ------------------------------------------------------------------------------

	-- Set the stage to Pre Validations
	set_stage (xx_emf_cn_pkg.CN_PREVAL);
	-- PRE_VALIDATIONS SHOULD BE RETAINED
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling xx_bom_rtg_cnv_pkg.pre_validations ..');

	x_error_code := xx_bom_rtg_cnv_pkg.pre_validations('RES');

	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After pre_validations_rtg X_ERROR_CODE ' || X_ERROR_CODE);
	-- Update process code of staging records
	-- Update Header and Lines Level
	update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS, 'RES');

	xx_emf_pkg.propagate_error ( x_error_code);

	-- Set the stage to data Validations
	set_stage (xx_emf_cn_pkg.CN_VALID);
	OPEN c_xx_rtgres ( xx_emf_cn_pkg.CN_PREVAL);
	    LOOP
	       	FETCH c_xx_rtgres
		   BULK COLLECT INTO x_rtgres_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

		   FOR i IN 1 .. x_rtgres_table.COUNT
		   LOOP
			BEGIN

			    -- Perform Base App Validations
			    x_error_code := xx_rtgres_validation(x_rtgres_table (i));

			    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_rtgres_table (i).record_number|| ' is ' || x_error_code);
			    update_record_status_res (x_rtgres_table (i), x_error_code);

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
				  update_int_records_res ( x_rtgres_table);
				  RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
			   WHEN OTHERS
			   THEN
				  xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, 'HERE----'||x_rtgres_table (i).record_number);
			END;

		   END LOOP;

		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_rtgres_table.count ' || x_rtgres_table.COUNT );
		update_int_records_res( x_rtgres_table);
		x_rtgres_table.DELETE;

		EXIT WHEN c_xx_rtgres%NOTFOUND;
	    END LOOP;
	IF c_xx_rtgres%ISOPEN THEN
	    CLOSE c_xx_rtgres;
	END IF;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'i m here 9');
	xx_emf_pkg.WRITE_LOG(xx_emf_cn_pkg.cn_low, fnd_global.conc_request_id || ' : Before Data Derivations');
	-- Once data-validations are complete the loop through the pre-interface records
	-- and perform data derivations on this table
	-- Set the stage to data derivations

	set_stage (xx_emf_cn_pkg.CN_DERIVE);
	OPEN c_xx_rtgres ( xx_emf_cn_pkg.CN_VALID);
	LOOP
            FETCH c_xx_rtgres
            BULK COLLECT INTO x_rtgres_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

            FOR i IN 1 .. x_rtgres_table.COUNT
            LOOP
		BEGIN

		    -- Perform Base App Validations
		    x_error_code := xx_rtgres_data_derivations (x_rtgres_table (i));
		    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_rtgres_table (i).record_number|| ' is ' || x_error_code);

		    update_record_status_res (x_rtgres_table (i), x_error_code);
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
			    update_int_records_res ( x_rtgres_table);
			    RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
		    WHEN OTHERS
		    THEN
			    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_rtgres_table (i).record_number);
		END;
            END LOOP;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_rtgres_table.count ' || x_rtgres_table.COUNT );

            update_int_records_res ( x_rtgres_table);
            x_rtgres_table.DELETE;

            EXIT WHEN c_xx_rtgres%NOTFOUND;
	END LOOP;

	IF c_xx_rtgres%ISOPEN THEN
            CLOSE c_xx_rtgres;
	END IF;
	-- Set the stage to Post Validations
	set_stage (xx_emf_cn_pkg.CN_POSTVAL);

        -- Change the validations package to the appropriate package name
        -- Modify the parameters as required
        -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
	-- PRE_VALIDATIONS SHOULD BE RETAINED
	x_error_code := post_validations (p_transaction_type, 'RES');
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
	mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL, 'RES');
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete_res post-validations X_ERROR_CODE ' || X_ERROR_CODE);
	xx_emf_pkg.propagate_error ( x_error_code);

	--Added as per Wave2
	------------------------------------------------------------------------------
	--	processing for Operation Network
	------------------------------------------------------------------------------

	-- Set the stage to Pre Validations
	set_stage (xx_emf_cn_pkg.CN_PREVAL);
	-- PRE_VALIDATIONS SHOULD BE RETAINED
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling xx_bom_rtg_cnv_pkg.pre_validations ..');

	x_error_code := xx_bom_rtg_cnv_pkg.pre_validations('NTWRK');

	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After pre_validations_rtg X_ERROR_CODE ' || X_ERROR_CODE);
	-- Update process code of staging records
	-- Update Header and Lines Level
	update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS, 'NTWRK');

	xx_emf_pkg.propagate_error ( x_error_code);

	-- Set the stage to data Validations
	set_stage (xx_emf_cn_pkg.CN_VALID);
	OPEN c_xx_rtgntwrk ( xx_emf_cn_pkg.CN_PREVAL);
	    LOOP
	       	FETCH c_xx_rtgntwrk
		    BULK COLLECT INTO x_rtgntwrk_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

		   FOR i IN 1 .. x_rtgntwrk_table.COUNT
		   LOOP
			BEGIN
			    -- Perform Base App Validations
			    x_error_code := xx_rtgntwrk_validation(x_rtgntwrk_table (i));
			    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_rtgntwrk_table (i).record_number|| ' is ' || x_error_code);
			    update_record_status_ntwrk (x_rtgntwrk_table (i), x_error_code);

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
				  update_int_records_ntwrk ( x_rtgntwrk_table);
				  RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
			   WHEN OTHERS
			   THEN
				  xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_rtgntwrk_table (i).record_number);
			END;

		   END LOOP;
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_rtgntwrk_table.count ' || x_rtgntwrk_table.COUNT );
		update_int_records_ntwrk( x_rtgntwrk_table);
		x_rtgntwrk_table.DELETE;

		EXIT WHEN c_xx_rtgntwrk%NOTFOUND;
	    END LOOP;
	IF c_xx_rtgntwrk%ISOPEN THEN
	    CLOSE c_xx_rtgntwrk;
	END IF;

	-- Set the stage to data derivation
	set_stage (xx_emf_cn_pkg.CN_DERIVE);
	OPEN c_xx_rtgntwrk ( xx_emf_cn_pkg.CN_VALID);
	    LOOP
	       	FETCH c_xx_rtgntwrk
		    BULK COLLECT INTO x_rtgntwrk_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

		   FOR i IN 1 .. x_rtgntwrk_table.COUNT
		   LOOP
			BEGIN
			    -- Perform Base App Validations
			    x_error_code := data_derivations_rtgntwrk(x_rtgntwrk_table (i));
			    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_rtgntwrk_table (i).record_number|| ' is ' || x_error_code);
			    update_record_status_ntwrk (x_rtgntwrk_table (i), x_error_code);

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
				  update_int_records_ntwrk ( x_rtgntwrk_table);
				  RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
			   WHEN OTHERS
			   THEN
				  xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_rtgntwrk_table (i).record_number);
			END;

		   END LOOP;
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_rtgntwrk_table.count ' || x_rtgntwrk_table.COUNT );
		update_int_records_ntwrk( x_rtgntwrk_table);
		x_rtgntwrk_table.DELETE;

		EXIT WHEN c_xx_rtgntwrk%NOTFOUND;
	    END LOOP;
	IF c_xx_rtgntwrk%ISOPEN THEN
	    CLOSE c_xx_rtgntwrk;
	END IF;

	-- Set the stage to Post Validations
	set_stage (xx_emf_cn_pkg.CN_POSTVAL);

        -- Change the validations package to the appropriate package name
        -- Modify the parameters as required
        -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
	-- PRE_VALIDATIONS SHOULD BE RETAINED
	x_error_code := post_validations (p_transaction_type, 'NTWRK');
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
	mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL, 'NTWRK');
	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete_op post-validations X_ERROR_CODE ' || X_ERROR_CODE);
	xx_emf_pkg.propagate_error ( x_error_code);

END IF; -- G_TRANS_TYPE_CREATE -- If CREATE then validate operations and resources

	-- Perform data derivations and process data only if p_validate_only_flag is set to VALIDATE_AND_LOAD
	IF p_validate_and_load = G_VALIDATE_AND_LOAD THEN
	    -- Set the stage to Process
	    set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Before process_data');
	    x_error_code := xx_insert_interface(p_transaction_type, 'RTG');
	    x_error_code := xx_insert_interface(p_transaction_type, 'OPR');
	    x_error_code := xx_insert_interface(p_transaction_type, 'RES');
	    x_error_code := xx_insert_interface(p_transaction_type, 'NTWRK');  --Added as per Wave2

	    IF  p_transaction_type = G_TRANS_TYPE_CREATE THEN
		xx_itemrtg_upload;
	    ELSIF  p_transaction_type = G_TRANS_TYPE_DELETE THEN
		xx_itemrtg_upload;
		xx_itemrtg_delete;
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'xx_itemrtg_upload - xx_itemrtg_delete');
	    END IF;

	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After process_data');
	    mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL, 'RTG');
	    mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL, 'OPR');
	    mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL, 'RES');
	    mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL, 'NTWRK');  --Added as per Wave2

	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After Process Data mark_records_complete x_error_code'||x_error_code);
	    xx_emf_pkg.propagate_error ( x_error_code);
	END IF; --for validate only flag check

	update_record_count(p_validate_and_load);
  print_detail_record_count(p_validate_and_load);
	xx_emf_pkg.create_report;

--- Added as part of DCR 300035 raised during SIT by Ebey Kurian -----
/*update bom_operation_resources
set autocharge_type = (select lookup_code
                       from fnd_lookup_values
                      where lookup_type = 'BOM_AUTOCHARGE_TYPE'
                      and UPPER(meaning) = 'PO MOVE'
                      and language = 'US')
where resource_id in (select bdr.resource_id
                      from bom_department_resources_v  bdr,
                      	    bom_departments bd,
                      	    org_organization_definitions ood
                      where bdr.department_id = bd.department_id
                      and bd.department_code = 'OSP'
                      and bd.organization_id = ood.organization_id
                      and ood.organization_code = '401'
                      and bdr.organization_id = ood.organization_id
                      );

update bom_operation_resources
set autocharge_type = (select lookup_code
                       from fnd_lookup_values
                      where lookup_type = 'BOM_AUTOCHARGE_TYPE'
                      and UPPER(meaning) = 'PO MOVE'
                      and language = 'US')
where resource_id in (select bdr.resource_id
                      from bom_department_resources_v  bdr,
                      	   bom_departments bd,
                      	   org_organization_definitions ood
                      where bdr.department_id = bd.department_id
                      and bd.department_code = 'OSP'
                      and bd.organization_id = ood.organization_id
                      and ood.organization_code = '101'
                      and bdr.organization_id = ood.organization_id
                      );

commit;*/
--- Addition of code for DCR 300035 ends -----


EXCEPTION
	WHEN xx_emf_pkg.G_E_ENV_NOT_SET THEN
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Checking if this is OK');
		fnd_file.put_line ( fnd_file.output, xx_emf_pkg.CN_ENV_NOT_SET);
		x_retcode := xx_emf_cn_pkg.CN_REC_ERR;
		update_record_count(p_validate_and_load);
		xx_emf_pkg.create_report;

	WHEN xx_emf_pkg.G_E_REC_ERROR THEN
		x_retcode := xx_emf_cn_pkg.CN_REC_ERR;
		update_record_count(p_validate_and_load);
		xx_emf_pkg.create_report;

	WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
		x_retcode := xx_emf_cn_pkg.CN_PRC_ERR;
		update_record_count(p_validate_and_load);
		xx_emf_pkg.create_report;

	WHEN OTHERS THEN
		x_retcode := xx_emf_cn_pkg.CN_PRC_ERR;
		update_record_count(p_validate_and_load);
		xx_emf_pkg.create_report;

 END main;

END xx_bom_rtg_cnv_pkg;
/


GRANT EXECUTE ON APPS.XX_BOM_RTG_CNV_PKG TO INTG_XX_NONHR_RO;
