DROP VIEW APPS.XX_XRTX_PO_REQ_TXN_OU_SUPP_V19;

/* Formatted on 6/6/2016 4:54:40 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_TXN_OU_SUPP_V19
(
   OPERATING_UNIT,
   SUPPLIER_NAME,
   YEAR,
   TOTAL_CNT,
   INCOMPLETE_CNT,
   INPROCESS_CNT,
   CANCELLED_CNT,
   REJECTED_CNT,
   APPROVED_CNT,
   PRE_APPROVED_CNT,
   RETURNED_CNT,
   SYSTEM_SAVED_CNT
)
AS
   SELECT A.operating_unit,
          a.supplier_name,
          A.YEAR,
          NVL (A.Total_count, 0) Total_cnt,
          NVL (b.Incomplete_count, 0) incomplete_cnt,
          NVL (c.inprocess_count, 0) inprocess_cnt,
          NVL (d.cancelled_count, 0) cancelled_cnt,
          NVL (e.rejected_count, 0) rejected_cnt,
          NVL (f.approved_count, 0) approved_cnt,
          NVL (g.pre_approved_count, 0) pre_approved_cnt,
          NVL (h.returned_count, 0) returned_cnt,
          NVL (i.system_saved_count, 0) system_saved_cnt
     FROM xx_xrtx_po_req_txn_ou_supp_v1 A,
          xx_xrtx_po_req_txn_ou_supp_v2 b,
          xx_xrtx_po_req_txn_ou_supp_v3 c,
          xx_xrtx_po_req_txn_ou_supp_v4 d,
          xx_xrtx_po_req_txn_ou_supp_v5 e,
          xx_xrtx_po_req_txn_ou_supp_v6 f,
          xx_xrtx_po_req_txn_ou_supp_v7 g,
          xx_xrtx_po_req_txn_ou_supp_v8 h,
          xx_xrtx_po_req_txn_ou_supp_v9 i
    WHERE     A.operating_unit = b.operating_unit(+)
          AND NVL (A.supplier_name, 0) = NVL (b.supplier_name(+), 0)
          AND A.year = b.year(+)
          AND A.operating_unit = c.operating_unit(+)
          AND NVL (A.supplier_name, 0) = NVL (c.supplier_name(+), 0)
          AND A.year = c.year(+)
          AND A.operating_unit = d.operating_unit(+)
          AND NVL (A.supplier_name, 0) = NVL (d.supplier_name(+), 0)
          AND A.YEAR = d.YEAR(+)
          AND A.operating_unit = e.operating_unit(+)
          AND NVL (A.supplier_name, 0) = NVL (e.supplier_name(+), 0)
          AND A.year = e.year(+)
          AND A.operating_unit = f.operating_unit(+)
          AND NVL (A.supplier_name, 0) = NVL (f.supplier_name(+), 0)
          AND A.year = f.year(+)
          AND A.operating_unit = g.operating_unit(+)
          AND NVL (A.supplier_name, 0) = NVL (g.supplier_name(+), 0)
          AND A.YEAR = g.YEAR(+)
          AND A.operating_unit = h.operating_unit(+)
          AND NVL (A.supplier_name, 0) = NVL (h.supplier_name(+), 0)
          AND A.year = h.year(+)
          AND A.operating_unit = i.operating_unit(+)
          AND NVL (A.supplier_name, 0) = NVL (i.supplier_name(+), 0)
          AND A.year = i.year(+);
