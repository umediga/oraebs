DROP VIEW APPS.XX_XRTX_BG_V;

/* Formatted on 6/6/2016 4:56:46 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_BG_V
(
   SHORT_CODE,
   "Description"
)
AS
   SELECT hoi.org_information1 "SHORT_CODE", haou.NAME "Description"
     FROM hr_all_organization_units haou, hr_organization_information hoi
    WHERE     haou.TYPE IN ('BU', 'BG')
          AND hoi.organization_id = haou.organization_id
          AND hoi.org_information_context = 'Business Group Information';
