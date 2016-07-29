DROP PACKAGE BODY APPS.XX_CONCUR_SAE_IMPORT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_CONCUR_SAE_IMPORT_PKG"
IS
----------------------------------------------------------------------
/*
 Created By    : Jaya Maran Jayaraj
 Creation Date : 17-JAN-2014
 File Name     : xx_concur_sae_import_pkg.pkb
 Description   : This script creates the body of the package
                 APPS.xx_concur_sae_import_pkg
 Change History:
 Date        Name                     Remarks
 ----------- -------------------      -----------------------------------
 17-Jan-2014 Jaya Maran Jayaraj       Initial Version
 15-Apr-2014 Jaya Maran Jayaraj       Modified for Ticket 5204
 23-Apr-2014 Jaya Maran Jayaraj       Modified for Ticket 5621
 07-Jan-2015 Jaya Maran Jayaraj       Modified for PCard Implementation
 11-Aug-2015 Prasanna (NTT DATA)      Modified for Credit Card transactions - Case 00004426
 20-Nov-2015 Prasanna (NTT DATA)      Modified for P-Card Oracle Interface - Case 00005831
*/
-------------------------------------------------------------------------
   PROCEDURE main (
      errbuf        OUT      VARCHAR2,
      retcode       OUT      VARCHAR2,
      p_file_name   IN       VARCHAR2
   )
   IS
      x_error_code   NUMBER;
   BEGIN
      /* Custom Initialization*/
      g_ret_code := xx_emf_cn_pkg.cn_success;
      x_error_code := xx_emf_pkg.set_env;
      g_file_name := p_file_name;
      fnd_file.put_line
         (fnd_file.output,
          '                   Concur SAE Import Interface                               '
         );
      fnd_file.put_line (fnd_file.output,
                            'Request id                    :'
                         || fnd_global.conc_request_id
                        );
      fnd_file.put_line
         (fnd_file.output,
          '-----------------------------------------------------------------------------'
         );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            '------------------------------'
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Starting to Process Data File.' || g_file_name
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Calling Load_Layout_Table Procedure.'
                           );
      load_layout_table;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            '------------------------------'
                           );

      IF g_ret_code = xx_emf_cn_pkg.cn_success
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Calling Load_Staging_Table Procedure.'
                              );
         load_staging_table;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Concur Batch Id:' || g_batch_id
                              );
      ELSIF g_ret_code = xx_emf_cn_pkg.cn_prc_err
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Error in Load_Layout_Table Procedure.'
                              );
         g_send_email := 'I';
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, g_errbuf);
      END IF;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            '------------------------------'
                           );

      IF g_ret_code = xx_emf_cn_pkg.cn_success
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Calling Load_Interface_Table Procedure.'
                              );
         load_interface_table;
      ELSIF g_ret_code = xx_emf_cn_pkg.cn_prc_err
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Error in Load_Staging_Table Procedure.'
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, g_errbuf);
         g_send_email := 'I';
      END IF;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            '------------------------------'
                           );

      IF g_ret_code = xx_emf_cn_pkg.cn_success
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Calling  generate_credit_lines Procedure.'
                              );
         generate_credit_lines;
      ELSIF g_ret_code = xx_emf_cn_pkg.cn_prc_err
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Error in  generate_credit_lines Procedure.'
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, g_errbuf);
         g_send_email := 'I';
      END IF;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            '------------------------------'
                           );

      IF g_ret_code = xx_emf_cn_pkg.cn_success
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Calling Call_Import_Program Procedure.'
                              );
         call_import_program;
      ELSIF g_ret_code = xx_emf_cn_pkg.cn_prc_err
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Error in Load_Interface_Table Procedure.'
                              );
         g_send_email := 'I';
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, g_errbuf);
      END IF;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            '------------------------------'
                           );

