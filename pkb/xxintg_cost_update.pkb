DROP PACKAGE BODY APPS.XXINTG_COST_UPDATE;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_COST_UPDATE" 
AS
   -- +========================================================================+
   -- + Global Constants                                                       +
   -- +========================================================================+
   g_user_id        CONSTANT NUMBER := NVL (fnd_global.user_id, -1);
   g_request_id     CONSTANT NUMBER := NVL (fnd_global.conc_request_id, -1);
   g_resp_id        CONSTANT NUMBER := NVL (fnd_global.resp_id, -1);
   g_resp_appl_id   CONSTANT NUMBER := NVL (fnd_global.resp_appl_id, -1);
   g_batch_size     CONSTANT NUMBER := 1000;

   -- +========================================================================+
   -- + Global Debug Variables                                                 +
   -- +========================================================================+
   g_debug_point             VARCHAR2 (30);
   g_error_flag              VARCHAR2 (1);
   g_error_msg               VARCHAR2 (4000) := NULL;
   g_req                     NUMBER;
   g_org_id                  NUMBER := fnd_profile.VALUE ('ORG_ID');

   --------------------------------------------------------------------
   /************************************************************************
   Procedure Name : write
   Parameters     : None
   Purpose        : Procedure writes to the log file or output file
                    based on type.O=Output File, L=Log File
 *************************************************************************/
   PROCEDURE write (p_type IN VARCHAR2, p_message IN VARCHAR2)
   IS
   BEGIN
      IF p_type = 'L'
      THEN
         fnd_file.put_line (fnd_file.LOG, p_message);
      ELSIF p_type = 'O'
      THEN
         fnd_file.put_line (fnd_file.output, p_message);
      END IF;
   END write;


   PROCEDURE xxintg_cost_import_update (
      errbuf                   OUT VARCHAR2,
      retcode                  OUT VARCHAR2,
      p_batch_id            IN     VARCHAR2,
      p_organization_code   IN     VARCHAR2,
      p_cost_type           IN     VARCHAR2)
   IS
      v_cost_type           VARCHAR2 (50) := NULL;
      v_resource1           VARCHAR2 (50) := NULL;
      v_resource2           VARCHAR2 (50) := NULL;
      v_resource3           VARCHAR2 (50) := NULL;
      v_resource4           VARCHAR2 (50) := NULL;
      v_inventory_item_id   NUMBER;
      v_organization_id     NUMBER;
      v_cost_type_id        NUMBER;
      v_resource_id1        NUMBER;
      v_resource_code1      VARCHAR2 (100);
      v_cost_element_id1    NUMBER;
      v_basis_type1         NUMBER;
      v_resource_id2        NUMBER;
      v_resource_code2      VARCHAR2 (100);
      v_cost_element_id2    NUMBER;
      v_basis_type2         NUMBER;
      v_resource_id3        NUMBER;
      v_resource_code3      VARCHAR2 (100);
      v_cost_element_id3    NUMBER;
      v_basis_type3         NUMBER;
      v_resource_id4        NUMBER;
      v_resource_code4      VARCHAR2 (100);
      v_cost_element_id4    NUMBER;
      v_basis_type4         NUMBER;
      x_error_code          NUMBER;
      v_err_msg             VARCHAR2 (500) := NULL;
      v_err_flag            VARCHAR2 (1) := NULL;
      v_status_flag         VARCHAR2 (1) := 'N';
      v_retcode_e           VARCHAR2 (1) := NULL;
      v_retcode             VARCHAR2 (1) := NULL;
      v_count               NUMBER := 0;
      l_buy_count           NUMBER := 0;
      v_cst_count           NUMBER := 0;
      l_cst_enabled_count   NUMBER := 0;
      v_pro_count           NUMBER := 0;
      v_succ_count          NUMBER := 0;
      v_group_id            NUMBER := 1000;



      CURSOR c1
      IS
         SELECT *
           FROM xx_item_cost_update_stg
          WHERE     NVL (status_flag, 'N') = 'N'
                AND ORGANIZATION_CODE =
                       NVL (p_organization_code, organization_code)
                AND cost_type = NVL (p_cost_type, cost_type)
                AND batch_id = NVL (p_batch_id, batch_id);

      CURSOR c2
      IS
         SELECT ITEM_NUMBER, ORGANIZATION_CODE, ERROR
           FROM xx_item_cost_update_stg
          WHERE     status_flag = 'E'
                AND ERROR IS NOT NULL
                AND REQUEST_ID = g_request_id;
   BEGIN
      BEGIN
         SELECT COUNT (1)
           INTO v_count
           FROM xx_item_cost_update_stg
          WHERE status_flag IS NULL;

         IF v_count > 0
         THEN
            UPDATE xx_item_cost_update_stg
               SET status_flag = 'N'
             WHERE status_flag IS NULL;

            COMMIT;
         ELSE
            v_err_msg := (v_err_msg || 'No Records to Process.');
         END IF;
      END;

      BEGIN
         SELECT cost_type_id
           INTO v_cost_type_id
           FROM cst_cost_types
          WHERE cost_type = p_cost_type;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_status_flag := 'E';

            v_cost_type_id := NULL;
            v_err_msg := v_err_msg || ' Cost Type is Not defined.';
      END;


      FOR i IN c1
      LOOP
         v_pro_count := v_pro_count + 1;

         BEGIN
            SELECT organization_id
              INTO v_organization_id
              FROM mtl_parameters
             WHERE organization_code = i.organization_code;


            IF v_organization_id IS NOT NULL
            THEN
               v_err_msg := NULL;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_err_flag := 'E';
               v_status_flag := 'E';
               v_organization_id := NULL;
               v_err_msg := v_err_msg || ' Organization Doest Not Exists ';
         END;


         BEGIN
            SELECT inventory_item_id
              INTO v_inventory_item_id
              FROM mtl_system_items_b
             WHERE     UPPER (segment1) = UPPER (i.item_number)
                   AND organization_id = v_organization_id;



            IF v_inventory_item_id IS NOT NULL
            THEN
               v_err_msg := NULL;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_err_flag := 'E';
               v_status_flag := 'E';
               v_inventory_item_id := NULL;
               v_err_msg :=
                  v_err_msg || ' Item Doest Not Exists in the organization ';
         END;

         BEGIN
            SELECT COUNT (1)
              INTO l_buy_count
              FROM mtl_system_items_b
             WHERE     inventory_item_id = v_inventory_item_id
                   AND planning_make_buy_code = 2
                   AND organization_id = v_organization_id;


            IF l_buy_count > 0
            THEN
               v_err_msg := NULL;
            ELSE
               v_err_flag := 'E';
               v_status_flag := 'E';
               v_inventory_item_id := NULL;
               v_err_msg := v_err_msg || ' Item is not a Buy Item ';
            END IF;
         END;


         BEGIN
            SELECT COUNT (1)
              INTO l_cst_enabled_count
              FROM mtl_system_items_b
             WHERE     inventory_item_id = v_inventory_item_id
                   AND costing_enabled_flag = 'Y'
                   AND organization_id = v_organization_id;



            IF l_cst_enabled_count > 0
            THEN
               v_err_msg := NULL;
            ELSE
               v_err_flag := 'E';
               v_status_flag := 'E';
               v_inventory_item_id := NULL;
               v_err_msg := v_err_msg || ' Item is not Cost Enabled Item ';
            END IF;
         END;

         BEGIN
            SELECT resource_id,
                   resource_code,
                   cost_element_id,
                   default_basis_type
              INTO v_resource_id1,
                   v_resource_code1,
                   v_cost_element_id1,
                   v_basis_type1
              FROM bom_resources
             WHERE     resource_code = i.resource_code
                   AND ORGANIZATION_ID = v_organization_id
                   AND resource_code IN ('MTL', 'MTLOH');
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err_flag := 'E';
               v_status_flag := 'E';
               v_resource_id1 := NULL;
               v_resource_code1 := NULL;
               v_cost_element_id1 := NULL;
               v_basis_type1 := NULL;
               v_err_msg :=
                     v_err_msg
                  || ' Error in fetching the resource code,cost element ';
         END;
         
          BEGIN
            SELECT count(*) into v_cst_count
                           FROM CST_ITEM_COST_DETAILS cicd
             WHERE     cicd.inventory_item_id = v_inventory_item_id
                   AND cicd.ORGANIZATION_ID = v_organization_id
                   AND cicd.RESOURCE_ID = v_resource_id1
                   AND cicd.USAGE_RATE_OR_AMOUNT = i.USAGE_RATE_OR_AMOUNT
                   AND cicd.COST_TYPE_ID = v_cost_type_id ; 
                IF v_cst_count > 0 then 
                
                   v_err_flag := 'E';
               v_status_flag := 'E';
               v_err_msg :=
                     v_err_msg
                  || 'There are rows already present for this item,
                      organization,cost type,resource combination ';
               end if;
                  
         
         END;
        

         IF v_status_flag = 'N'                          --i.status_flag = 'N'
         THEN
            BEGIN
               INSERT
                 INTO apps.cst_item_cst_dtls_interface (last_update_date,
                                                        last_updated_by,
                                                        process_flag,
                                                        creation_date,
                                                        created_by,
                                                        transaction_type,
                                                        cost_type_id,
                                                        --organization_code,
                                                        inventory_item_id,
                                                        cost_element_id,
                                                        usage_rate_or_amount,
                                                        resource_code,
                                                        basis_type,
                                                        organization_id,
                                                        resource_id,
                                                        GROUP_ID)
               VALUES (SYSDATE,
                       -1,
                       1,
                       SYSDATE,
                       -1,
                       'UPDATE',
                       v_cost_type_id,
                       --i.organization_code,
                       v_inventory_item_id,
                       v_cost_element_id1,
                       i.USAGE_RATE_OR_AMOUNT,
                       v_resource_code1,
                       v_basis_type1,
                       v_organization_id,
                       v_resource_id1,
                       v_group_id);

               v_succ_count := v_succ_count + 1;
               v_status_flag := 'Y';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_err_flag := 'E';               --xx_emf_cn_pkg.cn_prc_err;
                  v_status_flag := 'E';
                  v_err_msg :=
                        v_err_msg
                     || ' Material Cost Update Failed - Resource Definition not available.';
               WHEN OTHERS
               THEN
                  v_status_flag := 'E';
                  v_err_flag := 'E';
                  v_err_msg :=
                        v_err_msg
                     || ' Material Cost Update Failed - '
                     || SQLERRM;
            END;
         END IF;


         BEGIN
            UPDATE xx_item_cost_update_stg
               SET error = v_err_msg,
                   status_flag = v_status_flag,
                   REQUEST_ID = g_request_id
             WHERE     item_number = i.item_number
                   AND batch_id = p_batch_id
                   AND organization_code = i.organization_code
                   AND RESOURCE_CODE = i.resource_code
                   AND USAGE_RATE_OR_AMOUNT = i.USAGE_RATE_OR_AMOUNT;

            COMMIT;
         END;

         v_status_flag := 'N';
         v_err_msg := NULL;
      END LOOP;


      COMMIT;
      WRITE (
         'L',
         ' -------------------------------------------------------------------------------');
      WRITE (
         'L',
         '                          Success and Error Report                     ');
      WRITE (
         'L',
         ' -------------------------------------------------------------------------------');
      WRITE ('L', ' ');

      WRITE ('L', 'Date: ' || SYSDATE);
      WRITE ('L', 'Concurrent Request ID: ' || g_request_id);
      WRITE (
         'L',
         'Concurrent Program Name : INTG BUY Cost Mass Upload/Update Program');
      WRITE ('L', 'Processed Records : ' || v_pro_count);
      WRITE ('L', 'Success Records : ' || v_succ_count);
      WRITE ('L', 'Failed Records : ' || (v_pro_count - v_succ_count));
      WRITE ('L', ' ');
      WRITE ('L', ' ');

      WRITE ('L',  'SUMMARY SECTION');
      WRITE ('L', '--------------------------');
      WRITE ('L', ' ');
      WRITE (
         'L',
        'ERR_ITEM                 ERROR_MSG                           REQ_ID         BATCH_ID  ');
WRITE('L', '                                                                                   ');
      FOR j IN c2
      LOOP
         WRITE (
            'L',
               j.ITEM_NUMBER
            || '  '
            || j.ERROR
            || '  '
            || g_request_id
            || '   '
            || p_batch_id);
      END LOOP;
   END xxintg_cost_import_update;
END xxintg_cost_update;
/
