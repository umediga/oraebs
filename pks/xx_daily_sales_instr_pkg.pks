DROP PACKAGE APPS.XX_DAILY_SALES_INSTR_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_DAILY_SALES_INSTR_PKG" as
----------------------------------------------------------------------
/*
 Created By    : Ravi Vishnu
 Creation Date : 24-Dec-2014
 File Name     : xx_daily_sales_instr_pkg
 Description   : This code is being written to get data  for Recon Daily sales

 Change History:
 Date         Name                  Remarks
 ----------- -------------         -----------------------------------
 24-Dec-2014  Ravi Vishnu          Initial Version
*/
----------------------------------------------------------------------
   PROCEDURE main(p_division IN VARCHAR, p_from_date DATE, p_to_date DATE, p_dcode VARCHAR);
   end;
/
