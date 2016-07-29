DROP VIEW APPS.XX_XRTX_AS_MOD_V1;

/* Formatted on 6/6/2016 4:56:47 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AS_MOD_V1
(
   MODULE_CLASSIFICATION,
   USER_ACCESS_MODULE_WISE,
   PCTG
)
AS
     SELECT a.module_classification,
            a.user_acess_module_wise AS user_access_module_wise,
            ROUND ( (a.user_acess_module_wise / b.sm) * 100, 2) AS pctg
       FROM xx_xrtx_mc_user_count_t a,
            (SELECT SUM (user_acess_module_wise) sm
               FROM xx_xrtx_mc_user_count_t
              WHERE user_acess_module_wise IS NOT NULL) b
      WHERE     user_acess_module_wise IS NOT NULL
            AND a.user_acess_module_wise IS NOT NULL
   ORDER BY 3 DESC;