-- Un Comment this while implementing P-Card
     /* IF g_ret_code = xx_emf_cn_pkg.cn_success
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Calling Call_Import_Program_pc Procedure.'
                              );
         call_import_program_pc;
      ELSIF g_ret_code = xx_emf_cn_pkg.cn_prc_err
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Error in Call_Import_Program_pc Procedure.'
                              );
         g_send_email_pc := 'I';
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, g_errbuf);
      END IF;*/

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            '------------------------------'
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Calling update_staging_table Procedure.'
                           );
      update_staging_table;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            '------------------------------'
                           );

      IF g_arch_flag = 'Y'
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Calling archive_file Procedure.'
                              );
         archive_file;
      ELSE
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'File Not archived');
      END IF;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Execution Completed.');
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Concurrent Program Status:' || g_ret_code
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Concurrent Program Error:'
                            || NVL (g_errbuf, 'No Errors')
                           );
      send_email;
      send_email_pc;
      retcode := g_ret_code;
      errbuf := g_errbuf;
   EXCEPTION
      WHEN OTHERS
      THEN
         g_ret_code := xx_emf_cn_pkg.cn_prc_err;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'When Others Exception in main Procedure.'
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, SQLERRM);
         retcode := g_ret_code;
         errbuf := SQLERRM;
   END main;

   PROCEDURE load_layout_table
   IS
      v_file_type         UTL_FILE.file_type;
      v_line              VARCHAR2 (3000);
      v_data_rec          g_xx_concur_sae_tab_type;
      v_count             NUMBER                   := 0;
      v_pos               NUMBER                   := 1;
      v_delimeter         VARCHAR2 (10)            := '|';
      v_skip_first_line   VARCHAR2 (1);
      v_header1           VARCHAR2 (10);
      v_header2           VARCHAR2 (15);
      v_header3           NUMBER;
      v_header4           NUMBER;
   BEGIN
      xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'DATA_DIR',
                                       x_param_value       => g_data_dir
                                      );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Data Directory:' || g_data_dir
                           );

      BEGIN
         v_file_type := UTL_FILE.fopen_nchar (g_data_dir, g_file_name, 'R');
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'File Opened for Reading.'
                              );
      EXCEPTION
         WHEN UTL_FILE.invalid_path
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf := 'Invalid Path for File Creation:' || g_data_dir;
         WHEN UTL_FILE.invalid_filehandle
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf := 'File handle is invalid for File :' || g_file_name;
         WHEN UTL_FILE.write_error
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf := 'Unable to write the File :' || g_file_name;
         WHEN UTL_FILE.invalid_operation
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf :=
                       'File could not be opened for writing:' || g_file_name;
         WHEN UTL_FILE.invalid_maxlinesize
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf := 'Invalid Max Line Size ' || g_file_name;
         WHEN UTL_FILE.access_denied
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf := 'Access denied for File :' || g_file_name;
         WHEN OTHERS
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf := 'File ' || g_file_name || '-' || SQLERRM;
      END;

      v_skip_first_line := 'Y';

      LOOP
         BEGIN
            UTL_FILE.get_line_nchar (v_file_type, v_line);

            IF v_skip_first_line = 'Y'
            THEN
               -- Added IF condition to skip reading the first line, as it contains column header.
               v_pos := 1;
               v_header1 := next_field (v_line, v_delimeter, v_pos);
               v_header2 := next_field (v_line, v_delimeter, v_pos);
               v_header3 := next_field (v_line, v_delimeter, v_pos);
               IF v_header3 = 0 THEN
               g_ret_code := xx_emf_cn_pkg.cn_prc_err;
               g_errbuf := 'No Records to Process.';
               g_arch_flag := 'Y';
               Rollback;
               EXIT;
               END IF;
               v_header4 := next_field (v_line, v_delimeter, v_pos);
               g_batch_total := v_header4;

               v_skip_first_line := 'N';
            ELSE
               v_pos := 1;
               v_count := v_count + 1;
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Fetching record '
                                     || v_count
                                     || ' from file.'
                                    );
               v_data_rec (v_count).batch_constant :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).batch_id :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).batch_date :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).batch_seq_number :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).emp_employee_id :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).emp_last_name :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).emp_first_name :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).emp_mi :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).emp_group_id :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).emp_org_unit1 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).emp_org_unit2 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).emp_org_unit3 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).emp_org_unit4 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).emp_org_unit5 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).emp_org_unit6 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).emp_ach_account_number :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).emp_ach_routing_number :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).emp_adjusted_reclaim_tax :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_report_id :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_report_key :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_ledger :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_reim_currency :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_home_country :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_submit_date :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_user_defined_date :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_pay_process_date :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_report_name :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_image_required :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_vat_entry :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_ta_entry :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_total_post_amount :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_total_approved_amount :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_policy_name :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_budget_accrual_date :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_org_unit1 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_org_unit2 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_org_unit3 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_org_unit4 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_org_unit5 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_org_unit6 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom1 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom2 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom3 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom4 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom5 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom6 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom7 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom8 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom9 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom10 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom11 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom12 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom13 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom14 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom15 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom16 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom17 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom18 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom19 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpt_custom20 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_entry_id :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_transaction_type :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_expense_type :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_transaction_date :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_currency_code :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_exchange_rate :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_exchange_rate_dir :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_personal_flag :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_description :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_vendor_name :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_vendor_desc :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_receipt_received_flag :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_receipt_type :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_employee_attendee :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_spouse_attendee :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_business_attendee :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_org_unit1 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_org_unit2 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_org_unit3 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_org_unit4 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_org_unit5 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_org_unit6 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom1 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom2 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom3 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom4 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom5 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom6 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom7 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom8 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom9 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom10 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom11 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom12 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom13 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom14 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom15 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom16 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom17 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom18 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom19 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom20 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom21 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom22 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom23 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom24 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom25 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom26 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom27 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom28 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom29 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom30 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom31 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom32 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom33 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom34 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom35 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom36 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom37 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom38 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom39 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_custom40 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_transaction_amount :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_posted_amount :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_approved_amount :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_payment_type_code :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_payment_code :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_payment_reim_type :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_bill_date :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column1 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column2 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column3 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column4 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column5 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column6 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column7 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column8 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column9 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column10 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column11 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column12 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column13 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column14 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column15 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column16 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column17 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column18 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column19 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column20 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column21 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column22 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column23 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column24 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column25 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column26 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column27 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cc_card_column28 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).eld_loc_country_code :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).eld_loc_country_subcode :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).eld_domestic_foreign_flag :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).eld_market_code :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).eld_processor_ref_number :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).jed_payer_type_name :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).jed_payer_code_name :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).jed_payee_type_name :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).jed_payee_code_name :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).jed_account_code :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).jed_debit_credit :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).jed_journal_amount :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).jed_journal_key :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cmd_column1 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cmd_column2 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cmd_column3 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cmd_column4 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cmd_column5 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cmd_column6 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cad_column1 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cad_column2 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cad_column3 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cad_column4 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cad_column5 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cad_column6 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cad_column7 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cad_column8 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cad_column9 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cad_column10 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cad_column11 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cad_column12 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_allocation_key :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_allocation_per :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom1 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom2 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom3 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom4 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom5 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom6 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom7 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom8 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom9 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom10 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom11 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom12 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom13 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom14 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom15 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom16 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom17 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom18 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom19 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_custom20 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).ad_net_adjusted_tax :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).tad_column1 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).tad_column2 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).tad_column3 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).tad_column4 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).tad_column5 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).tad_column6 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).tad_column7 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).tad_column8 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).tad_column9 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).tad_column10 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).tad_column11 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).tad_column12 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).tad_column13 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_column1 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_column2 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_column3 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_column4 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_column5 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_column6 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_column7 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_column8 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_column9 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_column10 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_column11 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_column12 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_column13 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_column14 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).atrd_column1 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).atrd_column2 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).atrd_column3 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).atrd_column4 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).atrd_column5 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).atrd_column6 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).atrd_column7 :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_total_tax_posted :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_net_tax_amount :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_total_reclaim_adjusted :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).vtd_net_reclaim_adjusted :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).rpte_payment_type_name :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cbs_card_program_type_code :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cbs_smt_period_start_date :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).cbs_smt_period_end_date :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).epd_cash_account_code :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).epd_liability_account_code :=
                                       next_field (v_line, v_delimeter, v_pos);
               v_data_rec (v_count).epd_estd_pay_date :=
                                       next_field (v_line, v_delimeter, v_pos);
               g_batch_id := v_data_rec (v_count).batch_id;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               IF v_count > 0
               THEN
                  EXIT;
               ELSE
                  g_ret_code := xx_emf_cn_pkg.cn_prc_err;
                  g_errbuf := 'No data in file :' || g_file_name;
               END IF;
            WHEN UTL_FILE.invalid_filehandle
            THEN
               g_ret_code := xx_emf_cn_pkg.cn_prc_err;
               g_errbuf := 'Not a valid file handle :' || g_file_name;
            WHEN UTL_FILE.invalid_operation
            THEN
               g_ret_code := xx_emf_cn_pkg.cn_prc_err;
               g_errbuf :=
                     'File is not open for reading or file is open for byte mode access:'
                  || g_file_name;
            WHEN UTL_FILE.read_error
            THEN
               g_ret_code := xx_emf_cn_pkg.cn_prc_err;
               g_errbuf := 'OS error occurred during read:' || g_file_name;
            WHEN UTL_FILE.charsetmismatch
            THEN
               g_ret_code := xx_emf_cn_pkg.cn_prc_err;
               g_errbuf := 'File is open for char data.:' || g_file_name;
            WHEN OTHERS
            THEN
               g_ret_code := xx_emf_cn_pkg.cn_prc_err;
               g_errbuf :=
                      'Error Reading File :' || g_file_name || '-' || SQLERRM;
         END;
      END LOOP;

      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output,
                         'SAE File Header Total         :' || g_batch_total
                        );
      fnd_file.put_line (fnd_file.output,
                         'SAE File Batch Id             :' || g_batch_id
                        );
      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line
         (fnd_file.output,
          '-----------------------------------------------------------------------------'
         );

      /* Close File*/
      IF UTL_FILE.is_open (v_file_type)
      THEN
         UTL_FILE.fclose (v_file_type);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Data File Closed.');
      END IF;

      IF g_ret_code = xx_emf_cn_pkg.cn_success
      THEN
         FOR i IN 1 .. v_data_rec.COUNT
         LOOP
            BEGIN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Inserting record '
                                     || i
                                     || ' into layout table.'
                                    );

               INSERT INTO xx_concur_sae_layout_tbl
                    VALUES (v_data_rec (i).batch_constant,
                            v_data_rec (i).batch_id,
                            v_data_rec (i).batch_date,
                            v_data_rec (i).batch_seq_number,
                            v_data_rec (i).emp_employee_id,
                            v_data_rec (i).emp_last_name,
                            v_data_rec (i).emp_first_name,
                            v_data_rec (i).emp_mi,
                            v_data_rec (i).emp_group_id,
                            v_data_rec (i).emp_org_unit1,
                            v_data_rec (i).emp_org_unit2,
                            v_data_rec (i).emp_org_unit3,
                            v_data_rec (i).emp_org_unit4,
                            v_data_rec (i).emp_org_unit5,
                            v_data_rec (i).emp_org_unit6,
                            v_data_rec (i).emp_ach_account_number,
                            v_data_rec (i).emp_ach_routing_number,
                            v_data_rec (i).emp_adjusted_reclaim_tax,
                            v_data_rec (i).rpt_report_id,
                            v_data_rec (i).rpt_report_key,
                            v_data_rec (i).rpt_ledger,
                            v_data_rec (i).rpt_reim_currency,
                            v_data_rec (i).rpt_home_country,
                            v_data_rec (i).rpt_submit_date,
                            v_data_rec (i).rpt_user_defined_date,
                            v_data_rec (i).rpt_pay_process_date,
                            v_data_rec (i).rpt_report_name,
                            v_data_rec (i).rpt_image_required,
                            v_data_rec (i).rpt_vat_entry,
                            v_data_rec (i).rpt_ta_entry,
                            v_data_rec (i).rpt_total_post_amount,
                            v_data_rec (i).rpt_total_approved_amount,
                            v_data_rec (i).rpt_policy_name,
                            v_data_rec (i).rpt_budget_accrual_date,
                            v_data_rec (i).rpt_org_unit1,
                            v_data_rec (i).rpt_org_unit2,
                            v_data_rec (i).rpt_org_unit3,
                            v_data_rec (i).rpt_org_unit4,
                            v_data_rec (i).rpt_org_unit5,
                            v_data_rec (i).rpt_org_unit6,
                            v_data_rec (i).rpt_custom1,
                            v_data_rec (i).rpt_custom2,
                            v_data_rec (i).rpt_custom3,
                            v_data_rec (i).rpt_custom4,
                            v_data_rec (i).rpt_custom5,
                            v_data_rec (i).rpt_custom6,
                            v_data_rec (i).rpt_custom7,
                            v_data_rec (i).rpt_custom8,
                            v_data_rec (i).rpt_custom9,
                            v_data_rec (i).rpt_custom10,
                            v_data_rec (i).rpt_custom11,
                            v_data_rec (i).rpt_custom12,
                            v_data_rec (i).rpt_custom13,
                            v_data_rec (i).rpt_custom14,
                            v_data_rec (i).rpt_custom15,
                            v_data_rec (i).rpt_custom16,
                            v_data_rec (i).rpt_custom17,
                            v_data_rec (i).rpt_custom18,
                            v_data_rec (i).rpt_custom19,
                            v_data_rec (i).rpt_custom20,
                            v_data_rec (i).rpte_entry_id,
                            v_data_rec (i).rpte_transaction_type,
                            v_data_rec (i).rpte_expense_type,
                            v_data_rec (i).rpte_transaction_date,
                            v_data_rec (i).rpte_currency_code,
                            v_data_rec (i).rpte_exchange_rate,
                            v_data_rec (i).rpte_exchange_rate_dir,
                            v_data_rec (i).rpte_personal_flag,
                            v_data_rec (i).rpte_description,
                            v_data_rec (i).rpte_vendor_name,
                            v_data_rec (i).rpte_vendor_desc,
                            v_data_rec (i).rpte_receipt_received_flag,
                            v_data_rec (i).rpte_receipt_type,
                            v_data_rec (i).rpte_employee_attendee,
                            v_data_rec (i).rpte_spouse_attendee,
                            v_data_rec (i).rpte_business_attendee,
                            v_data_rec (i).rpte_org_unit1,
                            v_data_rec (i).rpte_org_unit2,
                            v_data_rec (i).rpte_org_unit3,
                            v_data_rec (i).rpte_org_unit4,
                            v_data_rec (i).rpte_org_unit5,
                            v_data_rec (i).rpte_org_unit6,
                            v_data_rec (i).rpte_custom1,
                            v_data_rec (i).rpte_custom2,
                            v_data_rec (i).rpte_custom3,
                            v_data_rec (i).rpte_custom4,
                            v_data_rec (i).rpte_custom5,
                            v_data_rec (i).rpte_custom6,
                            v_data_rec (i).rpte_custom7,
                            v_data_rec (i).rpte_custom8,
                            v_data_rec (i).rpte_custom9,
                            v_data_rec (i).rpte_custom10,
                            v_data_rec (i).rpte_custom11,
                            v_data_rec (i).rpte_custom12,
                            v_data_rec (i).rpte_custom13,
                            v_data_rec (i).rpte_custom14,
                            v_data_rec (i).rpte_custom15,
                            v_data_rec (i).rpte_custom16,
                            v_data_rec (i).rpte_custom17,
                            v_data_rec (i).rpte_custom18,
                            v_data_rec (i).rpte_custom19,
                            v_data_rec (i).rpte_custom20,
                            v_data_rec (i).rpte_custom21,
                            v_data_rec (i).rpte_custom22,
                            v_data_rec (i).rpte_custom23,
                            v_data_rec (i).rpte_custom24,
                            v_data_rec (i).rpte_custom25,
                            v_data_rec (i).rpte_custom26,
                            v_data_rec (i).rpte_custom27,
                            v_data_rec (i).rpte_custom28,
                            v_data_rec (i).rpte_custom29,
                            v_data_rec (i).rpte_custom30,
                            v_data_rec (i).rpte_custom31,
                            v_data_rec (i).rpte_custom32,
                            v_data_rec (i).rpte_custom33,
                            v_data_rec (i).rpte_custom34,
                            v_data_rec (i).rpte_custom35,
                            v_data_rec (i).rpte_custom36,
                            v_data_rec (i).rpte_custom37,
                            v_data_rec (i).rpte_custom38,
                            v_data_rec (i).rpte_custom39,
                            v_data_rec (i).rpte_custom40,
                            v_data_rec (i).rpte_transaction_amount,
                            v_data_rec (i).rpte_posted_amount,
                            v_data_rec (i).rpte_approved_amount,
                            v_data_rec (i).rpte_payment_type_code,
                            v_data_rec (i).rpte_payment_code,
                            v_data_rec (i).rpte_payment_reim_type,
                            v_data_rec (i).rpte_bill_date,
                            v_data_rec (i).cc_card_column1,
                            v_data_rec (i).cc_card_column2,
                            v_data_rec (i).cc_card_column3,
                            v_data_rec (i).cc_card_column4,
                            v_data_rec (i).cc_card_column5,
                            v_data_rec (i).cc_card_column6,
                            v_data_rec (i).cc_card_column7,
                            v_data_rec (i).cc_card_column8,
                            v_data_rec (i).cc_card_column9,
                            v_data_rec (i).cc_card_column10,
                            v_data_rec (i).cc_card_column11,
                            v_data_rec (i).cc_card_column12,
                            v_data_rec (i).cc_card_column13,
                            v_data_rec (i).cc_card_column14,
                            v_data_rec (i).cc_card_column15,
                            v_data_rec (i).cc_card_column16,
                            v_data_rec (i).cc_card_column17,
                            v_data_rec (i).cc_card_column18,
                            v_data_rec (i).cc_card_column19,
                            v_data_rec (i).cc_card_column20,
                            v_data_rec (i).cc_card_column21,
                            v_data_rec (i).cc_card_column22,
                            v_data_rec (i).cc_card_column23,
                            v_data_rec (i).cc_card_column24,
                            v_data_rec (i).cc_card_column25,
                            v_data_rec (i).cc_card_column26,
                            v_data_rec (i).cc_card_column27,
                            v_data_rec (i).cc_card_column28,
                            v_data_rec (i).eld_loc_country_code,
                            v_data_rec (i).eld_loc_country_subcode,
                            v_data_rec (i).eld_domestic_foreign_flag,
                            v_data_rec (i).eld_market_code,
                            v_data_rec (i).eld_processor_ref_number,
                            v_data_rec (i).jed_payer_type_name,
                            v_data_rec (i).jed_payer_code_name,
                            v_data_rec (i).jed_payee_type_name,
                            v_data_rec (i).jed_payee_code_name,
                            v_data_rec (i).jed_account_code,
                            v_data_rec (i).jed_debit_credit,
                            v_data_rec (i).jed_journal_amount,
                            v_data_rec (i).jed_journal_key,
                            v_data_rec (i).cmd_column1,
                            v_data_rec (i).cmd_column2,
                            v_data_rec (i).cmd_column3,
                            v_data_rec (i).cmd_column4,
                            v_data_rec (i).cmd_column5,
                            v_data_rec (i).cmd_column6,
                            v_data_rec (i).cad_column1,
                            v_data_rec (i).cad_column2,
                            v_data_rec (i).cad_column3,
                            v_data_rec (i).cad_column4,
                            v_data_rec (i).cad_column5,
                            v_data_rec (i).cad_column6,
                            v_data_rec (i).cad_column7,
                            v_data_rec (i).cad_column8,
                            v_data_rec (i).cad_column9,
                            v_data_rec (i).cad_column10,
                            v_data_rec (i).cad_column11,
                            v_data_rec (i).cad_column12,
                            v_data_rec (i).ad_allocation_key,
                            v_data_rec (i).ad_allocation_per,
                            v_data_rec (i).ad_custom1,
                            v_data_rec (i).ad_custom2,
                            v_data_rec (i).ad_custom3,
                            v_data_rec (i).ad_custom4,
                            v_data_rec (i).ad_custom5,
                            v_data_rec (i).ad_custom6,
                            v_data_rec (i).ad_custom7,
                            v_data_rec (i).ad_custom8,
                            v_data_rec (i).ad_custom9,
                            v_data_rec (i).ad_custom10,
                            v_data_rec (i).ad_custom11,
                            v_data_rec (i).ad_custom12,
                            v_data_rec (i).ad_custom13,
                            v_data_rec (i).ad_custom14,
                            v_data_rec (i).ad_custom15,
                            v_data_rec (i).ad_custom16,
                            v_data_rec (i).ad_custom17,
                            v_data_rec (i).ad_custom18,
                            v_data_rec (i).ad_custom19,
                            v_data_rec (i).ad_custom20,
                            v_data_rec (i).ad_net_adjusted_tax,
                            v_data_rec (i).tad_column1,
                            v_data_rec (i).tad_column2,
                            v_data_rec (i).tad_column3,
                            v_data_rec (i).tad_column4,
                            v_data_rec (i).tad_column5,
                            v_data_rec (i).tad_column6,
                            v_data_rec (i).tad_column7,
                            v_data_rec (i).tad_column8,
                            v_data_rec (i).tad_column9,
                            v_data_rec (i).tad_column10,
                            v_data_rec (i).tad_column11,
                            v_data_rec (i).tad_column12,
                            v_data_rec (i).tad_column13,
                            v_data_rec (i).vtd_column1,
                            v_data_rec (i).vtd_column2,
                            v_data_rec (i).vtd_column3,
                            v_data_rec (i).vtd_column4,
                            v_data_rec (i).vtd_column5,
                            v_data_rec (i).vtd_column6,
                            v_data_rec (i).vtd_column7,
                            v_data_rec (i).vtd_column8,
                            v_data_rec (i).vtd_column9,
                            v_data_rec (i).vtd_column10,
                            v_data_rec (i).vtd_column11,
                            v_data_rec (i).vtd_column12,
                            v_data_rec (i).vtd_column13,
                            v_data_rec (i).vtd_column14,
                            v_data_rec (i).atrd_column1,
                            v_data_rec (i).atrd_column2,
                            v_data_rec (i).atrd_column3,
                            v_data_rec (i).atrd_column4,
                            v_data_rec (i).atrd_column5,
                            v_data_rec (i).atrd_column6,
                            v_data_rec (i).atrd_column7,
                            v_data_rec (i).vtd_total_tax_posted,
                            v_data_rec (i).vtd_net_tax_amount,
                            v_data_rec (i).vtd_total_reclaim_adjusted,
                            v_data_rec (i).vtd_net_reclaim_adjusted,
                            v_data_rec (i).rpte_payment_type_name,
                            v_data_rec (i).cbs_card_program_type_code,
                            v_data_rec (i).cbs_smt_period_start_date,
                            v_data_rec (i).cbs_smt_period_end_date,
                            v_data_rec (i).epd_cash_account_code,
                            v_data_rec (i).epd_liability_account_code,
                            v_data_rec (i).epd_estd_pay_date,
                            fnd_global.conc_request_id);
            EXCEPTION
               WHEN OTHERS
               THEN
                  g_ret_code := xx_emf_cn_pkg.cn_prc_err;
                  g_errbuf := 'Error inserting into layout table:' || SQLERRM;
                  Rollback;
            END;
         END LOOP;
      END IF;
   END load_layout_table;

   PROCEDURE load_staging_table
   IS
      CURSOR c_main
      IS
         SELECT batch_id, batch_date, emp_employee_id, emp_last_name,
                emp_first_name, emp_group_id, rpt_report_key,
                rpt_reim_currency, rpt_home_country, rpt_submit_date,
                rpt_pay_process_date, rpt_report_name, rpt_image_required,
                rpt_vat_entry, rpt_ta_entry, rpt_total_post_amount,
                rpt_total_approved_amount, rpt_policy_name, rpte_entry_id,
                rpte_transaction_type, rpte_expense_type,
                rpte_transaction_date, rpte_exchange_rate,
                rpte_personal_flag, rpte_description,
                rpte_receipt_received_flag, rpte_custom1, rpte_custom2,
                rpte_custom3, rpte_custom4, rpte_custom5, rpte_custom6,
                rpte_custom7, rpte_custom8, rpte_custom9, rpte_custom10,
                rpte_custom11, rpte_transaction_amount, rpte_posted_amount,
                rpte_approved_amount, rpte_payment_type_code, rpte_bill_date,
                eld_loc_country_code, eld_loc_country_subcode,
                eld_domestic_foreign_flag, jed_payer_type_name,
                jed_payer_code_name, jed_payee_type_name,
                jed_payee_code_name, jed_account_code, jed_debit_credit,
                jed_journal_amount, jed_journal_key, ad_allocation_key,
                ad_allocation_per, ad_net_adjusted_tax,
                rpte_payment_type_name, cbs_card_program_type_code,
                epd_cash_account_code, epd_liability_account_code
           FROM xx_concur_sae_layout_tbl
          WHERE batch_id = g_batch_id
            AND request_id = fnd_global.conc_request_id;

      v_record_id   NUMBER;
      v_count       NUMBER;
   BEGIN
      v_count := 1;

      FOR v_main IN c_main
      LOOP
         BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Inserting record '
                                  || v_count
                                  || ' into layout table.'
                                 );

            SELECT xx_concur_sae_int_s.NEXTVAL
              INTO v_record_id
              FROM DUAL;

            INSERT INTO xx_concur_sae_tbl
                 VALUES (v_record_id, v_main.batch_id,
                         TO_DATE (v_main.batch_date, 'RRRR-MM-DD'),
                         v_main.emp_employee_id, v_main.emp_last_name,
                         v_main.emp_first_name, v_main.emp_group_id,
                         v_main.rpt_report_key, v_main.rpt_reim_currency,
                         v_main.rpt_home_country,
                         TO_DATE (v_main.rpt_submit_date, 'RRRR-MM-DD'),
                         TO_DATE (v_main.rpt_pay_process_date, 'RRRR-MM-DD'),
                         v_main.rpt_report_name, v_main.rpt_image_required,
                         v_main.rpt_vat_entry, v_main.rpt_ta_entry,
                         v_main.rpt_total_post_amount,
                         v_main.rpt_total_approved_amount,
                         v_main.rpt_policy_name, v_main.rpte_entry_id,
                         v_main.rpte_transaction_type,
                         v_main.rpte_expense_type,
                         TO_DATE (v_main.rpte_transaction_date, 'RRRR-MM-DD'),
                         v_main.rpte_exchange_rate, v_main.rpte_personal_flag,
                         v_main.rpte_description,
                         v_main.rpte_receipt_received_flag,
                         v_main.rpte_custom1, v_main.rpte_custom2,
                         v_main.rpte_custom3, v_main.rpte_custom4,
                         v_main.rpte_custom5, v_main.rpte_custom6,
                         v_main.rpte_custom7, v_main.rpte_custom8,
                         v_main.rpte_custom9, v_main.rpte_custom10,
                         v_main.rpte_custom11, v_main.rpte_transaction_amount,
                         v_main.rpte_posted_amount,
                         v_main.rpte_approved_amount,
                         v_main.rpte_payment_type_code,
                         TO_DATE (v_main.rpte_bill_date, 'RRRR-MM-DD'),
                         v_main.eld_loc_country_code,
                         v_main.eld_loc_country_subcode,
                         v_main.eld_domestic_foreign_flag,
                         v_main.jed_payer_type_name,
                         v_main.jed_payer_code_name,
                         v_main.jed_payee_type_name,
                         v_main.jed_payee_code_name, v_main.jed_account_code,
                         v_main.jed_debit_credit, v_main.jed_journal_amount,
                         v_main.jed_journal_key, v_main.ad_allocation_key,
                         v_main.ad_allocation_per, v_main.ad_net_adjusted_tax,
                         v_main.rpte_payment_type_name,
                         v_main.cbs_card_program_type_code,
                         v_main.epd_cash_account_code,
                         v_main.epd_liability_account_code, 'NEW', NULL, NULL,
                         fnd_global.conc_request_id);

            v_count := v_count + 1;
         EXCEPTION
            WHEN OTHERS
            THEN
               g_ret_code := xx_emf_cn_pkg.cn_prc_err;
               g_errbuf := 'Error inserting into staging table:' || SQLERRM;
               Rollback;
         END;
      END LOOP;
   END load_staging_table;

   PROCEDURE load_interface_table
   IS
      CURSOR c_main
      IS
         SELECT DISTINCT company, department, ACCOUNT, classification,
                         product, region, intercompany, future,
                         --report_entry_transaction_date,
                         journal_debit_or_credit

                    FROM xx_concur_sae_tbl
                   WHERE batch_id = g_batch_id
                     AND request_id = fnd_global.conc_request_id
                     AND personal_expense = 'N'
                     AND report_policy_name = 'US Expense Policy'
                     ORDER BY journal_debit_or_credit; -- Added for Ticket#5621

      CURSOR c_main_pc
      IS
         SELECT DISTINCT company, department, ACCOUNT, classification,
                         product, region, intercompany, future,
                         --report_entry_transaction_date,
                         journal_debit_or_credit
                    FROM xx_concur_sae_tbl
                   WHERE batch_id = g_batch_id
                     AND REQUEST_ID = FND_GLOBAL.CONC_REQUEST_ID
