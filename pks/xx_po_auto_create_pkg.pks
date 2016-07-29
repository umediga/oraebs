DROP PACKAGE APPS.XX_PO_AUTO_CREATE_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_PO_AUTO_CREATE_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 25-MAR-14
 File Name     : XXPOAUTOCREATEBE.pkb
 Description   : This script creates package specification for xx_po_auto_create_pkg
 Change History:

 Date        Name                Remarks
 ----------- ------------        -------------------------------------
 25-MAR-14    Sharath Babu       Initial Version 
*/
----------------------------------------------------------------------

   FUNCTION xx_upd_note_to_sup(
                               p_subscription_guid   IN              RAW,
                               p_event               IN OUT NOCOPY   wf_event_t
                              )
      RETURN VARCHAR2;
END xx_po_auto_create_pkg;
/
