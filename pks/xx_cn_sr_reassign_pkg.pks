DROP PACKAGE APPS.XX_CN_SR_REASSIGN_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_CN_SR_REASSIGN_PKG" AUTHID CURRENT_USER
AS
/* $Header: XXOICPOPSALESREPS.pks 1.0.0 2012/05/18 00:00:00 partha noship $ */
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 18-May-2012
 File Name     : XXOICPOPSALESREPS.pks
 Description   : This script creates the specification of the package
                 xx_cn_sr_reassign_pkg
 Change History:
 Date         Name                   Remarks
 -----------  -------------          -----------------------------------
 18-May-2012  IBM Development Team   Initial development.
*/
----------------------------------------------------------------------


g_total_cnt     NUMBER ;
g_error_cnt     NUMBER ;
g_success_cnt   NUMBER ;
g_warn_cnt      NUMBER ;


PROCEDURE xx_insert_record (o_errbuf OUT VARCHAR2,
                            o_retcode OUT VARCHAR2);

PROCEDURE update_record_count;


END xx_cn_sr_reassign_pkg;
/
