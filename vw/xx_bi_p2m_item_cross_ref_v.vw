DROP VIEW APPS.XX_BI_P2M_ITEM_CROSS_REF_V;

/* Formatted on 6/6/2016 4:59:12 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_P2M_ITEM_CROSS_REF_V
(
   CROSS_REFERENCE_TYPE,
   ORGANIZATION_CODE,
   CROSS_REFERENCE,
   ATTRIBUTE1,
   ATTRIBUTE2,
   ATTRIBUTE3,
   ATTRIBUTE4,
   ATTRIBUTE5,
   ATTRIBUTE6,
   ATTRIBUTE7,
   ATTRIBUTE8,
   ATTRIBUTE9,
   MARKING,
   FINISH,
   PACKAGING,
   IFU,
   ATTRIBUTE14,
   ATTRIBUTE15,
   LIST_PRICE_PER_UNIT,
   PRIMARY_UOM_CODE,
   INVENTORY_ITEM_STATUS_CODE,
   ITEM_TYPE
)
AS
   SELECT mcr.cross_reference_type,
          ood.organization_code,
          mcr.cross_reference,
          mcr.attribute1,
          mcr.attribute2,
          mcr.attribute3,
          mcr.attribute4,
          mcr.attribute5,
          mcr.attribute6,
          mcr.attribute7,
          mcr.attribute8,
          mcr.attribute9,
          mcr.attribute10,
          mcr.attribute11,
          mcr.attribute12,
          mcr.attribute13,
          mcr.attribute14,
          mcr.attribute15,
          msib.list_price_per_unit,
          msib.primary_uom_code,
          msib.inventory_item_status_code,
          (SELECT flv.meaning
             FROM FND_LOOKUP_VALUES flv
            WHERE     flv.lookup_type = 'ITEM_TYPE'
                  AND flv.language = 'US'
                  AND flv.lookup_code = msib.item_type
                  AND ROWNUM <= 1)
     FROM mtl_cross_references mcr,
          mtl_system_items_b msib,
          org_organization_definitions ood
    WHERE     msib.inventory_item_id = mcr.inventory_item_id
          AND msib.organization_id = ood.organization_id;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_P2M_ITEM_CROSS_REF_V FOR APPS.XX_BI_P2M_ITEM_CROSS_REF_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_P2M_ITEM_CROSS_REF_V TO ETLEBSUSER;
