DROP PACKAGE BODY APPS.XX_HR_EMP_ADD_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_EMP_ADD_CONVERSION_PKG" 
AS
--------------------------------------------------------------------------------------------------------------------------------------------------
/*
 Created By     : IBM Development
 Creation Date  : 04-DEC-2007
 File Name      : XXHRADDCNV.pkb
 Description    : This script creates the body of the package xx_hr_emp_add_conversion_pkg
COMMON GUIDELINES REGARDING EMF
--------------------------------------------------------------------------------------------------------------------------------------------------
1. ALL LOW LEVEL EMF MESSAGES CAN BE RETAINED
2. HARD CODING OF EMF MESSAGES ARE ALLOWED IN THE CODE
3. ANY OTHER HARD CODING SHOULD BE DEALT BY CONSTANTS PACKAGE
4. EXCEPTION HANDLING SHOULD BE LEFT AS IS MOST OF THE PLACES UNLESS SPECIFIED
 Change History:
 Date           Name              Version       Remarks
------------- ------------------  -------   ---------------------------------------
 04-DEC-2007   IBM Development               Initial development.
 16-Jan-2012   Dinesh Babuji                 Integra Changes
 24-feb-2012  Arjun.K                        Change to primary_flag before loading to pre interface table
*/
-------------------------------------------------------------------------------------------------------------------------------------------------
   -- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
   -- START RESTRICTIONS
-------------------------------------------------------------------------------
-----------------------< set_cnv_env >-----------------------------------------
-------------------------------------------------------------------------------
   PROCEDURE set_cnv_env (
                          p_batch_id      VARCHAR2,
                          p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES
                         )
   IS
      x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
      G_BATCH_ID := p_batch_id;
      -- Set the environment
      x_error_code := xx_emf_pkg.set_env;
      IF NVL (p_required_flag, xx_emf_cn_pkg.CN_YES) <> xx_emf_cn_pkg.CN_NO
      THEN
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         RAISE xx_emf_pkg.G_E_ENV_NOT_SET;
   END set_cnv_env;
-------------------------------------------------------------------------------
-----------------------< mark_records_for_processing >-------------------------
-------------------------------------------------------------------------------
   PROCEDURE mark_records_for_processing
          (
           p_restart_flag  IN VARCHAR2,
           p_override_flag IN VARCHAR2
          )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

   BEGIN
      -- If the override is set records should not be purged from the pre-interface tables
      IF p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS
      THEN
         IF p_override_flag = xx_emf_cn_pkg.CN_NO
         THEN
            -- purge from pre-interface tables and oracle standard tables
            DELETE FROM xx_hr_emp_add_pre
             WHERE batch_id = G_BATCH_ID;
          UPDATE xx_hr_emp_add_stg
               SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                   error_code   = xx_emf_cn_pkg.CN_NULL,
                   process_code = xx_emf_cn_pkg.CN_NEW
             WHERE batch_id     = G_BATCH_ID;
          ELSE
            UPDATE xx_hr_emp_add_pre
               SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                   error_code   = xx_emf_cn_pkg.CN_SUCCESS,
                   request_id   = xx_emf_pkg.G_REQUEST_ID
             WHERE batch_id     = G_BATCH_ID;
         END IF;
      ELSIF p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS
      THEN
         IF p_override_flag = xx_emf_cn_pkg.CN_NO
         THEN
            -- Update staging table
            UPDATE xx_hr_emp_add_stg
               SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                   error_code   = xx_emf_cn_pkg.CN_NULL,
                   process_code = xx_emf_cn_pkg.CN_NEW
             WHERE batch_id     = G_BATCH_ID
               AND (
                      process_code = xx_emf_cn_pkg.CN_NEW
                      OR (
                          process_code = xx_emf_cn_pkg.CN_PREVAL
                          AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
                          xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                          )
                    );
         END IF;
         -- Update pre-interface table
         -- Scenario 1 Pre-Validation Stage
         UPDATE xx_hr_emp_add_stg a
            SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                error_code   = xx_emf_cn_pkg.CN_NULL,
                process_code = xx_emf_cn_pkg.CN_NEW
          WHERE batch_id     = G_BATCH_ID
            AND EXISTS (
                 SELECT 1
                   FROM xx_hr_emp_add_pre
                  WHERE batch_id     = G_BATCH_ID
                    AND process_code = xx_emf_cn_pkg.CN_PREVAL
                    AND error_code IN (xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR)
                    AND record_number = a.record_number);
         DELETE
           FROM xx_hr_emp_add_pre
          WHERE batch_id     = G_BATCH_ID
            AND process_code = xx_emf_cn_pkg.CN_PREVAL
            AND error_code   IN (xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);
         -- Scenario 2 Data Validation Stage
         UPDATE xx_hr_emp_add_pre
            SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                error_code   = xx_emf_cn_pkg.CN_SUCCESS,
                process_code = xx_emf_cn_pkg.CN_PREVAL
          WHERE batch_id     = G_BATCH_ID
            AND process_code = xx_emf_cn_pkg.CN_VALID
            AND error_code   IN (xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);
         -- Scenario 3 Data Derivation Stage
         UPDATE xx_hr_emp_add_pre
            SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                error_code   = xx_emf_cn_pkg.CN_SUCCESS,
                process_code = xx_emf_cn_pkg.CN_DERIVE
          WHERE batch_id     = G_BATCH_ID
            AND process_code = xx_emf_cn_pkg.CN_DERIVE
            AND error_code   IN (xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);
         -- Scenario 4 Post Validation Stage
         UPDATE xx_hr_emp_add_pre
            SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                error_code   = xx_emf_cn_pkg.CN_SUCCESS,
                process_code = xx_emf_cn_pkg.CN_POSTVAL
          WHERE batch_id     = G_BATCH_ID
            AND process_code = xx_emf_cn_pkg.CN_POSTVAL
            AND error_code   IN (xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR);
         -- Scenario 5 Process Data Stage
         UPDATE xx_hr_emp_add_pre
            SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                error_code   = xx_emf_cn_pkg.CN_SUCCESS,
                process_code = xx_emf_cn_pkg.CN_POSTVAL
          WHERE batch_id     = G_BATCH_ID
            AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
            AND error_code   IN (xx_emf_cn_pkg.CN_NULL, xx_emf_cn_pkg.CN_REC_ERR);
      END IF;
      COMMIT;
	  EXCEPTION
	  WHEN OTHERS THEN
	  fnd_file.Put_line(1, ' Message:'||SQLERRM);
   END mark_records_for_processing;
-------------------------------------------------------------------------------
-----------------------< set_stage >-------------------------------------------
-------------------------------------------------------------------------------
   PROCEDURE set_stage (p_stage VARCHAR2)
   IS
   BEGIN
           G_STAGE := p_stage;
   END set_stage;
