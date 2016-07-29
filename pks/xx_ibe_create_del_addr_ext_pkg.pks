DROP PACKAGE APPS.XX_IBE_CREATE_DEL_ADDR_EXT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_IBE_CREATE_DEL_ADDR_EXT_PKG" AUTHID CURRENT_USER AS
  /* $Header: XX_IBE_CREATE_DELIVER_ADDRESS.pks 1.0.0 2013/07/02 700:00:00 riqbal noship $ */
  --------------------------------------------------------------------------------
  /*
  Created By     : Raquib Iqbal
  Creation Date  : 02-Jul-2013
  Filename       : XX_IBE_CREATE_DELIVER_ADDRESS.pkb
  Description    : Deliver to Address creattion public pacakge
  Change History:
  Date        Version#    Name                Remarks
  ----------- --------    ---------------     -----------------------------------
  02-Jul-2012   1.0       Raquib Iqbal        Initial development.
  */
  --------------------------------------------------------------------------------

  FUNCTION xx_create_new_party_site(
      p_shippartysiteid_orig IN VARCHAR2,
      p_address1             IN VARCHAR2,
      p_address2             IN VARCHAR2,
      p_city                 IN VARCHAR2,
      p_state                IN VARCHAR2,
      p_postal_code          IN VARCHAR2,
      p_country              IN VARCHAR2,
      p_shiptoCustAccountId  IN VARCHAR2,
      p_shiptoCustPartyId    IN VARCHAR2
      )

    RETURN NUMBER;

     PROCEDURE xx_get_party_site_address(
      p_shippartysiteid      IN   VARCHAR2,
      p_address1             OUT  VARCHAR2,
      p_address2             OUT  VARCHAR2,
      p_city                 OUT  VARCHAR2,
      p_state                OUT  VARCHAR2,
      p_postal_code          OUT  VARCHAR2,
      p_country              OUT  VARCHAR2);


END XX_IBE_CREATE_DEL_ADDR_EXT_PKG;
/
