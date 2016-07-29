DROP PACKAGE BODY APPS.XX_BOOKING_NEURO_RM_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_BOOKING_NEURO_RM_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : Ravi Vishnu
 Creation Date : 05-Nov-2014
 File Name     : XX_BOOKING_NEURO_RM_PKG
 Description   : This code is being written to get data  for recon Daily sales

 Change History:
 Date         Name                  Remarks
 ----------- -------------         -----------------------------------
 05-Nov-2014  Ravi Vishnu          Initial Version
*/
----------------------------------------------------------------------
   PROCEDURE main (p_division IN VARCHAR, p_from_date DATE, p_to_date DATE, p_dcode VARCHAR)
   IS
   l_dummy_mgr_email varchar2(200) := NULL;
   l_database        varchar2(200) := NULL;
   BEGIN
-------------------------------------
-- Insert into STage Table --
-------------------------------------

      DELETE FROM xxintg.xx_daily_booking_neuro_rm_tmp;

      DELETE FROM xxintg.xx_daily_booking_neuro_rm_main;

      COMMIT;

	  BEGIN
	  SELECT UPPER(name)
	    INTO l_database
	    FROM v$database;
	  EXCEPTION
	  WHEN OTHERS THEN
	  l_database := NULL;
	  fnd_file.put_line (
               fnd_file.LOG,
               'Unable to derive database name : '
               || SQLERRM
            );
	  END;

      INSERT INTO xxintg.xx_daily_booking_neuro_rm_tmp
      (SELECT   DISTINCT NVL (team.team_resource_id, res.resource_id),
         TRUNC (oha.booked_date) Booking_Date,
         TRUNC (oha.ordered_date) Ordered_Date,
         oha.order_number Order_No,
         ola.line_number,
         ott.name Order_Type,
         oha.cust_po_number "Customer PO Number",
         caa.account_number Ship_To_Customer_No,
		 ps.party_site_number ship_to_customer_site_no,
         csua.location Ship_To_Customer_Loc_No,
            p.party_name
         || ' '
         || l.city
         || ', '
         || l.state
         || ' '
         || l.postal_code
            Ship_To_Name,
         sib.segment1 Item_Part_No,
         sib.description Description,
         mc.segment4 Division,
         mc.segment9 DCODE,
         TO_NUMBER (DECODE (ola.line_category_code,
                            'ORDER',
                            ola.ordered_quantity,
                            'RETURN',
                            -1 * ola.ordered_quantity))
            Ordered_Qty,
         ola.unit_selling_price Unit_Selling_Price,
         TO_NUMBER (
            DECODE (ola.line_category_code,
                    'ORDER',
                    ola.unit_selling_price * ola.ordered_quantity,
                    'RETURN',
                    -1 * ola.unit_selling_price * ola.ordered_quantity)
         )
            Total_Sales_Dollars,
         NULL mgr_name,
		 NULL mgr_email,
         NVL (team.full_name, NVL (restl.RESOURCE_NAME, papf.full_name)) SalesRep_Name,
		 sa.RESOURCE_ID rep_resource_id,
		 jrb.manager_flag MANAGER_FLAG,
         osc.attribute1 Territory_Name,
         osc.attribute2 Territory_Code,
		 trunc(jrr.start_date_active) role_start_active_date,
         trunc(jrr.end_date_active) role_end_active_date,
         trunc(team.team_start_date),
         trunc(team.team_end_date),
         trunc(team.start_date_active) team_start_active_date,
         trunc(team.end_date_active) team_end_active_date
            FROM   jtf_rs_salesreps sa,
                   mtl_system_items_b sib,
                   hz_parties p,
                   hz_party_sites ps,
                   hz_cust_accounts_all caa,
                   hz_cust_acct_sites_all casa,
                   oe_order_headers_all oha,
                   oe_order_lines_all ola,
                   oe_transaction_types_tl ott,
                   apps.mtl_item_categories_v icv,
                   apps.mtl_categories_b mc,
                   hz_cust_site_uses_all csua,
                   hz_locations l,
                   per_all_people_f papf,
                   oe_sales_credits osc
                   ,JTF_RS_RESOURCE_EXTNS RES
                   ,JTF_RS_RESOURCE_EXTNS_TL RESTL
                   ,(SELECT DISTINCT team.team_id, team.team_resource_id,  papf.full_name, papf.person_id,papf.EMAIL_ADDRESS,
                          team.RESOURCE_TYPE,tres.team_resource_id trsid,ateam.TEAM_START_DATE,ateam.TEAM_END_DATE,REL.START_DATE_ACTIVE,REL.END_DATE_ACTIVE
                    from JTF_RS_TEAM_MEMBERS team, per_all_people_f papf, JTF_RS_TEAM_MEMBERS TRES, JTF_RS_DEFRESTEAMS_VL ATEAM
                        ,JTF_RS_ROLE_RELATIONS REL -- Added on 06-Aug-2014
                        where 1 = 1
                        and sysdate between papf.effective_start_date and papf.effective_end_date
                        and team.person_id = papf.person_id
                        and team.delete_flag = 'N'
                        and tres.delete_flag = 'N'
                        and team.team_id = tres.team_id
                        and team.TEAM_id = ATEAM.TEAM_id
                        AND team.team_resource_id = ATEAM.team_resource_id
                        --AND team.team_resource_id = tres.team_resource_id
                        --and trunc(sysdate) between trunc(ateam.TEAM_START_DATE) and nvl(trunc(ateam.TEAM_END_DATE), trunc(sysdate+1))
                        and sysdate between ateam.TEAM_START_DATE and nvl(ateam.TEAM_END_DATE, sysdate+1)
                        AND REL.ROLE_RESOURCE_ID = TEAM.TEAM_MEMBER_ID
                        AND NVL(REL.DELETE_FLAG, 'N') = 'N'
                        AND REL.ROLE_RESOURCE_TYPE = 'RS_TEAM_MEMBER'
                        ) team,
					 jtf_rs_role_relations jrr,
					 jtf_rs_roles_b jrb,
					 jtf_rs_roles_tl jrbt
           WHERE       1 = 1
--		           AND caa.party_id = p.party_id
                   AND p.party_id = ps.party_id
                   AND caa.cust_account_id = casa.cust_account_id
                   AND casa.party_site_id = ps.party_site_id
                   AND ola.inventory_item_id = sib.inventory_item_id
                   AND oha.header_id = ola.header_id
                   AND oha.booked_flag = 'Y'
                   AND csua.cust_acct_site_id = casa.cust_acct_site_id
                   AND nvl(casa.attribute3,'Domestic') = 'Domestic'
                   AND csua.site_use_code = 'SHIP_TO'
                   AND csua.site_use_id = oha.ship_to_org_id
                   AND sib.inventory_item_id = icv.inventory_item_id
                   AND sib.organization_id = icv.organization_id
                   AND icv.category_id = mc.category_id
                   AND sib.organization_id = ola.ship_from_org_id
                   AND icv.category_set_name = 'Sales and Marketing'
                   AND l.location_id = ps.location_id
                   AND sa.person_id = papf.person_id
                   AND TRUNC(SYSDATE) BETWEEN papf.effective_start_date
                                   AND  nvl(effective_end_date,TRUNC(SYSDATE))
                   AND oha.order_type_id = ott.TRANSACTION_TYPE_ID
                   AND sa.STATUS = 'A'
                   AND ott.language = 'US'
                  AND ola.line_id = osc.line_id(+)
                  AND osc.SALESREP_ID = sa.SALESREP_ID(+)
                  AND sa.person_id = papf.person_id(+)
                  AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date(+) AND  papf.effective_end_date(+)
                  AND sa.STATUS(+) = 'A'
                 AND sa.RESOURCE_ID = RES.RESOURCE_ID(+)
                 AND restl.language = USERENV ('LANG')
                 AND res.resource_id = restl.resource_id(+)
                 AND team.trsid(+) = RES.resource_id
--                   AND upper(mc.segment4) = 'RECON'
                   --AND oha.order_number = '87969'
--                   AND TRUNC (oha.booked_date) BETWEEN '04-MAY-2014' and TRUNC(SYSDATE)
                   AND UPPER (mc.segment4) = CASE WHEN UPPER(p_division) = 'INSTRUMENTS' THEN 'INSTR' ELSE UPPER (NVL (p_division, mc.segment4)) END
                   AND TRUNC (oha.booked_date) BETWEEN NVL (TO_DATE (p_from_date,'DD-MON-RRRR'),TRUNC (oha.booked_date))
                                                   AND  NVL (TO_DATE (p_to_date,'DD-MON-RRRR'),TRUNC (oha.booked_date))
--                   AND RES.RESOURCE_ID = NVL(:P_SALESREP, RES.RESOURCE_ID)
--				   AND UPPER (mc.segment4) = 'INSTR'
--                   AND TRUNC (oha.booked_date) BETWEEN '01-OCT-2014' AND '01-OCT-2014'
                   AND jrr.role_id = jrb.role_id
				   AND jrb.role_id = jrbt.role_id
				   AND jrbt.language = 'US'
				   AND jrr.role_resource_id = NVL (team.trsid, NVL (restl.resource_id, papf.person_id)) --100022102
				   AND jrb.role_type_code like 'SALES_COMP'
				   AND UPPER(jrbt.role_name) NOT LIKE '%SPINE%'	 		--Added By Ravi Vishnu to exclude SPINE Dealers
				   and nvl(sib.attribute1, 'Y') = 'Y'                     -- Added to have commisionable items only for NEURO
			--	   AND jrb.manager_flag <> 'Y'  --Exclude Manager
                   AND upper(ott.name) in ('ILS BILL ONLY ORDER',
                                            'ILS CHARGE SHEET ORDER',
                                            'ILS STANDARD ORDER',
                                            'ILS RETURN ORDER',
                           --                 'ILS SAMPLE ORDER',                     --Commented By Ravi Vishnu on 08-AUG-14 to exclude Sample Orders
                                            'ILS CREDIT ONLY ORDER')
											);

         COMMIT;


        IF l_database = 'PROD' THEN

		 UPDATE xxintg.xx_daily_booking_neuro_rm_tmp x
         set mgr_name = NVL((SELECT   DISTINCT relmem.resource_name
                    FROM   jtf_rs_resource_extns res1,
                           jtf_rs_defresgroups_vl resgp,
                           jtf_rs_groups_vl grp,
                           jtf_rs_group_members_vl grpmem,
                           jtf_rs_grp_relations_vl rel,
                           jtf_rs_group_members_vl relmem,
                           jtf_rs_defresroles_vl role,
                           jtf_rs_group_mbr_role_vl group_role,
                           jtf_rs_resource_extns resemail,
                           jtf_rs_salesreps sa
                   WHERE   1 = 1
                         --  AND res1.resource_id = x.resource_id  --100023136--
                           AND res1.resource_id=relmem.resource_id
                           AND sa.resource_id = resemail.resource_id
                           AND sa.status = 'A'
                           AND resgp.resource_id = x.resource_id--res1.resource_id
                           AND resgp.GROUP_ID = grp.GROUP_ID
                           AND grp.GROUP_ID = grpmem.GROUP_ID
                           AND grpmem.GROUP_ID = rel.GROUP_ID
                           AND rel.related_group_id = relmem.GROUP_ID
                           AND relmem.delete_flag = 'N'
                           and rel.delete_flag='N'
                           AND relmem.GROUP_MEMBER_ID = role.ROLE_RESOURCE_ID
                           AND role.manager_flag = 'Y'
                           AND relmem.resource_id = resemail.resource_id
                           AND x.resource_id = group_role.RESOURCE_ID
                           AND grpmem.group_member_id = group_role.group_member_id
                           and  (x.booking_date) between trunc(RES1.START_DATE_ACTIVE) AND NVL(TRUNC(RES1.END_DATE_ACTIVE), SYSDATE+1)
                           AND  (x.booking_date) BETWEEN TRUNC(group_role.START_DATE_ACTIVE) AND  NVL (TRUNC(group_role.END_DATE_ACTIVE),SYSDATE + 1)
                           AND  (x.booking_date) BETWEEN TRUNC(role.RES_RL_START_DATE) AND  NVL (TRUNC(role.RES_RL_END_DATE),SYSDATE + 1)
                           AND  (x.booking_date) BETWEEN TRUNC(resgp.GROUP_START_DATE) AND  NVL (TRUNC(resgp.GROUP_END_DATE),SYSDATE + 1)
                           AND rownum = 1), (SELECT   DISTINCT relmem.resource_name
                    FROM   jtf_rs_resource_extns res1,
                           jtf_rs_defresgroups_vl resgp,
                           jtf_rs_groups_vl grp,
                           jtf_rs_group_members_vl grpmem,
                           jtf_rs_grp_relations_vl rel,
                           jtf_rs_group_members_vl relmem,
                           jtf_rs_defresroles_vl role,
                           jtf_rs_group_mbr_role_vl group_role,
                           jtf_rs_resource_extns resemail,
                           jtf_rs_salesreps sa
                   WHERE   1 = 1
                        --   AND res1.resource_id = x.resource_id  --100023136--
                           AND res1.resource_id=relmem.resource_id
                           AND sa.resource_id = resemail.resource_id
                           AND sa.status = 'A'
                           AND resgp.resource_id = x.resource_id--res1.resource_id
                           AND resgp.GROUP_ID = grp.GROUP_ID
                           AND grp.GROUP_ID = grpmem.GROUP_ID
                           AND grpmem.GROUP_ID = rel.GROUP_ID
                           AND rel.related_group_id = relmem.GROUP_ID
                           AND relmem.delete_flag = 'N'
                           and rel.delete_flag='N'
                           AND relmem.GROUP_MEMBER_ID = role.ROLE_RESOURCE_ID
                           AND role.manager_flag = 'Y'
                           AND relmem.resource_id = resemail.resource_id
                           AND x.resource_id = group_role.RESOURCE_ID
                           AND grpmem.group_member_id = group_role.group_member_id
                           and  TRUNC(SYSDATE) between trunc(RES1.START_DATE_ACTIVE) AND NVL(TRUNC(RES1.END_DATE_ACTIVE), SYSDATE+1)
                           --AND  TRUNC(SYSDATE) BETWEEN TRUNC(group_role.START_DATE_ACTIVE) AND  NVL (TRUNC(group_role.END_DATE_ACTIVE),SYSDATE + 1)
                           AND  TRUNC(SYSDATE) BETWEEN TRUNC(role.RES_RL_START_DATE) AND  NVL (TRUNC(role.RES_RL_END_DATE),SYSDATE + 1)
                           AND  TRUNC(SYSDATE) BETWEEN TRUNC(resgp.GROUP_START_DATE) AND  NVL (TRUNC(resgp.GROUP_END_DATE),SYSDATE + 1)
                           AND rownum = 1)),
	            mgr_email = NVL((SELECT DISTINCT NVL (sa.email_address, resemail.source_email)
                    FROM   jtf_rs_resource_extns res1,
                           jtf_rs_defresgroups_vl resgp,
                           jtf_rs_groups_vl grp,
                           jtf_rs_group_members_vl grpmem,
                           jtf_rs_grp_relations_vl rel,
                           jtf_rs_group_members_vl relmem,
                           jtf_rs_defresroles_vl role,
                           jtf_rs_group_mbr_role_vl group_role,
                           jtf_rs_resource_extns resemail,
                           jtf_rs_salesreps sa
                   WHERE   1 = 1
                           AND res1.resource_id=relmem.resource_id
                           AND sa.resource_id = resemail.resource_id
                           AND sa.status = 'A'
                           AND resgp.resource_id = x.resource_id--res1.resource_id
                           AND resgp.GROUP_ID = grp.GROUP_ID
                           AND grp.GROUP_ID = grpmem.GROUP_ID
                           AND grpmem.GROUP_ID = rel.GROUP_ID
                           AND rel.related_group_id = relmem.GROUP_ID
                           AND relmem.delete_flag = 'N'
                           and rel.delete_flag='N'
                           AND relmem.GROUP_MEMBER_ID = role.ROLE_RESOURCE_ID
                           AND role.manager_flag = 'Y'
                           AND relmem.resource_id = resemail.resource_id
                           AND x.resource_id = group_role.RESOURCE_ID
                           AND grpmem.group_member_id = group_role.group_member_id
                           and  (x.booking_date) between trunc(RES1.START_DATE_ACTIVE) AND NVL(TRUNC(RES1.END_DATE_ACTIVE), SYSDATE+1)
                           AND  (x.booking_date) BETWEEN TRUNC(group_role.START_DATE_ACTIVE) AND  NVL (TRUNC(group_role.END_DATE_ACTIVE),SYSDATE + 1)
                           AND  (x.booking_date) BETWEEN TRUNC(role.RES_RL_START_DATE) AND  NVL (TRUNC(role.RES_RL_END_DATE),SYSDATE + 1)
                           AND  (x.booking_date) BETWEEN TRUNC(resgp.GROUP_START_DATE) AND  NVL (TRUNC(resgp.GROUP_END_DATE),SYSDATE + 1)
                           AND rownum = 1), (SELECT   DISTINCT NVL (sa.email_address, resemail.source_email)
                    FROM   jtf_rs_resource_extns res1,
                           jtf_rs_defresgroups_vl resgp,
                           jtf_rs_groups_vl grp,
                           jtf_rs_group_members_vl grpmem,
                           jtf_rs_grp_relations_vl rel,
                           jtf_rs_group_members_vl relmem,
                           jtf_rs_defresroles_vl role,
                           jtf_rs_group_mbr_role_vl group_role,
                           jtf_rs_resource_extns resemail,
                           jtf_rs_salesreps sa
                   WHERE   1 = 1
                           AND res1.resource_id=relmem.resource_id
                           AND sa.resource_id = resemail.resource_id
                           AND sa.status = 'A'
                           AND resgp.resource_id = x.resource_id--res1.resource_id
                           AND resgp.GROUP_ID = grp.GROUP_ID
                           AND grp.GROUP_ID = grpmem.GROUP_ID
                           AND grpmem.GROUP_ID = rel.GROUP_ID
                           AND rel.related_group_id = relmem.GROUP_ID
                           AND relmem.delete_flag = 'N'
                           and rel.delete_flag='N'
                           AND relmem.GROUP_MEMBER_ID = role.ROLE_RESOURCE_ID
                           AND role.manager_flag = 'Y'
                           AND relmem.resource_id = resemail.resource_id
                           AND x.resource_id = group_role.RESOURCE_ID
                           AND grpmem.group_member_id = group_role.group_member_id
                           and  TRUNC(SYSDATE) between trunc(RES1.START_DATE_ACTIVE) AND NVL(TRUNC(RES1.END_DATE_ACTIVE), SYSDATE+1)
                           --AND  TRUNC(SYSDATE) BETWEEN TRUNC(group_role.START_DATE_ACTIVE) AND  NVL (TRUNC(group_role.END_DATE_ACTIVE),SYSDATE + 1)
                           AND  TRUNC(SYSDATE) BETWEEN TRUNC(role.RES_RL_START_DATE) AND  NVL (TRUNC(role.RES_RL_END_DATE),SYSDATE + 1)
                           AND  TRUNC(SYSDATE) BETWEEN TRUNC(resgp.GROUP_START_DATE) AND  NVL (TRUNC(resgp.GROUP_END_DATE),SYSDATE + 1)
                           AND rownum = 1));
			    ELSE

					   BEGIN
					   l_dummy_mgr_email := NULL;

				       SELECT c.parameter_value
                         INTO l_dummy_mgr_email
						 FROM FND_SVC_COMP_PARAM_VALS c,
                              FND_SVC_COMPONENTS a,
                              FND_SVC_COMP_PARAMS_B b
                        WHERE a.COMPONENT_ID = c.COMPONENT_ID
                          AND b.PARAMETER_ID = c.PARAMETER_ID
                          AND a.COMPONENT_NAME LIKE 'Workflow Notification Mailer'
                          AND b.parameter_name = 'TEST_ADDRESS';
				        EXCEPTION
						WHEN OTHERS THEN
						l_dummy_mgr_email := NULL;
						END;

				UPDATE xxintg.xx_daily_booking_neuro_rm_tmp x
					      set mgr_name = NVL((SELECT   DISTINCT relmem.resource_name
                    FROM   jtf_rs_resource_extns res1,
                           jtf_rs_defresgroups_vl resgp,
                           jtf_rs_groups_vl grp,
                           jtf_rs_group_members_vl grpmem,
                           jtf_rs_grp_relations_vl rel,
                           jtf_rs_group_members_vl relmem,
                           jtf_rs_defresroles_vl role,
                           jtf_rs_group_mbr_role_vl group_role,
                           jtf_rs_resource_extns resemail,
                           jtf_rs_salesreps sa
                   WHERE   1 = 1
                         --  AND res1.resource_id = x.resource_id  --100023136--
                           AND res1.resource_id=relmem.resource_id
                           AND sa.resource_id = resemail.resource_id
                           AND sa.status = 'A'
                           AND resgp.resource_id = x.resource_id--res1.resource_id
                           AND resgp.GROUP_ID = grp.GROUP_ID
                           AND grp.GROUP_ID = grpmem.GROUP_ID
                           AND grpmem.GROUP_ID = rel.GROUP_ID
                           AND rel.related_group_id = relmem.GROUP_ID
                           AND relmem.delete_flag = 'N'
                           and rel.delete_flag='N'
                           AND relmem.GROUP_MEMBER_ID = role.ROLE_RESOURCE_ID
                           AND role.manager_flag = 'Y'
                           AND relmem.resource_id = resemail.resource_id
                           AND x.resource_id = group_role.RESOURCE_ID
                           AND grpmem.group_member_id = group_role.group_member_id
                           and  (x.booking_date) between trunc(RES1.START_DATE_ACTIVE) AND NVL(TRUNC(RES1.END_DATE_ACTIVE), SYSDATE+1)
                           AND  (x.booking_date) BETWEEN TRUNC(group_role.START_DATE_ACTIVE) AND  NVL (TRUNC(group_role.END_DATE_ACTIVE),SYSDATE + 1)
                           AND  (x.booking_date) BETWEEN TRUNC(role.RES_RL_START_DATE) AND  NVL (TRUNC(role.RES_RL_END_DATE),SYSDATE + 1)
                           AND  (x.booking_date) BETWEEN TRUNC(resgp.GROUP_START_DATE) AND  NVL (TRUNC(resgp.GROUP_END_DATE),SYSDATE + 1)
                           AND rownum = 1), (SELECT   DISTINCT relmem.resource_name
                    FROM   jtf_rs_resource_extns res1,
                           jtf_rs_defresgroups_vl resgp,
                           jtf_rs_groups_vl grp,
                           jtf_rs_group_members_vl grpmem,
                           jtf_rs_grp_relations_vl rel,
                           jtf_rs_group_members_vl relmem,
                           jtf_rs_defresroles_vl role,
                           jtf_rs_group_mbr_role_vl group_role,
                           jtf_rs_resource_extns resemail,
                           jtf_rs_salesreps sa
                   WHERE   1 = 1
                        --   AND res1.resource_id = x.resource_id  --100023136--
                           AND res1.resource_id=relmem.resource_id
                           AND sa.resource_id = resemail.resource_id
                           AND sa.status = 'A'
                           AND resgp.resource_id = x.resource_id--res1.resource_id
                           AND resgp.GROUP_ID = grp.GROUP_ID
                           AND grp.GROUP_ID = grpmem.GROUP_ID
                           AND grpmem.GROUP_ID = rel.GROUP_ID
                           AND rel.related_group_id = relmem.GROUP_ID
                           AND relmem.delete_flag = 'N'
                           and rel.delete_flag='N'
                           AND relmem.GROUP_MEMBER_ID = role.ROLE_RESOURCE_ID
                           AND role.manager_flag = 'Y'
                           AND relmem.resource_id = resemail.resource_id
                           AND x.resource_id = group_role.RESOURCE_ID
                           AND grpmem.group_member_id = group_role.group_member_id
                           and  TRUNC(SYSDATE) between trunc(RES1.START_DATE_ACTIVE) AND NVL(TRUNC(RES1.END_DATE_ACTIVE), SYSDATE+1)
                           --AND  TRUNC(SYSDATE) BETWEEN TRUNC(group_role.START_DATE_ACTIVE) AND  NVL (TRUNC(group_role.END_DATE_ACTIVE),SYSDATE + 1)
                           AND  TRUNC(SYSDATE) BETWEEN TRUNC(role.RES_RL_START_DATE) AND  NVL (TRUNC(role.RES_RL_END_DATE),SYSDATE + 1)
                           AND  TRUNC(SYSDATE) BETWEEN TRUNC(resgp.GROUP_START_DATE) AND  NVL (TRUNC(resgp.GROUP_END_DATE),SYSDATE + 1)
                           AND rownum = 1) ),
	            mgr_email = l_dummy_mgr_email;

	    END IF;

        COMMIT;

        INSERT INTO xxintg.xx_daily_booking_neuro_rm_main
        SELECT * FROM xxintg.xx_daily_booking_neuro_rm_tmp x
                WHERE 1=1
		          AND resource_id = rep_resource_id
                  AND x.booking_date BETWEEN  NVL(x.role_start_active_date,x.booking_date) AND NVL(x.role_end_active_date,x.booking_date)
				  --Added By Ravi Vishnu to have only commisionable items shown on the report
				  AND EXISTS (SELECT 1
							    FROM apps.XXINTG_COMMISSION_DCODES_V comm
							   WHERE 1 = 1
							     AND comm.rev_name = 'NEURO'
							     AND comm.user_type_name = 'Product Type'
							     AND x.dcode BETWEEN comm.low_value AND comm.high_value)
	    UNION
        SELECT * FROM xxintg.xx_daily_booking_neuro_rm_tmp x
		WHERE 1=1
	          and resource_id!=rep_resource_id
	          AND (x.booking_date between  nvl(x.team_start_active_date,x.booking_date) and nvl(x.team_end_active_date,x.booking_date)
                  AND x.booking_date between  nvl(x.team_start_date,x.booking_date) and nvl(x.team_end_date,x.booking_date) ) -- added or logic on 26-Aug-2014 by balaji
                  AND x.booking_date between  nvl(x.role_start_active_date,x.booking_date) and nvl(x.role_end_active_date,x.booking_date)
                                    --AND UPPER(Customer_type) <> 'DISTRIBUTOR'
                  AND (x.resource_id in (SELECT   res.resource_id
                                                           FROM   jtf_rs_teams_tl tm,
                                                                  jtf_rs_team_usages ua,
                                                                  jtf_rs_team_members mm,
                                                                  jtf_rs_role_relations rel,
                                                                  jtf_rs_roles_b rol,
                                                                  jtf_rs_resource_extns res,
                                                                  jtf_objects_tl obj
                                                          WHERE       MM.RESOURCE_TYPE = 'INDIVIDUAL'
                                                                  AND UA.TEAM_ID = TM.TEAM_ID
                                                                  AND UA.USAGE = 'SALES_COMP'
                                                                  AND TM.TEAM_ID = MM.TEAM_ID
                                                                  AND TM.LANGUAGE = USERENV ('LANG')
                                                                  AND MM.DELETE_FLAG <> 'Y'
                                                                  AND REL.ROLE_RESOURCE_ID = MM.TEAM_MEMBER_ID
                                                                  AND REL.DELETE_FLAG <> 'Y'
                                                                  AND REL.ROLE_RESOURCE_TYPE = 'RS_TEAM_MEMBER'
                                                                  AND REL.ROLE_ID = ROL.ROLE_ID
                                                                  AND MM.TEAM_RESOURCE_ID = RES.RESOURCE_ID
                                                                  AND OBJ.OBJECT_CODE = RES.CATEGORY
                                                                  AND OBJ.LANGUAGE = USERENV ('LANG')
                                                                  AND ROL.MEMBER_FLAG = 'Y'
                                                                  AND TRUNC (x.booking_date) BETWEEN TRUNC(REL.START_DATE_ACTIVE)AND  NVL (TRUNC(REL.END_DATE_ACTIVE),TRUNC(SYSDATE+1))
                                                                  AND ROL.ROLE_TYPE_CODE IN ('SALES_COMP')
                                                                  AND RES.CATEGORY IN ('EMPLOYEE', 'PARTNER')
                                                                  AND RES.SOURCE_NAME IS NOT NULL
                                                                  )
                                                  OR x.resource_id IN (SELECT   group_mem.resource_id
                                                                         FROM   jtf_rs_group_members_vl group_mem,
                                                                                jtf_rs_group_mbr_role_vl group_rol
                                                                        WHERE   1 = 1
                                                                                AND group_mem.GROUP_ID = group_rol.GROUP_ID
                                                                                AND group_mem.group_member_id =
                                                                                      group_rol.group_member_id
                                                                                AND group_mem.resource_id =
                                                                                      group_rol.RESOURCE_ID
                                                                                AND (x.booking_date) BETWEEN TRUNC(START_DATE_ACTIVE) AND  NVL (TRUNC(END_DATE_ACTIVE),TRUNC(SYSDATE+1))
                                                                       )
                                                 )
		 /*       and resource_id  not in
			        (select distinct rep_resource_id
				   from xxintg.xx_daily_booking_neuro_rm_tmp x
                                  where resource_id = rep_resource_id
                                    and (x.booking_date >=  x.team_end_active_date or x.booking_date >=  x.team_end_date)) */
				and exists
                     (select 1
                   from xxintg.xx_daily_booking_neuro_rm_tmp y
                  where resource_id = rep_resource_id
					and TO_DATE(y.booking_date) BETWEEN TO_DATE(y.team_start_active_date) AND NVL(TO_DATE(y.team_end_active_date),TO_DATE(SYSDATE))
                    and TO_DATE(y.booking_date) BETWEEN TO_DATE(y.team_start_date) AND NVL(TO_DATE(y.team_end_date),TO_DATE(SYSDATE))
                    AND y.order_no = x.order_no
--                    AND invoice_no = '23258835'
						)
				--Added By Ravi Vishnu to have only commisionable items shown on the report
				  AND EXISTS (SELECT 1
							    FROM apps.XXINTG_COMMISSION_DCODES_V comm
							   WHERE 1 = 1
							     AND comm.rev_name = 'NEURO'
							     AND comm.user_type_name = 'Product Type'
							     AND x.dcode BETWEEN comm.low_value AND comm.high_value)
                order by order_no, line_number;


      COMMIT;
   END main;
END XX_BOOKING_NEURO_RM_PKG;
/
