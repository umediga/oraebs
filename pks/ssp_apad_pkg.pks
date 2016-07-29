DROP PACKAGE APPS.SSP_APAD_PKG;

CREATE OR REPLACE PACKAGE APPS.SSP_APAD_PKG AUTHID CURRENT_USER as
/*$Header: spapadapi.pkh 120.0.12010000.1 2010/11/27 18:12:08 npannamp noship $
+==============================================================================+
|                       Copyright (c) 1994 Oracle Corporation                  |
|                          Redwood Shores, California, USA                     |
|                               All rights reserved.                           |
+==============================================================================+
--
Name
	Additional Statutory Paternity Pay Adoption Business Process
--
Purpose
	To perform calculation of entitlement and payment for APAD purposes
--
History
	17 Nov 10       npannamp   9897338  Created from SSP_PAD_PKG
*/
--------------------------------------------------------------------------------
-- ***************************************************************************
-- * Performs actions required by the UK legislation for Additional Statutory
-- * Paternity Pay Adoption. See the High Level Design document for general
-- * details of the functionality and use of GB_ADDL_PAT_ADO.
-- ***************************************************************************
--
c_APAD_element_name        constant varchar2(80) := 'Additional Statutory Paternity Pay Adoption';
c_APAD_Corr_element_name   constant varchar2(80) := 'ASPP Adoption Corrections';
c_APAD_creator_type	  constant varchar2(3)  := 'M';
c_APAD_entry_type	  constant varchar2(1)  := 'E';
c_week_commencing_name	  constant varchar2(30) := 'Week Commencing';
c_amount_name		  constant varchar2(30) := 'Amount';
c_recoverable_amount_name constant varchar2(30) := 'Recoverable Amount';
c_rate_name		  constant varchar2(30) := 'Rate';
--
-- Get the element details for APAD
--
-- Get the legislative parameters for APAD, which are held in the
-- Developer descriptive Flexfield of the element.
--
cursor CSR_APAD_ELEMENT_DETAILS (p_effective_date date     default sysdate,
                                p_element_name	 varchar2 default c_APAD_element_name) is
	select	ele1.element_type_id,
		ele1.effective_start_date,
		ele1.effective_end_date,
		to_number (ele1.element_information1) *7        EARLIEST_START_OF_ASPPP,
                to_number (ele1.element_information2) *7        QUALIFYING_WEEK,
		to_number (ele1.element_information3) *7        CONTINUOUS_EMPLOYMENT_PERIOD,
		to_number (ele1.element_information4)           MAXIMUM_ASPPP_WEEKS,
		to_number (ele1.ELEMENT_INFORMATION5)           MAXIMUM_ASPPP_MOM_DEATH_WEEKS,
		to_number (ele1.element_information6) /100      ASPP_RATE,
		to_number (ele1.element_information7) /100      RECOVERY_RATE,
                to_number (ele1.element_information8)           STANDARD_RATE,
                to_number (ele1.element_information9)          LATEST_END_OF_APL,
                to_number (ele1.element_information10)          MIN_APL_WEEKS,
                to_number (ele1.element_information11)          MAX_APL_WEEKS,
                to_number (ele1.element_information12)          MAX_APL_MOM_DEATH_WEEKS,
                to_number (ele1.element_information13)          EARLIEST_START_MOM_DEATH_ASPPP,
                to_number (ele1.element_information14)          ASPP_NOTICE_REQUIREMENT,
                to_number (ele1.element_information15)          ASPP_CHANGE_NOTICE_REQUIREMENT,
                to_number (ele1.element_information16) *7        DEATH_OF_CHILD_WEEK,
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
function MATERNITY_RECORD_EXISTS (p_person_id in number) return boolean;
--
-- Returns TRUE if there is a maternity record for the person
--
pragma restrict_references (maternity_record_exists, WNPS,WNDS);

function MATCHING_WEEK_OF_ADOPTION (p_matching_date in date) return date;
--
-- Returns the start date of the Matching Week
-- for SAP, based on the matching date.
--
pragma restrict_references (MATCHING_WEEK_OF_ADOPTION, WNPS,WNDS);

function Earliest_ASPPP_start_date (p_placement_date in date) return date;
--
-- Returns the earliest date a person may start their Paternity Pay
-- Period, based on the expected date.
--
pragma restrict_references (Earliest_ASPPP_start_date, WNPS,WNDS);

function Latest_ASPPP_start_date (p_placement_date in date, p_mpp_start_date in date) return date;
--
-- Returns the latest date a person may start their Paternity Pay
-- Period, based on the placement date.
--
pragma restrict_references (Latest_ASPPP_start_date, WNPS,WNDS);

function Continuous_employment_date (p_matching_date in date) return date;
--
-- Returns the start date of the period ending with the Qualifying
-- Week, for which the woman must have been continuously employed
-- in order to qualify for APAD
--
pragma restrict_references (Continuous_employment_date, WNPS,WNDS);

function partner_app_end_date (p_partner_app_start_date	in date, p_partner_return_to_work in date) return date;
--
	-- Returns the End date of mother/partners MPP/SAP.
	-- Date on which partner returns to work - 1.
	--
	pragma restrict_references (partner_app_end_date, WNPS,WNDS);
	--


procedure APAD_control (p_maternity_id in number,
                       p_deleting     in boolean default FALSE);
--
end ssp_APAD_pkg;

/


GRANT EXECUTE ON APPS.SSP_APAD_PKG TO INTG_NONHR_NONXX_RO;
