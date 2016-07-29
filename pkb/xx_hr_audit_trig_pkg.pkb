DROP PACKAGE BODY APPS.XX_HR_AUDIT_TRIG_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_AUDIT_TRIG_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 08-Apr-2013
 File Name     : xx_hr_audit_trig.pkb
 Description   : This script creates the body of the package
                 xx_hr_audit_rpt_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 08-Apr-2013 Renjith               Initial Version
*/
----------------------------------------------------------------------
   x_user_id          NUMBER := FND_GLOBAL.USER_ID;
   x_resp_id          NUMBER := FND_GLOBAL.RESP_ID;
   x_resp_appl_id     NUMBER := FND_GLOBAL.RESP_APPL_ID;
   x_login_id         NUMBER := FND_GLOBAL.LOGIN_ID;
   x_request_id       NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
  ----------------------------------------------------------------------
  PROCEDURE insert_audit (  p_person_id              IN NUMBER
                           ,p_table_prim_id          IN NUMBER
                           ,p_table_name             IN VARCHAR2
                           ,p_data_element           IN VARCHAR2
                           ,p_data_value_old         IN VARCHAR2
                           ,p_data_value_new         IN VARCHAR2
                           ,p_data_element_upd_date  IN DATE
                           ,p_effective_start_date   IN DATE
                           ,p_effective_end_date     IN DATE
                           ,p_creation_date          IN DATE)
  IS
    x_record_id         NUMBER;
    x_exclude           VARCHAR2(1);
    x_userper_type      VARCHAR2(30);
    x_data_value_new    VARCHAR2(200);
  BEGIN

      BEGIN
        SELECT  data_value_new
          INTO  x_data_value_new
          FROM  xx_hr_payroll_aud_tbl tbl
         WHERE  tbl.person_id = p_person_id
           AND  tbl.data_element = p_table_name||'.'||p_data_element
           AND  record_id = (SELECT  MAX(record_id)
                               FROM  xx_hr_payroll_aud_tbl t
                              WHERE  t.person_id=tbl.person_id
                                AND  t.data_element = tbl.data_element);
      EXCEPTION
        WHEN OTHERS THEN
           x_data_value_new := NULL;
      END;

      --INSERT INTO test_hr values (1,p_person_id,p_table_name,p_data_element,'Old='||x_data_value_new,'New='||p_data_value_new);

      IF NVL(x_data_value_new,'X') <> NVL(p_data_value_new,'X')  THEN

         SELECT xx_hr_audit_aud_s.NEXTVAL
           INTO x_record_id
           FROM dual;

         INSERT INTO XX_HR_PAYROLL_AUD_TBL
          ( record_id
           ,person_id
           ,table_prim_id
           ,table_name
           ,data_element
           ,data_value_old
           ,data_value_new
           ,data_element_upd_date
           ,effective_start_date
           ,effective_end_date
           ,record_creation_date
           ,created_by
           ,creation_date
           ,last_update_date
           ,last_updated_by
           ,last_update_login
          )
         VALUES
          (  x_record_id                         -- record_id
            ,p_person_id                         -- person_id
            ,p_table_prim_id                     -- table_prim_id
            ,p_table_name                        -- table_name
            ,p_table_name||'.'||p_data_element   -- data_element
            ,p_data_value_old                    -- data_value_old
            ,p_data_value_new                    -- data_value_new
            ,p_data_element_upd_date             -- data_element_upd_date
            ,p_effective_start_date              -- effective_start_date
            ,p_effective_end_date                -- effective_end_date
            ,p_creation_date                     -- record_creation_date
            ,x_user_id                           -- created_by
            ,SYSDATE                             -- creation_date
            ,SYSDATE                             -- last_update_date
            ,x_user_id                           -- last_updated_by
            ,x_login_id                          -- last_update_login
           );
      END IF;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END insert_audit;

  -------------------------------------------------------------------------------------------------

  PROCEDURE insert_audit_date (  p_person_id              IN NUMBER
                                ,p_table_prim_id          IN NUMBER
                                ,p_table_name             IN VARCHAR2
                                ,p_data_element           IN VARCHAR2
                                ,p_data_value_old         IN VARCHAR2
                                ,p_data_value_new         IN VARCHAR2
                                ,p_data_element_upd_date  IN DATE
                                ,p_effective_start_date   IN DATE
                                ,p_effective_end_date     IN DATE
                                ,p_creation_date          IN DATE)
  IS
    x_record_id         NUMBER;
    x_exclude           VARCHAR2(1);
    x_userper_type      VARCHAR2(30);
    x_data_value_new    VARCHAR2(200);
  BEGIN
      BEGIN
        SELECT  data_value_new
          INTO  x_data_value_new
          FROM  xx_hr_payroll_aud_tbl tbl
         WHERE  tbl.person_id = p_person_id
           AND  tbl.data_element = p_table_name||'.'||p_data_element
           AND  record_id = (SELECT  MAX(record_id)
                               FROM  xx_hr_payroll_aud_tbl t
                              WHERE  t.person_id=tbl.person_id
                                AND  t.data_element = tbl.data_element);
      EXCEPTION
        WHEN OTHERS THEN
           x_data_value_new := NULL;
      END;

      IF NVL(x_data_value_new,'X') <> NVL(p_data_value_new,'X')  THEN

         SELECT xx_hr_audit_aud_s.NEXTVAL
           INTO x_record_id
           FROM dual;

         INSERT INTO XX_HR_PAYROLL_AUD_TBL
          ( record_id
           ,person_id
           ,table_prim_id
           ,table_name
           ,data_element
           ,data_value_old
           ,data_value_new
           ,data_element_upd_date
           ,effective_start_date
           ,effective_end_date
           ,record_creation_date
           ,created_by
           ,creation_date
           ,last_update_date
           ,last_updated_by
           ,last_update_login
          )
         VALUES
          (  x_record_id                         -- record_id
            ,p_person_id                         -- person_id
            ,p_table_prim_id                     -- table_prim_id
            ,p_table_name                        -- table_name
            ,p_table_name||'.'||p_data_element   -- data_element
            ,x_data_value_new                    -- data_value_old
            ,p_data_value_new                    -- data_value_new
            ,p_data_element_upd_date             -- data_element_upd_date
            ,p_effective_start_date              -- effective_start_date
            ,p_effective_end_date                -- effective_end_date
            ,p_creation_date                     -- record_creation_date
            ,x_user_id                           -- created_by
            ,SYSDATE                             -- creation_date
            ,SYSDATE                             -- last_update_date
            ,x_user_id                           -- last_updated_by
            ,x_login_id                          -- last_update_login
           );
      END IF;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END insert_audit_date;

END xx_hr_audit_trig_pkg;
/
