DROP VIEW APPS.XX_BI_R2R_JOURNAL_V;

/* Formatted on 6/6/2016 4:59:02 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_R2R_JOURNAL_V
(
   ACCOUNT_NUMBER,
   ACCOUNT_DESCRIPTION,
   SOURCE,
   PERIOD,
   LINE_NUMBER,
   JOURNAL_DESCRIPTION,
   JOURNAL_CATEGORY,
   DOCUMENT_NUMBER,
   ENTERED_DR_AMOUNT,
   ENTERED_CR_AMOUNT,
   ACCOUNTED_DR_AMOUNT,
   ACCOUNTED_CR_AMOUNT,
   CURRENCY,
   CREATION_DATE,
   CREATED_BY,
   BATCH_NAME,
   BATCH_DESCRIPTION,
   BATCH_DATE,
   ACCOUNTING_DATE,
   APPROVED_BY,
   APPROVED_BY_EMP_ID
)
AS
     SELECT glcc.concatenated_segments account_number,
            gjl.description account_description,
            gjh.je_source SOURCE,
            gjh.period_name period,
            gjl.je_line_num line_number,
            gjh.description journal_description,
            gjh.je_category journal_category,
            gjh.doc_sequence_value document_number,
            gjl.entered_dr entered_dr_amount,
            gjl.entered_cr entered_cr_amount,
            gjl.accounted_dr accounted_dr_amount,
            gjl.accounted_cr accounted_cr_amount,
            gjh.currency_code currency,
            gjh.creation_date creation_date,
            fu.user_name created_by,
            gjb.NAME batch_name,
            gjb.description batch_description,
            gjb.creation_date batch_date,
            gjb.posted_date accounting_date,
            (SELECT user_name
               FROM apps.fnd_user fu
              WHERE fu.employee_id = gjb.approver_employee_id)
               approved_by,
            (SELECT employee_id
               FROM apps.fnd_user fu
              WHERE fu.employee_id = gjb.approver_employee_id)
               approved_by_emp_id
       FROM apps.gl_je_batches gjb,
            apps.gl_je_headers gjh,
            apps.gl_je_lines gjl,
            apps.gl_code_combinations_kfv glcc,
            apps.gl_ledgers gll,
            apps.fnd_user fu
      WHERE     gjb.je_batch_id = gjh.je_batch_id
            AND gjh.je_header_id = gjl.je_header_id
            AND glcc.code_combination_id = gjl.code_combination_id
            AND gll.ledger_id = gjh.ledger_id
            AND gll.chart_of_accounts_id = glcc.chart_of_accounts_id
            AND gjh.created_by = fu.user_id
            AND UPPER (gjh.je_source) IN ('MANUAL', 'SPREADSHEET')
            AND TRUNC (gjl.effective_date) BETWEEN TRUNC (
                                                      TO_DATE ('01-JAN-2014',
                                                               'DD-MON-YYYY'))
                                               AND TRUNC (
                                                      TO_DATE ('30-JUN-2014',
                                                               'DD-MON-YYYY'))
   ORDER BY gjh.doc_sequence_value, gjl.je_line_num;
