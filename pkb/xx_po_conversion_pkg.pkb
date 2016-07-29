DROP PACKAGE BODY APPS.XX_PO_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xx_po_conversion_pkg AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 23-FEB-2012
 File Name     : XXPOOPENPOCNV.pkb
 Description   : This script creates the body of the package
                 xx_po_conversion_pkg
 Change History:
 Date         Name                    Remarks
 -----------  -------------           -----------------------------------
 23-FEB-2012  IBM Development Team      Initial Draft.
 15-JUL-2013  ABHARGAVA					WAVE1 Changes
 25-MAR-2015  Sharath Babu/Pravin           Modified as per Wave2 for document_num
  */
----------------------------------------------------------------------


-- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
-- START RESTRICTIONS
--------------------------------------------------------------------------------
------------------< set_cnv_env >-----------------------------------------------
 /**
 * PROCEDURE set_cnv_env
 *
 * DESCRIPTION
 *     PROCEDURE to set conversion env.
 *
 * ARGUMENTS
 *   IN:
 *      p_batch_id          Batch id
 *      p_required_flag     Required flag
 *      p_batch_flag        Batch flag
 *   IN/OUT:
 *   OUT:
 */
--------------------------------------------------------------------------------
G_DIST_LINE_NUM NUMBER :=0;
G_DIST_LEGACY_PO_NUMBER VARCHAR2(1000) :=NULL;
G_LINE_LEGACY_PO_NUMBER VARCHAR2(1000);

PROCEDURE set_cnv_env (p_batch_id      VARCHAR2
                      ,p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES
                      ,p_batch_flag    VARCHAR2
                      ) IS
    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
BEGIN
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside set_cnv_env...');
    IF p_batch_flag = 'HDR' THEN
         G_BATCH_ID      := p_batch_id;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_BATCH_ID: '||G_BATCH_ID );
    ELSIF p_batch_flag = 'LINE' THEN
          G_LINE_BATCH_ID   := p_batch_id;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_LINE_BATCH_ID: '||G_LINE_BATCH_ID );
    ELSIF p_batch_flag = 'DIST' THEN --added
          G_DIST_BATCH_ID   := p_batch_id;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_DIST_BATCH_ID: '||G_DIST_BATCH_ID );
    END IF;

    -- Set the environment
    x_error_code := xx_emf_pkg.set_env;
    IF NVL (p_required_flag, xx_emf_cn_pkg.CN_YES) <> xx_emf_cn_pkg.CN_NO THEN
        xx_emf_pkg.propagate_error(x_error_code);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE xx_emf_pkg.G_E_ENV_NOT_SET;
END set_cnv_env;
--------------------------------------------------------------------------------
------------<Update Batch Id in Line And Distribution STG Table>----------------
 /**
 * TYPE      : Procedure
 * NAME      : update_cnv_batch
 * AUTHOR    : IBM Development Team
 * PURPOSE   : PROCEDURE to update batch id.
 *
 * ARGUMENTS :
 *   INPUT PARAMETERS:
 *      p_batch_id          Batch id
 *   IN/OUT  :
 *   OUT     :
 *
 */
--------------------------------------------------------------------------------
PROCEDURE update_cnv_batch (p_batch_id      VARCHAR2
                            ) IS
    x_batch_id    VARCHAR2(200);
BEGIN
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Batch update for Lines and Distributions staging tables.....Batch ID: '||p_batch_id);

    SELECT DISTINCT batch_id
      INTO x_batch_id
      FROM xx_po_headers_stg
     WHERE batch_id = p_batch_id
       AND UPPER(process_code) = UPPER(xx_emf_cn_pkg.CN_NEW)
       AND ERROR_CODE IS NULL;

    IF x_batch_id IS NOT NULL
        THEN
        UPDATE xx_po_lines_stg
           SET batch_id = x_batch_id
         WHERE batch_id IS NULL
           AND UPPER(process_code) = UPPER(xx_emf_cn_pkg.CN_NEW)
           AND ERROR_CODE IS NULL
           AND legacy_po_number IN
            (SELECT legacy_po_number
               FROM xx_po_headers_stg
              WHERE batch_id = p_batch_id
                AND UPPER (process_code) = UPPER(xx_emf_cn_pkg.CN_NEW)
                AND ERROR_CODE IS NULL);

        UPDATE xx_po_distributions_stg
           SET batch_id = x_batch_id
         WHERE batch_id IS NULL
           AND UPPER(process_code_c) = UPPER(xx_emf_cn_pkg.CN_NEW)
           AND ERROR_CODE IS NULL
           AND attribute2 IN
            (SELECT legacy_po_number
               FROM xx_po_headers_stg
              WHERE batch_id = p_batch_id
                AND UPPER (process_code) = UPPER(xx_emf_cn_pkg.CN_NEW)
                AND ERROR_CODE IS NULL);
    END IF;
    COMMIT;
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'End of Batch update for Lines and Distributions staging tables...Batch ID: '||p_batch_id);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'No Data Found while updating Batch for Lines and Distributions staging tables...Batch ID: '||p_batch_id);
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Too Many Rows found while updating Batch for Lines and Distributions staging tables...Batch ID: '||p_batch_id);
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Error while updating Batch for Lines and Distributions staging tables...Batch ID: '||p_batch_id);
END update_cnv_batch;

--------------------------------------------------------------------------------
------------------< mark_records_for_processing >-------------------------------
 /**
 * PROCEDURE mark_records_for_processing
 *
 * DESCRIPTION
 *     PROCEDURE to mark records for processing.
 *
 * ARGUMENTS
 *   IN:
 *      p_restart_flag            Restart flag
 *      p_override_flag           Override flag
 *   IN/OUT:
 *   OUT:
 */
--------------------------------------------------------------------------------

PROCEDURE mark_records_for_processing (p_restart_flag  IN VARCHAR2
                                      ,p_override_flag IN VARCHAR2
                                      ) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    -- If the override is set records should not be purged from the pre-interface tables
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside of mark records for processing...');

    IF p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS THEN

      IF p_override_flag = xx_emf_cn_pkg.CN_NO THEN

            -- purge from pre-interface tables and oracle standard tables
            DELETE FROM xx_po_headers_pre_int
                  WHERE batch_id = G_BATCH_ID;

            DELETE FROM xx_po_lines_pre_int
                  WHERE batch_id = G_LINE_BATCH_ID;

            DELETE FROM xx_po_distributions_pre_int --added
                  WHERE batch_id = G_DIST_BATCH_ID;

            UPDATE xx_po_headers_stg -- PO Header Staging
               SET request_id = xx_emf_pkg.G_REQUEST_ID,
                   ERROR_CODE = xx_emf_cn_pkg.CN_NULL,
                   process_code = xx_emf_cn_pkg.CN_NEW
             WHERE batch_id = G_BATCH_ID;

            UPDATE xx_po_lines_stg -- PO Lines Staging
               SET request_id = xx_emf_pkg.G_REQUEST_ID,
                   ERROR_CODE = xx_emf_cn_pkg.CN_NULL,
                   process_code = xx_emf_cn_pkg.CN_NEW
             WHERE batch_id = G_LINE_BATCH_ID;

             UPDATE xx_po_distributions_stg -- PO Distributions Staging --added
               SET request_id = xx_emf_pkg.G_REQUEST_ID,
                   ERROR_CODE = xx_emf_cn_pkg.CN_NULL,
                   process_code_c = xx_emf_cn_pkg.CN_NEW
             WHERE batch_id = G_DIST_BATCH_ID;
  ELSE
            UPDATE xx_po_headers_pre_int
               SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                   ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
                   request_id = xx_emf_pkg.G_REQUEST_ID
             WHERE batch_id = G_BATCH_ID;

            UPDATE xx_po_lines_pre_int
               SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                   ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
                   request_id = xx_emf_pkg.G_REQUEST_ID
             WHERE batch_id = G_LINE_BATCH_ID;

            UPDATE xx_po_distributions_pre_int --added
               SET process_code_c = xx_emf_cn_pkg.CN_PREVAL,
                   ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
                   request_id = xx_emf_pkg.G_REQUEST_ID
             WHERE batch_id = G_DIST_BATCH_ID;
  END IF;

        DELETE FROM PO_HEADERS_INTERFACE -- PO Headers Interface Table
              WHERE attribute11 = G_BATCH_ID;

        DELETE FROM PO_LINES_INTERFACE -- PO LInes Interface Table
              WHERE line_attribute11 = G_LINE_BATCH_ID;

        DELETE FROM PO_DISTRIBUTIONS_INTERFACE -- PO Distributions Interface Table --added
              WHERE attribute11 = G_DIST_BATCH_ID;

    ELSIF p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS THEN

        IF p_override_flag = xx_emf_cn_pkg.CN_NO THEN

            -- Update PO HDR staging table
            UPDATE xx_po_headers_stg
               SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                   ERROR_CODE   = xx_emf_cn_pkg.CN_NULL,
                   process_code = xx_emf_cn_pkg.CN_NEW
             WHERE batch_id = G_BATCH_ID
               AND (process_code = xx_emf_cn_pkg.CN_NEW
                  OR ( process_code = xx_emf_cn_pkg.CN_PREVAL
                       AND NVL (ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) IN (
                       xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                      )
                );

            -- Update PO LINE staging table
            UPDATE xx_po_lines_stg
               SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                   ERROR_CODE   = xx_emf_cn_pkg.CN_NULL,
                   process_code = xx_emf_cn_pkg.CN_NEW
             WHERE batch_id = G_LINE_BATCH_ID
               AND (   process_code = xx_emf_cn_pkg.CN_NEW
                    OR (   process_code = xx_emf_cn_pkg.CN_PREVAL
                        AND NVL (ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) IN (
                        xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                        )
                );

            -- Update PO DISTRIBUTION staging table --added
            UPDATE xx_po_distributions_stg
               SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                   ERROR_CODE   = xx_emf_cn_pkg.CN_NULL,
                   process_code_c = xx_emf_cn_pkg.CN_NEW
             WHERE batch_id = G_DIST_BATCH_ID
               AND (   process_code_c = xx_emf_cn_pkg.CN_NEW
                    OR (   process_code_c = xx_emf_cn_pkg.CN_PREVAL
                        AND NVL (ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) IN (
                        xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                        )
                );
       ----

        END IF;

        -- Update pre-interface table
        -- Scenario 1 Pre-Validation Stage

        UPDATE xx_po_headers_stg
           SET request_id = xx_emf_pkg.G_REQUEST_ID,
                 ERROR_CODE = xx_emf_cn_pkg.CN_NULL,
               process_code = xx_emf_cn_pkg.CN_NEW
         WHERE batch_id = G_BATCH_ID
           AND EXISTS (
            SELECT 1
              FROM xx_po_headers_pre_int a
             WHERE batch_id = G_BATCH_ID
               AND process_code = xx_emf_cn_pkg.CN_PREVAL
               AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
               AND record_number = a.record_number);

        UPDATE xx_po_lines_stg
           SET request_id = xx_emf_pkg.G_REQUEST_ID,
               ERROR_CODE = xx_emf_cn_pkg.CN_NULL,
               process_code = xx_emf_cn_pkg.CN_NEW
         WHERE batch_id = G_LINE_BATCH_ID
           AND EXISTS (
            SELECT 1
              FROM xx_po_lines_pre_int a
             WHERE batch_id = G_LINE_BATCH_ID
               AND process_code = xx_emf_cn_pkg.CN_PREVAL
               AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
               AND record_number = a.record_number);

        UPDATE xx_po_distributions_stg --added
           SET request_id = xx_emf_pkg.G_REQUEST_ID,
               ERROR_CODE = xx_emf_cn_pkg.CN_NULL,
               process_code_c = xx_emf_cn_pkg.CN_NEW
         WHERE batch_id = G_DIST_BATCH_ID
           AND EXISTS (
            SELECT 1
              FROM xx_po_distributions_pre_int a
             WHERE batch_id = G_DIST_BATCH_ID
               AND process_code_c = xx_emf_cn_pkg.CN_PREVAL
               AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
               AND record_number = a.record_number);

        DELETE
          FROM xx_po_headers_pre_int
         WHERE batch_id = G_BATCH_ID
           AND process_code = xx_emf_cn_pkg.CN_PREVAL
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

        DELETE
          FROM xx_po_lines_pre_int
         WHERE batch_id = G_LINE_BATCH_ID
           AND process_code = xx_emf_cn_pkg.CN_PREVAL
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

        DELETE --added
          FROM xx_po_distributions_pre_int
         WHERE batch_id = G_DIST_BATCH_ID
           AND process_code_c = xx_emf_cn_pkg.CN_PREVAL
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

        -- Scenario 2 Data Validation Stage

        UPDATE xx_po_headers_pre_int
           SET request_id = xx_emf_pkg.G_REQUEST_ID,
               ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
               process_code = xx_emf_cn_pkg.CN_PREVAL
         WHERE batch_id = G_BATCH_ID
           AND process_code = xx_emf_cn_pkg.CN_VALID
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

        UPDATE xx_po_lines_pre_int
           SET request_id = xx_emf_pkg.G_REQUEST_ID,
               ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
               process_code = xx_emf_cn_pkg.CN_PREVAL
         WHERE batch_id = G_LINE_BATCH_ID
           AND process_code = xx_emf_cn_pkg.CN_VALID
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

        UPDATE xx_po_distributions_pre_int --added
           SET request_id = xx_emf_pkg.G_REQUEST_ID,
               ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
               process_code_c = xx_emf_cn_pkg.CN_PREVAL
         WHERE batch_id = G_DIST_BATCH_ID
           AND process_code_c = xx_emf_cn_pkg.CN_VALID
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

        -- Scenario 3 Data Derivation Stage

        UPDATE xx_po_headers_pre_int
           SET request_id = xx_emf_pkg.G_REQUEST_ID,
               ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
               process_code = xx_emf_cn_pkg.CN_DERIVE
         WHERE batch_id = G_BATCH_ID
           AND process_code = xx_emf_cn_pkg.CN_DERIVE
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

        UPDATE xx_po_lines_pre_int
           SET request_id = xx_emf_pkg.G_REQUEST_ID,
               ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
               process_code = xx_emf_cn_pkg.CN_DERIVE
         WHERE batch_id = G_LINE_BATCH_ID
           AND process_code = xx_emf_cn_pkg.CN_DERIVE
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

        UPDATE xx_po_distributions_pre_int --added
           SET request_id = xx_emf_pkg.G_REQUEST_ID,
               ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
               process_code_c = xx_emf_cn_pkg.CN_DERIVE
         WHERE batch_id = G_DIST_BATCH_ID
           AND process_code_c = xx_emf_cn_pkg.CN_DERIVE
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

        -- Scenario 4 Post Validation Stage

        UPDATE xx_po_headers_pre_int
           SET request_id = xx_emf_pkg.G_REQUEST_ID,
               ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
               process_code = xx_emf_cn_pkg.CN_POSTVAL
         WHERE batch_id = G_BATCH_ID
           AND process_code = xx_emf_cn_pkg.CN_POSTVAL
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

        UPDATE xx_po_lines_pre_int
           SET request_id = xx_emf_pkg.G_REQUEST_ID,
               ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
               process_code = xx_emf_cn_pkg.CN_POSTVAL
         WHERE batch_id = G_LINE_BATCH_ID
           AND process_code = xx_emf_cn_pkg.CN_POSTVAL
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

        UPDATE xx_po_distributions_pre_int --added
           SET request_id = xx_emf_pkg.G_REQUEST_ID,
               ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
               process_code_c = xx_emf_cn_pkg.CN_POSTVAL
         WHERE batch_id = G_DIST_BATCH_ID
           AND process_code_c = xx_emf_cn_pkg.CN_POSTVAL
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);

        -- Scenario 5 Process Data Stage

        UPDATE xx_po_headers_pre_int
           SET request_id = xx_emf_pkg.G_REQUEST_ID,
               ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
               process_code = xx_emf_cn_pkg.CN_POSTVAL
         WHERE batch_id = G_BATCH_ID
           AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_ERR);

        UPDATE xx_po_lines_pre_int
           SET request_id = xx_emf_pkg.G_REQUEST_ID,
               ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
               process_code = xx_emf_cn_pkg.CN_POSTVAL
         WHERE batch_id = G_LINE_BATCH_ID
           AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_ERR);

        UPDATE xx_po_distributions_pre_int --added
           SET request_id = xx_emf_pkg.G_REQUEST_ID,
               ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
               process_code_c = xx_emf_cn_pkg.CN_POSTVAL
         WHERE batch_id = G_DIST_BATCH_ID
           AND process_code_c = xx_emf_cn_pkg.CN_PROCESS_DATA
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_ERR);
      END IF;
      COMMIT;
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'End of mark records for processing...');
END;

--------------------------------------------------------------------------------
-----------------< set_stage >--------------------------------------------------
 /**
 * PROCEDURE set_stage
 *
 * DESCRIPTION
 *     PROCEDURE to set stage.
 *
 * ARGUMENTS
 *   IN:
 *      p_stage
 *   IN/OUT:
 *   OUT:
 */
--------------------------------------------------------------------------------

PROCEDURE set_stage (p_stage VARCHAR2)
IS
BEGIN
    G_STAGE := p_stage;
END set_stage;

--------------------------------------------------------------------------------
-----------------< update_staging_records >-------------------------------------
 /**
 * PROCEDURE update_staging_records
 *
 * DESCRIPTION
 *     PROCEDURE to update staging records.
 *
 * ARGUMENTS
 *   IN:
 *      p_error_code      Error Code
 *      p_level           Level
 *   IN/OUT:
 *   OUT:
 */
--------------------------------------------------------------------------------

PROCEDURE update_staging_records( p_error_code VARCHAR2
                                , p_level VARCHAR2) IS

    x_last_update_date     DATE   := SYSDATE;
    x_last_updated_by      NUMBER := fnd_global.user_id;
    x_last_update_login    NUMBER := fnd_profile.VALUE (xx_emf_cn_pkg.CN_LOGIN_ID);

    PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside update_staging_records...'||p_level);

    IF p_level = 'HDR' THEN
    UPDATE xx_po_headers_stg        --Header
       SET process_code = G_STAGE,
           ERROR_CODE = DECODE ( ERROR_CODE, NULL, p_error_code, ERROR_CODE),
           last_update_date = x_last_update_date,
           last_updated_by   = x_last_updated_by,
           last_update_login = x_last_update_login -- In template please made change
     WHERE batch_id        = G_BATCH_ID
       AND request_id    = xx_emf_pkg.G_REQUEST_ID
       AND process_code    = xx_emf_cn_pkg.CN_NEW;
    END IF;

    IF p_level = 'LINE' THEN
    UPDATE xx_po_lines_stg        --Line
       SET process_code = G_STAGE,
           ERROR_CODE = DECODE ( ERROR_CODE, NULL, p_error_code, ERROR_CODE),
           last_update_date = x_last_update_date,
           last_updated_by   = x_last_updated_by,
           last_update_login = x_last_update_login -- In template please made change
     WHERE batch_id        = G_LINE_BATCH_ID
       AND request_id    = xx_emf_pkg.G_REQUEST_ID
       AND process_code    = xx_emf_cn_pkg.CN_NEW;
    END IF;

    IF p_level = 'DIST' THEN --added
    UPDATE xx_po_distributions_stg        --Distribution
       SET process_code_c = G_STAGE,
           ERROR_CODE = DECODE ( ERROR_CODE, NULL, p_error_code, ERROR_CODE),
           last_update_date = x_last_update_date,
           last_updated_by   = x_last_updated_by,
           last_update_login = x_last_update_login -- In template please made change
     WHERE batch_id        = G_DIST_BATCH_ID
       AND request_id    = xx_emf_pkg.G_REQUEST_ID
       AND process_code_c    = xx_emf_cn_pkg.CN_NEW;
    END IF;

    COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while updating staging records status: '||SQLERRM);

END update_staging_records;

--------------------------------------------------------------------------------
------------------< main >------------------------------------------------------
 /**
 * PROCEDURE main
 *
 * DESCRIPTION
 *     MAIN PROCEDURE to call other procedures and functions.
 *
 * ARGUMENTS
 *   IN:
 *      p_batch_id              Batch Id
 *      p_restart_flag          Restart Flag
 *      p_override_flag         Override Flag
 *      p_validate_and_load     Validate and Load
 *   IN/OUT:
 *   OUT:
 *      errbuf                  Error
 *      retcode                 Code
 */
--------------------------------------------------------------------------------
PROCEDURE main (
    errbuf              OUT VARCHAR2,
    retcode             OUT VARCHAR2,
    p_batch_id          IN  VARCHAR2,
    p_restart_flag      IN  VARCHAR2,
    p_override_flag     IN  VARCHAR2,
    p_acct_mapping_required IN  VARCHAR2,
    p_validate_and_load IN VARCHAR2
) IS

    x_error_code VARCHAR2(1) := xx_emf_cn_pkg.CN_SUCCESS;
    x_pre_std_hdr_table   G_XX_PO_CNV_PRE_HDR_TAB_TYPE;
    x_pre_std_line_table  G_XX_PO_CNV_PRE_LINE_TAB_TYPE;
    x_pre_std_dist_table  G_XX_PO_CNV_PRE_DIST_TAB_TYPE; --added

