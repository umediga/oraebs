DROP PACKAGE APPS.XX_ONT_CHRG_SHT_XMLP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ONT_CHRG_SHT_XMLP_PKG" AUTHID CURRENT_USER
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 26-MAR-2013
 File Name     : XXONTCHRGSHTXMLP.pks
 Description   : This script creates the specification of the package
                 xx_ont_chrg_sht_xmlp_pkg to create code for after
                 report trigger
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 26-MAR-2013 Sharath Babu          Initial Development
*/
----------------------------------------------------------------------

    p_header_id        NUMBER;
    p_case_num         VARCHAR2(50);
    p_email_send       VARCHAR2(10);
    p_email            VARCHAR2(240);
    P_CONC_REQUEST_ID  NUMBER;

    LP_WHERE           VARCHAR2(2000);

    FUNCTION AFTERPFORM RETURN BOOLEAN;
    FUNCTION AFTERREPORT RETURN BOOLEAN;

    FUNCTION get_email_id (p_header_id IN NUMBER) RETURN VARCHAR2;

END XX_ONT_CHRG_SHT_XMLP_PKG;
/
