DROP PACKAGE APPS.SSP_SMP_PKG;

CREATE OR REPLACE PACKAGE APPS.SSP_SMP_PKG AUTHID CURRENT_USER as
/*$Header: spsmpapi.pkh 120.1.12000000.1 2007/01/17 14:14:52 appldev noship $
+==============================================================================+
|                       Copyright (c) 1994 Oracle Corporation                  |
|                          Redwood Shores, California, USA                     |
|                               All rights reserved.                           |
+==============================================================================+
--
Name
	Statutory Maternity Pay Business Process
--
Purpose
	To perform calculation of entitlement and payment for SMP purposes
--
History
	31 Aug 95       N Simpson       Created
	 1 Sep 95	N Simpson	Added restriction WNPS to pragmas.
	 4 Sep 95	N Simpson	Removed legislation restriction from
					CSR_SMP_ELEMENT_DETAILS.
	 8 Sep 95	N Simpson	Converted public procedure
					check_entitlement_to_SMP into private
					function entitled_to_SMP. NB The header
					remains here because this file acts as
					the LLD for the package.
	19 Sep 95	N Simpson	Modified medical_control parameters.
	 8 Dec 95	N Simpson	Modified c_recoverable_amount_name
	22 Aug 96       C Barbieri      Deleted function maternity_leave_exists.
					With Oracle 7.3.2 it is not possible to
					reference a function that returns a
					BOOLEAN inside a SELECT statement.
  08-Jan-98  RThirlby  608724  30.16    Parameter p_deleting added - part of
                                        solution to SMP element entries prob.
  24-JUL-98  A.Myers   701750  30.17    Parameter p_deleting added to procedure
                                        absence_control; part of solution to
					performance fix 563202 and bug 701750.
  06-NOV-02  G.Butler  2649135 115.6	Fix to CBO related issue on csr_SMP_
  					element_details cursor - removed
  					to_number calls so that SQL execution
  					path changed and ORA-1722 does not occur.
  					Also commented out pragma restrict_
  					references statements on functions
  12-JUL-04  A.Blinko  3682122 115.7    Added g_smp_update for lump sun recalc
  21-MAR-06  K.Thampan 5105039 115.8    Added get_max_SMP_date
*/
--------------------------------------------------------------------------------
-- ***************************************************************************
-- * Performs actions required by the UK legislation for Statutory
-- * Maternity Pay. See the High Level Design document for general details
-- * of the functionality and use of SMP.
-- ***************************************************************************
--
c_SMP_element_name	  constant
			           varchar2 (80) := 'Statutory Maternity Pay';
c_SMP_Corr_element_name	  constant
			           varchar2 (80) := 'SMP Corrections';
c_SMP_creator_type	  constant varchar2 (3) := 'M';
c_SMP_entry_type	  constant varchar2 (1) := 'E';
c_week_commencing_name    constant varchar2 (30) := 'Week commencing';
c_amount_name		  constant varchar2 (30) := 'Amount';
c_recoverable_amount_name constant varchar2 (30) := 'Recoverable amount';
c_rate_name		  constant varchar2 (30) := 'Rate';
--
g_smp_update                       varchar2 (1) := 'N';
--
-- Get the element details for SMP
--
cursor CSR_SMP_ELEMENT_DETAILS (
	--
	-- Get the legislative parameters for SMP, which are held in the
	-- Developer descriptive Flexfield of the element.
	--
	p_effective_date	date default sysdate,
	--
	-- p_effective_date restricts us to a single row for the selected
	-- element
	--
	p_element_name		varchar2 default c_SMP_element_name
	--
	-- p_element_name allows us to select different elements in the same
	-- cursor
	--
	) is
	--
	select	ele1.element_type_id,
		ele1.effective_start_date,
		ele1.effective_end_date,
				ele1.element_information1 *7
		EARLIEST_START_OF_MPP,
				ele1.element_information2 *7
		QUALIFYING_WEEK,
				ele1.element_information3 *7
		CONTINUOUS_EMPLOYMENT_PERIOD,
				ele1.element_information4
		MAXIMUM_MPP,
				ele1.element_information5 *7
		COMPULSORY_LEAVE_PERIOD,
				ele1.element_information6
		MPP_NOTICE_REQUIREMENT,
				ele1.element_information7
		NOTICE_OF_BIRTH_REQUIREMENT,
				ele1.element_information8 *7
		EARLIEST_SMP_EVIDENCE,
				ele1.element_information9 /100
		HIGHER_SMP_RATE,
				ele1.element_information10
		LOWER_SMP_RATE,
				ele1.element_information11 /100
		RECOVERY_RATE,
				ele1.element_information12 *7
		LATEST_SMP_EVIDENCE,
				ele1.element_information13 *7
		EXTENDED_SMP_EVIDENCE,
				ele1.element_information14
		PERIOD_AT_HIGHER_RATE,
				ele1.element_information15 *7
		STILLBIRTH_THRESHHOLD_WEEK,
                                ele1.element_information16
                STANDARD_SMP_RATE,
		ssp_smp_support_pkg.element_input_value_id
			(ele1.element_type_id, c_rate_name) RATE_ID,
		ssp_smp_support_pkg.element_input_value_id
			(ele1.element_type_id, c_week_commencing_name)
						WEEK_COMMENCING_ID,
		ssp_smp_support_pkg.element_input_value_id
			(ele1.element_type_id, c_amount_name) AMOUNT_ID,
		ssp_smp_support_pkg.element_input_value_id
			(ele1.element_type_id, c_recoverable_amount_name)
						RECOVERABLE_AMOUNT_ID
	from	pay_element_types_f ele1
	where	ele1.element_name = p_element_name
	and	p_effective_date between ele1.effective_start_date
					and ele1.effective_end_date;
	--
