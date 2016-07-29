DROP PACKAGE BODY APPS.XX_CN_LOAD_REVENUE_CLASS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_CN_LOAD_REVENUE_CLASS_PKG" AS
   ----------------------------------------------------------------------
   /*
    Created By    : Kunal Seal
    Creation Date : 27-Mar-2012
    File Name     : XXCNCOMITEM.PKB
    Description   : This package creates Revenue Class in OIC tables for
                    the commissionable items in Inventory
    Change History:
    Date           Name                  Remarks
    -----------    -------------         -----------------------------------
    27-Mar-2012    Kunal Seal            Initial Version
   */
   ----------------------------------------------------------------------

   --###########################################
   --# Procedure to create Revenue class       #
   --# through API  l                           #
   --###########################################
   PROCEDURE create_revenue_class(p_item_no     IN VARCHAR2,
                                  p_description IN VARCHAR2,
                                  p_org_id      IN NUMBER) IS

      --X_ITEM_NUM    VARCHAR2(250);
      --X_DESCRIPTION VARCHAR2(250);
      --X_ORG_ID      NUMBER;

      x_return_status    VARCHAR2(10);
      x_msg_count        NUMBER := 0;
      x_msg_data         VARCHAR2(2000);
      x_loading_status   VARCHAR2(30);
      x_revenue_class_id NUMBER;
      x_rev_class_rec    cn_revenue_class_pvt.revenue_class_rec_type;

      x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
      -- X_TOTAL_CNT   NUMBER := 0;
      -- X_SUCCESS_CNT NUMBER := 0;
      --X_WARN_CNT    NUMBER := 0;
      --X_ERROR_CNT   NUMBER := 0;

   BEGIN

      -- Put the valuses of Item No and Description for Creating Revenue
      -- class for the Item
      x_rev_class_rec.NAME                  := p_item_no;
      x_rev_class_rec.description           := p_description;
      x_rev_class_rec.liability_account_id  := NULL;
      x_rev_class_rec.expense_account_id    := NULL;
      x_rev_class_rec.object_version_number := NULL;

      -- Call the API to create Revenue Class for the Item
      cn_revenue_class_pvt.create_revenue_class(p_api_version       => 1.0,
                                                x_return_status     => x_return_status,
                                                p_init_msg_list     => fnd_api.g_true,
                                                x_msg_count         => x_msg_count,
                                                x_msg_data          => x_msg_data,
                                                x_loading_status    => x_loading_status,
                                                x_revenue_class_id  => x_revenue_class_id,
                                                p_revenue_class_rec => x_rev_class_rec,
                                                p_org_id            => p_org_id);

      IF (x_return_status != 'S') THEN
         -- If any issue on creating revenue class
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Revenue Class : '
                                                              ||x_return_status);
         xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.cn_low,
                          p_category            => xx_emf_cn_pkg.cn_prc_err,
                          p_error_text          => 'Error inserting through API : ' ||
                                                   x_msg_data,
                          p_record_identifier_1 => p_item_no);
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         xx_emf_pkg.propagate_error(x_error_code);
      ELSE
           xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Revenue Class : '
                                                     ||x_revenue_class_id);

      END IF;

   EXCEPTION
      WHEN xx_emf_pkg.g_e_prc_error THEN
         xx_emf_pkg.propagate_error(x_error_code);
      WHEN OTHERS THEN
         -- For any other issue in this block
         xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.cn_low,
                          p_category            => xx_emf_cn_pkg.cn_prc_err,
                          p_error_text          => 'Error calling API :',
                          p_record_identifier_1 => p_item_no);
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         xx_emf_pkg.propagate_error(x_error_code);


   END create_revenue_class;

   --###########################################
   --# Main Procedure for Concurrent Program   #
   --###########################################

   PROCEDURE main(errbuff OUT VARCHAR2,
             retcode OUT VARCHAR2)
   IS
      CURSOR c_comm_items
      -- This cursor will fetch all the Commissionable Items
      IS
         SELECT iciv.item_number      item_number,
                iciv.item_description item_description,
                iciv.org_id           org_id
           FROM xxcn_intg_comm_item_v iciv
          WHERE 1 = 1
               -- Check if Revenue Class already exists for the item
            AND NOT EXISTS
          (SELECT 1
                   FROM cn_revenue_classes_all crc
                  WHERE 1 = 1
                    AND crc.NAME = iciv.item_number
                    AND crc.org_id = iciv.org_id)
          GROUP BY iciv.item_number, iciv.item_description, iciv.org_id;
      x_error_code  NUMBER := xx_emf_cn_pkg.cn_success;
      x_total_cnt   NUMBER := 0;
      x_success_cnt NUMBER := 0;
      x_warn_cnt    NUMBER := 0;
      x_error_cnt   NUMBER := 0;
   BEGIN
      errbuff := NULL;
      retcode := '0';
      -- Set the environment
      x_error_code := xx_emf_pkg.set_env;

      FOR item_data IN c_comm_items LOOP
         x_total_cnt := x_total_cnt + 1;
         BEGIN
            create_revenue_class(item_data.item_number,
                                 item_data.item_description,
                                 item_data.org_id);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'After Create call');
            x_success_cnt := x_success_cnt + 1;
         EXCEPTION
            WHEN xx_emf_pkg.g_e_prc_error THEN
               x_error_cnt := x_error_cnt + 1;
         END;
      END LOOP;

      -- Generate report through EMF
      xx_emf_pkg.update_recs_cnt(p_total_recs_cnt   => x_total_cnt,
                                 p_success_recs_cnt => x_success_cnt,
                                 p_warning_recs_cnt => x_warn_cnt,
                                 p_error_recs_cnt   => x_error_cnt);
      xx_emf_pkg.create_report;
   EXCEPTION

      WHEN OTHERS THEN
         -- In case of any Unexpected Error
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,
                              'Unexpected Error : ' ||
                              substr(SQLERRM,
                                     1,
                                     250));
         xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.cn_low,
                          p_category            => xx_emf_cn_pkg.cn_prc_err,
                          p_error_text          => 'Unexpected Error',
                          p_record_identifier_1 => NULL);
         retcode := xx_emf_cn_pkg.cn_prc_err;
         xx_emf_pkg.create_report;

   END main;
END xx_cn_load_revenue_class_pkg;
/
