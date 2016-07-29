DROP PACKAGE BODY APPS.XX_QA_SCAR_RPT_XMLP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_QA_SCAR_RPT_XMLP_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 11-DEC-2012
 File Name     : XXQASCARRPT.pkb
 Description   : This script creates the body of the package
                 xx_qa_scar_rpt_xmlp_pkg to create code for after
                 parameter form trigger
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 11-DEC-2012 Sharath Babu          Initial Development
 06-SEP-2013 Francis               Address function has been added
*/
----------------------------------------------------------------------
   FUNCTION AFTERPFORM RETURN BOOLEAN
   IS
   BEGIN
      BEGIN
         SELECT view_name
           INTO lp_q_scar_v
           FROM qa_plans_v
          WHERE name = p_scar_pname;
      EXCEPTION
         WHEN OTHERS THEN
         NULL;
      END;
      BEGIN
         SELECT view_name
           INTO lp_q_ncmr_v
           FROM qa_plans_v
          WHERE name = p_ncmr_pname;
      EXCEPTION
         WHEN OTHERS THEN
         NULL;
      END;
      RETURN (TRUE);
   END AFTERPFORM;

   FUNCTION ADDRESS(ln_location_id NUMBER) RETURN VARCHAR2
   IS
     l_return_status         VARCHAR2(100);
     l_msg_count             NUMBER := 0;
     l_msg_data              VARCHAR2(4000);
     l_formatted_address     VARCHAR2(4000);
     l_formatted_lines_cnt   NUMBER := 0;
     l_formatted_address_tbl hz_format_pub.string_tbl_type;
     l_country               VARCHAR(10):=NULL;
     l_style_format_code     VARCHAR2(50);
BEGIN
   SELECT country INTO l_country from HZ_LOCATIONS WHERE location_id =ln_location_id;
   IF l_country='DE' THEN
      l_style_format_code:='POSTAL_ADDR_DE';
   ELSE
     l_style_format_code:='POSTAL_ADDR_US';
   END IF;

   hz_format_pub.format_address (
   -- input parameters
   p_location_id          => ln_location_id,
   p_style_format_code    =>l_style_format_code,
   p_line_break           =>CHR(10),
   x_return_status        => l_return_status,
   x_msg_count            => l_msg_count,
   x_msg_data             => l_msg_data,
   x_formatted_address    => l_formatted_address,
   x_formatted_lines_cnt  => l_formatted_lines_cnt,
   x_formatted_address_tbl=> l_formatted_address_tbl
                                );
  IF l_formatted_address_tbl.COUNT > 0 THEN
     FOR l_ct IN 1..l_formatted_address_tbl.COUNT
     LOOP
     IF l_ct=1 THEN
        l_formatted_address:= trim(l_formatted_address_tbl(l_ct));
     ELSIF l_ct=2 then
        IF l_style_format_code='POSTAL_ADDR_US' then
           l_formatted_address:=trim(l_formatted_address)||CHR(10)||trim(l_formatted_address_tbl(l_ct));
        ELSE
           NULL;
        END IF;
     ELSE
        l_formatted_address:=trim(l_formatted_address)||CHR(10)||trim(l_formatted_address_tbl(l_ct));
     END IF;

      END LOOP;
   END IF;
return (l_formatted_address);
EXCEPTION
WHEN OTHERS THEN
return NULL;
END;
END XX_QA_SCAR_RPT_XMLP_PKG;
/
