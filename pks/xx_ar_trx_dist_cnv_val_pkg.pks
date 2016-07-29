DROP PACKAGE APPS.XX_AR_TRX_DIST_CNV_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_TRX_DIST_CNV_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 24-FEB-2012
 File Name     : XXARTRXDISTVAL.pks
 Description   : This script creates the specification of the package
		 xx_ar_trx_dist_cnv_val_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 24-FEB-2012 Sharath Babu        Initial Development
*/
----------------------------------------------------------------------

  /*****************************************************************************************
    Function find_max is used to compare the error code
    Error_Code :  CN_SUCCESS       =  '0';
                  CN_REC_WARN      =  '1';
                  CN_REC_ERR       =  '2';
                  CN_PRC_ERR       =  '3';
    to get the maximum error code by comparing the existing error _code for a specific record
    with the latest error code occured during validation/derivation process for another
    column of the same record , so that once the whole record's columns gets vaidated/derived
    we should get the maximum error  code to indicate the proper error status of it
    Parameter : p_error_code1  --> existing error code in the record
                p_error_code2  --> current error code
		                                 generated for next column validation/derivation
   *****************************************************************************************/
  FUNCTION find_max(p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2 ) RETURN VARCHAR2;

  FUNCTION pre_validations(p_trx_stg_rec IN xx_inv_trx_dist_cnv_pkg.G_XX_AR_CNV_STG_REC_TYPE) RETURN NUMBER;

  FUNCTION  data_validations (p_trx_piface_rec IN OUT xx_inv_trx_dist_cnv_pkg.g_xx_ar_cnv_pre_std_rec_type) RETURN NUMBER;

  FUNCTION  data_derivations (p_trxcnv_preiface_rec IN OUT xx_inv_trx_dist_cnv_pkg.G_XX_AR_CNV_PRE_STD_REC_TYPE ) RETURN NUMBER;

  FUNCTION post_validations RETURN NUMBER;

END xx_ar_trx_dist_cnv_val_pkg;
/


GRANT EXECUTE ON APPS.XX_AR_TRX_DIST_CNV_VAL_PKG TO INTG_XX_NONHR_RO;
