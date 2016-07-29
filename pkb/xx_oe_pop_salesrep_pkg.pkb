DROP PACKAGE BODY APPS.XX_OE_POP_SALESREP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OE_POP_SALESREP_PKG" 
----------------------------------------------------------------------
/* $Header: XXOESALESREPNAME.pkb 1.0 2014/10/20 12:00:00 dparida noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 20-Oct-2014
 File Name      : XXOESALESREPNAME.pks
 Description    : This script creates the specification of the xx_oe_pop_salesrep_pkg package

 Change History:

 Version Date        Name                    Remarks
 ------- ----------- ----                    ----------------------
 1.0     20-Oct-2014 IBM Development Team    Initial development.
*/
----------------------------------------------------------------------
AS

  g_object_name VARCHAR2 (30) := 'XX_OE_ASSIGN_SALESREP';
  g_created_by        NUMBER         := fnd_global.user_id;
  g_last_update_login NUMBER         := fnd_global.login_id;
  g_multiple_salesrep VARCHAR2 (30)  := xx_emf_pkg.get_paramater_value (g_object_name, 'MULTIPLE_SALESREP');
  g_no_salesrep       VARCHAR2 (30)  := xx_emf_pkg.get_paramater_value (g_object_name, 'NO_SALESREP');
  g_no_territories    VARCHAR2 (30)  := NVL(xx_emf_pkg.get_paramater_value (g_object_name, 'NO_TERRITORIES'),'Territory Mismatch');
  g_program_source    VARCHAR2 (1)   := NULL;
  g_prog_stage        VARCHAR2 (200) := 'xx_oe_pop_salesrep_pkg Global';

PROCEDURE write_emf_log_high(
    p_debug_text  IN VARCHAR2,
    p_attribute1  IN VARCHAR2 DEFAULT NULL,
    p_attribute2  IN VARCHAR2 DEFAULT NULL,
    p_attribute3  IN VARCHAR2 DEFAULT NULL,
    p_attribute4  IN VARCHAR2 DEFAULT NULL,
    p_attribute5  IN VARCHAR2 DEFAULT NULL,
    p_attribute6  IN VARCHAR2 DEFAULT NULL,
    p_attribute7  IN VARCHAR2 DEFAULT NULL,
    p_attribute8  IN VARCHAR2 DEFAULT NULL,
    p_attribute9  IN VARCHAR2 DEFAULT NULL,
    p_attribute10 IN VARCHAR2 DEFAULT NULL )
IS
BEGIN
  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, p_debug_text,p_attribute1,p_attribute2,p_attribute3,p_attribute4,p_attribute5,p_attribute6,p_attribute7,p_attribute8,p_attribute9,p_attribute10);
END;
PROCEDURE write_emf_log_low(
    p_debug_text  IN VARCHAR2,
    p_attribute1  IN VARCHAR2 DEFAULT NULL,
    p_attribute2  IN VARCHAR2 DEFAULT NULL,
    p_attribute3  IN VARCHAR2 DEFAULT NULL,
    p_attribute4  IN VARCHAR2 DEFAULT NULL,
    p_attribute5  IN VARCHAR2 DEFAULT NULL,
    p_attribute6  IN VARCHAR2 DEFAULT NULL,
    p_attribute7  IN VARCHAR2 DEFAULT NULL,
    p_attribute8  IN VARCHAR2 DEFAULT NULL,
    p_attribute9  IN VARCHAR2 DEFAULT NULL,
    p_attribute10 IN VARCHAR2 DEFAULT NULL )
IS
BEGIN
  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, p_debug_text,p_attribute1,p_attribute2,p_attribute3,p_attribute4,p_attribute5,p_attribute6,p_attribute7,p_attribute8,p_attribute9,p_attribute10);
END;


