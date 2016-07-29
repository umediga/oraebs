DROP PACKAGE APPS.XX_SDC_OIC_OUTBOUND_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_SDC_OIC_OUTBOUND_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 04-APR-2014
 File Name     : XXSDCOICOUTINTF.pks
 Description   : This script creates the specification of the package
                 xx_sdc_oic_outbound_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 04-APR-2014 Sharath Babu          Initial Development
 */
----------------------------------------------------------------------
   PROCEDURE fetch_upd_oic_details(
                                       p_errbuf           OUT NOCOPY  VARCHAR2
                                      ,p_retcode          OUT NOCOPY  NUMBER
                                      ,p_type             IN VARCHAR2
                                      ,p_hidden1          IN VARCHAR2
                                      ,p_hidden2          IN VARCHAR2
                                      ,p_slrep_num_from   IN JTF_RS_SALESREPS.SALESREP_NUMBER%TYPE DEFAULT NULL
                                      ,p_slrep_num_to     IN JTF_RS_SALESREPS.SALESREP_NUMBER%TYPE DEFAULT NULL
                                      ,p_date_from        IN VARCHAR2 DEFAULT NULL
                                      ,p_date_to          IN VARCHAR2 DEFAULT NULL
                                     );
END xx_sdc_oic_outbound_pkg;
/
