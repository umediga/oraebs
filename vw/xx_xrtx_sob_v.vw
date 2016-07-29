DROP VIEW APPS.XX_XRTX_SOB_V;

/* Formatted on 6/6/2016 4:54:12 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_SOB_V
(
   "SOB Name",
   "SOB Short Name",
   "SOB Description",
   ID_FLEX_STRUCTURE_CODE,
   "Period Set Name",
   "Periods/Year",
   "Year Type"
)
AS
   SELECT gsob.name "SOB Name",
          gsob.short_name "SOB Short Name",
          gsob.Description "SOB Description",
          fifs.id_flex_structure_code,
          gsob.period_set_name "Period Set Name",
          gpt.number_per_fiscal_year "Periods/Year",
          DECODE (gpt.year_type_in_name,  'F', 'Fiscal',  'C', 'Calendar')
             "Year Type"
     FROM GL_SETS_OF_BOOKS GSOB,
          GL_PERIODS_AND_TYPES_V gps,
          GL_PERIOD_TYPES gpt,
          fnd_id_flex_structures fifs
    WHERE     gsob.period_set_name = gps.period_set_name
          AND gpt.PERIOD_TYPE = gps.PERIOD_TYPE
          AND gsob.CHART_OF_ACCOUNTS_ID = fifs.id_flex_num
          AND id_flex_code = 'GLLE';
