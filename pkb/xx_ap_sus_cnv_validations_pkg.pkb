DROP PACKAGE BODY APPS.XX_AP_SUS_CNV_VALIDATIONS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AP_SUS_CNV_VALIDATIONS_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 06-FEB-2012
 File Name     : XXAPSUSVAL.pkb
 Description   : This script creates the body of the package
                 xx_ap_sus_cnv_validations_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 06-FEB-2012 Sharath Babu          Initial development.
 24-FEB-2012 Sharath Babu          Added function to derive mappping value
 02-MAY-2012 Sharath Babu          Modified ship_via validation query and payment term logic
 22-JUN-2012 Sharath Babu          Modified to handle duplicate leg sup num issue
 28-JUN-2012 Sharath Babu          Added is_vendor_scode_duplicate to check for
                                   Duplicate vendor site codes in data file
 07-MAY-2013 Sharath Babu          Modified as per Wave1
 22-OCT-2013 Sharath Babu          Modified as per Wave1
 16-DEC-2013 Sharath Babu          Modified logic to check payment_method_lookup_code
 06-Jan-2013 ABHARGAVA             Modified to validate Inactive dates logic
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
   -- Checking for pre validations
   --
   FUNCTION pre_validations
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Pre-Validations');
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

   FUNCTION data_validations (
      p_cnv_hdr_rec   IN OUT   xx_ap_sus_conversion_pkg.g_xx_sus_cnv_pre_std_rec_type
     ,p_validate_and_load   IN       VARCHAR2
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

      --- Local functions for all Data validations
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
             WHERE UPPER(name) = UPPER(x_operating_unit);

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
                   p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
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
                    p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
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
                    p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
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
                    p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                    p_record_identifier_3      => p_cnv_hdr_rec.operating_unit_name
                   );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'X_ERROR_CODE Org Id: ' || x_error_code
                                 );
            RETURN x_error_code;
      END is_operating_unit_valid;

      --------------------------Vendor Validation ------------------------------------------
      FUNCTION is_vendor_valid (
                                p_attribute1   IN       VARCHAR2,
                                p_attribute2   IN       VARCHAR2,
                                p_vendor_id    IN OUT   NUMBER
                                )   --Modified to handle duplicate leg sup num issue
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' p_attribute2 : ' || p_attribute2
                              );
         SELECT vendor_id
           INTO p_vendor_id
           FROM ap_suppliers
          WHERE attribute2 = p_attribute2
            AND attribute1 = p_attribute1;  --Modified to handle duplicate leg sup num issue

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
                                                       || p_attribute2
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_too_many,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.attribute2
                        );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT DISTINCT aps.vendor_id
                 INTO p_vendor_id
                 FROM xx_ap_suppliers_staging stg
                     ,ap_suppliers aps
                WHERE UPPER(aps.vendor_name) = UPPER(stg.vendor_name)
                  AND stg.attribute1 = p_attribute1
                  AND stg.attribute2 = p_attribute2
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
                                                          || p_attribute2
                                                          || '-'
                                                          || xx_emf_cn_pkg.cn_no_data,
                            p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                            p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                            p_record_identifier_3      => p_cnv_hdr_rec.attribute2
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
                                                       || p_attribute2
                                                       || '-'
                                                       || SQLERRM,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.attribute2
                        );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'X_ERROR_CODE Vendor ' || x_error_code
                                 );
            RETURN x_error_code;
      END is_vendor_valid;

      -------------------Vendor Ship To Location Validation     -----------------
      FUNCTION is_ship_loc_valid (
         p_ship_to_location_code   IN OUT   VARCHAR2,
         p_ship_to_location_id     IN OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' p_ship_to_location_code : '
                               || p_ship_to_location_code
                              );
         --Modified as per Wave1 22-OCT-13
         SELECT hla.ship_to_location_id, hla.location_code
           INTO p_ship_to_location_id, p_ship_to_location_code
           FROM hr_locations_all hla
          WHERE UPPER (hla.location_code) = UPPER (p_ship_to_location_code)
            AND hla.ship_to_site_flag = 'Y';

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' p_ship_to_location_id : '
                               || p_ship_to_location_id
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
                                                || 'Invalid Ship To Location => '
                                                || p_ship_to_location_code
                                                || '-'
                                                || xx_emf_cn_pkg.cn_too_many,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.ship_to_location_code
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
                                                || 'Invalid Ship To Location =>'
                                                || p_ship_to_location_code
                                                || '-'
                                                || xx_emf_cn_pkg.cn_no_data,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.ship_to_location_code
                 );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                'Errors In ship_to_location_code Validation '
                             || SQLCODE
                            );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                  p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                || ' Invalid Ship To Location  =>'
                                                || p_ship_to_location_code
                                                || '-'
                                                || SQLERRM,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.ship_to_location_code
                 );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE ship_to_location_code '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_ship_loc_valid;

      -----------------------------Vendor BILL To Location Validation ---------------------------------------
      FUNCTION is_bill_loc_valid (
         p_bill_to_location_code   IN OUT   VARCHAR2,
         p_bill_to_location_id     IN OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' p_bill_to_location_code : '
                               || p_bill_to_location_code
                              );
         --Modified as per Wave1 22-OCT-13
         SELECT hla.location_id, hla.location_code
           INTO p_bill_to_location_id, p_bill_to_location_code
           FROM hr_locations_all hla
          WHERE UPPER (hla.location_code) = UPPER (p_bill_to_location_code)
            AND hla.bill_to_site_flag = 'Y';

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' p_bill_to_location_id : '
                               || p_bill_to_location_id
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
                                                || 'Invalid Bill To Location => '
                                                || p_bill_to_location_code
                                                || '-'
                                                || xx_emf_cn_pkg.cn_too_many,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.bill_to_location_code
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
                                                || 'Invalid Bill To Location =>'
                                                || p_bill_to_location_code
                                                || '-'
                                                || xx_emf_cn_pkg.cn_no_data,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.bill_to_location_code
                 );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                'Errors In bill_to_location_code Validation '
                             || SQLCODE
                            );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                  p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                || ' Invalid Bill To Location  =>'
                                                || p_bill_to_location_code
                                                || '-'
                                                || SQLERRM,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.bill_to_location_code
                 );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE bill_to_location_code '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_bill_loc_valid;
      --Function to check for Duplicate vendor site codes in data file
      FUNCTION is_vendor_scode_duplicate (
               p_vendor_site_code   IN   VARCHAR2,
               p_leg_vendor         IN   VARCHAR2,
               p_ou_name            IN   VARCHAR2,
               p_batch_id           IN   VARCHAR2,
               p_record_num         IN   NUMBER
            )
               RETURN NUMBER
      IS
         CURSOR c_dup_vendor_scodes( p_vendor_site_code  VARCHAR2
                                    ,p_leg_vendor        VARCHAR2
                                    ,p_ou_name           VARCHAR2
                                    ,p_batch_id          VARCHAR2
                                    ,p_record_num        NUMBER    )
         IS
         SELECT b.vendor_site_code,b.attribute2,b.operating_unit_name,b.record_number,b.batch_id
           FROM xx_ap_sup_sites_pre_int b,
               (
                SELECT vendor_site_code,attribute2,operating_unit_name
                  FROM xx_ap_sup_sites_pre_int
                 WHERE 1=1
                   AND batch_id = p_batch_id
                   AND vendor_site_code = p_vendor_site_code
                   AND attribute2 = p_leg_vendor
                   AND operating_unit_name = p_ou_name
                   AND error_code = xx_emf_cn_pkg.cn_success
              GROUP BY vendor_site_code,attribute2,operating_unit_name
                HAVING COUNT(*) > 1
               ) a
          WHERE 1=1
            AND b.vendor_site_code = a.vendor_site_code
            AND b.attribute2 = a.attribute2
            AND b.operating_unit_name = a.operating_unit_name
            AND batch_id = p_batch_id
            AND b.record_number <> p_record_num;

         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
         x_count        NUMBER;
      BEGIN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Check for Duplicate Vendor Site Codes in Data File'
                                    );

               SELECT COUNT(*)
                 INTO x_count
                 FROM xx_ap_sup_sites_pre_int
                WHERE 1 = 1
                  AND batch_id = p_batch_id
                  AND vendor_site_code = p_vendor_site_code
                  AND attribute2 = p_leg_vendor
                  AND operating_unit_name = p_ou_name;

               IF x_count > 1 THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  FOR r_dup_vsite_code IN c_dup_vendor_scodes(p_vendor_site_code,p_leg_vendor,p_ou_name,p_batch_id,p_record_num)
                  LOOP
                     x_error_code := xx_emf_cn_pkg.cn_success;

                     UPDATE xx_ap_sup_sites_pre_int
                        SET error_code = xx_emf_cn_pkg.cn_rec_err
                      WHERE batch_id = r_dup_vsite_code.batch_id
                        AND record_number = r_dup_vsite_code.record_number
                        AND vendor_site_code = r_dup_vsite_code.vendor_site_code
                        AND attribute2 = r_dup_vsite_code.attribute2
                        AND operating_unit_name = r_dup_vsite_code.operating_unit_name;
                  END LOOP;
                  COMMIT;
                  IF x_error_code = xx_emf_cn_pkg.cn_rec_err THEN
                     xx_emf_pkg.error
                             (p_severity                 => xx_emf_cn_pkg.cn_medium,
                              p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                              p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                            || ' - Invalid: Duplicate Vendor Site Code In Data File => '
                                                            || p_ou_name,
                              p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                              p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                              p_record_identifier_3      => p_cnv_hdr_rec.vendor_site_code
                             );
                  END IF;
               ELSE
                  x_error_code := xx_emf_cn_pkg.cn_success;
               END IF;

               RETURN x_error_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                        'Checking for duplicate Vendor Site Code : when others'
                                       );
                  RETURN x_error_code;
      END is_vendor_scode_duplicate;

      ----------------vendor site code validation funtion----------------------------------------------------
      FUNCTION is_vendor_sitecode_valid (
         p_vendor_site_code   IN       po_vendor_sites_all.vendor_site_code%TYPE,
         p_vendor_id          IN       po_vendor_sites_all.vendor_id%TYPE,
         p_org_id             IN       NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER       := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (1);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Validations for vendor site code '
                               || p_vendor_site_code
                              );

         IF p_vendor_site_code IS NOT NULL
         THEN
            SELECT 'X'
              INTO x_variable
              FROM ap_supplier_sites_all
             WHERE UPPER(vendor_site_code) = UPPER(p_vendor_site_code)
               and nvl(inactive_date,'31-DEC-4712') > sysdate
               AND vendor_id = p_vendor_id
               AND org_id = p_org_id;

             --Added as per Wave1
             IF p_validate_and_load = g_validate_and_load THEN
                UPDATE ap_supplier_sites_all
	           SET attribute1 = attribute1||'|'||p_cnv_hdr_rec.attribute1
	              ,attribute2 = attribute2||'|'||p_cnv_hdr_rec.attribute2
	         WHERE UPPER(vendor_site_code) = UPPER(p_vendor_site_code)
	           AND vendor_id = p_vendor_id
	           AND org_id = p_org_id
	           AND attribute1 NOT LIKE '%'||p_cnv_hdr_rec.attribute1||'%'
	           AND attribute2 NOT LIKE '%'||p_cnv_hdr_rec.attribute2||'%';
                COMMIT;
             END IF;
                xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
	                               'Vendor Site Code already exists in the system'
	                             );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
	                         (p_severity                 => xx_emf_cn_pkg.cn_medium,
	                          p_category                 => xx_emf_cn_pkg.cn_vendor_sitecode_valid,
	                          p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
	                                                        || ' - Invalid : Vendor Site Code already exists in the system => '
	                                                        || p_vendor_site_code,
	                          p_record_identifier_1      => p_cnv_hdr_rec.record_number,
	                          p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
	                          p_record_identifier_3      => p_cnv_hdr_rec.vendor_site_code
                                 );
         ELSE
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => xx_emf_cn_pkg.cn_vendor_sitecode_valid,
                        p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                      || 'Vendor Site Code IS NULL',
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                        p_record_identifier_3      => p_cnv_hdr_rec.attribute2
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
                         p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                       || 'Invalid Vendor Site Code => '
                                                       || p_vendor_site_code
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_too_many,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.attribute2
                        );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
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
                         p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                       || ' Invalid Vendor Site Code  =>'
                                                       || p_vendor_site_code
                                                       || '-'
                                                       || SQLERRM,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.attribute2
                        );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE vendor_site_code '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_vendor_sitecode_valid;

      ---------------------------validation for fob_lookup_code -----------------------------------
      FUNCTION is_fob_lookup_code_valid (
         p_fob_lookup_code   IN OUT   fnd_lookup_values.lookup_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_fob_lookup_code     VARCHAR2 (40);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Validations for fob lookup code : '
                               || p_fob_lookup_code
                              );
         x_fob_lookup_code :=
	             xx_intg_common_pkg.get_mapping_value (p_mapping_type   => 'FOB_POINT',
	                                                   p_old_value      => p_fob_lookup_code,
	                                                   p_date_effective => SYSDATE
	                                                  );

	          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
	                                'derived value of  x_fob_lookup_code: '
	                                || x_fob_lookup_code
                              );

         SELECT DISTINCT lookup_code
           INTO p_fob_lookup_code
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (TRIM(x_fob_lookup_code))
            AND lookup_type = xx_emf_cn_pkg.cn_fob_lookup_code
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' lookup value : fob lookup code : '
                               || p_fob_lookup_code
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
                                                      || 'Invalid FOB => '
                                                      || x_fob_lookup_code
                                                      || '-'
                                                      || xx_emf_cn_pkg.cn_too_many,
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                        p_record_identifier_3      => p_cnv_hdr_rec.fob_lookup_code
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
                                                      || 'Invalid FOB =>'
                                                      || x_fob_lookup_code
                                                      || '-'
                                                      || xx_emf_cn_pkg.cn_no_data,
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                        p_record_identifier_3      => p_cnv_hdr_rec.fob_lookup_code
                       );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors In FOB Validation ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                        p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                      || ' Invalid FOB  =>'
                                                      || x_fob_lookup_code
                                                      || '-'
                                                      || SQLERRM,
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                        p_record_identifier_3      => p_cnv_hdr_rec.fob_lookup_code
                       );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'X_ERROR_CODE FOB ' || x_error_code
                                 );
            RETURN x_error_code;
      END is_fob_lookup_code_valid;

      ----------validation for pay_group_lookup_code------------------------------
      FUNCTION is_pay_group_code_valid (
         p_pay_group_code   IN OUT NOCOPY   fnd_lookup_values.lookup_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_pay_group    VARCHAR2 (30);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Validations for pay group code : '
                               || p_pay_group_code
                              );

         SELECT lookup_code
           INTO x_pay_group
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_pay_group_code)  --UPPER (meaning) = UPPER (p_pay_group_code) Modified as per Wave1 22-OCT-13
            AND lookup_type = xx_emf_cn_pkg.cn_paygroup_lookup_code
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         p_pay_group_code := x_pay_group;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'p_pay_group_code : ' || p_pay_group_code
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
                                                || 'Invalid PAY GROUP => '
                                                || p_pay_group_code
                                                || '-'
                                                || xx_emf_cn_pkg.cn_too_many,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.pay_group_lookup_code
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
                                                || 'Invalid PAY GROUP =>'
                                                || p_pay_group_code
                                                || '-'
                                                || xx_emf_cn_pkg.cn_no_data,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.pay_group_lookup_code
                 );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Organization Validation '
                                  || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                  p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                || ' Invalid PAY GROUP  =>'
                                                || p_pay_group_code
                                                || '-'
                                                || SQLERRM,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.pay_group_lookup_code
                 );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'X_ERROR_CODE PAY GROUP ' || x_error_code
                                 );
            RETURN x_error_code;
      END is_pay_group_code_valid;

      -----------------------validation for pay_method_lookup_code------------------------------
      FUNCTION is_pay_method_code_valid (
         p_pay_method_code   IN OUT   ap_suppliers.payment_method_lookup_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code       NUMBER        := xx_emf_cn_pkg.cn_success;
         x_payment_method   VARCHAR2 (30);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Validation for pay method code : '
                               || p_pay_method_code
                              );
           --Modified on 16-DEC-13 as per Wave1
           SELECT payment_method_code
	     INTO x_payment_method
	     FROM iby_payment_methods_b
	    WHERE UPPER(payment_method_code) = UPPER(p_pay_method_code)
              AND NVL (inactive_date, SYSDATE+1) >= SYSDATE;

         /*SELECT lookup_code
           INTO x_payment_method
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_pay_method_code) --UPPER (meaning) = UPPER (p_pay_method_code) Modified as per Wave1 22-OCT-13
            AND lookup_type = xx_emf_cn_pkg.cn_pay_metohd_lookup_code
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));*/

         p_pay_method_code := x_payment_method;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'pay method lookup value :'
                               || p_pay_method_code
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
                                              || ' - Invalid Payment Method Code =>'
                                              || p_pay_method_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.payment_method_lookup_code
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
                                              || ' - Invalid Payment Method Code =>'
                                              || p_pay_method_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.payment_method_lookup_code
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                              (xx_emf_cn_pkg.cn_low,
                                  'Errors In Payment Method Code Validation '
                               || SQLCODE
                              );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                              || ' - Invalid Payment Method Code =>'
                                              || p_pay_method_code
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.payment_method_lookup_code
               );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE Payment Method Code '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_pay_method_code_valid;

      -------------------------Validation for freight_terms_code--------------------------------------
      FUNCTION is_freight_terms_code_valid (
         p_freight_terms_code   IN OUT NOCOPY   fnd_lookup_values.lookup_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code      NUMBER        := xx_emf_cn_pkg.cn_success;
         x_freight_terms   VARCHAR2 (30);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Validation for freight term code : '
                               || p_freight_terms_code
                              );

         SELECT lookup_code
           INTO x_freight_terms
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_freight_terms_code) --UPPER (meaning) = UPPER (p_freight_terms_code) Modified as per Wave1 22-OCT-13
            AND lookup_type = xx_emf_cn_pkg.cn_freight_terms_code
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         p_freight_terms_code := x_freight_terms;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'x_freight_terms : ' || x_freight_terms
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
                                              || ' - Invalid Freight Terms Code =>'
                                              || p_freight_terms_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.freight_terms_lookup_code
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
                                              || ' - Invalid Freight Terms Code =>'
                                              || p_freight_terms_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.freight_terms_lookup_code
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                                 'Errors In Ship Via Lookup Code Validation '
                              || SQLCODE
                             );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                              || ' - Invalid Freight Terms code =>'
                                              || p_freight_terms_code
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.freight_terms_lookup_code
               );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'X_ERROR_CODE Freight Terms '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_freight_terms_code_valid;

      ----------validation for currency_code------------------------------
      FUNCTION is_invoice_cur_code_valid (
         p_inv_cur_code   IN OUT fnd_currencies.currency_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_cur_code     VARCHAR2 (10);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for currency code'
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Invoice currency code: ' || p_inv_cur_code
                              );
         x_cur_code :=
	 	     xx_intg_common_pkg.get_mapping_value (p_mapping_type   => 'VENDOR_CURRENCY',
	 	                                                   p_old_value      => p_inv_cur_code,
	 	                                                   p_date_effective => SYSDATE
	                                                           );
	            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
	                                'derived value of  x_cur_code: '
	                                || x_cur_code
                              );

         SELECT currency_code
           INTO p_inv_cur_code
           FROM fnd_currencies fc
          WHERE UPPER(fc.currency_code) = UPPER(TRIM(x_cur_code))
            AND NVL (fc.end_date_active, ADD_MONTHS (SYSDATE, 1)) >=
                                                       ADD_MONTHS (SYSDATE, 1)
            AND fc.enabled_flag = 'Y';

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
                  p_category                 => xx_emf_cn_pkg.cn_currency_code_valid,
                  p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                || ' - Invalid Invioce Currency code =>'
                                                || p_inv_cur_code
                                                || '-'
                                                || xx_emf_cn_pkg.cn_too_many,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.invoice_currency_code
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
                  p_category                 => xx_emf_cn_pkg.cn_currency_code_valid,
                  p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                || ' - Invalid Invoice Currency code =>'
                                                || p_inv_cur_code
                                                || '-'
                                                || xx_emf_cn_pkg.cn_no_data,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.invoice_currency_code
                 );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Currency Code Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.cn_currency_code_valid,
                  p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                || ' - Invalid Invoice Currency code =>'
                                                || p_inv_cur_code
                                                || '-'
                                                || SQLERRM,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.invoice_currency_code
                 );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE Invoice Currency Code '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_invoice_cur_code_valid;

