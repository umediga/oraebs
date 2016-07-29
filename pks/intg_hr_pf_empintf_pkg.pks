DROP PACKAGE APPS.INTG_HR_PF_EMPINTF_PKG;

CREATE OR REPLACE PACKAGE APPS.intg_hr_pf_empintf_pkg AS

    PROCEDURE intg_hr_pf_employee_main(x_errbuff out VARCHAR2,
                                       x_retcode out NUMBER,
                                       p_eff_date IN VARCHAR2,
                                       p_file_name IN NUMBER);

    PROCEDURE hr_pf_per_data(x_errbuff OUT VARCHAR2,
                             x_retcode OUT NUMBER,
                             p_eff_date IN DATE,
                             p_file_name IN NUMBER);

    PROCEDURE hr_pf_emp_data(x_errbuff OUT VARCHAR2,
                             x_retcode OUT NUMBER,
                             p_eff_date IN DATE,
                             p_file_name IN NUMBER);
   PROCEDURE hr_pf_user_data(x_errbuff OUT VARCHAR2,
                              x_retcode OUT NUMBER,
                              p_eff_date IN DATE,
                              p_file_name IN NUMBER);
   PROCEDURE hr_pf_pos_holder_data(x_errbuff OUT VARCHAR2,
                                 x_retcode OUT NUMBER,
                                 p_eff_date IN DATE,
                                 p_file_name IN NUMBER);
function get_hr_person(p_person_id IN NUMBER, p_eff_date IN DATE)
return number;
function get_next_hr_emp(p_hr_person_id IN NUMBER, p_eff_date IN DATE)
return number;
   PROCEDURE hr_pf_pos_hr_data(x_errbuff OUT VARCHAR2,
                                 x_retcode OUT NUMBER,
                                 p_eff_date IN DATE,
                                 p_file_name IN NUMBER);
   PROCEDURE hr_pf_incentive_data(x_errbuff OUT VARCHAR2,
                                 x_retcode OUT NUMBER,
                                 p_eff_date IN DATE,
                                 p_file_name IN NUMBER);
   PROCEDURE hr_pf_salary_data(x_errbuff OUT VARCHAR2,
                                x_retcode OUT NUMBER,
                                p_eff_date IN DATE,
                                 p_file_name IN NUMBER);
   PROCEDURE hr_pf_custom_data(x_errbuff OUT VARCHAR2,
                                 x_retcode OUT NUMBER,
                                 p_eff_date IN DATE,
                                 p_file_name IN NUMBER);
   PROCEDURE create_pf_file( p_file_number    IN   VARCHAR2
                            ,p_file_name IN VARCHAR2
                            ,x_return_code  OUT  NUMBER
                            ,x_error_msg    OUT  VARCHAR2);
   PROCEDURE create_pf_err_file( p_file_number    IN   VARCHAR2
                                ,p_file_name       IN VARCHAR2
                                ,x_return_code  OUT  NUMBER
                                ,x_error_msg    OUT  VARCHAR2);
   PROCEDURE create_pf_log_file( p_file_number    IN   VARCHAR2
                                ,p_file_name IN VARCHAR2
                                ,x_return_code  OUT  NUMBER
                                ,x_error_msg    OUT  VARCHAR2);
END intg_hr_pf_empintf_pkg;
/
