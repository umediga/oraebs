DROP PACKAGE BODY APPS.XX_OM_SHIP_MANIFESTINV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xx_om_ship_manifestinv_pkg
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 16-May-2012
 File Name     : XX_OM_SHIP_MANIFESTIN_INT.pkb
 Description   : This script creates the specification of the package
                 xx_om_ship_manifest_pkg
 Change History:
 Date          Name                  Remarks
 -----------   -------------         -----------------------------------
 16-May-2012   Renjith               Initial Version
 10-Aug-2012   Renjith               Added currency_code_in as per CR#297463
 17-Aug-2012   Renjith               Added condition to prevent null value
                                     update at delivery level.
 29-Sep-2012   Renjith               Added error handling for user exceptions
 01-Oct-2012   Renjith               Added new fields to update at delivery level
 24-Jul-2013   Renjith               Added org, inv org and delay parameters
                                     for processing
*/
----------------------------------------------------------------------
   x_user_id          NUMBER := FND_GLOBAL.USER_ID;
   x_resp_id          NUMBER := FND_GLOBAL.RESP_ID;
   x_resp_appl_id     NUMBER := FND_GLOBAL.RESP_APPL_ID;
   x_login_id         NUMBER := FND_GLOBAL.LOGIN_ID;
   x_request_id       NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
----------------------------------------------------------------------

   PROCEDURE apps_init( x_return_status     OUT  VARCHAR2
                       ,x_error_msg         OUT  VARCHAR2)
   IS
       x_user_error       EXCEPTION;
   BEGIN
       mo_global.init('ONT');
       fnd_global.apps_initialize(user_id      => x_user_id,
                                  resp_id      => x_resp_id,
                                  resp_appl_id => x_resp_appl_id);

   EXCEPTION
      WHEN OTHERS THEN
          x_return_status := 'E';
          x_error_msg     := 'Procedure apps_init -> Apps Itialization Failed Unexpected Error'||SQLERRM;
   END apps_init;

