DROP PACKAGE BODY APPS.XX_AR_RECEIPT_CONV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_RECEIPT_CONV_PKG" AS
  -- ---------------------------------------------------------------------------------
  -- Created By     : Renjith
  -- Creation Date  : 04-JUN-2013
  -- Filename       : XXARCASHREPT.pks
  -- Description    : Package specification for AR Receipt Conversion

  -- Change History:

  -- Date          Version#    Name                Remarks
  -- -----------   --------    ---------------     ------------------------------------
  -- 04-JUN-2013   1.0         Renjith             Initial version
  -- ----------------------------------------------------------------------------------

    PROCEDURE set_cnv_env ( p_batch_id      VARCHAR2
                           ,p_rcpt_method   VARCHAR2
                           ,p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES
                          ) IS
    	x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
    	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside set_cnv_env...');
    	G_BATCH_ID	  := p_batch_id;
    	G_RCPT_METHOD     := p_rcpt_method;
    	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_BATCH_ID   : '||G_BATCH_ID );
    	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_RCPT_METHOD: '||G_RCPT_METHOD );

    	-- Set the environment
    	x_error_code := xx_emf_pkg.set_env;
    	IF NVL (p_required_flag, xx_emf_cn_pkg.CN_YES) <> xx_emf_cn_pkg.CN_NO THEN
    		xx_emf_pkg.propagate_error(x_error_code);
    	END IF;
    EXCEPTION
    	WHEN OTHERS THEN
    		RAISE xx_emf_pkg.G_E_ENV_NOT_SET;
    END set_cnv_env;

    -- --------------------------------------------------------------------------------------- --

    PROCEDURE dbg_low (p_dbg_text varchar2)
    IS
    BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low
                                , 'In xx_iby_cc_conv_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_low;

    -- --------------------------------------------------------------------------------------- --

    PROCEDURE dbg_med (p_dbg_text varchar2)
    IS
    BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium
                                , 'In xx_iby_cc_conv_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_med;

    -- --------------------------------------------------------------------------------------- --

    PROCEDURE dbg_high (p_dbg_text varchar2)
    IS
    BEGIN
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high
                                , 'In xx_iby_cc_conv_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_high;

    -- --------------------------------------------------------------------------------------- --
    --	Procedure to mark records for processing.
    -- --------------------------------------------------------------------------------------- --
    PROCEDURE mark_records_for_processing ( p_restart_flag  IN VARCHAR2
                                           ,p_override_flag IN VARCHAR2
                                          ) IS
    	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
    	----- All records are processed if the Restart Flag is set to All Records otherwise only Error records -----
        g_api_name := 'mark_records_for_processing';
    	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside of mark records for processing...');

    	IF p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS THEN
           IF p_override_flag = xx_emf_cn_pkg.cn_no THEN
	--------------Update stg table-------------------------------
    		UPDATE xx_ar_cash_receipt_stg
    		   SET request_id = xx_emf_pkg.G_REQUEST_ID,
    		       error_code = xx_emf_cn_pkg.CN_NULL,
    		       process_code = xx_emf_cn_pkg.CN_NEW
    		 WHERE batch_id = G_BATCH_ID;
    		   --AND receipt_method_name = NVL(G_RCPT_METHOD,receipt_method_name);
           ELSE
	--------------Update stg table-------------------------------
                UPDATE xx_ar_cash_receipt_stg
                   SET process_code = xx_emf_cn_pkg.cn_preval,
                       error_code = xx_emf_cn_pkg.cn_success,
                       request_id = xx_emf_pkg.g_request_id
                 WHERE batch_id = g_batch_id;
                   --AND receipt_method_name = NVL(G_RCPT_METHOD,receipt_method_name);
           END IF;
    	ELSIF p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS THEN
           --IF p_override_flag = xx_emf_cn_pkg.cn_no THEN
	--------------Update stg table table-------------------------------
    		UPDATE xx_ar_cash_receipt_stg
    		   SET request_id   = xx_emf_pkg.G_REQUEST_ID,
    		       error_code   = xx_emf_cn_pkg.CN_NULL,
    		       process_code = xx_emf_cn_pkg.CN_NEW
    		 WHERE batch_id = G_BATCH_ID
    		   --AND receipt_method_name = NVL(G_RCPT_METHOD,receipt_method_name)
    		   AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
    		       xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR);
           --END IF;
        END IF;

        COMMIT;

        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'End of mark records for processing...');
    END;

    -- --------------------------------------------------------------------------------------- --
    --	Procedure to set stage for staging table.
    -- --------------------------------------------------------------------------------------- --

    PROCEDURE set_stage (p_stage VARCHAR2)
    IS
    BEGIN
    	G_STAGE := p_stage;
    END set_stage;

    -- --------------------------------------------------------------------------------------- --

    PROCEDURE update_staging_records( p_error_code VARCHAR2) IS

	x_last_update_date     DATE   := SYSDATE;
	x_last_updated_by      NUMBER := fnd_global.user_id;
	x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
	g_api_name := 'update_staging_records';

    	    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside update_staging_records');
	    UPDATE xx_ar_cash_receipt_stg
	       SET process_code = G_STAGE,
		   error_code = DECODE ( error_code, NULL, p_error_code, error_code),
		   last_update_date = x_last_update_date,
		   last_updated_by   = x_last_updated_by,
		   last_update_login = x_last_update_login
	     WHERE batch_id		= G_BATCH_ID
	       --AND receipt_method_name = NVL(G_RCPT_METHOD,receipt_method_name)
	       AND request_id	= xx_emf_pkg.G_REQUEST_ID
	       AND process_code	= xx_emf_cn_pkg.CN_NEW;

	COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
	     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while updating staging records status: '||SQLERRM);

    END update_staging_records;

    -- --------------------------------------------------------------------------------------- --
    --	Function to Find Max

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

    -- --------------------------------------------------------------------------------------- --
    --	Function for pre validations

    FUNCTION pre_validations
    RETURN NUMBER
    IS
	x_error_code	    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;


    BEGIN

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

    -- --------------------------------------------------------------------------------------- --
    --	Function to validate data

    FUNCTION data_validation( p_cnv_hdr_rec IN OUT xx_ar_receipt_conv_pkg.g_rcpt_rec_type
                             ,p_rcpt_method IN VARCHAR2
                          ) RETURN NUMBER
    IS

	x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

        ------------------------------------------------------------------------------------------

	FUNCTION is_currency_null(p_currency IN VARCHAR2)
	RETURN NUMBER
	IS
	    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	BEGIN
	    IF p_currency IS NULL THEN
		dbg_med('Currency Number is Null ');
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Invalid : Currency is Null'
			 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			 ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
			 ,p_record_identifier_3 => p_currency
			);
            END IF;
	    RETURN x_error_code;
	EXCEPTION
	WHEN OTHERS THEN
	   dbg_med('Unexpected error while checking null for Currency');
	   x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
	   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		            ,p_category    => xx_emf_cn_pkg.CN_VALID
		            ,p_error_text  => 'Unexpected error while checking null for Currency'
		            ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		            ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
		            ,p_record_identifier_3 => p_currency
		           );
           RETURN  x_error_code;

	END is_currency_null;

        ------------------------------------------------------------------------------------------

	FUNCTION is_receipt_method_null(p_receipt_method IN VARCHAR2)
	RETURN NUMBER
	IS
	    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	BEGIN
	    IF p_receipt_method IS NULL THEN
		dbg_med('Receipt_method is Null ');
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			         ,p_category    => xx_emf_cn_pkg.CN_VALID
			         ,p_error_text  => 'Invalid : Receipt_method is Null'
			         ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			         ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
			         ,p_record_identifier_3 => p_receipt_method
			          );
            END IF;
	    RETURN x_error_code;
	EXCEPTION
	WHEN OTHERS THEN
	   dbg_med('Unexpected error while checking null for Receipt_method');
	   x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
	   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		            ,p_category    => xx_emf_cn_pkg.CN_VALID
		            ,p_error_text  => 'Unexpected error while checking null for Receipt_method'
		            ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		            ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
		            ,p_record_identifier_3 => p_receipt_method
		           );
           RETURN  x_error_code;

	END is_receipt_method_null;

	------------------------------------------------------------------------------------------

	FUNCTION is_amt_null(p_amt IN NUMBER)
	RETURN NUMBER
	IS
	    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	BEGIN
	    IF NVL(p_amt,0) = 0 OR p_amt < 0 THEN
		dbg_med('Amount is Null ');
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Invalid : Amount is Null or Nagative'
			 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			 ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
			 ,p_record_identifier_3 => p_amt
			);
            END IF;
	    RETURN x_error_code;
	EXCEPTION
	WHEN OTHERS THEN
	   dbg_med('Unexpected error while checking null for Amount');
	   x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
	   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		            ,p_category    => xx_emf_cn_pkg.CN_VALID
		            ,p_error_text  => 'Unexpected error while checking null for Amount'
		            ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		            ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
		            ,p_record_identifier_3 => p_amt
		           );
           RETURN  x_error_code;

	END is_amt_null;

	------------------------------------------------------------------------------------------

	FUNCTION is_rcpt_no(p_rcpt_no IN VARCHAR2)
	RETURN NUMBER
	IS
	    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	BEGIN
	    IF p_rcpt_no IS NULL THEN
		dbg_med('Receipt Number is Null ');
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Invalid : Receipt Number is Null'
			 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			 ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
			 ,p_record_identifier_3 => p_rcpt_no
			);
            END IF;
	    RETURN x_error_code;
	EXCEPTION
	WHEN OTHERS THEN
	   dbg_med('Unexpected error while checking null for Amount');
	   x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
	   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		            ,p_category    => xx_emf_cn_pkg.CN_VALID
		            ,p_error_text  => 'Unexpected error while checking null for Receipt Number'
		            ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		            ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
		            ,p_record_identifier_3 => p_rcpt_no
		           );
           RETURN  x_error_code;

	END is_rcpt_no;

	------------------------------------------------------------------------------------------

	FUNCTION is_rcpt_date(p_rcpt_date IN DATE)
	RETURN NUMBER
	IS
	    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	BEGIN
	    IF p_rcpt_date IS NULL THEN
		dbg_med('Receipt Date is Null ');
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Invalid : Receipt Date is Null'
			 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			 ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
			 ,p_record_identifier_3 => p_rcpt_date
			);
            END IF;
	    RETURN x_error_code;
	EXCEPTION
	WHEN OTHERS THEN
	   dbg_med('Unexpected error while checking null for Receipt Date');
	   x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
	   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		            ,p_category    => xx_emf_cn_pkg.CN_VALID
		            ,p_error_text  => 'Unexpected error while checking null for Receipt Date'
		            ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		            ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
		            ,p_record_identifier_3 => p_rcpt_date
		           );
           RETURN  x_error_code;

	END is_rcpt_date;
	------------------------------------------------------------------------------------------

        FUNCTION is_exg_rate ( p_exg_rate          IN    NUMBER,
                               p_currency          IN    VARCHAR2)
	RETURN NUMBER
	IS
	    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	BEGIN
	    IF p_exg_rate IS NULL AND p_currency <> 'USD' THEN
		dbg_med('Exchange Rate is Null ');
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Invalid : Exchange Rate is Null'
			 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			 ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
			 ,p_record_identifier_3 => p_exg_rate
			);
            END IF;
	    RETURN x_error_code;
	EXCEPTION
	WHEN OTHERS THEN
	   dbg_med('Unexpected error while checking null for Exchange Rate');
	   x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
	   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		            ,p_category    => xx_emf_cn_pkg.CN_VALID
		            ,p_error_text  => 'Unexpected error while checking null for Exchange Rate'
		            ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		            ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
		            ,p_record_identifier_3 => p_exg_rate
		           );
           RETURN  x_error_code;

	END is_exg_rate;

	------------------------------------------------------------------------------------------

        FUNCTION is_rcpt_status ( p_status   IN    VARCHAR2)
	RETURN NUMBER
	IS
	    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	BEGIN
	    IF p_status IS NULL THEN
		dbg_med('Receipt Status is Null ');
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Invalid : Receipt Status is Null'
			 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			 ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
			 ,p_record_identifier_3 => p_status
			);
            ELSIF p_status NOT IN ('ACC','UNAPP','UNID') THEN -- AR lookup PAYMENT_TYPE
		dbg_med('Receipt Status is Invalid ');
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Invalid : Receipt Status'
			 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			 ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
			 ,p_record_identifier_3 => p_status
			);
            END IF;
	    RETURN x_error_code;
	EXCEPTION
	WHEN OTHERS THEN
	   dbg_med('Unexpected error while checking null for Receipt Status');
	   x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
	   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		            ,p_category    => xx_emf_cn_pkg.CN_VALID
		            ,p_error_text  => 'Unexpected error while checking null for Receipt Status'
		            ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		            ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
		            ,p_record_identifier_3 => p_status
		           );
           RETURN  x_error_code;

	END is_rcpt_status;

	------------------------------------------------------------------------------------------
        FUNCTION is_customer_acc_valid ( p_cust_acc      IN    VARCHAR2,
                                         x_cust_acc_id   OUT   NUMBER,
                                         x_cust_id       OUT   NUMBER)
        RETURN NUMBER
        IS
           x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
        BEGIN
           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Validation for Customer Acc with orig_system_reference');
             SELECT  hca.cust_account_id
                    ,hca.party_id
               INTO  x_cust_acc_id
                    ,x_cust_id
               FROM  hz_cust_accounts hca
              --WHERE  hca.account_number = p_cust_acc;
              WHERE  hca.orig_system_reference = p_cust_acc;

            RETURN x_error_code;
        EXCEPTION
         WHEN NO_DATA_FOUND
          THEN
             BEGIN
                x_error_code := xx_emf_cn_pkg.cn_success;
                xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Validation for Customer Acc with account_number');
                SELECT  hca.cust_account_id
                       ,hca.party_id
                  INTO  x_cust_acc_id
                       ,x_cust_id
                  FROM  hz_cust_accounts hca
                 WHERE  hca.account_number = p_cust_acc;

                 RETURN x_error_code;
             EXCEPTION
                WHEN NO_DATA_FOUND
                  THEN
                 xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
                 x_error_code := xx_emf_cn_pkg.cn_rec_err;
                 xx_emf_pkg.error
                      (p_severity                 => xx_emf_cn_pkg.cn_medium,
                       p_category                 => xx_emf_cn_pkg.CN_VALID,
                       p_error_text               => 'Invalid Customer Acc => '
                                                     || p_cust_acc
                                                     || '-'
                                                     || xx_emf_cn_pkg.cn_no_data,
                       p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                       p_record_identifier_2      => p_cnv_hdr_rec.receipt_number,
                       p_record_identifier_3      => p_cust_acc
                       );
                RETURN x_error_code;
             END;
        WHEN TOO_MANY_ROWS
             THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.CN_VALID,
                  p_error_text               => 'Invalid Customer Acc => '
                                                || p_cust_acc
                                                || '-'
                                                || xx_emf_cn_pkg.cn_too_many,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.receipt_number,
                  p_record_identifier_3      => p_cust_acc
                 );
            RETURN x_error_code;
        WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Customer Acc Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.CN_VALID,
                  p_error_text               => 'Invalid Customer Acc => '
                                                || p_cust_acc
                                                || '-'
                                                || SQLERRM,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.receipt_number,
                  p_record_identifier_3      => p_cust_acc
                 );
            RETURN x_error_code;
        END is_customer_acc_valid;
        ------------------------------------------------------------------------------------------

	FUNCTION is_batch_source ( p_receipt_source      IN    VARCHAR2)
	RETURN NUMBER
	IS
	    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	BEGIN
	    IF p_receipt_source IS NULL THEN
		dbg_med('Batch Source is Null ');
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			 ,p_category    => xx_emf_cn_pkg.CN_VALID
			 ,p_error_text  => 'Invalid : Batch Source is Null'
			 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			 ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
			 ,p_record_identifier_3 => p_receipt_source
			);
            END IF;
	    RETURN x_error_code;
	EXCEPTION
	WHEN OTHERS THEN
	   dbg_med('Unexpected error while checking null for Batch Source');
	   x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
	   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		            ,p_category    => xx_emf_cn_pkg.CN_VALID
		            ,p_error_text  => 'Unexpected error while checking null for Batch Source'
		            ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		            ,p_record_identifier_2 => p_cnv_hdr_rec.receipt_number
		            ,p_record_identifier_3 => p_receipt_source
		           );
           RETURN  x_error_code;

	END is_batch_source;

	------------------------------------------------------------------------------------------

        FUNCTION is_rcpt_batch_source ( p_receipt_source      IN    VARCHAR2,
                                        x_receipt_source_id   OUT   NUMBER,
                                        x_org_id              OUT   NUMBER)
        RETURN NUMBER
        IS
           x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
        BEGIN
           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                'Validation for Batch Source');
             SELECT  batch_source_id
                    ,org_id
               INTO  x_receipt_source_id
                    ,x_org_id
               FROM  ar_batch_sources_all
              WHERE  name = p_receipt_source;

            RETURN x_error_code;
        EXCEPTION
           WHEN TOO_MANY_ROWS
             THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.CN_VALID,
                  p_error_text               => 'Invalid Batch Source => '
                                                || p_receipt_source
                                                || '-'
                                                || xx_emf_cn_pkg.cn_too_many,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.receipt_number,
                  p_record_identifier_3      => p_receipt_source
                 );
            RETURN x_error_code;
        WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.CN_VALID,
                  p_error_text               => 'Invalid Batch Source => '
                                                || p_receipt_source
                                                || '-'
                                                || xx_emf_cn_pkg.cn_no_data,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.receipt_number,
                  p_record_identifier_3      => p_receipt_source
                 );
            RETURN x_error_code;
        WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Batch Source Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.CN_VALID,
                  p_error_text               => 'Invalid Batch Source => '
                                                || p_receipt_source
                                                || '-'
                                                || SQLERRM,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.receipt_number,
                  p_record_identifier_3      => p_receipt_source
                 );
            RETURN x_error_code;
        END is_rcpt_batch_source;
	------------------------------------------------------------------------------------------

        FUNCTION is_rcpt_method ( p_rcpt_method         IN    VARCHAR2,
                                  x_receipt_method_id   OUT   NUMBER)
        RETURN NUMBER
        IS
           x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
        BEGIN
           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                'Validation for Receipt Method');
             SELECT  receipt_method_id
               INTO  x_receipt_method_id
               FROM  ar_receipt_methods
              WHERE  UPPER(name) = UPPER(p_rcpt_method);

            RETURN x_error_code;
        EXCEPTION
           WHEN TOO_MANY_ROWS
             THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.CN_VALID,
                  p_error_text               => 'Invalid Receipt Method => '
                                                || p_rcpt_method
                                                || '-'
                                                || xx_emf_cn_pkg.cn_too_many,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.receipt_number,
                  p_record_identifier_3      => p_rcpt_method
                 );
            RETURN x_error_code;
        WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.CN_VALID,
                  p_error_text               => 'Invalid Receipt Method => '
                                                || p_rcpt_method
                                                || '-'
                                                || xx_emf_cn_pkg.cn_no_data,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.receipt_number,
                  p_record_identifier_3      => p_rcpt_method
                 );
            RETURN x_error_code;
        WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Receipt Method Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.CN_VALID,
                  p_error_text               => 'Invalid Receipt Method => '
                                                || p_rcpt_method
                                                || '-'
                                                || SQLERRM,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.receipt_number,
                  p_record_identifier_3      => p_rcpt_method
                 );
            RETURN x_error_code;
        END is_rcpt_method;
	------------------------------------------------------------------------------------------
        FUNCTION is_exchange_type_valid ( p_exchange_type   IN    VARCHAR2)
        RETURN NUMBER
        IS
           x_type VARCHAR2(30);
        BEGIN
           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                'Validation for Customer Acc');
             SELECT  user_conversion_type
               INTO  x_type
               FROM  gl_daily_conversion_types
              WHERE  user_conversion_type = p_exchange_type;

            RETURN x_error_code;
        EXCEPTION
           WHEN TOO_MANY_ROWS
             THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.CN_VALID,
                  p_error_text               => 'Invalid Exchange Conversion Type => '
                                                || p_exchange_type
                                                || '-'
                                                || xx_emf_cn_pkg.cn_too_many,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.receipt_number,
                  p_record_identifier_3      => p_exchange_type
                 );
            RETURN x_error_code;
        WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.CN_VALID,
                  p_error_text               => 'Invalid Exchange Conversion Type => '
                                                || p_exchange_type
                                                || '-'
                                                || xx_emf_cn_pkg.cn_no_data,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.receipt_number,
                  p_record_identifier_3      => p_exchange_type
                 );
            RETURN x_error_code;
        WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Exchange Conversion Type Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.CN_VALID,
                  p_error_text               => 'Invalid Exchange Conversion Type => '
                                                || p_exchange_type
                                                || '-'
                                                || SQLERRM,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.receipt_number,
                  p_record_identifier_3      => p_exchange_type
                 );
            RETURN x_error_code;
        END is_exchange_type_valid;
	------------------------------------------------------------------------------------------

        FUNCTION fuct_currency ( p_org_id   IN    NUMBER
                                ,x_currency OUT   VARCHAR2)
        RETURN NUMBER
        IS
           x_type VARCHAR2(30);
        BEGIN
           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Fetching functional Currency');

          SELECT  glt.currency_code
            INTO  x_currency
            FROM  hr_operating_units hru
                 ,gl_sets_of_books   glt
           WHERE  hru.set_of_books_id = glt.set_of_books_id
             AND  hru.organization_id = p_org_id;
             RETURN x_error_code;
        EXCEPTION
           WHEN TOO_MANY_ROWS
             THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.CN_VALID,
                  p_error_text               => 'Invalid functional Currency => '
                                                || p_org_id
                                                || '-'
                                                || xx_emf_cn_pkg.cn_too_many,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.receipt_number,
                  p_record_identifier_3      => p_org_id
                 );
            RETURN x_error_code;
        WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.CN_VALID,
                  p_error_text               => 'Invalid functional Currency => '
                                                || p_org_id
                                                || '-'
                                                || xx_emf_cn_pkg.cn_no_data,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.receipt_number,
                  p_record_identifier_3      => p_org_id
                 );
            RETURN x_error_code;
        WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In functional Currency derivation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.CN_VALID,
                  p_error_text               => 'Invalid functional Currency => '
                                                || p_org_id
                                                || '-'
                                                || SQLERRM,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.receipt_number,
                  p_record_identifier_3      => p_org_id
                 );
            RETURN x_error_code;
        END fuct_currency;
	------------------------------------------------------------------------------------------

    BEGIN

       g_api_name := 'Data_validation';
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations');

       x_error_code_temp := is_currency_null(p_cnv_hdr_rec.currency_code);
       x_error_code := find_max (x_error_code, x_error_code_temp);

       x_error_code_temp := is_receipt_method_null(p_cnv_hdr_rec.receipt_method_name);
       x_error_code := find_max (x_error_code, x_error_code_temp);

       x_error_code_temp := is_amt_null(p_cnv_hdr_rec.amount);
       x_error_code := find_max (x_error_code, x_error_code_temp);

       x_error_code_temp := is_rcpt_no(p_cnv_hdr_rec.receipt_number);
       x_error_code := find_max (x_error_code, x_error_code_temp);

       x_error_code_temp := is_rcpt_date(p_cnv_hdr_rec.receipt_date);
       x_error_code := find_max (x_error_code, x_error_code_temp);

       x_error_code_temp := is_exg_rate( p_cnv_hdr_rec.exchange_rate
                                        ,p_cnv_hdr_rec.currency_code);
       x_error_code := find_max (x_error_code, x_error_code_temp);

       x_error_code_temp := is_rcpt_status(p_cnv_hdr_rec.receipt_status);
       x_error_code := find_max (x_error_code, x_error_code_temp);

       IF p_cnv_hdr_rec.customer_number IS NOT NULL THEN
          --IF (p_cnv_hdr_rec.customer_number <> 'O11_' AND p_cnv_hdr_rec.receipt_status <> 'UNID') THEN
          IF p_cnv_hdr_rec.receipt_status <> 'UNID' THEN
             x_error_code_temp := is_customer_acc_valid(  p_cnv_hdr_rec.customer_number
                                                         ,p_cnv_hdr_rec.customer_acc_id
                                                         ,p_cnv_hdr_rec.customer_id);
             x_error_code := find_max (x_error_code, x_error_code_temp);
          END IF;
       END IF;

       IF p_cnv_hdr_rec.receipt_batch_source IS NOT NULL THEN
          x_error_code_temp := is_batch_source(p_cnv_hdr_rec.receipt_batch_source);
          x_error_code := find_max (x_error_code, x_error_code_temp);

          x_error_code_temp := is_rcpt_batch_source(  p_cnv_hdr_rec.receipt_batch_source
                                                     ,p_cnv_hdr_rec.receipt_batch_source_id
                                                     ,p_cnv_hdr_rec.org_id);
          x_error_code := find_max (x_error_code, x_error_code_temp);
       END IF;

       IF p_cnv_hdr_rec.receipt_method_name IS NOT NULL THEN
          x_error_code_temp := is_rcpt_method(  p_cnv_hdr_rec.receipt_method_name--p_rcpt_method
                                               ,p_cnv_hdr_rec.receipt_method_id);
          x_error_code := find_max (x_error_code, x_error_code_temp);
       END IF;

       IF p_cnv_hdr_rec.usr_exchange_rate_type IS NOT NULL THEN
          x_error_code_temp := is_exchange_type_valid(p_cnv_hdr_rec.usr_exchange_rate_type);
          x_error_code := find_max (x_error_code, x_error_code_temp);
       END IF;

       IF p_cnv_hdr_rec.org_id IS NOT NULL THEN
          x_error_code_temp := fuct_currency(  p_cnv_hdr_rec.org_id
                                              ,p_cnv_hdr_rec.fuct_currency_code);
          x_error_code := find_max (x_error_code, x_error_code_temp);
       END IF;
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
    END data_validation;

    -- --------------------------------------------------------------------------------------- --
    --  Function for Data Derivations

    FUNCTION data_derivations(p_cnv_hdr_rec IN OUT xx_ar_receipt_conv_pkg.g_rcpt_rec_type
                          )
     RETURN NUMBER
     IS
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

    BEGIN
	g_api_name := 'data_derivations';

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
    END data_derivations;

    -- --------------------------------------------------------------------------------------- --
    --	Function for post validation

    FUNCTION post_validations
    RETURN NUMBER
    IS
	x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
	g_api_name := 'main.post_validations';
	RETURN x_error_code;
    EXCEPTION
	WHEN xx_emf_pkg.G_E_REC_ERROR THEN
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, '8');
    	    x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	    RETURN x_error_code;
	WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, '9');
	    x_error_code := xx_emf_cn_pkg.cn_prc_err;
	    RETURN x_error_code;
	WHEN OTHERS THEN
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, '9');
	    x_error_code := xx_emf_cn_pkg.cn_prc_err;
	    RETURN x_error_code;
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Completed Post-Validations');
    END post_validations;

    -- --------------------------------------------------------------------------------------- --
    --	Procedure to count staging table record for Routing Headers

    PROCEDURE update_record_count(pr_validate_and_load IN VARCHAR2)
	IS
	CURSOR c_get_total_cnt IS
	SELECT COUNT (1) total_count
	  FROM xx_ar_cash_receipt_stg
	 WHERE batch_id = G_BATCH_ID
	   --AND receipt_method_name = NVL(G_RCPT_METHOD,receipt_method_name)
	   AND request_id = xx_emf_pkg.G_REQUEST_ID;

	x_total_cnt NUMBER;

	CURSOR c_get_error_cnt IS
	SELECT SUM(error_count)
	  FROM (
		SELECT COUNT (1) error_count
		  FROM xx_ar_cash_receipt_stg
		 WHERE batch_id   = G_BATCH_ID
		   --AND receipt_method_name = NVL(G_RCPT_METHOD,receipt_method_name)
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

	x_error_cnt NUMBER;

	CURSOR c_get_warning_cnt IS
	SELECT COUNT (1) warn_count
	  FROM xx_ar_cash_receipt_stg
	 WHERE batch_id = G_BATCH_ID
	   --AND receipt_method_name = NVL(G_RCPT_METHOD,receipt_method_name)
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

	x_warn_cnt NUMBER;

	CURSOR c_get_success_cnt IS
	SELECT COUNT (1) success_count
	  FROM xx_ar_cash_receipt_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND receipt_method_name = NVL(G_RCPT_METHOD,receipt_method_name)
	   --AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

	x_success_cnt NUMBER;

	-- Added for if p_validate_only_flag is set to VALIDATE_ONLY Starts
	CURSOR c_get_success_valid_cnt IS
	SELECT COUNT (1) success_count
	  FROM xx_ar_cash_receipt_stg
	 WHERE batch_id = G_BATCH_ID
	   AND request_id = xx_emf_pkg.G_REQUEST_ID
	   --AND receipt_method_name = NVL(G_RCPT_METHOD,receipt_method_name)
	   --AND process_code = xx_emf_cn_pkg.CN_POSTVAL
	   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

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

	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, ' Record processing status - ');
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, ' x_total_cnt : '|| x_total_cnt );
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, ' x_success_cnt : '|| x_success_cnt );
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, ' x_warn_cnt : '|| x_warn_cnt );
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, ' x_error_cnt : '|| x_error_cnt );
	xx_emf_pkg.update_recs_cnt
	(
	    p_total_recs_cnt   => x_total_cnt,
	    p_success_recs_cnt => x_success_cnt,
	    p_warning_recs_cnt => x_warn_cnt,
	    p_error_recs_cnt   => x_error_cnt
	);
    END update_record_count;

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- --------------------------------------------------------------------------------------- --
    --  Main Procedure
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    PROCEDURE main( x_errbuf              OUT      VARCHAR2
                   ,x_retcode             OUT      VARCHAR2
                   ,p_batch_id            IN       VARCHAR2
                   ,p_restart_flag        IN       VARCHAR2
                   ,p_override_flag       IN       VARCHAR2
                   ,p_validate_and_load   IN       VARCHAR2
                   ,p_gl_date             IN       VARCHAR2
                   ,p_rcpt_method         IN       VARCHAR2
                ) IS

    ----------------------- Private Variable Declaration Section -----------------------
    --Stop the program with EMF error header insertion fails
      l_process_status NUMBER;

      x_error_code          NUMBER                := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp     NUMBER                := xx_emf_cn_pkg.CN_SUCCESS;

      --x_cust_cc_table   g_rept_tbl_type;
      x_rcpt_table          g_rcpt_tbl_type;
      x_gl_date             DATE         := FND_DATE.CANONICAL_TO_DATE (p_gl_date);

    --CURSOR c_cust_cc_stg ( cp_process_status VARCHAR2)
    CURSOR c_rcpt_stg ( cp_process_status VARCHAR2)
        IS
        SELECT *
          FROM xx_ar_cash_receipt_stg
        WHERE batch_id     = G_BATCH_ID
          AND request_id   = xx_emf_pkg.G_REQUEST_ID
          AND process_code = cp_process_status
          --AND receipt_method_name = NVL(G_RCPT_METHOD,receipt_method_name)
          AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
        ORDER BY record_number;


    -- --------------------------------------------------------------------------------------- --
    --	Procedure to update Routing Header error record status

    PROCEDURE upd_rec_status_cust_cc (
              p_conv_hdr_rec  IN OUT  g_rcpt_rec_type,
              p_error_code    IN      VARCHAR2
       ) IS
    BEGIN
        g_api_name := 'main.upd_rec_status_cust_cc';
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update record status...');

        IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
        THEN
           p_conv_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
        ELSE
           p_conv_hdr_rec.error_code := xx_intg_common_pkg.find_max(p_error_code, NVL (p_conv_hdr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));
        END IF;
        p_conv_hdr_rec.process_code := G_STAGE;

    END upd_rec_status_cust_cc;

    -- --------------------------------------------------------------------------------------- --
    --	    Procedure to update Routing Header staging records

    PROCEDURE update_int_records_rcptcc (p_cnv_rcpt_table IN g_rcpt_tbl_type)
    IS
      x_last_update_date      DATE := SYSDATE;
      x_last_updated_by       NUMBER := fnd_global.user_id;
      x_last_update_login     NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
      indx                    NUMBER;

      PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
       g_api_name := 'main.update_int_records_rcptcc';

	FOR indx IN 1 .. p_cnv_rcpt_table.COUNT LOOP

	  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_rcpt_table(indx).process_code ' || p_cnv_rcpt_table(indx).process_code);
	  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_rcpt_table(indx).error_code ' || p_cnv_rcpt_table(indx).error_code);

	  UPDATE xx_ar_cash_receipt_stg
	     SET batch_id                    = p_cnv_rcpt_table(indx).batch_id
                ,source_system_name          = p_cnv_rcpt_table(indx).source_system_name
                ,receipt_batch_source        = p_cnv_rcpt_table(indx).receipt_batch_source
                ,receipt_batch_source_id     = p_cnv_rcpt_table(indx).receipt_batch_source_id
                ,currency_code               = p_cnv_rcpt_table(indx).currency_code
                ,usr_exchange_rate_type      = p_cnv_rcpt_table(indx).usr_exchange_rate_type
                ,exchange_rate               = p_cnv_rcpt_table(indx).exchange_rate
                ,amount                      = p_cnv_rcpt_table(indx).amount
                ,receipt_number              = p_cnv_rcpt_table(indx).receipt_number
                ,receipt_date                = p_cnv_rcpt_table(indx).receipt_date
                ,receipt_status              = p_cnv_rcpt_table(indx).receipt_status
                ,gl_date                     = x_gl_date--p_cnv_rcpt_table(indx).gl_date
                ,customer_id                 = p_cnv_rcpt_table(indx).customer_id
                ,customer_number             = p_cnv_rcpt_table(indx).customer_number
                ,customer_acc_id             = p_cnv_rcpt_table(indx).customer_acc_id
                ,receipt_method_name         = p_cnv_rcpt_table(indx).receipt_method_name
                ,receipt_method_id           = p_cnv_rcpt_table(indx).receipt_method_id
                ,comments                    = p_cnv_rcpt_table(indx).comments
                ,status                      = p_cnv_rcpt_table(indx).status
                ,org_id                      = p_cnv_rcpt_table(indx).org_id
                ,fuct_currency_code          = p_cnv_rcpt_table(indx).fuct_currency_code
                ,record_number               = p_cnv_rcpt_table(indx).record_number
                ,process_code                = p_cnv_rcpt_table(indx).process_code
                ,error_code                  = p_cnv_rcpt_table(indx).error_code
                ,request_id                  = p_cnv_rcpt_table(indx).request_id
                ,creation_date               = p_cnv_rcpt_table(indx).creation_date
                ,created_by                  = p_cnv_rcpt_table(indx).created_by
                ,last_update_date            = p_cnv_rcpt_table(indx).last_update_date
                ,last_updated_by             = p_cnv_rcpt_table(indx).last_updated_by
                ,last_update_login           = p_cnv_rcpt_table(indx).last_update_login
          WHERE record_number = p_cnv_rcpt_table(indx).record_number
	    AND batch_id = G_BATCH_ID;
	END LOOP;
	COMMIT;
    END update_int_records_rcptcc;

    -- --------------------------------------------------------------------------------------- --
    --		Procedure to mark records complete

    PROCEDURE mark_records_complete (
	p_process_code	VARCHAR2
       ) IS
	x_last_update_date       DATE   := SYSDATE;
	x_last_updated_by        NUMBER := fnd_global.user_id;
	x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
	g_api_name := 'main.mark_records_complete';

	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'10');--**DS
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of mark records complete...');

	    UPDATE xx_ar_cash_receipt_stg	--Header
	       SET process_code      = G_STAGE,
		   error_code        = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
		   last_updated_by   = x_last_updated_by,
		   last_update_date  = x_last_update_date,
		   last_update_login = x_last_update_login
	     WHERE batch_id     = G_BATCH_ID
	       AND request_id   = xx_emf_pkg.G_REQUEST_ID
	       AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
	       AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

	COMMIT;

    EXCEPTION
	    WHEN OTHERS THEN
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in Update of mark_records_complete '||SQLERRM);
    END mark_records_complete;

    PROCEDURE apps_init
    IS
    BEGIN
        mo_global.init('AR');
        fnd_global.apps_initialize(user_id      => G_USER_ID,
                                   resp_id      => G_RESP_ID,
                                   resp_appl_id => G_RESP_APPL_ID);

    END apps_init;
    -- --------------------------------------------------------------------------------------- --
    --	Function to call standard APIs to load data into Oracle tables
    -- --------------------------------------------------------------------------------------- --

    FUNCTION process_data
     RETURN NUMBER
    IS

	--cursor to select data
	CURSOR c_xx_rcpt_data(cp_process_status VARCHAR2) IS
         SELECT *
           FROM xx_ar_cash_receipt_stg
          WHERE batch_id     = G_BATCH_ID
	    AND request_id   = xx_emf_pkg.G_REQUEST_ID
	    AND process_code = cp_process_status
	    AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
	  ORDER BY record_number;

          x_process_code                  VARCHAR2(30);
	  x_error_code	                  NUMBER;
	  x_return_code	                  VARCHAR2(15)  := xx_emf_cn_pkg.CN_SUCCESS;
	  p_init_msg_list                 VARCHAR2(200) := fnd_api.g_true;
	  x_msg_count                     NUMBER;
	  x_msg_data                      VARCHAR2(2000);
	  x_return_status	          VARCHAR2(15)  := xx_emf_cn_pkg.CN_SUCCESS;
	  l_msg_index_out                 VARCHAR2(400);

	  l_payercontext_rec_type         iby_fndcpt_common_pub.payercontext_rec_type;
	  l_pmtinstrassignment_rec_type   iby_fndcpt_setup_pub.pmtinstrassignment_rec_type;
	  l_pmtinstr_rec_type             iby_fndcpt_setup_pub.pmtinstrument_rec_type;
	  l_result_rec                    iby_fndcpt_common_pub.result_rec_type;

          x_msg                           VARCHAR2(2000);
          x_record_skip                   EXCEPTION;
          x_cr_id                         NUMBER;

          x_exchange_rate_type            VARCHAR2(30);
          x_exchange_rate                 NUMBER;
          x_exchange_date                 DATE;
    BEGIN
       apps_init;
       g_api_name := 'main.process_data';
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside Process Data');

       FOR r_xx_rcpt_data IN c_xx_rcpt_data(xx_emf_cn_pkg.CN_POSTVAL)
       LOOP
       BEGIN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Receipt Creation....');
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'r_xx_rcpt_data.usr_exchange_rate_type ->'||r_xx_rcpt_data.usr_exchange_rate_type);
              ---
              mo_global.set_policy_context('S',r_xx_rcpt_data.org_id);
              x_return_status := NULL;
              x_msg_count     := NULL;
              x_msg_data      := NULL;
              l_msg_index_out := NULL;

              x_exchange_rate_type := NULL;
              x_exchange_rate      := NULL;
              x_exchange_date      := NULL;
              ---
              IF r_xx_rcpt_data.currency_code = r_xx_rcpt_data.fuct_currency_code THEN
                 x_exchange_rate_type := NULL;
                 x_exchange_rate      := NULL;
                 x_exchange_date      := NULL;
              ELSE
                 x_exchange_rate_type := r_xx_rcpt_data.usr_exchange_rate_type;
                 x_exchange_rate      := r_xx_rcpt_data.exchange_rate;
                 x_exchange_date      := r_xx_rcpt_data.receipt_date;
              END IF;
              ar_receipt_api_pub.Create_cash(
                  p_api_version                  => 1.0
                 ,p_init_msg_list                => FND_API.G_TRUE
                 ,p_commit                       => FND_API.G_FALSE
                 ,p_validation_level             => FND_API.G_VALID_LEVEL_FULL
                 ,x_return_status                => x_return_status
                 ,x_msg_count                    => x_msg_count
                 ,x_msg_data                     => x_msg_data
                 ,p_currency_code                => r_xx_rcpt_data.currency_code
                 ,p_exchange_rate_type           => x_exchange_rate_type--r_xx_rcpt_data.usr_exchange_rate_type
                 ,p_exchange_rate                => x_exchange_rate--r_xx_rcpt_data.exchange_rate
                 ,p_exchange_rate_date           => x_exchange_date--r_xx_rcpt_data.receipt_date
                 ,p_amount                       => r_xx_rcpt_data.amount
                 ,p_receipt_number               => r_xx_rcpt_data.receipt_number
                 ,p_receipt_date                 => r_xx_rcpt_data.receipt_date
                 ,p_gl_date                      => x_gl_date
                 ,p_customer_id                  => r_xx_rcpt_data.customer_acc_id
                 ,p_receipt_method_id            => r_xx_rcpt_data.receipt_method_id
                 ,p_called_from                  => 'pl/sql Script'
                 ,p_comments                     => r_xx_rcpt_data.comments
                 ,p_cr_id                        => x_cr_id);

              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Create_cash x_return_status=' || x_return_status);
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cr_id=' || x_cr_id);

              IF x_return_status = 'S' AND x_cr_id IS NOT NULL THEN
                 ---
                 IF r_xx_rcpt_data.receipt_status = 'ACC' THEN
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before apply_on_account....');
                    x_return_status := NULL;
                    x_msg_count     := NULL;
                    x_msg_data      := NULL;
                    l_msg_index_out := NULL;

                    ar_receipt_api_pub.apply_on_account
                      (  p_api_version      => 1.0
                        ,p_init_msg_list    => FND_API.G_TRUE
                        ,p_commit           => FND_API.G_FALSE
                        ,p_validation_level => FND_API.G_VALID_LEVEL_FULL
                        ,x_return_status    => x_return_status
                        ,x_msg_count        => x_msg_count
                        ,x_msg_data         => x_msg_data
                        ,p_cash_receipt_id  => x_cr_id
                        ,p_org_id           => r_xx_rcpt_data.org_id
                        ,p_amount_applied   => r_xx_rcpt_data.amount
                        ,p_apply_date       => r_xx_rcpt_data.receipt_date
                        ,p_apply_gl_date    => x_gl_date
                      );

                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'apply_on_account x_return_status=' || x_return_status);

                    IF x_return_status <> 'S' THEN
                        x_msg := NULL;
                        FOR i IN 1 .. x_msg_count
                        LOOP
                            fnd_msg_pub.get ( p_msg_index          => i
                                             ,p_encoded            => fnd_api.g_false
                                             ,p_data               => x_msg_data
                                             ,p_msg_index_out      => l_msg_index_out
                                            );
                            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW
                                              ,    'x_msg_data(l_msg_index_out)='
                                               || x_msg_data
                                               || '('
                                               || l_msg_index_out
                                               || ')'
                                                );
                            x_msg := x_msg ||  x_msg_data;
                        END LOOP;

                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'API error: ar_receipt_api_pub.Create_cash');
                        x_error_code := xx_emf_cn_pkg.cn_rec_err;
                        xx_emf_pkg.error ( p_severity            => xx_emf_cn_pkg.cn_low
                                          ,p_category            => xx_emf_cn_pkg.CN_POSTVAL
                                          ,p_error_text          => 'After ar_receipt_api_pub.apply_on_account: x_msg:'||x_msg||' x_return_status:'||x_return_status
                                          ,p_record_identifier_1 => r_xx_rcpt_data.record_number
                                          ,p_record_identifier_2 => r_xx_rcpt_data.receipt_number
                                         );
                        ROLLBACK;
                        UPDATE  xx_ar_cash_receipt_stg
                           SET  error_code     = xx_emf_cn_pkg.CN_REC_ERR
                         WHERE  batch_id       = G_BATCH_ID
                           AND  record_number  = r_xx_rcpt_data.record_number;
                        COMMIT;
                        RAISE x_record_skip;
                    ELSE
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, ' apply_on_account on : '||r_xx_rcpt_data.record_number);
                    END IF; -- Success or error
                 END IF; -- 'ACC'
              ELSE -- S main API
                    x_msg := NULL;
                    FOR i IN 1 .. x_msg_count
                    LOOP
                       fnd_msg_pub.get (p_msg_index          => i
                                       ,p_encoded            => fnd_api.g_false
                                       ,p_data               => x_msg_data
                                       ,p_msg_index_out      => l_msg_index_out
                                       );
                       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW
                                         ,    'x_msg_data(l_msg_index_out)='
                                           || x_msg_data
                                           || '('
                                           || l_msg_index_out
                                           || ')'
                                         );
                       x_msg := x_msg ||  x_msg_data;
                    END LOOP;

                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'API error: ar_receipt_api_pub.Create_cash');
                    x_error_code := xx_emf_cn_pkg.cn_rec_err;
                    xx_emf_pkg.error ( p_severity            => xx_emf_cn_pkg.cn_low
                                      ,p_category            => xx_emf_cn_pkg.CN_POSTVAL
                                      ,p_error_text          => 'After ar_receipt_api_pub.Create_cash: x_msg:'||x_msg||' x_return_status:'||x_return_status
                                      ,p_record_identifier_1 => r_xx_rcpt_data.record_number
                                      ,p_record_identifier_2 => r_xx_rcpt_data.receipt_number
                                     );
                    ROLLBACK;
                    UPDATE  xx_ar_cash_receipt_stg
                       SET  error_code     = xx_emf_cn_pkg.CN_REC_ERR
                     WHERE  batch_id       = G_BATCH_ID
                       AND  record_number  = r_xx_rcpt_data.record_number;
                    COMMIT;
                    RAISE x_record_skip;
              END IF;
              COMMIT;
          EXCEPTION WHEN x_record_skip THEN
               NULL;
          END;
          END LOOP;
      RETURN x_return_code;
    EXCEPTION
	WHEN OTHERS THEN
	    x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while inserting into Standard Oracle Tables: ' ||SQLERRM);
	    xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.CN_HIGH
                                ,p_category            =>   xx_emf_cn_pkg.CN_TECH_ERROR
                                ,p_error_text          =>   sqlerrm
                                ,p_record_identifier_3 =>   'Process Receipt'
                             );
	    RETURN x_error_code;
    END process_data;

