DROP PACKAGE BODY APPS.XX_AP_SUS_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AP_SUS_CONVERSION_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 06-FEB-2012
 File Name     : XXAPSUSCNV.pks
 Description   : This script creates the body of the package
                 xx_ap_sus_conversion_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 06-FEB-2012 Sharath Babu          Initial development.
 14-MAY-2012 Sharath Babu          Modified to populate HCP falg
 23-MAY-2013 Sharath Babu          Modified as per Wave1
*/
----------------------------------------------------------------------

   -- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
   -- START RESTRICTIONS

   --------------------------------------------------------------------------------
 ------------------< set_cnv_env >-----------------------------------------------
 --------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
    ------------------< mark_records_for_processing >-------------------------------
    --------------------------------------------------------------------------------
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
            DELETE FROM xx_ap_sup_sites_pre_int
                  WHERE batch_id = g_batch_id;

            UPDATE xx_ap_sup_sites_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id;
         ELSE
            UPDATE xx_ap_sup_sites_pre_int
               SET process_code = xx_emf_cn_pkg.cn_preval,
                   ERROR_CODE = xx_emf_cn_pkg.cn_success,
                   request_id = xx_emf_pkg.g_request_id
             WHERE batch_id = g_batch_id;
         END IF;

         DELETE FROM ap_supplier_sites_int
               WHERE attribute15 = g_batch_id; --Modified for HCP flag
               --WHERE attribute11 = g_batch_id;
      ELSIF p_restart_flag = xx_emf_cn_pkg.cn_err_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- Update staging table
            UPDATE xx_ap_sup_sites_stg
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
         UPDATE xx_ap_sup_sites_stg
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new
          WHERE batch_id = g_batch_id
            AND EXISTS (
                   SELECT 1
                     FROM xx_ap_sup_sites_pre_int a
                    WHERE batch_id = g_batch_id
                      AND process_code = xx_emf_cn_pkg.cn_preval
                      AND ERROR_CODE IN
                             (xx_emf_cn_pkg.cn_null,
                              xx_emf_cn_pkg.cn_rec_warn,
                              xx_emf_cn_pkg.cn_rec_err
                             )
                      AND record_number = a.record_number);

         DELETE FROM xx_ap_sup_sites_pre_int
               WHERE batch_id = g_batch_id
                 AND process_code = xx_emf_cn_pkg.cn_preval
                 AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_null,
                         xx_emf_cn_pkg.cn_rec_warn,
                         xx_emf_cn_pkg.cn_rec_err
                        );

         -- Scenario 2 Data Validation Stage
         UPDATE xx_ap_sup_sites_pre_int
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
         UPDATE xx_ap_sup_sites_pre_int
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
         UPDATE xx_ap_sup_sites_pre_int
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
         UPDATE xx_ap_sup_sites_pre_int
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

    --------------------------------------------------------------------------------
    ------------------< set_stage >-------------------------------------------------
    --------------------------------------------------------------------------------
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
      UPDATE xx_ap_sup_sites_stg
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

   --------------------------------------------------------------------------------
 ------------------< main >------------------------------------------------------
 --------------------------------------------------------------------------------
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
      x_pre_std_hdr_table   g_xx_sus_cnv_pre_std_tab_type;
      x_process_code        VARCHAR2 (100);

      -- Cursor for various stages
      CURSOR c_xx_ap_sup_sites_pre_int (cp_process_status VARCHAR2)
      IS
         SELECT   *
             FROM xx_ap_sup_sites_pre_int hdr
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
         ORDER BY record_number;

      PROCEDURE update_record_status (
         p_conv_pre_std_hdr_rec   IN OUT   g_xx_sus_cnv_pre_std_rec_type,
         p_error_code             IN       VARCHAR2
      )
      IS
      BEGIN
         IF p_error_code IN
                        (xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err)
         THEN
            p_conv_pre_std_hdr_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            p_conv_pre_std_hdr_rec.ERROR_CODE :=
               xx_intg_common_pkg.find_max
                                     (p_error_code,
                                      NVL (p_conv_pre_std_hdr_rec.ERROR_CODE,
                                           xx_emf_cn_pkg.cn_success
                                          )
                                     );
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
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  '  inside mark_records_complete '
                               || p_process_code
                              );
         UPDATE xx_ap_sup_sites_pre_int
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
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'others ' || p_process_code
                                 );
      END mark_records_complete;

      PROCEDURE update_pre_interface_records (
         p_cnv_pre_std_hdr_table   IN   g_xx_sus_cnv_pre_std_tab_type
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

            UPDATE  xx_ap_sup_sites_pre_int
               SET  vendor_id                     =p_cnv_pre_std_hdr_table(indx).vendor_id
                    ,vendor_site_code              =p_cnv_pre_std_hdr_table(indx).vendor_site_code
                    ,vendor_site_code_alt          =p_cnv_pre_std_hdr_table(indx).vendor_site_code_alt
                    ,purchasing_site_flag          =p_cnv_pre_std_hdr_table(indx).purchasing_site_flag
                    ,rfq_only_site_flag            =p_cnv_pre_std_hdr_table(indx).rfq_only_site_flag
                    ,pay_site_flag                 =p_cnv_pre_std_hdr_table(indx).pay_site_flag
                    ,attention_ar_flag             =p_cnv_pre_std_hdr_table(indx).attention_ar_flag
                    ,address_line1                 =p_cnv_pre_std_hdr_table(indx).address_line1
                    ,address_lines_alt             =p_cnv_pre_std_hdr_table(indx).address_lines_alt
                    ,address_line2                 =p_cnv_pre_std_hdr_table(indx).address_line2
                    ,address_line3                 =p_cnv_pre_std_hdr_table(indx).address_line3
                    ,city                          =p_cnv_pre_std_hdr_table(indx).city
                    ,state                         =p_cnv_pre_std_hdr_table(indx).state
                    ,zip                           =p_cnv_pre_std_hdr_table(indx).zip
                    ,province                      =p_cnv_pre_std_hdr_table(indx).province
                    ,country                       =p_cnv_pre_std_hdr_table(indx).country
                    ,area_code                     =p_cnv_pre_std_hdr_table(indx).area_code
                    ,phone                         =p_cnv_pre_std_hdr_table(indx).phone
                    ,customer_num                  =p_cnv_pre_std_hdr_table(indx).customer_num
                    ,ship_to_location_id           =p_cnv_pre_std_hdr_table(indx).ship_to_location_id
                    ,ship_to_location_code         =p_cnv_pre_std_hdr_table(indx).ship_to_location_code
                    ,bill_to_location_id           =p_cnv_pre_std_hdr_table(indx).bill_to_location_id
                    ,bill_to_location_code         =p_cnv_pre_std_hdr_table(indx).bill_to_location_code
                    ,ship_via_lookup_code          =p_cnv_pre_std_hdr_table(indx).ship_via_lookup_code
                    ,freight_terms_lookup_code     =p_cnv_pre_std_hdr_table(indx).freight_terms_lookup_code
                    ,fob_lookup_code               =p_cnv_pre_std_hdr_table(indx).fob_lookup_code
                    ,inactive_date                 =p_cnv_pre_std_hdr_table(indx).inactive_date
                    ,fax                           =p_cnv_pre_std_hdr_table(indx).fax
                    ,fax_area_code                 =p_cnv_pre_std_hdr_table(indx).fax_area_code
                    ,telex                         =p_cnv_pre_std_hdr_table(indx).telex
                    ,payment_method_lookup_code    =p_cnv_pre_std_hdr_table(indx).payment_method_lookup_code
                    ,terms_date_basis              =p_cnv_pre_std_hdr_table(indx).terms_date_basis
                    ,vat_code                      =p_cnv_pre_std_hdr_table(indx).vat_code
                    ,distribution_set_id           =p_cnv_pre_std_hdr_table(indx).distribution_set_id
                    ,distribution_set_name         =p_cnv_pre_std_hdr_table(indx).distribution_set_name
                    ,accts_pay_code_comb_value     =p_cnv_pre_std_hdr_table(indx).accts_pay_code_comb_value
                    ,prepay_code_comb_value        =p_cnv_pre_std_hdr_table(indx).prepay_code_comb_value
                    ,accts_pay_code_combination_id =p_cnv_pre_std_hdr_table(indx).accts_pay_code_combination_id
                    ,prepay_code_combination_id    =p_cnv_pre_std_hdr_table(indx).prepay_code_combination_id
                    ,pay_group_lookup_code         =p_cnv_pre_std_hdr_table(indx).pay_group_lookup_code
                    ,payment_priority              =p_cnv_pre_std_hdr_table(indx).payment_priority
                    ,terms_id                      =p_cnv_pre_std_hdr_table(indx).terms_id
                    ,terms_name                    =p_cnv_pre_std_hdr_table(indx).terms_name
                    ,invoice_amount_limit          =p_cnv_pre_std_hdr_table(indx).invoice_amount_limit
                    ,pay_date_basis_lookup_code    =p_cnv_pre_std_hdr_table(indx).pay_date_basis_lookup_code
                    ,always_take_disc_flag         =p_cnv_pre_std_hdr_table(indx).always_take_disc_flag
                    ,invoice_currency_code         =p_cnv_pre_std_hdr_table(indx).invoice_currency_code
                    ,payment_currency_code         =p_cnv_pre_std_hdr_table(indx).payment_currency_code
                    ,hold_all_payments_flag        =p_cnv_pre_std_hdr_table(indx).hold_all_payments_flag
                    ,hold_future_payments_flag     =p_cnv_pre_std_hdr_table(indx).hold_future_payments_flag
                    ,hold_reason                   =p_cnv_pre_std_hdr_table(indx).hold_reason
                    ,hold_unmatched_invoices_flag  =p_cnv_pre_std_hdr_table(indx).hold_unmatched_invoices_flag
                    ,ap_tax_rounding_rule          =p_cnv_pre_std_hdr_table(indx).ap_tax_rounding_rule
                    ,auto_tax_calc_flag            =p_cnv_pre_std_hdr_table(indx).auto_tax_calc_flag
                    ,auto_tax_calc_override        =p_cnv_pre_std_hdr_table(indx).auto_tax_calc_override
                    ,amount_includes_tax_flag      =p_cnv_pre_std_hdr_table(indx).amount_includes_tax_flag
                    ,exclusive_payment_flag        =p_cnv_pre_std_hdr_table(indx).exclusive_payment_flag
                    ,tax_reporting_site_flag       =p_cnv_pre_std_hdr_table(indx).tax_reporting_site_flag
                    ,attribute_category            =p_cnv_pre_std_hdr_table(indx).attribute_category
                    ,attribute1                    =p_cnv_pre_std_hdr_table(indx).attribute1
                    ,attribute2                    =p_cnv_pre_std_hdr_table(indx).attribute2
                    ,attribute3                    =p_cnv_pre_std_hdr_table(indx).attribute3
                    ,attribute4                    =p_cnv_pre_std_hdr_table(indx).attribute4
                    ,attribute5                    =p_cnv_pre_std_hdr_table(indx).attribute5
                    ,attribute6                    =p_cnv_pre_std_hdr_table(indx).attribute6
                    ,attribute7                    =p_cnv_pre_std_hdr_table(indx).attribute7
                    ,attribute8                    =p_cnv_pre_std_hdr_table(indx).attribute8
                    ,attribute9                    =p_cnv_pre_std_hdr_table(indx).attribute9
                    ,attribute10                   =p_cnv_pre_std_hdr_table(indx).attribute10
                    ,attribute11                   =p_cnv_pre_std_hdr_table(indx).attribute11
                    ,attribute12                   =p_cnv_pre_std_hdr_table(indx).attribute12
                    ,attribute13                   =p_cnv_pre_std_hdr_table(indx).attribute13
                    ,attribute14                   =p_cnv_pre_std_hdr_table(indx).attribute14
                    ,attribute15                   =p_cnv_pre_std_hdr_table(indx).attribute15
                    ,exclude_freight_from_discount =p_cnv_pre_std_hdr_table(indx).exclude_freight_from_discount
                    ,vat_registration_num          =p_cnv_pre_std_hdr_table(indx).vat_registration_num
                    ,org_id                        =p_cnv_pre_std_hdr_table(indx).org_id
                    ,operating_unit_name           =p_cnv_pre_std_hdr_table(indx).operating_unit_name
                    ,address_line4                 =p_cnv_pre_std_hdr_table(indx).address_line4
                    ,county                        =p_cnv_pre_std_hdr_table(indx).county
                    ,address_style                 =p_cnv_pre_std_hdr_table(indx).address_style
                    ,language                      =p_cnv_pre_std_hdr_table(indx).language
                    ,allow_awt_flag                =p_cnv_pre_std_hdr_table(indx).allow_awt_flag
                    ,awt_group_id                  =p_cnv_pre_std_hdr_table(indx).awt_group_id
                    ,awt_group_name                =p_cnv_pre_std_hdr_table(indx).awt_group_name
                    ,global_attribute1             =p_cnv_pre_std_hdr_table(indx).global_attribute1
                    ,global_attribute2             =p_cnv_pre_std_hdr_table(indx).global_attribute2
                    ,global_attribute3             =p_cnv_pre_std_hdr_table(indx).global_attribute3
                    ,global_attribute4             =p_cnv_pre_std_hdr_table(indx).global_attribute4
                    ,global_attribute5             =p_cnv_pre_std_hdr_table(indx).global_attribute5
                    ,global_attribute6             =p_cnv_pre_std_hdr_table(indx).global_attribute6
                    ,global_attribute7             =p_cnv_pre_std_hdr_table(indx).global_attribute7
                    ,global_attribute8             =p_cnv_pre_std_hdr_table(indx).global_attribute8
                    ,global_attribute9             =p_cnv_pre_std_hdr_table(indx).global_attribute9
                    ,global_attribute10            =p_cnv_pre_std_hdr_table(indx).global_attribute10
                    ,global_attribute11            =p_cnv_pre_std_hdr_table(indx).global_attribute11
                    ,global_attribute12            =p_cnv_pre_std_hdr_table(indx).global_attribute12
                    ,global_attribute13            =p_cnv_pre_std_hdr_table(indx).global_attribute13
                    ,global_attribute14            =p_cnv_pre_std_hdr_table(indx).global_attribute14
                    ,global_attribute15            =p_cnv_pre_std_hdr_table(indx).global_attribute15
                    ,global_attribute16            =p_cnv_pre_std_hdr_table(indx).global_attribute16
                    ,global_attribute17            =p_cnv_pre_std_hdr_table(indx).global_attribute17
                    ,global_attribute18            =p_cnv_pre_std_hdr_table(indx).global_attribute18
                    ,global_attribute19            =p_cnv_pre_std_hdr_table(indx).global_attribute19
                    ,global_attribute20            =p_cnv_pre_std_hdr_table(indx).global_attribute20
                    ,global_attribute_category     =p_cnv_pre_std_hdr_table(indx).global_attribute_category
                    ,edi_transaction_handling      =p_cnv_pre_std_hdr_table(indx).edi_transaction_handling
                    ,edi_id_number                 =p_cnv_pre_std_hdr_table(indx).edi_id_number
                    ,edi_payment_method            =p_cnv_pre_std_hdr_table(indx).edi_payment_method
                    ,edi_payment_format            =p_cnv_pre_std_hdr_table(indx).edi_payment_format
                    ,edi_remittance_method         =p_cnv_pre_std_hdr_table(indx).edi_remittance_method
                    ,bank_charge_bearer            =p_cnv_pre_std_hdr_table(indx).bank_charge_bearer
                    ,edi_remittance_instruction    =p_cnv_pre_std_hdr_table(indx).edi_remittance_instruction
                    ,pay_on_code                   =p_cnv_pre_std_hdr_table(indx).pay_on_code
                    ,default_pay_site_id           =p_cnv_pre_std_hdr_table(indx).default_pay_site_id
                    ,pay_on_receipt_summary_code   =p_cnv_pre_std_hdr_table(indx).pay_on_receipt_summary_code
                    ,tp_header_id                  =p_cnv_pre_std_hdr_table(indx).tp_header_id
                    ,ece_tp_location_code          =p_cnv_pre_std_hdr_table(indx).ece_tp_location_code
                    ,pcard_site_flag               =p_cnv_pre_std_hdr_table(indx).pcard_site_flag
                    ,match_option                  =p_cnv_pre_std_hdr_table(indx).match_option
                    ,country_of_origin_code        =p_cnv_pre_std_hdr_table(indx).country_of_origin_code
                    ,future_dated_payment_ccid     =p_cnv_pre_std_hdr_table(indx).future_dated_payment_ccid
                    ,create_debit_memo_flag        =p_cnv_pre_std_hdr_table(indx).create_debit_memo_flag
                    ,offset_tax_flag               =p_cnv_pre_std_hdr_table(indx).offset_tax_flag
                    ,supplier_notif_method         =p_cnv_pre_std_hdr_table(indx).supplier_notif_method
                    ,email_address                 =p_cnv_pre_std_hdr_table(indx).email_address
                    ,remittance_email              =p_cnv_pre_std_hdr_table(indx).remittance_email
                    ,primary_pay_site_flag         =p_cnv_pre_std_hdr_table(indx).primary_pay_site_flag
                    ,shipping_control              =p_cnv_pre_std_hdr_table(indx).shipping_control
                    ,duns_number                   =p_cnv_pre_std_hdr_table(indx).duns_number
                    ,tolerance_id                  =p_cnv_pre_std_hdr_table(indx).tolerance_id
                    ,tolerance_name                =p_cnv_pre_std_hdr_table(indx).tolerance_name
                    ,iby_bank_charge_bearer        =p_cnv_pre_std_hdr_table(indx).iby_bank_charge_bearer
                    ,bank_instruction1_code        =p_cnv_pre_std_hdr_table(indx).bank_instruction1_code
                    ,bank_instruction2_code        =p_cnv_pre_std_hdr_table(indx).bank_instruction2_code
                    ,bank_instruction_details      =p_cnv_pre_std_hdr_table(indx).bank_instruction_details
                    ,payment_reason_code           =p_cnv_pre_std_hdr_table(indx).payment_reason_code
                    ,payment_reason_comments       =p_cnv_pre_std_hdr_table(indx).payment_reason_comments
                    ,delivery_channel_code         =p_cnv_pre_std_hdr_table(indx).delivery_channel_code
                    ,payment_format_code           =p_cnv_pre_std_hdr_table(indx).payment_format_code
                    ,settlement_priority           =p_cnv_pre_std_hdr_table(indx).settlement_priority
                    ,payment_text_message1         =p_cnv_pre_std_hdr_table(indx).payment_text_message1
                    ,payment_text_message2         =p_cnv_pre_std_hdr_table(indx).payment_text_message2
                    ,payment_text_message3         =p_cnv_pre_std_hdr_table(indx).payment_text_message3
                    ,vendor_site_interface_id      =p_cnv_pre_std_hdr_table(indx).vendor_site_interface_id
                    ,payment_method_code           =p_cnv_pre_std_hdr_table(indx).payment_method_code
                    ,retainage_rate                =p_cnv_pre_std_hdr_table(indx).retainage_rate
                    ,gapless_inv_num_flag          =p_cnv_pre_std_hdr_table(indx).gapless_inv_num_flag
                    ,selling_company_identifier    =p_cnv_pre_std_hdr_table(indx).selling_company_identifier
                    ,pay_awt_group_id              =p_cnv_pre_std_hdr_table(indx).pay_awt_group_id
                    ,pay_awt_group_name            =p_cnv_pre_std_hdr_table(indx).pay_awt_group_name
                    ,party_site_id                 =p_cnv_pre_std_hdr_table(indx).party_site_id
                    ,party_site_name               =p_cnv_pre_std_hdr_table(indx).party_site_name
                    ,remit_advice_delivery_method  =p_cnv_pre_std_hdr_table(indx).remit_advice_delivery_method
                    ,remit_advice_fax              =p_cnv_pre_std_hdr_table(indx).remit_advice_fax
                    ,party_orig_system             =p_cnv_pre_std_hdr_table(indx).party_orig_system
                    ,party_orig_system_reference   =p_cnv_pre_std_hdr_table(indx).party_orig_system_reference
                    ,party_site_orig_system        =p_cnv_pre_std_hdr_table(indx).party_site_orig_system
                    ,party_site_orig_sys_reference =p_cnv_pre_std_hdr_table(indx).party_site_orig_sys_reference
                    ,supplier_site_orig_system     =p_cnv_pre_std_hdr_table(indx).supplier_site_orig_system
                    ,sup_site_orig_system_reference=p_cnv_pre_std_hdr_table(indx).sup_site_orig_system_reference
                    ,sdh_batch_id                  =p_cnv_pre_std_hdr_table(indx).sdh_batch_id
                    ,party_id                      =p_cnv_pre_std_hdr_table(indx).party_id
                    ,location_id                   =p_cnv_pre_std_hdr_table(indx).location_id
                    ,cage_code                     =p_cnv_pre_std_hdr_table(indx).cage_code
                    ,legal_business_name           =p_cnv_pre_std_hdr_table(indx).legal_business_name
                    ,doing_bus_as_name             =p_cnv_pre_std_hdr_table(indx).doing_bus_as_name
                    ,division_name                 =p_cnv_pre_std_hdr_table(indx).division_name
                    ,small_business_code           =p_cnv_pre_std_hdr_table(indx).small_business_code
                    ,ccr_comments                  =p_cnv_pre_std_hdr_table(indx).ccr_comments
                    ,debarment_start_date          =p_cnv_pre_std_hdr_table(indx).debarment_start_date
                    ,debarment_end_date            =p_cnv_pre_std_hdr_table(indx).debarment_end_date
                    ,process_code	           =p_cnv_pre_std_hdr_table(indx).process_code
		    ,error_code			   =p_cnv_pre_std_hdr_table(indx).error_code
		    ,request_id			   =p_cnv_pre_std_hdr_table(indx).request_id
                    ,last_updated_by               =x_last_updated_by
                    ,last_update_date              =x_last_update_date
                    ,last_update_login             =x_last_update_login
               WHERE record_number = p_cnv_pre_std_hdr_table(indx).record_number
                 AND batch_id      = p_cnv_pre_std_hdr_table(indx).batch_id;


            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'The vendor is after update '
                                  || p_cnv_pre_std_hdr_table (indx).vendor_id
                                 );
         END LOOP;

         COMMIT;
      END update_pre_interface_records;

        -------------------------------------------------------------------------
        -----------< move_rec_pre_standard_table >-------------------------------
        -------------------------------------------------------------------------
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
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                           'Inserting Records into xx_ap_sup_sites_pre_int'
                          );

         INSERT INTO xx_ap_sup_sites_pre_int
                             (
                         vendor_interface_id
                        ,vendor_id
                        ,vendor_site_code
                        ,vendor_site_code_alt
                        ,purchasing_site_flag
                        ,rfq_only_site_flag
                        ,pay_site_flag
                        ,attention_ar_flag
                        ,address_line1
                        ,address_lines_alt
                        ,address_line2
                        ,address_line3
                        ,address_line4
                        ,city
                        ,state
                        ,zip
                        ,county
                        ,province
                        ,country
                        ,area_code
                        ,phone
                        ,customer_num
                        ,ship_to_location_code
                        ,bill_to_location_code
                        ,ship_via_lookup_code
                        ,freight_terms_lookup_code
                        ,fob_lookup_code
                        ,inactive_date
                        ,fax
                        ,fax_area_code
                        ,telex
                        ,terms_date_basis
                        ,vat_code
                        ,accts_pay_code_comb_value
                        ,prepay_code_comb_value
                        ,pay_group_lookup_code
                        ,payment_priority
                        ,terms_name
                        ,pay_date_basis_lookup_code
                        ,always_take_disc_flag
                        ,invoice_currency_code
                        ,payment_currency_code
                        ,hold_all_payments_flag
                        ,hold_future_payments_flag
                        ,hold_reason
                        ,hold_unmatched_invoices_flag
                        ,auto_tax_calc_flag
                        ,auto_tax_calc_override
                        ,amount_includes_tax_flag
                        ,exclusive_payment_flag
                        ,tax_reporting_site_flag
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
                        ,exclude_freight_from_discount
                        ,vat_registration_num
                        ,operating_unit_name
                        ,address_style
                        ,language
                        ,allow_awt_flag
                        ,awt_group_name
                        ,pcard_site_flag
                        ,match_option
                        ,country_of_origin_code
                        ,create_debit_memo_flag
                        ,offset_tax_flag
                        ,supplier_notif_method
                        ,email_address
                        ,remittance_email
                        ,primary_pay_site_flag
                        ,shipping_control
                        ,duns_number
                        ,iby_bank_charge_bearer
                        ,bank_instruction1_code
                        ,bank_instruction2_code
                        ,bank_instruction_details
                        ,payment_reason_code
                        ,payment_reason_comments
                        ,delivery_channel_code
                        ,payment_format_code
                        ,settlement_priority
                        ,payment_text_message1
                        ,payment_text_message2
                        ,payment_text_message3
                        ,payment_method_code
                        ,retainage_rate
                        ,gapless_inv_num_flag
                        ,selling_company_identifier
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
                     ,vendor_id
                     ,vendor_site_code
                     ,vendor_site_code_alt
                     ,purchasing_site_flag
                     ,rfq_only_site_flag
                     ,pay_site_flag
                     ,attention_ar_flag
                     ,address_line1
                     ,address_lines_alt
                     ,address_line2
                     ,address_line3
                     ,address_line4
                     ,city
                     ,state
                     ,zip
                     ,county
                     ,province
                     ,country
                     ,area_code
                     ,phone
                     ,customer_num
                     ,ship_to_location_code
                     ,bill_to_location_code
                     ,ship_via_lookup_code
                     ,freight_terms_lookup_code
                     ,fob_lookup_code
                     ,inactive_date
                     ,fax
                     ,fax_area_code
                     ,telex
                     ,terms_date_basis
                     ,vat_code
                     ,accts_pay_code_comb_value
                     ,prepay_code_comb_value
                     ,pay_group_lookup_code
                     ,payment_priority
                     ,terms_name
                     ,pay_date_basis_lookup_code
                     ,always_take_disc_flag
                     ,invoice_currency_code
                     ,payment_currency_code
                     ,hold_all_payments_flag
                     ,hold_future_payments_flag
                     ,hold_reason
                     ,hold_unmatched_invoices_flag
                     ,auto_tax_calc_flag
                     ,auto_tax_calc_override
                     ,amount_includes_tax_flag
                     ,exclusive_payment_flag
                     ,tax_reporting_site_flag
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
                     ,exclude_freight_from_discount
                     ,vat_registration_num
                     ,operating_unit_name
                     ,address_style
                     ,language
                     ,allow_awt_flag
                     ,awt_group_name
                     ,pcard_site_flag
                     ,match_option
                     ,country_of_origin_code
                     ,create_debit_memo_flag
                     ,offset_tax_flag
                     ,NVL(supplier_notif_method,'EMAIL')
                     ,email_address
                     ,remittance_email
                     ,primary_pay_site_flag
                     ,shipping_control
                     ,duns_number
                     ,iby_bank_charge_bearer
                     ,bank_instruction1_code
                     ,bank_instruction2_code
                     ,bank_instruction_details
                     ,payment_reason_code
                     ,payment_reason_comments
                     ,delivery_channel_code
                     ,payment_format_code
                     ,settlement_priority
                     ,payment_text_message1
                     ,payment_text_message2
                     ,payment_text_message3
                     ,payment_method_code
                     ,retainage_rate
                     ,gapless_inv_num_flag
                     ,selling_company_identifier
                     ,pay_awt_group_name
                     ,batch_id
                     ,record_number
                     ,G_STAGE
                     ,error_code
                     ,request_id
                     ,x_created_by
                     ,x_creation_date
                     ,x_last_update_date
                     ,x_last_updated_by
                     ,x_last_update_login
                         FROM xx_ap_sup_sites_stg
                              WHERE BATCH_ID     = G_BATCH_ID
                                AND process_code = xx_emf_cn_pkg.CN_PREVAL
                                AND request_id   = xx_emf_pkg.G_REQUEST_ID
                           AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

         COMMIT;

         IF SQL%ROWCOUNT > 0
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'No Of Records Inserted : ' || SQL%ROWCOUNT
                              );
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                'Error While Inserting Records into xx_ap_sup_sites_pre_int ..'
               );
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand
                             );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            RETURN x_error_code;
      END move_rec_pre_standard_table;

        -------------------------------------------------------------------------
        -----------< process_data >----------------------------------------------
        -------------------------------------------------------------------------
      FUNCTION process_data
         RETURN NUMBER
      IS
         x_return_status   VARCHAR2 (15) := xx_emf_cn_pkg.cn_success;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         -- Change the logic to whatever needs to be done
         -- with valid records in the pre-interface tables
         -- either call the appropriate API to process the data
         -- or to insert into an interface table
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Inserting Records into ap_supplier_sites_int'
                           );

         INSERT INTO ap_supplier_sites_int
                             (
                        vendor_interface_id
                       ,vendor_id
                       ,vendor_site_code
                       ,vendor_site_code_alt
                       ,purchasing_site_flag
                       ,rfq_only_site_flag
                       ,pay_site_flag
                       ,attention_ar_flag
                       ,address_line1
                       ,address_lines_alt
                       ,address_line2
                       ,address_line3
                       ,city
                       ,state
                       ,zip
                       ,province
                       ,country
                       ,area_code
                       ,phone
                       ,customer_num
                       ,ship_to_location_id
                       ,ship_to_location_code
                       ,bill_to_location_id
                       ,bill_to_location_code
                       ,ship_via_lookup_code
                       ,freight_terms_lookup_code
                       ,fob_lookup_code
                       ,inactive_date
                       ,fax
                       ,fax_area_code
                       ,telex
                       ,payment_method_lookup_code
                       ,terms_date_basis
                       ,vat_code
                       ,distribution_set_id
                       ,distribution_set_name
                       ,accts_pay_code_combination_id
                       ,prepay_code_combination_id
                       ,pay_group_lookup_code
                       ,payment_priority
                       ,terms_id
                       ,terms_name
                       ,invoice_amount_limit
                       ,pay_date_basis_lookup_code
                       ,always_take_disc_flag
                       ,invoice_currency_code
                       ,payment_currency_code
                       ,hold_all_payments_flag
                       ,hold_future_payments_flag
                       ,hold_reason
                       ,hold_unmatched_invoices_flag
                       ,ap_tax_rounding_rule
                       ,auto_tax_calc_flag
                       ,auto_tax_calc_override
                       ,amount_includes_tax_flag
                       ,exclusive_payment_flag
                       ,tax_reporting_site_flag
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
                       ,program_application_id
                       ,program_id
                       ,program_update_date
                       ,exclude_freight_from_discount
                       ,vat_registration_num
                       ,org_id
                       ,operating_unit_name
                       ,address_line4
                       ,county
                       ,address_style
                       ,language
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
                       ,edi_id_number
                       ,edi_payment_method
                       ,edi_payment_format
                       ,edi_remittance_method
                       ,bank_charge_bearer
                       ,edi_remittance_instruction
                       ,pay_on_code
                       ,default_pay_site_id
                       ,pay_on_receipt_summary_code
                       ,tp_header_id
                       ,ece_tp_location_code
                       ,pcard_site_flag
                       ,match_option
                       ,country_of_origin_code
                       ,future_dated_payment_ccid
                       ,create_debit_memo_flag
                       ,offset_tax_flag
                       ,supplier_notif_method
                       ,email_address
                       ,remittance_email
                       ,primary_pay_site_flag
                       ,shipping_control
                       ,duns_number
                       ,tolerance_id
                       ,tolerance_name
                       ,iby_bank_charge_bearer
                       ,bank_instruction1_code
                       ,bank_instruction2_code
                       ,bank_instruction_details
                       ,payment_reason_code
                       ,payment_reason_comments
                       ,delivery_channel_code
                       ,payment_format_code
                       ,settlement_priority
                       ,payment_text_message1
                       ,payment_text_message2
                       ,payment_text_message3
                       ,vendor_site_interface_id
                       ,payment_method_code
                       ,retainage_rate
                       ,gapless_inv_num_flag
                       ,selling_company_identifier
                       ,pay_awt_group_id
                       ,pay_awt_group_name
                       ,party_site_id
                       ,party_site_name
                       ,remit_advice_delivery_method
                       ,remit_advice_fax
                       ,party_orig_system
                       ,party_orig_system_reference
                       ,party_site_orig_system
                       ,party_site_orig_sys_reference
                       ,supplier_site_orig_system
                       ,sup_site_orig_system_reference
                       ,sdh_batch_id
                       ,party_id
                       ,location_id
                       ,cage_code
                       ,legal_business_name
                       ,doing_bus_as_name
                       ,division_name
                       ,small_business_code
                       ,ccr_comments
                       ,debarment_start_date
                       ,debarment_end_date
                       ,status
                       ,created_by
                       ,creation_date
                       ,last_updated_by
                       ,last_update_date
                       ,last_update_login
                             )
                 SELECT
                      vendor_interface_id
                     ,vendor_id
                     ,vendor_site_code
                     ,vendor_site_code_alt
                     ,purchasing_site_flag
                     ,rfq_only_site_flag
                     ,pay_site_flag
                     ,attention_ar_flag
                     ,address_line1
                     ,address_lines_alt
                     ,address_line2
                     ,address_line3
                     ,city
                     ,state
                     ,zip
                     ,province
                     ,country
                     ,area_code
                     ,phone
                     ,customer_num
                     ,ship_to_location_id
                     ,ship_to_location_code
                     ,bill_to_location_id
                     ,bill_to_location_code
                     ,ship_via_lookup_code
                     ,freight_terms_lookup_code
                     ,fob_lookup_code
                     ,inactive_date
                     ,fax
                     ,fax_area_code
                     ,telex
                     ,payment_method_lookup_code
                     ,terms_date_basis
                     ,vat_code
                     ,distribution_set_id
                     ,distribution_set_name
                     ,accts_pay_code_combination_id
                     ,prepay_code_combination_id
                     ,pay_group_lookup_code
                     ,payment_priority
                     ,terms_id
                     ,terms_name
                     ,invoice_amount_limit
                     ,pay_date_basis_lookup_code
                     ,always_take_disc_flag
                     ,invoice_currency_code
                     ,payment_currency_code
                     ,hold_all_payments_flag
                     ,hold_future_payments_flag
                     ,hold_reason
                     ,hold_unmatched_invoices_flag
                     ,ap_tax_rounding_rule
                     ,auto_tax_calc_flag
                     ,auto_tax_calc_override
                     ,amount_includes_tax_flag
                     ,exclusive_payment_flag
                     ,tax_reporting_site_flag
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
                     ,program_application_id
                     ,program_id
                     ,program_update_date
                     ,exclude_freight_from_discount
                     ,vat_registration_num
                     ,org_id
                     ,operating_unit_name
                     ,address_line4
                     ,county
                     ,address_style
                     ,language
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
                     ,edi_id_number
                     ,edi_payment_method
                     ,edi_payment_format
                     ,edi_remittance_method
                     ,bank_charge_bearer
                     ,edi_remittance_instruction
                     ,pay_on_code
                     ,default_pay_site_id
                     ,pay_on_receipt_summary_code
                     ,tp_header_id
                     ,ece_tp_location_code
                     ,pcard_site_flag
                     ,match_option
                     ,country_of_origin_code
                     ,future_dated_payment_ccid
                     ,create_debit_memo_flag
                     ,offset_tax_flag
                     ,supplier_notif_method
                     ,email_address
                     ,remittance_email
                     ,primary_pay_site_flag
                     ,shipping_control
                     ,duns_number
                     ,tolerance_id
                     ,tolerance_name
                     ,iby_bank_charge_bearer
                     ,bank_instruction1_code
                     ,bank_instruction2_code
                     ,bank_instruction_details
                     ,payment_reason_code
                     ,payment_reason_comments
                     ,delivery_channel_code
                     ,payment_format_code
                     ,settlement_priority
                     ,payment_text_message1
                     ,payment_text_message2
                     ,payment_text_message3
                     ,ap_supplier_sites_int_s.NEXTVAL  --,vendor_site_interface_id
                     ,payment_method_code
                     ,retainage_rate
                     ,gapless_inv_num_flag
                     ,selling_company_identifier
                     ,pay_awt_group_id
                     ,pay_awt_group_name
                     ,party_site_id
                     ,party_site_name
                     ,remit_advice_delivery_method
                     ,remit_advice_fax
                     ,party_orig_system
                     ,party_orig_system_reference
                     ,party_site_orig_system
                     ,party_site_orig_sys_reference
                     ,supplier_site_orig_system
                     ,sup_site_orig_system_reference
                     ,sdh_batch_id
                     ,party_id
                     ,location_id
                     ,cage_code
                     ,legal_business_name
                     ,doing_bus_as_name
                     ,division_name
                     ,small_business_code
                     ,ccr_comments
                     ,debarment_start_date
                     ,debarment_end_date
                     ,'NEW'
                     ,created_by
                     ,creation_date
                     ,last_updated_by
                     ,last_update_date
                     ,last_update_login
                  FROM xx_ap_sup_sites_pre_int
                              WHERE batch_id = G_BATCH_ID
                                AND request_id = xx_emf_pkg.G_REQUEST_ID
                                AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                           AND process_code = xx_emf_cn_pkg.CN_POSTVAL;

         COMMIT;
         RETURN x_return_status;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                                 'Error while inserting into Inerface Table: '
                              || SQLERRM
                             );
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand
                             );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            RETURN x_error_code;
      END process_data;

	-------------------------------------------------------------------------
	-----------< update_record_count >--------------------------------------
	-------------------------------------------------------------------------
      PROCEDURE update_record_count
      IS
         CURSOR c_get_total_cnt
         IS
            SELECT SUM (total_count)
              FROM (SELECT COUNT (1) total_count
                      FROM xx_ap_sup_sites_stg
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                    UNION
                    SELECT COUNT (1) total_count
                      FROM xx_ap_sup_sites_pre_int
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id);

         x_total_cnt     NUMBER;

         CURSOR c_get_error_cnt
         IS
            SELECT SUM (error_count)
              FROM (SELECT COUNT (1) error_count
                      FROM xx_ap_sup_sites_stg
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err
                    UNION ALL
                    SELECT COUNT (1) error_count
                      FROM xx_ap_sup_sites_pre_int
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err);

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_ap_sup_sites_pre_int
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

         x_warn_cnt      NUMBER;

         CURSOR c_get_success_cnt
         IS
            SELECT COUNT (1) success_count
              FROM xx_ap_sup_sites_pre_int
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
   BEGIN
      retcode := xx_emf_cn_pkg.cn_success;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Before Setting Environment'
                           );
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
         x_error_code := xx_ap_sus_cnv_validations_pkg.pre_validations ();
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
      -- Start with pre-validations
      -- Set the stage to Batch Validations
      set_stage (xx_emf_cn_pkg.cn_batchval);
      -- batch_validations
      x_error_code :=
                  xx_ap_sus_cnv_validations_pkg.batch_validations (p_batch_id);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'After batch_validations X_ERROR_CODE '
                            || x_error_code
                           );
      xx_emf_pkg.propagate_error (x_error_code);
      -- Once pre-validations are complete the loop through the pre-interface records
      -- and perform data validations on this table
      -- Set the stage to data Validations
      set_stage (xx_emf_cn_pkg.cn_valid);

      OPEN c_xx_ap_sup_sites_pre_int (xx_emf_cn_pkg.cn_preval);

      LOOP
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'In the pre interface records loop'
                              );

         FETCH c_xx_ap_sup_sites_pre_int
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               -- Perform Data Validations
               x_error_code :=
                  xx_ap_sus_cnv_validations_pkg.data_validations
                                                      (x_pre_std_hdr_table (i)
                                                      ,p_validate_and_load          --Added as per Wave1
                                                      );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'After Data Validations ... x_error_code : '
                               || x_error_code
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
         EXIT WHEN c_xx_ap_sup_sites_pre_int%NOTFOUND;
      END LOOP;

      IF c_xx_ap_sup_sites_pre_int%ISOPEN
      THEN
         CLOSE c_xx_ap_sup_sites_pre_int;
      END IF;

      -- Once data-validations are complete the loop through the pre-interface records
      -- and perform data derivations on this table
      -- Set the stage to data derivations
      set_stage (xx_emf_cn_pkg.cn_derive);

      OPEN c_xx_ap_sup_sites_pre_int (xx_emf_cn_pkg.cn_valid);

      LOOP
         FETCH c_xx_ap_sup_sites_pre_int
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               -- Perform Data derivations
               x_error_code :=
                  xx_ap_sus_cnv_validations_pkg.data_derivations
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
         EXIT WHEN c_xx_ap_sup_sites_pre_int%NOTFOUND;
      END LOOP;

      IF c_xx_ap_sup_sites_pre_int%ISOPEN
      THEN
         CLOSE c_xx_ap_sup_sites_pre_int;
      END IF;

      -- Set the stage to Post Validations
      set_stage (xx_emf_cn_pkg.cn_postval);
      -- Post Validations
      x_error_code := xx_ap_sus_cnv_validations_pkg.post_validations ();
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
         x_error_code := process_data;
         mark_records_complete (xx_emf_cn_pkg.cn_process_data);
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;                                 --End If for p_validate_and_load

      update_record_count;
      --xx_emf_pkg.create_report;  Modified as per Wave1 to display distinct errors
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
END xx_ap_sus_conversion_pkg;
/


GRANT EXECUTE ON APPS.XX_AP_SUS_CONVERSION_PKG TO INTG_XX_NONHR_RO;