----------------------------------------------------------------------

   PROCEDURE ship_confirm( p_organization_id     IN     NUMBER
                          ,p_delivery_name       IN     VARCHAR2
                          ,p_delivery_id         IN     NUMBER
                          ,x_return_status       OUT    VARCHAR2
                          ,x_error_msg           OUT    VARCHAR2)
   IS
      CURSOR c_ship_param
      IS
      SELECT  ship_confirm_rule_id,delivery_report_set_id
        FROM  wsh_shipping_parameters
       WHERE  organization_id = p_organization_id;

      x_del_error             EXCEPTION;
      x_rule_error            EXCEPTION;
      x_ret_status            VARCHAR2(1);
      x_msg_count             NUMBER;
      x_msg_data              VARCHAR2(3000);
      x_msg_details           VARCHAR2(3000);
      x_msg_summary           VARCHAR2(3000);

      x_action_code           VARCHAR2(15) := 'CONFIRM';
      x_asg_trip_id           NUMBER;
      x_asg_trip_name         VARCHAR2(30);
      x_asg_pickup_stop_id    NUMBER;
      x_asg_pickup_loc_id     NUMBER;
      x_asg_pickup_loc_code   VARCHAR2(30);
      x_asg_pickup_arr_date   DATE;
      x_asg_pickup_dep_date   DATE;
      x_asg_dropoff_stop_id   NUMBER;
      x_asg_dropoff_loc_id    NUMBER;
      x_asg_dropoff_loc_code  VARCHAR2(30);
      x_asg_dropoff_arr_date  DATE;
      x_asg_dropoff_dep_date  DATE;
      x_sc_action_flag        VARCHAR2(10) := 'S';
      x_sc_close_trip_flag    VARCHAR2(10);-- := 'Y';
      x_sc_create_bol_flag    VARCHAR2(10);
      x_sc_stage_del_flag     VARCHAR2(10);--:= 'N';
      x_sc_defer_interface_flag VARCHAR2(10);--:= 'N';
      x_sc_trip_ship_method   VARCHAR2(30);
      x_sc_actual_dep_date    VARCHAR2(30);
      x_sc_report_set_id      NUMBER;
      x_sc_report_set_name    VARCHAR2(60);
      x_wv_override_flag      VARCHAR2(10);

      x_trip_id               VARCHAR2(30);
      x_trip_name             VARCHAR2(30);
      x_sc_rule_id            NUMBER;
      x_ship_rule_name        VARCHAR2(100);

   BEGIN
      OPEN c_ship_param;
      FETCH c_ship_param INTO x_sc_rule_id,x_sc_report_set_id;
      IF c_ship_param%NOTFOUND THEN
         RAISE x_del_error;
      END IF;
      CLOSE c_ship_param;

      IF x_sc_rule_id IS NULL THEN
        RAISE x_rule_error;
      END IF;
      WSH_DELIVERIES_PUB.DELIVERY_ACTION
          ( p_api_version_number      => 1.0
           ,p_init_msg_list           => FND_API.G_TRUE
           ,x_return_status           => x_ret_status
           ,x_msg_count               => x_msg_count
           ,x_msg_data                => x_msg_data
           ,p_action_code             => x_action_code
           ,p_delivery_id             => p_delivery_id
           ,p_delivery_name           => p_delivery_name
           ,p_asg_trip_id             => x_asg_trip_id
           ,p_asg_trip_name           => x_asg_trip_name
           ,p_asg_pickup_stop_id      => x_asg_pickup_stop_id
           ,p_asg_pickup_loc_id       => x_asg_pickup_loc_id
           ,p_asg_pickup_loc_code     => x_asg_pickup_loc_code
           ,p_asg_pickup_arr_date     => x_asg_pickup_arr_date
           ,p_asg_pickup_dep_date     => x_asg_pickup_dep_date
           ,p_asg_dropoff_stop_id     => x_asg_dropoff_stop_id
           ,p_asg_dropoff_loc_id      => x_asg_dropoff_loc_id
           ,p_asg_dropoff_loc_code    => x_asg_dropoff_loc_code
           ,p_asg_dropoff_arr_date    => x_asg_dropoff_arr_date
           ,p_asg_dropoff_dep_date    => x_asg_dropoff_dep_date
           ,p_sc_action_flag          => x_sc_action_flag
           ,p_sc_close_trip_flag      => x_sc_close_trip_flag
           ,p_sc_defer_interface_flag => x_sc_defer_interface_flag
           ,p_sc_create_bol_flag      => x_sc_create_bol_flag
           ,p_sc_stage_del_flag       => x_sc_stage_del_flag
           ,p_sc_trip_ship_method     => x_sc_trip_ship_method
           ,p_sc_actual_dep_date      => x_sc_actual_dep_date
           ,p_sc_report_set_id        => x_sc_report_set_id
           ,p_sc_report_set_name      => x_sc_report_set_name
           ,p_wv_override_flag        => x_wv_override_flag
           ,p_sc_rule_id              => x_sc_rule_id
           ,x_trip_id                 => x_trip_id
           ,x_trip_name               => x_trip_name);

       IF (x_ret_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN
          RAISE x_del_error;
       END IF;
       COMMIT;
   EXCEPTION
      WHEN x_rule_error THEN
           x_return_status := 'E';
           x_error_msg     := 'Ship Confirm Rule is not defined ';
      WHEN x_del_error THEN

           WSH_UTIL_CORE.get_messages( 'Y'
                                      ,x_msg_summary
                                      ,x_msg_details
                                      ,x_msg_count);
           IF x_msg_count > 1 THEN
              x_msg_data := x_msg_summary || x_msg_details;
           ELSE
              x_msg_data := x_msg_summary;
           END IF;
           x_return_status := 'E';
           x_error_msg     := 'Ship_confirm -> API Error '||x_msg_data||' ';
   WHEN OTHERS THEN
      x_return_status := 'E';
      x_error_msg     := 'Procedure ship_confirm -> Unexpected Error'||SQLERRM;
      FND_FILE.PUT_LINE( FND_FILE.LOG,x_error_msg);
   END ship_confirm;
----------------------------------------------------------------------

   PROCEDURE delivery_update( p_delivery_name       IN     VARCHAR2
                             ,p_waybill             IN     VARCHAR2
                             ,p_shipping_method     IN     VARCHAR2
                             ,p_net_weight          IN     NUMBER
                             ,p_weight_uom_code     IN     VARCHAR2
                             ,p_volume              IN     NUMBER
                             ,p_volume_uom_code     IN     VARCHAR2
                             ,p_number_of_lpn       IN     NUMBER
                             ,x_return_status       OUT    VARCHAR2
                             ,x_error_msg           OUT    VARCHAR2)
   IS
      x_del_error             EXCEPTION;
      x_ret_status            VARCHAR2(1);
      x_msg_count             NUMBER;
      x_msg_data              VARCHAR2(3000);
      x_delivery_info         wsh_deliveries_pub.delivery_pub_rec_type;
      x_del_id                NUMBER;
      x_del_name              VARCHAR2(30);

      CURSOR c_uom( p_uom_class VARCHAR2
                   ,p_uom_code  VARCHAR2)
      IS
      SELECT uom_code
        FROM mtl_uom_conversions
       WHERE uom_class = p_uom_class
         AND uom_code  = p_uom_code;
      x_uom_code VARCHAR2(3);
   BEGIN
      IF p_shipping_method IS NOT NULL THEN
         x_delivery_info.ship_method_code := p_shipping_method;
      END IF;

      IF p_waybill IS NOT NULL THEN
         x_delivery_info.waybill := p_waybill;
      END IF;

      x_delivery_info.net_weight      := p_net_weight;

      x_uom_code := NULL;
      IF p_net_weight IS NOT NULL THEN
         IF p_weight_uom_code IS NULL THEN
            x_delivery_info.weight_uom_code := 'LB';
         ELSE
           OPEN c_uom('Weight',p_weight_uom_code);
           FETCH c_uom INTO x_uom_code;
           IF c_uom%NOTFOUND THEN
              x_uom_code := 'LB';
           END IF;
           CLOSE c_uom;
           x_delivery_info.weight_uom_code := x_uom_code;
         END IF;
      END IF;

      x_delivery_info.volume := p_volume;

      x_uom_code := NULL;
      IF p_volume IS NOT NULL THEN
         IF p_volume_uom_code IS NULL THEN
            x_delivery_info.volume_uom_code := 'IN3';
         ELSE
           OPEN c_uom('Volume',p_volume_uom_code);
           FETCH c_uom INTO x_uom_code;
           IF c_uom%NOTFOUND THEN
              x_uom_code := 'IN3';
           END IF;
           CLOSE c_uom;
            x_delivery_info.volume_uom_code := x_uom_code;
         END IF;
      END IF;

      x_delivery_info.number_of_lpn := p_number_of_lpn;

      WSH_DELIVERIES_PUB.CREATE_UPDATE_DELIVERY
           ( p_api_version_number => 1.0
            ,p_init_msg_list      => FND_API.G_TRUE
            ,x_return_status      => x_ret_status
            ,x_msg_count          => x_msg_count
            ,x_msg_data           => x_msg_data
            ,p_action_code        => 'UPDATE'
            ,p_delivery_info      => x_delivery_info
            ,p_delivery_name      => p_delivery_name
            ,x_delivery_id        => x_del_id
            ,x_name               => x_del_name);

      IF (x_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) OR x_msg_data IS NOT NULL THEN
         RAISE x_del_error;
      END IF;
      COMMIT;
   EXCEPTION
      WHEN x_del_error THEN
         x_return_status := 'E';
         x_error_msg     := 'Delivery_update -> API Error '||x_msg_data||' ';
         FND_FILE.PUT_LINE( FND_FILE.LOG,x_error_msg);
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_error_msg     := 'Procedure delivery_update -> Unexpected Error'||SQLERRM;
         FND_FILE.PUT_LINE( FND_FILE.LOG,x_error_msg);
   END delivery_update;
----------------------------------------------------------------------

   PROCEDURE freight_cost( p_delivery_id         IN     NUMBER
                          ,p_cost                IN     NUMBER
                          ,p_charge_cost         IN     NUMBER
                          ,p_currency            IN     VARCHAR2
                          ,p_cost_type           IN     VARCHAR2
                          ,x_return_status       OUT    VARCHAR2
                          ,x_error_msg           OUT    VARCHAR2)

   IS
      CURSOR c_fr(p_name VARCHAR2)
      IS
      SELECT freight_cost_type_id
        FROM wsh_freight_cost_types
       WHERE name = p_name;

      x_freight_cost          wsh_freight_costs_pub.pubfreightcostrectype;
      x_freight_cost_id       NUMBER;
      x_del_error             EXCEPTION;
      x_ret_status            VARCHAR2(1);
      x_msg_count             NUMBER;
      x_msg_data              VARCHAR2(3000);
      x_fr_type_id            NUMBER := NULL;
      x_fr_type               VARCHAR2(60) := NULL;
      x_fr_error              EXCEPTION;
   BEGIN
      IF p_cost_type = 'FREIGHT' THEN
         xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXOMSHIPPINGIN'
                                                    ,p_param_name      => 'FREIGHT_COST_TYPE'
                                                    ,x_param_value     => x_fr_type);
         OPEN c_fr(x_fr_type);
         FETCH c_fr INTO x_fr_type_id;
         IF c_fr%NOTFOUND THEN
            RAISE x_fr_error;
         END IF;
         CLOSE c_fr;
      ELSIF p_cost_type = 'INSURANCE' THEN
         xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXOMSHIPPINGIN'
                                                    ,p_param_name      => 'INSURANCE_COST_TYPE'
                                                    ,x_param_value     => x_fr_type);
         OPEN c_fr(x_fr_type);
         FETCH c_fr INTO x_fr_type_id;
         IF c_fr%NOTFOUND THEN
            RAISE x_fr_error;
         END IF;
         CLOSE c_fr;
      END IF;

      x_freight_cost.freight_cost_type_id := x_fr_type_id;
      x_freight_cost.unit_amount          := p_cost;
      x_freight_cost.attribute1           := p_charge_cost;
      --x_freight_cost.currency_code        := 'USD';
      x_freight_cost.currency_code        := p_currency;
      x_freight_cost.delivery_id          := p_delivery_id;

      WSH_FREIGHT_COSTS_PUB.Create_Update_Freight_Costs
           ( p_api_version_number   => 1.0
            ,p_init_msg_list        => FND_API.G_TRUE
            ,p_commit               => FND_API.G_FALSE
            ,x_return_status        => x_ret_status
            ,x_msg_count            => x_msg_count
            ,x_msg_data             => x_msg_data
            ,p_pub_freight_costs    => x_freight_cost
            ,p_action_code          => 'CREATE'
            ,x_freight_cost_id      => x_freight_cost_id);

      IF (x_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) OR x_msg_data IS NOT NULL THEN
         RAISE x_del_error;
      END IF;
   EXCEPTION
      WHEN x_fr_error THEN
         x_return_status := 'E';
         x_error_msg     := 'Freight_cost -> Freight Cost Type Not Defined in Process setform';
         FND_FILE.PUT_LINE( FND_FILE.LOG,x_error_msg);
      WHEN x_del_error THEN
         x_return_status := 'E';
         x_error_msg     := 'Freight_cost -> API Error '||x_msg_data||' ';
         FND_FILE.PUT_LINE( FND_FILE.LOG,x_error_msg);
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_error_msg     := 'Procedure Freight_cost -> Unexpected Error'||SQLERRM;
         FND_FILE.PUT_LINE( FND_FILE.LOG,x_error_msg);
   END freight_cost;

