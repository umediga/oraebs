DROP PACKAGE BODY APPS.XX_PTP_COMMON_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_PTP_COMMON_PKG" AS
--------------------------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 07-MAR-2012
 File Name     : XXPTPCOMMON.pkb
 Description   : This script creates package body xx_ptp_common_pkg

 Change History:

 Date        Name             Remarks
 ----------- -----------      ---------------------------------------
 07-MAR-2012 IBM Development  Initial development
 */
--------------------------------------------------------------------------------------

/*--------------------------------------------------------------------
--  Procedure will return vendor information required for AP invoice import
--  The IN parameter is Vendor Name AND Vendor Number  AND Vendor Site Code AND ORG_ID.
--  Vendor And Vendor Site Information can be Fetch from the as a pr_vendor_record Record type
--  and  pr_site_code_record as Record Type.
--  Validation - If Vendor Name OR Vendor Number will not be provided, the Procedore will throw error message. Invalid Vendor Name Or Invalid Vendor Number.
--  Validation - If Vendor Name OR Vendor Number will be provided, It will display only Vendor Level Information.
--  Validation - If Vendor Site Code will be provided with Vendor Information, It will display only Vendor  and Vendor site Level Information.
--  Validation - If Vendor Name OR Vendor Number provided, and the provided data is not correct then it will throw error message " Invalid Vendor Name Or Invalid Vendor Number."
--  Validation - If Vendor Name OR Vendor Number provided Correctly , and Vendor Site Code is not Provide Correctly then it will also throw error message.
--  It will also check for Enable flag.
--------------------------------------------------------------------*/
PROCEDURE GET_VENDOR_INFO (
		p_vendor_name              IN OUT po_vendors.vendor_name%type
		, p_vendor_number          IN OUT po_vendors.segment1%type
		, p_vendor_site_code       IN OUT po_vendor_sites.vendor_site_code%type
		, p_org_id                 IN     po_vendor_sites.org_id%type
		, pr_vendor_record         OUT    po_vendors%ROWTYPE
		, pr_site_code_record      OUT   po_vendor_sites%ROWTYPE
		, p_process_status         OUT   NUMBER
		, p_error_message          OUT   VARCHAR2
		)
	IS
BEGIN
		  p_process_status              := 0;
		  p_error_message               := NULL;
   IF  	  p_vendor_name   IS NOT NULL
   THEN
       BEGIN
          SELECT *
          INTO   pr_vendor_record
          FROM   po_vendors        vn
          WHERE  vn.vendor_name    = p_vendor_name;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
               p_process_status  := 1;
               p_error_message   := 'No data found for Vendor Name : ' || p_vendor_name;
               pr_vendor_record     := NULL;
               pr_site_code_record  := NULL;
          WHEN OTHERS THEN
               p_process_status  := 1;
               p_error_message   := 'Invalid Vendor Name '
                                    || substr(SQLERRM, 1, 200);
               pr_vendor_record     := NULL;
               pr_site_code_record  := NULL;
       END;
   ELSIF       p_vendor_number IS NOT NULL
   THEN
          BEGIN
          SELECT *
          INTO   pr_vendor_record
          FROM   po_vendors        vn
          WHERE  vn.segment1       = p_vendor_number;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
               p_process_status  := 1;
               p_error_message   := 'No data found for Vendor Number : ' || p_vendor_number ;
               pr_vendor_record     := NULL;
               pr_site_code_record  := NULL;
          WHEN OTHERS THEN
               p_process_status  := 1;
               p_error_message   := 'Invalid Vendor Number '
                                    || substr(SQLERRM, 1, 200);
               pr_vendor_record     := NULL;
               pr_site_code_record  := NULL;
       END;
