DROP VIEW APPS.XX_PL_SFDC_DETAIL_V;

/* Formatted on 6/6/2016 4:58:15 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_PL_SFDC_DETAIL_V
(
   PL_PRIMARY,
   PL_HEADER_ID,
   PL_OUNAME,
   PL_SEC_NAME,
   PL_SEC_ID,
   ITEM,
   ITEM_ID,
   CURRENCY_CODE,
   UNIT_PRICE,
   UOM,
   START_DATE,
   END_DATE,
   ARITHMETIC_OPERATOR,
   LINE_ID,
   QPL_LAST_UPDATE_DATE,
   QPHP_LAST_UPDATE_DATE,
   QPS_LAST_UPDATE_DATE
)
AS
   SELECT                                                   -- Query for US OU
         qphp.Name AS PL_PRIMARY,
          qphp.list_header_id AS pl_header_id,
          hou.name AS PL_OUNAME,
          qps.name AS PL_SEC_NAME,
          qps.list_header_id AS PL_SEC_ID,
          mtl.segment1 AS ITEM,
          mtl.inventory_item_id AS ITEM_id,
          qps.currency_code AS CURRENCY_CODE,
          qpl.operand AS UNIT_PRICE,
          qpp.product_uom_code AS UOM,
          NVL (qpl.start_date_active, qps.start_date_active) AS START_DATE,
          DECODE (
             NVL (qphp.active_flag, 'Y'),
             'Y', NVL (qphp.end_date_active,
                       NVL (qps.end_date_active, qpl.end_date_active)),
             SYSDATE - 1)
             AS END_DATE,
          qpl.arithmetic_operator,
          qpl.list_line_id AS LINE_ID,
          qpl.last_update_date QPL_last_update_date,
          qphp.last_update_date QPHP_last_update_date,
          qps.last_update_date QPS_last_update_date
     FROM QP_list_headers qphp,
          hr_operating_units hou,
          qp_secondary_price_lists_v qps,
          apps.qp_list_lines qpl,
          apps.qp_pricing_attributes qpp,
          apps.mtl_system_items_b mtl,
          apps.FND_LOOKUP_VALUES flv
    WHERE     flv.lookup_type = 'XX_PL_TO_SFDC_INTEGRATION' -- Added for wave2
          AND UPPER (qphp.name) = flv.description           --'ILS LIST PRICE'
          AND flv.language = USERENV ('LANG')
          AND flv.enabled_flag = 'Y'
          AND SYSDATE BETWEEN flv.start_date_active
                          AND NVL (flv.end_date_active, SYSDATE + 1)
          AND qphp.orig_org_id = hou.organization_id
          AND hou.name = 'OU United States'
          AND qphp.currency_code = 'USD'
          --AND NVL(qphp.active_flag,'Y') = 'Y' -- Only Active Primary Price Lists
          --AND SYSDATE BETWEEN qphp.start_date_active AND NVL(qphp.end_date_active,SYSDATE+1)
          AND qps.parent_price_list_id = TO_CHAR (qphp.list_header_id)
          --AND qps.currency_code      = 'USD'
          AND qps.precedence =
                 (SELECT MIN (precedence)
                    FROM qp_secondary_price_lists_v qpsv
                   WHERE     parent_price_list_id =
                                TO_CHAR (qphp.list_header_id)
                         AND SYSDATE BETWEEN qpsv.start_date_active
                                         AND NVL (qpsv.end_date_active,
                                                  SYSDATE + 1)
                         AND qpsv.currency_code = 'USD')
          AND qps.start_date_active =
                 (SELECT MAX (qpsv1.start_date_active)
                    FROM qp_secondary_price_lists_v qpsv1
                   WHERE     qpsv1.parent_price_list_id =
                                TO_CHAR (qphp.list_header_id)
                         AND qpsv1.precedence = qps.precedence
                         AND qpsv1.currency_code = qps.currency_code
                         AND SYSDATE BETWEEN qpsv1.start_date_active
                                         AND NVL (qpsv1.end_date_active,
                                                  SYSDATE + 1))
          AND qps.list_header_id = qpl.list_header_id
          AND qps.list_header_id = qpp.list_header_id
          AND qpl.list_line_id = qpp.list_line_id
          AND mtl.inventory_item_id =
                 DECODE (
                    LENGTH (
                       TRIM (
                          TRANSLATE (qpp.product_attr_value,
                                     '0123456789',
                                     ' '))),
                    NULL, qpp.product_attr_value,
                    NULL)
          AND mtl.organization_id = (SELECT UNIQUE master_organization_id
                                       FROM mtl_parameters)
          AND mtl.item_type IN ('FG', 'RPR', 'TLIN') -- only finished Goods, Repair Items and tools instruments are sent by Item master interface
          AND qpp.product_attribute_context = 'ITEM'
   UNION
   SELECT                                   -- Query for non US OU from lookup
         qphp.Name AS PL_PRIMARY,
          qphp.list_header_id AS pl_header_id,
          hou.name AS PL_OUNAME,
          NULL AS PL_SEC_NAME,
          NULL AS PL_SEC_ID,
          mtl.segment1 AS ITEM,
          mtl.inventory_item_id AS ITEM_id,
          qphp.currency_code AS CURRENCY_CODE,
          qpl.operand AS UNIT_PRICE,
          qpp.product_uom_code AS UOM,
          NVL (qpl.start_date_active, qphp.start_date_active) AS START_DATE,
          DECODE (NVL (qphp.active_flag, 'Y'),
                  'Y', NVL (qphp.end_date_active, qpl.end_date_active),
                  SYSDATE - 1)
             AS END_DATE,
          qpl.arithmetic_operator,
          qpl.list_line_id AS LINE_ID,
          qpl.last_update_date QPL_last_update_date,
          qphp.last_update_date QPHP_last_update_date,
          NULL QPS_last_update_date
     FROM QP_list_headers qphp,
          hr_operating_units hou,
          --  qp_secondary_price_lists_v qps ,
          apps.qp_list_lines qpl,
          apps.qp_pricing_attributes qpp,
          apps.mtl_system_items_b mtl,
          apps.FND_LOOKUP_VALUES flv
    WHERE     flv.lookup_type = 'XX_PL_TO_SFDC_INTEGRATION'
          AND UPPER (qphp.name) = flv.description    --'ILS CANADA LIST PRICE'
          AND flv.language = USERENV ('LANG')
          AND flv.enabled_flag = 'Y'
          AND SYSDATE BETWEEN flv.start_date_active
                          AND NVL (flv.end_date_active, SYSDATE + 1)
          AND qphp.orig_org_id = hou.organization_id
          AND hou.name <> 'OU United States'
          AND qphp.currency_code <> 'USD'
          --AND NVL(qphp.active_flag,'Y') = 'Y' -- Only Active Primary Price Lists
          --AND SYSDATE BETWEEN qphp.start_date_active AND NVL(qphp.end_date_active,SYSDATE+1)
          AND qphp.list_header_id = qpl.list_header_id
          AND qphp.list_header_id = qpp.list_header_id
          AND qpl.list_line_id = qpp.list_line_id
          AND mtl.inventory_item_id =
                 DECODE (
                    LENGTH (
                       TRIM (
                          TRANSLATE (qpp.product_attr_value,
                                     '0123456789',
                                     ' '))),
                    NULL, qpp.product_attr_value,
                    NULL)
          AND mtl.organization_id = (SELECT UNIQUE master_organization_id
                                       FROM mtl_parameters)
          AND mtl.item_type IN ('FG', 'RPR', 'TLIN') -- only finished Goods, Repair Items and tools instruments are sent by Item master interface
          AND qpp.product_attribute_context = 'ITEM';


GRANT SELECT ON APPS.XX_PL_SFDC_DETAIL_V TO XXAPPSREAD;