----------------------------------------------------------------------

   PROCEDURE header_modifer( p_header_id           IN     NUMBER
                            ,p_freight_charge      IN     NUMBER
                            ,x_return_status       OUT    VARCHAR2
                            ,x_error_msg           OUT    VARCHAR2)

   IS

       CURSOR c_charge(p_desc VARCHAR2)
       IS
       SELECT  h.list_header_id,l.list_line_id,l.list_line_type_code,l.operand,l.modifier_level_code,l.charge_type_code
         FROM  qp_secu_list_headers_vl h,qp_modifier_summary_v l
        WHERE  h.list_header_id = l.list_header_id
          AND  h.description = p_desc;

       x_charge_error  EXCEPTION;

       x_ret_status               VARCHAR2(30);
       x_msg_data                 VARCHAR2(256);
       x_msg_count                NUMBER;

       x_header_rec               oe_order_pub.header_rec_type ;
       x_header_val_rec           oe_order_pub.header_val_rec_type ;
       x_line_tbl                 oe_order_pub.line_tbl_type;
       x_line_val_tbl             oe_order_pub.line_val_tbl_type;
       x_header_adj_tbl           oe_order_pub.header_adj_tbl_type ;
       x_header_adj_val_tbl       oe_order_pub.header_adj_val_tbl_type ;
       x_header_price_att_tbl     oe_order_pub.header_price_att_tbl_type;
       x_header_adj_assoc_tbl     oe_order_pub.header_adj_assoc_tbl_type;
       x_header_scredit_tbl       oe_order_pub.header_scredit_tbl_type;
       x_header_scredit_val_tbl   oe_order_pub.header_scredit_val_tbl_type;
       x_header_adj_att_tbl       oe_order_pub.header_adj_att_tbl_type;
       x_line_adj_tbl             oe_order_pub.line_adj_tbl_type;
       x_line_adj_val_tbl         oe_order_pub.line_adj_val_tbl_type;
       x_line_price_att_tbl       oe_order_pub.line_price_att_tbl_type;
       x_line_adj_att_tbl         oe_order_pub.line_adj_att_tbl_type ;
       x_line_adj_assoc_tbl       oe_order_pub.line_adj_assoc_tbl_type;
       x_line_scredit_tbl         oe_order_pub.line_scredit_tbl_type;
       x_line_scredit_val_tbl     oe_order_pub.line_scredit_val_tbl_type;
       x_line_price_att_rec       oe_order_pub.line_price_att_rec_type;
       x_lot_serial_tbl           oe_order_pub.lot_serial_tbl_type;
       x_lot_serial_val_tbl       oe_order_pub.lot_serial_val_tbl_type;
       x_request_tbl              oe_order_pub.request_tbl_type ;
       x_header_adj               oe_order_pub.header_adj_tbl_type;

       x_list_header_id           NUMBER;
       x_list_line_id             NUMBER;
       x_list_line_type_code      VARCHAR2(30);
       x_operand                  NUMBER;
       x_modifier_level_code      VARCHAR2(30);
       x_charge_type_code         VARCHAR2(30);
       x_modifier                 VARCHAR2(60);
   BEGIN

       xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXOMSHIPPINGIN'
                                                  ,p_param_name      => 'HEADER_MODIFER'
                                                  ,x_param_value     => x_modifier
                                                 );
       -- 'ILS Header Freight'
       OPEN c_charge(x_modifier);
       FETCH c_charge INTO x_list_header_id,x_list_line_id,x_list_line_type_code,x_operand,x_modifier_level_code,x_charge_type_code;
       IF c_charge%NOTFOUND THEN
          RAISE x_charge_error;
       END IF;
       CLOSE c_charge;

       x_header_adj := Oe_Order_Pub.G_MISS_HEADER_ADJ_TBL;
       x_header_adj(1).header_id           := p_header_id;
       x_header_adj(1).automatic_flag      :='N';
       x_header_adj(1).list_header_id      := x_list_header_id;
       x_header_adj(1).list_line_id        := x_list_line_id;
       x_header_adj(1).list_line_type_code := x_list_line_type_code;
       x_header_adj(1).change_reason_code  :='MANUAL';
       x_header_adj(1).change_reason_text  :='Freight Charge from Manifest';
       x_header_adj(1).updated_flag        :='Y';
       x_header_adj(1).applied_flag        :='Y';
       x_header_adj(1).operand             := x_operand;

       x_header_adj(1).charge_type_code    := x_charge_type_code;
       x_header_adj(1).modifier_level_code := x_modifier_level_code;
       x_header_adj(1).adjusted_amount     := p_freight_charge;
       x_header_adj(1).operation           := OE_GLOBALS.G_OPR_CREATE;

       OE_ORDER_PUB.PROCESS_ORDER
         ( p_api_version_number     => 1.0
          ,p_init_msg_list          => FND_API.G_FALSE
          ,p_return_values          => FND_API.G_FALSE
          ,p_action_commit          => FND_API.G_FALSE
          ,p_header_rec             => x_header_rec
          ,p_header_val_rec         => x_header_val_rec
          ,p_line_tbl               => x_line_tbl
          ,p_line_adj_tbl           => x_line_adj_tbl
          ,p_line_scredit_tbl       => x_line_scredit_tbl
          ,p_Header_Adj_tbl         => x_header_adj
          ,x_return_status          => x_ret_status
          ,x_msg_count              => x_msg_count
          ,x_msg_data               => x_msg_data
          ,x_header_rec             => x_header_rec
          ,x_header_val_rec         => x_header_val_rec
          ,x_header_adj_tbl         => x_header_adj_tbl
          ,x_header_adj_val_tbl     => x_header_adj_val_tbl
          ,x_header_price_att_tbl   => x_header_price_att_tbl
          ,x_header_adj_att_tbl     => x_header_adj_att_tbl
          ,x_header_adj_assoc_tbl   => x_header_adj_assoc_tbl
          ,x_header_scredit_tbl     => x_header_scredit_tbl
          ,x_header_scredit_val_tbl => x_header_scredit_val_tbl
          ,x_line_tbl               => x_line_tbl
          ,x_line_val_tbl           => x_line_val_tbl
          ,x_line_adj_tbl           => x_line_adj_tbl
          ,x_line_adj_val_tbl       => x_line_adj_val_tbl
          ,x_line_price_att_tbl     => x_line_price_att_tbl
          ,x_line_adj_att_tbl       => x_line_adj_att_tbl
          ,x_line_adj_assoc_tbl     => x_line_adj_assoc_tbl
          ,x_line_scredit_tbl       => x_line_scredit_tbl
          ,x_line_scredit_val_tbl   => x_line_scredit_val_tbl
          ,x_lot_serial_tbl         => x_lot_serial_tbl
          ,x_lot_serial_val_tbl     => x_lot_serial_val_tbl
          ,x_action_request_tbl     => x_request_tbl
         );

       IF x_ret_status = FND_API.G_RET_STS_SUCCESS THEN
          COMMIT;
          DBMS_OUTPUT.put_line ('Order Header Updation Success ');
       ELSE
          DBMS_OUTPUT.put_line ('Order Header Updation failed:'||x_msg_data);
          ROLLBACK;
          FOR i IN 1 .. x_msg_count    LOOP
            x_msg_data := oe_msg_pub.get( p_msg_index => i
                                        , p_encoded   => 'F');
            dbms_output.put_line( i|| ') '|| x_msg_data);
            x_error_msg := x_error_msg ||'-'||x_msg_data;
          END LOOP;
       END IF;

   EXCEPTION
      WHEN x_charge_error THEN
         x_return_status := 'E';
         x_error_msg     := 'Modifier '||x_modifier||' is not defined';
         FND_FILE.PUT_LINE( FND_FILE.LOG,x_error_msg);
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_error_msg     := 'Procedure header_modifer -> Unexpected Error'||SQLERRM;
         FND_FILE.PUT_LINE( FND_FILE.LOG,x_error_msg);
   END header_modifer;
