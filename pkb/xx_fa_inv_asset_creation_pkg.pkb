DROP PACKAGE BODY APPS.XX_FA_INV_ASSET_CREATION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_FA_INV_ASSET_CREATION_PKG" as
    ----------------------------------------------------------------------
    /*
     Created By    : Sharath Babu
     Creation Date : 15-JUN-2013
     File Name     : XXFAINVASSTCREATE.pkb
     Description   : This script creates the body of the package
                     xx_fa_inv_asset_creation_pkg
     Change History:
     Date        Name                  Remarks
     ----------- -------------         -----------------------------------
     15-JUN-2013 Sharath Babu          Initial development.
    */
    ----------------------------------------------------------------------
    --Get Expense CCID - Depreciation Account
    procedure xx_get_deprn_exp_ccid(p_asset_cat_id      in            number,
                                    p_book_type_code    in            varchar2,
                                    p_transaction_rec   in out nocopy xx_fa_inv_asset_creation_pkg.transaction_rec,
                                    p_deprn_exp_ccid       out        number) is
        l_payables_ccid        number;
        l_deprn_exp_ccid       number;
        l_deprn_expense_ccid   number;
        l_dprn_seg1            varchar2(30);
        l_dprn_seg2            varchar2(30);
        l_dprn_seg3            varchar2(30);
        l_dprn_seg4            varchar2(30);
        l_dprn_seg5            varchar2(30);
        l_dprn_seg6            varchar2(30);
        l_dprn_seg7            varchar2(30);
        l_dprn_seg8            varchar2(30);
        l_coa_id               number;
        x_eff_date             date := sysdate;
        l_concatenated_segs    varchar2(1000);
        l_ccid                 number;
        l_delimiter            varchar2(1);
    begin
        --Derive Expense CCID - Depreciation Account
        --Company code is same as the asset clearing account
        --50348 is the COA ID for INTG_ACCOUNTING_FLEXFIELD
        /*
        --   Company    From Asset Clearing Account
        --Department    DFF in WO or MMT
        --Account      From the Asset Category
        --Classification    From Asset clearing
        --Product       From Item segment1 of the financial category
        --Region        From depreciation expense account
        --Intercompany    From depreciation expense account
        --Future         From depreciation expense account
        */
        
       select id_flex_num into l_coa_id from fnd_id_flex_structures
       where application_id=101
       and id_flex_code='GL#'
       and id_flex_structure_code='INTG_ACCOUNTING_FLEXFIELD';
       
        l_delimiter := fnd_flex_ext.get_delimiter('SQLGL', 'GL#', l_coa_id);
        begin
            select fcb.asset_clearing_account_ccid
              into l_payables_ccid
              from fa_category_books fcb
             where fcb.category_id = p_asset_cat_id and fcb.book_type_code = p_book_type_code;
        exception
            when others then
                l_payables_ccid := null;
        end;
        begin
            select gcc.segment1
              into l_dprn_seg1
              from gl_code_combinations gcc
             where gcc.code_combination_id = p_transaction_rec.payables_ccid and gcc.enabled_flag = 'Y';
        exception
            when others then
                l_dprn_seg1 := null;
        end;
        --For Surgical Kits
        begin
            if upper(p_transaction_rec.item_type) = upper(g_surg_item_type) then
                select nvl(attribute11, '2001')
                  into l_dprn_seg2
                  from wip_discrete_jobs
                 where wip_entity_id = p_transaction_rec.wip_entity_id;
            else
                select nvl(attribute11, '2001')
                  into l_dprn_seg2
                  from mtl_material_transactions
                 where transaction_id = p_transaction_rec.mtl_txn_id;
            end if;
        exception
            when others then
                l_dprn_seg2 := null;
        end;
        begin
            select fcb.deprn_expense_account_ccid
              into l_deprn_exp_ccid
              from fa_category_books fcb
             where fcb.category_id = p_asset_cat_id and fcb.book_type_code = p_book_type_code;
        exception
            when others then
                l_deprn_exp_ccid := null;
        end;
        begin
            select gcc.segment3, gcc.segment4, gcc.segment6, gcc.segment7, gcc.segment8
              into l_dprn_seg3, l_dprn_seg4, l_dprn_seg6, l_dprn_seg7, l_dprn_seg8
              from gl_code_combinations gcc
             where gcc.code_combination_id = l_deprn_exp_ccid and gcc.enabled_flag = 'Y';
        exception
            when others then
                l_dprn_seg3 := null;
                l_dprn_seg4 := null;
                l_dprn_seg6 := null;
                l_dprn_seg7 := null;
                l_dprn_seg8 := null;
        end;
        begin
            select mcat.segment1
              into l_dprn_seg5
              from mtl_item_categories micat, mtl_category_sets mcats, mtl_categories mcat
             where mcats.category_set_name =
                       nvl(xx_emf_pkg.get_paramater_value('XXFAINVASSTCREATE', 'CAT_SET_FIN'), 'Financial Reporting')
                   and micat.category_set_id = mcats.category_set_id
                   and micat.category_id = mcat.category_id
                   and micat.inventory_item_id = p_transaction_rec.inventory_item_id
                   and micat.organization_id = nvl(xx_emf_pkg.get_paramater_value('XXFAINVASSTCREATE', 'MASTER_ORG_ID'), 83);
        exception
            when others then
                l_dprn_seg5 := null;
        end;
        --Fetch CCID
        l_concatenated_segs := l_dprn_seg1 || l_delimiter || l_dprn_seg2 || l_delimiter || l_dprn_seg3 || l_delimiter ||
                               l_dprn_seg4 || l_delimiter || l_dprn_seg5 || l_delimiter || l_dprn_seg6 || l_delimiter ||
                               l_dprn_seg7 || l_delimiter || l_dprn_seg8;
        dbms_output.put_line(l_concatenated_segs);
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Depreciation Expense Account :' || l_concatenated_segs);
        l_deprn_expense_ccid := fnd_flex_ext.get_ccid('SQLGL',
                                                      'GL#',
                                                      l_coa_id,
                                                      to_char(x_eff_date, 'YYYY/MM/DD HH24:MI:SS'),
                                                      l_concatenated_segs);
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Depreciation Expense Account ID :' || l_deprn_expense_ccid);
        /*BEGIN
           SELECT gcc.code_combination_id
             INTO l_deprn_expense_ccid
             FROM gl_code_combinations gcc
            WHERE gcc.segment1 = l_dprn_seg1
              AND gcc.segment2 = l_dprn_seg2
              AND gcc.segment3 = l_dprn_seg3
              AND gcc.segment4 = l_dprn_seg4
              AND gcc.segment5 = l_dprn_seg5
              AND gcc.segment6 = l_dprn_seg6
              AND gcc.segment7 = l_dprn_seg7
              AND gcc.segment8 = l_dprn_seg8
              AND gcc.enabled_flag = 'Y';
        EXCEPTION
        WHEN OTHERS THEN
           BEGIN
              SELECT fcb.deprn_expense_account_ccid
                INTO l_deprn_expense_ccid
                FROM fa_category_books fcb
               WHERE fcb.category_id = p_asset_cat_id
                 AND fcb.book_type_code = p_book_type_code;
           EXCEPTION
           WHEN OTHERS THEN
              l_deprn_expense_ccid := NULL;
           END;
        END;*/
        p_deprn_exp_ccid := l_deprn_expense_ccid;
    exception
        when others then
            p_transaction_rec.derivation_flag := g_error_flag;
            p_transaction_rec.error_message := p_transaction_rec.error_message ||
                                               'Expense CCID-Depreciation Account Derivation Error|';
            xx_emf_pkg.error(p_severity              => xx_emf_cn_pkg.cn_medium,
                             p_category              => 'DATA_DERIVATION',
                             p_error_text            => 'Expense CCID-Depreciation Account Derivation Error',
                             p_record_identifier_1   => p_transaction_rec.record_number,
                             p_record_identifier_2   => p_transaction_rec.mtl_txn_id,
                             p_record_identifier_3   => p_transaction_rec.organization_id);
    end xx_get_deprn_exp_ccid;
    --Derive Asset Attributes
    procedure xx_fa_derive_asset_attribs(p_transaction_tbl in out nocopy transaction_tbl) is
        l_asset_description        varchar2(80);
        l_trxn_tbl                 transaction_tbl;
        l_asset_cost               number;
        l_asset_unit_cost          number;
        l_asset_category           varchar2(240);
        l_asset_category_id        number;
        l_default_group_asset_id   number;
        l_book_type_code           varchar2(30);
        l_deprn_expense_ccid       number;
        l_payables_ccid            number;
        l_tag_number               varchar2(15);
        l_txn_ou_context           varchar2(10);
        l_ou_name                  varchar2(50);
        l_major_cat                varchar2(30);
        l_minor_cat                varchar2(30);
        l_location_id              number;
        l_completed_qty            number;
        l_dpis                     date;
        l_trf_organization_id      number;
        l_dprn_seg2                varchar2(100);
    begin
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'inside xx_fa_derive_asset_attribs');
        l_trxn_tbl := p_transaction_tbl;
        
        if l_trxn_tbl.count > 0 then
            for l_ind in l_trxn_tbl.first .. l_trxn_tbl.last loop
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '***Asset Attributes Derivation***');
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  Transaction Id  : ' || l_trxn_tbl(l_ind).mtl_txn_id);
                -- asset description
                if upper(l_trxn_tbl(l_ind).item_type) = upper(g_surg_item_type) then
                    l_asset_description := l_trxn_tbl(l_ind).wrk_order_num || '-' || l_trxn_tbl(l_ind).item || '-' || l_trxn_tbl
                                           (l_ind).organization_code;
                else
                    l_asset_description := l_trxn_tbl(l_ind).item || '-' || l_trxn_tbl(l_ind).txn_reference || '-' || l_trxn_tbl
                                           (l_ind).mtl_txn_id || '-' || l_trxn_tbl(l_ind).organization_code;
                end if;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  l_asset_description  : ' || l_asset_description);
                -- asset unit cost
                begin
                    if upper(l_trxn_tbl(l_ind).item_type) = upper(g_surg_item_type)
                       and l_trxn_tbl(l_ind).wip_entity_id is not null then
                        select quantity_completed
                          into l_completed_qty
                          from wip_discrete_jobs
                         where wip_entity_id = l_trxn_tbl(l_ind).wip_entity_id;
                        select round((sum(nvl(abs(cstd.base_transaction_value), 0)) / l_completed_qty), 2)
                          into l_asset_unit_cost
                          from cst_distribution_v cstd, gl_code_combinations_kfv gl
                         where     1 = 1
                               and cstd.wip_entity_id = l_trxn_tbl(l_ind).wip_entity_id
                               and cstd.reference_account = gl.code_combination_id
                               and gl.segment3 = '163010'
                               and cstd.transaction_type_name='WIP Issue';                               
                    /*    SELECT SUM(NVL(cstd.unit_cost,0)*wro.quantity_per_assembly)
                          INTO l_asset_unit_cost
                  FROM cst_distribution_v cstd,
                       wip_requirement_operations wro,
                       mtl_system_items_b msib,
                       fnd_common_lookups fnd
                 WHERE 1=1
                   AND NVL(fnd.start_date_active,SYSDATE)<=SYSDATE
                   AND NVL(fnd.end_date_active,SYSDATE)>=SYSDATE
                   AND fnd.enabled_flag ='Y'
                   AND fnd.lookup_type='ITEM_TYPE'
                   AND fnd.meaning = 'Tools/ Instruments'
                   AND fnd.lookup_code = msib.item_type
                   AND msib.organization_id = cstd.organization_id
                   AND msib.inventory_item_id = cstd.inventory_item_id
                   AND wro.organization_id = cstd.organization_id
                   AND wro.inventory_item_id = cstd.inventory_item_id
                   AND wro.wip_entity_id = cstd.wip_entity_id
                   AND cstd.line_type_name = 'WIP valuation'
                           AND cstd.wip_entity_id = l_trxn_tbl(l_ind).wip_entity_id;*/
                    elsif (l_trxn_tbl(l_ind).item_type) = 'Tools/ Instruments' then
                    select transfer_organization_Id into l_trf_organization_id
                    from mtl_material_transactions
                    where transaction_id=l_trxn_tbl(l_ind).mtl_txn_id;
                        select /*+ leading( d ) */
                              sum(accounted_dr),a.code_combination_id
                          into l_asset_unit_cost,l_payables_ccid
                          from xla_ae_lines a,
                               xla_ae_headers b,
                               xla_events c,
                               xla_transaction_entities_upg d
                         where     a.ae_header_id = b.ae_header_id
                               and b.event_id = c.event_id
                               and c.entity_id = d.entity_id
                               and a.accounting_class_code = 'PURCHASE_PRICE_VARIANCE'
                               and d.ledger_id = (select set_of_books_id
                                                    from cst_organization_definitions
                                                   where organization_id = l_trf_organization_id)
                               and d.application_id = 707
                               and d.entity_code = 'MTL_ACCOUNTING_EVENTS'
                               and nvl(source_id_int_1, -99) = l_trxn_tbl(l_ind).mtl_txn_id
                               and nvl(source_id_int_2, -99) = l_trf_organization_id
                               group by a.code_combination_id;
                    elsif l_trxn_tbl(l_ind).mtl_txn_type ='INTG Pool Issue to FA' then
                        begin
                         select nvl(attribute11, '2001')
                  into l_dprn_seg2
                  from mtl_material_transactions
                 where transaction_id = l_trxn_tbl(l_ind).mtl_txn_id;
                        select abs(round((nvl(mmt.actual_cost, 0)*primary_quantity),2))
                          into l_asset_unit_cost
                          from mtl_material_transactions mmt
                         where  transaction_id=l_trxn_tbl(l_ind).mtl_txn_id;
                         exception when others then
                         l_asset_unit_cost:=0;
                         end;
                    end if;
                exception
                    when others then
                        l_trxn_tbl(l_ind).derivation_flag := g_error_flag;
                        l_trxn_tbl(l_ind).error_message := l_trxn_tbl(l_ind).error_message || 'Asset Unit Cost Derivation Error|';
                        xx_emf_pkg.error(p_severity              => xx_emf_cn_pkg.cn_medium,
                                         p_category              => 'DATA_DERIVATION',
                                         p_error_text            => 'Asset Unit Cost Derivation Error',
                                         p_record_identifier_1   => l_trxn_tbl(l_ind).record_number,
                                         p_record_identifier_2   => l_trxn_tbl(l_ind).mtl_txn_id,
                                         p_record_identifier_3   => l_trxn_tbl(l_ind).organization_id);
                end;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  l_asset_unit_cost  : ' || l_asset_unit_cost);
                --Check for surgical kits
                if upper(l_trxn_tbl(l_ind).item_type) = upper(g_surg_item_type) then
                    l_major_cat := nvl(xx_emf_pkg.get_paramater_value('XXFAINVASSTCREATE', 'SURG_MAJ_CAT'), 'SURGICAL KITS');
                    begin
                        l_minor_cat := 'NONE';
                    /*SELECT mcat.segment2
                      INTO l_minor_cat
                      FROM mtl_item_categories  micat,
                             mtl_category_sets mcats,
                             mtl_categories mcat
                     WHERE mcats.category_set_name = NVL(xx_emf_pkg.get_paramater_value('XXFAINVASSTCREATE','CAT_SET_FIN'),'Financial Reporting')
                         AND micat.category_set_id = mcats.category_set_id
                         AND micat.category_id = mcat.category_id
                         AND micat.inventory_item_id = l_trxn_tbl(l_ind).inventory_item_id
                       AND micat.organization_id = NVL(xx_emf_pkg.get_paramater_value('XXFAINVASSTCREATE','MASTER_ORG_ID'),83);
                 EXCEPTION
                    WHEN OTHERS THEN
                       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while fetching l_minor_cat');
                       l_trxn_tbl(l_ind).derivation_flag := g_error_flag;
                       l_trxn_tbl(l_ind).error_message := l_trxn_tbl(l_ind).error_message||'Asset Category Id Derivation Error|';
                       xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => 'DATA_DERIVATION',
                         p_error_text               => 'Asset Category Id Derivation Error',
                         p_record_identifier_1      => l_trxn_tbl(l_ind).record_number,
                         p_record_identifier_2      => l_trxn_tbl(l_ind).mtl_txn_id,
                         p_record_identifier_3      => l_trxn_tbl(l_ind).organization_id
                                      );*/
                    end;
                --Check for Pool
                 elsif l_trxn_tbl(l_ind).item_type = 'Tools/ Instruments' then
                    l_major_cat := nvl(xx_emf_pkg.get_paramater_value('XXFAINVASSTCREATE', 'POOL_MAJ_CAT'), 'POOL');
                    l_minor_cat := nvl(xx_emf_pkg.get_paramater_value('XXFAINVASSTCREATE', 'POOL_MIN_CAT'), 'NONE');
                elsif (l_trxn_tbl(l_ind).mtl_txn_type = 'INTG Pool Issue to FA' AND nvl(l_dprn_seg2,'2001')='2001') then
                    l_major_cat := 'DEMO';
                    l_minor_cat := nvl(xx_emf_pkg.get_paramater_value('XXFAINVASSTCREATE', 'POOL_MIN_CAT'), 'NONE');
                elsif (l_trxn_tbl(l_ind).mtl_txn_type = 'INTG Pool Issue to FA' AND nvl(l_dprn_seg2,'2001')<>'2001') then
                    l_major_cat := nvl(xx_emf_pkg.get_paramater_value('XXFAINVASSTCREATE', 'POOL_MAJ_CAT'), 'POOL');
                    l_minor_cat := nvl(xx_emf_pkg.get_paramater_value('XXFAINVASSTCREATE', 'POOL_MIN_CAT'), 'NONE');    
                end if;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  l_major_cat  : ' || l_major_cat);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  l_minor_cat  : ' || l_minor_cat);
                -- asset category, asset category id
                if l_major_cat is not null and l_minor_cat is not null then
                    begin
                        select fcb.category_id, fcb.segment1 || '-' || fcb.segment2 cat_seg
                          into l_asset_category_id, l_asset_category
                          from fa_categories_b fcb
                         where     fcb.segment1 || '-' || fcb.segment2 = l_major_cat || '-' || l_minor_cat
                               and fcb.enabled_flag = 'Y'
                               and fcb.date_ineffective is null;
                    exception
                        when others then
                            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Error while fetching l_asset_category_id');
                            l_trxn_tbl(l_ind).derivation_flag := g_error_flag;
                            l_trxn_tbl(l_ind).error_message := l_trxn_tbl(l_ind).error_message ||
                                                               'Asset Category Derivation Error|';
                            xx_emf_pkg.error(p_severity              => xx_emf_cn_pkg.cn_medium,
                                             p_category              => 'DATA_DERIVATION',
                                             p_error_text            => 'Asset Category Derivation Error',
                                             p_record_identifier_1   => l_trxn_tbl(l_ind).record_number,
                                             p_record_identifier_2   => l_trxn_tbl(l_ind).mtl_txn_id,
                                             p_record_identifier_3   => l_trxn_tbl(l_ind).organization_id);
                    end;
                end if;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  l_asset_category_id  : ' || l_asset_category_id);
                -- book type code
                begin
                    select ood.operating_unit
                      into l_txn_ou_context
                      from org_organization_definitions ood, mtl_material_transactions mmt
                     where     mmt.transaction_id = l_trxn_tbl(l_ind).mtl_txn_id
                           and mmt.organization_id = ood.organization_id
                           and rownum = 1;
                    select hou.name
                      into l_ou_name
                      from hr_operating_units hou
                     where hou.organization_id = l_txn_ou_context;
                    if upper(l_ou_name) = upper(g_ou_us) then
                        l_book_type_code := nvl(xx_emf_pkg.get_paramater_value('XXFAINVASSTCREATE', 'BOOK_TYPE_CODE_US'),
                                                'US INTG CORP');
                    end if;
                exception
                    when others then
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Error while fetching l_book_type_code');
                        l_trxn_tbl(l_ind).derivation_flag := g_error_flag;
                        l_trxn_tbl(l_ind).error_message := l_trxn_tbl(l_ind).error_message || 'Book Type Code Derivation Error|';
                        xx_emf_pkg.error(p_severity              => xx_emf_cn_pkg.cn_medium,
                                         p_category              => 'DATA_DERIVATION',
                                         p_error_text            => 'Book Type Code Derivation Error',
                                         p_record_identifier_1   => l_trxn_tbl(l_ind).record_number,
                                         p_record_identifier_2   => l_trxn_tbl(l_ind).mtl_txn_id,
                                         p_record_identifier_3   => l_trxn_tbl(l_ind).organization_id);
                end;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  l_book_type_code  : ' || l_book_type_code);
                -- default asset group id
                /*BEGIN
                   SELECT fcb.default_group_asset_id
                     INTO l_default_group_asset_id
                     FROM fa_category_books fcb
                    WHERE fcb.category_id = l_asset_category_id
                      AND fcb.book_type_code = l_book_type_code;
                EXCEPTION
                WHEN OTHERS THEN
                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while fetching l_default_group_asset_id');
                   l_trxn_tbl(l_ind).derivation_flag := g_error_flag;
                   l_trxn_tbl(l_ind).error_message := l_trxn_tbl(l_ind).error_message||'Asset Group Id Derivation Error|';
                   xx_emf_pkg.error
                                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                                   p_category                 => 'DATA_DERIVATION',
                                   p_error_text               => 'Asset Group Id Derivation Error',
                                   p_record_identifier_1      => l_trxn_tbl(l_ind).record_number,
                                   p_record_identifier_2      => l_trxn_tbl(l_ind).mtl_txn_id,
                                   p_record_identifier_3      => l_trxn_tbl(l_ind).organization_id
                                  );
                END;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'  l_default_group_asset_id  : '||l_default_group_asset_id);*/
                -- get payables ccid
                begin
                    if upper(l_trxn_tbl(l_ind).item_type) = upper(g_surg_item_type) then
                        select material_variance_account
                          into l_payables_ccid
                          from wip_discrete_jobs
                         where wip_entity_id = l_trxn_tbl(l_ind).wip_entity_id;
                    elsif l_trxn_tbl(l_ind).mtl_txn_type = 'INTG Pool Issue to FA' then
                        select reference_account
                          into l_payables_ccid
                          from mtl_transaction_accounts
                         where     transaction_id = l_trxn_tbl(l_ind).mtl_txn_id
                               and inventory_item_id = l_trxn_tbl(l_ind).inventory_item_id
                               and organization_id = l_trxn_tbl(l_ind).organization_id
                               and accounting_line_type = 2;
                    end if;
                exception
                    when others then
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Error while fetching l_payables_ccid');
                        l_trxn_tbl(l_ind).derivation_flag := g_error_flag;
                        l_trxn_tbl(l_ind).error_message := l_trxn_tbl(l_ind).error_message || 'Payables CCID Derivation Error|';
                        xx_emf_pkg.error(p_severity              => xx_emf_cn_pkg.cn_medium,
                                         p_category              => 'DATA_DERIVATION',
                                         p_error_text            => 'Payables CCID Derivation Error',
                                         p_record_identifier_1   => l_trxn_tbl(l_ind).record_number,
                                         p_record_identifier_2   => l_trxn_tbl(l_ind).mtl_txn_id,
                                         p_record_identifier_3   => l_trxn_tbl(l_ind).organization_id);
                end;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  l_payables_ccid  : ' || l_payables_ccid);
                l_trxn_tbl(l_ind).payables_ccid := l_payables_ccid;
                -- Location Id
                begin
                    select location_id
                      into l_location_id
                      from fa_locations fl
                     where fl.attribute1 = l_trxn_tbl(l_ind).organization_id and fl.enabled_flag = 'Y';
                exception
                    when others then
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Error while fetching l_location_id');
                        l_trxn_tbl(l_ind).derivation_flag := g_error_flag;
                        l_trxn_tbl(l_ind).error_message := l_trxn_tbl(l_ind).error_message || 'Location Id Derivation Error|';
                        xx_emf_pkg.error(p_severity              => xx_emf_cn_pkg.cn_medium,
                                         p_category              => 'DATA_DERIVATION',
                                         p_error_text            => 'Location Id Derivation Error',
                                         p_record_identifier_1   => l_trxn_tbl(l_ind).record_number,
                                         p_record_identifier_2   => l_trxn_tbl(l_ind).mtl_txn_id,
                                         p_record_identifier_3   => l_trxn_tbl(l_ind).organization_id);
                end;
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  l_location_id  : ' || l_location_id);
                xx_get_deprn_exp_ccid(l_asset_category_id, l_book_type_code, l_trxn_tbl(l_ind), l_deprn_expense_ccid);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  l_deprn_expense_ccid  : ' || l_deprn_expense_ccid);
                --Asset Cost
                l_asset_cost := nvl(l_trxn_tbl(l_ind).asset_quantity, 0) * nvl(l_asset_unit_cost, 0);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  l_asset_cost  : ' || l_asset_cost);
                --l_trxn_tbl(l_ind).group_asset_id         := l_default_group_asset_id;
                l_trxn_tbl(l_ind).asset_type := nvl(xx_emf_pkg.get_paramater_value('XXFAINVASSTCREATE', 'ASSET_TYPE'),
                                                    'CAPITALIZED');
                l_trxn_tbl(l_ind).asset_description := l_asset_description;
                l_trxn_tbl(l_ind).asset_unit_cost := l_asset_unit_cost;
                l_trxn_tbl(l_ind).asset_cost := l_asset_cost;
                l_trxn_tbl(l_ind).asset_category_id := l_asset_category_id;
                l_trxn_tbl(l_ind).asset_category := l_asset_category;
                l_trxn_tbl(l_ind).book_type_code := l_book_type_code;
                l_trxn_tbl(l_ind).date_placed_in_service := l_trxn_tbl(l_ind).mtl_txn_date;
                l_trxn_tbl(l_ind).asset_location_id := l_location_id;
                l_trxn_tbl(l_ind).deprn_expense_ccid := l_deprn_expense_ccid;
                l_trxn_tbl(l_ind).payables_ccid := l_payables_ccid;
                --l_trxn_tbl(l_ind).tag_number             := l_trxn_tbl(l_ind).mtl_txn_id;
                begin
                    select start_date
                      into l_dpis
                      from fa_book_controls fbc, fa_calendar_periods fcp
                     where     fbc.book_type_code = l_book_type_code
                           and fcp.calendar_type = fbc.deprn_calendar
                           and trunc(l_trxn_tbl(l_ind).mtl_txn_date) between fcp.start_date and fcp.end_date;
                exception
                    when others then
                        l_trxn_tbl(l_ind).date_placed_in_service := null;
                end;
                --If Derivation fails then set process flag to error
                if l_trxn_tbl(l_ind).derivation_flag = g_error_flag then
                    l_trxn_tbl(l_ind).process_flag := g_error_flag;
                end if;
            end loop;
        end if;
        p_transaction_tbl := l_trxn_tbl;
    exception
        when others then
            g_retcode := xx_emf_cn_pkg.cn_prc_err;
            g_errmsg := 'Error in xx_fa_derive_asset_attribs' || sqlerrm;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'retcode: ' || g_retcode || ' Error: ' || g_errmsg);
            xx_emf_pkg.error(xx_emf_cn_pkg.cn_medium,
                             xx_emf_cn_pkg.cn_tech_error,
                             xx_emf_cn_pkg.cn_exp_unhand,
                             'Unexpected error in xx_fa_derive_asset_attribs',
                             sqlerrm);
    end xx_fa_derive_asset_attribs;
    --Function to create asset key ccid
    function xx_fa_create_asset_key(p_asset_key in varchar2)
        return number is
        l_asset_key_ccid   number;
        pragma autonomous_transaction;
    begin
        insert into fa_asset_keywords(enabled_flag,
                                      code_combination_id,
                                      segment1,
                                      summary_flag,
                                      last_update_date,
                                      last_updated_by,
                                      last_update_login)
             values (
                        'Y',
                        fa_asset_keywords_s.nextval,
                        substr(p_asset_key, 1, 30),
                        'N',
                        g_last_update_date,
                        g_last_updated_by,
                        g_last_update_login);
        commit;
        --Fetch newly created ccid
        select fak.code_combination_id
          into l_asset_key_ccid
          from fa_asset_keywords fak
         where fak.enabled_flag = 'Y' and fak.segment1 = p_asset_key;
        return l_asset_key_ccid;
    exception
        when others then
            rollback;
            l_asset_key_ccid := null;
            return l_asset_key_ccid;
    end xx_fa_create_asset_key;
    --Procedure to get asset creation data
    procedure xx_fa_get_asset_data(p_from_trx_date     in            date,
                                   p_to_trx_date       in            date,
                                   p_transaction_tbl   in out nocopy transaction_tbl) is
        cursor c_trx_data is --Query for Surgical Kits
            select mmt.transaction_id,
            mmt.inventory_item_id,
            mmt.organization_id,
            mmt.transaction_type_id,
            mtt.transaction_type_name transaction_type,
            mmt.transaction_date,
            mmt.transaction_quantity,
            mmt.completion_transaction_id,
            mmt.transaction_reference,
            msib.segment1 item,
            fnd.meaning item_type,
            mut.serial_number serial_number,
            wdj.wip_entity_id,
            we.wip_entity_name wrk_order_num,
            wdj.attribute10 capex_num,
            wdj.attribute11 department
              from mtl_material_transactions mmt,
            mtl_transaction_types mtt,
            mtl_txn_source_types mts,
            mtl_system_items_b msib,
            fnd_common_lookups fnd,
            mtl_unit_transactions_all_v mut,
            wip_entities we,
            wip_discrete_jobs wdj
             where     1 = 1
            and we.wip_entity_id = wdj.wip_entity_id
            and wdj.wip_entity_id = mmt.transaction_source_id
            and wdj.organization_id = mmt.organization_id
            and wdj.primary_item_id = mmt.inventory_item_id
            and mut.transaction_id = mmt.transaction_id
            and mtt.transaction_source_type_id = mts.transaction_source_type_id
            --AND mts.transaction_source_type_name = 'Job'
            and mts.transaction_source_type_id = mmt.transaction_source_type_id
            and mtt.transaction_source_type_id = mmt.transaction_source_type_id
            and mtt.transaction_type_name = 'WIP Completion'
            and mtt.transaction_type_id = mmt.transaction_type_id
            and mmt.inventory_item_id = msib.inventory_item_id
            and mmt.organization_id = msib.organization_id
            and fnd.lookup_code = msib.item_type
            and fnd.meaning = 'Surgical Kit'
            and nvl(fnd.start_date_active, sysdate) <= sysdate
            and nvl(fnd.end_date_active, sysdate) >= sysdate
            and fnd.enabled_flag = 'Y'
            and fnd.lookup_type = 'ITEM_TYPE'
            --AND NOT EXISTS (SELECT 'Y' FROM fa_additions_b faab WHERE faab.tag_number = mut.serial_number)
            and not exists
                (  select 1
                     from xx_fa_inv_asset_data_stg
                    where mmt.transaction_id = mtl_txn_id and process_flag = 'P')
            and exists
                (  select 'X' --Check for GL Transfer
                     from xla_ae_headers xah, xla_distribution_links xdl
                    where     xah.ae_header_id = xdl.ae_header_id
            and xdl.application_id = 707
            and xah.gl_transfer_status_code = 'Y'
            and xah.gl_transfer_date is not null
            and xdl.source_distribution_type = 'MTL_TRANSACTION_ACCOUNTS'
            and xdl.source_distribution_id_num_1 in
                (         select mta.inv_sub_ledger_id
                            from mtl_transaction_accounts mta
                           where     mta.transaction_id = mmt.transaction_id
            and mta.inventory_item_id = mmt.inventory_item_id
            and mta.organization_id = mmt.organization_id))
            and mmt.transaction_date between p_from_trx_date and p_to_trx_date
            union --Query for CUSA Loaners
            select mmt.transaction_id,
            mmt.inventory_item_id,
            mmt.organization_id,
            mmt.transaction_type_id,
            mtt.transaction_type_name transaction_type,
            mmt.transaction_date,
            mmt.transaction_quantity,
            mmt.completion_transaction_id,
            mmt.transaction_reference,
            msib.segment1 item,
            fnd.meaning item_type,
            mut.serial_number serial_number,
            null wip_entity_id,
            null wrk_order_num,
            mmt.attribute10 capex_num,
            mmt.attribute11 department
              from mtl_material_transactions mmt,
            mtl_transaction_types mtt,
            mtl_txn_source_types mts,
            mtl_system_items_b msib,
            fnd_common_lookups fnd,
            mtl_unit_transactions_all_v mut
             where     1 = 1
            and mut.transaction_id = mmt.transaction_id
            and mtt.transaction_source_type_id = mts.transaction_source_type_id
            --AND mts.transaction_source_type_name = 'Inventory'
            and mts.transaction_source_type_id = mmt.transaction_source_type_id
            and mtt.transaction_source_type_id = mmt.transaction_source_type_id
            and mtt.transaction_type_name = 'INTG Pool Issue to FA'
            and mtt.transaction_type_id = mmt.transaction_type_id
            and mmt.inventory_item_id = msib.inventory_item_id
            and mmt.organization_id = msib.organization_id
            and fnd.lookup_code = msib.item_type
            --AND fnd.meaning IN ('Pool')
            and nvl(fnd.start_date_active, sysdate) <= sysdate
            and nvl(fnd.end_date_active, sysdate) >= sysdate
            and fnd.enabled_flag = 'Y'
            and fnd.lookup_type = 'ITEM_TYPE'
            --AND NOT EXISTS (SELECT 'Y' FROM fa_additions_b faab WHERE faab.tag_number = mut.serial_number)
            and not exists
                (  select 1
                     from xx_fa_inv_asset_data_stg
                    where mmt.transaction_id = mtl_txn_id and process_flag = 'P')
            and exists
                (  select 'X' --Check for GL Transfer
                     from xla_ae_headers xah, xla_distribution_links xdl
                    where     xah.ae_header_id = xdl.ae_header_id
            and xdl.application_id = 707
            and xah.gl_transfer_status_code = 'Y'
            and xah.gl_transfer_date is not null
            and xdl.source_distribution_type = 'MTL_TRANSACTION_ACCOUNTS'
            and xdl.source_distribution_id_num_1 in
                (         select mta.inv_sub_ledger_id
                            from mtl_transaction_accounts mta
                           where     mta.transaction_id = mmt.transaction_id
            and mta.inventory_item_id = mmt.inventory_item_id
            and mta.organization_id = mmt.organization_id))
            and mmt.transaction_date between p_from_trx_date and p_to_trx_date
            union --Query for Loose Instruments
             select mmt.transaction_id,
            mmt.inventory_item_id,
            mmt.organization_id,
            mmt.transaction_type_id,
            mtt.transaction_type_name transaction_type,
            mmt.transaction_date,
            mmt.transaction_quantity,
            mmt.completion_transaction_id,
            mmt.transaction_reference,
            msib.segment1 item,
            fnd.meaning item_type,
            --mut.serial_number serial_number,
            null serial_number,
            null wip_entity_id,
            null wrk_order_num,
            mmt.attribute10 capex_num,
            mmt.attribute11 department
              from mtl_material_transactions mmt,
            mtl_transaction_types mtt,
            mtl_system_items_b msib,
            fnd_common_lookups fnd
            --mtl_unit_transactions_all_v mut
             where     1 = 1
            --and mut.transaction_id(+) = mmt.transaction_id
           -- and mtt.transaction_source_type_id = mts.transaction_source_type_id
            --AND mts.transaction_source_type_name = 'Inventory'
           -- and mts.transaction_source_type_id = mmt.transaction_source_type_id
           -- and mtt.transaction_source_type_id = mmt.transaction_source_type_id
            and mtt.transaction_type_name = 'Int Order Intr Ship'
            --and mtt.transaction_type_id=61
            and mtt.transaction_type_id = mmt.transaction_type_id
            and mmt.inventory_item_id = msib.inventory_item_id
            and mmt.organization_id = msib.organization_id
            and fnd.lookup_code = msib.item_type
            and fnd.meaning ='Tools/ Instruments'
            and nvl(fnd.start_date_active, sysdate) <= sysdate
            and nvl(fnd.end_date_active, sysdate) >= sysdate
            and fnd.enabled_flag = 'Y'
            and fnd.lookup_type = 'ITEM_TYPE'
            --AND NOT EXISTS (SELECT 'Y' FROM fa_additions_b faab WHERE faab.tag_number = mut.serial_number)
            and not exists
                (  select 1
                     from xx_fa_inv_asset_data_stg
                    where mmt.transaction_id = mtl_txn_id
                    and process_flag='P')
            /*AND NOT EXISTS ( SELECT stg.asset_number
                               FROM xx_fa_inv_asset_data_stg stg
                              WHERE stg.mtl_txn_id = mmt.transaction_id
                                AND stg.organization_id = mmt.organization_id
                                AND ( stg.serial_number = mut.serial_number OR stg.serial_number IS NULL )
                                AND stg.process_flag = 'P' )*/
            and exists
                (  select 'X' --Check for GL Transfer
                     from xla_ae_headers xah, xla_distribution_links xdl
                    where     xah.ae_header_id = xdl.ae_header_id
            and xdl.application_id = 707
            and xah.gl_transfer_status_code = 'Y'
            and xah.gl_transfer_date is not null
            and xdl.source_distribution_type = 'MTL_TRANSACTION_ACCOUNTS'
            and xdl.source_distribution_id_num_1 in
                (         select mta.inv_sub_ledger_id
                            from mtl_transaction_accounts mta
                           where     mta.transaction_id = mmt.transaction_id
            and mta.inventory_item_id = mmt.inventory_item_id
            and mta.organization_id = mmt.organization_id))
            and mmt.transaction_date between p_from_trx_date and p_to_trx_date;
        l_inventory_item_id      number;
        l_organization_id        number;
        l_serial_code            number;
        l_primary_uom_code       varchar2(6);
        l_asset_creation_code    varchar2(10);
        l_eam_item_type          number;
        l_location_type_code     varchar2(30);
        l_asset_quantity         number;
        l_serial_number          number;
        l_lot_number             number;
        l_depreciable_flag       varchar2(10);
        l_inventory_asset_flag   varchar2(10);
        l_item                   varchar2(80);
        l_item_description       varchar2(240);
        l_org_code               varchar2(30);
        l_record_number          number;
        l_asset_key_ccid         number;
        l_rec_num_exits          number;
        l_trxn_tbl               transaction_tbl;
        l_ind                    binary_integer := 0;
    begin
        l_ind := 0;
        for r_trx_data in c_trx_data loop
            l_record_number := xx_fa_asset_rec_num_seq.nextval;
            l_ind := l_ind + 1;
            --Set Process Falg to Ready
            l_trxn_tbl(l_ind).process_flag := g_ready_flag;
            l_trxn_tbl(l_ind).record_number := l_record_number;
            l_rec_num_exits := null;
            begin
                select record_number
                  into l_rec_num_exits
                  from xx_fa_inv_asset_data_stg
                 where     mtl_txn_id = r_trx_data.transaction_id
                       and organization_id = r_trx_data.organization_id
                       and (serial_number = r_trx_data.serial_number or serial_number is null)
                       and (derivation_flag = g_error_flag or process_flag = g_error_flag or process_flag = g_ready_flag);
                if l_rec_num_exits is not null then
                    delete from xx_fa_inv_asset_data_stg
                          where record_number = l_rec_num_exits;
                    commit;
                end if;
            exception
                when others then
                    null;
            end;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, ' ******Deriving Values*********');
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  transaction_id     : ' || r_trx_data.transaction_id);
            -- Item Details
            begin
                select primary_uom_code, description, segment1
                  into l_primary_uom_code, l_item_description, l_item
                  from mtl_system_items_b
                 where inventory_item_id = r_trx_data.inventory_item_id and organization_id = r_trx_data.organization_id;
            exception
                when others then
                    l_trxn_tbl(l_ind).derivation_flag := g_error_flag;
                    l_trxn_tbl(l_ind).error_message := l_trxn_tbl(l_ind).error_message || 'Item Details Derivation Error|';
                    xx_emf_pkg.error(p_severity              => xx_emf_cn_pkg.cn_medium,
                                     p_category              => 'DATA_DERIVATION',
                                     p_error_text            => 'Item Details Derivation Error',
                                     p_record_identifier_1   => l_trxn_tbl(l_ind).record_number,
                                     p_record_identifier_2   => r_trx_data.transaction_id,
                                     p_record_identifier_3   => r_trx_data.organization_id);
            end;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  inventory_item_id      : ' || r_trx_data.inventory_item_id);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  organization_id        : ' || r_trx_data.organization_id);
            /*IF nvl(l_asset_creation_code,'0') in ('1', 'Y') THEN
              l_depreciable_flag := 'YES';
            ELSE
              l_depreciable_flag := 'NO';
            END IF;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'  asset_creation_code    : '||l_asset_creation_code);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'  depreciable_flag       : '||l_depreciable_flag);*/
            -- Organization Code
            begin
                select ood.organization_code
                  into l_org_code
                  from org_organization_definitions ood
                 where organization_id = r_trx_data.organization_id;
            exception
                when others then
                    l_trxn_tbl(l_ind).derivation_flag := g_error_flag;
                    l_trxn_tbl(l_ind).error_message := l_trxn_tbl(l_ind).error_message || 'Org Code Derivation Error|';
                    xx_emf_pkg.error(p_severity              => xx_emf_cn_pkg.cn_medium,
                                     p_category              => 'DATA_DERIVATION',
                                     p_error_text            => 'Org Code Derivation Error',
                                     p_record_identifier_1   => l_trxn_tbl(l_ind).record_number,
                                     p_record_identifier_2   => r_trx_data.transaction_id,
                                     p_record_identifier_3   => r_trx_data.organization_id);
            end;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  l_org_code             : ' || l_org_code);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  item_name              : ' || l_item);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  item_description       : ' || l_item_description);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  mtl_txn_id             : ' || r_trx_data.transaction_id);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  mtl_txn_type_id        : ' || r_trx_data.transaction_type_id);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  mtl_txn_type_name      : ' || r_trx_data.transaction_type);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  mtl_txn_date           : ' || r_trx_data.transaction_date);
            l_location_type_code := 'INVENTORY';
            if (upper(r_trx_data.item_type) = upper(g_surg_item_type) or l_trxn_tbl(l_ind).mtl_txn_type = 'INTG Pool Issue to FA') then
                l_asset_quantity := 1;
            else
                l_asset_quantity := abs(r_trx_data.transaction_quantity);
            end if;
            --Derive asset key ccid
            if r_trx_data.capex_num is not null then
                begin
                    select fak.code_combination_id
                      into l_asset_key_ccid
                      from fa_asset_keywords fak
                     where fak.enabled_flag = 'Y' and fak.segment1 = r_trx_data.capex_num;
                exception
                    when no_data_found then
                        l_asset_key_ccid := xx_fa_create_asset_key(r_trx_data.capex_num);
                    when others then
                        l_asset_key_ccid := null;
                end;
            end if;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  Asset Key CCID             : ' || l_asset_key_ccid);
            l_trxn_tbl(l_ind).mtl_txn_id := r_trx_data.transaction_id;
            l_trxn_tbl(l_ind).mtl_txn_date := r_trx_data.transaction_date;
            l_trxn_tbl(l_ind).mtl_txn_qty := r_trx_data.transaction_quantity;
            l_trxn_tbl(l_ind).mtl_txn_type := r_trx_data.transaction_type;
            l_trxn_tbl(l_ind).compl_txn_id := r_trx_data.completion_transaction_id;
            l_trxn_tbl(l_ind).txn_reference := r_trx_data.transaction_reference;
            l_trxn_tbl(l_ind).capex_number := r_trx_data.capex_num;
           -- l_trxn_tbl(l_ind).department := r_trx_data.department;
            l_trxn_tbl(l_ind).asset_quantity := abs(l_asset_quantity);
            l_trxn_tbl(l_ind).inventory_item_id := r_trx_data.inventory_item_id;
            l_trxn_tbl(l_ind).organization_id := r_trx_data.organization_id;
            l_trxn_tbl(l_ind).wip_entity_id := r_trx_data.wip_entity_id;
            l_trxn_tbl(l_ind).wrk_order_num := r_trx_data.wrk_order_num;
            l_trxn_tbl(l_ind).asset_key_ccid := l_asset_key_ccid;
            l_trxn_tbl(l_ind).organization_code := l_org_code;
            l_trxn_tbl(l_ind).item := l_item;
            l_trxn_tbl(l_ind).item_description := l_item_description;
            l_trxn_tbl(l_ind).item_type := r_trx_data.item_type;
            l_trxn_tbl(l_ind).primary_uom_code := l_primary_uom_code;
            l_trxn_tbl(l_ind).serial_number := r_trx_data.serial_number;
            l_trxn_tbl(l_ind).tag_number := substr(r_trx_data.serial_number, 1, 15);
            --l_trxn_tbl(l_ind).lot_number         := l_lot_number;
            l_trxn_tbl(l_ind).location_type_code := l_location_type_code;
            --l_trxn_tbl(l_ind).depreciable_flag   := l_depreciable_flag;
            l_trxn_tbl(l_ind).creation_date := g_creation_date;
            l_trxn_tbl(l_ind).created_by := g_created_by;
            l_trxn_tbl(l_ind).last_update_date := g_last_update_date;
            l_trxn_tbl(l_ind).last_updated_by := g_last_updated_by;
            l_trxn_tbl(l_ind).last_update_login := g_last_update_login;
            l_trxn_tbl(l_ind).request_id := g_request_id;
        end loop;
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '  l_trxn_tbl.count             : ' || l_trxn_tbl.count());
        if l_trxn_tbl.count > 0 then
            -- derive asset specific attribs
            xx_fa_derive_asset_attribs(p_transaction_tbl => l_trxn_tbl);
        end if;
        p_transaction_tbl := l_trxn_tbl;
    exception
        when others then
            g_retcode := xx_emf_cn_pkg.cn_prc_err;
            g_errmsg := 'Error in xx_fa_get_asset_data' || sqlerrm;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'retcode: ' || g_retcode || ' Error: ' || g_errmsg);
            xx_emf_pkg.error(xx_emf_cn_pkg.cn_medium,
                             xx_emf_cn_pkg.cn_tech_error,
                             xx_emf_cn_pkg.cn_exp_unhand,
                             'Unexpected error in xx_fa_get_asset_data',
                             sqlerrm);
    end xx_fa_get_asset_data;
    procedure xx_fa_create_asset_api(p_transaction_tbl in out nocopy transaction_tbl) is
        l_trans_rec             fa_api_types.trans_rec_type;
        l_dist_trans_rec        fa_api_types.trans_rec_type;
        l_asset_hdr_rec         fa_api_types.asset_hdr_rec_type;
        l_asset_desc_rec        fa_api_types.asset_desc_rec_type;
        l_asset_cat_rec         fa_api_types.asset_cat_rec_type;
        l_asset_type_rec        fa_api_types.asset_type_rec_type;
        l_asset_hierarchy_rec   fa_api_types.asset_hierarchy_rec_type;
        l_asset_fin_rec         fa_api_types.asset_fin_rec_type;
        l_asset_deprn_rec       fa_api_types.asset_deprn_rec_type;
        l_asset_dist_rec        fa_api_types.asset_dist_rec_type;
        l_asset_dist_tbl        fa_api_types.asset_dist_tbl_type;
        l_inv_rec               fa_api_types.inv_rec_type;
        l_inv_tbl               fa_api_types.inv_tbl_type;
        l_inv_rate_tbl          fa_api_types.inv_rate_tbl_type;
        l_return_status         varchar2(1);
        l_msg_count             number;
        l_msg_data              varchar2(4000);
        l_msg                   varchar2(4000);
        l_msg_index_out         number;
        l_trxn_tbl              transaction_tbl;
    begin
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Inside xx_fa_create_asset_api');
        l_trxn_tbl := p_transaction_tbl;
        fa_srvr_msg.init_server_message;
        if l_trxn_tbl.count > 0 then
            for l_ind in l_trxn_tbl.first .. l_trxn_tbl.last loop
                l_trans_rec.transaction_header_id := null;
                l_trans_rec.transaction_type_code := null;
                l_trans_rec.transaction_date_entered := null;
                l_trans_rec.transaction_name := null;
                l_trans_rec.source_transaction_header_id := null;
                l_trans_rec.mass_reference_id := null;
                l_trans_rec.transaction_subtype := null;
                l_trans_rec.transaction_key := null;
                l_trans_rec.amortization_start_date := null;
                l_trans_rec.calling_interface := 'CUSTOM';
                l_trans_rec.mass_transaction_id := null;
                l_trans_rec.deprn_override_flag := 'N';
                l_trans_rec.member_transaction_header_id := null;
                l_trans_rec.trx_reference_id := null;
                l_trans_rec.event_id := null;
                --l_dist_trans_rec        := NULL;
                l_asset_hdr_rec := null;
                l_asset_desc_rec := null;
                l_asset_cat_rec := null;
                l_asset_type_rec := null;
                --l_asset_hierarchy_rec   := NULL;
                l_asset_fin_rec := null;
                --l_asset_deprn_rec       := NULL;
                l_asset_dist_rec := null;
                l_return_status := null;
                l_msg_count := null;
                l_msg_data := null;
                l_msg := null;
                l_msg_index_out := null;
                if l_trxn_tbl(l_ind).derivation_flag is null then
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Record Number: ' || l_trxn_tbl(l_ind).record_number);
                    -- desc info
                    l_asset_desc_rec.description := l_trxn_tbl(l_ind).asset_description;
                    l_asset_desc_rec.serial_number := l_trxn_tbl(l_ind).serial_number;
                    l_asset_desc_rec.asset_key_ccid := l_trxn_tbl(l_ind).asset_key_ccid;
                    l_asset_desc_rec.tag_number := l_trxn_tbl(l_ind).tag_number;
                    -- cat info
                    l_asset_cat_rec.category_id := l_trxn_tbl(l_ind).asset_category_id;
                    --type info
                    l_asset_type_rec.asset_type := l_trxn_tbl(l_ind).asset_type;
                    -- fin info
                    l_asset_fin_rec.cost := l_trxn_tbl(l_ind).asset_cost;
                    l_asset_fin_rec.date_placed_in_service := l_trxn_tbl(l_ind).date_placed_in_service;
                    --l_asset_fin_rec.depreciate_flag               := l_trxn_tbl(l_ind).depreciable_flag;
                    --l_asset_fin_rec.group_asset_id                := l_trxn_tbl(l_ind).group_asset_id;
                    -- deprn info
                    --l_asset_deprn_rec.ytd_deprn                   := ytd
                    --l_asset_deprn_rec.deprn_reserve               := reserve
                    --l_asset_deprn_rec.bonus_ytd_deprn             := 0;
                    --l_asset_deprn_rec.bonus_deprn_reserve         := 0;
                    -- book / trans info
                    l_asset_hdr_rec.book_type_code := l_trxn_tbl(l_ind).book_type_code;
                    -- distribution info
                    l_asset_dist_rec.units_assigned := l_trxn_tbl(l_ind).asset_quantity;
                    l_asset_dist_rec.expense_ccid := l_trxn_tbl(l_ind).deprn_expense_ccid;
                    l_asset_dist_rec.location_ccid := l_trxn_tbl(l_ind).asset_location_id;
                    l_asset_dist_rec.assigned_to := null;
                    l_asset_dist_rec.transaction_units := l_trxn_tbl(l_ind).mtl_txn_qty;
                    l_asset_dist_tbl(1) := l_asset_dist_rec;
                    l_inv_rec.fixed_assets_cost:=l_trxn_tbl(l_ind).asset_cost;
                    l_inv_rec.payables_cost:=l_trxn_tbl(l_ind).asset_cost;
                    l_inv_rec.payables_code_combination_id := l_trxn_tbl(l_ind).payables_ccid;                    
                    l_inv_tbl(1) := l_inv_rec;
                    -- call the api
                    fa_addition_pub.do_addition( -- std parameters
                                                p_api_version            => 1.0,
                                                p_init_msg_list          => fnd_api.g_false,
                                                p_commit                 => fnd_api.g_false,
                                                p_validation_level       => fnd_api.g_valid_level_full,
                                                p_calling_fn             => null,
                                                x_return_status          => l_return_status,
                                                x_msg_count              => l_msg_count,
                                                x_msg_data               => l_msg_data,
                                                -- api parameters
                                                px_trans_rec             => l_trans_rec,
                                                px_dist_trans_rec        => l_dist_trans_rec,
                                                px_asset_hdr_rec         => l_asset_hdr_rec,
                                                px_asset_desc_rec        => l_asset_desc_rec,
                                                px_asset_type_rec        => l_asset_type_rec,
                                                px_asset_cat_rec         => l_asset_cat_rec,
                                                px_asset_hierarchy_rec   => l_asset_hierarchy_rec,
                                                px_asset_fin_rec         => l_asset_fin_rec,
                                                px_asset_deprn_rec       => l_asset_deprn_rec,
                                                px_asset_dist_tbl        => l_asset_dist_tbl,
                                                px_inv_tbl               => l_inv_tbl);
                    if l_return_status != fnd_api.g_ret_sts_success then
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'FAILURE');
                        l_msg := null;
                        for i in 1 .. l_msg_count loop
                            fnd_msg_pub.get(p_msg_index       => i,
                                            p_encoded         => 'F',
                                            p_data            => l_msg_data,
                                            p_msg_index_out   => l_msg_index_out);
                            l_msg := l_msg || l_msg_data;
                        end loop;
                        l_trxn_tbl(l_ind).process_flag := g_error_flag;
                        l_trxn_tbl(l_ind).error_message := l_msg;
                        xx_emf_pkg.error(p_severity              => xx_emf_cn_pkg.cn_medium,
                                         p_category              => 'DATA_PROCESS',
                                         p_error_text            => 'After fa_addition_pub.do_addition Error',
                                         p_record_identifier_1   => l_trxn_tbl(l_ind).record_number,
                                         p_record_identifier_2   => l_trxn_tbl(l_ind).mtl_txn_id,
                                         p_record_identifier_3   => l_trxn_tbl(l_ind).organization_id);
                        fnd_msg_pub.delete_msg();
                    else
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'SUCCESS');
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'ASSET_ID: ' || l_asset_hdr_rec.asset_id);
                        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'ASSET_NUMBER: ' || l_asset_desc_rec.asset_number);
                        l_trxn_tbl(l_ind).process_flag := g_process_flag;
                        l_trxn_tbl(l_ind).asset_number := l_asset_desc_rec.asset_number;
                        commit;
                    end if;
                end if; --Derivation Flag Check
            end loop;
        end if;
        p_transaction_tbl := l_trxn_tbl;
    exception
        when others then
            g_retcode := xx_emf_cn_pkg.cn_prc_err;
            g_errmsg := 'Error in xx_fa_create_asset_api' || sqlerrm;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'retcode: ' || g_retcode || ' Error: ' || g_errmsg);
            xx_emf_pkg.error(xx_emf_cn_pkg.cn_medium,
                             xx_emf_cn_pkg.cn_tech_error,
                             xx_emf_cn_pkg.cn_exp_unhand,
                             'Unexpected error in xx_fa_create_asset_api',
                             sqlerrm);
    end xx_fa_create_asset_api;
    --Procedure to insert data into stg table
    procedure xx_fa_insert_data_stg(p_transaction_tbl in transaction_tbl) is
    begin
        forall i in 1 .. p_transaction_tbl.count
            insert into xx_fa_inv_asset_data_stg
                 values p_transaction_tbl(i);
        commit;
    exception
        when others then
            g_retcode := xx_emf_cn_pkg.cn_prc_err;
            g_errmsg := 'Error in xx_fa_insert_data_stg' || sqlerrm;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'retcode: ' || g_retcode || ' Error: ' || g_errmsg);
            xx_emf_pkg.error(xx_emf_cn_pkg.cn_medium,
                             xx_emf_cn_pkg.cn_tech_error,
                             xx_emf_cn_pkg.cn_exp_unhand,
                             'Unexpected error in xx_fa_insert_data_stg',
                             sqlerrm);
    end xx_fa_insert_data_stg;
    --Procedure to update stg table
    procedure xx_fa_update_data_stg(p_transaction_tbl in transaction_tbl) is
        pragma autonomous_transaction;
    begin
        for i in 1 .. p_transaction_tbl.count loop
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, ' Inside Update Transaction Id: ' || p_transaction_tbl(i).mtl_txn_id);
            update xx_fa_inv_asset_data_stg
               set asset_number = p_transaction_tbl(i).asset_number,
                   asset_quantity = abs(p_transaction_tbl(i).asset_quantity),
                   asset_type = p_transaction_tbl(i).asset_type,
                   asset_description = p_transaction_tbl(i).asset_description,
                   asset_unit_cost = p_transaction_tbl(i).asset_unit_cost,
                   asset_cost = p_transaction_tbl(i).asset_cost,
                   asset_category = p_transaction_tbl(i).asset_category,
                   asset_category_id = p_transaction_tbl(i).asset_category_id,
                   book_type_code = p_transaction_tbl(i).book_type_code,
                   date_placed_in_service = p_transaction_tbl(i).date_placed_in_service,
                   asset_location_id = p_transaction_tbl(i).asset_location_id,
                   asset_key_ccid = p_transaction_tbl(i).asset_key_ccid,
                   deprn_expense_ccid = p_transaction_tbl(i).deprn_expense_ccid,
                   payables_ccid = p_transaction_tbl(i).payables_ccid,
                   tag_number = p_transaction_tbl(i).tag_number --,group_asset_id         = p_transaction_tbl(i).group_asset_id
                                                                --,depreciable_flag       = p_transaction_tbl(i).depreciable_flag
                   ,
                   process_flag = p_transaction_tbl(i).process_flag,
                   derivation_flag = p_transaction_tbl(i).derivation_flag,
                   error_message = p_transaction_tbl(i).error_message,
                   last_update_date = g_last_update_date,
                   last_updated_by = g_last_updated_by,
                   last_update_login = g_last_update_login
             where record_number = p_transaction_tbl(i).record_number and request_id = p_transaction_tbl(i).request_id;
        end loop;
        commit;
    exception
        when others then
            g_retcode := xx_emf_cn_pkg.cn_prc_err;
            g_errmsg := 'Error in xx_fa_update_data_stg' || sqlerrm;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'retcode: ' || g_retcode || ' Error: ' || g_errmsg);
            xx_emf_pkg.error(xx_emf_cn_pkg.cn_medium,
                             xx_emf_cn_pkg.cn_tech_error,
                             xx_emf_cn_pkg.cn_exp_unhand,
                             'Unexpected error in xx_fa_update_data_stg',
                             sqlerrm);
    end xx_fa_update_data_stg;
    --Procedure to get record count
    procedure update_record_count(p_request_id in number) is
        cursor c_get_total_cnt is
            select count(1) total_count
              from xx_fa_inv_asset_data_stg
             where request_id = p_request_id;
        cursor c_get_error_cnt is
            select count(1) error_count
              from xx_fa_inv_asset_data_stg
             where request_id = p_request_id and (derivation_flag = g_error_flag or process_flag = g_error_flag);
        cursor c_get_success_cnt is
            select count(1) success_count
              from xx_fa_inv_asset_data_stg
             where request_id = p_request_id and (process_flag = g_process_flag or nvl(derivation_flag, 'S') <> g_error_flag);
        x_total_cnt     number;
        x_error_cnt     number := 0;
        x_warn_cnt      number := 0;
        x_success_cnt   number := 0;
    begin
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium, 'In update_record_count ');
        open c_get_total_cnt;
        fetch c_get_total_cnt into x_total_cnt;
        close c_get_total_cnt;
        open c_get_error_cnt;
        fetch c_get_error_cnt into x_error_cnt;
        close c_get_error_cnt;
        open c_get_success_cnt;
        fetch c_get_success_cnt into x_success_cnt;
        close c_get_success_cnt;
        xx_emf_pkg.update_recs_cnt(p_total_recs_cnt     => x_total_cnt,
                                   p_success_recs_cnt   => x_success_cnt,
                                   p_warning_recs_cnt   => x_warn_cnt,
                                   p_error_recs_cnt     => x_error_cnt);
    exception
        when others then
            g_retcode := xx_emf_cn_pkg.cn_prc_err;
            g_errmsg := 'Error in update_record_count' || sqlerrm;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'retcode: ' || g_retcode || ' Error: ' || g_errmsg);
            xx_emf_pkg.error(xx_emf_cn_pkg.cn_low,
                             xx_emf_cn_pkg.cn_tech_error,
                             xx_emf_cn_pkg.cn_exp_unhand,
                             'Unexpected error in update_record_count',
                             sqlerrm);
    end update_record_count;
    --Procedure to fetch process param values
    procedure xx_fa_get_process_param_val is
        x_process_name   varchar2(25) := 'XXFAINVASSTCREATE';
    begin
        --Fetch value from process setup
        xx_intg_common_pkg.get_process_param_value(x_process_name, 'POOL_ITEM_TYPE', g_pool_item_type);
        --Fetch value from process setup
        xx_intg_common_pkg.get_process_param_value(x_process_name, 'SURG_ITEM_TYPE', g_surg_item_type);
        --g_instr_item_type:='Tools/ Instruments';
        xx_intg_common_pkg.get_process_param_value(x_process_name, 'ORG_NAME_US', g_ou_us);
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'g_pool_item_type : ' || g_pool_item_type);
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'g_surg_item_type : ' || g_surg_item_type);
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'g_ou_us : ' || g_ou_us);
    exception
        when others then
            g_retcode := xx_emf_cn_pkg.cn_prc_err;
            g_errmsg := 'Error in xx_fa_get_process_param_val' || sqlerrm;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'retcode: ' || g_retcode || ' Error: ' || g_errmsg);
            xx_emf_pkg.error(xx_emf_cn_pkg.cn_low,
                             xx_emf_cn_pkg.cn_tech_error,
                             xx_emf_cn_pkg.cn_exp_unhand,
                             'Unexpected error in xx_fa_get_process_param_val',
                             sqlerrm);
    end xx_fa_get_process_param_val;
    --Main Procedure
    procedure main(errbuf               out varchar2,
                   retcode              out varchar2,
                   p_from_trx_date   in     varchar2,
                   p_to_trx_date     in     varchar2,
                   p_run_mode        in     varchar2,
                   p_request_id      in     number,
                   p_disp_trx        in     varchar2,
                   p_capex_num       in     varchar2) is
        l_application     varchar2(10) := 'XXINTG';
        l_program_name    varchar2(30) := 'XXFAINVCASSETRPT';
        l_program_desc    varchar2(100) := 'INTG Asset Creation for Kits and Loaner Pools Report';
        l_rpt_reqid       number;
        l_template_code   varchar2(30) := 'XXFAINVCASSETRPT';
        l_layout_status   boolean := false;
        l_ter             fnd_languages.iso_territory%type := 'US';
        l_lang            fnd_languages.iso_language%type := 'en';
        l_error_code      number;
        l_request_id      number;
        l_disp_trx        varchar2(30);
        l_date_from       date;
        l_date_to         date;
        l_trxn_tbl        transaction_tbl;
    begin
        --Main Procedure
        begin
            retcode := xx_emf_cn_pkg.cn_success;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Before Setting Environment');
            -- Set the environment
            l_error_code := xx_emf_pkg.set_env;
        exception
            when others then
                raise xx_emf_pkg.g_e_env_not_set;
        end;
        g_retcode := xx_emf_cn_pkg.cn_success;
        l_request_id := p_request_id;
        if p_disp_trx is not null then
            l_disp_trx := p_disp_trx;
        else
            l_disp_trx := 'All';
        end if;
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '********************Program Parameters****************');
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Period Date From: ' || p_from_trx_date);
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Period Date To: ' || p_to_trx_date);
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Run Mode: ' || p_run_mode);
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Request Id: ' || p_request_id);
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Show transactions: ' || p_disp_trx);
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '******************************************************');
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Current Run request_id: ' || g_request_id);
        if l_request_id is null then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Before Call xx_hr_get_process_param_val');
            --Procedure to fetch process setup values
            xx_fa_get_process_param_val;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'After Call xx_hr_get_process_param_val');
            l_date_from := trunc(to_date(p_from_trx_date, 'YYYY-MM-DD HH24:MI:SS'));
            l_date_to := trunc(to_date(p_to_trx_date, 'YYYY-MM-DD HH24:MI:SS'))+.9999;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Date From: ' || l_date_from);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Date To: ' || l_date_to);
           --Call procedure to get trx asset data
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Before Call xx_fa_get_asset_data');
            xx_fa_get_asset_data(l_date_from, l_date_to, l_trxn_tbl);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'After xx_fa_get_asset_data g_retcode: ' || g_retcode);
            xx_emf_pkg.propagate_error(g_retcode);
            --Call procedure to insert into staging table
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Before Call xx_fa_insert_data_stg');
            xx_fa_insert_data_stg(l_trxn_tbl);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'After xx_fa_insert_data_stg g_retcode: ' || g_retcode);
            xx_emf_pkg.propagate_error(g_retcode);
            if p_run_mode = 'Create' then
                --Call procedure to create asset
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Before Call xx_fa_create_asset_api');
                xx_fa_create_asset_api(l_trxn_tbl);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'After xx_fa_create_asset_api g_retcode: ' || g_retcode);
                xx_emf_pkg.propagate_error(g_retcode);
                l_request_id := g_request_id;
                l_disp_trx := 'All';
            end if;
            --Call procedure to update staging table
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Before Call xx_fa_update_data_stg');
            xx_fa_update_data_stg(l_trxn_tbl);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'After xx_fa_update_data_stg g_retcode: ' || g_retcode);
            xx_emf_pkg.propagate_error(g_retcode);
            --Update error record count
            update_record_count(g_request_id);
            --Generate error report
            xx_emf_pkg.create_report;
        end if;
        if l_request_id is not null then
            fnd_global.apps_initialize(g_user_id --User id
                                                , g_resp_id --responsibility_id
                                                           , g_resp_appl_id); --application_id
            l_layout_status := fnd_request.add_layout(template_appl_name   => l_application,
                                                      template_code        => l_template_code,
                                                      template_language    => l_lang,
                                                      template_territory   => l_ter,
                                                      output_format        => 'EXCEL');
            l_rpt_reqid := fnd_request.submit_request(application   => l_application,
                                                      program       => l_program_name,
                                                      description   => l_program_desc,
                                                      start_time    => sysdate,
                                                      sub_request   => false,
                                                      argument1     => l_request_id,
                                                      argument2     => l_disp_trx,
                                                      argument3     => p_capex_num);
            commit;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Report Request Id: ' || l_rpt_reqid);
        end if;
    exception
        when xx_emf_pkg.g_e_env_not_set then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'xx_emf_pkg.cn_env_not_set: ' || xx_emf_pkg.cn_env_not_set);
            retcode := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.create_report;
        when xx_emf_pkg.g_e_prc_error then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Procedure Error:retcode: ' || g_retcode || ' Err Msg: ' || g_errmsg);
            retcode := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.create_report;
        when others then
            retcode := xx_emf_cn_pkg.cn_prc_err;
            errbuf := substr(sqlerrm, 1, 250);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'retcode: ' || retcode || ' Error: ' || errbuf);
            xx_emf_pkg.error(xx_emf_cn_pkg.cn_low,
                             xx_emf_cn_pkg.cn_tech_error,
                             xx_emf_cn_pkg.cn_exp_unhand,
                             'Unexpected error in main',
                             sqlerrm);
    end main;
end xx_fa_inv_asset_creation_pkg;
/
