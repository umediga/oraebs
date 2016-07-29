DROP PACKAGE BODY APPS.XX_INV_EO_EXP_ANLYS_XMLP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.XX_INV_EO_EXP_ANLYS_XMLP_PKG
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 26-MAR-2013
 File Name     : XXINVEOEXPANLYXMLP.pkb
 Description   : This script creates the body of the package
                 xx_ont_chrg_sht_xmlp_pkg to create code for after
                 parameter form trigger
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 26-MAR-2013 Sharath Babu          Initial Development
 31-JAN-2014 Sharath Babu          Modified to fix performance
 07-FEB-2014 Sharath Babu          Modified code to introduce param p_incl_exp
 21-May-2014 Aabhas Bhargava       Modified code to include param p_incl_thirdsales
 02-Jun-2014 Aabhas Bhargava       Added Lookup Mapping for SO History Warehouse Data
 05-Jun-2014 Aabhas Bhargava       Added logic to calculate qty as negative for RMA Orders
 18-Dec-2014 Pravinkumar R         Added outer select statement to add up WPI and sales
 09-Mar-2014 Ramya Neeharika       changed the code to pick sales and WIP issues separately in different columns
 09-Sep-2015 Renganayaki (NTT DATA) Case#00005452 - Latest report version from Integra - Fixed for MST Org id hardcoding
*/
----------------------------------------------------------------------
   g_cat_set_fin         VARCHAR2(100) := NVL(xx_emf_pkg.get_paramater_value('XXINVEOEXPANLYS','CAT_SET_FIN'),'Financial Reporting');
 --g_master_org_id       NUMBER        := NVL(xx_emf_pkg.get_paramater_value('XXINVEOEXPANLYS','MASTER_ORG_ID'),83);
   g_master_org_id       NUMBER        := NVL(xx_emf_pkg.get_paramater_value('XXINVEOEXPANLYS','MASTER_ORG_ID'),102);
   g_cat_set_sale        VARCHAR2(100) := NVL(xx_emf_pkg.get_paramater_value('XXINVEOEXPANLYS','CAT_SET_SALE_MARK'),'Sales and Marketing');
   g_val_set_prod_class  VARCHAR2(100) := NVL(xx_emf_pkg.get_paramater_value('XXINVEOEXPANLYS','VAL_SET_PROD_CLASS'),'INTG_PRODUCT_CLASS');
   g_val_set_prod_type   VARCHAR2(100) := NVL(xx_emf_pkg.get_paramater_value('XXINVEOEXPANLYS','VAL_SET_PROD_TYPE'),'INTG_PRODUCT_TYPE');
   g_qa_status_code      VARCHAR2(100) := NVL(xx_emf_pkg.get_paramater_value('XXINVEOEXPANLYS','QA_STATUS_CODE'),'Active: QA');

--After Parameter Form Trigger
FUNCTION AFTERPFORM RETURN BOOLEAN
IS
BEGIN
   P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;

   IF p_org_hrchy IS NOT NULL AND p_org_hrchy <> 'None' THEN
      LP_ORG_HRCY := ' AND msib.organization_id IN ( SELECT  organization_id_child'||
                                                      ' FROM  per_organization_structures pos, per_org_structure_versions pov, per_org_structure_elements ose'||
                                                      ' WHERE pos.organization_structure_id = pov.organization_structure_id AND ose.org_structure_version_id = pov.org_structure_version_id'||
                                                      ' AND pos.name= :p_org_hrchy )';
   ELSE
      LP_ORG_HRCY := ' ';
   END IF;
   IF p_organization_id IS NOT NULL THEN
      LP_ORG := ' AND msib.organization_id = :p_organization_id ';
   ELSE
      LP_ORG := ' ';
   END IF;
   IF p_usr_item_type IS NOT NULL THEN
      LP_ITEM_TYPE := ' AND msib.item_type = :p_usr_item_type ';
   ELSE
      LP_ITEM_TYPE := ' ';
   END IF;

   RETURN (TRUE);
END AFTERPFORM;

