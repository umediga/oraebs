DROP PACKAGE BODY APPS.XX_EMF_PROCESS_FILES_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_EMF_PROCESS_FILES_PKG" AS
----------------------------------------------------------------------
/*
Created By   : IBM Development
Creation Date: 07-MAR-2012
Flle Name    : XXemfPRFLS.pkb
Description  : This Package body is used for insert,update,lock and delete procedures for the table XX_emf_PROCESS_FILES

Change History:
Date        Name               Remarks
----------- ----               ---------------------------------------
07-MAR-2012 IBM Development   Initial development.
*/
----------------------------------------------------------------------
/* This procedure is used for inserting data into table XX_emf_PROCESS_FILES and this procedure is called through form */
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
   )
   IS
      CURSOR c_procesfile
      IS
         SELECT ROWID
           FROM xx_emf_process_files
          WHERE process_file_id = x_process_file_id;
   BEGIN
      SELECT xx_emf_process_files_s.NEXTVAL
        INTO x_process_file_id
        FROM DUAL;

      INSERT INTO xx_emf_process_files
                  (process_id, process_file_id, seq_no,
                   process_file_name, direction, trans_source,
                   file_directory, source_destination, last_run_date,
                   last_request_id, last_run_status, enabled_flag,
                   org_id, created_by, creation_date,
                   last_update_date, last_updated_by, last_update_login
                  )
           VALUES (x_process_id, x_process_file_id, x_seq_no,
                   x_process_file_name, x_direction, x_trans_source,
                   x_file_directory, x_source_destination, x_last_run_date,
                   x_last_request_id, x_last_run_status, x_enabled_flag,
                   x_org_id, x_created_by, x_creation_date,
                   x_last_update_date, x_last_updated_by, x_last_update_login
                  );

      OPEN c_procesfile;
      FETCH c_procesfile INTO x_rowid;

      IF (c_procesfile%NOTFOUND)
      THEN
         CLOSE c_procesfile;
         RAISE NO_DATA_FOUND;
      END IF;

      CLOSE c_procesfile;
   END insert_row;

   /* This procedure is used for locking data of table XX_emf_PROCESS_FILES and this procedure is called through form */
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
   )
   IS
      CURSOR c_procesfile
      IS
         SELECT        *
         FROM xx_emf_process_files
         WHERE ROWID = x_rowid
         FOR UPDATE OF process_file_id NOWAIT;

      recinfo   c_procesfile%ROWTYPE;
   BEGIN
      OPEN c_procesfile;
      FETCH c_procesfile INTO recinfo;

      IF (c_procesfile%NOTFOUND)
      THEN
         CLOSE c_procesfile;
         fnd_message.set_name ('fnd', 'form_record_deleted');
         app_exception.raise_exception;
      END IF;

      CLOSE c_procesfile;

      IF (    (recinfo.process_id = x_process_id)
          AND (   (recinfo.process_file_id = x_process_file_id)
               OR (    (recinfo.process_file_id IS NULL)
                   AND (x_process_file_id IS NULL)
                  )
              )
          AND (   (recinfo.seq_no = x_seq_no)
               OR ((recinfo.seq_no IS NULL) AND (x_seq_no IS NULL))
              )
          AND (   (recinfo.process_file_name = x_process_file_name)
               OR (    (recinfo.process_file_name IS NULL)
                   AND (x_process_file_name IS NULL)
                  )
              )
          AND (   (recinfo.direction = x_direction)
               OR ((recinfo.direction IS NULL) AND (x_direction IS NULL))
              )
          AND (   (recinfo.trans_source = x_trans_source)
               OR (    (recinfo.trans_source IS NULL)
                   AND (x_trans_source IS NULL)
                  )
              )
          AND (   (recinfo.file_directory = x_file_directory)
               OR (    (recinfo.file_directory IS NULL)
                   AND (x_file_directory IS NULL)
                  )
              )
          AND (   (recinfo.source_destination = x_source_destination)
               OR (    (recinfo.source_destination IS NULL)
                   AND (x_source_destination IS NULL)
                  )
              )
          AND (   (recinfo.last_run_date = x_last_run_date)
               OR (    (recinfo.last_run_date IS NULL)
                   AND (x_last_run_date IS NULL)
                  )
              )
          AND (   (recinfo.last_request_id = x_last_request_id)
               OR (    (recinfo.last_request_id IS NULL)
                   AND (x_last_request_id IS NULL)
                  )
              )
          AND (   (recinfo.last_run_status = x_last_run_status)
               OR (    (recinfo.last_run_status IS NULL)
                   AND (x_last_run_status IS NULL)
                  )
              )
          AND (   (recinfo.enabled_flag = x_enabled_flag)
               OR (    (recinfo.enabled_flag IS NULL)
                   AND (x_enabled_flag IS NULL)
                  )
              )
          AND (   (recinfo.org_id = x_org_id)
               OR ((recinfo.org_id IS NULL) AND (x_org_id IS NULL))
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

   /* This procedure is used for updating data into table XX_emf_PROCESS_FILES and this procedure is called through form */
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
   )
   IS
   BEGIN
      UPDATE xx_emf_process_files
         SET process_id = x_process_id,
             process_file_id = x_process_file_id,
             seq_no = x_seq_no,
             process_file_name = x_process_file_name,
             direction = x_direction,
             trans_source = x_trans_source,
             file_directory = x_file_directory,
             source_destination = x_source_destination,
             last_run_date = x_last_run_date,
             last_request_id = x_last_request_id,
             last_run_status = x_last_run_status,
             enabled_flag = x_enabled_flag,
             org_id = x_org_id,
             created_by = x_created_by,
             creation_date = x_creation_date,
             last_update_date = x_last_update_date,
             last_updated_by = x_last_updated_by,
             last_update_login = x_last_update_login
       WHERE ROWID = x_rowid;

      IF (SQL%NOTFOUND)
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   END update_row;

   /* This procedure is used for deleting data into table XX_emf_PROCESS_FILES and this procedure is called through form */
   PROCEDURE delete_row (x_rowid VARCHAR2)
   IS
   BEGIN
      DELETE FROM xx_emf_process_files
            WHERE ROWID = x_rowid;

      IF (SQL%NOTFOUND)
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   END delete_row;
END xx_emf_process_files_pkg;
/


GRANT EXECUTE ON APPS.XX_EMF_PROCESS_FILES_PKG TO INTG_XX_NONHR_RO;
