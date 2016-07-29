DROP PACKAGE BODY APPS.XXINTG_WMS_RELEASE_BATCH_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_WMS_RELEASE_BATCH_PKG"
AS
   PROCEDURE release_batch (
      errbuf           OUT   VARCHAR2,
      retcode          OUT   VARCHAR2,
      p_order_number         NUMBER,
      p_ship_confirm_flag VARCHAR2
   )
   IS
      x_return_status    VARCHAR2 (100);
      x_msg_count        NUMBER;
      x_msg_data         VARCHAR2 (1000);
      l_batch_id         NUMBER;
      l_pick_status      VARCHAR2 (100);
      l_pick_phase       VARCHAR2 (100);
      l_pick_skip        VARCHAR2 (100);
      x_error_count      NUMBER;
      v_msg_data         VARCHAR2 (4000);
      l_release_status   VARCHAR2 (30);

      CURSOR c_pick_rule
      IS
         SELECT *
           FROM wsh_picking_rules
          WHERE NAME = '150 DC Release';

      c_pick_record      c_pick_rule%ROWTYPE;

--select * from wsh_Ship_Confirm_rules
      CURSOR c_order
      IS
         SELECT DISTINCT wdd.source_header_number order_number,
                         wdd.source_header_type_name,
                         wdd.source_header_id header_id, wdd.released_status
                    FROM wsh_delivery_details wdd
                   --  mtl_material_transactions_temp d1
         WHERE           1 = 1
                     AND wdd.released_status IN ('R', 'B')
                     AND wdd.source_code = 'OE'
                     AND wdd.organization_id = 104
                     AND wdd.source_header_number =
                                NVL (p_order_number, wdd.source_header_number)
                     AND wdd.source_header_type_name =
                                                      'ILS Charge Sheet Order';

      --l_pick_rule        wsh_picking_rules%TYPE;
      l_batch_info_rec   wsh_picking_batches_pub.batch_info_rec;
   BEGIN
      BEGIN
         mo_global.set_policy_context ('S', 101);
         fnd_global.apps_initialize (1154, 21623, 660);

         fnd_file.put_line (fnd_file.LOG, 'Order Number       :'||p_order_number);
         fnd_file.put_line (fnd_file.LOG, 'Ship Confirm Flag  :'||p_ship_confirm_flag);

         IF p_ship_confirm_flag = 'N' THEN
                                          --INTG_SCHEDULE, OM Super User, ONT
         -- Use Order Management Super User , INTG Schedule , Which User?
         OPEN c_pick_rule;

         FETCH c_pick_rule
          INTO c_pick_record;

         CLOSE c_pick_rule;

         fnd_file.put_line (fnd_file.LOG, 'Pick Rule Cursor Complete.');
         fnd_file.put_line (fnd_file.LOG, 'Order Cursor Processing Start.');
         fnd_file.put_line
                 (fnd_file.output,
                  '                                     Batch Release Status'
                 );
         fnd_file.put_line
            (fnd_file.output,
             '--------------------------------------------------------------------------'
            );
         fnd_file.put_line (fnd_file.output, '');
         fnd_file.put_line
                 (fnd_file.output,
                  'Order Number            Batch ID            Release Status'
                 );
         fnd_file.put_line (fnd_file.output, '');

         FOR r_order IN c_order
         LOOP
            l_batch_info_rec.backorders_only_flag :=
                                           c_pick_record.backorders_only_flag;
            l_batch_info_rec.document_set_id := c_pick_record.document_set_id;
            l_batch_info_rec.document_set_name := c_pick_record.NAME;
            l_batch_info_rec.existing_rsvs_only_flag :=
                                        c_pick_record.existing_rsvs_only_flag;
            l_batch_info_rec.shipment_priority_code :=
                                         c_pick_record.shipment_priority_code;
            l_batch_info_rec.ship_method_code :=
                                               c_pick_record.ship_method_code;
            l_batch_info_rec.ship_method_name := NULL;
            -- fnd_lookup_values_vl.meaning,
            l_batch_info_rec.customer_id := c_pick_record.customer_id;
            --TCA view removal Changes Starts
            l_batch_info_rec.customer_number := NULL;
            --TCA view removal Changes End
            l_batch_info_rec.order_header_id := r_order.header_id;
            l_batch_info_rec.order_number := r_order.order_number;
            l_batch_info_rec.ship_set_id := c_pick_record.ship_set_number;
            l_batch_info_rec.ship_set_number := NULL;    -- oe_sets.set_name,
            l_batch_info_rec.inventory_item_id :=
                                              c_pick_record.inventory_item_id;
            l_batch_info_rec.order_type_id := c_pick_record.order_type_id;
            l_batch_info_rec.order_type_name := NULL;
            -- oe_transaction_types_tl.name,
            l_batch_info_rec.from_requested_date := NULL;
            l_batch_info_rec.to_requested_date := NULL;
            l_batch_info_rec.from_scheduled_ship_date := NULL;
            l_batch_info_rec.to_scheduled_ship_date := NULL;
            l_batch_info_rec.ship_to_location_id :=
                                            c_pick_record.ship_to_location_id;
            l_batch_info_rec.ship_to_location_code := NULL;
            -- hr_locations_all_tl.location_code,
            l_batch_info_rec.ship_from_location_id :=
                                          c_pick_record.ship_from_location_id;
            l_batch_info_rec.ship_from_location_code := NULL;
            --  hr_locations_all_tl.location_code,
            l_batch_info_rec.trip_id := NULL;        --c_pick_record.trip_id;
            l_batch_info_rec.trip_name := NULL;            -- wsh_trips.name,
            l_batch_info_rec.delivery_id := NULL;
            --c_pick_record.delivery_id;
            l_batch_info_rec.delivery_name := NULL;
            --wsh_new_deliveries.name,
            l_batch_info_rec.include_planned_lines :=
                                          c_pick_record.include_planned_lines;
            l_batch_info_rec.pick_grouping_rule_id :=
                                          c_pick_record.pick_grouping_rule_id;
            l_batch_info_rec.pick_grouping_rule_name := NULL;
            -- wsh_pick_grouping_rules.name,
            l_batch_info_rec.pick_sequence_rule_id :=
                                          c_pick_record.pick_sequence_rule_id;
            l_batch_info_rec.pick_sequence_rule_name := NULL;
            --  wsh_pick_sequence_rules.name,
            l_batch_info_rec.autocreate_delivery_flag :=
                                       c_pick_record.autocreate_delivery_flag;
            l_batch_info_rec.attribute_category :=
                                             c_pick_record.attribute_category;
            l_batch_info_rec.attribute1 := c_pick_record.attribute1;
            l_batch_info_rec.attribute2 := c_pick_record.attribute2;
            l_batch_info_rec.attribute3 := c_pick_record.attribute3;
            l_batch_info_rec.attribute4 := c_pick_record.attribute4;
            l_batch_info_rec.attribute5 := c_pick_record.attribute5;
            l_batch_info_rec.attribute6 := c_pick_record.attribute6;
            l_batch_info_rec.attribute7 := c_pick_record.attribute7;
            l_batch_info_rec.attribute8 := c_pick_record.attribute8;
            l_batch_info_rec.attribute9 := c_pick_record.attribute9;
            l_batch_info_rec.attribute10 := c_pick_record.attribute10;
            l_batch_info_rec.attribute11 := c_pick_record.attribute11;
            l_batch_info_rec.attribute12 := c_pick_record.attribute12;
            l_batch_info_rec.attribute13 := c_pick_record.attribute13;
            l_batch_info_rec.attribute14 := c_pick_record.attribute14;
            l_batch_info_rec.attribute15 := c_pick_record.attribute15;
            l_batch_info_rec.autodetail_pr_flag :=
                                             c_pick_record.autodetail_pr_flag;
            l_batch_info_rec.trip_stop_id := NULL;
            --c_pick_record.trip_stop_id;
            l_batch_info_rec.trip_stop_location_id := NULL;
            -- wsh_trip_stops.Stop_Id,
            l_batch_info_rec.default_stage_subinventory :=
                                     c_pick_record.default_stage_subinventory;
            l_batch_info_rec.default_stage_locator_id :=
                                       c_pick_record.default_stage_locator_id;
            l_batch_info_rec.pick_from_subinventory :=
                                         c_pick_record.pick_from_subinventory;
            l_batch_info_rec.pick_from_locator_id :=
                                           c_pick_record.pick_from_locator_id;
            l_batch_info_rec.auto_pick_confirm_flag :=
                                         c_pick_record.auto_pick_confirm_flag;
            l_batch_info_rec.delivery_detail_id := NULL;
            --c_pick_record.delivery_detail_id;
            l_batch_info_rec.project_id := c_pick_record.project_id;
            l_batch_info_rec.task_id := c_pick_record.task_id;
            l_batch_info_rec.organization_id := c_pick_record.organization_id;
            l_batch_info_rec.organization_code := '150';
            -- org_organization_definitions.organization_code,
            l_batch_info_rec.ship_confirm_rule_id :=
                                           c_pick_record.ship_confirm_rule_id;
            -- l_Batch_Info_Rec.Ship_Confirm_Rule_Name      := wsh_Ship_Confirm_rules.name,
            l_batch_info_rec.autopack_flag := c_pick_record.autopack_flag;
            l_batch_info_rec.autopack_level := c_pick_record.autopack_level;
            l_batch_info_rec.task_planning_flag :=
                                             c_pick_record.task_planning_flag;
            l_batch_info_rec.category_set_id := c_pick_record.category_set_id;
            l_batch_info_rec.category_id := c_pick_record.category_id;
            l_batch_info_rec.ship_set_smc_flag := NULL;
            --c_pick_record.ship_set_smc_flag;
            l_batch_info_rec.region_id := c_pick_record.region_id;
            l_batch_info_rec.zone_id := c_pick_record.zone_id;
            l_batch_info_rec.ac_delivery_criteria :=
                                           c_pick_record.ac_delivery_criteria;
            l_batch_info_rec.rel_subinventory :=
                                               c_pick_record.rel_subinventory;
            l_batch_info_rec.append_flag := c_pick_record.append_flag;
            l_batch_info_rec.task_priority := c_pick_record.task_priority;
            l_batch_info_rec.actual_departure_date := SYSDATE;
            --NULL;-- c_pick_record.actual_departure_date;
            l_batch_info_rec.allocation_method :=
                                              c_pick_record.allocation_method;
            -- X-dock
            l_batch_info_rec.crossdock_criteria_id :=
                                          c_pick_record.crossdock_criteria_id;
            -- X-dock
            l_batch_info_rec.crossdock_criteria_name := NULL;
            --varchar2(80), -- X-dock
            l_batch_info_rec.dynamic_replenishment_flag := NULL;
                      --  varchar2(1), --bug# 6689448 (replenishment project)
            -- LSP PROJECT
            l_batch_info_rec.client_id := c_pick_record.client_id;
            l_batch_info_rec.client_code := NULL;

            -- LSP PROJECT
            BEGIN
               wsh_picking_batches_pub.create_batch
                                         (p_api_version        => 1.0,
                                          p_init_msg_list      => NULL,
                                          p_commit             => NULL,
                                          x_return_status      => x_return_status,
                                          x_msg_count          => x_msg_count,
                                          x_msg_data           => x_msg_data,
                                          -- program specific paramters.
                                          p_rule_id            => NULL,
                                          p_rule_name          => NULL,
                                          p_batch_rec          => l_batch_info_rec,
                                          -- WSH_PICKING_BATCHES_PUB.Batch_Info_Rec ,
                                          p_batch_prefix       => NULL,
                                          x_batch_id           => l_batch_id
                                         );

               IF x_msg_count > 0
               THEN
                  v_msg_data := NULL;

                  FOR i IN 1 .. x_msg_count
                  LOOP
                     fnd_msg_pub.get (i,
                                      fnd_api.g_false,
                                      v_msg_data,
                                      x_error_count
                                     );
                     v_msg_data := v_msg_data || '. ' || v_msg_data;
                  END LOOP;

                  fnd_file.put_line (fnd_file.LOG,
                                        'Failed to Create Batch for '
                                     || l_batch_info_rec.order_number
                                     || ' - '
                                     || v_msg_data
                                    );
                  fnd_file.put_line
                     (fnd_file.output,
                         l_batch_info_rec.order_number
                      || '            '
                      || 'ERROR-Create Batch Failed for the order. See Log File for Details.'
                     );
                  retcode := xx_emf_cn_pkg.cn_rec_warn;
                  errbuf :=
                     'One or more Create Batch failed. See Output/Log File for details';
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  retcode := xx_emf_cn_pkg.cn_prc_err;
                  errbuf := 'Create Batch API Call Error: ' || SQLERRM;
                  fnd_file.put_line (fnd_file.LOG,
                                     'Create Batch API Call Error: '
                                     || SQLERRM
                                    );
                  ROLLBACK;
            END;

            BEGIN
               wsh_pick_list.online_release (l_batch_id,
                                             l_pick_status,
                                             l_pick_phase,
                                             l_pick_skip
                                            );

               BEGIN
                  SELECT DISTINCT flv.meaning
                    INTO l_release_status
                    FROM fnd_lookup_values flv, wsh_delivery_details wdd
                   WHERE wdd.source_header_number = r_order.order_number
                     AND wdd.released_status = flv.lookup_code
                     AND flv.lookup_type = 'PICK_STATUS'
                     AND flv.LANGUAGE = 'US';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_release_status := 'Invalid Release Status';
               END;

               fnd_file.put_line (fnd_file.output,
                                     r_order.order_number
                                  || '            '
                                  || l_batch_id
                                  || '            '
                                  || l_release_status
                                 );
            EXCEPTION
               WHEN OTHERS
               THEN
                  retcode := xx_emf_cn_pkg.cn_prc_err;
                  errbuf := 'Online Release API Call Error: ' || SQLERRM;
                  fnd_file.put_line (fnd_file.LOG,
                                        'Online Release API Call Error: '
                                     || SQLERRM
                                    );
                  ROLLBACK;
            END;
         END LOOP;

         fnd_file.put_line (fnd_file.LOG, 'Order Cursor Processing End.');
      ELSE
      pick_ship_confirm(p_order_number);
      END IF;
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         retcode := xx_emf_cn_pkg.cn_prc_err;
         errbuf := 'Error While Execution: ' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG,
                            'Error While Execution: ' || SQLERRM
                           );
         ROLLBACK;
   END release_batch;

   PROCEDURE pick_ship_confirm(p_order_number NUMBER)
   IS
   CURSOR c_pick_confirm
   IS
   SELECT    b.order_number,
             d1.wms_task_status,
             d1.operation_plan_id,
             wdd.batch_id,
             d1.process_flag,
             d1.ERROR_CODE,
             d1.error_explanation,
             d1.transaction_header_id,
             d1.move_order_line_id,
             d1.move_order_header_id,
             b.header_id
      FROM   oe_order_headers_all b,
             oe_order_lines_all c,
             wsh_delivery_details wdd,
             mtl_material_transactions_temp d1
      WHERE  EXISTS (SELECT 1
                       FROM wsh_delivery_details d
                      WHERE d.source_line_id = c.line_id AND d.released_status = 'S')
         AND c.line_id = wdd.source_line_id
         AND b.header_id = c.header_id
         AND wdd.released_status = 'S'
         AND d1.trx_source_line_id = c.line_id
         AND wdd.organization_id = 104
         AND wdd.source_header_type_name = 'ILS Charge Sheet Order'
         AND b.order_number = NVL(p_order_number, b.order_number);

   CURSOR c_ship_confirm
   IS
      SELECT DISTINCT wnd.delivery_id,
                      wnd.NAME,
                      ooh.order_number
                 FROM oe_order_lines_all ool,
                      oe_order_headers_all ooh,
                      wsh_delivery_details wdd,
                      wsh_new_deliveries wnd,
                      wsh_delivery_assignments wda
                WHERE 1 = 1
                  AND wdd.source_header_id = ool.header_id
                  AND wdd.source_header_id = ooh.header_id
                  AND ooh.header_id = ool.header_id
                  AND wdd.source_line_id = ool.line_id
                  AND wda.delivery_detail_id = wdd.delivery_detail_id
                  AND wda.delivery_id = wnd.delivery_id
                  AND wdd.released_status = 'Y'
                  AND wdd.organization_id = 104
                  AND wdd.source_header_type_name = 'ILS Charge Sheet Order'
                  AND ooh.order_number = NVL(p_order_number, ooh.order_number);

   cursor c_error (p_order_no IN VARCHAR2)IS
   SELECT    DISTINCT b.order_number,
             b.ATTRIBUTE12 surgery_no,
             mic.segment4 division,
             d1.error_explanation message
      FROM   oe_order_headers_all b,
             oe_order_lines_all c,
             wsh_delivery_details wdd,
             mtl_material_transactions_temp d1,
             mtl_item_categories_v mic
      WHERE  EXISTS (SELECT 1
                       FROM wsh_delivery_details d
                      WHERE d.source_line_id = c.line_id AND d.released_status = 'S')
         AND c.line_id = wdd.source_line_id
         AND b.header_id = c.header_id
         AND wdd.released_status = 'S'
         AND d1.trx_source_line_id = c.line_id
         AND wdd.organization_id = 104
         AND c.inventory_item_id = mic.inventory_item_id
         AND mic.category_set_name = 'Sales and Marketing'
         AND mic.organization_id = 104
         AND wdd.source_header_type_name = 'ILS Charge Sheet Order'
         AND b.order_number = NVL(p_order_no,b.order_number);


   l_number             NUMBER;
   x_proc_msg           VARCHAR2 (1000);
   l_ship_conf_status   VARCHAR2 (100);
   x_msg_data           VARCHAR2 (2000);
   BEGIN
     IF p_order_number IS NULL
     THEN
       DELETE FROM xxintg_pick_ship_tbl;
       fnd_file.put_line (fnd_file.LOG,
                            'Delete from Custom Table.'
                           );
     END IF;
    fnd_file.put_line (fnd_file.LOG,
                            'Start Pick Confirm Process.'
                           );
   FOR i IN c_pick_confirm
   LOOP
      UPDATE mtl_material_transactions_temp
         SET transaction_status = 1
       WHERE transaction_header_id = i.transaction_header_id AND transaction_status <> 1;
      BEGIN
      l_number                   :=
         inv_lpn_trx_pub.process_lpn_trx (p_trx_hdr_id              => i.transaction_header_id,
                                          p_commit                  => fnd_api.g_false,
                                          x_proc_msg                => x_proc_msg,
                                          p_proc_mode               => NULL,
                                          p_process_trx             => fnd_api.g_true,
                                          p_atomic                  => fnd_api.g_false,
                                          p_business_flow_code      => NULL
                                         );

      EXCEPTION
        WHEN OTHERS THEN
       fnd_file.put_line (fnd_file.LOG,
                            'Error While Pick Confirm: ' || i.order_number
                           );
      END;
      COMMIT;
   END LOOP;

   fnd_file.put_line (fnd_file.LOG,
                            'Start Ship Confirm Process.'
                           );

   FOR j IN c_ship_confirm
   LOOP
      BEGIN
        xx_ship_confirm_delivery (j.NAME,'S', l_ship_conf_status, x_msg_data);
      EXCEPTION
        WHEN OTHERS THEN
       fnd_file.put_line (fnd_file.LOG,
                            'Error While Ship Confirm: ' || j.order_number
                           );
       END;
   COMMIT;

   fnd_file.put_line (fnd_file.LOG,
                            'Ship Confirm: ' || j.order_number
                           );


   END LOOP;

   IF p_order_number IS NULL THEN
     fnd_file.put_line (fnd_file.LOG,
                            'Insert into Custom Table.'
                           );
     FOR k IN c_error(NULL)
     LOOP
     INSERT INTO XXINTG_PICK_SHIP_TBL
     VALUES (k.order_number
            ,k.division
            ,k.surgery_no
            ,k.message);
     END LOOP;
   END IF;

   IF p_order_number IS NOT NULL
   THEN
   fnd_file.put_line
                 (fnd_file.output,
                  '                                     Release to Warehouse Status'
                 );
         fnd_file.put_line
            (fnd_file.output,
             '--------------------------------------------------------------------------'
            );
         fnd_file.put_line (fnd_file.output, '');
         fnd_file.put_line
                 (fnd_file.output,
                  'Order Number            Division            Surgery No            Error Message'
                 );
         fnd_file.put_line (fnd_file.output, '');
   FOR k IN c_error(p_order_number)
     LOOP
     fnd_file.put_line (fnd_file.output,
                                     k.order_number
                                  || '            '
                                  || k.division
                                  || '            '
                                  || k.surgery_no
                                  || '            '
                                  || k.message
                                 );
     END LOOP;

     fnd_file.put_line
            (fnd_file.output,
             '--------------------------------------------------------------------------'
            );

   END IF;

   COMMIT;
   END pick_ship_confirm;
END xxintg_wms_release_batch_pkg;
/