-------------------------------------------------------------------------------
-----------------------< update_staging_records >------------------------------
-------------------------------------------------------------------------------
   PROCEDURE update_staging_records (
                                     p_error_code VARCHAR2
                                    )
   IS
      x_last_update_date       DATE   := SYSDATE;
      x_last_updated_by        NUMBER := fnd_global.user_id;
      x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE xx_hr_emp_add_stg
         SET process_code       = G_STAGE,
             error_code         = DECODE (error_code, NULL, p_error_code, error_code),
             last_update_date   = x_last_update_date,
             last_updated_by    = x_last_updated_by,
             last_update_login  = x_last_update_login
       WHERE batch_id           = G_BATCH_ID
         AND request_id         = xx_emf_pkg.G_REQUEST_ID
         AND process_code       = xx_emf_cn_pkg.CN_NEW;
      COMMIT;
   END update_staging_records;
   -- END RESTRICTIONS
-------------------------------------------------------------------------------
-----------------------< get_county_from_vertex >------------------------------
-- this function is now replaced by function get_us_county_from_ora in validation package
-------------------------------------------------------------------------------
-----------------------< get_flex_values >------------------------------
-------------------------------------------------------------------------------
procedure get_flex_values(p_style              in            varchar2 --added for integra
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
--                         ,p_telephone_number_1 in out nocopy varchar2
--                         ,p_telephone_number_2 in out nocopy varchar2
--                         ,p_telephone_number_3 in out nocopy varchar2
                         ) is
  CURSOR c_flex_setup(x_address_style IN varchar2
                     ) IS
  select  application_column_name
    from fnd_descr_flex_column_usages a1
   where application_id                = 800
     and descriptive_flexfield_name    = 'Address Structure'
     and descriptive_flex_context_code = x_address_style
     and enabled_flag = 'Y'
   order by application_column_name  ;
    x_address_style       varchar2(100)  := null;
    x_sqlerrm             varchar2(1000) := null;
    x_address_line1       varchar2(300)  := null;
    x_address_line2       varchar2(300)  := null;
    x_address_line3       varchar2(300)  := null;
    x_postal_code         varchar2(300)  := null;
    x_town_or_city        varchar2(300)  := null;
    x_region_1            varchar2(300)  := null;
    x_region_2            varchar2(300)  := null;
    x_region_3            varchar2(300)  := null;
    x_add_information1   varchar2(300)  := null;
    x_add_information2   varchar2(300)  := null;
    x_add_information3   varchar2(300)  := null;
    x_add_information4   varchar2(300)  := null;
    x_add_information5   varchar2(300)  := null;
    x_add_information6   varchar2(300)  := null;
    x_add_information7   varchar2(300)  := null;
    x_add_information8   varchar2(300)  := null;
--    x_telephone_number_1  varchar2(300)  := null;
--    x_telephone_number_2  varchar2(300)  := null;
--    x_telephone_number_3  varchar2(300)  := null;
BEGIN

    x_address_style := p_style; --xx_hr_common_pkg.get_mapping_value('ADDRESS_STYLE', p_country); ----- Change for integra.


  FOR r_flex_setup IN c_flex_setup(x_address_style)
  LOOP
    if    r_flex_setup.application_column_name = 'ADDRESS_LINE1' then
        x_address_line1        :=  p_address_line1;
    elsif r_flex_setup.application_column_name = 'ADDRESS_LINE2' then
        x_address_line2        :=  p_address_line2;
    elsif r_flex_setup.application_column_name = 'ADDRESS_LINE3' then
        x_address_line3        :=  p_address_line3;
    elsif r_flex_setup.application_column_name = 'POSTAL_CODE' then
        x_postal_code          :=  p_postal_code;
    elsif r_flex_setup.application_column_name = 'TOWN_OR_CITY' then
        x_town_or_city         :=  p_town_or_city;
    elsif r_flex_setup.application_column_name = 'REGION_1' then
        x_region_1             :=  p_region_1;
    elsif r_flex_setup.application_column_name = 'REGION_2' then
        x_region_2             :=  p_region_2;
    elsif r_flex_setup.application_column_name = 'REGION_3' then
        x_region_3             :=  p_region_3;
    elsif r_flex_setup.application_column_name = 'ADD_INFORMATION1' then
        x_add_information1        :=  p_add_information1;
    elsif r_flex_setup.application_column_name = 'ADD_INFORMATION2' then
        x_add_information2        :=  p_add_information2;
    elsif r_flex_setup.application_column_name = 'ADD_INFORMATION3' then
        x_add_information3        :=  p_add_information3;
    elsif r_flex_setup.application_column_name = 'ADD_INFORMATION4' then
        x_add_information4        :=  p_add_information4;
    elsif r_flex_setup.application_column_name = 'ADD_INFORMATION5' then
        x_add_information5        :=  p_add_information5;
    elsif r_flex_setup.application_column_name = 'ADD_INFORMATION6' then
        x_add_information6        :=  p_add_information6;
    elsif r_flex_setup.application_column_name = 'ADD_INFORMATION7' then
        x_add_information7        :=  p_add_information7;
    elsif r_flex_setup.application_column_name = 'ADD_INFORMATION8' then
        x_add_information8        :=  p_add_information8;
 --   elsif r_flex_setup.application_column_name = 'TELEPHONE_NUMBER_1' then
 --       x_telephone_number_1       :=  p_telephone_number_1;
 --   elsif r_flex_setup.application_column_name = 'TELEPHONE_NUMBER_2' then
 --       x_telephone_number_2       :=  p_telephone_number_2;
 --   elsif r_flex_setup.application_column_name = 'TELEPHONE_NUMBER_3' then
 --       x_telephone_number_3       :=  p_telephone_number_3;
    end if;
  END LOOP;
    -- if flex value is found in cursor pass that value or pass initialized value (null)
    p_address_line1         :=  x_address_line1;
    p_address_line2         :=  x_address_line2;
    p_address_line3         :=  x_address_line3;
    p_postal_code           :=  x_postal_code;
    p_town_or_city          :=  x_town_or_city;
    p_region_1              :=  x_region_1;
    p_region_2              :=  x_region_2;
    p_region_3              :=  x_region_3;
    p_add_information1     :=  x_add_information1;
    p_add_information2     :=  x_add_information2;
    p_add_information3     :=  x_add_information3;
    p_add_information4     :=  x_add_information4;
    p_add_information5     :=  x_add_information5;
    p_add_information6     :=  x_add_information6;
    p_add_information7     :=  x_add_information7;
    p_add_information8     :=  x_add_information8;
