DROP PACKAGE APPS.SSP_PAB_PKG;

CREATE OR REPLACE PACKAGE APPS.SSP_PAB_PKG AUTHID CURRENT_USER as
/*$Header: sppabapi.pkh 120.1.12000000.1 2007/01/17 14:14:45 appldev noship $
+==============================================================================+
|                       Copyright (c) 1994 Oracle Corporation                  |
|                          Redwood Shores, California, USA                     |
|                               All rights reserved.                           |
+==============================================================================+
--
Name
	Statutory Paternity Pay (Birth) Business Process
--
Purpose
	To perform calculation of entitlement and payment for PAB purposes
--
History
	17 Oct 02       A Blinko  2690305  Created from SSP_SMP_PKG
        10 Jan 03       A Blinko           amended latest_ppp_start_date
        18 Oct 04       KThampan  4670360  Amended latest_ppp_start_date
*/
--------------------------------------------------------------------------------
-- ***************************************************************************
-- * Performs actions required by the UK legislation for Statutory
-- * Adoption Pay. See the High Level Design document for general details
-- * of the functionality and use of ADO.
-- ***************************************************************************
--
c_PAB_element_name        constant varchar2 (80) := 'Statutory Paternity Pay Birth';
c_PAB_corr_element_name   constant varchar2 (80) := 'SPP Birth Corrections';
c_PAB_creator_type        constant varchar2 (3)  := 'M';
c_PAB_entry_type          constant varchar2 (1)  := 'E';
c_week_commencing_name	  constant varchar2 (30) := 'Week Commencing';
c_amount_name		  constant varchar2 (30) := 'Amount';
c_recoverable_amount_name constant varchar2 (30) := 'Recoverable Amount';
c_rate_name		  constant varchar2 (30) := 'Rate';
--
-- Get the element details for SMP
--
cursor CSR_PAB_ELEMENT_DETAILS (
	--
	-- Get the legislative parameters for PAB, which are held in the
	-- Developer descriptive Flexfield of the element.
	--
	p_effective_date	date default sysdate,
	--
	-- p_effective_date restricts us to a single row for the selected
	-- element
	--
	p_element_name		varchar2 default c_PAB_element_name
	--
	-- p_element_name allows us to select different elements in the same
	-- cursor
	--
	) is
	--
	select	ele1.element_type_id,
		ele1.effective_start_date,
		ele1.effective_end_date,
				to_number (ele1.element_information1) *7
		EARLIEST_START_OF_PPP,
                                to_number (ele1.element_information2) *7
                QUALIFYING_WEEK,
				to_number (ele1.element_information3) *7
		CONTINUOUS_EMPLOYMENT_PERIOD,
				to_number (ele1.element_information4)
		MAXIMUM_PPP_WEEKS,
				to_number (ele1.element_information5)
		MPP_NOTICE_REQUIREMENT,
				to_number (ele1.element_information6) /100
		SPP_RATE,
				to_number (ele1.element_information7) /100
		RECOVERY_RATE,
                                to_number (ele1.element_information8) *7
                STILLBIRTH_THRESHOLD_WEEK,
                                to_number (ele1.element_information9)
                STANDARD_RATE,
                                to_number (ele1.element_information10) *7
                LATEST_END_OF_PPP,
		ssp_smp_support_pkg.element_input_value_id
			(ele1.element_type_id, c_rate_name)
                RATE_ID,
		ssp_smp_support_pkg.element_input_value_id
			(ele1.element_type_id, c_week_commencing_name)
                WEEK_COMMENCING_ID,
		ssp_smp_support_pkg.element_input_value_id
			(ele1.element_type_id, c_amount_name)
                AMOUNT_ID,
		ssp_smp_support_pkg.element_input_value_id
			(ele1.element_type_id, c_recoverable_amount_name)
   		RECOVERABLE_AMOUNT_ID
	from	pay_element_types_f ele1
	where	ele1.element_name = p_element_name
	and	p_effective_date between ele1.effective_start_date
					and ele1.effective_end_date;