l_cnt NUMBER := 0;

    -- CURSOR FOR VARIOUS STAGES

    -- Header level


 CURSOR c_xx_po_headers_pre ( cp_process_status VARCHAR2) IS
  SELECT interface_header_id
         , batch_id
         , source_system_name -- New column Added for CR P2P-DCR-006
         , interface_source_code
         , process_code
         , action
         , group_code
         , org_id
         , document_type_code
         , document_subtype
         , document_num
         , po_header_id
         , release_num
         , po_release_id
         , release_date
         , currency_code
         , rate_type
         , rate_type_code
         , rate_date
         , rate
         , agent_name
         , agent_id
         , vendor_name
         , vendor_number
         , vendor_id
         , vendor_site_code
         , vendor_site_id
         , vendor_contact
         , vendor_contact_id
         , ship_to_location
         , ship_to_location_id
         , bill_to_location
         , bill_to_location_id
         , payment_terms
         , terms_id
         , freight_carrier
         , fob
         , freight_terms
         , approval_status
         , approved_date
         , revised_date
         , revision_num
         , note_to_vendor
         , note_to_receiver
         , confirming_order_flag
         , comments
         , acceptance_required_flag
         , acceptance_due_date
         , amount_agreed
         , amount_limit
         , min_release_amount
         , effective_date
         , expiration_date
         , print_count
         , printed_date
         , firm_flag
         , frozen_flag
         , closed_code
         , closed_date
         , reply_date
         , reply_method
         , rfq_close_date
         , quote_warning_delay
         , vendor_doc_num
         , approval_required_flag
         , vendor_list
         , vendor_list_header_id
         , from_header_id
         , from_type_lookup_code
         , ussgl_transaction_code
         , attribute_category
         , attribute1
         , attribute2
         , attribute3
         , attribute4
         , attribute5
         , attribute6
         , attribute7
         , attribute8
         , attribute9
         , attribute10
         , attribute11
         , attribute12
         , attribute13
         , attribute14
         , attribute15
         , creation_date
         , created_by
         , last_update_date
         , last_updated_by
         , last_update_login
         , request_id
         , program_application_id
         , program_id
         , program_update_date
         , reference_num
         , load_sourcing_rules_flag
         , vendor_num
         , from_rfq_num
         , wf_group_id
         , pcard_id
         , pay_on_code
         , global_agreement_flag
         , consume_req_demand_flag
         , shipping_control
         , encumbrance_required_flag
         , amount_to_encumber
         , change_summary
         , budget_account_segment1
         , budget_account_segment2
         , budget_account_segment3
         , budget_account_segment4
         , budget_account_segment5
         , budget_account_segment6
         , budget_account_segment7
         , budget_account_segment8
         , budget_account_segment9
         , budget_account_segment10
         , budget_account_segment11
         , budget_account_segment12
         , budget_account_segment13
         , budget_account_segment14
         , budget_account_segment15
         , budget_account_segment16
         , budget_account_segment17
         , budget_account_segment18
         , budget_account_segment19
         , budget_account_segment20
         , budget_account_segment21
         , budget_account_segment22
         , budget_account_segment23
         , budget_account_segment24
         , budget_account_segment25
         , budget_account_segment26
         , budget_account_segment27
         , budget_account_segment28
         , budget_account_segment29
         , budget_account_segment30
         , budget_account
         , budget_account_id
         , gl_encumbered_date
         , gl_encumbered_period_name
         , created_language
         , cpa_reference
         , draft_id
         , processing_id
         , processing_round_num
         , original_po_header_id
         , style_id
         , style_display_name
         , organization_code
         , organization_id
         , record_number
         , ERROR_CODE
       ,legacy_po_number
   FROM xx_po_headers_pre_int hdr
  WHERE batch_id     = G_BATCH_ID
    AND request_id   = xx_emf_pkg.G_REQUEST_ID
    AND process_code = cp_process_status
    AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
 ORDER BY record_number;

     -- Line level

    CURSOR c_xx_po_lines_pre ( cp_process_status VARCHAR2) IS
    SELECT interface_line_id
         , interface_header_id
         , action
         , group_code
         , organization_code
         , line_num
         , po_line_id
         , shipment_num
         , line_location_id
         , shipment_type
         , requisition_line_id
         , document_num
         , release_num
         , po_header_id
         , po_release_id
         , source_shipment_id
         , contract_num
         , line_type
         , line_type_id
         , item
         , item_id
         , item_revision
         , category
         , category_id
         , item_description
         , vendor_product_num
         , uom_code
         , unit_of_measure
         , quantity
         , committed_amount
         , min_order_quantity
         , max_order_quantity
         , unit_price
         , list_price_per_unit
         , market_price
         , allow_price_override_flag
         , not_to_exceed_price
         , negotiated_by_preparer_flag
         , un_number
         , un_number_id
         , hazard_class
         , hazard_class_id
         , note_to_vendor
         , transaction_reason_code
         , taxable_flag
         , tax_name
         , type_1099
         , capital_expense_flag
         , inspection_required_flag
         , receipt_required_flag
         , payment_terms
         , terms_id
         , price_type
         , min_release_amount
         , price_break_lookup_code
         , ussgl_transaction_code
         , closed_code
         , closed_reason
         , closed_date
         , closed_by
         , invoice_close_tolerance
         , receive_close_tolerance
         , firm_flag
         , days_early_receipt_allowed
         , days_late_receipt_allowed
         , enforce_ship_to_location_code
         , allow_substitute_receipts_flag
         , receiving_routing
         , receiving_routing_id
         , qty_rcv_tolerance
         , over_tolerance_error_flag
         , qty_rcv_exception_code
         , receipt_days_exception_code
         , ship_to_organization_code
         , ship_to_organization_id
         , ship_to_location
         , ship_to_location_id
         , need_by_date
         , promised_date
         , accrue_on_receipt_flag
         , lead_time
         , lead_time_unit
         , price_discount
         , freight_carrier
         , fob
         , freight_terms
         , effective_date
         , expiration_date
         , from_header_id
         , from_line_id
         , from_line_location_id
         , line_attribute_category_lines
         , line_attribute1
         , line_attribute2
         , line_attribute3
         , line_attribute4
         , line_attribute5
         , line_attribute6
         , line_attribute7
         , line_attribute8
         , line_attribute9
         , line_attribute10
         , line_attribute11
         , line_attribute12
         , line_attribute13
         , line_attribute14
         , line_attribute15
         , shipment_attribute_category
         , shipment_attribute1
         , shipment_attribute2
         , shipment_attribute3
         , shipment_attribute4
         , shipment_attribute5
         , shipment_attribute6
         , shipment_attribute7
         , shipment_attribute8
         , shipment_attribute9
         , shipment_attribute10
         , shipment_attribute11
         , shipment_attribute12
         , shipment_attribute13
         , shipment_attribute14
         , shipment_attribute15
         , last_update_date
         , last_updated_by
         , last_update_login
         , creation_date
         , created_by
         , request_id
         , program_application_id
         , program_id
         , program_update_date
         , organization_id
         , item_attribute_category
         , item_attribute1
         , item_attribute2
         , item_attribute3
         , item_attribute4
         , item_attribute5
         , item_attribute6
         , item_attribute7
         , item_attribute8
         , item_attribute9
         , item_attribute10
         , item_attribute11
         , item_attribute12
         , item_attribute13
         , item_attribute14
         , item_attribute15
         , unit_weight
         , weight_uom_code
         , volume_uom_code
         , unit_volume
         , template_id
         , template_name
         , line_reference_num
         , sourcing_rule_name
         , tax_status_indicator
         ,PROCESS_CODE
         , price_chg_accept_flag
         , price_break_flag
         , price_update_tolerance
         , tax_user_override_flag
         , tax_code_id
         , note_to_receiver
         , oke_contract_header_id
         , oke_contract_header_num
         , oke_contract_version_id
         , secondary_unit_of_measure
         , secondary_uom_code
         , secondary_quantity
         , preferred_grade
         , vmi_flag
         , auction_header_id
         , auction_line_number
         , auction_display_number
         , bid_number
         , bid_line_number
         , orig_from_req_flag
         , consigned_flag
         , supplier_ref_number
         , contract_id
         , job_id
         , amount
         , job_name
         , contractor_first_name
         , contractor_last_name
         , drop_ship_flag
         , base_unit_price
         , transaction_flow_header_id
         , job_business_group_id
         , job_business_group_name
         , catalog_name
         , supplier_part_auxid
         , ip_category_id
         , tracking_quantity_ind
         , secondary_default_ind
         , dual_uom_deviation_high
         , dual_uom_deviation_low
         , processing_id
         , line_loc_populated_flag
         , ip_category_name
         , retainage_rate
         , max_retainage_amount
         , progress_payment_rate
         , recoupment_rate
         , advance_amount
         , file_line_number
         , parent_interface_line_id
         , file_line_language
         , po_header_num
         , batch_id
         , record_number
         , ERROR_CODE
       ,legacy_po_number
     FROM xx_po_lines_pre_int line
    WHERE batch_id     = G_LINE_BATCH_ID
      AND request_id   = xx_emf_pkg.G_REQUEST_ID
      AND process_code = cp_process_status
      AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN,xx_emf_cn_pkg.CN_REC_ERR)
      AND line_type <> 'C' --28may2012
      AND line_num NOT LIKE 'C%'--Added on 19-07-2012
    ORDER BY record_number;

    -- Distribution level --added

    CURSOR c_xx_po_dist_pre ( cp_process_status VARCHAR2) IS
    SELECT interface_header_id
          ,interface_line_id
          ,interface_distribution_id
          ,po_header_id
          ,po_release_id
          ,po_line_id
          ,line_location_id
          ,po_distribution_id
          ,distribution_num
          ,source_distribution_id
          ,org_id
          ,quantity_ordered
          ,quantity_delivered
          ,quantity_billed
          ,quantity_cancelled
          ,rate_date
          ,rate
          ,deliver_to_location
          ,deliver_to_location_id
          ,deliver_to_person_full_name
          ,deliver_to_person_id
          ,destination_type
          ,destination_type_code
          ,destination_organization
          ,destination_organization_id
          ,destination_subinventory
          ,destination_context
          ,set_of_books
          ,set_of_books_id
          ,charge_account
          ,charge_account_id
          ,budget_account
          ,budget_account_id
          ,accural_account
          ,accrual_account_id
          ,variance_account
          ,variance_account_id
          ,amount_billed
          ,accrue_on_receipt_flag
          ,accrued_flag
          ,prevent_encumbrance_flag
          ,encumbered_flag
          ,encumbered_amount
          ,unencumbered_quantity
          ,unencumbered_amount
          ,failed_funds
          ,failed_funds_lookup_code
          ,gl_encumbered_date
          ,gl_encumbered_period_name
          ,gl_cancelled_date
          ,gl_closed_date
          ,req_header_reference_num
          ,req_line_reference_num
          ,req_distribution_id
          ,wip_entity
          ,wip_entity_id
          ,wip_operation_seq_num
          ,wip_resource_seq_num
          ,wip_repetitive_schedule
          ,wip_repetitive_schedule_id
          ,wip_line_code
          ,wip_line_id
          ,bom_resource_code
          ,bom_resource_id
          ,ussgl_transaction_code
          ,government_context
          ,project
          ,project_id
          ,task
          ,task_id
          ,end_item_unit_number
          ,expenditure
          ,expenditure_type
          ,project_accounting_context
          ,expenditure_organization
          ,expenditure_organization_id
          ,project_releated_flag
          ,expenditure_item_date
          ,attribute_category
          ,attribute1
          ,attribute2
          ,attribute3
          ,attribute4
          ,attribute5
          ,attribute6
          ,attribute7
          ,attribute8
          ,attribute9
          ,attribute10
          ,attribute11
          ,attribute12
          ,attribute13
          ,attribute14
          ,attribute15
          ,last_update_date
          ,last_updated_by
          ,last_update_login
          ,creation_date
          ,created_by
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date
          ,recoverable_tax
          ,nonrecoverable_tax
          ,recovery_rate
          ,tax_recovery_override_flag
          ,award_id
          ,charge_account_segment1
          ,charge_account_segment2
          ,charge_account_segment3
          ,charge_account_segment4
          ,charge_account_segment5
          ,charge_account_segment6
          ,charge_account_segment7
          ,charge_account_segment8
          ,charge_account_segment9
          ,charge_account_segment10
          ,charge_account_segment11
          ,charge_account_segment12
          ,charge_account_segment13
          ,charge_account_segment14
          ,charge_account_segment15
          ,charge_account_segment16
          ,charge_account_segment17
          ,charge_account_segment18
          ,charge_account_segment19
          ,charge_account_segment20
          ,charge_account_segment21
          ,charge_account_segment22
          ,charge_account_segment23
          ,charge_account_segment24
          ,charge_account_segment25
          ,charge_account_segment26
          ,charge_account_segment27
          ,charge_account_segment28
          ,charge_account_segment29
          ,charge_account_segment30
          ,oke_contract_line_id
          ,oke_contract_line_num
          ,oke_contract_deliverable_id
          ,oke_contract_deliverable_num
          ,award_number
          ,amount_ordered
          ,invoice_adjustment_flag
          ,dest_charge_account_id
          ,dest_variance_account_id
          ,interface_line_location_id
          ,processing_id
          ,process_code
          ,interface_distribution_ref
          ,batch_id
          ,record_number
          ,ERROR_CODE
          ,process_code_c
          ,organization_code
          ,document_num
          ,release_num
          ,line_num
          ,group_code
          ,shipment_num
      FROM xx_po_distributions_pre_int dist
     WHERE batch_id     = G_DIST_BATCH_ID
       AND request_id   = xx_emf_pkg.G_REQUEST_ID
       AND process_code_c = cp_process_status
       AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
       AND line_num NOT LIKE 'C%'--Added on 19-07-2012
    ORDER BY record_number;

-------------------------------------------------------------------------------
 /**
 * PROCEDURE update_hdr_record_status
 *
 * DESCRIPTION
 *     PROCEDURE to update header record status.
 *
 * ARGUMENTS
 *   IN:
 *      p_error_code                Error Code
 *   IN/OUT:
 *      p_conv_pre_std_hdr_rec      Header Record Type
 *   OUT:
 */
-------------------------------------------------------------------------------
    PROCEDURE update_hdr_record_status (
        p_conv_pre_std_hdr_rec  IN OUT  G_XX_PO_CNV_PRE_HDR_REC_TYPE,
        p_error_code            IN      VARCHAR2
           ) IS
  BEGIN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update record status...');

        IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
        THEN
            p_conv_pre_std_hdr_rec.ERROR_CODE := xx_emf_cn_pkg.CN_REC_ERR;
        ELSE
            p_conv_pre_std_hdr_rec.ERROR_CODE := xx_intg_common_pkg.find_max(p_error_code, NVL (p_conv_pre_std_hdr_rec.ERROR_CODE, xx_emf_cn_pkg.CN_SUCCESS));

        END IF;
        p_conv_pre_std_hdr_rec.process_code := G_STAGE;

    END update_hdr_record_status;

-------------------------------------------------------------------------------
 /**
 * PROCEDURE update_line_record_status
 *
 * DESCRIPTION
 *     PROCEDURE to update line record status.
 *
 * ARGUMENTS
 *   IN:
 *      p_error_code                Error Code
 *   IN/OUT:
 *      p_conv_pre_std_line_rec     Line Record Type
 *   OUT:
 */
-------------------------------------------------------------------------------
    PROCEDURE update_line_record_status (
        p_conv_pre_std_line_rec  IN OUT  G_XX_PO_CNV_PRE_LINE_REC_TYPE,
        p_error_code             IN      VARCHAR2
           ) IS

    BEGIN
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update line record status...');

           IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
           THEN
                  p_conv_pre_std_line_rec.ERROR_CODE := xx_emf_cn_pkg.CN_REC_ERR;
           ELSE
                  p_conv_pre_std_line_rec.ERROR_CODE := xx_intg_common_pkg.find_max(p_error_code, NVL (p_conv_pre_std_line_rec.ERROR_CODE, xx_emf_cn_pkg.CN_SUCCESS));

           END IF;
           p_conv_pre_std_line_rec.process_code := G_STAGE;

    END update_line_record_status;

-------------------------------------------------------------------------------
 /**
 * PROCEDURE update_dist_record_status
 *
 * DESCRIPTION
 *     PROCEDURE to update distribution record status.
 *
 * ARGUMENTS
 *   IN:
 *      p_error_code                Error Code
 *   IN/OUT:
 *      p_conv_pre_std_dist_rec     Distribution Record Type
 *   OUT:
 */
-------------------------------------------------------------------------------
    PROCEDURE update_dist_record_status (
        p_conv_pre_std_dist_rec  IN OUT  G_XX_PO_CNV_PRE_DIST_REC_TYPE,
        p_error_code             IN      VARCHAR2
           ) IS

    BEGIN
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update distribution record status...');

           IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
           THEN
                  p_conv_pre_std_dist_rec.ERROR_CODE := xx_emf_cn_pkg.CN_REC_ERR;
           ELSE
                  p_conv_pre_std_dist_rec.ERROR_CODE := xx_intg_common_pkg.find_max(p_error_code, NVL (p_conv_pre_std_dist_rec.ERROR_CODE, xx_emf_cn_pkg.CN_SUCCESS));

           END IF;
           p_conv_pre_std_dist_rec.process_code_c := G_STAGE;

    END update_dist_record_status;

-------------------------------------------------------------------------------
 /**
 * PROCEDURE mark_records_complete
 *
 * DESCRIPTION
 *     PROCEDURE to mark records as complete.
 *
 * ARGUMENTS
 *   IN:
 *      p_process_code                Process Code
 *      p_level                       Level
 *   IN/OUT:
 *   OUT:
 */
-------------------------------------------------------------------------------
    PROCEDURE mark_records_complete (
                                    p_process_code    VARCHAR2,
                                    p_level            VARCHAR2
                                    ) IS
        x_last_update_date       DATE   := SYSDATE;
        x_last_updated_by        NUMBER := fnd_global.user_id;
        x_last_update_login      NUMBER := fnd_profile.VALUE (xx_emf_cn_pkg.CN_LOGIN_ID);

        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of mark records complete...');

        IF p_level = 'HDR' THEN

           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside mark_records_complete :: p_level: '||p_level);

            UPDATE xx_po_headers_pre_int    --Header
               SET process_code      = G_STAGE,
                   ERROR_CODE        = NVL ( ERROR_CODE, xx_emf_cn_pkg.CN_SUCCESS),
                   last_updated_by   = x_last_updated_by,
                   last_update_date  = x_last_update_date,
                   last_update_login = x_last_update_login
             WHERE batch_id     = G_BATCH_ID
               AND request_id   = xx_emf_pkg.G_REQUEST_ID
               AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
               AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

        ELSIF p_level = 'LINE' THEN

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside mark_records_complete :: p_level: '||p_level);

            UPDATE xx_po_lines_pre_int    -- Line level
               SET process_code      = G_STAGE,
                   ERROR_CODE        = NVL ( ERROR_CODE, xx_emf_cn_pkg.CN_SUCCESS),
                   last_updated_by   = x_last_updated_by,
                   last_update_date  = x_last_update_date,
                   last_update_login = x_last_update_login
             WHERE batch_id     = G_LINE_BATCH_ID
               AND request_id   = xx_emf_pkg.G_REQUEST_ID
               AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
               AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

        ELSIF p_level = 'DIST' THEN --added

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside mark_records_complete :: p_level: '||p_level);

            UPDATE xx_po_distributions_pre_int    -- Distribution level
               SET process_code_c    = G_STAGE,
                   ERROR_CODE        = NVL ( ERROR_CODE, xx_emf_cn_pkg.CN_SUCCESS),
                   last_updated_by   = x_last_updated_by,
                   last_update_date  = x_last_update_date,
                   last_update_login = x_last_update_login
             WHERE batch_id     = G_DIST_BATCH_ID
               AND request_id   = xx_emf_pkg.G_REQUEST_ID
               AND process_code_c = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
               AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);
        END IF;
        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in Update of mark_records_complete '||SQLERRM);
    END mark_records_complete;

-------------------------------------------------------------------------------
 /**
 * PROCEDURE submit_standard_po_import
 *
 * DESCRIPTION
 *     PROCEDURE to submit Standard PO import Program.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *   OUT:
 */
-------------------------------------------------------------------------------
    PROCEDURE submit_standard_po_import IS
        x_request_id        NUMBER ;
        x_phase             VARCHAR2 (100);
        x_status            VARCHAR2 (100);
        x_dev_phase         VARCHAR2 (100);
        x_dev_status        VARCHAR2 (100);
        x_message           VARCHAR2 (240);
        x_wait_request      BOOLEAN;

      CURSOR c_org_id IS
        SELECT batch_id,org_id
          FROM po_headers_interface
         WHERE process_code ='PENDING'
      GROUP BY batch_id,org_id;

        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside submit_standard_po_import');

        FOR c_org_id_rec IN c_org_id
        LOOP

        fnd_request.set_org_id(c_org_id_rec.org_id);

        -- Submitting Import Standard Purchase Orders
        x_request_id := fnd_request.submit_request
                    (application      => 'PO',                     --Application Short Name
                     program          => 'POXPOPDOI',              --Concurrent Program Short Name
                     description        => 'Import Standard Purchase Orders',
                     start_time          => SYSDATE,
                     sub_request      => FALSE,
                     argument1        => NULL,                     --Default Buyer
                     argument2        => 'STANDARD',               --Document Type
                     argument3        => NULL,                     --Document SubType
                     argument4        => 'N',                      --Create or Update Items
                     argument5        => NULL ,                    --Create Sourcing Rules
                     argument6        => 'APPROVED',               --Approval Status
                     argument7        => NULL,                     --Release Generation Method
                     argument8        => c_org_id_rec.batch_id,    --Batch Id
                     argument9        => c_org_id_rec.org_id,      --Operating Unit
                     argument10       => NULL,                     --Global Agreement
                     argument11       => NULL,                     --Enable Sourcing Level
                     argument12       => NULL,                     --Sourcing Level
                     argument13       => NULL,                     --Inv Org Enable
                     argument14       => NULL                      --Inventory Organization
                    );
            COMMIT;

            IF x_request_id = 0 THEN
                     xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Error in submitting the Standard PO import');
        ELSE
                      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Standard PO import submitted successfully');

                      x_wait_request := fnd_concurrent.wait_for_request
                         (request_id          => x_request_id,
                          interval              => 10,
                          max_wait          => 2000,
                          phase             => x_phase,
                          status            => x_status,
                          dev_phase         => x_dev_phase,
                          dev_status        => x_dev_status,
                          MESSAGE           => x_message
                         );

              IF x_dev_phase = 'COMPLETE' AND x_dev_status = 'NORMAL'
                THEN
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Open Purchase Order Program Completed - Successfully');
                ELSE
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Open Purchase Order Program Completed - Failed');

              END IF;
      END IF;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND,SUBSTR(SQLERRM,1,255));
    END submit_standard_po_import;

-------------------------------------------------------------------------------
 /**
 * PROCEDURE submit_blanket_po_import
 *
 * DESCRIPTION
 *     PROCEDURE to Submitting Import Price Catalogs Program.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *   OUT:
 */
-------------------------------------------------------------------------------
    PROCEDURE submit_blanket_po_import IS
        x_request_id        NUMBER ;
        x_phase             VARCHAR2 (100);
        x_status            VARCHAR2 (100);
        x_dev_phase         VARCHAR2 (100);
        x_dev_status        VARCHAR2 (100);
        x_message           VARCHAR2 (240);
        x_wait_request      BOOLEAN;

      CURSOR c_org_id IS
        SELECT batch_id,org_id
          FROM po_headers_interface
         WHERE process_code ='PENDING'
      GROUP BY batch_id,org_id;

        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside submit_blanket_po_import');

        FOR c_org_id_rec IN c_org_id
        LOOP

        fnd_request.set_org_id(c_org_id_rec.org_id);

        -- Submitting Import Price Catalogs Program
        x_request_id := fnd_request.submit_request
                    (application      => 'PO',                     --Application Short Name
                     program          => 'POXPDOI',                --Concurrent Program Short Name
                     description        => 'Importing Price Catalogs (Blanket and Quotation) Program',
                     start_time          => SYSDATE,
                     sub_request      => FALSE,
                     argument1        => NULL,                     --Default Buyer
                     argument2        => 'BLANKET',                --Document Type
                     argument3        => NULL,                     --Document SubType
                     argument4        => 'N',                      --Create or Update Items
                     argument5        => NULL ,                    --Create Sourcing Rules
                     argument6        => 'APPROVED',               --Approval Status
                     argument7        => NULL,                     --Release Generation Method
                     argument8        => c_org_id_rec.batch_id,    --Batch Id
                     argument9        => c_org_id_rec.org_id,      --Operating Unit
                     argument10       => NULL,                     --Global Agreement
                     argument11       => NULL,                     --Enable Sourcing Level
                     argument12       => NULL,                     --Sourcing Level
                     argument13       => NULL,                     --Inv Org Enable
                     argument14       => NULL                      --Inventory Organization
                    );
            COMMIT;

            IF x_request_id = 0 THEN
                     xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Error in submitting the Price Catalogs import');
         ELSE
                      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Price Catalogs import submitted successfully');

                      x_wait_request := fnd_concurrent.wait_for_request
                         (request_id          => x_request_id,
                          interval              => 10,
                          max_wait          => 2000,
                          phase             => x_phase,
                          status            => x_status,
                          dev_phase         => x_dev_phase,
                          dev_status        => x_dev_status,
                          MESSAGE           => x_message
                         );

              IF x_dev_phase = 'COMPLETE' AND x_dev_status = 'NORMAL'
                THEN
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Price Catalogs Program Completed - Successfully');
          ELSE
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Price Catalogs Program Completed - Failed');

              END IF;
      END IF;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND,SUBSTR(SQLERRM,1,255));
    END submit_blanket_po_import;

  --Header Level Update
-------------------------------------------------------------------------------
 /**
 * PROCEDURE update_pre_hdr_int_records
 *
 * DESCRIPTION
 *     PROCEDURE to update header preinterface records.
 *
 * ARGUMENTS
 *   IN:
 *      p_cnv_pre_std_hdr_table     Header Table Type
 *   IN/OUT:
 *   OUT:
 */
-------------------------------------------------------------------------------
    PROCEDURE update_pre_hdr_int_records (p_cnv_pre_std_hdr_table IN G_XX_PO_CNV_PRE_HDR_TAB_TYPE)
    IS
        x_last_update_date     DATE   := SYSDATE;
        x_last_updated_by      NUMBER := fnd_global.user_id;
        x_last_update_login    NUMBER := fnd_profile.VALUE (xx_emf_cn_pkg.CN_LOGIN_ID);

        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        fnd_file.put_line(fnd_file.LOG,'Inside of update pre header interface records...');
        FOR indx IN 1 .. p_cnv_pre_std_hdr_table.COUNT
        LOOP
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).process_code ' || p_cnv_pre_std_hdr_table(indx).process_code);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).error_code ' || p_cnv_pre_std_hdr_table(indx).ERROR_CODE);

         UPDATE xx_po_headers_pre_int
            SET interface_header_id       =    p_cnv_pre_std_hdr_table(indx).interface_header_id
              , batch_id                  =    p_cnv_pre_std_hdr_table(indx).batch_id
              , source_system_name        =    p_cnv_pre_std_hdr_table(indx).source_system_name -- New column Added for CR P2P-DCR-006
              , interface_source_code     =    p_cnv_pre_std_hdr_table(indx).interface_source_code
              , process_code              =    p_cnv_pre_std_hdr_table(indx).process_code
              , action                    =    p_cnv_pre_std_hdr_table(indx).action
              , group_code                =    p_cnv_pre_std_hdr_table(indx).group_code
              , org_id                    =    p_cnv_pre_std_hdr_table(indx).org_id
              , document_type_code        =    p_cnv_pre_std_hdr_table(indx).document_type_code
              , document_subtype          =    p_cnv_pre_std_hdr_table(indx).document_subtype
              , document_num              =    p_cnv_pre_std_hdr_table(indx).document_num
              , po_header_id              =    p_cnv_pre_std_hdr_table(indx).po_header_id
              , release_num               =    p_cnv_pre_std_hdr_table(indx).release_num
              , po_release_id             =    p_cnv_pre_std_hdr_table(indx).po_release_id
              , release_date              =    p_cnv_pre_std_hdr_table(indx).release_date
              , currency_code             =    p_cnv_pre_std_hdr_table(indx).currency_code
              , rate_type                 =    p_cnv_pre_std_hdr_table(indx).rate_type
              , rate_type_code            =    p_cnv_pre_std_hdr_table(indx).rate_type_code
              , rate_date                 =    p_cnv_pre_std_hdr_table(indx).rate_date
              , rate                      =    p_cnv_pre_std_hdr_table(indx).rate
              , agent_name                =    p_cnv_pre_std_hdr_table(indx).agent_name
              , agent_id                  =    p_cnv_pre_std_hdr_table(indx).agent_id
              , vendor_name               =    p_cnv_pre_std_hdr_table(indx).vendor_name
              , vendor_number              = p_cnv_pre_std_hdr_table(indx).vendor_number
              , vendor_id                 =    p_cnv_pre_std_hdr_table(indx).vendor_id
              , vendor_site_code          =    p_cnv_pre_std_hdr_table(indx).vendor_site_code
              , vendor_site_id            =    p_cnv_pre_std_hdr_table(indx).vendor_site_id
              , vendor_contact            =    p_cnv_pre_std_hdr_table(indx).vendor_contact
              , vendor_contact_id         =    p_cnv_pre_std_hdr_table(indx).vendor_contact_id
              , ship_to_location          =    p_cnv_pre_std_hdr_table(indx).ship_to_location
              , ship_to_location_id       =    p_cnv_pre_std_hdr_table(indx).ship_to_location_id
              , bill_to_location          =    p_cnv_pre_std_hdr_table(indx).bill_to_location
              , bill_to_location_id       =    p_cnv_pre_std_hdr_table(indx).bill_to_location_id
              , payment_terms             =    p_cnv_pre_std_hdr_table(indx).payment_terms
              , terms_id                  =    p_cnv_pre_std_hdr_table(indx).terms_id
              , freight_carrier           =    p_cnv_pre_std_hdr_table(indx).freight_carrier
              , fob                       =    p_cnv_pre_std_hdr_table(indx).fob
              , freight_terms             =    p_cnv_pre_std_hdr_table(indx).freight_terms
              , approval_status           =    p_cnv_pre_std_hdr_table(indx).approval_status
              , approved_date             =    p_cnv_pre_std_hdr_table(indx).approved_date
              , revised_date              =    p_cnv_pre_std_hdr_table(indx).revised_date
              , revision_num              =    p_cnv_pre_std_hdr_table(indx).revision_num
              , note_to_vendor            =    p_cnv_pre_std_hdr_table(indx).note_to_vendor
              , note_to_receiver          =    p_cnv_pre_std_hdr_table(indx).note_to_receiver
              , confirming_order_flag     =    p_cnv_pre_std_hdr_table(indx).confirming_order_flag
              , comments                  =    p_cnv_pre_std_hdr_table(indx).comments
              , acceptance_required_flag  =    p_cnv_pre_std_hdr_table(indx).acceptance_required_flag
              , acceptance_due_date       =    p_cnv_pre_std_hdr_table(indx).acceptance_due_date
              , amount_agreed             =    p_cnv_pre_std_hdr_table(indx).amount_agreed
              , amount_limit              =    p_cnv_pre_std_hdr_table(indx).amount_limit
              , min_release_amount        =    p_cnv_pre_std_hdr_table(indx).min_release_amount
              , effective_date            =    p_cnv_pre_std_hdr_table(indx).effective_date
              , expiration_date           =    p_cnv_pre_std_hdr_table(indx).expiration_date
              , print_count               =    p_cnv_pre_std_hdr_table(indx).print_count
              , printed_date              =    p_cnv_pre_std_hdr_table(indx).printed_date
              , firm_flag                 =    p_cnv_pre_std_hdr_table(indx).firm_flag
              , frozen_flag               =    p_cnv_pre_std_hdr_table(indx).frozen_flag
              , closed_code               =    p_cnv_pre_std_hdr_table(indx).closed_code
              , closed_date               =    p_cnv_pre_std_hdr_table(indx).closed_date
              , reply_date                =    p_cnv_pre_std_hdr_table(indx).reply_date
              , reply_method              =    p_cnv_pre_std_hdr_table(indx).reply_method
              , rfq_close_date            =    p_cnv_pre_std_hdr_table(indx).rfq_close_date
              , quote_warning_delay       =    p_cnv_pre_std_hdr_table(indx).quote_warning_delay
              , vendor_doc_num            =    p_cnv_pre_std_hdr_table(indx).vendor_doc_num
              , approval_required_flag    =    p_cnv_pre_std_hdr_table(indx).approval_required_flag
              , vendor_list               =    p_cnv_pre_std_hdr_table(indx).vendor_list
              , vendor_list_header_id     =    p_cnv_pre_std_hdr_table(indx).vendor_list_header_id
              , from_header_id            =    p_cnv_pre_std_hdr_table(indx).from_header_id
              , from_type_lookup_code     =    p_cnv_pre_std_hdr_table(indx).from_type_lookup_code
              , ussgl_transaction_code    =    p_cnv_pre_std_hdr_table(indx).ussgl_transaction_code
              , attribute_category        =    p_cnv_pre_std_hdr_table(indx).attribute_category
              , attribute1                =    p_cnv_pre_std_hdr_table(indx).attribute1
              , attribute2                =    p_cnv_pre_std_hdr_table(indx).attribute2
              , attribute3                =    p_cnv_pre_std_hdr_table(indx).attribute3
              , attribute4                =    p_cnv_pre_std_hdr_table(indx).attribute4
              , attribute5                = p_cnv_pre_std_hdr_table(indx).attribute5
              , attribute6                =    p_cnv_pre_std_hdr_table(indx).attribute6
              , attribute7                =    p_cnv_pre_std_hdr_table(indx).attribute7
              , attribute8                =    p_cnv_pre_std_hdr_table(indx).attribute8
              , attribute9                =    p_cnv_pre_std_hdr_table(indx).attribute9
              , attribute10               =    p_cnv_pre_std_hdr_table(indx).attribute10
              , attribute11               =    p_cnv_pre_std_hdr_table(indx).attribute11
              , attribute12               =    p_cnv_pre_std_hdr_table(indx).attribute12
              , attribute13               =    p_cnv_pre_std_hdr_table(indx).attribute13
              , attribute14               =    p_cnv_pre_std_hdr_table(indx).attribute14
              , attribute15               =    p_cnv_pre_std_hdr_table(indx).attribute15
              , creation_date             =    p_cnv_pre_std_hdr_table(indx).creation_date
              , created_by                =    p_cnv_pre_std_hdr_table(indx).created_by
              , last_update_date          =    x_last_update_date
              , last_updated_by           =    x_last_updated_by
              , last_update_login         =    x_last_update_login
              , request_id                =    p_cnv_pre_std_hdr_table(indx).request_id
              , program_application_id    =    p_cnv_pre_std_hdr_table(indx).program_application_id
              , program_id                =    p_cnv_pre_std_hdr_table(indx).program_id
              , program_update_date       =    p_cnv_pre_std_hdr_table(indx).program_update_date
              , reference_num             =    p_cnv_pre_std_hdr_table(indx).reference_num
              , load_sourcing_rules_flag  =    p_cnv_pre_std_hdr_table(indx).load_sourcing_rules_flag
              , vendor_num                =    p_cnv_pre_std_hdr_table(indx).vendor_num
              , from_rfq_num              =    p_cnv_pre_std_hdr_table(indx).from_rfq_num
              , wf_group_id               =    p_cnv_pre_std_hdr_table(indx).wf_group_id
              , pcard_id                  =    p_cnv_pre_std_hdr_table(indx).pcard_id
              , pay_on_code               =    p_cnv_pre_std_hdr_table(indx).pay_on_code
              , global_agreement_flag     =    p_cnv_pre_std_hdr_table(indx).global_agreement_flag
              , consume_req_demand_flag   =    p_cnv_pre_std_hdr_table(indx).consume_req_demand_flag
              , shipping_control          =    p_cnv_pre_std_hdr_table(indx).shipping_control
              , encumbrance_required_flag =    p_cnv_pre_std_hdr_table(indx).encumbrance_required_flag
              , amount_to_encumber        =    p_cnv_pre_std_hdr_table(indx).amount_to_encumber
              , change_summary            =    p_cnv_pre_std_hdr_table(indx).change_summary
              , budget_account_segment1   =    p_cnv_pre_std_hdr_table(indx).budget_account_segment1
              , budget_account_segment2   =    p_cnv_pre_std_hdr_table(indx).budget_account_segment2
              , budget_account_segment3   =    p_cnv_pre_std_hdr_table(indx).budget_account_segment3
              , budget_account_segment4   =    p_cnv_pre_std_hdr_table(indx).budget_account_segment4
              , budget_account_segment5   =    p_cnv_pre_std_hdr_table(indx).budget_account_segment5
              , budget_account_segment6   =    p_cnv_pre_std_hdr_table(indx).budget_account_segment6
              , budget_account_segment7   =    p_cnv_pre_std_hdr_table(indx).budget_account_segment7
              , budget_account_segment8   =    p_cnv_pre_std_hdr_table(indx).budget_account_segment8
              , budget_account_segment9   =    p_cnv_pre_std_hdr_table(indx).budget_account_segment9
              , budget_account_segment10  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment10
              , budget_account_segment11  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment11
              , budget_account_segment12  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment12
              , budget_account_segment13  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment13
              , budget_account_segment14  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment14
              , budget_account_segment15  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment15
              , budget_account_segment16  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment16
              , budget_account_segment17  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment17
              , budget_account_segment18  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment18
              , budget_account_segment19  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment19
              , budget_account_segment20  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment20
              , budget_account_segment21  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment21
              , budget_account_segment22  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment22
              , budget_account_segment23  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment23
              , budget_account_segment24  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment24
              , budget_account_segment25  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment25
              , budget_account_segment26  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment26
              , budget_account_segment27  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment27
              , budget_account_segment28  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment28
              , budget_account_segment29  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment29
              , budget_account_segment30  =    p_cnv_pre_std_hdr_table(indx).budget_account_segment30
              , budget_account            =    p_cnv_pre_std_hdr_table(indx).budget_account
              , budget_account_id         =    p_cnv_pre_std_hdr_table(indx).budget_account_id
              , gl_encumbered_date        =    p_cnv_pre_std_hdr_table(indx).gl_encumbered_date
              , gl_encumbered_period_name =    p_cnv_pre_std_hdr_table(indx).gl_encumbered_period_name
              , created_language          =    p_cnv_pre_std_hdr_table(indx).created_language
              , cpa_reference             =    p_cnv_pre_std_hdr_table(indx).cpa_reference
              , draft_id                  =    p_cnv_pre_std_hdr_table(indx).draft_id
              , processing_id             =    p_cnv_pre_std_hdr_table(indx).processing_id
              , processing_round_num      =    p_cnv_pre_std_hdr_table(indx).processing_round_num
              , original_po_header_id     =    p_cnv_pre_std_hdr_table(indx).original_po_header_id
              , style_id                  =    p_cnv_pre_std_hdr_table(indx).style_id
              , style_display_name        =    p_cnv_pre_std_hdr_table(indx).style_display_name
              , organization_code         =    p_cnv_pre_std_hdr_table(indx).organization_code
              , organization_id           =    p_cnv_pre_std_hdr_table(indx).organization_id
              , record_number             =    p_cnv_pre_std_hdr_table(indx).record_number
              , ERROR_CODE                =    p_cnv_pre_std_hdr_table(indx).ERROR_CODE
              , legacy_po_number          =    p_cnv_pre_std_hdr_table(indx).legacy_po_number
          WHERE record_number             =    p_cnv_pre_std_hdr_table(indx).record_number
            AND batch_id                  = G_BATCH_ID;
        END LOOP;
  COMMIT;
    END update_pre_hdr_int_records;

    --Line Level Update
