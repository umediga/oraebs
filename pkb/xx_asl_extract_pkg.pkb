DROP PACKAGE BODY APPS.XX_ASL_EXTRACT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_ASL_EXTRACT_PKG" 
IS
   ----------------------------------------------------------------------
   /*
    Created By    : Renjith
    Creation Date : 13-Jul-2012
    File Name     : XX_ASL_EXTRACT_PKG.pkb
    Description   : This script creates the body of the package
                    xx_asl_extract_pkg
    Change History:
    Date        Name                  Remarks
    ----------- -------------         -----------------------------------
    13-Jul-2012 Renjith               Initial Version
    26-Sep-2012 Renjith               Commented order by
   */
    ----------------------------------------------------------------------
   PROCEDURE data_validation ( p_approved_vendor IN    VARCHAR2
                              ,p_operating_unit  IN    NUMBER)
   IS
      CURSOR c_vendor
      IS
      SELECT  DISTINCT
              vendor
        FROM  xx_asl_data
       WHERE  approved_vendor = p_approved_vendor;

      CURSOR c_part
      IS
      SELECT  DISTINCT
              part_number
        FROM  xx_asl_data
       WHERE  approved_vendor = p_approved_vendor;

        x_vendor_id NUMBER;
        x_part      VARCHAR2(40);

   BEGIN
     FND_FILE.PUT_LINE( FND_FILE.LOG,'Vendors Not found');
     FND_FILE.PUT_LINE( FND_FILE.LOG,'-----------------------------------');
     FOR vendor_rec IN c_vendor LOOP
        BEGIN
          SELECT  DISTINCT vendor_id
            INTO  x_vendor_id
            FROM  ap_supplier_sites_all
           WHERE  attribute2 = vendor_rec.vendor
             AND  org_id  = p_operating_unit;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
             FND_FILE.PUT_LINE( FND_FILE.LOG,vendor_rec.vendor);
        END;
     END LOOP;

     FND_FILE.PUT_LINE( FND_FILE.LOG,' ');
     FND_FILE.PUT_LINE( FND_FILE.LOG,' ');
     FND_FILE.PUT_LINE( FND_FILE.LOG,' ');
     FND_FILE.PUT_LINE( FND_FILE.LOG,'Part Number Not found (Master Org MST)');
     FND_FILE.PUT_LINE( FND_FILE.LOG,'---------------------------------------------------------------------');
     FOR part_rec IN c_part LOOP
        BEGIN
          SELECT  DISTINCT itm.segment1
            INTO  x_part
            FROM  mtl_system_items_b itm
                 ,mtl_parameters prm
           WHERE  itm.organization_id = prm.organization_id
             AND  itm.segment1  = part_rec.part_number
             AND  prm.organization_code = 'MST';
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
             FND_FILE.PUT_LINE( FND_FILE.LOG,part_rec.part_number);
        END;
     END LOOP;
   EXCEPTION
      WHEN OTHERS THEN
          FND_FILE.PUT_LINE( FND_FILE.LOG,'Procedure DATA_VALIDATION -> Unexpected Error ' ||SQLERRM);
   END data_validation;
    ----------------------------------------------------------------------
   --PROCEDURE write_data_file (p_approved_vendor IN  VARCHAR2)
   PROCEDURE write_data_file( x_error_code      OUT   NUMBER
                             ,x_error_msg       OUT   VARCHAR2
                             ,p_file_dir        IN    VARCHAR2
                             ,p_file_name       IN    VARCHAR2
                             ,p_operating_unit  IN    NUMBER
                             ,p_approved_vendor IN    VARCHAR2)
   IS
       CURSOR c_asl_stg
       IS
       SELECT DISTINCT
                dat.part_number
               ,'Direct' business
               ,sup.vendor_name
               ,sup.vendor_id
               ,'QAS' status
               ,sit.attribute2
         FROM   ap_supplier_sites_all sit
               ,ap_suppliers  sup
               ,xx_asl_data   dat
               ,mtl_system_items_b itm
               ,mtl_parameters prm
        WHERE  dat.vendor    = sit.attribute2
          AND  sit.vendor_id = sup.vendor_id
          AND  dat.approved_vendor = p_approved_vendor
          AND  sit.purchasing_site_flag = 'Y'
          AND  itm.organization_id = prm.organization_id
          AND  itm.segment1  = dat.part_number
          AND  prm.organization_code = 'MST'
          AND  sit.org_id  = p_operating_unit;
          --ORDER BY sit.org_id;

       CURSOR c_sit(p_attribute VARCHAR2)
       IS
       SELECT   sit.vendor_site_code
               ,hr.name
         FROM   ap_supplier_sites_all sit
               ,hr_operating_units hr
        WHERE  sit.org_id = hr.organization_id
          AND  sit.attribute2 = p_attribute
          AND  sit.purchasing_site_flag = 'Y'
          AND  sit.org_id  = p_operating_unit;

        x_line_hd         VARCHAR2(4000);
        x_line_lt         VARCHAR2(4000);
        x_file_type       utl_file.file_type;
   BEGIN
       x_file_type := UTL_FILE.FOPEN(p_file_dir,p_file_name,'W', 32767);
       data_validation(p_approved_vendor,p_operating_unit);
       FOR r_asl_rec IN c_asl_stg LOOP
           x_line_hd := NULL;
           x_line_lt := NULL;
           x_line_hd := r_asl_rec.part_number||'|'||r_asl_rec.business||'|'||r_asl_rec.vendor_name;
           FOR r_sit IN c_sit(r_asl_rec.attribute2) LOOP
              IF x_line_lt IS NULL THEN
                x_line_lt:= x_line_hd||'|'||r_sit.vendor_site_code||'|'||r_sit.name||'|'||p_approved_vendor;
              ELSE
                x_line_lt:= x_line_lt||'|'||x_line_hd||'|'||r_sit.vendor_site_code||'|'||r_sit.name||'|'||p_approved_vendor;
              END IF;
           END LOOP;
           dbms_output.put_line(x_line_lt||'|');
           FND_FILE.PUT_LINE( FND_FILE.OUTPUT,x_line_lt||'|');
           UTL_FILE.PUT_LINE(x_file_type,x_line_lt||'|');
       END LOOP;
       utl_file.fclose(x_file_type);
   EXCEPTION
        WHEN OTHERS THEN
           FND_FILE.PUT_LINE( FND_FILE.LOG,'Procedure WRITE_DATA_FILE -> Unexpected Error ' ||SQLERRM);
   END write_data_file;

   ----------------------------------------------------------------------
END xx_asl_extract_pkg;
/


GRANT EXECUTE ON APPS.XX_ASL_EXTRACT_PKG TO INTG_XX_NONHR_RO;
