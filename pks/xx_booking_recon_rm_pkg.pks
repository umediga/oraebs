DROP PACKAGE APPS.XX_BOOKING_RECON_RM_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_BOOKING_RECON_RM_PKG" as
----------------------------------------------------------------------
/*
 Created By    : Ravi Vishnu
 Creation Date : 08-Nov-2014
 File Name     : XX_BOOKING_RECON_RM_PKG
 Description   : This code is being written to get data for recon BackOrder

 Change History:
 Date         Name                  Remarks
 ----------- -------------         -----------------------------------
 08-Nov-2014  Ravi Vishnu          Initial Version
*/
----------------------------------------------------------------------
   PROCEDURE main(p_division IN VARCHAR, p_from_date DATE, p_to_date DATE, p_dcode VARCHAR);
   end;
/
