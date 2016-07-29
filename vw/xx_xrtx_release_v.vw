DROP VIEW APPS.XX_XRTX_RELEASE_V;

/* Formatted on 6/6/2016 4:54:15 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_RELEASE_V
(
   APPLICATIONS_SYSTEM_NAME,
   ARU_RELEASE_NAME,
   RELEASE_NAME,
   MULTI_ORG_FLAG,
   MULTI_LINGUAL_FLAG,
   MULTI_CURRENCY_FLAG
)
AS
   SELECT applications_system_name,
          aru_release_name,
          release_name,
          multi_org_flag,
          multi_lingual_flag,
          multi_currency_flag
     FROM fnd_product_groups;
