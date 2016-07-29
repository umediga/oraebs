DROP VIEW APPS.XX_XRTX_PO_DOC_OU_SUPP_V;

/* Formatted on 6/6/2016 4:56:00 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_DOC_OU_SUPP_V
(
   OPERATING_UNIT,
   SUPPLIER_NAME,
   YEAR,
   DOCUMENT_TYPE,
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
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'STANDARD' document_type,
          'Total' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'STANDARD'
          AND a.authorization_status IS NOT NULL
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'STANDARD' document_type,
          'Incomplete' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'STANDARD'
          AND a.authorization_status = 'INCOMPLETE'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'STANDARD' document_type,
          'Inprocess' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'STANDARD'
          AND a.authorization_status = 'IN PROCESS'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'STANDARD' document_type,
          'Requires Reapproval' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'STANDARD'
          AND a.authorization_status = 'REQUIRES REAPPROVAL'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'STANDARD' document_type,
          'Rejected' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'STANDARD'
          AND a.authorization_status = 'REJECTED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'STANDARD' document_type,
          'Pre-Approved' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'STANDARD'
          AND a.authorization_status = 'PRE-APPROVED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'STANDARD' document_type,
          'Approved' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'STANDARD'
          AND a.authorization_status = 'APPROVED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'BLANKET' document_type,
          'Total' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'BLANKET'
          AND a.authorization_status IS NOT NULL
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'BLANKET' document_type,
          'Incomplete' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'BLANKET'
          AND a.authorization_status = 'INCOMPLETE'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'BLANKET' document_type,
          'Inprocess' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'BLANKET'
          AND a.authorization_status = 'IN PROCESS'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'BLANKET' document_type,
          'Requires Reapproval' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'BLANKET'
          AND a.authorization_status = 'REQUIRES REAPPROVAL'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'BLANKET' document_type,
          'Rejected' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'BLANKET'
          AND a.authorization_status = 'REJECTED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'BLANKET' document_type,
          'Pre-Approved' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'BLANKET'
          AND a.authorization_status = 'PRE-APPROVED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'BLANKET' document_type,
          'Approved' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'BLANKET'
          AND a.authorization_status = 'APPROVED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'CONTRACT' document_type,
          'Total' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'CONTRACT'
          AND a.authorization_status IS NOT NULL
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'CONTRACT' document_type,
          'Incomplete' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'CONTRACT'
          AND a.authorization_status = 'INCOMPLETE'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'CONTRACT' document_type,
          'Inprocess' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'CONTRACT'
          AND a.authorization_status = 'IN PROCESS'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'CONTRACT' document_type,
          'Requires Reapproval' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'CONTRACT'
          AND a.authorization_status = 'REQUIRES REAPPROVAL'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'CONTRACT' document_type,
          'Rejected' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'CONTRACT'
          AND a.authorization_status = 'REJECTED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'CONTRACT' document_type,
          'Pre-Approved' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'CONTRACT'
          AND a.authorization_status = 'PRE-APPROVED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'CONTRACT' document_type,
          'Approved' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'CONTRACT'
          AND a.authorization_status = 'APPROVED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'PLANNED' document_type,
          'Total' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PLANNED'
          AND a.authorization_status IS NOT NULL
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'PLANNED' document_type,
          'Incomplete' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PLANNED'
          AND a.authorization_status = 'INCOMPLETE'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'PLANNED' document_type,
          'Inprocess' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PLANNED'
          AND a.authorization_status = 'IN PROCESS'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'PLANNED' document_type,
          'Requires Reapproval' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PLANNED'
          AND a.authorization_status = 'REQUIRES REAPPROVAL'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'PLANNED' document_type,
          'Rejected' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PLANNED'
          AND a.authorization_status = 'REJECTED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'PLANNED' document_type,
          'Pre-Approved' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PLANNED'
          AND a.authorization_status = 'PRE-APPROVED'
   UNION ALL
   SELECT hou.NAME operating_unit,
          aps.vendor_name supplier_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'PLANNED' document_type,
          'Approved' TOtal_type,
          TRUNC (A.creation_date) creation_date,
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
     FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
    WHERE     A.org_id = hou.organization_id
          AND A.vendor_id = aps.vendor_id(+)
          AND A.type_lookup_code = 'PLANNED'
          AND a.authorization_status = 'APPROVED';
