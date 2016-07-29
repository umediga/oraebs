DROP PACKAGE BODY APPS.XX_P2M_MATREQREP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_P2M_MATREQREP_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 24-May-2013
 File Name     : xx_p2m_matreqrep_pkg.pkb
 Description   : This script creates the package body of
                 xx_p2m_matreqrep_pkg, which will create a Material Requirements Report
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 25-May-2013 Rajesh Kendhuli       Initial Version
 23-Sep-2013 Omkar A Deshpande     All Bug Fixes

*/
----------------------------------------------------------------------
   PROCEDURE bom_explode (p_item IN VARCHAR2, p_org IN VARCHAR2)
   AS
--v_item                  VARCHAR2(240)   := '#3-F/S-S/S'; -- item to explode
--v_org                   VARCHAR2(3)     := '101'; -- org in which item is exploded
      v_item                VARCHAR2 (240);
      v_org                 VARCHAR2 (3);
      v_cnt                 NUMBER         := 0;
      v_err_msg             VARCHAR2 (240); -- error message returned in this
      v_err_code            NUMBER         := 0;
                                               -- error code returned in this
      v_verify_flag         NUMBER         := 0;             -- DEFAULTS TO 0
      v_online_flag         NUMBER         := 2;             -- DEFAULTS TO 0
      v_item_id             NUMBER         := 0;
                               -- set to inventory_item_id of item to explode
      v_org_id              NUMBER         := 0;
                                 -- set to organization_id of item to explode
      v_alternate           VARCHAR2 (240) := NULL;       -- DEFAULTS TO NULL
      v_list_id             NUMBER         := 0;   -- for reports (default 0)
      v_order_by            NUMBER         := 1;             -- DEFAULTS TO 1
      v_grp_id              NUMBER         := 0;
                                   -- Unique identifier for this exploder run
      v_session_id          NUMBER         := 0;             -- DEFAULTS TO 0
      v_req_id              NUMBER         := 0;             -- DEFAULTS TO 0
      v_prgm_appl_id        NUMBER         := -1;           -- DEFAULTS TO -1
      v_prgm_id             NUMBER         := -1;           -- DEFAULTS TO -1
      v_levels_to_explode   NUMBER         := 10;            -- DEFAULTS TO 1
      v_bom_or_eng          NUMBER         := 1;             -- DEFAULTS TO 1
      v_impl_flag           NUMBER         := 1;             -- DEFAULTS TO 1
      v_plan_factor_flag    NUMBER         := 2;             -- DEFAULTS TO 2
      v_incl_lt_flag        NUMBER         := 2;             -- DEFAULTS TO 2
      v_explode_option      NUMBER         := 2;             -- DEFAULTS TO 2
      v_module              NUMBER         := 2;             -- DEFAULTS TO 2
      v_cst_type_id         NUMBER         := 0;             -- DEFAULTS TO 0
      v_std_comp_flag       NUMBER         := 0;             -- DEFAULTS TO 0
      v_rev_date            VARCHAR2 (240);                  -- revision date
      v_comp_code           VARCHAR2 (240) := NULL;
      v_expl_qty            NUMBER         := 1;                 -- DEFAULT 1
      v_unit_number         VARCHAR2 (240) := NULL;
      v_release_option      NUMBER         := 0;                 -- DEFAULT 0
   BEGIN
    -- DELETE FROM XXINTG.XX_BOM_EXPLOSION_TEMP1;

    --  FND_FILE.PUT_LINE(FND_FILE.log,
    --                 'Deleted data from the temp table XXINTG.XX_BOM_EXPLOSION_TEMP1 :'
    --                );
   -- COMMIT;
      -- item revision is based on this explode date.
      -- In this example, we use current date/time
      v_rev_date := TO_CHAR (SYSDATE);

      BEGIN
         -- Find org_id
         SELECT organization_id
           INTO v_org_id
           FROM mtl_parameters
          WHERE organization_code = p_org;
      EXCEPTION
         WHEN OTHERS
         THEN
             FND_FILE.PUT_LINE(FND_FILE.log,
                                  'Error while deriving ORG_ID ! '
                                 );
      END;

      BEGIN
         -- Find item_id
         SELECT inventory_item_id
           INTO v_item_id
           FROM mtl_system_items_b
          WHERE organization_id = v_org_id AND segment1 = p_item;
      EXCEPTION
         WHEN OTHERS
         THEN
             FND_FILE.PUT_LINE(FND_FILE.log,
                                  'Error while deriving ITEM_ID ! '
                                 );
      END;

      BEGIN
         -- v_grp_id is a unique identifier for this run of the exploder
         SELECT bom_explosion_temp_s.NEXTVAL
           INTO v_grp_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
             FND_FILE.PUT_LINE(FND_FILE.log,
                                  'Error while deriving UNIQUE IDENTIFIER ! '
                                 );
      END;

      /*
      BEGIN
          -- determine maximum levels to explode from bom_explosions
          SELECT nvl(maximum_bom_level,1) INTO v_levels_to_explode
          FROM bom_parameters WHERE organization_id = v_org_id;
      EXCEPTION
          WHEN OTHERS
          THEN
              FND_FILE.PUT_LINE(FND_FILE.log,'Error while deriving MAXIMUM BOM LEVELS ! ' );
      END;
      */
      BEGIN
         apps.bompexpl.exploder_userexit (v_verify_flag,
                                          v_org_id,
                                          v_order_by,
                                          v_grp_id,
                                          v_session_id,
                                          v_levels_to_explode,
                                          v_bom_or_eng,
                                          v_impl_flag,
                                          v_plan_factor_flag,
                                          v_explode_option,
                                          v_module,
                                          v_cst_type_id,
                                          v_std_comp_flag,
                                          v_expl_qty,
                                          v_item_id,
                                          v_alternate,
                                          v_comp_code,
                                          v_rev_date,
                                          v_unit_number,
                                          v_release_option,
                                          v_err_msg,
                                          v_err_code
                                         );

         IF (v_err_code != 0)
         THEN
            --dbms_output.put_line('ERROR: ' || v_err_msg);
             FND_FILE.PUT_LINE(FND_FILE.log,
                                  'ERROR :' || v_err_msg
                                 );
                                 
         ELSE
            SELECT COUNT (*)
              INTO v_cnt
              FROM bom_explosion_temp
             WHERE GROUP_ID = v_grp_id;

            INSERT INTO XXINTG.XX_BOM_EXPLOSION_TEMP1
               SELECT *
                 FROM BOM_EXPLOSION_TEMP;

            --dbms_output.put_line('Row Count=' || v_cnt);
            --dbms_output.put_line('Group Id =' || v_grp_id);
            --dbms_output.put_line('Org Code =' || v_org);
            --dbms_output.put_line('Item =' || v_item);
            --dbms_output.put_line('Ord Id =' || v_org_id);
            --dbms_output.put_line('Item Id =' || v_item_id);
            --dbms_output.put_line('Levels =' || v_levels_to_explode);
             FND_FILE.PUT_LINE(FND_FILE.log, 'Row Count=' || v_cnt);
             FND_FILE.PUT_LINE(FND_FILE.log,
                                  'Group Id =' || v_grp_id
                                 );
             FND_FILE.PUT_LINE(FND_FILE.log, 'Org Code =' || v_org);
             FND_FILE.PUT_LINE(FND_FILE.log, 'Item =' || v_item);
             FND_FILE.PUT_LINE(FND_FILE.log,
                                  'Ord Id =' || v_org_id);
             FND_FILE.PUT_LINE(FND_FILE.log,
                                  'Item Id =' || v_item_id
                                 );
             FND_FILE.PUT_LINE(FND_FILE.log,
                                  'Levels =' || v_levels_to_explode
                                 );
         END IF;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
             FND_FILE.PUT_LINE(FND_FILE.log,
                                  'Error during bom explosion ! '
                                 );
      END;
   END BOM_EXPLODE;
   
   
   
   PROCEDURE BOM_ITEMS_REM (P_ITEM1 IN VARCHAR2, P_ORG1 IN VARCHAR2)  --added by Omkar
   AS
   
   V_ORG_ID   NUMBER         := 0;
   V_ITEM_ID             NUMBER         := 0;
  
   BEGIN
   
   BEGIN
         -- Find org_id
         SELECT organization_id
           INTO v_org_id
           FROM MTL_PARAMETERS
          WHERE organization_code = p_org1;
      EXCEPTION
         WHEN OTHERS
         THEN
             FND_FILE.PUT_LINE(FND_FILE.log,
                                  'Error while deriving ORG_ID ! '
                                 );
    END;
    
     BEGIN
         -- Find item_id
         SELECT inventory_item_id
           INTO v_item_id
           FROM MTL_SYSTEM_ITEMS_B
          WHERE organization_id = v_org_id AND segment1 = p_item1;
      EXCEPTION
         WHEN OTHERS
         THEN
             FND_FILE.PUT_LINE(FND_FILE.log,
                                  'Error while deriving ITEM_ID ! '
                                 );
      END;
      
      
      BEGIN 
      
      INSERT INTO XXINTG.XX_BOM_EXPLOSION_TEMP1
                  (TOP_BILL_SEQUENCE_ID,BILL_SEQUENCE_ID,ORGANIZATION_ID,COMPONENT_ITEM_ID,PLAN_LEVEL,
                  SORT_ORDER,REQUEST_ID,PROGRAM_UPDATE_DATE,TOP_ITEM_ID,COMPONENT_CODE)
             VALUES(99999999,99999999,v_org_id,v_item_id,0,0000001,0,SYSDATE,v_item_id,v_item_id); --Inserting Some Dummy Data
      
      COMMIT;
      
       EXCEPTION
         WHEN OTHERS
         THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,
                                  'Error during entering data! '
                                 );
      END;

   END BOM_ITEMS_REM;
   
   
   
   PROCEDURE main_prc (
      p_org          IN       VARCHAR2,
      P_FORECAST_NAME IN       VARCHAR2,
      p_shipto_org    IN      VARCHAR2,
      x_error_code   OUT      NUMBER,
      x_error_msg    OUT      VARCHAR2
   )
   IS
      x_err_code            NUMBER;
      x_err_msg             VARCHAR2 (50);
      v_org_id              NUMBER;
      v_org_code            VARCHAR2 (10);
      v_bom_flag            VARCHAR2 (5);
      v_org_name            VARCHAR2 (500);
      l_plan_level          NUMBER;
      l_part_number         mtl_system_items_b.segment1%TYPE;
      l_item_desc           mtl_system_items_b.description%TYPE;
      l_quantity            NUMBER;
      l_type                VARCHAR2 (50);
      l_planner_code        VARCHAR2 (10);
      L_AVAIL_TO_TRANSACT   NUMBER;
      L_FORECAST            NUMBER;
      L_OPEN_SALES_ORDERS   NUMBER;
      L_RESV_ORD_QTY        NUMBER;
      L_INTR_ORD_QTY        NUMBER;
      L_OPEN_WO_DEMAND      NUMBER;
      L_WO_SUP_QTY          NUMBER;
      L_WO_DMD_QTY          NUMBER;
      l_intransit           NUMBER;
      l_open_wo_atc         NUMBER;
      l_open_po_cumulative  NUMBER;
      l_open_req_cumulative NUMBER;
      l_work_order          VARCHAR2 (50);
      L_OPEN_QUANTITY       NUMBER;
      L_OPEN_QUANTITY_WO    NUMBER;
      L_OPEN_QUANTITY_REQ   NUMBER;
      l_open_qty_sign       NUMBER;
      l_order_type          VARCHAR2 (50);
      l_due_date            DATE;
      l_supplier_name       VARCHAR2 (250);
      l_short_hzn           NUMBER;
      l_long_hzn            NUMBER;
      l_wip_count           NUMBER;
      l_po_count            NUMBER;
      L_REQ_COUNT	    NUMBER;
      L_REQ_COUNT_DUP NUMBER;
      l_req_count_check     NUMBER;
      l_sort_order          NUMBER;
      l_top_bill_seq_id     NUMBER;
      l_bill_seq_id         NUMBER;
      l_comp_seq_id         NUMBER;
      l_comp_item_id        NUMBER;
      l_top_item_id         NUMBER;
      L_ASSEMBLY_ITEM_ID    number;
      L_RECEIPTS_QTY        number;
      L_CNT                 NUMBER := 0;
      L_USER_ID            NUMBER := FND_GLOBAL.USER_ID;
      L_RESP               NUMBER;
      L_RESP_APPL          NUMBER;
      L_ORG_ID             NUMBER := FND_GLOBAL.ORG_ID;
      V_CLIENT_INFO        VARCHAR2 (250);
      l_app_shrt           VARCHAR2 (50);
      

      CURSOR c_mrp_items (p_org_id NUMBER, p_forecast_name VARCHAR2)
      IS
        /* SELECT DISTINCT msi.inventory_item_id, msi.segment1,
                         msi.bom_enabled_flag
                    FROM mtl_system_items_b msi, mrp_forecast_dates mfd
                   WHERE mfd.inventory_item_id = msi.inventory_item_id
                     AND mfd.organization_id = msi.organization_id
                     --AND mfd.forecast_date = (TRUNC (LAST_DAY (ADD_MONTHS (SYSDATE, -1)) + 1))
                     AND MSI.ORGANIZATION_ID = P_ORG_ID
                   --  AND msi.segment1 = 'MA-PTS' -- in ('012-14061','012-14067','012-28004')-- '510008'--'ZIM-001'--'DEF6-SG';--'012330';--'DEF6-SG';
                     --AND msi.segment1 = NVL (p_item, msi.segment1)
                     AND mfd.forecast_designator = NVL(p_forecast_name,mfd.forecast_designator)
                     ORDER BY msi.segment1;*/
                     
        SELECT DISTINCT msi.inventory_item_id, msi.segment1,
                         MSI.BOM_ENABLED_FLAG
                    FROM mtl_system_items_b msi, mrp_forecast_dates mfd, BOM_BILL_OF_MATERIALS bom
                   WHERE mfd.inventory_item_id = msi.inventory_item_id
                     AND MFD.ORGANIZATION_ID = MSI.ORGANIZATION_ID
                     AND BOM.ASSEMBLY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                     AND BOM.ORGANIZATION_ID = MSI.ORGANIZATION_ID
                     --AND mfd.forecast_date = (TRUNC (LAST_DAY (ADD_MONTHS (SYSDATE, -1)) + 1))
                     AND MSI.ORGANIZATION_ID = P_ORG_ID
                   --  AND msi.segment1 = 'MA-PTS' -- in ('012-14061','012-14067','012-28004')-- '510008'--'ZIM-001'--'DEF6-SG';--'012330';--'DEF6-SG';
                     --AND msi.segment1 = NVL (p_item, msi.segment1)
                     AND MFD.FORECAST_DESIGNATOR = NVL(p_forecast_name,MFD.FORECAST_DESIGNATOR)
                     ORDER BY msi.segment1;

 CURSOR C_MRP_ITEMS_REM (P_ORG_ID NUMBER, P_FORECAST_NAME VARCHAR2)
      IS
      
      SELECT DISTINCT msi.inventory_item_id, msi.segment1,
                         msi.bom_enabled_flag
                    FROM mtl_system_items_b msi, mrp_forecast_dates mfd
                   WHERE mfd.inventory_item_id = msi.inventory_item_id
                     AND mfd.organization_id = msi.organization_id
                     --AND mfd.forecast_date = (TRUNC (LAST_DAY (ADD_MONTHS (SYSDATE, -1)) + 1))
                     AND MSI.ORGANIZATION_ID = P_ORG_ID
                   --  AND msi.segment1 = 'MA-PTS' -- in ('012-14061','012-14067','012-28004')-- '510008'--'ZIM-001'--'DEF6-SG';--'012330';--'DEF6-SG';
                     --AND msi.segment1 = NVL (p_item, msi.segment1)
                     AND MFD.FORECAST_DESIGNATOR = NVL(p_forecast_name,MFD.FORECAST_DESIGNATOR)
                     MINUS
          SELECT DISTINCT msi.inventory_item_id, msi.segment1,
                         MSI.BOM_ENABLED_FLAG
                    FROM mtl_system_items_b msi, mrp_forecast_dates mfd, BOM_BILL_OF_MATERIALS bom
                   WHERE mfd.inventory_item_id = msi.inventory_item_id
                     AND MFD.ORGANIZATION_ID = MSI.ORGANIZATION_ID
                     AND BOM.ASSEMBLY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                     AND BOM.ORGANIZATION_ID = MSI.ORGANIZATION_ID
                     --AND mfd.forecast_date = (TRUNC (LAST_DAY (ADD_MONTHS (SYSDATE, -1)) + 1))
                     AND MSI.ORGANIZATION_ID = P_ORG_ID
                   --  AND msi.segment1 = 'MA-PTS' -- in ('012-14061','012-14067','012-28004')-- '510008'--'ZIM-001'--'DEF6-SG';--'012330';--'DEF6-SG';
                     --AND msi.segment1 = NVL (p_item, msi.segment1)
                     AND MFD.FORECAST_DESIGNATOR = NVL(p_forecast_name,MFD.FORECAST_DESIGNATOR)
                     order by segment1;


      CURSOR c_bom_temp
      IS
         SELECT   *
             FROM XXINTG.XX_BOM_EXPLOSION_TEMP1
         ORDER BY sort_order;

      CURSOR c_wip (p_item_id NUMBER)
      IS
         SELECT wip_entity_name,
                (start_quantity - NVL (quantity_completed, 0)) open_qty,
                scheduled_completion_date
           FROM wip_discrete_jobs_v
          WHERE primary_item_id = p_item_id
            AND upper(status_type_disp) = 'RELEASED';

      CURSOR C_PO (P_ITEM_ID NUMBER, p_shipto_org VARCHAR2)
      IS
         SELECT DISTINCT POH.SEGMENT1,POH.VENDOR_ID,PLL.QUANTITY,PLL.NEED_BY_DATE,POL.ITEM_ID,(PLL.QUANTITY - NVL (PLL.QUANTITY_RECEIVED, 0)) QUANTITY_DUE --added by Omkar
           FROM po_headers_all poh, po_lines_all pol, po_line_locations_all pll,po_distributions_all pod
          WHERE poh.po_header_id = pol.po_header_id
   	    AND pol.po_line_id = pll.po_line_id
   	    AND pll.line_location_id = pod.line_location_id
	   -- AND (upper(poh.closed_code) = 'OPEN' OR poh.closed_code IS NULL)
      AND Pll.SHIP_TO_ORGANIZATION_ID = nvl(p_shipto_org, Pll.SHIP_TO_ORGANIZATION_ID)
	    AND poh.closed_date IS NULL
	    AND poh.type_lookup_code not in ('QUOTATION')
	    AND pol.item_id = p_item_id;


      CURSOR c_req (p_item_id NUMBER)
      IS
        /* SELECT distinct porh.segment1,porl.need_by_date,porl.quantity,porl.item_id,porl.vendor_id
           FROM po_requisition_headers_all porh,
     	        po_requisition_lines_all porl,
                po_req_distributions_all prd
          where porh.requisition_header_id = porl.requisition_header_id
            and porl.requisition_line_id = prd.requisition_line_id
            AND (upper(porl.closed_code) = 'OPEN' OR porl.closed_code IS NULL)
            and porl.item_id = p_item_id;*/
            
  SELECT   --added by Omkar
  Distinct PRH.SEGMENT1,PRL.NEED_BY_DATE,PRL.QUANTITY,PRL.ITEM_ID,PRL.VENDOR_ID
  FROM 
  PO_REQUISITION_HEADERS_ALL PRH, 
  PO_REQUISITION_LINES_all PRL, 
  APPS.PER_PEOPLE_F PPF1, 
  (SELECT DISTINCT AGENT_ID,AGENT_NAME FROM APPS.PO_AGENTS_V ) PPF2, 
  PO_REQ_DISTRIBUTIONS_all PRD, 
  INV.MTL_SYSTEM_ITEMS_B MSI, 
  PO_LINE_LOCATIONS_ALL PLL, 
  PO_LINES_ALL PL, 
  PO_HEADERS_all PH
  WHERE 
  PRH.REQUISITION_HEADER_ID = PRL.REQUISITION_HEADER_ID 
  AND PRL.REQUISITION_LINE_ID = PRD.REQUISITION_LINE_ID 
  AND PPF1.PERSON_ID = PRH.PREPARER_ID 
  AND PRH.CREATION_DATE BETWEEN PPF1.EFFECTIVE_START_DATE AND PPF1.EFFECTIVE_END_DATE 
  AND PPF2.AGENT_ID(+) = MSI.BUYER_ID 
  AND MSI.INVENTORY_ITEM_ID = PRL.ITEM_ID 
  AND MSI.ORGANIZATION_ID = PRL.DESTINATION_ORGANIZATION_ID 
  AND PLL.LINE_LOCATION_ID(+) = PRL.LINE_LOCATION_ID 
  AND PLL.PO_HEADER_ID = PH.PO_HEADER_ID(+) 
  AND PLL.PO_LINE_ID = PL.PO_LINE_ID(+) 
  AND PRH.AUTHORIZATION_STATUS IN ('APPROVED','IN PROCESS', 'INCOMPLETE', 'PRE–APPROVED')
  AND PLL.LINE_LOCATION_ID IS NULL 
  AND PRL.CLOSED_CODE IS NULL 
  AND NVL(PRL.CANCEL_FLAG,'N') <> 'Y'
  AND PRH.TYPE_LOOKUP_CODE <> 'INTERNAL'  -- added later to eliminate Internal Requisitions
  AND PRL.DESTINATION_ORGANIZATION_ID = NVL(  p_shipto_org, PRL.DESTINATION_ORGANIZATION_ID)
  and PRL.ITEM_ID = p_item_id;

            


   BEGIN
   
    --Initialize the profile values so that we can run the submit request package added by Omkar
   
  /* SELECT FR.APPLICATION_ID, FR.RESPONSIBILITY_ID,FA.APPLICATION_SHORT_NAME
   INTO   l_resp_appl, l_resp, l_app_shrt
   FROM   FND_RESPONSIBILITY FR, FND_APPLICATION FA
   WHERE  FR.APPLICATION_ID = FA.APPLICATION_ID
   AND UPPER(responsibility_key) = 'SUPPLY_CHAIN_PLANNER';

   APPS.FND_GLOBAL.APPS_INITIALIZE(L_USER_ID, L_RESP, L_RESP_APPL);
   APPS.MO_GLOBAL.INIT('INV');
   --APPS.MO_GLOBAL.SET_ORG_CONTEXT(L_ORG_ID, NULL, 'INV');
   APPS.MO_GLOBAL.SET_POLICY_CONTEXT('S',L_ORG_ID);*/
   
   /* SELECT client_info into v_client_info FROM v$session WHERE audsid = USERENV('SESSIONID');
    
    DBMS_APPLICATION_INFO.SET_CLIENT_INFO(v_client_info);*/

   
      x_err_code := xx_emf_pkg.set_env;
       FND_FILE.PUT_LINE(FND_FILE.log,
                            'Set EMF Env x_error_code: ' || x_error_code
                           );

      DELETE FROM XXINTG.XX_BOM_REPORT_66;
      DELETE FROM XXINTG.XX_BOM_EXPLOSION_TEMP1;

      COMMIT;
       -- Find org_id
      -- SELECT organization_id INTO v_org_id
      -- FROM MTL_PARAMETERS
      -- WHERE organization_code = p_org;
      v_org_id := p_org;

      SELECT organization_code, organization_name
        INTO v_org_code, v_org_name
        FROM org_organization_definitions
       WHERE organization_id = p_org;

      DBMS_OUTPUT.put_line ('v_org_id ' || v_org_id);

      FOR c_mrp_items_rec IN c_mrp_items (v_org_id, p_forecast_name)
      LOOP
         DBMS_OUTPUT.put_line ('Inside c_mrp_items ');