--                     AND personal_expense='N'
                     AND personal_expense in( 'N','Y') --Added for Ticket#5831
                     AND report_policy_name <> 'US Expense Policy'
                     ORDER BY journal_debit_or_credit; -- Added for Ticket#5621

      v_ledger_name        VARCHAR2 (40);
      v_source_name        VARCHAR2 (40);
      v_line_description   VARCHAR2 (240);
      v_count              NUMBER;
      v_debit_amount       NUMBER;
      v_credit_amount      NUMBER;
      v_sce1               NUMBER;
      v_sce2               NUMBER;
      v_sce3               NUMBER;
      v_sce4               NUMBER;
      v_sce5               NUMBER; -- Added for P-Card implementation
      v_sce6               NUMBER; -- Added for P-Card implementation
      v_journal_name       VARCHAR2 (100);
      v_category_name      VARCHAR2 (100);
   BEGIN
      xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'LEDGER_NAME',
                                       x_param_value       => v_ledger_name
                                      );
      xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'SOURCE_NAME',
                                        x_param_value       => g_je_source_name
                                       );
      xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CATEGORY_NAME',
                                        x_param_value       => v_category_name
                                       );
      xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'JOURNAL_NAME',
                                        x_param_value       => v_journal_name
                                       );
      v_journal_name :=
               v_journal_name || '_' || TO_CHAR (SYSDATE, 'RRRRMMDD_HH24MMSS');
      g_journal_name := v_journal_name;  -- Added for ticket# 5204
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Source Name: ' || g_je_source_name
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Category Name: ' || v_category_name
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Journal Name: ' || v_journal_name
                           );

      BEGIN
         SELECT ledger_id
           INTO g_ledger_id
           FROM gl_ledgers
          WHERE NAME = v_ledger_name;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Ledger Name: ' || v_ledger_name
                              );
      EXCEPTION
         WHEN OTHERS
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf := 'Error Getting Ledger Name:' || SQLERRM;
            Rollback;
      END;
      g_int_total_d := 0; -- Added for Ticket#5621
      g_int_total_c := 0; -- Added for Ticket#5621
      fnd_file.put_line (fnd_file.output,
                         'Records Inserted into GL_INTERFACE Table'
                        );
      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, 'Debit/Credit Reversal Records for expenses');

      IF g_ret_code = xx_emf_cn_pkg.cn_success
      THEN
         v_count := 1;

         FOR v_main IN c_main
         LOOP
            BEGIN
               IF v_main.journal_debit_or_credit = 'CR'
               THEN
                  SELECT (SUM (journal_line_amount)* -1)
                    INTO v_credit_amount
                    FROM xx_concur_sae_tbl
                   WHERE company = v_main.company
                     AND department = v_main.department
                     AND ACCOUNT = v_main.ACCOUNT
                     AND classification = v_main.classification
                     AND product = v_main.product
                     AND region = v_main.region
                     AND intercompany = v_main.intercompany
                     --AND report_entry_transaction_date =
                       --                   v_main.report_entry_transaction_date
                     AND journal_debit_or_credit =
                                                v_main.journal_debit_or_credit
                     AND batch_id = g_batch_id
                     AND report_policy_name = 'US Expense Policy'
                     AND request_id = fnd_global.conc_request_id
                     AND personal_expense = 'N';
                  g_int_total_c := g_int_total_c + NVL(v_credit_amount,0); -- Added for Ticket#5621
                  v_debit_amount := NULL;
               ELSE
                  SELECT SUM (journal_line_amount)
                    INTO v_debit_amount
                    FROM xx_concur_sae_tbl
                   WHERE company = v_main.company
                     AND department = v_main.department
                     AND ACCOUNT = v_main.ACCOUNT
                     AND classification = v_main.classification
                     AND product = v_main.product
                     AND region = v_main.region
                     AND intercompany = v_main.intercompany
                     AND report_policy_name = 'US Expense Policy'
                     --AND report_entry_transaction_date =
                                          --v_main.report_entry_transaction_date
                     AND journal_debit_or_credit =
                                                v_main.journal_debit_or_credit
                     AND batch_id = g_batch_id
                     AND request_id = fnd_global.conc_request_id
                     AND personal_expense = 'N';
                  g_int_total_d := g_int_total_d + NVL(v_debit_amount,0); -- Added for Ticket#5621
                  v_credit_amount := NULL;
               END IF;

               v_line_description := NULL;

               SELECT COUNT (1)
                 INTO v_sce1
                 FROM XX_CONCUR_SAE_TBL
                WHERE UPPER (payment_type_code) ='CBCP'
                  --AND UPPER (employee_group_id) = 'ILSUS' --Modified for Ticket 5204
                  AND UPPER (personal_expense) = 'N'
                  AND company = v_main.company
                  AND department = v_main.department
                  AND ACCOUNT = v_main.ACCOUNT
                  AND classification = v_main.classification
                  AND product = v_main.product
                  AND region = v_main.region
                  AND intercompany = v_main.intercompany
                  AND future = v_main.future
                  and report_policy_name = 'US Expense Policy'
                  AND journal_debit_or_credit =
                                                v_main.journal_debit_or_credit
                  AND request_id = fnd_global.conc_request_id;

               SELECT COUNT (1)
                 INTO v_sce2
                 FROM XX_CONCUR_SAE_TBL
                WHERE UPPER (payment_type_code) = 'CBCP'
                  AND UPPER (personal_expense) = 'Y'
                  AND company = v_main.company
                  AND department = v_main.department
                  AND ACCOUNT = v_main.ACCOUNT
                  AND classification = v_main.classification
                  AND journal_debit_or_credit =
                                                v_main.journal_debit_or_credit
                  and report_policy_name = 'US Expense Policy'
                  AND product = v_main.product
                  AND region = v_main.region
                  AND intercompany = v_main.intercompany
                  AND future = v_main.future
                  AND request_id = fnd_global.conc_request_id
                  AND journal_debit_or_credit = 'DR';

               SELECT COUNT (1)
                 INTO v_sce3
                 FROM XX_CONCUR_SAE_TBL
                WHERE UPPER (payment_type_code) ='CASH'
                  AND UPPER (employee_group_id) = 'US'
                  AND UPPER (personal_expense) = 'N'
                  AND company = v_main.company
                  AND department = v_main.department
                  AND ACCOUNT = v_main.ACCOUNT
                  AND classification = v_main.classification
                  AND product = v_main.product
                  AND region = v_main.region
                  AND intercompany = v_main.intercompany
                  AND future = v_main.future
                  AND report_policy_name = 'US Expense Policy'
                  AND journal_debit_or_credit =
                                                v_main.journal_debit_or_credit
                  AND request_id = fnd_global.conc_request_id;

               SELECT COUNT (1)
                 INTO v_sce4
                 FROM XX_CONCUR_SAE_TBL
                WHERE UPPER (payment_type_code) ='CASH'
                  AND UPPER (employee_group_id) != 'US'
                  AND UPPER (personal_expense) = 'N'
                  AND company = v_main.company
                  AND department = v_main.department
                  AND ACCOUNT = v_main.ACCOUNT
                  AND classification = v_main.classification
                  AND product = v_main.product
                  AND region = v_main.region
                  AND intercompany = v_main.intercompany
                  AND future = v_main.future
                  AND report_policy_name = 'US Expense Policy'
                  AND journal_debit_or_credit =
                                                v_main.journal_debit_or_credit
                  AND request_id = fnd_global.conc_request_id;

               IF v_sce1 > 0
               THEN
                 IF v_main.journal_debit_or_credit ='DR' THEN
                  v_line_description :=
                        v_line_description || 'BOA Visa T Transaction.';
                 ELSE
                 v_line_description :=
                        v_line_description || 'BOA Visa T Transaction Credit Reversal.';

                 END IF;
               END IF;

               IF v_sce5 > 0 -- IF Condition Added for P-Card implementation
               THEN
                 IF v_main.journal_debit_or_credit ='DR' THEN

                  IF v_line_description IS NULL
                  THEN
                     v_line_description := 'BOA Visa Pcard Transaction(P-Card).';
                  ELSE
                     v_line_description :=
                           v_line_description
                        || '+ BOA Visa Pcard Transaction(P-Card).';
                  END IF;

                 ELSE

                  IF v_line_description IS NULL
                  THEN
                     v_line_description := 'BOA Visa Pcard Transaction Credit Reversal(P-Card).';
                  ELSE
                     v_line_description :=
                           v_line_description
                        || '+ BOA Visa Pcard Transaction Credit Reversal(P-Card).';
                  END IF;

                 END IF;
               END IF;

               IF v_sce2 > 0
               THEN
                  IF v_line_description IS NULL
                  THEN
                     v_line_description := 'Personal Expense Transaction.';
                  ELSE
                     v_line_description :=
                           v_line_description
                        || '+ Personal Expense Transaction.';
                  END IF;
               END IF;

               IF v_sce6 > 0 -- IF Condition Added for P-Card implementation
               THEN
                  IF v_line_description IS NULL
                  THEN
                     v_line_description := 'Personal Expense Transaction(P-Card).';
                  ELSE
                     v_line_description :=
                           v_line_description
                        || '+ Personal Expense Transaction(P-Card).';
                  END IF;
               END IF;

               IF v_sce3 > 0
               THEN
                  IF v_line_description IS NULL
                  THEN
                    IF v_main.journal_debit_or_credit ='DR' THEN
                     v_line_description :=
                                         'Out of Pocket - Expense Pay Group.';
                    ELSE
                    v_line_description :=
                                         'Out of Pocket - Expense Pay Group Credit Reversal.';
                    END IF;
                  ELSE
                    IF v_main.journal_debit_or_credit ='DR' THEN
                     v_line_description :=
                           v_line_description
                        || '+ Out of Pocket - Expense Pay Group.';
                    ELSE
                    v_line_description :=
                           v_line_description
                        || '+ Out of Pocket - Expense Pay Group Credit Reversal.';
                    END IF;
                  END IF;
               END IF;

               IF v_sce4 > 0
               THEN
                  IF v_line_description IS NULL
                  THEN
                    IF v_main.journal_debit_or_credit ='DR' THEN
                     v_line_description :=
                                         'Out of Pocket - Non Expense Pay Group.';
                    ELSE
                    v_line_description :=
                                         'Out of Pocket - Non Expense Pay Group Credit Reversal.';
                    END IF;
                  ELSE
                     IF v_main.journal_debit_or_credit ='DR' THEN
                     v_line_description :=
                           v_line_description
                        ||'+ Out of Pocket - Non Expense Pay Group.';
                    ELSE
                    v_line_description :=
                           v_line_description
                        ||'+ Out of Pocket - Non Expense Pay Group Credit Reversal.';
                    END IF;
                  END IF;
               END IF;

               /*v_line_description :=
                     TO_CHAR (SYSDATE, 'RRRRMMDD')
                  || '-'
                  || v_main.company
                  || '.'
                  || v_main.department
                  || '.'
                  || v_main.ACCOUNT
                  || '.'
                  || v_main.classification
                  || '.'
                  || v_main.product
                  || '.'
                  || v_main.region
                  || '.'
                  || v_main.intercompany
                  || '.'
                  || v_main.future;*/
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Inserting record '
                                     || v_count
                                     || ' into Interface table.'
                                    );

               INSERT INTO gl_interface
                           (status, accounting_date, currency_code,
                            date_created, actual_flag, user_je_category_name,
                            user_je_source_name, segment1,
                            segment2, segment3,
                            segment4, segment5,
                            segment6, segment7,
                            segment8, created_by,
                            entered_dr, entered_cr, ledger_id,
                            reference4, reference10, GROUP_ID
                           )
                    VALUES ('New', SYSDATE,
                                            --v_main.report_entry_transaction_date,
                            'USD',
                            SYSDATE, 'A', v_category_name,
                            g_je_source_name, v_main.company,
                            v_main.department, v_main.ACCOUNT,
                            v_main.classification, v_main.product,
                            v_main.region, v_main.intercompany,
                            v_main.future, fnd_global.user_id,
                            v_debit_amount, v_credit_amount, g_ledger_id,
                            v_journal_name, v_line_description, g_batch_id
                           );

               g_string :=
                     v_main.company
                  || '.'
                  || v_main.department
                  || '.'
                  || v_main.ACCOUNT
                  || '.'
                  || v_main.classification
                  || '.'
                  || v_main.product
                  || '.'
                  || v_main.region
                  || '.'
                  || v_main.intercompany
                  || '.'
                  || v_main.future;
             IF  v_debit_amount IS NOT NULL THEN
               fnd_file.put_line (fnd_file.output,
                                     g_string
                                  || '     '
                                  || 'Dr'
                                  || '     '
                                  || TO_CHAR (SYSDATE, 'DD-MON-RRRR')
                                  || '     '
                                  || v_debit_amount
                                 );
               fnd_file.put_line (fnd_file.output, '');
            END IF;
            -- Added for Ticket#5621 Start
            IF  v_credit_amount IS NOT NULL THEN
               fnd_file.put_line (fnd_file.output,
                                     g_string
                                  || '     '
                                  || 'Cr'
                                  || '     '
                                  || TO_CHAR (SYSDATE, 'DD-MON-RRRR')
                                  || '     '
                                  || v_credit_amount
                                 );
               fnd_file.put_line (fnd_file.output, '');
            END IF;
            -- Added for Ticket#5621 End
               g_string := NULL;
               v_count := v_count + 1;
            EXCEPTION
               WHEN OTHERS
               THEN
                  g_ret_code := xx_emf_cn_pkg.cn_prc_err;
                  g_errbuf :=
                           'Error inserting into interface table:' || SQLERRM;
                  Rollback;
            END;
         END LOOP;

         FOR v_main IN c_main_pc
         LOOP
            BEGIN
               IF v_main.journal_debit_or_credit = 'CR'
               THEN
                  SELECT (SUM (journal_line_amount)* -1)
                    INTO v_credit_amount
                    FROM xx_concur_sae_tbl
                   WHERE company = v_main.company
                     AND department = v_main.department
                     AND ACCOUNT = v_main.ACCOUNT
                     AND classification = v_main.classification
                     AND product = v_main.product
                     AND region = v_main.region
                     AND intercompany = v_main.intercompany
                     --AND report_entry_transaction_date =
                       --                   v_main.report_entry_transaction_date
                     AND journal_debit_or_credit =
                                                v_main.journal_debit_or_credit
                     AND batch_id = g_batch_id
                     AND report_policy_name <> 'US Expense Policy'
                     AND request_id = fnd_global.conc_request_id
--                     AND personal_expense = 'N';
                     AND PERSONAL_EXPENSE IN ('N','Y');--Added for Ticket#5831
                  g_int_total_c := g_int_total_c + NVL(v_credit_amount,0); -- Added for Ticket#5621
                  v_debit_amount := NULL;
               ELSE
                  SELECT SUM (journal_line_amount)
                    INTO v_debit_amount
                    FROM xx_concur_sae_tbl
                   WHERE company = v_main.company
                     AND department = v_main.department
                     AND ACCOUNT = v_main.ACCOUNT
                     AND classification = v_main.classification
                     AND product = v_main.product
                     AND region = v_main.region
                     AND intercompany = v_main.intercompany
                     AND report_policy_name <> 'US Expense Policy'
                     --AND report_entry_transaction_date =
                                          --v_main.report_entry_transaction_date
                     AND journal_debit_or_credit =
                                                v_main.journal_debit_or_credit
                     AND batch_id = g_batch_id
                     AND request_id = fnd_global.conc_request_id
