DROP PACKAGE BODY APPS.XX_QP_PRICE_LIST_CNV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_QP_PRICE_LIST_CNV_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : Samir
 Creation Date  : 27-FEB-2012
 File Name      : XXQPPRICELISTCNVTL.pkb
 Description    : This script creates the body of the package xx_qp_price_list_cnv_pkg

Change History:

Version Date          Name        Remarks
------- -----------   --------    -------------------------------
1.0     27-FEB-2012   Samir     Initial development.
*/
----------------------------------------------------------------------

   -- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
   -- START RESTRICTIONS
      x_total_record        NUMBER := 0 ;
      x_success_record      NUMBER := 0 ;
      x_success_header      NUMBER := 0 ;
      x_total_header        NUMBER := 0 ;
      x_error_record        NUMBER := 0 ;
      x_grp_total           NUMBER := 0 ;
      x_grp_success         NUMBER := 0 ;
      x_grp_error           NUMBER := 0 ;

   PROCEDURE set_cnv_env (
      p_batch_id        VARCHAR2
    , p_required_flag   VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_yes
   )
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      g_batch_id := p_batch_id;
      -- Set the environment
      x_error_code := xx_emf_pkg.set_env;

      IF NVL ( p_required_flag, xx_emf_cn_pkg.cn_yes ) <> xx_emf_cn_pkg.cn_no
      THEN
         xx_emf_pkg.propagate_error ( x_error_code );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE xx_emf_pkg.g_e_env_not_set;
   END set_cnv_env;

   PROCEDURE mark_records_for_processing (
      p_restart_flag    IN   VARCHAR2
    , p_override_flag   IN   VARCHAR2
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      -- If the override is set records should not be purged from the pre-interface tables
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'mark_records_for_processing' );

      IF p_restart_flag = xx_emf_cn_pkg.cn_all_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- purge from pre-interface tables and oracle standard tables
            DELETE FROM xx_qp_price_list_pre
                  WHERE batch_id = g_batch_id;

            UPDATE xx_qp_price_list_stg
               SET request_id = xx_emf_pkg.g_request_id
                 , ERROR_CODE = xx_emf_cn_pkg.cn_null
                 , process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id;
         ELSE
            NULL;
         END IF;
      ELSIF p_restart_flag = xx_emf_cn_pkg.cn_err_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- Update staging table
            UPDATE xx_qp_price_list_stg
               SET request_id = xx_emf_pkg.g_request_id
                 , ERROR_CODE = xx_emf_cn_pkg.cn_null
                 , process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id
               AND (    process_code = xx_emf_cn_pkg.cn_new
                     OR (     process_code = xx_emf_cn_pkg.cn_preval
                          AND NVL ( ERROR_CODE, xx_emf_cn_pkg.cn_rec_err ) IN
                                                                ( xx_emf_cn_pkg.cn_rec_warn, xx_emf_cn_pkg.cn_rec_err )
                        )
                   );
         END IF;

         -- Update pre-interface table
         -- Scenario 1 Pre-Validation Stage
         UPDATE xx_qp_price_list_stg a
            SET request_id = xx_emf_pkg.g_request_id
              , ERROR_CODE = xx_emf_cn_pkg.cn_null
              , process_code = xx_emf_cn_pkg.cn_new
          WHERE batch_id = g_batch_id
            AND EXISTS (
                   SELECT 1
                     FROM xx_qp_price_list_pre
                    WHERE batch_id = g_batch_id
                      AND process_code = xx_emf_cn_pkg.cn_preval
                      AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_null, xx_emf_cn_pkg.cn_rec_warn, xx_emf_cn_pkg.cn_rec_err )
                      AND record_number = a.record_number );

         DELETE FROM xx_qp_price_list_pre
               WHERE batch_id = g_batch_id
                 AND process_code = xx_emf_cn_pkg.cn_preval
                 AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_null, xx_emf_cn_pkg.cn_rec_warn, xx_emf_cn_pkg.cn_rec_err );
         -- Scenario 2 Data Validation Stage
         UPDATE xx_qp_price_list_pre
            SET request_id = xx_emf_pkg.g_request_id
              , ERROR_CODE = xx_emf_cn_pkg.cn_success
              , process_code = xx_emf_cn_pkg.cn_preval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_valid
            AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_null, xx_emf_cn_pkg.cn_rec_warn, xx_emf_cn_pkg.cn_rec_err );

         -- Scenario 3 Data Derivation Stage
         UPDATE xx_qp_price_list_pre
            SET request_id = xx_emf_pkg.g_request_id
              , error_code = xx_emf_cn_pkg.cn_success
              , process_code = xx_emf_cn_pkg.cn_derive
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_derive
            AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_null, xx_emf_cn_pkg.cn_rec_warn, xx_emf_cn_pkg.cn_rec_err );

         -- Scenario 4 Post Validation Stage
         UPDATE xx_qp_price_list_pre
            SET request_id = xx_emf_pkg.g_request_id
              , error_code = xx_emf_cn_pkg.cn_success
              , process_code = xx_emf_cn_pkg.cn_postval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_postval
            AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_null, xx_emf_cn_pkg.cn_rec_warn, xx_emf_cn_pkg.cn_rec_err );

         -- Scenario 5 Process Data Stage
         UPDATE xx_qp_price_list_pre
            SET request_id = xx_emf_pkg.g_request_id
              , ERROR_CODE = xx_emf_cn_pkg.cn_success
              , process_code = xx_emf_cn_pkg.cn_postval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_process_data
            AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_null, xx_emf_cn_pkg.cn_rec_err );
      END IF;

      COMMIT;
   END;
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
      --Set Active Flag
      OPEN cur_get_global_var_value('ACTIVE_FLAG');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_ACTIVE_FLAG := l_parameter_value;
      --Set Global Flag
      OPEN cur_get_global_var_value('GLOBAL_FLAG');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_GLOBAL_FLAG := l_parameter_value;
      --Set Automatic Flag
      OPEN cur_get_global_var_value('AUTOMATIC_FLAG');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_ATOMATIC_FLAG := l_parameter_value;
      --Set Currency Code
      OPEN cur_get_global_var_value('CURRENCY');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_CURRENCY := l_parameter_value;
      --Set GMBH Currency Code
      /*OPEN cur_get_global_var_value('GMBH_CURRENCY');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_GMBH_CURRENCY := l_parameter_value;*/
      --Set End Date Active
      OPEN cur_get_global_var_value('END_DATE_ACTIVE');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_END_DATE_ACTIVE := TO_DATE(l_parameter_value,'DD-Mon-YYYY');
      --Set Modile Download
      OPEN cur_get_global_var_value('MOBILE_DOWNLOAD');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_MOBILE_DOWNLOAD := l_parameter_value;
      --Set List Type Code
      OPEN cur_get_global_var_value('LIST_TYPE_CODE');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_LIST_TYPE_CODE := l_parameter_value;
      --Set List Line Type
      OPEN cur_get_global_var_value('LIST_LINE_TYPE');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_LIST_LINE_TYPE := l_parameter_value;
      --Set Product Attribute Context
      OPEN cur_get_global_var_value('PRODUCT_ATTR_CONTEXT');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_PRODUCT_ATTR_CONTEXT := l_parameter_value;
      --Set Product Attribute Code
      OPEN cur_get_global_var_value('PRODUCT_ATTR_CODE');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_PRODUCT_ATTR_CODE := l_parameter_value;
      --Set Arithmatic Operator
      OPEN cur_get_global_var_value('ARITHMETIC_OPERATOR');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_ARITHMETIC_OPERATOR := l_parameter_value;
      --Set Product Precedence
      OPEN cur_get_global_var_value('PRODUCT_PRECEDENCE');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      G_PRODUCT_PRECEDENCE := TO_NUMBER(l_parameter_value);
      --Set Currency Header
      OPEN cur_get_global_var_value('CURRENCY_HEADER');
      FETCH cur_get_global_var_value INTO l_parameter_value;
      CLOSE cur_get_global_var_value;
      BEGIN
         SELECT currency_header_id
           INTO g_currency_header_id
           FROM qp_currency_lists_vl
          WHERE name=l_parameter_value
	    ;
      EXCEPTION
        WHEN OTHERS THEN
           g_currency_header_id := NULL;
      END;
      IF G_ACTIVE_FLAG IS NULL OR  G_GLOBAL_FLAG IS NULL OR G_ATOMATIC_FLAG IS NULL OR
	       G_CURRENCY IS NULL OR G_END_DATE_ACTIVE IS NULL OR G_LIST_TYPE_CODE IS NULL OR
	       G_MOBILE_DOWNLOAD IS NULL OR G_PRODUCT_ATTR_CONTEXT IS NULL OR G_PRODUCT_ATTR_CODE IS NULL OR
	       G_LIST_LINE_TYPE IS NULL OR G_ARITHMETIC_OPERATOR IS NULL OR G_PRODUCT_PRECEDENCE IS NULL
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
   -----------< get_price_list_name >-------------------------------
   -------------------------------------------------------------------------
   FUNCTION get_price_list_name(p_attribute1 IN VARCHAR2,
                                p_attribute2 IN VARCHAR2,
				p_currency   IN VARCHAR2)
      RETURN VARCHAR2 IS
         l_price_list       VARCHAR2(240);
         l_customer         VARCHAR2(240);
	 l_account_number   VARCHAR2(60);
	 x_parameter_name   VARCHAR2(60);
      BEGIN
         IF p_attribute1 IS NOT NULL
         THEN
	    IF p_currency='USD' THEN
	      x_parameter_name := 'CUSTOMER_'||p_attribute1;
	    ELSE
	       x_parameter_name := 'CUSTOMER_GMBH_'||p_attribute1;
	    END IF;
	    l_customer := xx_emf_pkg.get_paramater_value
                           ( p_process_name => g_process_name
                 	   , p_parameter_name => x_parameter_name
			   );
            IF l_customer IS NOT NULL
            THEN
               l_price_list := TO_CHAR(SYSDATE, 'YYYY-')||l_customer||g_formal_pl;
            END IF;
	    IF l_price_list IS NOT NULL AND p_currency='EUR'
	    THEN
	       l_price_list := l_price_list||'_GMBH';
	    END IF;
          ELSIF p_attribute2 IS NOT NULL
          THEN
             BEGIN
	        SELECT hp.party_name,
                       hca.account_number
		  INTO l_customer,
		       l_account_number
                  FROM hz_cust_accounts hca,
                       hz_parties hp
                 WHERE hca.party_id=hp.party_id
                   AND hca.orig_system_reference=p_attribute2;
                /*SELECT party_name
                  INTO l_customer
                  FROM hz_parties
                 WHERE orig_system_reference = p_attribute2;*/
                l_price_list := g_informal_pl||l_customer||' - '||l_account_number;
             EXCEPTION
               WHEN OTHERS THEN
                 l_price_list := NULL;
             END;
          END IF;
          RETURN l_price_list;
      EXCEPTION
         WHEN OTHERS THEN
           RETURN NULL;
      END get_price_list_name;
   PROCEDURE set_stage (
      p_stage   VARCHAR2
   )
   IS
   BEGIN
      g_stage := p_stage;
   END set_stage;
   -------------------------------------------------------------------------
   -----------< update_staging_records >-------------------------------
   -------------------------------------------------------------------------
   PROCEDURE update_staging_records (
      p_error_code   VARCHAR2
   )
   IS
      x_last_update_date     DATE   := SYSDATE;
      x_last_update_by       NUMBER := fnd_global.user_id;
      x_last_updated_login   NUMBER := fnd_profile.VALUE ( xx_emf_cn_pkg.cn_login_id );
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE xx_qp_price_list_stg
         SET process_code = g_stage
           , ERROR_CODE = DECODE ( ERROR_CODE, NULL, p_error_code, ERROR_CODE )
           , last_update_date = x_last_update_date
           , last_updated_by = x_last_update_by
           , last_update_login = x_last_updated_login
       WHERE batch_id = g_batch_id
         AND request_id = xx_emf_pkg.g_request_id
         AND process_code = xx_emf_cn_pkg.cn_new;
      COMMIT;
   END update_staging_records;

