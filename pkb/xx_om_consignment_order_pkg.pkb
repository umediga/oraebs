DROP PACKAGE BODY APPS.XX_OM_CONSIGNMENT_ORDER_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.XX_OM_CONSIGNMENT_ORDER_PKG as
  /*----------------------------------------------------------------------*/
  /* $Header: XX_OM_CONSIGNMENT_ORDER_PKG.pks 1.7 2012/12/19 12:00:00 dparida noship $ */
  /*
   Created By     : IBM Development Team
   Creation Date  : 19-Dec-2012
   File Name      : XX_OM_CONSIGNMENT_ORDER_PKG.pks
   Description    : This script creates the specification of the xx_om_consignment_order package

   Change History:

   Version Date        Name                    Remarks
   ------- ----------- ----                    ----------------------
   1.0     19-Dec-12   IBM Development Team    Initial development.
   1.1     10-Feb-14   Dhiren                  Logic Added for New Line Type ILS Kitting Request
   1.2     18-Feb-14   Dhiren                  Logic Added for destination Subinventory
   1.3     24-FEB-2014 Jagdish                 Populating source org id in Req Import instead of NULL.
   1.4     25-FEB-2014 Jagdish                 New procedure to verify Booking eligibility for
                                               ILS Product Request Order Type Only.
                                               This procedure along with new Order header Workflow Branch validates eligibility.
                                               OEOH : XXOM_PROD_REQ_HEADER -- XXOM Order Flow - Product Request.
                                               These changes need to go along with OEOH workflow and Application message XXOM_ORDER_BOOK_PROD_REQ
   1.5     19-MAR-2014 Jagdish                 Chargesheet - Warehouse should be picked up from Master Org - Default Shipping Org and not from Original Order -
   1.6     28-APR-2014 Naga                    Made change to make MB Scoz as default preparer. The changes are to both xx_om_insert_req_line
                                               and xx_om_create_ir_iso. These are seperate calls made: first one is made in replenishment workflow as part
                                               of chargesheet creation and second one is made as part of prdocut request.In both cases MB will be default preparer
                                               But the requester remains the same as the salesrep or who ever has created the order which is the current logic.
   1.7     21-MAY-2014 Jagdish                 1. Added exception for Subinventory in xx_om_create_ir_iso procedure.
                                               If Sub-inventory cannot be found, Header workflow will not prgress further. Added result type FAIL/SUCCESS.
                                               2. Added cancelled_flag and bokked_flag conditions to line cursor.
   1.8     23-AUG-2014 Naga/Jagdish            Locator Derivation Issue Case # 008644.
   1.9     02-FEB-2016 Vinod                   Case Number 9141. Added procedure xx_om_iso_eligible to check if order is elgible for
                                               ISO. Case Numer 9143. Update transferred_to_oe_flag on po_requisition_headers_all and 
                                               po_requisition_lines_all table for requisition created by part request process
  */
  ----------------------------------------------------------------------
  g_org_id number;
  g_user_id number;
  g_resp_id number;
  g_app_id number;
  g_itemkey varchar2(200);
  c_created_by_module constant varchar2(100) := 'ONT_PROCESS_ORDER_API';
  --This cursor is shared in two places
  cursor po_hold_line_type_cur(p_line_type in varchar2) is
    select lu.meaning
    from   fnd_lookup_values lu
    where      lu.lookup_type = 'XXOM_PO_HOLD_LINE_TYPES'
           and lu.meaning = p_line_type
           and lu.language = 'US'
           and lu.enabled_flag = 'Y'
           and sysdate between lu.start_date_active and nvl(lu.end_date_active, sysdate + 1);
  --Used in create_rep_deliver_to
  cursor so_dt_address_cur(p_site_use_id in number) is
    select loc.address1, loc.address2, loc.city, loc.state, loc.postal_code
    from   hz_cust_site_uses_all su, hz_cust_acct_sites_all cas, hz_party_sites ps, hz_locations loc
    where      su.site_use_id = p_site_use_id
           and su.cust_acct_site_id = cas.cust_acct_site_id
           and cas.party_site_id = ps.party_site_id
           and ps.location_id = loc.location_id;
  --Forward Declarations of private procedures
  procedure copy_attachments(p_from_header_id in number, p_to_header_id in number);
  procedure create_rep_deliver_to(p_salesrep_id in number, p_so_deliver_to_org_id in number, x_iso_deliver_to_org_id out number);
  procedure create_location(p_party_id in number, p_loc_data in so_dt_address_cur%rowtype, x_location_id out number);
  procedure create_sites(p_party_id in number
                       , p_cust_acct_id in number
                       , p_location_id in number
                       , p_salesrep_number in varchar2
                       , x_cust_acct_site_id   out number);
  procedure create_site_use(p_cust_acct_site_id in number, p_site_use_code in varchar2, x_site_use_id out number);
  --**********************************************************************
  ----Procedure to set environment.
  --**********************************************************************
  procedure log_message(p_log_message in varchar2) is
    pragma autonomous_transaction;
  begin
    insert into xxintg_cnsgn_cmn_log_tbl
    values      (xxintg_cnsgn_cmn_log_seq.nextval, 'CONSGN-WF', p_log_message, sysdate);
    commit;
    dbms_output.put_line('log message: ' || p_log_message);
  end LOG_MESSAGE;
  procedure set_cnv_env(p_required_flag varchar2 default xx_emf_cn_pkg.cn_yes) is
    x_error_code number := xx_emf_cn_pkg.cn_success;
  begin
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Inside set_cnv_env...');
    -- Set the environment
    x_error_code := xx_emf_pkg.set_env(p_process_name => 'XXOMISOCRT');
    if nvl(p_required_flag, xx_emf_cn_pkg.cn_yes) <> xx_emf_cn_pkg.cn_no then
      xx_emf_pkg.propagate_error(x_error_code);
    end if;
  exception
    when others then
      raise xx_emf_pkg.g_e_env_not_set;
  end set_cnv_env;
  
  -- 1.9 Case 9141
  -- ==============================================================================================
  -- Name           : xx_om_iso_eligible
  -- Description    : Procedure to check if order is eligible for iso
  -- Parameters description       :
  --
  -- No user parameter
  -- =================================================================================================
  PROCEDURE xx_om_iso_eligible(itemtype  IN VARCHAR2,
                               itemkey   IN VARCHAR2,
                               actid     IN NUMBER,
                               funcmode  IN VARCHAR2,
                               resultout OUT NOCOPY VARCHAR2)
  IS
    l_org_id      NUMBER ;
    l_user_id     NUMBER ;
    l_resp_id     NUMBER ;
    l_app_id      NUMBER ;
    l_header_id   NUMBER ;
    l_tra_type    VARCHAR2(200);
    l_count       NUMBER ;
    l_eligible    VARCHAR2(10) := 'N' ;
  BEGIN
    IF funcmode = 'RUN'
    THEN
      --- Validate if order is eligible for ISO ---
      l_org_id    := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
      l_user_id   := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'USER_ID');
      l_resp_id   := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'RESPONSIBILITY_ID');
      l_app_id    := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'APPLICATION_ID');
      l_header_id := to_number(itemkey) ;
    
      --- Check for the Order Type  ---
      BEGIN
        SELECT name
        INTO   l_tra_type
        FROM   oe_transaction_types_tl a
             , oe_order_headers        b
        WHERE  b.header_id     = l_header_id
        AND    b.order_type_id = a.transaction_type_id ;
      EXCEPTION
        WHEN OTHERS THEN
          l_tra_type := NULL ;
      END ;
    
      IF (l_tra_type = 'ILS Product Request Order') OR (l_tra_type = 'ILS Charge Sheet Order') 
      THEN
        l_count := 0 ;
      
        BEGIN
          SELECT COUNT(*)
          INTO   l_count
          FROM   po_requisitions_interface_all
          WHERE  header_attribute15 = itemkey ;
        EXCEPTION
          WHEN OTHERS THEN
            l_count := 0 ;
        END ;
     
        IF l_count > 0
        THEN
          l_eligible := 'Y' ;
        END IF ;
      END IF ;
      
      resultout := 'COMPLETE:'||l_eligible ;
      RETURN ;
    END IF ;
    
    -- if cancel then return N 
    IF funcmode = 'CANCEL'
    THEN
      resultout := 'COMPLETE:N';
      RETURN;
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
      resultout := 'COMPLETE:N';
      wf_core.CONTEXT('xx_om_consignment_order_pkg'
                    , 'xx_om_iso_eligible'
                    , itemtype
                    , itemkey
                    , 'xx_om_iso_eligible');
      RAISE;
  END xx_om_iso_eligible ;
                               
  -- ==============================================================================================
  -- Name           : xx_om_create_iso
  -- Description    : Procedure To Create ISO
  -- Parameters description       :
  --
  -- No user parameter
  -- =================================================================================================
  procedure xx_om_create_iso(itemtype in   varchar2
                           , itemkey in    varchar2
                           , actid in      number
                           , funcmode in   varchar2
                           , resultout   out nocopy varchar2) is
    x_conc_req_id number;
    x_org_id number;
    x_user_id number;
    x_resp_id number;
    x_app_id number;
    l_dev_status varchar2(100);
    l_dev_phase varchar2(100);
    l_phase varchar2(100);
    l_status varchar2(30);
    l_message varchar2(4000);
    l_tra_type varchar2(200);
    l_request_complete boolean;
    l_con_reqid number;
    e_req_error exception;
  begin
    --- Call the Concurrent Program To Submit the Procedures to Create ISO ---
    x_org_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
    x_user_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'USER_ID');
    x_resp_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'RESPONSIBILITY_ID');
    x_app_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'APPLICATION_ID');
    --- Check for the Order Type Then Submit the Program ---
    begin
      select NAME --- ILS Product Request Order OR ILS Charge Sheet Order
      into   l_tra_type
      from   oe_transaction_types_tl a, oe_order_headers b
      where  a.transaction_type_id = b.order_type_id and b.header_id = itemkey and rownum < 2;
    exception
      when others then
        l_tra_type := null;
    end;
    if (l_tra_type = 'ILS Product Request Order') or (l_tra_type = 'ILS Charge Sheet Order') then
      xx_om_create_iso_prag(p_argument1 => x_org_id
                          , p_argument2 => x_user_id
                          , p_argument3 => x_resp_id
                          , p_argument4 => x_app_id
                          , p_argument5 => itemkey
                          , p_con_reqid => l_con_reqid);
    end if;
    if l_con_reqid = 0 then
      raise e_req_error;
    end if;
    return;
  exception
    when e_req_error then
      wf_core.CONTEXT('xx_om_consignment_order_pkg'
                    , 'xx_om_create_iso'
                    , itemtype
                    , itemkey
                    , 'xx_om_create_iso');
      raise;
    when others then
      wf_core.CONTEXT('xx_om_consignment_order_pkg'
                    , 'xx_om_create_iso'
                    , itemtype
                    , itemkey
                    , 'xx_om_create_iso');
      raise;
  end xx_om_create_iso;
  -- ==============================================================================================
  -- Name           : xx_om_create_iso_prag
  -- Description    : Procedure To Create ISO
  -- Parameters description       :
  --
  -- No user parameter
  -- =================================================================================================
  procedure xx_om_create_iso_prag(p_argument1 number
                                , p_argument2 number
                                , p_argument3 number
                                , p_argument4 number
                                , p_argument5 varchar2
                                , p_con_reqid out number) is
    pragma autonomous_transaction;
    x_conc_req_id number;
    x_org_id number;
    x_user_id number;
    x_resp_id number;
    x_app_id number;
    l_dev_status varchar2(100);
    l_dev_phase varchar2(100);
    l_phase varchar2(100);
    l_status varchar2(30);
    l_message varchar2(4000);
    l_tra_type varchar2(200);
    l_request_complete boolean;
  begin
    x_conc_req_id := fnd_request.submit_request(application => 'XXINTG'
                                              , program => 'XXOMISOCRT'
                                              , description => null
                                              , start_time => sysdate
                                              , sub_request => false
                                              , argument1 => p_argument1
                                              , argument2 => p_argument2
                                              , argument3 => p_argument3
                                              , argument4 => p_argument4
                                              , argument5 => p_argument5);
    commit;
    p_con_reqid := x_conc_req_id;
  exception
    when others then
      p_con_reqid := 0;
  end xx_om_create_iso_prag;
  procedure xx_om_closed_lines_count(itemtype in   varchar2
                                   , itemkey in    varchar2
                                   , actid in      number
                                   , funcmode in   varchar2
                                   , resultout   out nocopy varchar2) is
    l_line_count number;
    l_closed_line_count number;
    l_org_id number;
  begin
    l_org_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
    select count(*)
    into   l_line_count
    from   oe_order_lines ol
    where  ol.org_id = l_org_id and ol.header_id = itemkey;
    select count(*)
    into   l_closed_line_count
    from   oe_order_lines ol
    where  ol.org_id = l_org_id and flow_status_code = 'CLOSED' and ol.header_id = itemkey;
    if l_line_count = l_closed_line_count then
      resultout := 'COMPLETE:Y';
    else
      resultout := 'COMPLETE:N';
    end if;
    return;
  exception
    when others then
      wf_core.CONTEXT('xx_om_consignment_order_pkg'
                    , 'xx_om_closed_lines_count'
                    , itemtype
                    , itemkey
                    , 'xx_om_closed_lines_count');
      raise;
  end xx_om_closed_lines_count;
  -- =================================================================================
  -- Name           : xx_om_import_req
  -- Description    : Procedure To Create Req Records In Oracle Base Table
  -- Parameters description       :
  --
  -- No user parameter
  -- ==================================================================================
  procedure xx_om_import_req(p_errbuf   out varchar2
                           , p_retcode   out varchar2
                           , p_org_id in number
                           , p_user_id in number
                           , p_resp_id in number
                           , p_app_id in number
                           , p_item_key in varchar2) is
    l_source varchar2(100);
    l_request_id number;
    l_group_by varchar2(100);
    l_wait boolean;
    l_errmsg varchar2(4000);
    l_dev_status varchar2(100);
    l_dev_phase varchar2(100);
    l_phase varchar2(100);
    l_status varchar2(30);
    l_message varchar2(4000);
    l_appr_req varchar2(100);
    l_org_id number;
    l_request_complete boolean;
    l_req_no varchar2(100);
    l_error_message varchar2(1000);
    l_process_flag varchar2(1000);
    l_transaction_id number;
    l_order_number varchar2(1000);
    l_temp number;
    cursor cur_chk_req_no(p_org_id number, p_header_id number) is
      select b.attribute14, b.order_number
      from   oe_order_headers b
      where  b.org_id = p_org_id and b.header_id = p_header_id;
  begin
    set_cnv_env;
    g_org_id := p_org_id;
    g_user_id := p_user_id;
    g_resp_id := p_resp_id;
    g_app_id := p_app_id;
    g_itemkey := p_item_key;
    l_source := 'OM' || g_itemkey;
    l_group_by := 'Item';
    l_appr_req := 'N';
    l_req_no := null;
    l_org_id := g_org_id;
    open cur_chk_req_no(l_org_id, g_itemkey);
    fetch cur_chk_req_no
    into l_req_no, l_order_number;
    close cur_chk_req_no;
    if l_req_no is null or l_req_no = 'In Process' then
      xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                     , p_category => 'Consignment Process'
                     , p_error_text => 'Calling Requisition Import Program'
                     , p_record_identifier_1 => l_order_number
                     , p_record_identifier_2 => null);
      fnd_request.set_org_id(l_org_id);
      l_request_id := fnd_request.submit_request(application => 'PO'
                                               , program => 'REQIMPORT'
                                               , description => null
                                               , start_time => sysdate
                                               , sub_request => false
                                               , argument1 => l_source
                                               , argument2 => null
                                               , argument3 => l_group_by
                                               , argument4 => null
                                               , argument6 => l_appr_req);
      commit;
      --- Wait For The Completion ---
      if l_request_id is not null then
        loop
          l_request_complete := apps.fnd_concurrent.wait_for_request(l_request_id
                                                                   , 1
                                                                   , 0
                                                                   , l_phase
                                                                   , l_status
                                                                   , l_dev_phase
                                                                   , l_dev_status
                                                                   , l_message);
          if upper(l_phase) = 'COMPLETED' then
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                           , p_category => 'Consignment Process'
                           , p_error_text =>   'Requisition Import Program Completed. Please check the Request ID '
                                            || l_request_id
                                            || ' for LOG and OUT '
                           , p_record_identifier_1 => l_order_number
                           , p_record_identifier_2 => l_request_id);
            exit;
          end if;
        end loop;
        log_message('Calling Internal Order Program');
        -- Check the Interface Table For Record Status and Update the Emf Table --
        begin
          select process_flag, transaction_id
          into   l_process_flag, l_transaction_id
          from   po_requisitions_interface_all
          where  header_attribute15 = to_char(g_itemkey);
        exception
          when others then
            l_process_flag := null;
        end;
        if l_process_flag = 'ERROR' then
          xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                         , p_category => 'Consignment Process'
                         , p_error_text => 'Error While Creating Requisition, Please Query The Table PO_INTERFACE_ERRORS For INTERFACE_TRANSACTION_ID '
                                          || l_transaction_id
                         , p_record_identifier_1 => l_order_number
                         , p_record_identifier_2 => l_request_id);
        else
          xx_om_import_internal_ord;
        end if;
      end if;
    end if;
  exception
    when others then
      l_error_message := 'Error In xx_om_import_req ' || substr(sqlerrm, 11, 150);
      log_message('Error In xx_om_import_req' || l_error_message);
      raise;
  end xx_om_import_req;
  -- =================================================================================
  -- Name           : xx_om_insert_req_line
  -- Description    : Procedure To Insert Data Into Req Interface Table
  -- Parameters description       :
  --
  -- No user parameter
  -- ==================================================================================
  procedure xx_om_insert_req_line(itemtype in   varchar2
                                , itemkey in    varchar2
                                , actid in      number
                                , funcmode in   varchar2
                                , resultout   out nocopy varchar2) is
    cursor cur_copy_ord(p_org_id number
                      , p_line_id number) is
      select a.org_id
           , a.header_id
           , a.line_number
           , a.inventory_item_id
           , a.unit_selling_price
           , a.ordered_quantity
           , a.order_quantity_uom
           , trunc(a.request_date) request_date
           , a.ship_from_org_id src_org_id
           , b.transactional_curr_code
           , a.ship_to_org_id
           , a.salesrep_id
           , b.attribute14
           , (select NAME
              from   oe_transaction_types_tl
              where  transaction_type_id = a.line_type_id and rownum < 2)
               line_type
           , b.order_number
           , a.subinventory
           , --- added on 18-Feb-14
            (select a.NAME
             from   oe_transaction_types_tl a
             where  a.transaction_type_id = b.order_type_id and rownum < 2)
               header_type
           , --- added on 18-Feb-14
            a.sold_to_org_id --- added on 18-Feb-14
      from   oe_order_lines a, oe_order_headers b
      where      a.org_id = p_org_id
             and a.line_id = p_line_id
             and a.header_id = b.header_id
             and (b.attribute14 is null or b.attribute14 = 'In Process');
    l_user_id number;
    l_person_id number;
    l_dest_org_id number;
    l_src_org_id number;
    l_deliver_to_loc_id number;
    l_err_msg varchar2(150);
    l_cc_id number;
    l_line_num varchar2(100);
    l_line_id number;
    l_org_id number;
    l_error_flag varchar2(100);
    l_subinventory varchar2(100);
    l_temp_employee_id number; -- Naga MB Scoz changes
    e_insert_error exception;
  begin
    -- Extract WF data
    l_org_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
    l_user_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'USER_ID');
    l_error_flag := 'N';
    for rec_copy_ord in cur_copy_ord(l_org_id, itemkey) loop
      log_message('Req Inser: Line Loop ');
      --- Check For Line Number
      begin
        l_line_num := 0;
        select line_attribute15
        into   l_line_num
        from   po_requisitions_interface
        where  header_attribute15 = to_char(rec_copy_ord.header_id) and line_attribute15 = to_char(rec_copy_ord.line_number);
      exception
        when no_data_found then
          l_line_num := 0;
      end;
      --- Extract Person ID
      begin
        select employee_id
        into   l_person_id
        from   fnd_user
        where  user_id = l_user_id;
      exception
        when others then
          l_person_id := null;
      end;
      l_temp_employee_id := Oe_Sys_Parameters.value('ONT_EMP_ID_FOR_SS_ORDERS', l_org_id);
      --- Extract Deliver to location _id
      -- IF rec_copy_ord.line_type = 'Request' THEN
      if (rec_copy_ord.line_type = 'ILS Consignment Request' or rec_copy_ord.line_type = 'ILS Kitting Request') then
        begin
          select location_id
          into   l_deliver_to_loc_id
          from   po_location_associations
          where  site_use_id = rec_copy_ord.ship_to_org_id;
        exception
          when others then
            l_deliver_to_loc_id := null;
        end;
      else
        begin
          -- Fix For Point# 4
          select ship_to_location_id
          into   l_deliver_to_loc_id
          from   apps.hr_locations hl, mtl_secondary_inventories ms, oe_order_lines ool
          where      hl.location_id = ms.location_id
                 --- and hl.location_code = ms.description
                 and ms.secondary_inventory_name = ool.subinventory
                 and ool.header_id = rec_copy_ord.header_id
                 and ool.line_number = rec_copy_ord.line_number;
        /* select ship_to_location_id
          into l_deliver_to_loc_id
          from apps.hr_locations hl, apps.JTF_RS_SRP_VL jrs
        -- , oe_order_headers_all ooh
         where hl.location_code = jrs.name
           and jrs.salesrep_id = rec_copy_ord.salesrep_id;
        */
        /*
                     ooh.salesrep_id
                     and ooh.order_number = rec_copy_ord.order_number;
        */
        exception
          when others then
            l_deliver_to_loc_id := null;
        end;
      end if;
      --- as per brian destination organization id is 150 org code
      begin
        select organization_id
        into   l_dest_org_id
        from   org_organization_definitions
        where  organization_code = '150';
      exception
        when others then
          l_dest_org_id := null;
      end;
      -- set the source org to the ship_from_org on the order line
      l_src_org_id := rec_copy_ord.src_org_id;
      --- Insert data to Interface table
      if rec_copy_ord.inventory_item_id is not null
         and rec_copy_ord.line_type in ('Replenishment', 'ILS Consignment Request', 'ILS Kitting Request') then
        log_message('Req Inser: Order Line Type :' || rec_copy_ord.line_type);
        if l_line_num = 0 then
          --- Derive the Destination Subinventory ---  --- added on 18-Feb-14
          l_subinventory := null;
          if rec_copy_ord.header_type = 'ILS Product Request Order' then
            select secondary_inventory_name
            into   l_subinventory
            from   mtl_secondary_inventories msi, hr_locations hl, po_location_associations_all pla
            where      msi.location_id = hl.location_id
                   and hl.location_id = pla.location_id
                   and pla.customer_id = rec_copy_ord.sold_to_org_id
                   and rownum < 2;
          elsif rec_copy_ord.header_type = 'ILS Charge Sheet Order' then
            l_subinventory := rec_copy_ord.subinventory;
            log_message('Charge Sheet: ' || l_subinventory);
            -- 03/18/2014 --
            -- For Chargesheet, warehouse should come from Master Org - Default Shipping org --
            -- BXS - default shipping org is always 150
            -- we are trying to get the subinventory
            begin
              select default_shipping_org
              into   l_src_org_id
              from   mtl_system_items_b
              where  inventory_item_id = rec_copy_ord.inventory_item_id --l_line_tbl(i).inventory_item_id
                     and organization_id = (select distinct master_organization_id
                                            from   mtl_parameters
                                            where  organization_code = '150');
            exception
              when others then
                l_subinventory := null;
                log_message('Charge Sheet - Unable to get default Shiping Org from Master for Item: ' || rec_copy_ord.inventory_item_id);
            end;
          end if;
          log_message('Before  xx_om_insert_req_line_prag');
          xx_om_insert_req_line_prag('OM' || rec_copy_ord.header_id
                                   , --Interface Source
                                    rec_copy_ord.org_id
                                   , --Operating Unit
                                     -- null, -- rec_copy_ord.src_org_id,                     --tbd
                                     -- rec_copy_ord.src_org_id,  -- Since we are deriving l_ship_from_org in original SO, no need to default to null 02/24/2014 Jag.
                                     l_src_org_id
                                   , -- we need to get the source organization off off of the item master
                                    'INTERNAL'
                                   , --Constant
                                    'INVENTORY'
                                   , --Constant
                                    'APPROVED'
                                   , --Constant
                                     --l_person_id, --per_people_f.person_id
                                     l_temp_employee_id
                                   , -- Naga MB Scoz change as default preparer
                                    'INVENTORY'
                                   , --Constant
                                    rec_copy_ord.order_quantity_uom
                                   , --UOM
                                    1
                                   , --Line Type of Goods
                                    rec_copy_ord.ordered_quantity
                                   , --quantity
                                    rec_copy_ord.unit_selling_price
                                   , --unit_price
                                    rec_copy_ord.transactional_curr_code
                                   , --currency code
                                    l_dest_org_id
                                   , --Dest Org Inv Org.
                                    l_deliver_to_loc_id
                                   , --Represents V1-New York City
                                    l_person_id
                                   , --This is the Deliver to Requestor
                                    rec_copy_ord.inventory_item_id
                                   , --Item ID
                                    rec_copy_ord.request_date
                                   , --Need By Date
                                    rec_copy_ord.header_id
                                   , --Order Header ID
                                    rec_copy_ord.line_number
                                   , --Line Num
                                    l_subinventory
                                   , -- dest subinventory  --- added on 18-Feb-14
                                    l_error_flag);
          log_message('After  xx_om_insert_req_line_prag');
        end if;
      end if;
    end loop;
    if l_error_flag = 'Y' then
      raise e_insert_error;
    end if;
  exception
    when e_insert_error then
      l_err_msg := 'Error While Inserting Records To Interface Table';
      wf_core.CONTEXT('xx_om_consignment_order_pkg'
                    , 'xx_om_insert_req_line'
                    , itemtype
                    , itemkey
                    , 'Error ' || l_err_msg);
      raise;
    when others then
      l_err_msg := 'Error While Inserting Records To Interface Table ' || substr(sqlerrm, 11, 150);
      wf_core.CONTEXT('xx_om_consignment_order_pkg'
                    , 'xx_om_insert_req_line'
                    , itemtype
                    , itemkey
                    , 'Error ' || l_err_msg);
      raise;
  end xx_om_insert_req_line;
  -- =================================================================================
  -- Name           : xx_om_insert_req_line_prag
  -- Description    : Procedure To Insert Data Into Req Interface Table With PRAGMA
  -- Parameters description       :
  --
  -- No user parameter
  -- ==================================================================================
  procedure xx_om_insert_req_line_prag(p_interface_source_code varchar2
                                     , p_org_id number
                                     , p_source_organization_id number
                                     , p_requisition_type varchar2
                                     , p_destination_type_code varchar2
                                     , p_authorization_status varchar2
                                     , p_preparer_id number
                                     , p_source_type_code varchar2
                                     , p_uom_code varchar2
                                     , p_line_type_id number
                                     , p_quantity number
                                     , p_unit_price number
                                     , p_currency_code varchar2
                                     , p_destination_organization_id number
                                     , p_deliver_to_location_id number
                                     , p_deliver_to_requestor_id number
                                     , p_item_id number
                                     , p_need_by_date date
                                     , p_header_attribute15 varchar2
                                     , p_line_attribute15 varchar2
                                     , p_destination_subinventory varchar2
                                     , p_error_flag out varchar2) is
    pragma autonomous_transaction;
    l_user_id number;
    l_person_id number;
    l_dest_org_id number;
    l_deliver_to_loc_id number;
    l_err_msg varchar2(150);
    l_cc_id number;
    l_line_num varchar2(100);
    l_line_id number;
    l_org_id number;
    l_itemkey varchar2(50);
  begin
    log_message('Right Before Insert');
    insert into po_requisitions_interface_all(interface_source_code
                                            , org_id
                                            , source_organization_id
                                            , requisition_type
                                            , destination_type_code
                                            , authorization_status
                                            , preparer_id
                                            , --   charge_account_id,
                                             source_type_code
                                            , uom_code
                                            , line_type_id
                                            , quantity
                                            , unit_price
                                            , currency_code
                                            , destination_organization_id
                                            , deliver_to_location_id
                                            , deliver_to_requestor_id
                                            , item_id
                                            , need_by_date
                                            , header_attribute15
                                            , line_attribute15
                                            , destination_subinventory)
    values      (p_interface_source_code, p_org_id, p_source_organization_id, p_requisition_type, p_destination_type_code
               , p_authorization_status, p_preparer_id, p_source_type_code, p_uom_code, p_line_type_id, p_quantity, p_unit_price
               , p_currency_code, p_destination_organization_id, p_deliver_to_location_id, p_deliver_to_requestor_id, p_item_id
               , p_need_by_date, p_header_attribute15, p_line_attribute15, p_destination_subinventory);
    log_message('Right After Insert');
    commit;
  exception
    when others then
      p_error_flag := 'Y';
  end xx_om_insert_req_line_prag;
  -- =================================================================================
  -- Name           : xx_om_import_internal_so
  -- Description    : Procedure To Create Internal Sales Orders In Oracle
  -- Parameters description       :
  --
  -- No user parameter
  -- ==================================================================================
  procedure xx_om_import_internal_so is
    --PRAGMA AUTONOMOUS_TRANSACTION;
    cursor c_get_ship_method_hdr(p_header_id number) is
      select flv.meaning, flv.lookup_code, oh.deliver_to_org_id, oh.deliver_to_contact_id, oh.salesrep_id
      from   fnd_lookup_values flv, oe_order_headers oh
      where      flv.lookup_type(+) = 'SHIP_METHOD'
             and flv.lookup_code(+) = oh.shipping_method_code
             and oh.header_id = p_header_id
             and flv.LANGUAGE(+) = userenv('LANG');
    cursor c_get_ship_method_lines(p_header_id number) is
      select flv.meaning, flv.lookup_code, ol.line_id, ol.deliver_to_org_id, ol.deliver_to_contact_id, ol.ship_set_id
      from   fnd_lookup_values flv, oe_order_lines ol
      where      flv.lookup_type(+) = 'SHIP_METHOD'
             and flv.lookup_code(+) = ol.shipping_method_code
             and ol.header_id = p_header_id
             and flv.LANGUAGE(+) = userenv('LANG');
    cursor c_get_req_line_id(p_req_header_id in number
                           , p_org_id in number
                           , p_header_id number) is
      select prl.requisition_line_id, ol.line_id, ol.line_type_id
      from   po_requisition_headers prh, po_requisition_lines prl, oe_order_lines ol
      where      prh.requisition_header_id = prl.requisition_header_id
             and prh.requisition_header_id = p_req_header_id
             and prh.org_id = p_org_id
             and prl.attribute15 = to_char(ol.line_number)
             and ol.header_id = p_header_id;
    cursor cur_chk_req_no(p_org_id number, p_header_id number) is
      select b.attribute14, b.order_number
      from   oe_order_headers b
      where  b.org_id = p_org_id and b.header_id = p_header_id;
    x_conc_req_id number(10);
    x_req_header_id number(30);
    x_req_phase varchar2(60);
    x_status varchar2(60);
    x_dev_phase varchar2(60);
    x_dev_status varchar2(60);
    x_message varchar2(2000);
    x_complete_status boolean;
    x_org_id number;
    l_dev_status varchar2(100);
    l_dev_phase varchar2(100);
    l_phase varchar2(100);
    l_status varchar2(30);
    l_message varchar2(4000);
    l_request_complete boolean;
    l_req_no varchar2(60);
    l_error_message varchar2(1000);
    l_line_typ_id number;
    l_order_number varchar2(1000);
    l_iso_number varchar2(1000);
    l_orig_sys_document_ref varchar2(1000);
    l_srep_dt_org_id number;
  begin
    l_req_no := null;
    x_org_id := g_org_id;
    l_iso_number := null;
    open cur_chk_req_no(x_org_id, g_itemkey);
    fetch cur_chk_req_no
    into l_req_no, l_order_number;
    close cur_chk_req_no;
    if l_req_no is null or l_req_no = 'In Process' then
      xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                     , p_category => 'Consignment Process'
                     , p_error_text => 'Calling  Order Import Program'
                     , p_record_identifier_1 => l_order_number
                     , p_record_identifier_2 => null);
      begin
        select requisition_header_id
        into   x_req_header_id
        from   po_requisition_headers
        where  substr(interface_source_code, 3, length(interface_source_code)) = g_itemkey and org_id = x_org_id;
      exception
        when others then
          x_req_header_id := 0;
      end;
      -- New Logic To Determine Line Type Based Upon ORIG DOCUMENT REF
      -- Extract the DOCUMENT TYPE ---
      /* l_orig_sys_document_ref := Null;
       BEGIN
         SELECT SUBSTR(orig_sys_document_ref, 1, 2)
           INTO l_orig_sys_document_ref
           FROM oe_order_headers
          WHERE header_id = TO_NUMBER(g_itemkey);

       EXCEPTION
         WHEN OTHERS THEN
           l_orig_sys_document_ref := Null;
       END;

       IF UPPER(l_orig_sys_document_ref) = 'PR' THEN

         -- Fix for point# 10
         BEGIN
           SELECT transaction_type_id
             INTO l_line_typ_id
             FROM oe_transaction_types_tl
            WHERE UPPER(NAME) = UPPER('ILS Consignment Request')
              AND ROWNUM < 2;
         EXCEPTION
           WHEN OTHERS THEN
             l_line_typ_id := 0;
             xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.cn_medium,
                              p_category            => 'Consignment Process',
                              p_error_text          => 'Line Type ILS Consignment Request Not Found ',
                              p_record_identifier_1 => l_order_number,
                              p_record_identifier_2 => NULL);
         END;

       ELSIF UPPER(l_orig_sys_document_ref) = 'RR' THEN

         -- New Logic For ILS Kitting Request
         BEGIN
           SELECT transaction_type_id
             INTO l_line_typ_id
             FROM oe_transaction_types_tl
            WHERE UPPER(NAME) = UPPER('ILS Kitting Request')
              AND ROWNUM < 2;
         EXCEPTION
           WHEN OTHERS THEN
             l_line_typ_id := 0;
             xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.cn_medium,
                              p_category            => 'Consignment Process',
                              p_error_text          => 'Line Type ILS Kitting Request Not Found ',
                              p_record_identifier_1 => l_order_number,
                              p_record_identifier_2 => NULL);
         END;

       END IF;
       */
      for rec_c_get_ship_method_hdr in c_get_ship_method_hdr(to_number(g_itemkey)) loop
        create_rep_deliver_to(p_salesrep_id => rec_c_get_ship_method_hdr.salesrep_id
                            , p_so_deliver_to_org_id => rec_c_get_ship_method_hdr.deliver_to_org_id
                            , x_iso_deliver_to_org_id => l_srep_dt_org_id);
        update oe_headers_iface_all
        set --shipping_method       = rec_c_get_ship_method_hdr.meaning, -- Interface fails if both code and name is populated. 03/03
           shipping_method_code = rec_c_get_ship_method_hdr.lookup_code, deliver_to_org_id = l_srep_dt_org_id --rec_c_get_ship_method_hdr.deliver_to_org_id,
        --deliver_to_contact_id = rec_c_get_ship_method_hdr.deliver_to_contact_id
        where  orig_sys_document_ref = x_req_header_id and org_id = x_org_id;
      end loop;
      for rec_c_get_req_line_id in c_get_req_line_id(x_req_header_id, x_org_id, to_number(g_itemkey)) loop
        for rec_c_get_ship_method_lines in c_get_ship_method_lines(to_number(g_itemkey)) loop
          update oe_lines_iface_all
          set --1=1,--,shipping_method       = rec_c_get_ship_method_lines.meaning, -- Interface fails if both code and name is populated. 03/03
             shipping_method_code = rec_c_get_ship_method_lines.lookup_code
               , ship_set_name = rec_c_get_ship_method_lines.ship_set_id
               , deliver_to_org_id = l_srep_dt_org_id --rec_c_get_ship_method_lines.deliver_to_org_id,
          --deliver_to_contact_id = rec_c_get_ship_method_lines.deliver_to_contact_id
          -- line_type_id          = rec_c_get_req_line_id.line_type_id -- Jag, Naga: Decision on which Line Type to use 03/03
          where      orig_sys_document_ref = x_req_header_id
                 and orig_sys_line_ref = rec_c_get_req_line_id.requisition_line_id
                 and org_id = x_org_id;
          if sql%rowcount > 0 and rec_c_get_ship_method_lines.ship_set_id is not null then
            log_message('Updated the ship_set_name to ' || rec_c_get_ship_method_lines.ship_set_id);
          end if;
        end loop;
      end loop;
      commit;
      begin
        log_message('Calling OEIMP');
        x_conc_req_id := fnd_request.submit_request(application => 'ONT'
                                                  , program => 'OEOIMP'
                                                  , description => null
                                                  , start_time => sysdate
                                                  , sub_request => false
                                                  , argument1 => x_org_id
                                                  , -- Org_id
                                                   argument2 => '10'
                                                  , -- Order source - Internal
                                                   argument3 => x_req_header_id
                                                  , -- Populate Req number Header ID
                                                   argument4 => null
                                                  , argument5 => 'N'
                                                  , argument6 => '1'
                                                  , argument7 => '4'
                                                  , argument8 => null
                                                  , argument9 => null
                                                  , argument10 => null
                                                  , argument11 => 'Y'
                                                  , argument12 => 'N'
                                                  , argument13 => 'Y'
                                                  , argument14 => x_org_id
                                                  , argument15 => 'N');
        commit;
        --- Wait For The Completion ---
        if x_conc_req_id is not null then
          loop
            l_request_complete := apps.fnd_concurrent.wait_for_request(x_conc_req_id
                                                                     , 1
                                                                     , 0
                                                                     , l_phase
                                                                     , l_status
                                                                     , l_dev_phase
                                                                     , l_dev_status
                                                                     , l_message);
            if upper(l_phase) = 'COMPLETED' then
              xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                             , p_category => 'Consignment Process'
                             , p_error_text =>   'Order Import Program Completed. Please check the Request ID '
                                              || x_conc_req_id
                                              || ' for LOG and OUT '
                             , p_record_identifier_1 => l_order_number
                             , p_record_identifier_2 => x_conc_req_id);
              log_message('Order Import Program Completed. Please check the Request ID ' || x_conc_req_id || ' for LOG and OUT ');
              exit;
            end if;
          end loop;
          --- Check for ISO Created OR Not ---
          begin
            select b.order_number
            into   l_iso_number
            from   po_requisition_headers a, oe_order_headers b
            where  substr(interface_source_code, 3, length(interface_source_code)) = g_itemkey
                   and b.source_document_id = a.requisition_header_id;
            log_message('Internal Sales Order Created ' || l_iso_number);
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                           , p_category => 'Consignment Process'
                           , p_error_text => 'Internal Sales Order Created ' || l_iso_number
                           , p_record_identifier_1 => l_order_number
                           , p_record_identifier_2 => x_conc_req_id);
          exception
            when others then
              l_iso_number := 'ERROR';
              xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                             , p_category => 'Consignment Process'
                             , p_error_text => 'Error While Importing Order, Please check the log for the Request ID  ' || x_conc_req_id
                             , p_record_identifier_1 => l_order_number
                             , p_record_identifier_2 => x_conc_req_id);
              log_message('Error While Importing Order, Please check the log for the Request ID  ' || x_conc_req_id);
          end;
          log_message('Calling Sales Order Update Program');
          xx_om_update_sales_ord;
          --- Fix For Point# 3
          log_message('Calling Internal Sales Order Update Program');
          xx_om_update_isales_ord;
        end if;
      exception
        when others then
          null;
      end;
    end if;
    xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                   , p_category => 'Consignment Process'
                   , p_error_text => 'Consignment Process Completed For Order Number ' || l_order_number
                   , p_record_identifier_1 => l_order_number
                   , p_record_identifier_2 => null);
  exception
    when others then
      --- Fix for ERROR ---
      log_message('Calling Sales Order Update Program');
      xx_om_update_sales_ord;
      l_error_message := 'Unexpected Error In xx_om_import_internal_so procedure ' || substr(sqlerrm, 11, 150);
      log_message('Error In xx_om_import_internal_so ' || l_error_message);
      xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                     , p_category => 'Consignment Process'
                     , p_error_text => l_error_message
                     , p_record_identifier_1 => l_order_number
                     , p_record_identifier_2 => null);
      raise;
  end xx_om_import_internal_so;
  -- =================================================================================
  -- Name           : xx_om_import_internal_ord
  -- Description    : Procedure To Create Internal Orders In Interface Table
  -- Parameters description       :
  --
  -- No user parameter
  -- ==================================================================================
  procedure xx_om_import_internal_ord is
    --PRAGMA AUTONOMOUS_TRANSACTION;
    x_conc_req_id number;
    x_org_id number;
    l_dev_status varchar2(100);
    l_dev_phase varchar2(100);
    l_phase varchar2(100);
    l_status varchar2(30);
    l_message varchar2(4000);
    l_request_complete boolean;
    l_req_no varchar2(100);
    l_error_message varchar2(1000);
    l_order_number varchar2(1000);
    l_iface_count number;
    cursor cur_chk_req_no(p_org_id number, p_header_id number) is
      select b.attribute14, b.order_number
      from   oe_order_headers b
      where  b.org_id = p_org_id and b.header_id = p_header_id;
  begin
    l_req_no := null;
    x_org_id := g_org_id;
    open cur_chk_req_no(x_org_id, g_itemkey);
    fetch cur_chk_req_no
    into l_req_no, l_order_number;
    close cur_chk_req_no;
    if l_req_no is null or l_req_no = 'In Process' then
      --- Updating the Flag
      update po_requisition_headers_all
      set    transferred_to_oe_flag = 'Y'
      where  attribute15 = g_itemkey;
      commit;
      xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                     , p_category => 'Consignment Process'
                     , p_error_text => 'Calling  Create Internal Orders Program'
                     , p_record_identifier_1 => l_order_number
                     , p_record_identifier_2 => null);
      fnd_request.set_org_id(x_org_id);
      x_conc_req_id := fnd_request.submit_request(application => 'PO'
                                                , program => 'POCISO'
                                                , description => null
                                                , start_time => sysdate
                                                , sub_request => false);
      commit;
      --- Wait For The Completion ---
      if x_conc_req_id is not null then
        loop
          l_request_complete := apps.fnd_concurrent.wait_for_request(x_conc_req_id
                                                                   , 1
                                                                   , 0
                                                                   , l_phase
                                                                   , l_status
                                                                   , l_dev_phase
                                                                   , l_dev_status
                                                                   , l_message);
          if upper(l_phase) = 'COMPLETED' then
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                           , p_category => 'Consignment Process'
                           , p_error_text =>   'Create Internal Orders Program Completed. Please check the Request ID '
                                            || x_conc_req_id
                                            || ' for LOG and OUT '
                           , p_record_identifier_1 => l_order_number
                           , p_record_identifier_2 => x_conc_req_id);
            exit;
          end if;
        end loop;
        log_message('Calling Import Internal Order Program');
        begin
          l_iface_count := 0;
          select count(*)
          into   l_iface_count
          from   oe_headers_iface_all
          where  orig_sys_document_ref in (select requisition_header_id
                                           from   po_requisition_headers
                                           where  attribute15 = g_itemkey);
        exception
          when others then
            l_iface_count := 0;
        end;
        if l_iface_count = 0 then
          xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                         , p_category => 'Consignment Process'
                         , p_error_text => 'Error While Creating Internal Order, Please check the log for the Request ID  ' || x_conc_req_id
                         , p_record_identifier_1 => l_order_number
                         , p_record_identifier_2 => x_conc_req_id);
        else
          xx_om_import_internal_so;
        end if;
      end if;
    end if;
  exception
    when others then
      l_error_message := 'Error In xx_om_import_internal_ord  ' || substr(sqlerrm, 11, 150);
      log_message('Error In xx_om_import_internal_ord ' || l_error_message);
      raise;
  end xx_om_import_internal_ord;
  -- ==============================================================================================
  -- Name           : xx_om_get_iso_number
  -- Description    : Procedure To Get ISO Number Created
  -- Parameters description       :
  --
  -- No user parameter
  -- =================================================================================================
  procedure xx_om_get_iso_number(itemtype in   varchar2
                               , itemkey in    varchar2
                               , actid in      number
                               , funcmode in   varchar2
                               , resultout   out nocopy varchar2) is
    x_conc_req_id number;
    x_org_id number;
    l_dev_status varchar2(100);
    l_dev_phase varchar2(100);
    l_phase varchar2(100);
    l_status varchar2(30);
    l_message varchar2(4000);
    l_request_complete boolean;
    l_req_no varchar2(100);
    cursor cur_chk_req_no(p_org_id number, p_header_id number) is
      select b.attribute14
      from   oe_order_headers b, oe_order_lines a
      where  a.org_id = p_org_id and a.line_id = p_header_id and a.header_id = b.header_id;
  begin
    l_req_no := null;
    x_org_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
    open cur_chk_req_no(x_org_id, itemkey);
    fetch cur_chk_req_no into l_req_no;
    close cur_chk_req_no;
    if l_req_no is null or l_req_no = 'In Process' then
      resultout := 'COMPLETE:N';
    else
      resultout := 'COMPLETE:Y';
    end if;
  exception
    when others then
      wf_core.CONTEXT('xx_om_consignment_order_pkg'
                    , 'xx_om_get_iso_number'
                    , itemtype
                    , itemkey
                    , 'xx_om_get_iso_number');
      raise;
  end xx_om_get_iso_number;
  -- =================================================================================================
  -- Name           : xx_om_update_sales_ord
  -- Description    : Procedure To Update attribute14 of Sales Order with the internal order number
  -- Parameters description       :
  --
  -- No user parameter
  -- ====================================================================================================
  procedure xx_om_update_sales_ord is
    --PRAGMA AUTONOMOUS_TRANSACTION;
    x_conc_req_id number;
    x_org_id number;
    x_user_id number;
    x_resp_id number;
    x_app_id number;
    l_dev_status varchar2(100);
    l_dev_phase varchar2(100);
    l_phase varchar2(100);
    l_status varchar2(30);
    l_message varchar2(4000);
    l_request_complete boolean;
    x_int_ord_num varchar2(1000);
    x_api_version_number number := 1.0;
    x_header_rec oe_order_pub.header_rec_type;
    x_line_tbl oe_order_pub.line_tbl_type;
    x_action_request_tbl oe_order_pub.request_tbl_type;
    x_line_adj_tbl oe_order_pub.line_adj_tbl_type;
    pp_header_rec_out oe_order_pub.header_rec_type;
    pp_header_val_rec_out oe_order_pub.header_val_rec_type;
    pp_header_adj_tbl_out oe_order_pub.header_adj_tbl_type;
    pp_header_adj_val_tbl_out oe_order_pub.header_adj_val_tbl_type;
    pp_header_price_att_tbl_out oe_order_pub.header_price_att_tbl_type;
    pp_header_adj_att_tbl_out oe_order_pub.header_adj_att_tbl_type;
    pp_header_adj_assoc_tbl_out oe_order_pub.header_adj_assoc_tbl_type;
    pp_header_scredit_tbl_out oe_order_pub.header_scredit_tbl_type;
    pp_header_scredit_val_tbl_out oe_order_pub.header_scredit_val_tbl_type;
    pp_line_tbl_out oe_order_pub.line_tbl_type;
    pp_line_val_tbl_out oe_order_pub.line_val_tbl_type;
    pp_line_adj_tbl_out oe_order_pub.line_adj_tbl_type;
    pp_line_adj_val_tbl_out oe_order_pub.line_adj_val_tbl_type;
    pp_line_price_att_tbl_out oe_order_pub.line_price_att_tbl_type;
    pp_line_adj_att_tbl_out oe_order_pub.line_adj_att_tbl_type;
    pp_line_adj_assoc_tbl_out oe_order_pub.line_adj_assoc_tbl_type;
    pp_line_scredit_tbl_out oe_order_pub.line_scredit_tbl_type;
    pp_line_scredit_val_tbl_out oe_order_pub.line_scredit_val_tbl_type;
    pp_lot_serial_tbl_out oe_order_pub.lot_serial_tbl_type;
    pp_lot_serial_val_tbl_out oe_order_pub.lot_serial_val_tbl_type;
    pp_action_request_tbl_out oe_order_pub.request_tbl_type;
    pp_msg_index number;
    pp_data varchar2(2000);
    pp_loop_count number;
    pp_debug_file varchar2(200);
    pp_return_status varchar2(2000);
    pp_msg_count number;
    pp_msg_data varchar2(2000);
    l_req_no varchar2(100);
    l_iso_number varchar2(100);
    l_error_message varchar2(1000);
    l_line_type number;
    l_order_number varchar2(1000);
    cursor cur_chk_req_no(p_org_id number, p_header_id number) is
      select b.attribute14, b.order_number
      from   oe_order_headers b
      where  b.org_id = p_org_id and b.header_id = p_header_id;
  begin
    l_req_no := null;
    x_org_id := g_org_id;
    x_user_id := g_user_id;
    x_resp_id := g_resp_id;
    x_app_id := g_app_id;
    open cur_chk_req_no(x_org_id, g_itemkey);
    fetch cur_chk_req_no
    into l_req_no, l_order_number;
    close cur_chk_req_no;
    --- Check For Line Type
    --- If Bill Only Lines Then Skip Status ERROR
    begin
      select count((select NAME
                    from   oe_transaction_types_tl
                    where      transaction_type_id = a.line_type_id
                           and rownum < 2
                           and NAME in ('ILS Consignment Request', 'ILS Kitting Request', 'Replenishment')))
      into   l_line_type
      from   oe_order_lines a, oe_order_headers b
      where  a.org_id = x_org_id and b.header_id = g_itemkey and a.header_id = b.header_id;
    exception
      when others then
        l_line_type := 0;
    end;
    if l_req_no is null or l_req_no = 'In Process' then
      xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                     , p_category => 'Consignment Process'
                     , p_error_text => 'Calling oe_order_pub.process_order API to update ISO Number in Original Sales Order Attribute14 '
                     , p_record_identifier_1 => l_order_number
                     , p_record_identifier_2 => null);
      begin
        select b.order_number
        into   l_iso_number
        from   po_requisition_headers a, oe_order_headers b
        where  substr(interface_source_code, 3, length(interface_source_code)) = g_itemkey
               and b.source_document_id = a.requisition_header_id;
      exception
        when others then
          l_iso_number := 'ERROR';
      end;
      x_header_rec := oe_order_pub.g_miss_header_rec;
      x_header_rec.operation := oe_globals.g_opr_update;
      x_action_request_tbl(1) := oe_order_pub.g_miss_request_rec;
      x_line_tbl(1) := oe_order_pub.g_miss_line_rec;
      mo_global.set_policy_context('S', x_org_id);
      x_int_ord_num := l_iso_number;
      x_header_rec.CONTEXT := 'Consignment';
      x_header_rec.attribute14 := x_int_ord_num;
      x_header_rec.header_id := to_number(g_itemkey);
      if l_line_type <> 0 then
        oe_order_pub.process_order(p_api_version_number => x_api_version_number
                                 , p_org_id => x_org_id
                                 , p_header_rec => x_header_rec
                                 , p_line_tbl => x_line_tbl
                                 , p_action_request_tbl => x_action_request_tbl
                                 , p_line_adj_tbl => x_line_adj_tbl
                                 , x_header_rec => pp_header_rec_out
                                 , x_header_val_rec => pp_header_val_rec_out
                                 , x_header_adj_tbl => pp_header_adj_tbl_out
                                 , x_header_adj_val_tbl => pp_header_adj_val_tbl_out
                                 , x_header_price_att_tbl => pp_header_price_att_tbl_out
                                 , x_header_adj_att_tbl => pp_header_adj_att_tbl_out
                                 , x_header_adj_assoc_tbl => pp_header_adj_assoc_tbl_out
                                 , x_header_scredit_tbl => pp_header_scredit_tbl_out
                                 , x_header_scredit_val_tbl => pp_header_scredit_val_tbl_out
                                 , x_line_tbl => pp_line_tbl_out
                                 , x_line_val_tbl => pp_line_val_tbl_out
                                 , x_line_adj_tbl => pp_line_adj_tbl_out
                                 , x_line_adj_val_tbl => pp_line_adj_val_tbl_out
                                 , x_line_price_att_tbl => pp_line_price_att_tbl_out
                                 , x_line_adj_att_tbl => pp_line_adj_att_tbl_out
                                 , x_line_adj_assoc_tbl => pp_line_adj_assoc_tbl_out
                                 , x_line_scredit_tbl => pp_line_scredit_tbl_out
                                 , x_line_scredit_val_tbl => pp_line_scredit_val_tbl_out
                                 , x_lot_serial_tbl => pp_lot_serial_tbl_out
                                 , x_lot_serial_val_tbl => pp_lot_serial_val_tbl_out
                                 , x_action_request_tbl => pp_action_request_tbl_out
                                 , x_return_status => pp_return_status
                                 , x_msg_count => pp_msg_count
                                 , x_msg_data => pp_msg_data);
        commit;
      end if;
    end if;
    xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                   , p_category => 'Consignment Process'
                   , p_error_text => 'oe_order_pub.process_order API Completed with Status ' || pp_return_status
                   , p_record_identifier_1 => l_order_number
                   , p_record_identifier_2 => null);
    if pp_return_status <> 'S' then
      for i in 1 .. pp_msg_count loop
        oe_msg_pub.get(p_msg_index => i, p_encoded => fnd_api.g_false, p_data => pp_msg_data, p_msg_index_out => pp_msg_index);
        xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                       , p_category => 'Consignment Process'
                       , p_error_text => 'Error Line ' || pp_msg_index || ': ' || pp_msg_data
                       , p_record_identifier_1 => l_order_number
                       , p_record_identifier_2 => null);
        log_message('API message is:' || pp_msg_data);
        log_message('API message index is:' || pp_msg_index);
      end loop;
    end if;
    log_message('SO Update Program Ends');
  exception
    when others then
      l_error_message := 'Unexpected Error In xx_om_update_sales_ord procedure ' || substr(sqlerrm, 11, 150);
      log_message('Error In xx_om_update_sales_ord' || l_error_message);
      xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                     , p_category => 'Consignment Process'
                     , p_error_text => l_error_message
                     , p_record_identifier_1 => l_order_number
                     , p_record_identifier_2 => null);
      raise;
  end xx_om_update_sales_ord;
  -- Fix For Point# 3
  -- =================================================================================================
  -- Name           : xx_om_update_isales_ord
  -- Description    : Procedure To Update attribute14 of Internal Sales Order with the original order number
  -- Parameters description       :
  --
  -- No user parameter
  -- ====================================================================================================
  procedure xx_om_update_isales_ord is
    --PRAGMA AUTONOMOUS_TRANSACTION;
    x_conc_req_id number;
    x_org_id number;
    x_user_id number;
    x_resp_id number;
    x_app_id number;
    l_dev_status varchar2(100);
    l_dev_phase varchar2(100);
    l_phase varchar2(100);
    l_status varchar2(30);
    l_message varchar2(4000);
    l_request_complete boolean;
    x_int_ord_num varchar2(1000);
    x_api_version_number number := 1.0;
    x_header_rec oe_order_pub.header_rec_type;
    x_line_tbl oe_order_pub.line_tbl_type;
    x_action_request_tbl oe_order_pub.request_tbl_type;
    x_line_adj_tbl oe_order_pub.line_adj_tbl_type;
    pp_header_rec_out oe_order_pub.header_rec_type;
    pp_header_val_rec_out oe_order_pub.header_val_rec_type;
    pp_header_adj_tbl_out oe_order_pub.header_adj_tbl_type;
    pp_header_adj_val_tbl_out oe_order_pub.header_adj_val_tbl_type;
    pp_header_price_att_tbl_out oe_order_pub.header_price_att_tbl_type;
    pp_header_adj_att_tbl_out oe_order_pub.header_adj_att_tbl_type;
    pp_header_adj_assoc_tbl_out oe_order_pub.header_adj_assoc_tbl_type;
    pp_header_scredit_tbl_out oe_order_pub.header_scredit_tbl_type;
    pp_header_scredit_val_tbl_out oe_order_pub.header_scredit_val_tbl_type;
    pp_line_tbl_out oe_order_pub.line_tbl_type;
    pp_line_val_tbl_out oe_order_pub.line_val_tbl_type;
    pp_line_adj_tbl_out oe_order_pub.line_adj_tbl_type;
    pp_line_adj_val_tbl_out oe_order_pub.line_adj_val_tbl_type;
    pp_line_price_att_tbl_out oe_order_pub.line_price_att_tbl_type;
    pp_line_adj_att_tbl_out oe_order_pub.line_adj_att_tbl_type;
    pp_line_adj_assoc_tbl_out oe_order_pub.line_adj_assoc_tbl_type;
    pp_line_scredit_tbl_out oe_order_pub.line_scredit_tbl_type;
    pp_line_scredit_val_tbl_out oe_order_pub.line_scredit_val_tbl_type;
    pp_lot_serial_tbl_out oe_order_pub.lot_serial_tbl_type;
    pp_lot_serial_val_tbl_out oe_order_pub.lot_serial_val_tbl_type;
    pp_action_request_tbl_out oe_order_pub.request_tbl_type;
    pp_msg_index number;
    pp_data varchar2(2000);
    pp_loop_count number;
    pp_debug_file varchar2(200);
    pp_return_status varchar2(2000);
    pp_msg_count number;
    pp_msg_data varchar2(2000);
    l_req_no varchar2(100);
    l_so_number varchar2(100);
    l_error_message varchar2(1000);
    l_iso_id number;
    l_so_rec oe_order_headers%rowtype;
  begin
    l_req_no := null;
    l_iso_id := null;
    x_org_id := g_org_id;
    x_user_id := g_user_id;
    x_resp_id := g_resp_id;
    x_app_id := g_app_id;
    begin
      select b.header_id
      into   l_iso_id
      from   po_requisition_headers a, oe_order_headers b
      where  substr(interface_source_code, 3, length(interface_source_code)) = g_itemkey and b.source_document_id = a.requisition_header_id;
    exception
      when others then
        l_iso_id := null;
    end;
    begin
      select * --b.order_number
      into   l_so_rec --l_so_number
      from   oe_order_headers b
      where  b.header_id = g_itemkey;
    exception
      when others then
        l_so_number := null;
    end;
    xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                   , p_category => 'Consignment Process'
                   , p_error_text => 'Calling oe_order_pub.process_order API to update SO Number in Internal Sales Order Attribute14 '
                   , p_record_identifier_1 => l_so_rec.order_number
                   , --l_so_number,
                    p_record_identifier_2 => null);
    log_message('Calling oe_order_pub.process_order API to update SO Number in Internal Sales Order Attribute14 ' || l_so_rec.order_number);
    x_header_rec := oe_order_pub.g_miss_header_rec;
    x_header_rec.operation := oe_globals.g_opr_update;
    x_action_request_tbl(1) := oe_order_pub.g_miss_request_rec;
    x_line_tbl(1) := oe_order_pub.g_miss_line_rec;
    mo_global.set_policy_context('S', x_org_id);
    x_int_ord_num := l_so_rec.order_number; --l_so_number;
    x_header_rec.CONTEXT := 'Consignment';
    x_header_rec.attribute1 := l_so_rec.attribute1;
    x_header_rec.attribute2 := l_so_rec.attribute2;
    x_header_rec.attribute3 := l_so_rec.attribute3;
    x_header_rec.attribute4 := l_so_rec.attribute4;
    x_header_rec.attribute9 := l_so_rec.attribute9;
    x_header_rec.attribute14 := x_int_ord_num;
    x_header_rec.attribute20 := l_so_rec.attribute20;
    --Temporarily removed until we determine the proper action
    --x_header_rec.deliver_to_org_id     := l_so_rec.deliver_to_org_id;
    --x_header_rec.deliver_to_contact_id := l_so_rec.deliver_to_contact_id;
    --New logic: If attribute18 has a value, it should be the deliver_to_org_id created via the SOI package.
    if l_so_rec.attribute18 is not null then
      x_header_rec.deliver_to_org_id := l_so_rec.attribute18;
    end if;
    x_header_rec.header_id := l_iso_id;
    oe_order_pub.process_order(p_api_version_number => x_api_version_number
                             , p_org_id => x_org_id
                             , p_header_rec => x_header_rec
                             , p_line_tbl => x_line_tbl
                             , p_action_request_tbl => x_action_request_tbl
                             , p_line_adj_tbl => x_line_adj_tbl
                             , x_header_rec => pp_header_rec_out
                             , x_header_val_rec => pp_header_val_rec_out
                             , x_header_adj_tbl => pp_header_adj_tbl_out
                             , x_header_adj_val_tbl => pp_header_adj_val_tbl_out
                             , x_header_price_att_tbl => pp_header_price_att_tbl_out
                             , x_header_adj_att_tbl => pp_header_adj_att_tbl_out
                             , x_header_adj_assoc_tbl => pp_header_adj_assoc_tbl_out
                             , x_header_scredit_tbl => pp_header_scredit_tbl_out
                             , x_header_scredit_val_tbl => pp_header_scredit_val_tbl_out
                             , x_line_tbl => pp_line_tbl_out
                             , x_line_val_tbl => pp_line_val_tbl_out
                             , x_line_adj_tbl => pp_line_adj_tbl_out
                             , x_line_adj_val_tbl => pp_line_adj_val_tbl_out
                             , x_line_price_att_tbl => pp_line_price_att_tbl_out
                             , x_line_adj_att_tbl => pp_line_adj_att_tbl_out
                             , x_line_adj_assoc_tbl => pp_line_adj_assoc_tbl_out
                             , x_line_scredit_tbl => pp_line_scredit_tbl_out
                             , x_line_scredit_val_tbl => pp_line_scredit_val_tbl_out
                             , x_lot_serial_tbl => pp_lot_serial_tbl_out
                             , x_lot_serial_val_tbl => pp_lot_serial_val_tbl_out
                             , x_action_request_tbl => pp_action_request_tbl_out
                             , x_return_status => pp_return_status
                             , x_msg_count => pp_msg_count
                             , x_msg_data => pp_msg_data);
    commit;
    xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                   , p_category => 'Consignment Process'
                   , p_error_text => 'oe_order_pub.process_order API Completed with Status ' || pp_return_status
                   , p_record_identifier_1 => l_so_rec.order_number
                   , --l_so_number,
                    p_record_identifier_2 => null);
    log_message('oe_order_pub.process_order API Completed with Status ' || pp_return_status);
    if pp_return_status <> 'S' then
      for i in 1 .. pp_msg_count loop
        oe_msg_pub.get(p_msg_index => i, p_encoded => fnd_api.g_false, p_data => pp_msg_data, p_msg_index_out => pp_msg_index);
        xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                       , p_category => 'Consignment Process'
                       , p_error_text => 'Error Line ' || pp_msg_index || ': ' || pp_msg_data
                       , p_record_identifier_1 => l_so_rec.order_number
                       , --l_so_number,
                        p_record_identifier_2 => null);
        log_message('API message is:' || pp_msg_data);
        log_message('API message index is:' || pp_msg_index);
      end loop;
    else
      --After ISO has been successfully updated, also copy any attachements from the source order to the new ISO.
      copy_attachments(p_from_header_id => l_so_rec.header_id, p_to_header_id => l_iso_id);
      commit;
    end if;
    log_message('Internal SO Update Program Ends');
  exception
    when others then
      l_error_message := 'Unexpected Error In xx_om_update_isales_ord procedure ' || substr(sqlerrm, 11, 150);
      log_message('Error In xx_om_update_isales_ord' || l_error_message);
      xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                     , p_category => 'Consignment Process'
                     , p_error_text => l_error_message
                     , p_record_identifier_1 => l_so_rec.order_number
                     , --l_so_number,
                      p_record_identifier_2 => null);
      raise;
  end xx_om_update_isales_ord;
  -- ==============================================================================================
  -- Name           : xx_om_validate_po
  -- Description    : Procedure To Check Cust PO Number
  -- Parameters description       :
  --
  -- No user parameter
  -- =================================================================================================
  procedure xx_om_validate_po(itemtype in   varchar2
                            , itemkey in    varchar2
                            , actid in      number
                            , funcmode in   varchar2
                            , resultout   out nocopy varchar2) is
    cursor cur_copy_ord(p_org_id number, p_line_id number) is
      select ooha.cust_po_number
           , (select NAME
              from   oe_transaction_types_tl
              where  transaction_type_id = oola.line_type_id and rownum < 2)
               line_type
           , ooha.attribute5 -- Fix For Point# 8
      from   oe_order_lines oola, oe_order_headers ooha
      where  oola.org_id = p_org_id and oola.line_id = p_line_id and oola.header_id = ooha.header_id;
    -- Cursor to verify line hOLD
    cursor c_chk_hold is
      select 'Y'
      from   oe_order_holds a, oe_hold_sources b, oe_hold_definitions c
      where      1 = 1
             and a.line_id = to_number(itemkey)
             and a.hold_source_id = b.hold_source_id
             and c.hold_id = b.hold_id
             and c.NAME = 'Awaiting PO Hold'
             and c.type_code = 'HOLD'
             and a.released_flag = 'N'
             and a.hold_release_id is null
             and trunc(sysdate) between nvl(c.start_date_active, trunc(sysdate)) and nvl(c.end_date_active, trunc(sysdate))
             and c.item_type = 'OEOL';
    l_user_id number;
    l_person_id number;
    l_dest_org_id number;
    l_deliver_to_loc_id number;
    l_err_msg varchar2(150);
    l_cc_id number;
    l_line_num varchar2(100);
    l_line_id number;
    l_org_id number;
    x_hold_exists varchar2(100);
    l_hold_line_type varchar2(10);
    l_temp varchar2(100);
  begin
    -- Extract WF data
    l_org_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
    l_user_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'USER_ID');
    for rec_copy_ord in cur_copy_ord(l_org_id, itemkey) loop
      l_hold_line_type := 'N';
      open po_hold_line_type_cur(rec_copy_ord.line_type);
      fetch po_hold_line_type_cur into l_temp;
      if po_hold_line_type_cur%found then
        l_hold_line_type := 'Y';
      end if;
      close po_hold_line_type_cur;
      --IF rec_copy_ord.line_type IN
      --   ('Bill Only Line', 'Replenishment', 'Non-Replenishment') THEN
      if l_hold_line_type = 'Y' then
        x_hold_exists := 'N';
        open c_chk_hold;
        fetch c_chk_hold into x_hold_exists;
        close c_chk_hold;
        if rec_copy_ord.cust_po_number is null and x_hold_exists = 'Y' then
          resultout := 'COMPLETE:N';
        elsif rec_copy_ord.cust_po_number is not null and x_hold_exists = 'N' then
          resultout := 'COMPLETE:Y';
          xx_om_update_sales_line('BOOKED', l_org_id, itemkey);
        else
          resultout := 'COMPLETE:N';
        end if;
      else
        resultout := 'COMPLETE:Y';
      end if;
    end loop;
  exception
    when others then
      l_err_msg := substr(sqlerrm, 1, 130);
      wf_core.CONTEXT('xx_om_consignment_order_pkg'
                    , 'xx_om_validate_po'
                    , itemtype
                    , itemkey
                    , 'Error ' || l_err_msg);
      raise;
  end xx_om_validate_po;
  -- ==============================================================================================
  -- Name           : xx_om_apply_cust_po_hold
  -- Description    : Procedure To Put Cust PO Number HOLD
  -- Parameters description       :
  --
  -- No user parameter
  -- =================================================================================================
  procedure xx_om_custpo_hold(itemtype in   varchar2
                            , itemkey in    varchar2
                            , actid in      number
                            , funcmode in   varchar2
                            , resultout in out nocopy varchar2) is
    x_order_tbl oe_holds_pvt.order_tbl_type;
    x_hold_id number;
    x_return_status varchar2(1000);
    x_msg_data varchar2(1000);
    x_msg_count number;
    x_hold_exists varchar2(100);
    l_org_id number;
    l_user_id number;
    x_release_reason_code varchar2(100);
    l_hold_line_type varchar2(10);
    l_temp varchar2(100);
    -- Cursor to fetch line details of the SO
    cursor c_oe_order_lines(p_itemkey number) is
      select oel.line_id
           , oel.ship_from_org_id
           , oel.header_id
           , oel.order_source_id
           , oel.inventory_item_id
           , oeh.cust_po_number
           , (select NAME
              from   oe_transaction_types_tl
              where  transaction_type_id = oel.line_type_id and rownum < 2)
               line_type
           , oel.line_number
           , oeh.order_number
           , oel.last_updated_by
           , oeh.attribute5
      from   oe_order_lines oel, oe_order_headers oeh
      where  line_id = p_itemkey and oeh.header_id = oel.header_id;
    -- Cursor to fetch HOLD ID
    cursor c_hold_id is
      select hold_id
      from   oe_hold_definitions
      where      NAME = 'Awaiting PO Hold'
             and type_code = 'HOLD'
             and trunc(sysdate) between nvl(start_date_active, trunc(sysdate)) and nvl(end_date_active, trunc(sysdate))
             and item_type = 'OEOL';
    -- Cursor to verify line hOLD
    cursor c_chk_hold is
      select 'Y'
      from   oe_order_holds a, oe_hold_sources b, oe_hold_definitions c
      where      1 = 1
             and a.line_id = to_number(itemkey)
             and a.hold_source_id = b.hold_source_id
             and c.hold_id = b.hold_id
             and c.NAME = 'Awaiting PO Hold'
             and c.type_code = 'HOLD'
             and a.released_flag = 'N'
             and a.hold_release_id is null
             and trunc(sysdate) between nvl(c.start_date_active, trunc(sysdate)) and nvl(c.end_date_active, trunc(sysdate))
             and c.item_type = 'OEOL';
  begin
    if (funcmode = 'RUN') then
      -- Extract WF data
      l_org_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
      l_user_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'USER_ID');
      x_release_reason_code := 'SUPERVISOR_APPROVE';
      for rec_oe_order_lines in c_oe_order_lines(to_number(itemkey)) loop
        --A lookup now allows line types to be added to/removed from thios logic on the fly
        l_hold_line_type := 'N';
        open po_hold_line_type_cur(rec_oe_order_lines.line_type);
        fetch po_hold_line_type_cur into l_temp;
        if po_hold_line_type_cur%found then
          l_hold_line_type := 'Y';
        end if;
        close po_hold_line_type_cur;
        if l_hold_line_type = 'Y' then
          --IF rec_oe_order_lines.line_type IN
          --   ('Bill Only Line', 'Replenishment', 'Non-Replenishment') THEN
          x_order_tbl(1).header_id := rec_oe_order_lines.header_id;
          x_order_tbl(1).line_id := rec_oe_order_lines.line_id;
          x_hold_exists := 'N';
          open c_chk_hold;
          fetch c_chk_hold into x_hold_exists;
          close c_chk_hold;
          open c_hold_id;
          fetch c_hold_id into x_hold_id;
          close c_hold_id;
          if x_hold_id is not null and x_hold_exists = 'N' and rec_oe_order_lines.cust_po_number is null then
            xx_om_update_sales_line('AWAITING_PO', l_org_id, itemkey);
            oe_holds_pub.apply_holds(p_api_version => 1.0
                                   , p_init_msg_list => fnd_api.g_true
                                   , p_commit => fnd_api.g_false
                                   , p_validation_level => fnd_api.g_valid_level_full
                                   , p_order_tbl => x_order_tbl
                                   , p_hold_id => x_hold_id
                                   , p_hold_until_date => null
                                   , p_hold_comment => null
                                   , p_check_authorization_flag => null
                                   , x_return_status => x_return_status
                                   , x_msg_count => x_msg_count
                                   , x_msg_data => x_msg_data);
          elsif x_hold_id is not null and x_hold_exists = 'Y' and rec_oe_order_lines.cust_po_number is not null then
            xx_om_update_sales_line('BOOKED', l_org_id, itemkey);
            oe_holds_pub.release_holds(p_api_version => 1.0
                                     , p_init_msg_list => fnd_api.g_true
                                     , p_commit => fnd_api.g_false
                                     , p_validation_level => fnd_api.g_valid_level_full
                                     , p_order_tbl => x_order_tbl
                                     , p_hold_id => x_hold_id
                                     , p_release_reason_code => x_release_reason_code
                                     , p_release_comment => null
                                     , p_check_authorization_flag => null
                                     , x_return_status => x_return_status
                                     , x_msg_count => x_msg_count
                                     , x_msg_data => x_msg_data);
          end if;
        end if;
      end loop;
    end if;
    resultout := 'COMPLETE:COMPLETE';
    return;
  exception
    when others then
      wf_core.CONTEXT('xx_om_consignment_order_pkg'
                    , 'xx_om_custpo_hold '
                    , itemtype
                    , itemkey
                    , to_char(actid)
                    , funcmode
                    , 'ERROR : ' || sqlerrm);
      raise;
  end xx_om_custpo_hold;
  -- =================================================================================================
  -- Name           : xx_om_update_sales_line
  -- Description    : Procedure To Update Sales Order Line Status
  -- Parameters description       :
  --
  -- No user parameter
  -- ====================================================================================================
  procedure xx_om_update_sales_line(p_status_code varchar2, p_org_id number, p_line_id number) is
  -- uediga, ticket#1234, commented out pragma auto transaction
    --pragma autonomous_transaction;
    x_conc_req_id number;
    x_org_id number;
    x_user_id number;
    x_resp_id number;
    x_app_id number;
    l_dev_status varchar2(100);
    l_dev_phase varchar2(100);
    l_phase varchar2(100);
    l_status varchar2(30);
    l_message varchar2(4000);
    l_request_complete boolean;
    x_int_ord_num varchar2(1000);
    x_api_version_number number := 1;
    x_header_rec oe_order_pub.header_rec_type;
    x_line_tbl oe_order_pub.line_tbl_type;
    x_action_request_tbl oe_order_pub.request_tbl_type;
    x_line_adj_tbl oe_order_pub.line_adj_tbl_type;
    pp_header_rec_out oe_order_pub.header_rec_type;
    pp_header_val_rec_out oe_order_pub.header_val_rec_type;
    pp_header_adj_tbl_out oe_order_pub.header_adj_tbl_type;
    pp_header_adj_val_tbl_out oe_order_pub.header_adj_val_tbl_type;
    pp_header_price_att_tbl_out oe_order_pub.header_price_att_tbl_type;
    pp_header_adj_att_tbl_out oe_order_pub.header_adj_att_tbl_type;
    pp_header_adj_assoc_tbl_out oe_order_pub.header_adj_assoc_tbl_type;
    pp_header_scredit_tbl_out oe_order_pub.header_scredit_tbl_type;
    pp_header_scredit_val_tbl_out oe_order_pub.header_scredit_val_tbl_type;
    pp_line_tbl_out oe_order_pub.line_tbl_type;
    pp_line_val_tbl_out oe_order_pub.line_val_tbl_type;
    pp_line_adj_tbl_out oe_order_pub.line_adj_tbl_type;
    pp_line_adj_val_tbl_out oe_order_pub.line_adj_val_tbl_type;
    pp_line_price_att_tbl_out oe_order_pub.line_price_att_tbl_type;
    pp_line_adj_att_tbl_out oe_order_pub.line_adj_att_tbl_type;
    pp_line_adj_assoc_tbl_out oe_order_pub.line_adj_assoc_tbl_type;
    pp_line_scredit_tbl_out oe_order_pub.line_scredit_tbl_type;
    pp_line_scredit_val_tbl_out oe_order_pub.line_scredit_val_tbl_type;
    pp_lot_serial_tbl_out oe_order_pub.lot_serial_tbl_type;
    pp_lot_serial_val_tbl_out oe_order_pub.lot_serial_val_tbl_type;
    pp_action_request_tbl_out oe_order_pub.request_tbl_type;
    pp_msg_index number;
    pp_data varchar2(2000);
    pp_loop_count number;
    pp_debug_file varchar2(200);
    pp_return_status varchar2(2000);
    pp_msg_count number;
    pp_msg_data varchar2(2000);
    l_req_no varchar2(100);
    l_iso_number varchar2(100);
    l_error_message varchar2(1000);
    l_order_number varchar2(1000);
    --Update the cust_po_number onto the lines as well
    l_cust_po_number varchar2(100);
    cursor cur_chk_req_no(p_org_id number, p_header_id number) is
      select b.attribute14, b.order_number, b.cust_po_number
      from   oe_order_headers b
      where  b.org_id = p_org_id and b.header_id = p_header_id;
  begin
    l_req_no := null;
    l_order_number := null;
    mo_global.set_policy_context('S', p_org_id);
    mo_global.init('ONT');
    begin
      select header_id
      into   x_line_tbl(1).header_id
      from   oe_order_lines a
      where  a.org_id = p_org_id and a.line_id = p_line_id;
    exception
      when others then
        x_line_tbl(1).header_id := null;
    end;
    open cur_chk_req_no(p_org_id, x_line_tbl(1).header_id);
    fetch cur_chk_req_no
    into l_req_no, l_order_number, l_cust_po_number;
    close cur_chk_req_no;
    x_action_request_tbl(1) := oe_order_pub.g_miss_request_rec;
    -- Line Record --
    x_line_tbl(1) := oe_order_pub.g_miss_line_rec;
    x_line_tbl(1).operation := oe_globals.g_opr_update;
    x_line_tbl(1).line_id := p_line_id;
    x_line_tbl(1).change_reason := 'Not provided';
    x_line_tbl(1).flow_status_code := p_status_code; --- AWAITING_PO
    x_line_tbl(1).cust_po_number := l_cust_po_number;
    oe_order_pub.process_order(p_api_version_number => x_api_version_number
                             , p_org_id => p_org_id
                             , p_header_rec => x_header_rec
                             , p_line_tbl => x_line_tbl
                             , p_action_request_tbl => x_action_request_tbl
                             , p_line_adj_tbl => x_line_adj_tbl
                             , x_header_rec => pp_header_rec_out
                             , x_header_val_rec => pp_header_val_rec_out
                             , x_header_adj_tbl => pp_header_adj_tbl_out
                             , x_header_adj_val_tbl => pp_header_adj_val_tbl_out
                             , x_header_price_att_tbl => pp_header_price_att_tbl_out
                             , x_header_adj_att_tbl => pp_header_adj_att_tbl_out
                             , x_header_adj_assoc_tbl => pp_header_adj_assoc_tbl_out
                             , x_header_scredit_tbl => pp_header_scredit_tbl_out
                             , x_header_scredit_val_tbl => pp_header_scredit_val_tbl_out
                             , x_line_tbl => pp_line_tbl_out
                             , x_line_val_tbl => pp_line_val_tbl_out
                             , x_line_adj_tbl => pp_line_adj_tbl_out
                             , x_line_adj_val_tbl => pp_line_adj_val_tbl_out
                             , x_line_price_att_tbl => pp_line_price_att_tbl_out
                             , x_line_adj_att_tbl => pp_line_adj_att_tbl_out
                             , x_line_adj_assoc_tbl => pp_line_adj_assoc_tbl_out
                             , x_line_scredit_tbl => pp_line_scredit_tbl_out
                             , x_line_scredit_val_tbl => pp_line_scredit_val_tbl_out
                             , x_lot_serial_tbl => pp_lot_serial_tbl_out
                             , x_lot_serial_val_tbl => pp_lot_serial_val_tbl_out
                             , x_action_request_tbl => pp_action_request_tbl_out
                             , x_return_status => pp_return_status
                             , x_msg_count => pp_msg_count
                             , x_msg_data => pp_msg_data);
    commit;
    for i in 1 .. pp_msg_count loop
      oe_msg_pub.get(p_msg_index => i, p_encoded => fnd_api.g_false, p_data => pp_msg_data, p_msg_index_out => pp_msg_index);
      oe_msg_pub.delete_msg(p_msg_index => pp_msg_index);
    end loop;
    commit;
    log_message('SO Update Line Status End - ' || p_line_id || ' - ' || p_status_code);
  exception
    when others then
      l_error_message := 'Unexpected Error In xx_om_update_sales_line procedure ' || substr(sqlerrm, 11, 150);
      log_message(l_error_message);
      xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_medium
                     , p_category => 'Consignment Process'
                     , p_error_text => l_error_message
                     , p_record_identifier_1 => l_order_number
                     , p_record_identifier_2 => null);
      raise;
  end xx_om_update_sales_line;
  ----------------------------------------------------------------------------------------
  -- Description: New procedure to verify Booking eligibility for
  -- ILS Product Request Order Type Only.
  -- This procedure along with new Order header Workflow Branch validates eligibility.
  -- OEOH : XXOM_PROD_REQ_HEADER -- XXOM Order Flow - Product Request
  -- Date : 02/25/2014 --
  ----------------------------------------------------------------------------------------
  procedure xxom_verify_wsh(itemtype in   varchar2
                          , itemkey in    varchar2
                          , actid in      number
                          , funcmode in   varchar2
                          , resultout   out nocopy varchar2) is
    x_org_id number;
    lexists varchar2(20);
    p_result number;
    l_count number;
  begin
    log_message('OM WF - Begin for Item key' || itemkey);
    g_itemkey := itemkey; -- Order Header Id
    x_org_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
    g_org_id := x_org_id;
    log_message('OM WF - Check Warehouse ' || itemkey);
    --OE_MSG_PUB.initialize;
    begin
      p_result := 0;
      select count(*)
      into   l_count
      from   oe_order_lines_all
      where  header_id = g_itemkey and ship_from_org_id is null and org_id = g_org_id;
      p_result := 1;
      log_message(itemkey || ' OM WF - Check Warehouse ' || p_result);
    exception
      when others then
        p_result := 0;
        log_message(itemkey || ' OM WF - Check Warehouse' || p_result);
    end;
    if (l_count <> 0) then
      -- IF (p_result = 1) then
      FND_MESSAGE.SET_NAME('XXINTG', 'XXOM_ORDER_BOOK_PROD_REQ');
      --FND_MESSAGE.SET_TOKEN('LINE_NUM',l_t_line_number(i));
      OE_MSG_PUB.ADD;
      resultout := 'COMPLETE:N';
      --OE_STANDARD_WF.Save_Messages;
      --OE_STANDARD_WF.Clear_Msg_Context;
    else
      log_message(itemkey || ' OM WF - Complete');
      resultout := 'COMPLETE:Y';
    end if;
  end xxom_verify_wsh;
  procedure xx_om_create_ir_iso(itemtype in   varchar2
                            , itemkey in    varchar2
                            , actid in      number
                            , funcmode in   varchar2
                            , resultout in out nocopy varchar2) is
  l_int_req_ret_sts varchar2(1);
  l_req_header_rec po_create_requisition_sv.header_rec_type;
  l_req_line_tbl po_create_requisition_sv.line_tbl_type;
  l_created_by number;
  l_org_id number;
  l_preparer_id number;
  l_destination_org_id number;
  l_deliver_to_locn_id number;
  l_msg_count number;
  l_msg_data varchar2(2000);
  k number := 0;
  j number := 0;
  l_item_exists varchar2(50);
  l_item varchar2(50);
  v_msg_index_out number;
  g_pkg_name varchar2(30) := 'auto_create_internal_req';
  l_header_id number;
  x_return_status varchar2(1000);
  l_dest_subinventory mtl_secondary_inventories.secondary_inventory_name%type;
  l_order_locator_id mtl_item_locations.INVENTORY_LOCATION_ID%type;
  l_source_org_code varchar2(10);
  l_dest_lpn_id number;
  l_cust_po_number oe_order_headers.cust_po_number%type;
  l_temp_employee_id number;
  l_order_source_id number;
  l_source_document_id number;
  cursor ord_hdr_cur(p_header_id in number) is
    select created_by, org_id, cust_po_number,order_source_id,source_document_id
    from   oe_order_headers
    where  header_id = p_header_id;
  cursor ord_line_cur(p_header_id in number) is
    select line_id, order_quantity_uom, ordered_quantity, ship_to_org_id, inventory_item_id, schedule_ship_date, org_id, ship_from_org_id
         , sold_to_org_id, subinventory, source_document_id, source_document_line_id, item_type_code
    from   oe_order_lines
    where  header_id = p_header_id and nvl(cancelled_flag, 'N') = 'N';
    -- and nvl(booked_flag, 'N') = 'Y';
  cursor employee_id_cur(p_user_id in number) is
    select employee_id
    from   fnd_user
    where  user_id = p_user_id;
  cursor dest_org_locn_cur(p_cust_id in number) is
    select b.location_id, b.organization_id
    from   oe_ship_to_orgs_v a, po_location_associations b
    where  a.organization_id = b.site_use_id and a.organization_id = p_cust_id;
