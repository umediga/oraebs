DROP VIEW APPS.XX_XRTX_PO_DOC_BUY_V29;

/* Formatted on 6/6/2016 4:56:13 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_DOC_BUY_V29
(
   OPERATING_UNIT,
   BUYER_NAME,
   YEAR,
   TOTAL_CNT,
   INCOMPLETE_CNT,
   INPROCESS_CNT,
   REQ_REAPPROVAL_CNT,
   REJECTED_CNT,
   PRE_APPRROVED_CNT,
   APPROVED_CNT
)
AS
   SELECT A.operating_unit,
          a.Buyer_name,
          A.YEAR,
          NVL (A.total_count, 0) total_cnt,
          NVL (b.incomplete_count, 0) incomplete_cnt,
          NVL (c.inprocess_count, 0) inprocess_cnt,
          NVL (d.req_reapproval_count, 0) req_reapproval_cnt,
          NVL (e.rejected_count, 0) rejected_cnt,
          NVL (f.pre_apprroved_count, 0) pre_apprroved_cnt,
          NVL (g.approved_count, 0) approved_cnt
     FROM xx_xrtx_po_doc_buy_v1 A,
          xx_xrtx_po_doc_buy_v2 b,
          xx_xrtx_po_doc_buy_v3 c,
          xx_xrtx_po_doc_buy_v4 d,
          xx_xrtx_po_doc_buy_v5 e,
          xx_xrtx_po_doc_buy_v6 f,
          xx_xrtx_po_doc_buy_v7 g
    WHERE     A.operating_unit = b.operating_unit(+)
          AND a.buyer_name = b.buyer_name(+)
          AND A.YEAR = b.YEAR(+)
          AND A.operating_unit = c.operating_unit(+)
          AND a.buyer_name = c.buyer_name(+)
          AND A.YEAR = c.YEAR(+)
          AND A.operating_unit = d.operating_unit(+)
          AND a.buyer_name = d.buyer_name(+)
          AND A.YEAR = d.YEAR(+)
          AND A.operating_unit = e.operating_unit(+)
          AND a.buyer_name = e.buyer_name(+)
          AND A.YEAR = e.YEAR(+)
          AND A.operating_unit = f.operating_unit(+)
          AND a.buyer_name = f.buyer_name(+)
          AND A.YEAR = f.YEAR(+)
          AND A.operating_unit = g.operating_unit(+)
          AND a.buyer_name = g.buyer_name(+)
          AND a.year = g.year(+);
