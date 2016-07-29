DROP VIEW APPS.XX_XRTX_AP_FSP2_V;

/* Formatted on 6/6/2016 4:57:56 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AP_FSP2_V
(
   "Opearting Unit",
   "Set OF Books",
   EXPENSE_CHECK_ADDRESS_FLAG,
   USE_POSITIONS_FLAG,
   USER_DEFINED_VENDOR_NUM_CODE
)
AS
   SELECT b.name "Opearting Unit",
          c.name "Set OF Books",                --,EXPENSE_CHECK_ADDRESS_FLAG,
          DECODE (a.EXPENSE_CHECK_ADDRESS_FLAG,
                  'O', 'OFFICE',
                  'H', 'HOME',
                  'HOME')
             EXPENSE_CHECK_ADDRESS_FLAG,
          A.USE_POSITIONS_FLAG,
          A.USER_DEFINED_VENDOR_NUM_CODE
     FROM financials_system_params_all a,
          hr_operating_units b,
          GL_SETS_OF_BOOKS c
    WHERE     a.ORG_ID = b.organization_id
          AND a.SET_OF_BOOKS_ID = c.SET_OF_BOOKS_ID(+);