--    dbms_output.put_line ('count ' ||c_mrp_items%ROWCOUNT);
--    dbms_output.put_line ('segment1 ' ||c_mrp_items_rec.segment1);
--    dbms_output.put_line ('item id ' ||c_mrp_items_rec.inventory_item_id);
         IF c_mrp_items_rec.bom_enabled_flag = 'Y'
         THEN
             FND_FILE.PUT_LINE(FND_FILE.log,
                                  'Calling Procedure bom_explode: '
                                 );
            bom_explode (c_mrp_items_rec.segment1, v_org_code);
         END IF;
      END LOOP;
      
      FOR c_mrp_items_rem_rec IN c_mrp_items_rem (v_org_id, p_forecast_name)  --added by Omkar
      LOOP
         DBMS_OUTPUT.put_line ('Inside c_mrp_items_rem ');

--    dbms_output.put_line ('count ' ||c_mrp_items%ROWCOUNT);
--    dbms_output.put_line ('segment1 ' ||c_mrp_items_rec.segment1);
--    dbms_output.put_line ('item id ' ||c_mrp_items_rec.inventory_item_id);
         IF c_mrp_items_rem_rec.bom_enabled_flag = 'Y'
         THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,
                                  'Calling Procedure bom_items_rem: '
                                 );
            bom_items_rem (c_mrp_items_rem_rec.segment1, v_org_code);
         END IF;
      END LOOP;
      
      

      FOR c_bom_temp_rec IN c_bom_temp
      LOOP
         DBMS_OUTPUT.put_line ('Inside c_bom_temp ');
         l_plan_level := c_bom_temp_rec.plan_level;
         l_sort_order := c_bom_temp_rec.sort_order;
         l_top_bill_seq_id := c_bom_temp_rec.top_bill_sequence_id;
         l_bill_seq_id := c_bom_temp_rec.bill_sequence_id;
         l_comp_seq_id := c_bom_temp_rec.component_sequence_id;
         l_comp_item_id := c_bom_temp_rec.component_item_id;
         l_top_item_id := c_bom_temp_rec.top_item_id;
         l_assembly_item_id := c_bom_temp_rec.assembly_item_id;

         BEGIN
            SELECT segment1, description
              INTO l_part_number, l_item_desc
              FROM mtl_system_items_b
             WHERE inventory_item_id = c_bom_temp_rec.component_item_id
               AND organization_id = c_bom_temp_rec.organization_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log
                   (xx_emf_cn_pkg.cn_low,
                    'Error while deriving PART NUMBER AND ITEM DESCRIPTION! '
                   );
         END;

         l_quantity := NVL (c_bom_temp_rec.component_quantity, 0);

         BEGIN
            SELECT flv.meaning
              INTO l_type
              FROM mtl_system_items_b msi, fnd_lookup_values flv
             WHERE TO_CHAR (msi.planning_make_buy_code) = flv.lookup_code
               AND flv.lookup_type = 'MTL_PLANNING_MAKE_BUY'
               AND msi.inventory_item_id = c_bom_temp_rec.component_item_id
               AND msi.organization_id = c_bom_temp_rec.organization_id
               AND flv.LANGUAGE = 'US';
         EXCEPTION
            WHEN OTHERS
            THEN
                FND_FILE.PUT_LINE(FND_FILE.log,
                                     'Error while deriving TYPE! '
                                    );
         END;

         BEGIN
            SELECT planner_code
              INTO l_planner_code
              FROM mtl_system_items_b
             WHERE inventory_item_id = c_bom_temp_rec.component_item_id
               AND organization_id = c_bom_temp_rec.organization_id;
         EXCEPTION
            WHEN OTHERS
            THEN
                FND_FILE.PUT_LINE(FND_FILE.log,
                                     'Error while deriving PLANNER CODE! '
                                    );
         END;

         BEGIN
            SELECT NVL ((  (SELECT SUM (transaction_quantity)
                              FROM mtl_onhand_quantities
                             WHERE inventory_item_id = c_bom_temp_rec.component_item_id
                               AND organization_id = c_bom_temp_rec.organization_id)
                         - (SELECT NVL (SUM (RESERVATION_QUANTITY), 0)
                              from MTL_RESERVATIONS
                             WHERE inventory_item_id = c_bom_temp_rec.component_item_id)
                        ),
                        0
                       )
              INTO l_avail_to_transact
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log
                              (xx_emf_cn_pkg.cn_low,
                               'Error while deriving AVAILABLE TO TRANSACT! '
                              );
         END;


        IF L_PLAN_LEVEL = 0   -- added By Omkar
        THEN
         BEGIN
            SELECT NVL (original_forecast_quantity, 0)
              INTO l_forecast
              from MRP_FORECAST_DATES
             WHERE inventory_item_id = c_bom_temp_rec.component_item_id
               and ORGANIZATION_ID = C_BOM_TEMP_REC.ORGANIZATION_ID;
               --AND forecast_date = (TRUNC (LAST_DAY (ADD_MONTHS (SYSDATE, -1)) + 1));
         EXCEPTION
            WHEN OTHERS
            THEN
                FND_FILE.PUT_LINE(FND_FILE.log,
                                     'Error while deriving FORECAST! '
                                    );
         END;
        
        ELSE 
        
        L_FORECAST := 0;
       END IF;

  --       BEGIN
  --          SELECT NVL (((SELECT SUM (ordered_quantity)
  --                          FROM oe_order_lines_all
  --                         WHERE inventory_item_id =
  --                                            c_bom_temp_rec.component_item_id
  --                           AND open_flag = 'Y')
  --                       MINUS
  --                       (SELECT SUM (shipped_quantity)
  --                          FROM oe_order_lines_all
  --                         WHERE inventory_item_id =
  --                                            c_bom_temp_rec.component_item_id
  --                           AND open_flag = 'Y')),
  --                      0
  --                     )
  --            INTO l_open_sales_orders
  --            FROM DUAL;
  --       EXCEPTION
  --          WHEN OTHERS
  --          THEN
  --             xx_emf_pkg.write_log
  --                                (xx_emf_cn_pkg.cn_low,
  --                                 'Error while deriving OPEN SALES ORDERS! '
  --                                );
  --       END;

  /*
  	-- not working for mtl_supply_demand_temp table as it will not have data once the front end item supply/demand form is closed
  	 BEGIN
  	 	SELECT abs(sum(quantity))
  	 	  INTO l_open_sales_orders
  	 	  FROM mtl_supply_demand_temp
		 WHERE inventory_item_id = c_bom_temp_rec.component_item_id
		   AND supply_demand_source_type = (SELECT lookup_code
		                                      FROM mfg_lookups
		                                     WHERE lookup_type like 'MTL_SUPPLY_DEMAND_SOURCE_TYPE'
						       AND upper(meaning) = 'SALES ORDER');
         EXCEPTION
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log
                                  (xx_emf_cn_pkg.cn_low,
                                   'Error while deriving OPEN SALES ORDERS! '
                                  );
         END;

  */

 --   	 BEGIN

  		/*SELECT NVL(((SELECT SUM (ordered_quantity)
                           FROM oe_order_lines_all
                          WHERE inventory_item_id = c_bom_temp_rec.component_item_id
                               AND open_flag = 'Y'
                               AND schedule_ship_date is NOT NULL
                               AND shipped_quantity is null)
                        -
                        (SELECT sum(reservation_quantity)
                           FROM mtl_reservations
                          WHERE inventory_item_id = c_bom_temp_rec.component_item_id)),0)
                  INTO l_open_sales_orders
		  FROM DUAL;*/
      
      --Reserved Sales Orders

