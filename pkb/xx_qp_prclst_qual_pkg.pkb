DROP PACKAGE BODY APPS.XX_QP_PRCLST_QUAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xx_qp_prclst_qual_pkg
AS
----------------------------------------------------------------------
/*
Created By : IBM Development Team
Creation Date : 11-Jun-2013
File Name : XXQPPRICLSTQUAL.pks
Description : This script creates the body of the package xx_qp_prclst_qual_pkg
Change History:
Version Date Name Remarks
------- ----------- -------- -------------------------------
1.0 11-Sep-2013 IBM Development Team Initial development.
*/
----------------------------------------------------------------------

   FUNCTION main (
      p_list_type         IN   VARCHAR2,
      p_list_name         IN   VARCHAR2,
      p_grouping_number   IN   VARCHAR2,
      p_operator          IN   VARCHAR2,
      p_customer_number   IN   VARCHAR2,
      p_customer_name     IN   VARCHAR2,
      p_start_date        IN   DATE,
      p_end_date          IN   DATE,
      p_precedence        IN   VARCHAR2,
      p_record_type       IN   VARCHAR2
   )
      RETURN VARCHAR
   IS
      l_control_rec                qp_globals.control_rec_type;
      l_return_status              VARCHAR2 (1);
      x_msg_count                  NUMBER;
      x_msg_data                   VARCHAR2 (2000);
      x_msg_index                  NUMBER;
      x_error_msg                  VARCHAR2 (2000);
      l_cust_id                    hz_cust_accounts_all.cust_account_id%TYPE;
      l_cust_name                  hz_cust_accounts_all.account_name%TYPE;
      l_grp_nmber                  VARCHAR2 (100);
      l_precedence                 VARCHAR2 (100);
      l_list_header_id             NUMBER;
      l_qual_id                    NUMBER;
      l_qual_seg                   VARCHAR2 (100);
      l_strt_dt                    DATE;
      l_end_dt                     DATE;
      l_modifier_list_rec          qp_modifiers_pub.modifier_list_rec_type;
      l_modifier_list_val_rec      qp_modifiers_pub.modifier_list_val_rec_type;
      l_modifiers_tbl              qp_modifiers_pub.modifiers_tbl_type;
      l_modifiers_val_tbl          qp_modifiers_pub.modifiers_val_tbl_type;
      l_qualifiers_tbl             qp_qualifier_rules_pub.qualifiers_tbl_type;
      l_qualifiers_val_tbl         qp_qualifier_rules_pub.qualifiers_val_tbl_type;
      l_pricing_attr_tbl           qp_modifiers_pub.pricing_attr_tbl_type;
      l_pricing_attr_val_tbl       qp_modifiers_pub.pricing_attr_val_tbl_type;
      l_x_modifier_list_rec        qp_modifiers_pub.modifier_list_rec_type;
      l_x_modifier_list_val_rec    qp_modifiers_pub.modifier_list_val_rec_type;
      l_x_modifiers_tbl            qp_modifiers_pub.modifiers_tbl_type;
      l_x_modifiers_val_tbl        qp_modifiers_pub.modifiers_val_tbl_type;
      l_x_qualifiers_tbl           qp_qualifier_rules_pub.qualifiers_tbl_type;
      l_x_qualifiers_val_tbl       qp_qualifier_rules_pub.qualifiers_val_tbl_type;
      l_x_pricing_attr_tbl         qp_modifiers_pub.pricing_attr_tbl_type;
      l_x_pricing_attr_val_tbl     qp_modifiers_pub.pricing_attr_val_tbl_type;
      l_qualifier_rules_rec        qp_qualifier_rules_pub.qualifier_rules_rec_type;
      lx_qualifier_rules_rec       qp_qualifier_rules_pub.qualifier_rules_rec_type;
      l_qualifier_rules_val_rec    qp_qualifier_rules_pub.qualifier_rules_val_rec_type;
      lx_qualifier_rules_val_rec   qp_qualifier_rules_pub.qualifier_rules_val_rec_type;
   BEGIN
      x_error_msg := NULL;

      IF p_list_name IS NULL
      THEN
         x_error_msg := 'Error: List Name cannot be null. ';
      END IF;

      IF p_customer_number IS NULL AND p_customer_name IS NULL
      THEN
         x_error_msg :=
               x_error_msg
            || 'Error: Both customer name and number cannot be null';
      END IF;



      IF p_customer_name IS NOT NULL
      THEN
         BEGIN
            SELECT cust_account_id, account_name
              INTO l_cust_id, l_cust_name
              FROM hz_cust_accounts_all
             WHERE account_name = p_customer_name;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_cust_id := NULL;
            WHEN OTHERS
            THEN
               x_error_msg :=
                     x_error_msg
                  || 'Error: Customer could not be fetched from name'
                  || SQLERRM;
         END;
      END IF;

      IF l_cust_id IS NULL AND p_customer_number IS NOT NULL
      THEN
         BEGIN
            SELECT cust_account_id, account_name
              INTO l_cust_id, l_cust_name
              FROM hz_cust_accounts_all
             WHERE account_number = p_customer_number;
         EXCEPTION
            WHEN OTHERS
            THEN
               x_error_msg :=
                     x_error_msg
                  || 'Error: Customer could not be fetched from customer number.'
                  || SQLERRM;
         END;
      END IF;

      IF l_cust_id IS NULL
      THEN
         x_error_msg :=
                       x_error_msg || 'Error: Customer could not be fetched.';
      END IF;

      IF p_grouping_number IS NULL AND p_record_type = 'NEW'
      THEN
         BEGIN
            SELECT attribute3
              INTO l_grp_nmber
              FROM fnd_lookup_values
             WHERE lookup_type = 'INTG_MASS_UPLOAD_DEFAULTS'
               AND lookup_code = 'QUALIFIER'
               AND LANGUAGE = USERENV ('LANG');
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_grp_nmber := NULL;
            WHEN OTHERS
            THEN
               x_error_msg :=
                     x_error_msg
                  || 'Error: Could not fetch grouping number.'
                  || SQLCODE
                  || SQLERRM;
         END;
      ELSE
         l_grp_nmber := p_grouping_number;
      END IF;

      IF p_precedence IS NULL AND p_record_type = 'NEW'
      THEN
         BEGIN
            SELECT attribute2
              INTO l_precedence
              FROM fnd_lookup_values
             WHERE lookup_type = 'INTG_MASS_UPLOAD_DEFAULTS'
               AND lookup_code = 'QUALIFIER'
               AND LANGUAGE = USERENV ('LANG');
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_precedence := NULL;
            WHEN OTHERS
            THEN
               x_error_msg :=
                     x_error_msg
                  || 'Error: Could not fetch precedence.'
                  || SQLCODE
                  || SQLERRM;
         END;
      ELSE
         l_precedence := p_precedence;
      END IF;

      BEGIN
         SELECT qsb.segment_mapping_column
           INTO l_qual_seg
           FROM qp_prc_contexts_b qpc, qp_segments_b qsb, qp_segments_tl qst
          WHERE qpc.prc_context_id = qsb.prc_context_id
            AND qsb.segment_id = qst.segment_id
            AND qst.LANGUAGE = USERENV ('LANG')
            AND UPPER (qpc.prc_context_code) = 'CUSTOMER'
            AND UPPER (user_segment_name) = 'CUSTOMER NAME';
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_msg :=
                  x_error_msg
               || 'Error: Could not qualifier mapping.'
               || SQLCODE
               || SQLERRM;
      END;

      IF p_operator NOT IN ('=', 'NOT =')   --<> '=' AND p_operator <> 'NOT ='
      THEN
         x_error_msg :=
                     x_error_msg || 'Error: Operator can be only = or NOT = ';
      END IF;

      BEGIN
         IF UPPER (p_list_type) = 'PRICE LIST'
         THEN
            SELECT list_header_id, start_date_active, end_date_active
              INTO l_list_header_id, l_strt_dt, l_end_dt
              FROM qp_list_headers_all
             WHERE NAME = p_list_name   --Added by DR
               AND list_type_code = 'PRL'; --Added by DR
         ELSIF UPPER (p_list_type) = 'DISCOUNT LIST'
         THEN
            SELECT list_header_id, start_date_active, end_date_active
              INTO l_list_header_id, l_strt_dt, l_end_dt
              FROM qpbv_modifier_headers
             --WHERE UPPER (NAME) = p_list_name;            --UPPER causes more than one record to be returned
			  WHERE NAME = p_list_name;                     --Modified on 18-Feb-14
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_msg :=
                  x_error_msg
               || 'Error: List name could not be found for creating new qualifier. '
               || SQLCODE
               || SQLERRM;
      END;

       IF p_end_date < p_start_date OR p_end_date < l_strt_dt
            THEN
               x_error_msg :=
                     x_error_msg
                  || 'Error: End Date cannot be past date or less than start date.';
      END IF;

