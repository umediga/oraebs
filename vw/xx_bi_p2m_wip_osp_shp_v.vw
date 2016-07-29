DROP VIEW APPS.XX_BI_P2M_WIP_OSP_SHP_V;

/* Formatted on 6/6/2016 4:59:06 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_P2M_WIP_OSP_SHP_V
(
   PRODUCT,
   ORGANIZATION_ID,
   ORG_CODE,
   ORG_NAME,
   FORGING_LOT_QTY,
   PO_NUMBER,
   PO_LINE,
   DESCRIPTION,
   NEED_BY_DATE,
   JOB_NO,
   FORGING_NO,
   VENDOR_FORGING_NUMBER,
   FORGING_LOT_NO,
   QUANTITY_ORDERED,
   QUANTITY_DELIVERED,
   QUANTITY_COMPLETED,
   QTY_AWAITING_INSPECTION
)
AS
     SELECT DISTINCT
            msi_po.segment1 product,
            ood.organization_id,
            ood.organization_code,
            ood.organization_name,
            -1 * rcv_mtln.primary_quantity forging_lot_qty,
            poh.segment1 po_number,
            pol.line_num po_line,
            msi_po.description,
            pll.need_by_date,
            w.wip_entity_name job_no,
            msi_fo.segment1 forging_no,
            fo_pasl.primary_vendor_item vendor_forging_number,
            rcv_mtln.lot_number forging_lot_no,
            pod.quantity_ordered,
            pod.quantity_delivered,
            job.quantity_completed,
            pod.quantity_delivered - job.quantity_completed
               qty_awaiting_inspection
       FROM apps.wip_discrete_jobs job,
            apps.wip_entities w,
            apps.mtl_system_items_b msi_fo,
            apps.mtl_material_transactions rcv_mmt,
            apps.mtl_transaction_lot_numbers rcv_mtln,
            apps.po_approved_supplier_list fo_pasl,
            apps.po_lines_all pol,
            apps.po_headers_all poh,
            apps.po_line_locations_all pll,
            apps.po_distributions_all pod,
            apps.mtl_system_items_b msi_po,
            apps.org_organization_definitions ood
      WHERE     job.organization_id = w.organization_id
            AND job.wip_entity_id = w.wip_entity_id
            AND job.status_type = 3
            AND w.organization_id = rcv_mmt.organization_id
            AND msi_fo.organization_id = w.organization_id
            AND msi_fo.inventory_item_id = rcv_mmt.inventory_item_id
            AND rcv_mmt.organization_id = w.organization_id
            AND rcv_mmt.transaction_source_type_id = 5
            AND rcv_mmt.transaction_action_id = 1
            AND rcv_mmt.transaction_type_id = 35
            AND rcv_mmt.transaction_source_id = w.wip_entity_id
            AND rcv_mmt.transaction_id = rcv_mtln.transaction_id
            AND fo_pasl.item_id = msi_fo.inventory_item_id
            AND fo_pasl.asl_status_id = 4
            AND (   w.organization_id <> 2098
                 OR (    w.organization_id = 2098
                     AND SUBSTR (rcv_mtln.lot_number, 1, 4) <> 'Conv'))
            AND pod.wip_entity_id = w.wip_entity_id
            AND poh.po_header_id = pod.po_header_id
            AND pol.line_type_id = 3
            AND pll.po_line_id = pol.po_line_id
            AND pll.ship_to_organization_id = w.organization_id
            AND pll.po_line_id = pod.po_line_id
            AND pll.line_location_id = pod.line_location_id
            AND pod.destination_organization_id = w.organization_id
            AND poh.po_header_id = pod.po_header_id
            AND msi_po.organization_id = pll.ship_to_organization_id
            AND msi_po.inventory_item_id = pol.item_id
            AND msi_po.organization_id = ood.organization_id
   --and w.wip_entity_name between '' and ''
   ORDER BY 1, 7;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_P2M_WIP_OSP_SHP_V FOR APPS.XX_BI_P2M_WIP_OSP_SHP_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_P2M_WIP_OSP_SHP_V TO ETLEBSUSER;
