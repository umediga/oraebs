DROP PACKAGE BODY APPS.XX_OE_ORDER_WS_IN_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OE_ORDER_WS_IN_PKG" 
IS
----------------------------------------------------------------------------------
/* $Header: XXOEORDERWSIN.pkb 1.2 2013/05/01 12:00:00 Beda noship $ */
/*
Created By    : IBM Development Team
Creation Date : 04-Apr-2012
File Name     : XXOEORDERWSIN.pkb
Description   : This script creates the body for the Sales Order from SOA

Change History:

Version Date        Name                   Remarks
------- ----------- -------------------    ----------------------
1.0     04-Apr-12   IBM Development Team   Initial development.
1.1     14-Nov-12   IBM Development Team   API fixes and enhancements
1.2     22-May-13   IBM Development Team   Case#002724 Change for N2 Additional Address Name
                                           Case#003548 Changes for RO order type and REF > CO > End cust PO
1.3     18-Oct-13   IBM Development Team   Changes for GHX Mailbox
1.4     05-May-2014 IBM Development Team   Case # 5909 do not pass price list id to api
1.5     02-Jun-2014 IBM Development Team   Case # 006584 check Items with out case sensitivity, check with UPPER()
1.6     19-Jun-2014  Jaya Maran Jayaraj    Case#7587 and 7635 - Including Shipping Method code and Shipping priority code
                                           For Covidien
1.7     28-Oct-2014 Sanjeev                Case#10912-- Added to char to for invalid_number exception raised while selecting
                                           l_seq_num
*/
----------------------------------------------------------------------
   PROCEDURE assign_global_var (
      p_oe_status   OUT   VARCHAR2
    , p_err_msg     OUT   VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 11-APRIL-2012
Filename       :
Description    : Procedure to assign global variables.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
11-Apr-2012   1.0       IBM Technical Team         Initial development.
*/
--------------------------------------------------------------------------------
      CURSOR cur_get_global_var_value (p_parameter IN VARCHAR2)
      IS
         SELECT emfpp.parameter_value
           FROM xx_emf_process_setup emfps
              , xx_emf_process_parameters emfpp
          WHERE emfps.process_id = emfpp.process_id
            AND emfps.process_name = g_process_name
            AND emfpp.parameter_name = p_parameter;

      l_parameter_name    VARCHAR2 (60);
      l_parameter_value   VARCHAR2 (60);
   BEGIN
      --Set SOURCE_NAME
      OPEN cur_get_global_var_value ('ORDER_SOURCE_NAME');

      FETCH cur_get_global_var_value
       INTO l_parameter_value;

      CLOSE cur_get_global_var_value;

      g_order_source_name := l_parameter_value;

      --Set SA_ORDER_TYPE
      OPEN cur_get_global_var_value ('SA_ORDER_TYPE');

      FETCH cur_get_global_var_value
       INTO l_parameter_value;

      CLOSE cur_get_global_var_value;

      g_sa_order_type := l_parameter_value;

      --Set CN_ORDER_TYPE -- Addition for GHX
      OPEN cur_get_global_var_value ('CN_ORDER_TYPE');

      FETCH cur_get_global_var_value
       INTO l_parameter_value;

      CLOSE cur_get_global_var_value;

      g_cn_order_type := l_parameter_value;

      --Set RO_SHIP_PRIORITY_CODE -- Addition for GHX
      OPEN cur_get_global_var_value ('RO_SHIP_PRIORITY_CODE');

      FETCH cur_get_global_var_value
       INTO l_parameter_value;

      CLOSE cur_get_global_var_value;

      g_ro_ship_priority_code := l_parameter_value;

      --Set G_OVERNIGHT_SHIP_METHOD-- Addition for GHX
      OPEN cur_get_global_var_value ('OVERNIGHT_SHIP_METHOD');

      FETCH cur_get_global_var_value
       INTO l_parameter_value;

      CLOSE cur_get_global_var_value;

      g_overnight_ship_method := l_parameter_value;



      --Set SA_ORGANIZATION_CODE
      OPEN cur_get_global_var_value ('SA_ORGANIZATION_CODE');

      FETCH cur_get_global_var_value
       INTO l_parameter_value;

      CLOSE cur_get_global_var_value;

      g_sa_organization_code := l_parameter_value;

       --Set INT_ORDER_TYPE
      /* OPEN cur_get_global_var_value('INT_ORDER_TYPE');
       FETCH cur_get_global_var_value
         INTO l_parameter_value;
       CLOSE cur_get_global_var_value;
       G_INT_ORDER_TYPE := l_parameter_value;
       --Set INT_ORGANIZATION_CODE
       OPEN cur_get_global_var_value('INT_ORGANIZATION_CODE');
       FETCH cur_get_global_var_value
         INTO l_parameter_value;
       CLOSE cur_get_global_var_value;
       G_INT_ORGANIZATION_CODE := l_parameter_value;*/
       --Set CREATED_BY_MODULE
      OPEN cur_get_global_var_value ('CREATED_BY_MODULE');

      FETCH cur_get_global_var_value
       INTO l_parameter_value;

      CLOSE cur_get_global_var_value;

      g_created_by_module := l_parameter_value;

      --GHX file type
      OPEN cur_get_global_var_value ('GHX_FILE_TYPE');

      FETCH cur_get_global_var_value
       INTO l_parameter_value;

      CLOSE cur_get_global_var_value;

      g_ghx_file_type := l_parameter_value;

      --GXS file type
      OPEN cur_get_global_var_value ('GXS_FILE_TYPE');

      FETCH cur_get_global_var_value
       INTO l_parameter_value;

      CLOSE cur_get_global_var_value;

      g_gxs_file_type := l_parameter_value;

      --GHX Reference ID
      OPEN cur_get_global_var_value ('GHX_REF_ID');

      FETCH cur_get_global_var_value
       INTO l_parameter_value;

      CLOSE cur_get_global_var_value;

      g_ghx_ref_id := l_parameter_value;

      OPEN cur_get_global_var_value ('HDR_TP_CONTEXT');

      FETCH cur_get_global_var_value
       INTO l_parameter_value;

      CLOSE cur_get_global_var_value;

      g_hdr_tp_context := l_parameter_value;

      OPEN cur_get_global_var_value ('SALES_CHANNEL');

      FETCH cur_get_global_var_value
       INTO l_parameter_value;

      CLOSE cur_get_global_var_value;

      g_sales_channel := l_parameter_value;

      OPEN cur_get_global_var_value ('TP_CONTEXT');

      FETCH cur_get_global_var_value
       INTO l_parameter_value;

      CLOSE cur_get_global_var_value;

      g_tp_context := l_parameter_value;

      OPEN cur_get_global_var_value ('ISA_NO');

      FETCH cur_get_global_var_value
       INTO l_parameter_value;

      CLOSE cur_get_global_var_value;

      g_isa_no := l_parameter_value;

      OPEN cur_get_global_var_value ('GHX_EDIINVALID_ITEM');

      FETCH cur_get_global_var_value
       INTO l_parameter_value;

      CLOSE cur_get_global_var_value;

      g_ghx_ediinvalid_item := l_parameter_value;

      IF    g_order_source_name IS NULL
         OR g_sa_order_type IS NULL
         OR g_cn_order_type IS NULL
         OR g_ro_ship_priority_code IS NULL
         OR g_sa_organization_code IS NULL
         ---- OR G_INT_ORDER_TYPE IS NULL OR G_INT_ORGANIZATION_CODE IS NULL
         OR g_created_by_module IS NULL
         OR g_ghx_file_type IS NULL
         OR g_gxs_file_type IS NULL
         OR g_ghx_ref_id IS NULL
         OR g_sales_channel IS NULL
         OR g_tp_context IS NULL
         OR g_isa_no IS NULL
         OR g_ghx_ediinvalid_item IS NULL
      THEN
         p_oe_status := g_failed_msg;
         p_err_msg := 'Unable to assign Global Variables';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_oe_status := g_failed_msg;
         p_err_msg := 'Unable to assign Global Variables' || SQLERRM;
   END assign_global_var;

--********************************************************************************************
   PROCEDURE xx_oe_insert (
      p_header      IN       xx_oe_order_hdr_ws_in_typ
    , p_line        IN       xx_oe_order_line_ws_in_tabtyp
    , p_header_id   OUT      NUMBER
    , p_err_msg     OUT      VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 11-APRIL-2012
Filename       :
Description    : Procedure to insert sales order header and line level information into staging tables.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
11-Apr-2012   1.0       IBM Technical Team         Initial development.
01-May-2013   1.1       IBM Technical Team         Added new columns for GHX
*/
--------------------------------------------------------------------------------
      l_orig_sys_ref   VARCHAR2 (100) := '';
      p_oe_status      VARCHAR2 (100);
      p_error_msg      VARCHAR2 (400);
   BEGIN
      ------Assign Global Variables---
      assign_global_var (p_oe_status, p_error_msg);

      --File Type check
      IF (p_header.attribute1 = g_ghx_file_type)
      THEN
         IF (p_header.ref_id_qualifier = g_ghx_ref_id)
         THEN
            l_orig_sys_ref := p_header.ref_identification;
        /* ELSE -- Commented out for GHX
            l_orig_sys_ref :=
                  g_ghx_file_type
               || '.'
               || p_header.beg_po_number
               || '.'
               || TRIM (p_header.beg_po_date); */
         END IF;
      ELSIF (p_header.attribute1 != g_ghx_file_type)
      THEN
         l_orig_sys_ref :=
               g_gxs_file_type
            || '.'
            || p_header.beg_po_number
            || '.'
            || TRIM (p_header.beg_po_date);
      END IF;

      INSERT INTO xx_oe_order_ws_in_header_stg
                  (header_id
                 , st_trans_set_id
                 , st_trans_control_no
                 , beg_trans_set_code
                 , beg_po_type_code
                 , beg_po_number
                 , beg_po_rls_no
                 , beg_po_date
                 , ref_id_qualifier
                 , ref_identification
                 , ref_description
                 , dtm_qualifier
                 , dtm_date
                 , td5_trans_mthd_type
                 , td5_origin_cr
                 , n1_ship_to_id
                 , n1_ship_to_name
                 , n1_ship_to_id_code_qlf
                 , n1_ship_to_id_code
                 , n1_bill_to_id
                 , n1_bill_to_name
                 , n1_bill_to_id_code_qlf
                 , n1_bill_to_id_code
                 , n1_so_id
                 , n1_so_name
                 , n1_so_id_code_qlf
                 , n1_so_id_code
                 , n1_attribute1_id
                 , n1_attribute1_name
                 , n1_attribute1_id_code_qlf
                 , n1_attribute1_id_code
                 , n1_attribute2_id
                 , n1_attribute2_name
                 , n1_attribute2_id_code_qlf
                 , n1_attribute2_id_code
                 , n2_additional_name
                 , n3_address1
                 , n3_address2
                 , n4_city
                 , n4_state
                 , n4_postal_code
                 , n9_ref_id_qualifier
                 , n9_ref_identification
                 , per_contact_function_code
                 , per_buyer_name
                 , per_communication_id
                 , per_communication_no
                 , ctt_line_item_no
                 , ctt_hash_total
                 , se_segment_count
                 , se_trans_control_no
                 , creation_date
                 , instance_id
                 , status
                 , error_mssg
                 , attribute1
                 , attribute2
                 , attribute3
                 , attribute4
                 , attribute5
                 , n4_country
                 , n2_bt_additional_name
                 , n3_bt_address1
                 , n3_bt_address2
                 , n4_bt_city
                 , n4_bt_state
                 , n4_bt_postal_code
                 , n4_bt_country
                 , td5_routing_seq
                 , td5_carrier_id_code_qlf
                 , td5_carrier_id_code
                 , td5_service_level_code
                 , n9_ref_description
                 , msg_message
                 , attribute6
                 , attribute7
                 , attribute8
                 , attribute9
                 , attribute10
                 , attribute11
                 , attribute12
                 , attribute13
                 , attribute14
                 , attribute15
                 , bt_site_number
                 , shipping_method_type --added in version 1.6
                 , shipment_priority_code --added in version 1.6
                  )
           VALUES (xx_oe_order_ws_in_header_id_s.NEXTVAL
                 , p_header.st_trans_set_id
                 , p_header.st_trans_control_no
                 , p_header.beg_trans_set_code
                 , p_header.beg_po_type_code
                 , p_header.beg_po_number
                 , p_header.beg_po_rls_no
                 , TRIM (p_header.beg_po_date)
                 , p_header.ref_id_qualifier
                 , p_header.ref_identification
                 , p_header.ref_description
                 , p_header.dtm_qualifier
                 , TRIM (p_header.dtm_date)
                 , p_header.td5_trans_mthd_type
                 , p_header.td5_origin_cr
                 , p_header.n1_ship_to_id
                 , p_header.n1_ship_to_name
                 , p_header.n1_ship_to_id_code_qlf
                 , p_header.n1_ship_to_id_code
                 , p_header.n1_bill_to_id
                 , p_header.n1_bill_to_name
                 , p_header.n1_bill_to_id_code_qlf
                 , p_header.n1_bill_to_id_code
                 , p_header.n1_so_id
                 , p_header.n1_so_name
                 , p_header.n1_so_id_code_qlf
                 , p_header.n1_so_id_code
                 , p_header.n1_attribute1_id
                 , p_header.n1_attribute1_name
                 , p_header.n1_attribute1_id_code_qlf
                 , p_header.n1_attribute1_id_code
                 , p_header.n1_attribute2_id
                 , p_header.n1_attribute2_name
                 , p_header.n1_attribute2_id_code_qlf
                 , p_header.n1_attribute2_id_code
                 , p_header.n2_additional_name
                 , p_header.n3_address1
                 , p_header.n3_address2
                 , p_header.n4_city
                 , p_header.n4_state
                 , p_header.n4_postal_code
                 , p_header.n9_ref_id_qualifier
                 , p_header.n9_ref_identification
                 , p_header.per_contact_function_code
                 , p_header.per_buyer_name
                 , p_header.per_communication_id
                 , p_header.per_communication_no
                 , p_header.ctt_line_item_no
                 , p_header.ctt_hash_total
                 , p_header.se_segment_count
                 , p_header.se_trans_control_no
                 , SYSDATE
                 , p_header.instance_id
                 , p_header.status
                 , p_header.error_mssg
                 , p_header.attribute1
                 , p_header.attribute2
                 , p_header.attribute3
                 , l_orig_sys_ref
                 , p_header.attribute5
                 , p_header.n4_country
                 , p_header.n2_bt_additional_name
                 , p_header.n3_bt_address1
                 , p_header.n3_bt_address2
                 , p_header.n4_bt_city
                 , p_header.n4_bt_state
                 , p_header.n4_bt_postal_code
                 , p_header.n4_bt_country
                 , p_header.td5_routing_seq
                 , p_header.td5_carrier_id_code_qlf
                 , p_header.td5_carrier_id_code
                 , p_header.td5_service_level_code
                 , p_header.n9_ref_description
                 , p_header.msg_message
                 , p_header.attribute6
                 , p_header.attribute7
                 , p_header.attribute8
                 , p_header.attribute9
                 , p_header.attribute10
                 , p_header.attribute11
                 , p_header.attribute12
                 , p_header.attribute13
                 , p_header.attribute14
                 , p_header.attribute15
                 , p_header.bt_site_number
                 , p_header.shipping_method_type --added in version 1.6
                 , p_header.shipment_priority_code --added in version 1.6
                  );

      p_header_id := xx_oe_order_ws_in_header_id_s.CURRVAL;

      IF p_line.COUNT () <> 0
      THEN
         FOR i IN p_line.FIRST .. p_line.LAST
         LOOP
            INSERT INTO xx_oe_order_ws_in_line_stg
                        (header_id
                       , line_id
                       , po1_line_no
                       , po1_quantity
                       , po1_uom
                       , po1_unit_price
                       , po1_basis_unit_price_code
                       , po1_prod_id_code1
                       , po1_prod_id_code1_val
                       , po1_prod_id_code2
                       , po1_prod_id_code2_val
                       , po1_prod_id_code3
                       , po1_prod_id_code3_val
                       , pid_type
                       , pid_description
                       , ref_identifier
                       , ref_identification
                       , ref_description
                       , status
                       , error_mssg
                       , attribute1
                       , attribute2
                       , attribute3
                       , attribute4
                       , attribute5
                        )
                 VALUES (p_header_id
                       , xx_oe_order_ws_in_line_id_s.NEXTVAL
                       , p_line (i).po1_line_no
                       , p_line (i).po1_quantity
                       , p_line (i).po1_uom
                       , p_line (i).po1_unit_price
                       , p_line (i).po1_basis_unit_price_code
                       , p_line (i).po1_prod_id_code1
                       , p_line (i).po1_prod_id_code1_val
                       , p_line (i).po1_prod_id_code2
                       , p_line (i).po1_prod_id_code2_val
                       , p_line (i).po1_prod_id_code3
                       , p_line (i).po1_prod_id_code3_val
                       , p_line (i).pid_type
                       , p_line (i).pid_description
                       , p_line (i).ref_identifier
                       , p_line (i).ref_identification
                       , p_line (i).ref_description
                       , p_line (i).status
                       , p_line (i).error_mssg
                       , p_line (i).attribute1
                       , p_line (i).attribute2
                       , p_line (i).attribute3
                       , l_orig_sys_ref
                       , p_line (i).attribute5
                        );
         END LOOP;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_err_msg := 'Exception in the time of inserting data: ' || SQLERRM;
   END xx_oe_insert;

--********************************************************************************************
   PROCEDURE xx_oe_fetch (
      p_header_id   IN       NUMBER
    , p_header      OUT      xx_oe_order_hdr_ws_in_typ
    , p_line        OUT      xx_oe_order_line_ws_in_tabtyp
    , p_err_msg     OUT      VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 11-APRIL-2012
Filename       :
Description    : Procedure to fetch sales order header and line level information from staging tables.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
11-Apr-2012   1.0       IBM Technical Team         Initial development.
24-Oct-2012   1.1       IBM Technical Team         Modified to handle Discarded Lines.
01-May-2013   1.2       IBM Technical Team         Modified to handle additional columns for GHX
*/
--------------------------------------------------------------------------------
      CURSOR c_line_fetch
      IS
         SELECT xx_oe_order_line_ws_in_typ (header_id
                                          , line_id
                                          , po1_line_no
                                          , po1_quantity
                                          , po1_uom
                                          , po1_unit_price
                                          , po1_basis_unit_price_code
                                          , po1_prod_id_code1
                                          , po1_prod_id_code1_val
                                          , po1_prod_id_code2
                                          , po1_prod_id_code2_val
                                          , po1_prod_id_code3
                                          , po1_prod_id_code3_val
                                          , pid_type
                                          , pid_description
                                          , ref_identifier
                                          , ref_identification
                                          , ref_description
                                          , status
                                          , error_mssg
                                          , attribute1
                                          , attribute2
                                          , attribute3
                                          , attribute4
                                          , attribute5
                                           )
           FROM xx_oe_order_ws_in_line_stg
          WHERE header_id = p_header_id
            AND NVL (status, 'Success') <> 'Discarded';
   -- Modified on 24Oct2012 to handle Discarded Orders.
   BEGIN
      p_header :=
         xx_oe_order_hdr_ws_in_typ (NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                  , NULL
                                   );

      SELECT header_id
           , st_trans_set_id
           , st_trans_control_no
           , beg_trans_set_code
           , beg_po_type_code
           , beg_po_number
           , beg_po_rls_no
           , beg_po_date
           , ref_id_qualifier
           , ref_identification
           , ref_description
           , dtm_qualifier
           , dtm_date
           , td5_trans_mthd_type
           , td5_origin_cr
           , n1_ship_to_id
           , n1_ship_to_name
           , n1_ship_to_id_code_qlf
           , n1_ship_to_id_code
           , n1_bill_to_id
           , n1_bill_to_name
           , n1_bill_to_id_code_qlf
           , n1_bill_to_id_code
           , n1_so_id
           , n1_so_name
           , n1_so_id_code_qlf
           , n1_so_id_code
           , n1_attribute1_id
           , n1_attribute1_name
           , n1_attribute1_id_code_qlf
           , n1_attribute1_id_code
           , n1_attribute2_id
           , n1_attribute2_name
           , n1_attribute2_id_code_qlf
           , n1_attribute2_id_code
           , n2_additional_name
           , n3_address1
           , n3_address2
           , n4_city
           , n4_state
           , n4_postal_code
           , n9_ref_id_qualifier
           , n9_ref_identification
           , per_contact_function_code
           , per_buyer_name
           , per_communication_id
           , per_communication_no
           , ctt_line_item_no
           , ctt_hash_total
           , se_segment_count
           , se_trans_control_no
           , creation_date
           , instance_id
           , status
           , error_mssg
           , attribute1
           , attribute2
           , attribute3
           , attribute4
           , attribute5
           , n4_country
           , n2_bt_additional_name
           , n3_bt_address1
           , n3_bt_address2
           , n4_bt_city
           , n4_bt_state
           , n4_bt_postal_code
           , n4_bt_country
           , td5_routing_seq
           , td5_carrier_id_code_qlf
           , td5_carrier_id_code
           , td5_service_level_code
           , n9_ref_description
           , msg_message
           , attribute6
           , attribute7
           , attribute8
           , attribute9
           , attribute10
           , attribute11
           , attribute12
           , attribute13
           , attribute14
           , attribute15
           , bt_site_number
           , shipping_method_type --added in version 1.6
           , shipment_priority_code --added in version 1.6
        INTO p_header.header_id
           , p_header.st_trans_set_id
           , p_header.st_trans_control_no
           , p_header.beg_trans_set_code
           , p_header.beg_po_type_code
           , p_header.beg_po_number
           , p_header.beg_po_rls_no
           , p_header.beg_po_date
           , p_header.ref_id_qualifier
           , p_header.ref_identification
           , p_header.ref_description
           , p_header.dtm_qualifier
           , p_header.dtm_date
           , p_header.td5_trans_mthd_type
           , p_header.td5_origin_cr
           , p_header.n1_ship_to_id
           , p_header.n1_ship_to_name
           , p_header.n1_ship_to_id_code_qlf
           , p_header.n1_ship_to_id_code
           , p_header.n1_bill_to_id
           , p_header.n1_bill_to_name
           , p_header.n1_bill_to_id_code_qlf
           , p_header.n1_bill_to_id_code
           , p_header.n1_so_id
           , p_header.n1_so_name
           , p_header.n1_so_id_code_qlf
           , p_header.n1_so_id_code
           , p_header.n1_attribute1_id
           , p_header.n1_attribute1_name
           , p_header.n1_attribute1_id_code_qlf
           , p_header.n1_attribute1_id_code
           , p_header.n1_attribute2_id
           , p_header.n1_attribute2_name
           , p_header.n1_attribute2_id_code_qlf
           , p_header.n1_attribute2_id_code
           , p_header.n2_additional_name
           , p_header.n3_address1
           , p_header.n3_address2
           , p_header.n4_city
           , p_header.n4_state
           , p_header.n4_postal_code
           , p_header.n9_ref_id_qualifier
           , p_header.n9_ref_identification
           , p_header.per_contact_function_code
           , p_header.per_buyer_name
           , p_header.per_communication_id
           , p_header.per_communication_no
           , p_header.ctt_line_item_no
           , p_header.ctt_hash_total
           , p_header.se_segment_count
           , p_header.se_trans_control_no
           , p_header.creation_date
           , p_header.instance_id
           , p_header.status
           , p_header.error_mssg
           , p_header.attribute1
           , p_header.attribute2
           , p_header.attribute3
           , p_header.attribute4
           , p_header.attribute5
           , p_header.n4_country
           , p_header.n2_bt_additional_name
           , p_header.n3_bt_address1
           , p_header.n3_bt_address2
           , p_header.n4_bt_city
           , p_header.n4_bt_state
           , p_header.n4_bt_postal_code
           , p_header.n4_bt_country
           , p_header.td5_routing_seq
           , p_header.td5_carrier_id_code_qlf
           , p_header.td5_carrier_id_code
           , p_header.td5_service_level_code
           , p_header.n9_ref_description
           , p_header.msg_message
           , p_header.attribute6
           , p_header.attribute7
           , p_header.attribute8
           , p_header.attribute9
           , p_header.attribute10
           , p_header.attribute11
           , p_header.attribute12
           , p_header.attribute13
           , p_header.attribute14
           , p_header.attribute15
           , p_header.bt_site_number
           , p_header.shipping_method_type --added in version 1.6
           , p_header.shipment_priority_code --added in version 1.6
        FROM xx_oe_order_ws_in_header_stg
       WHERE header_id = p_header_id;

      OPEN c_line_fetch;

      LOOP
         FETCH c_line_fetch
         BULK COLLECT INTO p_line;

         EXIT WHEN c_line_fetch%NOTFOUND;
      END LOOP;

      IF c_line_fetch%ISOPEN
      THEN
         CLOSE c_line_fetch;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_err_msg :=
            p_err_msg || 'Exception in the time of fetching data: '
            || SQLERRM;
   END xx_oe_fetch;

--********************************************************************************************

   --********************************************************************************************
   PROCEDURE get_customer_dtls (
      p_translated_customer_name    IN       VARCHAR2
    , p_edi_loc_code                IN       VARCHAR2
    , p_order_type                  IN       VARCHAR2
    , p_file_type                   IN       VARCHAR2
    , p_state                       IN       VARCHAR2 DEFAULT NULL
    , p_bill_to_customer_number     IN       VARCHAR2 DEFAULT NULL
    , p_bill_to_site_number         IN       VARCHAR2 DEFAULT NULL
    , p_header_id                   IN       NUMBER
    , p_sold_to_org                 OUT      hz_cust_accounts.account_number%TYPE
    , p_sold_to_org_id              OUT      hz_cust_accounts.cust_account_id%TYPE
    , p_party_id                    OUT      hz_parties.party_id%TYPE
    , p_ship_to_site_id             OUT      hz_cust_site_uses_all.site_use_id%TYPE
    , p_ship_to_cust_acct_site_id   OUT      hz_cust_site_uses_all.cust_acct_site_id%TYPE
    , p_country                     IN OUT   hz_locations.country%TYPE
    , p_payment_term_id             OUT      hz_cust_site_uses_all.payment_term_id%TYPE
    , p_bill_to_site_id             OUT      hz_cust_site_uses_all.site_use_id%TYPE
    , p_coc                         OUT      hz_cust_acct_sites_all.attribute10%TYPE
    , p_oe_status                   OUT      VARCHAR2
    , p_err_msg                     OUT      VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
   /*
   Created By     : IBM Technical Team
   Creation Date  : 11-APRIL-2012
   Filename       :
   Description    : Procedure to fetch customer details.

   Change History:

   Date        Version#    Name                  Remarks
   ----------- --------    ---------------      -----------------------------------
   11-Apr-2012   1.0       IBM Technical Team   Initial development.
   31-May-2012   1.1       IBM Technical Team   Modified logic for Payment terms and
                                            bill to customer from Account Relationship
   17-Aug-2012   1.2       IBM Technical Team   Added Certificate Of Conformance
   10-Oct-2012   1.3       IBM Technical Team   Added as per DCR#100912
   20-Oct-2013   1.4       IBM Technical Team   Added Logic for GHX
   */
   --------------------------------------------------------------------------------
      l_sold_to_org                 hz_cust_accounts.account_number%TYPE;
      l_sold_to_org_id              hz_cust_accounts.cust_account_id%TYPE;
      l_party_id                    hz_parties.party_id%TYPE;
      l_ship_to_site_id             hz_cust_site_uses_all.site_use_id%TYPE;
      l_ship_to_cust_acct_site_id   hz_cust_site_uses_all.cust_acct_site_id%TYPE;
      l_country                     hz_locations.country%TYPE;
      l_payment_term_id             hz_cust_site_uses_all.payment_term_id%TYPE;
      l_bill_to_site_id             hz_cust_site_uses_all.site_use_id%TYPE;
      l_relation_acc_num            hz_cust_accounts.account_number%TYPE;
      l_relation_acc_id             hz_cust_accounts.cust_account_id%TYPE;
      l_bill_to_count               NUMBER;
      l_edi_cnt                     NUMBER;
      l_bill_cnt                    NUMBER;
      l_rel_count                   NUMBER;
      l_edi_loc_code                fnd_lookup_values.lookup_code%TYPE;
      l_account_number              hz_cust_accounts.account_number%TYPE;
      l_coc                         hz_cust_acct_sites_all.attribute10%TYPE;
      e_missing_cust_setup          EXCEPTION;
      e_missing_state               EXCEPTION;
      e_missing_bill_to             EXCEPTION;
      e_missing_payment_term        EXCEPTION;
      p_err_msg_cust_setup          VARCHAR2 (3500);
      p_err_msg_state               VARCHAR2 (3500);
      p_err_msg_bill_to             VARCHAR2 (3500);
      p_err_msg_payment_term        VARCHAR2 (3500);
      l_bt_edi_loc_code             VARCHAR2 (240);
   BEGIN
      --Code modification(2012-05-31) to fetch Bill to and payment terms from Account Relationship

    IF p_file_type = g_gxs_file_type THEN
      ---EDI location null for Henry Schein-------
      IF (p_order_type = 'DS') AND (p_translated_customer_name = g_isa_no)
      THEN
         BEGIN
            SELECT meaning
              INTO l_account_number
              FROM fnd_lookup_values
             WHERE lookup_type = 'INTG_EDI_DROPSHIP_ACCOUNT'
               AND lookup_code = p_translated_customer_name
               AND enabled_flag = 'Y'
               AND LANGUAGE = USERENV ('LANG');
         EXCEPTION
            WHEN OTHERS
            THEN
               p_oe_status := g_failed_msg;
               xx_oe_error_insert
                   (p_header_id
                  , NULL
                  , 'Header Level Validation'
                  ,    'DropShip Account is not setup in lookup. Exception: '
                    || SQLERRM
                   );
         END;

         ------------Derive Sold-To, Ship-To, Bill-To details for Henry Schein----
         BEGIN
            SELECT hca.account_number
                 , hca.cust_account_id
                 , hca.party_id
                 , hcsu.site_use_id
                 , rt.term_id
                 ,
                   --hcsu.payment_term_id,  -- Modified Payment term from Account Level
                   hcsu1.site_use_id
                 , hcsu1.cust_acct_site_id
                 , hcas.attribute10
              ----Added Certificate Of Conformance ------
            INTO   l_sold_to_org
                 , l_sold_to_org_id
                 , l_party_id
                 , l_bill_to_site_id
                 , l_payment_term_id
                 , l_ship_to_site_id
                 , l_ship_to_cust_acct_site_id
                 , l_coc           ----Added Certificate Of Conformance ------
              FROM hz_cust_accounts hca
                 , hz_cust_acct_sites_all hcas
                 , hz_cust_site_uses_all hcsu
                 , hz_cust_site_uses_all hcsu1
                 , hz_customer_profiles hcp
                 ,                 -- Modified Payment term from Account Level
                   ra_terms rt     -- Modified Payment term from Account Level
             WHERE hca.cust_account_id = hcas.cust_account_id
               AND hcp.cust_account_id(+) = hca.cust_account_id
               -- Modified Payment term from Account Level
               AND hcp.site_use_id IS NULL
               -- Modified Payment term from Account Level
               AND hcp.standard_terms = rt.term_id(+)
               -- Modified Payment term from Account Level
               AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
               AND hcas.cust_acct_site_id = hcsu1.cust_acct_site_id
               AND hcsu.site_use_code = 'BILL_TO'
               AND hcsu1.site_use_code = 'SHIP_TO'
               AND hcsu.status = 'A'
               AND hcsu1.status = 'A'
               AND hcas.status = 'A'
               AND hca.status = 'A'
               AND hcsu.primary_flag = 'Y'
               AND hca.account_number = l_account_number;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_oe_status := g_failed_msg;
               xx_oe_error_insert
                         (p_header_id
                        , NULL
                        , 'Header Level Validation'
                        ,    'Bill To , Ship To Sites not setup. Exception: '
                          || SQLERRM
                         );
         END;
      ELSE
         ----Check EDI location exist in customer master---
         BEGIN
            SELECT COUNT (1)
              INTO l_edi_cnt
              FROM hz_cust_acct_sites_all
             --WHERE  ece_tp_location_code =p_edi_loc_code;---Commented as per DCR#100912
            WHERE  attribute5 = p_edi_loc_code;     ---Added as per DCR#100912

            IF l_edi_cnt > 0
            THEN
               l_edi_loc_code := p_edi_loc_code;
            ELSE                                      ---IF l_edi_cnt > 0 THEN
               BEGIN
                  SELECT TRIM (description)
                    --lookup_code  -- Lookup Modified to hold many to one relationship
                  INTO   l_edi_loc_code
                    FROM fnd_lookup_values
                   WHERE lookup_type = 'INTG_850_ADDRESS'
                     AND LANGUAGE = USERENV ('LANG')
                     AND enabled_flag = 'Y'
                     AND tag = p_translated_customer_name
                     AND meaning = p_edi_loc_code;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_oe_status := g_failed_msg;
                     xx_oe_error_insert
                        (p_header_id
                       , NULL
                       , 'Header Level Validation'
                       ,    'Same EDI location is not setup in lookup. Exception: '
                         || SQLERRM
                        );
               END;
            END IF;                                  ----IF l_edi_cnt > 0 THEN
         END;

         --Derive Sold-To, Ship-To, Bill-To (Linked) details
         BEGIN
            SELECT hca.account_number
                 , hca.cust_account_id
                 , hca.party_id
                 , hsu.site_use_id
                 , hsu.cust_acct_site_id
                 , hzl.country
                 , hcs.attribute10 ----Added Certificate Of Conformance ------
                 /*,(SELECT hsu1.payment_term_id
                    FROM hz_cust_site_uses_all hsu1
                   WHERE hsu1.site_use_code = 'BILL_TO'
                     AND hsu1.primary_flag = 'Y'
                     AND hsu1.cust_acct_site_id = hsu.cust_acct_site_id) payment_term_id,
                 (SELECT hsu1.site_use_id
                    FROM hz_cust_site_uses_all hsu1
                   WHERE hsu1.site_use_code = 'BILL_TO'
                     AND hsu1.primary_flag = 'Y'
                     AND hsu1.cust_acct_site_id = hsu.cust_acct_site_id) bill_to_site_use_id */ -- commented out
            ,      bill_to_site_use_id
              -- added on 2012-Nov-16 to have site level bill to logic indluded
            INTO   l_sold_to_org
                 , l_sold_to_org_id
                 , l_party_id
                 , l_ship_to_site_id
                 , l_ship_to_cust_acct_site_id
                 , l_country
                 , l_coc           ----Added Certificate Of Conformance ------
                 /*,l_payment_term_id,
                 l_bill_to_site_id */ -- commented out
            ,      l_bill_to_site_id
              FROM hz_parties hp
                 , hz_party_sites hps
                 , hz_cust_accounts hca
                 , hz_cust_acct_sites_all hcs
                 , hz_cust_site_uses_all hsu
                 , hz_locations hzl
             WHERE hp.party_id = hps.party_id
               AND hps.party_id = hca.party_id
               AND hca.cust_account_id = hcs.cust_account_id
               AND hcs.party_site_id = hps.party_site_id
               AND hps.location_id = hzl.location_id
               AND hcs.cust_acct_site_id = hsu.cust_acct_site_id
               AND hca.status = 'A'
               AND hsu.status = 'A'
               AND hcs.status = 'A'
               AND hsu.site_use_code = 'SHIP_TO'
               --AND hcs.ece_tp_location_code = l_edi_loc_code----Commented as per DCR#100912
               --AND hcs.translated_customer_name = p_translated_customer_name;---Commented as per DCR#100912
               AND hcs.attribute5 = l_edi_loc_code ----Added as per DCR#100912
               AND hcs.attribute4 = p_translated_customer_name;
         ----Added as per DCR#100912
         EXCEPTION
            WHEN OTHERS
            THEN
               p_oe_status := g_failed_msg;
               xx_oe_error_insert
                  (p_header_id
                 , NULL
                 , 'Header Level Validation'
                 ,    'EDI Location Code/Translated Customer Name not setup. Exception: '
                   || SUBSTR (SQLERRM, 1, 3500)
                  );
         END;

         -- added on 2012-Nov-16 to have site level bill to logic indluded
         IF l_bill_to_site_id IS NOT NULL
         THEN
            --Addition of logic to fetch Payment Terms for Customer Account
            BEGIN
               SELECT rt.term_id
                 INTO l_payment_term_id
                 FROM hz_cust_accounts hca
                    , hz_cust_acct_sites_all hcas
                    , hz_cust_site_uses_all hcsu
                    , ra_terms rt
                    , hz_customer_profiles hcp
                WHERE hca.cust_account_id = hcas.cust_account_id
                  AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
                  AND hcsu.site_use_code = 'BILL_TO'
                  AND hcsu.status = 'A'
                  AND hcas.status = 'A'
                  AND hca.status = 'A'
                  AND hcp.status = 'A'
                  AND hcsu.primary_flag = 'Y'
                  AND hcp.cust_account_id(+) = hca.cust_account_id
                  AND hcp.site_use_id IS NULL
                  AND hcp.standard_terms = rt.term_id(+)
                  AND hcsu.site_use_id = l_bill_to_site_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_oe_status := g_failed_msg;
                  xx_oe_error_insert
                     (p_header_id
                    , NULL
                    , 'Header Level Validation'
                    ,    'Payment Term is Not setup for Bill To Account Properly. Exception: '
                      || SUBSTR (SQLERRM, 1, 3500)
                     );
            END;
         ELSE
            --------Checking count of Relationship Account----
            BEGIN
               SELECT COUNT (hca1.account_number)
                 INTO l_rel_count
                 FROM hz_cust_accounts hca1
                    , hz_cust_acct_relate_all hcar
                    , hz_customer_profiles hcp
                    , ra_terms rt
                WHERE hcp.standard_terms = rt.term_id(+)
                  AND hcp.cust_account_id(+) = hca1.cust_account_id
                  AND hcp.site_use_id IS NULL
                  AND hca1.status = 'A'
                  AND hcar.status = 'A'
                  AND hca1.status = 'A'
                  AND hcar.cust_account_id = hca1.cust_account_id
                  AND hcar.cust_account_id = l_sold_to_org_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_oe_status := g_failed_msg;
                  xx_oe_error_insert
                     (p_header_id
                    , NULL
                    , 'Header Level Validation'
                    ,    'Exception while checkinh Account Relationship count. Exception: '
                      || SUBSTR (SQLERRM, 1, 3500)
                     );
            END;

            IF (l_rel_count = 0) OR (l_rel_count > 1)
            THEN
               BEGIN
                  SELECT hcsu.site_use_id
                    INTO l_bill_to_site_id
                    FROM hz_cust_accounts hca
                       , hz_cust_acct_sites_all hcas
                       , hz_cust_site_uses_all hcsu
                   WHERE hca.cust_account_id = hcas.cust_account_id
                     AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
                     AND hcsu.site_use_code = 'BILL_TO'
                     AND hcsu.status = 'A'
                     AND hcas.status = 'A'
                     AND hca.status = 'A'
                     AND hcsu.primary_flag = 'Y'
                     AND hca.cust_account_id = l_sold_to_org_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_oe_status := g_failed_msg;
                     xx_oe_error_insert
                            (p_header_id
                           , NULL
                           , 'Header Level Validation'
                           ,    'Bill To Site not exist for Customer Account'
                             || l_sold_to_org
                            );
               END;

               --Addition of logic to fetch Payment Terms for Customer Account
               BEGIN
                  SELECT hca1.account_number
                       , hca1.cust_account_id
                       , rt.term_id
                    INTO l_relation_acc_num
                       , l_relation_acc_id
                       , l_payment_term_id
                    FROM hz_cust_accounts hca1
                       , hz_customer_profiles hcp
                       , ra_terms rt
                   WHERE hcp.standard_terms = rt.term_id(+)
                     AND hcp.cust_account_id(+) = hca1.cust_account_id
                     AND hcp.site_use_id IS NULL
                     AND hca1.status = 'A'
                     AND hcp.status = 'A'
                     AND hca1.cust_account_id = l_sold_to_org_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_oe_status := g_failed_msg;
                     xx_oe_error_insert
                        (p_header_id
                       , NULL
                       , 'Header Level Validation'
                       ,    'Payment Term is Not setup for this Account Properly. Exception: '
                         || SUBSTR (SQLERRM, 1, 3500)
                        );
               END;
            ELSE                   ----IF l_rel_count= 0 or l_rel_count>1 THEN
               --Addition of logic to fetch Payment Terms from Account Relationship
               BEGIN
                  SELECT hca1.account_number
                       , hca1.cust_account_id
                       , rt.term_id
                    INTO l_relation_acc_num
                       , l_relation_acc_id
                       , l_payment_term_id
                    FROM hz_cust_accounts hca1
                       , hz_cust_acct_relate_all hcar
                       , hz_customer_profiles hcp
                       , ra_terms rt
                   WHERE hcp.standard_terms = rt.term_id(+)
                     AND hcp.cust_account_id(+) = hca1.cust_account_id
                     AND hcp.site_use_id IS NULL
                     AND hca1.status = 'A'
                     AND hcar.status = 'A'
                     AND hcp.status = 'A'
                     AND hcar.related_cust_account_id = hca1.cust_account_id
                     AND hcar.cust_account_id = l_sold_to_org_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_oe_status := g_failed_msg;
                     xx_oe_error_insert
                        (p_header_id
                       , NULL
                       , 'Header Level Validation'
                       ,    'Payment Term is Not setup in Account Relationship Properly. Exception: '
                         || SUBSTR (SQLERRM, 1, 3500)
                        );
               END;

               ----checking bill to site count for single account relationship
               BEGIN
                  SELECT COUNT (hcsu.site_use_id)
                    INTO l_bill_cnt
                    FROM hz_cust_accounts hca
                       , hz_cust_acct_sites_all hcas
                       , hz_cust_site_uses_all hcsu
                   WHERE hca.cust_account_id = hcas.cust_account_id
                     AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
                     AND hcsu.site_use_code = 'BILL_TO'
                     AND hcsu.status = 'A'
                     AND hca.status = 'A'
                     AND hcas.status = 'A'
                     AND hcsu.primary_flag = 'Y'
                     AND hca.cust_account_id = l_relation_acc_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_oe_status := g_failed_msg;
                     xx_oe_error_insert
                         (p_header_id
                        , NULL
                        , 'Header Level Validation'
                        ,    'Exception while checking Bill to account count'
                          || SUBSTR (SQLERRM, 1, 3500)
                         );
               END;

               IF l_bill_cnt = 1
               THEN
                  -- Addition of Logic for Bill to Site Use ID
                  BEGIN
                     SELECT hcsu.site_use_id
                       INTO l_bill_to_site_id
                       FROM hz_cust_accounts hca
                          , hz_cust_acct_sites_all hcas
                          , hz_cust_site_uses_all hcsu
                      WHERE hca.cust_account_id = hcas.cust_account_id
                        AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
                        AND hcsu.site_use_code = 'BILL_TO'
                        AND hcsu.status = 'A'
                        AND hcas.status = 'A'
                        AND hca.status = 'A'
                        AND hcsu.primary_flag = 'Y'
                        AND hca.cust_account_id = l_relation_acc_id;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_oe_status := g_failed_msg;
                        xx_oe_error_insert
                                    (p_header_id
                                   , NULL
                                   , 'Header Level Validation'
                                   ,    'Bill To Site not exist. Exception: '
                                     || SUBSTR (SQLERRM, 1, 3500)
                                    );
                  END;
-----For multiple Bill to site----
               ELSE                                 ----IF l_bill_cnt = 1 THEN
                  BEGIN
                     SELECT hcsu.site_use_id
                       INTO l_bill_to_site_id
                       FROM hz_cust_accounts hca
                          , hz_cust_acct_sites_all hcas
                          , hz_cust_site_uses_all hcsu
                      WHERE hca.cust_account_id = hcas.cust_account_id
                        AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
                        AND hcsu.site_use_code = 'BILL_TO'
                        AND hcsu.status = 'A'
                        AND hcas.status = 'A'
                        AND hca.status = 'A'
                        AND hcsu.primary_flag = 'Y'
                        AND hca.cust_account_id = l_sold_to_org_id;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_oe_status := g_failed_msg;
                        xx_oe_error_insert
                           (p_header_id
                          , NULL
                          , 'Header Level Validation'
                          ,    'Bill To Site not exist for corresponding ship to site. Exception: '
                            || SUBSTR (SQLERRM, 1, 3500)
                           );
                  END;
               END IF;                              ----IF l_bill_cnt = 1 THEN
            END IF;                                  ---IF l_rel_count= 0 THEN
         END IF;
      END IF;

      ---IF (p_order_type = 'DS') AND (p_translated_customer_name=G_ISA_NO) THEN
      --- Customer Derivation logic for GXS Ends
    ELSIF p_file_type = g_ghx_file_type THEN --- Customer Derivation logic for GHX
        l_edi_loc_code := p_edi_loc_code;

     -- Deriving Bill To Customer from BT EDI Location Code
      IF p_bill_to_customer_number IS NOT NULL THEN
        l_bt_edi_loc_code := p_bill_to_customer_number;
        BEGIN
            SELECT hsu.site_use_id
              INTO l_bill_to_site_id
              FROM hz_parties hp
                 , hz_party_sites hps
                 , hz_cust_accounts hca
                 , hz_cust_acct_sites_all hcs
                 , hz_cust_site_uses_all hsu
                 , hz_locations hzl
             WHERE hp.party_id = hps.party_id
               AND hps.party_id = hca.party_id
               AND hca.cust_account_id = hcs.cust_account_id
               AND hcs.party_site_id = hps.party_site_id
               AND hps.location_id = hzl.location_id
               AND hcs.cust_acct_site_id = hsu.cust_acct_site_id
               AND hca.status = 'A'
               AND hsu.status = 'A'
               AND hcs.status = 'A'
               AND hsu.site_use_code = 'BILL_TO'
               AND hcs.attribute5 = l_bt_edi_loc_code
               AND hcs.attribute4 = p_translated_customer_name;
        EXCEPTION
         WHEN OTHERS THEN
           l_bill_to_site_id := NULL; -- Bill to Site not found from BT EDI Location Code
        END;

      END IF;

     -- Deriving Bill To Customer from BT Site Number entered from EDI error correction form
      IF ((p_bill_to_site_number IS NOT NULL) and (l_bill_to_site_id IS NULL)) THEN
        l_bt_edi_loc_code := p_bill_to_customer_number;
        BEGIN
            SELECT hsu.site_use_id
              INTO l_bill_to_site_id
              FROM hz_parties hp
                 , hz_party_sites hps
                 , hz_cust_accounts hca
                 , hz_cust_acct_sites_all hcs
                 , hz_cust_site_uses_all hsu
                 , hz_locations hzl
             WHERE hp.party_id = hps.party_id
               AND hps.party_id = hca.party_id
               AND hca.cust_account_id = hcs.cust_account_id
               AND hcs.party_site_id = hps.party_site_id
               AND hps.location_id = hzl.location_id
               AND hcs.cust_acct_site_id = hsu.cust_acct_site_id
               AND hca.status = 'A'
               AND hsu.status = 'A'
               AND hcs.status = 'A'
               AND hsu.site_use_code = 'BILL_TO'
               AND hps.party_site_number = p_bill_to_site_number;
        EXCEPTION
         WHEN OTHERS THEN
           l_bill_to_site_id := NULL; -- Bill to Site not found from BT EDI Location Code
        END;

      END IF;

        --Derive Sold-To, Ship-To, Bill-To details (Linked BIll To)
        BEGIN
           SELECT hca.account_number
                , hca.cust_account_id
                , hca.party_id
                , hsu.site_use_id
                , hsu.cust_acct_site_id
                , hzl.country
                , hcs.attribute10 ---- Certificate Of Conformance ------
           ,      nvl(l_bill_to_site_id, bill_to_site_use_id)
           INTO   l_sold_to_org
                , l_sold_to_org_id
                , l_party_id
                , l_ship_to_site_id
                , l_ship_to_cust_acct_site_id
                , l_country
                , l_coc           ---- Certificate Of Conformance ------
           ,      l_bill_to_site_id
             FROM hz_parties hp
                , hz_party_sites hps
                , hz_cust_accounts hca
                , hz_cust_acct_sites_all hcs
                , hz_cust_site_uses_all hsu
                , hz_locations hzl
            WHERE hp.party_id = hps.party_id
              AND hps.party_id = hca.party_id
              AND hca.cust_account_id = hcs.cust_account_id
              AND hcs.party_site_id = hps.party_site_id
              AND hps.location_id = hzl.location_id
              AND hcs.cust_acct_site_id = hsu.cust_acct_site_id
              AND hca.status = 'A'
              AND hsu.status = 'A'
              AND hcs.status = 'A'
              AND hsu.site_use_code = 'SHIP_TO'
              AND hcs.attribute5 = l_edi_loc_code
              AND hcs.attribute4 = p_translated_customer_name;
        EXCEPTION
           WHEN OTHERS
           THEN
              p_oe_status := g_failed_msg;
              xx_oe_error_insert
                 (p_header_id
                , NULL
                , 'Header Level Validation'
                ,    'EDI Location Code/Translated Customer Name not setup. Exception: '
                  || SUBSTR (SQLERRM, 1, 3500)
                 );
        END;

         -- added on 2012-Nov-16 to have site level bill to logic indluded
       IF l_bill_to_site_id IS NOT NULL
       THEN
            --Addition of logic to fetch Payment Terms for Customer Account
            BEGIN
               SELECT rt.term_id
                 INTO l_payment_term_id
                 FROM hz_cust_accounts hca
                    , hz_cust_acct_sites_all hcas
                    , hz_cust_site_uses_all hcsu
                    , ra_terms rt
                    , hz_customer_profiles hcp
                WHERE hca.cust_account_id = hcas.cust_account_id
                  AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
                  AND hcsu.site_use_code = 'BILL_TO'
                  AND hcsu.status = 'A'
                  AND hcas.status = 'A'
                  AND hca.status = 'A'
                  AND hcp.status = 'A'
                  AND hcsu.primary_flag = 'Y'
                  AND hcp.cust_account_id(+) = hca.cust_account_id
                  AND hcp.site_use_id IS NULL
                  AND hcp.standard_terms = rt.term_id(+)
                  AND hcsu.site_use_id = l_bill_to_site_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_oe_status := g_failed_msg;
                  xx_oe_error_insert
                     (p_header_id
                    , NULL
                    , 'Header Level Validation'
                    ,    'Payment Term is Not setup for Bill To Account Properly. Exception: '
                      || SUBSTR (SQLERRM, 1, 3500)
                     );
            END;

       ELSE -- Bill to Site not found
             --- get primary bill to for the ship to site account
           BEGIN
              SELECT hcsu.site_use_id
                INTO l_bill_to_site_id
                FROM hz_cust_accounts hca
                   , hz_cust_acct_sites_all hcas
                   , hz_cust_site_uses_all hcsu
               WHERE hca.cust_account_id = hcas.cust_account_id
                 AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
                 AND hcsu.site_use_code = 'BILL_TO'
                 AND hcsu.status = 'A'
                 AND hcas.status = 'A'
                 AND hca.status = 'A'
                 AND hcsu.primary_flag = 'Y'
                 AND hca.cust_account_id = l_sold_to_org_id;
           EXCEPTION
              WHEN OTHERS
              THEN
               l_bill_to_site_id := NULL;
           END;

           --Addition of logic to fetch Payment Terms for Customer Account
           BEGIN
              SELECT hca1.account_number
                   , hca1.cust_account_id
                   , rt.term_id
                INTO l_relation_acc_num
                   , l_relation_acc_id
                   , l_payment_term_id
                FROM hz_cust_accounts hca1
                   , hz_customer_profiles hcp
                   , ra_terms rt
               WHERE hcp.standard_terms = rt.term_id(+)
                 AND hcp.cust_account_id(+) = hca1.cust_account_id
                 AND hcp.site_use_id IS NULL
                 AND hca1.status = 'A'
                 AND hcp.status = 'A'
                 AND hca1.cust_account_id = l_sold_to_org_id;
           EXCEPTION
              WHEN OTHERS
              THEN
                 p_oe_status := g_failed_msg;
                 xx_oe_error_insert
                    (p_header_id
                   , NULL
                   , 'Header Level Validation'
                   ,    'Payment Term is Not setup for this Account Properly. Exception: '
                     || SUBSTR (SQLERRM, 1, 3500)
                    );
           END;

         IF l_bill_to_site_id IS NULL THEN
            --- Checking count of Relationship Account ---
           BEGIN
            SELECT hcsu.site_use_id
                 , rel.related_acc_num
                 , rel.related_acc_id
                 , rel.term_id
              INTO l_bill_to_site_id
                 , l_relation_acc_num
                 , l_relation_acc_id
                 , l_payment_term_id
              FROM hz_cust_accounts hca
                 , hz_cust_acct_sites_all hcas
                 , hz_cust_site_uses_all hcsu
                 , (SELECT hca1.account_number related_acc_num
                         , hca1.cust_account_id related_acc_id
                         , rt.term_id term_id
                      FROM hz_cust_accounts hca1
                         , hz_cust_acct_relate_all hcar
                         , hz_customer_profiles hcp
                         , ra_terms rt
                     WHERE hcp.standard_terms = rt.term_id(+)
                       AND hcp.cust_account_id(+) = hca1.cust_account_id
                       AND hcp.site_use_id IS NULL
                       AND hca1.status = 'A'
                       AND hcar.status = 'A'
                       AND hcp.status = 'A'
                       AND hcar.related_cust_account_id = hca1.cust_account_id
                       AND hcar.cust_account_id = l_sold_to_org_id) rel -- For Ship to Site Account
             WHERE hca.cust_account_id = hcas.cust_account_id
               AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
               AND hcsu.site_use_code = 'BILL_TO'
               AND hcsu.status = 'A'
               AND hcas.status = 'A'
               AND hca.status = 'A'
               AND hcsu.primary_flag = 'Y'
               AND hca.cust_account_id = rel.related_acc_id;

           EXCEPTION
           WHEN OTHERS THEN
                 p_oe_status := g_failed_msg;
                 xx_oe_error_insert
                        (p_header_id
                       , NULL
                       , 'Header Level Validation'
                       ,    'Unable to determine Bill To Site Customer Account '
                         || l_sold_to_org
                        );
           END;
         END IF; -- Bill to from relationship
       END IF;

       ---- Change for GHX Customer Relationship -- Bill To Account should be used as Sold To
       --  21stMarch2014 requirement by Sharon and Mellisa
      IF (l_bill_to_site_id IS NOT NULL) AND (p_file_type = g_ghx_file_type) THEN
        BEGIN
            SELECT hca.account_number
                 , hca.cust_account_id
              INTO l_sold_to_org
                 , l_sold_to_org_id
              FROM hz_cust_accounts hca
                 , hz_cust_acct_sites_all hcs
                 , hz_cust_site_uses_all hsu
             WHERE hca.cust_account_id = hcs.cust_account_id
               AND hcs.cust_acct_site_id = hsu.cust_acct_site_id
               AND hsu.site_use_id = l_bill_to_site_id
               AND hca.status = 'A'
               AND hsu.status = 'A'
               AND hcs.status = 'A'
               AND hsu.site_use_code = 'BILL_TO';
        EXCEPTION
         WHEN OTHERS THEN
                 p_oe_status := g_failed_msg;
                 xx_oe_error_insert
                        (p_header_id
                       , NULL
                       , 'Header Level Validation'
                       ,    'Unable to determine Sold To Customer Account from Bill To Site: '
                         || l_bill_to_site_id
                        );
        END;
      END IF;
      ---- Logic for GHX
    END IF;

      --Derive country from lookup for DropShip Order Type
      -- Modified for GHX
      IF p_country IS NULL
      THEN
         IF p_order_type = 'DS'
         THEN
            l_country := '';

            BEGIN
               SELECT tag
                 INTO l_country
                 FROM fnd_lookup_values
                WHERE lookup_type = 'INTG_EDI_STATE_COUNTRY'
                  AND lookup_code = p_state
                  AND LANGUAGE = USERENV ('LANG')
                  AND enabled_flag = 'Y';
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_oe_status := g_failed_msg;
                  xx_oe_error_insert
                                 (p_header_id
                                , NULL
                                , 'Header Level Validation'
                                ,    'State not setup in lookup. Exception: '
                                  || SUBSTR (SQLERRM, 1, 3500)
                                 );
            END;
         END IF;
      END IF;


      ----Added Certificate Of Conformance ------
      IF l_coc = 'Y'
      THEN
         p_coc := 'Yes';                -- changed from Y to Yes (2012-08-24)
      ELSE
         p_coc := 'No';               -- changed from NULL to No (2012-08-24)
      END IF;

      ----Added Certificate Of Conformance ------

      --Assign Out Parameters
      p_sold_to_org := l_sold_to_org;
      p_sold_to_org_id := l_sold_to_org_id;
      p_party_id := l_party_id;
      p_ship_to_site_id := l_ship_to_site_id;
      p_ship_to_cust_acct_site_id := l_ship_to_cust_acct_site_id;

      IF p_country IS NULL                             -- Modification for GHX
      THEN
         p_country := l_country;
      END IF;

      p_payment_term_id := l_payment_term_id;
      p_bill_to_site_id := l_bill_to_site_id;
      --p_oe_status := G_SUCCESS_MSG;----Added 20/08/2012
      p_err_msg := NULL;
   --Main exception block
   EXCEPTION
      WHEN OTHERS
      THEN
         p_oe_status := g_failed_msg;
         xx_oe_error_insert
                     (p_header_id
                    , NULL
                    , 'Header Level Validation'
                    ,    'Unknown Exception in get_customer_dtls Procedure: '
                      || SQLERRM
                     );
   END get_customer_dtls;

   -- End of modification (2012-05-31)

   --********************************************************************************************
   PROCEDURE find_location (
      p_deliver_to_loc   IN       hz_location_v2pub.location_rec_type
    , p_location_id      OUT      NUMBER
   )
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 11-APRIL-2012
Filename       :
Description    : Procedure to find out location id.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
11-Apr-2012   1.0       IBM Technical Team         Initial development.
*/
--------------------------------------------------------------------------------
   BEGIN
      SELECT location_id
        INTO p_location_id
        FROM hz_locations hl
       WHERE UPPER (hl.address1) = UPPER (p_deliver_to_loc.address1)
         AND UPPER (hl.city) = UPPER (p_deliver_to_loc.city)
         AND UPPER (hl.state) = UPPER (p_deliver_to_loc.state)
         AND UPPER (hl.postal_code) = UPPER (p_deliver_to_loc.postal_code)
         AND (   (hl.county IS NULL AND p_deliver_to_loc.county IS NULL)
              OR (UPPER (hl.county) = UPPER (p_deliver_to_loc.county))
             )
         AND UPPER (hl.country) = UPPER (p_deliver_to_loc.country);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_location_id := NULL;
   END find_location;

--********************************************************************************************
   PROCEDURE find_party_site (
      p_location_id     IN       NUMBER
    , p_party_id        IN       NUMBER
    , p_party_site_id   OUT      NUMBER
   )
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 11-APRIL-2012
Filename       :
Description    : Procedure to find out party site id.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
11-Apr-2012   1.0       IBM Technical Team         Initial development.
*/
--------------------------------------------------------------------------------
   BEGIN
      SELECT party_site_id
        INTO p_party_site_id
        FROM hz_party_sites
       WHERE location_id = p_location_id AND party_id = p_party_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_party_site_id := NULL;
   END find_party_site;

--********************************************************************************************
   PROCEDURE find_cust_acct_site (
      p_cust_account_id     IN       NUMBER
    , p_party_site_id       IN       NUMBER
    , p_cust_acct_site_id   OUT      NUMBER
   )
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 11-APRIL-2012
Filename       :
Description    : Procedure to find out customer account site id.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
11-Apr-2012   1.0       IBM Technical Team         Initial development.
*/
--------------------------------------------------------------------------------
   BEGIN
      SELECT cust_acct_site_id
        INTO p_cust_acct_site_id
        FROM hz_cust_acct_sites_all
       WHERE cust_account_id = p_cust_account_id
         AND party_site_id = p_party_site_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_cust_acct_site_id := NULL;
   END find_cust_acct_site;

--********************************************************************************************
   PROCEDURE find_cust_site_use (
      p_cust_acct_site_id   IN       NUMBER
    , p_site_use_code       IN       VARCHAR2
    , p_deliver_to_org_id   OUT      NUMBER
   )
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 11-APRIL-2012
Filename       :
Description    : Procedure to find out account site use id.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
11-Apr-2012   1.0       IBM Technical Team         Initial development.
*/
--------------------------------------------------------------------------------
   BEGIN
      SELECT site_use_id
        INTO p_deliver_to_org_id
        FROM hz_cust_site_uses_all
       WHERE cust_acct_site_id = p_cust_acct_site_id
         AND site_use_code = p_site_use_code
         AND status = 'A';
   EXCEPTION
      WHEN OTHERS
      THEN
         p_deliver_to_org_id := NULL;
   END find_cust_site_use;

--********************************************************************************************
   PROCEDURE find_contact_person (
      p_contact_person     IN       hz_party_v2pub.person_rec_type
    , p_contact_party_id   OUT      NUMBER
   )
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 11-APRIL-2012
Filename       :
Description    : Procedure to find out contact person.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
11-Apr-2012   1.0       IBM Technical Team  Initial development.
22-Feb-2013   1.1       Bedabrata (IBM)     Added Count check and if logic
12-Mar-2013   1.2       Bedabrata (IBM)     Added check to consider Person Type
*/
--------------------------------------------------------------------------------
      l_count_contact_per   NUMBER := 0;
   BEGIN
      SELECT COUNT (party_id)
        INTO l_count_contact_per
        FROM hz_parties
       WHERE party_name = p_contact_person.person_last_name
         AND party_type = 'PERSON';

      IF l_count_contact_per <> 0
      THEN
         SELECT party_id
           INTO p_contact_party_id
           FROM hz_parties
          WHERE party_name = p_contact_person.person_last_name
            AND party_type = 'PERSON'
            AND ROWNUM < 2;
      ELSE
         p_contact_party_id := NULL;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_contact_party_id := NULL;
   END find_contact_person;

--********************************************************************************************
   PROCEDURE find_contact_party_site (
      p_location_id             IN       NUMBER
    , p_contact_party_id        IN       NUMBER
    , p_contact_party_site_id   OUT      NUMBER
   )
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 11-APRIL-2012
Filename       :
Description    : Procedure to find out contact party site id.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
11-Apr-2012   1.0       IBM Technical Team         Initial development.
*/
--------------------------------------------------------------------------------
   BEGIN
      SELECT party_site_id
        INTO p_contact_party_site_id
        FROM hz_party_sites
       WHERE location_id = p_location_id AND party_id = p_contact_party_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_contact_party_site_id := NULL;
   END find_contact_party_site;

--********************************************************************************************
   PROCEDURE find_org_contact (
      p_contact_party_id   IN       NUMBER
    , p_party_id           IN       NUMBER
    , p_new_party_id       OUT      NUMBER
   )
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 11-APRIL-2012
Filename       :
Description    : Procedure to find out org contact id.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
11-Apr-2012   1.0       IBM Technical Team         Initial development.
*/
--------------------------------------------------------------------------------
   BEGIN
      SELECT party_id
        INTO p_new_party_id
        FROM hz_party_relationship_v
       WHERE subject_id = p_contact_party_id AND object_id = p_party_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_new_party_id := NULL;
   END find_org_contact;

--********************************************************************************************
   PROCEDURE find_cust_acct_role (
      p_new_party_id           IN       NUMBER
    , p_cust_account_role_id   OUT      NUMBER
   )
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 11-APRIL-2012
Filename       :
Description    : Procedure to find out contact relationship id.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
11-Apr-2012   1.0       IBM Technical Team         Initial development.
*/
--------------------------------------------------------------------------------
   BEGIN
      SELECT cust_account_role_id
        INTO p_cust_account_role_id
        FROM hz_cust_account_roles
       WHERE party_id = p_new_party_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_cust_account_role_id := NULL;
   END find_cust_acct_role;

--********************************************************************************************
   PROCEDURE create_cust_site_contact (
      p_cust_account_id         IN       NUMBER
    , p_party_id                IN       NUMBER
    , p_org_id                  IN       NUMBER
    , p_site_use_code           IN       VARCHAR2
    , p_contact_person          IN       hz_party_v2pub.person_rec_type
    , p_deliver_to_loc          IN       hz_location_v2pub.location_rec_type
    , p_header_id               IN       NUMBER
    , p_deliver_to_org_id       OUT      NUMBER
    , p_deliver_to_contact_id   OUT      NUMBER
    , p_oe_status               OUT      VARCHAR2
    , p_err_msg                 OUT      VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 11-APRIL-2012
Filename       :
Description    : Procedure to create the address creation for customer Deliver to business purpose.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
11-Apr-2012   1.0       IBM Technical Team         Initial development.
*/
--------------------------------------------------------------------------------
      x_location_rec            hz_location_v2pub.location_rec_type;
      x_party_site_rec          hz_party_site_v2pub.party_site_rec_type;
      x_location_id             hz_locations.location_id%TYPE;
      x_party_site_id           hz_party_sites.party_site_id%TYPE;
      x_party_site_number       hz_party_sites.party_site_number%TYPE;
      x_cust_acct_site_rec      hz_cust_account_site_v2pub.cust_acct_site_rec_type;
      x_cust_acct_site_id       NUMBER;
      x_cust_site_use_rec       hz_cust_account_site_v2pub.cust_site_use_rec_type;
      x_site_use_id             NUMBER;
      x_customer_profile_rec1   hz_customer_profile_v2pub.customer_profile_rec_type;
      x_contact_party_id        NUMBER;
      x_profile_id              NUMBER;
      x_cust_acc_role_rec       hz_cust_account_role_v2pub.cust_account_role_rec_type;
      x_cust_account_role_id    NUMBER;
      x_org_contact_rec         hz_party_contact_v2pub.org_contact_rec_type;
      x_org_contact_id          NUMBER;
      x_party_rel_id            NUMBER;
      x_new_party_id            NUMBER;
      x_party_number            NUMBER;
      x_return_status           VARCHAR2 (1);
      x_msg_count               NUMBER;
      x_msg_data                VARCHAR2 (4000);
      p_location_id             NUMBER;
      p_party_site_id           NUMBER;
      p_contact_party_id        NUMBER;
      p_cust_acct_site_id       NUMBER;
      p_contact_party_site_id   NUMBER;
      p_site_use_id             NUMBER;
      p_new_party_id            NUMBER;
      p_cust_account_role_id    NUMBER;
   BEGIN
      -- assign the out parameters
      p_oe_status := fnd_api.g_ret_sts_success;
      p_err_msg := NULL;
      mo_global.init ('AR');
      mo_global.set_policy_context ('S', p_org_id);
      ----------Check location exists-----------------
      find_location (p_deliver_to_loc, p_location_id);

      IF p_location_id IS NOT NULL
      THEN
         x_location_id := p_location_id;
      ELSE
         -- Create the deliver to location
         x_location_rec := p_deliver_to_loc;
         x_location_rec.created_by_module := g_created_by_module;
         hz_location_v2pub.create_location
                                         (p_init_msg_list      => fnd_api.g_true
                                        , p_location_rec       => x_location_rec
                                        , x_location_id        => x_location_id
                                        , x_return_status      => x_return_status
                                        , x_msg_count          => x_msg_count
                                        , x_msg_data           => x_msg_data
                                         );

         -- Return if there is API error
         IF x_return_status <> fnd_api.g_ret_sts_success
         THEN
            FOR i IN 1 .. x_msg_count
            LOOP
               p_err_msg := x_msg_data || fnd_msg_pub.get (i, 'F');
            END LOOP;

            ---- p_oe_status := x_return_status;-----Added 20/08/2012
            p_oe_status := g_failed_msg;                  ----Added 20/08/2012
            xx_oe_error_insert (p_header_id, NULL, 'API Error', p_err_msg);
            RETURN;
         END IF;
      END IF;                            ----IF p_location_id IS NOT NULL THEN

      --------Check Party site
      find_party_site (x_location_id, p_party_id, p_party_site_id);

      IF p_party_site_id IS NOT NULL
      THEN
         x_party_site_id := p_party_site_id;
      ELSE
         -- Create deliver to party site
         x_party_site_rec.location_id := x_location_id;
         x_party_site_rec.party_id := p_party_id;                  ---sold to
         x_party_site_rec.identifying_address_flag := 'N';
         x_party_site_rec.created_by_module := g_created_by_module;
         hz_party_site_v2pub.create_party_site
                                 (p_init_msg_list          => fnd_api.g_true
                                , p_party_site_rec         => x_party_site_rec
                                , x_party_site_id          => x_party_site_id
                                , x_party_site_number      => x_party_site_number
                                , x_return_status          => x_return_status
                                , x_msg_count              => x_msg_count
                                , x_msg_data               => x_msg_data
                                 );

         IF x_return_status <> fnd_api.g_ret_sts_success
         THEN
            FOR i IN 1 .. x_msg_count
            LOOP
               p_err_msg := x_msg_data || fnd_msg_pub.get (i, 'F');
            END LOOP;

            ---- p_oe_status := x_return_status;-----Added 20/08/2012
            p_oe_status := g_failed_msg;                  ----Added 20/08/2012
            xx_oe_error_insert (p_header_id, NULL, 'API Error', p_err_msg);
            RETURN;
         END IF;                                  -- Party site not successful
      END IF;                          ----IF p_party_site_id IS NOT NULL THEN

      -------Check Customer Account Site-------
      find_cust_acct_site (p_cust_account_id
                         , x_party_site_id
                         , p_cust_acct_site_id
                          );

      IF p_cust_acct_site_id IS NOT NULL
      THEN
         x_cust_acct_site_id := p_cust_acct_site_id;
      ELSE
         -----Create deliver to Cust Acct Site
         x_cust_acct_site_rec.cust_account_id := p_cust_account_id;
         x_cust_acct_site_rec.party_site_id := x_party_site_id;
         x_cust_acct_site_rec.created_by_module := g_created_by_module;
         hz_cust_account_site_v2pub.create_cust_acct_site
                               (p_init_msg_list           => fnd_api.g_true
                              , p_cust_acct_site_rec      => x_cust_acct_site_rec
                              , x_cust_acct_site_id       => x_cust_acct_site_id
                              , x_return_status           => x_return_status
                              , x_msg_count               => x_msg_count
                              , x_msg_data                => x_msg_data
                               );

         IF x_return_status <> fnd_api.g_ret_sts_success
         THEN
            FOR i IN 1 .. x_msg_count
            LOOP
               p_err_msg := x_msg_data || fnd_msg_pub.get (i, 'F');
            END LOOP;

            ---- p_oe_status := x_return_status;-----Added 20/08/2012
            p_oe_status := g_failed_msg;                  ----Added 20/08/2012
            xx_oe_error_insert (p_header_id, NULL, 'API Error', p_err_msg);
            RETURN;
         END IF;                            ------ Account site not successful
      END IF;                     -----IF p_cust_acct_site_id IS NOT NULL THEN

      ------------Check Account Site usage----
      find_cust_site_use (x_cust_acct_site_id
                        , p_site_use_code
                        , p_deliver_to_org_id
                         );

      IF p_deliver_to_org_id IS NOT NULL
      THEN
         x_site_use_id := p_deliver_to_org_id;
      ELSE
         ---------Create Cust Acct Site Usage
         x_cust_site_use_rec.cust_acct_site_id := x_cust_acct_site_id;
         x_cust_site_use_rec.site_use_code := p_site_use_code;
         x_cust_site_use_rec.created_by_module := g_created_by_module;
         hz_cust_account_site_v2pub.create_cust_site_use
                                                    (fnd_api.g_true
                                                   , x_cust_site_use_rec
                                                   , x_customer_profile_rec1
                                                   , ''
                                                   , ''
                                                   , x_site_use_id
                                                   , x_return_status
                                                   , x_msg_count
                                                   , x_msg_data
                                                    );
         p_deliver_to_org_id := x_site_use_id;

         IF x_return_status <> fnd_api.g_ret_sts_success
         THEN
            FOR i IN 1 .. x_msg_count
            LOOP
               p_err_msg := x_msg_data || fnd_msg_pub.get (i, 'F');
            END LOOP;

            ---- p_oe_status := x_return_status;-----Added 20/08/2012
            p_oe_status := g_failed_msg;                  ----Added 20/08/2012
            xx_oe_error_insert (p_header_id, NULL, 'API Error', p_err_msg);
            RETURN;
         END IF;
      END IF;                            ---IF p_site_uses_id IS NOT NULL THEN

      ------Check Contact Person exists--------
      find_contact_person (p_contact_person, p_contact_party_id);

      IF p_contact_party_id IS NOT NULL
      THEN
         x_contact_party_id := p_contact_party_id;
      ELSE
         --------Create contact person
         hz_party_v2pub.create_person (fnd_api.g_true
                                     , p_contact_person
                                     , x_contact_party_id
                                     , x_party_number
                                     , x_profile_id
                                     , x_return_status
                                     , x_msg_count
                                     , x_msg_data
                                      );

         IF x_return_status <> fnd_api.g_ret_sts_success
         THEN
            FOR i IN 1 .. x_msg_count
            LOOP
               p_err_msg := x_msg_data || fnd_msg_pub.get (i, 'F');
            END LOOP;

            ---- p_oe_status := x_return_status;-----Added 20/08/2012
            p_oe_status := g_failed_msg;                  ----Added 20/08/2012
            xx_oe_error_insert (p_header_id, NULL, 'API Error', p_err_msg);
            RETURN;
         END IF;
      END IF;                      ----IF  p_contact_party_id IS NOT NULL THEN

      -------Check Contact Party site
      find_contact_party_site (x_location_id
                             , x_contact_party_id
                             , p_contact_party_site_id
                              );

      IF p_contact_party_site_id IS NOT NULL
      THEN
         x_party_site_id := p_contact_party_site_id;
      ELSE
         ------------Create contact party site
         x_party_site_rec.party_id := x_contact_party_id;
         x_party_site_rec.location_id := x_location_id;
         x_party_site_rec.identifying_address_flag := 'N';
         x_party_site_rec.created_by_module := g_created_by_module;
         hz_party_site_v2pub.create_party_site
                                 (p_init_msg_list          => fnd_api.g_true
                                , p_party_site_rec         => x_party_site_rec
                                , x_party_site_id          => x_party_site_id
                                , x_party_site_number      => x_party_site_number
                                , x_return_status          => x_return_status
                                , x_msg_count              => x_msg_count
                                , x_msg_data               => x_msg_data
                                 );

         IF x_return_status <> fnd_api.g_ret_sts_success
         THEN
            FOR i IN 1 .. x_msg_count
            LOOP
               p_err_msg := x_msg_data || fnd_msg_pub.get (i, 'F');
            END LOOP;

            ---- p_oe_status := x_return_status;-----Added 20/08/2012
            p_oe_status := g_failed_msg;                  ----Added 20/08/2012
            xx_oe_error_insert (p_header_id, NULL, 'API Error', p_err_msg);
            RETURN;
         END IF;
      END IF;                  ----IF p_contact_party_site_id IS NOT NULL THEN

      -------Check Org Contact---
      find_org_contact (x_contact_party_id, p_party_id, p_new_party_id);

      IF p_new_party_id IS NOT NULL
      THEN
         x_new_party_id := p_new_party_id;
      ELSE
         ----------Create org contact
         x_org_contact_rec.created_by_module := g_created_by_module;
         x_org_contact_rec.party_rel_rec.subject_id := x_contact_party_id;
         x_org_contact_rec.party_rel_rec.subject_type := 'PERSON';
         x_org_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES';
         x_org_contact_rec.party_rel_rec.object_id := p_party_id;
         x_org_contact_rec.party_rel_rec.object_type := 'ORGANIZATION';
         x_org_contact_rec.party_rel_rec.object_table_name := 'HZ_PARTIES';
         x_org_contact_rec.party_rel_rec.relationship_code := 'CONTACT_OF';
         x_org_contact_rec.party_rel_rec.relationship_type := 'CONTACT';
         x_org_contact_rec.party_rel_rec.start_date := SYSDATE;
         hz_party_contact_v2pub.create_org_contact
                                     (p_init_msg_list        => fnd_api.g_true
                                    , p_org_contact_rec      => x_org_contact_rec
                                    , x_org_contact_id       => x_org_contact_id
                                    , x_party_rel_id         => x_party_rel_id
                                    , x_party_id             => x_new_party_id
                                    , x_party_number         => x_party_number
                                    , x_return_status        => x_return_status
                                    , x_msg_count            => x_msg_count
                                    , x_msg_data             => x_msg_data
                                     );

         IF x_return_status <> fnd_api.g_ret_sts_success
         THEN
            FOR i IN 1 .. x_msg_count
            LOOP
               p_err_msg := x_msg_data || fnd_msg_pub.get (i, 'F');
            END LOOP;

            ---- p_oe_status := x_return_status;-----Added 20/08/2012
            p_oe_status := g_failed_msg;                  ----Added 20/08/2012
            xx_oe_error_insert (p_header_id, NULL, 'API Error', p_err_msg);
            RETURN;
         END IF;
      END IF;                           ----IF p_new_party_id IS NOT NULL THEN

      ------Check cust account role
      find_cust_acct_role (x_new_party_id, p_cust_account_role_id);

      IF p_cust_account_role_id IS NOT NULL
      THEN
         p_deliver_to_contact_id := p_cust_account_role_id;
      ELSE
         ----------Create cust account role
         x_cust_acc_role_rec.party_id := x_new_party_id;
         x_cust_acc_role_rec.cust_account_id := p_cust_account_id;
         x_cust_acc_role_rec.cust_acct_site_id := x_cust_acct_site_id;
--      x_cust_acc_role_rec.primary_flag      := 'Y';
         x_cust_acc_role_rec.role_type := 'CONTACT';
         x_cust_acc_role_rec.created_by_module := g_created_by_module;
         hz_cust_account_role_v2pub.create_cust_account_role
                                                     (fnd_api.g_true
                                                    , x_cust_acc_role_rec
                                                    , x_cust_account_role_id
                                                    , x_return_status
                                                    , x_msg_count
                                                    , x_msg_data
                                                     );
         p_deliver_to_contact_id := x_cust_account_role_id;

         IF x_return_status <> fnd_api.g_ret_sts_success
         THEN
            FOR i IN 1 .. x_msg_count
            LOOP
               p_err_msg := x_msg_data || fnd_msg_pub.get (i, 'F');
            END LOOP;

            ---- p_oe_status := x_return_status;-----Added 20/08/2012
            p_oe_status := g_failed_msg;                  ----Added 20/08/2012
            xx_oe_error_insert (p_header_id, NULL, 'API Error', p_err_msg);
            RETURN;
         END IF;
      END IF;                    ---IF p_cust_account_role_id IS NOT NULL THEN
   EXCEPTION
      WHEN OTHERS
      THEN
         --p_oe_status := fnd_api.g_ret_sts_error;
         --p_err_msg   := SQLCODE || ' : ' ||dbms_utility.format_error_backtrace;
         --RETURN;

         ---- p_oe_status := x_return_status;-----Added 20/08/2012
         p_oe_status := g_failed_msg;                    ----Added 20/08/2012
         xx_oe_error_insert (p_header_id, NULL, 'Exception', SQLERRM);
   END create_cust_site_contact;

--********************************************************************************************
   PROCEDURE create_header_attach (
      p_header_id   IN       NUMBER
    , p_message     IN       VARCHAR2
    , p_ws_hdr_id   IN       NUMBER
    , p_oe_status   OUT      VARCHAR2
    , p_err_msg     OUT      VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 11-APRIL-2012
Filename       :
Description    : Procedure to create the header level attachment for EDI note.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
11-Apr-2012   1.0       IBM Technical Team         Initial development.
*/
--------------------------------------------------------------------------------
      l_rowid                  ROWID;
      l_attached_document_id   NUMBER;
      l_document_id            NUMBER;
      l_media_id               NUMBER;
      l_category_id            NUMBER;
      l_description            fnd_documents_tl.description%TYPE
                                                                := 'EDI Note';
      l_seq_num                NUMBER;
      l_data_type_id           NUMBER;
      l_user_id                NUMBER        := fnd_profile.VALUE ('USER_ID');
      l_login_id               NUMBER       := fnd_profile.VALUE ('LOGIN_ID');
   BEGIN
      BEGIN
         SELECT fnd_documents_short_text_s.NEXTVAL
           INTO l_media_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_oe_status := g_failed_msg;
            xx_oe_error_insert (p_ws_hdr_id
                              , NULL
                              , 'Header Level Validation'
                              ,    'Unable to get short text next value'
                                || SQLERRM
                               );
            RETURN;
      END;

      ----Get Document_id---
      BEGIN
         SELECT fnd_documents_s.NEXTVAL
           INTO l_document_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_oe_status := g_failed_msg;
            xx_oe_error_insert (p_ws_hdr_id
                              , NULL
                              , 'Header Level Validation'
                              ,    'Unable to get fnd documents next value'
                                || SQLERRM
                               );
            RETURN;
      END;

      ---------Get Datatype_id----
      BEGIN
         SELECT datatype_id
           INTO l_data_type_id
           FROM fnd_document_datatypes
          WHERE NAME = 'SHORT_TEXT' AND LANGUAGE = USERENV ('lang');
      EXCEPTION
         WHEN OTHERS
         THEN
            p_oe_status := g_failed_msg;
            xx_oe_error_insert (p_ws_hdr_id
                              , NULL
                              , 'Header Level Validation'
                              , 'Unable to find out datatype id' || SQLERRM
                               );
            RETURN;
      END;

      -------Get category_id-----
      BEGIN
         SELECT category_id
           INTO l_category_id
           FROM fnd_document_categories_tl
          WHERE user_name = 'Short Text' AND LANGUAGE = USERENV ('lang');
      EXCEPTION
         WHEN OTHERS
         THEN
            p_oe_status := g_failed_msg;
            xx_oe_error_insert (p_ws_hdr_id
                              , NULL
                              , 'Header Level Validation'
                              , 'Unable to find out category id' || SQLERRM
                               );
            RETURN;
      END;

      ----Get next Attach Sequence Number----
      SELECT NVL (MAX (seq_num), 0) + 10
        INTO l_seq_num
        FROM fnd_attached_documents
       WHERE pk1_value = to_char(p_header_id) AND entity_name = 'OE_ORDER_HEADERS';

      -------Call API ----
      BEGIN
         fnd_documents_pkg.insert_row (x_rowid                  => l_rowid
                                     , x_document_id            => l_document_id
                                     , x_creation_date          => SYSDATE
                                     , x_created_by             => l_user_id
                                     , x_last_update_date       => SYSDATE
                                     , x_last_updated_by        => l_user_id
                                     , x_last_update_login      => l_login_id
                                     , x_datatype_id            => l_data_type_id
                                     , x_category_id            => l_category_id
                                     , x_security_type          => 4
                                     , x_publish_flag           => 'Y'
                                     , x_usage_type             => 'O'
                                     , x_language               => USERENV
                                                                       ('lang')
                                     , x_media_id               => l_media_id
                                      );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_oe_status := g_failed_msg;
            xx_oe_error_insert (p_ws_hdr_id
                              , NULL
                              , 'API Error'
                              ,    'While inserting data into fnd documents'
                                || SQLERRM
                               );
            RETURN;
      END;

      BEGIN
         fnd_documents_pkg.insert_tl_row (x_document_id            => l_document_id
                                        , x_creation_date          => SYSDATE
                                        , x_created_by             => l_user_id
                                        , x_last_update_date       => SYSDATE
                                        , x_last_updated_by        => l_user_id
                                        , x_last_update_login      => l_login_id
                                        , x_language               => USERENV
                                                                         ('lang'
                                                                         )
                                        , x_description            => l_description
                                         );
      --COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_oe_status := g_failed_msg;
            xx_oe_error_insert
                             (p_ws_hdr_id
                            , NULL
                            , 'API Error'
                            ,    'While inserting data into fnd documents_tl'
                              || SQLERRM
                             );
            RETURN;
      END;

--------Get
      BEGIN
         SELECT fnd_attached_documents_s.NEXTVAL
           INTO l_attached_document_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_oe_status := g_failed_msg;
            xx_oe_error_insert
                        (p_ws_hdr_id
                       , NULL
                       , 'API Error'
                       ,    'Unable to get fnd attached documents next value'
                         || SQLERRM
                        );
            RETURN;
      END;

      -------Call API
      BEGIN
         fnd_attached_documents_pkg.insert_row
                           (x_rowid                         => l_rowid
                          , x_attached_document_id          => l_attached_document_id
                          , x_document_id                   => l_document_id
                          , x_creation_date                 => SYSDATE
                          , x_created_by                    => l_user_id
                          , x_last_update_date              => SYSDATE
                          , x_last_updated_by               => l_user_id
                          , x_last_update_login             => l_login_id
                          , x_seq_num                       => l_seq_num
                          , x_entity_name                   => 'OE_ORDER_HEADERS'
                          , x_column1                       => NULL
                          , x_pk1_value                     => p_header_id
                          , x_pk2_value                     => NULL
                          , x_pk3_value                     => NULL
                          , x_pk4_value                     => NULL
                          , x_pk5_value                     => NULL
                          , x_automatically_added_flag      => 'N'
                          , x_datatype_id                   => l_data_type_id
                          , x_category_id                   => l_category_id
                          , x_security_type                 => 4
                          , x_publish_flag                  => 'Y'
                          , x_language                      => USERENV ('lang')
                          , x_media_id                      => l_media_id
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_oe_status := g_failed_msg;
            xx_oe_error_insert
                       (p_ws_hdr_id
                      , NULL
                      , 'API Error'
                      ,    'While inserting data into fnd attached documents'
                        || SQLERRM
                       );
            RETURN;
      END;

      ---------Insert
      BEGIN
         INSERT INTO fnd_documents_short_text
              VALUES (l_media_id
                    , p_message
                    , NULL
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_oe_status := g_failed_msg;
            xx_oe_error_insert
                     (p_ws_hdr_id
                    , NULL
                    , 'API Error'
                    ,    'While inserting data into fnd_documents_short_text'
                      || SQLERRM
                     );
            RETURN;
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_oe_status := g_failed_msg;
         xx_oe_error_insert (p_ws_hdr_id
                           , NULL
                           , 'Exception'
                           ,    'Execption in create_header_attach procedure'
                             || SQLERRM
                            );
   END create_header_attach;

--********************************************************************************************
   FUNCTION get_price_list_id (
      p_ship_to_id    IN   NUMBER
    , p_item_id       IN   NUMBER
    , p_customer_id   IN   NUMBER
    , p_org_id        IN   NUMBER
   )
      RETURN NUMBER
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 11-APRIL-2012
Filename       :
Description    : Procedure to return Price List ID.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
11-Apr-2012   1.0       IBM Technical Team         Initial development.
*/
--------------------------------------------------------------------------------
      x_price_list      NUMBER;
      l_price_list      NUMBER;
      indx              NUMBER        := 0;
      l_context         VARCHAR2 (30)
                := xx_emf_pkg.get_paramater_value ('XXOMEXT036PL', 'CONTEXT');
      l_inv_cat         VARCHAR2 (30)
            := xx_emf_pkg.get_paramater_value ('XXOMEXT036PL', 'INV_CAT_SET');
      l_sales_mkt_cat   VARCHAR2 (30)
         := xx_emf_pkg.get_paramater_value ('XXOMEXT036PL'
                                          , 'SALES_MKT_CAT_SET'
                                           );

      CURSOR ship_to_csr
      IS
         SELECT qh.list_header_id
           FROM hz_cust_site_uses_all hcsu
              , qp_list_headers qh
              , qp_list_lines ql
              , qp_pricing_attributes qpa
          WHERE hcsu.site_use_id = p_ship_to_id
            AND hcsu.site_use_code = 'SHIP_TO'
            AND hcsu.status = 'A'
            AND hcsu.price_list_id = qh.list_header_id
            AND qh.list_type_code = 'PRL'
            AND SYSDATE BETWEEN NVL (qh.start_date_active, SYSDATE)
                            AND NVL (qh.end_date_active, SYSDATE + 1)
            AND ql.list_line_type_code = 'PLL'
            AND qh.list_header_id = ql.list_header_id
            AND SYSDATE BETWEEN NVL (ql.start_date_active, SYSDATE)
                            AND NVL (ql.end_date_active, SYSDATE + 1)
            AND ql.list_line_id = qpa.list_line_id
            AND qh.list_header_id = qpa.list_header_id
            AND qpa.product_attribute_context = 'ITEM'
            AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
            AND qpa.product_attr_value = p_item_id;

      CURSOR price_list_csr
      IS
         SELECT DISTINCT qh.list_header_id
                       , qh.NAME
                       , ql.product_precedence
                       , obh.order_number
                    FROM qp_list_headers qh
                       , qp_pricing_attributes qpa
                       , qp_list_lines ql
                       , oe_blanket_headers_all obh
                       , oe_blanket_headers_ext bhe
                   WHERE qh.list_header_id = obh.price_list_id
                     AND obh.org_id = p_org_id
                     AND (qh.global_flag = 'Y' OR qh.orig_org_id = p_org_id)
                     AND obh.order_number = bhe.order_number
                     AND SYSDATE BETWEEN NVL (bhe.start_date_active, SYSDATE)
                                     AND NVL (bhe.end_date_active, SYSDATE)
                     AND obh.sold_to_org_id = p_customer_id
                     AND obh.open_flag = 'Y'
                     AND obh.cancelled_flag IS NULL
                     AND qh.CONTEXT = l_context         --'Price List Details'
                     AND UPPER (qh.attribute4) IN (
                            SELECT DISTINCT UPPER (segment6)
                                       FROM mtl_item_categories_v
                                      WHERE category_set_name IN
                                                 (l_inv_cat, l_sales_mkt_cat)
                                        --('Inventory','Sales and Marketing')
                                        AND inventory_item_id = p_item_id
                                        AND organization_id IN (
                                               SELECT DISTINCT master_organization_id
                                                          FROM mtl_parameters))
                     AND qh.list_type_code = 'PRL'
                     AND ql.list_line_type_code = 'PLL'
                     AND qpa.product_attribute_context = 'ITEM'
                     AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
                     AND SYSDATE BETWEEN NVL (qh.start_date_active, SYSDATE)
                                     AND NVL (qh.end_date_active, SYSDATE + 1)
                     AND SYSDATE BETWEEN NVL (ql.start_date_active, SYSDATE)
                                     AND NVL (ql.end_date_active, SYSDATE + 1)
                     AND qh.list_header_id = qpa.list_header_id
                     AND qpa.product_attr_value = p_item_id
                     AND qh.list_header_id = ql.list_header_id
                     AND ql.list_line_id = qpa.list_line_id
                ORDER BY ql.product_precedence
                       , obh.order_number;
   BEGIN
      p_price_list_table.DELETE;

      IF NVL (p_customer_id, -99) <> -99
      THEN
         OPEN ship_to_csr;

         FETCH ship_to_csr
          INTO x_price_list;

         CLOSE ship_to_csr;

         IF x_price_list IS NULL
         THEN
            FOR i IN price_list_csr
            LOOP
               indx := indx + 1;
               p_price_list_table (indx).list_header_id := i.list_header_id;
               p_price_list_table (indx).NAME := i.NAME;
               p_price_list_table (indx).product_precedence :=
                                                         i.product_precedence;
               p_price_list_table (indx).order_number := i.order_number;
            END LOOP;
         END IF;

         IF x_price_list IS NOT NULL
         THEN
            l_price_list := x_price_list;
         ELSE
            l_price_list := p_price_list_table (1).list_header_id;
         END IF;
      ELSE
         l_price_list := NULL;
      END IF;

      RETURN l_price_list;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_price_list_id;

--********************************************************************************************
   PROCEDURE order_type_validation (
      p_order_type   IN       VARCHAR2
    , p_header_id    IN       NUMBER
    , p_oe_status    OUT      VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
 /*
 Created By     : IBM Technical Team
 Creation Date  : 11-APRIL-2012
 Filename       :
 Description    : Procedure to validate order type.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 11-Apr-2012   1.0       IBM Technical Team         Initial development.
 09-May-2013   1.1       Bedabrata Bhattacharjee    Added RO and CN order type
 */
 --------------------------------------------------------------------------------
   BEGIN
      IF p_order_type IS NULL
      THEN
         DBMS_OUTPUT.put_line ('test1');
         p_oe_status := g_failed_msg;
         xx_oe_error_insert (p_header_id
                           , NULL
                           , 'Header Level Validation'
                           , 'Order Type can not be null'
                            );
      ELSE
         DBMS_OUTPUT.put_line ('test2');

         IF p_order_type NOT IN
                    ('SA', 'DS', 'NE', 'RO', 'CN') -- RO and CN added for GHX
         THEN
            p_oe_status := g_failed_msg;
            xx_oe_error_insert
                           (p_header_id
                          , NULL
                          , 'Header Level Validation'
                          , 'Order Type is other than SA , NE, DS, RO and CN'
                           );
            DBMS_OUTPUT.put_line ('test3');
         END IF;
      END IF;
   END order_type_validation;

--********************************************************************************************
   PROCEDURE xx_oe_create (
      p_oe_header   IN       xx_oe_order_hdr_objtyp
    , p_oe_line     IN       xx_oe_order_line_tabtyp
    , p_oe_status   OUT      VARCHAR2
    , p_err_msg     OUT      VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 11-APRIL-2012
Filename       :
Description    : Procedure to create sales order by Oracle API.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
11-Apr-2012   1.0       IBM Technical Team         Initial development.
07-May-2013   1.1       IBM Technical Team         Changes for GHX
*/
--------------------------------------------------------------------------------
      g_file_type                    VARCHAR2 (10);
      l_order_source_id              oe_order_sources.order_source_id%TYPE;
      l_sold_to_org                  hz_cust_accounts.account_number%TYPE;
      l_sold_to_org_id               hz_cust_accounts.cust_account_id%TYPE;
      l_party_id                     hz_parties.party_id%TYPE;
      l_ship_to_site_id              hz_cust_site_uses_all.site_use_id%TYPE;
      l_ship_to_cust_acct_site_id    hz_cust_site_uses_all.cust_acct_site_id%TYPE;
      l_country                      hz_locations.country%TYPE;
      l_payment_term_id              hz_cust_site_uses_all.payment_term_id%TYPE;
      l_bill_to_site_id              hz_cust_site_uses_all.site_use_id%TYPE;
      l_order_type                   VARCHAR2 (30);
      l_organization_code            hr_operating_units.NAME%TYPE;
      l_order_type_id                oe_transaction_types_tl.transaction_type_id%TYPE;
      l_org_id                       hr_operating_units.organization_id%TYPE;
      l_deliver_to_loc               hz_location_v2pub.location_rec_type;
      l_person_rec                   hz_party_v2pub.person_rec_type;
      p_deliver_to_org_id            NUMBER;
      p_deliver_to_contact_id        NUMBER;
      l_inventory_item_id            mtl_system_items_b.inventory_item_id%TYPE;
      l_coc                          hz_cust_acct_sites_all.attribute10%TYPE;
      -----Added Certificate Of Conformance
      p_cust_site_err_msg            VARCHAR2 (4000);
      p_cust_dtls_err_msg            VARCHAR2 (4000);
      e_cust_site_exception          EXCEPTION;
      e_cust_dtls_exception          EXCEPTION;
      ------Sales order Variables----------------
      l_api_version_number           NUMBER                              := 1;
      l_return_status                VARCHAR2 (2000);
      l_msg_count                    NUMBER;
      l_msg_data                     VARCHAR2 (2000);
      l_msg_index_out                NUMBER (10);
      l_no_orders                    NUMBER                              := 1;
                                                              -- NO OF ORDERS
      /*****************INPUT VARIABLES FOR PROCESS_ORDER API*************************/
      l_header_rec                   oe_order_pub.header_rec_type;
      l_line_tbl                     oe_order_pub.line_tbl_type;
      l_action_request_tbl           oe_order_pub.request_tbl_type;
      l_line_adj_tbl                 oe_order_pub.line_adj_tbl_type;
      /*****************OUT VARIABLES FOR PROCESS_ORDER API***************************/
      l_header_rec_out               oe_order_pub.header_rec_type;
      l_header_val_rec_out           oe_order_pub.header_val_rec_type;
      l_header_adj_tbl_out           oe_order_pub.header_adj_tbl_type;
      l_header_adj_val_tbl_out       oe_order_pub.header_adj_val_tbl_type;
      l_header_price_att_tbl_out     oe_order_pub.header_price_att_tbl_type;
      l_header_adj_att_tbl_out       oe_order_pub.header_adj_att_tbl_type;
      l_header_adj_assoc_tbl_out     oe_order_pub.header_adj_assoc_tbl_type;
      l_header_scredit_tbl_out       oe_order_pub.header_scredit_tbl_type;
      l_header_scredit_val_tbl_out   oe_order_pub.header_scredit_val_tbl_type;
      l_line_tbl_out                 oe_order_pub.line_tbl_type;
      l_line_val_tbl_out             oe_order_pub.line_val_tbl_type;
      l_line_adj_tbl_out             oe_order_pub.line_adj_tbl_type;
      l_line_adj_val_tbl_out         oe_order_pub.line_adj_val_tbl_type;
      l_line_price_att_tbl_out       oe_order_pub.line_price_att_tbl_type;
      l_line_adj_att_tbl_out         oe_order_pub.line_adj_att_tbl_type;
      l_line_adj_assoc_tbl_out       oe_order_pub.line_adj_assoc_tbl_type;
      l_line_scredit_tbl_out         oe_order_pub.line_scredit_tbl_type;
      l_line_scredit_val_tbl_out     oe_order_pub.line_scredit_val_tbl_type;
      l_lot_serial_tbl_out           oe_order_pub.lot_serial_tbl_type;
      l_lot_serial_val_tbl_out       oe_order_pub.lot_serial_val_tbl_type;
      l_action_request_tbl_out       oe_order_pub.request_tbl_type;
      l_line_id                      NUMBER;
      l_status_flag                  VARCHAR2 (5)                   := 'TRUE';
--      l_primary_uom_code             VARCHAR2 (5);
--      l_ordered_quantity             NUMBER;
      l_line_item                    VARCHAR2 (100);
      l_ro_ship_priority_code        VARCHAR2 (100)                 := NULL;
      l_ro_ship_method_code          VARCHAR2 (240)                 := NULL;
      l_ds_ghx_addr_segment          VARCHAR2 (240)                 := NULL;
      l_proactive_count              NUMBER                         := 0;
      l_overnight_count              NUMBER                         := 0;
   BEGIN
      ------Assign Global Variables---
      assign_global_var (p_oe_status, p_err_msg);
      DBMS_OUTPUT.put_line ('assign_global_var' || p_oe_status);

      IF p_oe_status = g_failed_msg
      THEN
         l_status_flag := 'FALSE';
         xx_oe_error_insert (p_oe_header.header_id
                           , NULL
                           , 'Header Level Validation'
                           , p_err_msg
                            );
      END IF;

       --File Type Derivation
      /* IF SUBSTR (p_oe_header.orig_sys_document_ref, 1, 3) = g_gxs_file_type
       THEN
          g_file_type := g_gxs_file_type;
       ELSE
          g_file_type := g_ghx_file_type;
       END IF;
      */
      -- New logic for File Source added for GHX
      IF p_oe_header.tp_source = g_ghx_file_type THEN
        g_file_type := p_oe_header.tp_source;
      ELSE
        g_file_type := g_gxs_file_type;
      END IF;

      -----Order Type validation
      DBMS_OUTPUT.put_line (   'order_type_validation before'
                            || p_oe_header.order_type
                           );
      order_type_validation (p_oe_header.order_type
                           , p_oe_header.header_id
                           , p_oe_status
                            );
      DBMS_OUTPUT.put_line ('order_type_validation after' || p_oe_status);

      IF p_oe_status = g_failed_msg
      THEN
         l_status_flag := 'FALSE';
      END IF;

      --Order source Derivation
      BEGIN
         SELECT order_source_id
           INTO l_order_source_id
           FROM oe_order_sources
          WHERE NAME = g_order_source_name || g_file_type;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_oe_status := g_failed_msg;
            l_status_flag := 'FALSE';
            xx_oe_error_insert (p_oe_header.header_id
                              , NULL
                              , 'Header Level Validation'
                              , 'Order Source does not exist'
                               );
         WHEN OTHERS
         THEN
            p_oe_status := g_failed_msg;
            l_status_flag := 'FALSE';
            xx_oe_error_insert
                              (p_oe_header.header_id
                             , NULL
                             , 'Header Level Validation'
                             , 'Unexpected error while fetching Order Source'
                              );
      END;

      --Fetch Customer details
      DBMS_OUTPUT.put_line ('Customer details' || p_oe_header.tp_attribute1);
      DBMS_OUTPUT.put_line (   'Customer details'
                            || p_oe_header.ship_to_customer_number
                           );
      DBMS_OUTPUT.put_line ('Customer details' || p_oe_header.order_type);
      DBMS_OUTPUT.put_line ('Customer details' || p_oe_header.ship_to_state);
      DBMS_OUTPUT.put_line (   'Customer details'
                            || p_oe_header.bill_to_customer_number
                           );

      IF p_oe_header.ship_to_country IS NOT NULL
      THEN
         l_country := p_oe_header.ship_to_country;
      ELSE
         l_country := NULL;
      END IF;

      get_customer_dtls (p_oe_header.tp_attribute1
                       , p_oe_header.ship_to_customer_number
                       , p_oe_header.order_type
                       , g_file_type
                       , p_oe_header.ship_to_state
                       , p_oe_header.bill_to_customer_number
                       , p_oe_header.bt_site_number
                       , p_oe_header.header_id
                       , l_sold_to_org
                       , l_sold_to_org_id
                       , l_party_id
                       , l_ship_to_site_id
                       , l_ship_to_cust_acct_site_id
                       , l_country
                       , l_payment_term_id
                       , l_bill_to_site_id
                       , l_coc
                       ,                 -----Added Certificate Of Conformance
                         p_oe_status
                       , p_cust_dtls_err_msg
                        );
      DBMS_OUTPUT.put_line ('l_sold_to_org_id' || l_sold_to_org_id);
      DBMS_OUTPUT.put_line ('l_ship_to_site_id' || l_ship_to_site_id);
      DBMS_OUTPUT.put_line ('l_country' || l_country);
      DBMS_OUTPUT.put_line ('l_payment_term_id' || l_payment_term_id);
      DBMS_OUTPUT.put_line ('l_bill_to_site_id' || l_bill_to_site_id);
      DBMS_OUTPUT.put_line ('p_oe_status' || p_oe_status);

      --For Error customer details fetch
      IF p_oe_status = g_failed_msg
      THEN
         l_status_flag := 'FALSE';
      END IF;

      --Derive Order Type, Organization Code based on Country
      --IF l_country = 'US' THEN

      -- Logic for Consignment Orders
      IF p_oe_header.order_type = 'CN'
      THEN
         l_order_type := g_cn_order_type;
      ELSE
         l_order_type := g_sa_order_type;
      END IF;

      l_organization_code := g_sa_organization_code;
      DBMS_OUTPUT.put_line ('l_order_type' || l_order_type);
      DBMS_OUTPUT.put_line ('l_organization_code ' || l_organization_code);

      /* ELSE
         l_order_type        := g_int_order_type;
         l_organization_code := g_int_organization_code;
       END IF;*/

      --Get Order Type id
      BEGIN
         SELECT ott.transaction_type_id
           INTO l_order_type_id
           FROM oe_transaction_types_tl ott
          WHERE ott.NAME = l_order_type
            AND ROWNUM = 1
            AND ott.LANGUAGE = USERENV ('LANG');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_oe_status := g_failed_msg;
            l_status_flag := 'FALSE';
            xx_oe_error_insert (p_oe_header.header_id
                              , NULL
                              , 'Header Level Validation'
                              , 'Order Type does not exist'
                               );
         WHEN OTHERS
         THEN
            p_oe_status := g_failed_msg;
            l_status_flag := 'FALSE';
            xx_oe_error_insert (p_oe_header.header_id
                              , NULL
                              , 'Header Level Validation'
                              , 'Unexpected error while fetching Order Type'
                               );
      END;

      DBMS_OUTPUT.put_line ('l_order_type_id' || l_order_type_id);

      --Derive Org ID
      BEGIN
         SELECT organization_id
           INTO l_org_id
           FROM hr_operating_units
          WHERE UPPER (NAME) = UPPER (l_organization_code);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_oe_status := g_failed_msg;
            l_status_flag := 'FALSE';
            xx_oe_error_insert (p_oe_header.header_id
                              , NULL
                              , 'Header Level Validation'
                              , 'Organization Code does not exist'
                               );
         WHEN OTHERS
         THEN
            p_oe_status := g_failed_msg;
            l_status_flag := 'FALSE';
            xx_oe_error_insert
                           (p_oe_header.header_id
                          , NULL
                          , 'Header Level Validation'
                          , 'Unexpected error while fetching Organization Id'
                           );
      END;

      --For DropShip Order Type, Deliver-To address creation block
      IF p_oe_header.order_type = 'DS'
      THEN
         --New Deliver To Adress assignments
         l_deliver_to_loc.address1 := p_oe_header.deliver_to_address1;
         l_deliver_to_loc.address2 := p_oe_header.deliver_to_address2;
        -- l_deliver_to_loc.address3 := p_oe_header.ship_to_address3; -- added for case#002724
         l_deliver_to_loc.city := p_oe_header.ship_to_city;
         l_deliver_to_loc.state := p_oe_header.ship_to_state;
         l_deliver_to_loc.postal_code := p_oe_header.ship_to_postal_code;
         l_deliver_to_loc.country := l_country;

         IF p_oe_header.ship_to_address3 IS NOT NULL THEN -- added for case#002724
         l_person_rec.person_last_name := p_oe_header.ship_to_address3||', '||p_oe_header.attribute1; -- added for case#002724
         ELSE-- added for case#002724
         l_person_rec.person_last_name := p_oe_header.attribute1; -- added for case#002724
         END IF;-- added for case#002724
         l_person_rec.created_by_module := g_created_by_module;

         -- Segment to store full address for GHX DS orders and not create them
         IF g_file_type = g_ghx_file_type THEN  -- GHX
          BEGIN
            SELECT SUBSTR (   DECODE (p_oe_header.deliver_to_address2
                                    , NULL, p_oe_header.deliver_to_address1
                                    , p_oe_header.deliver_to_address1 || ', '
                                     )
                           || DECODE (p_oe_header.ship_to_city
                                    , NULL, p_oe_header.deliver_to_address2
                                    , p_oe_header.deliver_to_address2 || ', '
                                     )
                           || DECODE (p_oe_header.ship_to_state
                                    , NULL, p_oe_header.ship_to_city
                                    , p_oe_header.ship_to_city || ', '
                                     )
                           || DECODE (p_oe_header.ship_to_postal_code
                                    , NULL, p_oe_header.ship_to_state
                                    , p_oe_header.ship_to_state || ', '
                                     )
                           || DECODE (l_country
                                    , NULL, p_oe_header.ship_to_postal_code
                                    , p_oe_header.ship_to_postal_code || ', '
                                     )
                           || l_country
                         , 1
                         , 240
                          )
              INTO l_ds_ghx_addr_segment
              FROM DUAL;
          EXCEPTION
            WHEN OTHERS THEN
             l_ds_ghx_addr_segment := NULL;
          END;
         END IF;

         DBMS_OUTPUT.put_line (   'l_deliver_to_loc.address1'
                               || l_deliver_to_loc.address1
                              );
         DBMS_OUTPUT.put_line (   'l_deliver_to_loc.address2'
                               || l_deliver_to_loc.address2
                              );
         DBMS_OUTPUT.put_line ('l_deliver_to_loc.city'
                               || l_deliver_to_loc.city
                              );
         DBMS_OUTPUT.put_line (   'l_deliver_to_loc.state'
                               || l_deliver_to_loc.state
                              );
         DBMS_OUTPUT.put_line (   'l_deliver_to_loc.postal_code'
                               || l_deliver_to_loc.postal_code
                              );
         DBMS_OUTPUT.put_line (   'l_deliver_to_loc.country '
                               || l_deliver_to_loc.country
                              );
         DBMS_OUTPUT.put_line (   'l_person_rec.person_last_name'
                               || l_person_rec.person_last_name
                              );
        IF g_file_type = g_gxs_file_type THEN -- other than GHX
         create_cust_site_contact (l_sold_to_org_id
                                 , l_party_id
                                 , l_org_id
                                 , 'DELIVER_TO'
                                 , l_person_rec
                                 , l_deliver_to_loc
                                 , p_oe_header.header_id
                                 , p_deliver_to_org_id
                                 , p_deliver_to_contact_id
                                 , p_oe_status
                                 , p_err_msg
                                  );
         DBMS_OUTPUT.put_line ('p_deliver_to_org_id' || p_deliver_to_org_id);
         DBMS_OUTPUT.put_line (   'p_deliver_to_contact_id'
                               || p_deliver_to_contact_id
                              );
         DBMS_OUTPUT.put_line ('p_oe_status' || p_oe_status);
         DBMS_OUTPUT.put_line ('p_err_msg' || p_err_msg);

         --For Error in Deliver-To Address creation
         IF p_oe_status = g_failed_msg
         THEN
            l_status_flag := 'FALSE';
            p_oe_status := g_failed_msg;
            p_err_msg := NULL;
            xx_oe_error_insert
                    (p_oe_header.header_id
                   , NULL
                   , 'Header Level Validation'
                   ,    'New Deliver To address creation failed. Exception: '
                     || p_err_msg
                    );
         END IF;
        END IF;
      END IF;                                                         --DS end

      -- Added for GHX for Rush (RO) Orders

      -- Logic for Rush Orders
      IF p_oe_header.order_type = 'RO'
      THEN
          --  determine ship method code
           IF p_oe_header.service_level_code IS NOT NULL THEN
             BEGIN
                SELECT ship_method_code
                  INTO l_ro_ship_method_code
                  FROM wsh_carrier_services
                 WHERE attribute2 = p_oe_header.service_level_code
                   AND enabled_flag = 'Y'
                   AND ROWNUM = 1;

             EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                   p_oe_status := g_failed_msg;
                   l_status_flag := 'FALSE';
                   xx_oe_error_insert
                      (p_oe_header.header_id
                     , NULL
                     , 'Header Level Validation'
                     , 'Service Level Code is not Setup propely in Ship Methods for Rush Order'
                      );
                WHEN OTHERS
                THEN
                   p_oe_status := g_failed_msg;
                   l_status_flag := 'FALSE';
                   xx_oe_error_insert
                         (p_oe_header.header_id
                        , NULL
                        , 'Header Level Validation'
                        , 'Unexpected error while setting Shipment Method Code'
                         );
             END;
           END IF;

         -- derive Shipment Priority Code
         BEGIN
            SELECT lookup_code
              INTO l_ro_ship_priority_code
              FROM oe_lookups
             WHERE lookup_type = 'SHIPMENT_PRIORITY'
               AND enabled_flag = 'Y'
               AND meaning = g_ro_ship_priority_code
               AND NVL (end_date_active, SYSDATE + 1) >= SYSDATE;

         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_oe_status := g_failed_msg;
               l_status_flag := 'FALSE';
               xx_oe_error_insert
                  (p_oe_header.header_id
                 , NULL
                 , 'Header Level Validation'
                 , 'Shipment Priority Code is not Setup propely for RO Order'
                  );
            WHEN OTHERS
            THEN
               p_oe_status := g_failed_msg;
               l_status_flag := 'FALSE';
               xx_oe_error_insert
                     (p_oe_header.header_id
                    , NULL
                    , 'Header Level Validation'
                    , 'Unexpected error while setting Shipment Priority Code'
                     );
         END;
      END IF;


      -------------- Sales order API---------------------------
      BEGIN
         mo_global.init ('ONT');
         DBMS_APPLICATION_INFO.set_client_info (l_org_id);
         mo_global.set_policy_context ('S', l_org_id);
         /*****************INITIALIZE HEADER RECORD******************************/
         l_header_rec := oe_order_pub.g_miss_header_rec;
         /*****************POPULATE REQUIRED ATTRIBUTES **********************************/
         l_header_rec := oe_order_pub.g_miss_header_rec;
         l_header_rec.operation := oe_globals.g_opr_create;
         l_header_rec.order_type_id := l_order_type_id;
         l_header_rec.orig_sys_document_ref :=
                                            p_oe_header.orig_sys_document_ref;
         l_header_rec.sold_to_org_id := l_sold_to_org_id;
         l_header_rec.ship_to_org_id := l_ship_to_site_id;
         l_header_rec.invoice_to_org_id := l_bill_to_site_id;
         l_header_rec.deliver_to_org_id := NVL (p_deliver_to_org_id, NULL);

         -- Addition for GHX
         IF l_ro_ship_priority_code IS NOT NULL
         THEN
           l_header_rec.shipment_priority_code := l_ro_ship_priority_code;
         END IF;
         -- Ship method code for Rush Order
         IF (l_ro_ship_method_code IS NOT NULL)
         THEN
           l_header_rec.shipping_method_code := l_ro_ship_method_code;
         END IF;
         l_header_rec.deliver_to_contact_id :=
                                          NVL (p_deliver_to_contact_id, NULL);
         l_header_rec.order_source_id := l_order_source_id;
         --l_header_rec.booked_flag           := 'Y';
         --   l_header_rec.price_list_id := nvl(l_price_list_id, NULL);
         l_header_rec.pricing_date := SYSDATE;
         l_header_rec.request_date := NVL (p_oe_header.request_date, SYSDATE);
         l_header_rec.ordered_date := NVL (p_oe_header.ordered_date, SYSDATE);
         l_header_rec.attribute1 := NVL (p_oe_header.buyer_name, NULL);
         l_header_rec.attribute2 := NVL (p_oe_header.contact_num, NULL);
         l_header_rec.attribute5 := NVL (p_oe_header.end_cust_po_num, NULL);
         l_header_rec.attribute10 := l_coc;

                                        -----Added Certificate Of Conformance
         IF p_oe_header.ship_to_address3 IS NOT NULL THEN-- added for case#002724
         l_header_rec.attribute20 := p_oe_header.ship_to_address3||', '||p_oe_header.attribute1; -- added for case#002724
         ELSE-- added for case#002724
         l_header_rec.attribute20 := p_oe_header.attribute1; -- added for case#002724
         END IF;-- added for case#002724
         IF g_file_type = g_ghx_file_type THEN -- GHX
         l_header_rec.tp_context := g_hdr_tp_context; -- Set TP Context as shipping
         l_header_rec.tp_attribute6 := l_ds_ghx_addr_segment;
         l_header_rec.tp_attribute7 := p_oe_header.tp_attribute7; -- Release Number
         l_header_rec.tp_attribute8 := p_oe_header.tp_attribute8; -- Vendor Number
         END IF;

         --l_header_rec.transactional_curr_code := l_transactional_curr_code;
         --l_header_rec.flow_status_code := 'BOOKED';
         l_header_rec.payment_term_id := l_payment_term_id;
         l_header_rec.cust_po_number := p_oe_header.customer_po_number;
         l_header_rec.sales_channel_code := g_sales_channel;
         /*****************INITIALIZE ACTION REQUEST RECORD*************************************/
         l_action_request_tbl (1).request_type := oe_globals.g_book_order;
         l_action_request_tbl (1).entity_code := oe_globals.g_entity_header;

         /*****************INITIALIZE LINE RECORD********************************/

         --Looping through lines
         FOR i IN p_oe_line.FIRST .. p_oe_line.LAST
         LOOP
            ------------Derive Inventory Item---------------------
            l_line_id := p_oe_line (i).line_id;
--            l_primary_uom_code := NULL;
--            l_ordered_quantity := 0;
            l_line_item         := NULL;
            l_inventory_item_id := NULL;

            --Check for Product Qualifier1 Value (Integra Item)
            IF p_oe_line (i).product_qlf1 IS NOT NULL
            THEN
               BEGIN
                --- Check with Integra Item
                  SELECT DISTINCT msi.inventory_item_id
--                                , msi.primary_uom_code        -- Added for GHX
                                , msi.segment1                -- Added for GHX
                             INTO l_inventory_item_id
--                                , l_primary_uom_code
                                , l_line_item
                             FROM mtl_system_items_b msi
                            WHERE UPPER(msi.segment1) = UPPER(p_oe_line (i).product_val1);
               EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                    --- For GHX Check again with Striping the special characters
                  IF g_file_type = g_ghx_file_type THEN

                   BEGIN
                     --- Check with Integra Item
                     SELECT
                   DISTINCT msi.inventory_item_id
--                          , msi.primary_uom_code        -- Added for GHX
                          , msi.segment1                -- Added for GHX
                       INTO l_inventory_item_id
--                          , l_primary_uom_code
                          , l_line_item
                       FROM mtl_system_items_b msi
                      WHERE UPPER(msi.segment1) = UPPER(replace(translate(p_oe_line (i).product_val1,'~`!@#$%^*()-_=+[{]}\|;:.,<>/"?',' '),' '));
                   EXCEPTION
                    WHEN OTHERS THEN
                     NULL;
                   END;

                  END IF;


                     -----------If Integra Item does not exits then find out Customer item-----------------------
                     IF ((p_oe_line (i).product_qlf2 IS NOT NULL) AND (l_inventory_item_id IS NULL))
                     THEN
                        DBMS_OUTPUT.put_line ('11');

                        BEGIN
                           SELECT DISTINCT mcix.inventory_item_id
--                                         , msi.primary_uom_code -- Added for GHX
                           ,               msi.segment1       -- Added for GHX
                                      INTO l_inventory_item_id
--                                         , l_primary_uom_code
                                         , l_line_item
                                      FROM mtl_customer_item_xrefs_v mcix
                                         , mtl_system_items_b msi
                                     -- Added for GHX
                           WHERE           UPPER(customer_item_number) =
                                                    UPPER(p_oe_line (i).product_val2)
                                       AND mcix.inventory_item_id =
                                                         msi.inventory_item_id;
                        EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN

                        --- For GHX Check again with Striping the special characters
                         IF g_file_type = g_ghx_file_type THEN

                          BEGIN
                           -- Check for Customer Items
                           SELECT DISTINCT mcix.inventory_item_id
--                                         , msi.primary_uom_code -- Added for GHX
                           ,               msi.segment1       -- Added for GHX
                                      INTO l_inventory_item_id
--                                         , l_primary_uom_code
                                         , l_line_item
                                      FROM mtl_customer_item_xrefs_v mcix
                                         , mtl_system_items_b msi
                                     WHERE UPPER(customer_item_number) = UPPER(replace(translate(p_oe_line (i).product_val2,'~`!@#$%^*()-_=+[{]}\|;:.,<>/"?',' '),' '))
                                       AND mcix.inventory_item_id = msi.inventory_item_id;

                          EXCEPTION
                          WHEN NO_DATA_FOUND
                          THEN

                             --- Check Generic Xref Data for Customer Item
                              BEGIN
                                    SELECT DISTINCT xref.inventory_item_id
--                                         , xref.primary_uom_code -- Added for GHX
                                          , xref.segment1
                                       INTO l_inventory_item_id
--                                         , l_primary_uom_code
                                          , l_line_item
                                       FROM
                                    (SELECT mcr.inventory_item_id
--                                         , msi.primary_uom_code -- Added for GHX
                           ,               msi.segment1       -- Added for GHX
                                      FROM mtl_cross_references mcr
                                         , mtl_system_items_b msi
                                     WHERE UPPER(mcr.cross_reference) = UPPER(p_oe_line (i).product_val2)
                                       AND mcr.inventory_item_id = msi.inventory_item_id
                                       UNION ALL
                                    SELECT mcr.inventory_item_id
--                                         , msi.primary_uom_code -- Added for GHX
                           ,               msi.segment1       -- Added for GHX
                                      FROM mtl_cross_references mcr
                                         , mtl_system_items_b msi
                                     WHERE UPPER(mcr.cross_reference) = UPPER(replace(translate(p_oe_line (i).product_val2,'~`!@#$%^*()-_=+[{]}\|;:.,<>/"?',' '),' '))
                                       AND mcr.inventory_item_id = msi.inventory_item_id) xref;


                              EXCEPTION
                              WHEN OTHERS THEN
                                l_inventory_item_id := NULL;
                              END;

                          WHEN OTHERS THEN
                             l_inventory_item_id := NULL;
                          END;

                         ELSE
                          p_oe_status := g_failed_msg;
                          l_status_flag := 'FALSE';
                          xx_oe_error_insert
                             (p_oe_header.header_id
                            , l_line_id
                            , 'Line Validation Error'
                            ,    'Customer Item does not exist, Item No -'
                              || p_oe_line (i).product_val2
                             );
                         END IF;

                        WHEN OTHERS
                        THEN
                              p_oe_status := g_failed_msg;
                              l_status_flag := 'FALSE';
                              xx_oe_error_insert
                                 (p_oe_header.header_id
                                , l_line_id
                                , 'Line Validation Error'
                                ,    'Unexpected error while fetching Customer Item No- '
                                  || p_oe_line (i).product_val2
                                 );
                        END;
                     ELSE
                       IF g_file_type = g_gxs_file_type THEN
                        p_oe_status := g_failed_msg;
                        l_status_flag := 'FALSE';
                        xx_oe_error_insert
                                 (p_oe_header.header_id
                                , l_line_id
                                , 'Line Validation Error'
                                ,    'Integra Item does not exist, Item No -'
                                  || p_oe_line (i).product_val1
                                 );
                        DBMS_OUTPUT.put_line ('14');
                       END IF;
                     END IF;
               WHEN OTHERS
               THEN
                     p_oe_status := g_failed_msg;
                     l_status_flag := 'FALSE';
                     xx_oe_error_insert
                              (p_oe_header.header_id
                             , l_line_id
                             , 'Line Validation Error'
                             ,    'Unexpected error while fetching Item No -'
                               || p_oe_line (i).product_val1
                              );
               END;
            ELSE
               BEGIN
                  SELECT DISTINCT mcix.inventory_item_id
--                                , msi.primary_uom_code        -- Added for GHX
                                , msi.segment1                -- Added for GHX
                             INTO l_inventory_item_id
--                                , l_primary_uom_code
                                , l_line_item
                             FROM mtl_customer_item_xrefs_v mcix
                                , mtl_system_items_b msi      -- Added for GHX
                            WHERE UPPER(customer_item_number) =
                                                    UPPER(p_oe_line (i).product_val2)
                              AND mcix.inventory_item_id =
                                                         msi.inventory_item_id;
               EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  --- For GHX Check again with Striping the special characters
                  IF p_oe_header.tp_source = g_ghx_file_type THEN
                    BEGIN
                    -- Check for Customer Items
                     SELECT DISTINCT mcix.inventory_item_id
--                                   , msi.primary_uom_code -- Added for GHX
                          , msi.segment1       -- Added for GHX
                       INTO l_inventory_item_id
--                          , l_primary_uom_code
                          , l_line_item
                       FROM mtl_customer_item_xrefs_v mcix
                          , mtl_system_items_b msi
                      WHERE UPPER(customer_item_number) = UPPER(replace(translate(p_oe_line (i).product_val2,'~`!@#$%^*()-_=+[{]}\|;:.,<>/"?',' '),' '))
                        AND mcix.inventory_item_id = msi.inventory_item_id;

                    EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN

                            --- Check Generic Xref Data for Customer Item
                              BEGIN
                                    SELECT DISTINCT xref.inventory_item_id
--                                         , xref.primary_uom_code -- Added for GHX
                                          , xref.segment1
                                       INTO l_inventory_item_id
--                                         , l_primary_uom_code
                                          , l_line_item
                                       FROM
                                    (SELECT mcr.inventory_item_id
--                                         , msi.primary_uom_code -- Added for GHX
                           ,               msi.segment1       -- Added for GHX
                                      FROM mtl_cross_references mcr
                                         , mtl_system_items_b msi
                                     WHERE UPPER(mcr.cross_reference) = UPPER(p_oe_line (i).product_val2)
                                       AND mcr.inventory_item_id = msi.inventory_item_id
                                       UNION ALL
                                    SELECT mcr.inventory_item_id
--                                         , msi.primary_uom_code -- Added for GHX
                           ,               msi.segment1       -- Added for GHX
                                      FROM mtl_cross_references mcr
                                         , mtl_system_items_b msi
                                     WHERE UPPER(mcr.cross_reference) = UPPER(replace(translate(p_oe_line (i).product_val2,'~`!@#$%^*()-_=+[{]}\|;:.,<>/"?',' '),' '))
                                       AND mcr.inventory_item_id = msi.inventory_item_id) xref;


                              EXCEPTION
                              WHEN OTHERS THEN
                                l_inventory_item_id := NULL;
                              END;

                    WHEN OTHERS THEN
                     l_inventory_item_id := NULL;
                    END;
                  ELSE
                     p_oe_status := g_failed_msg;
                     l_status_flag := 'FALSE';
                     xx_oe_error_insert
                                (p_oe_header.header_id
                               , l_line_id
                               , 'Line Validation Error'
                               ,    'Customer Item does not exist, Item No -'
                                 || p_oe_line (i).product_val2
                          );
                  END IF;

               WHEN OTHERS
               THEN
                 p_oe_status := g_failed_msg;
                 l_status_flag := 'FALSE';
                 xx_oe_error_insert
                    (p_oe_header.header_id
                   , l_line_id
                   , 'Line Validation Error'
                   , 'Unexpected error while fetching Customer Item No- '
                     || p_oe_line (i).product_val2
                    );
               END;
            ------
            END IF;

            --- Check for GHX if Item found or not, if not found use EDIINVALID item
            IF (p_oe_header.tp_source = g_ghx_file_type) AND (l_inventory_item_id IS NULL) THEN
             BEGIN
                  SELECT DISTINCT msi.inventory_item_id
--                                , msi.primary_uom_code        -- Added for GHX
                                , msi.segment1                -- Added for GHX
                             INTO l_inventory_item_id
--                                , l_primary_uom_code
                                , l_line_item
                             FROM mtl_system_items_b msi
                            WHERE msi.segment1 = g_ghx_ediinvalid_item;
             EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
                p_oe_status := g_failed_msg;
                l_status_flag := 'FALSE';
                xx_oe_error_insert
                         (p_oe_header.header_id
                        , l_line_id
                        , 'Line Validation Error'
                        , 'Integra Item - '||p_oe_line (i).product_val1||' or Customer Item -'
                          || p_oe_line (i).product_val2
                          || 'does not exist and EDIINVALID Item is also not defined'
                         );
             WHEN OTHERS
             THEN
                p_oe_status := g_failed_msg;
                l_status_flag := 'FALSE';
                xx_oe_error_insert
                   (p_oe_header.header_id
                  , l_line_id
                  , 'Line Validation Error'
                  ,    'Unexpected error while fetching EDIINVALID Item'
                   );
             END;

            END IF;

            --- UOM conversion logic for GHX
/*            IF (    (p_oe_header.tp_source = g_ghx_file_type)          --'GHX'
                AND (l_primary_uom_code IS NOT NULL)
                AND (p_oe_line (i).order_quantity_uom IS NOT NULL)
                AND (l_primary_uom_code <> p_oe_line (i).order_quantity_uom)
               )
            THEN
               BEGIN
                  SELECT (  TO_NUMBER (NVL (attribute3, 1))
                          * (NVL ((p_oe_line (i).ordered_quantity), 0))
                         )
                    INTO l_ordered_quantity
                    FROM fnd_lookup_values
                   WHERE lookup_type = 'INTG_EDI_UOM_CONVERSION'
                     AND description = l_line_item
                     AND tag = p_oe_line (i).order_quantity_uom
                     AND attribute_category = 'EDI'
                     AND attribute2 = l_primary_uom_code
                     AND LANGUAGE = USERENV ('LANG')
                     AND enabled_flag = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     p_oe_status := g_failed_msg;
                     l_status_flag := 'FALSE';
                     xx_oe_error_insert
                        (p_oe_header.header_id
                       , l_line_id
                       , 'Line Validation Error'
                       ,    'UOM Conversion not found in lookup INTG_EDI_UOM_CONVERSION for Item -'
                         || l_line_item
                         || ' and TP UOM '
                         || p_oe_line (i).order_quantity_uom
                         || ' to Integra UOM '
                         || l_primary_uom_code
                        );
                  WHEN OTHERS
                  THEN
                     p_oe_status := g_failed_msg;
                     l_status_flag := 'FALSE';
                     xx_oe_error_insert
                        (p_oe_header.header_id
                       , l_line_id
                       , 'Line Validation Error'
                       ,    'Unexpected error while fetching UOM Conversion for Item -'
                         || l_line_item
                         || ' and TP UOM '
                         || p_oe_line (i).order_quantity_uom
                         || ' to Integra UOM '
                         || l_primary_uom_code
                        );
               END;
            ELSE
               l_ordered_quantity := p_oe_line (i).ordered_quantity;
            END IF;
*/
            --- End of UOM Logic for GHX

            --- Logic for GHX Proactive Flag
            IF (p_oe_header.tp_source = g_ghx_file_type) AND (l_proactive_count = 0)-- For GHX
            THEN
             SELECT count(1)
               INTO l_proactive_count
               FROM fnd_lookup_values
              WHERE lookup_type = 'XX_OM_MANIFEST_PROACTIVE_ITEMS'
                AND enabled_flag = 'Y'
                AND language = USERENV('LANG')
                AND meaning = l_line_item
                AND NVL (end_date_active, SYSDATE + 1) >= SYSDATE;
            END IF;

            --- Logic for GHX Overnight Shippned Items
            IF (g_file_type = g_ghx_file_type) AND (l_overnight_count = 0)-- For GHX
            THEN
             SELECT count(1)
               INTO l_overnight_count
               FROM oe_lookups
              WHERE lookup_type = 'INTG_EDI_GHX_OVERNIGHT_ITEMS'
                AND enabled_flag = 'Y'
                AND meaning = l_line_item
                AND NVL (end_date_active, SYSDATE + 1) >= SYSDATE;
            END IF;

            --- End Logic for GHX Proactive flag
            l_line_tbl (i) := oe_order_pub.g_miss_line_rec;
            l_line_tbl (i).operation := oe_globals.g_opr_create;
            l_line_tbl (i).inventory_item_id := l_inventory_item_id;
            l_line_tbl (i).ordered_quantity := p_oe_line (i).ordered_quantity;
            --l_line_tbl(i).order_quantity_uom := p_oe_line(i).order_quantity_uom;
            l_line_tbl (i).unit_selling_price :=
                                              p_oe_line (i).unit_selling_price;
            -- The price is done using adjustments
            l_line_tbl (i).unit_list_price :=
                                     NVL (p_oe_line (i).unit_list_price, NULL);
            l_line_tbl (i).customer_item_net_price :=
                                              p_oe_line (i).unit_selling_price;
            l_line_tbl (i).tp_context := g_tp_context;
            l_line_tbl (i).tp_attribute1 := p_oe_line (i).order_quantity_uom;
            l_line_tbl (i).customer_line_number := p_oe_line (i).line_number;
            l_line_tbl (i).tp_attribute2 :=
                                        NVL (p_oe_line (i).product_val2, NULL);

           --IF condition added in version 1.6
         IF p_oe_header.shipping_method_type IS NOT NULL THEN
         l_line_tbl (i).shipping_method_code := p_oe_header.shipping_method_type;
         END IF;
           --IF condition added in version 1.6
         IF p_oe_header.shipment_priority_code IS NOT NULL THEN
         l_line_tbl (i).shipment_priority_code := p_oe_header.shipment_priority_code;
         END IF;
            --l_line_tbl(i).booked_flag := 'Y';

            /*Price List logic*/
            -- Case # 5909 : Do not pass price list to API. Beda
            /*l_line_tbl (i).price_list_id :=
               get_price_list_id (l_ship_to_site_id
                                , l_inventory_item_id
                                , l_sold_to_org_id
                                , l_org_id
                                 );
            */
            DBMS_OUTPUT.put_line ('18');
         END LOOP;



         -- Set more Data for GHX Order Header
         IF l_proactive_count > 0 THEN
          l_header_rec.tp_attribute2 := 'Y'; -- Proactive Flag for GHX Items
         END IF;

         -- Overnight Items Logic
         IF (l_overnight_count > 0) THEN

             -- derive Shipment priority Code
             BEGIN
                SELECT lookup_code
                  INTO l_ro_ship_priority_code
                  FROM oe_lookups
                 WHERE lookup_type = 'SHIPMENT_PRIORITY'
                   AND enabled_flag = 'Y'
                   AND meaning = g_ro_ship_priority_code
                   AND NVL (end_date_active, SYSDATE + 1) >= SYSDATE;

             EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                   p_oe_status := g_failed_msg;
                   l_status_flag := 'FALSE';
                   xx_oe_error_insert
                      (p_oe_header.header_id
                     , NULL
                     , 'Header Level Validation'
                     , 'Shipment Priority Code is not Setup propely for Overnight Items'
                      );
                WHEN OTHERS
                THEN
                   p_oe_status := g_failed_msg;
                   l_status_flag := 'FALSE';
                   xx_oe_error_insert
                         (p_oe_header.header_id
                        , NULL
                        , 'Header Level Validation'
                        , 'Unexpected error while setting Shipment Priority Code'
                         );
             END;

          -- Set Ship method and shipment priority
          l_header_rec.shipping_method_code := g_overnight_ship_method; -- Overnight ship method for GHX Items
          l_header_rec.shipment_priority_code := l_ro_ship_priority_code; -- Rush
         END IF;


       --IF condition added in version 1.6
         IF p_oe_header.shipping_method_type IS NOT NULL THEN
         l_header_rec.shipping_method_code := p_oe_header.shipping_method_type;
         END IF;

         --IF condition added in version 1.6
         IF p_oe_header.shipment_priority_code IS NOT NULL THEN
         l_header_rec.shipment_priority_code := p_oe_header.shipment_priority_code;
         END IF;


                  --
         ----Checking status flag------
         IF l_status_flag = 'TRUE'
         THEN

            FOR k IN 1 .. l_no_orders
            LOOP

               /*****************CALLTO PROCESS ORDER API*********************************/
               oe_order_pub.process_order
                   (p_org_id                      => l_org_id
                  , p_operating_unit              => NULL
                  , p_api_version_number          => l_api_version_number
                  , p_header_rec                  => l_header_rec
                  , p_line_tbl                    => l_line_tbl
                  , p_action_request_tbl          => l_action_request_tbl
                  ,
                    -- OUT variables
                    x_header_rec                  => l_header_rec_out
                  , x_header_val_rec              => l_header_val_rec_out
                  , x_header_adj_tbl              => l_header_adj_tbl_out
                  , x_header_adj_val_tbl          => l_header_adj_val_tbl_out
                  , x_header_price_att_tbl        => l_header_price_att_tbl_out
                  , x_header_adj_att_tbl          => l_header_adj_att_tbl_out
                  , x_header_adj_assoc_tbl        => l_header_adj_assoc_tbl_out
                  , x_header_scredit_tbl          => l_header_scredit_tbl_out
                  , x_header_scredit_val_tbl      => l_header_scredit_val_tbl_out
                  , x_line_tbl                    => l_line_tbl_out
                  , x_line_val_tbl                => l_line_val_tbl_out
                  , x_line_adj_tbl                => l_line_adj_tbl_out
                  , x_line_adj_val_tbl            => l_line_adj_val_tbl_out
                  , x_line_price_att_tbl          => l_line_price_att_tbl_out
                  , x_line_adj_att_tbl            => l_line_adj_att_tbl_out
                  , x_line_adj_assoc_tbl          => l_line_adj_assoc_tbl_out
                  , x_line_scredit_tbl            => l_line_scredit_tbl_out
                  , x_line_scredit_val_tbl        => l_line_scredit_val_tbl_out
                  , x_lot_serial_tbl              => l_lot_serial_tbl_out
                  , x_lot_serial_val_tbl          => l_lot_serial_val_tbl_out
                  , x_action_request_tbl          => l_action_request_tbl_out
                  , x_return_status               => l_return_status
                  , x_msg_count                   => l_msg_count
                  , x_msg_data                    => l_msg_data
                   );

            END LOOP;

            FOR i IN 1 .. l_msg_count
            LOOP

               oe_msg_pub.get (p_msg_index          => i
                             , p_encoded            => fnd_api.g_false
                             , p_data               => l_msg_data
                             , p_msg_index_out      => l_msg_index_out
                              );

            END LOOP;

            -- Check the return status
            IF l_return_status = fnd_api.g_ret_sts_success
            THEN

               p_oe_status := g_success_msg;
               p_err_msg := NULL;
            ELSE

               p_oe_status := g_failed_msg;
               l_status_flag := 'FALSE';
               xx_oe_error_insert (p_oe_header.header_id
                                 , NULL
                                 , 'API Error'
                                 , l_msg_data
                                  );
               DBMS_OUTPUT.put_line ('API Error' || l_msg_data);

            END IF;
         END IF;                           ---- IF l_status_flag = 'TRUE' THEN
      EXCEPTION
         WHEN OTHERS
         THEN
            p_oe_status := 'Execption in sales order API block';
            l_status_flag := 'FALSE';
            xx_oe_error_insert (p_oe_header.header_id
                              , NULL
                              , 'API Error'
                              ,    'Exeception in sales order API block'
                                || SQLERRM
                               );
      END;



      -----------------Create header attachment for GHX--------------------------
      IF     p_oe_header.MESSAGE IS NOT NULL
         AND l_status_flag = 'TRUE'
         AND p_oe_header.tp_source = 'GHX'
      THEN
         DBMS_OUTPUT.put_line ('19');
         create_header_attach
                             (l_header_rec_out.header_id
                            , p_oe_header.MESSAGE  --p_oe_header.reference_idn
                            , p_oe_header.header_id
                            , p_oe_status
                            , p_err_msg
                             );

         IF p_oe_status IS NULL
         THEN
            DBMS_OUTPUT.put_line ('20');
            p_oe_status := g_success_msg;
            p_err_msg := NULL;
         ELSE
            DBMS_OUTPUT.put_line ('21');
            p_oe_status := g_failed_msg;
            l_status_flag := 'FALSE';
            xx_oe_error_insert
                         (p_oe_header.header_id
                        , NULL
                        , 'Header Level Validation'
                        ,    'Header Attachment creation failed. Exception: '
                          || p_err_msg
                         );
            DBMS_OUTPUT.put_line ('22');
         END IF;
      END IF;

        --For Error during Customer details fetching
      --ELSE

      --RAISE e_cust_dtls_exception;

      -- END IF;

           ------Cheking status-------
      IF l_status_flag = 'FALSE'
      THEN
         DBMS_OUTPUT.put_line ('23');
         p_oe_status := g_failed_msg;
         p_err_msg := NULL;

         ---Calling to update header table with status
         UPDATE xx_oe_order_ws_in_header_stg hdr
            SET hdr.status = p_oe_status
          WHERE hdr.header_id = p_oe_header.header_id;

         DBMS_OUTPUT.put_line ('24');
      ELSE
         p_oe_status := g_success_msg;
         p_err_msg := NULL;

         ---Calling to update header table with status
         UPDATE xx_oe_order_ws_in_header_stg hdr
            SET hdr.status = p_oe_status
          WHERE hdr.header_id = p_oe_header.header_id;

         DBMS_OUTPUT.put_line ('25');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_oe_status := g_failed_msg;
         p_err_msg := NULL;
         l_status_flag := 'FALSE';
         xx_oe_error_insert
                       (p_oe_header.header_id
                      , NULL
                      , 'Execption'
                      ,    'Exception in xx_oe_create Procedure. Exception: '
                        || SQLERRM
                       );
   END xx_oe_create;

--********************************************************************************************
   PROCEDURE xx_oe_update (
      p_header_id   IN       NUMBER
    , p_status      IN       VARCHAR2
    , p_err_dtls    IN       VARCHAR2
    , p_inst_id     IN       VARCHAR2
    , p_err_msg     OUT      VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 11-APRIL-2012
Filename       :
Description    : Procedure to update sales order header into staging tables.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
11-Apr-2012   1.0       IBM Technical Team         Initial development.
*/
--------------------------------------------------------------------------------
   BEGIN
      UPDATE xx_oe_order_ws_in_header_stg hdr
         SET hdr.status = p_status
           ,
             -- hdr.error_mssg  = p_err_dtls,
             hdr.instance_id = p_inst_id
       WHERE hdr.header_id = p_header_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_err_msg := 'Exception while updating status: ' || SQLERRM;
   END xx_oe_update;

--------------

   --********************************************************************************************
   PROCEDURE xx_oe_error_insert (
      p_header_id     IN   NUMBER
    , p_line_id       IN   NUMBER
    , p_source_type   IN   VARCHAR2
    , p_err_msg       IN   VARCHAR2
   )
   IS
-------------------------------------------------------------------------------
/*
Created By     : IBM Technical Team
Creation Date  : 15-JUN-2012
Filename       :
Description    : Procedure to insert sales order header and line level error records into staging tables.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
15-JUN-2012   1.0       IBM Technical Team         Initial development.
*/
--------------------------------------------------------------------------------
   BEGIN
      DBMS_OUTPUT.put_line ('xx_oe_error_insert inside');

      INSERT INTO xx_oe_order_ws_in_error_stg
                  (header_id
                 , line_id
                 , source_type
                 , error_mssg
                 , creation_date
                 , last_update_date
                  )
           VALUES (p_header_id
                 , p_line_id
                 , p_source_type
                 , p_err_msg
                 , SYSDATE
                 , SYSDATE
                  );
   --commit;
   EXCEPTION
      WHEN OTHERS
      THEN
         --NULL;
         DBMS_OUTPUT.put_line ('xx_oe_error_insert inside exception'
                               || SQLERRM
                              );
   END xx_oe_error_insert;
--------------
END xx_oe_order_ws_in_pkg;
/
