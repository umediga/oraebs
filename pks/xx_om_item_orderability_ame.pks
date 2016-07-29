DROP PACKAGE APPS.XX_OM_ITEM_ORDERABILITY_AME;

CREATE OR REPLACE PACKAGE APPS."XX_OM_ITEM_ORDERABILITY_AME" 
AS
----------------------------------------------------------------------
/*
 Created By    : Yogesh
 Creation Date : 22-SEP-2013
 File Name     : xxomitmordame.pks
 Description   : This script creates the specification of the package
                 xx_om_item_orderability_ame
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 22-SEP-2013 Yogesh                Initial Development
*/
----------------------------------------------------------------------
g_chr_pkg_name          VARCHAR2(30) := 'XX_OM_ITEM_ORDERABILITY_AME';
g_chr_transaction_type  VARCHAR2 (200) ;
g_num_err_loc_code      NUMBER (5);
g_line_cancel_reason    VARCHAR2(500);

PROCEDURE chk_item_orderability( p_itemType   IN         VARCHAR2
                                ,p_itemKey    IN         VARCHAR2
                                ,p_activityId IN         NUMBER
                                ,funmode      IN         VARCHAR2
                                ,result       OUT NOCOPY VARCHAR2
                               );

----------------------------------------------------------------------
PROCEDURE ame_nxt_appr (
                         itemtype    IN              VARCHAR2,
                         itemkey     IN              VARCHAR2,
                         actid       IN              NUMBER,
                         funcmode    IN              VARCHAR2,
                         resultout   IN OUT NOCOPY   VARCHAR2
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

PROCEDURE clear_all_approvals( p_itemType   IN         VARCHAR2
                              ,p_itemKey    IN         VARCHAR2
                              ,p_activityId IN         NUMBER
                              ,funmode      IN         VARCHAR2
                              ,result       OUT NOCOPY VARCHAR2
                             );

----------------------------------------------------------------------

PROCEDURE order_line_Cacellation( p_itemType   IN         VARCHAR2
                                 ,p_itemKey    IN         VARCHAR2
                                 ,p_activityId IN         NUMBER
                                 ,funmode      IN         VARCHAR2
                                 ,result       OUT NOCOPY VARCHAR2
                                );
----------------------------------------------------------------------
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
                            );
----------------------------------------------------------------------
PROCEDURE release_hold( p_itemType   IN         VARCHAR2
                       ,p_itemKey    IN         VARCHAR2
                       ,p_activityId IN         NUMBER
                       ,funmode      IN         VARCHAR2
                       ,result       OUT NOCOPY VARCHAR2
                      );
----------------------------------------------------------------------
FUNCTION chk_line_orderability(p_header_id  IN NUMBER)

RETURN VARCHAR2;

END xx_om_item_orderability_ame;
----------------------------------------------------------------------
/
