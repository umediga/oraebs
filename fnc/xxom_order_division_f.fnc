DROP FUNCTION APPS.XXOM_ORDER_DIVISION_F;

CREATE OR REPLACE FUNCTION APPS."XXOM_ORDER_DIVISION_F" (
   p_header_id       IN NUMBER
   ) RETURN VARCHAR2 IS
/*
|| This function returns the division for the given order header_id.
||
|| The division is determined by segment4 of the items on the order.
|| If all lines share the same division, then that value is returned.
|| If lines are from different divisions, then NULL is returned.
*/
   l_division_return          VARCHAR2(30) := NULL;
BEGIN
   /*
   || If this is moved to a package, The category_set_id for 'Sales and Marketing' 
   || could be derived in the package initialization and improve performance of this SQL.
   */
   SELECT DISTINCT mc.segment4 division
     INTO l_division_return
     FROM oe_order_Lines_all     ol,
          mtl_item_categories    mic,
          mtl_categories_b       mc,
          mtl_category_sets      mcs
    WHERE ol.header_id = p_header_id
      AND ol.inventory_item_id = mic.inventory_item_id
      AND ol.ship_from_org_id = mic.organization_id
      AND mic.category_id = mc.category_id
      AND mic.category_set_id = mcs.category_set_id
      AND mcs.category_set_name = 'Sales and Marketing';

   --No_data_found and too_many_rows should retunr NULL.
   RETURN l_division_return;
   
EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END xxom_order_division_f; 
/


GRANT EXECUTE ON APPS.XXOM_ORDER_DIVISION_F TO XXAPPSREAD;
