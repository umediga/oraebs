DROP VIEW APPS.XX_XRTX_PO_REQ_TXN_OU_RQST_V19;

/* Formatted on 6/6/2016 4:54:49 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_TXN_OU_RQST_V19
(
   OPERATING_UNIT,
   REQUESTOR_NAME,
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
          a.requestor_name,
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
     FROM xx_xrtx_po_req_txn_ou_rqst_v1 A,
          xx_xrtx_po_req_txn_ou_rqst_v2 b,
          xx_xrtx_po_req_txn_ou_rqst_v3 c,
          xx_xrtx_po_req_txn_ou_rqst_v4 d,
          xx_xrtx_po_req_txn_ou_rqst_v5 e,
          xx_xrtx_po_req_txn_ou_rqst_v6 f,
          xx_xrtx_po_req_txn_ou_rqst_v7 g,
          xx_xrtx_po_req_txn_ou_rqst_v8 h,
          xx_xrtx_po_req_txn_ou_rqst_v9 i
    WHERE     A.operating_unit = b.operating_unit(+)
          AND A.requestor_name = b.requestor_name(+)
          AND A.year = b.year(+)
          AND A.operating_unit = c.operating_unit(+)
          AND A.requestor_name = c.requestor_name(+)
          AND A.year = c.year(+)
          AND A.operating_unit = d.operating_unit(+)
          AND A.requestor_name = d.requestor_name(+)
          AND A.YEAR = d.YEAR(+)
          AND A.operating_unit = e.operating_unit(+)
          AND A.requestor_name = e.requestor_name(+)
          AND A.year = e.year(+)
          AND A.operating_unit = f.operating_unit(+)
          AND A.requestor_name = f.requestor_name(+)
          AND A.year = f.year(+)
          AND A.operating_unit = g.operating_unit(+)
          AND A.requestor_name = g.requestor_name(+)
          AND A.YEAR = g.YEAR(+)
          AND A.operating_unit = h.operating_unit(+)
          AND A.requestor_name = h.requestor_name(+)
          AND A.year = h.year(+)
          AND A.operating_unit = i.operating_unit(+)
          AND A.requestor_name = i.requestor_name(+)
          AND A.year = i.year(+);
