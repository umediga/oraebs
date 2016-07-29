DROP VIEW APPS.XXX_LEDGER_STATUS_V;

/* Formatted on 6/6/2016 5:00:02 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXX_LEDGER_STATUS_V
(
   LEDGER_NAME,
   STATUS,
   PERIOD_NAME,
   PERIOD_END_DATE
)
AS
     SELECT DISTINCT a.ledger_name,
                     a.status,
                     a.period_name,
                     a.Period_end_date
       FROM (SELECT led.name ledger_name,
                    UPPER (
                       DECODE (gps.CLOSING_STATUS,
                               'O', 'OPEN',
                               'F', 'FUTURE ENTRY',
                               'W', 'Close Pending',
                               'C', 'Closed',
                               'N', 'Not Opened',
                               CLOSING_STATUS))
                       STATUS,
                    gps.period_name period_name,
                    TO_CHAR (gps.end_date, 'DD-Mon-YYYY') Period_end_date
               FROM apps.GL_PERIOD_STATUSES gps,
                    apps.fnd_application_vl apl,
                    apps.GL_LEDGERS led
              WHERE     gps.set_of_books_id = led.ledger_id
                    AND gps.application_id = apl.application_id
                    AND apl.application_id = 101 --(222, 200, 101, 201,140, 300,660,275)
                                                --and UPPER(gps.period_name) = ''
                                                /*union all
                                                select gll.name ledger_name,
                                                       --UPPER(inp.STATUS) STATUS,
                                                 UPPER(decode(inp.open_flag,'N','Closed','Y','Open','Others')) STATUS,
                                                       inp.period_name period_name,
                                                      to_char(inp.Period_close_date,'DD-Mon-YYYY') Period_end_date
                                                  FROM apps.ORG_ACCT_PERIODS inp
                                                      ,apps.ORG_ORGANIZATION_DEFINITIONS OOD
                                                      ,apps.gl_ledgers gll
                                                WHERE INP.ORGANIZATION_ID = OOD.ORGANIZATION_ID
                                                      --and UPPER(inp.period_name) = ''
                                                      and OOD.set_of_books_id =gll.ledger_id
                                                union all
                                                select gll.name ledger_name,
                                                       to_char(DECODE(fap.PERIOD_CLOSE_DATE, null,'OPEN','CLOSED')) STATUS,
                                                       fap.period_name period_name,
                                                      to_char(fap.period_close_date,'DD-Mon-YYYY') Period_end_date
                                                from apps.fa_deprn_periods FAP,
                                                     apps.fa_book_controls fbc,
                                                     apps.gl_ledgers gll
                                                WHERE fap.book_type_code = fbc.book_type_code
                                                  and fbc.set_of_books_id = gll.ledger_id*/
                                                --and UPPER(fap.period_name) = ''
            ) a
   ORDER BY a.ledger_name;
