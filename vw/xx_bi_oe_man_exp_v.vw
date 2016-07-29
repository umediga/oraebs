DROP VIEW APPS.XX_BI_OE_MAN_EXP_V;

/* Formatted on 6/6/2016 4:59:22 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_OE_MAN_EXP_V
(
   WEEKNO,
   RECEIPTNO,
   VENDOR,
   INVOICE,
   BOXES,
   WEIGHT,
   BOXFR,
   BOX_TO,
   AE_NU,
   VALUE_1,
   VALUE,
   CURRENCY,
   PLAN_ID
)
AS
     SELECT character1 weekno,
            character2 receiptno,
            character3 vendor,
            character4 invoice,
            character5 boxes,
            character6 weight,
            character7 boxfr,
            character8 boxto,
            character9 ae_no,
            character10 VALUE,
            character11 "$ Value",
            character12 "Currency",
            plan_id
       FROM apps.qa_results
      WHERE plan_id = 38109
   --AND character1 =
   ORDER BY 1, 4;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_OE_MAN_EXP_V FOR APPS.XX_BI_OE_MAN_EXP_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_OE_MAN_EXP_V TO ETLEBSUSER;
