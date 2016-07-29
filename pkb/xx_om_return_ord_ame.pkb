DROP PACKAGE BODY APPS.XX_OM_RETURN_ORD_AME;

CREATE OR REPLACE PACKAGE BODY APPS.xx_om_return_ord_ame
AS
----------------------------------------------------------------------
/*
 Created By    : Yogesh
 Creation Date : 04-JUL-2012
 File Name     : xxomretordame.pkb
 Description   : This script creates the cody of the package
                 body xx_om_return_ord_ame
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 04-JUL-2012 Yogesh                Initial Development
 27-FEB-2015 Dhiren                Modified as per WAVE2 Requirment
 25-MAR-2015 Jaya/Sanjeev	   Merged with changes made for ticket#7839
                                   into the pacakge for CC#013847
*/
----------------------------------------------------------------------
   PROCEDURE cust_get_approver (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   )
   AS
      --g_chr_transaction_type      VARCHAR2 (200);
      x_chr_item_key         VARCHAR2 (200);
      x_chr_apprvl_out_put   VARCHAR2 (100);
      x_next_approver        ame_util.approverstable2;
      x_chr_approver_id      VARCHAR2 (10);
      x_chr_appr_name        VARCHAR2 (50);
      x_item_index           ame_util.idlist;
      x_item_class           ame_util.stringlist;
      x_item_id              ame_util.stringlist;
      x_item_source          ame_util.longstringlist;
      x_ame_show_msg_flag    VARCHAR2 (5);
      x_common_msg_body      VARCHAR2 (3000);
      x_common_msg_sub       VARCHAR2 (1000);
      x_order_number         NUMBER;
      x_rma_value            NUMBER;
      x_cust_name            VARCHAR2 (1000);
      x_rma_notes            VARCHAR2 (4000);
      x_common_rma_notes     VARCHAR2 (4000);
      x_line                 VARCHAR2 (1000);
      lv_details             VARCHAR2 (32767);

      CURSOR c_rma_notes (p_order_number VARCHAR2)
      IS
         SELECT a.attached_document_id, a.document_id, a.seq_num,
                a.category_id, b.datatype_name, b.category_description,
                b.media_id, b.title
           FROM fnd_attached_documents a,
                fnd_documents_vl b,
                oe_order_headers_all c
          WHERE a.pk1_value = TO_CHAR (c.header_id)
            AND b.document_id = a.document_id
            AND b.datatype_name = 'Short Text'
            AND b.category_description = 'RMA Notes'
            AND c.order_number = p_order_number;

      CURSOR c_notes (p_media_id NUMBER)
      IS
         SELECT c.short_text
           FROM fnd_documents_short_text c
          WHERE c.media_id = p_media_id;
   BEGIN
      g_num_err_loc_code := '00001';
      x_ame_show_msg_flag :=
         wf_engine.getitemattrtext (itemtype      => p_itemtype,
                                    itemkey       => p_itemkey,
                                    aname         => 'XXOM_AME_SHOW_MSG_FLAG'
                                   );
      x_order_number :=
         wf_engine.getitemattrnumber (itemtype      => p_itemtype,
                                      itemkey       => p_itemkey,
                                      aname         => 'XXOM_AME_ODR_NUM'
                                     );
      x_rma_value :=
         wf_engine.getitemattrnumber (itemtype      => p_itemtype,
                                      itemkey       => p_itemkey,
                                      aname         => 'XXOM_AME_RMA_VAL'
                                     );

      BEGIN
         SELECT hp.party_name
           INTO x_cust_name
           FROM oe_order_headers_all oeh, hz_cust_accounts hca, hz_parties hp
          WHERE 1 = 1
            AND hca.cust_account_id = oeh.sold_to_org_id
            AND hca.party_id = hp.party_id
            AND oeh.order_number = x_order_number;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_cust_name := NULL;
      END;

      IF funmode = 'RUN'
      THEN
         BEGIN
            xx_intg_common_pkg.get_process_param_value
                                                  ('XXOMAMERMA',
                                                   'G_TRANSACTION_TYPE_NAME',
                                                   g_chr_transaction_type
                                                  );
            --
            -- Getting next approver using AME_API2.GETNEXTAPPROVERS1 procedure
            --
            ame_api2.getnextapprovers1
               (applicationidin                   => 660
                                                     --Order Management APP ID
                                                        ,
                transactiontypein                 => g_chr_transaction_type
                                                     --short name of AME Trans
                                                                           ,
                transactionidin                   => p_itemkey
                       --l_chr_item_key  --unique ID that can be passed to AME
                                                              ,
                flagapproversasnotifiedin         => ame_util.booleantrue,
                approvalprocesscompleteynout      => x_chr_apprvl_out_put,
                nextapproversout                  => x_next_approver,
                itemindexesout                    => x_item_index,
                itemidsout                        => x_item_id,
                itemclassesout                    => x_item_class,
                itemsourcesout                    => x_item_source
               );

            IF x_chr_apprvl_out_put = 'N'
            THEN
               IF x_next_approver.COUNT > 0
               THEN
                  x_chr_approver_id := x_next_approver (1).orig_system_id;
                  x_chr_appr_name := x_next_approver (1).NAME;
                  wf_engine.setitemattrtext (itemtype      => p_itemtype,
                                             itemkey       => p_itemkey,
                                             aname         => 'XXOM_AME_APPROVER',
                                             avalue        => x_chr_appr_name
                                            );
                  wf_engine.setitemattrtext (itemtype      => p_itemtype,
                                             itemkey       => p_itemkey,
                                             aname         => 'XXOM_AME_ESC_MGR',
                                             avalue        => x_chr_appr_name
                                            );

                  IF x_next_approver (1).approver_category = 'F'
                  THEN
                     BEGIN
                        x_common_msg_sub :=
                           xx_intg_common_pkg.set_token_message
                                   (p_message_name      => 'XXOM_AME_FYI_MSG_SUB',
                                    p_token_value1      => x_order_number,
                                    p_token_value2      => x_rma_value,
                                    p_no_of_tokens      => 2
                                   );
                        x_common_msg_body :=
                           xx_intg_common_pkg.set_token_message
                                   (p_message_name      => 'XXOM_AME_FYI_MSG_BODY',
                                    p_token_value1      => x_chr_appr_name,
                                    p_token_value2      => x_order_number,
                                    p_token_value3      => x_rma_value,
                                    p_no_of_tokens      => 3
                                   );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           RESULT := 'NO_APPROVER';
                           wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                                            proc_name      => 'cust_get_approver',
                                            arg1           => SUBSTR (SQLERRM,
                                                                      1,
                                                                      80
                                                                     ),
                                            arg2           => p_itemtype,
                                            arg3           => p_itemkey,
                                            arg4           => TO_CHAR
                                                                 (p_activityid),
                                            arg5           => funmode,
                                            arg6           =>    'error location:'
                                                              || g_num_err_loc_code
                                           );
                           RAISE;
                     END;

                     wf_engine.setitemattrtext
                                          (itemtype      => p_itemtype,
                                           itemkey       => p_itemkey,
                                           aname         => 'XXOM_AME_COMMON_MSG_SUB',
                                           avalue        => x_common_msg_sub
                                          );
                     wf_engine.setitemattrtext
                                         (itemtype      => p_itemtype,
                                          itemkey       => p_itemkey,
                                          aname         => 'XXOM_AME_COMMON_MSG_BODY',
                                          avalue        => x_common_msg_body
                                         );
                     RESULT := 'FYI';
                     RETURN;
                  ELSIF x_next_approver (1).approver_category = 'A'
                  THEN
                     IF x_ame_show_msg_flag = 'Y'
                     THEN
                        fnd_message.set_name ('XXINTG',
                                              'XXOM_AME_ORDER_BOOK_MSG'
                                             );
                        oe_msg_pub.ADD;
                        wf_engine.setitemattrtext
                                           (itemtype      => p_itemtype,
                                            itemkey       => p_itemkey,
                                            aname         => 'XXOM_AME_SHOW_MSG_FLAG',
                                            avalue        => 'N'
                                           );

                        BEGIN
                           x_common_msg_sub :=
                              xx_intg_common_pkg.set_token_message
                                   (p_message_name      => 'XXOM_AME_APR_MSG_SUB',
                                    p_token_value1      => x_order_number,
                                    p_token_value2      => x_rma_value,
                                    p_no_of_tokens      => 2
                                   );
                           x_common_msg_body :=
                              xx_intg_common_pkg.set_token_message
                                   (p_message_name      => 'XXOM_AME_APR_MSG_BODY',
                                    p_token_value1      => x_chr_appr_name,
                                    p_token_value2      => x_order_number,
                                    p_token_value3      => x_rma_value,
                                    p_token_value4      => x_cust_name,
                                    p_no_of_tokens      => 4
                                   );
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              RESULT := 'NO_APPROVER';
                              wf_core.CONTEXT
                                           (pkg_name       => g_chr_pkg_name,
                                            proc_name      => 'cust_get_approver',
                                            arg1           => SUBSTR (SQLERRM,
                                                                      1,
                                                                      80
                                                                     ),
                                            arg2           => p_itemtype,
                                            arg3           => p_itemkey,
                                            arg4           => TO_CHAR
                                                                 (p_activityid),
                                            arg5           => funmode,
                                            arg6           =>    'error location:'
                                                              || g_num_err_loc_code
                                           );
                              RAISE;
                        END;

                        wf_engine.setitemattrtext
                                          (itemtype      => p_itemtype,
                                           itemkey       => p_itemkey,
                                           aname         => 'XXOM_AME_COMMON_MSG_SUB',
                                           avalue        => x_common_msg_sub
                                          );
                        wf_engine.setitemattrtext
                                         (itemtype      => p_itemtype,
                                          itemkey       => p_itemkey,
                                          aname         => 'XXOM_AME_COMMON_MSG_BODY',
                                          avalue        => x_common_msg_body
                                         );
                     END IF;

                     RESULT := 'APPROVAL';
                     x_common_msg_body :=
                        xx_intg_common_pkg.set_token_message
                                   (p_message_name      => 'XXOM_AME_APR_MSG_BODY',
                                    p_token_value1      => x_chr_appr_name,
                                    p_token_value2      => x_order_number,
                                    p_token_value3      => x_rma_value,
                                    p_token_value4      => x_cust_name,
                                    p_no_of_tokens      => 4
                                   );
                     xx_om_appr_message_body (x_common_msg_body,
                                              p_itemkey,
                                              'INS'
                                             );
                     RETURN;
                  END IF;
               ELSE
                  RESULT := 'NO_APPROVER';
                  RETURN;
               END IF;
            ELSE
               RESULT := 'NO_APPROVER';
               RETURN;
            END IF;
         --
         -- Exception handling
         --
         EXCEPTION
            WHEN OTHERS
            THEN
               RESULT := 'NO_APPROVER';
               wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                                proc_name      => 'cust_get_approver',
                                arg1           => SUBSTR (SQLERRM, 1, 80),
                                arg2           => p_itemtype,
                                arg3           => p_itemkey,
                                arg4           => TO_CHAR (p_activityid),
                                arg5           => funmode,
                                arg6           =>    'error location:'
                                                  || g_num_err_loc_code
                               );
               RAISE;
         END;
      END IF;

      IF (funmode = 'CANCEL')
      THEN
         RESULT := 'NO_APPROVER';
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RESULT := 'NO_APPROVER';
         wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                          proc_name      => 'CUST_GET_APPROVER',
                          arg1           =>    'Procedure Exception:'
                                            || SUBSTR (SQLERRM, 1, 80),
                          arg2           => p_itemtype,
                          arg3           => p_itemkey,
                          arg4           => TO_CHAR (p_activityid),
                          arg5           => funmode,
                          arg6           =>    'error location:'
                                            || g_num_err_loc_code
                         );
         RAISE;
   END cust_get_approver;

