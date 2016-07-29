DROP VIEW APPS.XX_XRTX_INV_ORG_V;

/* Formatted on 6/6/2016 4:56:40 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_INV_ORG_V
(
   "Organization Code",
   "Description"
)
AS
   SELECT b.organization_code "Organization Code",
          b.organization_NAME "Description"
     FROM apps.org_organization_definitions b;
