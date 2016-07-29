DROP PACKAGE APPS.XX_CONCUR_EXTRACT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_CONCUR_EXTRACT_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : Jaya Maran Jayaraj
 Creation Date : 07-JAN-2014
 File Name     : xx_concur_extract_pkg.pks
 Description   : This script creates the specification of the package
                 xx_concur_extract_pkg
 Change History:
 Date        Name                     Remarks
 ----------- -------------------      -----------------------------------
 07-Jan-2014 Jaya Maran Jayaraj       Initial Version
*/
----------------------------------------------------------------------
   g_list_count NUMBER :=0;
   g_hr_count   NUMBER :=0;
   PROCEDURE list_extract (errbuf OUT VARCHAR2, retcode OUT VARCHAR2);

   PROCEDURE hr_extract (errbuf OUT VARCHAR2, retcode OUT VARCHAR2);

   FUNCTION active_status (
      p_employee_id          IN   NUMBER,
      p_effective_end_date   IN   DATE
   )
      RETURN VARCHAR2;

   FUNCTION division_name (p_organization_id IN NUMBER)
      RETURN VARCHAR2;

   FUNCTION division (p_name IN VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION send_supervisor (p_person_id IN NUMBER)
      RETURN VARCHAR2;

   FUNCTION pay_group (p_emp_number VARCHAR2)
      RETURN VARCHAR2;
END xx_concur_extract_pkg;
/
