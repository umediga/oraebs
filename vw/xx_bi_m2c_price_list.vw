DROP VIEW APPS.XX_BI_M2C_PRICE_LIST;

/* Formatted on 6/6/2016 4:59:28 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_M2C_PRICE_LIST
(
   PRODUCT_ATTRIBUTE_VALUE,
   START_DATE_ACTIVE,
   END_DATE_ACTIVE,
   NAME,
   ACTIVE_FLAG,
   START_DATE_ACTIVE_1,
   END_DATE_ACTIVE_1
)
AS
   (SELECT qp_price_list_line_util.get_product_value (
              'QP_ATTR_DEFNS_PRICING',
              pa.product_attribute_context,
              pa.product_attribute,
              pa.product_attr_value)
              PRODUCT_ATTRIBUTE_VALUE,
           lh.START_DATE_ACTIVE START_DATE_ACTIVE,
           lh.END_DATE_ACTIVE END_DATE_ACTIVE,
           tl.NAME NAME,
           lh.ACTIVE_FLAG ACTIVE_FLAG,
           ll.START_DATE_ACTIVE START_DATE_ACTIVE_1,
           ll.END_DATE_ACTIVE END_DATE_ACTIVE_1
      FROM qp_pricing_attributes pa,
           qp_list_headers_b lh,
           qp_list_headers_tl tl,
           qp_list_lines ll
     WHERE     pa.excluder_flag = 'N'
           AND lh.list_header_id = tl.list_header_id
           AND tl.language = USERENV ('lang')
           AND lh.list_type_code IN ('PRL', 'AGR')
           AND ll.list_line_type_code = 'PLL'
           AND NOT EXISTS
                  (SELECT 'x'
                     FROM qp_rltd_modifiers rltd
                    WHERE ll.list_line_id = rltd.to_rltd_modifier_id));


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_M2C_PRICE_LIST FOR APPS.XX_BI_M2C_PRICE_LIST;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_M2C_PRICE_LIST FOR APPS.XX_BI_M2C_PRICE_LIST;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_M2C_PRICE_LIST FOR APPS.XX_BI_M2C_PRICE_LIST;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_M2C_PRICE_LIST FOR APPS.XX_BI_M2C_PRICE_LIST;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_M2C_PRICE_LIST TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_M2C_PRICE_LIST TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_M2C_PRICE_LIST TO XXINTG;
