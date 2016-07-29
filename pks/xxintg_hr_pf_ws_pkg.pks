DROP PACKAGE APPS.XXINTG_HR_PF_WS_PKG;

CREATE OR REPLACE PACKAGE APPS.xxintg_hr_pf_ws_pkg
AS
----------------------------------------------------------------------
/*
 Created By    : Shekhar Nikam
 Creation Date : 06-OCT-2014
 File Name     : xxintg_hr_pf_ws_pkg.pks
 Description   : This script creates the specification of the package
                 xxintg_hr_pf_ws_pkg
 Change History:
 Date          Name                  Remarks
 -----------   -------------         -----------------------------------
 06-OCT-2014   Shekhar Nikam          Initial development.
 */
------------------------------------------------------------------------
PROCEDURE main(x_errbuff out VARCHAR2,
                                       x_retcode out NUMBER,
                                       p_eff_date IN VARCHAR2, -- Shekhar : Changed to Varchar2
                                       p_file_name IN NUMBER);

PROCEDURE hr_pf_wsdata(x_errbuff OUT VARCHAR2,
                                 x_retcode OUT NUMBER,
                                 p_eff_date IN DATE,
                                 p_file_name IN NUMBER);

PROCEDURE hr_pf_org_data(x_errbuff out VARCHAR2,
                                     x_retcode out NUMBER,
                                     p_eff_date IN DATE,
                                     p_file_name IN NUMBER);
PROCEDURE hr_pf_job_data(x_errbuff out VARCHAR2,
                                     x_retcode out NUMBER,
                                     p_eff_date IN DATE,
                                     p_file_name IN NUMBER);
PROCEDURE hr_pf_pos_a_data(x_errbuff out VARCHAR2,
                                     x_retcode out NUMBER,
                                     p_eff_date IN DATE,
                                     p_file_name IN NUMBER);

PROCEDURE hr_pf_pos_b_data(x_errbuff out VARCHAR2,
                                     x_retcode out NUMBER,
                                     p_eff_date IN DATE,
                                     p_file_name IN NUMBER);


PROCEDURE create_pf_file( p_file_number    IN   VARCHAR2
                          ,p_file_name IN Varchar2
                           ,x_return_code  OUT  NUMBER
                           ,x_error_msg    OUT  VARCHAR2);


PROCEDURE create_pf_err_file( p_file_number    IN   VARCHAR2
                          ,p_file_name IN Varchar2
                           ,x_return_code  OUT  NUMBER
                           ,x_error_msg    OUT  VARCHAR2);
PROCEDURE create_pf_log_file( p_file_number    IN   VARCHAR2
                          ,p_file_name IN Varchar2
                           ,x_return_code  OUT  NUMBER
                           ,x_error_msg    OUT  VARCHAR2);
FUNCTION get_sup_position(p_person_id IN NUMBER, p_effective_date IN DATE)
RETURN NUMBER;


END xxintg_hr_pf_ws_pkg;
/