--    p_telephone_number_1    :=  x_telephone_number_1;
--    p_telephone_number_2    :=  x_telephone_number_2;
--    p_telephone_number_3    :=  x_telephone_number_3;
EXCEPTION
   WHEN OTHERS THEN
     x_sqlerrm    := substr(sqlerrm,1,800);
     p_address_line1         :=  x_address_line1;
     p_address_line2         :=  x_address_line2;
     p_address_line3         :=  x_address_line3;
     p_postal_code           :=  x_postal_code;
     p_town_or_city          :=  x_town_or_city;
     p_region_1              :=  x_region_1;
     p_region_2              :=  x_region_2;
     p_region_3              :=  x_region_3;
     p_add_information1     :=  x_add_information1;
     p_add_information2     :=  x_add_information2;
     p_add_information3     :=  x_add_information3;
     p_add_information4     :=  x_add_information4;
     p_add_information5     :=  x_add_information5;
     p_add_information6     :=  x_add_information6;
     p_add_information7     :=  x_add_information7;
     p_add_information8     :=  x_add_information8;
--     p_telephone_number_1    :=  x_telephone_number_1;
--     p_telephone_number_2    :=  x_telephone_number_2;
--     p_telephone_number_3    :=  x_telephone_number_3;
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in get_flex_values:' || x_sqlerrm);
end get_flex_values;
-------------------------------------------------------------------------------
-----------------------< main >------------------------------------------------
-------------------------------------------------------------------------------
   PROCEDURE main (
                   errbuf          OUT NOCOPY VARCHAR2,
                   retcode         OUT NOCOPY VARCHAR2,
                   p_batch_id      IN         VARCHAR2,
                   p_restart_flag  IN         VARCHAR2,
                   p_override_flag IN         VARCHAR2,
                   p_validate_and_load       IN VARCHAR2

                   )
   IS
      x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_pre_std_hdr_table     G_XX_HR_ADD_CNV_PRE_TAB_TYPE;  --changed



      -- CURSOR FOR VARIOUS STAGES
      CURSOR c_xx_pre_std_hdr (
                                   cp_process_status VARCHAR2
                                  )
      IS
      SELECT
            batch_id                          ,
	        record_number		      ,
	        unique_id		      , -- Added for Integra- Dinesh
	        process_code		      ,
	        error_code                    ,
	        request_id                    ,
	        first_name                    ,
	        last_name                     ,
	        employee_number               ,
	        npw_number                    ,
	        applicant_number	      ,
	        business_group_name           ,
	        date_of_birth		      ,
	        address_id                    ,
	        business_group_id             ,
	        person_id                     ,
	        date_from                     ,
	        primary_flag                  ,
	        style                         ,
	        address_line1                 ,
	        address_line2                 ,
	        address_line3                 ,
	        address_type                  ,
	        country                       ,
	        date_to                       ,
	        postal_code                   ,
	        region_1                      ,
	        region_2                      ,
	        region_3                      ,
	        --telephone_number_1            ,
	        --telephone_number_2            ,
	        --telephone_number_3            ,
	        town_or_city                  ,
	        program_application_id        ,
	        program_id                    ,
	        program_update_date           ,
	        addr_attribute_category       ,
	        addr_attribute1               ,
	        addr_attribute2               ,
	        addr_attribute3               ,
	        addr_attribute4               ,
	        addr_attribute5               ,
	        addr_attribute6               ,
	        addr_attribute7               ,
	        addr_attribute8               ,
	        addr_attribute9               ,
	        addr_attribute10              ,
	        addr_attribute11              ,
	        addr_attribute12              ,
	        addr_attribute13              ,
	        addr_attribute14              ,
	        addr_attribute15              ,
	        addr_attribute16              ,
	        addr_attribute17              ,
	        addr_attribute18              ,
	        addr_attribute19              ,
	        addr_attribute20              ,
	        object_version_number         ,
	        add_information1             ,
	        add_information2             ,
	        add_information3             ,
	        add_information4             ,
	        add_information5             ,
	        add_information6             ,
	        add_information6             ,
	        add_information8             ,
	        party_id                      ,
	        derived_locale
          FROM xx_hr_emp_add_pre hdr
          WHERE batch_id     = G_BATCH_ID
            AND request_id   = xx_emf_pkg.G_REQUEST_ID
            AND process_code = cp_process_status
	    AND NVL(error_code, xx_emf_cn_pkg.CN_SUCCESS) IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
            ORDER BY record_number;
      --------------------------------------------------------------------------
      -----------------------< update_record_status >---------------------------
      --------------------------------------------------------------------------
      PROCEDURE update_record_status(
                                      p_conv_pre_std_hdr_rec  IN OUT  G_XX_HR_ADD_CNV_PRE_REC_TYPE,
                                      p_error_code            IN      VARCHAR2
                                     )
      IS
      BEGIN
         IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
         THEN
            p_conv_pre_std_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
         ELSE
            p_conv_pre_std_hdr_rec.error_code := xx_hr_emp_add_cnv_val_pkg.find_max(p_error_code, NVL(p_conv_pre_std_hdr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));
         END IF;
            p_conv_pre_std_hdr_rec.process_code := G_STAGE;
      END update_record_status;
      --------------------------------------------------------------------------
      -----------------------< mark_records_complete >--------------------------
      --------------------------------------------------------------------------
      PROCEDURE mark_records_complete (
                                       p_process_code VARCHAR2
                                      )
      IS
         x_last_update_date       DATE   := SYSDATE;
         x_last_updated_by        NUMBER := fnd_global.user_id;
         x_last_update_login      NUMBER := fnd_profile.value(xx_emf_cn_pkg.CN_LOGIN_ID);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         UPDATE xx_hr_emp_add_pre
            SET process_code       = G_STAGE,
                error_code         = NVL(error_code, xx_emf_cn_pkg.CN_SUCCESS),
                last_updated_by    = x_last_updated_by,
                last_update_date   = x_last_update_date,
                last_update_login  = x_last_update_login
          WHERE batch_id           = G_BATCH_ID
            AND request_id         = xx_emf_pkg.G_REQUEST_ID
            AND process_code       = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
            AND error_code  IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);
         COMMIT;
      END mark_records_complete;
      --------------------------------------------------------------------------
      -----------------------< update_pre_interface_records >-------------------
      --------------------------------------------------------------------------
      PROCEDURE update_pre_interface_records(
                                              p_cnv_pre_std_hdr_table   IN  G_XX_HR_ADD_CNV_PRE_TAB_TYPE
                                             )
      IS
         x_last_update_date       DATE   := SYSDATE;
         x_last_updated_by        NUMBER := fnd_global.user_id;
         x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         FOR indx IN 1 .. p_cnv_pre_std_hdr_table.COUNT LOOP
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).process_code ' || p_cnv_pre_std_hdr_table(indx).process_code);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).error_code ' || p_cnv_pre_std_hdr_table(indx).error_code);

            UPDATE xx_hr_emp_add_pre
            SET
                process_code                    = p_cnv_pre_std_hdr_table(indx).process_code,
                error_code                      = p_cnv_pre_std_hdr_table(indx).error_code,
                request_id                      = p_cnv_pre_std_hdr_table(indx).request_id,
                unique_id                       = p_cnv_pre_std_hdr_table(indx).unique_id, --- Added for Integra -- Dinesh
                first_name                      = p_cnv_pre_std_hdr_table(indx).first_name,
                last_name                       = p_cnv_pre_std_hdr_table(indx).last_name,
                employee_number                 = p_cnv_pre_std_hdr_table(indx).employee_number,
                npw_number                      = p_cnv_pre_std_hdr_table(indx).npw_number,
                applicant_number                = p_cnv_pre_std_hdr_table(indx).applicant_number,
                date_of_birth                   = p_cnv_pre_std_hdr_table(indx).date_of_birth,
                address_id                      = p_cnv_pre_std_hdr_table(indx).address_id,
                business_group_id               = p_cnv_pre_std_hdr_table(indx).business_group_id,
                person_id                       = p_cnv_pre_std_hdr_table(indx).person_id,
                date_from                       = p_cnv_pre_std_hdr_table(indx).date_from,
                primary_flag                    = p_cnv_pre_std_hdr_table(indx).primary_flag,
                style                           = p_cnv_pre_std_hdr_table(indx).style,
                address_line1                   = p_cnv_pre_std_hdr_table(indx).address_line1,
                address_line2                   = p_cnv_pre_std_hdr_table(indx).address_line2,
                address_line3                   = p_cnv_pre_std_hdr_table(indx).address_line3,
                address_type                    = p_cnv_pre_std_hdr_table(indx).address_type,
                country                         = p_cnv_pre_std_hdr_table(indx).country ,
                date_to                         = p_cnv_pre_std_hdr_table(indx).date_to,
                postal_code                     = p_cnv_pre_std_hdr_table(indx).postal_code ,
                region_1                        = p_cnv_pre_std_hdr_table(indx).region_1,
                region_2                        = p_cnv_pre_std_hdr_table(indx).region_2,
                region_3                        = p_cnv_pre_std_hdr_table(indx).region_3 ,