----------------------------------------------------------------------

   PROCEDURE table_update( p_org_id          IN   NUMBER
                          ,p_organization    IN   NUMBER
                          ,p_delivery_id     IN   NUMBER
                          ,x_return_status   OUT  VARCHAR2
                          ,x_error_msg       OUT  VARCHAR2)
   IS
      CURSOR c_header
      IS
      SELECT  oeh.header_id,oeh.order_number,del.delivery_number,oeh.org_id,del.organization_id
        FROM  xx_om_ship_manifest_v del
             ,oe_order_headers_all oeh
       WHERE  oeh.header_id     = del.header_id
        AND   del.delivery_id   = p_delivery_id
        AND   ROWNUM = 1;

       x_header     c_header%ROWTYPE;
       x_ship_count NUMBER := 0;
       x_del_error  EXCEPTION;
       PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      SELECT  COUNT(*)
        INTO  x_ship_count
        FROM  xx_om_ship_manifest
       WHERE  delivery_id = p_delivery_id
         AND  delivery_id IN (SELECT  delivery_id
                                FROM  xx_om_ship_manifest
                               WHERE  delivery_id = p_delivery_id
                                 AND  NVL(process_flag,'X') = 'Y');

      IF NVL(x_ship_count,0) > 0 THEN
         UPDATE  xx_om_ship_manifest
            SET  process_flag      = 'D'
                ,last_update_date  = SYSDATE
                ,last_updated_by   = x_user_id
                ,last_update_login = x_login_id
                ,request_id        = x_request_id
          WHERE  delivery_id       = p_delivery_id
            AND  process_flag IS NULL;
      END IF;
      COMMIT;

      OPEN c_header;
      FETCH c_header INTO x_header;
      IF c_header%NOTFOUND THEN
         RAISE x_del_error;
      END IF;
      CLOSE c_header;

      UPDATE  xx_om_ship_manifest
         SET  org_id          = x_header.org_id
             ,organization_id = x_header.organization_id
             ,header_id       = x_header.header_id
             ,order_number    = x_header.order_number
             ,delivery_number = x_header.delivery_number
             ,created_by      = x_user_id
             ,request_id      = x_request_id
       WHERE  delivery_id     = p_delivery_id
         AND  NVL(process_flag,'X') <> 'Y' ;
      COMMIT;

      x_ship_count := 0;
      SELECT  COUNT(*)
        INTO  x_ship_count
        FROM  xx_om_ship_manifest
       WHERE  delivery_id = p_delivery_id
         AND  process_flag IS NULL;

      IF NVL(x_ship_count,0) > 1 THEN
         UPDATE  xx_om_ship_manifest
            SET  process_flag     = 'D'
                ,last_update_date = SYSDATE
                ,last_updated_by  = x_user_id
                ,last_update_login = x_login_id
                ,request_id       = x_request_id
          WHERE  delivery_id      = p_delivery_id
            AND  manifest_received_date <> (SELECT  MAX(manifest_received_date)
                                              FROM  xx_om_ship_manifest
                                             WHERE  delivery_id = p_delivery_id);
      END IF;
      COMMIT;
   EXCEPTION
      WHEN x_del_error THEN
         x_return_status := 'E';
         x_error_msg     := 'Delivery Not Found OR Already Processed';
         FND_FILE.PUT_LINE( FND_FILE.LOG,x_error_msg);
   WHEN OTHERS THEN
         x_return_status := 'E';
         x_error_msg     := 'Procedure table_update -> Unexpected Error'||SQLERRM;
         FND_FILE.PUT_LINE( FND_FILE.LOG,x_error_msg);
   END table_update;

