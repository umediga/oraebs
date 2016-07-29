DROP PACKAGE APPS.SSP_SSPRPELR_XMLP_PKG;

CREATE OR REPLACE PACKAGE APPS.SSP_SSPRPELR_XMLP_PKG AUTHID CURRENT_USER AS
/* $Header: SSPRPELRS.pls 120.1 2007/12/24 14:05:46 amakrish noship $ */
	P_BUSINESS_GROUP_ID	number;
	P_SESSION_DATE	date;
	P_CONC_REQUEST_ID	number;
	P_PAYROLL_ID	number;
	P_CONSOLIDATION_SET	number;
	P_TIME_PERIOD_ID	number;
	P_SORT_OPTION	varchar2(60);
	P_SORT_OPTION_1 varchar2(60);
	C_BUSINESS_GROUP_NAME	varchar2(240);
	C_REPORT_SUBTITLE	varchar2(60);
	C_PAYROLL_NAME	varchar2(80);
	C_CONSOLIDATION_SET_NAME	varchar2(60);
	C_TIME_PERIOD_NAME	varchar2(35);
	C_SORT_OPTION	varchar2(60);
	function BeforeReport return boolean  ;
	function P_SORT_OPTIONValidTrigger return boolean  ;
	function AfterReport return boolean  ;
	Function C_BUSINESS_GROUP_NAME_p return varchar2;
	Function C_REPORT_SUBTITLE_p return varchar2;
	Function C_PAYROLL_NAME_p return varchar2;
	Function C_CONSOLIDATION_SET_NAME_p return varchar2;
	Function C_TIME_PERIOD_NAME_p return varchar2;
	Function C_SORT_OPTION_p return varchar2;

function Derive_sort_criteria return varchar2;
END SSP_SSPRPELR_XMLP_PKG;

/


GRANT EXECUTE ON APPS.SSP_SSPRPELR_XMLP_PKG TO INTG_NONHR_NONXX_RO;