/*      IF p_start_date IS NULL AND p_record_type = 'NEW'
      THEN
         x_error_msg :=
            x_error_msg || 'Error: Start Date cannot be null for NEW records';                  --Modified on 18-Feb-14
      END IF;
*/
      IF    (l_strt_dt IS NOT NULL AND p_start_date < l_strt_dt)
         OR (l_end_dt IS NOT NULL AND p_end_date > l_end_dt)
      THEN
         x_error_msg :=
            x_error_msg || 'Error: Line date range is outside List Header date range.';
      END IF;

 --     DBMS_OUTPUT.put_line ('before loop:' || x_error_msg);

      IF x_error_msg IS NULL       -- If there are errors then do not call API
      THEN
-- Derive Price List Name
         IF p_record_type = 'NEW' AND UPPER (p_list_type) = 'DISCOUNT LIST'
         THEN
--            DBMS_OUTPUT.put_line ('Inside 1');

-- API Call
            BEGIN
-- Create new qualifier for existing modifier
/* update Modifier information */
               l_modifier_list_rec.list_header_id := l_list_header_id;
               l_modifier_list_rec.operation := qp_globals.g_opr_update;
/* Create a Qualifier Record at header level */
               l_qualifiers_tbl (1).excluder_flag := 'N';
               l_qualifiers_tbl (1).comparison_operator_code := '=';
               l_qualifiers_tbl (1).qualifier_context := 'CUSTOMER';
               l_qualifiers_tbl (1).qualifier_attribute := l_qual_seg;
