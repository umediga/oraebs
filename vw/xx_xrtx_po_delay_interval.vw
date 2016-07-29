DROP VIEW APPS.XX_XRTX_PO_DELAY_INTERVAL;

/* Formatted on 6/6/2016 4:56:31 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_DELAY_INTERVAL
(
   OPERATING_UNIT,
   CAL_MON,
   NEED_BY_DATE,
   YEAR,
   D,
   E,
   F,
   G,
   H,
   I,
   J,
   K
)
AS
     SELECT A.NAME operating_unit,
            TO_CHAR (pla.need_by_date, 'MON') cal_mon,
            TRUNC (pla.need_by_date) need_by_date,
            EXTRACT (YEAR FROM rt.transaction_date) YEAR,
            CASE
               WHEN     ROUND ( (rt.transaction_date - pla.need_by_date) * 24,
                               2) > 0
                    AND ROUND ( (rt.transaction_date - pla.need_by_date) * 24,
                               2) <= 24
               THEN
                  1
            END
               "D",
            CASE
               WHEN     ROUND ( (rt.transaction_date - pla.need_by_date) * 24,
                               2) > 24
                    AND ROUND ( (rt.transaction_date - pla.need_by_date) * 24,
                               2) <= 48
               THEN
                  1
            END
               "E",
            CASE
               WHEN     ROUND ( (rt.transaction_date - pla.need_by_date) * 24,
                               2) > 48
                    AND ROUND ( (rt.transaction_date - pla.need_by_date) * 24,
                               2) <= 72
               THEN
                  1
            END
               "F",
            CASE
               WHEN     ROUND ( (rt.transaction_date - pla.need_by_date) * 24,
                               2) > 72
                    AND ROUND ( (rt.transaction_date - pla.need_by_date) * 24,
                               2) <= 168
               THEN
                  1
            END
               "G",
            CASE
               WHEN     ROUND ( (rt.transaction_date - pla.need_by_date) * 24,
                               2) > 168
                    AND ROUND ( (rt.transaction_date - pla.need_by_date) * 24,
                               2) <= 336
               THEN
                  1
            END
               "H",
            CASE
               WHEN     ROUND ( (rt.transaction_date - pla.need_by_date) * 24,
                               2) > 336
                    AND ROUND ( (rt.transaction_date - pla.need_by_date) * 24,
                               2) <= 504
               THEN
                  1
            END
               "I",
            CASE
               WHEN     ROUND ( (rt.transaction_date - pla.need_by_date) * 24,
                               2) > 504
                    AND ROUND ( (rt.transaction_date - pla.need_by_date) * 24,
                               2) <= 672
               THEN
                  1
            END
               "J",
            CASE
               WHEN ROUND ( (rt.transaction_date - pla.need_by_date) * 24, 2) >
                       672
               THEN
                  1
            END
               "K"
       FROM po_line_locations_all pla,
            po_headers_all pha,
            rcv_transactions rt,
            hr_all_organization_units a
      WHERE     pha.po_header_id = pla.po_header_id
            AND rt.po_line_location_id = pla.line_location_id
            AND pha.org_id = a.organization_id
            AND pla.need_by_date < rt.transaction_date
            AND pha.authorization_status = 'APPROVED'
   ORDER BY 1, 2, 3;
