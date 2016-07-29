DROP PACKAGE APPS.SSP_SSP_PKG;

CREATE OR REPLACE PACKAGE APPS.SSP_SSP_PKG AUTHID CURRENT_USER as
/* $Header: spsspapi.pkh 120.2.12010000.1 2008/07/25 08:16:09 appldev ship $
+==============================================================================+
|                       Copyright (c) 1994 Oracle Corporation                  |
|                          Redwood Shores, California, USA                     |
|                               All rights reserved.                           |
+==============================================================================+
--
Name
	Statutory Sick Pay Business Process
--
Purpose
	To perform calculation of entitlement and payment for SSP purposes.
History:
-------
Version  Date       Author     Bug No   Description
-------  ----       ------     ------   -----------
        11 Sep 95   N Simpson           Created
        19 Sep 95   N Simpson           New procedure check_sickness_date_change
        15 Nov 95   N Simpson           Added pragma to linked_PIW_end_date
        09 Apr 96   N Simpson           New procedure update_linked_absence_ids
        18 Jun 98   A Parkes            Added input_currency_code to
                                        csr_SSP_element_details
30.14   19-AUG-98   A.Myers    701750   Added parameter processing level to
                                        qualifying_days_in_peiod, which controls
                                        the amount of work done in the calendars
                                        package.
115.4   12-Oct-99   C Carter   1027169  Removed pragma restriction from
                                        absence_is_a_piw,linked_piw_start_date
                                        and linked_piw_end_date
115.9   22-Mar-04   A Blinko   3466672  Added procedure medical_control
115.10  24-Aug-06   K Thampan  5482199  Added procedure check_for_other_stoppage
                                        and check_employee_too_old
115.11  06-Sep-06   K Thampan  5482199  Remove procedure check_for_other_stoppage
                                        and check_employee_too_old
*/
--------------------------------------------------------------------------------
-- ***************************************************************************
-- * Performs actions required by the UK legislation for Statutory
-- * Sick Pay. See the High Level Design document for general details
-- * of the functionality and use of SSP. For specific rules about SSP, see
-- * the Statutory Sick Pay Manual for Employers, CA30 (NI270) issued by the
-- * Department of Social Security. The latest version as at the time of
-- * writing was dated 6 April 1995.
-- ***************************************************************************
--
c_rate_name		constant varchar2 (80) := 'Rate';
c_from_name		constant varchar2 (80) := 'From';
c_to_name		constant varchar2 (80) := 'To';
c_amount_name		constant varchar2 (80) := 'Amount';
c_withheld_days_name	constant varchar2 (80) := 'Withheld days';
c_SSP_weeks_name	constant varchar2 (80) := 'SSP weeks';
c_SSP_days_due_name	constant varchar2 (80) := 'SSP days due';
c_qualifying_days_name	constant varchar2 (80) := 'Qualifying days';
c_SSP_element_name	constant varchar2 (80) := 'Statutory Sick Pay';
c_SSP_correction_element_name	constant varchar2 (80) := 'SSP Corrections';
c_SSP_creator_type      constant varchar2 (30) := 'S';
--
cursor csr_SSP_element_details (
  --
  -- Gets the SSP legislative parameters held in the element DDF.
  --
  p_effective_date  in date,
  p_element_name    in varchar2 default c_SSP_element_name
  ) is
  --
  select  element_type_id,
    effective_start_date,
    effective_end_date,
    to_number (element_information1) MAXIMUM_SSP_PERIOD,
    to_number (element_information2) MAXIMUM_AGE,
    to_number (element_information3)+1 LINKING_PERIOD_DAYS,
    to_number (element_information4) WAITING_DAYS,
    to_number (element_information5) PIW_THRESHHOLD,
    to_number (element_information6) MAXIMUM_LINKED_PIW_YEARS,
    to_number (element_information7) PERCENTAGE_THRESHHOLD,
    ssp_smp_support_pkg.element_input_value_id
      (element_type_id, c_SSP_days_due_name) SSP_DAYS_DUE_ID,
    ssp_smp_support_pkg.element_input_value_id
      (element_type_id, c_amount_name) AMOUNT_ID,
    ssp_smp_support_pkg.element_input_value_id
      (element_type_id, c_from_name) FROM_ID,
    ssp_smp_support_pkg.element_input_value_id
      (element_type_id, c_to_name) TO_ID,
    ssp_smp_support_pkg.element_input_value_id
      (element_type_id, c_rate_name) RATE_ID,
    ssp_smp_support_pkg.element_input_value_id
      (element_type_id,c_withheld_days_name) WITHHELD_DAYS_ID,
    ssp_smp_support_pkg.element_input_value_id
      (element_type_id, c_SSP_weeks_name) SSP_WEEKS_ID,
    ssp_smp_support_pkg.element_input_value_id
      (element_type_id, c_qualifying_days_name) QUALIFYING_DAYS_ID,
    input_currency_code
  from  pay_element_types_f
  where element_name = p_element_name
  and   p_effective_date between effective_start_date
                             and effective_end_date;
