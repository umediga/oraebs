DROP PROCEDURE APPS.XXINTG_CUST_SITE_UPDATE;

CREATE OR REPLACE PROCEDURE APPS."XXINTG_CUST_SITE_UPDATE" 
IS
   p_cust_site_use_rec    HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
   x_return_status        VARCHAR2 (2000);
   x_msg_count            NUMBER;
   xio_p_object_version   NUMBER;
   x_msg_data             VARCHAR2 (2000);
   v_site_use_id          NUMBER;
   V_CUST_ACCT_SITE_ID    NUMBER;
   V_OBJECT_VERSION       NUMBER;

   CURSOR c_fob
   IS
      SELECT HCSU.SITE_USE_ID,
             HCSU.CUST_ACCT_SITE_ID,
             HCSU.OBJECT_VERSION_NUMBER,
             HCSU.FOB_POINT
        FROM HZ_PARTIES HP,
             HZ_PARTY_SITES HPS,
             HZ_CUST_ACCT_SITES_ALL HCAS,
             HZ_CUST_SITE_USES_ALL HCSU
       WHERE     HP.PARTY_ID = HPS.PARTY_ID
             AND HPS.PARTY_SITE_ID = HCAS.PARTY_SITE_ID
             AND HCAS.CUST_ACCT_SITE_ID = HCSU.CUST_ACCT_SITE_ID
             AND HCSU.fob_point IN ('SHIP POINT','CUSTOMER SITE');
             --AND HCSU.SITE_USE_ID IN (1120,1051);
BEGIN
   --    FND_GLOBAL.APPS_INITIALIZE(<user_id>,<resp_id>,<resp_applicarion_id>);
   --    MO_GLOBAL.INIT('AR');
   --    MO_GLOBAL.SET_POLICY_CONTEXT('S', <org_id>);

   FND_GLOBAL.APPS_INITIALIZE (128817, 20678, 222);
   FND_GLOBAL.APPS_INITIALIZE (128817, 20678, 661);
   FND_GLOBAL.APPS_INITIALIZE (128817, 20678, 660);
   MO_GLOBAL.INIT ('AR');
   MO_GLOBAL.SET_POLICY_CONTEXT ('S', '82');
  -- MO_GLOBAL.SET_POLICY_CONTEXT ('S', '84');

   FOR i IN c_fob
   LOOP
      p_cust_site_use_rec.site_use_id := i.SITE_USE_ID; -- Site USe to be updated
      xio_p_object_version := i.OBJECT_VERSION_NUMBER;   --xio_p_object_version := 1;
      p_cust_site_use_rec.CUST_ACCT_SITE_ID := i.CUST_ACCT_SITE_ID;

      if i.FOB_POINT = 'SHIP POINT' THEN    
      p_cust_site_use_rec.fob_point := 'FOB ORIGIN';
      ELSIF i.FOB_POINT = 'CUSTOMER SITE' THEN 
      p_cust_site_use_rec.fob_point := 'FOB DESTINATION';
      END IF;
                 -- SSE Standard
      --     p_cust_site_use_rec.payment_term_id := 1000 ;              -- 90 Days
      --     p_cust_site_use_rec.order_type_id   := 1193;               --SSE Duabi Showroom Cash Sales

      hz_cust_account_site_v2pub.update_cust_site_use ('T',
                                                       p_cust_site_use_rec,
                                                       xio_p_object_version,
                                                       x_return_status,
                                                       x_msg_count,
                                                       x_msg_data);
   END LOOP;

   DBMS_OUTPUT.put_line ('***************************');
   DBMS_OUTPUT.put_line ('Output information ....');
   DBMS_OUTPUT.put_line ('x_return_status: ' || x_return_status);
   DBMS_OUTPUT.put_line ('x_msg_count: ' || x_msg_count);
   DBMS_OUTPUT.put_line ('xio_p_object_version: ' || xio_p_object_version);
   DBMS_OUTPUT.put_line ('x_msg_data: ' || x_msg_data);
   DBMS_OUTPUT.put_line ('***************************');

   COMMIT;
END;
/