-- Condition if the Vendor Or Site level Information will be given to pull the information.
       IF  p_vendor_site_code IS NOT NULL
       OR  p_org_id           IS NOT NULL
       THEN
           BEGIN
              SELECT *
              INTO   pr_site_code_record
              FROM   po_vendor_sites    vs
              WHERE  vs.vendor_id           = pr_vendor_record.vendor_id
              AND    vs.org_id              = nvl(p_org_id, vs.org_id)
              AND    vs.vendor_site_code    = p_vendor_site_code;
           EXCEPTION
              WHEN TOO_MANY_ROWS THEN
                   p_process_status  := 1;
                   p_error_message   := 'Too many records found for Vendor Site code '
                                        || p_vendor_site_code
                                        || ' and Org ID '
                                        || p_org_id;
                   pr_site_code_record  := NULL;
              WHEN NO_DATA_FOUND THEN
                   p_process_status  := 1;
                   p_error_message   := 'No data found for Vendor site code: '
                                     || p_vendor_name ||
                                     ' Or Vendor number '
                                     || p_vendor_number;
                   pr_site_code_record  := NULL;
              WHEN OTHERS THEN
                   p_process_status     := 1;
                   p_error_message      := 'Invalid data for vendor site code'
                                           || substr(SQLERRM, 1, 200);
                   pr_site_code_record  := NULL;
           END;
       END IF;
   ELSE       -- Else for the First IF statement.
       p_process_status  := 1;
       p_error_message   := 'Please provide Vendor Name Or Vendor Number';
       pr_vendor_record     := NULL;
       pr_site_code_record  := NULL;
   END IF;	   -- End if of the First IF Statement
END	GET_VENDOR_INFO;
/*--------------------------------------------------------------------
-- Procedure will retrieve vendor information based on employee number.
-- Employee number is passed as an input parameter.
-- Procedure will return vendor number, name, and ID.
-- Process status is set to 0 for success Or 1 for failure.
--------------------------------------------------------------------*/
PROCEDURE GET_EMPLOYEE_VENDOR_INFO (
		p_employee_num              IN  per_people_f.employee_number%type
		, p_vendor_number           OUT po_vendors.segment1%type
		, p_vendor_name             OUT po_vendors.vendor_name%type
		, p_vendor_id               OUT po_vendors.vendor_id%type
		, p_process_status          OUT NUMBER
		, p_error_message           OUT VARCHAR2
		)
IS
BEGIN
   BEGIN
      SELECT vn.segment1       vendor_number
             , vn.vendor_name
             , vn.vendor_id
      INTO   p_vendor_number
             , p_vendor_name
             , p_vendor_id
      FROM   PO_VENDORS         vn
             , PER_ALL_PEOPLE_F ppf
      WHERE  1  =  1
      AND    ppf.employee_number     = p_employee_num
      AND    ppf.person_id           = vn.employee_id
      AND    vn.vendor_type_lookup_code = 'EMPLOYEE';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
           p_process_status          := 1;
           p_error_message           := 'Employee number ' || p_employee_num ||
                                     ' is not setup as vendor';
      WHEN OTHERS THEN
           p_process_status          := 1;
           p_error_message           := 'Oracle error ' || substr(SQLERRM, 1, 200);
   END;
END GET_EMPLOYEE_VENDOR_INFO;
/*--------------------------------------------------------------------
-- Procedure to Validate the PO
-- It will accept VPo Number and Po Line Number as IN Parameter.
-- It will return Process status 0 Or 1 in terms of success Or failure.
--------------------------------------------------------------------*/
PROCEDURE VALIDATE_PO  (
          p_po_number        IN  po_headers.segment1%type
          , p_po_line        IN  po_lines.line_num%type
          , p_process_status OUT NUMBER
          , p_error_message  OUT VARCHAR2
          )