PROCEDURE xx_find_territories(
    p_country             VARCHAR2 ,
    p_customer_name_range VARCHAR2 ,
    p_customer_id         NUMBER ,
    p_site_number         NUMBER,
    p_division            VARCHAR2,
    p_sub_division        VARCHAR2,
    p_dcode               VARCHAR2,
    p_surgeon_name        VARCHAR2,
    p_cust_account        VARCHAR2,
    p_county              VARCHAR2,
    p_postal_code         VARCHAR2,
    p_province            VARCHAR2,
    p_state               VARCHAR2,
    o_terr_id OUT NUMBER ,
    o_status OUT VARCHAR2 ,
    o_error_message OUT VARCHAR2 )
IS
  CURSOR cur_multiple_territories
  IS
    SELECT terr_id ,
      rank ,
      terr_name,
      select_flag,
      qualifier_name ,
      qualifier_value
    FROM xxintg.xx_o2c_salesrep_territory_data
    WHERE terr_id IS NOT NULL FOR UPDATE ;
  l_rank             NUMBER   := NULL;
  l_max_rank         NUMBER   := NULL;
  l_current_rank     NUMBER   := NULL;
  l_parent_terr_id   NUMBER   := NULL;
  l_current_terr_id  NUMBER   := NULL;
  l_terr_id          NUMBER;
  l_count            NUMBER := 0;
  l_multi_count      NUMBER := 0;
  l_territories_name VARCHAR2 (500);
  l_select_flag      VARCHAR2 (1);
  l_terr_select_flag VARCHAR2 (1);
  l_terr_count       NUMBER;
  l_exception_count  NUMBER;