/*SELECT
SUM(-1 * ( D.PRIMARY_UOM_QUANTITY - GREATEST (NVL (D.RESERVATION_QUANTITY, 0), D.COMPLETED_QUANTITY) )) 
INTO l_resv_ord_qty
FROM
  mtl_parameters p,
  mtl_system_items i,
  bom_calendar_dates c,
  mtl_demand d,
  mfg_lookups ml,
  (
    SELECT
      DECODE (demand_source_type, 2, DECODE (reservation_type, 1, 2, 3, DECODE
      (supply_source_type, 5, 23, 31), 9 ), 8, DECODE (reservation_type, 1, 21,
      22), demand_source_type) supply_demand_source_type,
      demand_id
    FROM
      mtl_demand
  )
  dx,
  oe_order_headers_all ooha,
  oe_order_lines_all oola
WHERE
  1                        =1
AND d.demand_source_line   = oola.line_id
AND ooha.header_id         = oola.header_id
AND d.organization_id      = c_bom_temp_rec.organization_id
AND d.demand_id            = dx.demand_id
AND ml.lookup_type         = 'MTL_SUPPLY_DEMAND_SOURCE_TYPE'
AND ml.lookup_code         = dx.supply_demand_source_type
AND d.primary_uom_quantity > GREATEST (NVL (d.reservation_quantity, 0),
  d.completed_quantity)
AND d.inventory_item_id   = c_bom_temp_rec.component_item_id
AND d.available_to_atp    = 1
AND d.reservation_type   != -1
AND d.demand_source_type != 13
AND d.demand_source_type != -1
AND
  (
    d.subinventory  IS NULL
  OR d.subinventory IN
    (
      SELECT
        s.secondary_inventory_name
      FROM
        mtl_secondary_inventories s
      WHERE
        s.organization_id      = d.organization_id
      AND s.inventory_atp_code = 1
    )
  )
AND i.organization_id           = d.organization_id
AND i.inventory_item_id         = d.inventory_item_id
AND p.organization_id           = d.organization_id
AND p.calendar_code             = c.calendar_code
AND p.calendar_exception_set_id = c.exception_set_id
AND c.calendar_date             = TRUNC (d.requirement_date)
AND d.inventory_item_id         = DECODE (d.reservation_type, 1, DECODE (
  D.PARENT_DEMAND_ID, NULL, D.INVENTORY_ITEM_ID, -1 ), 2, D.INVENTORY_ITEM_ID,
  3, d.inventory_item_id,                        -1 );
      
       EXCEPTION
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log
                                  (XX_EMF_CN_PKG.CN_LOW,
                                   'Error while deriving RESERVED SALES ORDERS! '
                                  );
         END;*/


