DROP PACKAGE APPS.XX_PO_SUP_ADI_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_PO_SUP_ADI_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : Yogesh (IBM Development)
 Creation Date : 06-Jun-2013
 File Name     : xxposupadi.pks
 Description   : This script creates the specification of the package
                 xx_po_sup_adi_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 06-Jun-2013 Yogesh                Initial Version
*/
----------------------------------------------------------------------
FUNCTION update_po_doc (p_action         IN        VARCHAR2
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
FUNCTION add_line_bpa_doc (p_action         IN        VARCHAR2
                          ,p_po_num         IN        VARCHAR2
                          ,P_line_num       IN        VARCHAR2
                          ,p_line_type      IN        VARCHAR2
                          ,p_item           IN        VARCHAR2
                          ,p_item_desc      IN        VARCHAR2
                          ,P_unit_price     IN        NUMBER
                          ,p_supplier       IN        VARCHAR2
                          ,p_last_line_flag IN        VARCHAR2
                          )
RETURN VARCHAR2;

----------------------------------------------------------------------
FUNCTION call_import_program
RETURN VARCHAR2;

END xx_po_sup_adi_pkg;
/
