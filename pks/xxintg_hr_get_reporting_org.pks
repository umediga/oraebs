DROP PACKAGE APPS.XXINTG_HR_GET_REPORTING_ORG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_HR_GET_REPORTING_ORG" 
is

----------------------------------------------------------------------
/*
 Created By    : Jaya Maran Jayaraj
 Creation Date : 17-SEP-2014
 File Name     : xxintg_hr_get_reporting_org.pks
 Description   : This script creates the specification of the package
                 xxintg_hr_get_reporting_org
 Change History:
 Date        Name                     Remarks
 ----------- -------------------      -----------------------------------
 17-Sep-2014 Jaya Maran Jayaraj       Initial Version
*/
-------------------------------------------------------------------------
x_effective_date DATE;

function get_reporting_org (p_person_id IN NUMBER, p_effective_date DATE)
return varchar2;
end xxintg_hr_get_reporting_org; 
/


GRANT EXECUTE ON APPS.XXINTG_HR_GET_REPORTING_ORG TO XXAPPSHRRO;
