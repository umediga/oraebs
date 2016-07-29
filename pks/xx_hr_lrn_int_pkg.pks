DROP PACKAGE APPS.XX_HR_LRN_INT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_LRN_INT_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 06-Aug-2013
 File Name     : xx_hr_lrn_int.pks
 Description   : This script creates the specification of the package
                 xx_hr_lrn_int_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 08-Apr-2013 Renjith               Initial Version
 20-Nov-2013 Francis               Code added for CASE-3481
*/
----------------------------------------------------------------------
  Function special_char_rep(p_name IN VARCHAR2) RETURN VARCHAR2;

  PROCEDURE main ( p_errbuf            OUT   VARCHAR2
                  ,p_retcode           OUT   VARCHAR2
                  ,p_email_flag        IN    VARCHAR2);


END xx_hr_lrn_int_pkg;
/