-------------------------------------------------------------------------------
 /**
 * PROCEDURE update_pre_lines_int_records
 *
 * DESCRIPTION
 *     PROCEDURE to update lines preinterface records.
 *
 * ARGUMENTS
 *   IN:
 *      p_cnv_pre_std_line_table     Line Table Type
 *   IN/OUT:
 *   OUT:
 */
-------------------------------------------------------------------------------
    PROCEDURE update_pre_lines_int_records (p_cnv_pre_std_line_table IN G_XX_PO_CNV_PRE_LINE_TAB_TYPE)
    IS


            PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
            fnd_file.put_line(fnd_file.LOG,'Inside of update pre lines interface records...');
            FOR indx IN 1 .. p_cnv_pre_std_line_table.COUNT
            LOOP
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_line_table(indx).process_code ' || p_cnv_pre_std_line_table(indx).process_code);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_line_table(indx).error_code ' || p_cnv_pre_std_line_table(indx).ERROR_CODE);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_line_table(indx).shipment_num inside update_pre_lines_int_records ' || p_cnv_pre_std_line_table(indx).shipment_num);
         UPDATE xx_po_lines_pre_int
            SET interface_line_id                =    p_cnv_pre_std_line_table(indx).interface_line_id
              , interface_header_id              =    p_cnv_pre_std_line_table(indx).interface_header_id
              , action                           =    p_cnv_pre_std_line_table(indx).action
              , group_code                       =    p_cnv_pre_std_line_table(indx).group_code
              , organization_code                 =  p_cnv_pre_std_line_table(indx).organization_code
              , line_num                         =    p_cnv_pre_std_line_table(indx).line_num
              , po_line_id                       =    p_cnv_pre_std_line_table(indx).po_line_id
              , shipment_num                     =    p_cnv_pre_std_line_table(indx).shipment_num
              , line_location_id                 =    p_cnv_pre_std_line_table(indx).line_location_id
              , shipment_type                    =    p_cnv_pre_std_line_table(indx).shipment_type
              , requisition_line_id              =    p_cnv_pre_std_line_table(indx).requisition_line_id
              , document_num                     =    p_cnv_pre_std_line_table(indx).document_num
              , release_num                      =    p_cnv_pre_std_line_table(indx).release_num
              , po_header_id                     =    p_cnv_pre_std_line_table(indx).po_header_id
              , po_release_id                    =    p_cnv_pre_std_line_table(indx).po_release_id
              , source_shipment_id               =    p_cnv_pre_std_line_table(indx).source_shipment_id
              , contract_num                     =    p_cnv_pre_std_line_table(indx).contract_num
              , line_type                        =    p_cnv_pre_std_line_table(indx).line_type
              , line_type_id                     =    p_cnv_pre_std_line_table(indx).line_type_id
              , item                             =    p_cnv_pre_std_line_table(indx).item
              , item_id                          =    p_cnv_pre_std_line_table(indx).item_id
              , item_revision                    =    p_cnv_pre_std_line_table(indx).item_revision    ----- Added for WAVE2 Changes by Pravin
              , category                         =    p_cnv_pre_std_line_table(indx).category
              , category_id                      =    p_cnv_pre_std_line_table(indx).category_id
              , item_description                 =    p_cnv_pre_std_line_table(indx).item_description
              , vendor_product_num               =    p_cnv_pre_std_line_table(indx).vendor_product_num
              , uom_code                         =    p_cnv_pre_std_line_table(indx).uom_code
              , unit_of_measure                  =    p_cnv_pre_std_line_table(indx).unit_of_measure
              , quantity                         =    p_cnv_pre_std_line_table(indx).quantity
              , committed_amount                 =    p_cnv_pre_std_line_table(indx).committed_amount
              , min_order_quantity               =    p_cnv_pre_std_line_table(indx).min_order_quantity
              , max_order_quantity               =    p_cnv_pre_std_line_table(indx).max_order_quantity
              , unit_price                       =    p_cnv_pre_std_line_table(indx).unit_price
              , list_price_per_unit              =    p_cnv_pre_std_line_table(indx).list_price_per_unit
              , market_price                     =    p_cnv_pre_std_line_table(indx).market_price
              , allow_price_override_flag        =    p_cnv_pre_std_line_table(indx).allow_price_override_flag
              , not_to_exceed_price              =    p_cnv_pre_std_line_table(indx).not_to_exceed_price
              , negotiated_by_preparer_flag      =    p_cnv_pre_std_line_table(indx).negotiated_by_preparer_flag
              , un_number                        =    p_cnv_pre_std_line_table(indx).un_number
              , un_number_id                     =    p_cnv_pre_std_line_table(indx).un_number_id
              , hazard_class                     =    p_cnv_pre_std_line_table(indx).hazard_class
              , hazard_class_id                  =    p_cnv_pre_std_line_table(indx).hazard_class_id
              , note_to_vendor                   =    p_cnv_pre_std_line_table(indx).note_to_vendor
              , transaction_reason_code          =    p_cnv_pre_std_line_table(indx).transaction_reason_code
              , taxable_flag                     =    p_cnv_pre_std_line_table(indx).taxable_flag
              , tax_name                         =    p_cnv_pre_std_line_table(indx).tax_name
              , type_1099                        =    p_cnv_pre_std_line_table(indx).type_1099
              , capital_expense_flag             =    p_cnv_pre_std_line_table(indx).capital_expense_flag
              , inspection_required_flag         =    p_cnv_pre_std_line_table(indx).inspection_required_flag
              , receipt_required_flag            =    p_cnv_pre_std_line_table(indx).receipt_required_flag
              , payment_terms                    =    p_cnv_pre_std_line_table(indx).payment_terms
              , terms_id                         =    p_cnv_pre_std_line_table(indx).terms_id
              , price_type                       =    p_cnv_pre_std_line_table(indx).price_type
              , min_release_amount               =    p_cnv_pre_std_line_table(indx).min_release_amount
              , price_break_lookup_code          =    p_cnv_pre_std_line_table(indx).price_break_lookup_code
              , ussgl_transaction_code           =    p_cnv_pre_std_line_table(indx).ussgl_transaction_code
              , closed_code                      =    p_cnv_pre_std_line_table(indx).closed_code
              , closed_reason                    =    p_cnv_pre_std_line_table(indx).closed_reason
              , closed_date                      =    p_cnv_pre_std_line_table(indx).closed_date
              , closed_by                        =    p_cnv_pre_std_line_table(indx).closed_by
              , invoice_close_tolerance          =    p_cnv_pre_std_line_table(indx).invoice_close_tolerance
              , receive_close_tolerance          =    p_cnv_pre_std_line_table(indx).receive_close_tolerance
              , firm_flag                        =    p_cnv_pre_std_line_table(indx).firm_flag
              , days_early_receipt_allowed       =    p_cnv_pre_std_line_table(indx).days_early_receipt_allowed
              , days_late_receipt_allowed        =    p_cnv_pre_std_line_table(indx).days_late_receipt_allowed
              , enforce_ship_to_location_code    =    p_cnv_pre_std_line_table(indx).enforce_ship_to_location_code
              , allow_substitute_receipts_flag   =    p_cnv_pre_std_line_table(indx).allow_substitute_receipts_flag
              , receiving_routing                =    p_cnv_pre_std_line_table(indx).receiving_routing
              , receiving_routing_id             =    p_cnv_pre_std_line_table(indx).receiving_routing_id
              , qty_rcv_tolerance                =    p_cnv_pre_std_line_table(indx).qty_rcv_tolerance
              , over_tolerance_error_flag        =    p_cnv_pre_std_line_table(indx).over_tolerance_error_flag
              , qty_rcv_exception_code           =    p_cnv_pre_std_line_table(indx).qty_rcv_exception_code
              , receipt_days_exception_code      =    p_cnv_pre_std_line_table(indx).receipt_days_exception_code
              , ship_to_organization_code        =    p_cnv_pre_std_line_table(indx).ship_to_organization_code
              , ship_to_organization_id          =    p_cnv_pre_std_line_table(indx).ship_to_organization_id
              , ship_to_location                 =    p_cnv_pre_std_line_table(indx).ship_to_location
              , ship_to_location_id              =    p_cnv_pre_std_line_table(indx).ship_to_location_id
              , need_by_date                     =    p_cnv_pre_std_line_table(indx).need_by_date
              , promised_date                    =    p_cnv_pre_std_line_table(indx).promised_date
              , accrue_on_receipt_flag           =    p_cnv_pre_std_line_table(indx).accrue_on_receipt_flag
              , lead_time                        =    p_cnv_pre_std_line_table(indx).lead_time
              , lead_time_unit                   =    p_cnv_pre_std_line_table(indx).lead_time_unit
              , price_discount                   =    p_cnv_pre_std_line_table(indx).price_discount
              , freight_carrier                  =    p_cnv_pre_std_line_table(indx).freight_carrier
              , fob                              =    p_cnv_pre_std_line_table(indx).fob
              , freight_terms                    =    p_cnv_pre_std_line_table(indx).freight_terms
              , effective_date                   =    p_cnv_pre_std_line_table(indx).effective_date
              , expiration_date                  =    p_cnv_pre_std_line_table(indx).expiration_date
              , from_header_id                   =    p_cnv_pre_std_line_table(indx).from_header_id
              , from_line_id                     =    p_cnv_pre_std_line_table(indx).from_line_id
              , from_line_location_id            =    p_cnv_pre_std_line_table(indx).from_line_location_id
              , line_attribute_category_lines    =    p_cnv_pre_std_line_table(indx).line_attribute_category_lines
              , line_attribute1                  =    p_cnv_pre_std_line_table(indx).line_attribute1
              , line_attribute2                  =    p_cnv_pre_std_line_table(indx).line_attribute2
              , line_attribute3                  =    p_cnv_pre_std_line_table(indx).line_attribute3
              , line_attribute4                  =    p_cnv_pre_std_line_table(indx).line_attribute4
              , line_attribute5                  =    p_cnv_pre_std_line_table(indx).line_attribute5
              , line_attribute6                  =    p_cnv_pre_std_line_table(indx).line_attribute6
              , line_attribute7                  =    p_cnv_pre_std_line_table(indx).line_attribute7
              , line_attribute8                  =    p_cnv_pre_std_line_table(indx).line_attribute8
              , line_attribute9                  =    p_cnv_pre_std_line_table(indx).line_attribute9
              , line_attribute10                 =    p_cnv_pre_std_line_table(indx).line_attribute10
              , line_attribute11                 =    p_cnv_pre_std_line_table(indx).line_attribute11
              , line_attribute12                 =    p_cnv_pre_std_line_table(indx).line_attribute12
              , line_attribute13                 =    p_cnv_pre_std_line_table(indx).line_attribute13
              , line_attribute14                 =    p_cnv_pre_std_line_table(indx).line_attribute14
              , line_attribute15                 =    p_cnv_pre_std_line_table(indx).line_attribute15
              , shipment_attribute_category      =    p_cnv_pre_std_line_table(indx).shipment_attribute_category
              , shipment_attribute1              =    p_cnv_pre_std_line_table(indx).shipment_attribute1
              , shipment_attribute2              =    p_cnv_pre_std_line_table(indx).shipment_attribute2
              , shipment_attribute3              =    p_cnv_pre_std_line_table(indx).shipment_attribute3
              , shipment_attribute4              =    p_cnv_pre_std_line_table(indx).shipment_attribute4
              , shipment_attribute5              =    p_cnv_pre_std_line_table(indx).shipment_attribute5
              , shipment_attribute6              =    p_cnv_pre_std_line_table(indx).shipment_attribute6
              , shipment_attribute7              =    p_cnv_pre_std_line_table(indx).shipment_attribute7
              , shipment_attribute8              =    p_cnv_pre_std_line_table(indx).shipment_attribute8
              , shipment_attribute9              =    p_cnv_pre_std_line_table(indx).shipment_attribute9
              , shipment_attribute10             =    p_cnv_pre_std_line_table(indx).shipment_attribute10
              , shipment_attribute11             =    p_cnv_pre_std_line_table(indx).shipment_attribute11
              , shipment_attribute12             =    p_cnv_pre_std_line_table(indx).shipment_attribute12
              , shipment_attribute13             =    p_cnv_pre_std_line_table(indx).shipment_attribute13
              , shipment_attribute14             =    p_cnv_pre_std_line_table(indx).shipment_attribute14
              , shipment_attribute15             =    p_cnv_pre_std_line_table(indx).shipment_attribute15
              , last_update_date                 =    p_cnv_pre_std_line_table(indx).last_update_date
              , last_updated_by                  =    p_cnv_pre_std_line_table(indx).last_updated_by
              , last_update_login                =    p_cnv_pre_std_line_table(indx).last_update_login
              , creation_date                    =    p_cnv_pre_std_line_table(indx).creation_date
              , created_by                       =    p_cnv_pre_std_line_table(indx).created_by
              , request_id                       =    p_cnv_pre_std_line_table(indx).request_id
              , program_application_id           =    p_cnv_pre_std_line_table(indx).program_application_id
              , program_id                       =    p_cnv_pre_std_line_table(indx).program_id
              , program_update_date              =    p_cnv_pre_std_line_table(indx).program_update_date
              , organization_id                  =    p_cnv_pre_std_line_table(indx).organization_id
              , item_attribute_category          =    p_cnv_pre_std_line_table(indx).item_attribute_category
              , item_attribute1                  =    p_cnv_pre_std_line_table(indx).item_attribute1
              , item_attribute2                  =    p_cnv_pre_std_line_table(indx).item_attribute2
              , item_attribute3                  =    p_cnv_pre_std_line_table(indx).item_attribute3
              , item_attribute4                  =    p_cnv_pre_std_line_table(indx).item_attribute4
              , item_attribute5                  =    p_cnv_pre_std_line_table(indx).item_attribute5
              , item_attribute6                  =    p_cnv_pre_std_line_table(indx).item_attribute6
              , item_attribute7                  =    p_cnv_pre_std_line_table(indx).item_attribute7
              , item_attribute8                  =    p_cnv_pre_std_line_table(indx).item_attribute8
              , item_attribute9                  =    p_cnv_pre_std_line_table(indx).item_attribute9
              , item_attribute10                 =    p_cnv_pre_std_line_table(indx).item_attribute10
              , item_attribute11                 =    p_cnv_pre_std_line_table(indx).item_attribute11
              , item_attribute12                 =    p_cnv_pre_std_line_table(indx).item_attribute12
              , item_attribute13                 =    p_cnv_pre_std_line_table(indx).item_attribute13
              , item_attribute14                 =    p_cnv_pre_std_line_table(indx).item_attribute14
              , item_attribute15                 =    p_cnv_pre_std_line_table(indx).item_attribute15
              , unit_weight                      =    p_cnv_pre_std_line_table(indx).unit_weight
              , weight_uom_code                  =    p_cnv_pre_std_line_table(indx).weight_uom_code
              , volume_uom_code                  =    p_cnv_pre_std_line_table(indx).volume_uom_code
              , unit_volume                      =    p_cnv_pre_std_line_table(indx).unit_volume
              , template_id                      =    p_cnv_pre_std_line_table(indx).template_id
              , template_name                    =    p_cnv_pre_std_line_table(indx).template_name
              , line_reference_num               =    p_cnv_pre_std_line_table(indx).line_reference_num
              , sourcing_rule_name               =    p_cnv_pre_std_line_table(indx).sourcing_rule_name
              , tax_status_indicator             =    p_cnv_pre_std_line_table(indx).tax_status_indicator
              , process_code                     =    p_cnv_pre_std_line_table(indx).process_code
              , price_chg_accept_flag            =    p_cnv_pre_std_line_table(indx).price_chg_accept_flag
              , price_break_flag                 =    p_cnv_pre_std_line_table(indx).price_break_flag
              , price_update_tolerance           =    p_cnv_pre_std_line_table(indx).price_update_tolerance
              , tax_user_override_flag           =    p_cnv_pre_std_line_table(indx).tax_user_override_flag
              , tax_code_id                      =    p_cnv_pre_std_line_table(indx).tax_code_id
              , note_to_receiver                 =    p_cnv_pre_std_line_table(indx).note_to_receiver
              , oke_contract_header_id           =    p_cnv_pre_std_line_table(indx).oke_contract_header_id
              , oke_contract_header_num          =    p_cnv_pre_std_line_table(indx).oke_contract_header_num
              , oke_contract_version_id          =    p_cnv_pre_std_line_table(indx).oke_contract_version_id
              , secondary_unit_of_measure        =    p_cnv_pre_std_line_table(indx).secondary_unit_of_measure
              , secondary_uom_code               =    p_cnv_pre_std_line_table(indx).secondary_uom_code
              , secondary_quantity               =    p_cnv_pre_std_line_table(indx).secondary_quantity
              , preferred_grade                  =    p_cnv_pre_std_line_table(indx).preferred_grade
              , vmi_flag                         =    p_cnv_pre_std_line_table(indx).vmi_flag
              , auction_header_id                =    p_cnv_pre_std_line_table(indx).auction_header_id
              , auction_line_number              =    p_cnv_pre_std_line_table(indx).auction_line_number
              , auction_display_number           =    p_cnv_pre_std_line_table(indx).auction_display_number
              , bid_number                       =    p_cnv_pre_std_line_table(indx).bid_number
              , bid_line_number                  =    p_cnv_pre_std_line_table(indx).bid_line_number
              , orig_from_req_flag               =    p_cnv_pre_std_line_table(indx).orig_from_req_flag
              , consigned_flag                   =    p_cnv_pre_std_line_table(indx).consigned_flag
              , supplier_ref_number              =    p_cnv_pre_std_line_table(indx).supplier_ref_number
              , contract_id                      =    p_cnv_pre_std_line_table(indx).contract_id
              , job_id                           =    p_cnv_pre_std_line_table(indx).job_id
              , amount                           =    p_cnv_pre_std_line_table(indx).amount
              , job_name                         =    p_cnv_pre_std_line_table(indx).job_name
              , contractor_first_name            =    p_cnv_pre_std_line_table(indx).contractor_first_name
              , contractor_last_name             =    p_cnv_pre_std_line_table(indx).contractor_last_name
              , drop_ship_flag                   =    p_cnv_pre_std_line_table(indx).drop_ship_flag
              , base_unit_price                  =    p_cnv_pre_std_line_table(indx).base_unit_price
              , transaction_flow_header_id       =    p_cnv_pre_std_line_table(indx).transaction_flow_header_id
              , job_business_group_id            =    p_cnv_pre_std_line_table(indx).job_business_group_id
              , job_business_group_name          =    p_cnv_pre_std_line_table(indx).job_business_group_name
              , catalog_name                     =    p_cnv_pre_std_line_table(indx).catalog_name
              , supplier_part_auxid              =    p_cnv_pre_std_line_table(indx).supplier_part_auxid
              , ip_category_id                   =    p_cnv_pre_std_line_table(indx).ip_category_id
              , tracking_quantity_ind            =    p_cnv_pre_std_line_table(indx).tracking_quantity_ind
              , secondary_default_ind            =    p_cnv_pre_std_line_table(indx).secondary_default_ind
              , dual_uom_deviation_high          =    p_cnv_pre_std_line_table(indx).dual_uom_deviation_high
              , dual_uom_deviation_low           =    p_cnv_pre_std_line_table(indx).dual_uom_deviation_low
              , processing_id                    =    p_cnv_pre_std_line_table(indx).processing_id
              , line_loc_populated_flag          =    p_cnv_pre_std_line_table(indx).line_loc_populated_flag
              , ip_category_name                 =    p_cnv_pre_std_line_table(indx).ip_category_name
              , retainage_rate                   =    p_cnv_pre_std_line_table(indx).retainage_rate
              , max_retainage_amount             =    p_cnv_pre_std_line_table(indx).max_retainage_amount
              , progress_payment_rate            =    p_cnv_pre_std_line_table(indx).progress_payment_rate
              , recoupment_rate                  =    p_cnv_pre_std_line_table(indx).recoupment_rate
              , advance_amount                   =    p_cnv_pre_std_line_table(indx).advance_amount
              , file_line_number                 =    p_cnv_pre_std_line_table(indx).file_line_number
              , parent_interface_line_id         =    p_cnv_pre_std_line_table(indx).parent_interface_line_id
              , file_line_language               =    p_cnv_pre_std_line_table(indx).file_line_language
              , po_header_num                    =    p_cnv_pre_std_line_table(indx).po_header_num
              , batch_id                         =    p_cnv_pre_std_line_table(indx).batch_id
              , record_number                    =    p_cnv_pre_std_line_table(indx).record_number
              , ERROR_CODE                       =    p_cnv_pre_std_line_table(indx).ERROR_CODE
              , legacy_po_number                 =  p_cnv_pre_std_line_table(indx).legacy_po_number
          WHERE record_number                     =    p_cnv_pre_std_line_table(indx).record_number
            AND BATCH_ID                         =  G_LINE_BATCH_ID;


           IF p_cnv_pre_std_line_table(indx).ERROR_CODE IN ( xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_REC_WARN) THEN
               UPDATE xx_po_headers_pre_int
                  SET ERROR_CODE = p_cnv_pre_std_line_table(indx).ERROR_CODE
                WHERE legacy_po_number = p_cnv_pre_std_line_table(indx).legacy_po_number;
       END IF;
        END LOOP;
        COMMIT;
    END update_pre_lines_int_records;

    --Distribution Level Update
