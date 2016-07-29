DROP PACKAGE BODY APPS.XX_GL_ASSN_DIV_TO_GL_ACCT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_GL_ASSN_DIV_TO_GL_ACCT_PKG" 
-----------------------------------------------------------------------------------

/*$Header:  XXGLSSNDIVTOGLACCTPKG.pkb 1.0 2012/03/22 12:00:00 dparida noship $ */
/*
 Created By   : IBM Development Team
 Creation Date: 16-Mar-2012
 Filename     : XXGLSSNDIVTOGLACCTPKG.pkb
 Description  : This Package body is used for update procedures
                (attribut1,attribute2)for the table GL_CODE_COMBINATIONS

 Change History:

 Date        Version#      Name                         Remarks
 ----------- --------    ---------------        ---------------------------------------
 16 -Mar-2012  1.0     IBM Development Team         Initial development.
 26-Mar-1212   1.1     IBM Development Team    Added the logic for Process Setup Form
*/

-----------------------------------------------------------------------------------

AS

  /***********************************************************************************
       This function is used covert values in 100s. It will take  any numeric value
        as input paramenetr and convet it into 100 by the use of floor function
       Parameter :
       p_value --> the numeric value which need to convert into 100.
  *************************************************************************************/

   FUNCTION convert_to_100 (p_value IN NUMBER)
   RETURN NUMBER
   IS

   BEGIN
      RETURN floor(p_value/100)*100;

   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while converting segment value to 100'|| p_value);
   END;



  /***********************************************************************************
       This function is used to fractionalized the concatednated segments value.It takes the
       concatenated segments as input parameter and gives out 9 segments separated by '-'.
       p_con_seg --> concatenated_segments which segments needed to fractionalized.
  *************************************************************************************/

   FUNCTION segment_fractions(p_con_seg IN VARCHAR2)

   RETURN gl_code_combinations_kfv%ROWTYPE
   IS
   x_str VARCHAR2(500);
   x_res gl_code_combinations_kfv%ROWTYPE;

   x_counter NUMBER;
   i  NUMBER := 1;
   j  NUMBER := 1;
   x_val VARCHAR2(100);


   BEGIN
       x_str := p_con_seg ||'-';
        FOR x_counter IN 1..8

        LOOP
           j:= instr(x_str,'-',1,x_counter)-1;

           IF(i<=j) THEN

           x_val := substr(x_str,i,j-i+1);

                 IF(x_counter = 1) THEN
                  x_res.SEGMENT1 := x_val;
                 ELSIF (x_counter=2) THEN
                  x_res.SEGMENT2 := x_val;
                 ELSIF(x_counter = 3) THEN
                  x_res.SEGMENT3 := x_val;
                ELSIF(x_counter = 4) THEN
                  x_res.SEGMENT4 := x_val;
                 ELSIF(x_counter = 5) THEN
                  x_res.SEGMENT5 := x_val;
                ELSIF(x_counter = 6) THEN
                  x_res.SEGMENT6 := x_val;
                ELSIF(x_counter = 7) THEN
                  x_res.SEGMENT7 := x_val;
                ELSIF(x_counter = 8) THEN
                  x_res.SEGMENT8 := x_val;
               /*ELSIF(x_counter = 9) THEN
                 x_res.SEGMENT9 := x_val;  */ ---modified for 8 Segment COA
                 END IF;

            END IF;

          i := j+2;
        END LOOP;

    RETURN x_res;

   EXCEPTION
             WHEN OTHERS THEN

             xx_emf_pkg.error  (p_severity    => xx_emf_cn_pkg.CN_LOW
   					 ,p_category    => xx_emf_cn_pkg.CN_PRC_ERR
   					 ,p_error_text  => 'Error While fetching Code combination '|| p_con_seg
   					 ,p_record_identifier_1 => p_con_seg
   			      );


   END segment_fractions ;



   /***********************************************************************************
       This function will take lookup type and lookup code as input parameter and return
       the corresponding tag value of that lookup :
       p_lookup_type --> lookup_type  whose tag value is needed.
       p_lookup_code --> lookup_code  whose tag value is needed.
   *************************************************************************************/
   FUNCTION lookup_val ( p_lookup_type IN VARCHAR2
                        ,p_lookup_code IN VARCHAR2
                       )
   RETURN VARCHAR2 IS
   BEGIN
      FOR rec IN ( SELECT *
                     FROM fnd_lookup_values
                    WHERE lookup_type = p_lookup_type
                      AND lookup_code = p_lookup_code
                      AND language = 'US'
                      AND enabled_flag = 'Y'
                      AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE-1)
                                      AND NVL(end_date_active,SYSDATE+1)
                 )
      LOOP
         RETURN rec.tag;
      END LOOP;

      RETURN NULL;

   EXCEPTION
      WHEN OTHERS THEN
         RETURN NULL;
   END lookup_val;


   /***********************************************************************************
       This procedure will execute when user do not enter any value for DFF segment and
       tag value get populated according to the lookup processing order and process mode.

       p_gl_cc_rec --> Recod for code combination which get selected between high and
       low account value entered by user
       p_lookup --> lookup_code as enterd by user for specific lookup or derived by lookup
                    processing logic.
       p_process_mode --> process mode enterd by user either 'Update' or 'Replace'
    *************************************************************************************/
   PROCEDURE lookup_processing ( p_gl_cc_rec    IN OUT gl_code_combinations_kfv%ROWTYPE
                                ,p_lookup       IN VARCHAR2
                                ,p_process_mode IN VARCHAR2
                               )
   IS

    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

      -- Cursor to get the processing order
      CURSOR c_lookup_orders
      IS
      SELECT *
        FROM fnd_lookup_values
       WHERE lookup_type = 'INTG_DIVISION_ORDER'
         AND lookup_code = NVL(p_lookup,lookup_code)
         AND language = 'US'
         AND enabled_flag = 'Y'
         AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE-1)
                         AND NVL(end_date_active,SYSDATE+1)
       ORDER BY tag;

      l_div_reg      fnd_lookup_values.tag%TYPE := NULL;
      l_div_prod     fnd_lookup_values.tag%TYPE := NULL;
      l_div_prod_tmp fnd_lookup_values.tag%TYPE := NULL;

   BEGIN
       -- validate tag values according to processing order of lookups
       -- modified by Ashish on 06/12/2012 according to 8 segment CoA
      FOR lookups IN c_lookup_orders
      LOOP
         IF lookups.lookup_code = 'INTG_DIV_REGION_LOOKUP_1' THEN
            l_div_reg := lookup_val( 'INTG_DIV_REGION_LOOKUP_1'
                                    ,convert_to_100(p_gl_cc_rec.segment6)
                                   );


         -- For Company/ Entity Segment
         ELSIF lookups.lookup_code = 'INTG_DIV_PROD_03' THEN
            l_div_prod_tmp := lookup_val('INTG_DIV_PROD_03',p_gl_cc_rec.segment1);

            IF l_div_prod_tmp IS NOT NULL THEN
               l_div_prod := l_div_prod_tmp;
            END IF;

         -- For Department Segment
         -- Modified by Ashish on 10-May-2012
         ELSIF lookups.lookup_code = 'INTG_DIV_PROD_02' THEN
            l_div_prod_tmp := lookup_val('INTG_DIV_PROD_02'
                                       ,convert_to_100(p_gl_cc_rec.segment2)
                                       );

            IF l_div_prod_tmp IS NOT NULL THEN
               l_div_prod := l_div_prod_tmp;
            END IF;

         -- For Product Segment
         -- Modified by Ashish on 10-May-2012
         ELSIF lookups.lookup_code = 'INTG_DIV_PROD_01' THEN
            l_div_prod_tmp := lookup_val('INTG_DIV_PROD_01'
                                         ,convert_to_100(p_gl_cc_rec.segment5)
                                         );

            IF l_div_prod_tmp IS NOT NULL THEN
               l_div_prod := l_div_prod_tmp;
            END IF;
         END IF;
      END LOOP;

      -- Process Mode = Update
      IF p_process_mode = '1' THEN
         p_gl_cc_rec.attribute2 := NVL(p_gl_cc_rec.attribute2,l_div_reg);
         p_gl_cc_rec.attribute1 := NVL(p_gl_cc_rec.attribute1,l_div_prod);

      -- Process mode = '2' (Replace)
      ELSE
         p_gl_cc_rec.attribute2 := NVL(l_div_reg,p_gl_cc_rec.attribute2);
         p_gl_cc_rec.attribute1 := NVL(l_div_prod,p_gl_cc_rec.attribute1);

      END IF;

 EXCEPTION
     WHEN OTHERS THEN
         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
					 ,p_category    => xx_emf_cn_pkg.CN_PRC_ERR
					 ,p_error_text  => 'Error While fetching Code combination '|| p_gl_cc_rec.concatenated_segments
					 ,p_record_identifier_1 => p_gl_cc_rec.concatenated_segments
			      );
             x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
             xx_emf_pkg.propagate_error(x_error_code);

  END lookup_processing;

   /***********************************************************************************
       This procedure will be executed as a concurrent program and this will invoke
       programs to update the two DFF Segments acoording to the parameter entered
       by the user.
       p_coa_id       --> Charts_of_accounts_id,Maddatory parameter, which is populated
                          with default value
       p_process_mode --> Process Mode,Mandatory Parameter,have two value either 'Upadate'
                          or 'Replce'
       p_low_acct    --> Low Account,Optional Parameter,begining account combination.
       p_high_acct   --> High Account,Optional Parameter,ending account combination.
       p_lookup      --> Lookup value,Optional Parameter,if upadate for specific lookup.
       p_div_prod_val -->Div Prod Value,Optional Parameter,if entered by user then
                         upadate DFF with this value
       p_div_geo_region Div Geo Region Value,Optional Parameter,if entered by user then
                         upadate DFF with this value
   *************************************************************************************/
   PROCEDURE main ( o_errbuff          OUT VARCHAR2
                   ,o_retcode          OUT VARCHAR2
                   ,p_coa_id         IN NUMBER
                   ,p_process_mode   IN VARCHAR2
                   ,p_low_acct       IN VARCHAR2
                   ,p_high_acct      IN VARCHAR2
                   ,p_lookup         IN VARCHAR2
                   ,p_div_prod_val   IN VARCHAR2
                   ,p_div_geo_region IN varchar2
                   )
   IS
      rec_cc_low  gl_code_combinations_kfv%ROWTYPE;
      rec_cc_high gl_code_combinations_kfv%ROWTYPE;
      x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_total_cnt NUMBER := 0;
      x_success_cnt NUMBER := 0;
      x_warn_cnt NUMBER := 0;
      x_error_cnt  NUMBER := 0;
   BEGIN
      -- Initialize the out parameters for normal completion
      o_errbuff := NULL;
      o_retcode := '0';

      -- Set the environment
      x_error_code := xx_emf_pkg.set_env;

      -- write message to concurrent log
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'INPUT PARAMETERS');
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'-----------------------------');
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'COA_ID : '|| p_coa_id);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'PROCESS_MODE : '|| p_process_mode);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'LOW_ACCOUNT : '|| p_low_acct );
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'HIGH_ACCOUNT : '|| p_high_acct);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'LOOKUP_NAME : '|| p_lookup);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'DIV PROD VALUE : '|| p_div_prod_val);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'DIV GEO REGION VALUE : '|| p_div_geo_region);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'-----------------------------');



      IF p_low_acct IS NOT NULL THEN

            rec_cc_low := segment_fractions(p_low_acct);

      END IF;


      IF p_high_acct IS NOT NULL THEN

            rec_cc_high := segment_fractions(p_high_acct);

      END IF;

      -- Fetch all the code combinations between the range
      FOR acct IN ( SELECT *
                      FROM gl_code_combinations_kfv
                     WHERE chart_of_accounts_id = p_coa_id
                       AND segment1 BETWEEN NVL(rec_cc_low.segment1,segment1) AND NVL(rec_cc_high.segment1,segment1)
                       AND segment2 BETWEEN NVL(rec_cc_low.segment2,segment2) AND NVL(rec_cc_high.segment2,segment2)
                       AND segment3 BETWEEN NVL(rec_cc_low.segment3,segment3) AND NVL(rec_cc_high.segment3,segment3)
                       AND segment4 BETWEEN NVL(rec_cc_low.segment4,segment4) AND NVL(rec_cc_high.segment4,segment4)
                       AND segment5 BETWEEN NVL(rec_cc_low.segment5,segment5) AND NVL(rec_cc_high.segment5,segment5)
                       AND segment6 BETWEEN NVL(rec_cc_low.segment6,segment6) AND NVL(rec_cc_high.segment6,segment6)
                       AND segment7 BETWEEN NVL(rec_cc_low.segment7,segment7) AND NVL(rec_cc_high.segment7,segment7)
                       AND segment8 BETWEEN NVL(rec_cc_low.segment8,segment8) AND NVL(rec_cc_high.segment8,segment8)
                      --- AND segment9 BETWEEN NVL(rec_cc_low.segment9,segment9) AND NVL(rec_cc_high.segment9,segment9) ---modified for 8 segment COA
                  )


     LOOP
         BEGIN

         x_total_cnt := x_total_cnt + 1;
         IF (p_div_prod_val IS NULL) AND (p_div_geo_region IS NULL) THEN
            -- Lookup processing
            lookup_processing( p_gl_cc_rec    => acct
                              ,p_lookup       => p_lookup
                              ,p_process_mode => p_process_mode
                              );
         ELSE
            IF p_process_mode = '1' THEN -- Update
               acct.attribute2 := NVL(acct.attribute2,p_div_geo_region);
               acct.attribute1 := NVL(acct.attribute1,p_div_prod_val);



            ELSE -- Process mode = '2' (Replace)
                 acct.attribute2 := NVL(p_div_geo_region,acct.attribute2);
                 acct.attribute1 := NVL(p_div_prod_val,acct.attribute1);


            END IF;
         END IF;

         -- Update the table

         BEGIN

           UPDATE gl_code_combinations
               SET attribute2 = acct.attribute2
                  ,attribute1 = acct.attribute1
             WHERE code_combination_id = acct.code_combination_id
               AND chart_of_accounts_id = acct.chart_of_accounts_id;
               x_success_cnt := x_success_cnt + 1;
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'DFF segments for Account : '||acct.concatenated_segments ||' has been successfully processed');

         EXCEPTION
         WHEN OTHERS
         THEN
             x_error_cnt := x_error_cnt + 1;
             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while updating DFF Segmants : '|| acct.concatenated_segments||'. '||SQLERRM);
             xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
					 ,p_category    => xx_emf_cn_pkg.CN_PRC_ERR
					 ,p_error_text  => 'Error while updating DFF Segmants '
					 ,p_record_identifier_1 => acct.concatenated_segments
			      );
             x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
             xx_emf_pkg.propagate_error(x_error_code);
         END;


       EXCEPTION
          WHEN xx_emf_pkg.G_E_REC_ERROR
           THEN
             xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.CN_REC_ERR);
       END;
      END LOOP;

      -- when no record selected

      IF x_total_cnt = 0 THEN
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No Record selected between range');
      END IF;

      xx_emf_pkg.update_recs_cnt
                 (
                   p_total_recs_cnt => x_total_cnt,
                   p_success_recs_cnt => x_success_cnt,
                   p_warning_recs_cnt => x_warn_cnt,
                   p_error_recs_cnt => x_error_cnt
                 );
        xx_emf_pkg.create_report;

   EXCEPTION
      WHEN xx_emf_pkg.G_E_ENV_NOT_SET THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Checking if this is OK');
         o_retcode := xx_emf_cn_pkg.CN_REC_ERR;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.G_E_REC_ERROR THEN
           o_retcode := xx_emf_cn_pkg.CN_REC_ERR;
           xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
           o_retcode := xx_emf_cn_pkg.CN_PRC_ERR;
           xx_emf_pkg.create_report;
      WHEN OTHERS THEN
         o_retcode := xx_emf_cn_pkg.CN_PRC_ERR;
         xx_emf_pkg.create_report;
   END main;

END XX_GL_ASSN_DIV_TO_GL_ACCT_PKG;
/
