DROP PACKAGE APPS.SSP_PAD_PKG;

CREATE OR REPLACE PACKAGE APPS.SSP_PAD_PKG AUTHID CURRENT_USER as
/*$Header: sppadapi.pkh 120.0.12000000.1 2007/01/17 14:14:47 appldev noship $
+==============================================================================+
|                       Copyright (c) 1994 Oracle Corporation                  |
|                          Redwood Shores, California, USA                     |
|                               All rights reserved.                           |
+==============================================================================+
--
Name
	Statutory Paternity Pay Adoption Business Process
--
Purpose
	To perform calculation of entitlement and payment for PAD purposes
--
History
	30 Oct 02       A Blinko   2690305  Created from SSP_SMP_PKG
*/
--------------------------------------------------------------------------------
-- ***************************************************************************
-- * Performs actions required by the UK legislation for Statutory
-- * Paternity Pay Adoption. See the High Level Design document for general
-- * details of the functionality and use of GB_PAT_ADO.
-- ***************************************************************************
--
c_PAD_element_name        constant varchar2(80) := 'Statutory Paternity Pay Adoption';
c_PAD_Corr_element_name   constant varchar2(80) := 'SPP Adoption Corrections';
c_PAD_creator_type	  constant varchar2(3)  := 'M';
c_PAD_entry_type	  constant varchar2(1)  := 'E';
c_week_commencing_name	  constant varchar2(30) := 'Week Commencing';
c_amount_name		  constant varchar2(30) := 'Amount';
c_recoverable_amount_name constant varchar2(30) := 'Recoverable Amount';
c_rate_name		  constant varchar2(30) := 'Rate';
--
-- Get the element details for PAD
--
-- Get the legislative parameters for PAD, which are held in the
-- Developer descriptive Flexfield of the element.
--
cursor CSR_PAD_ELEMENT_DETAILS (p_effective_date date     default sysdate,
                                p_element_name	 varchar2 default c_PAD_element_name) is
select ele1.element_type_id,
       ele1.effective_start_date,
       ele1.effective_end_date,
       to_number(ele1.element_information1) *7    EARLIEST_START_OF_PPP,
       to_number(ele1.element_information2) *7    QUALIFYING_WEEK,
       to_number(ele1.element_information3) *7    CONTINUOUS_EMPLOYMENT_PERIOD,
       to_number(ele1.element_information4)       MAXIMUM_PPP,
       to_number(ele1.element_information5)       MPP_NOTICE_REQUIREMENT,
       to_number(ele1.element_information6) /100  SPP_RATE,
       to_number(ele1.element_information7) /100  RECOVERY_RATE,
       to_number(ele1.element_information8)       STANDARD_RATE,
       to_number(ele1.element_information9) *7    LATEST_END_OF_PPP,
       ssp_smp_support_pkg.element_input_value_id
         (ele1.element_type_id,
          c_rate_name)                            RATE_ID,
       ssp_smp_support_pkg.element_input_value_id
         (ele1.element_type_id,
          c_week_commencing_name)                 WEEK_COMMENCING_ID,
       ssp_smp_support_pkg.element_input_value_id
	 (ele1.element_type_id,
          c_amount_name)                          AMOUNT_ID,
       ssp_smp_support_pkg.element_input_value_id
	 (ele1.element_type_id,
          c_recoverable_amount_name)              RECOVERABLE_AMOUNT_ID
from   pay_element_types_f ele1
where  ele1.element_name = p_element_name
and    p_effective_date between ele1.effective_start_date
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

function Earliest_PPP_start_date (p_due_date in date) return date;
--
-- Returns the earliest date a person may start their Paternity Pay
-- Period, based on the expected date.
--
pragma restrict_references (Earliest_PPP_start_date, WNPS,WNDS);

function Latest_PPP_start_date (p_placement_date in date) return date;
--
-- Returns the latest date a person may start their Paternity Pay
-- Period, based on the placement date.
--
pragma restrict_references (Latest_PPP_start_date, WNPS,WNDS);

function Continuous_employment_date (p_matching_date in date) return date;
--
-- Returns the start date of the period ending with the Qualifying
-- Week, for which the woman must have been continuously employed
-- in order to qualify for PAD
--
pragma restrict_references (Continuous_employment_date, WNPS,WNDS);

procedure PAD_control (p_maternity_id in number,
                       p_deleting     in boolean default FALSE);
--
end ssp_pad_pkg;

/


GRANT EXECUTE ON APPS.SSP_PAD_PKG TO INTG_NONHR_NONXX_RO;