--
--------------------------------------------------------------------------------
procedure update_linked_absence_ids;
	--
	-- Called from the recalculate_ssp_and_smp procedure in the
	-- ssp_smp_support_pkg. This procedure handles the case where an
	-- absence has been updated such that it is now a PIW, having not
	-- previously been one. It will update the linked_absence_id of the
	-- modified absence if it links to a previous PIW, and amend the PIW
	-- ID held in the temporary store which determines which PIWs have
	-- their SSP recalculated.
--------------------------------------------------------------------------------
function linked_absence_ID
(
p_person_id		in number,
p_sickness_start_date	in date,
p_sickness_end_date	in date
) return number;
	--
	-- Called from absence before row insert trigger. Returns the ID
	-- of the absence which is the start of a series of linked periods
	-- of incapacity for work. The linking period is held on the SSP
	-- element DDF. If any sickness absence starts within the linking
	-- period from the end of a previous sickness, then those absences
	-- are said to be linked. We hold the ID of the first of the series
	-- because that is the one which is used to derive many of the
	-- details for checking entitlement to SSP.
	--
	-- Steps:
	--
	-- 1. Get the linking period from the element DDF.
	-- 2. Calculate the date which is the sickness start date minus the
	--    linking period.
	-- 3. Find the details of any sickness absence for this
	--    person whose sickness end date falls between the new sickness
	--    start date and the date calculated at step 2.
	-- 4. If the linked_absence_id found at step 3 is not null, that is the
	--    linked_absence_id to be returned. If it is null, then return the
	--    absence id of the row found at step 3. If no row was found,
	--    return null.
	--
	-- Known Restrictions:
	--
	-- If the user inserts a sickness absence which is PRIOR to existing
	-- sickness absences and this absence would become the first in the
	-- series of linked PIWs, then we cannot update all of the existing
	-- absences as required because of the 'mutating table restriction'
	-- on database triggers. This case must be handled by the
	-- application interface.
	--
procedure check_sickness_date_change
(
p_person_id                     in number,-- :old.person_id
p_linked_absence_id             in number,-- :old.linked_absence_id
p_absence_attendance_id         in number,-- :old.absence_attendance_id
p_new_sickness_start_date       in date,-- :new.sickness_start_date
p_new_sickness_end_date         in date, -- :new.sickness_end_date
p_old_sickness_end_date         in date -- :old.sickness_end_date
);
	--
	-- Called from AFTER update of sickness_start_date, sickness_end_date
	-- trigger. Prevents update if the change would invalidate the
	-- linked_absence_id of either this row or the next one.
	--
procedure Check_for_break_in_linked_PIW
(
p_sickness_start_date	in date,
p_sickness_end_date	in date,
p_linked_absence_id	in number,
p_absence_attendance_id	in number);
	--
	-- Called from absence before delete trigger. Prevent the removal of a
	-- sickness absence from the start or middle of a linked series if by
	-- so doing the user would break the link. If the link would remain
	-- intact even after removal of the deleted absence, then allow the
	-- deletion to go ahead.
	--
	-- The ideal situation would be that if an absence is removed from the
	-- start or middle of a linked PIW, we would recalculate the linked
	-- PIW ID of all subsequent sickness absences and update them. However,
	-- the restriction on 'mutating tables' for database triggers prevents
	-- us from implementing that logic. Therefore, we must prevent the user
	-- from destroying the series by removing one of its components.
	--
