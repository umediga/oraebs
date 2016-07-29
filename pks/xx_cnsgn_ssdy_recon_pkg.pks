DROP PACKAGE APPS.XX_CNSGN_SSDY_RECON_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_CNSGN_SSDY_RECON_PKG" is
procedure get_onhand_qty (p_organization_code char,p_retcode number, p_errbuf char);
procedure load_ssdy_files (p_organization_id number,p_retcode number, p_errbuf char);
end xx_cnsgn_ssdy_recon_pkg; 
/
