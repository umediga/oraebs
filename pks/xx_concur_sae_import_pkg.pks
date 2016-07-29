DROP PACKAGE APPS.XX_CONCUR_SAE_IMPORT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_CONCUR_SAE_IMPORT_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : Jaya Maran Jayaraj
 Creation Date : 17-JAN-2014
 File Name     : xx_concur_sae_import_pkg.pks
 Description   : This script creates the specification of the package
                 xx_concur_sae_import_pkg
 Change History:
 Date        Name                     Remarks
 ----------- -------------------      -----------------------------------
 17-Jan-2014 Jaya Maran Jayaraj       Initial Version
 15-Apr-2014 Jaya Maran Jayaraj       Modified for Ticket 5204
 23-Apr-2014 Jaya Maran Jayaraj       Modified for Ticket 5621
*/
-------------------------------------------------------------------------
   TYPE g_xx_concur_sae_rec_type IS RECORD (
      batch_constant               VARCHAR2 (6),
      batch_id                     VARCHAR2 (13),
      batch_date                   VARCHAR2 (10),
      batch_seq_number             NUMBER,
      emp_employee_id              VARCHAR2 (48),
      emp_last_name                VARCHAR2 (32),
      emp_first_name               VARCHAR2 (32),
      emp_mi                       VARCHAR2 (1),
      emp_group_id                 VARCHAR2 (48),
      emp_org_unit1                VARCHAR2 (48),
      emp_org_unit2                VARCHAR2 (48),
      emp_org_unit3                VARCHAR2 (48),
      emp_org_unit4                VARCHAR2 (48),
      emp_org_unit5                VARCHAR2 (48),
      emp_org_unit6                VARCHAR2 (48),
      emp_ach_account_number       NUMBER,
      emp_ach_routing_number       VARCHAR2 (48),
      emp_adjusted_reclaim_tax     VARCHAR2 (23),
      rpt_report_id                VARCHAR2 (32),
      rpt_report_key               VARCHAR2 (48),
      rpt_ledger                   VARCHAR2 (20),
      rpt_reim_currency            VARCHAR2 (3),
      rpt_home_country             VARCHAR2 (64),
      rpt_submit_date              VARCHAR2 (10),
      rpt_user_defined_date        VARCHAR2 (10),
      rpt_pay_process_date         VARCHAR2 (10),
      rpt_report_name              VARCHAR2 (40),
      rpt_image_required           VARCHAR2 (1),
      rpt_vat_entry                VARCHAR2 (1),
      rpt_ta_entry                 VARCHAR2 (1),
      rpt_total_post_amount        VARCHAR2 (23),
      rpt_total_approved_amount    VARCHAR2 (23),
      rpt_policy_name              VARCHAR2 (64),
      rpt_budget_accrual_date      VARCHAR2 (10),
      rpt_org_unit1                VARCHAR2 (48),
      rpt_org_unit2                VARCHAR2 (48),
      rpt_org_unit3                VARCHAR2 (48),
      rpt_org_unit4                VARCHAR2 (48),
      rpt_org_unit5                VARCHAR2 (48),
      rpt_org_unit6                VARCHAR2 (48),
      rpt_custom1                  VARCHAR2 (48),
      rpt_custom2                  VARCHAR2 (48),
      rpt_custom3                  VARCHAR2 (48),
      rpt_custom4                  VARCHAR2 (48),
      rpt_custom5                  VARCHAR2 (48),
      rpt_custom6                  VARCHAR2 (48),
      rpt_custom7                  VARCHAR2 (48),
      rpt_custom8                  VARCHAR2 (48),
      rpt_custom9                  VARCHAR2 (48),
      rpt_custom10                 VARCHAR2 (48),
      rpt_custom11                 VARCHAR2 (48),
      rpt_custom12                 VARCHAR2 (48),
      rpt_custom13                 VARCHAR2 (48),
      rpt_custom14                 VARCHAR2 (48),
      rpt_custom15                 VARCHAR2 (48),
      rpt_custom16                 VARCHAR2 (48),
      rpt_custom17                 VARCHAR2 (48),
      rpt_custom18                 VARCHAR2 (48),
      rpt_custom19                 VARCHAR2 (48),
      rpt_custom20                 VARCHAR2 (48),
      rpte_entry_id                VARCHAR2 (13),
      rpte_transaction_type        VARCHAR2 (3),
      rpte_expense_type            VARCHAR2 (64),
      rpte_transaction_date        VARCHAR2 (10),
      rpte_currency_code           VARCHAR2 (3),
      rpte_exchange_rate           VARCHAR2 (23),
      rpte_exchange_rate_dir       VARCHAR2 (1),
      rpte_personal_flag           VARCHAR2 (1),
      rpte_description             VARCHAR2 (64),
      rpte_vendor_name             VARCHAR2 (64),
      rpte_vendor_desc             VARCHAR2 (64),
      rpte_receipt_received_flag   VARCHAR2 (1),
      rpte_receipt_type            VARCHAR2 (1),
      rpte_employee_attendee       VARCHAR2 (23),
      rpte_spouse_attendee         VARCHAR2 (23),
      rpte_business_attendee       VARCHAR2 (23),
      rpte_org_unit1               VARCHAR2 (48),
      rpte_org_unit2               VARCHAR2 (48),
      rpte_org_unit3               VARCHAR2 (48),
      rpte_org_unit4               VARCHAR2 (48),
      rpte_org_unit5               VARCHAR2 (48),
      rpte_org_unit6               VARCHAR2 (48),
      rpte_custom1                 VARCHAR2 (48),
      rpte_custom2                 VARCHAR2 (48),
      rpte_custom3                 VARCHAR2 (48),
      rpte_custom4                 VARCHAR2 (48),
      rpte_custom5                 VARCHAR2 (48),
      rpte_custom6                 VARCHAR2 (48),
      rpte_custom7                 VARCHAR2 (48),
      rpte_custom8                 VARCHAR2 (48),
      rpte_custom9                 VARCHAR2 (48),
      rpte_custom10                VARCHAR2 (48),
      rpte_custom11                VARCHAR2 (48),
      rpte_custom12                VARCHAR2 (48),
      rpte_custom13                VARCHAR2 (48),
      rpte_custom14                VARCHAR2 (48),
      rpte_custom15                VARCHAR2 (48),
      rpte_custom16                VARCHAR2 (48),
      rpte_custom17                VARCHAR2 (48),
      rpte_custom18                VARCHAR2 (48),
      rpte_custom19                VARCHAR2 (48),
      rpte_custom20                VARCHAR2 (48),
      rpte_custom21                VARCHAR2 (48),
      rpte_custom22                VARCHAR2 (48),
      rpte_custom23                VARCHAR2 (48),
      rpte_custom24                VARCHAR2 (48),
      rpte_custom25                VARCHAR2 (48),
      rpte_custom26                VARCHAR2 (48),
      rpte_custom27                VARCHAR2 (48),
      rpte_custom28                VARCHAR2 (48),
      rpte_custom29                VARCHAR2 (48),
      rpte_custom30                VARCHAR2 (48),
      rpte_custom31                VARCHAR2 (48),
      rpte_custom32                VARCHAR2 (48),
      rpte_custom33                VARCHAR2 (48),
      rpte_custom34                VARCHAR2 (48),
      rpte_custom35                VARCHAR2 (48),
      rpte_custom36                VARCHAR2 (48),
      rpte_custom37                VARCHAR2 (48),
      rpte_custom38                VARCHAR2 (48),
      rpte_custom39                VARCHAR2 (48),
      rpte_custom40                VARCHAR2 (48),
      rpte_transaction_amount      VARCHAR2 (23),
      rpte_posted_amount           VARCHAR2 (23),
      rpte_approved_amount         VARCHAR2 (23),
      rpte_payment_type_code       VARCHAR2 (4),
      rpte_payment_code            VARCHAR2 (80),
      rpte_payment_reim_type       VARCHAR2 (1),
      rpte_bill_date               VARCHAR2 (10),
      cc_card_column1              VARCHAR2 (255 BYTE),
      cc_card_column2              VARCHAR2 (255 BYTE),
      cc_card_column3              VARCHAR2 (13 BYTE),
      cc_card_column4              VARCHAR2 (64 BYTE),
      cc_card_column5              VARCHAR2 (13 BYTE),
      cc_card_column6              VARCHAR2 (3 BYTE),
      cc_card_column7              VARCHAR2 (32 BYTE),
      cc_card_column8              VARCHAR2 (23 BYTE),
      cc_card_column9              VARCHAR2 (23 BYTE),
      cc_card_column10             VARCHAR2 (3 BYTE),
      cc_card_column11             VARCHAR2 (23 BYTE),
      cc_card_column12             VARCHAR2 (3 BYTE),
      cc_card_column13             VARCHAR2 (10 BYTE),
      cc_card_column14             VARCHAR2 (10 BYTE),
      cc_card_column15             VARCHAR2 (42 BYTE),
      cc_card_column16             VARCHAR2 (5 BYTE),
      cc_card_column17             VARCHAR2 (50 BYTE),
      cc_card_column18             VARCHAR2 (40 BYTE),
      cc_card_column19             VARCHAR2 (32 BYTE),
      cc_card_column20             VARCHAR2 (2 BYTE),
      cc_card_column21             VARCHAR2 (15 BYTE),
      cc_card_column22             VARCHAR2 (2 BYTE),
      cc_card_column23             VARCHAR2 (23 BYTE),
      cc_card_column24             VARCHAR2 (23 BYTE),
      cc_card_column25             VARCHAR2 (255 BYTE),
      cc_card_column26             VARCHAR2 (255 BYTE),
      cc_card_column27             VARCHAR2 (64 BYTE),
      cc_card_column28             VARCHAR2 (50 BYTE),
      eld_loc_country_code         VARCHAR2 (2),
      eld_loc_country_subcode      VARCHAR2 (6),
      eld_domestic_foreign_flag    VARCHAR2 (4),
      eld_market_code              VARCHAR2 (255),
      eld_processor_ref_number     VARCHAR2 (64),
      jed_payer_type_name          VARCHAR2 (64),
      jed_payer_code_name          VARCHAR2 (80),
      jed_payee_type_name          VARCHAR2 (64),
      jed_payee_code_name          VARCHAR2 (80),
      jed_account_code             VARCHAR2 (48),
      jed_debit_credit             VARCHAR2 (2),
      jed_journal_amount           VARCHAR2 (23),
      jed_journal_key              VARCHAR2 (48),
      cmd_column1                  VARCHAR2 (13 BYTE),
      cmd_column2                  VARCHAR2 (13 BYTE),
      cmd_column3                  VARCHAR2 (13 BYTE),
      cmd_column4                  VARCHAR2 (30 BYTE),
      cmd_column5                  VARCHAR2 (23 BYTE),
      cmd_column6                  VARCHAR2 (64 BYTE),
      cad_column1                  VARCHAR2 (23 BYTE),
      cad_column2                  VARCHAR2 (3 BYTE),
      cad_column3                  VARCHAR2 (3 BYTE),
      cad_column4                  VARCHAR2 (23 BYTE),
      cad_column5                  VARCHAR2 (3 BYTE),
      cad_column6                  VARCHAR2 (3 BYTE),
      cad_column7                  VARCHAR2 (10 BYTE),
      cad_column8                  VARCHAR2 (80 BYTE),
      cad_column9                  VARCHAR2 (1 BYTE),
      cad_column10                 VARCHAR2 (10 BYTE),
      cad_column11                 VARCHAR2 (13 BYTE),
      cad_column12                 VARCHAR2 (1 BYTE),
      ad_allocation_key            VARCHAR2 (13),
      ad_allocation_per            VARCHAR2 (11),
      ad_custom1                   VARCHAR2 (48),
      ad_custom2                   VARCHAR2 (48),
      ad_custom3                   VARCHAR2 (48),
      ad_custom4                   VARCHAR2 (48),
      ad_custom5                   VARCHAR2 (48),
      ad_custom6                   VARCHAR2 (48),
      ad_custom7                   VARCHAR2 (48),
      ad_custom8                   VARCHAR2 (48),
      ad_custom9                   VARCHAR2 (48),
      ad_custom10                  VARCHAR2 (48),
      ad_custom11                  VARCHAR2 (48),
      ad_custom12                  VARCHAR2 (48),
      ad_custom13                  VARCHAR2 (48),
      ad_custom14                  VARCHAR2 (48),
      ad_custom15                  VARCHAR2 (48),
      ad_custom16                  VARCHAR2 (48),
      ad_custom17                  VARCHAR2 (48),
      ad_custom18                  VARCHAR2 (48),
      ad_custom19                  VARCHAR2 (48),
      ad_custom20                  VARCHAR2 (48),
      ad_net_adjusted_tax          VARCHAR2 (23),
      tad_column1                  VARCHAR2 (1 BYTE),
      tad_column2                  VARCHAR2 (23 BYTE),
      tad_column3                  VARCHAR2 (23 BYTE),
      tad_column4                  VARCHAR2 (23 BYTE),
      tad_column5                  VARCHAR2 (1 BYTE),
      tad_column6                  VARCHAR2 (23 BYTE),
      tad_column7                  VARCHAR2 (23 BYTE),
      tad_column8                  VARCHAR2 (1 BYTE),
      tad_column9                  VARCHAR2 (3 BYTE),
      tad_column10                 VARCHAR2 (3 BYTE),
      tad_column11                 VARCHAR2 (3 BYTE),
      tad_column12                 VARCHAR2 (23 BYTE),
      tad_column13                 VARCHAR2 (23 BYTE),
      vtd_column1                  VARCHAR2 (50 BYTE),
      vtd_column2                  VARCHAR2 (5 BYTE),
      vtd_column3                  VARCHAR2 (23 BYTE),
      vtd_column4                  VARCHAR2 (23 BYTE),
      vtd_column5                  VARCHAR2 (4 BYTE),
      vtd_column6                  VARCHAR2 (23 BYTE),
      vtd_column7                  VARCHAR2 (23 BYTE),
      vtd_column8                  VARCHAR2 (20 BYTE),
      vtd_column9                  VARCHAR2 (1 BYTE),
      vtd_column10                 VARCHAR2 (23 BYTE),
      vtd_column11                 VARCHAR2 (23 BYTE),
      vtd_column12                 VARCHAR2 (20 BYTE),
      vtd_column13                 VARCHAR2 (23 BYTE),
      vtd_column14                 VARCHAR2 (20 BYTE),
      atrd_column1                 VARCHAR2 (20 BYTE),
      atrd_column2                 VARCHAR2 (40 BYTE),
      atrd_column3                 VARCHAR2 (23 BYTE),
      atrd_column4                 VARCHAR2 (23 BYTE),
      atrd_column5                 VARCHAR2 (10 BYTE),
      atrd_column6                 VARCHAR2 (10 BYTE),
      atrd_column7                 VARCHAR2 (10 BYTE),
      vtd_total_tax_posted         VARCHAR2 (23),
      vtd_net_tax_amount           VARCHAR2 (23),
      vtd_total_reclaim_adjusted   VARCHAR2 (23),
      vtd_net_reclaim_adjusted     VARCHAR2 (23),
      rpte_payment_type_name       VARCHAR2 (64),
      cbs_card_program_type_code   VARCHAR2 (5 BYTE),
      cbs_smt_period_start_date    VARCHAR2 (10 BYTE),
      cbs_smt_period_end_date      VARCHAR2 (10 BYTE),
      epd_cash_account_code        VARCHAR2 (48 BYTE),
      epd_liability_account_code   VARCHAR2 (48 BYTE),
      epd_estd_pay_date            VARCHAR2 (10 BYTE)
   );

   TYPE g_xx_concur_sae_tab_type IS TABLE OF g_xx_concur_sae_rec_type
      INDEX BY BINARY_INTEGER;

   g_ret_code         VARCHAR2 (1);
   g_file_name        VARCHAR2 (100);
   g_errbuf           VARCHAR2 (1000);
   g_batch_id         NUMBER;
   g_ledger_id        NUMBER;
   g_je_source_name   VARCHAR2 (100);
   g_journal_name     VARCHAR2 (100); -- Added for ticket # 5204
   g_con_req_id       NUMBER;
   g_data_dir         VARCHAR2 (240);
   g_arch_dir         VARCHAR2 (240);
   g_arch_flag        VARCHAR2 (1)    := 'N';
   g_send_email       VARCHAR2 (1)    := 'N';
   g_send_email_b     VARCHAR2 (1)    := 'N';
   g_send_email_pc       VARCHAR2 (1)    := 'N';
   g_send_email_b_pc     VARCHAR2 (1)    := 'N';
   g_batch_total      NUMBER;
   g_string           VARCHAR2 (240);
   g_notavbl_flag     VARCHAR2 (1)    := 'N';
   g_con_req_id_pc       NUMBER;
   g_stg_total        NUMBER;
   g_int_total_d      NUMBER;
   g_int_total_c      NUMBER;
   g_int_total_dr     NUMBER;
   g_int_total_cr     NUMBER;



   PROCEDURE main (
      errbuf        OUT      VARCHAR2,
      retcode       OUT      VARCHAR2,
      p_file_name   IN       VARCHAR2
   );

   PROCEDURE load_layout_table;

   PROCEDURE load_staging_table;

   PROCEDURE load_interface_table;

   PROCEDURE generate_credit_lines;

   PROCEDURE call_import_program;
   
   PROCEDURE call_import_program_pc;

   PROCEDURE update_staging_table;

   PROCEDURE archive_file;

   PROCEDURE send_email;
   
   PROCEDURE send_email_pc;

   FUNCTION next_field (
      p_line_buffer     IN       VARCHAR2,
      p_delimiter       IN       VARCHAR2,
      x_last_position   IN OUT   NUMBER
   )
      RETURN VARCHAR2;
END xx_concur_sae_import_pkg; 
/
