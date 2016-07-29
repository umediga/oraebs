DROP VIEW APPS.XX_XRTX_WIP_JOB_TYPE_V;

/* Formatted on 6/6/2016 4:54:03 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_WIP_JOB_TYPE_V
(
   INVENTORY_ORGANIZATION,
   YEAR,
   JOB_TYPE,
   CREATION_DATE,
   A,
   B,
   C,
   D,
   E,
   F,
   G,
   H,
   I,
   J,
   K,
   L
)
AS
   SELECT hou.name inventory_organization,
          TO_CHAR (TRUNC (wdj.creation_date), 'YYYY') YEAR,
          DECODE (wdj.job_type, '1', 'Standard', 'Non-Standard') job_type,
          TRUNC (wdj.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM wdj.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM wdj.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM wdj.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM wdj.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM wdj.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM wdj.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM wdj.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM wdj.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM wdj.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM wdj.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM wdj.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM wdj.creation_date) = 12 THEN 1 END L --"DEC",
     FROM wip_discrete_jobs wdj, hr_all_organization_units hou
    WHERE wdj.organization_id = hou.organization_id;
