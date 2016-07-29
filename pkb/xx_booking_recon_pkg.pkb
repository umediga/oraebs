DROP PACKAGE BODY APPS.XX_BOOKING_RECON_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_BOOKING_RECON_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : Ravi Vishnu
 Creation Date : 04-Dec-2014
 File Name     : xx_booking_recon_pkg
 Description   : This code is being written to get data  for Recon Daily sales Booking

 Change History:
 Date         Name                  Remarks
 ----------- -------------         -----------------------------------
 04-Dec-2014  Ravi Vishnu          Initial Version
*/
----------------------------------------------------------------------
   PROCEDURE main (p_division IN VARCHAR, p_from_date DATE, p_to_date DATE, p_dcode VARCHAR, p_salesrep IN VARCHAR)
   IS
   l_dummy_mgr_email varchar2(200) := NULL;
   l_database        varchar2(200) := NULL;
   BEGIN
-------------------------------------
-- Insert into STage Table --
-------------------------------------

      DELETE FROM xxintg.xx_daily_booking_recon_tmp;

      DELETE FROM xxintg.xx_daily_booking_recon_main;

      COMMIT;

	  	  BEGIN
	  SELECT UPPER(name)
	    INTO l_database
	    FROM v$database;
	  EXCEPTION
	  WHEN OTHERS THEN
	  l_database := NULL;
	  fnd_file.put_line (fnd_file.LOG,'Unable to derive database name : '|| SQLERRM);
	  END;


      INSERT INTO xxintg.xx_daily_booking_recon_tmp
      (SELECT /* index(hz_cust_site_uses_all HZ_CUST_SITE_USES_U1) index(RES JTF_RS_RESOURCE_EXTNS_U1) */
      DISTINCT nvl (team.team_resource_id, res.resource_id) resource_id,
       ORDER_DETAILS.ordered_date,
--       ORDER_DETAILS.booked_date BOOKING_DATE,								-- Commented By Ravi Vishnu on 24-DEC-2014 to handle NULL Booked Date Orders
       NVL(ORDER_DETAILS.booked_date, ORDER_DETAILS.ordered_date) BOOKING_DATE,	-- Added By Ravi Vishnu on 24-DEC-2014 to handle NULL Booked Date Orders
       ORDER_DETAILS.order_number Order_No,
       ORDER_DETAILS.line_number,
       ORDER_DETAILS.Order_Type,
       ORDER_DETAILS.cust_po_number "Customer PO Number",
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
       ORDER_DETAILS.Item_Part_No,
       ORDER_DETAILS.Description,
       ORDER_DETAILS.Division,
       ORDER_DETAILS.DCODE,
       TO_NUMBER (DECODE (ORDER_DETAILS.line_category_code,
                            'ORDER',
                            ORDER_DETAILS.ordered_quantity,
                            'RETURN',
                            -1 * ORDER_DETAILS.ordered_quantity))
            Ordered_Qty,
         ORDER_DETAILS.unit_selling_price Unit_Selling_Price,
         TO_NUMBER (
            DECODE (ORDER_DETAILS.line_category_code,
                    'ORDER',
                    ORDER_DETAILS.unit_selling_price * ORDER_DETAILS.ordered_quantity,
                    'RETURN',
                    -1 * ORDER_DETAILS.unit_selling_price * ORDER_DETAILS.ordered_quantity)
         )
            Total_Sales_Dollars,
		 NULL MGR_NAME,
		 NULL MGR_EMAIL,
         SA.RESOURCE_ID REP_RESOURCE_ID,
         NVL (team.full_name, NVL (restl.RESOURCE_NAME, papf.full_name))
            SalesRep_Name,
--         NVL (team.email_address, NVL (sa.email_address,res.source_email))  SalesRep_Email, --Commented By Ravi Vishnu on 30-JUL-14 to avoid sending mails to other than PROD
         CASE WHEN ((SELECT name FROM v$database) = 'PROD')
               THEN NVL (team.email_address, NVL (sa.email_address,res.source_email))
               ELSE (  SELECT c.parameter_value
                         FROM FND_SVC_COMP_PARAM_VALS c,
                              FND_SVC_COMPONENTS a,
                              FND_SVC_COMP_PARAMS_B b
                        WHERE a.COMPONENT_ID = c.COMPONENT_ID
                          AND b.PARAMETER_ID = c.PARAMETER_ID
                          AND a.COMPONENT_NAME LIKE 'Workflow Notification Mailer'
                          AND b.parameter_name = 'TEST_ADDRESS')
        END     SalesRep_Email,                                                                --Added By Ravi Vishnu on 30-JUL-14 to avoid sending mails to other than PROD
            jrb.manager_flag MANAGER_FLAG,
            osc.attribute1 Territory_Name,
            osc.attribute2 Territory_Code,
           trunc(jrr.start_date_active) role_start_active_date,
           trunc(jrr.end_date_active) role_end_active_date,
           trunc(team.team_start_date),
           trunc(team.team_end_date),
           trunc(team.start_date_active) team_start_active_date,
           trunc(team.end_date_active) team_end_active_date
FROM
(select TRUNC (oha.booked_date) booked_date,
       oha.order_number,
       oha.header_id HEADER_ID,
       oha.org_id,
       TRUNC (oha.ordered_date) ordered_date,
       oha.cust_po_number,
       oha.ship_to_org_id,
       oha.order_type_id,
       ola.line_number,
       ola.line_category_code,
       ola.ordered_quantity,
       ola.unit_selling_price,
       ola.inventory_item_id,
       ola.ship_from_org_id,
       ola.line_id,
       oha.sold_to_org_id,
       sib.segment1 Item_Part_No,
       sib.description Description,
       sib.organization_id,
       ott.name Order_Type,
       mc.segment4 Division,
       mc.segment9 DCODE
  from oe_order_headers_all oha,
       oe_order_lines_all ola,
       mtl_system_items_b sib ,
       oe_transaction_types_tl ott,
       apps.mtl_item_categories_v icv,
       apps.mtl_categories_b mc
 where 1 = 1
   and oha.header_id = ola.header_id
   and oha.org_id = ola.org_id
--   AND UPPER (mc.segment4) = 'RECON'
--   and trunc(oha.booked_date) between '01-JUL-2014' and '01-JUL-2014'
   AND UPPER (mc.segment4) = CASE WHEN UPPER(p_division) = 'INSTRUMENTS' THEN 'INSTR' ELSE UPPER (NVL (p_division, mc.segment4)) END
   AND TRUNC (oha.booked_date) BETWEEN (p_from_date) AND (p_to_date)
   AND oha.booked_flag = 'Y'
   AND ola.inventory_item_id = sib.inventory_item_id
   AND sib.organization_id = ola.ship_from_org_id
   AND oha.order_type_id = ott.TRANSACTION_TYPE_ID
   AND ott.language = 'US'
--   and oha.order_number = '183560'
   AND sib.inventory_item_id = icv.inventory_item_id
   AND sib.organization_id = icv.organization_id
   AND icv.category_id = mc.category_id
   AND icv.category_set_name = 'Sales and Marketing'
   AND upper(ott.name) in ('ILS BILL ONLY ORDER',
                                            'ILS CHARGE SHEET ORDER',
                                            'ILS STANDARD ORDER',
                                            'ILS RETURN ORDER',
                                            --'ILS SAMPLE ORDER',
                                            'ILS CREDIT ONLY ORDER')
) ORDER_DETAILS,
hz_cust_accounts_all caa,
hz_parties p,
hz_cust_acct_sites_all casa,
hz_party_sites ps,
hz_cust_site_uses_all csua,
hz_locations l,
jtf_rs_salesreps sa,
oe_sales_credits osc,
per_all_people_f papf,
JTF_RS_RESOURCE_EXTNS RES,
JTF_RS_RESOURCE_EXTNS_TL RESTL,
(SELECT DISTINCT team.team_id, team.team_resource_id,  papf.full_name, papf.person_id,papf.EMAIL_ADDRESS,
                                team.RESOURCE_TYPE,tres.team_resource_id trsid,ateam.TEAM_START_DATE,ateam.TEAM_END_DATE,REL.START_DATE_ACTIVE,REL.END_DATE_ACTIVE
                        from JTF_RS_TEAM_MEMBERS team, per_all_people_f papf, JTF_RS_TEAM_MEMBERS TRES, JTF_RS_DEFRESTEAMS_VL ATEAM
                        ,JTF_RS_ROLE_RELATIONS REL -- Added on 06-Aug-2014
                        where 1 = 1
                        and trunc(sysdate) between trunc(papf.effective_start_date) and trunc(papf.effective_end_date)
                        and team.person_id = papf.person_id
                        and team.delete_flag = 'N'
                        and tres.delete_flag = 'N'
                        and team.team_id = tres.team_id
                        and team.TEAM_id = ATEAM.TEAM_id
                        AND team.team_resource_id = ATEAM.team_resource_id
                        --AND team.team_resource_id = tres.team_resource_id
                        --and trunc(sysdate) between trunc(ateam.TEAM_START_DATE) and nvl(trunc(ateam.TEAM_END_DATE), trunc(sysdate+1))
                        AND REL.ROLE_RESOURCE_ID = TEAM.TEAM_MEMBER_ID
                        AND REL.DELETE_FLAG <> 'Y'
                        AND REL.ROLE_RESOURCE_TYPE = 'RS_TEAM_MEMBER'
                        --and team.team_id=10008
                        ) team,
jtf_rs_role_relations jrr,
jtf_rs_roles_b jrb,
jtf_rs_roles_tl jrbt
WHERE 1 = 1
  AND p.status = 'A'
--  AND caa.party_id = p.party_id
  AND caa.cust_account_id = casa.cust_account_id
  AND p.party_id = ps.party_id
  AND casa.party_site_id = ps.party_site_id
  AND csua.cust_acct_site_id = casa.cust_acct_site_id
  AND nvl(casa.attribute3,'Domestic') = 'Domestic'
--  AND csua.site_use_code = 'SHIP_TO'
  AND csua.site_use_id = ORDER_DETAILS.ship_to_org_id
  AND l.location_id = ps.location_id
  AND sa.STATUS = 'A'
  AND osc.SALESREP_ID = sa.SALESREP_ID(+)
  AND ORDER_DETAILS.line_id = osc.line_id(+)
  AND sa.person_id = papf.person_id
  AND TRUNC(SYSDATE) BETWEEN papf.effective_start_date AND  nvl(effective_end_date,TRUNC(SYSDATE))
  AND sa.RESOURCE_ID = RES.RESOURCE_ID(+)
  AND restl.language = USERENV ('LANG')
  AND res.resource_id = restl.resource_id(+)
  AND team.trsid(+) = RES.resource_id
--  AND (ORDER_DETAILS.booked_date) between  NVL(trunc(team.TEAM_START_DATE),(ORDER_DETAILS.booked_date)) and NVL(trunc(team.TEAM_END_DATE),(ORDER_DETAILS.booked_date))
--  AND (ORDER_DETAILS.booked_date) between  NVL(trunc(team.START_DATE_ACTIVE),(ORDER_DETAILS.booked_date)) and NVL(trunc(team.END_DATE_ACTIVE),(ORDER_DETAILS.booked_date))
  AND jrr.role_id = jrb.role_id
  AND jrb.role_id = jrbt.role_id
  AND jrbt.language = 'US'
  AND jrr.role_resource_id = NVL (team.trsid, NVL (restl.resource_id, papf.person_id)) --100022102
  AND jrb.role_type_code = 'SALES_COMP'
 -- AND jrb.manager_flag <> 'Y'  --Exclude Manager
  AND nvl(jrb.manager_flag,'N') = 'N'
  AND UPPER(jrbt.role_name) NOT LIKE '%SPINE%'       --Added By Ravi Vishnu on 22-SEP-14 to avoid sending mails to 'SPINE' dealers
  AND DECODE(p_salesrep,NULL,1, nvl (team.team_resource_id, res.resource_id)) = DECODE(p_salesrep,NULL,1,p_salesrep)  --100038246, 100024100
  AND (TO_NUMBER (
            DECODE (ORDER_DETAILS.line_category_code,
                    'ORDER',
                    ORDER_DETAILS.unit_selling_price * ORDER_DETAILS.ordered_quantity,
                    'RETURN',
                    -1 * ORDER_DETAILS.unit_selling_price * ORDER_DETAILS.ordered_quantity)
         )) <> 0                                     --Added by Ravi Vishnu on 02-DEC-2014 to exclude $ 0 Orders
 /* AND (NVL (team.team_resource_id, res.resource_id) IN
                    (SELECT   RES.RESOURCE_ID
                       FROM   JTF_RS_TEAMS_TL TM,
                              JTF_RS_TEAM_USAGES UA,
                              JTF_RS_TEAM_MEMBERS MM,
                              JTF_RS_ROLE_RELATIONS REL,
                              JTF_RS_ROLES_B ROL,
                              JTF_RS_RESOURCE_EXTNS RES,
                              JTF_OBJECTS_TL OBJ
                      WHERE       MM.RESOURCE_TYPE = 'INDIVIDUAL'
                              AND UA.TEAM_ID = TM.TEAM_ID
                              AND UA.USAGE = 'SALES_COMP'
                              AND TM.TEAM_ID = MM.TEAM_ID
                              AND TM.LANGUAGE = USERENV ('LANG')
                              --AND MM.DELETE_FLAG <> 'Y'
                              AND NVL(MM.DELETE_FLAG,'N') = 'N'
                              AND REL.ROLE_RESOURCE_ID = MM.TEAM_MEMBER_ID
                              --AND REL.DELETE_FLAG <> 'Y'
                              AND NVL(REL.DELETE_FLAG,'N') ='N'
                              AND REL.ROLE_RESOURCE_TYPE = 'RS_TEAM_MEMBER'
                              AND REL.ROLE_ID = ROL.ROLE_ID
                              AND MM.TEAM_RESOURCE_ID = RES.RESOURCE_ID
                              AND OBJ.OBJECT_CODE = RES.CATEGORY
                              AND OBJ.LANGUAGE = USERENV ('LANG')
                              AND ROL.MEMBER_FLAG = 'Y'
                              AND (ORDER_DETAILS.booked_date) BETWEEN TRUNC(REL.START_DATE_ACTIVE)
                                                               AND  NVL (
                                                                       TRUNC(REL.END_DATE_ACTIVE),
                                                                       TRUNC(SYSDATE
                                                                             + 1)
                                                                    )
                              AND ROL.ROLE_TYPE_CODE IN ('SALES_COMP')
                              AND RES.CATEGORY IN ('EMPLOYEE', 'PARTNER')
                              AND RES.SOURCE_NAME IS NOT NULL
                              AND MM.TEAM_RESOURCE_ID =
                                    NVL (
                                       team.team_resource_id,
                                       NVL (restl.resource_id,
                                            papf.person_id)
                                    ))
                          OR NVL (team.team_resource_id, res.resource_id) IN
                                  (SELECT   group_mem.resource_id
                                     FROM   jtf_rs_group_members_vl group_mem,
                                            JTF_RS_GROUP_MBR_ROLE_VL group_rol
                                    WHERE   1 = 1
                                            AND group_mem.GROUP_ID = group_rol.GROUP_ID
                                            AND group_mem.group_member_id =
                                                  group_rol.group_member_id
                                            AND group_mem.resource_id =
                                                  group_rol.RESOURCE_ID
                                            AND (ORDER_DETAILS.booked_date) BETWEEN TRUNC(START_DATE_ACTIVE)
                                                                             AND  NVL (
                                                                                     TRUNC(END_DATE_ACTIVE),
                                                                                     TRUNC(SYSDATE
                                                                                           + 1)
                                                                                  )
                                            AND GROUP_ROL.RESOURCE_ID =
                                                  NVL (
                                                     team.team_resource_id,
                                                     NVL (restl.resource_id,
                                                          papf.person_id)
                                                  )))          */
				);

         COMMIT;


                  IF l_database = 'PROD' THEN

		 UPDATE xxintg.xx_daily_booking_recon_tmp x
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
                           AND rownum = 1) )
				--Commented by Ravi Vishnu as mgr_email is being used to capture the Original Rep Id to derive team logic
					/*	   ,
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
                           AND rownum = 1))   */
						   ;
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

				UPDATE xxintg.xx_daily_booking_recon_tmp x
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
                        --  AND  TRUNC(SYSDATE) BETWEEN TRUNC(group_role.START_DATE_ACTIVE) AND  NVL (TRUNC(group_role.END_DATE_ACTIVE),SYSDATE + 1)
                           AND  TRUNC(SYSDATE) BETWEEN TRUNC(role.RES_RL_START_DATE) AND  NVL (TRUNC(role.RES_RL_END_DATE),SYSDATE + 1)
                           AND  TRUNC(SYSDATE) BETWEEN TRUNC(resgp.GROUP_START_DATE) AND  NVL (TRUNC(resgp.GROUP_END_DATE),SYSDATE + 1)
                           AND rownum = 1))
				--Commented by Ravi Vishnu as mgr_email is being used to capture the Original Rep Id to derive team logic
				/*		   ,
	            mgr_email = l_dummy_mgr_email    */
				;
			    END IF;

        COMMIT;

        INSERT INTO xxintg.xx_daily_booking_recon_main
        SELECT * FROM xxintg.xx_daily_booking_recon_tmp x
                WHERE 1=1
		          and resource_id=REP_RESOURCE_ID
                  AND x.booking_date between  nvl(x.role_start_active_date,x.booking_date) and nvl(x.role_end_active_date,x.booking_date)
	UNION
        SELECT * FROM xxintg.xx_daily_booking_recon_tmp x
		WHERE 1=1
	          and resource_id!=REP_RESOURCE_ID
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
                                                                                JTF_RS_GROUP_MBR_ROLE_VL group_rol
                                                                        WHERE   1 = 1
                                                                                AND group_mem.GROUP_ID = group_rol.GROUP_ID
                                                                                AND group_mem.group_member_id =
                                                                                      group_rol.group_member_id
                                                                                AND group_mem.resource_id =
                                                                                      group_rol.RESOURCE_ID
                                                                                AND (x.booking_date) BETWEEN TRUNC(START_DATE_ACTIVE) AND  NVL (TRUNC(END_DATE_ACTIVE),TRUNC(SYSDATE+1))
                                                                       )
                                                 )
		      /*  and to_number(resource_id)  not in
			        (select distinct to_number(SALESREP_EMAIL)
				   from xxintg.xx_daily_booking_recon_tmp x
                                  where resource_id = to_number(SALESREP_EMAIL)
                                    and (x.booking_date >=  x.team_end_active_date or x.booking_date >=  x.team_end_date))  */
				and exists
                     (select 1
                   from xxintg.xx_daily_booking_recon_tmp y
                  where resource_id = REP_RESOURCE_ID
					and TO_DATE(y.booking_date) BETWEEN TO_DATE(y.team_start_active_date) AND NVL(TO_DATE(y.team_end_active_date),TO_DATE(SYSDATE))
                    and TO_DATE(y.booking_date) BETWEEN TO_DATE(y.team_start_date) AND NVL(TO_DATE(y.team_end_date),TO_DATE(SYSDATE))
                    AND y.Order_No = x.Order_No
--                    AND invoice_no = '23258835'
						)
                order by Order_No, line_number;


      COMMIT;
   END main;
END XX_BOOKING_RECON_PKG;
/
