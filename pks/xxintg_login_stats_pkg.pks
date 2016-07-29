DROP PACKAGE APPS.XXINTG_LOGIN_STATS_PKG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_LOGIN_STATS_PKG" 
AS

PROCEDURE insert_stg_prc 
            (errbuf  out varchar2, 
             errcode out varchar2
            );
            
END  XXINTG_Login_Stats_Pkg; 
/
