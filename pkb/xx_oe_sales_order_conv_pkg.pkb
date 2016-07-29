DROP PACKAGE BODY APPS.XX_OE_SALES_ORDER_CONV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OE_SALES_ORDER_CONV_PKG" 
	AS
	----------------------------------------------------------------------
	/*
	 Created By    : Samir Singha Mahapatra
	 Creation Date : 15-Mar-2012
	 File Name     : XXOESOHDRCNV.pkb
	 Description   : This script creates the specification of the package
			 xx_oe_sales_order_conv_pkg
	 Change History:
	 Date        Name                  Remarks
	 ----------- -------------         -----------------------------------
         15-Mar-2012 Samir                 Initial Version
         06-JUL-2012 Sharath Babu          Modified code to insert customer number into 
                                           header iface and set schedule_status_code to NULL
                                           at line iface
         26-OCT-2012 Sharath Babu          Modified code to fix duplicate delivery site creation
         30-OCT-2012 Sharath Babu          Modified code to fix issues as per TDR
         10-DEC-2012 Sharath Babu          Modified code to fix duplicate location creation
         21-JAN-2013 Sharath Babu          Added shipment_priority_code to iface table
         15-MAY-2013 Sharath Babu          Modified as per Wave1
         15-OCT-2013 Sharath Babu          Modified as per Wave1 UIT run
         11-DEC-2013 Sharath Babu          Modified to add REQUEST_DATE as per Wave1
         03-FEB-2014 Sharath Babu          Modified as per Wave1 to add ship_set_name
         28-FEB-2014 Sharath Babu          Modified to add return_reason_code
	*/
	----------------------------------------------------------------------
        -- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
        -- START RESTRICTIONS
	
	--------------------------------------------------------------------------------
        ------------------< set_cnv_env >-----------------------------------------------
        --------------------------------------------------------------------------------
	
	PROCEDURE set_cnv_env ( p_batch_id VARCHAR2, p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES,p_batch_flag VARCHAR2) IS
                x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
                fnd_file.put_line(fnd_file.log,'Inside set_cnv_env...');
                
	        if p_batch_flag = 'HDR' Then
                	G_BATCH_ID	  := p_batch_id;
                	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_BATCH_ID	    = ' || G_BATCH_ID );
                elsif p_batch_flag = 'LINE' Then
			G_LINE_BATCH_ID   := p_batch_id;
			xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_LINE_BATCH_ID  = ' || G_LINE_BATCH_ID );
		end if;


                -- Set the environment
                x_error_code := xx_emf_pkg.set_env;
                IF NVL (p_required_flag, xx_emf_cn_pkg.CN_YES) <> xx_emf_cn_pkg.CN_NO THEN
                        xx_emf_pkg.propagate_error(x_error_code);
                END IF;
        EXCEPTION
                WHEN OTHERS THEN
                        RAISE xx_emf_pkg.G_E_ENV_NOT_SET;
        END set_cnv_env;
   -------------------------------------------------------------------------
   -----------< assign_global_var >-------------------------------
   -------------------------------------------------------------------------
   PROCEDURE assign_global_var
   IS
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
      --Set Org Name
      OPEN cur_get_global_var_value('ORG_NAME');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_ORG_NAME := l_parameter_value;
      --Set Source Name
      OPEN cur_get_global_var_value('SOURCE_NAME');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_SOURCE_NAME := l_parameter_value;
      --Set Ship From Org
      OPEN cur_get_global_var_value('SHIP_FROM_ORG');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_SHIP_FROM_ORG := l_parameter_value;
      --Set Order Type
      OPEN cur_get_global_var_value('ORDER_TYPE');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_ORDER_TYPE := l_parameter_value;
      --Set RMA Order Type
      OPEN cur_get_global_var_value('RMA_ORDER_TYPE');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_RMA_ORDER_TYPE := l_parameter_value;
      --Set Hold Type H
      OPEN cur_get_global_var_value('HOLD_TYPE_H');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_HOLD_TYPE_H := l_parameter_value;
      --Set Hold Type ABC
      OPEN cur_get_global_var_value('HOLD_TYPE_ABC');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_HOLD_TYPE_ABC := l_parameter_value;
      --Set Shiponly Line
      OPEN cur_get_global_var_value('SHIPONLY_LINE');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_SHIPONLY_LINE := l_parameter_value;
      --Set Line Type
      OPEN cur_get_global_var_value('LINE_TYPE');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_LINE_TYPE := l_parameter_value;
      --Set RMA Line Type
      OPEN cur_get_global_var_value('RMA_LINE_TYPE');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_RMA_LINE_TYPE := l_parameter_value;
      --Set Price List
      OPEN cur_get_global_var_value('PRICE_LIST');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_PRICE_LIST := l_parameter_value;
      --Set tp context value  23-AUG-12 
      OPEN cur_get_global_var_value('TP_CONTEXT_VAL');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_TP_CONTEXT := l_parameter_value;
      
      IF G_ORG_NAME IS NULL OR  G_SOURCE_NAME IS NULL OR G_SHIP_FROM_ORG IS NULL OR
	       G_ORDER_TYPE IS NULL OR G_RMA_ORDER_TYPE IS NULL OR G_HOLD_TYPE_H IS NULL OR
	       G_HOLD_TYPE_ABC IS NULL OR G_SHIPONLY_LINE IS NULL OR G_LINE_TYPE IS NULL OR
	       G_RMA_LINE_TYPE IS NULL OR G_PRICE_LIST IS NULL OR G_TP_CONTEXT IS NULL
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
	--------------------------------------------------------------------------------
			--GET SOURCE ID	---
        PROCEDURE get_source_id IS
                x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN
	      SELECT order_source_id
		INTO G_SOURCE_ID
	        FROM oe_order_sources
	       WHERE upper(name) = upper('CONV')
		 AND enabled_flag = 'Y'; 

		fnd_file.put_line(fnd_file.log,'G_SOURCE_ID :: '||G_SOURCE_ID);

                x_error_code := xx_emf_cn_pkg.CN_SUCCESS; 
               
        EXCEPTION
                WHEN OTHERS THEN
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Getting Source Id : ' ||SQLERRM);
                    x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                    xx_emf_pkg.propagate_error(x_error_code);

        END get_source_id;
        
	--------------------------------------------------------------------------------
	PROCEDURE get_org_id( p_batch_id VARCHAR2) IS
                x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_organization_name	VARCHAR2(200);
		x_org_code		VARCHAR2(200);
        BEGIN
	        
                SELECT organization_id
		INTO G_ORG_ID
		FROM hr_operating_units
		WHERE UPPER (NAME) = UPPER (G_ORG_NAME);
		fnd_file.put_line(fnd_file.log,'G_ORG_ID :: '|| G_ORG_ID);

                x_error_code := xx_emf_cn_pkg.CN_SUCCESS; 
               
        EXCEPTION
                WHEN OTHERS THEN
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Getting Org Id : ' ||SQLERRM);
                    x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                    xx_emf_pkg.propagate_error(x_error_code);

        END get_org_id; 
	
	--------------------------------------------------------------------------------
        ------------------< mark_records_for_processing >-------------------------------
        --------------------------------------------------------------------------------		
	
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
                	        
                              
                                DELETE FROM XX_OE_ORDER_HEADERS_ALL_PRE
                                WHERE batch_id = G_BATCH_ID;
                                --
				DELETE FROM XX_OE_ORDER_LINES_ALL_PRE
                                WHERE batch_id = G_LINE_BATCH_ID;
                                --
				UPDATE XX_OE_ORDER_LINES_ALL_STG
				   SET batch_id = G_LINE_BATCH_ID
				 WHERE batch_id IS NULL;
				---
                                UPDATE XX_OE_ORDER_HEADERS_ALL_STG -- Order Header Staging
                                   SET request_id = xx_emf_pkg.G_REQUEST_ID,
                                       error_code = xx_emf_cn_pkg.CN_NULL,
                                       process_code = xx_emf_cn_pkg.CN_NEW
                                 WHERE batch_id = G_BATCH_ID;
                                 --
				 UPDATE XX_OE_ORDER_LINES_ALL_STG -- Order Lines Staging
                                   SET request_id = xx_emf_pkg.G_REQUEST_ID,
                                       error_code = xx_emf_cn_pkg.CN_NULL,
                                       process_code = xx_emf_cn_pkg.CN_NEW
                                 WHERE batch_id = G_LINE_BATCH_ID;
				 
                        ELSE

                                UPDATE XX_OE_ORDER_HEADERS_ALL_PRE
                                   SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                                       error_code = xx_emf_cn_pkg.CN_SUCCESS,
                                       request_id = xx_emf_pkg.G_REQUEST_ID
                                 WHERE batch_id = G_BATCH_ID;

				 UPDATE XX_OE_ORDER_LINES_ALL_PRE
                                   SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                                       error_code = xx_emf_cn_pkg.CN_SUCCESS,
                                       request_id = xx_emf_pkg.G_REQUEST_ID
                                 WHERE batch_id = G_LINE_BATCH_ID;


                        END IF;
			
                        DELETE FROM  OE_HEADERS_IFACE_ALL -- Order Headers Interface Table
                        WHERE TP_ATTRIBUTE15 = G_BATCH_ID;  --attribute1 = G_BATCH_ID; 25-JUL-12 Modified to use tp_attr15

			DELETE FROM  OE_LINES_IFACE_ALL -- Order LInes Interface Table
                        WHERE TP_ATTRIBUTE15 = G_LINE_BATCH_ID; --attribute1 = G_LINE_BATCH_ID; 25-JUL-12 Modified to use tp_attr15
                ELSIF p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS THEN

                        IF p_override_flag = xx_emf_cn_pkg.CN_NO THEN
     
				-- Update HDR staging table
                                UPDATE XX_OE_ORDER_HEADERS_ALL_STG
                                   SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                                       error_code   = xx_emf_cn_pkg.CN_NULL,
                                       process_code = xx_emf_cn_pkg.CN_NEW
                                 WHERE batch_id = G_BATCH_ID
                                   AND (process_code = xx_emf_cn_pkg.CN_NEW
                                          OR ( process_code = xx_emf_cn_pkg.CN_PREVAL
                                               AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
                                               xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                                              )
                                        );

				-- Update HDR staging table
                                UPDATE XX_OE_ORDER_LINES_ALL_STG
                                   SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                                       error_code   = xx_emf_cn_pkg.CN_NULL,
                                       process_code = xx_emf_cn_pkg.CN_NEW
                                 WHERE batch_id = G_LINE_BATCH_ID
                                   AND (   process_code = xx_emf_cn_pkg.CN_NEW
                                                OR (   process_code = xx_emf_cn_pkg.CN_PREVAL
                                                        AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
                                                        xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                                                    )
                                        );
                        END IF;
                       
			-- Update pre-interface table
                        -- Scenario 1 Pre-Validation Stage

                        UPDATE XX_OE_ORDER_HEADERS_ALL_STG
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_NULL,
                               process_code = xx_emf_cn_pkg.CN_NEW
                         WHERE batch_id = G_BATCH_ID
                           AND EXISTS (
                                SELECT 1
                                  FROM XX_OE_ORDER_HEADERS_ALL_PRE a 
                                 WHERE batch_id = G_BATCH_ID
                                   AND process_code = xx_emf_cn_pkg.CN_PREVAL
                                   AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                                   AND record_number = a.record_number);

                          UPDATE XX_OE_ORDER_LINES_ALL_STG
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_NULL,
                               process_code = xx_emf_cn_pkg.CN_NEW
                         WHERE batch_id = G_LINE_BATCH_ID
                           AND EXISTS (
                                SELECT 1
                                  FROM XX_OE_ORDER_LINES_ALL_PRE a 
                                 WHERE batch_id = G_LINE_BATCH_ID
                                   AND process_code = xx_emf_cn_pkg.CN_PREVAL
                                   AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                                   AND record_number = a.record_number);


                        DELETE
                          FROM XX_OE_ORDER_HEADERS_ALL_PRE
                         WHERE batch_id = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_PREVAL
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

		        DELETE
                          FROM XX_OE_ORDER_LINES_ALL_PRE
                         WHERE batch_id = G_LINE_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_PREVAL
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);
                        
			-- Scenario 2 Data Validation Stage

                        UPDATE XX_OE_ORDER_HEADERS_ALL_PRE	-- Hdr
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               process_code = xx_emf_cn_pkg.CN_PREVAL
                         WHERE batch_id = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_VALID
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

			 UPDATE XX_OE_ORDER_LINES_ALL_PRE		--Lines
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               process_code = xx_emf_cn_pkg.CN_PREVAL
                         WHERE batch_id = G_LINE_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_VALID
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                        
			-- Scenario 3 Data Derivation Stage

                        UPDATE XX_OE_ORDER_HEADERS_ALL_PRE
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,	--Header
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               process_code = xx_emf_cn_pkg.CN_DERIVE
                         WHERE batch_id = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_DERIVE
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

			 UPDATE XX_OE_ORDER_LINES_ALL_PRE		--Line
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               process_code = xx_emf_cn_pkg.CN_DERIVE
                         WHERE batch_id = G_LINE_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_DERIVE
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                        -- Scenario 4 Post Validation Stage

                        UPDATE XX_OE_ORDER_HEADERS_ALL_PRE		--Header
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               process_code = xx_emf_cn_pkg.CN_POSTVAL
                         WHERE batch_id = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_POSTVAL
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

			UPDATE XX_OE_ORDER_LINES_ALL_PRE		--Line
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               process_code = xx_emf_cn_pkg.CN_POSTVAL
                         WHERE batch_id = G_LINE_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_POSTVAL
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

                        -- Scenario 5 Process Data Stage

                        UPDATE XX_OE_ORDER_HEADERS_ALL_PRE		--Header		
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               process_code = xx_emf_cn_pkg.CN_POSTVAL
                         WHERE batch_id = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_ERR);

			   UPDATE XX_OE_ORDER_LINES_ALL_PRE		--Line	
                           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                               error_code = xx_emf_cn_pkg.CN_SUCCESS,
                               process_code = xx_emf_cn_pkg.CN_POSTVAL
                         WHERE batch_id = G_LINE_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                           AND error_code IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_ERR);
               END IF;
              COMMIT;

        END;
	
	
	 --------------------------------------------------------------------------------
         ------------------< set_stage >-------------------------------------------------
         --------------------------------------------------------------------------------
 
	
	PROCEDURE set_stage ( p_stage VARCHAR2)
        IS
        BEGIN
                G_STAGE := p_stage;
        END set_stage;

        PROCEDURE update_staging_records(p_level VARCHAR2, p_error_code VARCHAR2) IS

                x_last_update_date     DATE   := SYSDATE;
                x_last_updated_by      NUMBER := fnd_global.user_id;
                x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

                PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN
	      IF p_level = 'HDR' THEN
                UPDATE XX_OE_ORDER_HEADERS_ALL_STG		--Header
                   SET process_code = G_STAGE,
                       error_code = DECODE ( error_code, NULL, p_error_code, error_code),
                       last_update_date = x_last_update_date,
                       last_updated_by   = x_last_updated_by,
                       last_update_login = x_last_update_login -- In template please made change
                 WHERE batch_id		= G_BATCH_ID
                   AND request_id	= xx_emf_pkg.G_REQUEST_ID
                   AND process_code	= xx_emf_cn_pkg.CN_NEW;
	      END IF;

	      IF p_level = 'LINE' THEN
		   UPDATE XX_OE_ORDER_LINES_ALL_STG		--Line
                   SET process_code = G_STAGE,
                       error_code = DECODE ( error_code, NULL, p_error_code, error_code),
                       last_update_date = x_last_update_date,
                       last_updated_by   = x_last_updated_by,
                       last_update_login = x_last_update_login -- In template please made change
                 WHERE batch_id		= G_LINE_BATCH_ID
                   AND request_id	= xx_emf_pkg.G_REQUEST_ID
                   AND process_code	= xx_emf_cn_pkg.CN_NEW;

	       END IF;

                COMMIT;

        EXCEPTION
	    WHEN OTHERS THEN
	            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Updating STAGE status : ' ||SQLERRM);
                    --x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		    --xx_emf_pkg.propagate_error(x_error_code);
        END update_staging_records;
        -- END RESTRICTIONS
	
	
	--------------------------------------------------------------------------------
        ------------------< main >------------------------------------------------------
        --------------------------------------------------------------------------------
	PROCEDURE main (
                errbuf               OUT VARCHAR2,
                retcode              OUT VARCHAR2,
                p_batch_id           IN  VARCHAR2,
                p_restart_flag       IN  VARCHAR2,
                p_override_flag      IN  VARCHAR2,
		p_validate_and_load  IN VARCHAR2
        ) IS
		
		x_error_code VARCHAR2(1)   := xx_emf_cn_pkg.CN_SUCCESS;
                x_pre_std_hdr_table   G_XX_SO_CNV_PRE_STD_TAB_TYPE;
		x_pre_std_line_table  G_XX_SO_LINE_PRE_STD_TAB_TYPE;
		x_batch_flag	VARCHAR2(10);

		x_process_code    VARCHAR2(100);
                
		-- CURSOR FOR VARIOUS STAGES

		-- Header level

		CURSOR C_XX_OE_ORDER_HEADERS_ALL_PRE ( cp_process_status VARCHAR2) IS 
                SELECT *
                  FROM XX_OE_ORDER_HEADERS_ALL_PRE hdr
                 WHERE batch_id     = G_BATCH_ID
                   AND request_id   = xx_emf_pkg.G_REQUEST_ID
                   AND process_code = cp_process_status
                   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                 ORDER BY record_number;

                 -- Line level

		 CURSOR C_XX_OE_ORDER_LINES_ALL_PRE ( cp_process_status VARCHAR2) IS 
                SELECT   *		
                  FROM XX_OE_ORDER_LINES_ALL_PRE line
                 WHERE batch_id     = G_LINE_BATCH_ID
                   AND request_id   = xx_emf_pkg.G_REQUEST_ID
                   AND process_code = cp_process_status
                   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                 ORDER BY record_number;
                 
                
		PROCEDURE update_record_status (
                        p_conv_pre_std_hdr_rec  IN OUT  G_XX_SO_CNV_PRE_STD_REC_TYPE,
                        p_error_code            IN      VARCHAR2
                )
                IS
                BEGIN
                        IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
                        THEN
                                p_conv_pre_std_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                        ELSE
				p_conv_pre_std_hdr_rec.error_code := XX_INTG_COMMON_PKG.find_max(p_error_code, NVL (p_conv_pre_std_hdr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));
                             
                        END IF;
                        p_conv_pre_std_hdr_rec.process_code := G_STAGE;

                END update_record_status;


		PROCEDURE update_line_record_status (
                        p_conv_pre_std_line_rec  IN OUT  G_XX_SO_LINE_PRE_STD_REC_TYPE,
                        p_error_code            IN      VARCHAR2
                )
                IS
                BEGIN
                       IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
                        THEN
                                p_conv_pre_std_line_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                        ELSE
				p_conv_pre_std_line_rec.error_code := XX_INTG_COMMON_PKG.find_max(p_error_code, NVL (p_conv_pre_std_line_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));
                             
                        END IF;
                        p_conv_pre_std_line_rec.process_code := G_STAGE;	
			null;

                END update_line_record_status;



		---- Submitting Standard Order Import Program --------

                PROCEDURE submit_order_import_program
                IS
                        x_request_id        NUMBER ;
			x_phase             VARCHAR2 (100);
			x_status            VARCHAR2 (100);
			x_dev_phase         VARCHAR2 (100);
			x_dev_status        VARCHAR2 (100);
			x_message           VARCHAR2 (240);
			x_completed         BOOLEAN;
                        PRAGMA AUTONOMOUS_TRANSACTION;
                BEGIN
                        -- Submitting Standard Order Import Program
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside Submitting Standard Order Import Program');

		x_request_id := fnd_request.submit_request
                                   (application      => 'ONT',
                                    program          => 'OEOIMP',
                                    argument1        => G_ORG_ID,     -- Operating Unit
                                    argument2        => G_SOURCE_ID,  -- Order Source
                                    argument3        => NULL,         -- Original System Document Ref
                                    argument4        => NULL,         -- Operation Code
                                    argument5        => 'N',	      -- Validate_Only?
                                    argument6        => 1,	      -- Debug Level
                                    argument7        => 4,            -- Number of Order Import instances
                                    argument10       => NULL,         -- change sequence
                                    argument11       => 'Y',          -- Enable Single Line Queue for Instances
                                    argument12       => 'N',          -- Trim Trailing Blanks
                                    argument15       => 'Y' --,	-- Validate DFF
                                   -- start_time       => SYSDATE,
                                   -- sub_request      => FALSE
                                   );
		COMMIT;
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Request ID for Order Import  = ' ||x_request_id );

		IF (x_request_id <> 0) THEN
    
                           x_completed := fnd_concurrent.wait_for_request
                                             (request_id     => x_request_id,
						INTERVAL     => 0,
						phase        => x_phase,
						status       => x_status,
						dev_phase    => x_dev_phase,
						dev_status   => x_dev_status,
						MESSAGE      => x_message
                                            );

		  IF x_completed   THEN

			IF  (    x_dev_phase != xx_emf_cn_pkg.CN_COMPLETE 
			      OR x_dev_status != xx_emf_cn_pkg.CN_NORMAL) THEN

				xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM,'Order import completed - Failed'||x_request_id);
				--x_status := 'ERROR';
		        ELSE  
			        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Order import  Completed - Successfully' ||x_request_id);
				--x_status := 'SUCCESS';
			END IF; 
		  END IF;
		END IF;

	       EXCEPTION
		WHEN OTHERS THEN
                    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND,substr(SQLERRM,1,255));

                END submit_order_import_program;

		---

                PROCEDURE mark_records_complete
                (
                        p_process_code	VARCHAR2
		      , p_level		VARCHAR2
                )
                IS
                        x_last_update_date       DATE   := SYSDATE;
                        x_last_updated_by        NUMBER := fnd_global.user_id;
                        x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

                        PRAGMA AUTONOMOUS_TRANSACTION;
                BEGIN

			IF p_level = 'HDR' THEN
			
			xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, '  inside mark_records_complete :: Level : ' || p_level);
		   

				UPDATE XX_OE_ORDER_HEADERS_ALL_PRE	--Header
				   SET process_code      = G_STAGE,
				       error_code        = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
				       last_updated_by   = x_last_updated_by,
				       last_update_date  = x_last_update_date,
				       last_update_login = x_last_update_login
				 WHERE batch_id     = G_BATCH_ID
				   AND request_id   = xx_emf_pkg.G_REQUEST_ID
				   AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
				   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

				 /*  if sql%rowcount = 0 Then
					fnd_file.put_line(fnd_file.log,'Order Header Level => Update Stmt Fail !!...'||sqlerrm);
				   else
					fnd_file.put_line(fnd_file.log,'Order Header Level => Update Stmt Success...');
				    end if;*/

		        END IF;

		        IF p_level = 'LINE' THEN
			
			xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, '  inside mark_records_complete :: Level : ' || p_level);

			xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, '  G_STAGE ' || G_STAGE);
			xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, '  p_process_code ' || p_process_code);

				UPDATE XX_OE_ORDER_LINES_ALL_PRE	-- Line level
				   SET process_code      = G_STAGE,
				       error_code        = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
				       last_updated_by   = x_last_updated_by,
				       last_update_date  = x_last_update_date,
				       last_update_login = x_last_update_login
				 WHERE batch_id     = G_LINE_BATCH_ID
				   AND request_id   = xx_emf_pkg.G_REQUEST_ID
				  -- AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
				   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

				  /*   if sql%rowcount = 0 Then
					 fnd_file.put_line(fnd_file.log,'Order Line Level => Update Stmt Fail !!...'||sqlerrm);
				     else
					fnd_file.put_line(fnd_file.log,'Order Line Level => Update Stmt Success...');
				     end if;*/


			END IF;
                        COMMIT;

	        EXCEPTION WHEN OTHERS THEN
		    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'others ' || p_process_code);
                END mark_records_complete;

		--Header Level Update
                PROCEDURE update_pre_interface_records (p_cnv_pre_std_hdr_table IN G_XX_SO_CNV_PRE_STD_TAB_TYPE)
                IS
                        x_last_update_date     DATE   := SYSDATE;
                        x_last_updated_by      NUMBER := fnd_global.user_id;
                        x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

                        PRAGMA AUTONOMOUS_TRANSACTION;
                BEGIN
                        FOR indx IN 1 .. p_cnv_pre_std_hdr_table.COUNT LOOP
                                --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside Header level update_pre_interface_records ..' );

                               
				UPDATE  XX_OE_ORDER_HEADERS_ALL_PRE
				SET
			        ORG_ID                   	=	p_cnv_pre_std_hdr_table(indx).ORG_ID			,
				ORG_CODE			=	p_cnv_pre_std_hdr_table(indx).ORG_CODE			,
				ORDER_NUMBER                    =	p_cnv_pre_std_hdr_table(indx).ORDER_NUMBER		,
				ORDER_ID                        =	p_cnv_pre_std_hdr_table(indx).ORDER_ID		,
				ORDERED_DATE			=	p_cnv_pre_std_hdr_table(indx).ORDERED_DATE		,
				ORDER_TYPE_ID			=	p_cnv_pre_std_hdr_table(indx).ORDER_TYPE_ID		,
				ORDER_SOURCE_ID			=	p_cnv_pre_std_hdr_table(indx).ORDER_SOURCE_ID		,
				PRICE_LIST_ID			=	p_cnv_pre_std_hdr_table(indx).PRICE_LIST_ID		,
				TRANSACTIONAL_CURR_CODE		=	p_cnv_pre_std_hdr_table(indx).TRANSACTIONAL_CURR_CODE	,
				--TRANSACTIONAL_CURR		=	p_cnv_pre_std_hdr_table(indx).TRANSACTIONAL_CURR	,
				SALESREP_ID			=	p_cnv_pre_std_hdr_table(indx).SALESREP_ID		,
				TAX_EXEMPT_FLAG			=	p_cnv_pre_std_hdr_table(indx).TAX_EXEMPT_FLAG,
                                INVOICING_RULE_ID               =	p_cnv_pre_std_hdr_table(indx).INVOICING_RULE_ID,
                                ACCOUNTING_RULE_ID              =	p_cnv_pre_std_hdr_table(indx).ACCOUNTING_RULE_ID,
				PAYMENT_TERM_ID			=	p_cnv_pre_std_hdr_table(indx).PAYMENT_TERM_ID		,
				SHIPPING_METHOD_CODE		=	p_cnv_pre_std_hdr_table(indx).SHIPPING_METHOD_CODE	,
				--SHIPPING_METHOD		=	p_cnv_pre_std_hdr_table(indx).SHIPPING_METHOD		,
				FREIGHT_TERMS_CODE		=	p_cnv_pre_std_hdr_table(indx).FREIGHT_TERMS_CODE	,
				--FREIGHT_TERMS			=	p_cnv_pre_std_hdr_table(indx).FREIGHT_TERMS		,
				FOB_POINT_CODE			=	p_cnv_pre_std_hdr_table(indx).FOB_POINT_CODE		,
				CUSTOMER_PO_NUMBER		=	p_cnv_pre_std_hdr_table(indx).CUSTOMER_PO_NUMBER	,
				SOLD_TO_ORG_ID			=	p_cnv_pre_std_hdr_table(indx).SOLD_TO_ORG_ID		,
				SHIP_FROM_ORG_ID		=	p_cnv_pre_std_hdr_table(indx).SHIP_FROM_ORG_ID		,
				SHIP_TO_ORG_ID			=	p_cnv_pre_std_hdr_table(indx).SHIP_TO_ORG_ID		,
				INVOICE_TO_ORG_ID		=	p_cnv_pre_std_hdr_table(indx).INVOICE_TO_ORG_ID		,
				--CUSTOMER_NAME			=	p_cnv_pre_std_hdr_table(indx).CUSTOMER_NAME		,
				CUSTOMER_NUMBER			=	p_cnv_pre_std_hdr_table(indx).CUSTOMER_NUMBER		,
				SHIP_TO_ADDRESS1		=	p_cnv_pre_std_hdr_table(indx).SHIP_TO_ADDRESS1		,
				SHIP_TO_ADDRESS2		=	p_cnv_pre_std_hdr_table(indx).SHIP_TO_ADDRESS2		,
				SHIP_TO_ADDRESS3		=	p_cnv_pre_std_hdr_table(indx).SHIP_TO_ADDRESS3		,
				SHIP_TO_ADDRESS4		=	p_cnv_pre_std_hdr_table(indx).SHIP_TO_ADDRESS4		,
				SHIP_TO_CITY			=	p_cnv_pre_std_hdr_table(indx).SHIP_TO_CITY		,
				SHIP_TO_COUNTY			=	p_cnv_pre_std_hdr_table(indx).SHIP_TO_COUNTY		,
				--SHIP_TO_CUSTOMER		=	p_cnv_pre_std_hdr_table(indx).SHIP_TO_CUSTOMER		,
				SHIP_TO_CUSTOMER_NUMBER		=	p_cnv_pre_std_hdr_table(indx).SHIP_TO_CUSTOMER_NUMBER	,
				SHIP_TO_POSTAL_CODE		=	p_cnv_pre_std_hdr_table(indx).SHIP_TO_POSTAL_CODE	,
				SHIP_TO_PROVINCE		=	p_cnv_pre_std_hdr_table(indx).SHIP_TO_PROVINCE		,
				SHIP_TO_STATE			=	p_cnv_pre_std_hdr_table(indx).SHIP_TO_STATE		,
				SHIP_TO_COUNTRY			=	p_cnv_pre_std_hdr_table(indx).SHIP_TO_COUNTRY		,
				--INVOICE_ADDRESS1		=	p_cnv_pre_std_hdr_table(indx).INVOICE_ADDRESS1		,
				--INVOICE_ADDRESS2		=	p_cnv_pre_std_hdr_table(indx).INVOICE_ADDRESS2		,
				--INVOICE_ADDRESS3		=	p_cnv_pre_std_hdr_table(indx).INVOICE_ADDRESS3		,
				--INVOICE_ADDRESS4		=	p_cnv_pre_std_hdr_table(indx).INVOICE_ADDRESS4		,
				--INVOICE_CITY			=	p_cnv_pre_std_hdr_table(indx).INVOICE_CITY		,
				--INVOICE_COUNTRY		=	p_cnv_pre_std_hdr_table(indx).INVOICE_COUNTRY		,
				--INVOICE_COUNTY		=	p_cnv_pre_std_hdr_table(indx).INVOICE_COUNTY		,
				--INVOICE_CUSTOMER		=	p_cnv_pre_std_hdr_table(indx).INVOICE_CUSTOMER		,
				--INVOICE_CUSTOMER_NUMBER	=	p_cnv_pre_std_hdr_table(indx).INVOICE_CUSTOMER_NUMBER	,
				--INVOICE_POSTAL_CODE		=	p_cnv_pre_std_hdr_table(indx).INVOICE_POSTAL_CODE	,
				--INVOICE_PROVINCE_INT		=	p_cnv_pre_std_hdr_table(indx).INVOICE_PROVINCE_INT	,
				--INVOICE_SITE			=	p_cnv_pre_std_hdr_table(indx).INVOICE_SITE		,
				--INVOICE_SITE_CODE		=	p_cnv_pre_std_hdr_table(indx).INVOICE_SITE_CODE		,
				--INVOICE_STATE			=	p_cnv_pre_std_hdr_table(indx).INVOICE_STATE		,
				BOOKED_FLAG			=	p_cnv_pre_std_hdr_table(indx).BOOKED_FLAG		,
				CANCELLED_FLAG			=	p_cnv_pre_std_hdr_table(indx).CANCELLED_FLAG		,
				CLOSED_FLAG			=	p_cnv_pre_std_hdr_table(indx).CLOSED_FLAG		,
				ORDER_CATEGORY			=	p_cnv_pre_std_hdr_table(indx).ORDER_CATEGORY		,
				SOLD_FROM_ORG_ID		=	p_cnv_pre_std_hdr_table(indx).SOLD_FROM_ORG_ID		,
				ORIG_SHIP_ADDRESS_REF		=	p_cnv_pre_std_hdr_table(indx).ORIG_SHIP_ADDRESS_REF	,
				PRICING_DATE			=	p_cnv_pre_std_hdr_table(indx).PRICING_DATE		,
				TRANSACTION_PHASE_CODE		=	p_cnv_pre_std_hdr_table(indx).TRANSACTION_PHASE_CODE	,
				ATTRIBUTE1			=	p_cnv_pre_std_hdr_table(indx).ATTRIBUTE1		,
				ATTRIBUTE2			=	p_cnv_pre_std_hdr_table(indx).ATTRIBUTE2		,
				ATTRIBUTE3			=	p_cnv_pre_std_hdr_table(indx).ATTRIBUTE3		,
				ATTRIBUTE4			=	p_cnv_pre_std_hdr_table(indx).ATTRIBUTE4		,
				ATTRIBUTE5			=	p_cnv_pre_std_hdr_table(indx).ATTRIBUTE5		,
				--STATUS			=	p_cnv_pre_std_hdr_table(indx).STATUS			,
				REQUEST_DATE			=	p_cnv_pre_std_hdr_table(indx).REQUEST_DATE		,  --Added on 11-DEC-13 Wave1
				PROCESS_CODE			=	p_cnv_pre_std_hdr_table(indx).PROCESS_CODE		,
				ERROR_CODE			=	p_cnv_pre_std_hdr_table(indx).ERROR_CODE		,
				LAST_UPDATE_DATE		=	p_cnv_pre_std_hdr_table(indx).LAST_UPDATE_DATE		,
				LAST_UPDATED_BY			=	p_cnv_pre_std_hdr_table(indx).LAST_UPDATED_BY		,
				--SITE_NUMBER			=	p_cnv_pre_std_hdr_table(indx).SITE_NUMBER		,
				--LOCATION_NUMBER		=	p_cnv_pre_std_hdr_table(indx).LOCATION_NUMBER		,
				HOLD_ID				=	p_cnv_pre_std_hdr_table(indx).HOLD_ID			,
				BATCH_ID  			=	p_cnv_pre_std_hdr_table(indx).BATCH_ID			,
				RECORD_NUMBER			=	p_cnv_pre_std_hdr_table(indx).RECORD_NUMBER		,
                                NEW_FOB_POINT			=	p_cnv_pre_std_hdr_table(indx).NEW_FOB_POINT		,
				NEW_FREIGHT_TERM    		=	p_cnv_pre_std_hdr_table(indx).NEW_FREIGHT_TERM		,
				NEW_PARTY_ID			=	p_cnv_pre_std_hdr_table(indx).NEW_PARTY_ID		,
				GLOBAL_LOCATION_NUMBER		=	p_cnv_pre_std_hdr_table(indx).GLOBAL_LOCATION_NUMBER	,
				NEW_WAREHOUSE_ID		=	p_cnv_pre_std_hdr_table(indx).NEW_WAREHOUSE_ID		,
				NEW_SHIP_VIA			=	p_cnv_pre_std_hdr_table(indx).NEW_SHIP_VIA		,
				NEW_PRIMARY_SALESREP_ID		=	p_cnv_pre_std_hdr_table(indx).NEW_PRIMARY_SALESREP_ID	,
				NEW_ADD_FLAG			=	p_cnv_pre_std_hdr_table(indx).NEW_ADD_FLAG		,
				NEW_SITE_FLAG			=	p_cnv_pre_std_hdr_table(indx).NEW_SITE_FLAG		,
                                NEW_LOCATION_ID			=	p_cnv_pre_std_hdr_table(indx).NEW_location_id           ,
                                SHIPMENT_PRIORITY_CODE          =       p_cnv_pre_std_hdr_table(indx).SHIPMENT_PRIORITY_CODE      --Added on 21-JAN-13
			WHERE	record_number			=	p_cnv_pre_std_hdr_table(indx).record_number             
			AND   BATCH_ID                          = G_BATCH_ID;

				
                        END LOOP;
				/*if sql%rowcount <> 0 Then
		     			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Failed to update Header Level Records !!');					
				else
					xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Header Level Records got Updated !! '||sql%rowcount);
				end if;*/
                        COMMIT;
                END update_pre_interface_records;

		--Line Level Update
		PROCEDURE update_pre_lines_int_records (p_cnv_pre_std_line_table IN G_XX_SO_LINE_PRE_STD_TAB_TYPE)
                IS
                        x_last_update_date     DATE   := SYSDATE;
                        x_last_updated_by      NUMBER := fnd_global.user_id;
                        x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

                        PRAGMA AUTONOMOUS_TRANSACTION;
                BEGIN
                     FOR indx IN 1 .. p_cnv_pre_std_line_table.COUNT LOOP
                     --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside update_pre_lines_int_records ..' );

                               
				UPDATE  XX_OE_ORDER_LINES_ALL_PRE
				SET
			        LINE_ID				=	p_cnv_pre_std_line_table(indx).LINE_ID			,		
				--ORG_ID			=	p_cnv_pre_std_line_table(indx).ORG_ID			,
				HEADER_ID			=	p_cnv_pre_std_line_table(indx).HEADER_ID		,
				ORIG_SYS_DOCUMENT_REF		=	p_cnv_pre_std_line_table(indx).ORIG_SYS_DOCUMENT_REF	,
				ORIG_SYS_LINE_REF		=	p_cnv_pre_std_line_table(indx).ORIG_SYS_LINE_REF	,
				SHIPMENT_NUMBER			=	p_cnv_pre_std_line_table(indx).SHIPMENT_NUMBER		,
				LINE_TYPE			=	p_cnv_pre_std_line_table(indx).LINE_TYPE		,
				LINE_TYPE_ID			=	p_cnv_pre_std_line_table(indx).LINE_TYPE_ID		,	
				--ORDER_SOURCE_ID		=	p_cnv_pre_std_line_table(indx).ORDER_SOURCE_ID		,	
				LINE_NUMBER			=	p_cnv_pre_std_line_table(indx).LINE_NUMBER		,	
				ITEM_TYPE_CODE			=	p_cnv_pre_std_line_table(indx).ITEM_TYPE_CODE		,	
				INVENTORY_ITEM			=	p_cnv_pre_std_line_table(indx).INVENTORY_ITEM		,	
				INVENTORY_ITEM_ID		=	p_cnv_pre_std_line_table(indx).INVENTORY_ITEM_ID	,	
				SOURCE_TYPE_CODE		=	p_cnv_pre_std_line_table(indx).SOURCE_TYPE_CODE		,
				SCHEDULE_STATUS_CODE		=	p_cnv_pre_std_line_table(indx).SCHEDULE_STATUS_CODE	,	
				SCHEDULE_SHIP_DATE		=	p_cnv_pre_std_line_table(indx).SCHEDULE_SHIP_DATE	,	
				SCHEDULE_ARRIVAL_DATE		=	p_cnv_pre_std_line_table(indx).SCHEDULE_ARRIVAL_DATE	,	
				PROMISE_DATE			=	p_cnv_pre_std_line_table(indx).PROMISE_DATE		,	
				SCHEDULE_DATE			=	p_cnv_pre_std_line_table(indx).SCHEDULE_DATE		,	
				ORDERED_QUANTITY		=	p_cnv_pre_std_line_table(indx).ORDERED_QUANTITY		,
				ORDER_QUANTITY_UOM		=	p_cnv_pre_std_line_table(indx).ORDER_QUANTITY_UOM	,	
				PRICING_QUANTITY		=	p_cnv_pre_std_line_table(indx).PRICING_QUANTITY		,
				SHIPPING_QUANTITY_UOM		=	p_cnv_pre_std_line_table(indx).SHIPPING_QUANTITY_UOM	,	
				PRICING_QUANTITY_UOM		=	p_cnv_pre_std_line_table(indx).PRICING_QUANTITY_UOM	,	
				CANCELLED_QUANTITY		=	p_cnv_pre_std_line_table(indx).CANCELLED_QUANTITY	,	
				SOLD_TO_ORG			=	p_cnv_pre_std_line_table(indx).SOLD_TO_ORG		,	
				SHIP_FROM_ORG			=	p_cnv_pre_std_line_table(indx).SHIP_FROM_ORG		,	
				SHIP_FROM_ORG_ID		=	p_cnv_pre_std_line_table(indx).SHIP_FROM_ORG_ID		,
				SHIP_TO_ORG			=	p_cnv_pre_std_line_table(indx).SHIP_TO_ORG		,	
				SHIP_TO_ORG_ID			=	p_cnv_pre_std_line_table(indx).SHIP_TO_ORG_ID		,	
				INVOICE_TO_ORG			=	p_cnv_pre_std_line_table(indx).INVOICE_TO_ORG		,	
				INVOICE_TO_ORG_ID		=	p_cnv_pre_std_line_table(indx).INVOICE_TO_ORG_ID	,
				--SHIP_TO_ADDRESS1		=	p_cnv_pre_std_line_table(indx).SHIP_TO_ADDRESS1		,
				--SHIP_TO_ADDRESS2		=	p_cnv_pre_std_line_table(indx).SHIP_TO_ADDRESS2		,
				--SHIP_TO_ADDRESS3		=	p_cnv_pre_std_line_table(indx).SHIP_TO_ADDRESS3		,
				--SHIP_TO_ADDRESS4		=	p_cnv_pre_std_line_table(indx).SHIP_TO_ADDRESS4		,
				--SHIP_TO_CITY			=	p_cnv_pre_std_line_table(indx).SHIP_TO_CITY		,	
				--SHIP_TO_COUNTY		=	p_cnv_pre_std_line_table(indx).SHIP_TO_COUNTY		,	
				--SHIP_TO_STATE			=	p_cnv_pre_std_line_table(indx).SHIP_TO_STATE		,	
				--SHIP_TO_POSTAL_CODE		=	p_cnv_pre_std_line_table(indx).SHIP_TO_POSTAL_CODE	,	
				--SHIP_TO_COUNTRY		=	p_cnv_pre_std_line_table(indx).SHIP_TO_COUNTRY		,	
				PRICE_LIST			=	p_cnv_pre_std_line_table(indx).PRICE_LIST		,	
				PRICE_LIST_ID			=	p_cnv_pre_std_line_table(indx).PRICE_LIST_ID		,	
				PRICING_DATE			=	p_cnv_pre_std_line_table(indx).PRICING_DATE		,	
				UNIT_LIST_PRICE			=	p_cnv_pre_std_line_table(indx).UNIT_LIST_PRICE		,	
				UNIT_SELLING_PRICE		=	p_cnv_pre_std_line_table(indx).UNIT_SELLING_PRICE	,	
				CALCULATE_PRICE_FLAG		=	p_cnv_pre_std_line_table(indx).CALCULATE_PRICE_FLAG	,	
				TAX_DATE			=	p_cnv_pre_std_line_table(indx).TAX_DATE			,
				TAX_EXEMPT_FLAG			=	p_cnv_pre_std_line_table(indx).TAX_EXEMPT_FLAG		,	
				PAYMENT_TERM			=	p_cnv_pre_std_line_table(indx).PAYMENT_TERM		,	
				--PAYMENT_TERM_ID		=	p_cnv_pre_std_line_table(indx).PAYMENT_TERM_ID		,	
				SHIPPING_METHOD_CODE		=	p_cnv_pre_std_line_table(indx).SHIPPING_METHOD_CODE	,	
				--SHIPPING_METHOD		=	p_cnv_pre_std_line_table(indx).SHIPPING_METHOD		,	
				FREIGHT_CARRIER_CODE		=	p_cnv_pre_std_line_table(indx).FREIGHT_CARRIER_CODE	,	
				FREIGHT_TERMS_CODE		=	p_cnv_pre_std_line_table(indx).FREIGHT_TERMS_CODE	,	
				--FREIGHT_TERMS			=	p_cnv_pre_std_line_table(indx).FREIGHT_TERMS		,	
				FOB_POINT_CODE			=	p_cnv_pre_std_line_table(indx).FOB_POINT_CODE		,	
				--FOB_POINT			=	p_cnv_pre_std_line_table(indx).FOB_POINT		,
				SALESREP			=	p_cnv_pre_std_line_table(indx).SALESREP			,
				CUSTOMER_PO_NUMBER		=	p_cnv_pre_std_line_table(indx).CUSTOMER_PO_NUMBER	,	
				CANCELLED_FLAG			=	p_cnv_pre_std_line_table(indx).CANCELLED_FLAG		,	
				--OPEN_FLAG			=	p_cnv_pre_std_line_table(indx).OPEN_FLAG		,
				--BOOKED_FLAG			=	p_cnv_pre_std_line_table(indx).BOOKED_FLAG		,	
				REQUEST_DATE			=	p_cnv_pre_std_line_table(indx).REQUEST_DATE		,	
				SOLD_FROM_ORG			=	p_cnv_pre_std_line_table(indx).SOLD_FROM_ORG		,	
				UNIT_LIST_PRICE_PER_PQTY	=	p_cnv_pre_std_line_table(indx).UNIT_LIST_PRICE_PER_PQTY	,
				UNIT_SELLING_PRICE_PER_PQTY	=	p_cnv_pre_std_line_table(indx).UNIT_SELLING_PRICE_PER_PQTY	,
				--INVOICE_TO_ADDRESS1		=	p_cnv_pre_std_line_table(indx).INVOICE_TO_ADDRESS1	,	
				--INVOICE_TO_ADDRESS2		=	p_cnv_pre_std_line_table(indx).INVOICE_TO_ADDRESS2	,	
				--INVOICE_TO_ADDRESS3		=	p_cnv_pre_std_line_table(indx).INVOICE_TO_ADDRESS3	,	
				--INVOICE_TO_ADDRESS4		=	p_cnv_pre_std_line_table(indx).INVOICE_TO_ADDRESS4	,	
				--INVOICE_TO_CITY		=	p_cnv_pre_std_line_table(indx).INVOICE_TO_CITY		,	
				--INVOICE_TO_COUNTY		=	p_cnv_pre_std_line_table(indx).INVOICE_TO_COUNTY	,
				--INVOICE_TO_STATE		=	p_cnv_pre_std_line_table(indx).INVOICE_TO_STATE		,
				--INVOICE_TO_POSTAL_CODE	=	p_cnv_pre_std_line_table(indx).INVOICE_TO_POSTAL_CODE	,	
				--INVOICE_TO_COUNTRY		=	p_cnv_pre_std_line_table(indx).INVOICE_TO_COUNTRY	,	
				--SHIP_TO_CUSTOMER_NAME		=	p_cnv_pre_std_line_table(indx).SHIP_TO_CUSTOMER_NAME	,	
				SHIP_TO_CUSTOMER_NUMBER		=	p_cnv_pre_std_line_table(indx).SHIP_TO_CUSTOMER_NUMBER	,	
				--INVOICE_TO_CUSTOMER_NAME	=	p_cnv_pre_std_line_table(indx).INVOICE_TO_CUSTOMER_NAME	,
				INVOICE_TO_CUSTOMER_NUMBER	=	p_cnv_pre_std_line_table(indx).INVOICE_TO_CUSTOMER_NUMBER,	
				LINE_CATEGORY_CODE		=	p_cnv_pre_std_line_table(indx).LINE_CATEGORY_CODE	,	
				--STATUS			=	p_cnv_pre_std_line_table(indx).STATUS			,	
				BATCH_ID			=	p_cnv_pre_std_line_table(indx).BATCH_ID			,
				RECORD_NUMBER			=	p_cnv_pre_std_line_table(indx).RECORD_NUMBER		,	
				PROCESS_CODE			=	p_cnv_pre_std_line_table(indx).PROCESS_CODE		,	
				ERROR_CODE			=	p_cnv_pre_std_line_table(indx).ERROR_CODE		,	
				REQUEST_ID			=	p_cnv_pre_std_line_table(indx).REQUEST_ID		,	
				CREATED_BY			=	p_cnv_pre_std_line_table(indx).CREATED_BY		,	
				CREATION_DATE			=	p_cnv_pre_std_line_table(indx).CREATION_DATE		,	
				LAST_UPDATE_DATE		=	p_cnv_pre_std_line_table(indx).LAST_UPDATE_DATE		,
				LAST_UPDATED_BY			=	p_cnv_pre_std_line_table(indx).LAST_UPDATED_BY		,	
				LAST_UPDATE_LOGIN		=	p_cnv_pre_std_line_table(indx).LAST_UPDATE_LOGIN	,
                                CUSTOMER_ITEM_NAME              =       p_cnv_pre_std_line_table(indx).CUSTOMER_ITEM_NAME       ,
                                CUSTOMER_ITEM_ID_TYPE           =       p_cnv_pre_std_line_table(indx).CUSTOMER_ITEM_ID_TYPE
			    WHERE record_number			=	p_cnv_pre_std_line_table(indx).record_number
			    AND   BATCH_ID                      = G_LINE_BATCH_ID;

			    IF p_cnv_pre_std_line_table(indx).ERROR_CODE IN ( xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_REC_WARN) THEN

			      UPDATE XX_OE_ORDER_HEADERS_ALL_PRE
			      SET    error_code = p_cnv_pre_std_line_table(indx).ERROR_CODE
			      WHERE  ORIG_SYS_DOCUMENT_REF = p_cnv_pre_std_line_table(indx).ORIG_SYS_DOCUMENT_REF; 

			   END IF;
			    			    
			    
			END LOOP;
				/*if sql%rowcount <> 0 Then		     			
					xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Failed to update Line Level Records !!');
				else
					xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Line Level Records got Updated !! '||sql%rowcount);
				end if; */
                        COMMIT;
                END update_pre_lines_int_records;
		
		-------------------------------------------------------------------------
                -----------< move_rec_pre_standard_table >-------------------------------
                -------------------------------------------------------------------------
		
		-- Header Level
		FUNCTION move_rec_pre_standard_table RETURN NUMBER
                IS
                        x_creation_date         DATE   := SYSDATE;
                        x_created_by            NUMBER := fnd_global.user_id;
                        x_last_update_date      DATE   := SYSDATE;
                        x_last_updated_by       NUMBER := fnd_global.user_id;
                        x_last_update_login     NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
                        x_error_code		NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

                        PRAGMA AUTONOMOUS_TRANSACTION;
                BEGIN
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside move_rec_pre_standard_table');

			-- Select only the appropriate columns that are required to be inserted into the
                        -- Pre-Interface Table and insert from the Staging Table
			
			--fnd_file.put_line(fnd_file.log,'Batch Id ... '||G_BATCH_ID);
			--fnd_file.put_line(fnd_file.log,'Insert Into XX_OE_ORDER_HEADERS_ALL_PRE.... ');


                        INSERT INTO XX_OE_ORDER_HEADERS_ALL_PRE
                        (ORIG_SYS_DOCUMENT_REF                 
			, ORDER_SOURCE                          
			, ORG_CODE                              
			, ORDER_NUMBER                          
			, ORDERED_DATE                          
			, ORDER_TYPE                            
			, PRICE_LIST                            
			, CONVERSION_RATE                       
			, CONVERSION_RATE_DATE                  
			, CONVERSION_TYPE_CODE                  
			, TRANSACTIONAL_CURR_CODE                 
			, SALESREP                                
			, SALES_CHANNEL_CODE                      
			, RETURN_REASON_CODE                      
			, TAX_POINT_CODE                          
			, TAX_EXEMPT_FLAG                         
			, TAX_EXEMPT_NUMBER                       
			, TAX_EXEMPT_REASON_CODE                  
			, PAYMENT_TERM                            
			, DEMAND_CLASS_CODE                       
			, SHIPMENT_PRIORITY_CODE                  
			, SHIPPING_METHOD_CODE                    
			, FREIGHT_CARRIER_CODE                    
			, FREIGHT_TERMS_CODE                      
			, FOB_POINT_CODE                          
			, PARTIAL_SHIPMENTS_ALLOWED               
			, SHIPPING_INSTRUCTIONS                   
			, PACKING_INSTRUCTIONS                    
			, CUSTOMER_PO_NUMBER                      
			, CUSTOMER_PAYMENT_TERM                   
			, SOLD_TO_ORG                             
			, INVOICE_TO_ORG     
			, BILL_TO_CUSTOMER_NUMBER                 
			, BILL_TO_ADDRESS1                        
			, BILL_TO_ADDRESS2                        
			, BILL_TO_ADDRESS3                        
			, BILL_TO_ADDRESS4                        
			, BILL_TO_CITY                            
			, BILL_TO_COUNTY                          
			, BILL_TO_POSTAL_CODE                     
			, BILL_TO_PROVINCE                        
			, BILL_TO_STATE                           
			, BILL_TO_COUNTRY   
			, DELIVER_TO_ORG                          
			, DELIVER_TO_CUSTOMER_NUMBER  
			, DELIVER_TO_ADDRESS1                        
			, DELIVER_TO_ADDRESS2                        
			, DELIVER_TO_ADDRESS3                        
			, DELIVER_TO_ADDRESS4                        
			, DELIVER_TO_CITY                            
			, DELIVER_TO_COUNTY                          
			, DELIVER_TO_POSTAL_CODE                     
			, DELIVER_TO_PROVINCE                        
			, DELIVER_TO_STATE                           
			, DELIVER_TO_COUNTRY   
			, DELIVER_TO_CONTACT
			, CUSTOMER_NUMBER                         
			, SHIPMENT_PRIORITY_CODE_INT              
			, SHIP_TO_ORG                             
			, SHIP_TO_CUSTOMER_NUMBER                 
			, SHIP_TO_ADDRESS1                        
			, SHIP_TO_ADDRESS2                        
			, SHIP_TO_ADDRESS3                        
			, SHIP_TO_ADDRESS4                        
			, SHIP_TO_CITY                            
			, SHIP_TO_COUNTY                          
			, SHIP_TO_POSTAL_CODE                     
			, SHIP_TO_PROVINCE                        
			, SHIP_TO_STATE                           
			, SHIP_TO_COUNTRY                         
			, SHIP_FROM_ORG                           
			, SOLD_FROM_ORG                           
			, DROP_SHIP_FLAG                          
			, BOOKED_FLAG                             
			, CLOSED_FLAG                             
			, CANCELLED_FLAG                          
			, CONTEXT                                 
			, ATTRIBUTE1                              
			, ATTRIBUTE2                              
			, ATTRIBUTE3                              
			, ATTRIBUTE4                              
			, ATTRIBUTE5
			, ATTRIBUTE6  --Added as per TDR 30-OCT-12
			, ATTRIBUTE7
			, ATTRIBUTE8
			, ATTRIBUTE9
			, ATTRIBUTE10
			, GLOBAL_ATTRIBUTE_CATEGORY               
			, GLOBAL_ATTRIBUTE1                       
			, GLOBAL_ATTRIBUTE2                       
			, GLOBAL_ATTRIBUTE3                       
			, GLOBAL_ATTRIBUTE4                       
			, GLOBAL_ATTRIBUTE5                       
			, ORDER_CATEGORY                          
			, REJECTED_FLAG                           
			, SALES_CHANNEL                           
			, CUSTOMER_PREFERENCE_SET_CODE            
			, PRICE_REQUEST_CODE                      
			, ORIG_SYS_CUSTOMER_REF                   
			, ORIG_SHIP_ADDRESS_REF                   
			, ACCOUNTING_RULE_DURATION                
			, BLANKET_NUMBER                          
			, PRICING_DATE                            
			, TRANSACTION_PHASE_CODE                  
			, QUOTE_NUMBER                           
			, QUOTE_DATE                             
			, SUPPLIER_SIGNATURE                     
			, SUPPLIER_SIGNATURE_DATE                
			, CUSTOMER_SIGNATURE                     
			, CUSTOMER_SIGNATURE_DATE                
			, EXPIRATION_DATE                        
			, SALES_REGION                           
			, SALESMAN_NUMBER                        
			, HOLD_TYPE_CODE                         
			, RELEASE_REASON_CODE                    
			, COMMENTS                               
			, CHAR_PARAM1                             
			, CHAR_PARAM2                             
			, DATE_PARAM1                             
			, DATE_PARAM2  
			, TP_CONTEXT                             
			, TP_ATTRIBUTE1                          
                        , TP_ATTRIBUTE2      
                        , REQUEST_DATE   --Added on 11-DEC-13 as per Wave1
			, BATCH_ID                                
		        , RECORD_NUMBER                         
			, PROCESS_CODE                            
			, ERROR_CODE                              
			, CREATED_BY                              
			, CREATION_DATE                           
			, LAST_UPDATE_DATE                        
			, LAST_UPDATED_BY                         
			, LAST_UPDATE_LOGIN                       
			, REQUEST_ID                 )
			SELECT 
			  ORIG_SYS_DOCUMENT_REF                 
			, ORDER_SOURCE                          
			, ORG_CODE                              
			, ORDER_NUMBER                          
			, ORDERED_DATE                          
			, ORDER_TYPE                            
			, PRICE_LIST                            
			, CONVERSION_RATE                       
			, CONVERSION_RATE_DATE                  
			, CONVERSION_TYPE_CODE                  
			, TRANSACTIONAL_CURR_CODE                 
			, SALESREP                                
			, SALES_CHANNEL_CODE                      
			, RETURN_REASON_CODE                      
			, TAX_POINT_CODE                          
			, TAX_EXEMPT_FLAG                         
			, TAX_EXEMPT_NUMBER                       
			, TAX_EXEMPT_REASON_CODE                  
			, PAYMENT_TERM                            
			, DEMAND_CLASS_CODE                       
			, SHIPMENT_PRIORITY_CODE                  
			, SHIPPING_METHOD_CODE                    
			, FREIGHT_CARRIER_CODE                    
			, FREIGHT_TERMS_CODE                      
			, FOB_POINT_CODE                          
			, PARTIAL_SHIPMENTS_ALLOWED               
			, SHIPPING_INSTRUCTIONS                   
			, PACKING_INSTRUCTIONS                    
			, CUSTOMER_PO_NUMBER                      
			, CUSTOMER_PAYMENT_TERM                   
			, SOLD_TO_ORG                             
			, INVOICE_TO_ORG
			, BILL_TO_CUSTOMER_NUMBER
                        , BILL_TO_ADDRESS1
                        , BILL_TO_ADDRESS2
                        , BILL_TO_ADDRESS3
                        , BILL_TO_ADDRESS4
                        , BILL_TO_CITY
                        , BILL_TO_COUNTY
                        , BILL_TO_POSTAL_CODE
                        , BILL_TO_PROVINCE
                        , BILL_TO_STATE
                        , BILL_TO_COUNTRY
			, DELIVER_TO_ORG                          
			, DELIVER_TO_CUSTOMER_NUMBER   
			, DELIVER_TO_ADDRESS1                        
			, DELIVER_TO_ADDRESS2                        
			, DELIVER_TO_ADDRESS3                        
			, DELIVER_TO_ADDRESS4                        
			, DELIVER_TO_CITY                            
			, DELIVER_TO_COUNTY                          
			, DELIVER_TO_POSTAL_CODE                     
			, DELIVER_TO_PROVINCE                        
			, DELIVER_TO_STATE                           
			, DELIVER_TO_COUNTRY 
			, DELIVER_TO_CONTACT  
			, CUSTOMER_NUMBER                         
			, SHIPMENT_PRIORITY_CODE_INT              
			, SHIP_TO_ORG                             
			, SHIP_TO_CUSTOMER_NUMBER                 
			, SHIP_TO_ADDRESS1                        
			, SHIP_TO_ADDRESS2                        
			, SHIP_TO_ADDRESS3                        
			, SHIP_TO_ADDRESS4                        
			, SHIP_TO_CITY                            
			, SHIP_TO_COUNTY                          
			, SHIP_TO_POSTAL_CODE                     
			, SHIP_TO_PROVINCE                        
			, SHIP_TO_STATE                           
			, SHIP_TO_COUNTRY                         
			, SHIP_FROM_ORG                           
			, SOLD_FROM_ORG                           
			, DROP_SHIP_FLAG                          
			, BOOKED_FLAG                             
			, CLOSED_FLAG                             
			, CANCELLED_FLAG                          
			, CONTEXT                                 
			, ATTRIBUTE1                              
			, ATTRIBUTE2                              
			, ATTRIBUTE3                              
			, ATTRIBUTE4                              
			, ATTRIBUTE5  
			, ATTRIBUTE6  --Added as per TDR 30-OCT-12
			, ATTRIBUTE7
			, ATTRIBUTE8
			, ATTRIBUTE9
			, ATTRIBUTE10
			, GLOBAL_ATTRIBUTE_CATEGORY               
			, GLOBAL_ATTRIBUTE1                       
			, GLOBAL_ATTRIBUTE2                       
			, GLOBAL_ATTRIBUTE3                       
			, GLOBAL_ATTRIBUTE4                       
			, GLOBAL_ATTRIBUTE5                       
			, ORDER_CATEGORY                          
			, REJECTED_FLAG                           
			, SALES_CHANNEL                           
			, CUSTOMER_PREFERENCE_SET_CODE            
			, PRICE_REQUEST_CODE                      
			, ORIG_SYS_CUSTOMER_REF                   
			, ORIG_SHIP_ADDRESS_REF                   
			, ACCOUNTING_RULE_DURATION                
			, BLANKET_NUMBER                          
			, PRICING_DATE                            
			, TRANSACTION_PHASE_CODE                  
			, QUOTE_NUMBER                           
			, QUOTE_DATE                             
			, SUPPLIER_SIGNATURE                     
			, SUPPLIER_SIGNATURE_DATE                
			, CUSTOMER_SIGNATURE                     
			, CUSTOMER_SIGNATURE_DATE                
			, EXPIRATION_DATE                        
			, SALES_REGION                           
			, SALESMAN_NUMBER                        
			, HOLD_TYPE_CODE                         
			, RELEASE_REASON_CODE                    
			, COMMENTS                               
			, CHAR_PARAM1                             
			, CHAR_PARAM2                             
			, DATE_PARAM1                             
			, DATE_PARAM2       
			, TP_CONTEXT                             
			, TP_ATTRIBUTE1                          
			, TP_ATTRIBUTE2
			, REQUEST_DATE
			, BATCH_ID                                
		        , RECORD_NUMBER
			, PROCESS_CODE                            
			, ERROR_CODE                              
			, X_CREATED_BY
			, X_CREATION_DATE
			, X_LAST_UPDATE_DATE
			, X_LAST_UPDATED_BY
			, X_LAST_UPDATE_LOGIN  -- DO NOT CHANGE TO THIS LINE
			, REQUEST_ID                              
			  FROM XX_OE_ORDER_HEADERS_ALL_STG	-- Order Headers Staging
                         WHERE BATCH_ID     = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_PREVAL
                           AND request_id   = xx_emf_pkg.G_REQUEST_ID
                           AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
			   ;

			   
			 /*  if sql%rowcount > 0 Then
			      fnd_file.put_line(fnd_file.log,'No Of Records Inserted : '||sql%rowcount);
			    else
                              fnd_file.put_line(fnd_file.log,'Failed Insert Stmt !! ');
			   end if;*/

		           COMMIT;                

                        RETURN x_error_code;
                EXCEPTION
                        WHEN OTHERS THEN
                                xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
                                x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
                                RETURN x_error_code;
                END move_rec_pre_standard_table;
		

		-- Line Level
		FUNCTION move_rec_pre_lines_table RETURN NUMBER
                IS
                        x_creation_date         DATE   := SYSDATE;
                        x_created_by            NUMBER := fnd_global.user_id;
                        x_last_update_date      DATE   := SYSDATE;
                        x_last_updated_by       NUMBER := fnd_global.user_id;
                        x_last_update_login     NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
                        x_error_code		NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

                        PRAGMA AUTONOMOUS_TRANSACTION;
                BEGIN
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside move_rec_pre_Lines_table');

			-- Select only the appropriate columns that are required to be inserted into the
                        -- Pre-Interface Table and insert from the Staging Table


                        INSERT INTO XX_OE_ORDER_LINES_ALL_PRE
                        (BATCH_ID   			
			,RECORD_NUMBER  			
			,ORIG_SYS_DOCUMENT_REF 		
			,ORIG_SYS_LINE_REF 		
			,ORIG_SYS_SHIPMENT_REF 		
			,LINE_NUMBER 			
			,SHIPMENT_NUMBER 		
			,LINE_TYPE 			
			,ITEM_TYPE_CODE  		
			,INVENTORY_ITEM		        
			,SOURCE_TYPE_CODE 		
			,SCHEDULE_STATUS_CODE 		
			,SCHEDULE_SHIP_DATE 		
			,SCHEDULE_ARRIVAL_DATE 		
			,ACTUAL_ARRIVAL_DATE 		
			,PROMISE_DATE 			
			,SCHEDULE_DATE 			
			,ORDERED_QUANTITY 		
			,ORDER_QUANTITY_UOM 		
			,SHIPPING_QUANTITY 		
			,SHIPPING_QUANTITY_UOM 		
			,SHIPPED_QUANTITY 		
			,CANCELLED_QUANTITY 		
			,FULFILLED_QUANTITY 		
			,PRICING_QUANTITY 		
			,PRICING_QUANTITY_UOM 		
			,SOLD_TO_ORG  			
			,SHIP_FROM_ORG 			
			,SHIP_TO_ORG 
			,DELIVER_TO_ORG 			
			,INVOICE_TO_ORG 
			,DROP_SHIP_FLAG 			
			,LOAD_SEQ_NUMBER 		
			,AUTHORIZED_TO_SHIP_FLAG 	
			,SHIP_SET_NAME 			
			,ARRIVAL_SET_NAME 		
			,INVOICE_SET_NAME 		
			,PRICE_LIST 			
			,PRICING_DATE 			
			,UNIT_LIST_PRICE 		
			,UNIT_SELLING_PRICE 		
			,CALCULATE_PRICE_FLAG 		
			,TAX_CODE 			
			,TAX_VALUE 			
			,TAX_DATE 			
			,TAX_POINT_CODE 			
			,TAX_EXEMPT_FLAG 		
			,TAX_EXEMPT_NUMBER 		
			,TAX_EXEMPT_REASON_CODE 		
			,PAYMENT_TERM 			
			,DEMAND_CLASS_CODE 		
			,SHIPMENT_PRIORITY_CODE 		
			,SHIPPING_METHOD_CODE	 	
			,FREIGHT_CARRIER_CODE 		
			,FREIGHT_TERMS_CODE 		
			,FOB_POINT_CODE 			
			,SALESREP 			
			,CUSTOMER_PO_NUMBER 		
			,CUSTOMER_LINE_NUMBER 		
			,CUSTOMER_SHIPMENT_NUMBER 	
			,CLOSED_FLAG 			
			,CANCELLED_FLAG 			
			,CONTEXT 			
			,ATTRIBUTE1 			
			,ATTRIBUTE2 			
			,ATTRIBUTE3 			
			,ATTRIBUTE4 			
			,ATTRIBUTE5 			
			,GLOBAL_ATTRIBUTE_CATEGORY 	
			,GLOBAL_ATTRIBUTE1 		
			,GLOBAL_ATTRIBUTE2 		
			,GLOBAL_ATTRIBUTE3 		
			,GLOBAL_ATTRIBUTE4 		
			,GLOBAL_ATTRIBUTE5 		
			,FULFILLED_FLAG 			
			,REQUEST_DATE 			
			,SHIPPING_INSTRUCTIONS 		
			,PACKING_INSTRUCTIONS 		
			,SOLD_FROM_ORG 			
			,CUSTOMER_ITEM_NAME 		
			,SUBINVENTORY 			
			,UNIT_LIST_PRICE_PER_PQTY 	
			,UNIT_SELLING_PRICE_PER_PQTY 	
			,PRICE_REQUEST_CODE 		
			,ORIG_SHIP_ADDRESS_REF 		
			,ORIG_BILL_ADDRESS_REF 		
			,SHIP_TO_CUSTOMER_NUMBER 	
			,INVOICE_TO_CUSTOMER_NUMBER 	
			,DELIVER_TO_CUSTOMER_NUMBER 	
			,ACCOUNTING_RULE_DURATION  	
			,USER_ITEM_DESCRIPTION 		
			,LINE_CATEGORY_CODE 
			,TP_CONTEXT                 
			,TP_ATTRIBUTE1              
			,TP_ATTRIBUTE2              
			,TP_ATTRIBUTE3              
			,TP_ATTRIBUTE4              
			,TP_ATTRIBUTE5              
                        ,ORDERED_ITEM               
			,SALES_REGION 			
			,SALESMAN_NUMBER 		
			,PROCESS_CODE 			
			,ERROR_CODE 			
			,CREATED_BY 			
			,CREATION_DATE 			
			,LAST_UPDATE_DATE 		
			,LAST_UPDATED_BY 		
			,LAST_UPDATE_LOGIN 		
			,REQUEST_ID 	
			,RETURN_REASON_CODE     --Added on 28-FEB-2014
			)				
			SELECT xol.BATCH_ID   			
			,xol.RECORD_NUMBER  			
			,xol.ORIG_SYS_DOCUMENT_REF 		
			,xol.ORIG_SYS_LINE_REF 		
			,xol.ORIG_SYS_SHIPMENT_REF 		
			,xol.LINE_NUMBER 			
			,xol.SHIPMENT_NUMBER 		
			,xol.LINE_TYPE 			
			,xol.ITEM_TYPE_CODE  		
			,xol.INVENTORY_ITEM		        
			,xol.SOURCE_TYPE_CODE 		
			,xol.SCHEDULE_STATUS_CODE 		
			,xol.SCHEDULE_SHIP_DATE 		
			,xol.SCHEDULE_ARRIVAL_DATE 		
			,xol.ACTUAL_ARRIVAL_DATE 		
			,xol.PROMISE_DATE 			
			,xol.SCHEDULE_DATE 			
			,xol.ORDERED_QUANTITY 		
			,xol.ORDER_QUANTITY_UOM 		
			,xol.SHIPPING_QUANTITY 		
			,xol.SHIPPING_QUANTITY_UOM 		
			,xol.SHIPPED_QUANTITY 		
			,xol.CANCELLED_QUANTITY 		
			,xol.FULFILLED_QUANTITY 		
			,xol.PRICING_QUANTITY 		
			,xol.PRICING_QUANTITY_UOM 		
			,xol.SOLD_TO_ORG  			
			,xol.SHIP_FROM_ORG 			
			,xol.SHIP_TO_ORG 
			,xol.DELIVER_TO_ORG 			
			,xol.INVOICE_TO_ORG
			,xol.DROP_SHIP_FLAG 			
			,xol.LOAD_SEQ_NUMBER 		
			,xol.AUTHORIZED_TO_SHIP_FLAG 	
			,xol.SHIP_SET_NAME 			
			,xol.ARRIVAL_SET_NAME 		
			,xol.INVOICE_SET_NAME 		
			,xol.PRICE_LIST 			
			,xol.PRICING_DATE 			
			,xol.UNIT_LIST_PRICE 		
			,xol.UNIT_SELLING_PRICE 		
			,xol.CALCULATE_PRICE_FLAG 		
			,xol.TAX_CODE 			
			,xol.TAX_VALUE 			
			,xol.TAX_DATE 			
			,xol.TAX_POINT_CODE 			
			,xol.TAX_EXEMPT_FLAG 		
			,xol.TAX_EXEMPT_NUMBER 		
			,xol.TAX_EXEMPT_REASON_CODE 		
			,xol.PAYMENT_TERM 			
			,xol.DEMAND_CLASS_CODE 		
			,xol.SHIPMENT_PRIORITY_CODE 		
			,xol.SHIPPING_METHOD_CODE	 	
			,xol.FREIGHT_CARRIER_CODE 		
			,xol.FREIGHT_TERMS_CODE 		
			,xol.FOB_POINT_CODE 			
			,xol.SALESREP 			
			,xol.CUSTOMER_PO_NUMBER 		
			,xol.CUSTOMER_LINE_NUMBER 		
			,xol.CUSTOMER_SHIPMENT_NUMBER 	
			,xol.CLOSED_FLAG 			
			,xol.CANCELLED_FLAG 			
			,xol.CONTEXT 			
			,xol.ATTRIBUTE1 			
			,xol.ATTRIBUTE2 			
			,xol.ATTRIBUTE3 			
			,xol.ATTRIBUTE4 			
			,xol.ATTRIBUTE5 			
			,xol.GLOBAL_ATTRIBUTE_CATEGORY 	
			,xol.GLOBAL_ATTRIBUTE1 		
			,xol.GLOBAL_ATTRIBUTE2 		
			,xol.GLOBAL_ATTRIBUTE3 		
			,xol.GLOBAL_ATTRIBUTE4 		
			,xol.GLOBAL_ATTRIBUTE5 		
			,xol.FULFILLED_FLAG 			
			,xol.REQUEST_DATE 			
			,xol.SHIPPING_INSTRUCTIONS 		
			,xol.PACKING_INSTRUCTIONS 		
			,xol.SOLD_FROM_ORG 			
			,xol.CUSTOMER_ITEM_NAME 		
			,xol.SUBINVENTORY 			
			,xol.UNIT_LIST_PRICE_PER_PQTY 	
			,xol.UNIT_SELLING_PRICE_PER_PQTY 	
			,xol.PRICE_REQUEST_CODE 		
			,xol.ORIG_SHIP_ADDRESS_REF 		
			,xol.ORIG_BILL_ADDRESS_REF 		
			,xol.SHIP_TO_CUSTOMER_NUMBER 	
			,xol.INVOICE_TO_CUSTOMER_NUMBER 	
			,xol.DELIVER_TO_CUSTOMER_NUMBER 	
			,xol.ACCOUNTING_RULE_DURATION  	
			,xol.USER_ITEM_DESCRIPTION 		
			,xol.LINE_CATEGORY_CODE 
			,xol.TP_CONTEXT                 
			,xol.TP_ATTRIBUTE1              
			,xol.TP_ATTRIBUTE2              
			,xol.TP_ATTRIBUTE3              
			,xol.TP_ATTRIBUTE4              
			,xol.TP_ATTRIBUTE5              
                        ,xol.ORDERED_ITEM               
			,xol.SALES_REGION 			
			,xol.SALESMAN_NUMBER 		
			,xol.PROCESS_CODE 			
			,xol.ERROR_CODE 			
			,X_CREATED_BY		  
			,X_CREATION_DATE		  
			,X_LAST_UPDATE_DATE	  
			,X_LAST_UPDATED_BY	  
			,X_LAST_UPDATE_LOGIN		-- DO NOT CHANGE TO THIS LINE	
			,xol.REQUEST_ID 	
			,xol.RETURN_REASON_CODE   --Added on 28-FEB-2014
			FROM  XX_OE_ORDER_LINES_ALL_STG		xol	-- Order Lines Staging			     
                         WHERE 1=1
			   AND xol.BATCH_ID		 = G_LINE_BATCH_ID
			   AND xol.process_code		 = xx_emf_cn_pkg.CN_PREVAL
                           AND xol.request_id		 = xx_emf_pkg.G_REQUEST_ID
                           AND xol.error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)  ;

			  /* if sql%rowcount > 0 Then			      
			      fnd_file.put_line(fnd_file.log,'Line Level No Of Records Inserted : '||sql%rowcount);
			   end if;	*/		
		         COMMIT;                  
                        RETURN x_error_code;
                EXCEPTION
                        WHEN OTHERS THEN
                                xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
                                x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
                                RETURN x_error_code;
                END move_rec_pre_lines_table;
		 -------------------------------------------------------------------------
                 -----------< process_data >----------------------------------------------
                 -------------------------------------------------------------------------
		
		-- Header Level
		FUNCTION process_data
                RETURN NUMBER
                IS
                        x_return_status VARCHAR2(15) := xx_emf_cn_pkg.CN_SUCCESS;
			
			PRAGMA AUTONOMOUS_TRANSACTION;
                BEGIN
                        -- Change the logic to whatever needs to be done
                        -- with valid records in the pre-interface tables
                        -- either call the appropriate API to process the data
                        -- or to insert into an interface table

                        fnd_file.put_line(fnd_file.log,'Inserting into Standard Headers Iface....');

                        INSERT INTO OE_HEADERS_IFACE_ALL -- Standard Order Headers Interface Table
                        (ORIG_SYS_DOCUMENT_REF	,	
			 ORG_ID			,
			 ORDER_NUMBER		,
			 ORDERED_DATE		,
			 ORDER_TYPE_ID		,
			 ORDER_SOURCE_ID		,
			 PRICE_LIST_ID           ,
			 TRANSACTIONAL_CURR_CODE	,
			 SALESREP_ID		,
			 TAX_EXEMPT_FLAG		,
                         INVOICING_RULE_ID,
                         ACCOUNTING_RULE_ID,
			 PAYMENT_TERM_ID		,
			 SHIPPING_METHOD_CODE	,
			 --FREIGHT_TERMS_CODE	, --Commented by Samir on 19-Jul-2012
                         FREIGHT_TERMS          ,
			 --Added by Samir on 23-Jul-2012 STARTS
			 SALES_CHANNEL_CODE     ,
			 SHIPPING_INSTRUCTIONS  ,                   
			 PACKING_INSTRUCTIONS   ,
                         --Added by Samir on 23-Jul-2012 ENDS
                         SHIPMENT_PRIORITY_CODE , --Added on 21-JAN-13
                         --PARTIAL_SHIPMENTS_ALLOWED, --Added on 21-JAN-13
			 FOB_POINT_CODE		,
			 CUSTOMER_PO_NUMBER	,
			 SOLD_TO_ORG_ID		,
			 SHIP_FROM_ORG_ID	,
			 SHIP_TO_ORG_ID		,
			 INVOICE_TO_ORG_ID	,
			 DELIVER_TO_ORG_ID       ,
			 DELIVER_TO_CONTACT_ID  ,      --Added as per DCR 03-SEP-12
			 --CUSTOMER_NUMBER        ,          --Added to populate customer number  Modified as per Wave1
			 BOOKED_FLAG		,
			 CANCELLED_FLAG		,
			 CLOSED_FLAG		,
			 ORDER_CATEGORY		,
			 SOLD_FROM_ORG_ID	,
			 TP_CONTEXT              ,   
			 TP_ATTRIBUTE1           ,   
			 TP_ATTRIBUTE2           ,   
			 TP_ATTRIBUTE15          ,         --25-JUL-12 Added to populate batch_id
			 REQUEST_DATE            ,   --Added on 11-DEC-13 as per Wave1
			 --ORIG_SHIP_ADDRESS_REF	,
			 PRICING_DATE		,
			 TRANSACTION_PHASE_CODE	,
			 RETURN_REASON_CODE     ,   --Added on 28-FEB-2014
			 ATTRIBUTE1		,
			 ATTRIBUTE2		,
			 ATTRIBUTE3		,
			 ATTRIBUTE4		,
			 ATTRIBUTE5		,
			 ATTRIBUTE6		,
			 ATTRIBUTE7		,
			 ATTRIBUTE8		,
			 ATTRIBUTE9		,
			 ATTRIBUTE10		,
			 ATTRIBUTE11		,
			 ATTRIBUTE12		,
			 ATTRIBUTE13		,
			 ATTRIBUTE14		,
			 ATTRIBUTE15		,
			 ATTRIBUTE16		,
			 ATTRIBUTE17		,
			 ATTRIBUTE18		,
			 ATTRIBUTE19		,
			 ATTRIBUTE20		,
			 OPERATION_CODE		,
			 CREATED_BY		,
			 CREATION_DATE		,
			 LAST_UPDATE_DATE	,
			 LAST_UPDATED_BY		,
			 LAST_UPDATE_LOGIN     )
                    SELECT ORIG_SYS_DOCUMENT_REF	,
			   ORG_ID			,
			   ORDER_NUMBER		,
			   ORDERED_DATE		,
			   ORDER_TYPE_ID		,
			   ORDER_SOURCE_ID		,
			   PRICE_LIST_ID           ,
			   TRANSACTIONAL_CURR_CODE	,
			   SALESREP_ID		,
			   TAX_EXEMPT_FLAG		,
                           INVOICING_RULE_ID,
                           ACCOUNTING_RULE_ID,
			   PAYMENT_TERM_ID		,
			   SHIPPING_METHOD_CODE	,
			   FREIGHT_TERMS_CODE	,
			   --Added by Samir on 23-Jul-2012 STARTS
			   SALES_CHANNEL_CODE     ,
			   SHIPPING_INSTRUCTIONS  ,                   
			   PACKING_INSTRUCTIONS   ,
                           --Added by Samir on 23-Jul-2012 ENDS
                           SHIPMENT_PRIORITY_CODE,            --Added on 21-JAN-13
                           --UPPER(PARTIAL_SHIPMENTS_ALLOWED),  --Added on 21-JAN-13
			   FOB_POINT_CODE		,
			   CUSTOMER_PO_NUMBER	,
			   SOLD_TO_ORG_ID		,
			   SHIP_FROM_ORG_ID	,
			   SHIP_TO_ORG_ID		,
			   INVOICE_TO_ORG_ID	,
			   DELIVER_TO_ORG_ID       ,
			   DELIVER_TO_CONTACT_ID  ,  --Added as per DCR to populate delvr to contact id 03-SEP-12
			   --CUSTOMER_NUMBER        ,          --Added to populate customer number Modified as per Wave1
			   BOOKED_FLAG,  --NULL, --BOOKED_FLAG	, --DINESH 17 Jul  21-SEP-13 Modified as per Wave1
			   CANCELLED_FLAG		,
			   CLOSED_FLAG		,
			   ORDER_CATEGORY		,
			   SOLD_FROM_ORG_ID	,
			   G_TP_CONTEXT         ,  --'SHIPPING', --TP_CONTEXT, 14-AUG-12 added value as per FS change
			   --Modifed as per Wave1 Start
				TP_ATTRIBUTE1,   --ATTRIBUTE2      , --TP_ATTRIBUTE1, 14-AUG-12 Modified as per FS change
				TP_ATTRIBUTE2,  --NULL            , --TP_ATTRIBUTE2 , 14-AUG-12 Modified as per FS change
				BATCH_ID                ,  --25-JUL-12 Added to populate batch_id
				REQUEST_DATE,  --Added on 11-DEC-13 Wave1
				--ORIG_SHIP_ADDRESS_REF	,
				PRICING_DATE		,
				TRANSACTION_PHASE_CODE	,
				RETURN_REASON_CODE      ,  --Added on 28-FEB-2014
				ATTRIBUTE1,  --NULL                    ,  --BATCH_ID , 25-JUL-12 Commented to populated batch_id in tp_attr15				
				ATTRIBUTE2,  --                    ,  --09-AUG-12 Modified insert to inert null for attr1 to attr20
				ATTRIBUTE3,  --                    ,
				ATTRIBUTE4,  --                    ,
				ATTRIBUTE5,  --                    ,
				ATTRIBUTE6,  --                    ,
				ATTRIBUTE7,  --                    ,
				ATTRIBUTE8,  --                    ,
				ATTRIBUTE9,  --                    ,
				DECODE(ATTRIBUTE10,'Y','Yes','N','No',ATTRIBUTE10) ,  --Added as per TDR 30-OCT-12 to fix err value does not exist in value set INTG_YES_NO
				NULL,  --                    ,
				NULL,  --                    ,
				NULL,  --                    ,
				NULL,  --                    ,
				NULL,  --                    ,
				NULL,  --                    ,
				NULL,  --		,
				NULL,  --                    ,
				NULL,  --                    ,
			        NULL,  --                    ,	
			   --Modifed as per Wave1 End
				'INSERT'		,	-- OPERATION_CODE
				--INVENTORY_ITEM_ID	,
				--BATCH_ID		,
				--STATUS			,
				--RECORD_NUMBER		,
				--PROCESS_CODE		,
				--ERROR_CODE		,
				--REQUEST_ID		,
				CREATED_BY		,
				CREATION_DATE		,
				LAST_UPDATE_DATE	,
				LAST_UPDATED_BY		,
				LAST_UPDATE_LOGIN  
			 FROM XX_OE_ORDER_HEADERS_ALL_PRE
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                           AND process_code = xx_emf_cn_pkg.CN_POSTVAL
                           AND EXISTS ( SELECT 1
			                  FROM XX_OE_ORDER_LINES_ALL_PRE ool
					 WHERE ool.batch_id = G_BATCH_ID
					   AND ool.process_code = xx_emf_cn_pkg.CN_POSTVAL
					   AND ool.error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
					   AND ool.ORIG_SYS_DOCUMENT_REF=ORIG_SYS_DOCUMENT_REF )    --Added on 03-FEB-2014 to check atleast one line exists
                          ;
			 /*  if sql%rowcount = 0 Then			      
			      fnd_file.put_line(fnd_file.log,'Failed to Insert into Standard Headers Iface !!');
			   else
			      fnd_file.put_line(fnd_file.log,'Inserted records into Standard Headers Iface !!');
			   end if;*/

			COMMIT;

                        RETURN x_return_status;
                EXCEPTION
                        WHEN OTHERS THEN
                                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while inserting into Interface Table: ' ||SQLERRM);
                                xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
                                x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
                                RETURN x_error_code;
                                                
                END process_data;

		-- Actions Level
		FUNCTION process_actions_data
                RETURN NUMBER
                IS
                        x_return_status VARCHAR2(15) := xx_emf_cn_pkg.CN_SUCCESS;
			
			PRAGMA AUTONOMOUS_TRANSACTION;
                BEGIN
                        -- Change the logic to whatever needs to be done
                        -- with valid records in the pre-interface tables
                        -- either call the appropriate API to process the data
                        -- or to insert into an interface table

                        fnd_file.put_line(fnd_file.log,'Inserting into OE Actions Iface....');

                        INSERT INTO OE_ACTIONS_IFACE_ALL	-- Standard Order Actions Interface Table
                        (	ORIG_SYS_DOCUMENT_REF	,
				ORDER_SOURCE_ID		,
				ORG_ID			,
				HOLD_TYPE_CODE		,
				HOLD_TYPE_ID		,
                                HOLD_ID			,
				OPERATION_CODE
				)
                        SELECT	
  				ORIG_SYS_DOCUMENT_REF	,
				ORDER_SOURCE_ID		,
				ORG_ID			,
				'O'			,  -- Order Hold Source
				CUSTOMER_NUMBER   ,  -- HOLD_TYPE_ID depends on value you populate in HOLD_TYPE_CODE
				HOLD_ID		        ,  -- HOLD_ID
				'APPLY_HOLD'
			 FROM XX_OE_ORDER_HEADERS_ALL_PRE
                         WHERE batch_id        = G_BATCH_ID
                           AND request_id      = xx_emf_pkg.G_REQUEST_ID
                           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                           AND process_code    = xx_emf_cn_pkg.CN_POSTVAL
			   AND hold_type_code  = '20';

			  /* if sql%rowcount = 0 Then
			      fnd_file.put_line(fnd_file.log,'Failed to Insert into OE Actions Iface !!');			      
			   else
			      fnd_file.put_line(fnd_file.log,'Inserted records into OE Actions Iface !!');
			   end if;*/

			COMMIT;

                        RETURN x_return_status;
                EXCEPTION
                        WHEN OTHERS THEN
                                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while inserting into Actions Interface Table: ' ||SQLERRM);
                                xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
                                x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
                                RETURN x_error_code;
                                                
                END process_actions_data;
      FUNCTION cust_add_creation
      RETURN NUMBER
      IS
         x_return_status VARCHAR2(15) := xx_emf_cn_pkg.CN_SUCCESS;
         x_cust_account_id               NUMBER;
	 x_return_status1                VARCHAR2 (2000);
	 x_msg_count                     NUMBER;
	 x_msg_data                      VARCHAR2 (2000);
	 x_msg                           VARCHAR2(2000);
	 x_msg_index_out                 NUMBER;

	 x_module			 VARCHAR2(100)	:= 'ONT_OI_ADD_CUSTOMER';
	 
	 x_location_rec                  hz_location_v2pub.location_rec_type;
	 x_location_id                   NUMBER;
	 x_party_site_rec                hz_party_site_v2pub.party_site_rec_type;
	 x_party_site_id                 NUMBER;
	 x_party_site_number             VARCHAR2(2000);
	 x_cust_acct_site_rec            hz_cust_account_site_v2pub.cust_acct_site_rec_type;
	 x_cust_acct_site_id             NUMBER;
	 x_cust_site_use_rec             hz_cust_account_site_v2pub.cust_site_use_rec_type;
	 x_site_use_id                   NUMBER;
	 x_customer_profile_rec1         hz_customer_profile_v2pub.customer_profile_rec_type;
	 x_record_skip                   EXCEPTION;
         x_country_code                  fnd_territories.territory_code%TYPE;
    CURSOR xx_add_cur
    IS
    SELECT *
    FROM XX_OE_ORDER_HEADERS_ALL_PRE
    WHERE error_code IN (xx_emf_cn_pkg.CN_SUCCESS,xx_emf_cn_pkg.CN_REC_WARN)
    AND batch_id     = G_BATCH_ID
    AND deliver_to_address1 IS NOT NULL  --14-AUG-12 added to check for null value
    AND deliver_to_country IS NOT NULL   
    AND order_type != G_RMA_ORDER_TYPE   --deliver to addr is null for return orders
   ;   
    
     BEGIN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Inside cust_add_creation');
         -- Change the logic to whatever needs to be done
         -- with valid records in the pre-interface tables
         -- either call the appropriate API to process the data
         -- or to insert into an interface table.
		x_location_rec.country               := NULL;
		x_location_rec.address1              := NULL;
		x_location_rec.address2              := NULL;
		x_location_rec.address3              := NULL;
		x_location_rec.address4              := NULL;
		x_location_rec.county                := NULL;
		x_location_rec.city                  := NULL;
		x_location_rec.postal_code           := NULL;
		x_location_rec.state                 := NULL;
		x_location_rec.province              := NULL;


       FOR xx_add_rec IN xx_add_cur
       LOOP
       BEGIN
         BEGIN
	     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Validate Deliver to Country : Header : ' || xx_add_rec.orig_sys_document_ref);
	    SELECT territory_code
	      INTO x_country_code
	      FROM fnd_territories
	     WHERE UPPER(nls_territory)=UPPER(xx_add_rec.deliver_to_country)
	        OR UPPER(iso_territory_code)=UPPER(xx_add_rec.deliver_to_country)
	        OR UPPER(territory_code)=UPPER(xx_add_rec.deliver_to_country)  --Added as per Wave1
	    ;
	 EXCEPTION
	    WHEN OTHERS THEN
	      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Invalid Deliver to Country =>' ||xx_add_rec.deliver_to_country);
	      --Added to deliver to org issue 09-AUG-12 
	      x_error_code := xx_emf_cn_pkg.cn_rec_err;
	      xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
	                       ,p_category   => xx_emf_cn_pkg.cn_valid
	      	 	       ,p_error_text => 'Invalid Deliver to Country =>' || xx_add_rec.deliver_to_country
	                       ,p_record_identifier_1 => xx_add_rec.record_number
	                       ,p_record_identifier_2 =>  xx_add_rec.orig_sys_document_ref
	                       );
	      
	      UPDATE XX_OE_ORDER_HEADERS_ALL_PRE
	         SET error_code     = xx_emf_cn_pkg.CN_REC_ERR
	       WHERE batch_id     = G_BATCH_ID
	         AND record_number	= xx_add_rec.record_number
	         AND orig_sys_document_ref   = xx_add_rec.orig_sys_document_ref;
             COMMIT;
              RAISE x_record_skip;
	 END;
	 x_site_use_id := NULL;
	 --Check for deliver to site use
         BEGIN
	    SELECT hcsu.site_use_id
	      INTO x_site_use_id
              FROM hz_cust_accounts hca,
                   hz_party_sites hps,
                   hz_cust_acct_sites_all hcas,
                   hz_cust_site_uses_all hcsu,
                   hz_locations hl
             WHERE hca.party_id=hps.party_id
               AND hps.location_id=hl.location_id
               AND hcas.cust_account_id=hca.cust_account_id
               AND hcas.party_site_id=hps.party_site_id
               AND hcsu.cust_acct_site_id=hcas.cust_acct_site_id
               AND hcsu.site_use_code='DELIVER_TO'
	       AND hcsu.status='A'
	       AND hca.status='A'
	       AND hcas.status='A'
	       AND hps.status='A'
               AND hcas.org_id=hcsu.org_id
               AND UPPER(hl.address1)=UPPER(xx_add_rec.deliver_to_address1)
               AND ((hl.address2 IS NULL AND xx_add_rec.deliver_to_address2 IS NULL )OR (UPPER(hl.address2)=UPPER(xx_add_rec.deliver_to_address2)))
               AND ((hl.address3 IS NULL AND xx_add_rec.deliver_to_address3 IS NULL )OR (UPPER(hl.address3)=UPPER(xx_add_rec.deliver_to_address3)))
               AND ((hl.address4 IS NULL AND xx_add_rec.deliver_to_address4 IS NULL )OR (UPPER(hl.address4)=UPPER(xx_add_rec.deliver_to_address4)))
               --Modified to fix duplicate delivery site creation 26-OCT-12
               --AND UPPER(hl.city)=UPPER(xx_add_rec.deliver_to_city)
	       --AND UPPER(hl.state)=UPPER(xx_add_rec.deliver_to_state)
               --AND UPPER(hl.postal_code)=UPPER(xx_add_rec.deliver_to_postal_code)
               AND ((hl.city IS NULL AND xx_add_rec.deliver_to_city IS NULL) OR (UPPER(hl.city)=UPPER(xx_add_rec.deliver_to_city)))
               AND ( ((hl.state IS NULL AND xx_add_rec.deliver_to_state IS NULL) OR (UPPER(hl.state)=UPPER(xx_add_rec.deliver_to_state)))
		      OR
		     ((hl.province IS NULL AND xx_add_rec.deliver_to_province IS NULL) OR (UPPER(hl.province)=UPPER(xx_add_rec.deliver_to_province)))
                   )
               AND ((hl.postal_code IS NULL AND xx_add_rec.deliver_to_postal_code IS NULL) OR (UPPER(hl.postal_code)=UPPER(xx_add_rec.deliver_to_postal_code)))               
               --End for changes
	       AND ((hl.county IS NULL AND xx_add_rec.deliver_to_county IS NULL )OR (UPPER(hl.county)=UPPER(xx_add_rec.deliver_to_county)))
	       AND UPPER(hl.country)=UPPER(x_country_code)
	       AND hca.cust_account_id=xx_add_rec.sold_to_org_id
	       AND hcsu.org_id=xx_add_rec.org_id
	       AND ROWNUM = 1;
	 EXCEPTION
	    WHEN OTHERS THEN
	      x_site_use_id := NULL;
	 END;
	 IF x_site_use_id IS NULL 
	 THEN
	    x_cust_acct_site_id := NULL;
	    --Check for cust site exists 10-DEC-12
	    BEGIN
               SELECT hcas.cust_acct_site_id
	         INTO x_cust_acct_site_id 
                 FROM hz_cust_accounts hca,
                      hz_party_sites hps,
                      hz_cust_acct_sites_all hcas,                    
                      hz_locations hl
                WHERE hca.party_id=hps.party_id
                 AND hps.location_id=hl.location_id
                 AND hcas.cust_account_id=hca.cust_account_id
                 AND hcas.party_site_id=hps.party_site_id
	         AND hca.status='A'
	         AND hcas.status='A'
	         AND hps.status='A'
                 AND UPPER(hl.address1)=UPPER(xx_add_rec.deliver_to_address1)
                 AND ((hl.address2 IS NULL AND xx_add_rec.deliver_to_address2 IS NULL )OR (UPPER(hl.address2)=UPPER(xx_add_rec.deliver_to_address2)))
                 AND ((hl.address3 IS NULL AND xx_add_rec.deliver_to_address3 IS NULL )OR (UPPER(hl.address3)=UPPER(xx_add_rec.deliver_to_address3)))
                 AND ((hl.address4 IS NULL AND xx_add_rec.deliver_to_address4 IS NULL )OR (UPPER(hl.address4)=UPPER(xx_add_rec.deliver_to_address4)))
                 AND ((hl.city IS NULL AND xx_add_rec.deliver_to_city IS NULL) OR (UPPER(hl.city)=UPPER(xx_add_rec.deliver_to_city)))
                 AND ( ((hl.state IS NULL AND xx_add_rec.deliver_to_state IS NULL) OR (UPPER(hl.state)=UPPER(xx_add_rec.deliver_to_state)))
		         OR
		        ((hl.province IS NULL AND xx_add_rec.deliver_to_province IS NULL) OR (UPPER(hl.province)=UPPER(xx_add_rec.deliver_to_province)))
                      )                 
                 AND ((hl.postal_code IS NULL AND xx_add_rec.deliver_to_postal_code IS NULL) OR (UPPER(hl.postal_code)=UPPER(xx_add_rec.deliver_to_postal_code)))                 
	         AND ((hl.county IS NULL AND xx_add_rec.deliver_to_county IS NULL )OR (UPPER(hl.county)=UPPER(xx_add_rec.deliver_to_county)))
	         AND UPPER(hl.country)=UPPER(x_country_code)
	         AND hca.cust_account_id=xx_add_rec.sold_to_org_id	       
	         AND hcas.org_id=xx_add_rec.org_id
	         AND ROWNUM = 1;
	    EXCEPTION
	    WHEN OTHERS THEN	       
	       x_cust_acct_site_id := NULL;
	    END;
	    mo_global.init('AR');
	    mo_global.set_policy_context('S',xx_add_rec.org_id);
	    --If Adrees not exists then create address 10-DEC-12
	    IF x_cust_acct_site_id IS NULL THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Address / Site Creation : Header : ' || xx_add_rec.orig_sys_document_ref);
               --fnd_client_info.set_org_context (xx_add_rec.org_id);		
		x_party_site_id := NULL;
		--Check for Party site 10-DEC-12
		BEGIN
		   SELECT hps.party_site_id
		     INTO x_party_site_id 
		     FROM hz_cust_accounts hca,
		          hz_party_sites hps,                                       
		          hz_locations hl
		    WHERE hca.party_id=hps.party_id
		      AND hps.location_id=hl.location_id                                  
		      AND hca.status='A'	         
		      AND hps.status='A'
		      AND UPPER(hl.address1)=UPPER(xx_add_rec.deliver_to_address1)
		      AND ((hl.address2 IS NULL AND xx_add_rec.deliver_to_address2 IS NULL )OR (UPPER(hl.address2)=UPPER(xx_add_rec.deliver_to_address2)))
		      AND ((hl.address3 IS NULL AND xx_add_rec.deliver_to_address3 IS NULL )OR (UPPER(hl.address3)=UPPER(xx_add_rec.deliver_to_address3)))
		      AND ((hl.address4 IS NULL AND xx_add_rec.deliver_to_address4 IS NULL )OR (UPPER(hl.address4)=UPPER(xx_add_rec.deliver_to_address4)))
		      AND ((hl.city IS NULL AND xx_add_rec.deliver_to_city IS NULL) OR (UPPER(hl.city)=UPPER(xx_add_rec.deliver_to_city)))
                      AND ( ((hl.state IS NULL AND xx_add_rec.deliver_to_state IS NULL) OR (UPPER(hl.state)=UPPER(xx_add_rec.deliver_to_state)))
		              OR
		            ((hl.province IS NULL AND xx_add_rec.deliver_to_province IS NULL) OR (UPPER(hl.province)=UPPER(xx_add_rec.deliver_to_province)))
                          )		      
		      AND ((hl.postal_code IS NULL AND xx_add_rec.deliver_to_postal_code IS NULL) OR (UPPER(hl.postal_code)=UPPER(xx_add_rec.deliver_to_postal_code)))		      
		      AND ((hl.county IS NULL AND xx_add_rec.deliver_to_county IS NULL )OR (UPPER(hl.county)=UPPER(xx_add_rec.deliver_to_county)))
		      AND UPPER(hl.country)=UPPER(x_country_code)
	              AND hca.cust_account_id=xx_add_rec.sold_to_org_id
	              AND ROWNUM = 1;
		EXCEPTION
                   WHEN OTHERS THEN	       
	              x_party_site_id := NULL;
		END;
		IF x_party_site_id IS NULL THEN
		   x_location_id := NULL;
		   --Check for location exists 10-DEC-12
		   BEGIN
		      SELECT hl.location_id
		      	INTO x_location_id 
		        FROM hz_locations hl
		       WHERE 1=1
		         AND UPPER(hl.address1)=UPPER(xx_add_rec.deliver_to_address1)
		         AND ((hl.address2 IS NULL AND xx_add_rec.deliver_to_address2 IS NULL )OR (UPPER(hl.address2)=UPPER(xx_add_rec.deliver_to_address2)))
		         AND ((hl.address3 IS NULL AND xx_add_rec.deliver_to_address3 IS NULL )OR (UPPER(hl.address3)=UPPER(xx_add_rec.deliver_to_address3)))
		         AND ((hl.address4 IS NULL AND xx_add_rec.deliver_to_address4 IS NULL )OR (UPPER(hl.address4)=UPPER(xx_add_rec.deliver_to_address4)))
		         AND ((hl.city IS NULL AND xx_add_rec.deliver_to_city IS NULL) OR (UPPER(hl.city)=UPPER(xx_add_rec.deliver_to_city)))
                         AND ( ((hl.state IS NULL AND xx_add_rec.deliver_to_state IS NULL) OR (UPPER(hl.state)=UPPER(xx_add_rec.deliver_to_state)))
                 	      OR
		             ((hl.province IS NULL AND xx_add_rec.deliver_to_province IS NULL) OR (UPPER(hl.province)=UPPER(xx_add_rec.deliver_to_province)))
                              )		      		         
		         AND ((hl.postal_code IS NULL AND xx_add_rec.deliver_to_postal_code IS NULL) OR (UPPER(hl.postal_code)=UPPER(xx_add_rec.deliver_to_postal_code)))		         
		      	 AND ((hl.county IS NULL AND xx_add_rec.deliver_to_county IS NULL )OR (UPPER(hl.county)=UPPER(xx_add_rec.deliver_to_county)))
	                 AND UPPER(hl.country)=UPPER(x_country_code)
	                 AND ROWNUM = 1;
		   EXCEPTION
                   WHEN OTHERS THEN	       
	              x_location_id := NULL;		   
		   END;
		   IF x_location_id IS NULL THEN
                        --Create Location		      		   
			x_location_rec.address1              := xx_add_rec.deliver_to_address1;
			x_location_rec.address2              := xx_add_rec.deliver_to_address2;
			x_location_rec.address3              := xx_add_rec.deliver_to_address3;
			x_location_rec.address4              := xx_add_rec.deliver_to_address4;
			x_location_rec.county                := xx_add_rec.deliver_to_county;
			x_location_rec.city                  := xx_add_rec.deliver_to_city;
			x_location_rec.postal_code           := xx_add_rec.deliver_to_postal_code;
			x_location_rec.state                 := xx_add_rec.deliver_to_state;
			x_location_rec.province              := xx_add_rec.deliver_to_province;
			x_location_rec.country               := x_country_code;
			x_location_rec.created_by_module     := x_module;
			fnd_file.put_line(fnd_file.log,' xx_add_rec.deliver_to_address1    : '|| x_location_rec.address1);
			fnd_file.put_line(fnd_file.log,' xx_add_rec.deliver_to_address2    : '|| x_location_rec.address2);
			fnd_file.put_line(fnd_file.log,' xx_add_rec.deliver_to_address3    : '|| x_location_rec.address3);
			fnd_file.put_line(fnd_file.log,' xx_add_rec.ship_to_country     : '|| x_country_code);
			fnd_file.put_line(fnd_file.log,' xx_add_rec.ship_to_city        : '|| x_location_rec.city);
			fnd_file.put_line(fnd_file.log,' xx_add_rec.ship_to_province    : '|| xx_add_rec.ship_to_province);
			fnd_file.put_line(fnd_file.log,' xx_add_rec.ship_to_state       : '|| x_location_rec.state);
			fnd_file.put_line(fnd_file.log,' xx_add_rec.ship_to_postal_code : '|| x_location_rec.postal_code);
			xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'Before calling hz_location_v2pub.create_location ');
			hz_location_v2pub.create_location ('T',
							    x_location_rec,
							    x_location_id,
							    x_return_status,
							    x_msg_count,
							    x_msg_data
							     );
			xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'After calling hz_location_v2pub.create_location ');
			fnd_file.put_line(fnd_file.log,' New Location Id : '|| x_location_id);
			IF x_return_status !=  fnd_api.G_RET_STS_SUCCESS THEN
			  x_msg := NULL;
			  FOR I IN 1..x_msg_count 
			  LOOP
			    fnd_msg_pub.get(p_msg_index     => i
					    ,p_encoded       => 'F'
					    ,p_data          => x_msg_data
					    ,p_msg_index_out => x_msg_index_out);


			    x_msg := x_msg ||  x_msg_data;		  
			  END LOOP;
			  x_error_code := xx_emf_cn_pkg.cn_rec_err;
			  xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
							 ,p_category   => xx_emf_cn_pkg.cn_valid
							 ,p_error_text => 'After  hz_location_v2pub.create_location ' || x_msg || ' '|| xx_add_rec.sold_to_org
							 ,p_record_identifier_1 => xx_add_rec.sold_to_org 
							 ,p_record_identifier_2 => xx_add_rec.sold_to_org
							);
			  ROLLBACK; 

			  UPDATE XX_OE_ORDER_HEADERS_ALL_PRE
			  SET error_code     = xx_emf_cn_pkg.CN_REC_ERR
			  WHERE batch_id     = G_BATCH_ID
			    AND record_number	= xx_add_rec.record_number
			    AND orig_sys_document_ref   = xx_add_rec.orig_sys_document_ref;
			  COMMIT;
			  RAISE x_record_skip;

			END IF; -- location creation not successful  
                   END IF; --End for location null check
                   
		   --Party Site Creation
	           xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'Create_party_site ');
	           x_party_site_rec.location_id              := x_location_id;
		   x_party_site_rec.party_id                 := xx_add_rec.new_party_id;
		   x_party_site_rec.identifying_address_flag := 'N';  --'Y';
		   x_party_site_rec.orig_system_reference    := xx_add_rec.sold_to_org || '-' ||substr(xx_add_rec.sold_to_org,instr(xx_add_rec.sold_to_org,'-')+1);	 
		   x_party_site_rec.created_by_module        := x_module;
		   xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'Before calling hz_party_site_v2pub.create_party_site ');
		   hz_party_site_v2pub.create_party_site ('T',
								x_party_site_rec,
								x_party_site_id,
								x_party_site_number,
								x_return_status,
								x_msg_count,
								x_msg_data
							       );
	           xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'After hz_party_site_v2pub.create_party_site ');
		   fnd_file.put_line(fnd_file.log,' New Party Site Id : '|| x_party_site_id);
		   IF x_return_status !=  fnd_api.G_RET_STS_SUCCESS THEN
		      x_msg := NULL;
		      FOR I IN 1..x_msg_count 
		      LOOP
		         fnd_msg_pub.get(p_msg_index     => i
		    		     ,p_encoded       => 'F'
				     ,p_data          => x_msg_data
				     ,p_msg_index_out => x_msg_index_out);

		         x_msg := x_msg ||  x_msg_data;		  
		      END LOOP;
		      x_error_code := xx_emf_cn_pkg.cn_rec_err;
		      xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
					    ,p_category   => xx_emf_cn_pkg.cn_valid
					    ,p_error_text => x_msg||xx_add_rec.sold_to_org
					    ,p_record_identifier_1 => xx_add_rec.sold_to_org 
					    ,p_record_identifier_2 => xx_add_rec.sold_to_org
					    );
		      ROLLBACK; 	
		      UPDATE XX_OE_ORDER_HEADERS_ALL_PRE
			 SET error_code     = xx_emf_cn_pkg.CN_REC_ERR
		       WHERE batch_id     = G_BATCH_ID
			 AND record_number	= xx_add_rec.record_number
			 AND orig_sys_document_ref   = xx_add_rec.orig_sys_document_ref;
		       COMMIT;
		      RAISE x_record_skip;
	           END IF; -- Party site not successful
	        END IF;  --End if for party site null check
	        
		 -- Cust Acct Site creation
		fnd_file.put_line(fnd_file.log,' Starting Cust Acct Site Creation .. ');

		fnd_file.put_line(fnd_file.log,'  xx_add_rec.sold_to_org_id : '|| xx_add_rec.sold_to_org_id);

		x_cust_acct_site_rec.cust_account_id       := xx_add_rec.sold_to_org_id;
		x_cust_acct_site_rec.party_site_id         := x_party_site_id;
		x_cust_acct_site_rec.orig_system_reference := xx_add_rec.sold_to_org || '-' ||xx_add_rec.orig_sys_document_ref;	 
		x_cust_acct_site_rec.created_by_module     := x_module;
		xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'Before calling hz_cust_account_site_v2pub.create_cust_acct_site ');
		hz_cust_account_site_v2pub.create_cust_acct_site('T',
								  x_cust_acct_site_rec,
								  x_cust_acct_site_id,
								  x_return_status,
								  x_msg_count,
								  x_msg_data
								 );

		 xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'After calling hz_cust_account_site_v2pub.create_cust_acct_site ');

		 fnd_file.put_line(fnd_file.log,' New x_cust_acct_site_id : '|| x_cust_acct_site_id);

		 IF x_return_status !=  fnd_api.G_RET_STS_SUCCESS THEN
		   x_msg := NULL;

		   fnd_file.put_line(fnd_file.log,' Error While running Cust Acct Site Creation ..');

		   FOR I IN 1..x_msg_count 
		   LOOP
		     fnd_msg_pub.get(p_msg_index     => i
				    ,p_encoded       => 'F'
				    ,p_data          => x_msg_data
				    ,p_msg_index_out => x_msg_index_out);


		     x_msg := x_msg ||  x_msg_data;		  
		   END LOOP;
		   x_error_code := xx_emf_cn_pkg.cn_rec_err;
		   xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
						 ,p_category   => xx_emf_cn_pkg.cn_valid
						 ,p_error_text => 'After hz_cust_account_site_v2pub.create_cust_acct_site ' ||x_msg || ' '|| xx_add_rec.sold_to_org
						 ,p_record_identifier_1 => xx_add_rec.sold_to_org 
						 ,p_record_identifier_2 => xx_add_rec.sold_to_org
						);
		   ROLLBACK; 
		   UPDATE XX_OE_ORDER_HEADERS_ALL_PRE
		   SET error_code     = xx_emf_cn_pkg.CN_REC_ERR
		   WHERE batch_id     = G_BATCH_ID
		   AND record_number	= xx_add_rec.record_number
		   AND orig_sys_document_ref   = xx_add_rec.orig_sys_document_ref;
		   COMMIT;
		   RAISE x_record_skip;
		   --xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Running ');           

		 END IF; -- Account site not successful
              END IF;  --End if for cust site null check
            --Cust Site Use Creation              
	    fnd_file.put_line(fnd_file.log,' Starting Cust Acct Site Usage Creation .. ');
	    x_cust_site_use_rec.cust_acct_site_id      := x_cust_acct_site_id;
	    x_cust_site_use_rec.site_use_code          := 'DELIVER_TO';
	    x_cust_site_use_rec.orig_system_reference  := xx_add_rec.sold_to_org || '-' ||xx_add_rec.orig_sys_document_ref;
	    x_cust_site_use_rec.created_by_module	   := x_module;	 
	         
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'Before calling hz_cust_account_site_v2pub.create_cust_site_use ');
            hz_cust_account_site_v2pub.create_cust_site_use('T',
	                                                 x_cust_site_use_rec,
	                                                 x_customer_profile_rec1,
	                                                 '',
	                                                 '',
	                                                 x_site_use_id,
	                                                 x_return_status,
	                                                 x_msg_count,
	                                                 x_msg_data
	                                                );
	    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'After calling hz_cust_account_site_v2pub.create_cust_site_use ');                                               

	    fnd_file.put_line(fnd_file.log,' New x_site_use_id : '|| x_site_use_id);
            
	    IF x_return_status !=  fnd_api.G_RET_STS_SUCCESS THEN
	       x_msg := NULL;
	       FOR I IN 1..x_msg_count 
	       LOOP
	         fnd_msg_pub.get(p_msg_index     => i
	       		    ,p_encoded       => 'F'
			    ,p_data          => x_msg_data
			    ,p_msg_index_out => x_msg_index_out);


	         x_msg := x_msg ||  x_msg_data;		  
	       END LOOP;
	       x_error_code := xx_emf_cn_pkg.cn_rec_err;
	       xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
	  		    ,p_category   => xx_emf_cn_pkg.cn_valid
			    ,p_error_text => x_msg||'CUSTOMER NO :' || xx_add_rec.sold_to_org  || 'SHIP_TO_ORG ' || xx_add_rec.ship_to_org 
			    ,p_record_identifier_1 => xx_add_rec.sold_to_org 
			    ,p_record_identifier_2 => xx_add_rec.ship_to_org
			    );
	       ROLLBACK;
	      UPDATE XX_OE_ORDER_HEADERS_ALL_PRE
	         SET error_code     = xx_emf_cn_pkg.CN_REC_ERR
	       WHERE batch_id     = G_BATCH_ID
	         AND record_number	= xx_add_rec.record_number
	         AND orig_sys_document_ref   = xx_add_rec.orig_sys_document_ref;
	      COMMIT;
	      RAISE x_record_skip;
	    END IF; -- Account site uses not successful
	    UPDATE XX_OE_ORDER_HEADERS_ALL_PRE
	       SET error_code         = xx_emf_cn_pkg.CN_SUCCESS
	     WHERE batch_id         = G_BATCH_ID
               AND record_number	= xx_add_rec.record_number;
            COMMIT;
       END IF;
       BEGIN
         UPDATE XX_OE_ORDER_HEADERS_ALL_PRE
	         set deliver_to_org_id = x_site_use_id 
	      WHERE orig_sys_document_ref = xx_add_rec.orig_sys_document_ref;
	  COMMIT;
	 EXCEPTION
            WHEN OTHERS THEN
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Header : '||xx_add_rec.orig_sys_document_ref||' Error While Fetching Site use ID ');
                xx_emf_pkg.error (p_severity        =>   xx_emf_cn_pkg.CN_HIGH
                             ,p_category            =>   xx_emf_cn_pkg.CN_TECH_ERROR
                             ,p_error_text          =>   sqlerrm 
                             ,p_record_identifier_3 =>   'Process create Address'
                             );
            RETURN x_error_code;
	 END;      
       EXCEPTION
         WHEN x_record_skip THEN
           NULL;
       END;  
       END LOOP;
          
     RETURN xx_emf_cn_pkg.CN_SUCCESS;
     EXCEPTION
          WHEN OTHERS THEN
            
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Running 1 ');
            xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.CN_HIGH
                             ,p_category            =>   xx_emf_cn_pkg.CN_TECH_ERROR
                             ,p_error_text          =>   sqlerrm 
                             ,p_record_identifier_3 =>   'Process create Address'
                             );
            RETURN x_error_code;
     END cust_add_creation;
