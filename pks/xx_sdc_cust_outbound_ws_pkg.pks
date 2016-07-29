DROP PACKAGE APPS.XX_SDC_CUST_OUTBOUND_WS_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_SDC_CUST_OUTBOUND_WS_PKG" 
AUTHID CURRENT_USER IS
/* $Header: XXSDCCUSTOUTWS.pks 1.0.0 2014/02/12 00:00:00  noship $ */
--------------------------------------------------------------------------------
 /*
 Created By     : Yogesh
 Creation Date  : 12-FEB-2014
 Filename       : XXSDCCUSTOUTWS.pks
 Description    : Customer Outbound Web Service API.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 12-Feb-2014   1.0       Yogesh              Initial development.

 */
--------------------------------------------------------------------------------
   /*FUNCTION xx_get_line_item_status_code (
      p_source_header_id   NUMBER,
      p_source_line_id     NUMBER
   )
      RETURN VARCHAR2;*/

      PROCEDURE xx_get_customer (
         p_mode                 IN              VARCHAR2,
         p_publish_batch_id     IN              NUMBER,
         p_cust_accont_id_ls    IN              xx_sdc_in_cust_ws_ot_tabtyp,
         x_output_Customer      OUT NOCOPY      xx_sdc_cust_otbound_ws_tabtyp,
         x_return_status        OUT NOCOPY      VARCHAR2,
         x_return_message       OUT NOCOPY      VARCHAR2
   );

--------------------------------------------------------------------------------
   FUNCTION sdc_publish_customer ( p_subscription_guid   IN              RAW,
                                   p_event               IN OUT NOCOPY   wf_event_t
                                 )
   RETURN VARCHAR2;

   /*PROCEDURE xx_update_ack (
      p_publish_batch_id   IN              NUMBER,
      p_publish_system     IN              VARCHAR2,
      p_ack_status         IN              VARCHAR2,
      p_aia_proc_inst_id   IN              VARCHAR2,
      x_return_status      OUT NOCOPY      VARCHAR2,
      x_return_message     OUT NOCOPY      VARCHAR2
   );*/

   FUNCTION get_territories( p_country             VARCHAR2 ,
                                p_customer_id         NUMBER ,
                                p_site_number         NUMBER,
                                p_cust_account        VARCHAR2,
                                p_county              VARCHAR2,
                                p_postal_code         VARCHAR2,
                                p_province            VARCHAR2,
                                p_state               VARCHAR2,
                                p_cust_name           VARCHAR2
                              )
   RETURN VARCHAR2;

END xx_sdc_cust_outbound_ws_pkg;
/