--'QUALIFIER_ATTRIBUTE2';
               l_qualifiers_tbl (1).qualifier_attr_value := l_cust_id;
               l_qualifiers_tbl (1).start_date_active := p_start_date;
/*
               IF l_grp_nmber IS NULL
               THEN
                  l_qualifiers_tbl (1).qualifier_grouping_no := -1;
               ELSE
                  l_qualifiers_tbl (1).qualifier_grouping_no := l_grp_nmber;
               END IF;

               IF l_precedence IS NULL
               THEN
                  l_qualifiers_tbl (1).qualifier_precedence := 1;
               ELSE
                  l_qualifiers_tbl (1).qualifier_precedence := l_precedence;
               END IF;
              */
              IF l_grp_nmber IS NOT NULL
	                     THEN
	                      l_qualifiers_tbl (1).qualifier_grouping_no := l_grp_nmber;
	                     END IF;

	                     IF l_precedence IS NOT NULL
	      	                      THEN
	      	        l_qualifiers_tbl (1).qualifier_precedence := l_precedence;
               END IF;

               l_qualifiers_tbl (1).operation := qp_globals.g_opr_create;
/* Call the Modifiers Public API to update the modifier header, with qualifier information provided */
               qp_modifiers_pub.process_modifiers
                        (p_api_version_number         => 1.0,
                         p_init_msg_list              => fnd_api.g_false,
                         p_return_values              => fnd_api.g_false,
                         p_commit                     => fnd_api.g_false,
                         x_return_status              => l_return_status,
                         x_msg_count                  => x_msg_count,
                         x_msg_data                   => x_msg_data,
                         p_modifier_list_rec          => l_modifier_list_rec,
                         p_modifiers_tbl              => l_modifiers_tbl,
                         p_qualifiers_tbl             => l_qualifiers_tbl,
                         p_pricing_attr_tbl           => l_pricing_attr_tbl,
                         x_modifier_list_rec          => l_x_modifier_list_rec,
                         x_modifier_list_val_rec      => l_x_modifier_list_val_rec,
                         x_modifiers_tbl              => l_x_modifiers_tbl,
                         x_modifiers_val_tbl          => l_x_modifiers_val_tbl,
                         x_qualifiers_tbl             => l_x_qualifiers_tbl,
                         x_qualifiers_val_tbl         => l_x_qualifiers_val_tbl,
                         x_pricing_attr_tbl           => l_x_pricing_attr_tbl,
                         x_pricing_attr_val_tbl       => l_x_pricing_attr_val_tbl
                        );

                        DBMS_OUTPUT.put_line ('Inside 1 l_return_status'||l_return_status);

               IF l_return_status <> fnd_api.g_ret_sts_success
               THEN
                  RAISE fnd_api.g_exc_unexpected_error;
               END IF;
            EXCEPTION
               WHEN fnd_api.g_exc_error
               THEN
                  l_return_status := fnd_api.g_ret_sts_error;
                  ROLLBACK;
