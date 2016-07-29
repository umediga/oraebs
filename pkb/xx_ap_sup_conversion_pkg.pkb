DROP PACKAGE BODY APPS.XX_AP_SUP_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AP_SUP_CONVERSION_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 06-FEB-2012
 File Name     : XXAPSUPCNV.pks
 Description   : This script creates the body of the package
                 xx_ap_sup_conversion_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 06-FEB-2012 Sharath Babu          Initial development.
 14-MAY-2012 Sharath Babu          Modified to populate HCP falg
 23-MAY-2013 Sharath Babu          Modified as per Wave1
*/
----------------------------------------------------------------------
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

   PROCEDURE mark_records_for_processing (
      p_restart_flag    IN   VARCHAR2,
      p_override_flag   IN   VARCHAR2
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      -- If the override is set records should not be purged from the pre-interface tables
      IF p_restart_flag = xx_emf_cn_pkg.cn_all_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- purge from pre-interface tables and oracle standard tables
            DELETE FROM xx_ap_suppliers_pre_int
                  WHERE batch_id = g_batch_id;

            UPDATE xx_ap_suppliers_staging
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id;
         ELSE
            UPDATE xx_ap_suppliers_pre_int
               SET process_code = xx_emf_cn_pkg.cn_preval,
                   ERROR_CODE = xx_emf_cn_pkg.cn_success,
                   request_id = xx_emf_pkg.g_request_id
             WHERE batch_id = g_batch_id;
         END IF;

         DELETE FROM ap_suppliers_int
               WHERE attribute15 = g_batch_id;  --Modified for HCP flag
               --WHERE attribute11 = g_batch_id;
      ELSIF p_restart_flag = xx_emf_cn_pkg.cn_err_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- Update staging table
            UPDATE xx_ap_suppliers_staging
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
         UPDATE xx_ap_suppliers_staging
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new
          WHERE batch_id = g_batch_id
            AND EXISTS (
                   SELECT 1
                     FROM xx_ap_suppliers_pre_int a
                    WHERE batch_id = g_batch_id
                      AND process_code = xx_emf_cn_pkg.cn_preval
                      AND ERROR_CODE IN
                             (xx_emf_cn_pkg.cn_null,
                              xx_emf_cn_pkg.cn_rec_warn,
                              xx_emf_cn_pkg.cn_rec_err
                             )
                      AND record_number = a.record_number);

         DELETE FROM xx_ap_suppliers_pre_int
               WHERE batch_id = g_batch_id
                 AND process_code = xx_emf_cn_pkg.cn_preval
                 AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_null,
                         xx_emf_cn_pkg.cn_rec_warn,
                         xx_emf_cn_pkg.cn_rec_err
                        );

         -- Scenario 2 Data Validation Stage
         UPDATE xx_ap_suppliers_pre_int
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
         UPDATE xx_ap_suppliers_pre_int
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
         UPDATE xx_ap_suppliers_pre_int
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
         UPDATE xx_ap_suppliers_pre_int
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

   PROCEDURE set_stage (p_stage VARCHAR2)
   IS
   BEGIN
      g_stage := p_stage;
   END set_stage;

   PROCEDURE update_staging_records (p_error_code VARCHAR2)
   IS
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE xx_ap_suppliers_staging
         SET process_code = g_stage,
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
      errbuf                OUT      VARCHAR2,
      retcode               OUT      VARCHAR2,
      p_batch_id            IN       VARCHAR2,
      p_restart_flag        IN       VARCHAR2,
      p_override_flag       IN       VARCHAR2,
      p_validate_and_load   IN       VARCHAR2
   )
   IS
      x_error_code          NUMBER                := xx_emf_cn_pkg.cn_success;
      x_pre_std_hdr_table   g_xx_sup_cnv_pre_std_tab_type;

      -- Cursor for various stages
      CURSOR c_xx_intg_pre_std_hdr (cp_process_status VARCHAR2)
      IS
         SELECT   *
             FROM xx_ap_suppliers_pre_int hdr
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
         ORDER BY record_number;

      PROCEDURE update_record_status (
         p_conv_pre_std_hdr_rec   IN OUT   g_xx_sup_cnv_pre_std_rec_type,
         p_error_code             IN       VARCHAR2
      )
      IS
      BEGIN
         IF p_error_code IN
                        (xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err)
         THEN
            p_conv_pre_std_hdr_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            p_conv_pre_std_hdr_rec.ERROR_CODE := p_error_code;
         END IF;

         p_conv_pre_std_hdr_rec.process_code := g_stage;
      END update_record_status;

      PROCEDURE mark_records_complete (p_process_code VARCHAR2)
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         UPDATE xx_ap_suppliers_pre_int
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

      PROCEDURE update_pre_interface_records (
         p_cnv_pre_std_hdr_table   IN   g_xx_sup_cnv_pre_std_tab_type
      )
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
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

            UPDATE xx_ap_suppliers_pre_int
               SET   vendor_name                    =p_cnv_pre_std_hdr_table(indx).vendor_name
                    ,vendor_name_alt                =p_cnv_pre_std_hdr_table(indx).vendor_name_alt
                    ,segment1                       =p_cnv_pre_std_hdr_table(indx).segment1
                    ,summary_flag                   =p_cnv_pre_std_hdr_table(indx).summary_flag
                    ,enabled_flag                   =p_cnv_pre_std_hdr_table(indx).enabled_flag
                    ,employee_id                    =p_cnv_pre_std_hdr_table(indx).employee_id
                    ,vendor_type_lookup_code        =p_cnv_pre_std_hdr_table(indx).vendor_type_lookup_code
                    ,customer_num                   =p_cnv_pre_std_hdr_table(indx).customer_num
                    ,one_time_flag                  =p_cnv_pre_std_hdr_table(indx).one_time_flag
                    ,min_order_amount               =p_cnv_pre_std_hdr_table(indx).min_order_amount
                    ,ship_to_location_id            =p_cnv_pre_std_hdr_table(indx).ship_to_location_id
                    ,ship_to_location_code          =p_cnv_pre_std_hdr_table(indx).ship_to_location_code
                    ,bill_to_location_id            =p_cnv_pre_std_hdr_table(indx).bill_to_location_id
                    ,bill_to_location_code          =p_cnv_pre_std_hdr_table(indx).bill_to_location_code
                    ,ship_via_lookup_code           =p_cnv_pre_std_hdr_table(indx).ship_via_lookup_code
                    ,freight_terms_lookup_code      =p_cnv_pre_std_hdr_table(indx).freight_terms_lookup_code
                    ,fob_lookup_code                =p_cnv_pre_std_hdr_table(indx).fob_lookup_code
                    ,terms_id                       =p_cnv_pre_std_hdr_table(indx).terms_id
                    ,terms_name                     =p_cnv_pre_std_hdr_table(indx).terms_name
                    ,set_of_books_id                =p_cnv_pre_std_hdr_table(indx).set_of_books_id
                    ,always_take_disc_flag          =p_cnv_pre_std_hdr_table(indx).always_take_disc_flag
                    ,pay_date_basis_lookup_code     =p_cnv_pre_std_hdr_table(indx).pay_date_basis_lookup_code
                    ,pay_group_lookup_code          =p_cnv_pre_std_hdr_table(indx).pay_group_lookup_code
                    ,payment_priority               =p_cnv_pre_std_hdr_table(indx).payment_priority
                    ,invoice_currency_code          =p_cnv_pre_std_hdr_table(indx).invoice_currency_code
                    ,payment_currency_code          =p_cnv_pre_std_hdr_table(indx).payment_currency_code
                    ,invoice_amount_limit           =p_cnv_pre_std_hdr_table(indx).invoice_amount_limit
                    ,hold_all_payments_flag         =p_cnv_pre_std_hdr_table(indx).hold_all_payments_flag
                    ,hold_future_payments_flag      =p_cnv_pre_std_hdr_table(indx).hold_future_payments_flag
                    ,hold_reason                    =p_cnv_pre_std_hdr_table(indx).hold_reason
                    ,distribution_set_id            =p_cnv_pre_std_hdr_table(indx).distribution_set_id
                    ,distribution_set_name          =p_cnv_pre_std_hdr_table(indx).distribution_set_name
                    ,accts_pay_code_comb_value      =p_cnv_pre_std_hdr_table(indx).accts_pay_code_comb_value
                    ,prepay_code_comb_value         =p_cnv_pre_std_hdr_table(indx).prepay_code_comb_value
                    ,accts_pay_code_combination_id  =p_cnv_pre_std_hdr_table(indx).accts_pay_code_combination_id
                    ,prepay_code_combination_id     =p_cnv_pre_std_hdr_table(indx).prepay_code_combination_id
                    ,num_1099                       =p_cnv_pre_std_hdr_table(indx).num_1099
                    ,type_1099                      =p_cnv_pre_std_hdr_table(indx).type_1099
                    ,organization_type_lookup_code  =p_cnv_pre_std_hdr_table(indx).organization_type_lookup_code
                    ,vat_code                       =p_cnv_pre_std_hdr_table(indx).vat_code
                    ,start_date_active              =p_cnv_pre_std_hdr_table(indx).start_date_active
                    ,end_date_active                =p_cnv_pre_std_hdr_table(indx).end_date_active
                    ,minority_group_lookup_code     =p_cnv_pre_std_hdr_table(indx).minority_group_lookup_code
                    ,payment_method_lookup_code     =p_cnv_pre_std_hdr_table(indx).payment_method_lookup_code
                    ,women_owned_flag               =p_cnv_pre_std_hdr_table(indx).women_owned_flag
                    ,small_business_flag            =p_cnv_pre_std_hdr_table(indx).small_business_flag
                    ,standard_industry_class        =p_cnv_pre_std_hdr_table(indx).standard_industry_class
                    ,hold_flag                      =p_cnv_pre_std_hdr_table(indx).hold_flag
                    ,purchasing_hold_reason         =p_cnv_pre_std_hdr_table(indx).purchasing_hold_reason
                    ,hold_by                        =p_cnv_pre_std_hdr_table(indx).hold_by
                    ,hold_date                      =p_cnv_pre_std_hdr_table(indx).hold_date
                    ,terms_date_basis               =p_cnv_pre_std_hdr_table(indx).terms_date_basis
                    ,inspection_required_flag       =p_cnv_pre_std_hdr_table(indx).inspection_required_flag
                    ,receipt_required_flag          =p_cnv_pre_std_hdr_table(indx).receipt_required_flag
                    ,qty_rcv_tolerance              =p_cnv_pre_std_hdr_table(indx).qty_rcv_tolerance
                    ,qty_rcv_exception_code         =p_cnv_pre_std_hdr_table(indx).qty_rcv_exception_code
                    ,enforce_ship_to_location_code  =p_cnv_pre_std_hdr_table(indx).enforce_ship_to_location_code
                    ,days_early_receipt_allowed     =p_cnv_pre_std_hdr_table(indx).days_early_receipt_allowed
                    ,days_late_receipt_allowed      =p_cnv_pre_std_hdr_table(indx).days_late_receipt_allowed
                    ,receipt_days_exception_code    =p_cnv_pre_std_hdr_table(indx).receipt_days_exception_code
                    ,receiving_routing_id           =p_cnv_pre_std_hdr_table(indx).receiving_routing_id
                    ,allow_substitute_receipts_flag =p_cnv_pre_std_hdr_table(indx).allow_substitute_receipts_flag
                    ,allow_unordered_receipts_flag  =p_cnv_pre_std_hdr_table(indx).allow_unordered_receipts_flag
                    ,hold_unmatched_invoices_flag   =p_cnv_pre_std_hdr_table(indx).hold_unmatched_invoices_flag
                    ,exclusive_payment_flag         =p_cnv_pre_std_hdr_table(indx).exclusive_payment_flag
                    ,ap_tax_rounding_rule           =p_cnv_pre_std_hdr_table(indx).ap_tax_rounding_rule
                    ,auto_tax_calc_flag             =p_cnv_pre_std_hdr_table(indx).auto_tax_calc_flag
                    ,auto_tax_calc_override         =p_cnv_pre_std_hdr_table(indx).auto_tax_calc_override
                    ,amount_includes_tax_flag       =p_cnv_pre_std_hdr_table(indx).amount_includes_tax_flag
                    ,tax_verification_date          =p_cnv_pre_std_hdr_table(indx).tax_verification_date
                    ,name_control                   =p_cnv_pre_std_hdr_table(indx).name_control
                    ,state_reportable_flag          =p_cnv_pre_std_hdr_table(indx).state_reportable_flag
                    ,federal_reportable_flag        =p_cnv_pre_std_hdr_table(indx).federal_reportable_flag
                    ,attribute_category             =p_cnv_pre_std_hdr_table(indx).attribute_category
                    ,attribute1                     =p_cnv_pre_std_hdr_table(indx).attribute1
                    ,attribute2                     =p_cnv_pre_std_hdr_table(indx).attribute2
                    ,attribute3                     =p_cnv_pre_std_hdr_table(indx).attribute3
                    ,attribute4                     =p_cnv_pre_std_hdr_table(indx).attribute4
                    ,attribute5                     =p_cnv_pre_std_hdr_table(indx).attribute5
                    ,attribute6                     =p_cnv_pre_std_hdr_table(indx).attribute6
                    ,attribute7                     =p_cnv_pre_std_hdr_table(indx).attribute7
                    ,attribute8                     =p_cnv_pre_std_hdr_table(indx).attribute8
                    ,attribute9                     =p_cnv_pre_std_hdr_table(indx).attribute9
                    ,attribute10                    =p_cnv_pre_std_hdr_table(indx).attribute10
                    ,attribute11                    =p_cnv_pre_std_hdr_table(indx).attribute11
                    ,attribute12                    =p_cnv_pre_std_hdr_table(indx).attribute12
                    ,attribute13                    =p_cnv_pre_std_hdr_table(indx).attribute13
                    ,attribute14                    =p_cnv_pre_std_hdr_table(indx).attribute14
                    ,attribute15                    =p_cnv_pre_std_hdr_table(indx).attribute15
                    ,vat_registration_num           =p_cnv_pre_std_hdr_table(indx).vat_registration_num
                    ,auto_calculate_interest_flag   =p_cnv_pre_std_hdr_table(indx).auto_calculate_interest_flag
                    ,exclude_freight_from_discount  =p_cnv_pre_std_hdr_table(indx).exclude_freight_from_discount
                    ,tax_reporting_name             =p_cnv_pre_std_hdr_table(indx).tax_reporting_name
                    ,allow_awt_flag                 =p_cnv_pre_std_hdr_table(indx).allow_awt_flag
                    ,awt_group_id                   =p_cnv_pre_std_hdr_table(indx).awt_group_id
                    ,awt_group_name                 =p_cnv_pre_std_hdr_table(indx).awt_group_name
                    ,global_attribute1              =p_cnv_pre_std_hdr_table(indx).global_attribute1
                    ,global_attribute2              =p_cnv_pre_std_hdr_table(indx).global_attribute2
                    ,global_attribute3              =p_cnv_pre_std_hdr_table(indx).global_attribute3
                    ,global_attribute4              =p_cnv_pre_std_hdr_table(indx).global_attribute4
                    ,global_attribute5              =p_cnv_pre_std_hdr_table(indx).global_attribute5
                    ,global_attribute6              =p_cnv_pre_std_hdr_table(indx).global_attribute6
                    ,global_attribute7              =p_cnv_pre_std_hdr_table(indx).global_attribute7
                    ,global_attribute8              =p_cnv_pre_std_hdr_table(indx).global_attribute8
                    ,global_attribute9              =p_cnv_pre_std_hdr_table(indx).global_attribute9
                    ,global_attribute10             =p_cnv_pre_std_hdr_table(indx).global_attribute10
                    ,global_attribute11             =p_cnv_pre_std_hdr_table(indx).global_attribute11
                    ,global_attribute12             =p_cnv_pre_std_hdr_table(indx).global_attribute12
                    ,global_attribute13             =p_cnv_pre_std_hdr_table(indx).global_attribute13
                    ,global_attribute14             =p_cnv_pre_std_hdr_table(indx).global_attribute14
                    ,global_attribute15             =p_cnv_pre_std_hdr_table(indx).global_attribute15
                    ,global_attribute16             =p_cnv_pre_std_hdr_table(indx).global_attribute16
                    ,global_attribute17             =p_cnv_pre_std_hdr_table(indx).global_attribute17
                    ,global_attribute18             =p_cnv_pre_std_hdr_table(indx).global_attribute18
                    ,global_attribute19             =p_cnv_pre_std_hdr_table(indx).global_attribute19
                    ,global_attribute20             =p_cnv_pre_std_hdr_table(indx).global_attribute20
                    ,global_attribute_category      =p_cnv_pre_std_hdr_table(indx).global_attribute_category
                    ,edi_transaction_handling       =p_cnv_pre_std_hdr_table(indx).edi_transaction_handling
                    ,edi_payment_method             =p_cnv_pre_std_hdr_table(indx).edi_payment_method
                    ,edi_payment_format             =p_cnv_pre_std_hdr_table(indx).edi_payment_format
                    ,edi_remittance_method          =p_cnv_pre_std_hdr_table(indx).edi_remittance_method
                    ,edi_remittance_instruction     =p_cnv_pre_std_hdr_table(indx).edi_remittance_instruction
                    ,ece_tp_location_code           =p_cnv_pre_std_hdr_table(indx).ece_tp_location_code
                    ,bank_charge_bearer             =p_cnv_pre_std_hdr_table(indx).bank_charge_bearer
                    ,match_option                   =p_cnv_pre_std_hdr_table(indx).match_option
                    ,future_dated_payment_ccid      =p_cnv_pre_std_hdr_table(indx).future_dated_payment_ccid
                    ,create_debit_memo_flag         =p_cnv_pre_std_hdr_table(indx).create_debit_memo_flag
                    ,offset_tax_flag                =p_cnv_pre_std_hdr_table(indx).offset_tax_flag
                    ,iby_bank_charge_bearer         =p_cnv_pre_std_hdr_table(indx).iby_bank_charge_bearer
                    ,bank_instruction1_code        =p_cnv_pre_std_hdr_table(indx).bank_instruction1_code
                    ,bank_instruction2_code        =p_cnv_pre_std_hdr_table(indx).bank_instruction2_code
                    ,bank_instruction_details    =p_cnv_pre_std_hdr_table(indx).bank_instruction_details
                    ,payment_reason_code        =p_cnv_pre_std_hdr_table(indx).payment_reason_code
                    ,payment_reason_comments    =p_cnv_pre_std_hdr_table(indx).payment_reason_comments
                    ,payment_text_message1        =p_cnv_pre_std_hdr_table(indx).payment_text_message1
                    ,payment_text_message2        =p_cnv_pre_std_hdr_table(indx).payment_text_message2
                    ,payment_text_message3        =p_cnv_pre_std_hdr_table(indx).payment_text_message3
                    ,delivery_channel_code        =p_cnv_pre_std_hdr_table(indx).delivery_channel_code
                    ,payment_format_code        =p_cnv_pre_std_hdr_table(indx).payment_format_code
                    ,settlement_priority        =p_cnv_pre_std_hdr_table(indx).settlement_priority
                    ,payment_method_code        =p_cnv_pre_std_hdr_table(indx).payment_method_code
                    ,pay_awt_group_name         =p_cnv_pre_std_hdr_table(indx).pay_awt_group_name
	            ,process_code	        =p_cnv_pre_std_hdr_table(indx).process_code
		    ,error_code			=p_cnv_pre_std_hdr_table(indx).error_code
		    ,request_id			=p_cnv_pre_std_hdr_table(indx).request_id
                    ,last_updated_by                =x_last_updated_by
                    ,last_update_date               =x_last_update_date
                    ,last_update_login              =x_last_update_login
              WHERE record_number    = p_cnv_pre_std_hdr_table(indx).record_number
                AND batch_id         = p_cnv_pre_std_hdr_table(indx).batch_id;
         END LOOP;

         COMMIT;
      END update_pre_interface_records;

      FUNCTION move_rec_pre_standard_table
         RETURN NUMBER
      IS
         x_creation_date       DATE   := SYSDATE;
         x_created_by          NUMBER := fnd_global.user_id;
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         x_error_code          NUMBER := xx_emf_cn_pkg.cn_success;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside move_rec_pre_standard_table'
                              );

         -- Select only the appropriate columns that are required to be inserted into the
         -- Pre-Interface Table and insert from the Staging Table
         INSERT INTO xx_ap_suppliers_pre_int
                       (
                          vendor_interface_id
                         ,vendor_name
                         ,segment1
                         ,summary_flag
                         ,enabled_flag
                         ,employee_id
                         ,vendor_type_lookup_code
                         ,customer_num
                         ,one_time_flag
                         ,min_order_amount
                         ,ship_to_location_code
                         ,bill_to_location_code
                         ,ship_via_lookup_code
                         ,freight_terms_lookup_code
                         ,fob_lookup_code
                         ,terms_id
                         ,terms_name
                         ,set_of_books_id
                         ,always_take_disc_flag
                         ,pay_date_basis_lookup_code
                         ,pay_group_lookup_code
                         ,payment_priority
                         ,invoice_currency_code
                         ,payment_currency_code
                         ,invoice_amount_limit
                         ,hold_all_payments_flag
                         ,hold_future_payments_flag
                         ,hold_reason
                         ,accts_pay_code_comb_value
                         ,prepay_code_comb_value
                         ,num_1099
                         ,type_1099
                         ,organization_type_lookup_code
                         ,vat_code
                         ,start_date_active
                         ,end_date_active
                         ,minority_group_lookup_code
                         ,payment_method_lookup_code
                         ,women_owned_flag
                         ,small_business_flag
                         ,standard_industry_class
                         ,hold_flag
                         ,purchasing_hold_reason
                         ,hold_by
                         ,hold_date
                         ,terms_date_basis
                         ,inspection_required_flag
                         ,receipt_required_flag
                         ,qty_rcv_tolerance
                         ,qty_rcv_exception_code
                         ,enforce_ship_to_location_code
                         ,days_early_receipt_allowed
                         ,days_late_receipt_allowed
                         ,receipt_days_exception_code
                         ,receiving_routing_id
                         ,allow_substitute_receipts_flag
                         ,allow_unordered_receipts_flag
                         ,hold_unmatched_invoices_flag
                         ,exclusive_payment_flag
                         ,ap_tax_rounding_rule
                         ,auto_tax_calc_flag
                         ,auto_tax_calc_override
                         ,amount_includes_tax_flag
                         ,tax_verification_date
                         ,name_control
                         ,state_reportable_flag
                         ,federal_reportable_flag
                         ,attribute_category
                         ,attribute1
                         ,attribute2
                         ,attribute3
                         ,attribute4
                         ,attribute5
                         ,attribute6
                         ,attribute7
                         ,attribute8
                         ,attribute9
                         ,attribute10
                         ,attribute11
                         ,attribute12
                         ,attribute13
                         ,attribute14
                         ,attribute15
                         ,vat_registration_num
                         ,auto_calculate_interest_flag
                         ,exclude_freight_from_discount
                         ,tax_reporting_name
                         ,allow_awt_flag
                         ,awt_group_name
                         ,bank_charge_bearer
                         ,match_option
                         ,future_dated_payment_ccid
                         ,create_debit_memo_flag
                         ,offset_tax_flag
                         ,ece_tp_location_code
                         ,iby_bank_charge_bearer
                         ,bank_instruction1_code
                         ,bank_instruction2_code
                         ,bank_instruction_details
                         ,payment_reason_code
                         ,payment_reason_comments
                         ,payment_text_message1
                         ,payment_text_message2
                         ,payment_text_message3
                         ,delivery_channel_code
                         ,payment_format_code
                         ,settlement_priority
                         ,payment_method_code
                         ,pay_awt_group_name
                         ,batch_id
			 ,record_number
			 ,process_code
			 ,error_code
			 ,request_id
			 ,created_by
                         ,creation_date
                         ,last_update_date
                         ,last_updated_by
                         ,last_update_login
                             )
                     SELECT
                          ap_suppliers_int_s.nextval
                         ,vendor_name
                         ,segment1
                         ,summary_flag
                         ,enabled_flag
                         ,employee_id
                         ,vendor_type_lookup_code
                         ,customer_num
                         ,one_time_flag
                         ,min_order_amount
                         ,ship_to_location_code
                         ,bill_to_location_code
                         ,ship_via_lookup_code
                         ,freight_terms_lookup_code
                         ,fob_lookup_code
                         ,terms_id
                         ,terms_name
                         ,set_of_books_id
                         ,always_take_disc_flag
                         ,pay_date_basis_lookup_code
                         ,pay_group_lookup_code
                         ,payment_priority
                         ,invoice_currency_code
                         ,payment_currency_code
                         ,invoice_amount_limit
                         ,hold_all_payments_flag
                         ,hold_future_payments_flag
                         ,hold_reason
                         ,accts_pay_code_comb_value
                         ,prepay_code_comb_value
                         ,num_1099
                         ,type_1099
                         ,organization_type_lookup_code
                         ,vat_code
                         ,start_date_active
                         ,end_date_active
                         ,minority_group_lookup_code
                         ,payment_method_lookup_code
                         ,women_owned_flag
                         ,small_business_flag
                         ,standard_industry_class
                         ,hold_flag
                         ,purchasing_hold_reason
                         ,hold_by
                         ,hold_date
                         ,terms_date_basis
                         ,inspection_required_flag
                         ,receipt_required_flag
                         ,qty_rcv_tolerance
                         ,qty_rcv_exception_code
                         ,enforce_ship_to_location_code
                         ,days_early_receipt_allowed
                         ,days_late_receipt_allowed
                         ,receipt_days_exception_code
                         ,receiving_routing_id
                         ,allow_substitute_receipts_flag
                         ,allow_unordered_receipts_flag
                         ,hold_unmatched_invoices_flag
                         ,exclusive_payment_flag
                         ,ap_tax_rounding_rule
                         ,auto_tax_calc_flag
                         ,auto_tax_calc_override
                         ,amount_includes_tax_flag
                         ,tax_verification_date
                         ,name_control
                         ,state_reportable_flag
                         ,federal_reportable_flag
                         ,attribute_category
                         ,attribute1
                         ,attribute2
                         ,attribute3
                         ,attribute4
                         ,attribute5
                         ,attribute6
                         ,attribute7
                         ,attribute8
                         ,attribute9
                         ,attribute10
                         ,attribute11
                         ,attribute12
                         ,attribute13
                         ,attribute14
                         ,attribute15
                         ,vat_registration_num
                         ,auto_calculate_interest_flag
                         ,exclude_freight_from_discount
                         ,tax_reporting_name
                         ,allow_awt_flag
                         ,awt_group_name
                         ,bank_charge_bearer
                         ,match_option
                         ,future_dated_payment_ccid
                         ,create_debit_memo_flag
                         ,offset_tax_flag
                         ,ece_tp_location_code
                         ,iby_bank_charge_bearer
                         ,bank_instruction1_code
                         ,bank_instruction2_code
                         ,bank_instruction_details
                         ,payment_reason_code
                         ,payment_reason_comments
                         ,payment_text_message1
                         ,payment_text_message2
                         ,payment_text_message3
                         ,delivery_channel_code
                         ,payment_format_code
                         ,settlement_priority
                         ,payment_method_code
                         ,pay_awt_group_name
                         ,batch_id
                         ,record_number
                         ,g_stage
                         ,error_code
                         ,request_id
                         ,x_created_by
                         ,x_creation_date
                         ,x_last_update_date
                         ,x_last_updated_by
                         ,x_last_update_login
                         FROM xx_ap_suppliers_staging
                              WHERE BATCH_ID = G_BATCH_ID
                                AND process_code = xx_emf_cn_pkg.CN_PREVAL
                                AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);
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

      FUNCTION process_data
         RETURN NUMBER
      IS
         x_return_status   VARCHAR2 (15) := xx_emf_cn_pkg.cn_success;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'The batch id is ' || g_batch_id
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'The Request id is ' || xx_emf_pkg.g_request_id
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'The error_code id is '
                               || xx_emf_cn_pkg.cn_success
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'The process code id is '
                               || xx_emf_cn_pkg.cn_postval
                              );

         -- Change the logic to whatever needs to be done
         -- with valid records in the pre-interface tables
         -- either call the appropriate API to process the data
         -- or to insert into an interface table
         INSERT INTO ap_suppliers_int
                             (
                                  vendor_interface_id
                     ,vendor_name
                     ,vendor_name_alt
                     ,segment1
                     ,summary_flag
                     ,enabled_flag
                     ,employee_id
                     ,vendor_type_lookup_code
                     ,customer_num
                     ,one_time_flag
                     ,min_order_amount
                     ,ship_to_location_id
                     ,ship_to_location_code
                     ,bill_to_location_id
                     ,bill_to_location_code
                     ,ship_via_lookup_code
                     ,freight_terms_lookup_code
                     ,fob_lookup_code
                     ,terms_id
                     ,terms_name
                     ,set_of_books_id
                     ,always_take_disc_flag
                     ,pay_date_basis_lookup_code
                     ,pay_group_lookup_code
                     ,payment_priority
                     ,invoice_currency_code
                     ,payment_currency_code
                     ,invoice_amount_limit
                     ,hold_all_payments_flag
                     ,hold_future_payments_flag
                     ,hold_reason
                     ,distribution_set_id
                     ,distribution_set_name
                     ,accts_pay_code_combination_id
                     ,prepay_code_combination_id
                     ,num_1099
                     ,type_1099
                     ,organization_type_lookup_code
                     ,vat_code
                     ,start_date_active
                     ,end_date_active
                     ,minority_group_lookup_code
                     ,payment_method_lookup_code
                     ,women_owned_flag
                     ,small_business_flag
                     ,standard_industry_class
                     ,hold_flag
                     ,purchasing_hold_reason
                     ,hold_by
                     ,hold_date
                     ,terms_date_basis
                     ,inspection_required_flag
                     ,receipt_required_flag
                     ,qty_rcv_tolerance
                     ,qty_rcv_exception_code
                     ,enforce_ship_to_location_code
                     ,days_early_receipt_allowed
                     ,days_late_receipt_allowed
                     ,receipt_days_exception_code
                     ,receiving_routing_id
                     ,allow_substitute_receipts_flag
                     ,allow_unordered_receipts_flag
                     ,hold_unmatched_invoices_flag
                     ,exclusive_payment_flag
                     ,ap_tax_rounding_rule
                     ,auto_tax_calc_flag
                     ,auto_tax_calc_override
                     ,amount_includes_tax_flag
                     ,tax_verification_date
                     ,name_control
                     ,state_reportable_flag
                     ,federal_reportable_flag
                     ,attribute_category
                     ,attribute1
                     ,attribute2
                     ,attribute3
                     ,attribute4
                     ,attribute5
                     ,attribute6
                     ,attribute7
                     ,attribute8
                     ,attribute9
                     ,attribute10
                     ,attribute11
                     ,attribute12
                     ,attribute13
                     ,attribute14
                     ,attribute15
                     ,vat_registration_num
                     ,auto_calculate_interest_flag
                     ,exclude_freight_from_discount
                     ,tax_reporting_name
                     ,allow_awt_flag
                     ,awt_group_id
                     ,awt_group_name
                     ,global_attribute1
                     ,global_attribute2
                     ,global_attribute3
                     ,global_attribute4
                     ,global_attribute5
                     ,global_attribute6
                     ,global_attribute7
                     ,global_attribute8
                     ,global_attribute9
                     ,global_attribute10
                     ,global_attribute11
                     ,global_attribute12
                     ,global_attribute13
                     ,global_attribute14
                     ,global_attribute15
                     ,global_attribute16
                     ,global_attribute17
                     ,global_attribute18
                     ,global_attribute19
                     ,global_attribute20
                     ,global_attribute_category
                     ,edi_transaction_handling
                     ,edi_payment_method
                     ,edi_payment_format
                     ,edi_remittance_method
                     ,edi_remittance_instruction
                     ,bank_charge_bearer
                     ,match_option
                     ,future_dated_payment_ccid
                     ,create_debit_memo_flag
                     ,offset_tax_flag
                     ,ece_tp_location_code
                         ,iby_bank_charge_bearer
                     ,bank_instruction1_code
                     ,bank_instruction2_code
                     ,bank_instruction_details
                     ,payment_reason_code
                     ,payment_reason_comments
                     ,payment_text_message1
                     ,payment_text_message2
                     ,payment_text_message3
                     ,delivery_channel_code
                     ,payment_format_code
                     ,settlement_priority
                     ,payment_method_code
                                     ,pay_awt_group_name
                                     ,status
                                     ,created_by
                                     ,creation_date

                              )
                     SELECT
                         vendor_interface_id
                ,vendor_name
                ,vendor_name_alt
                ,segment1
                ,summary_flag
                ,enabled_flag
                ,employee_id
                ,vendor_type_lookup_code
                ,customer_num
                ,one_time_flag
                ,min_order_amount
                ,ship_to_location_id
                ,ship_to_location_code
                ,bill_to_location_id
                ,bill_to_location_code
                ,ship_via_lookup_code
                ,freight_terms_lookup_code
                ,fob_lookup_code
                ,terms_id
                ,terms_name
                ,set_of_books_id
                ,always_take_disc_flag
                ,pay_date_basis_lookup_code
                ,pay_group_lookup_code
                ,payment_priority
                ,invoice_currency_code
                ,payment_currency_code
                ,invoice_amount_limit
                ,hold_all_payments_flag
                ,hold_future_payments_flag
                ,hold_reason
                ,distribution_set_id
                ,distribution_set_name
                ,accts_pay_code_combination_id
                ,prepay_code_combination_id
                ,num_1099
                ,type_1099
                ,organization_type_lookup_code
                ,vat_code
                ,start_date_active
                ,end_date_active
                ,minority_group_lookup_code
                ,payment_method_lookup_code
                ,women_owned_flag
                ,small_business_flag
                ,standard_industry_class
                ,hold_flag
                ,purchasing_hold_reason
                ,hold_by
                ,hold_date
                ,terms_date_basis
                ,inspection_required_flag
                ,receipt_required_flag
                ,qty_rcv_tolerance
                ,qty_rcv_exception_code
                ,enforce_ship_to_location_code
                ,days_early_receipt_allowed
                ,days_late_receipt_allowed
                ,receipt_days_exception_code
                ,receiving_routing_id
                ,allow_substitute_receipts_flag
                ,allow_unordered_receipts_flag
                ,hold_unmatched_invoices_flag
                ,exclusive_payment_flag
                ,ap_tax_rounding_rule
                ,auto_tax_calc_flag
                ,auto_tax_calc_override
                ,amount_includes_tax_flag
                ,tax_verification_date
                ,name_control
                ,state_reportable_flag
                ,federal_reportable_flag
                ,attribute_category
                ,attribute1
                ,attribute2
                ,attribute3
                ,attribute4
                ,attribute5
                ,attribute6
                ,attribute7
                ,attribute8
                ,attribute9
                ,attribute10
                ,attribute11   --batch_id  --attribute11 Modified for HCP flag
                ,attribute12
                ,attribute13
                ,attribute14
                ,batch_id      --attribute15 Modified for HCP flag
                ,vat_registration_num
                ,auto_calculate_interest_flag
                ,exclude_freight_from_discount
                ,tax_reporting_name
                ,allow_awt_flag
                ,awt_group_id
                ,awt_group_name
                ,global_attribute1
                ,global_attribute2
                ,global_attribute3
                ,global_attribute4
                ,global_attribute5
                ,global_attribute6
                ,global_attribute7
                ,global_attribute8
                ,global_attribute9
                ,global_attribute10
                ,global_attribute11
                ,global_attribute12
                ,global_attribute13
                ,global_attribute14
                ,global_attribute15
                ,global_attribute16
                ,global_attribute17
                ,global_attribute18
                ,global_attribute19
                ,global_attribute20
                ,global_attribute_category
                ,edi_transaction_handling
                ,edi_payment_method
                ,edi_payment_format
                ,edi_remittance_method
                ,edi_remittance_instruction
                ,bank_charge_bearer
                ,match_option
                ,future_dated_payment_ccid
                ,create_debit_memo_flag
                ,offset_tax_flag
                ,ece_tp_location_code
                ,iby_bank_charge_bearer
                ,bank_instruction1_code
                ,bank_instruction2_code
                ,bank_instruction_details
                ,payment_reason_code
                ,payment_reason_comments
                ,payment_text_message1
                ,payment_text_message2
                ,payment_text_message3
                ,delivery_channel_code
                ,payment_format_code
                ,settlement_priority
                ,payment_method_code
                            ,pay_awt_group_name
                        ,'NEW'
                        ,created_by
                        ,creation_date
                  FROM xx_ap_suppliers_pre_int
                              WHERE batch_id = G_BATCH_ID
                                AND request_id = xx_emf_pkg.G_REQUEST_ID
                                AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                           AND process_code = xx_emf_cn_pkg.CN_POSTVAL;

         COMMIT;
         RETURN x_return_status;
      END process_data;

      PROCEDURE update_record_count
      IS
         CURSOR c_get_total_cnt
         IS
            SELECT SUM (total_count)
              FROM (SELECT COUNT (1) total_count
                      FROM xx_ap_suppliers_staging
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                    UNION
                    SELECT COUNT (1) total_count
                      FROM xx_ap_suppliers_pre_int
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id);

         x_total_cnt     NUMBER;

         CURSOR c_get_error_cnt
         IS
            SELECT SUM (error_count)
              FROM (SELECT COUNT (1) error_count
                      FROM xx_ap_suppliers_staging
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err
                    UNION ALL
                    SELECT COUNT (1) error_count
                      FROM xx_ap_suppliers_pre_int
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err);

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_ap_suppliers_pre_int
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

         x_warn_cnt      NUMBER;

         CURSOR c_get_success_cnt
         IS
            SELECT COUNT (1) succ_count
              FROM xx_ap_suppliers_pre_int
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               --AND process_code = xx_emf_cn_pkg.cn_process_data
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
      END update_record_count;

 -------------- Procedure MAIN code begins here ------------------------

 BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Main  begins');
      retcode := xx_emf_cn_pkg.cn_success;
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
      -- Call procedure to update records with the current request_id
      -- So that we can process only those records
      -- This gives a better handling of restartability
      mark_records_for_processing (p_restart_flag       => p_restart_flag,
                                   p_override_flag      => p_override_flag
                                  );

      -- Once the records are identified based on the input parameters
      -- Start with pre-validations
      IF NVL (p_override_flag, xx_emf_cn_pkg.cn_no) = xx_emf_cn_pkg.cn_no
      THEN
         -- Set the stage to Pre Validations
         set_stage (xx_emf_cn_pkg.cn_preval);
         -- Change the validations package to the appropriate package name
         -- Modify the parameters as required
         -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
         -- PRE_VALIDATIONS SHOULD BE RETAINED
         x_error_code := xx_ap_sup_cnv_validations_pkg.pre_validations ();
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

      /* Added for batch validation */
      -- Once the records are identified based on the input parameters
      -- Start with batch-validations
      -- Set the stage to batch Validations
      set_stage (xx_emf_cn_pkg.cn_batchval);
      x_error_code :=
                  xx_ap_sup_cnv_validations_pkg.batch_validations (p_batch_id);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'After batch_validations X_ERROR_CODE '
                            || x_error_code
                           );
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
               -- Perform Data Validations
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Calling Data Validations ..');
               x_error_code :=
                  xx_ap_sup_cnv_validations_pkg.data_validations
                                                      (x_pre_std_hdr_table (i)
                                                      ,p_validate_and_load          --Added as per Wave1
                                                      );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'After Calling Data Validations ..'
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
               -- Perform Data Derivations
               x_error_code :=
                  xx_ap_sup_cnv_validations_pkg.data_derivations
                                                   (x_pre_std_hdr_table (i)
                                                   );
               xx_emf_pkg.write_log
                                   (xx_emf_cn_pkg.cn_low,
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
                  raise_application_error (-20199,
                                           xx_emf_cn_pkg.cn_prc_err);
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

      -- Set the stage to Post Validations
      set_stage (xx_emf_cn_pkg.cn_postval);
      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      x_error_code := xx_ap_sup_cnv_validations_pkg.post_validations ();
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'After post-validations X_ERROR_CODE '
                            || x_error_code
                           );
      mark_records_complete (xx_emf_cn_pkg.cn_postval);
      xx_emf_pkg.propagate_error (x_error_code);
      -- Perform process data only if p_validate_and_load is set to VALIDATE_AND_LOAD
      IF p_validate_and_load = g_validate_and_load
      THEN
         -- Set the stage to Process Data
         set_stage (xx_emf_cn_pkg.cn_process_data);
         x_error_code := process_data ();
         mark_records_complete (xx_emf_cn_pkg.cn_process_data);
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;                                 --End If for p_validate_and_load

      update_record_count;
      --xx_emf_pkg.create_report; Modified as per Wave1 to display distinct errors
      xx_emf_pkg.generate_report;

   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               xx_emf_pkg.cn_env_not_set);
         retcode := xx_emf_cn_pkg.cn_rec_err;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         retcode := xx_emf_cn_pkg.cn_rec_err;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         retcode := xx_emf_cn_pkg.cn_prc_err;
         xx_emf_pkg.create_report;
      WHEN OTHERS
      THEN
         retcode := xx_emf_cn_pkg.cn_prc_err;
         xx_emf_pkg.create_report;
   END main;
END xx_ap_sup_conversion_pkg;
/


GRANT EXECUTE ON APPS.XX_AP_SUP_CONVERSION_PKG TO INTG_XX_NONHR_RO;