BEGIN
  write_emf_log_low('Entering xx_find_territories ',NULL,NULL,p_country,p_customer_name_range,p_customer_id,p_site_number);
  BEGIN
    SELECT COUNT(1)
    INTO l_exception_count
    FROM xx_emf_process_setup xeps ,
      xx_emf_process_parameters xepp
    WHERE xeps.process_name = g_object_name
    AND xeps.process_id     = xepp.process_id
    AND upper (xepp.parameter_name) LIKE 'DIVISION_EXCEPTIONS%'
    AND NVL (xepp.enabled_flag, 'Y') = 'Y'
    AND xepp.parameter_value         = p_division;
  EXCEPTION
  WHEN OTHERS THEN
    l_exception_count := 0;
  END;
  IF l_exception_count != 0 THEN
    BEGIN
      INSERT
      INTO xxintg.xx_o2c_salesrep_territory_data
        (
          terr_id,
          rank,
          terr_name,
          qualifier_name,
          qualifier_value,
          unique_flag ,
          select_flag
        )
      SELECT jtqa.terr_id ,
        rank ,
        jta.name,
        jsqa.name qualifier_name,
        jtva.low_value_char,
        'Y',
        'Y'
      FROM jtf_terr_values jtva ,
        jtf_terr_qual jtqa ,
        jtf_qual_usgs jqua ,
        jtf_seeded_qual jsqa ,
        apps.jtf_terr jta
      WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
      AND jtqa.qual_usg_id         = jqua.qual_usg_id
      AND jqua.org_id              = jtqa.org_id
      AND jqua.enabled_flag        = 'Y'
      AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
      AND qual_type_usg_id         = -1001
      AND jtqa.terr_id             = jta.terr_id
      AND jsqa.name                = 'Division'
      AND jtva.comparison_operator = '='
      AND jtva.low_value_char      = p_division;
    EXCEPTION
    WHEN OTHERS THEN
      write_emf_log_low('Error inserting xx_o2c_salesrep_territory_data ' || sqlerrm);
    END;
  ELSE
    BEGIN
      INSERT
      INTO xxintg.xx_o2c_salesrep_territory_data
        (
          terr_id,
          rank,
          terr_name,
          qualifier_name,
          qualifier_value
        )
      SELECT DISTINCT terr_id ,
        rank ,
        name,
        qualifier_name,
        low_value_char
      FROM
        (SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'Country'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char      = p_country
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id = jtqa.terr_qual_id
        AND jtqa.qual_usg_id    = jqua.qual_usg_id
        AND jqua.org_id         = jtqa.org_id
        AND jqua.enabled_flag   = 'Y'
        AND jqua.seeded_qual_id = jsqa.seeded_qual_id
        AND qual_type_usg_id    = -1001
        AND jtqa.terr_id        = jta.terr_id
        AND jsqa.name           = 'Customer Name Range'
          -- Condition splited for Ticket  # 2381
        AND ((jtva.comparison_operator = 'LIKE'
        AND p_customer_name_range LIKE '%'
          || jtva.low_value_char
          || '%')
        OR (jtva.comparison_operator = '='
        AND p_customer_name_range    = jtva.low_value_char )
        OR (jtva.comparison_operator = 'BETWEEN'
        AND p_customer_name_range BETWEEN jtva.low_value_char AND jtva.high_value_char) )
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'Customer Name'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char_id   = p_customer_id
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'Site Number'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char_id   = p_site_number
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'Division'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char      = p_division
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'Sub Division'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char      = p_sub_division
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id         = jtqa.terr_qual_id
        AND jtqa.qual_usg_id            = jqua.qual_usg_id
        AND jqua.org_id                 = jtqa.org_id
        AND jqua.enabled_flag           = 'Y'
        AND jqua.seeded_qual_id         = jsqa.seeded_qual_id
        AND qual_type_usg_id            = -1001
        AND jtqa.terr_id                = jta.terr_id
        AND jsqa.name                   = 'Dcode'
        AND ( (jtva.comparison_operator = 'LIKE'
        AND p_dcode LIKE '%'
          || jtva.low_value_char
          || '%')
        OR (jtva.comparison_operator = '='
        AND p_dcode                  = jtva.low_value_char )
        OR (jtva.comparison_operator = 'BETWEEN'
        AND p_dcode BETWEEN jtva.low_value_char AND jtva.high_value_char) )
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'Surgeon Name'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char      = p_surgeon_name
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id         = jtqa.terr_qual_id
        AND jtqa.qual_usg_id            = jqua.qual_usg_id
        AND jqua.org_id                 = jtqa.org_id
        AND jqua.enabled_flag           = 'Y'
        AND jqua.seeded_qual_id         = jsqa.seeded_qual_id
        AND qual_type_usg_id            = -1001
        AND jtqa.terr_id                = jta.terr_id
        AND jsqa.name                   = 'Customer Account Number'
        AND ( (jtva.comparison_operator = 'LIKE'
        AND p_cust_account LIKE '%'
          || jtva.low_value_char
          || '%')
        OR (jtva.comparison_operator = '='
        AND p_cust_account           = jtva.low_value_char )
        OR (jtva.comparison_operator = 'BETWEEN'
        AND p_cust_account BETWEEN jtva.low_value_char AND jtva.high_value_char) )
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'County'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char      = p_county
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'Province'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char      = p_province
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id         = jtqa.terr_qual_id
        AND jtqa.qual_usg_id            = jqua.qual_usg_id
        AND jqua.org_id                 = jtqa.org_id
        AND jqua.enabled_flag           = 'Y'
        AND jqua.seeded_qual_id         = jsqa.seeded_qual_id
        AND qual_type_usg_id            = -1001
        AND jtqa.terr_id                = jta.terr_id
        AND jsqa.name                   = 'Postal Code'
        AND ( (jtva.comparison_operator = 'LIKE'
        AND p_postal_code LIKE '%'
          || jtva.low_value_char
          || '%')
        OR (jtva.comparison_operator = '='
        AND p_postal_code            = jtva.low_value_char )
        OR (jtva.comparison_operator = 'BETWEEN'
        AND p_postal_code BETWEEN jtva.low_value_char AND jtva.high_value_char) )
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'State'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char      = p_state
        )
      ORDER BY rank ;
    EXCEPTION
    WHEN OTHERS THEN
      write_emf_log_low('Error inserting xx_o2c_salesrep_territory_data ' || sqlerrm);
    END;
    BEGIN
      INSERT
      INTO xxintg.xx_o2c_salesrep_territory_data
        (
          qualifier_name,
          qualifier_value
        )
        (SELECT 'Country',p_country FROM dual
          UNION ALL
          SELECT 'Customer Name Range',p_customer_name_range FROM dual
          UNION ALL
          SELECT 'Customer Name',TO_CHAR(p_customer_id) FROM dual
          UNION ALL
          SELECT 'Site Number',TO_CHAR(p_site_number) FROM dual
          UNION ALL
          SELECT 'Division',p_division FROM dual
          UNION ALL
          SELECT 'Sub Division',p_sub_division FROM dual
          UNION ALL
          SELECT 'Dcode',p_dcode FROM dual
          UNION ALL
          SELECT 'Surgeon Name',p_surgeon_name FROM dual
          UNION ALL
          SELECT 'Customer Account Number',p_cust_account FROM dual
          UNION ALL
          SELECT 'County',p_county FROM dual
          UNION ALL
          SELECT 'Province',p_province FROM dual
          UNION ALL
          SELECT 'Postal Code',p_postal_code FROM dual
          UNION ALL
          SELECT 'State',p_state FROM dual
        );
    EXCEPTION
    WHEN OTHERS THEN
      write_emf_log_low('Error inserting xx_o2c_salesrep_territory_data ' || sqlerrm);
    END;
    FOR rec_cur_multiple_territories IN cur_multiple_territories
    LOOP
      l_current_rank         :=rec_cur_multiple_territories.rank ;
      l_max_rank             :=rec_cur_multiple_territories.rank ;
      l_parent_terr_id       :=rec_cur_multiple_territories.terr_id ;
      l_current_terr_id      :=rec_cur_multiple_territories.terr_id ;
      l_select_flag          := 'Y';
      WHILE l_parent_terr_id <> 1
      LOOP
        BEGIN
          SELECT parent_territory_id,
            rank
          INTO l_parent_terr_id,
            l_current_rank
          FROM apps.jtf_terr jta
          WHERE terr_id = l_current_terr_id;
        EXCEPTION
        WHEN OTHERS THEN
          l_parent_terr_id := 1;
        END;
        IF l_parent_terr_id  != 1 THEN
          l_terr_select_flag := 'N';
          l_terr_count       := 0;
          FOR qua_row        IN
          (SELECT jtva.low_value_char std_qua_value,
            xxmstd.qualifier_value cust_qua_value,
            qualifier_name
          FROM jtf_terr_values jtva ,
            jtf_terr_qual jtqa ,
            jtf_qual_usgs jqua ,
            jtf_seeded_qual jsqa ,
            apps.jtf_terr jta,
            xxintg.xx_o2c_salesrep_territory_data xxmstd
          WHERE jtva.terr_qual_id                          = jtqa.terr_qual_id
          AND jtqa.qual_usg_id                             = jqua.qual_usg_id
          AND jqua.org_id                                  = jtqa.org_id
          AND jqua.enabled_flag                            = 'Y'
          AND jqua.seeded_qual_id                          = jsqa.seeded_qual_id
          AND qual_type_usg_id                             = -1001
          AND jtqa.terr_id                                 = jta.terr_id
          AND jsqa.name                                    = qualifier_name
          AND jtqa.terr_id                                 = l_parent_terr_id
          AND rec_cur_multiple_territories.qualifier_name != qualifier_name
          )
          LOOP
            l_terr_count            := l_terr_count + 1;
            IF qua_row.std_qua_value = qua_row.cust_qua_value THEN
              l_terr_select_flag    := 'Y';
            END IF;
          END LOOP;
          IF l_terr_select_flag = 'N' AND l_terr_count != 0 THEN
            l_select_flag      := 'N';
          END IF;
          l_current_terr_id := l_parent_terr_id;
        END IF;
      END LOOP;
      IF l_select_flag = 'Y' THEN
        UPDATE xxintg.xx_o2c_salesrep_territory_data
        SET select_flag = 'Y'
        WHERE CURRENT OF cur_multiple_territories;
      END IF;
    END LOOP;
  END IF;
  SELECT COUNT(1)
  INTO l_count
  FROM xxintg.xx_o2c_salesrep_territory_data
  WHERE select_flag  = 'Y';
  IF l_count         = 0 THEN
    o_terr_id       := -9999;
    o_status        := 'Error';
    o_error_message := 'No matching territories found for the attributes';
    write_emf_log_low('Inside l_count         = 0   ',NULL,NULL,p_country,p_customer_name_range,p_customer_id,p_site_number);
  ELSE
    UPDATE xxintg.xx_o2c_salesrep_territory_data
    SET unique_flag   = 'Y'
    WHERE select_flag = 'Y'
    AND rank          =
      (SELECT MIN(rank)
      FROM xxintg.xx_o2c_salesrep_territory_data
      WHERE select_flag = 'Y'
      ) ;
    UPDATE xxintg.xx_o2c_salesrep_territory_data
    SET unique_flag = 'D'
    WHERE terr_id  IN
      (SELECT terr_id
      FROM xxintg.xx_o2c_salesrep_territory_data
      WHERE select_flag = 'Y'
      AND unique_flag   = 'Y'
      HAVING COUNT(1)  !=
        (SELECT MAX(COUNT(1))
        FROM xxintg.xx_o2c_salesrep_territory_data
        WHERE select_flag = 'Y'
        AND unique_flag   = 'Y'
        GROUP BY terr_id
        )
      GROUP BY terr_id
      );
    o_status        := 'Success';
    o_error_message := NULL;
    write_emf_log_low('Inside l_count         = 1   ',NULL,NULL,p_country,p_customer_name_range,p_customer_id,p_site_number);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  o_terr_id       := -9999;
  o_status        := 'Error';
  o_error_message := 'Unexpected Error occured in find_territories procedure ' ;
  write_emf_log_high('Exception xx_find_territories ' || sqlerrm,NULL,NULL,p_country,p_customer_name_range,p_customer_id,p_site_number);
