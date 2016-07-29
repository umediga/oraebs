DROP PACKAGE APPS.XX_FASSETS_TAX_CNV_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_FASSETS_TAX_CNV_PKG" 
AS
-----------------------------------------------------------------------------------------------
/*
 Created By     : IBM Development Team

 Creation Date  : 20-Mar-2012
 File Name      : XXFASSTTAXCNV.pks
 Description    : This script creates the Specification of the package xx_fassets_tax_cnv_pkg
 Change History :
 -----------------------------------------------------------------------------------------------
 Date        Name          Remarks
 -----------------------------------------------------------------------------------------------
 20-Sep-10   IBM Development Team  Initial development.
 -----------------------------------------------------------------------------------------------
*/
   G_STAGE                  VARCHAR2(2000);
   G_BATCH_ID               VARCHAR2(200);
   G_VALIDATE_AND_LOAD	VARCHAR2(100) := 'VALIDATE_AND_LOAD';

  ---------Defining Type for stage table---------------------------

  TYPE G_XX_FAASST_TAX_STG_REC IS RECORD (
    asset_number                    	VARCHAR2(15),
    book_type_code 		        VARCHAR2(15),
    adjusted_rate 		        NUMBER      ,
    basic_rate 		        	NUMBER      ,
    bonus_rule 		        	VARCHAR2(30),
    ceiling_name 		        VARCHAR2(30),
    cost 			        NUMBER 	,
    date_placed_in_service 	        DATE 	,
    depreciate_flag 	        	VARCHAR2(3),
    deprn_method_code 	        	VARCHAR2(12),
    deprn_reserve 		        NUMBER 	,
    itc_amount_id 		        NUMBER(15),
    life_in_months 		        NUMBER(4),
    original_cost 		        NUMBER 	,
    production_capacity 	        NUMBER 	,
    prorate_convention_code         	VARCHAR2(10),
    salvage_value 		        NUMBER 	,
    ytd_deprn 		        	NUMBER 	,
    accumulated_deprn	        	NUMBER	,
    posting_status 		        VARCHAR2(15),
    tax_request_id 		        NUMBER(15),
    short_fiscal_year_flag 	        VARCHAR2(3),
    conversion_date 	        	DATE 	,
    original_deprn_start_date       	DATE 	,
    amortize_nbv_flag 	        	VARCHAR2(3),
    amortization_start_date         	DATE 	,
    fully_rsvd_revals_counter       	NUMBER 	,
    reval_amortization_basis        	NUMBER 	,
    reval_ceiling 		        NUMBER 	,
    reval_reserve 		        NUMBER 	,
    unrevalued_cost 	        	NUMBER 	,
    ytd_reval_deprn_expense         	NUMBER 	,
    transaction_name 	        	VARCHAR2(30),
    attribute1 		        	VARCHAR2(150),
    attribute2 		        	VARCHAR2(150),
    attribute3 		        	VARCHAR2(150),
    attribute4 		        	VARCHAR2(150),
    attribute5 		        	VARCHAR2(150),
    attribute6 		        	VARCHAR2(150),
    attribute7 		        	VARCHAR2(150),
    attribute8 		        	VARCHAR2(150),
    attribute9 		        	VARCHAR2(150),
    attribute10 		        VARCHAR2(150),
    attribute11 		        VARCHAR2(150),
    attribute12 		        VARCHAR2(150),
    attribute13 		        VARCHAR2(150),
    attribute14 		        VARCHAR2(150),
    attribute15 		        VARCHAR2(150),
    attribute_category_code         	VARCHAR2(30),
    global_attribute1 	        	VARCHAR2(150),
    global_attribute2 	        	VARCHAR2(150),
    global_attribute3 	        	VARCHAR2(150),
    global_attribute4 	        	VARCHAR2(150),
    global_attribute5 	        	VARCHAR2(150),
    global_attribute6 	        	VARCHAR2(150),
    global_attribute7 	        	VARCHAR2(150),
    global_attribute8 	        	VARCHAR2(150),
    global_attribute9 	        	VARCHAR2(150),
    global_attribute10 	        	VARCHAR2(150),
    global_attribute11 	        	VARCHAR2(150),
    global_attribute12 	        	VARCHAR2(150),
    global_attribute13 	        	VARCHAR2(150),
    global_attribute14 	        	VARCHAR2(150),
    global_attribute15 	        	VARCHAR2(150),
    global_attribute16 	        	VARCHAR2(150),
    global_attribute17 	        	VARCHAR2(150),
    global_attribute18 	       		VARCHAR2(150),
    global_attribute19 	       		VARCHAR2(150),
    global_attribute20 	       		VARCHAR2(150),
    global_attribute_category      	VARCHAR2(30),
    --description				VARCHAR2(400),
    group_asset_id 		       	NUMBER      ,
    batch_id	        		VARCHAR2(200)	,
    record_number			NUMBER       	,
    process_code			VARCHAR2(100)	,
    error_code				VARCHAR2(100)	,
    creation_date			DATE	     	,
    created_by				NUMBER(15)   	,
    last_update_date			DATE         	,
    last_updated_by	        	NUMBER(15)   	,
    last_update_login			NUMBER(15)   	,
    request_id	        		NUMBER(15)   	,
    program_application_id		NUMBER(15)   	,
    program_id	        		NUMBER(15)   	,
    program_update_date			DATE
     );

      TYPE G_XX_FAASST_TAX_CNV_STG_TAB IS TABLE OF G_XX_FAASST_TAX_STG_REC
      INDEX BY BINARY_INTEGER;

      TYPE G_XX_FAASST_TAX_PIFACE_REC IS RECORD (
          asset_number                 		 VARCHAR2(15),
	  book_type_code 			VARCHAR2(15),
	  adjusted_rate 			NUMBER      ,
	  basic_rate 		        	NUMBER      ,
	  bonus_rule 		        	VARCHAR2(30),
	  ceiling_name 		        	VARCHAR2(30),
	  cost 			        	NUMBER 	,
	  date_placed_in_service 		DATE 	,
	  depreciate_flag 	        	VARCHAR2(3),
	  deprn_method_code 	        	VARCHAR2(12),
	  deprn_reserve 			NUMBER 	,
	  itc_amount_id 			NUMBER(15),
	  life_in_months 			NUMBER(4),
	  original_cost 			NUMBER 	,
	  production_capacity 	        	NUMBER 	,
	  prorate_convention_code       	VARCHAR2(10),
	  salvage_value 	        	NUMBER 	,
	  ytd_deprn 		        	NUMBER 	,
	  accumulated_deprn	        	NUMBER	,
	  posting_status 			VARCHAR2(15),
	  tax_request_id 			NUMBER(15),
	  short_fiscal_year_flag 		VARCHAR2(3),
	  conversion_date 	        	DATE 	,
	  original_deprn_start_date     	DATE 	,
	  amortize_nbv_flag 	        	VARCHAR2(3),
	  amortization_start_date       	DATE 	,
	  fully_rsvd_revals_counter     	NUMBER 	,
	  reval_amortization_basis      	NUMBER 	,
	  reval_ceiling 	        	NUMBER 	,
	  reval_reserve 	        	NUMBER 	,
	  unrevalued_cost 	        	NUMBER 	,
	  ytd_reval_deprn_expense       	NUMBER 	,
	  transaction_name 	        	VARCHAR2(30),
	  attribute1 		        	VARCHAR2(150),
	  attribute2 		        	VARCHAR2(150),
	  attribute3 		        	VARCHAR2(150),
	  attribute4 		        	VARCHAR2(150),
	  attribute5 		        	VARCHAR2(150),
	  attribute6 		        	VARCHAR2(150),
	  attribute7 		        	VARCHAR2(150),
	  attribute8 		        	VARCHAR2(150),
	  attribute9 		        	VARCHAR2(150),
	  attribute10 		        	VARCHAR2(150),
	  attribute11 		        	VARCHAR2(150),
	  attribute12 		        	VARCHAR2(150),
	  attribute13 		        	VARCHAR2(150),
	  attribute14 		        	VARCHAR2(150),
	  attribute15 		        	VARCHAR2(150),
	  attribute_category_code       	VARCHAR2(30),
	  global_attribute1 	        	VARCHAR2(150),
	  global_attribute2 	        	VARCHAR2(150),
	  global_attribute3 	        	VARCHAR2(150),
	  global_attribute4 	        	VARCHAR2(150),
	  global_attribute5 	        	VARCHAR2(150),
	  global_attribute6 	        	VARCHAR2(150),
	  global_attribute7 	        	VARCHAR2(150),
	  global_attribute8 	        	VARCHAR2(150),
	  global_attribute9 	        	VARCHAR2(150),
	  global_attribute10 	        	VARCHAR2(150),
	  global_attribute11 	        	VARCHAR2(150),
	  global_attribute12 	        	VARCHAR2(150),
	  global_attribute13 	        	VARCHAR2(150),
	  global_attribute14 	        	VARCHAR2(150),
	  global_attribute15 	        	VARCHAR2(150),
	  global_attribute16 	        	VARCHAR2(150),
	  global_attribute17 	        	VARCHAR2(150),
	  global_attribute18 	       		VARCHAR2(150),
	  global_attribute19 	       		VARCHAR2(150),
	  global_attribute20 	       		VARCHAR2(150),
	  global_attribute_category     	VARCHAR2(30),
	 -- description 				VARCHAR2(400),
	  group_asset_id 			NUMBER      ,
	  batch_id	        		VARCHAR2(200)	,
	  record_number				NUMBER       	,
	  process_code				VARCHAR2(100)	,
	  error_code				VARCHAR2(100)	,
	  creation_date				DATE	     	,
	  created_by				NUMBER(15)   	,
	  last_update_date			DATE         	,
	  last_updated_by	        	NUMBER(15)   	,
	  last_update_login			NUMBER(15)   	,
	  request_id	        		NUMBER(15)   	,
	  program_application_id		NUMBER(15)   	,
	  program_id	        		NUMBER(15)   	,
          program_update_date			DATE
      	  );

      TYPE G_XX_FAASST_TAX_PIFACE_TAB IS TABLE OF G_XX_FAASST_TAX_PIFACE_REC
      INDEX BY BINARY_INTEGER;

  PROCEDURE main (
      errbuf                 OUT      VARCHAR2,
      retcode                OUT      VARCHAR2,
      p_batch_id             IN       VARCHAR2,
      p_restart_flag         IN       VARCHAR2,
      p_override_flag        IN       VARCHAR2,
      p_tax_book             IN       VARCHAR2,
      p_validate_and_load    IN       VARCHAR2           );

   -- Constants defined for version control of all the files of the components --

END xx_fassets_tax_cnv_pkg;
/


GRANT EXECUTE ON APPS.XX_FASSETS_TAX_CNV_PKG TO INTG_XX_NONHR_RO;
