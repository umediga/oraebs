DROP PACKAGE APPS.XX_EMF_PROCESS_PRM_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_EMF_PROCESS_PRM_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By   : IBM Development
 Creation Date: 07-MAR-2012
 File Name    : XXemfPRPRM.pks
 Description  : This Package spcification is used for insert,update,lock and delete procedures
                for the table XX_emf_PROCESS_parameters

 Change History:

 Date        Name               Remarks
 ----------- ----               ---------------------------------------
 07-MAR-2012 IBM Development   Initial development.
----------------------------------------------------------------------*/

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
   );

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
   );

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
   );

   PROCEDURE delete_row (x_rowid VARCHAR2);
END xx_emf_process_prm_pkg;
/


GRANT EXECUTE ON APPS.XX_EMF_PROCESS_PRM_PKG TO INTG_XX_NONHR_RO;
