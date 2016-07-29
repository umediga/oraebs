DROP PACKAGE BODY APPS.XX_ASO_GROSS_MARGIN_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_ASO_GROSS_MARGIN_PKG" 
----------------------------------------------------------------------
/* $Header: XXASOGROSSMARGIN.pkb 1.0 2012/04/02 12:00:00 dparida noship $ */
/*
 Created By    : IBM Development Team
 Creation Date : 28-Apr-2012
 File Name     : XXASOGROSSMARGIN.pks
 Description   : This script creates the body of the package
                 xx_aso_gross_margin_pkg
 Change History:
 Date         Name                   Remarks
 -----------  -------------          -----------------------------------
 28-Apr-2012  IBM Development Team   Initial Draft.
*/
----------------------------------------------------------------------
AS
-- =================================================================================
-- Name           : xx_aso_grossmargin_header_calc
-- Description    : This Function Will Invoked From The HTML Quoting AM Class
--                  This will calculate the gross margin of all the product at line
--                  level and return the same to the AM Class.
-- Parameters description       :
--
-- p_quote_hdr_id  : Parameter To Store Quote Header ID (IN)
-- p_org_id        : Parameter To Org ID (IN)
-- ==============================================================================
   FUNCTION xx_aso_grossmargin_header_calc (
      p_quote_hdr_id   NUMBER,
      p_org_id         NUMBER
   )
      RETURN VARCHAR2
   IS
      x_unit_standard_price       VARCHAR2 (100) := NULL;
      x_unit_selling_price        VARCHAR2 (100) := NULL;
      x_tot_unit_standard_price   VARCHAR2 (100) := NULL;
      x_tot_unit_selling_price    VARCHAR2 (100) := NULL;
      x_tot_gross_line_margin     VARCHAR2 (100) := NULL;
      x_inventory_item_id         NUMBER;
      x_conversion_rate           NUMBER;

      CURSOR c_quote_item_details (cp_quote_hdr_id NUMBER, cp_org_id NUMBER)
      IS
         SELECT aqlq.inventory_item_id,
                NVL (aqs.ship_from_org_id, aqlq.org_id) ship_from_org_id,
                aqlq.quantity, aqlq.line_quote_price, aqha.org_id,
                aqha.currency_code, aqha.creation_date,
                (SELECT gl.currency_code
                   FROM financials_system_params_all fspa,
                        gl_ledgers gl
                  WHERE fspa.org_id = aqha.org_id
                    AND fspa.set_of_books_id = gl.ledger_id) func_curr_code,
                (SELECT gl.period_end_rate_type
                   FROM financials_system_params_all fspa,
                        gl_ledgers gl
                  WHERE fspa.org_id = aqha.org_id
                    AND fspa.set_of_books_id = gl.ledger_id) rate_conv_type
           FROM aso_quote_lines_all aqlq,
                aso_shipments aqs,
                aso_quote_headers_all aqha
          WHERE aqlq.org_id = cp_org_id
            AND aqlq.quote_header_id = cp_quote_hdr_id
            AND aqlq.quote_header_id = aqs.quote_header_id
            AND aqlq.quote_header_id = aqha.quote_header_id
            AND aqha.org_id = cp_org_id
            AND aqs.quote_line_id = aqlq.quote_line_id
            AND aqlq.attribute2 is not null;
   BEGIN
      FOR r_quote_item_details IN c_quote_item_details (p_quote_hdr_id,
                                                        p_org_id
                                                       )
      LOOP
         x_unit_standard_price := 0;
         x_unit_selling_price :=
              r_quote_item_details.line_quote_price
            * r_quote_item_details.quantity;

         /*Calculating Conversion Rate*/
         IF r_quote_item_details.currency_code =
                                           r_quote_item_details.func_curr_code
         THEN
            --- When both the currency are same
            x_conversion_rate := 1;
         ELSE
            --- When both the currency are different
            BEGIN
               SELECT conversion_rate
                 INTO x_conversion_rate
                 FROM gl_daily_rates
                WHERE from_currency = r_quote_item_details.func_curr_code
                  AND to_currency = r_quote_item_details.currency_code
                  AND conversion_date =
                                    TRUNC (r_quote_item_details.creation_date)
                  AND conversion_type = r_quote_item_details.rate_conv_type;
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_conversion_rate := 0;
            END;
         END IF;

         BEGIN
            SELECT NVL((  (MAX (NVL (item_cost, 0)) * x_conversion_rate)
                    * r_quote_item_details.quantity
                   ),0)
              INTO x_unit_standard_price
              FROM cst_item_cost_type_v
             WHERE inventory_item_id = r_quote_item_details.inventory_item_id
               AND cost_type =
                      xx_emf_pkg.get_paramater_value (g_process_name,
                                                      g_cost_type
                                                     )
               AND item_cost <> 0
               AND organization_id IN (
                      SELECT organization_id
                        FROM org_organization_definitions
                       WHERE operating_unit = p_org_id
                         AND disable_date IS NULL
                         AND inventory_enabled_flag = 'Y');
         -- GROUP BY inventory_item_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               x_unit_standard_price := 0;
            WHEN OTHERS
            THEN
               x_unit_standard_price := 0;
         END;


         x_tot_unit_standard_price :=
                     NVL (x_tot_unit_standard_price, 0)
                     + x_unit_standard_price;
         x_tot_unit_selling_price :=
                       NVL (x_tot_unit_selling_price, 0)
                       + x_unit_selling_price;
      END LOOP;


      x_tot_gross_line_margin :=
         ROUND ((  (  NVL (x_tot_unit_selling_price, 0)
                    - NVL (x_tot_unit_standard_price, 0)
                   )
                 / NVL (x_tot_unit_selling_price, 1)
                 * 100
                ),
                1
               );

      IF x_tot_unit_standard_price > 0
      THEN
         RETURN (x_tot_gross_line_margin);
      ELSE
         x_tot_gross_line_margin := '0.00';
         RETURN (x_tot_gross_line_margin);
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_tot_gross_line_margin := '0.00';
         RETURN x_tot_gross_line_margin;
      WHEN OTHERS
      THEN
         x_tot_gross_line_margin := '0.00';
         RETURN x_tot_gross_line_margin;
   END xx_aso_grossmargin_header_calc;

