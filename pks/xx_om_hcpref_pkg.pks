DROP PACKAGE APPS.XX_OM_HCPREF_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OM_HCPREF_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM
 Creation Date : 04-FEB-2014
 File Name     : XX_OM_HCPREF_PKG.pks
 Description   : This script creates the specification of the package
		 xx_om_hcpref_pkg
 Change History:
 Date        Name                Remarks
 ----------- -------------       -----------------------------------
 04-FEB-2014 Renjith             Initial Development
*/
----------------------------------------------------------------------

   PROCEDURE main (  p_errbuf        OUT  VARCHAR2
                    ,p_retcode       OUT  NUMBER
                    ,p_refresh       IN   VARCHAR2
                    ,p_clear         IN   VARCHAR2
                    );

END xx_om_hcpref_pkg;
/
