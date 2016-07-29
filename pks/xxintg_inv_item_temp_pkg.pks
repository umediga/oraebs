DROP PACKAGE APPS.XXINTG_INV_ITEM_TEMP_PKG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_INV_ITEM_TEMP_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 03-Aug-2013
 File Name     : XXINVITEMTEMPDET.pks
 Description   : This script creates the package body of
                 XXINTG_INV_ITEM_TEMP_PKG, which will produce report
                 output
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 03-Sep-2013 Debjani Roy           Initial Version
*/
----------------------------------------------------------------------
   PROCEDURE generate_report (errbuf    OUT VARCHAR2
                             ,retcode   OUT NUMBER
                             ,p_inv_org IN  NUMBER
                              );
END  XXINTG_INV_ITEM_TEMP_PKG;
/