--Before Report Trigger
FUNCTION BEFOREREPORT RETURN BOOLEAN
IS
   --Query to fetch Item data
   CURSOR c_item_data
   IS
   SELECT
                             msib.inventory_item_id
                            ,msib.organization_id
                         ,msib.segment1 item_num
                         ,msib.description item_desc
                         ,msib.inventory_item_status_code item_status
                         ,DECODE(msib.inventory_item_status_code,'Obsolete','OBSOLETE','Inactive','OBSOLETE','STANDARD') item_line_cfication
                         ,(SELECT meaning
                                 FROM fnd_common_lookups
                                WHERE lookup_type='ITEM_TYPE'
                                  AND lookup_code = msib.item_type
                                  AND NVL(start_date_active,SYSDATE)<=SYSDATE
                                  AND NVL(end_date_active,SYSDATE)>=SYSDATE
                                  AND enabled_flag ='Y' ) item_type
                         --,NULL item_type
                         ,TO_CHAR(TRUNC(msib.creation_date),'DD-MON-YYYY') item_creat_date
                         /*,(select mcat.segment1||'.'|| mcat.segment2||'.'|| mcat.segment3
                             from  mtl_item_categories  micat,
                                   mtl_category_sets mcats,
                                   mtl_categories mcat
                             where mcats.category_set_name = g_cat_set_fin
                               and micat.category_set_id = mcats.category_set_id
                               and micat.category_id = mcat.category_id
                               and msib.inventory_item_id = micat.inventory_item_id
                               and micat.organization_id = g_master_org_id ) financial_category*/
                         ,NULL financial_category
                         ,msib.primary_unit_of_measure uom
                         ,DECODE(msib.lot_control_code,1,'No Control',2,'Full Control',msib.lot_control_code) lot_control
                         /*,(select mcat.segment4
                             from  mtl_item_categories  micat,
                                   mtl_category_sets mcats,
                                   mtl_categories mcat
                             where mcats.category_set_name = g_cat_set_sale
                               and micat.category_set_id = mcats.category_set_id
                               and micat.category_id = mcat.category_id
                               and msib.inventory_item_id = micat.inventory_item_id
                               and micat.organization_id = g_master_org_id ) division
                         ,(select mcat.segment7
                             from  mtl_item_categories  micat,
                                   mtl_category_sets mcats,
                                   mtl_categories mcat
                             where mcats.category_set_name = g_cat_set_sale
                               and micat.category_set_id = mcats.category_set_id
                               and micat.category_id = mcat.category_id
                               and msib.inventory_item_id = micat.inventory_item_id
                               and micat.organization_id = g_master_org_id ) brand
                         ,(select mcat.segment8
                             from  mtl_item_categories  micat,
                                   mtl_category_sets mcats,
                                   mtl_categories mcat
                             where mcats.category_set_name = g_cat_set_sale
                               and micat.category_set_id = mcats.category_set_id
                               and micat.category_id = mcat.category_id
                               and msib.inventory_item_id = micat.inventory_item_id
                               and micat.organization_id = g_master_org_id ) product_class_value*/
                         ,NULL division
                         ,NULL brand
                         ,NULL product_class_value
                         /*,(select DISTINCT fvt.description
                             from  mtl_item_categories  micat,
                                   mtl_category_sets mcats,
                                   mtl_categories mcat,
                                   fnd_flex_value_sets fvs,
                                   fnd_flex_values_tl fvt,
                                   fnd_flex_values ffv
                             where ffv.flex_value_set_id = fvs.flex_value_set_id
                               and fvs.flex_value_set_name = g_val_set_prod_class
                               and fvt.language = USERENV ('LANG')
                               AND NVL(ffv.enabled_flag,'X') = 'Y'
                               and fvt.flex_value_id = ffv.flex_value_id
                               and NVL (ffv.start_date_active, SYSDATE) <= SYSDATE
                               and NVL (ffv.end_date_active, SYSDATE) >= SYSDATE
                               and mcat.segment8 = ffv.flex_value
                               and mcats.category_set_name = g_cat_set_sale
                               and micat.category_set_id = mcats.category_set_id
                               and micat.category_id = mcat.category_id
                               and msib.inventory_item_id = micat.inventory_item_id
                               and micat.organization_id = g_master_org_id
                               AND ROWNUM = 1 ) product_class_desc*/
                          ,NULL product_class_desc
                         /*,(select mcat.segment9
                             from  mtl_item_categories  micat,
                                   mtl_category_sets mcats,
                                   mtl_categories mcat
                             where mcats.category_set_name = g_cat_set_sale
                               and micat.category_set_id = mcats.category_set_id
                               and micat.category_id = mcat.category_id
                               and msib.inventory_item_id = micat.inventory_item_id
                               and micat.organization_id = g_master_org_id ) product_type_value
                         ,(select DISTINCT fvt.description
                             from  mtl_item_categories  micat,
                                   mtl_category_sets mcats,
                                   mtl_categories mcat,
                                   fnd_flex_value_sets fvs,
                                   fnd_flex_values_tl fvt,
                                   fnd_flex_values ffv
                             where ffv.flex_value_set_id = fvs.flex_value_set_id
                               and fvs.flex_value_set_name = g_val_set_prod_type
                               and fvt.language = USERENV ('LANG')
                               AND NVL(ffv.enabled_flag,'X') = 'Y'
                               and fvt.flex_value_id = ffv.flex_value_id
                               and NVL (ffv.start_date_active, SYSDATE) <= SYSDATE
                               and NVL (ffv.end_date_active, SYSDATE) >= SYSDATE
                               and mcat.segment9 = ffv.flex_value
                               and mcats.category_set_name = g_cat_set_sale
                               and micat.category_set_id = mcats.category_set_id
                               and micat.category_id = mcat.category_id
                               and msib.inventory_item_id = micat.inventory_item_id
                               and micat.organization_id = g_master_org_id
                               AND ROWNUM = 1 ) product_type_desc
                           ,(SELECT ood.organization_code
                                   FROM org_organization_definitions ood
                                  WHERE ood.organization_id = msib.organization_id
                                    AND ood.inventory_enabled_flag='Y'
                                    AND NVL(ood.disable_date,SYSDATE+1) > SYSDATE ) inv_org_code*/
                           ,NULL product_type_value
               ,NULL product_type_desc
                           ,ood.organization_code inv_org_code
                           ,(SELECT abc.abc_class_name
                                   FROM mtl_abc_assignments_v abc
                                  WHERE abc.inventory_item_id = msib.inventory_item_id
                                    AND abc.organization_id = msib.organization_id
                                    AND ROWNUM = 1 ) abc_code
                           /*,(select NVL(cic.item_cost,0)
                               from cst_item_costs  cic
                              where cic.inventory_item_id = msib.inventory_item_id
                                and cic.organization_id = msib.organization_id
                                and cic.cost_type_id=1 ) standard_cost*/
                           ,NVL(cic.item_cost,0) standard_cost
                           ,NULL on_hand_qty
                           ,NULL expiring_lot_qty
                           ,NULL qa_subinv_qty
                           ,NULL trx_qty_cur
                           ,NULL trx_qty_cur_1
                           ,NULL trx_qty_cur_2
                           ,NULL trx_qty_cur_3
                           ,NULL trx_qty_cur_4
                           ,NULL trx_qty_cur_5
                           ,NULL trx_qty_cur_6
                           ,NULL trx_qty_cur_7
                           ,NULL trx_qty_cur_8
                           ,NULL trx_qty_cur_9
                           ,NULL trx_qty_cur_10
                           ,NULL trx_qty_cur_11
                           ,NULL sale_hqty_cur
                           ,NULL sale_hqty_cur_1
                           ,NULL sale_hqty_cur_2
                           ,NULL sale_hqty_cur_3
                           ,NULL sale_hqty_cur_4
                           ,NULL sale_hqty_cur_5
                           ,NULL sale_hqty_cur_6
                           ,NULL sale_hqty_cur_7
                           ,NULL sale_hqty_cur_8
                           ,NULL sale_hqty_cur_9
                           ,NULL sale_hqty_cur_10
                           ,NULL sale_hqty_cur_11
                           ,NULL WIP_TRX_QTY_CUR -- added the columns from "WIP_TRX_QTY_CUR" to "WIP_TRX_QTY_CUR_11" for enhancement ticket no :12697
                           ,NULL WIP_TRX_QTY_CUR_1
                           ,NULL WIP_TRX_QTY_CUR_2
                           ,NULL WIP_TRX_QTY_CUR_3
                           ,NULL WIP_TRX_QTY_CUR_4
                           ,NULL WIP_TRX_QTY_CUR_5
                           ,NULL WIP_TRX_QTY_CUR_6
                           ,NULL WIP_TRX_QTY_CUR_7
                           ,NULL WIP_TRX_QTY_CUR_8
                           ,NULL WIP_TRX_QTY_CUR_9
                           ,NULL WIP_TRX_QTY_CUR_10
                           ,NULL WIP_TRX_QTY_CUR_11
                    FROM  mtl_system_items_b msib
                        ,org_organization_definitions ood
                        ,cst_item_costs  cic
                   WHERE  1 = 1
                     AND cic.cost_type_id(+)=1
                     AND msib.inventory_item_id = cic.inventory_item_id(+)
             AND msib.organization_id = cic.organization_id(+)
                     AND NVL(ood.disable_date,SYSDATE+1) > SYSDATE
                     AND ood.inventory_enabled_flag='Y'
                     AND ood.organization_id = msib.organization_id
                     AND msib.item_type = NVL(p_usr_item_type, msib.item_type)
                     AND msib.organization_id = NVL(p_organization_id, msib.organization_id)
                     AND msib.organization_id IN ( SELECT  organization_id_child
                                                  FROM  per_organization_structures pos, per_org_structure_versions pov, per_org_structure_elements ose
                                                 WHERE pos.organization_structure_id = pov.organization_structure_id AND ose.org_structure_version_id = pov.org_structure_version_id
                                              AND pos.name= NVL(p_org_hrchy,pos.name) );

   --Query to fetch transaction data with internal transactions
   CURSOR c_trx_sum_data_intl
   IS
   SELECT INVENTORY_ITEM_ID,ORGANIZATION_ID,PERIOD_NAME,NVL(ABS(SUM(TRX_QTY)),0) TRX_QTY FROM (
    -- INTERNAL
    SELECT mmt.inventory_item_id,mmt.organization_id,oap.period_name,nvl(abs(sum(mmt.primary_quantity)),0) trx_qty
               FROM mtl_material_transactions mmt,
                    mtl_transaction_types mtt,
                    mtl_txn_source_types mts,
                    fnd_lookup_values flv,
                    org_acct_periods_v oap
              WHERE mtt.transaction_source_type_id = mts.transaction_source_type_id
                AND mts.transaction_source_type_name = flv.description
                AND mmt.acct_period_id = oap.acct_period_id
                AND mmt.organization_id = oap.organization_id
                AND mts.transaction_source_type_id = mmt.transaction_source_type_id
                AND mtt.transaction_type_id = mmt.transaction_type_id
                AND EXISTS (SELECT 1
                              from MTL_SECONDARY_INVENTORIES MSI
                             WHERE ( ( p_incl_exp = 'Y' ) OR ( msi.asset_inventory = 1 AND p_incl_exp = 'N' ) )
                               AND msi.secondary_inventory_name = mmt.subinventory_code
                               and MSI.ORGANIZATION_ID = MMT.ORGANIZATION_ID )  --Added on 07-FEB-2014
                AND mmt.organization_id = NVL(p_organization_id,mmt.organization_id)
                AND mtt.transaction_type_name = flv.meaning
                AND flv.tag IN ('INTERNAL') -- removed wip
                AND flv.language = USERENV ('LANG')
                AND flv.enabled_flag = 'Y'
                AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(flv.start_date_active,SYSDATE)) AND TRUNC(NVL(flv.end_date_active,SYSDATE+1))
                and FLV.LOOKUP_TYPE = 'XXINV_EO_DEMAND_TRX_TYPES'
             group by MMT.INVENTORY_ITEM_ID,MMT.ORGANIZATION_ID,OAP.PERIOD_NAME
      union all
      -- Thirdsales = N and , fetch all sales Order
      SELECT mmt.inventory_item_id,mmt.organization_id,oap.period_name,nvl(abs(sum(mmt.primary_quantity)),0) trx_qty
               FROM mtl_material_transactions mmt,
                    mtl_transaction_types mtt,
                    mtl_txn_source_types mts,
                    fnd_lookup_values flv,
                    org_acct_periods_v oap
              WHERE mtt.transaction_source_type_id = mts.transaction_source_type_id
                AND mts.transaction_source_type_name = flv.description
                AND mmt.acct_period_id = oap.acct_period_id
                AND mmt.organization_id = oap.organization_id
                AND mts.transaction_source_type_id = mmt.transaction_source_type_id
                AND mtt.transaction_type_id = mmt.transaction_type_id
                AND EXISTS (SELECT 1
                              from MTL_SECONDARY_INVENTORIES MSI
                             WHERE ( ( p_incl_exp = 'Y' ) OR ( msi.asset_inventory = 1 AND p_incl_exp = 'N' ) )
                               AND msi.secondary_inventory_name = mmt.subinventory_code
                               and MSI.ORGANIZATION_ID = MMT.ORGANIZATION_ID )  --Added on 07-FEB-2014
                AND mmt.organization_id = NVL(p_organization_id,mmt.organization_id)
                AND mtt.transaction_type_name = flv.meaning
                and FLV.TAG in ('SALES')
                and P_INCL_THIRDSALES = 'N'
                AND flv.language = USERENV ('LANG')
                AND flv.enabled_flag = 'Y'
                AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(flv.start_date_active,SYSDATE)) AND TRUNC(NVL(flv.end_date_active,SYSDATE+1))
                and FLV.LOOKUP_TYPE = 'XXINV_EO_DEMAND_TRX_TYPES'
             group by MMT.INVENTORY_ITEM_ID,MMT.ORGANIZATION_ID,OAP.PERIOD_NAME
      union all
      -- Thirdsales = Y then fetch only the sales order of specific Order Types
      select MMT.INVENTORY_ITEM_ID,MMT.ORGANIZATION_ID,OAP.PERIOD_NAME,nvl(abs(sum(mmt.primary_quantity)),0) trx_qty
               FROM mtl_material_transactions mmt,
                    mtl_transaction_types mtt,
                    mtl_txn_source_types mts,
                    fnd_lookup_values flv,
                    ORG_ACCT_PERIODS_V OAP,
                    OE_ORDER_LINES_ALL OOL,
                    OE_ORDER_HEADERS_ALL OOH,
                    OE_TRANSACTION_TYPES_TL OTT
              where MTT.TRANSACTION_SOURCE_TYPE_ID = MTS.TRANSACTION_SOURCE_TYPE_ID
                and MMT.SOURCE_LINE_ID = OOL.LINE_ID
                and OOL.HEADER_ID = OOH.HEADER_ID
                and OOH.ORDER_TYPE_ID = OTT.TRANSACTION_TYPE_ID
                and P_INCL_THIRDSALES = 'Y'
                and OTT.name  in (select MEANING from FND_LOOKUP_VALUES_VL
                                            where LOOKUP_TYPE like 'INTG_R2R_RPT_081_SALES_DEMAND'
                                            and enabled_flag = 'Y')
                AND mts.transaction_source_type_name = flv.description
                AND mmt.acct_period_id = oap.acct_period_id
                AND mmt.organization_id = oap.organization_id
                AND mts.transaction_source_type_id = mmt.transaction_source_type_id
                AND mtt.transaction_type_id = mmt.transaction_type_id
                AND EXISTS (SELECT 1
                              from MTL_SECONDARY_INVENTORIES MSI
                             WHERE ( ( p_incl_exp = 'Y' ) OR ( msi.asset_inventory = 1 AND p_incl_exp = 'N' ) )
                               AND msi.secondary_inventory_name = mmt.subinventory_code
                               and MSI.ORGANIZATION_ID = MMT.ORGANIZATION_ID )  --Added on 07-FEB-2014
                AND mmt.organization_id = NVL(p_organization_id,mmt.organization_id)
                AND mtt.transaction_type_name = flv.meaning
                AND flv.tag IN ('SALES')
                and FLV.LANGUAGE = USERENV ('LANG')
                AND OTT.LANGUAGE = USERENV ('LANG')
                AND flv.enabled_flag = 'Y'
                AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(flv.start_date_active,SYSDATE)) AND TRUNC(NVL(flv.end_date_active,SYSDATE+1))
                and FLV.LOOKUP_TYPE = 'XXINV_EO_DEMAND_TRX_TYPES'
             GROUP BY MMT.INVENTORY_ITEM_ID,MMT.ORGANIZATION_ID,OAP.PERIOD_NAME
             )
             GROUP BY INVENTORY_ITEM_ID,ORGANIZATION_ID,PERIOD_NAME;

   --query to fetch WIP issues ( changed for ticket 12697)

   CURSOR c_trx_sum_data_wip
   IS
   SELECT INVENTORY_ITEM_ID,ORGANIZATION_ID,PERIOD_NAME,NVL(ABS(SUM(TRX_QTY)),0) TRX_QTY FROM (
    SELECT mmt.inventory_item_id,mmt.organization_id,oap.period_name,nvl(abs(sum(mmt.primary_quantity)),0) trx_qty
               FROM mtl_material_transactions mmt,
                    mtl_transaction_types mtt,
                    mtl_txn_source_types mts,
                    fnd_lookup_values flv,
                    org_acct_periods_v oap
              WHERE mtt.transaction_source_type_id = mts.transaction_source_type_id
                AND mts.transaction_source_type_name = flv.description
                AND mmt.acct_period_id = oap.acct_period_id
                AND mmt.organization_id = oap.organization_id
                AND mts.transaction_source_type_id = mmt.transaction_source_type_id
                AND mtt.transaction_type_id = mmt.transaction_type_id
                AND EXISTS (SELECT 1
                              from MTL_SECONDARY_INVENTORIES MSI
                             WHERE ( ( p_incl_exp = 'Y' ) OR ( msi.asset_inventory = 1 AND p_incl_exp = 'N' ) )
                               AND msi.secondary_inventory_name = mmt.subinventory_code
                               and MSI.ORGANIZATION_ID = MMT.ORGANIZATION_ID )  --Added on 07-FEB-2014
                AND mmt.organization_id = NVL(p_organization_id,mmt.organization_id)
                AND mtt.transaction_type_name = flv.meaning
                AND flv.tag IN ('WIP')
                AND flv.language = USERENV ('LANG')
                AND flv.enabled_flag = 'Y'
                AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(flv.start_date_active,SYSDATE)) AND TRUNC(NVL(flv.end_date_active,SYSDATE+1))
                and FLV.LOOKUP_TYPE = 'XXINV_EO_DEMAND_TRX_TYPES'
             group by MMT.INVENTORY_ITEM_ID,MMT.ORGANIZATION_ID,OAP.PERIOD_NAME
             )
             GROUP BY INVENTORY_ITEM_ID,ORGANIZATION_ID,PERIOD_NAME;

   --Query to fetch transaction data with out internal transactions
   CURSOR c_trx_sum_data
   IS
   SELECT INVENTORY_ITEM_ID,ORGANIZATION_ID,PERIOD_NAME,NVL(ABS(SUM(TRX_QTY)),0) TRX_QTY FROM
