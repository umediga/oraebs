DROP PROCEDURE APPS.XX_SHIP_CONFIRM_DELIVERY;

CREATE OR REPLACE PROCEDURE APPS."XX_SHIP_CONFIRM_DELIVERY" (
   v_delivery_name      IN       VARCHAR2,                                                           --  delivery number
   v_action             IN       VARCHAR2,                             -- Pass 'B' to backorder the unspecified quantity
 --  v_sc_actual_dep_date  IN      date,
   p_ship_conf_status   OUT      VARCHAR2,
   x_msg_data           OUT      VARCHAR2
)
IS
   p_api_version_number     NUMBER;
   init_msg_list            VARCHAR2 (30);
   x_msg_count              NUMBER;
   x_msg_details            VARCHAR2 (32000);
   x_msg_summary            VARCHAR2 (32000);
   p_validation_level       NUMBER;
   p_commit                 VARCHAR2 (30);
   x_return_status          VARCHAR2 (15);
   source_code              VARCHAR2 (15);
   changed_attributes       wsh_delivery_details_pub.changedattributetabtype;
   p_action_code            VARCHAR2 (15);
   p_delivery_id            NUMBER;
   p_delivery_name          VARCHAR2 (30);
   p_asg_trip_id            NUMBER;
   p_asg_trip_name          VARCHAR2 (30);
   p_asg_pickup_stop_id     NUMBER;
   p_asg_pickup_loc_id      NUMBER;
   p_asg_pickup_loc_code    VARCHAR2 (30);
   p_asg_pickup_arr_date    DATE;
   p_asg_pickup_dep_date    DATE;
   p_asg_dropoff_stop_id    NUMBER;
   p_asg_dropoff_loc_id     NUMBER;
   p_asg_dropoff_loc_code   VARCHAR2 (30);
   p_asg_dropoff_arr_date   DATE;
   p_asg_dropoff_dep_date   DATE;
   p_sc_action_flag         VARCHAR2 (10);
   p_sc_close_trip_flag     VARCHAR2 (10);
   p_defer_iface            VARCHAR2 (10);
   p_sc_create_bol_flag     VARCHAR2 (10);
   p_sc_stage_del_flag      VARCHAR2 (10);
   p_sc_trip_ship_method    VARCHAR2 (30);
   p_sc_actual_dep_date     VARCHAR2 (30);
   p_sc_report_set_id       NUMBER;
   p_sc_report_set_name     VARCHAR2 (60);
   p_wv_override_flag       VARCHAR2 (10);
   x_trip_id                VARCHAR2 (30);
   x_trip_name              VARCHAR2 (30);
   p_msg_data               VARCHAR2 (32000);
   fail_api                 EXCEPTION;
BEGIN
   x_return_status            := wsh_util_core.g_ret_sts_success;
   p_action_code              := 'CONFIRM';
   p_delivery_name            := v_delivery_name;
   p_sc_action_flag           := v_action; -- 'S' 'C'
   p_sc_close_trip_flag       := 'Y';                   
   p_defer_iface              := 'N';
  -- p_sc_actual_dep_date       := v_sc_actual_dep_date;
   wsh_deliveries_pub.delivery_action (p_api_version_number           => 1.0,
                                       p_init_msg_list                => init_msg_list,
                                       x_return_status                => x_return_status,
                                       x_msg_count                    => x_msg_count,
                                       x_msg_data                     => p_msg_data,
                                       p_action_code                  => p_action_code,
                                       p_delivery_id                  => p_delivery_id,
                                       p_delivery_name                => p_delivery_name,
                                       p_asg_trip_id                  => p_asg_trip_id,
                                       p_asg_trip_name                => p_asg_trip_name,
                                       p_asg_pickup_stop_id           => p_asg_pickup_stop_id,
                                       p_asg_pickup_loc_id            => p_asg_pickup_loc_id,
                                       p_asg_pickup_loc_code          => p_asg_pickup_loc_code,
                                       p_asg_pickup_arr_date          => p_asg_pickup_arr_date,
                                       p_asg_pickup_dep_date          => p_asg_pickup_dep_date,
                                       p_asg_dropoff_stop_id          => p_asg_dropoff_stop_id,
                                       p_asg_dropoff_loc_id           => p_asg_dropoff_loc_id,
                                       p_asg_dropoff_loc_code         => p_asg_dropoff_loc_code,
                                       p_asg_dropoff_arr_date         => p_asg_dropoff_arr_date,
                                       p_asg_dropoff_dep_date         => p_asg_dropoff_dep_date,
                                       p_sc_action_flag               => p_sc_action_flag,
                                       p_sc_close_trip_flag           => p_sc_close_trip_flag,
                                       p_sc_create_bol_flag           => p_sc_create_bol_flag,
                                       p_sc_stage_del_flag            => p_sc_stage_del_flag,
                                       p_sc_trip_ship_method          => p_sc_trip_ship_method,
                                       p_sc_actual_dep_date           => p_sc_actual_dep_date,
                                       p_sc_report_set_id             => p_sc_report_set_id,
                                       p_sc_report_set_name           => p_sc_report_set_name,
                                       p_sc_defer_interface_flag      => p_defer_iface,
                                       p_wv_override_flag             => p_wv_override_flag,
                                       x_trip_id                      => x_trip_id,
                                       x_trip_name                    => x_trip_name
                                      );

   IF (x_return_status != wsh_util_core.g_ret_sts_success)
   THEN
      wsh_util_core.get_messages ('Y', x_msg_summary, x_msg_details, x_msg_count);

      IF x_msg_count > 1
      THEN
         x_msg_data                 := x_msg_summary || x_msg_details;
      ELSE
         x_msg_data                 := x_msg_summary;
      END IF;

      p_ship_conf_status         := 'E';
   ELSE
      p_ship_conf_status         := 'S';
   END IF;
END xx_ship_confirm_delivery; 
/