BEGIN
  SELECT NVL(SUM(NVL( -1 * ( d.primary_uom_quantity - d.total_reservation_quantity - D.COMPLETED_QUANTITY ), 0)),0)
  INTO L_OPEN_SALES_ORDERS
  FROM mtl_parameters p,
    mtl_system_items i,
    bom_calendar_dates c,
    mrp_demand_om_reservations_v d,
    oe_order_headers_all ooha,
    oe_order_lines_all oola,
    mfg_lookups ml,
    (SELECT DECODE (demand_source_type, 2, DECODE (reservation_type, 1, 2, 3, 23, 9), 8, DECODE (reservation_type, 1, 21, 22), demand_source_type ) supply_demand_source_type,
      demand_id
    FROM mrp_demand_om_reservations_v
    ) dx
  WHERE d.open_flag                     = 'Y'
  AND ml.lookup_type                    = 'MTL_SUPPLY_DEMAND_SOURCE_TYPE'
  AND ml.lookup_code                    = dx.supply_demand_source_type
  AND d.demand_id                       = dx.demand_id
  AND ooha.header_id                    = oola.header_id
  AND oola.line_id                      = d.demand_id
  AND d.reservation_type               != 2
  AND d.organization_id                 = c_bom_temp_rec.organization_id
  AND d.primary_uom_quantity            > (d.total_reservation_quantity + d.completed_quantity )
  AND d.inventory_item_id               = c_bom_temp_rec.component_item_id
  AND ( d.visible_demand_flag           = 'Y'
  OR ( NVL (d.visible_demand_flag, 'N') = 'N'
  AND d.ato_line_id                    IS NOT NULL
  AND NOT EXISTS
    (SELECT NULL
    FROM oe_order_lines_all ool,
      mtl_demand md
    WHERE TO_CHAR (ool.line_id) = md.demand_source_line
    AND ool.ato_line_id         = d.ato_line_id
    AND ool.item_type_code      = 'CONFIG'
    AND md.reservation_type    IN (2, 3)
    ) ) )
  AND d.reservation_type   != -1
  AND d.reservation_type   != -1
  AND d.demand_source_type != -1
  AND d.demand_source_type != -1
  AND (d.subinventory      IS NULL
  OR d.subinventory        IN
    (SELECT s.secondary_inventory_name
    FROM mtl_secondary_inventories s
    WHERE s.organization_id  = d.organization_id
    AND s.inventory_atp_code = 1
    AND s.attribute1         = 'FG'
    ) )
  AND i.organization_id           = d.organization_id
  AND i.inventory_item_id         = d.inventory_item_id
  AND p.organization_id           = d.organization_id
  AND p.calendar_code             = c.calendar_code
  AND p.calendar_exception_set_id = c.exception_set_id
  AND c.calendar_date             = TRUNC (d.requirement_date)
  AND d.inventory_item_id         = DECODE (d.reservation_type, 1, DECODE (d.parent_demand_id, NULL, d.inventory_item_id, -1 ), 2, d.inventory_item_id, 3, d.inventory_item_id, -1 );
EXCEPTION
WHEN OTHERS THEN
  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Error while deriving OPEN SALES ORDERS! ' );
END;

--L_OPEN_SALES_ORDERS := NVL(L_RESV_ORD_QTY,0) + NVL(L_INTR_ORD_QTY,0);


         BEGIN
            /*SELECT NVL (SUM (quantity_open), 0)
              INTO l_open_wo_demand
              FROM wip_requirement_operations_v
             WHERE inventory_item_id = c_bom_temp_rec.component_item_id
               AND organization_id = c_bom_temp_rec.organization_id;*/
               
    SELECT   
        NVL(SUM (LEAST (-1 * (O.REQUIRED_QUANTITY - O.QUANTITY_ISSUED), 0)),0)
        into L_OPEN_WO_DEMAND 
  FROM                                           
       mtl_parameters p,
       mfg_lookups ml,
       -- mtl_atp_rules r,
       mtl_system_items i,
       bom_calendar_dates c,
       wip_requirement_operations o,
       wip_discrete_jobs d,
       wip_entities we,
       (select DECODE (job_type, 1, 5, 7) supply_demand_source_type, wip_entity_id from wip_discrete_jobs) dx
 WHERE 1 = 1
 and we.wip_entity_id = d.wip_entity_id
   AND ml.lookup_type         = 'MRP_SUPPLY_DEMAND_SOURCE_TYPE'
  AND ml.lookup_code         = dx.supply_demand_source_type
  and d.wip_entity_id = dx.wip_entity_id
   AND O.ORGANIZATION_ID = D.ORGANIZATION_ID
   AND o.organization_id = c_bom_temp_rec.organization_id
   AND o.inventory_item_id = c_bom_temp_rec.component_item_id
   AND o.wip_entity_id = d.wip_entity_id
   AND o.wip_supply_type NOT IN (5, 6)
   AND o.required_quantity > 0
   AND o.required_quantity <> (o.quantity_issued)
   AND o.operation_seq_num > 0
   AND o.date_required IS NOT NULL
   AND (   o.supply_subinventory IS NULL
        OR EXISTS (
              SELECT 'X'
                FROM mtl_secondary_inventories s
               WHERE s.organization_id = o.organization_id
                 AND o.supply_subinventory = s.secondary_inventory_name
                 AND s.inventory_atp_code = 1)
       )
   AND d.status_type IN (1, 3, 4, 6)
   AND p.organization_id = o.organization_id
   AND i.organization_id = o.organization_id
   AND i.inventory_item_id = o.inventory_item_id
   AND p.calendar_code = c.calendar_code
   AND P.CALENDAR_EXCEPTION_SET_ID = C.EXCEPTION_SET_ID
   AND c.calendar_date = TRUNC (o.date_required);
                        
         EXCEPTION
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log
                             (XX_EMF_CN_PKG.CN_LOW,
                              'Error while deriving WIP DEMAND WORD ORDER DEMAND! '
                             );
         END;
      
