DROP PACKAGE APPS.XX_PO_MULTI_ADI_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_PO_MULTI_ADI_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : Yogesh (IBM Development)
 Creation Date : 12-Jan-2014
 File Name     : xxpomultiadi.pks
 Description   : This script creates the specification of the package
                 xx_po_multi_adi_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 12-Jan-2014 Yogesh                Initial Version
*/
----------------------------------------------------------------------
FUNCTION update_po_multi_doc (p_action         IN        VARCHAR2
                            ,p_po_number      IN        VARCHAR2
                            ,p_po_line_num    IN        VARCHAR2
                            ,p_rel_num        IN        VARCHAR2
                            ,p_ship_line_num  IN        VARCHAR2
                            ,p_item           IN        VARCHAR2
                            ,p_item_desc      IN        VARCHAR2
                            ,p_quantity       IN        VARCHAR2
                            ,p_unit_price     IN        NUMBER
                            ,p_need_by_date   IN        VARCHAR2
                            ,p_promise_date   IN        VARCHAR2
                            ,p_sup_name       IN        VARCHAR2
                            ,p_last_line_flag IN        VARCHAR2
                       )
RETURN VARCHAR2;
----------------------------------------------------------------------

END xx_po_multi_adi_pkg;
/
