DROP PACKAGE BODY APPS.XX_EMF_PROCESS_PRM_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_EMF_PROCESS_PRM_PKG" 
/*----------------------------------------------------------------------
 Created By   : IBM Development
 Creation Date: 07-MAR-2012
 File Name    : XXemfPRPRM.pkb
 Description  : This Package body is used for insert,update,lock and delete procedures
                for the table XX_emf_PROCESS_parameters
 Change History:
 Date        Name               Remarks
 ----------- ----               ---------------------------------------
 07-MAR-2012 IBM Development   Initial development.
----------------------------------------------------------------------
/*This procedure is used for inserting data into table XX_emf_PROCESS_SETUP and this procedure is called through form */
AS
   PROCEDURE insert_row (
      x_rowid                IN OUT   VARCHAR2,
      x_process_id                    NUMBER,
      x_parameter_id         IN OUT   NUMBER,
      x_param_seq                     NUMBER,
      x_parameter_name                VARCHAR2,
      x_parameter_value               VARCHAR2,
      x_enabled_flag                  VARCHAR2,
      x_org_id                        NUMBER,
      x_created_by                    NUMBER,
      x_creation_date                 DATE,
      x_last_update_date              DATE,
      x_last_updated_by               NUMBER,
      x_last_update_login             NUMBER
   )
   IS
      CURSOR c_process_parameters
      IS
         SELECT ROWID
           FROM xx_emf_process_parameters
          WHERE parameter_id = x_parameter_id;
   BEGIN
      SELECT xx_emf_process_setup_s.NEXTVAL
        INTO x_parameter_id
        FROM DUAL;
      INSERT INTO xx_emf_process_parameters
      (process_id,
       parameter_id,
       param_seq,
       parameter_name,
       parameter_value,
       enabled_flag,
       org_id,
       created_by,
       creation_date,
       last_update_date,
       last_updated_by,
       last_update_login
      )
      values
      (
      x_process_id,
      x_parameter_id,
      x_param_seq,
      x_parameter_name,
      x_parameter_value,
      x_enabled_flag,
      x_org_id,
      x_created_by,
      x_creation_date,
      x_last_update_date,
      x_last_updated_by,
      x_last_update_login
      );
      OPEN c_process_parameters;
      FETCH c_process_parameters INTO x_rowid;
      IF (c_process_parameters%NOTFOUND)
      THEN
         CLOSE c_process_parameters;
         RAISE NO_DATA_FOUND;
      END IF;
      CLOSE c_process_parameters;
   END insert_row;
   /* This procedure is used for lockin data of table XX_emf_PROCESS_SETUP and this procedure is called through form */
   PROCEDURE lock_row (
      x_rowid                         VARCHAR2,
      x_process_id                    NUMBER,
      x_parameter_id                  NUMBER,
      x_param_seq                     NUMBER,
      x_parameter_name                VARCHAR2,
      x_parameter_value               VARCHAR2,
      x_enabled_flag                  VARCHAR2,
      x_org_id                        NUMBER,
      x_created_by                    NUMBER,
      x_creation_date                 DATE,
      x_last_update_date              DATE,
      x_last_updated_by               NUMBER,
      x_last_update_login             NUMBER
   )
   IS
      CURSOR c_process_parameters
      IS
         SELECT        *
         FROM xx_emf_process_parameters
         WHERE ROWID = x_rowid
         FOR UPDATE OF parameter_id NOWAIT;
      recinfo   c_process_parameters%ROWTYPE;
   BEGIN
      OPEN c_process_parameters;
      FETCH c_process_parameters INTO recinfo;
      IF (c_process_parameters%NOTFOUND)
      THEN
         CLOSE c_process_parameters;
         fnd_message.set_name ('fnd', 'form_record_deleted');
         app_exception.raise_exception;
      END IF;
      CLOSE c_process_parameters;
      IF (    (recinfo.process_id = x_process_id)
          AND (   (recinfo.parameter_id = x_parameter_id)
              )
          AND (   (recinfo.param_seq = x_param_seq)
               OR ((recinfo.param_seq IS NULL) AND (x_param_seq IS NULL))
              )
          AND (   (recinfo.parameter_name = x_parameter_name)
               OR ((recinfo.parameter_name IS NULL) AND (x_parameter_name IS NULL))
              )
          AND (   (recinfo.parameter_value = x_parameter_value)
               OR (    (recinfo.parameter_value IS NULL)
                   AND (x_parameter_value IS NULL)
                  )
              )
          AND (   (recinfo.enabled_flag = x_enabled_flag)
               OR (    (recinfo.enabled_flag IS NULL)
                   AND (x_enabled_flag IS NULL)
                  )
              )
          AND (   (recinfo.org_id  = x_org_id )
               OR ((recinfo.org_id  IS NULL) AND (x_org_id  IS NULL))
              )
          AND (   (recinfo.created_by = x_created_by)
               OR ((recinfo.created_by IS NULL) AND (x_created_by IS NULL))
              )
          AND (   (recinfo.creation_date = x_creation_date)
               OR (    (recinfo.creation_date IS NULL)
                   AND (x_creation_date IS NULL)
                  )
              )
          AND (   (recinfo.last_update_date = x_last_update_date)
               OR (    (recinfo.last_update_date IS NULL)
                   AND (x_last_update_date IS NULL)
                  )
              )
          AND (   (recinfo.last_updated_by = x_last_updated_by)
               OR (    (recinfo.last_updated_by IS NULL)
                   AND (x_last_updated_by IS NULL)
                  )
              )
          AND (   (recinfo.last_update_login = x_last_update_login)
               OR (    (recinfo.last_update_login IS NULL)
                   AND (x_last_update_login IS NULL)
                  )
              )
         )
      THEN
         RETURN;
      ELSE
         fnd_message.set_name ('fnd', 'form_record_changed');
         app_exception.raise_exception;
      END IF;
   END lock_row;
   /* This procedure is used for updating data into table XX_emf_PROCESS_SETUP and this procedure is called through form */
   PROCEDURE update_row (
      x_rowid                         VARCHAR2,
      x_process_id                    NUMBER,
      x_parameter_id                  NUMBER,
      x_param_seq                     NUMBER,
      x_parameter_name                VARCHAR2,
      x_parameter_value               VARCHAR2,
      x_enabled_flag                  VARCHAR2,
      x_org_id                        NUMBER,
      x_created_by                    NUMBER,
      x_creation_date                 DATE,
      x_last_update_date              DATE,
      x_last_updated_by               NUMBER,
      x_last_update_login             NUMBER
   )
   IS
   BEGIN
      UPDATE xx_emf_process_parameters
      SET process_id = X_process_id,
          parameter_id = X_parameter_id,
          param_seq = X_param_seq,
          parameter_name = X_parameter_name,
          parameter_value = X_parameter_value,
          enabled_flag = X_enabled_flag,
          org_id = X_org_id,
          created_by = X_created_by,
          creation_date = X_creation_date,
          last_update_date = X_last_update_date,
          last_updated_by = X_last_updated_by,
          last_update_login = X_last_update_login
      WHERE ROWID = x_rowid;
      IF (SQL%NOTFOUND)
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   END update_row;
   /* This procedure is used for deleting data into table XX_emf_PROCESS_SETUP and this procedure is called through form */
   PROCEDURE delete_row (x_rowid VARCHAR2)
   IS
   BEGIN
      DELETE FROM xx_emf_process_parameters
      WHERE ROWID = x_rowid;
      IF (SQL%NOTFOUND)
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   END delete_row;
END xx_emf_process_prm_pkg;
/


GRANT EXECUTE ON APPS.XX_EMF_PROCESS_PRM_PKG TO INTG_XX_NONHR_RO;
