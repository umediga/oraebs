DROP PACKAGE APPS.XXOM_CNSGN_TERR_SALESREP_PKG;

CREATE OR REPLACE PACKAGE APPS."XXOM_CNSGN_TERR_SALESREP_PKG" as
  CRLF            varchar2(1) := CHR(10);
gk_data_file_path constant varchar2(50) := fnd_profile.value('XXINTG_DATAFILE_OUTDIR');

  procedure write_file(p_retcode out number,x_error_message out varchar2,  p_datafile_name in varchar2 );
end xxom_cnsgn_terr_salesrep_pkg;
/
