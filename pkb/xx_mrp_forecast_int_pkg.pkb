DROP PACKAGE BODY APPS.XX_MRP_FORECAST_INT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_MRP_FORECAST_INT_PKG" 
IS
   ----------------------------------------------------------------------
   /*
    Created By    : IBM Development
    Creation Date :
    File Name     : XXMRPFORECASTINT.pkb
    Description   : This script creates the specification of the package
                    xx_mrp_forecast_int_pkg
    Change History:
    Date        Name                  Remarks
    ----------- -------------         -----------------------------------
    19-JAN-2012 Renjith               Initial Version
    22-Feb-2012 Renjith               Changes to forecast date format
    17-Dec-2014 Pravin		            Perfomance tuning and Added Designator as parameter.
   */
    ----------------------------------------------------------------------
    -- This procedure will update the new records for processing
    PROCEDURE mark_records_for_processing (p_designator VARCHAR2)
    -- ( p_restart_flag   IN VARCHAR2)
    IS
       PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling mark_records_for_processing..');
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'mark_records_for_processing..'||xx_emf_pkg.G_REQUEST_ID||' - '||xx_emf_cn_pkg.CN_NULL||' - '||xx_emf_cn_pkg.CN_NEW);
            UPDATE XX_MRP_FORCAST_INT_STG
               SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                   error_code   = xx_emf_cn_pkg.CN_NULL,
                   process_code = xx_emf_cn_pkg.CN_NEW
             WHERE ERROR_CODE IS NULL
             AND NVL2(P_DESIGNATOR,FORECAST_DESIGNATOR,1) = NVL2(P_DESIGNATOR,P_DESIGNATOR,1);
         COMMIT;

    END mark_records_for_processing;
   -- --------------------------------------------------------------------- --
    -- Setting stage
    PROCEDURE set_stage ( p_stage VARCHAR2)
    IS
    BEGIN
       G_STAGE := p_stage;
    END set_stage;

   -- --------------------------------------------------------------------- --

   -- Cross Updating the stagin table
   PROCEDURE update_staging_records(p_error_code VARCHAR2) IS

           x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

           PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
           UPDATE  xx_mrp_forcast_int_stg
              SET  process_code = G_STAGE
                  ,error_code = p_error_code --DECODE ( error_code, NULL, p_error_code, error_code)
                  ,creation_date         = SYSDATE
                  ,created_by            = fnd_global.user_id
                  ,last_update_date      = SYSDATE
                  ,last_updated_by       = fnd_global.user_id
                  ,last_update_login     = x_last_update_login
            WHERE request_id	= xx_emf_pkg.G_REQUEST_ID
              AND process_code	= xx_emf_cn_pkg.CN_NEW
              AND NVL(process_status,3) <> 0;
         COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Updating STAGE status : ' ||SQLERRM);
   END update_staging_records;

   -- --------------------------------------------------------------------- --
  -- Postvalidation process if any
  FUNCTION post_validations RETURN NUMBER
  IS
     x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
     x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
  BEGIN
     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations');
     RETURN x_error_code;
  EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR THEN
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
          x_error_code := xx_emf_cn_pkg.cn_rec_err;
          RETURN x_error_code;
      WHEN OTHERS THEN
          x_error_code := xx_emf_cn_pkg.cn_rec_err;
          RETURN x_error_code;
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Completed Post-Validations');
  END post_validations;

  -- --------------------------------------------------------------------- --

   -- update_record_count
   PROCEDURE update_record_count
   IS
      CURSOR c_get_total_cnt IS
      SELECT COUNT (1) total_count
        FROM xx_mrp_forcast_int_stg
       WHERE request_id = xx_emf_pkg.G_REQUEST_ID;

      x_total_cnt NUMBER;

      CURSOR c_get_error_cnt IS
      SELECT SUM(error_count)
        FROM (
      SELECT COUNT (1) error_count
        FROM xx_mrp_forcast_int_stg
       WHERE request_id = xx_emf_pkg.G_REQUEST_ID
         AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

       x_error_cnt NUMBER;

      CURSOR c_get_warning_cnt IS
      SELECT COUNT (1) warn_count
        FROM xx_mrp_forcast_int_stg
       WHERE request_id = xx_emf_pkg.G_REQUEST_ID
         AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

       x_warn_cnt NUMBER;

      CURSOR c_get_success_cnt IS
      SELECT COUNT (1) success_count
        FROM xx_mrp_forcast_int_stg
       WHERE request_id = xx_emf_pkg.G_REQUEST_ID
         AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
         AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

      x_success_cnt NUMBER;

   BEGIN
      OPEN c_get_total_cnt;
      FETCH c_get_total_cnt INTO x_total_cnt;
      CLOSE c_get_total_cnt;

      OPEN c_get_error_cnt;
      FETCH c_get_error_cnt INTO x_error_cnt;
      CLOSE c_get_error_cnt;

      OPEN c_get_warning_cnt;
      FETCH c_get_warning_cnt INTO x_warn_cnt;
      CLOSE c_get_warning_cnt;

      OPEN c_get_success_cnt;
      FETCH c_get_success_cnt INTO x_success_cnt;
      CLOSE c_get_success_cnt;

      xx_emf_pkg.update_recs_cnt
        ( p_total_recs_cnt   => x_total_cnt,
          p_success_recs_cnt => x_success_cnt,
          p_warning_recs_cnt => x_warn_cnt,
          p_error_recs_cnt   => x_error_cnt
        );

   END update_record_count;

  -- --------------------------------------------------------------------- --
   PROCEDURE file_read_stg( p_file_name           IN     VARCHAR2
                           ,p_error_code          OUT    VARCHAR2
                           ,p_error_msg           OUT    VARCHAR2)
   IS
       x_file_type                 UTL_FILE.FILE_TYPE;
       x_line                      VARCHAR2(3000);
       x_pos                       NUMBER := 1;
       x_rec_cntr                  NUMBER := 0;
       x_cntr                      NUMBER := 0;
       x_filename                  VARCHAR2(100);
       x_delimeter                 VARCHAR2(10) := ',';
       x_data_path                 VARCHAR2(300);
       x_file_yn_flag              VARCHAR2(1) := 'N';
       x_exists                    BOOLEAN;
       x_file_length               NUMBER;
       x_size                      NUMBER;
       x_data_dir                  VARCHAR2(1000);

       TYPE x_xx_mrp_frcst_int_rec_type IS RECORD
       ( item_name              VARCHAR2(40)
        ,organization_code      VARCHAR2(3)
        ,forecast_designator    VARCHAR2(10)
        ,forecast_date          VARCHAR2(11)
        ,forecast_end_date      VARCHAR2(11)
        ,quantity               NUMBER
        ,confidence_percentage  NUMBER
        ,bucket_type            VARCHAR2(11));

       TYPE x_xx_mrp_frcst_int_tab_type IS TABLE OF x_xx_mrp_frcst_int_rec_type
       INDEX BY BINARY_INTEGER;

       x_data_rec               x_xx_mrp_frcst_int_tab_type;

       CURSOR  c_data_dir(p_dir VARCHAR2)
       IS
       SELECT  directory_path
         FROM  all_directories
        WHERE  directory_name= p_dir;
       -- ---------------------------------------------------------------------
       FUNCTION next_field ( p_line_buffer     IN       VARCHAR2
                            ,p_delimiter       IN       VARCHAR2
                            ,x_last_position   IN OUT   NUMBER)
       RETURN VARCHAR2
       IS
         x_new_position     NUMBER (6)     := NULL;
         x_out_field        VARCHAR2 (20000) := NULL;
         x_delimiter        VARCHAR2 (200)  := p_delimiter;
         x_delimiter_size   NUMBER (2)     := 1;
       BEGIN
         x_new_position := INSTR (p_line_buffer, x_delimiter, x_last_position);
         IF x_new_position = 0 THEN
            x_new_position := LENGTH (p_line_buffer) + 1;
         END IF;
         x_out_field := SUBSTR (p_line_buffer, x_last_position, x_new_position - x_last_position);
         x_out_field := LTRIM (RTRIM (x_out_field));

         IF x_new_position = LENGTH (p_line_buffer) + 1 THEN
            x_last_position := 0;
         ELSE
            x_last_position := x_new_position + x_delimiter_size;
         END IF;

         RETURN x_out_field;
       EXCEPTION
           WHEN OTHERS THEN
              x_last_position := -1;
              RETURN ' Error :'||SQLERRM;
       END next_field;
       -- ---------------------------------------------------------------------
   BEGIN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside xx_utl_read_insert_stg');
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside xx_utl_read_insert_stg');

       xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXFORECASTDIR'
                                                  ,p_param_name      => 'DATA_DIR'
                                                  ,x_param_value     =>  x_data_dir);
       OPEN  c_data_dir(x_data_dir);
       FETCH c_data_dir INTO x_data_path;
       IF c_data_dir%NOTFOUND THEN
         x_data_path := NULL;
       END IF;
       CLOSE c_data_dir;

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Path ->'||x_data_path);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'utl_read_insert_stg Data Dir->'||x_data_dir);

       IF x_data_path IS NOT NULL THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'File ->'||p_file_name);
          BEGIN
             x_file_type := UTL_FILE.FOPEN(x_data_dir, p_file_name, 'R');
          EXCEPTION
             WHEN UTL_FILE.invalid_path THEN
                p_error_code := xx_emf_cn_pkg.cn_prc_err;
                p_error_msg  := 'Invalid Path for File :' || p_file_name;
             WHEN UTL_FILE.invalid_filehandle THEN
                p_error_code := xx_emf_cn_pkg.cn_prc_err;
                p_error_msg  :=  'File handle is invalid for File :' || p_file_name;
             WHEN UTL_FILE.read_error THEN
                p_error_code := xx_emf_cn_pkg.cn_prc_err;
                p_error_msg  := 'Unable to read the File :' || p_file_name;
             WHEN UTL_FILE.invalid_operation THEN
                p_error_code := xx_emf_cn_pkg.cn_prc_err;
                p_error_msg  := 'File could not be opened :' || p_file_name;
                UTL_FILE.fgetattr ( x_data_dir
                                   ,p_file_name
                                   ,x_exists
                                   ,x_file_length
                                   ,x_size);

                IF x_exists THEN
                   p_error_msg := 'File '||p_file_name || 'exists ';
                ELSE
                   p_error_code := xx_emf_cn_pkg.cn_prc_err;
                   p_error_msg  := 'File '||p_file_name || ' File Does not exits ';
                   x_file_yn_flag := 'Y';
                END IF;
             WHEN UTL_FILE.file_open THEN
                  p_error_code := xx_emf_cn_pkg.cn_prc_err;
                  p_error_msg  := 'Unable to Open File :' || p_file_name;
             WHEN UTL_FILE.invalid_maxlinesize THEN
                  p_error_code := xx_emf_cn_pkg.cn_prc_err;
                  p_error_msg  := 'File ' || p_file_name;
             WHEN UTL_FILE.access_denied THEN
                  p_error_code := xx_emf_cn_pkg.cn_prc_err;
                  p_error_msg  := 'Access denied for File :' || p_file_name;
             WHEN OTHERS THEN
                  p_error_code := xx_emf_cn_pkg.cn_prc_err;
                  p_error_msg  := p_file_name || SQLERRM;
          END; -- End of File open exception

          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Code->'||p_error_code||'Exits Flag-> '||x_file_yn_flag);
          IF NVL(p_error_code,0) = 0 AND NVL(x_file_yn_flag,'N') <> 'Y' THEN
             LOOP
               BEGIN
                  BEGIN
                     UTL_FILE.GET_LINE(x_file_type, x_line);
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                     EXIT;
                  END;
                  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Line->'||x_line);

                  x_rec_cntr := x_rec_cntr + 1;
                  x_pos := 1;
                  x_cntr := x_cntr + 1;

                  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'x_cntr->'||x_cntr);

                  x_data_rec (x_cntr).item_name             := next_field (x_line, x_delimeter, x_pos);
                  x_data_rec (x_cntr).organization_code     := next_field (x_line, x_delimeter, x_pos);
                  x_data_rec (x_cntr).forecast_designator   := next_field (x_line, x_delimeter, x_pos);
                  x_data_rec (x_cntr).forecast_date         := next_field (x_line, x_delimeter, x_pos);
                  x_data_rec (x_cntr).forecast_end_date     := next_field (x_line, x_delimeter, x_pos);
                  x_data_rec (x_cntr).quantity              := next_field (x_line, x_delimeter, x_pos);
                  x_data_rec (x_cntr).confidence_percentage := next_field (x_line, x_delimeter, x_pos);
                  x_data_rec (x_cntr).bucket_type           := next_field (x_line, x_delimeter, x_pos);
               EXCEPTION
                   WHEN UTL_FILE.invalid_filehandle THEN
                        p_error_code := xx_emf_cn_pkg.cn_prc_err;
                        p_error_msg  :=  'File handle is invalid for File :' || p_file_name;
                   WHEN OTHERS THEN
                        p_error_msg := p_error_msg || SQLERRM;
                        p_error_code := xx_emf_cn_pkg.cn_rec_err;
                        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_HIGH,'Error While Reading Line ' || x_rec_cntr||SQLERRM);
               END;
             END LOOP;
          END IF; -- flag and error code
          UTL_FILE.fclose (x_file_type);

          FOR i IN 1 .. x_data_rec.COUNT
          LOOP

            INSERT INTO XX_MRP_FORCAST_INT_STG
             ( item_name
              ,organization_code
              ,forecast_designator
              ,forecast_date
              ,forecast_end_date
              ,quantity
              ,confidence_percentage
              ,bucket_type
              ,file_name
             )
            VALUES
             ( x_data_rec (i).item_name
              ,x_data_rec (i).organization_code
              ,x_data_rec (i).forecast_designator
              ,x_data_rec (i).forecast_date
              ,x_data_rec (i).forecast_end_date
              ,x_data_rec (i).quantity
              ,x_data_rec (i).confidence_percentage
              ,to_number(substr(x_data_rec (i).bucket_type,1,1))
              ,p_file_name
             );
          END LOOP;
       END IF; -- dir check
       COMMIT;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while reading File: ' ||SQLERRM);
          xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
          p_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
          p_error_msg := 'Error while reading File: ' ||SQLERRM;
   END file_read_stg;
  -- --------------------------------------------------------------------- --

  -- Staging Error Report
  PROCEDURE staging_error
  IS
      x_total_rec     NUMBER :=0;
      x_no_rec_error  NUMBER :=0;
      x_no_rec_sucess NUMBER :=0;

      CURSOR  c_err IS
      SELECT  *
        FROM  xx_mrp_forcast_int_stg
       WHERE  error_code     = 2
       ORDER BY record_id;

  BEGIN --Start of the logic to report the errors occured in the interface load

       SELECT COUNT(*)
         INTO x_total_rec
         FROM xx_mrp_forcast_int_stg;

       SELECT COUNT(*)
         INTO x_no_rec_error
         FROM xx_mrp_forcast_int_stg
        WHERE error_code=2;

       SELECT COUNT(*)
         INTO x_no_rec_sucess
         FROM xx_mrp_forcast_int_stg
        WHERE error_code <> 2;

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'START OF STAGING ERROR REPORT');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------');



       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The summary of the Staging Program run is: ');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of records loaded in the Table :'||x_total_rec);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of records errored in the Table :'||x_no_rec_error);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of records sucessfully loaded in the Interface Table :'||x_no_rec_sucess);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------');

       FND_FILE.PUT_LINE( FND_FILE.OUTPUT,RPAD('Item Name',18)||' '||RPAD('Organization Code',22)||' '||RPAD('Forecast Dsignator',28)
                    ||' '||RPAD('Forecast Date',18)||' '||RPAD('Forecast End Date',24)||' '||RPAD('Quantity',18)||' '||RPAD('Confidence Percentage',30)
                    ||' '||RPAD('Bucket Type',22)||' '||RPAD('Error Message',40));

      FND_FILE.PUT_LINE( FND_FILE.OUTPUT,RPAD('------------------',18)||' '||RPAD('--------------------',22)||' '||RPAD('------------------------',28)
         ||' '||RPAD('---------------------',18)||' '||RPAD('---------------------',24)||' '||RPAD('---------------------',18)
         ||' '||RPAD('-------------------------',30)||' '||RPAD('---------------------',22)||' '||RPAD('-----------------',40));

    FOR err_rec IN c_err
     LOOP
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT,RPAD(err_rec.item_name,18)||' '||RPAD(err_rec.organization_code,22)||' '||RPAD(err_rec.forecast_designator,28)
             ||' '||RPAD(err_rec.forecast_date,18)||' '||RPAD(NVL(err_rec.forecast_end_date,' '),24)||' '||RPAD(err_rec.quantity,18)
             ||' '||RPAD(err_rec.confidence_percentage,30)||' '||RPAD(err_rec.bucket_type,22)||' '||RPAD(err_rec.error_message,40));

    END LOOP;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'END OF STAGING ERROR REPORT');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------');

  EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR IS: '||SQLCODE ||' : '||SQLERRM);
  END  staging_error;

  -- --------------------------------------------------------------------- --

  PROCEDURE process_prc(x_errbuf          OUT VARCHAR2
                       ,X_RETCODE         OUT VARCHAR2
                       ,p_designator      IN VARCHAR2)
  IS

       CURSOR C_XX_MRP_FORCAST_INT_STG ( cp_process_status VARCHAR2) IS
       SELECT *
         FROM XX_MRP_FORCAST_INT_STG
        WHERE request_id   = xx_emf_pkg.G_REQUEST_ID
          AND process_code = cp_process_status
          AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
          ORDER BY record_id;
        x_error_code VARCHAR2(1)   := xx_emf_cn_pkg.CN_SUCCESS;
        x_cst_error                   EXCEPTION;
        x_item_id                     NUMBER;
        -- --------------------------------------------------------------------- --

        FUNCTION pre_validation RETURN NUMBER
        IS
           CURSOR  c_desig
           IS
           SELECT  DISTINCT forecast_designator,organization_code
             FROM  xx_mrp_forcast_int_stg
            WHERE  request_id   = xx_emf_pkg.G_REQUEST_ID
              AND  NVL(error_code,3) NOT IN (xx_emf_cn_pkg.CN_SUCCESS,xx_emf_cn_pkg.CN_REC_ERR);

           CURSOR  c_item
           IS
           SELECT  DISTINCT item_name,organization_code
             FROM  xx_mrp_forcast_int_stg
            WHERE  request_id   = xx_emf_pkg.G_REQUEST_ID
              AND  NVL(error_code,3) NOT IN (xx_emf_cn_pkg.CN_SUCCESS,xx_emf_cn_pkg.CN_REC_ERR);

           x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
           x_designator           mrp_forecast_designators.forecast_designator%TYPE;
           x_item_id              NUMBER;
           x_org_id               NUMBER;
        BEGIN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Pre-Validation started');
              -- --------------------------------------------------------------
              -- Checking quantity
              -- --------------------------------------------------------------
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'forecat date and quantity Check started');
              UPDATE  xx_mrp_forcast_int_stg
                 SET  process_status=2
                     ,error_code = xx_emf_cn_pkg.CN_REC_ERR
                     ,process_code = xx_emf_cn_pkg.CN_PREVAL
                     ,error_message = 'Invalid Quantity'
                     ,created_by = fnd_global.user_id
                     ,creation_date = sysdate
                     ,last_update_date = sysdate
                     ,last_updated_by = fnd_global.user_id
                     ,last_update_login = x_last_update_login
              WHERE  request_id   = xx_emf_pkg.G_REQUEST_ID
                AND  NVL(quantity,0) <=0
                AND  NVL(error_code,3) NOT IN (xx_emf_cn_pkg.CN_SUCCESS,xx_emf_cn_pkg.CN_REC_ERR);
              COMMIT;
              -- --------------------------------------------------------------
              -- Checking duplicate recors
              -- --------------------------------------------------------------
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'duplicate started');
              UPDATE  XX_MRP_FORCAST_INT_STG
                 SET  process_status = 2
                     ,error_code = xx_emf_cn_pkg.CN_REC_ERR
                     ,process_code = xx_emf_cn_pkg.CN_PREVAL
                     ,error_message = 'Duplicate records exists'
                     ,created_by = fnd_global.user_id
                     ,creation_date = sysdate
                     ,last_update_date = sysdate
                     ,last_updated_by = fnd_global.user_id
                     ,last_update_login = x_last_update_login
              WHERE  REQUEST_ID   = XX_EMF_PKG.G_REQUEST_ID
              AND
               --    record_id IN (SELECT record_id FROM xx_mrp_forcast_int_stg
              --                    WHERE
                                  ROWID  NOT IN ( SELECT    MAX(ROWID)
                                                            FROM    xx_mrp_forcast_int_stg
                                                           WHERE    NVL(error_code,3) NOT IN (xx_emf_cn_pkg.CN_SUCCESS,xx_emf_cn_pkg.CN_REC_ERR)
                                                        GROUP BY    item_name,organization_code,forecast_designator,forecast_date,forecast_end_date,bucket_type)
                                    AND NVL(error_code,3) NOT IN (xx_emf_cn_pkg.CN_SUCCESS,xx_emf_cn_pkg.CN_REC_ERR);
               COMMIT;
              -- --------------------------------------------------------------
              -- Checking forecat date,
              -- --------------------------------------------------------------
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'forecat date and quantity Check started');
              UPDATE  xx_mrp_forcast_int_stg
                 SET  process_status=2
                     ,error_code = xx_emf_cn_pkg.CN_REC_ERR
                     ,process_code = xx_emf_cn_pkg.CN_PREVAL
                     ,error_message = 'Invalid Item / Org / forecast dates / Bucket Type'
                     ,created_by = fnd_global.user_id
                     ,creation_date = sysdate
                     ,last_update_date = sysdate
                     ,last_updated_by = fnd_global.user_id
                     ,last_update_login = x_last_update_login
              WHERE  request_id   = xx_emf_pkg.G_REQUEST_ID
                AND  NVL(forecast_end_date,to_date(forecast_date,'dd-mon-yy')+1) < to_date(forecast_date,'dd-mon-yy')
                     OR NVL(bucket_type,0) NOT IN (1,2,3) OR item_name IS NULL OR organization_code IS NULL
                     AND NVL(error_code,3) NOT IN (xx_emf_cn_pkg.CN_SUCCESS,xx_emf_cn_pkg.CN_REC_ERR);
              COMMIT;
              -- --------------------------------------------------------------
              -- Designator Check
              -- --------------------------------------------------------------
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Designator Check started');
              FOR desig_rec IN c_desig LOOP
                  BEGIN
                     SELECT  mfd.forecast_designator
                       INTO  x_designator
                       FROM  mrp_forecast_designators mfd
                            ,mtl_parameters mtp
                      WHERE  mfd.forecast_designator=desig_rec.forecast_designator
                        AND  (NVL(mfd.disable_date,sysdate+1)>sysdate)
                        AND  mtp.organization_code = desig_rec.organization_code
                        AND  mtp.organization_id=mfd.organization_id;
                  EXCEPTION WHEN OTHERS THEN
                      UPDATE  xx_mrp_forcast_int_stg
                         SET  process_status=2
                             ,error_code = xx_emf_cn_pkg.CN_REC_ERR
                             ,process_code = xx_emf_cn_pkg.CN_PREVAL
                             ,error_message = 'Invalid Designator'
                             ,created_by = fnd_global.user_id
                             ,creation_date = sysdate
                             ,last_update_date = sysdate
                             ,last_updated_by = fnd_global.user_id
                             ,last_update_login = x_last_update_login
                       WHERE  request_id   = xx_emf_pkg.G_REQUEST_ID
                         AND  forecast_designator = desig_rec.forecast_designator
                         AND  organization_code   = desig_rec.organization_code
                         AND NVL(error_code,3) NOT IN (xx_emf_cn_pkg.CN_SUCCESS,xx_emf_cn_pkg.CN_REC_ERR);
                  END;
              END LOOP;
              COMMIT;
              -- --------------------------------------------------------------
              -- Item Org Check
              -- --------------------------------------------------------------
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Designator Check started');
              FOR item_rec IN c_item LOOP
                   x_org_id  := NULL;
                   x_item_id := NULL;
                   BEGIN
                      SELECT  msib.inventory_item_id
                             ,msib.organization_id
                        INTO  x_item_id
                             ,x_org_id
                        FROM  mtl_system_items_b msib
                             ,mtl_parameters     mtp
                       WHERE  msib.segment1=item_rec.item_name
                         AND  mtp.organization_code=item_rec.organization_code
                         AND  mtp.organization_id=msib.organization_id
                         AND  msib.enabled_flag='Y'
                         AND  NVL(msib.start_date_active,sysdate)<=sysdate
                         AND  NVL(msib.end_date_active,sysdate)>=sysdate;

                      UPDATE  xx_mrp_forcast_int_stg
                         SET  inv_item_id = x_item_id
                             ,organization_id = x_org_id
                             ,process_code          = xx_emf_cn_pkg.CN_POSTVAL
                             ,process_status        = xx_emf_cn_pkg.CN_SUCCESS
                             ,error_code            = xx_emf_cn_pkg.CN_SUCCESS
                             ,created_by = fnd_global.user_id
                             ,creation_date = sysdate
                             ,last_update_date = sysdate
                             ,last_updated_by = fnd_global.user_id
                             ,last_update_login = x_last_update_login
                       WHERE  request_id   = xx_emf_pkg.G_REQUEST_ID
                         AND  item_name = item_rec.item_name
                         AND  organization_code   = item_rec.organization_code
                         AND NVL(error_code,3) NOT IN (xx_emf_cn_pkg.CN_SUCCESS,xx_emf_cn_pkg.CN_REC_ERR);

                   EXCEPTION WHEN OTHERS THEN
                      UPDATE  xx_mrp_forcast_int_stg
                         SET  process_status=2
                             ,error_code = xx_emf_cn_pkg.CN_REC_ERR
                             ,process_code = xx_emf_cn_pkg.CN_PREVAL
                             ,error_message = 'Invalid Item OR Not in Inv Org'
                             ,created_by = fnd_global.user_id
                             ,creation_date = sysdate
                             ,last_update_date = sysdate
                             ,last_updated_by = fnd_global.user_id
                             ,last_update_login = x_last_update_login
                       WHERE  request_id   = xx_emf_pkg.G_REQUEST_ID
                         AND  item_name = item_rec.item_name
                         AND  organization_code   = item_rec.organization_code
                         AND  NVL(error_code,3) NOT IN (xx_emf_cn_pkg.CN_SUCCESS,xx_emf_cn_pkg.CN_REC_ERR);
                   END;
              END LOOP;
              COMMIT;
              -- --------------------------------------------------------------
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Pre-Validation end');
           RETURN x_error_code;
        EXCEPTION
          WHEN OTHERS THEN
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in pre_validation' ||SQLERRM);
              xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
              x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
              RETURN x_error_code;
        END pre_validation;
        -- --------------------------------------------------------------------- --
        -- Inserting to interface table
        FUNCTION xx_mrp_forecast_interface  RETURN NUMBER
        IS
            x_return_status       VARCHAR2(15) := xx_emf_cn_pkg.CN_SUCCESS;
            x_workday_control    NUMBER :=2;--constant for the workday control
        BEGIN
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,' request_id ->'||xx_emf_pkg.G_REQUEST_ID);
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,' process_code ->'||xx_emf_cn_pkg.CN_POSTVAL);

           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside Interface Insert');
           BEGIN
                INSERT INTO mrp_forecast_interface
                   ( inventory_item_id
                    ,forecast_designator
                    ,organization_id
                    ,forecast_date
                    ,forecast_end_date
                    ,last_update_date
                    ,last_updated_by
                    ,creation_date
                    ,created_by
                    ,quantity
                    ,process_status
                    ,confidence_percentage
                    ,workday_control
                    ,bucket_type
                    )
                SELECT  inv_item_id                 --inventory id
                       ,forecast_designator         --forecast designator
                       ,organization_id             --organizaton id
                       ,TO_DATE(forecast_date)      --forecast date
                       ,TO_DATE(forecast_end_date)  --forecast end date
                       ,SYSDATE                     --last update date defaulted to sysdate
                       ,FND_GLOBAL.USER_ID          --last updated by
                       ,SYSDATE                     --creation date
                       ,FND_GLOBAL.USER_ID          --created_by
                       ,quantity                    --quantity
                       ,2                           --process_status
                       ,confidence_percentage       --confidence percentage
                       ,x_workday_control           --workday_control defaulted to 2 (constant)
                       ,bucket_type
                  FROM  xx_mrp_forcast_int_stg
                 WHERE  request_id   = xx_emf_pkg.G_REQUEST_ID
                   AND  process_code = xx_emf_cn_pkg.CN_POSTVAL
                   AND  error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                   ORDER BY record_id;
              EXCEPTION
                  WHEN OTHERS THEN
                  x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
              END;
            COMMIT;
           RETURN x_return_status;
        EXCEPTION
          WHEN OTHERS THEN
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while inserting into Standard Interface Tables: ' ||SQLERRM);
              xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
              x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
              RETURN x_error_code;

        END xx_mrp_forecast_interface;
        -- --------------------------------------------------------------------- --
        -- mark_records_complete
        PROCEDURE mark_records_complete (p_process_code	VARCHAR2)
        IS
           x_last_update_date       DATE   := SYSDATE;
           x_last_updated_by        NUMBER := fnd_global.user_id;
           x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
           PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of mark records complete...');
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside mark_records_complete');

           UPDATE xx_mrp_forcast_int_stg	--Header
              SET process_code      = G_STAGE,
                  error_code        = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
                  Process_status    = 0,
                  last_updated_by   = x_last_updated_by,
                  last_update_date  = x_last_update_date,
                  last_update_login = x_last_update_login
            WHERE request_id   = xx_emf_pkg.G_REQUEST_ID
              AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
              AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);
           COMMIT;

         EXCEPTION
            WHEN OTHERS THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in Update of mark_records_complete '||SQLERRM);
         END mark_records_complete;

 -- --------------------------------------------------------------------- --

    BEGIN
       x_retcode := xx_emf_cn_pkg.CN_SUCCESS;
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Before Setting Environment');

       -- Emf Env initialization
       x_error_code := xx_emf_pkg.set_env;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Starting main process with the following parameters');
       --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_restart_flag '	|| p_restart_flag);

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Start Calling mark_records_for_processing..');
       --mark_records_for_processing(p_restart_flag => p_restart_flag);
       mark_records_for_processing(p_designator);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'End Calling mark_records_for_processing..');

       -- Set the stage to Pre Validations
       set_stage (xx_emf_cn_pkg.CN_PREVAL);

       -- Prevalidation
       x_error_code := pre_validation;
       IF x_error_code != xx_emf_cn_pkg.cn_success THEN
          RAISE x_cst_error;
       END IF;

       -- Cross updating staging table
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Start Calling update_staging_records..');
       update_staging_records (xx_emf_cn_pkg.CN_SUCCESS);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'End Calling update_staging_records..');

       xx_emf_pkg.propagate_error ( x_error_code);

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
       mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);

       xx_emf_pkg.propagate_error ( x_error_code);

       -- to interface table
       x_error_code := xx_mrp_forecast_interface;
       IF x_error_code != xx_emf_cn_pkg.cn_success THEN
          RAISE x_cst_error;
       END IF;

       -- Set the stage to Process Data
       set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);

       mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After Process Data mark_records_complete x_error_code'||x_error_code);

       -- Emf error propagate
       --xx_emf_pkg.propagate_error ( x_error_code);

       -- update record count
       --update_record_count;

       -- emf report
       --xx_emf_pkg.create_report;
       staging_error;
    EXCEPTION
        WHEN x_cst_error THEN

            x_retcode := x_error_code;
            x_errbuf  := SQLERRM;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,' Error ='
                                  || ' x_error_code = '
                                  || x_error_code
                                 );

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'SQLERRM = ' || SQLERRM
                                 );
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR IS: '||SQLCODE ||' : '||SQLERRM);
        WHEN OTHERS THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,' Main Exception :'
                                     || ' x_error_code = '
                                     || x_error_code
                                    );

               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                     'SQLERRM = ' || SQLERRM
                                    );

               x_retcode := x_error_code;
               x_errbuf  := SQLERRM;

               xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                                 p_category                 => xx_emf_cn_pkg.cn_tech_error,
                                 p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                                 p_record_identifier_1      => SQLCODE,
                                 p_record_identifier_2      => SQLERRM
                                );
FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR IS: '||SQLCODE ||' : '||SQLERRM);
               xx_emf_pkg.create_report;
    END process_prc;
-- --------------------------------------------------------------------- --

  PROCEDURE main_prc ( x_errbuf          OUT VARCHAR2
                      ,X_RETCODE         OUT VARCHAR2
                      --,p_load_method     IN  VARCHAR2
                      --,P_FILE_NAME       IN  VARCHAR2
                      ,p_designator      IN  VARCHAR2
                     )
  IS
     x_error_code     VARCHAR2(1);
     x_error_buf      VARCHAR2(3000);
     x_ret_status     VARCHAR(1);
     x_error_message  VARCHAR2(3000);
  BEGIN
     /* IF NVL(p_load_method,'X') = 'L' THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside load ->'||P_FILE_NAME);
         file_read_stg( p_file_name    => p_file_name
                       ,p_error_code   => x_ret_status
                       ,p_error_msg    => x_error_message);
      END IF;*/
      process_prc( x_errbuf   => x_error_buf
                  ,X_RETCODE  => X_ERROR_CODE
                  ,p_designator => p_designator);
  END main_prc;

-- --------------------------------------------------------------------- --
    -- Interface Error Report
    PROCEDURE interface_error
    IS
      x_total_rec     NUMBER :=0;
      x_no_rec_error  NUMBER :=0;
      x_no_rec_sucess NUMBER :=0;

      CURSOR  c_forecast_iface_err IS
      SELECT  mfd.inventory_item_id   inventory_item_id
             ,msib.segment1           item_name
             ,mfd.forecast_designator forecast_designator
             ,mfd.organization_id     organization_id
             ,mtp.organization_code   organization_code
             ,mfd.forecast_date       forecast_date
             ,mfd.process_status      process_status
             ,mfd.error_message       error_message
        FROM  mrp_forecast_interface mfd
             ,mtl_system_items_b     msib
             ,mtl_parameters         mtp
       WHERE  process_status     =4
         AND  msib.inventory_item_id      =mfd.inventory_item_id
         AND  msib.organization_id=mfd.organization_id
         AND  mtp.organization_id=mfd.organization_id;

  BEGIN --Start of the logic to report the errors occured in the interface load

       SELECT COUNT(*)
         INTO x_total_rec
         FROM mrp_forecast_interface;

       SELECT COUNT(*)
         INTO x_no_rec_error
         FROM mrp_forecast_interface
        WHERE process_status=4;

       SELECT COUNT(*)
         INTO x_no_rec_sucess
         FROM mrp_forecast_interface
        WHERE process_status=5;

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'START OF INTERFACE ERROR REPORT');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------');



       FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'The summary of the Interface Program run is: ');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of records loaded in the Interface Table :'||x_total_rec);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of records errored in the Interface Table :'||x_no_rec_error);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of records successfully loaded in the Interface Table :'
                                                                            ||x_no_rec_sucess);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------');

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The summary of the Interface Proogram run is: ');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of records loaded in the Interface Table :'||x_total_rec);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of records errored in the Interface Table :'||x_no_rec_error);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of records successfully loaded in the Interface Table :'
                                                                             ||x_no_rec_sucess);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------');

    FOR rec_mrp_forecast_iface_err IN c_forecast_iface_err
     LOOP
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Inventory Item Id   :'||rec_mrp_forecast_iface_err.inventory_item_id);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Item Name           :'||rec_mrp_forecast_iface_err.item_name);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Forecast Designator :'||rec_mrp_forecast_iface_err.forecast_designator);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Organization Id     :'||rec_mrp_forecast_iface_err.organization_id);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Organization Code   :'||rec_mrp_forecast_iface_err.organization_code);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Forecast Date       :'||rec_mrp_forecast_iface_err.forecast_date);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error Message       :'||rec_mrp_forecast_iface_err.error_message);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------');
    END LOOP;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'END OF INTERFACE ERROR REPORT');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------');

  EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR IS: '||SQLCODE ||' : '||SQLERRM);
  END  interface_error;

