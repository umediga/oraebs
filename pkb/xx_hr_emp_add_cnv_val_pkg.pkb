DROP PACKAGE BODY APPS.XX_HR_EMP_ADD_CNV_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_EMP_ADD_CNV_VAL_PKG" 
AS
----------------------------------------------------------------------
  /*
 Created BY    : IBM Development
 Creation DATE : 3-DEC-2007
 FILE NAME     : XXHRADDVAL.pkb
 Description   : This script creates THE BODY OF THE PACKAGE
                           xx_hr_emp_add_cnv_val_pkg
 CHANGE History:
 DATE         NAME                     Version          Remarks
 ----------- -----------------   ------------------   ---------------------
 16-jan-2012  Dinesh                 1.0              Integra Initial development
 13-Jun-2012  MuthuKumar             2.0              Validation For Address Style 'GENERIC' is changed
 19-jun-2012  Arjun K                2.1              get_address_line2 function call
                                                      commented post CRP3 for Integra
*/ ---------------------------------------------------------------------------------

  --**********************************************************************
  --Function to Find Max.
  --**********************************************************************
   FUNCTION find_max(
                     p_error_code1 IN VARCHAR2,
                     p_error_code2 IN VARCHAR2
                     ) RETURN VARCHAR2
   IS
                  x_return_value VARCHAR2(100);
  BEGIN
    x_return_value := XX_INTG_common_pkg.find_max(p_error_code1,
                                                 p_error_code2);
    RETURN x_return_value;
  END find_max;
  --**********************************************************************
  --Function to Pre Validations .
  --**********************************************************************
  FUNCTION pre_validations( p_cnv_hdr_rec IN OUT nocopy
                            xx_hr_emp_add_conversion_pkg.G_XX_HR_ADD_CNV_PRE_REC_TYPE
                           ) RETURN NUMBER
  IS
              x_error_code      NUMBER := xx_emf_cn_pkg.cn_success;
              x_error_code_temp NUMBER := xx_emf_cn_pkg.cn_success;

