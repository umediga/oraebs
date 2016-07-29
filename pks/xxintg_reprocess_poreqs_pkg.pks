DROP PACKAGE APPS.XXINTG_REPROCESS_POREQS_PKG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_REPROCESS_POREQS_PKG" 
as
  
   procedure auto_create_internal_req(x_return_status out nocopy varchar2);
   procedure main (errbuf out varchar2, retcode out varchar2);

end xxintg_reprocess_poreqs_pkg; 
/
