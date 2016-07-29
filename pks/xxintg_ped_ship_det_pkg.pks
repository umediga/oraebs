DROP PACKAGE APPS.XXINTG_PED_SHIP_DET_PKG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_PED_SHIP_DET_PKG" 
AS

   ----------------------------------------------------------------------
   /*
    Created By     : Shankar Narayanan
    Creation Date  : 30-AUG-2013
    File Name      : XXINTG_Pedigree_PKG.pks
    Description    : This script creates the package specification for the xxintg_PED_SHIP_DET_PKG package


   Change History:

   Version Date          Name                Remarks
   ------- -----------   -----------------    -------------------------------
   1.0     30-AUG-2013   Shankar Narayanan       Initial development.
   
   */
   ----------------------------------------------------------------------
   
   PROCEDURE intg_PED_SHIP_DET_PRC (errbuf     OUT VARCHAR2,
                                    retcode    OUT VARCHAR2,
                                    p_org_id       NUMBER,
                                    p_date         VARCHAR2);
                                    
end xxintg_PED_SHIP_DET_PKG; 
/
