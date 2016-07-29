DROP PACKAGE BODY APPS.XX_JTF_USER_REG_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_JTF_USER_REG_PKG" 
	----------------------------------------------------------------------
	/* $Header: XXJTF_USERREG.pkb 1.0 2012/07/20 12:00:00 pnarva noship $ */
	/*
	 Created By     : IBM Development Team
	 Creation Date  : 20-Jul-2012
	 File Name      : XXJTF_USERREG.pks
	 Description    : This script creates the body of xx_jtf_user_reg_pkg package

	 Change History:

	 Version Date          Name                    Remarks
	 ------- -----------   ----                    ----------------------
	 1.0     20-Jul-2012   IBM Development Team    Initial development.
	*/
	----------------------------------------------------------------------
	AS
	   g_status      VARCHAR2 (50);
	   g_role_name   VARCHAR2 (200);
	   g_role_desc   VARCHAR2 (200);

	-- =================================================================================
	-- Name           : xx_jtf_send_mail
	-- Description    : Procedure is used to send mails to the User to notify about the
	--                  approval progress
	-- Parameters description       :
	--
	-- itemtype                    : Parameter To Store itemtype (IN)
	-- itemkey                     : Parameter To Store itemkey  (IN)
	-- actid                       : Parameter To Store actid    (IN)
	-- funcmode                    : Parameter To Store funcmode (IN)
	-- resultout                   : Parameter To Store resultout(IN OUT)
	-- ==============================================================================

	   PROCEDURE xx_jtf_send_mail (
	      itemtype    IN              VARCHAR2,
	      itemkey     IN              VARCHAR2,
	      actid       IN              NUMBER,
	      funcmode    IN              VARCHAR2,
	      resultout   OUT NOCOPY      VARCHAR2
	   )
	   IS
	      x_msg_sender              VARCHAR2 (100) ;
	      x_can_email               VARCHAR2 (100);
	      x_msg_sub                 VARCHAR2 (2000);
	      x_msg_body                VARCHAR2 (2000);
	      x_loop_counter            NUMBER;
	      x_main_counter            NUMBER;
	      x_user_key                VARCHAR2 (50);
	      x_user_name               VARCHAR2 (240);
	      x_seq_num                 NUMBER;
	      x_ac_num                  VARCHAR2 (30);
	      x_ac_name                 VARCHAR2 (240);
	      x_first_name              VARCHAR2 (240);
	      x_last_name               VARCHAR2 (240);
	      x_email                   VARCHAR2 (2000);
	      x_business_number         VARCHAR2 (80);
	      x_personal_ph_number      VARCHAR2 (80);
	      x_comments                VARCHAR2 (2000);
	   BEGIN
	      IF (funcmode = 'RUN')
	      THEN
		 x_user_name :=
		    wf_engine.getitemattrtext (itemtype      => itemtype,
					       itemkey       => itemkey,
					       aname         => 'USER_NAME'
					      );
		 x_user_key :=
		    wf_engine.getitemuserkey (itemtype      => itemtype,
					      itemkey       => itemkey);

		 x_seq_num  :=
		    wf_engine.getitemattrnumber (itemtype      => itemtype,
						 itemkey       => itemkey,
						 aname         => 'XXIBE_SEQ_NUM'
						);


		 BEGIN
		    xx_intg_common_pkg.get_process_param_value( 'XXIBEAMEAPR'
								,'MESSAGE_SENDER'
							       ,x_msg_sender
							      );
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					itemtype,
					itemkey,
					'xx_jtf_send_mail- Check Message Sender Name in Process Setup Parameter'
				       );
		       RAISE;
		 END;

		 BEGIN
		    UPDATE xxjtf_user_reg_tbl
		       SET user_key = x_user_key,
			   item_key = itemkey,
			   item_type = itemtype
		     WHERE account_name = x_user_name AND user_key IS NULL
		       AND seq_num = x_seq_num;
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					itemtype,
					itemkey,
					'xx_jtf_send_mail'
				       );
		       RAISE;
		 END;


		 BEGIN
		    SELECT account_number,
			   account_name,
			   first_name,
			   last_name,
			   email,
			   comments,
			   business_ph_country_code||business_ph_area_code||business_ph_number||decode(Business_ph_extn,NUll,NUll,'-'||Business_ph_extn),
			   personal_ph_country_code||personal_ph_area_code||personal_ph_number||decode(personal_ph_extn,NUll,NUll,'-'||personal_ph_extn)
		      INTO x_ac_num,
			   x_ac_name,
			   x_first_name,
			   x_last_name,
			   x_email,
			   x_comments,
			   x_business_number,
			   x_personal_ph_number
		      FROM xxjtf_user_reg_tbl
		     WHERE seq_num = x_seq_num;
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					itemtype,
					itemkey,
					'xx_jtf_send_mail'
				       );
		       RAISE;
		 END;


		 wf_engine.setitemattrnumber (itemtype,
					      itemkey,
					      'XX_JTF_ACC_NUM',
					      x_ac_num
					     );
		 wf_engine.setitemattrtext (itemtype,
					    itemkey,
					    'XX_JTF_ACC_NAM',
					    x_ac_name
					   );
		 wf_engine.setitemattrtext (itemtype,
					    itemkey,
					    'XX_JTF_FIRST_NAM',
					    x_first_name
					   );
		 wf_engine.setitemattrtext (itemtype,
					    itemkey,
					    'XX_JTF_LAST_NAM',
					    x_last_name
					   );
		 wf_engine.setitemattrtext (itemtype,
					    itemkey,
					    'XX_JTF_EMAIL',
					    x_email
					   );
		 wf_engine.setitemattrtext (itemtype,
					    itemkey,
					    'XX_JTF_BIZ_PH',
					    x_business_number
					   );
		 wf_engine.setitemattrtext (itemtype,
					    itemkey,
					    'XX_JTF_PER_PH',
					    x_personal_ph_number
					   );
		 wf_engine.setitemattrtext (itemtype,
					    itemkey,
					    'XX_JTF_USER_COMMENTS',
					    x_comments
					   );

		 BEGIN
		    SELECT email
		      INTO x_can_email
		      FROM xxjtf_user_reg_tbl
		     WHERE user_key = x_user_key
		       AND seq_num = x_seq_num;

		    xx_intg_common_pkg.get_process_param_value( 'XXIBEAMEAPR'
								,'MESSAGE_SUBJECT_1'
							       ,x_msg_sub
							      );

		    x_msg_body :=xx_intg_common_pkg.set_long_message( 'XX_IBE_USR_REG_BODY'
								  ,NVL(x_user_name,' ')
								  ,NVL(x_ac_num,' ')
								  ,NVL(x_ac_name,' ')
								  ,NVL(x_first_name,' ')
								  ,NVL(x_last_name, ' ')
								  ,NVL(x_email,' ')
								  ,NVL(x_business_number, ' ')
								  ,NVL(x_personal_ph_number,' ')
								  ,NVL(x_comments,' ')
								 );
		    BEGIN
		       xx_intg_mail_util_pkg.mail (sender          => x_msg_sender,
						   recipients      => x_can_email,
						   subject         => x_msg_sub,
						   MESSAGE         => x_msg_body
						  );
		    EXCEPTION
		       WHEN OTHERS
		       THEN
			  resultout:='N';
			  RETURN;
		    END;

		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					itemtype,
					itemkey,
					'xx_jtf_send_mail'
				       );
		       RAISE;
		 END;
		 resultout:='Y';
	      END IF;
	   EXCEPTION
	      WHEN OTHERS
	      THEN
		 wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
				  SUBSTR (SQLERRM, 1, 200),
				  itemtype,
				  itemkey,
				  'xx_jtf_send_mail'
				 );
		 RAISE;
	   END xx_jtf_send_mail;
	----------------------------------------------------------------------

	   PROCEDURE xx_jtf_create_adhoc_role (
	      p_email    IN   VARCHAR2,
	      itemtype   IN   VARCHAR2,
	      itemkey    IN   VARCHAR2
	   )
	   IS
	      l_role_name   VARCHAR2 (200) := NULL;
	      l_err         VARCHAR2 (100);
	   BEGIN
	      BEGIN
		 SELECT NAME
		   INTO l_role_name
		   FROM wf_roles
		  WHERE UPPER (NAME) = g_role_name;
	      EXCEPTION
		 WHEN OTHERS
		 THEN
		    l_role_name := NULL;
	      END;

	      IF l_role_name IS NULL
	      THEN
		 BEGIN
		    wf_directory.createadhocrole (g_role_name,
						  g_role_name,
						  NULL,
						  NULL,
						  g_role_desc,
						  'MAILHTML',
						  NULL,
						  p_email,
						  NULL,
						  'ACTIVE',
						  NULL
						 );
		 END;
	      END IF;
	   EXCEPTION
	      WHEN OTHERS
	      THEN
		 wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
				  SUBSTR (SQLERRM, 1, 200),
				  itemtype,
				  itemkey,
				  'xx_jtf_create_adhoc_role'
				 );
		 RAISE;
		 NULL;
	   END xx_jtf_create_adhoc_role;

	-- =================================================================================
	-- Name           : xx_jtf_admin_appr
	-- Description    : Procedure is used to send mails to the User to notify about the
	--                  approval progress and also send a notification to the Admin
	--                  to create user account for the User.
	-- Parameters description       :
	--
	-- itemtype                    : Parameter To Store itemtype (IN)
	-- itemkey                     : Parameter To Store itemkey  (IN)
	-- actid                       : Parameter To Store actid    (IN)
	-- funcmode                    : Parameter To Store funcmode (IN)
	-- resultout                   : Parameter To Store resultout(IN OUT)
	-- ==============================================================================

	   PROCEDURE xx_jtf_admin_appr (
	      itemtype    IN              VARCHAR2,
	      itemkey     IN              VARCHAR2,
	      actid       IN              NUMBER,
	      funcmode    IN              VARCHAR2,
	      resultout   OUT NOCOPY      VARCHAR2
	   )
	   IS
	      x_user_name               VARCHAR2 (240);
	      x_user_key                VARCHAR2 (50);
	      x_body                    VARCHAR2 (4000);
	      x_admin_appr              VARCHAR2 (80);
	      x_seq_num                 NUMBER;
	      x_admin_apprv_lookup      VARCHAR2 (100);
	      x_ac_num                  VARCHAR2 (30);
	      x_ac_name                 VARCHAR2 (240);
	      x_first_name              VARCHAR2 (240);
	      x_last_name               VARCHAR2 (240);
	      x_email                   VARCHAR2 (2000);
	      x_business_number         VARCHAR2 (80);
	      x_personal_ph_number      VARCHAR2 (80);
	      x_comments                VARCHAR2 (2000);
	      x_msg_body                VARCHAR2(3000);
	      x_msg_sub                 VARCHAR2(1000);
	   BEGIN
	      x_user_name := NULL;
	      x_user_key := NULL;
	      x_admin_appr := NULL;

	      IF (funcmode = 'RUN')
	      THEN
		 x_user_name :=
		    wf_engine.getitemattrtext (itemtype      => itemtype,
					       itemkey       => itemkey,
					       aname         => 'USER_NAME'
					      );
		 x_user_key :=
		    wf_engine.getitemuserkey (itemtype      => itemtype,
					      itemkey       => itemkey);
		 x_seq_num :=
		    wf_engine.getitemattrnumber (itemtype      => itemtype,
						 itemkey       => itemkey,
						 aname         => 'XXIBE_SEQ_NUM'
						);

		    BEGIN
		       xx_intg_common_pkg.get_process_param_value( 'XXIBEAMEAPR'
								  ,'G_ADMIN_APPRV_LOOKUP'
								  ,x_admin_apprv_lookup
								 );
		    EXCEPTION
		       WHEN OTHERS
		       THEN
			  wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					   SUBSTR (SQLERRM, 1, 200),
					   itemtype,
					   itemkey,
					   'xx_jtf_admin_appr- Check Admin Lookup Name in Process Setup Parameter'
					  );
			  RAISE;
		    END;

		    BEGIN
		       SELECT account_number,
			      account_name,
			      first_name,
			      last_name,
			      email,
			      comments,
			      business_ph_country_code||business_ph_area_code||business_ph_number||decode(Business_ph_extn,NUll,NUll,'-'||Business_ph_extn),
			      personal_ph_country_code||personal_ph_area_code||personal_ph_number||decode(personal_ph_extn,NUll,NUll,'-'||personal_ph_extn)
			 INTO x_ac_num,
			      x_ac_name,
			      x_first_name,
			      x_last_name,
			      x_email,
			      x_comments,
			      x_business_number,
			      x_personal_ph_number
			 FROM xxjtf_user_reg_tbl
			WHERE seq_num = x_seq_num;
		    EXCEPTION
		       WHEN OTHERS
		       THEN
			  wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					   SUBSTR (SQLERRM, 1, 200),
					   itemtype,
					   itemkey,
					   'xx_jtf_admin_appr'
					  );
			  RAISE;
		    END;


		 BEGIN
		    SELECT meaning
		      INTO x_admin_appr
		      FROM fnd_lookup_values_vl
		     WHERE lookup_type = x_admin_apprv_lookup
		       AND enabled_flag = 'Y'
		       AND TRUNC (SYSDATE) BETWEEN (NVL (start_date_active,
							 TRUNC (SYSDATE)
							)
						   )
					       AND (NVL (end_date_active,
							 TRUNC (SYSDATE)
							)
						   );
		  EXCEPTION
		    WHEN OTHERS
			  THEN
	                  resultout := 'COMPLETE:N';
	                  RETURN;
		  END;

 		 BEGIN
		    IF x_admin_appr IS NOT NULL
		    THEN
		       g_role_name := 'XX_JTF_USR_APPR_ROLE-' || itemkey;
		       g_role_desc := 'XX_JTF_USR_APPR_ROLE-' || itemkey;
		       --- Creating role --
		       xx_jtf_create_adhoc_role (x_admin_appr, itemtype, itemkey);
		       wf_engine.setitemattrtext (itemtype      => itemtype,
						  itemkey       => itemkey,
						  aname         => 'XX_JTF_APPROVER_LIST',
						  avalue        => g_role_name
						 );
		       /*wf_engine.setitemattrtext (itemtype,
						  itemkey,
						  'MAIL_SUB',
						  'iStore User Approval'
						 );
		       */
		       BEGIN

			  x_msg_sub:=xx_intg_common_pkg.set_long_message('XX_IBE_ADMIN_APR_MSG_SUB');

			  x_msg_body :=xx_intg_common_pkg.set_long_message( 'XX_IBE_ADMIN_APR_MSG_BODY'
									    ,NVL(x_user_name,' ')
									   ,NVL(x_ac_num,' ')
									   ,NVL(x_ac_name,' ')
									   ,NVL(x_first_name,' ')
									   ,NVL(x_last_name, ' ')
									   ,NVL(x_email,' ')
									   ,NVL(x_business_number, ' ')
									   ,NVL(x_personal_ph_number,' ')
									   ,NVL(x_comments,' ')
									 );
			  wf_engine.setitemattrtext (itemtype      => itemtype,
						     itemkey       => itemkey,
						     aname         => 'XXIBE_MAIL_SUB',
						     avalue        => x_msg_sub
						    );
			  wf_engine.setitemattrtext (itemtype      => itemtype,
						     itemkey       => itemkey,
						     aname         => 'XXIBE_MAIL_BODY',
						     avalue        => x_msg_body
						    );


		       EXCEPTION
			  WHEN OTHERS
			  THEN
			     wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					      SUBSTR (SQLERRM, 1, 200),
					      itemtype,
					      itemkey,
					      'xx_jtf_admin_appr'
					     );
			     RAISE;
		       END;

		       resultout := 'COMPLETE:Y';
		    --ELSE
		       --resultout := 'COMPLETE:N';
		    END IF;
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					itemtype,
					itemkey,
					'xx_jtf_admin_appr'
				       );
		       RAISE;
		 END;
	      END IF;
	   EXCEPTION
	      WHEN OTHERS
	      THEN
		 wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
				  SUBSTR (SQLERRM, 1, 200),
				  itemtype,
				  itemkey,
				  'xx_jtf_admin_appr'
				 );
		 RAISE;
	   END xx_jtf_admin_appr;


	-- =================================================================================
	-- Name           : xx_jtf_usr_approved
	-- Description    : Procedure is used to send mails to the User to notify about the
	--                  approval completion of the User Creation request.
	-- Parameters description       :
	--
	-- itemtype                    : Parameter To Store itemtype (IN)
	-- itemkey                     : Parameter To Store itemkey  (IN)
	-- actid                       : Parameter To Store actid    (IN)
	-- funcmode                    : Parameter To Store funcmode (IN)
	-- resultout                   : Parameter To Store resultout(IN OUT)
	-- ==============================================================================
	   PROCEDURE xx_jtf_usr_approved (
	      itemtype    IN              VARCHAR2,
	      itemkey     IN              VARCHAR2,
	      actid       IN              NUMBER,
	      funcmode    IN              VARCHAR2,
	      resultout   OUT NOCOPY      VARCHAR2
	   )
	   IS
	      x_msg_sender              VARCHAR2 (100);
	      x_can_email               VARCHAR2 (100);
	      x_msg_sub                 VARCHAR2 (2000);
	      x_msg_body                VARCHAR2 (2000);
	      x_user_key                VARCHAR2 (50);
	      x_user_name               VARCHAR2 (240);
	      x_ac_num                  VARCHAR2 (30);
	      x_ac_name                 VARCHAR2 (240);
	      x_first_name              VARCHAR2 (240);
	      x_last_name               VARCHAR2 (240);
	      x_email                   VARCHAR2 (2000);
	      x_business_number         VARCHAR2 (80);
	      x_personal_ph_number      VARCHAR2 (80);
	      x_comments                VARCHAR2 (2000);
	      x_seq_num                 NUMBER;
	   BEGIN
	      IF (funcmode = 'RUN')
	      THEN
		 x_user_name :=
		    wf_engine.getitemattrtext (itemtype      => itemtype,
					       itemkey       => itemkey,
					       aname         => 'USER_NAME'
					      );
		 x_user_key :=
		    wf_engine.getitemuserkey (itemtype      => itemtype,
					      itemkey       => itemkey);
		 x_seq_num  :=
		    wf_engine.getitemattrnumber (itemtype      => itemtype,
						 itemkey       => itemkey,
						 aname         => 'XXIBE_SEQ_NUM'
						);
		 BEGIN
		    xx_intg_common_pkg.get_process_param_value( 'XXIBEAMEAPR'
								,'MESSAGE_SENDER'
							       ,x_msg_sender
							      );
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					itemtype,
					itemkey,
					'xx_jtf_usr_approved - Check Message Sender Name in Process Setup Parameter'
				       );
		       RAISE;
		 END;

		 BEGIN
		    g_status := 'APPROVED';

		    UPDATE xxjtf_user_reg_tbl
		       SET status = g_status
		     WHERE user_key = x_user_key;
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					itemtype,
					itemkey,
					'xx_jtf_usr_approved'
				       );
		       RAISE;
		 END;

		 BEGIN
		    SELECT account_number,
			   account_name,
			   first_name,
			   last_name,
			   email,
			   comments,
			   business_ph_country_code||business_ph_area_code||business_ph_number||decode(Business_ph_extn,NUll,NUll,'-'||Business_ph_extn),
			   personal_ph_country_code||personal_ph_area_code||personal_ph_number||decode(personal_ph_extn,NUll,NUll,'-'||personal_ph_extn)
		      INTO x_ac_num,
			   x_ac_name,
			   x_first_name,
			   x_last_name,
			   x_email,
			   x_comments,
			   x_business_number,
			   x_personal_ph_number
		      FROM xxjtf_user_reg_tbl
		     WHERE seq_num = x_seq_num;
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					itemtype,
					itemkey,
					'xx_jtf_usr_approved'
				       );
		       RAISE;
		 END;

		 BEGIN
		    SELECT email
		      INTO x_can_email
		      FROM xxjtf_user_reg_tbl
		     WHERE user_key = x_user_key
		       AND seq_num = x_seq_num;

		    xx_intg_common_pkg.get_process_param_value( 'XXIBEAMEAPR'
								,'MESSAGE_SUBJECT_3'
							       ,x_msg_sub
							      );

		    x_msg_body :=xx_intg_common_pkg.set_long_message( 'XX_IBE_USR_CRE_BODY'
								  ,NVL(x_user_name,' ')
								  ,NVL(x_ac_num,' ')
								  ,NVL(x_ac_name,' ')
								  ,NVL(x_first_name,' ')
								  ,NVL(x_last_name, ' ')
								  ,NVL(x_email,' ')
								  ,NVL(x_business_number, ' ')
								  ,NVL(x_personal_ph_number,' ')
								  ,NVL(x_comments,' ')
								 );
		    BEGIN
		       xx_intg_mail_util_pkg.mail (sender          => x_msg_sender,
						   recipients      => x_can_email,
						   subject         => x_msg_sub,
						   MESSAGE         => x_msg_body
						  );
		    EXCEPTION
		       WHEN OTHERS
		       THEN
			 resultout:='N';
			 RETURN;
		    END;
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					itemtype,
					itemkey,
					'xx_jtf_usr_approved'
				       );
		       RAISE;
		 END;
		 resultout:='Y';
	      END IF;
	   EXCEPTION
	      WHEN OTHERS
	      THEN
		 wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
				  SUBSTR (SQLERRM, 1, 200),
				  itemtype,
				  itemkey,
				  'xx_jtf_usr_approved'
				 );
		 RAISE;
	   END xx_jtf_usr_approved;

	-- =================================================================================
	-- Name           : xx_jtf_usr_rejected
	-- Description    : Procedure is used to send mails to the User to notify about the
	--                  approval rejection of the User Creation request.
	-- Parameters description       :
	--
	-- itemtype                    : Parameter To Store itemtype (IN)
	-- itemkey                     : Parameter To Store itemkey  (IN)
	-- actid                       : Parameter To Store actid    (IN)
	-- funcmode                    : Parameter To Store funcmode (IN)
	-- resultout                   : Parameter To Store resultout(IN OUT)
	-- ==============================================================================
	   PROCEDURE xx_jtf_usr_rejected (
	      itemtype    IN              VARCHAR2,
	      itemkey     IN              VARCHAR2,
	      actid       IN              NUMBER,
	      funcmode    IN              VARCHAR2,
	      resultout   OUT NOCOPY      VARCHAR2
	   )
	   IS
	      x_msg_sender              VARCHAR2 (100);
	      x_can_email               VARCHAR2 (100);
	      x_msg_sub                 VARCHAR2 (2000);
	      x_msg_body                VARCHAR2 (2000);
	      x_user_key                VARCHAR2 (50);
	      x_user_name               VARCHAR2 (240);
	      x_ac_num                  VARCHAR2 (30);
	      x_ac_name                 VARCHAR2 (240);
	      x_first_name              VARCHAR2 (240);
	      x_last_name               VARCHAR2 (240);
	      x_email                   VARCHAR2 (2000);
	      x_business_number         VARCHAR2 (80);
	      x_personal_ph_number      VARCHAR2 (80);
	      x_comments                VARCHAR2 (2000);
	      x_seq_num                 NUMBER;
	   BEGIN
	      g_status := 'REJECTED';

	      IF (funcmode = 'RUN')
	      THEN
		 x_user_name :=
		    wf_engine.getitemattrtext (itemtype      => itemtype,
					       itemkey       => itemkey,
					       aname         => 'USER_NAME'
					      );
		 x_user_key :=
		    wf_engine.getitemuserkey (itemtype      => itemtype,
					      itemkey       => itemkey);

		 x_seq_num  :=
		    wf_engine.getitemattrnumber (itemtype      => itemtype,
						 itemkey       => itemkey,
						 aname         => 'XXIBE_SEQ_NUM'
						);


		 BEGIN
		    xx_intg_common_pkg.get_process_param_value( 'XXIBEAMEAPR'
								,'MESSAGE_SENDER'
							       ,x_msg_sender
							      );
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					itemtype,
					itemkey,
					'xx_jtf_usr_rejected - Check Message Sender Name in Process Setup Parameter'
				       );
		       RAISE;
		 END;

		 BEGIN
		    UPDATE xxjtf_user_reg_tbl
		       SET status = g_status
		     WHERE user_key = x_user_key;
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					itemtype,
					itemkey,
					'xx_jtf_usr_rejected'
				       );
		       RAISE;
		 END;

		 BEGIN
		    SELECT account_number,
			   account_name,
			   first_name,
			   last_name,
			   email,
			   comments,
			   business_ph_country_code||business_ph_area_code||business_ph_number||decode(Business_ph_extn,NUll,NUll,'-'||Business_ph_extn),
			   personal_ph_country_code||personal_ph_area_code||personal_ph_number||decode(personal_ph_extn,NUll,NUll,'-'||personal_ph_extn)
		      INTO x_ac_num,
			   x_ac_name,
			   x_first_name,
			   x_last_name,
			   x_email,
			   x_comments,
			   x_business_number,
			   x_personal_ph_number
		      FROM xxjtf_user_reg_tbl
		     WHERE seq_num = x_seq_num;
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					itemtype,
					itemkey,
					'xx_jtf_usr_rejected'
				       );
		       RAISE;
		 END;

		 BEGIN
		    SELECT email
		      INTO x_can_email
		      FROM xxjtf_user_reg_tbl
		     WHERE user_key = x_user_key
		       AND seq_num = x_seq_num;

		    xx_intg_common_pkg.get_process_param_value( 'XXIBEAMEAPR'
								,'MESSAGE_SUBJECT_2'
							       ,x_msg_sub
							      );

		    x_msg_body :=xx_intg_common_pkg.set_long_message( 'XX_IBE_USR_REJ_BODY'
								  ,NVL(x_user_name,' ')
								  ,NVL(x_ac_num,' ')
								  ,NVL(x_ac_name,' ')
								  ,NVL(x_first_name,' ')
								  ,NVL(x_last_name, ' ')
								  ,NVL(x_email,' ')
								  ,NVL(x_business_number, ' ')
								  ,NVL(x_personal_ph_number,' ')
								  ,NVL(x_comments,' ')
								 );
		    BEGIN
			xx_intg_mail_util_pkg.mail (sender          => x_msg_sender,
						    recipients      => x_can_email,
						    subject         => x_msg_sub,
						    MESSAGE         => x_msg_body
						   );
		    EXCEPTION
		       WHEN OTHERS
		       THEN
			 resultout:='N';
			 RETURN;
		    END;
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					itemtype,
					itemkey,
					'xx_jtf_usr_rejected'
				       );
		       RAISE;
		 END;
		 resultout:='Y';
	      END IF;
	   EXCEPTION
	      WHEN OTHERS
	      THEN
		 wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
				  SUBSTR (SQLERRM, 1, 200),
				  itemtype,
				  itemkey,
				  'xx_jtf_usr_rejected'
				 );
		 RAISE;
	   END xx_jtf_usr_rejected;

	-- =================================================================================
	-- Name           : xx_jtf_create_user
	-- Description    : Procedure is used to create contact , relationship , account roles
	--                  contact points.
	-- Parameters description       :
	--
	-- itemtype                    : Parameter To Store itemtype (IN)
	-- itemkey                     : Parameter To Store itemkey  (IN)
	-- actid                       : Parameter To Store actid    (IN)
	-- funcmode                    : Parameter To Store funcmode (IN)
	-- resultout                   : Parameter To Store resultout(IN OUT)
	-- ==============================================================================
	   PROCEDURE xx_jtf_create_user (
	      itemtype    IN              VARCHAR2,
	      itemkey     IN              VARCHAR2,
	      actid       IN              NUMBER,
	      funcmode    IN              VARCHAR2,
	      resultout   OUT NOCOPY      VARCHAR2
	   )
	   IS
	      x_user_key                xxjtf_user_reg_tbl.user_key%TYPE;
	      x_user_name               xxjtf_user_reg_tbl.first_name%TYPE;
	      x_last_name               xxjtf_user_reg_tbl.last_name%TYPE;
	      x_password                xxjtf_user_reg_tbl.PASSWORD%TYPE;
	      x_email                   xxjtf_user_reg_tbl.email%TYPE;
	      x_account_number          xxjtf_user_reg_tbl.account_number%TYPE;
	      x_account_name            xxjtf_user_reg_tbl.account_name%TYPE;
	      x_cust_acct_id            hz_cust_accounts_all.cust_account_id%TYPE;
	      x_org_party_id            hz_parties.party_id%TYPE;
	      x_user_id                 NUMBER;
	      x_biz_ph_country_code     xxjtf_user_reg_tbl.business_ph_country_code%TYPE;
	      x_biz_ph_area_code        xxjtf_user_reg_tbl.business_ph_area_code%TYPE;
	      x_biz_ph_number           xxjtf_user_reg_tbl.business_ph_number%TYPE;
	      x_biz_ph_extn             xxjtf_user_reg_tbl.business_ph_extn%TYPE;
	      x_per_ph_country_code     xxjtf_user_reg_tbl.personal_ph_country_code%TYPE;
	      x_per_ph_area_code        xxjtf_user_reg_tbl.personal_ph_area_code%TYPE;
	      x_per_ph_number           xxjtf_user_reg_tbl.personal_ph_number%TYPE;
	      x_per_ph_extn             xxjtf_user_reg_tbl.personal_ph_extn%TYPE;
	      x_return_status           VARCHAR2 (2000);
	      x_msg_count               NUMBER;
	      x_msg_data                VARCHAR2 (2000);
	      x_output                  VARCHAR2 (4000);
	      x_msg_dummy               VARCHAR2 (4000);
	      x_person_party_id         hz_parties.party_id%TYPE;
	      x_person_party_number     hz_parties.party_number%TYPE;
	      x_person_profile_id       hz_person_profiles.person_profile_id%TYPE;
	      x_create_person_rec       hz_party_v2pub.person_rec_type;
	      x_org_contact_id          hz_org_contacts.org_contact_id%TYPE;
	      x_party_rel_id            hz_relationships.relationship_id%TYPE;
	      x_api_party_id            hz_parties.party_id%TYPE;
	      x_api_party_number        hz_parties.party_number%TYPE;
	      x_org_contact_rec         hz_party_contact_v2pub.org_contact_rec_type;
	      x_cust_account_role_rec   hz_cust_account_role_v2pub.cust_account_role_rec_type;
	      x_cust_account_role_id    hz_cust_account_roles.cust_account_role_id%TYPE;
	      x_contact_point_id        hz_contact_points.contact_point_id%TYPE;
	      x_contact_point_rec       hz_contact_point_v2pub.contact_point_rec_type;
	      x_phone_rec               hz_contact_point_v2pub.phone_rec_type;
	      x_email_rec               hz_contact_point_v2pub.email_rec_type;
	      x_error_flag              VARCHAR2 (1)                           := 'S';
	      x_wf_exception            EXCEPTION;
	   BEGIN
	      IF (funcmode = 'RUN')
	      THEN
		 BEGIN
		    x_user_key :=
		       wf_engine.getitemuserkey (itemtype      => itemtype,
						 itemkey       => itemkey
						);
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       x_error_flag := 'E';
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					itemtype,
					itemkey,
					'xx_jtf_create_user'
				       );
		       RAISE;
		 END;

		 BEGIN
		    SELECT first_name, last_name, PASSWORD, email,
			   account_number, account_name, business_ph_country_code,
			   business_ph_area_code, business_ph_number,
			   business_ph_extn, personal_ph_country_code,
			   personal_ph_area_code, personal_ph_number,
			   personal_ph_extn
		      INTO x_user_name, x_last_name, x_password, x_email,
			   x_account_number, x_account_name, x_biz_ph_country_code,
			   x_biz_ph_area_code, x_biz_ph_number,
			   x_biz_ph_extn, x_per_ph_country_code,
			   x_per_ph_area_code, x_per_ph_number,
			   x_per_ph_extn
		      FROM xxjtf_user_reg_tbl
		     WHERE user_key = x_user_key;                   --'USERKEY:409';--
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       x_error_flag := 'E';
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					itemtype,
					itemkey,
					'xx_jtf_create_user'
				       );
		       RAISE;
		 END;

		 BEGIN
		    SELECT hp.party_id, hca.cust_account_id
		      INTO x_org_party_id, x_cust_acct_id
		      FROM hz_parties hp, hz_cust_accounts_all hca
		     WHERE hp.party_id = hca.party_id
		       AND hca.account_number = x_account_number
		       AND hca.account_name = x_account_name;
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       x_error_flag := 'E';
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					itemtype,
					itemkey,
					'xx_jtf_create_user'
				       );
		       RAISE;
		 END;

		 SAVEPOINT create_contact_person;
		 ------------------------------ Contact Creation ------------------------------------------

		 /********************* Person Party *******************/
		 x_return_status := NULL;
		 x_msg_count := NULL;
		 x_msg_data := NULL;
		 x_person_party_id := NULL;
		 x_person_party_number := NULL;
		 x_person_profile_id := NULL;
		 x_create_person_rec := NULL;

		 BEGIN
		    x_create_person_rec.person_last_name := x_last_name;
		    --x_create_person_rec.person_middle_name  := l_rec_cust_contacts.middle_name;
		    x_create_person_rec.person_first_name := x_user_name;
		    x_create_person_rec.created_by_module := 'TCA_V1_API';
		    hz_party_v2pub.create_person
					    (p_init_msg_list      => 'T',
					     p_person_rec         => x_create_person_rec,
					     x_party_id           => x_person_party_id,
					     x_party_number       => x_person_party_number,
					     x_profile_id         => x_person_profile_id,
					     x_return_status      => x_return_status,
					     x_msg_count          => x_msg_count,
					     x_msg_data           => x_msg_data
					    );

		    IF (x_msg_count > 0 AND x_return_status <> 'S')
		    THEN
		       FOR j IN 1 .. x_msg_count
		       LOOP
			  fnd_msg_pub.get (j,
					   fnd_api.g_false,
					   x_msg_data,
					   x_msg_dummy
					  );
			  x_output :=
			       ('create_person:' || TO_CHAR (j) || ': ' || x_msg_data
			       );
			  x_error_flag := 'E';
		       --l_error_flag :='E';  --Set some WF variable

		       --RAISE;
		       END LOOP;

		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					x_output,
					itemtype,
					itemkey,
					'xx_jtf_create_user'
				       );
		       ROLLBACK TO create_contact_person;
		       wf_core.RAISE ('ERROR');
		    END IF;

		    fnd_msg_pub.delete_msg;
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       x_error_flag := 'E';
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					   'Error: While Person API was run'
					|| SUBSTR (SQLERRM, 1, 250),
					itemtype,
					itemkey,
					'xx_jtf_create_user'
				       );
		       RAISE;
		 --l_error_flag :='E';  --Set some WF variable
		 END;

		 /************************** Create Relationship *************************/
		 BEGIN
		    x_org_contact_id := NULL;
		    x_party_rel_id := NULL;
		    x_api_party_id := NULL;
		    x_api_party_number := NULL;
		    x_return_status := NULL;
		    x_msg_count := NULL;
		    x_msg_data := NULL;
		    x_org_contact_rec := NULL;
		    x_org_contact_rec.created_by_module := 'TCA_V1_API';
		    --l_org_contact_rec.party_site_id := l_party_site_id;--if passed
		    x_org_contact_rec.party_rel_rec.subject_id := x_person_party_id;
		    x_org_contact_rec.party_rel_rec.subject_type := 'PERSON';
		    x_org_contact_rec.party_rel_rec.subject_table_name :=
									 'HZ_PARTIES';
		    x_org_contact_rec.party_rel_rec.object_id := x_org_party_id;
		    x_org_contact_rec.party_rel_rec.object_type := 'ORGANIZATION';
		    x_org_contact_rec.party_rel_rec.object_table_name := 'HZ_PARTIES';
		    x_org_contact_rec.party_rel_rec.relationship_code := 'CONTACT_OF';
		    x_org_contact_rec.party_rel_rec.relationship_type := 'CONTACT';
		    x_org_contact_rec.party_rel_rec.start_date := SYSDATE;
		    hz_party_contact_v2pub.create_org_contact
					     (p_init_msg_list        => 'T',
					      p_org_contact_rec      => x_org_contact_rec,
					      x_org_contact_id       => x_org_contact_id,
					      x_party_rel_id         => x_party_rel_id,
					      x_party_id             => x_api_party_id,
					      x_party_number         => x_api_party_number,
					      x_return_status        => x_return_status,
					      x_msg_count            => x_msg_count,
					      x_msg_data             => x_msg_data
					     );

		    IF (x_msg_count > 0 AND x_return_status <> 'S')
		    THEN
		       FOR j IN 1 .. x_msg_count
		       LOOP
			  fnd_msg_pub.get (j,
					   fnd_api.g_false,
					   x_msg_data,
					   x_msg_dummy
					  );
			  x_output :=
			     ('create_org_contact:' || TO_CHAR (j) || ': '
			      || x_msg_data
			     );
			  x_error_flag := 'E';
		       --l_error_flag :='E';

		       -- RAISE;
		       END LOOP;

		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					x_output,
					itemtype,
					itemkey,
					'xx_jtf_create_user'
				       );
		       ROLLBACK TO create_contact_person;
		       wf_core.RAISE ('ERROR');
		    END IF;

		    fnd_msg_pub.delete_msg;
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       --l_error_flag :='E';
		       x_error_flag := 'E';
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					   'Error: While Relationship API was run'
					|| SUBSTR (SQLERRM, 1, 250),
					itemtype,
					itemkey,
					'xx_jtf_create_user'
				       );
		       RAISE;
		 END;

		 /********************* Cust Account Role *******************************/
		 BEGIN
		    x_return_status := NULL;
		    x_msg_count := NULL;
		    x_msg_data := NULL;
		    x_cust_account_role_rec := NULL;
		    x_cust_account_role_id := NULL;
		    x_cust_account_role_rec.created_by_module := 'TCA_V1_API';
		    x_cust_account_role_rec.party_id := x_api_party_id;
		    x_cust_account_role_rec.role_type := 'CONTACT';
		    --x_cust_account_role_rec.primary_flag := 'Y';
		    x_cust_account_role_rec.cust_account_id := x_cust_acct_id;
		    hz_cust_account_role_v2pub.create_cust_account_role
				 ('T',
				  p_cust_account_role_rec      => x_cust_account_role_rec,
				  x_cust_account_role_id       => x_cust_account_role_id,
				  x_return_status              => x_return_status,
				  x_msg_count                  => x_msg_count,
				  x_msg_data                   => x_msg_data
				 );

		    IF (x_msg_count > 0 AND x_return_status <> 'S')
		    THEN
		       FOR j IN 1 .. x_msg_count
		       LOOP
			  fnd_msg_pub.get (j,
					   fnd_api.g_false,
					   x_msg_data,
					   x_msg_dummy
					  );
			  x_output :=
			     (   'create_cust_account_role:'
			      || TO_CHAR (j)
			      || ': '
			      || x_msg_data
			     );
			  x_error_flag := 'E';
		       END LOOP;

		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					x_output,
					itemtype,
					itemkey,
					'xx_jtf_create_user'
				       );
		       ROLLBACK TO create_contact_person;
		       wf_core.RAISE ('ERROR');
		    END IF;
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       --l_error_flag :='E';
		       x_error_flag := 'E';
		       wf_core.CONTEXT
			     ('xx_jtf_user_reg_pkg',
				 'Error: While create_cust_account_role API was run'
			      || SUBSTR (SQLERRM, 1, 250),
			      itemtype,
			      itemkey,
			      'xx_jtf_create_user'
			     );
		       RAISE;
		 END;

		 BEGIN
		    x_contact_point_id := NULL;
		    x_return_status := NULL;
		    x_msg_count := NULL;
		    x_msg_data := NULL;
		    x_output := NULL;
		    x_contact_point_rec := NULL;
		    x_phone_rec := NULL;
		    x_email_rec := NULL;

		    IF x_email IS NOT NULL
		    THEN
		       x_contact_point_rec.contact_point_type := 'EMAIL';
		       x_email_rec.email_address := x_email;
		       -- no provision to send purpose, and status, primary
		       x_contact_point_rec.contact_point_purpose := 'BUSINESS';
		       x_contact_point_rec.owner_table_name := 'HZ_PARTIES';
		       x_contact_point_rec.owner_table_id := x_api_party_id;
		       x_contact_point_rec.primary_by_purpose := 'Y';
		       x_contact_point_rec.created_by_module := 'TCA_V1_API';
		       hz_contact_point_v2pub.create_email_contact_point
					 (p_init_msg_list          => 'T',
					  p_contact_point_rec      => x_contact_point_rec,
					  p_email_rec              => x_email_rec,
					  x_contact_point_id       => x_contact_point_id,
					  x_return_status          => x_return_status,
					  x_msg_count              => x_msg_count,
					  x_msg_data               => x_msg_data
					 );

		       IF (x_msg_count > 0 AND x_return_status <> 'S')
		       THEN
			  FOR j IN 1 .. x_msg_count
			  LOOP
			     fnd_msg_pub.get (j,
					      fnd_api.g_false,
					      x_msg_data,
					      x_msg_dummy
					     );
			     x_output :=
				       ('email:' || TO_CHAR (j) || ': ' || x_msg_data
				       );
			     x_error_flag := 'E';
			  END LOOP;

			  wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					   x_output,
					   itemtype,
					   itemkey,
					   'xx_jtf_create_user'
					  );
			  ROLLBACK TO create_contact_person;
			  wf_core.RAISE ('ERROR');
		       END IF;

		       fnd_msg_pub.delete_msg;
		    END IF;

		    x_contact_point_id := NULL;
		    x_return_status := NULL;
		    x_msg_count := NULL;
		    x_msg_data := NULL;
		    x_output := NULL;
		    x_contact_point_rec := NULL;
		    x_phone_rec := NULL;
		    x_email_rec := NULL;

		    IF x_biz_ph_number IS NOT NULL
		    THEN
		       x_contact_point_rec.contact_point_type := 'PHONE';
		       x_phone_rec.phone_area_code := x_biz_ph_area_code;
		       x_phone_rec.phone_country_code := x_biz_ph_country_code;
		       x_phone_rec.phone_number := x_biz_ph_number;
		       x_phone_rec.phone_extension := x_biz_ph_extn;
		       x_phone_rec.phone_line_type := 'GEN';
		       x_contact_point_rec.contact_point_purpose := 'BUSINESS';
		       x_contact_point_rec.owner_table_name := 'HZ_PARTIES';
		       x_contact_point_rec.owner_table_id := x_api_party_id;
		       --x_contact_point_rec.status := l_rec_cust_contacts.phone_status;
		       --x_contact_point_rec.primary_by_purpose := l_rec_cust_contacts.phone_primary;
		       x_contact_point_rec.created_by_module := 'TCA_V1_API';
		       hz_contact_point_v2pub.create_phone_contact_point
					 (p_init_msg_list          => 'T',
					  p_contact_point_rec      => x_contact_point_rec,
					  p_phone_rec              => x_phone_rec,
					  x_contact_point_id       => x_contact_point_id,
					  x_return_status          => x_return_status,
					  x_msg_count              => x_msg_count,
					  x_msg_data               => x_msg_data
					 );

		       IF (x_msg_count > 0 AND x_return_status <> 'S')
		       THEN
			  FOR j IN 1 .. x_msg_count
			  LOOP
			     fnd_msg_pub.get (j,
					      fnd_api.g_false,
					      x_msg_data,
					      x_msg_dummy
					     );
			     x_output :=
				  ('phone(fax):' || TO_CHAR (j) || ': ' || x_msg_data
				  );
			     x_error_flag := 'E';
			  END LOOP;

			  wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					   x_output,
					   itemtype,
					   itemkey,
					   'xx_jtf_create_user'
					  );
			  ROLLBACK TO create_contact_person;
			  wf_core.RAISE ('ERROR');
		       END IF;

		       fnd_msg_pub.delete_msg;
		    END IF;

		    x_contact_point_id := NULL;
		    x_return_status := NULL;
		    x_msg_count := NULL;
		    x_msg_data := NULL;
		    x_output := NULL;
		    x_contact_point_rec := NULL;
		    x_phone_rec := NULL;
		    x_email_rec := NULL;

		    IF x_per_ph_number IS NOT NULL
		    THEN
		       x_contact_point_rec.contact_point_type := 'PHONE';
		       x_phone_rec.phone_area_code := x_per_ph_area_code;
		       x_phone_rec.phone_country_code := x_per_ph_country_code;
		       x_phone_rec.phone_number := x_per_ph_number;
		       x_phone_rec.phone_extension := x_biz_ph_extn;
		       x_phone_rec.phone_line_type := 'GEN';
		       x_contact_point_rec.contact_point_purpose := 'PERSONAL';
		       x_contact_point_rec.owner_table_name := 'HZ_PARTIES';
		       x_contact_point_rec.owner_table_id := x_api_party_id;
		       --l_contact_point_rec.status := l_rec_cust_contacts.phone_status;
		       --l_contact_point_rec.primary_by_purpose := l_rec_cust_contacts.phone_primary;
		       x_contact_point_rec.created_by_module := 'TCA_V1_API';
		       hz_contact_point_v2pub.create_phone_contact_point
					 (p_init_msg_list          => 'T',
					  p_contact_point_rec      => x_contact_point_rec,
					  p_phone_rec              => x_phone_rec,
					  x_contact_point_id       => x_contact_point_id,
					  x_return_status          => x_return_status,
					  x_msg_count              => x_msg_count,
					  x_msg_data               => x_msg_data
					 );

		       IF (x_msg_count > 0 AND x_return_status <> 'S')
		       THEN
			  FOR j IN 1 .. x_msg_count
			  LOOP
			     fnd_msg_pub.get (j,
					      fnd_api.g_false,
					      x_msg_data,
					      x_msg_dummy
					     );
			     x_output :=
				       ('phone:' || TO_CHAR (j) || ': ' || x_msg_data
				       );
			     x_error_flag := 'E';
			  END LOOP;

			  wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					   x_output,
					   itemtype,
					   itemkey,
					   'xx_jtf_create_user'
					  );
			  ROLLBACK TO create_contact_person;
			  wf_core.RAISE ('ERROR');
		       END IF;

		       fnd_msg_pub.delete_msg;
		    END IF;
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       --l_error_flag :='E';
		       x_error_flag := 'E';
		       wf_core.CONTEXT
				 ('xx_jtf_user_reg_pkg',
				     'Error: While create contact point API was run'
				  || SUBSTR (SQLERRM, 1, 250),
				  itemtype,
				  itemkey,
				  'xx_jtf_create_user'
				 );
		       RAISE;
		 END;

		 COMMIT;

		 ----------------------------- End of contact Creation ------------------------------------

		 -- API to create User:
		 IF x_error_flag = 'S'
		 THEN
		    BEGIN
		       ibe_user_pvt.create_user
			  (p_user_name          => UPPER (x_email),
			   p_password           => UTL_RAW.cast_to_varchar2
						      (UTL_ENCODE.base64_decode
							  (UTL_RAW.cast_to_raw
									   (x_password)
							  )
						      ),
			   p_start_date         => SYSDATE,
			   p_end_date           => NULL,
			   p_password_date      => SYSDATE,
			   p_email_address      => x_email,
			   p_customer_id        => x_api_party_id,
								  --x_person_party_id,
			   x_user_id            => x_user_id
			  );
		    --commit;
		    EXCEPTION
		       WHEN OTHERS
		       THEN
			  x_error_flag := 'E';
			  wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					   SUBSTR (SQLERRM, 1, 200),
					   itemtype,
					   itemkey,
					   'xx_jtf_create_user'
					  );
			  RAISE;
		    END;

		    -- API to update User with correct start and End dates:  (Previous API inserts junk values in both date . This API will correct the same)
		    IF x_error_flag = 'S'
		    THEN
		       BEGIN
			  ibe_user_pvt.update_user (p_user_name         => UPPER
									      (x_email),
						    p_password          => NULL,
						    p_start_date        => SYSDATE,
						    p_end_date          => NULL,
						    p_old_password      => NULL,
						    p_party_id          => NULL
						   );
		       --In case of Error:
		       EXCEPTION
			  WHEN OTHERS
			  THEN
			     x_error_flag := 'E';
			     wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					      SUBSTR (SQLERRM, 1, 200),
					      itemtype,
					      itemkey,
					      'xx_jtf_create_user'
					     );
			     RAISE;
		       END;
		    END IF;

		    -- API to assign responsibility:
		    IF x_error_flag = 'S'
		    THEN
		       BEGIN
			  fnd_user_pkg.addresp
					     (username            => UPPER (x_email),
					      resp_app            => 'IBE',
					      resp_key            => 'INTG_IBE_MILTEX_CUSTOMER',
					      security_group      => 'STANDARD',
					      description         => 'Auto Assignment',
					      start_date          => SYSDATE,
					      end_date            => NULL
					     );
		       --In case of Error:
		       EXCEPTION
			  WHEN OTHERS
			  THEN
			     x_error_flag := 'E';
			     wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					      SUBSTR (SQLERRM, 1, 200),
					      itemtype,
					      itemkey,
					      'xx_jtf_create_user'
					     );
			     RAISE;
		       END;
		    END IF;

		    -- API to assign role to Istore User:
		    IF x_error_flag = 'S'
		    THEN
		       BEGIN
			  jtf_auth_bulkload_pkg.assign_role (UPPER (x_email),
							     'IBE_BUSINESS_USER_ROLE'
							    );
		       --In case of Error:
		       EXCEPTION
			  WHEN OTHERS
			  THEN
			     x_error_flag := 'E';
			     wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					      SUBSTR (SQLERRM, 1, 200),
					      itemtype,
					      itemkey,
					      'xx_jtf_create_user'
					     );
			     RAISE;
		       END;
		    END IF;
		 END IF;
	  --skipping user creation if contact/party creation failed or was rolled back

		 IF x_error_flag = 'E'
		 THEN
		    resultout := 'COMPLETE:N';
		 ELSE
		    resultout := 'COMPLETE:Y';
		 END IF;
	      END IF;
	   EXCEPTION
	      WHEN OTHERS
	      THEN
		 x_error_flag := 'E';
		 wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
				  SUBSTR (SQLERRM, 1, 200),
				  itemtype,
				  itemkey,
				  'xx_jtf_create_user'
				 );
		 RAISE;
	   END xx_jtf_create_user;

	-- =================================================================================
	-- Name           : cust_get_approver
	-- Description    : Procedure is used to get Next Approver in AME
	-- Parameters description       :
	--
	-- itemtype                    : Parameter To Store itemtype (IN)
	-- itemkey                     : Parameter To Store itemkey  (IN)
	-- actid                       : Parameter To Store actid    (IN)
	-- funcmode                    : Parameter To Store funcmode (IN)
	-- resultout                   : Parameter To Store resultout(IN OUT)
	-- ==============================================================================
	PROCEDURE cust_get_approver (
	      p_itemtype     IN              VARCHAR2,
	      p_itemkey      IN              VARCHAR2,
	      p_activityid   IN              NUMBER,
	      funmode        IN              VARCHAR2,
	      RESULT         OUT NOCOPY      VARCHAR2
	   )
	   AS
	      x_chr_item_key            VARCHAR2 (200);
	      x_chr_apprvl_out_put      VARCHAR2 (100);
	      x_next_approver           ame_util.approverstable2;
	      x_chr_approver_id         VARCHAR2 (10);
	      x_chr_appr_name           VARCHAR2 (50);
	      x_item_index              ame_util.idlist;
	      x_item_class              ame_util.stringlist;
	      x_item_id                 ame_util.stringlist;
	      x_item_source             ame_util.longstringlist;
	      x_seq_num                 VARCHAR2 (50);
	      x_user_name               VARCHAR2 (240);
	      x_body                    VARCHAR2 (4000);
	      x_ac_num                  VARCHAR2 (30);
	      x_ac_name                 VARCHAR2 (240);
	      x_first_name              VARCHAR2 (240);
	      x_last_name               VARCHAR2 (240);
	      x_email                   VARCHAR2 (2000);
	      x_business_number         VARCHAR2 (80);
	      x_personal_ph_number      VARCHAR2 (80);
	      x_comments                VARCHAR2 (2000);
	      x_msg_body                VARCHAR2(3000);
	      x_msg_sub                 VARCHAR2(1000);
	   BEGIN
	      g_num_err_loc_code := '00001';

	      IF funmode = 'RUN'
	      THEN
		 BEGIN
		    BEGIN
		       xx_intg_common_pkg.get_process_param_value( 'XXIBEAMEAPR'
								  ,'G_TRANSACTION_TYPE_NAME'
								  ,g_chr_transaction_type
								 );
		    EXCEPTION
		       WHEN OTHERS
		       THEN
			  wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					   SUBSTR (SQLERRM, 1, 200),
					   p_itemtype,
					   p_itemkey,
					   'cust_get_approver- Check TXN Type in Process Setup Parameter'
					  );
			  RAISE;
		    END;


		    x_seq_num :=
		       wf_engine.getitemattrnumber (itemtype      => p_itemtype,
						    itemkey       => p_itemkey,
						    aname         => 'XXIBE_SEQ_NUM'
						   );
		    x_user_name :=
		       wf_engine.getitemattrtext (itemtype      => p_itemtype,
						  itemkey       => p_itemkey,
						  aname         => 'USER_NAME'
						 );

		    BEGIN
		       SELECT account_number,
			      account_name,
			      first_name,
			      last_name,
			      email,
			      comments,
			      business_ph_country_code||business_ph_area_code||business_ph_number||decode(Business_ph_extn,NUll,NUll,'-'||Business_ph_extn),
			      personal_ph_country_code||personal_ph_area_code||personal_ph_number||decode(personal_ph_extn,NUll,NUll,'-'||personal_ph_extn)
			 INTO x_ac_num,
			      x_ac_name,
			      x_first_name,
			      x_last_name,
			      x_email,
			      x_comments,
			      x_business_number,
			      x_personal_ph_number
			 FROM xxjtf_user_reg_tbl
			WHERE seq_num = x_seq_num;
		    EXCEPTION
		       WHEN OTHERS
		       THEN
			  wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					   SUBSTR (SQLERRM, 1, 200),
					   p_itemtype,
					   p_itemkey,
					   'cust_get_approver'
					  );
			  RAISE;
		    END;

		    --
		    -- Getting next approver using AME_API2.GETNEXTAPPROVERS1 procedure
		    --
		    ame_api2.getnextapprovers1
		       (applicationidin                   => 671,
			transactiontypein                 => g_chr_transaction_type,
			transactionidin                   => x_seq_num,--unique ID that can be passed to AME
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
						     aname         => 'XX_JTF_APPROVER_LIST',
						     avalue        => x_chr_appr_name
						    );
			  /*wf_engine.setitemattrtext (p_itemtype,
						     p_itemkey,
						     'MAIL_SUB',
						     '	'
						    );
			  */
			  -----------------------------
			  BEGIN

			     x_msg_sub:=xx_intg_common_pkg.set_long_message('XX_IBE_APR_MSG_SUB');

			     x_msg_body :=xx_intg_common_pkg.set_long_message( 'XX_IBE_APR_MSG_BODY'
									       ,NVL(x_user_name,' ')
									      ,NVL(x_ac_num,' ')
									      ,NVL(x_ac_name,' ')
									      ,NVL(x_first_name,' ')
									      ,NVL(x_last_name, ' ')
									      ,NVL(x_email,' ')
									      ,NVL(x_business_number, ' ')
									      ,NVL(x_personal_ph_number,' ')
									      ,NVL(x_comments,' ')
									    );
			     wf_engine.setitemattrtext (itemtype      => p_itemtype,
							itemkey       => p_itemkey,
							aname         => 'XXIBE_MAIL_SUB',
							avalue        => x_msg_sub
						       );
			     wf_engine.setitemattrtext (itemtype      => p_itemtype,
							itemkey       => p_itemkey,
							aname         => 'XXIBE_MAIL_BODY',
							avalue        => x_msg_body
						       );


			  EXCEPTION
			     WHEN OTHERS
			     THEN
				wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
						 SUBSTR (SQLERRM, 1, 200),
						 p_itemtype,
						 p_itemkey,
						 'cust_get_approver'
						);
				RAISE;
			  END;
			  -----------------------------
			  BEGIN
			     UPDATE xxjtf_user_reg_tbl
				SET status = 'INPROGRESS'
			      WHERE seq_num = x_seq_num AND status IS NULL;

			     COMMIT;
			  EXCEPTION
			     WHEN OTHERS
			     THEN
				NULL;
			  END;

			  IF x_next_approver (1).approver_category = 'A'
			  THEN
			     RESULT := 'APPROVAL';
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
				  proc_name      => 'cust_get_approver',
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

	-- =================================================================================
	-- Name           : upd_appr_status
	-- Description    : Procedure is used to get Update Approval Status for AME Approver
	-- Parameters description       :
	--
	-- itemtype                    : Parameter To Store itemtype (IN)
	-- itemkey                     : Parameter To Store itemkey  (IN)
	-- actid                       : Parameter To Store actid    (IN)
	-- funcmode                    : Parameter To Store funcmode (IN)
	-- resultout                   : Parameter To Store resultout(IN OUT)
	-- ==============================================================================
	PROCEDURE upd_appr_status (
	      p_itemtype     IN              VARCHAR2,
	      p_itemkey      IN              VARCHAR2,
	      p_activityid   IN              NUMBER,
	      funmode        IN              VARCHAR2,
	      RESULT         OUT NOCOPY      VARCHAR2
	   )
	   AS
	      x_chr_approver_name   VARCHAR (100);
	      x_seq_num             VARCHAR2 (50);
	   BEGIN
	      IF funmode = 'RUN'
	      THEN
		 g_num_err_loc_code := '00002';
		 x_chr_approver_name :=
		    wf_engine.getitemattrtext (itemtype      => p_itemtype,
					       itemkey       => p_itemkey,
					       aname         => 'XX_JTF_APPROVER_LIST'
					      );
		 BEGIN
		    xx_intg_common_pkg.get_process_param_value( 'XXIBEAMEAPR'
							       ,'G_TRANSACTION_TYPE_NAME'
							       ,g_chr_transaction_type
							      );
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					p_itemtype,
					p_itemkey,
					'upd_appr_status- Check TXN Type in Process Setup Parameter'
				       );
		       RAISE;
		 END;
		 x_seq_num :=
		    wf_engine.getitemattrnumber (itemtype      => p_itemtype,
						 itemkey       => p_itemkey,
						 aname         => 'XXIBE_SEQ_NUM'
						);
		 ame_api2.updateapprovalstatus2
				(applicationidin        => 671,
				 transactiontypein      => g_chr_transaction_type,
				 transactionidin        => x_seq_num,
				 approvalstatusin       => ame_util.approvedstatus,
				 approvernamein         => x_chr_approver_name
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
				  proc_name      => 'upd_appr_status',
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

	-- =================================================================================
	-- Name           : upd_rejected_status
	-- Description    : Procedure is used to get Update Approval Reject Status for AME Approver
	-- Parameters description       :
	--
	-- itemtype                    : Parameter To Store itemtype (IN)
	-- itemkey                     : Parameter To Store itemkey  (IN)
	-- actid                       : Parameter To Store actid    (IN)
	-- funcmode                    : Parameter To Store funcmode (IN)
	-- resultout                   : Parameter To Store resultout(IN OUT)
	-- ==============================================================================
	PROCEDURE upd_rejected_status (
	      p_itemtype     IN              VARCHAR2,
	      p_itemkey      IN              VARCHAR2,
	      p_activityid   IN              NUMBER,
	      funmode        IN              VARCHAR2,
	      RESULT         OUT NOCOPY      VARCHAR2
	   )
	   AS
	      x_chr_approver_name   VARCHAR (100);
	      x_seq_num             VARCHAR2 (50);
	   BEGIN
	      IF funmode = 'RUN'
	      THEN
		 g_num_err_loc_code := '00003';
		 x_chr_approver_name :=
		    wf_engine.getitemattrtext (itemtype      => p_itemtype,
					       itemkey       => p_itemkey,
					       aname         => 'XX_JTF_APPROVER_LIST'
					      );
		 x_seq_num :=
		    wf_engine.getitemattrnumber (itemtype      => p_itemtype,
						 itemkey       => p_itemkey,
						 aname         => 'XXIBE_SEQ_NUM'
						);
		 BEGIN
		    xx_intg_common_pkg.get_process_param_value( 'XXIBEAMEAPR'
							       ,'G_TRANSACTION_TYPE_NAME'
							       ,g_chr_transaction_type
							      );
		 EXCEPTION
		    WHEN OTHERS
		    THEN
		       wf_core.CONTEXT ('xx_jtf_user_reg_pkg',
					SUBSTR (SQLERRM, 1, 200),
					p_itemtype,
					p_itemkey,
					'upd_rejected_status- Check TXN Type in Process Setup Parameter'
				       );
		       RAISE;
		 END;
		 ame_api2.updateapprovalstatus2
					 (applicationidin        => 671,
					  transactiontypein      => g_chr_transaction_type,
					  transactionidin        => x_seq_num,
					  approvalstatusin       => ame_util.rejectstatus,
					  approvernamein         => x_chr_approver_name
					 );
		 RESULT := 'Y';
		 ame_api2.clearallapprovals
					 (applicationidin        => 671,
					  transactiontypein      => g_chr_transaction_type,
					  transactionidin        => x_seq_num
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
	   END upd_rejected_status;
	--------------------------------------------------------------------------------------------------
	END xx_jtf_user_reg_pkg;
/
