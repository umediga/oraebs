DROP VIEW APPS.XX_PRICE_LIST_SFDC_PUBLISH_V;

/* Formatted on 6/6/2016 4:58:14 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_PRICE_LIST_SFDC_PUBLISH_V
(
   PUBLISH_BATCH_ID,
   SOURCE_SYSTEM,
   TARGET_SYSTEM,
   PRICE_LIST_TBL
)
AS
   SELECT plc.PUBLISH_BATCH_ID publish_batch_id,
          plc.SOURCE_SYSTEM source_system,
          plc.TARGET_SYSTEM TARGET_SYSTEM,
          CAST (
             MULTISET (
                SELECT plst.RECORD_ID,
                       plst.CONTROL_RECORD_ID,
                       plst.PUBLISH_BATCH_ID,
                       plst.LIST_HEADER_ID,
                       plst.PRICE_LIST_NAME,
                       plst.PRICE_LIST_STATUS,
                       plst.USE_STANDARD_PRICE,
                       plst.PRICE_LIST_LINE_ID,
                       plst.ITEM_PRODUCT,
                       plst.CURRENCY_CODE,
                       plst.LIST_PRICE,
                       plst.START_DATE,
                       plst.END_DATE,
                       plst.creation_date,
                       plst.created_by,
                       plst.last_update_date,
                       plst.last_updated_by,
                       plst.last_update_login
                  FROM XX_PRICE_LIST_SFDC_STAGING plst,
                       XX_PRICE_LIST_SFDC_CONTROL plc1
                 WHERE     plst.CONTROL_RECORD_ID = plc1.record_id
                       AND plc1.PUBLISH_BATCH_ID = plst.PUBLISH_BATCH_ID
                       AND plc1.PUBLISH_BATCH_ID = plc.PUBLISH_BATCH_ID) AS XX_PL_SFDC_PUBLISH_TAB_TYP)
             PRICE_LIST_TBL
     FROM (SELECT DISTINCT PUBLISH_BATCH_ID, SOURCE_SYSTEM, TARGET_SYSTEM
             FROM XX_PRICE_LIST_SFDC_CONTROL) plc;
