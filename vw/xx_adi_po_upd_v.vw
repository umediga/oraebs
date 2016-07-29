DROP VIEW APPS.XX_ADI_PO_UPD_V;

/* Formatted on 6/6/2016 5:00:01 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_ADI_PO_UPD_V
(
   ACTION,
   PO_NUMBER,
   REL_NUM,
   PO_LINE_NUM,
   SHIPMENT_NUM,
   UNIT_PRICE,
   QUANTITY,
   ITEM_NUMBER,
   ITEM_DESCRIPTION,
   NEED_BY_DATE,
   PROMISED_DATE,
   VENDOR_NAME,
   TYPE_NAME
)
AS
     SELECT "ACTION",
            "PO_NUMBER",
            "REL_NUM",
            "PO_LINE_NUM",
            "SHIPMENT_NUM",
            "UNIT_PRICE",
            "QUANTITY",
            "ITEM_NUMBER",
            "ITEM_DESCRIPTION",
            "NEED_BY_DATE",
            "PROMISED_DATE",
            "VENDOR_NAME",
            "TYPE_NAME"
       FROM (SELECT 'SYNC' action,
                    pha.segment1 po_number,
                    NULL rel_num,
                    pla.line_num po_line_num,
                    plla.shipment_num,
                    pla.unit_price,
                    pla.quantity,
                    (SELECT msi.segment1
                       FROM mtl_system_items_b msi
                      WHERE     msi.inventory_item_id = pla.item_id
                            AND msi.organization_id =
                                   po_lines_sv4.get_inventory_orgid (
                                      pla.org_id))
                       item_number,
                    pla.item_description,
                    plla.need_by_date,
                    plla.promised_date,
                    aps.vendor_name,
                    pdt.type_name
               FROM po_headers_all pha,
                    po_lines_all pla,
                    po_line_locations_all plla,
                    ap_suppliers aps,
                    po_document_types_all_tl pdt
              WHERE     pha.po_header_id = pla.po_header_id
                    AND pha.po_header_id = plla.po_header_id
                    AND pla.po_header_id = plla.po_header_id
                    AND pla.po_line_id = plla.po_line_id
                    AND pha.type_lookup_code = pdt.document_subtype
                    AND pdt.type_name = 'Standard Purchase Order'
                    AND pdt.language = 'US'
                    AND pdt.org_id = pha.org_id
                    AND aps.vendor_id = pha.vendor_id
             UNION
             SELECT 'SYNC' action,
                    pha.segment1 po_number,
                    pr.release_num rel_num,
                    pla.line_num po_line_num,
                    plla.shipment_num,
                    pla.unit_price,
                    pla.quantity,
                    (SELECT msi.segment1
                       FROM mtl_system_items_b msi
                      WHERE     msi.inventory_item_id = pla.item_id
                            AND msi.organization_id =
                                   po_lines_sv4.get_inventory_orgid (
                                      pla.org_id))
                       item_number,
                    pla.item_description,
                    plla.need_by_date,
                    plla.promised_date,
                    aps.vendor_name,
                    pdt.type_name
               FROM po_headers_all pha,
                    po_lines_all pla,
                    po_line_locations_all plla,
                    ap_suppliers aps,
                    po_document_types_all_tl pdt,
                    po_releases_all pr
              WHERE     pha.po_header_id = pla.po_header_id
                    AND pha.po_header_id = plla.po_header_id
                    AND pla.po_header_id = plla.po_header_id
                    AND pla.po_line_id = plla.po_line_id
                    AND pha.type_lookup_code = pdt.document_subtype
                    AND pdt.type_name = 'Blanket Release'
                    AND pdt.language = 'US'
                    AND pdt.org_id = pha.org_id
                    AND aps.vendor_id = pha.vendor_id
                    AND pr.po_release_id = plla.po_release_id
                    AND pr.po_header_id = pha.po_header_id
             UNION
             SELECT 'SYNC' action,
                    pha.segment1 po_number,
                    NULL rel_num,
                    pla.line_num po_line_num,
                    NULL shipment_num,
                    pla.unit_price,
                    pla.quantity,
                    (SELECT msi.segment1
                       FROM mtl_system_items_b msi
                      WHERE     msi.inventory_item_id = pla.item_id
                            AND msi.organization_id =
                                   po_lines_sv4.get_inventory_orgid (
                                      pla.org_id))
                       item_number,
                    pla.item_description,
                    NULL need_by_date,
                    NULL promised_date,
                    aps.vendor_name,
                    pdt.type_name
               FROM po_headers_all pha,
                    po_lines_all pla,
                    po_document_types_all_tl pdt,
                    ap_suppliers aps
              WHERE     pha.po_header_id = pla.po_header_id
                    AND pha.type_lookup_code = pdt.document_subtype
                    AND pdt.type_name = 'Blanket Purchase Agreement'
                    AND pdt.language = 'US'
                    AND pdt.org_id = pha.org_id
                    AND aps.vendor_id = pha.vendor_id)
   ORDER BY po_line_num, shipment_num;
