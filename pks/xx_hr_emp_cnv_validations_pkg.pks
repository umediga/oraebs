DROP PACKAGE APPS.XX_HR_EMP_CNV_VALIDATIONS_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_EMP_CNV_VALIDATIONS_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : XXHREMPVAL.pks
 Description   : This script creates the body of the package specs for
                 xx_hr_emp_cnv_validations_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 30-Oct-2007 Setu                  Initial development.
 06-Jan-2012 Deepika Jain          Changes for Integra

*/
----------------------------------------------------------------------
   g_emp_person_type           VARCHAR2 (100) := 'Employee';
   g_cwk_person_type           VARCHAR2 (100) := 'Contingent Worker';
   g_cdt_person_type           VARCHAR2 (100) := 'Candidate';
   g_country_category          VARCHAR2 (100) := 'Country';
   g_business_group_category   VARCHAR2 (100) := 'Business Group';
   g_person_type_category      VARCHAR2 (100) := 'Person Type';
   g_emp_num_category          VARCHAR2 (100) := 'Employee Number';
   g_first_name_category       VARCHAR2 (100) := 'First Name';
   g_date_of_birth_category    VARCHAR2 (100) := 'Date of Birth';
   g_hire_date_category        VARCHAR2 (100) := 'Hire Date';
   g_email_address_category    VARCHAR2 (100) := 'Email Address';
   g_unique_id_category        VARCHAR2 (100) := 'Unique Id';
   g_i9_exp_date_category      VARCHAR2 (100) := 'i9 Expiration Date';
   g_us_ethnic_origin          VARCHAR2 (100) := 'US_ETHNIC_ORIGIN';

   FUNCTION find_max (p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION pre_validations (
      p_cnv_hdr_rec   IN OUT NOCOPY   xx_hr_emp_conversion_pkg.g_xx_hr_cnv_pre_rec_type
   )
      RETURN NUMBER;

   FUNCTION data_validations (
      p_cnv_hdr_rec   IN OUT NOCOPY   xx_hr_emp_conversion_pkg.g_xx_hr_cnv_pre_rec_type
   )
      RETURN NUMBER;

   FUNCTION post_validations
      RETURN NUMBER;

   FUNCTION data_derivations (
      p_cnv_pre_std_hdr_rec   IN OUT NOCOPY   xx_hr_emp_conversion_pkg.g_xx_hr_cnv_pre_rec_type
   )
      RETURN NUMBER;
END xx_hr_emp_cnv_validations_pkg;
/
