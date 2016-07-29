DROP VIEW APPS.XX_XRTX_PO_REQ_TXN_SUPP_PUR;

/* Formatted on 6/6/2016 4:54:19 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_TXN_SUPP_PUR
(
   SUPPLIER_NAME,
   YEAR,
   TOTAL_CNT,
   CANCEL_CNT,
   OPEN_CNT,
   CLOSED_CNT
)
AS
   SELECT A.supplier_name,
          A.YEAR,
          NVL (A.Total_count, 0) Total_cnt,
          NVL (b.cancel_count, 0) cancel_cnt,
          NVL (c.open_count, 0) open_cnt,
          NVL (d.closed_count, 0) closed_cnt
     FROM xx_xrtx_po_req_txn_supp_pu_tot A,
          xx_xrtx_po_req_txn_supp_pu_can b,
          xx_xrtx_po_req_txn_supp_pu_opn c,
          xx_xrtx_po_req_txn_supp_pu_cls d
    WHERE     NVL (A.supplier_name, 0) = NVL (b.supplier_name(+), 0)
          AND A.YEAR = b.YEAR(+)
          AND NVL (A.supplier_name, 0) = NVL (c.supplier_name(+), 0)
          AND A.YEAR = c.YEAR(+)
          AND NVL (A.supplier_name, 0) = NVL (d.supplier_name(+), 0)
          AND A.year = d.year(+);