IS
BEGIN
p_process_status     := 0; -- operation successful
p_error_message      := NULL;
  IF  p_po_number IS NOT NULL
  AND p_po_line   IS NULL
  THEN
      BEGIN
         SELECT  0
         INTO    p_process_status
         FROM    po_headers
         WHERE   UPPER(po_headers.segment1) = UPPER(p_po_number);
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
              p_process_status := 1;
              p_error_message  := 'No data found for Po Number: ' || p_po_number;
         WHEN OTHERS THEN
              p_process_status := 1;
              p_error_message  := substr(SQLERRM,1,200);
      END;
  ELSIF p_po_number IS NOT NULL
  AND   p_po_line   IS NOT NULL
  THEN
      BEGIN
         SELECT 0
         INTO   p_process_status
         FROM   po_headers
                , po_lines
         WHERE  UPPER(po_headers.segment1) = UPPER(p_po_number)
         AND    po_headers.po_header_id    = po_lines.po_header_id
         AND    po_lines.line_num          = p_po_line;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
              p_process_status := 1;
              p_error_message  := 'No data found for Po Number: ' || p_po_number
                                  || ' Or PO line number. ' || p_po_line;
         WHEN OTHERS THEN
              p_process_status := 1;
              p_error_message  := substr(SQLERRM,1,200);
      END;
  ELSE
      p_process_status     := 1; -- operation successful
      p_error_message      := 'Please Provide the PO Number';
  END IF;
END VALIDATE_PO;






/*--------------------------------------------------------------------
Based on the Parameter Provided (item_number and organization_Id )
procedure will Validate the Inventory Item.
If Item does not exist in the database, set process_status to fail (1) and set output parameters to NULL.
If Oracle error is encountered, return first 200 characters of SQLERRM.

--------------------------------------------------------------------*/
FUNCTION VALIDATE_INVENTORY_ITEM  (
          p_item_number                IN  mtl_system_items_b.segment1%type
        , p_inventory_org              IN  org_organization_definitions.organization_id%type
        , p_error_message              OUT VARCHAR2
  ) RETURN NUMBER
IS
l_flag   VARCHAR2(100);

BEGIN
p_error_message      := NULL;

  IF  p_item_number IS NOT NULL
  AND p_inventory_org   IS NOT NULL
  THEN

      BEGIN
            SELECT  0
            INTO    l_flag
            FROM   MTL_SYSTEM_ITEMS_B
            WHERE  segment1        =   p_item_number
            AND    organization_id  =  p_inventory_org;
      RETURN l_flag;

      EXCEPTION
             WHEN NO_DATA_FOUND THEN
                p_error_message  := 'Item number ' || P_item_number || ' Not found in the MTL_SYSTEM ITEM table.';
                RETURN 1;
             WHEN OTHERS THEN
                p_error_message  := substr(SQLERRM,1,200);
                RETURN 1;
      END;


      p_error_message      := 'Please Provide the Item Number and Inventory organization Code';
  END IF;
END VALIDATE_INVENTORY_ITEM;



-- Validating the UOM
  FUNCTION VALIDATE_UOM  (
        p_uom_code                  IN  mtl_units_of_measure_tl.uom_code%type
        , p_error_message            OUT VARCHAR2
  ) RETURN NUMBER
IS
l_flag   VARCHAR2(100);

BEGIN
p_error_message      := NULL;

  IF  p_uom_code IS NOT NULL
  THEN

      BEGIN
            SELECT  0
            INTO    l_flag
            FROM   mtl_units_of_measure_tl muom
            WHERE  muom.uom_code  = p_uom_code;
            RETURN l_flag;

      EXCEPTION
             WHEN NO_DATA_FOUND THEN
                p_error_message  := 'UOM Code  ' || p_uom_code || ' Not found in the mtl_units_of_measure_tl table.';
                RETURN 1;
             WHEN OTHERS THEN
                p_error_message  := substr(SQLERRM,1,200);
                RETURN 1;
      END;


      p_error_message      := 'Please Provide the units of measure ';
  END IF;
END VALIDATE_UOM;