-- Get message count and data
--dbms_output.put_line('err msg is : ' || x_msg_data);
                  x_error_msg :=
                       x_error_msg || 'API Error1 in API call1' || x_msg_data;
               WHEN fnd_api.g_exc_unexpected_error
               THEN
                  l_return_status := fnd_api.g_ret_sts_unexp_error;
                  ROLLBACK;

                  FOR k IN 1 .. x_msg_count
                  LOOP
-- Get message count and data
                     x_msg_data :=
                          oe_msg_pub.get (p_msg_index      => k,
                                          p_encoded        => 'F');
 --                    DBMS_OUTPUT.put_line (   'err msg '
 --                                          || k
 --                                          || 'is: '
 --                                          || x_msg_data
 --                                         );
                  END LOOP;

                  x_error_msg :=
                        x_error_msg || 'API Error2 in API call1' || x_msg_data;
               WHEN OTHERS
               THEN
                  l_return_status := fnd_api.g_ret_sts_unexp_error;
                  ROLLBACK;

                  FOR k IN 1 .. x_msg_count
                  LOOP
                     x_msg_data :=
                          oe_msg_pub.get (p_msg_index      => k,
                                          p_encoded        => 'F');
-- Get message count and data
--dbms_output.put_line('err msg ' || k ||'is: ' || x_msg_data);
                  END LOOP;

                  x_error_msg :=
                        x_error_msg || 'API Error3 in API call1' || x_msg_data;
            END;
--            DBMS_OUTPUT.put_line ('Inside 1 x_error_msg'||x_error_msg);
         ELSIF     p_record_type = 'UPDATE'
               AND UPPER (p_list_type) = 'DISCOUNT LIST'
         THEN
--            DBMS_OUTPUT.put_line ('Inside 2'||l_list_header_id||'cust ID'||l_cust_id);

-- update_row;
            BEGIN
               BEGIN
                  SELECT qualifier_id
                    INTO l_qual_id
                    FROM qp_qualifiers
                   WHERE list_header_id = l_list_header_id
                     AND qualifier_attr_value = TO_CHAR(l_cust_id)                           --Modified on 18-Feb-14
                     AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE - 1)
                                     AND NVL (end_date_active, SYSDATE + 1);
               EXCEPTION
                  WHEN TOO_MANY_ROWS
                  THEN
                     l_qual_id := NULL;
                     x_error_msg :=
                           x_error_msg
                        || 'Could not fetch existing qualifier for update as there are more than one active rows for same customer:'
                        || SQLERRM;
                  WHEN NO_DATA_FOUND
                  THEN
                     l_qual_id := NULL;
                     x_error_msg :=
                           x_error_msg
                        || 'Could not find existing qualifier for update due to error:'
                        || SQLERRM;

						WHEN OTHERS
                  THEN
                     l_qual_id := NULL;
                     x_error_msg :=
                           x_error_msg
                        || 'Could not fetch existing qualifier for update due to error:'
                        || SQLERRM;
               END;

