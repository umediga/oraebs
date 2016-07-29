DROP FUNCTION APPS.XX_MTL_ITEM_CATEGORIES;
/**
*uediga, new function
*/
CREATE OR REPLACE FUNCTION APPS."XX_MTL_ITEM_CATEGORIES" (p_ITEM_ID NUMBER,p_category VARCHAR,p_org_id NUMBER, p_ip in VARCHAR)
RETURN VARCHAR AS
l_cat_set_name  VARCHAR2(200);
l_concat_segs   VARCHAR2(200);
l_div           VARCHAR2(200);
BEGIN

     select b.CATEGORY_SET_NAME,c.concatenated_segments,c.segment4
     into l_cat_set_name , l_concat_segs,l_div
     from MTL_ITEM_CATEGORIES a
         ,MTL_CATEGORY_SETS B
         ,mtl_categories_kfv c
     where a.CATEGORY_SET_ID = B.CATEGORY_SET_ID
     and  B.CATEGORY_SET_NAME = p_category
     and a.category_id = c.category_id
     and a.INVENTORY_ITEM_ID = p_ITEM_ID
     and a.organization_id = p_org_id;

     IF p_ip = 'CAT_SET' THEN
        return(l_cat_set_name);
     ELSIF p_ip = 'CONCATE_SEG' THEN
        return(l_concat_segs);
     ELSIF    p_ip = 'DIV' THEN
        return(l_div);
     ELSE
         return NULL;
     END IF;

Exception
when others then
     return(null);
END;
/
