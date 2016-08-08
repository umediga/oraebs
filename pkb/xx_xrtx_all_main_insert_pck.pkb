DROP PACKAGE BODY APPS.XX_XRTX_ALL_MAIN_INSERT_PCK;
/**
* inserted a comment
*/
CREATE OR REPLACE PACKAGE BODY APPS."XX_XRTX_ALL_MAIN_INSERT_PCK" 
IS
--V_ORG_ID VARCHAR2(500);
   v_org_name                       VARCHAR2 (500);
--V_ROWNUM NUMBER;
--L_QUERY VARCHAR2(10000);
--l_statement varchar2(10000);
--V_MIN_COUNT NUMBER;
--V_MAX_COUNT NUMBER;
   v_parameter_name                 VARCHAR2 (500);
   v_parameter_value                VARCHAR2 (500);
--v_oe_inventory_item  VARCHAR2(500);
   v_recurring_charges              VARCHAR2 (500);
   v_recurring_charges_cou          NUMBER;
   v_oe_invoice_freight_as_line     VARCHAR2 (500);
   v_oe_invoice_freight_as_li_cou   NUMBER;
   v_installment_options            VARCHAR2 (500);
   v_installment_options_cou        NUMBER;
   v_oe_invoice_source              VARCHAR2 (500);
   v_oe_invoice_source_cou          NUMBER;
   v_oe_inv_item_for_fre            VARCHAR2 (100);
   v_oe_inv_item_for_fre_cou        NUMBER;
   v_oe_inv_tran_type_id            VARCHAR2 (100);
   v_oe_inv_tra_ty_id_cou           NUMBER;
   v_oe_credit_tr_type_id           VARCHAR2 (100);
   v_oe_credit_tr_type_id_cou       NUMBER;
   v_oe_non_del_inv_source          VARCHAR2 (100);
   v_oe_non_del_inv_sou_cou         NUMBER;
   v_oe_overship_invoice_basis      VARCHAR2 (100);
   v_oe_os_inv_basis_cou            NUMBER;
   v_oe_dis_det_on_inv              VARCHAR2 (100);
   v_oe_dis_det_on_inv_cou          NUMBER;
   v_ont_reservation_time_fence     VARCHAR2 (100);
   v_ont_reservation_time_fen_cou   NUMBER;
   v_ont_schedule_line_on_hold      VARCHAR2 (100);
   v_ont_sched_line_on_hold_cou     NUMBER;
   v_wsh_cr_srep_for_freight        VARCHAR2 (100);
   v_wsh_cr_srep_for_freight_cou    NUMBER;
   v_ont_gsa_violation_action       VARCHAR2 (100);
   v_ont_gsa_violation_action_cou   NUMBER;
   v_ont_emp_id_for_ss_orders       VARCHAR2 (100);
   v_ont_emp_id_for_ss_orders_cou   NUMBER;
   v_enable_fulfillment_acc         VARCHAR2 (100);
   v_enable_fulfillment_acc_cou     NUMBER;
   v_master_organization_id         VARCHAR2 (100);
   v_master_org_id_cou              NUMBER;
   v_audit_trail_enable_flag        VARCHAR2 (100);
   v_audit_trail_enable_flag_cou    NUMBER;
   v_customer_relationships_flag    VARCHAR2 (100);
   v_customer_relation_flag_cou     NUMBER;
   v_compute_margin                 VARCHAR2 (100);
   v_compute_margin_cou             NUMBER;
   v_freight_rating_enabled_flag    VARCHAR2 (100);
   v_freight_rating_enabd_fl_cou    NUMBER;
   v_fte_ship_method_enabled_flag   VARCHAR2 (100);
   v_fte_ship_method_enabl_fg_cou   NUMBER;
   v_latest_acceptable_date_flag    VARCHAR2 (100);
   v_latest_acc_date_fl_cou         NUMBER;
   v_reschedule_request_date_flag   VARCHAR2 (100);
   v_reschedule_reque_date_fl_cou   NUMBER;
   v_ont_prc_ava_default_hint       VARCHAR2 (100);
   v_ont_prc_ava_default_hint_cou   NUMBER;
   v_reschedule_ship_method_flag    VARCHAR2 (100);
   v_res_ship_method_fl_cou         NUMBER;
   v_promise_date_flag              VARCHAR2 (100);
   v_promise_date_flag_cou          NUMBER;
   v_partial_reservation_flag       VARCHAR2 (100);
   v_partial_res_flag_cou           NUMBER;
   v_firm_demand_events             VARCHAR2 (100);
   v_firm_demand_events_cou         NUMBER;
   v_multiple_payments              VARCHAR2 (100);
   v_multiple_payments_cou          NUMBER;
   v_acc_first_install_only         VARCHAR2 (100);
   v_acc_first_insta_only_cou       NUMBER;
   v_ont_config_effectivity_date    VARCHAR2 (100);
   v_ont_config_effec_date_cou      NUMBER;
   v_retrobill_reasons              VARCHAR2 (100);
   v_retrobill_reasons_cou          NUMBER;
   v_retrobill_default_order_type   VARCHAR2 (100);
   v_retrobill_deft_or_type_cou     NUMBER;
   v_enable_retrobilling            VARCHAR2 (100);
   v_enable_retrobilling_cou        NUMBER;
   v_no_response_from_approver      VARCHAR2 (100);
   v_no_response_from_appr_cou      NUMBER;
   v_copy_line_dff_ext_api          VARCHAR2 (100);
   v_copy_line_dff_ext_api_cou      NUMBER;
   v_copy_complete_config           VARCHAR2 (100);
   v_copy_complete_config_cou       NUMBER;
   v_trx_date_for_inv_iface         VARCHAR2 (100);
   v_trx_date_for_inv_iface_cou     NUMBER;
   v_credit_hold_zero_value_order   VARCHAR2 (100);
   v_cr_hold_zero_value_or_cou      NUMBER;
   v_ont_cascade_hold_nonsmc_pto    VARCHAR2 (100);
   v_ont_cascade_hold_non_pto_cou   NUMBER;
   v_oe_addr_valid_oimp             VARCHAR2 (100);
   v_oe_addr_valid_oimp_cou         NUMBER;
   v_oe_hold_line_sequence          VARCHAR2 (100);
   v_oe_hold_line_sequence_cou      NUMBER;
   v_cust_relationships_flag_svc    VARCHAR2 (100);
   v_cust_relation_flag_svc_cou     NUMBER;
   v_oe_cc_cancel_param             VARCHAR2 (100);
   v_oe_cc_cancel_param_cou         NUMBER;
   v_ont_auto_sch_sets              VARCHAR2 (100);
   v_ont_auto_sch_sets_cou          NUMBER;
   v_execution_file_name            VARCHAR2 (200);
   v_type                           VARCHAR2 (100);
   v_api_name                       VARCHAR2 (400);
   v_concurrent_programe_name       VARCHAR2 (100);
   v_concurrent_count               NUMBER;

   PROCEDURE xx_xrtx_main_insert_p
   IS
   BEGIN
      xx_xrtx_all_tables_data_pro;
      xx_xrtx_org_table_p;
      xx_org_structure_user_p;
      xx_org_structure_user_p1;
      xx_org_structure_user_p2;
      xx_org_structure_user_p3;
      xx_org_structure_user_p4;
      xx_org_structure_user_p5;
      xx_coa_load_table_p;
      xx_coa_user;
      xx_xrtx_load_table_p;
      xx_xrtx_qual_p;
      xx_xrtx_api_list_det_p;
   END xx_xrtx_main_insert_p;

   PROCEDURE xx_xrtx_org_table_p
   IS
   BEGIN
      DELETE FROM xx_xrtx_org_structure_t;

      FOR count_rec IN (SELECT 'BG' "ORG_LEVEL", haou.business_group_id,
                               haou.organization_id, haou.NAME,
                               hoi.org_information1
                          FROM hr_all_organization_units haou,
                               hr_organization_information hoi
                         WHERE nvl(haou.type,'BG') in ('BG','BU')
                           AND hoi.organization_id = haou.organization_id
                           AND hoi.org_information_context =
                                                  'Business Group Information')
      LOOP
         BEGIN
            INSERT INTO xx_xrtx_org_structure_t
                        (org_level, business_group_id,
                         organization_id, NAME,
                         short_code
                        )
                 VALUES (count_rec.org_level, count_rec.business_group_id,
                         count_rec.organization_id, count_rec.NAME,
                         count_rec.org_information1
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               DBMS_OUTPUT.put_line
                  ('ERROR WHILE INSERTING DATA INTO TABLE xx_xrtx_org_structure_t'
                  );
         END;
      END LOOP;

      --END;
--begin
      FOR count_rec1 IN (SELECT 'OU' "ORG_LEVEL", hou.organization_id,
                                hou.business_group_id,
                                hou.organization_id "operating_unit",
                                hou.short_code, NAME, gle.legal_entity_name,
                                gle.primary_ledger_name
                           FROM hr_operating_units hou,
                                gmf_legal_entities gle
                          WHERE default_legal_context_id = legal_entity_id)
      LOOP
         BEGIN
            INSERT INTO xx_xrtx_org_structure_t
                        (org_level, organization_id,
                         business_group_id,
                         operating_unit, short_code,
                         NAME, legal_entity_name,
                         primary_ledger_name
                        )
                 VALUES (count_rec1.org_level, count_rec1.organization_id,
                         count_rec1.business_group_id,
                         count_rec1.organization_id, count_rec1.short_code,
                         count_rec1.NAME, count_rec1.legal_entity_name,
                         count_rec1.primary_ledger_name
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               DBMS_OUTPUT.put_line
                  ('ERROR WHILE INSERTING DATA INTO TABLE xx_xrtx_org_structure_t'
                  );
         END;
      END LOOP;

--end;
-- begin
      FOR count_rec2 IN (SELECT 'INV_ORG' "ORG_LEVEL", a.organization_id,
                                a.business_group_id, b.operating_unit,
                                b.organization_code, a.NAME,
                                gle.legal_entity_name,
                                gle.primary_ledger_name
                           FROM hr_all_organization_units a,
                                org_organization_definitions b,
                                gmf_legal_entities gle
                          WHERE a.organization_id = b.organization_id(+)
                            AND legal_entity = legal_entity_id)
      LOOP
         BEGIN
            INSERT INTO xx_xrtx_org_structure_t
                        (org_level, org_id,
                         organization_id,
                         business_group_id,
                         operating_unit,
                         short_code, NAME,
                         legal_entity_name,
                         primary_ledger_name
                        )
                 VALUES (count_rec2.org_level, count_rec2.organization_id,
                         count_rec2.organization_id,
                         count_rec2.business_group_id,
                         count_rec2.operating_unit,
                         count_rec2.organization_code, count_rec2.NAME,
                         count_rec2.legal_entity_name,
                         count_rec2.primary_ledger_name
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               DBMS_OUTPUT.put_line
                  ('ERROR WHILE INSERTING DATA INTO TABLE xx_xrtx_org_structure_t'
                  );
         END;
      END LOOP;
--end;
   END xx_xrtx_org_table_p;

   PROCEDURE xx_org_structure_user_p
   IS
      CURSOR cur_get_org_structure_p
      IS
         SELECT org_level, business_group_id, NAME, short_code
           FROM xx_xrtx_org_structure_t;
   BEGIN
      FOR user_rec IN cur_get_org_structure_p
      LOOP
         BEGIN
            UPDATE xx_xrtx_org_structure_t a
               SET employee_cnt =
                (select count(distinct b.person_id)
               		from apps.per_person_types a,apps.per_all_people_f b
               		where a.person_type_id=b.person_type_id
               		and a.system_person_type = 'EMP'
               		and nvl(b.effective_end_date,sysdate+1) > TRUNC(sysdate)
               		and b.business_group_id = user_rec.business_group_id)--Changed on 11-July-2014
               WHERE a.org_level = 'BG'
               AND a.business_group_id = user_rec.business_group_id;
         END;
      END LOOP;

      COMMIT;
   END;

   PROCEDURE xx_org_structure_user_p1
   IS
      CURSOR cur_get_org_structure_p1
      IS
         SELECT org_level, operating_unit, business_group_id
           FROM xx_xrtx_org_structure_t
          WHERE org_level = 'OU';
   BEGIN
      FOR user_rec1 IN cur_get_org_structure_p1
      LOOP
         BEGIN
            UPDATE xx_xrtx_org_structure_t a
               SET bill_to_cnt =
                      (SELECT COUNT (*)
                         FROM hz_cust_site_uses_all b
                        WHERE status = 'A'
                          AND site_use_code IN ('BILL_TO')
                          AND b.org_id = user_rec1.operating_unit)
             WHERE a.org_level = 'OU'
               AND a.operating_unit = user_rec1.operating_unit;
         END;
      END LOOP;

      COMMIT;
   END;

   PROCEDURE xx_org_structure_user_p2
   IS
      CURSOR cur_get_org_structure_p2
      IS
         SELECT org_level, operating_unit, business_group_id
           FROM xx_xrtx_org_structure_t
          WHERE org_level = 'OU';
   BEGIN
      FOR user_rec2 IN cur_get_org_structure_p2
      LOOP
         BEGIN
            UPDATE xx_xrtx_org_structure_t a
               SET ship_to_cnt =
                      (SELECT COUNT (*)
                         FROM hz_cust_site_uses_all b
                        WHERE status = 'A'
                          AND site_use_code IN ('SHIP_TO')
                          AND b.org_id = user_rec2.operating_unit)
             WHERE a.org_level = 'OU'
               AND a.operating_unit = user_rec2.operating_unit;
         END;
      END LOOP;

      COMMIT;
   END;

   PROCEDURE xx_org_structure_user_p3
   IS
      CURSOR cur_get_org_structure_p3
      IS
         SELECT org_level, operating_unit, business_group_id
           FROM xx_xrtx_org_structure_t
          WHERE org_level = 'OU';
   BEGIN
      FOR user_rec3 IN cur_get_org_structure_p3
      LOOP
         BEGIN
            UPDATE xx_xrtx_org_structure_t a
               SET supplier_cnt =
                      (SELECT COUNT (*)
                         FROM ap_supplier_sites_all b
                        WHERE NVL (inactive_date, SYSDATE + 1) >
                                                               TRUNC (SYSDATE)
                          AND b.org_id = user_rec3.operating_unit)
             WHERE a.org_level = 'OU'
               AND a.operating_unit = user_rec3.operating_unit;
         END;
      END LOOP;

      COMMIT;
   END;

   PROCEDURE xx_org_structure_user_p4
   IS
      CURSOR cur_get_org_structure_p4
      IS
         SELECT org_id
           FROM xx_xrtx_org_structure_t
          WHERE org_level = 'INV_ORG';
   BEGIN
      FOR user_rec4 IN cur_get_org_structure_p4
      LOOP
         BEGIN
            UPDATE xx_xrtx_org_structure_t a
               SET active_items_cnt =
                      (SELECT COUNT (*)
                         FROM mtl_system_items_b b
                        WHERE TRUNC (SYSDATE)
                                 BETWEEN TRUNC (NVL (start_date_active,
                                                     SYSDATE - 1
                                                    )
                                               )
                                     AND TRUNC (NVL (end_date_active,
                                                     SYSDATE + 1
                                                    )
                                               )
                          AND enabled_flag = 'Y'
                          AND b.organization_id = user_rec4.org_id)
             WHERE a.org_level = 'INV_ORG' AND a.org_id = user_rec4.org_id;
         END;
      END LOOP;

      COMMIT;
   END;

   PROCEDURE xx_org_structure_user_p5
   IS
      CURSOR cur_get_org_structure_p5
      IS
         SELECT org_id
           FROM xx_xrtx_org_structure_t
          WHERE org_level = 'INV_ORG';
   BEGIN
      FOR user_rec5 IN cur_get_org_structure_p5
      LOOP
         BEGIN
            UPDATE xx_xrtx_org_structure_t a
               SET active_sub_inventories =
                      (SELECT COUNT (*)
                         FROM mtl_secondary_inventories b
                        WHERE NVL (disable_date, SYSDATE + 1) >
                                                               TRUNC (SYSDATE)
                          AND b.organization_id = user_rec5.org_id)
             WHERE a.org_level = 'INV_ORG' AND a.org_id = user_rec5.org_id;
         END;
      END LOOP;

      COMMIT;
   END;

   PROCEDURE xx_xrtx_all_tables_data_pro
   IS
   BEGIN
      EXECUTE IMMEDIATE 'truncate table xx_temp_concurrent_programs';

      EXECUTE IMMEDIATE 'truncate table XX_XTRX_CUS_ALERTS_MASTER_T';

     -- EXECUTE IMMEDIATE 'truncate table xx_temp1_database_objects';

      EXECUTE IMMEDIATE 'truncate table xx_xrtx_mas_forper_t';

      EXECUTE IMMEDIATE 'truncate table xx_xrtx_child_forper_t';

      EXECUTE IMMEDIATE 'truncate table xx_xrtx_child_actions_t';

      EXECUTE IMMEDIATE 'truncate table xx_xrtx_costom_oaf_t';

      EXECUTE IMMEDIATE 'truncate table xx_temp_profile';

      EXECUTE IMMEDIATE 'truncate table xx_xrtx_mas_cus_wf_t';

      EXECUTE IMMEDIATE 'truncate table xx_xrtx_child_wf_t';

      EXECUTE IMMEDIATE 'truncate table xx_xtrx_cust_wf_exec_t';

      --EXECUTE IMMEDIATE 'truncate table xx_Xrtx_HL_forms_t ';

      -- EXECUTE IMMEDIATE 'truncate table xx_Xrtx_HL_forms_Hourwise_t';

      --EXECUTE IMMEDIATE 'truncate table xx_Xrtx_HL_forms_daywise_t';

      EXECUTE IMMEDIATE 'truncate table xx_xtrx_hour_usr_analysis_t';

      EXECUTE IMMEDIATE 'truncate table xx_temp_profile_values';

      EXECUTE IMMEDIATE 'truncate table xx_xrtx_all_cp_t';

      EXECUTE IMMEDIATE 'truncate table XX_Xrtx_dayws_Module_Cls_T ';

      EXECUTE IMMEDIATE 'truncate table XX_Xrtx_Hrws_Module_Cls_T';

      EXECUTE IMMEDIATE 'truncate table xx_xrtx_mc_user_count_t';

      EXECUTE IMMEDIATE 'truncate table XX_XRTX_MASTER_ITEM_T';

      EXECUTE IMMEDIATE 'truncate table xx_xrtx_itemtype_master_t';

      EXECUTE IMMEDIATE 'truncate table xx_xrtx_item_inv_data_t';

      --EXECUTE IMMEDIATE 'truncate table xx_xrtx_inv_transactions_t';

      EXECUTE IMMEDIATE 'truncate table xx_xtrx_hr_usr_analysis_t';

      EXECUTE IMMEDIATE 'truncate table XX_XRTX_Conprg_date';

      EXECUTE IMMEDIATE 'truncate table XX_XRTX_HLDATE_RANGE';

      EXECUTE IMMEDIATE 'truncate table XX_XRTX_INTERFACE_ERRORS_T';

      EXECUTE IMMEDIATE 'truncate table XX_XRTX_ITEMTYPE_INV_T';

      EXECUTE IMMEDIATE 'truncate table BUSINESSUSAGE';

      EXECUTE IMMEDIATE 'truncate table TASKTYPE';

      EXECUTE IMMEDIATE 'truncate table XX_XRTX_CUST_ERROR_CODES';

      EXECUTE IMMEDIATE 'truncate table XX_XRTX_CLASSIFICATION_T';

      EXECUTE IMMEDIATE 'truncate table xx_xrtx_cust_int_err';

      EXECUTE IMMEDIATE 'truncate table xx_xrtx_cust_profile_err';

      EXECUTE IMMEDIATE 'truncate table XX_XRTX_DB_SCHEMA_T';

      EXECUTE IMMEDIATE 'truncate table  xx_xrtx_om_sys_pa';

      EXECUTE IMMEDIATE 'truncate table  XX_XRTX_API_LIST';

      EXECUTE IMMEDIATE 'truncate table  XX_XRTS_API_LIST_DETAILS';

      INSERT INTO xx_temp_concurrent_programs
         (SELECT fef.application_name, fef.user_executable_name,
                 fef.executable_name, fef.execution_file_name,
                 flv.meaning "EXECUTABLE_TYPE", fcp.concurrent_program_name,
                 fcpt.description, fcp.enabled_flag,
                 fcp.concurrent_program_id, fef.application_id
            FROM fnd_concurrent_programs fcp,
                 fnd_executables_form_v fef,
                 fnd_lookup_values flv,
                 fnd_application_tl fat,
                 fnd_concurrent_programs_tl fcpt
           WHERE fcp.concurrent_program_name LIKE 'XX%'
             AND fcp.executable_id = fef.executable_id
             AND fef.executable_name LIKE 'XX%'
             AND flv.lookup_type = 'CP_EXECUTION_METHOD_CODE'
             AND flv.lookup_code = fef.execution_method_code
             AND flv.enabled_flag = 'Y'
             AND flv.LANGUAGE = 'US'
             AND fat.LANGUAGE = 'US'
             AND fcpt.LANGUAGE = 'US'
             AND fat.application_id = fcp.application_id
--   AND fcp.application_id = fef.application_id
             AND fcpt.concurrent_program_id = fcp.concurrent_program_id);

      COMMIT;

      INSERT INTO xx_xtrx_cus_alerts_master_t
         (SELECT fat.application_name, aa.alert_id, aa.alert_name,
                 aa.description,
                 (SELECT meaning
                    FROM alr_lookups
                   WHERE lookup_type =
                                  'ALERT_CONDITION_TYPE'
                     AND lookup_code = alert_condition_type)
                                                         alert_condition_type,
                 aa.enabled_flag,
                 (SELECT meaning
                    FROM alr_lookups
                   WHERE lookup_type = 'ALERT_FREQUENCY_TYPE'
                     AND lookup_code = frequency_type) frequency_type,
                 aa.weekly_check_day, aa.last_update_date, aa.last_updated_by,
                 aa.creation_date, aa.monthly_check_day_num,
                 aa.days_between_checks, aa.check_begin_date,
                 aa.date_last_checked, aa.insert_flag, aa.update_flag,
                 aa.delete_flag, aa.maintain_history_days, aa.check_time,
                 aa.check_start_time, aa.check_end_time,
                 aa.seconds_between_checks, aa.check_once_daily_flag
            FROM alr_alerts aa, fnd_application_tl fat
           WHERE aa.created_by IN (SELECT user_id
                                     FROM fnd_user
                                    WHERE user_name NOT LIKE '%AUTOINSTALL%')
             AND aa.application_id = fat.application_id
             AND aa.created_by IN (SELECT user_id
                                     FROM fnd_user
                                    WHERE user_name NOT LIKE '%ORACLE%')
             AND aa.created_by IN (SELECT user_id
                                     FROM fnd_user
                                    WHERE user_name NOT LIKE '%ANONYMOUS%'));

      COMMIT;

      /*INSERT INTO xx_temp1_database_objects
         (SELECT owner, object_name, status, object_type, created,
                 last_ddl_time, TIMESTAMP
            FROM all_objects
           WHERE object_name LIKE 'XX%'
             AND object_type <> 'PACKAGE BODY'
             AND object_name NOT LIKE 'XX_XRTX%'
             AND object_name <> 'xx_temp1_database_objects'
             AND object_name <> 'XX_TEST1'
             and object_name <>'xx_temp_concurrent_programs'
             and object_name <>'xx_temp_profile'
             and object_name <>'xx_temp_profile_values'
             and object_name <>'BUSINESSUSAGE'
             and object_name <>'TASKTYPE'
             and object_name <>'xx_coa_load_table_p'
             and object_name <>'xx_coa_structure'
             and object_name <>'xx_coa_user');*/

      COMMIT;

      INSERT INTO xx_xrtx_mas_forper_t
         (SELECT fff.function_name, ffv.form_name,
                 ffft.user_function_name "User Form Name", ffv.form_id
            FROM fnd_form_custom_rules ffcr,
                 fnd_form_functions_vl ffft,
                 fnd_form_vl ffv,
                 fnd_form_functions fff
           WHERE ffcr.ID = ffft.function_id
             AND ffft.function_id = fff.function_id
             AND fff.form_id = ffv.form_id);

      COMMIT;

      INSERT INTO xx_xrtx_child_forper_t
         (SELECT ffv.form_name, ffft.user_function_name "User Form Name",
                 ffcr.SEQUENCE, ffv.form_id, ffcr.description, ffcr.rule_type,
                 ffcr.enabled, ffcr.trigger_event, ffcr.trigger_object,
                 ffcr.condition, ffcr.fire_in_enter_query,
                 (SELECT user_name
                    FROM fnd_user fu
                   WHERE fu.user_id = ffcr.created_by) "Created By "
            FROM fnd_form_custom_rules ffcr,
                 fnd_form_functions_vl ffft,
                 fnd_form_vl ffv,
                 fnd_form_functions fff
           WHERE ffcr.ID = ffft.function_id
             AND ffft.function_id = fff.function_id
             AND fff.form_id = ffv.form_id);

      COMMIT;

      INSERT INTO xx_xrtx_costom_oaf_t
         (SELECT perz_doc_id, perz_doc_path,
                 SUBSTR (perz_doc_path,
                         INSTR (perz_doc_path, '/', -1, 1) + 1
                        ) oaf_page,
                 SUBSTR (perz_doc_path,
                         INSTR (perz_doc_path, '/', 1, 3) + 1,
                           INSTR (perz_doc_path, '/', 1, 4)
                         - INSTR (perz_doc_path, '/', 1, 3)
                         - 1
                        ) module
            FROM (SELECT PATH.path_docid perz_doc_id,
                         jdr_mds_internal.getdocumentname
                                               (PATH.path_docid)
                                                                perz_doc_path
                    FROM apps.jdr_paths PATH
                   WHERE PATH.path_docid IN (
                            SELECT DISTINCT comp_docid
                                       FROM jdr_components
                                      WHERE comp_seq = 0
                                        AND comp_element = 'customization'
                                        AND comp_id IS NULL)
                  MINUS
                  SELECT PATH.path_docid perz_doc_id,
                         jdr_mds_internal.getdocumentname
                                               (PATH.path_docid)
                                                                perz_doc_path
                    FROM apps.jdr_paths PATH
                   WHERE PATH.path_docid IN (
                            SELECT DISTINCT comp_docid
                                       FROM jdr_components, jdr_attributes
                                      WHERE comp_seq = 0
                                        AND comp_element = 'customization'
                                        AND comp_id IS NULL
                                        AND att_comp_docid = comp_docid
                                        AND att_comp_seq = 0
                                        AND att_name = 'developerMode'
                                        AND att_value = 'true')));

      COMMIT;

      INSERT INTO xx_xrtx_child_actions_t
         (SELECT aa.alert_id, ac.NAME action_name, ac.description,
                 (SELECT meaning
                    FROM alr_lookups
                   WHERE lookup_type = 'ACTION_LEVEL'
                     AND lookup_code = ac.action_level_type) action_level,
                 (SELECT meaning
                    FROM alr_lookups
                   WHERE lookup_type = 'ACTION_TYPE'
                     AND lookup_code = ac.action_type) action_type,
                 ac.list_id, ac.to_recipients, ac.cc_recipients,
                 ac.bcc_recipients, ac.print_recipients, ac.printer,
                 ac.subject, ac.reply_to, ac.column_wrap_flag,
                 ac.maximum_summary_message_width, ac.BODY
            FROM alr_actions ac, alr_alerts aa
           WHERE ac.alert_id = aa.alert_id);

      COMMIT;

      INSERT INTO xx_temp_profile
         (SELECT fpov.application_id, fpov.profile_option_id,
                 fat.application_name, fpov.profile_option_name,
                 fpov.user_profile_option_name, fpov.description,
                 fpov.hierarchy_type
            FROM fnd_profile_options_vl fpov, fnd_application_tl fat
           WHERE fpov.profile_option_name LIKE 'XX%'
             AND fpov.application_id = fat.application_id
             AND fat.LANGUAGE = 'US');

      COMMIT;

      INSERT INTO xx_xrtx_mas_cus_wf_t
         (SELECT   wa.item_type, witv.display_name, wa.VERSION,
                   COUNT (*) activity_count, witv.description
              FROM wf_activities wa, wf_item_types_vl witv
             WHERE 1 = 1
               AND wa.item_type = witv.NAME                 --end_date is null
               AND (   wa.FUNCTION LIKE 'XX%'
                    OR wa.NAME LIKE 'RHM%'
                    OR wa.NAME LIKE 'XX%'
                   )
          GROUP BY item_type, VERSION, witv.display_name, witv.description);

      COMMIT;

      INSERT INTO xx_xrtx_child_wf_t
         (SELECT wa.item_type, witv.display_name, wa.NAME, wa.VERSION,
                 wa.TYPE, wa.rerun, wa.expand_role, wa.protect_level,
                 wa.custom_level, wa.begin_date, wa.end_date, wa.FUNCTION,
                 wa.result_type, wa.COST, wa.read_role, wa.write_role,
                 wa.execute_role, wa.icon_name, wa.MESSAGE, wa.error_process,
                 wa.error_item_type, wa.runnable_flag, wa.function_type,
                 wa.event_name, wa.direction, wa.security_group_id
            FROM wf_activities wa, wf_item_types_vl witv
           WHERE 1 = 1
             AND wa.item_type = witv.NAME                   --end_date is null
             AND (   wa.FUNCTION LIKE 'XX%'
                  OR wa.NAME LIKE 'RHM%'
                  OR wa.NAME LIKE 'XX%'
                 ));

      COMMIT;

      INSERT INTO xx_xtrx_cust_wf_exec_t
         (SELECT   COUNT (activity_id) "Execution Count", activity_name,
                   item_type_display_name, item_type
              FROM wf_item_activity_statuses_v
             WHERE activity_id IN (
                      SELECT instance_id
                        FROM wf_process_activities
                       WHERE 1 = 1
--and PROCESS_item_TYPE = 'OEOH'
                         AND (process_item_type, process_version) IN (
                                SELECT   process_item_type,
                                         MAX (process_version)
                                    FROM wf_process_activities
                                   WHERE process_item_type IN (
                                             SELECT DISTINCT process_item_type
                                                        FROM wf_process_activities)
                                GROUP BY process_item_type))
               AND activity_name LIKE 'XX%'
          GROUP BY activity_id,
                   activity_name,
                   item_type_display_name,
                   item_type);

      COMMIT;

      INSERT INTO xx_temp_profile_values
         (SELECT fpo.profile_option_name,
                 DECODE (fpov.level_id, '10001', 'Site') "Site Level",
                 DECODE (fpov.level_id,
                         '10002', fa.application_short_name
                        ) "Application Level",
                 DECODE (fpov.level_id,
                         '10003', fr.responsibility_key
                        ) "Responsibility Level",
                 DECODE (fpov.level_id, '10004', fu.user_name) "User Level",
                 fpov.profile_option_value,
                 faa.application_short_name "Level Value for Apps"
            FROM fnd_profile_option_values fpov,
                 fnd_profile_options fpo,
                 fnd_application fa,
                 fnd_responsibility fr,
                 fnd_application faa,
                 fnd_user fu
           WHERE fpo.profile_option_id = fpov.profile_option_id
             AND fpov.level_value = fa.application_id(+)
             AND fpov.level_value = fr.responsibility_id(+)
             AND fpov.level_value = fu.user_id(+)
             AND fpov.level_value_application_id = faa.application_id(+)
             AND fpo.profile_option_name LIKE 'XX%');

      COMMIT;

      INSERT INTO xx_xrtx_all_cp_t
         (SELECT fef.application_name, fef.user_executable_name,
                 fef.executable_name, fef.execution_file_name,
                 flv.meaning "EXECUTABLE_TYPE", fcp.concurrent_program_name,
                 fcpt.description, fcp.enabled_flag,
                 fcp.concurrent_program_id, fef.application_id
            FROM fnd_concurrent_programs fcp,
                 fnd_executables_form_v fef,
                 fnd_lookup_values flv,
                 fnd_application_tl fat,
                 fnd_concurrent_programs_tl fcpt
           WHERE fcp.executable_id = fef.executable_id
             AND flv.lookup_type = 'CP_EXECUTION_METHOD_CODE'
             AND flv.lookup_code = fef.execution_method_code
             AND flv.enabled_flag = 'Y'
             AND flv.LANGUAGE = 'US'
             AND fat.LANGUAGE = 'US'
             AND fcpt.LANGUAGE = 'US'
             AND fat.application_id = fcp.application_id
             AND fcpt.concurrent_program_id = fcp.concurrent_program_id);

      COMMIT;

      INSERT INTO xx_xrtx_master_item_t
         (SELECT   mp.master_organization_id,
                   ood.organization_code master_org_code,
                   ood.organization_name master_org_name,
                   ood.business_group_id,
                   COUNT (master_organization_id) inv_orgs_count,
                   xx_xrtx_all_main_insert_pck.xx_master_all
                                          (master_organization_id)
                                                                  no_of_items,
                   xx_xrtx_all_main_insert_pck.xx_master_manual
                                  (master_organization_id)
                                                          items_manual_create,
                   xx_xrtx_all_main_insert_pck.xx_master_intf
                                (master_organization_id)
                                                        item_interface_create
              FROM mtl_parameters mp, org_organization_definitions ood
             WHERE mp.master_organization_id <> mp.organization_id
               AND mp.master_organization_id = ood.organization_id
          GROUP BY mp.master_organization_id,
                   ood.organization_code,
                   ood.organization_name,
                   ood.business_group_id
          UNION ALL
          SELECT   mp.master_organization_id,
                   ood.organization_code master_org_code,
                   ood.organization_name master_org_name,
                   ood.business_group_id,
                   COUNT (master_organization_id) inv_org_count,
                   xx_xrtx_all_main_insert_pck.xx_master_all
                                          (master_organization_id)
                                                                  no_of_items,
                   xx_xrtx_all_main_insert_pck.xx_master_manual
                               (mp.master_organization_id)
                                                          items_manual_create,
                   xx_xrtx_all_main_insert_pck.xx_master_intf
                                (master_organization_id)
                                                        item_interface_create
              FROM mtl_parameters mp, org_organization_definitions ood
             WHERE mp.master_organization_id = ood.organization_id
          GROUP BY mp.master_organization_id,
                   ood.organization_code,
                   ood.organization_name,
                   ood.business_group_id
            HAVING COUNT (mp.master_organization_id) = 1
               AND mp.master_organization_id = mp.master_organization_id);

      COMMIT;

      INSERT INTO xx_xrtx_itemtype_master_t
         (SELECT   COUNT (a.segment1) item_cnt, a.item_type,
                   b.organization_code, b.organization_id, c.meaning
              FROM apps.mtl_system_items_b a,
                   apps.mtl_parameters b,
                   apps.fnd_lookup_values c
             WHERE a.organization_id = b.organization_id
               AND b.organization_id = b.master_organization_id
               AND a.item_type = c.lookup_code
               AND c.lookup_type = 'ITEM_TYPE'
               AND c.LANGUAGE = 'US'
               AND c.enabled_flag = 'Y'
          GROUP BY a.item_type,
                   b.organization_code,
                   c.meaning,
                   b.organization_id);

      COMMIT;

      INSERT INTO xx_xrtx_item_inv_data_t
         (SELECT DISTINCT mp.organization_id, mp.master_organization_id,
                          ood.organization_code short_code,
                          'INVENTORY ORG' description,
                          xx_xrtx_all_main_insert_pck.xx_master_all
                                    (mp.organization_id)
                                                        items_defined_inv_org,
                          xx_xrtx_all_main_insert_pck.xx_master_manual
                                   (mp.organization_id)
                                                       items_manually_created,
                          xx_xrtx_all_main_insert_pck.xx_master_intf
                                   (mp.organization_id)
                                                       items_iterface_created
                     FROM mtl_parameters mp, org_organization_definitions ood
                    WHERE mp.master_organization_id <> mp.organization_id
                      AND mp.organization_id = ood.organization_id
                 GROUP BY mp.master_organization_id,
                          mp.organization_id,
                          ood.organization_code,
                          ood.organization_name,
                          ood.business_group_id
          UNION ALL
          SELECT DISTINCT mp.organization_id, mp.master_organization_id,
                          ood.organization_code master_org_code,
                          'INVENTORY ORG' description,
                          xx_xrtx_all_main_insert_pck.xx_master_all
                                    (mp.organization_id)
                                                        items_defined_inv_org,
                          xx_xrtx_all_main_insert_pck.xx_master_manual
                                   (mp.organization_id)
                                                       items_manually_created,
                          xx_xrtx_all_main_insert_pck.xx_master_intf
                                   (mp.organization_id)
                                                       items_iterface_created
                     FROM mtl_parameters mp, org_organization_definitions ood
                    WHERE mp.organization_id = mp.organization_id
                      AND mp.organization_id = ood.organization_id
                 GROUP BY mp.master_organization_id,
                          mp.organization_id,
                          ood.organization_code,
                          ood.organization_name,
                          ood.business_group_id
                   HAVING COUNT (mp.organization_id) = 1
                      AND mp.organization_id = mp.organization_id);

      COMMIT;

      INSERT INTO xx_xrtx_itemtype_inv_t
         (SELECT   COUNT (a.segment1) item_cnt, a.item_type,
                   b.organization_code, b.organization_id, c.meaning
              FROM apps.mtl_system_items_b a,
                   apps.mtl_parameters b,
                   apps.fnd_lookup_values c
             WHERE a.organization_id = b.organization_id
               AND b.organization_id <> b.master_organization_id
               AND a.item_type = c.lookup_code
               AND c.lookup_type = 'ITEM_TYPE'
               AND c.LANGUAGE = 'US'
               AND c.enabled_flag = 'Y'
          GROUP BY a.item_type,
                   b.organization_code,
                   c.meaning,
                   b.organization_id);

      COMMIT;

      INSERT INTO xx_xrtx_conprg_date
           VALUES ('01-JAN-2012', '01-JAN-2013');

      COMMIT;

      INSERT INTO xx_xrtx_hldate_range
           VALUES ('01-JAN-2012', '01-JAN-2013');

      COMMIT;

      INSERT INTO xx_xtrx_hr_usr_analysis_t
         (SELECT   TO_CHAR (flr.start_time, 'HH24') login_hour,
                   COUNT (*) total_login_count,
                   ROUND (  COUNT (*)
                          / (TO_DATE (dr.end_date) - TO_DATE (dr.start_date)),
                          2
                         ) avg_login_per_hr,
                   ROUND (SUM ((flr.end_time - flr.start_time) * 24 * 60),
                          2
                         ) total_usage_mins,
                   ROUND (AVG ((flr.end_time - flr.start_time) * 24 * 60),
                          2
                         ) avg_mins_usage,
                   flr.resp_appl_id
              FROM fnd_login_responsibilities flr,
                   fnd_application_tl fat,
                   xx_xrtx_hldate_range dr
             WHERE flr.start_time BETWEEN TO_DATE (dr.start_date)
                                      AND TO_DATE (dr.end_date)
               AND fat.LANGUAGE = 'US'
               AND flr.resp_appl_id = fat.application_id
          GROUP BY TO_CHAR (start_time, 'HH24'),
                   dr.start_date,
                   dr.end_date,
                   flr.resp_appl_id);

      COMMIT;
      /*INSERT INTO xx_xrtx_hl_forms_hourwise_t
         SELECT   TO_CHAR (flrf.start_time, 'HH24') login_hour,
                  COUNT (*) total_login_count,
                  ROUND (  COUNT (*)
                         / (TO_DATE (dr.end_date) - TO_DATE (dr.start_date)),
                         2
                        ) avg_login_per_hr,
                  ROUND (SUM ((flrf.end_time - flrf.start_time) * 24 * 60),
                         2
                        ) total_usage_mins,
                  ROUND (AVG ((flrf.end_time - flrf.start_time) * 24 * 60),
                         2
                        ) avg_mins_usage,
                  flrf.form_id
             FROM fnd_login_resp_forms flrf,
                  fnd_form_tl ffl,
                  xx_xrtx_hldate_range dr
            WHERE ffl.form_id = flrf.form_id
              AND ffl.LANGUAGE = 'US'
              AND flrf.start_time BETWEEN TO_DATE (dr.start_date)
                                      AND TO_DATE (dr.end_date)
         GROUP BY TO_CHAR (start_time, 'HH24'),
                  dr.start_date,
                  dr.end_date,
                  flrf.form_id;*/
      COMMIT;
      /*INSERT INTO XX_XRTX_HL_FORMS_T
         SELECT   ffl.user_form_name, COUNT (flrf.form_id) form_usage_count,
                  ROUND (  COUNT (flrf.form_id)
                         / (TO_DATE (dr.end_date) - TO_DATE (dr.start_date)),
                         2
                        ) form_usage_per_day,
                  ROUND (SUM ((flrf.end_time) - flrf.start_time) * 24 * 60,
                         2
                        ) form_usage_mins,
                  ROUND (AVG ((flrf.end_time) - flrf.start_time) * 24 * 60,
                         2
                        ) form_min_per_day,
                  flrf.form_id
             FROM fnd_login_resp_forms flrf,
                  fnd_form_tl ffl,
                  xx_xrtx_hldate_range dr
            WHERE ffl.form_id = flrf.form_id
              AND ffl.LANGUAGE = 'US'
              AND flrf.start_time BETWEEN TO_DATE (dr.start_date)
                                      AND TO_DATE (dr.end_date)
         GROUP BY ffl.user_form_name, flrf.form_id, dr.start_date,
                  dr.end_date;

      COMMIT;*/
/*
insert into xx_Xrtx_HL_forms_daywise_t SELECT   DECODE (TO_CHAR (start_time, 'D'),
                 1, 'Sunday',
                 2, 'Monday',
                 3, 'Tuesday',
                 4, 'Wednesday',
                 5, 'Thursday',
                 6, 'Friday',
                 7, 'Saturday'
                ) login_day,
         COUNT (*) total_login_count,
         ROUND (COUNT (*) / (to_date(dr.end_date)-to_date(dr.start_date)), 2) avg_login_per_day,
         ROUND (SUM ((flrf.end_time - flrf.start_time) * 24 * 60),2) total_usage_mins,
         ROUND (AVG ((flrf.end_time - flrf.start_time) * 24 * 60),2) mins_usage_per_day,flrf.form_id
    FROM fnd_login_resp_forms flrf, fnd_form_tl ffl,XX_XRTX_HLDate_Range dr
   WHERE ffl.form_id = flrf.form_id
     AND ffl.LANGUAGE = 'US'
     AND flrf.start_time between to_date(dr.start_date) and to_date(dr.end_date)
GROUP BY TO_CHAR (start_time, 'D'),dr.start_date,dr.end_date,flrf.form_id;*/
      COMMIT;

      INSERT INTO xx_xtrx_hour_usr_analysis_t
         SELECT   TO_CHAR (fl.start_time, 'HH24') login_hour,
                  COUNT (*) total_login_count,
                  ROUND (  COUNT (*)
                         / (TO_DATE (dr.end_date) - TO_DATE (dr.start_date)),
                         2
                        ) avg_login_per_hr,
                  ROUND (SUM ((fl.end_time - fl.start_time) * 24 * 60),
                         2
                        ) total_usage_mins,
                  ROUND (AVG ((fl.end_time - fl.start_time) * 24 * 60),
                         2
                        ) avg_mins_usage
             FROM fnd_logins fl, xx_xrtx_hldate_range dr
            WHERE fl.start_time BETWEEN TO_DATE (dr.start_date)
                                    AND TO_DATE (dr.end_date)
         GROUP BY TO_CHAR (fl.start_time, 'HH24'), dr.end_date, dr.start_date;

      COMMIT;
       /*insert into xx_xrtx_inv_transactions_t(transaction_type_id,transaction_source_type_id,transaction_action_id,Transaction_source_type_name,organization_id,SOURCE_CODE,CNT_TRAN_SOURCE)
       (
      select a.transaction_type_id,a.transaction_source_type_id,transaction_action_id,b.transaction_source_type_name,a.organization_id,a.SOURCE_CODE,count(*)
      from xx_xrtx_mmt_dup_t a, xx_mtstav_dup_t b
      where a.transaction_source_type_id =b.transaction_source_type_id
      group by a.organization_id,a.transaction_type_id,a.transaction_source_type_id,a.transaction_action_id,b.transaction_source_type_name,a.SOURCE_CODE
      );

      commit;

       update xx_xrtx_inv_transactions_t a
      set business_group_id=(select business_group_id from org_organization_definitions b
      where a.organization_id=b.organization_id);

      commit;


        update xx_xrtx_inv_transactions_t a
      set operating_unit=(select operating_unit from org_organization_definitions b
      where a.organization_id=b.organization_id);

      commit;

        update xx_xrtx_inv_transactions_t x
      set (TRANSACTION_TYPE_NAME,CNT_TRAN_TYPE)=(select b.TRANSACTION_TYPE_NAME,count(*)
      from mtl_material_transactions a, mtl_transaction_types b
      where a.TRANSACTION_TYPE_ID =b.TRANSACTION_TYPE_ID
      and x.ORGANIZATION_ID=a.ORGANIZATION_ID
      and x.TRANSACTION_TYPE_ID=a.TRANSACTION_TYPE_ID
      group by b.transaction_type_name,a.organization_id);

      commit;


       update xx_xrtx_inv_transactions_t x
      set (TRANSACTION_action_NAME,CNT_TRAN_action)=(select (select meaning from mfg_lookups where lookup_type='MTL_TRANSACTION_ACTION' and lookup_code=b.transaction_action_id)
      ,count(*)
      from mtl_material_transactions a, mtl_transaction_types b
      where a.TRANSACTION_action_ID =b.TRANSACTION_action_ID
      and x.ORGANIZATION_ID=a.ORGANIZATION_ID
      and x.TRANSACTION_action_ID=a.TRANSACTION_action_ID
      group by b.transaction_action_id,a.organization_id);*/
      COMMIT;

      INSERT INTO xx_xrtx_interface_errors_t
         SELECT   COUNT (*) error_count, b.organization_code,
                  a.table_name error_interface, a.message_name ERROR_CODE,
                  a.error_message
             FROM apps.mtl_interface_errors a, apps.mtl_parameters b
            WHERE table_name = 'MTL_SYSTEM_ITEMS_INTERFACE'
         GROUP BY b.organization_code,
                  a.table_name,
                  a.message_name,
                  a.error_message
         UNION
         SELECT   COUNT (*) error_count, d.organization_code,
                  'MTL_TRANSACTIONS_INTERFACE' error_interface, a.ERROR_CODE,
                     a.error_explanation
                  || '  '
                  || b.ERROR_CODE
                  || ' '
                  || c.ERROR_CODE error_message
             FROM apps.mtl_transactions_interface a,
                  apps.mtl_parameters d,
                  apps.mtl_transaction_lots_interface b,
                  apps.mtl_serial_numbers_interface c
            WHERE a.organization_id = d.organization_id
              AND a.process_flag IN (3, 4)
              AND a.transaction_interface_id = b.transaction_interface_id(+)
              AND a.transaction_interface_id = c.transaction_interface_id(+)
         GROUP BY d.organization_code,
                  a.ERROR_CODE,
                     a.error_explanation
                  || '  '
                  || b.ERROR_CODE
                  || ' '
                  || c.ERROR_CODE;

      COMMIT;

      INSERT INTO businessusage
                  (status, blevel
                  )
           VALUES ('1-Critical', '1'
                  );

      COMMIT;

      INSERT INTO businessusage
                  (status, blevel
                  )
           VALUES ('2-High', '2'
                  );

      COMMIT;

      INSERT INTO businessusage
                  (status, blevel
                  )
           VALUES ('3-Medium', '3'
                  );

      COMMIT;

      INSERT INTO businessusage
                  (status, blevel
                  )
           VALUES ('4-Low', '4'
                  );

      COMMIT;

      INSERT INTO tasktype
                  (tasktype, tlevel
                  )
           VALUES ('1-Concurrent-Program', '1'
                  );

      COMMIT;

      INSERT INTO tasktype
                  (tasktype, tlevel
                  )
           VALUES ('2-Form', '2'
                  );

      COMMIT;

      INSERT INTO tasktype
                  (tasktype, tlevel
                  )
           VALUES ('3-WorkFlow', '3'
                  );

      COMMIT;

      INSERT INTO tasktype
                  (tasktype, tlevel
                  )
           VALUES ('4-Personalization', '4'
                  );

      COMMIT;

      INSERT INTO tasktype
                  (tasktype, tlevel
                  )
           VALUES ('5-Alert', '5'
                  );

      COMMIT;

      INSERT INTO tasktype
                  (tasktype, tlevel
                  )
           VALUES ('6-OAF', '6'
                  );

      COMMIT;

      INSERT INTO tasktype
                  (tasktype, tlevel
                  )
           VALUES ('7-Profile', '7'
                  );

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('S1', 'The customer reference specified is invalid');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('S2', 'The address reference specified is invalid');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('S3',
                   'The address reference specified is not valid for this customer');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('S7',
                   'An active BILL_TO site must be defined for this customer and address');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('J8',
                   'Valid values for the INSERT_UPDATE_FLAG are ''I'' and ''U''');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('a3', 'The customer profile for insert already exists');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('a4',
                   'The customer profile for update does not exist Validate RA_CUSTOMER_PROFILES_INTERFACE.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('B7', 'CUSTOMER_PROFILE_CLASS_NAME has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('L1',
                   'COLLECTOR_NAME is mandatory when no profile class specified.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('L2',
                   'TOLERANCE is mandatory when no profile class specified.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('L3',
                   'DISCOUNT_TERMS is mandatory when no profile class specified.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('L4',
                   'DUNNING_LETTERS is mandatory when no profile class specified.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('L5',
                   'INTEREST_CHARGES is mandatory when no profile class specified.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('L6',
                   'STATEMENTS is mandatory when no profile class specified.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('L7',
                   'CREDIT_BALANCE_STATEMENTS mandatory when no profile class specified.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('L9',
                   'DUNNING_LETTER_SET_NAME is mandatory when DUNNING_LETTERS is "Yes"');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('L0',
                   'CHARGE_ON_FINANCE_CHARGE_FLAG mandatory when INTEREST_CHARGES is  "Yes"');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('X1',
                   'AUTO_REC_INCL_DISPUTED_FLAG mandatory when profile class is null');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('X2',
                   'TAX_PRINTING_OPTION is mandatory when no profile class specified');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('X3',
                   'GROUPING_RULE_NAME is mandatory when no profile class is specified');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('X4',
                   'CHARGE_ON_FINANCE_CHARGES_FLAG has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('X5', 'GROUPING_RULE_NAME has an invalid value');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('X6', 'CURRENCY_CODE has an invalid value');

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('X7',
                   'CREDIT_BALANCE_STATEMENTS is mandatory when STATEMENTS is "Yes"');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('X8',
                   'CREDIT_BALANCE_STATEMENTS must be "No" when STATEMENTS is "No"');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('X9',
                   'STATEMENT_CYCLE_NAME must be null when STATEMENTS is "No"');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('X0',
                   'OVERRIDE_TERMS is mandatory when no profile class is specified');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('M1',
                   'INTEREST_PERIOD_DAYS is mandatory when INTEREST_CHARGES is "Yes"');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('M3', 'COLLECTOR_NAME has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('M4', 'CREDIT_CHECKING has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('M5', 'TOLERANCE must be in the range -100 to 100');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('M6', 'DISCOUNT_TERMS has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('M7', 'DUNNING_LETTERS has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('M8', 'INTEREST_CHARGES has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('M9', 'STATEMENTS has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('M0', 'CREDIT_BALANCE_STATEMENTS has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('N1', 'CREDIT_HOLD has an invalid value');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('N2', 'CREDIT_RATING has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('N3', 'RISK_CODE has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('N4', 'STANDARD_TERM_NAME has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('N5', 'OVERRIDE_TERMS has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('N6', 'DUNNING_LETTER_SET has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('N7', 'STATEMENT_CYCLE_NAME has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('N8', 'ACCOUNT_STATUS has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('N9', 'PERCENT_COLLECTABLE must be in the range 0 to 100');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('N0', 'AUTOCASH_HIERARCHY_NAME has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('O1',
                   'STATEMENT_CYCLE_NAME is mandatory when STATEMENTS is "Yes".');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('O4',
                   'CREDIT_CHECKING is mandatory when profile class is null');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('O5',
                   'CHARGE_ON_FINANCE_CHARGE_FLAG must be null if INTEREST_CHARGES is No');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('O6',
                   'INTEREST_PERIOD_DAYS must be null if INTEREST_CHARGES is "No"');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('O7', 'INTEREST_PERIOD_DAYS must be greater than zero.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('Z1',
                   'CREDIT_BALANCE_STATEMENTS must be null when STATEMENTS is null');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('Z2',
                   'STATEMENT_CYCLE_NAME must be null when STATEMENTS is null');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('Z3',
                   'CHARGE_ON_FINANCE_CHARGE_FLAG must be null when INTEREST_CHARGES is null');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('Z4',
                   'INTEREST_PERIOD_DAYS must be null when INTEREST_CHARGES is null');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('Z5',
                   'DISCOUNT_GRACE_DAYS must be null when DISCOUNT_TERMS is null');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('Z6', 'DISCOUNT_GRACE_DAYS must be positive');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('Z7',
                   'DISCOUNT_GRACE_DAYS must be null when DISCOUNT_TERMS is "No"');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('Z8',
                   'DUNNING_LETTER_SET_NAME must be null when DUNNING_LETTERS is "No"');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('Z9',
                   'DUNNING_LETTER_SET_NAME must be null when DUNNING_LETTERS is null');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('Z0',
                   'CURRENCY_CODE is mandatory when a profile amount value is populated');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('a2', 'TAX_PRINTING_OPTION has an invalid value.');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('b1',
                   'TRX_CREDIT_LIMIT and OVERALL_CREDIT_LIMIT must be populated');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('b2',
                   'TRX_CREDIT_LIMIT may not be greater than the OVERALL_CREDIT_LIMIT');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('b3', 'DUNNING_LETTER_SET_NAME must have a unique value');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('b4', 'COLLECTOR_NAME must have a unique value');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('b5', 'STANDARD_TERM_NAME must have a unique value');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('b6', 'STATEMENT_CYCLE_NAME must have a unique value');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('b8', 'AUTO_REC_INCL_DISPUTE_FLAG has an invalid value');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('b9', 'PAYMENT_GRACE_DAYS must be greater than zero');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('y4', 'LOCKBOX_MATCHING_OPTION must have a valid value');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('w2', 'CREDIT_CLASSIFICATION must have a valid value');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('a7',
                   'Duplicate Customer profile record with the same currency code');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('a8',
                   'Duplicate Customer Profile record with same profile classes name specified');

      COMMIT;

      INSERT INTO xx_xrtx_cust_error_codes
           VALUES ('f4', 'CLEARING_DAYS value cannot be negative');

      COMMIT;

      INSERT INTO xx_xrtx_classification_t
                  (short_code, application)
         SELECT fav.application_short_name, fav.application_name
           FROM fnd_application_vl fav;

      UPDATE xx_xrtx_classification_t a
         SET app_id = (SELECT application_id
                         FROM fnd_application_vl fav
                        WHERE fav.application_short_name = a.short_code);

      COMMIT;

      UPDATE xx_xrtx_classification_t a
         SET basepath = (SELECT basepath
                           FROM fnd_application_vl fav
                          WHERE fav.application_short_name = a.short_code);

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Development'
       WHERE app_id = 0;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Development'
       WHERE app_id = 160;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Development'
       WHERE app_id = 174;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Development'
       WHERE app_id = 175;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Development'
       WHERE app_id = 190;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Development'
       WHERE app_id = 191;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Development'
       WHERE app_id = 231;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Development'
       WHERE app_id = 265;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Development'
       WHERE app_id = 271;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Development'
       WHERE app_id = 429;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Development'
       WHERE app_id = 603;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Development'
       WHERE app_id = 603;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 101;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 168;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 185;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 186;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 204;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 206;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 210;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 222;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 235;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 242;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 260;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 266;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 435;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 450;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 505;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 507;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 508;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 600;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 602;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 673;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 674;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 695;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 8400;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 8401;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 8402;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 8406;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 8450;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 8724;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Financial Management'
       WHERE app_id = 8901;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Asset Lifecycle Management'
       WHERE app_id = 140;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Asset Lifecycle Management'
       WHERE app_id = 205;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Asset Lifecycle Management'
       WHERE app_id = 240;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Asset Lifecycle Management'
       WHERE app_id = 275;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Asset Lifecycle Management'
       WHERE app_id = 426;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Asset Lifecycle Management'
       WHERE app_id = 430;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Asset Lifecycle Management'
       WHERE app_id = 432;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Asset Lifecycle Management'
       WHERE app_id = 440;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Asset Lifecycle Management'
       WHERE app_id = 540;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Asset Lifecycle Management'
       WHERE app_id = 718;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Asset Lifecycle Management'
       WHERE app_id = 777;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'DAsset Lifecycle Management'
       WHERE app_id = 867;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Asset Lifecycle Management'
       WHERE app_id = 873;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Asset Lifecycle Management'
       WHERE app_id = 8731;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 170;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 172;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 510;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 512;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 513;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 515;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 519;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 523;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 524;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 539;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 542;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 545;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 549;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 672;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 677;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 680;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 682;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 698;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 862;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 868;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 870;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 883;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 8407;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'E-Records'
       WHERE app_id = 207;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'E-Records'
       WHERE app_id = 709;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Discrete Manufacturing'
       WHERE app_id = 250;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Discrete Manufacturing'
       WHERE app_id = 388;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Discrete Manufacturing'
       WHERE app_id = 410;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Discrete Manufacturing'
       WHERE app_id = 700;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Discrete Manufacturing'
       WHERE app_id = 702;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Discrete Manufacturing'
       WHERE app_id = 703;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Discrete Manufacturing'
       WHERE app_id = 704;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Discrete Manufacturing'
       WHERE app_id = 705;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Discrete Manufacturing'
       WHERE app_id = 706;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Discrete Manufacturing'
       WHERE app_id = 9001;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Advance Procurement'
       WHERE app_id = 177;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Advance Procurement'
       WHERE app_id = 178;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Advance Procurement'
       WHERE app_id = 200;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Advance Procurement'
       WHERE app_id = 201;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Advance Procurement'
       WHERE app_id = 202;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Advance Procurement'
       WHERE app_id = 203;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Advance Procurement'
       WHERE app_id = 230;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Advance Procurement'
       WHERE app_id = 298;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Advance Procurement'
       WHERE app_id = 396;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Advance Procurement'
       WHERE app_id = 451;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Advance Procurement'
       WHERE app_id = 452;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Advance Procurement'
       WHERE app_id = 177;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 690;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 694;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 696;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 869;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 875;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 880;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 9000;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 511;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 506;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 517;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 520;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 521;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 522;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 667;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 280;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 283;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 689;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 875;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 521;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 530;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 544;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 676;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'CRM'
       WHERE app_id = 279;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 300;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 518;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 535;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 660;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 661;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 662;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 665;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 671;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 697;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 708;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 879;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Process Manufacturing'
       WHERE app_id = 550;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Process Manufacturing'
       WHERE app_id = 551;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Process Manufacturing'
       WHERE app_id = 552;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Process Manufacturing'
       WHERE app_id = 553;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Process Manufacturing'
       WHERE app_id = 554;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Process Manufacturing'
       WHERE app_id = 555;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Process Manufacturing'
       WHERE app_id = 556;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Process Manufacturing'
       WHERE app_id = 557;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Process Manufacturing'
       WHERE app_id = 558;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Process Manufacturing'
       WHERE app_id = 560;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Mobility'
       WHERE app_id = 405;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Mobility'
       WHERE app_id = 874;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Telecom'
       WHERE app_id = 534;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Telecom'
       WHERE app_id = 881;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Project Portfolio Management'
       WHERE app_id = 1292;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Project Portfolio Management'
       WHERE app_id = 8721;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Product Value Chain'
       WHERE app_id = 431;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Product Value Chain'
       WHERE app_id = 455;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Industry'
       WHERE app_id = 663;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Industry'
       WHERE app_id = 866;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Localization'
       WHERE app_id = 7000;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Localization'
       WHERE app_id = 7002;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Localization'
       WHERE app_id = 7003;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Localization'
       WHERE app_id = 7004;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Planning'
       WHERE app_id = 390;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Planning'
       WHERE app_id = 722;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Planning'
       WHERE app_id = 723;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Planning'
       WHERE app_id = 724;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Planning'
       WHERE app_id = 726;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Planning'
       WHERE app_id = 8722;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Planning'
       WHERE app_id = 8723;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Planning'
       WHERE app_id = 8727;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Planning'
       WHERE app_id = 9003;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Planning'
       WHERE app_id = 9004;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Oracle Web Analytics'
       WHERE app_id = 666;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Channel Revenue Management'
       WHERE app_id = 691;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 453;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 800;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 801;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 802;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 803;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 804;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 805;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 808;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 809;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 810;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 821;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 8301;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 8302;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 8303;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 8403;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 8404;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'HRMS'
       WHERE app_id = 8405;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET classification_b = 'Sales'
       WHERE app_id = 279;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET classification_b = 'Sales'
       WHERE app_id = 280;

      UPDATE xx_xrtx_classification_t
         SET classification_b = 'Sales'
       WHERE app_id = 506;

      UPDATE xx_xrtx_classification_t
         SET classification_b = 'Sales'
       WHERE app_id = 521;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET classification_b = 'Sales'
       WHERE app_id = 522;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET classification_b = 'Sales'
       WHERE app_id = 544;

      UPDATE xx_xrtx_classification_t
         SET classification_b = 'Sales'
       WHERE app_id = 676;

      UPDATE xx_xrtx_classification_t
         SET classification_b = 'Sales'
       WHERE app_id = 694;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET classification_b = 'Sales'
       WHERE app_id = 869;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET classification_b = 'Sales'
       WHERE app_id = 880;

      UPDATE xx_xrtx_classification_t
         SET classification_b = 'Incentive Compensation'
       WHERE app_id = 283;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET classification_b = 'Project Portfolio Management'
       WHERE app_id = 440;

      UPDATE xx_xrtx_classification_t
         SET classification_b = 'Project Portfolio Management'
       WHERE app_id = 772;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET classification_b = 'CRM'
       WHERE app_id = 539;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET classification_b = 'eMRO'
       WHERE app_id = 867;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET classification_b = 'Maintenance Management'
       WHERE app_id = 873;

      UPDATE xx_xrtx_classification_t
         SET classification_b = NULL
       WHERE classification_b = 'Administrator';

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Administrator'
       WHERE app_id = 1;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Administrator'
       WHERE app_id = 3;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Administrator'
       WHERE app_id = 50;

      COMMIT;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Administrator'
       WHERE app_id = 60;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Administrator'
       WHERE app_id = 274;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Administrator'
       WHERE app_id = 278;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Administrator'
       WHERE app_id = 438;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Administrator'
       WHERE app_id = 601;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Execution'
       WHERE app_id = 385;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Execution'
       WHERE app_id = 401;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Execution'
       WHERE app_id = 401;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Execution'
       WHERE app_id = 454;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Service Management'
       WHERE app_id = 699;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Flow Manufacturing'
       WHERE app_id = 714;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Execution'
       WHERE app_id = 701;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Execution'
       WHERE app_id = 778;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Execution'
       WHERE app_id = 716;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Execution'
       WHERE app_id = 9004;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 697;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Project Manufacturing'
       WHERE app_id = 712;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Asset Lifecycle Management'
       WHERE app_id = 867;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Channel Revenue Management'
       WHERE app_id = 691;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Execution'
       WHERE app_id = 385;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Execution'
       WHERE app_id = 401;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Execution'
       WHERE app_id = 454;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Execution'
       WHERE app_id = 701;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Execution'
       WHERE app_id = 716;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Execution'
       WHERE app_id = 778;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Value Chain Execution'
       WHERE app_id = 9004;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 300;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 518;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 535;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 660;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 661;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 662;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 665;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 671;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 697;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 708;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 879;

      UPDATE xx_xrtx_classification_t
         SET module_classification = 'Order Fufillment'
       WHERE app_id = 697;


insert into xx_xrtx_gl_error_codes values('EP01',' This date is not in any open or future enterable period.');

insert into xx_xrtx_gl_error_codes values('EP02',' This set of books does not have any open or future enterable periods.');

insert into xx_xrtx_gl_error_codes values('EP03',' This date is not within any period in an open encumbrance year.');

insert into xx_xrtx_gl_error_codes values('EP04',' This date is not a business day.');

insert into xx_xrtx_gl_error_codes values('EP05',' There are no business days in this period');

insert into xx_xrtx_gl_error_codes values('WU01',' Warning: This journal entry is unbalanced. It is accepted because suspense posting is allowed in this set of books.');

insert into xx_xrtx_gl_error_codes values('EU02',' This journal entry is unbalanced and suspense posting is not allowed in this set of books.');

insert into xx_xrtx_gl_error_codes values('EU03',' This encumbrance journal entry is unbalanced and the Reserve for Encumbrance account is not defined.');

insert into xx_xrtx_gl_error_codes values('EF01',' This Accounting Flexfield is inactive for this accounting date.');

insert into xx_xrtx_gl_error_codes values('EF02',' Detail posting not allowed for this Accounting Flexfield.');

insert into xx_xrtx_gl_error_codes values('EF03',' Disabled Accounting Flexfield.');

insert into xx_xrtx_gl_error_codes values('EF04',' This is an invalid Accounting Flexfield. Check your cross-validation rules and segment values.');

insert into xx_xrtx_gl_error_codes values('EF05',' There is no Accounting Flexfield with this Code Combination ID.');

insert into xx_xrtx_gl_error_codes values('EC01',' A conversion rate must be entered when using the User conversion rate type.');

insert into xx_xrtx_gl_error_codes values('EC02',' There is no conversion date supplied.');

insert into xx_xrtx_gl_error_codes values('EC03',' A conversion rate type or an accounted amount must be supplied when entering foreign currency journal lines.');

insert into xx_xrtx_gl_error_codes values('EC06',' There is no conversion rate for this currency, conversion type and conversion date.');

insert into xx_xrtx_gl_error_codes values('EC08',' Invalid currency code.');

insert into xx_xrtx_gl_error_codes values('EC09',' No currencies are enabled.');

insert into xx_xrtx_gl_error_codes values('EC10',' Encumbrance journals cannot be created in a foreign currency.');

insert into xx_xrtx_gl_error_codes values('EC11',' Invalid conversion rate type.');

insert into xx_xrtx_gl_error_codes values('EC12',' The entered amount must equal the accounted amount in a functional or STAT currency journal line.');

insert into xx_xrtx_gl_error_codes values('EC13',' The entered amount multiplied by the conversion rate must equal the accounted amount.');

insert into xx_xrtx_gl_error_codes values('ECW1',' Warning: Converted amounts could not be validated because the conversion rate type is not specified.');

insert into xx_xrtx_gl_error_codes values('EB01',' A budget version is required for budget lines.');

insert into xx_xrtx_gl_error_codes values('EB02',' Journals cannot be created for a frozen budget.');

insert into xx_xrtx_gl_error_codes values('EB03',' The budget year is not open.');

insert into xx_xrtx_gl_error_codes values('EB04',' This budget does not exist for this set of books.');

insert into xx_xrtx_gl_error_codes values('EB05',' The encumbrance_type_id column must be null for budget journals.');

insert into xx_xrtx_gl_error_codes values('EB06',' A period name is required for budget journals.');

insert into xx_xrtx_gl_error_codes values('EB07',' This period name is not valid. Check calendar for valid periods.');

insert into xx_xrtx_gl_error_codes values('EB08',' Average journals cannot be created for budgets.');

insert into xx_xrtx_gl_error_codes values('EB09',' Originating company information cannot be specified for budgets.');

insert into xx_xrtx_gl_error_codes values('EE01',' An encumbrance type is required for encumbrance lines.');

insert into xx_xrtx_gl_error_codes values('EE02',' Invalid or disabled encumbrance type.');

insert into xx_xrtx_gl_error_codes values('EE03',' Encumbrance journals cannot be created in the STAT currency.');

insert into xx_xrtx_gl_error_codes values('EE04',' The BUDGET_VERSION_ID column must be null for encumbrance lines.');

insert into xx_xrtx_gl_error_codes values('EE05',' Average journals cannot be created for encumbrances.');

insert into xx_xrtx_gl_error_codes values('EE06',' Originating company information cannot be specified for encumbrances.');

insert into xx_xrtx_gl_error_codes values('ER01',' A reversal period name must be provided.');

insert into xx_xrtx_gl_error_codes values('ER02',' This reversal period name is invalid. Check your calendar for valid periods.');

insert into xx_xrtx_gl_error_codes values('ER03',' A reversal date must be provided');

insert into xx_xrtx_gl_error_codes values('ER04',' This reversal date is not in a valid period.');

insert into xx_xrtx_gl_error_codes values('ER05',' This reversal date is not in your database date format.');

insert into xx_xrtx_gl_error_codes values('ER06',' Your reversal date must be the same as or after your effective date.');

insert into xx_xrtx_gl_error_codes values('ER07',' This reversal date is not a business day.');

insert into xx_xrtx_gl_error_codes values('ER08',' There are no business days in your reversal period.');

insert into xx_xrtx_gl_error_codes values('ER09',' Default reversal information could not be determined.');

insert into xx_xrtx_gl_error_codes values('ED01',' The context and attribute values do not form a valid descriptive flexfield for Journals ? Journal Entry Lines.');

insert into xx_xrtx_gl_error_codes values('ED02',' The context and attribute values do not form a valid descriptive flexfield for Journals ? Captured Information.');

insert into xx_xrtx_gl_error_codes values('ED03',' The context and attribute values do not form a valid descriptive flexfield for Value Added Tax.');

insert into xx_xrtx_gl_error_codes values('EM01',' Invalid journal entry category.');

insert into xx_xrtx_gl_error_codes values('EM02',' There are no journal entry categories defined.');

insert into xx_xrtx_gl_error_codes values('EM03',' Invalid set of books id.');

insert into xx_xrtx_gl_error_codes values('EM04',' The value in the ACTUAL_FLAG must be "A" (actuals), "B" (budgets), or "E" (encumbrances).');

insert into xx_xrtx_gl_error_codes values('EM05',' The encumbrance_type_id column must be null for actual journals.');

insert into xx_xrtx_gl_error_codes values('EM06',' The budget_version_id column must be null for actual journals.');

insert into xx_xrtx_gl_error_codes values('EM07',' A statistical amount belongs in the entered_dr(cr) column when entering a STAT currency journal line.');

insert into xx_xrtx_gl_error_codes values('EM09',' There is no Transaction Code defined.');

insert into xx_xrtx_gl_error_codes values('EM10',' Invalid Transaction Code.');

insert into xx_xrtx_gl_error_codes values('EM12',' An Oracle error occurred when generating sequential numbering.');

insert into xx_xrtx_gl_error_codes values('EM13',' The assigned sequence is inactive.');

insert into xx_xrtx_gl_error_codes values('EM14',' There is a sequential numbering setup error resulting from a missing grant or synonym.');

insert into xx_xrtx_gl_error_codes values('EM17',' Sequential numbering is always used and there is no assignment for this set of books and journal entry category.');

insert into xx_xrtx_gl_error_codes values('EM18',' Manual document sequences cannot be used with Journal Import.');

insert into xx_xrtx_gl_error_codes values('EM19',' Value Added Tax data is only valid in conjunction with actual journals.');

insert into xx_xrtx_gl_error_codes values('EM21',' Budgetary Control must be enabled to import this batch.');

insert into xx_xrtx_gl_error_codes values('EM22',' A conversion rate must be defined for this accounting date, your default conversion rate type, and your dual currency.');

insert into xx_xrtx_gl_error_codes values('EM23',' There is no value entered for the Dual Currency Default Rate Type profile option.');

insert into xx_xrtx_gl_error_codes values('EM24',' Average journals can only be imported into consolidation sets of books.');

insert into xx_xrtx_gl_error_codes values('EM25',' Invalid average journal flag. Valid values are "Y", "N", and null.');

insert into xx_xrtx_gl_error_codes values('EM26',' Invalid originating company.');

INSERT INTO xx_xrtx_gl_error_codes VALUES('EM27',' Originating company information can only be specified when intercompany balancing is enabled');

      INSERT INTO xx_xrtx_dayws_module_cls_t
         (SELECT   DECODE (TO_CHAR (start_time, 'D'),
                           1, 'Sunday',
                           2, 'Monday',
                           3, 'Tuesday',
                           4, 'Wednesday',
                           5, 'Thursday',
                           6, 'Friday',
                           7, 'Saturday'
                          ) usage_day,
                   xxct.module_classification,
                   COUNT (xxct.module_classification) total_usage_count,
                   ROUND
                       (  COUNT (xxct.module_classification)
                        / (TO_DATE (dr.end_date) - TO_DATE (dr.start_date)),
                        2
                       ) avg_login_per_day,
                   ROUND (SUM ((end_time - start_time) * 24 * 60),
                          2
                         ) total_usage_mins,
                   ROUND (AVG ((end_time - start_time) * 24 * 60),
                          2
                         ) mins_usage_per_day
              FROM fnd_login_responsibilities flr,
                   xx_xrtx_classification_t xxct,
                   xx_xrtx_hldate_range dr,
                   fnd_application_tl fat
             WHERE flr.start_time BETWEEN TO_DATE (dr.start_date)
                                      AND TO_DATE (dr.end_date)
               AND flr.resp_appl_id = xxct.app_id
               AND fat.LANGUAGE = 'US'
          GROUP BY TO_CHAR (start_time, 'D'),
                   dr.start_date,
                   dr.end_date,
                   xxct.module_classification);

      COMMIT;

      INSERT INTO xx_xrtx_hrws_module_cls_t
         (SELECT   TO_CHAR (flr.start_time, 'HH24') login_hour,
                   xxct.module_classification, COUNT (*) total_usage_count,
                   ROUND (  COUNT (*)
                          / (TO_DATE (dr.end_date) - TO_DATE (dr.start_date)),
                          2
                         ) avg_login_per_hr,
                   ROUND (SUM ((flr.end_time - flr.start_time) * 24 * 60),
                          2
                         ) total_usage_mins,
                   ROUND (AVG ((flr.end_time - flr.start_time) * 24 * 60),
                          2
                         ) avg_mins_usage
              FROM fnd_login_responsibilities flr,
                   xx_xrtx_classification_t xxct,
                   fnd_application_tl fat,
                   xx_xrtx_hldate_range dr
             WHERE start_time BETWEEN TO_DATE (dr.start_date)
                                  AND TO_DATE (dr.end_date)
               AND fat.LANGUAGE = 'US'
               AND flr.resp_appl_id = xxct.app_id
          GROUP BY TO_CHAR (start_time, 'HH24'),
                   dr.start_date,
                   dr.end_date,
                   xxct.module_classification);

      COMMIT;

      INSERT INTO xx_xrtx_mc_user_count_t
                  (module_classification, total_modules_installed)
         SELECT   module_classification, COUNT (*)
             FROM xx_xrtx_classification_t xxct
         GROUP BY module_classification;

      COMMIT;

      UPDATE xx_xrtx_mc_user_count_t a
         SET user_acess_module_wise =
                (SELECT   COUNT (*) "CNT"
                     FROM fnd_user_resp_groups furg,
                          fnd_user fu,
                          fnd_application fa,
                          fnd_application_tl fat,
                          xx_xrtx_classification_t xxct
                    WHERE NVL (furg.end_date, SYSDATE + 1) > SYSDATE
                      AND NVL (fu.end_date, SYSDATE + 1) > SYSDATE
                      AND (fu.start_date + NVL (fu.password_lifespan_days, 0)
                          ) < SYSDATE
                      AND furg.user_id = fu.user_id
                      AND fat.LANGUAGE = 'US'
                      AND fat.application_id =
                                            furg.responsibility_application_id
                      AND fa.application_id = fat.application_id
                      AND xxct.app_id = furg.responsibility_application_id
                      AND xxct.module_classification = a.module_classification
                 GROUP BY xxct.module_classification);

      COMMIT;

      INSERT INTO xx_xrtx_cust_int_err
         SELECT interface_status, customer_name, org_id
           FROM ra_customers_interface_all;

      COMMIT;

      INSERT INTO xx_xrtx_cust_profile_err
         SELECT interface_status, customer_profile_class_name, org_id
           FROM ra_customer_profiles_int_all;

      COMMIT;

      INSERT INTO xx_xrtx_db_schema_t
         (SELECT username, user_id, PASSWORD, account_status, lock_date,
                 expiry_date, default_tablespace, temporary_tablespace,
                 created, PROFILE, initial_rsrc_consumer_group
            FROM dba_users);

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('OE_ORDER_PUB', 'API USED TO PROCESS ORDER',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%OE_ORDER_PUB%' AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('OE_PRICING_CONT_PUB', 'API USED TO PROCESS AGREEMENT',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%OE_PRICING_CONT_PUB%'
                       AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('QP_ATTR_MAPPING_PUB', 'API USED TO BUILD CONTEXTS',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%QP_ATTR_MAPPING_PUB%'
                       AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('QP_MODIFIERS_PUB', 'API USED TO PROCESS MODIFIERS',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%QP_MODIFIERS_PUB%' AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('QP_PRICE_FORMULA_PUB',
                   'API USED TO PROCESS PRICE FORMULA',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%QP_PRICE_FORMULA_PUB%'
                       AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('QP_LIMITS_PUB', 'API USED TO PROCESS PRICE LIMITS',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%QP_LIMITS_PUB%' AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('QP_PRICE_BOOK_PUB',
                   'API USED TO CREATE PUBLISH PRICE BOOK',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%QP_PRICE_BOOK_PUB%' AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('QP_RUNTIME_SOURCE',
                   'API USED TO GET CUSTOM UNTIME SOURCING',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%QP_RUNTIME_SOURCE%' AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('QP_CURRENCY_PUB', 'API USED TO GET CURRENCY',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%QP_CURRENCY_PUB%' AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('QP_UTIL_PUB', 'API USED TO GET ATTRIBUTE TEXT',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%QP_UTIL_PUB%' AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('QP_CUSTOM',
                   'API USED TO GET CUSTOM PRICE (Used in Formulas Setup)',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%QP_CUSTOM%' AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('QP_PRICE_BOOK', 'API USED TO GET PRICE BOOK',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%QP_PRICE_BOOK%' AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('QP_PREQ_PUB', 'API USED TO GET PRICE FOR LINE',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%QP_PREQ_PUB%' AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('QP_PRICE_LIST_PUB', 'API USED TO GET PRICE LIST SETUP',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%QP_PRICE_LIST_PUB%' AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('QP_PRICE_LIST_GRP',
                   'API USED TO GET PRICE LIST SETUP GROUP',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%QP_PRICE_LIST_GRP%' AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('QP_BULK_LOADER_PUB',
                   'API USED FOR PRICING DATA BULK LOADER',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%QP_BULK_LOADER_PUB%'
                           AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('WSH_TRIP_STOPS_PUB', 'API USED FOR STOP PUBLIC',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%WSH_TRIP_STOPS_PUB%'
                           AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('WSH_DELIVERIES_PUB', 'API USED FOR DELIVERIES PUBLIC',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%WSH_DELIVERIES_PUB%'
                           AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('QP_QUALIFIER_RULES_PUB',
                   'API USED TO PROCESS QUALIFIER RULES',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%QP_QUALIFIER_RULES_PUB%'
                       AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('WSH_TRIPS_PUB', 'API USED FOR TRIP PUBLIC',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%WSH_TRIPS_PUB%' AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('WSH_EXCEPTIONS_PUB', 'API USED FOR EXCEPTIONS PUBLIC',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%WSH_EXCEPTIONS_PUB%'
                           AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('WSH_DELIVERY_DETAILS_PUB',
                   'API USED FOR DELIVERY DETAILS PUBLIC',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%WSH_DELIVERY_DETAILS_PUB%'
                       AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('WSH_CONTAINER_PUB', 'API USED FOR CONTAINER PUBLIC',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%WSH_CONTAINER_PUB%' AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('WSH_FREIGHT_COSTS_PUB',
                   'API USED FOR FREIGHT COSTS PUBLIC',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%WSH_FREIGHT_COSTS_PUB%'
                       AND NAME LIKE 'XX%'));

      COMMIT;

      INSERT INTO xx_xrtx_api_list
           VALUES ('WSH_PICKING_BATCHES_PUB', 'API USED FOR PICK RELEASE',
                   (SELECT COUNT (DISTINCT NAME)
                      FROM all_source
                     WHERE              -- TYPE IN ('PACKAGE', 'PACKAGE BODY')
--AND
                           text LIKE '%WSH_PICKING_BATCHES_PUB%'
                       AND NAME LIKE 'XX%'));

      COMMIT;
   END xx_xrtx_all_tables_data_pro;

   FUNCTION xx_master_all (p_org_id NUMBER)
      RETURN NUMBER
   IS
      v_cnt   NUMBER;
   BEGIN
      SELECT   COUNT (a.segment1)                       --,b.organization_code
          INTO v_cnt
          FROM apps.mtl_system_items_b a, apps.mtl_parameters b
         WHERE a.organization_id = b.organization_id
           AND a.organization_id = p_org_id
      GROUP BY b.organization_code;

      RETURN (v_cnt);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_cnt := NULL;
         RETURN v_cnt;
   END xx_master_all;

   FUNCTION xx_master_manual (p_org_id NUMBER)
      RETURN NUMBER
   IS
      v_cnt   NUMBER;
   BEGIN
      SELECT   COUNT (a.segment1)                       --,b.organization_code
          INTO v_cnt
          FROM apps.mtl_system_items_b a, apps.mtl_parameters b
         WHERE a.organization_id = b.organization_id
           AND a.request_id IS NULL
           AND a.program_application_id IS NULL
           AND a.program_id IS NULL
           AND a.organization_id = p_org_id
      GROUP BY b.organization_code;

      RETURN (v_cnt);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_cnt := NULL;
         RETURN v_cnt;
   END xx_master_manual;

   FUNCTION xx_master_intf (p_org_id NUMBER)
      RETURN NUMBER
   IS
      v_cnt   NUMBER;
   BEGIN
      SELECT   COUNT (a.segment1)                       --,b.organization_code
          INTO v_cnt
          FROM apps.mtl_system_items_b a, apps.mtl_parameters b
         WHERE a.organization_id = b.organization_id
           AND a.request_id IS NOT NULL
           AND a.program_application_id IS NOT NULL
           AND a.program_id IS NOT NULL
           AND a.organization_id = p_org_id
      GROUP BY b.organization_code;

      RETURN (v_cnt);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_cnt := NULL;
         RETURN v_cnt;
   END xx_master_intf;

   PROCEDURE xx_coa_load_table_p
   IS
   BEGIN
      DELETE FROM xx_coa_structure;

      FOR count_rec IN (SELECT fifs.id_flex_num, fifs.segment_num,
                               fifs.segment_name,
                               fifs.application_column_name,
                               fifs.DEFAULT_VALUE
                          FROM fnd_id_flex_segments fifs,
                               fnd_id_flex_structures_vl fifsv
                         WHERE fifs.id_flex_code = fifsv.id_flex_code
                           -- AND fifsv.id_flex_structure_code = 'OPERATIONS_ACCOUNTING_FLEX'
                           AND fifsv.id_flex_code = 'GLLE'
                           AND fifs.enabled_flag = 'Y'
                           AND display_flag = 'Y'
                           AND freeze_flex_definition_flag = 'Y'
                           AND fifs.id_flex_num = fifsv.id_flex_num)
      LOOP
         BEGIN
            INSERT INTO xx_coa_structure
                        (coa_id, segment_num,
                         segment_name,
                         application_column_name,
                         DEFAULT_VALUE
                        )
                 VALUES (count_rec.id_flex_num, count_rec.segment_num,
                         count_rec.segment_name,
                         count_rec.application_column_name,
                         count_rec.DEFAULT_VALUE
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               DBMS_OUTPUT.put_line
                    ('ERROR WHILE INSERTING DATA INTO TABLE xx_coa_structure');
         END;

         COMMIT;
      END LOOP;
   END xx_coa_load_table_p;

   PROCEDURE xx_coa_user
   IS
   BEGIN
      FOR my_rec IN (SELECT DISTINCT coa_id, segment_num, segment_name,
                                     application_column_name
                                FROM xx_coa_structure)
      LOOP
         FOR my_rec1 IN (SELECT application_column_name
                           FROM xx_coa_structure
                          WHERE coa_id = my_rec.coa_id
                            AND application_column_name IN
                                   ('SEGMENT1',
                                    'SEGMENT2',
                                    'SEGMENT3',
                                    'SEGMENT4',
                                    'SEGMENT5',
                                    'SEGMENT6',
                                    'SEGMENT7',
                                    'SEGMENT8',
                                    'SEGMENT9',
                                    'SEGMENT10',
                                    'SEGMENT11',
                                    'SEGMENT12',
                                    'SEGMENT13',
                                    'SEGMENT14',
                                    'SEGMENT15',
                                    'SEGMENT16',
                                    'SEGMENT17',
                                    'SEGMENT18',
                                    'SEGMENT19',
                                    'SEGMENT20',
                                    'SEGMENT1',
                                    'SEGMENT21',
                                    'SEGMENT22',
                                    'LEDGER_SEGMENT'
                                   ))
         LOOP
            BEGIN
               UPDATE xx_coa_structure a
                  SET gl_account =
                         (SELECT attribute_value
                            FROM fnd_segment_attribute_values fsav
                           WHERE fsav.id_flex_num = my_rec.coa_id
                             AND fsav.id_flex_code = 'GLLE'
                             AND fsav.application_column_name =
                                               my_rec1.application_column_name
                             AND fsav.segment_attribute_type = 'GL_ACCOUNT')
                WHERE a.application_column_name =
                                               my_rec1.application_column_name
                  --between 'SEGMENT1' and 'SEGMENT9'
                  AND a.coa_id = my_rec.coa_id;

               UPDATE xx_coa_structure a
                  SET gl_balancing =
                         (SELECT attribute_value
                            FROM fnd_segment_attribute_values fsav
                           WHERE fsav.id_flex_num = my_rec.coa_id
                             AND fsav.id_flex_code = 'GLLE'
                             AND fsav.application_column_name =
                                               my_rec1.application_column_name
                             AND fsav.segment_attribute_type = 'GL_BALANCING')
                WHERE a.application_column_name =
                                               my_rec1.application_column_name
                  --between 'SEGMENT1' and 'SEGMENT9'
                  AND a.coa_id = my_rec.coa_id;

               UPDATE xx_coa_structure a
                  SET gl_management =
                         (SELECT attribute_value
                            FROM fnd_segment_attribute_values fsav
                           WHERE fsav.id_flex_num = my_rec.coa_id
                             AND fsav.id_flex_code = 'GLLE'
                             AND fsav.application_column_name =
                                               my_rec1.application_column_name
                             AND fsav.segment_attribute_type = 'GL_MANAGEMENT')
                WHERE a.application_column_name =
                                               my_rec1.application_column_name
                  AND a.coa_id = my_rec.coa_id;

               UPDATE xx_coa_structure a
                  SET fa_cost_ctr =
                         (SELECT attribute_value
                            FROM fnd_segment_attribute_values fsav
                           WHERE fsav.id_flex_num = my_rec.coa_id
                             AND fsav.id_flex_code = 'GLLE'
                             AND fsav.application_column_name =
                                               my_rec1.application_column_name
                             AND fsav.segment_attribute_type = 'FA_COST_CTR')
                WHERE a.application_column_name =
                                               my_rec1.application_column_name
                  AND a.coa_id = my_rec.coa_id;

               UPDATE xx_coa_structure a
                  SET gl_secondary_tracking =
                         (SELECT attribute_value
                            FROM fnd_segment_attribute_values fsav
                           WHERE fsav.id_flex_num = my_rec.coa_id
                             AND fsav.id_flex_code = 'GLLE'
                             AND fsav.application_column_name =
                                               my_rec1.application_column_name
                             AND fsav.segment_attribute_type =
                                                       'GL_SECONDARY_TRACKING')
                WHERE a.application_column_name =
                                               my_rec1.application_column_name
                  AND a.coa_id = my_rec.coa_id;

               UPDATE xx_coa_structure a
                  SET gl_intercompany =
                         (SELECT attribute_value
                            FROM fnd_segment_attribute_values fsav
                           WHERE fsav.id_flex_num = my_rec.coa_id
                             AND fsav.id_flex_code = 'GLLE'
                             AND fsav.application_column_name =
                                               my_rec1.application_column_name
                             AND fsav.segment_attribute_type =
                                                             'GL_INTERCOMPANY')
                WHERE a.application_column_name =
                                               my_rec1.application_column_name
                  AND a.coa_id = my_rec.coa_id;

               UPDATE xx_coa_structure a
                  SET gl_ledger =
                         (SELECT attribute_value
                            FROM fnd_segment_attribute_values fsav
                           WHERE fsav.id_flex_num = my_rec.coa_id
                             AND fsav.id_flex_code = 'GLLE'
                             AND fsav.application_column_name =
                                               my_rec1.application_column_name
                             AND fsav.segment_attribute_type = 'GL_LEDGER')
                WHERE a.application_column_name =
                                               my_rec1.application_column_name
                  AND a.coa_id = my_rec.coa_id;

               UPDATE xx_coa_structure a
                  SET coa_name =
                         (SELECT DISTINCT fifs.id_flex_structure_code
                                     FROM gl_sets_of_books gsob,
                                          fnd_id_flex_structures fifs
                                    WHERE gsob.chart_of_accounts_id =
                                                              fifs.id_flex_num
                                      AND fifs.id_flex_num = my_rec.coa_id
                                      AND fifs.id_flex_code = 'GLLE')
                WHERE a.application_column_name =
                                               my_rec1.application_column_name
                  AND a.coa_id = my_rec.coa_id;
            END;

            COMMIT;
         END LOOP;
      END LOOP;
   END;

   PROCEDURE xx_xrtx_load_table_p
   IS
   BEGIN
      DELETE FROM xx_xrtx_segments_t;

      FOR count_rec IN (SELECT segment_name, a.description, a.enabled_flag,
                               application_column_name, segment_num,
                               display_flag, form_above_prompt,
                               form_left_prompt, c.flex_value_set_id,
                               c.flex_value_set_name, a.id_flex_num,
                               a.id_flex_code, a.application_id
                          FROM fnd_id_flex_segments_vl a,
                               xx_xrtx_structure_name_t b,
                               fnd_flex_value_sets c
                         WHERE c.flex_value_set_id = a.flex_value_set_id
                           AND (a.id_flex_num = b.id_flex_num)
                           AND (a.id_flex_code = b.id_flex_code)
                           AND a.id_flex_code <> 'GL#'
                           AND (a.application_id = b.application_id))
      LOOP
         BEGIN
            INSERT INTO xx_xrtx_segments_t
                        (segment_name, description,
                         enabled_flag,
                         application_column_name,
                         segment_num, display_flag,
                         form_above_prompt,
                         form_left_prompt,
                         flex_value_set_id,
                         flex_value_set_name,
                         id_flex_num, id_flex_code,
                         application_id
                        )
                 VALUES (count_rec.segment_name, count_rec.description,
                         count_rec.enabled_flag,
                         count_rec.application_column_name,
                         count_rec.segment_num, count_rec.display_flag,
                         count_rec.form_above_prompt,
                         count_rec.form_left_prompt,
                         count_rec.flex_value_set_id,
                         count_rec.flex_value_set_name,
                         count_rec.id_flex_num, count_rec.id_flex_code,
                         count_rec.application_id
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               DBMS_OUTPUT.put_line
                  ('ERROR WHILE INSERTING DATA INTO TABLE xx_xrtx_flex_segments_t'
                  );
         END;

         COMMIT;
      END LOOP;
   END xx_xrtx_load_table_p;

   PROCEDURE xx_xrtx_qual_p
   IS
   BEGIN
      FOR my_rec IN (SELECT DISTINCT id_flex_num, id_flex_code, segment_num,
                                     segment_name, application_column_name
                                FROM xx_xrtx_segments_t)
      LOOP
         FOR my_rec1 IN (SELECT application_column_name
                           FROM xx_xrtx_segments_t
                          WHERE id_flex_num = my_rec.id_flex_num
                            AND application_column_name IN
                                   ('SEGMENT1',
                                    'SEGMENT2',
                                    'SEGMENT3',
                                    'SEGMENT4',
                                    'SEGMENT5',
                                    'SEGMENT6',
                                    'SEGMENT7',
                                    'SEGMENT8',
                                    'SEGMENT9',
                                    'SEGMENT10',
                                    'SEGMENT11',
                                    'SEGMENT12',
                                    'SEGMENT13',
                                    'SEGMENT14',
                                    'SEGMENT15',
                                    'SEGMENT16',
                                    'SEGMENT17',
                                    'SEGMENT18',
                                    'SEGMENT19',
                                    'SEGMENT20',
                                    'SEGMENT1',
                                    'SEGMENT21',
                                    'SEGMENT22',
                                    'LEDGER_SEGMENT'
                                   ))
         LOOP
            BEGIN
               UPDATE xx_xrtx_segments_t a
                  SET gl_account =
                         (SELECT attribute_value
                            FROM fnd_segment_attribute_values fsav
                           WHERE fsav.id_flex_num = my_rec.id_flex_num
                             AND fsav.id_flex_code IN
                                    ('CAT#',
                                     'FII#',
                                     'CAGR',
                                     'COST',
                                     'RLOC',
                                     'SCL',
                                     'MTLL',
                                     'MCAT',
                                     'LOC#',
                                     'CMP',
                                     'JOB',
                                     'GLLE',
                                     'SERV',
                                     'MKTS',
                                     'GLAT'
                                    )
--and fsav.id_flex_code<>'GL#'
--and  fsav.ATTRIBUTE_VALUE='Y'
                             AND fsav.application_column_name =
                                               my_rec1.application_column_name
                             AND fsav.segment_attribute_type = 'GL_ACCOUNT')
                WHERE a.application_column_name =
                                               my_rec1.application_column_name
                  --between 'SEGMENT1' and 'SEGMENT9'
                  AND a.id_flex_num = my_rec.id_flex_num;

               UPDATE xx_xrtx_segments_t a
                  SET gl_balancing =
                         (SELECT attribute_value
                            FROM fnd_segment_attribute_values fsav
                           WHERE fsav.id_flex_num = my_rec.id_flex_num
                             AND fsav.id_flex_code IN
                                    ('CAT#',
                                     'FII#',
                                     'CAGR',
                                     'COST',
                                     'RLOC',
                                     'SCL',
                                     'MTLL',
                                     'MCAT',
                                     'LOC#',
                                     'CMP',
                                     'JOB',
                                     'GLLE',
                                     'SERV',
                                     'MKTS',
                                     'GLAT'
                                    )
--and fsav.id_flex_code<>'GL#'
--and fsav.ATTRIBUTE_VALUE='Y'
                             AND fsav.application_column_name =
                                               my_rec1.application_column_name
                             AND fsav.segment_attribute_type = 'GL_BALANCING')
                WHERE a.application_column_name =
                                               my_rec1.application_column_name
                  --between 'SEGMENT1' and 'SEGMENT9'
                  AND a.id_flex_num = my_rec.id_flex_num;

               UPDATE xx_xrtx_segments_t a
                  SET gl_management =
                         (SELECT attribute_value
                            FROM fnd_segment_attribute_values fsav
                           WHERE fsav.id_flex_num = my_rec.id_flex_num
                             AND fsav.id_flex_code IN
                                    ('CAT#',
                                     'FII#',
                                     'CAGR',
                                     'COST',
                                     'RLOC',
                                     'SCL',
                                     'MTLL',
                                     'MCAT',
                                     'LOC#',
                                     'CMP',
                                     'JOB',
                                     'GLLE',
                                     'SERV',
                                     'MKTS',
                                     'GLAT'
                                    )
--and fsav.id_flex_code<>'GL#'
--and  fsav.ATTRIBUTE_VALUE='Y'
                             AND fsav.application_column_name =
                                               my_rec1.application_column_name
                             AND fsav.segment_attribute_type = 'GL_MANAGEMENT')
                WHERE a.application_column_name =
                                               my_rec1.application_column_name
                  AND a.id_flex_num = my_rec.id_flex_num;

               UPDATE xx_xrtx_segments_t a
                  SET fa_cost_ctr =
                         (SELECT attribute_value
                            FROM fnd_segment_attribute_values fsav
                           WHERE fsav.id_flex_num = my_rec.id_flex_num
                             AND fsav.id_flex_code IN
                                    ('CAT#',
                                     'FII#',
                                     'CAGR',
                                     'COST',
                                     'RLOC',
                                     'SCL',
                                     'MTLL',
                                     'MCAT',
                                     'LOC#',
                                     'CMP',
                                     'JOB',
                                     'GLLE',
                                     'SERV',
                                     'MKTS',
                                     'GLAT'
                                    )
--and fsav.id_flex_code<>'GL#'
--and  fsav.ATTRIBUTE_VALUE='Y'
                             AND fsav.application_column_name =
                                               my_rec1.application_column_name
                             AND fsav.segment_attribute_type = 'FA_COST_CTR')
                WHERE a.application_column_name =
                                               my_rec1.application_column_name
                  AND a.id_flex_num = my_rec.id_flex_num;

               UPDATE xx_xrtx_segments_t a
                  SET gl_secondary_tracking =
                         (SELECT attribute_value
                            FROM fnd_segment_attribute_values fsav
                           WHERE fsav.id_flex_num = my_rec.id_flex_num
                             AND fsav.id_flex_code IN
                                    ('CAT#',
                                     'FII#',
                                     'CAGR',
                                     'COST',
                                     'RLOC',
                                     'SCL',
                                     'MTLL',
                                     'MCAT',
                                     'LOC#',
                                     'CMP',
                                     'JOB',
                                     'GLLE',
                                     'SERV',
                                     'MKTS',
                                     'GLAT'
                                    )
--and fsav.id_flex_code<>'GL#'
--and fsav.ATTRIBUTE_VALUE='Y'
                             AND fsav.application_column_name =
                                               my_rec1.application_column_name
                             AND fsav.segment_attribute_type =
                                                       'GL_SECONDARY_TRACKING')
                WHERE a.application_column_name =
                                               my_rec1.application_column_name
                  AND a.id_flex_num = my_rec.id_flex_num;

               UPDATE xx_xrtx_segments_t a
                  SET gl_intercompany =
                         (SELECT attribute_value
                            FROM fnd_segment_attribute_values fsav
                           WHERE fsav.id_flex_num = my_rec.id_flex_num
                             AND fsav.id_flex_code IN
                                    ('CAT#',
                                     'FII#',
                                     'CAGR',
                                     'COST',
                                     'RLOC',
                                     'SCL',
                                     'MTLL',
                                     'MCAT',
                                     'LOC#',
                                     'CMP',
                                     'JOB',
                                     'GLLE',
                                     'SERV',
                                     'MKTS',
                                     'GLAT'
                                    )
--and fsav.id_flex_code<>'GL#'
--and fsav.ATTRIBUTE_VALUE='Y'
                             AND fsav.application_column_name =
                                               my_rec1.application_column_name
                             AND fsav.segment_attribute_type =
                                                             'GL_INTERCOMPANY')
                WHERE a.application_column_name =
                                               my_rec1.application_column_name
                  AND a.id_flex_num = my_rec.id_flex_num;

               UPDATE xx_xrtx_segments_t a
                  SET gl_ledger =
                         (SELECT attribute_value
                            FROM fnd_segment_attribute_values fsav
                           WHERE fsav.id_flex_num = my_rec.id_flex_num
                             AND fsav.id_flex_code IN
                                    ('CAT#',
                                     'FII#',
                                     'CAGR',
                                     'COST',
                                     'RLOC',
                                     'SCL',
                                     'MTLL',
                                     'MCAT',
                                     'LOC#',
                                     'CMP',
                                     'JOB',
                                     'GLLE',
                                     'SERV',
                                     'MKTS',
                                     'GLAT'
                                    )
--and fsav.id_flex_code<>'GL#'
--and fsav.ATTRIBUTE_VALUE='Y'
                             AND fsav.application_column_name =
                                               my_rec1.application_column_name
                             AND fsav.segment_attribute_type = 'GL_LEDGER')
                WHERE a.application_column_name =
                                               my_rec1.application_column_name
                  AND a.id_flex_num = my_rec.id_flex_num;
            END;

            COMMIT;
         END LOOP;
      END LOOP;
   END xx_xrtx_qual_p;

   PROCEDURE xx_xrtx_om_sys_param_p
   IS
--   del_sql:='DELETE  FROM xx_xrtx_om_sys_pa';
--
--   execute immediate del_sql;
      CURSOR c1
      IS
         SELECT NAME
           FROM hr_all_organization_units
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all);
   BEGIN
      OPEN c1;

      LOOP
         FETCH c1
          INTO v_org_name;

         EXIT WHEN c1%NOTFOUND;

         SELECT COUNT (b.parameter_value)
           INTO v_recurring_charges_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'RECURRING_CHARGES';

         IF v_recurring_charges_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_recurring_charges
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'RECURRING_CHARGES';
         ELSE
            v_recurring_charges := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_oe_invoice_freight_as_li_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'OE_INVOICE_FREIGHT_AS_LINE';

         IF v_oe_invoice_freight_as_li_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_oe_invoice_freight_as_line
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'OE_INVOICE_FREIGHT_AS_LINE';
         ELSE
            v_oe_invoice_freight_as_line := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_installment_options_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'INSTALLMENT_OPTIONS';

         IF v_installment_options_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_installment_options
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'INSTALLMENT_OPTIONS';
         ELSE
            v_installment_options := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_oe_invoice_source_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'OE_INVOICE_SOURCE';

         IF v_oe_invoice_source_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_oe_invoice_source
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'OE_INVOICE_SOURCE';
         ELSE
            v_oe_invoice_source := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_oe_inv_item_for_fre_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'OE_INVENTORY_ITEM_FOR_FREIGHT';

         IF v_oe_inv_item_for_fre_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_oe_inv_item_for_fre
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'OE_INVENTORY_ITEM_FOR_FREIGHT';
         ELSE
            v_oe_inv_item_for_fre := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_oe_inv_tra_ty_id_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'OE_INVOICE_TRANSACTION_TYPE_ID';

         IF v_oe_inv_tra_ty_id_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_oe_inv_tran_type_id
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'OE_INVOICE_TRANSACTION_TYPE_ID';
         ELSE
            v_oe_inv_tran_type_id := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_oe_credit_tr_type_id_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'OE_CREDIT_TRANSACTION_TYPE_ID';

         IF v_oe_credit_tr_type_id_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_oe_credit_tr_type_id
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'OE_CREDIT_TRANSACTION_TYPE_ID';
         ELSE
            v_oe_credit_tr_type_id := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_oe_non_del_inv_sou_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'OE_NON_DELIVERY_INVOICE_SOURCE';

         IF v_oe_non_del_inv_sou_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_oe_non_del_inv_source
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'OE_NON_DELIVERY_INVOICE_SOURCE';
         ELSE
            v_oe_non_del_inv_source := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_oe_os_inv_basis_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'OE_OVERSHIP_INVOICE_BASIS';

         IF v_oe_os_inv_basis_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_oe_overship_invoice_basis
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'OE_OVERSHIP_INVOICE_BASIS';
         ELSE
            v_oe_overship_invoice_basis := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_oe_dis_det_on_inv_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'OE_DISCOUNT_DETAILS_ON_INVOICE';

         IF v_oe_dis_det_on_inv_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_oe_dis_det_on_inv
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'OE_DISCOUNT_DETAILS_ON_INVOICE';
         ELSE
            v_oe_dis_det_on_inv := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_ont_reservation_time_fen_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'ONT_RESERVATION_TIME_FENCE';

         IF v_ont_reservation_time_fen_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_ont_reservation_time_fence
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'ONT_RESERVATION_TIME_FENCE';
         ELSE
            v_ont_reservation_time_fence := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_ont_sched_line_on_hold_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'ONT_SCHEDULE_LINE_ON_HOLD';

         IF v_ont_sched_line_on_hold_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_ont_schedule_line_on_hold
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'ONT_SCHEDULE_LINE_ON_HOLD';
         ELSE
            v_ont_schedule_line_on_hold := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_wsh_cr_srep_for_freight_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'WSH_CR_SREP_FOR_FREIGHT';

         IF v_wsh_cr_srep_for_freight_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_wsh_cr_srep_for_freight
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'WSH_CR_SREP_FOR_FREIGHT';
         ELSE
            v_wsh_cr_srep_for_freight := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_ont_gsa_violation_action_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'ONT_GSA_VIOLATION_ACTION';

         IF v_ont_gsa_violation_action_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_ont_gsa_violation_action
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'ONT_GSA_VIOLATION_ACTION';
         ELSE
            v_ont_gsa_violation_action := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_ont_emp_id_for_ss_orders_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'ONT_EMP_ID_FOR_SS_ORDERS';

         IF v_ont_emp_id_for_ss_orders_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_ont_emp_id_for_ss_orders
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'ONT_EMP_ID_FOR_SS_ORDERS';
         ELSE
            v_ont_emp_id_for_ss_orders := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_enable_fulfillment_acc_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'ENABLE_FULFILLMENT_ACC';

         IF v_enable_fulfillment_acc_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_enable_fulfillment_acc
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'ENABLE_FULFILLMENT_ACC';
         ELSE
            v_enable_fulfillment_acc := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_master_org_id_cou
           FROM hr_all_organization_units a,
                oe_sys_parameters_all b,
                hr_all_organization_units c
          WHERE a.organization_id IN (SELECT DISTINCT org_id
                                                 FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND TO_NUMBER (b.parameter_value) = c.organization_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'MASTER_ORGANIZATION_ID';

         IF v_master_org_id_cou = 1
         THEN
            SELECT c.NAME
              INTO v_master_organization_id
              FROM hr_all_organization_units a,
                   oe_sys_parameters_all b,
                   hr_all_organization_units c
             WHERE a.organization_id IN (SELECT DISTINCT org_id
                                                    FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND TO_NUMBER (b.parameter_value) = c.organization_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'MASTER_ORGANIZATION_ID';
         ELSE
            v_master_organization_id := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_audit_trail_enable_flag_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'AUDIT_TRAIL_ENABLE_FLAG';

         IF v_audit_trail_enable_flag_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_audit_trail_enable_flag
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'AUDIT_TRAIL_ENABLE_FLAG';
         ELSE
            v_audit_trail_enable_flag := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_customer_relation_flag_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'CUSTOMER_RELATIONSHIPS_FLAG';

         IF v_customer_relation_flag_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_customer_relationships_flag
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'CUSTOMER_RELATIONSHIPS_FLAG';
         ELSE
            v_customer_relationships_flag := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_compute_margin_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'COMPUTE_MARGIN';

         IF v_compute_margin_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_compute_margin
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'COMPUTE_MARGIN';
         ELSE
            v_compute_margin := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_freight_rating_enabd_fl_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'FREIGHT_RATING_ENABLED_FLAG';

         IF v_freight_rating_enabd_fl_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_freight_rating_enabled_flag
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'FREIGHT_RATING_ENABLED_FLAG';
         ELSE
            v_freight_rating_enabled_flag := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_fte_ship_method_enabl_fg_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'FTE_SHIP_METHOD_ENABLED_FLAG';

         IF v_fte_ship_method_enabl_fg_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_fte_ship_method_enabled_flag
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'FTE_SHIP_METHOD_ENABLED_FLAG';
         ELSE
            v_fte_ship_method_enabled_flag := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_latest_acc_date_fl_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'LATEST_ACCEPTABLE_DATE_FLAG';

         IF v_latest_acc_date_fl_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_latest_acceptable_date_flag
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'LATEST_ACCEPTABLE_DATE_FLAG';
         ELSE
            v_latest_acceptable_date_flag := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_reschedule_reque_date_fl_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'RESCHEDULE_REQUEST_DATE_FLAG';

         IF v_reschedule_reque_date_fl_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_reschedule_request_date_flag
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'RESCHEDULE_REQUEST_DATE_FLAG';
         ELSE
            v_reschedule_request_date_flag := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_ont_prc_ava_default_hint_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'ONT_PRC_AVA_DEFAULT_HINT';

         IF v_ont_prc_ava_default_hint_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_ont_prc_ava_default_hint
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'ONT_PRC_AVA_DEFAULT_HINT';
         ELSE
            v_ont_prc_ava_default_hint := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_res_ship_method_fl_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'RESCHEDULE_SHIP_METHOD_FLAG';

         IF v_res_ship_method_fl_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_reschedule_ship_method_flag
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'RESCHEDULE_SHIP_METHOD_FLAG';
         ELSE
            v_reschedule_ship_method_flag := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_promise_date_flag_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'PROMISE_DATE_FLAG';

         IF v_promise_date_flag_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_promise_date_flag
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'PROMISE_DATE_FLAG';
         ELSE
            v_promise_date_flag := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_partial_res_flag_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'PARTIAL_RESERVATION_FLAG';

         IF v_partial_res_flag_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_partial_reservation_flag
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'PARTIAL_RESERVATION_FLAG';
         ELSE
            v_partial_reservation_flag := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_firm_demand_events_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'FIRM_DEMAND_EVENTS';

         IF v_firm_demand_events_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_firm_demand_events
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'FIRM_DEMAND_EVENTS';
         ELSE
            v_firm_demand_events := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_multiple_payments_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'MULTIPLE_PAYMENTS';

         IF v_multiple_payments_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_multiple_payments
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'MULTIPLE_PAYMENTS';
         ELSE
            v_multiple_payments := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_acc_first_insta_only_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'ACCOUNT_FIRST_INSTALLMENT_ONLY';

         IF v_acc_first_insta_only_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_acc_first_install_only
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'ACCOUNT_FIRST_INSTALLMENT_ONLY';
         ELSE
            v_acc_first_install_only := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_ont_config_effec_date_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'ONT_CONFIG_EFFECTIVITY_DATE';

         IF v_ont_config_effec_date_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_ont_config_effectivity_date
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'ONT_CONFIG_EFFECTIVITY_DATE';
         ELSE
            v_ont_config_effectivity_date := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_retrobill_reasons_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'RETROBILL_REASONS';

         IF v_retrobill_reasons_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_retrobill_reasons
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'RETROBILL_REASONS';
         ELSE
            v_retrobill_reasons := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_retrobill_deft_or_type_cou
           FROM hr_all_organization_units a,
                oe_sys_parameters_all b,
                oe_transaction_types_all c
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND TO_NUMBER (b.parameter_value) = c.transaction_type_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'RETROBILL_DEFAULT_ORDER_TYPE';

         IF v_retrobill_deft_or_type_cou = 1
         THEN
            SELECT c.transaction_type_code
              INTO v_retrobill_default_order_type
              FROM hr_all_organization_units a,
                   oe_sys_parameters_all b,
                   oe_transaction_types_all c
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND TO_NUMBER (b.parameter_value) = c.transaction_type_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'RETROBILL_DEFAULT_ORDER_TYPE';
         ELSE
            v_retrobill_default_order_type := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_enable_retrobilling_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'ENABLE_RETROBILLING';

         IF v_enable_retrobilling_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_enable_retrobilling
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'ENABLE_RETROBILLING';
         ELSE
            v_enable_retrobilling := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_no_response_from_appr_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'NO_RESPONSE_FROM_APPROVER';

         IF v_no_response_from_appr_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_no_response_from_approver
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'NO_RESPONSE_FROM_APPROVER';
         ELSE
            v_no_response_from_approver := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_copy_line_dff_ext_api_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'COPY_LINE_DFF_EXT_API';

         IF v_copy_line_dff_ext_api_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_copy_line_dff_ext_api
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'COPY_LINE_DFF_EXT_API';
         ELSE
            v_copy_line_dff_ext_api := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_copy_complete_config_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'COPY_COMPLETE_CONFIG';

         IF v_copy_complete_config_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_copy_complete_config
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'COPY_COMPLETE_CONFIG';
         ELSE
            v_copy_complete_config := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_trx_date_for_inv_iface_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'TRX_DATE_FOR_INV_IFACE';

         IF v_trx_date_for_inv_iface_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_trx_date_for_inv_iface
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'TRX_DATE_FOR_INV_IFACE';
         ELSE
            v_trx_date_for_inv_iface := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_cr_hold_zero_value_or_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'CREDIT_HOLD_ZERO_VALUE_ORDER';

         IF v_cr_hold_zero_value_or_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_credit_hold_zero_value_order
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'CREDIT_HOLD_ZERO_VALUE_ORDER';
         ELSE
            v_credit_hold_zero_value_order := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_ont_cascade_hold_non_pto_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'ONT_CASCADE_HOLD_NONSMC_PTO';

         IF v_ont_cascade_hold_non_pto_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_ont_cascade_hold_nonsmc_pto
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'ONT_CASCADE_HOLD_NONSMC_PTO';
         ELSE
            v_ont_cascade_hold_nonsmc_pto := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_oe_addr_valid_oimp_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'OE_ADDR_VALID_OIMP';

         IF v_oe_addr_valid_oimp_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_oe_addr_valid_oimp
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'OE_ADDR_VALID_OIMP';
         ELSE
            v_oe_addr_valid_oimp := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_oe_hold_line_sequence_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'OE_HOLD_LINE_SEQUENCE';

         IF v_oe_hold_line_sequence_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_oe_hold_line_sequence
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'OE_HOLD_LINE_SEQUENCE';
         ELSE
            v_oe_hold_line_sequence := NULL;
         END IF;

----------------------------
         SELECT COUNT (b.parameter_value)
           INTO v_cust_relation_flag_svc_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'CUSTOMER_RELATIONSHIPS_FLAG_SVC';

         IF v_cust_relation_flag_svc_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_cust_relationships_flag_svc
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'CUSTOMER_RELATIONSHIPS_FLAG_SVC';
         ELSE
            v_cust_relationships_flag_svc := NULL;
         END IF;

----------------------------
         SELECT COUNT (b.parameter_value)
           INTO v_oe_cc_cancel_param_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'OE_CC_CANCEL_PARAM';

         IF v_oe_cc_cancel_param_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_oe_cc_cancel_param
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'OE_CC_CANCEL_PARAM';
         ELSE
            v_oe_cc_cancel_param := NULL;
         END IF;

         SELECT COUNT (b.parameter_value)
           INTO v_ont_auto_sch_sets_cou
           FROM hr_all_organization_units a, oe_sys_parameters_all b
          WHERE organization_id IN (SELECT DISTINCT org_id
                                               FROM oe_order_headers_all)
            AND a.organization_id = b.org_id
            AND a.NAME = v_org_name
            AND b.parameter_code = 'ONT_AUTO_SCH_SETS';

         IF v_ont_auto_sch_sets_cou = 1
         THEN
            SELECT b.parameter_value
              INTO v_ont_auto_sch_sets
              FROM hr_all_organization_units a, oe_sys_parameters_all b
             WHERE organization_id IN (SELECT DISTINCT org_id
                                                  FROM oe_order_headers_all)
               AND a.organization_id = b.org_id
               AND a.NAME = v_org_name
               AND b.parameter_code = 'ONT_AUTO_SCH_SETS';
         ELSE
            v_ont_auto_sch_sets := NULL;
         END IF;

         INSERT INTO xx_xrtx_om_sys_pa
              VALUES (v_org_name, v_recurring_charges, v_oe_inv_item_for_fre,
                      v_oe_invoice_freight_as_line, v_oe_inv_tran_type_id,
                      v_oe_credit_tr_type_id, v_oe_non_del_inv_source,
                      v_installment_options, v_oe_invoice_source,
                      v_oe_overship_invoice_basis, v_oe_dis_det_on_inv,
                      v_ont_reservation_time_fence,
                      v_ont_schedule_line_on_hold, v_wsh_cr_srep_for_freight,
                      v_ont_gsa_violation_action, v_ont_emp_id_for_ss_orders,
                      v_enable_fulfillment_acc, v_master_organization_id,
                      v_audit_trail_enable_flag,
                      v_customer_relationships_flag, v_compute_margin,
                      v_freight_rating_enabled_flag,
                      v_fte_ship_method_enabled_flag,
                      v_latest_acceptable_date_flag,
                      v_reschedule_request_date_flag,
                      v_ont_prc_ava_default_hint,
                      v_reschedule_ship_method_flag, v_promise_date_flag,
                      v_partial_reservation_flag, v_firm_demand_events,
                      v_multiple_payments, v_acc_first_install_only,
                      v_ont_config_effectivity_date, v_retrobill_reasons,
                      v_retrobill_default_order_type, v_enable_retrobilling,
                      v_no_response_from_approver, v_copy_line_dff_ext_api,
                      v_copy_complete_config, v_trx_date_for_inv_iface,
                      v_credit_hold_zero_value_order,
                      v_ont_cascade_hold_nonsmc_pto, v_oe_addr_valid_oimp,
                      v_oe_hold_line_sequence, v_oe_cc_cancel_param,
                      v_ont_auto_sch_sets, v_cust_relationships_flag_svc);

         COMMIT;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('NO DATA FOUND');

         CLOSE c1;
   END xx_xrtx_om_sys_param_p;

   PROCEDURE xx_xrtx_api_list_det_p
   AS
      CURSOR c1
      IS
         SELECT api_name
--INTO V_ORG_ID,V_ORG_NAME,V_ROWNUM
         FROM   xx_xrtx_api_list;

      CURSOR c2
      IS
         SELECT DISTINCT NAME, TYPE
--INTO V_EXECUTION_FILE_NAME,V_TYPE
         FROM            all_source
                   WHERE text LIKE '%' || v_api_name || '%'
                     AND NAME LIKE 'XX%';
   BEGIN
      OPEN c1;

      LOOP
         FETCH c1
          INTO v_api_name;

         EXIT WHEN c1%NOTFOUND;
         DBMS_OUTPUT.put_line ('v_api_name' || v_api_name);

         OPEN c2;

         DBMS_OUTPUT.put_line ('inside c2');

         LOOP
            FETCH c2
             INTO v_execution_file_name, v_type;

            EXIT WHEN c2%NOTFOUND;
            DBMS_OUTPUT.put_line (   'EXECUTION_FILE_NAME'
                                  || v_execution_file_name
                                  || ' '
                                  || v_type
                                 );

            SELECT COUNT (fct.user_concurrent_program_name)
              INTO v_concurrent_count
              FROM fnd_concurrent_programs_tl fct,
                   fnd_concurrent_programs fcp,
                   fnd_executables fe,
                   fnd_lookups fl
             WHERE
     --upper(fct.user_concurrent_program_name) = upper('concurrent program')
--AND
                   fct.concurrent_program_id = fcp.concurrent_program_id
               AND fe.executable_id = fcp.executable_id
               AND fl.lookup_code = fe.execution_method_code
               AND fl.lookup_type = 'CP_EXECUTION_METHOD_CODE'
               AND fe.execution_file_name LIKE
                                           '%' || v_execution_file_name || '%';

            DBMS_OUTPUT.put_line ('v_concurrent_count' || v_concurrent_count);

            IF v_concurrent_count > 0
            THEN
               DBMS_OUTPUT.put_line ('inside if');

               SELECT fct.user_concurrent_program_name
                 INTO v_concurrent_programe_name
                 FROM fnd_concurrent_programs_tl fct,
                      fnd_concurrent_programs fcp,
                      fnd_executables fe,
                      fnd_lookups fl
                WHERE
     --upper(fct.user_concurrent_program_name) = upper('concurrent program')
--AND
                      fct.concurrent_program_id = fcp.concurrent_program_id
                  AND fe.executable_id = fcp.executable_id
                  AND fl.lookup_code = fe.execution_method_code
                  AND fl.lookup_type = 'CP_EXECUTION_METHOD_CODE'
                  AND fe.execution_file_name LIKE
                                           '%' || v_execution_file_name || '%'
                  AND ROWNUM = 1;

               DBMS_OUTPUT.put_line (   'v_concurrent_programe_name'
                                     || v_concurrent_programe_name
                                    );
            ELSE
               v_concurrent_programe_name := NULL;
            END IF;

            INSERT INTO xx_xrts_api_list_details
                        (name_of_custom_object_ref_api, TYPE,
                         concurrent_program_name, api_name
                        )
                 VALUES (v_execution_file_name, v_type,
                         v_concurrent_programe_name, v_api_name
                        );

            COMMIT;
         END LOOP;

         CLOSE c2;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('NO DATA FOUND');

         CLOSE c1;
   END xx_xrtx_api_list_det_p;
END xx_xrtx_all_main_insert_pck;
/
