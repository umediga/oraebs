DROP PROCEDURE APPS.XXINTG_UPDATE_PRICE_LIST;

CREATE OR REPLACE PROCEDURE APPS."XXINTG_UPDATE_PRICE_LIST" (
   errbuf         OUT      VARCHAR2,
   retcode        OUT      VARCHAR2,
   p_list_name    IN       VARCHAR2,
   p_precedence   IN       NUMBER
)
IS
   gpr_price_list_rec             qp_price_list_pub.price_list_rec_type;
   gpr_price_list_val_rec         qp_price_list_pub.price_list_val_rec_type;
   gpr_price_list_line_tbl        qp_price_list_pub.price_list_line_tbl_type;
   gpr_price_list_line_val_tbl    qp_price_list_pub.price_list_line_val_tbl_type;
   gpr_qualifiers_tbl             qp_qualifier_rules_pub.qualifiers_tbl_type;
   gpr_qualifiers_val_tbl         qp_qualifier_rules_pub.qualifiers_val_tbl_type;
   gpr_pricing_attr_tbl           qp_price_list_pub.pricing_attr_tbl_type;
   gpr_pricing_attr_val_tbl       qp_price_list_pub.pricing_attr_val_tbl_type;
   ppr_price_list_rec             qp_price_list_pub.price_list_rec_type;
   ppr_price_list_val_rec         qp_price_list_pub.price_list_val_rec_type;
   ppr_price_list_line_tbl        qp_price_list_pub.price_list_line_tbl_type;
   ppr_price_list_line_val_tbl    qp_price_list_pub.price_list_line_val_tbl_type;
   ppr_qualifier_rules_rec        qp_qualifier_rules_pub.qualifier_rules_rec_type;
   ppr_qualifier_rules_val_rec    qp_qualifier_rules_pub.qualifier_rules_val_rec_type;
   ppr_qualifiers_tbl             qp_qualifier_rules_pub.qualifiers_tbl_type;
   ppr_qualifiers_val_tbl         qp_qualifier_rules_pub.qualifiers_val_tbl_type;
   ppr_pricing_attr_tbl           qp_price_list_pub.pricing_attr_tbl_type;
   ppr_pricing_attr_val_tbl       qp_price_list_pub.pricing_attr_val_tbl_type;
   x_return_status                VARCHAR2 (15)   := xx_emf_cn_pkg.cn_success;
   x_init_msg_list                VARCHAR2 (1000)           := fnd_api.g_true;
   gpr_return_status              VARCHAR2 (1)                        := NULL;
   gpr_msg_count                  NUMBER                                 := 0;
   x_msg_count                    NUMBER;
   x_msg_data                     VARCHAR2 (2000);
   gpr_msg_data                   VARCHAR2 (32767);
   gpr_msg_data2                  VARCHAR2 (32767);
   x_success_record               NUMBER;
   x_error_record                 NUMBER;
   x_pricing_attr_index           NUMBER                                 := 0;
   x_lpr_line_index               NUMBER                                 := 0;
   x_product_attribute            VARCHAR2 (60);
   b_list_line_count              NUMBER;
   b_list_attr_count              NUMBER;
   x_err_msg                      VARCHAR2 (3000);
   --------
   c_yn_flag_y           CONSTANT VARCHAR2 (1)                         := 'Y';
   c_yn_flag_n           CONSTANT VARCHAR2 (1)                         := 'N';
   x_exists_flag                  VARCHAR2 (1);
   c_pricelist           CONSTANT VARCHAR2 (3)                       := 'PRL';
   c_discountlist        CONSTANT VARCHAR2 (3)                       := 'DLT';
   c_action_ins          CONSTANT VARCHAR2 (3)                       := 'INS';
   c_action_upd          CONSTANT VARCHAR2 (3)                       := 'UPD';
   c_incomp_grp          CONSTANT VARCHAR2 (10)                    := 'LVL 1';
   c_appl_method_mod     CONSTANT VARCHAR2 (20)                 := 'NEWPRICE';
   c_appl_method_prc     CONSTANT VARCHAR2 (20)               := 'UNIT_PRICE';
   x_list_header_id               qp_list_headers.list_header_id%TYPE;
   x_invitem_cat_id               mtl_system_items_b.inventory_item_id%TYPE;
   x_list_line_id                 qp_list_lines.list_line_id%TYPE;
   x_uom_code                     mtl_system_items_b.primary_uom_code%TYPE;
   c_product_attr_item   CONSTANT VARCHAR2 (20)              := 'Item Number';
   c_product_attr_cat    CONSTANT VARCHAR2 (20)            := 'Item Category';
   c_prc_context_type    CONSTANT VARCHAR2 (20)                  := 'PRODUCT';
   c_prc_context_code    CONSTANT VARCHAR2 (20)                     := 'ITEM';
   x_act_line_exists_flag         VARCHAR2 (1);
   x_price_protect_hdr            VARCHAR2 (10);
   x_price_protect_lin            VARCHAR2 (10);
   x_price_protect_lin_flg        VARCHAR2 (10);
   x_list_price                   qp_list_lines_v.list_price%TYPE;
   x_start_date_active            qp_list_lines_v.start_date_active%TYPE;
   x_end_date_active              qp_list_lines_v.end_date_active%TYPE;
