DROP VIEW APPS.XX_P2M_JOB_DISPATCH_V;

/* Formatted on 6/6/2016 4:58:17 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_P2M_JOB_DISPATCH_V
(
   ASSEMBLY,
   JOB,
   SCHEDULE_GROUP,
   LINE_NUM,
   TOTAL_JOB_QUANTITY,
   COMPLEATION_DATE,
   OPERATION_CODE,
   DEPARTMENT,
   OP_SEQUENCE,
   DESCRIPTION,
   QUANTITY_IN_QUEUE,
   QUANTITY_TO_MOVE,
   OPERATION_START_DATE,
   OPERATION_COMPLETION_DATE
)
AS
   SELECT msi.segment1 "ASSEMBLY",
          we.wip_entity_name "JOB",
          --wsg.schedule_group_name,
          wdj.net_quantity "SCHEDULE_GROUP",
          wdj.line_id "LINE",
          wdj.start_quantity "TOTAL_JOB_QUANTITY",
          wdj.scheduled_completion_date "COMPLETION_DATE",
          bso.operation_code "OPERATION_CODE",
          bd.department_code "DEPARTMENT",
          wo.operation_seq_num "OP_SEQUENCE",
          wo.description "DESCRIPTION",
          DECODE (wo.quantity_in_queue, 0, NULL, wo.quantity_in_queue)
             "QUANTITY_IN_QUEUE",
          DECODE (wo.quantity_waiting_to_move,
                  0, NULL,
                  wo.quantity_waiting_to_move)
             "QUANTITY_TO_MOVE",
          wo.first_unit_start_date "OPERATION_START_DATE",
          wo.last_unit_completion_date "OPERATION_COMPLETION_DATE"
     FROM wip_entities we,
          wip_discrete_jobs wdj,
          wip_lines wl,
          wip_schedule_groups wsg,
          mtl_system_items_b msi,
          bom_standard_operations bso,
          bom_departments bd,
          wip_operations wo
    WHERE     we.wip_entity_id = wdj.wip_entity_id
          AND bd.department_id = wo.department_id
          AND wo.wip_entity_id = wdj.wip_entity_id
          AND wsg.schedule_group_id(+) = wdj.schedule_group_id
          AND wl.line_id(+) = wdj.line_id
          AND wl.organization_id(+) = wdj.organization_id
          AND bso.standard_operation_id(+) = wo.standard_operation_id
          AND NVL (bso.operation_type, 1) = 1
          AND bso.line_id IS NULL
          AND msi.inventory_item_id(+) = wdj.primary_item_id
          AND msi.organization_id(+) = wdj.organization_id
--     and wo.organization_id='2361'
--      and we.WIP_ENTITY_NAME='344321-2~DSP'     --'344320'   --'335325-1'  358563-1
;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_P2M_JOB_DISPATCH_V FOR APPS.XX_P2M_JOB_DISPATCH_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_P2M_JOB_DISPATCH_V FOR APPS.XX_P2M_JOB_DISPATCH_V;


CREATE OR REPLACE SYNONYM XXBI.XX_P2M_JOB_DISPATCH_V FOR APPS.XX_P2M_JOB_DISPATCH_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_P2M_JOB_DISPATCH_V FOR APPS.XX_P2M_JOB_DISPATCH_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_P2M_JOB_DISPATCH_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_P2M_JOB_DISPATCH_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_P2M_JOB_DISPATCH_V TO XXBI;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_P2M_JOB_DISPATCH_V TO XXINTG;
