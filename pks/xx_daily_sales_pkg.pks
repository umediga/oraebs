DROP PACKAGE APPS.XX_DAILY_SALES_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_DAILY_SALES_PKG" as
----------------------------------------------------------------------
/*
 Created By    : Balaji Krishnamurthy
 Creation Date : 12-July-2014
 File Name     : xx_daily_sales_pkg
 Description   : This code is being written to get data  for Recon Daily sales

 Change History:
 Date         Name                  Remarks
 ----------- -------------         -----------------------------------
 12-Jul-2014  Balaji Krishanmurthy          Initial Version
*/
----------------------------------------------------------------------
   PROCEDURE main(p_division IN VARCHAR, p_from_date DATE, p_to_date DATE, p_dcode VARCHAR, p_salesrep IN VARCHAR);
   end;
/
