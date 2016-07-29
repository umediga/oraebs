DROP VIEW APPS.XX_XRTX_PO_REQ_DELAY_V;

/* Formatted on 6/6/2016 4:55:01 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_DELAY_V
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
   H
)
AS
   SELECT TO_CHAR (TRUNC (prha.creation_date), 'MON') cal_mon,
          TRUNC (prha.creation_date) creation_date,
          TO_CHAR (TRUNC (prha.creation_date), 'YYYY') YEAR,
          hou.name operating_unit,
          CASE
             WHEN ROUND ( (prha.approved_date - prha.creation_date) * 24, 2) BETWEEN 0
                                                                                 AND 24
             THEN
                1
          END
             "A",
          CASE
             WHEN ROUND ( (prha.approved_date - prha.creation_date) * 24, 2) BETWEEN 24
                                                                                 AND 48
             THEN
                1
          END
             "B",
          CASE
             WHEN ROUND ( (prha.approved_date - prha.creation_date) * 24, 2) BETWEEN 48
                                                                                 AND 72
             THEN
                1
          END
             "C",
          CASE
             WHEN ROUND ( (prha.approved_date - prha.creation_date) * 24, 2) BETWEEN 72
                                                                                 AND 168
             THEN
                1
          END
             "D",
          CASE
             WHEN ROUND ( (prha.approved_date - prha.creation_date) * 24, 2) BETWEEN 168
                                                                                 AND 336
             THEN
                1
          END
             "E",
          CASE
             WHEN ROUND ( (prha.approved_date - prha.creation_date) * 24, 2) BETWEEN 336
                                                                                 AND 504
             THEN
                1
          END
             "F",
          CASE
             WHEN ROUND ( (prha.approved_date - prha.creation_date) * 24, 2) BETWEEN 504
                                                                                 AND 672
             THEN
                1
          END
             "G",
          CASE
             WHEN ROUND ( (prha.approved_date - prha.creation_date) * 24, 2) >
                     672
             THEN
                1
          END
             "H"
     FROM PO_REQUISITION_HEADERS_ALL prha,
          PO_REQUISITION_LINES_ALL prla,
          hr_all_organization_units hou
    WHERE     NVL (prla.cancel_flag, 'Y') = 'N'
          AND prha.requisition_header_id = prla.requisition_header_id
          AND prha.ORG_ID = hou.ORGANIZATION_ID
          AND prha.creation_date < prha.approved_date
          AND prla.destination_type_code = 'INVENTORY'
          AND NVL (prla.closed_code, 'OPEN') <> 'OPEN';
