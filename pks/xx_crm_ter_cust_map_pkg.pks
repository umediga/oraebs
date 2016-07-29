DROP PACKAGE APPS.XX_CRM_TER_CUST_MAP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_CRM_TER_CUST_MAP_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : xxcrmtercustmap.pks
 Description   : This script creates the specification of the package
                 xx_crm_ter_cust_map_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 12-Aug-2014 Yogesh                Initial Version
*/
----------------------------------------------------------------------

PROCEDURE main_prc( x_error_code    OUT   NUMBER
                   ,x_error_msg     OUT   VARCHAR2);

END xx_crm_ter_cust_map_pkg;
/
