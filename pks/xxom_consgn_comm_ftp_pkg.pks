DROP PACKAGE APPS.XXOM_CONSGN_COMM_FTP_PKG;

CREATE OR REPLACE PACKAGE APPS."XXOM_CONSGN_COMM_FTP_PKG" as
procedure gen_conf_file (p_file_name IN VARCHAR,p_data_dir varchar2, p_arch_dir varchar2);
procedure ftp_data_file;
procedure add_new_file (p_file_name IN VARCHAR);
end; 
/
