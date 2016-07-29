DROP VIEW APPS.XX_XRTX_AS_MOD_V;

/* Formatted on 6/6/2016 4:56:47 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AS_MOD_V
(
   RN,
   MODULE_CLASSIFICATION,
   USER_ACCESS_MODULE_WISE,
   PCTG
)
AS
   SELECT ROWNUM AS rn,
          module_classification,
          user_access_module_wise,
          pctg
     FROM xx_xrtx_as_mod_v1;
