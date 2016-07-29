DROP PACKAGE APPS.XX_BOOKING_INSTR_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_BOOKING_INSTR_PKG" as
----------------------------------------------------------------------
/*
 Created By    : Ravi Vishnu
 Creation Date : 02-Jan-2015
 File Name     : XX_BOOKING_INSTR_PKG
 Description   : This code is being written to get data for recon BackOrder

 Change History:
 Date         Name                  Remarks
 ----------- -------------         -----------------------------------
 02-Jan-2015  Ravi Vishnu          Initial Version
*/
----------------------------------------------------------------------
   PROCEDURE main(p_division IN VARCHAR, p_from_date DATE, p_to_date DATE, p_dcode VARCHAR);
   end;
/
