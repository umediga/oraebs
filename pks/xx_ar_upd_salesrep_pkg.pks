DROP PACKAGE APPS.XX_AR_UPD_SALESREP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_UPD_SALESREP_PKG" is
  ----------------------------------------------------------------------
  /*
   Created By    : IBM Development
   Creation Date :
   File Name     : XX_AR_UPDATE_SALESREP_PKG.pks
   Description   : This script creates the specification of the package
                   XX_AR_UPDATE_SALESREP_PKG and update sales reps
   Change History:
   Date        Name                  Remarks
   ----------- -------------         -----------------------------------
   19-Apr-2012 Renjith               Initial Version
  */
  ----------------------------------------------------------------------
  -- this proc will identify the no sales rep and update AR interface table with new sales rep
  procedure main_prc(x_errbuf out varchar2, x_retcode out varchar2, int_context in varchar2);
end xx_ar_upd_salesrep_pkg; 
/
