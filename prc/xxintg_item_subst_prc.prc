DROP PROCEDURE APPS.XXINTG_ITEM_SUBST_PRC;

CREATE OR REPLACE PROCEDURE APPS."XXINTG_ITEM_SUBST_PRC" (P_ITEM_ID IN NUMBER)
AS
----------------------------------------------------------------------
/*
 Created By    : Aabhas Bhargava
 Creation Date : 14-Aug-2013
 File Name     : XXINTG_ITEM_SUBST.prc
 Description   : Insert data into Gloabl Temporary Table for Item Substitue Report
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
14-Aug-2013  Aabhas Bhargava       Initial Development
*/
 ----------------------------------------------------------------------
CURSOR C1_CURR IS
select mri.inventory_item_id,
       mri.related_item_id
from mtl_related_items mri
where inventory_item_id  = P_ITEM_ID
union
select mri.related_item_id inventory_item_id
      ,mri.inventory_item_id related_item_id
from mtl_related_items mri
where related_item_id  = P_ITEM_ID;


CURSOR C2_CURR IS
select qlh.list_header_id list_header,
       qlh.name,
       decode(qlh.list_type_code,'PRL','PRICE LIST','MODIFIER ') list_type,
       qll.operand,
       NVL(qll.start_date_active,qlh.start_date_active) start_date_active,
       qll.end_date_active,
       msib.segment1 item_number,
       msib.description,
       msib.inventory_item_id ,
       ood.organization_id
from qp_list_headers qlh
    ,qp_list_lines qll
    ,qp_pricing_attributes qpa
    ,mtl_system_items_b msib
    ,org_organization_definitions ood
where qlh.list_header_id = qll.list_header_id
and   qll.list_line_id = qpa.list_line_id
AND   qpa.product_attribute_context = 'ITEM'
AND   qpa.product_attribute = 'PRICING_ATTRIBUTE1'
AND   qpa.product_attr_value = msib.inventory_item_id
AND   msib.organization_id = ood.organization_id
AND   ood.organization_name = 'IO INTEGRA ITEM MASTER'
AND   qpa.product_attr_value = P_ITEM_ID;

l_cnt    NUMBER := 0;

BEGIN
FOR C1 in C1_CURR
LOOP
BEGIN
    FOR C2 in C2_CURR
    LOOP
    BEGIN
        select count(qpa.product_attr_value)
        into l_cnt
        from qp_list_headers qlh
            ,qp_list_lines qll
            ,qp_pricing_attributes qpa
        where qlh.list_header_id = qll.list_header_id
        AND   qlh.list_header_id = c2.list_header
        AND   qll.list_line_id = qpa.list_line_id
        AND   qpa.product_attribute_context = 'ITEM'
        AND   qpa.product_attribute = 'PRICING_ATTRIBUTE1'
        AND   qpa.product_attr_value = c1.related_item_id;

        IF l_cnt >= 1 THEN
           insert into XXINTG_ITEM_SUBST
           values (c2.list_header,c2.name,c2.list_type,c2.item_number,c2.description,c2.inventory_item_id,c2.operand,
           c2.start_date_active,c2.end_date_active,c2.organization_id,c1.related_item_id);
        END IF;
    EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('ERROR Second Cursor');
    END;
    END LOOP;
EXCEPTION
WHEN OTHERS THEN
      dbms_output.put_line('ERROR First Cursor');
END;
END LOOP;
INSERT INTO XXINTG_ITEM_SUBST
(
select qlh.list_header_id list_header,
       qlh.name,
       DECODE(QLH.LIST_TYPE_CODE,'PRL','PRICE LIST','MODIFIER ') LIST_TYPE,
       MSIB.SEGMENT1 ITEM_NUMBER,
       msib.description,
       MSIB.INVENTORY_ITEM_ID ,
       qll.operand,
       NVL(qll.start_date_active,qlh.start_date_active) start_date_active,
       QLL.END_DATE_ACTIVE,
       OOD.ORGANIZATION_ID,
       NULL
from qp_list_headers qlh
    ,qp_list_lines qll
    ,qp_pricing_attributes qpa
    ,mtl_system_items_b msib
    ,org_organization_definitions ood
where qlh.list_header_id = qll.list_header_id
and   qll.list_line_id = qpa.list_line_id
AND   qpa.product_attribute_context = 'ITEM'
AND   qpa.product_attribute = 'PRICING_ATTRIBUTE1'
AND   qpa.product_attr_value = msib.inventory_item_id
AND   msib.organization_id = ood.organization_id
AND   OOD.ORGANIZATION_NAME = 'IO INTEGRA ITEM MASTER'
AND   qpa.product_attr_value = P_ITEM_ID
AND   qlh.list_header_id NOT IN (select distinct LIST_HEADER_ID from XXINTG_ITEM_SUBST));

EXCEPTION
WHEN OTHERS THEN
         dbms_output.put_line('ERROR MAIN');
END;
/