/*BEGIN
      
SELECT
  SUM ((D.START_QUANTITY - D.QUANTITY_COMPLETED - D.QUANTITY_SCRAPPED ))
  into l_wo_sup_qty
FROM
  wip_discrete_jobs d,
  bom_calendar_dates c,
  mtl_parameters p,
  mtl_system_items i,
  wip_entities we,
  (
    SELECT
      DECODE (job_type, 1, 5, 7) supply_demand_source_type,
      wip_entity_id
    FROM
      wip_discrete_jobs
  )
  dx,
  mfg_lookups ml
WHERE
  1                              =1
AND d.wip_entity_id              = dx.wip_entity_id
AND dx.supply_demand_source_type = ml.lookup_code
AND ml.lookup_type               = 'MRP_SUPPLY_DEMAND_SOURCE_TYPE'
AND d.wip_entity_id              = we.wip_entity_id
AND d.status_type               IN (1, 3, 4, 6)
AND
  (
    d.start_quantity - d.quantity_completed
  )
                      > 0
AND d.organization_id = c_bom_temp_rec.organization_id
AND d.primary_item_id = c_bom_temp_rec.component_item_id
AND
  (
    d.completion_subinventory IS NULL
  OR EXISTS
    (
      SELECT
        'X'
      FROM
        mtl_secondary_inventories s
      WHERE
        s.organization_id           = d.organization_id
      AND d.completion_subinventory = s.secondary_inventory_name
      AND s.inventory_atp_code      = 1
    )
  )
AND p.organization_id           = d.organization_id
AND i.organization_id           = d.organization_id
AND i.inventory_item_id         = d.primary_item_id
AND p.calendar_code             = c.calendar_code
AND P.CALENDAR_EXCEPTION_SET_ID = C.EXCEPTION_SET_ID
AND c.calendar_date             = TRUNC (d.scheduled_completion_date);
      
      EXCEPTION
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log
                             (XX_EMF_CN_PKG.CN_LOW,
                              'Error while deriving WIP SUPPLY WORD ORDER DEMAND! '
                             );
         END;
         
  L_OPEN_WO_DEMAND :=  NVL(l_wo_dmd_qty,0) + NVL(l_wo_sup_qty,0);*/

