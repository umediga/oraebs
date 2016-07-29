DROP PACKAGE BODY APPS.XX_BOM_IMPORT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_BOM_IMPORT_PKG" AS
/* $Header: XXINTGBOMCNV.pkb 1.0.0 2012/03/07 00:00:00 partha noship $ */
--==================================================================================
  -- Created By     : Partha S Mohanty
  -- Creation Date  : 07-MAR-2012
  -- Filename       : XXINTGBOMCNV.pkb
  -- Description    : Package body for Bills of Material conversion

  -- Change History:

  -- Date        Version#    Name                Remarks
  -- ----------- --------    ---------------     ------------------------------------
  -- 07-MAR-2012   1.0       Partha S Mohanty    Initial development.
  -- 13-Feb-2014   2.0       Aabhas Bhargava     Added Check for Engineering Items
--====================================================================================
   --Main Procedure Section
   -------------------------------------------------------------------------------------------------------------------------
   g_request_id NUMBER := fnd_profile.VALUE('CONC_REQUEST_ID');

   g_user_id NUMBER := fnd_global.user_id; --fnd_profile.VALUE('USER_ID');

   g_resp_id NUMBER := fnd_profile.VALUE('RESP_ID');


------------------< set_cnv_env >-----------------------------------------------
--------------------------------------------------------------------------------
    PROCEDURE set_cnv_env (p_batch_id      VARCHAR2
                          ,p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES
                          ,p_batch_flag    VARCHAR2
                          )
        IS
     /*-------------------------------------------------------------------------------------------------------------------------
            Procedure Name   :   set_cnv_env
            Parameters       :       p_batch_id      VARCHAR2
                                     p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES
                                     p_batch_flag    VARCHAR2
            Purpose          :   sets environment
      -------------------------------------------------------------------------------------------------------------------------*/

    	x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
    	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside set_cnv_env...');
    	IF p_batch_flag = 'BOM_HDR' THEN
    		G_BATCH_ID	  := p_batch_id;
    		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_BATCH_ID: '||G_BATCH_ID );
    	ELSIF p_batch_flag = 'BOM_COMP' THEN
    		G_COMP_BATCH_ID   := p_batch_id;
    		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_COMP_BATCH_ID: '||G_COMP_BATCH_ID );
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
                                , 'In xx_bom_import_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_low;

    PROCEDURE dbg_med (p_dbg_text varchar2)
        IS
    BEGIN
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium
                                , 'In xx_bom_import_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_med;

    PROCEDURE dbg_high (p_dbg_text varchar2)
        IS
    BEGIN
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high
                                , 'In xx_bom_import_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_high;
------------------< mark_records_for_processing >-------------------------------
--------------------------------------------------------------------------------

    PROCEDURE mark_records_for_processing (p_restart_flag  IN VARCHAR2
                                          )
        IS
    	PRAGMA AUTONOMOUS_TRANSACTION;
      /*-------------------------------------------------------------------------------------------------------------------------
            Procedure Name   :   mark_records_for_processing
            Parameters       :   p_restart_flag  IN VARCHAR2

            Purpose          :   Marks records for processing
      -------------------------------------------------------------------------------------------------------------------------*/

    BEGIN
    	-- If the override is set records should not be purged from the pre-interface tables
        g_api_name := 'mark_records_for_processing';
    	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside of mark records for processing...');

    	IF p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS THEN

    	              UPDATE xx_bom_bill_of_mtls_stg -- BOM Header Staging
    	                SET request_id = xx_emf_pkg.G_REQUEST_ID,
    		            error_code = xx_emf_cn_pkg.CN_NULL,
    		            process_code = xx_emf_cn_pkg.CN_NEW,
                            error_mesg = NULL
    	              WHERE batch_id = G_BATCH_ID;


    			UPDATE xx_bom_inv_component_stg -- BOM Comp Staging
    			   SET request_id = xx_emf_pkg.G_REQUEST_ID,
    			       error_code = xx_emf_cn_pkg.CN_NULL,
    			       process_code = xx_emf_cn_pkg.CN_NEW,
                               error_mesg = NULL
    			 WHERE batch_id = G_COMP_BATCH_ID;


           DELETE FROM bom_bill_of_mtls_interface
                       WHERE attribute11 = G_BATCH_ID;

            DELETE FROM bom_inventory_comps_interface
                       WHERE attribute11 = G_COMP_BATCH_ID;

    	ELSIF p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS THEN
    			-- Update BOM Header Staging
    			UPDATE xx_bom_bill_of_mtls_stg
    			   SET request_id   = xx_emf_pkg.G_REQUEST_ID,
    			       error_code   = xx_emf_cn_pkg.CN_NULL,
    			       process_code = xx_emf_cn_pkg.CN_NEW,
                               error_mesg = NULL
    			 WHERE batch_id = G_BATCH_ID
    			   AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
    				       xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR);

    			-- Update BOM Comp Staging
    			UPDATE xx_bom_inv_component_stg
    			   SET request_id   = xx_emf_pkg.G_REQUEST_ID,
    			       error_code   = xx_emf_cn_pkg.CN_NULL,
    			       process_code = xx_emf_cn_pkg.CN_NEW,
                               error_mesg = NULL
    			 WHERE batch_id = G_COMP_BATCH_ID
    			   AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
    				       xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR);

            DELETE FROM bom_bill_of_mtls_interface
                       WHERE attribute11 = G_BATCH_ID;

            DELETE FROM bom_inventory_comps_interface
                       WHERE attribute11 = G_COMP_BATCH_ID;

          END IF;
          COMMIT;
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'End of mark records for processing...');
    END;

    --------------------------------------------------------------------------------
    -----------------< set_stage >--------------------------------------------------
    --------------------------------------------------------------------------------

    PROCEDURE set_stage (p_stage VARCHAR2)
    IS
     /*-------------------------------------------------------------------------------------------------------------------------
            Procedure Name   :   set_stage
            Parameters       :   p_stage VARCHAR2

            Purpose          :   Set stage
      -------------------------------------------------------------------------------------------------------------------------*/

    BEGIN
    	G_STAGE := p_stage;
    END set_stage;




-----------------< update_staging_records >-------------------------------------
--------------------------------------------------------------------------------

PROCEDURE update_staging_records( p_error_code VARCHAR2
                                , p_level VARCHAR2)
  IS
  /*-------------------------------------------------------------------------------------------------------------------------
     Procedure Name   :   update_staging_records
     Parameters       :   p_error_code VARCHAR2
                          p_level VARCHAR2

     Purpose          :   Updating the staging table records
   -------------------------------------------------------------------------------------------------------------------------*/

	x_last_update_date     DATE   := SYSDATE;
	x_last_updated_by      NUMBER := fnd_global.user_id;
	x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
 g_api_name := 'update_staging_records';
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside update_staging_records...'||p_level);

	IF p_level = 'BOM_HDR' THEN
	UPDATE xx_bom_bill_of_mtls_stg		--Header
	   SET process_code = G_STAGE,
	       error_code = DECODE ( error_code, NULL, p_error_code, error_code),
	       last_update_date = x_last_update_date,
	       last_updated_by   = x_last_updated_by,
	       last_update_login = x_last_update_login -- In template please made change
	 WHERE batch_id		= G_BATCH_ID
	   AND request_id	= xx_emf_pkg.G_REQUEST_ID
	   AND process_code	= xx_emf_cn_pkg.CN_NEW;
	END IF;

  IF p_level = 'BOM_COMP' THEN
        UPDATE xx_bom_inv_component_stg		--Component
	   SET process_code = G_STAGE,
	       error_code = DECODE ( error_code, NULL, p_error_code, error_code),
	       last_update_date = x_last_update_date,
	       last_updated_by   = x_last_updated_by,
	       last_update_login = x_last_update_login
	 WHERE batch_id		= G_COMP_BATCH_ID
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
   /*-------------------------------------------------------------------------------------------------------------------------
     Function Name    :   pre_validations
     Parameters       :

     Purpose          :   Updating the duplicate staging table records as error
   -------------------------------------------------------------------------------------------------------------------------*/
     x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
     x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

     -- Cursor for duplicate header record
     CURSOR c_xx_bom_hdr_dup IS
     SELECT
         bom1.ITEM_NUMBER
	        ,bom1.organization_code
	        ,bom1.alternate_bom_designator
          FROM   xx_bom_bill_of_mtls_stg bom1
          WHERE  bom1.rowid<>(SELECT min(bom2.rowid)
                   FROM xx_bom_bill_of_mtls_stg bom2
                   WHERE bom2.ITEM_NUMBER= bom1.ITEM_NUMBER
                   AND bom2.organization_code=bom1.organization_code
                   AND NVL(bom2.alternate_bom_designator,'XXX') = NVL(bom1.alternate_bom_designator,'XXX')
                   AND bom2.process_code = xx_emf_cn_pkg.CN_NEW
                   AND bom2.batch_id	= G_BATCH_ID
                   )
          AND bom1.process_code = xx_emf_cn_pkg.CN_NEW
          AND bom1.batch_id	=G_BATCH_ID
          FOR UPDATE OF bom1.process_code
              ,bom1.error_code
              ,bom1.error_mesg;

      -- Cursor for duplicate component record
      CURSOR c_xx_bom_comp_dup IS
          SELECT
                 bom1.organization_code
                ,bom1.ASSEMBLY_ITEM_NUMBER
                ,bom1.COMPONENT_ITEM_NUMBER
          FROM  xx_bom_inv_component_stg bom1
          WHERE bom1.rowid<>(SELECT min(bom2.rowid)
                            FROM xx_bom_inv_component_stg bom2
          		  WHERE bom2.organization_code=bom1.organization_code
          		  AND   bom2.ASSEMBLY_ITEM_NUMBER=bom1.ASSEMBLY_ITEM_NUMBER
          		  AND   bom2.COMPONENT_ITEM_NUMBER=bom1.COMPONENT_ITEM_NUMBER
                AND   bom2.batch_id	=G_COMP_BATCH_ID
          		  AND   bom2.process_code = xx_emf_cn_pkg.CN_NEW
          		  )
          AND bom1.process_code = xx_emf_cn_pkg.CN_NEW
          AND bom1.batch_id	=G_COMP_BATCH_ID
          FOR UPDATE OF bom1.process_code
                       ,bom1.error_code
                       ,bom1.error_mesg;
