DROP PACKAGE BODY APPS.XX_AP_SUS_CONTACT_CNV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AP_SUS_CONTACT_CNV_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 06-FEB-2011
 File Name     : XXAPSUSCONTCNV.pkb
 Description   : This script creates the body of the package
                 XX_AP_SUS_CONTACT_CNV_PKG
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 06-FEB-2011 Sharath Babu          Initial Version
 07-MAY-2013 Sharath Babu          Modified as per Wave1
*/
----------------------------------------------------------------------

   -- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
   -- START RESTRICTIONS

   --------------------------------------------------------------------------------
    ------------------< set_cnv_env >-----------------------------------------------
    --------------------------------------------------------------------------------
   PROCEDURE set_cnv_env (
      p_batch_id        VARCHAR2,
      p_required_flag   VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_yes
   )
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      g_batch_id := p_batch_id;
      -- Set the environment
      x_error_code := xx_emf_pkg.set_env;

      IF NVL (p_required_flag, xx_emf_cn_pkg.cn_yes) <> xx_emf_cn_pkg.cn_no
      THEN
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE xx_emf_pkg.g_e_env_not_set;
   END set_cnv_env;

    --------------------------------------------------------------------------------
    ------------------< mark_records_for_processing >-------------------------------
    --------------------------------------------------------------------------------
   PROCEDURE mark_records_for_processing (
      p_restart_flag    IN   VARCHAR2,
      p_override_flag   IN   VARCHAR2
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      -- If the override is set records should not be purged from the pre-interface tables
      IF p_restart_flag = xx_emf_cn_pkg.cn_all_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- purge from pre-interface tables and oracle standard tables
            DELETE FROM xx_ap_sup_site_contact_pre_int
                  WHERE batch_id = g_batch_id;

            UPDATE xx_ap_sup_site_contact_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id;
         ELSE
            UPDATE xx_ap_sup_site_contact_pre_int
               SET process_code = xx_emf_cn_pkg.cn_preval,
                   ERROR_CODE = xx_emf_cn_pkg.cn_success,
                   request_id = xx_emf_pkg.g_request_id
             WHERE batch_id = g_batch_id;
         END IF;

         DELETE ap_sup_site_contact_int sscont
	  WHERE sscont.last_name IN (SELECT last_name
	                               FROM xx_ap_sup_site_contact_stg
	                              WHERE vendor_site_code    = sscont.vendor_site_code
	                                AND operating_unit_name = sscont.operating_unit_name);

      ELSIF p_restart_flag = xx_emf_cn_pkg.cn_err_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- Update staging table
            UPDATE xx_ap_sup_site_contact_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id
               AND (   process_code = xx_emf_cn_pkg.cn_new
                    OR (    process_code = xx_emf_cn_pkg.cn_preval
                        AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_rec_err) IN
                               (xx_emf_cn_pkg.cn_rec_warn,
                                xx_emf_cn_pkg.cn_rec_err
                               )
                       )
                   );
         END IF;

         -- Update pre-interface table
         -- Scenario 1 Pre-Validation Stage
         UPDATE xx_ap_sup_site_contact_stg
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new
          WHERE batch_id = g_batch_id
            AND EXISTS (
                   SELECT 1
                     FROM xx_ap_sup_site_contact_pre_int a
                    WHERE batch_id = g_batch_id
                      AND process_code = xx_emf_cn_pkg.cn_preval
                      AND ERROR_CODE IN
                             (xx_emf_cn_pkg.cn_null,
                              xx_emf_cn_pkg.cn_rec_warn,
                              xx_emf_cn_pkg.cn_rec_err
                             )
                      AND record_number = a.record_number);

         DELETE FROM xx_ap_sup_site_contact_pre_int
               WHERE batch_id = g_batch_id
                 AND process_code = xx_emf_cn_pkg.cn_preval
                 AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_null,
                         xx_emf_cn_pkg.cn_rec_warn,
                         xx_emf_cn_pkg.cn_rec_err
                        );

         -- Scenario 2 Data Validation Stage
         UPDATE xx_ap_sup_site_contact_pre_int
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_preval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_valid
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 3 Data Derivation Stage
         UPDATE xx_ap_sup_site_contact_pre_int
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_derive
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_derive
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 4 Post Validation Stage
         UPDATE xx_ap_sup_site_contact_pre_int
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_postval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_postval
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 5 Process Data Stage
         UPDATE xx_ap_sup_site_contact_pre_int
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_postval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_process_data
            AND ERROR_CODE IN
                            (xx_emf_cn_pkg.cn_null, xx_emf_cn_pkg.cn_rec_err);
      END IF;

      COMMIT;
   END;

    --------------------------------------------------------------------------------
    ------------------< set_stage >-------------------------------------------------
    --------------------------------------------------------------------------------
   PROCEDURE set_stage (p_stage VARCHAR2)
   IS
   BEGIN
      g_stage := p_stage;
   END set_stage;

   PROCEDURE update_staging_records (p_error_code VARCHAR2,p_record_number NUMBER)
   IS
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE xx_ap_sup_site_contact_stg
         SET process_code = g_stage,
             ERROR_CODE = DECODE (ERROR_CODE, NULL, p_error_code, ERROR_CODE),
             last_update_date = x_last_update_date,
             last_updated_by = x_last_updated_by,
             last_update_login = x_last_update_login
       WHERE batch_id = g_batch_id
         AND request_id = xx_emf_pkg.g_request_id
         AND process_code = xx_emf_cn_pkg.cn_new
         AND record_number = p_record_number;

      COMMIT;
   END update_staging_records;

    --------------------------------------------------------------------------------
    ------------------< main >------------------------------------------------------
    --------------------------------------------------------------------------------
   PROCEDURE main (
      errbuf                OUT      VARCHAR2,
      retcode               OUT      VARCHAR2,
      p_batch_id            IN       VARCHAR2,
      p_restart_flag        IN       VARCHAR2,
      p_override_flag       IN       VARCHAR2,
      p_validate_and_load   IN       VARCHAR2
   )
   IS
      x_error_code          NUMBER                := xx_emf_cn_pkg.cn_success;
      x_cnv_stg_tbl         g_xx_sus_cont_stg_tab_type;
      x_pre_std_hdr_table   g_xx_sus_cont_pre_std_tab_type;
      x_process_code        VARCHAR2 (100);

      -- Cursor for pre validation
      CURSOR c_xx_ap_sup_site_contact_stg (cp_process_status VARCHAR2)
      IS --Modified as per Wave1
         SELECT   batch_id
		 ,record_number
		 ,vendor_site_code
		 ,operating_unit_name
		 ,inactive_date
		 ,first_name
		 ,middle_name
		 ,last_name
		 ,prefix
		 ,title
		 ,mail_stop
		 ,area_code
		 ,phone
		 ,department
		 ,email_address
		 ,url
		 ,alt_area_code
		 ,alt_phone
		 ,fax_area_code
		 ,fax
		 ,legacy_supplier_number
		 ,process_code
		 ,ERROR_CODE
		 ,created_by
		 ,creation_date
		 ,last_update_date
		 ,last_updated_by
		 ,last_update_login
		 ,request_id
             FROM xx_ap_sup_site_contact_stg hdr
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              AND ERROR_CODE IS NULL
         ORDER BY record_number;

      -- Cursor for various stages
      CURSOR c_xx_ap_sup_site_cont_pre_int (cp_process_status VARCHAR2)
      IS
         SELECT  vendor_site_id
		,org_id
		,operating_unit_name
		,inactive_date
		,first_name
		,middle_name
		,last_name
		,prefix
		,title
		,mail_stop
		,area_code
		,phone
		,program_application_id
		,program_id
		,program_update_date
		,request_id
		,contact_name_alt
		,first_name_alt
		,last_name_alt
		,department
		,email_address
		,url
		,alt_area_code
		,alt_phone
		,fax_area_code
		,fax
		,vendor_interface_id
		,vendor_id
		,vendor_contact_interface_id
		,party_site_id
		,party_site_name
		,party_orig_system
		,party_orig_system_reference
		,party_site_orig_system
		,party_site_orig_sys_reference
		,supplier_site_orig_system
		,sup_site_orig_system_reference
		,contact_orig_system
		,contact_orig_system_reference
		,party_id
		,per_party_id
		,rel_party_id
		,relationship_id
		,org_contact_id
		,vendor_site_code
		,legacy_supplier_number
		,process_code
		,error_code
		,record_number
		,batch_id
		,creation_date
		,created_by
		,last_update_date
		,last_updated_by
		,last_update_login
             FROM xx_ap_sup_site_contact_pre_int hdr
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
         ORDER BY record_number;

      PROCEDURE update_record_status (
         p_conv_pre_std_hdr_rec   IN OUT   g_xx_sus_cont_pre_std_rec_type,
         p_error_code             IN       VARCHAR2
      )
      IS
      BEGIN
         IF p_error_code IN
                        (xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err)
         THEN
            p_conv_pre_std_hdr_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            p_conv_pre_std_hdr_rec.ERROR_CODE :=
               xx_intg_common_pkg.find_max
                                     (p_error_code,
                                      NVL (p_conv_pre_std_hdr_rec.ERROR_CODE,
                                           xx_emf_cn_pkg.cn_success
                                          )
                                     );
         END IF;

         p_conv_pre_std_hdr_rec.process_code := g_stage;
      END update_record_status;

      PROCEDURE mark_records_complete (p_process_code VARCHAR2)
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  '  inside mark_records_complete '
                               || p_process_code
                              );
         UPDATE xx_ap_sup_site_contact_pre_int
            SET process_code = g_stage,
                ERROR_CODE = NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success),
                last_updated_by = x_last_updated_by,
                last_update_date = x_last_update_date,
                last_update_login = x_last_update_login
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND process_code =
                   DECODE (p_process_code,
                           xx_emf_cn_pkg.cn_process_data, xx_emf_cn_pkg.cn_postval,
                           xx_emf_cn_pkg.cn_derive
                          )
            AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn);

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'others ' || p_process_code
                                 );
      END mark_records_complete;

      PROCEDURE update_pre_interface_records (
         p_cnv_pre_std_hdr_table   IN   g_xx_sus_cont_pre_std_tab_type
      )
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         FOR indx IN 1 .. p_cnv_pre_std_hdr_table.COUNT
         LOOP
            xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                'p_cnv_pre_std_hdr_table(indx).process_code '
                             || p_cnv_pre_std_hdr_table (indx).process_code
                            );
            xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                   'p_cnv_pre_std_hdr_table(indx).error_code '
                                || p_cnv_pre_std_hdr_table (indx).ERROR_CODE
                               );

            UPDATE  xx_ap_sup_site_contact_pre_int
                SET
                 vendor_site_id                 =p_cnv_pre_std_hdr_table(indx).vendor_site_id
		,org_id                         =p_cnv_pre_std_hdr_table(indx).org_id
		,operating_unit_name            =p_cnv_pre_std_hdr_table(indx).operating_unit_name
		,inactive_date                  =p_cnv_pre_std_hdr_table(indx).inactive_date
		,first_name                     =p_cnv_pre_std_hdr_table(indx).first_name
		,middle_name                    =p_cnv_pre_std_hdr_table(indx).middle_name
		,last_name                      =p_cnv_pre_std_hdr_table(indx).last_name
		,prefix                         =p_cnv_pre_std_hdr_table(indx).prefix
		,title                          =p_cnv_pre_std_hdr_table(indx).title
		,mail_stop                      =p_cnv_pre_std_hdr_table(indx).mail_stop
		,area_code                      =p_cnv_pre_std_hdr_table(indx).area_code
		,phone                          =p_cnv_pre_std_hdr_table(indx).phone
		,program_application_id         =p_cnv_pre_std_hdr_table(indx).program_application_id
		,program_id                     =p_cnv_pre_std_hdr_table(indx).program_id
		,program_update_date            =p_cnv_pre_std_hdr_table(indx).program_update_date
		,contact_name_alt               =p_cnv_pre_std_hdr_table(indx).contact_name_alt
		,first_name_alt                 =p_cnv_pre_std_hdr_table(indx).first_name_alt
		,last_name_alt                  =p_cnv_pre_std_hdr_table(indx).last_name_alt
		,department                     =p_cnv_pre_std_hdr_table(indx).department
		,email_address                  =p_cnv_pre_std_hdr_table(indx).email_address
		,url                            =p_cnv_pre_std_hdr_table(indx).url
		,alt_area_code                  =p_cnv_pre_std_hdr_table(indx).alt_area_code
		,alt_phone                      =p_cnv_pre_std_hdr_table(indx).alt_phone
		,fax_area_code                  =p_cnv_pre_std_hdr_table(indx).fax_area_code
		,fax                            =p_cnv_pre_std_hdr_table(indx).fax
		,vendor_id                      =p_cnv_pre_std_hdr_table(indx).vendor_id
		,party_site_id                  =p_cnv_pre_std_hdr_table(indx).party_site_id
		,party_site_name                =p_cnv_pre_std_hdr_table(indx).party_site_name
		,party_orig_system              =p_cnv_pre_std_hdr_table(indx).party_orig_system
		,party_orig_system_reference    =p_cnv_pre_std_hdr_table(indx).party_orig_system_reference
		,party_site_orig_system         =p_cnv_pre_std_hdr_table(indx).party_site_orig_system
		,party_site_orig_sys_reference  =p_cnv_pre_std_hdr_table(indx).party_site_orig_sys_reference
		,supplier_site_orig_system      =p_cnv_pre_std_hdr_table(indx).supplier_site_orig_system
		,sup_site_orig_system_reference =p_cnv_pre_std_hdr_table(indx).sup_site_orig_system_reference
		,contact_orig_system            =p_cnv_pre_std_hdr_table(indx).contact_orig_system
		,contact_orig_system_reference  =p_cnv_pre_std_hdr_table(indx).contact_orig_system_reference
		,party_id                       =p_cnv_pre_std_hdr_table(indx).party_id
		,per_party_id                   =p_cnv_pre_std_hdr_table(indx).per_party_id
		,rel_party_id                   =p_cnv_pre_std_hdr_table(indx).rel_party_id
		,relationship_id                =p_cnv_pre_std_hdr_table(indx).relationship_id
		,org_contact_id                 =p_cnv_pre_std_hdr_table(indx).org_contact_id
		,vendor_site_code               =p_cnv_pre_std_hdr_table(indx).vendor_site_code
		,legacy_supplier_number         =p_cnv_pre_std_hdr_table(indx).legacy_supplier_number
		,process_code	                =p_cnv_pre_std_hdr_table(indx).process_code
		,error_code		        =p_cnv_pre_std_hdr_table(indx).error_code
		,request_id		        =p_cnv_pre_std_hdr_table(indx).request_id
                ,last_updated_by                =x_last_updated_by
                ,last_update_date               =x_last_update_date
                ,last_update_login              =x_last_update_login
                WHERE record_number = p_cnv_pre_std_hdr_table(indx).record_number
                  AND batch_id = p_cnv_pre_std_hdr_table(indx).batch_id;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'The vendor is after update '
                                  || p_cnv_pre_std_hdr_table (indx).vendor_id
                                 );
         END LOOP;

         COMMIT;
      END update_pre_interface_records;

        -------------------------------------------------------------------------
        -----------< move_rec_pre_standard_table >-------------------------------
        -------------------------------------------------------------------------
      FUNCTION move_rec_pre_standard_table
         RETURN NUMBER
      IS
         x_creation_date       DATE   := SYSDATE;
         x_created_by          NUMBER := fnd_global.user_id;
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         x_error_code          NUMBER := xx_emf_cn_pkg.cn_success;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside move_rec_pre_standard_table'
                              );
         -- Select only the appropriate columns that are required to be inserted into the
         -- Pre-Interface Table and insert from the Staging Table
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                    'Inserting Records into xx_ap_sup_site_contact_pre_int ..'
                   );

         INSERT INTO xx_ap_sup_site_contact_pre_int
                        (
                vendor_site_code
	       ,operating_unit_name
	       ,inactive_date
	       ,first_name
	       ,middle_name
	       ,last_name
	       ,prefix
	       ,title
	       ,mail_stop
	       ,area_code
	       ,phone
	       ,department
	       ,email_address
	       ,url
	       ,alt_area_code
	       ,alt_phone
	       ,fax_area_code
	       ,fax
	       ,legacy_supplier_number
               ,batch_id
               ,record_number
               ,process_code
               ,error_code
               ,request_id
               ,created_by
               ,creation_date
               ,last_update_date
               ,last_updated_by
               ,last_update_login
                        )
             SELECT
		 vendor_site_code
		,operating_unit_name
		,inactive_date
		,first_name
		,middle_name
		,last_name
		,prefix
		,title
		,mail_stop
		,area_code
		,phone
		,department
		,email_address
		,url
		,alt_area_code
		,alt_phone
		,fax_area_code
		,fax
		,legacy_supplier_number
                ,batch_id
                ,record_number
                ,G_STAGE
                ,error_code
                ,request_id
                ,x_created_by
                ,x_creation_date
                ,x_last_update_date
                ,x_last_updated_by
                ,x_last_update_login
                    FROM xx_ap_sup_site_contact_stg
                         WHERE BATCH_ID     = G_BATCH_ID
                           AND process_code = xx_emf_cn_pkg.CN_PREVAL
                           AND request_id   = xx_emf_pkg.G_REQUEST_ID
                           AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

         COMMIT;

         IF SQL%ROWCOUNT > 0
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'No Of Records Inserted : ' || SQL%ROWCOUNT
                              );
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                'Error While Inserting Records into xx_ap_sup_site_contact_pre_int ..'
               );
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand
                             );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            RETURN x_error_code;
      END move_rec_pre_standard_table;

        -------------------------------------------------------------------------
        -----------< process_data >----------------------------------------------
        -------------------------------------------------------------------------
      FUNCTION process_data
         RETURN NUMBER
      IS
         x_return_status   VARCHAR2 (15) := xx_emf_cn_pkg.cn_success;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         -- Change the logic to whatever needs to be done
         -- with valid records in the pre-interface tables
         -- either call the appropriate API to process the data
         -- or to insert into an interface table
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                          'Inserting Records into ap_sup_site_contact_int ..'
                         );

         INSERT INTO ap_sup_site_contact_int
                        (
                   vendor_site_id
		,  vendor_site_code
		,  org_id
		,  operating_unit_name
		,  last_update_date
		,  last_updated_by
		,  last_update_login
		,  creation_date
		,  created_by
		,  inactive_date
		,  first_name
		,  middle_name
		,  last_name
		,  prefix
		,  title
		,  mail_stop
		,  area_code
		,  phone
		,  program_application_id
		,  program_id
		,  program_update_date
		,  contact_name_alt
		,  first_name_alt
		,  last_name_alt
		,  department
		,  status
		,  email_address
		,  url
		,  alt_area_code
		,  alt_phone
		,  fax_area_code
		,  fax
		,  vendor_interface_id
		,  vendor_id
		,  vendor_contact_interface_id
		,  party_site_id
		,  party_site_name
		,  party_orig_system
		,  party_orig_system_reference
		,  party_site_orig_system
		,  party_site_orig_sys_reference
		,  supplier_site_orig_system
		,  sup_site_orig_system_reference
		,  contact_orig_system
		,  contact_orig_system_reference
		,  party_id
		,  per_party_id
		,  rel_party_id
		,  relationship_id
		,  org_contact_id
			    )
					SELECT
		  vendor_site_id
		,  vendor_site_code
		,  org_id
		,  operating_unit_name
		,  last_update_date
		,  last_updated_by
		,  last_update_login
		,  creation_date
		,  created_by
		,  inactive_date
		,  first_name
		,  middle_name
		,  last_name
		,  prefix
		,  title
		,  mail_stop
		,  area_code
		,  phone
		,  program_application_id
		,  program_id
		,  program_update_date
		,  contact_name_alt
		,  first_name_alt
		,  last_name_alt
		,  department
		,  'NEW'
		,  email_address
		,  url
		,  alt_area_code
		,  alt_phone
		,  fax_area_code
		,  fax
		,  ap_suppliers_int_s.nextval                  --vendor_interface_id
		,  vendor_id
		,  ap_sup_site_contact_int_s.nextval                --vendor_contact_interface_id
		,  party_site_id
		,  party_site_name
		,  party_orig_system
		,  party_orig_system_reference
		,  party_site_orig_system
		,  party_site_orig_sys_reference
		,  supplier_site_orig_system
		,  sup_site_orig_system_reference
		,  contact_orig_system
		,  contact_orig_system_reference
		,  party_id
		,  per_party_id
		,  rel_party_id
		,  relationship_id
		,  org_contact_id
             FROM xx_ap_sup_site_contact_pre_int
                         WHERE batch_id = G_BATCH_ID
                           AND request_id = xx_emf_pkg.G_REQUEST_ID
                           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                           AND process_code = xx_emf_cn_pkg.CN_POSTVAL;

         COMMIT;
         RETURN x_return_status;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                'Error While Inserting Records into ap_sup_site_contact_int ..'
               );
            xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                                 'Error while inserting into Inerface Table: '
                              || SQLERRM
                             );
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand
                             );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            RETURN x_error_code;
      END process_data;