--------------------------------------------------------------------------------------------------
   PROCEDURE upd_appr_status (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   )
   AS
      x_chr_approver_name   VARCHAR (100);
      x_order_number        NUMBER;
      x_rma_value           NUMBER;
      x_common_msg_body     VARCHAR2 (3000);
      x_common_msg_sub      VARCHAR2 (1000);
   BEGIN
      --- Delete any msg body records if present for the Sales Order
      BEGIN
         xx_om_appr_message_body (NULL, p_itemkey, 'DEL');
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      IF funmode = 'RUN'
      THEN
         g_num_err_loc_code := '00002';
         x_order_number :=
            wf_engine.getitemattrnumber (itemtype      => p_itemtype,
                                         itemkey       => p_itemkey,
                                         aname         => 'XXOM_AME_ODR_NUM'
                                        );
         x_rma_value :=
            wf_engine.getitemattrnumber (itemtype      => p_itemtype,
                                         itemkey       => p_itemkey,
                                         aname         => 'XXOM_AME_RMA_VAL'
                                        );
         x_chr_approver_name :=
            wf_engine.getitemattrtext (itemtype      => p_itemtype,
                                       itemkey       => p_itemkey,
                                       aname         => 'XXOM_AME_APPROVER'
                                      );
         xx_intg_common_pkg.get_process_param_value
                                                   ('XXOMAMERMA',
                                                    'G_TRANSACTION_TYPE_NAME',
                                                    g_chr_transaction_type
                                                   );
         ame_api2.updateapprovalstatus2
                        (applicationidin        => 660,
                         transactiontypein      => g_chr_transaction_type
                                                                     --'RMAA',
                                                                         ,
                         transactionidin        => p_itemkey,
                         approvalstatusin       => ame_util.approvedstatus,
                         approvernamein         => x_chr_approver_name
                        );
         /*
         BEGIN
            x_common_msg_sub:=xx_intg_common_pkg.set_token_message( p_message_name  => 'XXOM_AME_POST_APR_MSG_SUB'
                                                                   ,p_token_value1  => x_order_number
                                                                   ,p_token_value2  => x_rma_value
                                                                   ,p_no_of_tokens  => 2
                                                                  );

            x_common_msg_body:=xx_intg_common_pkg.set_token_message( p_message_name  =>'XXOM_AME_POST_APR_MSG_BODY'
                                                               ,p_token_value1  =>x_order_number
                                                               ,p_token_value2  =>x_rma_value
                                                               ,p_no_of_tokens  => 2
                                                                   );
         EXCEPTION
                WHEN OTHERS THEN
                result := 'N';
          WF_CORE.CONTEXT (pkg_name       => g_chr_pkg_name,
                     proc_name      => 'upd_appr_status',
                     arg1           => SUBSTR (SQLERRM, 1, 80),
                     arg2           => p_itemType,
                     arg3           => p_itemKey,
                     arg4           => TO_CHAR (p_activityId),
                     arg5           => funmode,
                     arg6           => 'error location:'||g_num_err_loc_code);
                RAISE;
         END;
         wf_engine.setItemAttrText ( itemtype => p_itemType
                           ,itemkey  => p_itemKey
                           ,aname    => 'XXOM_AME_COMMON_MSG_SUB'
                           ,avalue   => x_common_msg_sub
                                   );
         wf_engine.setItemAttrText ( itemtype => p_itemType
                           ,itemkey  => p_itemKey
                           ,aname    => 'XXOM_AME_COMMON_MSG_BODY'
                           ,avalue   => x_common_msg_body
                                   );
         */
         wf_engine.setitemattrtext (itemtype      => p_itemtype,
                                    itemkey       => p_itemkey,
                                    aname         => 'XXOM_APPRV_FLOW',
                                    avalue        => 'Y'
                                   );
         RESULT := 'Y';
      END IF;

      IF (funmode = 'CANCEL')
      THEN
         RESULT := 'N';
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RESULT := 'N';
         wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                          proc_name      => 'UPD_APPR_STATUS',
                          arg1           => SUBSTR (SQLERRM, 1, 80),
                          arg2           => p_itemtype,
                          arg3           => p_itemkey,
                          arg4           => TO_CHAR (p_activityid),
                          arg5           => funmode,
                          arg6           =>    'error location:'
                                            || g_num_err_loc_code
                         );
         RAISE;
   END upd_appr_status;

