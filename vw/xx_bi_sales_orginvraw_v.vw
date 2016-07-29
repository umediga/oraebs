DROP VIEW APPS.XX_BI_SALES_ORGINVRAW_V;

/* Formatted on 6/6/2016 4:58:57 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_SALES_ORGINVRAW_V
(
   ORGANIZATION_CODE,
   PROCESS_ITEM_NUMBER,
   SUM,
   SUBINVENTORY_NAME,
   DIVISION
)
AS
     SELECT ood.organization_code "Organization Code",
            msib.segment1 "Process Item Number",
            SUM (moq.transaction_quantity) "SUM",
            moq.subinventory_code "Subinventory Name",
            (SELECT mcb.segment4
               FROM mtl_item_categories mic,
                    mtl_category_sets_tl mcst,
                    mtl_category_sets_b mcsb,
                    mtl_categories_b mcb
              WHERE     mcst.category_set_id = mcsb.category_set_id
                    AND mcst.language = USERENV ('LANG')
                    AND mic.category_set_id = mcsb.category_set_id
                    AND mic.category_id = mcb.category_id
                    AND mcst.category_set_name = 'Sales and Marketing'
                    AND mic.inventory_item_id = msib.inventory_item_id
                    AND mic.organization_id = msib.organization_id)
               DIVISION
       FROM apps.org_organization_definitions ood,
            apps.mtl_system_items_b msib,
            apps.mtl_onhand_quantities_detail moq
      WHERE     msib.organization_id = ood.organization_id
            AND msib.inventory_item_id = moq.inventory_item_id
            AND msib.organization_id = moq.owning_organization_id
   GROUP BY ood.organization_code,
            msib.segment1,
            moq.transaction_quantity,
            moq.subinventory_code,
            msib.inventory_item_id,
            msib.organization_id;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_SALES_ORGINVRAW_V FOR APPS.XX_BI_SALES_ORGINVRAW_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_SALES_ORGINVRAW_V FOR APPS.XX_BI_SALES_ORGINVRAW_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_SALES_ORGINVRAW_V FOR APPS.XX_BI_SALES_ORGINVRAW_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_SALES_ORGINVRAW_V FOR APPS.XX_BI_SALES_ORGINVRAW_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_ORGINVRAW_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_ORGINVRAW_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_ORGINVRAW_V TO XXINTG;
