DROP VIEW APPS.XX_BI_R2R_WO_TO_ASSETS_V;

/* Formatted on 6/6/2016 4:59:01 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_R2R_WO_TO_ASSETS_V
(
   ORGANIZATION_ID,
   ORGANIZATION_CODE,
   ORGANIZATION_NAME,
   WORK_ORDER_NUM,
   KIT_ASSEMBLY_ITEM,
   WORK_ORDER_CLOSE_DATE,
   TOOLS_INST_ISSUED_TO_WO,
   WO_VARIANCES_CREATED,
   WO_CAPEX,
   WO_SERIAL_NUM,
   WO_DEPARTMENT,
   ASSET_NUM,
   DATE_PLACE_IN_SERVICE,
   ASSET_COST,
   ASSET_CAPEX,
   ASSET_SERIAL_NUM,
   DEPRECIATION_DEPARTMENT,
   ASSET_LOCATION
)
AS
   SELECT W.ORGANIZATION_ID,
          --W.ORGANIZATION_NAME,
          W.ORGANIZATION_CODE,
          W.ORGANIZATION_NAME,
          W.WORK_ORDER_NUM,
          W.KIT_ASSEMBLY_ITEM,
          W.WORK_ORDER_CLOSE_DATE,
          W.TOOLS_INST_ISSUED_TO_WO,
          W.WO_VARIANCES_CREATED,
          W.WO_CAPEX,
          W.WO_SERIAL_NUM,
          W.WO_DEPARTMENT,
          S.ASSET_NUM,
          S.DATE_PLACE_IN_SERVICE,
          S.ASSET_COST,
          S.ASSET_CAPEX,
          S.ASSET_SERIAL_NUM,
          S.DEPRECIATION_DEPARTMENT,
          S.ASSET_LOCATION
     FROM (SELECT WDJ.ORGANIZATION_ID AS ORGANIZATION_ID,
                  --hou.name AS ORGANIZATION_NAME,
                  OOD.ORGANIZATION_CODE AS ORGANIZATION_CODE,
                  OOD.ORGANIZATION_NAME AS ORGANIZATION_NAME,
                  WE.WIP_ENTITY_NAME AS WORK_ORDER_NUM,
                  (SELECT MSI.SEGMENT1
                     FROM MTL_SYSTEM_ITEMS_B MSI
                    WHERE     MSI.INVENTORY_ITEM_ID IN (WDJ.PRIMARY_ITEM_ID)
                          AND MSI.ORGANIZATION_ID IN (WDJ.ORGANIZATION_ID))
                     KIT_ASSEMBLY_ITEM,
                  WDJ.DATE_CLOSED AS WORK_ORDER_CLOSE_DATE,
                  (SELECT SUM (NVL (WPB.PL_MATERIAL_IN, 0))
                     FROM WIP_PERIOD_BALANCES WPB
                    WHERE     WPB.WIP_ENTITY_ID = WDJ.WIP_ENTITY_ID
                          AND WPB.ORGANIZATION_ID = WDJ.ORGANIZATION_ID
                          AND WPB.ACCT_PERIOD_ID IN
                                 (SELECT DISTINCT OAP.ACCT_PERIOD_ID
                                    FROM ORG_ACCT_PERIODS OAP
                                   WHERE OAP.ORGANIZATION_ID =
                                            WDJ.ORGANIZATION_ID))
                     TOOLS_INST_ISSUED_TO_WO,
                  (SELECT SUM (
                               NVL (WPB.PL_MATERIAL_VAR, 0)
                             + NVL (WPB.TL_MATERIAL_VAR, 0))
                     FROM WIP_PERIOD_BALANCES WPB
                    WHERE     WPB.WIP_ENTITY_ID = WDJ.WIP_ENTITY_ID
                          AND WPB.ORGANIZATION_ID = WDJ.ORGANIZATION_ID
                          AND WPB.ACCT_PERIOD_ID IN
                                 (SELECT DISTINCT OAP.ACCT_PERIOD_ID
                                    FROM ORG_ACCT_PERIODS OAP
                                   WHERE OAP.ORGANIZATION_ID =
                                            WDJ.ORGANIZATION_ID))
                     WO_VARIANCES_CREATED,
                  WDJ.ATTRIBUTE10 AS WO_CAPEX,
                  (SELECT MSN.SERIAL_NUMBER
                     FROM MTL_SERIAL_NUMBERS MSN,
                          MFG_LOOKUPS ML1,
                          MTL_OBJECT_GENEALOGY MOG,
                          WIP_ENTITIES WIE
                    WHERE     MSN.GEN_OBJECT_ID = MOG.PARENT_OBJECT_ID
                          AND MOG.OBJECT_TYPE = 5
                          AND MOG.PARENT_OBJECT_TYPE = 2
                          AND MOG.END_DATE_ACTIVE IS NULL
                          AND ML1.LOOKUP_TYPE = 'WIP_SERIAL_STATUS'
                          AND ML1.LOOKUP_CODE = 3
                          AND WIE.GEN_OBJECT_ID = MOG.OBJECT_ID
                          AND WIE.WIP_ENTITY_ID = WE.WIP_ENTITY_ID)
                     WO_SERIAL_NUM,
                  WDJ.ATTRIBUTE11 AS WO_DEPARTMENT
             FROM WIP_DISCRETE_JOBS WDJ
                  LEFT OUTER JOIN HR_ALL_ORGANIZATION_UNITS HOU
                     ON WDJ.ORGANIZATION_ID = HOU.ORGANIZATION_ID,
                  WIP_ENTITIES WE,
                  ORG_ORGANIZATION_DEFINITIONS OOD
            WHERE     WE.WIP_ENTITY_ID = WDJ.WIP_ENTITY_ID --and we.wip_entity_name = '98899'
                  AND WDJ.ORGANIZATION_ID = OOD.ORGANIZATION_ID
                  AND WDJ.STATUS_TYPE = 12) W,
          (SELECT REGEXP_SUBSTR (FAT.DESCRIPTION, '[^-]+') WORK_ORDER_NUM,
                  FAB.ASSET_NUMBER ASSET_NUM,
                  FB.DATE_PLACED_IN_SERVICE AS DATE_PLACE_IN_SERVICE,
                  FB.COST AS ASSET_COST,
                  (SELECT DISTINCT FAK.SEGMENT1
                     FROM FA_ASSET_KEYWORDS FAK
                    WHERE FAB.ASSET_KEY_CCID = FAK.CODE_COMBINATION_ID)
                     ASSET_CAPEX,
                  FAB.SERIAL_NUMBER AS ASSET_SERIAL_NUM,
                  (SELECT DISTINCT GCC.SEGMENT2
                     FROM FA_DISTRIBUTION_HISTORY FDH,
                          GL_CODE_COMBINATIONS GCC
                    WHERE     FDH.CODE_COMBINATION_ID =
                                 GCC.CODE_COMBINATION_ID
                          AND FDH.ASSET_ID = FAT.ASSET_ID)
                     DEPRECIATION_DEPARTMENT,
                  (SELECT (   UPPER (FL.SEGMENT1)
                           || '.'
                           || UPPER (FL.SEGMENT2)
                           || '.'
                           || UPPER (FL.SEGMENT3)
                           || '.'
                           || UPPER (FL.SEGMENT4)
                           || '.'
                           || UPPER (FL.SEGMENT5))
                     FROM FA_LOCATIONS FL
                    WHERE FL.LOCATION_ID IN
                             (SELECT FBH.LOCATION_ID
                                FROM FA_DISTRIBUTION_HISTORY FBH
                               WHERE FBH.ASSET_ID = FAT.ASSET_ID))
                     ASSET_LOCATION
             FROM FA_ADDITIONS_TL FAT, FA_BOOKS FB, FA_ADDITIONS_B FAB
            WHERE     FAT.LANGUAGE = 'US'
                  AND FAT.SOURCE_LANG = 'US'
                  --and fat.asset_id=1037659
                  AND FB.DATE_INEFFECTIVE IS NULL
                  AND FAT.ASSET_ID = FB.ASSET_ID
                  AND FAT.ASSET_ID = FAB.ASSET_ID) S
    WHERE W.WORK_ORDER_NUM = S.WORK_ORDER_NUM;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_R2R_WO_TO_ASSETS_V FOR APPS.XX_BI_R2R_WO_TO_ASSETS_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_R2R_WO_TO_ASSETS_V FOR APPS.XX_BI_R2R_WO_TO_ASSETS_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_R2R_WO_TO_ASSETS_V FOR APPS.XX_BI_R2R_WO_TO_ASSETS_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_R2R_WO_TO_ASSETS_V FOR APPS.XX_BI_R2R_WO_TO_ASSETS_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_R2R_WO_TO_ASSETS_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_R2R_WO_TO_ASSETS_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_R2R_WO_TO_ASSETS_V TO XXINTG;
