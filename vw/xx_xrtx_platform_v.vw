DROP VIEW APPS.XX_XRTX_PLATFORM_V;

/* Formatted on 6/6/2016 4:56:32 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PLATFORM_V
(
   PLATFORM_NAME
)
AS
   SELECT platform_name FROM v$database;
