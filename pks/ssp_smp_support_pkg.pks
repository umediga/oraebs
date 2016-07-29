DROP PACKAGE APPS.SSP_SMP_SUPPORT_PKG;

CREATE OR REPLACE PACKAGE APPS.ssp_smp_support_pkg AUTHID CURRENT_USER as
/*      $Header: spsspbsi.pkh 120.0.12010000.3 2010/11/27 15:23:10 npannamp ship $
+==============================================================================+
|                       Copyright (c) 1994 Oracle Corporation                  |
|                          Redwood Shores, California, USA                     |
|                               All rights reserved.                           |
+==============================================================================+

Name
	SSP/SMP Common Code
Purpose
	To provide routines common to both SSP and SMP processes.
History
	31 Aug 95	N Simpson       Created
	15 Sep 95       N Simpson       Added function stoppage_overridden
	16 Nov 95	N Simpson	Renamed p_last_standard_process_date
					in procedure get_entry_details to
					p_last_process_date because it may
					be the last_standard_process_date (SSP)
					or the final_close_date (SMP).
	 5 Dec 95	N Simpson	Added function average_earnings_error.
	 6 Dec 95	N Simpson	Added global variable reason_for_no_earnings
	19 Jan 96	N Simpson	Added functions start_of_week and
					end_of_week.
 08-Jan-98  RThirlby 608724  110.0      Parameter p_deleting added to procedure
                                        recalculate_ssp_and_smp - part of fix
                                        for SMP element entries problem.
 19-AUG-99  MVilrokx 855830  110.3      The testing of the bug bust revealed a
                                        problem with a pragma setting.  It
                                        appeared that the pragma in the value
                                        function was commented out for no apparent
                                        reasoning causing the error. I uncommented
                                        the pragma to fix the problem.
 05-DEC-01	GButler	1759066  115.3	Added new procedure update_ssp_smp_entries
 					to allow automatic recalculation of SSP/
					SMP entries over tax year end following
					legislative updates to the corresponding
					SSP/SMP rates
 25-FEB-02	GButler 	 115.4  Added P_UPDATE_ERROR out parameter to
					update_ssp_smp_entries
 17-DEC-02      ABlinko          115.6  gscc fix
 24-JAN-03	GButler		 115.7  nocopy fixes
 21-FEB-09      pbalu            115.8  Added multithreaded version of update_ssp_smp_entries
 27-NOV-10      npannamp         115.9  ASPP Changes 9897338. Added end_of_rolling_week function.
*/
--------------------------------------------------------------------------------
/*This variable should be set by the ssp_ern_bus.calculate_average_earnings
procedure if the average earnings cannot be calculated. */
--
reason_for_no_earnings	varchar2(80);
Type l_job_err_typ  is table of varchar2(4000) index by binary_integer;
--
function entry_already_processed (p_element_entry_id in number) return boolean;
--
function NI_Lower_Earnings_Limit (p_effective_date in date) return number;
--
function value (
		p_element_entry_id	number,
		p_input_value_name	varchar2)
return varchar2;
-- put pragma back in place.
pragma restrict_references (value, WNDS, WNPS);
--
function element_input_value_id (
		p_element_type_id	number,
		p_input_value_name	varchar2)
return number;
--
pragma restrict_references (element_input_value_id, WNDS, WNPS);
--
function stoppage_overridden (
	p_reason_id	in number,
	p_absence_attendance_id in number default null,
	p_maternity_id in number default null) return boolean;
	--
function withholding_reason_id (
	p_element_type_id	in number,
	p_reason		in varchar2) return number;
	--
function start_of_week (p_date date) return date;
--
function end_of_week (p_date date) return date;
--
function end_of_rolling_week (p_start_date date, p_date date) return date;
--
procedure recalculate_SSP_and_SMP (p_deleting in boolean default FALSE);
--
procedure get_entry_details (
	p_date_earned			in date,
	p_last_process_date		in date,
	p_person_id			in number,
	p_element_type_id		in number,
	p_element_link_id		in out nocopy number,
	p_assignment_id			in out nocopy number,
	p_effective_start_date	 out nocopy date,
	p_effective_end_date	 out nocopy date,
	p_pay_as_lump_sum		in varchar2 default 'N');
	--
function average_earnings_error return varchar2;

/* Bug 1759066 */
procedure update_ssp_smp_entries (P_UPDATE_ERROR out nocopy BOOLEAN);
--
procedure update_ssp_smp_entries (P_UPDATE_ERROR OUT NOCOPY boolean, p_job_err OUT NOCOPY l_job_err_typ);
--
end ssp_smp_support_pkg;

/


GRANT EXECUTE ON APPS.SSP_SMP_SUPPORT_PKG TO INTG_NONHR_NONXX_RO;
