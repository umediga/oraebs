DROP PACKAGE APPS.XXINTG_SUPPLIER_LINES;

CREATE OR REPLACE PACKAGE APPS.XXINTG_SUPPLIER_LINES AS
----------------------------------------------------------------------
/*
 Created By     : Shradha
 Creation Date  : 10-Mar-2015
 File Name      : XXINTG_SUPPLIER_LINES.sql
 Description    : This script pricelist load data using staging table data.

Change History:

Version Date        Name                  Remarks
------- ----------- ---------            ------------------------------------
1.0     10-Mar-2014 Shradha              Initial development.
-----------------------------------------------------------------------------
*/
PROCEDURE XXINTG_SUPPLIER_DATA (RETCODE out number,
	                       ERR_BUF out varchar);

END XXINTG_SUPPLIER_LINES;
/