---------------------------------------------------------------
   x_modifier_list_rec            qp_modifiers_pub.modifier_list_rec_type;
   x_modifier_list_val_rec        qp_modifiers_pub.modifier_list_val_rec_type;
   x_modifiers_tbl                qp_modifiers_pub.modifiers_tbl_type;
   x_modifiers_val_tbl            qp_modifiers_pub.modifiers_val_tbl_type;
   x_qualifiers_tbl               qp_qualifier_rules_pub.qualifiers_tbl_type;
   x_qualifiers_val_tbl           qp_qualifier_rules_pub.qualifiers_val_tbl_type;
   x_pricing_attr_tbl             qp_modifiers_pub.pricing_attr_tbl_type;
   x_pricing_attr_val_tbl         qp_modifiers_pub.pricing_attr_val_tbl_type;
   p_modifier_list_rec            qp_modifiers_pub.modifier_list_rec_type;
   p_modifier_list_val_rec        qp_modifiers_pub.modifier_list_val_rec_type;
   p_modifiers_tbl                qp_modifiers_pub.modifiers_tbl_type;
   p_modifiers_val_tbl            qp_modifiers_pub.modifiers_val_tbl_type;
   p_qualifiers_tbl               qp_qualifier_rules_pub.qualifiers_tbl_type;
   p_qualifiers_val_tbl           qp_qualifier_rules_pub.qualifiers_val_tbl_type;
   p_pricing_attr_tbl             qp_modifiers_pub.pricing_attr_tbl_type;
   p_pricing_attr_val_tbl         qp_modifiers_pub.pricing_attr_val_tbl_type;
   x_msg_data2                    VARCHAR2 (2000);
   x_arithmetic_operator          qp_list_lines.arithmetic_operator%TYPE;
   x_product_precedence           qp_list_lines.product_precedence%TYPE;
   x_pricing_phase_id             qp_list_lines.pricing_phase_id%TYPE;
   x_error_code                   NUMBER;

-----------------------------------------------------------------------------
   CURSOR select_lines (ip_list_name IN VARCHAR2)
   IS
      SELECT list_header_id, list_line_id
        FROM qp_list_lines
       WHERE list_header_id IN (SELECT list_header_id
                                  FROM qp_list_headers
                                 WHERE NAME = ip_list_name);
BEGIN
   /* Custom Initialization*/
   x_error_code := xx_emf_pkg.set_env;
   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                         'Price List Name :' || p_list_name
                        );
   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                         'Precedence      :' || p_precedence
                        );

   FOR select_lines_cur IN select_lines (p_list_name)
   LOOP
      x_lpr_line_index := x_lpr_line_index + 1;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Processing Record '
                            || x_lpr_line_index
                            || ' for list header id '
                            || select_lines_cur.list_header_id
                           );
      gpr_price_list_line_tbl (x_lpr_line_index).list_header_id :=
                                               select_lines_cur.list_header_id;
      gpr_price_list_line_tbl (x_lpr_line_index).list_line_id :=
                                                 select_lines_cur.list_line_id;
      gpr_price_list_line_tbl (x_lpr_line_index).product_precedence :=
                                                                  p_precedence;
      gpr_price_list_line_tbl (x_lpr_line_index).operation :=
                                                       qp_globals.g_opr_update;
   END LOOP;

   ---Call API for Update-----------------------------------------------------
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Calling API for Update');
      qp_price_list_pub.process_price_list
                   (p_api_version_number           => 1,
                    p_init_msg_list                => fnd_api.g_true,
                    p_return_values                => fnd_api.g_false,
                    p_commit                       => fnd_api.g_false,
                    x_return_status                => gpr_return_status,
                    x_msg_count                    => gpr_msg_count,
                    x_msg_data                     => gpr_msg_data,
                    p_price_list_rec               => gpr_price_list_rec,
                    p_price_list_line_tbl          => gpr_price_list_line_tbl,
                    p_qualifiers_tbl               => gpr_qualifiers_tbl,
                    p_pricing_attr_tbl             => gpr_pricing_attr_tbl,
                    x_price_list_rec               => ppr_price_list_rec,
                    x_price_list_val_rec           => ppr_price_list_val_rec,
                    x_price_list_line_tbl          => ppr_price_list_line_tbl,
                    x_price_list_line_val_tbl      => ppr_price_list_line_val_tbl,
                    x_qualifiers_tbl               => ppr_qualifiers_tbl,
                    x_qualifiers_val_tbl           => ppr_qualifiers_val_tbl,
                    x_pricing_attr_tbl             => ppr_pricing_attr_tbl,
                    x_pricing_attr_val_tbl         => ppr_pricing_attr_val_tbl
                   );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_err_msg :=
               'Error occured calling api to create/update price list line '
            || ' Error: '
            || SQLERRM;
         ROLLBACK;
         retcode := 2;
   END;

   IF gpr_return_status IN ('E', 'U')
   THEN
      gpr_msg_data := '';
      gpr_msg_data2 := '';
      x_error_record := x_error_record + 1;

      FOR k IN 1 .. gpr_msg_count
      LOOP
         gpr_msg_data :=
            SUBSTR (oe_msg_pub.get (p_msg_index => k, p_encoded => 'F'),
                    1,
                    160
                   );
         gpr_msg_data2 :=
                SUBSTR (gpr_msg_data2 || LTRIM (RTRIM (gpr_msg_data)), 1, 200);
      END LOOP;

      x_err_msg :=
              'Price List line not updated ' || ' API Error: ' || gpr_msg_data;
      ROLLBACK;
      retcode := 2;
   ELSE
      x_err_msg := 'Successful updation';
      COMMIT;
   END IF;

   -----------API call for update end----------------------------------------
   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                         'Program Completion Message :' || x_err_msg
                        );
EXCEPTION
   WHEN OTHERS
   THEN
      retcode := 2;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Program Exception :' || x_err_msg
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, SQLERRM);
END;
/
