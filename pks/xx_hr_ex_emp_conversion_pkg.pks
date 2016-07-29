DROP PACKAGE APPS.XX_HR_EX_EMP_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_EX_EMP_CONVERSION_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : VASAVI CHAIKAM
 Creation Date : 09-mar-2012
 File Name     : XX_HR_EX_EMP_CNV.pks
 Description   : This script creates the specification of the package
                 xx_hr_emp_conversion_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 30-Oct-2007 IBM Development              Initial Development
 09-Mar-2012 Vasavi Chaikam		Changed as per Integra
 27-Mar-2012 Vasavi             Change implemented for Final_process_date
*/
----------------------------------------------------------------------
   g_stage      	VARCHAR2 (2000);
   g_batch_id   	VARCHAR2 (200);
   g_file1      	VARCHAR2(100):='XX_HR_EX_EMP_STG.tbl';
   g_file2      	VARCHAR2(100):='XX_HR_EX_EMP_PRE.tbl';
   g_file3      	VARCHAR2(100):='XX_HR_EX_EMP_STG.syn';
   g_file4      	VARCHAR2(100):='XX_HR_EX_EMP_PRE.syn';
   g_file5      	VARCHAR2(100):='XX_HR_EX_EMP_CNV.pks';
   g_file6      	VARCHAR2(100):='XX_HR_EX_EMP_CNV.pkb';
   g_file7      	VARCHAR2(100):='XX_HR_EX_EMP_VAL.pks';
   g_file8      	VARCHAR2(100):='XX_HR_EX_EMP_VAL.pkb';
   g_file1_ver      	VARCHAR2(100):='1.0';
   g_file2_ver      	VARCHAR2(100):='1.0';
   g_file3_ver      	VARCHAR2(100):='1.0';
   g_file4_ver      	VARCHAR2(100):='1.0';
   g_file5_ver      	VARCHAR2(100):='1.0';
   g_file6_ver      	VARCHAR2(100):='1.0';
   g_file7_ver      	VARCHAR2(100):='1.0';
   g_file8_ver      	VARCHAR2(100):='1.0';
   g_validate_flag boolean := TRUE;
   g_validate_and_load VARCHAR2(100) := 'VALIDATE_AND_LOAD';
   g_emp_attr_context     CONSTANT per_periods_of_service.attribute_category%TYPE
                                                     := 'Global Data Elements';

