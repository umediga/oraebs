DROP VIEW APPS.XXINTG_COGNOS_V;

/* Formatted on 6/6/2016 5:00:24 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_COGNOS_V
(
   SITE_USE_CODE,
   SALESREP,
   PARTY_NAME,
   ACCOUNT_NUMBER,
   ORIG_SYSTEM_REFERENCE,
   ORIG_SYSTEM_REFERENCE_1,
   ADDRESS1,
   ADDRESS2,
   STATE,
   POSTAL_CODE
)
AS
     SELECT hsua.site_use_code,
            (SELECT RESOURCE_NAME
               FROM apps.JTF_RS_SALESREPS jrs, apps.JTF_RS_DEFRESOURCES_V jrre
              WHERE     1 = 1
                    AND jrs.resource_id = jrre.resource_id
                    AND jrs.salesrep_id = hsua.primary_salesrep_id
                    AND ROWNUM < 2)
               "SalesRep",
            hp.party_name,
            hca.account_number,
            hca.orig_system_reference,
            hl.orig_system_reference "orig_system_reference_1",
            hl.address1,
            hl.address2,
            hl.state,
            HL.POSTAL_CODE
       FROM apps.hz_cust_accounts hca,
            apps.hz_parties hp,
            apps.hz_party_sites hps,
            apps.hz_cust_acct_sites_all hcas,
            apps.hz_locations hl,
            apps.hz_cust_site_uses_all hsua
      WHERE     1 = 1
            AND hp.party_id = hca.party_id
            AND hps.party_site_id = hcas.party_site_id
            AND hp.party_id = hps.party_id
            AND hps.location_id = hl.location_id
            AND hcas.cust_acct_site_id = hsua.cust_acct_site_id
            AND hsua.primary_salesrep_id IS NOT NULL
            AND hsua.org_id = 101
            AND HSUA.STATUS = 'A'
   ORDER BY 1, 2;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XXINTG_COGNOS_V FOR APPS.XXINTG_COGNOS_V;


CREATE OR REPLACE SYNONYM XXBI.XXINTG_COGNOS_V FOR APPS.XXINTG_COGNOS_V;


GRANT SELECT ON APPS.XXINTG_COGNOS_V TO ETLEBSUSER;
