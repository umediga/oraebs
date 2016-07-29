DROP PACKAGE APPS.XX_WSH_PUBLISH_ASN_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_WSH_PUBLISH_ASN_PKG" 
AUTHID CURRENT_USER IS
/* $Header: xxwshpublishasnpkg.pls 1.0.0 2012/02/27 08:48:59 bedabrata no ship $ */
-----------------------------------------------------------------------------------
/*
 Created By   : Bedabrata Bhattacharjee
 Creation Date: 27-Feb-2012
 Filename     : XXWSHPUBLISHASNPKG.pks
 Description  : ASN Publish Public API

 Change History:

 Date        Version#   Name                         Remarks
 ----------- --------   ----                         ------------------------------
 27-Feb-2012   1.0      Bedabrata Bhattacharjee      Initial development.
 30-Aug-2012   1.1      Bedabrata Bhattacharjee      Exposed xx_publish_gxs_ghx function
                                                     in package specification.

*/
-----------------------------------------------------------------------------------

   -- This is a subscription function for oracle.apps.wsh.delivery.gen.shipconfirmed
   -- business event which gets trigerred when we Shipconfirm a Delivery
   FUNCTION xx_publish_shipconfirmed (
      p_subscription_guid   IN              RAW
    , p_event               IN OUT NOCOPY   wf_event_t
   )
      RETURN VARCHAR2;

   -- This procedure is used by the republish concurrent program
   PROCEDURE xx_republish_asn (
      p_errbuf          OUT NOCOPY      VARCHAR2
    , p_retcode         OUT NOCOPY      VARCHAR2
    , p_type            IN              VARCHAR2
    , p_delivery_from   IN              NUMBER
    , p_delivery_to     IN              NUMBER
    , p_date_from       IN              DATE
    , p_date_to         IN              DATE
   );

   -- This function returns Y if the delivery customer is interested in EDI 856 transaction.
   FUNCTION xx_publish_gxs_ghx (p_delivery_id IN NUMBER)
      RETURN VARCHAR2;

   -- This function returns single saler Order header id for the delivery id passed if source is GHX/GXS
   FUNCTION xx_source_header_id (p_delivery_id IN NUMBER)
      RETURN NUMBER;
END xx_wsh_publish_asn_pkg;
/
