DROP PACKAGE APPS.XX_IRC_EMP_REF_NOTIF_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_IRC_EMP_REF_NOTIF_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : xxircemprefntf.pks
 Description   : This script creates the specification of the package
                 xx_irc_emp_ref_notif_pkg.
 Change History:
 Date           Name                    Remarks
 ----------- -------------         -----------------------------------
 08-May-2012 Rajeev Rath               Initial Version
*/
----------------------------------------------------------------------
PROCEDURE main_prc( x_error_code    OUT   NUMBER
                   ,x_error_msg     OUT   VARCHAR2);
END xx_irc_emp_ref_notif_pkg;
/
