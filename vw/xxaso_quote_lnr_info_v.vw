DROP VIEW APPS.XXASO_QUOTE_LNR_INFO_V;

/* Formatted on 6/6/2016 5:00:29 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXASO_QUOTE_LNR_INFO_V
(
   QUOTE_LINE_ID,
   QUOTE_HEADER_ID,
   LAST_UPDATE_DATE,
   REQUEST_ID,
   PROGRAM_APPLICATION_ID,
   PROGRAM_ID,
   PROGRAM_UPDATE_DATE,
   ORG_ID,
   LINE_CATEGORY_CODE,
   ITEM_TYPE_CODE,
   LINE_NUMBER_SORT,
   LINE_NUMBER,
   START_DATE_ACTIVE,
   END_DATE_ACTIVE,
   ORDER_LINE_TYPE_ID,
   INVOICE_TO_PARTY_SITE_ID,
   INVOICE_TO_PARTY_ID,
   ORGANIZATION_ID,
   INVENTORY_ITEM_ID,
   QUANTITY,
   UOM_CODE,
   MARKETING_SOURCE_CODE_ID,
   PRICE_LIST_ID,
   PRICE_LIST_LINE_ID,
   CURRENCY_CODE,
   LINE_LIST_PRICE,
   LINE_ADJUSTED_AMOUNT,
   LINE_ADJUSTED_PERCENT,
   LINE_QUOTE_PRICE,
   RELATED_ITEM_ID,
   ITEM_RELATIONSHIP_TYPE,
   ACCOUNTING_RULE_ID,
   INVOICING_RULE_ID,
   SPLIT_SHIPMENT_FLAG,
   BACKORDER_FLAG,
   ATTRIBUTE_CATEGORY,
   ATTRIBUTE1,
   ATTRIBUTE2,
   ATTRIBUTE3,
   ATTRIBUTE4,
   ATTRIBUTE5,
   ATTRIBUTE6,
   ATTRIBUTE7,
   ATTRIBUTE8,
   ATTRIBUTE9,
   ATTRIBUTE10,
   ATTRIBUTE11,
   ATTRIBUTE12,
   ATTRIBUTE13,
   ATTRIBUTE14,
   ATTRIBUTE15,
   SECURITY_GROUP_ID,
   OBJECT_VERSION_NUMBER,
   INVOICE_TO_CUST_ACCOUNT_ID,
   MINISITE_ID,
   SECTION_ID,
   PRICED_PRICE_LIST_ID,
   AGREEMENT_ID,
   COMMITMENT_ID,
   DISPLAY_ARITHMETIC_OPERATOR,
   LINE_TYPE_SOURCE_FLAG,
   SERVICE_ITEM_FLAG,
   SERVICEABLE_PRODUCT_FLAG,
   INVOICE_TO_CUST_PARTY_ID,
   SELLING_PRICE_CHANGE,
   RECALCULATE_FLAG,
   PRICING_LINE_TYPE_INDICATOR,
   END_CUSTOMER_PARTY_ID,
   END_CUSTOMER_PARTY_SITE_ID,
   END_CUSTOMER_CUST_PARTY_ID,
   END_CUSTOMER_CUST_ACCOUNT_ID,
   ATTRIBUTE16,
   ATTRIBUTE17,
   ATTRIBUTE18,
   ATTRIBUTE19,
   ATTRIBUTE20,
   SHIP_MODEL_COMPLETE_FLAG,
   CHARGE_PERIODICITY_CODE,
   QUOTE_LINE_DETAIL_ID,
   REQUEST_ID1,
   PROGRAM_APPLICATION_ID1,
   PROGRAM_ID1,
   PROGRAM_UPDATE_DATE1,
   QUOTE_LINE_ID1,
   CONFIG_HEADER_ID,
   CONFIG_REVISION_NUM,
   CONFIG_ITEM_ID,
   COMPLETE_CONFIGURATION_FLAG,
   VALID_CONFIGURATION_FLAG,
   COMPONENT_CODE,
   SERVICE_COTERMINATE_FLAG,
   SERVICE_DURATION,
   SERVICE_PERIOD,
   SERVICE_REF_TYPE_CODE,
   SERVICE_REF_ORDER_NUMBER,
   SERVICE_REF_LINE_NUMBER,
   SERVICE_REF_LINE_ID,
   SERVICE_REF_SYSTEM_ID,
   SECURITY_GROUP_ID1,
   OBJECT_VERSION_NUMBER1,
   REF_TYPE_CODE,
   REF_LINE_ID,
   INSTANCE_ID,
   BOM_SORT_ORDER,
   CONFIG_DELTA,
   CONFIG_INSTANCE_NAME,
   TOP_MODEL_LINE_ID,
   ATO_LINE_ID,
   COMPONENT_SEQUENCE_ID,
   INVENTORY_ITEM,
   ITEM_DESCRIPTION,
   INVENTORY_ITEM_TYPE,
   LONG_DESCRIPTION,
   SHIP_QUOTE_PRICE,
   EXTENDED_ADJUSTED_AMOUNT,
   EXTENDED_LIST_PRICE,
   EXTENDED_SELLING_PRICE,
   QUANTITY_SWITCHER,
   DESCRIPTION_SWITCHER,
   PRICE_SWITCHER,
   ICON_SWITCHER,
   PRC_ADJ_SWITCHER,
   UOM_SWITCHER,
   ROLLUP_PRICE,
   LINE_TOTAL_PRICE,
   LINE_DISCOUNT_FLAG,
   PERIODICITY,
   LINE_PAYNOW_SUBTOTAL,
   LINE_PAYNOW_TAX,
   LINE_PAYNOW_CHARGES,
   UI_LINE_NUMBER,
   UNIT_OF_MEASURE,
   LINE_TYPE_SWITCHER,
   LINE_ADJ_AMT_SWITCHER,
   LINE_CATEGORY,
   LINE_DISCOUNT,
   LINE_TYPE,
   IS_CONTAINER,
   LINE_DET_IMAGE_SWITCHER,
   QUOTE_LINE_DISCRIMINATOR,
   DUE_WITH_ORDER,
   CONFIG_MODEL_TYPE
)
AS
   SELECT "QUOTE_LINE_ID",
          "QUOTE_HEADER_ID",
          "LAST_UPDATE_DATE",
          "REQUEST_ID",
          "PROGRAM_APPLICATION_ID",
          "PROGRAM_ID",
          "PROGRAM_UPDATE_DATE",
          "ORG_ID",
          "LINE_CATEGORY_CODE",
          "ITEM_TYPE_CODE",
          "LINE_NUMBER_SORT",
          "LINE_NUMBER",
          "START_DATE_ACTIVE",
          "END_DATE_ACTIVE",
          "ORDER_LINE_TYPE_ID",
          "INVOICE_TO_PARTY_SITE_ID",
          "INVOICE_TO_PARTY_ID",
          "ORGANIZATION_ID",
          "INVENTORY_ITEM_ID",
          "QUANTITY",
          "UOM_CODE",
          "MARKETING_SOURCE_CODE_ID",
          "PRICE_LIST_ID",
          "PRICE_LIST_LINE_ID",
          "CURRENCY_CODE",
          "LINE_LIST_PRICE",
          "LINE_ADJUSTED_AMOUNT",
          "LINE_ADJUSTED_PERCENT",
          "LINE_QUOTE_PRICE",
          "RELATED_ITEM_ID",
          "ITEM_RELATIONSHIP_TYPE",
          "ACCOUNTING_RULE_ID",
          "INVOICING_RULE_ID",
          "SPLIT_SHIPMENT_FLAG",
          "BACKORDER_FLAG",
          "ATTRIBUTE_CATEGORY",
          "ATTRIBUTE1",
          "ATTRIBUTE2",
          "ATTRIBUTE3",
          "ATTRIBUTE4",
          "ATTRIBUTE5",
          "ATTRIBUTE6",
          "ATTRIBUTE7",
          "ATTRIBUTE8",
          "ATTRIBUTE9",
          "ATTRIBUTE10",
          "ATTRIBUTE11",
          "ATTRIBUTE12",
          "ATTRIBUTE13",
          "ATTRIBUTE14",
          "ATTRIBUTE15",
          "SECURITY_GROUP_ID",
          "OBJECT_VERSION_NUMBER",
          "INVOICE_TO_CUST_ACCOUNT_ID",
          "MINISITE_ID",
          "SECTION_ID",
          "PRICED_PRICE_LIST_ID",
          "AGREEMENT_ID",
          "COMMITMENT_ID",
          "DISPLAY_ARITHMETIC_OPERATOR",
          "LINE_TYPE_SOURCE_FLAG",
          "SERVICE_ITEM_FLAG",
          "SERVICEABLE_PRODUCT_FLAG",
          "INVOICE_TO_CUST_PARTY_ID",
          "SELLING_PRICE_CHANGE",
          "RECALCULATE_FLAG",
          "PRICING_LINE_TYPE_INDICATOR",
          "END_CUSTOMER_PARTY_ID",
          "END_CUSTOMER_PARTY_SITE_ID",
          "END_CUSTOMER_CUST_PARTY_ID",
          "END_CUSTOMER_CUST_ACCOUNT_ID",
          "ATTRIBUTE16",
          "ATTRIBUTE17",
          "ATTRIBUTE18",
          "ATTRIBUTE19",
          "ATTRIBUTE20",
          "SHIP_MODEL_COMPLETE_FLAG",
          "CHARGE_PERIODICITY_CODE",
          "QUOTE_LINE_DETAIL_ID",
          "REQUEST_ID1",
          "PROGRAM_APPLICATION_ID1",
          "PROGRAM_ID1",
          "PROGRAM_UPDATE_DATE1",
          "QUOTE_LINE_ID1",
          "CONFIG_HEADER_ID",
          "CONFIG_REVISION_NUM",
          "CONFIG_ITEM_ID",
          "COMPLETE_CONFIGURATION_FLAG",
          "VALID_CONFIGURATION_FLAG",
          "COMPONENT_CODE",
          "SERVICE_COTERMINATE_FLAG",
          "SERVICE_DURATION",
          "SERVICE_PERIOD",
          "SERVICE_REF_TYPE_CODE",
          "SERVICE_REF_ORDER_NUMBER",
          "SERVICE_REF_LINE_NUMBER",
          "SERVICE_REF_LINE_ID",
          "SERVICE_REF_SYSTEM_ID",
          "SECURITY_GROUP_ID1",
          "OBJECT_VERSION_NUMBER1",
          "REF_TYPE_CODE",
          "REF_LINE_ID",
          "INSTANCE_ID",
          "BOM_SORT_ORDER",
          "CONFIG_DELTA",
          "CONFIG_INSTANCE_NAME",
          "TOP_MODEL_LINE_ID",
          "ATO_LINE_ID",
          "COMPONENT_SEQUENCE_ID",
          "INVENTORY_ITEM",
          "ITEM_DESCRIPTION",
          "INVENTORY_ITEM_TYPE",
          "LONG_DESCRIPTION",
          "SHIP_QUOTE_PRICE",
          "EXTENDED_ADJUSTED_AMOUNT",
          "EXTENDED_LIST_PRICE",
          "EXTENDED_SELLING_PRICE",
          "QUANTITY_SWITCHER",
          "DESCRIPTION_SWITCHER",
          "PRICE_SWITCHER",
          "ICON_SWITCHER",
          "PRC_ADJ_SWITCHER",
          "UOM_SWITCHER",
          "ROLLUP_PRICE",
          "LINE_TOTAL_PRICE",
          "LINE_DISCOUNT_FLAG",
          "PERIODICITY",
          "LINE_PAYNOW_SUBTOTAL",
          "LINE_PAYNOW_TAX",
          "LINE_PAYNOW_CHARGES",
          "UI_LINE_NUMBER",
          "UNIT_OF_MEASURE",
          "LINE_TYPE_SWITCHER",
          "LINE_ADJ_AMT_SWITCHER",
          "LINE_CATEGORY",
          "LINE_DISCOUNT",
          "LINE_TYPE",
          "IS_CONTAINER",
          "LINE_DET_IMAGE_SWITCHER",
          "QUOTE_LINE_DISCRIMINATOR",
          "DUE_WITH_ORDER",
          "CONFIG_MODEL_TYPE"
     FROM (SELECT quotelineeo.quote_line_id,
                  quotelineeo.quote_header_id,
                  quotelineeo.last_update_date,
                  quotelineeo.request_id,
                  quotelineeo.program_application_id,
                  quotelineeo.program_id,
                  quotelineeo.program_update_date,
                  quotelineeo.org_id,
                  quotelineeo.line_category_code,
                  quotelineeo.item_type_code,
                  quotelineeo.line_number line_number_sort,
                  (SELECT (quotelineeo.line_number / 10000) || '.0'
                     FROM DUAL)
                     line_number,
                  quotelineeo.start_date_active,
                  quotelineeo.end_date_active,
                  quotelineeo.order_line_type_id,
                  quotelineeo.invoice_to_party_site_id,
                  quotelineeo.invoice_to_party_id,
                  quotelineeo.organization_id,
                  quotelineeo.inventory_item_id,
                  quotelineeo.quantity,
                  quotelineeo.uom_code,
                  quotelineeo.marketing_source_code_id,
                  quotelineeo.price_list_id,
                  quotelineeo.price_list_line_id,
                  quotelineeo.currency_code,
                  quotelineeo.line_list_price,
                  quotelineeo.line_adjusted_amount,
                  quotelineeo.line_adjusted_percent,
                  quotelineeo.line_quote_price,
                  quotelineeo.related_item_id,
                  quotelineeo.item_relationship_type,
                  quotelineeo.accounting_rule_id,
                  quotelineeo.invoicing_rule_id,
                  quotelineeo.split_shipment_flag,
                  quotelineeo.backorder_flag,
                  quotelineeo.attribute_category,
                  quotelineeo.attribute1,
                  quotelineeo.attribute2,
                  quotelineeo.attribute3,
                  quotelineeo.attribute4,
                  quotelineeo.attribute5,
                  quotelineeo.attribute6,
                  quotelineeo.attribute7,
                  quotelineeo.attribute8,
                  quotelineeo.attribute9,
                  quotelineeo.attribute10,
                  quotelineeo.attribute11,
                  quotelineeo.attribute12,
                  quotelineeo.attribute13,
                  quotelineeo.attribute14,
                  quotelineeo.attribute15,
                  quotelineeo.security_group_id,
                  quotelineeo.object_version_number,
                  quotelineeo.invoice_to_cust_account_id,
                  quotelineeo.minisite_id,
                  quotelineeo.section_id,
                  quotelineeo.priced_price_list_id,
                  quotelineeo.agreement_id,
                  quotelineeo.commitment_id,
                  quotelineeo.display_arithmetic_operator,
                  quotelineeo.line_type_source_flag,
                  quotelineeo.service_item_flag,
                  quotelineeo.serviceable_product_flag,
                  quotelineeo.invoice_to_cust_party_id,
                  quotelineeo.selling_price_change,
                  quotelineeo.recalculate_flag,
                  quotelineeo.pricing_line_type_indicator,
                  quotelineeo.end_customer_party_id,
                  quotelineeo.end_customer_party_site_id,
                  quotelineeo.end_customer_cust_party_id,
                  quotelineeo.end_customer_cust_account_id,
                  quotelineeo.attribute16,
                  quotelineeo.attribute17,
                  quotelineeo.attribute18,
                  quotelineeo.attribute19,
                  quotelineeo.attribute20,
                  quotelineeo.ship_model_complete_flag,
                  quotelineeo.charge_periodicity_code,
                  qte_line_det.quote_line_detail_id,
                  qte_line_det.request_id AS request_id1,
                  qte_line_det.program_application_id
                     AS program_application_id1,
                  qte_line_det.program_id AS program_id1,
                  qte_line_det.program_update_date AS program_update_date1,
                  qte_line_det.quote_line_id AS quote_line_id1,
                  qte_line_det.config_header_id,
                  qte_line_det.config_revision_num,
                  qte_line_det.config_item_id,
                  qte_line_det.complete_configuration_flag,
                  qte_line_det.valid_configuration_flag,
                  qte_line_det.component_code,
                  qte_line_det.service_coterminate_flag,
                  qte_line_det.service_duration,
                  qte_line_det.service_period,
                  qte_line_det.service_ref_type_code,
                  qte_line_det.service_ref_order_number,
                  qte_line_det.service_ref_line_number,
                  qte_line_det.service_ref_line_id,
                  qte_line_det.service_ref_system_id,
                  qte_line_det.security_group_id AS security_group_id1,
                  qte_line_det.object_version_number
                     AS object_version_number1,
                  qte_line_det.ref_type_code,
                  qte_line_det.ref_line_id,
                  qte_line_det.instance_id,
                  qte_line_det.bom_sort_order,
                  qte_line_det.config_delta,
                  qte_line_det.config_instance_name,
                  qte_line_det.top_model_line_id,
                  qte_line_det.ato_line_id,
                  qte_line_det.component_sequence_id,
                  items.concatenated_segments inventory_item,
                  items.description item_description,
                  items.item_type inventory_item_type,
                  items.long_description long_description,
                  ship.ship_quote_price,
                  (quotelineeo.line_adjusted_amount * quotelineeo.quantity)
                     extended_adjusted_amount,
                  (quotelineeo.line_list_price * quotelineeo.quantity)
                     extended_list_price,
                  (quotelineeo.line_quote_price * quotelineeo.quantity)
                     extended_selling_price,
                  '' quantity_switcher,
                  (CASE
                      WHEN (    quotelineeo.item_type_code = 'MDL'
                            AND qte_line_det.complete_configuration_flag
                                   IS NOT NULL
                            AND NVL (items.config_model_type, 'XX') <> 'N')
                      THEN
                         'TOTAL'
                      ELSE
                         'NOTOTAL'
                   END)
                     description_switcher,
                  '' price_switcher,
                  '' icon_switcher,
                  '' prc_adj_switcher,
                  '' uom_switcher,
                  (CASE
                      WHEN (    quotelineeo.item_type_code = 'MDL'
                            AND qte_line_det.complete_configuration_flag
                                   IS NOT NULL
                            AND NVL (items.config_model_type, 'XX') <> 'N')
                      THEN
                         aso_quote_pub_w.get_model_rollup_quote_price (
                            quotelineeo.quote_line_id)
                      ELSE
                         0
                   END)
                     rollup_price,
                  (quotelineeo.quantity * quotelineeo.line_quote_price)
                     line_total_price,
                  DECODE (NVL (quotelineeo.line_list_price, 0), 0, 'A', 'P')
                     line_discount_flag,
                  mc.unit_of_measure periodicity,
                  quotelineeo.line_paynow_subtotal,
                  quotelineeo.line_paynow_tax,
                  quotelineeo.line_paynow_charges,
                  aso_line_num_int.get_ui_line_number (
                     quotelineeo.quote_line_id)
                     ui_line_number,
                  muv.unit_of_measure,
                  '' line_type_switcher,
                  '' line_adj_amt_switcher,
                  cat_lok.meaning line_category,
                  0 line_discount,
                  ottt.NAME line_type,
                  DECODE (
                     quotelineeo.item_type_code,
                     'MDL', DECODE (items.config_model_type, 'N', 'Y', 'N'),
                     'N')
                     is_container,
                  'LN_DET_IMAGE' line_det_image_switcher,
                  quotelineeo.quote_line_discriminator,
                    NVL (quotelineeo.line_paynow_subtotal, 0)
                  + NVL (quotelineeo.line_paynow_charges, 0)
                  + NVL (quotelineeo.line_paynow_tax, 0)
                     due_with_order,
                  quotelineeo.config_model_type
             FROM aso_oa_quote_lines_all_v quotelineeo,
                  aso_quote_line_details qte_line_det,
                  mtl_system_items_vl items,
                  aso_shipments ship,
                  mtl_units_of_measure_vl mc,
                  mtl_units_of_measure_vl muv,
                  oe_transaction_types_tl ottt,
                  fnd_lookup_values cat_lok
            WHERE     quotelineeo.quote_line_id =
                         qte_line_det.quote_line_id(+)
                  AND quotelineeo.inventory_item_id = items.inventory_item_id
                  AND quotelineeo.organization_id = items.organization_id
                  AND quotelineeo.quote_header_id = ship.quote_header_id
                  AND quotelineeo.quote_line_id = ship.quote_line_id
                  AND quotelineeo.charge_periodicity_code = mc.uom_code(+)
                  AND mc.uom_class(+) =
                         fnd_profile.VALUE (
                            'ONT_UOM_CLASS_CHARGE_PERIODICITY')
                  AND quotelineeo.line_category_code = cat_lok.lookup_code(+)
                  AND cat_lok.lookup_type(+) = 'LINE_CATEGORY'
                  AND cat_lok.LANGUAGE(+) = USERENV ('LANG')
                  AND quotelineeo.uom_code = muv.uom_code
                  AND quotelineeo.order_line_type_id =
                         ottt.transaction_type_id(+)
                  AND ottt.LANGUAGE(+) = USERENV ('LANG'));
