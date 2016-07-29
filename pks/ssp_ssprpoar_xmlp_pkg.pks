DROP PACKAGE APPS.SSP_SSPRPOAR_XMLP_PKG;

CREATE OR REPLACE PACKAGE APPS.SSP_SSPRPOAR_XMLP_PKG AUTHID CURRENT_USER AS
/* $Header: SSPRPOARS.pls 120.1 2007/12/24 14:06:37 amakrish noship $ */
	P_BUS_GRP	number;
	P_PAYROLL	number;
	P_SESSION_DATE	date;
	P_CONC_REQUEST_ID	number;
	C_BUSINESS_GROUP_NAME	varchar2(60);
	C_PAYROLL_NAME	varchar2(30);
	function BeforeReport return boolean  ;
	function end_report(c_report_tot in number) return varchar2  ;
	function AfterReport return boolean  ;
	Function C_BUSINESS_GROUP_NAME_p return varchar2;
	Function C_PAYROLL_NAME_p return varchar2;
END SSP_SSPRPOAR_XMLP_PKG;

/


GRANT EXECUTE ON APPS.SSP_SSPRPOAR_XMLP_PKG TO INTG_NONHR_NONXX_RO;