-- function entitled_to_SSP
	--
	-- This is not a public procedure but is documented here because this
	-- header file acts as the Low Level Design document for the package.
	--
	-- Check whether or not an absence gives rise to an entitlement to
	-- Statutory Sick Pay. First check whether there is a prima facia
	-- entitlement (eg there must be a PIW formed), and then check for any
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
	-- overridden period. However, if the stoppage is overridden, it must
	-- not be deleted by the system.
	--
	-- Code each of the following checks as individual, private functions
	-- or procedures. That will make the code easier to debug, read and
	-- amend if required.
	--
	-- SICK
	-- Check that the absence is for a sickness absence type category
	--
	-- The presence of a value for sickness_start_date may be taken to
	-- indicate that the absence is sick leave because it is mandatory for
	-- sickness-type absences.
	--
	-- DEATH
	-- Check that the person is still alive.
	--
	-- There is a date of death on the person table. Create a stoppage from
	-- the start of the following day.
	--
	-- AGE
	-- Check that the person is not too old.
	--
	-- There is a date of birth on the person table. Create a stoppage if
	-- the person was too old for SSP AS AT THE START OF THE LINKED PIW.
	-- The linked_PIW_start_date is a function defined below. The age
	-- limit is defined in years and is held on the SSP element as a DDF
	-- segment. Create a stoppage from the PIW start date if the person
	-- was too old.
	--
	-- PREGNANT
	-- Check that the person is not within a maternity pay period.
	--
	-- The SMP package will have a function to perform this check. Pass the
	-- linked_absence_start_date, the absence end date, the sickness start
	-- date of any absence in the series which is pregnancy related.
	--
	-- EARNINGS
	-- Check that the person's average earnings are high enough.
	--
	-- Compare the earnings figure against the NI Lower Earnings Limit.
	--
	-- ASSIGNMENT
	-- Check that the person's primary assignment is not excluded from SSP.
	--
	-- There is a flag on the assignment DDF.
	--
	-- TERMINATION
	-- Check that the person has a current period of service.
	--
	-- Create a stoppage from the end of the period of service which covers
	-- the absence.
	--
	-- EVIDENCE
	-- If the user requires it, check that medical evidence of
	-- sickness has been received.
	--
	-- There is a DDF segment on the organization table, for the business
	-- group, which flags the requirement for medical evidence. If it is
	-- set to 'Y', check the medical evidence table for a child of the
	-- absence with a status of 'CURRENT'.
	--
	-- PIW
	-- Check that a PIW has been formed
	--
	-- The PIW threshhold is a DDF segment on the SSP element. It
	-- identifies the number of calendar days which form a Period of
	-- Incapacity for Work. If the difference between the sickness start
	-- date and the absence end date is less than this, then no PIW is
	-- formed and no SSP is due. Do not create a stoppage for this
	-- circumstance, but prevent the creation of payment entries. (NB the
	-- removal of any existing entries must continue if this check is
	-- being done as a result of the absence end date being brought
	-- forward).
	--
	-- WAITING
	-- Check that the waiting days have been served.
	--
	-- There is a DDF segment on the SSP element which identifies the
	-- number of qualifying days which must be served as 'waiting days'
	-- before SSP is due. If the number of qualifying days between the
	-- start of the linked series of PIWs and the absence end date is less
	-- than this figure, then create a stoppage for the absence. If there
	-- is a stoppage for late notification of sickness (this would be
	-- created by the user), then the period covered by that stoppage
	-- will not count towards the waiting days.
	--
	-- QUALIFYING
	-- Check that there are qualifying days within the PIW.
	--
	-- Using the function defined below to determine the number of
	-- qualifying days within a PIW, check that there are qualifying days
	-- in the period of absence. If there is none, create a stoppage for
	-- the absence period. If the absence is open ended, then check up to
	-- the end date of the maximum PIW length.
	--
	-- WORK
	-- Check that no work was done on the qualifying day.
	--
	-- Using the absence start and end times, determine if the person was
	-- present at all on a qualifying day. It is up to the user to enter
	-- the appropriate start and end times on both their SSP qualifying
	-- pattern and the absence. If there is a period of the qualifying day
	-- which is not covered by the absence, then create a stoppage for
	-- that whole day.
	--
	-- WEEKS
	-- Check that the number of weeks SSP does not exceed the maximum.
	--
	-- The maximum number of weeks which may be paid is held as a DDF
	-- segment on the SSP element. Check that the entries already created
	-- for the absence do not exceed that figure. Take into account the
	-- number of weeks paid under a previous employer if the absence links
	-- to the end of the PIW paid under a previous employer. The previous
	-- employment values are held on a DDF on the assignment.
	-- Also take into account any stoppages for the absence, excepting
	-- stoppages for late notification.
	--
	-- YEARS
	-- Check that the PIW does not exceed the maximum period.
	--
	-- Create a stoppage from the start of the third year after the linked
	-- PIW start date, if the absence covers that date and there has not
	-- been a stoppage already for maximum payment.
	--
