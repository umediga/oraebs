DROP PACKAGE BODY APPS.XX_CN_SR_REASSIGN_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_CN_SR_REASSIGN_PKG" 
AS
/* $Header: XXOICPOPSALESREPS.pkb 1.0.0 2012/05/18 00:00:00 partha noship $ */
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 18-May-2012
 File Name     : XXOICPOPSALESREPS.pkb
 Description   : This script creates the body for package xx_oic_populate_sales_pkg
         Selects records from xx_intg_oic_sr_reassign_v and inserts into CN_COMM_LINES_API_ALL.
         Program Output prints the processed Record count aswell Error messages if any.
 Change History:
 Date         Name                   Remarks
 -----------  -------------          -----------------------------------
 18-May-2012    IBM Development Team   Initial development.
*/
----------------------------------------------------------------------

   -- Below procedure will set the EMF environment
-- Parameter p_required_flag use for required_flag
   PROCEDURE set_cnv_env (
      p_required_flag   VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_yes
   )
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      -- Set the environment
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Before Set env');
      x_error_code := xx_emf_pkg.set_env;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'After Set env');

      IF NVL (p_required_flag, xx_emf_cn_pkg.cn_yes) <> xx_emf_cn_pkg.cn_no
      THEN
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE xx_emf_pkg.g_e_env_not_set;
   END set_cnv_env;

-- Procedure will count total, sucess, error records.
   PROCEDURE update_record_count
   IS
      x_total_cnt     NUMBER := 0;
      x_error_cnt     NUMBER := 0;
      x_success_cnt   NUMBER := 0;
      x_warn_cnt      NUMBER := 0;
   BEGIN
      x_total_cnt := g_total_cnt;
      x_error_cnt := g_error_cnt;
      x_success_cnt := g_success_cnt;
      x_warn_cnt := g_warn_cnt;
--Calling update record count Procedure of EMF Packg
      xx_emf_pkg.update_recs_cnt (p_total_recs_cnt        => x_total_cnt,
                                  p_success_recs_cnt      => x_success_cnt,
                                  p_warning_recs_cnt      => x_warn_cnt,
                                  p_error_recs_cnt        => x_error_cnt
                                 );
   END;

-- Below procedure will insert the data in to interface table from custom view.
-- Two o_erruf and o_retcode is two parameter.
   PROCEDURE xx_insert_record (o_errbuf OUT VARCHAR2, o_retcode OUT VARCHAR2)
   IS
      x_trx_type   VARCHAR2 (20);

--Cursor cur_bgp is fetching data from the custom view xx_intg_oic_sr_reassign_v
      CURSOR cur_popsales
      IS
         SELECT *
           FROM xx_intg_oic_sr_reassign_v;
   BEGIN

      g_total_cnt := 0;
      g_error_cnt := 0;
      g_success_cnt := 0;
      g_warn_cnt := 0;
-- Calling the procedure get_process_param_value
      xx_intg_common_pkg.get_process_param_value ('XXCNSRRP41',
                                                  'trx_type',
                                                  x_trx_type
                                                 );