-- --------------------------------------------------------------------- --

   PROCEDURE status_update( p_delivery_id     IN    NUMBER
                           ,p_error_code      IN    VARCHAR2
                           ,p_error_message   IN    VARCHAR2)
   IS
   BEGIN
     IF p_error_code = 'E' THEN
        UPDATE  xx_om_ship_manifest
           SET  error_code        = 'E'
               ,process_flag      = 'Y'
               ,error_message     = p_error_message
               ,last_update_date  = SYSDATE
               ,last_updated_by   = x_user_id
               ,last_update_login = x_login_id
               ,request_id        = x_request_id
         WHERE  delivery_id       = p_delivery_id
           AND  NVL(process_flag,'X')  <> 'D';
     ELSE
        UPDATE  xx_om_ship_manifest
           SET  process_flag      = 'Y'
               ,last_update_date  = SYSDATE
               ,last_updated_by   = x_user_id
               ,last_update_login = x_login_id
               ,request_id        = x_request_id
         WHERE  delivery_id       = p_delivery_id
           AND  NVL(process_flag,'X')  <> 'D';
     END IF;
     COMMIT;
   END status_update;
-- --------------------------------------------------------------------- --

   PROCEDURE manifest_update( p_delivery_id         IN     NUMBER
                             ,p_freight_cost        IN     NUMBER
                             ,p_insurance_cost      IN     NUMBER
                             ,p_currency            IN     VARCHAR2
                             ,p_charge_freight_cost IN     NUMBER
                             ,p_freight_charge      IN     NUMBER
                             ,p_waybill             IN     VARCHAR2
                             ,p_ship_method         IN     VARCHAR2
                             ,p_net_weight          IN     NUMBER
                             ,p_weight_uom_code     IN     VARCHAR2
                             ,p_volume              IN     NUMBER
                             ,p_volume_uom_code     IN     VARCHAR2
                             ,p_number_of_lpn       IN     NUMBER
                             ,x_return_status       OUT    VARCHAR2
                             ,x_error_msg           OUT    VARCHAR2)
   IS

      CURSOR c_del(p_del_id  NUMBER)
          IS
       SELECT  DISTINCT ship_created_by,delivery_number,header_id,ship_org_id
         FROM  xx_om_ship_manifest_v
        WHERE  delivery_id = p_del_id;

      CURSOR c_ship (p_ship_method_code VARCHAR2)
      IS
      SELECT  ship_method_code
        FROM  wsh_carrier_services_v
       WHERE  ship_method_meaning  = p_ship_method_code;

      CURSOR c_curr (p_curr_code VARCHAR2)
      IS
      SELECT  currency_code
        FROM  fnd_currencies
       WHERE  currency_code  = p_currency;

      x_del_error             EXCEPTION;
      x_method_error          EXCEPTION;
      x_curr_error            EXCEPTION;
      x_ret_status            VARCHAR2(1);
      x_ship_method           VARCHAR2(30);
      x_header_id             NUMBER;

      x_error_message         VARCHAR(3000);
      x_ship_user             NUMBER;
      x_delivery_number       VARCHAR2(30);
      x_organization_id       NUMBER;
      x_ship_count            NUMBER;
      x_currency_code         VARCHAR2(15);
   BEGIN
      OPEN c_del(p_delivery_id);
      FETCH c_del INTO x_ship_user,x_delivery_number,x_header_id,x_organization_id;
      IF c_del%NOTFOUND THEN
         RAISE x_del_error;
      END IF;
      CLOSE c_del;

      IF p_ship_method IS NOT NULL THEN
         OPEN c_ship(p_ship_method);
         FETCH c_ship INTO x_ship_method;
         IF c_ship%NOTFOUND THEN
            RAISE x_method_error;
         END IF;
         CLOSE c_ship;
      END IF;

      IF p_currency IS NOT NULL THEN
         OPEN c_curr(p_currency);
         FETCH c_curr INTO x_currency_code;
         IF c_curr%NOTFOUND THEN
            RAISE x_curr_error;
         END IF;
         CLOSE c_curr;
      END IF;

      apps_init( x_return_status    => x_ret_status
                ,x_error_msg        => x_error_msg);

      IF NVL(x_ret_status,'X') = 'E' THEN
         x_error_message := x_error_message ||x_error_msg;
         x_return_status := 'E';
      END IF;
      FND_FILE.PUT_LINE( FND_FILE.LOG,'APPS_INIT >>>> x_ret_status -> '||x_ret_status||' '||'x_error_msg ->'||x_error_msg);

      IF NVL(p_freight_charge,0) > 0 THEN
         header_modifer( p_header_id          => x_header_id
                        ,p_freight_charge     => p_freight_charge
                        ,x_return_status      => x_ret_status
                        ,x_error_msg          => x_error_msg);

         IF NVL(x_ret_status,'X') = 'E' THEN
                x_error_message := x_error_message ||x_error_msg;
                x_return_status := 'E';
         END IF;
         FND_FILE.PUT_LINE( FND_FILE.LOG,'HEADER_MODIFER >>>> x_ret_status -> '||x_ret_status||' '||'x_error_msg ->'||x_error_msg);
      END IF;

      IF p_waybill IS NOT NULL OR p_ship_method IS NOT NULL THEN
         delivery_update( p_delivery_name       => x_delivery_number
                         ,p_waybill             => p_waybill
                         ,p_shipping_method     => x_ship_method
                         ,p_net_weight          => p_net_weight
                         ,p_weight_uom_code     => p_weight_uom_code
                         ,p_volume              => p_volume
                         ,p_volume_uom_code     => p_volume_uom_code
                         ,p_number_of_lpn       => p_number_of_lpn
                         ,x_return_status       => x_ret_status
                         ,x_error_msg           => x_error_msg);

         IF NVL(x_ret_status,'X') = 'E' THEN
            x_error_message := x_error_message ||x_error_msg;
            x_return_status := 'E';
         END IF;
         FND_FILE.PUT_LINE( FND_FILE.LOG,'DELIVERY_UPDATE >>>> x_ret_status -> '||x_ret_status||' '||'x_error_msg ->'||x_error_msg);
     END IF;

     IF NVL(p_freight_cost,0) > 0 THEN
        freight_cost( p_delivery_id         => p_delivery_id
                     ,p_cost                => p_freight_cost
                     ,p_charge_cost         => p_charge_freight_cost
                     ,p_currency            => p_currency
                     ,p_cost_type           => 'FREIGHT'
                     ,x_return_status       => x_ret_status
                     ,x_error_msg           => x_error_msg);

        IF NVL(x_ret_status,'X') = 'E' THEN
           x_error_message := x_error_message ||x_error_msg;
           x_return_status := 'E';
        END IF;
        FND_FILE.PUT_LINE( FND_FILE.LOG,'FREIGHT_COST >>>> x_ret_status -> '||x_ret_status||' '||'x_error_msg ->'||x_error_msg);
     END IF;

     IF NVL(p_insurance_cost,0) <> 0 THEN
        freight_cost( p_delivery_id         => p_delivery_id
                     ,p_cost                => p_insurance_cost
                     ,p_charge_cost         => NULL
                     ,p_currency            => p_currency
                     ,p_cost_type           => 'INSURANCE'
                     ,x_return_status       => x_ret_status
                     ,x_error_msg           => x_error_msg);

        IF NVL(x_ret_status,'X') = 'E' THEN
           x_error_message := x_error_message ||x_error_msg;
           x_return_status := 'E';
        END IF;
        FND_FILE.PUT_LINE( FND_FILE.LOG,'INSURANCE_COST >>>> x_ret_status -> '||x_ret_status||' '||'x_error_msg ->'||x_error_msg);
     END IF;


     ship_confirm( p_organization_id => x_organization_id
                  ,p_delivery_name   => x_delivery_number
                  ,p_delivery_id     => p_delivery_id
                  ,x_return_status   => x_ret_status
                  ,x_error_msg       => x_error_msg);

     IF NVL(x_ret_status,'X') = 'E' THEN
        x_error_message := x_error_message ||x_error_msg;
        x_return_status := 'E';
        ROLLBACK;
     ELSE
        UPDATE  xx_om_ship_manifest
           SET  trip_status        = 'Y'
               ,trip_date          = SYSDATE
               ,trip_created_by    = 'MANIFEST'
         WHERE  delivery_id        = p_delivery_id
           AND  NVL(process_flag,'X')  <> 'D';
         COMMIT;
     END IF;
     FND_FILE.PUT_LINE( FND_FILE.LOG,'SHIP_CONFIRM >>>> x_ret_status -> '||x_ret_status||' '||'x_error_msg ->'||x_error_msg);

     status_update( p_delivery_id     => p_delivery_id
                   ,p_error_code      => x_return_status
                   ,p_error_message   => SUBSTR(x_error_message,1,3000));
   EXCEPTION
      WHEN x_del_error THEN
         x_return_status := 'E';
         x_error_msg     := 'Delivery Not Found OR Already Processed';
         FND_FILE.PUT_LINE( FND_FILE.LOG,x_error_msg);
         status_update( p_delivery_id     => p_delivery_id
                       ,p_error_code      => x_return_status
                       ,p_error_message   => x_error_msg);
      WHEN x_curr_error THEN
         x_return_status := 'E';
         x_error_msg     := 'Invalid Currency Code';
         FND_FILE.PUT_LINE( FND_FILE.LOG,x_error_msg);
         status_update( p_delivery_id     => p_delivery_id
                       ,p_error_code      => x_return_status
                       ,p_error_message   => x_error_msg);
      WHEN x_method_error THEN
         x_return_status := 'E';
         x_error_msg     := 'Invalid Ship Method';
         FND_FILE.PUT_LINE( FND_FILE.LOG,x_error_msg);
         status_update( p_delivery_id     => p_delivery_id
                       ,p_error_code      => x_return_status
                       ,p_error_message   => x_error_msg);
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_error_msg     := 'Procedure manifest_update -> Unexpected Error'||SQLERRM;
         FND_FILE.PUT_LINE( FND_FILE.LOG,x_error_msg);
         status_update( p_delivery_id     => p_delivery_id
                       ,p_error_code      => x_return_status
                       ,p_error_message   => x_error_msg);
   END manifest_update;
