DROP VIEW APPS.XX_OM_SURGEON_DATA_V;

/* Formatted on 6/6/2016 4:58:17 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_OM_SURGEON_DATA_V
(
   REC_ID,
   NPI,
   SURGEON_NAME,
   ACTIVE_FLAG,
   END_DATE
)
AS
   SELECT rec_id,
          npi,
          surgeon_name,
          'Y' active_flag,
          NULL end_date
     FROM XX_OM_NONNPI_SURGEONS
   UNION
   SELECT TO_CHAR (rec_id),
          TO_CHAR (npi),
             doctors_last_name
          || ', '
          || doctors_first_name
          || ' '
          || doctors_middle_name,
          active_flag,
          end_date
     FROM XXINTG_HCP_INT_MAIN;


GRANT SELECT ON APPS.XX_OM_SURGEON_DATA_V TO XXAPPSREAD;