END xx_find_territories;


PROCEDURE xx_ins_sales_credit_record(
    p_line_scredit_tbl IN OUT oe_order_pub.line_scredit_tbl_type ,
    p_org_id           IN NUMBER ,
    o_return_status OUT VARCHAR2 ,
    o_return_message OUT VARCHAR2 )
IS


type l_salescredit_type
IS
  record
  (
    salesrep_id jtf_rs_salesreps.salesrep_id%type,
    role_id jtf_rs_defresroles_vl.role_id%type,
    terr_id jtf_rs_defresroles_vl.attribute1%type,
    terr_name jtf_rs_defresroles_vl.attribute2%type) ;
type l_salescredit_id_tbl_type
IS
  TABLE OF l_salescredit_type INDEX BY binary_integer;
type l_lines_salescredit_type
IS
  record
  (
    salesrep_id jtf_rs_salesreps.salesrep_id%type,
    role_id jtf_rs_defresroles_vl.role_id%type,
    percent oe_sales_credits.percent%type,
    sales_credit_id oe_sales_credits.sales_credit_id%type) ;
type l_lines_salescredit_tbl_type
IS
  TABLE OF l_lines_salescredit_type INDEX BY binary_integer;

  l_index NUMBER := 1;
  l_lines_salescredit_tbl_rec l_lines_salescredit_tbl_type;
  l_salesrep_id_tbl_rec l_salescredit_id_tbl_type;
  l_tot_credit NUMBER                                              := 0;
  l_winn_terr_name xxintg.xx_o2c_salesrep_territory_data.terr_name%type := NULL;
  l_winn_terr_id xxintg.xx_o2c_salesrep_territory_data.terr_id%type     := NULL;
  l_lines_salesrep oe_order_lines_all.salesrep_id%type             := 0;
  l_credit_salesrep oe_order_lines_all.salesrep_id%type            := 0;
  l_no_salesrep oe_order_lines_all.salesrep_id%type                := 0;

