DROP PACKAGE APPS.XX_P2P_HCP_EXTN;

CREATE OR REPLACE PACKAGE APPS."XX_P2P_HCP_EXTN" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 19-June-2013
File Name     : XXP2PHCPEXT.pks
Description   : This script creates the specification of the package xx_p2p_hcp_extn
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
19-June-2013  ABHARGAVA            Initial Draft.
*/
----------------------------------------------------------------------

-- Main Procedure
PROCEDURE main (errbuf                   OUT VARCHAR2,
                retcode                  OUT VARCHAR2
               );

END xx_p2p_hcp_extn;
/