-- Validating Inventory Organization
-- Invenotry Org Code need to pass and it will be validated.
  FUNCTION VALIDATE_INVENTORY_ORG  (
        p_inventory_org         IN  org_organization_definitions.organization_code%type
        , p_error_message       OUT VARCHAR2
  ) RETURN NUMBER
IS
l_flag   VARCHAR2(100);

BEGIN
p_error_message      := NULL;

  IF  p_inventory_org IS NOT NULL
  THEN

      BEGIN
            SELECT  0
            INTO    l_flag
            FROM   org_organization_definitions
            WHERE  organization_code  = p_inventory_org;
            RETURN l_flag;

      EXCEPTION
             WHEN NO_DATA_FOUND THEN
                p_error_message  := 'Inventory org  ' || p_inventory_org || ' Not found in the org_organization_definitions table.';
                RETURN 1;
             WHEN OTHERS THEN
                p_error_message  := substr(SQLERRM,1,200);
                RETURN 1;
      END;


      p_error_message      := 'Please Provide the Inventory Organization ';
  END IF;
END VALIDATE_INVENTORY_ORG;



-- Validating Item template
  FUNCTION VALIDATE_ITEM_TEMPLATE  (
        p_template_name                 IN  mtl_item_templates_b.template_name%type
        , p_error_message               OUT VARCHAR2
  ) RETURN NUMBER
IS
l_flag   VARCHAR2(100);

BEGIN
p_error_message      := NULL;

  IF  p_template_name IS NOT NULL
  THEN

      BEGIN
            SELECT  0
            INTO    l_flag
            FROM   mtl_item_templates_b
            WHERE  template_name  = p_template_name;
            RETURN l_flag;

      EXCEPTION
             WHEN NO_DATA_FOUND THEN
                p_error_message  := 'Template name  ' || p_template_name || ' Not found in the mtl_item_templates_b table.';
                RETURN 1;
             WHEN OTHERS THEN
                p_error_message  := substr(SQLERRM,1,200);
                RETURN 1;
      END;


      p_error_message      := 'Please Provide the Item Template name ';
  END IF;
END VALIDATE_ITEM_TEMPLATE;




-- Validating Sub Inventory Organization
  FUNCTION VALIDATE_SUBINV  (
        p_secondary_inventory_name      IN  mtl_secondary_inventories.secondary_inventory_name%type
        , p_inv_organization_id         IN  mtl_secondary_inventories.organization_id%type
        , p_error_message               OUT VARCHAR2
  ) RETURN NUMBER
IS
l_flag   VARCHAR2(100);

BEGIN
p_error_message      := NULL;

  IF    p_secondary_inventory_name IS NOT NULL
  AND   p_inv_organization_id      IS NOT NULL
  THEN

      BEGIN
            SELECT  0
            INTO    l_flag
            FROM    mtl_secondary_inventories
            WHERE   secondary_inventory_name  = p_secondary_inventory_name
            AND     organization_id           = p_inv_organization_id;
            RETURN l_flag;
      EXCEPTION
             WHEN NO_DATA_FOUND THEN
                p_error_message  := 'Sub Inventory Name ' || p_secondary_inventory_name ||
                                    ' is not available in Oracle';
                RETURN 1;
             WHEN OTHERS THEN
                p_error_message  := 'Oracle error ' || substr(SQLERRM, 1, 200);
                RETURN 1;
      END;


      p_error_message    := 'Please Provide both the Sub Inventory Organization and Organization ID. ';
  END IF;
END VALIDATE_SUBINV;



-- Validating Item Catogory
FUNCTION VALIDATE_ITEM_CATEGORY  (
          p_inventory_item              IN  mtl_system_items_b.segment1%type
        , p_organization_id             IN  mtl_secondary_inventories.organization_id%type
        , P_Category_set_id             IN  mtl_item_categories.category_set_id%type
        , p_error_message               OUT VARCHAR2
  ) RETURN NUMBER