--                     AND personal_expense = 'N';
                     AND PERSONAL_EXPENSE IN ('N','Y');--Added by Prasanna S
                  g_int_total_d := g_int_total_d + NVL(v_debit_amount,0); -- Added for Ticket#5621
                  v_credit_amount := NULL;
               END IF;

               v_line_description := NULL;


               -- Select statement Added for P-Card implementation
               SELECT COUNT (1)
                 INTO v_sce5
                 FROM XX_CONCUR_SAE_TBL
                WHERE UPPER (payment_type_code)= 'CBCP'
                  --AND UPPER (employee_group_id) = 'ILSUS' --Modified for Ticket 5204
                  AND UPPER (personal_expense) in('N','Y')
                  AND company = v_main.company
                  AND department = v_main.department
                  AND ACCOUNT = v_main.ACCOUNT
                  AND classification = v_main.classification
                  AND product = v_main.product
                  AND region = v_main.region
                  AND intercompany = v_main.intercompany
                  AND future = v_main.future
                  and report_policy_name <> 'US Expense Policy'
                  AND journal_debit_or_credit =
                                                v_main.journal_debit_or_credit
                  AND request_id = fnd_global.conc_request_id;

                -- Select statement Added for P-Card implementation
                /*SELECT COUNT (1)
                 INTO v_sce6
                 FROM xx_concur_sae_tbl
                WHERE UPPER (payment_type_code) = 'CBCP'
                  AND UPPER (personal_expense) = 'Y'
                  AND company = v_main.company
                  AND department = v_main.department
                  AND ACCOUNT = v_main.ACCOUNT
                  AND classification = v_main.classification
                  AND journal_debit_or_credit =
                                                v_main.journal_debit_or_credit
                  and report_policy_name <> 'US Expense Policy'
                  AND product = v_main.product
                  AND region = v_main.region
                  AND intercompany = v_main.intercompany
                  AND future = v_main.future
                  AND request_id = fnd_global.conc_request_id
                  AND journal_debit_or_credit = 'DR'; */


               IF v_sce5 > 0 -- IF Condition Added for P-Card implementation
               THEN
                 IF v_main.journal_debit_or_credit ='DR' THEN

                  IF v_line_description IS NULL
                  THEN
                     v_line_description := 'BOA Visa Pcard Transaction(P-Card).';
                  ELSE
                     v_line_description :=
                           v_line_description
                        || '+ BOA Visa Pcard Transaction(P-Card).';
                  END IF;

                 ELSE

                  IF v_line_description IS NULL
                  THEN
                     v_line_description := 'BOA Visa Pcard Transaction Credit Reversal(P-Card).';
                  ELSE
                     v_line_description :=
                           v_line_description
                        || '+ BOA Visa Pcard Transaction Credit Reversal(P-Card).';
                  END IF;

                 END IF;
               END IF;


               IF v_sce6 > 0 -- IF Condition Added for P-Card implementation
               THEN
                  IF v_line_description IS NULL
                  THEN
                     v_line_description := 'Personal Expense Transaction(P-Card).';
                  ELSE
                     v_line_description :=
                           v_line_description
                        || '+ Personal Expense Transaction(P-Card).';
                  END IF;
               END IF;

               /*v_line_description :=
                     TO_CHAR (SYSDATE, 'RRRRMMDD')
                  || '-'
                  || v_main.company
                  || '.'
                  || v_main.department
                  || '.'
                  || v_main.ACCOUNT
                  || '.'
                  || v_main.classification
                  || '.'
                  || v_main.product
                  || '.'
                  || v_main.region
                  || '.'
                  || v_main.intercompany
                  || '.'
                  || v_main.future;*/
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Inserting record '
                                     || v_count
                                     || ' into Interface table.'
                                    );

               INSERT INTO gl_interface
                           (status, accounting_date, currency_code,
                            date_created, actual_flag, user_je_category_name,
                            user_je_source_name, segment1,
                            segment2, segment3,
                            segment4, segment5,
                            segment6, segment7,
                            segment8, created_by,
                            entered_dr, entered_cr, ledger_id,
                            reference4, reference10, GROUP_ID
                           )
                    VALUES ('New', SYSDATE,
                                            --v_main.report_entry_transaction_date,
                            'USD',
                            SYSDATE, 'A', 'Other', --Added for Ticket#5831
                            'Concur GL', v_main.company,
                            v_main.department, v_main.ACCOUNT,
                            v_main.classification, v_main.product,
                            v_main.region, v_main.intercompany,
                            v_main.future, fnd_global.user_id,
                            v_debit_amount, v_credit_amount, g_ledger_id,
                            v_journal_name, v_line_description, g_batch_id
                           );

               g_string :=
                     v_main.company
                  || '.'
                  || v_main.department
                  || '.'
                  || v_main.ACCOUNT
                  || '.'
                  || v_main.classification
                  || '.'
                  || v_main.product
                  || '.'
                  || v_main.region
                  || '.'
                  || v_main.intercompany
                  || '.'
                  || v_main.future;
             IF  v_debit_amount IS NOT NULL THEN
               fnd_file.put_line (fnd_file.output,
                                     g_string
                                  || '     '
                                  || 'Dr'
                                  || '     '
                                  || TO_CHAR (SYSDATE, 'DD-MON-RRRR')
                                  || '     '
                                  || v_debit_amount
                                 );
               fnd_file.put_line (fnd_file.output, '');
            END IF;
            -- Added for Ticket#5621 Start
            IF  v_credit_amount IS NOT NULL THEN
               fnd_file.put_line (fnd_file.output,
                                     g_string
                                  || '     '
                                  || 'Cr'
                                  || '     '
                                  || TO_CHAR (SYSDATE, 'DD-MON-RRRR')
                                  || '     '
                                  || v_credit_amount
                                 );
               fnd_file.put_line (fnd_file.output, '');
            END IF;
            -- Added for Ticket#5621 End
               g_string := NULL;
               v_count := v_count + 1;
            EXCEPTION
               WHEN OTHERS
               THEN
                  g_ret_code := xx_emf_cn_pkg.cn_prc_err;
                  g_errbuf :=
                           'Error inserting into interface table:' || SQLERRM;
                  Rollback;
            END;
         END LOOP;


      END IF;
   END load_interface_table;

   PROCEDURE generate_credit_lines
   IS
      v_ledger_name          VARCHAR2 (40);
      v_source_name          VARCHAR2 (40);
      v_line_description     VARCHAR2 (240);
      v_sum_off_card         NUMBER;
      v_off_card_segment1    VARCHAR2 (40);
      v_off_card_segment2    VARCHAR2 (40);
      v_off_card_segment3    VARCHAR2 (40);
      v_off_card_segment4    VARCHAR2 (40);
      v_off_card_segment5    VARCHAR2 (40);
      v_off_card_segment6    VARCHAR2 (40);
      v_off_card_segment7    VARCHAR2 (40);
      v_off_card_segment8    VARCHAR2 (40);
      v_pers_sum             NUMBER;
      v_db_pers_segment1     VARCHAR2 (40);
      v_db_pers_segment2     VARCHAR2 (40);
      v_db_pers_segment3     VARCHAR2 (40);
      v_db_pers_segment4     VARCHAR2 (40);
      v_db_pers_segment5     VARCHAR2 (40);
      v_db_pers_segment6     VARCHAR2 (40);
      v_db_pers_segment7     VARCHAR2 (40);
      v_db_pers_segment8     VARCHAR2 (40);
      v_cr_pers_segment1     VARCHAR2 (40);
      v_cr_pers_segment2     VARCHAR2 (40);
      v_cr_pers_segment3     VARCHAR2 (40);
      v_cr_pers_segment4     VARCHAR2 (40);
      v_cr_pers_segment5     VARCHAR2 (40);
      v_cr_pers_segment6     VARCHAR2 (40);
      v_cr_pers_segment7     VARCHAR2 (40);
      v_cr_pers_segment8     VARCHAR2 (40);
      v_cash_exp             NUMBER;
      v_cash_exp_segment1    VARCHAR2 (40);
      v_cash_exp_segment2    VARCHAR2 (40);
      v_cash_exp_segment3    VARCHAR2 (40);
      v_cash_exp_segment4    VARCHAR2 (40);
      v_cash_exp_segment5    VARCHAR2 (40);
      v_cash_exp_segment6    VARCHAR2 (40);
      v_cash_exp_segment7    VARCHAR2 (40);
      v_cash_exp_segment8    VARCHAR2 (40);
      v_cash_nexp            NUMBER;
      v_cash_nexp_segment1   VARCHAR2 (40);
      v_cash_nexp_segment2   VARCHAR2 (40);
      v_cash_nexp_segment3   VARCHAR2 (40);
      v_cash_nexp_segment4   VARCHAR2 (40);
      v_cash_nexp_segment5   VARCHAR2 (40);
      v_cash_nexp_segment6   VARCHAR2 (40);
      v_cash_nexp_segment7   VARCHAR2 (40);
      v_cash_nexp_segment8   VARCHAR2 (40);
      v_count                NUMBER;
      v_debit_amount         NUMBER;
      v_credit_amount        NUMBER;
      v_journal_name         VARCHAR2 (100);
      v_category_name        VARCHAR2 (100);
      v_accounting_date      DATE;
       v_stg_total1         NUMBER;
      v_stg_total2         NUMBER;
      v_stg_total3         NUMBER;
      v_stg_total4         NUMBER;
      v_stg_total5         NUMBER;

      CURSOR c_card_expense
      IS
         SELECT              --report_entry_transaction_date accounting_date,
                SUM (journal_line_amount) sum_off_card
           FROM XX_CONCUR_SAE_TBL
          WHERE UPPER (payment_type_code) in('CBCP','IBIP')
            --AND UPPER (employee_group_id) = 'ILSUS'--Modified for Ticket 5204
            AND UPPER (personal_expense) = 'N'
            AND journal_debit_or_credit = 'DR'-- Modified for Ticket 5621
            and report_policy_name = 'US Expense Policy'--added for P-Card implementation
            AND request_id = fnd_global.conc_request_id;

       CURSOR c_card_expense_pc -- cursor added for P-Card implementation
      IS
         SELECT
                SUM (journal_line_amount) sum_off_card
           FROM XX_CONCUR_SAE_TBL
          WHERE UPPER (PAYMENT_TYPE_CODE) ='CBCP'
            AND UPPER (personal_expense) = 'N'
            AND journal_debit_or_credit = 'DR'
            and report_policy_name <> 'US Expense Policy'
            AND request_id = fnd_global.conc_request_id;

      CURSOR c_card_expense1 -- Added for Ticket#5621
      IS
         SELECT              --report_entry_transaction_date accounting_date,
                (SUM (journal_line_amount)*-1) sum_off_card
           FROM XX_CONCUR_SAE_TBL
          WHERE UPPER (PAYMENT_TYPE_CODE) in('CBCP','IBIP')
            --AND UPPER (employee_group_id) = 'ILSUS'--Modified for Ticket 5204
            AND UPPER (personal_expense) = 'N'
            AND journal_debit_or_credit = 'CR'-- Modified for Ticket 5621
            and report_policy_name = 'US Expense Policy'--added for P-Card implementation
            AND request_id = fnd_global.conc_request_id;

      CURSOR c_card_expense1_pc -- Cursor Added for P-Card implementation
      IS
         SELECT
                (SUM (journal_line_amount)*-1) sum_off_card
           FROM XX_CONCUR_SAE_TBL
          WHERE UPPER (payment_type_code) = 'CBCP'
            AND UPPER (personal_expense) = 'N'
            AND journal_debit_or_credit = 'CR'
            and report_policy_name <> 'US Expense Policy'
            AND request_id = fnd_global.conc_request_id;


      CURSOR c_personal_expense_pc --cursor added for P-Card implementation
      IS
         SELECT
                SUM (journal_line_amount) pers_sum
           FROM XX_CONCUR_SAE_TBL
          WHERE UPPER (payment_type_code) = 'CBCP'
            AND UPPER (personal_expense) = 'Y'
            AND request_id = fnd_global.conc_request_id
            and report_policy_name <> 'US Expense Policy'
            AND journal_debit_or_credit = 'DR';

      --GROUP BY report_entry_transaction_date;
      CURSOR c_personal_expense
      IS
         SELECT               --report_entry_transaction_date accounting_date,
                SUM (journal_line_amount) pers_sum
           FROM XX_CONCUR_SAE_TBL
          WHERE UPPER (payment_type_code) ='CBCP'
            AND UPPER (personal_expense) = 'Y'
            AND request_id = fnd_global.conc_request_id
            and report_policy_name = 'US Expense Policy'--added for P-Card implementation
            AND journal_debit_or_credit = 'DR';

      --GROUP BY report_entry_transaction_date;--
      CURSOR c_oop_expense
      IS
         SELECT               --report_entry_transaction_date accounting_date,
                SUM (journal_line_amount) cash_exp
           FROM XX_CONCUR_SAE_TBL
          WHERE UPPER (payment_type_code) ='CASH'
            AND UPPER (employee_group_id) = 'US'
            AND UPPER (personal_expense) = 'N'
            AND journal_debit_or_credit = 'DR'
            AND request_id = fnd_global.conc_request_id;

       --GROUP BY report_entry_transaction_date;--
      CURSOR c_oop_expense1 -- Added for Ticket#5621
      IS
         SELECT               --report_entry_transaction_date accounting_date,
                (SUM (journal_line_amount)*-1) cash_exp
           FROM XX_CONCUR_SAE_TBL
          WHERE UPPER (payment_type_code) ='CASH'
            AND UPPER (employee_group_id) = 'US'
            AND UPPER (personal_expense) = 'N'
            AND journal_debit_or_credit = 'CR'
            AND request_id = fnd_global.conc_request_id;

      --GROUP BY report_entry_transaction_date;
      CURSOR c_oop_nonexpense
      IS
         SELECT               --report_entry_transaction_date accounting_date,
                SUM (journal_line_amount) cash_nexp
           FROM XX_CONCUR_SAE_TBL
          WHERE UPPER (payment_type_code) ='CASH'
            AND UPPER (employee_group_id) != 'US'
            AND UPPER (personal_expense) = 'N'
            AND journal_debit_or_credit = 'DR'
            AND request_id = fnd_global.conc_request_id;

      CURSOR c_oop_nonexpense1 -- Added for Ticket#5621
      IS
         SELECT               --report_entry_transaction_date accounting_date,
                (SUM (journal_line_amount)*-1) cash_nexp
           FROM XX_CONCUR_SAE_TBL
          WHERE UPPER (payment_type_code) ='CASH'
            AND UPPER (employee_group_id) != 'US'
            AND UPPER (personal_expense) = 'N'
            AND journal_debit_or_credit = 'CR'
            AND request_id = fnd_global.conc_request_id;
   --GROUP BY report_entry_transaction_date;
   BEGIN
      xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'LEDGER_NAME',
                                       x_param_value       => v_ledger_name
                                      );
      xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'SOURCE_NAME',
                                        x_param_value       => g_je_source_name
                                       );
      xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CATEGORY_NAME',
                                        x_param_value       => v_category_name
                                       );
       --Modified for ticket 5204 Start
      /*xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'JOURNAL_NAME',
                                        x_param_value       => v_journal_name
                                       );
      v_journal_name :=
               v_journal_name || '_' || TO_CHAR (SYSDATE, 'RRRRMMDD_HH24MMSS');*/
      v_journal_name := g_journal_name;
      --Modified for ticket 5204 End
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Source Name: ' || g_je_source_name
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Category Name: ' || v_category_name
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Journal Name: ' || v_journal_name
                           );

      BEGIN
         SELECT ledger_id
           INTO g_ledger_id
           FROM gl_ledgers
          WHERE NAME = v_ledger_name;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Ledger Name: ' || v_ledger_name
                              );
      EXCEPTION
         WHEN OTHERS
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf := 'Error Getting Ledger Name:' || SQLERRM;
            Rollback;
      END;

      /*BEGIN
         SELECT SUM(journal_line_amount)
           INTO v_sum_off_card
           FROM xx_concur_sae_tbl
          WHERE UPPER (payment_type_code) = 'CARD'
            AND UPPER (employee_group_id) = 'ILSUS'
            AND UPPER (personal_expense) = 'N'
            AND request_id = fnd_global.conc_request_id;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'v_sum_off_card: ' || v_sum_off_card
                              );
      EXCEPTION
         WHEN OTHERS
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf := 'Error Getting v_sum_off_card:' || SQLERRM;
            Rollback;
      END;*/
      v_accounting_date := NULL;
      g_notavbl_flag := 'N';
      fnd_file.put_line
         (fnd_file.output,
          '-----------------------------------------------------------------------------'
         );
      fnd_file.put_line (fnd_file.output, 'BOA Visa Record');

      FOR v_card_expense IN c_card_expense
      LOOP
         v_sum_off_card := v_card_expense.sum_off_card;
         v_accounting_date := SYSDATE;
         g_int_total_c := g_int_total_c + NVL(v_sum_off_card,0);

         IF g_ret_code = xx_emf_cn_pkg.cn_success AND v_sum_off_card > 0
         THEN
            xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'CARD_SEGMENT1',
                                       x_param_value       => v_off_card_segment1
                                      );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT2',
                                        x_param_value       => v_off_card_segment2
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT3',
                                        x_param_value       => v_off_card_segment3
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT4',
                                        x_param_value       => v_off_card_segment4
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT5',
                                        x_param_value       => v_off_card_segment5
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT6',
                                        x_param_value       => v_off_card_segment6
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT7',
                                        x_param_value       => v_off_card_segment7
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT8',
                                        x_param_value       => v_off_card_segment8
                                       );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Credit String for Credit card expense: '
                                  || v_off_card_segment1
                                  || '.'
                                  || v_off_card_segment2
                                  || '.'
                                  || v_off_card_segment3
                                  || '.'
                                  || v_off_card_segment4
                                  || '.'
                                  || v_off_card_segment5
                                  || '.'
                                  || v_off_card_segment6
                                  || '.'
                                  || v_off_card_segment7
                                  || '.'
                                  || v_off_card_segment8
                                 );
            v_line_description :=
                  TO_CHAR (SYSDATE, 'RRRRMMDD')
               || '-'
               || v_off_card_segment1
               || '.'
               || v_off_card_segment2
               || '.'
               || v_off_card_segment3
               || '.'
               || v_off_card_segment4
               || '.'
               || v_off_card_segment5
               || '.'
               || v_off_card_segment6
               || '.'
               || v_off_card_segment7
               || '.'
               || v_off_card_segment8;

            INSERT INTO gl_interface
                        (status, accounting_date, currency_code,
                         date_created, actual_flag, user_je_category_name,
                         user_je_source_name, segment1,
                         segment2, segment3,
                         segment4, segment5,
                         segment6, segment7,
                         segment8, created_by, entered_dr,
                         entered_cr, ledger_id, reference4,
                         reference10, GROUP_ID
                        )
                 VALUES ('New', SYSDATE, 'USD',
                         SYSDATE, 'A', v_category_name,
                         g_je_source_name, v_off_card_segment1,
                         v_off_card_segment2, v_off_card_segment3,
                         v_off_card_segment4, v_off_card_segment5,
                         v_off_card_segment6, v_off_card_segment7,
                         v_off_card_segment8, fnd_global.user_id, NULL,
                         V_SUM_OFF_CARD, G_LEDGER_ID, V_JOURNAL_NAME,
                         'BOA Visa T and E Transaction.', G_BATCH_ID
                        );

            g_string :=
                  v_off_card_segment1
               || '.'
               || v_off_card_segment2
               || '.'
               || v_off_card_segment3
               || '.'
               || v_off_card_segment4
               || '.'
               || v_off_card_segment5
               || '.'
               || v_off_card_segment6
               || '.'
               || v_off_card_segment7
               || '.'
               || v_off_card_segment8;
            fnd_file.put_line (fnd_file.output,
                                  g_string
                               || '     '
                               || 'Cr'
                               || '     '
                               || TO_CHAR (SYSDATE, 'DD-MON-RRRR')
                               || '     '
                               || v_sum_off_card
                              );
            fnd_file.put_line (fnd_file.output, '');
            g_notavbl_flag := 'Y';
         END IF;
      END LOOP;

      IF g_notavbl_flag = 'N'
      THEN
         fnd_file.put_line (fnd_file.output, 'N/A');
      END IF;
      v_accounting_date := NULL;
      g_notavbl_flag := 'N';
      g_string := NULL;

      fnd_file.put_line
         (fnd_file.output,
          '-----------------------------------------------------------------------------'
         );
      fnd_file.put_line (fnd_file.output, 'BOA Visa Record(P-Card)');

      FOR v_card_expense_pc IN c_card_expense_pc
      LOOP
         v_sum_off_card := v_card_expense_pc.sum_off_card;
         v_accounting_date := SYSDATE;
         g_int_total_c := g_int_total_c + NVL(v_sum_off_card,0);

         IF g_ret_code = xx_emf_cn_pkg.cn_success AND v_sum_off_card > 0
         THEN
            xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'CARD_SEGMENT1_PC',
                                       x_param_value       => v_off_card_segment1
                                      );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT2_PC',
                                        x_param_value       => v_off_card_segment2
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT3_PC',
                                        x_param_value       => v_off_card_segment3
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT4_PC',
                                        x_param_value       => v_off_card_segment4
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT5_PC',
                                        x_param_value       => v_off_card_segment5
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT6_PC',
                                        x_param_value       => v_off_card_segment6
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT7_PC',
                                        x_param_value       => v_off_card_segment7
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT8_PC',
                                        x_param_value       => v_off_card_segment8
                                       );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Credit String for Credit card expense(P-Card): '
                                  || v_off_card_segment1
                                  || '.'
                                  || v_off_card_segment2
                                  || '.'
                                  || v_off_card_segment3
                                  || '.'
                                  || v_off_card_segment4
                                  || '.'
                                  || v_off_card_segment5
                                  || '.'
                                  || v_off_card_segment6
                                  || '.'
                                  || v_off_card_segment7
                                  || '.'
                                  || v_off_card_segment8
                                 );
            v_line_description :=
                  TO_CHAR (SYSDATE, 'RRRRMMDD')
               || '-'
               || v_off_card_segment1
               || '.'
               || v_off_card_segment2
               || '.'
               || v_off_card_segment3
               || '.'
               || v_off_card_segment4
               || '.'
               || v_off_card_segment5
               || '.'
               || v_off_card_segment6
               || '.'
               || v_off_card_segment7
               || '.'
               || v_off_card_segment8;

            INSERT INTO gl_interface
                        (status, accounting_date, currency_code,
                         date_created, actual_flag, user_je_category_name,
                         user_je_source_name, segment1,
                         segment2, segment3,
                         segment4, segment5,
                         segment6, segment7,
                         segment8, created_by, entered_dr,
                         entered_cr, ledger_id, reference4,
                         reference10, GROUP_ID
                        )
                 VALUES ('New', SYSDATE, 'USD',
                         SYSDATE, 'A', 'Other',--Added for Ticket#5831
                         'Concur GL', v_off_card_segment1,
                         v_off_card_segment2, v_off_card_segment3,
                         v_off_card_segment4, v_off_card_segment5,
                         v_off_card_segment6, v_off_card_segment7,
                         v_off_card_segment8, fnd_global.user_id, NULL,
                         v_sum_off_card, g_ledger_id, v_journal_name,
                         'BOA Visa Pcard Transaction(P-Card).', g_batch_id
                        );

            g_string :=
                  v_off_card_segment1
               || '.'
               || v_off_card_segment2
               || '.'
               || v_off_card_segment3
               || '.'
               || v_off_card_segment4
               || '.'
               || v_off_card_segment5
               || '.'
               || v_off_card_segment6
               || '.'
               || v_off_card_segment7
               || '.'
               || v_off_card_segment8;
            fnd_file.put_line (fnd_file.output,
                                  g_string
                               || '     '
                               || 'Cr'
                               || '     '
                               || TO_CHAR (SYSDATE, 'DD-MON-RRRR')
                               || '     '
                               || v_sum_off_card
                              );
            fnd_file.put_line (fnd_file.output, '');
            g_notavbl_flag := 'Y';
         END IF;
      END LOOP;

       IF g_notavbl_flag = 'N'
      THEN
         fnd_file.put_line (fnd_file.output, 'N/A');
      END IF;
      v_accounting_date := NULL;
      g_notavbl_flag := 'N';
      g_string := NULL;

      fnd_file.put_line (fnd_file.output,
          '-----------------------------------------------------------------------------'
         );
      fnd_file.put_line (fnd_file.output, 'BOA Visa T and E Transaction Liability Debit Reversal(P-Card)');
      -- Added for Ticket#5621 Start
       FOR v_card_expense1_pc IN c_card_expense1_pc
      LOOP
         v_sum_off_card := v_card_expense1_pc.sum_off_card;
         v_accounting_date := SYSDATE;
         g_int_total_d := g_int_total_d + NVL(v_sum_off_card,0);
         IF g_ret_code = xx_emf_cn_pkg.cn_success AND v_sum_off_card > 0
         THEN
            xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'CARD_SEGMENT1_PCL',
                                       x_param_value       => v_off_card_segment1
                                      );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT2_PCL',
                                        x_param_value       => v_off_card_segment2
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT3_PCL',
                                        x_param_value       => v_off_card_segment3
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT4_PCL',
                                        x_param_value       => v_off_card_segment4
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT5_PCL',
                                        x_param_value       => v_off_card_segment5
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT6_PCL',
                                        x_param_value       => v_off_card_segment6
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT7_PCL',
                                        x_param_value       => v_off_card_segment7
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT8_PCL',
                                        x_param_value       => v_off_card_segment8
                                       );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Debit String for Credit card expense(P-Card): '
                                  || v_off_card_segment1
                                  || '.'
                                  || v_off_card_segment2
                                  || '.'
                                  || v_off_card_segment3
                                  || '.'
                                  || v_off_card_segment4
                                  || '.'
                                  || v_off_card_segment5
                                  || '.'
                                  || v_off_card_segment6
                                  || '.'
                                  || v_off_card_segment7
                                  || '.'
                                  || v_off_card_segment8
                                 );
            v_line_description :=
                  TO_CHAR (SYSDATE, 'RRRRMMDD')
               || '-'
               || v_off_card_segment1
               || '.'
               || v_off_card_segment2
               || '.'
               || v_off_card_segment3
               || '.'
               || v_off_card_segment4
               || '.'
               || v_off_card_segment5
               || '.'
               || v_off_card_segment6
               || '.'
               || v_off_card_segment7
               || '.'
               || v_off_card_segment8;

            INSERT INTO gl_interface
                        (status, accounting_date, currency_code,
                         date_created, actual_flag, user_je_category_name,
                         user_je_source_name, segment1,
                         segment2, segment3,
                         segment4, segment5,
                         segment6, segment7,
                         segment8, created_by, entered_dr,
                         entered_cr, ledger_id, reference4,
                         reference10, GROUP_ID
                        )
                 VALUES ('New', SYSDATE, 'USD',
                         SYSDATE, 'A', 'Other', -- Added for Ticket#5831
                         'Concur GL', v_off_card_segment1,
                         v_off_card_segment2, v_off_card_segment3,
                         v_off_card_segment4, v_off_card_segment5,
                         v_off_card_segment6, v_off_card_segment7,
                         v_off_card_segment8, fnd_global.user_id, v_sum_off_card,
                         NULL, G_LEDGER_ID, V_JOURNAL_NAME,
                         'BOA Visa T Transaction Liability Debit Reversal(P-Card).', g_batch_id
                        );

            g_string :=
                  v_off_card_segment1
               || '.'
               || v_off_card_segment2
               || '.'
               || v_off_card_segment3
               || '.'
               || v_off_card_segment4
               || '.'
               || v_off_card_segment5
               || '.'
               || v_off_card_segment6
               || '.'
               || v_off_card_segment7
               || '.'
               || v_off_card_segment8;
            fnd_file.put_line (fnd_file.output,
                                  g_string
                               || '     '
                               || 'Dr'
                               || '     '
                               || TO_CHAR (SYSDATE, 'DD-MON-RRRR')
                               || '     '
                               || v_sum_off_card
                              );
            fnd_file.put_line (fnd_file.output, '');
            g_notavbl_flag := 'Y';
         END IF;
      END LOOP;

       IF g_notavbl_flag = 'N'
      THEN
         fnd_file.put_line (fnd_file.output, 'N/A');
      END IF;
      v_accounting_date := NULL;
      g_notavbl_flag := 'N';
      g_string := NULL;


      fnd_file.put_line (fnd_file.output,
          '-----------------------------------------------------------------------------'
         );
      fnd_file.put_line (fnd_file.output, 'BOA Visa T and E Transaction Liability Debit Reversal');
      -- Added for Ticket#5621 Start
       FOR v_card_expense1 IN c_card_expense1
      LOOP
         v_sum_off_card := v_card_expense1.sum_off_card;
         v_accounting_date := SYSDATE;
         g_int_total_d := g_int_total_d + NVL(v_sum_off_card,0);
         IF g_ret_code = xx_emf_cn_pkg.cn_success AND v_sum_off_card > 0
         THEN
            xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'CARD_SEGMENT1',
                                       x_param_value       => v_off_card_segment1
                                      );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT2',
                                        x_param_value       => v_off_card_segment2
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT3',
                                        x_param_value       => v_off_card_segment3
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT4',
                                        x_param_value       => v_off_card_segment4
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT5',
                                        x_param_value       => v_off_card_segment5
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT6',
                                        x_param_value       => v_off_card_segment6
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT7',
                                        x_param_value       => v_off_card_segment7
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'CARD_SEGMENT8',
                                        x_param_value       => v_off_card_segment8
                                       );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Debit String for Credit card expense: '
                                  || v_off_card_segment1
                                  || '.'
                                  || v_off_card_segment2
                                  || '.'
                                  || v_off_card_segment3
                                  || '.'
                                  || v_off_card_segment4
                                  || '.'
                                  || v_off_card_segment5
                                  || '.'
                                  || v_off_card_segment6
                                  || '.'
                                  || v_off_card_segment7
                                  || '.'
                                  || v_off_card_segment8
                                 );
            v_line_description :=
                  TO_CHAR (SYSDATE, 'RRRRMMDD')
               || '-'
               || v_off_card_segment1
               || '.'
               || v_off_card_segment2
               || '.'
               || v_off_card_segment3
               || '.'
               || v_off_card_segment4
               || '.'
               || v_off_card_segment5
               || '.'
               || v_off_card_segment6
               || '.'
               || v_off_card_segment7
               || '.'
               || v_off_card_segment8;

            INSERT INTO gl_interface
                        (status, accounting_date, currency_code,
                         date_created, actual_flag, user_je_category_name,
                         user_je_source_name, segment1,
                         segment2, segment3,
                         segment4, segment5,
                         segment6, segment7,
                         segment8, created_by, entered_dr,
                         entered_cr, ledger_id, reference4,
                         reference10, GROUP_ID
                        )
                 VALUES ('New', SYSDATE, 'USD',
                         SYSDATE, 'A', v_category_name,
                         g_je_source_name, v_off_card_segment1,
                         v_off_card_segment2, v_off_card_segment3,
                         v_off_card_segment4, v_off_card_segment5,
                         v_off_card_segment6, v_off_card_segment7,
                         v_off_card_segment8, fnd_global.user_id, v_sum_off_card,
                         NULL, g_ledger_id, v_journal_name,
                         'BOA Visa T Transaction Liability Debit Reversal.', g_batch_id
                        );

            g_string :=
                  v_off_card_segment1
               || '.'
               || v_off_card_segment2
               || '.'
               || v_off_card_segment3
               || '.'
               || v_off_card_segment4
               || '.'
               || v_off_card_segment5
               || '.'
               || v_off_card_segment6
               || '.'
               || v_off_card_segment7
               || '.'
               || v_off_card_segment8;
            fnd_file.put_line (fnd_file.output,
                                  g_string
                               || '     '
                               || 'Dr'
                               || '     '
                               || TO_CHAR (SYSDATE, 'DD-MON-RRRR')
                               || '     '
                               || v_sum_off_card
                              );
            fnd_file.put_line (fnd_file.output, '');
            g_notavbl_flag := 'Y';
         END IF;
      END LOOP;

      IF g_notavbl_flag = 'N'
      THEN
         fnd_file.put_line (fnd_file.output, 'N/A');
      END IF;
