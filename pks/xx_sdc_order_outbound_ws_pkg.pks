DROP PACKAGE APPS.XX_SDC_ORDER_OUTBOUND_WS_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_SDC_ORDER_OUTBOUND_WS_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By	: Renjith
 Creation Date	: 12-Feb-2014
 File Name	: XX_SDC_ORDER_INT.pks
 Description	: This script creates the specification of the package

 Change History:

 Date          Name           Remarks
 -----------   ----           ---------------------------------------
 12-Feb-2014   Renjith        Initial development.
*/
----------------------------------------------------------------------

   PROCEDURE get_header_details ( p_mode               IN              VARCHAR2
                                 ,p_publish_batch_id   IN              NUMBER
                                 ,p_instance_id        IN              NUMBER
                                 ,x_head_out_tab       OUT NOCOPY      xx_sfdc_order_head_out_tabtyp
                                 ,x_return_status      OUT NOCOPY      VARCHAR2
                                 ,x_return_message     OUT NOCOPY      VARCHAR2
                                );

   PROCEDURE get_line_details   ( p_mode               IN              VARCHAR2
                                 ,p_publish_batch_id   IN              NUMBER
                                 ,p_instance_id        IN              NUMBER
                                 ,x_line_out_tab       OUT NOCOPY      xx_sfdc_order_line_out_tabtyp
                                 ,x_return_status      OUT NOCOPY      VARCHAR2
                                 ,x_return_message     OUT NOCOPY      VARCHAR2
                                );

   PROCEDURE get_del_details    ( p_mode               IN              VARCHAR2
                                 ,p_publish_batch_id   IN              NUMBER
                                 ,p_instance_id        IN              NUMBER
                                 ,x_del_out_tab        OUT NOCOPY      xx_sfdc_order_del_out_tabtyp
                                 ,x_return_status      OUT NOCOPY      VARCHAR2
                                 ,x_return_message     OUT NOCOPY      VARCHAR2
                                );

   PROCEDURE header_status_update( p_head_status_tab    IN              xx_sfdc_order_hd_status_tabtyp
                                  ,x_return_status      OUT NOCOPY      VARCHAR2
                                  ,x_return_message     OUT NOCOPY      VARCHAR2
                                );

   PROCEDURE line_status_update  ( p_line_status_tab    IN              xx_sfdc_order_ln_status_tabtyp
                                  ,x_return_status      OUT NOCOPY      VARCHAR2
                                  ,x_return_message     OUT NOCOPY      VARCHAR2
                                );

   PROCEDURE del_status_update   ( p_del_status_tab     IN              xx_sfdc_order_dl_status_tabtyp
                                  ,x_return_status      OUT NOCOPY      VARCHAR2
                                  ,x_return_message     OUT NOCOPY      VARCHAR2
                                );
END xx_sdc_order_outbound_ws_pkg;
/
