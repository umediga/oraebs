DROP PACKAGE APPS.XX_SFDC_ITEM_OUT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_SFDC_ITEM_OUT_PKG" AS
--------------------------------------------------------------------------------
 /*
 Created By     : Dipankar Bagchi
 Creation Date  : 28-FEB-2014
 Filename       : XXSFDCITEMOUT.pks
 Description    : Item Outbound Web Service API.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 28-Feb-2014   1.0       Dipankar Bagchi     Initial development.
 23-May-2014   1.1       Renjith             Added p_instance_id
 */
--------------------------------------------------------------------------------

PROCEDURE get_item ( p_mode          IN            VARCHAR2
                    ,p_batch_id      IN            NUMBER
                    ,p_instance_id   IN            NUMBER
                    ,p_inv_id_ls     IN            x_sfdc_list_in_tabtyp
                    ,x_out_item      OUT  NOCOPY   x_sfdc_item_out_tabtyp
                    ,x_ret_status    OUT  NOCOPY   VARCHAR2
                    ,x_ret_msg       OUT  NOCOPY   VARCHAR2
                    );

FUNCTION sfdc_publish_item    ( p_subscription_guid   IN              RAW,
                                p_event               IN OUT NOCOPY   wf_event_t
                              )
RETURN VARCHAR2;
END xx_sfdc_item_out_pkg;
/
