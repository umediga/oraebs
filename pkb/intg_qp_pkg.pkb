DROP PACKAGE BODY APPS.INTG_QP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."INTG_QP_PKG" IS
/*
 Created By     : IBM Development Team
 Creation Date  : 08-Feb-2012
 File Name      : XXQPPKG.pkb
 Description    : This script creates the package of the intg_qp_pkg package

 Change History:

 Version Date        Name                    Remarks
 ------- ----------- ---------------------   ----------------------
 1.0     08-Oct-12   IBM Development Team    Initial development.
*/
   FUNCTION get_ship_to_country(p_headerid IN NUMBER
                               ,p_lineid   IN NUMBER)
   RETURN VARCHAR2 AS
      l_country VARCHAR2(60) := NULL;

   BEGIN
      l_country := NULL;

      -- Get country from line id
      IF (p_lineid IS NOT NULL) THEN
         BEGIN
            SELECT ship_loc.country
              INTO l_country
              FROM hz_locations           ship_loc
                  ,hz_party_sites         ship_ps
                  ,hz_cust_acct_sites_all ship_cas
                  ,hz_cust_site_uses_all  ship_su
                  ,oe_order_headers_all   h
                  ,oe_order_lines_all     l
             WHERE l.line_id = p_lineid
               AND h.header_id = l.header_id
               AND ship_su.site_use_id(+) = h.ship_to_org_id
               AND ship_cas.cust_acct_site_id(+) = ship_su.cust_acct_site_id
               AND ship_ps.party_site_id(+) = ship_cas.party_site_id
               AND ship_loc.location_id(+) = ship_ps.location_id;
         EXCEPTION
            WHEN OTHERS THEN
               l_country := NULL;
         END;

      ELSIF (p_headerid IS NOT NULL) THEN
         -- Get country from header id
         BEGIN
            SELECT ship_loc.country
              INTO l_country
              FROM hz_locations           ship_loc
                  ,hz_party_sites         ship_ps
                  ,hz_cust_acct_sites_all ship_cas
                  ,hz_cust_site_uses_all  ship_su
                  ,oe_order_headers_all   h
             WHERE h.header_id = p_headerid
               AND ship_su.site_use_id(+) = h.ship_to_org_id
               AND ship_cas.cust_acct_site_id(+) = ship_su.cust_acct_site_id
               AND ship_ps.party_site_id(+) = ship_cas.party_site_id
               AND ship_loc.location_id(+) = ship_ps.location_id;
         EXCEPTION
            WHEN OTHERS THEN
               l_country := NULL;
         END;

      END IF;

      RETURN(l_country);
   END get_ship_to_country;

END intg_qp_pkg;
/
