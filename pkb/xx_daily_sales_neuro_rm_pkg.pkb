DROP PACKAGE BODY APPS.XX_DAILY_SALES_NEURO_RM_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_DAILY_SALES_NEURO_RM_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : Ravi Vishnu
 Creation Date : 08-Sep-2014
 File Name     : xx_daily_sales_rm_pkg
 Description   : This code is being written to get data  for Neuro Daily sales

 Change History:
 Date         Name                  Remarks
 ----------- -------------         -----------------------------------
 08-Sep-2014  Ravi Vishnu          Initial Version
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

      DELETE FROM xxintg.xx_daily_inv_neuro_rm_tmp;

      DELETE FROM xxintg.xx_daily_inv_neuro_rm_main;

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

      INSERT INTO xxintg.xx_daily_inv_neuro_rm_tmp
      (SELECT   DISTINCT NVL (team.team_resource_id, res.resource_id) resource_id,UPPER(caa.customer_class_code) Customer_type,
         TRUNC (cta.trx_date) Invoice_date,
         cta.trx_number Invoice_No,
         ctla.line_number,
         ctype.name Invoice_Type,
         cta.interface_header_attribute1 Order_Number,
         NULL   order_type,
         NULL   Order_date,
         NULL   Booked_date,
         caa.account_number ship_to_customer_no,
         ps.party_site_number ship_to_customer_site_no,
         csua.location Ship_To_Customer_Loc_No,
            p.party_name
         || ' '
         || l.address1
         || ' '
         || l.address2
         || ' '
         || l.address3
         || ' '
         || l.address4
         || ' '
         || l.street_number
         || ' '
         || l.street
         || ' '
         || l.city
         || ', '
         || l.state
         || ' '
         || l.postal_code
            ship_to_name,
         cta.purchase_order transaction_po_number,
         sib.segment1 item_part_no,
         ctla.description description,
         mc.segment4 Division,
         mc.segment9 DCODE,
         DECODE (ctla.quantity_invoiced,
                 NULL, ctla.quantity_credited,
                 ctla.quantity_invoiced)
            base_qty,
         ctla.unit_selling_price unit_selling_price,
         ctla.unit_selling_price
         * DECODE (ctla.quantity_invoiced,
                   NULL, ctla.quantity_credited,
                   ctla.quantity_invoiced)
            total_sales_dollars,
            --res.source_mgr_name   mgr_name,
            null mgr_name,
         --(select source_email from APPS.JTF_RS_RESOURCE_EXTNS where source_name=res.source_mgr_name) mgr_email,
         null mgr_email,
         NVL (team.full_name, NVL (restl.RESOURCE_NAME, papf.full_name))
            SalesRep_Name,
         sa.RESOURCE_ID SalesRep_Email,
         jrb.manager_flag MANAGER_FLAG,
         (SELECT   osc.attribute1
            FROM   apps.oe_sales_credits osc
           WHERE       1 = 1
                   AND osc.line_id = ctla.interface_line_attribute6
                   AND osc.salesrep_id = sa.salesrep_id and rownum=1)
            Territory_Name,
         (SELECT   osc.attribute2
            FROM   apps.oe_sales_credits osc
           WHERE       1 = 1
                   AND osc.line_id = ctla.interface_line_attribute6
                   AND osc.salesrep_id = sa.salesrep_id and rownum=1)
            Territory_Code,
           trunc(jrr.start_date_active) role_start_active_date,
           trunc(jrr.end_date_active) role_end_active_date,
           trunc(team.team_start_date),
           trunc(team.team_end_date),
           trunc(team.start_date_active) team_start_active_date,
           trunc(team.end_date_active) team_end_active_date
  FROM   APPS.ra_customer_trx_all cta,
         APPS.ra_customer_trx_lines_all ctla,
         APPS.ra_cust_trx_types_all ctype,
         APPS.jtf_rs_salesreps sa,
         apps.ra_cust_trx_line_salesreps_all ctlsa,
         APPS.hz_parties p,
         APPS.hz_party_sites ps,
         APPS.hz_cust_accounts_all caa,
         APPS.hz_cust_acct_sites_all casa,
         APPS.hz_cust_site_uses_all csua,
         APPS.hz_locations l,
         APPS.mtl_system_items_b sib,
         apps.mtl_item_categories_v icv,
         apps.mtl_categories_b mc,
         apps.per_all_people_f papf,
         APPS.JTF_RS_RESOURCE_EXTNS RES,
         APPS.jtf_rs_resource_extns_tl restl,
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
                        )  team,
         jtf_rs_role_relations jrr,
         jtf_rs_roles_b jrb,
         jtf_rs_roles_tl jrbt
         --oe_order_headers_all ooha
 WHERE       cta.customer_trx_id = ctla.customer_trx_id
         AND cta.complete_flag = 'Y'
         AND ctla.line_type = 'LINE'
         AND ctla.customer_trx_line_id = ctlsa.customer_trx_line_id
         AND cta.CUST_TRX_TYPE_ID = ctype.CUST_TRX_TYPE_ID
         AND cta.org_id = ctype.org_id
         AND cta.ship_to_customer_id = caa.cust_account_id
         AND SA.salesrep_id = ctlsa.salesrep_id
         AND caa.party_id = p.party_id
         AND p.party_id = ps.party_id
         AND caa.cust_account_id = casa.cust_account_id
         AND casa.party_site_id = ps.party_site_id
         AND csua.cust_acct_site_id = casa.cust_acct_site_id
         AND NVL (casa.attribute3, 'Domestic') = 'Domestic'
         AND csua.site_use_code = 'SHIP_TO'
         AND csua.site_use_id = cta.ship_to_site_use_id
         AND ctla.inventory_item_id = sib.inventory_item_id
         AND ctla.org_id =
               (SELECT   FSP.ORG_ID
                  FROM   apps.FINANCIALS_SYSTEM_PARAMS_ALL FSP,
                         apps.HR_OPERATING_UNITS HOU,
                         apps.mtl_parameters mp
                 WHERE   1 = 1 AND FSP.ORG_ID = HOU.ORGANIZATION_ID
                         AND FSP.INVENTORY_ORGANIZATION_ID =
                               MP.ORGANIZATION_ID(+)
                         AND FSP.INVENTORY_ORGANIZATION_ID =
                               sib.organization_id
                         AND ctla.org_id = fsp.org_id)
         AND sib.inventory_item_id = icv.inventory_item_id
         AND sib.organization_id = icv.organization_id
         AND icv.category_id = mc.category_id
         AND icv.category_set_name = 'Sales and Marketing'
         AND l.location_id = ps.location_id
         AND sa.person_id = papf.person_id(+)
         AND TRUNC (SYSDATE) BETWEEN TRUNC (papf.effective_start_date(+)) AND  TRUNC (papf.effective_end_date(+))
         AND sa.STATUS = 'A'
         AND sa.RESOURCE_ID = RES.RESOURCE_ID(+)
         AND restl.language = USERENV ('LANG')
         AND res.resource_id = restl.resource_id(+)
         AND team.trsid(+) = sa.RESOURCE_ID
