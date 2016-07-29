DROP VIEW APPS.XXOM_CUST_ADDR_STG_V;

/* Formatted on 6/6/2016 5:00:07 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXOM_CUST_ADDR_STG_V
(
   CUSTOMER_NUMBER,
   PARTY_SITE_NUMBER,
   TERRITORY_NAME
)
AS
   (SELECT customer_number, party_site_number, recon_terr_code territory_name
      FROM xxom_cust_addr_stg xcas
     WHERE     1 = 1                              -- party_site_number = 90899
           AND last_update_date =
                  (SELECT MAX (last_update_date)
                     FROM xxom_cust_addr_stg
                    WHERE     1 = 1                 -- customer_number = 89696
                          AND party_site_number = xcas.party_site_number -- 90899
                                                                        )
           AND recon_terr_code IS NOT NULL
    UNION
    SELECT customer_number, party_site_number, recon1 territory_name
      FROM xxom_cust_addr_stg xcas
     WHERE     1 = 1                              -- party_site_number = 90899
           AND last_update_date =
                  (SELECT MAX (last_update_date)
                     FROM xxom_cust_addr_stg
                    WHERE     1 = 1                 -- customer_number = 89696
                          AND party_site_number = xcas.party_site_number -- 90899
                                                                        )
           AND recon1 IS NOT NULL
    UNION
    SELECT customer_number, party_site_number, recon2 territory_name
      FROM xxom_cust_addr_stg xcas
     WHERE     1 = 1                              -- party_site_number = 90899
           AND last_update_date =
                  (SELECT MAX (last_update_date)
                     FROM xxom_cust_addr_stg
                    WHERE     1 = 1                 -- customer_number = 89696
                          AND party_site_number = xcas.party_site_number -- 90899
                                                                        )
           AND recon2 IS NOT NULL
    UNION
    SELECT customer_number, party_site_number, recon3 territory_name
      FROM xxom_cust_addr_stg xcas
     WHERE     1 = 1                              -- party_site_number = 90899
           AND last_update_date =
                  (SELECT MAX (last_update_date)
                     FROM xxom_cust_addr_stg
                    WHERE     1 = 1                 -- customer_number = 89696
                          AND party_site_number = xcas.party_site_number -- 90899
                                                                        )
           AND recon3 IS NOT NULL
    UNION
    SELECT customer_number,
           party_site_number,
           spine_territory_code territory_name
      FROM xxom_cust_addr_stg xcas
     WHERE     1 = 1                              -- party_site_number = 90899
           AND last_update_date =
                  (SELECT MAX (last_update_date)
                     FROM xxom_cust_addr_stg
                    WHERE     1 = 1                 -- customer_number = 89696
                          AND party_site_number = xcas.party_site_number -- 90899
                                                                        )
           AND spine_territory_code IS NOT NULL
    UNION
    SELECT customer_number, party_site_number, neuro_terr_code territory_name
      FROM xxom_cust_addr_stg xcas
     WHERE     1 = 1                              -- party_site_number = 90899
           AND last_update_date =
                  (SELECT MAX (last_update_date)
                     FROM xxom_cust_addr_stg
                    WHERE     1 = 1                 -- customer_number = 89696
                          AND party_site_number = xcas.party_site_number -- 90899
                                                                        )
           AND neuro_terr_code IS NOT NULL);


GRANT SELECT ON APPS.XXOM_CUST_ADDR_STG_V TO XXAPPSREAD;
