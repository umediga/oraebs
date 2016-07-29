DROP PACKAGE APPS.XX_BACKORDER_RECON_RM_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_BACKORDER_RECON_RM_PKG" as
----------------------------------------------------------------------
/*
 Created By    : Ravi Vishnu
 Creation Date : 05-Nov-2014
 File Name     : xx_backorder_recon_rm_pkg
 Description   : This code is being written to get data for recon BackOrder

 Change History:
 Date         Name                  Remarks
 ----------- -------------         -----------------------------------
 05-Nov-2014  Ravi Vishnu          Initial Version
*/
----------------------------------------------------------------------
   PROCEDURE main(p_division IN VARCHAR, p_from_date DATE, p_to_date DATE, p_dcode VARCHAR);
   end;
/
