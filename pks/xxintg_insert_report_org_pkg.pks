DROP PACKAGE APPS.XXINTG_INSERT_REPORT_ORG_PKG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_INSERT_REPORT_ORG_PKG" 
AS
   PROCEDURE insert_reporting_org (
      x_errbuff   OUT   VARCHAR2,
      x_retcode   OUT   NUMBER
   );
end xxintg_insert_report_org_pkg;
/