-------------------------------------------------------------------------------
 /**
 * PROCEDURE update_pre_dist_int_records
 *
 * DESCRIPTION
 *     PROCEDURE to update distribution preinterface records.
 *
 * ARGUMENTS
 *   IN:
 *      p_cnv_pre_std_dist_table     Distribution Table Type
 *   IN/OUT:
 *   OUT:
 */
-------------------------------------------------------------------------------
    PROCEDURE update_pre_dist_int_records (p_cnv_pre_std_dist_table IN G_XX_PO_CNV_PRE_DIST_TAB_TYPE)
    IS
        x_last_update_date     DATE   := SYSDATE;
        x_last_updated_by      NUMBER := fnd_global.user_id;
        x_last_update_login    NUMBER := fnd_profile.VALUE (xx_emf_cn_pkg.CN_LOGIN_ID);

            PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
            fnd_file.put_line(fnd_file.LOG,'Inside of update pre distributions interface records...');
            FOR indx IN 1 .. p_cnv_pre_std_dist_table.COUNT
            LOOP
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_dist_table(indx).process_code_c ' || p_cnv_pre_std_dist_table(indx).process_code_c);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_dist_table(indx).error_code ' || p_cnv_pre_std_dist_table(indx).ERROR_CODE);

          UPDATE xx_po_distributions_pre_int
             SET interface_header_id                =    p_cnv_pre_std_dist_table(indx).interface_header_id
                ,interface_line_id                  =    p_cnv_pre_std_dist_table(indx).interface_line_id
                ,interface_distribution_id          =    p_cnv_pre_std_dist_table(indx).interface_distribution_id
                ,po_header_id                       =    p_cnv_pre_std_dist_table(indx).po_header_id
                ,po_release_id                      =    p_cnv_pre_std_dist_table(indx).po_release_id
                ,po_line_id                         =    p_cnv_pre_std_dist_table(indx).po_line_id
                ,line_location_id                   =    p_cnv_pre_std_dist_table(indx).line_location_id
                ,po_distribution_id                 =    p_cnv_pre_std_dist_table(indx).po_distribution_id
                ,distribution_num                   =    p_cnv_pre_std_dist_table(indx).distribution_num
                ,source_distribution_id             =    p_cnv_pre_std_dist_table(indx).source_distribution_id
                ,org_id                             =    p_cnv_pre_std_dist_table(indx).org_id
                ,quantity_ordered                   =    p_cnv_pre_std_dist_table(indx).quantity_ordered
                ,quantity_delivered                 =    p_cnv_pre_std_dist_table(indx).quantity_delivered
                ,quantity_billed                    =    p_cnv_pre_std_dist_table(indx).quantity_billed
                ,quantity_cancelled                 =    p_cnv_pre_std_dist_table(indx).quantity_cancelled
                ,rate_date                          =    p_cnv_pre_std_dist_table(indx).rate_date
                ,rate                               =    p_cnv_pre_std_dist_table(indx).rate
                ,deliver_to_location                =    p_cnv_pre_std_dist_table(indx).deliver_to_location
                ,deliver_to_location_id             =    p_cnv_pre_std_dist_table(indx).deliver_to_location_id
                ,deliver_to_person_full_name        =    p_cnv_pre_std_dist_table(indx).deliver_to_person_full_name
                ,deliver_to_person_id               =    p_cnv_pre_std_dist_table(indx).deliver_to_person_id
                ,destination_type                   =    p_cnv_pre_std_dist_table(indx).destination_type
                ,destination_type_code              =    p_cnv_pre_std_dist_table(indx).destination_type_code
                ,destination_organization           =    p_cnv_pre_std_dist_table(indx).destination_organization
                ,destination_organization_id        =    p_cnv_pre_std_dist_table(indx).destination_organization_id
                ,destination_subinventory           =    p_cnv_pre_std_dist_table(indx).destination_subinventory
                ,destination_context                =    p_cnv_pre_std_dist_table(indx).destination_context
                ,set_of_books                       =    p_cnv_pre_std_dist_table(indx).set_of_books
                ,set_of_books_id                    =    p_cnv_pre_std_dist_table(indx).set_of_books_id
                ,charge_account                     =    p_cnv_pre_std_dist_table(indx).charge_account
                ,charge_account_id                  =    p_cnv_pre_std_dist_table(indx).charge_account_id
                ,budget_account                     =    p_cnv_pre_std_dist_table(indx).budget_account
                ,budget_account_id                  =    p_cnv_pre_std_dist_table(indx).budget_account_id
                ,accural_account                    =    p_cnv_pre_std_dist_table(indx).accural_account
                ,accrual_account_id                 =    p_cnv_pre_std_dist_table(indx).accrual_account_id
                ,variance_account                   =    p_cnv_pre_std_dist_table(indx).variance_account
                ,variance_account_id                =    p_cnv_pre_std_dist_table(indx).variance_account_id
                ,amount_billed                      =    p_cnv_pre_std_dist_table(indx).amount_billed
                ,accrue_on_receipt_flag             =    p_cnv_pre_std_dist_table(indx).accrue_on_receipt_flag
                ,accrued_flag                       =    p_cnv_pre_std_dist_table(indx).accrued_flag
                ,prevent_encumbrance_flag           =    p_cnv_pre_std_dist_table(indx).prevent_encumbrance_flag
                ,encumbered_flag                    =    p_cnv_pre_std_dist_table(indx).encumbered_flag
                ,encumbered_amount                  =    p_cnv_pre_std_dist_table(indx).encumbered_amount
                ,unencumbered_quantity              =    p_cnv_pre_std_dist_table(indx).unencumbered_quantity
                ,unencumbered_amount                =    p_cnv_pre_std_dist_table(indx).unencumbered_amount
                ,failed_funds                       =    p_cnv_pre_std_dist_table(indx).failed_funds
                ,failed_funds_lookup_code           =    p_cnv_pre_std_dist_table(indx).failed_funds_lookup_code
                ,gl_encumbered_date                 =    p_cnv_pre_std_dist_table(indx).gl_encumbered_date
                ,gl_encumbered_period_name          =    p_cnv_pre_std_dist_table(indx).gl_encumbered_period_name
                ,gl_cancelled_date                  =    p_cnv_pre_std_dist_table(indx).gl_cancelled_date
                ,gl_closed_date                     =    p_cnv_pre_std_dist_table(indx).gl_closed_date
                ,req_header_reference_num           =    p_cnv_pre_std_dist_table(indx).req_header_reference_num
                ,req_line_reference_num             =    p_cnv_pre_std_dist_table(indx).req_line_reference_num
                ,req_distribution_id                =    p_cnv_pre_std_dist_table(indx).req_distribution_id
                ,wip_entity                         =    p_cnv_pre_std_dist_table(indx).wip_entity
                ,wip_entity_id                      =    p_cnv_pre_std_dist_table(indx).wip_entity_id
                ,wip_operation_seq_num              =    p_cnv_pre_std_dist_table(indx).wip_operation_seq_num
                ,wip_resource_seq_num               =    p_cnv_pre_std_dist_table(indx).wip_resource_seq_num
                ,wip_repetitive_schedule            =    p_cnv_pre_std_dist_table(indx).wip_repetitive_schedule
                ,wip_repetitive_schedule_id         =    p_cnv_pre_std_dist_table(indx).wip_repetitive_schedule_id
                ,wip_line_code                      =    p_cnv_pre_std_dist_table(indx).wip_line_code
                ,wip_line_id                        =    p_cnv_pre_std_dist_table(indx).wip_line_id
                ,bom_resource_code                  =    p_cnv_pre_std_dist_table(indx).bom_resource_code
                ,bom_resource_id                    =    p_cnv_pre_std_dist_table(indx).bom_resource_id
                ,ussgl_transaction_code             =    p_cnv_pre_std_dist_table(indx).ussgl_transaction_code
                ,government_context                 =    p_cnv_pre_std_dist_table(indx).government_context
                ,project                            =    p_cnv_pre_std_dist_table(indx).project
                ,project_id                         =    p_cnv_pre_std_dist_table(indx).project_id
                ,task                               =    p_cnv_pre_std_dist_table(indx).task
                ,task_id                            =    p_cnv_pre_std_dist_table(indx).task_id
                ,end_item_unit_number               =    p_cnv_pre_std_dist_table(indx).end_item_unit_number
                ,expenditure                        =    p_cnv_pre_std_dist_table(indx).expenditure
                ,expenditure_type                   =    p_cnv_pre_std_dist_table(indx).expenditure_type
                ,project_accounting_context         =    p_cnv_pre_std_dist_table(indx).project_accounting_context
                ,expenditure_organization           =    p_cnv_pre_std_dist_table(indx).expenditure_organization
                ,expenditure_organization_id        =    p_cnv_pre_std_dist_table(indx).expenditure_organization_id
                ,project_releated_flag              =    p_cnv_pre_std_dist_table(indx).project_releated_flag
                ,expenditure_item_date              =    p_cnv_pre_std_dist_table(indx).expenditure_item_date
                ,attribute_category                 =    p_cnv_pre_std_dist_table(indx).attribute_category
                ,attribute1                         =    p_cnv_pre_std_dist_table(indx).attribute1
                ,attribute2                         =    p_cnv_pre_std_dist_table(indx).attribute2
                ,attribute3                         =    p_cnv_pre_std_dist_table(indx).attribute3
                ,attribute4                         =    p_cnv_pre_std_dist_table(indx).attribute4
                ,attribute5                         =    p_cnv_pre_std_dist_table(indx).attribute5
                ,attribute6                         =    p_cnv_pre_std_dist_table(indx).attribute6
                ,attribute7                         =    p_cnv_pre_std_dist_table(indx).attribute7
                ,attribute8                         =    p_cnv_pre_std_dist_table(indx).attribute8
                ,attribute9                         =    p_cnv_pre_std_dist_table(indx).attribute9
                ,attribute10                        =    p_cnv_pre_std_dist_table(indx).attribute10
                ,attribute11                        =    p_cnv_pre_std_dist_table(indx).attribute11
                ,attribute12                        =    p_cnv_pre_std_dist_table(indx).attribute12
                ,attribute13                        =    p_cnv_pre_std_dist_table(indx).attribute13
                ,attribute14                        =    p_cnv_pre_std_dist_table(indx).attribute14
                ,attribute15                        =    p_cnv_pre_std_dist_table(indx).attribute15
                ,last_update_date                   =    x_last_update_date --p_cnv_pre_std_dist_table(indx).last_update_date
                ,last_updated_by                    =    x_last_updated_by --p_cnv_pre_std_dist_table(indx).last_updated_by
                ,last_update_login                  =    x_last_update_login --p_cnv_pre_std_dist_table(indx).last_update_login
                ,creation_date                      =    p_cnv_pre_std_dist_table(indx).creation_date
                ,created_by                         =    p_cnv_pre_std_dist_table(indx).created_by
                ,request_id                         =    p_cnv_pre_std_dist_table(indx).request_id
                ,program_application_id             =    p_cnv_pre_std_dist_table(indx).program_application_id
                ,program_id                         =    p_cnv_pre_std_dist_table(indx).program_id
                ,program_update_date                =    p_cnv_pre_std_dist_table(indx).program_update_date
                ,recoverable_tax                    =    p_cnv_pre_std_dist_table(indx).recoverable_tax
                ,nonrecoverable_tax                 =    p_cnv_pre_std_dist_table(indx).nonrecoverable_tax
                ,recovery_rate                      =    p_cnv_pre_std_dist_table(indx).recovery_rate
                ,tax_recovery_override_flag         =    p_cnv_pre_std_dist_table(indx).tax_recovery_override_flag
                ,award_id                           =    p_cnv_pre_std_dist_table(indx).award_id
                ,charge_account_segment1            =    p_cnv_pre_std_dist_table(indx).charge_account_segment1
                ,charge_account_segment2            =    p_cnv_pre_std_dist_table(indx).charge_account_segment2
                ,charge_account_segment3            =    p_cnv_pre_std_dist_table(indx).charge_account_segment3
                ,charge_account_segment4            =    p_cnv_pre_std_dist_table(indx).charge_account_segment4
                ,charge_account_segment5            =    p_cnv_pre_std_dist_table(indx).charge_account_segment5
                ,charge_account_segment6            =    p_cnv_pre_std_dist_table(indx).charge_account_segment6
                ,charge_account_segment7            =    p_cnv_pre_std_dist_table(indx).charge_account_segment7
                ,charge_account_segment8            =    p_cnv_pre_std_dist_table(indx).charge_account_segment8
                ,charge_account_segment9            =    p_cnv_pre_std_dist_table(indx).charge_account_segment9
                ,charge_account_segment10           =    p_cnv_pre_std_dist_table(indx).charge_account_segment10
                ,charge_account_segment11           =    p_cnv_pre_std_dist_table(indx).charge_account_segment11
                ,charge_account_segment12           =    p_cnv_pre_std_dist_table(indx).charge_account_segment12
                ,charge_account_segment13           =    p_cnv_pre_std_dist_table(indx).charge_account_segment13
                ,charge_account_segment14           =    p_cnv_pre_std_dist_table(indx).charge_account_segment14
                ,charge_account_segment15           =    p_cnv_pre_std_dist_table(indx).charge_account_segment15
                ,charge_account_segment16           =    p_cnv_pre_std_dist_table(indx).charge_account_segment16
                ,charge_account_segment17           =    p_cnv_pre_std_dist_table(indx).charge_account_segment17
                ,charge_account_segment18           =    p_cnv_pre_std_dist_table(indx).charge_account_segment18
                ,charge_account_segment19           =    p_cnv_pre_std_dist_table(indx).charge_account_segment19
                ,charge_account_segment20           =    p_cnv_pre_std_dist_table(indx).charge_account_segment20
                ,charge_account_segment21           =    p_cnv_pre_std_dist_table(indx).charge_account_segment21
                ,charge_account_segment22           =    p_cnv_pre_std_dist_table(indx).charge_account_segment22
                ,charge_account_segment23           =    p_cnv_pre_std_dist_table(indx).charge_account_segment23
                ,charge_account_segment24           =    p_cnv_pre_std_dist_table(indx).charge_account_segment24
                ,charge_account_segment25           =    p_cnv_pre_std_dist_table(indx).charge_account_segment25
                ,charge_account_segment26           =    p_cnv_pre_std_dist_table(indx).charge_account_segment26
                ,charge_account_segment27           =    p_cnv_pre_std_dist_table(indx).charge_account_segment27
                ,charge_account_segment28           =    p_cnv_pre_std_dist_table(indx).charge_account_segment28
                ,charge_account_segment29           =    p_cnv_pre_std_dist_table(indx).charge_account_segment29
                ,charge_account_segment30           =    p_cnv_pre_std_dist_table(indx).charge_account_segment30
                ,oke_contract_line_id               =    p_cnv_pre_std_dist_table(indx).oke_contract_line_id
                ,oke_contract_line_num              =      p_cnv_pre_std_dist_table(indx).oke_contract_line_num
                ,oke_contract_deliverable_id        =    p_cnv_pre_std_dist_table(indx).oke_contract_deliverable_id
                ,oke_contract_deliverable_num       =    p_cnv_pre_std_dist_table(indx).oke_contract_deliverable_num
                ,award_number                       =    p_cnv_pre_std_dist_table(indx).award_number
                ,amount_ordered                     =    p_cnv_pre_std_dist_table(indx).amount_ordered
                ,invoice_adjustment_flag            =    p_cnv_pre_std_dist_table(indx).invoice_adjustment_flag
                ,dest_charge_account_id             =    p_cnv_pre_std_dist_table(indx).dest_charge_account_id
                ,dest_variance_account_id           =    p_cnv_pre_std_dist_table(indx).dest_variance_account_id
                ,interface_line_location_id         =    p_cnv_pre_std_dist_table(indx).interface_line_location_id
                ,processing_id                      =    p_cnv_pre_std_dist_table(indx).processing_id
                ,process_code                       =    p_cnv_pre_std_dist_table(indx).process_code
                ,interface_distribution_ref         =    p_cnv_pre_std_dist_table(indx).interface_distribution_ref
                ,batch_id                           =    p_cnv_pre_std_dist_table(indx).batch_id
                ,record_number                      =    p_cnv_pre_std_dist_table(indx).record_number
                ,ERROR_CODE                         =    p_cnv_pre_std_dist_table(indx).ERROR_CODE
                ,process_code_c                     =    p_cnv_pre_std_dist_table(indx).process_code_c
                ,organization_code                    =    p_cnv_pre_std_dist_table(indx).organization_code
                ,document_num                        =    p_cnv_pre_std_dist_table(indx).document_num
                ,release_num                        =    p_cnv_pre_std_dist_table(indx).release_num
                ,line_num                            =    p_cnv_pre_std_dist_table(indx).line_num
                ,group_code                            =    p_cnv_pre_std_dist_table(indx).group_code
                ,shipment_num                           =   p_cnv_pre_std_dist_table(indx).shipment_num
           WHERE record_number                        =    p_cnv_pre_std_dist_table(indx).record_number
             AND BATCH_ID                           =   G_DIST_BATCH_ID;

           IF p_cnv_pre_std_dist_table(indx).ERROR_CODE IN ( xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_REC_WARN) THEN
               UPDATE xx_po_headers_pre_int
                  SET ERROR_CODE = p_cnv_pre_std_dist_table(indx).ERROR_CODE
                WHERE legacy_po_number = p_cnv_pre_std_dist_table(indx).attribute2;
       END IF;
        END LOOP;
        COMMIT;
    END update_pre_dist_int_records;

    -------------------------------------------------------------------------
    -----------< move_rec_pre_standard_table >-------------------------------
    -------------------------------------------------------------------------

    -- Header Level
-------------------------------------------------------------------------------
 /**
 * FUNCTION move_rec_pre_hdr_table
 *
 * DESCRIPTION
 *     FUNCTION to move records to header preinterface table.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *   OUT:
 *   RETURN:    Error Code
 */
-------------------------------------------------------------------------------
    FUNCTION move_rec_pre_hdr_table RETURN NUMBER
    IS
        x_creation_date         DATE   := SYSDATE;
        x_created_by            NUMBER := fnd_global.user_id;
        x_last_update_date      DATE   := SYSDATE;
        x_last_updated_by       NUMBER := fnd_global.user_id;
        x_last_update_login     NUMBER := fnd_profile.VALUE (xx_emf_cn_pkg.CN_LOGIN_ID);
        x_error_code                NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside move_rec_pre_hdr_table');

        -- Select only the appropriate columns that are required to be inserted into the
        -- Pre-Interface Table and insert from the Staging Table

        INSERT INTO xx_po_headers_pre_int
         ( batch_id
          ,record_number
          ,source_system_name  -- New column Added for CR P2P-DCR-006
          ,organization_code
          ,document_type_code
          ,currency_code
          ,rate_type
          ,rate_date
          ,rate
          ,agent_name
          ,vendor_number
          ,vendor_site_code
          ,ship_to_location
          ,bill_to_location
          ,payment_terms
          ,freight_carrier
          ,fob
          ,freight_terms
          ,approval_status
          ,attribute_category
          ,attribute1
          ,attribute2
          ,attribute3
          ,attribute4
          ,attribute5
          ,attribute6
          ,attribute7
          ,attribute8
          ,attribute9
          ,attribute10
          ,attribute11
          ,process_code
          ,ERROR_CODE
          ,creation_date
          ,created_by
          ,last_update_date
          ,last_updated_by
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date
      ,legacy_po_number
         )
  SELECT batch_id
            ,record_number
            ,source_system_name  -- New column Added for CR P2P-DCR-006
            ,organization_code
            ,document_type_code
            ,currency_code
            ,rate_type
            ,rate_date
            ,rate
            ,agent_name
            ,vendor_number
            ,vendor_site_code
            ,ship_to_location
            ,bill_to_location
            ,payment_terms
            ,freight_carrier
            ,fob
            ,freight_terms
            ,approval_status
            ,attribute_category
            ,attribute1
            ,attribute2
            ,attribute3
            ,attribute4
            ,attribute5
            ,attribute6
            ,attribute7
            ,attribute8
            ,attribute9
            ,attribute10
            ,batch_id
            ,process_code
            ,ERROR_CODE
            ,x_creation_date
            ,x_created_by
            ,x_last_update_date
            ,x_last_updated_by
            ,x_last_update_login
            ,request_id
            ,program_application_id
            ,program_id
            ,program_update_date
      ,legacy_po_number
          FROM xx_po_headers_stg    -- Order Headers Staging
         WHERE BATCH_ID     = G_BATCH_ID
           AND process_code = xx_emf_cn_pkg.CN_PREVAL
           AND request_id   = xx_emf_pkg.G_REQUEST_ID
           AND ERROR_CODE IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

        COMMIT;
        RETURN x_error_code;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
           xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
            x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
            RETURN x_error_code;
        WHEN TOO_MANY_ROWS THEN
            xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
            x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
            RETURN x_error_code;
        WHEN OTHERS THEN
            xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
            x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
            RETURN x_error_code;
    END move_rec_pre_hdr_table;

    -- Line Level
-------------------------------------------------------------------------------
 /**
 * FUNCTION move_rec_pre_lines_table
 *
 * DESCRIPTION
 *     FUNCTION to move records to Line preinterface table.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *   OUT:
 *   RETURN:    Error Code
 */
-------------------------------------------------------------------------------
    FUNCTION move_rec_pre_lines_table RETURN NUMBER
    IS

        x_error_code            NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside move_rec_pre_Lines_table');

        -- Select only the appropriate columns that are required to be inserted into the
        -- Pre-Interface Table and insert from the Staging Table
        INSERT INTO xx_po_lines_pre_int
         ( batch_id
          ,record_number
          ,organization_code
          ,line_num
          ,line_type
          ,shipment_num
          ,shipment_type
          ,item
          ,item_revision
          ,item_description
          ,vendor_product_num
          ,uom_code
          ,quantity
          ,unit_price
          ,payment_terms
          ,invoice_close_tolerance
          ,receive_close_tolerance
          ,ship_to_organization_code
          ,ship_to_location
          ,need_by_date
          ,promised_date
          ,freight_carrier
          ,fob
          ,freight_terms
          ,line_attribute_category_lines
          ,line_attribute1
          ,line_attribute2
          ,line_attribute3
          ,line_attribute4
          ,line_attribute5
          ,line_attribute6
          ,line_attribute7
          ,line_attribute8
          ,line_attribute9
          ,line_attribute10
          ,line_attribute11
          ,process_code
          ,ERROR_CODE
          ,creation_date
          ,created_by
          ,last_update_date
          ,last_updated_by
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date
      ,legacy_po_number
         )
         SELECT batch_id
               ,record_number
               ,organization_code
               ,line_num
               ,line_type
               ,shipment_num
               ,shipment_type
               ,item
               ,item_revision
               ,item_description
               ,vendor_product_num
               ,uom_code
               ,quantity
               ,unit_price
               ,payment_terms
               ,invoice_close_tolerance
               ,receive_close_tolerance
               ,ship_to_organization_code
               ,ship_to_location
               ,need_by_date
               ,promised_date
               ,freight_carrier
               ,fob
               ,freight_terms
               ,line_attribute_category
               ,line_attribute1
               ,line_attribute2
               ,line_attribute3
               ,line_attribute4
               ,line_attribute5
               ,line_attribute6
               ,line_attribute7
               ,line_attribute8
               ,line_attribute9
               ,line_attribute10
               ,batch_id
               ,process_code
               ,ERROR_CODE
               ,creation_date
               ,created_by
               ,last_update_date
               ,last_updated_by
               ,last_update_login
               ,request_id
               ,program_application_id
               ,program_id
               ,program_update_date
           ,legacy_po_number
          FROM xx_po_lines_stg
         WHERE batch_id     = G_LINE_BATCH_ID
           AND process_code = xx_emf_cn_pkg.CN_PREVAL
           AND request_id   = xx_emf_pkg.G_REQUEST_ID
           AND ERROR_CODE IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

        COMMIT;
        RETURN x_error_code;
    EXCEPTION
        WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in move_rec_pre_lines_table: '||SQLERRM);
            xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
            x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
            RETURN x_error_code;
    END move_rec_pre_lines_table;

 -- Distribution Level
 -------------------------------------------------------------------------------
 /**
 * FUNCTION move_rec_pre_dist_table
 *
 * DESCRIPTION
 *     FUNCTION to move records to Distribution preinterface table.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *   OUT:
 *   RETURN:    Error Code
 */
