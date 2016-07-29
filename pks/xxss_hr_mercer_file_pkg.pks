DROP PACKAGE APPS.XXSS_HR_MERCER_FILE_PKG;

CREATE OR REPLACE PACKAGE APPS.xxss_hr_mercer_file_pkg
as

/**************************************************************************
     Package              : Xxxss_hr_mercer_file_pkg
     Description          : This package creates extract file for SeaSpine Oracle
                            HR-Mercer outbound Interface

     Change List:
     ------------
     Name           Date        Version  Description
     -------------- ----------- -------  ------------------------------
     Shekhar Nikam  16-Jun-2015 1.0      Initial Version

***************************************************************************/

g_retcode NUMBER;
g_errmsg  VARCHAR2(2000);


TYPE g_census_data_rec_type IS RECORD
(person_id number
,national_identifier varchar2(30)
,employee_number varchar2(80)
,last_name varchar2(200)
,first_name varchar2(200)
,middle_name varchar2(200)
,gender varchar2(20)
,marital_status varchar2(100)
,date_of_birth varchar2(50)
,hire_date varchar2(50)
,ADJUSTED_HIRE_DATE varchar2(50)
,ADDRESS_LINE1 varchar2(200)
,ADDRESS_LINE2 varchar2(200)
,city varchar2(200)
,state varchar2(50)
,zip_code varchar2(50)
,work_phone varchar2(50)
,home_phone varchar2(50)
,WORK_LOCATION varchar2(100)
,EMAIL_ADDRESS varchar2(200)
,GRE varchar2(200)
,HR_ORGANIZATIONS varchar2(200)
,ASSIGNMENT_CHANGE_REASON varchar2(200)
,POSITION varchar2(200)
,PAYROLL_NAME varchar2(200)
,ASSIGNMENT_STATUS varchar2(200)
,FLSA_CODE varchar2(200)
,ASSIGNMENT_CATEGORY varchar2(200)
,WORKING_HOURS varchar2(50)
,SALARY_BASIS varchar2(200)
,BASE_SALARY varchar2(50)
,ACTUAL_TERMINATION_DATE varchar2(50)
,LEAVING_REASON varchar2(200)
,creation_date date
,status varchar2(10)
,error_message varchar2(2000)
);

TYPE g_census_data_tbl_type IS TABLE OF g_census_data_rec_type
INDEX BY BINARY_INTEGER;

procedure process_employees (p_eff_date IN DATE,p_file_name IN VARCHAR2);

procedure generate_file (p_file_name  IN VARCHAR2,p_data_dir   IN VARCHAR2) ;

procedure send_email(p_file_name IN VARCHAR2,p_data_dir IN VARCHAR2,x_return_code  OUT  NUMBER,x_error_msg OUT  VARCHAR2);

FUNCTION xx_hr_format_phone_num( p_phone_num IN VARCHAR2 )
return varchar2;

FUNCTION translate_leaving_reason(p_leaving_reason VARCHAR2)
return varchar2;

PROCEDURE truncate_table (p_table_name  IN      VARCHAR2);

procedure main (errbuf OUT VARCHAR2, retcode OUT VARCHAR2,p_effec_date IN VARCHAR2,p_file_name IN VARCHAR2);

end xxss_hr_mercer_file_pkg;
/
