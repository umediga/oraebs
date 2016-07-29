DROP PACKAGE BODY APPS.XX_EMF_PROCESS_SETUP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_EMF_PROCESS_SETUP_PKG" 
AS
  ----------------------------------------------------------------------
  /*
 Created By   : IBM Development
 Creation Date: 07-MAR-2012
 File Name    : XXEMFPRSET.pkb
 Description  : This Package body is used for insert,update,lock and delete procedures
                for the table XX_emf_PROCESS_SETUP

 Change History:

 Date        Name               Remarks
 ----------- ----               ---------------------------------------
 07-MAR-2012 IBM Development   Initial development.
----------------------------------------------------------------------*/
  /* This procedure is used for inserting data into table XX_emf_PROCESS_SETUP and this procedure is called through form */
  PROCEDURE insert_row
       (x_rowid                 IN OUT VARCHAR2,
        x_process_id            IN OUT NUMBER,
        x_process_name          VARCHAR2,
        x_object_type           VARCHAR2,
        x_description           VARCHAR2,
        x_process_type          VARCHAR2,
        x_module_name           VARCHAR2,
        x_notification_group    VARCHAR2,
        x_run_frequency         VARCHAR2,
        x_runtime               VARCHAR2,
        x_enabled_flag          VARCHAR2,
        x_debug_level           NUMBER,
        x_debug_type            VARCHAR2,
        x_purge_interval        NUMBER,
        x_pre_validation_flag   VARCHAR2,
        x_post_validation_flag  VARCHAR2,
        x_error_tab_ind         VARCHAR2,
        x_error_log_ind         VARCHAR2,
        x_org_id                NUMBER,
        x_attribute_category    VARCHAR2,
        x_attribute1            VARCHAR2,
        x_attribute2            VARCHAR2,
        x_attribute3            VARCHAR2,
        x_attribute4            VARCHAR2,
        x_attribute5            VARCHAR2,
        x_attribute6            VARCHAR2,
        x_attribute7            VARCHAR2,
        x_attribute8            VARCHAR2,
        x_attribute9            VARCHAR2,
        x_attribute10           VARCHAR2,
        x_attribute11           VARCHAR2,
        x_attribute12           VARCHAR2,
        x_attribute13           VARCHAR2,
        x_attribute14           VARCHAR2,
        x_attribute15           VARCHAR2,
        x_attribute16           VARCHAR2,
        x_attribute17           VARCHAR2,
        x_attribute18           VARCHAR2,
        x_attribute19           VARCHAR2,
        x_attribute20           VARCHAR2,
        x_attribute21           VARCHAR2,
        x_attribute22           VARCHAR2,
        x_attribute23           VARCHAR2,
        x_attribute24           VARCHAR2,
        x_attribute25           VARCHAR2,
        x_attribute26           VARCHAR2,
        x_attribute27           VARCHAR2,
        x_attribute28           VARCHAR2,
        x_attribute29           VARCHAR2,
        x_attribute30           VARCHAR2,
        x_created_by            NUMBER,
        x_creation_date         DATE,
        x_last_update_date      DATE,
        x_last_updated_by       NUMBER,
        x_last_update_login     NUMBER)
  IS
    CURSOR c_process_setup IS
      SELECT rowid
      FROM   xx_emf_process_setup
      WHERE  process_id = x_process_id;
  BEGIN
    SELECT xx_emf_process_setup_s.nextval
    INTO   x_process_id
    FROM   dual;

    INSERT INTO xx_emf_process_setup
               (process_id,
                process_name,
                object_type,
                description,
                process_type,
                module_name,
                notification_group,
                run_frequency,
                runtime,
                enabled_flag,
                debug_level,
                debug_type,
                purge_interval,
                pre_validation_flag,
                post_validation_flag,
                error_tab_ind,
                error_log_ind,
                attribute_category,
                attribute1,
                attribute2,
                attribute3,
                attribute4,
                attribute5,
                attribute6,
                attribute7,
                attribute8,
                attribute9,
                attribute10,
                attribute11,
                attribute12,
                attribute13,
                attribute14,
                attribute15,
                attribute16,
                attribute17,
                attribute18,
                attribute19,
                attribute20,
                attribute21,
                attribute22,
                attribute23,
                attribute24,
                attribute25,
                attribute26,
                attribute27,
                attribute28,
                attribute29,
                attribute30,
                org_id,
                created_by,
                creation_date,
                last_update_date,
                last_updated_by,
                last_update_login)
    VALUES     (x_process_id,
                x_process_name,
                x_object_type,
                x_description,
                x_process_type,
                x_module_name,
                x_notification_group,
                x_run_frequency,
                x_runtime,
                x_enabled_flag,
                x_debug_level,
                x_debug_type,
                x_purge_interval,
                x_pre_validation_flag,
                x_post_validation_flag,
                x_error_tab_ind,
                x_error_log_ind,
                x_attribute_category,
                x_attribute1,
                x_attribute2,
                x_attribute3,
                x_attribute4,
                x_attribute5,
                x_attribute6,
                x_attribute7,
                x_attribute8,
                x_attribute9,
                x_attribute10,
                x_attribute11,
                x_attribute12,
                x_attribute13,
                x_attribute14,
                x_attribute15,
                x_attribute16,
                x_attribute17,
                x_attribute18,
                x_attribute19,
                x_attribute20,
                x_attribute21,
                x_attribute22,
                x_attribute23,
                x_attribute24,
                x_attribute25,
                x_attribute26,
                x_attribute27,
                x_attribute28,
                x_attribute29,
                x_attribute30,
                x_org_id,
                x_created_by,
                x_creation_date,
                x_last_update_date,
                x_last_updated_by,
                x_last_update_login);

    OPEN c_process_setup;

    FETCH c_process_setup INTO x_rowid;

    IF (c_process_setup%NOTFOUND) THEN
      CLOSE c_process_setup;

      RAISE no_data_found;
    END IF;

    CLOSE c_process_setup;
  END insert_row;

  /* This procedure is used for lockin data of table XX_emf_PROCESS_SETUP and this procedure is called through form */
  PROCEDURE lock_row
       (x_rowid                 VARCHAR2,
        x_process_id            NUMBER,
        x_process_name          VARCHAR2,
        x_object_type           VARCHAR2,
        x_description           VARCHAR2,
        x_process_type          VARCHAR2,
        x_module_name           VARCHAR2,
        x_notification_group    VARCHAR2,
        x_run_frequency         VARCHAR2,
        x_runtime               VARCHAR2,
        x_enabled_flag          VARCHAR2,
        x_debug_level           NUMBER,
        x_debug_type            VARCHAR2,
        x_purge_interval        NUMBER,
        x_pre_validation_flag   VARCHAR2,
        x_post_validation_flag  VARCHAR2,
        x_error_tab_ind         VARCHAR2,
        x_error_log_ind         VARCHAR2,
        x_org_id                NUMBER,
        x_attribute_category    VARCHAR2,
        x_attribute1            VARCHAR2,
        x_attribute2            VARCHAR2,
        x_attribute3            VARCHAR2,
        x_attribute4            VARCHAR2,
        x_attribute5            VARCHAR2,
        x_attribute6            VARCHAR2,
        x_attribute7            VARCHAR2,
        x_attribute8            VARCHAR2,
        x_attribute9            VARCHAR2,
        x_attribute10           VARCHAR2,
        x_attribute11           VARCHAR2,
        x_attribute12           VARCHAR2,
        x_attribute13           VARCHAR2,
        x_attribute14           VARCHAR2,
        x_attribute15           VARCHAR2,
        x_attribute16           VARCHAR2,
        x_attribute17           VARCHAR2,
        x_attribute18           VARCHAR2,
        x_attribute19           VARCHAR2,
        x_attribute20           VARCHAR2,
        x_attribute21           VARCHAR2,
        x_attribute22           VARCHAR2,
        x_attribute23           VARCHAR2,
        x_attribute24           VARCHAR2,
        x_attribute25           VARCHAR2,
        x_attribute26           VARCHAR2,
        x_attribute27           VARCHAR2,
        x_attribute28           VARCHAR2,
        x_attribute29           VARCHAR2,
        x_attribute30           VARCHAR2,
        x_created_by            NUMBER,
        x_creation_date         DATE,
        x_last_update_date      DATE,
        x_last_updated_by       NUMBER,
        x_last_update_login     NUMBER)
  IS
    CURSOR c_process_setup IS
      SELECT *
      FROM   xx_emf_process_setup
      WHERE  rowid = x_rowid
      FOR UPDATE OF process_id NOWAIT;
    recinfo  c_process_setup%ROWTYPE;
  BEGIN
    OPEN c_process_setup;

    FETCH c_process_setup INTO recinfo;

    IF (c_process_setup%NOTFOUND) THEN
      CLOSE c_process_setup;

      fnd_message.SET_NAME('fnd','form_record_deleted');

      app_exception.raise_exception;
    END IF;

    CLOSE c_process_setup;

    IF ((recinfo.process_id = x_process_id)
        AND ((recinfo.process_name = x_process_name)
              OR ((recinfo.process_name IS NULL)
                  AND (x_process_name IS NULL)))
        AND ((recinfo.object_type = x_object_type)
              OR ((recinfo.object_type IS NULL)
                  AND (x_object_type IS NULL)))
        AND ((recinfo.description = x_description)
              OR ((recinfo.description IS NULL)
                  AND (x_description IS NULL)))
        AND ((recinfo.process_type = x_process_type)
              OR ((recinfo.process_type IS NULL)
                  AND (x_process_type IS NULL)))
        AND ((recinfo.module_name = x_module_name)
              OR ((recinfo.module_name IS NULL)
                  AND (x_module_name IS NULL)))
        AND ((recinfo.notification_group = x_notification_group)
              OR ((recinfo.notification_group IS NULL)
                  AND (x_notification_group IS NULL)))
        AND ((recinfo.run_frequency = x_run_frequency)
              OR ((recinfo.run_frequency IS NULL)
                  AND (x_run_frequency IS NULL)))
        AND ((recinfo.runtime = x_runtime)
              OR ((recinfo.runtime IS NULL)
                  AND (x_runtime IS NULL)))
        AND ((recinfo.enabled_flag = x_enabled_flag)
              OR ((recinfo.enabled_flag IS NULL)
                  AND (x_enabled_flag IS NULL)))
        AND ((recinfo.debug_level = x_debug_level)
              OR ((recinfo.debug_level IS NULL)
                  AND (x_debug_level IS NULL)))
        AND ((recinfo.debug_type = x_debug_type)
              OR ((recinfo.debug_type IS NULL)
                  AND (x_debug_type IS NULL)))
        AND ((recinfo.purge_interval = x_purge_interval)
              OR ((recinfo.purge_interval IS NULL)
                  AND (x_purge_interval IS NULL)))
        AND ((recinfo.pre_validation_flag = x_pre_validation_flag)
              OR ((recinfo.pre_validation_flag IS NULL)
                  AND (x_pre_validation_flag IS NULL)))
        AND ((recinfo.post_validation_flag = x_post_validation_flag)
              OR ((recinfo.post_validation_flag IS NULL)
                  AND (x_post_validation_flag IS NULL)))
        AND ((recinfo.error_tab_ind = x_error_tab_ind)
              OR ((recinfo.error_tab_ind IS NULL)
                 AND (x_error_tab_ind IS NULL)))
        AND ((recinfo.error_log_ind = x_error_log_ind)
              OR ((recinfo.error_log_ind IS NULL)
                  AND (x_error_log_ind IS NULL)))
        AND ((recinfo.attribute1 = x_attribute1)
              OR ((recinfo.attribute1 IS NULL)
                  AND (x_attribute1 IS NULL)))
        AND ((recinfo.attribute2 = x_attribute2)
              OR ((recinfo.attribute2 IS NULL)
                  AND (x_attribute2 IS NULL)))
        AND ((recinfo.attribute3 = x_attribute3)
              OR ((recinfo.attribute3 IS NULL)
                  AND (x_attribute3 IS NULL)))
        AND ((recinfo.attribute4 = x_attribute4)
              OR ((recinfo.attribute4 IS NULL)
                  AND (x_attribute4 IS NULL)))
        AND ((recinfo.attribute5 = x_attribute5)
              OR ((recinfo.attribute5 IS NULL)
                  AND (x_attribute5 IS NULL)))
        AND ((recinfo.attribute6 = x_attribute6)
              OR ((recinfo.attribute6 IS NULL)
                  AND (x_attribute6 IS NULL)))
        AND ((recinfo.attribute7 = x_attribute7)
              OR ((recinfo.attribute7 IS NULL)
                  AND (x_attribute7 IS NULL)))
        AND ((recinfo.attribute8 = x_attribute8)
              OR ((recinfo.attribute8 IS NULL)
                  AND (x_attribute8 IS NULL)))
        AND ((recinfo.attribute9 = x_attribute9)
              OR ((recinfo.attribute9 IS NULL)
                  AND (x_attribute9 IS NULL)))
        AND ((recinfo.attribute10 = x_attribute10)
              OR ((recinfo.attribute10 IS NULL)
                  AND (x_attribute10 IS NULL)))
        AND ((recinfo.attribute11 = x_attribute11)
              OR ((recinfo.attribute11 IS NULL)
                  AND (x_attribute11 IS NULL)))
        AND ((recinfo.attribute12 = x_attribute12)
              OR ((recinfo.attribute12 IS NULL)
                  AND (x_attribute12 IS NULL)))
        AND ((recinfo.attribute13 = x_attribute13)
              OR ((recinfo.attribute13 IS NULL)
                  AND (x_attribute13 IS NULL)))
        AND ((recinfo.attribute14 = x_attribute14)
              OR ((recinfo.attribute14 IS NULL)
                  AND (x_attribute14 IS NULL)))
        AND ((recinfo.attribute15 = x_attribute15)
              OR ((recinfo.attribute15 IS NULL)
                  AND (x_attribute15 IS NULL)))
        AND ((recinfo.attribute16 = x_attribute16)
              OR ((recinfo.attribute16 IS NULL)
                  AND (x_attribute16 IS NULL)))
        AND ((recinfo.attribute17 = x_attribute17)
              OR ((recinfo.attribute17 IS NULL)
                  AND (x_attribute17 IS NULL)))
        AND ((recinfo.attribute18 = x_attribute18)
              OR ((recinfo.attribute18 IS NULL)
                  AND (x_attribute18 IS NULL)))
        AND ((recinfo.attribute19 = x_attribute19)
              OR ((recinfo.attribute19 IS NULL)
                  AND (x_attribute19 IS NULL)))
        AND ((recinfo.attribute20 = x_attribute20)
              OR ((recinfo.attribute20 IS NULL)
                  AND (x_attribute20 IS NULL)))
        AND ((recinfo.attribute21 = x_attribute21)
              OR ((recinfo.attribute21 IS NULL)
                  AND (x_attribute21 IS NULL)))
        AND ((recinfo.attribute22 = x_attribute22)
              OR ((recinfo.attribute22 IS NULL)
                  AND (x_attribute22 IS NULL)))
        AND ((recinfo.attribute23 = x_attribute23)
              OR ((recinfo.attribute23 IS NULL)
                  AND (x_attribute23 IS NULL)))
        AND ((recinfo.attribute24 = x_attribute24)
              OR ((recinfo.attribute24 IS NULL)
                  AND (x_attribute24 IS NULL)))
        AND ((recinfo.attribute25 = x_attribute25)
              OR ((recinfo.attribute25 IS NULL)
                  AND (x_attribute25 IS NULL)))
        AND ((recinfo.attribute26 = x_attribute26)
              OR ((recinfo.attribute26 IS NULL)
                  AND (x_attribute26 IS NULL)))
        AND ((recinfo.attribute27 = x_attribute27)
              OR ((recinfo.attribute27 IS NULL)
                  AND (x_attribute27 IS NULL)))
        AND ((recinfo.attribute28 = x_attribute28)
              OR ((recinfo.attribute28 IS NULL)
                  AND (x_attribute28 IS NULL)))
        AND ((recinfo.attribute29 = x_attribute29)
              OR ((recinfo.attribute29 IS NULL)
                  AND (x_attribute29 IS NULL)))
        AND ((recinfo.attribute30 = x_attribute30)
              OR ((recinfo.attribute30 IS NULL)
                  AND (x_attribute30 IS NULL)))
        AND ((recinfo.org_id = x_org_id)
              OR ((recinfo.org_id IS NULL)
                  AND (x_org_id IS NULL)))
        AND ((recinfo.created_by = x_created_by)
              OR ((recinfo.created_by IS NULL)
                  AND (x_created_by IS NULL)))
        AND ((recinfo.creation_date = x_creation_date)
              OR ((recinfo.creation_date IS NULL)
                  AND (x_creation_date IS NULL)))
        AND ((recinfo.last_update_date = x_last_update_date)
              OR ((recinfo.last_update_date IS NULL)
                  AND (x_last_update_date IS NULL)))
        AND ((recinfo.last_updated_by = x_last_updated_by)
              OR ((recinfo.last_updated_by IS NULL)
                  AND (x_last_updated_by IS NULL)))
        AND ((recinfo.last_update_login = x_last_update_login)
              OR ((recinfo.last_update_login IS NULL)
                  AND (x_last_update_login IS NULL)))) THEN
      RETURN;
    ELSE
      fnd_message.SET_NAME('fnd','form_record_changed');

      app_exception.raise_exception;
    END IF;
  END lock_row;

  /* This procedure is used for updating data into table XX_emf_PROCESS_SETUP and this procedure is called through form */
  PROCEDURE update_row
       (x_rowid                 VARCHAR2,
        x_process_id            NUMBER,
        x_process_name          VARCHAR2,
        x_object_type           VARCHAR2,
        x_description           VARCHAR2,
        x_process_type          VARCHAR2,
        x_module_name           VARCHAR2,
        x_notification_group    VARCHAR2,
        x_run_frequency         VARCHAR2,
        x_runtime               VARCHAR2,
        x_enabled_flag          VARCHAR2,
        x_debug_level           NUMBER,
        x_debug_type            VARCHAR2,
        x_purge_interval        NUMBER,
        x_pre_validation_flag   VARCHAR2,
        x_post_validation_flag  VARCHAR2,
        x_error_tab_ind         VARCHAR2,
        x_error_log_ind         VARCHAR2,
        x_org_id                NUMBER,
        x_attribute_category    VARCHAR2,
        x_attribute1            VARCHAR2,
        x_attribute2            VARCHAR2,
        x_attribute3            VARCHAR2,
        x_attribute4            VARCHAR2,
        x_attribute5            VARCHAR2,
        x_attribute6            VARCHAR2,
        x_attribute7            VARCHAR2,
        x_attribute8            VARCHAR2,
        x_attribute9            VARCHAR2,
        x_attribute10           VARCHAR2,
        x_attribute11           VARCHAR2,
        x_attribute12           VARCHAR2,
        x_attribute13           VARCHAR2,
        x_attribute14           VARCHAR2,
        x_attribute15           VARCHAR2,
        x_attribute16           VARCHAR2,
        x_attribute17           VARCHAR2,
        x_attribute18           VARCHAR2,
        x_attribute19           VARCHAR2,
        x_attribute20           VARCHAR2,
        x_attribute21           VARCHAR2,
        x_attribute22           VARCHAR2,
        x_attribute23           VARCHAR2,
        x_attribute24           VARCHAR2,
        x_attribute25           VARCHAR2,
        x_attribute26           VARCHAR2,
        x_attribute27           VARCHAR2,
        x_attribute28           VARCHAR2,
        x_attribute29           VARCHAR2,
        x_attribute30           VARCHAR2,
        x_created_by            NUMBER,
        x_creation_date         DATE,
        x_last_update_date      DATE,
        x_last_updated_by       NUMBER,
        x_last_update_login     NUMBER)
  IS
  BEGIN
    UPDATE xx_emf_process_setup
    SET    process_id = x_process_id,
           process_name = x_process_name,
           object_type = x_object_type,
           description = x_description,
           process_type = x_process_type,
           module_name = x_module_name,
           notification_group = x_notification_group,
           run_frequency = x_run_frequency,
           runtime = x_runtime,
           enabled_flag = x_enabled_flag,
           debug_level = x_debug_level,
           debug_type = x_debug_type,
           purge_interval = x_purge_interval,
           pre_validation_flag = x_pre_validation_flag,
           post_validation_flag = x_post_validation_flag,
           error_tab_ind = x_error_tab_ind,
           error_log_ind = x_error_log_ind,
           org_id = x_org_id,
           attribute_category = x_attribute_category,
           attribute1 = x_attribute1,
           attribute2 = x_attribute2,
           attribute3 = x_attribute3,
           attribute4 = x_attribute4,
           attribute5 = x_attribute5,
           attribute6 = x_attribute6,
           attribute7 = x_attribute7,
           attribute8 = x_attribute8,
           attribute9 = x_attribute9,
           attribute10 = x_attribute10,
           attribute11 = x_attribute11,
           attribute12 = x_attribute12,
           attribute13 = x_attribute13,
           attribute14 = x_attribute14,
           attribute15 = x_attribute15,
           attribute16 = x_attribute16,
           attribute17 = x_attribute17,
           attribute18 = x_attribute18,
           attribute19 = x_attribute19,
           attribute20 = x_attribute20,
           attribute21 = x_attribute21,
           attribute22 = x_attribute22,
           attribute23 = x_attribute23,
           attribute24 = x_attribute24,
           attribute25 = x_attribute25,
           attribute26 = x_attribute26,
           attribute27 = x_attribute27,
           attribute28 = x_attribute28,
           attribute29 = x_attribute29,
           attribute30 = x_attribute30,
           created_by = x_created_by,
           creation_date = x_creation_date,
           last_update_date = x_last_update_date,
           last_updated_by = x_last_updated_by,
           last_update_login = x_last_update_login
    WHERE  rowid = x_rowid;

    IF (SQL%NOTFOUND) THEN
      RAISE no_data_found;
    END IF;
  END update_row;

  /* This procedure is used for deleting data into table XX_emf_PROCESS_SETUP and this procedure is called through form */
  PROCEDURE delete_row
       (x_rowid  VARCHAR2)
  IS
  BEGIN
    DELETE FROM xx_emf_process_setup
    WHERE       rowid = x_rowid;

    IF (SQL%NOTFOUND) THEN
      RAISE no_data_found;
    END IF;
  END delete_row;
END xx_emf_process_setup_pkg;
/


GRANT EXECUTE ON APPS.XX_EMF_PROCESS_SETUP_PKG TO INTG_XX_NONHR_RO;