BEGIN
  FOR c_terr_row IN
  (SELECT terr_id
  FROM xxintg.xx_o2c_salesrep_territory_data
  WHERE select_flag = 'Y'
  AND unique_flag   = 'Y'
  )
  LOOP
    ---write_emf_log_low('Entering ins_sales_credit_record',p_header_id,p_line_id,c_terr_row.terr_id);
    Null;
  END LOOP;
  FOR c_salesrep_rec IN
  (SELECT rs.resource_id ,
    rs.salesrep_number ,
    rs.salesrep_id ,
    rol.role_id,
    xmstd.terr_id,
    xmstd.terr_name
  FROM jtf_terr_rsc_all jtr ,
    jtf_rs_salesreps rs ,
    (SELECT jrd.role_id ,
      rs.resource_id
    FROM jtf_rs_salesreps rs ,
      jtf_rs_defresroles_vl jrd
    WHERE sysdate BETWEEN NVL (rs.start_date_active , sysdate) AND NVL (end_date_active, sysdate)
    AND jrd.role_resource_id = rs.resource_id
    AND jrd.role_type_name   = 'Sales Compensation'
    AND sysdate BETWEEN NVL (jrd.res_rl_start_date , sysdate ) AND NVL (jrd.res_rl_end_date, sysdate)
    AND delete_flag = 'N'
    ) rol,
    xxintg.xx_o2c_salesrep_territory_data xmstd
  WHERE jtr.terr_id = xmstd.terr_id
  AND sysdate BETWEEN NVL (jtr.start_date_active, sysdate) AND NVL (jtr.end_date_active, sysdate)
  AND sysdate BETWEEN NVL (rs.start_date_active, sysdate) AND NVL (rs.end_date_active, sysdate)
  AND rs.org_id          = p_org_id
  AND select_flag        = 'Y'
  AND unique_flag        = 'Y'
  AND rs.resource_id     = jtr.resource_id
  AND rol.resource_id(+) = rs.resource_id
  )
  LOOP
    l_salesrep_id_tbl_rec (l_index).salesrep_id := c_salesrep_rec.salesrep_id;
    l_salesrep_id_tbl_rec (l_index).role_id     := c_salesrep_rec.role_id;
    l_salesrep_id_tbl_rec (l_index).terr_id     := c_salesrep_rec.terr_id;
    l_salesrep_id_tbl_rec (l_index).terr_name   := c_salesrep_rec.terr_name;
    l_index                                     := l_index + 1;
  END LOOP;
  IF l_salesrep_id_tbl_rec.count = 0 THEN
    o_return_status  := 'Error';
    o_return_message := 'No active Resources is attached ';
  ELSE
      FOR l_salesrep_cnt IN l_salesrep_id_tbl_rec.first .. l_salesrep_id_tbl_rec.last
      LOOP
        p_line_scredit_tbl (l_salesrep_cnt).salesrep_id := l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_id;
        p_line_scredit_tbl (l_salesrep_cnt).sales_group_id       := l_salesrep_id_tbl_rec (l_salesrep_cnt).role_id;
        p_line_scredit_tbl (l_salesrep_cnt).attribute2           := l_salesrep_id_tbl_rec (l_salesrep_cnt).terr_id;
        p_line_scredit_tbl (l_salesrep_cnt).attribute1           := l_salesrep_id_tbl_rec (l_salesrep_cnt).terr_name;
        p_line_scredit_tbl (l_salesrep_cnt).sales_credit_type_id := 1;
        p_line_scredit_tbl (l_salesrep_cnt).percent              := TRUNC ((100  / l_salesrep_id_tbl_rec.count), 3);
        l_tot_credit                                             := l_tot_credit + p_line_scredit_tbl (l_salesrep_cnt).percent;
        IF l_salesrep_cnt                                         = l_salesrep_id_tbl_rec.last THEN
          p_line_scredit_tbl (l_salesrep_cnt).percent            := p_line_scredit_tbl (l_salesrep_cnt).percent + (100 - l_tot_credit);
        END IF;
      END LOOP;
    o_return_status  := 'Success';
    o_return_message := 'Successfully populated salesrep';
  END IF;