--------------------------------------------------------------------------------
--function entitled_to_SMP (
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
--	pragma restrict_references (maternity_record_exists, WNPS,WNDS);
	--
function Qualifying_Week
(
p_due_date	in date
) return date;
--
	-- Returns the start date of the Qualifying Week for SMP, based
	-- on the woman's due date.
	--
--	pragma restrict_references (qualifying_week, WNPS,WNDS);
	--
function Expected_week_of_confinement
(
p_due_date	in date
) return date;
--
	-- Returns the start date of the Expected Week of Confinement
	-- for SMP, based on the woman's due date.
	--
--	pragma restrict_references (Expected_week_of_confinement, WNPS,WNDS);
	--
function Earliest_MPP_start_date
(
p_due_date	in date
) return date;
--
	-- Returns the earliest date a woman may start her Maternity Pay
	-- Period, based on the due date and assuming a normal pregnancy.
	--
--	pragma restrict_references (Earliest_MPP_start_date, WNPS,WNDS);
	--
function Continuous_employment_date
(
p_due_date	in date
) return date;
--
	-- Returns the start date of the period ending with the Qualifying
	-- Week, for which the woman must have been continuously employed
	-- in order to qualify for SMP
	--
--	pragma restrict_references (Continuous_employment_date, WNPS,WNDS);
	--
procedure absence_control
(
p_maternity_id in number,
p_deleting     in boolean default FALSE
);
--
	-- Performs the necessary actions to trigger recalculation of SMP if
	-- a maternity leave absence is inserted, updated or deleted. This is
	-- the primary mechanism for controlling SMP and should be called from
	-- row level database triggers on per_absence_attendances, for each DML
	-- action.
	--
--
procedure maternity_control (p_maternity_id in number);
--
	-- Performs the necessary actions to trigger recalculation of SMP if
	-- a maternity record is updated and SMP has already been calculated
	-- for it. Must be called from the after-update trigger on
	-- ssp_maternities for each row.
	--
--
procedure medical_control (p_maternity_id in number);
--
	-- Performs the necessary actions to trigger recalculation of SMP if a
	-- medical report for the maternity is updated. As the initial
	-- calculation of SMP is triggered by insertion of maternity leave, we
	-- only need to recalculate if maternity leave already exists. Also,
	-- as medical evidence can be superceded, we only need to recalculate
	-- if the updated medical record is current, or is being updated to
	-- be current. Call from row-level database triggers for each DML action
	-- on ssp_medicals.
	--
procedure earnings_control (p_person_id in number, p_effective_date in date);
--
	-- Performs the necessary actions to trigger recalculation of SMP if a
	-- calculation of average earnings is inserted or updated (delete is
	-- not allowed). As the initial calculation of SMP is triggered by the
	-- insertion of maternity leave, we only need recalculate if such leave
	-- is recorded. Also, we only need to recalculate if the earnings
	-- calculation is used by the SMP calculation (decided by its
	-- effective date). This procedure should be called from row-level
	-- database triggers on ssp_earnings_calculations after insert and
	-- update. Those triggers should also call a similar procedure for SSP
	-- recalculation and so a shared requirement of both these procedures is
	-- for the triggers to filter out any updates which do not move the
	-- earnings figure to the other side of the Lower Earnings Limit; if
	-- the limit is not crossed by the change, then no recalculation is
	-- necessary.
	--
procedure person_control (p_person_id in number, p_date_of_death in date);
--
	-- Performs the necessary actions to trigger recalculation of SMP if a
	-- person dies. Only triggers recalculation if death occurs within an
	-- MPP for which leave exists. Call from row-level after update
	-- database trigger on per_people_f.
	--
--
procedure stoppage_control (p_maternity_id in number);
--
	-- Performs the necessary actions to trigger recalculation of SMP if a
	-- stoppage is modified. We must NOT call the check on entitlement to
	-- SMP from this procedure because that check will cause modification
	-- of stoppages and we would enter an infinite loop. To protect
	-- ourselves from this, we filter calls to this procedure in the
	-- database trigger on ssp_stoppages by only calling it for stoppages
	-- changed by the user, rather than the system (ie user_entered = 'Y').
	-- Also, we call the generate_payments procedure directly from this
	-- procedure and miss out the check_entitlement_to_SMP procedure.
	--
--
procedure SMP_control (p_maternity_id in number,
                       p_deleting     in boolean default FALSE);

--
function get_max_SMP_date(p_maternity_id in number) return date;
function get_max_SMP_date(p_maternity_id in number,
                          p_due_date     in date,
                          p_mpp_date     in date) return date;
--
end ssp_smp_pkg;

/


GRANT EXECUTE ON APPS.SSP_SMP_PKG TO INTG_NONHR_NONXX_RO;
