DROP PACKAGE APPS.XX_AR_INVOICE_OUTBOUND_WS_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_INVOICE_OUTBOUND_WS_PKG" 
IS

--------------------------------------------------------------------------------
 /*
 Created By     : Deepika Jain
 Creation Date  : 05-APR-2012
 Filename       : XXARINVOUTWS.pks
 Description    : Invoice Outbound Web Service API.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 05-APR-2012   1.0       Deepika Jain         Initial development.

 */
--------------------------------------------------------------------------------
   PROCEDURE get_invoice_details (
      p_mode               IN              VARCHAR2,
      p_publish_batch_id   IN              NUMBER,
      p_ar_input_invoice   IN              xx_ar_input_inv_ws_out_tabtyp,
      x_ar_output_invoice  OUT NOCOPY      xx_ar_inv_outbound_ws_tabtyp,
      x_return_status      OUT NOCOPY      VARCHAR2,
      x_return_message     OUT NOCOPY      VARCHAR2
   );

   PROCEDURE update_ack (
      p_publish_batch_id        IN              NUMBER,
      p_publish_system          IN              VARCHAR2,
      p_ack_status              IN              VARCHAR2,
      p_aia_proc_inst_id        IN              VARCHAR2,
      x_return_status           OUT NOCOPY      VARCHAR2,
      x_return_message          OUT NOCOPY      VARCHAR2
   );


   FUNCTION get_order_header_id (
      p_customer_trx_id   NUMBER
   )
   RETURN NUMBER;

   FUNCTION get_notes (
      p_customer_trx_id   NUMBER
   )
   RETURN VARCHAR2;

END xx_ar_invoice_outbound_ws_pkg;
/