EXCEPTION
WHEN OTHERS THEN
  o_return_status  := 'Error';
  o_return_message := 'Unexpected Error ';
END xx_ins_sales_credit_record;


FUNCTION xx_oe_get_sales_rep_detail(p_inventory_item_id number,p_customer_id number,p_org_id number,p_ship_to_org_id number)
return varchar2
IS
PRAGMA AUTONOMOUS_TRANSACTION;
CURSOR c_get_customer_detail
IS
    SELECT hps.party_id ,
      hp.party_name ,
      hl.country ,
      hps.party_site_id,
      mc.segment4,
      mc.segment10,
      mc.segment9,
      account_number,
      hl.county,
      hl.postal_code,
      hl.province,
      hl.state,
      msi.attribute1
    FROM  hz_cust_site_uses hcsu ,
      hz_cust_acct_sites hcas ,
      hz_party_sites hps ,
      hz_locations hl ,
      hz_parties hp,
      mtl_category_sets mcs,
      mtl_item_categories mic,
      mtl_categories_b mc,
      hz_cust_accounts hca,
      mtl_system_items_b msi
    WHERE  hcsu.site_use_id       = p_ship_to_org_id
    AND hcsu.site_use_code     = 'SHIP_TO'
    AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
    AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id(+)
    AND hcas.party_site_id     = hps.party_site_id(+)
    AND hl.location_id(+)      = hps.location_id
    AND hp.party_id            = hps.party_id
    AND hps.status             = 'A'
    AND hp.status              = 'A'
    AND hcas.status            = 'A'
    AND hcsu.status            = 'A'
    AND mcs.category_set_name              = xx_emf_pkg.get_paramater_value ('XX_OE_ASSIGN_SALESREP', 'CATEGORY_NAME' )
    AND mcs.category_set_id                = mic.category_set_id
    AND mic.inventory_item_id              = p_inventory_item_id
    AND mic.organization_id                = fnd_profile.value ('MSD_MASTER_ORG')
    AND mic.inventory_item_id              = msi.inventory_item_id
    AND mic.organization_id                = msi.organization_id
    AND mc.category_id                     = mic.category_id
    AND mc.enabled_flag                    = 'Y'
    AND NVL (mc.disable_date, sysdate + 1) > sysdate
    AND hca.cust_account_id                = p_customer_id;

  x_action_type       VARCHAR2 (10) := NULL;
  x_validation_status VARCHAR2 (30) := NULL;
  x_return_status     VARCHAR2 (10) := NULL;
  x_error_message     VARCHAR2 (2000);
  x_territory_status  VARCHAR2 (10);
  x_msg_count         NUMBER;
  x_msg_data          VARCHAR2 (2000);
  x_org_id            NUMBER;
  x_return_message    VARCHAR2 (2000);
  x_error_code        NUMBER      := xx_emf_cn_pkg.cn_success;
  x_terr_id jtf_terr.terr_id%type := NULL;
  x_ord_number NUMBER;

  x_line_scredit_tbl oe_order_pub.line_scredit_tbl_type;
  x_msg_string      VARCHAR2(4000) := NULL;

  l_rep_name        VARCHAR2(50);
  l_comm_flag       VARCHAR2 (10);

