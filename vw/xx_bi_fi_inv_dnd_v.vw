DROP VIEW APPS.XX_BI_FI_INV_DND_V;

/* Formatted on 6/6/2016 4:59:54 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_INV_DND_V
(
   DEMAND_ID,
   NAME,
   ORGANIZATION_CODE,
   REQUIREMENT_DATE,
   INVENTORY_ITEM_NAME,
   DEMAND_SOURCE_TYPE,
   TRANSACTION_SOURCE_TYPE_NAME,
   DEMAND_SOURCE_HEADER_ID,
   SALES_ORDER_ID,
   ACCOUNT_ID,
   ACCOUNT_ALIAS_ID,
   DEMAND_SOURCE_TYPE1,
   UOM_CODE,
   DEMANDED_QUANTITY,
   RESERVED_QUANTITY,
   REVISION,
   LOT_NUMBER,
   SUBINVENTORY,
   CREATION_DATE,
   LAST_UPDATE_DATE,
   DEMAND_SRC_HDR_NAME,
   INV_LOC_NAME,
   CREATION_DATE_DD,
   CREATION_DATE_MONTH,
   CREATION_DATE_Q,
   CREATION_DATE_YEAR,
   LAST_UPDATE_DATE_DD,
   LAST_UPDATE_DATE_MONTH,
   LAST_UPDATE_DATE_Q,
   LAST_UPDATE_DATE_YEAR,
   REQUIREMENT_DATE_DD,
   REQUIREMENT_DATE_MONTH,
   REQUIREMENT_DATE_Q,
   REQUIREMENT_DATE_YEAR
)
AS
   SELECT M.DEMAND_ID,
          HOU.NAME,
          MP.ORGANIZATION_CODE,
          M.REQUIREMENT_DATE,
          NULL,
          M.DEMAND_SOURCE_TYPE,
          MTS.TRANSACTION_SOURCE_TYPE_NAME,
          M.DEMAND_SOURCE_HEADER_ID,
          M.DEMAND_SOURCE_HEADER_ID SALES_ORDER_ID,
          TO_NUMBER (NULL) ACCOUNT_ID,
          TO_NUMBER (NULL) ACCOUNT_ALIAS_ID,
          DECODE (M.DEMAND_SOURCE_TYPE,
                  2, NULL,
                  3, NULL,
                  6, NULL,
                  8, NULL,
                  12, NULL,
                  M.DEMAND_SOURCE_NAME),
          M.UOM_CODE UOM,
          M.LINE_ITEM_QUANTITY DEMANDED_QUANTITY,
          M.LINE_ITEM_RESERVATION_QTY RESERVED_QUANTITY,
          M.REVISION,
          M.LOT_NUMBER,
          M.SUBINVENTORY,
          M.CREATION_DATE,
          M.LAST_UPDATE_DATE,
          NULL AS DEMAND_SRC_HDR_NAME,
          NULL AS INV_LOC_NAME,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM'))),
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM'))),
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
     FROM MTL_SALES_ORDERS MSO,
          MTL_SYSTEM_ITEMS_B MSI,
          MTL_ITEM_LOCATIONS MIL,
          MTL_TXN_SOURCE_TYPES MTS,
          HR_ALL_ORGANIZATION_UNITS HOU,
          MTL_PARAMETERS MP,
          MTL_DEMAND M,
          ORG_ORGANIZATION_DEFINITIONS OOD
    WHERE     MSI.ORGANIZATION_ID = M.ORGANIZATION_ID
          AND MSI.INVENTORY_ITEM_ID = M.INVENTORY_ITEM_ID
          AND MIL.INVENTORY_LOCATION_ID(+) = M.LOCATOR_ID
          AND MIL.ORGANIZATION_ID(+) = M.ORGANIZATION_ID
          -- AND M.RESERVATION_TYPE = 1
          -- AND M.PARENT_DEMAND_ID IS NULL
          AND HOU.ORGANIZATION_ID = M.ORGANIZATION_ID
          AND MP.ORGANIZATION_ID = M.ORGANIZATION_ID
          AND MTS.TRANSACTION_SOURCE_TYPE_ID = M.DEMAND_SOURCE_TYPE
          -- AND (M.LINE_ITEM_QUANTITY - M.LINE_ITEM_RESERVATION_QTY) > 0
          AND MSO.SALES_ORDER_ID = M.DEMAND_SOURCE_HEADER_ID
          --AND M.DEMAND_SOURCE_TYPE IN (2, 8, 12)
          AND OOD.ORGANIZATION_ID = M.ORGANIZATION_ID
          AND HR_SECURITY.SHOW_BIS_RECORD (OOD.OPERATING_UNIT) = 'TRUE'
   UNION ALL
   SELECT M.DEMAND_ID,
          HOU.NAME,
          MP.ORGANIZATION_CODE,
          M.REQUIREMENT_DATE,
          NULL,
          M.DEMAND_SOURCE_TYPE,
          MTS.TRANSACTION_SOURCE_TYPE_NAME,
          M.DEMAND_SOURCE_HEADER_ID,
          TO_NUMBER (NULL) SALES_ORDER_ID,
          M.DEMAND_SOURCE_HEADER_ID ACCOUNT_ID,
          TO_NUMBER (NULL) ACCOUNT_ALIAS_ID,
          DECODE (M.DEMAND_SOURCE_TYPE,
                  2, NULL,
                  3, NULL,
                  6, NULL,
                  8, NULL,
                  12, NULL,
                  M.DEMAND_SOURCE_NAME),
          M.UOM_CODE UOM,
          M.LINE_ITEM_QUANTITY DEMANDED_QUANTITY,
          M.LINE_ITEM_RESERVATION_QTY RESERVED_QUANTITY,
          M.REVISION,
          M.LOT_NUMBER,
          M.SUBINVENTORY,
          M.CREATION_DATE,
          M.LAST_UPDATE_DATE,
          NULL AS DEMAND_SRC_HDR_NAME,
          NULL AS INV_LOC_NAME,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM'))),
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM'))),
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
     FROM GL_CODE_COMBINATIONS GLC,
          MTL_SYSTEM_ITEMS_B MSI,
          MTL_ITEM_LOCATIONS MIL,
          MTL_TXN_SOURCE_TYPES MTS,
          HR_ALL_ORGANIZATION_UNITS HOU,
          MTL_PARAMETERS MP,
          MTL_DEMAND M,
          ORG_ORGANIZATION_DEFINITIONS OOD
    WHERE     MSI.ORGANIZATION_ID = M.ORGANIZATION_ID
          AND MSI.INVENTORY_ITEM_ID = M.INVENTORY_ITEM_ID
          AND MIL.INVENTORY_LOCATION_ID(+) = M.LOCATOR_ID
          AND MIL.ORGANIZATION_ID(+) = M.ORGANIZATION_ID
          -- AND M.RESERVATION_TYPE = 1
          -- AND M.PARENT_DEMAND_ID IS NULL
          AND HOU.ORGANIZATION_ID = M.ORGANIZATION_ID
          AND MP.ORGANIZATION_ID = M.ORGANIZATION_ID
          AND MTS.TRANSACTION_SOURCE_TYPE_ID = M.DEMAND_SOURCE_TYPE
          -- AND (M.LINE_ITEM_QUANTITY - M.LINE_ITEM_RESERVATION_QTY) > 0
          AND GLC.CODE_COMBINATION_ID = M.DEMAND_SOURCE_HEADER_ID
          -- AND M.DEMAND_SOURCE_TYPE = 3
          AND OOD.ORGANIZATION_ID = M.ORGANIZATION_ID
          AND HR_SECURITY.SHOW_BIS_RECORD (OOD.OPERATING_UNIT) = 'TRUE'
   UNION ALL
   SELECT M.DEMAND_ID,
          HOU.NAME,
          MP.ORGANIZATION_CODE,
          M.REQUIREMENT_DATE,
          NULL,
          M.DEMAND_SOURCE_TYPE,
          MTS.TRANSACTION_SOURCE_TYPE_NAME,
          M.DEMAND_SOURCE_HEADER_ID,
          TO_NUMBER (NULL) SALES_ORDER_ID,
          TO_NUMBER (NULL) ACCOUNT_ID,
          M.DEMAND_SOURCE_HEADER_ID ACCOUNT_ALIAS_ID,
          DECODE (M.DEMAND_SOURCE_TYPE,
                  2, NULL,
                  3, NULL,
                  6, NULL,
                  8, NULL,
                  12, NULL,
                  M.DEMAND_SOURCE_NAME),
          M.UOM_CODE UOM,
          M.LINE_ITEM_QUANTITY DEMANDED_QUANTITY,
          M.LINE_ITEM_RESERVATION_QTY RESERVED_QUANTITY,
          M.REVISION,
          M.LOT_NUMBER,
          M.SUBINVENTORY,
          M.CREATION_DATE,
          M.LAST_UPDATE_DATE,
          NULL AS DEMAND_SRC_HDR_NAME,
          NULL AS INV_LOC_NAME,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM'))),
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM'))),
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
     FROM MTL_GENERIC_DISPOSITIONS MGD,
          MTL_SYSTEM_ITEMS_B MSI,
          MTL_ITEM_LOCATIONS MIL,
          MTL_TXN_SOURCE_TYPES MTS,
          HR_ALL_ORGANIZATION_UNITS HOU,
          MTL_PARAMETERS MP,
          MTL_DEMAND M,
          ORG_ORGANIZATION_DEFINITIONS OOD
    WHERE     MSI.ORGANIZATION_ID = M.ORGANIZATION_ID
          AND MSI.INVENTORY_ITEM_ID = M.INVENTORY_ITEM_ID
          AND MIL.INVENTORY_LOCATION_ID(+) = M.LOCATOR_ID
          AND MIL.ORGANIZATION_ID(+) = M.ORGANIZATION_ID
          AND M.RESERVATION_TYPE = 1
          AND M.PARENT_DEMAND_ID IS NULL
          AND HOU.ORGANIZATION_ID = M.ORGANIZATION_ID
          AND MP.ORGANIZATION_ID = M.ORGANIZATION_ID
          AND MTS.TRANSACTION_SOURCE_TYPE_ID = M.DEMAND_SOURCE_TYPE
          --AND (M.LINE_ITEM_QUANTITY - M.LINE_ITEM_RESERVATION_QTY) > 0
          -- AND MGD.DISPOSITION_ID = M.DEMAND_SOURCE_HEADER_ID
          AND MGD.ORGANIZATION_ID = M.ORGANIZATION_ID
          -- AND M.DEMAND_SOURCE_TYPE = 6
          AND OOD.ORGANIZATION_ID = M.ORGANIZATION_ID
          AND HR_SECURITY.SHOW_BIS_RECORD (OOD.OPERATING_UNIT) = 'TRUE'
   UNION ALL
   SELECT M.DEMAND_ID,
          HOU.NAME,
          MP.ORGANIZATION_CODE,
          M.REQUIREMENT_DATE,
          NULL,
          M.DEMAND_SOURCE_TYPE,
          MTS.TRANSACTION_SOURCE_TYPE_NAME,
          M.DEMAND_SOURCE_HEADER_ID,
          TO_NUMBER (NULL) SALES_ORDER_ID,
          TO_NUMBER (NULL) ACCOUNT_ID,
          TO_NUMBER (NULL) ACCOUNT_ALIAS_ID,
          DECODE (M.DEMAND_SOURCE_TYPE,
                  2, NULL,
                  3, NULL,
                  6, NULL,
                  8, NULL,
                  12, NULL,
                  M.DEMAND_SOURCE_NAME),
          M.UOM_CODE UOM,
          M.LINE_ITEM_QUANTITY DEMANDED_QUANTITY,
          M.LINE_ITEM_RESERVATION_QTY RESERVED_QUANTITY,
          M.REVISION,
          M.LOT_NUMBER,
          M.SUBINVENTORY,
          M.CREATION_DATE,
          M.LAST_UPDATE_DATE,
          NULL AS DEMAND_SRC_HDR_NAME,
          NULL AS INV_LOC_NAME,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM'))),
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM'))),
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
     FROM MTL_SYSTEM_ITEMS_B MSI,
          MTL_ITEM_LOCATIONS MIL,
          MTL_TXN_SOURCE_TYPES MTS,
          HR_ALL_ORGANIZATION_UNITS HOU,
          MTL_PARAMETERS MP,
          MTL_DEMAND M,
          ORG_ORGANIZATION_DEFINITIONS OOD
    WHERE     MSI.ORGANIZATION_ID = M.ORGANIZATION_ID
          AND MSI.INVENTORY_ITEM_ID = M.INVENTORY_ITEM_ID
          AND MIL.INVENTORY_LOCATION_ID(+) = M.LOCATOR_ID
          AND MIL.ORGANIZATION_ID(+) = M.ORGANIZATION_ID
          AND M.RESERVATION_TYPE = 1
          AND M.PARENT_DEMAND_ID IS NULL
          AND HOU.ORGANIZATION_ID = M.ORGANIZATION_ID
          AND MP.ORGANIZATION_ID = M.ORGANIZATION_ID
          AND MTS.TRANSACTION_SOURCE_TYPE_ID = M.DEMAND_SOURCE_TYPE
          -- AND (M.LINE_ITEM_QUANTITY - nvl(M.LINE_ITEM_RESERVATION_QTY,0) > 0
          --AND (M.DEMAND_SOURCE_TYPE = 13 OR M.DEMAND_SOURCE_TYPE > 99)
          AND OOD.ORGANIZATION_ID = M.ORGANIZATION_ID
          AND HR_SECURITY.SHOW_BIS_RECORD (OOD.OPERATING_UNIT) = 'TRUE';


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_INV_DND_V FOR APPS.XX_BI_FI_INV_DND_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_INV_DND_V FOR APPS.XX_BI_FI_INV_DND_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_INV_DND_V FOR APPS.XX_BI_FI_INV_DND_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_INV_DND_V FOR APPS.XX_BI_FI_INV_DND_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_INV_DND_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_INV_DND_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_INV_DND_V TO XXINTG;
