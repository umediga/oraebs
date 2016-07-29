DROP PACKAGE BODY APPS.XXINTG_OE_SO_EXTRACT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_OE_SO_EXTRACT_PKG" 
----------------------------------------------------------------------
/* $Header: XXINTG_ORD_DETAIL.pkb 1.0 2012/05/10 12:00:00 dparida noship $ */
/*
 Created By    : IBM Development Team
 Creation Date : 20-Mar-2014
 File Name     : XXINTG_ORD_DETAIL.pks
 Description   : This script creates the specification of the package
                 xxintg_oe_so_extract_pkg
 Change History:
 Date         Name                   Remarks
 -----------  -------------          -----------------------------------
20-Mar-2014   IBM Development Team   Initial Draft.
*/
----------------------------------------------------------------------
AS

   FUNCTION get_modifier_number (p_header_id IN NUMBER, p_line_id IN NUMBER)
      RETURN VARCHAR2
   IS
      l_modifier_number   VARCHAR2 (2000);
   BEGIN
          SELECT   LTRIM(MAX(TRIM (
                                '&' FROM (SYS_CONNECT_BY_PATH (
                                             adjustment_name || '  ',
                                             '& '
                                          ))
                             )))
            INTO   l_modifier_number
            FROM   (SELECT   header_id,
                             line_id,
                             adjustment_name,
                             ROW_NUMBER ()
                                OVER (PARTITION BY header_id, line_id
                                      ORDER BY adjustment_name)
                             - 1
                                AS seq
                      FROM   oe_price_adjustments_v opa
                     WHERE       opa.header_id = p_header_id
                             AND opa.line_id = p_line_id
                             AND applied_flag = 'Y'
                             AND list_line_type_code <> 'FREIGHT_CHARGE') --WHERE  connect_by_isleaf = 1
      CONNECT BY   seq = PRIOR seq + 1
      START WITH   seq = 0;

      RETURN l_modifier_number;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_modifier_number;

   FUNCTION get_modifier_name (p_header_id IN NUMBER, p_line_id IN NUMBER)
      RETURN VARCHAR2
   IS
      l_modifier_name   VARCHAR2 (2000);
   BEGIN
          SELECT   LTRIM(MAX(TRIM (
                                '&' FROM (SYS_CONNECT_BY_PATH (
                                             adjustment_description || '  ',
                                             '& '
                                          ))
                             )))
            INTO   l_modifier_name
            FROM   (SELECT   header_id,
                             line_id,
                             adjustment_description,
                             ROW_NUMBER ()
                                OVER (PARTITION BY header_id, line_id
                                      ORDER BY adjustment_description)
                             - 1
                                AS seq
                      FROM   oe_price_adjustments_v opa
                     WHERE       opa.header_id = p_header_id
                             AND opa.line_id = p_line_id
                             AND applied_flag = 'Y'
                             AND list_line_type_code <> 'FREIGHT_CHARGE') --WHERE  connect_by_isleaf = 1
      CONNECT BY   seq = PRIOR seq + 1
      START WITH   seq = 0;

      RETURN l_modifier_name;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_modifier_name;

   FUNCTION get_hold_name (p_header_id IN NUMBER, p_line_id IN NUMBER)
      RETURN VARCHAR2
   IS
      lv_cur_hold_name   VARCHAR2 (200);
      l_hold_name        VARCHAR2 (2000) := NULL;

      CURSOR c1
      IS
         SELECT   hold_id
           FROM   oe_hold_sources_all
          WHERE   hold_source_id IN
                        (SELECT   hold_source_id
                           FROM   oe_order_holds_all
                          WHERE   header_id = p_header_id
                                  AND line_id = p_line_id);
   BEGIN
      FOR i IN c1
      LOOP
         SELECT   ohd.name
           INTO   lv_cur_hold_name
           FROM   oe_hold_definitions ohd
          WHERE   ohd.hold_id = i.hold_id;

         IF l_hold_name IS NULL
         THEN
            l_hold_name := lv_cur_hold_name;
         ELSE
            l_hold_name := l_hold_name || ' & ' || lv_cur_hold_name;
         END IF;
      END LOOP;

      RETURN l_hold_name;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_hold_name;


END xxintg_oe_so_extract_pkg;
/
