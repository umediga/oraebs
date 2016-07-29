DROP PACKAGE APPS.XX_INV_EO_EXP_ANLYS_XMLP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_INV_EO_EXP_ANLYS_XMLP_PKG" AUTHID CURRENT_USER
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 26-MAR-2013
 File Name     : XXINVEOEXPANLYXMLP.pks
 Description   : This script creates the specification of the package
                 XX_INV_EO_EXP_ANLYS_XMLP_PKG to create code for after
                 report trigger
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 26-MAR-2013 Sharath Babu          Initial Development
 21-MAY-2014 Aabhas Bhargava       Added Third Party Sales Unit Parameter
*/
----------------------------------------------------------------------

    p_org_id            NUMBER;
    p_org_hrchy         VARCHAR2(50);
    p_organization_id   NUMBER;
    p_inv_period        VARCHAR2(20);
    p_incl_intr_trx     VARCHAR2(5);
    p_lot_exp_date      VARCHAR2(30);
    p_usr_item_type     VARCHAR2(50);
    p_incl_exp          VARCHAR2(5);
    p_incl_thirdsales   VARCHAR2(5);

    P_CONC_REQUEST_ID   NUMBER;

    LP_ORG_HRCY         VARCHAR2(1000);
    LP_ORG              VARCHAR2(240);
    LP_ITEM_TYPE        VARCHAR2(240);

    FUNCTION AFTERPFORM RETURN BOOLEAN;
    FUNCTION AFTERREPORT RETURN BOOLEAN;
    FUNCTION BEFOREREPORT RETURN BOOLEAN;


END XX_INV_EO_EXP_ANLYS_XMLP_PKG;
/