--         BEGIN
--            SELECT NVL (SUM (rcvl.quantity_shipped), 0)
--              INTO l_intransit
--              FROM rcv_shipment_headers rcvh, rcv_shipment_lines rcvl
--             WHERE rcvh.shipment_header_id = rcvl.shipment_header_id
--               AND rcvl.item_id = c_bom_temp_rec.component_item_id
--               AND rcvh.receipt_source_code = 'INTERNAL ORDER';
--         EXCEPTION
--            WHEN OTHERS
--            THEN
--               xx_emf_pkg.write_log
--                               (xx_emf_cn_pkg.cn_low,
--                                'Error while deriving INTRANSIT IR ISO/IPO! '
--                               );
--         END;


	 BEGIN
		 SELECT nvl(SUM(ms.quantity),0)
		   INTO l_intransit
		   FROM mtl_supply ms,
			mtl_material_transactions mmt,
			rcv_shipment_lines rsl,
			mtl_system_items msi
		  WHERE 1=1
		    AND ms.to_organization_id = c_bom_temp_rec.organization_id
		    AND ms.supply_type_code IN ('SHIPMENT', 'RECEIVING')
		    AND ms.destination_type_code = 'INVENTORY'
		    AND rsl.shipment_line_id = ms.shipment_line_id
		    AND mmt.transaction_id(+) = rsl.mmt_transaction_id
		    AND msi.inventory_item_id = ms.item_id
		    AND msi.organization_id = ms.from_organization_id
		    AND ( mmt.transaction_action_id = 12
		     OR mmt.transaction_action_id = 21)
		    AND msi.inventory_item_id =c_bom_temp_rec.component_item_id ;
         EXCEPTION
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                'Error while deriving INTRANSIT IR ISO/IPO! '
                               );
         END;

	 BEGIN
		 SELECT NVL(SUM(to_org_primary_quantity),0)
		   INTO l_receipts_qty
		   FROM rcv_supply
		  WHERE 1=1
       AND TO_ORGANIZATION_ID = c_bom_temp_rec.organization_id
		    AND item_id =c_bom_temp_rec.component_item_id ;
         EXCEPTION
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                'Error while deriving Receipts QTY! '
                               );
         END;

         BEGIN
            /*SELECT NVL (SUM (quantity_waiting_to_move), 0)
              INTO l_open_wo_atc
              FROM wip_operations
             WHERE wip_entity_id IN (
                      SELECT wip_entity_id
                        FROM wip_discrete_jobs_v
                       WHERE primary_item_id =
                                              c_bom_temp_rec.component_item_id);*/
                                              
              SELECT NVL (SUM (quantity_remaining), 0)
              INTO l_open_wo_atc
              FROM wip_discrete_jobs_v
              WHERE primary_item_id = c_bom_temp_rec.component_item_id
              AND STATUS_TYPE_DISP IN ('Released','Unreleased')
              AND ORGANIZATION_ID = c_bom_temp_rec.organization_id; --added by omkar 
              
         EXCEPTION
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                     'Error while deriving Open WO (Available to Complete)! '
                    );
         END;

         --BEGIN
         --   SELECT NVL (SUM (rcvl.quantity_shipped), 0)
         --     INTO l_open_po_cumulative
         --     FROM rcv_shipment_headers rcvh, rcv_shipment_lines rcvl
         --    WHERE rcvh.shipment_header_id = rcvl.shipment_header_id
         --      AND rcvl.item_id = c_bom_temp_rec.component_item_id
         --      AND rcvh.receipt_source_code = 'VENDOR';
         --EXCEPTION
         --   WHEN OTHERS
         --   THEN
         --       FND_FILE.PUT_LINE(FND_FILE.log,
         --                            'Error while deriving Open PO! '
         --                           );
         --END;


         BEGIN
		SELECT NVL ( SUM (QUANTITY), 0 )  --po_headers
		  INTO L_OPEN_PO_CUMULATIVE
		  FROM (SELECT DISTINCT POH.SEGMENT1,POH.VENDOR_ID,(PLL.QUANTITY - NVL (PLL.QUANTITY_RECEIVED, 0)) QUANTITY, PLL.NEED_BY_DATE,POL.ITEM_ID --Added by Omkar
			  FROM po_headers_all poh, po_lines_all pol, po_line_locations_all pll,po_distributions_all pod
			 WHERE POH.PO_HEADER_ID = POL.PO_HEADER_ID
			   AND pol.po_line_id = pll.po_line_id
			   AND PLL.LINE_LOCATION_ID = POD.LINE_LOCATION_ID
         AND Pll.SHIP_TO_ORGANIZATION_ID = nvl(p_shipto_org, Pll.SHIP_TO_ORGANIZATION_ID)
			   AND poh.closed_date IS NULL
			   AND POH.TYPE_LOOKUP_CODE NOT IN ('QUOTATION')
         AND (PLL.QUANTITY - NVL (PLL.QUANTITY_RECEIVED, 0)) > =0
	                   AND pol.item_id = c_bom_temp_rec.component_item_id);
         EXCEPTION
            WHEN OTHERS
            THEN
                FND_FILE.PUT_LINE(FND_FILE.log,
                                     'Error while deriving Open PO Cumulative! '
                                   );
         END;


         BEGIN
		/*SELECT NVL(SUM(quantity), 0)
		  INTO l_open_req_cumulative
		  FROM (SELECT distinct porh.segment1,porl.need_by_date,porl.quantity,porl.item_id,porl.vendor_id
			  FROM po_requisition_headers_all porh,
			       po_requisition_lines_all porl,
			       po_req_distributions_all prd
		         WHERE porh.requisition_header_id = porl.requisition_header_id
		           AND porl.requisition_line_id = prd.requisition_line_id
		           AND (upper(porl.closed_code) = 'OPEN' or porl.closed_code is null)
		           AND porl.item_id = c_bom_temp_rec.component_item_id);*/
               
   SELECT NVL(SUM(QUANTITY), 0)
		  INTO L_OPEN_REQ_CUMULATIVE
		  FROM ( SELECT   --added by Omkar
             distinct PRH.SEGMENT1,PRL.NEED_BY_DATE,PRL.QUANTITY,PRL.ITEM_ID,PRL.VENDOR_ID
             FROM 
             PO_REQUISITION_HEADERS_ALL PRH, 
             PO_REQUISITION_LINES_all PRL, 
             APPS.PER_PEOPLE_F PPF1, 
             (SELECT DISTINCT AGENT_ID,AGENT_NAME FROM APPS.PO_AGENTS_V ) PPF2, 
             PO_REQ_DISTRIBUTIONS_ALL PRD, 
             INV.MTL_SYSTEM_ITEMS_B MSI, 
             PO_LINE_LOCATIONS_ALL PLL, 
             PO_LINES_ALL PL, 
             PO_HEADERS_all PH
             WHERE 
             PRH.REQUISITION_HEADER_ID = PRL.REQUISITION_HEADER_ID 
             AND PRL.REQUISITION_LINE_ID = PRD.REQUISITION_LINE_ID 
             AND PPF1.PERSON_ID = PRH.PREPARER_ID 
             AND PRH.CREATION_DATE BETWEEN PPF1.EFFECTIVE_START_DATE AND PPF1.EFFECTIVE_END_DATE 
             AND PPF2.AGENT_ID(+) = MSI.BUYER_ID 
             AND MSI.INVENTORY_ITEM_ID = PRL.ITEM_ID 
             AND MSI.ORGANIZATION_ID = PRL.DESTINATION_ORGANIZATION_ID 
             AND PLL.LINE_LOCATION_ID(+) = PRL.LINE_LOCATION_ID 
             AND PLL.PO_HEADER_ID = PH.PO_HEADER_ID(+) 
             AND PLL.PO_LINE_ID = PL.PO_LINE_ID(+) 
             AND PRH.AUTHORIZATION_STATUS IN ('APPROVED','IN PROCESS', 'INCOMPLETE', 'PRE–APPROVED')
             AND PLL.LINE_LOCATION_ID IS NULL 
             AND PRL.CLOSED_CODE IS NULL 
             AND NVL(PRL.CANCEL_FLAG,'N') <> 'Y'
             AND PRH.TYPE_LOOKUP_CODE <> 'INTERNAL' --added to eliminate Internal Req
             AND PRL.DESTINATION_ORGANIZATION_ID = NVL(  p_shipto_org, PRL.DESTINATION_ORGANIZATION_ID)
             AND PRL.ITEM_ID =c_bom_temp_rec.component_item_id );      
               
         EXCEPTION
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log
                                  (xx_emf_cn_pkg.cn_low,
                                   'Error while deriving Open Requisitions Cumulative! '
                                  );
         END;
         
         BEGIN
		   SELECT COUNT(*)   -- added by Omkar
      INTO L_REQ_COUNT_DUP
      FROM PO_REQUISITION_HEADERS_ALL PRH,
      PO_REQUISITION_LINES_ALL PRL,
      PO_REQ_DISTRIBUTIONS_ALL PRD,
      PO_LINE_LOCATIONS_ALL PLL,
      PO_LINES_ALL PL,
      PO_HEADERS_ALL PH
      WHERE prh.requisition_header_id = prl.requisition_header_id
      AND prl.requisition_line_id     = prd.requisition_line_id
      AND pll.line_location_id(+)   = prl.line_location_id
      AND pll.po_header_id          = ph.po_header_id(+)
      AND PLL.PO_LINE_ID            = PL.PO_LINE_ID(+)
      AND PRH.AUTHORIZATION_STATUS  IN ('APPROVED','IN PROCESS', 'INCOMPLETE', 'PRE–APPROVED')
      AND PLL.LINE_LOCATION_ID     IS NULL
      AND PRL.CLOSED_CODE          IS NULL
      AND NVL(PRL.CANCEL_FLAG,'N') <> 'Y'
      AND PRH.TYPE_LOOKUP_CODE <> 'INTERNAL'
      AND PRL.DESTINATION_ORGANIZATION_ID = NVL(  p_shipto_org, PRL.DESTINATION_ORGANIZATION_ID)
      AND prl.item_id = c_bom_temp_rec.component_item_id;
		  EXCEPTION
		    WHEN OTHERS
		    THEN
		       xx_emf_pkg.write_log
					  (xx_emf_cn_pkg.cn_low,
					   'Error while deriving Open Requisition Quantity! '
					  );
		  END;
		

         l_short_hzn :=
              (L_AVAIL_TO_TRANSACT)
            - (L_FORECAST)
            + (L_OPEN_SALES_ORDERS) -- addition because Open Sales Order Demand returning negative values
            + (l_open_wo_demand);  -- addition because Open WO Demand returning negative values

         l_long_hzn :=
              (nvl(l_short_hzn,0))
            + (l_intransit)
            + (l_receipts_qty)
            + (l_open_wo_atc)
            + (l_open_po_cumulative)
            + (l_open_req_cumulative);

         --   dbms_output.put_line ('l_plan_level' || l_plan_level);
         --   dbms_output.put_line ('l_sort_order' || l_sort_order);
         --   dbms_output.put_line ('l_part_number' || l_part_number);
         --   dbms_output.put_line ('l_item_desc'||l_item_desc);
         --   dbms_output.put_line ('l_quantity'||l_quantity);
         --   dbms_output.put_line ('l_type'||l_type);
         --   dbms_output.put_line ('l_planner_code'||l_planner_code);
         --   dbms_output.put_line ('l_avail_to_transact'||l_avail_to_transact);
         --   dbms_output.put_line ('l_forecast'||l_forecast);
         --   dbms_output.put_line ('l_open_sales_orders'||l_open_sales_orders);
         --   dbms_output.put_line ('l_open_wo_demand'||l_open_wo_demand);
         --   dbms_output.put_line ('l_intransit'||l_intransit);
         --   dbms_output.put_line ('l_open_wo_atc'||l_open_wo_atc);
         --   dbms_output.put_line ('l_open_po_cumulative'||l_open_po_cumulative);
         --   dbms_output.put_line ('l_open_req_cumulative'||l_open_req_cumulative);
         --   dbms_output.put_line ('l_work_order'||l_work_order);
         --   dbms_output.put_line ('l_open_quantity'||l_open_quantity);
         --   dbms_output.put_line ('l_due_date'||l_due_date);
         --   dbms_output.put_line ('l_supplier_name '||l_supplier_name);

         --   dbms_output.put_line ('NEAR IF l_type ');
         IF l_type = 'Make'
         THEN
            --       dbms_output.put_line ('INSIDE IF l_type ');
            BEGIN
               SELECT COUNT (*)
                 INTO l_wip_count
                 FROM wip_discrete_jobs_v
                WHERE 1=1
                  AND upper(status_type_disp) = 'RELEASED'
                  AND primary_item_id = c_bom_temp_rec.component_item_id;

            EXCEPTION
               WHEN OTHERS
               THEN
                   FND_FILE.PUT_LINE(FND_FILE.log,
                                        'Error while deriving l_wip_count! '
                                       );
            END;

            IF l_wip_count > 0
            THEN
               FOR c_wip_rec IN c_wip (c_bom_temp_rec.component_item_id)
               LOOP
                  --       dbms_output.put_line ('Inside c_wip ');
              /*    l_work_order := c_wip_rec.wip_entity_name;
                  l_open_quantity := NVL (c_wip_rec.open_qty, 0);
                  l_order_type := 'Work Order';
                  l_due_date := c_wip_rec.scheduled_completion_date;
                  l_supplier_name := NULL; -- added by omkar*/
                  
                  L_OPEN_QUANTITY_WO := SIGN(NVL (C_WIP_REC.OPEN_QTY, 0));  --Added New Login To Eliminate WO with 0 Open Quantity
                  
                  IF (L_OPEN_QUANTITY_WO = -1 OR L_OPEN_QUANTITY_WO = 0) THEN
                  L_OPEN_QUANTITY := NULL;
                  L_ORDER_TYPE := NULL;
                  L_SUPPLIER_NAME := NULL;
                  L_DUE_DATE := NULL;
                  L_WORK_ORDER := NULL;
                  ELSIF L_OPEN_QUANTITY_WO = +1 THEN
                  L_WORK_ORDER := C_WIP_REC.WIP_ENTITY_NAME;
                  L_OPEN_QUANTITY := NVL (C_WIP_REC.OPEN_QTY, 0);
                  L_ORDER_TYPE := 'Work Order';
                  L_DUE_DATE := C_WIP_REC.SCHEDULED_COMPLETION_DATE;
                  L_SUPPLIER_NAME := NULL;
                  END IF;
                  
                  
                  BEGIN
                     INSERT INTO XXINTG.XX_BOM_REPORT_66
                                 (org_name,org_code, todays_date, sort_order,
                                  top_bill_sequence_id, bill_sequence_id,
                                  component_sequence_id, component_item_id,
                                  top_item_id, assembly_item_id,
                                  bom_level, part_number, description,
                                  bom_qty, item_type, planner_code,
                                  available_to_transact, forecast,
                                  open_sales_order, open_work_order_demand,
                                  short_hzn, intransit,receipts_qty,open_wo_atc,
                                  open_po_cumulative, open_req_cumulative, long_hzn,
                                  due_date, open_quantity,order_type, order_number,
                                  supplier, attribute1, attribute2,
                                  attribute3, attribute4, attribute5,
                                  attribute6, attribute7, attribute8,
                                  attribute9, attribute10
                                 )
                          VALUES (v_org_name,v_org_code, SYSDATE, l_sort_order,
                                  l_top_bill_seq_id, l_bill_seq_id,
                                  l_comp_seq_id, l_comp_item_id,
                                  l_top_item_id, l_assembly_item_id,
                                  l_plan_level, l_part_number, l_item_desc,
                                  l_quantity, l_type, l_planner_code,
                                  l_avail_to_transact, l_forecast,
                                  l_open_sales_orders, l_open_wo_demand,
                                  nvl(l_short_hzn,0), l_intransit,l_receipts_qty,l_open_wo_atc,
                                  l_open_po_cumulative, l_open_req_cumulative, nvl(l_long_hzn,0),
                                  l_due_date, l_open_quantity,l_order_type, l_work_order,
                                  l_supplier_name, NULL, NULL,
                                  NULL, NULL, NULL,
                                  NULL, NULL, NULL,
                                  NULL, NULL
                                 );

 -- insert into APPS.XX_BOM_TEST values (l_cnt,'Loop'|| l_cnt, l_part_number, 'WO');

                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        xx_emf_pkg.write_log
                           (xx_emf_cn_pkg.cn_low,
                            'Error while INSERTING INTO TABLE XXINTG.XX_BOM_REPORT_66! '
                           );
                  END;
               END LOOP;
            ELSE
               l_work_order := NULL;
               l_open_quantity := 0;
               l_order_type := NULL;
               l_supplier_name := NULL;   --added by omkar 
               l_due_date := NULL;
               
               BEGIN
                     INSERT INTO XXINTG.XX_BOM_REPORT_66
                                 (org_name,org_code, todays_date, sort_order,
                                  top_bill_sequence_id, bill_sequence_id,
                                  component_sequence_id, component_item_id,
                                  top_item_id, assembly_item_id,
                                  bom_level, part_number, description,
                                  bom_qty, item_type, planner_code,
                                  available_to_transact, forecast,
                                  open_sales_order, open_work_order_demand,
                                  short_hzn, intransit,receipts_qty, open_wo_atc,
                                  open_po_cumulative, open_req_cumulative, long_hzn,
                                  due_date, open_quantity,order_type, order_number,
                                  supplier, attribute1, attribute2,
                                  attribute3, attribute4, attribute5,
                                  attribute6, attribute7, attribute8,
                                  attribute9, attribute10
                                 )
                       VALUES (v_org_name,v_org_code, SYSDATE, l_sort_order,
                               l_top_bill_seq_id, l_bill_seq_id,
                               l_comp_seq_id, l_comp_item_id,
                               l_top_item_id, l_assembly_item_id,
                               l_plan_level, l_part_number, l_item_desc,
                               l_quantity, l_type, l_planner_code,
                               l_avail_to_transact, l_forecast,
                               l_open_sales_orders, l_open_wo_demand,
                               nvl(l_short_hzn,0), l_intransit,l_receipts_qty,l_open_wo_atc,
                               l_open_po_cumulative, l_open_req_cumulative, nvl(l_long_hzn,0),
                               l_due_date, l_open_quantity,l_order_type, l_work_order,
                               l_supplier_name, NULL, NULL, NULL,
                               NULL, NULL, NULL,
                               NULL, NULL, NULL,
                               NULL
                              );
                              
                            --  insert into APPS.XX_BOM_TEST values (l_cnt,'Loop'|| l_cnt, l_part_number, 'non WO else part');

                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                         'Error while INSERTING INTO TABLE XXINTG.XX_BOM_REPORT_66! '
                        );
               END;
            END IF;
         END IF;

         IF l_type = 'Buy'
         THEN
           -- BEGIN
           --    SELECT NVL (SUM (quantity), 0)
           --      INTO l_open_quantity
           --      FROM po_line_locations_all
           --     WHERE po_line_id IN (
           --                   SELECT po_line_id
           --                     FROM po_lines_all
           --                    WHERE item_id =
           --                                   c_bom_temp_rec.component_item_id);
           -- EXCEPTION
           --    WHEN OTHERS
           --    THEN
           --       xx_emf_pkg.write_log
           --                           (xx_emf_cn_pkg.cn_low,
           --                            'Error while deriving Open Quantity! '
           --                           );
           -- END;
            --l_po_count := 0;
            
      --added req count again as additional duplicate line was printing with no data for requisition      
   /*   BEGIN
            SELECT COUNT(*)   -- added by Omkar
      INTO l_req_count_check
      FROM po.po_requisition_headers_all prh,
      po.po_requisition_lines_all prl,
      po.po_req_distributions_all prd,
      po.po_line_locations_all pll,
      po.po_lines_all pl,
      po.po_headers_all ph
      WHERE prh.requisition_header_id = prl.requisition_header_id
      AND prl.requisition_line_id     = prd.requisition_line_id
      AND pll.line_location_id(+)   = prl.line_location_id
      AND pll.po_header_id          = ph.po_header_id(+)
      AND PLL.PO_LINE_ID            = PL.PO_LINE_ID(+)
      AND PRH.AUTHORIZATION_STATUS  IN ('APPROVED','IN PROCESS', 'INCOMPLETE', 'PRE–APPROVED')
      AND PLL.LINE_LOCATION_ID     IS NULL
      AND PRL.CLOSED_CODE          IS NULL
      AND NVL(PRL.CANCEL_FLAG,'N') <> 'Y'
      AND prl.item_id = c_bom_temp_rec.component_item_id;


            EXCEPTION
               WHEN OTHERS
               THEN
                  xx_emf_pkg.write_log
                                      (xx_emf_cn_pkg.cn_low,
                                       'Error while deriving REQ Count '
                                      );
      END;*/
            
            
            

            BEGIN
               SELECT COUNT (*)
                 INTO L_PO_COUNT
                 FROM po_headers_all poh, po_lines_all pol, po_line_locations_all pll
                WHERE POH.PO_HEADER_ID = POL.PO_HEADER_ID
                 AND pol.po_line_id = pll.po_line_id
                  AND UPPER(POH.CLOSED_CODE) = 'OPEN'
                  AND Pll.SHIP_TO_ORGANIZATION_ID = nvl(p_shipto_org, Pll.SHIP_TO_ORGANIZATION_ID)
                  AND pol.item_id = c_bom_temp_rec.component_item_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  xx_emf_pkg.write_log
                                      (xx_emf_cn_pkg.cn_low,
                                       'Error while deriving PO Count '
                                      );
            END;

            IF l_po_count > 0
            THEN
               FOR c_po_rec IN c_po (c_bom_temp_rec.component_item_id,p_shipto_org)
               LOOP
                  DBMS_OUTPUT.PUT_LINE ('Inside c_po ');
                /*  l_work_order := c_po_rec.segment1;
                  L_DUE_DATE := C_PO_REC.NEED_BY_DATE;
                  L_OPEN_QTY_SIGN := SIGN(C_PO_REC.QUANTITY_DUE);
            
            IF (L_OPEN_QTY_SIGN = -1 OR L_OPEN_QTY_SIGN = 0) THEN
            L_OPEN_QUANTITY := 0;
            ELSIF L_OPEN_QTY_SIGN = +1 THEN
                  L_OPEN_QUANTITY := C_PO_REC.QUANTITY_DUE;
            END IF;      
            
                  L_ORDER_TYPE := 'Purchase Order';*/         

                  BEGIN
                     SELECT vendor_name
                       INTO l_supplier_name
                       FROM po_vendors
                      WHERE vendor_id = c_po_rec.vendor_id;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        xx_emf_pkg.write_log
                                      (xx_emf_cn_pkg.cn_low,
                                       'Error while deriving Supplier Name! '
                                      );
                  END;
 
 
                L_OPEN_QTY_SIGN := SIGN(C_PO_REC.QUANTITY_DUE);    --New Code for Test
                  
                IF (L_OPEN_QTY_SIGN = -1 OR L_OPEN_QTY_SIGN = 0) THEN
                L_OPEN_QUANTITY := NULL;
                L_ORDER_TYPE := NULL;
                L_SUPPLIER_NAME := NULL;
                L_DUE_DATE := NULL;
                L_WORK_ORDER := NULL;
                ELSIF L_OPEN_QTY_SIGN = +1 THEN
                L_WORK_ORDER := C_PO_REC.SEGMENT1;
                L_DUE_DATE := C_PO_REC.NEED_BY_DATE;
                L_OPEN_QUANTITY := C_PO_REC.QUANTITY_DUE;
                L_ORDER_TYPE := 'Purchase Order';
                END IF;
                
                

                  BEGIN
                     INSERT INTO XXINTG.XX_BOM_REPORT_66
                                 (org_name,org_code, todays_date, sort_order,
                                  top_bill_sequence_id, bill_sequence_id,
                                  component_sequence_id, component_item_id,
                                  top_item_id, assembly_item_id,
                                  bom_level, part_number, description,
                                  bom_qty, item_type, planner_code,
                                  available_to_transact, forecast,
                                  open_sales_order, open_work_order_demand,
                                  short_hzn, intransit,receipts_qty, open_wo_atc,
                                  open_po_cumulative, open_req_cumulative, long_hzn,
                                  due_date, open_quantity,order_type ,order_number,
                                  supplier, attribute1, attribute2,
                                  attribute3, attribute4, attribute5,
                                  attribute6, attribute7, attribute8,
                                  attribute9, attribute10
                                 )
                          VALUES (v_org_name,v_org_code, SYSDATE, l_sort_order,
                                  l_top_bill_seq_id, l_bill_seq_id,
                                  l_comp_seq_id, l_comp_item_id,
                                  l_top_item_id, l_assembly_item_id,
                                  l_plan_level, l_part_number, l_item_desc,
                                  l_quantity, l_type, l_planner_code,
                                  l_avail_to_transact, l_forecast,
                                  l_open_sales_orders, l_open_wo_demand,
                                  nvl(l_short_hzn,0), l_intransit,l_receipts_qty,l_open_wo_atc,
                                  l_open_po_cumulative, l_open_req_cumulative, nvl(l_long_hzn,0),
                                  l_due_date, l_open_quantity,l_order_type, l_work_order,
                                  l_supplier_name, NULL, NULL,
                                  NULL, NULL, NULL,
                                  NULL, NULL, NULL,
                                  NULL, NULL
                                 );

                     L_CNT := L_CNT + 1;
                    
                --    insert into APPS.XX_BOM_TEST values (l_cnt,'Loop'|| l_cnt, l_part_number, 'PO');  
                     
                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        xx_emf_pkg.write_log
                           (xx_emf_cn_pkg.cn_low,
                            'Error while INSERTING INTO TABLE XXINTG.XX_BOM_REPORT_66! '
                           );
                  END;
               END LOOP;
            ELSIF L_REQ_COUNT_DUP = 0 then-- added by omkar 
               l_work_order := NULL;
               l_supplier_name := NULL;
               l_due_date := NULL;
               l_open_quantity := 0;
               l_order_type := NULL;

               BEGIN
                     INSERT INTO XXINTG.XX_BOM_REPORT_66
                                 (org_name,org_code, todays_date, sort_order,
                                  top_bill_sequence_id, bill_sequence_id,
                                  component_sequence_id, component_item_id,
                                  top_item_id, assembly_item_id,
                                  bom_level, part_number, description,
                                  bom_qty, item_type, planner_code,
                                  available_to_transact, forecast,
                                  open_sales_order, open_work_order_demand,
                                  short_hzn, intransit,receipts_qty,open_wo_atc,
                                  open_po_cumulative, open_req_cumulative, long_hzn,
                                  due_date, open_quantity,order_type ,order_number,
                                  supplier, attribute1, attribute2,
                                  attribute3, attribute4, attribute5,
                                  attribute6, attribute7, attribute8,
                                  attribute9, attribute10
                                 )
                       VALUES (v_org_name,v_org_code, SYSDATE, l_sort_order,
                               l_top_bill_seq_id, l_bill_seq_id,
                               l_comp_seq_id, l_comp_item_id,
                               l_top_item_id, l_assembly_item_id,
                               l_plan_level, l_part_number, l_item_desc,
                               l_quantity, l_type, l_planner_code,
                               l_avail_to_transact, l_forecast,
                               l_open_sales_orders, l_open_wo_demand,
                               nvl(l_short_hzn,0), l_intransit,l_receipts_qty,l_open_wo_atc,
                               l_open_po_cumulative, l_open_req_cumulative, nvl(l_long_hzn,0),
                               l_due_date, l_open_quantity,l_order_type, l_work_order,
                               l_supplier_name, NULL, NULL, NULL,
                               NULL, NULL, NULL,
                               NULL, NULL, NULL,
                               NULL
                              );

               --    insert into APPS.XX_BOM_TEST values (l_cnt,'Loop'|| l_cnt, l_part_number, 'non PO else part');

                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                         'Error while INSERTING INTO TABLE XXINTG.XX_BOM_REPORT_66! '
                        );
               END;
            END IF;

