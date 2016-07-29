DROP VIEW APPS.XX_XRTX_PO_DOC_SUPP_V30;

/* Formatted on 6/6/2016 4:55:23 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_DOC_SUPP_V30
(
   OPERATING_UNIT,
   SUPPLIER_NAME,
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
          a.supplier_name,
          A.YEAR,
          NVL (A.total_count, 0) total_cnt,
          NVL (b.incomplete_count, 0) incomplete_cnt,
          NVL (c.inprocess_count, 0) inprocess_cnt,
          NVL (d.req_reapproval_count, 0) req_reapproval_cnt,
          NVL (e.rejected_count, 0) rejected_cnt,
          NVL (f.pre_apprroved_count, 0) pre_apprroved_cnt,
          NVL (g.approved_count, 0) approved_cnt
     FROM xx_xrtx_po_doc_supp_v8 A,
          xx_xrtx_po_doc_supp_v9 b,
          xx_xrtx_po_doc_supp_v10 c,
          xx_xrtx_po_doc_supp_v11 d,
          xx_xrtx_po_doc_supp_v12 e,
          xx_xrtx_po_doc_supp_v13 f,
          xx_xrtx_po_doc_supp_v14 g
    WHERE     A.operating_unit = b.operating_unit(+)
          AND NVL (A.supplier_name, 0) = NVL (b.supplier_name(+), 0)
          AND A.YEAR = b.YEAR(+)
          AND A.operating_unit = c.operating_unit(+)
          AND NVL (A.supplier_name, 0) = NVL (c.supplier_name(+), 0)
          AND A.YEAR = c.YEAR(+)
          AND A.operating_unit = d.operating_unit(+)
          AND NVL (A.supplier_name, 0) = NVL (d.supplier_name(+), 0)
          AND A.YEAR = d.YEAR(+)
          AND A.operating_unit = e.operating_unit(+)
          AND NVL (A.supplier_name, 0) = NVL (e.supplier_name(+), 0)
          AND A.YEAR = e.YEAR(+)
          AND A.operating_unit = f.operating_unit(+)
          AND NVL (A.supplier_name, 0) = NVL (f.supplier_name(+), 0)
          AND A.YEAR = f.YEAR(+)
          AND A.operating_unit = g.operating_unit(+)
          AND NVL (A.supplier_name, 0) = NVL (g.supplier_name(+), 0)
          AND a.year = g.year(+);