--               DBMS_OUTPUT.put_line ('Inside 2 Start update1 '||l_qual_id);

               IF l_qual_id IS NOT NULL
               THEN
--               DBMS_OUTPUT.put_line ('Inside 2 Start update1 '||l_qual_id);
-- Update qualifier for existing modifier
/* update Modifier information */
                  l_modifier_list_rec.list_header_id := l_list_header_id;
                  l_modifier_list_rec.operation := qp_globals.g_opr_update;
/* Create a Qualifier Record at header level */

                  l_qualifiers_tbl (1).operation := qp_globals.g_opr_update;
                  l_qualifiers_tbl (1).qualifier_id := l_qual_id;
                  l_qualifiers_tbl (1).end_date_active := p_end_date;
/* Call the Modifiers Public API to update the modifier header, with qualifier information provided */
                  qp_modifiers_pub.process_modifiers
                        (p_api_version_number         => 1.0,
                         p_init_msg_list              => fnd_api.g_false,
                         p_return_values              => fnd_api.g_false,
                         p_commit                     => fnd_api.g_false,
                         x_return_status              => l_return_status,
                         x_msg_count                  => x_msg_count,
                         x_msg_data                   => x_msg_data,
                         p_pricing_attr_tbl           => l_pricing_attr_tbl,
                         p_modifier_list_rec          => l_modifier_list_rec,
                         p_modifiers_tbl              => l_modifiers_tbl,
                         p_qualifiers_tbl             => l_qualifiers_tbl,
                         x_modifier_list_rec          => l_x_modifier_list_rec,
                         x_modifier_list_val_rec      => l_x_modifier_list_val_rec,
                         x_modifiers_tbl              => l_x_modifiers_tbl,
                         x_modifiers_val_tbl          => l_x_modifiers_val_tbl,
                         x_qualifiers_tbl             => l_x_qualifiers_tbl,
                         x_qualifiers_val_tbl         => l_x_qualifiers_val_tbl,
                         x_pricing_attr_tbl           => l_x_pricing_attr_tbl,
                         x_pricing_attr_val_tbl       => l_x_pricing_attr_val_tbl
                        );
--             DBMS_OUTPUT.put_line ('Inside 2 Start update '||l_return_status);
                  IF l_return_status <> fnd_api.g_ret_sts_success
                  THEN
                     RAISE fnd_api.g_exc_unexpected_error;
                     ELSE
                     COMMIT;
                  END IF;
               END IF;
            EXCEPTION
               WHEN fnd_api.g_exc_error
               THEN
                  l_return_status := fnd_api.g_ret_sts_error;
                  ROLLBACK;
-- Get message count and data
--dbms_output.put_line('err msg is : ' || x_msg_data);
                  x_error_msg :=
                       x_error_msg || 'API Error1 in API call2' || x_msg_data;
               WHEN fnd_api.g_exc_unexpected_error
               THEN
                  l_return_status := fnd_api.g_ret_sts_unexp_error;
                  ROLLBACK;

                  FOR k IN 1 .. x_msg_count
                  LOOP
                     x_msg_data :=
                          oe_msg_pub.get (p_msg_index      => k,
                                          p_encoded        => 'F');
-- Get message count and data
--dbms_output.put_line('err msg ' || k ||'is: ' || x_msg_data);
                  END LOOP;

                  x_error_msg :=
                        x_error_msg || 'API Error2 in API call2' || x_msg_data;
               WHEN OTHERS
               THEN
                  l_return_status := fnd_api.g_ret_sts_unexp_error;
                  ROLLBACK;

                  FOR k IN 1 .. x_msg_count
                  LOOP
                     x_msg_data :=
                          oe_msg_pub.get (p_msg_index      => k,
                                          p_encoded        => 'F');
