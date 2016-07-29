DROP PACKAGE BODY APPS.XX_OM_ITEM_ORDERABILITY_AME;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OM_ITEM_ORDERABILITY_AME" 
AS
----------------------------------------------------------------------
/*
 Created By    : Yogesh
 Creation Date : 22-SEP-2013
 File Name     : xxomitmordame.pkb
 Description   : This script creates the cody of the package
                 body xx_om_item_orderability_ame
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 22-SEP-2013  Yogesh                Initial Development
 15-Sep-2014  Jaya Maran             Modified for Ticket#7197. OE MSG intialize commented.
 03-Nov-2014  Dhiren                Added Logic For OU -- WAVE2 Requirment ---
*/
----------------------------------------------------------------------

    FUNCTION cancel_order_line (p_line_id IN NUMBER)
    RETURN VARCHAR2
    IS
       CURSOR c_so_details(p_line_id NUMBER)
       IS
         SELECT oh.order_number,
                ol.line_number,
                ol.shipment_number,
                ol.header_id,
                ol.line_id,
                ol.flow_status_code,
                oh.org_id
           FROM oe_order_headers oh,
                oe_order_lines ol--,
                --mtl_system_items msi,
                --mtl_parameters mp,
                --wsh_delivery_details wsh
          WHERE --mp.organization_id       = msi.organization_id
                ol.header_id             = oh.header_id
            --AND ol.inventory_item_id     = msi.inventory_item_id
            --AND wsh.source_line_id       = ol.line_id
            --AND wsh.source_header_id     = oh.header_id
            --AND wsh.released_status NOT IN ('Y','C','L','I')
            --AND ol.flow_status_code     IN ('AWAITING_SHIPPING','ENTERED')
            AND oh.flow_status_code     IN ('BOOKED', 'ENTERED')
            AND ol.line_id = p_line_id;

       x_user_id                       NUMBER;
       x_resp_id                       NUMBER;
       x_appl_id                       NUMBER;
       x_chr_program_unit_name         VARCHAR2 (100);
       x_ret_status                    VARCHAR2 (1000) := NULL;
       x_l_msg_count                   NUMBER          := 0;
       x_l_msg_data                    VARCHAR2 (2000);
       x_api_version                   NUMBER := 1.0;
       x_cancel_reason                 VARCHAR2 (80);
       x_cancel_reason_name            VARCHAR2 (80);
       x_header_rec_in                 oe_order_pub.header_rec_type;
       x_line_tbl_in                   oe_order_pub.line_tbl_type;
       x_action_request_tbl_in         oe_order_pub.request_tbl_type;
       x_header_rec_out                oe_order_pub.header_rec_type;
       x_line_tbl_out                  oe_order_pub.line_tbl_type;
       x_header_val_rec_out            oe_order_pub.header_val_rec_type;
       x_header_adj_tbl_out            oe_order_pub.header_adj_tbl_type;
       x_header_adj_val_tbl_out        oe_order_pub.header_adj_val_tbl_type;
       x_header_price_att_tbl_out      oe_order_pub.header_price_att_tbl_type;
       x_header_adj_att_tbl_out        oe_order_pub.header_adj_att_tbl_type;
       x_header_adj_assoc_tbl_out      oe_order_pub.header_adj_assoc_tbl_type;
       x_header_scredit_tbl_out        oe_order_pub.header_scredit_tbl_type;
       x_header_scredit_val_tbl_out    oe_order_pub.header_scredit_val_tbl_type;
       x_line_val_tbl_out              oe_order_pub.line_val_tbl_type;
       x_line_adj_tbl_out              oe_order_pub.line_adj_tbl_type;
       x_line_adj_val_tbl_out          oe_order_pub.line_adj_val_tbl_type;
       x_line_price_att_tbl_out        oe_order_pub.line_price_att_tbl_type;
       x_line_adj_att_tbl_out          oe_order_pub.line_adj_att_tbl_type;
       x_line_adj_assoc_tbl_out        oe_order_pub.line_adj_assoc_tbl_type;
       x_line_scredit_tbl_out          oe_order_pub.line_scredit_tbl_type;
       x_line_scredit_val_tbl_out      oe_order_pub.line_scredit_val_tbl_type;
       x_lot_serial_tbl_out            oe_order_pub.lot_serial_tbl_type;
       x_lot_serial_val_tbl_out        oe_order_pub.lot_serial_val_tbl_type;
       x_action_request_tbl_out        oe_order_pub.request_tbl_type;

    BEGIN
       --SELECT user_id INTO x_user_id FROM fnd_user WHERE user_name = 'SBABU';
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Entering the Proc cancel_order_line','XX_OM_ITEM_ORDERABILITY_AME','CANCEL_ORDER_LINE',p_line_id);

       SELECT responsibility_id,
         application_id
       INTO x_resp_id,
         x_appl_id
       FROM fnd_responsibility_vl
       WHERE responsibility_name LIKE 'Order Management Super User'; ---> UNCOMMENTED FRO TESTING TICKET#011319

       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'After Selecting The Resposibility ID','XX_OM_ITEM_ORDERABILITY_AME','CANCEL_ORDER_LINE',p_line_id);
       --fnd_global.apps_initialize (x_user_id, x_resp_id, x_appl_id);
       mo_global.init('ONT');
       fnd_global.apps_initialize (fnd_global.USER_ID,  x_resp_id, x_appl_id);


       xx_intg_common_pkg.get_process_param_value('XXOMAMEITEMORD','LINE_CANCEL_REASON',x_cancel_reason_name);

       BEGIN
          SELECT lookup_code
            INTO x_cancel_reason
        FROM fnd_lookup_values_vl
       WHERE lookup_type = 'CANCEL_CODE'
         AND view_application_id =660
             AND enabled_flag = 'Y'
             AND meaning = x_cancel_reason_name;
       EXCEPTION
         WHEN OTHERS THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Line Cancel Reason is Not Valid. Assigning Default Reason - Adminstrtion Reason','XX_OM_ITEM_ORDERABILITY_AME','CANCEL_ORDER_LINE',p_line_id);
              x_cancel_reason :='1';
       END;

       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Opening Cursor for Line Cancel','XX_OM_ITEM_ORDERABILITY_AME','CANCEL_ORDER_LINE',p_line_id);
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Line Cancellation Comments','XX_OM_ITEM_ORDERABILITY_AME','CANCEL_ORDER_LINE',p_line_id,g_line_cancel_reason);

       FOR i IN c_so_details(p_line_id)
       LOOP
         mo_global.set_policy_context ('S', i.org_id);
         x_line_tbl_in (1)                  := oe_order_pub.g_miss_line_rec;
         x_line_tbl_in (1).line_id          := i.line_id;
         x_line_tbl_in (1).ordered_quantity := 0;
         x_line_tbl_in (1).change_reason    := x_cancel_reason;
         x_line_tbl_in (1).change_comments  := g_line_cancel_reason;
         x_line_tbl_in (1).operation        := oe_globals.g_opr_update;
         --oe_msg_pub.delete_msg;
         oe_order_pub.process_order (p_api_version_number       => x_api_version,
                                     p_init_msg_list            => fnd_api.g_false,
                                     p_return_values            => fnd_api.g_false,
                                     p_action_commit            => fnd_api.g_true,
                                     p_line_tbl                 => x_line_tbl_in,
                                     x_header_rec               => x_header_rec_out,
                                     x_header_val_rec           => x_header_val_rec_out,
                                     x_header_adj_tbl           => x_header_adj_tbl_out,
                                     x_header_adj_val_tbl       => x_header_adj_val_tbl_out,
                                     x_header_price_att_tbl     => x_header_price_att_tbl_out,
                                     x_header_adj_att_tbl       => x_header_adj_att_tbl_out,
                                     x_header_adj_assoc_tbl     => x_header_adj_assoc_tbl_out,
                                     x_header_scredit_tbl       => x_header_scredit_tbl_out,
                                     x_header_scredit_val_tbl   => x_header_scredit_val_tbl_out,
                                     x_line_tbl                 => x_line_tbl_out,
                                     x_line_val_tbl             => x_line_val_tbl_out,
                                     x_line_adj_tbl             => x_line_adj_tbl_out,
                                     x_line_adj_val_tbl         => x_line_adj_val_tbl_out,
                                     x_line_price_att_tbl       => x_line_price_att_tbl_out,
                                     x_line_adj_att_tbl         => x_line_adj_att_tbl_out,
                                     x_line_adj_assoc_tbl       => x_line_adj_assoc_tbl_out,
                                     x_line_scredit_tbl         => x_line_scredit_tbl_out,
                                     x_line_scredit_val_tbl     => x_line_scredit_val_tbl_out,
                                     x_lot_serial_tbl           => x_lot_serial_tbl_out,
                                     x_lot_serial_val_tbl       => x_lot_serial_val_tbl_out,
                                     x_action_request_tbl       => x_action_request_tbl_out,
                                     x_return_status            => x_ret_status,
                                     x_msg_count                => x_l_msg_count,
                                     x_msg_data                 => x_l_msg_data
                                     );
         x_l_msg_data      := NULL;
         IF x_ret_status <> 'S' THEN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Failed to Cancel the Order Line','XX_OM_ITEM_ORDERABILITY_AME','CANCEL_ORDER_LINE',p_line_id);
           FOR iindx     IN 1 .. x_l_msg_count
           LOOP
          x_l_msg_data := x_l_msg_data || '  ' || oe_msg_pub.get (iindx);
         END LOOP;
       /* DBMS_OUTPUT.put_line ( 'Sales Order => '|| i.order_number);
        DBMS_OUTPUT.put_line ( 'Line ID=> ' || i.line_id || ' Line Cancelation Failed');
        DBMS_OUTPUT.put_line ('Return Status: ' || x_ret_status);
        DBMS_OUTPUT.put_line ('Error Message: ' || x_l_msg_data);*/
        RETURN 'E';
      ELSE
        /*DBMS_OUTPUT.put_line ( 'Sales Order => '|| i.order_number);
        DBMS_OUTPUT.put_line ( 'Line ID=> ' || i.line_id || ' Line Cancelled Successfully');
        DBMS_OUTPUT.put_line ('Return Status: ' || x_ret_status);
        DBMS_OUTPUT.put_line ('Error Message: ' || x_l_msg_data);*/
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Successfully Cancelled the Order Line and Completing the Proc','XX_OM_ITEM_ORDERABILITY_AME','CANCEL_ORDER_LINE',p_line_id);
        RETURN 'S';
      END IF;
    END LOOP;