--                telephone_number_1              = p_cnv_pre_std_hdr_table(indx).telephone_number_1,
--                telephone_number_2              = p_cnv_pre_std_hdr_table(indx).telephone_number_2,
--                telephone_number_3              = p_cnv_pre_std_hdr_table(indx).telephone_number_3 ,
                town_or_city                    = p_cnv_pre_std_hdr_table(indx).town_or_city,
                program_application_id          = p_cnv_pre_std_hdr_table(indx).program_application_id ,
                program_id                      = p_cnv_pre_std_hdr_table(indx).program_id ,
                program_update_date             = p_cnv_pre_std_hdr_table(indx).program_update_date ,
                addr_attribute_category         = p_cnv_pre_std_hdr_table(indx).addr_attribute_category ,
                addr_attribute1                 = p_cnv_pre_std_hdr_table(indx).addr_attribute1,
                addr_attribute2                 = p_cnv_pre_std_hdr_table(indx).addr_attribute2,
                addr_attribute3                 = p_cnv_pre_std_hdr_table(indx).addr_attribute3,
                addr_attribute4                 = p_cnv_pre_std_hdr_table(indx).addr_attribute4,
                addr_attribute5                 = p_cnv_pre_std_hdr_table(indx).addr_attribute5,
                addr_attribute6                 = p_cnv_pre_std_hdr_table(indx).addr_attribute6,
                addr_attribute7                 = p_cnv_pre_std_hdr_table(indx).addr_attribute7,
                addr_attribute8                 = p_cnv_pre_std_hdr_table(indx).addr_attribute8,
                addr_attribute9                 = p_cnv_pre_std_hdr_table(indx).addr_attribute9,
                addr_attribute10                = p_cnv_pre_std_hdr_table(indx).addr_attribute10,
                addr_attribute11                = p_cnv_pre_std_hdr_table(indx).addr_attribute11,
                addr_attribute12                = p_cnv_pre_std_hdr_table(indx).addr_attribute12,
                addr_attribute13                = p_cnv_pre_std_hdr_table(indx).addr_attribute13,
                addr_attribute14                = p_cnv_pre_std_hdr_table(indx).addr_attribute14,
                addr_attribute15                = p_cnv_pre_std_hdr_table(indx).addr_attribute15,
                addr_attribute16                = p_cnv_pre_std_hdr_table(indx).addr_attribute16,
                addr_attribute17                = p_cnv_pre_std_hdr_table(indx).addr_attribute17,
                addr_attribute18                = p_cnv_pre_std_hdr_table(indx).addr_attribute18,
                addr_attribute19                = p_cnv_pre_std_hdr_table(indx).addr_attribute19,
                addr_attribute20                = p_cnv_pre_std_hdr_table(indx).addr_attribute20,
                object_version_number           = p_cnv_pre_std_hdr_table(indx).object_version_number,
                add_information1               = p_cnv_pre_std_hdr_table(indx).add_information1,
                add_information2               = p_cnv_pre_std_hdr_table(indx).add_information2,
                add_information3               = p_cnv_pre_std_hdr_table(indx).add_information3,
                add_information4               = p_cnv_pre_std_hdr_table(indx).add_information4,
                add_information5               = p_cnv_pre_std_hdr_table(indx).add_information5,
                add_information6               = p_cnv_pre_std_hdr_table(indx).add_information6,
                add_information7               = p_cnv_pre_std_hdr_table(indx).add_information7,
                add_information8               = p_cnv_pre_std_hdr_table(indx).add_information8,
                party_id                       = p_cnv_pre_std_hdr_table(indx).party_id,
                derived_locale                  = p_cnv_pre_std_hdr_table(indx).derived_locale,
                last_updated_by                 =  x_last_updated_by,
                last_update_date                =  x_last_update_date,
                last_update_login               =  x_last_update_login
          WHERE record_number		= p_cnv_pre_std_hdr_table(indx).record_number
            and batch_id            = G_BATCH_ID;
         END LOOP;
         COMMIT;
      END update_pre_interface_records;
      --------------------------------------------------------------------------
      -----------------------< move_rec_pre_standard_table >--------------------
      --------------------------------------------------------------------------
      FUNCTION move_rec_pre_standard_table
      RETURN NUMBER
      IS
         x_creation_date           DATE   := SYSDATE;
         x_created_by              NUMBER := fnd_global.user_id;
         x_last_update_date        DATE   := SYSDATE;
         x_last_updated_by         NUMBER := fnd_global.user_id;
         x_last_update_login       NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
         x_cnv_pre_std_hdr_table   G_XX_HR_ADD_CNV_PRE_TAB_TYPE;  -- := G_XX_HR_CNV_PRE_REC_TYPE();
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
			 p varchar2(100);
			 q varchar2(100);
			 r varchar2(100);
			 s varchar2(100);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside move_rec_pre_standard_table');
        INSERT INTO xx_hr_emp_add_pre
         (
		batch_id	              ,
		record_number                 ,
		unique_id                     , -- Added for INtegra - Dinesh
		process_code                  ,
	        error_code                    ,
                request_id                    ,
                first_name                    ,
                last_name                     ,
	        employee_number               ,
	        npw_number                    ,
	        applicant_number              ,
	        business_group_name   	      ,
	        date_of_birth	              ,
	        date_from                     ,
	        primary_flag                  ,
	        style                         ,
	        address_line1                 ,
	        address_line2                 ,
	        address_line3                 ,
	        address_type                  ,
	        country                       ,
	        date_to                       ,
	        postal_code                   ,
	        region_1                      ,
	        region_2                      ,
	        region_3                      ,
--	        telephone_number_1            ,
--	        telephone_number_2            ,
--	        telephone_number_3            ,
	        town_or_city                  ,
	        program_application_id        ,
	        program_id                    ,
	        program_update_date           ,
	        addr_attribute_category       ,
	        addr_attribute1               ,
	        addr_attribute2               ,
	        addr_attribute3               ,
	        addr_attribute4               ,
	        addr_attribute5               ,
	        addr_attribute6               ,
	        addr_attribute7               ,
	        addr_attribute8               ,
	        addr_attribute9               ,
	        addr_attribute10              ,
	        addr_attribute11              ,
	        addr_attribute12              ,
	        addr_attribute13              ,
	        addr_attribute14              ,
	        addr_attribute15              ,
	        addr_attribute16              ,
	        addr_attribute17              ,
	        addr_attribute18              ,
	        addr_attribute19              ,
	        addr_attribute20              ,
	        object_version_number         ,
	        add_information1             ,
	        add_information2             ,
	        add_information3             ,
	        add_information4             ,
	        add_information5             ,
	        add_information6             ,
	        add_information7             ,
	        add_information8
           )
         SELECT
                batch_id                      ,
		record_number                 ,
		unique_id                     , -- Added for INtegra - Dinesh
		process_code                  ,
	        error_code                    ,
		request_id                    ,
                first_name                    ,
                last_name                     ,
	        employee_number               ,
	        npw_number                    ,
	        applicant_number              ,
	        business_group_name           ,
	        date_of_birth	              ,
	        date_from                     ,
	        DECODE(UPPER(primary_flag),'YES','Y','NO','N',primary_flag),--Changed for Integra 24/02/2012
	        style                         ,
	        address_line1                 ,
	        address_line2                 ,
	        address_line3                 ,
	        address_type                  ,
	        country                       ,
	        date_to                       ,
	        postal_code                   ,
	        region_1                      ,
	        region_2                      ,
	        region_3                      ,
