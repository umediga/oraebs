DROP PACKAGE BODY APPS.XX_OM_PREPAY_HOLD_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OM_PREPAY_HOLD_PKG" 
-----------------------------------------------------------------------------------
/* $Header: XXOMPREPAYHOLD.pkb 1.2 2014/01/08 12:00:00 dparida noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 08-Jan-2014
 File Name      : XXOMPREPAYHOLD.pkb
 Description    : This script creates the body of the xx_om_prepay_hold_pkg package

 Change History:

 Version Date        Name                     Remarks
 ------- ----------- ---------------------    -------------------------------------
 1.0     21-Jun-2012 IBM Development Team     Initial development.
 1.1     10-Feb-2014 Vishal                   Commented AND item_type = 'OEOH'
 1.2     24-Feb-2014 Dhiren                   Added the Logic to Display HOLD Message
*/
-----------------------------------------------------------------------------------
 AS
  -- =================================================================================
  -- Name           : xx_om_apply_prepay_hold
  -- Description    : Procedure To Apply The PRE-PAY HOLD To Order Header
  -- Parameters description       :
  --
  -- itemtype                    : Parameter To Store itemtype (IN)
  -- itemkey                     : Parameter To Store itemkey  (IN)
  -- actid                       : Parameter To Store actid    (IN)
  -- funcmode                    : Parameter To Store funcmode (IN)
  -- resultout                   : Parameter To Store resultout(IN OUT)
  -- ==============================================================================
  PROCEDURE xx_om_apply_prepay_hold(itemtype  IN VARCHAR2,
                                    itemkey   IN VARCHAR2,
                                    actid     IN NUMBER,
                                    funcmode  IN VARCHAR2,
                                    resultout IN OUT NOCOPY VARCHAR2) IS
    x_order_tbl     oe_holds_pvt.order_tbl_type;
    x_hold_id       NUMBER;
    x_msg_count     NUMBER;
    x_hold_count    NUMBER;
    x_err_msg       VARCHAR2(1000);
    x_return_status VARCHAR2(100);
    x_msg_data      VARCHAR2(100);
    x_term_name     VARCHAR2(100);
    x_pc_term_name  VARCHAR2(100);
    x_order_type    VARCHAR2(240);
    x_creation_date DATE;
    e_hold_id EXCEPTION;
    e_hold_error EXCEPTION;
    x_hold_source_rec oe_holds_pvt.hold_source_rec_type;

    -- Cursor to fetch SO details
    CURSOR c_oe_order_hdr(p_itemkey NUMBER) IS
      SELECT trv.name payment_type, ottt.name order_type
        FROM oe_order_headers        ooha,
             ra_terms_vl             trv,
             oe_transaction_types_tl ottt
       WHERE ooha.header_id = p_itemkey
         AND ooha.payment_term_id = trv.term_id
         AND ooha.order_type_id = ottt.transaction_type_id
         AND ottt.language = 'US';

    -- Cursor to fetch HOLD ID
    CURSOR c_hold_id(p_hold_name VARCHAR2) IS
      SELECT hold_id
        FROM oe_hold_definitions
       WHERE NAME = p_hold_name
         AND type_code = 'HOLD'
         AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active, TRUNC(SYSDATE)) AND
             NVL(end_date_active, TRUNC(SYSDATE))
      --AND item_type = 'OEOH'
      ;

    -- Cursor to check Dup Hold
    CURSOR c_hold_count(p_hold_id NUMBER, p_header_id NUMBER) IS
      SELECT COUNT(*)
        FROM oe_hold_sources_all
       WHERE hold_id = p_hold_id
         AND released_flag = 'Y'
         AND hold_entity_id = p_header_id;
  BEGIN
    IF (funcmode = 'RUN') THEN
      x_pc_term_name := xx_emf_pkg.get_paramater_value(g_process_name,
                                                       g_prepay_term_name);
      OPEN c_oe_order_hdr(TO_NUMBER(itemkey));

      FETCH c_oe_order_hdr
        INTO x_term_name, x_order_type;

      IF c_oe_order_hdr%NOTFOUND THEN
        x_term_name  := Null;
        x_order_type := Null;
      END IF;

      CLOSE c_oe_order_hdr;

    /*  OPEN c_hold_count(x_hold_id, TO_NUMBER(itemkey));

      FETCH c_hold_count
        INTO x_hold_count;

      IF c_hold_count%NOTFOUND THEN
        x_hold_count := 0;
      END IF;

      CLOSE c_hold_count; */

      IF x_term_name = x_pc_term_name AND
         x_order_type IN
         (xx_emf_pkg.get_paramater_value(g_process_name, g_prepay_trans_1),
          xx_emf_pkg.get_paramater_value(g_process_name, g_prepay_trans_2),
          xx_emf_pkg.get_paramater_value(g_process_name, g_prepay_trans_3),
          xx_emf_pkg.get_paramater_value(g_process_name, g_prepay_trans_4),
          xx_emf_pkg.get_paramater_value(g_process_name, g_prepay_trans_5),
          xx_emf_pkg.get_paramater_value(g_process_name, g_prepay_trans_6),
          xx_emf_pkg.get_paramater_value(g_process_name, g_prepay_trans_7),
          xx_emf_pkg.get_paramater_value(g_process_name, g_prepay_trans_8),
          xx_emf_pkg.get_paramater_value(g_process_name, g_prepay_trans_9)) THEN


      OPEN c_hold_id(xx_emf_pkg.get_paramater_value(g_process_name,
                                                    g_prepay_hold_name));

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

    resultout := 'COMPLETE:COMPLETE';
    RETURN;

  EXCEPTION
    WHEN e_hold_error THEN
      wf_core.CONTEXT('xx_om_prepay_hold_pkg',
                      'xx_om_apply_prepay_hold ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || x_err_msg);
      RAISE;
    WHEN e_hold_id THEN
      wf_core.CONTEXT('xx_om_prepay_hold_pkg',
                      'xx_om_apply_prepay_hold ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : Hold Not Define In Oracle');
      RAISE;
    WHEN OTHERS THEN
      wf_core.CONTEXT('xx_om_prepay_hold_pkg',
                      'xx_om_apply_prepay_hold ',
                      itemtype,
                      itemkey,
                      TO_CHAR(actid),
                      funcmode,
                      'ERROR : ' || SQLERRM);
      RAISE;
  END xx_om_apply_prepay_hold;

  FUNCTION chk_prepay_hold(headerid IN NUMBER) RETURN VARCHAR2 IS
    l_pre_msg varchar2(250);
    l_count   number;
  BEGIN
    l_pre_msg := Null;
    l_count   := 0;

    SELECT count(*)
      INTO l_count
      FROM oe_hold_definitions a, oe_hold_sources_all b
     WHERE a.NAME =
           xx_emf_pkg.get_paramater_value(g_process_name,
                                          g_prepay_hold_name)
       AND a.type_code = 'HOLD'
       AND TRUNC(SYSDATE) BETWEEN NVL(a.start_date_active, TRUNC(SYSDATE)) AND
           NVL(a.end_date_active, TRUNC(SYSDATE))
       AND b.hold_id = a.hold_id
       AND b.released_flag = 'N'
       AND b.hold_entity_id = headerid;

    IF l_count > 0 THEN
      l_pre_msg := 'Pre-Pay Order Hold Has Been Applied On This Order.';
    ELSE
      l_pre_msg := Null;
    END IF;

    return l_pre_msg;

  EXCEPTION
    WHEN OTHERS THEN
      return l_pre_msg;
  END chk_prepay_hold;

END xx_om_prepay_hold_pkg;
/