--------------------------------Validation for Payment Currency Code -----------------------------------
      FUNCTION is_payment_cur_code_valid (
         p_payment_currency_code   IN OUT   fnd_currencies.currency_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_cur_code     VARCHAR2 (10);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for currency code'
                              );
          x_cur_code := xx_intg_common_pkg.get_mapping_value (p_mapping_type   => 'VENDOR_CURRENCY',
	 	 	                                              p_old_value      => p_payment_currency_code,
	 	 	                                              p_date_effective => SYSDATE
	                                                              );
	           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
	                                'derived value of  x_cur_code: '
	                                || x_cur_code
                              );

         SELECT currency_code
           INTO p_payment_currency_code
           FROM fnd_currencies
          WHERE UPPER(currency_code) = UPPER(TRIM(x_cur_code))
            AND NVL (end_date_active, ADD_MONTHS (SYSDATE, 1)) >=
                                                       ADD_MONTHS (SYSDATE, 1)
            AND enabled_flag = 'Y';

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
                                                || ' - Invalid Payment Currency code =>'
                                                || p_payment_currency_code
                                                || '-'
                                                || xx_emf_cn_pkg.cn_too_many,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.payment_currency_code
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
                                                || ' - Invalid Payment Currency code =>'
                                                || p_payment_currency_code
                                                || '-'
                                                || xx_emf_cn_pkg.cn_no_data,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.payment_currency_code
                 );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                'Errors In Payment Currency Code Validation '
                             || SQLCODE
                            );
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                  p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                || ' - Invalid Payment Currency code =>'
                                                || p_payment_currency_code
                                                || '-'
                                                || SQLERRM,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.payment_currency_code
                 );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE p_payment_currency_code '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_payment_cur_code_valid;