--**********************************************************************
  --Function to check Date from Not Null or not equal to latest hire date -- Dinesh Integra.
  --**********************************************************************
  FUNCTION is_date_from_not_null( p_date_from IN DATE
  				  ,p_unique_id IN VARCHAR2
                                 ) RETURN NUMBER
  IS
   x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
   x_hire_date  DATE :=sysdate +1;
  BEGIN

    BEGIN
    SELECT ppf.effective_start_date
      INTO x_hire_date
      FROM per_all_people_f ppf
     WHERE ppf.attribute1 = p_unique_id
       AND trunc(sysdate) BETWEEN ppf.effective_start_date AND ppf.effective_end_date;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
          NULL;
    WHEN OTHERS THEN
	  NULL;
    END;

    IF p_date_from IS NULL OR x_hire_date <> p_date_from THEN
      x_error_code := xx_emf_cn_pkg.cn_rec_err;
      xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.cn_low,
                            p_category            =>   xx_emf_cn_pkg.cn_lstnm_valid,
                            p_error_text          =>   'Either DATE FROM is NULL or not equal to HIRE DATE'
                            ,p_record_identifier_1 =>   COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
                            --,p_record_identifier_2 =>   p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
                            ,p_record_identifier_2 =>   p_unique_id
                            --,p_record_identifier_4 =>   'Date From-'||p_date_from
                            );
    END IF;

    RETURN x_error_code;
  END is_date_from_not_null;

  ------------------------------------------------------------------
  ---------------------< is_country_null >--------------------------
  ------------------------------------------------------------------
  FUNCTION is_country_null( p_country IN varchar2
                          ) RETURN NUMBER  IS
   x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
  BEGIN
    IF p_country IS NULL THEN
      x_error_code := xx_emf_cn_pkg.cn_rec_err;
      xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.cn_low,
                            p_category            =>   xx_emf_cn_pkg.cn_lstnm_valid,
                            p_error_text          =>   'Country cannot be null'
                            ,p_record_identifier_1 =>   COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
                          --  ,p_record_identifier_2 =>   p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
                            ,p_record_identifier_2 =>   p_cnv_hdr_rec.unique_id
                          --  ,p_record_identifier_4 =>   'Country-'||p_country
                            );
    END IF;
    RETURN x_error_code;
  END is_country_null;


  BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Inside Pre-Validations');

    x_error_code_temp := is_date_from_not_null(p_cnv_hdr_rec.date_from,p_cnv_hdr_rec.unique_id);
    x_error_code := find_max(x_error_code,   x_error_code_temp);
    xx_emf_pkg.propagate_error(x_error_code_temp);

    x_error_code_temp := is_country_null(p_cnv_hdr_rec.country);
    x_error_code := find_max(x_error_code,   x_error_code_temp);
    xx_emf_pkg.propagate_error(x_error_code_temp);

     RETURN x_error_code;
  EXCEPTION
  WHEN xx_emf_pkg.g_e_rec_error THEN
    x_error_code := xx_emf_cn_pkg.cn_rec_err;
    RETURN x_error_code;
  WHEN xx_emf_pkg.g_e_prc_error THEN
    x_error_code := xx_emf_cn_pkg.cn_prc_err;
    RETURN x_error_code;
  WHEN others THEN
    x_error_code := xx_emf_cn_pkg.cn_prc_err;
    RETURN x_error_code;
  END pre_validations;
  --**********************************************************************
  --Function to Data Validations .
  --**********************************************************************
   FUNCTION data_validations( p_cnv_hdr_rec IN OUT NOCOPY xx_hr_emp_add_conversion_pkg.G_XX_HR_ADD_CNV_PRE_REC_TYPE
                             ) RETURN NUMBER
  IS
          x_error_code      NUMBER := xx_emf_cn_pkg.cn_success;
          x_error_code_temp NUMBER := xx_emf_cn_pkg.cn_success;
          x_person_id          NUMBER;
          x_party_id           NUMBER;
          x_parent_table       VARCHAR2(40);
          x_sqlerrm            VARCHAR2(2000);
   ------------------------------------------------------------------
      ---------------------< is_country_valid >--------------------------
      ------------------------------------------------------------------
      FUNCTION is_country_valid( p_country IN OUT NOCOPY varchar2
                              ) RETURN NUMBER  IS
       x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN

       IF p_country IS NOT NULL THEN
           SELECT territory_code
            INTO p_country
           FROM fnd_territories_tl
           WHERE UPPER(territory_code) = UPPER(p_country) --- Changed terriroty name to code as per Integra data file.Also commented UPPER(xx_hr_common_pkg.get_mapping_value ('COUNTRY',p_country))-- Dinesh Integra
            AND language = userenv('LANG') ;
       END IF;
       RETURN x_error_code;
       EXCEPTION
        WHEN no_data_found THEN
          x_error_code := xx_emf_cn_pkg.cn_rec_err;
          xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.cn_low,
                                p_category            =>  'CNTRY-DV001',
                                p_error_text          =>  'Country Not Found'
                               ,p_record_identifier_1 =>   COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
                               --,p_record_identifier_2 =>   p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
                               ,p_record_identifier_2 =>   p_cnv_hdr_rec.unique_id
                               --,p_record_identifier_4 =>   'Country-'||p_country
                                );
                                RETURN x_error_code;
          WHEN too_many_rows THEN
  	        x_error_code := xx_emf_cn_pkg.cn_rec_err;
  	        xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.cn_low,
  	                             p_category            =>  'CNTRY-DV001',
	                             p_error_text          =>  'Country Too Many Rows'
				    ,p_record_identifier_1 =>   COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
				    --,p_record_identifier_2 =>   p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
				    ,p_record_identifier_2 =>   p_cnv_hdr_rec.unique_id
				    --,p_record_identifier_4 =>   'Country-'||p_country
  	                              );
  	                              RETURN x_error_code;
  	 WHEN others THEN
         	        x_error_code := xx_emf_cn_pkg.cn_rec_err;
         	        xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.cn_low,
         	                             p_category            =>  'CNTRY-DV001',
         	                             p_error_text          =>  'Country : '||SQLERRM
					    ,p_record_identifier_1 =>   COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
					--    ,p_record_identifier_2 =>   p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
					    ,p_record_identifier_2 =>   p_cnv_hdr_rec.unique_id
					--    ,p_record_identifier_4 =>   'Country-'||p_country
  	                              );
  	                              RETURN x_error_code;


    END is_country_valid;
  ------------------------------------------------------------------------------
 --- Local functions for all batch level validations
 --- Add as many functions as required in here
  --*************************************************************
  --Procedure to get person Id and Party Id.
  --*************************************************************
 FUNCTION get_contact_id (p_cont_fname IN VARCHAR2
                        ,p_cont_lname IN VARCHAR2
			,p_cont_dob   IN DATE
			,p_unique_id    IN VARCHAR2 -- Added by Dinesh Integra
			,p_bg_name    IN VARCHAR2
			,p_person_id  OUT NUMBER
			,p_party_id   OUT NUMBER
                        )
			RETURN NUMBER
  IS
        x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
	--x_emp_num      VARCHAR2(50);
  BEGIN


   SELECT a.person_id , a.party_id
    INTO p_person_id , p_party_id
   FROM  per_all_people_f a
        ,per_all_people_f b
	,per_contact_relationships c
	,per_business_groups d
  WHERE a.business_group_id = b.business_group_id
   AND  d.name = p_bg_name
   AND  a.business_group_id = d.business_group_id
   AND  b.person_id = c.person_id
   AND  a.person_id = c.contact_person_id
   AND (p_unique_id IS NULL OR b.attribute1 = p_unique_id) -- Added by Dinesh Integra
   AND  a.first_name=p_cont_fname
   AND  a.last_name=p_cont_lname
   AND  (a.date_of_birth IS NULL OR a.date_of_birth = p_cont_dob)
   AND  rownum = 1;

    RETURN x_error_code;
  EXCEPTION
   WHEN no_data_found THEN
          x_error_code := xx_emf_cn_pkg.cn_rec_err;
          xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.cn_low,
                                p_category            =>  'GETCON-DV001',
                                p_error_text          =>  'Contact Not Found For The Employee',
				p_record_identifier_1 =>   '            ' -- Spaces for formatting in report
			  --     ,p_record_identifier_3 =>   p_cont_lname||', '||p_cont_fname
			       ,p_record_identifier_2 =>   p_unique_id
			  --     ,p_record_identifier_4 =>   'D.O.B-'||p_cont_dob
                                );

                                RETURN x_error_code;
          WHEN too_many_rows THEN
  	        x_error_code := xx_emf_cn_pkg.cn_rec_err;
  	        xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.cn_low,
  	                              p_category            =>  'GETCON-DV001',
  	                              p_error_text          =>  'Contact Too Many For The Employee',
				      p_record_identifier_1 =>   '            ' -- Spaces for formatting in report
				 --    ,p_record_identifier_3 =>   p_cont_lname||', '||p_cont_fname
				     ,p_record_identifier_2 =>   p_unique_id
				    -- ,p_record_identifier_4 =>   'D.O.B-'||p_cont_dob
  	                              );
  	                              RETURN x_error_code;
  	 WHEN others THEN
         	        x_error_code := xx_emf_cn_pkg.cn_rec_err;
         	        xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.cn_low,
         	                              p_category            =>  'GETCON-DV001',
         	                              p_error_text          =>  'Contact Error : '||SQLERRM,
					      p_record_identifier_1 =>   '            ' -- Spaces for formatting in report
					--     ,p_record_identifier_3 =>   p_cont_lname||', '||p_cont_fname
					     ,p_record_identifier_2 =>   p_unique_id
					 --    ,p_record_identifier_4 =>   'D.O.B-'||p_cont_dob
  	                              );
  	                              RETURN x_error_code;
  END get_contact_id;


  -------------------------------------------------------------------------------
    --------------------< check_mandatory_cloumns >-----------------------------
  -------------------------------------------------------------------------------

  FUNCTION check_mandatory_cloumns(p_style        in varchar2
                                  ,p_country      in varchar2
                                  ,p_address_line1 in varchar2
                                  ,p_town_or_city  in varchar2
                                  ,p_region_1        IN OUT NOCOPY VARCHAR2
                                  ,p_region_2        IN OUT NOCOPY VARCHAR2
                                  ) return number is
      x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
      x_sqlerrm      varchar2(1000);
      x_region_1     varchar2(120);
      x_region_2     varchar2(120);
    begin

        if (p_style = 'US_GLB') OR (p_style = 'US') then
            if (p_address_line1 is null) then
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
  	               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.cn_low
  	                                    ,p_category    => 'DV_Addr1'
  	                                    ,p_error_text  => 'Address Line1 cannot be NULL for US Address'
	                                   ,p_record_identifier_1 => COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
	                               --    ,p_record_identifier_2 => p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
	                                   ,p_record_identifier_2 => p_cnv_hdr_rec.unique_id
  	                               --     ,p_record_identifier_4 => 'Country-'||p_country
                                          );
            end if;
            IF p_region_2 IS NOT NULL THEN
                BEGIN
                        SELECT lookup_code
                          INTO x_region_2
	                  FROM fnd_lookup_values
			 WHERE lookup_type    = UPPER('US_STATE')
			   AND language = userenv('LANG')
			   AND UPPER(lookup_code) = UPPER(p_region_2) -- Added for Dinesh Integra
			   --AND UPPER(meaning)    = UPPER(xx_hr_common_pkg.get_mapping_value('US_STATE',p_region_2)) ---Commented Dinesh for Integra
			   AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE);

	                p_region_2 := x_region_2;
	          exception
	            when no_data_found then
	              x_error_code := xx_emf_cn_pkg.cn_rec_err;
	              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.cn_low
	                                   ,p_category    => 'DV_US_STATE'
	                                   ,p_error_text  => 'Valid US State not found'
	                                   ,p_record_identifier_1 => COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
	                              --     ,p_record_identifier_2 => p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
	                                   ,p_record_identifier_2 => p_cnv_hdr_rec.unique_id

	                                   );
	            when others then
	              x_sqlerrm  := substr(sqlerrm,1,800);
	              x_error_code := xx_emf_cn_pkg.cn_rec_err;
	              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.cn_low
	                                   ,p_category    => 'DV_US_STATE'
	                                   ,p_error_text  => 'Error in getting State: '||x_sqlerrm
	                                   ,p_record_identifier_1 => COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
	                                  -- ,p_record_identifier_2 => p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
	                                   ,p_record_identifier_2 => p_cnv_hdr_rec.unique_id
	                                   );
                end;
            END IF;

        elsif (p_style = 'MX_GLB') OR (p_style = 'MX')then -- Included check for MX -- Dinesh Integra
            if p_address_line1 is null then
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
  	     	               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.cn_low
  	     	                                    ,p_category    => 'DV_Addr1'
  	     	                                    ,p_error_text  => 'Address Line1 cannot be NULL for Mexican Address'
						   ,p_record_identifier_1 => COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
						--   ,p_record_identifier_2 => p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
						   ,p_record_identifier_2 => p_cnv_hdr_rec.unique_id
						--   ,p_record_identifier_4 => p_country
						   );
            end if;
            IF p_region_1 IS NOT NULL THEN
	                    BEGIN
	                        SELECT lookup_code
	                          INTO x_region_1
	    	                  FROM fnd_lookup_values
	    			 WHERE lookup_type    = UPPER('PER_MX_STATE_CODES')
	    			   AND language = userenv('LANG')
	    			   AND UPPER(lookup_code) = UPPER(p_region_1)  -- Added by Dinesh for Integra
	    			  -- AND UPPER(meaning) = UPPER(xx_hr_common_pkg.get_mapping_value('MX_STATE',p_region_1)) --- Commented by Dinesh for Integra
	    			   AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE);

	                          p_region_1 := x_region_1;

  	                         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, p_region_1);
               	          exception
	    	            when no_data_found then
	    	              x_error_code := xx_emf_cn_pkg.cn_rec_err;
	    	              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.cn_low
	    	                                   ,p_category    => 'DV_MX_STATE'
	    	                                   ,p_error_text  => 'Valid Mexico State not found'
						   ,p_record_identifier_1 => COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
						   --,p_record_identifier_2 => p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
						   ,p_record_identifier_2 => p_cnv_hdr_rec.unique_id
	    	                                   );
	    	            when others then
	    	              x_sqlerrm  := substr(sqlerrm,1,800);
	    	              x_error_code := xx_emf_cn_pkg.cn_rec_err;
	    	              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.cn_low
	    	                                   ,p_category    => 'DV_MX_STATE'
	    	                                   ,p_error_text  => 'Error in getting State: '||x_sqlerrm
						   ,p_record_identifier_1 => COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
						  -- ,p_record_identifier_2 => p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
						   ,p_record_identifier_2 => p_cnv_hdr_rec.unique_id	    	                                   );
	                    end;
            END IF;
        elsif (p_style = 'CA_GLB') then
	  if p_address_line1 is null then
	     x_error_code := xx_emf_cn_pkg.cn_rec_err;
			       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.cn_low
						    ,p_category    => 'DV_Addr1'
						    ,p_error_text  => 'Address Line1 cannot be NULL for Canadian Address'
						   ,p_record_identifier_1 => COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
						   --,p_record_identifier_2 => p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
						   ,p_record_identifier_2 => p_cnv_hdr_rec.unique_id					  );
	  elsif (p_town_or_city is null) then
	      x_error_code := xx_emf_cn_pkg.cn_rec_err;
					       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.cn_low
								    ,p_category    => 'DV_City'
								    ,p_error_text  => 'City cannot be NULL for Canadian Address'
								   ,p_record_identifier_1 => COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
								  -- ,p_record_identifier_2 => p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
								   ,p_record_identifier_2 => p_cnv_hdr_rec.unique_id
					  );
	   end if;
	       IF p_region_1 IS NOT NULL THEN
		    BEGIN
		        SELECT lookup_code
		          INTO x_region_1
			  FROM fnd_lookup_values
			 WHERE lookup_type    = UPPER('CA_PROVINCE')
			   AND language = userenv('LANG')
	    	           AND UPPER(lookup_code) = UPPER(p_region_1)  -- Added by Dinesh for Integra
			  -- AND UPPER(meaning)    = UPPER(xx_hr_common_pkg.get_mapping_value('CA_PROVINCE',p_region_1)) --- Dinesh
			   AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE);

		    p_region_1 := x_region_1;
		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, p_region_1);

		  exception
		    when no_data_found then
		      x_error_code := xx_emf_cn_pkg.cn_rec_err;
		      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.cn_low
					   ,p_category    => 'DV_CA_STATE'
					   ,p_error_text  => 'Valid Canada Province not found'
					   ,p_record_identifier_1 => COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
				          -- ,p_record_identifier_2 => p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
					   ,p_record_identifier_2 => p_cnv_hdr_rec.unique_id
					   );
		    when others then
		      x_sqlerrm  := substr(sqlerrm,1,800);
		      x_error_code := xx_emf_cn_pkg.cn_rec_err;
		      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.cn_low
					   ,p_category    => 'DV_CA_STATE'
					   ,p_error_text  => 'Error in getting State: '||x_sqlerrm
					   ,p_record_identifier_1 => COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
				          -- ,p_record_identifier_2 => p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
					   ,p_record_identifier_2 => p_cnv_hdr_rec.unique_id
					   );
		    end;
            END IF;


        end if;

       return x_error_code;
  end check_mandatory_cloumns;

  -------------------------------------------------------------------------------
  --------------------< get_missing_zipcode >-----------------------------
  -------------------------------------------------------------------------------
  function get_missing_zipcode(p_country     in varchar2
                              ,p_city        in varchar2
                              ,p_state       in varchar2
                              ,p_zip_code    in out nocopy varchar2
                              ) return number is
    x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
    x_sqlerrm      varchar2(1000);
    x_zip_code     varchar2(30);
  begin

      if (p_zip_code     is null
          and p_country   = 'US'
          --and nvl(p_cnv_hdr_rec.addr_attribute1,'@#$') <> 'EXEMP'
          ) then

        begin
          if p_state is not null then
            select zip.zip_start
              into x_zip_code
              from pay_us_city_names  city
                 , pay_us_states      state
                 , pay_us_zip_codes   zip
             where city.state_code           = state.state_code
               and city.city_code            = zip.city_code
               and city.state_code           = zip.state_code
               and upper(city.city_name)     = upper(p_city)
               and upper(state.state_abbrev) = upper(p_state)
               and rownum = 1;
          else
            select zip.zip_start
              into x_zip_code
              from pay_us_city_names  city
                 , pay_us_zip_codes   zip
             where city.city_code            = zip.city_code
               and city.state_code           = zip.state_code
               and upper(city.city_name)     = upper(p_city)
               and rownum = 1;
          end if;  -- if p_state is not null then

          if x_zip_code is not null then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, '--- New Zip code attached '|| x_zip_code ||'--for employee--'|| to_char(p_cnv_hdr_rec.employee_number));
          end if;
          p_zip_code    := x_zip_code;

      exception
        when no_data_found then
          x_error_code := xx_emf_cn_pkg.cn_rec_err;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.cn_low
                               ,p_category    => 'DV_ZIP'
                               ,p_error_text  => 'Valid Zip Code not found'
                               ,p_record_identifier_1 => COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
                               --,p_record_identifier_2 => p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
                               ,p_record_identifier_2 => p_cnv_hdr_rec.unique_id
                               ,p_record_identifier_3 => p_city||':'||p_state
                               );
        when others then
          x_sqlerrm  := substr(sqlerrm,1,800);
          x_error_code := xx_emf_cn_pkg.cn_rec_err;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.cn_low
                               ,p_category    => 'DV_ZIP'
                               ,p_error_text  => 'Error in Zip Code: '||x_sqlerrm
                               ,p_record_identifier_1 => COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
                               --,p_record_identifier_2 => p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
                               ,p_record_identifier_2 => p_cnv_hdr_rec.unique_id
                               ,p_record_identifier_3 => p_city||':'||p_state
                               );
        end;

      end if;  -- if p_zip_code is null and p_country = 'US' and p_cnv_hdr_rec.addr_attribute1 <> 'EXEMP' then

    return x_error_code;
  end get_missing_zipcode;
  -------------------------------------------------------------------------------
  --------------------< get_us_county_from_ora >-----------------------------
  -------------------------------------------------------------------------------
  function get_us_county_from_ora(p_country     in varchar2
                                 ,p_zip_code    in varchar2
                                 ,p_city        in out nocopy varchar2
                                 ,p_county      in out nocopy varchar2
                                 ) return number is
    x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
    x_sqlerrm      varchar2(1000);
    x_city         varchar2(30);
    x_county       varchar2(30);
  begin
    if (p_country = 'US'
        --and nvl(p_cnv_hdr_rec.addr_attribute1,'@#$') <> 'EXEMP'
        ) then

      begin
        select city.city_name
              ,county.county_name
           into x_city, x_county
          from pay_us_city_names  city
             , pay_us_counties    county
             , pay_us_states      state
             , pay_us_zip_codes   zip
         where city.state_code        = state.state_code
           and city.county_code       = county.county_code
           and county.state_code      = state.state_code
           and city.city_code         = zip.city_code
           and city.state_code        = zip.state_code
           and city.county_code       = zip.county_code
           and substr(p_zip_code,1,5) between zip.zip_start and zip.zip_end
           and upper(city.city_name)  = upper(p_city)
           and rownum = 1;
        if p_county <> x_county then
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, p_county||
      '--County does not match to Oracle County--'|| x_county ||'--for employee--'|| to_char(p_cnv_hdr_rec.employee_number));
        end if;
        p_city    := x_city;
        p_county  := x_county;
      exception
        when no_data_found then

         x_error_code := xx_emf_cn_pkg.cn_rec_err;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.cn_low
                               ,p_category    => 'DV_COUNTY'
                               ,p_error_text  => 'Valid County not found'
                               ,p_record_identifier_1 => COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
                          --     ,p_record_identifier_2 => p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
                               ,p_record_identifier_2 => p_cnv_hdr_rec.unique_id
                               ,p_record_identifier_3 => p_city||':'||p_zip_code
                               );

        when others then
          x_sqlerrm  := substr(sqlerrm,1,800);
          x_error_code := xx_emf_cn_pkg.cn_rec_err;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.cn_low
                               ,p_category    => 'DV_COUNTY'
                               ,p_error_text  => 'Error in County: '||x_sqlerrm
                               ,p_record_identifier_1 => COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
                               --,p_record_identifier_2 => p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
                               ,p_record_identifier_2 => p_cnv_hdr_rec.unique_id
                               ,p_record_identifier_3 => p_city||':'||p_zip_code
                               );
      end;

    end if; -- if p_country = 'US' then
    return x_error_code;

  end get_us_county_from_ora;
  -------------------------------------------------------------------------------
  --------------------< get_address_line2 >-----------------------------
  -------------------------------------------------------------------------------
  function get_address_line2(p_style         in varchar2
                            ,p_address_line2    in out nocopy varchar2
                            ,p_address_line3    in out nocopy varchar2
                            ) return number is
    x_error_code          NUMBER         := xx_emf_cn_pkg.cn_success;
    x_sqlerrm             varchar2(1000);
    x_address_style       varchar2(100)  := null;
    x_line3_mandatory     number         := 0;


  begin

  x_address_style := p_style;

  select count(1) into x_line3_mandatory
    from fnd_descr_flex_column_usages a1
   where application_id                = 800
     and descriptive_flexfield_name    = 'Address Structure'
     and descriptive_flex_context_code = x_address_style
     and application_column_name       = 'ADDRESS_LINE3'
     and enabled_flag  = 'Y'
     and required_flag = 'Y';

   if x_line3_mandatory = 0 then
     -- address line3 is not mandatory

     if p_address_line3 is not null then
       p_address_line2 := substr(p_address_line2||', '||p_address_line3,1,49);
       p_address_line3 := null;
     end if;

   end if;

   return x_error_code;

  exception
    when others then
          x_sqlerrm  := substr(sqlerrm,1,800);
          x_error_code := xx_emf_cn_pkg.cn_rec_err;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.cn_low
                               ,p_category    => 'DV_ADDLN2'
                               ,p_error_text  => 'Error in Adderess line2: '||x_sqlerrm
                               ,p_record_identifier_1 => COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
                               --,p_record_identifier_2 => p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
                               ,p_record_identifier_2 => p_cnv_hdr_rec.unique_id
                               --,p_record_identifier_4 => p_country||':'||p_address_line2||', '||p_address_line3
                               );
          return x_error_code;

  end get_address_line2;
  -------------------------------------------------------------------------------
  --- Start of the main function data_validations
  --- This will only have calls to the individual functions.
BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Inside Data-Validations');

      IF UPPER(NVL(p_cnv_hdr_rec.style,'x')) <> 'GENERIC' THEN   --Modified Post CRP3 on 13-Jun-2012
      x_error_code_temp := is_country_valid(p_cnv_hdr_rec.country);
      x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );
      END IF;

      xx_hr_common_pkg.get_ids (
             p_first_name       => p_cnv_hdr_rec.first_name ,
             p_last_name        => p_cnv_hdr_rec.last_name ,
             p_employee_number  => p_cnv_hdr_rec.unique_id, --employee_number , --- Passing the unique id being sent in data file for Integra
             p_npw_number       =>  NULL, --p_cnv_hdr_rec.npw_number,      --- Passing null because unique id in previous parameter takes care of unique identification
             p_business_group_name    =>  p_cnv_hdr_rec.business_group_name,
             p_person_type      => NULL,
             p_date_of_birth    => p_cnv_hdr_rec.date_of_birth ,
	     p_source_prog      => 'EMPADDR VAL',
             p_person_id        => p_cnv_hdr_rec.person_id ,
             p_party_id         => p_cnv_hdr_rec.party_id ,
             p_error_code       => x_error_code_temp
             ) ;

        IF p_cnv_hdr_rec.person_id IS NULL THEN
	   x_error_code_temp:= get_contact_id (p_cnv_hdr_rec.first_name -- contact fname
	                                       ,p_cnv_hdr_rec.last_name -- contact lname
					       ,p_cnv_hdr_rec.date_of_birth -- contact dob
					       ,p_cnv_hdr_rec.unique_id  -- Adde by Dinesh Integra
					       ,p_cnv_hdr_rec.business_group_name
					       ,p_cnv_hdr_rec.person_id  -- get contact person id
					       ,p_cnv_hdr_rec.party_id);
	END IF;

        x_error_code := find_max(x_error_code,   x_error_code_temp);


     -- commented on 19-jun-2012 post CPR3 for integra
     --IF p_cnv_hdr_rec.style IS NOT NULL
     --THEN
     --       x_error_code_temp := get_address_line2(p_style      => p_cnv_hdr_rec.style        -- in
     --                                      ,p_address_line2  => p_cnv_hdr_rec.address_line2  -- in/out
     --                                      ,p_address_line3  => p_cnv_hdr_rec.address_line3  -- in/out
     --                                      );
     --	     x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );
     --END IF;



     IF p_cnv_hdr_rec.style IS NOT NULL
     THEN

     x_error_code_temp := check_mandatory_cloumns(p_style          => p_cnv_hdr_rec.style
                                                 ,p_country        => p_cnv_hdr_rec.country
                                                 ,p_address_line1  => p_cnv_hdr_rec.address_line1
                                                 ,p_town_or_city   => p_cnv_hdr_rec.town_or_city
                                                 ,p_region_1       => p_cnv_hdr_rec.region_1
                                                 ,p_region_2       => p_cnv_hdr_rec.region_2
                                                );
     ELSE

      x_error_code_temp := xx_emf_cn_pkg.cn_rec_err;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.cn_low
					   ,p_category    => 'DV_STYLE_MISSING'
					   ,p_error_text  => 'Mandatory value Address Style missing'
					   ,p_record_identifier_1 => COALESCE(p_cnv_hdr_rec.employee_number,p_cnv_hdr_rec.npw_number,p_cnv_hdr_rec.applicant_number)
				          -- ,p_record_identifier_2 => p_cnv_hdr_rec.last_name||', '||p_cnv_hdr_rec.first_name
					   ,p_record_identifier_2 => p_cnv_hdr_rec.unique_id
					   );
     END IF;
