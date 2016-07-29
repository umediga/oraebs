DROP PACKAGE APPS.XXINTG_HR_SECURITY_PROFILE;

CREATE OR REPLACE PACKAGE APPS."XXINTG_HR_SECURITY_PROFILE" 
AS
----------------------------------------------------------------------
/*
 Created By    : Kirthana Ramesh
 Creation Date : 25-JAN-2013
 File Name     : XXINTG_HR_SECURITY_PROFILE.pks
 Description   : This script creates the specification of the package
                XXINTG_HR_SECURITY_PROFILE which is used to build the
                custom HR Security framework for Integra
 Change History:
 Date          Name                  Remarks
 -----------   -------------         -----------------------------------
 25-JAN-2013   Kirthana Ramesh       Initial Development
 04-NOV-2013   Francis               variable x_effective_date added for ticket 3088
*/
----------------------------------------------------------------------
x_effective_date DATE;
   FUNCTION xxintg_is_hr_person (p_person_id IN NUMBER)
      RETURN VARCHAR2;

   FUNCTION xxintg_is_subordinate (p_person_id IN NUMBER)
      RETURN VARCHAR2;

   FUNCTION xxintg_is_record_allowed (p_person_id IN NUMBER)
      RETURN VARCHAR2;
END xxintg_hr_security_profile;
/
