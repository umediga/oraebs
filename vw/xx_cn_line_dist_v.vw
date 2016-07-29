DROP VIEW APPS.XX_CN_LINE_DIST_V;

/* Formatted on 6/6/2016 4:58:50 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_CN_LINE_DIST_V
(
   TRX_LINE_ID,
   ORG_ID,
   CODE_COMBINATION
)
AS
     SELECT rctla.customer_trx_line_id,
            rctla.org_id,
            MAX (
                  gcc.segment1
               || '-'
               || gcc.segment2
               || '-'
               || gcc.segment3
               || '-'
               || gcc.segment4
               || '-'
               || gcc.segment5
               || '-'
               || gcc.segment6
               || '-'
               || gcc.segment7
               || '-'
               || gcc.segment8)
               Code_Combination
       FROM ra_customer_trx_lines_all rctla,
            ra_cust_trx_line_gl_dist_all rctglda,
            gl_code_combinations gcc
      WHERE     rctla.line_type = 'LINE'
            AND rctla.customer_trx_line_id = rctglda.customer_trx_line_id
            AND rctglda.account_class = 'REV'
            AND gcc.code_combination_id = rctglda.code_combination_id
   GROUP BY rctla.customer_trx_line_id, rctla.org_id;
