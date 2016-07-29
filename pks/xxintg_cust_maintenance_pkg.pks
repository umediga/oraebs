DROP PACKAGE APPS.XXINTG_CUST_MAINTENANCE_PKG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_CUST_MAINTENANCE_PKG" AS
procedure debug(p_msg in varchar2);
PROCEDURE identify_flag(errbuf        OUT      VARCHAR2,
      retcode       OUT      VARCHAR2,
      p_party_id1 in NUMBER);
PROCEDURE obsolete_deliver_to(errbuf        OUT      VARCHAR2,
      retcode       OUT      VARCHAR2,
      p_party_id1 in NUMBER,
      p_validate varchar2,
      p_months in number);    
PROCEDURE obsolete_contact_to(p_party_id1 in NUMBER);     
PROCEDURE obsolete_quoting_data(errbuf        OUT      VARCHAR2,
      retcode       OUT      VARCHAR2,
      p_party_id1 in NUMBER);  
END xxintg_cust_maintenance_pkg; 
/