--- start for requisition derivation

            BEGIN

		/* SELECT COUNT (*)
		   INTO l_req_count
		   FROM po_requisition_headers_all porh,
			po_requisition_lines_all porl
		  WHERE porh.requisition_header_id = porl.requisition_header_id
		 --   AND upper(porh.closed_code) = 'OPEN'
		    AND porl.item_id = c_bom_temp_rec.component_item_id;*/
        
      SELECT COUNT(*)   -- added by Omkar
      INTO L_REQ_COUNT
      FROM PO_REQUISITION_HEADERS_ALL PRH,
      PO_REQUISITION_LINES_ALL PRL,
      PO_REQ_DISTRIBUTIONS_ALL PRD,
      PO_LINE_LOCATIONS_ALL PLL,
      PO_LINES_ALL PL,
      PO_HEADERS_ALL PH
      WHERE prh.requisition_header_id = prl.requisition_header_id
      AND prl.requisition_line_id     = prd.requisition_line_id
      AND pll.line_location_id(+)   = prl.line_location_id
      AND pll.po_header_id          = ph.po_header_id(+)
      AND PLL.PO_LINE_ID            = PL.PO_LINE_ID(+)
      AND PRH.AUTHORIZATION_STATUS  IN ('APPROVED','IN PROCESS', 'INCOMPLETE', 'PRE–APPROVED')
      AND PLL.LINE_LOCATION_ID     IS NULL
      AND PRL.CLOSED_CODE          IS NULL
      AND NVL(PRL.CANCEL_FLAG,'N') <> 'Y'
      AND PRH.TYPE_LOOKUP_CODE <> 'INTERNAL'
      AND PRL.DESTINATION_ORGANIZATION_ID = NVL(  p_shipto_org, PRL.DESTINATION_ORGANIZATION_ID)
      AND prl.item_id = c_bom_temp_rec.component_item_id;


            EXCEPTION
               WHEN OTHERS
               THEN
                  xx_emf_pkg.write_log
                                      (xx_emf_cn_pkg.cn_low,
                                       'Error while deriving REQ Count '
                                      );
            END;

            IF l_req_count > 0 
            THEN
               FOR c_req_rec IN c_req (c_bom_temp_rec.component_item_id)
               LOOP
                  DBMS_OUTPUT.PUT_LINE ('Inside c_req ');
             /*     l_work_order := c_req_rec.segment1;
                  l_due_date := c_req_rec.need_by_date;
                  l_open_quantity := c_req_rec.quantity;
                  l_order_type := 'Requisition';*/

                  BEGIN
                     SELECT vendor_name
                       INTO l_supplier_name
                       FROM po_vendors
                      WHERE vendor_id = c_req_rec.vendor_id;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        xx_emf_pkg.write_log
                                      (xx_emf_cn_pkg.cn_low,
                                       'Error while deriving Supplier Name! '
                                      );
                  END;

                L_OPEN_QUANTITY_REQ := SIGN(C_REQ_REC.QUANTITY);   --added New Code to Eliminate Req with 0 Open Quantity
                
                IF (L_OPEN_QUANTITY_REQ = -1 OR L_OPEN_QUANTITY_REQ = 0) THEN
                L_OPEN_QUANTITY := NULL;
                L_ORDER_TYPE := NULL;
                L_SUPPLIER_NAME := NULL;
                L_DUE_DATE := NULL;
                L_WORK_ORDER := NULL;
                ELSIF L_OPEN_QUANTITY_REQ = +1 THEN
                L_WORK_ORDER := C_REQ_REC.SEGMENT1;
                L_DUE_DATE := C_REQ_REC.NEED_BY_DATE;
                L_OPEN_QUANTITY := C_REQ_REC.QUANTITY;
                L_ORDER_TYPE := 'Requisition';
                END IF;


                  BEGIN
                     INSERT INTO XXINTG.XX_BOM_REPORT_66
                                 (org_name,org_code, todays_date, sort_order,
                                  top_bill_sequence_id, bill_sequence_id,
                                  component_sequence_id, component_item_id,
                                  top_item_id, assembly_item_id,
                                  bom_level, part_number, description,
                                  bom_qty, item_type, planner_code,
                                  available_to_transact, forecast,
                                  open_sales_order, open_work_order_demand,
                                  short_hzn, intransit,receipts_qty, open_wo_atc,
                                  open_po_cumulative, open_req_cumulative, long_hzn,
                                  due_date, open_quantity,order_type ,order_number,
                                  supplier, attribute1, attribute2,
                                  attribute3, attribute4, attribute5,
                                  attribute6, attribute7, attribute8,
                                  attribute9, attribute10
                                 )
                          VALUES (v_org_name,v_org_code, SYSDATE, l_sort_order,
                                  l_top_bill_seq_id, l_bill_seq_id,
                                  l_comp_seq_id, l_comp_item_id,
                                  l_top_item_id, l_assembly_item_id,
                                  l_plan_level, l_part_number, l_item_desc,
                                  l_quantity, l_type, l_planner_code,
                                  l_avail_to_transact, l_forecast,
                                  l_open_sales_orders, l_open_wo_demand,
                                  nvl(l_short_hzn,0), l_intransit,l_receipts_qty,l_open_wo_atc,
                                  l_open_po_cumulative, l_open_req_cumulative, nvl(l_long_hzn,0),
                                  l_due_date, l_open_quantity,l_order_type, l_work_order,
                                  l_supplier_name, NULL, NULL,
                                  NULL, NULL, NULL,
                                  NULL, NULL, NULL,
                                  NULL, NULL
                                 );
                                 
                             --    insert into APPS.XX_BOM_TEST values (l_cnt,'Loop'|| l_cnt, l_part_number, 'REQ');

                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        xx_emf_pkg.write_log
                           (xx_emf_cn_pkg.cn_low,
                            'Error while INSERTING INTO TABLE XXINTG.XX_BOM_REPORT_66! '
                           );
                  END;
               END LOOP;
               
            ELSIF l_po_count = 0 then  -- added by Omkar
               l_work_order := NULL;
               l_supplier_name := NULL;
               l_due_date := NULL;
               l_open_quantity := 0;
               l_order_type := NULL;

               BEGIN
                     INSERT INTO XXINTG.XX_BOM_REPORT_66
                                 (org_name,org_code, todays_date, sort_order,
                                  top_bill_sequence_id, bill_sequence_id,
                                  component_sequence_id, component_item_id,
                                  top_item_id, assembly_item_id,
                                  bom_level, part_number, description,
                                  bom_qty, item_type, planner_code,
                                  available_to_transact, forecast,
                                  open_sales_order, open_work_order_demand,
                                  short_hzn, intransit,receipts_qty,open_wo_atc,
                                  open_po_cumulative, open_req_cumulative, long_hzn,
                                  due_date, open_quantity,order_type ,order_number,
                                  supplier, attribute1, attribute2,
                                  attribute3, attribute4, attribute5,
                                  attribute6, attribute7, attribute8,
                                  attribute9, attribute10
                                 )
                       VALUES (v_org_name,v_org_code, SYSDATE, l_sort_order,
                               l_top_bill_seq_id, l_bill_seq_id,
                               l_comp_seq_id, l_comp_item_id,
                               l_top_item_id, l_assembly_item_id,
                               l_plan_level, l_part_number, l_item_desc,
                               l_quantity, l_type, l_planner_code,
                               l_avail_to_transact, l_forecast,
                               l_open_sales_orders, l_open_wo_demand,
                               nvl(l_short_hzn,0), l_intransit,l_receipts_qty,l_open_wo_atc,
                               l_open_po_cumulative, l_open_req_cumulative, nvl(l_long_hzn,0),
                               l_due_date, l_open_quantity,l_order_type, l_work_order,
                               l_supplier_name, NULL, NULL, NULL,
                               NULL, NULL, NULL,
                               NULL, NULL, NULL,
                               NULL
                              );

         --  insert into APPS.XX_BOM_TEST values (l_cnt,'Loop'|| l_cnt, l_part_number, 'non REQ else part');

                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                         'Error while INSERTING INTO TABLE XXINTG.XX_BOM_REPORT_66! '
                        );
               END;
            END IF;

--- end for requisition derivation
           
         END IF;
      END LOOP;
   END main_prc;
end XX_P2M_MATREQREP_PKG;
/