END Cancel_order_line;

--------------------------------------------------------------------------------------------------

    PROCEDURE chk_item_orderability( p_itemType   IN         VARCHAR2
                                    ,p_itemKey    IN         VARCHAR2
                                    ,p_activityId IN         NUMBER
                                    ,funmode      IN         VARCHAR2
                                    ,result       OUT NOCOPY VARCHAR2 )
    AS
       CURSOR c_ord_line_det (p_line_id NUMBER)
       IS
           SELECT hp.party_name cust_name,
                  hca.cust_account_id cust_id,
                  oeol.end_customer_id end_cust,
              hcpc.profile_class_id  cust_class_id,
              (SELECT meaning
                 FROM ar_lookups
                WHERE lookup_type = 'CUSTOMER_CATEGORY'
                  AND lookup_code =hp.category_code) customer_category_code,
              hca.customer_class_code cust_classification_code,
              (SELECT upper(territory_short_name)
                 FROM fnd_territories_tl ftt
                WHERE ftt.territory_code =hl.country
                  AND ftt.language = 'US') cust_region_ctry,
              hl.state cust_region_state,
              hl.city cust_region_city,
              hl.postal_code cust_region_postal_code,
              oeoh.order_type_id,
              oeoh.sales_channel_code,
              oeol.salesrep_id,
              oeol.ship_to_org_id,
              oeol.invoice_to_org_id,
              oeol.deliver_to_org_id,
              hou.name  --- Added for Wave2
         FROM oe_order_headers oeoh,
              oe_order_lines oeol,
              hz_cust_site_uses hcsu ,
              hz_cust_acct_sites hcas ,
              hz_party_sites hps ,
              hz_locations hl ,
              hz_parties hp,
              hz_customer_profiles hcp,
              hz_cust_profile_classes hcpc,
              hz_cust_accounts hca,
              hr_operating_units hou   --- Added for Wave2
        WHERE 1=1
          AND hcsu.site_use_id       = oeoh.ship_to_org_id
          AND hcsu.site_use_code     = 'SHIP_TO'
          AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
          AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id(+)
          AND hcas.party_site_id     = hps.party_site_id(+)
          AND hl.location_id(+)      = hps.location_id
          AND hp.party_id            = hps.party_id
          AND hca.cust_account_id = hcas.cust_account_id
          AND hcp.cust_account_id = hcas.cust_account_id
          AND hcpc.profile_class_id=hcp.profile_class_id
          AND hcpc.status = 'A'
          AND hps.status  = 'A'
          AND hp.status   = 'A'
          AND hcas.status = 'A'
          AND hcsu.status = 'A'
          AND oeol.header_id = oeoh.header_id
          AND oeol.line_id =p_line_id
          --- Added for Wave2
          AND hou.organization_id = oeoh.org_id
          AND EXISTS
                        (SELECT 1
                       FROM xx_emf_process_parameters xpp, xx_emf_process_setup xps
                      WHERE 1 = 1
                        AND xps.process_id = xpp.process_id
                        AND xps.process_name = 'XXOMAMEITEMORD'
                        AND UPPER (parameter_name) LIKE 'INCLUDE_OU_%'
                        AND NVL (xpp.enabled_flag, 'Y') = 'Y'
                            AND NVL (xps.enabled_flag, 'Y') = 'Y'
                            AND parameter_value = hou.name);


       CURSOR c_ord_item_det (p_itemkey NUMBER)
       IS
           SELECT oel.inventory_item_id,ship_from_org_id--,mic.category_id
             FROM oe_order_lines oel--,
                  --mtl_item_categories mic
            WHERE oel.line_id = p_itemkey   ;
--              AND oel.inventory_item_id = mic.inventory_item_id
--              AND oel.ship_from_org_id = mic.organization_id;

       CURSOR c_ord_item_cat (p_item_id           NUMBER,
                              p_item_org          NUMBER,
                              p_category_set_name VARCHAR2)
       IS
      SELECT b.category_id
        FROM mtl_category_sets a,
             mtl_item_categories b,
             mtl_system_items_b c
       WHERE a.category_set_id = b.category_set_id
         AND c.inventory_item_id = b.inventory_item_id
         AND b.organization_id   = c.organization_id
         AND category_set_name   = nvl(p_category_set_name, 'Sales and Marketing')
         AND c.inventory_item_id = p_item_id
         AND c.organization_id   = p_item_org
      UNION
      SELECT b.category_id
        FROM mtl_category_sets a,
             mtl_item_categories b,
             mtl_system_items_b c
       WHERE a.category_set_id = b.category_set_id
         AND c.inventory_item_id = b.inventory_item_id
         AND b.organization_id   = c.organization_id
         AND category_set_name   = nvl(p_category_set_name, 'Sales and Marketing')
         AND c.inventory_item_id = p_item_id
         AND c.organization_id   =
                                  (SELECT organization_id
                                     FROM apps.mtl_parameters
                                    WHERE organization_id = master_organization_id
                                   ) ;

       CURSOR c_line_restrict_code (p_seq         NUMBER,
                                    p_item_id     NUMBER,
                                    p_category_id NUMBER,
                                    p_item_level  VARCHAR2
                                    )
       IS
           SELECT xto.restriction_code
         FROM xxintg_item_orderability xto
        WHERE sequence = p_seq
          AND xto.inventory_item_id = p_item_id
          AND XTO.ITEM_LEVEL = p_item_level
              AND sysdate between NVL(START_DATE,TO_DATE('01-01-1900','DD-MM-YYYY')) and NVL(END_DATE,sysdate+1)
           UNION
           SELECT xto.restriction_code
         FROM xxintg_item_orderability xto,
              mtl_categories_b_kfv mcs
        WHERE sequence = p_seq
          AND UPPER(nvl(xto.cat_seg1,'1'))= UPPER(DECODE(xto.cat_seg1,NULL,'1',mcs.segment4))
          AND UPPER(nvl(xto.cat_seg2,'1'))= UPPER(DECODE(xto.cat_seg2,NULL,'1',mcs.segment10))
          AND UPPER(nvl(xto.cat_seg3,'1'))= UPPER(DECODE(xto.cat_seg3,NULL,'1',mcs.segment7))
          AND UPPER(nvl(xto.cat_seg4,'1'))= UPPER(DECODE(xto.cat_seg4,NULL,'1',mcs.segment8))
          AND UPPER(nvl(xto.cat_seg5,'1'))= UPPER(DECODE(xto.cat_seg5,NULL,'1',mcs.segment9))
          AND UPPER(nvl(xto.cat_seg6,'1'))= UPPER(DECODE(xto.cat_seg6,NULL,'1',mcs.segment6))
          AND MCS.CATEGORY_ID = p_category_id
              AND xto.inventory_item_id is null
          AND XTO.ITEM_LEVEL = p_item_level
              AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1);
