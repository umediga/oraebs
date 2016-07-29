DROP PACKAGE APPS.SSP_SSPRPWKS_XMLP_PKG;

CREATE OR REPLACE PACKAGE APPS.SSP_SSPRPWKS_XMLP_PKG AUTHID CURRENT_USER AS
/* $Header: SSPRPWKSS.pls 120.1 2007/12/24 14:08:12 amakrish noship $ */
	P_BUSINESS_GROUP_ID	number;
	P_SESSION_DATE	date;
	LP_SESSION_DATE date;
	P_CONC_REQUEST_ID	number;
	P_PAYROLL	number;
	L_PAYROLL_ID	varchar2(80);
	C_BUSINESS_GROUP_NAME	varchar2(240);
	C_REPORT_SUBTITLE	varchar2(60);
	C_PAYROLL_NAME	varchar2(80);
	function BeforeReport return boolean  ;
	function AfterReport return boolean  ;
	Function C_BUSINESS_GROUP_NAME_p return varchar2;
	Function C_REPORT_SUBTITLE_p return varchar2;
	Function C_PAYROLL_NAME_p return varchar2;
--Added during DT Fix
        procedure Fetch_Payroll_name;
        procedure Fetch_Business_group_name;
--End of DT Fix
END SSP_SSPRPWKS_XMLP_PKG;

/


GRANT EXECUTE ON APPS.SSP_SSPRPWKS_XMLP_PKG TO INTG_NONHR_NONXX_RO;
