DROP VIEW APPS.XXWSM_MOVE_TRANSACTIONS_V;

/* Formatted on 6/6/2016 5:00:03 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXWSM_MOVE_TRANSACTIONS_V
(
   ORGANIZATION_CODE,
   NAME,
   ORGANIZATION_ID,
   CONCATENATED_SEGMENTS,
   DESCRIPTION,
   PRIMARY_UOM_CODE,
   TRANSACTION_TYPE_ID,
   TRANSACTION_DATE,
   SOURCE_CODE,
   QA_COLLECTION_ID,
   WIP_ENTITY_ID,
   TRANSACTION_TYPE_NAME,
   WIP_ENTITY_NAME,
   JOB_DESC,
   JOB_TYPE_MEANING,
   BOM_REVISION,
   ALTERNATE_BOM_DESIGNATOR,
   ROUTING_REVISION,
   ALTERNATE_ROUTING_DESIGNATOR,
   PROJECT_NUMBER,
   TASK_NUMBER,
   KANBAN_CARD_NUMBER,
   START_QUANTITY,
   TRANSACTION_SOURCE_ID,
   TRANSACTION_SET_ID
)
AS
   SELECT mp.organization_code,
          haou.name,
          haou.organization_id,
          msikfv.concatenated_segments,
          msikfv.description,
          msikfv.primary_uom_code,
          mmt.transaction_type_id,
          mmt.transaction_date,
          mmt.source_code,
          mmt.qa_collection_id,
          wmt.wip_entity_id,
          mtt.transaction_type_name,
          wdj.wip_entity_name,
          wdj.description job_desc,
          wdj.job_type_meaning,
          wdj.bom_revision,
          wdj.alternate_bom_designator,
          wdj.routing_revision,
          wdj.alternate_routing_designator,
          wdj.project_number,
          wdj.task_number,
          wdj.kanban_card_number,
          wdj.start_quantity,
          mmt.transaction_source_id,
          mmt.transaction_set_id
     FROM wip_move_transactions wmt,
          mtl_parameters mp,
          hr_all_organization_units haou,
          mtl_system_items_b msi,
          mtl_material_transactions mmt,
          mtl_transaction_types mtt,
          wip_discrete_jobs_v wdj,
          mtl_system_items_kfv msikfv
    WHERE     wmt.organization_id = haou.organization_id
          AND wmt.organization_id = mp.organization_id
          AND haou.organization_id = mp.organization_id
          AND wmt.to_operation_code IN ('SK99', '9999')
          AND wmt.primary_item_id = msi.inventory_item_id
          AND msi.organization_id = (SELECT organization_id
                                       FROM org_organization_definitions
                                      WHERE organization_code = 'MST')
          AND mmt.move_transaction_id = wmt.transaction_id
          AND mmt.transaction_source_id = wmt.wip_entity_id
          AND mmt.organization_id = wmt.organization_id
          AND mmt.transaction_type_id = mtt.transaction_type_id
          AND wmt.primary_item_id = msikfv.inventory_item_id
          AND msi.organization_id = msikfv.organization_id
          AND wdj.wip_entity_id = wmt.wip_entity_id
          AND wdj.organization_id = wmt.organization_id;