-- Get message count and data
--dbms_output.put_line('err msg ' || k ||'is: ' || x_msg_data);
                  END LOOP;

                  x_error_msg :=
                        x_error_msg || 'API Error3 in API call3' || x_msg_data;
            END;
         ELSIF p_record_type = 'NEW' AND UPPER (p_list_type) = 'PRICE LIST'
         THEN
            DBMS_OUTPUT.put_line ('Inside 3');

            BEGIN
/* Create a Qualifier Record at header level */
               l_qualifiers_tbl (1).list_header_id := l_list_header_id;
                                         --350828;--83155;--l_list_header_id;
               l_qualifiers_tbl (1).excluder_flag := 'N';
               l_qualifiers_tbl (1).comparison_operator_code := '=';
               l_qualifiers_tbl (1).qualifier_context := 'CUSTOMER';
               l_qualifiers_tbl (1).qualifier_attribute :=
                                                       'QUALIFIER_ATTRIBUTE2';
               l_qualifiers_tbl (1).qualifier_attr_value := l_cust_id;
               l_qualifiers_tbl (1).start_date_active := p_start_date;
--               DBMS_OUTPUT.put_line ('l_grp_nmber' || l_grp_nmber);

            /*   IF l_grp_nmber IS NULL
               THEN
                  l_qualifiers_tbl (1).qualifier_grouping_no := -1;
               ELSE
                  l_qualifiers_tbl (1).qualifier_grouping_no := l_grp_nmber;
               END IF;

               IF l_precedence IS NULL
               THEN
                  l_qualifiers_tbl (1).qualifier_precedence := 1;
               ELSE
                  l_qualifiers_tbl (1).qualifier_precedence := l_precedence;
               END IF;
               */

               IF l_grp_nmber IS NOT NULL
	                      THEN
	                       l_qualifiers_tbl (1).qualifier_grouping_no := l_grp_nmber;
	                      END IF;

	                      IF l_precedence IS NOT NULL
	       	                      THEN
	       	        l_qualifiers_tbl (1).qualifier_precedence := l_precedence;
               END IF;

               l_qualifiers_tbl (1).operation := qp_globals.g_opr_create;
               qp_qualifier_rules_pub.process_qualifier_rules
                     (p_api_version_number           => 1.0,
                      p_init_msg_list                => fnd_api.g_false,
                      p_return_values                => fnd_api.g_false,
                      p_commit                       => fnd_api.g_false,
                      x_return_status                => l_return_status,
                      x_msg_count                    => x_msg_count,
                      x_msg_data                     => x_msg_data,
                      p_qualifier_rules_rec          => l_qualifier_rules_rec,
                      p_qualifier_rules_val_rec      => l_qualifier_rules_val_rec,
                      x_qualifier_rules_val_rec      => lx_qualifier_rules_val_rec,
                      p_qualifiers_tbl               => l_qualifiers_tbl,
                      p_qualifiers_val_tbl           => l_qualifiers_val_tbl,
                      x_qualifier_rules_rec          => lx_qualifier_rules_rec,
                      x_qualifiers_tbl               => l_x_qualifiers_tbl,
                      x_qualifiers_val_tbl           => l_x_qualifiers_val_tbl
                     );
--               DBMS_OUTPUT.put_line ('1eror err msg is: ' || l_return_status);

               IF l_return_status = fnd_api.g_ret_sts_success
               THEN
                  COMMIT;
--                 DBMS_OUTPUT.put_line ('2eror err msg is: '
--                                       || l_return_status
--                                      );
               ELSE
                  ROLLBACK;
--                  DBMS_OUTPUT.put_line ('eror err msg is: ' || l_return_status
--                                       );
--dbms_output.put_line('Error is '|| x_msg_data ||' - ' || x_msg_count);
                  x_error_msg :=
                        x_error_msg || 'API Error1 in API call3' || x_msg_data;

                  FOR i IN 1 .. x_msg_count
                  LOOP
                     x_msg_data :=
                          oe_msg_pub.get (p_msg_index      => i,
                                          p_encoded        => 'F');
--                     DBMS_OUTPUT.put_line (   'err msg '
--                                           || i
--                                           || 'is: '
--                                           || x_msg_data
--                                          );
                  END LOOP;

                  x_error_msg :=
                        x_error_msg || 'API Error2 in API call3' || x_msg_data;
               END IF;
            END;
         ELSIF p_record_type = 'UPDATE' AND UPPER (p_list_type) = 'PRICE LIST'
         THEN