begin
  oe_debug_pub.ADD(' Entering procedure auto_create_internal_req ', 2);
  l_header_id := to_number(itemkey);
  x_return_status := fnd_api.g_ret_sts_success;
  l_cust_po_number := null;
  open ord_hdr_cur(l_header_id);
  fetch ord_hdr_cur
  into l_created_by, l_org_id, l_cust_po_number,l_order_source_id,l_source_document_id;
  close ord_hdr_cur;
  oe_debug_pub.ADD('auto_create_internal_req after hdr query ', 2);
 if nvl(l_order_source_id,-1)<>10 then
  begin
    open employee_id_cur(l_created_by);
    fetch employee_id_cur into l_preparer_id;
    close employee_id_cur;
  exception
    when no_data_found then
      l_preparer_id := null;
    when others then
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      raise fnd_api.g_exc_unexpected_error;
  end;
  if l_preparer_id is null then
    fnd_message.set_name('XXINTG', 'INTG_DEL_TO_PERSON_NOT_FOUND');
    oe_msg_pub.ADD;
    x_return_status := fnd_api.g_ret_sts_error;
    raise fnd_api.g_exc_error;
  end if;
  l_temp_employee_id := Oe_Sys_Parameters.value('ONT_EMP_ID_FOR_SS_ORDERS', l_org_id);
  if l_temp_employee_id is null then
    fnd_message.set_name('XXINTG', 'INTG_DEFAULT_PREP_NOT_FOUND');
    oe_msg_pub.ADD;
    x_return_status := fnd_api.g_ret_sts_error;
    raise fnd_api.g_exc_error;
  end if;
  l_req_header_rec.preparer_id := l_temp_employee_id;
  l_req_header_rec.summary_flag := 'N';
  l_req_header_rec.enabled_flag := 'Y';
  l_req_header_rec.authorization_status := 'APPROVED';
  l_req_header_rec.type_lookup_code := 'INTERNAL';
  l_req_header_rec.transferred_to_oe_flag := 'Y';
  l_req_header_rec.org_id := l_org_id;
  log_message('Header Data Populated ' || l_header_id);
  for cur_ord_line in ord_line_cur(l_header_id) loop
    j := j + 1;
    if cur_ord_line.item_type_code <> oe_globals.g_item_standard then
    log_message('Item type check' || l_header_id || ' / ' || cur_ord_line.inventory_item_id);
      fnd_message.set_name('ONT', 'ONT_ISO_ITEM_TYPE_NOT_STD');
      oe_msg_pub.ADD;
      x_return_status := fnd_api.g_ret_sts_error;
      raise fnd_api.g_exc_error;
    end if;
    begin
      open dest_org_locn_cur(cur_ord_line.ship_to_org_id);
      fetch dest_org_locn_cur
      into l_deliver_to_locn_id, l_destination_org_id;
      close dest_org_locn_cur;
    exception
      when no_data_found then
        l_destination_org_id := null;
        l_deliver_to_locn_id := null;
        begin
          select organization_id
          into   l_destination_org_id
          from   org_organization_definitions
          where  organization_code = '150';
        exception
          when others then
            l_destination_org_id := null;
        end;
        begin
          select location_id
          into   l_deliver_to_locn_id
          from   po_location_associations
          where  site_use_id = cur_ord_line.ship_to_org_id;
        exception
          when others then
            l_deliver_to_locn_id := null;
        end;
    end;
    log_message('Deliver To location ID is' || l_deliver_to_locn_id);
    if l_deliver_to_locn_id is null then
      log_message('Deliver to Location Not found for ship to site_use_id' || l_header_id || ' / ' || cur_ord_line.ship_to_org_id);
      fnd_message.set_name('XXINTG', 'INTG_OM_DELIVER_TO_LOCATION');
      oe_msg_pub.ADD;
      x_return_status := fnd_api.g_ret_sts_error;
      resultout := 'COMPLETE:N';
      raise fnd_api.g_exc_error;
    end if;
    l_item_exists := 'N';
    l_item:=null;
    begin
      select 'Y'
      into   l_item_exists
      from   mtl_system_items_b
      where  inventory_item_id = cur_ord_line.inventory_item_id
             and organization_id = (select organization_id
                                    from   mtl_parameters
                                    where  organization_code = '150');
    log_message('Item assigned to 150?' || l_item_exists);
    exception
      when others then
        log_message('Item is not assigned to consignment organization. ' || l_header_id || ' / ' || cur_ord_line.inventory_item_id);
        select segment1
      into   l_item
      from   mtl_system_items_b
      where  inventory_item_id = cur_ord_line.inventory_item_id
             and organization_id = (select organization_id
                                    from   mtl_parameters
                                    where  organization_code = 'MST');
        fnd_message.set_name('XXINTG', 'INTG_OM_ITEM_NOT_ASSIGNED');
        fnd_message.set_token('ITEM', l_item);
        oe_msg_pub.ADD;
        x_return_status := fnd_api.g_ret_sts_error;
        resultout := 'COMPLETE:N';
        raise fnd_api.g_exc_error;
    end;
    begin
      select secondary_inventory_name
      into   l_dest_subinventory
      from   mtl_secondary_inventories msi
      where  msi.location_id = l_deliver_to_locn_id
      and organization_id=l_destination_org_id;
      log_message('Destination Subinventory' || l_dest_subinventory);
    exception
      when others then
        log_message('Invalid ISO subinventory. ' || l_header_id || ' / ' || cur_ord_line.sold_to_org_id);
        fnd_message.set_name('XXINTG', 'INTG_OM_INVALID_ISO_SUBINV');
        oe_msg_pub.ADD;
        x_return_status := fnd_api.g_ret_sts_error;
        resultout := 'COMPLETE:N';
        raise fnd_api.g_exc_error;
    end;
    begin
      l_order_locator_id := null;
      if l_dest_subinventory = 'RECONKIT' then
        select inventory_location_id
        into   l_order_locator_id
        from   mtl_item_locations
        where  Subinventory_code = 'RECONKIT' and segment1 = 'RECONKIT' and segment2 = 'REC' and segment3 = '001';
      elsif l_dest_subinventory = 'NEUROKIT' then
        select inventory_location_id
        into   l_order_locator_id
        from   mtl_item_locations
        where  Subinventory_code = 'NEUROKIT' and segment1 = 'NEUROKIT' and segment2 = 'NEU' and segment3 = '001';
      elsif l_dest_subinventory = 'SPINEKIT' then
        begin
          select organization_code
          into   l_source_org_code
          from   mtl_parameters
          where  organization_id = cur_ord_line.ship_from_org_id;
        exception
          when others then
            null;
        end;
        if l_source_org_code = '160' then
          select inventory_location_id
          into   l_order_locator_id
          from   mtl_item_locations
          where  Subinventory_code = 'SPINEKIT' and segment1 = 'SPINEKIT' and segment2 = 'SPI' and segment3 = 'ODC';
        elsif l_source_org_code = '180' then
          select inventory_location_id
          into   l_order_locator_id
          from   mtl_item_locations
          where  Subinventory_code = 'SPINEKIT' and segment1 = 'SPINEKIT' and segment2 = 'SPI' and segment3 = 'VDC';
        end if;
      else
        begin
          select mil.inventory_location_id
          into   l_order_locator_id
          from   mtl_item_locations mil, xxom_sales_marketing_set_v xsms
          where      mil.organization_id = l_destination_org_id
                 and upper(mil.subinventory_code) = upper(l_dest_subinventory)
                 and xsms.inventory_item_id = cur_ord_line.inventory_item_id
                 and xsms.organization_id = l_destination_org_id
                 and upper(mil.segment1) = upper(l_dest_subinventory)
                 and mil.segment2 = substr(snm_division, 1, 3)
                 and mil.segment3 = '001';
        exception
          when others then
            begin
              select mil.inventory_location_id
              into   l_order_locator_id
              from   mtl_item_locations mil
              where      mil.organization_id = l_destination_org_id
                     and upper(mil.subinventory_code) = upper(l_dest_subinventory)
                     and upper(mil.segment1) = upper(l_dest_subinventory)
                     and mil.segment2 = '001'
                     and mil.segment3 = '001';
            exception
              when others then
                log_message(   'Error Replishment Request - Locator Derivation: '
                            || l_dest_subinventory
                            || ' for Item '
                            || cur_ord_line.inventory_item_id);
            end;
        end;
      end if;
      l_dest_lpn_id := null;
      begin
        select lpn_id
        into   l_dest_lpn_id
        from   wms_license_plate_numbers
        where  license_plate_number = l_cust_po_number;
      exception
        when others then
          log_message('LPN ID - Unable to find for - ' || l_cust_po_number);
      end;
    end;
    log_message('Destination Locator ' || l_order_locator_id);
    if l_order_locator_id is null then
      log_message('Invalid ISO Locator. ' || l_header_id || ' / ' || cur_ord_line.inventory_item_id || ' / ' || l_dest_subinventory);
      fnd_message.set_name('XXINTG', 'INTG_OM_INVALID_DEST_LOCATOR');
      oe_msg_pub.ADD;
      x_return_status := fnd_api.g_ret_sts_error;
      resultout := 'COMPLETE:N';
      raise fnd_api.g_exc_error;
    end if;
    l_req_line_tbl(j).line_num := j;
    l_req_line_tbl(j).line_type_id := 1;
    l_req_line_tbl(j).source_doc_line_reference := cur_ord_line.line_id;
    l_req_line_tbl(j).uom_code := cur_ord_line.order_quantity_uom;
    l_req_line_tbl(j).quantity := cur_ord_line.ordered_quantity;
    l_req_line_tbl(j).deliver_to_location_id := l_deliver_to_locn_id;
    l_req_line_tbl(j).destination_type_code := 'INVENTORY';
    l_req_line_tbl(j).destination_organization_id := l_destination_org_id;
    l_req_line_tbl(j).destination_subinventory := l_dest_subinventory;
    l_req_line_tbl(j).to_person_id := l_preparer_id;
    l_req_line_tbl(j).source_type_code := 'INVENTORY';
    l_req_line_tbl(j).item_id := cur_ord_line.inventory_item_id;
    l_req_line_tbl(j).need_by_date := nvl(cur_ord_line.schedule_ship_date, sysdate);
    l_req_line_tbl(j).source_organization_id := cur_ord_line.ship_from_org_id;
    l_req_line_tbl(j).org_id := cur_ord_line.org_id;
  end loop;
  oe_debug_pub.ADD(' auto_create_internal_req before PO API call ', 2);
  begin
    po_create_requisition_sv.process_requisition(px_header_rec => l_req_header_rec
                                               , px_line_table => l_req_line_tbl
                                               , x_return_status => l_int_req_ret_sts
                                               , x_msg_count => l_msg_count
                                               , x_msg_data => l_msg_data);
    if l_int_req_ret_sts = fnd_api.g_ret_sts_unexp_error then
      oe_debug_pub.ADD(' PO API call returned unexpected error ' || l_msg_data, 2);
      log_message('po_create_requisition_sv - returned unexpected error ' || l_header_id);
      log_message(l_msg_data);
      fnd_message.set_name('XXINTG', 'INTG_ISO_CREATION_FAILED');
      oe_msg_pub.ADD;
      resultout := 'COMPLETE:N';
      raise fnd_api.g_exc_unexpected_error;
    elsif l_int_req_ret_sts = fnd_api.g_ret_sts_error then
      oe_debug_pub.ADD(' PO API call returned error ' || l_msg_data, 2);
      log_message('po_create_requisition_sv - returned error ' || l_header_id);
      log_message(l_msg_data);
      fnd_message.set_name('XXINTG', 'INTG_ISO_CREATION_FAILED');
      oe_msg_pub.ADD;
      resultout := 'COMPLETE:N';
      raise fnd_api.g_exc_error;
    end if;
  end;
  if l_msg_count > 0 then
    for v_index in 1 .. l_msg_count loop
      oe_msg_pub.get(p_msg_index => v_index, p_encoded => 'F', p_data => l_msg_data, p_msg_index_out => v_msg_index_out);
      log_message(l_msg_data);
    end loop;
  end if;
  if (l_req_line_tbl.count()>0 and l_req_header_rec.requisition_header_id >0) then
    update oe_order_headers
    set    ATTRIBUTE14 = ORIG_SYS_DOCUMENT_REF
    where  header_id = l_header_id;
    log_message('Updating Header - Related Order ' || l_header_id);
    update oe_order_headers
    set    source_document_id = l_req_header_rec.requisition_header_id
         , orig_sys_document_ref = l_req_header_rec.segment1
         , source_document_type_id = oe_globals.g_order_source_internal
         , order_source_id = oe_globals.g_order_source_internal
    where  header_id = l_header_id;
    oe_debug_pub.add('auto_create_internal_req after hdr update ', 2);
    for k in 1 .. l_req_line_tbl.count loop
      if (l_req_line_tbl(k).requisition_line_id is not null) then
        update oe_order_lines
        set    source_document_id = l_req_header_rec.requisition_header_id
             , source_document_line_id = l_req_line_tbl(k).requisition_line_id
             , source_document_type_id = oe_globals.g_order_source_internal
             , orig_sys_document_ref = l_req_header_rec.segment1
             , orig_sys_line_ref = l_req_line_tbl(k).line_num
             , global_attribute14 = nvl(l_order_locator_id, global_attribute14)
             , global_attribute15 = nvl(l_dest_lpn_id, global_attribute15)
        where  oe_order_lines.line_id = l_req_line_tbl(k).source_doc_line_reference and header_id = l_header_id;
      end if;
    end loop;
    oe_debug_pub.add('auto_create_internal_req after line update ', 2);
    
    -- 1.9 Case 9143
    -- update po requisition tables
    UPDATE po_requisition_lines_all
    SET    transferred_to_oe_flag = 'Y'
    WHERE  requisition_header_id  = l_req_header_rec.requisition_header_id ;
    
    UPDATE po_requisition_headers_all
    SET    transferred_to_oe_flag = 'Y'
    WHERE  requisition_header_id  = l_req_header_rec.requisition_header_id ;
    
    oe_debug_pub.add('auto_create_internal_req after requisition update ', 2);
     
    resultout := 'COMPLETE:Y';
    x_return_status := fnd_api.g_ret_sts_success;
    fnd_message.set_name('XXINTG', 'INTG_ISO_CREATION_SUCCESS');
      oe_msg_pub.ADD;
      OE_STANDARD_WF.Save_Messages;
      OE_STANDARD_WF.Clear_Msg_Context;
    else
    x_return_status := fnd_api.g_ret_sts_error;
    resultout := 'COMPLETE:N';
   raise fnd_api.g_exc_error;
  end if;
 end if;
  --resultout := 'COMPLETE:Y';
