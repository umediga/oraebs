DROP PACKAGE APPS.XX_SFDC_ITEM_OUT_CP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_SFDC_ITEM_OUT_CP_PKG" AS
--------------------------------------------------------------------------------
 /*
 Created By     : IBM
 Creation Date  : 06-MAR-2014
 Filename       : XXSFDCITEMOUTCP.pkb
 Description    : Item Outbound Web Service API.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 06-MAR-2014   1.0       ibm                 Initial development.

 */
--------------------------------------------------------------------------------

 PROCEDURE sfdc_publish_item_cp    (  p_errbuf           OUT  VARCHAR2
                                     ,p_retcode          OUT  NUMBER
                                     ,p_type             IN   VARCHAR2
                                     ,p_hidden1          IN   VARCHAR2
                                     ,p_hidden2          IN   VARCHAR2
                                     ,p_item_from        IN   NUMBER
                                     ,p_item_to          IN   NUMBER
                                     ,p_date_from        IN   VARCHAR2
                                     ,p_date_to          IN   VARCHAR2);

  FUNCTION raise_publish_event ( p_subscription_guid   IN              RAW
                                ,p_event               IN OUT NOCOPY   wf_event_t) RETURN VARCHAR2;

END xx_sfdc_item_out_cp_pkg;
/
