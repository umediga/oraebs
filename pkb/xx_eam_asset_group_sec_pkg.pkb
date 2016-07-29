DROP PACKAGE BODY APPS.XX_EAM_ASSET_GROUP_SEC_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_EAM_ASSET_GROUP_SEC_PKG" 
is
   procedure add_policy
   is
      p_policy_owner   fnd_oracle_userid.oracle_username%type;
      l_status         varchar2(1);
      l_industry       varchar2(1);
      l_prod_schema    varchar2(30);
      cursor c1
      is
         select 1
           from all_policies
          where object_owner = p_policy_owner and object_name = 'MTL_SYSTEM_ITEMS_B' and policy_name = 'INTG_VPD_POLICY';
      cursor prod_policy
      is
         select 1
           from all_policies
          where object_owner = l_prod_schema and object_name = 'MTL_SYSTEM_ITEMS_B' and policy_name = 'INTG_VPD_POLICY';
   begin
      select oracle_username
        into p_policy_owner
        from fnd_oracle_userid
       where read_only_flag = 'U';
      for crec in c1
      loop
         return;
      end loop;
      if not fnd_installation.get_app_info('CSI', l_status, l_industry, l_prod_schema)
      then
         raise fnd_api.g_exc_unexpected_error;
      end if;
      for pprec in prod_policy
      loop
         return;
      end loop;
      dbms_rls.add_policy(object_schema     => 'APPS',
                          object_name       => 'MTL_SYSTEM_ITEMS_B',
                          policy_name       => 'INTG_VPD_POLICY',
                          policy_function   => 'xx_eam_asset_group_sec_pkg.vpd_eam_items',
                          statement_types   => 'SELECT');
   exception
      when others
      then
         null;
   end add_policy;
   procedure drop_policy
   is
   begin
      dbms_rls.drop_policy(object_schema => 'APPS', object_name => 'MTL_SYSTEM_ITEMS_B', policy_name => 'INTG_VPD_POLICY');
   end;
   function vpd_eam_items(obj_schema varchar2, obj_name varchar2)
      return varchar2
   is
      l_where_clause    varchar2(2000);
      l_enable_policy   varchar2(5);
      l_org_id          varchar2(15);
      l_user_id         varchar2(15) := null;
      l_resp_id         number;
      l_count           number;
      l_resp_count      number;
      l_resp_key        varchar2(100);
   begin
      fnd_profile.get('INTG_ENABLE_VPD_POLICY', l_enable_policy);
      fnd_profile.get('ORG_ID', l_org_id);
      fnd_profile.get('USER_ID', l_user_id);
      l_resp_id := nvl(fnd_global.resp_id, fnd_profile.value('RESP_ID'));
      begin
         select count(*)
           into l_count
           from fnd_responsibility
          where responsibility_key in ('INTG_Y_EAM_MAIN_SU_RP', 'INTG_101_CALIB_SUPER');
      exception
         when others
         then
            l_count := 0;
      end;
      if l_count = 0
      then
         return null;
      else
         begin
            select count(*)
              into l_resp_count
              from fnd_responsibility
             where responsibility_id = l_resp_id and responsibility_key in ('INTG_Y_EAM_MAIN_SU_RP', 'INTG_101_CALIB_SUPER');
         exception
            when others
            then
               l_resp_count := 0;
               return null;
         end;
      end if;
      if (l_user_id is not null and nvl(l_enable_policy, 'N') = 'Y' and l_resp_count > 0)
      then
         if dbms_mview.i_am_a_refresh
         then
            return null;
         end if;
         begin
            select responsibility_key
              into l_resp_key
              from fnd_responsibility
             where responsibility_id = l_resp_id;
         exception
            when others
            then
               return null;
         end;
         if l_resp_key = 'INTG_Y_EAM_MAIN_SU_RP'
         then
            l_where_clause := ' segment1 like case when eam_item_type=''1'' then ''10% MAINTENANCE''
                                when eam_item_type=''2'' then ''YKMA%''
                                when eam_item_type is null then segment1
                                else segment1 end';
         elsif l_resp_key = 'INTG_101_CALIB_SUPER'
         then
            l_where_clause := ' segment1 like case when eam_item_type=''1'' then ''101 CALIBRATION''
                                when eam_item_type=''2'' then ''YKCA%''
                                when eam_item_type is null then segment1
                                else segment1 end';
         else
            l_where_clause := '';
         end if;
      end if;
      dbms_output.put_line(l_where_clause);
      return (l_where_clause);
   end vpd_eam_items;
    function vpd_wo_policy(obj_schema varchar2, obj_name varchar2)
      return varchar2
   is
      l_where_clause    varchar2(2000);
      l_enable_policy   varchar2(5);
      l_org_id          varchar2(15);
      l_user_id         varchar2(15) := null;
      l_resp_id         number;
      l_count           number;
      l_resp_count      number;
      l_resp_key        varchar2(100);
   begin

      fnd_profile.get('INTG_ENABLE_VPD_POLICY', l_enable_policy);
      fnd_profile.get('ORG_ID', l_org_id);
      fnd_profile.get('USER_ID', l_user_id);
      l_resp_id := nvl(fnd_global.resp_id, fnd_profile.value('RESP_ID'));
      begin

         select count(*)
           into l_count
           from fnd_responsibility
          where responsibility_key in ('INTG_Y_EAM_MAIN_SU_RP', 'INTG_101_CALIB_SUPER');

      exception
         when others
         then
            l_count := 0;
      end;
      if l_count = 0
      then
         return null;
      else
         begin

            select count(*)
              into l_resp_count
              from fnd_responsibility
             where responsibility_id = l_resp_id and responsibility_key in ('INTG_Y_EAM_MAIN_SU_RP', 'INTG_101_CALIB_SUPER');

         exception
            when others
            then
               l_resp_count := 0;
               return null;
         end;
      end if;

      if (l_user_id is not null and nvl(l_enable_policy, 'N') = 'Y' and l_resp_count > 0)
      then
         if dbms_mview.i_am_a_refresh
         then
            return null;
         end if;
         begin

            select responsibility_key
              into l_resp_key
              from fnd_responsibility
             where responsibility_id = l_resp_id;

         exception
            when others
            then
               return null;
         end;
         if l_resp_key = 'INTG_Y_EAM_MAIN_SU_RP'
         then
            l_where_clause := ' asset_group_id in (select inventory_item_id
                             from mtl_system_items_b
                             where eam_item_type=''1''
                             and segment1 in (''101 MAINTENANCE'',''103 MAINTENANCE''))
                             and ( primary_item_id in (select distinct inventory_Item_id from mtl_system_items_b
                             where eam_item_type=2 and segment1 like ''YKMA%'') or primary_item_id is null)';
         elsif l_resp_key = 'INTG_101_CALIB_SUPER'
         then
            l_where_clause := ' asset_group_id in (select inventory_item_id
                             from mtl_system_items_b
                             where eam_item_type=''1''
                             and segment1=''101 CALIBRATION'')
                             and ( primary_item_id in (select distinct inventory_Item_id from mtl_system_items_b
                             where eam_item_type=2 and segment1 like ''YKCA%'') or primary_item_id is null)';
         else
            l_where_clause := '';
         end if;
      end if;
      dbms_output.put_line(l_where_clause);
      return (l_where_clause);
   end vpd_wo_policy;
end xx_eam_asset_group_sec_pkg;
/