--Calling the procedure set_cnv_env for set enviroment
      set_cnv_env (p_required_flag => xx_emf_cn_pkg.cn_yes);

      SELECT COUNT (1)
        INTO g_total_cnt
        FROM xx_intg_oic_sr_reassign_v;

      FOR rec_popsales IN cur_popsales
      LOOP
       BEGIN
         INSERT INTO cn_comm_lines_api_all
                     (
                      attribute1
                     ,attribute2
                     ,attribute4
                     ,attribute10
                     ,attribute35
                     ,attribute36
                     ,attribute37
                     ,attribute99
                     ,attribute26
                     ,attribute54
                     ,salesrep_id
                     ,processed_date
                     ,transaction_amount
                     ,salesrep_number
                     ,employee_number  -- New
                     ,created_by
                     ,creation_date
                     ,last_updated_by
                     ,last_update_date
                     ,transaction_currency_code
                     ,trx_id
                     ,trx_line_id
                     ,trx_sales_line_id
                     ,trx_type
                     ,comm_lines_api_id
                     ,org_id
                     ,quantity
                     ,order_number
                     ,booked_date
                     ,invoice_number
                     ,invoice_date
                     ,bill_to_address_id
                     ,ship_to_address_id
                     ,bill_to_contact_id
                     ,ship_to_contact_id
                     ,uom_code
                     ,source_trx_id
                     ,source_trx_line_id
                     ,source_trx_sales_line_id
                     ,customer_id
                     ,inventory_item_id
                     ,line_number
                     )
              VALUES (
                      rec_popsales.customer_name
                     ,rec_popsales.division
                     ,rec_popsales.sub_division
                     ,rec_popsales.dcode
                     ,rec_popsales.brand
                     ,rec_popsales.product_class
                     ,rec_popsales.product_type
                     ,rec_popsales.intg_record_id
                     ,rec_popsales.orig_book_salesrep_name
                     ,rec_popsales.orig_book_salesrep_num
                     ,rec_popsales.latest_salesrep_id
                     ,rec_popsales.processed_date
                     ,rec_popsales.transaction_amount
                     ,rec_popsales.salesrep_number
                     ,rec_popsales.employee_number -- new
                     ,fnd_global.user_id
                     ,SYSDATE
                     ,fnd_global.user_id
                     ,SYSDATE
                     ,rec_popsales.currency
                     ,rec_popsales.customer_trx_id
                     ,rec_popsales.customer_trx_line_id
                     ,rec_popsales.cust_trx_line_salesrep_id
                     ,x_trx_type
                     ,cn_comm_lines_api_s.NEXTVAL
                     ,rec_popsales.intg_org_id
                     ,rec_popsales.quantity_shipped
                     ,rec_popsales.order_number
                     ,rec_popsales.order_date
                     ,rec_popsales.invoice_number
                     ,rec_popsales.processed_date
                     ,rec_popsales.bill_to_address_id
                     ,rec_popsales.ship_to_address_id
                     ,rec_popsales.bill_to_contact_id
                     ,rec_popsales.ship_to_contact_id
                     ,rec_popsales.uom
                     ,rec_popsales.customer_trx_id
                     ,rec_popsales.customer_trx_line_id
                     ,rec_popsales.cust_trx_line_salesrep_id
                     ,rec_popsales.party_id
                     ,rec_popsales.inventory_item_id
                     ,rec_popsales.order_line_number
                     );

         G_SUCCESS_CNT := G_SUCCESS_CNT + 1;
    EXCEPTION
          WHEN OTHERS
      THEN
         --O_RETCODE := XX_EMF_CN_PKG.CN_PRC_ERR;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'trx_id: ' || rec_popsales.customer_trx_id
                                            || 'order_number: '||rec_popsales.order_number
                                            || 'intg_record_id: ' ||rec_popsales.intg_record_id
                                            || 'Error :' || SQLERRM);
         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                          ,p_category    => xx_emf_cn_pkg.CN_VALID
                          ,p_error_text  => 'Insert Failed Error :' || SQLERRM
                          ,p_record_identifier_1 => rec_popsales.customer_trx_id
                          ,p_record_identifier_2 => rec_popsales.order_number
                          ,p_record_identifier_3 => rec_popsales.intg_record_id
                         );
          g_error_cnt := g_error_cnt + 1;
       END;
      END LOOP;

      IF g_error_cnt > 0 THEN
         rollback;
         raise xx_emf_pkg.g_e_prc_error;
      ELSE
         commit;
      END IF;
      update_record_count;
      xx_emf_pkg.create_report;

   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Checking if this is OK');
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               xx_emf_pkg.cn_env_not_set
                              );
         o_retcode := xx_emf_cn_pkg.cn_rec_err;
         update_record_count;
         xx_emf_pkg.create_report;


      WHEN xx_emf_pkg.g_e_rec_error
      THEN
          o_retcode := xx_emf_cn_pkg.cn_rec_err;
          update_record_count;
          xx_emf_pkg.create_report;
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Error1 :' || SQLERRM);
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         o_retcode := xx_emf_cn_pkg.cn_prc_err;
         update_record_count;
         xx_emf_pkg.create_report;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Error2 :' || SQLERRM);
      WHEN OTHERS
      THEN
         o_retcode := xx_emf_cn_pkg.cn_prc_err;
         update_record_count;
         xx_emf_pkg.create_report;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Error3 :' || SQLERRM);

   END;
END xx_cn_sr_reassign_pkg;
/
