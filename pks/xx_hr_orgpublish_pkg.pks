DROP PACKAGE APPS.XX_HR_ORGPUBLISH_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_ORGPUBLISH_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 17-Dec-2012
 File Name     : XXHRORGPUBLISH.pks

 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 17-Dec-2012 Renjith               Initial Version
*/
----------------------------------------------------------------------


FUNCTION record_type (  p_emp_id            IN    NUMBER
                       ,p_job_title         IN    VARCHAR2
                       ,p_per_type          IN    VARCHAR2
                       ,p_position          IN    VARCHAR2)  RETURN VARCHAR2;

END xx_hr_orgpublish_pkg;
/
