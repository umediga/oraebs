DROP VIEW APPS.XXONTWSCORR_LINE_V;

/* Formatted on 6/6/2016 5:00:05 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXONTWSCORR_LINE_V
(
   HEADER_ID,
   LINE_ID,
   PO1_LINE_NO,
   PO1_QUANTITY,
   PO1_UOM,
   PO1_UNIT_PRICE,
   PO1_BASIS_UNIT_PRICE_CODE,
   PO1_PROD_ID_CODE1,
   PO1_PROD_ID_CODE1_VAL,
   PO1_PROD_ID_CODE2,
   PO1_PROD_ID_CODE2_VAL,
   PO1_PROD_ID_CODE3,
   PO1_PROD_ID_CODE3_VAL,
   PID_TYPE,
   PID_DESCRIPTION,
   REF_IDENTIFIER,
   REF_IDENTIFICATION,
   REF_DESCRIPTION,
   STATUS,
   ERROR_MSSG,
   ATTRIBUTE1,
   ATTRIBUTE2,
   ATTRIBUTE3,
   ATTRIBUTE4,
   DISCARD_REASON,
   DISCARD_CHK,
   ERR_FLAG
)
AS
   SELECT a.HEADER_ID,
          "LINE_ID",
          "PO1_LINE_NO",
          "PO1_QUANTITY",
          "PO1_UOM",
          "PO1_UNIT_PRICE",
          "PO1_BASIS_UNIT_PRICE_CODE",
          "PO1_PROD_ID_CODE1",
          "PO1_PROD_ID_CODE1_VAL",
          "PO1_PROD_ID_CODE2",
          "PO1_PROD_ID_CODE2_VAL",
          "PO1_PROD_ID_CODE3",
          "PO1_PROD_ID_CODE3_VAL",
          "PID_TYPE",
          "PID_DESCRIPTION",
          "REF_IDENTIFIER",
          a.REF_IDENTIFICATION,
          a.REF_DESCRIPTION,
          a.STATUS,
          a.ERROR_MSSG,
          a.ATTRIBUTE1,
          a.ATTRIBUTE2,
          a.ATTRIBUTE3,
          a.ATTRIBUTE4,
          DECODE (b.status,
                  'Discarded', 'Header Discarded-' || b.attribute5,
                  a.attribute5)
             DISCARD_REASON,
          DECODE (b.status,
                  'Discarded', 'Y',
                  DECODE (a.status, 'Discarded', 'Y', 'N'))
             DISCARD_CHK,
          DECODE ( (SELECT COUNT (1)
                      FROM xx_oe_order_ws_in_error_stg
                     WHERE line_id = a.line_id),
                  0, 'N',
                  'Y')
             "ERR_FLAG"
     FROM xx_oe_order_ws_in_line_stg a, xx_oe_order_ws_in_header_stg b
    WHERE a.header_id = b.header_id;