(
         -- Thirdsales = N and , fetch all sales Order
      SELECT mmt.inventory_item_id,mmt.organization_id,oap.period_name,nvl(abs(sum(mmt.primary_quantity)),0) trx_qty
               FROM mtl_material_transactions mmt,
                    mtl_transaction_types mtt,
                    mtl_txn_source_types mts,
                    fnd_lookup_values flv,
                    org_acct_periods_v oap
              WHERE mtt.transaction_source_type_id = mts.transaction_source_type_id
                AND mts.transaction_source_type_name = flv.description
                AND mmt.acct_period_id = oap.acct_period_id
                AND mmt.organization_id = oap.organization_id
                AND mts.transaction_source_type_id = mmt.transaction_source_type_id
                AND mtt.transaction_type_id = mmt.transaction_type_id
                AND EXISTS (SELECT 1
                              from MTL_SECONDARY_INVENTORIES MSI
                             WHERE ( ( p_incl_exp = 'Y' ) OR ( msi.asset_inventory = 1 AND p_incl_exp = 'N' ) )
                               AND msi.secondary_inventory_name = mmt.subinventory_code
                               and MSI.ORGANIZATION_ID = MMT.ORGANIZATION_ID )  --Added on 07-FEB-2014
                AND mmt.organization_id = NVL(p_organization_id,mmt.organization_id)
                AND mtt.transaction_type_name = flv.meaning
                and FLV.TAG in ('SALES')
                and P_INCL_THIRDSALES = 'N'
                AND flv.language = USERENV ('LANG')
                AND flv.enabled_flag = 'Y'
                AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(flv.start_date_active,SYSDATE)) AND TRUNC(NVL(flv.end_date_active,SYSDATE+1))
                and FLV.LOOKUP_TYPE = 'XXINV_EO_DEMAND_TRX_TYPES'
             group by MMT.INVENTORY_ITEM_ID,MMT.ORGANIZATION_ID,OAP.PERIOD_NAME
      union all
      -- Thirdsales = Y then fetch only the sales order of specific Order Types
      select MMT.INVENTORY_ITEM_ID,MMT.ORGANIZATION_ID,OAP.PERIOD_NAME,nvl(abs(sum(mmt.primary_quantity)),0) trx_qty
               FROM mtl_material_transactions mmt,
                    mtl_transaction_types mtt,
                    mtl_txn_source_types mts,
                    fnd_lookup_values flv,
                    ORG_ACCT_PERIODS_V OAP,
                    OE_ORDER_LINES_ALL OOL,
                    OE_ORDER_HEADERS_ALL OOH,
                    OE_TRANSACTION_TYPES_TL OTT
              where MTT.TRANSACTION_SOURCE_TYPE_ID = MTS.TRANSACTION_SOURCE_TYPE_ID
                and MMT.SOURCE_LINE_ID = OOL.LINE_ID
                and OOL.HEADER_ID = OOH.HEADER_ID
                and OOH.ORDER_TYPE_ID = OTT.TRANSACTION_TYPE_ID
                and P_INCL_THIRDSALES = 'Y'
                and OTT.name  in (select MEANING from FND_LOOKUP_VALUES_VL
                                            where LOOKUP_TYPE like 'INTG_R2R_RPT_081_SALES_DEMAND'
                                            and enabled_flag = 'Y')
                AND mts.transaction_source_type_name = flv.description
                AND mmt.acct_period_id = oap.acct_period_id
                AND mmt.organization_id = oap.organization_id
                AND mts.transaction_source_type_id = mmt.transaction_source_type_id
                AND mtt.transaction_type_id = mmt.transaction_type_id
                AND EXISTS (SELECT 1
                              from MTL_SECONDARY_INVENTORIES MSI
                             WHERE ( ( p_incl_exp = 'Y' ) OR ( msi.asset_inventory = 1 AND p_incl_exp = 'N' ) )
                               AND msi.secondary_inventory_name = mmt.subinventory_code
                               and MSI.ORGANIZATION_ID = MMT.ORGANIZATION_ID )  --Added on 07-FEB-2014
                AND mmt.organization_id = NVL(p_organization_id,mmt.organization_id)
                AND mtt.transaction_type_name = flv.meaning
                AND flv.tag IN ('SALES')
                and FLV.LANGUAGE = USERENV ('LANG')
                AND OTT.LANGUAGE = USERENV ('LANG')
                AND flv.enabled_flag = 'Y'
                AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(flv.start_date_active,SYSDATE)) AND TRUNC(NVL(flv.end_date_active,SYSDATE+1))
                and FLV.LOOKUP_TYPE = 'XXINV_EO_DEMAND_TRX_TYPES'
             GROUP BY MMT.INVENTORY_ITEM_ID,MMT.ORGANIZATION_ID,OAP.PERIOD_NAME
             ) GROUP BY INVENTORY_ITEM_ID,ORGANIZATION_ID,PERIOD_NAME;

   --Query to fetch sales order history data
   CURSOR c_sale_hist_data
   IS
   SELECT INVENTORY_ITEM_ID,ORGANIZATION_ID,PERIOD_NAME,SUM(SALE_QTY) SALE_QTY
  from (
    SELECT msib.inventory_item_id,msib.organization_id,oap.period_name
           ,NVL(SUM(decode(sohl.rma_number,NULL, sohl.shipped_quantity,-1* sohl.shipped_quantity)), 0) sale_qty
               FROM XX_SALES_ORDER_HISTORY_LINE SOHL
                   ,xx_sales_order_history_header SOHH
                   ,mtl_system_items_b msib
                   ,org_organization_definitions ood
                   ,org_acct_periods_v oap
              WHERE 1=1
                AND ood.organization_id = msib.organization_id
                AND sohl.item = msib.segment1
                AND OOD.ORGANIZATION_CODE = (SELECT tag FROM FND_LOOKUP_VALUES_VL
                                            where LOOKUP_TYPE like 'INTG_R2R_RPT_081_WH_TO_IO_MAP'
                                            and lookup_code = sohl.warehouse
                                            and ENABLED_FLAG = 'Y')
                and sohl.header_id = sohh.header_id
                AND ood.inventory_enabled_flag='Y'
                AND NVL(ood.disable_date,SYSDATE+1) > SYSDATE
                AND TRUNC(sohl.actual_ship_date) BETWEEN TRUNC(oap.start_date) AND TRUNC(oap.end_date)
                AND OAP.ORGANIZATION_ID = OOD.ORGANIZATION_ID
                AND OOD.ORGANIZATION_ID = NVL(P_ORGANIZATION_ID,OOD.ORGANIZATION_ID)
                AND P_INCL_THIRDSALES = 'N'
               GROUP BY MSIB.INVENTORY_ITEM_ID,MSIB.ORGANIZATION_ID,OAP.PERIOD_NAME
    UNION ALL
    SELECT msib.inventory_item_id,msib.organization_id,oap.period_name
           ,NVL(SUM(decode(sohl.rma_number,NULL, sohl.shipped_quantity,-1* sohl.shipped_quantity)), 0) sale_qty
               FROM XX_SALES_ORDER_HISTORY_LINE SOHL
                   ,xx_sales_order_history_header SOHH
                   ,mtl_system_items_b msib
                   ,org_organization_definitions ood
                   ,org_acct_periods_v oap
              WHERE 1=1
                AND ood.organization_id = msib.organization_id
                AND sohl.item = msib.segment1
                AND OOD.ORGANIZATION_CODE = (SELECT tag FROM FND_LOOKUP_VALUES_VL
                                            where LOOKUP_TYPE like 'INTG_R2R_RPT_081_WH_TO_IO_MAP'
                                            and lookup_code = sohl.warehouse
                                            and ENABLED_FLAG = 'Y')
                and sohl.header_id = sohh.header_id
                AND ood.inventory_enabled_flag='Y'
                AND NVL(ood.disable_date,SYSDATE+1) > SYSDATE
                AND TRUNC(sohl.actual_ship_date) BETWEEN TRUNC(oap.start_date) AND TRUNC(oap.end_date)
                AND OAP.ORGANIZATION_ID = OOD.ORGANIZATION_ID
                AND OOD.ORGANIZATION_ID = NVL(P_ORGANIZATION_ID,OOD.ORGANIZATION_ID)
                AND P_INCL_THIRDSALES = 'Y'
                AND sohh.order_type   in (SELECT meaning FROM FND_LOOKUP_VALUES_VL
                                            WHERE LOOKUP_TYPE LIKE 'INTG_R2R_RPT_081_HIST_DEMAND'
                                            and enabled_flag = 'Y')
               GROUP BY msib.inventory_item_id,msib.organization_id,oap.period_name
                )
               GROUP BY  INVENTORY_ITEM_ID,ORGANIZATION_ID,PERIOD_NAME;


   --table type declaration
   TYPE g_item_data IS TABLE OF c_item_data%ROWTYPE;
   x_item_data g_item_data;

   TYPE g_trx_sum_data_intl IS TABLE OF c_trx_sum_data_intl%ROWTYPE;
   x_trx_sum_data_intl  g_trx_sum_data_intl;

   TYPE g_trx_sum_data IS TABLE OF c_trx_sum_data%ROWTYPE;
   x_trx_sum_data  g_trx_sum_data;

   TYPE g_sale_hist_data IS TABLE OF c_sale_hist_data%ROWTYPE;
   x_sale_hist_data  g_sale_hist_data;

   TYPE g_trx_sum_data_wip IS TABLE OF c_trx_sum_data_wip%ROWTYPE; --added for ticket 12697
   x_trx_sum_data_wip  g_trx_sum_data_wip;