/*
TYPE G_XX_HR_EX_CNV_HDR_REC_TYPE IS RECORD
        (
	batch_id                       	VARCHAR2(200),
	record_number			NUMBER       ,
	process_code			VARCHAR2(100),
	error_code                     	VARCHAR2(100),
	request_id                     	NUMBER(15)   ,
	business_group_name		VARCHAR2(60) ,
	last_name                      	VARCHAR2(150),
	sex                            	VARCHAR2(30) ,
	date_employee_data_verified    	DATE         ,
	date_of_birth                  	DATE         ,
	email_address                  	VARCHAR2(240),
	employee_number                	VARCHAR2(30) ,
	expense_check_send_to_address  	VARCHAR2(30) ,
	first_name                     	VARCHAR2(150),
	known_as                       	VARCHAR2(80) ,
	marital_status                 	VARCHAR2(30) ,
	middle_names                   	VARCHAR2(60) ,
	nationality                    	VARCHAR2(30) ,
	national_identifier            	VARCHAR2(30) ,
	previous_last_name             	VARCHAR2(150),
	registered_disabled_flag       	VARCHAR2(30) ,
	title                          	VARCHAR2(30) ,
	attribute_category             	VARCHAR2(30) ,
	attribute1                     	VARCHAR2(150),
	attribute2                     	VARCHAR2(150),
	attribute3                     	VARCHAR2(150),
	attribute4                     	VARCHAR2(150),
	attribute5                     	VARCHAR2(150),
	attribute6                     	VARCHAR2(150),
	attribute7                     	VARCHAR2(150),
	attribute8                     	VARCHAR2(150),
	attribute9                     	VARCHAR2(150),
	attribute10                    	VARCHAR2(150),
	attribute11                    	VARCHAR2(150),
	attribute12                    	VARCHAR2(150),
	attribute13                    	VARCHAR2(150),
	attribute14                    	VARCHAR2(150),
	attribute15                    	VARCHAR2(150),
	attribute16                    	VARCHAR2(150),
	attribute17                    	VARCHAR2(150),
	attribute18                    	VARCHAR2(150),
	attribute19                    	VARCHAR2(150),
	attribute20                    	VARCHAR2(150),
	attribute21                    	VARCHAR2(150),
	attribute22                    	VARCHAR2(150),
	attribute23                    	VARCHAR2(150),
	attribute24                    	VARCHAR2(150),
	attribute25                    	VARCHAR2(150),
	attribute26                    	VARCHAR2(150),
	attribute27                    	VARCHAR2(150),
	attribute28                    	VARCHAR2(150),
	attribute29                    	VARCHAR2(150),
	attribute30                    	VARCHAR2(150),
	per_information1               	VARCHAR2(150),
	per_information2               	VARCHAR2(150),
	per_information3               	VARCHAR2(150),
	per_information4               	VARCHAR2(150),
	per_information5               	VARCHAR2(150),
	per_information6               	VARCHAR2(150),
	per_information7               	VARCHAR2(150),
	per_information8               	VARCHAR2(150),
	per_information9               	VARCHAR2(150),
	per_information10              	VARCHAR2(150),
	per_information11              	VARCHAR2(150),
	per_information12              	VARCHAR2(150),
	per_information13              	VARCHAR2(150),
	per_information14              	VARCHAR2(150),
	per_information15              	VARCHAR2(150),
	per_information16              	VARCHAR2(150),
	per_information17              	VARCHAR2(150),
	per_information18              	VARCHAR2(150),
	per_information19              	VARCHAR2(150),
	per_information20              	VARCHAR2(150),
	per_information21              	VARCHAR2(150),
	per_information22              	VARCHAR2(150),
	per_information23              	VARCHAR2(150),
	per_information24              	VARCHAR2(150),
	per_information25              	VARCHAR2(150),
	per_information26              	VARCHAR2(150),
	per_information27              	VARCHAR2(150),
	per_information28              	VARCHAR2(150),
	per_information29              	VARCHAR2(150),
	per_information30              	VARCHAR2(150),
	date_of_death                  	DATE         ,
	background_check_status        	VARCHAR2(30) ,
	background_date_check          	DATE         ,
	blood_type                     	VARCHAR2(30) ,
	correspondence_language        	VARCHAR2(30) ,
	honors                         	VARCHAR2(45) ,
	internal_location              	VARCHAR2(45) ,
	last_medical_test_by           	VARCHAR2(60) ,
	last_medical_test_date         	DATE         ,
	mailstop                       	VARCHAR2(45) ,
	office_number                  	VARCHAR2(45) ,
	on_military_service            	VARCHAR2(30) ,
	pre_name_adjunct               	VARCHAR2(30) ,
	resume_exists                  	VARCHAR2(30) ,
	resume_last_updated            	DATE         ,
	second_passport_exists         	VARCHAR2(30) ,
	student_status                 	VARCHAR2(30) ,
	work_schedule                  	VARCHAR2(30) ,
	suffix                         	VARCHAR2(30) ,
	benefit_group_name		VARCHAR2(240),
	receipt_of_death_cert_date     	DATE         ,
	coord_ben_med_pln_no           	VARCHAR2(30) ,
	coord_ben_no_cvg_flag          	VARCHAR2(30) ,
	coord_ben_med_ext_er           	VARCHAR2(80) ,
	coord_ben_med_pl_name          	VARCHAR2(80) ,
	coord_ben_med_insr_crr_name    	VARCHAR2(80) ,
	coord_ben_med_insr_crr_ident   	VARCHAR2(80) ,
	coord_ben_med_cvg_strt_dt      	DATE         ,
	coord_ben_med_cvg_end_dt       	DATE         ,
	uses_tobacco_flag              	VARCHAR2(30) ,
	dpdnt_adoption_date            	DATE         ,
	dpdnt_vlntry_svce_flag         	VARCHAR2(30) ,
	original_date_of_hire          	DATE         ,
	town_of_birth                  	VARCHAR2(90) ,
	region_of_birth                	VARCHAR2(90) ,
	country_of_birth               	VARCHAR2(90) ,
	party_id                       	NUMBER(15)   ,
	program_application_id          NUMBER(15)   ,
	program_id                      NUMBER(15)   ,
	program_update_date             DATE         ,
	last_update_date                DATE	     ,
	last_updated_by                 NUMBER(15)   ,
	last_update_login               NUMBER(15)   ,
	created_by                      NUMBER(15)   ,
	creation_date                   DATE         ,
	effective_start_date            DATE   ,
	effective_end_date		DATE   ,
	start_date			DATE   ,
	applicant_number		VARCHAR2(30)   ,
	current_applicant_flag          VARCHAR2(30)   ,
	current_emp_or_apl_flag         VARCHAR2(30)   ,
	current_employee_flag           VARCHAR2(30)   ,
	fast_path_employee		VARCHAR2(30)   ,
	fte_capacity			NUMBER   ,
	full_name			VARCHAR2(240)   ,
	hold_applicant_date_until       DATE   ,
	order_name			VARCHAR2(240)   ,
	projected_start_date            DATE   ,
	rehire_authorizor		VARCHAR2(30)   ,
	rehire_reason			VARCHAR2(60)   ,
	rehire_recommendation           VARCHAR2(30)   ,
	work_telephone			VARCHAR2(60)   ,
	per_information_category        VARCHAR2(30)   ,
	object_version_number           NUMBER   ,
	npw_number			VARCHAR2(30)   ,
	current_npw_flag		VARCHAR2(30)   ,
	global_name			VARCHAR2(240)   ,
	local_name			VARCHAR2(240),
	legislation_cd			VARCHAR2(100),
   	termination_accepted_person    	VARCHAR(200),
   	ppos_date_start 		DATE,
   	ppos_comment		   	VARCHAR2(2000),
   	ppos_request_id                	NUMBER(15),
    	ppos_program_application_id    	NUMBER(15),
   	ppos_program_id                	NUMBER(15),
   	ppos_program_update_date       	DATE,
    	ppos_attribute_category        	VARCHAR2(30),
    	ppos_attribute1                	VARCHAR2(150),
    	ppos_attribute2                	VARCHAR2(150),
    	ppos_attribute3                	VARCHAR2(150),
    	ppos_attribute4                	VARCHAR2(150),
    	ppos_attribute5                	VARCHAR2(150),
    	ppos_attribute6                	VARCHAR2(150),
    	ppos_attribute7                	VARCHAR2(150),
    	ppos_attribute8                	VARCHAR2(150),
    	ppos_attribute9                	VARCHAR2(150),
 --  	ppos_attribute10               	VARCHAR2(150),
  -- 	ppos_attribute11               	VARCHAR2(150),
  ---	ppos_attribute12               	VARCHAR2(150),
  ---	ppos_attribute13               	VARCHAR2(150),
  ---	ppos_attribute14               	VARCHAR2(150),
  ---	ppos_attribute15               	VARCHAR2(150),
 --- 	ppos_attribute16               	VARCHAR2(150),
 --- 	ppos_attribute17               	VARCHAR2(150),
 --- 	ppos_attribute18               	VARCHAR2(150),
 --- 	ppos_attribute19               	VARCHAR2(150),
 --- 	ppos_attribute20               	VARCHAR2(150),
	ppos_last_update_date          	DATE,
  	ppos_last_updated_by           	NUMBER(15),
	ppos_last_update_login         	NUMBER(15),
  	ppos_created_by                	NUMBER(15),
  	ppos_creation_date             	DATE,
  	ppos_object_version_number     	NUMBER(9),
 	ppos_prior_emp_ssp_paid_to     	DATE,
  	ppos_prior_emp_ssp_weeks       	NUMBER,
  	ppos_adjusted_svc_date         	DATE,
    	ppos_pds_information_category  	VARCHAR2(30),
    	ppos_pds_information1          	VARCHAR2(150),
    	ppos_pds_information2          	VARCHAR2(150),
    	ppos_pds_information3          	VARCHAR2(150),
    	ppos_pds_information4          	VARCHAR2(150),
    	ppos_pds_information5          	VARCHAR2(150),
    	ppos_pds_information6          	VARCHAR2(150),
    	ppos_pds_information7          	VARCHAR2(150),
    	ppos_pds_information8          	VARCHAR2(150),
    	ppos_pds_information9          	VARCHAR2(150),
    	ppos_pds_information10         	VARCHAR2(150),
 --  	ppos_pds_information11         	VARCHAR2(150),
  --	ppos_pds_information12         	VARCHAR2(150),
  -- 	ppos_pds_information13         	VARCHAR2(150),
  -- 	ppos_pds_information14         	VARCHAR2(150),
  -- 	ppos_pds_information15         	VARCHAR2(150),
  -- 	ppos_pds_information16         	VARCHAR2(150),
  -- 	ppos_pds_information17         	VARCHAR2(150),
  -- 	ppos_pds_information18         	VARCHAR2(150),
  -- 	ppos_pds_information19         	VARCHAR2(150),
  -- 	ppos_pds_information20         	VARCHAR2(150),
  -- 	ppos_pds_information21         	VARCHAR2(150),
  -- 	ppos_pds_information22         	VARCHAR2(150),
  -- 	ppos_pds_information23         	VARCHAR2(150),
  -- 	ppos_pds_information24         	VARCHAR2(150),
  -- 	ppos_pds_information25         	VARCHAR2(150),
  -- 	ppos_pds_information26         	VARCHAR2(150),
  -- 	ppos_pds_information27         	VARCHAR2(150),
  -- 	ppos_pds_information28         	VARCHAR2(150),
  --  ppos_pds_information29         	VARCHAR2(150)
  ---  ppos_pds_information30         	VARCHAR2(150)
	);
TYPE G_XX_HR_EX_CNV_HDR_TAB_TYPE IS TABLE OF G_XX_HR_EX_CNV_HDR_REC_TYPE
INDEX BY BINARY_INTEGER;
*/

