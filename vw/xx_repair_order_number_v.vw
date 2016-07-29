DROP VIEW APPS.XX_REPAIR_ORDER_NUMBER_V;

/* Formatted on 6/6/2016 4:58:14 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_REPAIR_ORDER_NUMBER_V
(
   ORDER_NUMBER
)
AS
     SELECT DISTINCT ooh.order_number
       FROM oe_order_headers_all ooh,
            oe_order_lines_all ool,
            oe_transaction_types_tl ott,
            FND_ATTACHED_DOCUMENTS ad,
            FND_DOCUMENTS_VL d
      WHERE     ooh.header_id = ool.header_id
            AND ool.line_type_id = ott.transaction_type_id
            AND ott.language = 'US'
            AND (ott.name LIKE '%Bill Only%' OR ott.name LIKE '%Standard Ship%')
            AND d.document_id = ad.document_id
            AND UPPER (d.category_description) = 'CUSTOM REPORT NOTE' --'Repair Note' -- Changed for DCR during SIT
            AND ad.entity_name = 'OE_ORDER_HEADERS'
            AND ad.pk1_value = ooh.header_id
   ORDER BY 1;


GRANT SELECT ON APPS.XX_REPAIR_ORDER_NUMBER_V TO XXAPPSREAD;