-------------------------------------------------------------------------------
    FUNCTION move_rec_pre_dist_table RETURN NUMBER
    IS

        x_error_code            NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside move_rec_pre_Dist_table');

        -- Select only the appropriate columns that are required to be inserted into the
        -- Pre-Interface Table and insert from the Staging Table
        INSERT INTO xx_po_distributions_pre_int
                                (organization_code
                                ,document_num
                                ,release_num
                                ,line_num
                                ,distribution_num
                                ,quantity_ordered
                                ,quantity_delivered
                                ,quantity_billed
                                ,quantity_cancelled
                                ,rate_date
                                ,rate
                                ,deliver_to_location
                                ,deliver_to_person_full_name
                                ,destination_type
                                ,destination_type_code
                                ,destination_organization
                                ,destination_subinventory
                                ,destination_context
                                ,set_of_books
                                ,charge_account
                                ,budget_account
                                ,accural_account
                                ,variance_account
                                ,amount_billed
                                ,accrue_on_receipt_flag
                                ,accrued_flag
                                ,prevent_encumbrance_flag
                                ,encumbered_flag
                                ,encumbered_amount
                                ,unencumbered_quantity
                                ,unencumbered_amount
                                ,failed_funds
                                ,failed_funds_lookup_code
                                ,gl_encumbered_date
                                ,gl_encumbered_period_name
                                ,gl_cancelled_date
                                ,gl_closed_date
                                ,req_header_reference_num
                                ,req_line_reference_num
                                ,wip_entity
                                ,wip_operation_seq_num
                                ,wip_resource_seq_num
                                ,wip_repetitive_schedule
                                ,wip_line_code
                                ,bom_resource_code
                                ,ussgl_transaction_code
                                ,government_context
                                ,project
                                ,task
                                ,end_item_unit_number
                                ,expenditure
                                ,expenditure_type
                                ,project_accounting_context
                                ,expenditure_organization
                                ,project_releated_flag
                                ,expenditure_item_date
                                ,attribute1
                                ,attribute2
                                ,attribute3
                                ,attribute4
                                ,attribute5
                                ,attribute6
                                ,attribute7
                                ,attribute8
                                ,attribute9
                                ,attribute10
                                ,attribute11
                                ,recoverable_tax
                                ,nonrecoverable_tax
                                ,recovery_rate
                                ,tax_recovery_override_flag
                                ,charge_account_segment1
                                ,charge_account_segment2
                                ,charge_account_segment3
                                ,charge_account_segment4
                                ,charge_account_segment5
                                ,charge_account_segment6
                                ,charge_account_segment7
                                ,charge_account_segment8
                                ,charge_account_segment9
                                ,charge_account_segment10
                                ,charge_account_segment11
                                ,charge_account_segment12
                                ,charge_account_segment13
                                ,charge_account_segment14
                                ,charge_account_segment15
                                ,charge_account_segment16
                                ,charge_account_segment17
                                ,charge_account_segment18
                                ,charge_account_segment19
                                ,charge_account_segment20
                                ,charge_account_segment21
                                ,charge_account_segment22
                                ,charge_account_segment23
                                ,charge_account_segment24
                                ,charge_account_segment25
                                ,charge_account_segment26
                                ,charge_account_segment27
                                ,charge_account_segment28
                                ,charge_account_segment29
                                ,charge_account_segment30
                                ,oke_contract_line_num
                                ,oke_contract_deliverable_num
                                ,award_number
                                ,amount_ordered
                                ,invoice_adjustment_flag
                                ,process_code
                                ,interface_distribution_ref
                                ,group_code
                                ,batch_id
                                ,record_number
                                ,process_code_c
                                ,ERROR_CODE
                                ,creation_date
                                ,created_by
                                ,last_update_date
                                ,last_updated_by
                                ,last_update_login
                                ,request_id
                                ,program_application_id
                                ,program_id
                                ,program_update_date
                                ,shipment_num
                                )
                          SELECT organization_code
                                ,document_num
                                ,release_num
                                ,line_num
                                ,distribution_num
                                ,quantity_ordered
                                ,quantity_delivered
                                ,quantity_billed
                                ,quantity_cancelled
                                ,rate_date
                                ,rate
                                ,deliver_to_location
                                ,deliver_to_person_full_name
                                ,destination_type
                                ,destination_type_code
                                ,destination_organization
                                ,destination_subinventory
                                ,destination_context
                                ,set_of_books
                                ,charge_account
                                ,budget_account
                                ,accural_account
                                ,variance_account
                                ,amount_billed
                                ,accrue_on_receipt_flag
                                ,accrued_flag
                                ,prevent_encumbrance_flag
                                ,encumbered_flag
                                ,encumbered_amount
                                ,unencumbered_quantity
                                ,unencumbered_amount
                                ,failed_funds
                                ,failed_funds_lookup_code
                                ,gl_encumbered_date
                                ,gl_encumbered_period_name
                                ,gl_cancelled_date
                                ,gl_closed_date
                                ,req_header_reference_num
                                ,req_line_reference_num
                                ,wip_entity
                                ,wip_operation_seq_num
                                ,wip_resource_seq_num
                                ,wip_repetitive_schedule
                                ,wip_line_code
                                ,bom_resource_code
                                ,ussgl_transaction_code
                                ,government_context
                                ,project
                                ,task
                                ,end_item_unit_number
                                ,expenditure
                                ,expenditure_type
                                ,project_accounting_context
                                ,expenditure_organization
                                ,project_releated_flag
                                ,expenditure_item_date
                                ,attribute1
                                ,attribute2
                                ,attribute3
                                ,attribute4
                                ,attribute5
                                ,attribute6
                                ,attribute7
                                ,attribute8
                                ,attribute9
                                ,attribute10
                                ,batch_id
                                ,recoverable_tax
                                ,nonrecoverable_tax
                                ,recovery_rate
                                ,tax_recovery_override_flag
                                ,charge_account_segment1
                                ,charge_account_segment2
                                ,charge_account_segment3
                                ,charge_account_segment4
                                ,charge_account_segment5
                                ,charge_account_segment6
                                ,charge_account_segment7
                                ,charge_account_segment8
                                ,charge_account_segment9
                                ,charge_account_segment10
                                ,charge_account_segment11
                                ,charge_account_segment12
                                ,charge_account_segment13
                                ,charge_account_segment14
                                ,charge_account_segment15
                                ,charge_account_segment16
                                ,charge_account_segment17
                                ,charge_account_segment18
                                ,charge_account_segment19
                                ,charge_account_segment20
                                ,charge_account_segment21
                                ,charge_account_segment22
                                ,charge_account_segment23
                                ,charge_account_segment24
                                ,charge_account_segment25
                                ,charge_account_segment26
                                ,charge_account_segment27
                                ,charge_account_segment28
                                ,charge_account_segment29
                                ,charge_account_segment30
                                ,oke_contract_line_num
                                ,oke_contract_deliverable_num
                                ,award_number
                                ,amount_ordered
                                ,invoice_adjustment_flag
                                ,process_code
                                ,interface_distribution_ref
                                ,group_code
                                ,batch_id
                                ,record_number
                                ,process_code_c
                                ,ERROR_CODE
                                ,creation_date
                                ,created_by
                                ,last_update_date
                                ,last_updated_by
                                ,last_update_login
                                ,request_id
                                ,program_application_id
                                ,program_id
                                ,program_update_date
                                ,shipment_num
                            FROM xx_po_distributions_stg
                           WHERE batch_id     = G_DIST_BATCH_ID
                             AND process_code_c = xx_emf_cn_pkg.CN_PREVAL
                             AND request_id   = xx_emf_pkg.G_REQUEST_ID
                             AND ERROR_CODE IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

        COMMIT;
        RETURN x_error_code;
    EXCEPTION
        WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in move_rec_pre_dist_table: '||SQLERRM);
            xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
            x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
            RETURN x_error_code;
    END move_rec_pre_dist_table;
     -------------------------------------------------------------------------
     -----------< process_data >----------------------------------------------
     -------------------------------------------------------------------------

    -- Header Level
 -------------------------------------------------------------------------------
 /**
 * FUNCTION process_data
 *
 * DESCRIPTION
 *     FUNCTION to process records.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *   OUT:
 *   RETURN:    Error Code
 */
