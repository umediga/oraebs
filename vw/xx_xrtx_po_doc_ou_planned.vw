DROP VIEW APPS.XX_XRTX_PO_DOC_OU_PLANNED;

/* Formatted on 6/6/2016 4:56:01 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_DOC_OU_PLANNED
(
   OPERATING_UNIT,
   YEAR,
   TOTAL_CNT,
   CANCEL_CNT,
   OPEN_CNT,
   CLOSED_CNT
)
AS
   SELECT A.operating_unit,
          A.YEAR,
          NVL (A.Total_count, 0) Total_cnt,
          NVL (b.cancel_count, 0) cancel_cnt,
          NVL (c.open_count, 0) open_cnt,
          NVL (d.closed_count, 0) closed_cnt
     FROM xx_xrtx_po_doc_ou_total3 A,
          xx_xrtx_po_doc_ou_cancel3 b,
          xx_xrtx_po_doc_ou_open3 c,
          xx_xrtx_po_doc_ou_closed3 d
    WHERE     A.operating_unit = b.operating_unit(+)
          AND A.YEAR = b.YEAR(+)
          AND A.operating_unit = c.operating_unit(+)
          AND A.YEAR = c.YEAR(+)
          AND A.operating_unit = d.operating_unit(+)
          AND A.YEAR = d.YEAR(+);