--------------------------------------------------------------------------------
--function entitled_to_SAP (
--
--p_maternity_id	in number
--
--) return boolean;
	--
	-- Check whether or not an absence gives rise to an entitlement to
	-- Statutory Maternity Pay. First check whether there is a prima facia
	-- entitlement (eg the person must be female), and then check for any
	-- reasons for withholding payment from an entitled person. If there is
	-- any such withholding reason, then insert a row in ssp_stoppages for
	-- the period to which the reason applies.
	--
	-- While checking entitlement, bear in mind that stoppages may also be
	-- created by users, and that the check may be being performed for
	-- a second time. Therefore, if there is a user-generated stoppage
	-- for a specific period, do not alter any value on it; should there be
	-- a need to create a stoppage for the same reason as the user's
	-- stoppage, which covers a wider period, then create stoppages around
	-- the user's one. Any system-generated stoppages in existence at the
	-- start of the check should first be deleted before commencing the
	-- checks.
	--
	-- Another feature of stoppages is that the user may override them.
	-- This means that the withholding reason is to be ignored for that
	-- period and so the user can effectively prevent any notice being taken
	-- of that reason. If the stoppage is only for a temporary period, then
	-- the system may still generate a stoppage for that reason outside the
	-- overridden period.
	--
	-- The following checks should be performed:
	--
	-- ABSENT
	-- Check that the woman is absent on maternity leave
	--
	-- There must be a maternity leave record. If not
	-- then exit silently (because this may be called from the trigger
	-- on the absence table).
	-- Check that notification of absence is given in time
	--
	-- CONTINUITY
	-- Check that the woman has a period of service of the right length
	-- covering the right period.
	--
	-- There must be an unbroken period of service for the woman which
	-- lasts for the period of time defined, in weeks, in the SMP
	-- continuous employment DDF segment, and the Qualifying Week. The
	-- woman must have been employed for at least part of the Qualifying
	-- Week. If this condition is not met then create a stoppage for the
	-- whole maternity.
	--
	-- PREGNANT
	-- Check that the woman is still pregnant or has given birth in the
	-- correct timescales.
	--
	-- If there is a stillbirth occurs before the stillbirth threshhold
	-- week, then create a stoppage for the whole maternity.
	-- Stillbirth is determined by there being a date of birth and the
	-- live birth flag being 'N'. The stillbirth threshhold week is
	-- determined by converting to days the stillbirth threshhold period
	-- defined on the SMP element DDF, and subtracting that number from the
	-- EWC start date.
	--
	-- EMPLOYER
	-- Check that the woman has not started work for a new employer after
	-- the birth of the child.
	--
	-- The start date with new employer is on the maternity table. If it is
	-- after the birth of the child then create a
	-- stoppage from the week the woman started work for the new employer.
	-- It is up to the user to override this if the new employer is one
	-- who employed the woman in the qualifying week.
	--
	-- DEATH
	-- Check that the woman has not died.
	--
	-- Create a stoppage from the Sunday following the date of death.
	--
	-- SMA
	-- Check that the woman is not receiving Statutory Maternity Allowance
	-- from the Department of Social Security.
	--
	-- The start date of Maternity Allowance is held on the maternity
	-- table. If it is entered, then create a stoppage from that week.
	--
	-- EARNINGS
	-- Check that the average earnings of the woman are high enough to
	-- qualify for SMP.
	--
	-- The average earnings calculation is shared with the SSP package and
	-- is defined in the header file for the SSP_SSP_pkg. The period to
	-- which average earnings are to be calculated is the QW start date.
	-- The average earnings period is defined on the SMP element DDF.
	--
	-- EVIDENCE
	-- Check that medical evidence of maternity has been received in time.
	--
	-- The earliest SMP evidence, the latest SMP evidence and the
	-- extended SMP evidence periods are defined in the SMP element DDF.
	-- Create a stoppage for the whole maternity if the evidence date is
	-- earlier than the earliest SMP evidence date. Calculate the earliest
	-- SMP evidence date by converting the earliest SMP evidence period to
	-- days from weeks, then subtracting that number of days from the
	-- EWC start date. Create a stoppage for the whole maternity if the
	-- evidence received date is later than the latest SMP evidence date.
	-- Calculate the latest SMP evidence date by converting the latest
	-- SMP evidence period to days from weeks and adding that number
	-- to the MPP start date. If the latest date is exceeded, then if the
	-- accept_late_notification flag is 'Y' then check the extended SMP
	-- evidence date (in the same manner). If this date is exceeded, or if
	-- the accept_late_notification flag is 'N', then create a stoppage
	-- for the whole maternity.
	--
	-- CONFIRMATION
	-- Check that confirmation of birth was received in time.
	--
	-- The SMP element DDF defines the number of days after the birth
	-- which is the end of the period in which the employee may notify the
	-- employer of the birth. If this date is exceeded, then create a
	-- stoppage for the whole maternity.
	--
function MATERNITY_RECORD_EXISTS
(
p_person_id	in number
) return boolean;
	--
	-- Returns TRUE if there is a maternity record for the person
	--
pragma restrict_references (maternity_record_exists, WNPS,WNDS);
	--

function QUALIFYING_WEEK
(
p_due_date	in date
) return date;
--
	--
pragma restrict_references (QUALIFYING_WEEK, WNPS,WNDS);
	--
function Earliest_PPP_start_date
(
p_birth_date	in date
) return date;
--
	-- Returns the earliest date a person may start their Paternity Pay
	-- Period, based on the due date and assuming a normal pregnancy.
	--
	pragma restrict_references (Earliest_PPP_start_date, WNPS,WNDS);
	--

function Latest_PPP_start_date
(
p_birth_date	in date,
p_ewc           in date,
p_due_date      in date
) return date;
--
function expected_week_of_confinement
(
p_due_date      in date
) return date;

	pragma restrict_references (expected_week_of_confinement, WNPS,WNDS);

function Continuous_employment_date
(
p_due_date	in date
) return date;
--
	-- Returns the start date of the period ending with the Qualifying
	-- Week, for which the woman must have been continuously employed
	-- in order to qualify for SMP
	--
	pragma restrict_references (Continuous_employment_date, WNPS,WNDS);
	--
procedure PAB_control (p_maternity_id in number,
                       p_deleting     in boolean default FALSE);
--
end ssp_pab_pkg;

/


GRANT EXECUTE ON APPS.SSP_PAB_PKG TO INTG_NONHR_NONXX_RO;