BEGIN
--Main Begin
 ----------------------------------------------------------------------------------------------------
--Initialize Trace
--Purpose : Set the program environment for Tracing
----------------------------------------------------------------------------------------------------

    x_retcode := xx_emf_cn_pkg.CN_SUCCESS;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Setting Environment');
    -- Set Env --
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling CC conversion Set_cnv_env');
    set_cnv_env (p_batch_id,p_rcpt_method,xx_emf_cn_pkg.CN_YES);

    -- include all the parameters to the conversion main here
    -- as medium log messages
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Starting main process with the following parameters');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_batch_id          -> '|| p_batch_id);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_restart_flag      -> '|| p_restart_flag);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_override_flag     -> '|| p_override_flag);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_validate_and_load -> '|| p_validate_and_load);
    --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_gl_date           -> '|| p_gl_date);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - Cononical p_gl_date -> '|| FND_DATE.CANONICAL_TO_DATE (p_gl_date));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_rcpt_method       -> '|| p_rcpt_method);


    -- Call procedure to update records with the current request_id
    -- So that we can process only those records
    -- This gives a better handling of restartability
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling mark_records_for_processing..');
    mark_records_for_processing ( p_restart_flag       => p_restart_flag
                                 ,p_override_flag      => p_override_flag);

    ------------------------------------------------------------------------------
    --	processing for Receipt Records
    ------------------------------------------------------------------------------

    -- Set the stage to Pre Validations
    set_stage (xx_emf_cn_pkg.CN_PREVAL);
    -- PRE_VALIDATIONS SHOULD BE RETAINED
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling xx_iby_cc_conv_pkg.pre_validations ..');

    x_error_code := pre_validations;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After pre_validations X_ERROR_CODE ' || X_ERROR_CODE);
    -- Update process code of staging records
    -- Update Header and Lines Level
    update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS);

    xx_emf_pkg.propagate_error ( x_error_code);

    -- Set the stage to data Validations
    set_stage (xx_emf_cn_pkg.CN_VALID);

    OPEN c_rcpt_stg ( xx_emf_cn_pkg.CN_PREVAL);
    LOOP
        FETCH c_rcpt_stg
           BULK COLLECT INTO x_rcpt_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

        FOR i IN 1 .. x_rcpt_table.COUNT
        LOOP
           BEGIN
              -- Perform Base App Validations
               x_error_code := data_validation(x_rcpt_table (i),p_rcpt_method);
               xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_rcpt_table (i).record_number|| ' is ' || x_error_code);
               upd_rec_status_cust_cc (x_rcpt_table (i), x_error_code);

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
                    update_int_records_rcptcc ( x_rcpt_table);
                    RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
               WHEN OTHERS
               THEN
                   xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_rcpt_table (i).record_number);
           END;
        END LOOP;
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_rcpt_table.count ' || x_rcpt_table.COUNT );
        update_int_records_rcptcc( x_rcpt_table);
        x_rcpt_table.DELETE;

        EXIT WHEN c_rcpt_stg%NOTFOUND;
    END LOOP;
    IF c_rcpt_stg%ISOPEN THEN
       CLOSE c_rcpt_stg;
    END IF;

    xx_emf_pkg.WRITE_LOG(xx_emf_cn_pkg.cn_low, fnd_global.conc_request_id || ' : Before Data Derivations');
    -- Once data-validations are complete the loop through the pre-interface records
    -- and perform data derivations on this table
    -- Set the stage to data derivations
    set_stage (xx_emf_cn_pkg.CN_DERIVE);
    OPEN c_rcpt_stg ( xx_emf_cn_pkg.CN_VALID);
    LOOP
       FETCH c_rcpt_stg
       BULK COLLECT INTO x_rcpt_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;
       FOR i IN 1 .. x_rcpt_table.COUNT
       LOOP
          BEGIN
             -- Perform Base App Validations
             x_error_code := data_derivations (x_rcpt_table (i));
             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_rcpt_table (i).record_number|| ' is ' || x_error_code);
             upd_rec_status_cust_cc (x_rcpt_table (i), x_error_code);
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
              update_int_records_rcptcc ( x_rcpt_table);
              RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
           WHEN OTHERS
           THEN
              xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_rcpt_table (i).record_number);
          END;
       END LOOP;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_rcpt_table.count ' || x_rcpt_table.COUNT );

       update_int_records_rcptcc ( x_rcpt_table);
       x_rcpt_table.DELETE;

       EXIT WHEN c_rcpt_stg%NOTFOUND;
    END LOOP;

    IF c_rcpt_stg%ISOPEN THEN
       CLOSE c_rcpt_stg;
    END IF;
    -- Set the stage to Post Validations
    set_stage (xx_emf_cn_pkg.CN_POSTVAL);

    x_error_code := post_validations;
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
    mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete_rtg post-validations X_ERROR_CODE ' || X_ERROR_CODE);
    xx_emf_pkg.propagate_error ( x_error_code);

    -- Perform data derivations and process data only if p_validate_only_flag is set to VALIDATE_AND_LOAD
    IF p_validate_and_load = G_VALIDATE_AND_LOAD THEN
       -- Set the stage to Process
       set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Before process_data');
       x_error_code := process_data;
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After process_data');

       mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After Process Data mark_records_complete x_error_code'||x_error_code);
       xx_emf_pkg.propagate_error ( x_error_code);
   END IF; --for validate only flag check

   update_record_count(p_validate_and_load);
   xx_emf_pkg.create_report;

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

END xx_ar_receipt_conv_pkg;
/