--Added as per DCR 03-SEP-12
FUNCTION cust_contact_creation
RETURN NUMBER
IS
   x_return_status VARCHAR2(15) := xx_emf_cn_pkg.CN_SUCCESS;         
   x_msg_count                     NUMBER;
   x_msg_data                      VARCHAR2 (2000);
   x_msg                           VARCHAR2(2000);
   x_msg_index_out                 NUMBER;
   x_module             VARCHAR2(100)    := 'ONT_OI_ADD_CUSTOMER';     
   x_create_person_rec   hz_party_v2pub.person_rec_type;
   x_org_contact_rec  hz_party_contact_v2pub.org_contact_rec_type;
   x_cr_cust_acc_role_rec   hz_cust_account_role_v2pub.cust_account_role_rec_type;
   x_del_contact_id     NUMBER;
   l_cust_acct_id               NUMBER;
   l_cust_party_id NUMBER;
   l_party_id        NUMBER;
   l_party_number    VARCHAR2 (2000);
   l_profile_id      NUMBER;
   l_return_status   VARCHAR2 (2000);
   l_msg_count       NUMBER;
   l_msg_data        VARCHAR2 (2000);          
   lr_party_rel_id     NUMBER;
   lr_org_contact_id   NUMBER;
   lr_party_id         NUMBER;
   lr_party_number     VARCHAR2 (2000);                           
   l_cust_account_role_id   NUMBER;    
   x_record_skip                   EXCEPTION;
   l_cust_acct_site_id  NUMBER;
    CURSOR xx_contact_cur
    IS
    SELECT *
    FROM XX_OE_ORDER_HEADERS_ALL_PRE
    WHERE error_code IN (xx_emf_cn_pkg.CN_SUCCESS,xx_emf_cn_pkg.CN_REC_WARN)
    AND batch_id     = G_BATCH_ID
    AND deliver_to_contact IS NOT NULL       
    AND order_type != G_RMA_ORDER_TYPE   --deliver to contact is null for return orders
   ;          
      
