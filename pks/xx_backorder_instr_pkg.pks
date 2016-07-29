DROP PACKAGE APPS.XX_BACKORDER_INSTR_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_BACKORDER_INSTR_PKG" as
----------------------------------------------------------------------
/*
 Created By    : Ravi Vishnu
 Creation Date : 02-Jan-2015
 File Name     : xx_backorder_instr_pkg
 Description   : This code is being written to get data for INSTR BackOrder

 Change History:
 Date         Name                  Remarks
 ----------- -------------         -----------------------------------
 02-Jan-2015  Ravi Vishnu          Initial Version
*/
----------------------------------------------------------------------
   PROCEDURE main(p_division IN VARCHAR, p_from_date DATE, p_to_date DATE, p_dcode VARCHAR);
   end;
/
