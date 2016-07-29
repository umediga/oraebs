DROP VIEW APPS.XXINTG_PAR_MINMAX_V;

/* Formatted on 6/6/2016 5:00:15 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_PAR_MINMAX_V
(
   ITEM_NUMBER,
   ITEM_DESC,
   ORGANIZATION,
   SUBINVENTORY,
   ON_HAND_QUANTITY,
   QOH_NONEXP,
   QOH_EXP,
   MIN_LEVEL,
   MAX_LEVEL,
   SALESREP_NUMBER,
   LOCATOR,
   LAST_6MONTHS_SALES
)
AS
   (  SELECT MSI.SEGMENT1 ITEM_NUMBER,
             MSI.DESCRIPTION ITEM_DESC,
             --  MOQ.ORGANIZATION_ID Organization,
             MP.ORGANIZATION_CODE ORGANIZATION,
             MOQ.SUBINVENTORY_CODE SUBINVENTORY,
             SUM (MOQ.primary_TRANSACTION_QUANTITY) ON_HAND_QUANTITY,
             SUM (
                CASE
                   WHEN TO_DATE (SYSDATE, 'DD-MM-YY') < LOTS.EXPIRATION_DATE
                   THEN
                      MOQ.PRIMARY_TRANSACTION_QUANTITY
                   ELSE
                      0
                END)
                QOH_NONEXP,
             SUM (
                CASE
                   WHEN TO_DATE (SYSDATE, 'DD-MM-YY') >= LOTS.EXPIRATION_DATE
                   THEN
                      MOQ.PRIMARY_TRANSACTION_QUANTITY
                   ELSE
                      0
                END)
                QOH_EXP,
             MAX (MISI.MIN_MINMAX_QUANTITY) MIN_LEVEL,
             MAX (MISI.MAX_MINMAX_QUANTITY) MAX_LEVEL,
             NVL (MIL.ATTRIBUTE3, ' ') SALESREP_NUMBER,
             (mil.SEGMENT1 || '.' || mil.SEGMENT2 || '.' || mil.SEGMENT3)
                LOCATOR,
             (SELECT ABS (SUM (NVL (TRANSACTION_QUANTITY, 0)))
                FROM apps.MTL_MATERIAL_TRANSACTIONS
               WHERE     TRUNC (TRANSACTION_DATE) BETWEEN TRUNC (
                                                             ADD_MONTHS (
                                                                (TRUNC (
                                                                    SYSDATE)),
                                                                -6))
                                                      AND TRUNC (SYSDATE)
                     AND INVENTORY_ITEM_ID = MOQ.INVENTORY_ITEM_ID
                     AND ORGANIZATION_ID = MOQ.ORGANIZATION_ID
                     AND SUBINVENTORY_CODE = MOQ.SUBINVENTORY_CODE
                     AND SIGN (NVL (TRANSACTION_QUANTITY, 0)) = -1)
                LAST_6MONTHS_SALES
        FROM apps.MTL_ONHAND_NET MOQ,
             apps.MTL_SYSTEM_ITEMS MSI,
             apps.MTL_ITEM_SUB_INVENTORIES MISI,
             apps.MTL_PARAMETERS MP,
             apps.MTL_LOT_NUMBERS LOTS,
             apps.MTL_ITEM_LOCATIONS MIL
       WHERE     1 = 1
             AND MSI.INVENTORY_ITEM_ID = MOQ.INVENTORY_ITEM_ID
             AND MSI.ORGANIZATION_ID = MOQ.ORGANIZATION_ID
             AND MISI.INVENTORY_ITEM_ID(+) = MOQ.INVENTORY_ITEM_ID
             AND MISI.ORGANIZATION_ID(+) = MOQ.ORGANIZATION_ID
             AND MOQ.SUBINVENTORY_CODE = MISI.SECONDARY_INVENTORY(+)
             AND MP.ORGANIZATION_ID = MOQ.ORGANIZATION_ID
             AND MOQ.LOT_NUMBER = LOTS.LOT_NUMBER(+)
             AND MOQ.INVENTORY_ITEM_ID = LOTS.INVENTORY_ITEM_ID(+)
             AND MOQ.ORGANIZATION_ID = LOTS.ORGANIZATION_ID(+)
             AND MOQ.LOCATOR_ID = MIL.INVENTORY_LOCATION_ID
             AND MOQ.ORGANIZATION_ID = MIL.ORGANIZATION_ID
             AND MP.ORGANIZATION_CODE = '150'
    GROUP BY MOQ.INVENTORY_ITEM_ID,
             MSI.SEGMENT1,
             MSI.DESCRIPTION,
             MOQ.ORGANIZATION_ID,
             MP.ORGANIZATION_CODE,
             MOQ.SUBINVENTORY_CODE,
             NVL (MIL.ATTRIBUTE3, ' '),
             (MIL.SEGMENT1 || '.' || MIL.SEGMENT2 || '.' || MIL.SEGMENT3));


CREATE OR REPLACE SYNONYM ETLEBSUSER.XXINTG_PAR_MINMAX_V FOR APPS.XXINTG_PAR_MINMAX_V;


CREATE OR REPLACE SYNONYM XXBI.XXINTG_PAR_MINMAX_V FOR APPS.XXINTG_PAR_MINMAX_V;


GRANT SELECT ON APPS.XXINTG_PAR_MINMAX_V TO ETLEBSUSER;

GRANT SELECT ON APPS.XXINTG_PAR_MINMAX_V TO XXAPPSREAD;