BEGIN
   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Inside cust_contact_creation');

   FOR xx_contact_rec IN xx_contact_cur
   LOOP
      BEGIN
         BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Derive Customer Party Id : ' || xx_contact_rec.orig_sys_document_ref);
      
            SELECT hca.party_id,cust_account_id
              INTO l_cust_party_id,l_cust_acct_id
	      FROM hz_cust_accounts hca
	     WHERE hca.cust_account_id = xx_contact_rec.sold_to_org_id
               AND hca.status='A';

	 EXCEPTION
	    WHEN OTHERS THEN
	      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Invalid Sold to Customer Account =>' ||xx_contact_rec.sold_to_org_id);	      
	      x_error_code := xx_emf_cn_pkg.cn_rec_err;
	      xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
	                       ,p_category   => xx_emf_cn_pkg.cn_valid
	      	 	       ,p_error_text => 'Invalid Deliver to Customer Account and Site Ids =>' || xx_contact_rec.sold_to_org_id
	                       ,p_record_identifier_1 => xx_contact_rec.record_number
	                       ,p_record_identifier_2 =>  xx_contact_rec.orig_sys_document_ref
	                       );
	      
	      UPDATE XX_OE_ORDER_HEADERS_ALL_PRE
	         SET error_code     = xx_emf_cn_pkg.CN_REC_ERR
	       WHERE batch_id     = G_BATCH_ID
	         AND record_number	= xx_contact_rec.record_number
	         AND orig_sys_document_ref   = xx_contact_rec.orig_sys_document_ref;
             COMMIT;
              RAISE x_record_skip;
	 END;
	 IF xx_contact_rec.deliver_to_org_id IS NOT NULL THEN
	    BEGIN
	       SELECT hcsu.cust_acct_site_id
	         INTO l_cust_acct_site_id
	         FROM hz_cust_site_uses_all hcsu
	        WHERE hcsu.status = 'A'
                  AND hcsu.site_use_id = xx_contact_rec.deliver_to_org_id;
            EXCEPTION
            WHEN OTHERS THEN
               l_cust_acct_site_id := NULL;
	    END;
	 END IF;
	 IF l_cust_acct_site_id IS NULL THEN
            BEGIN
               SELECT acct_role.cust_account_role_id 
                 INTO x_del_contact_id
	         FROM hz_contact_points cont_point,
	              hz_cust_account_roles acct_role,
	              hz_parties party,
	              hz_parties rel_party,
	              hz_relationships rel,
	              hz_cust_accounts role_acct            
	        WHERE acct_role.party_id = rel.party_id
	          AND acct_role.role_type = 'CONTACT'
	          AND rel.subject_id = party.party_id
	          AND rel_party.party_id = rel.party_id
	          AND cont_point.owner_table_id(+) = rel_party.party_id
	          AND acct_role.cust_account_id = role_acct.cust_account_id
	          AND role_acct.party_id = rel.object_id
	          AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
                  AND party.person_last_name = '.'
                  AND UPPER(party.person_first_name) = UPPER(xx_contact_rec.deliver_to_contact)
                  AND acct_role.cust_account_id = xx_contact_rec.sold_to_org_id
                  AND ROWNUM = 1;              
	    EXCEPTION
	       WHEN OTHERS THEN
	          x_del_contact_id := NULL;
	    END;
	 ELSIF l_cust_acct_site_id IS NOT NULL THEN
	    BEGIN
               SELECT acct_role.cust_account_role_id 
                 INTO x_del_contact_id
	         FROM hz_contact_points cont_point,
	              hz_cust_account_roles acct_role,
	              hz_parties party,
	              hz_parties rel_party,
	              hz_relationships rel,
	              hz_cust_accounts role_acct,
	              hz_cust_acct_sites_all hcas
	        WHERE acct_role.party_id = rel.party_id
	          AND acct_role.role_type = 'CONTACT'
	          AND rel.subject_id = party.party_id
	          AND rel_party.party_id = rel.party_id
	          AND cont_point.owner_table_id(+) = rel_party.party_id
	          AND acct_role.cust_account_id = role_acct.cust_account_id
	          AND role_acct.party_id = rel.object_id
	          AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
                  AND party.person_last_name = '.'
                  AND UPPER(party.person_first_name) = UPPER(xx_contact_rec.deliver_to_contact)
                  AND role_acct.cust_account_id = hcas.cust_account_id
                  AND hcas.cust_acct_site_id = l_cust_acct_site_id
                  AND acct_role.cust_account_id = xx_contact_rec.sold_to_org_id
                  AND ROWNUM = 1;
	    EXCEPTION
	       WHEN OTHERS THEN
	          x_del_contact_id := NULL;
	    END;	  
	 END IF;
	 IF x_del_contact_id IS NULL 
	 THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Deliver To Contact Creation : Header : ' || xx_contact_rec.orig_sys_document_ref);
            
            mo_global.init('AR');
            mo_global.set_policy_context('S',xx_contact_rec.org_id);
            l_party_id := NULL;
            --Check for party
            BEGIN
               SELECT party_id
                 INTO l_party_id
                 FROM hz_parties
                WHERE 1=1
                  AND party_type = 'PERSON'
                  AND created_by_module = x_module
                  AND person_last_name = '.'
                  AND UPPER(person_first_name) = UPPER(xx_contact_rec.deliver_to_contact)
                  AND ROWNUM = 1;
            EXCEPTION
            WHEN OTHERS THEN
               l_party_id := NULL;
            END;
            -- If Party not exits then create party
            IF l_party_id IS NULL THEN
               --Person Creation
	       xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'Before calling hz_location_v2pub.create_location ');
         
               x_create_person_rec.person_first_name := xx_contact_rec.deliver_to_contact;
               x_create_person_rec.person_last_name := '.';
               x_create_person_rec.created_by_module := x_module;
               fnd_msg_pub.initialize;
	       hz_party_v2pub.create_person (p_init_msg_list      => fnd_api.g_true
	                                   , p_person_rec         => x_create_person_rec
	                                   , x_party_id           => l_party_id
	                                   , x_party_number       => l_party_number
	                                   , x_profile_id         => l_profile_id
	                                   , x_return_status      => l_return_status
	                                   , x_msg_count          => l_msg_count
	                                   , x_msg_data           => l_msg_data
                                   );
                                                                      
	       xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'After calling hz_party_v2pub.create_person ');
               xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'New Party Id : '|| l_party_id);
               IF l_return_status !=  fnd_api.G_RET_STS_SUCCESS THEN
      	          x_msg := NULL;      	       
                  FOR i IN 1..x_msg_count 
                  LOOP
                     fnd_msg_pub.get(p_msg_index     => i
                                    ,p_encoded       => 'F'
                                    ,p_data          => x_msg_data
                                    ,p_msg_index_out => x_msg_index_out);
                           
   	             x_msg := x_msg ||  x_msg_data;		  
 	          END LOOP;
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
	          xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
	 	 		,p_category   => xx_emf_cn_pkg.cn_valid
	 	 		,p_error_text => 'After  hz_party_v2pub.create_person ' || x_msg || ' '|| xx_contact_rec.sold_to_org_id
	 	 		,p_record_identifier_1 => xx_contact_rec.record_number 
	           		,p_record_identifier_2 => xx_contact_rec.orig_sys_document_ref
	 			);
                  ROLLBACK; 

                  UPDATE XX_OE_ORDER_HEADERS_ALL_PRE
       	             SET error_code     = xx_emf_cn_pkg.CN_REC_ERR
	           WHERE batch_id     = G_BATCH_ID
	             AND record_number	= xx_contact_rec.record_number
	             AND orig_sys_document_ref   = xx_contact_rec.orig_sys_document_ref;
                  COMMIT;
                  RAISE x_record_skip;
               END IF; 
            END IF;
            lr_party_rel_id := NULL;
            --Check for party relationship
            BEGIN
               SELECT relationship_id, party_id
                 INTO lr_party_rel_id, lr_party_id
                 FROM hz_relationships
                WHERE subject_table_name = 'HZ_PARTIES'
                  AND object_table_name = 'HZ_PARTIES'
                  AND object_id = l_cust_party_id
                  AND subject_id = l_party_id
                  AND object_type = 'ORGANIZATION'
                  AND relationship_code = 'CONTACT_OF'
                  AND relationship_type = 'CONTACT'
                  AND subject_type = 'PERSON'
                  AND created_by_module = x_module
                  AND ROWNUM = 1;
            EXCEPTION
            WHEN OTHERS THEN
               lr_party_rel_id := NULL;
            END;   
            --If party relationship not exists then create relationship
            IF lr_party_rel_id IS NULL THEN
               --Party Relation Creation
               x_org_contact_rec.created_by_module := x_module;
               x_org_contact_rec.party_rel_rec.subject_id := l_party_id; --p_contact_rec.party_id;
               x_org_contact_rec.party_rel_rec.subject_type := 'PERSON';
               x_org_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES';
               x_org_contact_rec.party_rel_rec.object_id := l_cust_party_id;	                                               
               x_org_contact_rec.party_rel_rec.object_type := 'ORGANIZATION';
               x_org_contact_rec.party_rel_rec.object_table_name := 'HZ_PARTIES';
               x_org_contact_rec.party_rel_rec.relationship_code := 'CONTACT_OF';
               x_org_contact_rec.party_rel_rec.relationship_type := 'CONTACT';
               x_org_contact_rec.party_rel_rec.start_date := SYSDATE;
               fnd_msg_pub.initialize;
               hz_party_contact_v2pub.create_org_contact
                                           (p_init_msg_list        => fnd_api.g_true
                                          , p_org_contact_rec      => x_org_contact_rec
                                          , x_org_contact_id       => lr_org_contact_id
                                          , x_party_rel_id         => lr_party_rel_id
                                          , x_party_id             => lr_party_id
                                          , x_party_number         => lr_party_number
                                          , x_return_status        => l_return_status
                                          , x_msg_count            => l_msg_count
                                          , x_msg_data             => l_msg_data
                                           );
                                     
               xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'After calling hz_party_contact_v2pub.create_org_contact ');
	       IF l_return_status !=  fnd_api.G_RET_STS_SUCCESS THEN
	          x_msg := NULL;
	          FOR i IN 1..l_msg_count 
	          LOOP
	             fnd_msg_pub.get(p_msg_index     => i
	                            ,p_encoded       => 'F'
	                            ,p_data          => x_msg_data
	                            ,p_msg_index_out => x_msg_index_out);
	                           
	         	  x_msg := x_msg ||  x_msg_data;		  
	          END LOOP;
	          x_error_code := xx_emf_cn_pkg.cn_rec_err;
	          xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
		     	 	,p_category   => xx_emf_cn_pkg.cn_valid
		 	 	,p_error_text => 'After  hz_party_contact_v2pub.create_org_contact ' || x_msg || ' '|| xx_contact_rec.sold_to_org
		 	 	,p_record_identifier_1 => xx_contact_rec.record_number 
		           	,p_record_identifier_2 => xx_contact_rec.orig_sys_document_ref
		 		);
	          ROLLBACK;
	
	          UPDATE XX_OE_ORDER_HEADERS_ALL_PRE
	             SET error_code     = xx_emf_cn_pkg.CN_REC_ERR
	           WHERE batch_id     = G_BATCH_ID
	             AND record_number	= xx_contact_rec.record_number
	             AND orig_sys_document_ref   = xx_contact_rec.orig_sys_document_ref;
	          COMMIT;
	          RAISE x_record_skip;
               END IF;
            END IF;
            l_cust_account_role_id := NULL;
            --Check for account role            
            BEGIN
               SELECT cust_account_role_id
                 INTO l_cust_account_role_id
                 FROM hz_cust_account_roles
                WHERE party_id = lr_party_id
                  AND cust_account_id = l_cust_acct_id
                  AND (( xx_contact_rec.deliver_to_org_id IS NULL AND cust_acct_site_id IS NULL )                                              
                         OR 
                      ( xx_contact_rec.deliver_to_org_id IS NOT NULL AND cust_acct_site_id = l_cust_acct_site_id ))
                  AND role_type = 'CONTACT'
                  AND ROWNUM = 1;
            EXCEPTION
            WHEN OTHERS THEN
               l_cust_account_role_id := NULL;
            END;
            --If account role not exists then create account role
            IF l_cust_account_role_id IS NULL THEN 
               x_cr_cust_acc_role_rec.party_id := lr_party_id;
               x_cr_cust_acc_role_rec.cust_account_id := l_cust_acct_id; 
               IF l_cust_acct_site_id IS NOT NULL THEN
                  x_cr_cust_acc_role_rec.cust_acct_site_id := l_cust_acct_site_id;
               END IF;                                      
               --x_cr_cust_acc_role_rec.orig_system_reference := p_contact_rec.ORIG_SYS_CONTACT_REF;
               x_cr_cust_acc_role_rec.primary_flag := 'N';
               x_cr_cust_acc_role_rec.role_type := 'CONTACT';
               x_cr_cust_acc_role_rec.created_by_module := x_module;
               fnd_msg_pub.initialize;
               hz_cust_account_role_v2pub.create_cust_account_role
                                (p_init_msg_list              => 'T'
                               , p_cust_account_role_rec      => x_cr_cust_acc_role_rec
                               , x_cust_account_role_id       => l_cust_account_role_id
                               , x_return_status              => l_return_status
                               , x_msg_count                  => l_msg_count
                               , x_msg_data                   => l_msg_data
                               );
                          
               xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'After calling hz_cust_account_role_v2pub.create_cust_account_role ');
               IF l_return_status !=  fnd_api.G_RET_STS_SUCCESS THEN
                  x_msg := NULL;
                  FOR i IN 1..l_msg_count 
                  LOOP
                     fnd_msg_pub.get(p_msg_index     => i
	                            ,p_encoded       => 'F'
	                            ,p_data          => x_msg_data
	                            ,p_msg_index_out => x_msg_index_out);
	                           
                     x_msg := x_msg ||  x_msg_data;		  
                  END LOOP;
	          x_error_code := xx_emf_cn_pkg.cn_rec_err;
	          xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
		    	 	,p_category   => xx_emf_cn_pkg.cn_valid
		 	 	,p_error_text => 'After  hz_party_contact_v2pub.create_org_contact ' || x_msg || ' '|| xx_contact_rec.sold_to_org
		 	 	,p_record_identifier_1 => xx_contact_rec.record_number 
		           	,p_record_identifier_2 => xx_contact_rec.orig_sys_document_ref
		 		);
	          ROLLBACK; 
	  
	          UPDATE XX_OE_ORDER_HEADERS_ALL_PRE
		     SET error_code     = xx_emf_cn_pkg.CN_REC_ERR
	           WHERE batch_id     = G_BATCH_ID
	             AND record_number	= xx_contact_rec.record_number
	             AND orig_sys_document_ref   = xx_contact_rec.orig_sys_document_ref;
	          COMMIT;
	          RAISE x_record_skip;
               END IF;      
            END IF;
            x_del_contact_id := l_cust_account_role_id;        
	    UPDATE XX_OE_ORDER_HEADERS_ALL_PRE
	       SET error_code         = xx_emf_cn_pkg.CN_SUCCESS
	     WHERE batch_id         = G_BATCH_ID
               AND record_number	= xx_contact_rec.record_number;

            COMMIT;
         END IF;
         BEGIN
            UPDATE XX_OE_ORDER_HEADERS_ALL_PRE
	       SET deliver_to_contact_id = x_del_contact_id 
	     WHERE orig_sys_document_ref = xx_contact_rec.orig_sys_document_ref
	       AND record_number	= xx_contact_rec.record_number;
	    COMMIT;
	 EXCEPTION
            WHEN OTHERS THEN
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Header : '||xx_contact_rec.orig_sys_document_ref||' Error While updating contact ID ');
                xx_emf_pkg.error (p_severity        =>   xx_emf_cn_pkg.CN_HIGH
                                 ,p_category            =>   xx_emf_cn_pkg.CN_TECH_ERROR
                                 ,p_error_text          =>   sqlerrm 
                                 ,p_record_identifier_3 =>   'Process create Contact'
                                 );
            RETURN x_error_code;
	 END;      
      EXCEPTION
         WHEN x_record_skip THEN
           NULL;
      END;  
      END LOOP;
          
     RETURN xx_emf_cn_pkg.CN_SUCCESS;
     EXCEPTION
          WHEN OTHERS THEN
            
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Exception in cust_contact_creation');
            xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.CN_HIGH
                             ,p_category            =>   xx_emf_cn_pkg.CN_TECH_ERROR
                             ,p_error_text          =>   sqlerrm 
                             ,p_record_identifier_3 =>   'Process create Contact Func'
                             );
            RETURN x_error_code;
     END cust_contact_creation;

