DROP PACKAGE BODY APPS.XX_H2R_UPDATE_EXPENSE_ACCOUNT;

CREATE OR REPLACE PACKAGE BODY APPS."XX_H2R_UPDATE_EXPENSE_ACCOUNT" AS
/* $Header: XXH2RUPDEXPACCT.pkb 1.0.0 2012/04/02 00:00:00$ */
--=============================================================================
  -- Created By     : Arjun.K
  -- Creation Date  : 02-APR-2012
  -- Filename       : XXH2RUPDEXPACCT.pkb
  -- Description    : Package body for update expense account extension.

  -- Change History:

  -- Date          Version#    Name                Remarks
  -- -----------   --------    ---------------     ----------------------------
  -- 07-MAR-2012   1.0         Arjun.K             Initial Development.
  -- 01-Dec-2013  2.0         Shekhar N           Updated to pass SOFT_CODING_KEYFLEX_ID as IN/OUT Parameter CC003095
  -- 20-Jul-2014  3.0         Jaya Jayaraj        Updated for CC#7188
--=============================================================================

   ----------------------------------------------------------------------------
   --------------------------< xx_upd_exp_acct >-------------------------------
   ----------------------------------------------------------------------------
   PROCEDURE xx_upd_exp_acct
                 (o_errbuf              OUT   VARCHAR2
                 ,o_retcode             OUT   VARCHAR2
                 ,p_business_group_id    IN   NUMBER
                 )
   IS

       x_error_code                   NUMBER         := xx_emf_cn_pkg.CN_SUCCESS;
       x_error_message                VARCHAR2(2000) := NULL;
       x_check_segment                NUMBER         := 0;
       x_count                        NUMBER         := 0;
       x_total_count                  NUMBER         := 0;
       x_success_count                NUMBER         := 0;
       x_error_count                  NUMBER         := 0;

       x_flex_code                    fnd_id_flex_structures.id_flex_code%TYPE;
       x_flex_num                     fnd_id_flex_structures.id_flex_num%TYPE;
       x_conc_seg_delimiter           fnd_id_flex_structures.concatenated_segment_delimiter%TYPE;
       x_appl_name                    fnd_application.application_short_name%TYPE;
       x_ccid                         NUMBER;

       x_conc_segment                 VARCHAR2(240);
       x_effective_start_date         DATE;
       x_object_version_number        NUMBER;
       x_cagr_grade_def_id            NUMBER;
       x_cagr_concatenated_segments   VARCHAR2 (240);
       x_concatenated_segments        VARCHAR2 (240);
       x_soft_coding_keyflex_id       NUMBER;
       x_comment_id                   NUMBER;
       x_effective_end_date           DATE;
       x_no_managers_warning          BOOLEAN;
       x_other_manager_warning        BOOLEAN;
       x_hourly_salaried_warning      BOOLEAN;
       x_gsp_post_process_warning     VARCHAR2 (100);
       l_ledger                       VARCHAR2(100);
       l_set_of_book_id               VARCHAR2(20);       
       l_org_now_no_manager_warning   BOOLEAN;
       l_effective_start_date         DATE;
       l_effective_end_date           DATE;
       l_comment_id                   NUMBER(20);  
       l_no_managers_warning          BOOLEAN;
       l_other_manager_warning        BOOLEAN;
       l_soft_coding_keyflex_id       NUMBER(20);
       l_concatenated_segments        VARCHAR2(200);
       l_hourly_salaried_warning      BOOLEAN;
       

       -- Cursor to fetch expense accounts
       CURSOR cur_xx_upd_exp_acct (cp_business_group_id NUMBER)
       IS
          SELECT papf.person_id
                ,paaf.assignment_id
                ,papf.business_group_id
                ,paaf.organization_id
                ,pptf.person_type_id
                ,ppt.user_person_type
                ,ppt.system_person_type -- Added in July 2014
                ,haou.name "ORGANIZATION_NAME"
                ,haou.cost_allocation_keyflex_id "COSTING_INFO"
                ,pcak.segment1 "COSTING_INFO1"
                ,pcak.segment2 "COSTING_INFO2"
                ,pcak.segment3 "COSTING_INFO3"
                ,pcak.segment4 "COSTING_INFO4"
                ,pcak.segment5 "COSTING_INFO5"
                ,pcak.segment6 "COSTING_INFO6"
                ,pcak.segment7 "COSTING_INFO7"
                ,pcak.segment8 "COSTING_INFO8"
                ,pcak.segment8 "COSTING_INFO9"
                ,papf.full_name "EMPLOYEE_NAME"
                ,paaf.assignment_number
                ,paaf.change_reason
                ,paaf.assignment_status_type_id
                ,paaf.object_version_number
                ,paaf.effective_start_date "ASSIGNMENT_START_DATE"
                ,paaf.set_of_books_id
                ,paaf.default_code_comb_id "EXP_ACCT"
                ,paaf.SOFT_CODING_KEYFLEX_ID -- Added as a part of CC 3095
                ,gcc.segment1 "EXP_ACCT1"
                ,gcc.segment2 "EXP_ACCT2"
                ,gcc.segment3 "EXP_ACCT3"
                ,gcc.segment4 "EXP_ACCT4"
                ,gcc.segment5 "EXP_ACCT5"
                ,gcc.segment6 "EXP_ACCT6"
                ,gcc.segment7 "EXP_ACCT7"
                ,gcc.segment8 "EXP_ACCT8"
                ,gcc.segment9 "EXP_ACCT9"
            FROM per_all_people_f papf
                ,per_all_assignments_f paaf
                ,gl_code_combinations gcc
                ,per_person_types ppt
                ,per_person_type_usages_f pptf
                ,hr_all_organization_units haou
                ,pay_cost_allocation_keyflex pcak
           WHERE papf.person_id = paaf.person_id
             AND papf.business_group_id = paaf.business_group_id
             AND papf.business_group_id = cp_business_group_id
             AND paaf.primary_flag ='Y'
             AND papf.business_group_id = ppt.business_group_id
             AND ppt.active_flag='Y'
             AND papf.person_id = pptf.person_id
             AND pptf.person_type_id = ppt.person_type_id
             AND ppt.system_person_type in ('EMP','CWK')
             AND TRUNC(SYSDATE) BETWEEN papf.effective_start_date AND papf.effective_end_date
             AND TRUNC(SYSDATE) BETWEEN paaf.effective_start_date AND paaf.effective_end_date
             AND TRUNC(SYSDATE) BETWEEN pptf.effective_start_date AND pptf.effective_end_date
             AND paaf.default_code_comb_id = gcc.code_combination_id(+)
             AND papf.business_group_id = haou.business_group_id
             AND paaf.organization_id = haou.organization_id
             AND haou.cost_allocation_keyflex_id= pcak.cost_allocation_keyflex_id(+)
             AND NVL(UPPER(papf.attribute5),'YES')!='NO'
             ORDER BY ppt.system_person_type desc;  -- Added in Jul 2014 
     
   
 -- This cursor has been added in July 2014 to derive the correct ledger based on Company segment of the Cost String          
     CURSOR csr_get_ledger(p_balancing_segment VARCHAR2)
     IS
     select ledger_name
     ,flex_segment_value balancing_segment 
     from XLE_LE_OU_LEDGER_V xlol
     ,gl_legal_entities_bsvs gleb
     where xlol.LEGAL_ENTITY_ID = gleb.LEGAL_ENTITY_ID
     and flex_segment_value = p_balancing_segment
     UNION
     SELECT name ledger_name
     ,SEGMENT_VALUE balancing_segment
     FROM gl_ledgers gl
     ,gl_ledger_norm_seg_vals glnsv
     where gl.ledger_id = glnsv.ledger_id
     and segment_type_code = 'B'
     AND glnsv.legal_entity_id is null
     and SEGMENT_VALUE  = p_balancing_segment;


   BEGIN
      o_retcode := xx_emf_cn_pkg.CN_SUCCESS;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Before Setting Environment');

      -- Emf Env initialization
      x_error_code := xx_emf_pkg.set_env;

      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Starting main process with the following parameters');
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_business_group_id '|| p_business_group_id);

      -- Query to fetch flex details based on accounting
      BEGIN
         SELECT b.id_flex_code
               ,b.id_flex_num
               ,b.concatenated_segment_delimiter
               ,a.application_short_name
           INTO x_flex_code
               ,x_flex_num
               ,x_conc_seg_delimiter
               ,x_appl_name
           FROM fnd_id_flex_structures b
               ,fnd_application a
          WHERE b.enabled_flag = 'Y'
            AND UPPER(b.id_flex_structure_code) = g_accounting_flex
            AND b.application_id= a.application_id
            AND b.dynamic_inserts_allowed_flag='Y';
      EXCEPTION
      WHEN OTHERS THEN
         x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
         x_error_message := 'Flex Structure '||g_accounting_flex||' not found.';
         xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_high
                         ,p_category => 'FLEX-DV01'
                         ,p_error_text => 'E:'||x_error_message
                         );
      END;

      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Before loop c_xx_upd_exp_acct');
      FOR c_xx_upd_exp_acct IN cur_xx_upd_exp_acct (p_business_group_id)
      LOOP
         --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside loop c_xx_upd_exp_acct');
         x_error_code     := xx_emf_cn_pkg.CN_SUCCESS;
         x_error_message  := NULL;
         x_check_segment  := 0;
         x_conc_segment   := NULL;
         x_ccid           := 0;

         --Check condition for HR Organization Costing String
         IF c_xx_upd_exp_acct.costing_info IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            x_error_message := 'The default cost string is missing for the HR Organization.';
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                             p_category => 'COSTING_INFO',
                             p_error_text => 'E:'||x_error_message,
                             p_record_identifier_1 => c_xx_upd_exp_acct.employee_name,
                             p_record_identifier_2 => c_xx_upd_exp_acct.organization_name,
                             p_record_identifier_3 => c_xx_upd_exp_acct.assignment_start_date
                            );
         END IF;
         
         l_ledger := NULL;
        
        -- The below for loop has been added in July 2014 to derive the set of book id for the given ledger
         FOR rec_get_ledger IN csr_get_ledger(c_xx_upd_exp_acct.costing_info1)
         LOOP
             l_ledger := rec_get_ledger.ledger_name;
             
             BEGIN
                     select DISTINCT SET_OF_BOOKS_ID
                     into l_set_of_book_id
                     from gl_sets_of_books
                     where name = l_ledger;
                 EXCEPTION
                     when others then
                     l_set_of_book_id := NULL;
             END;
         END LOOP;    

         --Check condition for Ledger ID
         IF l_set_of_book_id IS NULL
         THEN
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            x_error_message := 'Ledger is missing for the Employee because no valid costing defined for HR Org.';
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                             p_category => 'EXP_ACCT',
                             p_error_text => 'E:'||x_error_message,
                             p_record_identifier_1 => c_xx_upd_exp_acct.employee_name,
                             p_record_identifier_2 => c_xx_upd_exp_acct.organization_name,
                             p_record_identifier_3 => c_xx_upd_exp_acct.assignment_start_date
                            );
         END IF;
        

         --Check for change in individual segments
         IF x_error_code = xx_emf_cn_pkg.CN_SUCCESS THEN
            IF NVL(c_xx_upd_exp_acct.costing_info1,0) <> NVL(c_xx_upd_exp_acct.exp_acct1,0) THEN
               x_check_segment :=1;
            END IF;

            IF NVL(c_xx_upd_exp_acct.costing_info2,0) <> NVL(c_xx_upd_exp_acct.exp_acct2,0) THEN
               x_check_segment :=1;
            END IF;

            IF NVL(c_xx_upd_exp_acct.costing_info3,0) <> NVL(c_xx_upd_exp_acct.exp_acct3,0) THEN
               x_check_segment :=1;
            END IF;

            IF NVL(c_xx_upd_exp_acct.costing_info4,0) <> NVL(c_xx_upd_exp_acct.exp_acct4,0) THEN
               x_check_segment :=1;
            END IF;

            IF NVL(c_xx_upd_exp_acct.costing_info5,0) <> NVL(c_xx_upd_exp_acct.exp_acct5,0) THEN
               x_check_segment :=1;
            END IF;

            IF NVL(c_xx_upd_exp_acct.costing_info6,0) <> NVL(c_xx_upd_exp_acct.exp_acct6,0) THEN
               x_check_segment :=1;
            END IF;

            IF NVL(c_xx_upd_exp_acct.costing_info7,0) <> NVL(c_xx_upd_exp_acct.exp_acct7,0) THEN
               x_check_segment :=1;
            END IF;

            IF NVL(c_xx_upd_exp_acct.costing_info8,0) <> NVL(c_xx_upd_exp_acct.exp_acct8,0) THEN
               x_check_segment :=1;
            END IF;
            
            -- The below IF statement has been added in July 2014 to check whether change in ledger on assignment is necessary.
            
        IF NVL(c_xx_upd_exp_acct.set_of_books_id,0) <> NVL(l_set_of_book_id,0) THEN
           x_check_segment :=1;
            END IF;
         END IF;

         IF x_check_segment = 1 AND x_error_code = xx_emf_cn_pkg.CN_SUCCESS THEN

            x_conc_segment := c_xx_upd_exp_acct.costing_info1||x_conc_seg_delimiter||
                              c_xx_upd_exp_acct.costing_info2||x_conc_seg_delimiter||
                              c_xx_upd_exp_acct.costing_info3||x_conc_seg_delimiter||
                              c_xx_upd_exp_acct.costing_info4||x_conc_seg_delimiter||
                              c_xx_upd_exp_acct.costing_info5||x_conc_seg_delimiter||
                              c_xx_upd_exp_acct.costing_info6||x_conc_seg_delimiter||
                              c_xx_upd_exp_acct.costing_info7||x_conc_seg_delimiter||
                              c_xx_upd_exp_acct.costing_info8;

            x_ccid:=fnd_flex_ext.get_ccid(x_appl_name
                                         ,x_flex_code
                                         ,x_flex_num
                                        -- ,TO_CHAR(TRUNC(SYSDATE))
                                        ,fnd_date.date_to_canonical(SYSDATE) -- Added in July 2014
                                         ,x_conc_segment
                                         );

            IF x_ccid = 0 THEN
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               x_error_message := 'Default Code Combination could not be derived.';
               xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low
                               ,p_category => 'CODCOMB-DV02'
                               ,p_error_text => 'E:'||x_error_message
                               ,p_record_identifier_1 => c_xx_upd_exp_acct.employee_name
                               ,p_record_identifier_2 => c_xx_upd_exp_acct.organization_name
                               ,p_record_identifier_3 => c_xx_upd_exp_acct.assignment_start_date
                               );
            END IF;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, ' ');
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_ccid           : '||x_ccid);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_conc_segment   : '||x_conc_segment);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_check_segment  : '||x_check_segment);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code     : '||x_error_code);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_message  : '||x_error_message);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, ' ');

            IF x_error_code = xx_emf_cn_pkg.CN_SUCCESS THEN

               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code before API call: '||x_error_code);
               
               IF c_xx_upd_exp_acct.system_person_type = 'EMP' THEN
               BEGIN
              hr_assignment_api.update_emp_asg
                   (p_validate                          => FALSE
                   ,p_effective_date                    => c_xx_upd_exp_acct.assignment_start_date
                   ,p_datetrack_update_mode             => 'CORRECTION'
                   ,p_assignment_id                     => c_xx_upd_exp_acct.assignment_id
                   ,p_object_version_number             => c_xx_upd_exp_acct.object_version_number
                   ,p_assignment_number                 => c_xx_upd_exp_acct.assignment_number
                   ,p_change_reason                     => c_xx_upd_exp_acct.change_reason
                   ,p_assignment_status_type_id         => c_xx_upd_exp_acct.assignment_status_type_id
                   ,p_default_code_comb_id              => x_ccid
                  -- ,p_set_of_books_id                   => c_xx_upd_exp_acct.set_of_books_id
                   ,p_set_of_books_id                   => l_set_of_book_id  -- Added in July 2014
                   ,p_cagr_grade_def_id                 => x_cagr_grade_def_id
                   ,p_cagr_concatenated_segments        => x_cagr_concatenated_segments
                   ,p_concatenated_segments             => x_concatenated_segments
                   --,p_soft_coding_keyflex_id            => x_soft_coding_keyflex_id   Commented as a part of CC3095
                   ,p_soft_coding_keyflex_id            => c_xx_upd_exp_acct.SOFT_CODING_KEYFLEX_ID -- Added as a part of CC3095
                   ,p_comment_id                        => x_comment_id
                   ,p_effective_start_date              => x_effective_start_date
                   ,p_effective_end_date                => x_effective_end_date
                   ,p_no_managers_warning               => x_no_managers_warning
                   ,p_other_manager_warning             => x_other_manager_warning
                   ,p_hourly_salaried_warning           => x_hourly_salaried_warning
                   ,p_gsp_post_process_warning          => x_gsp_post_process_warning
                   );
               EXCEPTION
               WHEN OTHERS THEN
              x_error_code :=  xx_emf_cn_pkg.CN_REC_ERR;
              x_error_message := SUBSTR(SQLERRM,1,1000);
              xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.CN_MEDIUM
                      ,p_category => xx_emf_cn_pkg.CN_TECH_ERROR
                      ,p_error_text => 'E: API Error: '||x_error_message
                      ,p_record_identifier_1 => c_xx_upd_exp_acct.employee_name
                      ,p_record_identifier_2 => c_xx_upd_exp_acct.organization_name
                      ,p_record_identifier_3 => c_xx_upd_exp_acct.assignment_start_date
                      );
               END;
           ELSIF c_xx_upd_exp_acct.system_person_type = 'CWK' THEN
           
             BEGIN
              hr_assignment_api.update_cwk_asg
                  (p_validate                      => FALSE
                  ,p_effective_date              => c_xx_upd_exp_acct.assignment_start_date
                  ,p_datetrack_update_mode        => 'CORRECTION'
                  ,p_assignment_id               => c_xx_upd_exp_acct.assignment_id
                  ,p_object_version_number        => c_xx_upd_exp_acct.object_version_number
                  ,p_assignment_number            => c_xx_upd_exp_acct.assignment_number
                  ,p_change_reason               => c_xx_upd_exp_acct.change_reason
                  ,p_default_code_comb_id         => x_ccid
                  ,p_set_of_books_id             => l_set_of_book_id 
                  ,p_assignment_status_type_id    => c_xx_upd_exp_acct.assignment_status_type_id
                  ,p_org_now_no_manager_warning  => l_org_now_no_manager_warning
                  ,p_effective_start_date        => l_effective_start_date
                  ,p_effective_end_date          => l_effective_end_date
                  ,p_comment_id                  => l_comment_id
                  ,p_no_managers_warning         => l_no_managers_warning
                  ,p_other_manager_warning       => l_other_manager_warning
                  ,p_soft_coding_keyflex_id     =>  l_soft_coding_keyflex_id 
                  ,p_concatenated_segments      =>  l_concatenated_segments 
                  ,p_hourly_salaried_warning    => l_hourly_salaried_warning  
                  );
                        EXCEPTION
                        WHEN OTHERS THEN
                       x_error_code :=  xx_emf_cn_pkg.CN_REC_ERR;
                       x_error_message := SUBSTR(SQLERRM,1,1000);
                       xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.CN_MEDIUM
                               ,p_category => xx_emf_cn_pkg.CN_TECH_ERROR
                               ,p_error_text => 'E: API Error: '||x_error_message
                               ,p_record_identifier_1 => c_xx_upd_exp_acct.employee_name
                               ,p_record_identifier_2 => c_xx_upd_exp_acct.organization_name
                               ,p_record_identifier_3 => c_xx_upd_exp_acct.assignment_start_date
                               );
               END;
           
           END IF;  
           
            END IF;
         END IF;

         IF x_error_code = xx_emf_cn_pkg.CN_SUCCESS AND x_check_segment = 1 THEN
            x_success_count := x_success_count + 1;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'x_success_count: '||x_success_count);
         ELSIF x_error_code = xx_emf_cn_pkg.CN_REC_ERR THEN
            x_error_count := x_error_count + 1;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'x_error_count: '||x_error_count);
         END IF;
      END LOOP;
      COMMIT;

      x_total_count :=x_success_count+x_error_count;

      xx_emf_pkg.update_recs_cnt(p_total_recs_cnt   => x_total_count
                                ,p_success_recs_cnt => x_success_count
                                ,p_warning_recs_cnt => 0
                                ,p_error_recs_cnt   => x_error_count
                                );

      xx_emf_pkg.create_report;
   EXCEPTION
   WHEN OTHERS THEN
      o_retcode := xx_emf_cn_pkg.CN_PRC_ERR;
      o_errbuf  := xx_emf_cn_pkg.cn_error;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Error in xx_upd_exp_acct procedure : '||SQLERRM);
      xx_emf_pkg.create_report;
   END xx_upd_exp_acct;
END xx_h2r_update_expense_account; 
/
