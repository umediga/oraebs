DROP PACKAGE APPS.XX_IREC_REF_BONUS_NOTIF_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_IREC_REF_BONUS_NOTIF_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : xxirecrefbnsnotif.pks
 Description   : This script creates the specification of the package
                 xx_irec_ref_bonus_notif_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 30-Mar-2012 Yogesh                Initial Version
*/
----------------------------------------------------------------------

PROCEDURE main_prc( x_error_code    OUT   NUMBER
                   ,x_error_msg     OUT   VARCHAR2);

END xx_irec_ref_bonus_notif_pkg;
/
