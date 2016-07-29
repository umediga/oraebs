DROP FUNCTION APPS.XXOM_GET_ACCT_SITE_PURPOSES;

CREATE OR REPLACE FUNCTION APPS."XXOM_GET_ACCT_SITE_PURPOSES" (
/*
Function Name - xxom_get_acct_site_purposes
Use - Get all account site purposes
Created by - IBM Development Team
Object - M2C-EXT-074
Date - 06-Sep-2012
*/
   p_party_id      IN   NUMBER,
   p_location_id   IN   NUMBER
)
   RETURN VARCHAR2
IS
   l_site_use_purpose        VARCHAR2 (100);
   l_all_site_use_purposes   VARCHAR2 (1000) := '';

   CURSOR c_site_use_purposes (l_party_id IN NUMBER, l_location_id NUMBER)
   IS
      SELECT   al.meaning
          FROM hz_cust_acct_sites_all s,
               hz_cust_site_uses_all u,
               ar_lookups al,
               hz_party_sites hps
         WHERE 1 = 1
           AND hps.party_id = l_party_id
           AND hps.location_id = l_location_id
           AND s.party_site_id = hps.party_site_id
           AND u.cust_acct_site_id = s.cust_acct_site_id
           AND u.status = 'A'
           AND al.lookup_type = 'SITE_USE_CODE'
           AND al.lookup_code = u.site_use_code
      ORDER BY al.meaning;
BEGIN
   OPEN c_site_use_purposes (p_party_id, p_location_id);

   LOOP
      FETCH c_site_use_purposes
       INTO l_site_use_purpose;

      IF c_site_use_purposes%NOTFOUND
      THEN
         EXIT;
      END IF;

      IF l_all_site_use_purposes IS NOT NULL
      THEN
         l_all_site_use_purposes := CONCAT (l_all_site_use_purposes, ', ');
      END IF;

      l_all_site_use_purposes :=
                          CONCAT (l_all_site_use_purposes, l_site_use_purpose);
   END LOOP;

   CLOSE c_site_use_purposes;

   RETURN l_all_site_use_purposes;
END xxom_get_acct_site_purposes;
/