-- Added for Ticket#5621 End
      /*BEGIN
         SELECT SUM(journal_line_amount)
           INTO v_pers_sum
           FROM xx_concur_sae_tbl
          WHERE UPPER (payment_type_code) = 'CARD'
            AND UPPER (personal_expense) = 'Y'
            AND request_id = fnd_global.conc_request_id;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'v_pers_sum: ' || v_pers_sum
                              );
      EXCEPTION
         WHEN OTHERS
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf := 'Error Getting v_pers_sum:' || SQLERRM;
            Rollback;
      END;*/
      fnd_file.put_line
         (fnd_file.output,
          '-----------------------------------------------------------------------------'
         );
      fnd_file.put_line (fnd_file.output,
                         'Personal Expense Debit/Credit Record'
                        );
      v_accounting_date := NULL;
      g_string := NULL;
      g_notavbl_flag := 'N';

      FOR v_personal_expense IN c_personal_expense
      LOOP
         v_pers_sum := v_personal_expense.pers_sum;
         v_accounting_date := SYSDATE;
         g_int_total_d := g_int_total_d + NVL(v_pers_sum,0);
         g_int_total_c := g_int_total_c + NVL(v_pers_sum,0);
         IF g_ret_code = xx_emf_cn_pkg.cn_success AND v_pers_sum > 0
         THEN
            xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'PDB_SEGMENT1',
                                       x_param_value       => v_db_pers_segment1
                                      );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PDB_SEGMENT2',
                                        x_param_value       => v_db_pers_segment2
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PDB_SEGMENT3',
                                        x_param_value       => v_db_pers_segment3
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PDB_SEGMENT4',
                                        x_param_value       => v_db_pers_segment4
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PDB_SEGMENT5',
                                        x_param_value       => v_db_pers_segment5
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PDB_SEGMENT6',
                                        x_param_value       => v_db_pers_segment6
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PDB_SEGMENT7',
                                        x_param_value       => v_db_pers_segment7
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PDB_SEGMENT8',
                                        x_param_value       => v_db_pers_segment8
                                       );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Debit String for Personal expense: '
                                  || v_db_pers_segment1
                                  || '.'
                                  || v_db_pers_segment2
                                  || '.'
                                  || v_db_pers_segment3
                                  || '.'
                                  || v_db_pers_segment4
                                  || '.'
                                  || v_db_pers_segment5
                                  || '.'
                                  || v_db_pers_segment6
                                  || '.'
                                  || v_db_pers_segment7
                                  || '.'
                                  || v_db_pers_segment8
                                 );
            v_line_description :=
                  TO_CHAR (SYSDATE, 'RRRRMMDD')
               || '-'
               || v_db_pers_segment1
               || '.'
               || v_db_pers_segment2
               || '.'
               || v_db_pers_segment3
               || '.'
               || v_db_pers_segment4
               || '.'
               || v_db_pers_segment5
               || '.'
               || v_db_pers_segment6
               || '.'
               || v_db_pers_segment7
               || '.'
               || v_db_pers_segment8;

            INSERT INTO gl_interface
                        (status, accounting_date, currency_code,
                         date_created, actual_flag, user_je_category_name,
                         user_je_source_name, segment1,
                         segment2, segment3,
                         segment4, segment5,
                         segment6, segment7,
                         segment8, created_by, entered_dr,
                         entered_cr, ledger_id, reference4,
                         reference10, GROUP_ID
                        )
                 VALUES ('New', v_accounting_date, 'USD',
                         SYSDATE, 'A', v_category_name,
                         g_je_source_name, v_db_pers_segment1,
                         v_db_pers_segment2, v_db_pers_segment3,
                         v_db_pers_segment4, v_db_pers_segment5,
                         v_db_pers_segment6, v_db_pers_segment7,
                         v_db_pers_segment8, fnd_global.user_id, v_pers_sum,
                         NULL, g_ledger_id, v_journal_name,
                         'Personal Expense Transaction.', g_batch_id
                        );

            g_string :=
                  v_db_pers_segment1
               || '.'
               || v_db_pers_segment2
               || '.'
               || v_db_pers_segment3
               || '.'
               || v_db_pers_segment4
               || '.'
               || v_db_pers_segment5
               || '.'
               || v_db_pers_segment6
               || '.'
               || v_db_pers_segment7
               || '.'
               || v_db_pers_segment8;
            fnd_file.put_line (fnd_file.output,
                                  g_string
                               || '     '
                               || 'Dr'
                               || '     '
                               || TO_CHAR (v_accounting_date, 'DD-MON-RRRR')
                               || '     '
                               || v_pers_sum
                              );
            fnd_file.put_line (fnd_file.output, '');
            g_string := NULL;
         END IF;

         IF g_ret_code = xx_emf_cn_pkg.cn_success AND v_pers_sum > 0
         THEN
            xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'PCR_SEGMENT1',
                                       x_param_value       => v_cr_pers_segment1
                                      );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PCR_SEGMENT2',
                                        x_param_value       => v_cr_pers_segment2
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PCR_SEGMENT3',
                                        x_param_value       => v_cr_pers_segment3
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PCR_SEGMENT4',
                                        x_param_value       => v_cr_pers_segment4
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PCR_SEGMENT5',
                                        x_param_value       => v_cr_pers_segment5
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PCR_SEGMENT6',
                                        x_param_value       => v_cr_pers_segment6
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PCR_SEGMENT7',
                                        x_param_value       => v_cr_pers_segment7
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PCR_SEGMENT8',
                                        x_param_value       => v_cr_pers_segment8
                                       );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Credit String for Personal expense: '
                                  || v_cr_pers_segment1
                                  || '.'
                                  || v_cr_pers_segment2
                                  || '.'
                                  || v_cr_pers_segment3
                                  || '.'
                                  || v_cr_pers_segment4
                                  || '.'
                                  || v_cr_pers_segment5
                                  || '.'
                                  || v_cr_pers_segment6
                                  || '.'
                                  || v_cr_pers_segment7
                                  || '.'
                                  || v_cr_pers_segment8
                                 );
            v_line_description :=
                  TO_CHAR (SYSDATE, 'RRRRMMDD')
               || '-'
               || v_cr_pers_segment1
               || '.'
               || v_cr_pers_segment2
               || '.'
               || v_cr_pers_segment3
               || '.'
               || v_cr_pers_segment4
               || '.'
               || v_cr_pers_segment5
               || '.'
               || v_cr_pers_segment6
               || '.'
               || v_cr_pers_segment7
               || '.'
               || v_cr_pers_segment8;

            INSERT INTO gl_interface
                        (status, accounting_date, currency_code,
                         date_created, actual_flag, user_je_category_name,
                         user_je_source_name, segment1,
                         segment2, segment3,
                         segment4, segment5,
                         segment6, segment7,
                         segment8, created_by, entered_dr,
                         entered_cr, ledger_id, reference4,
                         reference10, GROUP_ID
                        )
                 VALUES ('New', v_accounting_date, 'USD',
                         SYSDATE, 'A', v_category_name,
                         g_je_source_name, v_cr_pers_segment1,
                         v_cr_pers_segment2, v_cr_pers_segment3,
                         v_cr_pers_segment4, v_cr_pers_segment5,
                         v_cr_pers_segment6, v_cr_pers_segment7,
                         v_cr_pers_segment8, fnd_global.user_id, NULL,
                         v_pers_sum, g_ledger_id, v_journal_name,
                         'Personal Expense Transaction.', g_batch_id
                        );

            g_string :=
                  v_cr_pers_segment1
               || '.'
               || v_cr_pers_segment2
               || '.'
               || v_cr_pers_segment3
               || '.'
               || v_cr_pers_segment4
               || '.'
               || v_cr_pers_segment5
               || '.'
               || v_cr_pers_segment6
               || '.'
               || v_cr_pers_segment7
               || '.'
               || v_cr_pers_segment8;
            fnd_file.put_line (fnd_file.output,
                                  g_string
                               || '     '
                               || 'Cr'
                               || '     '
                               || TO_CHAR (v_accounting_date, 'DD-MON-RRRR')
                               || '     '
                               || v_pers_sum
                              );
            fnd_file.put_line (fnd_file.output, '');
            g_notavbl_flag := 'Y';
         END IF;
      END LOOP;

      IF g_notavbl_flag = 'N'
      THEN
         fnd_file.put_line (fnd_file.output, 'N/A');
      END IF;

      fnd_file.put_line
         (fnd_file.output,
          '-----------------------------------------------------------------------------'
         );
      fnd_file.put_line (fnd_file.output,
                         'Personal Expense Debit/Credit Record (P-Card)'
                        );
      v_accounting_date := NULL;
      g_string := NULL;
      g_notavbl_flag := 'N';

      FOR v_personal_expense IN c_personal_expense_pc
      LOOP
         v_pers_sum := v_personal_expense.pers_sum;
         v_accounting_date := SYSDATE;
         g_int_total_d := g_int_total_d + NVL(v_pers_sum,0);
         g_int_total_c := g_int_total_c + NVL(v_pers_sum,0);
         IF g_ret_code = xx_emf_cn_pkg.cn_success AND v_pers_sum > 0
         THEN
            xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'PDB_SEGMENT1_PC',
                                       x_param_value       => v_db_pers_segment1
                                      );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PDB_SEGMENT2_PC',
                                        x_param_value       => v_db_pers_segment2
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PDB_SEGMENT3_PC',
                                        x_param_value       => v_db_pers_segment3
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PDB_SEGMENT4_PC',
                                        x_param_value       => v_db_pers_segment4
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PDB_SEGMENT5_PC',
                                        x_param_value       => v_db_pers_segment5
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PDB_SEGMENT6_PC',
                                        x_param_value       => v_db_pers_segment6
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PDB_SEGMENT7_PC',
                                        x_param_value       => v_db_pers_segment7
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PDB_SEGMENT8_PC',
                                        x_param_value       => v_db_pers_segment8
                                       );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Debit String for Personal expense(P-Card): '
                                  || v_db_pers_segment1
                                  || '.'
                                  || v_db_pers_segment2
                                  || '.'
                                  || v_db_pers_segment3
                                  || '.'
                                  || v_db_pers_segment4
                                  || '.'
                                  || v_db_pers_segment5
                                  || '.'
                                  || v_db_pers_segment6
                                  || '.'
                                  || v_db_pers_segment7
                                  || '.'
                                  || v_db_pers_segment8
                                 );
            v_line_description :=
                  TO_CHAR (SYSDATE, 'RRRRMMDD')
               || '-'
               || v_db_pers_segment1
               || '.'
               || v_db_pers_segment2
               || '.'
               || v_db_pers_segment3
               || '.'
               || v_db_pers_segment4
               || '.'
               || v_db_pers_segment5
               || '.'
               || v_db_pers_segment6
               || '.'
               || v_db_pers_segment7
               || '.'
               || v_db_pers_segment8;

            INSERT INTO gl_interface
                        (status, accounting_date, currency_code,
                         date_created, actual_flag, user_je_category_name,
                         user_je_source_name, segment1,
                         segment2, segment3,
                         segment4, segment5,
                         segment6, segment7,
                         segment8, created_by, entered_dr,
                         entered_cr, ledger_id, reference4,
                         reference10, GROUP_ID
                        )
                 VALUES ('New', V_ACCOUNTING_DATE, 'USD',
                         SYSDATE, 'A', 'Other', --Added for Ticket#5831
                         'Concur GL', v_db_pers_segment1,
                         v_db_pers_segment2, v_db_pers_segment3,
                         v_db_pers_segment4, v_db_pers_segment5,
                         v_db_pers_segment6, v_db_pers_segment7,
                         v_db_pers_segment8, fnd_global.user_id, v_pers_sum,
                         NULL, g_ledger_id, v_journal_name,
                         'Personal Expense Transaction(P-Card).', g_batch_id
                        );

            g_string :=
                  v_db_pers_segment1
               || '.'
               || v_db_pers_segment2
               || '.'
               || v_db_pers_segment3
               || '.'
               || v_db_pers_segment4
               || '.'
               || v_db_pers_segment5
               || '.'
               || v_db_pers_segment6
               || '.'
               || v_db_pers_segment7
               || '.'
               || v_db_pers_segment8;
            fnd_file.put_line (fnd_file.output,
                                  g_string
                               || '     '
                               || 'Dr'
                               || '     '
                               || TO_CHAR (v_accounting_date, 'DD-MON-RRRR')
                               || '     '
                               || v_pers_sum
                              );
            fnd_file.put_line (fnd_file.output, '');
            g_string := NULL;
         END IF;

         IF g_ret_code = xx_emf_cn_pkg.cn_success AND v_pers_sum > 0
         THEN
            xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'PCR_SEGMENT1_PC',
                                       x_param_value       => v_cr_pers_segment1
                                      );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PCR_SEGMENT2_PC',
                                        x_param_value       => v_cr_pers_segment2
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PCR_SEGMENT3_PC',
                                        x_param_value       => v_cr_pers_segment3
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PCR_SEGMENT4_PC',
                                        x_param_value       => v_cr_pers_segment4
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PCR_SEGMENT5_PC',
                                        x_param_value       => v_cr_pers_segment5
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PCR_SEGMENT6_PC',
                                        x_param_value       => v_cr_pers_segment6
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PCR_SEGMENT7_PC',
                                        x_param_value       => v_cr_pers_segment7
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'PCR_SEGMENT8_PC',
                                        x_param_value       => v_cr_pers_segment8
                                       );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Credit String for Personal expense (P-card): '
                                  || v_cr_pers_segment1
                                  || '.'
                                  || v_cr_pers_segment2
                                  || '.'
                                  || v_cr_pers_segment3
                                  || '.'
                                  || v_cr_pers_segment4
                                  || '.'
                                  || v_cr_pers_segment5
                                  || '.'
                                  || v_cr_pers_segment6
                                  || '.'
                                  || v_cr_pers_segment7
                                  || '.'
                                  || v_cr_pers_segment8
                                 );
            v_line_description :=
                  TO_CHAR (SYSDATE, 'RRRRMMDD')
               || '-'
               || v_cr_pers_segment1
               || '.'
               || v_cr_pers_segment2
               || '.'
               || v_cr_pers_segment3
               || '.'
               || v_cr_pers_segment4
               || '.'
               || v_cr_pers_segment5
               || '.'
               || v_cr_pers_segment6
               || '.'
               || v_cr_pers_segment7
               || '.'
               || v_cr_pers_segment8;

            INSERT INTO gl_interface
                        (status, accounting_date, currency_code,
                         date_created, actual_flag, user_je_category_name,
                         user_je_source_name, segment1,
                         segment2, segment3,
                         segment4, segment5,
                         segment6, segment7,
                         segment8, created_by, entered_dr,
                         entered_cr, ledger_id, reference4,
                         reference10, GROUP_ID
                        )
                 VALUES ('New', V_ACCOUNTING_DATE, 'USD',
                         SYSDATE, 'A', 'Other',--Added for Ticket#5831
                         'Concur GL', v_cr_pers_segment1,
                         v_cr_pers_segment2, v_cr_pers_segment3,
                         v_cr_pers_segment4, v_cr_pers_segment5,
                         v_cr_pers_segment6, v_cr_pers_segment7,
                         v_cr_pers_segment8, fnd_global.user_id, NULL,
                         v_pers_sum, g_ledger_id, v_journal_name,
                         'Personal Expense Transaction(P-Card).', g_batch_id
                        );

            g_string :=
                  v_cr_pers_segment1
               || '.'
               || v_cr_pers_segment2
               || '.'
               || v_cr_pers_segment3
               || '.'
               || v_cr_pers_segment4
               || '.'
               || v_cr_pers_segment5
               || '.'
               || v_cr_pers_segment6
               || '.'
               || v_cr_pers_segment7
               || '.'
               || v_cr_pers_segment8;
            fnd_file.put_line (fnd_file.output,
                                  g_string
                               || '     '
                               || 'Cr'
                               || '     '
                               || TO_CHAR (v_accounting_date, 'DD-MON-RRRR')
                               || '     '
                               || v_pers_sum
                              );
            fnd_file.put_line (fnd_file.output, '');
            g_notavbl_flag := 'Y';
         END IF;
      END LOOP;

      IF g_notavbl_flag = 'N'
      THEN
         fnd_file.put_line (fnd_file.output, 'N/A');
      END IF;

      /*BEGIN
         SELECT SUM(journal_line_amount)
           INTO v_cash_exp
           FROM xx_concur_sae_tbl
          WHERE UPPER (payment_type_code) = 'CASH'
            AND UPPER (employee_group_id) = 'ILSUS'
            AND UPPER (personal_expense) = 'N'
            AND request_id = fnd_global.conc_request_id;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'v_cash_exp: ' || v_cash_exp
                              );
      EXCEPTION
         WHEN OTHERS
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf := 'Error Getting v_cash_exp:' || SQLERRM;
            Rollback;
      END;*/
      fnd_file.put_line
         (fnd_file.output,
          '-----------------------------------------------------------------------------'
         );
      fnd_file.put_line (fnd_file.output,
                         'Out-of-Pocket Credit Record - Expense Group'
                        );
      v_accounting_date := NULL;
      g_notavbl_flag := 'N';
      g_string := NULL;

      FOR v_oop_expense IN c_oop_expense
      LOOP
         v_cash_exp := v_oop_expense.cash_exp;
         v_accounting_date := SYSDATE;
         g_int_total_c := g_int_total_c + NVL(v_cash_exp,0);
         IF g_ret_code = xx_emf_cn_pkg.cn_success AND v_cash_exp > 0
         THEN
            xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'OOPE_SEGMENT1',
                                       x_param_value       => v_cash_exp_segment1
                                      );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPE_SEGMENT2',
                                        x_param_value       => v_cash_exp_segment2
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPE_SEGMENT3',
                                        x_param_value       => v_cash_exp_segment3
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPE_SEGMENT4',
                                        x_param_value       => v_cash_exp_segment4
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPE_SEGMENT5',
                                        x_param_value       => v_cash_exp_segment5
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPE_SEGMENT6',
                                        x_param_value       => v_cash_exp_segment6
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPE_SEGMENT7',
                                        x_param_value       => v_cash_exp_segment7
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPE_SEGMENT8',
                                        x_param_value       => v_cash_exp_segment8
                                       );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Credit String for OOP Expense Group: '
                                  || v_cash_exp_segment1
                                  || '.'
                                  || v_cash_exp_segment2
                                  || '.'
                                  || v_cash_exp_segment3
                                  || '.'
                                  || v_cash_exp_segment4
                                  || '.'
                                  || v_cash_exp_segment5
                                  || '.'
                                  || v_cash_exp_segment6
                                  || '.'
                                  || v_cash_exp_segment7
                                  || '.'
                                  || v_cash_exp_segment8
                                 );
            v_line_description :=
                  TO_CHAR (SYSDATE, 'RRRRMMDD')
               || '-'
               || v_cash_exp_segment1
               || '.'
               || v_cash_exp_segment2
               || '.'
               || v_cash_exp_segment3
               || '.'
               || v_cash_exp_segment4
               || '.'
               || v_cash_exp_segment5
               || '.'
               || v_cash_exp_segment6
               || '.'
               || v_cash_exp_segment7
               || '.'
               || v_cash_exp_segment8;

            INSERT INTO gl_interface
                        (status, accounting_date, currency_code,
                         date_created, actual_flag, user_je_category_name,
                         user_je_source_name, segment1,
                         segment2, segment3,
                         segment4, segment5,
                         segment6, segment7,
                         segment8, created_by, entered_dr,
                         entered_cr, ledger_id, reference4,
                         reference10, GROUP_ID
                        )
                 VALUES ('New', v_accounting_date, 'USD',
                         SYSDATE, 'A', v_category_name,
                         g_je_source_name, v_cash_exp_segment1,
                         v_cash_exp_segment2, v_cash_exp_segment3,
                         v_cash_exp_segment4, v_cash_exp_segment5,
                         v_cash_exp_segment6, v_cash_exp_segment7,
                         v_cash_exp_segment8, fnd_global.user_id, NULL,
                         v_cash_exp, g_ledger_id, v_journal_name,
                         'Out of Pocket - Expense Pay Group.', g_batch_id
                        );

            g_string :=
                  v_cash_exp_segment1
               || '.'
               || v_cash_exp_segment2
               || '.'
               || v_cash_exp_segment3
               || '.'
               || v_cash_exp_segment4
               || '.'
               || v_cash_exp_segment5
               || '.'
               || v_cash_exp_segment6
               || '.'
               || v_cash_exp_segment7
               || '.'
               || v_cash_exp_segment8;
            fnd_file.put_line (fnd_file.output,
                                  g_string
                               || '     '
                               || 'Cr'
                               || '     '
                               || TO_CHAR (v_accounting_date, 'DD-MON-RRRR')
                               || '     '
                               || v_cash_exp
                              );
            fnd_file.put_line (fnd_file.output, '');
            g_notavbl_flag := 'Y';
         END IF;
      END LOOP;

      IF g_notavbl_flag = 'N'
      THEN
         fnd_file.put_line (fnd_file.output, 'N/A');
      END IF;
      -- Added for Ticket#5621 Start
      fnd_file.put_line
         (fnd_file.output,
          '-----------------------------------------------------------------------------'
         );
      fnd_file.put_line (fnd_file.output,
                         'Out-of-Pocket Liability Debit Reversal - Expense Group'
                        );
      v_accounting_date := NULL;
      g_notavbl_flag := 'N';
      g_string := NULL;

      FOR v_oop_expense1 IN c_oop_expense1
      LOOP
         v_cash_exp := v_oop_expense1.cash_exp;
         v_accounting_date := SYSDATE;
         g_int_total_d := g_int_total_d + NVL(v_cash_exp,0);
         IF g_ret_code = xx_emf_cn_pkg.cn_success AND v_cash_exp > 0
         THEN
            xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'OOPE_SEGMENT1',
                                       x_param_value       => v_cash_exp_segment1
                                      );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPE_SEGMENT2',
                                        x_param_value       => v_cash_exp_segment2
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPE_SEGMENT3',
                                        x_param_value       => v_cash_exp_segment3
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPE_SEGMENT4',
                                        x_param_value       => v_cash_exp_segment4
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPE_SEGMENT5',
                                        x_param_value       => v_cash_exp_segment5
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPE_SEGMENT6',
                                        x_param_value       => v_cash_exp_segment6
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPE_SEGMENT7',
                                        x_param_value       => v_cash_exp_segment7
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPE_SEGMENT8',
                                        x_param_value       => v_cash_exp_segment8
                                       );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Debit String for OOP Expense Group: '
                                  || v_cash_exp_segment1
                                  || '.'
                                  || v_cash_exp_segment2
                                  || '.'
                                  || v_cash_exp_segment3
                                  || '.'
                                  || v_cash_exp_segment4
                                  || '.'
                                  || v_cash_exp_segment5
                                  || '.'
                                  || v_cash_exp_segment6
                                  || '.'
                                  || v_cash_exp_segment7
                                  || '.'
                                  || v_cash_exp_segment8
                                 );
            v_line_description :=
                  TO_CHAR (SYSDATE, 'RRRRMMDD')
               || '-'
               || v_cash_exp_segment1
               || '.'
               || v_cash_exp_segment2
               || '.'
               || v_cash_exp_segment3
               || '.'
               || v_cash_exp_segment4
               || '.'
               || v_cash_exp_segment5
               || '.'
               || v_cash_exp_segment6
               || '.'
               || v_cash_exp_segment7
               || '.'
               || v_cash_exp_segment8;

            INSERT INTO gl_interface
                        (status, accounting_date, currency_code,
                         date_created, actual_flag, user_je_category_name,
                         user_je_source_name, segment1,
                         segment2, segment3,
                         segment4, segment5,
                         segment6, segment7,
                         segment8, created_by, entered_dr,
                         entered_cr, ledger_id, reference4,
                         reference10, GROUP_ID
                        )
                 VALUES ('New', v_accounting_date, 'USD',
                         SYSDATE, 'A', v_category_name,
                         g_je_source_name, v_cash_exp_segment1,
                         v_cash_exp_segment2, v_cash_exp_segment3,
                         v_cash_exp_segment4, v_cash_exp_segment5,
                         v_cash_exp_segment6, v_cash_exp_segment7,
                         v_cash_exp_segment8, fnd_global.user_id, v_cash_exp,
                         NULL, g_ledger_id, v_journal_name,
                         'Out of Pocket - Expense Pay Group Liability Debit Reversal.', g_batch_id
                        );

            g_string :=
                  v_cash_exp_segment1
               || '.'
               || v_cash_exp_segment2
               || '.'
               || v_cash_exp_segment3
               || '.'
               || v_cash_exp_segment4
               || '.'
               || v_cash_exp_segment5
               || '.'
               || v_cash_exp_segment6
               || '.'
               || v_cash_exp_segment7
               || '.'
               || v_cash_exp_segment8;
            fnd_file.put_line (fnd_file.output,
                                  g_string
                               || '     '
                               || 'Dr'
                               || '     '
                               || TO_CHAR (v_accounting_date, 'DD-MON-RRRR')
                               || '     '
                               || v_cash_exp
                              );
            fnd_file.put_line (fnd_file.output, '');
            g_notavbl_flag := 'Y';
         END IF;
      END LOOP;

      IF g_notavbl_flag = 'N'
      THEN
         fnd_file.put_line (fnd_file.output, 'N/A');
      END IF;
