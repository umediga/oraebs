DROP PACKAGE APPS.XX_OM_LINE_PRICE_CHECK;

CREATE OR REPLACE PACKAGE APPS.xx_om_line_price_check AUTHID CURRENT_USER
----------------------------------------------------------------------
/* $Header: XXOMLINEPRICEWF.pks 1.0 2012/02/08 12:00:00 dparida noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 08-Feb-2012
 File Name      : XXOMLINEPRICEWF.pks
 Description    : This script creates the specification of the xx_om_line_price_check package

 Change History:

 Version Date        Name            Remarks
 ------- ----------- ----            ----------------------
 1.0     08-Feb-12   IBM Development Team    Initial development.
 1.1     27-Feb-12   IBM Development Team    Added the logic for Process Setup Form
 2.0     20-Jul-13   Yogesh          Added changes for WAVE1
 3.0     03-Feb-14   Dhiren          Added changes for WAVE1A
*/
----------------------------------------------------------------------
 AS
  -- =================================================================================
  -- These Global Variables are used to extract value from the process setup form
  -- =================================================================================
  g_hold_name            VARCHAR2(50) := 'HOLD_NAME';
  g_hdr_hold_name        VARCHAR2(50) := 'HDR_HOLD_NAME';
  g_release_reason_code  VARCHAR2(50) := 'RELEASE_REASON_CODE';
  g_process_name         VARCHAR2(50) := 'XXOMPRICEOVERRIDEEXT';
  g_hold_type            VARCHAR2(50) := 'HOLD_TYPE';
  g_item_type            VARCHAR2(50) := 'ITEM_TYPE';
  g_cost_type            VARCHAR2(50) := 'COST_TYPE';
  g_chr_transaction_type VARCHAR2(200);

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
                                      resultout IN OUT NOCOPY VARCHAR2);

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
                                         resultout IN OUT NOCOPY VARCHAR2);

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
                                    resultout IN OUT NOCOPY VARCHAR2);

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
                                   resultout IN OUT NOCOPY VARCHAR2);

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
                               resultout IN OUT NOCOPY VARCHAR2);

  -- =================================================================================
  -- Name           : get_supervisor
  -- Description    : Function to check if a supervisor exist or not;Returns Y/N
  -- User parameter - p_user_id
  -- ==================================================================================
  FUNCTION get_supervisor(p_userid IN NUMBER) RETURN VARCHAR2;

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
                               resultout IN OUT NOCOPY VARCHAR2);
  ----------------------------------------------------------------------

  PROCEDURE upd_appr_status(p_itemType   IN VARCHAR2,
                            p_itemKey    IN VARCHAR2,
                            p_activityId IN NUMBER,
                            funmode      IN VARCHAR2,
                            result       OUT NOCOPY VARCHAR2);

  PROCEDURE upd_lnr_appr_status(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout IN OUT NOCOPY VARCHAR2);

  ----------------------------------------------------------------------

  PROCEDURE upd_rejected_status(p_itemType   IN VARCHAR2,
                                p_itemKey    IN VARCHAR2,
                                p_activityId IN NUMBER,
                                funmode      IN VARCHAR2,
                                result       OUT NOCOPY VARCHAR2);
  ----------------------------------------------------------------------

  PROCEDURE clear_all_approvals(p_itemType   IN VARCHAR2,
                                p_itemKey    IN VARCHAR2,
                                p_activityId IN NUMBER,
                                funmode      IN VARCHAR2,
                                result       OUT NOCOPY VARCHAR2);
  ----------------------------------------------------------------------

  PROCEDURE get_next_hrmgr(p_itemType   IN VARCHAR2,
                           p_itemKey    IN VARCHAR2,
                           p_activityId IN NUMBER,
                           funmode      IN VARCHAR2,
                           result       OUT NOCOPY VARCHAR2);
  ----------------------------------------------------------------------

  FUNCTION hold_msg_display(p_header_id IN NUMBER) RETURN VARCHAR2;

/*FUNCTION calc_timeout_days (p_orig_days  NUMBER)
RETURN NUMBER;*/

--- To Add HTML Table
PROCEDURE xx_create_doc_wf
(
document_id     IN              VARCHAR2,
display_type    IN              VARCHAR2,
document        IN OUT NOCOPY   CLOB,
document_type   IN OUT NOCOPY   VARCHAR2
);

PROCEDURE xx_doc_call
(
itemtype  IN  VARCHAR2,
itemkey   IN  VARCHAR2,
actid     IN  NUMBER,
funcmode  IN  VARCHAR2,
resultout OUT VARCHAR2
);


END xx_om_line_price_check;
/
