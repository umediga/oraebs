DROP VIEW APPS.XX_XRTX_PO_REQ_TXN_OU_SUPPL;

/* Formatted on 6/6/2016 4:54:45 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_TXN_OU_SUPPL
(
   OPERATING_UNIT,
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
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'INTERNAL'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'INTERNAL' REQUISITION_TYPE,
          'Incomplete' total_type,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'INTERNAL'
          AND a.authorization_status = 'INCOMPLETE'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'INTERNAL' REQUISITION_TYPE,
          'Inprocess' total_type,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'INTERNAL'
          AND a.authorization_status = 'IN PROCESS'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'INTERNAL' REQUISITION_TYPE,
          'Cancelled' total_type,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'INTERNAL'
          AND a.authorization_status = 'CANCELLED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'INTERNAL' REQUISITION_TYPE,
          'Rejected' total_type,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'INTERNAL'
          AND a.authorization_status = 'REJECTED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'INTERNAL' REQUISITION_TYPE,
          'Approved' total_type,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'INTERNAL'
          AND a.authorization_status = 'APPROVED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'INTERNAL' REQUISITION_TYPE,
          'Pre Approved' total_type,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'INTERNAL'
          AND a.authorization_status = 'PRE-APPROVED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'INTERNAL' REQUISITION_TYPE,
          'Returned' total_type,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'INTERNAL'
          AND a.authorization_status = 'RETURNED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'INTERNAL' REQUISITION_TYPE,
          'System Saved' total_type,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'INTERNAL'
          AND A.authorization_status = 'SYSTEM_SAVED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PURCHASE'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'PURCHASE' REQUISITION_TYPE,
          'Incomplete' total_type,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PURCHASE'
          AND a.authorization_status = 'INCOMPLETE'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'PURCHASE' REQUISITION_TYPE,
          'Inprocess' total_type,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PURCHASE'
          AND a.authorization_status = 'IN PROCESS'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'PURCHASE' REQUISITION_TYPE,
          'Cancelled' total_type,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PURCHASE'
          AND a.authorization_status = 'CANCELLED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'PURCHASE' REQUISITION_TYPE,
          'Rejected' total_type,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PURCHASE'
          AND a.authorization_status = 'REJECTED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'PURCHASE' REQUISITION_TYPE,
          'Approved' total_type,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PURCHASE'
          AND a.authorization_status = 'APPROVED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'PURCHASE' REQUISITION_TYPE,
          'Pre Approved' total_type,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PURCHASE'
          AND a.authorization_status = 'PRE-APPROVED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'PURCHASE' REQUISITION_TYPE,
          'Returned' total_type,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PURCHASE'
          AND a.authorization_status = 'RETURNED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (A.creation_date, 'YYYY') YEAR,
          'PURCHASE' REQUISITION_TYPE,
          'System Saved' total_type,
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
          hr_all_organization_units hou,
          ap_suppliers aps
    WHERE     A.requisition_header_id = b.requisition_header_id
          AND A.org_id = hou.organization_id
          AND b.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PURCHASE'
          AND a.authorization_status = 'SYSTEM_SAVED';