-- Added for Ticket#5621 End
      /*BEGIN
         SELECT SUM(journal_line_amount)
           INTO v_cash_nexp
           FROM xx_concur_sae_tbl
          WHERE UPPER (payment_type_code) = 'CASH'
            AND UPPER (employee_group_id) != 'ILSUS'
            AND UPPER (personal_expense) = 'N'
            AND request_id = fnd_global.conc_request_id;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'v_cash_exp: ' || v_cash_exp
                              );
      EXCEPTION
         WHEN OTHERS
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf := 'Error Getting v_cash_exp:' || SQLERRM;
            Rollback;
      END;*/
      fnd_file.put_line
         (fnd_file.output,
          '-----------------------------------------------------------------------------'
         );
      fnd_file.put_line (fnd_file.output,
                         'Out-of-Pocket Credit Record - Non-Expense Group'
                        );
      v_accounting_date := NULL;
      g_string := NULL;
      g_notavbl_flag := 'N';

      FOR v_oop_nonexpense IN c_oop_nonexpense
      LOOP
         v_cash_nexp := v_oop_nonexpense.cash_nexp;
         v_accounting_date := SYSDATE;
         g_int_total_c := g_int_total_c + NVL(v_cash_nexp,0);
         IF g_ret_code = xx_emf_cn_pkg.cn_success AND v_cash_nexp > 0
         THEN
            xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'OOPNE_SEGMENT1',
                                       x_param_value       => v_cash_nexp_segment1
                                      );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPNE_SEGMENT2',
                                        x_param_value       => v_cash_nexp_segment2
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPNE_SEGMENT3',
                                        x_param_value       => v_cash_nexp_segment3
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPNE_SEGMENT4',
                                        x_param_value       => v_cash_nexp_segment4
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPNE_SEGMENT5',
                                        x_param_value       => v_cash_nexp_segment5
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPNE_SEGMENT6',
                                        x_param_value       => v_cash_nexp_segment6
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPNE_SEGMENT7',
                                        x_param_value       => v_cash_nexp_segment7
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPNE_SEGMENT8',
                                        x_param_value       => v_cash_nexp_segment8
                                       );
            xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                   'Credit String for OOP Non-Expense Group: '
                                || v_cash_nexp_segment1
                                || '.'
                                || v_cash_nexp_segment2
                                || '.'
                                || v_cash_nexp_segment3
                                || '.'
                                || v_cash_nexp_segment4
                                || '.'
                                || v_cash_nexp_segment5
                                || '.'
                                || v_cash_nexp_segment6
                                || '.'
                                || v_cash_nexp_segment7
                                || '.'
                                || v_cash_nexp_segment8
                               );
            v_line_description :=
                  TO_CHAR (SYSDATE, 'RRRRMMDD')
               || '-'
               || v_cash_nexp_segment1
               || '.'
               || v_cash_nexp_segment2
               || '.'
               || v_cash_nexp_segment3
               || '.'
               || v_cash_nexp_segment4
               || '.'
               || v_cash_nexp_segment5
               || '.'
               || v_cash_nexp_segment6
               || '.'
               || v_cash_nexp_segment7
               || '.'
               || v_cash_nexp_segment8;

            INSERT INTO gl_interface
                        (status, accounting_date, currency_code,
                         date_created, actual_flag, user_je_category_name,
                         user_je_source_name, segment1,
                         segment2, segment3,
                         segment4, segment5,
                         segment6, segment7,
                         segment8, created_by, entered_dr,
                         entered_cr, ledger_id, reference4,
                         reference10, GROUP_ID
                        )
                 VALUES ('New', v_accounting_date, 'USD',
                         SYSDATE, 'A', v_category_name,
                         g_je_source_name, v_cash_nexp_segment1,
                         v_cash_nexp_segment2, v_cash_nexp_segment3,
                         v_cash_nexp_segment4, v_cash_nexp_segment5,
                         v_cash_nexp_segment6, v_cash_nexp_segment7,
                         v_cash_nexp_segment8, fnd_global.user_id, NULL,
                         v_cash_nexp, g_ledger_id, v_journal_name,
                         'Out of Pocket - Non Expense Pay Group.', g_batch_id
                        );

            g_string :=
                  v_cash_nexp_segment1
               || '.'
               || v_cash_nexp_segment2
               || '.'
               || v_cash_nexp_segment3
               || '.'
               || v_cash_nexp_segment4
               || '.'
               || v_cash_nexp_segment5
               || '.'
               || v_cash_nexp_segment6
               || '.'
               || v_cash_nexp_segment7
               || '.'
               || v_cash_nexp_segment8;
            fnd_file.put_line (fnd_file.output,
                                  g_string
                               || '     '
                               || 'Cr'
                               || '     '
                               || TO_CHAR (v_accounting_date, 'DD-MON-RRRR')
                               || '     '
                               || v_cash_nexp
                              );
            fnd_file.put_line (fnd_file.output, '');
            g_notavbl_flag := 'Y';
         END IF;
      END LOOP;

      IF g_notavbl_flag = 'N'
      THEN
         fnd_file.put_line (fnd_file.output, 'N/A');
      END IF;
      -- Added for Ticket#5621 Start

      fnd_file.put_line
         (fnd_file.output,
          '-----------------------------------------------------------------------------'
         );
      fnd_file.put_line (fnd_file.output,
                         'Out-of-Pocket Liability Debit Reversal - Non-Expense Group'
                        );
      v_accounting_date := NULL;
      g_string := NULL;
      g_notavbl_flag := 'N';

      FOR v_oop_nonexpense1 IN c_oop_nonexpense1
      LOOP
         v_cash_nexp := v_oop_nonexpense1.cash_nexp;
         v_accounting_date := SYSDATE;
         g_int_total_d := g_int_total_d + NVL(v_cash_nexp,0);
         IF g_ret_code = xx_emf_cn_pkg.cn_success AND v_cash_nexp > 0
         THEN
            xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'OOPNE_SEGMENT1',
                                       x_param_value       => v_cash_nexp_segment1
                                      );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPNE_SEGMENT2',
                                        x_param_value       => v_cash_nexp_segment2
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPNE_SEGMENT3',
                                        x_param_value       => v_cash_nexp_segment3
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPNE_SEGMENT4',
                                        x_param_value       => v_cash_nexp_segment4
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPNE_SEGMENT5',
                                        x_param_value       => v_cash_nexp_segment5
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPNE_SEGMENT6',
                                        x_param_value       => v_cash_nexp_segment6
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPNE_SEGMENT7',
                                        x_param_value       => v_cash_nexp_segment7
                                       );
            xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'OOPNE_SEGMENT8',
                                        x_param_value       => v_cash_nexp_segment8
                                       );
            xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                   'Credit String for OOP Non-Expense Group: '
                                || v_cash_nexp_segment1
                                || '.'
                                || v_cash_nexp_segment2
                                || '.'
                                || v_cash_nexp_segment3
                                || '.'
                                || v_cash_nexp_segment4
                                || '.'
                                || v_cash_nexp_segment5
                                || '.'
                                || v_cash_nexp_segment6
                                || '.'
                                || v_cash_nexp_segment7
                                || '.'
                                || v_cash_nexp_segment8
                               );
            v_line_description :=
                  TO_CHAR (SYSDATE, 'RRRRMMDD')
               || '-'
               || v_cash_nexp_segment1
               || '.'
               || v_cash_nexp_segment2
               || '.'
               || v_cash_nexp_segment3
               || '.'
               || v_cash_nexp_segment4
               || '.'
               || v_cash_nexp_segment5
               || '.'
               || v_cash_nexp_segment6
               || '.'
               || v_cash_nexp_segment7
               || '.'
               || v_cash_nexp_segment8;

            INSERT INTO gl_interface
                        (status, accounting_date, currency_code,
                         date_created, actual_flag, user_je_category_name,
                         user_je_source_name, segment1,
                         segment2, segment3,
                         segment4, segment5,
                         segment6, segment7,
                         segment8, created_by, entered_dr,
                         entered_cr, ledger_id, reference4,
                         reference10, GROUP_ID
                        )
                 VALUES ('New', v_accounting_date, 'USD',
                         SYSDATE, 'A', v_category_name,
                         g_je_source_name, v_cash_nexp_segment1,
                         v_cash_nexp_segment2, v_cash_nexp_segment3,
                         v_cash_nexp_segment4, v_cash_nexp_segment5,
                         v_cash_nexp_segment6, v_cash_nexp_segment7,
                         v_cash_nexp_segment8, fnd_global.user_id, v_cash_nexp,
                         NULL, g_ledger_id, v_journal_name,
                         'Out of Pocket - Non Expense Pay Group Liability Debit Reversal.', g_batch_id
                        );

            g_string :=
                  v_cash_nexp_segment1
               || '.'
               || v_cash_nexp_segment2
               || '.'
               || v_cash_nexp_segment3
               || '.'
               || v_cash_nexp_segment4
               || '.'
               || v_cash_nexp_segment5
               || '.'
               || v_cash_nexp_segment6
               || '.'
               || v_cash_nexp_segment7
               || '.'
               || v_cash_nexp_segment8;
            fnd_file.put_line (fnd_file.output,
                                  g_string
                               || '     '
                               || 'Dr'
                               || '     '
                               || TO_CHAR (v_accounting_date, 'DD-MON-RRRR')
                               || '     '
                               || v_cash_nexp
                              );
            fnd_file.put_line (fnd_file.output, '');
            g_notavbl_flag := 'Y';
         END IF;
      END LOOP;

      IF g_notavbl_flag = 'N'
      THEN
         fnd_file.put_line (fnd_file.output, 'N/A');
      END IF;
