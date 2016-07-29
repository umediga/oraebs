DROP PACKAGE APPS.XX_EMF_CN_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_EMF_CN_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By : IBM Development
 Creation Date : 07-MAR-2012
 File Name  : XXEMFCONST.pks
 File Version   : 2
 Description   : This script creates the specification of the package xx_emf_cn_pkg
 Change History:
 Date        Name       Remarks
 ----------- ----       ---------------------------------------
 07-MAR-2012   IBM Development   Initial development.
*/
----------------------------------------------------------------------
        -- This package will only have specifications and all the constants that will be used by EMF Oracle
        -- implementation will be defined here in this specification.
        CN_SUCCESS                       CONSTANT VARCHAR2 (1)    := '0';
        CN_REC_WARN                      CONSTANT VARCHAR2 (1)    := '1';
        CN_REC_ERR                       CONSTANT VARCHAR2 (1)    := '2';
        CN_PRC_ERR                       CONSTANT VARCHAR2 (1)    := '3';
        --
        CN_ALL_RECS                      CONSTANT VARCHAR2 (7)    := 'ALLRECS';
        CN_ERR_RECS                      CONSTANT VARCHAR2 (7)    := 'ERRRECS';
        --
        CN_BULK_COLLECT                  CONSTANT NUMBER          := 20000;
        --
        CN_OFF                           CONSTANT VARCHAR2 (3)    := 'OFF';
        CN_ON                            CONSTANT VARCHAR2 (2)    := 'ON';
	--
	CN_NEW                           CONSTANT VARCHAR2 (200)  := 'New';
        CN_IN_PROG                       CONSTANT VARCHAR2 (200)  := 'In Progress';
        CN_PREVAL                        CONSTANT VARCHAR2 (200)  := 'Pre-Validations';
        CN_BATCHVAL                      CONSTANT VARCHAR2 (200)  := 'Batch Validations';
        CN_VALID                         CONSTANT VARCHAR2 (200)  := 'Data Validations';
        CN_BATCHDER                      CONSTANT VARCHAR2 (200)  := 'Batch Derivations';
        CN_DERIVE                        CONSTANT VARCHAR2 (200)  := 'Data Derivations';
        CN_POSTVAL                       CONSTANT VARCHAR2 (200)  := 'Post Validations';
        CN_PROCESS_DATA                  CONSTANT VARCHAR2 (200)  := 'Process Data';
	CN_SUBMIT_SUP_REQUEST            CONSTANT VARCHAR2 (200)  := 'Submit Sup Import Request';
        CN_SUBMIT_SUS_REQUEST            CONSTANT VARCHAR2 (200)  := 'Submit Sup Site Import Request';
	CN_COMPLETE                      CONSTANT VARCHAR2 (200)  := 'COMPLETE';
	CN_NORMAL                        CONSTANT VARCHAR2 (200)  := 'NORMAL';
	CN_WARNING                       CONSTANT VARCHAR2 (200)  := 'WARNING';
	--add by srikanth
	CN_DAT_VALID                     CONSTANT VARCHAR2 (200)  := 'INTEGRA_DV001';
	CN_TEST                          CONSTANT VARCHAR2 (200)  := null;

        --
        CN_DBMS                          CONSTANT VARCHAR2 (4)    := 'DBMS';
        CN_LOG                           CONSTANT VARCHAR2 (3)    := 'LOG';
        CN_TABLE                         CONSTANT VARCHAR2 (5)    := 'TABLE';
        CN_TDBMS                         CONSTANT VARCHAR2 (5)    := 'TDBMS';
        CN_TLOG                          CONSTANT VARCHAR2 (4)    := 'TLOG';
        CN_ALL                           CONSTANT VARCHAR2 (3)    := 'ALL';
        CN_OUT                           CONSTANT VARCHAR2 (3)    := 'OUT';
        --
        CN_HIGH                          CONSTANT NUMBER          := 3;
        CN_MEDIUM                        CONSTANT NUMBER          := 2;
        CN_LOW                           CONSTANT NUMBER          := 1;
        --
        CN_YES                           CONSTANT VARCHAR2 (1)    := 'Y';
        CN_NO                            CONSTANT VARCHAR2 (1)    := 'N';
        --
	CN_FALSE                         CONSTANT BOOLEAN         := FALSE ;
        CN_TRUE                          CONSTANT BOOLEAN         := TRUE ;

	CN_DEBUG_PROF                    CONSTANT VARCHAR2 (23)   := 'XX_EMF_DEBUG_TRC_SWITCH';
        --
        CN_EXP_UNHAND                    CONSTANT VARCHAR2 (42)   := 'Unhandled exception in procedure/function ';
        CN_TECH_ERROR                    CONSTANT VARCHAR2 (15)   := 'EMF-TE001';
	CN_ERROR                         CONSTANT VARCHAR2 (7)    := 'ERROR';
	CN_FAILED                        CONSTANT VARCHAR  (7)    := 'FAILED';

	CN_LOGIN_ID                      CONSTANT VARCHAR2 (8)    := 'LOGIN_ID';
	CN_NULL                          CONSTANT VARCHAR2 (2000) := NULL;

	--Constants added for EMPLOYEE CONVERSION

	CN_STRDT_VALID                CONSTANT  VARCHAR2(50) := 'STRDT-DV001';
	CN_STRDT_NULL		      CONSTANT  VARCHAR2(50) := 'Start Date Is Null';
	CN_TITLE_VALID                CONSTANT  VARCHAR2(50) := 'TITLE-DV001' ;
	CN_TITLE_TOOMANY	      CONSTANT  VARCHAR2(50) := 'Title Too_many_rows';
	CN_TITLE_NDTFOUND	      CONSTANT  VARCHAR2(50)	:= 'Title No_data_found';
	CN_TITLE_INVALID	      CONSTANT  VARCHAR2(50)	:= 'Title Invalid';
	CN_GENDR_VALID                CONSTANT  VARCHAR2(50) := 'GENDR-DV001';
	CN_GENDER_MISS		      CONSTANT  VARCHAR2(50) := 'Gender- Missing';
	CN_GENDER_TOOMANY             CONSTANT  VARCHAR2(50) := 'Gender- Too Many Rows';
	CN_GENDER_NODTFOUND	      CONSTANT  VARCHAR2(50) := 'Gender - No Data Found';
	CN_GENDER_INVALID	      CONSTANT  VARCHAR2(50) := 'Gender- Invalid';
	CN_LSTNM_VALID                CONSTANT  VARCHAR2(50) := 'LSTNM-DV001';
	CN_LAST_NAME_NULL             CONSTANT  VARCHAR2(50) := 'Last Name Is Null';
	CN_NATLY_VALID                CONSTANT  VARCHAR2(50) := 'NATLY-DV001';
	CN_NATIONALITY_TOOMANY	      CONSTANT  VARCHAR2(50)	:= 'Nationality - Too Many Rows';
	CN_NATIONALITY_NDTFOUND       CONSTANT  VARCHAR2(50)	:= 'Nationality No Data Found';
	CN_NATIONALITY_INVALID	      CONSTANT  VARCHAR2(50)	:= 'Nationality - Invalid';
	CN_MARTL_VALID                CONSTANT  VARCHAR2(50)    := 'MARTL-DV001';
	CN_MARITAL_TOOMANY	      CONSTANT  VARCHAR2(50)	:= 'Marital Status - Too Many Rows';
	CN_MARITAL_NDTFOUND	      CONSTANT  VARCHAR2(50)	:= 'Marital Status No Found';
	CN_MARITAL_INVALID	      CONSTANT  VARCHAR2(50)	:= 'Marital Status - Invalid';
	CN_OGHDT_VALID                CONSTANT  VARCHAR2(50)    := 'OGHDT-DV001';
	CN_ORIGL_HIREDT_INVALID       CONSTANT  VARCHAR2(50)	:= 'Orig_hire Incorrect';
	CN_EMGEN_VALID                CONSTANT  VARCHAR2(50)    := 'EMGEN-DV001';
	CN_AUTEMP_GEN_NOALLOW         CONSTANT  VARCHAR2(50)	:= 'Emp Auto Generation Not Allowed';
	CN_BUSINESS_GRP_NULL	      CONSTANT  VARCHAR2(50)	:= 'Business Group Is Required';
	CN_AUTOEMP_GEN_TOOMANY        CONSTANT  VARCHAR2(50)	:= 'Emp Generation - Too Many Rows';
	CN_AUTOEMP_GEN_INVALID        CONSTANT  VARCHAR2(50)	:= 'Emp Generation Invalid';
	CN_BUSINESS_GRP_INVALID       CONSTANT  VARCHAR2(50)	:= 'Not Valid Business Group';
	CN_BUSGRP_VALID               CONSTANT  VARCHAR2(50) := 'BUSGRP-DV001';
	CN_BUSINESS_GRP_MISS          CONSTANT  VARCHAR2(50)	:= 'Business Group Missing';
	CN_BUSINESS_GRP_TOOMANY       CONSTANT  VARCHAR2(50)	:= 'Business Group Too Many Rows';
	CN_BUSIGRP_NODTA_FND          CONSTANT  VARCHAR2(50)	:= 'Business Group - No Data Found';
	CN_BUSINESSGOUP_ID_VALID      CONSTANT  VARCHAR2(42) := 'HRBUGID-DV001';
	CN_PERSON_ID_ID_VALID         CONSTANT  VARCHAR2(42) := 'HRPERSONID-DV001';
	CN_ASSIGNMNT_ID_ID_VALID      CONSTANT  VARCHAR2(42) := 'HRASSINGID-DV001';
	CN_BGID_NULL                  CONSTANT  VARCHAR2(50) := 'BUSINESSGOUP ID IS NULL';
	CN_PERSONID_NULL              CONSTANT  VARCHAR2(50) := 'PERSON ID IS NULL';
	CN_ASSIGNMENTID_NULL          CONSTANT  VARCHAR2(50) := 'ASSIGNMENT ID IS NULL';
	CN_EFFECTIVE_DATE_VALID       CONSTANT  VARCHAR2 (42):= 'HRSALEFECTIVEDATE-DV001';
	CN_EFFECTIVEDATE_NULL         CONSTANT  VARCHAR2 (50):= 'EFFECTIVESTARTDATE is NULL';
	CN_PROPOSALREASON_VALID       CONSTANT  VARCHAR2 (42):= 'HRSALPROPOSALREASON-DV001';
	CN_PROPOSALREASON_NULL        CONSTANT  VARCHAR2 (50):= 'PROPOSAL REASON is NULL';
	CN_PERSON_TYPE_VALID          CONSTANT  VARCHAR2(50) := 'PERTYP-DV001';
	CN_PERSON_TYPE_TOOMANY        CONSTANT  VARCHAR2(50) := 'Person Type Too Many';
	CN_PERSON_TYPE_NODTA_FND      CONSTANT  VARCHAR2(50) := 'Person Type Not Exists';
	CN_PERSON_TYPE_INVALID        CONSTANT  VARCHAR2(50) := 'Person Type is invalid';
	CN_EMPNUM_VALID               CONSTANT  VARCHAR2(50) := 'EMPNO-DV001';
	CN_EMPNO_EXISTS               CONSTANT  VARCHAR2(50) := 'Employee already exists.';
	CN_FEDGOV_AFFLID_VALID        CONSTANT  VARCHAR2(50)  := 'AFFLID-DV001';
	CN_FEDGOV_AFFLID_INVALID      CONSTANT  VARCHAR2(50)	:= 'Federal Govt. Affiliation ID Not Equals 13 chars';
	CN_MILSER_ID_VALID            CONSTANT  VARCHAR2(50) := 'MILSERID-DV001';
	CN_MILSER_ID_INVALID          CONSTANT  VARCHAR2(50)	:= 'Military Service ID Not Equals 13 chars';
	CN_PERSON_VALID               CONSTANT VARCHAR2 (50) := 'PERSN-DV001';
	CN_PERSON_MISS                CONSTANT VARCHAR2 (50) := 'Person is missing';
	CN_PERSON_INVALID             CONSTANT VARCHAR2 (50) := 'Person is invalid';
	CN_PERSON_NODATA              CONSTANT VARCHAR2 (50) := 'Person not found';
	CN_PERSON_TOOMANY             CONSTANT VARCHAR2 (50) := 'Person too many';
	CN_SUPERVISOR_VALID           CONSTANT VARCHAR2 (50) := 'SPRVIS-DV001';
	CN_SUPERVISOR_MISS            CONSTANT VARCHAR2 (50) := 'Supervisor is missing';
	CN_SUPERVISOR_INVALID         CONSTANT VARCHAR2 (50) := 'Supervisor is invalid';
	CN_SUPERVISOR_NODATA          CONSTANT VARCHAR2 (50) := 'Supervisor not found';
	CN_SUPERVISOR_TOOMANY         CONSTANT VARCHAR2 (50) := 'Supervisor too many';
	CN_JOB_VALID                  CONSTANT VARCHAR2 (50) := 'JOB-DV001';
	CN_JOB_MISS                   CONSTANT VARCHAR2 (50) := 'Job name is missing';
	CN_JOB_INVALID                CONSTANT VARCHAR2 (50) := 'Job name is invalid';
	CN_JOB_NODATA                 CONSTANT VARCHAR2 (50) := 'Job name not found';
	CN_JOB_TOOMANY                CONSTANT VARCHAR2 (50) := 'Job name too many';
	CN_GRADE_VALID                CONSTANT VARCHAR2 (50) := 'GRADE-DV001';
	CN_GRADE_MISS                 CONSTANT VARCHAR2 (50) := 'Grade name is missing';
	CN_GRADE_INVALID              CONSTANT VARCHAR2 (50) := 'Grade name is invalid';
	CN_GRADE_NODATA               CONSTANT VARCHAR2 (50) := 'Grade name not found';
	CN_GRADE_TOOMANY              CONSTANT VARCHAR2 (50) := 'Grade name too many';
	CN_POSITION_VALID             CONSTANT VARCHAR2 (50) := 'POSIT-DV001';
	CN_POSITION_MISS              CONSTANT VARCHAR2 (50) := 'Position name is missing';
	CN_POSITION_INVALID           CONSTANT VARCHAR2 (50) := 'Position name is invalid';
	CN_POSITION_NODATA            CONSTANT VARCHAR2 (50) := 'Position name not found';
	CN_POSITION_TOOMANY           CONSTANT VARCHAR2 (50) := 'Position name too many';
	CN_LOCATION_VALID             CONSTANT VARCHAR2 (50) := 'LOC-DV001';
	CN_LOCATION_MISS              CONSTANT VARCHAR2 (50) := 'Location name is missing';
	CN_LOCATION_INVALID	      CONSTANT VARCHAR2 (50) := 'Location name is invalid';
	CN_LOCATION_NODATA            CONSTANT VARCHAR2 (50) := 'Location name not found';
	CN_LOCATION_TOOMANY	      CONSTANT VARCHAR2 (50) := 'Location name too many';
	CN_ASSIGNMENT_STATUS_VALID    CONSTANT VARCHAR2 (50) := 'ASGST-DV001';
	CN_ASSIGNMENT_STATUS_MISS     CONSTANT VARCHAR2 (50) := 'Assignment_status is missing';
	CN_ASSIGNMENT_STATUS_INVALID  CONSTANT VARCHAR2 (50) := 'Assignment_status is invalid';
	CN_ASSIGNMENT_STATUS_NODATA   CONSTANT VARCHAR2 (50) := 'Assignment_status not found';
	CN_ASSIGNMENT_STATUS_TOMNY    CONSTANT VARCHAR2 (50) := 'Assignment_status too many';
	CN_SALARY_BASIS_VALID	      CONSTANT VARCHAR2 (50) := 'PYBAS-DV001';
	CN_SALARY_BASIS_ID_MISS	      CONSTANT VARCHAR2 (50) := 'Salary_basis is missing';
	CN_SALARY_BASIS_ID_INVALID    CONSTANT VARCHAR2 (50) := 'Salary_basis is invalid';
	CN_SALARY_BASIS_ID_NODATA     CONSTANT VARCHAR2 (50) := 'Salary_basis not found';
	CN_SALARY_BASIS_ID_TOOMANY    CONSTANT VARCHAR2 (50) := 'Salary_basis too many';
	CN_PAYROLL_VALID              CONSTANT VARCHAR2 (50) := 'PYRLL-DV001';
	CN_PAYROLL_ID_MISS	      CONSTANT VARCHAR2 (50) := 'Payroll is missing';
	CN_PAYROLL_ID_INVALID	      CONSTANT VARCHAR2 (50) := 'Payroll is invalid';
	CN_PAYROLL_ID_NODATA          CONSTANT VARCHAR2 (50) := 'Payroll not found';
	CN_PAYROLL_ID_TOOMANY         CONSTANT VARCHAR2 (50) := 'Payroll too many';
	CN_ORGANIZATION_VALID         CONSTANT VARCHAR2 (50) := 'ORGN-DV001';
	CN_ORGANIZATION_ID_MISS       CONSTANT VARCHAR2 (50) := 'Organization name is missing';
	CN_ORGANIZATION_ID_INVALID    CONSTANT VARCHAR2 (50) := 'Organization name is invalid';
	CN_ORGANIZATION_ID_NODATA     CONSTANT VARCHAR2 (50) := 'Organization name not found';
	CN_ORGANIZATION_ID_TOOMANY    CONSTANT VARCHAR2 (50) := 'Organization name too many';
	CN_TAX_UNIT_VALID	      CONSTANT VARCHAR2 (50) := 'GRE-DV001';
	CN_TAX_UNIT_MISS              CONSTANT VARCHAR2 (50) := 'GRE is missing';
	CN_TAX_UNIT_INVALID	      CONSTANT VARCHAR2 (50) := 'GRE is invalid';
	CN_TAX_UNIT_NODATA	      CONSTANT VARCHAR2 (50) := 'GRE not found';
	CN_TAX_UNIT_TOOMANY	      CONSTANT VARCHAR2 (50) := 'GRE too many';
      CN_LERRESC_NULL                 CONSTANT  VARCHAR2(50) := 'LERRESN-DV001';
      CN_LERREST_NULL                 CONSTANT  VARCHAR2(50) := 'Release Reason is NULL';
      CN_LERRESC_TOO                  CONSTANT  VARCHAR2(50) := 'LERREST-DV001';
      CN_LERREST_TOO                  CONSTANT  VARCHAR2(50) := 'Release reason - Too Many Rows fetched';
      CN_LERRESC_NO                   CONSTANT  VARCHAR2(50) := 'LERRESNO-DV001';
      CN_LERREST_NO                   CONSTANT  VARCHAR2(50) := 'Release reason - No data found';
      CN_LERRESC_IVD                  CONSTANT  VARCHAR2(50) := 'LERRESI-DV001';
      CN_LERREST_IVD                  CONSTANT  VARCHAR2(50) := 'Release reason - Invalid date';
      CN_PERTYPEC_IVD    	      CONSTANT  VARCHAR2(50) := 'PERTYPI-DV001';
      CN_PERTYPET_IVD 	              CONSTANT  VARCHAR2(50) := 'Person Type - Invalid Data';

	-- Added for GL
        CN_PRE_VALID                     CONSTANT VARCHAR  (50)   := 'Pre Validation';
	CN_BATCH_VALID                   CONSTANT VARCHAR  (50)   := 'Batch Validation';
	CN_BATCH_NOT_MATCH 		 CONSTANT VARCHAR  (50)   := 'Bach Not Match';
	CN_CURR_VALID			 CONSTANT VARCHAR  (50)   := 'Currency Validation';
	CN_SOB_VALID			 CONSTANT VARCHAR  (50)   := 'SOB Validation';
	CN_PERIODNAME_VALID		 CONSTANT VARCHAR  (50)   := 'Period Validation';
	CN_PERIODNAME_NULL		 CONSTANT VARCHAR  (50)   := 'Period Is NULL';
	CN_NO_DATA                       CONSTANT VARCHAR (20)    := 'No Data Found';
	CN_JE_SOURCE_VALID                 CONSTANT VARCHAR (30)    := 'JE SOURCE VALIDATION';
	CN_JE_CATEGORY_VALID                 CONSTANT VARCHAR (30)    := 'JE SOURCE CATEGORY';


        -- Added for AP Suppliers
	CN_VENDOR_NAME_VALID             CONSTANT VARCHAR (30)    := 'Vendor Name Validation';
	CN_VENDORNAME_NULL	         CONSTANT VARCHAR (30)    := 'Vendor Name NULL';
	CN_TOO_MANY		         CONSTANT VARCHAR (30)    := 'Too Many Row';
	CN_SHIP_TO_CODE_VALID            CONSTANT VARCHAR (30)    := 'Ship To Code Validation';
	CN_BILL_TO_CODE_VALID            CONSTANT VARCHAR (30)    := 'Bill To Code Validation';
	CN_EMPLOYEE_ID_INVALID           CONSTANT VARCHAR (30)    := 'Invalid Employee ID';
	CN_TERMS_NAME_VALID		 CONSTANT VARCHAR (30)    := 'Payment Terms Validation';
	CN_CURRENCY_CODE_VALID		 CONSTANT VARCHAR (30) 	  := 'Currency Code Validation';
	CN_VENDOR_TYPE_CODE_VALID	 CONSTANT VARCHAR (30)    := 'Vendor Type Code Validation';
	CN_VENDOR_TYPE_LOOKUP_CODE       CONSTANT VARCHAR (30)    := 'VENDOR TYPE' ;--'TBD'
	CN_VENDOR_TYPE_CODE_NULL	 CONSTANT VARCHAR (30)    := 'Vendor Type Code is Null';
	CN_FREIGHT_TERMS_CODE_VALID      CONSTANT VARCHAR (30)    := 'Freight Terms Validation';
	CN_PAY_METHOD_CODE_VALID	 CONSTANT VARCHAR (30)    := 'Pay Method code Validation';
	CN_PAY_GROUP_CODE_VALID 	 CONSTANT VARCHAR (30)    := 'Pay Group code Validation';
	CN_PAYGROUP_LOOKUP_CODE		 CONSTANT VARCHAR (30)    := 'PAY GROUP'; --'TBD';
	CN_PAY_GROUP_CODE_NULL  	 CONSTANT VARCHAR (30)    := 'Pay Group code is NULL';
	CN_FOB_LOOKUP_CODE_VALID	 CONSTANT VARCHAR (30)    := 'FOB Lookup code Validation';
	CN_FOB_LOOKUP_CODE		 CONSTANT VARCHAR (30)    := 'FOB';
	CN_FREIGHT_TERMS_CODE	         CONSTANT VARCHAR (30)    := 'FREIGHT TERMS';
	CN_PAY_METHOD_CODE_NULL		 CONSTANT VARCHAR (30)    := 'Pay Method Code is NULL';
	CN_VENDOR_SITECODE_VALID         CONSTANT VARCHAR (30)    := 'Vendor SiteCode Validation';
	CN_ORG_ID_VALID                  CONSTANT VARCHAR (30)    := 'ORG ID Validation';
	CN_CURRENCY_CODE_NULL            CONSTANT VARCHAR (30)    := 'CCY CODE IS NULL';
	CN_ORG_ID_NULL			 CONSTANT VARCHAR (30)    := 'ORG ID IS NULL';
	CN_VENDOR_ID_VALID		 CONSTANT VARCHAR (30)    := 'Vendor ID Validation';
	CN_PAY_METOHD_LOOKUP_CODE        CONSTANT VARCHAR (30)    := 'PAYMENT METHOD';
	--CN_PAY_METOHD_LOOKUP_CODE        CONSTANT VARCHAR (30)    := 'Pay Method Lookup Validation';
	CN_VENDORID_NULL                 CONSTANT VARCHAR (30)    := 'Vendor ID IS NULL';
	CN_CUSTOMER_NUMBER_VALID         CONSTANT VARCHAR (30)    := 'Customer Number Validation';
	CN_CUSTOMER_NUMBER_NULL          CONSTANT VARCHAR (30)    := 'Customer Number is NULL';
        CN_CUST_TRX_TYPE_VALID	         CONSTANT VARCHAR (30)    := 'CUST TRX Validation';
        CN_CUST_TRX_NULL                 CONSTANT VARCHAR (30)    := 'CUST TRX IS NULL';

        -- Added for AR open invoice , constants yet to assigned
        CN_IFACE_LINE_CONTEXT_VALID      CONSTANT VARCHAR (30)    := 'IFACE CONTEXT VALIDATION';
	CN_IFACE_LINE_CONTEXT_NULL       CONSTANT VARCHAR (30)    := 'LINE CONTEXT IS NULL ';
	CN_IFACE_LINE_ATTRIBUTE1_VALID	 CONSTANT VARCHAR (30)    := 'LINE ATTRIBUTE1 VALIDATION';
	CN_IFACE_LINE_ATTRIBUTE1_NULL	 CONSTANT VARCHAR (30)    := 'LINE ATTRIBUTE1 IS NULL';
	CN_IFACE_LINE_ATTRIBUTE2_VALID   CONSTANT VARCHAR (30)    := 'LINE ATTRIBUTE2 VALIDATION';
	CN_IFACE_LINE_ATTRIBUTE2_NULL    CONSTANT VARCHAR (30)    := 'LINE ATTRIBUTE1 IS NULL';
	CN_TRX_NUMBER_VALID              CONSTANT VARCHAR (30)    := 'CUSTOMER NUMBER VALIDATION';
	CN_TRX_NUMBER_NULL               CONSTANT VARCHAR (30)    := 'TRX NUMBER IS NULL';
        CN_TERM_NAME_VALID	         CONSTANT VARCHAR (30)    := 'TERM NAME VALIDATION';
        CN_TERM_NAME_NULL                CONSTANT VARCHAR (30)    := 'TERM NAME IS NULL';
	CN_CURR_NEXISTS			 CONSTANT VARCHAR (30)    := 'CURRENCY NOT EXISITS';
	CN_CUST_TRX_TYPE_NEXIST		 CONSTANT VARCHAR (30)    := 'TRX TYPE NOT EXISTS';
	CN_CUST_TRX_VALID                CONSTANT VARCHAR (30)    := 'CUST TRX VALIDATION';
	CN_SOB_NULL                      CONSTANT VARCHAR (30)    := 'SOB IS NULL';
	CN_SOB_NEXIST                    CONSTANT VARCHAR (30)    := 'SOB NOT EXISTS';
	CN_ACCTRULE_NAM_VALID            CONSTANT VARCHAR (30)    := 'ACCT RULE NAME VALID';
	CN_TERM_NAME_NEXIS               CONSTANT VARCHAR (30)    := 'TERM NAME NEXIS';
	CN_INVRULE_NAM_VALID             CONSTANT VARCHAR (30)    := 'INVRULE NAME VALID';
	CN_TERM_NAME_NEXIST              CONSTANT VARCHAR (30)    := 'TERM NAME NEXIST';
	CN_CUST_NUM_NEXIST               CONSTANT VARCHAR (30)    := 'CUST NUM NOT EXIST';
	CN_CUST_NUM_VALID                CONSTANT VARCHAR (30)    := 'CUST NUM VALID';
	CN_INVRULE_NAM_NEXIST            CONSTANT VARCHAR (30)    := 'INVRULE NAM NEXISTS';
	---
	---Added By Sushil
	CN_STG_PREVAL                    CONSTANT VARCHAR (11)    := 'PRE-VAL';
	CN_STG_DATAVAL                   CONSTANT VARCHAR (11)    := 'DATA-VAL';
	CN_STG_DATADRV                   CONSTANT VARCHAR (11)    := 'DATA-DERIV';
	CN_STG_POSTVAL                   CONSTANT VARCHAR (11)    := 'POST-VAL';
	CN_STG_APICALL                   CONSTANT VARCHAR (11)    := 'API-ERR';
	CN_OTHERS                        CONSTANT VARCHAR (11)    := 'OTH-EXP';
	CN_EXISTS                        CONSTANT VARCHAR (11)    := 'DATA-EXIST';

	CN_VENDOR_SITE_CODE              CONSTANT VARCHAR2  (50)   :='VENDOR SITE CODE VALIDATION';
	CN_DOCUMENT_TYPE_CODE_VALID      CONSTANT VARCHAR2  (100)   :='DOCUMENT TYPE CODE VALIDATION';
	CN_ITEM_VALID                    CONSTANT VARCHAR2  (100)   :='ITEM VALIDATION';
	CN_ITEM_CATEGORY_VALID           CONSTANT VARCHAR2  (100)   :='ITEM CATEGORY VALIDATION';
	CN_UNIT_OF_MEASURE_VALID         CONSTANT VARCHAR2  (100)   :='UNIT OF MEASURE VALIDATION';
	--
	-- Added by Mahedhar
	CN_CURR_CONV_RATE_VALID          CONSTANT VARCHAR2  (100)   := 'Conversion rate not defined';
	CN_CURR_CONV_TYPE_VALID          CONSTANT VARCHAR2  (100)   := 'Invalid conversion type';

	-- Added by Aniruddha
	CN_LEGACY_ITEM_XREF_LEGACY       CONSTANT VARCHAR2  (20)    := 'Legacy Item Number';
	CN_LEGACY_ITEM_XREF_GTIN         CONSTANT VARCHAR2  (20)    := 'CASE_GTIN';
	CN_LEGACY_ITEM_XREF_MRPN         CONSTANT VARCHAR2  (20)    := 'Legacy MRPN';


END xx_emf_cn_pkg;
/


GRANT EXECUTE ON APPS.XX_EMF_CN_PKG TO INTG_XX_NONHR_RO;