-------------------------------------------------------------------------
-----------< mark_records_for_api_error >-------------------------------
-------------------------------------------------------------------------
   PROCEDURE mark_records_for_api_error (
      p_process_code          VARCHAR2
    , p_price_list_name       VARCHAR2
    , p_row_id                ROWID
    , p_msg_data              VARCHAR2
   )
   IS
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER := fnd_profile.VALUE ( xx_emf_cn_pkg.cn_login_id );

      CURSOR cur_print_err_records
      IS
         SELECT xgp.record_number
              , xgp.name
              , xgp.legacy_item_number
              , orig_sys_line_ref
           FROM xx_qp_price_list_pre xgp
          --,xx_qp_price_list_stg xgs
         WHERE  xgp.NAME = p_price_list_name
            AND xgp.request_id = xx_emf_pkg.g_request_id
            AND xgp.process_code = g_stage
	    AND NOT EXISTS ( SELECT 1
                               FROM qp_list_lines qll,
	 	                    qp_list_headers qlh
	 	              WHERE qll.inventory_item_id=xgp.product_attr_value
		                AND qlh.list_header_id=qll.list_header_id
		                AND qlh.name=xgp.name
	                   )
            AND xgp.batch_id = g_batch_id
      ;

      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN

      UPDATE xx_qp_price_list_pre pre
         SET process_code = g_stage
           , error_code = xx_emf_cn_pkg.cn_rec_err
           , last_updated_by = x_last_updated_by
           , last_update_date = x_last_update_date
           , last_update_login = x_last_update_login
       WHERE 1 = 1
         AND request_id = xx_emf_pkg.g_request_id
         AND process_code =
                DECODE ( p_process_code
                       , xx_emf_cn_pkg.cn_process_data, xx_emf_cn_pkg.cn_postval
                       , xx_emf_cn_pkg.cn_derive
                       )
         AND NOT EXISTS ( SELECT 1
                            FROM qp_list_lines qll,
	 	                 qp_list_headers qlh
	 	           WHERE qll.inventory_item_id=pre.product_attr_value
		             AND qlh.list_header_id=qll.list_header_id
		             AND qlh.name=pre.name
	                )
         AND error_code IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
         AND name = p_price_list_name
      ;

      COMMIT;

      FOR cur_rec IN cur_print_err_records
      LOOP
         xx_emf_pkg.error ( p_severity                 => xx_emf_cn_pkg.cn_medium
                          , p_category                 => xx_emf_cn_pkg.cn_stg_apicall
                          , p_error_text               => p_msg_data
                          , p_record_identifier_1      => cur_rec.record_number
                          , p_record_identifier_2      => cur_rec.NAME
                          , p_record_identifier_3      => cur_rec.legacy_item_number
                          );
      END LOOP;
   END mark_records_for_api_error;

   FUNCTION process_data_insert_mode (
      p_list_header_id   IN   NUMBER
    , p_name             IN   VARCHAR2
   )
      RETURN NUMBER
   IS
      CURSOR csr_list_headers (
         cp_list_header_id   NUMBER
       , cp_name             VARCHAR2
      )
      IS
         SELECT DISTINCT orig_sys_header_ref
                       , list_type_code
                       , NAME
                       , list_header_id
		       , orig_org_id --Added on 30-Apr-2012
                       , description
                       , currency_code
                       , active_flag
                       , currency_header_id
                       , trunc(start_date_active_hdr) start_date_active_hdr
                       , trunc(end_date_active_hdr) end_date_active_hdr
                       , automatic_flag
                       , comments
                       , pte_code
                       , global_flag
                       , list_source_code
                       , mobile_download
                       , DECODE ( rounding_factor, NULL, -2, rounding_factor ) rounding_factor
                       , source_system_code
                       , hdr_attribute2
                       , process_flag   --'Y'
                       , process_status_flag   --'P'
                       , created_by
                       , trunc(creation_date)  creation_date
                       , trunc(last_update_date) last_update_date
                       , last_updated_by
                       , last_update_login
                    FROM xx_qp_price_list_pre
                   WHERE batch_id = g_batch_id
                     AND request_id = xx_emf_pkg.g_request_id
                     AND NAME = cp_name
                     AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
                     AND process_code = xx_emf_cn_pkg.cn_postval
                     ORDER BY name;

      CURSOR csr_list_lines (
         cp_list_header_id      NUMBER
       , cp_name                VARCHAR2
       )
      IS
         SELECT DISTINCT orig_sys_line_ref
                       , orig_sys_header_ref
                       , name
                       , list_header_id
                       , list_line_type_code
                       , trunc(start_date_active_dtl) start_date_active_dtl
                       , trunc(end_date_active_dtl) end_date_active_dtl
                      -- , operand
		       , to_char(operand,'99999999.99') operand
                       , primary_uom_flag
                       , TO_NUMBER ( product_precedence ) product_precedence
                       , arithmetic_operator
                       , product_attribute_context
                       , product_attr_code
                       , product_attribute
                       , product_attr_value
                       , product_uom_code
                       , process_flag   --'Y'
                       , process_status_flag   --'P'
                       , created_by
                       , creation_date
                       , last_update_date
                       , last_updated_by
                       , last_update_login
                       , record_number
                    FROM xx_qp_price_list_pre
                   WHERE name = cp_name
		     AND batch_id = g_batch_id
                     AND request_id = xx_emf_pkg.g_request_id
                     AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
                     AND process_code = xx_emf_cn_pkg.cn_postval
                ORDER BY name,orig_sys_line_ref,list_line_type_code;

      TYPE xx_qp_hdrs_tbl IS TABLE OF csr_list_headers%ROWTYPE
         INDEX BY BINARY_INTEGER;

      xx_qp_hdrs_tbl_type           xx_qp_hdrs_tbl;

      TYPE xx_qp_lines_tbl IS TABLE OF csr_list_lines%ROWTYPE
         INDEX BY BINARY_INTEGER;

      xx_qp_lines_tbl_type          xx_qp_lines_tbl;

      i                             NUMBER;
      j                             NUMBER;
      k                             NUMBER;
      l_list_header_id              NUMBER;
      l_list_line_count             NUMBER;
      l_list_attr_count             NUMBER;
      b_list_line_count             NUMBER;
      b_list_attr_count             NUMBER;
      --xx_qp_attr_tbl_type           xx_qp_attrs_tbl;
      x_error_code                  NUMBER                                              := xx_emf_cn_pkg.cn_success;
      x_return_status               VARCHAR2 ( 15 )                                     := xx_emf_cn_pkg.cn_success;
      gpr_return_status             VARCHAR2 ( 1 )                                      := NULL;
      gpr_msg_count                 NUMBER                                              := 0;
      gpr_msg_data                  VARCHAR2 ( 32767 );
      gpr_msg_data2                 VARCHAR2 ( 32767 );
      l_attr_bulk_index             NUMBER                                              := 0;
      l_pricing_attr_index          NUMBER                                              := 1;
      l_line_bulk_index             NUMBER                                              := 0;
      l_lpr_line_index              NUMBER                                              := 0;
      x_hdr_limit                   NUMBER                                              := 1000;
      x_line_limit                  NUMBER                                              := 1000;
      x_attr_limit                  NUMBER                                              := 1000;
      l_orig_sys_header_ref         VARCHAR2 ( 20 )                                     := '';
      l_orig_sys_line_ref           VARCHAR2 ( 20 )                                     := '';
      l_price_break_index           NUMBER                                              := 0;
      x_qp_profile                  VARCHAR2(10);
      gpr_price_list_rec            qp_price_list_pub.price_list_rec_type;
      gpr_price_list_val_rec        qp_price_list_pub.price_list_val_rec_type;
      gpr_price_list_line_tbl       qp_price_list_pub.price_list_line_tbl_type;
      gpr_price_list_line_val_tbl   qp_price_list_pub.price_list_line_val_tbl_type;
      gpr_qualifiers_tbl            qp_qualifier_rules_pub.qualifiers_tbl_type;
      gpr_qualifiers_val_tbl        qp_qualifier_rules_pub.qualifiers_val_tbl_type;
      gpr_pricing_attr_tbl          qp_price_list_pub.pricing_attr_tbl_type;
      gpr_pricing_attr_val_tbl      qp_price_list_pub.pricing_attr_val_tbl_type;
      ppr_price_list_rec            qp_price_list_pub.price_list_rec_type;
      ppr_price_list_val_rec        qp_price_list_pub.price_list_val_rec_type;
      ppr_price_list_line_tbl       qp_price_list_pub.price_list_line_tbl_type;
      ppr_price_list_line_val_tbl   qp_price_list_pub.price_list_line_val_tbl_type;
      ppr_qualifier_rules_rec       qp_qualifier_rules_pub.qualifier_rules_rec_type;
      ppr_qualifier_rules_val_rec   qp_qualifier_rules_pub.qualifier_rules_val_rec_type;
      ppr_qualifiers_tbl            qp_qualifier_rules_pub.qualifiers_tbl_type;
      ppr_qualifiers_val_tbl        qp_qualifier_rules_pub.qualifiers_val_tbl_type;
      ppr_pricing_attr_tbl          qp_price_list_pub.pricing_attr_tbl_type;
      ppr_pricing_attr_val_tbl      qp_price_list_pub.pricing_attr_val_tbl_type;
      --************ added variable to count total,success and errro *******--------
      x_success_temp     NUMBER;
      X_DTL_ATTRIBUTE    VARCHAR2(100);
      -------------------------------------------------------------------------
      -----------< attach_pricelist_customer >-------------------------------
      -------------------------------------------------------------------------
      PROCEDURE attach_pricelist_customer(p_attribute2 IN VARCHAR2,
                                          p_list_header_id IN NUMBER)
      IS
         x_cust_site_use_rec           hz_cust_account_site_v2pub.cust_site_use_rec_type;
         l_object_version_number       NUMBER;
         l_return_status               VARCHAR2 (2000);
         l_msg_count                   NUMBER;
         l_msg_data                    VARCHAR2 (2000);
         CURSOR c_cust_info
         IS
	 SELECT  hcsu.site_use_id,
	         hcsu.cust_acct_site_id,
                 hcsu.object_version_number
            FROM hz_cust_accounts hca,
                 hz_party_sites hps,
                 hz_cust_acct_sites_all hcas,
                 hz_cust_site_uses_all hcsu
           WHERE hca.party_id=hps.party_id
             AND hcas.cust_account_id=hca.cust_account_id
             AND hcas.party_site_id=hps.party_site_id
             AND hcsu.cust_acct_site_id=hcas.cust_acct_site_id
             AND hcsu.site_use_code='SHIP_TO'
             AND hcsu.status='A'
             AND hca.status='A'
             AND hcas.org_id=hcsu.org_id
             AND hca.orig_system_reference=p_attribute2
            ;
      BEGIN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                , 'Attaching Price List to the Customer Account'
                               );
         /*OPEN c_cust_info;
         FETCH c_cust_info INTO x_cust_site_use_rec.site_use_id, x_cust_site_use_rec.cust_acct_site_id, l_object_version_number;
         CLOSE c_cust_info;*/
	 FOR rec_cust_info IN c_cust_info
	 LOOP
            x_cust_site_use_rec.site_use_id := rec_cust_info.site_use_id;
            x_cust_site_use_rec.cust_acct_site_id := rec_cust_info.cust_acct_site_id;
	    l_object_version_number := rec_cust_info.object_version_number;
            x_cust_site_use_rec.price_list_id := p_list_header_id;
            --mo_global.init ('AR');
            --mo_global.set_policy_context ('S', 82);
	    --Callling api to attach the Price List to the Customer Ship to site
            hz_cust_account_site_v2pub.update_cust_site_use(
                                                   FND_API.G_FALSE,
                                                   x_cust_site_use_rec,
                                                   l_object_version_number,
                                                   l_return_status,
                                                   l_msg_count,
                                                   l_msg_data
						   );
         IF l_return_status = fnd_api.g_ret_sts_success
         THEN
            COMMIT;
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                , 'Price List has been successfully attached to Customer Account'
                               );
         ELSE
            ROLLBACK;
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                , 'Price List has not been attached to Customer Account'
                               );
	          FOR i IN 1 .. l_msg_count
            LOOP
               l_msg_data := SUBSTR(fnd_msg_pub.get (p_msg_index => i, p_encoded => 'F'), 1, 999);
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                , i || ') ' || l_msg_data
                               );
            END LOOP;
         END IF;
      END LOOP;
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                , 'Error occured while attaching the price list to Customer Account. '||SQLERRM
                               );
      END attach_pricelist_customer;
   BEGIN
     -- LOOP
         --  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Processing a new set of Primary Price List- Current Time: '|| TO_CHAR (SYSDATE, 'DD-MON-YYYY  HH:MI:SS ');

         --Select the price lists header data from pre tables
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'passing parameter p_name' || p_name );

         OPEN csr_list_headers ( p_list_header_id, p_name );

         FETCH csr_list_headers
         BULK COLLECT INTO xx_qp_hdrs_tbl_type LIMIT x_hdr_limit;

         CLOSE csr_list_headers;

         IF xx_qp_hdrs_tbl_type.COUNT = 0
         THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'No more Primary Price lists to import in update mode' );
           -- EXIT;
         ELSE
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'header CNT ' || xx_qp_hdrs_tbl_type.COUNT );

            FOR l_header_index IN xx_qp_hdrs_tbl_type.FIRST .. xx_qp_hdrs_tbl_type.LAST
            LOOP
               l_line_bulk_index := 0;
               l_attr_bulk_index := 0;
               gpr_price_list_line_tbl.DELETE;
               gpr_pricing_attr_tbl.DELETE;
               l_pricing_attr_index := 0;
               --Check if price list is exists
               BEGIN
                   SELECT list_header_id
                     INTO xx_qp_hdrs_tbl_type ( l_header_index ).list_header_id
                     FROM qp_list_headers
                    WHERE 1=1
                     AND list_type_code = 'PRL'
                     AND name = xx_qp_hdrs_tbl_type ( l_header_index ).NAME;
               EXCEPTION
                  WHEN OTHERS THEN
                     xx_qp_hdrs_tbl_type ( l_header_index ).list_header_id := NULL;
               END;
               IF xx_qp_hdrs_tbl_type ( l_header_index ).list_header_id IS NOT NULL
               THEN
                  gpr_price_list_rec.list_header_id := xx_qp_hdrs_tbl_type ( l_header_index ).list_header_id;
                  gpr_price_list_rec.operation := qp_globals.g_opr_update;
                  gpr_price_list_rec.active_flag := 'Y';
                  gpr_price_list_rec.request_id :=xx_emf_pkg.g_request_id;
                  gpr_price_list_rec.ATTRIBUTE15 :=g_batch_id;
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Process Data in Update Mode' );
               ELSE
                /*  BEGIN  --commented to fetch the value from responsibility level
                     SELECT pov.profile_option_value
                       INTO x_qp_profile
            		       FROM fnd_profile_options_vl po,
            		            fnd_profile_option_values pov,
            		            fnd_user usr,
            		            fnd_application app,
            		            fnd_responsibility rsp,
            		            fnd_nodes svr,
            		            hr_operating_units org
            		      WHERE po.profile_option_name = 'QP_SOURCE_SYSTEM_CODE'
            		        AND pov.application_id = po.application_id
            		        AND pov.profile_option_id = po.profile_option_id
            		        AND usr.user_id (+) = pov.level_value
            		        AND rsp.application_id (+) = pov.level_value_application_id
            		        AND rsp.responsibility_id (+) = pov.level_value
            		        AND app.application_id (+) = pov.level_value
            		        AND svr.node_id (+) = pov.level_value
            		        AND org.organization_id (+) = pov.level_value
                        AND usr.user_id = FND_PROFILE.VALUE('USER_ID');
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'QP_SOURCE_SYSTEM_CODE profile value:'||x_qp_profile );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'QP User value:'||FND_PROFILE.VALUE('USER_ID'));
                  EXCEPTION
            		     WHEN OTHERS THEN
                        x_qp_profile := 'QP';
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'QP_SOURCE_SYSTEM_CODE profile value No Data found:'||SQLERRM);
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'QP User value:'||FND_PROFILE.VALUE('USER_ID'));
                  END; */
		  x_qp_profile := fnd_profile.value('QP_SOURCE_SYSTEM_CODE'); -- added to fetch the value from responsibility level
                  --
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Process Data in Insert Mode' );
                  gpr_price_list_rec.list_header_id := fnd_api.g_miss_num;
                  gpr_price_list_rec.automatic_flag := xx_qp_hdrs_tbl_type ( l_header_index ).automatic_flag;
                  gpr_price_list_rec.currency_code := xx_qp_hdrs_tbl_type ( l_header_index ).currency_code;
                  gpr_price_list_rec.currency_header_id := xx_qp_hdrs_tbl_type ( l_header_index ).currency_header_id;
                  gpr_price_list_rec.end_date_active := xx_qp_hdrs_tbl_type ( l_header_index ).end_date_active_hdr;
                  --gpr_price_list_rec.freight_terms_code := xx_qp_hdrs_tbl_type ( l_header_index ).freight_terms_code;
		  --gpr_price_list_rec.global_flag := 'Y';
		  --Added on 30-Apr-2012 for new logic for global flag
                  IF xx_qp_hdrs_tbl_type ( l_header_index ).orig_org_id IS NOT NULL
                  THEN
		     gpr_price_list_rec.global_flag := 'N';
                     gpr_price_list_rec.org_id := xx_qp_hdrs_tbl_type ( l_header_index ).orig_org_id;
		  ELSE
		     gpr_price_list_rec.global_flag := 'Y';
                  END IF;
                  gpr_price_list_rec.list_type_code := xx_qp_hdrs_tbl_type (l_header_index ).list_type_code;
                  --gpr_price_list_rec.orig_system_header_ref := l_orig_sys_header_ref;
                  gpr_price_list_rec.source_system_code := x_qp_profile ;
                 -- gpr_price_list_rec.pte_code := 'ORDFUL'; commented to fetch the value from responsibility level
                  gpr_price_list_rec.pte_code := fnd_profile.value('QP_PRICING_TRANSACTION_ENTITY'); -- added to fetch the value from responsibility level
                  gpr_price_list_rec.start_date_active := xx_qp_hdrs_tbl_type ( l_header_index ).start_date_active_hdr;
                  gpr_price_list_rec.operation := qp_globals.g_opr_create;
                  gpr_price_list_rec.name := xx_qp_hdrs_tbl_type ( l_header_index ).NAME;
                  gpr_price_list_rec.description := xx_qp_hdrs_tbl_type ( l_header_index ).description;
                  gpr_price_list_rec.active_flag := 'Y';
                  gpr_price_list_rec.request_id :=xx_emf_pkg.g_request_id;
                  gpr_price_list_rec.attribute15 :=g_batch_id;
                  -----------------------------
		              --Creating Price List Header
                  ------------------------------
                  BEGIN
                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Calling api to create pricelist ' );
                     fnd_msg_pub.initialize;
                     BEGIN
                        qp_price_list_pub.process_price_list ( p_api_version_number           => 1
                                                             , p_init_msg_list                => fnd_api.g_true
                                                             , p_return_values                => fnd_api.g_false
                                                             , p_commit                       => fnd_api.g_false
                                                             , x_return_status                => gpr_return_status
                                                             , x_msg_count                    => gpr_msg_count
                                                             , x_msg_data                     => gpr_msg_data
                                                             , p_price_list_rec               => gpr_price_list_rec
                                                             , p_price_list_line_tbl          => gpr_price_list_line_tbl
                                                             , p_qualifiers_tbl               => gpr_qualifiers_tbl
                                                             , p_pricing_attr_tbl             => gpr_pricing_attr_tbl
                                                             , x_price_list_rec               => ppr_price_list_rec
                                                             , x_price_list_val_rec           => ppr_price_list_val_rec
                                                             , x_price_list_line_tbl          => ppr_price_list_line_tbl
                                                             , x_price_list_line_val_tbl      => ppr_price_list_line_val_tbl
                                                             , x_qualifiers_tbl               => ppr_qualifiers_tbl
                                                             , x_qualifiers_val_tbl           => ppr_qualifiers_val_tbl
                                                             , x_pricing_attr_tbl             => ppr_pricing_attr_tbl
                                                             , x_pricing_attr_val_tbl         => ppr_pricing_attr_val_tbl
                                                             );
                     EXCEPTION
		                    WHEN OTHERS THEN
                            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error in Header API ');
                     END;
                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Return Status ' || gpr_return_status );
                     IF gpr_return_status IN ( 'E', 'U' ) THEN
                        gpr_msg_data  := '';
                        gpr_msg_data2 := '';
                        --x_grp_error   := x_grp_error + 1;
                        --x_error_record:= x_error_record + 1;
                        FOR k IN 1 .. gpr_msg_count
                        LOOP
                           gpr_msg_data := oe_msg_pub.get ( p_msg_index => k, p_encoded => 'F' );
                           gpr_msg_data2 := gpr_msg_data2 || LTRIM ( RTRIM ( gpr_msg_data ));
                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error Msg... =>' || gpr_msg_data );
                        END LOOP;
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error Msg..... =>' || gpr_msg_data2 );
                        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                        ROLLBACK;
                        xx_emf_pkg.error ( p_severity                 => xx_emf_cn_pkg.cn_medium
                                         , p_category                 => xx_emf_cn_pkg.cn_stg_apicall
                                         , p_error_text               => gpr_msg_data2
                                         , p_record_identifier_1      => NULL
                                         , p_record_identifier_2      => xx_qp_hdrs_tbl_type ( l_header_index ).NAME
                                         , p_record_identifier_3      => NULL
                                         );
                        mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                     , xx_qp_hdrs_tbl_type ( l_header_index ).NAME
                                                     , null
                                                     , SUBSTR ( gpr_msg_data2, 1, 1000 )
                                                     );
                        -- ROLLBACK;
                     ELSE
                        l_list_header_id := NULL;
                        SELECT a.list_header_id
                          INTO l_list_header_id
                          FROM qp_list_headers_b a,
			                         qp_list_headers_tl b
                         WHERE a.list_header_id=b.list_header_id
                           AND b.name=xx_qp_hdrs_tbl_type ( l_header_index ).NAME
                           AND a.list_type_code = 'PRL'
                           AND language=USERENV('LANG')
                        ;
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'l_list_header_id'||l_list_header_id);
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                              , 'Price List Creation => Success For Price List'
                                              || xx_qp_hdrs_tbl_type ( l_header_index ).NAME
                                              || '-'
                                              || l_orig_sys_header_ref
                                              --|| ' l_orig_sys_line_ref '
                                              --|| cur_rec.orig_sys_line_ref
                                              );
                        x_success_header := x_success_header + 1;
