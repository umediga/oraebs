DROP VIEW APPS.XX_XRTX_PO_DELAY_V;

/* Formatted on 6/6/2016 4:56:31 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_DELAY_V
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
     FROM po_line_locations_all pla,
          po_headers_all pha,
          rcv_transactions rt,
          hr_all_organization_units a
    WHERE     pha.po_header_id = pla.po_header_id
          AND rt.po_line_location_id = pla.line_location_id
          AND pha.org_id = a.organization_id
          AND pla.need_by_date < rt.transaction_date
          AND pha.authorization_status = 'APPROVED';
