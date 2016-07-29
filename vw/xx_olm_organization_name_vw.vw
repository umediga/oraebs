DROP VIEW APPS.XX_OLM_ORGANIZATION_NAME_VW;

/* Formatted on 6/6/2016 4:58:21 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_OLM_ORGANIZATION_NAME_VW
(
   NAME,
   ORGANIZATION_ID
)
AS
   SELECT "NAME", "ORGANIZATION_ID"
     FROM (SELECT 'ALL' NAME, 00 organization_id FROM DUAL
           UNION
           SELECT ort.NAME, org.organization_id
             FROM hr_organization_units org,
                  hr_all_organization_units_tl ort,
                  hr_lookups lkp,
                  hr_organization_information_v hoiv
            WHERE     org.organization_id = ort.organization_id
                  AND ort.LANGUAGE = USERENV ('LANG')
                  AND org.date_from <= SYSDATE
                  AND (org.date_to IS NULL OR SYSDATE <= org.date_to)
                  AND lkp.lookup_type(+) = 'INTL_EXTL'
                  AND lkp.lookup_code(+) = org.internal_external_flag
                  AND (   fnd_profile.VALUE (
                             'OTA_HR_GLOBAL_BUSINESS_GROUP_ID')
                             IS NOT NULL
                       OR org.business_group_id =
                             fnd_profile.VALUE ('PER_BUSINESS_GROUP_ID'))
                  AND hoiv.organization_id = org.organization_id
                  AND hoiv.org_information1 = 'HR_ORG'
                  AND hoiv.org_information2 = 'Y'
           ORDER BY NAME);
