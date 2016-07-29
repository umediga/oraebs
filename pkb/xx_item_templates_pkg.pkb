DROP PACKAGE BODY APPS.XX_ITEM_TEMPLATES_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.XX_ITEM_TEMPLATES_PKG IS
/*+=====================================================================================+
| Header: XX_ITEM_TEMPLATES_PKG.pkb                                               |
+========================================================================================
| NTTDATA Inc                                                                           |
|                                                                                       |
+=======================================================================================+
| DESCRIPTION                                                                           |
| This Package body is used to load the data for Carriers and Services.                 |
|                                                                                       |
|                                                                                       |
| MODIFICATION HISTORY                                                                  |
| version   Date        Modified By          Remarks                                    |
| 1.0       05-Mar-2015 Venkat Kumar S       Initial Version                            |
+======================================================================================*/
   
PROCEDURE XX_LOAD_MAIN_PRC ( errorbuf         OUT  VARCHAR2
                           , retcode          OUT  NUMBER 
                            )
IS 

g_user_id               NUMBER     :=apps.fnd_global.user_id;
l_item_template_rec     mtl_item_templates_b%ROWTYPE;
o_rowid                 ROWID;
l_organization_id       NUMBER;
l_template_id           NUMBER;
l_template_name         VARCHAR2(100);
l_count                 NUMBER;

CURSOR c_template
IS
SELECT *
  FROM xx_item_templates
 WHERE 1 = 1
 ;

BEGIN

  FOR r_template IN c_template
  LOOP
    dbms_output.put_line('TEMPLATE_ID :'||r_template.template_id||' Name '||r_template.template_name);
    l_count := 0;
    BEGIN
      SELECT organization_id
       	INTO l_organization_id 
       	FROM mtl_parameters
       WHERE organization_code = r_template.organization_code
        ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_organization_id := NULL;
    END;
    
    BEGIN
      SELECT COUNT(1)
        INTO l_count
        FROM mtl_item_templates_b
       WHERE template_name = ltrim(rtrim(r_template.template_name))
       ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_count := 0;
    END;
    IF l_count = 0 THEN
      l_item_template_rec.template_name           := ltrim(rtrim(r_template.template_name));
      l_item_template_rec.template_id             := MTL_ITEM_TEMPLATES_S.nextval;
      l_item_template_rec.description             := r_template.description;
      l_item_template_rec.last_update_date        := SYSDATE;
      l_item_template_rec.last_updated_by         := g_user_id;
      l_item_template_rec.creation_date           := SYSDATE;
      l_item_template_rec.created_by              := g_user_id;
      l_item_template_rec.context_organization_id := l_organization_id;    
      
      MTL_ITEM_TEMPLATES_PKG.INSERT_ROW( l_item_template_rec
                                       , o_rowid
                                       );  
      BEGIN
        SELECT template_id
             , template_name
         INTO l_template_id
            , l_template_name
         FROM mtl_item_templates_b
         WHERE rowid = o_rowid
          ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          l_template_id := NULL;
      END;
      dbms_output.put_line('Created template_id :'||l_template_id||' Name '||l_template_name);  
    ELSE
      dbms_output.put_line('Template :'||l_template_name||' Already available');  
    END IF;
    
  END LOOP;
  
  


END XX_LOAD_MAIN_PRC;

END XX_ITEM_TEMPLATES_PKG;
/
