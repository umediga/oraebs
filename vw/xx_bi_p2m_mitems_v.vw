DROP VIEW APPS.XX_BI_P2M_MITEMS_V;

/* Formatted on 6/6/2016 4:59:10 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_P2M_MITEMS_V
(
   ORGANIZATION_CODE,
   ORGANIZATION_NAME,
   ITEM_NUMBER,
   DESCRIPTION,
   UOM,
   ITEM_TYPE,
   ITEM_STATUS,
   DATE_CREATED,
   SALES_N_MARKETING_CATEGORY,
   INVENTORY_ITEM_FLAG,
   STOCK_ENABLED_FLAG,
   TRANSACTABLE_FLAG,
   REVISION_CONTROL_FLAG,
   RESERVABLE_FLAG,
   CHECK_MATERIAL_SHORTAGE_FLAG,
   SHELF_LIFE_CONTROL,
   SHELF_LIFE_DAYS,
   CYCLE_COUNT_ENABLED_FLAG,
   LOT_CONTROL,
   SERIAL_NUMBER_CONTROL,
   LOCATOR_CONTROL,
   RESTRICT_SUBINVENTORIES,
   RESTRICT_LOCATORS,
   BOM_ALLOWED_FLAG,
   BOM_ITEM_TYPE,
   COSTING_ENABLED_FLAG,
   INVENTORY_ASSET_FLAG,
   INCLUDE_IN_ROLLUP_FLAG,
   COST_OF_GOODS_SOLD_ACCOUNT,
   PURCHASING_ITEM_FLAG,
   PURCHASING_ENABLED_FLAG,
   USE_APPROVED_SUPPLIER_FLAG,
   OUTSIDE_OPERATION_FLAG,
   OUTSIDE_OPERATION_UOM_TYPE,
   TAXABLE_FLAG,
   RECEIPT_REQUIRED_FLAG,
   RECEIPT_CLOSE_TOLERANCE,
   LIST_PRICE,
   PRICE_TOLERANCE,
   ITEM_COST,
   MATERIAL_COST,
   OVERHEAD_COST,
   EXPENSE_SOLD_ACCOUNT,
   DAYS_EARLY_RECEIPT_ALLOWED,
   DAYS_LATE_RECEIPT_ALLOWED,
   OVER_RCPT_QTY_TOLERANCE,
   RECEIPT_ROUTING,
   WEIGHT_UOM,
   UNIT_WEIGHT,
   VOLUME_UOM,
   UNIT_VOLUME,
   DIMENSION_UOM,
   UNIT_LENGTH,
   UNIT_WIDTH,
   UNIT_HEIGHT,
   INVENTORY_PLANNING_METHOD,
   MAKE_BUY,
   PLANNER,
   MINIMUM_QUANTITY,
   MAXIMUM_QUANTITY,
   MINIMUM_ORDER_QUANTITY,
   MAXIMUM_ORDER_QUANTITY,
   SAFETY_STOCK_METHOD,
   CONSIGNED_FLAG,
   ASN_AUTO_EXPIRE_FLAG,
   RELEASE_AUTHORIZATION_REQUIRED,
   FORECAST_TYPE,
   MRP_PLANNING_CODE,
   ATO_FORECAST_CONTROL,
   END_ASSEMBLY_PEGGING_FLAG,
   EXCLUDE_FROM_BUDGET_FLAG,
   CREATE_SUPPLY_FLAG,
   CRITICAL_COMPONENET_FLAG,
   PREPROCESSING_LEAD_TIME,
   PROCESSING_LEAD_TIME,
   POSTPROCESSING_LEAD_TIME,
   FIXED_LEAD_TIME,
   VARIABLE_LEAD_TIME,
   CUMULATIVE_MFG_LEAD_TIME,
   CUMULATIVE_TOTAL_LEAD_TIME,
   LEAD_TIME_LOT_SIZE,
   WIP_SUPPLY_TYPE,
   INTERNAL_ORDER_FLAG,
   PICK_COMPONENTS_FLAG,
   REPLENISH_TO_ORDER_FLAG,
   RETURNABLE_FLAG,
   CUSTOMER_ORDER_ENABLED_FLAG,
   CUSTOMER_ORDER_FLAG,
   SHIPPABLE_ITEM_FLAG,
   INTERNAL_ORDER_ENABLED_FLAG,
   SHIP_MODEL_COMPLETE_FLAG,
   ORDER_ENTRY_TRANSACTABLE_FLAG,
   LOT_STATUS_ENABLED_FLAG,
   SERIAL_STATUS_ENABLED_FLAG,
   LOT_SPLIT_ENABLED_FLAG,
   LOT_MERGE_ENABLED_FLAG,
   LOT_TRANSLATE_ENABLED_FLAG,
   LOT_SUBSTITUTION_ENABLED_FLAG,
   BULK_PICKED_FLAG,
   CHECK_ATP,
   ATP_RULE_ID,
   ATP_COMPONENTS,
   DEFAULT_SHIPPING_ORG,
   DEFAULT_SO_SOURCE_TYPE,
   OVER_SHIPMENT_TOLERANCE,
   UNDER_SHIPMENT_TOLERANCE,
   OVER_RETURN_TOLERANCE,
   UNDER_RETURN_TOLERANCE,
   INVOICEABLE_ITEM_FLAG,
   INVOICE_ENABLED_FLAG,
   SALES_ACCOUNT
)
AS
   SELECT OOD.ORGANIZATION_CODE,
          OOD.ORGANIZATION_NAME,
          MSIB.SEGMENT1 ITEM_NUMBER,
          MSIB.DESCRIPTION,
          MSIB.PRIMARY_UNIT_OF_MEASURE UOM,
          MSIB.ITEM_TYPE                                     --,item_type_desc
                        ,
          MSIB.INVENTORY_ITEM_STATUS_CODE ITEM_STATUS,
          MSIB.CREATION_DATE DATE_CREATED,
          (SELECT    MIC.INVENTORY_ITEM_ID
                  || '.'
                  || MIC.ORGANIZATION_ID
                  || '.'
                  || MCB.SEGMENT4
                  || '.'
                  || MCB.SEGMENT10
                  || '.'
                  || MCB.SEGMENT7
                  || '.'
                  || MCB.SEGMENT8
                  || '.'
                  || MCB.SEGMENT9
                  || '.'
                  || MCB.SEGMENT6
             FROM mtl_item_categories mic,
                  mtl_category_sets_tl mcst,
                  mtl_category_sets_b mcsb,
                  mtl_categories_b mcb
            WHERE     mcst.category_set_id = mcsb.category_set_id
                  AND mcst.language = USERENV ('LANG')
                  AND mic.category_set_id = mcsb.category_set_id
                  AND mic.category_id = mcb.category_id
                  AND MCST.CATEGORY_SET_NAME = 'Sales and Marketing'
                  AND MIC.INVENTORY_ITEM_ID = MSIB.INVENTORY_ITEM_ID
                  AND MIC.ORGANIZATION_ID = msib.organization_id)
             Sales_N_Marketing_Category                     --code_Description
                                                           --S_N_M_A_CODE_DESC
                                                           --S_N_M_B_CODE_DESC
                                                           --S_N_M_C_CODE_DESC
                                                           --S_N_M_D_CODE_DESC
                                                                 --OM_Category
                                                            --OM_Category_Desc
                                                                --Inv_Category
                                                         --Purchasing_Category
                                                                       --Brand
                                                           --Brand_Description
                                                                       --MAJOR
                                                           --MAJOR_Description
                                                                       --MINOR
                                                           --MINOR_DESCRIPTION
                                                                      --MARKET
                                                          --MARKET_DESCRIPTION
                                                                     --CE_MARK
                                                                --FDA APPROVAL
                                                                 --IC_UPCHARGE
                                                            --DR_Cert_Required
                                                        --Multi_Language_Label
                                                       --Shipping_Instructions
                                                              --Drawing_Number
                                                     --Drawing_Revision_Number
                                                   --Drop_Shipment_Eligibility
                                                                 --Ship_Method
                                                                 --Invoice_UOM
          ,
          MSIB.INVENTORY_ITEM_FLAG,
          MSIB.STOCK_ENABLED_FLAG,
          MSIB.MTL_TRANSACTIONS_ENABLED_FLAG TRANSACTABLE_FLAG,
          MSIB.REVISION_QTY_CONTROL_CODE REVISION_CONTROL_FLAG,
          MSIB.RESERVABLE_TYPE RESERVABLE_FLAG,
          MSIB.CHECK_SHORTAGES_FLAG CHECK_MATERIAL_SHORTAGE_FLAG,
          MSIB.SHELF_LIFE_CODE SHELF_LIFE_CONTROL,
          MSIB.SHELF_LIFE_DAYS,
          MSIB.CYCLE_COUNT_ENABLED_FLAG,
          MSIB.LOT_CONTROL_CODE LOT_CONTROL,
          MSIB.SERIAL_NUMBER_CONTROL_CODE SERIAL_NUMBER_CONTROL,
          MSIB.LOCATION_CONTROL_CODE LOCATOR_CONTROL,
          MSIB.RESTRICT_SUBINVENTORIES_CODE RESTRICT_SUBINVENTORIES,
          MSIB.RESTRICT_LOCATORS_CODE RESTRICT_LOCATORS,
          MSIB.BOM_ENABLED_FLAG BOM_ALLOWED_FLAG,
          MSIB.BOM_ITEM_TYPE BOM_ITEM_TYPE,
          MSIB.COSTING_ENABLED_FLAG,
          MSIB.INVENTORY_ASSET_FLAG,
          MSIB.DEFAULT_INCLUDE_IN_ROLLUP_FLAG INCLUDE_IN_ROLLUP_FLAG,
          MSIB.COST_OF_SALES_ACCOUNT COST_OF_GOODS_SOLD_ACCOUNT,
          MSIB.PURCHASING_ITEM_FLAG PURCHASING_ITEM_FLAG,
          MSIB.PURCHASING_ENABLED_FLAG,
          MSIB.MUST_USE_APPROVED_VENDOR_FLAG USE_APPROVED_SUPPLIER_FLAG,
          MSIB.OUTSIDE_OPERATION_FLAG,
          MSIB.OUTSIDE_OPERATION_UOM_TYPE,
          MSIB.TAXABLE_FLAG,
          MSIB.RECEIPT_REQUIRED_FLAG,
          MSIB.RECEIVE_CLOSE_TOLERANCE RECEIPT_CLOSE_TOLERANCE,
          MSIB.LIST_PRICE_PER_UNIT LIST_PRICE,
          MSIB.PRICE_TOLERANCE_PERCENT PRICE_TOLERANCE,
          CST.ITEM_COST ITEM_COST,
          CST.MATERIAL_COST MATERIAL_COST,
          cst.overhead_cost OVERHEAD_COST                     --Item_Cost_Type
                                         ,
          MSIB.EXPENSE_ACCOUNT EXPENSE_SOLD_ACCOUNT,
          MSIB.DAYS_EARLY_RECEIPT_ALLOWED,
          MSIB.DAYS_LATE_RECEIPT_ALLOWED,
          MSIB.qty_rcv_tolerance OVER_RCPT_QTY_TOLERANCE,
          MSIB.RECEIVING_ROUTING_ID RECEIPT_ROUTING,
          MSIB.WEIGHT_UOM_CODE WEIGHT_UOM,
          MSIB.UNIT_WEIGHT,
          MSIB.VOLUME_UOM_CODE VOLUME_UOM,
          MSIB.UNIT_VOLUME,
          MSIB.DIMENSION_UOM_CODE DIMENSION_UOM,
          MSIB.UNIT_LENGTH,
          MSIB.UNIT_WIDTH,
          MSIB.UNIT_HEIGHT,
          MSIB.INVENTORY_PLANNING_CODE INVENTORY_PLANNING_METHOD,
          MSIB.PLANNING_MAKE_BUY_CODE MAKE_BUY,
          MSIB.PLANNER_CODE PLANNER,
          MSIB.MIN_MINMAX_QUANTITY MINIMUM_QUANTITY,
          msib.max_minmax_quantity Maximum_Quantity,
          MSIB.MINIMUM_ORDER_QUANTITY,
          MSIB.MAXIMUM_ORDER_QUANTITY,
          MSIB.MRP_SAFETY_STOCK_CODE SAFETY_STOCK_METHOD,
          MSIB.CONSIGNED_FLAG CONSIGNED_FLAG,
          MSIB.ASN_AUTOEXPIRE_FLAG ASN_AUTO_EXPIRE_FLAG,
          MSIB.SO_AUTHORIZATION_FLAG RELEASE_AUTHORIZATION_REQUIRED,
          msib.vmi_forecast_type FORECAST_TYPE,
          MSIB.MRP_PLANNING_CODE,
          MSIB.ATO_FORECAST_CONTROL,
          MSIB.END_ASSEMBLY_PEGGING_FLAG,
          MSIB.EXCLUDE_FROM_BUDGET_FLAG EXCLUDE_FROM_BUDGET_FLAG,
          MSIB.CREATE_SUPPLY_FLAG CREATE_SUPPLY_FLAG,
          msib.critical_component_flag Critical_Componenet_Flag,
          MSIB.PREPROCESSING_LEAD_TIME,
          msib.full_lead_time PROCESSING_LEAD_TIME,
          MSIB.POSTPROCESSING_LEAD_TIME,
          MSIB.FIXED_LEAD_TIME,
          MSIB.VARIABLE_LEAD_TIME,
          MSIB.CUM_MANUFACTURING_LEAD_TIME CUMULATIVE_MFG_LEAD_TIME,
          MSIB.CUMULATIVE_TOTAL_LEAD_TIME CUMULATIVE_TOTAL_LEAD_TIME,
          MSIB.LEAD_TIME_LOT_SIZE LEAD_TIME_LOT_SIZE,
          MSIB.WIP_SUPPLY_TYPE,
          MSIB.INTERNAL_ORDER_FLAG,
          MSIB.PICK_COMPONENTS_FLAG,
          MSIB.REPLENISH_TO_ORDER_FLAG,
          MSIB.RETURNABLE_FLAG,
          MSIB.CUSTOMER_ORDER_ENABLED_FLAG,
          MSIB.CUSTOMER_ORDER_FLAG,
          MSIB.SHIPPABLE_ITEM_FLAG,
          MSIB.INTERNAL_ORDER_ENABLED_FLAG,
          MSIB.SHIP_MODEL_COMPLETE_FLAG,
          msib.so_transactions_flag Order_Entry_Transactable_Flag,
          MSIB.LOT_STATUS_ENABLED LOT_STATUS_ENABLED_FLAG,
          MSIB.SERIAL_STATUS_ENABLED SERIAL_STATUS_ENABLED_FLAG,
          MSIB.LOT_SPLIT_ENABLED LOT_SPLIT_ENABLED_FLAG,
          MSIB.LOT_MERGE_ENABLED LOT_MERGE_ENABLED_FLAG,
          MSIB.LOT_TRANSLATE_ENABLED LOT_TRANSLATE_ENABLED_FLAG,
          MSIB.LOT_SUBSTITUTION_ENABLED LOT_SUBSTITUTION_ENABLED_FLAG,
          MSIB.BULK_PICKED_FLAG,
          MSIB.ATP_FLAG CHECK_ATP,
          MSIB.ATP_RULE_ID                                 --for atp_rule_name
                          ,
          MSIB.ATP_COMPONENTS_FLAG ATP_COMPONENTS,
          MSIB.DEFAULT_SHIPPING_ORG,
          msib.default_so_source_type Default_SO_Source_Type,
          MSIB.OVER_SHIPMENT_TOLERANCE,
          MSIB.UNDER_SHIPMENT_TOLERANCE,
          MSIB.OVER_RETURN_TOLERANCE,
          MSIB.UNDER_RETURN_TOLERANCE,
          MSIB.INVOICEABLE_ITEM_FLAG,
          MSIB.INVOICE_ENABLED_FLAG,
          MSIB.SALES_ACCOUNT
     FROM MTL_SYSTEM_ITEMS_B MSIB,
          ORG_ORGANIZATION_DEFINITIONS OOD,
          CST_ITEM_COSTS CST
    WHERE     OOD.ORGANIZATION_ID = MSIB.ORGANIZATION_ID
          AND MSIB.INVENTORY_ITEM_ID = CST.INVENTORY_ITEM_ID
          AND OOD.ORGANIZATION_ID = CST.ORGANIZATION_ID;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_P2M_MITEMS_V FOR APPS.XX_BI_P2M_MITEMS_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_P2M_MITEMS_V FOR APPS.XX_BI_P2M_MITEMS_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_P2M_MITEMS_V FOR APPS.XX_BI_P2M_MITEMS_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_P2M_MITEMS_V FOR APPS.XX_BI_P2M_MITEMS_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2M_MITEMS_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2M_MITEMS_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2M_MITEMS_V TO XXINTG;
