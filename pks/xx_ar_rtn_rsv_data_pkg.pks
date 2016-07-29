DROP PACKAGE APPS.XX_AR_RTN_RSV_DATA_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_RTN_RSV_DATA_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 30-JAN-2014
 File Name     : XXARRTNRSVRPT.pks
 Description   : This script creates the specification of the package
                 xx_ar_rtn_rsv_data_pkg to create code to fetch
                 report data
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 30-JAN-2014 Sharath Babu          Initial Development
*/
----------------------------------------------------------------------

   --Function to fetch credit memo data
   PROCEDURE get_rtn_rsv_report_data ( p_org_id     IN NUMBER
                                      ,p_date_from  IN DATE
                                      ,p_date_to    IN DATE
                                     );

END XX_AR_RTN_RSV_DATA_PKG;
/
