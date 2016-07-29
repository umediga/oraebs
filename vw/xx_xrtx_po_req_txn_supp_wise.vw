DROP VIEW APPS.XX_XRTX_PO_REQ_TXN_SUPP_WISE;

/* Formatted on 6/6/2016 4:54:17 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_TXN_SUPP_WISE
(
   SUPPLIER_NAME,
   YEAR,
   REQUISITION_TYPE,
   TOTAL_TYPE,
   CREATION_DATE,
   A,
   B,
   C,
   D,
   E,
   F,
   G,
   H,
   I,
   J,
   K,
   L
)
AS
   SELECT aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'INTERNAL' REQUISITION_TYPE,
          'Total' total_type,
          TRUNC (a.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM po_requisition_headers_all A,
          po_requisition_lines_all b,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'INTERNAL'
   UNION ALL
   SELECT aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'INTERNAL' REQUISITION_TYPE,
          'Cancel' total_type,
          TRUNC (a.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM po_requisition_headers_all A,
          po_requisition_lines_all b,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'INTERNAL'
          AND NVL (a.cancel_flag, 'N') <> 'N'
   UNION ALL
   SELECT aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'INTERNAL' REQUISITION_TYPE,
          'Open' total_type,
          TRUNC (a.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM po_requisition_headers_all A,
          po_requisition_lines_all b,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'INTERNAL'
          AND NVL (A.closed_code, 'OPEN') != 'FINALLY CLOSED'
          AND NVL (A.cancel_flag, 'N') = 'N'
   UNION ALL
   SELECT aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'INTERNAL' REQUISITION_TYPE,
          'Close' total_type,
          TRUNC (a.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM po_requisition_headers_all A,
          po_requisition_lines_all b,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'INTERNAL'
          AND NVL (A.closed_code, 'OPEN') = 'FINALLY CLOSED'
          AND NVL (a.cancel_flag, 'N') = 'N'
   UNION ALL
   SELECT aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'PURCHASE' REQUISITION_TYPE,
          'Total' total_type,
          TRUNC (a.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM po_requisition_headers_all A,
          po_requisition_lines_all b,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PURCHASE'
   UNION ALL
   SELECT aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'PURCHASE' REQUISITION_TYPE,
          'Cancel' total_type,
          TRUNC (a.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM po_requisition_headers_all A,
          po_requisition_lines_all b,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PURCHASE'
          AND NVL (a.cancel_flag, 'N') <> 'N'
   UNION ALL
   SELECT aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'PURCHASE' REQUISITION_TYPE,
          'Open' total_type,
          TRUNC (a.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM po_requisition_headers_all A,
          po_requisition_lines_all b,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PURCHASE'
          AND NVL (A.closed_code, 'OPEN') != 'FINALLY CLOSED'
          AND NVL (A.cancel_flag, 'N') = 'N'
   UNION ALL
   SELECT aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'PURCHASE' REQUISITION_TYPE,
          'Close' total_type,
          TRUNC (a.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM po_requisition_headers_all A,
          po_requisition_lines_all b,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PURCHASE'
          AND NVL (A.closed_code, 'OPEN') = 'FINALLY CLOSED'
          AND NVL (a.cancel_flag, 'N') = 'N';
