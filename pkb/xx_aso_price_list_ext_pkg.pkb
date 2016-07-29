DROP PACKAGE BODY APPS.XX_ASO_PRICE_LIST_EXT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_ASO_PRICE_LIST_EXT_PKG" AS
   ----------------------------------------------------------------------
/*
 Created By     : Partha
 Creation Date  : 24-JUL-2013
 File Name      : XXASOPRICELISTEXT.pkb
 Description    : This script creates the specification of the package xx_aso_price_list_ext_pkg


Change History:

Version Date          Name        Remarks
------- -----------   --------    -------------------------------
1.0     24-JUL-2013   Partha       Initial development.
2.0     07-APR-2014   Tushar       Quoting DRF Change.
*/
----------------------------------------------------------------------
   /**************************************************************************************
   *
   *   PROCEDURE
   *     assign_global_var
   *
   *   DESCRIPTION
   *   Assign Global Variables from Process Setup Parameter
   *
   *   PARAMETERS
   *   ==========
   *   NAME               TYPE             DESCRIPTION
   *   -----------------  --------         -----------------------------------------------
   *
   *   RETURN VALUE
   *   NA
   *
   *   PREREQUISITES
   *   NA
   *
   *   CALLED BY
   *   create_upd_price_list
   *
   **************************************************************************************/
   x_modifier_name                         VARCHAR2(1000);
   x_updt_modifier_flag                    VARCHAR2(1);
   x_send_mail                             VARCHAR2(1);
   PROCEDURE assign_global_var IS
   BEGIN
      --Get Territory Type from Process Setup Parameter
      g_jtf_terr_source := xx_emf_pkg.get_paramater_value(p_process_name   => g_process_name
                                                         ,p_parameter_name => 'JTF_TERR_SOURCE');
   EXCEPTION
      WHEN OTHERS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium
                             ,'Error while assigning global variables from process setup paramaeter' || 'Error: ' ||
                              SQLERRM);

   END assign_global_var;

   -- Send mail
   PROCEDURE send_mail(p_quote_header_id NUMBER)
    IS
      x_primary_em_addr  VARCHAR2(240)  := NULL;
      x_manager_em_addr  VARCHAR2(240)  := NULL;
      x_creator_em_addr  VARCHAR2(240)  := NULL;
      x_person_id        NUMBER(10)     := NULL;
      x_quote_name       VARCHAR2(500)  := NULL;
      x_quote_number     NUMBER         := NULL;
      x_acct_number      VARCHAR2(30)   := NULL;
      x_salesrep_name    VARCHAR2(240)  := NULL;
      x_party_name       VARCHAR2(500)  := NULL;
      x_msg_body         VARCHAR2(1000) := NULL;
      x_msg_sub          VARCHAR2(100)  := NULL;
      x_can_email        VARCHAR2(300)  := NULL;

    BEGIN

      -- get quote creator email address
      BEGIN
          SELECT papf.email_address
                  INTO x_creator_em_addr
               FROM per_all_people_f papf
                   ,aso_quote_headers_all aqha
                   ,fnd_user fu
               WHERE aqha.quote_header_id = p_quote_header_id
                 AND fu.user_id = aqha.created_by
                 AND fu.employee_id = papf.person_id;
        EXCEPTION
            WHEN OTHERS THEN
                 xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Unable to derive creator email  for quote ' || p_quote_header_id||' Error: ' ||SQLERRM);

                 x_creator_em_addr := NULL;
       END;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Derived creator email  for quote  ' || p_quote_header_id||':email :'||x_creator_em_addr);

      -- Get primary sales rep email address
      BEGIN
         SELECT papf.email_address , papf.person_id,papf.full_name
             INTO x_primary_em_addr,x_person_id,x_salesrep_name
          FROM per_all_people_f papf
              ,jtf_terr_rsc_all  jtra
              ,aso_quote_headers_all aqha
           WHERE aqha.quote_header_id = p_quote_header_id
              AND aqha.resource_id = jtra.resource_id
              AND jtra.person_id = papf.person_id;
      EXCEPTION
         WHEN OTHERS THEN
              xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Unable to derive primary sales rep email address for quote: ' || p_quote_header_id||' Error: ' ||SQLERRM);

              x_primary_em_addr := NULL;
      END;
             xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Derived primary sales rep email address for quote ' || p_quote_header_id||':email :'||x_primary_em_addr);

      -- Get primary sales rep managers email address

      BEGIN
          SELECT papf.email_address
                 INTO x_manager_em_addr
             FROM per_all_people_f papf
                 ,per_all_assignments_f  paaf
            WHERE paaf.supervisor_id = papf.person_id
              AND paaf.person_id = x_person_id
              AND (sysdate BETWEEN paaf.effective_start_date and paaf.effective_end_date);
      EXCEPTION
         WHEN OTHERS THEN
              xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Unable to derive manager email of primary sales rep for quote ' || p_quote_header_id||' Error: ' ||SQLERRM);

              x_manager_em_addr := NULL;
      END;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Derived manager email of primary sales rep for quote ' || p_quote_header_id||':email :'||x_manager_em_addr);

     -- get quote name , Number , party_name and account_number
     BEGIN
         SELECT aqha.quote_name,aqha.quote_number,hp.party_name,hca.account_number
           INTO x_quote_name,x_quote_number,x_party_name,x_acct_number
         FROM aso_quote_headers_all aqha
              ,hz_parties hp
              ,hz_cust_accounts_all hca
           WHERE aqha.quote_header_id = p_quote_header_id
             AND hp.party_id = hca.party_id
             AND hca.cust_account_id = aqha.cust_account_id;
     EXCEPTION
        WHEN OTHERS THEN
          NULL;
     END;

      x_can_email := x_creator_em_addr||'; '||x_primary_em_addr||'; '||x_manager_em_addr;

     -- Create subject
      x_msg_sub  := 'DRF created through Quote Number (quote number) processed successfully.';

      x_msg_body := 'This is to notify that the following Discount Request is successfully processed and pricing'
                        ||CHR(10)||' updates are made and available as requested.'
                        ||CHR(10)
                        ||CHR(10)
                        ||'Quote Name   : '||x_quote_name
                        ||CHR(10)
                        ||'Quote Number : '||x_quote_number
                        ||CHR(10)
                        ||'Customer     : '||x_party_name||'('||x_acct_number||')'
                        ||CHR(10)
                        ||'Sales Rep    : '||x_salesrep_name ;


      -- send mail procedure
      BEGIN
		       xx_intg_mail_util_pkg.mail (sender          => ' ',
                        						   recipients      => x_can_email,
                        						   subject         => x_msg_sub,
                        						   MESSAGE         => x_msg_body
                        						  );
		  EXCEPTION
		       WHEN OTHERS THEN
		          xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Error in sending mail(xx_intg_mail_util_pkg.mail) ' || ':Error : '||SQLERRM);

		  END;

   EXCEPTION
		       WHEN OTHERS THEN
		          xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Error in send_mail ' || ':Error : '||SQLERRM);


   END send_mail;


   --  get_start_dt_active
   FUNCTION get_start_dt_active(p_header_id  NUMBER
                               ,p_quote_date DATE
                               ,p_org_id     NUMBER)
            RETURN DATE

     IS
     x_apprv_date DATE := NULL;
    BEGIN

      BEGIN
         mo_global.SET_POLICY_CONTEXT('S',p_org_id);
      END;

      BEGIN
         SELECT end_date INTO x_apprv_date
            FROM aso_approval_instances_all_v
          WHERE quote_header_id = p_header_id
             AND object_type ='Quote'
             AND approval_status ='Approved';
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            RETURN (p_quote_date);
      END;
      IF  x_apprv_date IS NULL THEN
         RETURN(p_quote_date);
      END IF;

      IF( x_apprv_date > p_quote_date) THEN
          RETURN (x_apprv_date);
      ELSE
          RETURN (p_quote_date);
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium
                             ,'Error while deriving start_date_active' || 'Error: ' || SQLERRM);
        RETURN(NULL);
    END;

   -- Qualifier validation
   FUNCTION get_qualifiers_validated(p_party_id    IN VARCHAR2
                                    ,p_country     IN VARCHAR2
                                    ,p_county      IN VARCHAR2
                                    ,p_state       IN VARCHAR2
                                    ,p_postal_code IN VARCHAR2
                                    ,p_province    IN VARCHAR2
                                    ,p_city        IN VARCHAR2
                                    ,p_party_name  IN VARCHAR2
                                    ,p_rel_typ     IN VARCHAR2
                                    ,p_resource_id IN VARCHAR2) RETURN BOOLEAN IS
      x_process_flag BOOLEAN := FALSE;
      x_value_found  VARCHAR2(8);
      x_q1007_cp     VARCHAR2(2000);
      x_q1002_cp     VARCHAR2(2000);
      x_q1003_cp     VARCHAR2(2000);
      x_q1006_cp     VARCHAR2(2000);
      x_q1011_cp     VARCHAR2(2000);
      x_q1008_cp     VARCHAR2(2000);
      x_q1013_cp     VARCHAR2(2000);
      x_q1012_cp     VARCHAR2(2000);
      x_val_pass     VARCHAR2(10);

   BEGIN

      x_val_pass := 'Y';
      -- Checking For Column Validation
      BEGIN
               SELECT b.q1007_cp,b.q1002_cp,b.q1003_cp,b.q1006_cp,b.q1011_cp,b.q1008_cp,b.q1013_cp,b.q1012_cp
                 INTO x_q1007_cp,x_q1002_cp,x_q1003_cp,x_q1006_cp,x_q1011_cp,x_q1008_cp,x_q1013_cp,x_q1012_cp
                 FROM jty_1001_denorm_attr_values b
                WHERE b.source_id = -1001
                      AND b.trans_type_id = -1002
                      AND rownum < 2
                      AND exists (
                              select 1
                              FROM jtf_terr_all      jta
                                  ,jtf_terr_usgs_all jtu
                                  ,jtf_sources_all   jsa
                                  ,jtf_terr_rsc_all  jtr
                            WHERE jta.terr_id = jtu.terr_id
                                  AND jtu.source_id = jsa.source_id
                                  AND jsa.meaning = g_jtf_terr_source
                                  AND jtr.resource_id = p_resource_id
                                  AND jta.terr_id = jtr.terr_id
                                  AND jtr.terr_id = b.terr_id
                            );
      EXCEPTION
      WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'No Matching : '||SQLERRM);

            x_process_flag := FALSE;
            x_val_pass := 'N';
      END;

      -- Added for tkt# 002151
      --1 Party Name
      IF x_q1012_cp IS NOT NULL AND p_rel_typ = 'MAIN' AND x_q1007_cp IS NULL
      THEN
      BEGIN
         SELECT DISTINCT 'Yes'
           INTO x_value_found
           FROM jty_1001_denorm_attr_values b
          WHERE b.q1012_cp = '='
                AND b.q1012_low_value_char = p_party_name
                AND b.source_id = -1001
                AND b.trans_type_id = -1002
                AND exists (
                        select 1
                        FROM jtf_terr_all      jta
                            ,jtf_terr_usgs_all jtu
                            ,jtf_sources_all   jsa
                            ,jtf_terr_rsc_all  jtr
                      WHERE jta.terr_id = jtu.terr_id
                            AND jtu.source_id = jsa.source_id
                            AND jsa.meaning = g_jtf_terr_source
                            AND jtr.resource_id = p_resource_id
                            AND jta.terr_id = jtr.terr_id
                            AND jtr.terr_id = b.terr_id
                            );

        RETURN TRUE;
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Matching Party Name Range: '||SQLERRM);

            x_process_flag := FALSE;
            x_val_pass := 'N';
      END;
      ELSIF x_q1012_cp IS NOT NULL AND p_rel_typ <> 'MAIN' AND x_q1007_cp IS NULL
      THEN
        RETURN TRUE;
      END IF;

      -- Modified for tkt# 002151
      --2 Party Id
      IF x_q1002_cp IS NOT NULL AND p_rel_typ = 'MAIN' AND x_q1007_cp IS NULL
      THEN
      BEGIN
         SELECT DISTINCT 'Yes'
           INTO x_value_found
           FROM jty_1001_denorm_attr_values b
          WHERE b.q1002_cp = '='
                AND b.q1002_low_value_char_id = p_party_id
                AND b.source_id = -1001
                AND b.trans_type_id = -1002
                AND exists (
                        select 1
                        FROM jtf_terr_all      jta
                            ,jtf_terr_usgs_all jtu
                            ,jtf_sources_all   jsa
                            ,jtf_terr_rsc_all  jtr
                      WHERE jta.terr_id = jtu.terr_id
                            AND jtu.source_id = jsa.source_id
                            AND jsa.meaning = g_jtf_terr_source
                            AND jtr.resource_id = p_resource_id
                            AND jta.terr_id = jtr.terr_id
                            AND jtr.terr_id = b.terr_id
                            );

        RETURN TRUE;
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Matching Party Name : '||SQLERRM);

            x_process_flag := FALSE;
            x_val_pass := 'N';
      END;
      ELSIF x_q1002_cp IS NOT NULL AND p_rel_typ <> 'MAIN' AND x_q1007_cp IS NULL
      THEN
        RETURN TRUE;
      END IF;

      -- Modified for tkt# 002151
      --3 Postal Code
      IF x_q1007_cp IS NOT NULL AND x_q1012_cp IS NULL
      THEN
      BEGIN
         SELECT DISTINCT 'Yes'
           INTO x_value_found
           FROM jty_1001_denorm_attr_values b
          WHERE ((p_postal_code = b.q1007_low_value_char AND b.q1007_cp = '=') OR
                (p_postal_code LIKE b.q1007_low_value_char AND b.q1007_cp = 'LIKE') OR
                (b.q1007_cp = 'BETWEEN' AND p_postal_code BETWEEN b.q1007_low_value_char AND b.q1007_high_value_char))
                AND b.source_id = -1001
                AND b.trans_type_id = -1002
                AND exists (
                        select 1
                        FROM jtf_terr_all      jta
                            ,jtf_terr_usgs_all jtu
                            ,jtf_sources_all   jsa
                            ,jtf_terr_rsc_all  jtr
                      WHERE jta.terr_id = jtu.terr_id
                            AND jtu.source_id = jsa.source_id
                            AND jsa.meaning = g_jtf_terr_source
                            AND jtr.resource_id = p_resource_id
                            AND jta.terr_id = jtr.terr_id
                            AND jtr.terr_id = b.terr_id
                            );

         RETURN TRUE;

      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Matching Postal Code : '||SQLERRM);

            x_process_flag := FALSE;
            x_val_pass := 'N';
      END;
      END IF;

      /*
      --4 Country
      BEGIN
         SELECT DISTINCT 'Yes'
           INTO x_value_found
           FROM jty_1001_denorm_attr_values b
          WHERE b.q1003_cp = '='
                AND b.q1003_low_value_char = p_country
                AND b.source_id = -1001
                AND b.trans_type_id = -1002
                AND exists (
                        select 1
                        FROM jtf_terr_all      jta
                            ,jtf_terr_usgs_all jtu
                            ,jtf_sources_all   jsa
                            ,jtf_terr_rsc_all  jtr
                      WHERE jta.terr_id = jtu.terr_id
                            AND jtu.source_id = jsa.source_id
                            AND jsa.meaning = g_jtf_terr_source
                            AND jtr.resource_id = p_resource_id
                            AND jta.terr_id = jtr.terr_id
                            AND jtr.terr_id = b.terr_id
                            );

         RETURN TRUE;
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Matching Country Name : '||SQLERRM);

            x_process_flag := FALSE;
      END;

      --5 City
      BEGIN
         SELECT DISTINCT 'Yes'
           INTO x_value_found
           FROM jty_1001_denorm_attr_values b
          WHERE b.q1006_cp = '='
                AND b.q1006_low_value_char = p_city
                AND b.source_id = -1001
                AND b.trans_type_id = -1002
                AND exists (
                        select 1
                        FROM jtf_terr_all      jta
                            ,jtf_terr_usgs_all jtu
                            ,jtf_sources_all   jsa
                            ,jtf_terr_rsc_all  jtr
                      WHERE jta.terr_id = jtu.terr_id
                            AND jtu.source_id = jsa.source_id
                            AND jsa.meaning = g_jtf_terr_source
                            AND jtr.resource_id = p_resource_id
                            AND jta.terr_id = jtr.terr_id
                            AND jtr.terr_id = b.terr_id
                            );

         RETURN TRUE;
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Matching City Name : '||SQLERRM);

            x_process_flag := FALSE;
      END;

      --6 County
      BEGIN
         SELECT DISTINCT 'Yes'
           INTO x_value_found
           FROM jty_1001_denorm_attr_values b
          WHERE b.q1011_cp = '='
                AND b.q1011_low_value_char = p_county
                AND b.source_id = -1001
                AND b.trans_type_id = -1002
                AND exists (
                        select 1
                        FROM jtf_terr_all      jta
                            ,jtf_terr_usgs_all jtu
                            ,jtf_sources_all   jsa
                            ,jtf_terr_rsc_all  jtr
                      WHERE jta.terr_id = jtu.terr_id
                            AND jtu.source_id = jsa.source_id
                            AND jsa.meaning = g_jtf_terr_source
                            AND jtr.resource_id = p_resource_id
                            AND jta.terr_id = jtr.terr_id
                            AND jtr.terr_id = b.terr_id
                            );

        RETURN TRUE;
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Matching County Name : '||SQLERRM);

            x_process_flag := FALSE;
      END;

      --7 State
      BEGIN
         SELECT DISTINCT 'Yes'
           INTO x_value_found
           FROM jty_1001_denorm_attr_values b
          WHERE b.q1008_cp = '='
                AND b.q1008_low_value_char = p_state
                AND b.source_id = -1001
                AND b.trans_type_id = -1002
                AND exists (
                        select 1
                        FROM jtf_terr_all      jta
                            ,jtf_terr_usgs_all jtu
                            ,jtf_sources_all   jsa
                            ,jtf_terr_rsc_all  jtr
                      WHERE jta.terr_id = jtu.terr_id
                            AND jtu.source_id = jsa.source_id
                            AND jsa.meaning = g_jtf_terr_source
                            AND jtr.resource_id = p_resource_id
                            AND jta.terr_id = jtr.terr_id
                            AND jtr.terr_id = b.terr_id
                            );

         RETURN TRUE;
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Matching State Name : '||SQLERRM);

            x_process_flag := FALSE;
      END;

      --8 Province
      BEGIN
         SELECT DISTINCT 'Yes'
           INTO x_value_found
           FROM jty_1001_denorm_attr_values b
          WHERE b.q1013_cp = '='
                AND b.q1013_low_value_char = p_province
                AND b.source_id = -1001
                AND b.trans_type_id = -1002
                AND exists (
                        select 1
                        FROM jtf_terr_all      jta
                            ,jtf_terr_usgs_all jtu
                            ,jtf_sources_all   jsa
                            ,jtf_terr_rsc_all  jtr
                      WHERE jta.terr_id = jtu.terr_id
                            AND jtu.source_id = jsa.source_id
                            AND jsa.meaning = g_jtf_terr_source
                            AND jtr.resource_id = p_resource_id
                            AND jta.terr_id = jtr.terr_id
                            AND jtr.terr_id = b.terr_id
                            );

        RETURN TRUE;
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Matching Province Name : '||SQLERRM);

            x_process_flag := FALSE;
      END;


     IF x_val_pass = 'Y'
     THEN
       RETURN TRUE;
     ELSE
       RETURN FALSE;
     END IF;

     */

      RETURN x_process_flag;

   EXCEPTION
      WHEN OTHERS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Exception Occured in GET_QUALIFIERS_VALIDATED : '||SQLERRM);
         x_process_flag := FALSE;
         RETURN x_process_flag;
   END get_qualifiers_validated;

   -- Function for calculating manual adjustments

   FUNCTION calc_manual_price_adjmnt(pr_quote_header_id IN NUMBER
                                    ,pr_quote_line_id IN NUMBER)
             RETURN NUMBER
     IS
         x_calc_value NUMBER;
     BEGIN
         x_calc_value := 0;

         SELECT sum(sum_operand) INTO x_calc_value
                FROM(
                SELECT sum(NVL(apa.operand,0)) sum_operand
                            from apps.ASO_PRICE_ADJUSTMENTS apa,
                                     apps.QP_LIST_HEADERS qlh,
                                     apps.QP_LIST_LINES qll
                             WHERE apa.modifier_header_id   = qlh.list_header_id
                                    AND qll.list_header_id  = qlh.list_header_id
                                    AND qll.list_line_id    = apa.modifier_line_id
                                    AND qll.automatic_flag  = 'N'
                                    AND apa.applied_flag    = 'Y'
                               AND apa.quote_header_id      = pr_quote_header_id
                               AND apa.modifier_level_code      = 'ORDER'
                UNION
                SELECT sum(NVL(apa.operand,0))sum_operand
                                from apps.ASO_PRICE_ADJUSTMENTS apa,
                                     apps.QP_LIST_HEADERS qlh,
                                     apps.QP_LIST_LINES qll
                             WHERE apa.modifier_header_id   = qlh.list_header_id
                                    AND qll.list_header_id  = qlh.list_header_id
                                    AND qll.list_line_id    = apa.modifier_line_id
                                    AND qll.automatic_flag  = 'N'
                                    AND apa.applied_flag    = 'Y'
                                    AND apa.quote_header_id = pr_quote_header_id
                                    AND apa.quote_line_id   = pr_quote_line_id
                     );

         /*SELECT sum(NVL(operand,0)) INTO x_calc_value
            from ASO_PRICE_ADJUSTMENTS apa,
                      QP_LIST_HEADERS qlh
          WHERE apa.modifier_header_id = qlh.list_header_id
               AND qlh.automatic_flag = 'N'
               AND apa.applied_flag = 'Y'
               AND apa.quote_header_id = pr_quote_header_id
               AND apa.quote_line_id = pr_quote_line_id;
               --AND apa.ARITHMETIC_OPERATOR = g_arithmetic_operator; -- Commented on 10-JAN-2014*/

               IF x_calc_value IS NULL OR x_calc_value = 0 THEN
                  RETURN(0);
               ELSE
                  RETURN(x_calc_value);
               END IF;
     EXCEPTION
        WHEN OTHERS THEN
             xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Exception Occured in calc_manual_price_adjmnt : '||SQLERRM);
             RETURN(0);
    END calc_manual_price_adjmnt;

   -- End dated modifier line
   PROCEDURE endate_modifier_line( pr_quote_header_id   IN NUMBER
                                  ,pr_list_header_id    IN NUMBER
                                  ,pr_list_line_id      IN NUMBER
                                  ,pr_start_date        IN DATE
                                  ,pr_line_price        IN NUMBER --Added by Debjani26Feb
                                  ,x_line_ret_stat      OUT VARCHAR2
                                  )
     IS
        p_api_version_number                    NUMBER := 1;
        p_init_msg_list                         VARCHAR2(2000) := fnd_api.g_true;
        p_return_values                         VARCHAR2(2000) := fnd_api.g_true;
        p_commit                                VARCHAR2(2000) := fnd_api.g_false;
        x_return_status                         VARCHAR2(2000);
        x_msg_data1                             VARCHAR2(200);
        x_line_index                            NUMBER := 0;
        x_line_return_status                    VARCHAR2(30);
        x_line_msg_count                        NUMBER;
        x_line_msg_data                         VARCHAR2(2000);
        x_line_msg_data1                        VARCHAR2(2000);

        l_modifier_list_rec                     apps.qp_modifiers_pub.modifier_list_rec_type;
        l_modifier_list_val_rec                 apps.qp_modifiers_pub.modifier_list_val_rec_type;
        l_modifiers_tbl                         apps.qp_modifiers_pub.modifiers_tbl_type;
        l_modifiers_val_tbl                     apps.qp_modifiers_pub.modifiers_val_tbl_type;
        l_qualifiers_tbl                        apps.qp_qualifier_rules_pub.qualifiers_tbl_type;
        l_qualifiers_val_tbl                    apps.qp_qualifier_rules_pub.qualifiers_val_tbl_type;
        l_pricing_attr_tbl                      apps.qp_modifiers_pub.pricing_attr_tbl_type;
        l_pricing_attr_val_tbl                  apps.qp_modifiers_pub.pricing_attr_val_tbl_type;
        x_modifier_list_rec                     apps.qp_modifiers_pub.modifier_list_rec_type;
        x_modifier_list_val_rec                 apps.qp_modifiers_pub.modifier_list_val_rec_type;
        x_modifiers_tbl                         apps.qp_modifiers_pub.modifiers_tbl_type;
        x_modifiers_val_tbl                     apps.qp_modifiers_pub.modifiers_val_tbl_type;
        x_qualifiers_tbl                        apps.qp_qualifier_rules_pub.qualifiers_tbl_type;
        x_qualifiers_val_tbl                    apps.qp_qualifier_rules_pub.qualifiers_val_tbl_type;
        x_pricing_attr_tbl                      apps.qp_modifiers_pub.pricing_attr_tbl_type;
        x_pricing_attr_val_tbl                  apps.qp_modifiers_pub.pricing_attr_val_tbl_type;

      BEGIN
            x_line_ret_stat := 'E';
            x_line_index    := 0;
            BEGIN

                 x_line_index := x_line_index +1;
                 l_modifiers_tbl(x_line_index).list_header_id := pr_list_header_id;
                 l_modifiers_tbl(x_line_index).list_line_id :=  pr_list_line_id;
                 l_modifiers_tbl(x_line_index).end_date_active := TO_DATE ((TRUNC(pr_start_date)||'23:59:59'),'DD-MON-RR HH24:MI:SS'); --26FEB DEBJANI UPDATED
                 l_modifiers_tbl(x_line_index).operation := qp_globals.g_opr_update;

                 --ADDED BY DEBJANI26FEB
                 IF pr_line_price IS NOT NULL THEN
                    l_modifiers_tbl(x_line_index).operand := pr_line_price;
                 END IF;
                 --END ADDED BY DEBJANI26FEB

                fnd_msg_pub.initialize;
                qp_modifiers_pub.process_modifiers
                                  (p_api_version_number                     => p_api_version_number
                                  ,p_init_msg_list                          => p_init_msg_list
                                  ,p_return_values                          => p_return_values
                                  ,p_commit                                 => p_commit
                                  ,x_return_status                          => x_line_return_status
                                  ,x_msg_count                              => x_line_msg_count
                                  ,x_msg_data                               => x_line_msg_data
                                  ,p_modifier_list_rec                      => l_modifier_list_rec
                                  ,p_modifier_list_val_rec                  => l_modifier_list_val_rec
                                  ,p_modifiers_tbl                          => l_modifiers_tbl
                                  ,p_modifiers_val_tbl                      => l_modifiers_val_tbl
                                  ,p_qualifiers_tbl                         => l_qualifiers_tbl
                                  ,p_qualifiers_val_tbl                     => l_qualifiers_val_tbl
                                  ,p_pricing_attr_tbl                       => l_pricing_attr_tbl
                                  ,p_pricing_attr_val_tbl                   => l_pricing_attr_val_tbl
                                  ,x_modifier_list_rec                      => x_modifier_list_rec
                                  ,x_modifier_list_val_rec                  => x_modifier_list_val_rec
                                  ,x_modifiers_tbl                          => x_modifiers_tbl
                                  ,x_modifiers_val_tbl                      => x_modifiers_val_tbl
                                  ,x_qualifiers_tbl                         => x_qualifiers_tbl
                                  ,x_qualifiers_val_tbl                     => x_qualifiers_val_tbl
                                  ,x_pricing_attr_tbl                       => x_pricing_attr_tbl
                                  ,x_pricing_attr_val_tbl                   => x_pricing_attr_val_tbl
                                  );
                 EXCEPTION
                    WHEN OTHERS THEN
                       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                           ,'Error while End dating line for Quote id: ' || pr_quote_header_id ||
                                            ' Error: ' || x_line_msg_data);

                       ROLLBACK;
                       x_updt_modifier_flag := 'Y';
                       x_line_ret_stat := 'E';
                 END;

                 x_line_ret_stat := x_line_return_status;
                 IF x_line_return_status IN ('E', 'U') THEN
                    x_line_msg_data   := '';
                    x_line_msg_data1  := '';

                    FOR k IN 1 .. x_line_msg_count
                    LOOP
                       x_line_msg_data  := oe_msg_pub.get(p_msg_index => k, p_encoded => 'F');
                       x_line_msg_data1 := x_line_msg_data1 || substr(x_line_msg_data, 1, 200);
                    END LOOP;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                        ,'API Error occured while Error while End dating line for Quote id(Inside endate_modifier_line): ' ||
                                         pr_quote_header_id || ' Error: ' || x_line_msg_data1);
                    ROLLBACK;
                    x_updt_modifier_flag := 'Y';
                 END IF;
       EXCEPTION
          WHEN OTHERS THEN
              xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Modifier line not end dated  for Quote id(Inside endate_modifier_line): ' || pr_quote_header_id ||
                              ' OTHERS Error: ' || SQLERRM);
             x_updt_modifier_flag := 'Y';
             x_line_ret_stat := 'E';
    END endate_modifier_line;

   -- Create modifier line
    PROCEDURE create_modifier_line( pr_quote_header_id   IN NUMBER
                                   ,pr_list_header_id    IN NUMBER
                                   ,pr_start_date        IN DATE
                                   ,pr_end_date          IN DATE
                                   ,pr_price_adjmnt      IN NUMBER
                                   ,pr_line_item         IN NUMBER
                                   ,pr_quote_line_id     IN NUMBER -- New add after UIT
                                   ,x_list_line_id       OUT NUMBER
                                   ,x_line_ret_stat      OUT VARCHAR2
                                  )
     IS
        p_api_version_number                    NUMBER := 1;
        p_init_msg_list                         VARCHAR2(2000) := fnd_api.g_true;
        p_return_values                         VARCHAR2(2000) := fnd_api.g_true;
        p_commit                                VARCHAR2(2000) := fnd_api.g_false;
        x_return_status                         VARCHAR2(2000);
        x_list_header_id                        NUMBER;
        x_list_ln_id                            NUMBER;
        x_line_index                            NUMBER := 0;
        x_pricing_attr_index                    NUMBER := 0;
        x_quali_index                           NUMBER := 0;
        x_line_return_status                    VARCHAR2(30);
        x_line_msg_count                        NUMBER;
        x_line_msg_data                         VARCHAR2(2000);
        x_line_msg_data1                        VARCHAR2(2000);

        l_modifier_list_rec                     apps.qp_modifiers_pub.modifier_list_rec_type;
        l_modifier_list_val_rec                 apps.qp_modifiers_pub.modifier_list_val_rec_type;
        l_modifiers_tbl                         apps.qp_modifiers_pub.modifiers_tbl_type;
        l_modifiers_val_tbl                     apps.qp_modifiers_pub.modifiers_val_tbl_type;
        l_qualifiers_tbl                        apps.qp_qualifier_rules_pub.qualifiers_tbl_type;
        l_qualifiers_val_tbl                    apps.qp_qualifier_rules_pub.qualifiers_val_tbl_type;
        l_pricing_attr_tbl                      apps.qp_modifiers_pub.pricing_attr_tbl_type;
        l_pricing_attr_val_tbl                  apps.qp_modifiers_pub.pricing_attr_val_tbl_type;
        x_modifier_list_rec                     apps.qp_modifiers_pub.modifier_list_rec_type;
        x_modifier_list_val_rec                 apps.qp_modifiers_pub.modifier_list_val_rec_type;
        x_modifiers_tbl                         apps.qp_modifiers_pub.modifiers_tbl_type;
        x_modifiers_val_tbl                     apps.qp_modifiers_pub.modifiers_val_tbl_type;
        x_qualifiers_tbl                        apps.qp_qualifier_rules_pub.qualifiers_tbl_type;
        x_qualifiers_val_tbl                    apps.qp_qualifier_rules_pub.qualifiers_val_tbl_type;
        x_pricing_attr_tbl                      apps.qp_modifiers_pub.pricing_attr_tbl_type;
        x_pricing_attr_val_tbl                  apps.qp_modifiers_pub.pricing_attr_val_tbl_type;

      BEGIN
            x_line_ret_stat := 'E';
            x_pricing_attr_index := 0;
            x_line_index    := 0;
            x_list_ln_id := 0;
            BEGIN

                 x_line_index := x_line_index +1;
                 x_pricing_attr_index := x_pricing_attr_index +1;

                 l_modifiers_tbl(x_line_index).list_header_id := pr_list_header_id;
                 --l_modifiers_tbl(x_line_index).list_line_id :=  rec_list_lines.list_line_id; -- used only for update
                 l_modifiers_tbl(x_line_index).list_line_type_code := g_list_line_type_code;
                 l_modifiers_tbl(x_line_index).attribute1 := NULL;
                 l_modifiers_tbl(x_line_index).modifier_level_code := g_modifier_level_code;
                 l_modifiers_tbl(x_line_index).pricing_phase_id := 2;
                 l_modifiers_tbl(x_line_index).product_precedence := g_product_precedence;
                 --l_modifiers_tbl(x_line_index).start_date_active := pr_start_date;
                 l_modifiers_tbl(x_line_index).start_date_active := TRUNC(pr_start_date); --26FEB DEBJANI UPDATED
                 --l_modifiers_tbl(x_line_index).end_date_active := pr_end_date;
                 l_modifiers_tbl(x_line_index).end_date_active := TRUNC(pr_end_date); --26FEB DEBJANI UPDATED
                 l_modifiers_tbl(x_line_index).arithmetic_operator := g_arithmetic_operator;
                 l_modifiers_tbl(x_line_index).operand := pr_price_adjmnt;
                 l_modifiers_tbl(x_line_index).attribute3 := pr_quote_line_id;     -- New add after UIT
                 l_modifiers_tbl(x_line_index).operation := qp_globals.g_opr_create;
                 l_modifiers_tbl(x_line_index).incompatibility_grp_code := 'LVL 1'; --***
                 l_modifiers_tbl(x_line_index).pricing_group_sequence := 1; --***

                 l_pricing_attr_tbl(x_pricing_attr_index).product_attribute_context := g_product_attr_context;
                 l_pricing_attr_tbl(x_pricing_attr_index).product_attribute := g_product_attribute;
                 l_pricing_attr_tbl(x_pricing_attr_index).product_attr_value := pr_line_item;
                 l_pricing_attr_tbl(x_pricing_attr_index).modifiers_index := 1;
                 l_pricing_attr_tbl(x_pricing_attr_index).operation := qp_globals.g_opr_create;

                fnd_msg_pub.initialize;
                qp_modifiers_pub.process_modifiers
                                  (p_api_version_number                     => p_api_version_number
                                  ,p_init_msg_list                          => p_init_msg_list
                                  ,p_return_values                          => p_return_values
                                  ,p_commit                                 => p_commit
                                  ,x_return_status                          => x_line_return_status
                                  ,x_msg_count                              => x_line_msg_count
                                  ,x_msg_data                               => x_line_msg_data
                                  ,p_modifier_list_rec                      => l_modifier_list_rec
                                  ,p_modifier_list_val_rec                  => l_modifier_list_val_rec
                                  ,p_modifiers_tbl                          => l_modifiers_tbl
                                  ,p_modifiers_val_tbl                      => l_modifiers_val_tbl
                                  ,p_qualifiers_tbl                         => l_qualifiers_tbl
                                  ,p_qualifiers_val_tbl                     => l_qualifiers_val_tbl
                                  ,p_pricing_attr_tbl                       => l_pricing_attr_tbl
                                  ,p_pricing_attr_val_tbl                   => l_pricing_attr_val_tbl
                                  ,x_modifier_list_rec                      => x_modifier_list_rec
                                  ,x_modifier_list_val_rec                  => x_modifier_list_val_rec
                                  ,x_modifiers_tbl                          => x_modifiers_tbl
                                  ,x_modifiers_val_tbl                      => x_modifiers_val_tbl
                                  ,x_qualifiers_tbl                         => x_qualifiers_tbl
                                  ,x_qualifiers_val_tbl                     => x_qualifiers_val_tbl
                                  ,x_pricing_attr_tbl                       => x_pricing_attr_tbl
                                  ,x_pricing_attr_val_tbl                   => x_pricing_attr_val_tbl
                                  );
                 EXCEPTION
                    WHEN OTHERS THEN
                       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                           ,'Error while creating Modifier line for Quote id: ' || pr_quote_header_id ||
                                            ' Error: ' || x_line_msg_data);

                       ROLLBACK;
                       x_updt_modifier_flag := 'Y';
                       x_line_ret_stat := 'E';
                 END;

                 x_line_ret_stat := x_line_return_status;
                 IF x_line_return_status IN ('E', 'U') THEN
                    x_line_msg_data   := '';
                    x_line_msg_data1  := '';

                    FOR k IN 1 .. x_line_msg_count
                    LOOP
                       x_line_msg_data  := oe_msg_pub.get(p_msg_index => k, p_encoded => 'F');
                       x_line_msg_data1 := x_line_msg_data1 || substr(x_line_msg_data, 1, 200);
                    END LOOP;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                        ,'API Error occured while creating Modifier line for Quote id(Inside create_modifier_line): ' ||
                                         pr_quote_header_id || ' Error: ' || x_line_msg_data1);
                    ROLLBACK;
                    x_updt_modifier_flag := 'Y';

                ELSE
                    x_list_ln_id := x_modifiers_tbl(x_line_index).list_line_id;

                    x_list_line_id := x_list_ln_id;

                    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                ,'list_line_id after creation of Modifier line for Quote id(Inside update_modifier: create_qualifier): ' ||
                                 pr_quote_header_id || ' list_line_id: ' || x_list_line_id);

                 END IF;
       EXCEPTION
          WHEN OTHERS THEN
              xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Modifier line not created  for Quote id(Inside create_modifier_line): ' || pr_quote_header_id ||
                              ' OTHERS Error: ' || SQLERRM);
             x_updt_modifier_flag := 'Y';
             x_line_ret_stat := 'E';
             x_list_ln_id := 0;
    END create_modifier_line;

   -- Procedure create_qualifier

   PROCEDURE create_qualifier(pr_quote_header_id      IN  NUMBER,
                              pr_cust_acct_site_id    IN  NUMBER,
                              pr_account_number       IN  VARCHAR2,
                              pr_bill_to_acct_id      IN  NUMBER,
                              pr_apply_all_ship_to    IN  VARCHAR2,
                              pr_list_header_id       IN  NUMBER,
                              pr_list_line_id         IN  NUMBER,
                              pr_resource_id          IN  NUMBER,
                              x_quali_ret_status     OUT VARCHAR2
                              )

    IS
        --Cursor to get Customer Ship to Information
      CURSOR c_cust_ship_to IS
         SELECT hcsu.site_use_id
               ,hcsu.cust_acct_site_id
               ,hcsu.object_version_number
           FROM hz_cust_accounts       hca
               ,hz_party_sites         hps
               ,hz_cust_acct_sites_all hcas
               ,hz_cust_site_uses_all  hcsu
          WHERE hca.party_id = hps.party_id
                AND hcas.cust_account_id = hca.cust_account_id
                AND hcas.party_site_id = hps.party_site_id
                AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                AND hcas.cust_acct_site_id = pr_cust_acct_site_id --- Added By Dhiren 04-Jan-2013
                AND hcsu.site_use_code = 'SHIP_TO'
                AND hcsu.status = 'A'
                AND hca.status = 'A'
                AND hcas.org_id = hcsu.org_id
                AND hca.cust_account_id IN
                (SELECT related_cust_account_id
                       FROM hz_cust_acct_relate_all hcar
                           ,hz_cust_accounts        hzca
                      WHERE hzca.account_number = pr_account_number
                            AND hcar.cust_account_id = hzca.cust_account_id
                            AND g_apply_to_all_ship_to = 'Y'
                     UNION
                     SELECT cust_account_id
                       FROM hz_cust_accounts
                      WHERE account_number = pr_account_number);

        --Cursor to get address information of related bill to site of quote
       CURSOR c_related_cust_info IS
         SELECT hp.party_name
               ,hca.account_number
               ,hcsu.site_use_id
               ,hcsu.cust_acct_site_id
               ,hcsu.price_list_id
               ,hl.country
               ,hl.postal_code
               ,hl.state
               ,hl.county
               ,hl.city
               ,hl.province
               ,hp.party_id
               ,hcsu.object_version_number
               ,DECODE(hca.cust_account_id,pr_bill_to_acct_id,'MAIN','REL') rel_typ
           FROM hz_parties             hp
               ,hz_cust_accounts       hca
               ,hz_party_sites         hps
               ,hz_cust_acct_sites_all hcas
               ,hz_cust_site_uses_all  hcsu
               ,hz_locations           hl
          WHERE hp.party_id = hca.party_id
                AND hca.party_id = hps.party_id
                AND hps.location_id = hl.location_id
                AND hca.cust_account_id IN (SELECT related_cust_account_id
                                              FROM hz_cust_acct_relate_all
                                             WHERE cust_account_id = pr_bill_to_acct_id
                                            UNION
                                            SELECT pr_bill_to_acct_id
                                              FROM dual)
                AND hcas.cust_account_id = hca.cust_account_id
                AND hcas.party_site_id = hps.party_site_id
                AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                AND hcsu.site_use_code = 'SHIP_TO'
                AND hcsu.status = 'A'
                AND hca.status = 'A'
                AND hcas.org_id = hcsu.org_id
         --AND hcsu.org_id=p_org_id
          ORDER BY hcsu.price_list_id DESC;

        p_api_version_number                    NUMBER := 1;
        p_init_msg_list                         VARCHAR2(2000) := fnd_api.g_true;
        p_return_values                         VARCHAR2(2000) := fnd_api.g_true;
        p_commit                                VARCHAR2(2000) := fnd_api.g_false;
        x_list_header_id                        NUMBER;
        x_line_index                            NUMBER := 0;
        x_pricing_attr_index                    NUMBER := 0;
        x_quali_index                           NUMBER := 0;
        x_quali_return_status                   VARCHAR2(30);
        x_quali_msg_count                       NUMBER;
        x_quali_msg_data                        VARCHAR2(2000);
        x_quali_msg_data1                       VARCHAR2(2000);
        x_manual_price_adjmnt                   NUMBER;
        x_error_flag                            VARCHAR2(1) := 'N';
        x_postal_code                           VARCHAR2(100);
        x_qualifier_old_value                   NUMBER;

        l_modifier_list_rec                     apps.qp_modifiers_pub.modifier_list_rec_type;
        l_modifier_list_val_rec                 apps.qp_modifiers_pub.modifier_list_val_rec_type;
        l_modifiers_tbl                         apps.qp_modifiers_pub.modifiers_tbl_type;
        l_modifiers_val_tbl                     apps.qp_modifiers_pub.modifiers_val_tbl_type;
        l_qualifiers_tbl                        apps.qp_qualifier_rules_pub.qualifiers_tbl_type;
        l_qualifiers_val_tbl                    apps.qp_qualifier_rules_pub.qualifiers_val_tbl_type;
        l_pricing_attr_tbl                      apps.qp_modifiers_pub.pricing_attr_tbl_type;
        l_pricing_attr_val_tbl                  apps.qp_modifiers_pub.pricing_attr_val_tbl_type;
        x_modifier_list_rec                     apps.qp_modifiers_pub.modifier_list_rec_type;
        x_modifier_list_val_rec                 apps.qp_modifiers_pub.modifier_list_val_rec_type;
        x_modifiers_tbl                         apps.qp_modifiers_pub.modifiers_tbl_type;
        x_modifiers_val_tbl                     apps.qp_modifiers_pub.modifiers_val_tbl_type;
        x_qualifiers_tbl                        apps.qp_qualifier_rules_pub.qualifiers_tbl_type;
        x_qualifiers_val_tbl                    apps.qp_qualifier_rules_pub.qualifiers_val_tbl_type;
        x_pricing_attr_tbl                      apps.qp_modifiers_pub.pricing_attr_tbl_type;
        x_pricing_attr_val_tbl                  apps.qp_modifiers_pub.pricing_attr_val_tbl_type;

    BEGIN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Inside Create_qualifier');
          x_quali_ret_status := 'E';
        BEGIN
           p_api_version_number                    := 1;
           p_init_msg_list                         := fnd_api.g_true;
           p_return_values                         := fnd_api.g_true;
           p_commit                                := fnd_api.g_false;
           x_quali_return_status                   := NULL;
           x_quali_msg_count                       := NULL;
           x_quali_msg_data                        := NULL;
           l_modifier_list_rec                     := apps.qp_modifiers_pub.g_miss_modifier_list_rec;
           l_modifier_list_val_rec                 := apps.qp_modifiers_pub.g_miss_modifier_list_val_rec;
           l_modifiers_tbl                         := apps.qp_modifiers_pub.g_miss_modifiers_tbl;
           l_modifiers_val_tbl                     := apps.qp_modifiers_pub.g_miss_modifiers_val_tbl;
           l_qualifiers_tbl                        := apps.qp_qualifier_rules_pub.g_miss_qualifiers_tbl;
           l_qualifiers_val_tbl                    := apps.qp_qualifier_rules_pub.g_miss_qualifiers_val_tbl;
           l_pricing_attr_tbl                      := apps.qp_modifiers_pub.g_miss_pricing_attr_tbl;
           l_pricing_attr_val_tbl                  := apps.qp_modifiers_pub.g_miss_pricing_attr_val_tbl;
           x_modifier_list_rec                     := apps.qp_modifiers_pub.g_miss_modifier_list_rec;
           x_modifier_list_val_rec                 := apps.qp_modifiers_pub.g_miss_modifier_list_val_rec;
           x_modifiers_tbl                         := apps.qp_modifiers_pub.g_miss_modifiers_tbl;
           x_modifiers_val_tbl                     := apps.qp_modifiers_pub.g_miss_modifiers_val_tbl;
           x_qualifiers_tbl                        := apps.qp_qualifier_rules_pub.g_miss_qualifiers_tbl;
           x_qualifiers_val_tbl                    := apps.qp_qualifier_rules_pub.g_miss_qualifiers_val_tbl;
           x_pricing_attr_tbl                      := apps.qp_modifiers_pub.g_miss_pricing_attr_tbl;
           x_pricing_attr_val_tbl                  := apps.qp_modifiers_pub.g_miss_pricing_attr_val_tbl;

           x_quali_index := 0;

       IF pr_apply_all_ship_to = 'N' THEN
        FOR r_cust_ship_to IN c_cust_ship_to
         LOOP
           x_quali_index := x_quali_index + 1;

           l_qualifiers_tbl(x_quali_index).list_header_id := pr_list_header_id;
           l_qualifiers_tbl(x_quali_index).list_line_id := pr_list_line_id;
              --l_QUALIFIERS_tbl(x_quali_index).excluder_flag := 'N';
           l_qualifiers_tbl(x_quali_index).comparison_operator_code := '=';
           l_qualifiers_tbl(x_quali_index).qualifier_context := g_qualifier_context;
           l_qualifiers_tbl(x_quali_index).qualifier_attribute := g_qualifier_attribute;
           l_qualifiers_tbl(x_quali_index).qualifier_attr_value := to_char(r_cust_ship_to.site_use_id);  -- site_use_id  of HZ_CUST_SITE_USES_ALL
           l_qualifiers_tbl(x_quali_index).qualifier_grouping_no := -1;
           l_qualifiers_tbl(x_quali_index).operation := qp_globals.g_opr_create;
         END LOOP; -- Qualifier loop
        END IF;

        IF pr_apply_all_ship_to = 'Y' THEN

          FOR r_related_cust_info IN c_related_cust_info
           LOOP
           x_postal_code := NULL;
           xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                              ,'Account Number ' || r_related_cust_info.account_number );

           IF INSTR(r_related_cust_info.postal_code,'-',1,1) > 0 THEN
              BEGIN
               select SUBSTR(r_related_cust_info.postal_code,1,INSTR(r_related_cust_info.postal_code,'-',1,1)-1)
                 INTO x_postal_code
                 from dual;
             EXCEPTION
             WHEN OTHERS THEN
                x_postal_code := r_related_cust_info.postal_code;
            END;
           ELSE
              x_postal_code := r_related_cust_info.postal_code;
           END IF;

           IF (get_qualifiers_validated(r_related_cust_info.party_id
                                      ,r_related_cust_info.country
                                      ,r_related_cust_info.county
                                      ,r_related_cust_info.state
                                      ,x_postal_code
                                      ,r_related_cust_info.province
                                      ,r_related_cust_info.city
                                      ,r_related_cust_info.party_name
                                      ,r_related_cust_info.rel_typ
                                      ,pr_resource_id)) THEN

            x_quali_index := x_quali_index + 1;

            l_qualifiers_tbl(x_quali_index).list_header_id := pr_list_header_id;
            l_qualifiers_tbl(x_quali_index).list_line_id := pr_list_line_id;
              --l_QUALIFIERS_tbl(x_quali_index).excluder_flag := 'N';
            l_qualifiers_tbl(x_quali_index).comparison_operator_code := '=';
            l_qualifiers_tbl(x_quali_index).qualifier_context := g_qualifier_context;
            l_qualifiers_tbl(x_quali_index).qualifier_attribute := g_qualifier_attribute;
            l_qualifiers_tbl(x_quali_index).qualifier_attr_value := to_char(r_related_cust_info.site_use_id);  -- site_use_id  of HZ_CUST_SITE_USES_ALL
            l_qualifiers_tbl(x_quali_index).qualifier_grouping_no := -1;
            l_qualifiers_tbl(x_quali_index).operation := qp_globals.g_opr_create;

          END IF;
       END LOOP;

       END IF;

           -- Call API
           qp_modifiers_pub.process_modifiers
                                    (p_api_version_number                     => p_api_version_number
                                    ,p_init_msg_list                          => p_init_msg_list
                                    ,p_return_values                          => p_return_values
                                    ,p_commit                                 => p_commit
                                    ,x_return_status                          => x_quali_return_status
                                    ,x_msg_count                              => x_quali_msg_count
                                    ,x_msg_data                               => x_quali_msg_data
                                    ,p_modifier_list_rec                      => l_modifier_list_rec
                                    ,p_modifier_list_val_rec                  => l_modifier_list_val_rec
                                    ,p_modifiers_tbl                          => l_modifiers_tbl
                                    ,p_modifiers_val_tbl                      => l_modifiers_val_tbl
                                    ,p_qualifiers_tbl                         => l_qualifiers_tbl
                                    ,p_qualifiers_val_tbl                     => l_qualifiers_val_tbl
                                    ,p_pricing_attr_tbl                       => l_pricing_attr_tbl
                                    ,p_pricing_attr_val_tbl                   => l_pricing_attr_val_tbl
                                    ,x_modifier_list_rec                      => x_modifier_list_rec
                                    ,x_modifier_list_val_rec                  => x_modifier_list_val_rec
                                    ,x_modifiers_tbl                          => x_modifiers_tbl
                                    ,x_modifiers_val_tbl                      => x_modifiers_val_tbl
                                    ,x_qualifiers_tbl                         => x_qualifiers_tbl
                                    ,x_qualifiers_val_tbl                     => x_qualifiers_val_tbl
                                    ,x_pricing_attr_tbl                       => x_pricing_attr_tbl
                                    ,x_pricing_attr_val_tbl                   => x_pricing_attr_val_tbl
                                    );

         EXCEPTION
            WHEN OTHERS THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                   ,'Error while creating Modifier Line Qualifier for Quote id(Inside update_modifier: create_qualifier): ' || pr_quote_header_id ||
                                    ' Error: ' || x_quali_msg_data);

               ROLLBACK;
               x_updt_modifier_flag := 'Y';
               x_quali_ret_status := 'E';
         END;
         x_quali_ret_status := x_quali_return_status;  -- Out parameter
         IF x_quali_return_status IN ('E', 'U') THEN
            x_quali_msg_data   := '';
            x_quali_msg_data1  := '';
            --x_error_record := x_error_record + 1;
            FOR k IN 1 .. x_quali_msg_count
            LOOP
               x_quali_msg_data  := oe_msg_pub.get(p_msg_index => k, p_encoded => 'F');
               x_quali_msg_data1 := x_quali_msg_data1 || substr(x_quali_msg_data, 1, 200);
            END LOOP;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                ,'API Error occured while creating the Modifier line qualifier for Quote id(Inside update_modifier: create_qualifier): ' ||
                                 pr_quote_header_id || ' Error: ' || x_quali_msg_data1);
            ROLLBACK;
            x_updt_modifier_flag := 'Y';
         END IF;
      EXCEPTION
        WHEN OTHERS THEN
             xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                ,'Other Error occured while creating the Modifier line qualifier for Quote id(Inside update_modifier: create_qualifier)' ||
                                 pr_quote_header_id || ' Error: ' || SQLERRM);
             x_updt_modifier_flag := 'Y';
             x_quali_ret_status := 'E';
     END create_qualifier;


    -- Procedure for creating limit

    PROCEDURE create_limit( pr_quote_header_id IN  NUMBER
                           ,pr_list_header_id  IN  NUMBER
                           ,pr_list_line_id    IN  NUMBER
                           ,pr_limit_usage     IN  NUMBER
                           ,x_limit_ret_stat  OUT VARCHAR2
                           )
      IS
            p_api_version_number                    NUMBER := 1;
            p_init_msg_list                         VARCHAR2(2000) := fnd_api.g_true;
            p_return_values                         VARCHAR2(2000) := fnd_api.g_true;
            p_commit                                VARCHAR2(2000) := fnd_api.g_false;
            x_lmt_return_status                     VARCHAR2(30);
            x_lmt_msg_data                          VARCHAR2(2000);
            x_lmt_msg_count                         NUMBER := 0;
            x_lmt_msg_data1                         VARCHAR2(2000);


            l_limits_rec                            apps.qp_limits_pub.limits_rec_type;
            l_limits_val_rec                        apps.qp_limits_pub.limits_val_rec_type;
            l_limit_attrs_tbl                       apps.qp_limits_pub.limit_attrs_tbl_type;
            l_limit_attrs_val_tbl                   apps.qp_limits_pub.limit_attrs_val_tbl_type;
            l_limit_balances_tbl                    apps.qp_limits_pub.limit_balances_tbl_type;
            l_limit_balances_val_tbl                apps.qp_limits_pub.limit_balances_val_tbl_type;
            x_limits_rec                            apps.qp_limits_pub.limits_rec_type;
            x_limits_val_rec                        apps.qp_limits_pub.limits_val_rec_type;
            x_limit_attrs_tbl                       apps.qp_limits_pub.limit_attrs_tbl_type;
            x_limit_attrs_val_tbl                   apps.qp_limits_pub.limit_attrs_val_tbl_type;
            x_limit_balances_tbl                    apps.qp_limits_pub.limit_balances_tbl_type;
            x_limit_balances_val_tbl                apps.qp_limits_pub.limit_balances_val_tbl_type;
    BEGIN

            x_limit_ret_stat := 'E';
         BEGIN
            l_limits_rec.limit_id := FND_API.G_MISS_NUM;
            l_limits_rec.list_header_id := pr_list_header_id;
            l_limits_rec.list_line_id := pr_list_line_id; --rec_list_lines.list_line_id;
            l_limits_rec.limit_number := 1;
            l_limits_rec.basis := g_basis;
            l_limits_rec.organization_flag := 'N';
            l_limits_rec.limit_level_code := g_limit_level_code;
            --l_limits_rec.limit_exceed_action_code := 'HARD';
            l_limits_rec.amount := pr_limit_usage;
            l_limits_rec.LIMIT_HOLD_FLAG := 'N'; --'Y';
            l_limits_rec.operation := QP_GLOBALS.g_opr_create;

           QP_Limits_PUB.Process_Limits
                  ( p_api_version_number     => 1.0
                  , p_init_msg_list          => p_init_msg_list
                  , p_return_values          => p_return_values
                  , p_commit                 => p_commit
                  , x_return_status          => x_lmt_return_status
                  , x_msg_count              => x_lmt_msg_count
                  , x_msg_data               => x_lmt_msg_data
                  , p_LIMITS_rec             => l_limits_rec
                  , p_LIMITS_val_rec         => l_limits_val_rec
                  , p_LIMIT_ATTRS_tbl        => l_limit_attrs_tbl
                  , p_LIMIT_ATTRS_val_tbl    => l_limit_attrs_val_tbl
                  , p_LIMIT_BALANCES_tbl     => l_limit_balances_tbl
                  , p_LIMIT_BALANCES_val_tbl => l_limit_balances_val_tbl
                  , x_LIMITS_rec             => x_limits_rec
                  , x_LIMITS_val_rec         => x_limits_val_rec
                  , x_LIMIT_ATTRS_tbl        => x_limit_attrs_tbl
                  , x_LIMIT_ATTRS_val_tbl    => x_limit_attrs_val_tbl
                  , x_LIMIT_BALANCES_tbl     => x_limit_balances_tbl
                  , x_LIMIT_BALANCES_val_tbl => x_limit_balances_val_tbl
                  );
          EXCEPTION
            WHEN OTHERS THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                   ,'Error while creating Modifier Line Limit_Usage for Quote id(Inside update_modifier): ' || pr_quote_header_id ||
                                    ' Error: ' || x_lmt_msg_data);

               ROLLBACK;
               x_updt_modifier_flag := 'Y';
               x_limit_ret_stat := 'E';
          END;
             xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                          ,'limit Creation------------------------x_lmt_return_status (Inside update_modifier)'||x_lmt_return_status);
             x_limit_ret_stat := x_lmt_return_status;
        IF x_lmt_return_status IN ('E', 'U') THEN
             x_lmt_msg_data   := '';
             x_lmt_msg_data1  := '';
             --x_error_record := x_error_record + 1;
             FOR k IN 1 .. x_lmt_msg_count
             LOOP
               x_lmt_msg_data  := oe_msg_pub.get(p_msg_index => k, p_encoded => 'F');
               x_lmt_msg_data1 := x_lmt_msg_data1 || substr(x_lmt_msg_data, 1, 200);
             END LOOP;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                ,'API Error occured while creating the Modifier line Limit_Usage for Quote id(Inside update_modifier): ' ||
                                 pr_quote_header_id || ' Error: ' || x_lmt_msg_data1);
                ROLLBACK;
                x_updt_modifier_flag := 'Y';
         END IF;
     EXCEPTION
       WHEN OTHERS THEN
             xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                ,'Limit useage not creted for Quote id(Inside update_modifier: create_qualifier)' ||
                                 pr_quote_header_id || ' Error: ' || SQLERRM);
             x_updt_modifier_flag := 'Y';
             x_limit_ret_stat := 'E';
   END create_limit;



   /**************************************************************************************
   *
   *   PROCEDURE
   *     create_modifier
   *
   *   DESCRIPTION
   *   Create modifier from Quote Header Information
   *
   *   RETURN VALUE
   *   NA
   *
   *   PREREQUISITES
   *   NA
   *
   *   CALLED BY
   *   create_upd_price_list
   *
   **************************************************************************************/
   PROCEDURE create_modifier(p_quote_header_id   IN NUMBER
                              ,p_quote_line_id     IN NUMBER
                              ,p_party_name        IN VARCHAR2
                              ,p_account_number    IN VARCHAR2
                              ,p_site_use_id       IN NUMBER
                              ,p_cust_acct_site_id IN NUMBER
                              ,p_org_id            IN NUMBER
                              ,p_cust_acct_id      IN NUMBER
                              ,p_limit_usage       IN VARCHAR2
                              ,p_start_date_active IN DATE
                              ,p_resource_id       IN NUMBER
                              ,p_bill_to_acct_id   IN NUMBER
                              ,p_apply_to_all_ship_to IN VARCHAR2) IS
      PRAGMA AUTONOMOUS_TRANSACTION;
        p_api_version_number                    NUMBER := 1;
        p_init_msg_list                         VARCHAR2(2000) := fnd_api.g_true;
        p_return_values                         VARCHAR2(2000) := fnd_api.g_true;
        p_commit                                VARCHAR2(2000) := fnd_api.g_false;
        x_return_status                         VARCHAR2(2000);
        x_msg_count                             NUMBER;
        x_msg_data                              VARCHAR2(2000);
        x_status                                VARCHAR2(200);
        x_msg_data1                             VARCHAR2(200);
        x_list_header_id                        NUMBER;
        x_list_line_id                          NUMBER;
        x_lmt_return_status                     VARCHAR2(30);
        x_lmt_msg_data                          VARCHAR2(2000);
        x_lmt_msg_count                         NUMBER := 0;
        x_line_index                            NUMBER := 0;
        x_pricing_attr_index                    NUMBER := 0;
        x_quali_index                           NUMBER := 0;
        x_line_return_status                    VARCHAR2(30);
        x_line_msg_count                        NUMBER;
        x_line_msg_data                         VARCHAR2(2000);
        x_line_msg_data1                        VARCHAR2(2000);
        x_quali_return_status                   VARCHAR2(30);
        x_quali_msg_count                       NUMBER;
        x_quali_msg_data                        VARCHAR2(2000);
        x_quali_msg_data1                       VARCHAR2(2000);
        x_lmt_msg_data1                         VARCHAR2(2000);
        x_manual_price_adjmnt                   NUMBER;
        x_error_flag                            VARCHAR2(1):= 'N';
        x_postal_code                           VARCHAR2(100);
        x_line_create_cnt                       NUMBER := 0;

        l_modifier_list_rec                     apps.qp_modifiers_pub.modifier_list_rec_type;
        l_modifier_list_val_rec                 apps.qp_modifiers_pub.modifier_list_val_rec_type;
        l_modifiers_tbl                         apps.qp_modifiers_pub.modifiers_tbl_type;
        l_modifiers_val_tbl                     apps.qp_modifiers_pub.modifiers_val_tbl_type;
        l_qualifiers_tbl                        apps.qp_qualifier_rules_pub.qualifiers_tbl_type;
        l_qualifiers_val_tbl                    apps.qp_qualifier_rules_pub.qualifiers_val_tbl_type;
        l_pricing_attr_tbl                      apps.qp_modifiers_pub.pricing_attr_tbl_type;
        l_pricing_attr_val_tbl                  apps.qp_modifiers_pub.pricing_attr_val_tbl_type;
        x_modifier_list_rec                     apps.qp_modifiers_pub.modifier_list_rec_type;
        x_modifier_list_val_rec                 apps.qp_modifiers_pub.modifier_list_val_rec_type;
        x_modifiers_tbl                         apps.qp_modifiers_pub.modifiers_tbl_type;
        x_modifiers_val_tbl                     apps.qp_modifiers_pub.modifiers_val_tbl_type;
        x_qualifiers_tbl                        apps.qp_qualifier_rules_pub.qualifiers_tbl_type;
        x_qualifiers_val_tbl                    apps.qp_qualifier_rules_pub.qualifiers_val_tbl_type;
        x_pricing_attr_tbl                      apps.qp_modifiers_pub.pricing_attr_tbl_type;
        x_pricing_attr_val_tbl                  apps.qp_modifiers_pub.pricing_attr_val_tbl_type;

        -- Limit usage variables

        l_limits_rec                            apps.qp_limits_pub.limits_rec_type;
        l_limits_val_rec                        apps.qp_limits_pub.limits_val_rec_type;
        l_limit_attrs_tbl                       apps.qp_limits_pub.limit_attrs_tbl_type;
        l_limit_attrs_val_tbl                   apps.qp_limits_pub.limit_attrs_val_tbl_type;
        l_limit_balances_tbl                    apps.qp_limits_pub.limit_balances_tbl_type;
        l_limit_balances_val_tbl                apps.qp_limits_pub.limit_balances_val_tbl_type;
        x_limits_rec                            apps.qp_limits_pub.limits_rec_type;
        x_limits_val_rec                        apps.qp_limits_pub.limits_val_rec_type;
        x_limit_attrs_tbl                       apps.qp_limits_pub.limit_attrs_tbl_type;
        x_limit_attrs_val_tbl                   apps.qp_limits_pub.limit_attrs_val_tbl_type;
        x_limit_balances_tbl                    apps.qp_limits_pub.limit_balances_tbl_type;
        x_limit_balances_val_tbl                apps.qp_limits_pub.limit_balances_val_tbl_type;

      --Cursor to get Quote Line Information
      CURSOR c_quote_lines IS
         SELECT DISTINCT aqh.attribute1 offer_type
                        ,aqh.attribute3 price_protected
                        ,aqh.attribute9 max_days
                        ,to_date(aqh.attribute4, 'RRRR/MM/DD HH24:MI:SS') quote_start_date
                        ,to_date(to_char(to_date(aqh.attribute4, 'RRRR/MM/DD HH24:MI:SS')+to_number(aqh.attribute9),'RRRR/MM/DD HH24:MI:SS'), 'RRRR/MM/DD HH24:MI:SS') quote_end_date
                        ,aql.inventory_item_id item
                        ,aql.uom_code
                        ,aql.line_list_price list_price
                        ,aql.line_quote_price unit_selling_price
                        ,aql.quote_line_id
           FROM aso_quote_lines_all   aql
               ,aso_quote_headers_all aqh
          WHERE aql.quote_header_id = p_quote_header_id
                AND aql.quote_header_id = aqh.quote_header_id
                AND (p_quote_line_id IS NULL OR aql.quote_line_id = p_quote_line_id)
                AND aqh.org_id = aql.org_id
                AND aql.org_id = p_org_id;

      --Cursor to get Customer Ship to Information
      CURSOR c_cust_ship_to IS
         SELECT hcsu.site_use_id
               ,hcsu.cust_acct_site_id
               ,hcsu.object_version_number
           FROM hz_cust_accounts       hca
               ,hz_party_sites         hps
               ,hz_cust_acct_sites_all hcas
               ,hz_cust_site_uses_all  hcsu
          WHERE hca.party_id = hps.party_id
                AND hcas.cust_account_id = hca.cust_account_id
                AND hcas.party_site_id = hps.party_site_id
                AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                AND hcas.cust_acct_site_id = p_cust_acct_site_id --- Added By Dhiren 04-Jan-2013
                AND hcsu.site_use_code = 'SHIP_TO'
                AND hcsu.status = 'A'
                AND hca.status = 'A'
                AND hcas.org_id = hcsu.org_id
                AND hca.cust_account_id IN
                (SELECT related_cust_account_id
                       FROM hz_cust_acct_relate_all hcar
                           ,hz_cust_accounts        hzca
                      WHERE hzca.account_number = p_account_number
                            AND hcar.cust_account_id = hzca.cust_account_id
                            AND g_apply_to_all_ship_to = 'Y'
                     UNION
                     SELECT cust_account_id
                       FROM hz_cust_accounts
                      WHERE account_number = p_account_number);

       --Cursor to get address information of related bill to site of quote
       CURSOR c_related_cust_info IS
         SELECT hp.party_name
               ,hca.account_number
               ,hcsu.site_use_id
               ,hcsu.cust_acct_site_id
               ,hcsu.price_list_id
               ,hl.country
               ,hl.postal_code
               ,hl.state
               ,hl.county
               ,hl.city
               ,hl.province
               ,hp.party_id
               ,hcsu.object_version_number
               ,DECODE(hca.cust_account_id,p_bill_to_acct_id,'MAIN','REL') rel_typ
           FROM hz_parties             hp
               ,hz_cust_accounts       hca
               ,hz_party_sites         hps
               ,hz_cust_acct_sites_all hcas
               ,hz_cust_site_uses_all  hcsu
               ,hz_locations           hl
          WHERE hp.party_id = hca.party_id
                AND hca.party_id = hps.party_id
                AND hps.location_id = hl.location_id
                AND hca.cust_account_id IN (SELECT related_cust_account_id
                                              FROM hz_cust_acct_relate_all
                                             WHERE cust_account_id = p_bill_to_acct_id
                                            UNION
                                            SELECT p_bill_to_acct_id
                                              FROM dual)
                AND hcas.cust_account_id = hca.cust_account_id
                AND hcas.party_site_id = hps.party_site_id
                AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                AND hcsu.site_use_code = 'SHIP_TO'
                AND hcsu.status = 'A'
                AND hca.status = 'A'
                AND hcas.org_id = hcsu.org_id
         --AND hcsu.org_id=p_org_id
          ORDER BY hcsu.price_list_id DESC;

   BEGIN

      --x_modifier_name := 'DRF-DISCOUNT-'||p_party_name||'-'||p_account_number ;

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                          ,'Creating New Modifier for Quote id: ' || p_quote_header_id || ' Modifier Name: ' ||
                           x_modifier_name);
        x_error_flag := 'N';
        BEGIN
          p_init_msg_list := fnd_api.g_true;
          p_return_values := fnd_api.g_false;
          p_commit        := fnd_api.g_false;
          x_list_header_id := NULL;
          x_list_line_id   := NULL;
          -- Header Creation
          l_modifier_list_rec.currency_code:= 'USD';
          l_modifier_list_rec.list_type_code:= g_list_type_code;
          l_modifier_list_rec.start_date_active:= p_start_date_active; --sysdate;
          --l_MODIFIER_LIST_REC.end_date_active:= '12-OCT-13';
          l_modifier_list_rec.source_system_code:= 'QP';
          l_modifier_list_rec.active_flag:= 'Y';
          l_modifier_list_rec.automatic_flag:= 'Y';
          l_modifier_list_rec.NAME:= x_modifier_name;        -- It is Number in front End
          l_modifier_list_rec.description:= x_modifier_name; -- It is Name in front End
          l_modifier_list_rec.comments:=x_modifier_name;     -- It is Description in front End

          l_modifier_list_rec.global_flag:='N';           -- This must be done if operating_unit given
          l_modifier_list_rec.org_id:= p_org_id;          -- Actually it is operating_unit

          l_modifier_list_rec.operation := qp_globals.g_opr_create; --'CREATE';
          --l_MODIFIER_LIST_REC.version_no:= '1.9';
          -- End Header creation

          --Create a Header Qualifier Record
          --l_QUALIFIERS_tbl(1).excluder_flag := 'N';
          l_qualifiers_tbl(1).comparison_operator_code := '=';
          l_qualifiers_tbl(1).qualifier_context := g_qualifier_context;
          l_qualifiers_tbl(1).qualifier_attribute := g_qualifier_attr_hdr;
          l_qualifiers_tbl(1).qualifier_attr_value := p_cust_acct_id;
          --l_qualifiers_tbl(1).qualifier_grouping_no := -1; --***
          l_qualifiers_tbl(1).qualifier_grouping_no := 10; --***
          --l_QUALIFIERS_tbl(1).qualifier_precedence := 1;
          --l_qualifiers_tbl(1).start_date_active := SYSDATE;
          --l_QUALIFIERS_tbl(1).end_date_active := '11-OCT-00';
          l_qualifiers_tbl(1).operation := qp_globals.g_opr_create;
          -- End Header Qualifier creation

          l_qualifiers_tbl(2).comparison_operator_code := '=';  --***
          l_qualifiers_tbl(2).qualifier_context := 'SHIP_TO_CUST';  --***
          l_qualifiers_tbl(2).qualifier_attribute := 'QUALIFIER_ATTRIBUTE40';  --***
          l_qualifiers_tbl(2).qualifier_attr_value := p_cust_acct_id;  --***
          l_qualifiers_tbl(2).qualifier_grouping_no := 20;  --***
          l_qualifiers_tbl(2).operation := qp_globals.g_opr_create;  --***

      --Calling API to create modifier header and Qualifier

         qp_modifiers_pub.process_modifiers
                            (p_api_version_number                     => p_api_version_number
                            ,p_init_msg_list                          => p_init_msg_list
                            ,p_return_values                          => p_return_values
                            ,p_commit                                 => p_commit
                            ,x_return_status                          => x_return_status
                            ,x_msg_count                              => x_msg_count
                            ,x_msg_data                               => x_msg_data
                            ,p_modifier_list_rec                      => l_modifier_list_rec
                            ,p_modifier_list_val_rec                  => l_modifier_list_val_rec
                            ,p_modifiers_tbl                          => l_modifiers_tbl
                            ,p_modifiers_val_tbl                      => l_modifiers_val_tbl
                            ,p_qualifiers_tbl                         => l_qualifiers_tbl
                            ,p_qualifiers_val_tbl                     => l_qualifiers_val_tbl
                            ,p_pricing_attr_tbl                       => l_pricing_attr_tbl
                            ,p_pricing_attr_val_tbl                   => l_pricing_attr_val_tbl
                            ,x_modifier_list_rec                      => x_modifier_list_rec
                            ,x_modifier_list_val_rec                  => x_modifier_list_val_rec
                            ,x_modifiers_tbl                          => x_modifiers_tbl
                            ,x_modifiers_val_tbl                      => x_modifiers_val_tbl
                            ,x_qualifiers_tbl                         => x_qualifiers_tbl
                            ,x_qualifiers_val_tbl                     => x_qualifiers_val_tbl
                            ,x_pricing_attr_tbl                       => x_pricing_attr_tbl
                            ,x_pricing_attr_val_tbl                   => x_pricing_attr_val_tbl
                            );
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                ,'Error while creating Modifier header API Call for Quote id: ' || p_quote_header_id ||
                                 ' Error: ' || SQLERRM);
         x_error_flag := 'Y';
      END;

      --Check return status of the API
      IF x_return_status IN ('E', 'U') THEN
         x_msg_data  := '';
         x_msg_data1 := '';
         FOR k IN 1 .. x_msg_count
         LOOP
            x_msg_data    := oe_msg_pub.get(p_msg_index => k, p_encoded => 'F');
            x_msg_data1   := x_msg_data1 || trim(x_msg_data);
         END LOOP;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Error while creating Modifier Header After API call for Quote id: ' || p_quote_header_id || ' Error: ' ||
                              x_msg_data1);

         --For error transaction will be rollbacked
         ROLLBACK;
         x_error_flag := 'Y';
      ELSE
         --COMMIT;
         x_list_header_id := x_modifier_list_rec.list_header_id;
      END IF;

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'List header id of Modifier Header After API call for Quote id: ' || x_list_header_id);

      ---End of Modifier Header Creation
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                          ,'End of Modifier Header Creation-----------'||'x_return_status'||x_return_status);
      --Create Modifier Lines
      --Process Modifier Line for all the related quote Item
    x_line_create_cnt := 0;
    IF x_return_status NOT IN ('E', 'U') THEN
      FOR r_quote_lines IN c_quote_lines
         LOOP
             x_manual_price_adjmnt := 0;
             x_manual_price_adjmnt := calc_manual_price_adjmnt(p_quote_header_id,r_quote_lines.quote_line_id);

          IF x_manual_price_adjmnt > 0 THEN -- Added on 12-dec-2013  so that it will not create 0 valued lines
             BEGIN
               p_api_version_number                    := 1;
               p_init_msg_list                         := fnd_api.g_true;
               p_return_values                         := fnd_api.g_true;
               p_commit                                := fnd_api.g_false;
               x_line_return_status                    := NULL;
               x_line_msg_count                        := NULL;
               x_line_msg_data                         := NULL;
               l_modifier_list_rec                     := apps.qp_modifiers_pub.g_miss_modifier_list_rec;
               l_modifier_list_val_rec                 := apps.qp_modifiers_pub.g_miss_modifier_list_val_rec;
               l_modifiers_tbl                         := apps.qp_modifiers_pub.g_miss_modifiers_tbl;
               l_modifiers_val_tbl                     := apps.qp_modifiers_pub.g_miss_modifiers_val_tbl;
               l_qualifiers_tbl                        := apps.qp_qualifier_rules_pub.g_miss_qualifiers_tbl;
               l_qualifiers_val_tbl                    := apps.qp_qualifier_rules_pub.g_miss_qualifiers_val_tbl;
               l_pricing_attr_tbl                      := apps.qp_modifiers_pub.g_miss_pricing_attr_tbl;
               l_pricing_attr_val_tbl                  := apps.qp_modifiers_pub.g_miss_pricing_attr_val_tbl;
               x_modifier_list_rec                     := apps.qp_modifiers_pub.g_miss_modifier_list_rec;
               x_modifier_list_val_rec                 := apps.qp_modifiers_pub.g_miss_modifier_list_val_rec;
               x_modifiers_tbl                         := apps.qp_modifiers_pub.g_miss_modifiers_tbl;
               x_modifiers_val_tbl                     := apps.qp_modifiers_pub.g_miss_modifiers_val_tbl;
               x_qualifiers_tbl                        := apps.qp_qualifier_rules_pub.g_miss_qualifiers_tbl;
               x_qualifiers_val_tbl                    := apps.qp_qualifier_rules_pub.g_miss_qualifiers_val_tbl;
               x_pricing_attr_tbl                      := apps.qp_modifiers_pub.g_miss_pricing_attr_tbl;
               x_pricing_attr_val_tbl                  := apps.qp_modifiers_pub.g_miss_pricing_attr_val_tbl;

                x_list_line_id                          := NULL;
                x_line_index                            :=  1;
                x_pricing_attr_index                    :=  1;

                l_modifiers_tbl(x_line_index).list_header_id := x_list_header_id;
                l_modifiers_tbl(x_line_index).list_line_type_code := g_list_line_type_code;
                l_modifiers_tbl(x_line_index).attribute1 := NULL;
                --l_MODIFIERS_tbl(x_line_index).automatic_flag:= 'Y';
                l_modifiers_tbl(x_line_index).modifier_level_code := g_modifier_level_code;
                l_modifiers_tbl(x_line_index).pricing_phase_id := 2;
                l_modifiers_tbl(x_line_index).product_precedence := g_product_precedence;
                --l_MODIFIERS_tbl(x_line_index).accrual_flag := 'N';
                l_modifiers_tbl(x_line_index).start_date_active := p_start_date_active; --r_quote_lines.start_date;
                l_MODIFIERS_tbl(x_line_index).end_date_active := p_start_date_active+to_number(r_quote_lines.max_days); --r_quote_lines.end_date;
                l_modifiers_tbl(x_line_index).arithmetic_operator := g_arithmetic_operator;
                --l_MODIFIERS_tbl(x_line_index).pricing_group_sequence := 1;
                l_modifiers_tbl(x_line_index).operand := r_quote_lines.unit_selling_price;   -- x_manual_price_adjmnt; -- New add after UIT
                l_modifiers_tbl(x_line_index).attribute3 := r_quote_lines.quote_line_id;     -- New add after UIT
                l_modifiers_tbl(x_line_index).operation := qp_globals.g_opr_create;
                l_modifiers_tbl(x_line_index).pricing_group_sequence := 1; --***
                l_modifiers_tbl(x_line_index).incompatibility_grp_code := 'LVL 1'; --***


                l_pricing_attr_tbl(x_pricing_attr_index).product_attribute_context := g_product_attr_context;
                l_pricing_attr_tbl(x_pricing_attr_index).product_attribute := g_product_attribute;
                l_pricing_attr_tbl(x_pricing_attr_index).product_attr_value := r_quote_lines.item;    ---- Item Id of 8-6TC
                l_pricing_attr_tbl(x_pricing_attr_index).modifiers_index := 1;
                l_pricing_attr_tbl(x_pricing_attr_index).operation := qp_globals.g_opr_create;
             EXCEPTION
               WHEN OTHERS THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                   ,'Error while creating price Modifier line for Quote id before API: ' || p_quote_header_id ||
                                    ' Error: ' || SQLCODE||':'||SQLERRM);
               x_error_flag := 'Y';
             END;
             BEGIN
                fnd_msg_pub.initialize;
                qp_modifiers_pub.process_modifiers
                                  (p_api_version_number                     => p_api_version_number
                                  ,p_init_msg_list                          => p_init_msg_list
                                  ,p_return_values                          => p_return_values
                                  ,p_commit                                 => p_commit
                                  ,x_return_status                          => x_line_return_status
                                  ,x_msg_count                              => x_line_msg_count
                                  ,x_msg_data                               => x_line_msg_data
                                  ,p_modifier_list_rec                      => l_modifier_list_rec
                                  ,p_modifier_list_val_rec                  => l_modifier_list_val_rec
                                  ,p_modifiers_tbl                          => l_modifiers_tbl
                                  ,p_modifiers_val_tbl                      => l_modifiers_val_tbl
                                  ,p_qualifiers_tbl                         => l_qualifiers_tbl
                                  ,p_qualifiers_val_tbl                     => l_qualifiers_val_tbl
                                  ,p_pricing_attr_tbl                       => l_pricing_attr_tbl
                                  ,p_pricing_attr_val_tbl                   => l_pricing_attr_val_tbl
                                  ,x_modifier_list_rec                      => x_modifier_list_rec
                                  ,x_modifier_list_val_rec                  => x_modifier_list_val_rec
                                  ,x_modifiers_tbl                          => x_modifiers_tbl
                                  ,x_modifiers_val_tbl                      => x_modifiers_val_tbl
                                  ,x_qualifiers_tbl                         => x_qualifiers_tbl
                                  ,x_qualifiers_val_tbl                     => x_qualifiers_val_tbl
                                  ,x_pricing_attr_tbl                       => x_pricing_attr_tbl
                                  ,x_pricing_attr_val_tbl                   => x_pricing_attr_val_tbl
                                  );
         EXCEPTION
            WHEN OTHERS THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                   ,'Error while creating price Modifier line for Quote id: ' || p_quote_header_id ||
                                    ' Error: ' || x_msg_data);

               ROLLBACK;
               x_error_flag := 'Y';
         END;


         IF x_line_return_status IN ('E', 'U') THEN
            x_line_msg_data   := '';
            x_line_msg_data1  := '';
            --x_error_record := x_error_record + 1;
            FOR k IN 1 .. x_line_msg_count
            LOOP
               x_line_msg_data  := oe_msg_pub.get(p_msg_index => k, p_encoded => 'F');
               x_line_msg_data1 := x_line_msg_data1 || substr(x_line_msg_data, 1, 200);
            END LOOP;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                ,'API Error occured while creating the Modifier line for Quote id: ' ||
                                 p_quote_header_id || ' Error: ' || x_line_msg_data1);
            ROLLBACK;
            x_error_flag := 'Y';
         ELSE
            x_list_line_id := x_modifiers_tbl(x_line_index).list_line_id;
            x_line_create_cnt := x_line_create_cnt + 1 ; -- Added for UIT
            --COMMIT;
         END IF;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                ,'list_line_id after creation of Modifier line for Quote id: ' ||
                                 p_quote_header_id || ' list_line_id: ' || x_list_line_id);
         -- End Line
         -- Create Line level Qualifier
      IF x_line_return_status NOT IN ('E', 'U') THEN

        BEGIN
           p_api_version_number                    := 1;
           p_init_msg_list                         := fnd_api.g_true;
           p_return_values                         := fnd_api.g_true;
           p_commit                                := fnd_api.g_false;
           x_quali_return_status                   := NULL;
           x_quali_msg_count                       := NULL;
           x_quali_msg_data                        := NULL;
           l_modifier_list_rec                     := apps.qp_modifiers_pub.g_miss_modifier_list_rec;
           l_modifier_list_val_rec                 := apps.qp_modifiers_pub.g_miss_modifier_list_val_rec;
           l_modifiers_tbl                         := apps.qp_modifiers_pub.g_miss_modifiers_tbl;
           l_modifiers_val_tbl                     := apps.qp_modifiers_pub.g_miss_modifiers_val_tbl;
           l_qualifiers_tbl                        := apps.qp_qualifier_rules_pub.g_miss_qualifiers_tbl;
           l_qualifiers_val_tbl                    := apps.qp_qualifier_rules_pub.g_miss_qualifiers_val_tbl;
           l_pricing_attr_tbl                      := apps.qp_modifiers_pub.g_miss_pricing_attr_tbl;
           l_pricing_attr_val_tbl                  := apps.qp_modifiers_pub.g_miss_pricing_attr_val_tbl;
           x_modifier_list_rec                     := apps.qp_modifiers_pub.g_miss_modifier_list_rec;
           x_modifier_list_val_rec                 := apps.qp_modifiers_pub.g_miss_modifier_list_val_rec;
           x_modifiers_tbl                         := apps.qp_modifiers_pub.g_miss_modifiers_tbl;
           x_modifiers_val_tbl                     := apps.qp_modifiers_pub.g_miss_modifiers_val_tbl;
           x_qualifiers_tbl                        := apps.qp_qualifier_rules_pub.g_miss_qualifiers_tbl;
           x_qualifiers_val_tbl                    := apps.qp_qualifier_rules_pub.g_miss_qualifiers_val_tbl;
           x_pricing_attr_tbl                      := apps.qp_modifiers_pub.g_miss_pricing_attr_tbl;
           x_pricing_attr_val_tbl                  := apps.qp_modifiers_pub.g_miss_pricing_attr_val_tbl;

           x_quali_index := 0;

      IF p_apply_to_all_ship_to = 'N' THEN
        FOR r_cust_ship_to IN c_cust_ship_to
         LOOP
           x_quali_index := x_quali_index + 1;

           l_qualifiers_tbl(x_quali_index).list_header_id := x_list_header_id;
           l_qualifiers_tbl(x_quali_index).list_line_id := x_list_line_id;
              --l_QUALIFIERS_tbl(x_quali_index).excluder_flag := 'N';
           l_qualifiers_tbl(x_quali_index).comparison_operator_code := '=';
           l_qualifiers_tbl(x_quali_index).qualifier_context := g_qualifier_context;
           l_qualifiers_tbl(x_quali_index).qualifier_attribute := g_qualifier_attribute;
           l_qualifiers_tbl(x_quali_index).qualifier_attr_value := to_char(r_cust_ship_to.site_use_id);  -- site_use_id  of HZ_CUST_SITE_USES_ALL
           l_qualifiers_tbl(x_quali_index).qualifier_grouping_no := -1;
           l_qualifiers_tbl(x_quali_index).operation := qp_globals.g_opr_create;
         END LOOP; -- Qualifier loop
       END IF;   -- p_apply_to_all_ship_to := 'N'

       IF p_apply_to_all_ship_to = 'Y' THEN

          FOR r_related_cust_info IN c_related_cust_info
           LOOP
           x_postal_code := NULL;
           xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                              ,'Account Number ' || r_related_cust_info.account_number );

           IF INSTR(r_related_cust_info.postal_code,'-',1,1) > 0 THEN
              BEGIN
               select SUBSTR(r_related_cust_info.postal_code,1,INSTR(r_related_cust_info.postal_code,'-',1,1)-1)
                 INTO x_postal_code
                 from dual;
             EXCEPTION
             WHEN OTHERS THEN
                x_postal_code := r_related_cust_info.postal_code;
            END;
           ELSE
              x_postal_code := r_related_cust_info.postal_code;
           END IF;

           IF (get_qualifiers_validated(r_related_cust_info.party_id
                                      ,r_related_cust_info.country
                                      ,r_related_cust_info.county
                                      ,r_related_cust_info.state
                                      ,x_postal_code
                                      ,r_related_cust_info.province
                                      ,r_related_cust_info.city
                                      ,r_related_cust_info.party_name
                                      ,r_related_cust_info.rel_typ
                                      ,p_resource_id)) THEN

            x_quali_index := x_quali_index + 1;

            l_qualifiers_tbl(x_quali_index).list_header_id := x_list_header_id;
            l_qualifiers_tbl(x_quali_index).list_line_id := x_list_line_id;
              --l_QUALIFIERS_tbl(x_quali_index).excluder_flag := 'N';
            l_qualifiers_tbl(x_quali_index).comparison_operator_code := '=';
            l_qualifiers_tbl(x_quali_index).qualifier_context := g_qualifier_context;
            l_qualifiers_tbl(x_quali_index).qualifier_attribute := g_qualifier_attribute;
            l_qualifiers_tbl(x_quali_index).qualifier_attr_value := to_char(r_related_cust_info.site_use_id);  -- site_use_id  of HZ_CUST_SITE_USES_ALL
            l_qualifiers_tbl(x_quali_index).qualifier_grouping_no := -1;
            l_qualifiers_tbl(x_quali_index).operation := qp_globals.g_opr_create;

          END IF;
       END LOOP;

       END IF; -- p_apply_to_all_ship_to := 'Y'

           -- Call API
           qp_modifiers_pub.process_modifiers
                                    (p_api_version_number                     => p_api_version_number
                                    ,p_init_msg_list                          => p_init_msg_list
                                    ,p_return_values                          => p_return_values
                                    ,p_commit                                 => p_commit
                                    ,x_return_status                          => x_quali_return_status
                                    ,x_msg_count                              => x_quali_msg_count
                                    ,x_msg_data                               => x_quali_msg_data
                                    ,p_modifier_list_rec                      => l_modifier_list_rec
                                    ,p_modifier_list_val_rec                  => l_modifier_list_val_rec
                                    ,p_modifiers_tbl                          => l_modifiers_tbl
                                    ,p_modifiers_val_tbl                      => l_modifiers_val_tbl
                                    ,p_qualifiers_tbl                         => l_qualifiers_tbl
                                    ,p_qualifiers_val_tbl                     => l_qualifiers_val_tbl
                                    ,p_pricing_attr_tbl                       => l_pricing_attr_tbl
                                    ,p_pricing_attr_val_tbl                   => l_pricing_attr_val_tbl
                                    ,x_modifier_list_rec                      => x_modifier_list_rec
                                    ,x_modifier_list_val_rec                  => x_modifier_list_val_rec
                                    ,x_modifiers_tbl                          => x_modifiers_tbl
                                    ,x_modifiers_val_tbl                      => x_modifiers_val_tbl
                                    ,x_qualifiers_tbl                         => x_qualifiers_tbl
                                    ,x_qualifiers_val_tbl                     => x_qualifiers_val_tbl
                                    ,x_pricing_attr_tbl                       => x_pricing_attr_tbl
                                    ,x_pricing_attr_val_tbl                   => x_pricing_attr_val_tbl
                                    );

         EXCEPTION
            WHEN OTHERS THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                   ,'Error while creating Modifier Line Qualifier for Quote id: ' || p_quote_header_id ||
                                    ' Error: ' || x_quali_msg_data);

               ROLLBACK;
               x_error_flag := 'Y';
         END;
         IF x_quali_return_status IN ('E', 'U') THEN
            x_quali_msg_data   := '';
            x_quali_msg_data1  := '';
            FOR k IN 1 .. x_quali_msg_count
            LOOP
               x_quali_msg_data  := oe_msg_pub.get(p_msg_index => k, p_encoded => 'F');
               x_quali_msg_data1 := x_quali_msg_data1 || substr(x_quali_msg_data, 1, 200);
            END LOOP;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                ,'API Error occured while creating the Modifier line qualifier for Quote id: ' ||
                                 p_quote_header_id || ' Error: ' || x_quali_msg_data1);
            ROLLBACK;
            x_error_flag := 'Y';
         END IF;
     -- Line level qualifier ends;
     -- Create Limit_Usage

      IF x_quali_return_status NOT IN ('E', 'U') AND p_limit_usage >0 THEN
        BEGIN
            p_api_version_number   := 1;
            p_init_msg_list        := fnd_api.g_true;
            p_return_values        := fnd_api.g_true;
            p_commit               := fnd_api.g_false;
            x_lmt_return_status    := NULL;
            x_lmt_msg_data         := NULL;
            x_lmt_msg_count        := NULL;

            l_limits_rec                            := apps.qp_limits_pub.G_MISS_LIMITS_REC;
            l_limits_val_rec                        := apps.qp_limits_pub.G_MISS_LIMITS_VAL_REC;
            l_limit_attrs_tbl                       := apps.qp_limits_pub.G_MISS_LIMIT_ATTRS_TBL;
            l_limit_attrs_val_tbl                   := apps.qp_limits_pub.G_MISS_LIMIT_ATTRS_VAL_TBL;
            l_limit_balances_tbl                    := apps.qp_limits_pub.G_MISS_LIMIT_BALANCES_TBL;
            l_limit_balances_val_tbl                := apps.qp_limits_pub.G_MISS_LIMIT_BALANCES_VAL_TBL;
            x_limits_rec                            := apps.qp_limits_pub.G_MISS_LIMITS_REC;
            x_limits_val_rec                        := apps.qp_limits_pub.G_MISS_LIMITS_VAL_REC;
            x_limit_attrs_tbl                       := apps.qp_limits_pub.G_MISS_LIMIT_ATTRS_TBL;
            x_limit_attrs_val_tbl                   := apps.qp_limits_pub.G_MISS_LIMIT_ATTRS_VAL_TBL;
            x_limit_balances_tbl                    := apps.qp_limits_pub.G_MISS_LIMIT_BALANCES_TBL;
            x_limit_balances_val_tbl                := apps.qp_limits_pub.G_MISS_LIMIT_BALANCES_VAL_TBL;


            l_limits_rec.limit_id := FND_API.G_MISS_NUM;
            l_limits_rec.list_header_id := x_list_header_id;
            l_limits_rec.list_line_id := x_list_line_id;
            l_limits_rec.limit_number := 1;
            l_limits_rec.basis := g_basis;
            l_limits_rec.organization_flag := 'N';
            l_limits_rec.limit_level_code := g_limit_level_code;
            --l_limits_rec.limit_exceed_action_code := 'HARD';
            l_limits_rec.amount := p_limit_usage;
            l_limits_rec.LIMIT_HOLD_FLAG := 'N'; --'Y';
            l_limits_rec.operation := QP_GLOBALS.g_opr_create;

           QP_Limits_PUB.Process_Limits
                  ( p_api_version_number     => 1.0
                  , p_init_msg_list          => p_init_msg_list
                  , p_return_values          => p_return_values
                  , p_commit                 => p_commit
                  , x_return_status          => x_lmt_return_status
                  , x_msg_count              => x_lmt_msg_count
                  , x_msg_data               => x_lmt_msg_data
                  , p_LIMITS_rec             => l_limits_rec
                  , p_LIMITS_val_rec         => l_limits_val_rec
                  , p_LIMIT_ATTRS_tbl        => l_limit_attrs_tbl
                  , p_LIMIT_ATTRS_val_tbl    => l_limit_attrs_val_tbl
                  , p_LIMIT_BALANCES_tbl     => l_limit_balances_tbl
                  , p_LIMIT_BALANCES_val_tbl => l_limit_balances_val_tbl
                  , x_LIMITS_rec             => x_limits_rec
                  , x_LIMITS_val_rec         => x_limits_val_rec
                  , x_LIMIT_ATTRS_tbl        => x_limit_attrs_tbl
                  , x_LIMIT_ATTRS_val_tbl    => x_limit_attrs_val_tbl
                  , x_LIMIT_BALANCES_tbl     => x_limit_balances_tbl
                  , x_LIMIT_BALANCES_val_tbl => x_limit_balances_val_tbl
                  );
          EXCEPTION
            WHEN OTHERS THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                   ,'Error while creating Modifier Line Limit_Usage for Quote id: ' || p_quote_header_id ||
                                    ' Error: ' || x_lmt_msg_data);

               ROLLBACK;
               x_error_flag := 'Y';
        END;
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                          ,'limit Creation------------------------x_lmt_return_status '||x_lmt_return_status);
        IF x_lmt_return_status IN ('E', 'U') THEN
            x_lmt_msg_data   := '';
            x_lmt_msg_data1  := '';
            --x_error_record := x_error_record + 1;
            FOR k IN 1 .. x_lmt_msg_count
            LOOP
               x_lmt_msg_data  := oe_msg_pub.get(p_msg_index => k, p_encoded => 'F');
               x_lmt_msg_data1 := x_lmt_msg_data1 || substr(x_lmt_msg_data, 1, 200);
            END LOOP;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                ,'API Error occured while creating the Modifier line Limit_Usage for Quote id: ' ||
                                 p_quote_header_id || ' Error: ' || x_lmt_msg_data);
            ROLLBACK;
            x_error_flag := 'Y';
         ELSE
            --COMMIT;
            NULL;
         END IF;
      END IF;   -- Limit Usage

      END IF;   -- Line level Qualifier
    END IF;     -- for 0 valued lines
    END LOOP; -- Line loop
   END IF; -- Line IF
   IF x_error_flag = 'N' AND x_line_create_cnt > 0 THEN
     COMMIT; -- Commit all at a time
   ELSE
     ROLLBACK;
     x_send_mail := 'N';
   END IF;
   EXCEPTION
      WHEN OTHERS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Error occured while creating the Modifier for Quote id: ' || p_quote_header_id ||
                              ' Error: ' || SQLERRM);
         ROLLBACK;
         x_send_mail := 'N';
   END create_modifier;
   /**************************************************************************************
   *
   *   PROCEDURE
   *     update_modifier
   *
   *   DESCRIPTION
   *   Update or add new Price List line from Quote Information
   *
   *   PARAMETERS
   *   ==========
   *   NAME               TYPE
   *   -----------------  --------
   *   p_quote_header_id   NUMBER
   *   p_quote_line_id     NUMBER
   *   p_party_name        VARCHAR2
   *   p_account_number    VARCHAR2
   *   p_site_use_id       NUMBER
   *   p_cust_acct_site_id NUMBER
   *   p_org_id            NUMBER
   *   p_cust_acct_id      NUMBER
   *   p_limit_usage       VARCHAR2
   *
   *   RETURN VALUE
   *   NA
   *
   *   PREREQUISITES
   *   NA
   *
   *   CALLED BY
   *   create_upd_price_list
   *
   **************************************************************************************/
   PROCEDURE update_modifier  (p_quote_header_id   IN NUMBER
                              ,p_quote_line_id     IN NUMBER
                              ,p_party_name        IN VARCHAR2
                              ,p_account_number    IN VARCHAR2
                              ,p_site_use_id       IN NUMBER
                              ,p_cust_acct_site_id IN NUMBER
                              ,p_org_id            IN NUMBER
                              ,p_cust_acct_id      IN NUMBER
                              ,p_limit_usage       IN VARCHAR2
                              ,p_list_header_id    IN NUMBER
                              ,p_start_date_active IN DATE
                              ,p_resource_id       IN NUMBER
                              ,p_bill_to_acct_id   IN NUMBER
                              ,p_apply_to_all_ship_to IN VARCHAR2) IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      --Cursor to get Quote Line Information
      CURSOR c_quote_lines IS
         SELECT DISTINCT aqh.attribute1 offer_type
                        ,aqh.attribute3 price_protected
                        ,aqh.attribute9 max_days
                        ,to_date(aqh.attribute4, 'RRRR/MM/DD HH24:MI:SS') quote_start_date
                        ,to_date(to_char(to_date(aqh.attribute4, 'RRRR/MM/DD HH24:MI:SS')+to_number(aqh.attribute9),'RRRR/MM/DD HH24:MI:SS'), 'RRRR/MM/DD HH24:MI:SS') quote_end_date
                        ,aql.inventory_item_id item
                        ,aql.uom_code
                        ,aql.line_list_price list_price
                        ,aql.line_quote_price unit_selling_price
                        ,aql.quote_line_id -- Added by partha
         -- added on 17th_Aug_2012 by Mou
           FROM aso_quote_lines_all   aql
               ,aso_quote_headers_all aqh
          WHERE aql.quote_header_id = p_quote_header_id
                AND aql.quote_header_id = aqh.quote_header_id
                AND (p_quote_line_id IS NULL OR aql.quote_line_id = p_quote_line_id)
                AND aqh.org_id = aql.org_id
                AND aql.org_id = p_org_id;

      --Cursor to get Customer Ship to Information
      CURSOR c_cust_ship_to IS
         SELECT hcsu.site_use_id
               ,hcsu.cust_acct_site_id
               ,hcsu.object_version_number
           FROM hz_cust_accounts       hca
               ,hz_party_sites         hps
               ,hz_cust_acct_sites_all hcas
               ,hz_cust_site_uses_all  hcsu
          WHERE hca.party_id = hps.party_id
                AND hcas.cust_account_id = hca.cust_account_id
                AND hcas.party_site_id = hps.party_site_id
                AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                AND hcas.cust_acct_site_id = p_cust_acct_site_id --- Added By Dhiren 04-Jan-2013
                AND hcsu.site_use_code = 'SHIP_TO'
                AND hcsu.status = 'A'
                AND hca.status = 'A'
                AND hcas.org_id = hcsu.org_id
                AND hca.cust_account_id IN
                (SELECT related_cust_account_id
                       FROM hz_cust_acct_relate_all hcar
                           ,hz_cust_accounts        hzca
                      WHERE hzca.account_number = p_account_number
                            AND hcar.cust_account_id = hzca.cust_account_id
                            AND g_apply_to_all_ship_to = 'Y'
                     UNION
                     SELECT cust_account_id
                       FROM hz_cust_accounts
                      WHERE account_number = p_account_number);

      --Cursor to get Price List Line Information
      CURSOR c_list_lines(p_item_id IN VARCHAR2)
      IS
         SELECT qll.list_line_id
               ,qll.start_date_active
               ,qll.end_date_active
               ,qll.operand
           FROM qp_list_lines         qll
               ,qp_pricing_attributes qpa
          WHERE qll.list_header_id = qpa.list_header_id
                AND qll.list_line_id = qpa.list_line_id
                AND qpa.list_header_id = p_list_header_id
                AND qpa.product_attribute_context = g_product_attr_context
                AND qpa.product_attribute = g_product_attribute
                AND qpa.product_attr_value = p_item_id
                AND
                qll.start_date_active = (SELECT MAX(qll1.start_date_active)
                                          FROM qp_list_lines qll1,
                                               qp_pricing_attributes qpa1
                                          WHERE  qpa1.list_header_id = qll1.list_header_id
                                             AND qpa1.list_line_id = qll1.list_line_id
                                             AND qpa1.list_header_id = p_list_header_id
                                             AND qpa1.product_attribute_context = g_product_attr_context
                                             AND qpa1.product_attribute = g_product_attribute
                                             AND qpa1.product_attr_value = p_item_id);

        --Cursor to get address information of related bill to site of quote
       CURSOR c_related_cust_info IS
         SELECT hp.party_name
               ,hca.account_number
               ,hcsu.site_use_id
               ,hcsu.cust_acct_site_id
               ,hcsu.price_list_id
               ,hl.country
               ,hl.postal_code
               ,hl.state
               ,hl.county
               ,hl.city
               ,hl.province
               ,hp.party_id
               ,hcsu.object_version_number
               ,DECODE(hca.cust_account_id,p_bill_to_acct_id,'MAIN','REL') rel_typ
           FROM hz_parties             hp
               ,hz_cust_accounts       hca
               ,hz_party_sites         hps
               ,hz_cust_acct_sites_all hcas
               ,hz_cust_site_uses_all  hcsu
               ,hz_locations           hl
          WHERE hp.party_id = hca.party_id
                AND hca.party_id = hps.party_id
                AND hps.location_id = hl.location_id
                AND hca.cust_account_id IN (SELECT related_cust_account_id
                                              FROM hz_cust_acct_relate_all
                                             WHERE cust_account_id = p_bill_to_acct_id
                                            UNION
                                            SELECT p_bill_to_acct_id
                                              FROM dual)
                AND hcas.cust_account_id = hca.cust_account_id
                AND hcas.party_site_id = hps.party_site_id
                AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                AND hcsu.site_use_code = 'SHIP_TO'
                AND hcsu.status = 'A'
                AND hca.status = 'A'
                AND hcas.org_id = hcsu.org_id
         --AND hcsu.org_id=p_org_id
          ORDER BY hcsu.price_list_id DESC;

        rec_list_lines                          c_list_lines%ROWTYPE;
        x_list_header_id                        NUMBER;
        x_list_line_id                          NUMBER;
        x_manual_price_adjmnt                   NUMBER;
        x_error_flag                            VARCHAR2(1) := 'N';
        x_postal_code                           VARCHAR2(100);
        x_qualifier_old_value                   NUMBER;
        x_line_endate_ret_stat                  VARCHAR2(1):= NULL;
        x_line_cr_ret_stat                      VARCHAR2(1):= NULL;
        x_quali_ret_status                      VARCHAR2(1):= NULL;
        x_limit_ret_status                      VARCHAR2(1):= NULL;
        x_quote_ln_start_date                   DATE;
        x_quote_ln_end_date                     DATE;
        x_line_create_cnt                       NUMBER := 0;

        x_line_upd_cnt                          NUMBER := 0; --Added by Debjani26Feb
   BEGIN

       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low ,'Entering into UPDATE modifier');

       x_updt_modifier_flag   := 'N';
       x_line_create_cnt      := 0;
       x_line_upd_cnt         := 0; --Added by Debjani 26FEB
      FOR r_quote_lines IN c_quote_lines
      LOOP

        x_line_endate_ret_stat := NULL;
        x_line_cr_ret_stat     := NULL;
        x_quali_ret_status     := NULL;
        x_limit_ret_status     := NULL;
        x_quote_ln_start_date  := NULL;
        x_quote_ln_end_date    := NULL;
       BEGIN

        x_quote_ln_start_date := p_start_date_active;
        x_quote_ln_end_date   := p_start_date_active + to_number(r_quote_lines.max_days);

        x_manual_price_adjmnt := 0;
        x_manual_price_adjmnt := calc_manual_price_adjmnt(p_quote_header_id,r_quote_lines.quote_line_id);

        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low ,'quote_line_id :::'||r_quote_lines.quote_line_id||' x_manual_price_adjmnt '||x_manual_price_adjmnt);

      IF x_manual_price_adjmnt > 0 THEN -- Added on 12-dec-2013  so that it will not create 0 valued lines

        OPEN c_list_lines(r_quote_lines.item);

        FETCH c_list_lines INTO rec_list_lines;

        IF c_list_lines%FOUND THEN -- main if

            -- Logic for end date old line create 1 new line
            --IF x_quote_ln_start_date > rec_list_lines.start_date_active AND x_quote_ln_end_date > rec_list_lines.end_date_active THEN
            IF TRUNC(x_quote_ln_start_date) > TRUNC(rec_list_lines.start_date_active)
               AND TRUNC(x_quote_ln_end_date) > TRUNC(rec_list_lines.end_date_active) THEN  --DEBJANI ADDED TRUNC ON FEB 26

                 IF TRUNC(rec_list_lines.end_date_active) > TRUNC(x_quote_ln_start_date) THEN --ADDED ON 26FEB DEBJANI
                    endate_modifier_line (p_quote_header_id
                                         ,p_list_header_id
                                         ,rec_list_lines.list_line_id
                                         ,x_quote_ln_start_date - 1
                                         ,NULL --DEBJANI on 26FEB
                                         ,x_line_endate_ret_stat
                                         );
                    --Update end date only when it overlaps else leave as-is
                 ELSE
                   x_line_endate_ret_stat := 'S';
                 END IF; --End of addition by DEBJANI 26FEB

               IF x_line_endate_ret_stat  NOT IN ('E','U') THEN
                  x_list_line_id :=0;
                  create_modifier_line( p_quote_header_id
                                       ,p_list_header_id
                                       ,x_quote_ln_start_date
                                       ,x_quote_ln_end_date
                                       ,r_quote_lines.unit_selling_price --x_manual_price_adjmnt New add after UIT
                                       ,r_quote_lines.item
                                       ,r_quote_lines.quote_line_id  -- New add after UIT
                                       ,x_list_line_id
                                       ,x_line_cr_ret_stat
                                  );


               IF x_line_cr_ret_stat  NOT IN ('E','U') AND x_list_line_id <> 0 THEN

                    x_line_create_cnt := x_line_create_cnt + 1; -- add after UIT
                    create_qualifier( p_quote_header_id
                                     ,p_cust_acct_site_id
                                     ,p_account_number
                                     ,p_bill_to_acct_id
                                     ,p_apply_to_all_ship_to
                                     ,p_list_header_id
                                     ,x_list_line_id
                                     ,p_resource_id
                                     ,x_quali_ret_status
                                   );

               IF x_quali_ret_status  NOT IN ('E','U') AND p_limit_usage >0 THEN
                       create_limit(  p_quote_header_id
                                     ,p_list_header_id
                                     ,x_list_line_id
                                     ,p_limit_usage
                                     ,x_limit_ret_status
                                     );

               END IF;

              END IF; -- Qualifier
             END IF; -- for line
           END IF; -- for end date old line create 1 new line

           -- Logic for end date old line create 2 new line
          x_qualifier_old_value := NULL;
         -- IF x_quote_ln_start_date > rec_list_lines.start_date_active AND x_quote_ln_end_date < rec_list_lines.end_date_active THEN
          IF TRUNC(x_quote_ln_start_date) > TRUNC(rec_list_lines.start_date_active)
             AND TRUNC(x_quote_ln_end_date) < TRUNC(rec_list_lines.end_date_active) THEN  ---DEBJANI ADDED TRUNC ON FEB 26

                 x_qualifier_old_value := rec_list_lines.operand;

                 endate_modifier_line (p_quote_header_id
                                      ,p_list_header_id
                                      ,rec_list_lines.list_line_id
                                      ,x_quote_ln_start_date - 1
                                      ,NULL --DEBJANI on 26FEB
                                      ,x_line_endate_ret_stat
                                      );

                 IF x_line_endate_ret_stat  NOT IN ('E','U') THEN
                    x_list_line_id :=0;
                    create_modifier_line( p_quote_header_id
                                       ,p_list_header_id
                                       ,x_quote_ln_start_date
                                       ,x_quote_ln_end_date
                                       ,r_quote_lines.unit_selling_price -- x_manual_price_adjmnt New add after UIT
                                       ,r_quote_lines.item
                                       ,r_quote_lines.quote_line_id  -- New add after UIT
                                       ,x_list_line_id
                                       ,x_line_cr_ret_stat
                                  );
                   IF x_line_cr_ret_stat  NOT IN ('E','U') AND x_list_line_id <> 0 THEN
                    x_line_create_cnt := x_line_create_cnt + 1; -- add after UIT
                    create_qualifier( p_quote_header_id
                                     ,p_cust_acct_site_id
                                     ,p_account_number
                                     ,p_bill_to_acct_id
                                     ,p_apply_to_all_ship_to
                                     ,p_list_header_id
                                     ,x_list_line_id
                                     ,p_resource_id
                                     ,x_quali_ret_status
                                   );
                    IF x_quali_ret_status  NOT IN ('E','U') AND p_limit_usage >0 THEN
                       create_limit(  p_quote_header_id
                                     ,p_list_header_id
                                     ,x_list_line_id
                                     ,p_limit_usage
                                     ,x_limit_ret_status
                                     );

                     END IF;
                  END IF;
                END IF;

                -- For 2nd Line
                x_line_cr_ret_stat     := NULL;
                x_quali_ret_status     := NULL;
                x_limit_ret_status     := NULL;

                IF x_line_endate_ret_stat  NOT IN ('E','U') THEN

                    x_list_line_id :=0;
                    create_modifier_line( p_quote_header_id
                                       ,p_list_header_id
                                       ,x_quote_ln_end_date + 1
                                       ,rec_list_lines.end_date_active
                                       ,x_qualifier_old_value
                                       ,r_quote_lines.item
                                       ,r_quote_lines.quote_line_id  -- New add after UIT
                                       ,x_list_line_id
                                       ,x_line_cr_ret_stat
                                  );
                   IF x_line_cr_ret_stat  NOT IN ('E','U') AND x_list_line_id <> 0 THEN

                    x_line_create_cnt := x_line_create_cnt + 1; -- add after UIT
                    create_qualifier( p_quote_header_id
                                     ,p_cust_acct_site_id
                                     ,p_account_number
                                     ,p_bill_to_acct_id
                                     ,p_apply_to_all_ship_to
                                     ,p_list_header_id
                                     ,x_list_line_id
                                     ,p_resource_id
                                     ,x_quali_ret_status
                                   );
                    IF x_quali_ret_status  NOT IN ('E','U') AND p_limit_usage >0 THEN
                       create_limit(  p_quote_header_id
                                     ,p_list_header_id
                                     ,x_list_line_id
                                     ,p_limit_usage
                                     ,x_limit_ret_status
                                     );

                     END IF;
                  END IF;
                END IF;
          END IF;  -- Logic for end date old line create 2 new line

          -----DEBJANI Following code added to update existing line with end date/price 26Feb-----
          IF (TRUNC(x_quote_ln_start_date) = TRUNC(rec_list_lines.start_date_active) AND TRUNC(x_quote_ln_end_date) <> TRUNC(rec_list_lines.end_date_active))
          OR ((TRUNC(x_quote_ln_start_date) = TRUNC(rec_list_lines.start_date_active) AND r_quote_lines.unit_selling_price <> rec_list_lines.operand))
          THEN

                 endate_modifier_line (p_quote_header_id
                                      ,p_list_header_id
                                      ,rec_list_lines.list_line_id
                                      ,x_quote_ln_end_date
                                      ,r_quote_lines.unit_selling_price --DEBJANI 26 FEB
                                      ,x_line_endate_ret_stat

                                      );

                   x_line_upd_cnt := x_line_upd_cnt+1;
           END IF;
          ----DEBJANI -End of code added to upd existig line26Feb---

    ELSIF c_list_lines%NOTFOUND   THEN                      ------------------------------ Main if
              xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Entering into CREATION of Modifier line inside update_modifier procedure');

                x_list_line_id :=0;
               create_modifier_line( p_quote_header_id
                                     ,p_list_header_id
                                     ,x_quote_ln_start_date
                                     ,x_quote_ln_end_date
                                     ,r_quote_lines.unit_selling_price -- x_manual_price_adjmnt New add after UIT
                                     ,r_quote_lines.item
                                     ,r_quote_lines.quote_line_id  -- New add after UIT
                                     ,x_list_line_id
                                     ,x_line_cr_ret_stat
                                  );
               -- Create Line level Qualifier
               IF x_line_cr_ret_stat  NOT IN ('E','U') AND x_list_line_id <> 0 THEN
                    x_line_create_cnt := x_line_create_cnt + 1; -- add after UIT
                    create_qualifier( p_quote_header_id
                                     ,p_cust_acct_site_id
                                     ,p_account_number
                                     ,p_bill_to_acct_id
                                     ,p_apply_to_all_ship_to
                                     ,p_list_header_id
                                     ,x_list_line_id
                                     ,p_resource_id
                                     ,x_quali_ret_status
                                   );
                 -- Create Limit_Usage
                 IF x_quali_ret_status  NOT IN ('E','U') AND p_limit_usage >0 THEN
                       create_limit(  p_quote_header_id
                                     ,p_list_header_id
                                     ,x_list_line_id
                                     ,p_limit_usage
                                     ,x_limit_ret_status
                                     );

                  END IF;
             END IF;   -- Qualifier
      END IF; ------------------------------------------------------Main If
      CLOSE c_list_lines;

      END IF; -- for 0 valued line
      END;
      END LOOP;
      IF (x_updt_modifier_flag = 'N' AND x_line_create_cnt>0 )
         OR (x_updt_modifier_flag = 'N' AND x_line_upd_cnt>0) THEN --Debjani condition added on 26FebTHEN
         COMMIT;
      ELSE
         ROLLBACK;
         x_send_mail := 'N';
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                             ,'Modifier line not created/updated  for Quote id(Inside update_modifier): ' || p_quote_header_id ||
                              ' OTHERS Error: ' || SQLERRM);

         ROLLBACK;
         x_send_mail := 'N';
   END update_modifier;

   -- Check for modifier existance
   FUNCTION modifier_exists(p_cust_acct_id NUMBER)
            RETURN NUMBER IS

     x_party_name      VARCHAR2(400);
     x_acct_number     VARCHAR2(30);
     x_list_header_id  NUMBER;
     BEGIN
        x_list_header_id := NULL;
        x_acct_number    := NULL;
        x_party_name     := NULL;


        SELECT hp.party_name,hca.account_number
            INTO x_party_name,x_acct_number
            from hz_parties hp,
                 hz_cust_accounts_all hca
            where hp.party_id = hca.party_id
                 AND hca.cust_account_id =  p_cust_acct_id;

          x_modifier_name := 'DRF-DISCOUNT-'||x_acct_number;

          BEGIN
          SELECT list_header_id INTO x_list_header_id
                 FROM QP_LIST_HEADERS
                 WHERE name  = x_modifier_name;

           xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                            ,'List_header_id derived: ' || x_list_header_id ||
                                             ' for Modifier: ' || x_modifier_name);
           return(x_list_header_id);
         EXCEPTION
          WHEN OTHERS THEN
             xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                            ,'List_header_id not found, Modifier doesnot exist ');
             return(-1);
          END;
       EXCEPTION
          WHEN OTHERS THEN
             xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                            ,'Major Error : Unable to derive party_name and account_number ');
             return(-1);
     END modifier_exists;


   /**************************************************************************************
   *
   *   PROCEDURE
   *     create_upd_price_list
   *
   *   DESCRIPTION
   *   Main procedure to Create or Update Informal Price List
   *
   *   PARAMETERS
   *   ==========
   *   NAME               TYPE             DESCRIPTION
   *   -----------------  --------         -----------------------------------------------
   *   itemtype           VARCHAR2         Workflow Item Type
   *   itemkey            VARCHAR2         Workflow Item Key
   *   actid              NUMBER           Activity Identification
   *   funcmode           VARCHAR2         Function Mode
   *   resultout          VARCHAR2         Return Result
   *
   *   RETURN VALUE
   *   NA
   *
   *   PREREQUISITES
   *   NA
   *
   *   CALLED BY
   *   ASO Approval Workflow
   *
   **************************************************************************************/
   PROCEDURE create_upd_price_list(itemtype  IN VARCHAR2
                                  ,itemkey   IN VARCHAR2
                                  ,actid     IN NUMBER
                                  ,funcmode  IN VARCHAR2
                                  ,resultout OUT NOCOPY VARCHAR2) IS
      --Cursor to get Quote Header information
      CURSOR c_quote_hdr(p_header_id IN NUMBER) IS
       SELECT aqha.quote_header_id
               ,aqha.org_id
               ,aqha.party_id
               ,aqha.cust_account_id
               ,aqha.sold_to_party_site_id
               ,aqha.invoice_to_party_id
               ,aqha.invoice_to_cust_party_id
               ,aqha.invoice_to_cust_account_id
               ,aqha.invoice_to_party_site_id
               ,aqha.currency_code
               ,aqha.resource_id
               ,aqha.attribute_category CONTEXT
               ,aqha.attribute7   apply_to_all_ship_to
               ,aqha.attribute10  limit_usage           --- Added by partha
               ,to_date(aqha.attribute4, 'RRRR/MM/DD HH24:MI:SS') quote_start_date
               ,aosh.ship_to_party_site_id
           FROM aso_quote_headers_all    aqha
               ,aso_oa_shipments_hdr_v   aosh
          WHERE aqha.quote_header_id = p_header_id
            AND aqha.quote_header_id = aosh.quote_header_id;

      r_quote_headers c_quote_hdr%ROWTYPE;
      --Cursor to get Ship to price list
      CURSOR c_customer_info(p_party_id NUMBER, p_cust_acct_id NUMBER, p_party_site_id NUMBER, p_org_id NUMBER) IS
         SELECT hp.party_name
               ,hca.account_number
               ,hcsu.site_use_id
               ,hcsu.cust_acct_site_id
               ,hcsu.price_list_id
               ,hl.address1
               ,hl.address2
               ,hl.postal_code
               ,hcsu.object_version_number
           FROM hz_parties             hp
               ,hz_cust_accounts       hca
               ,hz_party_sites         hps
               ,hz_cust_acct_sites_all hcas
               ,hz_cust_site_uses_all  hcsu
               ,hz_locations           hl
          WHERE hp.party_id = hca.party_id
                AND hca.party_id = hps.party_id
                AND hps.location_id = hl.location_id
                AND hcas.cust_account_id = hca.cust_account_id
                AND hcas.party_site_id = hps.party_site_id
                AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                AND hcsu.site_use_code = 'SHIP_TO'
                AND hcsu.status = 'A'
                AND hca.status = 'A'
                AND hcas.org_id = hcsu.org_id
                AND hca.party_id = p_party_id
                AND hca.cust_account_id = p_cust_acct_id
                AND hps.party_site_id = p_party_site_id
                AND hcsu.org_id = p_org_id;

      r_cust_info       c_customer_info%ROWTYPE;
      x_quote_header_id NUMBER;
      x_error_code      NUMBER := xx_emf_cn_pkg.cn_success;
      x_modifier_exists NUMBER;
      x_modifier_type   VARCHAR2(25);
      x_st_date_active  DATE;
   BEGIN
      --Set emf envirnment
      x_error_code := xx_emf_pkg.set_env(g_process_name);
      --Assign Global Variables
      assign_global_var;
      --
      x_modifier_exists   := NULL;
      x_modifier_name     := NULL;
      x_st_date_active    := NULL;
      x_send_mail         := 'Y';

      IF funcmode = 'RUN' THEN
         -- Changed by Kunal to make compatible if called from package
         IF (itemtype IS NULL) THEN
            -- Its a call from package, Quote Header id will be in ITEMKEY field
            x_quote_header_id := itemkey;
         ELSE
            --Get the quote header id
            x_quote_header_id := wf_engine.getitemattrnumber(itemtype, itemkey, 'QTEHDRID');
         END IF;

         OPEN c_quote_hdr(x_quote_header_id);
         FETCH c_quote_hdr
            INTO r_quote_headers;
         CLOSE c_quote_hdr;

         --Get customer information from Quote Headers
         OPEN c_customer_info(r_quote_headers.party_id
                             ,r_quote_headers.cust_account_id
                             ,r_quote_headers.ship_to_party_site_id
                             ,r_quote_headers.org_id);
         FETCH c_customer_info
            INTO r_cust_info;
         CLOSE c_customer_info;

         --If Quote header's DFF apply to all ship to is No
         IF r_quote_headers.apply_to_all_ship_to = 'No' THEN
            g_apply_to_all_ship_to := 'N';
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                ,'apply_to_all_ship_to is no for  Quote_header_id: ' || x_quote_header_id);
         ELSIF r_quote_headers.apply_to_all_ship_to = 'Yes' THEN
            g_apply_to_all_ship_to := 'Y';
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                ,'apply_to_all_ship_to is Yes for  Quote_header_id: ' || x_quote_header_id);
         END IF;

             -- find start date active
             x_st_date_active  :=  get_start_dt_active(r_quote_headers.quote_header_id
                                                      ,r_quote_headers.quote_start_date
                                                      ,r_quote_headers.org_id);
             xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                ,'Quote start date for  Quote_header_id: ' || x_quote_header_id||' is : '||x_st_date_active);
             IF x_st_date_active IS NULL THEN
                 xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                ,'Can not derive quote start date for  Quote_header_id: ' || x_quote_header_id);
                 RETURN;
             END IF;

             x_modifier_exists := modifier_exists(r_quote_headers.cust_account_id);

             IF x_modifier_exists = -1 THEN
                 --Create modifier for the ship to site
                  create_modifier(r_quote_headers.quote_header_id
                                ,NULL
                                ,r_cust_info.party_name
                                ,r_cust_info.account_number
                                ,r_cust_info.site_use_id
                                ,r_cust_info.cust_acct_site_id
                                ,r_quote_headers.org_id
                                ,r_quote_headers.cust_account_id
                                ,r_quote_headers.limit_usage
                                ,x_st_date_active
                                ,r_quote_headers.resource_id
                                ,r_quote_headers.invoice_to_cust_account_id
                                ,g_apply_to_all_ship_to);
                ELSIF  x_modifier_exists >= 0 THEN
                   -- Create modifier line
                  update_modifier(r_quote_headers.quote_header_id
                                ,NULL
                                ,r_cust_info.party_name
                                ,r_cust_info.account_number
                                ,r_cust_info.site_use_id
                                ,r_cust_info.cust_acct_site_id
                                ,r_quote_headers.org_id
                                ,r_quote_headers.cust_account_id
                                ,r_quote_headers.limit_usage
                                ,x_modifier_exists
                                ,x_st_date_active
                                ,r_quote_headers.resource_id
                                ,r_quote_headers.invoice_to_cust_account_id
                                ,g_apply_to_all_ship_to
                                );

               END IF;

         IF x_send_mail = 'Y' THEN
           send_mail(x_quote_header_id);
         END IF;
      END IF; --IF funcmode = 'RUN'

   EXCEPTION
     WHEN OTHERS THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                                ,'Major error in create_upd_price_list : ' || 'Error :'||SQLERRM);

   END create_upd_price_list;


END xx_aso_price_list_ext_pkg;
/