--------------------------------Validation for terms_name -----------------------------------
      FUNCTION is_terms_name_valid (
         p_terms_name   IN OUT          VARCHAR2,
         p_terms_id     IN OUT NOCOPY   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         x_term_name    VARCHAR2 (40);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for term name'
                              );
         IF p_terms_name IS NOT NULL THEN
	    x_term_name :=
	   	     xx_intg_common_pkg.get_mapping_value (p_mapping_type   => 'PAYMENT_TERM',
							   p_old_value1     => p_terms_name,
							   p_old_value2     => 'AP',
							   p_date_effective => SYSDATE
							  );
	  	  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
					'Derived Term Name = ' || x_term_name
	  		       );


	    SELECT name, term_id
	      INTO p_terms_name, p_terms_id
	      FROM ap_terms_tl
	     WHERE UPPER(NAME) = UPPER(TRIM(x_term_name))
	       AND enabled_flag = 'Y'
	       AND LANGUAGE = 'US'
	       AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

	    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
	    		       'Terms Name : ' || p_terms_name
	   		      );
	    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
	   		       'Terms Id : ' || p_terms_id
	    		      );
         ELSE
             SELECT name, term_id
	       INTO p_terms_name, p_terms_id
	       FROM ap_terms_tl
	      WHERE UPPER(NAME) = 'NET 45'
		AND enabled_flag = 'Y'
		AND LANGUAGE = 'US'
                AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));
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
                                                       || ' - Invalid Terms Name =>'
                                                       || x_term_name
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_too_many,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.terms_name
                        );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
             SELECT name, term_id
	       INTO p_terms_name, p_terms_id
	       FROM ap_terms_tl
	      WHERE UPPER(NAME) = 'NET 45'
	        AND enabled_flag = 'Y'
	        AND LANGUAGE = 'US'
                AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));
            /*xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                       || ' - Invalid Terms Name =>'
                                                       || x_term_name
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_no_data,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.terms_name
                        );*/
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors In Terms Name Validation '
                                  || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                       || ' - Invalid Terms Name =>'
                                                       || x_term_name
                                                       || '-'
                                                       || SQLERRM,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.terms_name
                        );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'X_ERROR_CODE Terms Id ' || x_error_code
                                 );
            RETURN x_error_code;
      END is_terms_name_valid;

      FUNCTION is_ship_via_code_valid (
         p_ship_via_lookup_code   IN OUT NOCOPY   VARCHAR2,
         p_org_id                 IN              NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code      NUMBER        := xx_emf_cn_pkg.cn_success;
         x_ship_via_code   VARCHAR2 (50);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validations for Ship Via Code'
                              );

          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'p_ship_via_lookup_code :'
                               || p_ship_via_lookup_code
                              );
         x_ship_via_code :=
	             xx_intg_common_pkg.get_mapping_value (p_mapping_type   => 'SHIP_VIA',
	                                                   p_old_value      => p_ship_via_lookup_code,
	                                                   p_date_effective => SYSDATE
	                                                  );
	          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
	                                'derived value of  x_ship_via_code: ' || x_ship_via_code
                              );

         /*SELECT freight_code
           INTO p_ship_via_lookup_code
           FROM org_freight
          WHERE LANGUAGE = 'US'
            AND organization_id = (SELECT inventory_organization_id
                                     FROM financials_system_params_all
                                    WHERE org_id = p_org_id)
            AND UPPER(freight_code) = UPPER(x_ship_via_code);*/

          SELECT DISTINCT freight_code
	    INTO p_ship_via_lookup_code
	    FROM wsh_carriers_v
	   WHERE UPPER(freight_code) = UPPER(TRIM(x_ship_via_code))
             AND active = 'A';

          /*SELECT DISTINCT lookup_code
	    INTO p_ship_via_lookup_code
	    FROM fnd_lookup_values
	   WHERE lookup_type = 'SHIP_VIA'
	     AND language = 'US'
	     AND enabled_flag = 'Y'
             AND UPPER(lookup_code) = UPPER(TRIM(x_ship_via_code));*/

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'p_ship_via_lookup_code :'
                               || p_ship_via_lookup_code
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
                                                 || ' - Invalid Ship Via Code =>'
                                                 || x_ship_via_code
                                                 || '-'
                                                 || xx_emf_cn_pkg.cn_too_many,
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                   p_record_identifier_3      => p_cnv_hdr_rec.ship_via_lookup_code
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
                                                 || ' - Invalid Ship Via Code =>'
                                                 || x_ship_via_code
                                                 || '-'
                                                 || xx_emf_cn_pkg.cn_no_data,
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                   p_record_identifier_3      => p_cnv_hdr_rec.ship_via_lookup_code
                  );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                                 'Errors In Ship Via Lookup Code Validation '
                              || SQLCODE
                             );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                 || ' - Invalid Ship Via code =>'
                                                 || x_ship_via_code
                                                 || '-'
                                                 || SQLERRM,
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                   p_record_identifier_3      => p_cnv_hdr_rec.ship_via_lookup_code
                  );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE Ship Via Lookup Code '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_ship_via_code_valid;

