DROP PACKAGE APPS.XX_PER_TMP_EMP_NOTIF_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_PER_TMP_EMP_NOTIF_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : xxpertmpempnotif.pks
 Description   : This script creates the specification of the package
                 xx_per_tmp_emp_notif_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 16-Apr-2012 Yogesh                Initial Version
*/
----------------------------------------------------------------------

PROCEDURE main_prc( x_error_code    OUT   NUMBER
                   ,x_error_msg     OUT   VARCHAR2);

END xx_per_tmp_emp_notif_pkg;
/
