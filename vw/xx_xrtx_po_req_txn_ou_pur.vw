DROP VIEW APPS.XX_XRTX_PO_REQ_TXN_OU_PUR;

/* Formatted on 6/6/2016 4:54:56 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_TXN_OU_PUR
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
     FROM xx_xrtx_po_req_txn_ou_pur_tot A,
          xx_xrtx_po_req_txn_ou_pur_can b,
          xx_xrtx_po_req_txn_ou_pur_open c,
          xx_xrtx_po_req_txn_ou_pur_cls d
    WHERE     A.operating_unit = b.operating_unit(+)
          AND A.year = b.year(+)
          AND a.operating_unit = c.operating_unit(+)
          AND A.YEAR = c.YEAR(+)
          AND A.operating_unit = d.operating_unit(+)
          AND A.YEAR = d.YEAR(+);
