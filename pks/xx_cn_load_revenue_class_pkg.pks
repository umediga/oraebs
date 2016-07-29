DROP PACKAGE APPS.XX_CN_LOAD_REVENUE_CLASS_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_CN_LOAD_REVENUE_CLASS_PKG" IS

   ----------------------------------------------------------------------
   /*
    Created By    : Kunal Seal
    Creation Date : 27-Mar-2012
    File Name     : XXCNCOMITEM.PKS
    Description   : This package creates Revenue Class in OIC tables for
                    the commissionable items in Inventory
    Change History:
    Date           Name                  Remarks
    -----------    -------------         -----------------------------------
    27-Mar-2012    Kunal Seal            Initial Version
   */
   ----------------------------------------------------------------------
   PROCEDURE create_revenue_class(p_item_no     IN VARCHAR2,
                                  p_description IN VARCHAR2,
                                  p_org_id      IN NUMBER);

   PROCEDURE main(errbuff OUT VARCHAR2, retcode OUT VARCHAR2);
END xx_cn_load_revenue_class_pkg;
/
