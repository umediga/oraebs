DROP PACKAGE BODY APPS.XX_OM_HCPREF_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OM_HCPREF_PKG" 
AS
  ----------------------------------------------------------------------
  /*
  Created By    : IBM
  Creation Date : 04-FEB-2014
  File Name     : XX_OM_HCPREF_PKG.pkb
  Description   : This script creates the body of the package
  xx_om_hcpref_pkg
  Change History:
  Date        Name                Remarks
  ----------- -------------       -----------------------------------
  04-FEB-2014 Renjith             Initial Development
  */
  ----------------------------------------------------------------------
  x_user_id      NUMBER := fnd_global.user_id;
  x_resp_id      NUMBER := fnd_global.resp_id;
  x_resp_appl_id NUMBER := fnd_global.resp_appl_id;
  x_login_id     NUMBER := fnd_global.login_id;
  x_request_id   NUMBER := fnd_global.conc_request_id;
  ----------------------------------------------------------------------
   PROCEDURE main (  p_errbuf        OUT  VARCHAR2
                    ,p_retcode       OUT  NUMBER
                    ,p_refresh       IN   VARCHAR2
                    ,p_clear         IN   VARCHAR2
                    )
  IS
  BEGIN
     IF p_refresh = 'Full' THEN
        DELETE FROM XXINTG_HCP_INT_REF;
        INSERT INTO XXINTG_HCP_INT_REF
        SELECT * FROM ITGR_HCP_IEXPENSE_DATA_DW
         WHERE npi IS NOT NULL;
     ELSIF p_refresh = 'Update' THEN
       DELETE FROM XXINTG_HCP_INT_REF
        WHERE EXISTS (SELECT npi FROM ITGR_HCP_IEXPENSE_DATA_DW);

        INSERT INTO XXINTG_HCP_INT_REF
        SELECT * FROM ITGR_HCP_IEXPENSE_DATA_DW
         WHERE npi IS NOT NULL
         AND NOT EXISTS (SELECT npi FROM XXINTG_HCP_INT_REF);
     END IF;
     IF p_clear = 'Y' THEN
        DELETE FROM ITGR_HCP_IEXPENSE_DATA_DW;
     END IF;
     COMMIT;
  EXCEPTION
      WHEN OTHERS THEN
          p_retcode := xx_emf_cn_pkg.cn_rec_warn;
  END main;
END xx_om_hcpref_pkg;
/