-- Cursor to fetch line details of the SO
       CURSOR c_oe_order_lines (p_itemkey NUMBER)
       IS
           SELECT oel.line_id,
                  oel.ship_from_org_id,
                  oel.header_id,
                  oel.order_source_id,
                  oel.inventory_item_id,
                  oel.unit_selling_price,
                  oel.unit_list_price,
                  oel.line_number,
                  oeh.order_number,
                  oel.last_updated_by        -- changed for CR
             FROM oe_order_lines oel,
                  oe_order_headers oeh
            WHERE line_id = p_itemkey
              AND oeh.header_id = oel.header_id;

      CURSOR c_hold_id (
         p_hold_name   VARCHAR2
        -- p_hold_type   VARCHAR2,
        -- p_item_type   VARCHAR2
      )
      IS
         SELECT hold_id
           FROM oe_hold_definitions
          WHERE NAME = p_hold_name
            --AND type_code = p_hold_type
            AND TRUNC (SYSDATE) BETWEEN NVL (start_date_active,
                                             TRUNC (SYSDATE)
                                            )
                                    AND NVL (end_date_active, TRUNC (SYSDATE));
            --AND item_type = p_item_type;
       --- Added for Wave2
       CURSOR c_oe_ou_order_res (p_itemkey NUMBER)
       IS
        SELECT parameter_value
      FROM xx_emf_process_parameters xpp, xx_emf_process_setup xps
     WHERE 1 = 1
       AND xps.process_id = xpp.process_id
       AND xps.process_name = 'XXOMAMEITEMORD'
       AND UPPER (parameter_name) LIKE 'INCLUDE_OU_%'
       AND NVL (xpp.enabled_flag, 'Y') = 'Y'
           AND NVL (xps.enabled_flag, 'Y') = 'Y';

       x_item_ord_res              VARCHAR2(2):='N';
       x_seq_num                   NUMBER;
       x_item_id                   NUMBER;
       x_item_org                  NUMBER;
       x_item_category_id          NUMBER;
       x_restriction_code          VARCHAR2(500);
       x_order_tbl                 oe_holds_pvt.order_tbl_type;
       x_hold_id                   NUMBER;
       x_msg_count                 NUMBER;
       x_msg_data                  VARCHAR2 (100);
       x_hold_name                 VARCHAR2 (500);
       x_return_status             VARCHAR2 (100);
       x_item_level                VARCHAR2(2);
       x_ord_line_det_rec          c_ord_line_det%ROWTYPE;
       x_category_set_name         VARCHAR2 (30);
       x_rule_count                NUMBER;

    BEGIN
       IF funmode = 'RUN'
       THEN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Entering The Proc chk_item_orderability','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey);
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Opening The Cursor c_ord_item_det to Fecth Line Item ID and Org ID','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey);
           OPEN c_ord_item_det(to_number(p_itemKey));
          FETCH c_ord_item_det
           INTO x_item_id,x_item_org;--,x_item_category_id;
          CLOSE c_ord_item_det;
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Item ID and Org ID Value -','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey,x_item_id,x_item_org);

           xx_intg_common_pkg.get_process_param_value('XXOMAMEITEMORD','CATEGORY_SET_NAME',x_category_set_name);

           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Opening The Cursor c_ord_item_cat to Fecth Category ID of the Line Item ID ','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey);
           OPEN c_ord_item_cat(x_item_id,x_item_org,x_category_set_name);
          FETCH c_ord_item_cat
           INTO x_item_category_id;
           IF c_ord_item_cat%NOTFOUND
           THEN
              x_item_category_id:=NULL;
           END IF;
          CLOSE c_ord_item_cat;
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Item Category ID Value -','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey,x_item_category_id);

          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Opening The Cursor c_ord_line_det to Fecth the Line Details ','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey);
           OPEN c_ord_line_det(to_number(p_itemKey));
          FETCH c_ord_line_det
           INTO x_ord_line_det_rec;

           IF c_ord_line_det%NOTFOUND
           THEN
              result := 'COMPLETE:N';
              return;
           END IF;

          CLOSE c_ord_line_det;

          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Calling the Proc ORDERABILITY_CHECK ','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey,x_item_id,x_item_category_id);
          orderability_check( p_item_id            => x_item_id
                             ,p_category_id        => x_item_category_id
                             ,p_customer_id        => x_ord_line_det_rec.cust_id
                             ,p_end_customer_id    => x_ord_line_det_rec.end_cust
                             ,p_customer_class_id  => x_ord_line_det_rec.cust_class_id
                             ,p_cust_category_code => x_ord_line_det_rec.customer_category_code
                             ,p_cust_classif_code  => x_ord_line_det_rec.cust_classification_code
                             ,p_cust_region_ctry   => x_ord_line_det_rec.cust_region_ctry
                             ,p_cust_region_state  => x_ord_line_det_rec.cust_region_state
                             ,p_cust_region_city   => x_ord_line_det_rec.cust_region_city
                             ,p_cust_region_postal => x_ord_line_det_rec.cust_region_postal_code
                             ,p_order_type_id      => x_ord_line_det_rec.order_type_id
                             ,p_sales_channel_code => x_ord_line_det_rec.sales_channel_code
                             ,p_salesrep_id        => x_ord_line_det_rec.salesrep_id
                             ,p_ship_to_org_id     => x_ord_line_det_rec.ship_to_org_id
                             ,p_bill_to_org_id     => x_ord_line_det_rec.invoice_to_org_id
                             ,p_deliver_to_org_id  => x_ord_line_det_rec.deliver_to_org_id
                             ,p_orderability_flag  => x_item_ord_res
                             ,p_seq_no             => x_seq_num
                             ,p_item_level         => x_item_level
                          );

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'The Seq No, Orderability Flag and Item Level Values Returned from Proc ORDERABILITY_CHECK ','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey,x_seq_num,x_item_ord_res,x_item_level);

          IF x_item_ord_res = 'Y'
          THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Checking For Any Conflicting Restriction Rules:','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey,x_seq_num,x_item_ord_res,x_item_level);
            IF x_item_level = 'C'
            THEN
               SELECT count(1)
                 INTO x_rule_count
             FROM xxintg_item_orderability xto,
                  mtl_categories_b_kfv mcs
            WHERE sequence = x_seq_num
              AND UPPER(nvl(xto.cat_seg1,'1'))= UPPER(DECODE(xto.cat_seg1,NULL,'1',mcs.segment4))
              AND UPPER(nvl(xto.cat_seg2,'1'))= UPPER(DECODE(xto.cat_seg2,NULL,'1',mcs.segment10))
              AND UPPER(nvl(xto.cat_seg3,'1'))= UPPER(DECODE(xto.cat_seg3,NULL,'1',mcs.segment7))
              AND UPPER(nvl(xto.cat_seg4,'1'))= UPPER(DECODE(xto.cat_seg4,NULL,'1',mcs.segment8))
              AND UPPER(nvl(xto.cat_seg5,'1'))= UPPER(DECODE(xto.cat_seg5,NULL,'1',mcs.segment9))
              AND UPPER(nvl(xto.cat_seg6,'1'))= UPPER(DECODE(xto.cat_seg6,NULL,'1',mcs.segment6))
              AND mcs.category_id = x_item_category_id
              AND xto.item_level = x_item_level
                  AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1);

            ELSIF x_item_level = 'I'
               THEN
               SELECT count(1)
                 INTO x_rule_count
             FROM xxintg_item_orderability xto
            WHERE sequence = x_seq_num
              AND xto.inventory_item_id =x_item_id
              AND xto.item_level = x_item_level
                  AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1);
            END IF;

            IF x_rule_count > 1
            THEN
               g_line_cancel_reason:= 'Line Cancelled Due to Conflicting Rules Defined';
               result := 'COMPLETE:C';
               return;
            END IF;

              OPEN c_line_restrict_code(x_seq_num,x_item_id,x_item_category_id,x_item_level);
             FETCH c_line_restrict_code
              INTO x_restriction_code;
             CLOSE c_line_restrict_code;

             xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'The Restriction Code -','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey,x_restriction_code);

             IF x_restriction_code = 'NO_RES'
             THEN
                result := 'COMPLETE:N';
                return;
             END IF;

             IF x_restriction_code = 'NO_SALE'
             THEN
                IF x_item_level= 'I'
                THEN
                  BEGIN
                     SELECT 'Sequence:'
                  ||Sequence
                  ||' Restriction_Level:Item'
                  ||' Rule_Level:'
                  ||rule_level
             INTO g_line_cancel_reason
             FROM xxintg_item_orderability
            WHERE sequence = x_seq_num
              AND item_level = x_item_level
                      AND inventory_item_id = x_item_id
                      AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1);
                  EXCEPTION
                       WHEN OTHERS THEN
                       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Error in Setting the Line Cancel Comment string- Setting it to default Value','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey);
                       g_line_cancel_reason := 'Line Cancel With Reference to the Orderabilirty Restriction Rule';
                  END;
                ELSE
                  BEGIN
                     SELECT 'Sequence:'
                  ||Sequence
                  ||' Restriction_Level:Category'
                  ||' Rule_Level:'
                  ||rule_level
                  ||' Cancatenated Segemnts:'
                  || xto.cat_seg1
                  || '.'
                  || xto.cat_seg2
                  || '.'
                  || xto.cat_seg3
                  || '.'
                  || xto.cat_seg4
                  || '.'
                  || xto.cat_seg5
                  || '.'
                  || xto.cat_seg6
             INTO g_line_cancel_reason
             FROM xxintg_item_orderability xto,
                  mtl_categories_b_kfv mcs
            WHERE xto.sequence = x_seq_num
              AND xto.item_level = x_item_level
                      AND mcs.category_id=x_item_category_id
                      AND UPPER(nvl(xto.cat_seg1,'1'))= UPPER(DECODE(xto.cat_seg1,NULL,'1',mcs.segment4))
                      AND UPPER(nvl(xto.cat_seg2,'1'))= UPPER(DECODE(xto.cat_seg2,NULL,'1',mcs.segment10))
                      AND UPPER(nvl(xto.cat_seg3,'1'))= UPPER(DECODE(xto.cat_seg3,NULL,'1',mcs.segment7))
                      AND UPPER(nvl(xto.cat_seg4,'1'))= UPPER(DECODE(xto.cat_seg4,NULL,'1',mcs.segment8))
                      AND UPPER(nvl(xto.cat_seg5,'1'))= UPPER(DECODE(xto.cat_seg5,NULL,'1',mcs.segment9))
                      AND UPPER(nvl(xto.cat_seg6,'1'))= UPPER(DECODE(xto.cat_seg6,NULL,'1',mcs.segment6))
                      AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
                      AND rownum = 1;
                  EXCEPTION
                       WHEN OTHERS THEN
                       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Error in Setting the Line Cancel Comment string- Setting it to default Value','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey);
                       g_line_cancel_reason := 'Line Cancel With Reference to the Orderabilirty Restriction Rule';
                  END;
                END IF;
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'The Cancelation Reson Set to','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey,g_line_cancel_reason);
                result := 'COMPLETE:C';
                return;
             END IF;

             xx_intg_common_pkg.get_process_param_value('XXOMAMEITEMORD',x_restriction_code,x_hold_name);

             xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Fetching The Hold Name from EMF Process Setup and For Loop to Put Order Line On HoldLine ','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey,x_hold_name);

             FOR rec_oe_order_lines IN c_oe_order_lines (TO_NUMBER (p_itemKey))
             LOOP
                x_order_tbl (1).header_id := rec_oe_order_lines.header_id;
                x_order_tbl (1).line_id := rec_oe_order_lines.line_id;
               -- x_price_adjustment_id := NULL;
                --x_user_id := rec_oe_order_lines.last_updated_by;

              /*BEGIN
                   SELECT user_name
                     INTO x_user_name
                     FROM fnd_user
                    WHERE user_id = x_user_id;
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      x_user_name := NULL;
                END;*/
                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Opening Cursor to Fetch The Hold Name ID','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey,x_hold_name);
                    OPEN c_hold_id (x_hold_name);
                   FETCH c_hold_id
                    INTO x_hold_id;
                    IF c_hold_id%NOTFOUND
                    THEN
                       result := 'COMPLETE:N';
                       return;
                    END IF;
                   CLOSE c_hold_id;

                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'API TO Place the Order Line On Hold','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey,x_hold_id);
                IF x_hold_id IS NOT NULL
                THEN
                   oe_holds_pub.apply_holds
                            (p_api_version                   => 1.0,
                             p_init_msg_list                 => fnd_api.g_true,
                             p_commit                        => fnd_api.g_false,
                             p_validation_level              => fnd_api.g_valid_level_full,
                             p_order_tbl                     => x_order_tbl,
                             p_hold_id                       => x_hold_id,
                             p_hold_until_date               => NULL,
                             p_hold_comment                  => NULL,
                             p_check_authorization_flag      => NULL,
                             x_return_status                 => x_return_status,
                             x_msg_count                     => x_msg_count,
                             x_msg_data                      => x_msg_data
                            );

                   wf_engine.setItemAttrText ( itemtype => p_itemType
                                              ,itemkey  => p_itemKey
                                              ,aname    => 'XXOM_ITEM_ORD_HOLD_FLAG'
                                              ,avalue   => 'Y' );
                   wf_engine.setItemAttrText ( itemtype => p_itemType
                                              ,itemkey  => p_itemKey
                                              ,aname    => 'XXOM_ITM_ORD_HOLD_NAME'
                                              ,avalue   => x_hold_name );
                END IF;
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Applied The Hold on The Order Line','XX_OM_ITEM_ORDERABILITY_AME','CHK_ITEM_ORDERABILITY',p_itemKey,x_hold_name);
                result := 'COMPLETE:Y';
             END LOOP;
          ELSE
            result := 'COMPLETE:N';
            return;
          END IF;
       ELSE
            result := 'COMPLETE:N';
            return;
       END IF;
    END chk_item_orderability;


