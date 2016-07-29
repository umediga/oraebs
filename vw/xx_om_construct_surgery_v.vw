DROP VIEW APPS.XX_OM_CONSTRUCT_SURGERY_V;

/* Formatted on 6/6/2016 4:58:20 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_OM_CONSTRUCT_SURGERY_V
(
   SEGMENT1,
   DESCRIPTION,
   FIELD_ID
)
AS
   (SELECT m.segment1, m.description, m.segment1 field_id
      FROM apps.qp_pricing_attributes q,
           apps.qp_list_headers_all h,
           apps.mtl_system_items_b m
     WHERE     q.list_header_id = h.list_header_id
           AND q.product_attribute = 'PRICING_ATTRIBUTE1'
           AND h.context = 'Price List Details'
           AND h.attribute7 = 'CONSTRUCT'
           AND m.inventory_item_id = q.product_attr_value)
   UNION
   (SELECT flex_value segment1,
           fvl.description description,
           flex_value field_id
      FROM FND_FLEX_VALUES_VL fvl, FND_FLEX_VALUE_SETS fvs
     WHERE     fvs.FLEX_VALUE_SET_ID = fvl.FLEX_VALUE_SET_ID
           AND fvs.flex_value_set_name = 'INTG_NON_CONSTRUCT_SURGERY_TYPES');


GRANT SELECT ON APPS.XX_OM_CONSTRUCT_SURGERY_V TO XXAPPSREAD;