--	        telephone_number_1            ,
--	        telephone_number_2            ,
--	        telephone_number_3            ,
	        town_or_city                  ,
	        program_application_id        ,
	        program_id                    ,
	        program_update_date           ,
	        addr_attribute_category       ,
	        addr_attribute1               ,
	        addr_attribute2               ,
	        addr_attribute3               ,
	        addr_attribute4               ,
	        addr_attribute5               ,
	        addr_attribute6               ,
	        addr_attribute7               ,
	        addr_attribute8               ,
	        addr_attribute9               ,
	        addr_attribute10              ,
	        addr_attribute11              ,
	        addr_attribute12              ,
	        addr_attribute13              ,
	        addr_attribute14              ,
	        addr_attribute15              ,
	        addr_attribute16              ,
	        addr_attribute17              ,
	        addr_attribute18              ,
	        addr_attribute19              ,
	        addr_attribute20              ,
	        object_version_number         ,
	        add_information1             ,
	        add_information2             ,
	        add_information3             ,
	        add_information4             ,
	        add_information5             ,
	        add_information6             ,
	        add_information7             ,
	        add_information8
           FROM xx_hr_emp_add_stg
          WHERE BATCH_ID     = G_BATCH_ID
            AND process_code = xx_emf_cn_pkg.CN_PREVAL
            AND request_id   = xx_emf_pkg.G_REQUEST_ID
            AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
            AND NVL (date_to,sysdate) >= trunc(sysdate);

            COMMIT;
	    RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
            x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
            RETURN x_error_code;
      END move_rec_pre_standard_table;
      --------------------------------------------------------------------------
      -----------------------< process_data >-----------------------------------
      --------------------------------------------------------------------------
      FUNCTION process_data (
                             p_parameter_1     IN VARCHAR2,
                             p_parameter_2     IN VARCHAR2
                            )
      RETURN NUMBER
      IS
         x_return_status VARCHAR2(15) := xx_emf_cn_pkg.CN_SUCCESS;
      CURSOR xx_emp_add_cur
      IS
      SELECT *
        FROM xx_hr_emp_add_pre
       WHERE error_code IN (xx_emf_cn_pkg.CN_SUCCESS,xx_emf_cn_pkg.CN_REC_WARN)
         AND batch_id     = G_BATCH_ID
    ORDER BY COALESCE(employee_number,npw_number,applicant_number) , primary_flag desc, date_from desc;

    x_validate       		     BOOLEAN  := FALSE;
    x_effective_date		     DATE;
    x_pradd_ovlapval_override    BOOLEAN  := FALSE;
    x_validate_county 	         BOOLEAN  := TRUE;
    l_address_id                 NUMBER;
    l_object_version_number      NUMBER;
    x_legislation_code           NUMBER;
    x_sqlerrm                    VARCHAR2(2000);
    x_county                     varchar2(120);
    x_max_date_from              DATE;
    x_pa_count                   NUMBER;
  BEGIN
         -- Change the logic to whatever needs to be done
         -- with valid records in the pre-interface tables
         -- either call the appropriate API to process the data
         -- or to insert into an interface table.
   FOR xx_emp_add_rec IN xx_emp_add_cur
   LOOP
     x_max_date_from := null;
     x_pa_count      := 0;
     x_county        := null;
     BEGIN
     dbms_output.PUT_LINE ('Inside the loop');
       -- check if primary address already exists for this employee   ----
       -- if exists then date_start = date_to of existing address + 1 ----
       -- if not exists then date_start = employee joining date       ----
       select nvl(max(date_to),xx_emp_add_rec.date_from-1)+1
         into x_max_date_from
         from per_addresses pa
        where pa.person_id    = xx_emp_add_rec.person_id
          and pa.primary_flag = xx_emp_add_rec.primary_flag;
       -- if address date_from is greater than ppf.eff_start_date, take ppf date
       select greatest(min(papf.effective_start_date),x_max_date_from)
         into x_max_date_from
         from per_all_people_f papf
        where person_id = xx_emp_add_rec.person_id;
       -- dbms_output.PUT_LINE ('x_max_date_from :' || x_max_date_from);
       -- check if same address already exists in base table --
       select count(1)
         into x_pa_count
         from per_addresses pa
        where pa.person_id    = xx_emp_add_rec.person_id
          and pa.primary_flag = xx_emp_add_rec.primary_flag
          and nvl(pa.date_to,sysdate) = nvl(xx_emp_add_rec.date_to,sysdate);
       if x_pa_count > 0 then
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;

        UPDATE xx_hr_emp_add_pre
	 SET error_code    = x_error_code
        WHERE record_number = xx_emp_add_rec.record_number
	 AND batch_id      = G_BATCH_ID;

         xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.CN_MEDIUM
                              ,p_category            =>   xx_emf_cn_pkg.CN_TECH_ERROR
                              ,p_error_text          =>   'Address already exists in date range'
                                 ,p_record_identifier_1 =>   COALESCE(xx_emp_add_rec.employee_number,xx_emp_add_rec.npw_number,xx_emp_add_rec.applicant_number)
