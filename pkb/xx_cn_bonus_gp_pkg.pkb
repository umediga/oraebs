DROP PACKAGE BODY APPS.XX_CN_BONUS_GP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_CN_BONUS_GP_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 29-Mar-12
 File Name     : XXCNBONUSGP.pkb
 Description   : This script creates the body for package
         XX_OIC_BONUS_GP_PKG
         Selects records from XX_CN_BONUS_GP_V and inserts into CN_COMM_LINES_API_ALL.
         Program Output prints the processed Record count aswell Error messages if any.
 Change History:
 Date         Name                   Remarks
 -----------  -------------          -----------------------------------
 29-Mar-12    IBM Development Team   Initial development.
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
-- Two erruf and retcode is two parameter.
   PROCEDURE xx_insert_record (errbuf OUT VARCHAR2, retcode OUT VARCHAR2)
   IS
      x_trx_type   VARCHAR2 (20);

--Cursor cur_bgp is fetching data from the custom view xx_intg_oic_bonus_gp_v
      CURSOR cur_bgp
      IS
         SELECT invoice_number
               ,processed_date
               ,order_number
               ,header_id
               ,inventory_item_id
               ,order_line_number
               ,order_line_id
               ,item_number
               ,description
               ,INTG_org_id
               ,organization_code
               ,organization_id
               ,operating_unit
               ,warehouse_name
               ,party_id
               ,party_number
               ,customer_name
               ,material_number
               ,unit_selling_price
               ,unit_list_price
               ,item_cost
               ,ordered_quantity
               ,quantity_shipped
               ,uom
               ,unit_diff
               ,transaction_amount
               ,gross_profit
               ,discount
               ,cancelled_quantity
               ,shipping_quantity
               ,transaction_type_id
               ,ship_from_org_id
               ,bill_to_address_id
               ,ship_to_address_id
               ,bill_to_contact_id
               ,ship_to_contact_id
               ,creation_date
               ,line_type_id
               ,price_list_id
               ,division
               ,sub_division
               ,contract_category
               ,brand
               ,product_class
               ,product_type
               ,d_code
               ,inventory_item_status_code
               ,currency
               ,order_type
               ,cust_account_id
               ,order_date
               ,order_header_id
               ,conversion_rate
               ,conversion_type_code
               ,header_salesrep_id
               ,salesrep_id
               ,salesrep_number
               ,crm_salesrep_name
               ,header_ship_country_id
               ,customer_trx_id
               ,customer_trx_line_id
               ,primary_salesrep_id
               ,line_salesrep_id
               ,cust_trx_line_salesrep_id
               ,header_ship_country_name
           FROM xx_cn_bonus_gp_v;
   BEGIN
-- Calling the procedure get_process_param_value
-- Parameter @p_process_name  --> XXCNPEBGP42, @p_param_name  --> trx_type, @x_param_value -->x_trx_type
      xx_intg_common_pkg.get_process_param_value ('XXCNPEBGP42',
                                                  'trx_type',
                                                  x_trx_type
                                                 );
--Calling the procedure set_cnv_env for set enviroment
      set_cnv_env (p_required_flag => xx_emf_cn_pkg.cn_yes);

      SELECT COUNT (1)
        INTO g_total_cnt
        FROM xx_cn_bonus_gp_v;

--rec_bgp is the variable of Cursor cur_bgp


      FOR rec_bgp IN cur_bgp
      LOOP
--Insert data into Interface Table
BEGIN -------- for Insert inside loop
         INSERT INTO cn_comm_lines_api_all
                     (salesrep_id
                     ,processed_date
                     ,transaction_amount
                     ,salesrep_number
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
                     ,discount_percentage
                     ,uom_code
                     ,source_trx_id
                     ,source_trx_line_id
                     ,source_trx_sales_line_id
                     ,customer_id
                     ,inventory_item_id
                     ,line_number
                     )
              VALUES (rec_bgp.salesrep_id
                     ,rec_bgp.processed_date
                     ,rec_bgp.transaction_amount
                     ,rec_bgp.salesrep_number
                     ,fnd_global.user_id
                     ,SYSDATE
                     ,fnd_global.user_id
                     ,SYSDATE
                     ,rec_bgp.currency
                     ,rec_bgp.customer_trx_id
                     ,rec_bgp.customer_trx_line_id
                     ,rec_bgp.cust_trx_line_salesrep_id
                     ,x_trx_type
                     ,cn_comm_lines_api_s.NEXTVAL
                     ,rec_bgp.INTG_org_id
                     ,rec_bgp.quantity_shipped
                     ,rec_bgp.order_number
                     ,rec_bgp.order_date
                     ,rec_bgp.invoice_number
                     ,rec_bgp.processed_date
                     ,rec_bgp.bill_to_address_id
                     ,rec_bgp.ship_to_address_id
                     ,rec_bgp.bill_to_contact_id
                     ,rec_bgp.ship_to_contact_id
                     ,rec_bgp.discount
                     ,rec_bgp.uom
                     ,rec_bgp.customer_trx_id
                     ,rec_bgp.customer_trx_line_id
                     ,rec_bgp.cust_trx_line_salesrep_id
                     ,rec_bgp.party_id
                     ,rec_bgp.inventory_item_id
                     ,rec_bgp.order_line_number
                     );

         g_success_cnt := g_success_cnt + 1;

EXCEPTION
--Calling the procedure update_record_count from xx_emf_pkg
WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Checking if this is OK');
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               xx_emf_pkg.cn_env_not_set
                              );
         retcode := xx_emf_cn_pkg.cn_rec_err;

      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         retcode := xx_emf_cn_pkg.cn_rec_err;

      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         retcode := xx_emf_cn_pkg.cn_prc_err;

      WHEN OTHERS
      THEN
         retcode := xx_emf_cn_pkg.cn_prc_err;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Error :' || SQLERRM);

 -------- for Insert inside loop
END;

      COMMIT;
      END LOOP;
      update_record_count;
      xx_emf_pkg.create_report;

    ---------This exception is the outer exception block
   EXCEPTION
   --Calling the procedure update_record_count and create_report from xx_emf_pkg
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Checking if this is OK');
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               xx_emf_pkg.cn_env_not_set
                              );
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
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Error :' || SQLERRM);
         xx_emf_pkg.create_report;




   END;
END xx_cn_bonus_gp_pkg;
/