--------------------------------------------------------------------------------------------------
   PROCEDURE upd_rejected_status (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   )
   AS
      x_chr_approver_name   VARCHAR (100);
      x_order_number        NUMBER;
      x_rma_value           NUMBER;
      x_common_msg_body     VARCHAR2 (3000);
      x_common_msg_sub      VARCHAR2 (1000);
   BEGIN
      --- Delete any msg body records if present for the Sales Order
      BEGIN
         xx_om_appr_message_body (NULL, p_itemkey, 'DEL');
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      IF funmode = 'RUN'
      THEN
         x_order_number :=
            wf_engine.getitemattrnumber (itemtype      => p_itemtype,
                                         itemkey       => p_itemkey,
                                         aname         => 'XXOM_AME_ODR_NUM'
                                        );
         x_rma_value :=
            wf_engine.getitemattrnumber (itemtype      => p_itemtype,
                                         itemkey       => p_itemkey,
                                         aname         => 'XXOM_AME_RMA_VAL'
                                        );
         g_num_err_loc_code := '00003';
         x_chr_approver_name :=
            wf_engine.getitemattrtext (itemtype      => p_itemtype,
                                       itemkey       => p_itemkey,
                                       aname         => 'XXOM_AME_APPROVER'
                                      );
         xx_intg_common_pkg.get_process_param_value
                                                   ('XXOMAMERMA',
                                                    'G_TRANSACTION_TYPE_NAME',
                                                    g_chr_transaction_type
                                                   );
         ame_api2.updateapprovalstatus2
                                 (applicationidin        => 660,
                                  transactiontypein      => g_chr_transaction_type,
                                  transactionidin        => p_itemkey,
                                  approvalstatusin       => ame_util.rejectstatus,
                                  approvernamein         => x_chr_approver_name
                                 );

         BEGIN
            x_common_msg_sub :=
               xx_intg_common_pkg.set_token_message
                              (p_message_name      => 'XXOM_AME_POST_REJ_MSG_SUB',
                               p_token_value1      => x_order_number,
                               p_token_value2      => x_rma_value,
                               p_no_of_tokens      => 2
                              );
            x_common_msg_body :=
               xx_intg_common_pkg.set_token_message
                              (p_message_name      => 'XXOM_AME_POST_REJ_MSG_BODY',
                               p_token_value1      => x_order_number,
                               p_token_value2      => x_rma_value,
                               p_no_of_tokens      => 2
                              );
         EXCEPTION
            WHEN OTHERS
            THEN
               RESULT := 'N';
               wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                                proc_name      => 'upd_rejected_status',
                                arg1           => SUBSTR (SQLERRM, 1, 80),
                                arg2           => p_itemtype,
                                arg3           => p_itemkey,
                                arg4           => TO_CHAR (p_activityid),
                                arg5           => funmode,
                                arg6           =>    'error location:'
                                                  || g_num_err_loc_code
                               );
               RAISE;
         END;

         wf_engine.setitemattrtext (itemtype      => p_itemtype,
                                    itemkey       => p_itemkey,
                                    aname         => 'XXOM_AME_COMMON_MSG_SUB',
                                    avalue        => x_common_msg_sub
                                   );
         wf_engine.setitemattrtext (itemtype      => p_itemtype,
                                    itemkey       => p_itemkey,
                                    aname         => 'XXOM_AME_COMMON_MSG_BODY',
                                    avalue        => x_common_msg_body
                                   );
         RESULT := 'Y';
      END IF;

      IF funmode = 'CANCEL'
      THEN
         RESULT := 'N';
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RESULT := 'N';
         wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                          proc_name      => 'UPD_REJECTED_STATUS',
                          arg1           => SUBSTR (SQLERRM, 1, 80),
                          arg2           => p_itemtype,
                          arg3           => p_itemkey,
                          arg4           => TO_CHAR (p_activityid),
                          arg5           => funmode,
                          arg6           =>    'error location:'
                                            || g_num_err_loc_code
                         );
         RAISE;
   END upd_rejected_status;

--------------------------------------------------------------------------------------------------
   PROCEDURE init_variables (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   )
   AS
      x_rma_value            NUMBER;
      x_order_number         NUMBER;
      x_odr_created_user     VARCHAR2 (100);
      x_escalation_days      NUMBER;
      x_effective_days       NUMBER;
      x_counter              NUMBER         := 1;
      x_day_date             VARCHAR2 (20);
      x_emp_id_ord_creater   NUMBER;
      x_mgr_id               NUMBER;
      x_mgr_usr_name         VARCHAR2 (50);
   BEGIN
      /*FND_MESSAGE.set_name('XXINTG', 'XXOM_AME_ORDER_BOOK_MSG');
      oe_msg_pub.ADD; */
      SELECT SUM (ordered_quantity * unit_selling_price)
        INTO x_rma_value
        FROM oe_order_lines_all
       WHERE header_id = p_itemkey;

      SELECT oeoh.order_number, fu.user_name, fu.employee_id
        INTO x_order_number, x_odr_created_user, x_emp_id_ord_creater
        FROM oe_order_headers_all oeoh, fnd_user fu
       WHERE oeoh.header_id = p_itemkey AND fu.user_id = oeoh.created_by;

      BEGIN
         SELECT DISTINCT pafe.supervisor_id
                    INTO x_mgr_id
                    FROM per_all_assignments_f pafe,
                         per_all_people_f ppfs,
                         per_all_assignments_f pafs,
                         per_person_types_v ppts,
                         per_person_type_usages_f pptu
                   WHERE pafe.person_id = x_emp_id_ord_creater
                     AND TRUNC (SYSDATE) BETWEEN pafe.effective_start_date
                                             AND pafe.effective_end_date
                     AND pafe.primary_flag = 'Y'
                     AND pafe.assignment_type IN ('E', 'C')
                     AND ppfs.person_id = pafe.supervisor_id
                     AND TRUNC (SYSDATE) BETWEEN ppfs.effective_start_date
                                             AND ppfs.effective_end_date
                     AND pafs.person_id = ppfs.person_id
                     AND TRUNC (SYSDATE) BETWEEN pafs.effective_start_date
                                             AND pafs.effective_end_date
                     AND pafs.primary_flag = 'Y'
                     AND pafs.assignment_type IN ('E', 'C')
                     AND pptu.person_id = ppfs.person_id
                     AND ppts.person_type_id = pptu.person_type_id
                     AND ppts.system_person_type IN ('EMP', 'EMP_APL', 'CWK');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            x_mgr_usr_name := x_odr_created_user;
         WHEN OTHERS
         THEN
            x_mgr_usr_name := x_odr_created_user;
      END;

      BEGIN
         SELECT NAME
           INTO x_mgr_usr_name
           FROM wf_users
          WHERE orig_system_id = x_mgr_id AND orig_system = 'PER';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            x_mgr_usr_name := x_odr_created_user;
         WHEN OTHERS
         THEN
            x_mgr_usr_name := x_odr_created_user;
      END;

      xx_intg_common_pkg.get_process_param_value ('XXOMAMERMA',
                                                  'NOTIF_TIMEOUT_DAYS',
                                                  x_escalation_days
                                                 );
      /* x_effective_days:=x_escalation_days;
        LOOP
          BEGIN
            x_counter:= x_counter+1;
      SELECT TRIM (TO_CHAR (trunc(SYSDATE+x_counter), 'DAY'))
         INTO x_day_date
         FROM DUAL;
          END;
            IF x_day_date IN ('SATURDAY', 'SUNDAY')
            THEN
             IF x_day_date = 'SATURDAY' AND x_counter = x_escalation_days
             THEN
                x_effective_days:=x_effective_days+3;
             ELSIF x_day_date = 'SUNDAY' AND x_counter = x_escalation_days
             THEN
                x_effective_days:=x_effective_days+2;
             ELSE
                x_effective_days:=x_effective_days+1;
             END IF;
          END IF;
        EXIT WHEN x_counter = x_escalation_days;
       END LOOP; */
      x_effective_days :=
                    xx_om_return_ord_ame.calc_timeout_days (x_escalation_days);
      wf_engine.setitemattrnumber (itemtype      => p_itemtype,
                                   itemkey       => p_itemkey,
                                   aname         => 'XXOM_AME_TIMEOUT_DAYS',
                                   avalue        => x_effective_days
                                  );
      wf_engine.setitemattrtext (itemtype      => p_itemtype,
                                 itemkey       => p_itemkey,
                                 aname         => 'XXOM_AME_ORD_CREATER_MGR',
                                 avalue        => x_mgr_usr_name
                                );
      wf_engine.setitemattrnumber (itemtype      => p_itemtype,
                                   itemkey       => p_itemkey,
                                   aname         => 'XXOM_AME_ODR_NUM',
                                   avalue        => x_order_number
                                  );
      wf_engine.setitemattrnumber (itemtype      => p_itemtype,
                                   itemkey       => p_itemkey,
                                   aname         => 'XXOM_AME_RMA_VAL',
                                   avalue        => x_rma_value
                                  );
      wf_engine.setitemattrtext (itemtype      => p_itemtype,
                                 itemkey       => p_itemkey,
                                 aname         => 'XXOM_AME_CREATED_BY',
                                 avalue        => x_odr_created_user
                                );
      wf_engine.setitemattrtext (itemtype      => p_itemtype,
                                 itemkey       => p_itemkey,
                                 aname         => 'XXOM_AME_SHOW_MSG_FLAG',
                                 avalue        => 'Y'
                                );
   EXCEPTION
      WHEN OTHERS
      THEN
         RESULT := 'N';
         wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                          proc_name      => 'INIT_VARIABLES',
                          arg1           => SUBSTR (SQLERRM, 1, 80),
                          arg2           => p_itemtype,
                          arg3           => p_itemkey,
                          arg4           => TO_CHAR (p_activityid),
                          arg5           => funmode,
                          arg6           =>    'error location:'
                                            || g_num_err_loc_code
                         );
         RAISE;
   END init_variables;

--------------------------------------------------------------------------------------------------
   PROCEDURE clear_all_approvals (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   )
   AS
   BEGIN
      xx_intg_common_pkg.get_process_param_value ('XXOMAMERMA',
                                                  'G_TRANSACTION_TYPE_NAME',
                                                  g_chr_transaction_type
                                                 );
      ame_api2.clearallapprovals (applicationidin        => 660,
                                  transactiontypein      => g_chr_transaction_type,
                                  transactionidin        => p_itemkey
                                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         RESULT := 'N';
         wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                          proc_name      => 'CLEAR_ALL_APPROVALS',
                          arg1           => SUBSTR (SQLERRM, 1, 80),
                          arg2           => p_itemtype,
                          arg3           => p_itemkey,
                          arg4           => TO_CHAR (p_activityid),
                          arg5           => funmode,
                          arg6           =>    'error location:'
                                            || g_num_err_loc_code
                         );
         RAISE;
   END clear_all_approvals;

