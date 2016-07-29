DROP PACKAGE BODY APPS.XX_AP_SUP_CNV_VALIDATIONS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AP_SUP_CNV_VALIDATIONS_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 06-FEB-2012
 File Name     : XXAPSUPVAL.pks
 Description   : This script creates the body of the package
                 xx_ap_sup_cnv_validations_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 06-FEB-2012 Sharath Babu          Initial development.
 24-FEB-2012 Sharath Babu          Added function to derive mappping value
 02-MAY-2012 Sharath Babu          Modified ship_via validation query,payment term logic
 28-JUN-2012 Sharath Babu          Added is_vendor_duplicate to check for
                                   Duplicate vendors in data file
 07-MAY-2013 Sharath Babu          Modified as per Wave1
 22-OCT-2013 Sharath Babu          Modified as per Wave1
 16-DEC-2013 Sharath Babu          Modified logic to check payment_method_lookup_code
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
      RETURN x_error_code;
   END batch_validations;

   FUNCTION data_validations (
      p_cnv_hdr_rec   IN OUT   xx_ap_sup_conversion_pkg.g_xx_sup_cnv_pre_std_rec_type
     ,p_validate_and_load   IN       VARCHAR2
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

      --- Local functions for all batch level validations
      --- Add as many functions as required

      ------------------Validation for duplicate vendor Name----------------------
      FUNCTION is_vendor_name_valid (
         p_vendor_name   IN   ap_suppliers.vendor_name%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for vendor name'
                              );

         BEGIN
            IF p_vendor_name IS NOT NULL
            THEN
               SELECT 'X'
                 INTO x_variable
                 FROM ap_suppliers
                WHERE UPPER(vendor_name) = UPPER(p_vendor_name);

               --Added as per Wave1
               IF p_validate_and_load = g_validate_and_load THEN
                  UPDATE ap_suppliers
                     SET attribute1 = attribute1||'|'||p_cnv_hdr_rec.attribute1
                        ,attribute2 = attribute2||'|'||p_cnv_hdr_rec.attribute2
                   WHERE UPPER(vendor_name) = UPPER(p_vendor_name)
                     AND attribute1 NOT LIKE '%'||p_cnv_hdr_rec.attribute1||'%'
                     AND attribute2 NOT LIKE '%'||p_cnv_hdr_rec.attribute2||'%';
                  COMMIT;
               END IF;
               xx_emf_pkg.write_log
                                  (xx_emf_cn_pkg.cn_medium,
                                   'Vendor name  already exists in the system'
                                  );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                 || ' - Invalid : Vendor name  already exists in the system => '
                                                 || p_vendor_name
                                                 || '-'
                                                 || 'Data Exists',
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                   p_record_identifier_3      => p_cnv_hdr_rec.vendor_name
                  );
            ELSE
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                     'Vendor name IS NULL'
                                    );
               xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                       || ' - Invalid : Vendor name IS NULL => '
                                                       || p_vendor_name
                                                       || '-'
                                                       || 'Data not Provided',
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.vendor_name
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
                         p_category                 => xx_emf_cn_pkg.cn_vendor_name_valid,
                         p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                       || ' - Invalid Vendor name => '
                                                       || p_vendor_name
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_too_many,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.vendor_name
                        );
               RETURN x_error_code;
            WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_success;
               RETURN x_error_code;
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Errors In Vendor name Validation '
                                     || SQLCODE
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_vendor_name_valid,
                         p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                       || ' - Invalid Vendor name => '
                                                       || p_vendor_name
                                                       || '-'
                                                       || SQLERRM,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.vendor_name
                        );
               RETURN x_error_code;
         END;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                  'Checking for when others vendor name'
                                 );
            RETURN x_error_code;
      END is_vendor_name_valid;
      --Function to check for Duplicate vendors in data file
      FUNCTION is_vendor_duplicate (
               p_vendor_name   IN   ap_suppliers.vendor_name%TYPE,
               p_batch_id      IN   VARCHAR2,
               p_record_num    IN   NUMBER
            )
               RETURN NUMBER
      IS
         CURSOR c_duplicate_vendors( p_vendor_name  VARCHAR2
                                    ,p_batch_id     VARCHAR2
                                    ,p_record_num   NUMBER    )
         IS
         SELECT b.vendor_name,b.batch_id,b.record_number
           FROM xx_ap_suppliers_pre_int b
          WHERE 1=1
            AND b.vendor_name IN
                             (
                               SELECT vendor_name
                                 FROM xx_ap_suppliers_pre_int
                                WHERE 1=1
                                  AND batch_id = p_batch_id
                                  AND vendor_name = p_vendor_name
                                  AND error_code = xx_emf_cn_pkg.cn_success
                             GROUP BY vendor_name
                               HAVING COUNT(*) > 1
                              )
            AND b.batch_id = p_batch_id
            AND b.record_number <> p_record_num;

         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
         x_count        NUMBER;
      BEGIN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Check for Duplicate vendor name in Data File'
                                    );

               SELECT COUNT(*)
                 INTO x_count
                 FROM xx_ap_suppliers_pre_int
                WHERE vendor_name = p_vendor_name
                  AND batch_id = p_batch_id;

               IF x_count > 1 THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  FOR r_dup_vendors IN c_duplicate_vendors(p_vendor_name,p_batch_id,p_record_num)
                  LOOP
                     x_error_code := xx_emf_cn_pkg.cn_success;

                     UPDATE xx_ap_suppliers_pre_int
                        SET error_code = xx_emf_cn_pkg.cn_rec_err
                      WHERE batch_id = r_dup_vendors.batch_id
                        AND record_number = r_dup_vendors.record_number
                        AND vendor_name = r_dup_vendors.vendor_name;
                  END LOOP;
                  COMMIT;
                  IF x_error_code = xx_emf_cn_pkg.cn_rec_err THEN
                     xx_emf_pkg.error
                             (p_severity                 => xx_emf_cn_pkg.cn_medium,
                              p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                              p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                            || ' - Invalid: Duplicate Vendor In Data File => '
                                                            || p_vendor_name,
                              p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                              p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                              p_record_identifier_3      => p_cnv_hdr_rec.vendor_name
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
                                        'Checking for duplicate vendor name : when others'
                                       );
                  RETURN x_error_code;
      END is_vendor_duplicate;

      ----------------------validation for ship_to_location_code------------
      FUNCTION is_ship_to_code_valid (
         p_ship_to_code          IN       VARCHAR2,
         p_ship_to_location_id   IN OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Ship to Loc Code'
                              );

         SELECT ship_to_location_id
           INTO p_ship_to_location_id
           FROM hr_locations_all
          WHERE hr_locations_all.location_code = p_ship_to_code
            AND hr_locations_all.ship_to_site_flag = 'Y';

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
                  p_category                 => xx_emf_cn_pkg.cn_ship_to_code_valid,
                  p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                || ' - Invalid Ship to Loc code => '
                                                || p_ship_to_code
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
                  p_category                 => xx_emf_cn_pkg.cn_ship_to_code_valid,
                  p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                || ' - Invalid Ship to Loc code => '
                                                || p_ship_to_code
                                                || '-'
                                                || xx_emf_cn_pkg.cn_no_data,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.ship_to_location_code
                 );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Ship to Loc code Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.cn_ship_to_code_valid,
                  p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                || ' - Invalid Ship to Loc code => '
                                                || p_ship_to_code
                                                || '-'
                                                || SQLERRM,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.ship_to_location_code
                 );
            RETURN x_error_code;
      END is_ship_to_code_valid;

      -------------------validation for bill_to_location_code------------------
      FUNCTION is_bill_to_code_valid (
         p_bill_to_code          IN       VARCHAR2,
         p_bill_to_location_id   IN OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Bill to Loc code'
                              );

         SELECT location_id
           INTO p_bill_to_location_id
           FROM hr_locations_all
          WHERE hr_locations_all.location_code = p_bill_to_code
            AND hr_locations_all.bill_to_site_flag = 'Y';

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
                  p_category                 => xx_emf_cn_pkg.cn_bill_to_code_valid,
                  p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                || ' - Invalid Bill to Loc code => '
                                                || p_bill_to_code
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
                  p_category                 => xx_emf_cn_pkg.cn_bill_to_code_valid,
                  p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                || ' - Invalid Bill to Loc code => '
                                                || p_bill_to_code
                                                || '-'
                                                || xx_emf_cn_pkg.cn_no_data,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.bill_to_location_code
                 );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Bill to Loc code Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.cn_bill_to_code_valid,
                  p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                || ' - Invalid Bill to Loc code => '
                                                || p_bill_to_code
                                                || '-'
                                                || SQLERRM,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.bill_to_location_code
                 );
            RETURN x_error_code;
      END is_bill_to_code_valid;

      ----------validation for fob_lookup_code--------------------
      FUNCTION is_fob_lookup_code_valid (
         p_fob_lookup_code   IN OUT   ap_suppliers.fob_lookup_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code        NUMBER        := xx_emf_cn_pkg.cn_success;
         x_fob_lookup_code   VARCHAR2 (40);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for fob lookup code'
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
                        p_category                 => xx_emf_cn_pkg.cn_fob_lookup_code_valid,
                        p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                      || ' - Invalid FOB Lookup Code => '
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
                        p_category                 => xx_emf_cn_pkg.cn_fob_lookup_code_valid,
                        p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                      || ' - Invalid FOB Lookup Code => '
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
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In FOB Lookup Code Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => xx_emf_cn_pkg.cn_fob_lookup_code_valid,
                        p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                      || ' - Invalid FOB Lookup Code => '
                                                      || x_fob_lookup_code
                                                      || '-'
                                                      || SQLERRM,
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                        p_record_identifier_3      => p_cnv_hdr_rec.fob_lookup_code
                       );
            RETURN x_error_code;
      END is_fob_lookup_code_valid;

      --------------validation for PAY_GROUP_LOOKUP_CODE-----------------
      FUNCTION is_pay_group_code_valid (
         p_pay_group_code   IN OUT NOCOPY   ap_suppliers.pay_group_lookup_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_pay_group    VARCHAR2 (40);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Validation for pay group code: '
                               || p_pay_group_code
                              );

         SELECT lookup_code
           INTO x_pay_group
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_pay_group_code) --UPPER (meaning) = UPPER (p_pay_group_code) Modified as per Wave1 22-OCT-13
            AND lookup_type = xx_emf_cn_pkg.cn_paygroup_lookup_code
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         p_pay_group_code := x_pay_group;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'After validation p_pay_group_code : '
                               || p_pay_group_code
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
                  p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                || ' - Invalid Pay Group code => '
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
                  p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                || ' - Invalid Pay Group code => '
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
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                'Errors In Pay Group lookup Code Validation '
                             || SQLCODE
                            );
            xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium,
                  p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                  p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                || ' - Invalid Pay Group code => '
                                                || p_pay_group_code
                                                || '-'
                                                || SQLERRM,
                  p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                  p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                  p_record_identifier_3      => p_cnv_hdr_rec.pay_group_lookup_code
                 );
            RETURN x_error_code;
      END is_pay_group_code_valid;

      -----------validation for pay_method_lookup_code------------
      FUNCTION is_pay_method_code_valid (
         p_pay_method_code   IN OUT   ap_suppliers.payment_method_lookup_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code       NUMBER        := xx_emf_cn_pkg.cn_success;
         x_payment_method   VARCHAR2 (40);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for pay method code'
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
                               'p_pay_method_code : ' || p_pay_method_code
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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Payment Method Code =>'
                                              || p_pay_method_code
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.payment_method_lookup_code
               );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'X_ERROR_CODE Pay Method ' || x_error_code
                                 );
            RETURN x_error_code;
      END is_pay_method_code_valid;

      -----------Validation for freight_terms_code-------------
      FUNCTION is_freight_terms_code_valid (
         p_freight_terms_code   IN OUT NOCOPY   ap_suppliers.freight_terms_lookup_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code      NUMBER        := xx_emf_cn_pkg.cn_success;
         x_freight_terms   VARCHAR2 (50);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for freight term code'
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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
                                   'Errors In Freight Terms Code Validation '
                                || SQLCODE
                               );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
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

      ----------validation for vendor_type_lookup_code----------
      FUNCTION is_vendor_type_code_valid (
         p_vendor_type_code   IN OUT   ap_suppliers.vendor_type_lookup_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code         NUMBER        := xx_emf_cn_pkg.cn_success;
         x_vendor_type_code   VARCHAR2 (40);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for vendor type code'
                              );

         SELECT lookup_code
           INTO x_vendor_type_code
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_vendor_type_code)  --UPPER (meaning) = UPPER (p_vendor_type_code) Modified as per Wave1 11-SEP-13
            AND lookup_type = xx_emf_cn_pkg.cn_vendor_type_lookup_code
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         p_vendor_type_code := x_vendor_type_code;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Derived vendor type code: '
                               || p_vendor_type_code
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
                p_category                 => xx_emf_cn_pkg.cn_vendor_type_code_valid,
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Vendor Type Code =>'
                                              || p_vendor_type_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.vendor_type_lookup_code
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
                p_category                 => xx_emf_cn_pkg.cn_vendor_type_code_valid,
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Vendor Type Code =>'
                                              || p_vendor_type_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.vendor_type_lookup_code
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Vendor Type Code Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_vendor_type_code_valid,
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Vendor Type Code =>'
                                              || p_vendor_type_code
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.vendor_type_lookup_code
               );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE Vendor Type Code '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_vendor_type_code_valid;

      ----------validation for Invoice currency_code-----------
      FUNCTION is_currency_code_valid (
         p_currency_code   IN OUT   ap_suppliers.invoice_currency_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_cur_code     VARCHAR2 (40);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for currency code'
                              );
          x_cur_code :=
	             xx_intg_common_pkg.get_mapping_value (p_mapping_type   => 'VENDOR_CURRENCY',
	                                                   p_old_value      => p_currency_code,
	                                                   p_date_effective => SYSDATE
                                                          );
           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'derived value of  x_cur_code: '
                               || x_cur_code
                              );

         SELECT currency_code
           INTO p_currency_code
           FROM fnd_currencies
          WHERE UPPER (currency_code) = UPPER (TRIM(x_cur_code))
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
                  p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                || ' - Invalid Invioce Currency code =>'
                                                || x_cur_code
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
                  p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                  p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                || ' - Invalid Invoice Currency code =>'
                                                || x_cur_code
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
                  p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                  p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                || ' - Invalid Invoice Currency code =>'
                                                || x_cur_code
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
      END is_currency_code_valid;

      -----------------  Validation for Payment Currency Code ---------------
      FUNCTION is_payment_cur_code_valid (
         p_payment_currency_code   IN OUT   ap_suppliers.payment_currency_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_cur_code     VARCHAR2 (40);
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
                  p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                || ' - Invalid Payment Currency code =>'
                                                || x_cur_code
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
                  p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                || ' - Invalid Payment Currency code =>'
                                                || x_cur_code
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
                  p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                || ' - Invalid Payment Currency code =>'
                                                || x_cur_code
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

      ----------------Validation for terms_name --------------
      FUNCTION is_terms_name_valid (
         p_terms_name   IN OUT          VARCHAR2,
         p_terms_id     IN OUT NOCOPY   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
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
                         p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
                         p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
                                  'Errors In Term Name Validation ' || SQLCODE
                                 );
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    p_cnv_hdr_rec.vendor_name
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

      FUNCTION is_type_1099_valid (
         p_type_1099                 IN OUT  VARCHAR2,
         p_federal_reportable_flag   IN   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_type_1099    VARCHAR2 (50);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Type_1099 '
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'TYPE_1099 :' || p_type_1099
                              );

         SELECT income_tax_type
           INTO x_type_1099
           FROM ap_income_tax_types
          WHERE UPPER(income_tax_type) = UPPER(p_type_1099)
            AND 'Y' = p_federal_reportable_flag
            AND NVL (inactive_date, SYSDATE) >= SYSDATE;

            p_type_1099 := x_type_1099;

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
                         p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                       || ' - Invalid TYPE_1099 =>'
                                                       || p_type_1099
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_too_many,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.type_1099
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
                         p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                       || ' - Invalid TYPE_1099 =>'
                                                       || p_type_1099
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_no_data,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.type_1099
                        );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors In TYPE_1099 Validation ' || SQLCODE
                                 );
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                       || ' - Invalid TYPE_1099 =>'
                                                       || p_type_1099
                                                       || '-'
                                                       || SQLERRM,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.type_1099
                        );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'X_ERROR_CODE TYPE_1099 ' || x_error_code
                                 );
            RETURN x_error_code;
      END is_type_1099_valid;

      FUNCTION is_emp_id_valid (p_emp_id IN NUMBER)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         x_emp_id       NUMBER;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Employee Id '
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'p_emp_id :' || p_emp_id);

         SELECT employee_id
           INTO x_emp_id
           FROM hr_employees_current_v
          WHERE employee_id = p_emp_id;

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
                         p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                       || ' - Invalid Employee ID =>'
                                                       || p_emp_id
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_too_many,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.employee_id
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
                         p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                       || ' - Invalid Employee ID =>'
                                                       || p_emp_id
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_no_data,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.employee_id
                        );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Employee ID Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                       || ' - Invalid Employee ID =>'
                                                       || p_emp_id
                                                       || '-'
                                                       || SQLERRM,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                         p_record_identifier_3      => p_cnv_hdr_rec.employee_id
                        );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'X_ERROR_CODE p_emp_id ' || x_error_code
                                 );
            RETURN x_error_code;
      END is_emp_id_valid;

      FUNCTION is_ship_via_code_valid (p_ship_via_lookup_code IN OUT VARCHAR2 )
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

         /*SELECT DISTINCT freight_code
	   INTO p_ship_via_lookup_code
	   FROM org_freight
          WHERE UPPER(freight_code) = UPPER(x_ship_via_code);*/

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
                   p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
                   p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
            xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                 || ' - Invalid Ship Via code =>'
                                                 || x_ship_via_code
                                                 || '-'
                                                 || SQLERRM,
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                   p_record_identifier_3      => p_cnv_hdr_rec.ship_via_lookup_code
                  );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE ship_via_lookup_code '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_ship_via_code_valid;

      FUNCTION is_org_type_code_valid (
         p_org_type_code   IN OUT   ap_suppliers.organization_type_lookup_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code      NUMBER        := xx_emf_cn_pkg.cn_success;
         x_org_type_code   VARCHAR2 (30);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Organization Type lookup code'
                              );

         SELECT lookup_code
           INTO x_org_type_code
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_org_type_code)--UPPER (meaning) = UPPER (p_org_type_code) Modified as per Wave1 22-OCT-13
            AND lookup_type = xx_ap_sup_conversion_pkg.g_org_type_code
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         p_org_type_code := x_org_type_code;
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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Org Type Lookup Code =>'
                                              || p_org_type_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.organization_type_lookup_code
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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Org Type Lookup Code =>'
                                              || p_org_type_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.organization_type_lookup_code
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                                 'Errors In Org Type Lookup Code Validation '
                              || SQLCODE
                             );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Org Type Lookup Code =>'
                                              || p_org_type_code
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.organization_type_lookup_code
               );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE Org Type Lookup Code: '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_org_type_code_valid;

      FUNCTION is_minority_grp_code_valid (
         p_minority_grp_code   IN OUT   ap_suppliers.minority_group_lookup_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code          NUMBER        := xx_emf_cn_pkg.cn_success;
         x_minority_grp_code   VARCHAR2 (30);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Minority Group lookup code'
                              );

         SELECT lookup_code
           INTO x_minority_grp_code
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_minority_grp_code)--UPPER (meaning) = UPPER (p_minority_grp_code) Modified as per Wave1 22-OCT-13
            AND lookup_type = xx_ap_sup_conversion_pkg.g_minority_grp_code
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         p_minority_grp_code := x_minority_grp_code;
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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Minority Group Lookup Code =>'
                                              || p_minority_grp_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.minority_group_lookup_code
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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Minority Group Lookup Code =>'
                                              || p_minority_grp_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.minority_group_lookup_code
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                       (xx_emf_cn_pkg.cn_low,
                           'Errors In Minority Group Lookup Code Validation '
                        || SQLCODE
                       );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Minority Group Lookup Code =>'
                                              || p_minority_grp_code
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.minority_group_lookup_code
               );
            xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                   'X_ERROR_CODE Minority Group Lookup Code: '
                                || x_error_code
                               );
            RETURN x_error_code;
      END is_minority_grp_code_valid;

      FUNCTION is_qty_rcv_exp_code_valid (
         p_qty_exp_code   IN OUT   ap_suppliers.qty_rcv_exception_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code     NUMBER        := xx_emf_cn_pkg.cn_success;
         x_qty_exp_code   VARCHAR2 (30);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Qty Rcv Excep lookup code'
                              );

         SELECT lookup_code
           INTO x_qty_exp_code
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_qty_exp_code) --UPPER (meaning) = UPPER (p_qty_exp_code) Modified as per Wave1 22-OCT-13
            AND lookup_type = xx_ap_sup_conversion_pkg.g_rcv_option_code
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         p_qty_exp_code := x_qty_exp_code;
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
                 p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                               || ' - Invalid Qty Rcv Excep Lookup Code =>'
                                               || p_qty_exp_code
                                               || '-'
                                               || xx_emf_cn_pkg.cn_too_many,
                 p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                 p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                 p_record_identifier_3      => p_cnv_hdr_rec.qty_rcv_exception_code
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
                 p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                               || ' - Invalid Qty Rcv Excep Lookup Code =>'
                                               || p_qty_exp_code
                                               || '-'
                                               || xx_emf_cn_pkg.cn_no_data,
                 p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                 p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                 p_record_identifier_3      => p_cnv_hdr_rec.qty_rcv_exception_code
                );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                            'Errors In Qty Rcv Excep Lookup Code Validation '
                         || SQLCODE
                        );
            xx_emf_pkg.error
                (p_severity                 => xx_emf_cn_pkg.cn_medium,
                 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                 p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                               || ' - Invalid Qty Rcv Excep Lookup Code =>'
                                               || p_qty_exp_code
                                               || '-'
                                               || SQLERRM,
                 p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                 p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                 p_record_identifier_3      => p_cnv_hdr_rec.qty_rcv_exception_code
                );
            xx_emf_pkg.write_log
                                (xx_emf_cn_pkg.cn_low,
                                    'X_ERROR_CODE Qty Rcv Excep Lookup Code: '
                                 || x_error_code
                                );
            RETURN x_error_code;
      END is_qty_rcv_exp_code_valid;

      FUNCTION is_enf_ship_loc_code_valid (
         p_enf_ship_loc_code   IN OUT   ap_suppliers.enforce_ship_to_location_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code          NUMBER        := xx_emf_cn_pkg.cn_success;
         x_enf_ship_loc_code   VARCHAR2 (30);
      BEGIN
         xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                             'Validation for Enforce Ship To Loc lookup code'
                            );

         SELECT lookup_code
           INTO x_enf_ship_loc_code
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_enf_ship_loc_code) --UPPER (meaning) = UPPER (p_enf_ship_loc_code) Modified as per Wave1 22-OCT-13
            AND lookup_type = xx_ap_sup_conversion_pkg.g_rcv_option_code
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         p_enf_ship_loc_code := x_enf_ship_loc_code;
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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Enforce Ship To Loc Lookup Code =>'
                                              || p_enf_ship_loc_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.enforce_ship_to_location_code
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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Enforce Ship To Loc Lookup Code =>'
                                              || p_enf_ship_loc_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.enforce_ship_to_location_code
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                  (xx_emf_cn_pkg.cn_low,
                      'Errors In Enforce Ship To Loc Lookup Code Validation '
                   || SQLCODE
                  );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Enforce Ship To Loc Lookup Code =>'
                                              || p_enf_ship_loc_code
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.enforce_ship_to_location_code
               );
            xx_emf_pkg.write_log
                          (xx_emf_cn_pkg.cn_low,
                              'X_ERROR_CODE Enforce Ship To Loc Lookup Code: '
                           || x_error_code
                          );
            RETURN x_error_code;
      END is_enf_ship_loc_code_valid;

      FUNCTION is_rcpt_days_exp_code_valid (
         p_rcpt_days_exp_code   IN OUT   ap_suppliers.receipt_days_exception_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code           NUMBER        := xx_emf_cn_pkg.cn_success;
         x_rcpt_days_exp_code   VARCHAR2 (30);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Receipt Days Exp lookup code'
                              );

         SELECT lookup_code
           INTO x_rcpt_days_exp_code
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_rcpt_days_exp_code) --UPPER (meaning) = UPPER (p_rcpt_days_exp_code) Modified as per Wave1 22-OCT-13
            AND lookup_type = xx_ap_sup_conversion_pkg.g_rcv_option_code
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         p_rcpt_days_exp_code := x_rcpt_days_exp_code;
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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Receipt Days Exp Lookup Code =>'
                                              || p_rcpt_days_exp_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.receipt_days_exception_code
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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Receipt Days Exp Lookup Code =>'
                                              || p_rcpt_days_exp_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.receipt_days_exception_code
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                  (xx_emf_cn_pkg.cn_low,
                      'Errors In Enforce Ship To Loc Lookup Code Validation '
                   || SQLCODE
                  );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Receipt Days Exp Lookup Code =>'
                                              || p_rcpt_days_exp_code
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.receipt_days_exception_code
               );
            xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                                 'X_ERROR_CODE Receipt Days Exp Lookup Code: '
                              || x_error_code
                             );
            RETURN x_error_code;
      END is_rcpt_days_exp_code_valid;

      FUNCTION is_awt_grp_name_valid (
         p_awt_grp_name   IN OUT   VARCHAR2,
         p_awt_grp_id     IN OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         x_awt_grp_name VARCHAR2(50);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for AWT Group Name'
                              );

         SELECT name, group_id
           INTO x_awt_grp_name, p_awt_grp_id
           FROM ap_awt_groups
          WHERE NAME = p_awt_grp_name
            AND NVL (inactive_date, SYSDATE) >= SYSDATE;

         x_awt_grp_name := x_awt_grp_name;
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
                         p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
                         p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    p_cnv_hdr_rec.vendor_name
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

      FUNCTION is_bank_charge_bearer_valid (p_bank_chrg_bearer IN OUT VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code           NUMBER        := xx_emf_cn_pkg.cn_success;
         x_bank_charge_bearer   VARCHAR2 (30);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Bank chrg Bearer lookup code'
                              );

         SELECT lookup_code
           INTO x_bank_charge_bearer
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_bank_chrg_bearer) --UPPER (meaning) = UPPER (p_bank_chrg_bearer) Modified as per Wave1 22-OCT-13
            AND lookup_type = xx_ap_sup_conversion_pkg.g_bank_bearer_code
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         p_bank_chrg_bearer := x_bank_charge_bearer;
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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Bank chrg Bearer Lookup Code =>'
                                              || p_bank_chrg_bearer
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.bank_charge_bearer
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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Bank chrg Bearer Lookup Code =>'
                                              || p_bank_chrg_bearer
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.bank_charge_bearer
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                'Errors In Bank chrg Bearer Code Validation '
                             || SQLCODE
                            );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Bank chrg Bearer Lookup Code =>'
                                              || p_bank_chrg_bearer
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.bank_charge_bearer
               );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE Receipt Bank chrg Bearer: '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_bank_charge_bearer_valid;

      FUNCTION is_settle_priority_valid (p_settle_priority IN OUT VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code        NUMBER        := xx_emf_cn_pkg.cn_success;
         x_settle_priority   VARCHAR2 (30);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Settlement Prioirty'
                              );

         SELECT lookup_code
           INTO x_settle_priority
           FROM fnd_lookup_values
          WHERE UPPER (lookup_code) = UPPER (p_settle_priority) --UPPER (meaning) = UPPER (p_settle_priority) Modified as per Wave1 22-OCT-13
            AND lookup_type = xx_ap_sup_conversion_pkg.g_settle_prior_code
            AND enabled_flag = 'Y'
            AND LANGUAGE = 'US'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE)) AND TRUNC(NVL(end_date_active,SYSDATE+1));

         p_settle_priority := x_settle_priority;
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
                    p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                  || ' - Invalid Settlement Prioirty =>'
                                                  || p_settle_priority
                                                  || '-'
                                                  || xx_emf_cn_pkg.cn_too_many,
                    p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                    p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                    p_record_identifier_3      => p_cnv_hdr_rec.settlement_priority
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
                    p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                  || ' - Invalid Settlement Prioirty =>'
                                                  || p_settle_priority
                                                  || '-'
                                                  || xx_emf_cn_pkg.cn_no_data,
                    p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                    p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                    p_record_identifier_3      => p_cnv_hdr_rec.settlement_priority
                   );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                              (xx_emf_cn_pkg.cn_low,
                                  'Errors In Settlement Prioirty Validation '
                               || SQLCODE
                              );
            xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
                    p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                    p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                  || ' - Invalid Settlement Prioirty =>'
                                                  || p_settle_priority
                                                  || '-'
                                                  || SQLERRM,
                    p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                    p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                    p_record_identifier_3      => p_cnv_hdr_rec.settlement_priority
                   );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE Settlement Prioirty: '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_settle_priority_valid;

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
                    p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
                    p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
            xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
                    p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                    p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
                     p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
                     p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
            xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                   'Errors In Pay AWT Group Name Validation '
                                || SQLCODE
                               );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    p_cnv_hdr_rec.vendor_name
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

      FUNCTION is_federal_flag_valid (p_federal_flag IN OUT NOCOPY VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Validation for Federal Reportable Flag: '
                               || p_federal_flag
                              );
         p_federal_flag := UPPER(p_federal_flag);

         IF p_federal_flag IN ('Y', 'N')
         THEN
            RETURN x_error_code;
         ELSE
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                              xx_emf_cn_pkg.cn_stg_dataval,
                                 p_cnv_hdr_rec.vendor_name
                              || ' - Invalid Federal Reportable Flag =>'
                              || p_federal_flag,
                              p_cnv_hdr_rec.record_number,
                              p_cnv_hdr_rec.attribute2,
                              p_cnv_hdr_rec.federal_reportable_flag
                             );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                              || ' - Invalid Federal Flag =>'
                                              || p_federal_flag
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                p_record_identifier_3      => p_cnv_hdr_rec.federal_reportable_flag
               );
            RETURN x_error_code;
      END is_federal_flag_valid;

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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
                p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
                 p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
                 p_error_text               =>    p_cnv_hdr_rec.vendor_name
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
                 p_error_text               =>    p_cnv_hdr_rec.vendor_name
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

      --Function to check for Duplicate VAT_REGISTRATION_NUM Added as per Wave1 22-OCT-13
      FUNCTION is_vat_reg_num_duplicate (
               p_vat_reg_num   IN   ap_suppliers.vendor_name%TYPE,
               p_batch_id      IN   VARCHAR2,
               p_record_num    IN   NUMBER
            )
               RETURN NUMBER
      IS
         CURSOR c_dupl_vat_num( p_vat_reg_num  VARCHAR2
                                    ,p_batch_id     VARCHAR2
                                    ,p_record_num   NUMBER    )
         IS
         SELECT b.vat_registration_num,b.batch_id,b.record_number
           FROM xx_ap_suppliers_pre_int b
          WHERE 1=1
            AND b.vat_registration_num IN
                             (
                               SELECT vat_registration_num
                                 FROM xx_ap_suppliers_pre_int
                                WHERE 1=1
                                  AND batch_id = p_batch_id
                                  AND vat_registration_num = p_vat_reg_num
                                  AND error_code = xx_emf_cn_pkg.cn_success
                             GROUP BY vat_registration_num
                               HAVING COUNT(*) > 1
                              )
            AND b.batch_id = p_batch_id
            AND b.record_number <> p_record_num;

         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
         x_count        NUMBER;
      BEGIN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Check for Duplicate vat_registration_num in Data File'
                                    );

               SELECT COUNT(*)
                 INTO x_count
                 FROM xx_ap_suppliers_pre_int
                WHERE vat_registration_num = p_vat_reg_num
                  AND batch_id = p_batch_id;

               IF x_count > 1 THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  FOR r_dupl_vat_num IN c_dupl_vat_num(p_vat_reg_num,p_batch_id,p_record_num)
                  LOOP
                     x_error_code := xx_emf_cn_pkg.cn_success;

                     UPDATE xx_ap_suppliers_pre_int
                        SET error_code = xx_emf_cn_pkg.cn_rec_err
                      WHERE batch_id = r_dupl_vat_num.batch_id
                        AND record_number = r_dupl_vat_num.record_number
                        AND vat_registration_num = r_dupl_vat_num.vat_registration_num;
                  END LOOP;
                  COMMIT;
                  IF x_error_code = xx_emf_cn_pkg.cn_rec_err THEN
                     xx_emf_pkg.error
                             (p_severity                 => xx_emf_cn_pkg.cn_medium,
                              p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                              p_error_text               =>    p_cnv_hdr_rec.vendor_name
                                                            || ' - Invalid: Duplicate vat_registration_num In Data File => '
                                                            || p_vat_reg_num,
                              p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                              p_record_identifier_2      => p_cnv_hdr_rec.attribute2,
                              p_record_identifier_3      => p_cnv_hdr_rec.vat_registration_num
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
                                        'Checking for duplicate vat_registration_num : when others'
                                       );
                  RETURN x_error_code;
      END is_vat_reg_num_duplicate;

   ---------------------------Data Validation Starts Here-----------------------------------------
   --- Start of the main function perform_batch_validations
   --- This will only have calls to the individual functions.
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Data-Validations');
      --Added to check for Duplicate vendors in data file
      x_error_code_temp := is_vendor_duplicate(p_cnv_hdr_rec.vendor_name,
                                               p_cnv_hdr_rec.batch_id,
                                               p_cnv_hdr_rec.record_number);
      x_error_code := find_max (x_error_code, x_error_code_temp);

      IF x_error_code = xx_emf_cn_pkg.cn_success THEN
         x_error_code_temp := is_vendor_name_valid (p_cnv_hdr_rec.vendor_name);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.ship_to_location_code IS NOT NULL
      THEN
         x_error_code_temp :=
            is_ship_to_code_valid (p_cnv_hdr_rec.ship_to_location_code,
                                   p_cnv_hdr_rec.ship_to_location_id
                                  );
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.bill_to_location_code IS NOT NULL
      THEN
         x_error_code_temp :=
            is_bill_to_code_valid (p_cnv_hdr_rec.bill_to_location_code,
                                   p_cnv_hdr_rec.bill_to_location_id
                                  );
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.fob_lookup_code IS NOT NULL
      THEN
         x_error_code_temp :=
                     is_fob_lookup_code_valid (p_cnv_hdr_rec.fob_lookup_code
                                              );
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.pay_group_lookup_code IS NOT NULL
      THEN
         x_error_code_temp :=
                is_pay_group_code_valid (p_cnv_hdr_rec.pay_group_lookup_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.payment_method_lookup_code IS NOT NULL
      THEN
         x_error_code_temp :=
            is_pay_method_code_valid
                                    (p_cnv_hdr_rec.payment_method_lookup_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.freight_terms_lookup_code IS NOT NULL
      THEN
         x_error_code_temp :=
            is_freight_terms_code_valid
                                     (p_cnv_hdr_rec.freight_terms_lookup_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.vendor_type_lookup_code IS NOT NULL
      THEN
         x_error_code_temp :=
            is_vendor_type_code_valid (p_cnv_hdr_rec.vendor_type_lookup_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.invoice_currency_code IS NOT NULL
      THEN
         x_error_code_temp :=
                 is_currency_code_valid (p_cnv_hdr_rec.invoice_currency_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.payment_currency_code IS NOT NULL
      THEN
         x_error_code_temp :=
              is_payment_cur_code_valid (p_cnv_hdr_rec.payment_currency_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      x_error_code_temp :=
         is_terms_name_valid (p_cnv_hdr_rec.terms_name,
                              p_cnv_hdr_rec.terms_id
                             );
      x_error_code := find_max (x_error_code, x_error_code_temp);

      IF p_cnv_hdr_rec.federal_reportable_flag IS NOT NULL
      THEN
         x_error_code_temp :=
                is_federal_flag_valid (p_cnv_hdr_rec.federal_reportable_flag);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF     p_cnv_hdr_rec.type_1099 IS NOT NULL
         AND p_cnv_hdr_rec.federal_reportable_flag IS NOT NULL
      THEN
         x_error_code_temp :=
            is_type_1099_valid (p_cnv_hdr_rec.type_1099,
                                p_cnv_hdr_rec.federal_reportable_flag
                               );
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.employee_id IS NOT NULL
      THEN
         x_error_code_temp := is_emp_id_valid (p_cnv_hdr_rec.employee_id);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.ship_via_lookup_code IS NOT NULL
      THEN
         x_error_code_temp :=
                  is_ship_via_code_valid (p_cnv_hdr_rec.ship_via_lookup_code
                                         );
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.organization_type_lookup_code IS NOT NULL
      THEN
         x_error_code_temp :=
            is_org_type_code_valid
                                 (p_cnv_hdr_rec.organization_type_lookup_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.minority_group_lookup_code IS NOT NULL
      THEN
         x_error_code_temp :=
            is_minority_grp_code_valid
                                    (p_cnv_hdr_rec.minority_group_lookup_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.qty_rcv_exception_code IS NOT NULL
      THEN
         x_error_code_temp :=
             is_qty_rcv_exp_code_valid (p_cnv_hdr_rec.qty_rcv_exception_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.enforce_ship_to_location_code IS NOT NULL
      THEN
         x_error_code_temp :=
            is_enf_ship_loc_code_valid
                                 (p_cnv_hdr_rec.enforce_ship_to_location_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.receipt_days_exception_code IS NOT NULL
      THEN
         x_error_code_temp :=
            is_rcpt_days_exp_code_valid
                                   (p_cnv_hdr_rec.receipt_days_exception_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.awt_group_name IS NOT NULL
      THEN
         x_error_code_temp :=
            is_awt_grp_name_valid (p_cnv_hdr_rec.awt_group_name,
                                   p_cnv_hdr_rec.awt_group_id
                                  );
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.bank_charge_bearer IS NOT NULL
      THEN
         x_error_code_temp :=
               is_bank_charge_bearer_valid (p_cnv_hdr_rec.bank_charge_bearer);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.settlement_priority IS NOT NULL
      THEN
         x_error_code_temp :=
                 is_settle_priority_valid (p_cnv_hdr_rec.settlement_priority);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.payment_method_code IS NOT NULL
      THEN
         x_error_code_temp :=
             is_payment_method_code_valid (p_cnv_hdr_rec.payment_method_code);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.pay_awt_group_name IS NOT NULL
      THEN
         x_error_code_temp :=
                 is_pay_awt_grp_name_valid (p_cnv_hdr_rec.pay_awt_group_name);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.accts_pay_code_comb_value IS NOT NULL
      THEN
         x_error_code_temp :=
            is_accts_pay_cc_valid
                                 (p_cnv_hdr_rec.accts_pay_code_comb_value,
                                  p_cnv_hdr_rec.accts_pay_code_combination_id
                                 );
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

      IF p_cnv_hdr_rec.prepay_code_comb_value IS NOT NULL
      THEN
         x_error_code_temp :=
            is_accts_pay_cc_valid (p_cnv_hdr_rec.prepay_code_comb_value,
                                   p_cnv_hdr_rec.prepay_code_combination_id
                                  );
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;
      --Added as per Wave1 22-OCT-13
      IF p_cnv_hdr_rec.vat_registration_num IS NOT NULL
      THEN
         x_error_code_temp :=
            is_vat_reg_num_duplicate (p_cnv_hdr_rec.vat_registration_num,
                                      p_cnv_hdr_rec.batch_id,
                                      p_cnv_hdr_rec.record_number
                                     );
         x_error_code := find_max (x_error_code, x_error_code_temp);
      END IF;

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
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Completed Data-Validations'
                              );
   END data_validations;

   FUNCTION data_derivations (
      p_cnv_pre_std_hdr_rec   IN OUT   xx_ap_sup_conversion_pkg.g_xx_sup_cnv_pre_std_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Data-derivations');
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Completed Data-derivations'
                           );
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

END xx_ap_sup_cnv_validations_pkg;
/


GRANT EXECUTE ON APPS.XX_AP_SUP_CNV_VALIDATIONS_PKG TO INTG_XX_NONHR_RO;