BEGIN
     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Inside Pre-Validations : Duplicate checking');

     --Start of the loop to print all the headers that are duplicate in the staging table
     dbg_low('Following records are duplicate BOM header records');
      FOR count_hdr IN c_xx_bom_hdr_dup
      LOOP
           UPDATE xx_bom_bill_of_mtls_stg
           SET process_code = xx_emf_cn_pkg.CN_PREVAL,
               error_code = xx_emf_cn_pkg.CN_REC_ERR
              ,error_mesg='Duplicate record exists in the header staging table'
           WHERE CURRENT OF c_xx_bom_hdr_dup;

           dbg_low('Assembly Item Name:     '||count_hdr.ITEM_NUMBER);
           dbg_low('Organization Code:      '||count_hdr.organization_code);
           dbg_low('Alternate BOM Designator'||count_hdr.Alternate_Bom_Designator);

      END LOOP;--End of LOOP to print the duplicate header  records in the staging table

     COMMIT;
     dbg_low('Following records are duplicate BOM Component header records');

     FOR count_comps IN c_xx_bom_comp_dup
     LOOP
        UPDATE xx_bom_inv_component_stg
           SET process_code = xx_emf_cn_pkg.CN_PREVAL,
               error_code = xx_emf_cn_pkg.CN_REC_ERR
              ,error_mesg='Duplicate record exists in the bom component staging table'
           WHERE CURRENT OF c_xx_bom_comp_dup;
        dbg_low('');
        dbg_low('Assembly Item Name  '||count_comps.ASSEMBLY_ITEM_NUMBER);
        dbg_low('Organization Code   '||count_comps.organization_code);
        dbg_low('Component Item      '||count_comps.COMPONENT_ITEM_NUMBER);
      END LOOP;
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

  FUNCTION bom_header_validations(p_bom_hdr_rec IN OUT xx_bom_import_pkg.G_XX_BOM_HEADER_STG_REC_TYPE
                          ) RETURN NUMBER
     IS
    /*-------------------------------------------------------------------------------------------------------------------------
     Procedure Name   :   bom_header_validations
     Parameters       :   p_bom_hdr_rec IN OUT G_XX_BOM_HEADER_STG_REC_TYPE


     Purpose          :   Validating each bom Header records.
    -------------------------------------------------------------------------------------------------------------------------*/

      l_bill_sequence_id   NUMBER;
      l_invorg_id          NUMBER := NULL;
      l_assitem_id         NUMBER := NULL;
      l_alt_bom_desig      VARCHAR2(10);
      l_structure_type_id  NUMBER;
      l_assembly_type_code NUMBER;
      x_org_code           VARCHAR2(3):= NULL;
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

         FUNCTION is_org_code_valid( p_rec_number NUMBER
                                    ,p_org_code VARCHAR2
                                    ,p_item_number VARCHAR2)
           RETURN number
          IS
         /*-------------------------------------------------------------------------------------------------------------------------
            Procedure Name   :   is_org_code_valid
            Parameters       :       p_rec_number      NUMBER
                                    ,p_org_code        VARCHAR2
                                    ,p_item_number     VARCHAR2
            Purpose          :   Validating organization code for each bom componet records.
          -------------------------------------------------------------------------------------------------------------------------*/

           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           begin
            IF p_org_code IS NULL THEN
                dbg_med('Organization Code can not be Null ');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Organization Code can not be Null'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );

              return x_error_code;
            ELSE
             BEGIN

               x_org_code := xx_intg_common_pkg.get_mapping_value(p_mapping_type =>'ORGANIZATION_CODE'
                                  ,p_source      =>NULL
                                  ,p_old_value1   =>trim(p_org_code)
                                  ,p_old_value2   =>'XXINTGBOMCONV'
                                  ,p_date_effective => sysdate
                                  );
               dbg_low('Mapped Organization Code : '||x_org_code);
               SELECT mp.organization_id
                 INTO l_invorg_id
                 FROM mtl_parameters mp
                WHERE mp.organization_code = x_org_code;
                RETURN  x_error_code;
             EXCEPTION
               WHEN no_data_found THEN
                  dbg_med('Organization Code does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Organization Code does not exist'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the Organization Code');
                  x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Organization Code'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );
                RETURN  x_error_code;
             END;
            END IF;
           END;

         FUNCTION is_item_number_valid( p_rec_number NUMBER
                                       ,p_org_code VARCHAR2
                                       ,p_item_number VARCHAR2)
           RETURN number
           IS
        /*-------------------------------------------------------------------------------------------------------------------------
            Procedure Name   :   is_org_code_valid
            Parameters       :         p_rec_number NUMBER
                                       p_org_code VARCHAR2
                                       p_item_number VARCHAR2
            Purpose          :   Validating item_number for each bom componet records.
          -------------------------------------------------------------------------------------------------------------------------*/

           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           begin
            IF p_item_number IS NULL THEN
                dbg_med('Item Number can not be Null ');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Item Number can not be Null;'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );

              return x_error_code;
            ELSE
            ---
              BEGIN
                 SELECT a.inventory_item_id
                  INTO l_assitem_id
                 FROM mtl_system_items_b a
                  WHERE a.segment1 = p_item_number
                     AND a.organization_id = l_invorg_id
                     AND a.bom_enabled_flag = 'Y'
                     AND a.enabled_flag = 'Y';
                  RETURN  x_error_code;
               EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid Item Number');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid Item Number'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing Item Number');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing Item Number'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );
                  RETURN  x_error_code;
              END ;
            END IF;
           END;

         FUNCTION is_assembly_type_valid( p_rec_number NUMBER
                                         ,p_org_code VARCHAR2
                                         ,p_item_number VARCHAR2
                                         ,p_assembly_type VARCHAR2)
           RETURN number
          IS
         /*-------------------------------------------------------------------------------------------------------------------------
            Procedure Name   :   is_assembly_type_valid
            Parameters       :         p_rec_number NUMBER
                                       p_org_code VARCHAR2
                                       p_item_number VARCHAR2
                                       p_assembly_type VARCHAR2
            Purpose          :   Validating assembly_type for each bom componet records.
          -------------------------------------------------------------------------------------------------------------------------*/


           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
          BEGIN
          IF p_assembly_type IS NULL THEN

            dbg_med('BOM Assembly Type can not be null ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                         ,p_error_text  => 'BOM Assembly Type can not be null'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );
                   RETURN  x_error_code;
          END IF;
          RETURN  x_error_code;
        END;

       -- is_eng_item_valid
  FUNCTION is_eng_item_valid(p_rec_number NUMBER,p_org_code VARCHAR2,p_item_number VARCHAR2,p_assembly_type NUMBER)
        RETURN number
        IS
            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
            x_eng_item_flag VARCHAR2(1) := NULL;
        BEGIN

          SELECT eng_item_flag
                  INTO x_eng_item_flag
               FROM mtl_system_items_b
               WHERE segment1 = p_item_number
                 AND organization_id = l_invorg_id;

            IF UPPER(TRIM(x_eng_item_flag))= 'Y' and p_assembly_type <> 2  THEN
                   dbg_med('Item Is an Enginnering Item '||p_item_number);
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Item Is an Enginnering Item'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );
                   RETURN x_error_code;
            END IF;
		        RETURN x_error_code;
          EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   dbg_med('Enginnering Item Flag does not exist ');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Enginnering Item Flag does not exist'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );
                   RETURN x_error_code;

               WHEN OTHERS THEN
                  dbg_med(' Unexpected error while validating the Enginnering Item');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Enginnering Item'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );
                  RETURN x_error_code;
        END is_eng_item_valid;


         FUNCTION is_alt_bom_desig_valid( p_rec_number NUMBER
                                         ,p_org_code VARCHAR2
                                         ,p_item_number VARCHAR2
                                         ,p_alt_bom_designator VARCHAR2)
           RETURN number
          IS
          /*-------------------------------------------------------------------------------------------------------------------------
            Procedure Name   :   is_assembly_type_valid
            Parameters       :        p_rec_number NUMBER
                                      p_org_code VARCHAR2
                                      p_item_number VARCHAR2
                                      p_alt_bom_designator VARCHAR2
            Purpose          :   Validating alt_bom_desig for each bom componet records.
          -------------------------------------------------------------------------------------------------------------------------*/
           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
          BEGIN
           IF p_alt_bom_designator IS NOT NULL THEN
            BEGIN
               SELECT alternate_designator_code
                 INTO l_alt_bom_desig
                 FROM bom_alternate_designators
                WHERE alternate_designator_code = p_alt_bom_designator
                      AND organization_id = l_invorg_id;
                RETURN  x_error_code;
            EXCEPTION
               WHEN no_data_found THEN

                  dbg_med('Alternate BOM Designator does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                         ,p_error_text  => 'Alternate BOM Designator does not exist'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );
                   RETURN  x_error_code;

               WHEN OTHERS THEN

                  dbg_med(' Unexpected error while validating the Alternate BOM Designator ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                         ,p_error_text  => 'Unexpected error while validating the Alternate BOM Designator'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );
                   RETURN  x_error_code;

            END;
         ELSE
            RETURN  x_error_code;
         END IF;
         END;



     BEGIN
       g_api_name := 'xx_bom_header_validation';
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside BOM Header Data-Validations');
       x_error_code_temp := is_org_code_valid(p_bom_hdr_rec.record_number,
                                      p_bom_hdr_rec.organization_code,
                                      p_bom_hdr_rec.item_number
		                                  );
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_item_number_valid(p_bom_hdr_rec.record_number,
                                      p_bom_hdr_rec.organization_code,
                                      p_bom_hdr_rec.item_number
		                                  );
	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);


       x_error_code_temp := is_assembly_type_valid(p_bom_hdr_rec.record_number,
                                      p_bom_hdr_rec.organization_code,
                                      p_bom_hdr_rec.item_number,
		                                  p_bom_hdr_rec.assembly_type);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       -- Addeed after MOCK CONVERSION 03-MAR-2013 -- Check for engineering item

      x_error_code_temp := is_eng_item_valid(p_bom_hdr_rec.record_number,
				                                     p_bom_hdr_rec.organization_code,
				                                     p_bom_hdr_rec.item_number,
                                             p_bom_hdr_rec.assembly_type
					                                   );
	    x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       -- Addeed after MOCK CONVERSION 03-MAR-2013 END

       x_error_code_temp := is_alt_bom_desig_valid(p_bom_hdr_rec.record_number,
                                      p_bom_hdr_rec.organization_code,
                                      p_bom_hdr_rec.item_number,
		                                  p_bom_hdr_rec.alternate_bom_designator);

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

   END bom_header_validations;


  /*-------------------------------------------------------------------------------------------------------------------
   Procedure Name   :   XXS_BOM_HEADER_VALIDATION
   Parameters       :   p_bom_hdr_rec IN OUT
   Purpose          :   BOM Header Derivations
   --------------------------------------------------------------------------------------------------------------------*/
  FUNCTION bom_hdr_data_derivations(p_bom_hdr_rec IN OUT xx_bom_import_pkg.G_XX_BOM_HEADER_STG_REC_TYPE
                          ) RETURN NUMBER
     IS
     /*-------------------------------------------------------------------------------------------------------------------------
       Procedure Name   :   is_op_seq_num_valid
       Parameters       :   p_bom_hdr_rec IN OUT G_XX_BOM_HEADER_STG_REC_TYPE

       Purpose          :   Derive the required fields for each bom Header records.
     -------------------------------------------------------------------------------------------------------------------------*/
      l_bill_sequence_id   NUMBER;
      l_invorg_id          NUMBER := NULL;
      l_assitem_id         NUMBER := NULL;
      x_org_code           VARCHAR2(3):= NULL;
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

       FUNCTION get_org_id(p_rec_number         NUMBER
                           ,p_org_code          VARCHAR2
                           ,p_item_number       VARCHAR2
                           ,p_org_id        OUT NUMBER
                           ,p_org_code_orig OUT VARCHAR2)
           RETURN number
           IS
          /*-------------------------------------------------------------------------------------------------------------------------
           Function  Name   :   get_org_id
           Parameters       :    p_rec_number         NUMBER
                                 p_org_code          VARCHAR2
                                 p_item_number       VARCHAR2
                                 p_org_id        OUT NUMBER
                                 p_org_code_orig OUT VARCHAR2

           Purpose          :   Derive the organization_id for each bom Header records.
           -------------------------------------------------------------------------------------------------------------------------*/


             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           BEGIN
               x_org_code := xx_intg_common_pkg.get_mapping_value(p_mapping_type =>'ORGANIZATION_CODE'
                                  ,p_source      =>NULL
                                  ,p_old_value1   =>trim(p_org_code)
                                  ,p_old_value2   =>'XXINTGBOMCONV'
                                  ,p_date_effective => sysdate
                                  );
               SELECT mp.organization_id
                 INTO l_invorg_id
                 FROM mtl_parameters mp
                WHERE mp.organization_code = x_org_code;
                p_org_id := l_invorg_id;
                p_org_code_orig := x_org_code; -- used only for reference
                RETURN  x_error_code;
            EXCEPTION
               WHEN no_data_found THEN
                  dbg_med('Organization Code does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Organization Code does not exist'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while deriving the Organization Code');
                  x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving the Organization Code'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );
                RETURN  x_error_code;
            END get_org_id;

          FUNCTION get_assitem_id( p_rec_number NUMBER
                                  ,p_org_code VARCHAR2
                                  ,p_item_number VARCHAR2
                                  ,p_inv_item_id OUT NUMBER)
           RETURN number
           IS
           /*-------------------------------------------------------------------------------------------------------------------------
           Function  Name   :   get_assitem_id
           Parameters       :    p_rec_number      NUMBER
                                 p_org_code        VARCHAR2
                                 p_item_number     VARCHAR2
                                 p_inv_item_id OUT NUMBER

           Purpose          :   Derive the assembly_item_id for each bom Header records.
           -------------------------------------------------------------------------------------------------------------------------*/
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           BEGIN
               SELECT a.inventory_item_id
                 INTO l_assitem_id
                 FROM mtl_system_items_b a
                WHERE a.segment1 = p_item_number
                     AND a.organization_id = l_invorg_id
                     AND a.bom_enabled_flag = 'Y'
                     AND a.enabled_flag = 'Y';
                     p_inv_item_id := l_assitem_id;
                     RETURN  x_error_code;
            EXCEPTION
               WHEN no_data_found THEN
                  dbg_med('Unable to derive BOM enabled Assembly Item id');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unable to derive BOM enabled Assembly Item id'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while deriving BOM enabled Assembly Item id');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving BOM enabled Assembly Item id'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );
                   RETURN  x_error_code;
            END get_assitem_id;

     BEGIN
      g_api_name := 'bom_hdr_data_derivations';
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside bom_hdr_data_derivations');

      x_error_code_temp := get_org_id (p_bom_hdr_rec.record_number,
                                          p_bom_hdr_rec.organization_code,
                                          p_bom_hdr_rec.item_number,
                                          p_bom_hdr_rec.organization_id,
                                          p_bom_hdr_rec.organization_code_orig
		                                      );

       x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );

       x_error_code_temp := get_assitem_id (p_bom_hdr_rec.record_number,
                                          p_bom_hdr_rec.organization_code,
                                          p_bom_hdr_rec.item_number,
                                          p_bom_hdr_rec.assembly_item_id
		                                      );

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
	END bom_hdr_data_derivations;

  -- post Validation
  FUNCTION post_validations(p_trans_type VARCHAR2,p_batch_flag  VARCHAR2)
   RETURN NUMBER
        IS
		x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         BEGIN
     g_api_name := 'main.post_validations';
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations');

    -- Update Bom header staging table for error if BOM is already exists in Oracle
  IF p_trans_type = g_trans_type_create THEN

    IF p_batch_flag = 'BOM_HDR' THEN
     UPDATE xx_bom_bill_of_mtls_stg xbom
      SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
    	   process_code = xx_emf_cn_pkg.CN_POSTVAL,
         error_mesg='This Bills Of Material already exists in Oracle'
      WHERE 1=1
        AND xbom.batch_id = G_BATCH_ID  -- changed on 18 sep 2012
        AND  NVL (xbom.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
  				            xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
        AND EXISTS(SELECT 1
             FROM bom_bill_of_materials bom
             WHERE bom.assembly_item_id = xbom.assembly_item_id
               AND bom.organization_id = xbom.organization_id AND
               nvl(bom.alternate_bom_designator,'xxx') = nvl(xbom.alternate_bom_designator,'xxx'));
    END IF;
    -- Update Bom Component staging table for error if BOM component is already exists in Oracle
    IF p_batch_flag = 'BOM_COMP' THEN
      UPDATE xx_bom_inv_component_stg bcs
       SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
    	    process_code = xx_emf_cn_pkg.CN_POSTVAL,
          error_mesg='This BOM Component already exists in Oracle'
       WHERE 1=1
       AND  bcs.batch_id = G_COMP_BATCH_ID  -- changed on 18 sep 2012
       AND  NVL (bcs.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
  				            xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
       AND EXISTS(SELECT 1
        FROM bom_bill_of_materials    bom
            ,bom_inventory_components bic
          WHERE bom.bill_sequence_id = bic.bill_sequence_id
             AND bom.organization_id = bcs.organization_id
             AND bom.assembly_item_id = bcs.assembly_item_id
             AND bic.component_item_id = bcs.component_item_id
             AND nvl(bom.alternate_bom_designator,'xxx') = nvl(bcs.alternate_bom_designator,'xxx'));
      END IF;
   END IF; -- p_trans_type = 'CREATE'

   IF p_trans_type = g_trans_type_delete THEN

    -- Update Bom Header staging table with 'error' if BOM header for deletion not exists in Oracle
    IF p_batch_flag = 'BOM_HDR' THEN
     UPDATE xx_bom_bill_of_mtls_stg xbom
      SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
    	   process_code = xx_emf_cn_pkg.CN_POSTVAL,
         error_mesg='Bills Of Material Not exists in Oracle'
      WHERE 1=1
        AND  xbom.batch_id = G_BATCH_ID -- changed on 18 sep 2012
        AND  NVL (xbom.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
  				            xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
        AND NOT EXISTS(SELECT 1
             FROM bom_bill_of_materials bom
             WHERE bom.assembly_item_id = xbom.assembly_item_id
               AND bom.organization_id = xbom.organization_id AND
               nvl(bom.alternate_bom_designator,'xxx') = nvl(xbom.alternate_bom_designator,'xxx'));
    END IF;
    -- Update Bom Component staging table with 'error' if BOM component for deletion not exists in Oracle
    IF p_batch_flag = 'BOM_COMP' THEN
      UPDATE xx_bom_inv_component_stg bcs
       SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
    	    process_code = xx_emf_cn_pkg.CN_POSTVAL,
          error_mesg='BOM Component Not exists in Oracle'
       WHERE 1=1
       AND  bcs.batch_id = G_COMP_BATCH_ID  -- changed on 18 sep 2012
       AND  NVL (bcs.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
  				            xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
       AND NOT EXISTS(SELECT 1
        FROM bom_bill_of_materials    bom
            ,bom_inventory_components bic
          WHERE bom.bill_sequence_id = bic.bill_sequence_id
             AND bom.organization_id = bcs.organization_id
             AND bom.assembly_item_id = bcs.assembly_item_id
             AND bic.component_item_id = bcs.component_item_id
             AND nvl(bom.alternate_bom_designator,'xxx') = nvl(bcs.alternate_bom_designator,'xxx'));
      END IF;
   END IF; -- p_trans_type = 'DELETE'
   commit;

  IF p_batch_flag = 'BOM_COMP' THEN
   -- Update all Header record with 'error' if one of component record errored out
     UPDATE xx_bom_bill_of_mtls_stg xbm
       SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
    	    process_code = xx_emf_cn_pkg.CN_POSTVAL,
          error_mesg='BOM Header Errored out due to One of component record Error'
       WHERE 1=1
       AND  xbm.batch_id = G_BATCH_ID -- changed on 18 sep 2012
       AND  NVL (xbm.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
  				            xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
       AND (xbm.item_number,xbm.organization_code) IN (SELECT bcs.assembly_item_number,bcs.organization_code
                                                                    from xx_bom_inv_component_stg bcs
                                                                  WHERE  bcs.assembly_item_number = xbm.item_number
                                                                    AND  bcs.organization_code = xbm.organization_code
                                                                    AND  NVL (bcs.error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
    				                                                                    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
                                                                    AND  bcs.batch_id = G_COMP_BATCH_ID  -- changed on 18 sep 2012
                                                                    AND rownum = 1);

   -- Update all component record with 'error' if BOM Header record errored out

    UPDATE xx_bom_inv_component_stg bcs
     SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
  	    process_code = xx_emf_cn_pkg.CN_POSTVAL,
        error_mesg='BOM Component Errored out due to Header record error'
     WHERE 1=1
     AND  bcs.batch_id = G_COMP_BATCH_ID  -- changed on 18 sep 2012
     AND  NVL (bcs.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
				            xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
     AND (bcs.assembly_item_number,bcs.organization_code) IN (SELECT xbm.item_number,xbm.organization_code
                                                                  from xx_bom_bill_of_mtls_stg xbm
                                                                WHERE  xbm.item_number = bcs.assembly_item_number
                                                                  AND  xbm.organization_code = bcs.organization_code
                                                                  AND  NVL (xbm.error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
  				                                                                    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
                                                                   AND  xbm.batch_id = G_BATCH_ID -- changed on 18 sep 2012
                                                                  );

   END IF;
   commit;
   xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Completed Post-Validations');
	 RETURN x_error_code;
	EXCEPTION
		WHEN xx_emf_pkg.G_E_REC_ERROR THEN
			x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
			RETURN x_error_code;
		WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
			x_error_code := xx_emf_cn_pkg.cn_rec_err;
			RETURN x_error_code;
		WHEN OTHERS THEN
			x_error_code := xx_emf_cn_pkg.cn_rec_err;
			RETURN x_error_code;

	END post_validations;


  FUNCTION bom_component_validations(p_bomcomp_rec IN OUT xx_bom_import_pkg.G_XX_BOM_COMP_STG_REC_TYPE
                          ) RETURN NUMBER
     IS
    /*-------------------------------------------------------------------------------------------------------------------------
     Procedure Name   :   bom_component_validations
     Parameters       :   p_bomcomp_rec IN OUT xx_bom_import_pkg.G_XX_BOM_COMP_STG_REC_TYPE


     Purpose          :   Validating each bom componet records.
    -------------------------------------------------------------------------------------------------------------------------*/

      l_err_msg              VARCHAR2(4000);
      l_err_no               VARCHAR2(2000);
      l_comp_sequence_id     NUMBER := NULL;
      l_invorg_id1           NUMBER := NULL;
      l_assitem_id1          NUMBER := NULL;
      l_compitem_id          NUMBER := NULL;
      l_ops_chk              NUMBER;
      l_wip_supply_type_code NUMBER;
      l_bom_item_type_code   NUMBER;
      l_sub_inv_cnt          NUMBER := 0;
      l_inv_loc_id           NUMBER;
      l_cnt_bmc_dup          NUMBER := 0;
      l_primary_uom          VARCHAR2(25):= NULL;
      x_primary_uom          VARCHAR2(25):= NULL;
      x_org_code           VARCHAR2(3):= NULL;
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;


         FUNCTION is_org_code_valid( p_rec_number NUMBER
                                    ,p_org_code VARCHAR2
                                    ,p_item_number VARCHAR2
                                    ,p_compitem_number VARCHAR2)
           RETURN number
           IS
          /*-------------------------------------------------------------------------------------------------------------------------
            Procedure Name   :   is_org_code_valid
            Parameters       :       p_rec_number      NUMBER
                                    ,p_org_code        VARCHAR2
                                    ,p_item_number     VARCHAR2
                                    ,p_compitem_number VARCHAR2
            Purpose          :   Validating organization code for each bom componet records.
          -------------------------------------------------------------------------------------------------------------------------*/


           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           begin
            IF p_org_code IS NULL THEN
                dbg_med('Organization Code can not be Null ');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Organization Code can not be Null'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                        );

              return x_error_code;
            ELSE
             BEGIN
               x_org_code := xx_intg_common_pkg.get_mapping_value(p_mapping_type =>'ORGANIZATION_CODE'
                                  ,p_source      =>NULL
                                  ,p_old_value1   =>trim(p_org_code)
                                  ,p_old_value2   =>'XXINTGBOMCONV'
                                  ,p_date_effective => sysdate
                                  );
               dbg_low('Mapped Organization Code : '||x_org_code);
               SELECT mp.organization_id
                 INTO l_invorg_id1
                 FROM mtl_parameters mp
                WHERE mp.organization_code = x_org_code;
                RETURN  x_error_code;
             EXCEPTION
               WHEN no_data_found THEN
                  dbg_med('Organization Code does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Organization Code does not exist'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the Organization Code');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Organization Code'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                        );
                RETURN  x_error_code;
             END;
            END IF;
           END is_org_code_valid;

         FUNCTION is_assitem_num_valid( p_rec_number   NUMBER
                                       ,p_org_code   VARCHAR2
                                       ,p_item_number VARCHAR2
                                       ,p_compitem_number VARCHAR2)
           RETURN number
           IS
           /*-------------------------------------------------------------------------------------------------------------------------
            Procedure Name   :   is_assitem_num_valid
            Parameters       :       p_rec_number       NUMBER
                                     ,p_org_code        VARCHAR2
                                     ,p_item_number     VARCHAR2
                                     ,p_compitem_number VARCHAR2
            Purpose          :   Validating Assembly Item Number for each bom componet records.
          -------------------------------------------------------------------------------------------------------------------------*/

           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           begin
            IF p_item_number IS NULL THEN
                dbg_med('Assembly Item Number can not be Null ');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Item Number can not be Null;'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                        );

              return x_error_code;
            ELSE
            ---
              BEGIN
                 SELECT a.inventory_item_id
                  INTO l_assitem_id1
                 FROM mtl_system_items_b a
                  WHERE a.segment1 = p_item_number
                     AND a.organization_id = l_invorg_id1
                     AND a.bom_enabled_flag = 'Y'
                     AND a.enabled_flag = 'Y';
                  RETURN  x_error_code;
               EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid Assembly Item Number');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid Assembly Item Number'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing Assembly Item Number');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing Assembly Item Number'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                        );
                  RETURN  x_error_code;
              END ;
            END IF;
           END is_assitem_num_valid;
         -----------------------------------------------------------------------------------------------
         --Validate Component Item Number
         -----------------------------------------------------------------------------------------------
         FUNCTION is_compitem_num_valid( p_rec_number NUMBER
                                        ,p_org_code VARCHAR2
                                        ,p_item_number VARCHAR2
                                        ,p_compitem_number VARCHAR2)
           RETURN number
           IS
         /*-------------------------------------------------------------------------------------------------------------------------
            Procedure Name   :   is_compitem_num_valid
            Parameters       :          p_rec_number      NUMBER
                                        p_org_code        VARCHAR2
                                        p_item_number     VARCHAR2
                                        p_compitem_number VARCHAR2
            Purpose          :   Validating Component Item Number for each bom componet records.
          -------------------------------------------------------------------------------------------------------------------------*/

           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           begin
            IF p_item_number IS NULL THEN
                dbg_med('Component Item Number can not be Null ');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Component Item Number can not be Null;'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                        );

              return x_error_code;
            ELSE

               BEGIN
                  SELECT a.inventory_item_id
                    INTO l_compitem_id
                    FROM mtl_system_items_b a
                   WHERE a.segment1 = p_compitem_number
                        AND a.organization_id = l_invorg_id1
                        AND a.bom_enabled_flag = 'Y' AND a.enabled_flag = 'Y';
                   return x_error_code;
               EXCEPTION
                  WHEN no_data_found THEN
                     dbg_low('BOM enabled Component Item Number does not exist in Component Level');
                     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'BOM enabled Component Item Number does not exist in Component Level'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                         );
                     return x_error_code;
                  WHEN OTHERS THEN
                     dbg_low('Unexpected error while validating the Component Item Number');
                     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Component Item Number'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                         );
                     return x_error_code;
               END;
             END IF;
           END is_compitem_num_valid;

         FUNCTION is_primary_uom_valid(p_rec_number       NUMBER
                                       ,p_org_code        VARCHAR2
                                       ,p_item_number     VARCHAR2
                                       ,p_compitem_number VARCHAR2
                                       ,p_primary_uom     VARCHAR2)
           RETURN number
            IS
         /*-------------------------------------------------------------------------------------------------------------------------
            Procedure Name   :   is_primary_uom_valid
            Parameters       :         p_rec_number       NUMBER
                                       p_org_code         VARCHAR2
                                       p_item_number      VARCHAR2
                                       p_compitem_number  VARCHAR2
                                       p_primary_uom      VARCHAR2
            Purpose          :   Validating primary_unit_of_measure for each bom componet records.
          -------------------------------------------------------------------------------------------------------------------------*/


           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           begin
            /*IF p_primary_uom IS NULL THEN
                dbg_med('Primary_unit_of_measure can not be Null ');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Primary_unit_of_measure can not be Null'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                        );

              return x_error_code;
            ELSE */
             BEGIN
               x_primary_uom := xx_intg_common_pkg.get_mapping_value(p_mapping_type =>'PRIMARY_UOM'
                                  ,p_source       =>NULL
                                  ,p_old_value1   =>trim(p_primary_uom)
                                  ,p_old_value2   =>'XXINTGBOMCONV'
                                  ,p_date_effective => sysdate
                                  );
               dbg_low('Mapped primary_unit_of_measure  : '||x_primary_uom);

              /*IF x_primary_uom IS NULL THEN
                  dbg_med('Unable to validate primary_unit_of_measure');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unable to validate primary_unit_of_measure'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                        );
                END IF; */
             END;
             RETURN  x_error_code;
          --  END IF;
         END is_primary_uom_valid;

         FUNCTION is_incl_cost_rollup_valid(p_rec_number       NUMBER
                                            ,p_org_code        VARCHAR2
                                            ,p_item_number     VARCHAR2
                                            ,p_compitem_number VARCHAR2
                                            ,p_cost_roll_up    VARCHAR2)
           RETURN number
             IS
          /*-------------------------------------------------------------------------------------------------------------------------
            Procedure Name   :   is_incl_cost_rollup_valid
            Parameters       :         p_rec_number       NUMBER
                                       p_org_code         VARCHAR2
                                       p_item_number      VARCHAR2
                                       p_compitem_number  VARCHAR2
                                       p_cost_roll_up     VARCHAR2
            Purpose          :   Validating is_incl_cost_rollup_valid for each bom componet records.
          -------------------------------------------------------------------------------------------------------------------------*/

           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           begin
             IF p_cost_roll_up IS NULL THEN
                dbg_med('Include_in_cost_rollup can not be Null ');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Include_in_cost_rollup can not be Null'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                        );

                  return x_error_code;
               ELSE
                   return x_error_code;
               END IF;
            END is_incl_cost_rollup_valid;

          -----------------------------------------------------------------------------------------------
          --Validate operation_seq_num
         -----------------------------------------------------------------------------------------------
         FUNCTION is_op_seq_num_valid(p_rec_number       NUMBER
                                     ,p_org_code         VARCHAR2
                                     ,p_item_number      VARCHAR2
                                     ,p_compitem_number  VARCHAR2
                                     ,p_op_seq_num       NUMBER)
           RETURN number
           IS
          /*-------------------------------------------------------------------------------------------------------------------------
            Procedure Name   :   is_op_seq_num_valid
            Parameters       :       p_rec_number       NUMBER
                                     p_org_code         VARCHAR2
                                     p_item_number      VARCHAR2
                                     p_compitem_number  VARCHAR2
                                     p_op_seq_num       NUMBER
            Purpose          :   Validating operation_seq_num for each bom componet records.
          -------------------------------------------------------------------------------------------------------------------------*/

           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           begin
             IF p_op_seq_num IS NULL THEN
                dbg_med('Operation_seq_num can not be Null ');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Operation_seq_num can not be Null'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                        );

                  return x_error_code;
               ELSE
                   return x_error_code;
               END IF;
            END is_op_seq_num_valid;

      BEGIN
      -- Validate BOM Components
       g_api_name := 'bom_component_validations';

       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside BOM Component Data-Validations');
       x_error_code_temp := is_org_code_valid(p_bomcomp_rec.record_number,
                                      p_bomcomp_rec.organization_code,
                                      p_bomcomp_rec.assembly_item_number,
		                                  p_bomcomp_rec.component_item_number);
       x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_assitem_num_valid(p_bomcomp_rec.record_number,
                                      p_bomcomp_rec.organization_code,
                                      p_bomcomp_rec.assembly_item_number,
		                                  p_bomcomp_rec.component_item_number);
	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);


       x_error_code_temp := is_compitem_num_valid(p_bomcomp_rec.record_number,
                                      p_bomcomp_rec.organization_code,
                                      p_bomcomp_rec.assembly_item_number,
		                                  p_bomcomp_rec.component_item_number);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := is_primary_uom_valid(p_bomcomp_rec.record_number,
                                      p_bomcomp_rec.organization_code,
                                      p_bomcomp_rec.assembly_item_number,
		                                  p_bomcomp_rec.component_item_number,
                                      p_bomcomp_rec.primary_unit_of_measure);

	      x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

        x_error_code_temp := is_incl_cost_rollup_valid(p_bomcomp_rec.record_number,
                                      p_bomcomp_rec.organization_code,
                                      p_bomcomp_rec.assembly_item_number,
		                                  p_bomcomp_rec.component_item_number,
                                      p_bomcomp_rec.include_in_cost_rollup);

	      x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

        x_error_code_temp := is_op_seq_num_valid(p_bomcomp_rec.record_number,
                                      p_bomcomp_rec.organization_code,
                                      p_bomcomp_rec.assembly_item_number,
		                                  p_bomcomp_rec.component_item_number,
                                      p_bomcomp_rec.operation_seq_num);

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
   END bom_component_validations;



FUNCTION bom_component_derivations(p_bomcomp_rec IN OUT xx_bom_import_pkg.G_XX_BOM_COMP_STG_REC_TYPE
                                                                ) RETURN NUMBER
     IS
    /*-------------------------------------------------------------------------------------------------------------------------
       Procedure Name   :   is_op_seq_num_valid
       Parameters       :   p_bomcomp_rec IN OUT G_XX_BOM_COMP_STG_REC_TYPE

       Purpose          :   Derive the required fields for each bom componet records.
     -------------------------------------------------------------------------------------------------------------------------*/

      l_err_msg              VARCHAR2(4000);
      l_comp_sequence_id     NUMBER := NULL;
      l_invorg_id1           NUMBER := NULL;
      l_assitem_id1          NUMBER := NULL;
      l_compitem_id          NUMBER := NULL;
      l_wip_supply_type_code NUMBER;
      l_bom_item_type_code   NUMBER;
      l_sub_inv_cnt          NUMBER := 0;
      l_inv_loc_id           NUMBER;
      l_cnt_bmc_dup          NUMBER := 0;
      x_org_code             VARCHAR2(3):= NULL;
      x_primary_uom          VARCHAR2(25):= NULL;
      l_primary_uom          VARCHAR2(25):= NULL;
      x_bill_seq_id          NUMBER := NULL;
      x_comp_seq_id          NUMBER := NULL;
      x_error_code           NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp      NUMBER := xx_emf_cn_pkg.CN_SUCCESS;


       FUNCTION get_org_id(p_rec_number NUMBER
                           ,p_org_code VARCHAR2
                           ,p_item_number VARCHAR2
                           ,p_compitem_num VARCHAR2
                           ,p_org_id OUT NUMBER
                           ,p_org_code_orig OUT VARCHAR2)
           RETURN number
           IS
        /*-------------------------------------------------------------------------------------------------------------------------
         Function  Name   :   get_org_id
         Parameters       :   p_rec_number    NUMBER
                              p_org_code      VARCHAR2
                              p_item_number   VARCHAR2
                              p_compitem_num  VARCHAR2
                              p_org_id        OUT NUMBER
                              p_org_code_orig OUT VARCHAR2

         Purpose          :   Derive the organization id for each bom componet records.
        -------------------------------------------------------------------------------------------------------------------------*/

             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           BEGIN

               x_org_code := xx_intg_common_pkg.get_mapping_value(p_mapping_type =>'ORGANIZATION_CODE'
                                  ,p_source      =>NULL
                                  ,p_old_value1   =>trim(p_org_code)
                                  ,p_old_value2   =>'XXINTGBOMCONV'
                                  ,p_date_effective => sysdate
                                  );

               SELECT mp.organization_id
                 INTO l_invorg_id1
                 FROM mtl_parameters mp
                WHERE mp.organization_code = x_org_code;
                p_org_id := l_invorg_id1;
                p_org_code_orig := x_org_code;
                RETURN  x_error_code;
            EXCEPTION
               WHEN no_data_found THEN
                  dbg_med('Organization Code does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Organization Code does not exist'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_num
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while deriving the Organization Code');
                  x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving the Organization Code'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_num
                        );
                RETURN  x_error_code;
            END get_org_id;

          FUNCTION get_assitem_id( p_rec_number NUMBER
                                  ,p_org_code VARCHAR2
                                  ,p_item_number VARCHAR2
                                  ,p_compitem_num VARCHAR2
                                  ,p_inv_item_id OUT NUMBER)
           RETURN number
           IS
          /*-------------------------------------------------------------------------------------------------------------------------
           Function  Name   :   get_assitem_id
           Parameters       : p_rec_number        NUMBER
                              p_org_code          VARCHAR2
                              p_item_number       VARCHAR2
                              p_compitem_num      VARCHAR2
                              p_inv_item_id  OUT  NUMBER

           Purpose          :   Derive the Assembly Item id for each bom componet records.
           -------------------------------------------------------------------------------------------------------------------------*/
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           BEGIN
               SELECT a.inventory_item_id
                 INTO l_assitem_id1
                 FROM mtl_system_items_b a
                WHERE a.segment1 = p_item_number
                     AND a.organization_id = l_invorg_id1
                     AND a.bom_enabled_flag = 'Y'
                     AND a.enabled_flag = 'Y';
                     p_inv_item_id := l_assitem_id1;
                     RETURN  x_error_code;
            EXCEPTION
               WHEN no_data_found THEN
                  dbg_med('Unable to derive BOM enabled Assembly Item id');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unable to derive BOM enabled Assembly Item id'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_num
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while deriving BOM enabled Component Item id');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving BOM enabled Assembly Item id'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_num
                        );
                   RETURN  x_error_code;
            END get_assitem_id;


          FUNCTION get_compitem_id(p_rec_number NUMBER
                                  ,p_org_code VARCHAR2
                                  ,p_item_number VARCHAR2
                                  ,p_compitem_num VARCHAR2
                                  ,p_inv_item_id OUT NUMBER)
           RETURN number
           IS
          /*-------------------------------------------------------------------------------------------------------------------------
           Function  Name   :   get_compitem_id
           Parameters       :     p_rec_number        NUMBER
                                  p_org_code          VARCHAR2
                                  p_item_number       VARCHAR2
                                  p_compitem_num      VARCHAR2
                                  p_inv_item_id   OUT NUMBER

           Purpose          :   Derive the Component Item id for each bom componet records.
           -------------------------------------------------------------------------------------------------------------------------*/

             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           BEGIN
               SELECT a.inventory_item_id
                 INTO l_compitem_id
                 FROM mtl_system_items_b a
                WHERE a.segment1 = p_compitem_num
                     AND a.organization_id = l_invorg_id1
                     AND a.bom_enabled_flag = 'Y'
                     AND a.enabled_flag = 'Y';
                     p_inv_item_id := l_compitem_id;
                     RETURN  x_error_code;
            EXCEPTION
               WHEN no_data_found THEN
                  dbg_med('Unable to derive BOM enabled Component Item id');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unable to derive BOM enabled Component Item id'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while deriving BOM enabled Component Item id');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving BOM enabled Component Item id'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => NULL
                        );
                   RETURN  x_error_code;
            END get_compitem_id;

         FUNCTION get_primary_uom( p_rec_number NUMBER
                                  ,p_org_code VARCHAR2
                                  ,p_item_number VARCHAR2
                                  ,p_compitem_number VARCHAR2
                                  ,p_primary_uom VARCHAR2
                                  ,p_derive_uom OUT VARCHAR2)
           RETURN number
           IS
         /*-------------------------------------------------------------------------------------------------------------------------
           Function  Name   :   get_primary_uom
           Parameters       :      p_rec_number      NUMBER
                                   p_org_code        VARCHAR2
                                   p_item_number     VARCHAR2
                                   p_compitem_number VARCHAR2
                                   p_primary_uom     VARCHAR2
                                   p_derive_uom OUT  VARCHAR2

           Purpose          :   Derive the primary unit of measure for each bom componet records.
           -------------------------------------------------------------------------------------------------------------------------*/

           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           begin
           /* IF p_primary_uom IS NULL THEN
                dbg_med('Primary_unit_of_measure can not be Null ');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Primary_unit_of_measure can not be Null'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                        );

              return x_error_code;
            ELSE*/
             BEGIN
               x_primary_uom := xx_intg_common_pkg.get_mapping_value(p_mapping_type =>'PRIMARY_UOM'
                                  ,p_source       =>NULL
                                  ,p_old_value1   =>trim(p_primary_uom)
                                  ,p_old_value2   =>'XXINTGBOMCONV'
                                  ,p_date_effective => sysdate
                                  );
               dbg_low('Mapped primary_unit_of_measure  : '||x_primary_uom);
               p_derive_uom :=  x_primary_uom ;
              /* IF x_primary_uom IS NULL THEN
                  dbg_med('Unable to derive primary_unit_of_measure');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unable to derive primary_unit_of_measure'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                        );
                END IF; */
             END;
             RETURN  x_error_code;
           -- END IF;
           END get_primary_uom;

         FUNCTION get_incl_cost_rollup(p_rec_number NUMBER
                                       ,p_org_code VARCHAR2
                                       ,p_item_number VARCHAR2
                                       ,p_compitem_number VARCHAR2
                                       ,p_cost_roll_up VARCHAR2
                                       ,p_cost_roll_up_orig OUT NUMBER)
           RETURN number
          /*-------------------------------------------------------------------------------------------------------------------------
           Function  Name   :   get_incl_cost_rollup
           Parameters       :      p_rec_number NUMBER
                                   p_org_code VARCHAR2
                                   p_item_number VARCHAR2
                                   p_compitem_number VARCHAR2
                                   p_cost_roll_up VARCHAR2
                                   p_cost_roll_up_orig OUT NUMBER

           Purpose          :   Derive the cost_roll_up for each bom componet records.
           -------------------------------------------------------------------------------------------------------------------------*/



           IS
           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           begin
             /*IF p_cost_roll_up IS NOT NULL THEN
                 IF UPPER(TRIM(p_cost_roll_up)) = 'Y'  THEN
                         p_cost_roll_up_orig := 1;
                 ELSIF UPPER(TRIM(p_cost_roll_up)) = 'N'  THEN
                         p_cost_roll_up_orig := 2;
                 END IF;
              END IF;  */
              p_cost_roll_up_orig := 1; -- Change on 02-APR-2012 after discussion with Ebey, It is always 1
              return x_error_code;
            END get_incl_cost_rollup;

         FUNCTION get_comp_yield_factor( p_rec_number NUMBER
                                        ,p_org_code VARCHAR2
                                        ,p_item_number VARCHAR2
                                        ,p_compitem_number VARCHAR2
                                        ,p_comp_yield_factor NUMBER
                                        ,p_comp_yield_factor_orig OUT NUMBER)
           RETURN number
           IS
          /*-------------------------------------------------------------------------------------------------------------------------
           Function  Name   :   get_comp_yield_factor
           Parameters       :      p_rec_number NUMBER
                                   p_org_code VARCHAR2
                                   p_item_number VARCHAR2
                                   p_compitem_number VARCHAR2
                                   p_comp_yield_factor NUMBER
                                   p_comp_yield_factor_orig OUT NUMBER

           Purpose          :   Derive the comp_yield_factor for each bom componet records.
           -------------------------------------------------------------------------------------------------------------------------*/


           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           begin
             IF p_comp_yield_factor IS NOT NULL THEN

                 p_comp_yield_factor_orig := ROUND((p_comp_yield_factor * (1/100)),2);

              END IF;
              return x_error_code;
            END get_comp_yield_factor;

         FUNCTION get_comp_seq_id( p_rec_number NUMBER
                                  ,p_org_code VARCHAR2
                                  ,p_item_number VARCHAR2
                                  ,p_compitem_number VARCHAR2
                                  ,p_alt_bom_designator VARCHAR2
                                  ,p_op_seq_num NUMBER
                                  ,p_comp_seq_id OUT NUMBER)
           RETURN number
           IS
          /*-------------------------------------------------------------------------------------------------------------------------
           Function  Name   :   get_comp_seq_id
           Parameters       :     p_rec_number         NUMBER
                                  p_org_code           VARCHAR2
                                  p_item_number        VARCHAR2
                                  p_compitem_number    VARCHAR2
                                  p_alt_bom_designator VARCHAR2
                                  p_op_seq_num         NUMBER
                                  p_comp_seq_id  OUT   NUMBER

           Purpose          :   Derive the component_seq_id for each bom componet records.
           -------------------------------------------------------------------------------------------------------------------------*/


           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           begin
            begin
             SELECT bill_sequence_id INTO x_bill_seq_id
                 FROM bom_bill_of_materials bom
              WHERE bom.assembly_item_id = l_assitem_id1
                 AND bom.organization_id = l_invorg_id1
                 AND nvl(bom.alternate_bom_designator,'xxx') = nvl(p_alt_bom_designator,'xxx');
                 dbg_low('The bill_sequence_id :'||x_bill_seq_id);
             exception
              WHEN OTHERS THEN
                  dbg_med('Unexpected error while deriving the component_sequence_id');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving the component_sequence_id'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                        );
                RETURN  x_error_code;
             end;

             begin
                SELECT component_sequence_id INTO x_comp_seq_id
                 FROM bom_inventory_components bic
              WHERE bic.component_item_id = l_compitem_id
                 AND bic.bill_sequence_id = x_bill_seq_id
                 AND bic.operation_seq_num = p_op_seq_num;
                 p_comp_seq_id := x_comp_seq_id;
                 dbg_low('The component_sequence_id :'||x_comp_seq_id);
                 return x_error_code;
              exception
                WHEN OTHERS THEN
                   dbg_med('Unexpected error while deriving the component_sequence_id');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving the component_sequence_id'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_item_number
                         ,p_record_identifier_4 => p_compitem_number
                        );
                RETURN  x_error_code;
              end;
              return x_error_code;
           END get_comp_seq_id;



     BEGIN
      g_api_name := 'bom_component_derivations';
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside bom_component_derivations');

      x_error_code_temp := get_org_id (p_bomcomp_rec.record_number,
                                          p_bomcomp_rec.organization_code,
                                          p_bomcomp_rec.assembly_item_number,
                                          p_bomcomp_rec.component_item_number,
                                          p_bomcomp_rec.organization_id,
                                          p_bomcomp_rec.organization_code_orig
		                                      );

       x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );

       x_error_code_temp := get_assitem_id (p_bomcomp_rec.record_number,
                                          p_bomcomp_rec.organization_code,
                                          p_bomcomp_rec.assembly_item_number,
                                          p_bomcomp_rec.component_item_number,
                                          p_bomcomp_rec.assembly_item_id
		                                      );

       x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );

       x_error_code_temp := get_compitem_id (p_bomcomp_rec.record_number,
                                          p_bomcomp_rec.organization_code,
                                          p_bomcomp_rec.assembly_item_number,
                                          p_bomcomp_rec.component_item_number,
                                          p_bomcomp_rec.component_item_id
		                                      );

       x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );

       x_error_code_temp := get_primary_uom(p_bomcomp_rec.record_number,
                                      p_bomcomp_rec.organization_code,
                                      p_bomcomp_rec.assembly_item_number,
		                                  p_bomcomp_rec.component_item_number,
                                      p_bomcomp_rec.primary_unit_of_measure,
                                      p_bomcomp_rec.primary_unit_of_measure_orig);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       x_error_code_temp := get_incl_cost_rollup(p_bomcomp_rec.record_number,
                                      p_bomcomp_rec.organization_code,
                                      p_bomcomp_rec.assembly_item_number,
		                                  p_bomcomp_rec.component_item_number,
                                      p_bomcomp_rec.include_in_cost_rollup,
                                      p_bomcomp_rec.include_in_cost_rollup_orig);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

       -- commented for WAVE1 on 22-JUL-2013
       /*x_error_code_temp := get_comp_yield_factor(p_bomcomp_rec.record_number,
                                      p_bomcomp_rec.organization_code,
                                      p_bomcomp_rec.assembly_item_number,
		                                  p_bomcomp_rec.component_item_number,
                                      p_bomcomp_rec.component_yield_factor,
                                      p_bomcomp_rec.component_yield_factor_orig);

	     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);*/


       IF g_bom_transaction_type = g_trans_type_delete THEN
          x_error_code_temp := get_comp_seq_id(p_bomcomp_rec.record_number,
                                      p_bomcomp_rec.organization_code,
                                      p_bomcomp_rec.assembly_item_number,
		                                  p_bomcomp_rec.component_item_number,
                                      p_bomcomp_rec.alternate_bom_designator,
                                      p_bomcomp_rec.operation_seq_num,
                                      p_bomcomp_rec.component_sequence_id);

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
   END bom_component_derivations;



   -- update_hdr_record_count
   PROCEDURE update_hdr_record_count(pr_validate_and_load IN VARCHAR2)
	 IS
	  /*-------------------------------------------------------------------------------------------------------------------------
     Procedure Name   :   update_hdr_record_count
     Parameters       :   pr_validate_and_load   IN  VARCHAR2


     Purpose          :   Counts success,error and warning records.
    -------------------------------------------------------------------------------------------------------------------------*/


   	CURSOR c_get_total_cnt IS
		SELECT COUNT (1) total_count
		  FROM XX_BOM_BILL_OF_MTLS_STG
		 WHERE batch_id = G_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID;

		x_total_cnt NUMBER;

		CURSOR c_get_error_cnt IS
		SELECT SUM(error_count)
		  FROM (
			SELECT COUNT (1) error_count
			  FROM XX_BOM_BILL_OF_MTLS_STG
			 WHERE batch_id   = G_BATCH_ID
			   AND request_id = xx_emf_pkg.G_REQUEST_ID
			   AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

		x_error_cnt NUMBER;

		CURSOR c_get_warning_cnt IS
		SELECT COUNT (1) warn_count
		  FROM XX_BOM_BILL_OF_MTLS_STG
		 WHERE batch_id = G_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

		x_warn_cnt NUMBER;

		CURSOR c_get_success_cnt IS
		SELECT COUNT (1) success_count
		  FROM XX_BOM_BILL_OF_MTLS_STG
		 WHERE batch_id = G_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
		   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

		x_success_cnt NUMBER;

    -- Added for if p_validate_only_flag is set to VALIDATE_ONLY Starts
    CURSOR c_get_success_valid_cnt IS
		SELECT COUNT (1) success_count
		  FROM XX_BOM_BILL_OF_MTLS_STG
		 WHERE batch_id = G_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND process_code = xx_emf_cn_pkg.CN_POSTVAL
		   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;
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
	END;


   PROCEDURE main( errbuf   OUT VARCHAR2
                                ,retcode  OUT VARCHAR2
                                ,p_batch_id      IN  VARCHAR2
                                ,p_comp_batch_id	IN VARCHAR2
                                ,p_bom_transaction_type IN VARCHAR2
                                ,p_restart_flag  IN  VARCHAR2
                                ,p_validate_and_load     IN VARCHAR2
                ) IS
   /*-------------------------------------------------------------------------------------------------------------------------
   Procedure Name   :   xxs_bom_import_main
   Parameters       :   x_errbuf                  OUT VARCHAR2
                        x_retcode                 OUT VARCHAR2
                        p_batch_id                IN  VARCHAR2
                        p_comp_batch_id           IN  VARCHAR2
                        p_bom_transaction_type    IN VARCHAR2
                        p_restart_flag            IN  VARCHAR2
                        p_validate_and_load       IN VARCHAR2

   Purpose          :   This is the main procedure which subsequently calls all other procedure.
   -------------------------------------------------------------------------------------------------------------------------*/

      x_error_code          NUMBER                := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp     NUMBER                := xx_emf_cn_pkg.CN_SUCCESS;

      x_bom_hdr_table         g_xx_bom_hdr_tab_type;
      x_bom_comp_table        g_xx_bom_comp_tab_type;

      -- BOM Header Cursor
        CURSOR c_xx_bom_header ( cp_process_status VARCHAR2)
        IS
         SELECT *
           FROM xx_bom_bill_of_mtls_stg
         WHERE batch_id     = G_BATCH_ID
           AND request_id   = xx_emf_pkg.G_REQUEST_ID
           AND process_code = cp_process_status
           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         ORDER BY record_number;

     -- BOM Component Cursor
     CURSOR c_xx_bom_comp( cp_process_status VARCHAR2)  IS
         SELECT *
               FROM xx_bom_inv_component_stg
           WHERE batch_id     = G_COMP_BATCH_ID
           AND request_id   = xx_emf_pkg.G_REQUEST_ID
           AND process_code = cp_process_status
           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         ORDER BY record_number;

     PROCEDURE update_hdr_record_status (
    		                    p_conv_hdr_rec  IN OUT  G_XX_BOM_HEADER_STG_REC_TYPE,
    		                    p_error_code            IN      VARCHAR2
    	       ) IS
      /*-------------------------------------------------------------------------------------------------------------------------
        Procedure Name   :   update_hdr_record_status
        Parameters       :   p_conv_hdr_rec  IN OUT  G_XX_BOM_HEADER_STG_REC_TYPE
    		                     p_error_code            IN      VARCHAR2

        Purpose          :   Update header record status as xx_emf_cn_pkg.CN_REC_ERR Error
       -------------------------------------------------------------------------------------------------------------------------*/
           BEGIN
        g_api_name := 'main.update_hdr_record_status';
    		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update record status...');

    		IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
    		THEN
    			p_conv_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
    		ELSE
    			p_conv_hdr_rec.error_code := xx_intg_common_pkg.find_max(p_error_code, NVL (p_conv_hdr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));

    		END IF;
    		p_conv_hdr_rec.process_code := G_STAGE;

    	END update_hdr_record_status;

   PROCEDURE update_comp_record_status (
		                                p_conv_comp_rec  IN OUT  G_XX_BOM_COMP_STG_REC_TYPE,
		                                p_error_code             IN      VARCHAR2
	       ) IS
    /*-------------------------------------------------------------------------------------------------------------------------
        Procedure Name   :   update_hdr_record_status
        Parameters       :   p_conv_comp_rec  IN OUT  G_XX_BOM_COMP_STG_REC_TYPE,
		                         p_error_code             IN      VARCHAR2

        Purpose          :   Update componenty record status as xx_emf_cn_pkg.CN_REC_ERR Error
       -------------------------------------------------------------------------------------------------------------------------*/

	BEGIN
	       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update line record status...');
	       g_api_name := 'main.update_comp_record_status';
	       IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
	       THEN
			p_conv_comp_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
	       ELSE
			p_conv_comp_rec.error_code := xx_intg_common_pkg.find_max(p_error_code, NVL (p_conv_comp_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));

	       END IF;
	       p_conv_comp_rec.process_code := G_STAGE;

	END update_comp_record_status;

  PROCEDURE update_header_int_records (p_cnv_bom_hdr_table IN g_xx_bom_hdr_tab_type)
            IS
            x_last_update_date      DATE := SYSDATE;
            x_last_updated_by       NUMBER := fnd_global.user_id;
            x_last_update_login     NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

            PRAGMA AUTONOMOUS_TRANSACTION;
      /*-------------------------------------------------------------------------------------------------------------------------
        Procedure Name   :   update_header_int_records
        Parameters       :   p_cnv_bom_hdr_table IN g_xx_bom_hdr_tab_type

        Purpose          :   Update BOM header staging table with updated values
       -------------------------------------------------------------------------------------------------------------------------*/

       BEGIN
           g_api_name := 'main.update_header_int_records';
            FOR indx IN 1 .. p_cnv_bom_hdr_table.COUNT LOOP
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_bom_import_hdr_table(indx).process_code ' || p_cnv_bom_hdr_table(indx).process_code);
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_bom_import_hdr_table(indx).error_code ' || p_cnv_bom_hdr_table(indx).error_code);

                   UPDATE xx_bom_bill_of_mtls_stg
                    SET assembly_item_id             = p_cnv_bom_hdr_table(indx).assembly_item_id             ,
                      organization_id                = p_cnv_bom_hdr_table(indx).organization_id              ,
                      alternate_bom_designator       = p_cnv_bom_hdr_table(indx).alternate_bom_designator     ,
                      last_update_date               = x_last_update_date,--p_cnv_bom_hdr_table(indx).last_update_date             ,
                      last_updated_by                = x_last_updated_by, --p_cnv_bom_hdr_table(indx).last_updated_by              ,
                      creation_date                  = p_cnv_bom_hdr_table(indx).creation_date                ,
                      created_by                     = p_cnv_bom_hdr_table(indx).created_by                   ,
                      last_update_login              = x_last_update_login, --p_cnv_bom_hdr_table(indx).last_update_login            ,
                      common_assembly_item_id        = p_cnv_bom_hdr_table(indx).common_assembly_item_id      ,
                      specific_assembly_comment      = p_cnv_bom_hdr_table(indx).specific_assembly_comment    ,
                      pending_from_ecn               = p_cnv_bom_hdr_table(indx).pending_from_ecn             ,
                      attribute_category             = p_cnv_bom_hdr_table(indx).attribute_category           ,
                      attribute1                     = p_cnv_bom_hdr_table(indx).attribute1                   ,
                      attribute2                     = p_cnv_bom_hdr_table(indx).attribute2                   ,
                      attribute3                     = p_cnv_bom_hdr_table(indx).attribute3                   ,
                      attribute4                     = p_cnv_bom_hdr_table(indx).attribute4                   ,
                      attribute5                     = p_cnv_bom_hdr_table(indx).attribute5                   ,
                      attribute6                     = p_cnv_bom_hdr_table(indx).attribute6                   ,
                      attribute7                     = p_cnv_bom_hdr_table(indx).attribute7                   ,
                      attribute8                     = p_cnv_bom_hdr_table(indx).attribute8                   ,
                      attribute9                     = p_cnv_bom_hdr_table(indx).attribute9                   ,
                      attribute10                    = p_cnv_bom_hdr_table(indx).attribute10                  ,
                      attribute11                    = p_cnv_bom_hdr_table(indx).batch_id  , --Batch_id tracking
                      attribute12                    = p_cnv_bom_hdr_table(indx).attribute12                  ,
                      attribute13                    = p_cnv_bom_hdr_table(indx).attribute13                  ,
                      attribute14                    = p_cnv_bom_hdr_table(indx).attribute14                  ,
                      attribute15                    = p_cnv_bom_hdr_table(indx).attribute15                  ,
                      assembly_type                  = p_cnv_bom_hdr_table(indx).assembly_type                ,
                      common_bill_sequence_id        = p_cnv_bom_hdr_table(indx).common_bill_sequence_id      ,
                      bill_sequence_id               = p_cnv_bom_hdr_table(indx).bill_sequence_id             ,
                      request_id                     = p_cnv_bom_hdr_table(indx).request_id                   ,
                      program_application_id         = p_cnv_bom_hdr_table(indx).program_application_id       ,
                      program_id                     = p_cnv_bom_hdr_table(indx).program_id                   ,
                      program_update_date            = p_cnv_bom_hdr_table(indx).program_update_date          ,
                      demand_source_line             = p_cnv_bom_hdr_table(indx).demand_source_line           ,
                      set_id                         = p_cnv_bom_hdr_table(indx).set_id                       ,
                      common_organization_id         = p_cnv_bom_hdr_table(indx).common_organization_id       ,
                      demand_source_type             = p_cnv_bom_hdr_table(indx).demand_source_type           ,
                      demand_source_header_id        = p_cnv_bom_hdr_table(indx).demand_source_header_id      ,
                      transaction_id                 = p_cnv_bom_hdr_table(indx).transaction_id               ,
                      process_flag                   = p_cnv_bom_hdr_table(indx).process_flag                 ,
                      organization_code              = p_cnv_bom_hdr_table(indx).organization_code            ,
                      common_org_code                = p_cnv_bom_hdr_table(indx).common_org_code              ,
                      item_number                    = p_cnv_bom_hdr_table(indx).item_number                  ,
                      common_item_number             = p_cnv_bom_hdr_table(indx).common_item_number           ,
                      next_explode_date              = p_cnv_bom_hdr_table(indx).next_explode_date            ,
                      revision                       = p_cnv_bom_hdr_table(indx).revision                     ,
                      transaction_type               = p_cnv_bom_hdr_table(indx).transaction_type             ,
                      delete_group_name              = p_cnv_bom_hdr_table(indx).delete_group_name            ,
                      dg_description                 = p_cnv_bom_hdr_table(indx).dg_description               ,
                      original_system_reference      = p_cnv_bom_hdr_table(indx).original_system_reference    ,
                      implementation_date            = p_cnv_bom_hdr_table(indx).implementation_date          ,
                      obj_name                       = p_cnv_bom_hdr_table(indx).obj_name                     ,
                      pk1_value                      = p_cnv_bom_hdr_table(indx).pk1_value                    ,
                      pk2_value                      = p_cnv_bom_hdr_table(indx).pk2_value                    ,
                      pk3_value                      = p_cnv_bom_hdr_table(indx).pk3_value                    ,
                      pk4_value                      = p_cnv_bom_hdr_table(indx).pk4_value                    ,
                      pk5_value                      = p_cnv_bom_hdr_table(indx).pk5_value                    ,
                      structure_type_name            = p_cnv_bom_hdr_table(indx).structure_type_name          ,
                      structure_type_id              = p_cnv_bom_hdr_table(indx).structure_type_id            ,
                      effectivity_control            = p_cnv_bom_hdr_table(indx).effectivity_control          ,
                      return_status                  = p_cnv_bom_hdr_table(indx).return_status                ,
                      is_preferred                   = p_cnv_bom_hdr_table(indx).is_preferred                 ,
                      source_system_reference        = p_cnv_bom_hdr_table(indx).source_system_reference      ,
                      source_system_reference_desc   = p_cnv_bom_hdr_table(indx).source_system_reference_desc ,
                      --batch_id                       = p_cnv_bom_hdr_table(indx).batch_id                     ,
                      --batch_id1                      = p_cnv_bom_hdr_table(indx).batch_id1                    ,-- new
                      change_id                      = p_cnv_bom_hdr_table(indx).change_id                    ,
                      catalog_category_name          = p_cnv_bom_hdr_table(indx).catalog_category_name        ,
                      item_catalog_group_id          = p_cnv_bom_hdr_table(indx).item_catalog_group_id        ,
                      primary_unit_of_measure        = p_cnv_bom_hdr_table(indx).primary_unit_of_measure      ,
                      item_description               = p_cnv_bom_hdr_table(indx).item_description             ,
                      template_name                  = p_cnv_bom_hdr_table(indx).template_name                ,
                      source_bill_sequence_id        = p_cnv_bom_hdr_table(indx).source_bill_sequence_id      ,
                      enable_attrs_update            = p_cnv_bom_hdr_table(indx).enable_attrs_update          ,
                      interface_table_unique_id      = p_cnv_bom_hdr_table(indx).interface_table_unique_id    ,
                      bundle_id                      = p_cnv_bom_hdr_table(indx).bundle_id                    ,
                      source_system_name             = p_cnv_bom_hdr_table(indx).source_system_name           ,
                      organization_code_orig         = p_cnv_bom_hdr_table(indx).organization_code_orig       ,
                      process_code                   = p_cnv_bom_hdr_table(indx).process_code                 ,
                      error_code                     = p_cnv_bom_hdr_table(indx).error_code                   ,
                      error_mesg                     = p_cnv_bom_hdr_table(indx).error_mesg
                     -- record_number                  = p_cnv_bom_hdr_table(indx).record_number                ,
                    WHERE record_number = p_cnv_bom_hdr_table(indx).record_number
                           AND   BATCH_ID = G_BATCH_ID;

            END LOOP;

            COMMIT;
    END update_header_int_records;

    PROCEDURE update_comp_int_records (p_cnv_bom_comp_table IN g_xx_bom_comp_tab_type)
	    IS
		x_last_update_date     DATE   := SYSDATE;
		x_last_updated_by      NUMBER := fnd_global.user_id;
		x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

	        PRAGMA AUTONOMOUS_TRANSACTION;
	  /*-------------------------------------------------------------------------------------------------------------------------
        Procedure Name   :   update_comp_int_records
        Parameters       :   p_cnv_bom_comp_table IN g_xx_bom_comp_tab_type

        Purpose          :   Update BOM Component staging table with updated values
      -------------------------------------------------------------------------------------------------------------------------*/

  BEGIN
    g_api_name := 'main.update_comp_int_records';
    fnd_file.put_line(fnd_file.log,'Inside of update component interface records...');
    FOR indx IN 1 .. p_cnv_bom_comp_table.COUNT
    LOOP
   	 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_bom_comp_table(indx).process_code ' || p_cnv_bom_comp_table(indx).process_code);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_bom_comp_table(indx).error_code ' || p_cnv_bom_comp_table(indx).error_code);

     UPDATE xx_bom_inv_component_stg
			SET acd_type  													= p_cnv_bom_comp_table(indx).acd_type,
          alternate_bom_designator  					= p_cnv_bom_comp_table(indx).alternate_bom_designator,
          assembly_item_id  									= p_cnv_bom_comp_table(indx).assembly_item_id,
          assembly_item_number  							= p_cnv_bom_comp_table(indx).assembly_item_number,
          assembly_type 											= p_cnv_bom_comp_table(indx).assembly_type,
          attribute_category  								= p_cnv_bom_comp_table(indx).attribute_category,
          attribute1  												= p_cnv_bom_comp_table(indx).attribute1,
          attribute10 												= p_cnv_bom_comp_table(indx).attribute10,
          attribute11 												= p_cnv_bom_comp_table(indx).batch_id, --Batch_id tracking
          attribute12 												= p_cnv_bom_comp_table(indx).attribute12,
          attribute13 												= p_cnv_bom_comp_table(indx).attribute13,
          attribute14 												= p_cnv_bom_comp_table(indx).attribute14,
          attribute15 												= p_cnv_bom_comp_table(indx).attribute15,
          attribute2  												= p_cnv_bom_comp_table(indx).attribute2,
          attribute3  												= p_cnv_bom_comp_table(indx).attribute3,
          attribute4  												= p_cnv_bom_comp_table(indx).attribute4,
          attribute5  												= p_cnv_bom_comp_table(indx).attribute5,
          attribute6  												= p_cnv_bom_comp_table(indx).attribute6,
          attribute7  												= p_cnv_bom_comp_table(indx).attribute7,
          attribute8  												= p_cnv_bom_comp_table(indx).attribute8,
          attribute9  												= p_cnv_bom_comp_table(indx).attribute9,
          auto_request_material 							= p_cnv_bom_comp_table(indx).auto_request_material,
          basis_type  												= p_cnv_bom_comp_table(indx).basis_type,
        --  batch_id  													= p_cnv_bom_comp_table(indx).batch_id,
        --  batch_id1  													= p_cnv_bom_comp_table(indx).batch_id1, -- new
          bill_sequence_id  									= p_cnv_bom_comp_table(indx).bill_sequence_id,
          bom_inventory_comps_ifce_key  			= p_cnv_bom_comp_table(indx).bom_inventory_comps_ifce_key,
          bom_item_type 											= p_cnv_bom_comp_table(indx).bom_item_type,
          bundle_id 													= p_cnv_bom_comp_table(indx).bundle_id,
          catalog_category_name 							= p_cnv_bom_comp_table(indx).catalog_category_name,
          change_id 													= p_cnv_bom_comp_table(indx).change_id,
          change_notice 											= p_cnv_bom_comp_table(indx).change_notice,
          change_transaction_type 						= p_cnv_bom_comp_table(indx).change_transaction_type,
          check_atp 													= p_cnv_bom_comp_table(indx).check_atp,
          common_component_sequence_id  			= p_cnv_bom_comp_table(indx).common_component_sequence_id,
          comp_source_system_refer_desc 			= p_cnv_bom_comp_table(indx).comp_source_system_refer_desc,
          comp_source_system_reference  			= p_cnv_bom_comp_table(indx).comp_source_system_reference,
          component_item_id 									= p_cnv_bom_comp_table(indx).component_item_id,
          component_item_number 							= p_cnv_bom_comp_table(indx).component_item_number,
          component_quantity  								= p_cnv_bom_comp_table(indx).component_quantity,
          component_remarks 									= p_cnv_bom_comp_table(indx).component_remarks,
          component_revision_code 						= p_cnv_bom_comp_table(indx).component_revision_code,
          component_revision_id 							= p_cnv_bom_comp_table(indx).component_revision_id,
          component_sequence_id 							= p_cnv_bom_comp_table(indx).component_sequence_id,
          component_yield_factor  						= p_cnv_bom_comp_table(indx).component_yield_factor,
          cost_factor 												= p_cnv_bom_comp_table(indx).cost_factor,
          created_by  												= p_cnv_bom_comp_table(indx).created_by,
          creation_date 											= p_cnv_bom_comp_table(indx).creation_date,
          ddf_context1  											= p_cnv_bom_comp_table(indx).ddf_context1,
          ddf_context2  											= p_cnv_bom_comp_table(indx).ddf_context2,
          delete_group_name 									= p_cnv_bom_comp_table(indx).delete_group_name,
          dg_description  										= p_cnv_bom_comp_table(indx).dg_description,
          disable_date 												= p_cnv_bom_comp_table(indx).disable_date,
          effectivity_date  									= p_cnv_bom_comp_table(indx).effectivity_date,
          enforce_int_requirements  					= p_cnv_bom_comp_table(indx).enforce_int_requirements,
          eng_changes_ifce_key  							= p_cnv_bom_comp_table(indx).eng_changes_ifce_key,
          eng_revised_items_ifce_key  				= p_cnv_bom_comp_table(indx).eng_revised_items_ifce_key,
          from_end_item 											= p_cnv_bom_comp_table(indx).from_end_item,
          from_end_item_id  									= p_cnv_bom_comp_table(indx).from_end_item_id,
          from_end_item_minor_rev_code  			= p_cnv_bom_comp_table(indx).from_end_item_minor_rev_code,
          from_end_item_minor_rev_id  				= p_cnv_bom_comp_table(indx).from_end_item_minor_rev_id,
          from_end_item_rev_code  						= p_cnv_bom_comp_table(indx).from_end_item_rev_code,
          from_end_item_rev_id  							= p_cnv_bom_comp_table(indx).from_end_item_rev_id,
          from_end_item_unit_number 					= p_cnv_bom_comp_table(indx).from_end_item_unit_number,
          from_minor_revision_code  					= p_cnv_bom_comp_table(indx).from_minor_revision_code,
          from_minor_revision_id  						= p_cnv_bom_comp_table(indx).from_minor_revision_id,
          from_object_revision_code 					= p_cnv_bom_comp_table(indx).from_object_revision_code,
          from_object_revision_id 						= p_cnv_bom_comp_table(indx).from_object_revision_id,
          high_quantity 											= p_cnv_bom_comp_table(indx).high_quantity,
          implementation_date 								= p_cnv_bom_comp_table(indx).implementation_date,
          include_in_cost_rollup  						= p_cnv_bom_comp_table(indx).include_in_cost_rollup,
          include_on_bill_docs  							= p_cnv_bom_comp_table(indx).include_on_bill_docs,
          include_on_ship_docs  							= p_cnv_bom_comp_table(indx).include_on_ship_docs,
          interface_entity_type 							= p_cnv_bom_comp_table(indx).interface_entity_type,
          interface_table_unique_id 					= p_cnv_bom_comp_table(indx).interface_table_unique_id,
          inverse_quantity  									= p_cnv_bom_comp_table(indx).inverse_quantity,
          item_catalog_group_id 							= p_cnv_bom_comp_table(indx).item_catalog_group_id,
          item_description  									= p_cnv_bom_comp_table(indx).item_description,
          item_num  													= p_cnv_bom_comp_table(indx).item_num,
          last_update_date  									= x_last_update_date, --p_cnv_bom_comp_table(indx).last_update_date,
          last_update_login 									= x_last_update_login, --p_cnv_bom_comp_table(indx).last_update_login,
          last_updated_by 										= x_last_updated_by, --p_cnv_bom_comp_table(indx).last_updated_by,
          location_name 											= p_cnv_bom_comp_table(indx).location_name,
          low_quantity  											= p_cnv_bom_comp_table(indx).low_quantity,
          model_comp_seq_id 									= p_cnv_bom_comp_table(indx).model_comp_seq_id,
          mutually_exclusive_options  				= p_cnv_bom_comp_table(indx).mutually_exclusive_options,
          new_effectivity_date  							= p_cnv_bom_comp_table(indx).new_effectivity_date,
          new_from_end_item_unit_number 			= p_cnv_bom_comp_table(indx).new_from_end_item_unit_number,
          new_operation_seq_num 							= p_cnv_bom_comp_table(indx).new_operation_seq_num,
          new_revised_item_revision 					= p_cnv_bom_comp_table(indx).new_revised_item_revision,
          obj_name  													= p_cnv_bom_comp_table(indx).obj_name,
          old_component_sequence_id 					= p_cnv_bom_comp_table(indx).old_component_sequence_id,
          old_effectivity_date  							= p_cnv_bom_comp_table(indx).old_effectivity_date,
          old_operation_seq_num 							= p_cnv_bom_comp_table(indx).old_operation_seq_num,
          operation_lead_time_percent 				= p_cnv_bom_comp_table(indx).operation_lead_time_percent,
          operation_seq_num 									= p_cnv_bom_comp_table(indx).operation_seq_num,
          optional  													= p_cnv_bom_comp_table(indx).optional,
          optional_on_model 									= p_cnv_bom_comp_table(indx).optional_on_model,
          organization_code 									= p_cnv_bom_comp_table(indx).organization_code,
          organization_id 										= p_cnv_bom_comp_table(indx).organization_id,
          original_system_reference 					= p_cnv_bom_comp_table(indx).original_system_reference,
          parent_bill_seq_id  								= p_cnv_bom_comp_table(indx).parent_bill_seq_id,
          parent_revision_code  							= p_cnv_bom_comp_table(indx).parent_revision_code,
          parent_revision_id  								= p_cnv_bom_comp_table(indx).parent_revision_id,
          parent_source_system_reference  		= p_cnv_bom_comp_table(indx).parent_source_system_reference,
          pick_components 										= p_cnv_bom_comp_table(indx).pick_components,
          pk1_value 													= p_cnv_bom_comp_table(indx).pk1_value,
          pk2_value 													= p_cnv_bom_comp_table(indx).pk2_value,
          pk3_value 													= p_cnv_bom_comp_table(indx).pk3_value,
          pk4_value 													= p_cnv_bom_comp_table(indx).pk4_value,
          pk5_value 													= p_cnv_bom_comp_table(indx).pk5_value,
          plan_level  												= p_cnv_bom_comp_table(indx).plan_level,
          planning_factor 										= p_cnv_bom_comp_table(indx).planning_factor,
          primary_unit_of_measure 						= p_cnv_bom_comp_table(indx).primary_unit_of_measure,
          process_flag  											= p_cnv_bom_comp_table(indx).process_flag,
          program_application_id  						= p_cnv_bom_comp_table(indx).program_application_id,
          program_id  												= p_cnv_bom_comp_table(indx).program_id,
          program_update_date 								= p_cnv_bom_comp_table(indx).program_update_date,
          quantity_related  									= p_cnv_bom_comp_table(indx).quantity_related,
          reference_designator  							= p_cnv_bom_comp_table(indx).reference_designator,
          request_id  												= p_cnv_bom_comp_table(indx).request_id,
          required_for_revenue  							= p_cnv_bom_comp_table(indx).required_for_revenue,
          required_to_ship  									= p_cnv_bom_comp_table(indx).required_to_ship,
          return_status 											= p_cnv_bom_comp_table(indx).return_status,
          revised_item_number 								= p_cnv_bom_comp_table(indx).revised_item_number,
          revised_item_sequence_id  					= p_cnv_bom_comp_table(indx).revised_item_sequence_id,
          shipping_allowed  									= p_cnv_bom_comp_table(indx).shipping_allowed,
          so_basis  													= p_cnv_bom_comp_table(indx).so_basis,
          substitute_comp_id  								= p_cnv_bom_comp_table(indx).substitute_comp_id,
          substitute_comp_number  						= p_cnv_bom_comp_table(indx).substitute_comp_number,
          suggested_vendor_name 							= p_cnv_bom_comp_table(indx).suggested_vendor_name,
          supply_locator_id 									= p_cnv_bom_comp_table(indx).supply_locator_id,
          supply_subinventory 								= p_cnv_bom_comp_table(indx).supply_subinventory,
          template_name 											= p_cnv_bom_comp_table(indx).template_name,
          to_end_item_minor_rev_code  				= p_cnv_bom_comp_table(indx).to_end_item_minor_rev_code,
          to_end_item_minor_rev_id  					= p_cnv_bom_comp_table(indx).to_end_item_minor_rev_id,
          to_end_item_rev_code  							= p_cnv_bom_comp_table(indx).to_end_item_rev_code,
          to_end_item_rev_id  								= p_cnv_bom_comp_table(indx).to_end_item_rev_id,
          to_end_item_unit_number 						= p_cnv_bom_comp_table(indx).to_end_item_unit_number,
          to_minor_revision_code  						= p_cnv_bom_comp_table(indx).to_minor_revision_code,
          to_minor_revision_id  							= p_cnv_bom_comp_table(indx).to_minor_revision_id,
          to_object_revision_code 						= p_cnv_bom_comp_table(indx).to_object_revision_code,
          to_object_revision_id 							= p_cnv_bom_comp_table(indx).to_object_revision_id,
          transaction_id  										= p_cnv_bom_comp_table(indx).transaction_id,
          transaction_type  									= p_cnv_bom_comp_table(indx).transaction_type,
          unit_price  												= p_cnv_bom_comp_table(indx).unit_price,
          wip_supply_type 										= p_cnv_bom_comp_table(indx).wip_supply_type,
          --record_number                     	= p_cnv_bom_comp_table(indx).record_number,
          --rec_number                        	= p_cnv_bom_comp_table(indx).rec_number,
          source_system_name                	= p_cnv_bom_comp_table(indx).source_system_name,
          organization_code_orig              = p_cnv_bom_comp_table(indx).organization_code_orig,  -- used for mapping
          primary_unit_of_measure_orig        = p_cnv_bom_comp_table(indx).primary_unit_of_measure_orig, -- used for mapping
          include_in_cost_rollup_orig         = p_cnv_bom_comp_table(indx).include_in_cost_rollup_orig,
          component_yield_factor_orig         = p_cnv_bom_comp_table(indx).component_yield_factor_orig,
          process_code                      	= p_cnv_bom_comp_table(indx).process_code,
          error_code                        	= p_cnv_bom_comp_table(indx).error_code,
          error_mesg                        	= p_cnv_bom_comp_table(indx).error_mesg
        WHERE record_number		                  =	p_cnv_bom_comp_table(indx).record_number
		      AND   BATCH_ID = G_COMP_BATCH_ID;
		END LOOP;

		COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'ERROR HERE...');

	END update_comp_int_records;

    -- mark_records_complete
    PROCEDURE mark_records_complete ( p_process_code	VARCHAR2,
	                                    p_level		VARCHAR2
	                                   )
         IS
     /*-------------------------------------------------------------------------------------------------------------------------
        Procedure Name   :   update_header_int_records
        Parameters       :   p_process_code	VARCHAR2,
	                           p_level		    VARCHAR2

        Purpose          :   Update the rcords of BOM header and Bom component staging table with "Processed"
       -------------------------------------------------------------------------------------------------------------------------*/

		x_last_update_date       DATE   := SYSDATE;
		x_last_updated_by        NUMBER := fnd_global.user_id;
		x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

		PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of mark records complete...');
    g_api_name := 'main.mark_records_complete';
		IF p_level = 'BOM_HDR' THEN

		   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside mark_records_complete :: p_level: '||p_level);

			UPDATE xx_bom_bill_of_mtls_stg	--Header
			   SET process_code      = G_STAGE,
			       error_code        = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
			       last_updated_by   = x_last_updated_by,
			       last_update_date  = x_last_update_date,
			       last_update_login = x_last_update_login
			 WHERE batch_id     = G_BATCH_ID
			   AND request_id   = xx_emf_pkg.G_REQUEST_ID
			   AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
			   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

		ELSIF p_level = 'BOM_COMP' THEN

		    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside mark_records_complete :: p_level: '||p_level);

			UPDATE xx_bom_inv_component_stg	-- Line level
			   SET process_code      = G_STAGE,
			       error_code        = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
			       last_updated_by   = x_last_updated_by,
			       last_update_date  = x_last_update_date,
			       last_update_login = x_last_update_login
			 WHERE batch_id     = G_COMP_BATCH_ID
			   AND request_id   = xx_emf_pkg.G_REQUEST_ID
			   AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
			   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);
		END IF;
		COMMIT;

	EXCEPTION
		WHEN OTHERS THEN
	            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in Update of mark_records_complete '||SQLERRM);
	END mark_records_complete;

  PROCEDURE header_delete_grp(p_delete_group_name OUT VARCHAR2,p_description OUT VARCHAR2)
    IS

    /*-------------------------------------------------------------------------------------------------------------------------
        Procedure Name   :   header_delete_grp
        Parameters       :   p_delete_group_name OUT VARCHAR2
                             p_description       OUT VARCHAR2
        Purpose          :   Derives the BOM Header delete group
       -------------------------------------------------------------------------------------------------------------------------*/
       x_entity_name        VARCHAR2(50):=NULL;
     BEGIN
       -- Find delete group for header

        BEGIN
            SELECT entity_name,delete_group_name,description
                INTO x_entity_name,p_delete_group_name,p_description
              FROM BOM_INTERFACE_DELETE_GROUPS
                WHERE entity_name = 'BOM_BILL_OF_MTLS_INTERFACE';
         EXCEPTION
             WHEN NO_DATA_FOUND THEN
               insert into BOM_INTERFACE_DELETE_GROUPS(entity_name,delete_group_name,description)
                values('BOM_BILL_OF_MTLS_INTERFACE','COSTBOMHD','Costing BOM Header Deletion');
                commit;
                dbg_low('Inserting 1st row into  BOM_INTERFACE_DELETE_GROUPS Tables.');
                p_delete_group_name := 'COSTBOMHD';
                p_description := 'Costing BOM Header Deletion';

             WHEN OTHERS THEN
                dbg_low('ERROR in deriving BOM header delete group');
         END;
   END header_delete_grp;

   PROCEDURE comp_delete_grp(p_delete_group_name OUT VARCHAR2,p_description OUT VARCHAR2)
    IS
       x_entity_name        VARCHAR2(50):=NULL;
    /*-------------------------------------------------------------------------------------------------------------------------
        Procedure Name   :   comp_delete_grp
        Parameters       :   p_delete_group_name OUT VARCHAR2
                             p_description       OUT VARCHAR2
        Purpose          :   Derives the BOM Compponent delete group
     -------------------------------------------------------------------------------------------------------------------------*/
     BEGIN
         -- Find delete group for component

         BEGIN
            SELECT entity_name,delete_group_name,description
                INTO x_entity_name,p_delete_group_name,p_description
              FROM BOM_INTERFACE_DELETE_GROUPS
                WHERE entity_name = 'BOM_INVENTORY_COMPS_INTERFACE';
         EXCEPTION
             WHEN NO_DATA_FOUND THEN
               insert into BOM_INTERFACE_DELETE_GROUPS(entity_name,delete_group_name,description)
                values('BOM_INVENTORY_COMPS_INTERFACE','COSTBOMCMP','Costing BOM Component Deletion');
                commit;
                dbg_low('Inserting 2nd row into into BOM_INTERFACE_DELETE_GROUPS Tables.');
                p_delete_group_name := 'COSTBOMCMP';
                p_description := 'Costing BOM Component Deletion';
             WHEN OTHERS THEN
                dbg_low('ERROR in deriving BOM Component delete group');
          END;
      END comp_delete_grp;

  -- mark_records_for_api_error
  PROCEDURE mark_records_for_api_error(p_process_code IN VARCHAR2)
	IS
	 /*-------------------------------------------------------------------------------------------------------------------------
        Procedure Name   :   mark_records_for_api_error
        Parameters       :   p_process_code IN VARCHAR2

        Purpose          :   Marks records with "Error" which are failed in Interface table
     -------------------------------------------------------------------------------------------------------------------------*/

  		x_last_update_date       DATE := SYSDATE;
			x_last_updated_by        NUMBER := fnd_global.user_id;
			x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
      x_record_count           NUMBER;
			PRAGMA AUTONOMOUS_TRANSACTION;
		BEGIN
		   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside Mark Record for API Error');
		   UPDATE xx_bom_bill_of_mtls_stg xbom
		     SET process_code = G_STAGE,
		         error_code   = xx_emf_cn_pkg.CN_REC_ERR,
             error_mesg   ='INTERFACE Error : Errored out inside BOM_BILL_OF_MTLS_INTERFACE',
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
		                   FROM bom_bill_of_mtls_interface bbom
		                  WHERE 1=1
		                    AND bbom.item_number    = xbom.item_number
                        AND bbom.organization_code = xbom.organization_code_orig
                        AND nvl(bbom.alternate_bom_designator,'xxx') = nvl(xbom.alternate_bom_designator,'xxx')
                        AND bbom.attribute11=xbom.batch_id
                        AND xbom.batch_id = G_BATCH_ID
		                    AND bbom.process_flag <> 7
		                 );

		   x_record_count := SQL%ROWCOUNT;
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No of BOM Header Record Marked with API Error=>'||x_record_count);
		   COMMIT;

       -- update component records
       x_record_count := 0;

       UPDATE xx_bom_inv_component_stg xbics
		     SET process_code = G_STAGE,
		         error_code   = xx_emf_cn_pkg.CN_REC_ERR,
             error_mesg   ='INTERFACE Error : Errored out inside BOM_INVENTORY_COMPS_INTERFACE',
		         last_updated_by   = x_last_updated_by,
		         last_update_date  = x_last_update_date,
		         last_update_login = x_last_update_login
		   WHERE batch_id    = G_COMP_BATCH_ID
		     AND process_code  = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
		                                , xx_emf_cn_pkg.CN_POSTVAL
		                                , xx_emf_cn_pkg.CN_DERIVE
		                                )
		     AND error_code    IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
		     AND Exists (SELECT 1
		                   FROM bom_inventory_comps_interface bic
		                  WHERE 1=1
		                    AND bic.assembly_item_number    = xbics.assembly_item_number
                        AND bic.component_item_number    = xbics.component_item_number
                        AND bic.organization_code = xbics.organization_code_orig
                        AND nvl(bic.alternate_bom_designator,'xxx') = nvl(xbics.alternate_bom_designator,'xxx')
                        AND bic.attribute11=xbics.batch_id
                        AND xbics.batch_id = G_COMP_BATCH_ID
		                    AND bic.process_flag <> 7
		                 );

		   x_record_count := SQL%ROWCOUNT;
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No of BOM Component Record Marked with API Error=>'||x_record_count);
		   COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while updating staging Tables with API error: ' ||SQLERRM);
		END mark_records_for_api_error;


   --print_records_with_api_error
    PROCEDURE print_records_with_api_error
  		IS
     /*-------------------------------------------------------------------------------------------------------------------------
        Procedure Name   :   mark_records_for_api_error
        Parameters       :   p_process_code IN VARCHAR2

        Purpose          :   Print records which are Marks records with "Error"  in Interface table
     -------------------------------------------------------------------------------------------------------------------------*/
         CURSOR c_print_err_head_records
             IS
           SELECT  xbom.item_number
  		            ,xbom.organization_code
  		            ,xbom.error_code
  		            ,trim(translate(mie.message_name||':'||mie.error_message,CHR(13)||CHR(10)||CHR(9),'   ')) error_mesg
  		            ,xbom.record_number
  		     FROM bom_bill_of_mtls_interface bbom
  		   	    ,xx_bom_bill_of_mtls_stg xbom
              ,mtl_interface_errors mie
  		     WHERE 1=1
             AND bbom.item_number    = xbom.item_number
             AND bbom.organization_code = xbom.organization_code_orig
             AND nvl(bbom.alternate_bom_designator,'xxx') = nvl(xbom.alternate_bom_designator,'xxx')
             AND bbom.attribute11=xbom.batch_id
             AND xbom.batch_id = G_BATCH_ID
             AND mie.transaction_id = bbom.transaction_id
             AND mie.request_id = bbom.request_id
             AND bbom.process_flag <> 7;

         -- component cursor
       CURSOR c_print_err_comp_records
             IS
          SELECT xbics.assembly_item_number
  		         ,xbics.organization_code
  		         ,xbics.error_code
  		         ,trim(translate(mie.message_name||':'||mie.error_message,CHR(13)||CHR(10)||CHR(9),'   ')) error_mesg
  		         ,xbics.record_number
               ,xbics.component_item_number
  		    FROM bom_inventory_comps_interface bic
  		   	     ,xx_bom_inv_component_stg xbics
               ,mtl_interface_errors mie
  		  WHERE 1=1
            AND bic.assembly_item_number    = xbics.assembly_item_number
            AND bic.component_item_number   = xbics.component_item_number
            AND bic.organization_code = xbics.organization_code_orig
            AND nvl(bic.alternate_bom_designator,'xxx') = nvl(xbics.alternate_bom_designator,'xxx')
            AND bic.attribute11 = xbics.batch_id
            AND xbics.batch_id  = G_COMP_BATCH_ID
            AND mie.transaction_id = bic.transaction_id
            AND mie.request_id = bic.request_id
            AND bic.process_flag <> 7;

  		BEGIN
        dbg_low('Inside print_records_with_api_error');
        dbg_low('Printing Header Error records');
        FOR cur_rec IN c_print_err_head_records
        LOOP
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
	               ,p_category    => xx_emf_cn_pkg.CN_STG_APICALL
                 ,p_error_text  => cur_rec.error_mesg
                 ,p_record_identifier_1 => cur_rec.record_number
                 ,p_record_identifier_2 => cur_rec.organization_code
                 ,p_record_identifier_3 => cur_rec.item_number
              );
  		   END LOOP;

         dbg_low('Printing Component Error records');
         FOR cur_rec1 IN c_print_err_comp_records
         LOOP
           xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
	               ,p_category    => xx_emf_cn_pkg.CN_STG_APICALL
                 ,p_error_text  => cur_rec1.error_mesg
                 ,p_record_identifier_1 => cur_rec1.record_number
                 ,p_record_identifier_2 => cur_rec1.organization_code
                 ,p_record_identifier_3 => cur_rec1.assembly_item_number
                 ,p_record_identifier_4 => cur_rec1.component_item_number
              );
  		    END LOOP;

  		END print_records_with_api_error;

  PROCEDURE print_staging_error_records
    IS
	  /*-------------------------------------------------------------------------------------------------------------------------
     Procedure Name   :   print_staging_error_records
     Parameters       :


     Purpose          :   Prints error records from staging table
    -------------------------------------------------------------------------------------------------------------------------*/
      CURSOR c_print_err_head_records
             IS
          SELECT xbom.item_number
  		         ,xbom.organization_code
  		         ,xbom.error_code
  		         ,xbom.error_mesg
  		         ,xbom.record_number
  		    FROM xx_bom_bill_of_mtls_stg xbom
  		  WHERE 1=1
            AND xbom.batch_id = G_BATCH_ID
            AND xbom.error_mesg IS NOT NULL
            AND NOT EXISTS( SELECT 1
                               FROM  mtl_interface_errors mie
                                     ,bom_bill_of_mtls_interface bbom
                               WHERE mie.transaction_id = bbom.transaction_id
                                 AND mie.request_id = bbom.request_id
                                 AND bbom.item_number    = xbom.item_number
                                 AND bbom.organization_code = xbom.organization_code_orig
                                 AND nvl(bbom.alternate_bom_designator,'xxx') = nvl(xbom.alternate_bom_designator,'xxx')
                                 AND bbom.attribute11=xbom.batch_id);

         -- component cursor
       CURSOR c_print_err_comp_records
             IS
         SELECT xbics.assembly_item_number
  		         ,xbics.organization_code
  		         ,xbics.error_code
  		         ,xbics.error_mesg
               ,xbics.component_item_number
  		         ,xbics.record_number
  		    FROM xx_bom_inv_component_stg xbics
  		  WHERE 1=1
            AND xbics.batch_id = G_COMP_BATCH_ID
            AND xbics.error_mesg IS NOT NULL
            AND NOT EXISTS( SELECT 1
                               FROM  mtl_interface_errors mie
                                     ,bom_inventory_comps_interface bic
                               WHERE mie.transaction_id = bic.transaction_id
                                 AND mie.request_id = bic.request_id
                                 AND bic.assembly_item_number  = xbics.assembly_item_number
                                 AND bic.component_item_number = xbics.component_item_number
                                 AND bic.organization_code = xbics.organization_code_orig
                                 AND nvl(bic.alternate_bom_designator,'xxx') = nvl(xbics.alternate_bom_designator,'xxx')
                                 AND bic.attribute11 = xbics.batch_id);

  		BEGIN
        dbg_low('Inside print_staging_error_records');
        dbg_low('Printing Staging Header Error records');
        FOR cur_rec IN c_print_err_head_records
        LOOP
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
	               ,p_category    => xx_emf_cn_pkg.CN_VALID
                 ,p_error_text  => cur_rec.error_mesg
                 ,p_record_identifier_1 => cur_rec.record_number
                 ,p_record_identifier_2 => cur_rec.organization_code
                 ,p_record_identifier_3 => cur_rec.item_number
              );
  		   END LOOP;

         dbg_low('Printing Staging Component Error records');
         FOR cur_rec1 IN c_print_err_comp_records
         LOOP
           xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
	               ,p_category    => xx_emf_cn_pkg.CN_VALID
                 ,p_error_text  => cur_rec1.error_mesg
                 ,p_record_identifier_1 => cur_rec1.record_number
                 ,p_record_identifier_2 => cur_rec1.organization_code
                 ,p_record_identifier_3 => cur_rec1.assembly_item_number
                 ,p_record_identifier_4 => cur_rec1.component_item_number
              );
  		    END LOOP;
   END print_staging_error_records;

  FUNCTION bom_insert_interface(p_bom_trans_type VARCHAR2)
    RETURN NUMBER
	 IS
   /*-------------------------------------------------------------------------------------------------------------------------
        Procedure Name   :   bom_insert_interface
        Parameters       :   p_bom_trans_type IN VARCHAR2

        Purpose          :   Insert records into BOM  in Interface tables
     -------------------------------------------------------------------------------------------------------------------------*/

		x_return_status       VARCHAR2(15)  := xx_emf_cn_pkg.CN_SUCCESS;
    x_head_del_grp        VARCHAR2(10)  := NULL;
    x_head_del_desc       VARCHAR2(240) := NULL;
    x_comp_del_grp        VARCHAR2(10)  := NULL;
    x_comp_del_desc       VARCHAR2(240) := NULL;
    x_cmmit_header        NUMBER :=0;
    x_cmmit_comp          NUMBER :=0;
    x_commit_sequence     NUMBER := 10000;
      --cursor to insert into bom interface table
      CURSOR c_xx_bomh_intupld(cp_process_status VARCHAR2) IS
         SELECT record_number,
                assembly_item_id ,
                organization_id ,
                alternate_bom_designator ,
                last_update_date ,
                last_updated_by ,
                creation_date,
                created_by ,
                last_update_login ,
                common_assembly_item_id  ,
                specific_assembly_comment ,
                pending_from_ecn ,
                attribute_category  ,
                attribute1 ,
                attribute2 ,
                attribute3 ,
                attribute4  ,
                attribute5  ,
                attribute6  ,
                attribute7  ,
                attribute8  ,
                attribute9  ,
                attribute10 ,
                attribute11  ,
                attribute12  ,
                attribute13 ,
                attribute14 ,
                attribute15 ,
                assembly_type  ,
                common_bill_sequence_id ,
                bill_sequence_id ,
                request_id ,
                program_application_id  ,
                program_id  ,
                program_update_date ,
                demand_source_line  ,
                set_id ,
                common_organization_id ,
                demand_source_type ,
                demand_source_header_id ,
                transaction_id ,
                process_flag ,
                organization_code,
                common_org_code ,
                item_number,
                common_item_number,
                next_explode_date,
                revision,
                transaction_type ,
                delete_group_name ,
                dg_description ,
                original_system_reference,
                implementation_date,
                obj_name,
                pk1_value ,
                pk2_value  ,
                pk3_value  ,
                pk4_value  ,
                pk5_value ,
                structure_type_name ,
                structure_type_id,
                effectivity_control ,
                return_status ,
                is_preferred ,
                source_system_reference ,
                source_system_reference_desc ,
                batch_id ,
                change_id  ,
                catalog_category_name ,
                item_catalog_group_id ,
                primary_unit_of_measure ,
                item_description,
                template_name  ,
                source_bill_sequence_id ,
                enable_attrs_update ,
                interface_table_unique_id  ,
                bundle_id  ,
                source_system_name,
                organization_code_orig,
                process_code,
                error_code ,
                error_mesg
           FROM xx_bom_bill_of_mtls_stg bis
           WHERE batch_id     = G_BATCH_ID
		         AND request_id   = xx_emf_pkg.G_REQUEST_ID
		         AND process_code = cp_process_status
		         AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
		        ORDER BY record_number;

      --cursor to insert into bom components interface table
      CURSOR c_xx_bom_comp_intupld (cp_process_status VARCHAR2) IS
               SELECT acd_type,
                      alternate_bom_designator,
                      assembly_item_id,
                      assembly_item_number,
                      assembly_type,
                      attribute_category,
                      attribute1,
                      attribute10,
                      attribute11,
                      attribute12,
                      attribute13,
                      attribute14,
                      attribute15,
                      attribute2,
                      attribute3,
                      attribute4,
                      attribute5,
                      attribute6,
                      attribute7,
                      attribute8,
                      attribute9,
                      auto_request_material,
                      basis_type,
                      batch_id,
                      bill_sequence_id,
                      bom_inventory_comps_ifce_key,
                      bom_item_type,
                      bundle_id,
                      catalog_category_name,
                      change_id,
                      change_notice,
                      change_transaction_type,
                      check_atp,
                      common_component_sequence_id,
                      comp_source_system_refer_desc,
                      comp_source_system_reference,
                      component_item_id	,
                      component_item_number,
                      component_quantity,
                      component_remarks,
                      component_revision_code,
                      component_revision_id,
                      component_sequence_id,
                      component_yield_factor,
                      cost_factor,
                      created_by,
                      creation_date,
                      ddf_context1,
                      ddf_context2,
                      delete_group_name,
                      dg_description,
                      disable_date	,
                      effectivity_date,
                      enforce_int_requirements,
                      eng_changes_ifce_key,
                      eng_revised_items_ifce_key,
                      from_end_item	,
                      from_end_item_id,
                      from_end_item_minor_rev_code,
                      from_end_item_minor_rev_id,
                      from_end_item_rev_code,
                      from_end_item_rev_id,
                      from_end_item_unit_number,
                      from_minor_revision_code,
                      from_minor_revision_id,
                      from_object_revision_code,
                      from_object_revision_id,
                      high_quantity,
                      implementation_date	,
                      include_in_cost_rollup,
                      include_on_bill_docs,
                      include_on_ship_docs,
                      interface_entity_type,
                      interface_table_unique_id	,
                      inverse_quantity,
                      item_catalog_group_id	,
                      item_description,
                      item_num,
                      last_update_date,
                      last_update_login,
                      last_updated_by	,
                      location_name,
                      low_quantity,
                      model_comp_seq_id,
                      mutually_exclusive_options,
                      new_effectivity_date,
                      new_from_end_item_unit_number,
                      new_operation_seq_num	,
                      new_revised_item_revision	,
                      obj_name,
                      old_component_sequence_id	,
                      old_effectivity_date,
                      old_operation_seq_num	,
                      operation_lead_time_percent,
                      operation_seq_num,
                      optional,
                      optional_on_model,
                      organization_code,
                      organization_id	,
                      original_system_reference,
                      parent_bill_seq_id,
                      parent_revision_code,
                      parent_revision_id,
                      parent_source_system_reference,
                      pick_components,
                      pk1_value,
                      pk2_value,
                      pk3_value,
                      pk4_value	,
                      pk5_value,
                      plan_level,
                      planning_factor,
                      primary_unit_of_measure,
                      process_flag,
                      program_application_id,
                      program_id,
                      program_update_date,
                      quantity_related,
                      reference_designator,
                      request_id,
                      required_for_revenue,
                      required_to_ship,
                      return_status,
                      revised_item_number,
                      revised_item_sequence_id,
                      shipping_allowed,
                      so_basis,
                      substitute_comp_id,
                      substitute_comp_number,
                      suggested_vendor_name,
                      supply_locator_id,
                      supply_subinventory,
                      template_name,
                      to_end_item_minor_rev_code,
                      to_end_item_minor_rev_id,
                      to_end_item_rev_code,
                      to_end_item_rev_id,
                      to_end_item_unit_number,
                      to_minor_revision_code,
                      to_minor_revision_id,
                      to_object_revision_code,
                      to_object_revision_id,
                      transaction_id,
                      transaction_type,
                      unit_price,
                      wip_supply_type,
                      record_number,
                      --rec_number,
                      source_system_name,
                      organization_code_orig,
                      primary_unit_of_measure_orig,
                      include_in_cost_rollup_orig,
                      component_yield_factor_orig,
                      process_code,
                      error_code,
                      error_mesg
           FROM xx_bom_inv_component_stg bss
           WHERE batch_id     = G_COMP_BATCH_ID -- changed on 18 sep 2012 G_BATCH_ID
		         AND request_id   = xx_emf_pkg.G_REQUEST_ID
		         AND process_code = cp_process_status
		         AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
		        ORDER BY record_number;

   BEGIN
      g_api_name := 'main.bom_insert_interface';

      x_head_del_grp  := NULL;
      x_head_del_desc := NULL;
      x_comp_del_grp  := NULL;
      x_comp_del_desc := NULL;
      g_comp_del_grp  := NULL;
      g_head_del_grp  := NULL;


      IF p_bom_trans_type = g_trans_type_delete THEN
         dbg_low('Transaction type is :'||p_bom_trans_type);
         header_delete_grp(x_head_del_grp,x_head_del_desc);
         g_head_del_grp := x_head_del_grp;
         dbg_low('BOM Header delete group is: '||g_head_del_grp||' ,delete group desc is: '||x_head_del_desc);
         comp_delete_grp(x_comp_del_grp,x_comp_del_desc);
         g_comp_del_grp := x_comp_del_grp;
         dbg_low('BOM Component delete group is: '||g_comp_del_grp||' ,delete group desc is: '||x_comp_del_desc);
      END IF;

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


      FOR c_xx_bomh_intupld_rec IN c_xx_bomh_intupld(xx_emf_cn_pkg.CN_POSTVAL)
      LOOP
          x_cmmit_header := x_cmmit_header + 1;
         BEGIN
            INSERT INTO bom_bill_of_mtls_interface
               (--record_number,
                assembly_item_id,
                organization_id,
                alternate_bom_designator,
                last_update_date,
                last_updated_by,
                creation_date ,
                created_by,
                last_update_login,
                common_assembly_item_id,
                specific_assembly_comment ,
                pending_from_ecn,
                attribute_category,
                attribute1,
                attribute2 ,
                attribute3 ,
                attribute4 ,
                attribute5 ,
                attribute6 ,
                attribute7 ,
                attribute8 ,
                attribute9 ,
                attribute10 ,
                attribute11 ,
                attribute12 ,
                attribute13,
                attribute14 ,
                attribute15 ,
                assembly_type,
                common_bill_sequence_id,
                bill_sequence_id ,
               -- request_id,
                program_application_id,
                program_id,
                program_update_date,
                demand_source_line ,
                set_id ,
                common_organization_id,
                demand_source_type,
                demand_source_header_id ,
                transaction_id,
                process_flag ,
                organization_code ,
                common_org_code ,
                item_number ,
                common_item_number ,
                next_explode_date ,
                revision ,
                transaction_type ,
                delete_group_name ,
                dg_description,
                original_system_reference,
                implementation_date ,
                obj_name,
                pk1_value ,
                pk2_value ,
                pk3_value ,
                pk4_value,
                pk5_value,
                structure_type_name ,
                structure_type_id,
                effectivity_control,
                return_status ,
                is_preferred,
                source_system_reference,
                source_system_reference_desc,
               -- batch_id,
                change_id ,
                catalog_category_name,
                item_catalog_group_id ,
                primary_unit_of_measure,
                item_description,
                template_name,
                source_bill_sequence_id,
                enable_attrs_update,
                interface_table_unique_id ,
                bundle_id
              --  process_code,
              --  error_code ,
              --  error_mesg
                )
            VALUES
               (--c_xx_bomh_intupld_rec.record_number                ,
                c_xx_bomh_intupld_rec.assembly_item_id             ,
                c_xx_bomh_intupld_rec.organization_id              ,
                c_xx_bomh_intupld_rec.alternate_bom_designator     ,
                SYSDATE,                                      -- c_xx_bomh_intupld_rec.last_update_date             ,
                g_user_id,                                    -- c_xx_bomh_intupld_rec.last_updated_by              ,
                SYSDATE,                                      -- c_xx_bomh_intupld_rec.creation_date                ,
                g_user_id,                                    -- c_xx_bomh_intupld_rec.created_by                   ,
                g_user_id,                                    -- g_user_idc_xx_bomh_intupld_rec.last_update_login   ,
                c_xx_bomh_intupld_rec.common_assembly_item_id      ,
                c_xx_bomh_intupld_rec.specific_assembly_comment    ,
                c_xx_bomh_intupld_rec.pending_from_ecn             ,
                c_xx_bomh_intupld_rec.attribute_category           ,
                c_xx_bomh_intupld_rec.attribute1                   ,
                c_xx_bomh_intupld_rec.attribute2                   ,
                c_xx_bomh_intupld_rec.attribute3                   ,
                c_xx_bomh_intupld_rec.attribute4                   ,
                c_xx_bomh_intupld_rec.attribute5                   ,
                c_xx_bomh_intupld_rec.attribute6                   ,
                c_xx_bomh_intupld_rec.attribute7                   ,
                c_xx_bomh_intupld_rec.attribute8                   ,
                c_xx_bomh_intupld_rec.attribute9                   ,
                c_xx_bomh_intupld_rec.attribute10                  ,
                c_xx_bomh_intupld_rec.attribute11 ,
                c_xx_bomh_intupld_rec.attribute12                  ,
                c_xx_bomh_intupld_rec.attribute13                  ,
                c_xx_bomh_intupld_rec.attribute14                  ,
                c_xx_bomh_intupld_rec.attribute15                  ,
                c_xx_bomh_intupld_rec.assembly_type                ,
                c_xx_bomh_intupld_rec.common_bill_sequence_id      ,
                c_xx_bomh_intupld_rec.bill_sequence_id             ,
               -- c_xx_bomh_intupld_rec.request_id                   ,
                c_xx_bomh_intupld_rec.program_application_id       ,
                c_xx_bomh_intupld_rec.program_id                   ,
                c_xx_bomh_intupld_rec.program_update_date          ,
                c_xx_bomh_intupld_rec.demand_source_line           ,
                c_xx_bomh_intupld_rec.set_id                       ,
                c_xx_bomh_intupld_rec.common_organization_id       ,
                c_xx_bomh_intupld_rec.demand_source_type           ,
                c_xx_bomh_intupld_rec.demand_source_header_id      ,
                c_xx_bomh_intupld_rec.transaction_id               ,
                g_process_flag,                                  -- c_xx_bomh_intupld_rec.process_flag ,
                c_xx_bomh_intupld_rec.organization_code_orig,     -- c_xx_bomh_intupld_rec.organization_code ,
                c_xx_bomh_intupld_rec.common_org_code              ,
                c_xx_bomh_intupld_rec.item_number                  ,
                c_xx_bomh_intupld_rec.common_item_number           ,
                c_xx_bomh_intupld_rec.next_explode_date            ,
                c_xx_bomh_intupld_rec.revision                     ,
                p_bom_trans_type,                               --c_xx_bomh_intupld_rec.transaction_type ,
                x_head_del_grp ,                                --c_xx_bomh_intupld_rec.delete_group_name  ,
                x_head_del_desc,                                --c_xx_bomh_intupld_rec.dg_description    ,
                c_xx_bomh_intupld_rec.original_system_reference    ,
                c_xx_bomh_intupld_rec.implementation_date          ,
                c_xx_bomh_intupld_rec.obj_name                     ,
                c_xx_bomh_intupld_rec.pk1_value                    ,
                c_xx_bomh_intupld_rec.pk2_value                    ,
                c_xx_bomh_intupld_rec.pk3_value                    ,
                c_xx_bomh_intupld_rec.pk4_value                    ,
                c_xx_bomh_intupld_rec.pk5_value                    ,
                c_xx_bomh_intupld_rec.structure_type_name          ,
                c_xx_bomh_intupld_rec.structure_type_id            ,
                c_xx_bomh_intupld_rec.effectivity_control          ,
                c_xx_bomh_intupld_rec.return_status                ,
                c_xx_bomh_intupld_rec.is_preferred                 ,
                c_xx_bomh_intupld_rec.source_system_reference      ,
                c_xx_bomh_intupld_rec.source_system_reference_desc ,
               -- c_xx_bomh_intupld_rec.batch_id                     ,
                c_xx_bomh_intupld_rec.change_id                    ,
                c_xx_bomh_intupld_rec.catalog_category_name        ,
                c_xx_bomh_intupld_rec.item_catalog_group_id        ,
                c_xx_bomh_intupld_rec.primary_unit_of_measure      ,
                c_xx_bomh_intupld_rec.item_description             ,
                c_xx_bomh_intupld_rec.template_name                ,
                c_xx_bomh_intupld_rec.source_bill_sequence_id      ,
                c_xx_bomh_intupld_rec.enable_attrs_update          ,
                c_xx_bomh_intupld_rec.interface_table_unique_id    ,
                c_xx_bomh_intupld_rec.bundle_id
               -- c_xx_bomh_intupld_rec.process_code                 ,
               -- c_xx_bomh_intupld_rec.error_code                   ,
               -- c_xx_bomh_intupld_rec.error_mesg                   ,
               );
          END;
          IF x_cmmit_header >= x_commit_sequence THEN -- Commit for every 10000 record as per review comment
                 commit;
          END IF;
      END LOOP;
      ------

      FOR c_xx_bom_comp_intupld_rec IN c_xx_bom_comp_intupld(xx_emf_cn_pkg.CN_POSTVAL)
      LOOP
         x_cmmit_comp := x_cmmit_comp + 1;
         BEGIN
            INSERT INTO bom_inventory_comps_interface
               (acd_type,
                alternate_bom_designator,
                assembly_item_id,
                assembly_item_number,
                assembly_type,
                attribute_category,
                attribute1,
                attribute10,
                attribute11,
                attribute12,
                attribute13,
                attribute14,
                attribute15,
                attribute2,
                attribute3,
                attribute4,
                attribute5,
                attribute6,
                attribute7,
                attribute8,
                attribute9,
                auto_request_material,
                basis_type,
               -- batch_id,
                bill_sequence_id,
                bom_inventory_comps_ifce_key,
                bom_item_type,
                bundle_id,
                catalog_category_name,
                change_id,
                --change_notice,		-- According new FS this should not be used
                change_transaction_type,
                check_atp,
                common_component_sequence_id,
                comp_source_system_refer_desc,
                comp_source_system_reference,
                component_item_id	,
                component_item_number,
                component_quantity,
                component_remarks,
                component_revision_code,
                component_revision_id,
                component_sequence_id,
                component_yield_factor,
                cost_factor,
                created_by,
                creation_date,
                ddf_context1,
                ddf_context2,
                delete_group_name,
                dg_description,
                disable_date	,
                effectivity_date,
                enforce_int_requirements,
                eng_changes_ifce_key,
                eng_revised_items_ifce_key,
                from_end_item	,
                from_end_item_id,
                from_end_item_minor_rev_code,
                from_end_item_minor_rev_id,
                from_end_item_rev_code,
                from_end_item_rev_id,
                from_end_item_unit_number,
                from_minor_revision_code,
                from_minor_revision_id,
                from_object_revision_code,
                from_object_revision_id,
                high_quantity,
                implementation_date	,
                include_in_cost_rollup,
                include_on_bill_docs,
                include_on_ship_docs,
                interface_entity_type,
                interface_table_unique_id	,
                inverse_quantity,
                item_catalog_group_id	,
                item_description,
                item_num,
                last_update_date,
                last_update_login,
                last_updated_by	,
                location_name,
                low_quantity,
                model_comp_seq_id,
                mutually_exclusive_options,
                new_effectivity_date,
                new_from_end_item_unit_number,
                new_operation_seq_num	,
                new_revised_item_revision	,
                obj_name,
                old_component_sequence_id	,
                old_effectivity_date,
                old_operation_seq_num	,
                operation_lead_time_percent,
                operation_seq_num,
                optional,
                optional_on_model,
                organization_code,
                organization_id	,
                original_system_reference,
                parent_bill_seq_id,
                parent_revision_code,
                parent_revision_id,
                parent_source_system_reference,
                pick_components,
                pk1_value,
                pk2_value,
                pk3_value,
                pk4_value	,
                pk5_value,
                plan_level,
                planning_factor,
                primary_unit_of_measure,
                process_flag,
                program_application_id,
                program_id,
                program_update_date,
                quantity_related,
                reference_designator,
                --request_id,
                required_for_revenue,
                required_to_ship,
                return_status,
                revised_item_number,
                revised_item_sequence_id,
                shipping_allowed,
                so_basis,
                substitute_comp_id,
                substitute_comp_number,
                suggested_vendor_name,
                supply_locator_id,
                supply_subinventory,
                template_name,
                to_end_item_minor_rev_code,
                to_end_item_minor_rev_id,
                to_end_item_rev_code,
                to_end_item_rev_id,
                to_end_item_unit_number,
                to_minor_revision_code,
                to_minor_revision_id,
                to_object_revision_code,
                to_object_revision_id,
                transaction_id,
                transaction_type,
                unit_price,
                wip_supply_type
                 )
            VALUES
               (
                c_xx_bom_comp_intupld_rec.acd_type,
                c_xx_bom_comp_intupld_rec.alternate_bom_designator,
                c_xx_bom_comp_intupld_rec.assembly_item_id,
                c_xx_bom_comp_intupld_rec.assembly_item_number,
                c_xx_bom_comp_intupld_rec.assembly_type,
                c_xx_bom_comp_intupld_rec.attribute_category,
                c_xx_bom_comp_intupld_rec.attribute1,
                c_xx_bom_comp_intupld_rec.attribute10,
                c_xx_bom_comp_intupld_rec.attribute11,
                c_xx_bom_comp_intupld_rec.attribute12,
                c_xx_bom_comp_intupld_rec.attribute13,
                c_xx_bom_comp_intupld_rec.attribute14,
                c_xx_bom_comp_intupld_rec.attribute15,
                c_xx_bom_comp_intupld_rec.attribute2,
                c_xx_bom_comp_intupld_rec.attribute3,
                c_xx_bom_comp_intupld_rec.attribute4,
                c_xx_bom_comp_intupld_rec.attribute5,
                c_xx_bom_comp_intupld_rec.attribute6,
                c_xx_bom_comp_intupld_rec.attribute7,
                c_xx_bom_comp_intupld_rec.attribute8,
                c_xx_bom_comp_intupld_rec.attribute9,
                c_xx_bom_comp_intupld_rec.auto_request_material,
                c_xx_bom_comp_intupld_rec.basis_type,
               -- c_xx_bom_comp_intupld_rec.batch_id,
                c_xx_bom_comp_intupld_rec.bill_sequence_id,
                c_xx_bom_comp_intupld_rec.bom_inventory_comps_ifce_key,
                c_xx_bom_comp_intupld_rec.bom_item_type,
                c_xx_bom_comp_intupld_rec.bundle_id,
                c_xx_bom_comp_intupld_rec.catalog_category_name,
                c_xx_bom_comp_intupld_rec.change_id,
                --c_xx_bom_comp_intupld_rec.change_notice,  -- According new FS this should not be used
                c_xx_bom_comp_intupld_rec.change_transaction_type,
                c_xx_bom_comp_intupld_rec.check_atp,
                c_xx_bom_comp_intupld_rec.common_component_sequence_id,
                c_xx_bom_comp_intupld_rec.comp_source_system_refer_desc,
                c_xx_bom_comp_intupld_rec.comp_source_system_reference,
                c_xx_bom_comp_intupld_rec.component_item_id,
                c_xx_bom_comp_intupld_rec.component_item_number,
                c_xx_bom_comp_intupld_rec.component_quantity,
                c_xx_bom_comp_intupld_rec.component_remarks,
                c_xx_bom_comp_intupld_rec.component_revision_code,
                c_xx_bom_comp_intupld_rec.component_revision_id,
                c_xx_bom_comp_intupld_rec.component_sequence_id,
                c_xx_bom_comp_intupld_rec.component_yield_factor, --c_xx_bom_comp_intupld_rec.component_yield_factor_orig, -- change for WAVE1 on 22-jul-2013
                c_xx_bom_comp_intupld_rec.cost_factor,
                g_user_id,               -- c_xx_bom_comp_intupld_rec.created_by,
                SYSDATE,                 -- c_xx_bom_comp_intupld_rec.creation_date,
                c_xx_bom_comp_intupld_rec.ddf_context1,
                c_xx_bom_comp_intupld_rec.ddf_context2,
                x_comp_del_grp,          -- c_xx_bom_comp_intupld_rec.delete_group_name,
                x_comp_del_desc,         -- c_xx_bom_comp_intupld_rec.dg_description,
                c_xx_bom_comp_intupld_rec.disable_date,
                c_xx_bom_comp_intupld_rec.effectivity_date,
                c_xx_bom_comp_intupld_rec.enforce_int_requirements,
                c_xx_bom_comp_intupld_rec.eng_changes_ifce_key,
                c_xx_bom_comp_intupld_rec.eng_revised_items_ifce_key,
                c_xx_bom_comp_intupld_rec.from_end_item,
                c_xx_bom_comp_intupld_rec.from_end_item_id,
                c_xx_bom_comp_intupld_rec.from_end_item_minor_rev_code,
                c_xx_bom_comp_intupld_rec.from_end_item_minor_rev_id,
                c_xx_bom_comp_intupld_rec.from_end_item_rev_code,
                c_xx_bom_comp_intupld_rec.from_end_item_rev_id,
                c_xx_bom_comp_intupld_rec.from_end_item_unit_number,
                c_xx_bom_comp_intupld_rec.from_minor_revision_code,
                c_xx_bom_comp_intupld_rec.from_minor_revision_id,
                c_xx_bom_comp_intupld_rec.from_object_revision_code,
                c_xx_bom_comp_intupld_rec.from_object_revision_id,
                c_xx_bom_comp_intupld_rec.high_quantity,
                c_xx_bom_comp_intupld_rec.implementation_date,
                c_xx_bom_comp_intupld_rec.include_in_cost_rollup_orig, -- c_xx_bom_comp_intupld_rec.include_in_cost_rollup,
                c_xx_bom_comp_intupld_rec.include_on_bill_docs,
                c_xx_bom_comp_intupld_rec.include_on_ship_docs,
                c_xx_bom_comp_intupld_rec.interface_entity_type,
                c_xx_bom_comp_intupld_rec.interface_table_unique_id,
                c_xx_bom_comp_intupld_rec.inverse_quantity,
                c_xx_bom_comp_intupld_rec.item_catalog_group_id,
                c_xx_bom_comp_intupld_rec.item_description,
                c_xx_bom_comp_intupld_rec.item_num,
                SYSDATE,                       --c_xx_bom_comp_intupld_rec.last_update_date,
                g_user_id,                     --c_xx_bom_comp_intupld_rec.last_update_login,
                g_user_id,                     --c_xx_bom_comp_intupld_rec.last_updated_by,
                c_xx_bom_comp_intupld_rec.location_name,
                c_xx_bom_comp_intupld_rec.low_quantity,
                c_xx_bom_comp_intupld_rec.model_comp_seq_id,
                c_xx_bom_comp_intupld_rec.mutually_exclusive_options,
                c_xx_bom_comp_intupld_rec.new_effectivity_date,
                c_xx_bom_comp_intupld_rec.new_from_end_item_unit_number,
                c_xx_bom_comp_intupld_rec.new_operation_seq_num,
                c_xx_bom_comp_intupld_rec.new_revised_item_revision,
                c_xx_bom_comp_intupld_rec.obj_name,
                c_xx_bom_comp_intupld_rec.old_component_sequence_id,
                c_xx_bom_comp_intupld_rec.old_effectivity_date,
                c_xx_bom_comp_intupld_rec.old_operation_seq_num,
                c_xx_bom_comp_intupld_rec.operation_lead_time_percent,
                c_xx_bom_comp_intupld_rec.operation_seq_num,
                c_xx_bom_comp_intupld_rec.optional,
                c_xx_bom_comp_intupld_rec.optional_on_model,
                c_xx_bom_comp_intupld_rec.organization_code_orig,  --c_xx_bom_comp_intupld_rec.organization_code,
                c_xx_bom_comp_intupld_rec.organization_id,
                c_xx_bom_comp_intupld_rec.original_system_reference,
                c_xx_bom_comp_intupld_rec.parent_bill_seq_id,
                c_xx_bom_comp_intupld_rec.parent_revision_code,
                c_xx_bom_comp_intupld_rec.parent_revision_id,
                c_xx_bom_comp_intupld_rec.parent_source_system_reference,
                c_xx_bom_comp_intupld_rec.pick_components,
                c_xx_bom_comp_intupld_rec.pk1_value,
                c_xx_bom_comp_intupld_rec.pk2_value,
                c_xx_bom_comp_intupld_rec.pk3_value,
                c_xx_bom_comp_intupld_rec.pk4_value,
                c_xx_bom_comp_intupld_rec.pk5_value,
                c_xx_bom_comp_intupld_rec.plan_level,
                c_xx_bom_comp_intupld_rec.planning_factor,
                c_xx_bom_comp_intupld_rec.primary_unit_of_measure_orig,  ---  c_xx_bom_comp_intupld_rec.primary_unit_of_measure,
                g_process_flag,                                          ---  c_xx_bom_comp_intupld_rec.process_flag,
                c_xx_bom_comp_intupld_rec.program_application_id,
                c_xx_bom_comp_intupld_rec.program_id,
                c_xx_bom_comp_intupld_rec.program_update_date,
                c_xx_bom_comp_intupld_rec.quantity_related,
                c_xx_bom_comp_intupld_rec.reference_designator,
               -- c_xx_bom_comp_intupld_rec.request_id,
                c_xx_bom_comp_intupld_rec.required_for_revenue,
                c_xx_bom_comp_intupld_rec.required_to_ship,
                c_xx_bom_comp_intupld_rec.return_status,
                c_xx_bom_comp_intupld_rec.revised_item_number,
                c_xx_bom_comp_intupld_rec.revised_item_sequence_id,
                c_xx_bom_comp_intupld_rec.shipping_allowed,
                c_xx_bom_comp_intupld_rec.so_basis,
                c_xx_bom_comp_intupld_rec.substitute_comp_id,
                c_xx_bom_comp_intupld_rec.substitute_comp_number,
                c_xx_bom_comp_intupld_rec.suggested_vendor_name,
                c_xx_bom_comp_intupld_rec.supply_locator_id,
                c_xx_bom_comp_intupld_rec.supply_subinventory,
                c_xx_bom_comp_intupld_rec.template_name,
                c_xx_bom_comp_intupld_rec.to_end_item_minor_rev_code,
                c_xx_bom_comp_intupld_rec.to_end_item_minor_rev_id,
                c_xx_bom_comp_intupld_rec.to_end_item_rev_code,
                c_xx_bom_comp_intupld_rec.to_end_item_rev_id,
                c_xx_bom_comp_intupld_rec.to_end_item_unit_number,
                c_xx_bom_comp_intupld_rec.to_minor_revision_code,
                c_xx_bom_comp_intupld_rec.to_minor_revision_id,
                c_xx_bom_comp_intupld_rec.to_object_revision_code,
                c_xx_bom_comp_intupld_rec.to_object_revision_id,
                c_xx_bom_comp_intupld_rec.transaction_id,
                p_bom_trans_type,                  -- c_xx_bom_comp_intupld_rec.transaction_type,
                c_xx_bom_comp_intupld_rec.unit_price,
                c_xx_bom_comp_intupld_rec.wip_supply_type
                );
         END;
         IF x_cmmit_comp >= x_commit_sequence THEN -- Commit for every 10000 record as per review comment
                 commit;
          END IF;
      END LOOP;
      commit;
      RETURN x_return_status;
	       EXCEPTION
		       WHEN OTHERS THEN
			       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while inserting into Standard Interface Tables: ' ||SQLERRM);
			       xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
			       x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
			       RETURN x_error_code;

   END bom_insert_interface;

   PROCEDURE bom_delete
   IS
   /*-------------------------------------------------------------------------------------------------------------------------
        Procedure Name   :   bom_delete
        Parameters       :

        Purpose          :  Delete   Costing BOMs
     -------------------------------------------------------------------------------------------------------------------------*/

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
       -- BOM Header Cursor for deletion
      CURSOR c_xx_bom_header_del ( cp_process_status VARCHAR2)
       IS
       SELECT distinct organization_id
          FROM xx_bom_bill_of_mtls_stg
        WHERE batch_id     = G_BATCH_ID
          AND request_id   = xx_emf_pkg.G_REQUEST_ID
          AND process_code = cp_process_status
          AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         ORDER BY organization_id;

       CURSOR c_xx_bom_comp_del ( cp_process_status VARCHAR2)
       IS
       SELECT distinct organization_id
          FROM xx_bom_inv_component_stg
        WHERE batch_id     = G_BATCH_ID
          AND request_id   = xx_emf_pkg.G_REQUEST_ID
          AND process_code = cp_process_status
          AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         ORDER BY organization_id;

    BEGIN
      g_api_name := 'main.bom_delete';

      dbg_low('Inside deleting Bills of Material Procedure');


      dbg_low('Deletion of  Bills of Material Component');

      -- Deleting BOM Component
      FOR c_xx_bomcmp_del_rec IN c_xx_bom_comp_del(xx_emf_cn_pkg.CN_POSTVAL)
      LOOP
         x_del_cmpgrp_seq_id := NULL;
        BEGIN

          -- Find delete_group_sequence_id
          SELECT delete_group_sequence_id INTO x_del_cmpgrp_seq_id
            FROM BOM_DELETE_GROUPS bdg
             WHERE bdg.organization_id = c_xx_bomcmp_del_rec.organization_id
               AND delete_group_name = g_comp_del_grp;
           dbg_low('Submitting Deletion OF BOM for org_id: '||c_xx_bomcmp_del_rec.organization_id
                                 ||' delete_group_sequence_id : '||x_del_cmpgrp_seq_id
                                 ||' Component Delete group :'|| g_comp_del_grp);
          BEGIN
                 l_standard_request_id := fnd_request.submit_request
                             (application  => 'BOM'
                              ,program     => 'BMCDEL'
                              ,description => 'Deleting BOM Component'
                              ,argument1   => x_del_cmpgrp_seq_id --9007
                              ,argument2   => 2 -- all_org yes = 1
                              ,argument3   => 4
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
			            dbg_low('Deleting Bills of Material component Program Completed - for ORGANIZATION_ID :'||c_xx_bomcmp_del_rec.organization_id|| '=>'||l_dev_status);
		           END IF;

            ELSIF l_standard_request_id = 0 THEN
                 dbg_low('Error in submitting the Deleting Bills of Material component Program for ORGANIZATION_ID :'||c_xx_bomcmp_del_rec.organization_id);
            END IF;

          EXCEPTION
	    	     WHEN OTHERS THEN
		           dbg_low(SUBSTR(SQLERRM,1,255));
          END;

        END;
      END LOOP;



      -- Deleting BOM Header
      dbg_low('Deletion of  Bills of Material Header');

      FOR c_xx_bomh_del_rec IN c_xx_bom_header_del(xx_emf_cn_pkg.CN_POSTVAL)
      LOOP
        x_del_grp_seq_id := NULL;
        BEGIN

          dbg_low('Submitting Deletion OF BOM for org_id: '||c_xx_bomh_del_rec.organization_id);
          -- Find delete_group_sequence_id
          SELECT delete_group_sequence_id INTO x_del_grp_seq_id
            FROM BOM_DELETE_GROUPS bdg
             WHERE bdg.organization_id = c_xx_bomh_del_rec.organization_id
               AND delete_group_name = g_head_del_grp;
           dbg_low('Submitting Deletion OF BOM for org_id: '||c_xx_bomh_del_rec.organization_id
                                 ||' delete_group_sequence_id : '||x_del_grp_seq_id
                                 ||' Header Delete group :'|| g_head_del_grp);
          BEGIN
                 l_standard_request_id := fnd_request.submit_request
                             (application  => 'BOM'
                              ,program     => 'BMCDEL'
                              ,description => 'Deleting Bills of Material'
                              ,argument1   => x_del_grp_seq_id --9007
                              ,argument2   => 2 -- all_org yes = 1
                              ,argument3   => 2
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
			            dbg_low('Deleting Bills of Material Program Completed - Successfully for ORGANIZATION_ID :'||c_xx_bomh_del_rec.organization_id|| '=>'||l_dev_status);
		            END IF;
            ELSIF l_standard_request_id = 0 THEN
                 dbg_low('Error in submitting the Deleting Bills of Material Program for ORGANIZATION_ID :'||c_xx_bomh_del_rec.organization_id);
            END IF;

          EXCEPTION
	    	     WHEN OTHERS THEN
		           dbg_low(SUBSTR(SQLERRM,1,255));
          END;

        END;
      END LOOP;
         mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA);
		     -- Print the records with API Error
		     print_records_with_api_error;
		     x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
     EXCEPTION
         WHEN OTHERS THEN
		           dbg_low('Error Deleting Bills of Material Program'||SUBSTR(SQLERRM,1,255));
   END bom_delete;

  /*-------------------------------------------------------------------------------------------------------------------
   Procedure Name   :   bom_upload
   Purpose          :   This is the bom_upload procedure which performs the creation of BOM.
   --------------------------------------------------------------------------------------------------------------------*/

  PROCEDURE bom_upload
    IS
   /*-------------------------------------------------------------------------------------------------------------------------
        Procedure Name   :   bom_upload
        Parameters       :

        Purpose          :  Create BOMs
     -------------------------------------------------------------------------------------------------------------------------*/

      --Variable Declaration
      l_completed           BOOLEAN;
      l_phase               VARCHAR2(200);
      l_vstatus             VARCHAR2(200);
      l_dev_phase           VARCHAR2(200);
      l_dev_status          VARCHAR2(200);
      l_message             VARCHAR2(2000);
      l_standard_request_id NUMBER;
   BEGIN
     g_api_name := 'main.bom_upload';
         l_standard_request_id := fnd_request.submit_request(application => 'BOM'
                                                            ,program     => 'BMCOIN'
                                                            ,description => 'Import Bills of Material'
                                                            ,argument1   => fnd_global.org_id
                                                            ,argument2   => 1 -- all_org yes = 1
                                                            ,argument3   => 2 -- routing yes = 1
                                                            ,argument4   => 1 -- bom     yes = 1
                                                            ,argument5   => 2
                                                             -- delete from inter yes = 1
                                                            ,argument6 => NULL);
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
			           xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Import Bills of Material Program Completed =>'||l_dev_status);
			          mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA);
		            -- Print the records with API Error
                IF g_bom_transaction_type = g_trans_type_create THEN
		               print_records_with_api_error;
                END IF;
		            x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
		       END IF;
           ELSIF l_standard_request_id = 0 THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Error in submitting the Import Bills of Material Program');
         END IF;

   EXCEPTION
		WHEN OTHERS THEN
		    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND,SUBSTR(SQLERRM,1,255));
   END bom_upload;

   BEGIN
      --Main Begin
      ----------------------------------------------------------------------------------------------------
      --Initialize Trace
      --Purpose : Set the program environment for Tracing
      ----------------------------------------------------------------------------------------------------

      retcode := xx_emf_cn_pkg.CN_SUCCESS;

	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Setting Environment');
      g_bom_transaction_type := p_bom_transaction_type;
	    -- Hdr level --
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling BOM Hdr Set_cnv_env');
	    set_cnv_env (p_batch_id,xx_emf_cn_pkg.CN_YES,'BOM_HDR');
	    -- Line level --
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling BOM COMP Set_cnv_env');
	    set_cnv_env (p_comp_batch_id,xx_emf_cn_pkg.CN_YES,'BOM_COMP');

        -- include all the parameters to the conversion main here
        -- as medium log messages
	     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Starting main process with the following parameters');
	     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_batch_id '	|| p_batch_id);
	     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_comp_batch_id '	|| p_comp_batch_id);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_bom_transaction_type '	|| p_bom_transaction_type);
	     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_restart_flag '	|| p_restart_flag);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_validate_and_load '	|| p_validate_and_load);

	    -- Call procedure to update records with the current request_id
	     -- So that we can process only those records
	     -- This gives a better handling of restartability
	     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling mark_records_for_processing..');
	     mark_records_for_processing(p_restart_flag => p_restart_flag);

       -- Set the stage to Pre Validations
		   set_stage (xx_emf_cn_pkg.CN_PREVAL);

       -- PRE_VALIDATIONS SHOULD BE RETAINED
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling xx_po_cnv_validations_pkg.pre_validations ..');

		x_error_code := xx_bom_import_pkg.pre_validations;

		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After pre-validations X_ERROR_CODE ' || X_ERROR_CODE);

      -- Update process code of staging records
		  -- Update Header and Lines Level
		  update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS,'BOM_HDR');
		  update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS,'BOM_COMP');
		  xx_emf_pkg.propagate_error ( x_error_code);

      -- Set the stage to data Validations
	    set_stage (xx_emf_cn_pkg.CN_VALID);

      OPEN c_xx_bom_header ( xx_emf_cn_pkg.CN_PREVAL);
	     LOOP
	       	FETCH c_xx_bom_header
		    BULK COLLECT INTO x_bom_hdr_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

		   FOR i IN 1 .. x_bom_hdr_table.COUNT
		  LOOP
			  BEGIN
				-- Perform header level Base App Validations
				x_error_code := bom_header_validations(x_bom_hdr_table (i));
			        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_bom_hdr_table (i).record_number|| ' is ' || x_error_code);
			       	update_hdr_record_status (x_bom_hdr_table(i), x_error_code);
				-- mark_records_complete(xx_emf_cn_pkg.CN_VALID,'HDR');
				-- xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'After update_hdr_record_status ...');
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
                  update_header_int_records ( x_bom_hdr_table);
                  RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
           WHEN OTHERS
           THEN
                  xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_bom_hdr_table (i).record_number);
         END;

       END LOOP;

          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_bom_hdr_table.count ' || x_bom_hdr_table.COUNT );
          update_header_int_records( x_bom_hdr_table);
          x_bom_hdr_table.DELETE;

          EXIT WHEN c_xx_bom_header%NOTFOUND;
      END LOOP;


      IF c_xx_bom_header%ISOPEN THEN
          CLOSE c_xx_bom_header;
      END IF;

    -- Once data-validations are complete the loop through the pre-interface records
    -- and perform data derivations on this table
    -- Set the stage to data derivations
    set_stage (xx_emf_cn_pkg.CN_DERIVE);

    OPEN c_xx_bom_header ( xx_emf_cn_pkg.CN_VALID);
    LOOP
            FETCH c_xx_bom_header
            BULK COLLECT INTO x_bom_hdr_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

            FOR i IN 1 .. x_bom_hdr_table.COUNT
            LOOP

                    BEGIN

                            -- Perform header level Base App Validations
                            x_error_code := bom_hdr_data_derivations (x_bom_hdr_table (i));
                            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_bom_hdr_table (i).record_number|| ' is ' || x_error_code);

                            update_hdr_record_status (x_bom_hdr_table (i), x_error_code);
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
                                    update_header_int_records ( x_bom_hdr_table);
                                    RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                            WHEN OTHERS
                            THEN
                                    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_bom_hdr_table (i).record_number);
                    END;

            END LOOP;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_bom_hdr_table.count ' || x_bom_hdr_table.COUNT );

            update_header_int_records ( x_bom_hdr_table);

            x_bom_hdr_table.DELETE;

            EXIT WHEN c_xx_bom_header%NOTFOUND;
    END LOOP;

    IF c_xx_bom_header%ISOPEN THEN
            CLOSE c_xx_bom_header;
    END IF;

   -- Set the stage to Post Validations
   set_stage (xx_emf_cn_pkg.CN_POSTVAL);

		x_error_code := post_validations (p_bom_transaction_type,'BOM_HDR');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
		mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL,'BOM_HDR');
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);
    xx_emf_pkg.propagate_error ( x_error_code);



    -------- BOM Component  Level Validation ---------------------------------------------------------------------------

	-- Set the stage to data Validations
	set_stage (xx_emf_cn_pkg.CN_VALID);

	OPEN c_xx_bom_comp (xx_emf_cn_pkg.CN_PREVAL);
	LOOP
	       	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'In the Line level pre interface records loop');

	       	FETCH c_xx_bom_comp
		         BULK COLLECT INTO x_bom_comp_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

		FOR i IN 1 .. x_bom_comp_table.COUNT
		LOOP
			BEGIN
			       -- Perform Line level Base App Validations
			       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling Data Validations for Line Level');
			       x_error_code := bom_component_validations(x_bom_comp_table(i));
			       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_bom_comp_table(i).record_number|| ' is ' || x_error_code);
			       update_comp_record_status (x_bom_comp_table(i), x_error_code);
			      -- mark_records_complete(xx_emf_cn_pkg.CN_VALID,'LINE');
			       xx_emf_pkg.propagate_error (x_error_code);

			EXCEPTION
				-- If HIGH error then it will be propagated to the next level
				-- IF the process has to continue maintain it as a medium severity
				WHEN xx_emf_pkg.G_E_REC_ERROR
				THEN
					xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'BOM Comp Level '||xx_emf_cn_pkg.CN_REC_ERR);

				WHEN xx_emf_pkg.G_E_PRC_ERROR
				THEN
					xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'BOM Comp Level - Process Level Error in Data Validations');

					update_comp_int_records ( x_bom_comp_table);

					RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);

				WHEN OTHERS
				THEN
					xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_bom_comp_table (i).record_number);
			END;
		END LOOP;

		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_bom_comp_table.count ' || x_bom_comp_table.COUNT );

		update_comp_int_records ( x_bom_comp_table);

		x_bom_comp_table.DELETE;

		EXIT WHEN c_xx_bom_comp%NOTFOUND;
	END LOOP;

  IF c_xx_bom_comp%ISOPEN THEN
          CLOSE c_xx_bom_comp;
  END IF;

  -- Set the stage to data derivations
    set_stage (xx_emf_cn_pkg.CN_DERIVE);

    OPEN c_xx_bom_comp ( xx_emf_cn_pkg.CN_VALID);
    LOOP
            FETCH c_xx_bom_comp
            BULK COLLECT INTO x_bom_comp_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

            FOR i IN 1 .. x_bom_comp_table.COUNT
            LOOP

                    BEGIN

                            -- Perform header level Base App Validations
                            x_error_code :=bom_component_derivations (x_bom_comp_table (i));
                            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_bom_comp_table (i).record_number|| ' is ' || x_error_code);

                            update_comp_record_status (x_bom_comp_table (i), x_error_code);
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
                                    update_comp_int_records ( x_bom_comp_table);
                                    RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                            WHEN OTHERS
                            THEN
                                    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_bom_comp_table(i).record_number);
                    END;

            END LOOP;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_bom_hdr_table.count ' || x_bom_comp_table.COUNT );

            update_comp_int_records ( x_bom_comp_table);

            x_bom_comp_table.DELETE;

            EXIT WHEN c_xx_bom_comp%NOTFOUND;
    END LOOP;

    IF c_xx_bom_comp%ISOPEN THEN
            CLOSE c_xx_bom_comp;
    END IF;

   -- Set the stage to Post Validations
   set_stage (xx_emf_cn_pkg.CN_POSTVAL);

		x_error_code := post_validations (p_bom_transaction_type,'BOM_COMP');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
		mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL,'BOM_COMP');
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);
    xx_emf_pkg.propagate_error ( x_error_code);

     IF p_validate_and_load = g_validate_and_load THEN
     -- Set the stage to Process
    	   set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);
    	   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Before process_data');
    	   x_error_code := bom_insert_interface(p_bom_transaction_type);
         IF  p_bom_transaction_type = g_trans_type_create THEN
            bom_upload;
         ELSIF  p_bom_transaction_type = g_trans_type_delete THEN
            bom_upload;
            bom_delete;
         END IF;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After process_data');
         mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA,'BOM_HDR');
    	   mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA,'BOM_COMP');
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After Process Data mark_records_complete x_error_code'||x_error_code);
    	   xx_emf_pkg.propagate_error ( x_error_code);
	   END IF;
     print_staging_error_records;
     update_hdr_record_count(p_validate_and_load);
	   --update_lines_record_count;
	   xx_emf_pkg.create_report;
EXCEPTION
	WHEN xx_emf_pkg.G_E_ENV_NOT_SET THEN
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Checking if this is OK');
		fnd_file.put_line ( fnd_file.output, xx_emf_pkg.CN_ENV_NOT_SET);
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

END xx_bom_import_pkg;
/


GRANT EXECUTE ON APPS.XX_BOM_IMPORT_PKG TO INTG_XX_NONHR_RO;
