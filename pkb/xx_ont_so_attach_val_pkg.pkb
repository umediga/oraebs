DROP PACKAGE BODY APPS.XX_ONT_SO_ATTACH_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xx_ont_so_attach_val_pkg
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 23-Sep-2013
File Name     : XXONTSOATTVAL.pkb
Description   : This script creates the package body of the package xx_ont_so_attach_val_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
23-Sep-2013  ABhargava              Initial Draft.
13-May-2015  Deepta N               Modified to include attachments for PO
*/
----------------------------------------------------------------------



FUNCTION data_validations_att (
         p_cnv_so_att_rec   IN OUT xx_ont_so_attach_pkg.g_xx_ont_so_att_rec_type
        )
RETURN NUMBER
IS
  x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
  x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

-- Validate if Sales Order Details are Valid
FUNCTION so_validation (l_value1 IN VARCHAR2,l_value2 IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    IF  p_cnv_so_att_rec.ENTITY_NAME = 'OE_ORDER_HEADERS' THEN
      select count(1)
      into l_cnt
      from oe_order_headers_all
      where ORIG_SYS_DOCUMENT_REF = l_value1;
    ELSIF  p_cnv_so_att_rec.ENTITY_NAME = 'OE_ORDER_LINES' THEN
      select count(1)
      into l_cnt
      from oe_order_lines_all
      where ORIG_SYS_DOCUMENT_REF = l_value1
      and   ORIG_SYS_LINE_REF  = l_value2;
      -- Added for PO attachments : Start
     ELSIF  p_cnv_so_att_rec.ENTITY_NAME in ('PO_HEAD','PO_HEADERS') THEN
      select count(1)
      into l_cnt
      from po_headers_all
      where segment1 = l_value1;
      ELSIF  p_cnv_so_att_rec.ENTITY_NAME = 'PO_LINES' THEN
            select count(1)
            into l_cnt
            from po_lines_all
            where po_header_id in (select Po_header_id
      from po_headers_all
      where segment1 = l_value1)-- = l_value1
      and   line_num  = l_value2;
       -- Added for PO attachments : End
    END IF;

    IF l_cnt >= 1 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Sales Order/Line  - '||l_value1||' '||l_value2||' does not exist ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Sales Order Does Not Exist',
                          p_cnv_so_att_rec.record_number,
                          p_cnv_so_att_rec.ORIG_SYS_DOCUMENT_REF,
                          p_cnv_so_att_rec.ORIG_SYS_LINE_REF
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'cust_validation  Unhandled Exception',
                     p_cnv_so_att_rec.record_number,
                     p_cnv_so_att_rec.ORIG_SYS_DOCUMENT_REF,
                     p_cnv_so_att_rec.ORIG_SYS_LINE_REF
                     );
   RETURN x_error_code;
END so_validation;

-- Validate if Entityt Name is valid
FUNCTION entity_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN

    IF l_value IN ('OE_ORDER_HEADERS','OE_ORDER_LINES','PO_HEAD','PO_HEADERS','PO_LINES') THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Entity Name should be OE_ORDER_HEADERS or OE_ORDER_LINES ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Entity Name should be OE_ORDER_HEADERS or OE_ORDER_LINES ',
                          p_cnv_so_att_rec.record_number,
                          p_cnv_so_att_rec.ORIG_SYS_DOCUMENT_REF,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'entity_validation  Unhandled Exception',
                     p_cnv_so_att_rec.record_number,
                     p_cnv_so_att_rec.ORIG_SYS_DOCUMENT_REF,
                     l_value
                     );
   RETURN x_error_code;
END entity_validation;

-- Validate if Security Type is valid
FUNCTION security_type (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN

    IF l_value is NOT NULL  THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Security Type can not be null ! ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Security Type can not be null ! ',
                          p_cnv_so_att_rec.record_number,
                          p_cnv_so_att_rec.ORIG_SYS_DOCUMENT_REF,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'security_type  Unhandled Exception',
                     p_cnv_so_att_rec.record_number,
                     p_cnv_so_att_rec.ORIG_SYS_DOCUMENT_REF,
                     l_value
                     );
   RETURN x_error_code;
END security_type;

-- Validate if Datatype Name is Valid
FUNCTION datatype_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from FND_DOCUMENT_DATATYPES
    where upper(NAME) = upper(l_value)
    and language = 'US';

    IF l_cnt >= 1 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Data Type Name  - '||l_value||' does not exist ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Data Type Name is Invalid ',
                          p_cnv_so_att_rec.record_number,
                          p_cnv_so_att_rec.ORIG_SYS_DOCUMENT_REF,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'datatype_validation  Unhandled Exception',
                     p_cnv_so_att_rec.record_number,
                     p_cnv_so_att_rec.ORIG_SYS_DOCUMENT_REF,
                     l_value
                     );
   RETURN x_error_code;
END datatype_validation;

-- Validate if Category Name is Valid
FUNCTION category_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from FND_DOCUMENT_CATEGORIES
    where upper(NAME) = upper(l_value);

    IF l_cnt >= 1 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Category Name  - '||l_value||' does not exist ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Category Name is Invalid ',
                          p_cnv_so_att_rec.record_number,
                          p_cnv_so_att_rec.ORIG_SYS_DOCUMENT_REF,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'category_validation  Unhandled Exception',
                     p_cnv_so_att_rec.record_number,
                     p_cnv_so_att_rec.ORIG_SYS_DOCUMENT_REF,
                     l_value
                     );
   RETURN x_error_code;
END category_validation;


BEGIN

    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Starting Customer Level Data-Validations');

    x_error_code_temp := so_validation (p_cnv_so_att_rec.ORIG_SYS_DOCUMENT_REF,p_cnv_so_att_rec.ORIG_SYS_LINE_REF);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  so_validation ' || x_error_code);

    x_error_code_temp := entity_validation (p_cnv_so_att_rec.ENTITY_NAME);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  entity_validation ' || x_error_code);

    x_error_code_temp := security_type (p_cnv_so_att_rec.security_type);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  security_type ' || x_error_code);

    x_error_code_temp := datatype_validation (p_cnv_so_att_rec.DATATYPE_NAME);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  datatype_validation ' || x_error_code);

    x_error_code_temp := category_validation(p_cnv_so_att_rec.CATEGORY_NAME);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  category_validation ' || x_error_code);


    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Completed Data-Validations');
    RETURN x_error_code;

EXCEPTION
WHEN xx_emf_pkg.G_E_REC_ERROR
THEN
    x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
    RETURN x_error_code;
WHEN xx_emf_pkg.G_E_PRC_ERROR
THEN
    x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
    RETURN x_error_code;
WHEN OTHERS
THEN
    x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
    RETURN x_error_code;
END data_validations_att;

END xx_ont_so_attach_val_pkg;
/
