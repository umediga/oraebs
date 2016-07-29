DROP VIEW APPS.XXINTG_ITEM_ORDERABILITY_V;

/* Formatted on 6/6/2016 5:00:19 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_ITEM_ORDERABILITY_V
(
   CUSTOM_ORD_ID,
   INV_ORG_ID,
   INV_ORG_NAME,
   SEQUENCE,
   ITEM_LEVEL,
   ITEM_LEVEL_NM,
   CAT_SEG1,
   CAT_SEG2,
   CAT_SEG3,
   CAT_SEG4,
   CAT_SEG5,
   CAT_SEG6,
   CONCAT_SEGS,
   INVENTORY_ITEM_ID,
   ITEM_NO,
   DESCRIPTION,
   RULE_LEVEL,
   RULE_LEVEL_DESC,
   RULE_LEVEL_VALUE,
   CUSTOMER_ID,
   CUSTOMER_CLASS_ID,
   END_CUSTOMER_ID,
   CUSTOMER_CATEGORY_CODE,
   CUSTOMER_CLASS_CODE,
   ORDER_TYPE_ID,
   SALES_CHANNEL_CODE,
   SALES_PERSON_ID,
   SHIP_TO_LOCATION_ID,
   BILL_TO_LOCATION_ID,
   DELIVER_TO_LOCATION_ID,
   REGION_ID,
   START_DATE,
   END_DATE,
   RESTRICTION_CODE,
   RESTRICTION_DESC,
   REG_NUMBER,
   NOTE,
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
   CREATED_BY,
   CREATION_DATE,
   LAST_UPDATED_BY,
   LAST_UPDATE_DATE
)
AS
   SELECT a.CUSTOM_ORD_ID,
          a.INV_ORG_ID,
          (SELECT organization_code
             FROM ORG_ORGANIZATION_DEFINITIONS
            WHERE organization_id = a.INV_ORG_ID)
             INV_ORG_NAME,
          a.SEQUENCE,
          a.ITEM_LEVEL,
          DECODE (a.ITEM_LEVEL,  'I', 'Item',  'C', 'Category',  NULL)
             ITEM_LEVEL_NM,
          a.CAT_SEG1,
          a.CAT_SEG2,
          a.CAT_SEG3,
          a.CAT_SEG4,
          a.CAT_SEG5,
          a.CAT_SEG6,
             a.CAT_SEG1
          || '.'
          || a.CAT_SEG2
          || '.'
          || a.CAT_SEG3
          || '.'
          || a.CAT_SEG4
          || '.'
          || a.CAT_SEG5
             CONCAT_SEGS,
          a.INVENTORY_ITEM_ID,
          XXINTG_CUSTOM_IORD.XXINTG_IOR_ITEM_SEG1 (a.INVENTORY_ITEM_ID)
             ITEM_NO,
          XXINTG_CUSTOM_IORD.XXINTG_IOR_ITEM_DESC (a.INVENTORY_ITEM_ID)
             DESCRIPTION,
          a.RULE_LEVEL,
          XXINTG_CUSTOM_IORD.XXINTG_IOR_VALUE_SET ('XXINTG_ITEM_RULE_VSET',
                                                   a.RULE_LEVEL)
             RULE_LEVEL_DESC,
          CASE
             WHEN a.RULE_LEVEL = 'CUSTOMER'
             THEN
                XXINTG_CUSTOM_IORD.XXINTG_IOR_RULEVALUE (a.RULE_LEVEL,
                                                         a.CUSTOMER_ID)
             WHEN a.RULE_LEVEL = 'END_CUST'
             THEN
                XXINTG_CUSTOM_IORD.XXINTG_IOR_RULEVALUE (a.RULE_LEVEL,
                                                         a.END_CUSTOMER_ID)
             WHEN a.RULE_LEVEL = 'CUST_CLASS'
             THEN
                XXINTG_CUSTOM_IORD.XXINTG_IOR_RULEVALUE (a.RULE_LEVEL,
                                                         a.CUSTOMER_CLASS_ID)
             WHEN a.RULE_LEVEL = 'CUST_CATEGORY'
             THEN
                XXINTG_CUSTOM_IORD.XXINTG_IOR_RULEVALUE (
                   a.RULE_LEVEL,
                   a.CUSTOMER_CATEGORY_CODE)
             WHEN a.RULE_LEVEL = 'CUST_CLASSIF'
             THEN
                XXINTG_CUSTOM_IORD.XXINTG_IOR_RULEVALUE (
                   a.RULE_LEVEL,
                   a.CUSTOMER_CLASS_CODE)
             WHEN a.RULE_LEVEL = 'REGIONS'
             THEN
                XXINTG_CUSTOM_IORD.XXINTG_IOR_RULEVALUE (a.RULE_LEVEL,
                                                         a.REGION_ID)
             WHEN a.RULE_LEVEL = 'ORDER_TYPE'
             THEN
                XXINTG_CUSTOM_IORD.XXINTG_IOR_RULEVALUE (a.RULE_LEVEL,
                                                         a.ORDER_TYPE_ID)
             WHEN a.RULE_LEVEL = 'SALES_CHANNEL'
             THEN
                XXINTG_CUSTOM_IORD.XXINTG_IOR_RULEVALUE (
                   a.RULE_LEVEL,
                   a.SALES_CHANNEL_CODE)
             WHEN a.RULE_LEVEL = 'SALES_REP'
             THEN
                XXINTG_CUSTOM_IORD.XXINTG_IOR_RULEVALUE (a.RULE_LEVEL,
                                                         a.SALES_PERSON_ID)
             WHEN a.RULE_LEVEL = 'SHIP_TO_LOC'
             THEN
                XXINTG_CUSTOM_IORD.XXINTG_IOR_RULEVALUE (
                   a.RULE_LEVEL,
                   a.SHIP_TO_LOCATION_ID)
             WHEN a.RULE_LEVEL = 'BILL_TO_LOC'
             THEN
                XXINTG_CUSTOM_IORD.XXINTG_IOR_RULEVALUE (
                   a.RULE_LEVEL,
                   a.BILL_TO_LOCATION_ID)
             WHEN a.RULE_LEVEL = 'DELIVER_TO_LOC'
             THEN
                XXINTG_CUSTOM_IORD.XXINTG_IOR_RULEVALUE (
                   a.RULE_LEVEL,
                   a.DELIVER_TO_LOCATION_ID)
          END
             RULE_LEVEL_VALUE,
          a.CUSTOMER_ID,
          a.CUSTOMER_CLASS_ID,
          a.END_CUSTOMER_ID,
          a.CUSTOMER_CATEGORY_CODE,
          a.CUSTOMER_CLASS_CODE,
          a.ORDER_TYPE_ID,
          a.SALES_CHANNEL_CODE,
          a.SALES_PERSON_ID,
          a.SHIP_TO_LOCATION_ID,
          a.BILL_TO_LOCATION_ID,
          a.DELIVER_TO_LOCATION_ID,
          a.REGION_ID,
          a.START_DATE,
          a.END_DATE,
          a.RESTRICTION_CODE,
          XXINTG_CUSTOM_IORD.XXINTG_IOR_VALUE_SET (
             'XXINTG_ITEM_RESTRICTION_VSET',
             a.RESTRICTION_CODE)
             RESTRICTION_DESC,
          a.REG_NUMBER,
          a.NOTE,
          a.ATTRIBUTE_CATEGORY,
          a.ATTRIBUTE1,
          a.ATTRIBUTE2,
          a.ATTRIBUTE3,
          a.ATTRIBUTE4,
          a.ATTRIBUTE5,
          a.ATTRIBUTE6,
          a.ATTRIBUTE7,
          a.ATTRIBUTE8,
          a.ATTRIBUTE9,
          a.ATTRIBUTE10,
          a.CREATED_BY,
          a.CREATION_DATE,
          a.LAST_UPDATED_BY,
          a.LAST_UPDATE_DATE
     FROM XXINTG_ITEM_ORDERABILITY a;