--------------------------------------------------------------------------------------------------
   PROCEDURE skip_ame_approvals (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   )
   AS
      x_ame_bypass_flag    VARCHAR2 (5);
      x_bypass_order_num   NUMBER;
      x_order_number       NUMBER;
   BEGIN
      BEGIN
         xx_intg_common_pkg.get_process_param_value ('XXOMAMERMA',
                                                     'AME_BYPASS_FLAG',
                                                     x_ame_bypass_flag
                                                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            x_ame_bypass_flag := NULL;
      END;

      BEGIN
         xx_intg_common_pkg.get_process_param_value ('XXOMAMERMA',
                                                     'BYPASS_ORDER_NUM',
                                                     x_bypass_order_num
                                                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            x_bypass_order_num := NULL;
      END;

      IF NVL (x_ame_bypass_flag, 'N') = 'Y'
      THEN
         IF x_bypass_order_num > 0
         THEN
            BEGIN
               SELECT order_number
                 INTO x_order_number
                 FROM oe_order_headers_all
                WHERE header_id = p_itemkey;
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_order_number := NULL;
            END;

            IF x_order_number = x_bypass_order_num
            THEN
               RESULT := 'Y';
               RETURN;
            ELSE
               RESULT := 'N';
               RETURN;
            END IF;
         END IF;

         RESULT := 'Y';
         RETURN;
      END IF;

      RESULT := 'N';
   EXCEPTION
      WHEN OTHERS
      THEN
         RESULT := 'N';
         wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                          proc_name      => 'SKIP_AME_APPROVALS',
                          arg1           => SUBSTR (SQLERRM, 1, 80),
                          arg2           => p_itemtype,
                          arg3           => p_itemkey,
                          arg4           => TO_CHAR (p_activityid),
                          arg5           => funmode,
                          arg6           =>    'error location:'
                                            || g_num_err_loc_code
                         );
         RAISE;
   END skip_ame_approvals;

--------------------------------------------------------------------------------------------------
   PROCEDURE assign_salesrep (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   )
   AS
      x_common_msg_body   VARCHAR2 (3000);
      x_common_msg_sub    VARCHAR2 (1000);
      x_validate          VARCHAR2 (1);
      x_ret_msg           VARCHAR2 (3000);
      x_success_flag      VARCHAR2 (1);
   BEGIN
      IF funmode = 'RUN'
      THEN
         BEGIN
            SELECT xx_oe_salesrep_assign_ext_pkg.check_sr_exits
                                                         (TO_NUMBER (p_itemkey)
                                                         )
              INTO x_validate
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               g_num_err_loc_code := 100;
               wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                                proc_name      => 'ASSIGN_SALESREP',
                                arg1           => SUBSTR (SQLERRM, 1, 80),
                                arg2           => p_itemtype,
                                arg3           => p_itemkey,
                                arg4           => TO_CHAR (p_activityid),
                                arg5           => funmode,
                                arg6           =>    'error location:'
                                                  || g_num_err_loc_code
                               );
               RAISE;
               x_validate := 'N';
         END;

         /* BEGIN  -- commented to test salesrep exits
            SELECT xx_oe_salesrep_assign_ext_pkg.validate_order_eligibility (to_number(p_itemKey))
            INTO x_validate
            FROM dual;
          EXCEPTION
          WHEN OTHERS THEN
              g_num_err_loc_code:=100;
              WF_CORE.CONTEXT (pkg_name       => g_chr_pkg_name,
                               proc_name      => 'ASSIGN_SALESREP',
                               arg1           => SUBSTR (SQLERRM, 1, 80),
                               arg2           => p_itemType,
                               arg3           => p_itemKey,
                               arg4           => TO_CHAR (p_activityId),
                               arg5           => funmode,
                               arg6           => 'error location:'||g_num_err_loc_code);
              RAISE;
            x_validate := 'N';
          END;*/  -- commented to test salesrep exits
         IF x_validate = 'Y'
         THEN
            fnd_message.set_name ('XXINTG', 'XXOE_SALESREP_EXISTS');
            oe_msg_pub.ADD;
            RESULT := 'Y';
            RETURN;
         ELSIF x_validate = 'N'
         THEN
            RESULT := 'N';
            fnd_message.set_name ('XXINTG', 'XXOM_AME_FAILED_SALESREP');
            oe_msg_pub.ADD;
            RETURN;
         END IF;
      /*  IF x_validate = 'N'  -- commented to test salesrep exits
         THEN
            fnd_message.set_name ('XXINTG', 'XXOE_SALESREP_EXISTS');
            oe_msg_pub.ADD;
            result := 'Y';
            RETURN;
         ElSIF x_validate = 'Y'

             x_ret_msg:=xx_oe_salesrep_assign_ext_pkg.xx_oe_call_salesrep_proc (  to_number(p_itemKey) );*/  -- commented to test salesrep exits
             /*FND_MESSAGE.SET_ENCODED(x_ret_msg);
             oe_msg_pub.ADD;*/

      /*   BEGIN  -- commented to test salesrep exits
            SELECT xx_oe_salesrep_assign_ext_pkg.validate_order_eligibility (to_number(p_itemKey))
            INTO x_success_flag
            FROM dual;
          EXCEPTION
          WHEN OTHERS THEN
              g_num_err_loc_code:=100;
              WF_CORE.CONTEXT (pkg_name       => g_chr_pkg_name,
                               proc_name      => 'ASSIGN_SALESREP',
                               arg1           => SUBSTR (SQLERRM, 1, 80),
                               arg2           => p_itemType,
                               arg3           => p_itemKey,
                               arg4           => TO_CHAR (p_activityId),
                               arg5           => funmode,
                               arg6           => 'error location:'||g_num_err_loc_code);
              RAISE;
            x_success_flag := 'Y';
          END;
          IF x_success_flag = 'Y'
          THEN
             result := 'N';
             FND_MESSAGE.set_name('XXINTG', 'XXOM_AME_FAILED_SALESREP');
             oe_msg_pub.ADD;
             RETURN;
          END IF;
          result := 'Y';
          RETURN;
      END IF;*/ -- commented to test salesrep exits
      END IF;

      IF funmode = 'CANCEL'
      THEN
         RESULT := 'N';
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RESULT := 'N';
         wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                          proc_name      => 'ASSIGN_SALESREP',
                          arg1           => SUBSTR (SQLERRM, 1, 80),
                          arg2           => p_itemtype,
                          arg3           => p_itemkey,
                          arg4           => TO_CHAR (p_activityid),
                          arg5           => funmode,
                          arg6           =>    'error location:'
                                            || g_num_err_loc_code
                         );
         RAISE;
   END assign_salesrep;

