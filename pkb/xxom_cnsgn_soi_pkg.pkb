DROP PACKAGE BODY APPS.XXOM_CNSGN_SOI_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xxom_cnsgn_soi_pkg
IS
/*************************************************************************************
*   PROGRAM NAME
*     XXOM_CNSGN_SOI_PKG.sql
*
*   DESCRIPTION
*
*   USAGE
*
*    PARAMETERS
*    ==========
*    NAME                    DESCRIPTION
*    ----------------      ------------------------------------------------------
*
*   DEPENDENCIES
*
*   CALLED BY
*
*   HISTORY
*   =======
*
* VERSION    DATE        AUTHOR(S)      DESCRIPTION
* ------- ----------- ---------------     ---------------------------------------------------
*     2.0 18-OCT-2013 Brian Stadnik
*     2.1             Product request - Verify Default Org and bring order in ENTERED /BOOKED.
                      Product request - l_subinventory --> Pass Null
      2.2 12-MAR-2014 Product Request - Derived LPN ID for kitting reqs.
      2.3 23-APR-2014 Brian Stadnik   - Credit Card changes including validation and coming in
                                          entered status
      2.4 14-JUN-2014 Brian Stadnik   - Fixed bug with surgeon name DFF where it was looking
                                          at surgeon_id field instead of surgeon name - per ticket 7122
     2.5  25-JUL-2014 Jagdish         - Surgen ID derivation added Function
     2.6  25-JUL-2014 Jagdish         -- Order Header Attribute1 commented for invoice printing issue Ticket # 

     2.7  30-SEP-2014 Sri V           -- Calculate Flag set to Y for non-construct as well 
     2.8  10-OCT-2014 Sri V           -- 'No Sales Rep' populated for RECON  and Attribute20 mappted to atribute2  by balaji
     2.9  12-May-2015 Sri V           -- Manual Discount Header and Line Id Hardcoded values changed to reflect SeaSpine
******************************************************************************************/

   -- These need to just be in an fnd_lookup/quickcodes
   c_ext_request_order_type         VARCHAR2 (100)                                  := 'Product Request';
   c_ext_replenishment_order_type   VARCHAR2 (100)                                  := 'Replenishment Request';
   c_request_order_type             VARCHAR2 (100)                                  := 'ILS Product Request Order';
   c_ext_chargesheet_order_type     VARCHAR2 (100)                                  := 'Billable To Customer';
   c_chargesheet_order_type         VARCHAR2 (100)                                  := 'ILS Charge Sheet Order';
   c_ext_sample_order_type          VARCHAR2 (100)                                := 'Consigned product used as sample';
   c_sample_order_type              VARCHAR2 (100)                                  := 'ILS Sample Order';
   c_ext_sales_clincal_order_type   VARCHAR2 (100)                               := 'No charge product used clinically';
   c_sales_clinical_order_type      VARCHAR2 (100)                                  := 'ILS Sales Clinical Sample';
   c_bill_w_po_hold_line_type       VARCHAR2 (100)                                  := 'Bill Line W/PO Hold Line';
   l_bill_w_po_hold_line_type_id    NUMBER;
   c_context                        VARCHAR2 (20)                                   := 'Consignment';
   c_order_source                   VARCHAR2 (20)                                   := 'Field Inv App';
   c_mso_order_source               VARCHAR2 (20)                                   := 'ORDER ENTRY';
   g_org_id                         NUMBER                                          := 81;
   l_org_id                         NUMBER                                          := 82;
   l_organization_id                NUMBER;
   l_ship_to_org_id                 NUMBER;
   l_ship_from_org_id               NUMBER;
   l_invoice_to_org_id              NUMBER;
   l_sold_to_org_id                 NUMBER;
   l_customer_account_id            NUMBER;
   l_party_site_id                  NUMBER;
   l_surgeon_id                     VARCHAR2 (100);
   l_ship_method_code               wsh_carrier_services.ship_method_code%TYPE;
   l_location_id                    NUMBER;
   l_party_site_number              VARCHAR2 (100);
   l_cust_acct_site_id              NUMBER;
   l_site_use_id                    NUMBER                                          := NULL;
   l_email_address                  VARCHAR2 (200);
   l_inventory_item_id              NUMBER;
   l_so_lines                       xxintg_t_so_line_t;
   l_order_type                     VARCHAR2 (50);
   l_line_type                      VARCHAR2 (30);
   l_line_type_id                   NUMBER;
   l_surgery_type                   VARCHAR2 (100);
   l_surgery_code                   VARCHAR2 (100);
   l_case_number                    VARCHAR2 (100);
   l_ship_priority                  VARCHAR2 (30);
   l_construct_pricing              VARCHAR2 (10);
   l_sales_channel_code             VARCHAR2 (30);
   l_salesrep_id                    NUMBER;
   l_subinventory                   VARCHAR2 (10);
   l_locator_id                     NUMBER;
   l_order_locator_id               NUMBER;                  -- Added for populating Order Line DFF global_attribute14.
   l_order_lpn_id                   NUMBER;                  -- Added for populating Order Line DFF global_attribute15.
   l_lpn_id                         NUMBER;
   l_mtl_sales_order_id             NUMBER;
   l_log_message                    VARCHAR2 (1000);
   l_process_step                   VARCHAR2 (50);
   l_api_version_number             NUMBER                                          := 1;
   l_ord_return_status              VARCHAR2 (2000);
   l_ord_msg_count                  NUMBER;
   l_ord_msg_data                   VARCHAR2 (2000);
   l_debug_level                    NUMBER                                          := 1;
   l_header_rec                     oe_order_pub.header_rec_type;
   l_line_tbl                       oe_order_pub.line_tbl_type;
   /*******Sri Calculate Price Changes Begin*********/
   l_header_rec_update              oe_order_pub.header_rec_type;
   l_line_tbl_update                oe_order_pub.line_tbl_type;
   l_line_adj_tbl_update            oe_order_pub.line_adj_tbl_type;
   l_action_request_tbl_update      oe_order_pub.request_tbl_type;
   l_line_tbl_index                 NUMBER := 0;   
   l_header_rec_out_update          oe_order_pub.header_rec_type;
   l_header_val_rec_out_update      oe_order_pub.header_val_rec_type;
   l_header_adj_tbl_out_update      oe_order_pub.header_adj_tbl_type;
   l_header_adj_val_tbl_out_upd  oe_order_pub.header_adj_val_tbl_type;
   l_header_price_att_tbl_out_upd oe_order_pub.header_price_att_tbl_type;
   l_header_adj_att_tbl_out_upd   oe_order_pub.header_adj_att_tbl_type;
   l_header_adj_assoc_tbl_out_upd oe_order_pub.header_adj_assoc_tbl_type;
   l_header_scredit_tbl_out_upd         oe_order_pub.header_scredit_tbl_type;
   l_header_scredit_val_tbl_out_u     oe_order_pub.header_scredit_val_tbl_type;
   l_line_tbl_out_update                   oe_order_pub.line_tbl_type;
   l_line_val_tbl_out_update               oe_order_pub.line_val_tbl_type;
   l_line_adj_tbl_out_update               oe_order_pub.line_adj_tbl_type;
   l_line_adj_val_tbl_out_update           oe_order_pub.line_adj_val_tbl_type;
   l_line_price_att_tbl_out_upd         oe_order_pub.line_price_att_tbl_type;
   l_line_adj_att_tbl_out_update           oe_order_pub.line_adj_att_tbl_type;
   l_line_adj_assoc_tbl_out_upd         oe_order_pub.line_adj_assoc_tbl_type;
   l_line_scredit_tbl_update               oe_order_pub.line_scredit_tbl_type;
   l_line_scredit_val_tbl_update           oe_order_pub.line_scredit_val_tbl_type;
   l_line_scredit_tbl_out_update           oe_order_pub.line_scredit_tbl_type;
   l_line_scredit_val_tbl_out_u       oe_order_pub.line_scredit_val_tbl_type;
   l_lot_serial_tbl_out_update             oe_order_pub.lot_serial_tbl_type;
   l_lot_serial_val_tbl_out_upd         oe_order_pub.lot_serial_val_tbl_type;
   l_action_request_tbl_out_upd         oe_order_pub.request_tbl_type;
   l_msg_index_update                      NUMBER;
   l_data_update                           VARCHAR2 (2000);
   l_ord_return_status_update              VARCHAR2 (2000);
   l_ord_msg_count_update                  NUMBER;
   l_ord_msg_data_update                   VARCHAR2 (2000);
   
   /*******Sri Calculate Price Changes End*********/
   l_line_adj_tbl                   oe_order_pub.line_adj_tbl_type;
   l_action_request_tbl             oe_order_pub.request_tbl_type;
   l_header_rec_out                 oe_order_pub.header_rec_type;
   l_header_val_rec_out             oe_order_pub.header_val_rec_type;
   l_header_adj_tbl_out             oe_order_pub.header_adj_tbl_type;
   l_header_adj_val_tbl_out         oe_order_pub.header_adj_val_tbl_type;
   l_header_price_att_tbl_out       oe_order_pub.header_price_att_tbl_type;
   l_header_adj_att_tbl_out         oe_order_pub.header_adj_att_tbl_type;
   l_header_adj_assoc_tbl_out       oe_order_pub.header_adj_assoc_tbl_type;
   l_header_scredit_tbl_out         oe_order_pub.header_scredit_tbl_type;
   l_header_scredit_val_tbl_out     oe_order_pub.header_scredit_val_tbl_type;
   l_line_tbl_out                   oe_order_pub.line_tbl_type;
   l_line_val_tbl_out               oe_order_pub.line_val_tbl_type;
   l_line_adj_tbl_out               oe_order_pub.line_adj_tbl_type;
   l_line_adj_val_tbl_out           oe_order_pub.line_adj_val_tbl_type;
   l_line_price_att_tbl_out         oe_order_pub.line_price_att_tbl_type;
   l_line_adj_att_tbl_out           oe_order_pub.line_adj_att_tbl_type;
   l_line_adj_assoc_tbl_out         oe_order_pub.line_adj_assoc_tbl_type;
   l_line_scredit_tbl               oe_order_pub.line_scredit_tbl_type;
   l_line_scredit_val_tbl           oe_order_pub.line_scredit_val_tbl_type;
   l_line_scredit_tbl_out           oe_order_pub.line_scredit_tbl_type;
   l_line_scredit_val_tbl_out       oe_order_pub.line_scredit_val_tbl_type;
   l_lot_serial_tbl_out             oe_order_pub.lot_serial_tbl_type;
   l_lot_serial_val_tbl_out         oe_order_pub.lot_serial_val_tbl_type;
   l_action_request_tbl_out         oe_order_pub.request_tbl_type;
   l_msg_index                      NUMBER;
   l_data                           VARCHAR2 (2000);
   l_loop_count                     NUMBER;
   l_debug_file                     VARCHAR2 (200);
   b_return_status                  VARCHAR2 (200);
   b_msg_count                      NUMBER;
   b_msg_data                       VARCHAR2 (2000);
   l_process_status                 VARCHAR2 (10)                                   := 'S';
   l_rsv_rec                        inv_reservation_global.mtl_reservation_rec_type;
   x_return_status_resv             VARCHAR2 (10);
   x_msg_count_resv                 NUMBER;
   x_msg_data_resv                  VARCHAR2 (2000);
   v_serial_number                  inv_reservation_global.serial_number_tbl_type;
   l_serial_number                  inv_reservation_global.serial_number_tbl_type;
   v_index                          NUMBER;
   v_msg_index_out                  NUMBER;
   x_msg_data                       VARCHAR2 (2000);
   v_quantity_reserved              NUMBER;
   v_reservation_id                 NUMBER;
   e_order_error                    EXCEPTION;
   e_other_error                    EXCEPTION;
   l_header_status_code             VARCHAR2 (1);
   l_header_status_message          VARCHAR2 (200);
   l_dt_party_site_id               NUMBER;
   l_lot_expiration_date            DATE;
   l_hold_name                      VARCHAR2 (100);
   l_user_name                      VARCHAR2 (100);
   --When this is set to true, the API will update the matching order instead of creating a new one.
   l_update_mode                    BOOLEAN                                         := FALSE;
   l_existing_header_id             NUMBER;
   l_adj_list_header_id             NUMBER                                          := NULL;
   l_adj_list_line_id               NUMBER                                          := NULL;
   l_created_by_module              VARCHAR2 (100)                                  := 'ONT_PROCESS_ORDER_API';
   g_external_ord_no                VARCHAR2 (100);

