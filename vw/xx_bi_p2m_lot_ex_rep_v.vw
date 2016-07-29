DROP VIEW APPS.XX_BI_P2M_LOT_EX_REP_V;

/* Formatted on 6/6/2016 4:59:11 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_P2M_LOT_EX_REP_V
(
   ORGANIZATION,
   ITEM_NUMBER,
   ITEM_DECRIPTION,
   SUBINVENTORY_CODE,
   ON_HAND_QUANTITY,
   LOT_NUMBER,
   EXPIRED_DATE
)
AS
     SELECT OOD.ORGANIZATION_code organization,
            MSIB.SEGMENT1 ITEM_NUMBER,
            MSIB.DESCRIPTION ITEM_DECRIPTION,
            MOQ.SUBINVENTORY_CODE,
            SUM (MOQ.TRANSACTION_QUANTITY) ON_HAND_QUANTITY,
            MOQ.LOT_NUMBER,
            MLN.EXPIRATION_DATE EXPIRED_DATE
       FROM MTL_SYSTEM_ITEMS_B MSIB,
            MTL_LOT_NUMBERS MLN,
            ORG_ORGANIZATION_DEFINITIONS OOD,
            MTL_ONHAND_QUANTITIES MOQ
      WHERE     OOD.ORGANIZATION_ID = MSIB.ORGANIZATION_ID
            AND MOQ.INVENTORY_ITEM_ID = MSIB.INVENTORY_ITEM_ID
            AND MOQ.ORGANIZATION_ID = MSIB.ORGANIZATION_ID
            AND MOQ.INVENTORY_ITEM_ID = MLN.INVENTORY_ITEM_ID(+)
            AND MOQ.LOT_NUMBER = MLN.LOT_NUMBER(+)
            AND MOQ.ORGANIZATION_ID = MLN.ORGANIZATION_ID(+)
   GROUP BY MOQ.TRANSACTION_QUANTITY,
            OOD.ORGANIZATION_code,
            MSIB.SEGMENT1,
            MSIB.DESCRIPTION,
            MOQ.LOT_NUMBER,
            MLN.EXPIRATION_DATE,
            MOQ.SUBINVENTORY_CODE;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_P2M_LOT_EX_REP_V FOR APPS.XX_BI_P2M_LOT_EX_REP_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_P2M_LOT_EX_REP_V FOR APPS.XX_BI_P2M_LOT_EX_REP_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_P2M_LOT_EX_REP_V FOR APPS.XX_BI_P2M_LOT_EX_REP_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_P2M_LOT_EX_REP_V FOR APPS.XX_BI_P2M_LOT_EX_REP_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2M_LOT_EX_REP_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2M_LOT_EX_REP_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2M_LOT_EX_REP_V TO XXINTG;
