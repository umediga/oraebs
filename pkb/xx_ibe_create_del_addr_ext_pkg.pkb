DROP PACKAGE BODY APPS.XX_IBE_CREATE_DEL_ADDR_EXT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_IBE_CREATE_DEL_ADDR_EXT_PKG" 
AS
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
FUNCTION xx_define_acct_site_use(
    p_cust_acct_site_id IN NUMBER)
  RETURN NUMBER
IS
  x_cust_site_use_rec HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
  x_customer_profile_rec HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
  x_acct_site_use_id NUMBER;
  x_return_status    VARCHAR2(2000);
  x_msg_count        NUMBER;
  x_msg_data         VARCHAR2(2000);
BEGIN
  dbms_output.put_line('defining variable for new  cust acct  site  use API ');
  x_cust_site_use_rec.cust_acct_site_id := p_cust_acct_site_id;
  x_cust_site_use_rec.site_use_code     := 'DELIVER_TO';
  x_cust_site_use_rec.created_by_module := 'TCA_V2_API';
  x_cust_site_use_rec.primary_flag      := 'N';
  dbms_output.put_line('calling party site use  API to define new cust acct site use  ');
  hz_cust_account_site_v2pub.create_cust_site_use(FND_API.G_TRUE, x_cust_site_use_rec, x_customer_profile_rec, '', '', x_acct_site_use_id, x_return_status, x_msg_count, x_msg_data);
  IF (x_return_status ='S' AND x_acct_site_use_id IS NOT NULL) THEN
    dbms_output.put_line('Cust Acct Site use  created successfully '|| x_acct_site_use_id);
    RETURN x_acct_site_use_id;
  ELSE
    dbms_output.put_line('Cust Acct Site use not created successfully '|| x_msg_data);
    RETURN -1;
  END IF;
END xx_define_acct_site_use;
FUNCTION xx_define_party_site_use(
    p_party_site_id NUMBER)
  RETURN NUMBER
AS
  x_party_site_use_rec hz_party_site_v2pub.PARTY_SITE_USE_REC_TYPE;
  x_party_site_use_id NUMBER;
  x_party_site_number VARCHAR2(2000);
  x_return_status     VARCHAR2(2000);
  x_msg_count         NUMBER;
  x_msg_data          VARCHAR2(2000);
BEGIN
  dbms_output.put_line('defining variable for new  party site  use API ');
  x_party_site_use_rec.party_site_id     := p_party_site_id;
  x_party_site_use_rec.site_use_type     := 'DELIVER_TO';
  x_party_site_use_rec.status            := 'A';
  x_party_site_use_rec.primary_per_type  := 'N';
  x_party_site_use_rec.created_by_module := 'TCA_V2_API';
  dbms_output.put_line('calling party site use  API to define new party site use  ');
  hz_party_site_v2pub.create_party_site_use ( p_init_msg_list => 'T', p_party_site_use_rec => x_party_site_use_rec, x_party_site_use_id => x_party_site_use_id, x_return_status => x_return_status, x_msg_count => x_msg_count, x_msg_data => x_msg_data);
  IF (x_return_status ='S' AND x_party_site_use_id IS NOT NULL) THEN
    dbms_output.put_line('Party Site use  created successfully '|| x_party_site_use_id);
    RETURN x_party_site_use_id;
  ELSE
    dbms_output.put_line('Party Site use  not created successfully '|| x_msg_data);
    RETURN -1;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  dbms_output.put_line('Unexpected error in xx_define_party_site_use function: '||SQLERRM);
END xx_define_party_site_use ;
FUNCTION xx_define_acct_site(
    p_party_site_id IN NUMBER,
    p_account_id    IN NUMBER)
  RETURN NUMBER
IS
  x_cust_acct_site_rec hz_cust_account_site_v2pub.cust_acct_site_rec_type;
  x_return_status     VARCHAR2 ( 2000 ) ;
  x_msg_count         NUMBER;
  x_msg_data          VARCHAR2 ( 2000 ) ;
  x_cust_acct_site_id NUMBER;
