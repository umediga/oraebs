DROP VIEW APPS.XX_XRTX_PO_DOC_BUY_PLANNED;

/* Formatted on 6/6/2016 4:56:24 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_DOC_BUY_PLANNED
(
   BUYER_NAME,
   YEAR,
   TOTAL_CNT,
   CANCEL_CNT,
   OPEN_CNT,
   CLOSED_CNT
)
AS
     SELECT A.Buyer_name,
            A.YEAR,
            NVL (A.Total_count, 0) Total_cnt,
            NVL (b.cancel_count, 0) cancel_cnt,
            NVL (c.open_count, 0) open_cnt,
            NVL (d.closed_count, 0) closed_cnt
       FROM xx_xrtx_po_doc_buy_total3 A,
            xx_xrtx_po_doc_buy_cancel3 b,
            xx_xrtx_po_doc_buy_open3 c,
            xx_xrtx_po_doc_buy_closed3 d
      WHERE     A.buyer_name = b.buyer_name(+)
            AND A.YEAR = b.YEAR(+)
            AND A.buyer_name = c.buyer_name(+)
            AND A.YEAR = c.YEAR(+)
            AND A.buyer_name = d.buyer_name(+)
            AND A.YEAR = d.YEAR(+)
   ORDER BY 2 DESC;
