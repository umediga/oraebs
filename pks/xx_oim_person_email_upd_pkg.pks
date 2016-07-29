DROP PACKAGE APPS.XX_OIM_PERSON_EMAIL_UPD_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OIM_PERSON_EMAIL_UPD_PKG" AUTHID CURRENT_USER
AS
----------------------------------------------------------------------
/* $Header: xxoimpersonemailupd.pks 1.0 2013/19/11 12:00:00 jbhosale noship $ */
/*
Created By     : INTEGRA Development Team
Creation Date  : 19-OCT-2013
File Name      : xxoimpersonemailupd.pks
Description    : This script is used to Update Integra Email Address on person record by OIM
 (Oracle Identity management) once exchange account is provisioned.
Change History:
Version Date        Name                     Remarks
------- ----------- ------------------------      ----------------------
1.0     19-NOV-2013   INTEGRA Development Team    Initial development.
1.1     03-DEC-2013   Jagdish Bhosale             Added Output parameter for status.
1.2     05-DEC-2013   Jagdish Bhosale             Bug: Email Update was not happening for CWK added NPW_NUMBER.
*/
/*----------------------------------------------------------------------*/
   PROCEDURE update_email (
      p_employee_number   IN       VARCHAR,
      p_email_address     IN       VARCHAR,
      p_status            OUT      VARCHAR
   );
END xx_oim_person_email_upd_pkg; 
/
