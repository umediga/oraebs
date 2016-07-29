DROP VIEW APPS.XX_XRTX_OPR_UNITS123_V;

/* Formatted on 6/6/2016 4:56:35 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_OPR_UNITS123_V
(
   "Organization Code",
   "Description"
)
AS
   SELECT b.short_code "Organization Code", b.name "Description"
     FROM apps.hr_operating_units b;
