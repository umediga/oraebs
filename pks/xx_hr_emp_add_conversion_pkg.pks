DROP PACKAGE APPS.XX_HR_EMP_ADD_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_EMP_ADD_CONVERSION_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 3-DEC-2007
 File Name     : XXHRADDCNV.pks
 Description   : This script creates the specification of the package
                 xx_hr_emp_add_conversion_pkg
 Change History:
 Date         Name                Version                  Remarks
 ----------- ------------------    ------  ----------------------------------
 3-DEC-2007   IBM Development                   Initial development.
 16-Jan-2011   Dinesh         1.0          Made changes as per 'Integra' requirements
*/
----------------------------------------------------------------------
G_STAGE         VARCHAR2(2000);
G_BATCH_ID      VARCHAR2(200);
g_validate_flag_for_api boolean := TRUE;

TYPE G_XX_HR_ADD_CNV_HDR_REC_TYPE IS RECORD
        (
	   batch_id                      VARCHAR2(200),
       record_number		         NUMBER,
       unique_id                     VARCHAR2(240), -- Added for INtegra - Dinesh
       process_code		             VARCHAR2(100),
	   error_code                    VARCHAR2(100),
	   request_id                    NUMBER(15),
	   first_name                    VARCHAR2(150),
	   last_name                     VARCHAR2(150),
	   employee_number               VARCHAR2(30),
	   npw_number                    VARCHAR2(30),
	   applicant_number 		 VARCHAR2(30), --Added for Integra
	   business_group_name             VARCHAR2(240),
	   date_of_birth		         DATE,
	--   start_date                    DATE,
	   address_id                    NUMBER(15),
	   business_group_id             NUMBER(15),
	   person_id                     NUMBER(10),
	   date_from                     DATE,
	   primary_flag                  VARCHAR2(30),
	   style                         VARCHAR2(30),
	   address_line1                 VARCHAR2(240),
	   address_line2                 VARCHAR2(240),
	   address_line3                 VARCHAR2(240),
	   address_type                  VARCHAR2(30),
	--   comments                      VARCHAR2(2000),
	   country                       VARCHAR2(60),
	   date_to                       DATE,
	   postal_code                   VARCHAR2(30),
	   region_1                      VARCHAR2(120),
	   region_2                      VARCHAR2(120),
	   region_3                      VARCHAR2(120),
	   --telephone_number_1            VARCHAR2(60),
	   --telephone_number_2            VARCHAR2(60),
	   --telephone_number_3            VARCHAR2(60),
	   town_or_city                  VARCHAR2(30),
	--   add_request_id                NUMBER(15),
	   program_application_id        NUMBER(15),
	   program_id                    NUMBER(15),
	   program_update_date           DATE,
	   addr_attribute_category       VARCHAR2(30),
	   addr_attribute1               VARCHAR2(150),
	   addr_attribute2               VARCHAR2(150),
	   addr_attribute3               VARCHAR2(150),
	   addr_attribute4               VARCHAR2(150),
	   addr_attribute5               VARCHAR2(150),
	   addr_attribute6               VARCHAR2(150),
	   addr_attribute7               VARCHAR2(150),
	   addr_attribute8               VARCHAR2(150),
	   addr_attribute9               VARCHAR2(150),
	   addr_attribute10              VARCHAR2(150),
	   addr_attribute11              VARCHAR2(150),
	   addr_attribute12              VARCHAR2(150),
	   addr_attribute13              VARCHAR2(150),
	   addr_attribute14              VARCHAR2(150),
	   addr_attribute15              VARCHAR2(150),
	   addr_attribute16              VARCHAR2(150),
	   addr_attribute17              VARCHAR2(150),
	   addr_attribute18              VARCHAR2(150),
	   addr_attribute19              VARCHAR2(150),
	   addr_attribute20              VARCHAR2(150),
	   --last_update_date              DATE,
	   --last_updated_by               NUMBER(15),
	  -- last_update_login             NUMBER(15),
	   --created_by                    NUMBER(15),
	   --creation_date                 DATE,
	   object_version_number         NUMBER(9),
	   add_information1             VARCHAR2(150),
	   add_information2             VARCHAR2(150),
	   add_information3             VARCHAR2(150),
	   add_information4             VARCHAR2(150),
	   add_information5             VARCHAR2(150),
	   add_information6             VARCHAR2(150),
	   add_information7             VARCHAR2(150),
	   add_information8             VARCHAR2(150),
	   party_id                      NUMBER(15),
	   derived_locale                VARCHAR2(240)
         --geometry                      sdo_geometry(1),
         );

TYPE G_XX_HR_ADD_CNV_HDR_TAB_TYPE IS TABLE OF G_XX_HR_ADD_CNV_HDR_REC_TYPE
INDEX BY BINARY_INTEGER;


