DROP VIEW APPS.XX_XRTX_PO_ONTIME_V;

/* Formatted on 6/6/2016 4:55:18 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_ONTIME_V
(
   OPERATING_UNIT,
   AUTHORIZATION_STATUS,
   NEED_BY_DATE,
   YEAR,
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
   SELECT a.name operating_unit,
          pha.authorization_status,
          TRUNC (pla.need_by_date) need_by_date,
          EXTRACT (YEAR FROM rt.transaction_date) YEAR,
          CASE WHEN EXTRACT (MONTH FROM rt.transaction_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM rt.transaction_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM rt.transaction_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM rt.transaction_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM rt.transaction_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM rt.transaction_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM rt.transaction_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM rt.transaction_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM rt.transaction_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM rt.transaction_date) = 10 THEN 1 END
             J,                                                       --"OCT",
          CASE WHEN EXTRACT (MONTH FROM rt.transaction_date) = 11 THEN 1 END
             K,                                                       --"NOV",
          CASE WHEN EXTRACT (MONTH FROM rt.transaction_date) = 12 THEN 1 END
             L                                                        --"DEC",
     FROM hr_all_organization_units a,
          po_headers_all pha,
          po_line_locations_all pla,
          rcv_transactions rt
    WHERE     pha.po_HEADER_ID = pla.po_HEADER_ID
          AND rt.po_line_location_id = pla.line_location_id
          AND pha.org_id = a.organization_id
          AND rt.transaction_date <= pla.need_by_date
          AND pha.authorization_status = 'APPROVED';