--                                 ,p_record_identifier_2 =>   xx_emp_add_rec.last_name||', '||xx_emp_add_rec.first_name
                                 ,p_record_identifier_2 =>   xx_emp_add_rec.unique_id
                              );

       else -- if x_pa_count > 0 then
       -- if xx_emp_add_rec.addr_attribute1 = 'EXEMP' then
     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'before get_flex_values call' );
     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, COALESCE(xx_emp_add_rec.employee_number,xx_emp_add_rec.npw_number,xx_emp_add_rec.applicant_number));


xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, '>>>>>>Din 1 >>>'|| xx_emp_add_rec.style );

          IF xx_emp_add_rec.style IS NOT NULL THEN -- Added check for integra
          get_flex_values(p_style               => xx_emp_add_rec.style         -- in
          	        ,p_country               => xx_emp_add_rec.country         -- in
                       ,p_addr_attribute1       => xx_emp_add_rec.addr_attribute1   -- in
                       ,p_address_line1         => xx_emp_add_rec.address_line1     -- in/out
                       ,p_address_line2         => xx_emp_add_rec.address_line2     -- in/out
                       ,p_address_line3         => xx_emp_add_rec.address_line3     -- in/out
                       ,p_postal_code           => xx_emp_add_rec.postal_code       -- in/out
                       ,p_town_or_city          => xx_emp_add_rec.town_or_city      -- in/out
                       ,p_region_1              => xx_emp_add_rec.region_1          -- in/out
                       ,p_region_2              => xx_emp_add_rec.region_2          -- in/out
                       ,p_region_3              => xx_emp_add_rec.region_3          -- in/out
                       ,p_add_information1     => xx_emp_add_rec.add_information1     -- in/out
                       ,p_add_information2     => xx_emp_add_rec.add_information2     -- in/out
                       ,p_add_information3     => xx_emp_add_rec.add_information3     -- in/out
                       ,p_add_information4     => xx_emp_add_rec.add_information4     -- in/out
                       ,p_add_information5     => xx_emp_add_rec.add_information5     -- in/out
                       ,p_add_information6     => xx_emp_add_rec.add_information6     -- in/out
                       ,p_add_information7     => xx_emp_add_rec.add_information7     -- in/out
                       ,p_add_information8     => xx_emp_add_rec.add_information8     -- in/out
--                       ,p_telephone_number_1    => xx_emp_add_rec.telephone_number_1    -- in/out
--                       ,p_telephone_number_2    => xx_emp_add_rec.telephone_number_2    -- in/out
--                       ,p_telephone_number_3    => xx_emp_add_rec.telephone_number_3    -- in/out
                       );
            END IF;
xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, '>>>>>>Din 2 >>>'|| xx_emp_add_rec.style );

        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, COALESCE(xx_emp_add_rec.employee_number,xx_emp_add_rec.npw_number,xx_emp_add_rec.applicant_number));
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'before create_person_address API call' );



         HR_PERSON_ADDRESS_API.create_person_address
              (
               p_validate                  => g_validate_flag_for_api --x_validate -- This will be TRUE or FALSE based on the validate and load parameter.
              ,p_effective_date            => sysdate--x_effective_date
              ,p_pradd_ovlapval_override   => x_pradd_ovlapval_override
              ,p_validate_county           => x_validate_county
              ,p_person_id                 => xx_emp_add_rec.person_id
              ,p_primary_flag              => xx_emp_add_rec.primary_flag
              ,p_style                     => xx_emp_add_rec.style
              ,p_date_from                 => x_max_date_from -- xx_emp_add_rec.start_date     -- xx_emp_add_rec.date_from
              ,p_date_to                   => xx_emp_add_rec.date_to
              ,p_address_type              => xx_emp_add_rec.address_type
              ,p_address_line1             => xx_emp_add_rec.address_line1
              ,p_address_line2             => xx_emp_add_rec.address_line2
              ,p_address_line3             => xx_emp_add_rec.address_line3
              ,p_town_or_city              => xx_emp_add_rec.town_or_city
              ,p_region_1                  => xx_emp_add_rec.region_1
              ,p_region_2                  => xx_emp_add_rec.region_2
              ,p_region_3                  => xx_emp_add_rec.region_3
              ,p_postal_code               => xx_emp_add_rec.postal_code
              ,p_country                   => xx_emp_add_rec.country
              ,p_telephone_number_1        => NULL --xx_emp_add_rec.telephone_number_1 -- Nulled for Integra
              ,p_telephone_number_2        => NULL --xx_emp_add_rec.telephone_number_2 -- Nulled for Integra
              ,p_telephone_number_3        => NULL --xx_emp_add_rec.telephone_number_3 -- Nulled for Integra
              ,p_addr_attribute_category   => xx_emp_add_rec.addr_attribute_category
              ,p_addr_attribute1           => xx_emp_add_rec.addr_attribute1
              ,p_addr_attribute2           => xx_emp_add_rec.addr_attribute2
              ,p_addr_attribute3           => xx_emp_add_rec.addr_attribute3
              ,p_addr_attribute4           => xx_emp_add_rec.addr_attribute4
              ,p_addr_attribute5           => xx_emp_add_rec.addr_attribute5
              ,p_addr_attribute6           => xx_emp_add_rec.addr_attribute6
              ,p_addr_attribute7           => xx_emp_add_rec.addr_attribute7
              ,p_addr_attribute8           => xx_emp_add_rec.addr_attribute8
              ,p_addr_attribute9           => xx_emp_add_rec.addr_attribute9
              ,p_addr_attribute10          => xx_emp_add_rec.addr_attribute10
              ,p_addr_attribute11          => xx_emp_add_rec.addr_attribute11
              ,p_addr_attribute12          => xx_emp_add_rec.addr_attribute12
              ,p_addr_attribute13          => xx_emp_add_rec.addr_attribute13
              ,p_addr_attribute14          => xx_emp_add_rec.addr_attribute14
              ,p_addr_attribute15          => xx_emp_add_rec.addr_attribute15
              ,p_addr_attribute16          => xx_emp_add_rec.addr_attribute16
              ,p_addr_attribute17          => xx_emp_add_rec.addr_attribute17
              ,p_addr_attribute18          => xx_emp_add_rec.addr_attribute18
              ,p_addr_attribute19          => xx_emp_add_rec.addr_attribute19
              ,p_addr_attribute20          => xx_emp_add_rec.addr_attribute20
              ,p_add_information13         => xx_emp_add_rec.add_information1
              ,p_add_information14         => xx_emp_add_rec.add_information2
              ,p_add_information15         => xx_emp_add_rec.add_information3
              ,p_add_information16         => xx_emp_add_rec.add_information4
              ,p_add_information17         => xx_emp_add_rec.add_information5
              ,p_add_information18         => xx_emp_add_rec.add_information6
              ,p_add_information19         => xx_emp_add_rec.add_information7
              ,p_add_information20         => xx_emp_add_rec.add_information8
              ,p_party_id                  => xx_emp_add_rec.party_id
              ,p_address_id                => l_address_id
              ,p_object_version_number     => l_object_version_number
	          );
	    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, COALESCE(xx_emp_add_rec.employee_number,xx_emp_add_rec.npw_number,xx_emp_add_rec.applicant_number) );
     end if; --if x_pa_count > 0 then

     COMMIT;
   EXCEPTION
          WHEN OTHERS THEN
            x_sqlerrm := substr(sqlerrm,1,800);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;

            UPDATE xx_hr_emp_add_pre
               SET error_code    = x_error_code
             WHERE record_number = xx_emp_add_rec.record_number
               AND batch_id      = G_BATCH_ID;

            COMMIT;
            xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category            =>   xx_emf_cn_pkg.CN_TECH_ERROR
                                 ,p_error_text          =>   x_sqlerrm
                                 ,p_record_identifier_1 =>   COALESCE(xx_emp_add_rec.employee_number,xx_emp_add_rec.npw_number,xx_emp_add_rec.applicant_number)
                                 --,p_record_identifier_2 =>   xx_emp_add_rec.last_name||', '||xx_emp_add_rec.first_name
                                 ,p_record_identifier_2 =>   xx_emp_add_rec.unique_id
                                 );
       END;
     END LOOP;
 	 RETURN x_return_status;
   EXCEPTION
      WHEN OTHERS THEN
            x_sqlerrm := sqlerrm;
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	        xx_emf_pkg.error (xx_emf_cn_pkg.CN_HIGH,
                                  xx_emf_cn_pkg.CN_TECH_ERROR,
                                  x_sqlerrm
                                  );
            RETURN x_error_code;
   END process_data;
      --------------------------------------------------------------------------
      -----------------------< update_record_count >---------------------------
      --------------------------------------------------------------------------
      PROCEDURE update_record_count
      IS
         CURSOR c_get_total_cnt
         IS
         SELECT COUNT (1) total_count
           FROM xx_hr_emp_add_stg
          WHERE batch_id   = G_BATCH_ID
            AND request_id = xx_emf_pkg.G_REQUEST_ID;
         x_total_cnt NUMBER;
         CURSOR c_get_error_cnt
         IS
         SELECT SUM(error_count)  FROM
         ( SELECT COUNT (1) error_count
           FROM xx_hr_emp_add_stg
          WHERE batch_id   = G_BATCH_ID
            AND request_id = xx_emf_pkg.G_REQUEST_ID
            AND error_code = xx_emf_cn_pkg.CN_REC_ERR
         UNION ALL
         SELECT COUNT (1) error_count
           FROM xx_hr_emp_add_pre
          WHERE batch_id = G_BATCH_ID
            AND request_id = xx_emf_pkg.G_REQUEST_ID
            AND error_code = xx_emf_cn_pkg.CN_REC_ERR);
         x_error_cnt NUMBER;
         CURSOR c_get_warning_cnt
         IS
         SELECT COUNT (1) warn_count
           FROM xx_hr_emp_add_pre
          WHERE batch_id   = G_BATCH_ID
            AND request_id = xx_emf_pkg.G_REQUEST_ID
            AND error_code = xx_emf_cn_pkg.CN_REC_WARN;
         x_warn_cnt NUMBER;
         CURSOR c_get_success_cnt
         IS
         SELECT COUNT (1) warn_count
           FROM xx_hr_emp_add_pre
          WHERE batch_id     = G_BATCH_ID
            AND request_id   = xx_emf_pkg.G_REQUEST_ID
            AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
            AND error_code   = xx_emf_cn_pkg.CN_SUCCESS;
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
      END update_record_count;
      ---------------------------MAIN PROCEDURE BEGINS HERE-----------------------------------------------
   BEGIN
	  retcode := xx_emf_cn_pkg.CN_SUCCESS;

      -- Set environment for EMF (Error Management Framework)
      -- If you want the process to continue even after the emf env not being set
      -- you must make p_required_flag from CN_YES to CN_NO
      -- If you do not pass proper value then it will be considered as CN_YES
      set_cnv_env (p_batch_id => p_batch_id, p_required_flag => xx_emf_cn_pkg.CN_YES);
      -- include all the parameters to the conversion main here
      -- as medium log messages


	    -- This checks whether the  validations including API validations are to be followed with actual
      -- loading of data into base tables or if it should just stop at validating and reporting
      IF p_validate_and_load = 'VALIDATE_AND_LOAD'
      THEN
      	g_validate_flag_for_api := FALSE; -- API will validate and update base tables if successful
      ELSE
      	g_validate_flag_for_api := TRUE; -- API will only validate and not modify database
      END IF;

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'The Versions of various objects used are printed hereunder...');
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Version of Staging Table:   ' || CN_XXHRADDSTG_TBL);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Version of Staging Table Synonym in APPS:   ' || CN_XXHRADDSTG_SYN);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Version of Pre-Interface Table:   ' || CN_XXHRADDPRE_TBL);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Version of Pre-Interface Table Synonym in APPS:   ' || CN_XXHRADDPRE_SYN);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Version of Validation Package Spec:   ' || CN_XXHRADDVAL_PKS);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Version of Validation Package Body:   ' || CN_XXHRADDVAL_PKB);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Version of Conversion Package Spec:   ' || CN_XXHRADDCNV_PKS);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Version of Conversion Package Body:   ' || CN_XXHRADDCNV_PKB);

      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Starting main process with the following parameters');
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_batch_id ' ||  p_batch_id);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_restart_flag ' ||  p_restart_flag);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_override_flag ' || p_override_flag);
      -- Call procedure to update records with the current request_id
      -- So that we can process only those records
      -- This gives a better handling of restartability
      mark_records_for_processing (p_restart_flag => p_restart_flag, p_override_flag => p_override_flag);
      -- Once the records are identified based on the input parameters
      -- Start with pre-validations
      IF NVL (p_override_flag, xx_emf_cn_pkg.CN_NO) = xx_emf_cn_pkg.CN_NO
      THEN
         -- Set the stage to Pre Validations
         set_stage (xx_emf_cn_pkg.CN_PREVAL);
         -- Change the validations package to the appropriate package name
         -- Modify the parameters as required
         -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
         -- PRE_VALIDATIONS SHOULD BE RETAINED
         -- Update process code of staging records
         -- Also move the successful records to pre-interface tables
         update_staging_records (xx_emf_cn_pkg.CN_SUCCESS);
         xx_emf_pkg.propagate_error (x_error_code);
         x_error_code := move_rec_pre_standard_table;
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;
      -- Once pre-validations are complete the loop through the pre-interface records
      -- and perform data validations on this table
      -- Set the stage to data Validations
      set_stage (xx_emf_cn_pkg.CN_VALID);
      OPEN c_xx_pre_std_hdr (xx_emf_cn_pkg.CN_PREVAL);
      LOOP
         FETCH c_xx_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;
         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN

            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, '>>>>>>Din 3 >>>'|| x_pre_std_hdr_table (i).style );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, '>>>>>>Din 4 >>>'|| x_pre_std_hdr_table (i).record_number );

               -- Perform header level Base App Validations
               x_error_code := xx_hr_emp_add_cnv_val_pkg.data_validations(x_pre_std_hdr_table (i));
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_hdr_table (i).record_number|| ' is ' || x_error_code);

            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, '>>>>>>Din 5 >>>'|| x_pre_std_hdr_table (i).style );

               update_record_status (x_pre_std_hdr_table (i), x_error_code);
               xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
               WHEN xx_emf_pkg.G_E_REC_ERROR THEN
			      fnd_file.Put_line(1, 'In Exception 1:'||SQLERRM);
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.CN_REC_ERR);
               WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
                  fnd_file.Put_line(1, 'In Exception 2:'||SQLERRM);
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Process Level Error in Data Validations');
                  update_pre_interface_records (x_pre_std_hdr_table);
                  RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
               WHEN OTHERS THEN
                  fnd_file.Put_line(1, ' In Exception 3:'||SQLERRM);
                  xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                                    xx_emf_cn_pkg.CN_TECH_ERROR,
                                    xx_emf_cn_pkg.CN_EXP_UNHAND
                                   ,p_record_identifier_1 =>   COALESCE(x_pre_std_hdr_table (i).employee_number,x_pre_std_hdr_table (i).npw_number,x_pre_std_hdr_table (i).applicant_number)
                                   --,p_record_identifier_2 =>   x_pre_std_hdr_table (i).last_name||', '||x_pre_std_hdr_table (i).first_name
                                   ,p_record_identifier_2 =>   x_pre_std_hdr_table (i).unique_id
                                    );
            END;
         END LOOP;
          xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_pre_std_hdr_table.count ' || x_pre_std_hdr_table.COUNT );
          update_pre_interface_records (x_pre_std_hdr_table);



          x_pre_std_hdr_table.DELETE;
         EXIT WHEN c_xx_pre_std_hdr%NOTFOUND;
      END LOOP;
      IF c_xx_pre_std_hdr%ISOPEN THEN
         CLOSE c_xx_pre_std_hdr;
      END IF;
      -- Once data-validations are complete the loop through the pre-interface records
      -- and perform data derivations on this table
      -- Set the stage to data derivations
      set_stage (xx_emf_cn_pkg.CN_DERIVE);
      OPEN c_xx_pre_std_hdr (xx_emf_cn_pkg.CN_VALID);
      LOOP
         FETCH c_xx_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;
	     fnd_file.Put_line(1, 'Records Count:'||x_pre_std_hdr_table.COUNT);
         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN


            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, '>>>>>>Din 8 >>>'|| x_pre_std_hdr_table (i).style );
             xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, '>>>>>>Din 9 >>>'|| x_pre_std_hdr_table (i).record_number );

               -- Perform header level Base App Validations
               x_error_code := xx_hr_emp_add_cnv_val_pkg.data_derivations(x_pre_std_hdr_table(i));
               xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_pre_std_hdr_table (i).record_number|| ' is ' || x_error_code);

            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, '>>>>>>Din 10 >>>'|| x_pre_std_hdr_table (i).style );
             xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, '>>>>>>Din 11 >>>'|| x_pre_std_hdr_table (i).record_number );

               update_record_status (x_pre_std_hdr_table (i), x_error_code);
               xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
               WHEN xx_emf_pkg.G_E_REC_ERROR THEN
                  fnd_file.Put_line(1, ' In Exception 1, During data derivation:'||SQLERRM);
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.CN_REC_ERR);
               WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
                  fnd_file.Put_line(1, ' In Exception 2, During data derivation:'||SQLERRM);
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Process Level Error in Data derivations');
                  update_pre_interface_records (x_pre_std_hdr_table);
                  RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
               WHEN OTHERS THEN
                  fnd_file.Put_line(1, ' In Exception 3, During data derivation:'||SQLERRM);
                  xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM
                                        ,xx_emf_cn_pkg.CN_TECH_ERROR
                                        ,xx_emf_cn_pkg.CN_EXP_UNHAND
					,p_record_identifier_1 =>   COALESCE(x_pre_std_hdr_table(i).employee_number,x_pre_std_hdr_table(i).npw_number,x_pre_std_hdr_table(i).applicant_number)
					--,p_record_identifier_2 =>   x_pre_std_hdr_table(i).last_name||', '||x_pre_std_hdr_table(i).first_name
					,p_record_identifier_2 =>   x_pre_std_hdr_table(i).unique_id
                                        );
           END;
         END LOOP;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_pre_std_hdr_table.count ' || x_pre_std_hdr_table.COUNT );
         update_pre_interface_records (x_pre_std_hdr_table);



         x_pre_std_hdr_table.DELETE;
         EXIT WHEN c_xx_pre_std_hdr%NOTFOUND;
      END LOOP;
      IF c_xx_pre_std_hdr%ISOPEN THEN
         CLOSE c_xx_pre_std_hdr;
      END IF;
      -- Set the stage to Pre Validations
      set_stage (xx_emf_cn_pkg.CN_POSTVAL);
      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
      -- PRE_VALIDATIONS SHOULD BE RETAINED
      -- x_error_code := xx_cn_trnx_validations_pkg.post_validations();
      x_error_code := xx_hr_emp_add_cnv_val_pkg.post_validations();
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
      mark_records_complete (xx_emf_cn_pkg.CN_POSTVAL);
      xx_emf_pkg.propagate_error (x_error_code);
      -- Set the stage to Pre Validations
      set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);
      x_error_code := process_data (NULL, NULL);
      mark_records_complete (xx_emf_cn_pkg.CN_PROCESS_DATA);
      xx_emf_pkg.propagate_error (x_error_code);
      update_record_count;
      xx_emf_pkg.create_report;
   EXCEPTION
      WHEN xx_emf_pkg.G_E_ENV_NOT_SET THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Checking if this is OK');
         fnd_file.PUT_LINE (fnd_file.output, xx_emf_pkg.CN_ENV_NOT_SET);
         dbms_output.PUT_LINE (xx_emf_pkg.CN_ENV_NOT_SET);
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
         xx_emf_pkg.create_report;
   END main;
END XX_HR_EMP_ADD_CONVERSION_PKG;
/