TYPE G_XX_HR_ADD_CNV_PRE_REC_TYPE IS RECORD
        (
	   batch_id                      VARCHAR2(200),
	   record_number		         NUMBER,
	   unique_id                     VARCHAR2(240), -- Added for INtegra - Dinesh
	   process_code		             VARCHAR2(100),
	   error_code                    VARCHAR2(100),
	   request_id                    NUMBER(15),
	   first_name                    VARCHAR2(150),
	   last_name                     VARCHAR2(150),
	   employee_number               VARCHAR2(30),
	   npw_number                    VARCHAR2(30),
	   applicant_number 		 VARCHAR2(30), -- Added for Integra
	   business_group_name             VARCHAR2(240),
	   date_of_birth		         DATE,
	 --  start_date                    DATE,
	   address_id                    NUMBER(15),
	   business_group_id             NUMBER(15),
	   person_id                     NUMBER(10),
	   date_from                     DATE,
	   primary_flag                  VARCHAR2(30),
	   style                         VARCHAR2(30),
	   address_line1                 VARCHAR2(240),
	   address_line2                 VARCHAR2(240),
	   address_line3                 VARCHAR2(240),
	   address_type                  VARCHAR2(30),
	--   comments                      VARCHAR2(2000),
	   country                       VARCHAR2(60),
	   date_to                       DATE,
	   postal_code                   VARCHAR2(30),
	   region_1                      VARCHAR2(120),
	   region_2                      VARCHAR2(120),
	   region_3                      VARCHAR2(120),
	   --telephone_number_1            VARCHAR2(60),
	   --telephone_number_2            VARCHAR2(60),
	   --telephone_number_3            VARCHAR2(60),
	   town_or_city                  VARCHAR2(30),
	 --  add_request_id                NUMBER(15),
	   program_application_id        NUMBER(15),
	   program_id                    NUMBER(15),
	   program_update_date           DATE,
	   addr_attribute_category       VARCHAR2(30),
	   addr_attribute1               VARCHAR2(150),
	   addr_attribute2               VARCHAR2(150),
	   addr_attribute3               VARCHAR2(150),
	   addr_attribute4               VARCHAR2(150),
	   addr_attribute5               VARCHAR2(150),
	   addr_attribute6               VARCHAR2(150),
	   addr_attribute7               VARCHAR2(150),
	   addr_attribute8               VARCHAR2(150),
	   addr_attribute9               VARCHAR2(150),
	   addr_attribute10              VARCHAR2(150),
	   addr_attribute11              VARCHAR2(150),
	   addr_attribute12              VARCHAR2(150),
	   addr_attribute13              VARCHAR2(150),
	   addr_attribute14              VARCHAR2(150),
	   addr_attribute15              VARCHAR2(150),
	   addr_attribute16              VARCHAR2(150),
	   addr_attribute17              VARCHAR2(150),
	   addr_attribute18              VARCHAR2(150),
	   addr_attribute19              VARCHAR2(150),
	   addr_attribute20              VARCHAR2(150),
         --last_update_date              DATE,
         --last_updated_by               NUMBER(15),
         --last_update_login             NUMBER(15),
         --created_by                    NUMBER(15),
         --creation_date                 DATE,
	   object_version_number         NUMBER(9),
	   add_information1             VARCHAR2(150),
	   add_information2             VARCHAR2(150),
	   add_information3             VARCHAR2(150),
	   add_information4             VARCHAR2(150),
	   add_information5             VARCHAR2(150),
	   add_information6             VARCHAR2(150),
	   add_information7             VARCHAR2(150),
	   add_information8             VARCHAR2(150),
	   party_id                      NUMBER(15),
	   derived_locale                VARCHAR2(240)
         --geometry                      sdo_geometry(1),
	   );

TYPE G_XX_HR_ADD_CNV_PRE_TAB_TYPE IS TABLE OF G_XX_HR_ADD_CNV_PRE_REC_TYPE
INDEX BY BINARY_INTEGER;

-- function get_county_from_vertex(p_zip_code in varchar2
--                               ) RETURN VARCHAR2;

procedure get_flex_values(p_style              in            varchar2
			 ,p_country            in            varchar2
                         ,p_addr_attribute1    in            varchar2
                         ,p_address_line1      in out nocopy varchar2
                         ,p_address_line2      in out nocopy varchar2
                         ,p_address_line3      in out nocopy varchar2
                         ,p_postal_code        in out nocopy varchar2
                         ,p_town_or_city       in out nocopy varchar2
                         ,p_region_1           in out nocopy varchar2
                         ,p_region_2           in out nocopy varchar2
                         ,p_region_3           in out nocopy varchar2
                         ,p_add_information1  in out nocopy varchar2
                         ,p_add_information2  in out nocopy varchar2
                         ,p_add_information3  in out nocopy varchar2
                         ,p_add_information4  in out nocopy varchar2
                         ,p_add_information5  in out nocopy varchar2
                         ,p_add_information6  in out nocopy varchar2
                         ,p_add_information7  in out nocopy varchar2
                         ,p_add_information8  in out nocopy varchar2
                         --,p_telephone_number_1 in out nocopy varchar2
                         --,p_telephone_number_2 in out nocopy varchar2
                         --,p_telephone_number_3 in out nocopy varchar2
                         );

PROCEDURE main (
                errbuf           OUT NOCOPY   VARCHAR2,
                retcode          OUT NOCOPY   VARCHAR2,
                p_batch_id       IN           VARCHAR2,
                p_restart_flag   IN           VARCHAR2,
                p_override_flag  IN           VARCHAR2,
				p_validate_and_load IN VARCHAR2
        );

-- Constants defined for version control of all the files of the components
        CN_XXHRADDSTG_TBL              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXHRADDSTG_SYN              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXHRADDPRE_TBL              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXHRADDPRE_SYN              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXHRADDVAL_PKS              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXHRADDVAL_PKB              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXHRADDCNV_PKS              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXHRADDCNV_PKB              CONSTANT VARCHAR2 (6)    := '1.0';

END XX_HR_EMP_ADD_CONVERSION_PKG;
/
