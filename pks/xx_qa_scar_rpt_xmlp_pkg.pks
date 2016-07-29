DROP PACKAGE APPS.XX_QA_SCAR_RPT_XMLP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_QA_SCAR_RPT_XMLP_PKG" AUTHID CURRENT_USER
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 11-DEC-2012
 File Name     : XXQASCARRPT.pkb
 Description   : This script creates the specification of the package
                 xx_qa_scar_rpt_xmlp_pkg to create code for after
                 parameter form trigger
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 11-DEC-2012 Sharath Babu          Initial Development
 06-SEP-2013 Francis               Address function has been added
*/
----------------------------------------------------------------------
    p_scar_pname VARCHAR2(240);
    p_ncmr_pname VARCHAR2(240);
    p_inv_org    VARCHAR2(240);
    p_scar_num   VARCHAR2(240);
    lp_q_scar_v  VARCHAR2(240);
    lp_q_ncmr_v  VARCHAR2(240);
    FUNCTION AFTERPFORM RETURN BOOLEAN;
    FUNCTION ADDRESS(ln_location_id NUMBER) RETURN VARCHAR2;
END XX_QA_SCAR_RPT_XMLP_PKG;
/