exception
  when fnd_api.g_exc_unexpected_error then
    log_message('Unexpected error in xx_om_create_ir_iso ' || l_header_id);
    x_return_status := fnd_api.g_ret_sts_unexp_error;
    fnd_message.set_name('XXINTG', 'INTG_ISO_CREATION_FAILED');
    oe_msg_pub.ADD;
    resultout := 'COMPLETE:N';
    OE_STANDARD_WF.Save_Messages;
    OE_STANDARD_WF.Clear_Msg_Context;
    oe_debug_pub.add('auto_create_internal_req: In Unexpected error', 2);
    wf_core.context('xx_om_consignment_order_pkg'
                  , 'xx_om_create_ir_iso'
                  , itemtype
                  , itemkey
                  , 'xx_om_create_ir_iso');
  when fnd_api.g_exc_error then
    log_message('Error in xx_om_create_ir_iso ' || l_header_id);
    x_return_status := fnd_api.g_ret_sts_error;
    oe_debug_pub.add('auto_create_internal_req: In execution error', 2);
    resultout := 'COMPLETE:N';
    OE_STANDARD_WF.Save_Messages;
    OE_STANDARD_WF.Clear_Msg_Context;
  when others then
    log_message('WHEN OTHERS in xx_om_create_ir_iso ' || l_header_id || ' / ' || sqlerrm);
    oe_debug_pub.add('auto_create_internal_req: In Other error', 2);
    if oe_msg_pub.check_msg_level(oe_msg_pub.g_msg_lvl_unexp_error) then
      oe_msg_pub.add_exc_msg(g_pkg_name, 'auto_create_internal_req');
    end if;
    x_return_status := fnd_api.g_ret_sts_unexp_error;
    wf_core.context('xx_om_consignment_order_pkg'
                  , 'xx_om_create_ir_iso'
                  , itemtype
                  , itemkey
                  , 'xx_om_create_ir_iso');
    resultout := 'COMPLETE:N';
    raise;
