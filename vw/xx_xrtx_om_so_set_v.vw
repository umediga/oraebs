DROP VIEW APPS.XX_XRTX_OM_SO_SET_V;

/* Formatted on 6/6/2016 4:56:37 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_OM_SO_SET_V
(
   NAME,
   DESCRIPTION,
   ENABLED_FLAG,
   AIA_ENABLED_FLAG
)
AS
   SELECT name,
          description,
          ENABLED_FLAG,
          aia_enabled_flag
     FROM oe_order_sources;
