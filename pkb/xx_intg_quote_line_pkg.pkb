DROP PACKAGE BODY APPS.XX_INTG_QUOTE_LINE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xx_intg_quote_line_pkg
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 05-JUL-2013
 File Name     : XXINTGQUOTELINE.pkb
 Description   : This script creates the body of the package
                 xx_intg_quote_line_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 05-JUL-2013 Sharath Babu          Initial development.
*/
----------------------------------------------------------------------
   --Procedure to create quote line
   PROCEDURE create_quote_line (
      x_msg_data            OUT NOCOPY      VARCHAR2,
      x_msg_count           OUT NOCOPY      NUMBER,
      x_return_status       OUT NOCOPY      VARCHAR2,
      x_quote_line_id       OUT             NUMBER,
      p_quote_header_id     IN              NUMBER,
      p_org_id              IN              NUMBER,
      p_inventory_item_id   IN              NUMBER,
      p_quantity            IN              NUMBER,
      p_uom_code            IN              VARCHAR2
   )
   IS
      lr_qte_header            aso_quote_pub.qte_header_rec_type
                                        := aso_utility_pvt.get_qte_header_rec;
      lr_control               aso_quote_pub.control_rec_type
                                           := aso_utility_pvt.get_control_rec;
      lt_hd_price_attributes   aso_quote_pub.price_attributes_tbl_type;
      lr_hd_shipment           aso_quote_pub.shipment_rec_type
                                          := aso_utility_pvt.get_shipment_rec;
      lt_hd_shipment           aso_quote_pub.shipment_tbl_type;
      lt_hd_payment            aso_quote_pub.payment_tbl_type;
      lt_hd_freight_charge     aso_quote_pub.freight_charge_tbl_type;
      lt_hd_tax_detail         aso_quote_pub.tax_detail_tbl_type;
      lt_hd_attr_ext           aso_quote_pub.line_attribs_ext_tbl_type;
      lt_hd_sales_credit       aso_quote_pub.sales_credit_tbl_type;
      lt_hd_quote_party        aso_quote_pub.quote_party_tbl_type;
      lt_qte_line              aso_quote_pub.qte_line_tbl_type;
      lt_qte_line_dtl          aso_quote_pub.qte_line_dtl_tbl_type;
      lt_ln_shipment           aso_quote_pub.shipment_tbl_type;
      lt_line_attr_ext         aso_quote_pub.line_attribs_ext_tbl_type;
      lt_line_rltship          aso_quote_pub.line_rltship_tbl_type;
      lt_price_adjustment      aso_quote_pub.price_adj_tbl_type;
      lt_price_adj_attr        aso_quote_pub.price_adj_attr_tbl_type;
      lt_price_adj_rltship     aso_quote_pub.price_adj_rltship_tbl_type;
      lt_ln_price_attributes   aso_quote_pub.price_attributes_tbl_type;
      lt_ln_payment            aso_quote_pub.payment_tbl_type;
      lt_ln_freight_charge     aso_quote_pub.freight_charge_tbl_type;
      lt_ln_tax_detail         aso_quote_pub.tax_detail_tbl_type;
      lt_ln_sales_credit       aso_quote_pub.sales_credit_tbl_type;
      lt_ln_quote_party        aso_quote_pub.quote_party_tbl_type;
      xr_qte_header            aso_quote_pub.qte_header_rec_type
                                        := aso_utility_pvt.get_qte_header_rec;
      xt_qte_line              aso_quote_pub.qte_line_tbl_type;
      xt_qte_line_dtl          aso_quote_pub.qte_line_dtl_tbl_type;
      xt_hd_price_attributes   aso_quote_pub.price_attributes_tbl_type;
      xt_hd_payment            aso_quote_pub.payment_tbl_type;
      xt_hd_shipment           aso_quote_pub.shipment_tbl_type;
      xr_hd_shipment           aso_quote_pub.shipment_rec_type
                                          := aso_utility_pvt.get_shipment_rec;
      --NEW
      xt_hd_freight_charge     aso_quote_pub.freight_charge_tbl_type;
      xt_hd_tax_detail         aso_quote_pub.tax_detail_tbl_type;
      xt_hd_attr_ext           aso_quote_pub.line_attribs_ext_tbl_type;
      xt_hd_sales_credit       aso_quote_pub.sales_credit_tbl_type;
      xt_hd_quote_party        aso_quote_pub.quote_party_tbl_type;
      xt_line_attr_ext         aso_quote_pub.line_attribs_ext_tbl_type;
      xt_line_rltship          aso_quote_pub.line_rltship_tbl_type;
      xt_price_adjustment      aso_quote_pub.price_adj_tbl_type;
      xt_price_adj_attr        aso_quote_pub.price_adj_attr_tbl_type;
      xt_price_adj_rltship     aso_quote_pub.price_adj_rltship_tbl_type;
      xt_ln_price_attributes   aso_quote_pub.price_attributes_tbl_type;
      xt_ln_payment            aso_quote_pub.payment_tbl_type;
      xt_ln_shipment           aso_quote_pub.shipment_tbl_type;
      xt_ln_freight_charge     aso_quote_pub.freight_charge_tbl_type;
      xt_ln_tax_detail         aso_quote_pub.tax_detail_tbl_type;
      xt_ln_sales_credit       aso_quote_pub.sales_credit_tbl_type;
      xt_ln_quote_party        aso_quote_pub.quote_party_tbl_type;

      l_user_id                NUMBER := FND_GLOBAL.USER_ID;
      l_resp_id                NUMBER := FND_GLOBAL.RESP_ID;
      l_resp_appl_id           NUMBER := FND_GLOBAL.RESP_APPL_ID;

      ln_line_tbl_idx          NUMBER;
      l_return_status          VARCHAR2 (1);
      l_msg_count              NUMBER;
      l_msg_data               VARCHAR2 (2000);
      l_msg_index_out          NUMBER;
      l_msg                    VARCHAR2(2000);

      l_org_id                 NUMBER;
      l_last_update_date       DATE;

      CURSOR c_quote_hdr (cp_quote_header_id NUMBER)
      IS
         SELECT last_update_date
           FROM aso_quote_headers_all
          WHERE quote_header_id = cp_quote_header_id;
   BEGIN

       mo_global.set_policy_context('S',p_org_id);

       --mo_global.init('ASO');
       fnd_global.apps_initialize(user_id      => l_user_id,
                                  resp_id      => l_resp_id,
                                  resp_appl_id => l_resp_appl_id);

      ln_line_tbl_idx := 1;

      OPEN c_quote_hdr (lr_qte_header.quote_header_id);
      FETCH c_quote_hdr
       INTO l_last_update_date;
      CLOSE c_quote_hdr;

      lr_control.pricing_request_type := 'ASO';
      lr_control.header_pricing_event := 'BATCH';
      /*lr_control.CALCULATE_TAX_FLAG := 'Y';
      lr_control.CALCULATE_FREIGHT_CHARGE_FLAG := 'Y';
      lr_control.PRICE_MODE := 'QUOTE_LINE';*/
      lr_control.last_update_date := l_last_update_date;

      lr_qte_header.quote_header_id := p_quote_header_id;
      lr_qte_header.last_update_date := l_last_update_date;

      lt_qte_line (ln_line_tbl_idx) := aso_quote_pub.g_miss_qte_line_rec;
      lt_qte_line (ln_line_tbl_idx).operation_code := 'CREATE';
      lt_qte_line (ln_line_tbl_idx).quote_header_id := p_quote_header_id;
      lt_qte_line (ln_line_tbl_idx).org_id := p_org_id;
      lt_qte_line (ln_line_tbl_idx).inventory_item_id := p_inventory_item_id;
      lt_qte_line (ln_line_tbl_idx).quantity := p_quantity;
      lt_qte_line (ln_line_tbl_idx).uom_code := p_uom_code;
      lt_qte_line (ln_line_tbl_idx).last_update_date := l_last_update_date;
      lt_qte_line (ln_line_tbl_idx).line_category_code := 'ORDER';

      dbms_output.put_line(
                      'Inside Pkg Values  '
                   || p_quote_header_id
                   || ' '
                   || p_inventory_item_id
                   || ' '
                   || p_quantity
                   || '  '
                   || p_uom_code);

      aso_quote_pub.update_quote
                         (p_api_version_number           => 1.0,
                          p_init_msg_list                => fnd_api.g_true,
                          p_commit                       => fnd_api.g_false,
                          p_validation_level             => fnd_api.g_valid_level_full,
                          p_control_rec                  => lr_control,
                          p_qte_header_rec               => lr_qte_header,
                          p_hd_price_attributes_tbl      => lt_hd_price_attributes,
                          p_hd_payment_tbl               => lt_hd_payment,
                          p_hd_shipment_tbl              => lt_hd_shipment,
                          p_hd_freight_charge_tbl        => lt_hd_freight_charge,
                          p_hd_tax_detail_tbl            => lt_hd_tax_detail,
                          p_hd_attr_ext_tbl              => lt_hd_attr_ext,
                          p_hd_sales_credit_tbl          => lt_hd_sales_credit,
                          p_hd_quote_party_tbl           => lt_hd_quote_party,
                          p_qte_line_tbl                 => lt_qte_line,
                          p_qte_line_dtl_tbl             => lt_qte_line_dtl,
                          p_line_attr_ext_tbl            => lt_line_attr_ext,
                          p_line_rltship_tbl             => lt_line_rltship,
                          p_price_adjustment_tbl         => lt_price_adjustment,
                          p_price_adj_attr_tbl           => lt_price_adj_attr,
                          p_price_adj_rltship_tbl        => lt_price_adj_rltship,
                          p_ln_price_attributes_tbl      => lt_ln_price_attributes,
                          p_ln_payment_tbl               => lt_ln_payment,
                          p_ln_shipment_tbl              => lt_ln_shipment,
                          p_ln_freight_charge_tbl        => lt_ln_freight_charge,
                          p_ln_tax_detail_tbl            => lt_ln_tax_detail,
                          p_ln_sales_credit_tbl          => lt_ln_sales_credit,
                          p_ln_quote_party_tbl           => lt_ln_quote_party,
                          x_qte_header_rec               => xr_qte_header,
                          x_qte_line_tbl                 => xt_qte_line,
                          x_qte_line_dtl_tbl             => xt_qte_line_dtl,
                          x_hd_price_attributes_tbl      => xt_hd_price_attributes,
                          x_hd_payment_tbl               => xt_hd_payment,
                          x_hd_shipment_tbl              => xt_hd_shipment,
                          x_hd_freight_charge_tbl        => xt_hd_freight_charge,
                          x_hd_tax_detail_tbl            => xt_hd_tax_detail,
                          x_hd_attr_ext_tbl              => xt_hd_attr_ext,
                          x_hd_sales_credit_tbl          => xt_hd_sales_credit,
                          x_hd_quote_party_tbl           => xt_hd_quote_party,
                          x_line_attr_ext_tbl            => xt_line_attr_ext,
                          x_line_rltship_tbl             => xt_line_rltship,
                          x_price_adjustment_tbl         => xt_price_adjustment,
                          x_price_adj_attr_tbl           => xt_price_adj_attr,
                          x_price_adj_rltship_tbl        => xt_price_adj_rltship,
                          x_ln_price_attributes_tbl      => xt_ln_price_attributes,
                          x_ln_payment_tbl               => xt_ln_payment,
                          x_ln_shipment_tbl              => xt_ln_shipment,
                          x_ln_freight_charge_tbl        => xt_ln_freight_charge,
                          x_ln_tax_detail_tbl            => xt_ln_tax_detail,
                          x_ln_sales_credit_tbl          => xt_ln_sales_credit,
                          x_ln_quote_party_tbl           => xt_ln_quote_party,
                          x_return_status                => l_return_status,
                          x_msg_count                    => l_msg_count,
                          x_msg_data                     => l_msg_data
                         );

      dbms_output.put_line(
                      'Messge is '
                   || SUBSTR (l_msg_data, 1, 500)
                   || 'Return Status is    '
                   || l_return_status);

      IF l_return_status <> fnd_api.g_ret_sts_success
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         x_msg_count := l_msg_count;
         l_msg := NULL;
         FOR i IN 1..x_msg_count
         LOOP
            fnd_msg_pub.get (p_msg_index          => i,
                             p_data               => l_msg_data,
                             p_encoded            => fnd_api.g_false,
                             p_msg_index_out      => l_msg_index_out
                            );
            l_msg := l_msg||l_msg_data;
         END LOOP;
         x_msg_data := l_msg;
      ELSE
         x_return_status := fnd_api.g_ret_sts_success;
         x_quote_line_id := xt_qte_line (ln_line_tbl_idx).quote_line_id;
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_msg_data := SQLERRM;
         x_return_status := fnd_api.g_ret_sts_error;
   END create_quote_line;
   --Procedure to update quote line
   PROCEDURE update_quote_line (
      x_msg_data          OUT NOCOPY      VARCHAR2,
      x_msg_count         OUT NOCOPY      NUMBER,
      x_return_status     OUT NOCOPY      VARCHAR2,
      p_quote_header_id   IN              NUMBER,
      p_org_id            IN              NUMBER,
      p_quote_line_id     IN              NUMBER,
      p_selling_price     IN              NUMBER,
      p_discount          IN              NUMBER
   )
   IS
      lr_qte_header            aso_quote_pub.qte_header_rec_type
                                        := aso_utility_pvt.get_qte_header_rec;
      lr_control               aso_quote_pub.control_rec_type
                                           := aso_utility_pvt.get_control_rec;
      lt_hd_price_attributes   aso_quote_pub.price_attributes_tbl_type;
      lr_hd_shipment           aso_quote_pub.shipment_rec_type
                                          := aso_utility_pvt.get_shipment_rec;
      lt_hd_shipment           aso_quote_pub.shipment_tbl_type;
      lt_hd_payment            aso_quote_pub.payment_tbl_type;
      lt_hd_freight_charge     aso_quote_pub.freight_charge_tbl_type;
      lt_hd_tax_detail         aso_quote_pub.tax_detail_tbl_type;
      lt_hd_attr_ext           aso_quote_pub.line_attribs_ext_tbl_type;
      lt_hd_sales_credit       aso_quote_pub.sales_credit_tbl_type;
      lt_hd_quote_party        aso_quote_pub.quote_party_tbl_type;
      lt_qte_line              aso_quote_pub.qte_line_tbl_type;
      lt_qte_line_dtl          aso_quote_pub.qte_line_dtl_tbl_type;
      lt_ln_shipment           aso_quote_pub.shipment_tbl_type;
      lt_line_attr_ext         aso_quote_pub.line_attribs_ext_tbl_type;
      lt_line_rltship          aso_quote_pub.line_rltship_tbl_type;
      lt_price_adjustment      aso_quote_pub.price_adj_tbl_type;
      lt_price_adj_attr        aso_quote_pub.price_adj_attr_tbl_type;
      lt_price_adj_rltship     aso_quote_pub.price_adj_rltship_tbl_type;
      lt_ln_price_attributes   aso_quote_pub.price_attributes_tbl_type;
      lt_ln_payment            aso_quote_pub.payment_tbl_type;
      lt_ln_freight_charge     aso_quote_pub.freight_charge_tbl_type;
      lt_ln_tax_detail         aso_quote_pub.tax_detail_tbl_type;
      lt_ln_sales_credit       aso_quote_pub.sales_credit_tbl_type;
      lt_ln_quote_party        aso_quote_pub.quote_party_tbl_type;
      xr_qte_header            aso_quote_pub.qte_header_rec_type
                                        := aso_utility_pvt.get_qte_header_rec;
      xt_qte_line              aso_quote_pub.qte_line_tbl_type;
      xt_qte_line_dtl          aso_quote_pub.qte_line_dtl_tbl_type;
      xt_hd_price_attributes   aso_quote_pub.price_attributes_tbl_type;
      xt_hd_payment            aso_quote_pub.payment_tbl_type;
      xt_hd_shipment           aso_quote_pub.shipment_tbl_type;
      xr_hd_shipment           aso_quote_pub.shipment_rec_type
                                          := aso_utility_pvt.get_shipment_rec;
      --NEW
      xt_hd_freight_charge     aso_quote_pub.freight_charge_tbl_type;
      xt_hd_tax_detail         aso_quote_pub.tax_detail_tbl_type;
      xt_hd_attr_ext           aso_quote_pub.line_attribs_ext_tbl_type;
      xt_hd_sales_credit       aso_quote_pub.sales_credit_tbl_type;
      xt_hd_quote_party        aso_quote_pub.quote_party_tbl_type;
      xt_line_attr_ext         aso_quote_pub.line_attribs_ext_tbl_type;
      xt_line_rltship          aso_quote_pub.line_rltship_tbl_type;
      xt_price_adjustment      aso_quote_pub.price_adj_tbl_type;
      xt_price_adj_attr        aso_quote_pub.price_adj_attr_tbl_type;
      xt_price_adj_rltship     aso_quote_pub.price_adj_rltship_tbl_type;
      xt_ln_price_attributes   aso_quote_pub.price_attributes_tbl_type;
      xt_ln_payment            aso_quote_pub.payment_tbl_type;
      xt_ln_shipment           aso_quote_pub.shipment_tbl_type;
      xt_ln_freight_charge     aso_quote_pub.freight_charge_tbl_type;
      xt_ln_tax_detail         aso_quote_pub.tax_detail_tbl_type;
      xt_ln_sales_credit       aso_quote_pub.sales_credit_tbl_type;
      xt_ln_quote_party        aso_quote_pub.quote_party_tbl_type;
      ln_line_tbl_idx          NUMBER;
      l_return_status          VARCHAR2 (1);
      l_msg_count              NUMBER;
      l_msg_data               VARCHAR2 (2000);

      l_user_id                NUMBER := FND_GLOBAL.USER_ID;
      l_resp_id                NUMBER := FND_GLOBAL.RESP_ID;
      l_resp_appl_id           NUMBER := FND_GLOBAL.RESP_APPL_ID;

      l_org_id                 NUMBER;
      l_msg_index_out          NUMBER;
      l_msg                    VARCHAR2(2000);
      l_last_update_date       DATE;
      l_line_last_update       DATE;
      l_line_list_price        NUMBER;
      l_line_adjusted_percent  NUMBER;
      l_line_adjusted_amount   NUMBER;
      l_line_quote_price       NUMBER;

      CURSOR c_quote_hdr (cp_quote_header_id NUMBER)
      IS
         SELECT last_update_date
           FROM aso_quote_headers_all
          WHERE quote_header_id = cp_quote_header_id;

      CURSOR c_quote_line (cp_quote_line_id NUMBER)
      IS
         SELECT last_update_date, line_list_price
           FROM aso_quote_lines_all
          WHERE quote_line_id = cp_quote_line_id;

   BEGIN
       mo_global.set_policy_context('S',p_org_id);
       --mo_global.init('ASO');
       fnd_global.apps_initialize(user_id      => l_user_id,
                                  resp_id      => l_resp_id,
                                  resp_appl_id => l_resp_appl_id);

      ln_line_tbl_idx := 1;
      --l_quote_header_id := p_quote_header_id;
      --l_quote_line_id := p_quote_line_id;

       OPEN c_quote_hdr (lr_qte_header.quote_header_id);
      FETCH c_quote_hdr
       INTO l_last_update_date;
      CLOSE c_quote_hdr;

       OPEN c_quote_line(p_quote_line_id);
      FETCH c_quote_line
       INTO l_line_last_update, l_line_list_price;
      CLOSE c_quote_line;

      lr_qte_header.quote_header_id := p_quote_header_id;
      lr_qte_header.last_update_date := l_last_update_date;
      lr_control.last_update_date := l_last_update_date;

      lt_qte_line (ln_line_tbl_idx).operation_code := 'UPDATE';
      lt_qte_line (ln_line_tbl_idx).quote_header_id := p_quote_header_id;
      lt_qte_line (ln_line_tbl_idx).quote_line_id := p_quote_line_id;
      lt_qte_line (ln_line_tbl_idx).selling_price_change := 'Y';
      lt_qte_line (ln_line_tbl_idx).last_update_date := l_last_update_date;--l_line_last_update;

      IF p_discount IS NOT NULL THEN
         l_line_adjusted_percent := p_discount*-1;
         l_line_adjusted_amount := l_line_list_price*(l_line_adjusted_percent/100);
         l_line_quote_price := l_line_list_price + l_line_adjusted_amount;
      END IF;
      IF p_selling_price IS NOT NULL THEN
         l_line_quote_price := p_selling_price;
         l_line_adjusted_amount := l_line_quote_price - l_line_list_price;
         l_line_adjusted_percent := (l_line_adjusted_amount/l_line_list_price)*100;
      END IF;

      lt_qte_line (ln_line_tbl_idx).line_adjusted_percent := l_line_adjusted_percent;
      lt_qte_line (ln_line_tbl_idx).line_adjusted_amount := l_line_adjusted_amount;
      lt_qte_line (ln_line_tbl_idx).line_quote_price := l_line_quote_price;

      aso_quote_pub.update_quote
                         (p_api_version_number           => 1.0,
                          p_init_msg_list                => fnd_api.g_true,
                          p_commit                       => fnd_api.g_false,
                          p_validation_level             => fnd_api.g_valid_level_full,
                          p_control_rec                  => lr_control,
                          p_qte_header_rec               => lr_qte_header,
                          p_hd_price_attributes_tbl      => lt_hd_price_attributes,
                          p_hd_payment_tbl               => lt_hd_payment,
                          p_hd_shipment_tbl              => lt_hd_shipment,
                          p_hd_freight_charge_tbl        => lt_hd_freight_charge,
                          p_hd_tax_detail_tbl            => lt_hd_tax_detail,
                          p_hd_attr_ext_tbl              => lt_hd_attr_ext,
                          p_hd_sales_credit_tbl          => lt_hd_sales_credit,
                          p_hd_quote_party_tbl           => lt_hd_quote_party,
                          p_qte_line_tbl                 => lt_qte_line,
                          p_qte_line_dtl_tbl             => lt_qte_line_dtl,
                          p_line_attr_ext_tbl            => lt_line_attr_ext,
                          p_line_rltship_tbl             => lt_line_rltship,
                          p_price_adjustment_tbl         => lt_price_adjustment,
                          p_price_adj_attr_tbl           => lt_price_adj_attr,
                          p_price_adj_rltship_tbl        => lt_price_adj_rltship,
                          p_ln_price_attributes_tbl      => lt_ln_price_attributes,
                          p_ln_payment_tbl               => lt_ln_payment,
                          p_ln_shipment_tbl              => lt_ln_shipment,
                          p_ln_freight_charge_tbl        => lt_ln_freight_charge,
                          p_ln_tax_detail_tbl            => lt_ln_tax_detail,
                          p_ln_sales_credit_tbl          => lt_ln_sales_credit,
                          p_ln_quote_party_tbl           => lt_ln_quote_party,
                          x_qte_header_rec               => xr_qte_header,
                          x_qte_line_tbl                 => xt_qte_line,
                          x_qte_line_dtl_tbl             => xt_qte_line_dtl,
                          x_hd_price_attributes_tbl      => xt_hd_price_attributes,
                          x_hd_payment_tbl               => xt_hd_payment,
                          x_hd_shipment_tbl              => xt_hd_shipment,
                          x_hd_freight_charge_tbl        => xt_hd_freight_charge,
                          x_hd_tax_detail_tbl            => xt_hd_tax_detail,
                          x_hd_attr_ext_tbl              => xt_hd_attr_ext,
                          x_hd_sales_credit_tbl          => xt_hd_sales_credit,
                          x_hd_quote_party_tbl           => xt_hd_quote_party,
                          x_line_attr_ext_tbl            => xt_line_attr_ext,
                          x_line_rltship_tbl             => xt_line_rltship,
                          x_price_adjustment_tbl         => xt_price_adjustment,
                          x_price_adj_attr_tbl           => xt_price_adj_attr,
                          x_price_adj_rltship_tbl        => xt_price_adj_rltship,
                          x_ln_price_attributes_tbl      => xt_ln_price_attributes,
                          x_ln_payment_tbl               => xt_ln_payment,
                          x_ln_shipment_tbl              => xt_ln_shipment,
                          x_ln_freight_charge_tbl        => xt_ln_freight_charge,
                          x_ln_tax_detail_tbl            => xt_ln_tax_detail,
                          x_ln_sales_credit_tbl          => xt_ln_sales_credit,
                          x_ln_quote_party_tbl           => xt_ln_quote_party,
                          x_return_status                => l_return_status,
                          x_msg_count                    => l_msg_count,
                          x_msg_data                     => l_msg_data
                         );

      IF l_return_status <> fnd_api.g_ret_sts_success
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         x_msg_count := l_msg_count;
         l_msg := NULL;
         FOR i IN 1..x_msg_count
         LOOP
            fnd_msg_pub.get (p_msg_index          => i,
                             p_data               => l_msg_data,
                             p_encoded            => fnd_api.g_false,
                             p_msg_index_out      => l_msg_index_out
                            );
            l_msg := l_msg||l_msg_data;
         END LOOP;
         x_msg_data := l_msg;
      ELSE
         x_return_status := fnd_api.g_ret_sts_success;
         --COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_msg_data := SQLERRM;
         x_return_status := fnd_api.g_ret_sts_error;
   END update_quote_line;
   --Main function
   FUNCTION create_quote_line_new
                                ( p_quote_num        IN  NUMBER,
                                  p_quote_name       IN  VARCHAR2,
                                  p_cust_name        IN  VARCHAR2,
                                  p_qline_item       IN  VARCHAR2,
                                  p_quantity         IN  NUMBER,
                                  p_selling_price    IN  NUMBER,
                                  p_discount         IN  NUMBER
                                )
   RETURN VARCHAR2
   IS
      l_msg_data       VARCHAR2(32000);
      l_return_status  VARCHAR2(1);
      l_msg_count      NUMBER;

      l_inventory_item_id  NUMBER;
      l_quote_header_id    NUMBER;
      l_quote_line_id      NUMBER;
      l_org_id             NUMBER;
      l_uom_code           VARCHAR2(10);
      l_selling_price      NUMBER;
      l_discount           NUMBER;

   BEGIN

      IF p_selling_price IS NOT NULL AND p_discount IS NOT NULL THEN
         l_msg_data := 'Enter either Selling Price or Discount Price only';
         RETURN l_msg_data;
      END IF;
      --INSERT INTO TEST_QUOTE_ADI VALUES(p_quote_num,p_qline_item,p_quantity,p_selling_price,p_discount,'ST');
      IF p_quote_num IS NOT NULL AND p_qline_item IS NOT NULL AND p_quantity IS NOT NULL THEN
         BEGIN
            SELECT inventory_item_id, primary_uom_code
              INTO l_inventory_item_id, l_uom_code
              FROM mtl_system_items_b msib
             WHERE msib.segment1 = p_qline_item
               AND ROWNUM = 1;
          EXCEPTION
          WHEN OTHERS THEN
             l_msg_data := 'Invalid Item: Please Correct Item';
             RETURN l_msg_data;
          END;

         BEGIN
            SELECT quote_header_id, org_id
              INTO l_quote_header_id, l_org_id
              FROM aso_quote_headers_all aqh
             WHERE aqh.quote_number = p_quote_num;
          EXCEPTION
          WHEN OTHERS THEN
             l_msg_data := 'Error while fetching Quote Details';
             RETURN l_msg_data;
          END;

         create_quote_line( l_msg_data
                           ,l_msg_count
                           ,l_return_status
                           ,l_quote_line_id
                           ,l_quote_header_id
                           ,l_org_id
                           ,l_inventory_item_id
                           ,p_quantity
                           ,l_uom_code
                           );

         IF l_return_status <> fnd_api.g_ret_sts_success
         THEN
            l_msg_data := 'Error while creating Quote Line: '||l_msg_data;
            RETURN l_msg_data;
         ELSE
            l_msg_data := NULL;
            dbms_output.put_line('Line Id Created: '||l_quote_line_id);
            BEGIN
               SELECT quote_line_id, line_quote_price
                 INTO l_quote_line_id, l_selling_price
                 FROM aso_quote_lines_all asl
                WHERE asl.quote_line_id = ( SELECT MAX(quote_line_id)
                                              FROM aso_quote_lines_all asl2
                                             WHERE asl2.quote_header_id = l_quote_header_id
                                               AND asl2.inventory_item_id = l_inventory_item_id );
            EXCEPTION
               WHEN OTHERS THEN
               l_quote_line_id := NULL;
               l_selling_price := NULL;
            END;
         END IF;

         IF p_selling_price IS NOT NULL OR p_discount IS NOT NULL AND l_quote_line_id IS NOT NULL THEN
            --INSERT INTO TEST_QUOTE_ADI VALUES(l_quote_line_id,p_qline_item,p_quantity,l_selling_price,l_discount,'BU');
            update_quote_line( l_msg_data
                              ,l_msg_count
                              ,l_return_status
                              ,l_quote_header_id
                              ,l_org_id
                              ,l_quote_line_id
                              ,p_selling_price
                              ,p_discount
                             );
            IF l_return_status <> fnd_api.g_ret_sts_success
            THEN
               l_msg_data := 'Error while Updating Quote Line: '||l_msg_data;
               RETURN l_msg_data;
            ELSE
               l_msg_data := NULL;
               COMMIT;
            END IF;
         END IF;
      END IF;

      RETURN l_msg_data;
   EXCEPTION
      WHEN OTHERS THEN
         l_msg_data := 'Error inside create_quote_line_new';
         RETURN l_msg_data;
   END create_quote_line_new;

END xx_intg_quote_line_pkg;
/
