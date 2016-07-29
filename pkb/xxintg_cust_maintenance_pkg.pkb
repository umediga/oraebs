DROP PACKAGE BODY APPS.XXINTG_CUST_MAINTENANCE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_CUST_MAINTENANCE_PKG" 
AS
   PROCEDURE DEBUG (p_msg IN VARCHAR2)
   IS
   BEGIN
      DBMS_OUTPUT.put_line (p_msg);
      fnd_file.put_line (fnd_file.LOG, p_msg);
   END;

   PROCEDURE identify_flag (
      errbuf        OUT      VARCHAR2,
      retcode       OUT      VARCHAR2,
      p_party_id1   IN       NUMBER
   )
   IS
      CURSOR c_identify (p_party_id1 IN NUMBER)
      IS
         SELECT hps.party_site_id, hps.party_id, hps.location_id,
                hps.party_site_number, hps.orig_system_reference,
                hps.mailstop, hps.identifying_address_flag, hps.status,
                hps.party_site_name, hps.attribute_category, hps.attribute1,
                hps.attribute2, hps.attribute3, hps.attribute4,
                hps.attribute5, hps.attribute6, hps.attribute7,
                hps.attribute8, hps.attribute9, hps.attribute10,
                hps.attribute11, hps.attribute12, hps.attribute13,
                hps.attribute14, hps.attribute15, hps.attribute16,
                hps.attribute17, hps.attribute18, hps.attribute19,
                hps.attribute20, hps.LANGUAGE, hps.addressee,
                hps.created_by_module, hps.application_id,
                hps.global_location_number, hps.duns_number_c
           FROM hz_party_sites hps, hz_party_site_uses hpsu
          WHERE hps.party_site_id = hpsu.party_site_id
            AND hps.identifying_address_flag = 'Y'
            AND hpsu.site_use_type = 'SHIP_TO'
            AND hps.status = 'A'
            AND hps.party_id = NVL (p_party_id1, hps.party_id)
            AND NOT EXISTS (
                   SELECT 1
                     FROM hz_party_site_uses hpsu1
                    WHERE hps.party_site_id = hpsu1.party_site_id
                      AND hpsu1.site_use_type = 'BILL_TO');

      CURSOR c_new_ident (p_party_id IN NUMBER)
      IS
         SELECT hps.party_site_id, hps.party_id, hps.location_id,
                hps.party_site_number, hps.orig_system_reference,
                hps.mailstop, hps.identifying_address_flag, hps.status,
                hps.party_site_name, hps.attribute_category, hps.attribute1,
                hps.attribute2, hps.attribute3, hps.attribute4,
                hps.attribute5, hps.attribute6, hps.attribute7,
                hps.attribute8, hps.attribute9, hps.attribute10,
                hps.attribute11, hps.attribute12, hps.attribute13,
                hps.attribute14, hps.attribute15, hps.attribute16,
                hps.attribute17, hps.attribute18, hps.attribute19,
                hps.attribute20, hps.LANGUAGE, hps.addressee,
                hps.created_by_module, hps.application_id,
                hps.global_location_number, hps.duns_number_c
           FROM hz_party_sites hps, hz_party_site_uses hpsu
          WHERE hps.party_site_id = hpsu.party_site_id
            AND hps.identifying_address_flag = 'N'
            AND hpsu.site_use_type = 'BILL_TO'
            AND hps.status = 'A'
            AND ROWNUM = 1
            AND hps.party_id = NVL (p_party_id, hps.party_id);

      l_party_site_rec          hz_party_site_v2pub.party_site_rec_type;
      v_party_site_rec          hz_party_site_v2pub.party_site_rec_type;
      v_return_status           VARCHAR2 (240);
      v_msg_count               NUMBER;
      v_msg_data                VARCHAR2 (240);
      v_object_version_number   NUMBER                                  := 1.0;
      v_error_msg               VARCHAR2 (240);
   BEGIN
      DEBUG ('program is running for the party_id:' || p_party_id1);

      BEGIN
         DEBUG
            (   'program is running for disabling the identifying_address_flag of ship_to :'
             || p_party_id1
            );

         FOR v_identify IN c_identify (p_party_id1)
         LOOP
            l_party_site_rec.party_site_id := v_identify.party_site_id;
            l_party_site_rec.party_id := v_identify.party_id;
            l_party_site_rec.location_id := v_identify.location_id;
            l_party_site_rec.party_site_number :=
                                                 v_identify.party_site_number;
            l_party_site_rec.orig_system_reference :=
                                             v_identify.orig_system_reference;
            l_party_site_rec.mailstop := v_identify.mailstop;
            l_party_site_rec.identifying_address_flag := 'N';
            l_party_site_rec.status := v_identify.status;
            l_party_site_rec.party_site_name := v_identify.party_site_name;
            l_party_site_rec.attribute_category :=
                                                v_identify.attribute_category;
            l_party_site_rec.attribute1 := v_identify.attribute1;
            l_party_site_rec.attribute2 := v_identify.attribute2;
            l_party_site_rec.attribute3 := v_identify.attribute3;
            l_party_site_rec.attribute4 := v_identify.attribute4;
            l_party_site_rec.attribute5 := v_identify.attribute5;
            l_party_site_rec.attribute6 := v_identify.attribute6;
            l_party_site_rec.attribute7 := v_identify.attribute7;
            l_party_site_rec.attribute8 := v_identify.attribute8;
            l_party_site_rec.attribute9 := v_identify.attribute9;
            l_party_site_rec.attribute10 := v_identify.attribute10;
            l_party_site_rec.attribute11 := v_identify.attribute11;
            l_party_site_rec.attribute12 := v_identify.attribute12;
            l_party_site_rec.attribute13 := v_identify.attribute13;
            l_party_site_rec.attribute14 := v_identify.attribute14;
            l_party_site_rec.attribute15 := v_identify.attribute15;
            l_party_site_rec.attribute16 := v_identify.attribute16;
            l_party_site_rec.attribute17 := v_identify.attribute17;
            l_party_site_rec.attribute18 := v_identify.attribute18;
            l_party_site_rec.attribute19 := v_identify.attribute19;
            l_party_site_rec.attribute20 := v_identify.attribute20;
            l_party_site_rec.LANGUAGE := v_identify.LANGUAGE;
            l_party_site_rec.addressee := v_identify.addressee;
            l_party_site_rec.created_by_module :=
                                                 v_identify.created_by_module;
            l_party_site_rec.application_id := v_identify.application_id;
            l_party_site_rec.global_location_number :=
                                            v_identify.global_location_number;
            l_party_site_rec.duns_number_c := v_identify.duns_number_c;
            hz_party_site_v2pub.update_party_site
                         (p_init_msg_list              => fnd_api.g_false,
                          p_party_site_rec             => l_party_site_rec,
                          p_object_version_number      => v_object_version_number,
                          x_return_status              => v_return_status,
                          x_msg_count                  => v_msg_count,
                          x_msg_data                   => v_msg_data
                         );
            DEBUG (   'updated for party_site_number c_identify'
                   || v_identify.party_site_number
                   || 'return_status '
                   || v_return_status
                   || 'MSG:'
                   || v_msg_count
                   || 'x_msg_data '
                   || v_msg_data
                  );
         END LOOP;

         COMMIT;

         IF v_msg_count > 1
         THEN
            v_error_msg := v_msg_data;
            DEBUG (   'v_error_msg in identifying_address_flag of ship_to '
                   || v_msg_data
                  );
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            DEBUG (   'identifying_address_flag of ship_to IN EXCEPTION'
                   || SQLERRM
                  );
      END;

      BEGIN
         DEBUG
            (   'program is running for  the identifying_address_flag of Bill_to :'
             || p_party_id1
            );

         FOR v_new_ident IN c_new_ident (p_party_id1)
         LOOP
            v_party_site_rec.party_site_id := v_new_ident.party_site_id;
            v_party_site_rec.party_id := v_new_ident.party_id;
            v_party_site_rec.location_id := v_new_ident.location_id;
            v_party_site_rec.party_site_number :=
                                                v_new_ident.party_site_number;
            v_party_site_rec.orig_system_reference :=
                                            v_new_ident.orig_system_reference;
            v_party_site_rec.mailstop := v_new_ident.mailstop;
            v_party_site_rec.identifying_address_flag := 'Y';
            v_party_site_rec.status := v_new_ident.status;
            v_party_site_rec.party_site_name := v_new_ident.party_site_name;
            v_party_site_rec.attribute_category :=
                                               v_new_ident.attribute_category;
            v_party_site_rec.attribute1 := v_new_ident.attribute1;
            v_party_site_rec.attribute2 := v_new_ident.attribute2;
            v_party_site_rec.attribute3 := v_new_ident.attribute3;
            v_party_site_rec.attribute4 := v_new_ident.attribute4;
            v_party_site_rec.attribute5 := v_new_ident.attribute5;
            v_party_site_rec.attribute6 := v_new_ident.attribute6;
            v_party_site_rec.attribute7 := v_new_ident.attribute7;
            v_party_site_rec.attribute8 := v_new_ident.attribute8;
            v_party_site_rec.attribute9 := v_new_ident.attribute9;
            v_party_site_rec.attribute10 := v_new_ident.attribute10;
            v_party_site_rec.attribute11 := v_new_ident.attribute11;
            v_party_site_rec.attribute12 := v_new_ident.attribute12;
            v_party_site_rec.attribute13 := v_new_ident.attribute13;
            v_party_site_rec.attribute14 := v_new_ident.attribute14;
            v_party_site_rec.attribute15 := v_new_ident.attribute15;
            v_party_site_rec.attribute16 := v_new_ident.attribute16;
            v_party_site_rec.attribute17 := v_new_ident.attribute17;
            v_party_site_rec.attribute18 := v_new_ident.attribute18;
            v_party_site_rec.attribute19 := v_new_ident.attribute19;
            v_party_site_rec.attribute20 := v_new_ident.attribute20;
            v_party_site_rec.LANGUAGE := v_new_ident.LANGUAGE;
            v_party_site_rec.addressee := v_new_ident.addressee;
            v_party_site_rec.created_by_module :=
                                                v_new_ident.created_by_module;
            v_party_site_rec.application_id := v_new_ident.application_id;
            v_party_site_rec.global_location_number :=
                                           v_new_ident.global_location_number;
            v_party_site_rec.duns_number_c := v_new_ident.duns_number_c;
            hz_party_site_v2pub.update_party_site
                         (p_init_msg_list              => fnd_api.g_false,
                          p_party_site_rec             => v_party_site_rec,
                          p_object_version_number      => v_object_version_number,
                          x_return_status              => v_return_status,
                          x_msg_count                  => v_msg_count,
                          x_msg_data                   => v_msg_data
                         );
            DEBUG (   'updated for party_site_number  c_new_ident '
                   || v_new_ident.party_site_number
                   || 'return_status  '
                   || v_return_status
                   || 'MSG:'
                   || v_msg_count
                   || 'x_msg_data '
                   || v_msg_data
                  );
         END LOOP;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            DEBUG (   'identifying_address_flag of Bill_to IN EXCEPTION'
                   || SQLERRM
                  );
      END;
   END identify_flag;

   PROCEDURE obsolete_deliver_to (
      errbuf        OUT      VARCHAR2,
      retcode       OUT      VARCHAR2,
      p_party_id1   IN       NUMBER,
      p_validate             VARCHAR2,
      p_months in number
   )
   IS
   v_days number;
   begin
    if p_validate='Y' then 
     v_days:=30;
     else
     v_days:=(nvl(p_months,1)*30);
    end if;
    
    declare
          CURSOR c1 (p_party_id1 IN NUMBER)
          IS
             SELECT hp.party_name, hp.party_id, hca.account_number,
                    hps.party_site_number, hcua.site_use_code,
                    hcas.cust_acct_site_id,
                    hcas.object_version_number site_object_version_number,
                    hcua.site_use_id,
                    hcua.object_version_number uses_object_version_number
               FROM apps.hz_parties hp,
                    apps.hz_party_sites hps,
                    apps.hz_party_site_uses hpsu,
                    apps.hz_cust_accounts hca,
                    apps.hz_cust_acct_sites_all hcas,
                    apps.hz_cust_site_uses_all hcua
              WHERE hp.party_id = hps.party_id
                AND hp.party_id = hca.party_id
                AND hcas.cust_account_id = hca.cust_account_id
                AND hps.party_site_id = hcas.party_site_id
                AND hcua.cust_acct_site_id = hcas.cust_acct_site_id
                AND hpsu.party_site_id = hps.party_site_id
                AND hpsu.site_use_type = 'DELIVER_TO'
                AND hcua.site_use_code = 'DELIVER_TO'
                AND hp.status = 'A'
                AND hps.status = 'A'
                AND hca.status = 'A'
                AND hcas.status = 'A'
                AND hcua.status = 'A'
                AND hpsu.status = 'A'
                AND hp.party_id = NVL (p_party_id1, hp.party_id)
                AND NOT EXISTS (
                       SELECT 1
                         FROM apps.oe_order_headers_all oha
                        WHERE oha.deliver_to_org_id IS NOT NULL
                          AND oha.open_flag = 'Y'
                          AND TRUNC (creation_date) >= TRUNC (SYSDATE - v_days)
                          AND oha.deliver_to_org_id = hcua.site_use_id)
                AND NOT EXISTS (
                       SELECT 1
                         FROM ra_customer_trx_all rcta
                        WHERE rcta.bill_to_site_use_id = hcua.site_use_id
                          AND TRUNC (rcta.creation_date) >= TRUNC (SYSDATE - v_days)
                          AND rcta.status_trx = 'OP');

          l_init_msg_list           VARCHAR2 (1000)              := fnd_api.g_true;
          l_cust_acct_site_rec      hz_cust_account_site_v2pub.cust_acct_site_rec_type;
          l_return_status           VARCHAR2 (1000);
          l_object_version_number   NUMBER;
          l_msg_count               NUMBER;
          l_msg_data                VARCHAR2 (1000);
       --  hdr long; --commented by Reshma for ticket 10312
       BEGIN
          DEBUG
             ('---------begining the updating the Inactivate obsolete Deliver To Addresses--------- '
             );
          DEBUG ('program is running for the party_id:' || p_party_id1);

          IF p_party_id1 IS NULL
          THEN
             DEBUG ('party is  null');
          END IF;

          --         SELECT 'PARTY_NAME'||'~'||'ACCOUNT_NUMBER'||'~'||'SITE_NUMBER'||'~'||'SITE_USE'  --commented by Reshma for ticket 10312
          --         INTO hdr
          --        FROM DUAL;
          DEBUG ('The program is running for validate mode:' || p_validate);
          DEBUG ('The program is running for months:' || p_months);
          --  fnd_file.put_line(fnd_file.output, hdr); --commented by Reshma for ticket 10312
          fnd_file.put_line (fnd_file.output,
                             '<?xml version="1.0" encoding="UTF-8"?>'
                            );
          fnd_file.put_line (fnd_file.output, '<PERDUMMY1>');
                                                --added by Reshma for ticket 10312

          FOR i IN c1 (p_party_id1)
          LOOP
             IF p_validate = 'Y'
             THEN
                --fnd_file.put_line(fnd_file.output,i.party_name||'~'||i.account_number||'~'||i.party_site_number||'~'||i.site_use_code);  --commented by Reshma for ticket 10312
               
                fnd_file.put_line (fnd_file.output, '<CUST>');  --added by Reshma for ticket 10312
                fnd_file.put_line (fnd_file.output,
                                      '<PARTY_NAME>'
                                   || REPLACE (i.party_name, '&', '&' || 'amp;')
                                   || '</PARTY_NAME>'
                                  );
                fnd_file.put_line (fnd_file.output,
                                      '<ACCOUNT_NUMBER>'
                                   || i.account_number
                                   || '</ACCOUNT_NUMBER>'
                                  );
                fnd_file.put_line (fnd_file.output,
                                      '<SITE_NUMBER>'
                                   || i.party_site_number
                                   || '</SITE_NUMBER>'
                                  );
                fnd_file.put_line (fnd_file.output,
                                   '<SITE_USE>' || i.site_use_code
                                   || '</SITE_USE>'
                                  );
                fnd_file.put_line (fnd_file.output, '</CUST>');
             ELSIF p_validate = 'N'
             THEN
                DEBUG ('updating for cust_account_id :' || i.cust_acct_site_id);
                l_cust_acct_site_rec.cust_acct_site_id := i.cust_acct_site_id;
                l_cust_acct_site_rec.status := 'I';
                l_object_version_number := i.site_object_version_number;
                hz_cust_account_site_v2pub.update_cust_acct_site
                                                        ('T',
                                                         l_cust_acct_site_rec,
                                                         l_object_version_number,
                                                         l_return_status,
                                                         l_msg_count,
                                                         l_msg_data
                                                        );
                DEBUG (   'updated for cust_account_id '
                       || i.cust_acct_site_id
                       || 'as  VERSION'
                       || i.site_object_version_number
                       || '-RETURN STATUS:'
                       || l_return_status
                       || 'MSG:'
                       || l_msg_data
                      );
                      
                fnd_file.put_line (fnd_file.output, '<CUST>');  --added by Reshma for ticket 10312
                fnd_file.put_line (fnd_file.output,
                                      '<PARTY_NAME>'
                                   || REPLACE (i.party_name, '&', '&' || 'amp;')
                                   || '</PARTY_NAME>'
                                  );
                fnd_file.put_line (fnd_file.output,
                                      '<ACCOUNT_NUMBER>'
                                   || i.account_number
                                   || '</ACCOUNT_NUMBER>'
                                  );
                fnd_file.put_line (fnd_file.output,
                                      '<SITE_NUMBER>'
                                   || i.party_site_number
                                   || '</SITE_NUMBER>'
                                  );
                fnd_file.put_line (fnd_file.output,
                                   '<SITE_USE>' || i.site_use_code
                                   || '</SITE_USE>'
                                  );
                fnd_file.put_line (fnd_file.output, '</CUST>');
                      
                obsolete_contact_to (i.party_id);
                       -- this procedure inactivates the contact at account level.
             END IF;
          END LOOP;

          fnd_file.put_line (fnd_file.output, '</PERDUMMY1>');  --added by Reshma for ticket 10312
          COMMIT;
          DEBUG ('---------finish updating the delivery to sites------------');
       EXCEPTION
          WHEN OTHERS
          THEN
             DEBUG ('IN EXCEPTION of obsolete_deliver_to' || SQLERRM);
         end;
   END obsolete_deliver_to;

   PROCEDURE obsolete_contact_to (p_party_id1 IN NUMBER)
   IS
      CURSOR c_update_contact (p_party_id1 IN NUMBER)
      IS
         (SELECT hcar.cust_account_role_id, hcar.party_id,
                 hcar.cust_account_id, hcar.cust_acct_site_id,
                 hcar.role_type, hcar.orig_system_reference, hcar.status,
                 hcar.created_by_module, hcar.object_version_number,
                 hp.party_name, hca.account_number
            FROM hz_cust_accounts hca,
                 apps.hz_cust_account_roles hcar,
                 apps.hz_parties hp
           WHERE hca.party_id = NVL (p_party_id1, hca.party_id)
             AND hca.cust_account_id = hcar.cust_account_id
             AND hcar.party_id = hp.party_id
             AND hcar.role_type = 'CONTACT'
             AND hcar.status = 'A'
             AND hp.party_name LIKE '.%');

      p_init_msg_list           VARCHAR2 (1000)             := fnd_api.g_false;
      p_cust_account_role_rec   hz_cust_account_role_v2pub.cust_account_role_rec_type;
      p_object_version_number   NUMBER;
      x_return_status           VARCHAR2 (250);
      x_msg_count               NUMBER;
      x_msg_data                VARCHAR2 (1000);
   BEGIN
      DEBUG
         ('---------begining the updating the obsolete_contact_to at account level--------- '
         );
      DEBUG (   'program is inactivating the obsolete_contact of party_id:'
             || p_party_id1
            );

      FOR j IN c_update_contact (p_party_id1)
      LOOP
         p_cust_account_role_rec.cust_account_role_id :=
                                                       j.cust_account_role_id;
         p_cust_account_role_rec.party_id := j.party_id;
         p_cust_account_role_rec.cust_account_id := j.cust_account_id;
         p_cust_account_role_rec.cust_acct_site_id := j.cust_acct_site_id;
         p_cust_account_role_rec.role_type := j.role_type;
         p_cust_account_role_rec.orig_system_reference :=
                                                       j.cust_account_role_id;
         p_cust_account_role_rec.created_by_module := j.created_by_module;
         p_object_version_number := j.object_version_number;
         p_cust_account_role_rec.status := 'I';
         hz_cust_account_role_v2pub.update_cust_account_role
                                                    ('T',
                                                     p_cust_account_role_rec,
                                                     p_object_version_number,
                                                     x_return_status,
                                                     x_msg_count,
                                                     x_msg_data
                                                    );
         DEBUG (   'updated for cust_account_id '
                || j.cust_account_id
                || 'as  cust_account_role_id'
                || j.cust_account_role_id
                || '-RETURN STATUS:'
                || x_return_status
                || 'MSG:'
                || x_msg_data
                || 'COUNT'
                || x_msg_count
               );
      END LOOP;

      COMMIT;
      DEBUG
         ('---------finish updating the obsolete_contact_to at account level------------'
         );
   EXCEPTION
      WHEN OTHERS
      THEN
         DEBUG ('IN EXCEPTION of  obsolete_contact_to ' || SQLERRM);
   END obsolete_contact_to;

   PROCEDURE obsolete_quoting_data (
      errbuf        OUT      VARCHAR2,
      retcode       OUT      VARCHAR2,
      p_party_id1   IN       NUMBER
   )
   IS
      CURSOR c2 (p_party_id1 IN NUMBER)
      IS
         SELECT hcas.cust_acct_site_id,
                hcas.object_version_number site_object_version_number,
                hcua.site_use_id,
                hcua.object_version_number uses_object_version_number
           FROM apps.hz_parties hp,
                apps.hz_party_sites hps,
                apps.hz_party_site_uses hpsu,
                apps.hz_cust_accounts hca,
                apps.hz_cust_acct_sites_all hcas,
                apps.hz_cust_site_uses_all hcua
          WHERE hp.party_id = hps.party_id
            AND hp.party_id = hca.party_id
            AND hcas.cust_account_id = hca.cust_account_id
            AND hps.party_site_id = hcas.party_site_id
            AND hcua.cust_acct_site_id = hcas.cust_acct_site_id
            AND hpsu.party_site_id = hps.party_site_id
            AND hp.party_id = NVL (p_party_id1, hp.party_id)
            AND hpsu.status = 'A'
            AND hp.status = 'A'
            AND hps.status = 'A'
            AND hca.status = 'A'
            AND hcas.status = 'A'
            AND hcua.status = 'A'
            AND hcua.site_use_code = 'SHIP_TO'
            AND hpsu.site_use_type = 'DELIVER_TO'
            AND hpsu.created_by_module = 'ASO_CUSTOMER_DATA';

      l_init_msg_list           VARCHAR2 (1000)              := fnd_api.g_true;
      l_cust_acct_site_rec      hz_cust_account_site_v2pub.cust_acct_site_rec_type;
      l_return_status           VARCHAR2 (1000);
      l_object_version_number   NUMBER;
      l_msg_count               NUMBER;
      l_msg_data                VARCHAR2 (1000);
   -- L_SITE_USE_ID             NUMBER;
   --  p_cust_acct_site_id number;
   --  p_object_version_number number;
   BEGIN
      DEBUG ('---------obsolete_quoting_data--------- ');
      DEBUG ('program is running for the party_id:' || p_party_id1);

      FOR i IN c2 (p_party_id1)
      LOOP
         DEBUG ('updating for cust_account_id :' || i.cust_acct_site_id);
         l_cust_acct_site_rec.cust_acct_site_id := i.cust_acct_site_id;
         l_cust_acct_site_rec.status := 'I';
         l_object_version_number := i.site_object_version_number;
         hz_cust_account_site_v2pub.update_cust_acct_site
                                                    ('T',
                                                     l_cust_acct_site_rec,
                                                     l_object_version_number,
                                                     l_return_status,
                                                     l_msg_count,
                                                     l_msg_data
                                                    );
         DEBUG (   'updated for cust_account_id '
                || i.cust_acct_site_id
                || 'as  VERSION'
                || i.site_object_version_number
                || '-RETURN STATUS:'
                || l_return_status
                || 'MSG:'
                || l_msg_data
               );
      END LOOP;

      COMMIT;
      DEBUG ('--------obsolete_quoting_data--------- ');
   EXCEPTION
      WHEN OTHERS
      THEN
         DEBUG ('in exception for obsolete_quoting_data ' || SQLERRM);
   END obsolete_quoting_data;
END xxintg_cust_maintenance_pkg; 
/
