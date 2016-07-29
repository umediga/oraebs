DROP PACKAGE APPS.XX_EMF_PROCESS_FILES_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_EMF_PROCESS_FILES_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By   : IBM Development
 Creation Date: 07-MAR-2012
 File Name	  : XXemfPRFLS.pks
 Description  : This Package spcification is used for insert,update,lock and delete procedures
                for the table  XX_emf_PROCESS_FILES

 Change History:

 Date        Name               Remarks
 ----------- ----               ---------------------------------------
07-MAR-2012 IBM Development   Initial development.
----------------------------------------------------------------------*/
   PROCEDURE insert_row (
      x_rowid                IN OUT NOCOPY   VARCHAR2,
      x_process_id                           NUMBER,
      x_process_file_id      IN OUT NOCOPY   NUMBER,
      x_seq_no                               NUMBER,
      x_process_file_name                    VARCHAR2,
      x_direction                            VARCHAR2,
      x_trans_source                         VARCHAR2,
      x_file_directory                       VARCHAR2,
      x_source_destination                   VARCHAR2,
      x_last_run_date                        DATE,
      x_last_request_id                      NUMBER,
      x_last_run_status                      VARCHAR2,
      x_enabled_flag                         VARCHAR2,
      x_org_id                               NUMBER,
      x_created_by                           NUMBER,
      x_creation_date                        DATE,
      x_last_update_date                     DATE,
      x_last_updated_by                      NUMBER,
      x_last_update_login                    NUMBER
   );

   PROCEDURE lock_row (
      x_rowid                IN OUT NOCOPY   VARCHAR2,
      x_process_id                           NUMBER,
      x_process_file_id      IN OUT NOCOPY   NUMBER,
      x_seq_no                               NUMBER,
      x_process_file_name                    VARCHAR2,
      x_direction                            VARCHAR2,
      x_trans_source                         VARCHAR2,
      x_file_directory                       VARCHAR2,
      x_source_destination                   VARCHAR2,
      x_last_run_date                        DATE,
      x_last_request_id                      NUMBER,
      x_last_run_status                      VARCHAR2,
      x_enabled_flag                         VARCHAR2,
      x_org_id                               NUMBER,
      x_created_by                           NUMBER,
      x_creation_date                        DATE,
      x_last_update_date                     DATE,
      x_last_updated_by                      NUMBER,
      x_last_update_login                    NUMBER
   );

   PROCEDURE update_row (
      x_rowid                IN OUT NOCOPY   VARCHAR2,
      x_process_id                           NUMBER,
      x_process_file_id      IN OUT NOCOPY   NUMBER,
      x_seq_no                               NUMBER,
      x_process_file_name                    VARCHAR2,
      x_direction                            VARCHAR2,
      x_trans_source                         VARCHAR2,
      x_file_directory                       VARCHAR2,
      x_source_destination                   VARCHAR2,
      x_last_run_date                        DATE,
      x_last_request_id                      NUMBER,
      x_last_run_status                      VARCHAR2,
      x_enabled_flag                         VARCHAR2,
      x_org_id                               NUMBER,
      x_created_by                           NUMBER,
      x_creation_date                        DATE,
      x_last_update_date                     DATE,
      x_last_updated_by                      NUMBER,
      x_last_update_login                    NUMBER
   );

   PROCEDURE delete_row (x_rowid VARCHAR2);
END xx_emf_process_files_pkg;
/


GRANT EXECUTE ON APPS.XX_EMF_PROCESS_FILES_PKG TO INTG_XX_NONHR_RO;
