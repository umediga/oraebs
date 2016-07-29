DROP PACKAGE BODY APPS.XX_MTLWRAP_UPD_ADI_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_MTLWRAP_UPD_ADI_PKG"
AS
   PROCEDURE log_message (p_message IN VARCHAR2)
   IS
   BEGIN
      INSERT INTO xx_debug
           VALUES ('MTL_UPD', p_message);
   END log_message;

   FUNCTION get_locator (p_subinv VARCHAR2, p_org_code VARCHAR2)
      RETURN VARCHAR2
   IS
      v_locator   VARCHAR2 (30);
      v_count     NUMBER;
   BEGIN
      v_count := 0;

      BEGIN
         SELECT COUNT (1)
           INTO v_count
           FROM mtl_item_locations mil, org_organization_definitions ood
          WHERE mil.organization_id = ood.organization_id
            AND mil.subinventory_code = p_subinv
            AND ood.organization_code = p_org_code;
      END;

      IF v_count > 1
      THEN
         SELECT mil.segment1 || '.' || mil.segment2 || '.' || mil.segment3
           INTO v_locator
           FROM mtl_item_locations mil, org_organization_definitions ood
          WHERE mil.organization_id = ood.organization_id
            AND mil.subinventory_code = p_subinv
            AND ood.organization_code = p_org_code
            AND mil.segment2 = 'SPI';
      ELSIF v_count = 1
      THEN
         SELECT mil.segment1 || '.' || mil.segment2 || '.' || mil.segment3
           INTO v_locator
           FROM mtl_item_locations mil, org_organization_definitions ood
          WHERE mil.organization_id = ood.organization_id
            AND mil.subinventory_code = p_subinv
            AND ood.organization_code = p_org_code;
      ELSIF v_count = 0
      THEN
         v_locator := NULL;
      END IF;

      RETURN v_locator;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_locator;

   FUNCTION upd_mtl_xns (
      p_header_id              IN   NUMBER,
      p_org_code               IN   VARCHAR2,
      p_transaction_type       IN   VARCHAR2,
      p_item                   IN   VARCHAR2,
      p_revision               IN   VARCHAR2,
      p_from_subinventory      IN   VARCHAR2,
      p_from_locator           IN   VARCHAR2,
      p_from_lpn               IN   VARCHAR2,
      p_to_subinventory        IN   VARCHAR2,
      p_to_locator             IN   VARCHAR2,
      p_to_lpn                 IN   VARCHAR2,
      p_uom                    IN   VARCHAR2,
      p_quantity               IN   NUMBER,
      p_lot_number             IN   VARCHAR2,
      p_serial_serial_number   IN   VARCHAR2,
      p_sales_rep              IN   VARCHAR2,
      p_account_alias_name     IN   VARCHAR2,
      p_reason                 IN   VARCHAR2,
      p_reference              IN   VARCHAR2,
      p_lot_expiry             IN   DATE,
      p_attribute1             IN   VARCHAR2,
      p_attribute2             IN   VARCHAR2,
      p_attribute3             IN   VARCHAR2,
      p_attribute4             IN   VARCHAR2,
      p_attribute5             IN   VARCHAR2,
      p_attribute6             IN   VARCHAR2,
      p_attribute7             IN   VARCHAR2,
      p_attribute8             IN   VARCHAR2,
      p_attribute9             IN   VARCHAR2,
      p_attribute10            IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      x_revision_num                NUMBER;
      x_err_msg                     VARCHAR2 (100);
      l_transaction_type_id         mtl_transaction_types.transaction_type_id%TYPE;
      l_transaction_src_type_id     mtl_transaction_types.transaction_source_type_id%TYPE;
      l_transaction_action_id       mtl_transaction_types.transaction_action_id%TYPE;
      l_transaction_type_name       mtl_transaction_types.transaction_type_name%TYPE;
      l_account_alias_name          mtl_generic_dispositions.segment1%TYPE;
      l_account_id                  mtl_generic_dispositions.distribution_account%TYPE;
      l_location_control_code       apps.mtl_system_items_b.location_control_code%TYPE;
      l_source_header_id            NUMBER;
      v_inv_item_id                 NUMBER;
      l_subinv_code                 VARCHAR2 (30);
      v_salesrep                    VARCHAR2 (30);
      l_source_line_id              NUMBER;
      l_trans_temp_id               NUMBER;
      v_org_id                      NUMBER;
      l_err_msg                     VARCHAR2 (6000)                     := '';
      l_source_code                 VARCHAR2 (30)              := 'SURGISOFT';
      v_primary_uom                 VARCHAR2 (3);
      v_lot_control_code            NUMBER;
      v_sno_control_code            NUMBER;
      v_shelf_life_code             NUMBER;
      v_revision_qty_control_code   NUMBER;
      v_account_alias_name          VARCHAR2 (30);
      v_cnt                         NUMBER;
      v_reason                      VARCHAR2 (1000);
      lv_count                      NUMBER                               := 0;
      v_issue_receipt_sign          VARCHAR2 (1)                      := NULL;
      v_mtl_trans                   NUMBER                               := 0;
      v_lot_no_serial               NUMBER                               := 0;
      v_serial_no_lot               NUMBER                               := 0;
      v_lot_serial                  NUMBER                               := 0;
      v_request_id                  NUMBER;
      v_err_cnt                     NUMBER;
      l_tranfer_locator             NUMBER;
      l_locator_id                  NUMBER;
      v_lot_cnt                     NUMBER;
      v_serial_cnt                  NUMBER;
      l_lot_expiry                  DATE;
      l_serial_serial_number        VARCHAR2 (30);
      -- p_api_version                NUMBER;
      l_reason_id                   NUMBER;
      p1_lot_number                 NUMBER;
      p_organization_id             NUMBER;
      p_inventory_item_id           NUMBER;
      p_transaction_temp_id         NUMBER;
      p_transaction_action_id       NUMBER;
      p_transfer_organization_id    NUMBER;
      p_object_id                   NUMBER;
      l_return_status               VARCHAR2 (100);
      l_msg_count                   NUMBER;
      l_msg_data                    VARCHAR2 (100);
      l_lpn_id                      NUMBER;
      l_transfer_lpn_id             NUMBER;
      v_trans_count                 NUMBER;
      l_lot_number                  VARCHAR2(80);
   BEGIN
      l_err_msg := NULL;
      l_transaction_type_id := NULL;
      l_transaction_action_id := NULL;
      l_transaction_src_type_id := NULL;
      l_transaction_type_name := NULL;
      v_org_id := NULL;
      l_trans_temp_id := NULL;
      l_source_header_id := NULL;
      l_source_line_id := NULL;
      v_inv_item_id := NULL;
      l_subinv_code := NULL;
      v_salesrep := NULL;
      v_primary_uom := NULL;
      v_shelf_life_code := NULL;
      v_lot_control_code := NULL;
      v_sno_control_code := NULL;
      v_revision_qty_control_code := NULL;
      l_location_control_code := NULL;
      v_issue_receipt_sign := NULL;
      v_reason := NULL;
      l_tranfer_locator := NULL;
      fnd_global.apps_initialize (1759, 51367, 401);
      oe_msg_pub.initialize;
      oe_debug_pub.initialize;
      mo_global.init ('ONT');
      mo_global.set_org_context (101, NULL, 'ONT');
      fnd_global.set_nls_context ('AMERICAN');
      mo_global.set_policy_context ('S', 101);

      BEGIN
         SELECT transaction_type_id, transaction_action_id,
                transaction_source_type_id, transaction_type_name
           INTO l_transaction_type_id, l_transaction_action_id,
                l_transaction_src_type_id, l_transaction_type_name
           FROM mtl_transaction_types
          WHERE transaction_type_name = p_transaction_type;
      /*AND transaction_type_name IN
             ('Account alias issue',
              'Account alias receipt',
              'Subinventory Transfer',
              'Direct Org Transfer'
             );*/
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg := l_err_msg || '1. Invalid Transaction Type';
            log_message (l_err_msg);
      --return l_err_msg;
      END;

      log_message (   'Transaction Type Name - '
                   || l_transaction_type_name
                   || ' ID - '
                   || l_transaction_type_id
                  );

      /* Derive the Organization_id */
      BEGIN
         SELECT organization_id
           INTO v_org_id
           FROM org_organization_definitions
          WHERE organization_code = p_org_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg := l_err_msg || ' 2.Invalid Organization';
            log_message (l_err_msg);
      --return l_err_msg;
      END;

      BEGIN
         SELECT inventory_item_id
           INTO v_inv_item_id
           FROM apps.mtl_system_items_b
          WHERE inventory_item_status_code <> 'Inactive'
            AND segment1 = p_item
            AND organization_id = v_org_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg := l_err_msg || ' 3.Invalid Item';
            log_message (l_err_msg);
      --return l_err_msg;
      END;

      IF p_revision IS NULL
      THEN
         --  l_err_msg := l_err_msg || ' 4.Revision is NULL';
          -- log_message (l_err_msg);
         NULL;
      --return l_err_msg;
      END IF;

      BEGIN
         SELECT secondary_inventory_name
           INTO l_subinv_code
           FROM apps.mtl_secondary_inventories
          WHERE secondary_inventory_name = p_from_subinventory
            AND organization_id = v_org_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg := l_err_msg || ' 5.Invalid From Subinventory';
            log_message (l_err_msg);
      --return l_err_msg;
      END;

      --validating For NULL OnHand Quantity
      IF p_quantity IS NULL
      THEN
         l_err_msg := l_err_msg || ' 6.Quantity Cannot be NULL';
         log_message (l_err_msg);
      --return l_err_msg;
      END IF;

      fnd_file.put_line (fnd_file.LOG, 'from_subinv :' || p_from_subinventory);

      --Validating For UOM Not Present in Base Table
      IF p_item IS NOT NULL
      THEN
         BEGIN
            SELECT primary_uom_code, shelf_life_code, lot_control_code,
                   serial_number_control_code, revision_qty_control_code,
                   location_control_code
              INTO v_primary_uom, v_shelf_life_code, v_lot_control_code,
                   v_sno_control_code, v_revision_qty_control_code,
                   l_location_control_code
              FROM apps.mtl_system_items_b
             WHERE inventory_item_status_code <> 'Inactive'
               AND inventory_item_id = v_inv_item_id
               AND primary_uom_code = p_uom
               AND organization_id = v_org_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg := l_err_msg || ' 6.Invalid UOM';
               log_message (l_err_msg);
         --return l_err_msg;
         END;
      END IF;

      v_issue_receipt_sign := NULL;

      -- Fetching Sign for Issue from stores, Receipt into stores
      BEGIN
         /*SELECT DECODE (ml.meaning,
                        'Account alias issue ', '-',
                        'NOSS-ISSUE', '-',
                        'Account alias receipt', '+',
                        'Subinventory Transfer', '-',
                        'NOSS-Sub Transfer', '+',
                        '+'
                       )
           INTO v_issue_receipt_sign
           FROM apps.mfg_lookups ml, mtl_transaction_types mtt
          WHERE ml.lookup_type = 'MTL_TRANSACTION_ACTION'
            AND ml.lookup_code = mtt.transaction_action_id
            AND mtt.transaction_type_name = l_transaction_type_name;*/
         SELECT DECODE (a.parameter_name,
                        'XXPOSSIGN', '+',
                        'XXNEGSIGN', '-',
                        '+'
                       )
           INTO v_issue_receipt_sign
           FROM xx_emf_process_parameters a, xx_emf_process_setup b
          WHERE a.process_id = b.process_id
            AND b.process_name = 'XXMTLUPLOAD'
            AND a.parameter_value = l_transaction_type_name
            AND a.parameter_name != 'XXTRANSFERLPN';

         log_message (   'v_issue_receipt_sign for transaction_type: '
                      || v_issue_receipt_sign
                      || 'for'
                      || l_transaction_type_name
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                    l_err_msg || ' 7.Error getting sign for transaction type';
            log_message (l_err_msg);
      --return l_err_msg;
      END;

      -- IF (l_transaction_type_id = 31) OR (l_transaction_type_id = 41)
      -- THEN
      fnd_file.put_line (fnd_file.LOG,
                         'Account alias issue or Account alias receipt'
                        );
      l_account_id := NULL;
      l_account_alias_name := NULL;

      IF p_account_alias_name IS NOT NULL THEN

      BEGIN
         SELECT segment1, distribution_account
           INTO l_account_alias_name, l_account_id
           FROM mtl_generic_dispositions
          WHERE organization_id = v_org_id AND segment1 = p_account_alias_name;

         fnd_file.put_line (fnd_file.LOG,
                            'account_alias_name:' || l_account_alias_name
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
            l_err_msg := l_err_msg || ' 8.Invalid Dist Account';
            log_message (l_err_msg);
      --return l_err_msg;
      END;
END IF;
      -- END IF;
      log_message ('l_account_alias_name:' || l_account_alias_name);

      IF p_reason IS NOT NULL
      THEN
         BEGIN
            -- Validating the Reason code
            SELECT reason_id
              INTO l_reason_id
              FROM mtl_transaction_reasons
             WHERE reason_name = p_reason;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
               l_err_msg := l_err_msg || ' 9.Invalid Reason Code';
               log_message (l_err_msg);
         --return l_err_msg;
         END;
      END IF;

      IF p_from_locator IS NOT NULL
      THEN
         BEGIN
            SELECT inventory_location_id
              INTO l_locator_id
              FROM mtl_item_locations_kfv
             WHERE concatenated_segments = p_from_locator;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
               l_err_msg := l_err_msg || ' 10.Invalid From Locator';
               log_message (l_err_msg);
         --return l_err_msg;
         END;
      END IF;

      log_message ('To Locator ' || p_to_locator);

      IF p_to_locator IS NOT NULL
      THEN
         BEGIN
            SELECT inventory_location_id
              INTO l_tranfer_locator
              FROM mtl_item_locations_kfv
             WHERE concatenated_segments = p_to_locator;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
               l_err_msg := l_err_msg || ' 11.Invalid To Locator';
               log_message (l_err_msg);
         --return l_err_msg;
         END;
      END IF;

      -- Validate lots ---
      IF p_lot_number IS NOT NULL
      THEN
         BEGIN
            SELECT 1, expiration_date,lot_number
              INTO v_lot_cnt, l_lot_expiry,l_lot_number
              FROM mtl_lot_numbers
             WHERE (lot_number = p_lot_number OR lot_number = UPPER(p_lot_number))
               AND inventory_item_id = v_inv_item_id
               AND organization_id = v_org_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_lot_cnt := 0;
            WHEN OTHERS
            THEN
               v_lot_cnt := 1;
         END;

         IF v_lot_cnt > 0
         THEN
            NULL;
         ELSIF v_lot_cnt = 0 AND g_aquisition_flag = 'Y'
         THEN
            l_lot_expiry := p_lot_expiry;
            inv_lot_api_pub.insertlot
                           (p_api_version                   => 1.0,
                            p_init_msg_list                 => fnd_api.g_true,
                            p_commit                        => fnd_api.g_true,
                            p_validation_level              => fnd_api.g_valid_level_full,
                            p_inventory_item_id             => v_inv_item_id,
                            p_organization_id               => v_org_id,
                            p_lot_number                    => p_lot_number,
                            p_expiration_date               => l_lot_expiry,
                            p_transaction_temp_id           => NULL,
                            p_transaction_action_id         => NULL,
                            p_transfer_organization_id      => NULL,
                            x_object_id                     => p_object_id,
                            x_return_status                 => l_return_status,
                            x_msg_count                     => l_msg_count,
                            x_msg_data                      => l_msg_data
                           );
            l_lot_number := p_lot_number;
         ELSE
            l_err_msg :=
                 l_err_msg || ' 11.Lot Number does not exist';
            log_message (l_err_msg);
         --return l_err_msg;
         END IF;
      ELSIF v_lot_control_code <> 1
      THEN
         IF p_lot_number IS NULL
         THEN
            l_err_msg := l_err_msg || ' 12.Lot Number not provied';
            log_message (l_err_msg);
         --return l_err_msg;
         END IF;
      END IF;

      IF p_serial_serial_number IS NOT NULL
      THEN
         SELECT COUNT (*)
           INTO v_serial_cnt
           FROM mtl_serial_numbers
          WHERE (serial_number = p_serial_serial_number OR serial_number = UPPER(p_serial_serial_number))
            AND inventory_item_id = v_inv_item_id;

         IF v_serial_cnt > 0
         THEN
            NULL;
         ELSIF v_serial_cnt = 0 AND g_aquisition_flag = 'Y'
         THEN
            NULL;
            l_serial_serial_number := p_serial_serial_number;
            inv_serial_number_pub.insertserial
                           (p_api_version              => 1.0,
                            p_init_msg_list            => fnd_api.g_false,
                            p_commit                   => fnd_api.g_false,
                            p_validation_level         => fnd_api.g_valid_level_full,
                            p_inventory_item_id        => v_inv_item_id,
                            p_organization_id          => v_org_id,
                            p_serial_number            => l_serial_serial_number,
                            p_current_status           => 1,
                            p_group_mark_id            => -1,
                            p_lot_number               => NULL,
                            p_initialization_date      => SYSDATE,
                            x_return_status            => l_return_status,
                            x_msg_count                => l_msg_count,
                            x_msg_data                 => l_msg_data,
                            p_organization_type        => NULL,
                            p_owning_org_id            => NULL,
                            p_owning_tp_type           => NULL,
                            p_planning_org_id          => NULL,
                            p_planning_tp_type         => NULL
                           );
            fnd_file.put_line
                            (fnd_file.LOG,
                                ' Serial control Item,  New serial number is:'
                             || l_serial_serial_number
                            );
         ELSE
            l_err_msg := l_err_msg || ' 13.Invalid Serial Number';
            log_message (l_err_msg);
         --return l_err_msg;
         END IF;
      ELSIF v_sno_control_code <> 1
      THEN
         IF p_serial_serial_number IS NULL
         THEN
            l_err_msg :=
                  l_err_msg
               || ' 14.Serial Number Cannot be blank for Serial controlled Item';
            log_message (l_err_msg);
         --return l_err_msg;
         END IF;
      END IF;

      IF p_from_lpn IS NOT NULL
      THEN
         BEGIN
            SELECT lpn_id
              INTO l_lpn_id
              FROM wms_license_plate_numbers
             WHERE license_plate_number = p_from_lpn;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg := l_err_msg || ' 15.Invalid LPN Number';
               log_message (l_err_msg);
         END;
      END IF;

      IF p_to_lpn IS NOT NULL
      THEN
         BEGIN
            SELECT lpn_id
              INTO l_transfer_lpn_id
              FROM wms_license_plate_numbers
             WHERE license_plate_number = p_to_lpn;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg := l_err_msg || ' 16.Invalid Transfer LPN Number';
               log_message (l_err_msg);
         END;
      END IF;

      BEGIN
         SELECT COUNT (1)
           INTO v_trans_count
           FROM xx_emf_process_parameters a, xx_emf_process_setup b
          WHERE a.process_id = b.process_id
            AND b.process_name = 'XXMTLUPLOAD'
            AND a.parameter_name = 'XXTRANSFERLPN'
            AND a.parameter_value = l_transaction_type_name;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_trans_count := 0;
      END;

      IF v_trans_count > 0 AND p_from_lpn IS NOT NULL AND p_to_lpn IS NULL
      THEN
         l_transfer_lpn_id := l_lpn_id;
         l_lpn_id := NULL;
      END IF;

      IF l_err_msg IS NOT NULL
      THEN
         --COMMIT;
         log_message ('l_err_msg IS NOT NULL aborting ..');
         RETURN l_err_msg;
      ELSE
         l_err_msg := 'SUCCESS';        --NULL; -- insert interface tables --
      END IF;

      IF l_err_msg = 'SUCCESS'
      THEN
         IF p_quantity <> 0
         THEN
            -- Fetching Transaction Interface ID from Sequence
            BEGIN
               SELECT apps.mtl_material_transactions_s.NEXTVAL
                 INTO l_trans_temp_id
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_err_msg := l_err_msg || ' 15.MTL Sequence Error';
                  log_message (l_err_msg);
            --return l_err_msg;
            END;

            -- Fetching Source Header ID from Sequence
            BEGIN
               SELECT xx_mtl_item_source_hdr_s.NEXTVAL
                 INTO l_source_header_id
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_err_msg := l_err_msg || ' 16.HDR Sequence Error';
                  log_message (l_err_msg);
            --return l_err_msg;
            END;

            -- Fetching Source Line ID from Sequence
            BEGIN
               SELECT xx_mtl_item_source_line_s.NEXTVAL
                 INTO l_source_line_id
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_err_msg := l_err_msg || ' 16.LINE Sequence Error';
                  log_message (l_err_msg);
            --return l_err_msg;
            END;

            INSERT INTO apps.mtl_transactions_interface
                        (source_code, source_line_id, source_header_id,
                         process_flag, transaction_mode, validation_required,
                         last_update_date, last_updated_by, creation_date,
                         created_by, organization_id,
                         transaction_quantity, transaction_uom,
                         transaction_date, dsp_segment1,
                         transaction_type_id, inventory_item_id,
                         subinventory_code, revision,
                         transaction_interface_id, distribution_account_id,
                         transaction_reference, scheduled_flag,
                         flow_schedule, attribute3, transfer_subinventory,
                         locator_id, reason_id,
                         transfer_locator, transaction_header_id,
                         lpn_id, transfer_lpn_id
                        )
                 VALUES (l_source_code,                         -- source_code
                                       l_source_line_id,     -- source_line_id
                                                        l_source_header_id,
                         -- source_header_id
                         1,                                    -- process_flag
                           3,                              -- transaction_mode
                             1,                         -- validation_required
                         SYSDATE,                          -- last_update_date
                                 fnd_global.user_id,        -- last_updated_by
                                                    SYSDATE,  -- creation_date
                         fnd_global.user_id,                     -- created_by
                                            v_org_id,       -- organization_id
                         v_issue_receipt_sign || p_quantity,
                                                            -- transaction_quantity
                                                            p_uom,
                         -- transaction_uom
                         SYSDATE,                          -- transaction_date
                                 l_account_alias_name,         -- dsp_segment1
                         l_transaction_type_id,         -- transaction_type_id
                                               v_inv_item_id,
                         -- inventory_item_id
                         l_subinv_code,                   -- subinventory_code
                                       p_revision,                 -- revision
                         l_trans_temp_id,          -- transaction_interface_id
                                         l_account_id,
                         -- distribution_account_id
                         p_reference,                 -- transaction_reference
                                     NULL,
                         '2',
                             -- v_salesrep,
                             -- Added by Sridhar on 2/7/2012.Salesrep fetched from cursor
                             p_sales_rep, p_to_subinventory,
                         -- Transfer_subinventory
                         l_locator_id,                         -- From Locator
                                      l_reason_id,                -- Reason id
                         l_tranfer_locator                 -- Transfer Locator
                                          , p_header_id,
                         l_lpn_id, l_transfer_lpn_id
                        );

            v_mtl_trans := v_mtl_trans + 1;

            fnd_file.put_line (fnd_file.LOG,
                                  'l_lot_expiry: '||l_lot_expiry
                                 );

--dbms_output.put_line('Inserted data '||v_mtl_trans);
         -- Inserting into interface table
            IF v_lot_control_code = 2 AND v_sno_control_code = 1
            -- lot controlled but not serial controlled
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                  'lot controlled but not serial controlled'
                                 );

               INSERT INTO apps.mtl_transaction_lots_interface
                           (transaction_interface_id, source_code,
                            source_line_id, lot_number, lot_expiration_date,
                            transaction_quantity, last_update_date,
                            last_updated_by, creation_date,
                            created_by
                           )
                    VALUES (l_trans_temp_id,       -- transaction interface_id
                                            l_source_code,      -- source code
                            l_source_line_id,                -- source line id
                                             l_lot_number,       -- lot number
                                                          l_lot_expiry,
                            -- lot_Expiration_date
                            p_quantity,                -- transaction_quantity
                                       SYSDATE,            -- last_update_date
                            fnd_global.user_id,             -- last_updated_by
                                               SYSDATE,       -- creation_date
                            fnd_global.user_id                   -- created_by
                           );

               v_lot_no_serial := v_lot_no_serial + 1;
            ELSIF     v_lot_control_code = 1
                  AND v_sno_control_code <> 1  -- Serial controlled and no lot
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                  'Serial controlled and no lot'
                                 );

               INSERT INTO apps.mtl_serial_numbers_interface
                           (transaction_interface_id, source_code,
                            source_line_id, fm_serial_number,
                            to_serial_number, last_update_date,
                            last_updated_by, creation_date, created_by
                           )
                    VALUES (l_trans_temp_id, l_source_code,
                            l_source_line_id, p_serial_serial_number,
                            p_serial_serial_number, SYSDATE,
                            fnd_global.user_id, SYSDATE, fnd_global.user_id
                           );

               v_serial_no_lot := v_serial_no_lot + 1;
            ELSIF v_lot_control_code = 2 AND v_sno_control_code = 2
            THEN
               -- lot and serial
               fnd_file.put_line (fnd_file.LOG, '-- lot and serial');

               INSERT INTO apps.mtl_serial_numbers_interface
                           (transaction_interface_id, fm_serial_number,
                            to_serial_number, last_update_date,
                            last_updated_by, creation_date, created_by
                           )
                    VALUES (l_trans_temp_id, p_serial_serial_number,
                            p_serial_serial_number, SYSDATE,
                            fnd_global.user_id, SYSDATE, fnd_global.user_id
                           );

               INSERT INTO apps.mtl_transaction_lots_interface
                           (transaction_interface_id, source_code,
                            source_line_id, lot_number,
                            lot_expiration_date,
                            transaction_quantity, last_update_date,
                            last_updated_by, creation_date,
                            created_by
                           )
                    VALUES (l_trans_temp_id,       -- transaction interface_id
                                            l_source_code,      -- source code
                            l_source_line_id,                -- source line id
                                             l_lot_number,       -- lot number
                            DECODE (v_shelf_life_code, 1, NULL, l_lot_expiry),
                            -- lot_Expiration_date
                            p_quantity,                -- transaction_quantity
                                       SYSDATE,            -- last_update_date
                            fnd_global.user_id,             -- last_updated_by
                                               SYSDATE,       -- creation_date
                            fnd_global.user_id                   -- created_by
                           );

               v_lot_serial := v_lot_serial + 1;
            END IF;
         END IF;
      ELSE
         NULL;
      END IF;

      g_interface_id := l_trans_temp_id;

      --COMMIT;

      /*

         BEGIN
                  SELECT revision_num
                    INTO x_revision_num
                    FROM po_headers_all
                   WHERE segment1 = p_org_code;
               EXCEPTION WHEN OTHERS THEN
                  x_err_msg := 'Cannot Fetch ORG_ID and PO Revision Num';
                  --    raise_application_error (-20001,x_err_msg);
                  return x_err_msg;
               END;
         return x_err_msg;
      */
      IF (l_err_msg = 'SUCCESS')
      THEN
         RETURN NULL;
      END IF;
   END upd_mtl_xns;

   PROCEDURE execute_wrapper (
      p_errbuf                 VARCHAR2,
      p_error_code             NUMBER,
      p_aquisition_flag   IN   VARCHAR2
   )
   IS
      CURSOR c_main
      IS
         SELECT *
           FROM xxintg_wrap_matl_stg
          WHERE status IS NULL OR status = 'E';

      CURSOR c_error_rep
      IS
         SELECT REFERENCE, trans_header_id, trans_interface_id,
                NVL (MESSAGE,ERROR_CODE) ERROR_CODE, error_explanation
           FROM xxintg_wrap_matl_stg
          WHERE status = 'E';

      l_txn_header_id     NUMBER;
      l_return            NUMBER;
      x_msg_count         NUMBER;
      --x_trans_count     NUMBER;
      x_return_status     VARCHAR2 (5);
      x_trans_count       NUMBER;
      x_return            VARCHAR2 (240);
      x_return_message    VARCHAR2 (100);
      l_total_count       NUMBER;
      l_success_count     NUMBER;
      l_fail_count        NUMBER;
      l_unprocess_count   NUMBER;
   BEGIN
      SELECT apps.mtl_material_transactions_s.NEXTVAL
        INTO l_txn_header_id
        FROM DUAL;

      g_header_id := l_txn_header_id;
      g_aquisition_flag := p_aquisition_flag;

      UPDATE xxintg_wrap_matl_stg a
         SET uom = (SELECT primary_uom_code
                      FROM mtl_system_items_b
                     WHERE segment1 = a.item AND organization_id = 104),
             a.inventory_item_id =
                           (SELECT inventory_item_id
                              FROM MTL_SYSTEM_ITEMS_B
                             WHERE organization_id = 104 AND segment1 = a.item),
             a.locator_id =
                (SELECT inventory_location_id
                   FROM mtl_item_locations mil
                  WHERE mil.segment1 || '.' || mil.segment2 || '.'
                        || mil.segment3 = a.from_locator)
       WHERE status IS NULL OR status = 'E';

      FOR v_main IN c_main
      LOOP
         x_return :=
            xx_mtlwrap_upd_adi_pkg.upd_mtl_xns
                          (p_header_id                 => l_txn_header_id,
                           p_org_code                  => v_main.org_code,
                           p_transaction_type          => v_main.transaction_type,
                           p_item                      => v_main.item,
                           p_revision                  => v_main.revision,
                           p_from_subinventory         => v_main.from_subinventory,
                           p_from_locator              => v_main.from_locator,
                           p_from_lpn                  => v_main.from_lpn,
                           p_to_subinventory           => v_main.to_subinventory,
                           p_to_locator                => v_main.to_locator,
                           p_to_lpn                    => v_main.to_lpn,
                           p_uom                       => v_main.uom,
                           p_quantity                  => v_main.quantity,
                           p_lot_number                => v_main.lot_number,
                           p_serial_serial_number      => v_main.serial_number,
                           p_sales_rep                 => v_main.sales_rep,
                           p_account_alias_name        => v_main.account_alias_name,
                           p_reason                    => v_main.reason,
                           p_reference                 => v_main.REFERENCE,
                           p_lot_expiry                => v_main.lot_expiry,
                           p_attribute1                => v_main.attribute1,
                           p_attribute2                => v_main.attribute2,
                           p_attribute3                => v_main.attribute3,
                           p_attribute4                => v_main.attribute4,
                           p_attribute5                => v_main.attribute5,
                           p_attribute6                => v_main.attribute6,
                           p_attribute7                => v_main.attribute7,
                           p_attribute8                => v_main.attribute8,
                           p_attribute9                => v_main.attribute9,
                           p_attribute10               => v_main.attribute10
                          );

         IF x_return IS NULL
         THEN
            UPDATE xxintg_wrap_matl_stg
               SET status = 'S',
                   MESSAGE = 'Successfully Inserted',
                   trans_header_id = g_header_id,
                   trans_interface_id = g_interface_id
             WHERE NVL (org_code, 'YY') = NVL (v_main.org_code, 'YY')
               AND NVL (transaction_type, 'YY') =
                                           NVL (v_main.transaction_type, 'YY')
               AND NVL (item, 'YY') = NVL (v_main.item, 'YY')
               AND NVL (revision, 'YY') = NVL (v_main.revision, 'YY')
               AND NVL (from_subinventory, 'YY') =
                                          NVL (v_main.from_subinventory, 'YY')
               AND NVL (from_locator, 'YY') = NVL (v_main.from_locator, 'YY')
               AND NVL (from_lpn, 'YY') = NVL (v_main.from_lpn, 'YY')
               AND NVL (to_subinventory, 'YY') =
                                            NVL (v_main.to_subinventory, 'YY')
               AND NVL (to_locator, 'YY') = NVL (v_main.to_locator, 'YY')
               AND NVL (to_lpn, 'YY') = NVL (v_main.to_lpn, 'YY')
               AND NVL (uom, 'YY') = NVL (v_main.uom, 'YY')
               AND NVL (quantity, 99999) = NVL (v_main.quantity, 99999)
               AND NVL (lot_number, 'YY') = NVL (v_main.lot_number, 'YY')
               AND NVL (serial_number, 'YY') =
                                              NVL (v_main.serial_number, 'YY')
               AND NVL (sales_rep, 'YY') = NVL (v_main.sales_rep, 'YY')
               AND NVL (account_alias_name, 'YY') =
                                         NVL (v_main.account_alias_name, 'YY')
               AND NVL (reason, 'YY') = NVL (v_main.reason, 'YY')
               AND NVL (REFERENCE, 'YY') = NVL (v_main.REFERENCE, 'YY')
               AND NVL (lot_expiry, SYSDATE) =
                                              NVL (v_main.lot_expiry, SYSDATE)
               AND NVL (attribute1, 'YY') = NVL (v_main.attribute1, 'YY')
               AND NVL (attribute2, 'YY') = NVL (v_main.attribute2, 'YY')
               AND NVL (attribute3, 'YY') = NVL (v_main.attribute3, 'YY')
               AND NVL (attribute4, 'YY') = NVL (v_main.attribute4, 'YY')
               AND NVL (attribute5, 'YY') = NVL (v_main.attribute5, 'YY')
               AND NVL (attribute6, 'YY') = NVL (v_main.attribute6, 'YY')
               AND NVL (attribute7, 'YY') = NVL (v_main.attribute7, 'YY')
               AND NVL (attribute8, 'YY') = NVL (v_main.attribute8, 'YY')
               AND NVL (attribute9, 'YY') = NVL (v_main.attribute9, 'YY')
               AND NVL (attribute10, 'YY') = NVL (v_main.attribute10, 'YY');

            g_interface_id := NULL;
         ELSE
            UPDATE xxintg_wrap_matl_stg
               SET status = 'E',
                   MESSAGE = x_return
             WHERE NVL (org_code, 'YY') = NVL (v_main.org_code, 'YY')
               AND NVL (transaction_type, 'YY') =
                                           NVL (v_main.transaction_type, 'YY')
               AND NVL (item, 'YY') = NVL (v_main.item, 'YY')
               AND NVL (revision, 'YY') = NVL (v_main.revision, 'YY')
               AND NVL (from_subinventory, 'YY') =
                                          NVL (v_main.from_subinventory, 'YY')
               AND NVL (from_locator, 'YY') = NVL (v_main.from_locator, 'YY')
               AND NVL (from_lpn, 'YY') = NVL (v_main.from_lpn, 'YY')
               AND NVL (to_subinventory, 'YY') =
                                            NVL (v_main.to_subinventory, 'YY')
               AND NVL (to_locator, 'YY') = NVL (v_main.to_locator, 'YY')
               AND NVL (to_lpn, 'YY') = NVL (v_main.to_lpn, 'YY')
               AND NVL (uom, 'YY') = NVL (v_main.uom, 'YY')
               AND NVL (quantity, 99999) = NVL (v_main.quantity, 99999)
               AND NVL (lot_number, 'YY') = NVL (v_main.lot_number, 'YY')
               AND NVL (serial_number, 'YY') =
                                              NVL (v_main.serial_number, 'YY')
               AND NVL (sales_rep, 'YY') = NVL (v_main.sales_rep, 'YY')
               AND NVL (account_alias_name, 'YY') =
                                         NVL (v_main.account_alias_name, 'YY')
               AND NVL (reason, 'YY') = NVL (v_main.reason, 'YY')
               AND NVL (REFERENCE, 'YY') = NVL (v_main.REFERENCE, 'YY')
               AND NVL (lot_expiry, SYSDATE) =
                                              NVL (v_main.lot_expiry, SYSDATE)
               AND NVL (attribute1, 'YY') = NVL (v_main.attribute1, 'YY')
               AND NVL (attribute2, 'YY') = NVL (v_main.attribute2, 'YY')
               AND NVL (attribute3, 'YY') = NVL (v_main.attribute3, 'YY')
               AND NVL (attribute4, 'YY') = NVL (v_main.attribute4, 'YY')
               AND NVL (attribute5, 'YY') = NVL (v_main.attribute5, 'YY')
               AND NVL (attribute6, 'YY') = NVL (v_main.attribute6, 'YY')
               AND NVL (attribute7, 'YY') = NVL (v_main.attribute7, 'YY')
               AND NVL (attribute8, 'YY') = NVL (v_main.attribute8, 'YY')
               AND NVL (attribute9, 'YY') = NVL (v_main.attribute9, 'YY')
               AND NVL (attribute10, 'YY') = NVL (v_main.attribute10, 'YY');
         END IF;
      END LOOP;

      l_return :=
         inv_txn_manager_pub.process_transactions
                            (p_api_version           => 1.0,
                             p_init_msg_list         => fnd_api.g_true,
                             p_commit                => fnd_api.g_true,
                             p_validation_level      => fnd_api.g_valid_level_full,
                             x_return_status         => x_return_status,
                             x_msg_count             => x_msg_count,
                             x_msg_data              => x_return_message,
                             x_trans_count           => x_trans_count,
                             p_table                 => 1,
                             p_header_id             => l_txn_header_id
                            );

      UPDATE xxintg_wrap_matl_stg xwms
         SET xwms.ERROR_CODE =
                (SELECT mti.ERROR_CODE
                   FROM mtl_transactions_interface mti
                  WHERE mti.transaction_header_id = g_header_id
                    AND mti.transaction_interface_id = xwms.trans_interface_id),
             xwms.error_explanation =
                (SELECT mti.error_explanation
                   FROM mtl_transactions_interface mti
                  WHERE mti.transaction_header_id = g_header_id
                    AND mti.transaction_interface_id = xwms.trans_interface_id),
             xwms.status = 'E'
       WHERE xwms.trans_header_id = g_header_id
         AND xwms.trans_interface_id IN (SELECT transaction_interface_id
                                           FROM mtl_transactions_interface
                                          WHERE error_explanation IS NOT NULL);

      COMMIT;

      BEGIN
         l_fail_count := 0;

         SELECT COUNT (*)
           INTO l_fail_count
           FROM xxintg_wrap_matl_stg
          WHERE status = 'E';

         l_success_count := 0;

         SELECT COUNT (*)
           INTO l_success_count
           FROM xxintg_wrap_matl_stg
          WHERE status = 'S';

         l_total_count := 0;

         SELECT COUNT (*)
           INTO l_total_count
           FROM xxintg_wrap_matl_stg;

         l_unprocess_count := 0;

         SELECT COUNT (*)
           INTO l_unprocess_count
           FROM xxintg_wrap_matl_stg
          WHERE NVL (status, '-1') = '-1';
      END;

      fnd_file.put_line
                      (fnd_file.output,
                       '-----------------------------------------------------'
                      );
      fnd_file.put_line (fnd_file.output,
                            'Summary of MTL Transaction Load - '
                         || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS')
                        );
      fnd_file.put_line
                      (fnd_file.output,
                       '-----------------------------------------------------'
                      );
      fnd_file.put_line (fnd_file.output,
                         'TOTAL RECORD         - ' || l_total_count
                        );
      fnd_file.put_line (fnd_file.output,
                         'SUCCESS RECORDS      - ' || l_success_count
                        );
      fnd_file.put_line (fnd_file.output,
                         'FAILED RECORDS       - ' || l_fail_count
                        );
      fnd_file.put_line (fnd_file.output,
                         'UNPROCESSED RECORDS  - ' || l_unprocess_count
                        );
      fnd_file.put_line
                      (fnd_file.output,
                       '-----------------------------------------------------'
                      );
      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line
                      (fnd_file.output,
                       '-----------------------------------------------------'
                      );
      fnd_file.put_line (fnd_file.output, 'Failed Record Details');
      fnd_file.put_line
                      (fnd_file.output,
                       '-----------------------------------------------------'
                      );
      fnd_file.put_line
         (fnd_file.output,
          ' Reference      Trans Header ID      Trans Interface ID      Error Code                               Error Explanation'
         );
      fnd_file.put_line
         (fnd_file.output,
          '--------------------------------------------------------------------------------------------------------'
         );

      FOR i_error IN c_error_rep
      LOOP
         fnd_file.put_line (fnd_file.output,
                               '  '
                            || RPAD (i_error.REFERENCE, 24, ' ')
                            || RPAD (i_error.trans_header_id, 24, ' ')
                            || RPAD (i_error.trans_interface_id, 24, ' ')
                            || RPAD (i_error.ERROR_CODE, 41, ' ')
                            || RPAD (i_error.error_explanation, 100, ' ')
                           );
      END LOOP;

      fnd_file.put_line
         (fnd_file.output,
          '--------------------------------------------------------------------------------------------------------'
         );
      fnd_file.put_line
         (fnd_file.output,
          '---------------------------------- End Of Report -------------------------------------------------------'
         );
      fnd_file.put_line
         (fnd_file.output,
          '--------------------------------------------------------------------------------------------------------'
         );
   END;
END xx_mtlwrap_upd_adi_pkg;
/
