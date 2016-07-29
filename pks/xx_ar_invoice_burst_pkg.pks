DROP PACKAGE APPS.XX_AR_INVOICE_BURST_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_INVOICE_BURST_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : XX_AR_INVOICE_BURST_PKG.pks
 Description   : This script creates the specification of the package
                 xx_ar_invoice_burst_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 28-Feb-2013 Renjith               Initial Version
*/
----------------------------------------------------------------------

   PROCEDURE launch_bursting( errbuf          OUT  VARCHAR2,
                              retcode         OUT  NUMBER,
                              p_request_id    IN   NUMBER);

END xx_ar_invoice_burst_pkg;
/