-------------------------------------------------------------------------------
    FUNCTION process_data
    RETURN NUMBER
    IS
        x_return_status       VARCHAR2(15) := xx_emf_cn_pkg.CN_SUCCESS;
        l_int_line_id         NUMBER;
        l_int_lin_loc_id      NUMBER;
        PRAGMA AUTONOMOUS_TRANSACTION;

        -- Header level

        CURSOR c_xx_po_headers_process (cp_process_status VARCHAR2) IS
        SELECT interface_header_id
             , batch_id
             , source_system_name -- New column Added for CR P2P-DCR-006
             , interface_source_code
             , process_code
             , action
             , group_code
             , org_id
             , document_type_code
             , document_subtype
             , document_num
             , po_header_id
             , release_num
             , po_release_id
             , release_date
             , currency_code
             , rate_type
             , rate_type_code
             , rate_date
             , rate
             , agent_name
             , agent_id
             , vendor_name
             , vendor_number
             , vendor_id
             , vendor_site_code
             , vendor_site_id
             , vendor_contact
             , vendor_contact_id
             , ship_to_location
             , ship_to_location_id
             , bill_to_location
             , bill_to_location_id
             , payment_terms
             , terms_id
             , freight_carrier
             , fob
             , freight_terms
             , approval_status
             , approved_date
             , revised_date
             , revision_num
             , note_to_vendor
             , note_to_receiver
             , confirming_order_flag
             , comments
             , acceptance_required_flag
             , acceptance_due_date
             , amount_agreed
             , amount_limit
             , min_release_amount
             , effective_date
             , expiration_date
             , print_count
             , printed_date
             , firm_flag
             , frozen_flag
             , closed_code
             , closed_date
             , reply_date
             , reply_method
             , rfq_close_date
             , quote_warning_delay
             , vendor_doc_num
             , approval_required_flag
             , vendor_list
             , vendor_list_header_id
             , from_header_id
             , from_type_lookup_code
             , ussgl_transaction_code
             , attribute_category
             , attribute1
             , attribute2
             , attribute3
             , attribute4
             , attribute5
             , attribute6
             , attribute7
             , attribute8
             , attribute9
             , attribute10
             , attribute11
             , attribute12
             , attribute13
             , attribute14
             , attribute15
             , creation_date
             , created_by
             , last_update_date
             , last_updated_by
             , last_update_login
             , request_id
             , program_application_id
             , program_id
             , program_update_date
             , reference_num
             , load_sourcing_rules_flag
             , vendor_num
             , from_rfq_num
             , wf_group_id
             , pcard_id
             , pay_on_code
             , global_agreement_flag
             , consume_req_demand_flag
             , shipping_control
             , encumbrance_required_flag
             , amount_to_encumber
             , change_summary
             , budget_account_segment1
             , budget_account_segment2
             , budget_account_segment3
             , budget_account_segment4
             , budget_account_segment5
             , budget_account_segment6
             , budget_account_segment7
             , budget_account_segment8
             , budget_account_segment9
             , budget_account_segment10
             , budget_account_segment11
             , budget_account_segment12
             , budget_account_segment13
             , budget_account_segment14
             , budget_account_segment15
             , budget_account_segment16
             , budget_account_segment17
             , budget_account_segment18
             , budget_account_segment19
             , budget_account_segment20
             , budget_account_segment21
             , budget_account_segment22
             , budget_account_segment23
             , budget_account_segment24
             , budget_account_segment25
             , budget_account_segment26
             , budget_account_segment27
             , budget_account_segment28
             , budget_account_segment29
             , budget_account_segment30
             , budget_account
             , budget_account_id
             , gl_encumbered_date
             , gl_encumbered_period_name
             , created_language
             , cpa_reference
             , draft_id
             , processing_id
             , processing_round_num
             , original_po_header_id
             , style_id
             , style_display_name
             , organization_code
             , organization_id
             , record_number
             , ERROR_CODE
         , legacy_po_number
          FROM xx_po_headers_pre_int hdr
         WHERE batch_id     = G_BATCH_ID
           AND request_id   = xx_emf_pkg.G_REQUEST_ID
           AND process_code = cp_process_status
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
           --AND legacy_po_number = '201245'
         ORDER BY record_number;

         -- Line level

        CURSOR c_xx_po_lines_process (cp_process_status VARCHAR2, cp_legacy_po_no VARCHAR2) IS
        SELECT interface_line_id
             , interface_header_id
             , action
             , group_code
             , organization_code
             , TO_NUMBER(line_num) line_num --Added on 19-07-2012
             , po_line_id
             , shipment_num
             , line_location_id
             , shipment_type
             , requisition_line_id
             , document_num
             , release_num
             , po_header_id
             , po_release_id
             , source_shipment_id
             , contract_num
             , line_type
             , line_type_id
             , item
             , item_id
             , item_revision
             , category
             , category_id
             , item_description
             , vendor_product_num
             , uom_code
             , unit_of_measure
             , quantity
             , committed_amount
             , min_order_quantity
             , max_order_quantity
             , unit_price
             , list_price_per_unit
             , market_price
             , allow_price_override_flag
             , not_to_exceed_price
             , negotiated_by_preparer_flag
             , un_number
             , un_number_id
             , hazard_class
             , hazard_class_id
             , note_to_vendor
             , transaction_reason_code
             , taxable_flag
             , tax_name
             , type_1099
             , capital_expense_flag
             , inspection_required_flag
             , receipt_required_flag
             , payment_terms
             , terms_id
             , price_type
             , min_release_amount
             , price_break_lookup_code
             , ussgl_transaction_code
             , closed_code
             , closed_reason
             , closed_date
             , closed_by
             , invoice_close_tolerance
             , receive_close_tolerance
             , firm_flag
             , days_early_receipt_allowed
             , days_late_receipt_allowed
             , enforce_ship_to_location_code
             , allow_substitute_receipts_flag
             , receiving_routing
             , receiving_routing_id
             , qty_rcv_tolerance
             , over_tolerance_error_flag
             , qty_rcv_exception_code
             , receipt_days_exception_code
             , ship_to_organization_code
             , ship_to_organization_id
             , ship_to_location
             , ship_to_location_id
             , need_by_date
             , promised_date
             , accrue_on_receipt_flag
             , lead_time
             , lead_time_unit
             , price_discount
             , freight_carrier
             , fob
             , freight_terms
             , effective_date
             , expiration_date
             , from_header_id
             , from_line_id
             , from_line_location_id
             , line_attribute_category_lines
             , line_attribute1
             , line_attribute2
             , line_attribute3
             , line_attribute4
             , line_attribute5
             , line_attribute6
             , line_attribute7
             , line_attribute8
             , line_attribute9
             , line_attribute10
             , line_attribute11
             , line_attribute12
             , line_attribute13
             , line_attribute14
             , line_attribute15
             , shipment_attribute_category
             , shipment_attribute1
             , shipment_attribute2
             , shipment_attribute3
             , shipment_attribute4
             , shipment_attribute5
             , shipment_attribute6
             , shipment_attribute7
             , shipment_attribute8
             , shipment_attribute9
             , shipment_attribute10
             , shipment_attribute11
             , shipment_attribute12
             , shipment_attribute13
             , shipment_attribute14
             , shipment_attribute15
             , last_update_date
             , last_updated_by
             , last_update_login
             , creation_date
             , created_by
             , request_id
             , program_application_id
             , program_id
             , program_update_date
             , organization_id
             , item_attribute_category
             , item_attribute1
             , item_attribute2
             , item_attribute3
             , item_attribute4
             , item_attribute5
             , item_attribute6
             , item_attribute7
             , item_attribute8
             , item_attribute9
             , item_attribute10
             , item_attribute11
             , item_attribute12
             , item_attribute13
             , item_attribute14
             , item_attribute15
             , unit_weight
             , weight_uom_code
             , volume_uom_code
             , unit_volume
             , template_id
             , template_name
             , line_reference_num
             , sourcing_rule_name
             , tax_status_indicator
             , price_chg_accept_flag
             , price_break_flag
             , price_update_tolerance
             , tax_user_override_flag
             , tax_code_id
             , note_to_receiver
             , oke_contract_header_id
             , oke_contract_header_num
             , oke_contract_version_id
             , secondary_unit_of_measure
             , secondary_uom_code
             , secondary_quantity
             , preferred_grade
             , vmi_flag
             , auction_header_id
             , auction_line_number
             , auction_display_number
             , bid_number
             , bid_line_number
             , orig_from_req_flag
             , consigned_flag
             , supplier_ref_number
             , contract_id
             , job_id
             , amount
             , job_name
             , contractor_first_name
             , contractor_last_name
             , drop_ship_flag
             , base_unit_price
             , transaction_flow_header_id
             , job_business_group_id
             , job_business_group_name
             , catalog_name
             , supplier_part_auxid
             , ip_category_id
             , tracking_quantity_ind
             , secondary_default_ind
             , dual_uom_deviation_high
             , dual_uom_deviation_low
             , processing_id
             , line_loc_populated_flag
             , ip_category_name
             , retainage_rate
             , max_retainage_amount
             , progress_payment_rate
             , recoupment_rate
             , advance_amount
             , file_line_number
             , parent_interface_line_id
             , file_line_language
             , po_header_num
             , batch_id
             , record_number
             , ERROR_CODE
             , process_code
         , legacy_po_number
          FROM xx_po_lines_pre_int line
         WHERE batch_id     = G_LINE_BATCH_ID
           AND request_id   = xx_emf_pkg.G_REQUEST_ID
           AND process_code = cp_process_status
           AND legacy_po_number   = cp_legacy_po_no
           AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
           --AND legacy_po_number = '201245'
             ORDER BY line_num;

        -- Distribution level

        CURSOR c_xx_po_dist_process (cp_process_status VARCHAR2, cp_legacy_po_no VARCHAR2, cp_line_num NUMBER,cp_ship_num NUMBER) IS
        SELECT  interface_header_id
                ,interface_line_id
                ,interface_distribution_id
                ,po_header_id
                ,po_release_id
                ,po_line_id
                ,line_location_id
                ,po_distribution_id
                ,distribution_num
                ,source_distribution_id
                ,org_id
                ,quantity_ordered
                ,quantity_delivered
                ,quantity_billed
                ,quantity_cancelled
                ,rate_date
                ,rate
                ,deliver_to_location
                ,deliver_to_location_id
                ,deliver_to_person_full_name
                ,deliver_to_person_id
                ,destination_type
                ,destination_type_code
                ,destination_organization
                ,destination_organization_id
                ,destination_subinventory
                ,destination_context
                ,set_of_books
                ,set_of_books_id
                ,charge_account
                ,charge_account_id
                ,budget_account
                ,budget_account_id
                ,accural_account
                ,accrual_account_id
                ,variance_account
                ,variance_account_id
                ,amount_billed
                ,accrue_on_receipt_flag
                ,accrued_flag
                ,prevent_encumbrance_flag
                ,encumbered_flag
                ,encumbered_amount
                ,unencumbered_quantity
                ,unencumbered_amount
                ,failed_funds
                ,failed_funds_lookup_code
                ,gl_encumbered_date
                ,gl_encumbered_period_name
                ,gl_cancelled_date
                ,gl_closed_date
                ,req_header_reference_num
                ,req_line_reference_num
                ,req_distribution_id
                ,wip_entity
                ,wip_entity_id
                ,wip_operation_seq_num
                ,wip_resource_seq_num
                ,wip_repetitive_schedule
                ,wip_repetitive_schedule_id
                ,wip_line_code
                ,wip_line_id
                ,bom_resource_code
                ,bom_resource_id
                ,ussgl_transaction_code
                ,government_context
                ,project
                ,project_id
                ,task
                ,task_id
                ,end_item_unit_number
                ,expenditure
                ,expenditure_type
                ,project_accounting_context
                ,expenditure_organization
                ,expenditure_organization_id
                ,project_releated_flag
                ,expenditure_item_date
                ,attribute_category
                ,attribute1
                ,attribute2
                ,attribute3
                ,attribute4
                ,attribute5
                ,attribute6
                ,attribute7
                ,attribute8
                ,attribute9
                ,attribute10
                ,attribute11
                ,attribute12
                ,attribute13
                ,attribute14
                ,attribute15
                ,last_update_date
                ,last_updated_by
                ,last_update_login
                ,creation_date
                ,created_by
                ,request_id
                ,program_application_id
                ,program_id
                ,program_update_date
                ,recoverable_tax
                ,nonrecoverable_tax
                ,recovery_rate
                ,tax_recovery_override_flag
                ,award_id
                ,charge_account_segment1
                ,charge_account_segment2
                ,charge_account_segment3
                ,charge_account_segment4
                ,charge_account_segment5
                ,charge_account_segment6
                ,charge_account_segment7
                ,charge_account_segment8
                ,charge_account_segment9
                ,charge_account_segment10
                ,charge_account_segment11
                ,charge_account_segment12
                ,charge_account_segment13
                ,charge_account_segment14
                ,charge_account_segment15
                ,charge_account_segment16
                ,charge_account_segment17
                ,charge_account_segment18
                ,charge_account_segment19
                ,charge_account_segment20
                ,charge_account_segment21
                ,charge_account_segment22
                ,charge_account_segment23
                ,charge_account_segment24
                ,charge_account_segment25
                ,charge_account_segment26
                ,charge_account_segment27
                ,charge_account_segment28
                ,charge_account_segment29
                ,charge_account_segment30
                ,oke_contract_line_id
                ,oke_contract_line_num
                ,oke_contract_deliverable_id
                ,oke_contract_deliverable_num
                ,award_number
                ,amount_ordered
                ,invoice_adjustment_flag
                ,dest_charge_account_id
                ,dest_variance_account_id
                ,interface_line_location_id
                ,processing_id
                ,process_code
                ,interface_distribution_ref
                ,batch_id
                ,record_number
                ,ERROR_CODE
                ,process_code_c
                ,organization_code
                ,document_num
                ,release_num
                ,TO_NUMBER(line_num) line_num
                ,group_code
                ,shipment_num
            FROM xx_po_distributions_pre_int dist
           WHERE batch_id     = G_DIST_BATCH_ID
             AND request_id   = xx_emf_pkg.G_REQUEST_ID
             AND process_code_c = cp_process_status
             AND attribute2   = cp_legacy_po_no
             AND line_num||'.'||shipment_num = cp_ship_num
             AND line_num      = cp_line_num
             AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
             --AND attribute2 = '201245'
          ORDER BY record_number;

    BEGIN
        -- Change the logic to whatever needs to be done
        -- with valid records in the pre-interface tables
        -- either call the appropriate API to process the data
        -- or to insert into an interface table
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inserting Records into Standard Headers Interface');

            FOR c_xx_po_headers_process_rec IN c_xx_po_headers_process (xx_emf_cn_pkg.CN_POSTVAL)
             LOOP

             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Inserting Records into Standard Headers Interface');

        --BEGIN
        INSERT INTO po_headers_interface
        (       interface_header_id              ,
            batch_id                          ,
            interface_source_code             ,
            process_code                      ,
            action                            ,
            group_code                        ,
            org_id                            ,
            document_type_code                ,
            document_subtype                  ,
            document_num                      ,
            po_header_id                      ,
            release_num                       ,
            po_release_id                     ,
            release_date                      ,
            currency_code                     ,
            rate_type                         ,
            rate_type_code                    ,
            rate_date                         ,
            rate                              ,
            agent_name                        ,
            agent_id                          ,
            vendor_name                       ,
            vendor_id                         ,
            vendor_site_code                  ,
            vendor_site_id                    ,
            vendor_contact                    ,
            vendor_contact_id                 ,
            ship_to_location                  ,
            ship_to_location_id               ,
            bill_to_location                  ,
            bill_to_location_id               ,
            payment_terms                     ,
            terms_id                          ,
            freight_carrier                  ,
            fob                               ,
            freight_terms                     ,
            approval_status                   ,
            approved_date                     ,
            revised_date                      ,
            revision_num                      ,
            note_to_vendor                    ,
            note_to_receiver                  ,
            confirming_order_flag             ,
            comments                          ,
            acceptance_required_flag          ,
            acceptance_due_date               ,
            amount_agreed                     ,
            amount_limit                      ,
            min_release_amount                ,
            effective_date                    ,
            expiration_date                   ,
            print_count                       ,
            printed_date                      ,
            firm_flag                         ,
            frozen_flag                       ,
            closed_code                       ,
            closed_date                       ,
            reply_date                        ,
            reply_method                      ,
            rfq_close_date                    ,
            quote_warning_delay               ,
            vendor_doc_num                    ,
            approval_required_flag            ,
            vendor_list                       ,
            vendor_list_header_id             ,
            from_header_id                    ,
            from_type_lookup_code             ,
            ussgl_transaction_code            ,
            attribute_category                ,
            attribute1                        ,
            attribute2                        ,
            attribute3                        ,
            attribute4                        ,
            attribute5                        ,
            attribute6                        ,
            attribute7                        ,
            attribute8                        ,
            attribute9                        ,
            attribute10                       ,
            attribute11                       ,
            attribute12                      ,
            attribute13                       ,
            attribute14                       ,
            attribute15                       ,
            creation_date                     ,
            created_by                        ,
            last_update_date                  ,
            last_updated_by                   ,
            last_update_login                 ,
            request_id                        ,
            program_application_id            ,
            program_id                        ,
            program_update_date               ,
            reference_num                     ,
            load_sourcing_rules_flag          ,
            vendor_num                        ,
            from_rfq_num                      ,
            wf_group_id                       ,
            pcard_id                          ,
            pay_on_code                       ,
            global_agreement_flag             ,
            consume_req_demand_flag           ,
            shipping_control                  ,
            encumbrance_required_flag         ,
            amount_to_encumber                ,
            change_summary                    ,
            budget_account_segment1           ,
            budget_account_segment2           ,
            budget_account_segment3           ,
            budget_account_segment4           ,
            budget_account_segment5           ,
            budget_account_segment6           ,
            budget_account_segment7           ,
            budget_account_segment8           ,
            budget_account_segment9           ,
            budget_account_segment10          ,
            budget_account_segment11          ,
            budget_account_segment12          ,
            budget_account_segment13          ,
            budget_account_segment14          ,
            budget_account_segment15         ,
            budget_account_segment16          ,
            budget_account_segment17          ,
            budget_account_segment18          ,
            budget_account_segment19          ,
            budget_account_segment20          ,
            budget_account_segment21          ,
            budget_account_segment22          ,
            budget_account_segment23          ,
            budget_account_segment24          ,
            budget_account_segment25          ,
            budget_account_segment26          ,
            budget_account_segment27          ,
            budget_account_segment28          ,
            budget_account_segment29          ,
            budget_account_segment30          ,
            budget_account                    ,
            budget_account_id                 ,
            gl_encumbered_date                ,
            gl_encumbered_period_name         ,
            created_language                  ,
            cpa_reference                     ,
            draft_id                          ,
            processing_id                     ,
            processing_round_num              ,
            original_po_header_id             ,
            style_id                          ,
            style_display_name
                )
      VALUES
            (po_headers_interface_s.NEXTVAL,
            NULL,--c_xx_po_headers_process_rec.batch_id,
            c_xx_po_headers_process_rec.interface_source_code             ,
            'PENDING',--process_code                      ,
            'ORIGINAL',--action                            ,
            c_xx_po_headers_process_rec.group_code                        ,
            c_xx_po_headers_process_rec.org_id                            ,
            c_xx_po_headers_process_rec.document_type_code                ,
            c_xx_po_headers_process_rec.document_subtype                  ,
            --c_xx_po_headers_process_rec.source_system_name||c_xx_po_headers_process_rec.legacy_po_number,  --document_num   ---- New column Added for CR P2P-DCR-006
            c_xx_po_headers_process_rec.legacy_po_number                  ,  --Modified as per Wave2
            c_xx_po_headers_process_rec.po_header_id                      ,
            c_xx_po_headers_process_rec.release_num                       ,
            c_xx_po_headers_process_rec.po_release_id                     ,
            c_xx_po_headers_process_rec.release_date                      ,
            c_xx_po_headers_process_rec.currency_code                     ,
            c_xx_po_headers_process_rec.rate_type                         ,
            c_xx_po_headers_process_rec.rate_type_code                    ,
            c_xx_po_headers_process_rec.rate_date                         ,
            c_xx_po_headers_process_rec.rate                              ,
            c_xx_po_headers_process_rec.agent_name                        ,
            c_xx_po_headers_process_rec.agent_id                          ,
            c_xx_po_headers_process_rec.vendor_name                       ,
            c_xx_po_headers_process_rec.vendor_id                         ,
            c_xx_po_headers_process_rec.vendor_site_code                  ,
            c_xx_po_headers_process_rec.vendor_site_id                    ,
            c_xx_po_headers_process_rec.vendor_contact                    ,
            c_xx_po_headers_process_rec.vendor_contact_id                 ,
            c_xx_po_headers_process_rec.ship_to_location                  ,
            c_xx_po_headers_process_rec.ship_to_location_id               ,
            c_xx_po_headers_process_rec.bill_to_location                  ,
            c_xx_po_headers_process_rec.bill_to_location_id               ,
            c_xx_po_headers_process_rec.payment_terms                     ,
            c_xx_po_headers_process_rec.terms_id                          ,
            c_xx_po_headers_process_rec.freight_carrier                ,
            c_xx_po_headers_process_rec.fob                               ,
            c_xx_po_headers_process_rec.freight_terms                     ,
            c_xx_po_headers_process_rec.approval_status                   ,
            c_xx_po_headers_process_rec.approved_date                     ,
            c_xx_po_headers_process_rec.revised_date                      ,
            c_xx_po_headers_process_rec.revision_num                      ,
            c_xx_po_headers_process_rec.note_to_vendor                    ,
            c_xx_po_headers_process_rec.note_to_receiver                  ,
            c_xx_po_headers_process_rec.confirming_order_flag             ,
            c_xx_po_headers_process_rec.legacy_po_number,--comments                          ,
            c_xx_po_headers_process_rec.acceptance_required_flag          ,
            c_xx_po_headers_process_rec.acceptance_due_date               ,
            c_xx_po_headers_process_rec.amount_agreed                     ,
            c_xx_po_headers_process_rec.amount_limit                      ,
            c_xx_po_headers_process_rec.min_release_amount                ,
            c_xx_po_headers_process_rec.effective_date                    ,
            c_xx_po_headers_process_rec.expiration_date                   ,
            c_xx_po_headers_process_rec.print_count                       ,
            c_xx_po_headers_process_rec.printed_date                      ,
            c_xx_po_headers_process_rec.firm_flag                         ,
            c_xx_po_headers_process_rec.frozen_flag                       ,
            c_xx_po_headers_process_rec.closed_code                       ,
            c_xx_po_headers_process_rec.closed_date                       ,
            c_xx_po_headers_process_rec.reply_date                        ,
            c_xx_po_headers_process_rec.reply_method                      ,
            c_xx_po_headers_process_rec.rfq_close_date                    ,
            c_xx_po_headers_process_rec.quote_warning_delay               ,
            c_xx_po_headers_process_rec.legacy_po_number, --c_xx_po_headers_process_rec.vendor_doc_num                    ,
            c_xx_po_headers_process_rec.approval_required_flag            ,
            c_xx_po_headers_process_rec.vendor_list                       ,
            c_xx_po_headers_process_rec.vendor_list_header_id             ,
            c_xx_po_headers_process_rec.from_header_id                    ,
            c_xx_po_headers_process_rec.from_type_lookup_code             ,
            c_xx_po_headers_process_rec.ussgl_transaction_code            ,
            c_xx_po_headers_process_rec.attribute_category                ,
            c_xx_po_headers_process_rec.attribute1                        ,
            c_xx_po_headers_process_rec.attribute2                        ,
            c_xx_po_headers_process_rec.attribute3                        ,
            c_xx_po_headers_process_rec.attribute4                        ,
            c_xx_po_headers_process_rec.attribute5                        ,
            c_xx_po_headers_process_rec.attribute6                        ,
            c_xx_po_headers_process_rec.attribute7                        ,
            c_xx_po_headers_process_rec.attribute8                        ,
            c_xx_po_headers_process_rec.attribute9                        ,
            c_xx_po_headers_process_rec.attribute10                       ,
            c_xx_po_headers_process_rec.batch_id,--c_xx_po_headers_process_rec.attribute11                       ,
            c_xx_po_headers_process_rec.attribute12                    ,
            c_xx_po_headers_process_rec.attribute13                       ,
            c_xx_po_headers_process_rec.attribute14                       ,
            c_xx_po_headers_process_rec.attribute15                       ,
            c_xx_po_headers_process_rec.creation_date                     ,
            c_xx_po_headers_process_rec.created_by                        ,
            c_xx_po_headers_process_rec.last_update_date                  ,
            c_xx_po_headers_process_rec.last_updated_by                   ,
            c_xx_po_headers_process_rec.last_update_login                 ,
            c_xx_po_headers_process_rec.request_id                        ,
            c_xx_po_headers_process_rec.program_application_id            ,
            c_xx_po_headers_process_rec.program_id                        ,
            c_xx_po_headers_process_rec.program_update_date               ,
            c_xx_po_headers_process_rec.reference_num                     ,
            c_xx_po_headers_process_rec.load_sourcing_rules_flag          ,
            c_xx_po_headers_process_rec.vendor_num                        ,
            c_xx_po_headers_process_rec.from_rfq_num                      ,
            c_xx_po_headers_process_rec.wf_group_id                       ,
            c_xx_po_headers_process_rec.pcard_id                          ,
            c_xx_po_headers_process_rec.pay_on_code                       ,
            c_xx_po_headers_process_rec.global_agreement_flag             ,
            c_xx_po_headers_process_rec.consume_req_demand_flag           ,
            c_xx_po_headers_process_rec.shipping_control                  ,
            c_xx_po_headers_process_rec.encumbrance_required_flag         ,
            c_xx_po_headers_process_rec.amount_to_encumber                ,
            c_xx_po_headers_process_rec.change_summary                    ,
            c_xx_po_headers_process_rec.budget_account_segment1           ,
            c_xx_po_headers_process_rec.budget_account_segment2           ,
            c_xx_po_headers_process_rec.budget_account_segment3           ,
            c_xx_po_headers_process_rec.budget_account_segment4           ,
            c_xx_po_headers_process_rec.budget_account_segment5           ,
            c_xx_po_headers_process_rec.budget_account_segment6           ,
            c_xx_po_headers_process_rec.budget_account_segment7           ,
            c_xx_po_headers_process_rec.budget_account_segment8           ,
            c_xx_po_headers_process_rec.budget_account_segment9           ,
            c_xx_po_headers_process_rec.budget_account_segment10          ,
            c_xx_po_headers_process_rec.budget_account_segment11          ,
            c_xx_po_headers_process_rec.budget_account_segment12          ,
            c_xx_po_headers_process_rec.budget_account_segment13          ,
            c_xx_po_headers_process_rec.budget_account_segment14          ,
            c_xx_po_headers_process_rec.budget_account_segment15       ,
            c_xx_po_headers_process_rec.budget_account_segment16          ,
            c_xx_po_headers_process_rec.budget_account_segment17          ,
            c_xx_po_headers_process_rec.budget_account_segment18          ,
            c_xx_po_headers_process_rec.budget_account_segment19          ,
            c_xx_po_headers_process_rec.budget_account_segment20          ,
            c_xx_po_headers_process_rec.budget_account_segment21          ,
            c_xx_po_headers_process_rec.budget_account_segment22          ,
            c_xx_po_headers_process_rec.budget_account_segment23          ,
            c_xx_po_headers_process_rec.budget_account_segment24          ,
            c_xx_po_headers_process_rec.budget_account_segment25          ,
            c_xx_po_headers_process_rec.budget_account_segment26          ,
            c_xx_po_headers_process_rec.budget_account_segment27          ,
            c_xx_po_headers_process_rec.budget_account_segment28          ,
            c_xx_po_headers_process_rec.budget_account_segment29          ,
            c_xx_po_headers_process_rec.budget_account_segment30          ,
            c_xx_po_headers_process_rec.budget_account                    ,
            c_xx_po_headers_process_rec.budget_account_id                 ,
            c_xx_po_headers_process_rec.gl_encumbered_date                ,
            c_xx_po_headers_process_rec.gl_encumbered_period_name         ,
            c_xx_po_headers_process_rec.created_language                  ,
            c_xx_po_headers_process_rec.cpa_reference                     ,
            c_xx_po_headers_process_rec.draft_id                          ,
            c_xx_po_headers_process_rec.processing_id                     ,
            c_xx_po_headers_process_rec.processing_round_num              ,
            c_xx_po_headers_process_rec.original_po_header_id             ,
            c_xx_po_headers_process_rec.style_id                          ,
            c_xx_po_headers_process_rec.style_display_name
               );

         FOR c_xx_po_lines_process_rec IN c_xx_po_lines_process (xx_emf_cn_pkg.CN_POSTVAL,c_xx_po_headers_process_rec.legacy_po_number)
         LOOP


             G_LINE_LEGACY_PO_NUMBER :=c_xx_po_headers_process_rec.legacy_po_number;

             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Inserting Records into Standard Lines Interface');

      INSERT INTO po_lines_interface
               (     interface_line_id                     ,
                interface_header_id                   ,
                action                                ,
                group_code                            ,
                line_num                              ,
                po_line_id                            ,
                shipment_num                          ,
                line_location_id                      ,
                shipment_type                         ,
                requisition_line_id                   ,
                document_num                          ,
                release_num                           ,
                po_header_id                          ,
                po_release_id                         ,
                source_shipment_id                    ,
                contract_num                          ,
                line_type                             ,
                line_type_id                          ,
                item                                  ,
                item_id                               ,
                item_revision                         ,
                category                              ,
                category_id                           ,
                item_description                      ,
                vendor_product_num                    ,
                uom_code                              ,
                unit_of_measure                       ,
                quantity                              ,
                committed_amount                      ,
                min_order_quantity                    ,
                max_order_quantity                    ,
                unit_price                            ,
                list_price_per_unit                   ,
                market_price                          ,
                allow_price_override_flag             ,
                not_to_exceed_price                   ,
                negotiated_by_preparer_flag           ,
                un_number                             ,
                un_number_id                          ,
                hazard_class                          ,
                hazard_class_id                       ,
                note_to_vendor                        ,
                transaction_reason_code               ,
                taxable_flag                          ,
                tax_name                              ,
                type_1099                             ,
                capital_expense_flag                  ,
                inspection_required_flag              ,
                receipt_required_flag                 ,
                payment_terms                         ,
                terms_id                              ,
                price_type                            ,
                min_release_amount                    ,
                price_break_lookup_code               ,
                ussgl_transaction_code                ,
                closed_code                           ,
                closed_reason                         ,
                closed_date                           ,
                closed_by                             ,
                invoice_close_tolerance               ,
                receive_close_tolerance               ,
                firm_flag                             ,
                days_early_receipt_allowed            ,
                days_late_receipt_allowed             ,
                enforce_ship_to_location_code         ,
                allow_substitute_receipts_flag        ,
                receiving_routing                     ,
                receiving_routing_id                  ,
                qty_rcv_tolerance                     ,
                over_tolerance_error_flag             ,
                qty_rcv_exception_code                ,
                receipt_days_exception_code           ,
                ship_to_organization_code             ,
                ship_to_organization_id               ,
                ship_to_location                      ,
                ship_to_location_id                   ,
                need_by_date                          ,
                promised_date                         ,
                accrue_on_receipt_flag                ,
                lead_time                             ,
                lead_time_unit                        ,
                price_discount                        ,
                freight_carrier                       ,
                fob                                   ,
                freight_terms                         ,
                effective_date                        ,
                expiration_date                       ,
                from_header_id                        ,
                from_line_id                          ,
                from_line_location_id                 ,
                line_attribute_category_lines         ,
                line_attribute1                       ,
                line_attribute2                       ,
                line_attribute3                       ,
                line_attribute4                       ,
                line_attribute5                       ,
                line_attribute6                       ,
                line_attribute7                       ,
                line_attribute8                       ,
                line_attribute9                       ,
                line_attribute10                      ,
                line_attribute11                      ,
                line_attribute12                      ,
                line_attribute13                      ,
                line_attribute14                      ,
                line_attribute15                      ,
                shipment_attribute_category           ,
                shipment_attribute1                   ,
                shipment_attribute2                   ,
                shipment_attribute3                   ,
                shipment_attribute4                   ,
                shipment_attribute5                   ,
                shipment_attribute6                   ,
                shipment_attribute7                   ,
                shipment_attribute8                   ,
                shipment_attribute9                   ,
                shipment_attribute10                  ,
                shipment_attribute11                  ,
                shipment_attribute12                  ,
                shipment_attribute13                  ,
                shipment_attribute14                  ,
                shipment_attribute15                  ,
                last_update_date                      ,
                last_updated_by                       ,
                last_update_login                     ,
                creation_date                         ,
                created_by                            ,
                request_id                            ,
                program_application_id                ,
                program_id                            ,
                program_update_date                   ,
                organization_id                       ,
                item_attribute_category               ,
                item_attribute1                       ,
                item_attribute2                       ,
                item_attribute3                       ,
                item_attribute4                       ,
                item_attribute5                       ,
                item_attribute6                       ,
                item_attribute7                       ,
                item_attribute8                       ,
                item_attribute9                       ,
                item_attribute10                      ,
                item_attribute11                      ,
                item_attribute12                      ,
                item_attribute13                      ,
                item_attribute14                      ,
                item_attribute15                      ,
                unit_weight                           ,
                weight_uom_code                       ,
                volume_uom_code                       ,
                unit_volume                           ,
                template_id                           ,
                template_name                         ,
                line_reference_num                    ,
                sourcing_rule_name                    ,
                tax_status_indicator                  ,
                process_code                          ,
                price_chg_accept_flag                 ,
                price_break_flag                      ,
                price_update_tolerance                ,
                tax_user_override_flag                ,
                tax_code_id                           ,
                note_to_receiver                      ,
                oke_contract_header_id                ,
                oke_contract_header_num               ,
                oke_contract_version_id               ,
                secondary_unit_of_measure             ,
                secondary_uom_code                    ,
                secondary_quantity                    ,
                preferred_grade                       ,
                vmi_flag                              ,
                auction_header_id                     ,
                auction_line_number                   ,
                auction_display_number                ,
                bid_number                            ,
                bid_line_number                       ,
                orig_from_req_flag                    ,
                consigned_flag                        ,
                supplier_ref_number                   ,
                contract_id                           ,
                job_id                                ,
                amount                                ,
                job_name                              ,
                contractor_first_name                 ,
                contractor_last_name                  ,
                drop_ship_flag                        ,
                base_unit_price                       ,
                transaction_flow_header_id            ,
                job_business_group_id                 ,
                job_business_group_name               ,
                catalog_name                          ,
                supplier_part_auxid                   ,
                ip_category_id                        ,
                tracking_quantity_ind                 ,
                secondary_default_ind                 ,
                dual_uom_deviation_high               ,
                dual_uom_deviation_low                ,
                processing_id                         ,
                line_loc_populated_flag               ,
                ip_category_name                      ,
                retainage_rate                        ,
                max_retainage_amount                  ,
                progress_payment_rate                 ,
                recoupment_rate                       ,
                advance_amount                        ,
                file_line_number                      ,
                parent_interface_line_id              ,
                file_line_language
            )
            VALUES
            (
                po_lines_interface_s.NEXTVAL                                    ,
                po_headers_interface_s.CURRVAL                                    ,
                'ORIGINAL',--c_xx_po_lines_process_rec.action                                ,
                c_xx_po_lines_process_rec.group_code                            ,
                c_xx_po_lines_process_rec.line_num                              ,
                c_xx_po_lines_process_rec.po_line_id                            ,
                c_xx_po_lines_process_rec.shipment_num                          ,
                c_xx_po_lines_process_rec.line_location_id                      ,
                c_xx_po_lines_process_rec.shipment_type                         ,
                c_xx_po_lines_process_rec.requisition_line_id                   ,
                c_xx_po_lines_process_rec.document_num                          ,
                c_xx_po_lines_process_rec.release_num                           ,
                c_xx_po_lines_process_rec.po_header_id                          ,
                c_xx_po_lines_process_rec.po_release_id                         ,
                c_xx_po_lines_process_rec.source_shipment_id                    ,
                c_xx_po_lines_process_rec.contract_num                          ,
                c_xx_po_lines_process_rec.line_type                             ,
                c_xx_po_lines_process_rec.line_type_id                          ,
                c_xx_po_lines_process_rec.item                                  ,
                c_xx_po_lines_process_rec.item_id                               ,
                c_xx_po_lines_process_rec.item_revision                         ,
                c_xx_po_lines_process_rec.category                              ,
                c_xx_po_lines_process_rec.category_id                           ,
                c_xx_po_lines_process_rec.item_description                      ,
                c_xx_po_lines_process_rec.vendor_product_num                    ,
                c_xx_po_lines_process_rec.uom_code                              ,
                c_xx_po_lines_process_rec.unit_of_measure                       ,
                c_xx_po_lines_process_rec.quantity                              ,
                c_xx_po_lines_process_rec.committed_amount                      ,
                c_xx_po_lines_process_rec.min_order_quantity                    ,
                c_xx_po_lines_process_rec.max_order_quantity                    ,
                c_xx_po_lines_process_rec.unit_price                            ,
                c_xx_po_lines_process_rec.list_price_per_unit                   ,
                c_xx_po_lines_process_rec.market_price                          ,
                c_xx_po_lines_process_rec.allow_price_override_flag             ,
                c_xx_po_lines_process_rec.not_to_exceed_price                   ,
                c_xx_po_lines_process_rec.negotiated_by_preparer_flag           ,
                c_xx_po_lines_process_rec.un_number                             ,
                c_xx_po_lines_process_rec.un_number_id                          ,
                c_xx_po_lines_process_rec.hazard_class                          ,
                c_xx_po_lines_process_rec.hazard_class_id                       ,
                c_xx_po_lines_process_rec.note_to_vendor                        ,
                c_xx_po_lines_process_rec.transaction_reason_code               ,
                c_xx_po_lines_process_rec.taxable_flag                          ,
                c_xx_po_lines_process_rec.tax_name                              ,
                c_xx_po_lines_process_rec.type_1099                             ,
                c_xx_po_lines_process_rec.capital_expense_flag                  ,
                c_xx_po_lines_process_rec.inspection_required_flag              ,
                c_xx_po_lines_process_rec.receipt_required_flag                 ,
                c_xx_po_lines_process_rec.payment_terms                         ,
                c_xx_po_lines_process_rec.terms_id                              ,
                c_xx_po_lines_process_rec.price_type                            ,
                c_xx_po_lines_process_rec.min_release_amount                    ,
                c_xx_po_lines_process_rec.price_break_lookup_code               ,
                c_xx_po_lines_process_rec.ussgl_transaction_code                ,
                c_xx_po_lines_process_rec.closed_code                           ,
                c_xx_po_lines_process_rec.closed_reason                         ,
                c_xx_po_lines_process_rec.closed_date                           ,
                c_xx_po_lines_process_rec.closed_by                             ,
                c_xx_po_lines_process_rec.invoice_close_tolerance               ,
                c_xx_po_lines_process_rec.receive_close_tolerance               ,
                c_xx_po_lines_process_rec.firm_flag                             ,
                c_xx_po_lines_process_rec.days_early_receipt_allowed            ,
                c_xx_po_lines_process_rec.days_late_receipt_allowed             ,
                c_xx_po_lines_process_rec.enforce_ship_to_location_code         ,
                c_xx_po_lines_process_rec.allow_substitute_receipts_flag        ,
                c_xx_po_lines_process_rec.receiving_routing                     ,
                c_xx_po_lines_process_rec.receiving_routing_id                  ,
                c_xx_po_lines_process_rec.qty_rcv_tolerance                     ,
                c_xx_po_lines_process_rec.over_tolerance_error_flag             ,
                c_xx_po_lines_process_rec.qty_rcv_exception_code                ,
                c_xx_po_lines_process_rec.receipt_days_exception_code           ,
                c_xx_po_lines_process_rec.ship_to_organization_code             ,
                c_xx_po_lines_process_rec.ship_to_organization_id               ,
                c_xx_po_lines_process_rec.ship_to_location                      ,
                c_xx_po_lines_process_rec.ship_to_location_id                   ,
                c_xx_po_lines_process_rec.need_by_date                          ,--sysdate + 6,
                c_xx_po_lines_process_rec.promised_date                         ,
                c_xx_po_lines_process_rec.accrue_on_receipt_flag                ,
                c_xx_po_lines_process_rec.lead_time                             ,
                c_xx_po_lines_process_rec.lead_time_unit                        ,
                c_xx_po_lines_process_rec.price_discount                        ,
                c_xx_po_lines_process_rec.freight_carrier                       ,
                c_xx_po_lines_process_rec.fob                                   ,
                c_xx_po_lines_process_rec.freight_terms                         ,
                c_xx_po_lines_process_rec.effective_date                        ,
                c_xx_po_lines_process_rec.expiration_date                       ,
                c_xx_po_lines_process_rec.from_header_id                        ,
                c_xx_po_lines_process_rec.from_line_id                          ,
                c_xx_po_lines_process_rec.from_line_location_id                 ,
                c_xx_po_lines_process_rec.line_attribute_category_lines         ,
                c_xx_po_lines_process_rec.line_attribute1                       ,
                c_xx_po_lines_process_rec.line_attribute2                       ,
                c_xx_po_lines_process_rec.line_attribute3                       ,
                c_xx_po_lines_process_rec.line_attribute4                       ,
                c_xx_po_lines_process_rec.line_attribute5                       ,
                c_xx_po_lines_process_rec.line_attribute6                       ,
                c_xx_po_lines_process_rec.line_attribute7                       ,
                c_xx_po_lines_process_rec.line_attribute8                       ,
                c_xx_po_lines_process_rec.line_attribute9                       ,
                c_xx_po_lines_process_rec.line_attribute10                      ,
                c_xx_po_lines_process_rec.line_attribute11                      ,
                c_xx_po_lines_process_rec.line_attribute12                      ,
                c_xx_po_lines_process_rec.line_attribute13                      ,
                c_xx_po_lines_process_rec.line_attribute14                      ,
                c_xx_po_lines_process_rec.line_attribute15                      ,
                c_xx_po_lines_process_rec.shipment_attribute_category           ,
                c_xx_po_lines_process_rec.shipment_attribute1                   ,
                c_xx_po_lines_process_rec.shipment_attribute2                   ,
                c_xx_po_lines_process_rec.shipment_attribute3                   ,
                c_xx_po_lines_process_rec.shipment_attribute4                   ,
                c_xx_po_lines_process_rec.shipment_attribute5                   ,
                c_xx_po_lines_process_rec.shipment_attribute6                   ,
                c_xx_po_lines_process_rec.shipment_attribute7                   ,
                c_xx_po_lines_process_rec.shipment_attribute8                   ,
                c_xx_po_lines_process_rec.shipment_attribute9                   ,
                c_xx_po_lines_process_rec.shipment_attribute10                  ,
                c_xx_po_lines_process_rec.shipment_attribute11                  ,
                c_xx_po_lines_process_rec.shipment_attribute12                  ,
                c_xx_po_lines_process_rec.shipment_attribute13                  ,
                c_xx_po_lines_process_rec.shipment_attribute14                  ,
                c_xx_po_lines_process_rec.shipment_attribute15                  ,
                c_xx_po_lines_process_rec.last_update_date                      ,
                c_xx_po_lines_process_rec.last_updated_by                       ,
                c_xx_po_lines_process_rec.last_update_login                     ,
                c_xx_po_lines_process_rec.creation_date                         ,
                c_xx_po_lines_process_rec.created_by                            ,
                c_xx_po_lines_process_rec.request_id                            ,
                c_xx_po_lines_process_rec.program_application_id                ,
                c_xx_po_lines_process_rec.program_id                            ,
                c_xx_po_lines_process_rec.program_update_date                   ,
                c_xx_po_lines_process_rec.organization_id                       ,
                c_xx_po_lines_process_rec.item_attribute_category               ,
                c_xx_po_lines_process_rec.item_attribute1                       ,
                c_xx_po_lines_process_rec.item_attribute2                       ,
                c_xx_po_lines_process_rec.item_attribute3                       ,
                c_xx_po_lines_process_rec.item_attribute4                       ,
                c_xx_po_lines_process_rec.item_attribute5                       ,
                c_xx_po_lines_process_rec.item_attribute6                       ,
                c_xx_po_lines_process_rec.item_attribute7                       ,
                c_xx_po_lines_process_rec.item_attribute8                       ,
                c_xx_po_lines_process_rec.item_attribute9                       ,
                c_xx_po_lines_process_rec.item_attribute10                      ,
                c_xx_po_lines_process_rec.item_attribute11                      ,
                c_xx_po_lines_process_rec.item_attribute12                      ,
                c_xx_po_lines_process_rec.item_attribute13                      ,
                c_xx_po_lines_process_rec.item_attribute14                      ,
                c_xx_po_lines_process_rec.item_attribute15                      ,
                c_xx_po_lines_process_rec.unit_weight                           ,
                c_xx_po_lines_process_rec.weight_uom_code                       ,
                c_xx_po_lines_process_rec.volume_uom_code                       ,
                c_xx_po_lines_process_rec.unit_volume                           ,
                c_xx_po_lines_process_rec.template_id                           ,
                c_xx_po_lines_process_rec.template_name                         ,
                c_xx_po_lines_process_rec.line_reference_num                    ,
                c_xx_po_lines_process_rec.sourcing_rule_name                    ,
                c_xx_po_lines_process_rec.tax_status_indicator                  ,
                NULL,--process_code                          ,
                c_xx_po_lines_process_rec.price_chg_accept_flag                 ,
                c_xx_po_lines_process_rec.price_break_flag                      ,
                c_xx_po_lines_process_rec.price_update_tolerance                ,
                c_xx_po_lines_process_rec.tax_user_override_flag                ,
                c_xx_po_lines_process_rec.tax_code_id                           ,
                c_xx_po_lines_process_rec.note_to_receiver                      ,
                c_xx_po_lines_process_rec.oke_contract_header_id                ,
                c_xx_po_lines_process_rec.oke_contract_header_num               ,
                c_xx_po_lines_process_rec.oke_contract_version_id               ,
                c_xx_po_lines_process_rec.secondary_unit_of_measure             ,
                c_xx_po_lines_process_rec.secondary_uom_code,
                c_xx_po_lines_process_rec.secondary_quantity,
                c_xx_po_lines_process_rec.preferred_grade                       ,
                c_xx_po_lines_process_rec.vmi_flag                              ,
                c_xx_po_lines_process_rec.auction_header_id                     ,
                c_xx_po_lines_process_rec.auction_line_number                   ,
                c_xx_po_lines_process_rec.auction_display_number                ,
                c_xx_po_lines_process_rec.bid_number                            ,
                c_xx_po_lines_process_rec.bid_line_number                       ,
                c_xx_po_lines_process_rec.orig_from_req_flag                    ,
                c_xx_po_lines_process_rec.consigned_flag                        ,
                c_xx_po_lines_process_rec.supplier_ref_number                   ,
                c_xx_po_lines_process_rec.contract_id                           ,
                c_xx_po_lines_process_rec.job_id                                ,
                c_xx_po_lines_process_rec.amount                                ,
                c_xx_po_lines_process_rec.job_name                              ,
                c_xx_po_lines_process_rec.contractor_first_name                 ,
                c_xx_po_lines_process_rec.contractor_last_name                  ,
                c_xx_po_lines_process_rec.drop_ship_flag                        ,
                c_xx_po_lines_process_rec.base_unit_price                       ,
                c_xx_po_lines_process_rec.transaction_flow_header_id            ,
                c_xx_po_lines_process_rec.job_business_group_id                 ,
                c_xx_po_lines_process_rec.job_business_group_name               ,
                c_xx_po_lines_process_rec.catalog_name                          ,
                c_xx_po_lines_process_rec.supplier_part_auxid                   ,
                c_xx_po_lines_process_rec.ip_category_id                        ,
                c_xx_po_lines_process_rec.tracking_quantity_ind                 ,
                c_xx_po_lines_process_rec.secondary_default_ind                 ,
                c_xx_po_lines_process_rec.dual_uom_deviation_high               ,
                c_xx_po_lines_process_rec.dual_uom_deviation_low                ,
                c_xx_po_lines_process_rec.processing_id                         ,
                c_xx_po_lines_process_rec.line_loc_populated_flag               ,
                c_xx_po_lines_process_rec.ip_category_name                      ,
                c_xx_po_lines_process_rec.retainage_rate                        ,
                c_xx_po_lines_process_rec.max_retainage_amount                  ,
                c_xx_po_lines_process_rec.progress_payment_rate                 ,
                c_xx_po_lines_process_rec.recoupment_rate                       ,
                c_xx_po_lines_process_rec.advance_amount                        ,
                c_xx_po_lines_process_rec.file_line_number                      ,
                c_xx_po_lines_process_rec.parent_interface_line_id              ,
                c_xx_po_lines_process_rec.file_line_language
            );
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_LINE_LINE_NUM'||c_xx_po_lines_process_rec.line_num);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_DIST_LINE_NUM'||G_DIST_LINE_NUM);
         COMMIT;
        IF UPPER(c_xx_po_headers_process_rec.document_type_code) = 'STANDARD' --added
            THEN
        FOR c_xx_po_dist_process_rec IN c_xx_po_dist_process (xx_emf_cn_pkg.CN_POSTVAL,c_xx_po_headers_process_rec.legacy_po_number,c_xx_po_lines_process_rec.line_num,c_xx_po_lines_process_rec.shipment_num)
         LOOP

             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Inserting Records into Standard Distributions Interface');

             l_int_line_id := po_lines_interface_s.CURRVAL;
             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,l_int_line_id||'- '||c_xx_po_dist_process_rec.line_num||'.'||c_xx_po_dist_process_rec.shipment_num);
             BEGIN
                 select INTERFACE_LINE_LOCATION_ID
                 into l_int_lin_loc_id
                 from po_line_locations_interface
                 where interface_line_id = l_int_line_id
                 and shipment_num = c_xx_po_dist_process_rec.line_num||'.'||c_xx_po_dist_process_rec.shipment_num;
             EXCEPTION
             WHEN OTHERS THEN
                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'ERROR '||SQLERRM);
             END;
             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Line Location ID '||l_int_lin_loc_id);

               insert into po_distributions_interface
                                   ( interface_header_id,
                                     interface_line_id,
                                     INTERFACE_LINE_LOCATION_ID,
                                     interface_distribution_id,
                                     po_header_id,
                                     po_release_id,
                                     po_line_id,
                                     line_location_id,
                                     po_distribution_id,
                                     distribution_num,
                                     source_distribution_id,
                                     org_id,
                                     quantity_ordered,
                                     quantity_delivered,
                                     quantity_billed,
                                     quantity_cancelled,
                                     rate_date,
                                     rate,
                                     deliver_to_location,
                                     deliver_to_location_id,
                                     deliver_to_person_full_name,
                                     deliver_to_person_id,
                                     destination_type,
                                     destination_type_code,
                                     destination_organization,
                                     destination_organization_id,
                                     destination_subinventory,
                                     destination_context,
                                     set_of_books,
                                     set_of_books_id,
                                     charge_account,
                                     charge_account_id,
                                     budget_account,
                                     budget_account_id,
                                     accural_account,
                                     accrual_account_id,
                                     variance_account,
                                     variance_account_id,
                                     amount_billed,
                                     accrue_on_receipt_flag,
                                     accrued_flag,
                                     prevent_encumbrance_flag,
                                     encumbered_flag,
                                     encumbered_amount,
                                     unencumbered_quantity,
                                     unencumbered_amount,
                                     failed_funds,
                                     failed_funds_lookup_code,
                                     gl_encumbered_date,
                                     gl_encumbered_period_name,
                                     gl_cancelled_date,
                                     gl_closed_date,
                                     req_header_reference_num,
                                     req_line_reference_num,
                                     req_distribution_id,
                                     wip_entity,
                                     wip_entity_id,
                                     wip_operation_seq_num,
                                     wip_resource_seq_num,
                                     wip_repetitive_schedule,
                                     wip_repetitive_schedule_id,
                                     wip_line_code,
                                     wip_line_id,
                                     bom_resource_code,
                                     bom_resource_id,
                                     ussgl_transaction_code,
                                     government_context,
                                     project,
                                     project_id,
                                     task,
                                     task_id,
                                     end_item_unit_number,
                                     expenditure,
                                     expenditure_type,
                                     project_accounting_context,
                                     expenditure_organization,
                                     expenditure_organization_id,
                                     project_releated_flag,
                                     expenditure_item_date,
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
                                     last_update_date,
                                     last_updated_by,
                                     last_update_login,
                                     creation_date,
                                     created_by,
                                     request_id,
                                     program_application_id,
                                     program_id,
                                     program_update_date,
                                     recoverable_tax,
                                     nonrecoverable_tax,
                                     recovery_rate,
                                     tax_recovery_override_flag,
                                     award_id,
                                     charge_account_segment1,
                                     charge_account_segment2,
                                     charge_account_segment3,
                                     charge_account_segment4,
                                     charge_account_segment5,
                                     charge_account_segment6,
                                     charge_account_segment7,
                                     charge_account_segment8,
                                     charge_account_segment9,
                                     charge_account_segment10,
                                     charge_account_segment11,
                                     charge_account_segment12,
                                     charge_account_segment13,
                                     charge_account_segment14,
                                     charge_account_segment15,
                                     charge_account_segment16,
                                     charge_account_segment17,
                                     charge_account_segment18,
                                     charge_account_segment19,
                                     charge_account_segment20,
                                     charge_account_segment21,
                                     charge_account_segment22,
                                     charge_account_segment23,
                                     charge_account_segment24,
                                     charge_account_segment25,
                                     charge_account_segment26,
                                     charge_account_segment27,
                                     charge_account_segment28,
                                     charge_account_segment29,
                                     charge_account_segment30,
                                     oke_contract_line_id,
                                     oke_contract_line_num,
                                     oke_contract_deliverable_id,
                                     oke_contract_deliverable_num,
                                     award_number,
                                     amount_ordered,
                                     invoice_adjustment_flag,
                                     dest_charge_account_id,
                                     dest_variance_account_id,
                                     --interface_line_location_id,
                                     processing_id,
                                     process_code,
                                     interface_distribution_ref
                                   )
                     VALUES
                                   ( po_headers_interface_s.CURRVAL,
                                     po_lines_interface_s.CURRVAL,
                                     l_int_lin_loc_id,
                                     po_distributions_interface_s.NEXTVAL,
                                     c_xx_po_dist_process_rec.po_header_id,
                                     c_xx_po_dist_process_rec.po_release_id,
                                     c_xx_po_dist_process_rec.po_line_id,
                                     c_xx_po_dist_process_rec.line_location_id,
                                     c_xx_po_dist_process_rec.po_distribution_id,
                                     c_xx_po_dist_process_rec.distribution_num,
                                     c_xx_po_dist_process_rec.source_distribution_id,
                                     c_xx_po_dist_process_rec.org_id,
                                     c_xx_po_dist_process_rec.quantity_ordered,
                                     c_xx_po_dist_process_rec.quantity_delivered,
                                     c_xx_po_dist_process_rec.quantity_billed,
                                     c_xx_po_dist_process_rec.quantity_cancelled,
                                     c_xx_po_dist_process_rec.rate_date,
                                     c_xx_po_dist_process_rec.rate,
                                     c_xx_po_dist_process_rec.deliver_to_location,
                                     c_xx_po_dist_process_rec.deliver_to_location_id,
                                     c_xx_po_dist_process_rec.deliver_to_person_full_name,
                                     c_xx_po_dist_process_rec.deliver_to_person_id,
                                     c_xx_po_dist_process_rec.destination_type,
                                     c_xx_po_dist_process_rec.destination_type_code,
                                     c_xx_po_dist_process_rec.destination_organization,
                                     c_xx_po_dist_process_rec.destination_organization_id,
                                     c_xx_po_dist_process_rec.destination_subinventory,
                                     c_xx_po_dist_process_rec.destination_context,
                                     c_xx_po_dist_process_rec.set_of_books,
                                     c_xx_po_dist_process_rec.set_of_books_id,
                                     c_xx_po_dist_process_rec.charge_account,
                                     c_xx_po_dist_process_rec.charge_account_id,
                                     c_xx_po_dist_process_rec.budget_account,
                                     c_xx_po_dist_process_rec.budget_account_id,
                                     c_xx_po_dist_process_rec.accural_account,
                                     c_xx_po_dist_process_rec.accrual_account_id,
                                     c_xx_po_dist_process_rec.variance_account,
                                     c_xx_po_dist_process_rec.variance_account_id,
                                     c_xx_po_dist_process_rec.amount_billed,
                                     c_xx_po_dist_process_rec.accrue_on_receipt_flag,
                                     c_xx_po_dist_process_rec.accrued_flag,
                                     c_xx_po_dist_process_rec.prevent_encumbrance_flag,
                                     c_xx_po_dist_process_rec.encumbered_flag,
                                     c_xx_po_dist_process_rec.encumbered_amount,
                                     c_xx_po_dist_process_rec.unencumbered_quantity,
                                     c_xx_po_dist_process_rec.unencumbered_amount,
                                     c_xx_po_dist_process_rec.failed_funds,
                                     c_xx_po_dist_process_rec.failed_funds_lookup_code,
                                     c_xx_po_dist_process_rec.gl_encumbered_date,
                                     c_xx_po_dist_process_rec.gl_encumbered_period_name,
                                     c_xx_po_dist_process_rec.gl_cancelled_date,
                                     c_xx_po_dist_process_rec.gl_closed_date,
                                     c_xx_po_dist_process_rec.req_header_reference_num,
                                     c_xx_po_dist_process_rec.req_line_reference_num,
                                     c_xx_po_dist_process_rec.req_distribution_id,
                                     c_xx_po_dist_process_rec.wip_entity,
                                     c_xx_po_dist_process_rec.wip_entity_id,
                                     c_xx_po_dist_process_rec.wip_operation_seq_num,
                                     c_xx_po_dist_process_rec.wip_resource_seq_num,
                                     c_xx_po_dist_process_rec.wip_repetitive_schedule,
                                     c_xx_po_dist_process_rec.wip_repetitive_schedule_id,
                                     c_xx_po_dist_process_rec.wip_line_code,
                                     c_xx_po_dist_process_rec.wip_line_id,
                                     c_xx_po_dist_process_rec.bom_resource_code,
                                     c_xx_po_dist_process_rec.bom_resource_id,
                                     c_xx_po_dist_process_rec.ussgl_transaction_code,
                                     c_xx_po_dist_process_rec.government_context,
                                     c_xx_po_dist_process_rec.project,
                                     c_xx_po_dist_process_rec.project_id,
                                     c_xx_po_dist_process_rec.task,
                                     c_xx_po_dist_process_rec.task_id,
                                     c_xx_po_dist_process_rec.end_item_unit_number,
                                     c_xx_po_dist_process_rec.expenditure,
                                     c_xx_po_dist_process_rec.expenditure_type,
                                     c_xx_po_dist_process_rec.project_accounting_context,
                                     c_xx_po_dist_process_rec.expenditure_organization,
                                     c_xx_po_dist_process_rec.expenditure_organization_id,
                                     c_xx_po_dist_process_rec.project_releated_flag,
                                     c_xx_po_dist_process_rec.expenditure_item_date,
                                     c_xx_po_dist_process_rec.attribute_category,
                                     c_xx_po_dist_process_rec.attribute1,
                                     c_xx_po_dist_process_rec.attribute2,
                                     c_xx_po_dist_process_rec.attribute3,
                                     c_xx_po_dist_process_rec.attribute4,
                                     c_xx_po_dist_process_rec.attribute5,
                                     c_xx_po_dist_process_rec.attribute6,
                                     c_xx_po_dist_process_rec.attribute7,
                                     c_xx_po_dist_process_rec.attribute8,
                                     c_xx_po_dist_process_rec.attribute9,
                                     c_xx_po_dist_process_rec.attribute10,
                                     c_xx_po_dist_process_rec.attribute11,
                                     c_xx_po_dist_process_rec.attribute12,
                                     c_xx_po_dist_process_rec.attribute13,
                                     c_xx_po_dist_process_rec.attribute14,
                                     c_xx_po_dist_process_rec.attribute15,
                                     c_xx_po_dist_process_rec.last_update_date,
                                     c_xx_po_dist_process_rec.last_updated_by,
                                     c_xx_po_dist_process_rec.last_update_login,
                                     c_xx_po_dist_process_rec.creation_date,
                                     c_xx_po_dist_process_rec.created_by,
                                     c_xx_po_dist_process_rec.request_id,
                                     c_xx_po_dist_process_rec.program_application_id,
                                     c_xx_po_dist_process_rec.program_id,
                                     c_xx_po_dist_process_rec.program_update_date,
                                     c_xx_po_dist_process_rec.recoverable_tax,
                                     c_xx_po_dist_process_rec.nonrecoverable_tax,
                                     c_xx_po_dist_process_rec.recovery_rate,
                                     c_xx_po_dist_process_rec.tax_recovery_override_flag,
                                     c_xx_po_dist_process_rec.award_id,
                                     c_xx_po_dist_process_rec.charge_account_segment1,
                                     c_xx_po_dist_process_rec.charge_account_segment2,
                                     c_xx_po_dist_process_rec.charge_account_segment3,
                                     c_xx_po_dist_process_rec.charge_account_segment4,
                                     c_xx_po_dist_process_rec.charge_account_segment5,
                                     c_xx_po_dist_process_rec.charge_account_segment6,
                                     c_xx_po_dist_process_rec.charge_account_segment7,
                                     c_xx_po_dist_process_rec.charge_account_segment8,
                                     c_xx_po_dist_process_rec.charge_account_segment9,
                                     c_xx_po_dist_process_rec.charge_account_segment10,
                                     c_xx_po_dist_process_rec.charge_account_segment11,
                                     c_xx_po_dist_process_rec.charge_account_segment12,
                                     c_xx_po_dist_process_rec.charge_account_segment13,
                                     c_xx_po_dist_process_rec.charge_account_segment14,
                                     c_xx_po_dist_process_rec.charge_account_segment15,
                                     c_xx_po_dist_process_rec.charge_account_segment16,
                                     c_xx_po_dist_process_rec.charge_account_segment17,
                                     c_xx_po_dist_process_rec.charge_account_segment18,
                                     c_xx_po_dist_process_rec.charge_account_segment19,
                                     c_xx_po_dist_process_rec.charge_account_segment20,
                                     c_xx_po_dist_process_rec.charge_account_segment21,
                                     c_xx_po_dist_process_rec.charge_account_segment22,
                                     c_xx_po_dist_process_rec.charge_account_segment23,
                                     c_xx_po_dist_process_rec.charge_account_segment24,
                                     c_xx_po_dist_process_rec.charge_account_segment25,
                                     c_xx_po_dist_process_rec.charge_account_segment26,
                                     c_xx_po_dist_process_rec.charge_account_segment27,
                                     c_xx_po_dist_process_rec.charge_account_segment28,
                                     c_xx_po_dist_process_rec.charge_account_segment29,
                                     c_xx_po_dist_process_rec.charge_account_segment30,
                                     c_xx_po_dist_process_rec.oke_contract_line_id,
                                     c_xx_po_dist_process_rec.oke_contract_line_num,
                                     c_xx_po_dist_process_rec.oke_contract_deliverable_id,
                                     c_xx_po_dist_process_rec.oke_contract_deliverable_num,
                                     c_xx_po_dist_process_rec.award_number,
                                     c_xx_po_dist_process_rec.amount_ordered,
                                     c_xx_po_dist_process_rec.invoice_adjustment_flag,
                                     c_xx_po_dist_process_rec.dest_charge_account_id,
                                     c_xx_po_dist_process_rec.dest_variance_account_id,
                                     --c_xx_po_dist_process_rec.interface_line_location_id,
                                     c_xx_po_dist_process_rec.processing_id,
                                     c_xx_po_dist_process_rec.process_code,
                                     c_xx_po_dist_process_rec.interface_distribution_ref
                               );
                          G_DIST_LINE_NUM :=c_xx_po_lines_process_rec.line_num;
                          G_DIST_LEGACY_PO_NUMBER := c_xx_po_headers_process_rec.legacy_po_number;
                       ----;
                 END LOOP;
               END IF;
              END LOOP;
            END LOOP;
            COMMIT;
             RETURN x_return_status;
      EXCEPTION
               WHEN OTHERS THEN
                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while inserting into Standard Interface Tables: ' ||SQLERRM);
                   xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
                   x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
                   RETURN x_error_code;

           END process_data;