BEGIN
  dbms_output.put_line('Defining cust acct site variable ');
  x_cust_acct_site_rec.cust_account_id   := p_account_id;
  x_cust_acct_site_rec.party_site_id     := p_party_site_id;
  x_cust_acct_site_rec.created_by_module := 'TCA_V2_API';
  x_cust_acct_site_rec.org_id            := 82;
  mo_global.set_policy_context('S',82);
  MO_GLOBAL.INIT ('AR');
  dbms_output.put_line('calling cust acct site  API to define cust acct site ');
  hz_cust_account_site_v2pub.create_cust_acct_site ( 'T' , x_cust_acct_site_rec , x_cust_acct_site_id , x_return_status , x_msg_count , x_msg_data ) ;
  IF (x_return_status ='S' AND x_cust_acct_site_id IS NOT NULL) THEN
    dbms_output.put_line('Cust Acct Site created successfully '||x_cust_acct_site_id);
    RETURN x_cust_acct_site_id;
  ELSE
    dbms_output.put_line('Cust Acct Site not created successfully '||x_msg_data);
    RETURN -1;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  dbms_output.put_line('Unexpected error in xx_define_acct_site function: '||SQLERRM);
END xx_define_acct_site;
FUNCTION xx_define_party_site(
    p_shippartysiteid_orig NUMBER,
    p_location_id          NUMBER,
    p_party_id             NUMBER)
  RETURN NUMBER
AS
  p_party_site_rec hz_party_site_v2pub.party_site_rec_type;
  x_party_site_id     NUMBER;
  x_party_site_number VARCHAR2(2000);
  x_return_status     VARCHAR2(2000);
  x_msg_count         NUMBER;
  x_msg_data          VARCHAR2(2000);
  x_party_id          NUMBER;
  x_party_site_use_id NUMBER;
BEGIN
  dbms_output.put_line('Defining party site variable ');
  p_party_site_rec.party_id                 := p_party_id;
  p_party_site_rec.location_id              := p_location_id;
  p_party_site_rec.identifying_address_flag := 'Y';
  p_party_site_rec.created_by_module        := 'TCA_V2_API';
  mo_global.set_policy_context('S',82);
  dbms_output.put_line('calling party site  API to define new party site ');
  hz_party_site_v2pub.Create_party_site ( p_init_msg_list => 'T' , p_party_site_rec => p_party_site_rec , x_party_site_id => x_party_site_id , x_party_site_number => x_party_site_number, x_return_status => x_return_status , x_msg_count => x_msg_count , x_msg_data => x_msg_data );
  IF (x_return_status ='S' AND x_party_site_id IS NOT NULL) THEN
    dbms_output.put_line('Party Site  created successfully '||x_party_site_id);
    RETURN x_party_site_id;
  ELSE
    dbms_output.put_line('Party Site not created successfully '||x_msg_data);
    RETURN -1;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  dbms_output.put_line('Unexpected error in xx_define_party_site function: '||SQLERRM);
END xx_define_party_site;
FUNCTION xx_define_new_locations(
    p_address1    IN VARCHAR2,
    p_address2    IN VARCHAR2,
    p_city        IN VARCHAR2,
    p_state       IN VARCHAR2,
    p_postal_code IN VARCHAR2,
    p_country     IN VARCHAR2)
  RETURN NUMBER
IS
  x_location_rec HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
  x_location_id HZ_LOCATIONS.location_id%TYPE;
  x_return_status VARCHAR2(2000);
  x_msg_count     NUMBER;
  x_Msg_Data      VARCHAR2(2000);
  x_country_code  VARCHAR2(30);
BEGIN

  dbms_output.put_line('Defining location variable ');
  x_location_rec.address1	   := p_address1;
  x_location_rec.address2          :=  p_address2;
  x_location_rec.City              := p_city;
  x_location_rec.postal_code       := p_postal_code;
  x_location_rec.state             := p_state ;
  x_location_rec.country           := p_country ;
  x_location_rec.created_by_module := 'TCA_V2_API';


  dbms_output.put_line('calling location API to define new location ');
  hz_location_v2pub.create_location( p_init_msg_list => 'T' , p_location_rec => x_location_rec , x_location_id => x_location_id , x_return_status => x_return_status , x_msg_count => x_msg_count , x_msg_data => x_msg_data );
  IF (x_return_status ='S' AND x_location_id IS NOT NULL) THEN
    dbms_output.put_line('Location created successfully '||x_location_id );
    RETURN x_location_id;
  ELSE
    dbms_output.put_line('Location not created successfully '||x_msg_data );
    RETURN -1;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  dbms_output.put_line('Unexpected error while creating location in xx_define_new_locations function: '||SQLERRM);
