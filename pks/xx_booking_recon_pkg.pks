DROP PACKAGE APPS.XX_BOOKING_RECON_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_BOOKING_RECON_PKG" as
----------------------------------------------------------------------
/*
 Created By    : Ravi Vishnu
 Creation Date : 04-Dec-2014
 File Name     : xx_booking_recon_pkg
 Description   : This code is being written to get data  for Recon Daily sales Booking

 Change History:
 Date         Name                  Remarks
 ----------- -------------         -----------------------------------
 04-Dec-2014  Ravi Vishnu          Initial Version
*/
----------------------------------------------------------------------
PROCEDURE main(p_division IN VARCHAR, p_from_date DATE, p_to_date DATE, p_dcode VARCHAR, p_salesrep IN VARCHAR);
END xx_booking_recon_pkg;
/