--------------------------------------------------------------------------------------------------
   PROCEDURE get_next_hrmgr (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   )
   AS
      x_appr_usrname      VARCHAR2 (50);
      x_order_number      NUMBER;
      x_esc_mgr           VARCHAR2 (50);
      x_appr_person_id    NUMBER;
      x_esc_mgr_id        NUMBER;
      x_escalation_days   NUMBER;
      x_effective_days    NUMBER;
      x_counter           NUMBER        := 1;
      x_day_date          VARCHAR2 (20);
   BEGIN
      IF funmode = 'RUN'
      THEN
         x_appr_usrname :=
            wf_engine.getitemattrtext (itemtype      => p_itemtype,
                                       itemkey       => p_itemkey,
                                       aname         => 'XXOM_AME_ESC_MGR'
                                      );
         x_order_number :=
            wf_engine.getitemattrnumber (itemtype      => p_itemtype,
                                         itemkey       => p_itemkey,
                                         aname         => 'XXOM_AME_ODR_NUM'
                                        );
         xx_intg_common_pkg.get_process_param_value ('XXOMAMERMA',
                                                     'NOTIF_TIMEOUT_DAYS',
                                                     x_escalation_days
                                                    );

         BEGIN
            /*SELECT distinct person_id
                   INTO x_appr_person_id
             FROM fnd_user fu, per_all_people_f paf
            WHERE paf.person_id = fu.employee_id
              AND SYSDATE BETWEEN paf.effective_start_date AND paf.effective_end_date
                    AND fu.user_name = x_appr_usrname;*/
            SELECT orig_system_id
              INTO x_appr_person_id
              FROM wf_users
             WHERE NAME = x_appr_usrname AND orig_system = 'PER';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               RESULT := 'N';
               g_num_err_loc_code := 110;
               wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                                proc_name      => 'GET_NEXT_HRMGR',
                                arg1           => SUBSTR (SQLERRM, 1, 80),
                                arg2           => p_itemtype,
                                arg3           => p_itemkey,
                                arg4           => TO_CHAR (p_activityid),
                                arg5           => funmode,
                                arg6           =>    'error location:'
                                                  || g_num_err_loc_code
                               );
               RAISE;
         END;

         BEGIN
            SELECT DISTINCT pafe.supervisor_id
                       INTO x_esc_mgr_id
                       FROM per_all_assignments_f pafe,
                            per_all_people_f ppfs,
                            per_all_assignments_f pafs,
                            per_person_types_v ppts,
                            per_person_type_usages_f pptu
                      WHERE pafe.person_id = x_appr_person_id
                        AND TRUNC (SYSDATE) BETWEEN pafe.effective_start_date
                                                AND pafe.effective_end_date
                        AND pafe.primary_flag = 'Y'
                        AND pafe.assignment_type IN ('E', 'C')
                        AND ppfs.person_id = pafe.supervisor_id
                        AND TRUNC (SYSDATE) BETWEEN ppfs.effective_start_date
                                                AND ppfs.effective_end_date
                        AND pafs.person_id = ppfs.person_id
                        AND TRUNC (SYSDATE) BETWEEN pafs.effective_start_date
                                                AND pafs.effective_end_date
                        AND pafs.primary_flag = 'Y'
                        AND pafs.assignment_type IN ('E', 'C')
                        AND pptu.person_id = ppfs.person_id
                        AND ppts.person_type_id = pptu.person_type_id
                        AND ppts.system_person_type IN
                                                    ('EMP', 'EMP_APL', 'CWK');
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               x_esc_mgr_id := x_appr_person_id;
         END;

         BEGIN
            SELECT NAME
              INTO x_esc_mgr
              FROM wf_users
             WHERE orig_system_id = x_esc_mgr_id AND orig_system = 'PER';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               RESULT := 'N';
               g_num_err_loc_code := 114;
               wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                                proc_name      => 'GET_NEXT_HRMGR',
                                arg1           => SUBSTR (SQLERRM, 1, 80),
                                arg2           => p_itemtype,
                                arg3           => p_itemkey,
                                arg4           => TO_CHAR (p_activityid),
                                arg5           => funmode,
                                arg6           =>    'error location:'
                                                  || g_num_err_loc_code
                               );
               RAISE;
         END;

         x_effective_days :=
                    xx_om_return_ord_ame.calc_timeout_days (x_escalation_days);
         /* x_effective_days:=x_escalation_days;
           LOOP
             BEGIN
               x_counter:= x_counter+1;
         SELECT TRIM (TO_CHAR (trunc(SYSDATE+x_counter), 'DAY'))
            INTO x_day_date
            FROM DUAL;
             END;
             IF x_day_date IN ('SATURDAY', 'SUNDAY')
             THEN
                IF x_day_date = 'SATURDAY' AND x_counter = x_escalation_days
                THEN
                   x_effective_days:=x_effective_days+3;
                ELSIF x_day_date = 'SUNDAY' AND x_counter = x_escalation_days
                THEN
                   x_effective_days:=x_effective_days+2;
                ELSE
                   x_effective_days:=x_effective_days+1;
                END IF;
             END IF;
           EXIT WHEN x_counter = x_escalation_days;
          END LOOP; */
         wf_engine.setitemattrtext (itemtype      => p_itemtype,
                                    itemkey       => p_itemkey,
                                    aname         => 'XXOM_AME_ESC_MGR',
                                    avalue        => x_esc_mgr
                                   );
         wf_engine.setitemattrnumber (itemtype      => p_itemtype,
                                      itemkey       => p_itemkey,
                                      aname         => 'XXOM_AME_TIMEOUT_DAYS',
                                      avalue        => x_effective_days
                                     );
         RESULT := 'Y';
      END IF;

      IF funmode = 'CANCEL'
      THEN
         RESULT := 'N';
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RESULT := 'N';
         wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                          proc_name      => 'GET_NEXT_HRMGR',
                          arg1           => SUBSTR (SQLERRM, 1, 80),
                          arg2           => p_itemtype,
                          arg3           => p_itemkey,
                          arg4           => TO_CHAR (p_activityid),
                          arg5           => funmode,
                          arg6           =>    'error location:'
                                            || g_num_err_loc_code
                         );
         RAISE;
   END get_next_hrmgr;

--------------------------------------------------------------------------------------------------
   PROCEDURE chk_ord_trx_type (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   )
   AS
      x_eligible_ord_tpy   VARCHAR2 (2);
   BEGIN
      IF funmode = 'RUN'
      THEN
         BEGIN
            SELECT NVL (ott.attribute2, 'N')
              INTO x_eligible_ord_tpy
              FROM oe_order_headers_all ooh, oe_transaction_types_all ott
             WHERE ooh.header_id = TO_NUMBER (p_itemkey)
               AND ooh.order_type_id = ott.transaction_type_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               RESULT := 'N';
               RETURN;
         END;

         IF x_eligible_ord_tpy = 'Y'
         THEN
            RESULT := 'Y';
            RETURN;
         ELSE
            RESULT := 'N';
            RETURN;
         END IF;
      END IF;

      IF funmode = 'CANCEL'
      THEN
         RESULT := 'N';
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RESULT := 'N';
         wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                          proc_name      => 'CHK_ORD_TRX_TYPE',
                          arg1           => SUBSTR (SQLERRM, 1, 80),
                          arg2           => p_itemtype,
                          arg3           => p_itemkey,
                          arg4           => TO_CHAR (p_activityid),
                          arg5           => funmode,
                          arg6           =>    'error location:'
                                            || g_num_err_loc_code
                         );
         RAISE;
   END chk_ord_trx_type;