-------------------------------------------------------------------------
-----------< update_record_count >--------------------------------------
-------------------------------------------------------------------------
      PROCEDURE update_record_count
      IS
         CURSOR c_get_total_cnt
         IS
            SELECT SUM (total_count)
              FROM (SELECT COUNT (1) total_count
                      FROM xx_ap_sup_site_contact_stg
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                    UNION
                    SELECT COUNT (1) total_count
                      FROM xx_ap_sup_site_contact_pre_int
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id);

         x_total_cnt     NUMBER;

         CURSOR c_get_error_cnt
         IS
            SELECT SUM (error_count)
              FROM (SELECT COUNT (1) error_count
                      FROM xx_ap_sup_site_contact_stg
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err
                    UNION ALL
                    SELECT COUNT (1) error_count
                      FROM xx_ap_sup_site_contact_pre_int
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err);

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_ap_sup_site_contact_pre_int
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

         x_warn_cnt      NUMBER;

         CURSOR c_get_success_cnt
         IS
            SELECT COUNT (1) success_count
              FROM xx_ap_sup_site_contact_pre_int
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               --AND process_code = xx_emf_cn_pkg.cn_process_data
               AND ERROR_CODE = xx_emf_cn_pkg.cn_success;

         x_success_cnt   NUMBER;
      BEGIN
         OPEN c_get_total_cnt;

         FETCH c_get_total_cnt
          INTO x_total_cnt;

         CLOSE c_get_total_cnt;

         OPEN c_get_error_cnt;

         FETCH c_get_error_cnt
          INTO x_error_cnt;

         CLOSE c_get_error_cnt;

         OPEN c_get_warning_cnt;

         FETCH c_get_warning_cnt
          INTO x_warn_cnt;

         CLOSE c_get_warning_cnt;

         OPEN c_get_success_cnt;

         FETCH c_get_success_cnt
          INTO x_success_cnt;

         CLOSE c_get_success_cnt;

         xx_emf_pkg.update_recs_cnt (p_total_recs_cnt        => x_total_cnt,
                                     p_success_recs_cnt      => x_success_cnt,
                                     p_warning_recs_cnt      => x_warn_cnt,
                                     p_error_recs_cnt        => x_error_cnt
                                    );
      END update_record_count;

   BEGIN
      retcode := xx_emf_cn_pkg.cn_success;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Before Setting Environment'
                           );
      set_cnv_env (p_batch_id           => p_batch_id,
                   p_required_flag      => xx_emf_cn_pkg.cn_yes
                  );
      -- include all the parameters to the conversion main here
      -- as medium log messages
      xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_medium,
                         'Starting main process with the following parameters'
                        );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_batch_id ' || p_batch_id
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_restart_flag ' || p_restart_flag
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_override_flag ' || p_override_flag
                           );
      -- Call procedure to update records with the current request_id
      -- So that we can process only those records
      -- This gives a better handling of restartability
      mark_records_for_processing (p_restart_flag       => p_restart_flag,
                                   p_override_flag      => p_override_flag
                                  );

        --------------------------------------
        ----------Pre Validation--------------
        --------------------------------------
        -- Start with pre-validations
      IF NVL (p_override_flag, xx_emf_cn_pkg.cn_no) = xx_emf_cn_pkg.cn_no
      THEN
         -- Set the stage to Pre Validations
         set_stage (xx_emf_cn_pkg.cn_preval);

         OPEN c_xx_ap_sup_site_contact_stg (xx_emf_cn_pkg.cn_new);

         FETCH c_xx_ap_sup_site_contact_stg
         BULK COLLECT INTO x_cnv_stg_tbl;

         FOR i IN 1 .. x_cnv_stg_tbl.COUNT
         LOOP
            BEGIN
               -- Change the validations package to the appropriate package name
               -- Modify the parameters as required
               -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
               -- PRE_VALIDATIONS SHOULD BE RETAINED
               x_error_code :=
                  xx_ap_sus_contact_valid_pkg.pre_validations (x_cnv_stg_tbl (i));
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                        'After pre-validations X_ERROR_CODE '
                                     || x_error_code
                                    );
               -- Update process code of staging records
               update_staging_records (x_error_code,x_cnv_stg_tbl(i).record_number);
               xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
	        -- If HIGH error then it will be propagated to the next level
	        -- IF the process has to continue maintain it as a medium severity
	        WHEN xx_emf_pkg.g_e_rec_error
	        THEN
	           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
	                                 xx_emf_cn_pkg.cn_rec_err
	                                );
	        WHEN xx_emf_pkg.g_e_prc_error
	        THEN
	           xx_emf_pkg.write_log
	                            (xx_emf_cn_pkg.cn_high,
	                             'Process Level Error in Pre Validations'
	                            );
	           update_pre_interface_records (x_pre_std_hdr_table);
	           raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
	        WHEN OTHERS
	        THEN
	           xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
	                             xx_emf_cn_pkg.cn_tech_error,
	                             xx_emf_cn_pkg.cn_exp_unhand,
	                             x_pre_std_hdr_table (i).record_number
                                     );
            END;
         END LOOP;

         IF c_xx_ap_sup_site_contact_stg%ISOPEN
         THEN
            CLOSE c_xx_ap_sup_site_contact_stg;
         END IF;

         -- Also move the successful records to pre-interface tables
         x_error_code := move_rec_pre_standard_table;
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;

      /* Added for batch validation */
        -- Once the records are identified based on the input parameters
        -- Start with batch-validations
        -- Set the stage to Batch Validations
        --------------------------------------
        ----------Btach Validation------------
        --------------------------------------
      set_stage (xx_emf_cn_pkg.cn_batchval);
      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
      -- batch_validations SHOULD BE RETAINED
      x_error_code :=
                    xx_ap_sus_contact_valid_pkg.batch_validations (p_batch_id);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'After batch_validations X_ERROR_CODE '
                            || x_error_code
                           );
      xx_emf_pkg.propagate_error (x_error_code);
        -- Once pre-validations are complete the loop through the pre-interface records
        -- and perform data validations on this table
        -- Set the stage to data Validations
        --------------------------------------
        ----------Data Validation-------------
        --------------------------------------
      set_stage (xx_emf_cn_pkg.cn_valid);

      OPEN c_xx_ap_sup_site_cont_pre_int (xx_emf_cn_pkg.cn_preval);

      LOOP
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'In the pre interface records loop'
                              );

         FETCH c_xx_ap_sup_site_cont_pre_int
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               -- Perform Data Validations
               x_error_code :=
                  xx_ap_sus_contact_valid_pkg.data_validations
                                                      (x_pre_std_hdr_table (i)
                                                      );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'After Data Validations ... x_error_code : '
                               || x_error_code
                              );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'x_error_code for  '
                                     || x_pre_std_hdr_table (i).record_number
                                     || ' is '
                                     || x_error_code
                                    );
               update_record_status (x_pre_std_hdr_table (i), x_error_code);
               xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
               WHEN xx_emf_pkg.g_e_rec_error
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                        xx_emf_cn_pkg.cn_rec_err
                                       );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
                  xx_emf_pkg.write_log
                                   (xx_emf_cn_pkg.cn_high,
                                    'Process Level Error in Data Validations'
                                   );
                  update_pre_interface_records (x_pre_std_hdr_table);
                  raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
               WHEN OTHERS
               THEN
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    xx_emf_cn_pkg.cn_exp_unhand,
                                    x_pre_std_hdr_table (i).record_number
                                   );
            END;
         END LOOP;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'x_pre_std_hdr_table.count '
                               || x_pre_std_hdr_table.COUNT
                              );
         update_pre_interface_records (x_pre_std_hdr_table);
         x_pre_std_hdr_table.DELETE;
         EXIT WHEN c_xx_ap_sup_site_cont_pre_int%NOTFOUND;
      END LOOP;

      IF c_xx_ap_sup_site_cont_pre_int%ISOPEN
      THEN
         CLOSE c_xx_ap_sup_site_cont_pre_int;
      END IF;

      -- Once data-validations are complete the loop through the pre-interface records
      -- and perform data derivations on this table
      --------------------------------------
      ----------Data Derivation-------------
      --------------------------------------
       -- Set the stage to data derivations
       set_stage (xx_emf_cn_pkg.cn_derive);

       OPEN c_xx_ap_sup_site_cont_pre_int (xx_emf_cn_pkg.cn_valid);

       LOOP
          FETCH c_xx_ap_sup_site_cont_pre_int
          BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

          FOR i IN 1 .. x_pre_std_hdr_table.COUNT
          LOOP
             BEGIN
                -- Perform Data Derivations
                x_error_code :=
                   xx_ap_sus_contact_valid_pkg.data_derivations
                                                    (x_pre_std_hdr_table (i)
                                                    );
                xx_emf_pkg.write_log
                                    (xx_emf_cn_pkg.cn_low,
                                        'x_error_code for  '
                                     || x_pre_std_hdr_table (i).record_number
                                     || ' is '
                                     || x_error_code
                                    );
                update_record_status (x_pre_std_hdr_table (i), x_error_code);
                xx_emf_pkg.propagate_error (x_error_code);
             EXCEPTION
                -- If HIGH error then it will be propagated to the next level
                -- IF the process has to continue maintain it as a medium severity
                WHEN xx_emf_pkg.g_e_rec_error
                THEN
                   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                         xx_emf_cn_pkg.cn_rec_err
                                        );
                WHEN xx_emf_pkg.g_e_prc_error
                THEN
                   xx_emf_pkg.write_log
                                 (xx_emf_cn_pkg.cn_high,
                                  'Process Level Error in Data derivations'
                                 );
                   update_pre_interface_records (x_pre_std_hdr_table);
                   raise_application_error (-20199,
                                            xx_emf_cn_pkg.cn_prc_err);
                WHEN OTHERS
                THEN
                   xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                     xx_emf_cn_pkg.cn_tech_error,
                                     xx_emf_cn_pkg.cn_exp_unhand,
                                     x_pre_std_hdr_table (i).record_number
                                    );
             END;
          END LOOP;

          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                   'x_pre_std_hdr_table.count '
                                || x_pre_std_hdr_table.COUNT
                               );
          update_pre_interface_records (x_pre_std_hdr_table);
          x_pre_std_hdr_table.DELETE;
          EXIT WHEN c_xx_ap_sup_site_cont_pre_int%NOTFOUND;
       END LOOP;

       IF c_xx_ap_sup_site_cont_pre_int%ISOPEN
       THEN
          CLOSE c_xx_ap_sup_site_cont_pre_int;
       END IF;

	--------------------------------------
	----------Post Validation-------------
	--------------------------------------
	-- Set the stage to Post Validations
       set_stage (xx_emf_cn_pkg.cn_postval);
       -- Change the validations package to the appropriate package name
       -- Modify the parameters as required
       -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
       -- PRE_VALIDATIONS SHOULD BE RETAINED
       x_error_code := xx_ap_sus_contact_valid_pkg.post_validations ();
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                'After post-validations X_ERROR_CODE '
                             || x_error_code
                            );
       mark_records_complete (xx_emf_cn_pkg.cn_postval);
       xx_emf_pkg.propagate_error (x_error_code);
	--------------------------------------
	----------Process Data----------------
	--------------------------------------
	-- Set the stage to Process Data
	-- Perform process data only if p_validate_and_load is set to VALIDATE_AND_LOAD
      IF p_validate_and_load = g_validate_and_load
      THEN
         set_stage (xx_emf_cn_pkg.cn_process_data);
         x_error_code := process_data;
         mark_records_complete (xx_emf_cn_pkg.cn_process_data);
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;                                 --End If for p_validate_and_load

      update_record_count;
      --xx_emf_pkg.create_report; Modified as per Wave1 to display distinct errors
      xx_emf_pkg.generate_report;

   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               xx_emf_pkg.cn_env_not_set);
         retcode := xx_emf_cn_pkg.cn_rec_err;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         retcode := xx_emf_cn_pkg.cn_rec_err;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         retcode := xx_emf_cn_pkg.cn_prc_err;
         xx_emf_pkg.create_report;
      WHEN OTHERS
      THEN
         retcode := xx_emf_cn_pkg.cn_prc_err;
         xx_emf_pkg.create_report;
   END main;
END xx_ap_sus_contact_cnv_pkg;
/


GRANT EXECUTE ON APPS.XX_AP_SUS_CONTACT_CNV_PKG TO INTG_XX_NONHR_RO;