-- procedure generate_payments;
	--
	-- When a sickness absence is created, after checking entitlement,
	-- generate an element entry for the SSP element for each week of the
	-- Period of Incapacity for Work (PIW). If the absence has an end date
	-- entered for it, then this is a straightforward matter, but for
	-- open-ended absences, the entries should be created up for weeks up
	-- to the lesser of the maximum allowed number of weeks and the
	-- actual termination date of the period of service. NB there may be
	-- a linked series of sickness absences, so the period for which
	-- payments may be generated may be broken into several chunks.
	--
	-- If there are stoppages for the absence, created as a result of the
	-- entitlement check, or by the user, then these will block the
	-- creation of entries for any weeks which are completely overlapped by
	-- a stoppage. Weeks which are partially overlapped will still have
	-- entries created for them, but there will be an effect on the
	-- entry values (see below). There are two kinds of stoppages; those
	-- which apply temporarily, and those which apply forever once started.
	-- Stoppages only apply within a PIW. If there is a stoppage which
	-- applies forever (ie it has no end date), then there is no need to
	-- continue creating entries after the start of that stoppage.
	-- Temporary entries should only affect creation while they apply.
	-- A further feature of stoppages is that they may be overridden by the
	-- user; if the override flag is set, then take no account of that
	-- stoppage when creating entries.
	--
	-- The maximum allowed number of weeks is held as a DDF segment on the
	-- SSP element. If the absence is open-ended, then the check on
	-- entitlement will create a stoppage starting with the date from
	-- which no further entries may be created, so there is no need to
	-- check explicitly for the maximum number of weeks; just keep going
	-- until the stoppage.
	--
	-- Whilst each entry is created to cover a particular period of absence,
	-- the payroll period in which the entry resides is determined
	-- separately. The default is that the entry will be created in the
	-- payroll period which covers the end of the week of absence for which
	-- the entry is created. If, however, that payroll period is in the
	-- past, or has already been processed, or is closed, or is after the
	-- person's last standard process date, then the entry must be placed
	-- in the next open period for which no main payroll run has been
	-- performed and which falls around or before the last standard process
	-- date. If the entry cannot be created in any such period, for whatever
	-- reason, then an error should be raised and the user required to
	-- resolve the problem before any entry for the absence can be created.
	--
	-- If any detail of the absence is changed, then the entries must be
	-- recalculated to ensure that the change is reflected in the
	-- payments. Therefore, we may be performing the entry creation when
	-- entries already exist for the absence. For each entry which we are
	-- about to create, we must check that there is not an existing entry
	-- which covers the same absence period. If there is not, then we
	-- create the entry as planned; if there is, then we must update the
	-- existing one rather than create a new one, if a change is required.
	-- However, if that entry has already been processed in a payroll run,
	-- then rather than updating it, we must ensure that the
	-- over/underpayment is corrected at the next opportunity. This is
	-- done by creating two entries; one which pays the correct amount
	-- and another, for the SSP Correction element, which reverses the
	-- incorrect payment by replicating it with a negative sign in front of
	-- the amount entry value. Before creating the negative entry, it is
	-- essential to check that there is not already a negative entry for
	-- the incorrect entry; we do not want to overcorrect.
	--
	-- The rate of SSP to be applied to each entry is that current for
	-- each day that a payment is being made. However, we know that the
	-- UK rate only changes once a year on 6th April. Therefore, it is only
	-- necessary to get the rate once unless the absence period crosses
	-- the 6th April. If this occurs, and there is a change of rate, then
	-- instead of one entry for that week, create two; one for each rate.
	-- The rate of SSP is held as the default for the rate input value
	-- on the SSP element.
	--
	-- The 'from' entry value will be the greater of the start date of the
	-- week for which the entry applies, and the absence start date. If the
	-- week includes the 6th April, when there is a change of SSP rate,
	-- then there will be one entry with a 'from' value of the start of
	-- that week or the start of the absence whichever is greater, and
	-- another entry with a from date of the 6th April.
	--
	-- The 'to' entry value will be the least of the end of the week for
	-- which the entry applies, and the PIW end date. If the week includes
	-- the 6th April, when there is a rate change, then there should be
	-- an entry created for the week up to the 5th April, and another for
	-- the remainder of the week.
	--
	-- The number of qualifying days is calculated by the calendars package
	-- functionality. Pass the start and end of the week and the ID of the
	-- person, requesting the SSP qualifying pattern availability. The
	-- return should be the number of qualifying days within the period.
	--
	-- The number of stopped qualifying days is derived by finding the
	-- period of overlap between the entry and any stoppage. Pass that
	-- period to the calendars package as for the number of qualifying days
	-- (see above). The return will be the number of qualifying days
	-- covered by the entry which are also covered by a stoppage.
	--
	-- The amount entry value is derived by subtracting the number of
	-- stopped qualifying days from the number of qualifying days (both
	-- figures explained above). The resulting number of days is multiplied
	-- by the SSP rate.
	--
	-- Each entry created by this procedure is to have a creator type
	-- which identifies it as an SSP entry, and a creator_id which is
	-- the absence_id of the first absence to which it relates, ie the
	-- linked_absence_id if it is populated or else the absence_id itself.
	--