-- Added for Ticket#5621 End
      fnd_file.put_line
         (fnd_file.output,
          '-----------------------------------------------------------------------------'
         );

          BEGIN
-- Added for Ticket#5621 Start
   SELECT NVL(SUM(a.journal_line_amount),0)
   INTO v_stg_total1
   FROM xx_concur_sae_tbl a
   WHERE A.REQUEST_ID = FND_GLOBAL.CONC_REQUEST_ID
   AND UPPER (payment_type_code) ='CBCP'
   AND UPPER (personal_expense) = 'N'
   AND journal_debit_or_credit = 'DR';

   SELECT NVL((SUM(a.journal_line_amount)*-1),0)
   INTO v_stg_total2
   FROM xx_concur_sae_tbl a
   WHERE A.REQUEST_ID = FND_GLOBAL.CONC_REQUEST_ID
   AND UPPER (payment_type_code) ='CBCP'
--   AND UPPER (personal_expense) = 'N'
   AND UPPER (personal_expense) in('N','Y') -- Added by Prasanna s
   AND journal_debit_or_credit = 'CR';

   SELECT NVL(SUM(a.journal_line_amount),0)
   INTO v_stg_total3
   FROM xx_concur_sae_tbl a
   WHERE A.REQUEST_ID = FND_GLOBAL.CONC_REQUEST_ID
   AND UPPER (payment_type_code) ='CBCP'
   AND UPPER (personal_expense) = 'Y'
   AND journal_debit_or_credit = 'DR';

   SELECT NVL(SUM(journal_line_amount),0)
                INTO v_stg_total4
           FROM XX_CONCUR_SAE_TBL
          WHERE UPPER (payment_type_code) in( 'CASH','IBIP')
            --AND UPPER (employee_group_id) = 'ILSUS'
            AND UPPER (personal_expense) = 'N'
            AND journal_debit_or_credit = 'DR'
            AND request_id = fnd_global.conc_request_id;

   SELECT NVL((SUM(journal_line_amount) *-1),0)
                INTO v_stg_total5
           FROM XX_CONCUR_SAE_TBL
          WHERE UPPER (payment_type_code) in( 'CASH','IBIP')
            --AND UPPER (employee_group_id) = 'ILSUS'
            AND UPPER (personal_expense) = 'N'
            AND journal_debit_or_credit = 'CR'
            AND request_id = fnd_global.conc_request_id;

   g_stg_total := v_stg_total1 + v_stg_total2 +v_stg_total3 + v_stg_total4 + v_stg_total5;