BEGIN
   --Fetch item data into temporary table
   BEGIN
         OPEN c_item_data;
         LOOP
         FETCH c_item_data
         BULK COLLECT INTO x_item_data LIMIT 1000;
         FORALL i IN 1 .. x_item_data.COUNT
        INSERT INTO XX_INV_EO_ANLYS_GBLTMP_TBL
        VALUES x_item_data (i);
        EXIT WHEN c_item_data%NOTFOUND;
     END LOOP;
     CLOSE c_item_data;
         --COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while bulk insert:Item Data'||SQLERRM);
   END;
   --Update temporary table with expiring_lot_qty
   BEGIN
      merge into XX_INV_EO_ANLYS_GBLTMP_TBL eoa
                  using (SELECT moqd.inventory_item_id,moqd.organization_id,NVL(SUM(moqd.primary_transaction_quantity),0) quantity
                               FROM mtl_onhand_quantities_detail moqd,
                                    mtl_lot_numbers mln,
                                    mtl_item_locations mil
                              WHERE 1=1
                                AND moqd.lot_number = mln.lot_number
                                AND moqd.organization_id = mil.organization_id (+)
                                AND moqd.locator_id = mil.inventory_location_id (+)
                                AND mln.expiration_date <= TRUNC(TO_DATE(p_lot_exp_date,'YYYY-MM-DD HH24:MI:SS'))
                                AND moqd.inventory_item_id = mln.inventory_item_id
                                AND EXISTS (SELECT 1
                                              FROM mtl_secondary_inventories msi
                                             WHERE ( ( p_incl_exp = 'Y' ) OR ( msi.asset_inventory = 1 AND p_incl_exp = 'N' ) )
                                               AND msi.secondary_inventory_name = moqd.subinventory_code
                                               AND msi.organization_id = moqd.organization_id )  --Added on 07-FEB-2014
                                AND mln.organization_id = moqd.organization_id
                                AND moqd.organization_id = NVL(p_organization_id,moqd.organization_id)
                                GROUP BY moqd.inventory_item_id,moqd.organization_id) rec
                  on (eoa.organization_id = rec.organization_id
                        and eoa.inventory_item_id = rec.inventory_item_id
                       )
               when matched then update set eoa.expiring_lot_qty = rec.quantity;
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while merging data for expiring_lot_qty: '||SQLERRM);
   END;
   --Update temporary table with on_hand_qty
   BEGIN
      merge into XX_INV_EO_ANLYS_GBLTMP_TBL eoa
                  using (SELECT mq.inventory_item_id,mq.organization_id,NVL(SUM(mq.transaction_quantity),0) quantity
                            FROM mtl_onhand_quantities mq
                           WHERE EXISTS (SELECT 1
                                              FROM mtl_secondary_inventories msi
                                             WHERE ( ( p_incl_exp = 'Y' ) OR ( msi.asset_inventory = 1 AND p_incl_exp = 'N' ) )
                                               AND msi.secondary_inventory_name = mq.subinventory_code
                                               AND msi.organization_id = mq.organization_id )  --Added on 07-FEB-2014
                             AND mq.organization_id = NVL(p_organization_id,mq.organization_id)
                                GROUP BY mq.inventory_item_id,mq.organization_id) rec
                  on (eoa.organization_id = rec.organization_id
                        and eoa.inventory_item_id = rec.inventory_item_id
                       )
               when matched then update set eoa.on_hand_qty = rec.quantity;
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while merging data for on_hand_qty: '||SQLERRM);
   END;
   --Update temporary table with qa_subinv_qty
   BEGIN
      merge into XX_INV_EO_ANLYS_GBLTMP_TBL eoa
                  using ( SELECT moq.inventory_item_id,moq.organization_id,NVL(SUM(moq.transaction_quantity),0) quantity
                                FROM mtl_onhand_quantities moq
                                    ,mtl_secondary_inventories msi
                                    ,mtl_material_statuses_tl mms
                               WHERE 1 = 1
                                 AND msi.status_id = mms.status_id
                                 AND mms.status_code = g_qa_status_code
                                 AND mms.language = USERENV ('LANG')
                                 AND ( ( p_incl_exp = 'Y' ) OR ( msi.asset_inventory = 1 AND p_incl_exp = 'N' ) )    --Added on 07-FEB-2014
                                 AND msi.organization_id = moq.organization_id
                                 AND msi.Secondary_inventory_name = moq.subinventory_code
                              AND moq.organization_id = NVL(p_organization_id,moq.organization_id)
                                GROUP BY moq.inventory_item_id,moq.organization_id) rec
                  on (eoa.organization_id = rec.organization_id
                        and eoa.inventory_item_id = rec.inventory_item_id
                       )
               when matched then update set eoa.qa_subinv_qty = rec.quantity;
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while merging data for qa_subinv_qty: '||SQLERRM);
   END;
   --Update temporary table with transaction qty with internal as per period
   IF p_incl_intr_trx = 'Y' OR p_incl_intr_trx IS NULL THEN
      BEGIN
         OPEN c_trx_sum_data_intl;
         LOOP
         FETCH c_trx_sum_data_intl
         BULK COLLECT INTO x_trx_sum_data_intl LIMIT 1000;
         FORALL i IN 1 .. x_trx_sum_data_intl.COUNT
        UPDATE XX_INV_EO_ANLYS_GBLTMP_TBL eoa
           SET eoa.trx_qty_cur = DECODE(x_trx_sum_data_intl(i).period_name,p_inv_period,x_trx_sum_data_intl(i).trx_qty,eoa.trx_qty_cur)
               ,eoa.trx_qty_cur_1 = DECODE(x_trx_sum_data_intl(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-1),'MON-YY'),x_trx_sum_data_intl(i).trx_qty,eoa.trx_qty_cur_1)
               ,eoa.trx_qty_cur_2 = DECODE(x_trx_sum_data_intl(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-2),'MON-YY'),x_trx_sum_data_intl(i).trx_qty,eoa.trx_qty_cur_2)
               ,eoa.trx_qty_cur_3 = DECODE(x_trx_sum_data_intl(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-3),'MON-YY'),x_trx_sum_data_intl(i).trx_qty,eoa.trx_qty_cur_3)
               ,eoa.trx_qty_cur_4 = DECODE(x_trx_sum_data_intl(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-4),'MON-YY'),x_trx_sum_data_intl(i).trx_qty,eoa.trx_qty_cur_4)
               ,eoa.trx_qty_cur_5 = DECODE(x_trx_sum_data_intl(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-5),'MON-YY'),x_trx_sum_data_intl(i).trx_qty,eoa.trx_qty_cur_5)
               ,eoa.trx_qty_cur_6 = DECODE(x_trx_sum_data_intl(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-6),'MON-YY'),x_trx_sum_data_intl(i).trx_qty,eoa.trx_qty_cur_6)
               ,eoa.trx_qty_cur_7 = DECODE(x_trx_sum_data_intl(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-7),'MON-YY'),x_trx_sum_data_intl(i).trx_qty,eoa.trx_qty_cur_7)
               ,eoa.trx_qty_cur_8 = DECODE(x_trx_sum_data_intl(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-8),'MON-YY'),x_trx_sum_data_intl(i).trx_qty,eoa.trx_qty_cur_8)
               ,eoa.trx_qty_cur_9 = DECODE(x_trx_sum_data_intl(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-9),'MON-YY'),x_trx_sum_data_intl(i).trx_qty,eoa.trx_qty_cur_9)
               ,eoa.trx_qty_cur_10 = DECODE(x_trx_sum_data_intl(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-10),'MON-YY'),x_trx_sum_data_intl(i).trx_qty,eoa.trx_qty_cur_10)
               ,eoa.trx_qty_cur_11 = DECODE(x_trx_sum_data_intl(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-11),'MON-YY'),x_trx_sum_data_intl(i).trx_qty,eoa.trx_qty_cur_11)
         WHERE eoa.organization_id = x_trx_sum_data_intl(i).organization_id
           and eoa.inventory_item_id = x_trx_sum_data_intl(i).inventory_item_id;
        EXIT WHEN c_trx_sum_data_intl%NOTFOUND;
     END LOOP;
     CLOSE c_trx_sum_data_intl;
         --COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while bulk update:Trx Data with Intl '||SQLERRM);
      END;
   --Update temporary table with transaction qty with out internal as per period
   ELSIF p_incl_intr_trx = 'N' THEN
      BEGIN
         OPEN c_trx_sum_data;
         LOOP
         FETCH c_trx_sum_data
         BULK COLLECT INTO x_trx_sum_data LIMIT 1000;
         FORALL i IN 1 .. x_trx_sum_data.COUNT
        UPDATE XX_INV_EO_ANLYS_GBLTMP_TBL eoa
           SET eoa.trx_qty_cur = DECODE(x_trx_sum_data(i).period_name,p_inv_period,x_trx_sum_data(i).trx_qty,eoa.trx_qty_cur)
               ,eoa.trx_qty_cur_1 = DECODE(x_trx_sum_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-1),'MON-YY'),x_trx_sum_data(i).trx_qty,eoa.trx_qty_cur_1)
               ,eoa.trx_qty_cur_2 = DECODE(x_trx_sum_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-2),'MON-YY'),x_trx_sum_data(i).trx_qty,eoa.trx_qty_cur_2)
               ,eoa.trx_qty_cur_3 = DECODE(x_trx_sum_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-3),'MON-YY'),x_trx_sum_data(i).trx_qty,eoa.trx_qty_cur_3)
               ,eoa.trx_qty_cur_4 = DECODE(x_trx_sum_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-4),'MON-YY'),x_trx_sum_data(i).trx_qty,eoa.trx_qty_cur_4)
               ,eoa.trx_qty_cur_5 = DECODE(x_trx_sum_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-5),'MON-YY'),x_trx_sum_data(i).trx_qty,eoa.trx_qty_cur_5)
               ,eoa.trx_qty_cur_6 = DECODE(x_trx_sum_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-6),'MON-YY'),x_trx_sum_data(i).trx_qty,eoa.trx_qty_cur_6)
               ,eoa.trx_qty_cur_7 = DECODE(x_trx_sum_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-7),'MON-YY'),x_trx_sum_data(i).trx_qty,eoa.trx_qty_cur_7)
               ,eoa.trx_qty_cur_8 = DECODE(x_trx_sum_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-8),'MON-YY'),x_trx_sum_data(i).trx_qty,eoa.trx_qty_cur_8)
               ,eoa.trx_qty_cur_9 = DECODE(x_trx_sum_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-9),'MON-YY'),x_trx_sum_data(i).trx_qty,eoa.trx_qty_cur_9)
               ,eoa.trx_qty_cur_10 = DECODE(x_trx_sum_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-10),'MON-YY'),x_trx_sum_data(i).trx_qty,eoa.trx_qty_cur_10)
               ,eoa.trx_qty_cur_11 = DECODE(x_trx_sum_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-11),'MON-YY'),x_trx_sum_data(i).trx_qty,eoa.trx_qty_cur_11)
         WHERE eoa.organization_id = x_trx_sum_data(i).organization_id
           and eoa.inventory_item_id = x_trx_sum_data(i).inventory_item_id;
        EXIT WHEN c_trx_sum_data%NOTFOUND;
     END LOOP;
     CLOSE c_trx_sum_data;
         --COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while bulk update:Trx Data without Intl '||SQLERRM);
      END;
   END IF;
   --Update temporary table with sales history as per period (added for ticket 12697)
      BEGIN
         OPEN c_sale_hist_data;
         LOOP
         FETCH c_sale_hist_data
         BULK COLLECT INTO x_sale_hist_data LIMIT 1000;
         FORALL i IN 1 .. x_sale_hist_data.COUNT
        UPDATE XX_INV_EO_ANLYS_GBLTMP_TBL eoa
           SET eoa.sale_hqty_cur = DECODE(x_sale_hist_data(i).period_name,p_inv_period,x_sale_hist_data(i).sale_qty,eoa.sale_hqty_cur)
               ,eoa.sale_hqty_cur_1 = DECODE(x_sale_hist_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-1),'MON-YY'),x_sale_hist_data(i).sale_qty,eoa.sale_hqty_cur_1)
               ,eoa.sale_hqty_cur_2 = DECODE(x_sale_hist_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-2),'MON-YY'),x_sale_hist_data(i).sale_qty,eoa.sale_hqty_cur_2)
               ,eoa.sale_hqty_cur_3 = DECODE(x_sale_hist_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-3),'MON-YY'),x_sale_hist_data(i).sale_qty,eoa.sale_hqty_cur_3)
               ,eoa.sale_hqty_cur_4 = DECODE(x_sale_hist_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-4),'MON-YY'),x_sale_hist_data(i).sale_qty,eoa.sale_hqty_cur_4)
               ,eoa.sale_hqty_cur_5 = DECODE(x_sale_hist_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-5),'MON-YY'),x_sale_hist_data(i).sale_qty,eoa.sale_hqty_cur_5)
               ,eoa.sale_hqty_cur_6 = DECODE(x_sale_hist_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-6),'MON-YY'),x_sale_hist_data(i).sale_qty,eoa.sale_hqty_cur_6)
               ,eoa.sale_hqty_cur_7 = DECODE(x_sale_hist_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-7),'MON-YY'),x_sale_hist_data(i).sale_qty,eoa.sale_hqty_cur_7)
               ,eoa.sale_hqty_cur_8 = DECODE(x_sale_hist_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-8),'MON-YY'),x_sale_hist_data(i).sale_qty,eoa.sale_hqty_cur_8)
               ,eoa.sale_hqty_cur_9 = DECODE(x_sale_hist_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-9),'MON-YY'),x_sale_hist_data(i).sale_qty,eoa.sale_hqty_cur_9)
               ,eoa.sale_hqty_cur_10 = DECODE(x_sale_hist_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-10),'MON-YY'),x_sale_hist_data(i).sale_qty,eoa.sale_hqty_cur_10)
               ,eoa.sale_hqty_cur_11 = DECODE(x_sale_hist_data(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-11),'MON-YY'),x_sale_hist_data(i).sale_qty,eoa.sale_hqty_cur_11)
         WHERE eoa.organization_id = x_sale_hist_data(i).organization_id
           and eoa.inventory_item_id = x_sale_hist_data(i).inventory_item_id;
        EXIT WHEN c_sale_hist_data%NOTFOUND;
     END LOOP;
     CLOSE c_sale_hist_data;
         --COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while bulk update:Sales History Data '||SQLERRM);
      END;
      -- update table with wip as period
       BEGIN
         OPEN c_trx_sum_data_wip;
         LOOP
         FETCH c_trx_sum_data_wip
         BULK COLLECT INTO x_trx_sum_data_wip LIMIT 1000;
         FORALL i IN 1 .. x_trx_sum_data_wip.COUNT
        UPDATE XX_INV_EO_ANLYS_GBLTMP_TBL eoa
           SET eoa.wip_trx_qty_cur = DECODE(x_trx_sum_data_wip(i).period_name,p_inv_period,x_trx_sum_data_wip(i).trx_qty,eoa.wip_trx_qty_cur)
               ,eoa.wip_trx_qty_cur_1 = DECODE(x_trx_sum_data_wip(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-1),'MON-YY'),x_trx_sum_data_wip(i).trx_qty,eoa.wip_trx_qty_cur_1)
               ,eoa.wip_trx_qty_cur_2 = DECODE(x_trx_sum_data_wip(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-2),'MON-YY'),x_trx_sum_data_wip(i).trx_qty,eoa.wip_trx_qty_cur_2)
               ,eoa.wip_trx_qty_cur_3 = DECODE(x_trx_sum_data_wip(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-3),'MON-YY'),x_trx_sum_data_wip(i).trx_qty,eoa.wip_trx_qty_cur_3)
               ,eoa.wip_trx_qty_cur_4 = DECODE(x_trx_sum_data_wip(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-4),'MON-YY'),x_trx_sum_data_wip(i).trx_qty,eoa.wip_trx_qty_cur_4)
               ,eoa.wip_trx_qty_cur_5 = DECODE(x_trx_sum_data_wip(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-5),'MON-YY'),x_trx_sum_data_wip(i).trx_qty,eoa.wip_trx_qty_cur_5)
               ,eoa.wip_trx_qty_cur_6 = DECODE(x_trx_sum_data_wip(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-6),'MON-YY'),x_trx_sum_data_wip(i).trx_qty,eoa.wip_trx_qty_cur_6)
               ,eoa.wip_trx_qty_cur_7 = DECODE(x_trx_sum_data_wip(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-7),'MON-YY'),x_trx_sum_data_wip(i).trx_qty,eoa.wip_trx_qty_cur_7)
               ,eoa.wip_trx_qty_cur_8 = DECODE(x_trx_sum_data_wip(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-8),'MON-YY'),x_trx_sum_data_wip(i).trx_qty,eoa.wip_trx_qty_cur_8)
               ,eoa.wip_trx_qty_cur_9 = DECODE(x_trx_sum_data_wip(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-9),'MON-YY'),x_trx_sum_data_wip(i).trx_qty,eoa.wip_trx_qty_cur_9)
               ,eoa.wip_trx_qty_cur_10 = DECODE(x_trx_sum_data_wip(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-10),'MON-YY'),x_trx_sum_data_wip(i).trx_qty,eoa.wip_trx_qty_cur_10)
               ,eoa.wip_trx_qty_cur_11 = DECODE(x_trx_sum_data_wip(i).period_name,TO_CHAR(ADD_MONTHS(TO_DATE(p_inv_period,'MON-YY'),-11),'MON-YY'),x_trx_sum_data_wip(i).trx_qty,eoa.wip_trx_qty_cur_11)
         WHERE eoa.organization_id = x_trx_sum_data_wip(i).organization_id
           and eoa.inventory_item_id = x_trx_sum_data_wip(i).inventory_item_id;
        EXIT WHEN c_trx_sum_data_wip%NOTFOUND;
     END LOOP;
     CLOSE c_trx_sum_data_wip;
         --COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while bulk update:Trx Data with Intl '||SQLERRM);
      END;

   --Added on 31-JAN-2014 to fix performance issue
   --Update segment values division,brand,product_class_value,product_type_value
   BEGIN
      UPDATE XX_INV_EO_ANLYS_GBLTMP_TBL eoa
         SET ( eoa.division
              ,eoa.brand
              ,eoa.product_class_value
              ,eoa.product_type_value) = ( SELECT mcat.segment4
                                        ,mcat.segment7
                                 ,mcat.segment8
                                 ,mcat.segment9
                                FROM  mtl_item_categories  micat,
                                  mtl_category_sets mcats,
                                  mtl_categories mcat
                                WHERE mcats.category_set_name = g_cat_set_sale
                                  AND micat.category_set_id = mcats.category_set_id
                                  AND micat.category_id = mcat.category_id
                                  AND micat.inventory_item_id = eoa.inventory_item_id
                                  AND micat.organization_id = g_master_org_id );
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Updating segment values division,brand,product_class_value,product_type_value: '||SQLERRM);
   END;
   --Update financial_category
   BEGIN
      UPDATE XX_INV_EO_ANLYS_GBLTMP_TBL eoa
         SET ( eoa.financial_category) = ( SELECT mcat.segment1||'.'|| mcat.segment2||'.'|| mcat.segment3
                                 FROM mtl_item_categories  micat,
                                  mtl_category_sets mcats,
                                  mtl_categories mcat
                                WHERE mcats.category_set_name = g_cat_set_fin
                                  AND micat.category_set_id = mcats.category_set_id
                                  AND micat.category_id = mcat.category_id
                                  AND micat.inventory_item_id = eoa.inventory_item_id
                                  AND micat.organization_id = g_master_org_id );
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Updating financial_category: '||SQLERRM);
   END;
   --Update product_class_desc
   BEGIN
      UPDATE XX_INV_EO_ANLYS_GBLTMP_TBL eoa
         SET ( eoa.product_class_desc ) = ( SELECT DISTINCT fvt.description
                              FROM fnd_flex_value_sets fvs,
                               fnd_flex_values_tl fvt,
                               fnd_flex_values ffv
                             WHERE ffv.flex_value_set_id = fvs.flex_value_set_id
                               AND fvs.flex_value_set_name = g_val_set_prod_class
                               AND fvt.language = USERENV ('LANG')
                               AND NVL(ffv.enabled_flag,'X') = 'Y'
                               AND fvt.flex_value_id = ffv.flex_value_id
                               AND NVL (ffv.start_date_active, SYSDATE) <= SYSDATE
                               AND NVL (ffv.end_date_active, SYSDATE) >= SYSDATE
                               AND ffv.flex_value = eoa.product_class_value
                               AND ROWNUM = 1 );
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Updating product_class_desc: '||SQLERRM);
   END;
   --Update product_type_desc
   BEGIN
      UPDATE XX_INV_EO_ANLYS_GBLTMP_TBL eoa
         SET ( eoa.product_type_desc ) = ( SELECT DISTINCT fvt.description
                             FROM fnd_flex_value_sets fvs,
                              fnd_flex_values_tl fvt,
                              fnd_flex_values ffv
                            WHERE ffv.flex_value_set_id = fvs.flex_value_set_id
                              AND fvs.flex_value_set_name = g_val_set_prod_type
                              AND fvt.language = USERENV ('LANG')
                              AND NVL(ffv.enabled_flag,'X') = 'Y'
                              AND fvt.flex_value_id = ffv.flex_value_id
                              AND NVL (ffv.start_date_active, SYSDATE) <= SYSDATE
                              AND NVL (ffv.end_date_active, SYSDATE) >= SYSDATE
                              AND ffv.flex_value = eoa.product_type_value
                              AND ROWNUM = 1 );
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Updating product_type_desc: '||SQLERRM);
   END;

   RETURN (TRUE);
EXCEPTION
   WHEN OTHERS THEN
   NULL;
   RETURN (FALSE);
END BEFOREREPORT;

--After Report Trigger
FUNCTION AFTERREPORT RETURN BOOLEAN
IS
BEGIN
   --COMMIT;
   RETURN (TRUE);
EXCEPTION
   WHEN OTHERS THEN
   NULL;
   RETURN (FALSE);
END AFTERREPORT;

END XX_INV_EO_EXP_ANLYS_XMLP_PKG;
/