---

     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Region_1 '|| p_cnv_hdr_rec.region_1);

     x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );
     xx_emf_pkg.propagate_error ( x_error_code_temp );

     RETURN x_error_code;
  EXCEPTION
  WHEN xx_emf_pkg.g_e_rec_error THEN
    x_error_code := xx_emf_cn_pkg.cn_rec_err;
    RETURN x_error_code;
  WHEN xx_emf_pkg.g_e_prc_error THEN
    x_error_code := xx_emf_cn_pkg.cn_prc_err;
    RETURN x_error_code;
  WHEN others THEN
    --x_sqlerrm := substr(sqlerrm,1,200);
    x_error_code := xx_emf_cn_pkg.cn_rec_err;
    RETURN x_error_code;
  END data_validations;
  --**********************************************************************
  --Function to Post Validations.
  --**********************************************************************
  FUNCTION post_validations
              RETURN NUMBER
  IS
         x_error_code      NUMBER := xx_emf_cn_pkg.cn_success;
         x_error_code_temp NUMBER := xx_emf_cn_pkg.cn_success;
  BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,  'Inside Post-Validations');
    RETURN x_error_code;
  EXCEPTION
  WHEN xx_emf_pkg.g_e_rec_error THEN
    x_error_code := xx_emf_cn_pkg.cn_rec_err;
    RETURN x_error_code;
  WHEN xx_emf_pkg.g_e_prc_error THEN
    x_error_code := xx_emf_cn_pkg.cn_prc_err;
    RETURN x_error_code;
  WHEN others THEN
    x_error_code := xx_emf_cn_pkg.cn_rec_err;
    RETURN x_error_code;
  END post_validations;