-- Added for Ticket#5621 End
   fnd_file.put_line (fnd_file.output, 'Staging Table Amount:'||g_stg_total);

   SELECT SUM(a.entered_dr)
   INTO g_int_total_dr
   FROM gl_interface a
   WHERE a.group_id = g_batch_id;
   fnd_file.put_line (fnd_file.output, 'Program Debit Amount:'||g_int_total_d);
   fnd_file.put_line (fnd_file.output, 'Interface Debit Amount:'||g_int_total_dr);

   SELECT SUM(a.entered_cr)
   INTO g_int_total_cr
   FROM gl_interface a
   WHERE a.group_id = g_batch_id;
   fnd_file.put_line (fnd_file.output, 'Program Credit Amount:'||g_int_total_c);
   fnd_file.put_line (fnd_file.output, 'Interface Credit Amount:'||g_int_total_cr);

   fnd_file.put_line
         (fnd_file.output,
          '-----------------------------------------------------------------------------'
         );

   IF g_int_total_dr = g_int_total_cr AND g_int_total_d = g_int_total_c  AND g_int_total_cr = g_stg_total
   AND g_int_total_d = g_int_total_dr AND g_int_total_cr = g_int_total_c  THEN -- Modified for Ticket#5621 Start
    xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,'Amount match in Staging/Interface tables.');
   ELSE

   g_ret_code := xx_emf_cn_pkg.cn_prc_err;
   G_ERRBUF   := 'Amount Mismatch in Staging/Interface tables.';
   Rollback;

   END IF;

   END;
   END generate_credit_lines;

   PROCEDURE call_import_program
   IS
      v_interface_run_id   NUMBER;
      v_conc_id            NUMBER;
      v_data_set_id        NUMBER;
      v_req_wait           BOOLEAN;
      v_phase              VARCHAR2 (25);
      v_status             VARCHAR2 (25);
      v_dev_phase          VARCHAR2 (25);
      v_dev_status         VARCHAR2 (25);
      v_message            VARCHAR2 (2000);

   BEGIN

   BEGIN
      SELECT gl_journal_import_s.NEXTVAL
        INTO v_interface_run_id
        FROM DUAL;
   EXCEPTION
         WHEN OTHERS
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf :=
                  'Error Getting Sequence value:'
               || SQLERRM;
            Rollback;
   END;



      BEGIN
         SELECT access_set_id
           INTO v_data_set_id
           FROM gl_access_set_ledgers
          WHERE ledger_id = g_ledger_id AND ROWNUM = 1;
      EXCEPTION
         WHEN OTHERS
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf :=
                  'Error Getting Access Set Details:'
               || g_ledger_id
               || '-'
               || SQLERRM;
            Rollback;
      END;


      IF g_ret_code = xx_emf_cn_pkg.cn_success
      THEN
         gl_journal_import_pkg.populate_interface_control
                                    (user_je_source_name      => g_je_source_name,
                                     GROUP_ID                 => g_batch_id,
                                     set_of_books_id          => g_ledger_id,
                                     interface_run_id         => v_interface_run_id
                                    );
         g_con_req_id :=
            fnd_request.submit_request (application      => 'SQLGL',
                                        program          => 'GLLEZL',
                                        description      => NULL,
                                        start_time       => SYSDATE,
                                        sub_request      => FALSE,
                                        argument1        => v_interface_run_id,
                                        argument2        => v_data_set_id,
                                        argument3        => 'N',
                                        argument4        => NULL,
                                        argument5        => NULL,
                                        argument6        => 'N',
                                        argument7        => 'W',
                                        argument8        => 'Y'
                                       );
      END IF;

      IF g_con_req_id > 0
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'GL Import Request Submission Success.'
                               || g_con_req_id
                              );
         COMMIT;
         g_arch_flag := 'Y';
         v_req_wait :=
            fnd_concurrent.wait_for_request (request_id      => g_con_req_id,
                                             INTERVAL        => 0,
                                             phase           => v_phase,
                                             status          => v_status,
                                             dev_phase       => v_dev_phase,
                                             dev_status      => v_dev_status,
                                             MESSAGE         => v_message
                                            );

         IF v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL'
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'No Interface Errors');
            g_send_email_b := 'C';
         ELSE
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Interface Completed in Error/Warning.'
                                  || g_con_req_id
                                 );
            g_ret_code := xx_emf_cn_pkg.cn_rec_warn;
            g_send_email_b := 'B';
            g_errbuf := 'Interface Completed in Error/Warning';
         END IF;
      ELSE
         g_ret_code := xx_emf_cn_pkg.cn_prc_err;
         g_errbuf := g_errbuf||'GL Import Request Submission failed.';
         g_send_email := 'I';
         Rollback;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         g_ret_code := xx_emf_cn_pkg.cn_prc_err;
         g_errbuf := 'Error in Call_Import_Program:' || SQLERRM;
         Rollback;
   END call_import_program;

   PROCEDURE call_import_program_pc
   IS
      v_interface_run_id   NUMBER;
      v_conc_id            NUMBER;
      v_data_set_id        NUMBER;
      v_req_wait           BOOLEAN;
      v_phase              VARCHAR2 (25);
      v_status             VARCHAR2 (25);
      v_dev_phase          VARCHAR2 (25);
      v_dev_status         VARCHAR2 (25);
      v_message            VARCHAR2 (2000);
      v_stg_total1         NUMBER;
      v_stg_total2         NUMBER;
      v_stg_total3         NUMBER;
      v_stg_total4         NUMBER;
      v_stg_total5         NUMBER;
   BEGIN

   BEGIN
      SELECT gl_journal_import_s.NEXTVAL
        INTO v_interface_run_id
        FROM DUAL;
   EXCEPTION
         WHEN OTHERS
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf :=
                  'Error Getting Sequence value:'
               || SQLERRM;
            Rollback;
   END;

      BEGIN
         SELECT access_set_id
           INTO v_data_set_id
           FROM gl_access_set_ledgers
          WHERE ledger_id = g_ledger_id AND ROWNUM = 1;
      EXCEPTION
         WHEN OTHERS
         THEN
            g_ret_code := xx_emf_cn_pkg.cn_prc_err;
            g_errbuf :=
                  'Error Getting Access Set Details P-CARD:'
               || g_ledger_id
               || '-'
               || SQLERRM;
            Rollback;
      END;


      IF g_ret_code = xx_emf_cn_pkg.cn_success
      THEN
         gl_journal_import_pkg.populate_interface_control
                                    (user_je_source_name      => 'P-CARD',
                                     GROUP_ID                 => g_batch_id,
                                     set_of_books_id          => g_ledger_id,
                                     interface_run_id         => v_interface_run_id
                                    );
         g_con_req_id_pc :=
            fnd_request.submit_request (application      => 'SQLGL',
                                        program          => 'GLLEZL',
                                        description      => NULL,
                                        start_time       => SYSDATE,
                                        sub_request      => FALSE,
                                        argument1        => v_interface_run_id,
                                        argument2        => v_data_set_id,
                                        argument3        => 'N',
                                        argument4        => NULL,
                                        argument5        => NULL,
                                        argument6        => 'N',
                                        argument7        => 'W',
                                        argument8        => 'Y'
                                       );
      END IF;

      IF g_con_req_id_pc > 0
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'GL Import P-CARD Request Submission Success.'
                               || g_con_req_id
                              );
         COMMIT;
         g_arch_flag := 'Y';
         v_req_wait :=
            fnd_concurrent.wait_for_request (request_id      => g_con_req_id_pc,
                                             INTERVAL        => 0,
                                             phase           => v_phase,
                                             status          => v_status,
                                             dev_phase       => v_dev_phase,
                                             dev_status      => v_dev_status,
                                             MESSAGE         => v_message
                                            );

         IF v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL'
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'No Interface Errors');
            g_send_email_b_pc := 'C';
         ELSE
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Interface Completed in Error/Warning.'
                                  || g_con_req_id
                                 );
            g_ret_code := xx_emf_cn_pkg.cn_rec_warn;
            g_send_email_b_pc := 'B';
            g_errbuf := 'Interface Completed in Error/Warning';
         END IF;
      ELSE
         g_ret_code := xx_emf_cn_pkg.cn_prc_err;
         g_errbuf := g_errbuf||'GL Import Request Submission failed.';
         g_send_email_pc := 'I';
         Rollback;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         g_ret_code := xx_emf_cn_pkg.cn_prc_err;
         g_errbuf := 'Error in Call_Import_Program:' || SQLERRM;
         Rollback;
   END call_import_program_pc;

   PROCEDURE update_staging_table
   IS
      v_count   NUMBER := 0;

      CURSOR c_update
      IS
         SELECT DISTINCT segment1, segment2, segment3, segment4, segment5,
                         segment6, segment7, segment8, accounting_date,
                         entered_dr, entered_cr, GROUP_ID, status,
                         status_description
                    FROM gl_interface
                   WHERE request_id = g_con_req_id
                     AND GROUP_ID = g_batch_id
                     AND status <> 'NEW';
   BEGIN
      FOR v_update IN c_update
      LOOP
         v_count := v_count + 1;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Updating Record '
                               || v_count
                               || ' in staging table'
                              );

         UPDATE xx_concur_sae_tbl
            SET process_code = 'Processed',
                ERROR_CODE = v_update.status,
                error_message = v_update.status_description
          WHERE company = v_update.segment1
            AND department = v_update.segment2
            AND ACCOUNT = v_update.segment3
            AND classification = v_update.segment4
            AND product = v_update.segment5
            AND region = v_update.segment6
            AND intercompany = v_update.segment7
            AND future = v_update.segment8
            AND request_id = fnd_global.conc_request_id
            AND batch_id = g_batch_id
            --AND report_entry_transaction_date = v_update.accounting_date
            AND journal_debit_or_credit =
                          DECODE (NVL (v_update.entered_dr, 0),
                                  0, 'CR',
                                  'DR'
                                 );
      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         g_ret_code := xx_emf_cn_pkg.cn_prc_err;
         g_send_email := 'I';
         g_errbuf := 'Error in update_staging_table:' || SQLERRM;
         Rollback;
   END update_staging_table;

   PROCEDURE archive_file
   IS
      v_archive_file   VARCHAR2 (240);
   BEGIN
      xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'ARCH_DIR',
                                       x_param_value       => g_arch_dir
                                      );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Archive Directory:' || g_arch_dir
                           );
      v_archive_file :=
            RTRIM (g_file_name, '.txt')
         || '_'
         || TO_CHAR (SYSDATE, 'RRRRMMDD_HH24MMSS')
         || '.txt';
      UTL_FILE.frename (g_data_dir,
                        g_file_name,
                        g_arch_dir,
                        v_archive_file,
                        FALSE
                       );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Archive File Name:' || v_archive_file
                           );
   EXCEPTION
      WHEN OTHERS
      THEN
         g_ret_code := xx_emf_cn_pkg.cn_prc_err;
         g_errbuf := 'Error in archive_file:' || SQLERRM;
         g_send_email := 'I';
   END archive_file;

   PROCEDURE send_email
   IS
      v_message_i     VARCHAR2 (1000);
      v_message_b     VARCHAR2 (1000);
      v_from_email    VARCHAR2 (60);
      v_to_email_i    VARCHAR2 (1000);
      v_to_email_b    VARCHAR2 (1000);
      v_to_email_b1   VARCHAR2 (1000);
      v_to_email_b2   VARCHAR2 (1000);
      v_to_email_b3   VARCHAR2 (1000);
   BEGIN
      xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'FROM_EMAIL',
                                       x_param_value       => v_from_email
                                      );
      xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'TO_EMAIL_B1',
                                        x_param_value       => v_to_email_b1
                                       );
      xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'TO_EMAIL_B2',
                                        x_param_value       => v_to_email_b2
                                       );
      xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'TO_EMAIL_B3',
                                        x_param_value       => v_to_email_b3
                                       );
      xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'TO_EMAIL_I',
                                        x_param_value       => v_to_email_i
                                       );
      v_to_email_b := v_to_email_b1 || v_to_email_b2 || v_to_email_b3;

      IF g_send_email = 'I' AND g_send_email_b = 'N'
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Sending Mail to IT Support Team.'
                              );
         v_message_i :=
               'Concur SAE Inbound Interface Program Failed with error message: '
            || g_errbuf
            || '. Request Id.'
            || fnd_global.conc_request_id;
         xx_intg_mail_util_pkg.mail
                             (sender          => v_from_email,
                              recipients      => v_to_email_i,
                              subject         => 'Concur SAE Inbound Interface Error',
                              MESSAGE         => v_message_i
                             );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, v_message_i);
      ELSIF g_send_email_b = 'B' AND g_send_email = 'N'
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Sending Mail to Business Team.'
                              );
         v_message_b :=
               'GL Import program triggered by Concur SAE Inbound Interface program('
            || fnd_global.conc_request_id
            || ') Completed in error/warning. Please review log/output file for Request Id.'
            || g_con_req_id;
         xx_intg_mail_util_pkg.mail
                 (sender          => v_from_email,
                  recipients      => v_to_email_b,
                  subject         => 'Concur SAE Inbound Interface - GL Import Error',
                  MESSAGE         => v_message_b
                 );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, v_message_b);
      ELSIF g_send_email_b = 'B' AND g_send_email = 'I'
      THEN
         xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                         'Sending Mail to IT Support Team and Business Team.'
                        );
         v_message_b :=
               'GL Import program triggered by Concur SAE Inbound Interface program('
            || fnd_global.conc_request_id
            || ') Completed in error/warning. Please review log/output file for Request Id.'
            || g_con_req_id;
         xx_intg_mail_util_pkg.mail
                 (sender          => v_from_email,
                  recipients      => v_to_email_b,
                  subject         => 'Concur SAE Inbound Interface - GL Import Error',
                  MESSAGE         => v_message_b
                 );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, v_message_b);
         v_message_i :=
               'Concur SAE Inbound Interface Program Failed with error message: '
            || g_errbuf
            || '. Request Id.'
            || fnd_global.conc_request_id;
         xx_intg_mail_util_pkg.mail
                             (sender          => v_from_email,
                              recipients      => v_to_email_i,
                              subject         => 'Concur SAE Inbound Interface Error',
                              MESSAGE         => v_message_i
                             );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, v_message_i);
      ELSIF g_send_email_b = 'C' AND g_send_email = 'N'
      THEN
         xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                         'Sending Mail to Business Team on Normal Completion.'
                        );
         v_message_b :=
               'GL Import program triggered by Concur SAE Inbound Interface program('
            || fnd_global.conc_request_id
            || ') Completed Normal.'
            || g_con_req_id;
         xx_intg_mail_util_pkg.mail
                 (sender          => v_from_email,
                  recipients      => v_to_email_b,
                  subject         => 'Concur SAE Inbound Interface - GL Import Success',
                  MESSAGE         => v_message_b
                 );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, v_message_b);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         g_ret_code := xx_emf_cn_pkg.cn_prc_err;
         g_errbuf := 'Error in send_email:' || SQLERRM;
   END;

   PROCEDURE send_email_pc
   IS
      v_message_i     VARCHAR2 (1000);
      v_message_b     VARCHAR2 (1000);
      v_from_email    VARCHAR2 (60);
      v_to_email_i    VARCHAR2 (1000);
      v_to_email_b    VARCHAR2 (1000);
      v_to_email_b1   VARCHAR2 (1000);
      v_to_email_b2   VARCHAR2 (1000);
      v_to_email_b3   VARCHAR2 (1000);
   BEGIN
      xx_intg_common_pkg.get_process_param_value
                                      (p_process_name      => 'XXCONCURSAEIMPORT',
                                       p_param_name        => 'FROM_EMAIL',
                                       x_param_value       => v_from_email
                                      );
      xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'TO_EMAIL_B1',
                                        x_param_value       => v_to_email_b1
                                       );
      xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'TO_EMAIL_B2',
                                        x_param_value       => v_to_email_b2
                                       );
      xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'TO_EMAIL_B3',
                                        x_param_value       => v_to_email_b3
                                       );
      xx_intg_common_pkg.get_process_param_value
                                       (p_process_name      => 'XXCONCURSAEIMPORT',
                                        p_param_name        => 'TO_EMAIL_I',
                                        x_param_value       => v_to_email_i
                                       );
      v_to_email_b := v_to_email_b1 || v_to_email_b2 || v_to_email_b3;

      IF g_send_email_pc = 'I' AND g_send_email_b_pc = 'N'
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Sending Mail to IT Support Team.'
                              );
         v_message_i :=
               'Concur SAE Inbound Interface Program Failed with error message: '
            || g_errbuf
            || '. Request Id.'
            || fnd_global.conc_request_id;
         xx_intg_mail_util_pkg.mail
                             (sender          => v_from_email,
                              recipients      => v_to_email_i,
                              subject         => 'Concur SAE Inbound Interface Error',
                              MESSAGE         => v_message_i
                             );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, v_message_i);
      ELSIF g_send_email_b_pc = 'B' AND g_send_email_pc = 'N'
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Sending Mail to Business Team.'
                              );
         v_message_b :=
               'GL Import(P-Card) program triggered by Concur SAE Inbound Interface program('
            || fnd_global.conc_request_id
            || ') Completed in error/warning. Please review log/output file for Request Id.'
            || g_con_req_id_pc;
         xx_intg_mail_util_pkg.mail
                 (sender          => v_from_email,
                  recipients      => v_to_email_b,
                  subject         => 'Concur SAE Inbound Interface - GL Import Error',
                  MESSAGE         => v_message_b
                 );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, v_message_b);
      ELSIF g_send_email_b_pc = 'B' AND g_send_email_pc = 'I'
      THEN
         xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                         'Sending Mail to IT Support Team and Business Team.'
                        );
         v_message_b :=
               'GL Import(P-Card) program triggered by Concur SAE Inbound Interface program('
            || fnd_global.conc_request_id
            || ') Completed in error/warning. Please review log/output file for Request Id.'
            || g_con_req_id_pc;
         xx_intg_mail_util_pkg.mail
                 (sender          => v_from_email,
                  recipients      => v_to_email_b,
                  subject         => 'Concur SAE Inbound Interface - GL Import Error',
                  MESSAGE         => v_message_b
                 );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, v_message_b);
         v_message_i :=
               'Concur SAE Inbound Interface Program Failed with error message: '
            || g_errbuf
            || '. Request Id.'
            || fnd_global.conc_request_id;
         xx_intg_mail_util_pkg.mail
                             (sender          => v_from_email,
                              recipients      => v_to_email_i,
                              subject         => 'Concur SAE Inbound Interface Error',
                              MESSAGE         => v_message_i
                             );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, v_message_i);
      ELSIF g_send_email_b = 'C' AND g_send_email = 'N'
      THEN
         xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                         'Sending Mail to Business Team on Normal Completion.'
                        );
         v_message_b :=
               'GL Import(P-Card) program triggered by Concur SAE Inbound Interface program('
            || fnd_global.conc_request_id
            || ') Completed Normal.'
            || g_con_req_id_pc;
         xx_intg_mail_util_pkg.mail
                 (sender          => v_from_email,
                  recipients      => v_to_email_b,
                  subject         => 'Concur SAE Inbound Interface - GL Import Success',
                  MESSAGE         => v_message_b
                 );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, v_message_b);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         g_ret_code := xx_emf_cn_pkg.cn_prc_err;
         g_errbuf := 'Error in send_email:' || SQLERRM;
   END;

   FUNCTION next_field (
      p_line_buffer     IN       VARCHAR2,
      p_delimiter       IN       VARCHAR2,
      x_last_position   IN OUT   NUMBER
   )
      RETURN VARCHAR2
   IS
      x_new_position     NUMBER (6)       := NULL;
      x_out_field        VARCHAR2 (20000) := NULL;
      x_delimiter        VARCHAR2 (200)   := p_delimiter;
      x_delimiter_size   NUMBER (2)       := 1;
   BEGIN
      x_new_position := INSTR (p_line_buffer, x_delimiter, x_last_position);

      IF x_new_position = 0
      THEN
         x_new_position := LENGTH (p_line_buffer) + 1;
      END IF;

      x_out_field :=
         SUBSTR (p_line_buffer,
                 x_last_position,
                 x_new_position - x_last_position
                );
      x_out_field := LTRIM (RTRIM (x_out_field));

      IF x_new_position = LENGTH (p_line_buffer) + 1
      THEN
         x_last_position := 0;
      ELSE
         x_last_position := x_new_position + x_delimiter_size;
      END IF;

      RETURN x_out_field;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_last_position := -1;
         RETURN ' Error :' || SQLERRM;
   END NEXT_FIELD;
END XX_CONCUR_SAE_IMPORT_PKG;
/
