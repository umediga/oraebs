DROP PACKAGE APPS.XX_OE_ORDER_OUTBOUND_WS_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OE_ORDER_OUTBOUND_WS_PKG" 
AUTHID CURRENT_USER IS
/* $Header: XXOEORDOUTWS.pks 1.0.0 2012/03/07 00:00:00 kdas noship $ */
--------------------------------------------------------------------------------
 /*
 Created By     : Koushik Das
 Creation Date  : 07-MAR-2012
 Filename       : XXOEORDOUTWS.pks
 Description    : Sales Order Outbound Web Service API.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 07-Mar-2012   1.0       Koushik Das         Initial development.

 */
--------------------------------------------------------------------------------
   FUNCTION xx_get_line_item_status_code (
      p_source_header_id   NUMBER,
      p_source_line_id     NUMBER
   )
      RETURN VARCHAR2;

   PROCEDURE xx_get_order (
      p_mode               IN              VARCHAR2,
      p_publish_batch_id   IN              NUMBER,
      p_oe_input_order     IN              xx_oe_input_ord_ws_out_tabtyp,
      x_oe_output_order    OUT NOCOPY      xx_oe_ord_outbound_ws_tabtyp,
      x_return_status      OUT NOCOPY      VARCHAR2,
      x_return_message     OUT NOCOPY      VARCHAR2
   );

   PROCEDURE xx_update_ack (
      p_publish_batch_id   IN              NUMBER,
      p_publish_system     IN              VARCHAR2,
      p_ack_status         IN              VARCHAR2,
      p_aia_proc_inst_id   IN              VARCHAR2,
      x_return_status      OUT NOCOPY      VARCHAR2,
      x_return_message     OUT NOCOPY      VARCHAR2
   );
END xx_oe_order_outbound_ws_pkg;
/