--
function Linked_PIW_start_date
(
p_person_id		in number,
p_sickness_start_date   in date,
p_sickness_end_date     in date
--
) return date;
--pragma restrict_references (Linked_PIW_start_date, WNDS);
--
	-- Returns the start date of a linked series of Periods of Incapacity
	-- for Work (PIWs). Each sickness absence may be 'linked' by virtue
	-- of being separated by less than a certain period. The start of
	-- the linked PIW is the sickness start date of the first absence
	-- in a series.
	--
function Linked_PIW_end_date
(
p_person_id		in number,
p_sickness_start_date   in date,
p_sickness_end_date     in date
) return date;
--pragma restrict_references (Linked_PIW_end_date, WNDS);
--
	-- Returns the end date of a linked series of Periods of Incapacity
	-- for Work (PIWs).
	--
function qualifying_days_in_period
(
p_period_from		in date,
p_period_to		in date,
p_person_id		in number,
p_business_group_id     in number,
p_processing_level	in number default 0
) return integer;
----------
	-- Returns the number of SSP qualifying days in a specific period
	--
function SSP_is_installed return boolean;
	--
	-- Returns TRUE if the user has installed the SSP product.
	--
procedure SSP1L_control (
--
-- If prior employment details are updated then we must recalculate SSP
--
p_person_id             in number,
p_date_start            in date
);
--
procedure person_control (
--
-- If the person dies or the date of birth is modified then we need to
-- recalculate SSP.
--
p_person_id     in number,
p_date_of_death in date,
p_date_of_birth in date);
--
procedure absence_control (
--
p_absence_attendance_id in number,
p_linked_absence_id     in number,
p_person_id             in number,
p_sickness_start_date   in date,
p_deleting		in boolean default FALSE);
--
procedure earnings_control (
--
-- If average earnings are altered then we must recalculate SSP.
--
p_person_id             in number,
p_effective_date        in date);
--
procedure stoppage_control (
--
-- If stoppage altered we must recalculate SSP.
--
p_absence_id            in number);
--
procedure medical_control (
--
-- If medical evidence altered we must recalculate SSP.
--
p_absence_id            in number);
--
procedure SSP_control (p_absence_attendance_id in number);
--
function absence_is_a_PIW (
--
-- Returns TRUE if the sickness dates constitute a PIW for the person,
-- either in their own right or as part of a contiguous series of absences.
--
p_person_id	number,
p_sickness_start_date	date,
p_sickness_end_date	date) return boolean;
--pragma restrict_references (absence_is_a_PIW, WNDS);
--
procedure get_ssp_element (p_effective_date in date);
pragma restrict_references (get_ssp_element, WNDS);
--
end ssp_SSP_pkg;

/


GRANT EXECUTE ON APPS.SSP_SSP_PKG TO INTG_NONHR_NONXX_RO;
