DROP VIEW APPS.XX_XRTX_PO_REQ_TXN_REQ_PUR;

/* Formatted on 6/6/2016 4:54:24 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_TXN_REQ_PUR
(
   REQUESTOR_NAME,
   YEAR,
   TOTAL_CNT,
   CANCEL_CNT,
   OPEN_CNT,
   CLOSED_CNT
)
AS
   SELECT A.requestor_name,
          A.YEAR,
          NVL (A.Total_count, 0) Total_cnt,
          NVL (b.cancel_count, 0) cancel_cnt,
          NVL (c.open_count, 0) open_cnt,
          NVL (d.closed_count, 0) closed_cnt
     FROM xx_xrtx_po_req_txn_req_pu_tot A,
          xx_xrtx_po_req_txn_req_pu_can b,
          xx_xrtx_po_req_txn_req_pu_open c,
          xx_xrtx_po_req_txn_req_pu_cls d
    WHERE     A.requestor_name = b.requestor_name(+)
          AND A.year = b.year(+)
          AND A.requestor_name = c.requestor_name(+)
          AND A.YEAR = c.YEAR(+)
          AND A.requestor_name = d.requestor_name(+)
          AND A.year = d.year(+);