-- =================================================================================
-- Name           : xx_aso_grossmargin_line_calc
-- Description    : This Function Will Invoked From The HTML Quoting AM Class
--                  This will calculate the gross margin of the product and return
--                  the same to the AM Class.
-- Parameters description       :
--
-- p_quote_lnr_id  : Parameter To Store Quote Line ID (IN)
-- p_org_id        : Parameter To Org ID (IN)
-- p_quote_price   : Parameter To Store Unit Selling Price (IN)
-- ==============================================================================
   FUNCTION xx_aso_grossmargin_line_calc (
      p_quote_lnr_id   NUMBER,
      p_org_id         NUMBER,
      p_quote_price    NUMBER
   )
      RETURN VARCHAR2
   IS
      x_unit_standard_price   VARCHAR2 (100);
      x_unit_selling_price    VARCHAR2 (100);
      x_gross_line_margin     VARCHAR2 (100);
      x_inventory_item_id     NUMBER;
      x_conversion_rate       NUMBER;

      CURSOR c_quote_item_details (cp_quote_lnr_id NUMBER, cp_org_id NUMBER)
      IS
         SELECT aqlq.inventory_item_id,
                NVL (aqs.ship_from_org_id, aqlq.org_id) ship_from_org_id,
                aqlq.quantity, aqlq.line_quote_price, aqha.org_id,
                aqha.currency_code, aqha.creation_date,
                (SELECT gl.currency_code
                   FROM financials_system_params_all fspa,
                        gl_ledgers gl
                  WHERE fspa.org_id = aqha.org_id
                    AND fspa.set_of_books_id = gl.ledger_id) func_curr_code,
                (SELECT gl.period_end_rate_type
                   FROM financials_system_params_all fspa,
                        gl_ledgers gl
                  WHERE fspa.org_id = aqha.org_id
                    AND fspa.set_of_books_id = gl.ledger_id) rate_conv_type
           FROM aso_quote_lines_all aqlq,
                aso_shipments aqs,
                aso_quote_headers_all aqha
          WHERE aqlq.org_id = cp_org_id
            AND aqlq.quote_line_id = cp_quote_lnr_id
            AND aqlq.quote_header_id = aqs.quote_header_id
            AND aqlq.quote_header_id = aqha.quote_header_id
            AND aqha.org_id = cp_org_id
            AND aqs.quote_line_id = aqlq.quote_line_id;
   BEGIN
      FOR r_quote_item_details IN c_quote_item_details (p_quote_lnr_id,
                                                        p_org_id
                                                       )
      LOOP
         /*Calculating Conversion Rate*/
         IF r_quote_item_details.currency_code =
                                          r_quote_item_details.func_curr_code
         THEN
            --- When both the currency are same
            x_conversion_rate := 1;
         ELSE
            --- When both the currency are different
            BEGIN
               SELECT conversion_rate
                 INTO x_conversion_rate
                 FROM gl_daily_rates
                WHERE from_currency = r_quote_item_details.func_curr_code
                  AND to_currency = r_quote_item_details.currency_code
                  AND conversion_date =
                                    TRUNC (r_quote_item_details.creation_date)
                  AND conversion_type = r_quote_item_details.rate_conv_type;
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_conversion_rate := 0;
            END;
         END IF;

         BEGIN
            SELECT NVL((MAX (NVL (item_cost, 0)) * x_conversion_rate),0)
              INTO x_unit_standard_price
              FROM cst_item_cost_type_v
             WHERE inventory_item_id = r_quote_item_details.inventory_item_id
               AND cost_type =
                      xx_emf_pkg.get_paramater_value (g_process_name,
                                                      g_cost_type
                                                     )
               AND item_cost <> 0
               AND organization_id IN (
                      SELECT organization_id
                        FROM org_organization_definitions
                       WHERE operating_unit = p_org_id
                         AND disable_date IS NULL
                         AND inventory_enabled_flag = 'Y');
         -- GROUP BY inventory_item_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               x_unit_standard_price := 0;
         END;

         IF x_unit_standard_price > 0
         THEN
            x_unit_selling_price := p_quote_price;

            IF r_quote_item_details.ship_from_org_id IS NOT NULL
            THEN
               x_gross_line_margin :=
                  ROUND ((  (  NVL (x_unit_selling_price, 0)
                             - NVL (x_unit_standard_price, 0)
                            )
                          / NVL (x_unit_selling_price, 1)
                          * 100
                         ),
                         1
                        );
            ELSE
               x_gross_line_margin := Null;
            END IF;
         ELSE
            x_gross_line_margin := Null;
         END IF;
      END LOOP;

      RETURN (x_gross_line_margin);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_gross_line_margin := NULL;
         RETURN x_gross_line_margin;
      WHEN OTHERS
      THEN
         x_gross_line_margin := NULL;
         RETURN x_gross_line_margin;
   END xx_aso_grossmargin_line_calc;