--------------------------------------------------------------------------------------------------

   PROCEDURE ame_nxt_appr (
                            itemtype    IN              VARCHAR2,
                            itemkey     IN              VARCHAR2,
                            actid       IN              NUMBER,
                            funcmode    IN              VARCHAR2,
                            resultout   IN OUT NOCOPY   VARCHAR2
                          )
   IS
       x_chr_item_key              VARCHAR2 (200);
       x_chr_apprvl_out_put        VARCHAR2 (100);
       x_next_approver             ame_util.approverstable2;
       x_chr_approver_id           VARCHAR2 (10);
       x_chr_appr_name             VARCHAR2 (50);
       x_item_index                ame_util.idlist;
       x_item_class                ame_util.stringlist;
       x_item_id                   ame_util.stringlist;
       x_item_source               ame_util.longstringlist;
       x_ame_show_msg_flag         VARCHAR2(5);
       x_common_msg_body           VARCHAR2(3000);
       x_common_msg_sub            VARCHAR2(1000);
       x_order_number              NUMBER;
       x_rma_value                 NUMBER;
       x_effective_days            NUMBER;
       x_escalation_days           NUMBER;
   BEGIN
          /* x_order_number:= wf_engine.getitemattrnumber ( itemtype => itemtype
                                                     ,itemkey  => itemkey
                                                     ,aname    => 'XX_OM_ORD_NUM'
                                                        );      */
           IF funcmode = 'RUN'
           THEN
             -- BEGIN
                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Entering The Proc ame_nxt_appr','XX_OM_ITEM_ORDERABILITY_AME','AME_NXT_APPR',itemtype);
                 xx_intg_common_pkg.get_process_param_value('XXOMAMEITEMORD','G_TRANSACTION_TYPE_NAME',g_chr_transaction_type);

              --
              -- Getting next approver using AME_API2.GETNEXTAPPROVERS1 procedure
              --
                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Calling API to Fetch Next AME Approver for the AME TRX','XX_OM_ITEM_ORDERABILITY_AME','AME_NXT_APPR',itemtype,g_chr_transaction_type);
                 AME_API2.GETNEXTAPPROVERS1( applicationidin                =>    660 --Order Management APP ID
                                            ,transactiontypein              =>    g_chr_transaction_type --short name of AME Trans
                                            ,transactionidin                =>    itemKey --l_chr_item_key  --unique ID that can be passed to AME
                                            ,flagapproversasnotifiedin      =>    ame_util.booleantrue
                                            ,approvalprocesscompleteynout   =>    x_chr_apprvl_out_put
                                            ,nextapproversout               =>    x_next_approver
                                            ,itemindexesout                 =>    x_item_index
                                            ,itemidsout                     =>    x_item_id
                                            ,itemclassesout                 =>    x_item_class
                                            ,itemsourcesout                 =>    x_item_source
                                            );

                 IF x_chr_apprvl_out_put = 'N' then
                    IF x_next_approver.COUNT > 0
                    THEN
                       x_chr_approver_id := x_next_approver (1).orig_system_id;
                       x_chr_appr_name := x_next_approver (1).NAME;

                       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Next AME Approver ','XX_OM_ITEM_ORDERABILITY_AME','AME_NXT_APPR',itemtype,x_chr_appr_name);

                       wf_engine.setItemAttrText ( itemtype => itemType
                                                  ,itemkey  => itemKey
                                                  ,aname    => 'INTG_APP_NAME'
                                                  ,avalue   => x_chr_appr_name );

                       --xx_intg_common_pkg.get_process_param_value('XXOMPRICEOVERRIDEEXT','ESCALATION_DAYS',x_escalation_days);
                       --x_effective_days:=xx_om_return_ord_ame.calc_timeout_days(nvl(x_escalation_days,1));

                       /*wf_engine.setItemAttrnumber ( itemtype => itemType
                                                    ,itemkey  => itemKey
                                                    ,aname    => 'INTG_TIMEOUT_DAYS'
                                                    ,avalue   => x_effective_days ); */

                             resultout := 'APPROVAL';
                             RETURN;
                       END IF;

                    ELSE
                       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'No AME Approver Fetched for Trx At this Fetch: ','XX_OM_ITEM_ORDERABILITY_AME','AME_NXT_APPR',itemtype);
                       resultout := 'NO_APPROVER';
                       RETURN;
                    END IF;
                 ELSE
                    resultout := 'NO_APPROVER';
                    RETURN;
                 END IF;

   END ame_nxt_appr;
--------------------------------------------------------------------------------------------------

    PROCEDURE upd_appr_status( p_itemType   IN         VARCHAR2
                              ,p_itemKey    IN         VARCHAR2
                              ,p_activityId IN         NUMBER
                              ,funmode      IN         VARCHAR2
                              ,result       OUT NOCOPY VARCHAR2 )
    AS
       x_chr_approver_name         VARCHAR(100);
       x_order_number              NUMBER;
      -- x_rma_value                 NUMBER;
       x_common_msg_body           VARCHAR2(3000);
       x_common_msg_sub            VARCHAR2(1000);

   BEGIN

     IF funmode = 'RUN'
       THEN
       --g_num_err_loc_code := '00002';
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Entering The Proc upd_appr_status','XX_OM_ITEM_ORDERABILITY_AME','UPD_APPR_STATUS',p_itemKey);
       x_order_number:= wf_engine.getitemattrnumber ( itemtype => p_itemType
                                                   ,itemkey  => p_itemKey
                                                   ,aname    => 'XX_OM_ORD_NUM'
                                                    );
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Order Fetched from The WF Attribute XX_OM_ORD_NUM:','XX_OM_ITEM_ORDERABILITY_AME','UPD_APPR_STATUS',p_itemKey,x_order_number);

       x_chr_approver_name:=wf_engine.getItemAttrText ( itemtype => p_itemType
                                                       ,itemkey  => p_itemKey
                                                       ,aname    => 'INTG_APP_NAME'
                                                      );

       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Approver Name Fetched from The WF Attribute INTG_APP_NAME:','XX_OM_ITEM_ORDERABILITY_AME','UPD_APPR_STATUS',p_itemKey,x_chr_approver_name);

        xx_intg_common_pkg.get_process_param_value('XXOMAMEITEMORD','G_TRANSACTION_TYPE_NAME',g_chr_transaction_type);

       AME_API2.UPDATEAPPROVALSTATUS2( applicationidin        => 660
                                      ,transactiontypein      => g_chr_transaction_type--'RMAA',
                                      ,transactionidin        => p_itemKey
                                      ,approvalstatusin       => ame_util.approvedstatus
                                      ,approvernamein         => x_chr_approver_name
                                     );
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'AME Approval Updated for The TRX','XX_OM_ITEM_ORDERABILITY_AME','UPD_APPR_STATUS',p_itemKey,x_chr_approver_name);
       result := 'Y';
     END IF;

     IF (funmode = 'CANCEL')
      THEN
         result := 'N';
         RETURN;
     END IF;


    EXCEPTION
          WHEN OTHERS THEN
             result := 'N';
             WF_CORE.CONTEXT (pkg_name       => 'XX_OM_ITEM_ORDERABILITY_AME',
                              proc_name      => 'UPD_APPR_STATUS',
                              arg1           => SUBSTR (SQLERRM, 1, 80),
                              arg2           => p_itemType,
                              arg3           => p_itemKey,
                              arg4           => TO_CHAR (p_activityId),
                              arg5           => funmode,
                              arg6           => 'error location:'||'000800');
             RAISE;
    END upd_appr_status;

--------------------------------------------------------------------------------------------------

    PROCEDURE upd_rejected_status( p_itemType   IN         VARCHAR2
                                  ,p_itemKey    IN         VARCHAR2
                                  ,p_activityId IN         NUMBER
                                  ,funmode      IN         VARCHAR2
                                  ,result       OUT NOCOPY VARCHAR2 )
     AS
       x_chr_approver_name         VARCHAR(100);
       x_order_number              NUMBER;
       --x_rma_value                 NUMBER;
       x_common_msg_body           VARCHAR2(3000);
       x_common_msg_sub            VARCHAR2(1000);

     BEGIN

        IF funmode = 'RUN'
        THEN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Entering The Proc upd_rejected_status','XX_OM_ITEM_ORDERABILITY_AME','UPD_REJECTED_STATUS',p_itemKey);
           x_order_number:= wf_engine.getitemattrnumber ( itemtype => p_itemType
                                                     ,itemkey  => p_itemKey
                                                     ,aname    => 'XX_OM_ORD_NUM'
                                                        );

           --g_num_err_loc_code := '00003';
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Order Fetched from The WF Attribute XX_OM_ORD_NUM:','XX_OM_ITEM_ORDERABILITY_AME','UPD_REJECTED_STATUS',p_itemKey,x_order_number);

           x_chr_approver_name:=wf_engine.getItemAttrText ( itemtype => p_itemType
                                                           ,itemkey  => p_itemKey
                                                           ,aname    => 'INTG_APP_NAME'
                                                          );

           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Approver Name Fetched from The WF Attribute INTG_APP_NAME:','XX_OM_ITEM_ORDERABILITY_AME','UPD_REJECTED_STATUS',p_itemKey,x_chr_approver_name);

           xx_intg_common_pkg.get_process_param_value('XXOMAMEITEMORD','G_TRANSACTION_TYPE_NAME',g_chr_transaction_type);

           AME_API2.UPDATEAPPROVALSTATUS2( applicationidin        => 660
                                          ,transactiontypein      => g_chr_transaction_type
                                          ,transactionidin        => p_itemKey
                                          ,approvalstatusin       => ame_util.rejectstatus
                                          ,approvernamein         => x_chr_approver_name
                                         );
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'AME Rejection Updated for The TRX','XX_OM_ITEM_ORDERABILITY_AME','UPD_APPR_STATUS',p_itemKey,x_chr_approver_name);
           result := 'Y';

        END IF;

        IF funmode = 'CANCEL'
        THEN
           result := 'N';
           RETURN;
        END IF;

    EXCEPTION
         WHEN OTHERS THEN
            result := 'N';
            WF_CORE.CONTEXT (pkg_name       => 'XX_OM_ITEM_ORDERABILITY_AME',
                             proc_name      => 'UPD_REJECTED_STATUS',
                             arg1           => SUBSTR (SQLERRM, 1, 80),
                             arg2           => p_itemType,
                             arg3           => p_itemKey,
                             arg4           => TO_CHAR (p_activityId),
                             arg5           => funmode,
                             arg6           => 'error location:'||'000900');
            RAISE;
    END upd_rejected_status;