-------------------------------------------------------------------------------------------------------------------------------
		
		-- Line Level
		FUNCTION update_pre_lines_data
                RETURN NUMBER
                IS
                        x_return_status VARCHAR2(15) := xx_emf_cn_pkg.CN_SUCCESS;
			
			PRAGMA AUTONOMOUS_TRANSACTION;
                BEGIN
                  --09-AUG-12 Modified update to comment dates
                  UPDATE XX_OE_ORDER_LINES_ALL_PRE xol
		     SET (--xol.org_id,
			  xol.ship_to_org_id,
			  xol.sold_to_org_id,
			  xol.invoice_to_org_id,
			  --xol.ship_from_org_id,
			  xol.sold_from_org_id,
			  xol.salesrep_id,
			  xol.fob_point_code,
			  xol.freight_terms_code,
			  xol.customer_po_number,
			  --xol.pricing_date,
                         -- xol.schedule_ship_date,
                          --xol.promise_date,
			  --xol.tax_date,
			  xol.ship_to_customer_number,
			  xol.payment_term_id,
			  xol.shipping_method_code,
			  xol.tax_exempt_flag) = (SELECT distinct ship_to_org_id,
								sold_to_org_id,
								invoice_to_org_id,
								--ship_from_org_id,  Modified as per Wave1
								sold_from_org_id,
								salesrep_id,      
								fob_point_code,
								freight_terms_code,
								customer_po_number,
								--ordered_date,
                                                                --ordered_date,
                                                                --ordered_date,
								--ordered_date,
								ship_to_customer_number,
								payment_term_id,
								shipping_method_code,
								tax_exempt_flag
					     FROM XX_OE_ORDER_HEADERS_ALL_PRE xoh
					     WHERE xoh.orig_sys_document_ref = xol.orig_sys_document_ref
					     and xoh.batch_id		     = G_BATCH_ID
					     AND request_id                  = xx_emf_pkg.G_REQUEST_ID
					     )
			  WHERE batch_id = G_LINE_BATCH_ID
			  AND request_id = xx_emf_pkg.G_REQUEST_ID;
				   COMMIT;
								
                        RETURN x_return_status;			
                EXCEPTION					
                        WHEN OTHERS THEN
                                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Order Lines Level ... Error while updating into Interface Table: ' ||SQLERRM);
                                xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
                                x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
                                RETURN x_error_code;
                                                
                END update_pre_lines_data; 

		
		-- Line Level
		FUNCTION process_lines_data
                RETURN NUMBER
                IS
                        x_return_status VARCHAR2(15) := xx_emf_cn_pkg.CN_SUCCESS;
			x_process_code   VARCHAR2(100);
			
			PRAGMA AUTONOMOUS_TRANSACTION;
                BEGIN
                        -- Change the logic to whatever needs to be done
                        -- with valid records in the pre-interface tables
                        -- either call the appropriate API to process the data
                        -- or to insert into an interface table
			
			INSERT INTO OE_LINES_IFACE_ALL -- Standard Order Lines Interface Table
                        ( 	--LINE_ID			,			
				--ORG_ID				,	
				--HEADER_ID			,
				ORIG_SYS_DOCUMENT_REF		,
				ORIG_SYS_LINE_REF		,
				SHIPMENT_NUMBER			,
				--LINE_TYPE			,
				LINE_TYPE_ID			,
				ORDER_SOURCE_ID			,
				--LINE_NUMBER			,
				--ITEM_TYPE_CODE		,	
				--INVENTORY_ITEM			,
				INVENTORY_ITEM_ID		,
				SOURCE_TYPE_CODE		,
				SCHEDULE_STATUS_CODE		,
				SCHEDULE_SHIP_DATE		,
				SCHEDULE_ARRIVAL_DATE		,
				PROMISE_DATE			,
				SCHEDULE_DATE			,
				ORDERED_QUANTITY		,
				ORDER_QUANTITY_UOM		,
				PRICING_QUANTITY		,
				PRICING_QUANTITY_UOM		,
				CANCELLED_QUANTITY		,
				SHIP_FROM_ORG_ID		,
				SHIP_TO_ORG_ID			,
				INVOICE_TO_ORG_ID		,  
				SHIP_SET_NAME                   ,  --Added on 03-FEB-2014 as per Wave1
				PRICE_LIST_ID			,
				PRICING_DATE			,
				UNIT_LIST_PRICE			,
				UNIT_SELLING_PRICE		,
				CALCULATE_PRICE_FLAG		,
				TAX_DATE			,
				TAX_EXEMPT_FLAG			,
				PAYMENT_TERM_ID			,
				SHIPPING_METHOD_CODE		,
				FREIGHT_CARRIER_CODE		,
				--FREIGHT_TERMS_CODE		, --Commented by Samir on 19-Jul-2012
                                FREIGHT_TERMS		        ,
				--Added by Samir on 23-Jul-2012 STARTS
			        SHIPPING_INSTRUCTIONS  ,                   
			        PACKING_INSTRUCTIONS   ,
                                --Added by Samir on 23-Jul-2012 ENDS
				FOB_POINT_CODE			,
				CUSTOMER_PO_NUMBER		,
				CANCELLED_FLAG			,
				REQUEST_DATE			,
				UNIT_LIST_PRICE_PER_PQTY	,
				UNIT_SELLING_PRICE_PER_PQTY	,
				INVOICE_TO_CUSTOMER_NAME	,
				LINE_CATEGORY_CODE		,
			        TP_CONTEXT                      ,       
				TP_ATTRIBUTE1                   ,       
				TP_ATTRIBUTE2                   ,       
				TP_ATTRIBUTE3                   ,       
				TP_ATTRIBUTE4                   ,       
				TP_ATTRIBUTE5                   ,  
				TP_ATTRIBUTE15                  ,  --25-JUL-12 Added to populate batch_id
				RETURN_REASON_CODE              ,  --02-AUG-12 Added for return order
				CUSTOMER_ITEM_NAME              ,       
                                CUSTOMER_ITEM_ID_TYPE           ,       
				--STATUS				,
				ATTRIBUTE1,   --BATCH_ID			,
				operation_code			,
				OVERRIDE_ATP_DATE_CODE          ,
				REQUEST_ID			,
				CREATED_BY			,
				CREATION_DATE			,
				LAST_UPDATE_DATE		,
				LAST_UPDATED_BY			,
				LAST_UPDATE_LOGIN 		
				)				
                        SELECT	ORIG_SYS_DOCUMENT_REF		,
				TO_NUMBER(ORIG_SYS_LINE_REF)		, --Modified as per Wave1 15-OCT-13
				SHIPMENT_NUMBER			,
				LINE_TYPE_ID			,
				G_SOURCE_ID			,
				INVENTORY_ITEM_ID		,
				SOURCE_TYPE_CODE		,
				SCHEDULE_STATUS_CODE            , --NULL,--'SCHEDULED',--SCHEDULE_STATUS_CODE  --Added NULL to set schedule status code to null 21-SEP-13 as per Wave1
				CASE WHEN SCHEDULE_SHIP_DATE < SYSDATE THEN NULL  --SCHEDULE_SHIP_DATE, --SCHEDULE_DATE,  --Modified as per TDR 30-OCT-12
				     WHEN SCHEDULE_SHIP_DATE >= SYSDATE THEN SCHEDULE_SHIP_DATE
				END                             ,
				CASE WHEN SCHEDULE_ARRIVAL_DATE < SYSDATE THEN NULL     --SCHEDULE_ARRIVAL_DATE
				     WHEN SCHEDULE_ARRIVAL_DATE >= SYSDATE THEN SCHEDULE_ARRIVAL_DATE
				END                             ,	--Modified as per Wave1 19-SEP-13			
				PROMISE_DATE			,
				SCHEDULE_DATE			,
				ORDERED_QUANTITY		,
				ORDER_QUANTITY_UOM		,
				PRICING_QUANTITY		,
				PRICING_QUANTITY_UOM		,
				CANCELLED_QUANTITY		,
				SHIP_FROM_ORG_ID		,
				SHIP_TO_ORG_ID			,
				INVOICE_TO_ORG_ID		,
				SHIP_SET_NAME                   ,  --Added on 03-FEB-2014 as per Wave1
				PRICE_LIST_ID			,
				PRICING_DATE			,
				UNIT_LIST_PRICE			,
				UNIT_SELLING_PRICE		,
				CALCULATE_PRICE_FLAG            ,  --'N',--CALCULATE_PRICE_FLAG	,  21-SEP-13 as per Wave1
				TAX_DATE			,
				TAX_EXEMPT_FLAG			,
				PAYMENT_TERM_ID			,
				SHIPPING_METHOD_CODE		,
				FREIGHT_CARRIER_CODE		,
				FREIGHT_TERMS_CODE		,
				--FREIGHT_TERMS			,
				--Added by Samir on 23-Jul-2012 STARTS
			        SHIPPING_INSTRUCTIONS  ,                   
			        PACKING_INSTRUCTIONS   ,
                                --Added by Samir on 23-Jul-2012 ENDS
				FOB_POINT_CODE			,
				--FOB_POINT			,
				--SALESREP			,
				CUSTOMER_PO_NUMBER		,
				CANCELLED_FLAG			,
				--OPEN_FLAG			,
				--BOOKED_FLAG			,
				--CASE WHEN REQUEST_DATE IS NULL THEN SYSDATE
                                --     WHEN REQUEST_DATE < SYSDATE THEN SYSDATE
                                --     WHEN REQUEST_DATE > SYSDATE THEN REQUEST_DATE
				/*CASE WHEN SCHEDULE_DATE IS NULL THEN SYSDATE
                                     WHEN SCHEDULE_DATE < SYSDATE THEN SYSDATE
                                     WHEN SCHEDULE_DATE > SYSDATE THEN SCHEDULE_DATE
                                END                             ,*/--REQUEST_DATE	, 13-Nov-2012 Modified to populate request date in R12 with
                                				 -- schedule_date from legacy. Based on TDR.
                                REQUEST_DATE	                ,  --Modified on 03-FEB-2014 as per Wave1
				--SOLD_FROM_ORG			,
				UNIT_LIST_PRICE_PER_PQTY	,
				UNIT_SELLING_PRICE_PER_PQTY	,
				INVOICE_TO_CUSTOMER_NUMBER	,
				LINE_CATEGORY_CODE		,
			        TP_CONTEXT                      ,       
				TP_ATTRIBUTE1                   ,       
				TP_ATTRIBUTE2                   ,       
				TP_ATTRIBUTE3                   ,       
				TP_ATTRIBUTE4                   ,       
				TP_ATTRIBUTE5                   ,  
				BATCH_ID                        , --25-JUL-12 Added to populate batch_id
				RETURN_REASON_CODE              , --DECODE(LINE_TYPE,G_RMA_LINE_TYPE,'CONV',NULL), --02-AUG-12 Added for return order Modified on 28-FEB-2014
				CUSTOMER_ITEM_NAME              ,       
                                CUSTOMER_ITEM_ID_TYPE           ,       
				--STATUS			,
				ATTRIBUTE1                      , --BATCH_ID , --attribute1 25-JUL-12 Commented to use tp_attr15
				'INSERT'			,
				--'Y', OVERRIDE_ATP_DATE_CODE,
                                null,
				REQUEST_ID			,
				CREATED_BY			,
				CREATION_DATE			,
				LAST_UPDATE_DATE		,
				LAST_UPDATED_BY			,
				LAST_UPDATE_LOGIN		
			 FROM  XX_OE_ORDER_LINES_ALL_PRE PRE
                         WHERE batch_id		= G_LINE_BATCH_ID		
                           AND request_id	= xx_emf_pkg.G_REQUEST_ID
                           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                           AND process_code	= xx_emf_cn_pkg.CN_POSTVAL
			   AND EXISTS (SELECT 1
			                 FROM OE_HEADERS_IFACE_ALL
					WHERE ORIG_SYS_DOCUMENT_REF=PRE.ORIG_SYS_DOCUMENT_REF)--Added by Samir on 23-Jul-2012
			  ORDER BY ORIG_SYS_DOCUMENT_REF, TO_NUMBER(ORIG_SYS_LINE_REF) --Added as per Wave1 15-OCT-13
			  ;
			COMMIT;	
								
                        RETURN x_return_status;			
                EXCEPTION					
                        WHEN OTHERS THEN
                                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while inserting into Interface Table: ' ||SQLERRM);
                                xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
                                x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
                                RETURN x_error_code;
                                                
                END process_lines_data;	
       -------------------------------------------------------------------------
       -----------< update_record_count >--------------------------------------
       -------------------------------------------------------------------------
		
		--- Order HEaders Level Record Count ------------
		PROCEDURE update_record_count
                IS
                        CURSOR c_get_total_cnt IS
                        SELECT COUNT (1) total_count
                          FROM XX_OE_ORDER_HEADERS_ALL_STG
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID;
                        
			x_total_cnt NUMBER;

			CURSOR c_get_error_cnt IS
			SELECT SUM(error_count)
                          FROM (
				SELECT COUNT (1) error_count
				  FROM XX_OE_ORDER_HEADERS_ALL_STG 
				 WHERE batch_id   = G_BATCH_ID
				   AND request_id = xx_emf_pkg.G_REQUEST_ID
				   AND error_code = xx_emf_cn_pkg.CN_REC_ERR
				UNION ALL
				SELECT COUNT (1) error_count
				  FROM XX_OE_ORDER_HEADERS_ALL_PRE
				 WHERE batch_id   = G_BATCH_ID
				   AND request_id = xx_emf_pkg.G_REQUEST_ID
				   AND error_code = xx_emf_cn_pkg.CN_REC_ERR
			       );
                        
			x_error_cnt NUMBER;

			CURSOR c_get_warning_cnt IS
                        SELECT COUNT (1) warn_count
                          FROM XX_OE_ORDER_HEADERS_ALL_PRE
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

                        x_warn_cnt NUMBER;

			CURSOR c_get_success_cnt IS
                        SELECT COUNT (1) warn_count
                          FROM XX_OE_ORDER_HEADERS_ALL_PRE
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND (p_validate_and_load= g_validate_and_load and process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                                OR 1=1 and process_code = xx_emf_cn_pkg.CN_POSTVAL)
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

                --- Order Lines Level Record Count ------------

		PROCEDURE update_lines_record_count
                IS
                        CURSOR c_get_total_cnt IS
                        SELECT COUNT (1) total_count
                          FROM XX_OE_ORDER_LINES_ALL_STG
                         WHERE batch_id = G_LINE_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID;
                        
			x_total_cnt NUMBER;

			CURSOR c_get_error_cnt IS
			SELECT SUM(error_count)
                          FROM (
				SELECT COUNT (1) error_count
				  FROM XX_OE_ORDER_LINES_ALL_STG 
				 WHERE batch_id   = G_LINE_BATCH_ID
				   AND request_id = xx_emf_pkg.G_REQUEST_ID
				   AND error_code = xx_emf_cn_pkg.CN_REC_ERR
				UNION ALL
				SELECT COUNT (1) error_count
				  FROM XX_OE_ORDER_LINES_ALL_PRE
				 WHERE batch_id   = G_LINE_BATCH_ID
				   AND request_id = xx_emf_pkg.G_REQUEST_ID
				   AND error_code = xx_emf_cn_pkg.CN_REC_ERR
			       );
                        
			x_error_cnt NUMBER;

			CURSOR c_get_warning_cnt IS
                        SELECT COUNT (1) warn_count
                          FROM XX_OE_ORDER_LINES_ALL_PRE
                         WHERE batch_id = G_LINE_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

                        x_warn_cnt NUMBER;

			CURSOR c_get_success_cnt IS
                        SELECT COUNT (1) warn_count
                          FROM XX_OE_ORDER_LINES_ALL_PRE
                         WHERE batch_id = G_LINE_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND (p_validate_and_load= g_validate_and_load and process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                                OR 1=1 and process_code = xx_emf_cn_pkg.CN_POSTVAL)
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

                G_LINE_BATCH_ID := p_batch_id;
                
 		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Setting Environment');
		fnd_file.put_line(fnd_file.log,'Before Setting Environment');

                -- Hdr level --
		fnd_file.put_line(fnd_file.log,'Calling HDr Set_cnv_env');
		--set_cnv_env (p_batch_id => p_batch_id,p_required_flag => xx_emf_cn_pkg.CN_YES,x_batch_flag => 'HDR');
		set_cnv_env (p_batch_id,xx_emf_cn_pkg.CN_YES,'HDR');

                -- Line level -- 
		fnd_file.put_line(fnd_file.log,'Calling Line Set_cnv_env');
		--set_cnv_env (p_batch_id => p_line_batch_id, p_required_flag => xx_emf_cn_pkg.CN_YES,x_batch_flag => 'LINE');
		set_cnv_env (p_batch_id, xx_emf_cn_pkg.CN_YES,'LINE');
                --Assigining the global variables
                assign_global_var;
		get_source_id();
		fnd_file.put_line(fnd_file.log,'After calling Get_source_id proc G_SOURCE_ID :: '||G_SOURCE_ID);

		get_org_id(p_batch_id => p_batch_id);
		fnd_file.put_line(fnd_file.log,'After calling Get_source_id proc G_ORG_ID :: '||G_ORG_ID);
                -- include all the parameters to the conversion main here
                -- as medium log messages
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Starting main process with the following parameters');
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_batch_id '	|| p_batch_id);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_restart_flag '	|| p_restart_flag);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_override_flag '	|| p_override_flag);
                
                -- Call procedure to update records with the current request_id
                -- So that we can process only those records
                -- This gives a better handling of restartability
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling mark_records_for_processing..');
		mark_records_for_processing(p_restart_flag => p_restart_flag, p_override_flag => p_override_flag);

                -- Once the records are identified based on the input parameters
                -- Start with pre-validations
                IF NVL ( p_override_flag, xx_emf_cn_pkg.CN_NO) = xx_emf_cn_pkg.CN_NO THEN
                        
    			xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling Set Stage ..');

			-- Set the stage to Pre Validations
                        set_stage (xx_emf_cn_pkg.CN_PREVAL);

                        -- Change the validations package to the appropriate package name
                        -- Modify the parameters as required
                        -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
                        -- PRE_VALIDATIONS SHOULD BE RETAINED
			xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling xx_oe_sales_order_val_pkg.pre_validations ..');

                        x_error_code := xx_oe_sales_order_val_pkg.pre_validations ();
                        
			--xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After pre-validations X_ERROR_CODE ' || X_ERROR_CODE);

                        -- Update process code of staging records
                        -- Also move the successful records to pre-interface tables
                        
			-- Update Header and Lines Level
			update_staging_records ('HDR', xx_emf_cn_pkg.CN_SUCCESS);
			update_staging_records ('LINE', xx_emf_cn_pkg.CN_SUCCESS);
                        xx_emf_pkg.propagate_error ( x_error_code);

                        -- Header Level
                        x_error_code := move_rec_pre_standard_table;
			xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After move_rec_pre_standard_table X_ERROR_CODE ' || X_ERROR_CODE);
                        xx_emf_pkg.propagate_error ( x_error_code);

                        -- Lines Level
                        x_error_code := move_rec_pre_lines_table;
			xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After move_rec_pre_lines_table  X_ERROR_CODE ' || X_ERROR_CODE);
                        xx_emf_pkg.propagate_error ( x_error_code);
			

                END IF;

		/* Added for batch validation */

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Main: Testing');

                -- Once the records are identified based on the input parameters
                -- Start with pre-validations
                -- Set the stage to Pre Validations
		   set_stage (xx_emf_cn_pkg.CN_BATCHVAL);

                -- CCID099 changes
                -- Change the validations package to the appropriate package name
                -- Modify the parameters as required
                -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
                -- batch_validations SHOULD BE RETAINED
                
		--x_error_code := xx_oe_sales_order_val_pkg.batch_validations (p_batch_id);
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After batch_validations X_ERROR_CODE ' || X_ERROR_CODE);
                xx_emf_pkg.propagate_error ( x_error_code); 

		-- Once pre-validations are complete the loop through the pre-interface records
                -- and perform data validations on this table
                -- Set the stage to data Validations
		set_stage (xx_emf_cn_pkg.CN_VALID);
		

		---- Header Level Validation -----------------------------------------------------------------
		OPEN C_XX_OE_ORDER_HEADERS_ALL_PRE ( xx_emf_cn_pkg.CN_PREVAL);
                LOOP
                       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'In the pre interface records loop');
                        
			FETCH C_XX_OE_ORDER_HEADERS_ALL_PRE 
                        BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;
                        
			FOR i IN 1 .. x_pre_std_hdr_table.COUNT
                        LOOP
                                BEGIN
                                        -- Perform header level Base App Validations
                                       x_error_code := xx_oe_sales_order_val_pkg.data_validations (x_pre_std_hdr_table (i));

				       fnd_file.PUT_LINE ( fnd_file.log, 'After Data Validations ... x_error_code : '||x_error_code);
                                       --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_hdr_table (i).record_number|| ' is ' || x_error_code);

                                        update_record_status (x_pre_std_hdr_table (i), x_error_code);
					fnd_file.PUT_LINE ( fnd_file.log, 'After update_record_status ...');
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
                        
			EXIT WHEN c_xx_oe_order_headers_all_pre%NOTFOUND;
                END LOOP;

                IF c_xx_oe_order_headers_all_pre%ISOPEN THEN
                        CLOSE c_xx_oe_order_headers_all_pre;
                END IF;

                -- Once data-validations are complete the loop through the pre-interface records
                -- and perform data derivations on this table

                -- Set the stage to data derivations
                set_stage (xx_emf_cn_pkg.CN_DERIVE);

                OPEN C_XX_OE_ORDER_HEADERS_ALL_PRE ( xx_emf_cn_pkg.CN_VALID);
                LOOP

                        FETCH C_XX_OE_ORDER_HEADERS_ALL_PRE
                        BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;
                        
			FOR i IN 1 .. x_pre_std_hdr_table.COUNT
                        LOOP
                                BEGIN

                                        -- Perform header level Base App Validations
                                        x_error_code := xx_oe_sales_order_val_pkg.data_derivations (x_pre_std_hdr_table (i));

                                       -- xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_hdr_table (i).record_number|| ' is ' || x_error_code);
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
                        
			EXIT WHEN C_XX_OE_ORDER_HEADERS_ALL_PRE%NOTFOUND;
                END LOOP;

                IF C_XX_OE_ORDER_HEADERS_ALL_PRE%ISOPEN THEN
                        CLOSE C_XX_OE_ORDER_HEADERS_ALL_PRE;
                END IF;

                -- Set the stage to Post Validations
                set_stage (xx_emf_cn_pkg.CN_POSTVAL);

                -- Change the validations package to the appropriate package name
                -- Modify the parameters as required
                -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
                -- PRE_VALIDATIONS SHOULD BE RETAINED
                
		x_error_code := xx_oe_sales_order_val_pkg.post_validations ();
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);                
		mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL,'HDR');
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);
                xx_emf_pkg.propagate_error ( x_error_code);

                -- Set the stage to Process
               /* set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);
		--xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Before Process Data');
                x_error_code := process_data;
		x_error_code := process_actions_data;
		--xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After Process Data');
                x_error_code := cust_add_creation;
		--xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After cust_add_creation ');
                mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA,'HDR');
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After Process Data mark_records_complete x_error_code'||x_error_code);
		xx_emf_pkg.propagate_error ( x_error_code);
		
		update_record_count;
		*/
		
		/*submit_order_import_program(xx_emf_cn_pkg.CN_SUBMIT_ORDER_REQUEST);*/
                
		--xx_emf_pkg.create_report;

  ----------------------------------- End Of Header Level Validation ----------------------------------------------------------------------------
          x_error_code := update_pre_lines_data;    --Modifed as per Wave1 15-OCT-13
  ------------------------------------ Order Line Level Validation ---------------------------------------------------------------------------

       BEGIN
                set_stage (xx_emf_cn_pkg.CN_VALID);

		OPEN C_XX_OE_ORDER_LINES_ALL_PRE ( xx_emf_cn_pkg.CN_PREVAL);
                LOOP
                       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'In the Line level pre interface records loop');
                        
			FETCH C_XX_OE_ORDER_LINES_ALL_PRE 
                        BULK COLLECT INTO x_pre_std_line_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

			--xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Line Records Count : '||x_pre_std_line_table.COUNT);
                        
			FOR i IN 1 .. x_pre_std_line_table.COUNT
                        LOOP
                                BEGIN
                                       -- Perform Line level Base App Validations
				       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Before Calling Data Validations.. ');

                                       x_error_code := xx_oe_sales_order_val_pkg.data_validations_line (x_pre_std_line_table (i));
 
				      -- fnd_file.PUT_LINE ( fnd_file.log, 'After Data Validations ... x_error_code : '||x_error_code);
                                       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_line_table (i).record_number|| ' is ' || x_error_code);

                                        update_line_record_status (x_pre_std_line_table (i), x_error_code);
					--fnd_file.PUT_LINE ( fnd_file.log, 'After update_record_status ...');
                                        xx_emf_pkg.propagate_error (x_error_code);

                                EXCEPTION
                                        -- If HIGH error then it will be propagated to the next level
                                        -- IF the process has to continue maintain it as a medium severity
                                        WHEN xx_emf_pkg.G_E_REC_ERROR
                                        THEN
                                                xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Order Line Level '||xx_emf_cn_pkg.CN_REC_ERR);

                                        WHEN xx_emf_pkg.G_E_PRC_ERROR
                                        THEN
                                                xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Order Line Level - Process Level Error in Data Validations');
                                                update_pre_lines_int_records ( x_pre_std_line_table);
                                                RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                                        WHEN OTHERS
                                        THEN
                                                xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_line_table (i).record_number);
                                END;
                        END LOOP;

                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_line_table.count ' || x_pre_std_line_table.COUNT );
                        
			update_pre_lines_int_records ( x_pre_std_line_table);
                        x_pre_std_line_table.DELETE;
                        
			EXIT WHEN C_XX_OE_ORDER_LINES_ALL_PRE%NOTFOUND;
                END LOOP;

		        IF C_XX_OE_ORDER_LINES_ALL_PRE%ISOPEN THEN
                           CLOSE C_XX_OE_ORDER_LINES_ALL_PRE;
                        END IF;
                EXCEPTION
		    WHEN OTHERS THEN
		        fnd_file.put_line(fnd_file.log,'Error While Fetching Line Records...' || SQLERRM);
		END;

                -- Once data-validations are complete the loop through the pre-interface records
                -- and perform data derivations on this table

                -- Set the stage to data derivations
                set_stage (xx_emf_cn_pkg.CN_DERIVE);

	     BEGIN

                OPEN C_XX_OE_ORDER_LINES_ALL_PRE ( xx_emf_cn_pkg.CN_VALID);
                LOOP

                        FETCH C_XX_OE_ORDER_LINES_ALL_PRE
                        BULK COLLECT INTO x_pre_std_line_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;
                        
			FOR i IN 1 .. x_pre_std_line_table.COUNT
                        LOOP
                                BEGIN

                                        -- Perform header level Base App Validations
                                        x_error_code := xx_oe_sales_order_val_pkg.data_derivations_line (x_pre_std_line_table (i));

                                        --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Order Line Level : x_error_code for  '|| x_pre_std_line_table (i).record_number|| ' is ' || x_error_code);
                                        update_line_record_status (x_pre_std_line_table (i), x_error_code);
                                        xx_emf_pkg.propagate_error (x_error_code);
                                EXCEPTION
                                        -- If HIGH error then it will be propagated to the next level
                                        -- IF the process has to continue maintain it as a medium severity
                                        WHEN xx_emf_pkg.G_E_REC_ERROR
                                        THEN
                                                xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.CN_REC_ERR);
                                        WHEN xx_emf_pkg.G_E_PRC_ERROR
                                        THEN
                                                xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Order Line Level - Process Level Error in Data derivations');
                                                update_pre_lines_int_records ( x_pre_std_line_table);
                                                RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                                        WHEN OTHERS
                                        THEN
                                                xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_line_table (i).record_number);
                                END;
                        END LOOP;
                        
			xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_line_table.count ' || x_pre_std_line_table.COUNT );
                        
			update_pre_lines_int_records ( x_pre_std_line_table);
                        x_pre_std_line_table.DELETE;
                        
			EXIT WHEN C_XX_OE_ORDER_LINES_ALL_PRE%NOTFOUND;
                END LOOP;

			IF C_XX_OE_ORDER_LINES_ALL_PRE%ISOPEN THEN
				 CLOSE C_XX_OE_ORDER_LINES_ALL_PRE;
			 END IF;

		 EXCEPTION
		    WHEN OTHERS THEN
		        fnd_file.put_line(fnd_file.log,'Error While Fetching Line Records...' || SQLERRM);
		END;

                -- Set the stage to Post Validations
                set_stage (xx_emf_cn_pkg.CN_POSTVAL);

                -- Change the validations package to the appropriate package name
                -- Modify the parameters as required
                -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
                -- PRE_VALIDATIONS SHOULD BE RETAINED
                
		x_error_code := xx_oe_sales_order_val_pkg.post_validations ();
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Order Line Level => After post-validations X_ERROR_CODE ' || X_ERROR_CODE);                
		mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL,'LINE');
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Order Line Level =>  After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);
                xx_emf_pkg.propagate_error ( x_error_code);

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'before calling cust_add_creation');
		x_error_code := cust_add_creation;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'after calling cust_add_creation');
                --Add as per DCR 03-SEP-12
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'before calling cust_contact_creation');
		x_error_code := cust_contact_creation;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'after calling cust_contact_creation');
                
                --x_error_code := update_pre_lines_data;
                IF p_validate_and_load = g_validate_and_load THEN
      		   -- Set the stage to Process
                   set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);                
                   x_error_code := process_data;
		   --x_error_code := process_actions_data;
		   mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA,'HDR');
		   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After Process Data mark_records_complete x_error_code'||x_error_code);
		   xx_emf_pkg.propagate_error ( x_error_code);
		   --update_record_count;
                   --xx_emf_pkg.create_report;
		   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Before process_lines_data');
                   x_error_code := process_lines_data;
		   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After process_lines_data');
                   mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA,'LINE');
		   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Line Level => After Process Data mark_records_complete x_error_code'||x_error_code);
		   xx_emf_pkg.propagate_error ( x_error_code);
		   -- Calling Standard Order Import Program -----------
		   --submit_order_import_program(xx_emf_cn_pkg.CN_SUBMIT_ORDER_REQUEST);
		   submit_order_import_program;
		 END IF; -- For validate only flag check
		 fnd_file.new_line(FND_FILE.OUTPUT,3);		
		 fnd_file.PUT_LINE (fnd_file.output, '						Order Lines Level Report ');
		 update_record_count;
		 --xx_emf_pkg.create_report;  Modified to display distinct errors record count
		 xx_emf_pkg.generate_report;        --Modified as per Wave1
		--------- End Of Order Line Level Validation --------------------------------------------------------------------

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

END xx_oe_sales_order_conv_pkg;
/


GRANT EXECUTE ON APPS.XX_OE_SALES_ORDER_CONV_PKG TO INTG_XX_NONHR_RO;
