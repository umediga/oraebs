DROP PACKAGE APPS.XX_INV_TRX_DIST_CNV_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_INV_TRX_DIST_CNV_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 24-FEB-2012
 File Name     : XXARTRXDISTCONV.pks
 Description   : This script creates the specification of the package
		 xx_inv_trx_dist_cnv_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 24-FEB-2012 Sharath Babu        Initial Development
*/
----------------------------------------------------------------------

   G_STAGE         VARCHAR2(2000);
   G_BATCH_ID      VARCHAR2(200);
   --Added for Integra change
   g_validate_and_load VARCHAR2(100) := 'VALIDATE_AND_LOAD';

   PROCEDURE set_cnv_env ( p_batch_id VARCHAR2, p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES);

   PROCEDURE mark_records_for_processing
           (       p_restart_flag IN VARCHAR2,
                   p_override_flag IN VARCHAR2
           );

   PROCEDURE set_stage (p_stage VARCHAR2);

   PROCEDURE update_staging_records(p_error_code VARCHAR2,p_record_number NUMBER);

   PROCEDURE mark_records_complete (p_process_code VARCHAR2);

   FUNCTION process_data RETURN NUMBER;

   TYPE G_XX_AR_CNV_STG_REC_TYPE IS RECORD
        (
	 amount                          NUMBER
	,percent                         NUMBER
	,segment1                        VARCHAR2(25)
	,segment2                        VARCHAR2(25)
	,segment3                        VARCHAR2(25)
	,segment4                        VARCHAR2(25)
	,segment5                        VARCHAR2(25)
	,segment6                        VARCHAR2(25)
	,segment7                        VARCHAR2(25)
	,segment8                        VARCHAR2(25)
	,segment9                        VARCHAR2(25)
	,segment10                       VARCHAR2(25)
	,comments                        VARCHAR2(240)
	,account_class                   VARCHAR2(20)
	,attribute_category              VARCHAR2(30)
	,attribute1                      VARCHAR2(150)
	,attribute2                      VARCHAR2(150)
	,attribute3                      VARCHAR2(150)
	,attribute4                      VARCHAR2(150)
	,attribute5                      VARCHAR2(150)
	,attribute6                      VARCHAR2(150)
	,attribute7                      VARCHAR2(150)
	,attribute8                      VARCHAR2(150)
	,attribute9                      VARCHAR2(150)
	,attribute10                     VARCHAR2(150)
	,acctd_amount                    NUMBER
	,interface_line_context          VARCHAR2(30)
	,interface_line_attribute1       VARCHAR2(150)
	,interface_line_attribute2       VARCHAR2(150)
	,interface_line_attribute3       VARCHAR2(150)
	,interface_line_attribute4       VARCHAR2(150)
	,interface_line_attribute5       VARCHAR2(150)
	,interface_line_attribute6       VARCHAR2(150)
	,interface_line_attribute7       VARCHAR2(150)
	,interface_line_attribute8       VARCHAR2(150)
	,interface_line_attribute9       VARCHAR2(150)
	,interface_line_attribute10      VARCHAR2(150)
	,operating_unit_name             VARCHAR2(240)
	,interim_tax_segment1            VARCHAR2(25)
	,interim_tax_segment2            VARCHAR2(25)
	,interim_tax_segment3            VARCHAR2(25)
	,interim_tax_segment4            VARCHAR2(25)
	,interim_tax_segment5            VARCHAR2(25)
	,interim_tax_segment6            VARCHAR2(25)
	,interim_tax_segment7            VARCHAR2(25)
	,interim_tax_segment8            VARCHAR2(25)
	,interim_tax_segment9            VARCHAR2(25)
	,interim_tax_segment10           VARCHAR2(25)
	,batch_id                        VARCHAR2(200)
	,record_number                   NUMBER
	,process_code                    VARCHAR2(100)
	,error_code                      VARCHAR2(100)
	,created_by                      NUMBER
	,creation_date                   DATE
	,last_update_date                DATE
	,last_updated_by                 NUMBER
	,last_update_login               NUMBER
	,request_id                      NUMBER
	,program_application_id          NUMBER
	,program_id                      NUMBER
	,program_update_date             DATE
       );

   TYPE G_XX_AR_CNV_STG_TAB_TYPE IS TABLE OF G_XX_AR_CNV_STG_REC_TYPE
   INDEX BY BINARY_INTEGER;


   TYPE G_XX_AR_CNV_PRE_STD_REC_TYPE IS RECORD
        (
	 interface_distribution_id              NUMBER(15)
	,interface_line_id                      NUMBER(15)
	,interface_line_context                 VARCHAR2(30)
	,interface_line_attribute1              VARCHAR2(150)
	,interface_line_attribute2              VARCHAR2(150)
	,interface_line_attribute3              VARCHAR2(150)
	,interface_line_attribute4              VARCHAR2(150)
	,interface_line_attribute5              VARCHAR2(150)
	,interface_line_attribute6              VARCHAR2(150)
	,interface_line_attribute7              VARCHAR2(150)
	,interface_line_attribute8              VARCHAR2(150)
	,account_class                          VARCHAR2(20)
	,amount                                 NUMBER
	,percent                                NUMBER
	,interface_status                       VARCHAR2(1)
	,request_id                             NUMBER(15)
	,code_combination_id                    NUMBER(15)
	,segment1                               VARCHAR2(25)
	,segment2                               VARCHAR2(25)
	,segment3                               VARCHAR2(25)
	,segment4                               VARCHAR2(25)
	,segment5                               VARCHAR2(25)
	,segment6                               VARCHAR2(25)
	,segment7                               VARCHAR2(25)
	,segment8                               VARCHAR2(25)
	,segment9                               VARCHAR2(25)
	,segment10                              VARCHAR2(25)
	,segment11                              VARCHAR2(25)
	,segment12                              VARCHAR2(25)
	,segment13                              VARCHAR2(25)
	,segment14                              VARCHAR2(25)
	,segment15                              VARCHAR2(25)
	,segment16                              VARCHAR2(25)
	,segment17                              VARCHAR2(25)
	,segment18                              VARCHAR2(25)
	,segment19                              VARCHAR2(25)
	,segment20                              VARCHAR2(25)
	,segment21                              VARCHAR2(25)
	,segment22                              VARCHAR2(25)
	,segment23                              VARCHAR2(25)
	,segment24                              VARCHAR2(25)
	,segment25                              VARCHAR2(25)
	,segment26                              VARCHAR2(25)
	,segment27                              VARCHAR2(25)
	,segment28                              VARCHAR2(25)
	,segment29                              VARCHAR2(25)
	,segment30                              VARCHAR2(25)
	,comments                               VARCHAR2(240)
	,attribute_category                     VARCHAR2(30)
	,attribute1                             VARCHAR2(150)
	,attribute2                             VARCHAR2(150)
	,attribute3                             VARCHAR2(150)
	,attribute4                             VARCHAR2(150)
	,attribute5                             VARCHAR2(150)
	,attribute6                             VARCHAR2(150)
	,attribute7                             VARCHAR2(150)
	,attribute8                             VARCHAR2(150)
	,attribute9                             VARCHAR2(150)
	,attribute10                            VARCHAR2(150)
	,attribute11                            VARCHAR2(150)
	,attribute12                            VARCHAR2(150)
	,attribute13                            VARCHAR2(150)
	,attribute14                            VARCHAR2(150)
	,attribute15                            VARCHAR2(150)
	,acctd_amount                           NUMBER
	,interface_line_attribute10             VARCHAR2(150)
	,interface_line_attribute11             VARCHAR2(150)
	,interface_line_attribute12             VARCHAR2(150)
	,interface_line_attribute13             VARCHAR2(150)
	,interface_line_attribute14             VARCHAR2(150)
	,interface_line_attribute15             VARCHAR2(150)
	,interface_line_attribute9              VARCHAR2(150)
	,created_by                             NUMBER(15)
	,creation_date                          DATE
	,last_updated_by                        NUMBER(15)
	,last_update_date                       DATE
	,last_update_login                      NUMBER(15)
	,org_id                                 NUMBER(15)
	,interim_tax_ccid                       NUMBER(15)
	,interim_tax_segment1                   VARCHAR2(25)
	,interim_tax_segment2                   VARCHAR2(25)
	,interim_tax_segment3                   VARCHAR2(25)
	,interim_tax_segment4                   VARCHAR2(25)
	,interim_tax_segment5                   VARCHAR2(25)
	,interim_tax_segment6                   VARCHAR2(25)
	,interim_tax_segment7                   VARCHAR2(25)
	,interim_tax_segment8                   VARCHAR2(25)
	,interim_tax_segment9                   VARCHAR2(25)
	,interim_tax_segment10                  VARCHAR2(25)
	,interim_tax_segment11                  VARCHAR2(25)
	,interim_tax_segment12                  VARCHAR2(25)
	,interim_tax_segment13                  VARCHAR2(25)
	,interim_tax_segment14                  VARCHAR2(25)
	,interim_tax_segment15                  VARCHAR2(25)
	,interim_tax_segment16                  VARCHAR2(25)
	,interim_tax_segment17                  VARCHAR2(25)
	,interim_tax_segment18                  VARCHAR2(25)
	,interim_tax_segment19                  VARCHAR2(25)
	,interim_tax_segment20                  VARCHAR2(25)
	,interim_tax_segment21                  VARCHAR2(25)
	,interim_tax_segment22                  VARCHAR2(25)
	,interim_tax_segment23                  VARCHAR2(25)
	,interim_tax_segment24                  VARCHAR2(25)
	,interim_tax_segment25                  VARCHAR2(25)
	,interim_tax_segment26                  VARCHAR2(25)
	,interim_tax_segment27                  VARCHAR2(25)
	,interim_tax_segment28                  VARCHAR2(25)
	,interim_tax_segment29                  VARCHAR2(25)
	,interim_tax_segment30                  VARCHAR2(25)
	,operating_unit_name                    VARCHAR2(50)
	,batch_id                               VARCHAR2(200)
	,record_number                          NUMBER
	,error_code                             NUMBER
	,process_code                           VARCHAR2(50)
	,program_id                             NUMBER
	,program_application_id                 NUMBER
	,program_update_date                    DATE
	,derived_segment7                       VARCHAR2(50)
	,derived_segment6                       VARCHAR2(50)
	,derived_segment5                       VARCHAR2(50)
	,derived_segment4                       VARCHAR2(50)
	,derived_segment3                       VARCHAR2(50)
	,derived_segment2                       VARCHAR2(50)
	,derived_segment1                       VARCHAR2(50)
 	) ;

   TYPE G_XX_AR_CNV_PRE_STD_TAB_TYPE IS TABLE OF G_XX_AR_CNV_PRE_STD_REC_TYPE
   INDEX BY BINARY_INTEGER;

   PROCEDURE main (
                errbuf OUT VARCHAR2,
                retcode OUT VARCHAR2,
                p_batch_id IN VARCHAR2,
                p_restart_flag IN VARCHAR2,
                p_override_flag IN VARCHAR2,
                p_validate_and_load IN VARCHAR2
		);

END  xx_inv_trx_dist_cnv_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_TRX_DIST_CNV_PKG TO INTG_XX_NONHR_RO;