end xx_om_create_ir_iso;

  --Local procedure to copy fnd_attachments from one order to another.
  --Currently ony copies SOI related SHORT_TEXT attachments and Replenishment attachments of all types.
  --Could be extends to copy others.
  procedure copy_attachments(p_from_header_id in number, p_to_header_id in number) is
    /*CURSOR existing_attachment_cur (p_header_id IN NUMBER) IS
       SELECT d.category_id, dc.user_name, dtl.description, dst.short_text
         FROM apps.fnd_attached_documents ad,
              apps.fnd_documents d,
              apps.fnd_document_categories_vl dc,
              apps.fnd_documents_tl dtl,
              apps.fnd_documents_short_text dst
        WHERE ad.entity_name = 'OE_ORDER_HEADERS'
          AND ad.pk1_value = p_header_id
          AND ad.document_id = d.document_id
          AND d.datatype_id = 1--SHORT_TEXT
          AND d.category_id = dc.category_id
          AND dc.user_name IN ('CSR Internal',
                               'To print on Sales Order Ack',
                               'To print on Pack Slip',
                               'To print on Sales Shipping Confirmation',
                               'Short Text')
          AND d.document_id = dtl.document_id
          --Should we also check the dtl.description for the values passed by SOI?
          --'Internal Note', 'External Note', 'Shipping Note'
          AND dtl.language = 'US'
          AND d.media_id = dst.media_id;

    v_attachment_id           NUMBER;
    v_attachment_status       VARCHAR2 (30);
    v_attachment_msg_cnt      NUMBER;
    v_attachment_msgs         VARCHAR2 (2000);
 BEGIN
    log_message ('Copying attachments from ' || p_from_header_id || ' to ' || p_to_header_id);
    FOR existing_attachment_rec IN existing_attachment_cur (p_from_header_id) LOOP
       log_message ('Copying attachment: ' || existing_attachment_rec.description);
       oe_atchmt_util.add_attachment (p_api_version        => 1.0,
                                      p_entity_code        => oe_globals.g_entity_header,
                                      p_entity_id          => p_to_header_id,
                                      p_document_desc      => existing_attachment_rec.description,
                                      p_document_text      => existing_attachment_rec.short_text,
                                      p_category_id        => existing_attachment_rec.category_id,
                                      p_document_id        => NULL,
                                      x_attachment_id      => v_attachment_id,
                                      x_return_status      => v_attachment_status,
                                      x_msg_count          => v_attachment_msg_cnt,
                                      x_msg_data           => v_attachment_msgs
                                     );
       log_message ('Result: ' || v_attachment_status || '/' || v_attachment_msgs);

    END LOOP;*/
    --The above was the original, manual-copy method
    v_attachment_status varchar2(30);
  begin
    oe_atchmt_util.copy_attachments(p_entity_code => oe_globals.g_entity_header
                                  , p_from_entity_id => p_from_header_id
                                  , p_to_entity_id => p_to_header_id
                                  , p_manual_attachments_only => 'Y'
                                  , x_return_status => v_attachment_status);
    log_message('Attachment copy status: ' || v_attachment_status);
  --RESOLVE: Should we delete any copied attchments (from p_to_header_id) that do not match the selected categories?
  -- Or just leave them all?
  end copy_attachments;
  /*
  || This procedure is called to replicate the Deliver To address from the original SO (which is under the SO customer),
  || to a new address under the salesrep account.
  ||
  || It calls a series of subprocedures to create the individual HZ elements.
  ||
  || If any HZ element matches the one about to be created, it's ID is returned instead of creating a duplicate.
  */
  procedure create_rep_deliver_to(p_salesrep_id in number, p_so_deliver_to_org_id in number, x_iso_deliver_to_org_id out number) is
    so_dt_address_rec so_dt_address_cur%rowtype;
    l_cust_acct_id number;
    l_party_id number;
    l_salesrep_number varchar2(50);
    l_location_id number;
    l_cust_acct_site_id number;
  begin
    if p_so_deliver_to_org_id is null then
      --Nothing can be done. Exit.
      raise no_data_found;
    end if;
    open so_dt_address_cur(p_so_deliver_to_org_id);
    fetch so_dt_address_cur into so_dt_address_rec;
    if so_dt_address_cur%notfound then
      --Nothing can be done. Exit.
      close so_dt_address_cur;
      log_message('Csnnot locate SO DT Address Data from SU: ' || p_so_deliver_to_org_id);
      raise no_data_found;
    else
      close so_dt_address_cur;
    end if;
    --Now so_dt_address_rec has everyting we need to continue.
    log_message('Trying to create a deliver to location.');
    -- This belongs with the Rep, so I need to look up their customer_account_id and party_site_number
    begin
      select pla.customer_id, hca.party_id, jrs.salesrep_number
      into   l_cust_acct_id, l_party_id, l_salesrep_number
      from   jtf_rs_salesreps jrs
           , mtl_secondary_inventories msi
           , hr_locations hl
           , po_location_associations_all pla
           , hz_cust_site_uses_all ship_to
           , hz_cust_site_uses_all bill_to
           , hz_cust_accounts hca
      where      hca.cust_account_id = pla.customer_id
             and bill_to.site_use_code = 'BILL_TO'
             and bill_to.cust_acct_site_id = ship_to.cust_acct_site_id
             and ship_to.site_use_id = pla.site_use_id
             and pla.location_id = hl.location_id
             and hl.location_id = msi.location_id
             and msi.attribute2 = jrs.salesrep_number
             and jrs.salesrep_id = p_salesrep_id;
    exception
      when others then
        raise no_data_found;
    end;
    log_message('cust_account_id: ' || l_cust_acct_id);
    -- create the address first
    create_location(p_party_id => l_party_id, p_loc_data => so_dt_address_rec, x_location_id => l_location_id);
    log_message('location_id: ' || l_location_id);
    -- Now create the party site
    create_sites(p_party_id => l_party_id
               , p_cust_acct_id => l_cust_acct_id
               , p_location_id => l_location_id
               , p_salesrep_number => l_salesrep_number
               , x_cust_acct_site_id => l_cust_acct_site_id);
    log_message('cust_acct_site_id: ' || l_cust_acct_site_id);
    -- Create the Site Use
    create_site_use(p_cust_acct_site_id => l_cust_acct_site_id, p_site_use_code => 'DELIVER_TO', x_site_use_id => x_iso_deliver_to_org_id);
    log_message('site_use_id: ' || x_iso_deliver_to_org_id);
  exception
    when no_data_found then
      x_iso_deliver_to_org_id := null;
    when others then
      x_iso_deliver_to_org_id := null;
  end create_rep_deliver_to;
  --Called during the creation of the DT Site under the salesrep's account
  procedure create_location(p_party_id in number, p_loc_data in so_dt_address_cur%rowtype, x_location_id out number) is
    v_location_rec HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
    v_location_id number;
    v_return_status varchar2(2000);
    v_msg_count number;
    v_msg_data varchar2(20000);
    cursor existing_loc_cur(p_party_id in number
                          , p_loc_data so_dt_address_cur%rowtype) is
      select loc.location_id
      from   hz_party_sites ps, hz_locations loc
      where      loc.location_id = ps.location_id
             and ps.party_id = p_party_id
             and loc.address1 = p_loc_data.address1
             and loc.postal_code = p_loc_data.postal_code;
  begin
    log_message('- In create_location');
    open existing_loc_cur(p_party_id, p_loc_data);
    fetch existing_loc_cur into v_location_id;
    if existing_loc_cur%found then
      --This party already had this
      log_message('- - Location already exists: ' || v_location_id || '  Continuing...');
    else
      --Create the location
      v_location_rec.country := 'US'; --Really?
      v_location_rec.address1 := p_loc_data.address1;
      v_location_rec.address2 := p_loc_data.address2;
      v_location_rec.city := p_loc_data.city;
      v_location_rec.postal_code := p_loc_data.postal_code;
      v_location_rec.state := p_loc_data.state;
      v_location_rec.created_by_module := c_created_by_module; --Must link to Receivables lookup type: HZ_CREATED_BY_MODULES
      HZ_LOCATION_V2PUB.CREATE_LOCATION(p_init_msg_list => FND_API.G_TRUE
                                      , p_location_rec => v_location_rec
                                      , x_location_id => v_location_id
                                      , x_return_status => v_return_status
                                      , x_msg_count => v_msg_count
                                      , x_msg_data => v_msg_data);
      if v_return_status = FND_API.G_RET_STS_SUCCESS then
        log_message('- - Created Location ID: ' || v_location_id);
      else
        log_message('- - x_return_status = ' || substr(v_return_status, 1, 255));
        log_message('- - x_msg_count = ' || to_char(v_msg_count));
        log_message('- - x_msg_data = ' || substr(v_msg_data, 1, 255));
        if v_msg_count > 1 then
          for I in 1 .. v_msg_count loop
            log_message('- - ' || I || '. ' || substr(FND_MSG_PUB.GET(p_encoded => FND_API.G_FALSE), 1, 255));
          end loop;
        end if;
      end if;
    end if;
    close existing_loc_cur;
    x_location_id := v_location_id;
  end create_location;
  --Called during the creation of the DT Site under the salesrep's account
  procedure create_sites(p_party_id in number
                       , p_cust_acct_id in number
                       , p_location_id in number
                       , p_salesrep_number in varchar2
                       , x_cust_acct_site_id   out number) is
    v_party_site_rec HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
    v_party_site_id number;
    v_party_site_num varchar2(100);
    v_cust_acct_site_rec HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
    v_cust_acct_site_id number;
    v_return_status varchar2(2000);
    v_msg_count number;
    v_msg_data varchar2(20000);
    cursor existing_ps_cur(p_party_id number, p_location_id number) is
      select ps.party_site_id
      from   hz_party_sites ps
      where  ps.location_id = p_location_id and ps.party_id = p_party_id;
    cursor existing_cas_cur(p_cust_acct_id number, p_party_site_id number) is
      select cust_acct_site_id
      from   hz_cust_acct_sites_all
      where  cust_account_id = p_cust_acct_id and party_site_id = p_party_site_id;
  begin
    log_message('- In create_sites');
    --Create the Party Site
    open existing_ps_cur(p_party_id, p_location_id);
    fetch existing_ps_cur into v_party_site_id;
    if existing_ps_cur%found then
      --This party already had a site for this location
      log_message('- - Party Site already exists: ' || v_party_site_id || '  Continuing...');
    else
      v_party_site_rec.party_id := p_party_id;
      v_party_site_rec.location_id := p_location_id;
      v_party_site_rec.attribute1 := p_salesrep_number; --Triggers sending this to Surgisoft
      v_party_site_rec.created_by_module := c_created_by_module; --Must link to Receivables lookup type: HZ_CREATED_BY_MODULES
      HZ_PARTY_SITE_V2PUB.CREATE_PARTY_SITE(p_init_msg_list => FND_API.G_TRUE
                                          , p_party_site_rec => v_party_site_rec
                                          , x_party_site_id => v_party_site_id
                                          , x_party_site_number => v_party_site_num
                                          , x_return_status => v_return_status
                                          , x_msg_count => v_msg_count
                                          , x_msg_data => v_msg_data);
      if v_return_status = FND_API.G_RET_STS_SUCCESS then
        log_message('- - Created Party Site ID: ' || v_party_site_id);
      else
        log_message('- - x_return_status = ' || substr(v_return_status, 1, 255));
        log_message('- - x_msg_count = ' || to_char(v_msg_count));
        log_message('- - x_msg_data = ' || substr(v_msg_data, 1, 255));
        if v_msg_count > 1 then
          for I in 1 .. v_msg_count loop
            log_message('- - ' || I || '. ' || substr(FND_MSG_PUB.GET(p_encoded => FND_API.G_FALSE), 1, 255));
          end loop;
        end if;
      end if;
    end if;
    close existing_ps_cur;
    --Create the Cust Acct Site
    open existing_cas_cur(p_cust_acct_id, v_party_site_id);
    fetch existing_cas_cur into v_cust_acct_site_id;
    if existing_cas_cur%found then
      --This customer already had a site for this location
      log_message('- - Cust Acct Site already exists: ' || v_cust_acct_site_id || '  Continuing...');
    else
      v_cust_acct_site_rec.cust_account_id := p_cust_acct_id;
      v_cust_acct_site_rec.party_site_id := v_party_site_id;
      v_cust_acct_site_rec.created_by_module := c_created_by_module; --Must link to Receivables lookup type: HZ_CREATED_BY_MODULES
      HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE(p_init_msg_list => FND_API.G_TRUE
                                                     , p_cust_acct_site_rec => v_cust_acct_site_rec
                                                     , x_cust_acct_site_id => v_cust_acct_site_id
                                                     , x_return_status => v_return_status
                                                     , x_msg_count => v_msg_count
                                                     , x_msg_data => v_msg_data);
      if v_return_status = FND_API.G_RET_STS_SUCCESS then
        log_message('- - Created Cust Acct Site ID: ' || v_cust_acct_site_id);
      else
        log_message('- - x_return_status = ' || substr(v_return_status, 1, 255));
        log_message('- - x_msg_count = ' || to_char(v_msg_count));
        log_message('- - x_msg_data = ' || substr(v_msg_data, 1, 255));
        if v_msg_count > 1 then
          for I in 1 .. v_msg_count loop
            log_message('- - ' || I || '. ' || substr(FND_MSG_PUB.GET(p_encoded => FND_API.G_FALSE), 1, 255));
          end loop;
        end if;
      end if;
    end if;
    close existing_cas_cur;
    x_cust_acct_site_id := v_cust_acct_site_id;
  end create_sites;
  procedure create_site_use(p_cust_acct_site_id in number, p_site_use_code in varchar2, x_site_use_id out number) is
    v_site_use_rec HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
    v_site_use_id number;
    v_st_site_use_rec HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
    v_st_site_id number;
    v_cust_profile_rec HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
    v_return_status varchar2(2000);
    v_msg_count number;
    v_msg_data varchar2(20000);
    cursor existing_su_cur(p_cust_acct_site_id number, p_site_use_code varchar2) is
      select site_use_id
      from   hz_cust_site_uses_all
      where  cust_acct_site_id = p_cust_acct_site_id and site_use_code = p_site_use_code and status = 'A';
  begin
    log_message('- In create_site_use ' || p_site_use_code);
    --Create BILL_TO Cust Site Uses (Creates Party Site Uses as a side-effect)
    open existing_su_cur(p_cust_acct_site_id, p_site_use_code);
    fetch existing_su_cur into v_site_use_id;
    if existing_su_cur%found then
      --This cust acct site already has a site use of this type
      log_message('- - ' || p_site_use_code || ' Cust Site Use already exists: ' || v_site_use_id || '  Continuing...');
    else
      v_site_use_rec.cust_acct_site_id := p_cust_acct_site_id;
      v_site_use_rec.site_use_code := p_site_use_code;
      v_site_use_rec.created_by_module := c_created_by_module; --Must link to Receivables lookup type: HZ_CREATED_BY_MODULES
      HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE(p_init_msg_list => FND_API.G_TRUE
                                                    , p_cust_site_use_rec => v_site_use_rec
                                                    , p_customer_profile_rec => v_cust_profile_rec
                                                    , p_create_profile => FND_API.G_FALSE
                                                    , p_create_profile_amt => FND_API.G_FALSE
                                                    , x_site_use_id => v_site_use_id
                                                    , x_return_status => v_return_status
                                                    , x_msg_count => v_msg_count
                                                    , x_msg_data => v_msg_data);
      if v_return_status = FND_API.G_RET_STS_SUCCESS then
        log_message('- - Created ' || p_site_use_code || ' Site Use ID: ' || v_site_use_id);
      else
        log_message('- - x_return_status = ' || substr(v_return_status, 1, 255));
        log_message('- - x_msg_count = ' || to_char(v_msg_count));
        log_message('- - x_msg_data = ' || substr(v_msg_data, 1, 255));
        if v_msg_count > 1 then
          for I in 1 .. v_msg_count loop
            log_message('- - ' || I || '. ' || substr(FND_MSG_PUB.GET(p_encoded => FND_API.G_FALSE), 1, 255));
          end loop;
        end if;
      end if;
    end if;
    close existing_su_cur;
    x_site_use_id := v_site_use_id;
  end create_site_use;
end xx_om_consignment_order_pkg;
/
