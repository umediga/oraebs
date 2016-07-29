DROP PACKAGE APPS.XX_AR_SFDC_CUST_OUTBOUND_PKG;

CREATE OR REPLACE PACKAGE APPS.xx_ar_sfdc_cust_outbound_pkg
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 04-APR-2014
 File Name     : XXARCUSTSFDCOUTINTF.pks
 Description   : This script creates the specification of the package
                 xx_ar_sfdc_cust_outbound_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 04-APR-2014 Sharath Babu          Initial Development
 */
----------------------------------------------------------------------
   PROCEDURE fetch_upd_cust_details(
                                       p_errbuf           OUT NOCOPY  VARCHAR2
                                      ,p_retcode          OUT NOCOPY  NUMBER
                                      ,p_type             IN VARCHAR2
				      ,p_hidden1          IN VARCHAR2
				      ,p_hidden2          IN VARCHAR2
				      ,p_cust_site_from   IN HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE DEFAULT NULL
				      ,p_cust_site_to     IN HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE DEFAULT NULL
				      ,p_date_from        IN VARCHAR2 DEFAULT NULL
				      ,p_date_to          IN VARCHAR2 DEFAULT NULL
                                     );

   --Function to fetch territories last update date
   FUNCTION get_terr_update_date( p_country             VARCHAR2,
                                  p_customer_id         NUMBER,
                                  p_site_number         NUMBER,
                                  p_cust_account        VARCHAR2,
                                  p_county              VARCHAR2,
                                  p_postal_code         VARCHAR2,
                                  p_province            VARCHAR2,
                                  p_state               VARCHAR2,
                                  p_cust_name           VARCHAR2
                                )
      RETURN DATE;

   --Function to fetch territory flag if territories updated in date range
   FUNCTION get_terr_update_flag( p_country             VARCHAR2,
                                  p_customer_id         NUMBER,
                                  p_site_number         NUMBER,
                                  p_cust_account        VARCHAR2,
                                  p_county              VARCHAR2,
                                  p_postal_code         VARCHAR2,
                                  p_province            VARCHAR2,
                                  p_state               VARCHAR2,
                                  p_cust_name           VARCHAR2,
                                  p_date_from           DATE,
                                  p_date_to             DATE
                                )
   RETURN VARCHAR2;

END xx_ar_sfdc_cust_outbound_pkg;
/
