DROP PACKAGE BODY APPS.XX_AP_SUS_CONTACT_VALID_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AP_SUS_CONTACT_VALID_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 06-FEB-2011
 File Name     : XXAPSUSCONTVAL.pkb
 Description   : This script creates the body of the package
                 xx_ap_sus_contact_valid_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 06-FEB-2012 Sharath Babu          Initial Version
 03-MAY-2012 Sharath Babu          Added mapping value func for operating unit
 22-JUN-2012 Sharath Babu          Modified to handle duplicate leg sup num issue
 07-MAY-2013 Sharath Babu          Modified as per Wave1
*/
----------------------------------------------------------------------
   FUNCTION find_max (p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2)
      RETURN VARCHAR2
   IS
      x_return_value   VARCHAR2 (100);
   BEGIN
      x_return_value :=
                   xx_intg_common_pkg.find_max (p_error_code1, p_error_code2);
      RETURN x_return_value;
   END find_max;

   --
   -- Pre Validations
   --
   FUNCTION pre_validations (
      p_cnv_stg_rec   IN   xx_ap_sus_contact_cnv_pkg.g_xx_sus_cont_stg_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

      FUNCTION is_vendor_site_code_null (p_vendor_site_code IN VARCHAR2)
         RETURN NUMBER
      IS
      BEGIN
         IF p_vendor_site_code IS NULL
         THEN
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_vendor_sitecode_valid,
                p_error_text               =>    p_cnv_stg_rec.last_name
                                              || ' - Vendor Site Code Null =>'
                                              || p_vendor_site_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_cnv_stg_rec.record_number,
                p_record_identifier_2      => p_cnv_stg_rec.legacy_supplier_number,
                p_record_identifier_3      => p_cnv_stg_rec.vendor_site_code
               );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
         END IF;

         RETURN x_error_code;
      END is_vendor_site_code_null;

      FUNCTION is_last_name_null (p_last_name IN VARCHAR2)
         RETURN NUMBER
      IS
      BEGIN
         IF p_last_name IS NULL
         THEN
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => 'Last Name Validation',
                p_error_text               =>    p_cnv_stg_rec.last_name
                                              || ' - Last Name Null =>'
                                              || p_last_name
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_cnv_stg_rec.record_number,
                p_record_identifier_2      => p_cnv_stg_rec.legacy_supplier_number,
                p_record_identifier_3      => p_cnv_stg_rec.last_name
               );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
         END IF;

         RETURN x_error_code;
      END is_last_name_null;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Pre-Validations');
      --Vendor Site Code
      x_error_code_temp :=
                    is_vendor_site_code_null (p_cnv_stg_rec.vendor_site_code);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
                         (xx_emf_cn_pkg.cn_low,
                             ' After is_vendor_site_code_null x_error_code :'
                          || x_error_code
                         );
      --Last Name
      x_error_code_temp := is_last_name_null (p_cnv_stg_rec.last_name);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' After is_last_name_null x_error_code :'
                            || x_error_code
                           );
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
   END pre_validations;

   /* Added for batch validations */
   FUNCTION batch_validations (p_batch_id VARCHAR2)
      RETURN NUMBER
   IS
      x_batch_id          VARCHAR2 (50) := p_batch_id;
      x_error_code        NUMBER        := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Batch-Validations');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
   END batch_validations;

   --
   -- Data Validations
   --
   FUNCTION data_validations (
      p_cnv_hdr_rec   IN OUT   xx_ap_sus_contact_cnv_pkg.g_xx_sus_cont_pre_std_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER         := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER         := xx_emf_cn_pkg.cn_success;
      x_lagacy_system     VARCHAR2 (100);

      --- Local functions for all data level validations
      --- Add as many functions as required
      ----------------------- validation for org Id ------------------------------------------
      FUNCTION is_operating_unit_valid (
         p_operating_unit_name   IN OUT   VARCHAR2,
         p_org_id                OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         x_operating_unit VARCHAR2(100);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validations for Operating Unit Name'
                              );

         IF p_operating_unit_name IS NOT NULL
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     ' Operating Unit Name '
                                  || p_operating_unit_name
                                 );
            x_operating_unit :=
	    	          xx_intg_common_pkg.get_mapping_value (p_mapping_type   => 'OPERATING_UNIT_NAME',
	    	                                                p_old_value      => p_operating_unit_name,
	    	                                                p_date_effective => SYSDATE
	                                                       );

	                xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
	                                         ' Operating Unit Name '
	                                      || p_operating_unit_name
                                 );

            SELECT name, organization_id
              INTO p_operating_unit_name, p_org_id
              FROM hr_operating_units
             WHERE UPPER(NAME) = UPPER(x_operating_unit);

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' p_org_id : ' || p_org_id
                                 );
         ELSE
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                              || '- Operating Unit IS NULL',
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.legacy_supplier_number,
                p_record_identifier_3      => p_cnv_hdr_rec.operating_unit_name
               );
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                              || ' - Invalid Org Id =>'
                                              || p_operating_unit_name
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.legacy_supplier_number,
                p_record_identifier_3      => p_cnv_hdr_rec.operating_unit_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                              || ' - Invalid Org Id =>'
                                              || p_operating_unit_name
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.legacy_supplier_number,
                p_record_identifier_3      => p_cnv_hdr_rec.operating_unit_name
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors In Org Id Validation ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                              || ' - Invalid Org Id =>'
                                              || p_operating_unit_name
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.legacy_supplier_number,
                p_record_identifier_3      => p_cnv_hdr_rec.operating_unit_name
               );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'X_ERROR_CODE Org Id: ' || x_error_code
                                 );
            RETURN x_error_code;
      END is_operating_unit_valid;

      --------------------------Vendor Id validation ------------------------------------------
      FUNCTION is_vendor_valid (
                                 p_vendor_site_code IN      VARCHAR2,
                                 p_legacy_num       IN      VARCHAR2,
                                 p_org_id           IN      NUMBER,
                                 p_vendor_id        IN OUT  NUMBER
                               )  --Modified to handle duplicate leg sup num issue
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         x_src_sys_name VARCHAR2(50);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' p_legacy_num : ' || p_legacy_num
                              );
         --Modified to handle duplicate leg sup num issue
         /*SELECT vendor_id
           INTO p_vendor_id
           FROM ap_suppliers
          WHERE attribute2 = p_legacy_num;*/

          --Added on 19-DEC-13
          SELECT source_system_name
            INTO x_src_sys_name
            FROM xx_ap_sup_site_contact_stg cstg
           WHERE cstg.batch_id = p_cnv_hdr_rec.batch_id
             AND cstg.record_number = p_cnv_hdr_rec.record_number;

           SELECT asp.vendor_id
             INTO p_vendor_id
             FROM ap_suppliers asp
                 ,ap_supplier_sites_all ass
            WHERE asp.vendor_id = ass.vendor_id
              AND ass.org_id = p_org_id
              AND UPPER(ass.vendor_site_code) = UPPER(p_vendor_site_code)
              AND xx_po_cnv_validations_pkg.xx_po_conv_ven(ass.attribute1,ass.attribute2,x_src_sys_name) = p_legacy_num  --Added on 19-DEC-13
              AND ass.attribute1 LIKE '%'||x_src_sys_name||'%'
              AND ass.attribute2 LIKE '%'||p_legacy_num||'%';

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' p_vendor_id : ' || p_vendor_id
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                              || 'Invalid Vendor => '
                                              || p_legacy_num
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.legacy_supplier_number,
                p_record_identifier_3      => p_cnv_hdr_rec.last_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            --Added as per Wave1
            BEGIN
                SELECT asp.vendor_id
                  INTO p_vendor_id
                  FROM ap_suppliers asp
                      ,ap_supplier_sites_all ass
                      ,xx_ap_suppliers_staging stg
                      ,xx_ap_sup_site_contact_stg cstg
                 WHERE asp.vendor_id = ass.vendor_id
                   AND ass.org_id = p_org_id
                   AND UPPER(ass.vendor_site_code) = UPPER(p_vendor_site_code)
                   AND UPPER(asp.vendor_name) = UPPER(stg.vendor_name)
                   AND stg.attribute2 = p_legacy_num
                   AND stg.attribute1 = cstg.source_system_name
                   AND cstg.record_number = p_cnv_hdr_rec.record_number
                   AND cstg.batch_id = p_cnv_hdr_rec.batch_id
                   AND ROWNUM < 2;

               RETURN x_error_code;
            EXCEPTION
            WHEN OTHERS THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                      'SQLCODE NODATA ' || SQLCODE
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                 || 'Invalid Vendor =>'
                                                 || p_legacy_num
                                                 || '-'
                                                 || xx_emf_cn_pkg.cn_no_data,
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.legacy_supplier_number,
                   p_record_identifier_3      => p_cnv_hdr_rec.last_name
                  );
            RETURN x_error_code;
            END;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors In Vendor Validation ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                              || 'Invalid Vendor  =>'
                                              || p_legacy_num
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.legacy_supplier_number,
                p_record_identifier_3      => p_cnv_hdr_rec.last_name
               );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'X_ERROR_CODE Vendor ' || x_error_code
                                 );
            RETURN x_error_code;
      END is_vendor_valid;

      ----------------vendor site code validation funtion-------------------
      FUNCTION is_vendor_sitecode_valid (
         p_vendor_site_code   IN       VARCHAR2,
         p_vedor_site_id      IN OUT   NUMBER,
         p_vendor_id          IN       NUMBER,
         p_org_id             IN       NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Validations for vendor site code '
                               || p_vendor_site_code
                              );

         IF p_vendor_site_code IS NOT NULL
         THEN
            SELECT vendor_site_id
              INTO p_vedor_site_id
              FROM ap_supplier_sites_all
             WHERE UPPER(vendor_site_code) = UPPER(p_vendor_site_code)
               AND vendor_id = p_vendor_id
               AND org_id = p_org_id;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'p_vedor_site_id ' || p_vedor_site_id
                                 );
            x_error_code := xx_emf_cn_pkg.cn_success;
         ELSE
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_vendor_sitecode_valid,
                p_error_text               =>    p_cnv_hdr_rec.last_name
                                              || 'Vendor Site Code IS NULL',
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.legacy_supplier_number,
                p_record_identifier_3      => p_cnv_hdr_rec.vendor_site_code
               );
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_vendor_sitecode_valid,
                p_error_text               =>    p_cnv_hdr_rec.last_name
                                              || 'Invalid Vendor Site Code => '
                                              || p_vendor_site_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.legacy_supplier_number,
                p_record_identifier_3      => p_cnv_hdr_rec.vendor_site_code
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_vendor_sitecode_valid,
                p_error_text               =>    p_cnv_hdr_rec.last_name
                                              || 'Invalid Vendor Site Code => '
                                              || p_vendor_site_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.legacy_supplier_number,
                p_record_identifier_3      => p_cnv_hdr_rec.vendor_site_code
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In vendor_site_code Validation '
                                  || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_vendor_sitecode_valid,
                p_error_text               =>    p_cnv_hdr_rec.last_name
                                              || ' Invalid Vendor Site Code  =>'
                                              || p_vendor_site_code
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.legacy_supplier_number,
                p_record_identifier_3      => p_cnv_hdr_rec.vendor_site_code
               );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE vendor_site_code '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_vendor_sitecode_valid;
      --Function to validate Contact Title Added as per Wave1 22-OCT-13
      FUNCTION is_contact_title_valid (
         p_contact_title   IN OUT  VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_contact_title    VARCHAR2 (40);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Validation for Contact Title: '
                               || p_contact_title
                              );

         SELECT lookup_code
           INTO x_contact_title
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_contact_title)
            AND lookup_type = 'CONTACT_TITLE'
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         p_contact_title := x_contact_title;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'After validation p_contact_title : '
                               || p_contact_title
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                  p_error_text               =>     p_cnv_hdr_rec.last_name
                                                || ' - Invalid Contact Title => '
                                                || p_contact_title
                                                || '-'
                                                || xx_emf_cn_pkg.cn_too_many,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.legacy_supplier_number,
                  p_record_identifier_3      => p_cnv_hdr_rec.prefix
                 );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                  p_error_text               =>     p_cnv_hdr_rec.last_name
                                                || ' - Invalid Contact Title => '
                                                || p_contact_title
                                                || '-'
                                                || xx_emf_cn_pkg.cn_no_data,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.legacy_supplier_number,
                  p_record_identifier_3      => p_cnv_hdr_rec.prefix
                 );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                'Errors In Pay Group lookup Code Validation '
                             || SQLCODE
                            );
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                  p_error_text               =>     p_cnv_hdr_rec.last_name
                                                || ' - Invalid Contact Title => '
                                                || p_contact_title
                                                || '-'
                                                || SQLERRM,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.legacy_supplier_number,
                  p_record_identifier_3      => p_cnv_hdr_rec.prefix
                 );
            RETURN x_error_code;
      END is_contact_title_valid;
   -- End of delcaration of Local Functions
   -----------------------Data validation starts here---------------------------------------
   -- Start of the main function data_validations
   --- This will only have calls to the individual functions.
   BEGIN
      -- for data_validations
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Data-Validations');
      --Operating Unit Name Validation
      x_error_code_temp :=
         is_operating_unit_valid (p_cnv_hdr_rec.operating_unit_name,
                                  p_cnv_hdr_rec.org_id
                                 );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' After Operating Unit Validation'
                           );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
                       (xx_emf_cn_pkg.cn_low,
                           ' p_cnv_hdr_rec.operating_unit_name x_error_code :'
                        || x_error_code
                       );
      --Vendor Validation
      x_error_code_temp :=
         is_vendor_valid (p_cnv_hdr_rec.vendor_site_code,
                          p_cnv_hdr_rec.legacy_supplier_number,
                          p_cnv_hdr_rec.org_id,
                          p_cnv_hdr_rec.vendor_id
                         );  --Modified to handle duplicate leg sup num issue
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' After Vendor Name Validation'
                           );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' p_cnv_hdr_rec.vendor_name x_error_code :'
                            || x_error_code
                           );
      --Vendor site Code Validation
      x_error_code_temp :=
         is_vendor_sitecode_valid (p_cnv_hdr_rec.vendor_site_code,
                                   p_cnv_hdr_rec.vendor_site_id,
                                   p_cnv_hdr_rec.vendor_id,
                                   p_cnv_hdr_rec.org_id
                                  );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' vendor site code-  x_error_code :'
                            || x_error_code
                           );
      --Contact Title Validation added as per Wave1 22-OCT-13
      IF p_cnv_hdr_rec.prefix IS NOT NULL THEN
         x_error_code_temp :=
            is_contact_title_valid (p_cnv_hdr_rec.prefix
                                   );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
	                                'Contact Title - x_error_code :'
	                             || x_error_code
                           );
      END IF;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Completed Data-Validations');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
   END data_validations;

   --
   -- Data Derivations
   --
   FUNCTION data_derivations (
      p_cnv_hdr_rec   IN OUT   xx_ap_sus_contact_cnv_pkg.g_xx_sus_cont_pre_std_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Data Derivations');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
   END data_derivations;

   --
   -- Post Validations
   --
   FUNCTION post_validations
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Post-Validations');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
   END post_validations;

END xx_ap_sus_contact_valid_pkg;
/


GRANT EXECUTE ON APPS.XX_AP_SUS_CONTACT_VALID_PKG TO INTG_XX_NONHR_RO;