BEGIN

DBMS_OUTPUT.PUT_LINE ('START');
x_msg_string := Null;

BEGIN
mo_global.set_policy_context('S',p_org_id);
END;

FOR order_details_info IN c_get_customer_detail
LOOP

xx_oe_pop_salesrep_pkg.xx_find_territories (p_country => order_details_info.country
                      , p_customer_name_range => order_details_info.party_name
                      , p_customer_id => order_details_info.party_id
                      , p_site_number => order_details_info.party_site_id
                      , p_division => order_details_info.segment4
                      , p_sub_division => order_details_info.segment10
                      , p_dcode => order_details_info.segment9
                      , p_surgeon_name => Null ---order_details_info.attribute8
                      , p_cust_account => order_details_info.account_number
                      , p_county => order_details_info.county
                      , p_postal_code => order_details_info.postal_code
                      , p_province => order_details_info.province
                      , p_state => order_details_info.state
                      , o_terr_id => x_terr_id
                      , o_status => x_territory_status
                      , o_error_message => x_error_message );

l_comm_flag := order_details_info.attribute1;

END LOOP;

IF p_inventory_item_id IS NULL OR p_customer_id IS NULL OR p_ship_to_org_id IS NULL
THEN
 x_msg_string := 'Either Item OR Customer# OR Ship-To Location Field is Null, Please Verify The Same';
 return x_msg_string;
