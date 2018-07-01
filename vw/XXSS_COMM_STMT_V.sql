/* Formatted on 11/13/2017 9:20:36 AM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXSS_COMM_STMT_V
(
   PAY_RUN,
   PR_CREATION_DATE,
   PR_LAST_UPDATE_DATE,
   PAYRUN_ID,
   PAY_DATE,
   PAY_PERIOD,
   SALESREP_NAME,
   SALESREP_ID,
   RESOURCE_ID,
   SALESREP_EMAIL,
   PATIENT,
   STATEMENT_STATUS,
   PE_NAME,
   REVENUE_CLASS_NAME,
   SALES_ORDER,
   SALES_ORDER_LINE,
   INVOICE_NUMBER,
   INVOICE_LINE_NUM,
   QUANTITY_INVOICED,
   TRX_AMOUNT,
   EXTENDED_AMOUNT,
   COMMISSION_RATE,
   COMMISSION_AMT,
   EXTENDED_COMMISSION_AMT,
   INVOICE_DATE,
   TRANSACTION_TYPE,
   CUSTOMER_NUMBER,
   BILL_TO_NAME,
   SHIP_TO_NAME,
   ADDRESS_LINE1,
   CITY,
   COUNTY,
   STATE,
   POSTAL_CODE,
   COUNTRY,
   d_code,
   ITEM_NUMBER,
   ITEM_DESCRIPTION,
   PO_NUMBER,
   COMMISSION_HEADER_ID,
   BILL_TO_CUSTOMER_ID,
   SHIP_TO_CUSTOMER_ID,
   BILL_TO_SITE_USE_ID,
   PROCESSED_PERIOD_ID,
   SOURCE_DOC_TYPE,
   SOURCE_TRX_ID,
   SOURCE_TRX_LINE_ID,
   CUST_ACCT_SITE_ID,
   ship_cust_acct_site_id,
   CUST_ACCOUNT_ID,
   SOURCE,
   SITE_NUMBER,
   HOSPITAL,
   PRODUCT_GROUP,
   SOURCE_LINE_ID,
   SALES_TOTAL,
   COMM_PERCENT,
   COMM_AMOUNT ,
   SURGEON,
   COMM_TYPE,
   SURGERY_DATE,
   PRODUCT_LINE,
   PLAN_ELEMENT,
   PAY_RUN_ORTHO,
   SALESREP_ORTHO,
   ADJUST_COMMENTS,
   INVENTORY_ITEM_ID,
   COMM_LINE_ID,
   ADJ_FLAG,
   ADJ_NOTES,
   NOTES
)
AS
     SELECT pay_run,
            pr_creation_date, 
            pr_last_update_date,
            payrun_id,
            PAY_DATE,
            pay_period_id,
            salesrep,
            salesrep_id,
            resource_id,
            salesrep_email,
            patient,
            Statement_status,
            pe_name,
            revenue_class_name,
            sales_order,
            sales_order_line,
            invoice_number,
            invoice_line_no,
            quantity_invoiced,
            trx_amount,
            extended_amount,
            commission_rate,
            commission_amt,
            extended_commission_amt,
            invoice_date,
            transaction_type,
            customer_number,
            bill_to_name,
            ship_to_name,
            address_line1,
            city,
            county,
            state,
            postal_code,
            country,
            d_code,
            item_number,
            item_desc,
            po_number,
            commission_header_id,
            bill_to_customer_id,
            ship_to_customer_id,
            bill_to_site_use_id,
            processed_period_id,
            source_doc_type,
            source_trx_id,
            source_trx_line_id,
            cust_acct_site_id,
            ship_cust_acct_site_id,
            cust_account_id,
            source,
            site_number                                     --,CUSTOMER_NUMBER
                       ,
            hospital,
            PRODUCT_GROUP,
            source_line_id,
            SUM (transaction_amount) sales_total,
            Commissionpercent,
            SUM (commission_amount) commission,
            surgeon,
            NULL commission_type,
            NULL surgery_Date,
            NULL product_line,
            NULL quota_name,
            pay_run pay_run_ortho,
            salesrep salesrep_ortho,
            adj_comments,
            inventory_item_id,
            commission_line_id,
            (CASE WHEN (adj_amount IS NOT NULL) THEN 'Y' ELSE 'N' END) adj_flag,
            adj_notes,
            NOTES
       FROM (SELECT par.name pay_run, par.creation_date pr_creation_date, par.last_update_date pr_last_update_date,
                    par.payrun_id,
                    par.pay_date,
                    par.pay_period_id,
                    res.resource_name salesrep,
                    rep.salesrep_id,
                    rep.resource_id,
                    rep.email_address salesrep_email,
                    to_char(cmh.attribute40) patient,
                    DECODE (par.status,
                            'PAID', 'Final',
                            'UNPAID', 'Preliminary')
                       Statement_status,
                    qut.name pe_name                                       --1
                                    ,
                    cre.name revenue_class_name                            --2
                                               ,
                    NVL (cmh.attribute41, TO_CHAR (cmh.order_number))
                       sales_order                         --3   (Case# 10575)
                                  ,
                    trl.sales_order_line                                   --4
                                        ,
                    cmh.invoice_number invoice_number                      --5
                                                     ,
                    cmh.line_number invoice_line_no                        --6
                                                   ,
                    trl.quantity_invoiced                                  --7
                                         ,
                    trl.unit_selling_price trx_amount                      --8
                                                     ,
                    (cmh.transaction_amount) extended_amount              -- 9
                                                            ,
                    (cml.commission_rate) commission_rate                 --10
                                                         ,
                    trl.unit_selling_price * cml.commission_rate commission_amt,
                    cml.commission_amount extended_commission_amt --Changed on 04-Jun-2014
                                                                 ,
                    cmh.invoice_date                                      --13
                                    ,
                    cmh.trx_type transaction_type                         --14
                                                 ,
                    cmh.attribute21 customer_number                       --15
                                                   ,
                    acc.account_number biil_to_customer                   --16
                                                       --       ,acc.account_name  bill_to_name             --17    --Commented by Deepta on 13-Aug-14
                                                       --      ,rac_ship.account_name ship_to_name               --19 --Commented by Deepta on 13-Aug-14
                    ,
                    cmh.attribute20 bill_to_name --17 -- Added by Deepta on 13-Aug-14
                                                ,
                    cmh.attribute19 ship_to_name --19 -- Added by Deepta on 13-Aug-14
                                                ,
                    RAA_SHIP_LOC.ADDRESS1 address_line1                   --20
                                                       ,
                    RAA_SHIP_LOC.CITY city                                --21
                                          ,
                    RAA_SHIP_LOC.COUNTY county                            --22
                                              ,
                    RAA_SHIP_LOC.STATE state                              --23
                                            ,
                    RAA_SHIP_LOC.POSTAL_CODE postal_code                  --24
                                                        ,
                    raa_ship_loc.country                                  --25
                                        ,
                    cmh.attribute6 d_code                                 --26
                                         ,
                    cmh.attribute1 item_number                            --27
                                              ,
                    cmh.attribute2 item_desc                              --28
                                            ,
                    TO_CHAR (cmh.attribute45) || ' ' po_number            --45
                                                              ,
                    cmh.commission_header_id,
                    trh.bill_to_customer_id,
                    trh.ship_to_customer_id,
                    trh.bill_to_site_use_id,
                    cml.processed_period_id,
                    cmh.source_doc_type,
                    (case when (cmh.source_trx_id is null and cmh.invoice_number is not null) then
                          (select customer_trx_id from apps.ra_customer_trx_all where trx_number=cmh.invoice_number and rownum<=1)
                      else
                      cmh.source_trx_id
                      end) source_trx_id,
                     (case when (cmh.source_trx_line_id is null and cmh.line_number is not null) then
                          (select customer_trx_line_id from apps.ra_customer_trx_all rct, apps.ra_customer_trx_lines_all rctl
where rct.trx_number=cmh.invoice_number and rctl.customer_trx_id =rct.customer_trx_id and 
rctl.line_number=cmh.line_number and rctl.line_type='LINE' and rownum<=1)
                      else
                      cmh.source_trx_line_id
                      end) source_trx_line_id,                    
                    --cmh.source_trx_line_id,
                    acu.cust_acct_site_id,
                    raa_ship.cust_acct_site_id ship_cust_acct_site_id,
                    acc.cust_account_id,
                    cmh.attribute65 source                  -- added on 6/6/14
                                          ,
                    raa_ship_ps.party_site_number site_number --,cmh.attribute21 CUSTOMER_NUMBER
                                                             ,
                    cmh.attribute20 hospital,
                    cre.name PRODUCT_GROUP,
                    cmh.attribute37 source_line_id,
                    cmh.transaction_amount,
                    Cml.Commission_Rate * 100 Commissionpercent,
                    cml.commission_amount,
                    REPLACE (cmh.attribute38, ',', ' ') surgeon,
                    cmh.attribute99 adj_comments,
                    --,cmh.source_trx_id,
                    --cmh.source_trx_line_id,
                    (case when (cmh.inventory_item_id is null) then
                     (select inventory_item_id from apps.mtl_system_items_b where segment1=cmh.attribute1 and rownum<=1)
                     else 
                     cmh.inventory_item_id
                     end) inventory_item_id,
                    cml.commission_line_id,
                    NULL adj_amount,
                    cmh.attribute75 adj_notes,
                    APPS.XXSS_COMM_NOTES( par.payrun_id,rep.salesrep_id) NOTES
               FROM cn_commission_headers_all cmh,
                    cn_commission_lines_all cml,
                    cn_revenue_classes_all cre,
                    cn_payruns_all par,
                    jtf_rs_salesreps rep,
                    cn_Payment_Worksheets_all Cpw,
                    Jtf_Rs_Groups_Tl Jrgt,
                    cn_quotas_all qut,
                    ra_customer_trx_all trh,
                    ra_customer_trx_lines_all trl,
                    hz_cust_accounts_all acc,
                    hz_cust_site_uses_all acu,
                    jtf_rs_resource_extns_tl res,
                    hz_party_sites raa_ship_ps,
                    hz_cust_acct_sites_all raa_ship,
                    hz_cust_accounts rac_ship,
                    hz_parties rac_ship_party,
                    HZ_LOCATIONS RAA_SHIP_LOC,
                    HZ_CUST_SITE_USES_ALL SU_SHIP,
                    CN_SRP_PAY_GROUPS_ALL CSPGA,        --Added on 01/21/16 DA
                    cn_period_statuses_all cpsa         --Added on 01/21/16 DA
              WHERE     cmh.commission_header_id = cml.commission_header_id
                    AND cml.processed_period_id = par.pay_period_id(+)
                    AND cml.credited_salesrep_id = rep.salesrep_id
                    AND cml.quota_id = qut.quota_id
                    AND NVL (cmh.transaction_amount, 0) <> 0
                    AND UPPER (Cml.Status) = 'CALC'
                    AND Cpw.Payrun_Id = Par.Payrun_Id
                    AND Rep.Salesrep_Id = Cpw.Salesrep_Id
                    AND Jrgt.GROUP_ID = Cmh.Comp_Group_Id
                    AND Jrgt.Language = 'US'
                    AND res.Language = 'US'
                    AND Qut.Quota_Group_Code IS NOT NULL
                    AND Qut.Quota_Group_Code(+) IN ('QUOTA') --KM20160518  :Case#12721
                    AND Cpw.Quota_Id IS NULL
                    AND REP.RESOURCE_ID = RES.RESOURCE_ID
                    AND par.pay_period_id = cpsa.period_id --Added on 01/21/16 DA
                    AND (   (cpsa.end_date BETWEEN cspga.start_date
                                               AND NVL (cspga.end_date,
                                                        cpsa.end_date)) --Added on 01/21/16 DA
                         OR (cpsa.start_date BETWEEN cspga.start_date
                                                 AND NVL (cspga.end_date,
                                                          cpsa.end_date)) --Added on 01/21/16 DA
                         OR (cspga.start_date BETWEEN cpsa.start_date
                                                  AND cpsa.end_date)) --Added on 01/21/16 DA
                    AND cmh.revenue_class_id = cre.revenue_class_id
                    AND cmh.source_trx_id = trh.customer_trx_id(+)
                    AND cmh.source_trx_line_id = trl.customer_trx_line_id(+)
                    AND trh.bill_to_customer_id = acc.cust_account_id(+)
                    AND trh.bill_to_site_use_id = acu.site_use_id(+)
                    AND raa_ship.party_site_id = raa_ship_ps.party_site_id(+)
                    AND trh.ship_to_customer_id = rac_ship.cust_account_id(+)
                    AND rac_ship.party_id = rac_ship_party.party_id(+)
                    AND su_ship.cust_acct_site_id =
                           raa_ship.cust_acct_site_id(+)
                    AND trh.ship_to_site_use_id = su_ship.site_use_id(+)
                    AND RAA_SHIP_LOC.LOCATION_ID(+) = RAA_SHIP_PS.LOCATION_ID
                    -- AND  par.payrun_id =  :P_PAY_GROUP_ID
                    -- AND  rep.salesrep_id = NVL(:P_SALESREP_ID, rep.salesrep_id)
                    --AND  :P_LAYOUT in ('Others','Ortho')
                    -- AND NVL(CML.COMMISSION_AMOUNT,0) !=0  KM20160518  :Case#12721
                    AND CSPGA.PAY_GROUP_ID = PAR.PAY_GROUP_ID
                    AND cspga.salesrep_id = rep.salesrep_id
             UNION
             SELECT par.name pay_run,par.creation_date pr_creation_date, par.last_update_date pr_last_update_date,
                    par.payrun_id,
                    par.pay_date,
                    par.pay_period_id,
                    res.resource_name salesrep,
                    rep.salesrep_id,
                    rep.resource_id,
                    rep.email_address salesrep_email,
                    to_char(cmh.attribute40) patient,
                    DECODE (par.status,
                            'PAID', 'Final',
                            'UNPAID', 'Preliminary')
                       Statement_status,
                    qut.name pe_name,
                    NULL revenue_class_name,
                    NVL (cmh.attribute41, TO_CHAR (cmh.order_number))
                       sales_order,
                    NULL sales_order_line,
                    cmh.invoice_number invoice_number,
                    cmh.line_number invoice_line_no,
                    NULL quantity_invoiced,
                    NULL trx_amount,
                    (cmh.transaction_amount) extended_amount,
                    (cml.commission_rate) commission_rate,
                    NULL commission_amt,
                    cml.commission_amount extended_commission_amt,
                    cmh.invoice_date,
                    cmh.trx_type transaction_type,
                    cmh.attribute21 customer_number,
                    NULL biil_to_customer,
                    NULL bill_to_name,
                    NULL ship_to_name,
                    NULL address_line1,
                    NULL city,
                    NULL county,
                    NULL state,
                    NULL postal_code,
                    NULL country,
                    cmh.attribute6 d_code                                 --26
                                         ,
                    cmh.attribute1 item_number,
                    cmh.attribute2 item_desc,
                    TO_CHAR (cmh.attribute45) || ' ' po_number,
                    cmh.commission_header_id,
                    NULL bill_to_customer_id,
                    NULL ship_to_customer_id,
                    NULL bill_to_site_use_id,
                    cml.processed_period_id,
                    cmh.source_doc_type,
                    (case when (cmh.source_trx_id is null and cmh.invoice_number is not null) then
                          (select customer_trx_id from apps.ra_customer_trx_all where trx_number=cmh.invoice_number and rownum<=1)
                      else
                      cmh.source_trx_id
                      end) source_trx_id,
                     (case when (cmh.source_trx_line_id is null and cmh.line_number is not null) then
                          (select customer_trx_line_id from apps.ra_customer_trx_all rct, apps.ra_customer_trx_lines_all rctl
where rct.trx_number=cmh.invoice_number and rctl.customer_trx_id =rct.customer_trx_id and 
rctl.line_number=cmh.line_number and rctl.line_type='LINE' and rownum<=1)
                      else
                      cmh.source_trx_line_id
                      end) source_trx_line_id,                    
                    NULL cust_acct_site_id,
                    null ship_cust_acct_site_id,
                    NULL cust_account_id,
                    cmh.attribute65 source,
                    NULL site_number        --,cmh.attribute21 CUSTOMER_NUMBER
                                    ,
                    NULL hospital,
                    CMH.attribute4 PRODUCT_GROUP,
                    cmh.attribute37 source_line_id,
                    cmh.transaction_amount,
                    Cml.Commission_Rate * 100 Commissionpercent,
                    cml.commission_amount,
                    REPLACE (cmh.attribute38, ',', ' ') surgeon,
                    cmh.attribute99 adj_comments,
                    --cmh.source_trx_id,
                    --  cmh.source_trx_line_id,
                    (case when (cmh.inventory_item_id is null) then
                     (select inventory_item_id from apps.mtl_system_items_b where segment1=cmh.attribute1 and rownum<=1)
                     else 
                     cmh.inventory_item_id
                     end) inventory_item_id,
                    cml.commission_line_id,
                    NULL adj_amount,
                    cmh.attribute75 adj_notes,
                    APPS.XXSS_COMM_NOTES( par.payrun_id,rep.salesrep_id) NOTES
               FROM cn_commission_headers_all cmh,
                    cn_commission_lines_all cml,
                    cn_payruns_all par,
                    jtf_rs_salesreps rep,
                    cn_quotas_all qut,
                    JTF_RS_RESOURCE_EXTNS_TL RES,
                    CN_SRP_PAY_GROUPS_ALL CSPGA,
                    cn_period_statuses_all cpsa         --Added on 01/21/16 DA
              WHERE     cmh.commission_header_id = cml.commission_header_id
                    AND cml.processed_period_id = par.pay_period_id(+)
                    AND cml.credited_salesrep_id = rep.salesrep_id
                    AND cml.quota_id = qut.quota_id
                    AND UPPER (cml.status) = 'CALC'
                    AND qut.quota_group_code IS NOT NULL
                    AND qut.quota_group_code(+) IN ('BONUS')
                    AND cml.status NOT IN ('OBSOLETE')
                    --AND PAR.PAYRUN_ID              = :P_PAY_GROUP_ID
                    AND par.pay_period_id = cpsa.period_id --Added on 01/21/16 DA
                    AND (   (cpsa.end_date BETWEEN cspga.start_date
                                               AND NVL (cspga.end_date,
                                                        cpsa.end_date)) --Added on 01/21/16 DA
                         OR (CPSA.START_DATE BETWEEN CSPGA.START_DATE
                                                 AND NVL (CSPGA.END_DATE,
                                                          CPSA.END_DATE)) --Added on 01/21/16 DA
                         OR (cspga.start_date BETWEEN cpsa.start_date
                                                  AND cpsa.end_date)) --Added on 01/21/16 DA
                    --AND rep.salesrep_id            = NVL(:p_salesrep_id, rep.salesrep_id)
                    AND NVL (cml.commission_amount, 0) != 0
                    --AND  :P_LAYOUT in ('Others','Ortho')
                    AND rep.resource_id = res.resource_id
                    AND res.Language = 'US'
                    AND cspga.pay_group_id = par.pay_group_id
                    AND cspga.salesrep_id = rep.salesrep_id
             UNION
             SELECT par.name pay_run,par.creation_date pr_creation_date, par.last_update_date pr_last_update_date,
                    par.payrun_id,
                    par.pay_date,
                    par.pay_period_id,
                    res.resource_name salesrep,
                    rep.salesrep_id,
                    rep.resource_id,
                    rep.email_address salesrep_email,
                    to_char(cmh.attribute40) patient,
                    DECODE (par.status,
                            'PAID', 'Final',
                            'UNPAID', 'Preliminary')
                       Statement_status,
                    qut.name pe_name,
                    NULL revenue_class_name,
                    NVL (cmh.attribute41, TO_CHAR (cmh.order_number))
                       sales_order,
                    NULL sales_order_line,
                    cmh.invoice_number invoice_number,
                    cmh.line_number invoice_line_no,
                    NULL quantity_invoiced,
                    NULL trx_amount,
                    (cmh.transaction_amount) extended_amount,
                    (cml.commission_rate) commission_rate,
                    NULL commission_amt,
                    cml.commission_amount extended_commission_amt,
                    cmh.invoice_date,
                    cmh.trx_type transaction_type,
                    cmh.attribute21 customer_number,
                    NULL biil_to_customer,
                    NULL bill_to_name,
                    NULL ship_to_name,
                    NULL address_line1,
                    NULL city,
                    NULL county,
                    NULL state,
                    NULL postal_code,
                    NULL country,
                    cmh.attribute6 d_code                                 --26
                                         ,
                    cmh.attribute1 item_number,
                    cmh.attribute2 item_desc,
                    TO_CHAR (cmh.attribute45) || ' ' po_number,
                    cmh.commission_header_id,
                    NULL bill_to_customer_id,
                    NULL ship_to_customer_id,
                    NULL bill_to_site_use_id,
                    cml.processed_period_id,
                    cmh.source_doc_type,
                    (case when (cmh.source_trx_id is null and cmh.invoice_number is not null) then
                          (select customer_trx_id from apps.ra_customer_trx_all where trx_number=cmh.invoice_number and rownum<=1)
                      else
                      cmh.source_trx_id
                      end) source_trx_id,
                     (case when (cmh.source_trx_line_id is null and cmh.line_number is not null) then
                          (select customer_trx_line_id from apps.ra_customer_trx_all rct, apps.ra_customer_trx_lines_all rctl
where rct.trx_number=cmh.invoice_number and rctl.customer_trx_id =rct.customer_trx_id and 
rctl.line_number=cmh.line_number and rownum<=1)
                      else
                      cmh.source_trx_line_id
                      end) source_trx_line_id,                    
                    NULL cust_acct_site_id,
                    null ship_cust_acct_site_id,
                    NULL cust_account_id,
                    cmh.attribute65 source,
                    NULL site_number        --,cmh.attribute21 CUSTOMER_NUMBER
                                    ,
                    NULL hospital,
                    CMH.attribute4 PRODUCT_GROUP,
                    cmh.attribute37 source_line_id,
                    cmh.transaction_amount,
                    Cml.Commission_Rate * 100 Commissionpercent,
                    cml.commission_amount,
                    REPLACE (cmh.attribute38, ',', ' ') surgeon,
                    cmh.attribute99 adj_comments,
                    --cmh.source_trx_id,
                    --  cmh.source_trx_line_id,
                    (case when (cmh.inventory_item_id is null) then
                     (select inventory_item_id from apps.mtl_system_items_b where segment1=cmh.attribute1 and rownum<=1)
                     else 
                     cmh.inventory_item_id
                     end) inventory_item_id,
                    cml.commission_line_id,
                    cmh.attribute74 adj_amount,
                    cmh.attribute75 adj_notes,
                    APPS.XXSS_COMM_NOTES( par.payrun_id,rep.salesrep_id) NOTES
               FROM cn_commission_headers_all cmh,
                    cn_commission_lines_all cml,
                    cn_payruns_all par,
                    jtf_rs_salesreps rep,
                    cn_quotas_all qut,
                    JTF_RS_RESOURCE_EXTNS_TL RES,
                    CN_SRP_PAY_GROUPS_ALL CSPGA,
                    cn_Payment_Worksheets_all cpwa,
                    cn_period_statuses_all cpsa         --Added on 01/21/16 DA
              WHERE     cmh.commission_header_id = cml.commission_header_id
                    AND cml.processed_period_id = par.pay_period_id(+)
                    AND cml.credited_salesrep_id = rep.salesrep_id
                    AND cml.quota_id = qut.quota_id
                    AND UPPER (cml.status) = 'CALC'
                    --AND qut.quota_group_code      IS NOT NULL
                    --AND qut.quota_group_code (+)  IN ('BONUS')
                    AND cml.status NOT IN ('OBSOLETE')
                    --AND PAR.PAYRUN_ID              = :P_PAY_GROUP_ID
                    AND par.pay_period_id = cpsa.period_id --Added on 01/21/16 DA
                    AND (   (cpsa.end_date BETWEEN cspga.start_date
                                               AND NVL (cspga.end_date,
                                                        cpsa.end_date)) --Added on 01/21/16 DA
                         OR (CPSA.START_DATE BETWEEN CSPGA.START_DATE
                                                 AND NVL (CSPGA.END_DATE,
                                                          CPSA.END_DATE)) --Added on 01/21/16 DA
                         OR (cspga.start_date BETWEEN cpsa.start_date
                                                  AND cpsa.end_date)) --Added on 01/21/16 DA
                    --AND rep.salesrep_id            = NVL(:p_salesrep_id, rep.salesrep_id)
                    AND CMH.ATTRIBUTE74 IS NOT NULL
                    --AND  :P_LAYOUT in ('Others','Ortho')
                    AND rep.resource_id = res.resource_id
                    AND res.Language = 'US'
                    AND cspga.pay_group_id = par.pay_group_id
                    AND cspga.salesrep_id = rep.salesrep_id
                    AND rep.salesrep_id = cpwa.salesrep_id
                    AND cpwa.quota_id IS NULL
                    AND cpwa.payrun_id = par.payrun_id
   union
   SELECT par.name pay_run,par.creation_date pr_creation_date, par.last_update_date pr_last_update_date,
                    par.payrun_id,
                    par.pay_date,
                    par.pay_period_id,
                    res.resource_name salesrep,
                    rep.salesrep_id,
                    rep.resource_id,
                    rep.email_address salesrep_email,
                    null patient,
                    DECODE (par.status,
                            'PAID', 'Final',
                            'UNPAID', 'Preliminary')
                       Statement_status,
                    null pe_name,
                    NULL revenue_class_name,
                    null
                       sales_order,
                    NULL sales_order_line,
                    null invoice_number,
                    null invoice_line_no,
                    NULL quantity_invoiced,
                    NULL trx_amount,
                    null extended_amount,
                    null commission_rate,
                    NULL commission_amt,
                    null extended_commission_amt,
                    null invoice_date,
                    null transaction_type,
                    null customer_number,
                    NULL biil_to_customer,
                    NULL bill_to_name,
                    NULL ship_to_name,
                    NULL address_line1,
                    NULL city,
                    NULL county,
                    NULL state,
                    NULL postal_code,
                    NULL country,
                    null d_code                                 --26
                                         ,
                    null item_number,
                    null item_desc,
                    null po_number,
                    null commission_header_id,
                    NULL bill_to_customer_id,
                    NULL ship_to_customer_id,
                    NULL bill_to_site_use_id,
                    null processed_period_id,
                    null source_doc_type,
                    null source_trx_id,
                     null source_trx_line_id,                    
                    NULL cust_acct_site_id,
                    null ship_cust_acct_site_id,
                    NULL cust_account_id,
                    null source,
                    NULL site_number        --,cmh.attribute21 CUSTOMER_NUMBER
                                    ,
                    NULL hospital,
                    null PRODUCT_GROUP,
                    null source_line_id,
                    null transaction_amount,
                    null Commissionpercent,
                    sum(cpw.pmt_amount_adj) commission_amount,
                    null surgeon,
                    null adj_comments,
                    --cmh.source_trx_id,
                    --  cmh.source_trx_line_id,
                    null inventory_item_id,
                    null commission_line_id,
                    null  adj_amount,
                    null adj_notes,
                    APPS.XXSS_COMM_NOTES( par.payrun_id,rep.salesrep_id) NOTES
                    from cn_Payment_Worksheets_all cpw, apps.cn_payruns_all par, apps.JTF_RS_RESOURCE_EXTNS_TL res,
                    apps.jtf_rs_salesreps rep
                    where cpw.payrun_id=par.payrun_id 
                     and  cpw.salesrep_id=rep.salesrep_id
                     and res.resource_id=rep.resource_id 
                     and cpw.quota_id is null
                     group by
                     par.name ,par.creation_date , par.last_update_date ,
                    par.payrun_id,
                    par.pay_date,
                    par.pay_period_id,
                    res.resource_name ,
                    rep.salesrep_id,
                    rep.resource_id,
                    rep.email_address,par.status
             )
   GROUP BY pay_run,
            pr_creation_date, 
            pr_last_update_date,
            payrun_id,
            pay_date,
            pay_period_id,
            salesrep,
            salesrep,
            salesrep_id,
            resource_id,
            salesrep_email,
            PATIENT,
            Statement_status,
            pe_name,
            revenue_class_name,
            sales_order,
            sales_order_line,
            invoice_number,
            invoice_line_no,
            quantity_invoiced,
            extended_amount,
            (trx_amount * quantity_invoiced),
            commission_rate,
            commission_amt,
            ( (extended_amount * quantity_invoiced) * commission_rate),
            (  quantity_invoiced
             * ( (extended_amount * quantity_invoiced) * commission_rate)),
            invoice_date,
            transaction_type,
            customer_number,
            bill_to_name,
            ship_to_name,
            address_line1,
            city,
            county,
            state,
            postal_code,
            country,
            d_code,
            item_number,
            item_desc,
            po_number,
            commission_header_id,
            bill_to_customer_id,
            bill_to_site_use_id,
            processed_period_id,
            source_doc_type,
            source_trx_id,
            source_trx_line_id,
            extended_commission_amt,
            cust_acct_site_id,
            ship_cust_acct_site_id,
            CUST_ACCOUNT_ID,
            source,
            trx_amount,
            SHIP_TO_CUSTOMER_ID,
            ship_to_name,
            site_number                                     --,CUSTOMER_NUMBER
                       ,
            hospital,
            PRODUCT_GROUP,
            source_line_id       --      ,SUM (transaction_amount) sales_total
                          ,
            Commissionpercent      --      ,SUM (commission_amount) commission
                             ,
            surgeon,
            adj_comments,
            --,source_trx_id,
            --  source_trx_line_id,
            inventory_item_id,
            commission_line_id,
            adj_amount,adj_notes,NOTES
   ORDER BY pe_name, INVOICE_NUMBER, invoice_line_no;


grant select on apps.XXSS_COMM_STMT_V to ETLEBSUSER;
grant select on apps.XXSS_COMM_STMT_V to xxappsread;
