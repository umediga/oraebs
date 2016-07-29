DROP VIEW APPS.XX_XRTX_AP_FSP_V;

/* Formatted on 6/6/2016 4:57:56 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AP_FSP_V
(
   "Opearting Unit",
   FUTUREPERIODS,
   ACCTS_PAY_CODE_COMBINATION_ID,
   "Liability",
   PREPAY_CODE_COMBINATION_ID,
   "Prepayment",
   FUTURE_DATED_PAYMENT_CCID,
   "Bills Payable",
   DISC_TAKEN_CODE_COMBINATION_ID,
   "Discount Taken",
   RATE_VAR_GAIN_CCID,
   "PO Rate Variance Gain",
   RATE_VAR_LOSS_CCID,
   "PO Rate Variance Loss",
   EXPENSE_CLEARING_CCID,
   "Expenses Clearing",
   MISC_CHARGE_CCID,
   "Miscellaneous",
   RETAINAGE_CODE_COMBINATION_ID,
   "Retainage"
)
AS
   SELECT b.name "Opearting Unit",
          a.FUTURE_PERIOD_LIMIT FUTUREPERIODS,
          a.ACCTS_PAY_CODE_COMBINATION_ID,
             c.segment1
          || '.'
          || c.segment2
          || '.'
          || c.segment3
          || '.'
          || c.segment4
          || '.'
          || c.segment5
          || '.'
          || c.segment6
          || '.'
          || c.segment7
          || c.segment8
          || '.'
          || c.segment9
          || '.'
          || c.segment10
             "Liability",
          a.PREPAY_CODE_COMBINATION_ID,
             d.segment1
          || '.'
          || d.segment2
          || '.'
          || d.segment3
          || '.'
          || d.segment4
          || '.'
          || d.segment5
          || '.'
          || d.segment6
          || '.'
          || d.segment7
          || d.segment8
          || '.'
          || d.segment9
          || '.'
          || d.segment10
             "Prepayment",
          a.FUTURE_DATED_PAYMENT_CCID,
             e.segment1
          || '.'
          || e.segment2
          || '.'
          || e.segment3
          || '.'
          || e.segment4
          || '.'
          || e.segment5
          || '.'
          || e.segment6
          || '.'
          || e.segment7
          || e.segment8
          || '.'
          || e.segment9
          || '.'
          || e.segment10
             "Bills Payable",
          a.DISC_TAKEN_CODE_COMBINATION_ID,
             f.segment1
          || '.'
          || f.segment2
          || '.'
          || f.segment3
          || '.'
          || f.segment4
          || '.'
          || f.segment5
          || '.'
          || f.segment6
          || '.'
          || f.segment7
          || f.segment8
          || '.'
          || f.segment9
          || '.'
          || f.segment10
             "Discount Taken",
          a.RATE_VAR_GAIN_CCID,
             g.segment1
          || '.'
          || g.segment2
          || '.'
          || g.segment3
          || '.'
          || g.segment4
          || '.'
          || g.segment5
          || '.'
          || g.segment6
          || '.'
          || g.segment7
          || g.segment8
          || '.'
          || g.segment9
          || '.'
          || g.segment10
             "PO Rate Variance Gain",
          a.RATE_VAR_LOSS_CCID,
             h.segment1
          || '.'
          || h.segment2
          || '.'
          || h.segment3
          || '.'
          || h.segment4
          || '.'
          || h.segment5
          || '.'
          || h.segment6
          || '.'
          || h.segment7
          || h.segment8
          || '.'
          || h.segment9
          || '.'
          || h.segment10
             "PO Rate Variance Loss",
          a.EXPENSE_CLEARING_CCID,
             i.segment1
          || '.'
          || i.segment2
          || '.'
          || i.segment3
          || '.'
          || i.segment4
          || '.'
          || i.segment5
          || '.'
          || i.segment6
          || '.'
          || i.segment7
          || i.segment8
          || '.'
          || i.segment9
          || '.'
          || i.segment10
             "Expenses Clearing",
          a.MISC_CHARGE_CCID,
             j.segment1
          || '.'
          || j.segment2
          || '.'
          || j.segment3
          || '.'
          || j.segment4
          || '.'
          || j.segment5
          || '.'
          || j.segment6
          || '.'
          || j.segment7
          || j.segment8
          || '.'
          || j.segment9
          || '.'
          || j.segment10
             "Miscellaneous",
          a.RETAINAGE_CODE_COMBINATION_ID,
             k.segment1
          || '.'
          || k.segment2
          || '.'
          || k.segment3
          || '.'
          || k.segment4
          || '.'
          || k.segment5
          || '.'
          || k.segment6
          || '.'
          || k.segment7
          || k.segment8
          || '.'
          || k.segment9
          || '.'
          || k.segment10
             "Retainage"
     FROM financials_system_params_all a,
          hr_operating_units b,
          GL_CODE_COMBINATIONS c,
          GL_CODE_COMBINATIONS d,
          GL_CODE_COMBINATIONS e,
          GL_CODE_COMBINATIONS f,
          GL_CODE_COMBINATIONS g,
          GL_CODE_COMBINATIONS h,
          GL_CODE_COMBINATIONS i,
          GL_CODE_COMBINATIONS j,
          GL_CODE_COMBINATIONS k
    WHERE     a.ORG_ID = b.organization_id
          AND a.ACCTS_PAY_CODE_COMBINATION_ID = c.code_combination_id(+)
          AND a.PREPAY_CODE_COMBINATION_ID = d.code_combination_id(+)
          AND a.FUTURE_DATED_PAYMENT_CCID = e.code_combination_id(+)
          AND a.DISC_TAKEN_CODE_COMBINATION_ID = f.code_combination_id(+)
          AND a.RATE_VAR_GAIN_CCID = g.code_combination_id(+)
          AND a.RATE_VAR_LOSS_CCID = h.code_combination_id(+)
          AND a.EXPENSE_CLEARING_CCID = i.code_combination_id(+)
          AND a.MISC_CHARGE_CCID = j.code_combination_id(+)
          AND a.RETAINAGE_CODE_COMBINATION_ID = k.code_combination_id(+);
