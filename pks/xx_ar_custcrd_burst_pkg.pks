DROP PACKAGE APPS.XX_AR_CUSTCRD_BURST_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_CUSTCRD_BURST_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : XX_AR_CUSTCRD_BURST_PKG.pks
 Description   : This script creates the specification of the package
                 xx_ar_custcrd_burst_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 17-Jun-2013 Rajesh Kendhuli       Initial Version
*/
----------------------------------------------------------------------

   PROCEDURE launch_bursting( errbuf          OUT  VARCHAR2,
                              retcode         OUT  NUMBER,
                              p_request_id    IN   NUMBER);

END xx_ar_custcrd_burst_pkg;
/
