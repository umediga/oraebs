DROP PACKAGE APPS.XX_WSH_ASN_OUTBOUND_WS_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_WSH_ASN_OUTBOUND_WS_PKG" 
AUTHID CURRENT_USER IS
/* $Header: XXWSHASNOUTBOUNDWS.pks 1.0.0 2012/03/20 00:00:00 bedabrata noship $ */
-----------------------------------------------------------------------------------
 /*
 Created By     : Bedabrata Bhattacharjee (IBM)
 Creation Date  : 20-MAR-2012
 Filename       : XXWSHASNOUTBOUNDWS.pks
 Description    : Approved Shipment Number (ASN) Outbound Web Service API.

 Change History:

 Date        Issue#   Name                           Remarks
 ----------- -------- -----------------------------  ------------------------------
 20-Mar-2012        1 Bedabrata Bhattacharjee (IBM)  Initial Development.

*/
-----------------------------------------------------------------------------------
   PROCEDURE xx_get_asn (
      p_mode               IN              VARCHAR2
    , p_publish_batch_id   IN              NUMBER
    , p_delivery_list      IN              xx_wsh_input_del_ws_tabtyp
    , x_wsh_output_asn     OUT NOCOPY      xx_wsh_asn_out_ws_tabtyp
    , x_return_status      OUT NOCOPY      VARCHAR2
    , x_return_message     OUT NOCOPY      VARCHAR2
   );

   PROCEDURE xx_update_ack (
      p_publish_batch_id   IN              NUMBER
    , p_publish_system     IN              VARCHAR2
    , p_aia_proc_inst_id   IN              NUMBER
    , p_ack_status         IN              VARCHAR2
    , x_return_status      OUT NOCOPY      VARCHAR2
    , x_return_message     OUT NOCOPY      VARCHAR2
   );
END xx_wsh_asn_outbound_ws_pkg;
/
