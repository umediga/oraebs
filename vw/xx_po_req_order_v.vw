DROP VIEW APPS.XX_PO_REQ_ORDER_V;

/* Formatted on 6/6/2016 4:58:15 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_PO_REQ_ORDER_V
(
   COL1,
   COL2
)
AS
   SELECT DISTINCT a.segment1 col1, 'Purchase Order' col2
     FROM po_headers_all a,
          po_lines_all b,
          rcv_transactions c,
          org_organization_definitions d
    WHERE     c.po_line_id = b.po_line_id
          AND b.po_header_id = a.po_header_id
          AND d.organization_id = c.organization_id
   UNION ALL
   SELECT DISTINCT e.segment1 col1, 'Requisition' col2
     FROM rcv_transactions c,
          po_requisition_headers_all e,
          po_requisition_lines_all f,
          org_organization_definitions d
    WHERE     c.requisition_line_id = f.requisition_line_id
          AND e.requisition_header_id = f.requisition_header_id
          AND d.organization_id = c.organization_id;