ELSIF p_inventory_item_id IS NOT NULL AND p_customer_id IS NOT NULL AND p_ship_to_org_id IS NOT NULL
THEN
BEGIN
xx_oe_pop_salesrep_pkg.xx_ins_sales_credit_record (p_line_scredit_tbl => x_line_scredit_tbl ,
                            p_org_id => p_org_id,
                            o_return_status => x_return_status,
                            o_return_message => x_return_message );

       x_msg_string := 'Salesrep Name                       | Territory Name ';
       x_msg_string := x_msg_string ||CHR(10)||'-----------------------------------------------------------';

IF x_line_scredit_tbl.count = 0
Then
      x_msg_string := x_msg_string ||CHR(10)||'NO SALES CREDIT';
end if;

FOR l_salesrep_cnt  IN x_line_scredit_tbl.first .. x_line_scredit_tbl.last
LOOP

      l_rep_name := Null;
      BEGIN
        SELECT jrdv.resource_name
          INTO l_rep_name
          FROM jtf_rs_salesreps rs
              ,jtf_rs_defresources_v jrdv
         WHERE rs.salesrep_id =  x_line_scredit_tbl(l_salesrep_cnt).salesrep_id
           AND rs.resource_id = jrdv.resource_id
           AND rownum < 2;
      EXCEPTION
      WHEN OTHERS THEN
        l_rep_name := Null;
      END;

      x_msg_string := x_msg_string ||CHR(10)||RPAD(l_rep_name,35,'*')||' | '||x_line_scredit_tbl(l_salesrep_cnt).attribute1;
     --- x_msg_string := x_msg_string ||CHR(10)||l_rep_name||'                                   | '||x_line_scredit_tbl(l_salesrep_cnt).percent;

END LOOP;
      DBMS_OUTPUT.PUT_LINE (x_msg_string);
EXCEPTION
WHEN OTHERS THEN
   DBMS_OUTPUT.PUT_LINE ('Error '||SQLERRM);
   return x_msg_string;
END;
--ELSE
  --  x_msg_string := x_msg_string ||CHR(10)||'NO SALES CREDIT';
END IF;

    return x_msg_string;

EXCEPTION
WHEN OTHERS THEN
   DBMS_OUTPUT.PUT_LINE ('Main In Error '||SQLERRM);
   return x_msg_string;
END xx_oe_get_sales_rep_detail;


END xx_oe_pop_salesrep_pkg;
/