END xx_define_new_locations;
FUNCTION xx_create_new_party_site(
    p_shippartysiteid_orig IN VARCHAR2,
    p_address1             IN VARCHAR2,
    p_address2             IN VARCHAR2,
    p_city                 IN VARCHAR2,
    p_state                IN VARCHAR2,
    p_postal_code          IN VARCHAR2,
    p_country              IN VARCHAR2,
    p_shiptoCustAccountId  IN VARCHAR2,
    p_shiptoCustPartyId    IN VARCHAR2)
  RETURN NUMBER
IS
  x_location_id HZ_LOCATIONS.location_id%TYPE;
  x_party_site_id hz_party_sites.party_site_id%TYPE;
  x_cust_acct_site_id hz_cust_Acct_sites_all.cust_Acct_site_id%TYPE;
  x_site_use_id           NUMBER;
  x_cust_acct_site_use_id NUMBER;
BEGIN
  --Create Location
  x_location_id    := xx_define_new_locations (p_address1=> p_address1, p_address2 => p_address2, p_city =>p_city, p_state => p_state, p_postal_code => p_postal_code, p_country =>p_country);
  IF x_location_id != -1 THEN
    --Create Party Site
    x_party_site_id := xx_define_party_site( p_shippartysiteid_orig => p_shippartysiteid_orig, p_location_id =>x_location_id, p_party_id => p_shiptoCustPartyId );
  END IF;
  IF x_party_site_id != -1 THEN
    -- Create Acccount Site
    x_cust_acct_site_id := xx_define_acct_site( p_party_site_id => x_party_site_id, p_account_id =>p_shiptoCustAccountId );
  END IF;
  IF x_party_site_id != -1 THEN
    --Create Party Site Use
    x_site_use_id := xx_define_party_site_use(p_party_site_id =>x_party_site_id );
  END IF;
  IF x_cust_acct_site_id != -1 THEN
    --Create Acct Site Use
    x_cust_acct_site_use_id := xx_define_acct_site_use ( p_cust_acct_site_id => x_cust_acct_site_id);
  END IF;
  IF x_party_site_id != -1 THEN
    COMMIT;
    dbms_output.put_line('Party site created, Party_SiteId: '|| x_party_site_id );
  ELSE
    ROLLBACK;
  END IF;
  RETURN x_party_site_id;
EXCEPTION
WHEN OTHERS THEN
  dbms_output.put_line('Unexpected error in xx_create_new_party_site function: '||SQLERRM);
END xx_create_new_party_site;
PROCEDURE xx_get_party_site_address(
    p_shippartysiteid IN VARCHAR2,
    p_address1 OUT VARCHAR2,
    p_address2 OUT VARCHAR2,
    p_city OUT VARCHAR2,
    p_state OUT VARCHAR2,
    p_postal_code OUT VARCHAR2,
    p_country OUT VARCHAR2)
IS
BEGIN
   SELECT hl.address1,
    hl.address2,
    hl.city,
    hl.postal_code,
    Hl.State,
    Ft.Territory_Short_Name
   INTO p_address1,
    p_address2,
    p_city,
    p_postal_code,
    p_state,
    p_country
  FROM Hz_Party_Sites Hps,
    Hz_Locations Hl,
    Fnd_Territories_Vl Ft,
    aso_shipments asp
  WHERE hl.country     = Ft.territory_code
  And Hl.Location_Id   = Hps.Location_Id
  And Hps.Party_Site_Id= Asp.Attribute11
  AND asp.shipment_id = P_Shippartysiteid;

EXCEPTION
WHEN OTHERS THEN
  dbms_output.put_line('Unexpected error in xx_get_party_site_address procedure: '||SQLERRM);
END xx_get_party_site_address;
END XX_IBE_CREATE_DEL_ADDR_EXT_PKG;
/
