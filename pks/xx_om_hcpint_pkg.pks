DROP PACKAGE APPS.XX_OM_HCPINT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OM_HCPINT_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM
 Creation Date : 04-FEB-2014
 File Name     : XX_OM_HCPINT_PKG.pks
 Description   : This script creates the specification of the package
		 xx_om_hcpint_pkg
 Change History:
 Date        Name                Remarks
 ----------- -------------       -----------------------------------
 04-FEB-2014 Renjith             Initial Development
*/
----------------------------------------------------------------------

   PROCEDURE main (  p_errbuf        OUT  VARCHAR2
                    ,p_retcode       OUT  NUMBER
                    ,p_update        IN   VARCHAR2
                    ,p_inactive      IN   VARCHAR2
                    ,p_insert        IN   VARCHAR2
                    ,p_report        IN   VARCHAR2
                    );

END xx_om_hcpint_pkg;
/