--            DBMS_OUTPUT.put_line ('Inside 4');

            BEGIN
               SELECT qualifier_id
                 INTO l_qual_id
                 FROM qp_qualifiers
                WHERE list_header_id = l_list_header_id
                  AND qualifier_attr_value = TO_CHAR(l_cust_id)                          --Modified on 18-Feb-14
                  AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE - 1)
                                  AND NVL (end_date_active, SYSDATE + 1);
            EXCEPTION
               WHEN TOO_MANY_ROWS
               THEN
                  l_qual_id:= NULL;
                  x_error_msg :=
                        x_error_msg
                     || 'Could not fetch existing qualifier for update as there are more than one active rows for same customer:'
                     || SQLERRM;
               WHEN OTHERS
               THEN
                  l_qual_id:= NULL;
                  x_error_msg :=
                        x_error_msg
                     || 'Could not fetch existing qualifier for update due to error:'
                     || SQLERRM;
            END;

         IF l_qual_id IS NOT NULL
         THEN
--          DBMS_OUTPUT.put_line ('Inside 4 Start update');

            BEGIN
/* Create a Qualifier Record at header level */

               l_qualifiers_tbl (1).list_header_id := l_list_header_id;
               l_qualifiers_tbl (1).qualifier_id := l_qual_id;
               l_qualifiers_tbl (1).end_date_active := p_end_date;
               l_qualifiers_tbl (1).operation := qp_globals.g_opr_update;
               qp_qualifier_rules_pub.process_qualifier_rules
                     (p_api_version_number           => 1.0,
                      p_init_msg_list                => fnd_api.g_false,
                      p_return_values                => fnd_api.g_false,
                      p_commit                       => fnd_api.g_false,
                      x_return_status                => l_return_status,
                      x_msg_count                    => x_msg_count,
                      x_msg_data                     => x_msg_data,
                      p_qualifier_rules_rec          => l_qualifier_rules_rec,
                      p_qualifier_rules_val_rec      => l_qualifier_rules_val_rec,
                      p_qualifiers_tbl               => l_qualifiers_tbl,
                      p_qualifiers_val_tbl           => l_qualifiers_val_tbl,
                      x_qualifier_rules_rec          => lx_qualifier_rules_rec,
                      x_qualifier_rules_val_rec      => lx_qualifier_rules_val_rec,
                      x_qualifiers_tbl               => l_x_qualifiers_tbl,
                      x_qualifiers_val_tbl           => l_x_qualifiers_val_tbl
                     );

--                      DBMS_OUTPUT.put_line ('Inside 4 **** '||l_return_status);

               IF l_return_status = fnd_api.g_ret_sts_success
               THEN
                  COMMIT;
--                  DBMS_OUTPUT.put_line ('Inside 4 - '||l_return_status);

               ELSE
                  ROLLBACK;

-- dbms_output.put_line('Error is '|| x_msg_data ||' - ' || x_msg_count);
                  x_error_msg :=
                       x_error_msg || 'API Error1 in API call4' || x_msg_data;

                  FOR i IN 1 .. x_msg_count
                  LOOP
                     x_msg_data :=
                          oe_msg_pub.get (p_msg_index      => i,
                                          p_encoded        => 'F');
-- dbms_output.put_line('err msg ' || i ||'is: ' || x_msg_data);
                  END LOOP;
--                  DBMS_OUTPUT.put_line ('Inside 4 err'||x_error_msg);

                  x_error_msg :=
                        x_error_msg || 'API Error2 in API call4' || x_msg_data;
               END IF;
            END;
            END IF; -- l_qual_id IS NULL
         END IF;
      END IF;

      IF x_error_msg IS NOT NULL
      THEN
         COMMIT;
         RETURN x_error_msg;

      END IF;
        RETURN x_error_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_error_msg := x_error_msg || SQLERRM;
         RETURN x_error_msg;
   END main;

END;
/