IS
l_flag   VARCHAR2(100);

BEGIN
p_error_message      := NULL;

  IF    P_inventory_item            IS NOT NULL
  AND   p_organization_id           IS NOT NULL
  AND   p_Category_set_id           IS NOT NULL
  THEN

      BEGIN
           SELECT distinct 0
           INTO   l_flag
           FROM   mtl_item_categories  mic
                  , mtl_system_items_b msi
           WHERE  mic.Category_set_id 	= p_Category_set_id
           AND	  mic.organization_id   = p_organization_id
           AND    msi.segment1          = p_inventory_item
           AND    msi.inventory_Item_id = mic.inventory_Item_id;
      RETURN l_flag;
      EXCEPTION
             WHEN NO_DATA_FOUND THEN
                p_error_message  := 'Please check the Item category for Item ' || P_inventory_item ||
                                    ' is not available in Oracle';
                RETURN 1;
             WHEN OTHERS THEN
                p_error_message  := 'Oracle error ' || substr(SQLERRM, 1, 200);
                RETURN 1;
      END;


      p_error_message    := 'Please Provide Item number , Organization_id , and Category Set Id ';
  END IF;
END VALIDATE_ITEM_CATEGORY;


-- Procedure to Validate and fetch Item and Item Level Attribute Information.
-- This proceudre will first Validate the Item Oce the Item is validated then all the Column of the MTL system Item are
-- populated into a Variable which can printed as per
 PROCEDURE GET_ITEM_INFO (
          p_item_number              IN OUT mtl_system_items_b.segment1%type
          , p_organization_id        IN OUT mtl_system_items_b.organization_id%type
          , pr_Item_record           OUT    mtl_system_items_b%rowtype
          , p_process_status         OUT    NUMBER
          , p_error_message          OUT    VARCHAR2
          )
   IS
BEGIN

		  p_process_status      := 0;
		  p_error_message       := NULL;

IF  	  p_item_number         IS NOT NULL
AND       p_organization_id     IS NOT NULL
THEN

      BEGIN
            SELECT  *
            INTO    pr_Item_record
            FROM    MTL_SYSTEM_ITEMS_B
            WHERE   segment1           =  p_item_number
            AND     organization_id   =  p_organization_id;
            p_process_status      := 0;

      EXCEPTION
             WHEN NO_DATA_FOUND THEN
                p_error_message  := 'No data found for Item number:  ' || P_item_number || ' in the MTL_SYSTEM ITEM table.';
                pr_Item_record   :=  NULL;
                p_process_status      := 1;
         WHEN OTHERS THEN
                pr_Item_record   :=  NULL;
                p_error_message  := substr(SQLERRM,1,200);
                p_process_status      := 1;
      END;

ELSE
       p_process_status  := 1;
       p_error_message   := 'Please provide both the Item Number and Organization ID';

END IF;

END GET_ITEM_INFO;






-- Procedure to get the Item Cost
  PROCEDURE GET_ITEM_COST  (
          p_item_id                  IN  NUMBER
        , p_cost_type                IN  VARCHAR2
        , p_organization_id          IN  NUMBER
        , P_item_cost                OUT NUMBER
        , p_process_status           OUT NUMBER
        , p_error_message            OUT VARCHAR2
  )
IS
BEGIN
p_process_status     := 0; -- operation successful
p_error_message      := NULL;
  IF  p_item_id         IS NOT NULL
  AND p_cost_type       IS NOT NULL
  AND p_organization_id IS NOT NULL
  THEN
      BEGIN

       SELECT    Item_cost
       INTO      P_item_cost
       FROM      cst_item_costs ctc
              ,  cst_cost_types cct
       WHERE	 Inventory_item_id =      p_item_id
       AND	     ctc.organization_id   =  p_organization_id
       AND       ctc.Cost_type_id   =     cct.Cost_type_id
       AND	     cct.cost_type	    =     p_cost_type;

     EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_process_status          := 1;
            p_error_message           := 'No Item cost is available in Oracle For Inv Item' || P_item_id || ' Inventory Org Id  ' || P_organization_id
                                           || ' and Cost type:   ' || p_cost_type  ;
      WHEN OTHERS THEN
            p_process_status          := 1;
            p_error_message           := 'Oracle error ' || substr(SQLERRM, 1, 200);