----------------------------------------------------------------------

   PROCEDURE manifest_inreprocess( p_errbuf            OUT   VARCHAR2
                                  ,p_retcode           OUT   VARCHAR2
                                  ,p_org_id            IN    NUMBER
                                  ,p_organization      IN    NUMBER
                                  ,p_delay             IN    NUMBER
                                  ,p_restart_flag      IN    VARCHAR2
                                  ,p_dummy             IN    VARCHAR2
                                  ,p_header_id         IN    NUMBER
                                  ,p_delivery_id       IN    NUMBER
                                  ,p_date_from         IN    VARCHAR2
                                  ,p_date_to           IN    VARCHAR2)
   IS
     CURSOR c_del
     IS
     SELECT  DISTINCT delivery_id
      FROM   xx_om_ship_manifest
     WHERE   process_flag IS NULL
     ORDER BY delivery_id;


     CURSOR c_rec
     IS
     SELECT  *
       FROM  xx_om_ship_manifest
      WHERE  org_id = NVL(p_org_id,org_id)
        AND  organization_id = NVL(p_organization,organization_id)
        AND  ROUND((sysdate - manifest_received_date)*24*60) > NVL(p_delay,0)
        AND  process_flag IS NULL;

     x_ret_status            VARCHAR2(1);
     x_error_message         VARCHAR(3000);
   BEGIN
     FND_FILE.PUT_LINE( FND_FILE.LOG,'------------------------------------------');
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_org_id        -> '||p_org_id);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_organization  -> '||p_organization);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_delay         -> '||p_delay);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_restart_flag  -> '||p_restart_flag);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_header_id     -> '||p_header_id);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_delivery_id   -> '||p_delivery_id);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_date_from     -> '||p_date_from);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_date_to       -> '||p_date_to);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'------------------------------------------');


     IF NVL(p_restart_flag,'X') <> 'NEWRECS' THEN
        UPDATE  xx_om_ship_manifest
           SET  error_code       = NULL
               ,error_message    = NULL
               ,trip_status      = NULL
               ,trip_date        = NULL
               ,trip_created_by  = NULL
               ,process_flag     = NULL
               ,request_id       = NULL
         WHERE   NVL(error_code,'X') = DECODE(p_restart_flag,'ERRRECS','E',NVL(error_code,'X') )
           AND   header_id   = NVL(p_header_id,header_id)
           AND   org_id = NVL(p_org_id,org_id)
           AND   organization_id = NVL(p_organization,organization_id)
           AND   delivery_id = NVL(p_delivery_id,delivery_id)
           AND   TRUNC(manifest_received_date) BETWEEN NVL(to_date(p_date_from,'YYYY/MM/DD HH24:MI:SS'),TRUNC(manifest_received_date))
           AND   NVL(to_date(p_date_to,'YYYY/MM/DD HH24:MI:SS'),TRUNC(manifest_received_date))
           AND   process_flag = 'Y';
           
        UPDATE xx_om_ship_manifest SET process_flag = 'Y' WHERE delivery_id is null AND process_flag is null;
        
        UPDATE xx_om_ship_manifest xsm SET process_flag = 'Y' 
         WHERE process_flag is null and delivery_id is not null AND header_id is null 
           AND EXISTS (SELECT 'x' FROM wsh_new_deliveries wnd WHERE wnd.delivery_id = xsm.delivery_id AND wnd.status_code = 'CL');
        
        COMMIT;
      ELSE
         FOR del_rec IN c_del LOOP
            table_update( p_org_id         =>  p_org_id
                         ,p_organization   =>  p_organization
                         ,p_delivery_id    =>  del_rec.delivery_id
                         ,x_return_status  =>  x_ret_status
                         ,x_error_msg      =>  x_error_message);
         END LOOP;
      END IF;


      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,LPAD(RPAD('Shipping Manifest Process Report',35),95));
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,LPAD(RPAD('===================================',35),95));
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,RPAD('Delivery Number',18)||' '||RPAD('Order Number',18)||' '||RPAD('Manifest Received Date',28)
                ||' '||RPAD('Freight Cost',18)||' '||RPAD('Insurance Cost',18)||' '||RPAD('Cost Currency',18)||' '||RPAD('Charge Freight Cost',24)
                ||' '||RPAD('Freight Charge',18)||' '||RPAD('Waybill',20)||' '||RPAD('Ship Method',22)||' '||'Error Message');

      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,RPAD('------------------',18)||' '||RPAD('----------------',18)||' '||RPAD('------------------------',28)
      ||' '||RPAD('---------------------',18)||' '||RPAD('---------------------',18)||' '||RPAD('---------------------',18)||' '||RPAD('---------------------',24)
      ||' '||RPAD('---------------------',18)||' '||RPAD('---------------------',20)||' '||RPAD('---------------------',22)||' '||'-----------------');

      FOR r_rec IN c_rec LOOP

            manifest_update(  p_delivery_id         => r_rec.delivery_id
                             ,p_freight_cost        => r_rec.freight_cost_in
                             ,p_insurance_cost      => r_rec.insurance_cost_in
                             ,p_charge_freight_cost => r_rec.charge_freight_cost_in
                             ,p_currency            => NVL(r_rec.currency_code_in,'USD')
                             ,p_freight_charge      => r_rec.freight_charge_in
                             ,p_waybill             => r_rec.waybill
                             ,p_ship_method         => r_rec.ship_method_in
                             ,p_net_weight          => r_rec.net_weight_in
                             ,p_weight_uom_code     => r_rec.weight_uom_code_in
                             ,p_volume              => r_rec.volume_in
                             ,p_volume_uom_code     => r_rec.volume_uom_code_in
                             ,p_number_of_lpn       => r_rec.number_of_lpn_in
                             ,x_return_status       => x_ret_status
                             ,x_error_msg           => x_error_message);

           FND_FILE.PUT_LINE( FND_FILE.OUTPUT,RPAD(NVL(r_rec.delivery_number,' '),18)||' '||RPAD(NVL(TO_CHAR(r_rec.order_number),' '),18)||' '||RPAD(NVL(TO_CHAR(r_rec.manifest_received_date),' '),28)
             ||' '||RPAD(NVL(TO_CHAR(r_rec.freight_cost_in),' '),18)||' '||RPAD(NVL(TO_CHAR(r_rec.insurance_cost_in),' '),18)||' '||RPAD(NVL(r_rec.currency_code_in,' '),18)
             ||' '||RPAD(NVL(TO_CHAR(r_rec.charge_freight_cost_in),' '),24)||' '||RPAD(NVL(TO_CHAR(r_rec.freight_charge_in),' '),18)
             ||' '||RPAD(NVL(r_rec.waybill,' '),20)||' '||RPAD(NVL(r_rec.ship_method_in,' '),22)||' '||x_error_message);

      END LOOP;

      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,LPAD(RPAD('End of the Report',20),80));
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,LPAD(RPAD('=================',20),80));

   EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE( FND_FILE.LOG,'manifest_inprocess -> Erro in Processing '||SQLERRM);
         p_retcode := 2;
   END manifest_inreprocess;

