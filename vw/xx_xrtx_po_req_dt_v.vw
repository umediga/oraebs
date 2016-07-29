DROP VIEW APPS.XX_XRTX_PO_REQ_DT_V;

/* Formatted on 6/6/2016 4:55:01 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_DT_V
(
   CAL_MON,
   CREATION_DATE,
   YEAR,
   OPERATING_UNIT,
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
   SELECT TO_CHAR (TRUNC (prha.creation_date), 'MON') cal_mon,
          TRUNC (prha.creation_date) creation_date,
          TO_CHAR (TRUNC (prha.creation_date), 'YYYY') YEAR,
          hou.name operating_unit,
          CASE WHEN EXTRACT (MONTH FROM prha.approved_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM prha.approved_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM prha.approved_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM prha.approved_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM prha.approved_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM prha.approved_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM prha.approved_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM prha.approved_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM prha.approved_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM prha.approved_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM prha.approved_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM prha.approved_date) = 12 THEN 1 END L --"DEC",
     FROM PO_REQUISITION_HEADERS_ALL prha,
          PO_REQUISITION_LINES_ALL prla,
          hr_all_organization_units hou
    WHERE     prla.cancel_flag = 'N'
          AND prha.requisition_header_id = prla.requisition_header_id
          AND prha.ORG_ID = hou.ORGANIZATION_ID
          AND prha.creation_date < prha.approved_date
          AND prla.destination_type_code = 'INVENTORY'
          AND NVL (prla.closed_code, 'OPEN') <> 'OPEN'
          AND TRUNC (prha.creation_date) BETWEEN TO_DATE (
                                                    (   '01-JAN-'
                                                     || (  TO_CHAR (SYSDATE,
                                                                    'YYYY')
                                                         - 3)),
                                                    'DD-MON-YYYY')
                                             AND SYSDATE;
