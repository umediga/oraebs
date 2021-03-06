DROP PACKAGE APPS.XX_EMF_PROCESS_SETUP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_EMF_PROCESS_SETUP_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By   : IBM Development
 Creation Date: 07-MAR-2012
 File Name    : XXEMFPRSET.pks
 Description  : This Package specification is used for insert,update,lock and delete procedures
                for the table XX_emf_PROCESS_SETUP

 Change History:

 Date        Name               Remarks
 ----------- ----               ---------------------------------------
 07-MAR-2012 IBM Development   Initial development.
----------------------------------------------------------------------*/

   PROCEDURE insert_row (
      x_rowid                IN OUT   VARCHAR2,
      x_process_id           IN OUT   NUMBER,
      x_process_name                  VARCHAR2,
      x_object_type                   VARCHAR2,
      x_description                   VARCHAR2,
      x_process_type                  VARCHAR2,
      x_module_name                   VARCHAR2,
      x_notification_group            VARCHAR2,
      x_run_frequency                 VARCHAR2,
      x_runtime                       VARCHAR2,
      x_enabled_flag                  VARCHAR2,
      x_debug_level                   NUMBER,
      x_debug_type                    VARCHAR2,
      x_purge_interval                NUMBER,
      x_pre_validation_flag           VARCHAR2,
      x_post_validation_flag          VARCHAR2,
      x_error_tab_ind                 VARCHAR2,
      x_error_log_ind                 VARCHAR2,
      x_org_id                        NUMBER,
      x_attribute_category            VARCHAR2,
      x_attribute1                    VARCHAR2,
      x_attribute2                    VARCHAR2,
      x_attribute3                    VARCHAR2,
      x_attribute4                    VARCHAR2,
      x_attribute5                    VARCHAR2,
      x_attribute6                    VARCHAR2,
      x_attribute7                    VARCHAR2,
      x_attribute8                    VARCHAR2,
      x_attribute9                    VARCHAR2,
      x_attribute10                   VARCHAR2,
      x_attribute11                   VARCHAR2,
      x_attribute12                   VARCHAR2,
      x_attribute13                   VARCHAR2,
      x_attribute14                   VARCHAR2,
      x_attribute15                   VARCHAR2,
      x_attribute16                   VARCHAR2,
      x_attribute17                   VARCHAR2,
      x_attribute18                   VARCHAR2,
      x_attribute19                   VARCHAR2,
      x_attribute20                   VARCHAR2,
      x_attribute21                   VARCHAR2,
      x_attribute22                   VARCHAR2,
      x_attribute23                   VARCHAR2,
      x_attribute24                   VARCHAR2,
      x_attribute25                   VARCHAR2,
      x_attribute26                   VARCHAR2,
      x_attribute27                   VARCHAR2,
      x_attribute28                   VARCHAR2,
      x_attribute29                   VARCHAR2,
      x_attribute30                   VARCHAR2,
      x_created_by                    NUMBER,
      x_creation_date                 DATE,
      x_last_update_date              DATE,
      x_last_updated_by               NUMBER,
      x_last_update_login             NUMBER
   );

   PROCEDURE lock_row (
      x_rowid                         VARCHAR2,
      x_process_id                    NUMBER,
      x_process_name                  VARCHAR2,
      x_object_type                   VARCHAR2,
      x_description                   VARCHAR2,
      x_process_type                  VARCHAR2,
      x_module_name                   VARCHAR2,
      x_notification_group            VARCHAR2,
      x_run_frequency                 VARCHAR2,
      x_runtime                       VARCHAR2,
      x_enabled_flag                  VARCHAR2,
      x_debug_level                   NUMBER,
      x_debug_type                    VARCHAR2,
      x_purge_interval                NUMBER,
      x_pre_validation_flag           VARCHAR2,
      x_post_validation_flag          VARCHAR2,
      x_error_tab_ind                 VARCHAR2,
      x_error_log_ind                 VARCHAR2,
      x_org_id                        NUMBER,
      x_attribute_category            VARCHAR2,
      x_attribute1                    VARCHAR2,
      x_attribute2                    VARCHAR2,
      x_attribute3                    VARCHAR2,
      x_attribute4                    VARCHAR2,
      x_attribute5                    VARCHAR2,
      x_attribute6                    VARCHAR2,
      x_attribute7                    VARCHAR2,
      x_attribute8                    VARCHAR2,
      x_attribute9                    VARCHAR2,
      x_attribute10                   VARCHAR2,
      x_attribute11                   VARCHAR2,
      x_attribute12                   VARCHAR2,
      x_attribute13                   VARCHAR2,
      x_attribute14                   VARCHAR2,
      x_attribute15                   VARCHAR2,
      x_attribute16                   VARCHAR2,
      x_attribute17                   VARCHAR2,
      x_attribute18                   VARCHAR2,
      x_attribute19                   VARCHAR2,
      x_attribute20                   VARCHAR2,
      x_attribute21                   VARCHAR2,
      x_attribute22                   VARCHAR2,
      x_attribute23                   VARCHAR2,
      x_attribute24                   VARCHAR2,
      x_attribute25                   VARCHAR2,
      x_attribute26                   VARCHAR2,
      x_attribute27                   VARCHAR2,
      x_attribute28                   VARCHAR2,
      x_attribute29                   VARCHAR2,
      x_attribute30                   VARCHAR2,
      x_created_by                    NUMBER,
      x_creation_date                 DATE,
      x_last_update_date              DATE,
      x_last_updated_by               NUMBER,
      x_last_update_login             NUMBER
   );

   PROCEDURE update_row (
      x_rowid                         VARCHAR2,
      x_process_id                    NUMBER,
      x_process_name                  VARCHAR2,
      x_object_type                   VARCHAR2,
      x_description                   VARCHAR2,
      x_process_type                  VARCHAR2,
      x_module_name                   VARCHAR2,
      x_notification_group            VARCHAR2,
      x_run_frequency                 VARCHAR2,
      x_runtime                       VARCHAR2,
      x_enabled_flag                  VARCHAR2,
      x_debug_level                   NUMBER,
      x_debug_type                    VARCHAR2,
      x_purge_interval                NUMBER,
      x_pre_validation_flag           VARCHAR2,
      x_post_validation_flag          VARCHAR2,
      x_error_tab_ind                 VARCHAR2,
      x_error_log_ind                 VARCHAR2,
      x_org_id                        NUMBER,
      x_attribute_category            VARCHAR2,
      x_attribute1                    VARCHAR2,
      x_attribute2                    VARCHAR2,
      x_attribute3                    VARCHAR2,
      x_attribute4                    VARCHAR2,
      x_attribute5                    VARCHAR2,
      x_attribute6                    VARCHAR2,
      x_attribute7                    VARCHAR2,
      x_attribute8                    VARCHAR2,
      x_attribute9                    VARCHAR2,
      x_attribute10                   VARCHAR2,
      x_attribute11                   VARCHAR2,
      x_attribute12                   VARCHAR2,
      x_attribute13                   VARCHAR2,
      x_attribute14                   VARCHAR2,
      x_attribute15                   VARCHAR2,
      x_attribute16                   VARCHAR2,
      x_attribute17                   VARCHAR2,
      x_attribute18                   VARCHAR2,
      x_attribute19                   VARCHAR2,
      x_attribute20                   VARCHAR2,
      x_attribute21                   VARCHAR2,
      x_attribute22                   VARCHAR2,
      x_attribute23                   VARCHAR2,
      x_attribute24                   VARCHAR2,
      x_attribute25                   VARCHAR2,
      x_attribute26                   VARCHAR2,
      x_attribute27                   VARCHAR2,
      x_attribute28                   VARCHAR2,
      x_attribute29                   VARCHAR2,
      x_attribute30                   VARCHAR2,
      x_created_by                    NUMBER,
      x_creation_date                 DATE,
      x_last_update_date              DATE,
      x_last_updated_by               NUMBER,
      x_last_update_login             NUMBER
   );

   PROCEDURE delete_row (x_rowid VARCHAR2);
END xx_emf_process_setup_pkg;
/


GRANT EXECUTE ON APPS.XX_EMF_PROCESS_SETUP_PKG TO INTG_XX_NONHR_RO;
