DROP PACKAGE APPS.XX_CNSGN_SSDY_RECON_PKG_EXPORT;

CREATE OR REPLACE PACKAGE APPS."XX_CNSGN_SSDY_RECON_PKG_EXPORT" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : Omkar (IBM Development)
 Creation Date : 27-Jun-2014
 File Name     : XX_CNSGN_SSDY_RECON_PKG_EXPORT.pks
 Description   : This script creates the specification of the package
                 XX_CNSGN_SSDY_RECON_PKG_EXPORT
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 21-Jun-2014 Omkar                Initial Version
*/
----------------------------------------------------------------------
PROCEDURE XX_CNSGN_RECON_R12_EXPORT         ( errbuf          OUT  VARCHAR2,
                              retcode         OUT  NUMBER
                                 );

procedure XX_CNSGN_RECON_SS_EXPORT         (

                              errbuf          OUT  VARCHAR2,
                              RETCODE         OUT  number,
                               cp_division     IN VARCHAR2,
                               cp_report_type  IN   VARCHAR2
                                 );

END XX_CNSGN_SSDY_RECON_PKG_EXPORT;
/
