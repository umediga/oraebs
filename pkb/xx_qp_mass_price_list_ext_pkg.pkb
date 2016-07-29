DROP PACKAGE BODY APPS.XX_QP_MASS_PRICE_LIST_EXT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xx_qp_mass_price_list_ext_pkg AS
  ----------------------------------------------------------------------
  /*
   Created By     : IBM Development Team
   Creation Date  : 20-SEP-2013
   File Name      : XXQPMASSPRICELISTEXT.pkb
   Description    : This script creates the body of the package xx_qp_mass_price_list_ext_pkg


  Change History:

  Version Date          Name                       Remarks
  ------- -----------   --------                   -------------------------------
  1.0     20-Sep-2013   IBM Development Team       Initial development.
  */
  ----------------------------------------------------------------------
  /**************************************************************************************
  *
  *   PROCEDURE
  *     update_price_list
  *
  *   DESCRIPTION
  *   Update or add new Price List line
  *
  **************************************************************************************/
  FUNCTION update_price_list(p_list_type          IN VARCHAR2,  --new
                             p_list_name          IN VARCHAR2,
                             p_product_attribute  IN VARCHAR2, --new
                             p_product_value      IN VARCHAR2, --mod
                             p_appl_method        IN VARCHAR2, --new
                             p_price              IN VARCHAR2,
                             p_start_date         IN DATE,
                             p_end_date           IN DATE,
                             p_precedence         IN VARCHAR2,
                             p_price_protect_flag IN VARCHAR2,
                             p_record_type        IN VARCHAR2,  --new
                             p_uom                IN VARCHAR2,
                             p_pricing_phase_id   IN NUMBER
                            ) RETURN VARCHAR IS


    gpr_price_list_rec          qp_price_list_pub.price_list_rec_type;
    gpr_price_list_val_rec      qp_price_list_pub.price_list_val_rec_type;
    gpr_price_list_line_tbl     qp_price_list_pub.price_list_line_tbl_type;
    gpr_price_list_line_val_tbl qp_price_list_pub.price_list_line_val_tbl_type;
    gpr_qualifiers_tbl          qp_qualifier_rules_pub.qualifiers_tbl_type;
    gpr_qualifiers_val_tbl      qp_qualifier_rules_pub.qualifiers_val_tbl_type;
    gpr_pricing_attr_tbl        qp_price_list_pub.pricing_attr_tbl_type;
    gpr_pricing_attr_val_tbl    qp_price_list_pub.pricing_attr_val_tbl_type;
    ppr_price_list_rec          qp_price_list_pub.price_list_rec_type;
    ppr_price_list_val_rec      qp_price_list_pub.price_list_val_rec_type;
    ppr_price_list_line_tbl     qp_price_list_pub.price_list_line_tbl_type;
    ppr_price_list_line_val_tbl qp_price_list_pub.price_list_line_val_tbl_type;
    ppr_qualifier_rules_rec     qp_qualifier_rules_pub.qualifier_rules_rec_type;
    ppr_qualifier_rules_val_rec qp_qualifier_rules_pub.qualifier_rules_val_rec_type;
    ppr_qualifiers_tbl          qp_qualifier_rules_pub.qualifiers_tbl_type;
    ppr_qualifiers_val_tbl      qp_qualifier_rules_pub.qualifiers_val_tbl_type;
    ppr_pricing_attr_tbl        qp_price_list_pub.pricing_attr_tbl_type;
    ppr_pricing_attr_val_tbl    qp_price_list_pub.pricing_attr_val_tbl_type;
    x_return_status             VARCHAR2(15) := xx_emf_cn_pkg.cn_success;
    x_init_msg_list             VARCHAR2(1000) := fnd_api.g_true;
    gpr_return_status           VARCHAR2(1) := NULL;
    gpr_msg_count               NUMBER := 0;
    x_msg_count                 NUMBER;
    x_msg_data                  VARCHAR2(2000);
    gpr_msg_data                VARCHAR2(32767);
    gpr_msg_data2               VARCHAR2(32767);
    x_success_record            NUMBER;
    x_error_record              NUMBER;
    x_pricing_attr_index        NUMBER := 0;
    x_lpr_line_index            NUMBER := 0;
    x_product_attribute         VARCHAR2(60);
    b_list_line_count           NUMBER;
    b_list_attr_count           NUMBER;
    x_err_msg                   VARCHAR2(3000);
    --------
    c_yn_flag_y               CONSTANT VARCHAR2(1) := 'Y';
    c_yn_flag_n               CONSTANT VARCHAR2(1) := 'N';
    x_exists_flag             VARCHAR2(1) ;
    c_pricelist               CONSTANT VARCHAR2(3) := 'PRL';
    c_discountlist            CONSTANT VARCHAR2(3) := 'DLT';
    c_action_ins              CONSTANT VARCHAR2(3) := 'INS';
    c_action_upd              CONSTANT VARCHAR2(3) := 'UPD';
    c_incomp_grp              CONSTANT VARCHAR2(10) := 'LVL 1';
    c_pricing_grp_seq         CONSTANT NUMBER       := 1;
    c_appl_method_mod         CONSTANT VARCHAR2(20) := 'NEWPRICE';
    c_appl_method_prc         CONSTANT VARCHAR2(20) := 'UNIT_PRICE';
    x_list_header_id          qp_list_headers.list_header_id%TYPE;
    x_invitem_cat_id          mtl_system_items_b.inventory_item_id%TYPE;
    x_invitem_dcode          VARCHAR2(500);
    x_list_line_id            qp_list_lines.list_line_id%TYPE;
    x_uom_code                mtl_system_items_b.primary_uom_code%TYPE;
    c_product_attr_item       CONSTANT VARCHAR2(20) := 'Item Number';
    c_product_attr_cat        CONSTANT VARCHAR2(20) := 'Item Category';
    c_product_attr_dcode      CONSTANT VARCHAR2(20) := 'DCODE';
    c_prc_context_type        CONSTANT VARCHAR2(20) := 'PRODUCT';
    c_prc_context_code        CONSTANT VARCHAR2(20) := 'ITEM';
    x_act_line_exists_flag    VARCHAR2(1) ;
    x_price_protect_hdr       VARCHAR2(10);
    x_price_protect_lin       VARCHAR2(10);
    x_price_protect_lin_flg   VARCHAR2(10);
    x_list_price              qp_list_lines_v.list_price%TYPE;
    x_start_date_active       qp_list_lines_v.start_date_active%TYPE;
    x_end_date_active         qp_list_lines_v.end_date_active%TYPE;
    ---------------------------------------------------------------
    x_modifier_list_rec     qp_modifiers_pub.modifier_list_rec_type;
    x_modifier_list_val_rec qp_modifiers_pub.modifier_list_val_rec_type;
    x_modifiers_tbl         qp_modifiers_pub.modifiers_tbl_type;
    x_modifiers_val_tbl     qp_modifiers_pub.modifiers_val_tbl_type;
    x_qualifiers_tbl        qp_qualifier_rules_pub.qualifiers_tbl_type;
    x_qualifiers_val_tbl    qp_qualifier_rules_pub.qualifiers_val_tbl_type;
    x_pricing_attr_tbl      qp_modifiers_pub.pricing_attr_tbl_type;
    x_pricing_attr_val_tbl  qp_modifiers_pub.pricing_attr_val_tbl_type;

    p_modifier_list_rec     qp_modifiers_pub.modifier_list_rec_type;
    p_modifier_list_val_rec qp_modifiers_pub.modifier_list_val_rec_type;
    p_modifiers_tbl         qp_modifiers_pub.modifiers_tbl_type;
    p_modifiers_val_tbl     qp_modifiers_pub.modifiers_val_tbl_type;
    p_qualifiers_tbl        qp_qualifier_rules_pub.qualifiers_tbl_type;
    p_qualifiers_val_tbl    qp_qualifier_rules_pub.qualifiers_val_tbl_type;
    p_pricing_attr_tbl      qp_modifiers_pub.pricing_attr_tbl_type;
    p_pricing_attr_val_tbl  qp_modifiers_pub.pricing_attr_val_tbl_type;
    x_msg_data2             varchar2(2000);
    x_arithmetic_operator   qp_list_lines.arithmetic_operator%TYPE;
    x_product_precedence    qp_list_lines.product_precedence%TYPE;
    x_pricing_phase_id      qp_list_lines.pricing_phase_id%TYPE;

    x_product_value         VARCHAR2(240);--Added on 12 FEB
    -----------------------------------------------------------------------------

  BEGIN

    BEGIN
       SELECT TRIM(TRANSLATE(p_product_value,chr(49824),' '))
        INTO x_product_value
        FROM dual;

    EXCEPTION
       WHEN OTHERS THEN
          x_err_msg := 'Error : When others in replacing junk values'||SQLERRM ;
          RETURN x_err_msg;
    END;

    BEGIN

       SELECT list_header_id
             ,DECODE(UPPER(attribute1),'YES',c_yn_flag_y,c_yn_flag_n)
        INTO  x_list_header_id
             ,x_price_protect_hdr
        FROM  qp_list_headers
       WHERE  name  =  TRIM(p_list_name)
         AND  list_type_code = TRIM(p_list_type);

    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          x_err_msg := 'Error : List Name Not Found' ;
          RETURN x_err_msg;
       WHEN OTHERS THEN
          x_err_msg := 'Error : When others in searching list name'||SQLERRM ;
          RETURN x_err_msg;
    END;


    IF TRIM(p_product_attribute)  =  c_product_attr_item THEN
       BEGIN
          x_exists_flag := NULL;

          SELECT lin.list_line_id
                ,product_attr_value
                ,qpa.product_uom_code
                ,DECODE(UPPER(lin.attribute1),'YES',c_yn_flag_y,'NO',c_yn_flag_n,UPPER(lin.attribute1))
                ,list_price
                ,lin.start_date_active
                ,lin.end_date_active
                ,arithmetic_operator
                ,lin.product_precedence
                ,c_yn_flag_y
           INTO x_list_line_id
               ,x_invitem_cat_id
               ,x_uom_code
               ,x_price_protect_lin
               ,x_list_price
               ,x_start_date_active
               ,x_end_date_active
               ,x_arithmetic_operator
               ,x_product_precedence
               ,x_exists_flag
           FROM qp_list_lines lin
               ,qp_pricing_attributes qpa
               ,mtl_system_items_b msi
          WHERE msi.inventory_item_id = qpa.product_attr_value
            AND lin.list_header_id = qpa.list_header_id
            AND lin.list_line_id   = qpa.list_line_id
            AND  msi.segment1      = TRIM(x_product_value)
            AND  msi.organization_id = (SELECT organization_id
                                             FROM mtl_parameters
                                            WHERE master_organization_id = organization_id)
            AND lin.list_header_id  = x_list_header_id
            AND product_attribute  = DECODE( TRIM(p_product_attribute)
                                           ,c_product_attr_item
                                           ,'PRICING_ATTRIBUTE1'
                                           ,'PRICING_ATTRIBUTE2'
                                           )
            AND NVL(lin.start_date_active
                    ,DECODE(TRIM(p_record_type),c_action_upd,TRUNC(sysdate),NVL(TRIM(p_start_date),TRUNC(sysdate)))
                    )
                                       <= DECODE(TRIM(p_record_type),c_action_upd,TRUNC(sysdate),NVL(TRIM(p_start_date),TRUNC(sysdate)))
            AND NVL(lin.end_date_active
                    ,DECODE(TRIM(p_record_type),c_action_upd,TRUNC(sysdate),NVL(NVL(TRIM(p_end_date),TRIM(p_start_date)),TRUNC(sysdate)))
                    )
                                       >= DECODE(TRIM(p_record_type),c_action_upd,TRUNC(sysdate),NVL(NVL(TRIM(p_end_date),TRIM(p_start_date)),TRUNC(sysdate))) ;

          x_act_line_exists_flag := c_yn_flag_y;

       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             x_act_line_exists_flag := c_yn_flag_n;
             IF TRIM(p_record_type) = c_action_upd THEN
                x_err_msg := 'Error : ACTIVE List Line Not Found to be updated' ;
                RETURN x_err_msg;
             END IF;
          WHEN TOO_MANY_ROWS THEN
             x_err_msg := 'Error : List has duplicate lines with overlapping/same period. Fix the issue manually and try loading again' ;
             RETURN x_err_msg;
          WHEN OTHERS THEN
             x_err_msg := 'Error : When others in searching existing list line :'||SQLERRM ;
             RETURN x_err_msg;
       END ;
    ELSIF TRIM(p_product_attribute) = c_product_attr_cat THEN
       BEGIN
          x_exists_flag := NULL;

          SELECT lin.list_line_id
                ,product_attr_value
                ,qpa.product_uom_code
                ,DECODE(UPPER(lin.attribute1),'YES',c_yn_flag_y,'NO',c_yn_flag_n,UPPER(lin.attribute1))
                ,list_price
                ,lin.start_date_active
                ,lin.end_date_active
                ,arithmetic_operator
                ,lin.product_precedence
                ,c_yn_flag_y
           INTO x_list_line_id
               ,x_invitem_cat_id
               ,x_uom_code
               ,x_price_protect_lin
               ,x_list_price
               ,x_start_date_active
               ,x_end_date_active
               ,x_arithmetic_operator
               ,x_product_precedence
               ,x_exists_flag
           FROM qp_list_lines lin
               ,qp_pricing_attributes qpa
               ,qp_item_categories_v qiv
          WHERE qiv.category_id = qpa.product_attr_value
            AND lin.list_header_id = qpa.list_header_id
            AND lin.list_line_id   = qpa.list_line_id
            AND  qiv.category_name      = TRIM(x_product_value)
            AND functional_area_id IN (
                                           SELECT DISTINCT functional_area_id
                                             FROM qp_sourcesystem_fnarea_map
                                            WHERE enabled_flag = 'Y')
            AND lin.list_header_id  = x_list_header_id
            AND product_attribute  = DECODE( TRIM(p_product_attribute)
                                           ,c_product_attr_item
                                           ,'PRICING_ATTRIBUTE1'
                                           ,'PRICING_ATTRIBUTE2'
                                           )
             AND NVL(lin.start_date_active
                    ,DECODE(TRIM(p_record_type),c_action_upd,TRUNC(sysdate),NVL(TRIM(p_start_date),TRUNC(sysdate)))
                    )
                                       <= DECODE(TRIM(p_record_type),c_action_upd,TRUNC(sysdate),NVL(TRIM(p_start_date),TRUNC(sysdate)))
            AND NVL(lin.end_date_active
                    ,DECODE(TRIM(p_record_type),c_action_upd,TRUNC(sysdate),NVL(NVL(TRIM(p_end_date),TRIM(p_start_date)),TRUNC(sysdate)))
                    )
                                       >= DECODE(TRIM(p_record_type),c_action_upd,TRUNC(sysdate),NVL(NVL(TRIM(p_end_date),TRIM(p_start_date)),TRUNC(sysdate))) ;

          x_act_line_exists_flag := c_yn_flag_y;
          /*IF NVL(x_exists_flag,c_yn_flag_n) = c_yn_flag_n THEN
             x_act_line_exists_flag := c_yn_flag_n;
             IF TRIM(p_record_type) = c_action_upd THEN
             END IF;
          ELSE
             x_act_line_exists_flag := c_yn_flag_y;
          END IF;*/
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             x_act_line_exists_flag := c_yn_flag_n;
             IF TRIM(p_record_type) = c_action_upd THEN
                x_err_msg := 'Error : ACTIVE List Line Not Found to be updated' ;
                RETURN x_err_msg;
             END IF;
          WHEN TOO_MANY_ROWS THEN
             x_err_msg := 'Error : List has duplicate lines with overlapping/same period. Fix the issue manually and try loading again' ;
             RETURN x_err_msg;
          WHEN OTHERS THEN
             x_err_msg := 'Error : When others in searching existing list line :'||SQLERRM ;
             RETURN x_err_msg;
       END ;
     ELSIF TRIM(p_product_attribute) = c_product_attr_dcode THEN
       BEGIN
          x_exists_flag := NULL;

          SELECT lin.list_line_id
                ,product_attr_value
                ,qpa.product_uom_code
                ,DECODE(UPPER(lin.attribute1),'YES',c_yn_flag_y,'NO',c_yn_flag_n,UPPER(lin.attribute1))
                ,list_price
                ,lin.start_date_active
                ,lin.end_date_active
                ,arithmetic_operator
                ,lin.product_precedence
                ,c_yn_flag_y
           INTO x_list_line_id
               ,x_invitem_dcode
               ,x_uom_code
               ,x_price_protect_lin
               ,x_list_price
               ,x_start_date_active
               ,x_end_date_active
               ,x_arithmetic_operator
               ,x_product_precedence
               ,x_exists_flag
           FROM qp_list_lines lin
               ,qp_pricing_attributes qpa
          WHERE EXISTS (SELECT 1
                          FROM   fnd_flex_values_vl fvl
                                ,fnd_flex_value_sets fvs
                         WHERE  flex_value = qpa.product_attr_value
                           AND  fvl.flex_value_set_id = fvs.flex_value_set_id
                           AND  fvs.flex_value_set_name = 'INTG_PRODUCT_TYPE')
            AND lin.list_header_id = qpa.list_header_id
            AND lin.list_line_id   = qpa.list_line_id
            AND qpa.product_attr_value      = TRIM(x_product_value)
            AND lin.list_header_id  = x_list_header_id
            AND product_attribute  = DECODE( TRIM(p_product_attribute)
                                           ,c_product_attr_dcode
                                           ,'PRICING_ATTRIBUTE25'
                                           ,NULL
                                           )
             AND NVL(lin.start_date_active
                    ,DECODE(TRIM(p_record_type),c_action_upd,TRUNC(sysdate),NVL(TRIM(p_start_date),TRUNC(sysdate)))
                    )
                                       <= DECODE(TRIM(p_record_type),c_action_upd,TRUNC(sysdate),NVL(TRIM(p_start_date),TRUNC(sysdate)))
            AND NVL(lin.end_date_active
                    ,DECODE(TRIM(p_record_type),c_action_upd,TRUNC(sysdate),NVL(NVL(TRIM(p_end_date),TRIM(p_start_date)),TRUNC(sysdate)))
                    )
                                       >= DECODE(TRIM(p_record_type),c_action_upd,TRUNC(sysdate),NVL(NVL(TRIM(p_end_date),TRIM(p_start_date)),TRUNC(sysdate))) ;

          x_act_line_exists_flag := c_yn_flag_y;

       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             x_act_line_exists_flag := c_yn_flag_n;
             IF TRIM(p_record_type) = c_action_upd THEN
                x_err_msg := 'Error : ACTIVE List Line Not Found to be updated' ;
                RETURN x_err_msg;
             END IF;
          WHEN TOO_MANY_ROWS THEN
             x_err_msg := 'Error : List has duplicate lines with overlapping/same period. Fix the issue manually and try loading again' ;
             RETURN x_err_msg;
          WHEN OTHERS THEN
             x_err_msg := 'Error : When others in searching existing list line :'||SQLERRM ;
             RETURN x_err_msg;
       END ;
    END IF;


    BEGIN
       IF x_act_line_exists_flag = c_yn_flag_n THEN
          IF TRIM(p_product_attribute) = c_product_attr_item THEN
             SELECT inventory_item_id
                   ,primary_uom_code
              INTO  x_invitem_cat_id
                   ,x_uom_code
               FROM mtl_system_items_b
              WHERE segment1 = TRIM(x_product_value)
                AND NVL(customer_order_flag,'N') = 'Y'
                AND  organization_id = (SELECT organization_id
                                          FROM mtl_parameters
                                         WHERE master_organization_id = organization_id);
          ELSIF TRIM(p_product_attribute) = c_product_attr_cat THEN
             SELECT category_id
                   ,NVL(TRIM(p_uom),'EA')
              INTO  x_invitem_cat_id
                   ,x_uom_code
               FROM qp_item_categories_v
              WHERE category_name = TRIM(x_product_value)
               AND functional_area_id IN (
                                           SELECT DISTINCT functional_area_id
                                             FROM qp_sourcesystem_fnarea_map
                                            WHERE enabled_flag = 'Y');
          ELSIF TRIM(p_product_attribute) = c_product_attr_dcode THEN
             SELECT flex_value
                   ,NVL(TRIM(p_uom),'EA')
              INTO  x_invitem_dcode
                   ,x_uom_code
               FROM fnd_flex_values_vl fvl
                   ,fnd_flex_value_sets fvs
              WHERE fvl.flex_value_set_id = fvs.flex_value_set_id
               AND  fvs.flex_value_set_name = 'INTG_PRODUCT_TYPE'
               AND  flex_value = TRIM(x_product_value)
               AND  rownum <2 ;
          ELSE
             x_err_msg := 'Error : Invalid product attribute value option';
             RETURN x_err_msg;
          END IF;
       END IF;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          x_err_msg := 'Error : Valid Item/Category/DCODE Not Found' ;
          RETURN x_err_msg;

       WHEN OTHERS THEN
          x_err_msg := 'Error : When others in searching item/category/DCODE :'||SQLERRM ;
          RETURN x_err_msg;
    END;

    IF TRIM(p_record_type) = c_action_ins THEN
       IF TRIM(p_price_protect_flag) = c_yn_flag_y THEN
          x_price_protect_lin_flg := 'Yes';
       ELSIF TRIM(p_price_protect_flag) = c_yn_flag_n THEN
          x_price_protect_lin_flg := 'No';
       END IF;
       IF TRIM(p_precedence) IS NULL THEN
          BEGIN
             SELECT attribute2
               INTO x_product_precedence
               FROM fnd_lookup_values
              WHERE lookup_type = 'INTG_MASS_UPLOAD_DEFAULTS'
                AND LOOKUP_CODE = TRIM(p_list_type)
                AND language = USERENV('LANG');
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                NULL;

             WHEN OTHERS THEN
                x_err_msg := 'Error : When others in searching product precedence'||SQLERRM ;
             RETURN x_err_msg;
          END;
       ELSE
          x_product_precedence := TRIM(p_precedence);
       END IF;

       IF x_product_precedence IS NULL THEN
          BEGIN
                SELECT user_precedence
                  INTO x_product_precedence
                  FROM qp_segments_v
                 WHERE prc_context_id IN (SELECT prc_context_id
                                            FROM qp_prc_contexts_v
                                           WHERE(
                                                  ('I' = 'S'
                                                   AND EXISTS
                                                           (SELECT 'x'
                                                              FROM qp_segments_v c
                                                             WHERE c.prc_context_id = qp_prc_contexts_v.prc_context_id
                                                               AND c.availability_in_basic IN('Y',    'F')
                                                           )
                                                   )
                                                  OR('I' <> 'S')
                                                 )
                                             AND prc_context_type = c_prc_context_type
                                             AND prc_context_code = c_prc_context_code)
                   AND(('I' = 'S'
                         AND availability_in_basic IN('Y',   'F')
                        )
                      OR('I' <> 'S')
                      )
                   and seeded_segment_name = TRIM(p_product_attribute);
                EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                      NULL;
                   WHEN OTHERS THEN
                      x_err_msg := 'Error : When others in searching seeded product precedence'||SQLERRM ;
                      RETURN x_err_msg;

                END;
       END IF;

       IF x_product_precedence IS NULL THEN
          IF TRIM(p_list_type) = c_discountlist THEN
             x_err_msg := 'Error : Precedence must be provided' ;
             RETURN x_err_msg;
          END IF;
       END IF;
       ----end defaulting precedence-------------------------------------
       ----start defaulting pricing phase for modifiers
       IF  TRIM(p_list_type) = c_discountlist THEN
          BEGIN
             SELECT pricing_phase_id
               INTO x_pricing_phase_id
               FROM qp_pricing_phases
              WHERE name = 'List Line Adjustment';

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                   x_err_msg := 'Error : Cannot find pricing phase' ;
                   RETURN x_err_msg;

             WHEN OTHERS THEN
                x_err_msg := 'Error : When others in searching pricing phase'||SQLERRM ;
             RETURN x_err_msg;
          END;
       END IF;
       --------end defaulting pricing phase id
    END IF;


    BEGIN
      SELECT seg.segment_mapping_column
        INTO x_product_attribute
        FROM qp_prc_contexts_v cntx, qp_segments_v seg
       WHERE cntx.prc_context_id = seg.prc_context_id
         AND cntx.prc_context_code = g_product_attr_context
         AND UPPER(seg.user_segment_name) = UPPER(TRIM(TRIM(p_product_attribute)));
    EXCEPTION
      WHEN OTHERS THEN
        /*fnd_file.put_line(fnd_file.LOG,
                          'Error occured fetching product attribute mapping ' ||
                          ' Error: ' || SQLERRM);*/
        x_product_attribute := NULL;
        x_err_msg := 'Error : When others in searching Product Attribute segment'||SQLERRM ;
        RETURN x_err_msg;
    END;

    BEGIN


      IF NVL(TRIM(p_price_protect_flag), 'N') NOT IN ('Y', 'N') THEN
        x_err_msg := 'Not A Valid Value For Price Protect Flag, Can be Yes Or No Or Blank ';
        RETURN x_err_msg;
      END IF;


      IF TRIM(p_record_type) = c_action_ins THEN
        IF x_act_line_exists_flag = c_yn_flag_y THEN

           IF NVL(x_price_protect_lin,c_yn_flag_n) = c_yn_flag_n
              AND NVL(x_price_protect_hdr,c_yn_flag_n) = c_yn_flag_n THEN
              x_lpr_line_index := x_lpr_line_index + 1;
              IF TRIM(p_list_type) = c_pricelist THEN
                 gpr_price_list_line_tbl(x_lpr_line_index).list_header_id := x_list_header_id;
                 gpr_price_list_line_tbl(x_lpr_line_index).list_line_id := x_list_line_id;
                 gpr_price_list_line_tbl(x_lpr_line_index).end_date_active := TO_DATE(TRIM(p_start_date),
                                                                                'DD-MON-YYYY') - 1;
                 gpr_price_list_line_tbl(x_lpr_line_index).operation := qp_globals.g_opr_update;

                 ---Call API for Update-----------------------------------------------------
                 BEGIN

                    qp_price_list_pub.process_price_list(p_api_version_number      => 1,
                                                         p_init_msg_list           => fnd_api.g_true,
                                                         p_return_values           => fnd_api.g_false,
                                                         p_commit                  => fnd_api.g_false,
                                                         x_return_status           => gpr_return_status,
                                                         x_msg_count               => gpr_msg_count,
                                                         x_msg_data                => gpr_msg_data,
                                                         p_price_list_rec          => gpr_price_list_rec,
                                                         p_price_list_line_tbl     => gpr_price_list_line_tbl,
                                                         p_qualifiers_tbl          => gpr_qualifiers_tbl,
                                                         p_pricing_attr_tbl        => gpr_pricing_attr_tbl,
                                                         x_price_list_rec          => ppr_price_list_rec,
                                                         x_price_list_val_rec      => ppr_price_list_val_rec,
                                                         x_price_list_line_tbl     => ppr_price_list_line_tbl,
                                                         x_price_list_line_val_tbl => ppr_price_list_line_val_tbl,
                                                         x_qualifiers_tbl          => ppr_qualifiers_tbl,
                                                         x_qualifiers_val_tbl      => ppr_qualifiers_val_tbl,
                                                         x_pricing_attr_tbl        => ppr_pricing_attr_tbl,
                                                         x_pricing_attr_val_tbl    => ppr_pricing_attr_val_tbl);
                    --COMMIT;

                  EXCEPTION
                    WHEN OTHERS THEN
                      x_err_msg := 'Error occured calling api to create/update price list line ' ||
                                   ' Error: ' || SQLERRM;
                      RETURN x_err_msg;
                      ROLLBACK;
                  END;

                  IF gpr_return_status IN ('E', 'U') THEN
                    gpr_msg_data   := '';
                    gpr_msg_data2  := '';
                    x_error_record := x_error_record + 1;

                    FOR k IN 1 .. gpr_msg_count LOOP
                      gpr_msg_data  := SUBSTR(oe_msg_pub.get(p_msg_index => k,
                                                             p_encoded   => 'F'),
                                              1,
                                              160);
                      gpr_msg_data2 := SUBSTR(gpr_msg_data2 || LTRIM(RTRIM(gpr_msg_data)),
                                              1,
                                              200);
                    END LOOP;

                    x_err_msg := 'Price List line not updated ' || ' API Error: ' ||
                                 gpr_msg_data;
                    RETURN x_err_msg;
                    ROLLBACK;
                  END IF;
                  -----------API call for update end----------------------------------------
              ELSIF TRIM(p_list_type) = c_discountlist THEN
                 p_modifier_list_rec.list_header_id                := x_list_header_id;
                 p_modifier_list_rec.operation                     := qp_globals.g_opr_update;
                 p_modifiers_tbl(x_lpr_line_index).end_date_active := TO_DATE(TRIM(p_start_date),
                                                                         'DD-MON-YYYY') - 1;
                 p_modifiers_tbl(x_lpr_line_index).list_line_id    := x_list_line_id;
                 p_modifiers_tbl(x_lpr_line_index).operation       := qp_globals.g_opr_update;

                 -------API call for modifier update--------------------------
                 BEGIN
                 qp_modifiers_pub.process_modifiers(p_api_version_number    => 1.0,
                                         p_init_msg_list         => fnd_api.g_true,
                                         p_return_values         => fnd_api.g_false,
                                         p_commit                => fnd_api.g_false,
                                         x_return_status         => x_return_status,
                                         x_msg_count             => x_msg_count,
                                         x_msg_data              => x_msg_data,
                                         p_modifier_list_rec     => p_modifier_list_rec,
                                         p_modifier_list_val_rec => p_modifier_list_val_rec,
                                         p_modifiers_tbl         => p_modifiers_tbl,
                                         p_modifiers_val_tbl     => p_modifiers_val_tbl,
                                         p_qualifiers_tbl        => p_qualifiers_tbl,
                                         p_qualifiers_val_tbl    => p_qualifiers_val_tbl,
                                         p_pricing_attr_tbl      => p_pricing_attr_tbl,
                                         p_pricing_attr_val_tbl  => p_pricing_attr_val_tbl,
                                         x_modifier_list_rec     => x_modifier_list_rec,
                                         x_modifier_list_val_rec => x_modifier_list_val_rec,
                                         x_modifiers_tbl         => x_modifiers_tbl,
                                         x_modifiers_val_tbl     => x_modifiers_val_tbl,
                                         x_qualifiers_tbl        => x_qualifiers_tbl,
                                         x_qualifiers_val_tbl    => x_qualifiers_val_tbl,
                                         x_pricing_attr_tbl      => x_pricing_attr_tbl,
                                         x_pricing_attr_val_tbl  => x_pricing_attr_val_tbl

                                         );
                  --COMMIT;

                EXCEPTION
                  WHEN OTHERS THEN
                    x_err_msg := 'Error occured calling api to create/update price list modifier ' ||
                                 ' Error: ' || SQLERRM;
                    RETURN x_err_msg;
                    ROLLBACK;
                END;

                IF x_return_status IN ('E', 'U') THEN
                  x_msg_data  := '';
                  x_msg_data2 := '';

                  FOR k IN 1 .. x_msg_count LOOP
                    x_msg_data  := SUBSTR(oe_msg_pub.get(p_msg_index => k,
                                                         p_encoded   => 'F'),
                                          1,
                                          160);
                    x_msg_data2 := SUBSTR(x_msg_data2 || LTRIM(RTRIM(x_msg_data)),
                                          1,
                                          200);
                  END LOOP;

                  x_err_msg := 'Price List Modifier not updated ' ||
                               ' API Error: ' || x_msg_data;

                  RETURN x_err_msg;

                  ROLLBACK;
                END IF;
                 -------API call fot modifier update end----------------------
              END IF;
           ELSE
              x_err_msg := 'Error: Exisitng line to be end dated is price protected hence not updated. ';
              RETURN x_err_msg;
           END IF;
        END IF;

        x_lpr_line_index     := x_lpr_line_index + 1;
        x_pricing_attr_index := x_pricing_attr_index + 1;


        IF TRIM(p_list_type) = c_pricelist THEN
           gpr_price_list_line_tbl(x_lpr_line_index).list_header_id := x_list_header_id;
           gpr_price_list_line_tbl(x_lpr_line_index).arithmetic_operator := NVL(TRIM(p_appl_method),c_appl_method_prc);
           gpr_price_list_line_tbl(x_lpr_line_index).list_line_id := fnd_api.g_miss_num;
           gpr_price_list_line_tbl(x_lpr_line_index).end_date_active := TO_DATE(TRIM(p_end_date),
                                                                                'DD-MON-YYYY');
           gpr_price_list_line_tbl(x_lpr_line_index).start_date_active := TO_DATE(TRIM(p_start_date),
                                                                                  'DD-MON-YYYY');
           gpr_price_list_line_tbl(x_lpr_line_index).list_line_type_code := g_list_line_type;

           IF TRIM(p_product_attribute) <> c_product_attr_dcode THEN
             -- gpr_price_list_line_tbl(x_lpr_line_index).inventory_item_id := x_invitem_dcode;
           --ELSE
              gpr_price_list_line_tbl(x_lpr_line_index).inventory_item_id := x_invitem_cat_id;
           END IF;

           gpr_price_list_line_tbl(x_lpr_line_index).operand := TRIM(p_price);
           --gpr_price_list_line_tbl(x_lpr_line_index).primary_uom_flag := g_primary_uom_flag;
           gpr_price_list_line_tbl(x_lpr_line_index).automatic_flag := g_automatic_flag;
           IF TRIM(p_price_protect_flag) IS NOT NULL THEN
              gpr_price_list_line_tbl(x_lpr_line_index).CONTEXT := g_qp_line_dff_context;
              gpr_price_list_line_tbl(x_lpr_line_index).attribute1 := x_price_protect_lin_flg;
           END IF;
           gpr_price_list_line_tbl(x_lpr_line_index).product_precedence := x_product_precedence;
           gpr_price_list_line_tbl(x_lpr_line_index).operation := qp_globals.g_opr_create;

           gpr_pricing_attr_tbl(x_pricing_attr_index).pricing_attribute_id := fnd_api.g_miss_num;
           gpr_pricing_attr_tbl(x_pricing_attr_index).list_line_id := fnd_api.g_miss_num;
           gpr_pricing_attr_tbl(x_pricing_attr_index).operation := qp_globals.g_opr_create;
           gpr_pricing_attr_tbl(x_pricing_attr_index).price_list_line_index := x_lpr_line_index;
           gpr_pricing_attr_tbl(x_pricing_attr_index).product_attribute_context := g_product_attr_context;
           gpr_pricing_attr_tbl(x_pricing_attr_index).product_attribute := x_product_attribute;

           IF TRIM(p_product_attribute) = c_product_attr_dcode THEN
              gpr_pricing_attr_tbl(x_pricing_attr_index).product_attr_value := x_invitem_dcode;
           ELSE
              gpr_pricing_attr_tbl(x_pricing_attr_index).product_attr_value := x_invitem_cat_id;
           END IF;


           gpr_pricing_attr_tbl(x_pricing_attr_index).product_uom_code := x_uom_code;

        ELSIF TRIM(p_list_type) = c_discountlist THEN
           p_modifier_list_rec.list_header_id                := x_list_header_id;
           p_modifier_list_rec.operation                     := qp_globals.g_opr_update;
           p_modifiers_tbl(x_lpr_line_index).operation := qp_globals.g_opr_create;
           p_modifiers_tbl(x_lpr_line_index).list_line_type_code := g_list_line_type_mod;
           p_modifiers_tbl(x_lpr_line_index).modifier_level_code := g_modifier_level_code;
           p_modifiers_tbl(x_lpr_line_index).start_date_active := TO_DATE(TRIM(p_start_date),
                                                                                'DD-MON-YYYY');
           p_modifiers_tbl(x_lpr_line_index).end_date_active := TO_DATE(TRIM(p_end_date),
                                                                                'DD-MON-YYYY');
           p_modifiers_tbl(x_lpr_line_index).print_on_invoice_flag    := c_yn_flag_y ;
           p_modifiers_tbl(x_lpr_line_index).incompatibility_grp_code := c_incomp_grp;
           p_modifiers_tbl(x_lpr_line_index).pricing_group_sequence   := c_pricing_grp_seq;
           p_modifiers_tbl(x_lpr_line_index).operand := TRIM(p_price);
           p_modifiers_tbl(x_lpr_line_index).product_precedence := x_product_precedence;
           IF TRIM(p_price_protect_flag) IS NOT NULL THEN
              p_modifiers_tbl(x_lpr_line_index).CONTEXT := g_qp_line_dff_context;
              p_modifiers_tbl(x_lpr_line_index).attribute1 := x_price_protect_lin_flg;
           END IF;
           p_modifiers_tbl(x_lpr_line_index).pricing_phase_id := x_pricing_phase_id;
           p_modifiers_tbl(x_lpr_line_index).arithmetic_operator := NVL(TRIM(p_appl_method),c_appl_method_mod);

           p_pricing_attr_tbl(x_pricing_attr_index).product_attribute_context := g_product_attr_context;
           p_pricing_attr_tbl(x_pricing_attr_index).product_attribute := x_product_attribute;

           IF TRIM(p_product_attribute) = c_product_attr_dcode THEN
              p_pricing_attr_tbl(x_pricing_attr_index).product_attr_value := x_invitem_dcode;
           ELSE
              p_pricing_attr_tbl(x_pricing_attr_index).product_attr_value := x_invitem_cat_id;
           END IF;

           p_pricing_attr_tbl(x_pricing_attr_index).operation := qp_globals.g_opr_create;
           p_pricing_attr_tbl(x_pricing_attr_index).modifiers_index := x_lpr_line_index;
        END IF;
      ELSIF TRIM(p_record_type) = c_action_upd THEN

        IF NVL(x_price_protect_lin,c_yn_flag_n) = c_yn_flag_n
              AND NVL(x_price_protect_hdr,c_yn_flag_n) = c_yn_flag_n THEN
           x_lpr_line_index     := x_lpr_line_index + 1;
           x_pricing_attr_index := x_pricing_attr_index + 1;
           IF TRIM(p_list_type) = c_pricelist THEN
              gpr_price_list_line_tbl(x_lpr_line_index).list_header_id := x_list_header_id;
              gpr_price_list_line_tbl(x_lpr_line_index).arithmetic_operator := NVL(TRIM(p_appl_method),x_arithmetic_operator);--g_arithmetic_operator;
              gpr_price_list_line_tbl(x_lpr_line_index).list_line_id := x_list_line_id;
              gpr_price_list_line_tbl(x_lpr_line_index).end_date_active := NVL(TRIM(p_end_date),x_end_date_active);
              gpr_price_list_line_tbl(x_lpr_line_index).start_date_active := NVL(TRIM(p_start_date),x_start_date_active);
              --gpr_price_list_line_tbl(x_lpr_line_index).list_line_type_code := g_list_line_type;
              --gpr_price_list_line_tbl(x_lpr_line_index).inventory_item_id := x_invitem_cat_id;
              gpr_price_list_line_tbl(x_lpr_line_index).list_price := NVL(TRIM(p_price),x_list_price);
              gpr_price_list_line_tbl(x_lpr_line_index).operand := NVL(TRIM(p_price),x_list_price);
              --gpr_price_list_line_tbl(x_lpr_line_index).primary_uom_flag := g_primary_uom_flag;
              --gpr_price_list_line_tbl(x_lpr_line_index).automatic_flag := g_automatic_flag;
              --gpr_price_list_line_tbl(x_lpr_line_index).CONTEXT := g_qp_line_dff_context;
              --gpr_price_list_line_tbl(x_lpr_line_index).attribute1 := TRIM(p_price_protect_flag);
              gpr_price_list_line_tbl(x_lpr_line_index).product_precedence := NVL(TRIM(p_precedence),x_product_precedence);
              gpr_price_list_line_tbl(x_lpr_line_index).operation := qp_globals.g_opr_update;
           ELSIF TRIM(p_list_type) = c_discountlist THEN
              p_modifier_list_rec.list_header_id := x_list_header_id;
              p_modifier_list_rec.operation := qp_globals.g_opr_update;
              p_modifiers_tbl(x_lpr_line_index).list_line_id := x_list_line_id;
              p_modifiers_tbl(x_lpr_line_index).operation := qp_globals.g_opr_update;
              p_modifiers_tbl(x_lpr_line_index).arithmetic_operator := NVL(TRIM(p_appl_method),x_arithmetic_operator);
              p_modifiers_tbl(x_lpr_line_index).start_date_active := NVL(TRIM(p_start_date),x_start_date_active);
              p_modifiers_tbl(x_lpr_line_index).end_date_active := NVL(TRIM(p_end_date),x_end_date_active);
              p_modifiers_tbl(x_lpr_line_index).operand := NVL(TRIM(p_price),x_list_price);
              p_modifiers_tbl(x_lpr_line_index).product_precedence := NVL(TRIM(p_precedence),x_product_precedence);
              --p_modifiers_tbl(x_lpr_line_index).attribute1 := TRIM(p_price_protect_flag);
           END IF;
         ELSE
            x_err_msg := 'Error: Line is price protected hence not updated. ';
            RETURN x_err_msg;
         END IF;

      ELSE
        x_err_msg := 'Error: Not a valid action. Action can be Insert or update ';
        RETURN x_err_msg;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        x_err_msg := 'Error occured while assigning values to the gpr_price_list_line_tbl ' ||
                     ' Error: ' || SQLERRM;
        RETURN x_err_msg;
    END;

    fnd_msg_pub.initialize;
    IF TRIM(p_list_type) = c_pricelist THEN
    BEGIN

      qp_price_list_pub.process_price_list(p_api_version_number      => 1,
                                           p_init_msg_list           => fnd_api.g_true,
                                           p_return_values           => fnd_api.g_false,
                                           p_commit                  => fnd_api.g_false,
                                           x_return_status           => gpr_return_status,
                                           x_msg_count               => gpr_msg_count,
                                           x_msg_data                => gpr_msg_data,
                                           p_price_list_rec          => gpr_price_list_rec,
                                           p_price_list_line_tbl     => gpr_price_list_line_tbl,
                                           p_qualifiers_tbl          => gpr_qualifiers_tbl,
                                           p_pricing_attr_tbl        => gpr_pricing_attr_tbl,
                                           x_price_list_rec          => ppr_price_list_rec,
                                           x_price_list_val_rec      => ppr_price_list_val_rec,
                                           x_price_list_line_tbl     => ppr_price_list_line_tbl,
                                           x_price_list_line_val_tbl => ppr_price_list_line_val_tbl,
                                           x_qualifiers_tbl          => ppr_qualifiers_tbl,
                                           x_qualifiers_val_tbl      => ppr_qualifiers_val_tbl,
                                           x_pricing_attr_tbl        => ppr_pricing_attr_tbl,
                                           x_pricing_attr_val_tbl    => ppr_pricing_attr_val_tbl);
      --COMMIT;

      gpr_price_list_line_tbl.DELETE;
      gpr_pricing_attr_tbl.DELETE;
    EXCEPTION
      WHEN OTHERS THEN
        x_err_msg := 'Error occured calling api to create/update price list line ' ||
                     ' Error: ' || SQLERRM;
        RETURN x_err_msg;
        ROLLBACK;
    END;

    IF gpr_return_status IN ('E', 'U') THEN
      gpr_msg_data   := '';
      gpr_msg_data2  := '';
      x_error_record := x_error_record + 1;

      FOR k IN 1 .. gpr_msg_count LOOP
        gpr_msg_data  := SUBSTR(oe_msg_pub.get(p_msg_index => k,
                                               p_encoded   => 'F'),
                                1,
                                160);
        gpr_msg_data2 := SUBSTR(gpr_msg_data2 || LTRIM(RTRIM(gpr_msg_data)),
                                1,
                                200);
      END LOOP;

      x_err_msg := 'Price List line not created/updated ' || ' API Error: ' ||
                   gpr_msg_data;
      RETURN x_err_msg;
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
    ELSIF TRIM(p_list_type) = c_discountlist THEN
       BEGIN
      mo_global.init('QP');
      qp_modifiers_pub.process_modifiers(p_api_version_number    => 1.0,
                                         p_init_msg_list         => fnd_api.g_true,
                                         p_return_values         => fnd_api.g_false,
                                         p_commit                => fnd_api.g_false,
                                         x_return_status         => x_return_status,
                                         x_msg_count             => x_msg_count,
                                         x_msg_data              => x_msg_data,
                                         p_modifier_list_rec     => p_modifier_list_rec,
                                         p_modifier_list_val_rec => p_modifier_list_val_rec,
                                         p_modifiers_tbl         => p_modifiers_tbl,
                                         p_modifiers_val_tbl     => p_modifiers_val_tbl,
                                         p_qualifiers_tbl        => p_qualifiers_tbl,
                                         p_qualifiers_val_tbl    => p_qualifiers_val_tbl,
                                         p_pricing_attr_tbl      => p_pricing_attr_tbl,
                                         p_pricing_attr_val_tbl  => p_pricing_attr_val_tbl,
                                         x_modifier_list_rec     => x_modifier_list_rec,
                                         x_modifier_list_val_rec => x_modifier_list_val_rec,
                                         x_modifiers_tbl         => x_modifiers_tbl,
                                         x_modifiers_val_tbl     => x_modifiers_val_tbl,
                                         x_qualifiers_tbl        => x_qualifiers_tbl,
                                         x_qualifiers_val_tbl    => x_qualifiers_val_tbl,
                                         x_pricing_attr_tbl      => x_pricing_attr_tbl,
                                         x_pricing_attr_val_tbl  => x_pricing_attr_val_tbl

                                         );
      --COMMIT;

    EXCEPTION
      WHEN OTHERS THEN
        x_err_msg := 'Error occured calling api to create/update price list modifier ' ||
                     ' Error: ' || SQLERRM;
        RETURN x_err_msg;
        ROLLBACK;
    END;

    IF x_return_status IN ('E', 'U') THEN
      x_msg_data  := '';
      x_msg_data2 := '';

      FOR k IN 1 .. x_msg_count LOOP
        x_msg_data  := SUBSTR(oe_msg_pub.get(p_msg_index => k,
                                             p_encoded   => 'F'),
                              1,
                              160);
        x_msg_data2 := SUBSTR(x_msg_data2 || LTRIM(RTRIM(x_msg_data)),
                              1,
                              200);
      END LOOP;

      x_err_msg := 'Price List Modifier not created/updated ' ||
                   ' API Error: ' || x_msg_data;

      RETURN x_err_msg;

      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
    END IF;
    RETURN x_err_msg;
  EXCEPTION
    WHEN fnd_api.g_exc_unexpected_error THEN
      FOR i IN 1 .. gpr_msg_count LOOP
        oe_msg_pub.get(p_msg_index     => i,
                       p_encoded       => fnd_api.g_false,
                       p_data          => gpr_msg_data,
                       p_msg_index_out => gpr_msg_count);
      END LOOP;

      x_err_msg := 'Price List line not created/updated ' ||
                   ' g_exc_unexpected_error Error: ' || gpr_msg_data;
      RETURN x_err_msg;
      ROLLBACK;
    WHEN OTHERS THEN
      x_err_msg := ' Price List line not created/updated  for Price List Id: OTHERS Error: ' ||
                   SQLERRM;
      RETURN x_err_msg;
      ROLLBACK;
  END update_price_list;

END xx_qp_mass_price_list_ext_pkg;
/