--------------------------------------------------------------------------------------------------

    PROCEDURE clear_all_approvals( p_itemType   IN         VARCHAR2
                                  ,p_itemKey    IN         VARCHAR2
                                  ,p_activityId IN         NUMBER
                                  ,funmode      IN         VARCHAR2
                                  ,result       OUT NOCOPY VARCHAR2 )
    AS
            x_escalation_days           NUMBER;
            x_effective_days            NUMBER;
    BEGIN

       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Entering The Proc clear_all_approvals','XX_OM_ITEM_ORDERABILITY_AME','CLEAR_ALL_APPROVALS',p_itemKey);
       xx_intg_common_pkg.get_process_param_value('XXOMAMEITEMORD','G_TRANSACTION_TYPE_NAME',g_chr_transaction_type);

       --xx_intg_common_pkg.get_process_param_value('XXOMPRICEOVERRIDEEXT','ESCALATION_DAYS',x_escalation_days);
       --x_effective_days:=xx_om_return_ord_ame.calc_timeout_days(x_escalation_days);
      /*wf_engine.setItemAttrnumber ( itemtype => p_itemType
                                   ,itemkey  => p_itemKey
                                   ,aname    => 'INTG_TIMEOUT_DAYS'
                                   ,avalue   => x_effective_days );    */

       AME_API2.clearAllApprovals(applicationIdIn   => 660,
                                  transactionTypeIn => g_chr_transaction_type,
                                  transactionIdIn   => p_itemKey);
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Clear All AME Approval history for the TRX','XX_OM_ITEM_ORDERABILITY_AME','CLEAR_ALL_APPROVALS',p_itemKey);
    EXCEPTION
         WHEN OTHERS THEN
            result := 'N';
            WF_CORE.CONTEXT (pkg_name       => 'XX_OM_ITEM_ORDERABILITY_AME',
                             proc_name      => 'CLEAR_ALL_APPROVALS',
                             arg1           => SUBSTR (SQLERRM, 1, 80),
                             arg2           => p_itemType,
                             arg3           => p_itemKey,
                             arg4           => TO_CHAR (p_activityId),
                             arg5           => funmode,
                             arg6           => 'error location:'||'0001000');
            RAISE;

    END clear_all_approvals;

--------------------------------------------------------------------------------------------------
    PROCEDURE order_line_Cacellation( p_itemType   IN         VARCHAR2
                                     ,p_itemKey    IN         VARCHAR2
                                     ,p_activityId IN         NUMBER
                                     ,funmode      IN         VARCHAR2
                                     ,result       OUT NOCOPY VARCHAR2
                                    )
    AS
       x_ret_status              VARCHAR2(20);
    BEGIN
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Entering The Proc order_line_Cacellation','XX_OM_ITEM_ORDERABILITY_AME','ORDER_LINE_CACELLATION',p_itemKey);

    x_ret_status:=cancel_order_line(to_number(p_itemKey));

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Aftering Calling The Proc order_line_Cacellation Return Status ','XX_OM_ITEM_ORDERABILITY_AME','ORDER_LINE_CACELLATION',p_itemKey,x_ret_status);

    END order_line_Cacellation;