END;

  ELSE

      p_process_status     := 1; -- operation successful
      p_error_message      := 'Please Provide the PO Number';

  END IF;
END GET_ITEM_COST;




-- Procedure to get the Item On Hand quantity.
-- It will have Inv Item and Organization as a Input Parameter and On-Hand Quantity as a Output paramter.
  PROCEDURE  GET_ITEM_ONHAND_QUANTITY  (
          p_Item_id                  IN  NUMBER
        , p_organization_id          IN  NUMBER
        , p_subinventory_code        IN  VARCHAR2
        , p_locator_id               IN  NUMBER
        , p_onhand_quantity          OUT NUMBER
        , p_process_status           OUT NUMBER
        , p_error_message            OUT VARCHAR2
  )
IS
    --p_error_message   := NULL;
    l_api_return_status VARCHAR2(1);
    l_qty_oh        NUMBER;
    l_qty_res_oh    NUMBER;
    l_qty_res       NUMBER;
    l_qty_sug       NUMBER;
    l_qty_att       NUMBER;
    l_qty_atr       NUMBER;
    l_msg_count     NUMBER;
    l_msg_data      VARCHAR2(1000);
    p_subinv_code   VARCHAR2(10);
    p_loc_id        NUMBER;

BEGIN


IF    p_item_Id                   IS NOT NULL
AND   p_organization_id           IS NOT NULL
THEN

        inv_quantity_tree_grp.clear_quantity_cache;
        p_subinv_code     := p_subinventory_code;
        p_loc_id          := p_locator_id;

      BEGIN
        inv_quantity_tree_pub.query_quantities ( p_api_version_number => 1.0
        , p_init_msg_lst        => apps.fnd_api.g_false
        , x_return_status       => l_api_return_status
        , x_msg_count           => l_msg_count
        , x_msg_data            => l_msg_data
        , p_organization_id     => p_organization_id
        , p_inventory_item_id   => p_Item_id
        , p_tree_mode           => inv_quantity_tree_pub.g_transaction_mode
        , p_onhand_source       => 3
        , p_is_revision_control => FALSE
        , p_is_lot_control      => FALSE
        , p_is_serial_control   => FALSE
        , p_revision            => NULL
        , p_lot_number          => NULL
        , p_subinventory_code   => p_subinv_code
        , p_locator_id          => p_loc_id
        , x_qoh                 => l_qty_oh
        , x_rqoh                => l_qty_res_oh
        , x_qr                  => l_qty_res
        , x_qs                  => l_qty_sug
        , x_att                 => l_qty_att
        , x_atr                 => l_qty_atr );

        P_onhand_quantity         := l_qty_att;
        p_process_status          := 0;
        p_error_message           := NULL;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_process_status          := 1;
            p_error_message           := 'No On-Item quantity is available in Oracle For Inv Item' || P_item_id ||
                                         ' and Inventory Org Id  ' || P_organization_id ;
      WHEN OTHERS THEN
            p_process_status          := 1;
            p_error_message           := 'Oracle error ' || substr(SQLERRM, 1, 200);

      END;

ELSE
        p_error_message               := 'Please Provide Item number and Organization_id  ';

END IF;


END;



-- Procedure to get the Item On hand quantity Orperating Unit basis
--  The Operating Unit will the one of the required paramter.
--  One the basis of the ORG_ID the Procedure will identified the Inventory Org.
--  It will accumulate all the Amount of that Item and give the output.
  PROCEDURE  GET_ITEM_ONHANDQTY_AFFILIT  (
          p_Item_id                  IN  NUMBER
        , p_org_id                   IN  NUMBER
        , P_tot_onhand_qty           OUT NUMBER
        , p_process_status           OUT NUMBER
        , p_error_message            OUT VARCHAR2
  )
