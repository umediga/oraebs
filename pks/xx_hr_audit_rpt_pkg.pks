DROP PACKAGE APPS.XX_HR_AUDIT_RPT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_AUDIT_RPT_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 08-Apr-2013
 File Name     : xx_hr_audit_rpt.pks
 Description   : This script creates the specification of the package
                 xx_hr_audit_rpt_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 08-Apr-2013 Renjith               Initial Version
 12-Sep-2013 Shekhar N             CC#3874 Updated to exclude the assignment and salary records
                                   having assignment type 'A' or 'O'. This update is in report_check
                                   PROC.

*/
----------------------------------------------------------------------

  PROCEDURE audit_report ( p_errbuf            OUT   VARCHAR2
                          ,p_retcode           OUT   VARCHAR2
                          ,p_country           IN    VARCHAR2
                          ,p_dummy3            IN    VARCHAR2
                          ,p_dummy4            IN    VARCHAR2
                          ,p_report_type       IN    VARCHAR2
                          ,p_dummy1            IN    VARCHAR2
                          ,p_dummy5            IN    VARCHAR2
                          ,p_prequest_id       IN    NUMBER
                          ,p_dummy2            IN    VARCHAR2
                          ,p_gre               IN    VARCHAR2
                          ,p_payroll_id        IN    NUMBER
                          ,p_run_type          IN    VARCHAR2
                          ,p_date_from         IN    VARCHAR2
                          ,p_date_to           IN    VARCHAR2
                         );
  PROCEDURE report_language ( p_user_id IN    NUMBER
                             ,x_lang    OUT   VARCHAR2
                             ,x_ter     OUT   VARCHAR2);
END xx_hr_audit_rpt_pkg;
/
