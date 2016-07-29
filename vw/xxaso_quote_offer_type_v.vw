DROP VIEW APPS.XXASO_QUOTE_OFFER_TYPE_V;

/* Formatted on 6/6/2016 5:00:29 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXASO_QUOTE_OFFER_TYPE_V
(
   FLEX_VALUE
)
AS
   SELECT "FLEX_VALUE"
     FROM (SELECT a.flex_value
             FROM FND_FLEX_VALUES_VL a, FND_FLEX_VALUE_SETS b
            WHERE     a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_set_name IN
                         ('INTG_OFFER_TYPE_L_S_CNS', 'INTG_ONETIME_CONTRACT')
                  AND a.enabled_flag = 'Y');