-- =================================================================================
-- Name           : xx_aso_grossmargin_role
-- Description    : This Function Will Invoked From The HTML Quoting AM Class
--                  This will Verify whether the login user is eligable to View the
--                  gross margin field in the quote form.
-- Parameters description       :
--
-- p_user_name   : Parameter To Store Log In User Name (IN)
-- ==============================================================================
   FUNCTION xx_aso_grossmargin_role (p_user_name VARCHAR2)
      RETURN VARCHAR2
   IS
      x_user_role    VARCHAR2 (100);
      x_role_count   NUMBER;

      CURSOR c_user_role_flag (cp_user_name VARCHAR2)
      IS
         SELECT COUNT (*)
           FROM fnd_lookup_values flv
          WHERE flv.lookup_type =
                   xx_emf_pkg.get_paramater_value (g_process_name,
                                                   g_lookup_type
                                                  )
            AND UPPER(flv.meaning) IN (
                   SELECT UPPER(role_name)
                     FROM jtf_rs_defresources_v jrdv,
                          jtf_rs_defresroles_vl jrdv1
                    WHERE UPPER(jrdv.user_name) = UPPER(cp_user_name)
                      AND jrdv1.role_resource_id = jrdv.resource_id
                      AND SYSDATE BETWEEN NVL (jrdv.start_date_active,
                                               SYSDATE)
                                      AND NVL (jrdv.end_date_active, SYSDATE)
                      AND jrdv1.delete_flag = 'N')
            AND SYSDATE BETWEEN NVL (flv.start_date_active, SYSDATE)
                            AND NVL (flv.end_date_active, SYSDATE)
            AND flv.LANGUAGE = 'US'
            AND UPPER (flv.attribute1) =
                   UPPER (xx_emf_pkg.get_paramater_value (g_process_name,
                                                          g_role_flag
                                                         )
                         );
   BEGIN
      x_user_role := NULL;

      OPEN c_user_role_flag (p_user_name);

      FETCH c_user_role_flag
       INTO x_role_count;

      CLOSE c_user_role_flag;

      IF x_role_count > 0
      THEN
         x_user_role := 'Yes';
      ELSE
         x_user_role := 'No';
      END IF;

      RETURN x_user_role;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_user_role := 'No';
         RETURN x_user_role;
      WHEN OTHERS
      THEN
         x_user_role := 'No';
         RETURN x_user_role;
   END xx_aso_grossmargin_role;
END xx_aso_gross_margin_pkg;
/