TYPE  G_XX_HR_EX_CNV_PRE_REC_TYPE IS RECORD
        (
	  BUSINESS_GROUP_NAME        VARCHAR2(240 BYTE),
	  BUSINESS_GROUP_ID          NUMBER,
	  EMPLOYEE_NUMBER            VARCHAR2(30 BYTE),
	  PERIOD_OF_SERVICE_ID       NUMBER,
	  PERSON_ID                  NUMBER,
	  PERSON_TYPE_ID             NUMBER(15),
	  LEAVING_REASON             VARCHAR2(100 BYTE),
	  LEAVING_REASON_CODE        VARCHAR2(30 BYTE),
	  ACTUAL_TERMINATION_DATE    DATE,
	  NOTIFIED_TERMINATION_DATE  DATE,
	  FINAL_PROCESS_DATE	     DATE,
	  OBJECT_VERSION_NUMBER      NUMBER,
	  USER_PERSON_TYPE           VARCHAR2(30 BYTE),
	  PERSON_TYPE                VARCHAR2(30 BYTE),
	  UNIQUE_ID                  VARCHAR2(30 BYTE),
	  FIRST_NAME                 VARCHAR2(30 BYTE),
	  LAST_NAME                  VARCHAR2(30 BYTE),
	  TERM_USER_STATUS           VARCHAR2(30 BYTE),
	  ATTRIBUTE1                 VARCHAR2(100 BYTE),
	  ASSIGNMENT_STATUS_TYPE_ID  NUMBER,
	  BATCH_ID                   VARCHAR2(200 BYTE),
	  RECORD_NUMBER              NUMBER,
	  PROCESS_CODE               VARCHAR2(100 BYTE),
	  ERROR_CODE                 VARCHAR2(100 BYTE),
	  REQUEST_ID                 NUMBER
 );

TYPE G_XX_HR_EX_CNV_PRE_TAB_TYPE IS TABLE OF G_XX_HR_EX_CNV_PRE_REC_TYPE
INDEX BY BINARY_INTEGER;

PROCEDURE main (
                errbuf          OUT NOCOPY VARCHAR2,
                retcode         OUT NOCOPY VARCHAR2,
                p_batch_id      IN         VARCHAR2,
                p_restart_flag  IN         VARCHAR2,
                p_override_flag IN         VARCHAR2,
                p_validate_and_load IN VARCHAR2
        );


END XX_HR_EX_EMP_CONVERSION_PKG;
/