--         AND TRUNC (ooha.booked_date) between  NVL(trunc(team.TEAM_START_DATE),TRUNC (ooha.booked_date)) and NVL(trunc(team.TEAM_END_DATE),TRUNC (ooha.booked_date))
--         AND TRUNC (ooha.booked_date) between  NVL(trunc(team.START_DATE_ACTIVE),TRUNC (ooha.booked_date)) and NVL(trunc(team.END_DATE_ACTIVE),TRUNC (ooha.booked_date))
         AND UPPER (ctype.name) IN ('INVOICE', 'CREDIT MEMO')
         AND UPPER (mc.segment4) = CASE WHEN UPPER(p_division) = 'INSTRUMENTS' THEN 'INSTR' ELSE UPPER (NVL (p_division, mc.segment4)) END
         AND trunc (cta.trx_date) BETWEEN NVL (to_date(p_from_date,'DD-MON-RRRR'), trunc(cta.trx_date))
                                     AND  NVL (to_date(p_to_date,'DD-MON-RRRR'), trunc(cta.trx_date))
--         AND DECODE(p_dcode,NULL,1,UPPER (mc.segment9)) = DECODE(p_dcode,NULL,1,UPPER(p_dcode))
--         AND DECODE(p_salesrep,NULL,1,RES.RESOURCE_ID) = DECODE(p_salesrep,NULL,1,p_salesrep)
         AND jrr.role_id = jrb.role_id
         AND jrb.role_id = jrbt.role_id
         AND jrbt.language = 'US'
         AND jrr.role_resource_id = NVL (team.team_resource_id, NVL (restl.resource_id, papf.person_id))