-- --------------------------------------------------------------------- --
  -- Interface Error Report
  PROCEDURE error_report ( x_errbuf  OUT VARCHAR2
                          ,x_retcode OUT VARCHAR2
                          ,p_type    IN  VARCHAR2)

  IS
  BEGIN
    IF NVL(p_type,'X') = 'S' THEN
      staging_error;
    ELSE
      interface_error;
    END IF;
  EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR IS: '||SQLCODE ||' : '||SQLERRM);
         x_retcode := 2;
  END error_report;
-- --------------------------------------------------------------------- --
    -- Forecast Purge
    PROCEDURE forecast_purge ( x_errbuf       OUT  VARCHAR2
                              ,x_retcode      OUT  VARCHAR2
                              ,p_user_id    IN   NUMBER
                              ,p_designator IN   VARCHAR2
                              ,p_org_id     IN   NUMBER
                              ,p_item_id    IN   NUMBER)
    IS
      CURSOR c_forcast
      IS
      SELECT  mrp.forecast_designator
             ,mrp.inventory_item_id
             ,mrp.organization_id
             ,itm.segment1
             ,usr.user_name
             ,prm.organization_code
        FROM  mrp_forecast_dates mrp
             ,fnd_user  usr
             ,mtl_system_items_b itm
             ,mtl_parameters prm
       WHERE  mrp.inventory_item_id = itm.inventory_item_id
         AND  mrp.organization_id   = itm.organization_id
         AND  mrp.organization_id   = prm.organization_id
         AND  mrp.created_by        = usr.user_id
         AND  mrp.inventory_item_id   = NVL(p_item_id,mrp.inventory_item_id)
         AND  mrp.organization_id     = NVL(p_org_id,mrp.organization_id)
         AND  mrp.forecast_designator = NVL(p_designator,mrp.forecast_designator)
         AND  mrp.created_by          = NVL(p_user_id,mrp.created_by);

      x_forecast_rec   mrp_forecast_interface_pk.t_forecast_designator;
      x_status         BOOLEAN;
      x_count          NUMBER := 1;
    BEGIN
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Frecast Purge Report');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Parameters');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'p_user_id ->   '||p_user_id);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'p_designator ->'||p_designator);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'p_item_id ->   '||p_item_id);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'p_org_id ->    '||p_org_id);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Records Purged');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------');
       FOR rec_forecast IN c_forcast
       LOOP
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Designator ->   '||rec_forecast.forecast_designator);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Item       ->   '||rec_forecast.segment1);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Designator ->   '||rec_forecast.organization_code);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'User       ->   '||rec_forecast.user_name);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');

          x_forecast_rec(x_count).forecast_designator := rec_forecast.forecast_designator;
          x_forecast_rec(x_count).inventory_item_id   := rec_forecast.inventory_item_id;
          x_forecast_rec(x_count).organization_id     := rec_forecast.organization_id;
          x_count := x_count + 1;
       End Loop;
       Fnd_File.Put_Line(Fnd_File.Output,'-------------------------------------------');
       Fnd_File.Put_Line(Fnd_File.Output,'Total record deleted       ->   '||X_Count);
       X_Status := Mrp_Forecast_Interface_Pk.Mrp_Forecast_Interface(X_Forecast_Rec);
       If X_Status Then
         Fnd_File.Put_Line(Fnd_File.Output,'Delete record successful       ');
       Else
         Fnd_File.Put_Line(Fnd_File.Output,'Delete record error            ');
         x_retcode := 1;
       end if;

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------');
    EXCEPTION
       WHEN OTHERS THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR IS: '||SQLCODE ||' : '||SQLERRM);
           x_retcode := 2;
    END  forecast_purge;

-- --------------------------------------------------------------------- --
END xx_mrp_forecast_int_pkg;
/
