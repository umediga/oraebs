DROP PACKAGE BODY APPS.XX_OM_LINE_HOLD_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OM_LINE_HOLD_PKG" 
----------------------------------------------------------------------
/* $Header: XXOMLINEHOLDWF.pkb 1.3 2013/05/13 12:00:00 dparida noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 21-Jun-2012
 File Name      : XXOMLINEHOLDWF.pkb
 Description    : This script creates the specification of the xx_om_line_price_check package

 Change History:

 Version Date        Name                     Remarks
 ------- ----------- ----                     ----------------------
 1.0     21-Jun-2012 IBM Development Team     Initial development.
 1.1     08-Feb-2013 Dhiren Parida            No Need to Apply Hold When customer NeT Price is 0
 1.2     07-May-2013 Bedabrata Bhattacharjee  Modification for GHX
 1.3     13-May-2013 Dhiren Parida            Add Logic for HOLD : Quarter End and Net Price at Header Level
 1.4     23-Oct-2013 Dhiren Parida            New HOLD Added : xx_om_hdr_dropship_hold_chk at Header Level
 1.5     07-May-2014 Bedabrata Bhattacharjee  removed Order Source check for Dup PO hold as per Case# 6244
*/
----------------------------------------------------------------------
 AS
  -- =================================================================================
  -- Name           : xx_om_dup_cust_po_chk
  -- Description    : Procedure To Check the count the DUP PO Reference and Apply The HOLD
  -- Parameters description       :
  --
  -- itemtype                    : Parameter To Store itemtype (IN)
  -- itemkey                     : Parameter To Store itemkey  (IN)
  -- actid                       : Parameter To Store actid    (IN)
  -- funcmode                    : Parameter To Store funcmode (IN)
  -- resultout                   : Parameter To Store resultout(IN OUT)
  -- ==============================================================================
  PROCEDURE xx_om_dup_cust_po_chk(itemtype  IN VARCHAR2,
                                  itemkey   IN VARCHAR2,
                                  actid     IN NUMBER,
                                  funcmode  IN VARCHAR2,
                                  resultout IN OUT NOCOPY VARCHAR2) IS
    x_order_tbl      oe_holds_pvt.order_tbl_type;
    x_hold_id        NUMBER;
    x_record_count   NUMBER;
    x_msg_count      NUMBER;
    x_hold_count     NUMBER;
    x_sold_to_org_id NUMBER;
    x_err_msg        VARCHAR2(1000);
    x_user_name      VARCHAR2(100);
    x_return_status  VARCHAR2(100);
    x_msg_data       VARCHAR2(100);
    x_source         VARCHAR2(100);
    x_cust_name      VARCHAR2(240);
    x_creation_date  DATE;
    x_order_number   VARCHAR2(100);
    e_hold_id EXCEPTION;
    e_hold_error EXCEPTION;
    x_hold_source_rec oe_holds_pvt.hold_source_rec_type;
  
    -- Cursor to fetch count for Dup PO attached to Other SO
    CURSOR c_oe_order_lines(p_itemkey NUMBER, p_source VARCHAR2) IS
      SELECT COUNT(*)
        FROM oe_order_headers_all ooha1
       WHERE (ooha1.cust_po_number, ooha1.sold_to_org_id) IN
             (SELECT ooha.cust_po_number, ooha.sold_to_org_id
                FROM oe_order_headers_all ooha
               WHERE ooha.header_id = p_itemkey
                 AND ooha.order_source_id IN
                     (SELECT order_source_id
                        FROM oe_order_sources
                       WHERE NAME LIKE '' || p_source || '%'
                         AND aia_enabled_flag = 'Y'
                         AND enabled_flag = 'Y')   -- Case# 6244
                         ) 
       /*  AND ooha1.order_source_id IN
             (SELECT order_source_id
                FROM oe_order_sources
               WHERE NAME LIKE '' || p_source || '%'
                 AND aia_enabled_flag = 'Y'
                 AND enabled_flag = 'Y') */  -- Case# 6244
         AND ooha1.order_number NOT IN
             (SELECT order_number
                FROM oe_order_headers_all
               WHERE header_id = p_itemkey);
  
    -- Cursor to fetch HOLD ID
    CURSOR c_hold_id(p_hold_name VARCHAR2, p_hold_type VARCHAR2, p_item_type VARCHAR2) IS
      SELECT hold_id
        FROM oe_hold_definitions
       WHERE NAME = p_hold_name
         AND type_code = p_hold_type
         AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active, TRUNC(SYSDATE)) AND
             NVL(end_date_active, TRUNC(SYSDATE))
         AND item_type = p_item_type;
  
    -- Cursor to check Dup Hold
    CURSOR c_hold_count(p_hold_id NUMBER, p_header_id NUMBER) IS
      SELECT COUNT(*)
        FROM oe_hold_sources_all
       WHERE hold_id = p_hold_id
         AND released_flag = 'Y'
         AND hold_entity_id = p_header_id;
  BEGIN
    IF (funcmode = 'RUN') THEN
      --- Query to Extract Line Details
      x_source := xx_emf_pkg.get_paramater_value(g_process_name,
                                                 g_order_source);
      wf_engine.setitemattrtext(itemtype,
                                itemkey,
                                'XX_OM_HDR_HOLD_NAME',
                                NULL);
    
      OPEN c_oe_order_lines(TO_NUMBER(itemkey), x_source);
    
      FETCH c_oe_order_lines
        INTO x_record_count;
    
      IF c_oe_order_lines%NOTFOUND THEN
        x_record_count := 0;
      END IF;
    
      CLOSE c_oe_order_lines;
    
      IF x_record_count > 0 THEN
        --- Query to Extract Hold Id
        OPEN c_hold_id(xx_emf_pkg.get_paramater_value(g_process_name,
                                                      g_hdr_hold_name),
                       xx_emf_pkg.get_paramater_value(g_process_name,
                                                      g_hold_type),
                       xx_emf_pkg.get_paramater_value(g_process_name,
                                                      g_hdr_item_type));
      
        FETCH c_hold_id
          INTO x_hold_id;
      
        IF c_hold_id%NOTFOUND THEN
          RAISE e_hold_id;
        END IF;
      
        CLOSE c_hold_id;
      
        OPEN c_hold_count(x_hold_id, TO_NUMBER(itemkey));
      
        FETCH c_hold_count
          INTO x_hold_count;
      
        IF c_hold_count%NOTFOUND THEN
          x_hold_count := 0;
        END IF;
      
        CLOSE c_hold_count;
      
        IF x_hold_count = 0 THEN
          x_hold_source_rec                  := oe_holds_pvt.g_miss_hold_source_rec;
          x_hold_source_rec.hold_id          := x_hold_id;
          x_hold_source_rec.hold_entity_code := 'O';
          x_hold_source_rec.hold_entity_id   := TO_NUMBER(itemkey);
          x_hold_source_rec.header_id        := TO_NUMBER(itemkey);
        
          BEGIN
            SELECT order_number, creation_date, sold_to_org_id
              INTO x_order_number, x_creation_date, x_sold_to_org_id
              FROM oe_order_headers_all
             WHERE header_id = TO_NUMBER(itemkey);
          EXCEPTION
            WHEN OTHERS THEN
              x_order_number   := NULL;
              x_creation_date  := NULL;
              x_sold_to_org_id := NULL;
          END;
        
          BEGIN
            SELECT account_name
              INTO x_cust_name
              FROM hz_cust_accounts
             WHERE cust_account_id = x_sold_to_org_id
               AND status = 'A'
               AND ROWNUM < 2;
          EXCEPTION
            WHEN OTHERS THEN
              x_cust_name := NULL;
          END;
        
          --- Set the Attributes for sending Mail to The Customer Care
          wf_engine.setitemattrtext(itemtype,
                                    itemkey,
                                    'XX_OM_HDR_HOLD_NAME',
                                    xx_emf_pkg.get_paramater_value(g_process_name,
                                                                   g_hdr_hold_name));
          wf_engine.setitemattrtext(itemtype,
                                    itemkey,
                                    'XX_OM_DATE',
                                    x_creation_date);
          wf_engine.setitemattrtext(itemtype,
                                    itemkey,
                                    'XX_OM_ORD_NUM',
                                    x_order_number);
          wf_engine.setitemattrtext(itemtype,
                                    itemkey,
                                    'XX_OM_CUST_NAME',
                                    x_cust_name);
        
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
      END IF;
    END IF;
  
    resultout := 'COMPLETE:COMPLETE';
    RETURN;
  EXCEPTION
    WHEN e_hold_error THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_dup_cust_po_chk ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || x_err_msg);
      RAISE;
    WHEN e_hold_id THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_dup_cust_po_chk ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : Hold Not Define In Oracle');
      RAISE;
    WHEN OTHERS THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_dup_cust_po_chk ',
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
  END xx_om_dup_cust_po_chk;

  /* 13-May-2013 Dhiren Parida : Start */
  -- =================================================================================
  -- Name           : xx_om_quater_end_hold_chk
  -- Description    : Procedure To  Apply The QUARTER END HOLD
  -- Parameters description       :
  --
  -- itemtype                    : Parameter To Store itemtype (IN)
  -- itemkey                     : Parameter To Store itemkey  (IN)
  -- actid                       : Parameter To Store actid    (IN)
  -- funcmode                    : Parameter To Store funcmode (IN)
  -- resultout                   : Parameter To Store resultout(IN OUT)
  -- ==============================================================================
  PROCEDURE xx_om_quater_end_hold_chk(itemtype  IN VARCHAR2,
                                      itemkey   IN VARCHAR2,
                                      actid     IN NUMBER,
                                      funcmode  IN VARCHAR2,
                                      resultout IN OUT NOCOPY VARCHAR2) IS
    x_order_tbl               oe_holds_pvt.order_tbl_type;
    x_hold_id                 NUMBER;
    x_hold_amount             NUMBER;
    x_msg_count               NUMBER;
    x_hold_count              NUMBER;
    x_sold_to_org_id          NUMBER;
    x_order_total             NUMBER;
    x_err_msg                 VARCHAR2(1000);
    x_user_name               VARCHAR2(100);
    x_return_status           VARCHAR2(100);
    x_msg_data                VARCHAR2(100);
    x_source                  VARCHAR2(100);
    x_cust_name               VARCHAR2(240);
    x_conv_rate               NUMBER;
    x_transactional_curr_code VARCHAR2(10);
    x_conversion_type_code    VARCHAR2(10);
    x_ordered_date            DATE;
    x_creation_date           DATE;
    x_order_number            VARCHAR2(100);
    e_hold_id EXCEPTION;
    e_hold_error EXCEPTION;
    x_hold_source_rec oe_holds_pvt.hold_source_rec_type;
    x_order_source    VARCHAR2(100);
  
    -- Cursor to fetch count for Dup PO attached to Other SO
    CURSOR c_oe_order_lines(p_itemkey NUMBER, p_source VARCHAR2) IS
      SELECT ol.description, oos.NAME
        FROM oe_order_headers_all ooha,
             oe_lookups           ol,
             oe_order_sources     oos,
             hz_cust_accounts     hca
       WHERE 1 = 1
            --AND header_id = 657417
         AND ooha.header_id = p_itemkey
         AND ol.lookup_type = 'EDI_QUARTER_END_MODIFIER'
            --AND TO_CHAR (TRUNC (ooha.creation_date, 'Q'), 'Mon-YYYY') =
            --                                                        ol.meaning
         AND TRUNC(ooha.creation_date) BETWEEN
             NVL(ol.START_DATE_ACTIVE, TRUNC(SYSDATE)) AND
             NVL(ol.END_DATE_ACTIVE, TRUNC(SYSDATE))
         AND ol.enabled_flag = 'Y'
         AND ol.START_DATE_ACTIVE IS NOT NULL
         AND ol.END_DATE_ACTIVE IS NOT NULL
         AND ooha.order_source_id = oos.order_source_id
         AND hca.cust_account_id = ooha.sold_to_org_id
         AND hca.status = 'A'
         AND ol.START_DATE_ACTIVE =
             (Select max(ol1.START_DATE_ACTIVE)
                from oe_lookups ol1
               where TRUNC(ooha.creation_date) BETWEEN
                     NVL(ol1.START_DATE_ACTIVE, TRUNC(SYSDATE)) AND
                     NVL(ol1.END_DATE_ACTIVE, TRUNC(SYSDATE))
                 AND ol1.lookup_type = 'EDI_QUARTER_END_MODIFIER'
                 AND ol1.enabled_flag = 'Y'
                 AND ol1.START_DATE_ACTIVE IS NOT NULL
                 AND ol1.END_DATE_ACTIVE IS NOT NULL)
         AND ooha.order_source_id IN
             (SELECT order_source_id
                FROM oe_order_sources
               WHERE NAME = p_source 
                 AND aia_enabled_flag = 'Y'
                 AND enabled_flag = 'Y');
  
    -- Cursor to fetch HOLD ID
    CURSOR c_hold_id(p_hold_name VARCHAR2, p_hold_type VARCHAR2, p_item_type VARCHAR2) IS
      SELECT hold_id
        FROM oe_hold_definitions
       WHERE NAME = p_hold_name
         AND type_code = p_hold_type
         AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active, TRUNC(SYSDATE)) AND
             NVL(end_date_active, TRUNC(SYSDATE))
         AND item_type = p_item_type;
  
    -- Cursor to check Dup Hold
    CURSOR c_hold_count(p_hold_id NUMBER, p_header_id NUMBER) IS
      SELECT COUNT(*)
        FROM oe_hold_sources_all
       WHERE hold_id = p_hold_id
         AND released_flag = 'Y'
         AND hold_entity_id = p_header_id;
  
    -- Cursor for currency conversion
    CURSOR c_fetch_conv_rate(p_from_curr VARCHAR2, p_to_curr VARCHAR2, p_conv_date DATE, p_conv_type VARCHAR2) IS
      SELECT conversion_rate
        FROM gl_daily_rates
       WHERE from_currency = p_from_curr
         AND to_currency = p_to_curr
         AND UPPER(conversion_type) = UPPER(p_conv_type)
         AND conversion_date = p_conv_date;
  BEGIN
    IF (funcmode = 'RUN') THEN
      --- Query to Extract Line Details

      wf_engine.setitemattrtext(itemtype,
                                itemkey,
                                'XX_OM_HDR_HOLD_NAME',
                                NULL);
    
      OPEN c_oe_order_lines(TO_NUMBER(itemkey), 'EDIGHX');
    
      FETCH c_oe_order_lines
        INTO x_hold_amount, x_order_source;
    
      IF c_oe_order_lines%NOTFOUND THEN
        x_hold_amount  := 0;
        x_order_source := NULL;
      END IF;
    
      CLOSE c_oe_order_lines;
    
      IF x_hold_amount > 0 AND x_order_source = 'EDIGHX' THEN
        --- Fetch the Order Amount
        BEGIN
          SELECT SUM(ordered_quantity * unit_selling_price)
            INTO x_order_total
            FROM oe_order_lines_all
           WHERE header_id = TO_NUMBER(itemkey);
        EXCEPTION
          WHEN OTHERS THEN
            x_order_total := 0;
        END;
      
        --- Fetch the Currency Code
        BEGIN
          SELECT oeh.transactional_curr_code,
                 oeh.conversion_type_code,
                 TRUNC(oeh.creation_date)
            INTO x_transactional_curr_code,
                 x_conversion_type_code,
                 x_ordered_date
            FROM oe_order_headers_all oeh
           WHERE header_id = TO_NUMBER(itemkey);
        EXCEPTION
          WHEN OTHERS THEN
            x_transactional_curr_code := NULL;
            x_conversion_type_code    := NULL;
            x_ordered_date            := NULL;
        END;
      
        IF 'USD' <> x_transactional_curr_code THEN
          OPEN c_fetch_conv_rate(x_transactional_curr_code,
                                 'USD',
                                 x_ordered_date,
                                 x_conversion_type_code);
        
          FETCH c_fetch_conv_rate
            INTO x_conv_rate;
        
          CLOSE c_fetch_conv_rate;
        
          x_order_total := ROUND(x_order_total * x_conv_rate, 2);
        END IF;
      
        IF NVL(x_order_total, 0) > NVL(x_hold_amount, 0) THEN
          --- Query to Extract Hold Id
          OPEN c_hold_id(xx_emf_pkg.get_paramater_value(g_process_name,
                                                        g_hdr_qtr_hold_name),
                         xx_emf_pkg.get_paramater_value(g_process_name,
                                                        g_hold_type),
                         xx_emf_pkg.get_paramater_value(g_process_name,
                                                        g_hdr_item_type));
        
          FETCH c_hold_id
            INTO x_hold_id;
        
          IF c_hold_id%NOTFOUND THEN
            RAISE e_hold_id;
          END IF;
        
          CLOSE c_hold_id;
        
          OPEN c_hold_count(x_hold_id, TO_NUMBER(itemkey));
        
          FETCH c_hold_count
            INTO x_hold_count;
        
          IF c_hold_count%NOTFOUND THEN
            x_hold_count := 0;
          END IF;
        
          CLOSE c_hold_count;
        
          IF x_hold_count = 0 THEN
            x_hold_source_rec                  := oe_holds_pvt.g_miss_hold_source_rec;
            x_hold_source_rec.hold_id          := x_hold_id;
            x_hold_source_rec.hold_entity_code := 'O';
            x_hold_source_rec.hold_entity_id   := TO_NUMBER(itemkey);
            x_hold_source_rec.header_id        := TO_NUMBER(itemkey);
          
            BEGIN
              SELECT order_number, creation_date, sold_to_org_id
                INTO x_order_number, x_creation_date, x_sold_to_org_id
                FROM oe_order_headers_all
               WHERE header_id = TO_NUMBER(itemkey);
            EXCEPTION
              WHEN OTHERS THEN
                x_order_number   := NULL;
                x_creation_date  := NULL;
                x_sold_to_org_id := NULL;
            END;
          
            BEGIN
              SELECT account_name
                INTO x_cust_name
                FROM hz_cust_accounts
               WHERE cust_account_id = x_sold_to_org_id
                 AND status = 'A'
                 AND ROWNUM < 2;
            EXCEPTION
              WHEN OTHERS THEN
                x_cust_name := NULL;
            END;
          
            --- Set the Attributes for sending Mail to The Customer Care
            wf_engine.setitemattrtext(itemtype,
                                      itemkey,
                                      'XX_OM_HDR_HOLD_NAME',
                                      xx_emf_pkg.get_paramater_value(g_process_name,
                                                                     g_hdr_qtr_hold_name));
            wf_engine.setitemattrtext(itemtype,
                                      itemkey,
                                      'XX_OM_DATE',
                                      x_creation_date);
            wf_engine.setitemattrtext(itemtype,
                                      itemkey,
                                      'XX_OM_ORD_NUM',
                                      x_order_number);
            wf_engine.setitemattrtext(itemtype,
                                      itemkey,
                                      'XX_OM_CUST_NAME',
                                      x_cust_name);
          
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
        END IF;
      END IF;
    END IF;
  
    resultout := 'COMPLETE:COMPLETE';
    RETURN;
  EXCEPTION
    WHEN e_hold_error THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_quater_end_hold_chk ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || x_err_msg);
      RAISE;
    WHEN e_hold_id THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_quater_end_hold_chk ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : Hold Not Define In Oracle');
      RAISE;
    WHEN OTHERS THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_quater_end_hold_chk ',
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
  END xx_om_quater_end_hold_chk;

  -- =================================================================================
  -- Name           : xx_om_hdr_prc_hold_chk
  -- Description    : Procedure To Check the total order amount with file line total
  --                  if mismatch then apply the HOLD
  -- Parameters description       :
  --
  -- itemtype                    : Parameter To Store itemtype (IN)
  -- itemkey                     : Parameter To Store itemkey  (IN)
  -- actid                       : Parameter To Store actid    (IN)
  -- funcmode                    : Parameter To Store funcmode (IN)
  -- resultout                   : Parameter To Store resultout(IN OUT)
  -- ==============================================================================
  PROCEDURE xx_om_hdr_prc_hold_chk(itemtype  IN VARCHAR2,
                                   itemkey   IN VARCHAR2,
                                   actid     IN NUMBER,
                                   funcmode  IN VARCHAR2,
                                   resultout IN OUT NOCOPY VARCHAR2) IS
    x_order_tbl          oe_holds_pvt.order_tbl_type;
    x_order_quantity_uom VARCHAR2(100);
    x_hold_id            NUMBER;
    x_record_count       NUMBER;
    x_tp_attribute1      VARCHAR2(100);
    x_source             VARCHAR2(100);
    x_msg_count          NUMBER;
    x_err_msg            VARCHAR2(1000);
    x_return_status      VARCHAR2(100);
    x_msg_data           VARCHAR2(100);
    x_cust_name          VARCHAR2(240);
    x_exempt_acct        NUMBER;
    e_hold_id EXCEPTION;
    e_hold_error EXCEPTION;
    x_order_total        NUMBER;
    x_total_amount       NUMBER;
    x_order_total_amount NUMBER;
    x_account_number     VARCHAR2(100);
    x_creation_date      DATE;
    x_order_number       VARCHAR2(100);
    x_hold_source_rec    oe_holds_pvt.hold_source_rec_type;
    x_sold_to_org_id     NUMBER;
    x_diff_amount        NUMBER;
    x_line_number        VARCHAR2(100);
    x_hold_comment       VARCHAR2(1000);
    x_ord_source         VARCHAR2(100);
  
    -- Cursor to fetch count for Dup PO attached to Other SO
    CURSOR c_oe_order_lines(p_itemkey NUMBER, p_source VARCHAR2) IS
      SELECT oola.unit_selling_price,
             oola.customer_item_net_price,
             oola.line_id,
             oola.header_id,
             oola.order_source_id,
             oola.creation_date,
             oola.line_number,
             ooha.order_number,
             oola.ordered_item,
             ooha.sold_to_org_id,
             oos.NAME,
             oola.ordered_quantity,
             hca.account_number
        FROM oe_order_headers_all ooha,
             oe_order_lines_all   oola,
             oe_order_sources     oos,
             hz_cust_accounts     hca
       WHERE ooha.header_id = p_itemkey
         AND oola.header_id = ooha.header_id
         AND oola.org_id = ooha.org_id
         AND oola.ordered_item <> xx_emf_pkg.get_paramater_value(g_process_name, g_ediinvalid_item)
         AND ooha.order_source_id = oos.order_source_id
         AND hca.cust_account_id = ooha.sold_to_org_id
         AND hca.status = 'A'
         AND oola.order_source_id IN
             (SELECT order_source_id
                FROM oe_order_sources
               WHERE NAME = p_source 
                 AND aia_enabled_flag = 'Y'
                 AND enabled_flag = 'Y');
  
    -- Cursor to fetch HOLD ID
    CURSOR c_hold_id(p_hold_name VARCHAR2, p_hold_type VARCHAR2, p_item_type VARCHAR2) IS
      SELECT hold_id
        FROM oe_hold_definitions
       WHERE NAME = p_hold_name
         AND type_code = p_hold_type
         AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active, TRUNC(SYSDATE)) AND
             NVL(end_date_active, TRUNC(SYSDATE))
         AND item_type = p_item_type;
  BEGIN
    IF (funcmode = 'RUN') THEN
      --- Query to Extract Line Details
      x_source      := 'EDIGHX';
      x_diff_amount := 0;
      x_ord_source  := Null;
      wf_engine.setitemattrtext(itemtype,
                                itemkey,
                                'XX_OM_HDR_HOLD_NAME',
                                NULL);
    
      x_line_number := NULL;
    
      FOR rec_oe_order_lines IN c_oe_order_lines(TO_NUMBER(itemkey),
                                                 x_source) LOOP
        x_exempt_acct := 0;
        --- Fetch the Order Total Amount From File
        x_order_total    := rec_oe_order_lines.ordered_quantity *
                            NVL(rec_oe_order_lines.customer_item_net_price,
                                rec_oe_order_lines.unit_selling_price);
        x_total_amount   := NVL(x_total_amount, 0) + NVL(x_order_total, 0);
        x_account_number := rec_oe_order_lines.account_number;
        x_ord_source     := rec_oe_order_lines.NAME;
      
        /* Added By Dhiren 22Oct2013*/
      
        IF (ABS(NVL(rec_oe_order_lines.customer_item_net_price, 0) -
                NVL(rec_oe_order_lines.unit_selling_price, 0)) >
           xx_emf_pkg.get_paramater_value(g_process_name, g_hold_lmt_diff) AND
           rec_oe_order_lines.NAME = 'EDIGHX') THEN
          x_line_number := x_line_number || ',' ||
                           rec_oe_order_lines.line_number;
        END IF;
      
      /* -----------------------  */
      END LOOP;
    
      IF length(x_line_number) > 1 THEN
        x_hold_comment := 'Line# Eligable For Price Hold : ' ||
                          SUBSTR(x_line_number, 2, length(x_line_number));
      ELSE
        x_hold_comment := NULL;
      END IF;
      --insert into xyz_test values('x_total_amount '||x_total_amount);
    
      --insert into xyz_test values('x_source '||x_source);
    
      -- Additional logic for GHX to exempt customers from Hold
      BEGIN
        SELECT COUNT(1)
          INTO x_exempt_acct
          FROM fnd_lookup_values
         WHERE lookup_type = 'INTG_EDI_PRICE_EXCEPTION'
           AND lookup_code = x_account_number
           AND enabled_flag = 'Y'
           AND LANGUAGE = USERENV('LANG');
      EXCEPTION
        WHEN OTHERS THEN
          x_exempt_acct := 0;
      END;
    
      IF ((UPPER(x_source) = UPPER(x_ord_source)) AND (x_exempt_acct = 0)) THEN
        --- Fetch the Order Total Amount From Oracle
        BEGIN
          SELECT SUM(ordered_quantity * unit_selling_price)
            INTO x_order_total_amount
            FROM oe_order_lines_v
           WHERE header_id = TO_NUMBER(itemkey);
        EXCEPTION
          WHEN OTHERS THEN
            x_order_total_amount := 0;
        END;
      
        ---insert into xyz_test values('x_order_total_amount '||x_order_total_amount);
        x_diff_amount := ABS(NVL(x_total_amount, 0) -
                             NVL(x_order_total_amount, 0));
      
        ---insert into xyz_test values('x_diff_amount '||x_diff_amount);
        IF (x_diff_amount >
           xx_emf_pkg.get_paramater_value(g_process_name, g_hold_lmt_diff)) THEN
          ---insert into xyz_test values('Inside IF');
        
          --- Query to Extract Hold Id
          OPEN c_hold_id(xx_emf_pkg.get_paramater_value(g_process_name,
                                                        g_hdr_price_hold_name),
                         xx_emf_pkg.get_paramater_value(g_process_name,
                                                        g_hold_type),
                         xx_emf_pkg.get_paramater_value(g_process_name,
                                                        g_hdr_item_type));
        
          FETCH c_hold_id
            INTO x_hold_id;
        
          IF c_hold_id%NOTFOUND THEN
            RAISE e_hold_id;
          END IF;
        
          CLOSE c_hold_id;
        
          x_hold_source_rec                  := oe_holds_pvt.g_miss_hold_source_rec;
          x_hold_source_rec.hold_id          := x_hold_id;
          x_hold_source_rec.hold_entity_code := 'O';
          x_hold_source_rec.hold_entity_id   := TO_NUMBER(itemkey);
          x_hold_source_rec.header_id        := TO_NUMBER(itemkey);
          x_hold_source_rec.HOLD_COMMENT     := x_hold_comment;
        
          BEGIN
            SELECT order_number, creation_date, sold_to_org_id
              INTO x_order_number, x_creation_date, x_sold_to_org_id
              FROM oe_order_headers_all
             WHERE header_id = TO_NUMBER(itemkey);
          EXCEPTION
            WHEN OTHERS THEN
              x_order_number   := NULL;
              x_creation_date  := NULL;
              x_sold_to_org_id := NULL;
          END;
        
          BEGIN
            SELECT account_name
              INTO x_cust_name
              FROM hz_cust_accounts
             WHERE cust_account_id = x_sold_to_org_id
               AND status = 'A'
               AND ROWNUM < 2;
          EXCEPTION
            WHEN OTHERS THEN
              x_cust_name := NULL;
          END;
        
          wf_engine.setitemattrtext(itemtype,
                                    itemkey,
                                    'XX_OM_HDR_HOLD_NAME',
                                    xx_emf_pkg.get_paramater_value(g_process_name,
                                                                   g_hdr_price_hold_name));
          wf_engine.setitemattrtext(itemtype,
                                    itemkey,
                                    'XX_OM_DATE',
                                    x_creation_date);
          wf_engine.setitemattrtext(itemtype,
                                    itemkey,
                                    'XX_OM_ORD_NUM',
                                    x_order_number);
          wf_engine.setitemattrtext(itemtype,
                                    itemkey,
                                    'XX_OM_CUST_NAME',
                                    x_cust_name);
        
          --insert into xyz_test values('Before API ');
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
          --insert into xyz_test values('After API ');
        END IF;
      END IF;
    END IF;
  
    resultout := 'COMPLETE:COMPLETE';
    RETURN;
  EXCEPTION
    WHEN e_hold_error THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_hdr_prc_hold_chk ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || x_err_msg);
      RAISE;
    WHEN e_hold_id THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_hdr_prc_hold_chk ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : Hold Not Define In Oracle');
      RAISE;
    WHEN OTHERS THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_hdr_prc_hold_chk ',
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
  END xx_om_hdr_prc_hold_chk;

  /* 13-May-2013 Dhiren Parida  */

  /* 22-Oct-2013 Dhiren Parida Start */

  -- =================================================================================
  -- Name           : xx_om_hdr_dropship_hold_chk
  -- Description    : Procedure To Check the Apply Drop Ship HOLD
  -- Parameters description       :
  --
  -- itemtype                    : Parameter To Store itemtype (IN)
  -- itemkey                     : Parameter To Store itemkey  (IN)
  -- actid                       : Parameter To Store actid    (IN)
  -- funcmode                    : Parameter To Store funcmode (IN)
  -- resultout                   : Parameter To Store resultout(IN OUT)
  -- ==============================================================================
  PROCEDURE xx_om_hdr_dropship_hold_chk(itemtype  IN VARCHAR2,
                                        itemkey   IN VARCHAR2,
                                        actid     IN NUMBER,
                                        funcmode  IN VARCHAR2,
                                        resultout IN OUT NOCOPY VARCHAR2) IS
    x_order_tbl          oe_holds_pvt.order_tbl_type;
    x_order_quantity_uom VARCHAR2(100);
    x_hold_id            NUMBER;
    x_record_count       NUMBER;
    x_tp_attribute1      VARCHAR2(100);
    x_source             VARCHAR2(100);
    x_msg_count          NUMBER;
    x_err_msg            VARCHAR2(1000);
    x_return_status      VARCHAR2(100);
    x_msg_data           VARCHAR2(100);
    x_cust_name          VARCHAR2(240);
    x_exempt_acct        NUMBER;
    e_hold_id EXCEPTION;
    e_hold_error EXCEPTION;
    x_order_total        NUMBER;
    x_total_amount       NUMBER;
    x_order_total_amount NUMBER;
    x_account_number     VARCHAR2(100);
    x_creation_date      DATE;
    x_order_number       VARCHAR2(100);
    x_hold_source_rec    oe_holds_pvt.hold_source_rec_type;
    x_sold_to_org_id     NUMBER;
    x_diff_amount        NUMBER;
    x_line_number        VARCHAR2(100);
    x_del_add            VARCHAR2(1000);
  
    -- Cursor to fetch count for Dup PO attached to Other SO
    CURSOR c_oe_order_lines(p_itemkey NUMBER, p_source VARCHAR2) IS
      SELECT oola.line_id,
             oola.header_id,
             oola.order_source_id,
             oola.line_number,
             ooha.order_number,
             oola.ordered_item,
             ooha.sold_to_org_id,
             oos.NAME,
             hca.account_number,
             ooha.tp_attribute6
        FROM oe_order_headers_all ooha,
             oe_order_lines_all   oola,
             oe_order_sources     oos,
             hz_cust_accounts     hca
       WHERE ooha.header_id = p_itemkey
         AND oola.header_id = ooha.header_id
         AND oola.org_id = ooha.org_id
         AND ooha.order_source_id = oos.order_source_id
         AND hca.cust_account_id = ooha.sold_to_org_id
         AND hca.status = 'A'
         AND oola.order_source_id IN
             (SELECT order_source_id
                FROM oe_order_sources
               WHERE NAME LIKE '' || p_source || '%'
                 AND aia_enabled_flag = 'Y'
                 AND enabled_flag = 'Y');
  
    -- Cursor to fetch HOLD ID
    CURSOR c_hold_id(p_hold_name VARCHAR2, p_hold_type VARCHAR2, p_item_type VARCHAR2) IS
      SELECT hold_id
        FROM oe_hold_definitions
       WHERE NAME = p_hold_name
         AND type_code = p_hold_type
         AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active, TRUNC(SYSDATE)) AND
             NVL(end_date_active, TRUNC(SYSDATE))
         AND item_type = p_item_type;
  BEGIN
    IF (funcmode = 'RUN') THEN
      --- Query to Extract Line Details
      x_source      := 'EDIGHX';
      x_diff_amount := 0;
    
      wf_engine.setitemattrtext(itemtype,
                                itemkey,
                                'XX_OM_HDR_HOLD_NAME',
                                NULL);
    
      x_line_number := NULL;
    
      FOR rec_oe_order_lines IN c_oe_order_lines(TO_NUMBER(itemkey),
                                                 x_source) LOOP
        x_source  := rec_oe_order_lines.NAME;
        x_del_add := rec_oe_order_lines.tp_attribute6;
      
      END LOOP;
    
      IF ((UPPER(x_source) = ('EDIGHX')) AND (x_del_add IS NOT NULL)) THEN
      
        --- Query to Extract Hold Id
        OPEN c_hold_id(xx_emf_pkg.get_paramater_value(g_process_name,
                                                      g_hdr_dpship_hold_name),
                       xx_emf_pkg.get_paramater_value(g_process_name,
                                                      g_hold_type),
                       xx_emf_pkg.get_paramater_value(g_process_name,
                                                      g_hdr_item_type));
      
        FETCH c_hold_id
          INTO x_hold_id;
      
        IF c_hold_id%NOTFOUND THEN
          RAISE e_hold_id;
        END IF;
      
        CLOSE c_hold_id;
      
        x_hold_source_rec                  := oe_holds_pvt.g_miss_hold_source_rec;
        x_hold_source_rec.hold_id          := x_hold_id;
        x_hold_source_rec.hold_entity_code := 'O';
        x_hold_source_rec.hold_entity_id   := TO_NUMBER(itemkey);
        x_hold_source_rec.header_id        := TO_NUMBER(itemkey);
      
        BEGIN
          SELECT order_number, creation_date, sold_to_org_id
            INTO x_order_number, x_creation_date, x_sold_to_org_id
            FROM oe_order_headers_all
           WHERE header_id = TO_NUMBER(itemkey);
        EXCEPTION
          WHEN OTHERS THEN
            x_order_number   := NULL;
            x_creation_date  := NULL;
            x_sold_to_org_id := NULL;
        END;
      
        BEGIN
          SELECT account_name
            INTO x_cust_name
            FROM hz_cust_accounts
           WHERE cust_account_id = x_sold_to_org_id
             AND status = 'A'
             AND ROWNUM < 2;
        EXCEPTION
          WHEN OTHERS THEN
            x_cust_name := NULL;
        END;
      
        wf_engine.setitemattrtext(itemtype,
                                  itemkey,
                                  'XX_OM_HDR_HOLD_NAME',
                                  xx_emf_pkg.get_paramater_value(g_process_name,
                                                                 g_hdr_dpship_hold_name));
        wf_engine.setitemattrtext(itemtype,
                                  itemkey,
                                  'XX_OM_DATE',
                                  x_creation_date);
        wf_engine.setitemattrtext(itemtype,
                                  itemkey,
                                  'XX_OM_ORD_NUM',
                                  x_order_number);
        wf_engine.setitemattrtext(itemtype,
                                  itemkey,
                                  'XX_OM_CUST_NAME',
                                  x_cust_name);
      
        --insert into xyz_test values('Before API ');
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
        --insert into xyz_test values('After API ');
      END IF;
    END IF;
  
    resultout := 'COMPLETE:COMPLETE';
    RETURN;
  EXCEPTION
    WHEN e_hold_error THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_hdr_dropship_hold_chk ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || x_err_msg);
      RAISE;
    WHEN e_hold_id THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_hdr_dropship_hold_chk ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : Hold Not Define In Oracle');
      RAISE;
    WHEN OTHERS THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_hdr_dropship_hold_chk ',
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
  END xx_om_hdr_dropship_hold_chk;

  /* 22-Oct-2013 Dhiren Parida  */
  -- =================================================================================
  -- Name           : xx_om_uom_hold_chk
  -- Description    : Procedure To Check the File UOM With Item UOM and Apply The HOLD
  -- Parameters description       :
  --
  -- itemtype                    : Parameter To Store itemtype (IN)
  -- itemkey                     : Parameter To Store itemkey  (IN)
  -- actid                       : Parameter To Store actid    (IN)
  -- funcmode                    : Parameter To Store funcmode (IN)
  -- resultout                   : Parameter To Store resultout(IN OUT)
  -- ==============================================================================
  PROCEDURE xx_om_uom_hold_chk(itemtype  IN VARCHAR2,
                               itemkey   IN VARCHAR2,
                               actid     IN NUMBER,
                               funcmode  IN VARCHAR2,
                               resultout IN OUT NOCOPY VARCHAR2) IS
    x_order_tbl          oe_holds_pvt.order_tbl_type;
    x_order_quantity_uom VARCHAR2(100);
    x_hold_id            NUMBER;
    x_source             VARCHAR2(100);
    x_record_count       NUMBER;
    x_tp_attribute1      VARCHAR2(100);
    x_msg_count          NUMBER;
    x_cust_name          VARCHAR2(240);
    x_err_msg            VARCHAR2(1000);
    x_return_status      VARCHAR2(100);
    x_msg_data           VARCHAR2(100);
    e_hold_id EXCEPTION;
    e_hold_error EXCEPTION;
  
    -- Cursor to fetch count for Dup PO attached to Other SO
    CURSOR c_oe_order_lines(p_itemkey NUMBER, p_source VARCHAR2) IS
      SELECT oola.order_quantity_uom,
             oola.tp_attribute1,
             oola.line_id,
             oola.header_id,
             oola.order_source_id,
             oola.creation_date,
             oola.line_number,
             ooha.order_number,
             oola.ordered_item,
             ooha.sold_to_org_id,
             oos.NAME
        FROM oe_order_headers_all ooha,
             oe_order_lines_all   oola,
             oe_order_sources     oos
       WHERE oola.line_id = p_itemkey
         AND oola.header_id = ooha.header_id
         AND oola.org_id = ooha.org_id
         AND ooha.order_source_id = oos.order_source_id
         AND oola.order_source_id IN
             (SELECT order_source_id
                FROM oe_order_sources
               WHERE NAME LIKE '' || p_source || '%'
                 AND aia_enabled_flag = 'Y'
                 AND enabled_flag = 'Y');
  
    -- Cursor to fetch HOLD ID
    CURSOR c_hold_id(p_hold_name VARCHAR2, p_hold_type VARCHAR2, p_item_type VARCHAR2) IS
      SELECT hold_id
        FROM oe_hold_definitions
       WHERE NAME = p_hold_name
         AND type_code = p_hold_type
         AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active, TRUNC(SYSDATE)) AND
             NVL(end_date_active, TRUNC(SYSDATE))
         AND item_type = p_item_type;
  BEGIN
    IF (funcmode = 'RUN') THEN
      --- Query to Extract Line Details
      x_source := xx_emf_pkg.get_paramater_value(g_process_name,
                                                 g_order_source);
      /* wf_engine.setitemattrtext(itemtype, itemkey, 'XX_OM_HOLD_NAME', NULL);
      FOR rec_oe_order_lines IN c_oe_order_lines (TO_NUMBER (itemkey),
                                                  x_source
                                                 )
      LOOP
         x_order_tbl (1).header_id := rec_oe_order_lines.header_id;
         x_order_tbl (1).line_id := rec_oe_order_lines.line_id;
      
         IF (    rec_oe_order_lines.tp_attribute1 IS NOT NULL
             AND rec_oe_order_lines.order_quantity_uom <>
                                           rec_oe_order_lines.tp_attribute1
             AND rec_oe_order_lines.name = 'EDIGHX' -- UOM Hold only for GHX Orders
            )
         THEN
            --- Query to Extract Hold Id
            OPEN c_hold_id
                     (xx_emf_pkg.get_paramater_value (g_process_name,
                                                      g_lnr_uom_hold_name
                                                     ),
                      xx_emf_pkg.get_paramater_value (g_process_name,
                                                      g_hold_type
                                                     ),
                      xx_emf_pkg.get_paramater_value (g_process_name,
                                                      g_lnr_item_type
                                                     )
                     );
      
            FETCH c_hold_id
             INTO x_hold_id;
      
            IF c_hold_id%NOTFOUND
            THEN
               RAISE e_hold_id;
            END IF;
      
            CLOSE c_hold_id;
      
             BEGIN
                SELECT account_name
                  INTO x_cust_name
                  FROM hz_cust_accounts
                 WHERE cust_account_id = rec_oe_order_lines.sold_to_org_id
                   AND status = 'A'
                   AND ROWNUM < 2;
             EXCEPTION
                WHEN OTHERS
                THEN
                   x_cust_name := NULL;
             END;
      
      
            --- Set the Attributes for sending Mail to The Customer Care
             wf_engine.setitemattrtext
                      (itemtype,
                       itemkey,
                       'XX_OM_HOLD_NAME',
                       xx_emf_pkg.get_paramater_value (g_process_name,
                                                       g_lnr_uom_hold_name
                                                      )
                      );
             wf_engine.setitemattrtext (itemtype,
                                        itemkey,
                                        'XX_OM_DATE',
                                        rec_oe_order_lines.creation_date
                                       );
             wf_engine.setitemattrnumber (itemtype,
                                          itemkey,
                                          'XX_OM_ORD_NUM',
                                          rec_oe_order_lines.order_number
                                         );
             wf_engine.setitemattrnumber (itemtype,
                                          itemkey,
                                          'XX_OM_LIN_NUM',
                                          rec_oe_order_lines.line_number
                                         );
             wf_engine.setitemattrtext (itemtype,
                                        itemkey,
                                        'XX_OM_CUST_NAME',
                                        x_cust_name
                                       );
             wf_engine.setitemattrtext (itemtype,
                                        itemkey,
                                        'XX_OM_ITEM',
                                        rec_oe_order_lines.ordered_item
                                       );
      
      
            --- Call the API to Apply Hold
            BEGIN
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
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_err_msg := SUBSTR (SQLERRM, 1, 80);
                  RAISE e_hold_error;
            END;
         END IF;
      END LOOP; */
    END IF;
  
    resultout := 'COMPLETE:COMPLETE';
    RETURN;
  EXCEPTION
    WHEN e_hold_error THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_uom_hold_chk ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || x_err_msg);
      RAISE;
    WHEN e_hold_id THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_uom_hold_chk ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : Hold Not Define In Oracle');
      RAISE;
    WHEN OTHERS THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_uom_hold_chk ',
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
  END xx_om_uom_hold_chk;

  -- =================================================================================
  -- Name           : xx_om_item_net_prc_hold_chk
  -- Description    : Procedure To Check the File Item Net Price With Item Unit Selling Price and Apply The HOLD
  -- Parameters description       :
  --
  -- itemtype                    : Parameter To Store itemtype (IN)
  -- itemkey                     : Parameter To Store itemkey  (IN)
  -- actid                       : Parameter To Store actid    (IN)
  -- funcmode                    : Parameter To Store funcmode (IN)
  -- resultout                   : Parameter To Store resultout(IN OUT)
  -- ==============================================================================
  PROCEDURE xx_om_item_net_prc_hold_chk(itemtype  IN VARCHAR2,
                                        itemkey   IN VARCHAR2,
                                        actid     IN NUMBER,
                                        funcmode  IN VARCHAR2,
                                        resultout IN OUT NOCOPY VARCHAR2) IS
    x_order_tbl          oe_holds_pvt.order_tbl_type;
    x_order_quantity_uom VARCHAR2(100);
    x_hold_id            NUMBER;
    x_record_count       NUMBER;
    x_tp_attribute1      VARCHAR2(100);
    x_source             VARCHAR2(100);
    x_msg_count          NUMBER;
    x_err_msg            VARCHAR2(1000);
    x_return_status      VARCHAR2(100);
    x_msg_data           VARCHAR2(100);
    x_cust_name          VARCHAR2(240);
    x_exempt_acct        NUMBER;
    e_hold_id EXCEPTION;
    e_hold_error EXCEPTION;
  
    -- Cursor to fetch count for Dup PO attached to Other SO
    CURSOR c_oe_order_lines(p_itemkey NUMBER, p_source VARCHAR2) IS
      SELECT oola.unit_selling_price,
             oola.customer_item_net_price,
             oola.line_id,
             oola.header_id,
             oola.order_source_id,
             oola.creation_date,
             oola.line_number,
             ooha.order_number,
             oola.ordered_item,
             ooha.sold_to_org_id,
             oos.NAME -- Added for GHX
            ,
             hca.account_number -- Added for GHX
        FROM oe_order_headers_all ooha,
             oe_order_lines_all   oola,
             oe_order_sources     oos,
             hz_cust_accounts     hca
       WHERE oola.line_id = p_itemkey
         AND oola.header_id = ooha.header_id
         AND oola.org_id = ooha.org_id
         AND ooha.order_source_id = oos.order_source_id -- Added for GHX
         AND hca.cust_account_id = ooha.sold_to_org_id -- Added for GHX
         AND hca.status = 'A' -- Added for GHX
         AND oola.order_source_id IN
             (SELECT order_source_id
                FROM oe_order_sources
               WHERE NAME LIKE '' || p_source || '%'
                 AND aia_enabled_flag = 'Y'
                 AND enabled_flag = 'Y');
  
    -- Cursor to fetch HOLD ID
    CURSOR c_hold_id(p_hold_name VARCHAR2, p_hold_type VARCHAR2, p_item_type VARCHAR2) IS
      SELECT hold_id
        FROM oe_hold_definitions
       WHERE NAME = p_hold_name
         AND type_code = p_hold_type
         AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active, TRUNC(SYSDATE)) AND
             NVL(end_date_active, TRUNC(SYSDATE))
         AND item_type = p_item_type;
  BEGIN
    IF (funcmode = 'RUN') THEN
      --- Query to Extract Line Details
      x_source := xx_emf_pkg.get_paramater_value(g_process_name,
                                                 g_order_source);
      wf_engine.setitemattrtext(itemtype, itemkey, 'XX_OM_HOLD_NAME', NULL);
    
      FOR rec_oe_order_lines IN c_oe_order_lines(TO_NUMBER(itemkey),
                                                 x_source) LOOP
        x_order_tbl(1).header_id := rec_oe_order_lines.header_id;
        x_order_tbl(1).line_id := rec_oe_order_lines.line_id;
        x_exempt_acct := 0;
      
        -- Additional logic for GHX to exempt customers from Hold
        BEGIN
          SELECT COUNT(1)
            INTO x_exempt_acct
            FROM fnd_lookup_values
           WHERE lookup_type = 'INTG_EDI_PRICE_EXCEPTION'
             AND lookup_code = rec_oe_order_lines.account_number
             AND enabled_flag = 'Y'
             AND LANGUAGE = USERENV('LANG');
        END;
      
        IF rec_oe_order_lines.customer_item_net_price IS NOT NULL AND
           rec_oe_order_lines.customer_item_net_price <> 0 THEN
          IF ((ABS(((NVL(rec_oe_order_lines.customer_item_net_price, 0) -
                   NVL(rec_oe_order_lines.unit_selling_price, 0)) /
                   ((NVL(rec_oe_order_lines.customer_item_net_price, 0)))) * 100) >
             xx_emf_pkg.get_paramater_value(g_process_name,
                                              g_hold_lmt_prc) AND
             rec_oe_order_lines.NAME = 'EDIGXS'
             -- added condition to separate GXS
             )
             /*  OR (    ABS
                                                        (  NVL
                                                              (rec_oe_order_lines.customer_item_net_price
                                                             , 0
                                                              )
                                                         - NVL (rec_oe_order_lines.unit_selling_price
                                                              , 0)
                                                        ) >
                                                        xx_emf_pkg.get_paramater_value (g_process_name
                                                                                      , g_hold_lmt_diff
                                                                                       )
                                                 AND rec_oe_order_lines.NAME = 'EDIGHX'
                                                 -- added condition to separate GHX
                                                 AND x_exempt_acct = 0
                                                -- Customer should not be exempt for Price HOld
                                                )
                                            */ --- Commented By Dhiren on 22Oct 2013
             )
          
           THEN
            --- Query to Extract Hold Id
            OPEN c_hold_id(xx_emf_pkg.get_paramater_value(g_process_name,
                                                          g_lnr_price_hold_name),
                           xx_emf_pkg.get_paramater_value(g_process_name,
                                                          g_hold_type),
                           xx_emf_pkg.get_paramater_value(g_process_name,
                                                          g_lnr_item_type));
          
            FETCH c_hold_id
              INTO x_hold_id;
          
            IF c_hold_id%NOTFOUND THEN
              RAISE e_hold_id;
            END IF;
          
            CLOSE c_hold_id;
          
            BEGIN
              SELECT account_name
                INTO x_cust_name
                FROM hz_cust_accounts
               WHERE cust_account_id = rec_oe_order_lines.sold_to_org_id
                 AND status = 'A'
                 AND ROWNUM < 2;
            EXCEPTION
              WHEN OTHERS THEN
                x_cust_name := NULL;
            END;
          
            --- Set the Attributes for sending Mail to The Customer Care
            wf_engine.setitemattrtext(itemtype,
                                      itemkey,
                                      'XX_OM_HOLD_NAME',
                                      xx_emf_pkg.get_paramater_value(g_process_name,
                                                                     g_lnr_price_hold_name));
            wf_engine.setitemattrtext(itemtype,
                                      itemkey,
                                      'XX_OM_DATE',
                                      rec_oe_order_lines.creation_date);
            wf_engine.setitemattrtext(itemtype,
                                      itemkey,
                                      'XX_OM_ORD_NUM',
                                      rec_oe_order_lines.order_number);
            wf_engine.setitemattrtext(itemtype,
                                      itemkey,
                                      'XX_OM_LIN_NUM',
                                      rec_oe_order_lines.line_number);
            wf_engine.setitemattrtext(itemtype,
                                      itemkey,
                                      'XX_OM_CUST_NAME',
                                      x_cust_name);
            wf_engine.setitemattrtext(itemtype,
                                      itemkey,
                                      'XX_OM_ITEM',
                                      rec_oe_order_lines.ordered_item);
          
            --- Call the API to Apply Hold
            BEGIN
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
            EXCEPTION
              WHEN OTHERS THEN
                x_err_msg := SUBSTR(SQLERRM, 1, 80);
                RAISE e_hold_error;
            END;
          END IF;
          /* ELSIF    rec_oe_order_lines.customer_item_net_price IS NULL   --- Commented By Dhiren 08-Feb-2013
                OR rec_oe_order_lines.customer_item_net_price = 0
          THEN
             --- Query to Extract Hold Id
             OPEN c_hold_id
                    (xx_emf_pkg.get_paramater_value (g_process_name,
                                                     g_lnr_price_hold_name
                                                    ),
                     xx_emf_pkg.get_paramater_value (g_process_name,
                                                     g_hold_type
                                                    ),
                     xx_emf_pkg.get_paramater_value (g_process_name,
                                                     g_lnr_item_type
                                                    )
                    );
          
             FETCH c_hold_id
              INTO x_hold_id;
          
             IF c_hold_id%NOTFOUND
             THEN
                RAISE e_hold_id;
             END IF;
          
             CLOSE c_hold_id;
          
             BEGIN
                SELECT account_name
                  INTO x_cust_name
                  FROM hz_cust_accounts
                 WHERE cust_account_id = rec_oe_order_lines.sold_to_org_id
                   AND status = 'A'
                   AND ROWNUM < 2;
             EXCEPTION
                WHEN OTHERS
                THEN
                   x_cust_name := NULL;
             END;
          
             --- Set the Attributes for sending Mail to The Customer Care
             wf_engine.setitemattrtext
                      (itemtype,
                       itemkey,
                       'XX_OM_HOLD_NAME',
                       xx_emf_pkg.get_paramater_value (g_process_name,
                                                       g_lnr_price_hold_name
                                                      )
                      );
             wf_engine.setitemattrtext (itemtype,
                                        itemkey,
                                        'XX_OM_DATE',
                                        rec_oe_order_lines.creation_date
                                       );
             wf_engine.setitemattrtext (itemtype,
                                        itemkey,
                                        'XX_OM_ORD_NUM',
                                        rec_oe_order_lines.order_number
                                       );
             wf_engine.setitemattrtext (itemtype,
                                        itemkey,
                                        'XX_OM_LIN_NUM',
                                        rec_oe_order_lines.line_number
                                       );
             wf_engine.setitemattrtext (itemtype,
                                        itemkey,
                                        'XX_OM_CUST_NAME',
                                        x_cust_name
                                       );
             wf_engine.setitemattrtext (itemtype,
                                        itemkey,
                                        'XX_OM_ITEM',
                                        rec_oe_order_lines.ordered_item
                                       );
          
             --- Call the API to Apply Hold
             BEGIN
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
             EXCEPTION
                WHEN OTHERS
                THEN
                   x_err_msg := SUBSTR (SQLERRM, 1, 80);
                   RAISE e_hold_error;
             END;
          */ --- Commented By Dhiren 08-Feb-2013
        END IF;
      END LOOP;
    END IF;
  
    resultout := 'COMPLETE:COMPLETE';
    RETURN;
  EXCEPTION
    WHEN e_hold_error THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_item_net_prc_hold_chk ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || x_err_msg);
      RAISE;
    WHEN e_hold_id THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_item_net_prc_hold_chk ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : Hold Not Define In Oracle');
      RAISE;
    WHEN OTHERS THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_om_item_net_prc_hold_chk ',
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
  END xx_om_item_net_prc_hold_chk;

  PROCEDURE xx_line_hold_send_mail(itemtype  IN VARCHAR2,
                                   itemkey   IN VARCHAR2,
                                   actid     IN NUMBER,
                                   funcmode  IN VARCHAR2,
                                   resultout OUT NOCOPY VARCHAR2) IS
    x_msg_sender   VARCHAR2(100) := NULL;
    x_msg_receiver VARCHAR2(100) := NULL;
    x_msg_sub      VARCHAR2(2000) := NULL;
    x_msg_body     VARCHAR2(2000) := NULL;
    x_hold_name    VARCHAR2(240) := NULL;
    x_ord_num      VARCHAR2(240) := NULL;
    x_lnr_num      VARCHAR2(240) := NULL;
    x_date         VARCHAR2(30) := NULL;
    x_cust_name    VARCHAR2(240) := NULL;
    x_item         VARCHAR2(240) := NULL;
  BEGIN
    IF (funcmode = 'RUN') THEN
      --- Get the Attributes for sending Mail to The Customer Care
      x_hold_name := wf_engine.getitemattrtext(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'XX_OM_HOLD_NAME');
      x_date      := wf_engine.getitemattrtext(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'XX_OM_DATE');
      x_ord_num   := wf_engine.getitemattrtext(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'XX_OM_ORD_NUM');
      x_lnr_num   := wf_engine.getitemattrtext(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'XX_OM_LIN_NUM');
      x_cust_name := wf_engine.getitemattrtext(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'XX_OM_CUST_NAME');
      x_item      := wf_engine.getitemattrtext(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'XX_OM_ITEM');
    
      IF x_hold_name IS NOT NULL THEN
        BEGIN
          x_msg_sender := xx_emf_pkg.get_paramater_value('XXOEORDERWSIN',
                                                         'MESSAGE_SENDER');
        EXCEPTION
          WHEN OTHERS THEN
            wf_core.CONTEXT('xx_om_line_hold_pkg',
                            SUBSTR(SQLERRM, 1, 200),
                            itemtype,
                            itemkey,
                            'xx_line_hold_send_mail- Check Message Sender Name in Process Setup Parameter');
            RAISE;
        END;
      
        BEGIN
          x_msg_receiver := xx_emf_pkg.get_paramater_value('XXOEORDERWSIN',
                                                           'MESSAGE_RECEIVER');
        EXCEPTION
          WHEN OTHERS THEN
            wf_core.CONTEXT('xx_om_line_hold_pkg',
                            SUBSTR(SQLERRM, 1, 200),
                            itemtype,
                            itemkey,
                            'xx_line_hold_send_mail- Check Message Receiver Name in Process Setup Parameter');
            RAISE;
        END;
      
        x_msg_sub  := xx_intg_common_pkg.set_long_message('XX_OM_LINE_HOLD_MAIL_SUB',
                                                          NVL(x_hold_name,
                                                              ' '),
                                                          NVL(x_ord_num, ' '),
                                                          NVL(x_lnr_num, ' '));
        x_msg_body := xx_intg_common_pkg.set_long_message('XX_OM_LINE_HOLD_MAIL_BODY',
                                                          NVL(x_date, ' '),
                                                          NVL(x_ord_num, ' '),
                                                          NVL(x_cust_name,
                                                              ' '),
                                                          NVL(x_lnr_num, ' '),
                                                          NVL(x_item, ' '),
                                                          NVL(x_hold_name,
                                                              ' '));
      
        BEGIN
          xx_intg_mail_util_pkg.mail(sender     => x_msg_sender,
                                     recipients => x_msg_receiver,
                                     subject    => x_msg_sub,
                                     MESSAGE    => x_msg_body);
        EXCEPTION
          WHEN OTHERS THEN
            resultout := 'N';
            RETURN;
        END;
      END IF;
    END IF;
  
    resultout := 'COMPLETE:COMPLETE';
    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_line_hold_send_mail ',
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
  END xx_line_hold_send_mail;

  PROCEDURE xx_hdr_hold_send_mail(itemtype  IN VARCHAR2,
                                  itemkey   IN VARCHAR2,
                                  actid     IN NUMBER,
                                  funcmode  IN VARCHAR2,
                                  resultout OUT NOCOPY VARCHAR2) IS
    x_msg_sender    VARCHAR2(100) := NULL;
    x_msg_receiver  VARCHAR2(100) := NULL;
    x_msg_sub       VARCHAR2(2000) := NULL;
    x_msg_body      VARCHAR2(2000) := NULL;
    x_hdr_hold_name VARCHAR2(240) := NULL;
    x_ord_num       VARCHAR2(240) := NULL;
    x_date          VARCHAR2(30) := NULL;
    x_cust_name     VARCHAR2(240) := NULL;
  BEGIN
    IF (funcmode = 'RUN') THEN
      --- Get the Attributes for sending Mail to The Customer Care
      x_hdr_hold_name := wf_engine.getitemattrtext(itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'XX_OM_HDR_HOLD_NAME');
      x_date          := wf_engine.getitemattrtext(itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'XX_OM_DATE');
      x_ord_num       := wf_engine.getitemattrtext(itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'XX_OM_ORD_NUM');
      x_cust_name     := wf_engine.getitemattrtext(itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'XX_OM_CUST_NAME');
    
      IF x_hdr_hold_name IS NOT NULL THEN
        BEGIN
          x_msg_sender := xx_emf_pkg.get_paramater_value('XXOEORDERWSIN',
                                                         'MESSAGE_SENDER');
        EXCEPTION
          WHEN OTHERS THEN
            wf_core.CONTEXT('xx_om_line_hold_pkg',
                            SUBSTR(SQLERRM, 1, 200),
                            itemtype,
                            itemkey,
                            'xx_hdr_hold_send_mail- Check Message Sender Name in Process Setup Parameter');
            RAISE;
        END;
      
        BEGIN
          x_msg_receiver := xx_emf_pkg.get_paramater_value('XXOEORDERWSIN',
                                                           'MESSAGE_RECEIVER');
        EXCEPTION
          WHEN OTHERS THEN
            wf_core.CONTEXT('xx_om_line_hold_pkg',
                            SUBSTR(SQLERRM, 1, 200),
                            itemtype,
                            itemkey,
                            'xx_hdr_hold_send_mail- Check Message Receiver Name in Process Setup Parameter');
            RAISE;
        END;
      
        x_msg_sub  := xx_intg_common_pkg.set_long_message('XX_OM_HDR_HOLD_MAIL_SUB',
                                                          NVL(x_hdr_hold_name,
                                                              ' '),
                                                          NVL(x_ord_num, ' '));
        x_msg_body := xx_intg_common_pkg.set_long_message('XX_OM_HDR_HOLD_MAIL_BODY',
                                                          NVL(x_date, ' '),
                                                          NVL(x_cust_name,
                                                              ' '),
                                                          NVL(x_hdr_hold_name,
                                                              ' '));
      
        BEGIN
          xx_intg_mail_util_pkg.mail(sender     => x_msg_sender,
                                     recipients => x_msg_receiver,
                                     subject    => x_msg_sub,
                                     MESSAGE    => x_msg_body);
        EXCEPTION
          WHEN OTHERS THEN
            resultout := 'N';
            RETURN;
        END;
      END IF;
    END IF;
  
    resultout := 'COMPLETE:COMPLETE';
    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.CONTEXT('xx_om_line_hold_pkg',
                      'xx_hdr_hold_send_mail ',
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
  END xx_hdr_hold_send_mail;
END xx_om_line_hold_pkg; 
/