PROCEDURE print_interface_error_records
    IS
      /*-------------------------------------------------------------------------------------------------------------------------
     Procedure Name   :   print_interface_error_records
     Parameters       :


     Purpose          :   Prints interface error records from interface error table
    -------------------------------------------------------------------------------------------------------------------------*/
        CURSOR c_print_interface_errors
            IS
        SELECT phs.batch_id,
               phs.record_number,
               phs.legacy_po_number,
               pie.error_message
          FROM po_headers_interface phi,
               po_interface_errors pie,
               xx_po_headers_stg phs
         WHERE phi.interface_header_id = pie.interface_header_id
           AND phi.vendor_doc_num = phs.legacy_po_number
           AND phi.attribute11 = phs.batch_id
           AND pie.table_name = 'PO_HEADERS_INTERFACE'
           AND phs.batch_id = G_BATCH_ID
         UNION
        SELECT pls.batch_id,
               pls.record_number,
               pls.legacy_po_number,
               pie.error_message
          FROM po_headers_interface phi,
               po_lines_interface plif,
               po_interface_errors pie,
               xx_po_lines_stg pls
         WHERE phi.interface_header_id = plif.interface_header_id
           AND plif.interface_header_id = pie.interface_header_id
           AND plif.interface_line_id = pie.interface_line_id
           AND phi.vendor_doc_num = pls.legacy_po_number
           AND plif.line_attribute11 = pls.batch_id
           AND plif.line_num = pls.line_num
           AND pie.table_name IN ('PO_LINES_INTERFACE', 'PO_LINE_LOCATIONS_INTERFACE')
           AND pls.batch_id = G_BATCH_ID
         UNION
        SELECT pds.batch_id,
               pds.record_number,
               pds.attribute2,
               pie.error_message
          FROM po_headers_interface phi,
               po_lines_interface plif,
               po_distributions_interface pdi,
               po_interface_errors pie,
               xx_po_distributions_stg pds
         WHERE phi.interface_header_id = plif.interface_header_id
           AND plif.interface_header_id = pdi.interface_header_id
           AND plif.interface_line_id = pdi.interface_line_id
           AND pdi.interface_header_id = pie.interface_header_id
           AND pdi.interface_line_id = pie.interface_line_id
           AND pdi.interface_distribution_id = pie.interface_distribution_id
           AND pdi.attribute2 = pds.attribute2
           AND pdi.attribute11 = pds.batch_id
           AND plif.line_num = pds.line_num
           AND pie.table_name = 'PO_DISTRIBUTIONS_INTERFACE'
           AND pds.batch_id = G_BATCH_ID;
        /*SELECT DISTINCT
               hstg.batch_id,
               hstg.record_number,
               hstg.legacy_po_number,
               pie.error_message
          FROM po_headers_interface phi,
               po_interface_errors pie,
               xx_po_headers_stg hstg
         WHERE 1=1
           AND phi.interface_header_id = pie.interface_header_id
           AND phi.attribute11 = hstg.batch_id
           AND phi.vendor_doc_num = hstg.legacy_po_number
           AND pie.table_name = 'PO_HEADERS_INTERFACE'
           AND hstg.batch_id = G_BATCH_ID
         UNION
        SELECT DISTINCT
               lstg.batch_id,
               lstg.record_number,
               lstg.legacy_po_number,
               pie.error_message
          FROM po_headers_interface phi,
               po_lines_interface plif,
               po_interface_errors pie,
               xx_po_lines_stg lstg
         WHERE phi.interface_header_id = plif.interface_header_id
           AND phi.interface_header_id = pie.interface_header_id
           AND plif.interface_line_id = pie.interface_line_id
           AND plif.line_attribute11 = lstg.batch_id
           AND phi.vendor_doc_num = lstg.legacy_po_number
           AND pie.table_name IN ('PO_LINES_INTERFACE','PO_LINE_LOCATIONS_INTERFACE')
           AND lstg.batch_id = G_BATCH_ID
         UNION
        SELECT DISTINCT
               dstg.batch_id,
               dstg.record_number,
               dstg.attribute2,
               pie.error_message
          FROM po_distributions_interface pdi,
               po_interface_errors pie,
               xx_po_distributions_stg dstg
         WHERE pdi.interface_distribution_id = pie.interface_distribution_id
           AND pdi.attribute11 = dstg.batch_id
           AND pdi.attribute2 = dstg.attribute2
           AND pie.table_name = 'PO_DISTRIBUTIONS_INTERFACE'
           AND dstg.batch_id = G_BATCH_ID;*/


    BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Inside Interface Import Program Errors');
        FOR cur_rec IN c_print_interface_errors
        LOOP

            xx_emf_pkg.error (xx_emf_cn_pkg.CN_LOW,
                              xx_emf_cn_pkg.CN_VALID,
                              cur_rec.error_message,
                              cur_rec.batch_id,
                              cur_rec.record_number,
                              cur_rec.legacy_po_number,
                              G_DOCUMENT_TYPE_CODE);
        END LOOP;
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'End Interface Import Program Errors');
    END print_interface_error_records;

------------------------------------------------------------------------
-----------< update_record_count >--------------------------------------
-------------------------------------------------------------------------

    --- PO Headers Level Record Count ------------
 -------------------------------------------------------------------------------
 /**
 * PROCEDURE update_hdr_record_count
 *
 * DESCRIPTION
 *     PROCEDURE to update header record count.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *   OUT:
 */
-------------------------------------------------------------------------------
    PROCEDURE update_hdr_record_count
    IS
        CURSOR c_get_total_cnt IS
        SELECT COUNT (1) total_count
          FROM xx_po_headers_stg
         WHERE batch_id = G_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID;

        x_total_cnt NUMBER;

        CURSOR c_get_error_cnt IS
        SELECT SUM(error_count)
          FROM (
            SELECT COUNT (1) error_count
              FROM xx_po_headers_stg
             WHERE batch_id   = G_BATCH_ID
               AND request_id = xx_emf_pkg.G_REQUEST_ID
               AND ERROR_CODE = xx_emf_cn_pkg.CN_REC_ERR
            UNION ALL
            SELECT COUNT (1) error_count
              FROM xx_po_headers_pre_int
             WHERE batch_id   = G_BATCH_ID
               AND request_id = xx_emf_pkg.G_REQUEST_ID
               AND ERROR_CODE = xx_emf_cn_pkg.CN_REC_ERR
               );

        x_error_cnt NUMBER;

        CURSOR c_get_warning_cnt IS
        SELECT COUNT (1) warn_count
          FROM xx_po_headers_pre_int
         WHERE batch_id = G_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID
           AND ERROR_CODE = xx_emf_cn_pkg.CN_REC_WARN;

        x_warn_cnt NUMBER;

        CURSOR c_get_success_cnt IS
        SELECT COUNT (1) success_count
          FROM xx_po_headers_pre_int
         WHERE batch_id = G_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID
           AND ((process_code = xx_emf_cn_pkg.CN_PROCESS_DATA AND p_validate_and_load = 'VALIDATE_AND_LOAD')
                OR ((process_code = xx_emf_cn_pkg.CN_DERIVE AND p_validate_and_load = 'VALIDATE_ONLY')))
           AND ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS;

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
        (
            p_total_recs_cnt   => x_total_cnt,
            p_success_recs_cnt => x_success_cnt,
            p_warning_recs_cnt => x_warn_cnt,
            p_error_recs_cnt   => x_error_cnt
        );
    END;

    --- PO Lines Level Record Count ------------
-------------------------------------------------------------------------------
 /**
 * PROCEDURE update_lines_record_count
 *
 * DESCRIPTION
 *     PROCEDURE to update lines record count.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *   OUT:
 */
-------------------------------------------------------------------------------
    PROCEDURE update_lines_record_count
    IS
        CURSOR c_get_total_cnt IS
        SELECT COUNT (1) total_count
          FROM xx_po_lines_stg
         WHERE batch_id = G_LINE_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID;

        x_total_cnt NUMBER;

        CURSOR c_get_error_cnt IS
        SELECT SUM(error_count)
          FROM (
            SELECT COUNT (1) error_count
              FROM xx_po_lines_stg
             WHERE batch_id   = G_LINE_BATCH_ID
               AND request_id = xx_emf_pkg.G_REQUEST_ID
               AND ERROR_CODE = xx_emf_cn_pkg.CN_REC_ERR
            UNION ALL
            SELECT COUNT (1) error_count
              FROM xx_po_lines_pre_int
             WHERE batch_id   = G_LINE_BATCH_ID
               AND request_id = xx_emf_pkg.G_REQUEST_ID
               AND ERROR_CODE = xx_emf_cn_pkg.CN_REC_ERR
               );

        x_error_cnt NUMBER;

        CURSOR c_get_warning_cnt IS
        SELECT COUNT (1) warn_count
          FROM xx_po_lines_pre_int
         WHERE batch_id = G_LINE_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID
           AND ERROR_CODE = xx_emf_cn_pkg.CN_REC_WARN;

        x_warn_cnt NUMBER;

        CURSOR c_get_success_cnt IS
        SELECT COUNT (1) warn_count
          FROM xx_po_lines_pre_int
         WHERE batch_id = G_LINE_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID
           AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
           AND ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS;

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
        (
            p_total_recs_cnt   => x_total_cnt,
            p_success_recs_cnt => x_success_cnt,
            p_warning_recs_cnt => x_warn_cnt,
            p_error_recs_cnt   => x_error_cnt
        );
    END;

    --- PO Distributions Level Record Count ------------
-------------------------------------------------------------------------------
 /**
 * PROCEDURE update_dist_record_count
 *
 * DESCRIPTION
 *     PROCEDURE to update distribution record count.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *   OUT:
 */
