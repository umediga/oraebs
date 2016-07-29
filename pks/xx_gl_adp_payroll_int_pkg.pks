DROP PACKAGE APPS.XX_GL_ADP_PAYROLL_INT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_GL_ADP_PAYROLL_INT_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : XXGLADPPAYINT.pks
 Description   : This script creates the specification of the package
                 xx_gl_adp_payroll_int_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 21-Feb-2012 Renjith               Initial Version
 12-Apr-2013 Yogesh                Commented Segment9 in G_XX_GL_ADP_PAYROLL_REC_TYPE
 20-Feb-2015 Dhiren                Added new procedure xx_gl_is_num
*/
----------------------------------------------------------------------
g_stage            VARCHAR2(2000);
g_data_dir         VARCHAR2(200);
g_arch_dir         VARCHAR2(200);
g_email_id         VARCHAR2(200);
g_set_of_books     VARCHAR2(30);
g_journal_name     VARCHAR2(100);
g_currency_conversion_type VARCHAR2(30);
g_set_of_books_id  NUMBER;
g_je_source_name   VARCHAR2(100);
g_je_category_name VARCHAR2(100);
g_group_id         NUMBER;
g_data_file_name   VARCHAR2(60);
g_ftp_data_dir_name VARCHAR2(60);
g_ftp_data_dir_arch VARCHAR2(60);
g_je_cur_code       VARCHAR2(10);

TYPE G_XX_GL_ADP_PAYROLL_REC_TYPE IS RECORD
( record_id               NUMBER
 ,batch_id                NUMBER
 ,file_name               VARCHAR2(260)
 ,user_je_category_name   VARCHAR2(25)
 ,user_je_source_name     VARCHAR2(25)
 ,currency_code           VARCHAR2(15)
 ,accounting_date         DATE
 ,segment1                VARCHAR2(25)
 ,segment2                VARCHAR2(25)
 ,segment3                VARCHAR2(25)
 ,segment4                VARCHAR2(25)
 ,segment5                VARCHAR2(25)
 ,segment6                VARCHAR2(25)
 ,segment7                VARCHAR2(25)
 ,segment8                VARCHAR2(25)
 --,segment9                VARCHAR2(25)
 ,date_created            DATE
 ,actual_flag             VARCHAR2(1)
 ,entered_dr              NUMBER
 ,entered_cr              NUMBER
 ,line_description        VARCHAR2(50) -- reference10
 ,journal_name            VARCHAR2(50)
 ,status                  VARCHAR2(50)
 ,request_id              NUMBER
 ,process_code            VARCHAR2(100)
 ,error_code              VARCHAR2(100)
 ,error_message           VARCHAR2(4000)
 ,created_by              NUMBER
 ,creation_date           DATE
 ,last_update_date        DATE
 ,last_updated_by         NUMBER
 ,last_update_login       NUMBER
);

TYPE G_XX_GL_ADP_PAYROLL_TAB_TYPE IS TABLE OF G_XX_GL_ADP_PAYROLL_REC_TYPE
INDEX BY BINARY_INTEGER;

-- Interface proc
PROCEDURE main_prc ( p_errbuf        OUT VARCHAR2
                    ,p_retcode       OUT VARCHAR2
                    ,p_reprocess     IN  VARCHAR2
                    ,p_dummy         IN  VARCHAR2
                    ,p_requestid     IN  NUMBER
                    ,p_file_name     IN  VARCHAR2
                    ,p_restart_flag  IN  VARCHAR2);

PROCEDURE utl_read_insert_stg( x_error_code    OUT   NUMBER
                              ,x_error_msg     OUT   VARCHAR2);

FUNCTION xx_gl_is_num(n varchar2)
RETURN VARCHAR2;


END xx_gl_adp_payroll_int_pkg;
/
