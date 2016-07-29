DROP PACKAGE APPS.XX_HR_AUDIT_TRIG_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_AUDIT_TRIG_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 08-Apr-2013
 File Name     : xx_hr_audit_trig.pks
 Description   : This script creates the specification of the package
                 xx_hr_audit_trig_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 08-Apr-2013 Renjith               Initial Version
*/
----------------------------------------------------------------------
  PROCEDURE insert_audit (  p_person_id              IN NUMBER
                           ,p_table_prim_id          IN NUMBER
                           ,p_table_name             IN VARCHAR2
                           ,p_data_element           IN VARCHAR2
                           ,p_data_value_old         IN VARCHAR2
                           ,p_data_value_new         IN VARCHAR2
                           ,p_data_element_upd_date  IN DATE
                           ,p_effective_start_date   IN DATE
                           ,p_effective_end_date     IN DATE
                           ,p_creation_date          IN DATE);

  PROCEDURE insert_audit_date (  p_person_id              IN NUMBER
                                ,p_table_prim_id          IN NUMBER
                                ,p_table_name             IN VARCHAR2
                                ,p_data_element           IN VARCHAR2
                                ,p_data_value_old         IN VARCHAR2
                                ,p_data_value_new         IN VARCHAR2
                                ,p_data_element_upd_date  IN DATE
                                ,p_effective_start_date   IN DATE
                                ,p_effective_end_date     IN DATE
                                ,p_creation_date          IN DATE);


END xx_hr_audit_trig_pkg;
/
