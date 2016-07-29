DROP PACKAGE APPS.SSP_SSPRPSAP_XMLP_PKG;

CREATE OR REPLACE PACKAGE APPS.SSP_SSPRPSAP_XMLP_PKG AUTHID CURRENT_USER AS
/* $Header: SSPRPSAPS.pls 120.1 2007/12/24 14:07:00 amakrish noship $ */
	P_BUSINESS_GROUP_ID	number;
	P_SESSION_DATE	date;
	P_CONC_REQUEST_ID	number;
	P_PAYROLL_ID	number;
	P_PERSON_ID	number;
	P_DATE_FROM	date;
	P_DATE_TO	date;
	C_EWC	date;
	C_WQ	date;
	C_AVG_EARNINGS	number := 0.00 ;
	C_BUSINESS_GROUP_NAME	varchar2(240);
	C_REPORT_SUBTITLE	varchar2(60);
	C_PAYROLL_NAME	varchar2(30);
	C_PERSON_NAME	varchar2(80);
	function BeforeReport return boolean  ;
	function c_sapformula(M_due_date in date, M_matching_date in date, M_PERSON_ID in number) return varchar2  ;
	function c_processedformula(E_Element_entry_id in number) return varchar2  ;
	function c_amount_processedformula(C_Processed in varchar2, E_amount in number) return number  ;
	function c_recoverable_processedformula(C_Processed in varchar2, E_recoverable in number) return number  ;
	function AfterReport return boolean  ;
	Function C_EWC_p return date;
	Function C_WQ_p return date;
	Function C_AVG_EARNINGS_p return number;
	Function C_BUSINESS_GROUP_NAME_p return varchar2;
	Function C_REPORT_SUBTITLE_p return varchar2;
	Function C_PAYROLL_NAME_p return varchar2;
	Function C_PERSON_NAME_p return varchar2;
END SSP_SSPRPSAP_XMLP_PKG;

/


GRANT EXECUTE ON APPS.SSP_SSPRPSAP_XMLP_PKG TO INTG_NONHR_NONXX_RO;