--Forward Declarations
   PROCEDURE apply_hold (
      p_hold_id          IN       oe_hold_definitions.hold_id%TYPE := NULL,
      --Caller must supply one of these two values.  If both are supplied, the ID is used.
      p_hold_name        IN       oe_hold_definitions.NAME%TYPE := NULL,
      p_header_id        IN       oe_order_headers_all.header_id%TYPE,
      p_line_id          IN       oe_order_lines_all.line_id%TYPE := NULL,     --NULL line_id will create a header hold
      p_return_status    OUT      VARCHAR2,
      p_return_message   OUT      VARCHAR2
   );

   PROCEDURE book_order (
      p_header_id       IN       oe_order_headers.header_id%TYPE,
      x_return_status   OUT      VARCHAR2,
      x_message_text    OUT      VARCHAR2
   );

   PROCEDURE validate_cc_info (
      p_cc_code              IN       VARCHAR2,
      p_cc_number            IN       VARCHAR2,
      p_cc_expiration_date   IN       VARCHAR2,
      p_cc_holder_name       IN       VARCHAR2,
      x_payment_type_code    OUT      VARCHAR2,
      x_cc_code              OUT      VARCHAR2,
      x_cc_number            OUT      VARCHAR2,
      x_cc_expiration_date   OUT      DATE,
      x_cc_holder_name       OUT      VARCHAR2
   );

   PROCEDURE create_deliver_to_site (
      p_external_ord_no     IN       VARCHAR2,
      p_srep_number         IN       VARCHAR2,
      p_party_site_number   IN       VARCHAR2,
      p_address_1           IN       VARCHAR2,
      p_address_2           IN       VARCHAR2,
      p_city                IN       VARCHAR2,
      p_state               IN       VARCHAR2,
      p_postal_code         IN       VARCHAR2,
      x_site_use_id         OUT      NUMBER,
      x_return_status       OUT      VARCHAR2,
      x_return_code         OUT      VARCHAR2,
      x_return_message      OUT      VARCHAR2
   );

   PROCEDURE create_location (
      p_external_ord_no   IN       VARCHAR2,
      p_party_id          IN       NUMBER,
      p_loc_data          IN       hz_location_v2pub.location_rec_type,
      x_location_id       OUT      NUMBER
   );

   PROCEDURE create_sites (
      p_external_ord_no     IN       VARCHAR2,
      p_party_id            IN       NUMBER,
      p_cust_acct_id        IN       NUMBER,
      p_location_id         IN       NUMBER,
      p_salesrep_number     IN       VARCHAR2,
      x_cust_acct_site_id   OUT      NUMBER
   );

   PROCEDURE create_site_use (
      p_external_ord_no     IN       VARCHAR2,
      p_cust_acct_site_id   IN       NUMBER,
      p_site_use_code       IN       VARCHAR2,
      x_site_use_id         OUT      NUMBER
   );

   PROCEDURE log_message (p_log_message IN VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      NULL;
      INSERT INTO xxintg_cnsgn_cmn_log_tbl
           VALUES (xxintg_cnsgn_cmn_log_seq.NEXTVAL,
                   'XXOM_CNSGN_SOI_PKG',
                   g_external_ord_no||p_log_message,
                   SYSDATE
                  );

      COMMIT;
      --DBMS_OUTPUT.put_line ('log message: ' || p_log_message);
   END log_message;

   FUNCTION get_surgeon_name (p_surgeon_id IN VARCHAR2, p_surgeon_name IN VARCHAR2, p_external_ord_no IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_surgeon_rec_id   VARCHAR2 (400);
--P_EXTERNAL_ORD_NO varchar2(400) :='9999999';
   BEGIN
      SELECT rec_id
        INTO l_surgeon_rec_id
        FROM xxintg_hcp_int_main
       WHERE npi = p_surgeon_id;

      RETURN l_surgeon_rec_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         log_message (p_external_ord_no || ' Unable to find l_surgeon_id: ' || p_surgeon_id);
         log_message (p_external_ord_no || ' Unable to find p_surgeon_name using NPI: ' || p_surgeon_name);

         BEGIN
            --If a name was passed, it will be in the format first,last
            SELECT rec_id
              INTO l_surgeon_rec_id
              FROM xxintg_hcp_int_main
             WHERE doctors_last_name = TRIM (SUBSTR (UPPER (p_surgeon_name), INSTR (UPPER (p_surgeon_name), ',') + 1))
               AND doctors_first_name =
                                       TRIM (SUBSTR (UPPER (p_surgeon_name), 1, INSTR (UPPER (p_surgeon_name), ',') - 1));

            RETURN l_surgeon_rec_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               BEGIN
                  SELECT surgeon_name
                    INTO l_surgeon_rec_id
                    FROM xx_om_nonnpi_surgeons
                   WHERE surgeon_name = p_surgeon_name;

                  log_message (   p_external_ord_no
                               || ' (3) Surgeon  found in Non NPI Data. Returning the same surgeon: '
                               || p_surgeon_name
                              );
                  RETURN l_surgeon_rec_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     log_message (   p_external_ord_no
                                  || ' (3) Surgeon not found in Non NPI Data. Inserting into table: '
                                  || p_surgeon_name
                                 );

                     INSERT INTO xx_om_nonnpi_surgeons
                                 (npi,
                                  rec_id,
                                  surgeon_name
                                 )
                          VALUES ('-99',
                                  '-99',
                                  p_surgeon_name
                                 );

                     l_surgeon_rec_id           := p_surgeon_name;
                     log_message (p_external_ord_no || ' (3) l_surgeon_rec_id: ' || l_surgeon_rec_id);
                     RETURN l_surgeon_rec_id;
               END;
         END;
      WHEN OTHERS
      THEN
         log_message (p_external_ord_no || ' (4) l_surgeon_id: ' || p_surgeon_name);
         l_surgeon_rec_id           := NULL;
   END;

   PROCEDURE initialize_values (
      p_first_item        IN       VARCHAR2,
      p_organization_id   OUT      NUMBER,
      p_return_status     IN OUT   VARCHAR2,
      p_return_code       IN OUT   VARCHAR2,
      p_return_message    IN OUT   VARCHAR2
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      l_user_id   NUMBER;
   BEGIN
      DBMS_OUTPUT.put_line ('initializing variables...');
      mo_global.set_policy_context ('S', g_org_id);
      mo_global.init ('ONT');
      oe_msg_pub.initialize;
      oe_debug_pub.initialize;
      oe_debug_pub.setdebuglevel (5);
      oe_debug_pub.debug_on;

      BEGIN
         SELECT organization_id
           INTO p_organization_id
           FROM mtl_parameters
          WHERE organization_code = '150';
      END;

      BEGIN
         --SELECT snm_division
           --INTO l_inventory_item_id
           --FROM mtl_system_items_b msib
          --WHERE organization_id = l_organization_id AND segment1 = l_so_lines (i).item;
         BEGIN
            SELECT user_id
              INTO l_user_id
              FROM fnd_user
             WHERE UPPER (user_name) = l_user_name;

            log_message ('User ID is: ' || l_user_name || ' - ' || l_user_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               BEGIN
                  --Get a default user for the current division
                  SELECT user_id
                    INTO l_user_id
                    FROM fnd_user fu,
                         fnd_lookup_values_vl lu,
                         mtl_system_items msi,
                         xxom_sales_marketing_set_v snm
                   WHERE msi.segment1 = p_first_item
                     AND msi.organization_id = p_organization_id
                     AND msi.inventory_item_id = snm.inventory_item_id
                     AND msi.organization_id = snm.organization_id
                     AND lu.lookup_type = 'SOI_USER_NAME_DEFAULT'
                     AND lu.lookup_code = snm.snm_division
                     AND lu.meaning = fu.user_name;

                  log_message ('User ID is Division default: ' || l_user_id);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_user_id                  := -1;
                     log_message ('User ID is the failsafe: ' || l_user_id);
               END;
         END;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_return_message           := 'apps_initialize error.';
            RAISE;
      END;

      fnd_global.apps_initialize (user_id           => l_user_id, resp_id => 21623,        -- Order Managment Super User
                                  resp_appl_id      => 660);
      DBMS_OUTPUT.put_line ('Complete initializing variables...');
   EXCEPTION
      WHEN OTHERS
      THEN
         p_return_status            := 'E';
         p_return_code              := SQLCODE;
         p_return_message           := p_return_message;
         DBMS_OUTPUT.put_line (p_return_message);
   END initialize_values;

   PROCEDURE create_sales_order_header (
      p_external_ord_no         IN       VARCHAR2,
      p_sales_rep_number        IN       VARCHAR2,
      p_surgery_date            IN       DATE,
      p_order_type              IN       VARCHAR2,
      p_cust_po_number          IN       VARCHAR2,
      p_ship_to_acct_num        IN       NUMBER,
      p_invoice_to_acct_num     IN       NUMBER,
      p_ship_to_site_id         IN       NUMBER,
      p_invoice_to_site_id      IN       NUMBER,
      p_ship_method_flag        IN       VARCHAR2,
      p_surgeon_name            IN       VARCHAR2,
      p_patient_id              IN       VARCHAR2,
      p_header_status_code      IN OUT   VARCHAR2,
      p_header_status_message   IN OUT   VARCHAR2,
      p_party_site_id           IN       NUMBER,
      p_dt_party_site_id        IN       NUMBER,                                                                  -- new
      p_dt_attn_contact         IN       VARCHAR2,                                                                -- new
      p_dt_attn_company         IN       VARCHAR2,                                                                -- new
      p_cc_code                 IN       VARCHAR2,                                                                -- new
      p_cc_holder_name          IN       VARCHAR2,                                                                -- new
      p_cc_number               IN       VARCHAR2,                                                                 --new
      p_cc_expiration_date               VARCHAR2                                                                  --new
   )
   --p_so_lines     IN   xxintg_t_so_line_t)
   IS
      l_order_type_id          NUMBER;
      l_price_list_id          NUMBER;
      l_order_source_id        NUMBER;
      l_salesrep_id            NUMBER;
      l_surgeon_rec_id         VARCHAR2(400);
      l_bill_to_site_use_id    NUMBER;
      l_duplicate_po_reason    VARCHAR2 (50);
      l_header_payment_rec     oe_order_pub.header_payment_rec_type;
      l_party_name             hz_parties.party_name%TYPE;
      l_rel_party_name         hz_parties.party_name%TYPE;
      l_rel_acct_num           hz_cust_accounts.account_number%TYPE;
      l_rel_cust_acct_id       hz_cust_accounts.cust_account_id%TYPE;
      l_orig_cust_account_id   NUMBER;
   BEGIN
      l_bill_to_site_use_id      := NULL;
      l_order_type_id            := NULL;
      l_order_source_id          := NULL;
      l_salesrep_id              := NULL;
      l_surgeon_rec_id           := NULL;
      l_duplicate_po_reason      := 'Not Applicable';

-- use flags to find out the appropriate order and line types
      IF p_order_type = c_ext_request_order_type
      THEN
         l_order_type               := c_request_order_type;
         l_line_type                := 'ILS Consignment Request';
      ELSIF p_order_type = c_ext_replenishment_order_type
      THEN
         l_order_type               := c_request_order_type;
         l_line_type                := 'ILS Kitting Request';
      ELSIF p_order_type = c_ext_sample_order_type
      THEN
         l_order_type               := c_sample_order_type;
         l_line_type                := 'Sample Line';
      ELSIF p_order_type = c_ext_sales_clincal_order_type
      THEN
         l_order_type               := c_sales_clinical_order_type;
         l_line_type                := 'Clinical Eval Line';
      ELSIF p_order_type = c_ext_chargesheet_order_type
      THEN
         l_order_type               := c_chargesheet_order_type;
      END IF;

      log_message (p_external_ord_no || 'l_order_type: ' || l_order_type);

      BEGIN
         SELECT ott.transaction_type_id,
                ott.price_list_id
           INTO l_order_type_id,
                l_price_list_id
           FROM oe_transaction_types_all ott,
                oe_transaction_types_tl otl
          WHERE NVL (ott.end_date_active, SYSDATE + 1) > SYSDATE
            AND ott.transaction_type_code = 'ORDER'
            AND otl.transaction_type_id = ott.transaction_type_id
            AND otl.LANGUAGE = 'US'                                                                   -- USERENV('LANG')
            AND otl.NAME = l_order_type;
      EXCEPTION
         WHEN OTHERS
         THEN
            log_message (p_external_ord_no || 'Unable to find Transaction Line Type. ' || l_order_type);
      /*  p_return_status            := 'E';
         p_return_code              := SQLCODE;
         p_return_message           := 'Unable to find Transaction Line Type. '||l_order_type||' - '|| SQLERRM ;
         RAISE e_other_error;
      */
      END;

      BEGIN
         SELECT oos.order_source_id
           INTO l_order_source_id
           FROM oe_order_sources oos
          WHERE oos.NAME = c_order_source AND NVL (oos.enabled_flag, 'Y') = 'Y';
      EXCEPTION
         WHEN OTHERS
         THEN
            -- ingnore this error the order will be created, but won't book
--            NULL;
          -- fnd_file.put_line(fnd_file.log,'Unable to find order source id for order source "Consignment Front End"');
            log_message (p_external_ord_no || 'Unable to find order_source_id. ' || c_order_source);
      /*
          p_return_status            := 'E';
          p_return_code              := SQLCODE;
          p_return_message           := 'Unable to find order_source_id. '||c_order_source||' - '|| SQLERRM ;
          RAISE e_other_error;
      */
      END;

      IF l_order_type = c_request_order_type
      THEN
         -- The rep is the customer, so get their customer info
         -- or it is a kitting center request
         log_message (p_external_ord_no || 'p_sales_rep_number: ' || p_sales_rep_number);

         IF (p_sales_rep_number < 0)
         THEN                                                                                                -- Jagdish
            log_message (p_external_ord_no || 'Product Request for Kitting Center.');
            l_duplicate_po_reason      := 'Other';

            -- this is a special rep e.g. Kitting Center requesting Product
            BEGIN
               SELECT ship_to.site_use_id,
                      bill_to.site_use_id,
                      pla.customer_id
                 INTO l_ship_to_org_id,
                      l_invoice_to_org_id,
                      l_sold_to_org_id
                 FROM mtl_secondary_inventories msi,
                      hr_locations hl,
                      po_location_associations_all pla,
                      hz_cust_site_uses_all ship_to,
                      hz_cust_site_uses_all bill_to,
                      apps.fnd_flex_values_vl ffvv,
                      apps.fnd_flex_value_sets ffvs
                WHERE bill_to.site_use_code = 'BILL_TO'
                  AND bill_to.cust_acct_site_id = ship_to.cust_acct_site_id
                  AND ship_to.site_use_id = pla.site_use_id
                  AND pla.location_id = hl.location_id
                  AND hl.location_id = msi.location_id
                  AND msi.secondary_inventory_name = ffvv.description                                    -- 'ODCRECONKT'
                  AND ffvv.flex_value = p_sales_rep_number
                  AND ffvs.flex_value_set_name = 'INTG_KITTING_CENTERS'
                  AND ffvv.enabled_flag = 'Y'
                  AND ffvv.flex_value_set_id = ffvs.flex_value_set_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  log_message (p_external_ord_no || 'Unable Customer Infor for Rep ' || p_sales_rep_number);
                  p_header_status_code       := 'E';
                  p_header_status_message    :=
                                              'Unable Customer Info for Rep ' || p_sales_rep_number || ' - ' || SQLERRM;
            END;

            log_message (   p_external_ord_no
                         || 'kitting center ship to, bill to, customer: '
                         || l_ship_to_org_id
                         || ': '
                         || l_invoice_to_org_id
                         || ': '
                         || l_sold_to_org_id
                        );
         ELSE
            log_message (p_external_ord_no || 'Product Request for Rep.');

            BEGIN
                           /*
                              SELECT ship_to.site_use_id,
                                     bill_to.site_use_id,
                                     pla.customer_id
                                INTO l_ship_to_org_id,
                                     l_invoice_to_org_id,
                                     l_sold_to_org_id
                                FROM
               -- jtf_rs_salesreps jrs,                                                                                           -- hr_employees he,
                                     mtl_secondary_inventories msi,
                                     hr_locations hl,
                                     po_location_associations_all pla,
                                     hz_cust_site_uses_all ship_to,
                                     hz_cust_site_uses_all bill_to
                               WHERE bill_to.site_use_code = 'BILL_TO'
                                 AND bill_to.cust_acct_site_id = ship_to.cust_acct_site_id
                                 AND ship_to.site_use_id = pla.site_use_id
                                 AND pla.location_id = hl.location_id
                                 AND hl.location_id = msi.location_id
                                 AND msi.attribute2 = p_sales_rep_number;
                                 */

               -- Changed logic to accomadate dealers like Black Diamond
               SELECT ship_to.site_use_id,
                      bill_to.site_use_id,
                      pla.customer_id
                 INTO l_ship_to_org_id,
                      l_invoice_to_org_id,
                      l_sold_to_org_id
                 FROM
-- jtf_rs_salesreps jrs,                                                                                           -- hr_employees he,
                      mtl_secondary_inventories msi,
                      mtl_item_locations mil,
                      hr_locations hl,
                      po_location_associations_all pla,
                      hz_cust_site_uses_all ship_to,
                      hz_cust_acct_sites_all st_cas,
                      hz_cust_acct_sites_all bt_cas,
                      hz_cust_site_uses_all bill_to
                WHERE bill_to.site_use_code = 'BILL_TO'
                  AND bill_to.primary_flag = 'Y'
                  AND ship_to.cust_acct_site_id = st_cas.cust_acct_site_id
                  AND st_cas.cust_account_id = bt_cas.cust_account_id
                  AND bt_cas.cust_acct_site_id = bill_to.cust_acct_site_id
                  AND ship_to.site_use_id = pla.site_use_id
                  AND pla.location_id = hl.location_id
                  AND hl.location_id = msi.location_id
                  AND msi.secondary_inventory_name = mil.subinventory_code
                  AND (msi.attribute2 = p_sales_rep_number OR mil.attribute3 = p_sales_rep_number)
                  AND ROWNUM < 2;
                               --Added to prevent too_many_rows if a multi-locator subinv is still linked on the subinv.

               --AND msi.attribute2 = p_sales_rep_number;

               -- and msi.description = he.full_name
               -- and   jrs.person_id = he.employee_id
               -- and   jrs.salesrep_number = p_sales_rep_number; -- '12004'
               log_message (   p_external_ord_no
                            || 'product request ship to, bill to, customer: '
                            || l_ship_to_org_id
                            || ': '
                            || l_invoice_to_org_id
                            || ': '
                            || l_sold_to_org_id
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  -- we will still enter the order, but it will go on hold
                  NULL;
                  -- fnd_file.put_line(fnd_file.log,'Unable to find order source id for order source "Consignment Front End"');
                  log_message (   p_external_ord_no
                               || 'unable to find ship to, bill to, customer: '
                               || l_ship_to_org_id
                               || ': '
                               || l_invoice_to_org_id
                               || ': '
                               || l_sold_to_org_id
                              );
            END;
         END IF;
      ELSE
         log_message (p_external_ord_no || 'Getting Charge Sheet Customer for: ' || l_party_site_id);
-----------------------------------------------------------
-- All Order should come in BOOKED Status -- JB 03/12/2014
-----------------------------------------------------------
-- l_header_rec.booked_flag   := 'N';
-- l_header_rec.flow_status_code := 'ENTERED';
         log_message (p_external_ord_no || ' Finding Bill To and Ship To INFO for : ' || l_party_site_id);

         BEGIN
            SELECT site_use_id,
                   hcsu.bill_to_site_use_id,
                   hcas.cust_account_id
              INTO l_ship_to_org_id,
                   l_bill_to_site_use_id,
                   l_orig_cust_account_id                           --Capture this now in case a Bill To is never found.
              FROM hz_cust_site_uses_all hcsu,
                   hz_cust_acct_sites_all hcas,
                   hz_party_sites hps
             WHERE hcas.party_site_id = hps.party_site_id
               AND hps.party_site_number = TO_CHAR (l_party_site_id)                                             --03.01
               AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
               AND hcsu.site_use_code = 'SHIP_TO'
               AND hcsu.status = 'A';

            --  p_ship_to_acct_num      IN   NUMBER,
            --  p_invoice_to_acct_num   IN   NUMBER,
            --  p_ship_to_site_id       IN   NUMBER,
            log_message (p_external_ord_no || 'SHIP_TO: ' || l_ship_to_org_id || ' for Cust ID '
                         || l_orig_cust_account_id
                        );
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               -- USE PRIMARY SHIP TO FOR THE ACCOUNT NUMBER
               BEGIN
                  SELECT hcsu.site_use_id,
                         hcsu.bill_to_site_use_id,
                         hcas.cust_account_id
                    INTO l_ship_to_org_id,
                         l_bill_to_site_use_id,
                         l_sold_to_org_id
                    FROM hz_cust_site_uses_all hcsu,
                         hz_cust_acct_sites_all hcas,
                         hz_cust_accounts hca
                   WHERE hcas.cust_account_id = hca.cust_account_id
                     AND hca.account_number = TO_CHAR (p_ship_to_acct_num)
                     AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                     AND hcsu.site_use_code = 'SHIP_TO'
                     AND hcsu.primary_flag = 'Y'
                     AND hcsu.status = 'A';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     log_message (p_external_ord_no || ' Unable to derive the ship to site id');
                     l_invoice_to_org_id        := NULL;
               END;

               log_message (p_external_ord_no || 'Unable to find SHIP_TO from Party Site Number; Used Acct Number: ');
            WHEN OTHERS
            THEN
               log_message (p_external_ord_no || ' Unable to derive the ship to site id');
               l_ship_to_org_id           := NULL;
         END;

         log_message (p_external_ord_no || ' l_bill_to_site_use_id: ' || l_bill_to_site_use_id);

         IF (l_bill_to_site_use_id IS NOT NULL)
         THEN
            l_invoice_to_org_id        := l_bill_to_site_use_id;

            BEGIN
               SELECT hca.cust_account_id
                 INTO l_sold_to_org_id
                 FROM hz_cust_accounts hca
                WHERE hca.account_number = TO_CHAR (p_ship_to_acct_num);

               log_message (p_external_ord_no || ' l_sold_to_org_id: ' || l_sold_to_org_id);
            EXCEPTION
               WHEN OTHERS
               THEN
                  log_message (p_external_ord_no || ' Unable to find cust_account_id for : ' || p_ship_to_acct_num);
            END;
         END IF;

         IF (l_invoice_to_org_id IS NULL) OR (l_sold_to_org_id IS NULL)
         THEN
            BEGIN
               SELECT NVL (l_invoice_to_org_id, hcsu.site_use_id),
                      hcas.cust_account_id
                 INTO l_invoice_to_org_id,
                      l_sold_to_org_id
                 FROM hz_cust_site_uses_all hcsu,
                      hz_cust_acct_sites_all hcas,
                      hz_party_sites hps
                WHERE hcas.party_site_id = hps.party_site_id
                  AND hps.party_site_number = TO_CHAR (l_party_site_id)
                  -- l_party_site_id is actually the party_site_number
                  AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                  AND hcsu.site_use_code = 'BILL_TO'
                  AND hcsu.status = 'A';

               log_message (   p_external_ord_no
                            || 'ship to, bill to, customer: '
                            || l_ship_to_org_id
                            || ': '
                            || l_invoice_to_org_id
                            || ': '
                            || l_sold_to_org_id
                           );
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  -- USE PRIMARY BILL TO FOR THE ACCOUNT NUMBER
                  BEGIN
                     SELECT hcsu.site_use_id,
                            hcas.cust_account_id
                       INTO l_invoice_to_org_id,
                            l_sold_to_org_id
                       FROM hz_cust_site_uses_all hcsu,
                            hz_cust_acct_sites_all hcas,
                            hz_cust_accounts hca
                      WHERE hcas.cust_account_id = hca.cust_account_id
                        AND hca.account_number = TO_CHAR (p_ship_to_acct_num)
                        AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                        AND hcsu.site_use_code = 'BILL_TO'
                        AND hcsu.primary_flag = 'Y'
                        AND hcsu.status = 'A';
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        log_message (   p_external_ord_no
                                     || ' Unable to derive the bill to site id from primary bill to account: '
                                     || p_ship_to_acct_num
                                    );
                        l_invoice_to_org_id        := NULL;
                        p_header_status_code       := 'x';
                        p_header_status_message    :=
                              'Unable to find Customer Info for Acct Num '
                           || p_ship_to_acct_num
                           || ' and party_site_number '
                           || l_party_site_id;
                  END;
               WHEN OTHERS
               THEN
                  log_message (p_external_ord_no || ' Unable to derive the bill to site id');
                  l_invoice_to_org_id        := NULL;
                  p_header_status_code       := 'x';
                  p_header_status_message    :=
                        'Unable to find Customer Info for Acct Num '
                     || p_ship_to_acct_num
                     || ' and party_site_number '
                     || l_party_site_id;
            END;
         END IF;

         --If invoice_to_org_id is still null, look for exactly one related, primary, BILL_TO site use and use it.
         --If making this switch, also change the sold_to_org_id to the related customer.
         IF l_invoice_to_org_id IS NULL AND p_ship_to_acct_num IS NOT NULL
         THEN
            BEGIN
               --Get a primary BILL_TO site use from a related customer.
               --Do not select a value if there are multiple hits or 0 hits.
               SELECT p.party_name main_name,
                      rel_p.party_name rel_name,
                      rel_ca.account_number rel_acct_num,
                      rel_ca.cust_account_id rel_cust_acct_id,
                      --rel_site.cust_acct_site_id, rel_su.primary_flag, rel_su.site_use_code,
                      rel_su.site_use_id
                 INTO l_party_name,
                      l_rel_party_name,
                      l_rel_acct_num,
                      l_rel_cust_acct_id,
                      l_invoice_to_org_id
                 FROM hz_cust_accounts ca,
                      hz_parties p,
                      hz_cust_acct_relate_all rel,
                      hz_cust_accounts rel_ca,
                      hz_parties rel_p,
                      hz_cust_acct_sites_all rel_site,
                      hz_cust_site_uses_all rel_su
                WHERE ca.account_number = TO_CHAR (p_ship_to_acct_num)
                  AND ca.party_id = p.party_id
                  AND ca.cust_account_id = rel.cust_account_id
                  --AND upper(rel.comments) LIKE 'PARENT%BILLER'
                  AND rel.related_cust_account_id = rel_ca.cust_account_id
                  AND rel_ca.party_id = rel_p.party_id
                  AND rel_ca.cust_account_id = rel_site.cust_account_id
                  AND rel_site.cust_acct_site_id = rel_su.cust_acct_site_id
                  AND rel_su.site_use_code = 'BILL_TO'
                  AND rel_su.primary_flag = 'Y'
                  AND rel.status = 'A'
                  AND rel_ca.status = 'A'
                  AND rel_site.status = 'A'
                  AND rel_su.status = 'A';

               log_message (   p_external_ord_no
                            || ' Found l_invoice_to_org_id: '
                            || l_invoice_to_org_id
                            || ' using relationship:'
                           );
               log_message (   p_external_ord_no
                            || ' '
                            || l_party_name
                            || ' -> '
                            || l_rel_party_name
                            || ' ('
                            || l_rel_acct_num
                            || ')'
                           );
               log_message (   p_external_ord_no
                            || ' Changing Sold To Org ID from: '
                            || l_sold_to_org_id
                            || ' to '
                            || l_rel_cust_acct_id
                           );
               l_sold_to_org_id           := l_rel_cust_acct_id;
            EXCEPTION
               WHEN TOO_MANY_ROWS
               THEN
                  --There are too many possible choices when looking at ALL related customers, so limit the relationships
                  -- to only those like PARENT%BILLER.
                  log_message (p_external_ord_no || ' Too many relationships.  Checking for PARENT_BILLER.');

                  BEGIN
                     --Get a primary BILL_TO site use from a PARENT_BILLER related customer.
                     --Do not select a value if there are multiple hits or 0 hits.
                     SELECT p.party_name main_name,
                            rel_p.party_name rel_name,
                            rel_ca.account_number rel_acct_num,
                            rel_ca.cust_account_id rel_cust_acct_id,
                            --rel_site.cust_acct_site_id, rel_su.primary_flag, rel_su.site_use_code,
                            rel_su.site_use_id
                       INTO l_party_name,
                            l_rel_party_name,
                            l_rel_acct_num,
                            l_rel_cust_acct_id,
                            l_invoice_to_org_id
                       FROM hz_cust_accounts ca,
                            hz_parties p,
                            hz_cust_acct_relate_all rel,
                            hz_cust_accounts rel_ca,
                            hz_parties rel_p,
                            hz_cust_acct_sites_all rel_site,
                            hz_cust_site_uses_all rel_su
                      WHERE ca.account_number = TO_CHAR (p_ship_to_acct_num)
                        AND ca.party_id = p.party_id
                        AND ca.cust_account_id = rel.cust_account_id
                        AND UPPER (rel.comments) LIKE 'PARENT%BILLER'
                        AND rel.related_cust_account_id = rel_ca.cust_account_id
                        AND rel_ca.party_id = rel_p.party_id
                        AND rel_ca.cust_account_id = rel_site.cust_account_id
                        AND rel_site.cust_acct_site_id = rel_su.cust_acct_site_id
                        AND rel_su.site_use_code = 'BILL_TO'
                        AND rel_su.primary_flag = 'Y'
                        AND rel.status = 'A'
                        AND rel_ca.status = 'A'
                        AND rel_site.status = 'A'
                        AND rel_su.status = 'A';

                     log_message (   p_external_ord_no
                                  || ' Found l_invoice_to_org_id: '
                                  || l_invoice_to_org_id
                                  || ' using PARENT_BILLER relationship:'
                                 );
                     log_message (   p_external_ord_no
                                  || ' '
                                  || l_party_name
                                  || ' -> '
                                  || l_rel_party_name
                                  || ' ('
                                  || l_rel_acct_num
                                  || ')'
                                 );
                     log_message (   p_external_ord_no
                                  || ' Changing Sold To Org ID from: '
                                  || l_sold_to_org_id
                                  || ' to '
                                  || l_rel_cust_acct_id
                                 );
                     l_sold_to_org_id           := l_rel_cust_acct_id;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        log_message (   p_external_ord_no
                                     || ' Unable to derive the bill to site id using PARENT_BILLER relationships.'
                                    );
                        l_invoice_to_org_id        := NULL;
                        p_header_status_code       := 'x';    --Changed from E to allow order without a bill_to site_use
                        p_header_status_message    :=
                              'Unable to find Customer Info for Acct Num '
                           || p_ship_to_acct_num
                           || ' and party_site_number '
                           || l_party_site_id;
                  END;
               WHEN OTHERS
               THEN
                  log_message (p_external_ord_no || ' Unable to derive the bill to site id using relationships.');
                  l_invoice_to_org_id        := NULL;
                  p_header_status_code       := 'x';         --Changed from E to allow order without a bill_to site_use
                  p_header_status_message    :=
                        'Unable to find Customer Info for Acct Num '
                     || p_ship_to_acct_num
                     || ' and party_site_number '
                     || l_party_site_id;
            END;
         END IF;
      END IF;

      --If ship to cust data is inadequate at this point, fail the request and provide feedback to the user.
      IF l_ship_to_org_id IS NULL
      THEN
         p_header_status_code       := 'E';
         p_header_status_message    :=
               'Unable to find Customer Info for Acct Num '
            || p_ship_to_acct_num
            || ' and party_site_number '
            || l_party_site_id;
      END IF;

      BEGIN
         SELECT lookup_code
           INTO l_sales_channel_code
           FROM apps.oe_lookups
          WHERE UPPER (meaning) = 'FIELD INV APP' AND lookup_type = 'SALES_CHANNEL' AND enabled_flag = 'Y';

         DBMS_OUTPUT.put_line ('l_sales_channel_code: ' || l_sales_channel_code);
         log_message (p_external_ord_no || 'l_sales_channel_code: ' || l_sales_channel_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            -- we will still enter the order, but it will go on hold
            NULL;
      -- fnd_file.put_line(fnd_file.log,'Unable to find order source id for order source "Consignment Front End"');
      END;

      IF p_ship_method_flag IS NOT NULL
      THEN
         BEGIN
            SELECT ship_method_code
              INTO l_ship_method_code
              FROM wsh_carrier_services
             WHERE ship_method_meaning = p_ship_method_flag;
         EXCEPTION
            WHEN OTHERS
            THEN
               -- we will still enter the order, but it will default the customer or order ship method
               NULL;
               log_message (p_external_ord_no || 'Unable to find ship_method_code for: ' || p_ship_method_flag);
         END;
      END IF;

      IF l_surgery_type IS NOT NULL
      THEN
         BEGIN
            SELECT segment1
              INTO l_surgery_code
              FROM xx_om_construct_surgery_v
             WHERE description = l_surgery_type;
         EXCEPTION
            WHEN OTHERS
            THEN
               -- we will still enter the order, but it will default the customer or order ship method
               NULL;
               log_message (p_external_ord_no || 'Unable to find surgery type for: ' || l_surgery_type);
         END;
      END IF;

      IF p_sales_rep_number < 0
      THEN
         l_salesrep_id              := -3;
      ELSE
         BEGIN
            SELECT salesrep_id
              INTO l_salesrep_id
              FROM jtf_rs_salesreps
             WHERE salesrep_number = p_sales_rep_number;
         EXCEPTION
            WHEN OTHERS
            THEN
               -- we will still enter the order, but it will not be able to be booked
               NULL;
               -- fnd_file.put_line(fnd_file.log,'Unable to find order source id for order source "Consignment Front End"');
               log_message (p_external_ord_no || 'Cannot Find Sales Rep id for: ' || p_sales_rep_number);
         END;
      END IF;

      l_header_rec               := oe_order_pub.g_miss_header_rec;

      --If this is an UPDATE, then we need to severely limit what values are assigned to l_header_rec.
      IF l_update_mode
      THEN
         l_header_rec.operation     := oe_globals.g_opr_update;
         l_header_rec.header_id     := l_existing_header_id;
         l_header_rec.cust_po_number := p_cust_po_number;
         --If cc data is incomplete or invalid, all of these fields will be cleared.
         validate_cc_info (p_cc_code                 => p_cc_code,
                           p_cc_number               => p_cc_number,
                           p_cc_expiration_date      => p_cc_expiration_date,
                           p_cc_holder_name          => p_cc_holder_name,
                           x_payment_type_code       => l_header_rec.payment_type_code,
                           x_cc_code                 => l_header_rec.credit_card_code,
                           x_cc_number               => l_header_rec.credit_card_number,
                           x_cc_expiration_date      => l_header_rec.credit_card_expiration_date,
                           x_cc_holder_name          => l_header_rec.credit_card_holder_name
                          );
      ELSE
         l_header_rec.operation     := oe_globals.g_opr_create;
         l_header_rec.order_type_id := l_order_type_id;
         l_header_rec.order_source_id := l_order_source_id;
         l_header_rec.orig_sys_document_ref := p_external_ord_no;
--         l_header_rec.orig_sys_document_ref := p_external_ord_no||sysdate;
         log_message (p_external_ord_no || ' l_sold_to_org_id: ' || l_sold_to_org_id);

         IF (l_sold_to_org_id IS NOT NULL)
         THEN
            l_header_rec.sold_to_org_id := l_sold_to_org_id;
         ELSE
            log_message (p_external_ord_no || ' Setting Sold To to the original Cust ID: ' || l_orig_cust_account_id);
            l_sold_to_org_id           := l_orig_cust_account_id;
            l_header_rec.sold_to_org_id := l_orig_cust_account_id;
         END IF;

         --  l_header_rec.sold_from_org_id := v_sold_from_org_id;
         --  l_header_rec.ship_from_org_id := v_ship_from_org_id;
         log_message (p_external_ord_no || ' l_site_use_id: ' || l_site_use_id);

         IF (l_order_type = c_request_order_type) AND (l_site_use_id IS NOT NULL)
         THEN
            log_message (p_external_ord_no || ' deliver_to_org_id being set to: ' || '*' || l_site_use_id || '*');
            l_header_rec.deliver_to_org_id := l_site_use_id;
         END IF;

         IF l_order_type = c_chargesheet_order_type AND l_site_use_id IS NOT NULL
         THEN
            log_message (p_external_ord_no || ' ISO deliver_to being saved to ATTRIBUTE18: ' || '*' || l_site_use_id
                         || '*'
                        );
            l_header_rec.attribute18   := l_site_use_id;
         END IF;

         log_message (p_external_ord_no || ' l_ship_to_org_id: ' || l_ship_to_org_id);

         IF (l_ship_to_org_id IS NOT NULL)
         THEN
            l_header_rec.ship_to_org_id := l_ship_to_org_id;
         END IF;

         l_header_rec.sales_channel_code := l_sales_channel_code;
         log_message (p_external_ord_no || 'l_invoice_to_org_id: ' || l_invoice_to_org_id);
         l_header_rec.invoice_to_org_id := l_invoice_to_org_id;
         l_header_rec.org_id        := g_org_id;

         --Removed to create orders in ENTERED
         --l_header_rec.booked_date   := SYSDATE;

         --  l_header_rec.price_list_id := v_price_list_id;
         --  l_header_rec.pricing_date := v_ss_ordered_date;
         IF (l_ship_method_code IS NOT NULL)
         THEN
            l_header_rec.shipping_method_code := l_ship_method_code;
         END IF;

         IF l_surgery_code IS NOT NULL
         THEN
            l_header_rec.attribute11   := l_surgery_code;
         END IF;

         -- Look up the surgeon record id-
         l_surgeon_rec_id           := get_surgeon_name (l_surgeon_id, p_surgeon_name, p_external_ord_no);
         /* BEGIN
              SELECT rec_id
              INTO   l_surgeon_rec_id
              FROM   XXINTG_HCP_INT_MAIN
              WHERE  npi = l_surgeon_id;

          EXCEPTION
          WHEN NO_DATA_FOUND THEN
              log_message (p_external_ord_no || ' Unable to find l_surgeon_id: ' || l_surgeon_id);
              BEGIN
                 --If a name was passed, it will be in the format first,last
                 SELECT rec_id
                 INTO   l_surgeon_rec_id
                 FROM   XXINTG_HCP_INT_MAIN
                 WHERE doctors_last_name =  TRIM (SUBSTR( UPPER(p_surgeon_name) , INSTR( UPPER (p_surgeon_name), ',') + 1)) --Trim in case the sent first, last
                 AND   doctors_first_name = TRIM (SUBSTR( UPPER(p_surgeon_name) , 1, INSTR( UPPER (p_surgeon_name), ',') - 1));
              EXCEPTION
              WHEN OTHERS THEN
                   log_message (p_external_ord_no || ' Unable to find p_surgeon_name: ' || p_surgeon_name);
                   l_surgeon_rec_id := null;
              END;

          WHEN TOO_MANY_ROWS THEN
             -- WE CAN'T MATCH THE SURGEON BASED ON ONLY FIRST AND LAST NAME
             log_message (p_external_ord_no || ' (3) l_surgeon_id: ' || l_surgeon_id);
             l_surgeon_rec_id := null;
          WHEN OTHERS THEN
             log_message (p_external_ord_no || ' (4) l_surgeon_id: ' || l_surgeon_id);
             l_surgeon_rec_id := null;
          END;
          */
         log_message (p_external_ord_no || ' l_surgeon_rec_id: ' || l_surgeon_rec_id);
         l_header_rec.salesrep_id   := l_salesrep_id;
         l_header_rec.transactional_curr_code := 'USD';
         --l_header_rec.booked_flag := 'Y';
         --l_header_rec.flow_status_code := 'BOOKED';
         l_header_rec.cust_po_number := p_cust_po_number;
         l_header_rec.CONTEXT       := c_context;
         -- l_header_rec.attribute1    := p_dt_attn_contact;
        ------------------------------------------------
        -- Inv Print printing incorrect ship to --
        -- Ticket # 
        ------------------------------------------------
--         l_header_rec.attribute2    := p_dt_attn_contact;
--         l_header_rec.attribute20   := p_dt_attn_company;
         l_header_rec.attribute2    := p_dt_attn_company; -- Changed done by balaji on 02-09-2015
         l_header_rec.attribute4    := l_email_address;
         l_header_rec.attribute6    := l_duplicate_po_reason;
         l_header_rec.attribute7    := TO_CHAR (p_surgery_date, 'YYYY/MM/DD HH24:MI:SS');
                                                                                --Let the DFF format it to 'DD-MON-YYYY'
         l_header_rec.attribute8    := l_surgeon_rec_id;
         -- l_header_rec.attribute10 := certificate_of_conformance; --  (Y/N)?;
         l_header_rec.attribute12   := l_case_number;
         l_header_rec.attribute13   := p_patient_id;
         l_header_rec.attribute15   := l_construct_pricing;
         l_header_rec.created_by    := 125166;
         l_header_rec.creation_date := SYSDATE;
         l_header_rec.last_updated_by := 125166;
         l_header_rec.last_update_date := SYSDATE;
               /*

               l_header_payment_rec.operation := OE_GLOBALS.G_OPR_CREATE;
         --l_header_payment_rec.header_index := 1;
         l_header_payment_rec.receipt_method_id := 1; --6875; --6755;
         l_header_payment_rec.payment_type_code := 'CREDIT_CARD';
         l_header_payment_rec.credit_card_number := '4111111111111111';
         l_header_payment_rec.credit_card_code := 'VISA';
         l_header_payment_rec.credit_card_holder_name := p_cc_holder_name;
         l_header_payment_rec.credit_card_expiration_date :=p_cc_expiration_date;
         l_header_payment_rec.payment_level_code := 'ORDER';
         l_header_payment_rec.prepaid_amount := 100;
         l_header_payment_tbl(1):=l_header_payment_rec;

               */
         -- l_header_rec.last_update_login :=

         --If cc data is incomplete or invalid, all of these fields will be cleared.
         validate_cc_info (p_cc_code                 => p_cc_code,
                           p_cc_number               => p_cc_number,
                           p_cc_expiration_date      => p_cc_expiration_date,
                           p_cc_holder_name          => p_cc_holder_name,
                           x_payment_type_code       => l_header_rec.payment_type_code,
                           x_cc_code                 => l_header_rec.credit_card_code,
                           x_cc_number               => l_header_rec.credit_card_number,
                           x_cc_expiration_date      => l_header_rec.credit_card_expiration_date,
                           x_cc_holder_name          => l_header_rec.credit_card_holder_name
                          );
      END IF;                                                                                         --IF l_update_mode
   END create_sales_order_header;

   PROCEDURE create_sales_order_line (
      p_inventory_item_id     IN   NUMBER,
      p_quantity              IN   NUMBER,
      p_item_description      IN   VARCHAR2,
      p_line_type             IN   VARCHAR2,
      p_external_ord_number   IN   VARCHAR2,
      p_price                 IN   NUMBER,
      p_lot_number            IN   VARCHAR2
   )
   IS
   BEGIN
      NULL;
   END create_sales_order_line;

   PROCEDURE create_sales_order_request (
      p_user_id                    IN       VARCHAR2,                                                             -- new
      p_external_ord_no            IN       VARCHAR2,
      p_sales_rep_number           IN       VARCHAR2,
      p_email_address              IN       VARCHAR2,
      p_order_type                 IN       VARCHAR2,
      p_cust_po_number             IN       VARCHAR2,
      p_ship_to_acct_num           IN       NUMBER,
      p_invoice_to_acct_num        IN       NUMBER,
      p_ship_to_site_id            IN       NUMBER,
      p_invoice_to_site_id         IN       NUMBER,
      p_party_site_id              IN       NUMBER,
      p_dt_party_site_id           IN       NUMBER,                                                               -- new
      p_dt_attn_contact            IN       VARCHAR2,                                                             -- new
      p_dt_attn_company            IN       VARCHAR2,                                                             -- new
      p_dt_address_1               IN       VARCHAR2,
      p_dt_address_2               IN       VARCHAR2,
      p_dt_city                    IN       VARCHAR2,
      p_dt_state                   IN       VARCHAR2,
      p_dt_postal_code             IN       VARCHAR2,
      p_date_needed                IN       VARCHAR2,
      p_ship_method                IN       VARCHAR2,
      p_ship_priority              IN       VARCHAR2,
      p_surgery_date               IN       VARCHAR2,
      p_surgery_type               IN       VARCHAR2,
      p_surgeon_id                 IN       VARCHAR2,
      p_external_surgeon_id        IN       VARCHAR2,
      p_surgeon_name               IN       VARCHAR2,
      p_patient_id                 IN       VARCHAR2,
      p_case_number                IN       VARCHAR2,
      p_internal_notes             IN       VARCHAR2,
      p_external_notes             IN       VARCHAR2,
      p_shipping_notes             IN       VARCHAR2,
      p_ship_complete              IN       VARCHAR2,
      p_construct_pricing          IN       VARCHAR2,
      p_third_party_billing        IN       VARCHAR2,
      p_third_party_billing_note   IN       VARCHAR2,
      p_cc_code                    IN       VARCHAR2,                                                             -- new
      p_cc_holder_name             IN       VARCHAR2,                                                             -- new
      p_cc_number                  IN       VARCHAR2,                                                              --new
      p_cc_expiration_date                  VARCHAR2,                                                              --new
      p_so_lines                   IN       xxintg_t_so_line_t,
      p_return_status              IN OUT   VARCHAR2,
      p_return_code                IN OUT   VARCHAR2,
      p_return_message             IN OUT   VARCHAR2
   )
   IS
      l_return_status           VARCHAR2 (10);
      l_return_code             VARCHAR2 (30);
      l_return_message          VARCHAR2 (2000);
      h_return_status           VARCHAR2 (10);
      h_return_message          VARCHAR2 (2000);
      b_return_status           VARCHAR2 (10);
      b_return_message          VARCHAR2 (2000);
      l_msg_count               NUMBER;
      l_msg_data                VARCHAR2 (2000);
      l_surgery_date            DATE;
      -- Variables to support calling OE_ATCHMT_UTIL.ADD_ATTACHMENT
      v_category_id             NUMBER;
      l_attach_entity           VARCHAR2 (30)             := 'OE_ORDER_HEADERS';
      l_seq_num                 VARCHAR2 (30);
      v_attachment_id           NUMBER;
      v_attachment_status       VARCHAR2 (30);
      v_attachment_msg_cnt      NUMBER;
      v_attachment_msgs         VARCHAR2 (2000);
      l_inventory_item_id       NUMBER;
      l_lot_control_code        NUMBER;
      l_serial_control_code     NUMBER;
      l_header_status_message   VARCHAR2 (200);
      l_item_division           VARCHAR2 (30);
      --Values to calculate the line price
      l_item_tab                xxintg_t_product_t;
      l_return_xml              XMLTYPE;
      l_p_return_status         VARCHAR2 (100);
      l_p_return_code           VARCHAR2 (100);
      l_p_return_msg            VARCHAR2 (2000);
      l_xml_string              VARCHAR2 (2000);
      l_qp_price                NUMBER;
      l_adj_index               NUMBER;
      l_pricing_tbl             qp_preq_grp.line_tbl_type;

      -- cursor for use in creating the reservation for each order line
      CURSOR order_lines_cur
      IS
         SELECT oel.line_id line_id,
                mso.sales_order_id mso_sales_order_id,
                oel.inventory_item_id,
                oel.ordered_item,
                oel.ordered_quantity,
                oel.line_type_id
           FROM oe_order_headers_all oeh,
                mtl_sales_orders mso,
                oe_order_lines_all oel,
                mtl_system_items_b msib
          WHERE TO_CHAR (oeh.order_number) = mso.segment1
            AND oeh.order_number = l_header_rec_out.order_number
            AND oel.header_id = oeh.header_id
            AND msib.inventory_item_id = oel.inventory_item_id
            AND msib.organization_id = oel.ship_from_org_id
            AND msib.inventory_item_flag = 'Y'
            AND mso.segment2 = l_order_type
            AND mso.segment3 = c_mso_order_source;

      CURSOR existing_order_cur (p_orig_sys_doc_ref IN VARCHAR2)
      IS
         SELECT header_id
           FROM oe_order_headers                                               --not _all!! to avoid dupes in other orgs
          WHERE orig_sys_document_ref = p_orig_sys_doc_ref
                                                          --These are some ideas for additional ways to limit the possibility of an accidental dupe being found.
                                                            --AND open_flag = 'Y'
                                                            --AND creation_date > sysdate - 30
      ;
   BEGIN
      l_so_lines                 := xxintg_t_so_line_t ();
      l_so_lines.DELETE;
      l_so_lines                 := p_so_lines;
      l_header_rec               := NULL;
      l_surgery_type             := NULL;
      l_line_tbl.DELETE;                                                         --  := oe_order_pub.G_MISS_LINE_TBL();
      /****Sri Calculate Price changes Begin************/
      l_line_tbl_update.DELETE;
      l_line_adj_tbl_update.DELETE;
      /****Sri Calculate Price changes End************/
      l_line_adj_tbl.DELETE;
      l_line_scredit_tbl.DELETE;
      l_action_request_tbl.DELETE;
      l_email_address            := p_email_address;
      l_surgery_type             := p_surgery_type;
      l_case_number              := p_external_ord_no;           -- p_case_number;  There is no difference in surgisoft
      l_ship_priority            := p_ship_priority;
      l_construct_pricing        := p_construct_pricing;
      l_party_site_id            := p_party_site_id;
      l_user_name                := p_user_id;
      l_surgeon_id               := p_surgeon_id;
      l_site_use_id              := NULL;
      l_ship_from_org_id         := NULL;
      l_subinventory             := NULL;
      l_order_locator_id         := NULL;
      l_sold_to_org_id           := NULL;
      l_site_use_id              := NULL;
      l_dt_party_site_id         := NULL;
      l_surgery_code             := NULL;
      l_invoice_to_org_id        := NULL;
      l_ship_to_org_id           := NULL;
      l_update_mode              := FALSE;
      l_existing_header_id       := NULL;
      g_external_ord_no          := p_external_ord_no;
      initialize_values (p_first_item           => l_so_lines (1).item,
                         p_organization_id      => l_organization_id,
                         p_return_status        => l_return_status,
                         p_return_code          => l_return_code,
                         p_return_message       => l_return_message
                        );

      --First test to see if this is an existing order.
      --Check is done here because the org_id is set in initialize_variables
      OPEN existing_order_cur (p_external_ord_no);
--      OPEN existing_order_cur (p_external_ord_no||sysdate);

      FETCH existing_order_cur
       INTO l_existing_header_id;

      IF existing_order_cur%FOUND
      THEN
         --Set the flag that will guide the rest of the API.
         l_update_mode              := TRUE;
         log_message (   p_external_ord_no
                      || ' Updating header: '
                      || l_existing_header_id
                      || ' PO Number to: '
                      || p_cust_po_number
                     );
      ELSE
         log_message (p_external_ord_no || ' Creating new order: ' || p_external_ord_no);
      END IF;

      CLOSE existing_order_cur;

      IF p_surgery_date IS NOT NULL
      THEN
         log_message (p_external_ord_no || ' p_surgery_date: ' || p_surgery_date);
         l_surgery_date             := TO_DATE (p_surgery_date, 'MM/DD/YYYY');
      END IF;

      -- create deliver_to_address
      IF NOT l_update_mode                                                                         --Skip in UPDATE mode
      THEN
         create_deliver_to_site (p_external_ord_no        => p_external_ord_no,
                                 p_srep_number            => p_sales_rep_number,
                                 p_party_site_number      => TO_CHAR (p_dt_party_site_id),
                                 p_address_1              => p_dt_address_1,
                                 p_address_2              => p_dt_address_2,
                                 p_city                   => p_dt_city,
                                 p_state                  => p_dt_state,
                                 p_postal_code            => p_dt_postal_code,
                                 x_site_use_id            => l_site_use_id,
                                 x_return_status          => p_return_status,
                                 x_return_code            => p_return_code,
                                 x_return_message         => p_return_message
                                );

         IF p_return_status <> 'S'
         THEN
            RAISE e_other_error;
         END IF;
      END IF;

      log_message (p_external_ord_no || ' Before Header Number Lines in L_SO_LINES: ' || p_so_lines.COUNT);
      l_header_status_message    := NULL;
      l_header_status_code       := 'N';
      create_sales_order_header (p_external_ord_no            => p_external_ord_no,
                                 p_sales_rep_number           => p_sales_rep_number,
                                 p_surgery_date               => l_surgery_date,
                                 p_order_type                 => p_order_type,
                                 p_cust_po_number             => p_cust_po_number,
                                 p_ship_to_acct_num           => p_ship_to_acct_num,
                                 p_invoice_to_acct_num        => p_invoice_to_acct_num,
                                 p_ship_to_site_id            => p_ship_to_site_id,
                                 p_invoice_to_site_id         => p_invoice_to_site_id,
                                 p_ship_method_flag           => p_ship_method,
                                 p_surgeon_name               => p_surgeon_name,
                                 p_patient_id                 => p_patient_id,
                                 p_header_status_code         => l_header_status_code,
                                 p_header_status_message      => l_header_status_message,
                                 p_party_site_id              => p_party_site_id,
                                 p_dt_party_site_id           => p_dt_party_site_id,
                                 p_dt_attn_contact            => p_dt_attn_contact,
                                 p_dt_attn_company            => p_dt_attn_company,
                                 p_cc_code                    => p_cc_code,
                                 p_cc_holder_name             => p_cc_holder_name,
                                 p_cc_number                  => p_cc_number,
                                 p_cc_expiration_date         => p_cc_expiration_date
                                );
      log_message (p_external_ord_no || ' After Header Procedure: Customer Info  L_SOLD_TO_ORG_ID - '
                   || l_sold_to_org_id
                  );

      IF (l_header_status_code = 'E')
      THEN
         log_message (p_external_ord_no || ' Exception:  ' || l_header_status_message);
         p_return_message           := l_header_status_message;
         RAISE e_other_error;
      END IF;

      IF (l_so_lines.COUNT = 0)
      THEN
         log_message (p_external_ord_no || ' Error: Submitted order has 0 lines.');
         p_return_status            := 'E';
         p_return_message           := 'Submitted order has 0 lines.';
         RAISE e_other_error;
      END IF;

      IF NOT l_update_mode
      THEN
         FOR i IN l_so_lines.FIRST .. l_so_lines.LAST
         LOOP
            --Check the lot expiration date as this can influence the line type decision below.
            IF l_so_lines (i).lot IS NOT NULL
            THEN                                                                              --A lot has been supplied
               BEGIN
                  SELECT NVL (lot.expiration_date, SYSDATE + 1)
                    INTO l_lot_expiration_date
                    FROM mtl_system_items_b msi,
                         mtl_lot_numbers_all_v lot
                   WHERE msi.segment1 = l_so_lines (i).item
                     AND msi.organization_id = l_organization_id
                     AND lot.lot_number = l_so_lines (i).lot
                     AND lot.inventory_item_id = msi.inventory_item_id
                     AND lot.organization_id = msi.organization_id
                     AND ROWNUM < 2;

                  log_message (   p_external_ord_no
                               || ' Lot expiration date: '
                               || TO_CHAR (l_lot_expiration_date, 'DD-MON-YYYY')
                              );
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     --Lot number not forund.  Set lot expiration so that the line goes on hold
                     l_lot_expiration_date      := SYSDATE - 1;
                     log_message (p_external_ord_no || ' lot number: ' || l_so_lines (i).lot || ' was not found.');
               END;
            ELSE
               l_lot_expiration_date      := SYSDATE + 1;           --Simulate a valid lot to pass the expiration test.
            END IF;

            -- use flags to find out the appropriate order and line types
            -- for a Chargesheet Order
            IF l_order_type = c_chargesheet_order_type
            THEN
               IF l_lot_expiration_date < TRUNC (SYSDATE)
               THEN
                  l_line_type                := c_bill_w_po_hold_line_type;
                  log_message (p_external_ord_no || ' Expired Lot on Chargesheet. Changing Line Type.');
               ELSIF l_so_lines (i).billable = 'N'
               THEN
                  l_line_type                := 'Clinical Eval Line';
               ELSIF l_so_lines (i).replenish = 'Y'
               THEN
                  l_line_type                := 'Replenishment';
               ELSIF NVL (l_so_lines (i).replenish, 'N') = 'N'
               THEN
                  l_line_type                := 'Non-Replenishment';
               END IF;
            END IF;

            log_message (p_external_ord_no || ' l_line_type: ' || l_line_type);

            BEGIN
               -- need the transaction_type_id now also
               SELECT ott.transaction_type_id
                 INTO l_line_type_id
                 FROM oe_transaction_types_all ott,
                      oe_transaction_types_tl otl
                WHERE NVL (ott.end_date_active, SYSDATE + 1) > SYSDATE
                  AND ott.transaction_type_code = 'LINE'
                  AND otl.transaction_type_id = ott.transaction_type_id
                  AND otl.LANGUAGE = 'US'
                  AND otl.NAME = l_line_type;
            EXCEPTION
               WHEN OTHERS
               THEN
                  -- l_log_message := 'error getting transaction type for: '|| l_line_type;
                  -- INSERT INTO apps.BXS_LOG VALUES ( l_return_message, sysdate);
                  log_message (p_external_ord_no || 'error getting transaction type for: ' || l_line_type);
                  NULL;
            END;

            log_message (p_external_ord_no || ' l_line_type_id: ' || l_line_type_id);

            IF l_line_type = c_bill_w_po_hold_line_type
            THEN
               --Store the line_type_id to a global for future use.
               l_bill_w_po_hold_line_type_id := l_line_type_id;
            END IF;

            BEGIN
               SELECT inventory_item_id
                 INTO l_inventory_item_id
                 FROM mtl_system_items_b msib
                WHERE organization_id = l_organization_id AND segment1 = l_so_lines (i).item;

               log_message (p_external_ord_no || ' Inventory Item ID: ' || l_inventory_item_id);
            EXCEPTION
               WHEN OTHERS
               THEN
                  log_message (p_external_ord_no || 'Error getting inventory id : ' || l_so_lines (i).item);
                  p_return_message           := 'Error getting inventory id for : ' || l_so_lines (i).item;
                  p_return_status            := 'E';
                  p_return_code              := SQLCODE;
                  p_return_message           := 'INTG Validation Error: ' || SQLERRM || p_return_message;
                  RAISE e_other_error;
            END;

            log_message (p_external_ord_no || ' p_sales_rep_number: ' || p_sales_rep_number);

            -- salesrep may differ on every line
            IF p_sales_rep_number < 0
            THEN
               -- No Sales Credits for Kitting Replenishments
               l_salesrep_id              := -3;
            ELSE
               -- need the salesrep number to put on the line and for sales credits
               -- need the ship_from_ord_id for the warehouse and l_subinventory for
               BEGIN
                  SELECT jrs.salesrep_id,
                         secondary_inventory_name,
                         msi.organization_id
                    INTO l_salesrep_id,
                         l_subinventory,
                         l_ship_from_org_id
                    FROM jtf_rs_salesreps jrs,
                         mtl_secondary_inventories msi,
                         mtl_item_locations mil
                   WHERE jrs.salesrep_number = p_sales_rep_number
                     AND msi.secondary_inventory_name = mil.subinventory_code
                     AND (msi.attribute2 = jrs.salesrep_number OR mil.attribute3 = jrs.salesrep_number)
                     AND ROWNUM < 2;
                               --Added to prevent too_many_rows if a multi-locator subinv is still linked on the subinv.

                  --AND msi.attribute2 = jrs.salesrep_number;
                  log_message (p_external_ord_no || ' jrs.salesrep_id: ' || l_salesrep_id);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     -- we will still enter the order, but it will go on hold
                     log_message (p_external_ord_no || 'Unable to find salesrep information for: ' || p_sales_rep_number
                                 );
                     NULL;
               END;
            END IF;

            -- BXS - put the kit serial number at the header level for kitting replenishments
            -- 02/26 - Brian --
            IF l_line_type = 'ILS Kitting Request'
            THEN
               log_message (   p_external_ord_no
                            || 'Adding Serial Number, l_so_lines(i).kit_serial_number: '
                            || l_so_lines (i).kit_serial_number
                           );
               l_header_rec.cust_po_number := l_so_lines (i).kit_serial_number;
            END IF;

--------------------------------------
-- Changed logic for l_ship_from_org;
-- 02/24/2014 --
---------------------------------------
            IF l_order_type = c_request_order_type
            THEN
               log_message (p_external_ord_no || ' Getting Default Shipping Org for ' || l_inventory_item_id);

               BEGIN
                  SELECT default_shipping_org
                    INTO l_ship_from_org_id
                    FROM mtl_system_items_b
                   WHERE inventory_item_id = l_inventory_item_id                       --l_line_tbl(i).inventory_item_id
                     AND organization_id = (SELECT DISTINCT master_organization_id
                                                       FROM mtl_parameters
                                                      WHERE organization_code = '150');

                  log_message (   p_external_ord_no
                               || ' Derive Def Ship Org for Inventory Item -'
                               || l_inventory_item_id
                               || ' -- '
                               || 'default_shipping_org - '
                               || l_ship_from_org_id
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     log_message (   p_external_ord_no
                                  || ' Error while Deriving Def Ship Org for Inventory Item -'
                                  || l_line_tbl (i).inventory_item_id
                                 );
                     l_ship_from_org_id         := NULL;
               END;
            END IF;

----------------------------------------
            log_message (p_external_ord_no || ' Getting Default Shipping Org ' || l_ship_from_org_id);
            l_line_tbl (i)             := oe_order_pub.g_miss_line_rec;
            l_line_tbl (i).operation   := oe_globals.g_opr_create;
            l_line_tbl (i).line_type_id := l_line_type_id;
            l_line_tbl (i).inventory_item_id := l_inventory_item_id;
            l_line_tbl (i).ordered_quantity := l_so_lines (i).quantity;
            log_message (   p_external_ord_no
                         || ' Line '
                         || i
                         || ' construct pricing '
                         || l_so_lines (i).construct_pricing
                         || ' header = '
                         || l_construct_pricing
                        );

            IF NVL (l_so_lines (i).construct_pricing, NVL (l_construct_pricing, 'Y')) = 'Y'
            THEN
               l_line_tbl (i).calculate_price_flag := 'Y';
               l_line_tbl (i).unit_selling_price := l_so_lines (i).price;
               l_line_tbl (i).unit_list_price := l_so_lines (i).price;
            ELSE
               --Line is marked to freeze at the given price.
               --Check Oracle price and create necessary adjustments
/***Sri Changes for Calculate Price start here****/               
--               l_line_tbl (i).calculate_price_flag := 'N';
               l_line_tbl (i).calculate_price_flag := 'Y';               
/***Sri Changes for Calculate Price End here****/               
               --Load the item into this table structure
               l_item_tab                 := xxintg_t_product_t ();
               l_item_tab.EXTEND;
               l_item_tab (l_item_tab.COUNT) :=
                          xxintg_t_product (l_so_lines (i).item, l_so_lines (i).quantity, l_so_lines (i).item_uom, 'Y');
               l_pricing_tbl.DELETE;
               xxom_prcng_avail_pkg.get_item_pricing (p_country                => 'US',
                                                      --ACTUALLY the PARTY_SITE_NUMBER!!
                                                      p_party_site_number      => TO_CHAR (l_party_site_id),
                                                      p_construct_pricing      => 'Y',
                                                      p_product_info           => l_item_tab,
                                                      x_pricing_tbl            => l_pricing_tbl,
                                                      x_return_status          => l_p_return_status,
                                                      x_return_code            => l_p_return_code,
                                                      x_msg_data               => l_p_return_msg
                                                     );

               IF l_p_return_status = fnd_api.g_ret_sts_success
               THEN
                  /*--Extract Pricing Info as VARCHAR2 from the returned XML.
                  l_xml_string := l_return_xml.EXTRACT('/*').getStringVal();
                  --Hack the Price element from the remaining XML.
                  l_qp_price := SUBSTR (SUBSTR (l_xml_string,
                                                1,
                                                INSTR (l_xml_string, '</Price>') - 1),
                                        INSTR (l_xml_string, '<Price>') + 7);
                  log_message ('QP Price for Line ' || i || ': ' || l_qp_price);*/
                  l_qp_price                 := l_pricing_tbl (l_pricing_tbl.FIRST).adjusted_unit_price;
/***Sri Changes for Calculate Price start here****/                                    
--                  l_line_tbl (i).unit_selling_price := l_so_lines (i).price;
--                  l_line_tbl (i).unit_list_price := l_qp_price;                                 --l_so_lines (i).price;
                  l_line_tbl (i).unit_selling_price := l_qp_price;
                  l_line_tbl (i).unit_list_price := l_pricing_tbl (l_pricing_tbl.FIRST).unit_price;
/***Sri Changes for Calculate Price end here****/
/***Sri Changes for Calculate Price start here****/                                    
--                  IF l_qp_price = l_so_lines (i).price
--                  THEN
                     --Prices match, do nothing.
--                     log_message (p_external_ord_no || ' Price matches the price sent into API.');
--                  ELSE
                     --Create adjustment to account for the difference
--                     log_message (   p_external_ord_no
--                                  || ' Creating adjustment for '
--                                  || TO_CHAR (TO_NUMBER (l_so_lines (i).price) - TO_NUMBER (l_qp_price))
--                                 );

                     --Get the list_header_id and list_line_id if they are still NULL
--                     BEGIN
--                        IF l_adj_list_header_id IS NULL
--                        THEN
--                           SELECT list_header_id
--                             INTO l_adj_list_header_id
--                             FROM qp_list_headers_tl
--                            WHERE NAME = 'ALLOW LP OVERRIDE' AND LANGUAGE = 'US';
--                        END IF;

--                        IF l_adj_list_line_id IS NULL
--                        THEN
--                           SELECT list_line_id
--                             INTO l_adj_list_line_id
--                             FROM qp_list_lines
--                            WHERE list_header_id = l_adj_list_header_id
--                              AND modifier_level_code = 'LINE'
--                              AND arithmetic_operator = 'NEWPRICE'
--                              AND ROWNUM <= 1;  --Ensure that multiple matches don't fail this SQL.  Any match is valid.
--                        END IF;
--                     EXCEPTION
--                        WHEN OTHERS
--                        THEN
--                           log_message (   p_external_ord_no
--                                        || ' Cannot determine the price_adjustment list_header_id and list_line_id'
--                                       );
--                     END;

--                     IF l_adj_list_header_id IS NOT NULL AND l_adj_list_line_id IS NOT NULL
--                     THEN
--                        l_adj_index                := l_line_adj_tbl.COUNT + 1;
--                        log_message (p_external_ord_no || ' Adjustment will be ' || l_adj_index);
--                        l_line_adj_tbl (l_adj_index) := oe_order_pub.g_miss_line_adj_rec;
--                        l_line_adj_tbl (l_adj_index).operation := oe_globals.g_opr_create;
--                        l_line_adj_tbl (l_adj_index).line_index := i;    --Links to the "current" line in the line loop
--                        l_line_adj_tbl (l_adj_index).operand := l_so_lines (i).price;
--                        l_line_adj_tbl (l_adj_index).adjusted_amount := l_so_lines (i).price - l_qp_price;
--                        l_line_adj_tbl (l_adj_index).change_reason_code := 'MANUAL';
--                        l_line_adj_tbl (l_adj_index).change_reason_text := 'Adjustment applied thru API';
--                        l_line_adj_tbl (l_adj_index).automatic_flag := 'Y';
--                        l_line_adj_tbl (l_adj_index).arithmetic_operator := 'NEWPRICE';
--                        l_line_adj_tbl (l_adj_index).modifier_level_code := 'LINE';
--                        l_line_adj_tbl (l_adj_index).list_header_id := 6008;
                                                                       --l_pricing_tbl (l_pricing_tbl.FIRST).header_id;
--                        l_line_adj_tbl (l_adj_index).list_line_id := 6011;
                                                                         --l_pricing_tbl (l_pricing_tbl.FIRST).line_id;

--                        IF TO_NUMBER (l_so_lines (i).price) - TO_NUMBER (l_qp_price) > 0
--                        THEN
--                           l_line_adj_tbl (l_adj_index).list_line_type_code := 'SUR';
--                        ELSE
--                           l_line_adj_tbl (l_adj_index).list_line_type_code := 'DIS';
--                        END IF;

--                        l_line_adj_tbl (l_adj_index).update_allowed := 'Y';
--                        l_line_adj_tbl (l_adj_index).applied_flag := 'Y';
--                     ELSE
--                        log_message (p_external_ord_no || ' Skipping Adjustment creation.');
--                     END IF;
--                  END IF;
/***Sri Changes for Calculate Price End here****/                                    
               ELSE
                  --Pricing call failed.
                  NULL;
                  log_message (p_external_ord_no || ' Pricing call failed. ' || l_p_return_status || '/'
                               || l_p_return_msg
                              );
                  l_line_tbl (i).unit_selling_price := l_so_lines (i).price;
                  l_line_tbl (i).unit_list_price := l_so_lines (i).price;
               END IF;
            END IF;
                     /*IF l_order_type <> c_request_order_type THEN
                        l_line_tbl(i).unit_selling_price := l_so_lines(i).price;
                     END IF;
                     */
                     --l_line_tbl (i).unit_selling_price := l_so_lines (i).price;
                     --l_line_tbl (i).unit_list_price := l_so_lines (i).price;
            /*         -- reserve quantity for product request; otherwise call reservations at the end
                     -- This has been taken below to avoid extra IF statements --
                     IF l_order_type = c_request_order_type
                     THEN
                        l_line_tbl (i).reserved_quantity := l_line_tbl (i).ordered_quantity;
                     END IF;
            */
            /****Begin Changes Version 2.8 by Sri*********/
--            l_line_tbl (i).salesrep_id := l_salesrep_id;
-- Move this into the division logic  
            /****End Changes Version 2.8 by Sri*********/
--------------------------------------
-- Derive Locator ID for Product Request Only --
-- 02/26 Jagdish --
---------------------------------------------------
            IF l_order_type = c_request_order_type
            THEN
               --             No need for reservation for product request 03/19/2014 --
               --            l_line_tbl (i).reserved_quantity := l_line_tbl (i).ordered_quantity;
                                                                                               -- Reserve Quantity for product request
               BEGIN
                  SELECT mil.inventory_location_id
                    INTO l_order_locator_id
                    FROM mtl_system_items_b msib,
                         mtl_item_locations mil,
                         xxom_sales_marketing_set_v xsms
                   WHERE msib.organization_id = l_organization_id
                     AND msib.inventory_item_status_code <> 'Inactive'
                     AND msib.inventory_item_id = l_line_tbl (i).inventory_item_id
                     AND mil.organization_id = msib.organization_id
                     AND mil.segment1 = l_subinventory
                     AND mil.segment2 = SUBSTR (snm_division, 1, 3)
                     AND mil.segment3 = '001'
                     AND xsms.organization_id = msib.organization_id
                     AND xsms.inventory_item_id = msib.inventory_item_id;

                  log_message (   p_external_ord_no
                               || ' Found Locator ID for Item '
                               || l_so_lines (i).item
                               || ' Sub Inv - '
                               || l_subinventory
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
                     log_message (   p_external_ord_no
                                  || ' Unable to derive Locatior ID for Item '
                                  || l_so_lines (i).item
                                  || ' Sub Inv - '
                                  || l_subinventory
                                 );
               END;

---------------------------------------------------------
-- Derive LPN ID - 03/12/2014 Jagdish
---------------------------------------------------------
               IF (l_line_type = 'ILS Kitting Request')
               THEN
                  l_order_lpn_id             := NULL;

                  IF (l_so_lines (i).kit_serial_number IS NOT NULL)
                  THEN
                     BEGIN
                        SELECT lpn_id
                          INTO l_order_lpn_id
                          FROM wms_license_plate_numbers
                         WHERE license_plate_number = l_so_lines (i).kit_serial_number
                           AND organization_id = l_organization_id;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           NULL;
                           log_message (   p_external_ord_no
                                        || ' Kitting Req - Unable to find LPN ID '
                                        || l_so_lines (i).kit_serial_number
                                       );
                     END;
                  END IF;                                                                     -- kit_serial_num not null
               END IF;                                                                     -- ILS Kitting Request end if

               log_message (p_external_ord_no || ' LPN ID Found ' || l_so_lines (i).kit_serial_number);
----------------------------------------------------------
               l_line_tbl (i).global_attribute14 := l_order_locator_id;
                                                                       -- Store Locator_ID in attribute14 on Order Line.
               l_line_tbl (i).global_attribute15 := l_order_lpn_id;    -- Store Locator_ID in attribute14 on Order Line.
               l_line_tbl (i).subinventory := NULL;                    -- We dont need subinventory for Product request.
            ELSE
               l_line_tbl (i).subinventory := l_subinventory;
            END IF;

            -- l_line_tbl(i).shipment_priority_code := p_ship_priority; not used at this time
            -- l_line_tbl(i).shipping_method_code := -- inherit from the header only
            l_line_tbl (i).CONTEXT     := c_context;
            log_message (p_external_ord_no || 'c_context: ' || c_context);
            l_line_tbl (i).attribute1  := l_so_lines (i).kit_serial_number;
            l_line_tbl (i).attribute2  := l_so_lines (i).lot;
            log_message (p_external_ord_no || 'l_so_lines(i).kit_serial_number: ' || l_so_lines (i).kit_serial_number);
            l_line_tbl (i).attribute8  := l_so_lines (i).certification;

            -- Surgeon name plus certification Number need to look this up when HCP is designed

            -- Ship Set logic - ignores the header parameter, since that is just an aid to the UI
            IF l_so_lines (i).ship_complete = 'Y'
            THEN
               l_line_tbl (i).ship_set    := 1;
            --This can be any number.  All lines that have the same value will ship together.
            --It is okay to use the same number across multiple orders. It does not have to be globally unique.
            ELSE
               l_line_tbl (i).ship_set    := NULL;
            END IF;

            -- Sales Credits all reps are 100% per requirments
            IF l_order_type = c_chargesheet_order_type
            THEN
               --Check the item's division and skip sales credits for Recon items.
               BEGIN
                  SELECT snm_division
                    INTO l_item_division
                    FROM xxom_sales_marketing_set_v xsms
                   WHERE xsms.organization_id = l_organization_id
                     AND xsms.inventory_item_id = l_line_tbl (i).inventory_item_id;

                  log_message (   p_external_ord_no
                               || ' Found '
                               || l_item_division
                               || ' division for Item '
                               || l_so_lines (i).item
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_item_division            := NULL;
                     log_message (p_external_ord_no || ' Unable to derive division for Item ' || l_so_lines (i).item);
               END;

               IF NVL (l_item_division, 'x') <> 'RECON'
               THEN
                  --Skip this for Recon items.
                  log_message (p_external_ord_no || ' sales_credit salesrep_id: ' || l_line_tbl (i).salesrep_id);
                  l_line_scredit_tbl (i)     := oe_order_pub.g_miss_line_scredit_rec;
                  l_line_scredit_tbl (i).operation := oe_globals.g_opr_create;
                  l_line_scredit_tbl (i).creation_date := SYSDATE;
                  l_line_scredit_tbl (i).last_update_date := SYSDATE;
                  l_line_scredit_tbl (i).salesrep_id := l_salesrep_id;
                  l_line_scredit_tbl (i).PERCENT := 100;
                  l_line_scredit_tbl (i).line_index := i;
                  l_line_scredit_tbl (i).sales_credit_type_id := 1;
            /****Begin Changes Version 2.8 by Sri*********/
                  -- set the salesrep_id at the line level
                  l_line_tbl (i).salesrep_id := l_salesrep_id;
               ELSE
                -- No Sales Rep at the line level for recon
                  l_line_scredit_tbl (i)     := oe_order_pub.g_miss_line_scredit_rec;
                  l_header_rec.salesrep_id   := 100000040;
                  l_line_tbl (i).salesrep_id := 100000040; --Assumption is surgisoft will be used only for US OU
            /****End Changes Version 2.8 by Sri*********/
               END IF;
            END IF;

            l_line_tbl (i).ship_from_org_id := l_ship_from_org_id;
         END LOOP;
      END IF;                                           --l_update_mode - In UPDATE mode, the lines table will be blank.

      l_action_request_tbl (1)   := oe_order_pub.g_miss_request_rec;

      --To update the header, the main action_request table remains empty.
      IF NOT l_update_mode
      THEN
         l_action_request_tbl (1).entity_code := oe_globals.g_entity_header;
         --Changed to create orders in ENTERED
         --l_action_request_tbl (1).request_type := oe_globals.g_book_order;
         l_action_request_tbl (1).request_type := oe_globals.g_opr_create;
      END IF;

----------------------------------------------------
-- 02/24 - JAG --
----------------------------------------------------
      DBMS_OUTPUT.put_line ('Processing Order...');
      log_message (p_external_ord_no || 'Processing Order...');
/*** Sri Begin changes for calculate price *****/      
--      log_message (p_external_ord_no || ' with ' || l_line_adj_tbl.COUNT || ' price adjustments.');
/*** Sri End changes for calculate price *****/      
      oe_order_pub.process_order (p_api_version_number          => l_api_version_number,
                                  p_header_rec                  => l_header_rec,
                                  p_line_tbl                    => l_line_tbl,
                                  p_line_adj_tbl                => l_line_adj_tbl,
                                  p_action_request_tbl          => l_action_request_tbl,
                                  p_line_scredit_tbl            => l_line_scredit_tbl,
                                  -- p_line_scredit_val_tbl     => l_line_scredit_val_tbl,
                                  x_header_rec                  => l_header_rec_out,
                                  x_header_val_rec              => l_header_val_rec_out,
                                  x_header_adj_tbl              => l_header_adj_tbl_out,
                                  x_header_adj_val_tbl          => l_header_adj_val_tbl_out,
                                  x_header_price_att_tbl        => l_header_price_att_tbl_out,
                                  x_header_adj_att_tbl          => l_header_adj_att_tbl_out,
                                  x_header_adj_assoc_tbl        => l_header_adj_assoc_tbl_out,
                                  x_header_scredit_tbl          => l_header_scredit_tbl_out,
                                  x_header_scredit_val_tbl      => l_header_scredit_val_tbl_out,
                                  x_line_tbl                    => l_line_tbl_out,
                                  x_line_val_tbl                => l_line_val_tbl_out,
                                  x_line_adj_tbl                => l_line_adj_tbl_out,
                                  x_line_adj_val_tbl            => l_line_adj_val_tbl_out,
                                  x_line_price_att_tbl          => l_line_price_att_tbl_out,
                                  x_line_adj_att_tbl            => l_line_adj_att_tbl_out,
                                  x_line_adj_assoc_tbl          => l_line_adj_assoc_tbl_out,
                                  x_line_scredit_tbl            => l_line_scredit_tbl_out,
                                  x_line_scredit_val_tbl        => l_line_scredit_val_tbl_out,
                                  x_lot_serial_tbl              => l_lot_serial_tbl_out,
                                  x_lot_serial_val_tbl          => l_lot_serial_val_tbl_out,
                                  x_action_request_tbl          => l_action_request_tbl_out,
                                  x_return_status               => l_ord_return_status,
                                  x_msg_count                   => l_ord_msg_count,
                                  x_msg_data                    => l_ord_msg_data
                                 );
      log_message (p_external_ord_no || 'File name ' || oe_debug_pub.g_dir || '/' || oe_debug_pub.g_file);
      log_message (   p_external_ord_no
                   || 'Sales Order Created is:===============>'
                   || TO_CHAR (l_header_rec_out.order_number)
                  );

      IF                                                                                     --  (l_debug_level >= 0) OR
         (l_ord_return_status <> fnd_api.g_ret_sts_success
         )
      THEN
         -- l_ord_msg_count > 0 THEN
         FOR i IN 1 .. l_ord_msg_count
         LOOP
            l_data                     := NULL;
            l_msg_index                := NULL;
            oe_msg_pub.get (p_msg_index          => i,
                            p_encoded            => fnd_api.g_false,
                            p_data               => l_ord_msg_data,            --  changed to l_ord_msg_data on june11th
                            p_msg_index_out      => l_msg_index
                           );
            log_message (p_external_ord_no || 'message is: ' || l_ord_msg_data);
            DBMS_OUTPUT.put_line ('message index is: ' || l_msg_index);
            log_message (p_external_ord_no || 'message index is: ' || l_msg_index);
         END LOOP;

         p_return_message           := p_return_message || l_ord_msg_data;
         p_return_status            := l_ord_return_status;
         RAISE e_order_error;
      -- After order is created, add attachments for Internal and External notes.
      ELSIF NOT l_update_mode
      THEN                                                                               --Skip all these in UPDATE mode
   /********************Sri Calculate Price Begin Update************************/ 
         log_message (p_external_ord_no || 'Inside Update price...');
         FOR i IN l_so_lines.FIRST .. l_so_lines.LAST
         LOOP
            log_message (p_external_ord_no || 'Inside price Loop...'||l_so_lines(i).price||'-'||l_line_tbl_out(i).unit_selling_price);
            IF l_line_tbl_out(i).unit_selling_price <> l_so_lines(i).price
            AND l_line_tbl_out(i).unit_list_price <> l_so_lines(i).price
            AND l_so_lines (i).billable = 'Y' --Non-Eval
            THEN
               l_line_tbl_index := l_line_tbl_update.count + 1; 
               log_message (p_external_ord_no || 'Inside IF...'||l_line_tbl_index||'-'||l_line_tbl_out(i).line_id||'-i-'||i);
               l_line_tbl_update(l_line_tbl_index) := OE_ORDER_PUB.G_MISS_LINE_REC;
               l_line_tbl_update(l_line_tbl_index).line_id := l_line_tbl_out(i).line_id;
               l_line_tbl_update(l_line_tbl_index).unit_selling_price := l_so_lines(i).price;
               l_line_tbl_update(l_line_tbl_index).operation := OE_GLOBALS.G_OPR_UPDATE;
              
               /*****************Adjustments********************/
               l_line_adj_tbl_update (l_line_tbl_index) := oe_order_pub.g_miss_line_adj_rec;
               l_line_adj_tbl_update (l_line_tbl_index).operation := oe_globals.g_opr_create;
               l_line_adj_tbl_update (l_line_tbl_index).line_index := l_line_tbl_index;    --Links to the "current" line in the line loop
               l_line_adj_tbl_update (l_line_tbl_index).operand := l_line_tbl_out(i).unit_selling_price - l_so_lines (i).price;
               l_line_adj_tbl_update (l_line_tbl_index).change_reason_code := 'MANUAL';
               l_line_adj_tbl_update (l_line_tbl_index).change_reason_text := 'Adjustment applied thru API';
               l_line_adj_tbl_update (l_line_tbl_index).automatic_flag := 'N';
               l_line_adj_tbl_update (l_line_tbl_index).arithmetic_operator := 'AMT';
               l_line_adj_tbl_update (l_line_tbl_index).modifier_level_code := 'LINE';
               l_line_adj_tbl_update (l_line_tbl_index).list_line_type_code := 'DIS';
               l_line_adj_tbl_update (l_line_tbl_index).list_header_id := 15012;--394454;--6008;
               l_line_adj_tbl_update (l_line_tbl_index).list_line_id := 8042;--2277366;--6011;
               l_line_adj_tbl_update (l_line_tbl_index).update_allowed := 'Y';
               l_line_adj_tbl_update (l_line_tbl_index).applied_flag := 'Y';
               l_line_adj_tbl_update (l_line_tbl_index).updated_flag       := 'Y';
               /*****************Adjustments********************/
            END IF;
         END LOOP;
         IF l_line_tbl_index > 0 THEN
            log_message (p_external_ord_no || 'Processing Update Order...Calling');
            oe_order_pub.process_order (p_api_version_number          => l_api_version_number,
                                  p_header_rec                  => l_header_rec_update,
                                  p_line_tbl                    => l_line_tbl_update,
                                  p_line_adj_tbl                => l_line_adj_tbl_update,
-- OUT PARAMETERS                                   
                                  x_header_rec                  => l_header_rec_out_update,
                                  x_header_val_rec              => l_header_val_rec_out_update,
                                  x_header_adj_tbl              => l_header_adj_tbl_out_update,
                                  x_header_adj_val_tbl          => l_header_adj_val_tbl_out_upd,
                                  x_header_price_att_tbl        => l_header_price_att_tbl_out_upd,
                                  x_header_adj_att_tbl          => l_header_adj_att_tbl_out_upd,
                                  x_header_adj_assoc_tbl        => l_header_adj_assoc_tbl_out_upd,
                                  x_header_scredit_tbl          => l_header_scredit_tbl_out_upd,
                                  x_header_scredit_val_tbl      => l_header_scredit_val_tbl_out_u,
                                  x_line_tbl                    => l_line_tbl_out_update,
                                  x_line_val_tbl                => l_line_val_tbl_out_update,
                                  x_line_adj_tbl                => l_line_adj_tbl_out_update,
                                  x_line_adj_val_tbl            => l_line_adj_val_tbl_out_update,
                                  x_line_price_att_tbl          => l_line_price_att_tbl_out_upd,
                                  x_line_adj_att_tbl            => l_line_adj_att_tbl_out_update,
                                  x_line_adj_assoc_tbl          => l_line_adj_assoc_tbl_out_upd,
                                  x_line_scredit_tbl            => l_line_scredit_tbl_out_update,
                                  x_line_scredit_val_tbl        => l_line_scredit_val_tbl_out_u,
                                  x_lot_serial_tbl              => l_lot_serial_tbl_out_update,
                                  x_lot_serial_val_tbl          => l_lot_serial_val_tbl_out_upd,
                                  x_action_request_tbl          => l_action_request_tbl_out_upd,
                                  x_return_status               => l_ord_return_status_update,
                                  x_msg_count                   => l_ord_msg_count_update,
                                  x_msg_data                    => l_ord_msg_data_update
                                 );
   
            IF (l_ord_return_status_update <> fnd_api.g_ret_sts_success)
            THEN
               FOR i IN 1 .. l_ord_msg_count_update
               LOOP
                  l_data_update              := NULL;
                  l_msg_index_update         := NULL;
                  oe_msg_pub.get (p_msg_index          => i,
                               p_encoded            => fnd_api.g_false,
                               p_data               => l_ord_msg_data_update,
                               p_msg_index_out      => l_msg_index_update
                              );
                  log_message (p_external_ord_no || 'Update message is: ' || l_ord_msg_data_update);
                  DBMS_OUTPUT.put_line ('Update message index is: ' || l_msg_index_update);
                  log_message (p_external_ord_no || 'Update message index is: ' || l_msg_index_update);
               END LOOP;
               p_return_message           := p_return_message || l_ord_msg_data_update;
               p_return_status            := l_ord_return_status_update;
               RAISE e_order_error;
            END IF;
         END IF;
      -- After order is updated, add attachments for Internal and External notes.
         
   /********************Sri Calculate Price End Update************************/   
      
         IF p_internal_notes IS NOT NULL
         THEN
            BEGIN
               SELECT category_id
                 INTO v_category_id
                 FROM fnd_document_categories_vl
                WHERE user_name = 'CSR Internal';

               /*oe_atchmt_util.add_attachment (p_api_version        => 1.0,
                                              p_entity_code        => oe_globals.g_entity_header,
                                              p_entity_id          => l_header_rec_out.header_id,
                                              p_document_desc      => 'Internal Note',
                                              p_document_text      => SUBSTR (p_internal_notes, 1, 2000),
                                              p_category_id        => v_category_id,
                                              p_document_id        => NULL,
                                              x_attachment_id      => v_attachment_id,
                                              x_return_status      => v_attachment_status,
                                              x_msg_count          => v_attachment_msg_cnt,
                                              x_msg_data           => v_attachment_msgs
                                             );*/
               SELECT (NVL (MAX (seq_num), 0) + 10)
                 INTO l_seq_num
                 FROM fnd_attached_documents
                WHERE entity_name = l_attach_entity AND pk1_value = TO_CHAR (l_header_rec_out.header_id);

               fnd_webattch.add_attachment (seq_num                   => l_seq_num,
                                            category_id               => v_category_id,
                                            document_description      => 'Internal Note',
                                            datatype_id               => oe_fnd_attachments_pub.g_datatype_long_text,
                                            text                      => p_internal_notes,
                                            file_name                 => NULL,
                                            url                       => NULL,
                                            function_name             => NULL,
                                            entity_name               => l_attach_entity,
                                            pk1_value                 => TO_CHAR (l_header_rec_out.header_id),
                                            pk2_value                 => NULL,
                                            pk3_value                 => NULL,
                                            pk4_value                 => NULL,
                                            pk5_value                 => NULL,
                                            media_id                  => NULL,
                                            user_id                   => fnd_global.user_id
                                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  log_message (p_external_ord_no || ' Error: While creating Internal attachment.');
                  NULL;
            END;
         END IF;

         IF p_external_notes IS NOT NULL
         THEN
            DECLARE
               CURSOR attachment_category_cur
               IS
                  SELECT category_id
                    --  INTO v_category_id
                  FROM   fnd_document_categories_vl
                   WHERE user_name IN
                            ('To print on Sales Order Ack',
                             'To print on Pack Slip',
                             'To print on Sales Shipping Confirmation'
                            );
            -- 'OM Sales Order Footer Note Printed';
            BEGIN
               FOR attachment_category_rec IN attachment_category_cur
               LOOP
                  BEGIN
                     /*oe_atchmt_util.add_attachment
                                                (p_api_version        => 1.0,
                                                 p_entity_code        => oe_globals.g_entity_header,
                                                 p_entity_id          => l_header_rec_out.header_id,
                                                 p_document_desc      => 'External Note',
                                                 p_document_text      => SUBSTR (p_external_notes, 1, 2000),
                                                 p_category_id        => attachment_category_rec.category_id,
                                                                                                       -- v_category_id,
                                                 p_document_id        => NULL,
                                                 x_attachment_id      => v_attachment_id,
                                                 x_return_status      => v_attachment_status,
                                                 x_msg_count          => v_attachment_msg_cnt,
                                                 x_msg_data           => v_attachment_msgs
                                                );*/
                     SELECT (NVL (MAX (seq_num), 0) + 10)
                       INTO l_seq_num
                       FROM fnd_attached_documents
                      WHERE entity_name = l_attach_entity AND pk1_value = TO_CHAR (l_header_rec_out.header_id);

                     fnd_webattch.add_attachment (seq_num                   => l_seq_num,
                                                  category_id               => attachment_category_rec.category_id,
                                                  document_description      => 'External Note',
                                                  datatype_id               => oe_fnd_attachments_pub.g_datatype_long_text,
                                                  text                      => p_external_notes,
                                                  file_name                 => NULL,
                                                  url                       => NULL,
                                                  function_name             => NULL,
                                                  entity_name               => l_attach_entity,
                                                  pk1_value                 => TO_CHAR (l_header_rec_out.header_id),
                                                  pk2_value                 => NULL,
                                                  pk3_value                 => NULL,
                                                  pk4_value                 => NULL,
                                                  pk5_value                 => NULL,
                                                  media_id                  => NULL,
                                                  user_id                   => fnd_global.user_id
                                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        log_message (p_external_ord_no || ' Error: While creating External attachment.');
                        NULL;
                  END;
               END LOOP;
            END;
         END IF;

         IF p_shipping_notes IS NOT NULL
         THEN
            -- dbms_output.put_line('Creating Shipping attachment.');
            BEGIN
               SELECT category_id
                 INTO v_category_id
                 FROM fnd_document_categories_vl
                WHERE user_name = 'Short Text';

               /*oe_atchmt_util.add_attachment (p_api_version        => 1.0,
                                              p_entity_code        => oe_globals.g_entity_header,
                                              p_entity_id          => l_header_rec_out.header_id,
                                              p_document_desc      => 'Shipping Note',
                                              p_document_text      => SUBSTR (p_shipping_notes, 1, 2000),
                                              p_category_id        => v_category_id,
                                              p_document_id        => NULL,
                                              x_attachment_id      => v_attachment_id,
                                              x_return_status      => v_attachment_status,
                                              x_msg_count          => v_attachment_msg_cnt,
                                              x_msg_data           => v_attachment_msgs
                                             );*/
               SELECT (NVL (MAX (seq_num), 0) + 10)
                 INTO l_seq_num
                 FROM fnd_attached_documents
                WHERE entity_name = l_attach_entity AND pk1_value = TO_CHAR (l_header_rec_out.header_id);

               fnd_webattch.add_attachment (seq_num                   => l_seq_num,
                                            category_id               => v_category_id,
                                            document_description      => 'Shipping Note',
                                            datatype_id               => oe_fnd_attachments_pub.g_datatype_long_text,
                                            text                      => p_shipping_notes,
                                            file_name                 => NULL,
                                            url                       => NULL,
                                            function_name             => NULL,
                                            entity_name               => l_attach_entity,
                                            pk1_value                 => TO_CHAR (l_header_rec_out.header_id),
                                            pk2_value                 => NULL,
                                            pk3_value                 => NULL,
                                            pk4_value                 => NULL,
                                            pk5_value                 => NULL,
                                            media_id                  => NULL,
                                            user_id                   => fnd_global.user_id
                                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  log_message (p_external_ord_no || ' Error: While creating Shipping Attachment.');
                  NULL;
            END;
         END IF;

----------------------------------------------------------------------------------
-- Create the reservation - Vishy --
--  Jagdish, Naga: 02/26: Reservation needs to be done only for Charge Sheets. --
-- Added below IF --
-----------------------------------------------------------------------------------
         IF l_order_type <> c_request_order_type
         THEN
            FOR order_lines_rec IN order_lines_cur
            LOOP
               BEGIN
                  SELECT msib.inventory_item_id,
                         lot_control_code,
                         serial_number_control_code,
                         mil.inventory_location_id
                    INTO l_inventory_item_id,
                         l_lot_control_code,
                         l_serial_control_code,
                         l_locator_id
                    FROM mtl_system_items_b msib,
                         mtl_item_locations mil,
                         xxom_sales_marketing_set_v xsms
                   WHERE msib.organization_id = l_organization_id
                     AND msib.inventory_item_status_code <> 'Inactive'
                     AND msib.segment1 = order_lines_rec.ordered_item
                     AND mil.organization_id = msib.organization_id
                     AND mil.segment1 = l_subinventory
                     AND mil.segment2 = SUBSTR (snm_division, 1, 3)
                     AND mil.segment3 = '001'
                     AND xsms.organization_id = msib.organization_id
                     AND xsms.inventory_item_id = msib.inventory_item_id;

                  log_message (   p_external_ord_no
                               || ': Lot control code:serial control: '
                               || l_lot_control_code
                               || ': '
                               || l_serial_control_code
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
                     log_message (p_external_ord_no || ': No Data found for lot, serial, sub, locator : ');
               END;

               FOR r IN l_so_lines.FIRST .. l_so_lines.LAST
               LOOP
                  IF     (order_lines_rec.ordered_item = l_so_lines (r).item)
                     AND (order_lines_rec.ordered_quantity = l_so_lines (r).quantity)
                     AND (l_so_lines (r).line_id IS NULL)
                  THEN
                     l_rsv_rec.demand_source_line_id := order_lines_rec.line_id;
                     l_rsv_rec.demand_source_name := NULL;
                     l_so_lines (r).line_id     := order_lines_rec.line_id;
                     l_rsv_rec.lot_number       := NULL;
                     l_rsv_rec.serial_number    := NULL;
                     log_message (p_external_ord_no || ' : Item is: ' || l_so_lines (r).item);
                     log_message (p_external_ord_no || ' : Qty to be reserved is: ' || l_so_lines (r).quantity);

                     -- check if it is lot or serial control on msi above
                     --  Lot Control     1 No 2 Yes
                     --  Serial Control  1 No 2 Predefined 5 dynamic at receipt
                     IF (l_lot_control_code = 2 AND l_so_lines (r).lot IS NOT NULL)
                     THEN
                        l_rsv_rec.lot_number       := l_so_lines (r).lot;
                        log_message (p_external_ord_no || ' : Lot Number: ' || l_so_lines (r).lot);
                        DBMS_OUTPUT.put_line ('lot: ' || l_so_lines (r).lot);
                     END IF;

                     IF (l_serial_control_code IN (2, 5) AND l_so_lines (r).serial_number IS NOT NULL)
                     THEN
                        l_serial_number (1).serial_number := l_so_lines (r).serial_number;
                        l_serial_number (1).inventory_item_id := l_inventory_item_id;
                        log_message (   p_external_ord_no
                                     || ': Lot control code:serial control: '
                                     || l_lot_control_code
                                     || ': '
                                     || l_serial_control_code
                                    );
                        log_message (p_external_ord_no || ' : Serial number: ' || l_serial_number (1).serial_number);
                        DBMS_OUTPUT.put_line ('serial: ' || l_serial_number (1).serial_number);
                        DBMS_OUTPUT.put_line ('item: ' || l_serial_number (1).inventory_item_id);
                     END IF;

                     DBMS_OUTPUT.put_line ('Lpn: ' || l_so_lines (r).kit_serial_number);
                     log_message (p_external_ord_no || ' : LPN Name: ' || l_so_lines (r).kit_serial_number);
                     l_rsv_rec.lpn_id           := NULL;
                     l_lpn_id                   := NULL;

                     IF (l_so_lines (r).kit_serial_number IS NOT NULL)
                     THEN
                        BEGIN
                           SELECT lpn_id
                             INTO l_lpn_id
                             FROM wms_license_plate_numbers
                            WHERE license_plate_number = l_so_lines (r).kit_serial_number
                              AND organization_id = l_organization_id;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                              DBMS_OUTPUT.put_line ('No Data found for lot, serial, sub, locator : ');
                        END;
                     END IF;

                     l_rsv_rec.lpn_id           := l_lpn_id;
                     log_message (p_external_ord_no || ' : LPN ID: ' || l_rsv_rec.lpn_id);
                     EXIT;
                  END IF;
               END LOOP;

               log_message (   p_external_ord_no
                            || 'Creating reservation for order header and line: '
                            || order_lines_rec.mso_sales_order_id
                            || ' : '
                            || order_lines_rec.line_id
                           );
               l_rsv_rec.requirement_date := SYSDATE;
               l_rsv_rec.organization_id  := l_organization_id;
               l_rsv_rec.demand_source_type_id := 2;                                                      -- sales order
               l_rsv_rec.inventory_item_id := l_inventory_item_id;
               l_rsv_rec.demand_source_header_id := order_lines_rec.mso_sales_order_id;          -- l_mtl_sales_order_id
               l_rsv_rec.primary_reservation_quantity := order_lines_rec.ordered_quantity;
               -- so_line_rec.ordered_quantity;
               l_rsv_rec.reservation_quantity := order_lines_rec.ordered_quantity;
               l_rsv_rec.reservation_uom_code := 'EA';
               l_rsv_rec.supply_source_type_id := 13;
               l_rsv_rec.ship_ready_flag  := NULL;                                                  -- 2;  -- don't need
               --
               l_rsv_rec.subinventory_id  := NULL;
               l_rsv_rec.subinventory_code := l_subinventory;      -- we always have this from above it is the rep's sub
               l_rsv_rec.locator_id       := l_locator_id;
               --  l_rsv_rec.reservation_uom_code := l_so_lines(r).item_uom;
               --  l_rsv_rec.reservation_quantity := l_so_lines(r).quantity; -- so_line_rec.ordered_quantity;
               l_rsv_rec.supply_source_name := 'OE-' || l_header_rec_out.order_number || '-RESERVATION';
               l_rsv_rec.supply_source_line_detail := NULL;
               l_rsv_rec.supply_source_line_id := NULL;
               l_rsv_rec.supply_source_header_id := NULL;
               l_rsv_rec.external_source_line_id := NULL;
               l_rsv_rec.external_source_code := NULL;
               l_rsv_rec.autodetail_group_id := NULL;
               l_rsv_rec.reservation_uom_id := NULL;
               l_rsv_rec.primary_uom_id   := NULL;
               l_rsv_rec.revision         := NULL;
               --- All of the below need explicitly set to NULL or API will throw errors
               l_rsv_rec.lot_number_id    := NULL;
               l_rsv_rec.reservation_id   := NULL;
               l_rsv_rec.demand_source_name := NULL;
               l_rsv_rec.demand_source_delivery := NULL;
               l_rsv_rec.autodetail_group_id := NULL;
               l_rsv_rec.external_source_code := NULL;
               l_rsv_rec.external_source_line_id := NULL;
               l_rsv_rec.supply_source_header_id := NULL;
               l_rsv_rec.pick_slip_number := NULL;
               l_rsv_rec.attribute_category := NULL;
               l_rsv_rec.attribute1       := NULL;
               l_rsv_rec.attribute2       := NULL;
               l_rsv_rec.attribute3       := NULL;
               l_rsv_rec.attribute4       := NULL;
               l_rsv_rec.attribute5       := NULL;
               l_rsv_rec.attribute6       := NULL;
               l_rsv_rec.attribute7       := NULL;
               l_rsv_rec.attribute8       := NULL;
               l_rsv_rec.attribute9       := NULL;
               l_rsv_rec.attribute10      := NULL;
               l_rsv_rec.attribute11      := NULL;
               l_rsv_rec.attribute12      := NULL;
               l_rsv_rec.attribute13      := NULL;
               l_rsv_rec.attribute14      := NULL;
               l_rsv_rec.attribute15      := NULL;
               log_message (   p_external_ord_no
                            || 'which is for item: '
                            || order_lines_rec.ordered_item
                            || ' and with primary qty: '
                            || l_rsv_rec.primary_reservation_quantity
                           );
               x_return_status_resv       := fnd_api.g_ret_sts_success;
               inv_reservation_pub.create_reservation (p_api_version_number            => 1.0,
                                                       p_init_msg_lst                  => fnd_api.g_true,
                                                       x_return_status                 => x_return_status_resv,
                                                       x_msg_count                     => x_msg_count_resv,
                                                       x_msg_data                      => x_msg_data_resv,
                                                       p_rsv_rec                       => l_rsv_rec,
                                                       p_serial_number                 => l_serial_number,
                                                       x_serial_number                 => v_serial_number,
                                                       p_partial_reservation_flag      => fnd_api.g_true,
                                                       p_force_reservation_flag        => fnd_api.g_false,
                                                       p_validation_flag               => fnd_api.g_true,
                                                       x_quantity_reserved             => v_quantity_reserved,
                                                       x_reservation_id                => v_reservation_id,
                                                       p_partial_rsv_exists            => FALSE
                                                      );
               log_message (p_external_ord_no || 'Reservation Created is id :===>' || TO_CHAR (v_reservation_id));
               log_message (p_external_ord_no || ' Rsv return status :===>' || x_return_status_resv);

               IF (x_return_status_resv <> fnd_api.g_ret_sts_success)
               THEN
                  IF order_lines_rec.line_type_id = l_bill_w_po_hold_line_type_id
                  THEN
                     l_hold_name                := 'Expired Inventory Hold';
                  ELSE
                     l_hold_name                := 'No Reservation Hold';
                  END IF;

                  -- If the reservation fails we need to put the line on Inventory Research Hold
                  -- Should also be in a shipset so that the invoice does not split
                  apply_hold
                      (p_hold_id             => NULL,
                       --Caller must supply one of these two values.  If both are supplied, the ID is used.
                       p_hold_name           => l_hold_name,
                                                  --'No Reservation Hold', variable used due to derived hold name above.
                       p_header_id           => l_header_rec_out.header_id,
                       p_line_id             => order_lines_rec.line_id,        --NULL line_id will create a header hold
                       p_return_status       => h_return_status,
                       p_return_message      => h_return_message
                      );

                  IF h_return_status <> fnd_api.g_ret_sts_success
                  THEN
                     --Something happened while applying the hold.  Raise appropriate error.
                     log_message (p_external_ord_no || 'Error applying hold: ' || h_return_message);
                  ELSE
                     --Hold applied
                     log_message (p_external_ord_no || 'Hold applied to line_id: ' || order_lines_rec.line_id);
                  END IF;

                  IF x_msg_count_resv > 0
                  THEN
                     FOR v_index IN 1 .. x_msg_count_resv
                     LOOP
                        fnd_msg_pub.get (p_msg_index          => v_index,
                                         p_encoded            => 'F',
                                         p_data               => x_msg_data_resv,
                                         p_msg_index_out      => v_msg_index_out
                                        );
                        x_msg_data_resv            := SUBSTR (x_msg_data_resv, 1, 1000);
                        log_message (   p_external_ord_no
                                     || ' x_msg_data_resv at Error at Reservation api --> '
                                     || x_msg_data_resv
                                    );
                     END LOOP;
                  END IF;
               ELSE
                  COMMIT;
                  log_message (p_external_ord_no || ' Reservation successfully created --> ' || v_reservation_id);
               END IF;
            END LOOP;
         END IF;                                                                -- Reservation only for Charge Sheets --

         --Order creation is successful.
         --Reservations have been attempted if necessary.
         --Now attempt to book the order.
         book_order (p_header_id          => l_header_rec_out.header_id,
                     x_return_status      => b_return_status,
                     x_message_text       => b_return_message
                    );
      ELSIF l_update_mode
      THEN
         --In case of a succesful update, go ahead and try to book the order.
         -- The book_order procedure will do nothing if the order is already booked.
         book_order (p_header_id          => l_header_rec_out.header_id,
                     x_return_status      => b_return_status,
                     x_message_text       => b_return_message
                    );
      END IF;                                                                       -- END CREATE ORDER SUCCESSFULL LOOP

      COMMIT;
      p_return_status            := fnd_api.g_ret_sts_success;
      p_return_code              := TO_CHAR (l_header_rec_out.order_number);

      IF l_update_mode
      THEN
         IF b_return_status = fnd_api.g_ret_sts_success
         THEN
            p_return_message           :=
                                    'Successfully updated and booked order ' || TO_CHAR (l_header_rec_out.order_number);
         ELSE
            p_return_message           := 'Successfully updated order ' || TO_CHAR (l_header_rec_out.order_number);
         END IF;
      ELSE
         IF b_return_status = fnd_api.g_ret_sts_success
         THEN
            p_return_message           :=
                                    'Successfully created and booked order ' || TO_CHAR (l_header_rec_out.order_number);
         ELSE
            p_return_message           := 'Successfully created order ' || TO_CHAR (l_header_rec_out.order_number);
         END IF;
      END IF;

      log_message (p_external_ord_no || ' ' || p_return_message);
   EXCEPTION
      WHEN e_order_error
      THEN
         p_return_status            := p_return_status;
         p_return_code              := SQLCODE;
         p_return_message           := 'Order API Error: ' || SQLERRM || p_return_message;
         log_message (p_external_ord_no || ' ' || p_return_message);
      WHEN e_other_error
      THEN
         p_return_status            := p_return_status;
         p_return_code              := SQLCODE;
         p_return_message           := 'INTG Validation: ' || p_return_message;
         log_message (p_external_ord_no || ' ' || p_return_message);
      WHEN OTHERS
      THEN
         p_return_status            := 'E';
         p_return_code              := SQLCODE;
         p_return_message           := 'INTG Unknown error processing order: ' || SQLERRM || ': ' || p_return_message;
         log_message (p_external_ord_no || ' ' || p_return_message);
   END;

   PROCEDURE apply_hold (
      p_hold_id          IN       oe_hold_definitions.hold_id%TYPE := NULL,
      --Caller must supply one of these two values.  If both are supplied, the ID is used.
      p_hold_name        IN       oe_hold_definitions.NAME%TYPE := NULL,
      p_header_id        IN       oe_order_headers_all.header_id%TYPE,
      p_line_id          IN       oe_order_lines_all.line_id%TYPE := NULL,      --NULL line_id will create a header hold
      p_return_status    OUT      VARCHAR2,
      p_return_message   OUT      VARCHAR2
   )
   IS
      c_procedure_name      CONSTANT VARCHAR2 (30)                      := 'APPLY_HOLD';
      v_hold_id                      oe_hold_definitions.hold_id%TYPE   := NULL;
      v_return_status                VARCHAR2 (30);
      v_msg_count                    NUMBER;
      v_msg_data                     VARCHAR2 (240);
      v_order_tbl                    oe_holds_pvt.order_tbl_type;
      c_default_hold_name   CONSTANT oe_hold_definitions.NAME%TYPE      := 'Customer Service Hold (L)';
   BEGIN
      IF p_hold_id IS NULL
      THEN
         IF p_hold_name IS NULL
         THEN
            --Both parameters cannot be null.  Return error.
            RAISE NO_DATA_FOUND;
         ELSE
            SELECT hold_id
              INTO v_hold_id
              FROM (SELECT   hold_id
                        FROM apps.oe_hold_definitions hd
                       WHERE hd.NAME = p_hold_name
                          --Enhancement opportunity: This default should be data-driven.
                          OR hd.NAME =
                                c_default_hold_name
                                               --This is a stop-gap hold to use in case the specified name is not found.
                    ORDER BY DECODE (hd.NAME, c_default_hold_name, 2, 1))
             WHERE ROWNUM < 2;
         END IF;
      ELSE
         v_hold_id                  := p_hold_id;
      END IF;

      --Now v_hold_id is the hold we will apply.
      v_order_tbl (1).header_id  := p_header_id;
      v_order_tbl (1).line_id    := p_line_id;                  --If this was NULL, then the hold is on the header only.
      --dbms_output.put_line ('attempting to hold id: ' || v_hold_id || ' to header/line: ' || v_order_tbl(1).header_id || ' / ' || v_order_tbl(1).line_id);
      oe_holds_pub.apply_holds (p_api_version          => 1.0,
                                p_order_tbl            => v_order_tbl,
                                p_hold_id              => v_hold_id,
                                p_hold_until_date      => NULL,
                                p_hold_comment         => NULL,
                                x_return_status        => v_return_status,
                                x_msg_count            => v_msg_count,
                                x_msg_data             => v_msg_data
                               );

      IF v_return_status = fnd_api.g_ret_sts_success
      THEN
         p_return_status            := fnd_api.g_ret_sts_success;
         p_return_message           := 'Hold was applied.';
      ELSE
         p_return_status            := 'E';
         p_return_message           :=
                         'Hold could not be applied ' || v_return_status || ' - ' || v_msg_count || ' - ' || v_msg_data;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_return_status            := 'E';
         p_return_message           := 'Unable to determine hold_id';
      WHEN OTHERS
      THEN
         p_return_status            := 'U';
         p_return_message           := 'Unable to apply hold: ' || SQLERRM;
   END apply_hold;

   PROCEDURE book_order (
      p_header_id       IN       oe_order_headers.header_id%TYPE,
      x_return_status   OUT      VARCHAR2,
      x_message_text    OUT      VARCHAR2
   )
   IS
      c_procedure_name      CONSTANT VARCHAR2 (30)                            := 'BOOK_ORDER';

      CURSOR booked_cur
      IS
         SELECT booked_flag
           FROM oe_order_headers
          WHERE header_id = p_header_id;

      v_action_request_tbl           oe_order_pub.request_tbl_type;
      v_return_status                VARCHAR2 (1);
      v_msg_count                    NUMBER;
      v_msg_data                     VARCHAR2 (2000);
      v_booked_flag                  oe_order_headers.booked_flag%TYPE;
      --Redifining "v" versions of these records to differentiate them from the "global" versions.
      v_header_rec_out               oe_order_pub.header_rec_type;
      v_header_val_rec_out           oe_order_pub.header_val_rec_type;
      v_header_adj_tbl_out           oe_order_pub.header_adj_tbl_type;
      v_header_adj_val_tbl_out       oe_order_pub.header_adj_val_tbl_type;
      v_header_price_att_tbl_out     oe_order_pub.header_price_att_tbl_type;
      v_header_adj_att_tbl_out       oe_order_pub.header_adj_att_tbl_type;
      v_header_adj_assoc_tbl_out     oe_order_pub.header_adj_assoc_tbl_type;
      v_header_scredit_tbl_out       oe_order_pub.header_scredit_tbl_type;
      v_header_scredit_val_tbl_out   oe_order_pub.header_scredit_val_tbl_type;
      v_line_tbl_out                 oe_order_pub.line_tbl_type;
      v_line_val_tbl_out             oe_order_pub.line_val_tbl_type;
      v_line_adj_tbl_out             oe_order_pub.line_adj_tbl_type;
      v_line_adj_val_tbl_out         oe_order_pub.line_adj_val_tbl_type;
      v_line_price_att_tbl_out       oe_order_pub.line_price_att_tbl_type;
      v_line_adj_att_tbl_out         oe_order_pub.line_adj_att_tbl_type;
      v_line_adj_assoc_tbl_out       oe_order_pub.line_adj_assoc_tbl_type;
      v_line_scredit_tbl_out         oe_order_pub.line_scredit_tbl_type;
      v_line_scredit_val_tbl_out     oe_order_pub.line_scredit_val_tbl_type;
      v_lot_serial_tbl_out           oe_order_pub.lot_serial_tbl_type;
      v_lot_serial_val_tbl_out       oe_order_pub.lot_serial_val_tbl_type;
      v_action_request_tbl_out       oe_order_pub.request_tbl_type;
   BEGIN
      oe_debug_pub.ADD ('INTG: In book_order', 1);
      log_message (g_external_ord_no || ' In book_order for: ' || p_header_id);

      --Start by checking if the order is already booked
      OPEN booked_cur;

      FETCH booked_cur
       INTO v_booked_flag;

      CLOSE booked_cur;

      IF v_booked_flag = 'Y'
      THEN
         log_message (g_external_ord_no || ' Order is already booked.');
         x_return_status            := fnd_api.g_ret_sts_error;
         RETURN;
      END IF;

      v_action_request_tbl (1).request_type := oe_globals.g_book_order;
      v_action_request_tbl (1).entity_code := oe_globals.g_entity_header;
      v_action_request_tbl (1).entity_id := p_header_id;
      oe_order_pub.process_order (p_api_version_number          => 1.0,
                                  p_init_msg_list               => fnd_api.g_true,
                                  p_action_commit               => fnd_api.g_false,
                                  p_action_request_tbl          => v_action_request_tbl,
                                  x_return_status               => v_return_status,
                                  x_msg_count                   => v_msg_count,
                                  x_msg_data                    => v_msg_data,
                                  --These are all unused but required in the call
                                  -- If book_order is called before something else that needs these out prameters,
                                  -- then change these to procedure local variables.
                                  x_header_rec                  => v_header_rec_out,
                                  x_header_val_rec              => v_header_val_rec_out,
                                  x_header_adj_tbl              => v_header_adj_tbl_out,
                                  x_header_adj_val_tbl          => v_header_adj_val_tbl_out,
                                  x_header_price_att_tbl        => v_header_price_att_tbl_out,
                                  x_header_adj_att_tbl          => v_header_adj_att_tbl_out,
                                  x_header_adj_assoc_tbl        => v_header_adj_assoc_tbl_out,
                                  x_header_scredit_tbl          => v_header_scredit_tbl_out,
                                  x_header_scredit_val_tbl      => v_header_scredit_val_tbl_out,
                                  x_line_tbl                    => v_line_tbl_out,
                                  x_line_val_tbl                => v_line_val_tbl_out,
                                  x_line_adj_tbl                => v_line_adj_tbl_out,
                                  x_line_adj_val_tbl            => v_line_adj_val_tbl_out,
                                  x_line_price_att_tbl          => v_line_price_att_tbl_out,
                                  x_line_adj_att_tbl            => v_line_adj_att_tbl_out,
                                  x_line_adj_assoc_tbl          => v_line_adj_assoc_tbl_out,
                                  x_line_scredit_tbl            => v_line_scredit_tbl_out,
                                  x_line_scredit_val_tbl        => v_line_scredit_val_tbl_out,
                                  x_lot_serial_tbl              => v_lot_serial_tbl_out,
                                  x_lot_serial_val_tbl          => v_lot_serial_val_tbl_out,
                                  x_action_request_tbl          => v_action_request_tbl_out
                                 );

      IF v_return_status = fnd_api.g_ret_sts_success
      THEN
         /*
         ||
         || The API returns FND_API.G_RET_STS_SUCCESS even when the
         || order has not been booked!  Need to check whether it has
         || been booked when success is returned.
         ||
         */
         OPEN booked_cur;

         FETCH booked_cur
          INTO v_booked_flag;

         CLOSE booked_cur;

         IF v_booked_flag = 'N'
         THEN
            log_message (g_external_ord_no || ' Order was NOT booked.');
            v_return_status            := fnd_api.g_ret_sts_error;
         ELSE
            log_message (g_external_ord_no || ' Order was booked.');
         END IF;
      END IF;

      --Display any messages regardless of booking status.
      FOR i IN 1 .. v_msg_count
      LOOP
         log_message (   g_external_ord_no
                      || ' Booking message '
                      || i
                      || ' of '
                      || v_msg_count
                      || ' is: '
                      || oe_msg_pub.get (p_msg_index => i, p_encoded => fnd_api.g_false)
                     );
      END LOOP;

      x_return_status            := v_return_status;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status            := fnd_api.g_ret_sts_unexp_error;
         log_message (g_external_ord_no || ' WHEN OTHERS in ' || c_procedure_name || ' - ' || SQLERRM);
   END book_order;

   /*
   || This procedure validates the cc info and returns it in the out variables
   || or it returns NULL values.
   */
   PROCEDURE validate_cc_info (
      p_cc_code              IN       VARCHAR2,
      p_cc_number            IN       VARCHAR2,
      p_cc_expiration_date   IN       VARCHAR2,
      p_cc_holder_name       IN       VARCHAR2,
      x_payment_type_code    OUT      VARCHAR2,
      x_cc_code              OUT      VARCHAR2,
      x_cc_number            OUT      VARCHAR2,
      x_cc_expiration_date   OUT      DATE,
      x_cc_holder_name       OUT      VARCHAR2
   )
   IS
      l_valid_flag   BOOLEAN := TRUE;

      --Local procedure to compute the cc_num checkdigit
      FUNCTION valid_digits (p_value VARCHAR2)
         RETURN BOOLEAN
      IS
         l_temp   NUMBER := 0;
         y        NUMBER := 0;
      BEGIN
         FOR x IN 1 .. LENGTH (p_value)
         LOOP
            y                          := TO_NUMBER (SUBSTR (p_value, -x, 1));

            IF MOD (x, 2) = 0
            THEN
               y                          := y * 2;

               IF y > 9
               THEN
                  y                          := y - 9;
               END IF;
            END IF;

            l_temp                     := l_temp + y;
         END LOOP;

         IF MOD (l_temp, 10) = 0
         THEN
            RETURN TRUE;
         ELSE
            RETURN FALSE;
         END IF;
      END valid_digits;
   BEGIN
      --All values must be not null
      IF p_cc_code IS NULL OR p_cc_number IS NULL OR p_cc_expiration_date IS NULL OR p_cc_holder_name IS NULL
      THEN
         log_message (g_external_ord_no || ' incomplete cc_data');
         l_valid_flag               := FALSE;
      END IF;

      --The cc_code must be found by this SQL.
      IF l_valid_flag
      THEN
         BEGIN
            SELECT credit_card_code
              INTO x_cc_code
              FROM so_credit_cards_v
             WHERE UPPER (credit_card) = UPPER (p_cc_code);
         EXCEPTION
            WHEN OTHERS
            THEN
               log_message (g_external_ord_no || ' cc validate failure: invalid cc_code');
               l_valid_flag               := FALSE;
         END;
      END IF;

      --Do checksum validation on the cc_num
      IF l_valid_flag
      THEN
         IF valid_digits (p_cc_number)
         THEN
            log_message (g_external_ord_no || ' valid cc num');
         ELSE
            log_message (g_external_ord_no || ' invalid cc_num');
            l_valid_flag               := FALSE;
         END IF;
      END IF;

      --Check known cc_num lengths
      IF l_valid_flag
      THEN
         IF SUBSTR (p_cc_number, 1, 1) IN ('4', '5')
         THEN
            IF LENGTH (p_cc_number) <> 16
            THEN
               log_message (g_external_ord_no || ' invalid visa/mc cc_num length');
               l_valid_flag               := FALSE;
            END IF;
         ELSIF SUBSTR (p_cc_number, 1, 1) IN ('3')
         THEN
            IF LENGTH (p_cc_number) <> 15
            THEN
               log_message (g_external_ord_no || ' invalid amex cc_num length');
               l_valid_flag               := FALSE;
            END IF;
         ELSE
            log_message (g_external_ord_no || ' unknown cc_num length - continuing.');
         END IF;
      END IF;

      --Verify the exp date is in the future
      IF l_valid_flag
      THEN
         BEGIN
            IF ADD_MONTHS (TO_DATE (p_cc_expiration_date, 'mm/yyyy'), 1) < SYSDATE
            THEN
               --expired card
               log_message (g_external_ord_no || ' expired cc date');
               l_valid_flag               := FALSE;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               log_message (g_external_ord_no || ' invalid cc date format ' || SQLERRM);
               l_valid_flag               := FALSE;
         END;
      END IF;

      IF l_valid_flag
      THEN
         log_message (g_external_ord_no || ' returning valid cc data.');
         x_payment_type_code        := 'CREDIT_CARD';
         --x_cc_code                     := p_cc_code; Filled by cursor above.
         x_cc_number                := p_cc_number;
         x_cc_expiration_date       := TO_DATE (p_cc_expiration_date, 'MM/YYYY');
         x_cc_holder_name           := p_cc_holder_name;
      ELSE
         x_payment_type_code        := fnd_api.g_miss_char;                                  --NULL; --Is this correct?
         x_cc_code                  := fnd_api.g_miss_char;                                                     --NULL;
         x_cc_number                := fnd_api.g_miss_char;                                                     --NULL;
         x_cc_expiration_date       := fnd_api.g_miss_date;                                                     --NULL;
         x_cc_holder_name           := fnd_api.g_miss_char;                                                     --NULL;
      END IF;
   END validate_cc_info;

   --Encapsulates all of the Deliver To Site find/create logic
   -- including managing the -1 and -2 values to control interfacing the site back to SS
   PROCEDURE create_deliver_to_site (
      p_external_ord_no     IN       VARCHAR2,
      p_srep_number         IN       VARCHAR2,
      p_party_site_number   IN       VARCHAR2,
      p_address_1           IN       VARCHAR2,
      p_address_2           IN       VARCHAR2,
      p_city                IN       VARCHAR2,
      p_state               IN       VARCHAR2,
      p_postal_code         IN       VARCHAR2,
      x_site_use_id         OUT      NUMBER,
      x_return_status       OUT      VARCHAR2,
      x_return_code         OUT      VARCHAR2,
      x_return_message      OUT      VARCHAR2
   )
   IS
      l_location_rec        hz_location_v2pub.location_rec_type;
      l_cust_acct_id        NUMBER;
      l_party_id            NUMBER;
      l_location_id         NUMBER;
      l_cust_acct_site_id   NUMBER;
      l_srep_number         VARCHAR2 (100);
   --l_party_site_rec          hz_party_site_v2pub.party_site_rec_type;
   --l_cust_acct_site_rec      hz_cust_account_site_v2pub.cust_acct_site_rec_type;
   --l_cust_site_use_rec       hz_cust_account_site_v2pub.cust_site_use_rec_type;
   BEGIN
      log_message (p_external_ord_no || ' Processing a deliver to address. ps_num: ' || p_party_site_number);

      --This is a flag to affect attribute1 on a created DT party_site.
      IF NVL (p_party_site_number, '-1') = '-1'
      THEN
         l_srep_number              := NULL;
      ELSIF p_party_site_number = '-2'
      THEN
         l_srep_number              := p_srep_number;
      ELSIF p_party_site_number IS NOT NULL
      THEN
         --This is the party_site_number of an existing DT site.  Get and return the site_use_id.
         BEGIN
            SELECT ps.location_id,
                   su.site_use_id
              INTO l_location_id,
                   x_site_use_id
              FROM hz_cust_site_uses_all su,
                   hz_cust_acct_sites_all cas,
                   hz_party_sites ps
             WHERE ps.party_site_number = p_party_site_number
               AND ps.party_site_id = cas.party_site_id
               AND cas.cust_acct_site_id =
                      su.cust_acct_site_id(+)
                    --OUTER to allow a valid PS number that has no DT Site Use.  Following code will add a new site use.
               AND su.site_use_code(+) = 'DELIVER_TO'
               AND su.status(+) = 'A';

            log_message (   p_external_ord_no
                         || ' Found a location. Loc ID/DT SU ID: '
                         || l_location_id
                         || '/'
                         || x_site_use_id
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               --Invalid party_site_number.  Treat it as if it were '-1'
               l_srep_number              := NULL;
               l_location_id              := NULL;
               x_site_use_id              := NULL;
         END;
      END IF;

      IF     x_site_use_id IS NULL                                                             --If already found, stop!
         AND (   (p_address_1 IS NOT NULL AND p_city IS NOT NULL AND p_state IS NOT NULL AND p_postal_code IS NOT NULL
                 )                                                                     --DT address fields were provided
              OR l_location_id IS NOT NULL
             )                                                      --Or a location was found with the party_site_number
      THEN
         log_message (p_external_ord_no || ' Processing a deliver to address. Loc ID: ' || l_location_id);

         -- This belongs with the Rep, so I need to look up their customer_account_id and party_id
         BEGIN
            SELECT pla.customer_id,
                   hca.party_id
              INTO l_cust_acct_id,
                   l_party_id
              FROM mtl_secondary_inventories msi,
                   mtl_item_locations mil,
                   hr_locations hl,
                   po_location_associations_all pla,
                   hz_cust_site_uses_all ship_to,
                   hz_cust_accounts hca
             WHERE hca.cust_account_id = pla.customer_id
               AND ship_to.site_use_id = pla.site_use_id
               AND pla.location_id = hl.location_id
               AND hl.location_id = msi.location_id
               AND msi.secondary_inventory_name = mil.subinventory_code
               AND (msi.attribute2 = p_srep_number OR mil.attribute3 = p_srep_number)
               AND ROWNUM < 2; --Added to prevent too_many_rows if a multi-locator subinv is still linked on the subinv.
         EXCEPTION
            WHEN OTHERS
            THEN
               log_message (p_external_ord_no || 'Sales Rep/Dealer Config Error : ' || p_srep_number || ' - ' || SQLERRM
                           );
               x_return_status            := 'E';
               x_return_code              := SQLCODE;
               x_return_message           := 'Sales Rep/Dealer Config Error : ' || p_srep_number || ' - ' || SQLERRM;
               RAISE e_other_error;
         END;

         log_message (p_external_ord_no || ' rep cust_account_id: ' || l_cust_acct_id);

         IF l_location_id IS NULL                                      --It is possible that we found the location above
         THEN
            -- create the address first
            l_location_rec.address1    := UPPER (p_address_1);
            l_location_rec.address2    := UPPER (p_address_2);
            l_location_rec.city        := UPPER (p_city);
            l_location_rec.state       := UPPER (p_state);
            l_location_rec.postal_code := p_postal_code;
            create_location (p_external_ord_no      => p_external_ord_no,
                             p_party_id             => l_party_id,
                             p_loc_data             => l_location_rec,
                             x_location_id          => l_location_id
                            );
         END IF;

         log_message (p_external_ord_no || ' rep location_id: ' || l_location_id);
         -- Now create the party site
         create_sites (p_external_ord_no        => p_external_ord_no,
                       p_party_id               => l_party_id,
                       p_cust_acct_id           => l_cust_acct_id,
                       p_location_id            => l_location_id,
                       p_salesrep_number        => l_srep_number,
                       x_cust_acct_site_id      => l_cust_acct_site_id
                      );
         log_message (p_external_ord_no || ' cust_acct_site_id: ' || l_cust_acct_site_id);
         -- Create the Site Use
         create_site_use (p_external_ord_no        => p_external_ord_no,
                          p_cust_acct_site_id      => l_cust_acct_site_id,
                          p_site_use_code          => 'DELIVER_TO',
                          x_site_use_id            => x_site_use_id
                         );

         IF x_site_use_id IS NULL
         THEN
            --something went wrong.
            x_return_status            := 'U';
            x_return_code              := -99;
            x_return_message           := 'DT Site not created: ' || p_srep_number;
         END IF;
      END IF;

      log_message (p_external_ord_no || ' rep DT site_use_id: ' || x_site_use_id);
      x_return_status            := 'S';
   EXCEPTION
      WHEN e_other_error
      THEN
         NULL;                                               --messages have already been assigned to return variables.
      WHEN OTHERS
      THEN
         log_message (p_external_ord_no || 'Error in create_deliver_to_site: ' || SQLERRM);
         x_return_status            := 'U';
         x_return_code              := SQLCODE;
         x_return_message           := 'Unable to find/create DT Site: ' || p_srep_number || ' - ' || SQLERRM;
   END create_deliver_to_site;

   --Called during the creation of the DT Site under the salesrep's account
   PROCEDURE create_location (
      p_external_ord_no   IN       VARCHAR2,
      p_party_id          IN       NUMBER,
      p_loc_data          IN       hz_location_v2pub.location_rec_type,
      x_location_id       OUT      NUMBER
   )
   IS
      v_location_rec    hz_location_v2pub.location_rec_type;
      v_location_id     NUMBER;
      v_return_status   VARCHAR2 (2000);
      v_msg_count       NUMBER;
      v_msg_data        VARCHAR2 (20000);

      CURSOR existing_loc_cur (p_party_id IN NUMBER, p_loc_data hz_location_v2pub.location_rec_type)
      IS
         SELECT loc.location_id
           FROM hz_party_sites ps,
                hz_locations loc
          WHERE ps.party_id = p_party_id
            AND loc.location_id = ps.location_id
            AND loc.address1 = p_loc_data.address1
            AND NVL (loc.address2, 'xyz123') = NVL (p_loc_data.address2, 'xyz123')
            AND loc.city = p_loc_data.city
            AND loc.state = p_loc_data.state
            AND loc.postal_code = p_loc_data.postal_code;
   BEGIN
      OPEN existing_loc_cur (p_party_id, p_loc_data);

      FETCH existing_loc_cur
       INTO v_location_id;

      IF existing_loc_cur%FOUND
      THEN
         --This party already had this
         log_message (p_external_ord_no || ' Location already exists: ' || v_location_id || '  Continuing...');
      ELSE
         --Create the location
         v_location_rec.country     := 'US';                                                                  --Really?
         v_location_rec.address1    := p_loc_data.address1;
         v_location_rec.address2    := p_loc_data.address2;
         v_location_rec.city        := p_loc_data.city;
         v_location_rec.postal_code := p_loc_data.postal_code;
         v_location_rec.state       := p_loc_data.state;
         v_location_rec.created_by_module := l_created_by_module;
                                                          --Must link to Receivables lookup type: HZ_CREATED_BY_MODULES
         hz_location_v2pub.create_location (p_init_msg_list      => fnd_api.g_true,
                                            p_location_rec       => v_location_rec,
                                            x_location_id        => v_location_id,
                                            x_return_status      => v_return_status,
                                            x_msg_count          => v_msg_count,
                                            x_msg_data           => v_msg_data
                                           );

         IF v_return_status = fnd_api.g_ret_sts_success
         THEN
            log_message (p_external_ord_no || ' Created Location ID: ' || v_location_id);
         ELSE
            log_message (p_external_ord_no || ' create_location x_return_status = ' || SUBSTR (v_return_status, 1, 255));
            log_message (p_external_ord_no || ' create_location x_msg_count = ' || TO_CHAR (v_msg_count));
            log_message (p_external_ord_no || ' create_location x_msg_data = ' || SUBSTR (v_msg_data, 1, 255));

            IF v_msg_count > 0
            THEN
               FOR i IN 1 .. v_msg_count
               LOOP
                  log_message (   p_external_ord_no
                               || ' Msg '
                               || i
                               || ': '
                               || SUBSTR (fnd_msg_pub.get (p_msg_index => i, p_encoded => fnd_api.g_false), 1, 1990)
                              );
               END LOOP;
            END IF;
         END IF;
      END IF;

      CLOSE existing_loc_cur;

      x_location_id              := v_location_id;
   END create_location;

   --Called during the creation of the DT Site under the salesrep's account
   PROCEDURE create_sites (
      p_external_ord_no     IN       VARCHAR2,
      p_party_id            IN       NUMBER,
      p_cust_acct_id        IN       NUMBER,
      p_location_id         IN       NUMBER,
      p_salesrep_number     IN       VARCHAR2,
      x_cust_acct_site_id   OUT      NUMBER
   )
   IS
      v_party_site_rec       hz_party_site_v2pub.party_site_rec_type;
      v_party_site_id        NUMBER;
      v_party_site_num       VARCHAR2 (100);
      v_cust_acct_site_rec   hz_cust_account_site_v2pub.cust_acct_site_rec_type;
      v_cust_acct_site_id    NUMBER;
      v_return_status        VARCHAR2 (2000);
      v_msg_count            NUMBER;
      v_msg_data             VARCHAR2 (20000);

      CURSOR existing_ps_cur (p_party_id NUMBER, p_location_id NUMBER)
      IS
         SELECT ps.party_site_id
           FROM hz_party_sites ps
          WHERE ps.location_id = p_location_id AND ps.party_id = p_party_id;

      CURSOR existing_cas_cur (p_cust_acct_id NUMBER, p_party_site_id NUMBER)
      IS
         SELECT cust_acct_site_id
           FROM hz_cust_acct_sites_all
          WHERE cust_account_id = p_cust_acct_id AND party_site_id = p_party_site_id;
   BEGIN
      --Create the Party Site
      OPEN existing_ps_cur (p_party_id, p_location_id);

      FETCH existing_ps_cur
       INTO v_party_site_id;

      IF existing_ps_cur%FOUND
      THEN
         --This party already had a site for this location
         log_message (p_external_ord_no || 'Party Site already exists: ' || v_party_site_id || '  Continuing...');
      ELSE
         v_party_site_rec.party_id  := p_party_id;
         v_party_site_rec.location_id := p_location_id;
         v_party_site_rec.attribute1 := p_salesrep_number;        --if not null, flags the site to sync with Surgisoft.
         v_party_site_rec.created_by_module := l_created_by_module;
                                                          --Must link to Receivables lookup type: HZ_CREATED_BY_MODULES
         hz_party_site_v2pub.create_party_site (p_init_msg_list          => fnd_api.g_true,
                                                p_party_site_rec         => v_party_site_rec,
                                                x_party_site_id          => v_party_site_id,
                                                x_party_site_number      => v_party_site_num,
                                                x_return_status          => v_return_status,
                                                x_msg_count              => v_msg_count,
                                                x_msg_data               => v_msg_data
                                               );

         IF v_return_status = fnd_api.g_ret_sts_success
         THEN
            log_message (p_external_ord_no || ' Created Party Site ID: ' || v_party_site_id);
         ELSE
            log_message (p_external_ord_no || ' Party Site x_return_status = ' || SUBSTR (v_return_status, 1, 255));
            log_message (p_external_ord_no || ' Party Site x_msg_count = ' || TO_CHAR (v_msg_count));
            log_message (p_external_ord_no || ' Party Site x_msg_data = ' || SUBSTR (v_msg_data, 1, 255));

            IF v_msg_count > 0
            THEN
               FOR i IN 1 .. v_msg_count
               LOOP
                  log_message (   p_external_ord_no
                               || ' Msg '
                               || i
                               || ': '
                               || SUBSTR (fnd_msg_pub.get (p_msg_index => i, p_encoded => fnd_api.g_false), 1, 1990)
                              );
               END LOOP;
            END IF;
         END IF;
      END IF;

      CLOSE existing_ps_cur;

      --Create the Cust Acct Site
      OPEN existing_cas_cur (p_cust_acct_id, v_party_site_id);

      FETCH existing_cas_cur
       INTO v_cust_acct_site_id;

      IF existing_cas_cur%FOUND
      THEN
         --This customer already had a site for this location
         log_message (p_external_ord_no || ' Cust Acct Site already exists: ' || v_cust_acct_site_id
                      || '  Continuing...'
                     );
      ELSE
         v_cust_acct_site_rec.cust_account_id := p_cust_acct_id;
         v_cust_acct_site_rec.party_site_id := v_party_site_id;
         v_cust_acct_site_rec.created_by_module := l_created_by_module;
                                                          --Must link to Receivables lookup type: HZ_CREATED_BY_MODULES
         hz_cust_account_site_v2pub.create_cust_acct_site (p_init_msg_list           => fnd_api.g_true,
                                                           p_cust_acct_site_rec      => v_cust_acct_site_rec,
                                                           x_cust_acct_site_id       => v_cust_acct_site_id,
                                                           x_return_status           => v_return_status,
                                                           x_msg_count               => v_msg_count,
                                                           x_msg_data                => v_msg_data
                                                          );

         IF v_return_status = fnd_api.g_ret_sts_success
         THEN
            log_message (p_external_ord_no || ' Created Cust Acct Site ID: ' || v_cust_acct_site_id);
         ELSE
            log_message (p_external_ord_no || ' Cust Acct Site x_return_status = ' || SUBSTR (v_return_status, 1, 255));
            log_message (p_external_ord_no || ' Cust Acct Site x_msg_count = ' || TO_CHAR (v_msg_count));
            log_message (p_external_ord_no || ' Cust Acct Site x_msg_data = ' || SUBSTR (v_msg_data, 1, 255));

            IF v_msg_count > 0
            THEN
               FOR i IN 1 .. v_msg_count
               LOOP
                  log_message (   p_external_ord_no
                               || ' Msg '
                               || i
                               || ': '
                               || SUBSTR (fnd_msg_pub.get (p_msg_index => i, p_encoded => fnd_api.g_false), 1, 1990)
                              );
               END LOOP;
            END IF;
         END IF;
      END IF;

      CLOSE existing_cas_cur;

      x_cust_acct_site_id        := v_cust_acct_site_id;
   END create_sites;

   PROCEDURE create_site_use (
      p_external_ord_no     IN       VARCHAR2,
      p_cust_acct_site_id   IN       NUMBER,
      p_site_use_code       IN       VARCHAR2,
      x_site_use_id         OUT      NUMBER
   )
   IS
      v_site_use_rec       hz_cust_account_site_v2pub.cust_site_use_rec_type;
      v_site_use_id        NUMBER;
      v_st_site_use_rec    hz_cust_account_site_v2pub.cust_site_use_rec_type;
      v_st_site_id         NUMBER;
      v_cust_profile_rec   hz_customer_profile_v2pub.customer_profile_rec_type;
      v_return_status      VARCHAR2 (2000);
      v_msg_count          NUMBER;
      v_msg_data           VARCHAR2 (20000);

      CURSOR existing_su_cur (p_cust_acct_site_id NUMBER, p_site_use_code VARCHAR2)
      IS
         SELECT site_use_id
           FROM hz_cust_site_uses_all
          WHERE cust_acct_site_id = p_cust_acct_site_id AND site_use_code = p_site_use_code AND status = 'A';
   BEGIN
      --Create BILL_TO Cust Site Uses (Creates Party Site Uses as a side-effect)
      OPEN existing_su_cur (p_cust_acct_site_id, p_site_use_code);

      FETCH existing_su_cur
       INTO v_site_use_id;

      IF existing_su_cur%FOUND
      THEN
         --This cust acct site already has a site use of this type
         log_message (   p_external_ord_no
                      || ' '
                      || p_site_use_code
                      || ' Cust Site Use already exists: '
                      || v_site_use_id
                      || '  Continuing...'
                     );
      ELSE
         v_site_use_rec.cust_acct_site_id := p_cust_acct_site_id;
         v_site_use_rec.site_use_code := p_site_use_code;
         v_site_use_rec.created_by_module := l_created_by_module;
                                                          --Must link to Receivables lookup type: HZ_CREATED_BY_MODULES
         hz_cust_account_site_v2pub.create_cust_site_use (p_init_msg_list             => fnd_api.g_true,
                                                          p_cust_site_use_rec         => v_site_use_rec,
                                                          p_customer_profile_rec      => v_cust_profile_rec,
                                                          p_create_profile            => fnd_api.g_false,
                                                          p_create_profile_amt        => fnd_api.g_false,
                                                          x_site_use_id               => v_site_use_id,
                                                          x_return_status             => v_return_status,
                                                          x_msg_count                 => v_msg_count,
                                                          x_msg_data                  => v_msg_data
                                                         );

         IF v_return_status = fnd_api.g_ret_sts_success
         THEN
            log_message (p_external_ord_no || ' Created ' || p_site_use_code || ' Site Use ID: ' || v_site_use_id);
         ELSE
            log_message (p_external_ord_no || ' Site Use x_return_status = ' || SUBSTR (v_return_status, 1, 255));
            log_message (p_external_ord_no || ' Site Use x_msg_count = ' || TO_CHAR (v_msg_count));
            log_message (p_external_ord_no || ' Site Use x_msg_data = ' || SUBSTR (v_msg_data, 1, 255));

            IF v_msg_count > 0
            THEN
               FOR i IN 1 .. v_msg_count
               LOOP
                  log_message (   p_external_ord_no
                               || ' Msg '
                               || i
                               || ': '
                               || SUBSTR (fnd_msg_pub.get (p_msg_index => i, p_encoded => fnd_api.g_false), 1, 1990)
                              );
               END LOOP;
            END IF;
         END IF;
      END IF;

      CLOSE existing_su_cur;

      x_site_use_id              := v_site_use_id;
   END create_site_use;
END xxom_cnsgn_soi_pkg;                                                                                       -- PACKAGE
/