--------------------------------------------------------------------------------------------------
   FUNCTION calc_timeout_days (p_orig_days NUMBER)
      RETURN NUMBER
   AS
      CURSOR c_cal_days (p_time_out NUMBER, p_cal_name VARCHAR2)
      IS
         SELECT TO_CHAR (calendar_date, 'DAY') DAY, seq_num
           FROM bom_calendar_dates
          WHERE calendar_date BETWEEN TRUNC (SYSDATE)
                                  AND TRUNC (SYSDATE + p_orig_days - 1)
            AND calendar_code = p_cal_name;

      x_effective_days   NUMBER;
      x_counter          NUMBER         := 0;
      x_day_date         VARCHAR2 (20);
      x_cal_name         VARCHAR2 (100);
   BEGIN
      x_effective_days := p_orig_days;
      xx_intg_common_pkg.get_process_param_value ('XXOMAMERMA',
                                                  'CALENDAR_CODE',
                                                  x_cal_name
                                                 );

      FOR cal_days_rec IN c_cal_days (p_orig_days, x_cal_name)
      LOOP
         x_counter := x_counter + 1;

         IF cal_days_rec.seq_num IS NULL
         THEN
            IF cal_days_rec.DAY = 'SATURDAY' AND x_counter = p_orig_days
            THEN
               x_effective_days := x_effective_days + 3;
            ELSIF cal_days_rec.DAY = 'SUNDAY' AND x_counter = p_orig_days
            THEN
               x_effective_days := x_effective_days + 2;
            ELSE
               x_effective_days := x_effective_days + 1;
            END IF;
         END IF;
      END LOOP;

      RETURN NVL (x_effective_days, 2) * 24 * 60;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NVL (p_orig_days, 2);
   END;

   --- Added on 02-Feb-2015
   PROCEDURE xx_doc_call (
      itemtype    IN       VARCHAR2,
      itemkey     IN       VARCHAR2,
      actid       IN       NUMBER,
      funcmode    IN       VARCHAR2,
      resultout   OUT      VARCHAR2
   )
   IS
      v_document_id   CLOB;
      v_itemkey       NUMBER;
      l_doc_id        NUMBER;
   BEGIN
      SELECT xx_ame_notification_s.NEXTVAL
        INTO l_doc_id
        FROM DUAL;

      wf_engine.setitemattrdocument
          (itemtype        => itemtype,
           itemkey         => itemkey,
           aname           => 'XXOM_AME_COMMON_RMA_NOTES',
           documentid      =>    'PLSQLCLOB:xx_om_return_ord_ame.xx_create_msg_wf/'
                              || TO_CHAR (l_doc_id)
                              || ':'
                              || TO_CHAR (itemkey)
          );
   END xx_doc_call;

   PROCEDURE xx_chk_flag (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   )
   AS
      x_apprv_flag        VARCHAR (100);
      x_order_number      NUMBER;
      x_rma_value         NUMBER;
      x_common_msg_body   VARCHAR2 (3000);
      x_common_msg_sub    VARCHAR2 (1000);
   BEGIN
      IF funmode = 'RUN'
      THEN
         x_apprv_flag :=
            wf_engine.getitemattrtext (itemtype      => p_itemtype,
                                       itemkey       => p_itemkey,
                                       aname         => 'XXOM_APPRV_FLOW'
                                      );

         IF x_apprv_flag = 'Y'
         THEN
            RESULT := 'Y';
            x_order_number :=
               wf_engine.getitemattrnumber (itemtype      => p_itemtype,
                                            itemkey       => p_itemkey,
                                            aname         => 'XXOM_AME_ODR_NUM'
                                           );
            x_rma_value :=
               wf_engine.getitemattrnumber (itemtype      => p_itemtype,
                                            itemkey       => p_itemkey,
                                            aname         => 'XXOM_AME_RMA_VAL'
                                           );

            BEGIN
               x_common_msg_sub :=
                  xx_intg_common_pkg.set_token_message
                              (p_message_name      => 'XXOM_AME_POST_APR_MSG_SUB',
                               p_token_value1      => x_order_number,
                               p_token_value2      => x_rma_value,
                               p_no_of_tokens      => 2
                              );
               x_common_msg_body :=
                  xx_intg_common_pkg.set_token_message
                              (p_message_name      => 'XXOM_AME_POST_APR_MSG_BODY',
                               p_token_value1      => x_order_number,
                               p_token_value2      => x_rma_value,
                               p_no_of_tokens      => 2
                              );
            EXCEPTION
               WHEN OTHERS
               THEN
                  RESULT := 'N';
                  wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                                   proc_name      => 'XX_CHK_FLAG',
                                   arg1           => SUBSTR (SQLERRM, 1, 80),
                                   arg2           => p_itemtype,
                                   arg3           => p_itemkey,
                                   arg4           => TO_CHAR (p_activityid),
                                   arg5           => funmode,
                                   arg6           => 'error location:'
                                  );
                  RAISE;
            END;

            wf_engine.setitemattrtext (itemtype      => p_itemtype,
                                       itemkey       => p_itemkey,
                                       aname         => 'XXOM_AME_COMMON_MSG_SUB',
                                       avalue        => x_common_msg_sub
                                      );
            wf_engine.setitemattrtext (itemtype      => p_itemtype,
                                       itemkey       => p_itemkey,
                                       aname         => 'XXOM_AME_COMMON_MSG_BODY',
                                       avalue        => x_common_msg_body
                                      );
         ELSE
            RESULT := 'N';
         END IF;
      END IF;

      IF (funmode = 'CANCEL')
      THEN
         RESULT := 'N';
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RESULT := 'N';
         wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                          proc_name      => 'XX_CHK_FLAG',
                          arg1           => SUBSTR (SQLERRM, 1, 80),
                          arg2           => p_itemtype,
                          arg3           => p_itemkey,
                          arg4           => TO_CHAR (p_activityid),
                          arg5           => funmode,
                          arg6           => 'error location:'
                         );
         RAISE;
   END xx_chk_flag;

   PROCEDURE xx_create_msg_wf (
      document_id     IN              VARCHAR2,
      display_type    IN              VARCHAR2,
      document        IN OUT NOCOPY   CLOB,
      document_type   IN OUT NOCOPY   VARCHAR2
   )
   IS
      lv_details            VARCHAR2 (32767);
      amount                NUMBER;
      l_der_doc_id          VARCHAR2 (100);
      temp_document         CLOB;
      x_common_msg_body     VARCHAR2 (3000);
      x_common_msg_sub      VARCHAR2 (1000);
      x_order_number        NUMBER;
      x_rma_value           NUMBER;
      x_cust_name           VARCHAR2 (1000);
      x_rma_notes           VARCHAR2 (4000);
      x_common_rma_notes    VARCHAR2 (4000);
      x_line                VARCHAR2 (1000);
      x_rma_cur_appr_name   VARCHAR2 (1000);
      p_itemtype            wf_items.item_type%TYPE;
      p_itemkey             wf_items.item_key%TYPE;

      CURSOR c_rma_notes (p_order_id NUMBER)
      IS
         SELECT   a.attached_document_id, a.document_id, a.seq_num,
                  a.category_id, b.datatype_name, b.category_description,
                  b.media_id, b.title
             FROM fnd_attached_documents a,
                  fnd_documents_vl b,
                  oe_order_headers_all c
            WHERE a.pk1_value = TO_CHAR (c.header_id)
              AND b.document_id = a.document_id
              AND b.datatype_name = 'Short Text'
              AND b.category_description = 'RMA Notes'
              AND c.header_id = p_order_id
         ORDER BY b.media_id ASC;

      CURSOR c_notes (p_media_id NUMBER)
      IS
         SELECT c.short_text
           FROM fnd_documents_short_text c
          WHERE c.media_id = p_media_id;

      CURSOR c_appr_msg_body (p_header_id NUMBER)
      IS
         SELECT *
           FROM xx_om_appr_message_body_tbl
          WHERE order_header_id = p_header_id AND ROWNUM < 2;

      -- Cursor to fetch RMA Line Details
      CURSOR c_adjustment_id (p_header_id IN NUMBER)
      IS
         SELECT   b.line_number, b.ordered_item, b.ordered_quantity,
                  b.unit_list_price, b.unit_selling_price, c.description
             FROM oe_order_headers_all a,
                  oe_order_lines_all b,
                  mtl_system_items_b c
            WHERE a.header_id = p_header_id
              AND a.header_id = b.header_id
              AND c.organization_id = (SELECT organization_id
                                         FROM org_organization_definitions
                                        WHERE organization_code = 'MST')
              AND c.inventory_item_id = b.inventory_item_id
         ORDER BY b.line_number ASC;
   BEGIN
      p_itemtype := SUBSTR (document_id, 1, INSTR (document_id, ':') - 1);
      p_itemkey :=
         SUBSTR (document_id,
                 INSTR (document_id, ':') + 1,
                 LENGTH (document_id) - 2
                );
      DBMS_LOB.createtemporary (temp_document, FALSE, DBMS_LOB.CALL);

      FOR rec_appr_msg_body IN c_appr_msg_body (p_itemkey)
      LOOP
         x_rma_notes := ' ' || '<BR>RMA Notes :' || '<BR><BR>';

         FOR rec_rma_notes IN c_rma_notes (rec_appr_msg_body.order_header_id)
         LOOP
            IF rec_rma_notes.title IS NOT NULL
            THEN
               x_rma_notes := x_rma_notes || rec_rma_notes.title || '<BR>';
               x_line := NULL;

               FOR i IN 1 .. LENGTH (rec_rma_notes.title) + 20
               LOOP
                  x_line := x_line || '-';
               END LOOP;

               x_rma_notes := x_rma_notes || x_line || '<BR>';
            END IF;

            FOR rec_notes IN c_notes (rec_rma_notes.media_id)
            LOOP
               x_rma_notes := x_rma_notes || rec_notes.short_text;
            END LOOP;

            x_rma_notes := x_rma_notes || '<BR><BR>';
         END LOOP;

         lv_details :=
               '<table border="0" cellpadding="0" cellspacing="0" width="1300">'
            || '    <tbody>'
            || '        <tr>'
            || '            <td valign="top" width="1300">'
            || '            </td>'
            || '        </tr>'
            || '        <tr>'
            || '            <td valign="top" width="1300">'
            || '<span style="font-size:12.0pt;line-height:107%;font-family:Times New Roman,serif;">'
            || SUBSTR (rec_appr_msg_body.msg_body,
                       1,
                       INSTR (rec_appr_msg_body.msg_body, ',', 1, 1)
                      )
            || '<BR><BR>'
            || SUBSTR (rec_appr_msg_body.msg_body,
                       INSTR (rec_appr_msg_body.msg_body, ',', 1, 1) + 4,
                         INSTR (rec_appr_msg_body.msg_body,
                                ', if rejecting',
                                1,
                                1
                               )
                       - INSTR (rec_appr_msg_body.msg_body, ',', 1, 1)
                       - 3
                      )
            || '<BR>'
            || SUBSTR (rec_appr_msg_body.msg_body,
                         INSTR (rec_appr_msg_body.msg_body,
                                ', if rejecting',
                                1,
                                1
                               )
                       + 2,
                       LENGTH (rec_appr_msg_body.msg_body)
                      )
            || '                 </span>'
            || '            </td>'
            || '        </tr>'
            || '        <tr>'
            || '            <td valign="top" width="500">'
            || '<pre> '
            || '<span style="font-size:12.0pt;line-height:107%;font-family:Times New Roman,serif; white-space:pre-wrap; word-break:break-all; word-wrap:break-word;"> '
            || x_rma_notes
            || ' </span>'
            || '</pre> '
            || '            </td>'
            || '        </tr>'
            || '    </tbody>'
            || '</table>';
      END LOOP;

      DBMS_LOB.writeappend (temp_document, LENGTH (lv_details), lv_details);
      lv_details := '';
      lv_details :=
            '<table border="1" cellpadding="0" cellspacing="0"> '
         || '    <tbody>'
         || '        <tr style="mso-yfti-irow:0;mso-yfti-firstrow:yes"> '
         || '           <td colspan="7" style="width:6.65in;border:solid windowtext 1.0pt; mso-border-alt:solid windowtext .5pt;background:#E5E5E5;mso-shading:windowtext;  mso-pattern:gray-10 auto;padding:0in 5.4pt 0in 5.4pt" valign="top" width="638">'
         || '                <p> <span style="font-family:Times New Roman,serif;">'
         || '                    <strong>Return Order Line Details : </strong>'
         || '                </span> </p>'
         || '            </td>'
         || '        </tr>'
         || '        <tr style="mso-yfti-irow:1">'
         || '            <td valign="top" width="67">'
         || '                <p> <span style="font-family:Times New Roman,serif;">'
         || '                    Line Number'
         || '                </span> </p>'
         || '            </td>'
         || '            <td valign="top" width="84">'
         || '                <p> <span style="font-family:Times New Roman,serif;">'
         || '                    Item'
         || '                </span> </p>'
         || '            </td>'
         || '            <td valign="top" width="500">'
         || '                <p> <span style="font-family:Times New Roman,serif;">'
         || '                    Description'
         || '                </span> </p>'
         || '            </td>'
         || '            <td valign="top" width="72">'
         || '                <p> <span style="font-family:Times New Roman,serif;">'
         || '                    Quantity'
         || '                </span> </p>'
         || '            </td>'
         || '            <td valign="top" width="78">'
         || '                <p> <span style="font-family:Times New Roman,serif;">'
         || '                    Price'
         || '                </span> </p>'
         || '            </td>'
         || '            <td valign="top" width="88">'
         || '                <p> <span style="font-family:Times New Roman,serif;">'
         || '                    Line Total'
         || '                </span> </p>'
         || '            </td>'
         || '        </tr>';
      DBMS_LOB.writeappend (temp_document, LENGTH (lv_details), lv_details);
      lv_details := '';

      FOR rec_adjustment_id IN c_adjustment_id (p_itemkey)
      LOOP
         lv_details :=
               '        <tr>'
            || '            <td valign="top" width="67">'
            || '                <p> <span style="font-family:Times New Roman,serif;">'
            || rec_adjustment_id.line_number
            || '                </span> </p>'
            || '            </td>'
            || '            <td valign="top" width="84">'
            || '                <p> <span style="font-family:Times New Roman,serif;">'
            || rec_adjustment_id.ordered_item
            || '                </span> </p>'
            || '            </td>'
            || '            <td valign="top" width="500">'
            || '                <p> <span style="font-family:Times New Roman,serif;">'
            || rec_adjustment_id.description
            || '                </span> </p>'
            || '            </td>'
            || '            <td valign="top" width="72">'
            || '                <p> <span style="font-family:Times New Roman,serif;">'
            || rec_adjustment_id.ordered_quantity
            || '                </span> </p>'
            || '            </td>'
            || '            <td valign="top" width="78">'
            || '                <p> <span style="font-family:Times New Roman,serif;">'
            || rec_adjustment_id.unit_selling_price
            || '                </span> </p>'
            || '            </td>'
            || '            <td valign="top" width="88">'
            || '                <p> <span style="font-family:Times New Roman,serif;">'
            || (  rec_adjustment_id.ordered_quantity
                * rec_adjustment_id.unit_selling_price
               )
            || '                </span> </p>'
            || '            </td>'
            || '        </tr>';
         DBMS_LOB.writeappend (temp_document, LENGTH (lv_details), lv_details);
         lv_details := '';
      END LOOP;

      lv_details := '    </tbody>' || '</table>' || '<BR></BR>';
      DBMS_LOB.writeappend (temp_document, LENGTH (lv_details), lv_details);
      lv_details := '';
      DBMS_LOB.createtemporary (document, FALSE, DBMS_LOB.CALL);
      amount := DBMS_LOB.getlength (temp_document);
      DBMS_LOB.COPY (document, temp_document, amount, 1, 1);
      document_type := 'text/html';
   EXCEPTION
      WHEN OTHERS
      THEN
         document := '<H4>Error ' || SQLERRM || '</H4>';
         document_type := 'text/html';
   END xx_create_msg_wf;

   PROCEDURE xx_om_appr_message_body (
      p_msg_body    VARCHAR2,
      p_header_id   NUMBER,
      p_mode        VARCHAR2
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      --- This is to delete 180 days old data from the custom table ---
      DELETE FROM xx_om_appr_message_body_tbl
            WHERE TRUNC (creation_date) < TRUNC (SYSDATE) - 180;

      COMMIT;

      IF p_mode = 'INS'
      THEN
         INSERT INTO xx_om_appr_message_body_tbl
                     (msg_body, order_header_id, creation_date
                     )
              VALUES (p_msg_body, p_header_id, TRUNC (SYSDATE)
                     );

         COMMIT;
      ELSIF p_mode = 'DEL'
      THEN
         DELETE FROM xx_om_appr_message_body_tbl
               WHERE order_header_id = p_header_id;

         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END xx_om_appr_message_body;

   --- WareHouse Validation ---
   PROCEDURE xx_chk_warehouse (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   )
   IS
      l_line_number   VARCHAR2 (500);
      l_count         NUMBER;
      l_order_typ     VARCHAR2 (500);
      l_org_id        NUMBER;

      CURSOR c_line_details (p_hdr_id NUMBER, p_org_id NUMBER)
      IS
         SELECT line_number
           FROM oe_order_lines_all
          WHERE header_id = p_hdr_id
            AND ship_from_org_id IS NULL
            AND org_id = p_org_id;
   BEGIN
      l_org_id :=
         wf_engine.getitemattrnumber (itemtype      => p_itemtype,
                                      itemkey       => p_itemkey,
                                      aname         => 'ORG_ID'
                                     );
      /*  Select count(*)
          into l_count
          from oe_order_headers_all
         where header_id = to_number(p_itemKey)
           and ship_from_org_id is null
           AND org_id = l_org_id;


          IF l_count > 0 THEN
            FND_MESSAGE.set_name('XXINTG', 'XXOM_WAREH_HDR_MSG');
            oe_msg_pub.ADD;
            OE_STANDARD_WF.Save_Messages;
            result := 'N';
            RETURN;
          ELSIF l_count = 0 THEN */
      l_line_number := NULL;
      RESULT := 'Y';

      FOR rec_line_details IN c_line_details (TO_NUMBER (p_itemkey), l_org_id)
      LOOP
         fnd_message.set_name ('XXINTG', 'XXOM_WAREH_LNR_MSG');
         fnd_message.set_token ('TOKEN1', rec_line_details.line_number);
         oe_msg_pub.ADD;
         oe_standard_wf.save_messages;
         RESULT := 'N';
      END LOOP;

      --END IF;
      RETURN;
   EXCEPTION
      WHEN OTHERS
      THEN
         RESULT := 'N';
         wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                          proc_name      => 'xx_chk_warehouse',
                          arg1           => SUBSTR (SQLERRM, 1, 80),
                          arg2           => p_itemtype,
                          arg3           => p_itemkey,
                          arg4           => TO_CHAR (p_activityid),
                          arg5           => funmode,
                          arg6           =>    'error location:'
                                            || g_num_err_loc_code
                         );
         RAISE;
   END;

   --- payment term Validation ---
   PROCEDURE xx_chk_payment_term (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   )
   IS
      l_line_number   VARCHAR2 (500);
      l_count         NUMBER;
      l_order_typ     VARCHAR2 (200);
      l_org_id        NUMBER;

      CURSOR c_line_details (p_hdr_id NUMBER, p_org_id NUMBER)
      IS
         SELECT line_number
           FROM oe_order_lines_all
          WHERE header_id = p_hdr_id
            AND payment_term_id IS NULL
            AND org_id = p_org_id;
   BEGIN
      l_org_id :=
         wf_engine.getitemattrnumber (itemtype      => p_itemtype,
                                      itemkey       => p_itemkey,
                                      aname         => 'ORG_ID'
                                     );

      SELECT COUNT (*)
        INTO l_count
        FROM oe_order_headers_all
       WHERE header_id = TO_NUMBER (p_itemkey)
         AND payment_term_id IS NULL
         AND org_id = l_org_id;

      RESULT := 'Y';

      IF l_count > 0
      THEN
         fnd_message.set_name ('XXINTG', 'XXOM_PAYTRM_HDR_MSG');
         oe_msg_pub.ADD;
         oe_standard_wf.save_messages;
         RESULT := 'N';
         RETURN;
      ELSIF l_count = 0
      THEN
         l_line_number := NULL;

         FOR rec_line_details IN c_line_details (TO_NUMBER (p_itemkey),
                                                 l_org_id
                                                )
         LOOP
            fnd_message.set_name ('XXINTG', 'XXOM_PAYTRM_LNR_MSG');
            fnd_message.set_token ('TOKEN1', rec_line_details.line_number);
            oe_msg_pub.ADD;
            oe_standard_wf.save_messages;
            RESULT := 'N';
         END LOOP;
      END IF;

      RETURN;
   EXCEPTION
      WHEN OTHERS
      THEN
         RESULT := 'N';
         wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                          proc_name      => 'xx_chk_payment_term',
                          arg1           => SUBSTR (SQLERRM, 1, 80),
                          arg2           => p_itemtype,
                          arg3           => p_itemkey,
                          arg4           => TO_CHAR (p_activityid),
                          arg5           => funmode,
                          arg6           =>    'error location:'
                                            || g_num_err_loc_code
                         );
         RAISE;
   END;

   --- Price List Validation ---
   PROCEDURE xx_chk_price_list (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   )
   IS
      l_line_number   VARCHAR2 (500);
      l_count         NUMBER;
      l_order_typ     VARCHAR2 (200);
      l_org_id        NUMBER;

      CURSOR c_line_details (p_hdr_id NUMBER, p_org_id NUMBER)
      IS
         SELECT line_number
           FROM oe_order_lines_all
          WHERE header_id = p_hdr_id
            AND price_list_id IS NULL
            AND org_id = p_org_id;
   BEGIN
      l_org_id :=
         wf_engine.getitemattrnumber (itemtype      => p_itemtype,
                                      itemkey       => p_itemkey,
                                      aname         => 'ORG_ID'
                                     );
      l_line_number := NULL;
      RESULT := 'Y';

      FOR rec_line_details IN c_line_details (TO_NUMBER (p_itemkey), l_org_id)
      LOOP
         fnd_message.set_name ('XXINTG', 'XXOM_PRCLST_LNR_MSG');
         fnd_message.set_token ('TOKEN1', rec_line_details.line_number);
         oe_msg_pub.ADD;
         oe_standard_wf.save_messages;
         RESULT := 'N';
      END LOOP;

      RETURN;
   EXCEPTION
      WHEN OTHERS
      THEN
         RESULT := 'N';
         wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                          proc_name      => 'xx_chk_price_list',
                          arg1           => SUBSTR (SQLERRM, 1, 80),
                          arg2           => p_itemtype,
                          arg3           => p_itemkey,
                          arg4           => TO_CHAR (p_activityid),
                          arg5           => funmode,
                          arg6           =>    'error location:'
                                            || g_num_err_loc_code
                         );
         RAISE;
   END;

   --- Quantity Validation ---
   PROCEDURE xx_chk_line_quantity (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   )
   IS
      l_line_number    VARCHAR2 (500);
      l_count          NUMBER;
      l_order_typ      VARCHAR2 (200);
      l_shipped_qty    NUMBER;
      l_tot_ret_qty    NUMBER;
      l_not_eligable   VARCHAR2 (100);
      l_org_id         NUMBER;

      CURSOR c_line_details (p_hdr_id NUMBER, p_org_id NUMBER)
      IS
         SELECT return_attribute1, return_attribute2, ordered_quantity,
                line_type_id, line_number, return_context
           FROM oe_order_lines_all
          WHERE header_id = p_hdr_id AND org_id = p_org_id;
   BEGIN
      l_not_eligable := 'N';
      RESULT := 'Y';
      l_org_id :=
         wf_engine.getitemattrnumber (itemtype      => p_itemtype,
                                      itemkey       => p_itemkey,
                                      aname         => 'ORG_ID'
                                     );

      FOR rec_line_details IN c_line_details (TO_NUMBER (p_itemkey), l_org_id)
      LOOP
         l_shipped_qty := 0;
         l_tot_ret_qty := 0;

         IF rec_line_details.return_context = 'ORDER'
         THEN
            --- Fetch the original shipped qty for that Item from the sales order
            BEGIN
               SELECT NVL (shipped_quantity, 0)
                 INTO l_shipped_qty
                 FROM oe_order_lines_all
                WHERE 1 = 1
                  AND header_id =
                                TO_NUMBER (rec_line_details.return_attribute1)
                  AND line_id = TO_NUMBER (rec_line_details.return_attribute2)
                  AND org_id = l_org_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_shipped_qty := 0;
            END;

            --- Fetch the sum of return qty for that Item
            BEGIN
               SELECT NVL (SUM (oel.ordered_quantity), 0)
                 INTO l_tot_ret_qty
                 FROM oe_order_lines_all oel, oe_order_headers_all oeh
                WHERE oel.return_context = 'ORDER'
                  -- AND line_type_id = rec_line_details.line_type_id
                  AND oel.return_attribute1 =
                                            rec_line_details.return_attribute1
                  AND oel.return_attribute2 =
                                            rec_line_details.return_attribute2
                  AND oel.org_id = l_org_id
                  AND oel.org_id = oeh.org_id
                  AND oel.header_id = oeh.header_id
                  --AND flow_status_code IN ('BOOKED', 'CLOSED');
                  AND oeh.flow_status_code IN ('BOOKED', 'CLOSED');
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_tot_ret_qty := 0;
            END;

            --- Check if prev qty is 0 then chk the current qty and display the message ---
            IF NVL (l_tot_ret_qty, 0) = 0
            THEN
               --- Condition# 2
               IF rec_line_details.ordered_quantity > l_shipped_qty
               THEN
                  fnd_message.set_name ('XXINTG', 'XXOM_QTYGTR0_LNR_MSG');
                  fnd_message.set_token ('TOKEN1',
                                         rec_line_details.line_number
                                        );
                  fnd_message.set_token ('TOKEN2', l_shipped_qty);
                  oe_msg_pub.ADD;
                  oe_standard_wf.save_messages;
                  l_not_eligable := 'Y';
               END IF;
            ELSIF l_tot_ret_qty > 0
            THEN
               --- Condition# 3
               IF l_tot_ret_qty >= l_shipped_qty
               THEN
                  fnd_message.set_name ('XXINTG', 'XXOM_QTYGTREQUAL_LNR_MSG');
                  fnd_message.set_token ('TOKEN1',
                                         rec_line_details.line_number
                                        );
                  fnd_message.set_token ('TOKEN2', l_tot_ret_qty);
                  oe_msg_pub.ADD;
                  oe_standard_wf.save_messages;
                  l_not_eligable := 'Y';
               --- Condition# 1
               ELSIF     rec_line_details.ordered_quantity >
                                              (l_shipped_qty - l_tot_ret_qty
                                              )
                     AND l_tot_ret_qty < l_shipped_qty
               THEN
                  fnd_message.set_name ('XXINTG',
                                        'XXOM_QTYGTRDIFFERENCE_LNR_MSG'
                                       );
                  fnd_message.set_token ('TOKEN1',
                                         rec_line_details.line_number
                                        );
                  fnd_message.set_token ('TOKEN2', l_tot_ret_qty);
                  fnd_message.set_token ('TOKEN3',
                                         l_shipped_qty - l_tot_ret_qty
                                        );
                  oe_msg_pub.ADD;
                  oe_standard_wf.save_messages;
                  l_not_eligable := 'Y';
               END IF;
            END IF;
         ELSE
            RESULT := 'Y'; --- If Reference Type is Not SO then go to AME ---
         END IF;
      END LOOP;

      IF l_not_eligable = 'Y'
      THEN
         RESULT := 'N';
      ELSE
         RESULT := 'Y';
      END IF;

      RETURN;
   EXCEPTION
      WHEN OTHERS
      THEN
         RESULT := 'N';
         wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                          proc_name      => 'xx_chk_line_quantity',
                          arg1           => SUBSTR (SQLERRM, 1, 80),
                          arg2           => p_itemtype,
                          arg3           => p_itemkey,
                          arg4           => TO_CHAR (p_activityid),
                          arg5           => funmode,
                          arg6           =>    'error location:'
                                            || g_num_err_loc_code
                         );
         RAISE;
   END;

   PROCEDURE xx_chk_order_typ (
      p_itemtype     IN              VARCHAR2,
      p_itemkey      IN              VARCHAR2,
      p_activityid   IN              NUMBER,
      funmode        IN              VARCHAR2,
      RESULT         OUT NOCOPY      VARCHAR2
   )
   IS
      l_order_typ   VARCHAR2 (200);
      l_org_id      NUMBER;
   BEGIN
      l_org_id :=
         wf_engine.getitemattrnumber (itemtype      => p_itemtype,
                                      itemkey       => p_itemkey,
                                      aname         => 'ORG_ID'
                                     );

      BEGIN
         SELECT NAME, b.org_id
           INTO l_order_typ, l_org_id
           FROM oe_transaction_types_tl a, oe_order_headers_all b
          WHERE a.transaction_type_id = b.order_type_id
            AND b.org_id = l_org_id
            AND b.header_id = TO_NUMBER (p_itemkey)
            AND ROWNUM < 2;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_order_typ := NULL;
      END;

      IF l_order_typ LIKE '%Return%'
      THEN
         RESULT := 'Y';
      ELSE
         RESULT := 'N';
      END IF;

      RETURN;
   EXCEPTION
      WHEN OTHERS
      THEN
         RESULT := 'N';
         wf_core.CONTEXT (pkg_name       => g_chr_pkg_name,
                          proc_name      => 'xx_chk_order_typ',
                          arg1           => SUBSTR (SQLERRM, 1, 80),
                          arg2           => p_itemtype,
                          arg3           => p_itemkey,
                          arg4           => TO_CHAR (p_activityid),
                          arg5           => funmode,
                          arg6           =>    'error location:'
                                            || g_num_err_loc_code
                         );
         RAISE;
   END;
END xx_om_return_ord_ame;
/
