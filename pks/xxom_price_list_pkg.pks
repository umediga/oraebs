DROP PACKAGE APPS.XXOM_PRICE_LIST_PKG;

CREATE OR REPLACE PACKAGE APPS."XXOM_PRICE_LIST_PKG" AUTHID CURRENT_USER
----------------------------------------------------------------------
/* $Header: XXOMPRICELIST.pks 1.0 2012/05/02 12:00:00 npanda noship $ */
/*
 Created By    : IBM Development Team
 Creation Date : 02-May-2012
 File Name     : XXOMPRICELIST.pks
 Description   : This script creates the specification of the package
                 XXOM_PRICE_LIST_PKG
 Change History:
 Date         Name                   Remarks
 -----------  -------------          -----------------------------------
 02-May-2012  IBM Development Team   Initial Draft.
*/
----------------------------------------------------------------------
AS
-- =================================================================================
-- Record Type for Default Price List
-- =================================================================================
    TYPE xx_price_list_rec_type
    IS
    RECORD (
            list_header_id           NUMBER,
            name                     VARCHAR2 (240),
            product_precedence       NUMBER,
            order_number             NUMBER
           );

-- =================================================================================
-- Table Type By Using the Record Type for Default Price List
-- =================================================================================
    TYPE xx_price_list_tab_type
    IS
      TABLE OF xx_price_list_rec_type
         INDEX BY BINARY_INTEGER;

-- =================================================================================
-- Declare Table type Variable
-- =================================================================================
    p_price_list_table  xx_price_list_tab_type;

-- =================================================================================
-- Name           : XXOM_PRICE_LIST_PKG.get_price_list
-- Description    : This Function Will Invoked At OM Sales Order Line Form Personalization
--                  This will return Default Price List Name for the Item Entered in
--                  OM Order Line.
--                  If there is no Price for the Item then It will Return Null
-- Parameters description       :
--  IN:
--      p_ship_to_id:   Customer Ship To Org ID
--      p_item_id:      Inventory Item ID
--      p_customer_id:  Customer ID
--      p_org_id:       Operating Unit
--  IN OUT:
--  OUT:
-- ==============================================================================
FUNCTION get_price_list(p_ship_to_id    IN NUMBER,
                        p_item_id       IN NUMBER,
                        p_customer_id   IN NUMBER,
                        p_org_id        IN NUMBER
                       )
      RETURN VARCHAR2;

-- =================================================================================
-- Name           : XXOM_PRICE_LIST_PKG.get_price_list_id
-- Description    : This Function Will Invoked At OM Sales Order Line Form Personalization
--                  This will return Default Price List ID for the Item Entered in
--                  OM Order Line.
--                  If there is no Price for the Item then It will Return Null
-- Parameters description       :
--  IN:
--      p_ship_to_id:   Customer Ship To Org ID
--      p_item_id:      Inventory Item ID
--      p_customer_id:  Customer ID
--      p_org_id:       Operating Unit
--  IN OUT:
--  OUT:
-- ==============================================================================
FUNCTION get_price_list_id(p_ship_to_id    IN NUMBER,
                           p_item_id       IN NUMBER,
                           p_customer_id   IN NUMBER,
                           p_org_id        IN NUMBER
                          )
      RETURN NUMBER;

-- =================================================================================
-- Name           : XXOM_PRICE_LIST_PKG.get_price_list_aso
-- Description    : This Function Will Invoked At ASO Quote Line OAF
--                  This will return Default Price List Name for the Item Entered in
--                  ASO Quote Line.
--                  If there is no Price for the Item then It will Return Null
-- Parameters description       :
--  IN:
--      p_quote_header_id:   Quote Header ID
--      p_item_id:          Inventory Item ID
--  IN OUT:
--  OUT:
-- ==============================================================================
FUNCTION get_price_list_aso(p_quote_header_id   IN NUMBER,
                            p_item_id           IN NUMBER
                           )
      RETURN VARCHAR2;

-- ==============================================================================
-- Name           : XXOM_PRICE_LIST_PKG.get_sales_agreement_num
-- Description    : This Function Will Invoked At OM Sales Order Line Form Personalization
--                  This will return Sales Agreement Number for the Customer and
--                  Item Entered in OM Order Line.
--                  If there is no Sales Agreement for the Customer hen It will
--                  Return Null
-- Parameters description       :
--  IN:
--      p_ship_to_id:   Customer Ship To Org ID
--      p_item_id:      Inventory Item ID
--      p_customer_id:  Customer ID
--      p_org_id:       Operating Unit
--  IN OUT:
--  OUT:
-- ==============================================================================
FUNCTION get_sales_agreement_num(p_ship_to_id    IN NUMBER,
                                 p_item_id       IN NUMBER,
                                 p_customer_id   IN NUMBER,
                                 p_org_id        IN NUMBER
                                )
      RETURN NUMBER;
END XXOM_PRICE_LIST_PKG;
/