--------------------------------------------------------------------------------------------------
    PROCEDURE orderability_check( p_item_id            IN         NUMBER
                                 ,p_category_id        IN         NUMBER
                                 ,p_customer_id        IN         NUMBER   -- PARTY_ID
                                 ,p_end_customer_id    IN         NUMBER   -- PARTY_ID
                                 ,p_customer_class_id  IN         NUMBER
                                 ,p_cust_category_code IN         VARCHAR2
                                 ,p_cust_classif_code  IN         VARCHAR2
                                 ,p_cust_region_ctry   IN         VARCHAR2
                 ,p_cust_region_state  IN         VARCHAR2
                 ,p_cust_region_city   IN         VARCHAR2
                                 ,p_cust_region_postal IN         VARCHAR2
                                 ,p_order_type_id      IN         NUMBER
                                 ,p_sales_channel_code IN         VARCHAR2
                                 ,p_salesrep_id        IN         VARCHAR2
                                 ,p_ship_to_org_id     IN         VARCHAR2
                                 ,p_bill_to_org_id     IN         VARCHAR2
                                 ,p_deliver_to_org_id  IN         VARCHAR2
                                 ,p_orderability_flag  OUT        VARCHAR2
                                 ,p_seq_no             OUT        NUMBER
                                 ,p_item_level         OUT        VARCHAR2
                                )
    AS
       CURSOR c_ord_res ( cp_item_id              NUMBER
                         ,cp_category_id          NUMBER
                         ,cp_customer_id          NUMBER
                         ,cp_end_customer_id      NUMBER
                         ,cp_customer_class_id    NUMBER
                         ,cp_cust_category_code   VARCHAR2
                         ,cp_cust_classif_code    VARCHAR2
                         ,cp_cust_region_ctry     VARCHAR2
                         ,cp_cust_region_state    VARCHAR2
                         ,cp_cust_region_city     VARCHAR2
                         ,cp_cust_region_postal   VARCHAR2
                         ,cp_order_type_id        NUMBER
                         ,cp_sales_channel_code   VARCHAR2
                         ,cp_salesrep_id          NUMBER
                         ,cp_ship_to_org_id       NUMBER
                         ,cp_bill_to_org_id       NUMBER
                         ,cp_deliver_to_org_id    NUMBER
                         )
       IS
       SELECT sequence,item_level
         FROM xxintg_item_orderability
        WHERE item_level = 'I'
          AND inventory_item_id = cp_item_id
          AND rule_level = 'CUSTOMER'
          AND customer_id = cp_customer_id
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability
        WHERE item_level = 'I'
          AND inventory_item_id = cp_item_id
          AND rule_level = 'END_CUST'
          AND end_customer_id = cp_end_customer_id
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability
        WHERE item_level = 'I'
          AND inventory_item_id = cp_item_id
          AND rule_level = 'CUST_CLASS'
          AND customer_class_id = cp_customer_class_id
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability
        WHERE item_level = 'I'
          AND inventory_item_id = cp_item_id
          AND rule_level = 'CUST_CATEGORY'
          AND customer_category_code = cp_cust_category_code
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability
        WHERE item_level = 'I'
          AND inventory_item_id = cp_item_id
          AND rule_level = 'CUST_CLASSIF'
          AND customer_class_code = cp_cust_classif_code
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
      /*
       SELECT sequence,item_level
         FROM xxintg_item_orderability xio,
              wsh_regions_v wrv
        WHERE item_level = 'I'
          AND inventory_item_id = cp_item_id
          AND rule_level = 'REGIONS'
          AND xio.region_id = wrv.region_id
          AND upper(wrv.country)= cp_cust_region
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)  */
       SELECT sequence,item_level
         FROM xxintg_item_orderability xio,
              wsh_regions_v wrv
        WHERE item_level = 'I'
          AND inventory_item_id = cp_item_id
          AND rule_level = 'REGIONS'
          AND xio.region_id = wrv.region_id
          AND wrv.zone is null
          AND UPPER(nvl(wrv.country,'1'))= UPPER(DECODE(wrv.country,null,'1',cp_cust_region_ctry))--CP_CUST_REGION
          AND UPPER(nvl(wrv.state,'1'))= UPPER(DECODE(wrv.state,null,'1',cp_cust_region_state))
          AND UPPER(nvl(wrv.city,'1'))= UPPER(DECODE(wrv.city,null,'1',cp_cust_region_city))
          AND UPPER(nvl(postal_code_from||postal_code_to,'1'))= UPPER(DECODE((postal_code_from||postal_code_to),null,'1',cp_cust_region_postal))
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability xio,
              wsh_regions_v wrv,
              wsh_zone_regions_v wzr
        WHERE item_level = 'I'
          AND inventory_item_id = cp_item_id
          AND rule_level = 'REGIONS'
          AND xio.region_id = wrv.region_id
          AND wrv.zone is not null
          AND wzr.zone_id = wrv.region_id
          AND xio.region_id =wzr.zone_id
          AND UPPER(nvl(wzr.country,'1'))= UPPER(DECODE(wzr.country,null,'1',cp_cust_region_ctry))--CP_CUST_REGION
          AND UPPER(nvl(wzr.state,'1'))= UPPER(DECODE(wzr.state,null,'1',cp_cust_region_state))
          AND UPPER(nvl(wzr.city,'1'))= UPPER(decode(wzr.city,null,'1',cp_cust_region_city))
          AND UPPER(nvl(wzr.postal_code_from||wzr.postal_code_to,'1'))= UPPER(decode((wzr.postal_code_from||wzr.postal_code_to),null,'1',cp_cust_region_postal))
          AND SYSDATE BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability
        WHERE item_level = 'I'
          AND inventory_item_id = cp_item_id
          AND rule_level = 'ORDER_TYPE'
          AND order_type_id = cp_order_type_id
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability
        WHERE item_level = 'I'
          AND inventory_item_id = cp_item_id
          AND rule_level = 'SALES_CHANNEL'
          AND sales_channel_code = cp_sales_channel_code
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability
        WHERE item_level = 'I'
          AND inventory_item_id = cp_item_id
          AND rule_level = 'SALES_REP'
          AND sales_person_id = cp_salesrep_id
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability
        WHERE item_level = 'I'
          AND inventory_item_id = cp_item_id
          AND rule_level = 'SHIP_TO_LOC'
          AND ship_to_location_id = cp_ship_to_org_id
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability
        WHERE item_level = 'I'
          AND inventory_item_id = cp_item_id
          AND rule_level = 'BILL_TO_LOC'
          AND bill_to_location_id = cp_bill_to_org_id
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability
        WHERE item_level = 'I'
          AND inventory_item_id = cp_item_id
          AND rule_level = 'DELIVER_TO_LOC'
          AND bill_to_location_id = cp_deliver_to_org_id
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability xto,
          mtl_categories_b_kfv mcs
    WHERE xto.item_level = 'C'
          AND mcs.category_id = cp_category_id
          AND UPPER(nvl(xto.cat_seg1,'1'))= UPPER(DECODE(xto.cat_seg1,NULL,'1',mcs.segment4))
          AND UPPER(nvl(xto.cat_seg2,'1'))= UPPER(DECODE(xto.cat_seg2,NULL,'1',mcs.segment10))
          AND UPPER(nvl(xto.cat_seg3,'1'))= UPPER(DECODE(xto.cat_seg3,NULL,'1',mcs.segment7))
          AND UPPER(nvl(xto.cat_seg4,'1'))= UPPER(DECODE(xto.cat_seg4,NULL,'1',mcs.segment8))
          AND UPPER(nvl(xto.cat_seg5,'1'))= UPPER(DECODE(xto.cat_seg5,NULL,'1',mcs.segment9))
          AND UPPER(nvl(xto.cat_seg6,'1'))= UPPER(DECODE(xto.cat_seg6,NULL,'1',mcs.segment6))
          AND rule_level = 'CUSTOMER'
          AND customer_id = cp_customer_id
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability xto,
          mtl_categories_b_kfv mcs
    WHERE xto.item_level = 'C'
          AND mcs.category_id = cp_category_id
          AND UPPER(nvl(xto.cat_seg1,'1'))= UPPER(DECODE(xto.cat_seg1,NULL,'1',mcs.segment4))
          AND UPPER(nvl(xto.cat_seg2,'1'))= UPPER(DECODE(xto.cat_seg2,NULL,'1',mcs.segment10))
          AND UPPER(nvl(xto.cat_seg3,'1'))= UPPER(DECODE(xto.cat_seg3,NULL,'1',mcs.segment7))
          AND UPPER(nvl(xto.cat_seg4,'1'))= UPPER(DECODE(xto.cat_seg4,NULL,'1',mcs.segment8))
          AND UPPER(nvl(xto.cat_seg5,'1'))= UPPER(DECODE(xto.cat_seg5,NULL,'1',mcs.segment9))
          AND UPPER(nvl(xto.cat_seg6,'1'))= UPPER(DECODE(xto.cat_seg6,NULL,'1',mcs.segment6))
          AND rule_level = 'END_CUST'
          AND end_customer_id = cp_end_customer_id
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability xto,
          mtl_categories_b_kfv mcs
    WHERE xto.item_level = 'C'
          AND mcs.category_id = cp_category_id
          AND UPPER(nvl(xto.cat_seg1,'1'))= UPPER(DECODE(xto.cat_seg1,NULL,'1',mcs.segment4))
          AND UPPER(nvl(xto.cat_seg2,'1'))= UPPER(DECODE(xto.cat_seg2,NULL,'1',mcs.segment10))
          AND UPPER(nvl(xto.cat_seg3,'1'))= UPPER(DECODE(xto.cat_seg3,NULL,'1',mcs.segment7))
          AND UPPER(nvl(xto.cat_seg4,'1'))= UPPER(DECODE(xto.cat_seg4,NULL,'1',mcs.segment8))
          AND UPPER(nvl(xto.cat_seg5,'1'))= UPPER(DECODE(xto.cat_seg5,NULL,'1',mcs.segment9))
          AND UPPER(nvl(xto.cat_seg6,'1'))= UPPER(DECODE(xto.cat_seg6,NULL,'1',mcs.segment6))
          AND rule_level = 'CUST_CLASS'
          AND customer_class_id = cp_customer_class_id
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability xto,
          mtl_categories_b_kfv mcs
    WHERE xto.item_level = 'C'
          AND mcs.category_id = cp_category_id
          AND UPPER(nvl(xto.cat_seg1,'1'))= UPPER(DECODE(xto.cat_seg1,NULL,'1',mcs.segment4))
          AND UPPER(nvl(xto.cat_seg2,'1'))= UPPER(DECODE(xto.cat_seg2,NULL,'1',mcs.segment10))
          AND UPPER(nvl(xto.cat_seg3,'1'))= UPPER(DECODE(xto.cat_seg3,NULL,'1',mcs.segment7))
          AND UPPER(nvl(xto.cat_seg4,'1'))= UPPER(DECODE(xto.cat_seg4,NULL,'1',mcs.segment8))
          AND UPPER(nvl(xto.cat_seg5,'1'))= UPPER(DECODE(xto.cat_seg5,NULL,'1',mcs.segment9))
          AND UPPER(nvl(xto.cat_seg6,'1'))= UPPER(DECODE(xto.cat_seg6,NULL,'1',mcs.segment6))
          AND rule_level = 'CUST_CATEGORY'
          AND customer_category_code = cp_cust_category_code
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability xto,
          mtl_categories_b_kfv mcs
    WHERE xto.item_level = 'C'
          AND mcs.category_id = cp_category_id
          AND UPPER(nvl(xto.cat_seg1,'1'))= UPPER(DECODE(xto.cat_seg1,NULL,'1',mcs.segment4))
          AND UPPER(nvl(xto.cat_seg2,'1'))= UPPER(DECODE(xto.cat_seg2,NULL,'1',mcs.segment10))
          AND UPPER(nvl(xto.cat_seg3,'1'))= UPPER(DECODE(xto.cat_seg3,NULL,'1',mcs.segment7))
          AND UPPER(nvl(xto.cat_seg4,'1'))= UPPER(DECODE(xto.cat_seg4,NULL,'1',mcs.segment8))
          AND UPPER(nvl(xto.cat_seg5,'1'))= UPPER(DECODE(xto.cat_seg5,NULL,'1',mcs.segment9))
          AND UPPER(nvl(xto.cat_seg6,'1'))= UPPER(DECODE(xto.cat_seg6,NULL,'1',mcs.segment6))
          AND rule_level = 'CUST_CLASSIF'
          AND customer_class_code = cp_cust_classif_code
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability xio,
              wsh_regions_v wrv,
              mtl_categories_b_kfv mcs
        WHERE item_level = 'C'
          AND mcs.category_id = cp_category_id
          AND UPPER(nvl(xio.cat_seg1,'1'))= UPPER(DECODE(xio.cat_seg1,NULL,'1',mcs.segment4))
          AND UPPER(nvl(xio.cat_seg2,'1'))= UPPER(DECODE(xio.cat_seg2,NULL,'1',mcs.segment10))
          AND UPPER(nvl(xio.cat_seg3,'1'))= UPPER(DECODE(xio.cat_seg3,NULL,'1',mcs.segment7))
          AND UPPER(nvl(xio.cat_seg4,'1'))= UPPER(DECODE(xio.cat_seg4,NULL,'1',mcs.segment8))
          AND UPPER(nvl(xio.cat_seg5,'1'))= UPPER(DECODE(xio.cat_seg5,NULL,'1',mcs.segment9))
          AND UPPER(nvl(xio.cat_seg6,'1'))= UPPER(DECODE(xio.cat_seg6,NULL,'1',mcs.segment6))
          AND rule_level = 'REGIONS'
          AND xio.region_id = wrv.region_id
          AND wrv.zone is null
          AND UPPER(nvl(wrv.country,'1'))= UPPER(DECODE(wrv.country,null,'1',cp_cust_region_ctry))--CP_CUST_REGION
          AND UPPER(nvl(wrv.state,'1'))= UPPER(DECODE(wrv.state,null,'1',cp_cust_region_state))
          AND UPPER(nvl(wrv.city,'1'))= UPPER(DECODE(wrv.city,null,'1',cp_cust_region_city))
          AND UPPER(nvl(postal_code_from||postal_code_to,'1'))= UPPER(DECODE((postal_code_from||postal_code_to),null,'1',cp_cust_region_postal))
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability xio,
              wsh_regions_v wrv,
              wsh_zone_regions_v wzr,
              mtl_categories_b_kfv mcs
        WHERE item_level = 'C'
          AND mcs.category_id = cp_category_id
          AND UPPER(nvl(xio.cat_seg1,'1'))= UPPER(DECODE(xio.cat_seg1,NULL,'1',mcs.segment4))
          AND UPPER(nvl(xio.cat_seg2,'1'))= UPPER(DECODE(xio.cat_seg2,NULL,'1',mcs.segment10))
          AND UPPER(nvl(xio.cat_seg3,'1'))= UPPER(DECODE(xio.cat_seg3,NULL,'1',mcs.segment7))
          AND UPPER(nvl(xio.cat_seg4,'1'))= UPPER(DECODE(xio.cat_seg4,NULL,'1',mcs.segment8))
          AND UPPER(nvl(xio.cat_seg5,'1'))= UPPER(DECODE(xio.cat_seg5,NULL,'1',mcs.segment9))
          AND UPPER(nvl(xio.cat_seg6,'1'))= UPPER(DECODE(xio.cat_seg6,NULL,'1',mcs.segment6))
          AND rule_level = 'REGIONS'
          AND xio.region_id = wrv.region_id
          AND wrv.zone is not null
          AND wzr.zone_id = wrv.region_id
          AND xio.region_id =wzr.zone_id
          AND UPPER(nvl(wzr.country,'1'))= UPPER(DECODE(wzr.country,null,'1',cp_cust_region_ctry))--CP_CUST_REGION
          AND UPPER(nvl(wzr.state,'1'))= UPPER(DECODE(wzr.state,null,'1',cp_cust_region_state))
          AND UPPER(nvl(wzr.city,'1'))= UPPER(decode(wzr.city,null,'1',cp_cust_region_city))
          AND UPPER(nvl(wzr.postal_code_from||wzr.postal_code_to,'1'))= UPPER(decode((wzr.postal_code_from||wzr.postal_code_to),null,'1',cp_cust_region_postal))
          AND SYSDATE BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability xto,
          mtl_categories_b_kfv mcs
    WHERE xto.item_level = 'C'
          AND mcs.category_id = cp_category_id
          AND UPPER(nvl(xto.cat_seg1,'1'))= UPPER(DECODE(xto.cat_seg1,NULL,'1',mcs.segment4))
          AND UPPER(nvl(xto.cat_seg2,'1'))= UPPER(DECODE(xto.cat_seg2,NULL,'1',mcs.segment10))
          AND UPPER(nvl(xto.cat_seg3,'1'))= UPPER(DECODE(xto.cat_seg3,NULL,'1',mcs.segment7))
          AND UPPER(nvl(xto.cat_seg4,'1'))= UPPER(DECODE(xto.cat_seg4,NULL,'1',mcs.segment8))
          AND UPPER(nvl(xto.cat_seg5,'1'))= UPPER(DECODE(xto.cat_seg5,NULL,'1',mcs.segment9))
          AND UPPER(nvl(xto.cat_seg6,'1'))= UPPER(DECODE(xto.cat_seg6,NULL,'1',mcs.segment6))
          AND rule_level = 'ORDER_TYPE'
          AND order_type_id = cp_order_type_id
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability xto,
          mtl_categories_b_kfv mcs
    WHERE xto.item_level = 'C'
          AND mcs.category_id = cp_category_id
          AND UPPER(nvl(xto.cat_seg1,'1'))= UPPER(DECODE(xto.cat_seg1,NULL,'1',mcs.segment4))
          AND UPPER(nvl(xto.cat_seg2,'1'))= UPPER(DECODE(xto.cat_seg2,NULL,'1',mcs.segment10))
          AND UPPER(nvl(xto.cat_seg3,'1'))= UPPER(DECODE(xto.cat_seg3,NULL,'1',mcs.segment7))
          AND UPPER(nvl(xto.cat_seg4,'1'))= UPPER(DECODE(xto.cat_seg4,NULL,'1',mcs.segment8))
          AND UPPER(nvl(xto.cat_seg5,'1'))= UPPER(DECODE(xto.cat_seg5,NULL,'1',mcs.segment9))
          AND UPPER(nvl(xto.cat_seg6,'1'))= UPPER(DECODE(xto.cat_seg6,NULL,'1',mcs.segment6))
          AND rule_level = 'SALES_CHANNEL'
          AND sales_channel_code = cp_sales_channel_code
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability xto,
          mtl_categories_b_kfv mcs
    WHERE xto.item_level = 'C'
          AND mcs.category_id = cp_category_id
          AND UPPER(nvl(xto.cat_seg1,'1'))= UPPER(DECODE(xto.cat_seg1,NULL,'1',mcs.segment4))
          AND UPPER(nvl(xto.cat_seg2,'1'))= UPPER(DECODE(xto.cat_seg2,NULL,'1',mcs.segment10))
          AND UPPER(nvl(xto.cat_seg3,'1'))= UPPER(DECODE(xto.cat_seg3,NULL,'1',mcs.segment7))
          AND UPPER(nvl(xto.cat_seg4,'1'))= UPPER(DECODE(xto.cat_seg4,NULL,'1',mcs.segment8))
          AND UPPER(nvl(xto.cat_seg5,'1'))= UPPER(DECODE(xto.cat_seg5,NULL,'1',mcs.segment9))
          AND UPPER(nvl(xto.cat_seg6,'1'))= UPPER(DECODE(xto.cat_seg6,NULL,'1',mcs.segment6))
          AND rule_level = 'SALES_REP'
          AND sales_person_id = cp_salesrep_id
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability xto,
          mtl_categories_b_kfv mcs
    WHERE xto.item_level = 'C'
          AND mcs.category_id = cp_category_id
          AND UPPER(nvl(xto.cat_seg1,'1'))= UPPER(DECODE(xto.cat_seg1,NULL,'1',mcs.segment4))
          AND UPPER(nvl(xto.cat_seg2,'1'))= UPPER(DECODE(xto.cat_seg2,NULL,'1',mcs.segment10))
          AND UPPER(nvl(xto.cat_seg3,'1'))= UPPER(DECODE(xto.cat_seg3,NULL,'1',mcs.segment7))
          AND UPPER(nvl(xto.cat_seg4,'1'))= UPPER(DECODE(xto.cat_seg4,NULL,'1',mcs.segment8))
          AND UPPER(nvl(xto.cat_seg5,'1'))= UPPER(DECODE(xto.cat_seg5,NULL,'1',mcs.segment9))
          AND UPPER(nvl(xto.cat_seg6,'1'))= UPPER(DECODE(xto.cat_seg6,NULL,'1',mcs.segment6))
          AND rule_level = 'SHIP_TO_LOC'
          AND ship_to_location_id = cp_ship_to_org_id
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability xto,
          mtl_categories_b_kfv mcs
    WHERE xto.item_level = 'C'
          AND mcs.category_id = cp_category_id
          AND UPPER(nvl(xto.cat_seg1,'1'))= UPPER(DECODE(xto.cat_seg1,NULL,'1',mcs.segment4))
          AND UPPER(nvl(xto.cat_seg2,'1'))= UPPER(DECODE(xto.cat_seg2,NULL,'1',mcs.segment10))
          AND UPPER(nvl(xto.cat_seg3,'1'))= UPPER(DECODE(xto.cat_seg3,NULL,'1',mcs.segment7))
          AND UPPER(nvl(xto.cat_seg4,'1'))= UPPER(DECODE(xto.cat_seg4,NULL,'1',mcs.segment8))
          AND UPPER(nvl(xto.cat_seg5,'1'))= UPPER(DECODE(xto.cat_seg5,NULL,'1',mcs.segment9))
          AND UPPER(nvl(xto.cat_seg6,'1'))= UPPER(DECODE(xto.cat_seg6,NULL,'1',mcs.segment6))
          AND rule_level = 'BILL_TO_LOC'
          AND bill_to_location_id = cp_bill_to_org_id
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1)
       UNION
       SELECT sequence,item_level
         FROM xxintg_item_orderability xto,
          mtl_categories_b_kfv mcs
    WHERE xto.item_level ='C'
          AND mcs.category_id = cp_category_id
          AND UPPER(nvl(xto.cat_seg1,'1'))= UPPER(DECODE(xto.cat_seg1,NULL,'1',mcs.segment4))
          AND UPPER(nvl(xto.cat_seg2,'1'))= UPPER(DECODE(xto.cat_seg2,NULL,'1',mcs.segment10))
          AND UPPER(nvl(xto.cat_seg3,'1'))= UPPER(DECODE(xto.cat_seg3,NULL,'1',mcs.segment7))
          AND UPPER(nvl(xto.cat_seg4,'1'))= UPPER(DECODE(xto.cat_seg4,NULL,'1',mcs.segment8))
          AND UPPER(nvl(xto.cat_seg5,'1'))= UPPER(DECODE(xto.cat_seg5,NULL,'1',mcs.segment9))
          AND UPPER(nvl(xto.cat_seg6,'1'))= UPPER(DECODE(xto.cat_seg6,NULL,'1',mcs.segment6))
          AND rule_level = 'DELIVER_TO_LOC'
          AND bill_to_location_id = cp_deliver_to_org_id
          AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1);


       x_first_run                VARCHAR2(2):='N';

    BEGIN

       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Entering The Proc orderability_check','XX_OM_ITEM_ORDERABILITY_AME','ORDERABILITY_CHECK',p_item_id,p_category_id);
       p_orderability_flag:='N';
       --p_seq_no := -1;
       IF p_item_id is null and p_category_id is null
       THEN
          p_orderability_flag :='X';
          p_seq_no := -1;
       END IF;

       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'Opening The Cursor ord_res_rec to find Lowest Seq of Restriction ','XX_OM_ITEM_ORDERABILITY_AME','ORDERABILITY_CHECK',p_item_id,p_category_id);
       FOR ord_res_rec in c_ord_res( p_item_id
                           ,p_category_id
                           ,p_customer_id
                           ,p_end_customer_id
                           ,p_customer_class_id
                           ,p_cust_category_code
                           ,p_cust_classif_code
                           ,p_cust_region_ctry
                           ,p_cust_region_state
                           ,p_cust_region_city
                           ,p_cust_region_postal
                           ,p_order_type_id
                           ,p_sales_channel_code
                           ,p_salesrep_id
                           ,p_ship_to_org_id
                           ,p_bill_to_org_id
                           ,p_deliver_to_org_id
                                   )
       LOOP
          p_orderability_flag:='Y';
          IF x_first_run = 'N'
          THEN
             x_first_run:='Y';
             p_seq_no:= ord_res_rec.sequence;
             p_item_level:=ord_res_rec.item_level;
          END IF;
          IF ord_res_rec.sequence  < p_seq_no
          THEN
             p_seq_no:= ord_res_rec.sequence;
             p_item_level:=ord_res_rec.item_level;
          END IF;
       END LOOP;

       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_low, 'The Lowest Seq of Restriction and the Item Level is :','XX_OM_ITEM_ORDERABILITY_AME','ORDERABILITY_CHECK',p_item_id,p_category_id,p_seq_no,p_item_level);
    END orderability_check;
