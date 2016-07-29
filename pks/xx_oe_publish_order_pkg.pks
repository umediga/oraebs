DROP PACKAGE APPS.XX_OE_PUBLISH_ORDER_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OE_PUBLISH_ORDER_PKG" 
AUTHID CURRENT_USER AS
/* $Header: XXOEPUBLISHORD.pks 1.0.0 2012/03/07 00:00:00 kdas noship $ */
--------------------------------------------------------------------------------
 /*
 Created By     : Koushik Das
 Creation Date  : 07-MAR-2012
 Filename       : XXOEPUBLISHORD.pks
 Description    : Sales Order Publish Public API.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 07-Mar-2012   1.0       Koushik Das         Initial development.
 28-Aug-2012   2.0       Koushik Das         Change datatype for p_order_from and p_order_to
                                             from VARCHAR2 to NUMBER.
 05-Sep-2012   1.0       Koushik Das         Added the procedure xx_publish_order_scheduled.

 */
--------------------------------------------------------------------------------

   -- This is a subscription function for oracle.apps.ont.oi.xml_int.status
   -- business event
   FUNCTION xx_publish_xmlint_status (
      p_subscription_guid   IN              RAW,
      p_event               IN OUT NOCOPY   wf_event_t
   )
      RETURN VARCHAR2;

   -- This procedure is used by the republish concurrent program
   PROCEDURE xx_republish_order (
      p_errbuf       OUT NOCOPY      VARCHAR2,
      p_retcode      OUT NOCOPY      VARCHAR2,
      p_type         IN              VARCHAR2,
      p_order_from   IN              NUMBER,
      p_order_to     IN              NUMBER,
      p_date_from    IN              VARCHAR2,
      p_date_to      IN              VARCHAR2
   );

   -- This function returns Y if the sales order is eligible for
   -- EDI 855 transaction.
   FUNCTION xx_publish_gxs_ghx (p_header_id IN NUMBER)
      RETURN VARCHAR2;

   -- This procedure is used by the scheduled publish concurrent program
   PROCEDURE xx_publish_order_scheduled (
      p_errbuf    OUT NOCOPY   VARCHAR2,
      p_retcode   OUT NOCOPY   VARCHAR2
   );
END xx_oe_publish_order_pkg;
/
