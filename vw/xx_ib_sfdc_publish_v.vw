DROP VIEW APPS.XX_IB_SFDC_PUBLISH_V;

/* Formatted on 6/6/2016 4:58:28 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_IB_SFDC_PUBLISH_V
(
   PUBLISH_BATCH_ID,
   CONTROL_RECORD_ID,
   ITEM,
   ITEM_DESC,
   SERIAL_NUMBER,
   LOT_NUMBER,
   SITE_NUMBER,
   SHIPPED_DATE,
   QUANTITY,
   SALES_ORDER_NUMBER,
   PURCHASE_ORDER_NUMBER,
   WARRANTY_NAME,
   CONTRACT_NUMBER,
   WARRANTY_STATUS,
   WARRANTY_START_DATE,
   WARRANTY_END_DATE,
   OWNERSHIP_TYPE,
   STATUS,
   MANUFACTURER,
   IB_INSTANCE_ID
)
AS
   SELECT publish_batch_id,
          control_record_id,
          item,
          item_desc,
          serial_number,
          lot_number,                            -- Added Lot Number for wave2
          site_number,
          shipped_date,
          quantity,
          sales_order_number,
          purchase_order_number,
          warranty_name,
          contract_number,
          warranty_status,
          warranty_start_date,
          warranty_end_date,
          xx_emf_pkg.get_paramater_value ('XXSFDCINSTBASE', 'OWNERSHIP_TYPE')
             ownership_type,
          xx_emf_pkg.get_paramater_value ('XXSFDCINSTBASE', 'STATUS') status,
          xx_emf_pkg.get_paramater_value ('XXSFDCINSTBASE', 'MANUFACTURER')
             manufacturer,
          ib_instance_id
     FROM xx_ib_sfdc_staging_tbl xxibbas;


GRANT SELECT ON APPS.XX_IB_SFDC_PUBLISH_V TO XXAPPSREAD;
