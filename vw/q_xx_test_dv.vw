DROP VIEW APPS.Q_XX_TEST_DV;

/* Formatted on 6/6/2016 5:00:31 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.Q_XX_TEST_DV
(
   ROW_ID,
   PLAN_ID,
   PLAN_NAME,
   ORGANIZATION_ID,
   ORGANIZATION_NAME,
   COLLECTION_ID,
   OCCURRENCE,
   LAST_UPDATE_DATE,
   LAST_UPDATED_BY_ID,
   LAST_UPDATED_BY,
   CREATION_DATE,
   CREATED_BY_ID,
   CREATED_BY,
   LAST_UPDATE_LOGIN,
   ITEM_ID,
   ITEM,
   ITEM_DESC
)
AS
   SELECT /*+ LEADING(qp) USE_NL(qp qr) push_pred(PH) USE_NL(PH PR)*/
         qr.ROWID row_id,
          qr.plan_id,
          qp.name plan_name,
          qr.organization_id,
          hou.name organization_name,
          qr.collection_id,
          qr.occurrence,
          qr.qa_last_update_date last_update_date,
          qr.qa_last_updated_by last_updated_by_id,
          fu2.user_name last_updated_by,
          qr.qa_creation_date creation_date,
          qr.qa_created_by created_by_id,
          fu.user_name created_by,
          qr.last_update_login,
          qr.ITEM_ID,
          MSIK.CONCATENATED_SEGMENTS "ITEM",
          qr.CHARACTER1 "ITEM_DESC"
     FROM qa_results qr,
          qa_plans qp,
          fnd_user_view fu,
          fnd_user_view fu2,
          hr_organization_units hou,
          MTL_SYSTEM_ITEMS_KFV MSIK
    WHERE     qp.plan_id = 2100
          AND qr.plan_id = 2100
          AND qp.plan_id = qr.plan_id
          AND qr.qa_created_by = fu.user_id
          AND qr.qa_last_updated_by = fu2.user_id
          AND qr.organization_id = hou.organization_id
          AND qr.ITEM_ID = MSIK.INVENTORY_ITEM_ID(+)
          AND qr.ORGANIZATION_ID = MSIK.ORGANIZATION_ID(+);