--**********************************************************************
--Function to Data Derivations.
--**********************************************************************
  FUNCTION data_derivations(p_cnv_pre_std_hdr_rec IN OUT NOCOPY
                                xx_hr_emp_add_conversion_pkg.G_XX_HR_ADD_CNV_PRE_REC_TYPE
                           )
                           RETURN NUMBER
  IS
         x_error_code         NUMBER := xx_emf_cn_pkg.cn_success;
--**********************************************************************
--Function to get Valid Address Type.
--**********************************************************************
  FUNCTION get_address_type_valid(p_address_type  IN OUT NOCOPY VARCHAR2
                                 ) RETURN NUMBER
  IS
           x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
           x_sqlerrm    VARCHAR2(2000);
  BEGIN
    BEGIN
      IF p_address_type IS NOT NULL THEN
        SELECT lookup_code
          INTO p_address_type
          FROM fnd_lookup_values
         WHERE lookup_type    = UPPER('ADDRESS_TYPE')
           AND language = userenv('LANG')
           --AND UPPER(meaning)    = UPPER(xx_hr_common_pkg.get_mapping_value('ADDRESS_TYPE',p_address_type)) -- Dinesh
           AND lookup_code    = UPPER(p_address_type) -- Integra Data file provides lookup code. This chekcs for the validity of that
           AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE);
        END IF;
    EXCEPTION
    WHEN TOO_MANY_ROWS THEN
      x_error_code := xx_emf_cn_pkg.cn_rec_err;
      xx_emf_pkg.error (p_severity            => xx_emf_cn_pkg.cn_low
                           ,p_category            => xx_emf_cn_pkg.cn_valid
                           ,p_error_text          => 'Multiple Address Types found'
			    ,p_record_identifier_1 =>   COALESCE(p_cnv_pre_std_hdr_rec.employee_number,p_cnv_pre_std_hdr_rec.npw_number,p_cnv_pre_std_hdr_rec.applicant_number)
			--    ,p_record_identifier_2 =>   p_cnv_pre_std_hdr_rec.last_name||', '||p_cnv_pre_std_hdr_rec.first_name
			    ,p_record_identifier_2 =>   p_cnv_pre_std_hdr_rec.unique_id
			    ,p_record_identifier_3 =>   'Address Type-'||p_address_type
                           );
    WHEN NO_DATA_FOUND THEN
      x_error_code := xx_emf_cn_pkg.cn_rec_err;
      xx_emf_pkg.error (p_severity            => xx_emf_cn_pkg.cn_low
                           ,p_category            => xx_emf_cn_pkg.cn_valid
                           ,p_error_text          => 'No Address Type found'
			    ,p_record_identifier_1 =>   COALESCE(p_cnv_pre_std_hdr_rec.employee_number,p_cnv_pre_std_hdr_rec.npw_number,p_cnv_pre_std_hdr_rec.applicant_number)
			   -- ,p_record_identifier_2 =>   p_cnv_pre_std_hdr_rec.last_name||', '||p_cnv_pre_std_hdr_rec.first_name
			    ,p_record_identifier_2 =>   p_cnv_pre_std_hdr_rec.unique_id
			    ,p_record_identifier_3 =>   'Address Type-'||p_address_type
                           );
    WHEN OTHERS THEN
      x_sqlerrm := substr(sqlerrm,1,200);
      x_error_code := xx_emf_cn_pkg.cn_rec_err;
      xx_emf_pkg.error (p_severity            => xx_emf_cn_pkg.cn_low
                           ,p_category            => xx_emf_cn_pkg.cn_valid
                           ,p_error_text          => 'Address Type:'||x_sqlerrm
			    ,p_record_identifier_1 =>   COALESCE(p_cnv_pre_std_hdr_rec.employee_number,p_cnv_pre_std_hdr_rec.npw_number,p_cnv_pre_std_hdr_rec.applicant_number)
			--    ,p_record_identifier_2 =>   p_cnv_pre_std_hdr_rec.last_name||', '||p_cnv_pre_std_hdr_rec.first_name
			    ,p_record_identifier_2 =>   p_cnv_pre_std_hdr_rec.unique_id
			    ,p_record_identifier_3 =>   'Address Type-'||p_address_type
                           );
    END;
                                                                  -- comment removed
  RETURN x_error_code;
  EXCEPTION
  WHEN OTHERS THEN
    x_sqlerrm := substr(sqlerrm,1,200);
    IF x_error_code = xx_emf_cn_pkg.cn_success THEN
      x_error_code := xx_emf_cn_pkg.cn_rec_err;
      xx_emf_pkg.error (p_severity            => xx_emf_cn_pkg.cn_low
                           ,p_category            => xx_emf_cn_pkg.cn_valid
                           ,p_error_text          => 'Address Type:'||x_sqlerrm
			    ,p_record_identifier_1 =>   COALESCE(p_cnv_pre_std_hdr_rec.employee_number,p_cnv_pre_std_hdr_rec.npw_number,p_cnv_pre_std_hdr_rec.applicant_number)
			    --,p_record_identifier_2 =>   p_cnv_pre_std_hdr_rec.last_name||', '||p_cnv_pre_std_hdr_rec.first_name
			    ,p_record_identifier_2 =>   p_cnv_pre_std_hdr_rec.unique_id
			    ,p_record_identifier_3 =>   'Address Type-'||p_address_type
                           );
    END IF;
    RETURN x_error_code;
  END get_address_type_valid ;