--------------------------------------------------------------------------------------------------
    PROCEDURE release_hold( p_itemType   IN         VARCHAR2
                           ,p_itemKey    IN         VARCHAR2
                           ,p_activityId IN         NUMBER
                           ,funmode      IN         VARCHAR2
                           ,result       OUT NOCOPY VARCHAR2
                          )
    AS
      CURSOR c_hold_id (
         p_hold_name   VARCHAR2
        -- p_hold_type   VARCHAR2,
        -- p_item_type   VARCHAR2
      )
      IS
         SELECT hold_id
           FROM oe_hold_definitions
          WHERE NAME = p_hold_name
            --AND type_code = p_hold_type
            AND TRUNC (SYSDATE) BETWEEN NVL (start_date_active,
                                             TRUNC (SYSDATE)
                                            )
                                    AND NVL (end_date_active, TRUNC (SYSDATE));
      CURSOR c_oe_order_lines (p_itemkey NUMBER)
      IS
         SELECT line_id, ship_from_org_id, header_id, order_source_id,
                inventory_item_id, unit_selling_price, unit_list_price
           FROM oe_order_lines
          WHERE line_id = p_itemkey;


       x_hold_flag                VARCHAR2(5);
       x_hold_name                VARCHAR2(500);
       x_hold_id                  NUMBER;
       x_msg_count                NUMBER;
       x_return_status            VARCHAR2 (100);
       x_msg_data                 VARCHAR2 (100);
       x_order_tbl                oe_holds_pvt.order_tbl_type;
       x_release_reason_code      VARCHAR2 (50);

    BEGIN
       x_hold_flag:=wf_engine.getItemAttrText ( itemtype => p_itemType
                                               ,itemkey  => p_itemKey
                                               ,aname    => 'XXOM_ITEM_ORD_HOLD_FLAG'
                                              );
       x_hold_name:=wf_engine.getItemAttrText ( itemtype => p_itemType
                                               ,itemkey  => p_itemKey
                                               ,aname    => 'XXOM_ITM_ORD_HOLD_NAME'
                                              );
       xx_intg_common_pkg.get_process_param_value('XXOMAMEITEMORD','G_RELEASE_REASON_CODE',x_release_reason_code);

       IF x_hold_flag = 'Y'
       THEN
           OPEN c_hold_id (x_hold_name);
          FETCH c_hold_id
           INTO x_hold_id;
           IF c_hold_id%NOTFOUND
           THEN
              return;
           END IF;
          CLOSE c_hold_id;

         FOR rec_oe_order_lines IN c_oe_order_lines (TO_NUMBER (p_itemkey))
         LOOP
            x_order_tbl (1).header_id := rec_oe_order_lines.header_id;
            x_order_tbl (1).line_id := rec_oe_order_lines.line_id;

           oe_holds_pub.release_holds
                    (p_api_version                   => 1.0,
                     p_init_msg_list                 => fnd_api.g_true,
                     p_commit                        => fnd_api.g_false,
                     p_validation_level              => fnd_api.g_valid_level_full,
                     p_order_tbl                     => x_order_tbl,
                     p_hold_id                       => x_hold_id,
                     p_release_reason_code           => x_release_reason_code,
                     p_release_comment               => NULL,
                     p_check_authorization_flag      => NULL,
                     x_return_status                 => x_return_status,
                     x_msg_count                     => x_msg_count,
                     x_msg_data                      => x_msg_data
                    );
         END LOOP;

       END IF;

    END release_hold;
