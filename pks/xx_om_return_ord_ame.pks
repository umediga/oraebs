DROP PACKAGE APPS.XX_OM_RETURN_ORD_AME;

CREATE OR REPLACE PACKAGE APPS.xx_om_return_ord_ame
AS
----------------------------------------------------------------------
/*
 Created By    : Yogesh
 Creation Date : 04-JUL-2012
 File Name     : xxomretordame.pks
 Description   : This script creates the specification of the package
         body xx_om_return_ord_ame
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 04-JUL-2012 Yogesh                Initial Development
 27-FEB-2015 Dhiren                Modified as per WAVE2 Requirment
*/
----------------------------------------------------------------------

g_chr_pkg_name          VARCHAR2(30) := 'XX_OM_RETURN_ORD_AME';
g_chr_transaction_type  VARCHAR2 (200) ;
g_num_err_loc_code      NUMBER (5);
g_appr_msg_body         VARCHAR2 (2000) ;

PROCEDURE cust_get_approver( p_itemType   IN         VARCHAR2
                            ,p_itemKey    IN         VARCHAR2
                            ,p_activityId IN         NUMBER
                            ,funmode      IN         VARCHAR2
                            ,result       OUT NOCOPY VARCHAR2
                           );

----------------------------------------------------------------------

PROCEDURE upd_appr_status( p_itemType   IN         VARCHAR2
                          ,p_itemKey    IN         VARCHAR2
                          ,p_activityId IN         NUMBER
                          ,funmode      IN         VARCHAR2
                          ,result       OUT NOCOPY VARCHAR2
                         );

----------------------------------------------------------------------

PROCEDURE upd_rejected_status( p_itemType   IN         VARCHAR2
                              ,p_itemKey    IN         VARCHAR2
                              ,p_activityId IN         NUMBER
                              ,funmode      IN         VARCHAR2
                              ,result       OUT NOCOPY VARCHAR2
                             );

----------------------------------------------------------------------

PROCEDURE init_variables( p_itemType   IN         VARCHAR2
                         ,p_itemKey    IN         VARCHAR2
                         ,p_activityId IN         NUMBER
                         ,funmode      IN         VARCHAR2
                         ,result       OUT NOCOPY VARCHAR2
                        );

----------------------------------------------------------------------

PROCEDURE clear_all_approvals( p_itemType   IN         VARCHAR2
                              ,p_itemKey    IN         VARCHAR2
                              ,p_activityId IN         NUMBER
                              ,funmode      IN         VARCHAR2
                              ,result       OUT NOCOPY VARCHAR2
                             );

----------------------------------------------------------------------

PROCEDURE skip_ame_approvals( p_itemType   IN         VARCHAR2
                             ,p_itemKey    IN         VARCHAR2
                             ,p_activityId IN         NUMBER
                             ,funmode      IN         VARCHAR2
                             ,result       OUT NOCOPY VARCHAR2
                            );
----------------------------------------------------------------------

PROCEDURE assign_salesrep( p_itemType   IN         VARCHAR2
                          ,p_itemKey    IN         VARCHAR2
                          ,p_activityId IN         NUMBER
                          ,funmode      IN         VARCHAR2
                          ,result       OUT NOCOPY VARCHAR2
                         );
----------------------------------------------------------------------
PROCEDURE get_next_hrmgr( p_itemType   IN         VARCHAR2
                         ,p_itemKey    IN         VARCHAR2
                         ,p_activityId IN         NUMBER
                         ,funmode      IN         VARCHAR2
                         ,result       OUT NOCOPY VARCHAR2
                         );
----------------------------------------------------------------------
PROCEDURE chk_ord_trx_type( p_itemType   IN         VARCHAR2
                           ,p_itemKey    IN         VARCHAR2
                           ,p_activityId IN         NUMBER
                           ,funmode      IN         VARCHAR2
                           ,result       OUT NOCOPY VARCHAR2
                          );
----------------------------------------------------------------------
FUNCTION calc_timeout_days (p_orig_days  NUMBER)
RETURN NUMBER;

--- To Add HTML Table
PROCEDURE xx_doc_call
(
itemtype  IN  VARCHAR2,
itemkey   IN  VARCHAR2,
actid     IN  NUMBER,
funcmode  IN  VARCHAR2,
resultout OUT VARCHAR2
);

PROCEDURE xx_chk_flag( p_itemType   IN         VARCHAR2
                      ,p_itemKey    IN         VARCHAR2
                      ,p_activityId IN         NUMBER
                      ,funmode      IN         VARCHAR2
                      ,result       OUT NOCOPY VARCHAR2
                      );

PROCEDURE xx_create_msg_wf
(
document_id     IN              VARCHAR2,
display_type    IN              VARCHAR2,
document        IN OUT NOCOPY   CLOB,
document_type   IN OUT NOCOPY   VARCHAR2
);

PROCEDURE xx_om_appr_message_body(p_msg_body varchar2,p_header_id number,p_mode varchar2);

--- WareHouse Validation ---
PROCEDURE xx_chk_warehouse(  p_itemType   IN         VARCHAR2
                            ,p_itemKey    IN         VARCHAR2
                            ,p_activityId IN         NUMBER
                            ,funmode      IN         VARCHAR2
                            ,result       OUT NOCOPY VARCHAR2
                          );

--- payment Term Validation ---
PROCEDURE xx_chk_payment_term(  p_itemType   IN         VARCHAR2
                               ,p_itemKey    IN         VARCHAR2
                               ,p_activityId IN         NUMBER
                               ,funmode      IN         VARCHAR2
                               ,result       OUT NOCOPY VARCHAR2
                             );

--- price list Validation ---
PROCEDURE xx_chk_price_list(  p_itemType   IN         VARCHAR2
                             ,p_itemKey    IN         VARCHAR2
                             ,p_activityId IN         NUMBER
                             ,funmode      IN         VARCHAR2
                             ,result       OUT NOCOPY VARCHAR2
                           );

--- Quantity Validation ---
PROCEDURE xx_chk_line_quantity(  p_itemType   IN         VARCHAR2
                                ,p_itemKey    IN         VARCHAR2
                                ,p_activityId IN         NUMBER
                                ,funmode      IN         VARCHAR2
                                ,result       OUT NOCOPY VARCHAR2
                              );

PROCEDURE xx_chk_order_typ(  p_itemType   IN         VARCHAR2
                            ,p_itemKey    IN         VARCHAR2
                            ,p_activityId IN         NUMBER
                            ,funmode      IN         VARCHAR2
                            ,result       OUT NOCOPY VARCHAR2

                          );

END xx_om_return_ord_ame;
/