--**********************************************************************
--Function to get Address Style.
--**********************************************************************
  FUNCTION get_style( p_country         IN         VARCHAR2
                    , p_style          OUT  NOCOPY VARCHAR2
                     ) RETURN NUMBER  IS
           x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
           x_sqlerrm    VARCHAR2(2000);
  BEGIN
    BEGIN
      IF (p_country IS NOT NULL

          )  THEN

        begin
	   xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, p_cnv_pre_std_hdr_rec.employee_number);
          SELECT descriptive_flex_context_code
            INTO p_style
            FROM fnd_descr_flex_contexts_tl
           WHERE descriptive_flexfield_name    = 'Address Structure'
             AND language                      = userenv('LANG')
             AND application_id                = 800
             AND descriptive_flex_context_code = upper(p_country);

              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, p_cnv_pre_std_hdr_rec.employee_number);

        exception
          when no_data_found then
            SELECT descriptive_flex_context_code
              INTO p_style
              FROM fnd_descr_flex_contexts_tl
             WHERE descriptive_flexfield_name    = 'Address Structure'
               AND language                      = userenv('LANG')
               AND application_id                = 800
               and descriptive_flex_context_name = 'United States (International)';
        end;
      END IF; -- IF p_country IS NOT NULL THEN

    EXCEPTION
    WHEN TOO_MANY_ROWS THEN
      x_error_code := xx_emf_cn_pkg.cn_rec_err;
      xx_emf_pkg.error (p_severity            => xx_emf_cn_pkg.cn_low
                           ,p_category            => xx_emf_cn_pkg.cn_valid
                           ,p_error_text          => 'Multiple Address Style found'
			    ,p_record_identifier_1 =>   COALESCE(p_cnv_pre_std_hdr_rec.employee_number,p_cnv_pre_std_hdr_rec.npw_number,p_cnv_pre_std_hdr_rec.applicant_number)
			   -- ,p_record_identifier_2 =>   p_cnv_pre_std_hdr_rec.last_name||', '||p_cnv_pre_std_hdr_rec.first_name
			    ,p_record_identifier_2 =>   p_cnv_pre_std_hdr_rec.unique_id
			    ,p_record_identifier_3 =>   'Country-'||p_country                           );
    WHEN NO_DATA_FOUND THEN
      x_error_code := xx_emf_cn_pkg.cn_rec_err;
      xx_emf_pkg.error (p_severity            => xx_emf_cn_pkg.cn_low
                           ,p_category            => xx_emf_cn_pkg.cn_valid
                           ,p_error_text          => 'No Address Style found'
			    ,p_record_identifier_1 =>   COALESCE(p_cnv_pre_std_hdr_rec.employee_number,p_cnv_pre_std_hdr_rec.npw_number,p_cnv_pre_std_hdr_rec.applicant_number)
			    --,p_record_identifier_2 =>   p_cnv_pre_std_hdr_rec.last_name||', '||p_cnv_pre_std_hdr_rec.first_name
			    ,p_record_identifier_2 =>   p_cnv_pre_std_hdr_rec.unique_id
			    ,p_record_identifier_3 =>   'Country-'||p_country                           );
    WHEN OTHERS THEN
      x_sqlerrm := substr(sqlerrm,1,200);
      x_error_code := xx_emf_cn_pkg.cn_rec_err;
      xx_emf_pkg.error (p_severity            => xx_emf_cn_pkg.cn_low
                           ,p_category            => xx_emf_cn_pkg.cn_valid
                           ,p_error_text          => 'Address Style:'||x_sqlerrm
			    ,p_record_identifier_1 =>   COALESCE(p_cnv_pre_std_hdr_rec.employee_number,p_cnv_pre_std_hdr_rec.npw_number,p_cnv_pre_std_hdr_rec.applicant_number)
			    --,p_record_identifier_2 =>   p_cnv_pre_std_hdr_rec.last_name||', '||p_cnv_pre_std_hdr_rec.first_name
			    ,p_record_identifier_2 =>   p_cnv_pre_std_hdr_rec.unique_id
			    ,p_record_identifier_3 =>   'Country-'||p_country
                           );
    END;

  RETURN x_error_code;

  EXCEPTION
  WHEN OTHERS THEN
    x_sqlerrm := substr(sqlerrm,1,200);
    IF x_error_code = xx_emf_cn_pkg.cn_success THEN
      x_error_code := xx_emf_cn_pkg.cn_rec_err;
      xx_emf_pkg.error (p_severity            => xx_emf_cn_pkg.cn_low
                           ,p_category            => xx_emf_cn_pkg.cn_valid
                           ,p_error_text          => 'Address Style:'||x_sqlerrm
			    ,p_record_identifier_1 =>   COALESCE(p_cnv_pre_std_hdr_rec.employee_number,p_cnv_pre_std_hdr_rec.npw_number,p_cnv_pre_std_hdr_rec.applicant_number)
			    --,p_record_identifier_2 =>   p_cnv_pre_std_hdr_rec.last_name||', '||p_cnv_pre_std_hdr_rec.first_name
			    ,p_record_identifier_2 =>   p_cnv_pre_std_hdr_rec.unique_id
			    ,p_record_identifier_3 =>   'Country-'||p_country
                           );
    END IF;
    RETURN x_error_code;
  END get_style ;
-------------------------------------------------------------------------------
 ----------------data_derivations begins--------------------------------------------------------------
  BEGIN
   x_error_code := get_address_type_valid(p_cnv_pre_std_hdr_rec.address_type);

   -- Integra does not want to derive the address style based on country.
   --x_error_code := get_style(p_cnv_pre_std_hdr_rec.country, p_cnv_pre_std_hdr_rec.style);

   RETURN x_error_code;
 EXCEPTION
  WHEN xx_emf_pkg.g_e_rec_error THEN
    x_error_code := xx_emf_cn_pkg.cn_rec_err;
    RETURN x_error_code;
  WHEN xx_emf_pkg.g_e_prc_error THEN
    x_error_code := xx_emf_cn_pkg.cn_prc_err;
    RETURN x_error_code;
  WHEN others THEN
    x_error_code := xx_emf_cn_pkg.cn_rec_err;
    RETURN x_error_code;
  END data_derivations;

END XX_HR_EMP_ADD_CNV_VAL_PKG;
/