-----------------------------------Validation For Address Line1 ----------------------------------------------
      FUNCTION is_address1_valid (p_address_line1 IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Address Line1  '
                              );

         IF p_address_line1 IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                        p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                      || ' - Address line1 IS NULL =>'
                                                      || p_address_line1,
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                        p_record_identifier_3      => p_cnv_hdr_rec.address_line1
                       );
         END IF;

         RETURN x_error_code;
      END is_address1_valid;

--------------------------------------Validation For State ------------------------------------------------------
      FUNCTION is_state_valid (p_state IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for State  ');

         IF p_state IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                        p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                      || ' - State IS NULL =>'
                                                      || p_state,
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                        p_record_identifier_3      => p_cnv_hdr_rec.state
                       );
         END IF;

         RETURN x_error_code;
      END is_state_valid;

----------------------------------------Validation For City-------------------------------------------------------
      FUNCTION is_city_valid (p_city IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Validation for City  ');

         IF p_city IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                        p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                      || ' - City IS NULL =>'
                                                      || p_city,
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                        p_record_identifier_3      => p_cnv_hdr_rec.city
                       );
         END IF;

         RETURN x_error_code;
      END is_city_valid;

------------------------Country Validation---------------------------------
      FUNCTION is_country_valid (p_country IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_country      VARCHAR2 (50);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Country '
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Country  :' || p_country);

         IF p_country IS NOT NULL
         THEN --Modified as per Wave1 22-OCT-13
            SELECT territory_code
              INTO x_country
              FROM fnd_territories
             WHERE UPPER (territory_code) = UPPER (p_country)
               AND NVL(obsolete_flag,'N') = 'N'
               --AND LANGUAGE = 'US';
               AND ROWNUM = 1;

            p_country := x_country;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'After xref p_country  :' || p_country
                                 );
         ELSE
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                        p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                      || ' - Invalid : Country IS NULL =>'
                                                      || p_country
                                                      || '-'
                                                      || SQLERRM,
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                        p_record_identifier_3      => p_cnv_hdr_rec.country
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
                                                       || ' - Invalid Country =>'
                                                       || p_country
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_too_many,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.country
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
                                                       || ' - Invalid Country =>'
                                                       || p_country
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_no_data,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.country
                        );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors In Country Validation ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                       || ' - Invalid Country =>'
                                                       || p_country
                                                       || '-'
                                                       || SQLERRM,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.country
                        );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'X_ERROR_CODE Country ' || x_error_code
                                 );
            RETURN x_error_code;
      END is_country_valid;

      FUNCTION is_county_valid (
         p_county    IN OUT NOCOPY   VARCHAR2,
         p_state     IN              VARCHAR2,
         p_zip       IN              VARCHAR2,
         p_city      IN              VARCHAR2,
         p_country   IN              VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
         x_county       VARCHAR2 (50);
         x_yn           VARCHAR2 (1);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for County ');
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'State         :' || p_state
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Postal Code   :' || p_zip
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Country       :' || p_country
                              );

         IF (p_country = 'US' AND p_state IS NOT NULL AND p_zip IS NOT NULL)
         THEN
            SELECT geography_element3
              INTO p_county
              FROM hz_geographies
             WHERE country_code = p_country
               AND geography_type = 'POSTAL_CODE'
               AND geography_name = SUBSTR (p_zip, 1, 5)
               AND geography_element2_code = p_state
               -- AND upper(geography_element4) = upper(p_city)
               AND ROWNUM = 1;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'After xref p_county  :' || p_county
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
                                                       || ' - Invalid County  =>'
                                                       || p_county
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_too_many,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.county
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
                                                       || ' - County Not Available =>'
                                                       || p_county
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_no_data,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.county
                        );
            NULL;
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors In County Validation ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                       || ' - Invalid County =>'
                                                       || p_county
                                                       || '-'
                                                       || SQLERRM,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.county
                        );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'X_ERROR_CODE County ' || x_error_code
                                 );
            RETURN x_error_code;
      END is_county_valid;

      FUNCTION is_address_style_valid (p_address_style IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code      NUMBER        := xx_emf_cn_pkg.cn_success;
         x_address_style   VARCHAR2 (30);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Address Style'
                              );

         SELECT lookup_code
           INTO x_address_style
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_address_style)  --UPPER (meaning) = UPPER (p_address_style) Modified as per Wave1 22-OCT-13
            AND lookup_type = xx_ap_sus_conversion_pkg.g_address_style_code
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         p_address_style := x_address_style;
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
                                                       || ' - Invalid Address Style =>'
                                                       || p_address_style
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_too_many,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.address_style
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
                                                       || ' - Invalid Address Style =>'
                                                       || p_address_style
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_no_data,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.address_style
                        );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Address Style Validation '
                                  || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                       || ' - Invalid Address Style =>'
                                                       || p_address_style
                                                       || '-'
                                                       || SQLERRM,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.address_style
                        );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'X_ERROR_CODE Address Style '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_address_style_valid;

      FUNCTION is_language_valid (p_language IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_language     VARCHAR2 (30);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Language'
                              );

         SELECT nls_language
           INTO x_language
           FROM fnd_languages
          WHERE UPPER (nls_language) = UPPER (p_language);

         p_language := x_language;
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
                                                       || ' - Invalid Language =>'
                                                       || p_language
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_too_many,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.LANGUAGE
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
                                                       || ' - Invalid Language =>'
                                                       || p_language
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_no_data,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.LANGUAGE
                        );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors In Language Validation ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                       || ' - Invalid Language =>'
                                                       || p_language
                                                       || '-'
                                                       || SQLERRM,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.LANGUAGE
                        );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'X_ERROR_CODE Language ' || x_error_code
                                 );
            RETURN x_error_code;
      END is_language_valid;

      FUNCTION is_awt_grp_name_valid (
         p_awt_grp_name   IN OUT   VARCHAR2,
         p_awt_grp_id     IN OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         x_awt_grp_name VARCHAR2(60);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for AWT Group Name'
                              );

         SELECT name, group_id
           INTO x_awt_grp_name, p_awt_grp_id
           FROM ap_awt_groups
          WHERE UPPER(name) = UPPER(p_awt_grp_name)
            AND NVL (inactive_date, SYSDATE) >= SYSDATE;

         p_awt_grp_name := x_awt_grp_name;
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
                                                       || ' - Invalid AWT Group Name =>'
                                                       || p_awt_grp_name
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_too_many,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.awt_group_name
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
                                                       || ' - Invalid AWT Group Name =>'
                                                       || p_awt_grp_name
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_no_data,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.awt_group_name
                        );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In AWT Group Name Validation '
                                  || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                       || ' - Invalid AWT Group Name =>'
                                                       || p_awt_grp_name
                                                       || '-'
                                                       || SQLERRM,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.awt_group_name
                        );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE AWT Group Name: '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_awt_grp_name_valid;

      FUNCTION is_shipping_control_valid (
         p_shipping_ctrl   IN OUT NOCOPY   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code      NUMBER        := xx_emf_cn_pkg.cn_success;
         x_shipping_ctrl   VARCHAR2 (30);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Shipping Control'
                              );

         SELECT lookup_code
           INTO x_shipping_ctrl
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_shipping_ctrl) --UPPER (meaning) = UPPER (p_shipping_ctrl) Modified as per Wave1 22-OCT-13
            AND lookup_type = xx_ap_sus_conversion_pkg.g_ship_control_code
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         p_shipping_ctrl := x_shipping_ctrl;
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
                                                     || ' - Invalid Shipping Control =>'
                                                     || p_shipping_ctrl
                                                     || '-'
                                                     || xx_emf_cn_pkg.cn_too_many,
                       p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                       p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                       p_record_identifier_3      => p_cnv_hdr_rec.shipping_control
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
                                                     || ' - Invalid Shipping Control =>'
                                                     || p_shipping_ctrl
                                                     || '-'
                                                     || xx_emf_cn_pkg.cn_no_data,
                       p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                       p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                       p_record_identifier_3      => p_cnv_hdr_rec.shipping_control
                      );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Shipping Control Validation '
                                  || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                      (p_severity                 => xx_emf_cn_pkg.cn_medium,
                       p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                       p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                     || ' - Invalid Shipping Control =>'
                                                     || p_shipping_ctrl
                                                     || '-'
                                                     || SQLERRM,
                       p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                       p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                       p_record_identifier_3      => p_cnv_hdr_rec.shipping_control
                      );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE Shipping Control '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_shipping_control_valid;

      FUNCTION is_payment_method_code_valid (p_payment_method IN OUT VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code       NUMBER        := xx_emf_cn_pkg.cn_success;
         x_payment_method   VARCHAR2 (60);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Payment Method Code'
                              );

         SELECT payment_method_code
           INTO x_payment_method
           FROM iby_payment_methods_b
          WHERE UPPER(payment_method_code) = UPPER(p_payment_method)
            AND NVL (inactive_date, SYSDATE) >= SYSDATE;

         p_payment_method := x_payment_method;
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
                                                  || ' - Invalid Payment Method Code =>'
                                                  || p_payment_method
                                                  || '-'
                                                  || xx_emf_cn_pkg.cn_too_many,
                    p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                    p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                    p_record_identifier_3      => p_cnv_hdr_rec.payment_method_code
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
                                                  || ' - Invalid Payment Method Code =>'
                                                  || p_payment_method
                                                  || '-'
                                                  || xx_emf_cn_pkg.cn_no_data,
                    p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                    p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                    p_record_identifier_3      => p_cnv_hdr_rec.payment_method_code
                   );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                              (xx_emf_cn_pkg.cn_low,
                                  'Errors In Payment Method Code Validation '
                               || SQLCODE
                              );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
                    p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                    p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                  || ' - Invalid Payment Method Code =>'
                                                  || p_payment_method
                                                  || '-'
                                                  || SQLERRM,
                    p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                    p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                    p_record_identifier_3      => p_cnv_hdr_rec.payment_method_code
                   );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE Payment Method Code: '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_payment_method_code_valid;

      FUNCTION is_pay_awt_grp_name_valid (p_pawt_grp_name IN OUT VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code      NUMBER        := xx_emf_cn_pkg.cn_success;
         x_pawt_grp_name   VARCHAR2 (60);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Pay AWT Group Name'
                              );

         SELECT name
           INTO x_pawt_grp_name
           FROM ap_awt_groups
          WHERE UPPER(name) = UPPER(p_pawt_grp_name)
            AND NVL (inactive_date, SYSDATE) >= SYSDATE;

         p_pawt_grp_name := x_pawt_grp_name;
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
                                                   || ' - Invalid Pay AWT Group Name =>'
                                                   || p_pawt_grp_name
                                                   || '-'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                     p_record_identifier_3      => p_cnv_hdr_rec.pay_awt_group_name
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
                                                   || ' - Invalid Pay AWT Group Name =>'
                                                   || p_pawt_grp_name
                                                   || '-'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                     p_record_identifier_3      => p_cnv_hdr_rec.pay_awt_group_name
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                   'Errors In Pay AWT Group Name Validation '
                                || SQLCODE
                               );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                   || ' - Invalid Pay AWT Group Name =>'
                                                   || p_pawt_grp_name
                                                   || '-'
                                                   || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                     p_record_identifier_3      => p_cnv_hdr_rec.pay_awt_group_name
                    );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE Pay AWT Group Name: '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_pay_awt_grp_name_valid;

      FUNCTION is_accts_pay_cc_valid (
         p_accts_pay_cc     IN       VARCHAR2,
         p_accts_pay_ccid   IN OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Acct Pay Code Combination'
                              );

         SELECT code_combination_id
           INTO p_accts_pay_ccid
           FROM gl_code_combinations_kfv
          WHERE concatenated_segments = p_accts_pay_cc
            AND gl_account_type = 'L'
            AND enabled_flag = 'Y'
            AND TRUNC (SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

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
                                              || ' - Invalid Acct Pay Code Combination =>'
                                              || p_accts_pay_cc
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.accts_pay_code_comb_value
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
                                              || ' - Invalid Acct Pay Code Combination =>'
                                              || p_accts_pay_cc
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.accts_pay_code_comb_value
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                            'Errors In Acct Pay Code Combination Validation '
                         || SQLCODE
                        );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                              || ' - Invalid Acct Pay Code Combination =>'
                                              || p_accts_pay_cc
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.accts_pay_code_comb_value
               );
            xx_emf_pkg.write_log
                                (xx_emf_cn_pkg.cn_low,
                                    'X_ERROR_CODE Acct Pay Code Combination: '
                                 || x_error_code
                                );
            RETURN x_error_code;
      END is_accts_pay_cc_valid;

      FUNCTION is_prepay_cc_valid (
         p_prepay_cc     IN       VARCHAR2,
         p_prepay_ccid   IN OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Prepay Combination'
                              );

         SELECT code_combination_id
           INTO p_prepay_ccid
           FROM gl_code_combinations_kfv
          WHERE concatenated_segments = p_prepay_cc
            AND enabled_flag = 'Y'
            AND TRUNC (SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

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
                                               || ' - Invalid Prepay Combination =>'
                                               || p_prepay_cc
                                               || '-'
                                               || xx_emf_cn_pkg.cn_too_many,
                 p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                 p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                 p_record_identifier_3      => p_cnv_hdr_rec.prepay_code_comb_value
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
                                               || ' - Invalid Prepay Combination =>'
                                               || p_prepay_cc
                                               || '-'
                                               || xx_emf_cn_pkg.cn_no_data,
                 p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                 p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                 p_record_identifier_3      => p_cnv_hdr_rec.prepay_code_comb_value
                );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                   'Errors In Prepay Combination Validation '
                                || SQLCODE
                               );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                (p_severity                 => xx_emf_cn_pkg.cn_medium,
                 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                 p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                               || ' - Invalid Prepay Combination =>'
                                               || p_prepay_cc
                                               || '-'
                                               || SQLERRM,
                 p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                 p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                 p_record_identifier_3      => p_cnv_hdr_rec.prepay_code_comb_value
                );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE Prepay Combination: '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_prepay_cc_valid;
      --Function to validate terms date basis as per Wave1 22-OCT-13
      FUNCTION is_terms_date_basis_valid (
         p_terms_basis   IN OUT  VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code      NUMBER        := xx_emf_cn_pkg.cn_success;
         x_terms_basis   VARCHAR2 (30);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Terms Date Basis'
                              );

         SELECT lookup_code
           INTO x_terms_basis
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_terms_basis)
            AND lookup_type = 'TERMS DATE BASIS'
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         p_terms_basis := x_terms_basis;
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
                                                     || ' - Invalid Terms Date Basis =>'
                                                     || p_terms_basis
                                                     || '-'
                                                     || xx_emf_cn_pkg.cn_too_many,
                       p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                       p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                       p_record_identifier_3      => p_cnv_hdr_rec.terms_date_basis
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
                                                     || ' - Invalid Terms Date Basis =>'
                                                     || p_terms_basis
                                                     || '-'
                                                     || xx_emf_cn_pkg.cn_no_data,
                       p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                       p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                       p_record_identifier_3      => p_cnv_hdr_rec.terms_date_basis
                      );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Terms Date Basis Validation '
                                  || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                      (p_severity                 => xx_emf_cn_pkg.cn_medium,
                       p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                       p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                     || ' - Invalid Terms Date Basis =>'
                                                     || p_terms_basis
                                                     || '-'
                                                     || SQLERRM,
                       p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                       p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                       p_record_identifier_3      => p_cnv_hdr_rec.terms_date_basis
                      );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE Terms Date Basis '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_terms_date_basis_valid;
      --Function to validate Match Option as per Wave1 22-OCT-13
      FUNCTION is_match_option_valid (
         p_match_option   IN OUT  VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code      NUMBER        := xx_emf_cn_pkg.cn_success;
         x_match_option   VARCHAR2 (30);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Match Option'
                              );

         SELECT lookup_code
           INTO x_match_option
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_match_option)
            AND lookup_type = 'PO INVOICE MATCH OPTION'
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         p_match_option := x_match_option;
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
                                                     || ' - Invalid Match Option =>'
                                                     || p_match_option
                                                     || '-'
                                                     || xx_emf_cn_pkg.cn_too_many,
                       p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                       p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                       p_record_identifier_3      => p_cnv_hdr_rec.match_option
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
                                                     || ' - Invalid Match Option =>'
                                                     || p_match_option
                                                     || '-'
                                                     || xx_emf_cn_pkg.cn_no_data,
                       p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                       p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                       p_record_identifier_3      => p_cnv_hdr_rec.match_option
                      );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Match Option Validation '
                                  || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                      (p_severity                 => xx_emf_cn_pkg.cn_medium,
                       p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                       p_error_text               =>    p_cnv_hdr_rec.vendor_site_code
                                                     || ' - Invalid Match Option =>'
                                                     || p_match_option
                                                     || '-'
                                                     || SQLERRM,
                       p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                       p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                       p_record_identifier_3      => p_cnv_hdr_rec.match_option
                      );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE Match Option '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_match_option_valid;

   -- End of delcaration of Local Functions

   -----------------------Data Validation Starts---------------------------------------------
   -- Start of the main function data_validations
   --- This will only have calls to the individual functions.
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Data-Validations');
      x_error_code_temp :=
         is_operating_unit_valid (p_cnv_hdr_rec.operating_unit_name,
                                  p_cnv_hdr_rec.org_id
                                 );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' After Operating Unit Validation'
                           );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' p_cnv_hdr_rec.org_id x_error_code :'
                            || x_error_code
                           );
      x_error_code_temp :=
           is_vendor_valid ( p_cnv_hdr_rec.attribute1
                            ,p_cnv_hdr_rec.attribute2
                            ,p_cnv_hdr_rec.vendor_id);  --Modified to handle duplicate leg sup num issue
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' p_cnv_hdr_rec.vendor_id x_error_code :'
                            || x_error_code
                           );
      --Added to check for Duplicate vendor site codes in data file
      x_error_code_temp :=
         is_vendor_scode_duplicate(p_cnv_hdr_rec.vendor_site_code,
                                   p_cnv_hdr_rec.attribute2,
                                   p_cnv_hdr_rec.operating_unit_name,
                                   p_cnv_hdr_rec.batch_id,
                                   p_cnv_hdr_rec.record_number
                                  );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' vendor site code duplicate in data file -  x_error_code :'
                            || x_error_code
                           );
      IF x_error_code = xx_emf_cn_pkg.cn_success THEN
         x_error_code_temp :=
            is_vendor_sitecode_valid (p_cnv_hdr_rec.vendor_site_code,
                                      p_cnv_hdr_rec.vendor_id,
                                      p_cnv_hdr_rec.org_id
                                     );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' vendor site code-  x_error_code :'
                               || x_error_code
                              );
      END IF;

      IF p_cnv_hdr_rec.ship_to_location_code IS NOT NULL
      THEN
         x_error_code_temp :=
            is_ship_loc_valid (p_cnv_hdr_rec.ship_to_location_code,
                               p_cnv_hdr_rec.ship_to_location_id
                              );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                     (xx_emf_cn_pkg.cn_low,
                         ' p_cnv_hdr_rec.ship_to_location_code x_error_code :'
                      || x_error_code
                     );
      END IF;

      IF p_cnv_hdr_rec.bill_to_location_code IS NOT NULL
      THEN
         x_error_code_temp :=
            is_bill_loc_valid (p_cnv_hdr_rec.bill_to_location_code,
                               p_cnv_hdr_rec.bill_to_location_id
                              );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                        ' p_cnv_hdr_rec.bill_to_location_code  x_error_code :'
                     || x_error_code
                    );
      END IF;

      IF p_cnv_hdr_rec.fob_lookup_code IS NOT NULL
      THEN
         x_error_code_temp :=
                     is_fob_lookup_code_valid (p_cnv_hdr_rec.fob_lookup_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                ' is_fob_lookup_code_valid -  x_error_code :'
                             || x_error_code
                            );
      END IF;

      IF p_cnv_hdr_rec.pay_group_lookup_code IS NOT NULL
      THEN
         x_error_code_temp :=
                is_pay_group_code_valid (p_cnv_hdr_rec.pay_group_lookup_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                                 ' is_pay_group_code_valid -  x_error_code :'
                              || x_error_code
                             );
      END IF;

      IF p_cnv_hdr_rec.payment_method_lookup_code IS NOT NULL
      THEN
         x_error_code_temp :=
            is_pay_method_code_valid
                                    (p_cnv_hdr_rec.payment_method_lookup_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                ' is_pay_method_code_valid -  x_error_code :'
                             || x_error_code
                            );
      END IF;

      IF p_cnv_hdr_rec.freight_terms_lookup_code IS NOT NULL
      THEN
         x_error_code_temp :=
            is_freight_terms_code_valid
                                     (p_cnv_hdr_rec.freight_terms_lookup_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                         (xx_emf_cn_pkg.cn_low,
                             ' is_freight_terms_code_valid -  x_error_code :'
                          || x_error_code
                         );
      END IF;

      x_error_code_temp :=
         is_terms_name_valid (p_cnv_hdr_rec.terms_name,
                              p_cnv_hdr_rec.terms_id
                             );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' is_terms_name_valid => '
                            || p_cnv_hdr_rec.terms_id
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' is_terms_name_valid -  x_error_code :'
                            || x_error_code
                           );

      IF p_cnv_hdr_rec.invoice_currency_code IS NOT NULL
      THEN
         x_error_code_temp :=
              is_invoice_cur_code_valid (p_cnv_hdr_rec.invoice_currency_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_invoice_cur_code_valid => '
                               || p_cnv_hdr_rec.invoice_currency_code
                              );
         xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                ' is_invoice_cur_code_valid -  x_error_code :'
                             || x_error_code
                            );
      END IF;

      IF p_cnv_hdr_rec.payment_currency_code IS NOT NULL
      THEN
         x_error_code_temp :=
              is_payment_cur_code_valid (p_cnv_hdr_rec.payment_currency_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_payment_cur_code_valid  => '
                               || p_cnv_hdr_rec.payment_currency_code
                              );
         xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                ' is_payment_cur_code_valid -  x_error_code :'
                             || x_error_code
                            );
      END IF;

      IF p_cnv_hdr_rec.ship_via_lookup_code IS NOT NULL
      THEN
         x_error_code_temp :=
            is_ship_via_code_valid (p_cnv_hdr_rec.ship_via_lookup_code,
                                    p_cnv_hdr_rec.org_id
                                   );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_ship_via_code_valid  => '
                               || p_cnv_hdr_rec.ship_via_lookup_code
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_ship_via_code_valid -  x_error_code :'
                               || x_error_code
                              );
      END IF;

      x_error_code_temp := is_address1_valid (p_cnv_hdr_rec.address_line1);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' is_address1_valid  => '
                            || p_cnv_hdr_rec.address_line1
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' is_address1_valid -  x_error_code :'
                            || x_error_code
                           );
      /*x_error_code_temp := is_state_valid (p_cnv_hdr_rec.state);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' is_state_valid  => ' || p_cnv_hdr_rec.state
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' is_state_valid -  x_error_code :'
                            || x_error_code
                           );
      x_error_code_temp := is_city_valid (p_cnv_hdr_rec.city);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' is_city_valid  => ' || p_cnv_hdr_rec.city
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' is_city_valid -  x_error_code :' || x_error_code
                           );*/
      x_error_code_temp := is_country_valid (p_cnv_hdr_rec.country);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' is_country_valid  => ' || p_cnv_hdr_rec.country
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' is_country_valid -  x_error_code :'
                            || x_error_code
                           );

      /*IF p_cnv_hdr_rec.county IS NOT NULL
      THEN
         x_error_code_temp :=
            is_county_valid (p_cnv_hdr_rec.county,
                             p_cnv_hdr_rec.state,
                             p_cnv_hdr_rec.zip,
                             p_cnv_hdr_rec.city,
                             p_cnv_hdr_rec.country
                            );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' is_county_valid  => ' || p_cnv_hdr_rec.county
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_county_valid -  x_error_code :'
                               || x_error_code
                              );
      END IF;*/

      IF p_cnv_hdr_rec.address_style IS NOT NULL
      THEN
         x_error_code_temp :=
                         is_address_style_valid (p_cnv_hdr_rec.address_style);
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_address_style_valid  => '
                               || p_cnv_hdr_rec.address_style
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_address_style_valid -  x_error_code :'
                               || x_error_code
                              );
      END IF;

      IF p_cnv_hdr_rec.LANGUAGE IS NOT NULL
      THEN
         x_error_code_temp := is_language_valid (p_cnv_hdr_rec.LANGUAGE);
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_language_valid  => '
                               || p_cnv_hdr_rec.LANGUAGE
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_language_valid -  x_error_code :'
                               || x_error_code
                              );
      END IF;

      IF p_cnv_hdr_rec.awt_group_name IS NOT NULL
      THEN
         x_error_code_temp :=
            is_awt_grp_name_valid (p_cnv_hdr_rec.awt_group_name,
                                   p_cnv_hdr_rec.awt_group_id
                                  );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_awt_grp_name_valid  => '
                               || p_cnv_hdr_rec.awt_group_name
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_awt_grp_name_valid -  x_error_code :'
                               || x_error_code
                              );
      END IF;

      IF p_cnv_hdr_rec.shipping_control IS NOT NULL
      THEN
         x_error_code_temp :=
                   is_shipping_control_valid (p_cnv_hdr_rec.shipping_control);
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_shipping_control_valid  => '
                               || p_cnv_hdr_rec.shipping_control
                              );
         xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                ' is_shipping_control_valid -  x_error_code :'
                             || x_error_code
                            );
      END IF;

      IF p_cnv_hdr_rec.payment_method_code IS NOT NULL
      THEN
         x_error_code_temp :=
             is_payment_method_code_valid (p_cnv_hdr_rec.payment_method_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_payment_method_code_valid  => '
                               || p_cnv_hdr_rec.payment_method_code
                              );
         xx_emf_pkg.write_log
                         (xx_emf_cn_pkg.cn_low,
                             ' is_payment_method_code_valid -  x_error_code :'
                          || x_error_code
                         );
      END IF;

      IF p_cnv_hdr_rec.pay_awt_group_name IS NOT NULL
      THEN
         x_error_code_temp :=
                 is_pay_awt_grp_name_valid (p_cnv_hdr_rec.pay_awt_group_name);
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_pay_awt_grp_name_valid  => '
                               || p_cnv_hdr_rec.pay_awt_group_name
                              );
         xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                ' is_pay_awt_grp_name_valid -  x_error_code :'
                             || x_error_code
                            );
      END IF;

      IF p_cnv_hdr_rec.accts_pay_code_comb_value IS NOT NULL
      THEN
         x_error_code_temp :=
            is_accts_pay_cc_valid
                                 (p_cnv_hdr_rec.accts_pay_code_comb_value,
                                  p_cnv_hdr_rec.accts_pay_code_combination_id
                                 );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_accts_pay_cc_valid  => '
                               || p_cnv_hdr_rec.accts_pay_code_comb_value
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_accts_pay_cc_valid -  x_error_code :'
                               || x_error_code
                              );
      END IF;

      IF p_cnv_hdr_rec.prepay_code_comb_value IS NOT NULL
      THEN
         x_error_code_temp :=
            is_accts_pay_cc_valid (p_cnv_hdr_rec.prepay_code_comb_value,
                                   p_cnv_hdr_rec.prepay_code_combination_id
                                  );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_accts_pay_cc_valid  => '
                               || p_cnv_hdr_rec.prepay_code_comb_value
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_accts_pay_cc_valid -  x_error_code :'
                               || x_error_code
                              );
      END IF;
      --Call function to validate terms_date_basis as per Wave1 22-OCT-13
      IF p_cnv_hdr_rec.terms_date_basis IS NOT NULL
      THEN
         x_error_code_temp :=
            is_terms_date_basis_valid (p_cnv_hdr_rec.terms_date_basis
                                       );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_terms_date_basis_valid  => '
                               || p_cnv_hdr_rec.terms_date_basis
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_terms_date_basis_valid -  x_error_code :'
                               || x_error_code
                              );
      END IF;
      --Call function to validate match_option as per Wave1 22-OCT-13
      IF p_cnv_hdr_rec.match_option IS NOT NULL
      THEN
         x_error_code_temp :=
            is_match_option_valid (p_cnv_hdr_rec.match_option
                                  );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_match_option_valid  => '
                               || p_cnv_hdr_rec.match_option
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' is_match_option_valid -  x_error_code :'
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
                        p_cnv_pre_std_hdr_rec   IN OUT   xx_ap_sus_conversion_pkg.g_xx_sus_cnv_pre_std_rec_type
                             )
      RETURN NUMBER
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      -- Declaration of Local Functions
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Data Derivations');
      x_error_code := xx_emf_cn_pkg.cn_success;
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

END xx_ap_sus_cnv_validations_pkg;
/


GRANT EXECUTE ON APPS.XX_AP_SUS_CNV_VALIDATIONS_PKG TO INTG_XX_NONHR_RO;
