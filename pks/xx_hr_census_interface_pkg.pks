DROP PACKAGE APPS.XX_HR_CENSUS_INTERFACE_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_CENSUS_INTERFACE_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 05-MAY-2013
 File Name     : XXHREMPCNSINTF.pks
 Description   : This script creates the specification of the package
                 xx_hr_census_interface_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 05-MAY-2013 Sharath Babu          Initial development.
 01-Dec-2014 Jaya Maran            Modified for defect#10447
*/
----------------------------------------------------------------------

   --Global Variables
   g_retcode NUMBER;
   g_errmsg  VARCHAR2(1000);

   TYPE g_census_data_rec_type IS RECORD
   (
    company_id                     NUMBER,
    line_business_code             VARCHAR2(40),
    employee_ssn                   VARCHAR2(300),
    last_name                      VARCHAR2(300),
    first_name                     VARCHAR2(240),
    middle_initial                 VARCHAR2(240),
    address_line1                  VARCHAR2(240),
    address_line2                  VARCHAR2(240),
    city                           VARCHAR2(30),
    state                          VARCHAR2(120),
    zip                            VARCHAR2(30),
    hire_date                      VARCHAR2(30),
    termination_date               VARCHAR2(30),
    adjusted_hire_date             VARCHAR2(30),
    plan_eligibility_date          VARCHAR2(30),
    base_salary                    NUMBER,
    additional_salary              NUMBER,
    filler1                        VARCHAR2(240),
    other_compensation1            VARCHAR2(240),
    other_compensation2            VARCHAR2(240),
    other_compensation3            VARCHAR2(240),
    filler2                        VARCHAR2(240),
    hours_per_week                 NUMBER,
    emp_category                   VARCHAR2(80),
    location_code                  VARCHAR2(60),
    date_of_birth                  VARCHAR2(30),
    gender                         VARCHAR2(30),
    smoker                         VARCHAR2(240),
    filler3                        VARCHAR2(240),
    months_per_year_worked         VARCHAR2(240),
    union_member                   VARCHAR2(240),
    filler4                        VARCHAR2(240),
    pin                            VARCHAR2(240),
    payroll_mode                   VARCHAR2(240),
    payroll_site                   VARCHAR2(240),
    department_code                VARCHAR2(240),
    division_code                  VARCHAR2(240),
    occupation_code                VARCHAR2(80),
    other_id                       VARCHAR2(30),
    marital_status                 VARCHAR2(30),
    cobra                          VARCHAR2(240),
    phone_number1                  VARCHAR2(60),
    phone_number2                  VARCHAR2(60),
    tax_filing_status_code         VARCHAR2(240),
    filler5                        VARCHAR2(240),
    vacation_days                  VARCHAR2(240),
    filler6                        VARCHAR2(240),
    user_defined1                  VARCHAR2(240),
    user_defined2                  VARCHAR2(240),
    user_defined3                  VARCHAR2(240),
    user_defined4                  VARCHAR2(240),
    user_defined5                  VARCHAR2(240),
    user_defined6                  VARCHAR2(240),
    user_defined7                  VARCHAR2(240),
    user_defined8                  VARCHAR2(240),
    user_defined9                  VARCHAR2(240),
    user_defined10                 VARCHAR2(240),
    user_defined11                 VARCHAR2(240),
    user_defined12                 VARCHAR2(240),
    user_defined13                 VARCHAR2(240),
    user_defined14                 VARCHAR2(240),
    user_defined15                 VARCHAR2(240),
    user_defined16                 VARCHAR2(240),
    user_defined17                 VARCHAR2(240),
    user_defined18                 VARCHAR2(240),
    user_defined19                 VARCHAR2(240),
    user_defined20                 VARCHAR2(240),
    user_defined21                 VARCHAR2(240),
    user_defined22                 VARCHAR2(240),
    user_defined23                 VARCHAR2(240),
    user_defined24                 VARCHAR2(240),
    work_state                     VARCHAR2(120),
    filler7                        VARCHAR2(240),
    email_address_work             VARCHAR2(240),
    email_address_home             VARCHAR2(240),
    termination_reason_code        VARCHAR2(240),
    country_code                   VARCHAR2(60),
    record_number                  NUMBER,
    process_code                   VARCHAR2(100),
    error_code                     VARCHAR2(100),
    request_id                     NUMBER,
    file_name                      VARCHAR2(100),
    created_by                     NUMBER,
    creation_date                  DATE,
    last_update_date               DATE,
    last_updated_by                NUMBER,
    last_update_login              NUMBER
    );
    TYPE g_census_data_tbl_type IS TABLE OF g_census_data_rec_type
    INDEX BY BINARY_INTEGER;

   PROCEDURE xx_hr_process_data_stg (
                                      p_eff_date            IN       DATE,
                                      p_request_id          IN       NUMBER,
                                      p_file_name           IN       VARCHAR2
                                     );

   PROCEDURE xx_hr_file_generation (
                                    p_file_name  IN VARCHAR2,
                                    p_data_dir   IN VARCHAR2,
                                    p_hdr_data   IN VARCHAR2,
                                    p_request_id IN NUMBER
                                   );


   PROCEDURE send_ben_file_email(p_file_name IN VARCHAR2
                           ,p_data_dir   IN VARCHAR2
                           ,x_return_code  OUT  NUMBER
                           ,x_error_msg    OUT  VARCHAR2);
                           
   FUNCTION xx_hr_format_phone_num( p_phone_num IN VARCHAR2 ) RETURN VARCHAR2;

   PROCEDURE main (
                    errbuf                OUT      VARCHAR2,
                    retcode               OUT      VARCHAR2,
                    p_effec_date          IN       VARCHAR2,
                    p_file_name           IN       VARCHAR2,
                    p_file_reprocess      IN       VARCHAR2,
                    p_dummy1              IN       VARCHAR2,
                    p_request_id          IN       NUMBER
                   );

END xx_hr_census_interface_pkg; 
/