--------------------------------------------------------------------------------------------------
    FUNCTION chk_line_orderability(p_header_id  IN NUMBER)
    RETURN VARCHAR2
    IS
       x_msg_txt                   VARCHAR2(1000);
       x_msg_flag                  VARCHAR2(1):='N';
       x_category_set_name         VARCHAR2 (30);
       x_item_ord_res              VARCHAR2(2):='N';
       x_seq_num                   NUMBER;
       x_item_level                VARCHAR2(2);
       x_restriction_code          VARCHAR2(50);

       CURSOR c_ord_line_det (p_header_id          NUMBER,
                              p_category_set_name  VARCHAR2 )
       IS
           SELECT hp.party_name cust_name,
                  hca.cust_account_id cust_id,
                  oeol.end_customer_id end_cust,
              hcpc.profile_class_id  cust_class_id,
              (SELECT meaning
                 FROM ar_lookups
                WHERE lookup_type = 'CUSTOMER_CATEGORY'
                  AND lookup_code =hp.category_code) customer_category_code,
              hca.customer_class_code cust_classification_code,
              (SELECT upper(territory_short_name)
                 FROM fnd_territories_tl ftt
                WHERE ftt.territory_code =hl.country
                  AND ftt.language = 'US') cust_region_ctry,
              hl.state cust_region_state,
              hl.city cust_region_city,
              hl.postal_code cust_region_postal_code,
              oeoh.order_type_id,
              oeoh.sales_channel_code,
              oeol.salesrep_id,
              oeol.ship_to_org_id,
              oeol.invoice_to_org_id,
              oeol.deliver_to_org_id,
              oeol.inventory_item_id item_id,
              oeol.line_number,
              (SELECT b.category_id
            FROM mtl_category_sets a,
                 mtl_item_categories b,
                 mtl_system_items_b c
           WHERE a.category_set_id = b.category_set_id
             AND c.inventory_item_id = b.inventory_item_id
             AND b.organization_id   = c.organization_id
             AND category_set_name   = nvl(p_category_set_name, 'Sales and Marketing')
             AND c.inventory_item_id = oeol.inventory_item_id
             AND c.organization_id   = oeol.ship_from_org_id
          UNION
          SELECT b.category_id
            FROM mtl_category_sets a,
                 mtl_item_categories b,
                 mtl_system_items_b c
           WHERE a.category_set_id = b.category_set_id
             AND c.inventory_item_id = b.inventory_item_id
             AND b.organization_id   = c.organization_id
             AND category_set_name   = nvl(p_category_set_name, 'Sales and Marketing')
             AND c.inventory_item_id = oeol.inventory_item_id
             AND c.organization_id   =
                                      (SELECT organization_id
                                         FROM apps.mtl_parameters
                                        WHERE organization_id = master_organization_id)) item_category_id,
             hou.name  --- Added for Wave2
         FROM oe_order_headers oeoh,
              oe_order_lines oeol,
              hz_cust_site_uses hcsu ,
              hz_cust_acct_sites hcas ,
              hz_party_sites hps ,
              hz_locations hl ,
              hz_parties hp,
              hz_customer_profiles hcp,
              hz_cust_profile_classes hcpc,
              hz_cust_accounts hca,
              hr_operating_units hou   --- Added for Wave2
        WHERE 1=1
          AND hcsu.site_use_id       = oeoh.ship_to_org_id
          AND hcsu.site_use_code     = 'SHIP_TO'
          AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
          AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id(+)
          AND hcas.party_site_id     = hps.party_site_id(+)
          AND hl.location_id(+)      = hps.location_id
          AND hp.party_id            = hps.party_id
          AND hca.cust_account_id = hcas.cust_account_id
          AND hcp.cust_account_id = hcas.cust_account_id
          AND hcpc.profile_class_id=hcp.profile_class_id
          AND hcpc.status = 'A'
          AND hps.status  = 'A'
          AND hp.status   = 'A'
          AND hcas.status = 'A'
          AND hcsu.status = 'A'
          AND oeol.header_id = oeoh.header_id
          AND oeol.header_id = p_header_id
          --- Added for Wave2
          AND hou.organization_id = oeoh.org_id
          AND EXISTS
                        (SELECT 1
                       FROM xx_emf_process_parameters xpp, xx_emf_process_setup xps
                      WHERE 1 = 1
                        AND xps.process_id = xpp.process_id
                        AND xps.process_name = 'XXOMAMEITEMORD'
                        AND UPPER (parameter_name) LIKE 'INCLUDE_OU_%'
                        AND NVL (xpp.enabled_flag, 'Y') = 'Y'
                            AND NVL (xps.enabled_flag, 'Y') = 'Y'
                            AND parameter_value = hou.name);

       CURSOR c_line_restrict_code (p_seq         NUMBER,
                                    p_item_id     NUMBER,
                                    p_category_id NUMBER,
                                    p_item_level  VARCHAR2
                                    )
       IS
           SELECT xto.restriction_code
         FROM xxintg_item_orderability xto
        WHERE sequence = p_seq
          AND xto.inventory_item_id = p_item_id
          AND XTO.ITEM_LEVEL = p_item_level
              AND sysdate between NVL(START_DATE,TO_DATE('01-01-1900','DD-MM-YYYY')) and NVL(END_DATE,sysdate+1)
           UNION
           SELECT xto.restriction_code
         FROM xxintg_item_orderability xto,
              mtl_categories_b_kfv mcs
        WHERE sequence = p_seq
          AND UPPER(nvl(xto.cat_seg1,'1'))= UPPER(DECODE(xto.cat_seg1,NULL,'1',mcs.segment4))
          AND UPPER(nvl(xto.cat_seg2,'1'))= UPPER(DECODE(xto.cat_seg2,NULL,'1',mcs.segment10))
          AND UPPER(nvl(xto.cat_seg3,'1'))= UPPER(DECODE(xto.cat_seg3,NULL,'1',mcs.segment7))
          AND UPPER(nvl(xto.cat_seg4,'1'))= UPPER(DECODE(xto.cat_seg4,NULL,'1',mcs.segment8))
          AND UPPER(nvl(xto.cat_seg5,'1'))= UPPER(DECODE(xto.cat_seg5,NULL,'1',mcs.segment9))
          AND UPPER(nvl(xto.cat_seg6,'1'))= UPPER(DECODE(xto.cat_seg6,NULL,'1',mcs.segment6))
          AND MCS.CATEGORY_ID = p_category_id
              AND xto.inventory_item_id is null
          AND XTO.ITEM_LEVEL = p_item_level
              AND sysdate BETWEEN NVL(start_date,to_date('01-01-1900','DD-MM-YYYY')) AND NVL(end_date,sysdate+1);

    BEGIN

       xx_intg_common_pkg.get_process_param_value('XXOMAMEITEMORD','CATEGORY_SET_NAME',x_category_set_name);

       FND_MESSAGE.SET_NAME ('XXINTG','XX_OM_ITM_ORDERABILITY_MSG');
       x_msg_txt:= FND_MESSAGE.GET;

       FOR x_ord_line_det_rec in c_ord_line_det( p_header_id,x_category_set_name)
       LOOP

           xx_om_item_orderability_ame.orderability_check( p_item_id            => x_ord_line_det_rec.item_id
                                                          ,p_category_id        => x_ord_line_det_rec.item_category_id
                                                          ,p_customer_id        => x_ord_line_det_rec.cust_id
                                                          ,p_end_customer_id    => x_ord_line_det_rec.end_cust
                                                          ,p_customer_class_id  => x_ord_line_det_rec.cust_class_id
                                                          ,p_cust_category_code => x_ord_line_det_rec.customer_category_code
                                                          ,p_cust_classif_code  => x_ord_line_det_rec.cust_classification_code
                                                          ,p_cust_region_ctry   => x_ord_line_det_rec.cust_region_ctry
                                                          ,p_cust_region_state  => x_ord_line_det_rec.cust_region_state
                                                          ,p_cust_region_city   => x_ord_line_det_rec.cust_region_city
                                                          ,p_cust_region_postal => x_ord_line_det_rec.cust_region_postal_code
                                                          ,p_order_type_id      => x_ord_line_det_rec.order_type_id
                                                          ,p_sales_channel_code => x_ord_line_det_rec.sales_channel_code
                                                          ,p_salesrep_id        => x_ord_line_det_rec.salesrep_id
                                                          ,p_ship_to_org_id     => x_ord_line_det_rec.ship_to_org_id
                                                          ,p_bill_to_org_id     => x_ord_line_det_rec.invoice_to_org_id
                                                          ,p_deliver_to_org_id  => x_ord_line_det_rec.deliver_to_org_id
                                                          ,p_orderability_flag  => x_item_ord_res
                                                          ,p_seq_no             => x_seq_num
                                                          ,p_item_level         => x_item_level
                                                        );
           IF x_item_ord_res = 'Y'
           THEN

               OPEN c_line_restrict_code(x_seq_num,x_ord_line_det_rec.item_id,x_ord_line_det_rec.item_category_id,x_item_level);
              FETCH c_line_restrict_code
               INTO x_restriction_code;
              CLOSE c_line_restrict_code;

              IF x_restriction_code = 'NO_SALE'
              THEN
                 x_msg_flag:='Y';
                 x_msg_txt:=x_msg_txt||x_ord_line_det_rec.line_number||',';
              END IF;
           END IF;

       END LOOP;

       IF x_msg_flag ='Y'
       THEN
          RETURN SUBSTR(x_msg_txt,1,(LENGTH(x_msg_txt)-1));
       ELSE
          --x_msg_txt:='There Is No Orderability Restrictions On The Order Lines';
          x_msg_txt:=NULL;
          RETURN x_msg_txt;
       END IF;

    END chk_line_orderability;
--------------------------------------------------------------------------------------------------
END xx_om_item_orderability_ame;
/