--                      x_grp_success    := x_grp_success + 1;
                        COMMIT;
                        IF xx_qp_hdrs_tbl_type ( l_header_index ).hdr_attribute2 IS NOT NULL
                        THEN
                           attach_pricelist_customer(xx_qp_hdrs_tbl_type ( l_header_index ).hdr_attribute2,
                                                    l_list_header_id );
                        END IF;
                     END IF;
                     --Update the Integra interface table with 'COMPLETE" status
                  EXCEPTION
                     WHEN fnd_api.g_exc_unexpected_error THEN
                          gpr_return_status := fnd_api.g_ret_sts_unexp_error;
                          FOR i IN 1 .. gpr_msg_count
                          LOOP
                             oe_msg_pub.get ( p_msg_index          => i
                                            , p_encoded            => fnd_api.g_false
                                            , p_data               => gpr_msg_data
                                            , p_msg_index_out      => gpr_msg_count
                                            );
                          END LOOP;
                          xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Err Msg ' || gpr_msg_data );
                          xx_emf_pkg.error (p_severity            => xx_emf_cn_pkg.CN_MEDIUM
                                           ,p_category            => xx_emf_cn_pkg.CN_STG_APICALL
                                           ,p_error_text          => gpr_msg_data2
                                           ,p_record_identifier_1 => NULL
                                           ,p_record_identifier_2 => xx_qp_hdrs_tbl_type (l_header_index).NAME
                                           ,p_record_identifier_3 => NULL
                                           );
                          --Update the inerface table with 'ERROR" status. Reprocess program will change the flag to Y
                          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                          ROLLBACK;
                  END;
                  ---End Of Creating Price List Header
               END IF;
               DECLARE
                  gpr_price_list_rec            qp_price_list_pub.price_list_rec_type;
                  gpr_price_list_val_rec        qp_price_list_pub.price_list_val_rec_type;
                  gpr_price_list_line_tbl       qp_price_list_pub.price_list_line_tbl_type;
                  gpr_price_list_line_val_tbl   qp_price_list_pub.price_list_line_val_tbl_type;
                  gpr_qualifiers_tbl            qp_qualifier_rules_pub.qualifiers_tbl_type;
                  gpr_qualifiers_val_tbl        qp_qualifier_rules_pub.qualifiers_val_tbl_type;
                  gpr_pricing_attr_tbl          qp_price_list_pub.pricing_attr_tbl_type;
                  gpr_pricing_attr_val_tbl      qp_price_list_pub.pricing_attr_val_tbl_type;
                  ppr_price_list_rec            qp_price_list_pub.price_list_rec_type;
                  ppr_price_list_val_rec        qp_price_list_pub.price_list_val_rec_type;
                  ppr_price_list_line_tbl       qp_price_list_pub.price_list_line_tbl_type;
                  ppr_price_list_line_val_tbl   qp_price_list_pub.price_list_line_val_tbl_type;
                  ppr_qualifier_rules_rec       qp_qualifier_rules_pub.qualifier_rules_rec_type;
                  ppr_qualifier_rules_val_rec   qp_qualifier_rules_pub.qualifier_rules_val_rec_type;
                  ppr_qualifiers_tbl            qp_qualifier_rules_pub.qualifiers_tbl_type;
                  ppr_qualifiers_val_tbl        qp_qualifier_rules_pub.qualifiers_val_tbl_type;
                  ppr_pricing_attr_tbl          qp_price_list_pub.pricing_attr_tbl_type;
                  ppr_pricing_attr_val_tbl      qp_price_list_pub.pricing_attr_val_tbl_type;
              BEGIN
                 --Process the logical group of line records for the price list header
                    -- Set the Price List line data
                    --Selecting line data
                  x_total_record := x_total_record + 1;
                  --
                  l_pricing_attr_index :=1;
                  l_list_line_count    :=0;
                  l_list_attr_count    :=0;
                  b_list_line_count    :=0;
                  b_list_attr_count    :=0;
                  OPEN csr_list_lines ( xx_qp_hdrs_tbl_type ( l_header_index ).list_header_id
                                      , xx_qp_hdrs_tbl_type ( l_header_index ).NAME
                                      );

                  LOOP
                     FETCH csr_list_lines
                     BULK COLLECT INTO xx_qp_lines_tbl_type LIMIT x_line_limit;
                     IF xx_qp_lines_tbl_type.COUNT = 0
                     THEN
                        EXIT;
                     END IF;
		     l_pricing_attr_index :=1;
                     l_list_line_count    :=0;
                     l_list_attr_count    :=0;
                     b_list_line_count    :=0;
                     b_list_attr_count    :=0;
                     x_grp_total    := x_grp_total + xx_qp_lines_tbl_type.COUNT;
                     x_success_temp :=0;
                     x_success_temp := xx_qp_lines_tbl_type.COUNT;
                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1');
                     IF xx_qp_lines_tbl_type.COUNT > 0
                     THEN
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                             ,    'Fetching Price List lines at a time '
                                               || xx_qp_lines_tbl_type.COUNT
                                               || ' records'
                                             );

                        --Process
                        FOR i IN xx_qp_lines_tbl_type.FIRST .. xx_qp_lines_tbl_type.LAST
                        LOOP
                           l_lpr_line_index := i;   -- + l_line_bulk_index;
                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                                ,    'l_lpr_line_index>>'
                                                  || l_lpr_line_index
                                                  || ' i>>'
                                                  || i
                                                  || ' l_line_bulk_index>>'
                                                  || l_line_bulk_index
                                                );
                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                                ,    'From LINE Cursor:::product_attribute_context '
                                                  || xx_qp_lines_tbl_type ( i ).product_attribute_context
                                                  || ' product_attribute  '
                                                  || xx_qp_lines_tbl_type ( i ).product_attribute
                                                  || ' product_attr_value '
                                                  || xx_qp_lines_tbl_type ( i ).product_attr_value
                                                  || ' product_uom_code   '
                                                  || xx_qp_lines_tbl_type ( i ).product_uom_code
                                                );
                           -- Need to flush before assign--
                           --gpr_price_list_line_tbl.DELETE;
                           gpr_price_list_line_tbl ( l_lpr_line_index ).list_header_id := nvl(l_list_header_id, xx_qp_hdrs_tbl_type ( l_header_index ).list_header_id);
                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.1');
                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                                   ,    'l_lpr_line_index>>'
                                                     || l_lpr_line_index
                                                     || ' i>>'
                                                     || i
                                                     || ' record number >>'
                                                     || xx_qp_lines_tbl_type ( i ).record_number
                                                   );
                                 gpr_price_list_line_tbl (l_lpr_line_index).arithmetic_operator := xx_qp_lines_tbl_type ( i ).arithmetic_operator;
                                 gpr_price_list_line_tbl ( l_lpr_line_index ).list_line_id := fnd_api.g_miss_num;
                                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.2');
                                 /*gpr_price_list_line_tbl ( l_lpr_line_index ).arithmetic_operator :=
                                                                          xx_qp_lines_tbl_type ( i ).arithmetic_operator;*/
                                 --gpr_price_list_line_tbl ( l_lpr_line_index ).attribute10 := cur_rec.orig_sys_line_ref;
                                 gpr_price_list_line_tbl( l_lpr_line_index ).request_id :=xx_emf_pkg.g_request_id;
                                 gpr_price_list_line_tbl( l_lpr_line_index ).ATTRIBUTE15 :=g_batch_id;
                                 gpr_price_list_line_tbl ( l_lpr_line_index ).end_date_active :=
                                                                          xx_qp_lines_tbl_type ( i ).end_date_active_dtl;
                                 gpr_price_list_line_tbl ( l_lpr_line_index ).start_date_active :=
                                                                        xx_qp_lines_tbl_type ( i ).start_date_active_dtl;
                                 gpr_price_list_line_tbl ( l_lpr_line_index ).list_line_type_code :=
                                                                          xx_qp_lines_tbl_type ( i ).list_line_type_code;
                                 gpr_price_list_line_tbl ( l_lpr_line_index ).inventory_item_id := xx_qp_lines_tbl_type ( i).product_attr_value;
                                 gpr_price_list_line_tbl ( l_lpr_line_index ).list_price :=
                                                                                      xx_qp_lines_tbl_type ( i ).operand;
                                 gpr_price_list_line_tbl ( l_lpr_line_index ).operand :=
                                                                                      xx_qp_lines_tbl_type ( i ).operand;
                                 gpr_price_list_line_tbl ( l_lpr_line_index ).primary_uom_flag := 'Y';
                                 gpr_price_list_line_tbl ( l_lpr_line_index ).automatic_flag := 'Y';
                                 gpr_price_list_line_tbl ( l_lpr_line_index ).product_precedence :=
                                                                             xx_qp_lines_tbl_type ( i ).product_precedence;
                               /*  gpr_price_list_line_tbl ( l_lpr_line_index ).price_break_type_code :=
                                                                        xx_qp_lines_tbl_type ( i ).price_break_type_code;*/
                                 gpr_price_list_line_tbl ( l_lpr_line_index ).operation := qp_globals.g_opr_create;
                                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.3');
				                         gpr_pricing_attr_tbl ( l_pricing_attr_index ).pricing_attribute_id := fnd_api.g_miss_num;
                                 gpr_pricing_attr_tbl ( l_pricing_attr_index ).list_line_id := fnd_api.g_miss_num;
                                 gpr_pricing_attr_tbl ( l_pricing_attr_index ).operation := qp_globals.g_opr_create;
                                 gpr_pricing_attr_tbl( l_pricing_attr_index ).request_id :=xx_emf_pkg.g_request_id;
                                 gpr_pricing_attr_tbl ( l_pricing_attr_index ).price_list_line_index := l_lpr_line_index;
                                 gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attribute :=
                                                                           xx_qp_lines_tbl_type ( i).product_attribute;
                                 gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attribute_context :=
                                                                    xx_qp_lines_tbl_type ( i ).product_attribute_context;
                                 gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attr_value :=
                                                                           xx_qp_lines_tbl_type ( i ).product_attr_value;
                                 gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_uom_code :=
                                                                             xx_qp_lines_tbl_type ( i ).product_uom_code;
                                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'price_list_line_index'||gpr_pricing_attr_tbl ( l_pricing_attr_index ).price_list_line_index);
                                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'product_attribute'|| gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attribute);
                                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'product_attribute_context'|| gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attribute_context);
                                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'product_attr_value'||gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_attr_value);
                                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'product_uom_code'|| gpr_pricing_attr_tbl ( l_pricing_attr_index ).product_uom_code);
                                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.4');
                                 l_pricing_attr_index := l_pricing_attr_index + 1;
                        END LOOP;   --end of line loop
                     END IF;
                     l_line_bulk_index := l_line_bulk_index + 1000;
                     -- Line attributes data selection end
                     BEGIN
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Calling api to create pricelist ' );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'IN API CALL l_list_line_count'||l_lpr_line_index );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'IN API CALL l_pricing_attr_index'||l_pricing_attr_index );
                        fnd_msg_pub.initialize;
                     BEGIN
                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.5');
                     qp_price_list_pub.process_price_list ( p_api_version_number           => 1
                                                          , p_init_msg_list                => fnd_api.g_true
                                                          , p_return_values                => fnd_api.g_false
                                                          , p_commit                       => fnd_api.g_false
                                                          , x_return_status                => gpr_return_status
                                                          , x_msg_count                    => gpr_msg_count
                                                          , x_msg_data                     => gpr_msg_data
                                                          , p_price_list_rec               => gpr_price_list_rec
                                                          , p_price_list_line_tbl          => gpr_price_list_line_tbl
                                                          , p_qualifiers_tbl               => gpr_qualifiers_tbl
                                                          , p_pricing_attr_tbl             => gpr_pricing_attr_tbl
                                                          , x_price_list_rec               => ppr_price_list_rec
                                                          , x_price_list_val_rec           => ppr_price_list_val_rec
                                                          , x_price_list_line_tbl          => ppr_price_list_line_tbl
                                                          , x_price_list_line_val_tbl      => ppr_price_list_line_val_tbl
                                                          , x_qualifiers_tbl               => ppr_qualifiers_tbl
                                                          , x_qualifiers_val_tbl           => ppr_qualifiers_val_tbl
                                                          , x_pricing_attr_tbl             => ppr_pricing_attr_tbl
                                                          , x_pricing_attr_val_tbl         => ppr_pricing_attr_val_tbl
                                                         );
                     gpr_price_list_line_tbl.DELETE;
                     gpr_pricing_attr_tbl.DELETE;

                     EXCEPTION
                     WHEN OTHERS THEN
                        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                        ROLLBACK;
                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error in Line API ');
                     END;
                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'API Return Status ' || gpr_return_status );

                     IF gpr_return_status IN ( 'E', 'U' )
                     THEN
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.6');
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error Status ' || gpr_return_status );
                        gpr_msg_data  := '';
                        gpr_msg_data2 := '';
                        x_grp_error   := x_grp_error + x_success_temp;
                        x_error_record:= x_error_record + 1;
                        FOR k IN 1 .. gpr_msg_count
                        LOOP
                           gpr_msg_data := substr(oe_msg_pub.get ( p_msg_index => k, p_encoded => 'F' ),1,160);
                           gpr_msg_data2 := substr(gpr_msg_data2 || LTRIM ( RTRIM ( gpr_msg_data )),1,200);
                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error Msg... =>' || gpr_msg_data );
                        END LOOP;
                        --xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error Msg..... =>' || gpr_msg_data2 );
                        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                        ROLLBACK;
                      /*  xx_emf_pkg.error ( p_severity                 => xx_emf_cn_pkg.cn_medium
                                         , p_category                 => xx_emf_cn_pkg.cn_stg_apicall
                                         --, p_error_text               => gpr_msg_data2
                                         , p_error_text               =>gpr_msg_data
                                        -- , p_record_identifier_1      => cur_rec.name--xx_qp_hdrs_tbl_type ( l_header_index ).NAME
                                         , p_record_identifier_1      => null
                                         , p_record_identifier_2      => l_orig_sys_header_ref
                                         , p_record_identifier_3      => cur_rec.orig_sys_line_ref
                                         );*/
                       mark_records_for_api_error ( xx_emf_cn_pkg.cn_process_data
                                                   , xx_qp_hdrs_tbl_type ( l_header_index ).name
                                                   , null
                                                   , SUBSTR ( gpr_msg_data, 1, 1000 )
                                                   );
                                                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.7');
                       -- ROLLBACK;
                     ELSE
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.8');
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium
                                             ,    'Price List Creation => Success For Price List'
                                               || xx_qp_hdrs_tbl_type ( l_header_index ).name
                                               || '-'
                                               || l_orig_sys_header_ref
                                               || ' l_orig_sys_line_ref '
                                               --|| xx_qp_hdrs_tbl_type ( l_header_index ).orig_sys_line_ref
                                             );

                        COMMIT;
                     END IF;
                     --Update the Ansell interface table with 'COMPLETE" status
                    EXCEPTION
                      WHEN fnd_api.g_exc_unexpected_error
                      THEN
                      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low,'DEBUG MESSAGE 1.10');
                         gpr_return_status := fnd_api.g_ret_sts_unexp_error;
                         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                           ,    'Err Msg For unexpected_error'||gpr_return_status
                              );

                         /*FOR i IN 1 .. gpr_msg_count
                         LOOP
                            oe_msg_pub.get ( p_msg_index          => i
                                           , p_encoded            => fnd_api.g_false
                                           , p_data               => gpr_msg_data
                                           , p_msg_index_out      => gpr_msg_count
                                           );
                         END LOOP;
                         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Err Msg ' || gpr_msg_data );
                         xx_emf_pkg.error   (p_severity            => xx_emf_cn_pkg.CN_MEDIUM
                        ,p_category            => xx_emf_cn_pkg.CN_STG_APICALL
                        ,p_error_text          => gpr_msg_data2
                        ,p_record_identifier_1 => xx_qp_hdrs_tbl_type (l_header_index).name
                        ,p_record_identifier_2 => l_orig_sys_header_ref
                        ,p_record_identifier_3 => cur_rec.orig_sys_line_ref
                          );*/
                      --Update the inerface table with 'ERROR" status. Reprocess program will change the flag to Y
                      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   ROLLBACK;
                   END;
		   xx_qp_lines_tbl_type.delete;
		   END LOOP;
                   CLOSE csr_list_lines;
                  -- one List Line group completed
              -- END LOOP;
                  --COMMIT;
             --END IF;
             -- End if p_header_line = 'Y'
               END;
               --One price list header completed. Fetch the next one


            END LOOP;
         END IF;
        RETURN x_error_code;
        /*xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                              ,    'Processing Completed for current set of Primary Price List, Current Time:'
                                || TO_CHAR ( SYSDATE, 'DD-MON-YYYY  HH:MI:SS' )
                              );
       --Save all changes..COMMIT is used to increase performence and reduce snapshot related error
       COMMIT;*/
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                              , 'Unexpected error occured in Child Primary Price List API Program  ' || SQLCODE
                                || SQLERRM
                              );
         RETURN x_error_code;
   END process_data_insert_mode;

   FUNCTION process_data_update_mode (
      p_header_line      IN   VARCHAR2
     ,p_list_header_id   IN   NUMBER
   )
      RETURN NUMBER
   IS
      x_error_code   NUMBER := 0;
   BEGIN
      RETURN x_error_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN x_error_code;
   END process_data_update_mode;

   -- END RESTRICTIONS
   PROCEDURE main (
      errbuf            OUT      VARCHAR2
    , retcode           OUT      VARCHAR2
    , p_batch_id        IN       VARCHAR2
    , p_restart_flag    IN       VARCHAR2
    , p_override_flag   IN       VARCHAR2
    , p_validate_and_load IN       VARCHAR2
   )
   IS
      x_error_code          NUMBER                  := xx_emf_cn_pkg.cn_success;
      x_error_code_temp     NUMBER                  := xx_emf_cn_pkg.cn_success;
      x_pre_std_hdr_table   g_xx_qp_pl_pre_tab_type;

      -- CURSOR FOR VARIOUS STAGES
      CURSOR c_xx_intg_pre_std_hdr (
         cp_process_status   VARCHAR2
      )
      IS
         SELECT   hdr.rowid,
                  hdr.*
             FROM xx_qp_price_list_pre hdr
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
         ORDER BY record_number;
      PROCEDURE update_record_status (
         p_conv_pre_std_hdr_rec   IN OUT   g_xx_qp_pl_pre_rec_type
       , p_error_code             IN       VARCHAR2
      )
      IS
      BEGIN
         IF p_error_code IN ( xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err )
         THEN
            p_conv_pre_std_hdr_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            p_conv_pre_std_hdr_rec.ERROR_CODE :=
               xx_qp_price_list_cnv_val_pkg.find_max ( p_error_code
                                                     , NVL ( p_conv_pre_std_hdr_rec.ERROR_CODE
                                                           , xx_emf_cn_pkg.cn_success )
                                                     );
         END IF;

         p_conv_pre_std_hdr_rec.process_code := g_stage;
      END update_record_status;

      PROCEDURE mark_records_complete (
         p_process_code   VARCHAR2
      )
      IS
         x_last_update_date     DATE   := SYSDATE;
         x_last_update_by       NUMBER := fnd_global.user_id;
         x_last_updated_login   NUMBER := fnd_profile.VALUE ( xx_emf_cn_pkg.cn_login_id );
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN

         UPDATE xx_qp_price_list_pre
            SET process_code = g_stage
              , ERROR_CODE = NVL ( ERROR_CODE, xx_emf_cn_pkg.cn_success )
              , last_updated_by = x_last_update_by
              , last_update_date = x_last_update_date
              , last_update_login = x_last_updated_login
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND process_code =
                   DECODE ( p_process_code
                          , xx_emf_cn_pkg.cn_process_data, xx_emf_cn_pkg.cn_postval
                          , xx_emf_cn_pkg.cn_derive
                          )
            AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn );

         COMMIT;
      END mark_records_complete;

      PROCEDURE update_pre_interface_records (
         p_cnv_pre_std_hdr_table   IN   g_xx_qp_pl_pre_tab_type
      )
      IS
         x_last_update_date     DATE   := SYSDATE;
         x_last_update_by       NUMBER := fnd_global.user_id;
         x_last_updated_login   NUMBER := fnd_profile.VALUE ( xx_emf_cn_pkg.cn_login_id );
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         FOR indx IN 1 .. p_cnv_pre_std_hdr_table.COUNT
         LOOP
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                 ,    'p_cnv_pre_std_hdr_table(indx).process_code '
                                   || p_cnv_pre_std_hdr_table ( indx ).process_code
                                   || ' for record number '
                                   || p_cnv_pre_std_hdr_table ( indx ).record_number
                                   || ' Error Code is '
                                   || p_cnv_pre_std_hdr_table ( indx ).ERROR_CODE
                                 );
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                 ,    'p_cnv_pre_std_hdr_table(indx).error_code '
                                   || p_cnv_pre_std_hdr_table ( indx ).ERROR_CODE
                                 );

            UPDATE xx_qp_price_list_pre
               SET active_flag = p_cnv_pre_std_hdr_table ( indx ).active_flag
                 , hdr_attribute1 = p_cnv_pre_std_hdr_table ( indx ).hdr_attribute1
                 , hdr_attribute2 = p_cnv_pre_std_hdr_table ( indx ).hdr_attribute2
                 , global_flag = p_cnv_pre_std_hdr_table ( indx ).global_flag
                 , operating_unit = p_cnv_pre_std_hdr_table ( indx ).operating_unit
                 , orig_org_id = p_cnv_pre_std_hdr_table ( indx ).orig_org_id
                 , automatic_flag = p_cnv_pre_std_hdr_table ( indx ).automatic_flag
                 , comments = p_cnv_pre_std_hdr_table ( indx ).comments
                 , currency_code = p_cnv_pre_std_hdr_table ( indx ).currency_code
                 , currency_header_id = p_cnv_pre_std_hdr_table ( indx ).currency_header_id
                 , delete_flag = p_cnv_pre_std_hdr_table ( indx ).delete_flag
                 , description = p_cnv_pre_std_hdr_table ( indx ).description
                 , end_date_active_hdr = p_cnv_pre_std_hdr_table ( indx ).end_date_active_hdr
                 , end_date_active_dtl = p_cnv_pre_std_hdr_table ( indx ).end_date_active_dtl
                 , freight_terms_code = p_cnv_pre_std_hdr_table ( indx ).freight_terms_code
                 , LANGUAGE = p_cnv_pre_std_hdr_table ( indx ).LANGUAGE
                 , list_source_code = p_cnv_pre_std_hdr_table ( indx ).list_source_code
                 , list_type_code = p_cnv_pre_std_hdr_table ( indx ).list_type_code
                 , lock_flag = p_cnv_pre_std_hdr_table ( indx ).lock_flag
                 , mobile_download = p_cnv_pre_std_hdr_table ( indx ).mobile_download
                 , NAME = p_cnv_pre_std_hdr_table ( indx ).NAME
                 , list_header_id = p_cnv_pre_std_hdr_table ( indx ).list_header_id
                 , orig_sys_header_ref = p_cnv_pre_std_hdr_table ( indx ).orig_sys_header_ref
                 , process_type = p_cnv_pre_std_hdr_table ( indx ).process_type
                 , pte_code = p_cnv_pre_std_hdr_table ( indx ).pte_code
                 , rounding_factor = p_cnv_pre_std_hdr_table ( indx ).rounding_factor
                 , ship_method_code = p_cnv_pre_std_hdr_table ( indx ).ship_method_code
                 , source_system_code = p_cnv_pre_std_hdr_table ( indx ).source_system_code
                 , start_date_active_hdr = p_cnv_pre_std_hdr_table ( indx ).start_date_active_hdr
                 , start_date_active_dtl = p_cnv_pre_std_hdr_table ( indx ).start_date_active_dtl
                 , terms = p_cnv_pre_std_hdr_table ( indx ).terms
                 , version_no = p_cnv_pre_std_hdr_table ( indx ).version_no
                 , arithmetic_operator = p_cnv_pre_std_hdr_table ( indx ).arithmetic_operator
                 , legacy_item_number = p_cnv_pre_std_hdr_table ( indx ).legacy_item_number
                 , list_line_no = p_cnv_pre_std_hdr_table ( indx ).list_line_no
                 , list_line_type_code = p_cnv_pre_std_hdr_table ( indx ).list_line_type_code
                 , list_price = p_cnv_pre_std_hdr_table ( indx ).list_price
                 , operand = p_cnv_pre_std_hdr_table ( indx ).operand
                 , organization_code = p_cnv_pre_std_hdr_table ( indx ).organization_code
                 , orig_sys_line_ref = p_cnv_pre_std_hdr_table ( indx ).orig_sys_line_ref
                 , primary_uom_flag = p_cnv_pre_std_hdr_table ( indx ).primary_uom_flag
                 , product_precedence = p_cnv_pre_std_hdr_table ( indx ).product_precedence
                 , product_attribute_context = p_cnv_pre_std_hdr_table ( indx ).product_attribute_context
                 , product_attr_code = p_cnv_pre_std_hdr_table ( indx ).product_attr_code
                 , product_attribute = p_cnv_pre_std_hdr_table ( indx ).product_attribute
                 , product_attr_value = p_cnv_pre_std_hdr_table ( indx ).product_attr_value
                 , product_uom_code = p_cnv_pre_std_hdr_table ( indx ).product_uom_code
                 , process_flag = p_cnv_pre_std_hdr_table ( indx ).process_flag
                 , process_status_flag = p_cnv_pre_std_hdr_table ( indx ).process_status_flag
                 , process_code = p_cnv_pre_std_hdr_table ( indx ).process_code
                 , ERROR_CODE = p_cnv_pre_std_hdr_table ( indx ).ERROR_CODE
                 , last_updated_by = x_last_update_by
                 , last_update_date = x_last_update_date
                 , last_update_login = x_last_updated_login
             WHERE rowid = p_cnv_pre_std_hdr_table ( indx ).row_id
              AND  batch_id      = g_batch_id;
         END LOOP;
         COMMIT;
      END update_pre_interface_records;
      /*******************MOVE_REC_PRE_STANDARD_TABLE*************************/
      FUNCTION move_rec_pre_standard_table
         RETURN NUMBER
      IS
         x_creation_date           DATE                    := SYSDATE;
         x_created_by              NUMBER                  := fnd_global.user_id;
         x_last_update_date        DATE                    := SYSDATE;
         x_last_update_by          NUMBER                  := fnd_global.user_id;
         x_last_updated_login      NUMBER                  := fnd_profile.VALUE ( xx_emf_cn_pkg.cn_login_id );
         x_cnv_pre_std_hdr_table   g_xx_qp_pl_pre_tab_type;
         x_error_code              NUMBER                  := xx_emf_cn_pkg.cn_success;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Inside move_rec_pre_standard_table' );
         -- Select only the appropriate columns that are required to be inserted into the
         -- Pre-Interface Table and insert from the Staging Table
         INSERT INTO xx_qp_price_list_pre
                     ( active_flag
                     , global_flag
                     , operating_unit
                     , automatic_flag
                     , currency_code
                     , description
                     , end_date_active_hdr
                     , end_date_active_dtl
                     , list_source_code
                     , list_type_code
                     , mobile_download
                     , NAME
                     , orig_sys_header_ref
                     , process_type
                     , pte_code
                     , rounding_factor
                     , source_system_code
                     , start_date_active_hdr
                     , start_date_active_dtl
                     , arithmetic_operator
                     , legacy_item_number
                     , list_line_type_code
                     , list_price
                     , operand
                     , organization_code
                     , orig_sys_line_ref
                     , primary_uom_flag
                     , product_precedence
                     , product_attribute_context
                     , product_attr_code
                     , product_attr_value
                     , product_uom_code
                     , hdr_attribute2
                     , process_flag
                     , process_status_flag
                     , batch_id
                     , record_number
                     , process_code
                     , ERROR_CODE
                     , created_by
                     , creation_date
                     , last_update_date
                     , last_updated_by
                     , last_update_login
                     , request_id
                     )
            SELECT G_ACTIVE_FLAG--active_flag
                 --, G_GLOBAL_FLAG--global_flag
		 , 'N'--global_flag
                 , operating_unit
                 , G_ATOMATIC_FLAG--automatic_flag
                 , NVL(currency_code,G_CURRENCY) --currency_code
                 , get_price_list_name(hdr_attribute1, hdr_attribute2,NVL(currency_code,G_CURRENCY))--description
                 , end_date_active_hdr
                 , G_END_DATE_ACTIVE--end_date_active_dtl
                 , list_source_code
                 , G_LIST_TYPE_CODE--list_type_code
                 , G_MOBILE_DOWNLOAD--mobile_download
                 , get_price_list_name(hdr_attribute1, hdr_attribute2,NVL(currency_code,G_CURRENCY))--name
                 , orig_sys_header_ref
                 , process_type
                 , pte_code
                 , rounding_factor
                 , source_system_code
                 , start_date_active_hdr
                 , start_date_active_dtl
                 , G_ARITHMETIC_OPERATOR--arithmetic_operator
                 , legacy_item_number
                 , G_LIST_LINE_TYPE--list_line_type_code
                 , list_price
                 , list_price--operand
                 , organization_code
                 , orig_sys_line_ref
                 , primary_uom_flag
                 , G_PRODUCT_PRECEDENCE--product_precedence
                 , G_PRODUCT_ATTR_CONTEXT--product_attribute_context
                 , G_PRODUCT_ATTR_CODE--product_attr_code
                 , legacy_item_number--product_attr_value
                 , product_uom_code
                 , hdr_attribute2
                 , process_flag
                 , process_status_flag
                 , batch_id
                 , record_number
                 , process_code
                 , ERROR_CODE
                 , x_created_by
                 , x_creation_date
                 , x_last_update_date
                 , x_last_update_by
                 , x_last_updated_login
                 , request_id
              FROM xx_qp_price_list_stg
             WHERE batch_id = g_batch_id
               AND process_code = xx_emf_cn_pkg.cn_preval
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn );

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'No of Records Insert into Pre-Interface 1=>' || SQL%ROWCOUNT );
         COMMIT;
         --Update the organization ID column to filter out the already loaded data
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                 , 'No of Records Insert into Pre-Interface 2=>' || SQL%ROWCOUNT || '-' || SQLERRM
                                 );
            xx_emf_pkg.error ( xx_emf_cn_pkg.cn_medium, xx_emf_cn_pkg.cn_tech_error, xx_emf_cn_pkg.cn_exp_unhand );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'error in insertion' || SQLERRM );
            RETURN x_error_code;
      END move_rec_pre_standard_table;
      FUNCTION process_data
         RETURN NUMBER
      IS
         CURSOR c_header
         IS
            SELECT DISTINCT orig_sys_header_ref
                          , list_type_code
                          , NAME
                          , list_header_id
                       FROM xx_qp_price_list_pre
                      WHERE batch_id = g_batch_id
                        AND request_id = xx_emf_pkg.g_request_id
                        --AND list_header_id IS NOT NULL
                        AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
                        AND process_code = xx_emf_cn_pkg.cn_postval;

         x_error_code          VARCHAR2 ( 15 )  := xx_emf_cn_pkg.cn_success;
         x_req_return_status   BOOLEAN;
         x_req_id              NUMBER;
         x_dev_phase           VARCHAR2 ( 20 );
         x_phase               VARCHAR2 ( 20 );
         x_dev_status          VARCHAR2 ( 20 );
         x_status              VARCHAR2 ( 20 );
         x_message             VARCHAR2 ( 100 );
      BEGIN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'INSIDE PROCESS_DATA' );
xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'INSIDE PROCESS_DATA'||xx_emf_pkg.g_request_id||xx_emf_cn_pkg.cn_postval );
         FOR hdr_rec IN c_header
         LOOP
            IF ( hdr_rec.list_header_id IS NULL )
            THEN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'INSIDE1' );
               x_error_code := process_data_insert_mode (hdr_rec.list_header_id, hdr_rec.NAME );
            ELSE
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'INSIDE2' );
               x_error_code := process_data_insert_mode (hdr_rec.list_header_id, hdr_rec.NAME );
            END IF;
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'INSIDE HEADER PROCESS_DATA' );
            x_total_header := x_total_header + 1;
         END LOOP;

         RETURN x_error_code;
      END process_data;

      PROCEDURE update_record_count
      IS
         CURSOR c_get_total_cnt
         IS
            SELECT COUNT ( 1 ) total_count
              FROM xx_qp_price_list_stg mststg
             WHERE mststg.batch_id = g_batch_id
               --AND mststg.legacy_item_number = orgstg.legacy_item_number
               AND mststg.request_id = xx_emf_pkg.g_request_id;

         x_total_cnt     NUMBER;

         CURSOR c_get_error_cnt
         IS
            SELECT SUM ( a.error_count ) error_count
              FROM ( SELECT COUNT ( 1 ) error_count
                      FROM xx_qp_price_list_stg
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err
                    UNION ALL
                    SELECT COUNT ( 1 ) error_count
                      FROM xx_qp_price_list_pre
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err ) a;

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT ( 1 ) warn_count
              FROM xx_qp_price_list_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

         x_warn_cnt      NUMBER;

         CURSOR c_get_success_cnt
         IS
            SELECT COUNT ( 1 ) warn_count
              FROM xx_qp_price_list_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND (p_validate_and_load= g_validate_and_load and process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                                OR 1=1 and process_code = xx_emf_cn_pkg.cn_valid)
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

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Success count ' || (x_grp_success));
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Error count ' || (x_grp_error));
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Success count ' || (x_success_record));
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Success count header' || (x_success_header));
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error count ' || (x_error_record ));
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'x_success_cnt ' || (x_success_cnt));
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'x_error_cnt ' || (x_error_cnt));
         --
         xx_emf_pkg.update_recs_cnt ( p_total_recs_cnt        => x_total_cnt
                                    , p_success_recs_cnt      => x_success_cnt
                                    , p_warning_recs_cnt      => x_warn_cnt
                                    , p_error_recs_cnt        => x_error_cnt
                                    );
      END;
   --  l_max_error  VARCHAR2(10);
   BEGIN
      retcode := xx_emf_cn_pkg.cn_success;
      -- Set environment for EMF (Error Management Framework)
      -- If you want the process to continue even after the emf env not being set
      -- you must make p_required_flag from CN_YES to CN_NO
      -- If you do not pass proper value then it will be considered as CN_YES
      set_cnv_env ( p_batch_id => p_batch_id, p_required_flag => xx_emf_cn_pkg.cn_yes );
      -- Need to maintain the version on the files.
      -- when updating the package remember to incrimint the version such that it can be checked in the log file from front end.
      /*xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxinvitemcnvvl_pks);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxinvitemcnvvl_pkb);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxinvitemcnvtl_pks);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxinvitemcnvtl_pkb);*/
      -- include all the parameters to the conversion main here
      -- as medium log messages
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'Starting main process with the following parameters' );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'Main:Param - p_batch_id ' || p_batch_id );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'Main:Param - p_restart_flag ' || p_restart_flag );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'Main:Param - p_override_flag ' || p_override_flag );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'Main:Param - p_validate_and_load '|| p_validate_and_load);
      -- Call procedure to update records with the current request_id
      -- So that we can process only those records
      -- This gives a better handling of restartability
      mark_records_for_processing ( p_restart_flag => p_restart_flag, p_override_flag => p_override_flag );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'xx_emf_pkg.g_request_id ' || xx_emf_pkg.g_request_id );
      -- Once the records are identified based on the input parameters
      -- Start with pre-validations
      IF NVL ( p_override_flag, xx_emf_cn_pkg.cn_no ) = xx_emf_cn_pkg.cn_no
      THEN
         ------------------------------------------------------
         ----------( Stage 1: Pre Validations)-----------------
         ------------------------------------------------------
         -- Set the stage to Pre Validations
         set_stage ( xx_emf_cn_pkg.cn_preval );
         -- Change the validations package to the appropriate package name
         -- Modify the parameters as required
         -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
         -- PRE_VALIDATIONS SHOULD BE RETAINED
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'calling pre_validations: batch_id' || p_batch_id );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'err code 1:' || x_error_code );
         x_error_code := xx_qp_price_list_cnv_val_pkg.pre_validations ( p_batch_id );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'err code 2' || x_error_code );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'After pre-validations X_ERROR_CODE ' || x_error_code );
         ---------------
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'xx_emf_pkg.g_request_id ' || xx_emf_pkg.g_request_id );
         -- Update process code of staging records
         -- Also move the successful records to pre-interface tables
         update_staging_records ( xx_emf_cn_pkg.cn_success );
         --xx_emf_pkg.propagate_error (x_error_code);
         --Marking duplicate records in Organization Assignment Table
         -----mark_duplicate_combination;
         /*Assigning Global Variables using Process Setup Paramters*/
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'Assigning Global Variables using Process Setup Paramters..');
         assign_global_var;
         x_error_code := move_rec_pre_standard_table;
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_medium, 'move_rec_pre_standard_table' || x_error_code );
         xx_emf_pkg.propagate_error ( x_error_code );
      END IF;
      -- Once pre-validations are complete the loop through the pre-interface records
      -- and perform data validations on this table
      -- Set the stage to data Validations
      -----------------------------------------------------
      ----------( Stage 2: DATA VALIDATION)-----------------
      ------------------------------------------------------
      set_stage ( xx_emf_cn_pkg.cn_valid );
      x_error_code := xx_qp_price_list_cnv_val_pkg.common_data_validations(p_batch_id);
      OPEN c_xx_intg_pre_std_hdr ( xx_emf_cn_pkg.cn_preval );
      LOOP
         FETCH c_xx_intg_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'BULK COLLECT' );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                              , 'Before Loop - x_pre_std_hdr_table.count ' || x_pre_std_hdr_table.COUNT
                              );

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               /*xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                                  'item_number_genaration'
                                               || x_error_code
                              );
               item_number_genaration(x_pre_std_hdr_table (i));*/
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Before data Validation' );
               -- Perform header level Base App Validations
               x_error_code := xx_qp_price_list_cnv_val_pkg.data_validations (x_pre_std_hdr_table ( i )
                                                                             );
               --xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After data Validation'||p_header_line );
               --xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
               --                     ,    'x_error_code for  '
               --                       || x_pre_std_hdr_table ( i ).record_number
               --                       || ' is '
               --                       || x_error_code
               --                     );
               update_record_status ( x_pre_std_hdr_table ( i ), x_error_code );
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After Record Status : '||g_stage );
               xx_emf_pkg.propagate_error ( x_error_code );
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
               WHEN xx_emf_pkg.g_e_rec_error
               THEN
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'Record Level Error in Data Validations' );
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.cn_rec_err );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'Process Level Error in Data Validations' );
                  --update_pre_interface_records ( x_pre_std_hdr_table );
                  raise_application_error ( -20199, xx_emf_cn_pkg.cn_prc_err );
               WHEN OTHERS
               THEN
                  --update_record_status ( x_pre_std_hdr_table ( i ), x_error_code );
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After DV Record Status : '||g_stage );
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'When Others Error in Data Validations' );
                  xx_emf_pkg.error ( xx_emf_cn_pkg.cn_medium
                                   , xx_emf_cn_pkg.cn_tech_error
                                   , xx_emf_cn_pkg.cn_exp_unhand
                                   , x_pre_std_hdr_table ( i ).record_number
                                   );
            END;
         END LOOP;

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'x_pre_std_hdr_table.count ' || x_pre_std_hdr_table.COUNT );
         update_pre_interface_records ( x_pre_std_hdr_table );
         x_pre_std_hdr_table.DELETE;
         EXIT WHEN c_xx_intg_pre_std_hdr%NOTFOUND;
      END LOOP;

      IF c_xx_intg_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_intg_pre_std_hdr;
      END IF;
      -- Perform data derivations and process data only if p_validate_only_flag is set to VALIDATE_AND_LOAD
      IF p_validate_and_load = g_validate_and_load THEN
      -- Once data-validations are complete the loop through the pre-interface records
      -- and perform data derivations on this table
      -- Set the stage to data derivations
      ------------------------------------------------------
      ----------( Stage 3: Data Derivations)----------------
      ------------------------------------------------------
      set_stage ( xx_emf_cn_pkg.cn_derive );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'batch_id  ' || g_batch_id || ' is ' || x_error_code );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'VALUEEEEE  ' || xx_emf_cn_pkg.cn_success || ' is ' || xx_emf_cn_pkg.cn_valid );
      /*   UPDATE xx_qp_price_list_pre
            SET request_id = xx_emf_pkg.g_request_id
              , ERROR_CODE = xx_emf_cn_pkg.cn_success
              , process_code =  'Pre-Validations'
          WHERE batch_id = g_batch_id;commit;*/
      OPEN c_xx_intg_pre_std_hdr ( xx_emf_cn_pkg.cn_valid );
      --OPEN c_xx_intg_pre_std_hdr ( 'Pre-Validations' );
      LOOP
         FETCH c_xx_intg_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'table count  ' || x_pre_std_hdr_table.COUNT );

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               -- Perform header level Base App Validations
               x_error_code := xx_qp_price_list_cnv_val_pkg.data_derivations ( x_pre_std_hdr_table ( i ));
               /*xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low
                                    ,    'After data derivation x_error_code for  '
                                      || x_pre_std_hdr_table ( i ).record_number
                                      || ' is '
                                      || x_error_code
                                    );*/
               update_record_status ( x_pre_std_hdr_table ( i ), x_error_code );
               --xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After DD Record Status : '||g_stage );
               xx_emf_pkg.propagate_error ( x_error_code );
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
               WHEN xx_emf_pkg.g_e_rec_error
               THEN
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'Record Level Error in Data Derivation' );
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.cn_rec_err );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'Process Level Error in Data derivations' );
                  update_pre_interface_records ( x_pre_std_hdr_table );
                  raise_application_error ( -20199, xx_emf_cn_pkg.cn_prc_err );
               WHEN OTHERS
               THEN
                  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'When others Error in Data Derivation' );
                  xx_emf_pkg.error ( xx_emf_cn_pkg.cn_medium
                                   , xx_emf_cn_pkg.cn_tech_error
                                   , xx_emf_cn_pkg.cn_exp_unhand
                                   , x_pre_std_hdr_table ( i ).record_number
                                   );
            END;
         END LOOP;

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'x_pre_std_hdr_table.count ' || x_pre_std_hdr_table.COUNT );
         update_pre_interface_records ( x_pre_std_hdr_table );
         x_pre_std_hdr_table.DELETE;
         EXIT WHEN c_xx_intg_pre_std_hdr%NOTFOUND;
      END LOOP;

      IF c_xx_intg_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_intg_pre_std_hdr;
      END IF;

      -- Set the stage to Pre Validations
      set_stage ( xx_emf_cn_pkg.cn_postval );
      -- CCID099 changes
      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
      -- PRE_VALIDATIONS SHOULD BE RETAINED
      x_error_code := xx_qp_price_list_cnv_val_pkg.post_validations (p_batch_id);
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After post-validations X_ERROR_CODE ' || x_error_code );
      mark_records_complete ( xx_emf_cn_pkg.cn_postval );
      xx_emf_pkg.propagate_error ( x_error_code );
      -- Set the stage to Process Data
      set_stage ( xx_emf_cn_pkg.cn_process_data );
      --Call Process Data
      x_error_code := process_data;--********************************************
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'After process data X_ERROR_CODE ' || x_error_code );
      mark_records_complete ( xx_emf_cn_pkg.cn_process_data );
      --xx_emf_pkg.propagate_error ( x_error_code );
   END IF; -- For validate only flag check
      update_record_count;
      --x_error_code:=process_data_cross_reference;
      --xx_emf_pkg.propagate_error (x_error_code);
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Total record'||x_total_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Success record'||x_success_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error record'||x_error_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Total'||x_grp_total );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Success'||x_grp_success );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Error '||x_grp_error );
      /* Report for Header Information  */
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, '*************************************************');
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Total number of Header record count : '||x_total_header );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, '*************************************************');
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, '*************************************************');
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Total number of Header record success : '||x_success_header );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, '*************************************************');
      xx_emf_pkg.create_report;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Checking if this is OK' );
         fnd_file.put_line ( fnd_file.output, xx_emf_pkg.cn_env_not_set );
         --retcode := xx_emf_cn_pkg.cn_rec_err;
         update_record_count;
         xx_emf_pkg.create_report;
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Total record'||x_total_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Success record'||x_success_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error record'||x_error_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Total'||x_grp_total );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Success'||x_grp_success );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Error '||x_grp_error );

      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'xyz1: ' || SQLERRM );
         retcode := xx_emf_cn_pkg.cn_rec_err;
         update_record_count;
         xx_emf_pkg.create_report;
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Total record'||x_total_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Success record'||x_success_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error record'||x_error_record );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Total'||x_grp_total );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Success'||x_grp_success );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Error '||x_grp_error );

      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'xyz2: ' || SQLERRM );
         retcode := xx_emf_cn_pkg.cn_prc_err;
         update_record_count;
         xx_emf_pkg.create_report;
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Total record'||x_total_record );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Success record'||x_success_record );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error record'||x_error_record );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Total'||x_grp_total );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Success'||x_grp_success );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Error '||x_grp_error );
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'xyz3: ' || SQLERRM );
         retcode := xx_emf_cn_pkg.cn_prc_err;
         update_record_count;
         xx_emf_pkg.create_report;
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Total record'||x_total_record );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Success record'||x_success_record );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Error record'||x_error_record );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Total'||x_grp_total );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Success'||x_grp_success );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, 'Grp Error '||x_grp_error );
   END main;
   PROCEDURE submit_main (
            errbuf OUT VARCHAR2,
            retcode OUT VARCHAR2,
            p_batch_id IN VARCHAR2,
            p_restart_flag IN VARCHAR2,
            p_override_flag IN VARCHAR2,
            p_validate_and_load     IN  VARCHAR2
           )
   IS
      x_error_code          NUMBER                  := xx_emf_cn_pkg.cn_success;
      x_error_code_temp     NUMBER                  := xx_emf_cn_pkg.cn_success;
      x_request_id          NUMBER                  := 0;
      x_req_phase           VARCHAR2 (60);
      x_status              VARCHAR2 (60);
      x_dev_phase           VARCHAR2 (60);
      x_dev_status          VARCHAR2 (60);
      x_message             VARCHAR2 (2000);
      x_call_status         BOOLEAN         := FALSE;
      x_call_status2        BOOLEAN         := FALSE;
      x_index               NUMBER          := 0;
      TYPE t_req_id_type IS TABLE OF NUMBER
         INDEX BY BINARY_INTEGER;
      TYPE t_status_type IS TABLE OF BOOLEAN
         INDEX BY BINARY_INTEGER;
      t_req_id        t_req_id_type;
      t_status        t_status_type;
       -- CURSOR FOR VARIOUS Batch id
      CURSOR c_get_batch_ids
      IS
         SELECT  DISTINCT batch_id
           FROM xx_qp_price_list_stg hdr
          WHERE batch_id = NVL(p_batch_id, batch_id)
	 ORDER BY to_number(decode(batch_id,'INFORMAL',100, batch_id));
      PROCEDURE update_prc_list_precedence
      IS
         --Cursor to get Price List headers
         CURSOR c_list_headers
         IS
         SELECT qlh.name price_list_name,
                qlh.list_header_id,
                flv.tag precedence_value
           FROM fnd_lookup_values  flv,
                qp_list_headers qlh,
                fnd_application appl
          WHERE flv.lookup_type = 'XXINTG_PRICE_LIST_CONV_PRE'
            AND flv.language=userenv('lang')
            AND flv.enabled_flag='Y'
            AND sysdate between flv.start_date_active AND NVL(flv.end_date_active,sysdate)
            AND flv.view_application_id=appl.application_id
            AND appl.application_short_name='AU'
            AND qlh.name like flv.meaning||'%'
         ;
         --Cursor to get Price List Line Information
         CURSOR c_list_lines(p_list_header_id IN NUMBER)
         IS
         SELECT qll.list_header_id,
                qll.list_line_id
           FROM qp_list_lines qll
          WHERE qll.list_header_id=p_list_header_id
         ;
         gpr_price_list_rec            qp_price_list_pub.price_list_rec_type;
         gpr_price_list_val_rec        qp_price_list_pub.price_list_val_rec_type;
         gpr_price_list_line_tbl       qp_price_list_pub.price_list_line_tbl_type;
         gpr_price_list_line_val_tbl   qp_price_list_pub.price_list_line_val_tbl_type;
         gpr_qualifiers_tbl            qp_qualifier_rules_pub.qualifiers_tbl_type;
         gpr_qualifiers_val_tbl        qp_qualifier_rules_pub.qualifiers_val_tbl_type;
         gpr_pricing_attr_tbl          qp_price_list_pub.pricing_attr_tbl_type;
         gpr_pricing_attr_val_tbl      qp_price_list_pub.pricing_attr_val_tbl_type;
         ppr_price_list_rec            qp_price_list_pub.price_list_rec_type;
         ppr_price_list_val_rec        qp_price_list_pub.price_list_val_rec_type;
         ppr_price_list_line_tbl       qp_price_list_pub.price_list_line_tbl_type;
         ppr_price_list_line_val_tbl   qp_price_list_pub.price_list_line_val_tbl_type;
         ppr_qualifier_rules_rec       qp_qualifier_rules_pub.qualifier_rules_rec_type;
         ppr_qualifier_rules_val_rec   qp_qualifier_rules_pub.qualifier_rules_val_rec_type;
         ppr_qualifiers_tbl            qp_qualifier_rules_pub.qualifiers_tbl_type;
         ppr_qualifiers_val_tbl        qp_qualifier_rules_pub.qualifiers_val_tbl_type;
         ppr_pricing_attr_tbl          qp_price_list_pub.pricing_attr_tbl_type;
         ppr_pricing_attr_val_tbl      qp_price_list_pub.pricing_attr_val_tbl_type;
         x_return_status               VARCHAR2(15) := xx_emf_cn_pkg.cn_success;
         x_init_msg_list               VARCHAR2(1000):= FND_API.G_TRUE;
         gpr_return_status             VARCHAR2(1)  := NULL;
         gpr_msg_count                 NUMBER       := 0;
         x_msg_count                   NUMBER;
         x_msg_data                    VARCHAR2 (2000);
         gpr_msg_data                  VARCHAR2(32767);
         gpr_msg_data2                 VARCHAR2(32767);
         x_success_record              NUMBER;
         x_error_record                NUMBER;
         x_lpr_line_index              NUMBER := 0;
         x_precedence                  NUMBER := 220;
      BEGIN
         FOR r_list_headers IN c_list_headers
         LOOP
            BEGIN
               dbms_output.put_line('Processing Price List: '||r_list_headers.price_list_name);
               dbms_output.put_line('Processing Price List id: '||r_list_headers.list_header_id);
               --Set the price list precedence by price list name
               x_precedence := r_list_headers.precedence_value;
               dbms_output.put_line('Price List precedence: '||x_precedence);
               x_lpr_line_index := 1;
               FOR r_list_lines IN c_list_lines(r_list_headers.list_header_id)
               LOOP
                  BEGIN
                     gpr_price_list_line_tbl(x_lpr_line_index).list_header_id := r_list_lines.list_header_id;
	             gpr_price_list_line_tbl(x_lpr_line_index).list_line_id := r_list_lines.list_line_id;
                     gpr_price_list_line_tbl(x_lpr_line_index).product_precedence := x_precedence;
                     gpr_price_list_line_tbl(x_lpr_line_index).operation := qp_globals.g_opr_update;
                     x_lpr_line_index := x_lpr_line_index + 1;
                  EXCEPTION
	             WHEN OTHERS THEN
	                dbms_output.put_line(
                               'Error occured while assigning gpr_price_list_line_tbl in update_price_list  for Price List : '||r_list_headers.price_list_name
                               ||' Error: '||SQLERRM
                              );
                  END;
               END LOOP;
               fnd_msg_pub.initialize;
            BEGIN
               mo_global.init('QP');
	       --Call api to update the Price List Lines precedence
               qp_price_list_pub.process_price_list ( p_api_version_number           => 1
                                                    , p_init_msg_list                => fnd_api.g_true
                                                    , p_return_values                => fnd_api.g_false
                                                    , p_commit                       => fnd_api.g_false
                                                    , x_return_status                => gpr_return_status
                                                    , x_msg_count                    => gpr_msg_count
                                                    , x_msg_data                     => gpr_msg_data
                                                    , p_price_list_rec               => gpr_price_list_rec
                                                    , p_price_list_line_tbl          => gpr_price_list_line_tbl
                                                    , p_qualifiers_tbl               => gpr_qualifiers_tbl
                                                    , p_pricing_attr_tbl             => gpr_pricing_attr_tbl
                                                    , x_price_list_rec               => ppr_price_list_rec
                                                    , x_price_list_val_rec           => ppr_price_list_val_rec
                                                    , x_price_list_line_tbl          => ppr_price_list_line_tbl
                                                    , x_price_list_line_val_tbl      => ppr_price_list_line_val_tbl
                                                    , x_qualifiers_tbl               => ppr_qualifiers_tbl
                                                    , x_qualifiers_val_tbl           => ppr_qualifiers_val_tbl
                                                    , x_pricing_attr_tbl             => ppr_pricing_attr_tbl
                                                    , x_pricing_attr_val_tbl         => ppr_pricing_attr_val_tbl
                                                    );
               gpr_price_list_line_tbl.DELETE;
               gpr_pricing_attr_tbl.DELETE;
            EXCEPTION
               WHEN OTHERS THEN
	          dbms_output.put_line(
                               'Error occured calling api to update price list line for Price List: '||r_list_headers.price_list_name
                               ||' Error: '||SQLERRM
                              );

                  ROLLBACK;
            END;
            IF gpr_return_status IN ( 'E', 'U' )
            THEN
               gpr_msg_data  := '';
               gpr_msg_data2 := '';
               x_error_record:= x_error_record + 1;
               FOR k IN 1 .. gpr_msg_count
               LOOP
                  gpr_msg_data := substr(oe_msg_pub.get ( p_msg_index => k, p_encoded => 'F' ),1,160);
                  gpr_msg_data2 := substr(gpr_msg_data2 || LTRIM ( RTRIM ( gpr_msg_data )),1,200);
               END LOOP;
	       dbms_output.put_line(
                               'Price List line not updated  for Price List: '||r_list_headers.price_list_name
                               ||' Error: '||gpr_msg_data
                              );
               ROLLBACK;
            ELSE
	       dbms_output.put_line(x_lpr_line_index||' Price List Lines successfully updated  for Price List: '||r_list_headers.price_list_name
                              );
	       dbms_output.put_line('-------------------------------------------------------------------------');
               COMMIT;
            END IF;
         EXCEPTION
            WHEN fnd_api.g_exc_unexpected_error THEN
               FOR i IN 1 .. gpr_msg_count
               LOOP
                  oe_msg_pub.get ( p_msg_index          => i
                                 , p_encoded            => fnd_api.g_false
                                 , p_data               => gpr_msg_data
                                 , p_msg_index_out      => gpr_msg_count
                                 );
               END LOOP;
	       dbms_output.put_line(
                               'Price List line not created/updated  for Price List: '||r_list_headers.price_list_name
                               ||' Error: '||gpr_msg_data
                              );

               ROLLBACK;
            WHEN OTHERS THEN
               dbms_output.put_line('Price List line not created/updated  for Price List: '||r_list_headers.price_list_name
                               ||' Error: '||SQLERRM
                              );
               ROLLBACK;
         END;
      END LOOP;
   EXCEPTION
      WHEN OTHERS THEN
         dbms_output.put_line('Error occured while updating price list precedence'
                               ||' Error: '||SQLERRM
                              );

   END;
   BEGIN
      --Set environment for EMF (Error Management Framework)
      x_error_code := xx_emf_pkg.set_env;
      --Loop to fetch different Batch IDs
      FOR r_batch_ids IN c_get_batch_ids
      LOOP
         x_index := x_index + 1;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Submitmiting Price List Conversion for Batch Id: '||r_batch_ids.batch_id);
	 --Submiting Price List Conversion Program for each batch
         x_request_id := fnd_request.submit_request
                                   (application      => 'XXINTG',
                                    program          => 'XXQPPRICELISTCNV',
                                    argument1        => r_batch_ids.batch_id, --Batch Id
                                    argument2        => p_restart_flag,       --Restart Flag
                                    argument3        => p_override_flag,      --Override Flag
                                    argument4        => p_validate_and_load   --Validate_and_load
                                   );
	 COMMIT;
	 t_req_id(x_index) := x_request_id;
	 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Request ID for Price List Conversion  = ' ||x_request_id );
      END LOOP;
      --Wait for all the child programs to finish
      WHILE x_call_status = FALSE
      LOOP
         FOR n IN 1 .. x_index
         LOOP
            t_status (n) :=
                 fnd_concurrent.wait_for_request (t_req_id (n),
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
            x_call_status2 := x_call_status2 AND t_status (n);
         END LOOP;
         x_call_status := x_call_status2;
      END LOOP;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Executing script to update precedence of price list line');
      update_prc_list_precedence;
   EXCEPTION
      WHEN OTHERS THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in submit_main procedure '|| SQLERRM);
   END submit_main;
END xx_qp_price_list_cnv_pkg;
/


GRANT EXECUTE ON APPS.XX_QP_PRICE_LIST_CNV_PKG TO INTG_XX_NONHR_RO;