-- --------------------------------------------------------------------- --

   PROCEDURE error_report( p_errbuf            OUT   VARCHAR2
                          ,p_retcode           OUT   VARCHAR2
                          ,p_header_id         IN    NUMBER
                          ,p_delivery_id       IN    NUMBER
                          ,p_date_from         IN    VARCHAR2
                          ,p_date_to           IN    VARCHAR2
                          ,p_status            IN    VARCHAR2
                          )
   IS
     CURSOR c_report1
     IS
     SELECT  *
      FROM   xx_om_ship_manifest
     WHERE   NVL(error_code,'X') = 'E'
       AND   NVL(process_flag,'X') <> 'D'
       AND   header_id = NVL(p_header_id,header_id)
       AND   delivery_id = NVL(p_delivery_id,delivery_id)
       AND   TRUNC(manifest_received_date) BETWEEN NVL(to_date(p_date_from,'YYYY/MM/DD HH24:MI:SS'),TRUNC(manifest_received_date))
       AND   NVL(to_date(p_date_to,'YYYY/MM/DD HH24:MI:SS'),TRUNC(manifest_received_date))
       ORDER BY delivery_id desc;

     CURSOR c_report2
     IS
     SELECT  *
      FROM   xx_om_ship_manifest
     WHERE   header_id = NVL(p_header_id,header_id)
       AND   delivery_id = NVL(p_delivery_id,delivery_id)
       AND   NVL(process_flag,'X') <> 'D'
       ORDER BY delivery_id desc;

   BEGIN
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,LPAD(RPAD(' Shipping Manifest Report',35),90));
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,LPAD(RPAD('===========================',35),95));
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,RPAD('Delivery Number',18)||' '||RPAD('Order Number',18)||' '||RPAD('Manifest Received Date',28)
                    ||' '||RPAD('Freight Cost',18)||' '||RPAD('Insurance Cost',18)||' '||RPAD('Cost Currency',18)||' '||RPAD('Charge Freight Cost',24)
                    ||' '||RPAD('Freight Charge',18)||' '||RPAD('Waybill',20)
                    ||' '||RPAD('Ship Method',22)||' '||RPAD('Error Message',40)
                    ||' '||RPAD('POD Received Date',22)||' '||RPAD('POD Accepted Quantity',28)||' '||RPAD('POD Comments',22)||' '||RPAD('POD Reference Document',28)
                    ||' '||RPAD('POD Signature',22)||' '||RPAD('POD Signature Date',22)||' '||RPAD('POD Error Message',22));

      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,RPAD('------------------',18)||' '||RPAD('----------------',18)||' '||RPAD('------------------------',28)
         ||' '||RPAD('---------------------',18)||' '||RPAD('---------------------',18)||' '||RPAD('---------------------',18)||' '||RPAD('---------------------',24)
         ||' '||RPAD('---------------------',18)||' '||RPAD('---------------------',20)
         ||' '||RPAD('---------------------',22)||' '||RPAD('-----------------',40)
         ||' '||RPAD('-----------------',22)||' '||RPAD('-----------------------',28)||' '||RPAD('-----------------',22)||' '||RPAD('---------------------------',28)
         ||' '||RPAD('-----------------',22)||' '||RPAD('-----------------',22)||' '||RPAD('-----------------',22));

      IF p_status = 'E' THEN
         FOR r_report1 IN c_report1 LOOP
           FND_FILE.PUT_LINE( FND_FILE.OUTPUT,RPAD(r_report1.delivery_number,18)||' '||RPAD(r_report1.order_number,18)||' '||RPAD(r_report1.manifest_received_date,28)
             ||' '||RPAD(r_report1.freight_cost_in,18)||' '||RPAD(r_report1.insurance_cost_in,18)||' '||RPAD(r_report1.currency_code_in,18)||' '||RPAD(r_report1.charge_freight_cost_in,24)
             ||' '||RPAD(r_report1.freight_charge_in,18)||' '||RPAD(r_report1.waybill,20)
             ||' '||RPAD(r_report1.ship_method_in,22)||' '||RPAD(r_report1.error_message,40)
             ||' '||RPAD(r_report1.pod_received_date,22)||' '||RPAD(r_report1.accepted_quantity,28)||' '||RPAD(r_report1.revrec_comments,22)||' '||RPAD(r_report1.revrec_reference_document,28)
             ||' '||RPAD(r_report1.revrec_signature,22)||' '||RPAD(r_report1.revrec_signature_date,22)||' '||RPAD(r_report1.pod_error_message,22));
         END LOOP;
      ELSIF p_status = 'A' THEN
        FOR r_report2 IN c_report2 LOOP
           FND_FILE.PUT_LINE( FND_FILE.OUTPUT,RPAD(r_report2.delivery_number,18)||' '||RPAD(r_report2.order_number,18)||' '||RPAD(r_report2.manifest_received_date,28)
             ||' '||RPAD(r_report2.freight_cost_in,18)||' '||RPAD(r_report2.insurance_cost_in,18)||' '||RPAD(r_report2.currency_code_in,18)||' '||RPAD(r_report2.charge_freight_cost_in,24)
             ||' '||RPAD(r_report2.freight_charge_in,18)||' '||RPAD(r_report2.waybill,20)
             ||' '||RPAD(r_report2.ship_method_in,22)||' '||RPAD(r_report2.error_message,40)
             ||' '||RPAD(r_report2.pod_received_date,22)||' '||RPAD(r_report2.accepted_quantity,28)||' '||RPAD(r_report2.revrec_comments,22)||' '||RPAD(r_report2.revrec_reference_document,28)
             ||' '||RPAD(r_report2.revrec_signature,22)||' '||RPAD(r_report2.revrec_signature_date,22)||' '||RPAD(r_report2.pod_error_message,22));
        END LOOP;
     END IF;

     FND_FILE.PUT_LINE( FND_FILE.OUTPUT,' ');
     FND_FILE.PUT_LINE( FND_FILE.OUTPUT,' ');
     FND_FILE.PUT_LINE( FND_FILE.OUTPUT,' ');
     FND_FILE.PUT_LINE( FND_FILE.OUTPUT,LPAD(RPAD('End of the Report',20),80));
     FND_FILE.PUT_LINE( FND_FILE.OUTPUT,LPAD(RPAD('=================',20),80));
   EXCEPTION
      WHEN OTHERS THEN
         p_retcode := 2;
   END error_report;

----------------------------------------------------------------------


END xx_om_ship_manifestinv_pkg;
/