--         AND TRUNC (ooha.booked_date) BETWEEN TRUNC (jrr.START_DATE_ACTIVE)
--                                          AND  NVL (
--                                                  TRUNC (jrr.END_DATE_ACTIVE),
--                                                  TRUNC (SYSDATE + 1)
--                                               )
         AND jrb.role_type_code LIKE 'SALES_COMP'
      --   AND jrb.manager_flag <> 'Y'
         AND (ctla.unit_selling_price
              * DECODE (ctla.quantity_invoiced,
                        NULL, ctla.quantity_credited,
                        ctla.quantity_invoiced)) <> 0
         and nvl(sib.attribute1, 'Y') = 'Y'
         AND UPPER(jrbt.role_name) NOT LIKE '%SPINE%'             --Added By Ravi Vishnu to exclude SPINE Dealers
         --AND UPPER (mc.segment4) = 'RECON'
         --AND (cta.trx_date) BETWEEN '01-AUG-2014' AND '11-AUG-2014'
         --AND TO_CHAR(ooha.order_number) = cta.interface_header_attribute1
         --AND ooha.org_id = cta.org_id
         --AND UPPER(caa.customer_class_code) <> 'DISTRIBUTOR'  -- Added By Ravi Vishnu to avoid 'DISTRIBUTOR' customer class records

         );

         COMMIT;

         UPDATE xxintg.xx_daily_inv_neuro_rm_tmp x
         set order_date = (select trunc(ordered_date) from oe_order_headers_all where order_number = x.order_number),
             booked_date = (select trunc(booked_date) from oe_order_headers_all where order_number = x.order_number),
             order_type = (SELECT   name
                           FROM   oe_transaction_types_tl a, oe_order_headers_all b
                           WHERE       a.transaction_type_id = b.order_type_id
                           AND a.language = 'US'
                            AND b.order_number =x.order_number );

         COMMIT;

        IF l_database = 'PROD' THEN

         UPDATE xxintg.xx_daily_inv_neuro_rm_tmp x
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
                           and  (x.booked_date) between trunc(RES1.START_DATE_ACTIVE) AND NVL(TRUNC(RES1.END_DATE_ACTIVE), SYSDATE+1)
                           AND  (x.booked_date) BETWEEN TRUNC(group_role.START_DATE_ACTIVE) AND  NVL (TRUNC(group_role.END_DATE_ACTIVE),SYSDATE + 1)
                           AND  (x.booked_date) BETWEEN TRUNC(role.RES_RL_START_DATE) AND  NVL (TRUNC(role.RES_RL_END_DATE),SYSDATE + 1)
                           AND  (x.booked_date) BETWEEN TRUNC(resgp.GROUP_START_DATE) AND  NVL (TRUNC(resgp.GROUP_END_DATE),SYSDATE + 1)
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
                           and  (x.booked_date) between trunc(RES1.START_DATE_ACTIVE) AND NVL(TRUNC(RES1.END_DATE_ACTIVE), SYSDATE+1)
                           AND  (x.booked_date) BETWEEN TRUNC(group_role.START_DATE_ACTIVE) AND  NVL (TRUNC(group_role.END_DATE_ACTIVE),SYSDATE + 1)
                           AND  (x.booked_date) BETWEEN TRUNC(role.RES_RL_START_DATE) AND  NVL (TRUNC(role.RES_RL_END_DATE),SYSDATE + 1)
                           AND  (x.booked_date) BETWEEN TRUNC(resgp.GROUP_START_DATE) AND  NVL (TRUNC(resgp.GROUP_END_DATE),SYSDATE + 1)
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

                UPDATE xxintg.xx_daily_inv_neuro_rm_tmp x
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
                           and  (x.booked_date) between trunc(RES1.START_DATE_ACTIVE) AND NVL(TRUNC(RES1.END_DATE_ACTIVE), SYSDATE+1)
                           AND  (x.booked_date) BETWEEN TRUNC(group_role.START_DATE_ACTIVE) AND  NVL (TRUNC(group_role.END_DATE_ACTIVE),SYSDATE + 1)
                           AND  (x.booked_date) BETWEEN TRUNC(role.RES_RL_START_DATE) AND  NVL (TRUNC(role.RES_RL_END_DATE),SYSDATE + 1)
                           AND  (x.booked_date) BETWEEN TRUNC(resgp.GROUP_START_DATE) AND  NVL (TRUNC(resgp.GROUP_END_DATE),SYSDATE + 1)
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
                mgr_email = l_dummy_mgr_email;

        END IF;

        COMMIT;

    INSERT INTO xxintg.xx_daily_inv_neuro_rm_main
        SELECT * FROM xxintg.xx_daily_inv_neuro_rm_tmp x
                WHERE 1=1
                      and resource_id=to_number(SALESREP_EMAIL)
                  AND x.booked_date between  nvl(x.role_start_active_date,x.booked_date) and nvl(x.role_end_active_date,x.booked_date)
				  --Added By Ravi Vishnu to have only commisionable items shown on the report
				  AND EXISTS (SELECT 1
							    FROM apps.XXINTG_COMMISSION_DCODES_V comm
							   WHERE 1 = 1
							     AND comm.rev_name = 'NEURO'
							     AND comm.user_type_name = 'Product Type'
							     AND x.dcode BETWEEN comm.low_value AND comm.high_value)
    UNION
        SELECT * FROM xxintg.xx_daily_inv_neuro_rm_tmp x
                WHERE 1=1
                  and resource_id!=to_number(SALESREP_EMAIL)
                                    AND (x.booked_date between  nvl(x.team_start_active_date,x.booked_date) and nvl(x.team_end_active_date,x.booked_date)
                                    AND x.booked_date between  nvl(x.team_start_date,x.booked_date) and nvl(x.team_end_date,x.booked_date) ) -- added or logic on 26-Aug-2014 by balaji
                                    AND x.booked_date between  nvl(x.role_start_active_date,x.booked_date) and nvl(x.role_end_active_date,x.booked_date)
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
                                                                  AND TRUNC (x.booked_date) BETWEEN TRUNC(REL.START_DATE_ACTIVE)AND  NVL (TRUNC(REL.END_DATE_ACTIVE),TRUNC(SYSDATE+1))
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
                                                                                AND (x.booked_date) BETWEEN TRUNC(START_DATE_ACTIVE) AND  NVL (TRUNC(END_DATE_ACTIVE),TRUNC(SYSDATE+1))
                                                                       )
                                                 )
      /*           and to_number(resource_id)  not in
                    (select distinct to_number(SALESREP_EMAIL)
                   from xxintg.xx_daily_inv_neuro_rm_tmp x
                                  where resource_id = to_number(SALESREP_EMAIL)
                                    and (x.booked_date >=  x.team_end_active_date or x.booked_date >=  x.team_end_date))     */
					and exists
                     (select 1
                   from xxintg.xx_daily_inv_neuro_rm_tmp y
                  where resource_id = to_number(SALESREP_EMAIL)
								    and TO_DATE(y.booked_date) BETWEEN TO_DATE(y.team_start_active_date) AND NVL(TO_DATE(y.team_end_active_date),TO_DATE(SYSDATE))
                    and TO_DATE(y.booked_date) BETWEEN TO_DATE(y.team_start_date) AND NVL(TO_DATE(y.team_end_date),TO_DATE(SYSDATE))
                    AND y.invoice_no = x.invoice_no
--                    AND invoice_no = '23258835'
						)
					--Added By Ravi Vishnu to have only commisionable items shown on the report
				  AND EXISTS (SELECT 1
							    FROM apps.XXINTG_COMMISSION_DCODES_V comm
							   WHERE 1 = 1
							     AND comm.rev_name = 'NEURO'
							     AND comm.user_type_name = 'Product Type'
							     AND x.dcode BETWEEN comm.low_value AND comm.high_value)
									order by invoice_no, line_number;


      COMMIT;
   END main;
END xx_daily_sales_neuro_rm_pkg;
/