-------------------------------------------------------------------------------
    PROCEDURE update_dist_record_count
    IS
        CURSOR c_get_total_cnt IS
        SELECT COUNT (1) total_count
          FROM xx_po_distributions_stg
         WHERE batch_id = G_DIST_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID;

        x_total_cnt NUMBER;

        CURSOR c_get_error_cnt IS
        SELECT SUM(error_count)
          FROM (
            SELECT COUNT (1) error_count
              FROM xx_po_distributions_stg
             WHERE batch_id   = G_DIST_BATCH_ID
               AND request_id = xx_emf_pkg.G_REQUEST_ID
               AND ERROR_CODE = xx_emf_cn_pkg.CN_REC_ERR
            UNION ALL
            SELECT COUNT (1) error_count
              FROM xx_po_distributions_pre_int
             WHERE batch_id   = G_DIST_BATCH_ID
               AND request_id = xx_emf_pkg.G_REQUEST_ID
               AND ERROR_CODE = xx_emf_cn_pkg.CN_REC_ERR
               );

        x_error_cnt NUMBER;

        CURSOR c_get_warning_cnt IS
        SELECT COUNT (1) warn_count
          FROM xx_po_distributions_pre_int
         WHERE batch_id = G_DIST_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID
           AND ERROR_CODE = xx_emf_cn_pkg.CN_REC_WARN;

        x_warn_cnt NUMBER;

        CURSOR c_get_success_cnt IS
        SELECT COUNT (1) warn_count
          FROM xx_po_distributions_pre_int
         WHERE batch_id = G_DIST_BATCH_ID
           AND request_id = xx_emf_pkg.G_REQUEST_ID
           AND process_code_c = xx_emf_cn_pkg.CN_PROCESS_DATA
           AND ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS;

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
        (
            p_total_recs_cnt   => x_total_cnt,
            p_success_recs_cnt => x_success_cnt,
            p_warning_recs_cnt => x_warn_cnt,
            p_error_recs_cnt   => x_error_cnt
        );
    END;

--Line Attachment,

PROCEDURE create_line_attach
     IS
      -------------------------------------------------------------------------------
      /*
      Created By     : IBM Technical Team
      Creation Date  : 11-APRIL-2012
      Filename       :
      Description    : Procedure to create the header level attachment for EDI note.

      Change History:

      Date        Version#    Name                Remarks
      ----------- --------    ---------------     -----------------------------------
      27-May-2012   1.0       IBM Technical Team  Initial development.
      */
      --------------------------------------------------------------------------------
CURSOR comment_line
    IS
    SELECT pla.po_line_id,
           pla.line_num,
           pls.item_description,
           pls.legacy_po_number
      FROM po_headers_all pha,
           po_lines_all pla,
           xx_po_lines_pre_int pls
     WHERE pha.po_header_id = pla.po_header_id
       AND pha.vendor_order_num = pls.legacy_po_number
       AND pla.line_num = SUBSTR(pls.line_num,2)
       AND pla.request_id = pls.request_id
       AND pls.process_code = xx_emf_cn_pkg.CN_PREVAL
       AND pls.batch_id = pla.attribute11
       AND pls.batch_id = g_batch_id
       AND pls.line_num LIKE 'C%'
       AND pls.line_type = 'C';

    l_category_id          NUMBER;
    l_description          fnd_documents_tl.description%TYPE :='PO Line Comment';
    l_seq_num              NUMBER;
    l_data_type_id         NUMBER;
    l_user_id              NUMBER := fnd_profile.VALUE('USER_ID');
    --l_login_id             NUMBER := fnd_profile.VALUE('LOGIN_ID')

 BEGIN

  FOR i IN comment_line
  LOOP
   BEGIN
    ---Get next Attach Sequence Number----
    BEGIN
     SELECT nvl(max(seq_num),0) + 10
       INTO l_seq_num
       FROM fnd_attached_documents
      WHERE pk1_value = i.po_line_id
        AND entity_name = 'PO_LINES';
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
      xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'No Data Found for get sequence number for line num: '||i.line_num||' '|| SQLERRM);
               xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' No Data Found for get sequence number for line num:'
               || i.line_num,
               g_batch_id,
               'Line Num: '||i.line_num,
               i.legacy_po_number,
               Null
            );
     WHEN OTHERS THEN
      xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'When Others for get sequence number for line num: '||i.line_num||' '|| SQLERRM);
               xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' When Others for get sequence number for line num:'
               || i.line_num ||' '||SQLERRM,
               g_batch_id,
               'Line Num: '||i.line_num,
               i.legacy_po_number,
               Null
            );

    END;

    -------Get category_id-----

    BEGIN
     SELECT category_id
      INTO l_category_id
      FROM fnd_document_categories_tl
      WHERE user_name = 'To Supplier'--'Short Text'
      AND language=userenv('lang');
    EXCEPTION
     WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Unable to get While finding category id for line num: ' || i.line_num
            );
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' Unable to get While finding category id for line num:'
               || i.line_num,
               g_batch_id,
               'Line Num: '||i.line_num,
               i.legacy_po_number,
               Null
            );

     WHEN OTHERS THEN
      xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in get While finding category id for line num: '||i.line_num||' '|| SQLERRM);
               xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' Error to get While finding category id for line num:'
               || i.line_num ||' '||SQLERRM,
               g_batch_id,
               'Line Num: '||i.line_num,
               i.legacy_po_number,
               Null
            );
    END;

   ---------Get Datatype_id----

    BEGIN
      SELECT datatype_id
        INTO l_data_type_id
        FROM fnd_document_datatypes
       WHERE name = 'SHORT_TEXT'
         AND language=userenv('lang');
    EXCEPTION
     WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Unable to get While finding datatype id for line num: ' || i.line_num
            );
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' Unable to get While finding datatype id for line num:'
               || i.line_num,
               g_batch_id,
               'Line Num: '||i.line_num,
               i.legacy_po_number,
               Null
            );

     WHEN OTHERS THEN
      xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in get While finding datatype id for line num: '||i.line_num||' '|| SQLERRM);
               xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' Error to get While finding datatype id for line num:'
               || i.line_num ||' '||SQLERRM,
               g_batch_id,
               'Line Num: '||i.line_num,
               i.legacy_po_number,
               Null
            );
    END;

    BEGIN
     fnd_webattch.add_attachment
            ( seq_num                => l_seq_num
             ,category_id            => l_category_id
             ,document_description   => l_description
             ,datatype_id            => l_data_type_id
             ,text                   => i.item_description
             ,file_name              => NULL
             ,url                    => NULL
             ,function_name          => 'PO_POXPOEPO'
             ,entity_name            => 'PO_LINES'
             ,pk1_value              => i.po_line_id
             ,pk2_value              => NULL
             ,pk3_value              => NULL
             ,pk4_value              => NULL
             ,pk5_value              => NULL
             ,media_id               => NULL
             ,user_id                => l_user_id
             ,usage_type             => 'O'
            );
     COMMIT;
    END;

   END;
  END LOOP;
 EXCEPTION
   WHEN others THEN
      xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Execption in create_line_attach procedure: '|| SQLERRM);
               xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' Execption in create_line_attach procedure:'
               ||SQLERRM,
               g_batch_id,
               Null,
               Null,
               Null
            );
 END create_line_attach;
/*
PROCEDURE call_line_attach
 IS
 CURSOR comment_line
    IS
    SELECT pla.po_line_id,
           pla.line_num,
           pls.item_description,
           pls.legacy_po_number
      FROM po_headers_all pha,
           po_lines_all pla,
           xx_po_lines_pre_int pls
     WHERE pha.po_header_id = pla.po_header_id
       AND pha.vendor_order_num = pls.legacy_po_number
       AND pla.line_num = pls.line_num
       AND pla.request_id = pls.request_id
       AND pls.process_code = xx_emf_cn_pkg.CN_PREVAL--'Pre-Validations'
       AND pls.line_type = 'C';

  BEGIN
    FOR i IN comment_line
     LOOP
        create_line_attach( i.po_line_id
                           ,i.item_description
                           ,i.line_num
                           ,i.legacy_po_number);
     END LOOP;
  EXCEPTION
   WHEN others THEN
      xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Execption in call_line_attach procedure: '|| SQLERRM);
      --x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' Execption in call_line_attach procedure:'
               ||SQLERRM,
               g_batch_id,
               Null,
               Null,
               Null
            );
  END call_line_attach;*/
--End Line Attachment

BEGIN
    retcode := xx_emf_cn_pkg.CN_SUCCESS;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Setting Environment');

    -- Hdr level --
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling Hdr Set_cnv_env');
    set_cnv_env (p_batch_id,xx_emf_cn_pkg.CN_YES,'HDR');
    -- Line level --
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling Line Set_cnv_env');
    set_cnv_env (p_batch_id,xx_emf_cn_pkg.CN_YES,'LINE');
    -- Distribution level -- --added
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling Distribution Set_cnv_env');
    set_cnv_env (p_batch_id,xx_emf_cn_pkg.CN_YES,'DIST');

    -- Update Batch Id in Line and Distribution with Header value.... --added
    update_cnv_batch(p_batch_id);
    -- include all the parameters to the conversion main here
    -- as medium log messages
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Starting main process with the following parameters');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_batch_id '    || p_batch_id);
    --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_line_batch_id '    || p_line_batch_id);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_restart_flag '    || p_restart_flag);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_override_flag '    || p_override_flag);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param -  p_acct_mapping_required '    ||  p_acct_mapping_required); -- Added for new CR
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_validate_and_load '    || p_validate_and_load);

    -- Call procedure to update records with the current request_id
    -- So that we can process only those records
    -- This gives a better handling of restartability
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling mark_records_for_processing..');
    mark_records_for_processing(p_restart_flag => p_restart_flag, p_override_flag => p_override_flag);

    -- Once the records are identified based on the input parameters
    -- Start with pre-validations
    IF NVL ( p_override_flag, xx_emf_cn_pkg.CN_NO) = xx_emf_cn_pkg.CN_NO THEN

        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling Set Stage ..');

        -- Set the stage to Pre Validations
        set_stage (xx_emf_cn_pkg.CN_PREVAL);

        -- Change the validations package to the appropriate package name
        -- Modify the parameters as required
        -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
        -- PRE_VALIDATIONS SHOULD BE RETAINED
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling xx_po_cnv_validations_pkg.pre_validations ..');

        x_error_code := xx_po_cnv_validations_pkg.pre_validations ();

        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After pre-validations X_ERROR_CODE ' || X_ERROR_CODE);

        -- Update process code of staging records
        -- Also move the successful records to pre-interface tables
        -- Update Header and Lines Level
        update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS,'HDR');
        update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS,'LINE');
        update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS,'DIST'); --added
        xx_emf_pkg.propagate_error ( x_error_code);

        -- Header Level
        x_error_code := move_rec_pre_hdr_table;
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After move_rec_pre_hdr_table X_ERROR_CODE ' || X_ERROR_CODE);
        xx_emf_pkg.propagate_error ( x_error_code);

        -- Lines Level
        x_error_code := move_rec_pre_lines_table;
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After move_rec_pre_lines_table X_ERROR_CODE ' || X_ERROR_CODE);
        xx_emf_pkg.propagate_error ( x_error_code);


        -- Distributions Level --added
        x_error_code := move_rec_pre_dist_table;
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After move_rec_pre_dist_table X_ERROR_CODE ' || X_ERROR_CODE);
        xx_emf_pkg.propagate_error ( x_error_code);
    END IF;

    /* Added for batch validation */

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Main: Testing');

    -- Once the records are identified based on the input parameters
    -- Start with pre-validations
    -- Set the stage to Pre Validations
    set_stage (xx_emf_cn_pkg.CN_BATCHVAL);

    -- CCID099 changes
    -- Change the validations package to the appropriate package name
    -- Modify the parameters as required
    -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
    -- batch_validations SHOULD BE RETAINED
    --x_error_code := xx_po_cnv_validations_pkg.batch_validations (p_batch_id);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After batch_validations X_ERROR_CODE ' || X_ERROR_CODE);
    xx_emf_pkg.propagate_error ( x_error_code);

    -- Once pre-validations are complete the loop through the pre-interface records
    -- and perform data validations on this table
    -- Set the stage to data Validations
    set_stage (xx_emf_cn_pkg.CN_VALID);

    ---- Header Level Validation -----------------------------------------------------------------
    OPEN c_xx_po_headers_pre ( xx_emf_cn_pkg.CN_PREVAL);
    LOOP
               FETCH c_xx_po_headers_pre
        BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

        FOR i IN 1 .. x_pre_std_hdr_table.COUNT
        LOOP
            BEGIN
                -- Perform header level Base App Validations
                x_error_code := xx_po_cnv_validations_pkg.data_validations_hdr(x_pre_std_hdr_table (i));
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_hdr_table (i).record_number|| ' is ' || x_error_code);
                       update_hdr_record_status (x_pre_std_hdr_table(i), x_error_code);
                mark_records_complete(xx_emf_cn_pkg.CN_VALID,'HDR');
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'After update_hdr_record_status ...');
                                xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
                -- If HIGH error then it will be propagated to the next level
                -- IF the process has to continue maintain it as a medium severity
                WHEN xx_emf_pkg.G_E_REC_ERROR
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.CN_REC_ERR);

                WHEN xx_emf_pkg.G_E_PRC_ERROR
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Process Level Error in Data Validations');
                    update_pre_hdr_int_records ( x_pre_std_hdr_table);
                    RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                WHEN OTHERS
                THEN
                    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_hdr_table (i).record_number);
            END;
        END LOOP;

        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_hdr_table.count ' || x_pre_std_hdr_table.COUNT );

        update_pre_hdr_int_records ( x_pre_std_hdr_table);
        x_pre_std_hdr_table.DELETE;

        EXIT WHEN c_xx_po_headers_pre%NOTFOUND;
    END LOOP;
    --mark_records_complete(xx_emf_cn_pkg.CN_VALID,'HDR');

    IF c_xx_po_headers_pre%ISOPEN THEN
        CLOSE c_xx_po_headers_pre;
    END IF;

    -- Once data-validations are complete the loop through the pre-interface records
    -- and perform data derivations on this table

    -- Set the stage to data derivations
    set_stage (xx_emf_cn_pkg.CN_DERIVE);

    OPEN c_xx_po_headers_pre ( xx_emf_cn_pkg.CN_VALID);
    LOOP
        FETCH c_xx_po_headers_pre
        BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;



        FOR i IN 1 .. x_pre_std_hdr_table.COUNT
        LOOP
            BEGIN


                -- Perform header level Base App Validations
                x_error_code := xx_po_cnv_validations_pkg.data_derivations_hdr (x_pre_std_hdr_table (i));
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_hdr_table (i).record_number|| ' is ' || x_error_code);
                update_hdr_record_status (x_pre_std_hdr_table(i),x_error_code);
                    xx_emf_pkg.propagate_error (x_error_code);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Stage = '||G_STAGE);
                mark_records_complete(xx_emf_cn_pkg.CN_DERIVE,'HDR');
            EXCEPTION
                -- If HIGH error then it will be propagated to the next level
                -- IF the process has to continue maintain it as a medium severity
                WHEN xx_emf_pkg.G_E_REC_ERROR
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.CN_REC_ERR);
                WHEN xx_emf_pkg.G_E_PRC_ERROR
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Process Level Error in Data derivations');
                    update_pre_hdr_int_records ( x_pre_std_hdr_table);
                    RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                WHEN OTHERS
                THEN
                    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_hdr_table (i).record_number);
            END;
        END LOOP;

        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_hdr_table.count ' || x_pre_std_hdr_table.COUNT );

        update_pre_hdr_int_records ( x_pre_std_hdr_table);
        x_pre_std_hdr_table.DELETE;

        EXIT WHEN c_xx_po_headers_pre%NOTFOUND;
    END LOOP;
    --mark_records_complete(xx_emf_cn_pkg.CN_DERIVE,'HDR');

    IF c_xx_po_headers_pre%ISOPEN THEN
        CLOSE c_xx_po_headers_pre;
    END IF;

    -------- PO Line Level Validation ---------------------------------------------------------------------------
  -- Once pre-validations are complete the loop through the pre-interface records
    -- and perform data validations on this table
    -- Set the stage to data Validations
    set_stage (xx_emf_cn_pkg.CN_VALID);

    OPEN c_xx_po_lines_pre (xx_emf_cn_pkg.CN_PREVAL);
    LOOP
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'In the Line level pre interface records loop');

               select count(1)
               into l_cnt
               FROM xx_po_lines_pre_int line
               WHERE batch_id     = G_LINE_BATCH_ID
                  AND request_id   = xx_emf_pkg.G_REQUEST_ID
                  AND process_code = xx_emf_cn_pkg.CN_PREVAL
                  AND ERROR_CODE IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
                  AND line_type <> 'C' --28may2012
                  AND line_num NOT LIKE 'C%';--Added on 19-07-2012

                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Count '||l_cnt);

               FETCH c_xx_po_lines_pre
        BULK COLLECT INTO x_pre_std_line_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Count '||x_pre_std_line_table.COUNT);

        FOR i IN 1 .. x_pre_std_line_table.COUNT
        LOOP
            BEGIN
             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Shipment_Num just after bulk collect_1 '|| x_pre_std_line_table (i).shipment_num);
                   -- Perform Line level Base App Validations
                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling Data Validations for Line Level');
                   x_error_code := xx_po_cnv_validations_pkg.data_validations_line (x_pre_std_line_table (i));
                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_line_table (i).record_number|| ' is ' || x_error_code);
                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'PO Line Level : shipment number is   '|| x_pre_std_line_table (i).shipment_num);
                   update_line_record_status (x_pre_std_line_table (i), x_error_code);
                   mark_records_complete(xx_emf_cn_pkg.CN_VALID,'LINE');
                   xx_emf_pkg.propagate_error (x_error_code);

            EXCEPTION
                -- If HIGH error then it will be propagated to the next level
                -- IF the process has to continue maintain it as a medium severity
                WHEN xx_emf_pkg.G_E_REC_ERROR
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'PO Line Level '||xx_emf_cn_pkg.CN_REC_ERR);

                WHEN xx_emf_pkg.G_E_PRC_ERROR
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'PO Line Level - Process Level Error in Data Validations');

                    update_pre_lines_int_records ( x_pre_std_line_table);

                    RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);

                WHEN OTHERS
                THEN
                    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_line_table (i).record_number);
            END;
        END LOOP;

        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_line_table.count ' || x_pre_std_line_table.COUNT );

        update_pre_lines_int_records (x_pre_std_line_table);


        x_pre_std_line_table.DELETE;

        EXIT WHEN c_xx_po_lines_pre%NOTFOUND;
    END LOOP;
    --mark_records_complete(xx_emf_cn_pkg.CN_VALID,'LINE');

    IF c_xx_po_lines_pre%ISOPEN THEN
        CLOSE c_xx_po_lines_pre;
    END IF;

    -- Once data-validations are complete the loop through the pre-interface records
    -- and perform data derivations on this table

    -- Set the stage to data derivations
    set_stage (xx_emf_cn_pkg.CN_DERIVE);


    OPEN c_xx_po_lines_pre ( xx_emf_cn_pkg.CN_VALID);
    LOOP
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'In the Line level pre interface derivations loop');

        FETCH c_xx_po_lines_pre
        BULK COLLECT INTO x_pre_std_line_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

        FOR i IN 1 .. x_pre_std_line_table.COUNT
        LOOP
            BEGIN
                 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Shipment_Num just after bulk collect_2 '|| x_pre_std_line_table (i).shipment_num);
                -- Perform header level Base App Validations
                x_error_code := xx_po_cnv_validations_pkg.data_derivations_line (x_pre_std_line_table (i));
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'PO Line Level : x_error_code for  '|| x_pre_std_line_table (i).record_number|| ' is ' || x_error_code);
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'PO Line Level : shipment number is   '|| x_pre_std_line_table (i).shipment_num);
        update_line_record_status (x_pre_std_line_table (i), x_error_code);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Stage = '||G_STAGE);
                mark_records_complete(xx_emf_cn_pkg.CN_DERIVE,'LINE');
                xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
                -- If HIGH error then it will be propagated to the next level
                -- IF the process has to continue maintain it as a medium severity
                WHEN xx_emf_pkg.G_E_REC_ERROR
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.CN_REC_ERR);
                WHEN xx_emf_pkg.G_E_PRC_ERROR
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'PO Line Level - Process Level Error in Data derivations');
                    update_pre_lines_int_records ( x_pre_std_line_table);
                    RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                WHEN OTHERS
                THEN
                    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_line_table (i).record_number);
            END;
        END LOOP;


        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'PO Line Level : shipment number is   '|| x_pre_std_line_table (1).shipment_num);
        update_pre_lines_int_records ( x_pre_std_line_table);
        FOR i IN 1 .. x_pre_std_line_table.COUNT
        LOOP
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Shipment_Num just after update_pre_lines_int_records_2  '|| x_pre_std_line_table (i).shipment_num);
        end loop;
        x_pre_std_line_table.DELETE;

        EXIT WHEN c_xx_po_lines_pre%NOTFOUND;
    END LOOP;
    --mark_records_complete(xx_emf_cn_pkg.CN_DERIVE,'LINE');

    IF c_xx_po_lines_pre%ISOPEN THEN
        CLOSE c_xx_po_lines_pre;
    END IF;
--added
    -------- PO Distribution Level Validation ---------------------------------------------------------------------------
  -- Once pre-validations are complete the loop through the pre-interface records
    -- and perform data validations on this table
    -- Set the stage to data Validations
    set_stage (xx_emf_cn_pkg.CN_VALID);

    OPEN c_xx_po_dist_pre (xx_emf_cn_pkg.CN_PREVAL);
    LOOP
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'In the Distribution level pre interface records loop');

               FETCH c_xx_po_dist_pre
        BULK COLLECT INTO x_pre_std_dist_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

        FOR i IN 1 .. x_pre_std_dist_table.COUNT
        LOOP
            BEGIN
                   -- Perform Distribution level Base App Validations
                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling Data Validations for Distribution Level');
                   x_error_code := xx_po_cnv_validations_pkg.data_validations_dist (x_pre_std_dist_table (i),p_acct_mapping_required);
                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_dist_table (i).record_number|| ' is ' || x_error_code);
                   update_dist_record_status (x_pre_std_dist_table (i), x_error_code);
                   mark_records_complete(xx_emf_cn_pkg.CN_VALID,'DIST');
                   xx_emf_pkg.propagate_error (x_error_code);

            EXCEPTION
                -- If HIGH error then it will be propagated to the next level
                -- IF the process has to continue maintain it as a medium severity
                WHEN xx_emf_pkg.G_E_REC_ERROR
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'PO Distribution Level '||xx_emf_cn_pkg.CN_REC_ERR);

                WHEN xx_emf_pkg.G_E_PRC_ERROR
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'PO Distribution Level - Process Level Error in Data Validations');

                    update_pre_dist_int_records ( x_pre_std_dist_table);

                    RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);

                WHEN OTHERS
                THEN
                    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_dist_table (i).record_number);
            END;
        END LOOP;

        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_dist_table.count ' || x_pre_std_dist_table.COUNT );

        update_pre_dist_int_records ( x_pre_std_dist_table);

        x_pre_std_dist_table.DELETE;

        EXIT WHEN c_xx_po_dist_pre%NOTFOUND;
    END LOOP;
    --mark_records_complete(xx_emf_cn_pkg.CN_VALID,'DIST');

    IF c_xx_po_dist_pre%ISOPEN THEN
        CLOSE c_xx_po_dist_pre;
    END IF;

    -- Once data-validations are complete the loop through the pre-interface records
    -- and perform data derivations on this table

    -- Set the stage to data derivations
    set_stage (xx_emf_cn_pkg.CN_DERIVE);

    OPEN c_xx_po_dist_pre ( xx_emf_cn_pkg.CN_VALID);
    LOOP
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'In the Distribution level pre interface derivations loop');

        FETCH c_xx_po_dist_pre
        BULK COLLECT INTO x_pre_std_dist_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

        FOR i IN 1 .. x_pre_std_dist_table.COUNT
        LOOP
            BEGIN

                -- Perform distribution level Base App Validations
                x_error_code := xx_po_cnv_validations_pkg.data_derivations_dist (x_pre_std_dist_table (i));
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'PO Distribution Level : x_error_code for  '|| x_pre_std_dist_table (i).record_number|| ' is ' || x_error_code);
        update_dist_record_status (x_pre_std_dist_table (i), x_error_code);
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Stage = '||G_STAGE);
                mark_records_complete(xx_emf_cn_pkg.CN_DERIVE,'DIST');
                xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
                -- If HIGH error then it will be propagated to the next level
                -- IF the process has to continue maintain it as a medium severity
                WHEN xx_emf_pkg.G_E_REC_ERROR
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.CN_REC_ERR);
                WHEN xx_emf_pkg.G_E_PRC_ERROR
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'PO Distribution Level - Process Level Error in Data derivations');
                    update_pre_dist_int_records ( x_pre_std_dist_table);
                    RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                WHEN OTHERS
                THEN
                    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_pre_std_dist_table (i).record_number);
            END;
        END LOOP;

        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_pre_std_dist_table.count ' || x_pre_std_dist_table.COUNT );

        update_pre_dist_int_records ( x_pre_std_dist_table);
        x_pre_std_dist_table.DELETE;

        EXIT WHEN c_xx_po_dist_pre%NOTFOUND;
    END LOOP;
    --mark_records_complete(xx_emf_cn_pkg.CN_DERIVE,'DIST');

    IF c_xx_po_dist_pre%ISOPEN THEN
        CLOSE c_xx_po_dist_pre;
    END IF;

  -- Perform data derivations and process data only if p_validate_only_flag is set to VALIDATE_AND_LOAD -- Nihar: Added 29-Feb-12
  IF p_validate_and_load = g_validate_and_load THEN
    -- Set the stage to Post Validations
    set_stage (xx_emf_cn_pkg.CN_POSTVAL);

    -- Change the validations package to the appropriate package name
    -- Modify the parameters as required
    -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
    -- PRE_VALIDATIONS SHOULD BE RETAINED

    x_error_code := xx_po_cnv_validations_pkg.post_validations ();
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'PO Line Level => After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
    mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL,'HDR');
    mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL,'LINE');
    mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL,'DIST'); --added
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);
    xx_emf_pkg.propagate_error ( x_error_code);

    -- Set the stage to Process
    set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Before process_data');
    x_error_code := process_data;
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After process_data');
    mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA,'HDR');
    mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA,'LINE');
    mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA,'DIST'); --added
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After Process Data mark_records_complete x_error_code'||x_error_code);
    xx_emf_pkg.propagate_error ( x_error_code);
    submit_standard_po_import;
    --submit_blanket_po_import;
    --Add Line attachments.
    create_line_attach;
   -----------
  END IF; --for validate only flag check -- Nihar: Added 29-Feb-12
    print_interface_error_records;
    update_hdr_record_count;
    --update_lines_record_count;
    --update_dist_record_count; --added
    xx_emf_pkg.create_report;
EXCEPTION
    WHEN xx_emf_pkg.G_E_ENV_NOT_SET THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Checking if this is OK');
         fnd_file.put_line ( fnd_file.output, xx_emf_pkg.CN_ENV_NOT_SET);
         retcode := xx_emf_cn_pkg.CN_REC_ERR;
         xx_emf_pkg.create_report;

    WHEN xx_emf_pkg.G_E_REC_ERROR THEN
         retcode := xx_emf_cn_pkg.CN_REC_ERR;
         xx_emf_pkg.create_report;

    WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
         retcode := xx_emf_cn_pkg.CN_PRC_ERR;
         xx_emf_pkg.create_report;

    WHEN OTHERS THEN
        retcode := xx_emf_cn_pkg.CN_PRC_ERR;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Other Errors '||SQLERRM);
        xx_emf_pkg.create_report;
END main;
END xx_po_conversion_pkg;
/


GRANT EXECUTE ON APPS.XX_PO_CONVERSION_PKG TO INTG_XX_NONHR_RO;
