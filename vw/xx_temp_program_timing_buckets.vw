DROP VIEW APPS.XX_TEMP_PROGRAM_TIMING_BUCKETS;

/* Formatted on 6/6/2016 4:58:01 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_TEMP_PROGRAM_TIMING_BUCKETS
(
   CONCURRENT_PROGRAM_ID,
   CONCURRENT_PROGRAM_NAME,
   TIME_TAKEN,
   B0_5,
   B5_15,
   B15_30,
   B30_45,
   B45_60,
   B60_90,
   B90_
)
AS
   SELECT concurrent_program_id,
          concurrent_program_name,
          time_taken,
          CASE WHEN bucket < 5 THEN 1 END "B0_5",                     --"0-5",
          CASE WHEN bucket >= 5 AND bucket < 15 THEN 1 END "B5_15",  --"5-15",
          CASE WHEN bucket >= 15 AND bucket < 30 THEN 1 END "B15_30", --"15-30",
          CASE WHEN bucket >= 30 AND bucket < 45 THEN 1 END "B30_45", --"30-45",
          CASE WHEN bucket >= 45 AND bucket < 60 THEN 1 END "B45_60", --"45-60",
          CASE WHEN bucket >= 60 AND bucket < 90 THEN 1 END "B60_90", --"60-90",
          CASE WHEN bucket >= 90 THEN 1 END "B90_"                     --">90"
     FROM xx_temp_program_timings;
