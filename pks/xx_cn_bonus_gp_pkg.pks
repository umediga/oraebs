DROP PACKAGE APPS.XX_CN_BONUS_GP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_CN_BONUS_GP_PKG" AUTHID CURRENT_USER
AS

----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 29-Mar-12
 File Name     : XXCNBONUSGP.pks
 Description   : This script creates the specification of the package
                 xx_cn_bonus_gp_pkg
 Change History:
 Date         Name                   Remarks
 -----------  -------------          -----------------------------------
 29-Mar-12    IBM Development Team   Initial development.
*/
----------------------------------------------------------------------


g_total_cnt     NUMBER ;
g_error_cnt     NUMBER ;
g_success_cnt   NUMBER ;
g_warn_cnt      NUMBER ;


PROCEDURE xx_insert_record (errbuf OUT VARCHAR2,
                            retcode OUT VARCHAR2);

PROCEDURE update_record_count;


END xx_cn_bonus_gp_pkg;
/
