DROP PACKAGE APPS.SSP_SSPRPSSP_XMLP_PKG;

CREATE OR REPLACE PACKAGE APPS.SSP_SSPRPSSP_XMLP_PKG AUTHID CURRENT_USER AS
/* $Header: SSPRPSSPS.pls 120.1 2007/12/24 14:07:49 amakrish noship $ */
	P_BUSINESS_GROUP_ID	number;
	P_SESSION_DATE	date;
	P_CONC_REQUEST_ID	number;
	P_PAYROLL_ID	number;
	P_PERSON_ID	number;
	P_DATE_FROM	date;
	P_DATE_TO	date;
	C_BUSINESS_GROUP_NAME	varchar2(240);
	C_REPORT_SUBTITLE	varchar2(60);
	C_PAYROLL_NAME	varchar2(80);
	C_PERSON_NAME	varchar2(240);
	function BeforeReport return boolean  ;
	function e_processedformula(E_ELEMENT_ENTRY_ID in number) return varchar2  ;
	function e_ssp_weeks_processedformula(E_PROCESSED in varchar2, E_SSP_WEEKS in number) return number  ;
	function e_amount_processedformula(E_PROCESSED in varchar2, E_AMOUNT in number) return number  ;
	function AfterReport return boolean  ;
	Function C_BUSINESS_GROUP_NAME_p return varchar2;
	Function C_REPORT_SUBTITLE_p return varchar2;
	Function C_PAYROLL_NAME_p return varchar2;
	Function C_PERSON_NAME_p return varchar2;
END SSP_SSPRPSSP_XMLP_PKG;

/


GRANT EXECUTE ON APPS.SSP_SSPRPSSP_XMLP_PKG TO INTG_NONHR_NONXX_RO;