IS
    l_api_return_status VARCHAR2(1);
    l_qty_oh        NUMBER;
    l_qty_res_oh    NUMBER;
    l_qty_res       NUMBER;
    l_qty_sug       NUMBER;
    l_qty_att       NUMBER;
    l_qty_atr       NUMBER;
    l_msg_count     NUMBER;
    l_msg_data      VARCHAR2(1000);
    x_rec_count     NUMBER;
    e_orginfo_notfound      EXCEPTION;
    p_onhand_quantity    NUMBER;

        Cursor c_org_id IS
        select organization_id
        from   org_organization_definitions
        where  operating_unit = p_org_id
        and    organization_code NOT LIKE 'IM%';

BEGIN


IF    p_org_id                    IS NOT NULL
AND   p_item_Id                   IS NOT NULL
THEN

        --P_tot_onhand_qty  := 0;
        inv_quantity_tree_grp.clear_quantity_cache;

        FOR  c_org_id_rec IN c_org_id
		LOOP

	          IF c_org_id%ROWCOUNT = 0
	          THEN
	             RAISE e_orginfo_notfound;
	          END IF;

	          EXIT WHEN c_org_id%NOTFOUND;
	          x_rec_count := x_rec_count
	                         + 1;

              BEGIN

                inv_quantity_tree_pub.query_quantities ( p_api_version_number => 1.0
                , p_init_msg_lst        => apps.fnd_api.g_false
                , x_return_status       => l_api_return_status
                , x_msg_count           => l_msg_count
                , x_msg_data            => l_msg_data
                , p_organization_id     => c_org_id_rec.organization_id  --p_organization_id
                , p_inventory_item_id   => p_Item_id
                , p_tree_mode           => inv_quantity_tree_pub.g_transaction_mode
                , p_onhand_source       => 3
                , p_is_revision_control => FALSE
                , p_is_lot_control      => FALSE
                , p_is_serial_control   => FALSE
                , p_revision            => NULL
                , p_lot_number          => NULL
                , p_subinventory_code   => NULL --p_subinv_code
                , p_locator_id          => NULL -- p_loc_id
                , x_qoh                 => l_qty_oh
                , x_rqoh                => l_qty_res_oh
                , x_qr                  => l_qty_res
                , x_qs                  => l_qty_sug
                , x_att                 => l_qty_att
                , x_atr                 => l_qty_atr );

                P_onhand_quantity         := l_qty_att;
                p_process_status          := 0;
                p_error_message           := NULL;

                P_tot_onhand_qty  := nvl(P_tot_onhand_qty,0) + nvl(P_onhand_quantity,0);


              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    p_process_status          := 1;
                    p_error_message           := 'No On-Item quantity is available in Oracle For Inv Item' || P_item_id ||
                                                 ' and  Org Id  ' || p_org_id ;
              WHEN OTHERS THEN
                    p_process_status          := 1;
                    p_error_message           := 'Oracle error ' || substr(SQLERRM, 1, 200);

              END;


            x_rec_count := x_rec_count + 1;

       END LOOP;

        IF P_tot_onhand_qty is NULL then

           p_process_status          := 1;
           p_error_message           := 'No On-Item quantity is available in Oracle For Inv Item' || P_item_id ||
                                                 ' and  Org Id  ' || p_org_id;
        END IF;

ELSE
        p_error_message               := 'Item number and Org Id are mandatory. Please provide them ';

END IF;


END;

END XX_PTP_COMMON_PKG;
/


GRANT EXECUTE ON APPS.XX_PTP_COMMON_PKG TO INTG_XX_NONHR_RO;
