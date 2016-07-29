DROP VIEW APPS.XXINTG_PAR_LEVEL_V;

/* Formatted on 6/6/2016 5:00:15 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_PAR_LEVEL_V
(
   ORG_CODE,
   ITEM_NUMBER,
   SUB_CODE,
   DESCRIPTION,
   PAR_LEVEL,
   QOH,
   QOH_NONEXP,
   QOH_EXP,
   MIN_LEVEL,
   MAX_LEVEL,
   BIN_TYPE
)
AS
     SELECT mp.Organization_code Org_Code,
            msib.segment1 Item_Number,
            msi.secondary_inventory_name Sub_Code,
            msi.description Description,
            misi.max_minmax_quantity Par_Level,
            SUM (MOQD.TRANSACTION_QUANTITY) QOH,
            CASE
               WHEN TO_DATE (SYSDATE, 'DD-MM-YY') < MLN.EXPIRATION_DATE
               THEN
                  SUM (MOQD.TRANSACTION_QUANTITY)
               ELSE
                  0
            END
               QOH_NONEXP,
            CASE
               WHEN TO_DATE (SYSDATE, 'DD-MM-YY') >= MLN.EXPIRATION_DATE
               THEN
                  SUM (MOQD.TRANSACTION_QUANTITY)
               ELSE
                  0
            END
               QOH_EXP,
            MAX (MISI.MIN_MINMAX_QUANTITY) MIN_LEVEL,
            MAX (MISI.MAX_MINMAX_QUANTITY) MAX_LEVEL,
            DECODE (msi.attribute1,
                    'D', 'Dealer',
                    'H', 'Hospital',
                    'R', 'Representative',
                    'HB', 'Holding Bucket',
                    'I', 'International',
                    'NA')
               Bin_Type
       FROM apps.MTL_ITEM_SUB_INVENTORIES misi,
            apps.mtl_system_items_b msib,
            APPS.MTL_ONHAND_QUANTITIES_DETAIL MOQD,
            apps.MTL_secondary_inventories msi,
            apps.mtl_parameters mp,
            APPS.MTL_LOT_NUMBERS MLN
      WHERE     misi.organization_id = msib.organization_id
            AND misi.inventory_item_id = msib.inventory_item_id
            AND MISI.SECONDARY_INVENTORY = MOQD.SUBINVENTORY_CODE
            AND MSIB.ORGANIZATION_ID = MOQD.ORGANIZATION_ID
            AND MSIB.INVENTORY_ITEM_ID = MOQD.INVENTORY_ITEM_ID
            AND MLN.ORGANIZATION_ID = MSIB.ORGANIZATION_ID
            AND MLN.INVENTORY_ITEM_ID = MSIB.INVENTORY_ITEM_ID
            AND misi.max_minmax_quantity > 0
            AND msib.organization_id = mp.organization_id
            AND mp.organization_code = '150'
            AND msi.secondary_inventory_name = misi.secondary_inventory
            AND msi.organization_id = misi.organization_id
   GROUP BY mp.Organization_code,
            msib.segment1,
            msi.secondary_inventory_name,
            msi.description,
            misi.max_minmax_quantity,
            msi.attribute1,
            mln.expiration_date
-- ORDER BY   sub_code;
;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XXINTG_PAR_LEVEL_V FOR APPS.XXINTG_PAR_LEVEL_V;


CREATE OR REPLACE SYNONYM XXBI.XXINTG_PAR_LEVEL_V FOR APPS.XXINTG_PAR_LEVEL_V;


GRANT SELECT ON APPS.XXINTG_PAR_LEVEL_V TO ETLEBSUSER;
