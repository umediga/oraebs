DROP PACKAGE BODY APPS.XX_OM_LINE_PRICE_CHECK;

CREATE OR REPLACE PACKAGE BODY APPS.xx_om_line_price_check
----------------------------------------------------------------------
/* $Header: XXOMLINEPRICEWF.pkb 1.0 2012/02/08 12:00:00 dparida noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 08-Feb-2012
 File Name      : XXOMLINEPRICEWF.pkb
 Description    : This script creates the specification of the xx_om_line_price_check package

 Change History:

 Version Date        Name            Remarks
 ------- ----------- ----            ----------------------
 1.0     08-Feb-12   IBM Development Team    Initial development.
 1.1     27-Feb-12   IBM Development Team    Added the logic for Process Setup Form
 1.2     01-Oct-12   IBM Development Team    - Header adjustment
                                             - Exclude order source
 2.0     20-Jul-13   Yogesh                  Added changes for WAVE1
 2.1     26-Feb-14   Dhiren                  Added Price Override header Logic
 3.1     14-Nov-14   Sanjeev                 Modified xx_om_chk_prcovr_hold_header as per the case 011324
 3.2     03-Feb-14   Dhiren                  Added changes for WAVE1A
*/
----------------------------------------------------------------------
 AS
  FUNCTION get_supervisor(p_userid IN NUMBER) RETURN VARCHAR2 IS
    x_supervisor CHAR(1) := 'N';
  BEGIN
    SELECT DECODE(COUNT(d.user_id), 0, 'N', 'Y')
      INTO x_supervisor
      FROM per_all_people_f      a,
           fnd_user              b,
           per_all_assignments_f c,
           fnd_user              d
     WHERE b.user_id = p_userid
       AND b.employee_id = a.person_id
       AND a.person_id = c.person_id
       AND TRUNC(SYSDATE) BETWEEN a.effective_start_date AND
           a.effective_end_date
       AND TRUNC(SYSDATE) BETWEEN c.effective_start_date AND
           c.effective_end_date
       AND d.employee_id = c.supervisor_id;

    RETURN(x_supervisor);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN('N');
  END;

  -- =================================================================================
  -- Name           : xx_om_line_hold_approve
  -- Description    : Procedure To Release HOLD Applied on the SO Lines due to
  --                  manuall price override , once approved by the supervisor
  -- Parameters description       :
  --
  -- itemtype                    : Parameter To Store itemtype (IN)
  -- itemkey                     : Parameter To Store itemkey  (IN)
  -- actid                       : Parameter To Store actid    (IN)
  -- funcmode                    : Parameter To Store funcmode (IN)
  -- resultout                   : Parameter To Store resultout(IN OUT)
  -- ==============================================================================
  PROCEDURE xx_om_line_hold_approve(itemtype  IN VARCHAR2,
                                    itemkey   IN VARCHAR2,
                                    actid     IN NUMBER,
                                    funcmode  IN VARCHAR2,
                                    resultout IN OUT NOCOPY VARCHAR2) IS
    x_order_tbl           oe_holds_pvt.order_tbl_type;
    x_hold_id             NUMBER;
    x_price_adjustment_id NUMBER;
    x_msg_count           NUMBER;
    x_app_user_id         NUMBER;
    x_err_msg             VARCHAR2(1000);
    x_return_status       VARCHAR2(100);
    x_msg_data            VARCHAR2(100);
    x_hold_name           VARCHAR2(50);
    x_release_reason_code VARCHAR2(50);
    x_hold_type           VARCHAR2(50);
    x_item_type           VARCHAR2(50);
    x_cost_type           VARCHAR2(50);
    e_hold_error EXCEPTION;
    e_emf_variables EXCEPTION;
    e_hold_id EXCEPTION;
    x_app_user_name VARCHAR2(50); -- Added by Yogesh to fetch the last Updated by as AME approver

    -- Cursor to fetch all the constant values from the emf table
    CURSOR c_emf_variables(p_parameter_name VARCHAR2) IS
      SELECT parameter_value
        FROM xx_emf_process_parameters xpp, xx_emf_process_setup xps
       WHERE 1 = 1
         AND xps.process_id = xpp.process_id
         AND xps.process_name = 'XXOMPRICEOVERRIDEEXT'
         AND UPPER(parameter_name) = UPPER(p_parameter_name)
         AND NVL(xpp.enabled_flag, 'Y') = 'Y'
         AND NVL(xps.enabled_flag, 'Y') = 'Y';

    -- Cursor to fetch line details of a perticular SO
    CURSOR c_oe_order_lines(p_itemkey NUMBER) IS
      SELECT line_id,
             ship_from_org_id,
             header_id,
             order_source_id,
             inventory_item_id,
             unit_selling_price,
             unit_list_price
        FROM oe_order_lines
       WHERE line_id = p_itemkey;

    -- Cursor to fetch HOLD ID
    CURSOR c_hold_id(p_hold_name VARCHAR2, p_hold_type VARCHAR2, p_item_type VARCHAR2) IS
      SELECT hold_id
        FROM oe_hold_definitions
       WHERE NAME = p_hold_name
         AND type_code = p_hold_type
         AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active, TRUNC(SYSDATE)) AND
             NVL(end_date_active, TRUNC(SYSDATE))
         AND item_type = p_item_type;

    -- Cursor to fetch ADJUSTMENT ID
    CURSOR c_adjustment_id(p_header_id NUMBER, p_line_id NUMBER) IS
      SELECT price_adjustment_id
        FROM oe_price_adjustments_v
       WHERE header_id = p_header_id
         AND (line_id = p_line_id OR line_id IS NULL) -- Changed 01-Oct-2012
         AND change_reason_code = 'MANUAL'
         AND charge_type_code IS NULL
         AND override_allowed_flag = 'Y';
  BEGIN
    IF (funcmode = 'RUN') THEN
      x_app_user_name := wf_engine.getItemAttrText(itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'INTG_APP_NAME');

      /*x_app_user_id:=wf_engine.getitemattrnumber (itemtype      => itemtype,
       itemkey       => itemkey,
       aname         => 'INTG_APP_ID'
      );*/

      BEGIN
        SELECT user_id
          INTO x_app_user_id
          FROM fnd_user
         WHERE user_name = x_app_user_name;
      EXCEPTION
        WHEN OTHERS THEN
          x_app_user_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                       itemkey  => itemkey,
                                                       aname    => 'USER_ID');
      END;

      --- Query to Extract Line Details
      FOR rec_oe_order_lines IN c_oe_order_lines(TO_NUMBER(itemkey)) LOOP
        x_order_tbl(1).header_id := rec_oe_order_lines.header_id;
        x_order_tbl(1).line_id := rec_oe_order_lines.line_id;
        x_price_adjustment_id := NULL;

        --- Query to extract the adjustment id
        OPEN c_adjustment_id(rec_oe_order_lines.header_id,
                             rec_oe_order_lines.line_id);

        FETCH c_adjustment_id
          INTO x_price_adjustment_id;

        CLOSE c_adjustment_id;

        IF x_price_adjustment_id IS NOT NULL THEN
          --- Query to extract constant values from the emf tables
          OPEN c_emf_variables(g_hold_name);

          FETCH c_emf_variables
            INTO x_hold_name;

          CLOSE c_emf_variables;

          OPEN c_emf_variables(g_release_reason_code);

          FETCH c_emf_variables
            INTO x_release_reason_code;

          CLOSE c_emf_variables;

          OPEN c_emf_variables(g_hold_type);

          FETCH c_emf_variables
            INTO x_hold_type;

          CLOSE c_emf_variables;

          OPEN c_emf_variables(g_item_type);

          FETCH c_emf_variables
            INTO x_item_type;

          CLOSE c_emf_variables;

          OPEN c_emf_variables(g_cost_type);

          FETCH c_emf_variables
            INTO x_cost_type;

          CLOSE c_emf_variables;

          --- Query to Extract Hold Id
          OPEN c_hold_id(x_hold_name, x_hold_type, x_item_type);

          FETCH c_hold_id
            INTO x_hold_id;

          CLOSE c_hold_id;

          -- Call the API to release HOLD
          BEGIN
            oe_holds_pub.release_holds(p_api_version              => 1.0,
                                       p_init_msg_list            => fnd_api.g_true,
                                       p_commit                   => fnd_api.g_false,
                                       p_validation_level         => fnd_api.g_valid_level_full,
                                       p_order_tbl                => x_order_tbl,
                                       p_hold_id                  => x_hold_id,
                                       p_release_reason_code      => x_release_reason_code,
                                       p_release_comment          => NULL,
                                       p_check_authorization_flag => NULL,
                                       x_return_status            => x_return_status,
                                       x_msg_count                => x_msg_count,
                                       x_msg_data                 => x_msg_data);

            -- Update the approver ID
            UPDATE oe_hold_releases
               SET created_by      = x_app_user_id,
                   last_updated_by = x_app_user_id
             WHERE hold_source_id IN
                   (SELECT b.hold_source_id
                      FROM oe_order_holds_all  a,
                           oe_hold_sources_all b,
                           oe_hold_definitions c
                     WHERE a.header_id = rec_oe_order_lines.header_id
                       AND a.line_id = rec_oe_order_lines.line_id
                       AND a.hold_source_id = b.hold_source_id
                       AND c.hold_id = b.hold_id
                       AND c.NAME = x_hold_name
                       AND c.type_code = x_hold_type
                       AND TRUNC(SYSDATE) BETWEEN
                           NVL(c.start_date_active, TRUNC(SYSDATE)) AND
                           NVL(c.end_date_active, TRUNC(SYSDATE))
                       AND c.item_type = x_item_type);
          EXCEPTION
            WHEN OTHERS THEN
              x_err_msg := SUBSTR(SQLERRM, 1, 80);
              RAISE e_hold_error;
          END;
        END IF;
      END LOOP;
    END IF;

    IF (funcmode = 'CANCEL') THEN
      NULL;
      RETURN;
    END IF;

    resultout := 'COMPLETE:COMPLETE';
  EXCEPTION
    WHEN e_hold_error THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_line_hold_approve ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || x_err_msg);
      RAISE;
    WHEN e_emf_variables THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_line_hold_approve ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || x_err_msg);
      RAISE;
    WHEN e_hold_id THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_line_hold_approve ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : Price Over Ride Hold Not Define In Oracle');
      RAISE;
    WHEN OTHERS THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_line_hold_approve ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || SQLERRM);
      oe_standard_wf.add_error_activity_msg(p_actid    => actid,
                                            p_itemtype => itemtype,
                                            p_itemkey  => itemkey);
      oe_standard_wf.save_messages;
      oe_standard_wf.clear_msg_context;
      RAISE;
  END xx_om_line_hold_approve;

  -- =================================================================================
  -- Name           : xx_om_validate_line_price
  -- Description    : Procedure To Check the Item Price against the ship from org Price
  --                  If there is a manuall override then it will Apply The HOLD
  -- Parameters description       :
  --
  -- itemtype                    : Parameter To Store itemtype (IN)
  -- itemkey                     : Parameter To Store itemkey  (IN)
  -- actid                       : Parameter To Store actid    (IN)
  -- funcmode                    : Parameter To Store funcmode (IN)
  -- resultout                   : Parameter To Store resultout(IN OUT)
  -- ==============================================================================
  PROCEDURE xx_om_validate_line_price(itemtype  IN VARCHAR2,
                                      itemkey   IN VARCHAR2,
                                      actid     IN NUMBER,
                                      funcmode  IN VARCHAR2,
                                      resultout IN OUT NOCOPY VARCHAR2) IS
    x_order_tbl           oe_holds_pvt.order_tbl_type;
    x_item_cost           NUMBER := 0;
    x_hold_id             NUMBER;
    x_price_adjustment_id NUMBER;
    x_user_id             NUMBER;
    x_msg_count           NUMBER;
    x_super_suer_id       NUMBER;
    x_margin_cost         VARCHAR2(240);
    x_super_suer_name     VARCHAR2(100);
    x_err_msg             VARCHAR2(1000);
    x_user_name           VARCHAR2(100);
    x_return_status       VARCHAR2(100);
    x_msg_data            VARCHAR2(100);
    x_hold_name           VARCHAR2(50);
    x_release_reason_code VARCHAR2(50);
    x_hold_type           VARCHAR2(50);
    x_item_type           VARCHAR2(50);
    x_cost_type           VARCHAR2(50);
    x_tran_curr           VARCHAR2(10);
    x_func_curr           VARCHAR2(10);
    x_conv_date           DATE;
    x_conv_type_code      VARCHAR2(240);
    e_item_cost EXCEPTION;
    e_hold_id EXCEPTION;
    e_hold_error EXCEPTION;
    e_emf_variables EXCEPTION;
    e_super_not_found EXCEPTION;
    x_cust_name    VARCHAR2(240);
    x_order_type   VARCHAR2(240);
    x_order_number VARCHAR2(240);
    x_item_num     VARCHAR2(240);
    x_app_body     VARCHAR2(2000);
    x_user_body    VARCHAR2(2000);
    x_app_title    VARCHAR2(1000);
    x_user_title   VARCHAR2(1000);
    x_conv_rate    NUMBER;

    -- Added 01-Oct-2012
    x_order_source_id NUMBER;
    x_line_type_id    NUMBER;
    --  x_exclude               VARCHAR2(1) := 'Y';
    x_ame_trx_type VARCHAR2(1) := 'Y';

    CURSOR c_fetch_msg_dets IS
      SELECT hp.party_name,
             ot.NAME,
             oeh.order_number,
             msi.segment1,
             oeh.transactional_curr_code,
             gll.currency_code,
             TRUNC(oeh.ordered_date),
             oeh.conversion_type_code,
             oeh.order_source_id,
             oel.line_type_id -- Added 01-Oct-2012
        FROM oe_order_headers_all oeh,
             oe_order_lines_all oel,
             oe_transaction_types_tl ot,
             mtl_system_items_b msi,
             hz_cust_accounts hca,
             hz_parties hp,
             (SELECT parameter_value, org_id
                FROM oe_sys_parameters_all osp
               WHERE osp.parameter_code = 'MASTER_ORGANIZATION_ID') t,
             hr_operating_units hou,
             gl_ledgers gll
       WHERE 1 = 1
         AND t.org_id = oel.org_id
         AND oeh.header_id = oel.header_id
         AND oel.line_id = TO_NUMBER(itemkey)
         AND oeh.order_type_id = ot.transaction_type_id
         AND ot.LANGUAGE = USERENV('LANG')
         AND msi.organization_id = oel.ship_from_org_id
         AND msi.inventory_item_id = oel.inventory_item_id
         AND hca.cust_account_id = oel.sold_to_org_id
         AND hca.party_id = hp.party_id
         AND oeh.org_id = hou.organization_id
         AND hou.set_of_books_id = gll.ledger_id;

    CURSOR c_fetch_conv_rate(p_from_curr VARCHAR2, p_to_curr VARCHAR2, p_conv_date DATE, p_conv_type VARCHAR2) IS
      SELECT conversion_rate
        FROM gl_daily_rates
       WHERE from_currency = p_from_curr
         AND to_currency = p_to_curr
         AND UPPER(conversion_type) = UPPER(p_conv_type)
         AND conversion_date = p_conv_date;

    -- Cursor to fetch all the constant values from the emf table
    CURSOR c_emf_variables(p_parameter_name VARCHAR2) IS
      SELECT parameter_value
        FROM xx_emf_process_parameters xpp, xx_emf_process_setup xps
       WHERE 1 = 1
         AND xps.process_id = xpp.process_id
         AND xps.process_name = 'XXOMPRICEOVERRIDEEXT'
         AND UPPER(parameter_name) = UPPER(p_parameter_name)
         AND NVL(xpp.enabled_flag, 'Y') = 'Y'
         AND NVL(xps.enabled_flag, 'Y') = 'Y';

    -- Cursor to fetch line details of the SO
    CURSOR c_oe_order_lines(p_itemkey NUMBER) IS
      SELECT oel.line_id,
             oel.ship_from_org_id,
             oel.header_id,
             oel.order_source_id,
             oel.inventory_item_id,
             oel.unit_selling_price,
             oel.unit_list_price,
             oel.line_number,
             oeh.order_number,
             oel.last_updated_by -- changed for CR
        FROM oe_order_lines_all oel, oe_order_headers_all oeh
       WHERE oel.line_id = p_itemkey
         AND oeh.header_id = oel.header_id
         AND oel.creation_date > oeh.booked_date; --- Added on 26-Feb-2014

    -- Cursor to fetch HOLD ID
    CURSOR c_hold_id(p_hold_name VARCHAR2, p_hold_type VARCHAR2, p_item_type VARCHAR2) IS
      SELECT hold_id
        FROM oe_hold_definitions
       WHERE NAME = p_hold_name
         AND type_code = p_hold_type
         AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active, TRUNC(SYSDATE)) AND
             NVL(end_date_active, TRUNC(SYSDATE))
         AND item_type = p_item_type;

    -- Cursor to fetch item cost at Ship From Org
    CURSOR c_item_cost(p_inventory_item_id NUMBER, p_ship_from_org_id NUMBER, p_cost_type VARCHAR2) IS
      SELECT NVL(item_cost, 0)
        FROM cst_item_cost_type_v
       WHERE inventory_item_id = p_inventory_item_id
         AND organization_id = p_ship_from_org_id
         AND cost_type = p_cost_type;

    -- Cursor to fetch Adjustment ID
    CURSOR c_adjustment_id(p_header_id NUMBER, p_line_id NUMBER) IS
      SELECT price_adjustment_id
        FROM oe_price_adjustments_v
       WHERE header_id = p_header_id
         AND (line_id = p_line_id OR line_id IS NULL) -- Changed 01-Oct-2012
         AND change_reason_code = 'MANUAL'
         AND charge_type_code IS NULL
         AND override_allowed_flag = 'Y';
    --Commented By Yogesh for WAVE1 changes, as the last update will be done from AME Approver
    -- Cursor to fetch CSR Supervisor details
    /* CURSOR c_supervisor_name (p_user_id NUMBER)
    IS
       SELECT d.user_name, d.user_id
         FROM per_all_people_f a,
              fnd_user b,
              per_all_assignments_f c,
              fnd_user d
        WHERE b.user_id = p_user_id
          AND b.employee_id = a.person_id
          AND a.person_id = c.person_id
          AND TRUNC (SYSDATE) BETWEEN a.effective_start_date
                                  AND a.effective_end_date
          AND TRUNC (SYSDATE) BETWEEN c.effective_start_date
                                  AND c.effective_end_date
          AND d.employee_id = c.supervisor_id;*/

    -- Cursor to exclude order source
    -- Added on 01-Oct-2012
    -- Commented By Yogesh, As we have a check on the attribute3 of Order Type.
    -- Check on Order source has been commented.
    /*CURSOR c_order_source (x_order_source_id IN NUMBER)
    IS
    SELECT 'N'
      FROM oe_order_sources oos
          ,xx_emf_process_parameters xpp
          ,xx_emf_process_setup xps
     WHERE 1 = 1
       AND xps.process_id = xpp.process_id
       AND xps.process_name = 'XXOMPRICEOVERRIDEEXT'
       AND NVL (xpp.enabled_flag, 'Y') = 'Y'
       AND NVL (xps.enabled_flag, 'Y') = 'Y'
       AND UPPER (xpp.parameter_name) LIKE 'ORDER_SOURCE%'
       AND oos.NAME = xpp.parameter_value
       AND oos.order_source_id = x_order_source_id;*/

    -- Cursor to Exclude order type from AME approvals
    CURSOR c_order_trx_typ(p_line_id IN VARCHAR) IS
      SELECT NVL(ott.attribute3, 'Y')
        FROM oe_order_headers_all ooh, oe_transaction_types_all ott
       WHERE ooh.header_id in
             (SELECT header_id
                FROM oe_order_lines_all
               WHERE line_id = TO_NUMBER(p_line_id))
         AND ooh.order_type_id = ott.transaction_type_id;

  BEGIN
    IF (funcmode = 'RUN') THEN

      resultout := 'COMPLETE:NA';
      /*x_user_id :=
      wf_engine.getitemattrnumber (itemtype      => itemtype,
                                   itemkey       => itemkey,
                                   aname         => 'USER_ID'
                                  );*/

      --- Query to Extract Line Details
      FOR rec_oe_order_lines IN c_oe_order_lines(TO_NUMBER(itemkey)) LOOP
        x_order_tbl(1).header_id := rec_oe_order_lines.header_id;
        x_order_tbl(1).line_id := rec_oe_order_lines.line_id;
        x_price_adjustment_id := NULL;
        x_user_id := rec_oe_order_lines.last_updated_by;



        BEGIN
          SELECT user_name
            INTO x_user_name
            FROM fnd_user
           WHERE user_id = x_user_id;
        EXCEPTION
          WHEN OTHERS THEN
            x_user_name := NULL;
        END;

        OPEN c_fetch_msg_dets;

        FETCH c_fetch_msg_dets
          INTO x_cust_name, x_order_type, x_order_number, x_item_num, x_tran_curr, x_func_curr, x_conv_date, x_conv_type_code, x_order_source_id, x_line_type_id; -- Added 01-Oct-2012

        CLOSE c_fetch_msg_dets;

        -- wf_test_data('Notification Data '||x_cust_name||'-'||x_order_type||'-'||x_order_number||'-'||x_item_num||'-'||x_tran_curr||'-'||x_func_curr||'-'||x_conv_date||'-'||x_conv_type_code||'-'||x_order_source_id||'-'||x_line_type_id);

        -- Order Source Exclusion logic: Added 01-Oct-2012
        -- Commeneted by Yogesh on 04-SEP-2013
        /* OPEN c_order_source(x_order_source_id);
        FETCH c_order_source
         INTO x_exclude;
        CLOSE c_order_source;*/

        OPEN c_order_trx_typ(itemkey);
        FETCH c_order_trx_typ
          INTO x_ame_trx_type;
        CLOSE c_order_trx_typ;

        IF x_ame_trx_type = 'N' THEN
          resultout := 'COMPLETE:NA';
          RETURN;
        END IF;

        -- Commeneted by Yogesh on 04-SEP-2013
        /* IF x_exclude = 'Y' THEN
           resultout := 'COMPLETE:NA';
           RETURN;
        END IF;*/

        --- Query to extract the adjustment id
        OPEN c_adjustment_id(rec_oe_order_lines.header_id,
                             rec_oe_order_lines.line_id);

        FETCH c_adjustment_id
          INTO x_price_adjustment_id;

        CLOSE c_adjustment_id;

        IF x_price_adjustment_id IS NOT NULL THEN
          --- Query to Extract Global Variable values from emf Table
          OPEN c_emf_variables(g_hold_name);

          FETCH c_emf_variables
            INTO x_hold_name;

          CLOSE c_emf_variables;

          OPEN c_emf_variables(g_release_reason_code);

          FETCH c_emf_variables
            INTO x_release_reason_code;

          CLOSE c_emf_variables;

          OPEN c_emf_variables(g_hold_type);

          FETCH c_emf_variables
            INTO x_hold_type;

          CLOSE c_emf_variables;

          OPEN c_emf_variables(g_item_type);

          FETCH c_emf_variables
            INTO x_item_type;

          CLOSE c_emf_variables;

          OPEN c_emf_variables(g_cost_type);

          FETCH c_emf_variables
            INTO x_cost_type;

          CLOSE c_emf_variables;

          --- Query to Extract Price For the Item in Shipping Org
          OPEN c_item_cost(rec_oe_order_lines.inventory_item_id,
                           rec_oe_order_lines.ship_from_org_id,
                           x_cost_type);

          FETCH c_item_cost
            INTO x_item_cost;

          CLOSE c_item_cost;

          IF x_func_curr <> x_tran_curr THEN
            OPEN c_fetch_conv_rate(x_func_curr,
                                   x_tran_curr,
                                   x_conv_date,
                                   x_conv_type_code);

            FETCH c_fetch_conv_rate
              INTO x_conv_rate;

            CLOSE c_fetch_conv_rate;

            x_item_cost := ROUND(x_item_cost * x_conv_rate, 2);
          END IF;

          IF x_item_cost <> 0 THEN
            x_margin_cost := ROUND(((rec_oe_order_lines.unit_selling_price -
                                   x_item_cost) / x_item_cost) * 100,
                                   2) || '%';
          ELSE
            x_margin_cost := 'cannot be derived as Item Cost is 0 or not defined in Shipping Org';
          END IF;

          x_app_title  := 'Following order price change needs your approval -  Order Number ' ||
                          x_order_number || ' Order Line ' ||
                          rec_oe_order_lines.line_number;
          x_app_body   := 'Please approve the following Price Override for the following order - ' ||
                          CHR(10) || 'Customer Name > ' || x_cust_name ||
                          CHR(10) || 'Order Type > ' || x_order_type ||
                          CHR(10) || 'Order Number > ' || x_order_number ||
                          CHR(10) || 'Line Number > ' ||
                          rec_oe_order_lines.line_number || CHR(10) ||
                          'Item Number > ' || x_item_num || CHR(10) ||
                          'Transaction Currency > ' || x_tran_curr ||
                          CHR(10) || 'Unit Selling Price > ' ||
                          rec_oe_order_lines.unit_selling_price || CHR(10) ||
                          'Unit List Price > ' ||
                          rec_oe_order_lines.unit_list_price || CHR(10) ||
                          'Margin Cost > ' || x_margin_cost;
          x_user_title := 'Following order price change is rejected -  Order Number ' ||
                          x_order_number || ' Order Line ' ||
                          rec_oe_order_lines.line_number;
          x_user_body  := 'Please correct the following Price Override for the following order - ' ||
                          CHR(10) || 'Customer Name > ' || x_cust_name ||
                          CHR(10) || 'Order Type > ' || x_order_type ||
                          CHR(10) || 'Order Number > ' || x_order_number ||
                          CHR(10) || 'Line Number > ' ||
                          rec_oe_order_lines.line_number || CHR(10) ||
                          'Item Number > ' || x_item_num || CHR(10) ||
                          'Transaction Currency > ' || x_tran_curr ||
                          CHR(10) || 'Unit Selling Price > ' ||
                          rec_oe_order_lines.unit_selling_price || CHR(10) ||
                          'Unit List Price > ' ||
                          rec_oe_order_lines.unit_list_price || CHR(10) ||
                          'Margin Cost > ' || x_margin_cost;

          --- Query to Extract Hold Id
          OPEN c_hold_id(x_hold_name, x_hold_type, x_item_type);

          FETCH c_hold_id
            INTO x_hold_id;

          /*
           IF c_hold_id%NOTFOUND
           THEN
              RAISE e_hold_id;
           END IF;
          */
          CLOSE c_hold_id;

          --Commented By Yogesh for WAVE1 changes, as the last update will be done from AME Approver
          --- Query to Extract the Supervisor Name
          /*OPEN c_supervisor_name (x_user_id);

          FETCH c_supervisor_name
           INTO x_super_suer_name, x_super_suer_id;

          /*
          IF c_supervisor_name%NOTFOUND
          THEN
             RAISE e_super_not_found;
          END IF;
          */
          /* CLOSE c_supervisor_name;*/

          IF x_hold_id IS NOT NULL THEN
            oe_holds_pub.apply_holds(p_api_version              => 1.0,
                                     p_init_msg_list            => fnd_api.g_true,
                                     p_commit                   => fnd_api.g_false,
                                     p_validation_level         => fnd_api.g_valid_level_full,
                                     p_order_tbl                => x_order_tbl,
                                     p_hold_id                  => x_hold_id,
                                     p_hold_until_date          => NULL,
                                     p_hold_comment             => NULL,
                                     p_check_authorization_flag => NULL,
                                     x_return_status            => x_return_status,
                                     x_msg_count                => x_msg_count,
                                     x_msg_data                 => x_msg_data);
          END IF;

          --- Call the API to Apply Hold When selling price is less than item cost at ship from org
          IF rec_oe_order_lines.unit_selling_price < x_item_cost THEN
            BEGIN
              x_app_body := x_app_body || CHR(10) ||
                            'NOTE - Item sold at a price less than item cost.';
              resultout  := 'COMPLETE:Y';
            EXCEPTION
              WHEN OTHERS THEN
                x_err_msg := SUBSTR(SQLERRM, 1, 80);
                RAISE e_hold_error;
            END;
          ELSIF rec_oe_order_lines.unit_selling_price > x_item_cost THEN
            --- Call the API to Apply Hold When selling price is greater than item cost at ship from org
            BEGIN
              x_app_body := x_app_body || CHR(10) ||
                            'NOTE - Item sold at a price greater than item cost.';
              resultout  := 'COMPLETE:Y';
            EXCEPTION
              WHEN OTHERS THEN
                x_err_msg := SUBSTR(SQLERRM, 1, 80);
                RAISE e_hold_error;
            END;
          ELSIF rec_oe_order_lines.unit_selling_price = x_item_cost THEN
            --- Call the API to Apply Hold When selling price is equal to item cost at ship from org
            BEGIN
              x_app_body := x_app_body || CHR(10) ||
                            'NOTE - Item sold at a price equal to item cost.';
              resultout  := 'COMPLETE:Y';
            EXCEPTION
              WHEN OTHERS THEN
                x_err_msg := SUBSTR(SQLERRM, 1, 80);
                RAISE e_hold_error;
            END;
          ELSIF x_item_cost IS NULL THEN
            x_app_body := x_app_body || CHR(10) ||
                          'NOTE - ITEM COST is not defined in the shipping org.';
            resultout  := 'COMPLETE:Y';
          END IF;

          wf_engine.setitemattrtext(itemtype => itemtype,
                                    itemkey  => itemkey,
                                    aname    => 'INTG_APP_NAME',
                                    avalue   => x_super_suer_name);
          --Commented By Yogesh for WAVE1 changes, As the last update will be done from AME Approver
          /* wf_engine.setitemattrtext (itemtype      => itemtype,
           itemkey       => itemkey,
           aname         => 'INTG_APP_ID',
           avalue        => x_super_suer_id
          );*/
          wf_engine.setitemattrtext(itemtype => itemtype,
                                    itemkey  => itemkey,
                                    aname    => 'XX_INTG_SO_NUMBER',
                                    avalue   => rec_oe_order_lines.order_number);
          wf_engine.setitemattrtext(itemtype => itemtype,
                                    itemkey  => itemkey,
                                    aname    => 'XX_INTG_LINE_NUMBER',
                                    avalue   => rec_oe_order_lines.line_number);
          wf_engine.setitemattrtext(itemtype => itemtype,
                                    itemkey  => itemkey,
                                    aname    => 'XX_INTG_USP',
                                    avalue   => rec_oe_order_lines.unit_selling_price);
          wf_engine.setitemattrtext(itemtype => itemtype,
                                    itemkey  => itemkey,
                                    aname    => 'XX_INTG_OVP',
                                    avalue   => x_margin_cost
                                    -- x_item_cost
                                    );
          wf_engine.setitemattrtext(itemtype => itemtype,
                                    itemkey  => itemkey,
                                    aname    => 'INTG_USER_NAME',
                                    avalue   => x_user_name
                                    -- x_item_cost
                                    );
          wf_engine.setitemattrtext(itemtype => itemtype,
                                    itemkey  => itemkey,
                                    aname    => 'XX_APP_BODY',
                                    avalue   => x_app_body);
          wf_engine.setitemattrtext(itemtype => itemtype,
                                    itemkey  => itemkey,
                                    aname    => 'XX_USER_BODY',
                                    avalue   => x_user_body);
          wf_engine.setitemattrtext(itemtype => itemtype,
                                    itemkey  => itemkey,
                                    aname    => 'XX_APP_TITLE',
                                    avalue   => x_app_title);
          wf_engine.setitemattrtext(itemtype => itemtype,
                                    itemkey  => itemkey,
                                    aname    => 'XX_USER_TITLE',
                                    avalue   => x_user_title);
        ELSE
          resultout := 'COMPLETE:NA';
        END IF;
      END LOOP;
    END IF;

    RETURN;
  EXCEPTION
    WHEN e_super_not_found THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_validate_line_price ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : Supervisor Not Found ');
      RAISE;
    WHEN e_emf_variables THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_validate_line_price ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || x_err_msg);
      RAISE;
    WHEN e_hold_error THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_validate_line_price ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || x_err_msg);
      RAISE;
    WHEN e_hold_id THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_validate_line_price ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : Price Over Ride Hold Not Define In Oracle');
      RAISE;
    WHEN e_item_cost THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_validate_line_price ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : Item Cost Not Define At Shipping Organization');
      RAISE;
    WHEN OTHERS THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_validate_line_price ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || SQLERRM);
      oe_standard_wf.add_error_activity_msg(p_actid    => actid,
                                            p_itemtype => itemtype,
                                            p_itemkey  => itemkey);
      oe_standard_wf.save_messages;
      oe_standard_wf.clear_msg_context;
      RAISE;
  END xx_om_validate_line_price;

  -- =================================================================================
  -- Name           : xx_om_gen_msg_body
  -- Description    : Procedure To generate msg for approver/requestor
  -- Parameters description       :
  --
  -- No user parameter
  -- ==================================================================================
  PROCEDURE xx_om_gen_msg_body(itemtype  IN VARCHAR2,
                               itemkey   IN VARCHAR2,
                               actid     IN NUMBER,
                               funcmode  IN VARCHAR2,
                               resultout IN OUT NOCOPY VARCHAR2) IS
    v_username        VARCHAR(240);
    v_supervisor_id   NUMBER;
    v_supervisor_name VARCHAR2(240);
    x_cust_name       VARCHAR2(240);
    x_order_type      VARCHAR2(240);
    x_order_number    VARCHAR2(240);
    x_line_number     VARCHAR2(240);
    x_usp             NUMBER;
    x_ulp             NUMBER;
    x_item_num        VARCHAR2(240);
    x_margin_cost     VARCHAR2(240);
    x_app_body        VARCHAR2(2000);
    x_user_body       VARCHAR2(2000);
    x_app_title       VARCHAR2(1000);
    x_user_title      VARCHAR2(1000);
    x_item_id         NUMBER;
    x_inv_org         NUMBER;
    x_item_cost       NUMBER;
    x_tran_curr       VARCHAR2(10);
    x_func_curr       VARCHAR2(10);
    x_conv_date       DATE;
    x_conv_type_code  VARCHAR2(240);
    x_conv_rate       NUMBER;

    CURSOR c_fetch_msg_dets IS
      SELECT hp.party_name,
             ot.NAME,
             oeh.order_number,
             oel.line_number,
             oel.unit_selling_price,
             oel.unit_list_price,
             msi.segment1,
             oel.inventory_item_id,
             oel.ship_from_org_id,
             oeh.transactional_curr_code,
             gll.currency_code,
             TRUNC(oeh.ordered_date),
             oeh.conversion_type_code
        FROM oe_order_headers_all oeh,
             oe_order_lines_all oel,
             oe_transaction_types_tl ot,
             mtl_system_items_b msi,
             hz_cust_accounts hca,
             hz_parties hp,
             (SELECT parameter_value, org_id
                FROM oe_sys_parameters_all osp
               WHERE osp.parameter_code = 'MASTER_ORGANIZATION_ID') t,
             hr_operating_units hou,
             gl_ledgers gll
       WHERE 1 = 1
         AND t.org_id = oel.org_id
         AND oeh.header_id = oel.header_id
         AND oel.line_id = TO_NUMBER(itemkey)
         AND oeh.order_type_id = ot.transaction_type_id
         AND ot.LANGUAGE = USERENV('LANG')
         AND msi.organization_id = oel.ship_from_org_id
         AND msi.inventory_item_id = oel.inventory_item_id
         AND hca.cust_account_id = oel.sold_to_org_id
         AND hca.party_id = hp.party_id
         AND oeh.org_id = hou.organization_id
         AND hou.set_of_books_id = gll.ledger_id;

    CURSOR c_fetch_conv_rate(p_from_curr VARCHAR2, p_to_curr VARCHAR2, p_conv_date DATE, p_conv_type VARCHAR2) IS
      SELECT conversion_rate
        FROM gl_daily_rates
       WHERE from_currency = p_from_curr
         AND to_currency = p_to_curr
         AND UPPER(conversion_type) = UPPER(p_conv_type)
         AND conversion_date = p_conv_date;

    -- Cursor to fetch item cost at Ship From Org
    CURSOR c_item_cost(p_inventory_item_id NUMBER, p_ship_from_org_id NUMBER) IS
      SELECT NVL(item_cost, 0)
        FROM cst_item_cost_type_v
       WHERE inventory_item_id = p_inventory_item_id
         AND organization_id = p_ship_from_org_id
         AND UPPER(cost_type) = 'FROZEN';
  BEGIN

    IF itemtype = 'OEOL' /* Added IF condition for TIC#006964 on 05/Jun/2014 */
    THEN

       OPEN c_fetch_msg_dets;

       FETCH c_fetch_msg_dets
         INTO x_cust_name, x_order_type, x_order_number, x_line_number, x_usp, x_ulp, x_item_num, x_item_id, x_inv_org, x_tran_curr, x_func_curr, x_conv_date, x_conv_type_code;

       CLOSE c_fetch_msg_dets;

       OPEN c_item_cost(x_item_id, x_inv_org);

       FETCH c_item_cost
         INTO x_item_cost;

       CLOSE c_item_cost;

       IF x_func_curr <> x_tran_curr THEN
         OPEN c_fetch_conv_rate(x_func_curr,
                                x_tran_curr,
                                x_conv_date,
                                x_conv_type_code);

         FETCH c_fetch_conv_rate
           INTO x_conv_rate;

         CLOSE c_fetch_conv_rate;

         x_item_cost := ROUND(x_item_cost * x_conv_rate, 2);
       END IF;

       IF x_item_cost <> 0 THEN
         x_margin_cost := ROUND(((x_usp - x_item_cost) / x_item_cost) * 100, 2) || '%';
       ELSE
         x_margin_cost := 'cannot be derived as Item Cost is 0 or not defined in Shipping Org';
       END IF;

       x_app_title  := 'Following order price change needs your approval -  Order Number ' ||
                       x_order_number || ' Order Line ' || x_line_number;
       x_app_body   := 'Please approve the following Price Override for the following order - ' ||
                       CHR(10) || 'Customer Name > ' || x_cust_name || CHR(10) ||
                       'Order Type > ' || x_order_type || CHR(10) ||
                       'Order Number > ' || x_order_number || CHR(10) ||
                       'Line Number > ' || x_line_number || CHR(10) ||
                       'Item Number > ' || x_item_num || CHR(10) ||
                       'Transaction Currency > ' || x_tran_curr || CHR(10) ||
                       'Unit Selling Price > ' || x_usp || CHR(10) ||
                       'Unit List Price > ' || x_ulp || CHR(10) ||
                       'Margin Cost > ' || x_margin_cost;
       x_user_title := 'Following order price change is rejected -  Order Number ' ||
                       x_order_number || ' Order Line ' || x_line_number;
       x_user_body  := 'Please correct the following Price Override for the following order - ' ||
                       CHR(10) || 'Customer Name > ' || x_cust_name || CHR(10) ||
                       'Order Type > ' || x_order_type || CHR(10) ||
                       'Order Number > ' || x_order_number || CHR(10) ||
                       'Line Number > ' || x_line_number || CHR(10) ||
                       'Item Number > ' || x_item_num || CHR(10) ||
                       'Transaction Currency > ' || x_tran_curr || CHR(10) ||
                       'Unit Selling Price > ' || x_usp || CHR(10) ||
                       'Unit List Price > ' || x_ulp || CHR(10) ||
                       'Margin Cost > ' || x_margin_cost;
       wf_engine.setitemattrtext(itemtype => itemtype,
                                 itemkey  => itemkey,
                                 aname    => 'XX_APP_BODY',
                                 avalue   => x_app_body);
       wf_engine.setitemattrtext(itemtype => itemtype,
                                 itemkey  => itemkey,
                                 aname    => 'XX_USER_BODY',
                                 avalue   => x_user_body);
       wf_engine.setitemattrtext(itemtype => itemtype,
                                 itemkey  => itemkey,
                                 aname    => 'XX_APP_TITLE',
                                 avalue   => x_app_title);
       wf_engine.setitemattrtext(itemtype => itemtype,
                                 itemkey  => itemkey,
                                 aname    => 'XX_USER_TITLE',
                                 avalue   => x_user_title);
       resultout := 'COMPLETE:COMPLETE';

    ELSIF itemtype = 'OEOH'  /* Added IF condition for TIC#006964 on 05/Jun/2014 */
    THEN
       resultout := 'COMPLETE:COMPLETE';
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      resultout := 'COMPLETE:COMPLETE';
  END xx_om_gen_msg_body;
  -- =================================================================================
  -- Name           : xx_om_ame_nxt_appr
  -- Description    : Procedure To fetch the next AME approver
  -- Parameters description       :
  --
  -- No user parameter
  -- ==================================================================================
  PROCEDURE xx_om_ame_nxt_appr(itemtype  IN VARCHAR2,
                               itemkey   IN VARCHAR2,
                               actid     IN NUMBER,
                               funcmode  IN VARCHAR2,
                               resultout IN OUT NOCOPY VARCHAR2) IS
    x_chr_item_key       VARCHAR2(200);
    x_chr_apprvl_out_put VARCHAR2(100);
    x_next_approver      ame_util.approverstable2;
    x_chr_approver_id    VARCHAR2(10);
    x_chr_appr_name      VARCHAR2(50);
    x_item_index         ame_util.idlist;
    x_item_class         ame_util.stringlist;
    x_item_id            ame_util.stringlist;
    x_item_source        ame_util.longstringlist;
    x_ame_show_msg_flag  VARCHAR2(5);
    x_common_msg_body    VARCHAR2(3000);
    x_common_msg_sub     VARCHAR2(1000);
    x_order_number       NUMBER;
    x_rma_value          NUMBER;
    x_effective_days     NUMBER;
    x_escalation_days    NUMBER;
  BEGIN

    x_order_number := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                  itemkey  => itemkey,
                                                  aname    => 'XX_OM_ORD_NUM');
    IF funcmode = 'RUN' THEN
      -- BEGIN
      xx_intg_common_pkg.get_process_param_value('XXOMPRICEOVERRIDEEXT',
                                                 'G_TRANSACTION_TYPE_NAME',
                                                 g_chr_transaction_type);

      --
      -- Getting next approver using AME_API2.GETNEXTAPPROVERS1 procedure
      --
      AME_API2.GETNEXTAPPROVERS1(applicationidin              => 660 --Order Management APP ID
                                ,
                                 transactiontypein            => g_chr_transaction_type --short name of AME Trans
                                ,
                                 transactionidin              => itemKey --l_chr_item_key  --unique ID that can be passed to AME
                                ,
                                 flagapproversasnotifiedin    => ame_util.booleantrue,
                                 approvalprocesscompleteynout => x_chr_apprvl_out_put,
                                 nextapproversout             => x_next_approver,
                                 itemindexesout               => x_item_index,
                                 itemidsout                   => x_item_id,
                                 itemclassesout               => x_item_class,
                                 itemsourcesout               => x_item_source);

      IF x_chr_apprvl_out_put = 'N' then
        IF x_next_approver.COUNT > 0 THEN
          x_chr_approver_id := x_next_approver(1).orig_system_id;
          x_chr_appr_name   := x_next_approver(1).NAME;
          wf_engine.setItemAttrText(itemtype => itemType,
                                    itemkey  => itemKey,
                                    aname    => 'INTG_APP_NAME',
                                    avalue   => x_chr_appr_name);

          -- Approver from the AME , will be used while updating the AME transaction.
          wf_engine.setItemAttrText(itemtype => itemType,
                                    itemkey  => itemKey,
                                    aname    => 'XX_INTG_AME_APP_NAME',
                                    avalue   => x_chr_appr_name);

          xx_intg_common_pkg.get_process_param_value('XXOMPRICEOVERRIDEEXT',
                                                     'ESCALATION_DAYS',
                                                     x_escalation_days);
          x_effective_days := xx_om_return_ord_ame.calc_timeout_days(nvl(x_escalation_days,
                                                                         1));

          wf_engine.setItemAttrnumber(itemtype => itemType,
                                      itemkey  => itemKey,
                                      aname    => 'INTG_TIMEOUT_DAYS',
                                      avalue   => x_effective_days);

          resultout := 'APPROVAL';
          RETURN;
        END IF;
      ELSE
        resultout := 'NO_APPROVER';
        RETURN;
      END IF;
    ELSE
      resultout := 'NO_APPROVER';
      RETURN;
    END IF;
  END xx_om_ame_nxt_appr;

  --------------------------------------------------------------------------------------------------

  PROCEDURE upd_appr_status(p_itemType   IN VARCHAR2,
                            p_itemKey    IN VARCHAR2,
                            p_activityId IN NUMBER,
                            funmode      IN VARCHAR2,
                            result       OUT NOCOPY VARCHAR2) AS
    x_chr_approver_name VARCHAR(100);
    x_order_number      NUMBER;
    -- x_rma_value                 NUMBER;
    x_common_msg_body VARCHAR2(3000);
    x_common_msg_sub  VARCHAR2(1000);

  BEGIN

    IF funmode = 'RUN' THEN
      --g_num_err_loc_code := '00002';
      x_order_number := wf_engine.getitemattrnumber(itemtype => p_itemType,
                                                    itemkey  => p_itemKey,
                                                    aname    => 'XX_OM_ORD_NUM');

      x_chr_approver_name := wf_engine.getItemAttrText(itemtype => p_itemType,
                                                       itemkey  => p_itemKey,
                                                       aname    => 'XX_INTG_AME_APP_NAME');

      xx_intg_common_pkg.get_process_param_value('XXOMPRICEOVERRIDEEXT',
                                                 'G_TRANSACTION_TYPE_NAME',
                                                 g_chr_transaction_type);

      AME_API2.UPDATEAPPROVALSTATUS2(applicationidin   => 660,
                                     transactiontypein => g_chr_transaction_type --'RMAA',
                                    ,
                                     transactionidin   => p_itemKey,
                                     approvalstatusin  => ame_util.approvedstatus,
                                     approvernamein    => x_chr_approver_name);
      result := 'Y';
    END IF;

    IF (funmode = 'CANCEL') THEN
      result := 'N';
      RETURN;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      result := 'N';
      WF_CORE.CONTEXT(pkg_name  => 'XX_OM_LINE_PRICE_CHECK',
                      proc_name => 'UPD_APPR_STATUS',
                      arg1      => SUBSTR(SQLERRM, 1, 80),
                      arg2      => p_itemType,
                      arg3      => p_itemKey,
                      arg4      => TO_CHAR(p_activityId),
                      arg5      => funmode,
                      arg6      => 'error location:' || '000800');
      RAISE;
  END upd_appr_status;
  --- Added on 26-Feb-2014 -- To Solve Line Issue After Booking Event
  PROCEDURE upd_lnr_appr_status(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout IN OUT NOCOPY VARCHAR2) AS
    x_chr_approver_name VARCHAR(100);
    x_order_number      NUMBER;
    -- x_rma_value                 NUMBER;
    x_common_msg_body VARCHAR2(3000);
    x_common_msg_sub  VARCHAR2(1000);

  BEGIN

    IF funcmode = 'RUN' THEN
      --g_num_err_loc_code := '00002';
      x_order_number := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                    itemkey  => itemkey,
                                                    aname    => 'XX_OM_ORD_NUM');

      x_chr_approver_name := wf_engine.getItemAttrText(itemtype => itemtype,
                                                       itemkey  => itemkey,
                                                       aname    => 'XX_INTG_AME_APP_NAME');

      xx_intg_common_pkg.get_process_param_value('XXOMPRICEOVERRIDEEXT',
                                                 'G_TRANSACTION_TYPE_NAME',
                                                 g_chr_transaction_type);

      AME_API2.UPDATEAPPROVALSTATUS2(applicationidin   => 660,
                                     transactiontypein => g_chr_transaction_type --'RMAA',
                                    ,
                                     transactionidin   => itemkey,
                                     approvalstatusin  => ame_util.approvedstatus,
                                     approvernamein    => x_chr_approver_name);
      resultout := 'Y';
    END IF;

    IF (funcmode = 'CANCEL') THEN
      resultout := 'N';
      RETURN;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      resultout := 'N';
      WF_CORE.CONTEXT(pkg_name  => 'XX_OM_LINE_PRICE_CHECK',
                      proc_name => 'upd_lnr_appr_status',
                      arg1      => SUBSTR(SQLERRM, 1, 80),
                      arg2      => itemtype,
                      arg3      => itemkey,
                      arg4      => TO_CHAR(actid),
                      arg5      => funcmode,
                      arg6      => 'error location:' || '000800');
      RAISE;
  END upd_lnr_appr_status;

  --------------------------------------------------------------------------------------------------

  PROCEDURE upd_rejected_status(p_itemType   IN VARCHAR2,
                                p_itemKey    IN VARCHAR2,
                                p_activityId IN NUMBER,
                                funmode      IN VARCHAR2,
                                result       OUT NOCOPY VARCHAR2) AS
    x_chr_approver_name VARCHAR(100);
    x_order_number      NUMBER;
    --x_rma_value                 NUMBER;
    x_common_msg_body VARCHAR2(3000);
    x_common_msg_sub  VARCHAR2(1000);

  BEGIN

    IF funmode = 'RUN' THEN
      x_order_number := wf_engine.getitemattrnumber(itemtype => p_itemType,
                                                    itemkey  => p_itemKey,
                                                    aname    => 'XX_OM_ORD_NUM');

      --g_num_err_loc_code := '00003';
      x_chr_approver_name := wf_engine.getItemAttrText(itemtype => p_itemType,
                                                       itemkey  => p_itemKey,
                                                       aname    => 'XX_INTG_AME_APP_NAME');

      xx_intg_common_pkg.get_process_param_value('XXOMPRICEOVERRIDEEXT',
                                                 'G_TRANSACTION_TYPE_NAME',
                                                 g_chr_transaction_type);

      AME_API2.UPDATEAPPROVALSTATUS2(applicationidin   => 660,
                                     transactiontypein => g_chr_transaction_type,
                                     transactionidin   => p_itemKey,
                                     approvalstatusin  => ame_util.rejectstatus,
                                     approvernamein    => x_chr_approver_name);
      result := 'Y';

    END IF;

    IF funmode = 'CANCEL' THEN
      result := 'N';
      RETURN;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      result := 'N';
      WF_CORE.CONTEXT(pkg_name  => 'XX_OM_LINE_PRICE_CHECK',
                      proc_name => 'UPD_REJECTED_STATUS',
                      arg1      => SUBSTR(SQLERRM, 1, 80),
                      arg2      => p_itemType,
                      arg3      => p_itemKey,
                      arg4      => TO_CHAR(p_activityId),
                      arg5      => funmode,
                      arg6      => 'error location:' || '000900');
      RAISE;
  END upd_rejected_status;
  --------------------------------------------------------------------------------------------------

  PROCEDURE clear_all_approvals(p_itemType   IN VARCHAR2,
                                p_itemKey    IN VARCHAR2,
                                p_activityId IN NUMBER,
                                funmode      IN VARCHAR2,
                                result       OUT NOCOPY VARCHAR2) AS
    x_escalation_days NUMBER;
    x_effective_days  NUMBER;
  BEGIN

    xx_intg_common_pkg.get_process_param_value('XXOMPRICEOVERRIDEEXT',
                                               'G_TRANSACTION_TYPE_NAME',
                                               g_chr_transaction_type);

    xx_intg_common_pkg.get_process_param_value('XXOMPRICEOVERRIDEEXT',
                                               'ESCALATION_DAYS',
                                               x_escalation_days);

    x_effective_days := xx_om_return_ord_ame.calc_timeout_days(x_escalation_days);
    wf_engine.setItemAttrnumber(itemtype => p_itemType,
                                itemkey  => p_itemKey,
                                aname    => 'INTG_TIMEOUT_DAYS',
                                avalue   => x_effective_days);

    AME_API2.clearAllApprovals(applicationIdIn   => 660,
                               transactionTypeIn => g_chr_transaction_type,
                               transactionIdIn   => p_itemKey);
  EXCEPTION
    WHEN OTHERS THEN
      result := 'N';
      WF_CORE.CONTEXT(pkg_name  => 'XX_OM_LINE_PRICE_CHECK',
                      proc_name => 'CLEAR_ALL_APPROVALS',
                      arg1      => SUBSTR(SQLERRM, 1, 80),
                      arg2      => p_itemType,
                      arg3      => p_itemKey,
                      arg4      => TO_CHAR(p_activityId),
                      arg5      => funmode,
                      arg6      => 'error location:' || '0001000');
      RAISE;

  END clear_all_approvals;

  --------------------------------------------------------------------------------------------------
  PROCEDURE get_next_hrmgr(p_itemType   IN VARCHAR2,
                           p_itemKey    IN VARCHAR2,
                           p_activityId IN NUMBER,
                           funmode      IN VARCHAR2,
                           result       OUT NOCOPY VARCHAR2) AS
    x_appr_usrname    VARCHAR2(50);
    x_order_number    NUMBER;
    x_esc_mgr         VARCHAR2(50);
    x_appr_person_id  NUMBER;
    x_esc_mgr_id      NUMBER;
    x_escalation_days NUMBER;
    x_effective_days  NUMBER;
    x_counter         NUMBER := 1;
    x_day_date        VARCHAR2(20);
  BEGIN
    IF funmode = 'RUN' THEN
      x_appr_usrname := wf_engine.getitemattrtext(itemtype => p_itemType,
                                                  itemkey  => p_itemKey,
                                                  aname    => 'INTG_APP_NAME');

      x_order_number := wf_engine.getitemattrnumber(itemtype => p_itemType,
                                                    itemkey  => p_itemKey,
                                                    aname    => 'XX_OM_ORD_NUM');

      xx_intg_common_pkg.get_process_param_value('XXOMPRICEOVERRIDEEXT',
                                                 'ESCALATION_DAYS',
                                                 x_escalation_days);

      BEGIN
        /*SELECT distinct person_id
               INTO x_appr_person_id
         FROM fnd_user fu, per_all_people_f paf
        WHERE paf.person_id = fu.employee_id
          AND SYSDATE BETWEEN paf.effective_start_date AND paf.effective_end_date
                AND fu.user_name = x_appr_usrname;*/
        SELECT orig_system_id
          INTO x_appr_person_id
          FROM wf_users
         WHERE name = x_appr_usrname
           AND orig_system = 'PER';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          result := 'N';
          --g_num_err_loc_code:=110;
          WF_CORE.CONTEXT(pkg_name  => 'XX_OM_LINE_PRICE_CHECK',
                          proc_name => 'GET_NEXT_HRMGR',
                          arg1      => SUBSTR(SQLERRM, 1, 80),
                          arg2      => p_itemType,
                          arg3      => p_itemKey,
                          arg4      => TO_CHAR(p_activityId),
                          arg5      => funmode,
                          arg6      => 'error location:' || '0001100');
          RAISE;
      END;

      BEGIN
        SELECT DISTINCT Pafe.supervisor_id
          INTO x_esc_mgr_id
          FROM Per_All_Assignments_f    pafe,
               Per_All_People_f         ppfs,
               Per_All_Assignments_f    pafs,
               per_person_types_v       ppts,
               per_person_type_usages_f pptu
         WHERE pafe.person_id = x_appr_person_id
           AND Trunc(SYSDATE) BETWEEN pafe.Effective_Start_Date AND
               pafe.Effective_End_Date
           AND pafe.Primary_Flag = 'Y'
           AND pafe.Assignment_Type IN ('E', 'C')
           AND ppfs.Person_Id = pafe.Supervisor_Id
           AND Trunc(SYSDATE) BETWEEN ppfs.Effective_Start_Date AND
               ppfs.Effective_End_Date
           AND Pafs.Person_Id = ppfs.Person_Id
           AND Trunc(SYSDATE) BETWEEN pafs.Effective_Start_Date AND
               pafs.Effective_End_Date
           AND pafs.Primary_Flag = 'Y'
           AND pafs.Assignment_Type IN ('E', 'C')
           AND pptu.Person_Id = ppfs.Person_Id
           AND ppts.person_type_id = pptu.person_type_id
           AND ppts.System_Person_Type IN ('EMP', 'EMP_APL', 'CWK');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          x_esc_mgr_id := x_appr_person_id;
      END;

      BEGIN
        SELECT name
          INTO x_esc_mgr
          FROM wf_users
         WHERE orig_system_id = x_esc_mgr_id
           AND orig_system = 'PER';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          result := 'N';
          --g_num_err_loc_code:=114;
          WF_CORE.CONTEXT(pkg_name  => 'XX_OM_LINE_PRICE_CHECK',
                          proc_name => 'GET_NEXT_HRMGR',
                          arg1      => SUBSTR(SQLERRM, 1, 80),
                          arg2      => p_itemType,
                          arg3      => p_itemKey,
                          arg4      => TO_CHAR(p_activityId),
                          arg5      => funmode,
                          arg6      => 'error location:' || '0001200');
          RAISE;
      END;
      x_effective_days := xx_om_return_ord_ame.calc_timeout_days(x_escalation_days);

      wf_engine.setItemAttrText(itemtype => p_itemType,
                                itemkey  => p_itemKey,
                                aname    => 'INTG_APP_NAME',
                                avalue   => x_esc_mgr);
      wf_engine.setItemAttrnumber(itemtype => p_itemType,
                                  itemkey  => p_itemKey,
                                  aname    => 'INTG_TIMEOUT_DAYS',
                                  avalue   => x_effective_days);
      result := 'Y';
    END IF;

    IF funmode = 'CANCEL' THEN
      result := 'N';
      RETURN;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      result := 'N';
      WF_CORE.CONTEXT(pkg_name  => 'XX_OM_LINE_PRICE_CHECK',
                      proc_name => 'GET_NEXT_HRMGR',
                      arg1      => SUBSTR(SQLERRM, 1, 80),
                      arg2      => p_itemType,
                      arg3      => p_itemKey,
                      arg4      => TO_CHAR(p_activityId),
                      arg5      => funmode,
                      arg6      => 'error location:' || '0001300');
      RAISE;
  END get_next_hrmgr;
  --- Added on 26-Feb-2014
  -- =================================================================================
  -- Name           : xx_om_chk_prcovr_hold_header
  -- Description    : Procedure To Check For any Manual Price Override at Line Level
  -- Parameters description       :
  --
  -- itemtype                    : Parameter To Store itemtype (IN)
  -- itemkey                     : Parameter To Store itemkey  (IN)
  -- actid                       : Parameter To Store actid    (IN)
  -- funcmode                    : Parameter To Store funcmode (IN)
  -- resultout                   : Parameter To Store resultout(IN OUT)
  -- ==============================================================================
  PROCEDURE xx_om_chk_prcovr_hold_header(itemtype  IN VARCHAR2,
                                         itemkey   IN VARCHAR2,
                                         actid     IN NUMBER,
                                         funcmode  IN VARCHAR2,
                                         resultout IN OUT NOCOPY VARCHAR2) IS
    x_order_tbl       oe_holds_pvt.order_tbl_type;
    x_hold_source_rec oe_holds_pvt.hold_source_rec_type;

    x_item_cost           NUMBER := 0;
    x_hold_id             NUMBER;
    x_price_adjustment_id NUMBER;
    x_user_id             NUMBER;
    x_msg_count           NUMBER;
    x_super_suer_id       NUMBER;
    x_margin_cost         VARCHAR2(240);
    x_super_suer_name     VARCHAR2(100);
    x_err_msg             VARCHAR2(1000);
    x_user_name           VARCHAR2(100);
    x_return_status       VARCHAR2(100);
    x_msg_data            VARCHAR2(100);
    x_hold_name           VARCHAR2(50);
    x_release_reason_code VARCHAR2(50);
    x_hold_type           VARCHAR2(50);
    x_item_type           VARCHAR2(50);
    x_cost_type           VARCHAR2(50);
    x_tran_curr           VARCHAR2(10);
    x_func_curr           VARCHAR2(10);
    x_conv_date           DATE;
    x_conv_type_code      VARCHAR2(240);
    e_item_cost EXCEPTION;
    e_hold_id EXCEPTION;
    e_hold_error EXCEPTION;
    e_emf_variables EXCEPTION;
    e_super_not_found EXCEPTION;
    x_cust_name    VARCHAR2(240);
    x_order_type   VARCHAR2(240);
    x_order_number VARCHAR2(240);
    x_item_num     VARCHAR2(240);
    x_app_body     VARCHAR2(2000);
    x_user_body    VARCHAR2(2000);
    x_app_title    VARCHAR2(1000);
    x_user_title   VARCHAR2(1000);
    x_conv_rate    NUMBER;
    x_hold_comment VARCHAR2(2000);
     x_max_line_num NUMBER;
     x_min_line_num NUMBER;

    -- Added 01-Oct-2012
    x_order_source_id NUMBER;
    x_line_type_id    NUMBER;
    --  x_exclude               VARCHAR2(1) := 'Y';
    x_ame_trx_type VARCHAR2(1) := 'Y';

    x_concat_line_num VARCHAR2(24000);

    CURSOR c_fetch_msg_dets IS
      SELECT hp.party_name,
             ot.NAME,
             oeh.order_number,
             oeh.transactional_curr_code,
             gll.currency_code,
             TRUNC(oeh.ordered_date),
             oeh.conversion_type_code,
             oeh.order_source_id,
             oeh.last_updated_by
        FROM oe_order_headers oeh,
             oe_transaction_types_tl ot,
             hz_cust_accounts hca,
             hz_parties hp,
             (SELECT parameter_value, org_id
                FROM oe_sys_parameters_all osp
               WHERE osp.parameter_code = 'MASTER_ORGANIZATION_ID') t,
             hr_operating_units hou,
             gl_ledgers gll
       WHERE 1 = 1
         AND t.org_id = oeh.org_id
         AND oeh.header_id = TO_NUMBER(itemkey)
         AND oeh.order_type_id = ot.transaction_type_id
         AND ot.LANGUAGE = USERENV('LANG')
         AND hca.cust_account_id = oeh.sold_to_org_id
         AND hca.party_id = hp.party_id
         AND oeh.org_id = hou.organization_id
         AND hou.set_of_books_id = gll.ledger_id;

    -- Cursor to fetch all the constant values from the emf table
    CURSOR c_emf_variables(p_parameter_name VARCHAR2) IS
      SELECT parameter_value
        FROM xx_emf_process_parameters xpp, xx_emf_process_setup xps
       WHERE 1 = 1
         AND xps.process_id = xpp.process_id
         AND xps.process_name = 'XXOMPRICEOVERRIDEEXT'
         AND UPPER(parameter_name) = UPPER(p_parameter_name)
         AND NVL(xpp.enabled_flag, 'Y') = 'Y'
         AND NVL(xps.enabled_flag, 'Y') = 'Y';

    -- Cursor to fetch line details of the SO
    CURSOR c_oe_order_lines(p_itemkey NUMBER) IS
      SELECT oel.line_id,
             oel.ship_from_org_id,
             oel.header_id,
             oel.order_source_id,
             oel.inventory_item_id,
             oel.unit_selling_price,
             oel.unit_list_price,
             oel.line_number,
             oeh.order_number,
             oel.last_updated_by
        FROM oe_order_lines oel, oe_order_headers oeh
       WHERE oeh.header_id = p_itemkey
         AND oeh.header_id = oel.header_id;

    -- Cursor to fetch HOLD ID
    CURSOR c_hold_id(p_hold_name VARCHAR2) IS
      SELECT hold_id
        FROM oe_hold_definitions
       WHERE NAME = p_hold_name
         AND type_code = 'HOLD'
         AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active, TRUNC(SYSDATE)) AND
             NVL(end_date_active, TRUNC(SYSDATE));

    -- Cursor to fetch Adjustment ID
    CURSOR c_adjustment_id(p_itemkey NUMBER) IS
      SELECT a.price_adjustment_id, b.line_number
        FROM oe_price_adjustments_v a, oe_order_lines b
       WHERE a.header_id = p_itemkey
         AND a.line_id = b.line_id
         AND a.change_reason_code = 'MANUAL'
         AND a.charge_type_code IS NULL
         AND a.override_allowed_flag = 'Y'
       UNION
      SELECT a.price_adjustment_id, -99 line_number
        FROM oe_price_adjustments_v a
       WHERE a.header_id = p_itemkey
         AND a.line_id  IS NULL
         AND a.charge_type_code IS NULL
         AND a.change_reason_code = 'MANUAL'
         AND a.override_allowed_flag = 'Y';

    -- Cursor to Exclude order type from AME approvals
    CURSOR c_order_trx_typ(p_itemkey IN NUMBER) IS
      SELECT NVL(ott.attribute3, 'Y')
        FROM oe_order_headers_all ooh, oe_transaction_types_all ott
       WHERE ooh.header_id = p_itemkey
         AND ooh.order_type_id = ott.transaction_type_id;

  BEGIN
    IF (funcmode = 'RUN') THEN
      x_concat_line_num     := Null;
      x_price_adjustment_id := Null;
      x_hold_comment        := Null;

      OPEN c_order_trx_typ(itemkey);
      FETCH c_order_trx_typ
        INTO x_ame_trx_type;
      CLOSE c_order_trx_typ;

      IF x_ame_trx_type = 'N' THEN
        resultout := 'COMPLETE:NA';
        RETURN;
      END IF;
      begin
      select max(line_number),min(line_number) into  x_max_line_num, x_min_line_num  from apps.oe_order_lines_all where header_id = TO_NUMBER(itemkey);
      exception when others then
      x_max_line_num :=0;
      end;


        --- Query to extract the adjustment id
      FOR rec_adjustment_id IN c_adjustment_id(itemkey) LOOP
        x_price_adjustment_id := rec_adjustment_id.price_adjustment_id;
        if x_max_line_num < 700 then
       IF rec_adjustment_id.line_number <> -99
        THEN
        x_concat_line_num     := x_concat_line_num || ',' || rec_adjustment_id.line_number;
        ELSE
        x_concat_line_num     := ',Header Level Price Override';
        END IF;
       elsif x_max_line_num > 700 then
       IF rec_adjustment_id.line_number <> -99 and rec_adjustment_id.line_number < (x_max_line_num - 32)
        THEN
        x_concat_line_num     := x_concat_line_num || ',' || rec_adjustment_id.line_number;
        ELSE
        x_concat_line_num     := ',Header Level Price Override';
        END IF;
        end if;
      END LOOP;

      --x_concat_line_num := substr(x_concat_line_num,1900);

      IF x_price_adjustment_id IS NOT NULL THEN

        x_concat_line_num := SUBSTR(x_concat_line_num,
                                    2,
                                    length(x_concat_line_num));

        IF  x_concat_line_num <> 'Header Level Price Override'
        THEN
        x_hold_comment := 'Line# On HOLD are ' || x_concat_line_num;
        ELSE
        x_hold_comment := x_concat_line_num;
        END IF;


        OPEN c_fetch_msg_dets;

        FETCH c_fetch_msg_dets
          INTO x_cust_name, x_order_type, x_order_number, x_tran_curr, x_func_curr, x_conv_date, x_conv_type_code, x_order_source_id, x_user_id;
        CLOSE c_fetch_msg_dets;

        --- Query to Extract Global Variable values from emf Table
        OPEN c_emf_variables(g_hdr_hold_name);

        FETCH c_emf_variables
          INTO x_hold_name;

        CLOSE c_emf_variables;

        BEGIN
          SELECT user_name
            INTO x_user_name
            FROM fnd_user
           WHERE user_id = x_user_id;
        EXCEPTION
          WHEN OTHERS THEN
            x_user_name := NULL;
        END;

        x_app_title  := 'Following order price change needs your approval -  Order Number ' ||
                        x_order_number;
        x_app_body   := 'Please approve the following Price Override for the following order - ' ||
                        CHR(10) || 'Customer Name > ' || x_cust_name ||
                        CHR(10) || 'Order Type > ' || x_order_type ||
                        CHR(10) || 'Order Number > ' || x_order_number ||
                        CHR(10) || 'Line Number > ' || x_concat_line_num;
        x_user_title := 'Following order price change is rejected -  Order Number ' ||
                        x_order_number;
        x_user_body  := 'Please correct the following Price Override for the following order - ' ||
                        CHR(10) || 'Customer Name > ' || x_cust_name ||
                        CHR(10) || 'Order Type > ' || x_order_type ||
                        CHR(10) || 'Order Number > ' || x_order_number ||
                        CHR(10) || 'Line Number > ' || x_concat_line_num;

        --- Query to Extract Hold Id
        OPEN c_hold_id(x_hold_name);

        FETCH c_hold_id
          INTO x_hold_id;

        CLOSE c_hold_id;

        IF x_hold_id IS NOT NULL THEN

          x_hold_source_rec                  := oe_holds_pvt.g_miss_hold_source_rec;
          x_hold_source_rec.hold_id          := x_hold_id;
          x_hold_source_rec.hold_entity_code := 'O';
          x_hold_source_rec.hold_entity_id   := TO_NUMBER(itemkey);
          x_hold_source_rec.header_id        := TO_NUMBER(itemkey);
          x_hold_source_rec.hold_comment     := x_hold_comment;

          BEGIN
            -- CALLING THE API TO APPLY HOLD ON EXISTING ORDER --
            oe_holds_pub.apply_holds(p_api_version      => 1.0,
                                     p_init_msg_list    => fnd_api.g_true,
                                     p_commit           => fnd_api.g_false,
                                     p_validation_level => fnd_api.g_valid_level_full,
                                     p_hold_source_rec  => x_hold_source_rec,
                                     x_return_status    => x_return_status,
                                     x_msg_count        => x_msg_count,
                                     x_msg_data         => x_msg_data);
          EXCEPTION
            WHEN OTHERS THEN
              x_err_msg := SUBSTR(SQLERRM, 1, 80);
              RAISE e_hold_error;
          END;

        END IF;

        wf_engine.setitemattrtext(itemtype => itemtype,
                                  itemkey  => itemkey,
                                  aname    => 'INTG_APP_NAME',
                                  avalue   => x_super_suer_name);
        wf_engine.setitemattrtext(itemtype => itemtype,
                                  itemkey  => itemkey,
                                  aname    => 'XX_INTG_SO_NUMBER',
                                  avalue   => x_order_number);
        wf_engine.setitemattrtext(itemtype => itemtype,
                                  itemkey  => itemkey,
                                  aname    => 'XX_INTG_LINE_NUMBER',
                                  avalue   => x_hold_comment);
        wf_engine.setitemattrtext(itemtype => itemtype,
                                  itemkey  => itemkey,
                                  aname    => 'INTG_USER_NAME',
                                  avalue   => x_user_name);
        wf_engine.setitemattrtext(itemtype => itemtype,
                                  itemkey  => itemkey,
                                  aname    => 'XX_APP_BODY',
                                  avalue   => x_app_body);
        wf_engine.setitemattrtext(itemtype => itemtype,
                                  itemkey  => itemkey,
                                  aname    => 'XX_USER_BODY',
                                  avalue   => x_user_body);
        wf_engine.setitemattrtext(itemtype => itemtype,
                                  itemkey  => itemkey,
                                  aname    => 'XX_APP_TITLE',
                                  avalue   => x_app_title);
        wf_engine.setitemattrtext(itemtype => itemtype,
                                  itemkey  => itemkey,
                                  aname    => 'XX_USER_TITLE',
                                  avalue   => x_user_title);
        resultout := 'COMPLETE:Y';
      ELSE
        resultout := 'COMPLETE:NA';
      END IF;
    END IF;

    RETURN;
  EXCEPTION
    WHEN e_emf_variables THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_chk_prcovr_hold_header ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || x_err_msg);
      RAISE;
    WHEN e_hold_error THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_chk_prcovr_hold_header ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || x_err_msg);
      RAISE;
    WHEN e_hold_id THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_chk_prcovr_hold_header ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : Price Over Ride Hold Not Define In Oracle');
      RAISE;


    WHEN OTHERS THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_chk_prcovr_hold_header ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || SQLERRM);
      RAISE;
  END xx_om_chk_prcovr_hold_header;
  --- Added on 26-Feb-2014
  -- =================================================================================
  -- Name           : xx_om_hdr_hold_approve
  -- Description    : Procedure To Release HOLD Applied on the SO Header due to
  --                  manuall price override , once approved by the supervisor
  -- Parameters description       :
  --
  -- itemtype                    : Parameter To Store itemtype (IN)
  -- itemkey                     : Parameter To Store itemkey  (IN)
  -- actid                       : Parameter To Store actid    (IN)
  -- funcmode                    : Parameter To Store funcmode (IN)
  -- resultout                   : Parameter To Store resultout(IN OUT)
  -- ==============================================================================
  PROCEDURE xx_om_hdr_hold_approve(itemtype  IN VARCHAR2,
                                   itemkey   IN VARCHAR2,
                                   actid     IN NUMBER,
                                   funcmode  IN VARCHAR2,
                                   resultout IN OUT NOCOPY VARCHAR2) IS
    x_order_tbl           oe_holds_pvt.order_tbl_type;
    x_hold_id             NUMBER;
    x_price_adjustment_id NUMBER;
    x_msg_count           NUMBER;
    x_app_user_id         NUMBER;
    x_err_msg             VARCHAR2(1000);
    x_return_status       VARCHAR2(100);
    x_msg_data            VARCHAR2(100);
    x_hold_name           VARCHAR2(50);
    x_release_reason_code VARCHAR2(50);
    x_hold_type           VARCHAR2(50);
    x_item_type           VARCHAR2(50);
    x_cost_type           VARCHAR2(50);
    e_hold_error EXCEPTION;
    e_emf_variables EXCEPTION;
    e_hold_id EXCEPTION;
    x_app_user_name VARCHAR2(50);

    -- Cursor to fetch all the constant values from the emf table
    CURSOR c_emf_variables(p_parameter_name VARCHAR2) IS
      SELECT parameter_value
        FROM xx_emf_process_parameters xpp, xx_emf_process_setup xps
       WHERE 1 = 1
         AND xps.process_id = xpp.process_id
         AND xps.process_name = 'XXOMPRICEOVERRIDEEXT'
         AND UPPER(parameter_name) = UPPER(p_parameter_name)
         AND NVL(xpp.enabled_flag, 'Y') = 'Y'
         AND NVL(xps.enabled_flag, 'Y') = 'Y';

    -- Cursor to fetch HOLD ID
    CURSOR c_hold_id(p_hold_name VARCHAR2) IS
      SELECT hold_id
        FROM oe_hold_definitions
       WHERE NAME = p_hold_name
         AND type_code = 'HOLD'
         AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active, TRUNC(SYSDATE)) AND
             NVL(end_date_active, TRUNC(SYSDATE));

    -- Cursor to fetch ADJUSTMENT ID
    CURSOR c_adjustment_id(p_itemkey NUMBER) IS
      SELECT price_adjustment_id
        FROM oe_price_adjustments_v
       WHERE header_id = p_itemkey
         AND change_reason_code = 'MANUAL'
         AND charge_type_code IS NULL
         AND override_allowed_flag = 'Y';
  BEGIN
    IF (funcmode = 'RUN') THEN
      x_app_user_name := wf_engine.getItemAttrText(itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'INTG_APP_NAME');

      BEGIN
        SELECT user_id
          INTO x_app_user_id
          FROM fnd_user
         WHERE user_name = x_app_user_name;
      EXCEPTION
        WHEN OTHERS THEN
          x_app_user_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                       itemkey  => itemkey,
                                                       aname    => 'USER_ID');
      END;

      x_price_adjustment_id := NULL;

      --- Query to extract the adjustment id
      OPEN c_adjustment_id(itemkey);

      FETCH c_adjustment_id
        INTO x_price_adjustment_id;

      CLOSE c_adjustment_id;

      IF x_price_adjustment_id IS NOT NULL THEN
        --- Query to extract constant values from the emf tables
        OPEN c_emf_variables(g_hdr_hold_name);

        FETCH c_emf_variables
          INTO x_hold_name;

        CLOSE c_emf_variables;

        OPEN c_emf_variables(g_release_reason_code);

        FETCH c_emf_variables
          INTO x_release_reason_code;

        CLOSE c_emf_variables;

        --- Query to Extract Hold Id
        OPEN c_hold_id(x_hold_name);

        FETCH c_hold_id
          INTO x_hold_id;

        CLOSE c_hold_id;

        x_order_tbl(1).header_id := itemkey;

        -- Call the API to release HOLD
        BEGIN
          oe_holds_pub.release_holds(p_api_version              => 1.0,
                                     p_init_msg_list            => fnd_api.g_true,
                                     p_commit                   => fnd_api.g_false,
                                     p_validation_level         => fnd_api.g_valid_level_full,
                                     p_order_tbl                => x_order_tbl,
                                     p_hold_id                  => x_hold_id,
                                     p_release_reason_code      => x_release_reason_code,
                                     p_release_comment          => NULL,
                                     p_check_authorization_flag => NULL,
                                     x_return_status            => x_return_status,
                                     x_msg_count                => x_msg_count,
                                     x_msg_data                 => x_msg_data);

          -- Update the approver ID
          UPDATE oe_hold_releases
             SET created_by      = x_app_user_id,
                 last_updated_by = x_app_user_id
           WHERE hold_source_id IN
                 (SELECT b.hold_source_id
                    FROM oe_order_holds_all  a,
                         oe_hold_sources_all b,
                         oe_hold_definitions c
                   WHERE a.header_id = itemkey
                     AND a.hold_source_id = b.hold_source_id
                     AND c.hold_id = b.hold_id
                     AND c.NAME = x_hold_name
                     AND c.type_code = 'HOLD'
                     AND TRUNC(SYSDATE) BETWEEN
                         NVL(c.start_date_active, TRUNC(SYSDATE)) AND
                         NVL(c.end_date_active, TRUNC(SYSDATE)));
        EXCEPTION
          WHEN OTHERS THEN
            x_err_msg := SUBSTR(SQLERRM, 1, 80);
            RAISE e_hold_error;
        END;
      END IF;
    END IF;

    IF (funcmode = 'CANCEL') THEN
      NULL;
      RETURN;
    END IF;

    resultout := 'COMPLETE:COMPLETE';
  EXCEPTION
    WHEN e_hold_error THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_hdr_hold_approve ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || x_err_msg);
      RAISE;
    WHEN e_emf_variables THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_hdr_hold_approve ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || x_err_msg);
      RAISE;
    WHEN e_hold_id THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_hdr_hold_approve ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : Price Over Ride Hold Not Define In Oracle');
      RAISE;
    WHEN OTHERS THEN
      wf_core.CONTEXT('xx_om_line_price_check',
                      'xx_om_hdr_hold_approve ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || SQLERRM);
      RAISE;
  END xx_om_hdr_hold_approve;
  --- Added on 26-Feb-2014
  FUNCTION hold_msg_display(p_header_id IN NUMBER) RETURN VARCHAR2 IS
    l_pre_msg varchar2(250);
    l_count   number;
  BEGIN
    l_pre_msg := Null;
    l_count   := 0;

    SELECT count(*)
      INTO l_count
      FROM oe_hold_definitions a, oe_hold_sources_all b
     WHERE a.NAME =
           xx_emf_pkg.get_paramater_value(g_process_name, g_hdr_hold_name)
       AND a.type_code = 'HOLD'
       AND TRUNC(SYSDATE) BETWEEN NVL(a.start_date_active, TRUNC(SYSDATE)) AND
           NVL(a.end_date_active, TRUNC(SYSDATE))
       AND b.hold_id = a.hold_id
       AND b.released_flag = 'N'
       AND b.hold_entity_id = p_header_id;

    IF l_count > 0 THEN
      l_pre_msg := 'Price Override Hold Has Been Applied On This Order.';
    ELSE
      l_pre_msg := Null;
    END IF;

    return l_pre_msg;

  EXCEPTION
    WHEN OTHERS THEN
      return l_pre_msg;
  END hold_msg_display;

--- Added on 02-Feb-2015
PROCEDURE xx_create_doc_wf
(
document_id     IN              VARCHAR2,
display_type    IN              VARCHAR2,
document        IN OUT NOCOPY   CLOB,
document_type   IN OUT NOCOPY   VARCHAR2
)
IS

lv_details         VARCHAR2 (32767);
amount             number;
l_der_doc_id       varchar2(100);

temp_document      clob;

rawBuff RAW(32000);
pos number;
charBuff varchar2(32000);
charBuff_size number;


    -- Cursor to fetch Adjustment ID
    CURSOR c_adjustment_id(p_doc_id in varchar2)
    IS
      SELECT a.price_adjustment_id, b.line_number,b.ordered_item,b.ordered_quantity,b.unit_list_price,b.unit_selling_price,a.adjusted_amount,c.description
        FROM oe_price_adjustments_v a, oe_order_lines_all b, mtl_system_items_b c
       WHERE a.header_id = to_number(p_doc_id)
         AND a.line_id = b.line_id
         AND a.change_reason_code = 'MANUAL'
         AND a.charge_type_code IS NULL
         AND a.override_allowed_flag = 'Y'
         AND c.organization_id = (select organization_id from org_organization_definitions where organization_code = 'MST')
         AND c.inventory_item_id = b.inventory_item_id
       UNION
      SELECT a.price_adjustment_id, -99 line_number,Null ordered_item,Null ordered_quantity,Null unit_list_price,Null unit_selling_price,Null adjusted_amount,Null description
        FROM oe_price_adjustments_v a
       WHERE a.header_id =  to_number(p_doc_id)
         AND a.line_id  IS NULL
         AND a.charge_type_code IS NULL
         AND a.change_reason_code = 'MANUAL'
         AND a.override_allowed_flag = 'Y'
         ORDER BY 2 asc;


    CURSOR c_fetch_msg_dets(p_doc_id in varchar2)
    IS
      SELECT hp.party_name,
             ot.NAME,
             oeh.order_number,
             oeh.transactional_curr_code,
             gll.currency_code,
             TRUNC(oeh.ordered_date),
             oeh.conversion_type_code,
             oeh.order_source_id,
             oeh.last_updated_by
        FROM oe_order_headers_all oeh,
             oe_transaction_types_tl ot,
             hz_cust_accounts_all hca,
             hz_parties hp,
             (SELECT parameter_value, org_id
                FROM oe_sys_parameters_all osp
               WHERE osp.parameter_code = 'MASTER_ORGANIZATION_ID') t,
             hr_operating_units hou,
             gl_ledgers gll
       WHERE 1 = 1
         AND t.org_id = oeh.org_id
         AND oeh.header_id = to_number(p_doc_id)
         AND oeh.order_type_id = ot.transaction_type_id
         AND ot.LANGUAGE = USERENV('LANG')
         AND hca.cust_account_id = oeh.sold_to_org_id
         AND hca.party_id = hp.party_id
         AND oeh.org_id = hou.organization_id
         AND hou.set_of_books_id = gll.ledger_id;


BEGIN

BEGIN
SELECT SUBSTR(document_id,1,INSTR(document_id,'-',1)-1)
INTO l_der_doc_id
FROM DUAl;

END;

DBMS_LOB.createtemporary (temp_document, FALSE ,dbms_lob.call);

FOR rec_fetch_msg_dets IN c_fetch_msg_dets(l_der_doc_id)
LOOP

lv_details :=
'<table border="0" cellpadding="0" cellspacing="0">'
||'    <tbody>    '
||'        <tr>   '
||'            <td colspan="2" valign="top" width="638"> '
||'                <p> <span style="font-family:Times New Roman,serif;">'
||'                    Please approve the following Price Override for the following order - '
||'                </span> </p> '
||'            </td> '
||'        </tr>'
||'        <tr>'
||'            <td valign="top" width="121">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||'                    Customer Name:'
||'                </span> </p>'
||'            </td>'
||'            <td valign="top" width="517">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||rec_fetch_msg_dets.party_name
||'                </span> </p>'
||'            </td>'
||'        </tr>'
||'        <tr>'
||'            <td valign="top" width="121">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||'                    Order Type:'
||'                </span> </p>'
||'            </td>'
||'            <td valign="top" width="517">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||rec_fetch_msg_dets.NAME
||'                </span> </p>'
||'            </td>'
||'        </tr>'
||'        <tr>'
||'            <td valign="top" width="121">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||'                    Order Number:'
||'                </span> </p>'
||'           </td>'
||'            <td valign="top" width="517">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||rec_fetch_msg_dets.order_number
||'                </span> </p>'
||'            </td>'
||'        </tr>'
||'        <tr>'
||'            <td valign="top" width="121">'
||'            </td>'
||'            <td valign="top" width="517">'
||'            </td>'
||'        </tr>'
||'    </tbody>'
||'</table>';
END LOOP;

dbms_lob.writeappend(temp_document,length(lv_details),lv_details);
lv_details := '';

lv_details :=
'<table border="1" cellpadding="0" cellspacing="0"> '
||'    <tbody>'
||'        <tr>'
||'            <td valign="top" width="67">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||'                    Line Number'
||'                </span> </p>'
||'            </td>'
||'            <td valign="top" width="84">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||'                    Item'
||'                </span> </p>'
||'            </td>'
||'            <td valign="top" width="500">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||'                    Description'
||'                </span> </p>'
||'            </td>'
||'            <td valign="top" width="72">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||'                    Quantity'
||'                </span> </p>'
||'            </td>'
||'            <td valign="top" width="78">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||'                    Original List Price'
||'                </span> </p>'
||'            </td>'
||'            <td valign="top" width="73">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||'                    Selling Price'
||'                </span> </p>'
||'            </td>'
||'            <td valign="top" width="90">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||'                    Adjusted Amount'
||'                </span> </p>'
||'            </td>'
||'        </tr>';

dbms_lob.writeappend(temp_document,length(lv_details),lv_details);
lv_details := '';

FOR rec_adjustment_id IN c_adjustment_id(l_der_doc_id)
LOOP
lv_details :=
'        <tr>'
||'            <td valign="top" width="67">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||rec_adjustment_id.line_number
||'                </span> </p>'
||'            </td>'
||'            <td valign="top" width="84">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||rec_adjustment_id.ordered_item
||'                </span> </p>'
||'            </td>'
||'            <td valign="top" width="500">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||rec_adjustment_id.description
||'                </span> </p>'
||'            </td>'
||'            <td valign="top" width="72">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||rec_adjustment_id.ordered_quantity
||'                </span> </p>'
||'            </td>'
||'            <td valign="top" width="78">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||rec_adjustment_id.unit_list_price
||'                </span> </p>'
||'            </td>'
||'            <td valign="top" width="73">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||rec_adjustment_id.unit_selling_price
||'                </span> </p>'
||'            </td>'
||'            <td valign="top" width="90">'
||'                <p> <span style="font-family:Times New Roman,serif;">'
||rec_adjustment_id.adjusted_amount
||'                </span> </p>'
||'            </td>'
||'        </tr>';
dbms_lob.writeappend(temp_document,length(lv_details),lv_details);
lv_details := '';
END LOOP;


lv_details :=
'    </tbody>'
||'</table>';

dbms_lob.writeappend(temp_document,length(lv_details),lv_details);
lv_details := '';

DBMS_LOB.createtemporary (document, FALSE ,dbms_lob.call);
amount := dbms_lob.getLength(temp_document);
dbms_lob.copy(document, temp_document, amount, 1, 1);

document_type := 'text/html';

EXCEPTION
WHEN OTHERS THEN
  document := '<H4>Error ' || SQLERRM || '</H4>';
  document_type := 'text/html';
END xx_create_doc_wf;

--- Added on 02-Feb-2015
procedure xx_doc_call
(
itemtype in varchar2,
itemkey in varchar2,
actid in number,
funcmode in varchar2,
resultout out varchar2
)
IS

v_document_id clob;
v_itemkey     number;
l_doc_id   number;

BEGIN

select xx_prc_notification_s.nextval into l_doc_id from dual;

wf_engine.setitemattrdocument
(
itemtype      => itemtype,
itemkey       => itemkey,
aname         => 'XX_NOT_BODY',
documentid        => 'PLSQLCLOB:xx_om_line_price_check.xx_create_doc_wf/'|| to_char(itemkey) ||'-'|| to_char(l_doc_id)
);


end xx_doc_call;

END xx_om_line_price_check;
/
