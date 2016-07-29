DROP PACKAGE APPS.XXINTG_WSH_BR100_DATA;

CREATE OR REPLACE PACKAGE APPS.XXINTG_WSH_BR100_DATA AS
----------------------------------------------------------------------
/*
 Created By     : Ravisankar
 Creation Date  : 25-Feb-2015
 File Name      : XXINTG_WSH_REGIONS.sql
 Description    : This script Region load data using staging table data.

Change History:

Version Date        Name                  Remarks
------- ----------- ---------            ------------------------------------
1.0     25-Feb-2014 Ravisankar            Initial development.
-----------------------------------------------------------------------------
*/
PROCEDURE XXINTG_BR100_DATA (RETCODE out number,
	                       ERR_BUF out varchar);

END XXINTG_WSH_BR100_DATA;
/
