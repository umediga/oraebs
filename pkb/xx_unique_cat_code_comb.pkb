DROP PACKAGE BODY APPS.XX_UNIQUE_CAT_CODE_COMB;

CREATE OR REPLACE PACKAGE BODY APPS."XX_UNIQUE_CAT_CODE_COMB" 
IS

----------------------------------------------------------------------
/*
 Created By    : Omkar (IBM Development)
 Creation Date : 16-DEC-2013
 File Name     : XXUNIQUECATCODECOMB.pkb
 Description   : This script creates the specification of the package
                 XX_UNIQUE_CAT_CODE_COMB
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 16-DEC-2013 Omkar                Initial Version
*/ 
----------------------------------------------------------------------

PROCEDURE LOAD_CAT_CODE_COMB        (  ERRBUF          OUT  VARCHAR2,
                                       RETCODE         OUT  NUMBER,
                                       P_CATEGORY_SET_NAME IN VARCHAR2
                                    )
    IS
   
                      L_CATEGORY_REC INV_ITEM_CATEGORY_PUB.CATEGORY_REC_TYPE;
                      L_API_VERSION     NUMBER;
                      O_RETURN_STATUS   VARCHAR2 (2000);
                      O_MSG_COUNT       NUMBER;
                      O_MSG_DATA        VARCHAR2 (2000);
                      O_ERRORCODE       VARCHAR2 (2000);
                      L_ERROR_CODE      VARCHAR2 (2000);
                      L_ERROR_DESC      VARCHAR2 (2000);
                      L_CONV_STATUS     VARCHAR2 (2000);
                      V_CATEGORY_ID     NUMBER;
                      L_RETURN_STATUS   VARCHAR2 (2000);
                      L_ERRORCODE       VARCHAR2 (2000);
                      L_MSG_COUNT       NUMBER;
                      L_MSG_DATA        VARCHAR2 (2000);
                      V_STRUCTURE_ID    NUMBER :=0;
                      V_CATEGORY_SET_ID NUMBER :=0;
                      E_EXCEPTION       EXCEPTION;
                      E_NO_STRUCTURE    EXCEPTION;
                      --l_user_id              NUMBER := -1;
                      l_resp_id        NUMBER       := -1;
                      l_application_id NUMBER       := -1;
                      l_rowcnt         NUMBER       := 1;
                      l_user_id        VARCHAR2(30) := FND_GLOBAL.USER_ID;
                      L_RESP_NAME      VARCHAR2(30); 
                      P_INV_TOTAL_CNT NUMBER := 0;
                      P_FIN_TOTAL_CNT NUMBER := 0;
                      P_CONTD_TOTAL_CNT NUMBER := 0;
                      P_CONTR_TOTAL_CNT NUMBER := 0;
                      P_PO_TOTAL_CNT NUMBER := 0;
                      P_SM_TOTAL_CNT NUMBER := 0;

   
    
   CURSOR C_CAT_CODE_DETAILS(P_CATEGORY_SET_NAME VARCHAR2)
   IS
   SELECT ROWID ROW_ID, XLUC.*
        FROM   XXINTG.XX_LOAD_UNIQUE_CAT XLUC
      WHERE  1=1
      AND    STATUS IS NULL
      AND CATEGORY = P_CATEGORY_SET_NAME;


BEGIN

FND_FILE.PUT_LINE(FND_FILE.LOG,'Start Loading Unique Code Combinations');

        -- Get the application_id and responsibility_id
      SELECT FR.APPLICATION_ID, FR.RESPONSIBILITY_ID
   INTO   L_APPLICATION_ID, l_resp_id
   FROM   FND_RESPONSIBILITY FR, FND_APPLICATION FA
   WHERE  FR.APPLICATION_ID = FA.APPLICATION_ID
   AND UPPER(responsibility_key) = 'INVENTORY';
      
        FND_GLOBAL.APPS_INITIALIZE(L_USER_ID, L_RESP_ID, L_APPLICATION_ID);  
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Initialized applications context: '|| l_user_id || ' '|| l_resp_id ||' '|| l_application_id );

IF UPPER(P_CATEGORY_SET_NAME) = 'INVENTORY' THEN

BEGIN

FND_FILE.PUT_LINE(FND_FILE.LOG,'Loading Inventory Unique Code Combinations...');

BEGIN

SELECT STRUCTURE_ID, CATEGORY_SET_ID
         INTO   V_STRUCTURE_ID, V_CATEGORY_SET_ID
         FROM MTL_CATEGORY_SETS_V
         WHERE  1=1
         AND    UPPER(CATEGORY_SET_NAME) = 'INVENTORY';

  FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP2');

 EXCEPTION
         WHEN OTHERS THEN RAISE E_NO_STRUCTURE;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Inventory Category Not found!');
END;

BEGIN

SELECT COUNT(*)
 into p_inv_total_cnt
        FROM   XXINTG.XX_LOAD_UNIQUE_CAT XLUC
      WHERE  1=1
      AND    STATUS IS NULL
      AND CATEGORY = 'INVENTORY';

FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Number of Records to Process : '||p_inv_total_cnt);

 EXCEPTION
         WHEN OTHERS THEN RAISE E_NO_STRUCTURE;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'No Inventory Records to Process');
END;


FOR R_CAT_CODE_DETAILS IN C_CAT_CODE_DETAILS(P_CATEGORY_SET_NAME)
LOOP

FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP3');

BEGIN

BEGIN

     -- L_CATEGORY_REC := NULL;
      L_CATEGORY_REC.STRUCTURE_ID := V_STRUCTURE_ID; --i.structure_id;   
      L_CATEGORY_REC.SUMMARY_FLAG := 'N';
      L_CATEGORY_REC.ENABLED_FLAG := 'Y';
      L_CATEGORY_REC.SEGMENT1 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT1);
      L_CATEGORY_REC.SEGMENT2 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT2);
      L_CATEGORY_REC.SEGMENT3 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT3);
      L_CATEGORY_REC.SEGMENT4 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT4);
      L_CATEGORY_REC.SEGMENT5 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT5);
    --  L_CATEGORY_REC.DESCRIPTION    := 'TEST';  
    
      
      --
      -- After the category record is loaded, then call the create_category api to
      -- create the new mtl_categories record.
      
      INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY
                                       (P_API_VERSION        => 1.0,
                                        P_INIT_MSG_LIST      => FND_API.G_TRUE,
                                        P_COMMIT             => FND_API.G_FALSE,
                                        X_RETURN_STATUS      => O_RETURN_STATUS,
                                        X_ERRORCODE          => O_ERRORCODE,
                                        X_MSG_COUNT          => O_MSG_COUNT,
                                        X_MSG_DATA           => O_MSG_DATA,
                                        P_CATEGORY_REC       => L_CATEGORY_REC,
                                        X_CATEGORY_ID        => V_CATEGORY_ID
                                       ); 

FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP4');
FND_FILE.PUT_LINE(FND_FILE.LOG,'O_RETURN_STATUS:'|| O_RETURN_STATUS);
FND_FILE.PUT_LINE(FND_FILE.LOG,'V_CATEGORY_ID:'|| V_CATEGORY_ID);
FND_FILE.PUT_LINE(FND_FILE.LOG,'O_MSG_COUNT:'|| O_MSG_COUNT);




IF (O_RETURN_STATUS = FND_API.G_RET_STS_SUCCESS)
      THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP5');

         FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Category successfully created. New Category Id = '|| V_CATEGORY_ID);
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.SEGMENT1|| '.'|| R_CAT_CODE_DETAILS.SEGMENT2|| '.'|| R_CAT_CODE_DETAILS.SEGMENT3|| '.'|| R_CAT_CODE_DETAILS.SEGMENT4|| '.'|| R_CAT_CODE_DETAILS.SEGMENT5);
         FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
         
         
         -- if successfull then call the next API to create valid cat
         
          INV_ITEM_CATEGORY_PUB.CREATE_VALID_CATEGORY (P_API_VERSION           => 1.0,
                                                      P_INIT_MSG_LIST      => FND_API.G_TRUE,
                                                      P_COMMIT             => FND_API.G_FALSE,
                                                      P_CATEGORY_SET_ID    => V_CATEGORY_SET_ID, -- for Inventory
                                                      P_CATEGORY_ID        => V_CATEGORY_ID,
                                                      P_PARENT_CATEGORY_ID => NULL,
                                                      X_RETURN_STATUS      => L_RETURN_STATUS,
                                                      X_ERRORCODE          => L_ERRORCODE,
                                                      X_MSG_COUNT          => L_MSG_COUNT,
                                                      X_MSG_DATA           => L_MSG_DATA
                                                       );
    
          IF L_RETURN_STATUS = 'S'
               THEN
                  FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
                  FND_FILE.PUT_LINE (  FND_FILE.LOG, 'Valid Cat successfully created.');
                  FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.SEGMENT1|| '.'|| R_CAT_CODE_DETAILS.SEGMENT2|| '.'|| R_CAT_CODE_DETAILS.SEGMENT3|| '.'|| R_CAT_CODE_DETAILS.SEGMENT4|| '.'|| R_CAT_CODE_DETAILS.SEGMENT5);
                   FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
                   
                  UPDATE XXINTG.XX_LOAD_UNIQUE_CAT
                   SET    ERROR_MESSAGE = NULL,
                      STATUS   = 'P'
                   WHERE  ROWID         = R_CAT_CODE_DETAILS.ROW_ID;   
                    
                  COMMIT;
                
                ELSE               


                    UPDATE XXINTG.XX_LOAD_UNIQUE_CAT
                      SET ERROR_MESSAGE = 'API- CREATE_VALID_CATEGORY failure',
                        STATUS          = 'E'
                      WHERE ROWID       = R_CAT_CODE_DETAILS.ROW_ID;
                      COMMIT;
                      RAISE E_EXCEPTION;
            
          END IF;
          
 ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP6');

         L_ERROR_DESC := NVL (L_ERROR_DESC, '') || '#API Error while creating Category';
         l_conv_status := 'ERROR';
         FND_FILE.PUT_LINE (FND_FILE.LOG,'API STATUS : ' || O_RETURN_STATUS);
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.segment1|| '.'|| R_CAT_CODE_DETAILS.segment2|| '.'|| R_CAT_CODE_DETAILS.segment3|| '.'|| R_CAT_CODE_DETAILS.segment4|| '.'|| R_CAT_CODE_DETAILS.segment5 || SQLERRM);

         IF o_msg_count > 0
         THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP7');

            FND_FILE.PUT_LINE (FND_FILE.LOG,O_ERRORCODE);
            FND_FILE.PUT_LINE (FND_FILE.LOG,o_msg_data);

            FOR i IN 1 .. o_msg_count
            LOOP
               FND_FILE.PUT_LINE
                      (  FND_FILE.LOG, i|| '.'|| SUBSTR(fnd_msg_pub.get (p_encoded      => fnd_api.g_false),1,255));
            END LOOP;
            

            update XXINTG.XX_LOAD_UNIQUE_CAT
             set    error_message = 'API- create_category failure',
                  STATUS   = 'E'
             where    ROWID         = R_CAT_CODE_DETAILS.row_id;            
            
            raise e_exception;
            
         END IF;
      END IF;
      
      
             EXCEPTION WHEN    OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP8');

             update XXINTG.XX_LOAD_UNIQUE_CAT
             set    error_message = 'OTHERS in the API loop',
                  STATUS   = 'E'
             where    ROWID         = R_CAT_CODE_DETAILS.row_id;

             raise e_exception;
      
            end; -- end1
           
         EXCEPTION WHEN    e_exception THEN
 
          FND_FILE.PUT_LINE(FND_FILE.LOG,'In e_exception'); 
             
        end; -- end1
        
      end loop;
      
 
  COMMIT; 
 EXCEPTION 
 
     WHEN e_no_structure THEN
     
        FND_FILE.PUT_LINE(FND_FILE.LOG,'There is no structure set for Inventory Category Set!');     
        
     WHEN OTHERS THEN 
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others error'); 
                       FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM); 

END;

ELSIF UPPER(P_CATEGORY_SET_NAME) = 'FINANCIAL REPORTING' THEN

BEGIN

FND_FILE.PUT_LINE(FND_FILE.LOG,'Loading Finance Unique Code Combinations...');
BEGIN

SELECT STRUCTURE_ID, CATEGORY_SET_ID
         INTO   V_STRUCTURE_ID, V_CATEGORY_SET_ID
         FROM MTL_CATEGORY_SETS_V
         WHERE  1=1
         AND    UPPER(CATEGORY_SET_NAME) = 'FINANCIAL REPORTING';

  FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP2 finance');

 EXCEPTION
         WHEN OTHERS THEN RAISE E_NO_STRUCTURE;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Finance Category Not found!');
END;

BEGIN

SELECT COUNT(*)
 into p_fin_total_cnt
        FROM   XXINTG.XX_LOAD_UNIQUE_CAT XLUC
      WHERE  1=1
      AND    STATUS IS NULL
      AND CATEGORY = 'FINANCIAL REPORTING';

FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Number of Records to Process : '||p_fin_total_cnt);

 EXCEPTION
         WHEN OTHERS THEN RAISE E_NO_STRUCTURE;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'No Finance Records to Process');
END;

FOR R_CAT_CODE_DETAILS IN C_CAT_CODE_DETAILS(P_CATEGORY_SET_NAME)
LOOP

FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP3 finance');

BEGIN

BEGIN

     -- L_CATEGORY_REC := NULL;
      L_CATEGORY_REC.STRUCTURE_ID := V_STRUCTURE_ID; --i.structure_id;   
      L_CATEGORY_REC.SUMMARY_FLAG := 'N';
      L_CATEGORY_REC.ENABLED_FLAG := 'Y';
      L_CATEGORY_REC.SEGMENT1 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT1);
      L_CATEGORY_REC.SEGMENT2 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT2);
      L_CATEGORY_REC.SEGMENT3 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT3);
     -- L_CATEGORY_REC.SEGMENT4 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT4);
     -- L_CATEGORY_REC.SEGMENT5 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT5);
    --  L_CATEGORY_REC.DESCRIPTION    := 'TEST';  
    
      
      --
      -- After the category record is loaded, then call the create_category api to
      -- create the new mtl_categories record.
      
      INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY
                                       (P_API_VERSION        => 1.0,
                                        P_INIT_MSG_LIST      => FND_API.G_TRUE,
                                        P_COMMIT             => FND_API.G_FALSE,
                                        X_RETURN_STATUS      => O_RETURN_STATUS,
                                        X_ERRORCODE          => O_ERRORCODE,
                                        X_MSG_COUNT          => O_MSG_COUNT,
                                        X_MSG_DATA           => O_MSG_DATA,
                                        P_CATEGORY_REC       => L_CATEGORY_REC,
                                        X_CATEGORY_ID        => V_CATEGORY_ID
                                       ); 

FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP4');
FND_FILE.PUT_LINE(FND_FILE.LOG,'O_RETURN_STATUS:'|| O_RETURN_STATUS);
FND_FILE.PUT_LINE(FND_FILE.LOG,'V_CATEGORY_ID:'|| V_CATEGORY_ID);
FND_FILE.PUT_LINE(FND_FILE.LOG,'O_MSG_COUNT:'|| O_MSG_COUNT);




IF (O_RETURN_STATUS = FND_API.G_RET_STS_SUCCESS)
      THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP5');

         FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Category successfully created. New Category Id = '|| V_CATEGORY_ID);
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.SEGMENT1|| '.'|| R_CAT_CODE_DETAILS.SEGMENT2|| '.'|| R_CAT_CODE_DETAILS.SEGMENT3);
         FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
         
         
         -- if successfull then call the next API to create valid cat
         
          INV_ITEM_CATEGORY_PUB.CREATE_VALID_CATEGORY (P_API_VERSION           => 1.0,
                                                      P_INIT_MSG_LIST      => FND_API.G_TRUE,
                                                      P_COMMIT             => FND_API.G_FALSE,
                                                      P_CATEGORY_SET_ID    => V_CATEGORY_SET_ID, -- for Finance
                                                      P_CATEGORY_ID        => V_CATEGORY_ID,
                                                      P_PARENT_CATEGORY_ID => NULL,
                                                      X_RETURN_STATUS      => L_RETURN_STATUS,
                                                      X_ERRORCODE          => L_ERRORCODE,
                                                      X_MSG_COUNT          => L_MSG_COUNT,
                                                      X_MSG_DATA           => L_MSG_DATA
                                                       );
    
          IF L_RETURN_STATUS = 'S'
               THEN
                  FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
                  FND_FILE.PUT_LINE (  FND_FILE.LOG, 'Valid Cat successfully created.');
                  FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.SEGMENT1|| '.'|| R_CAT_CODE_DETAILS.SEGMENT2|| '.'|| R_CAT_CODE_DETAILS.SEGMENT3);
                   FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
                   
                  UPDATE XXINTG.XX_LOAD_UNIQUE_CAT
                   SET    ERROR_MESSAGE = NULL,
                      STATUS   = 'P'
                   WHERE  ROWID         = R_CAT_CODE_DETAILS.ROW_ID;   
                    
                  COMMIT;
                
                ELSE               


                    UPDATE XXINTG.XX_LOAD_UNIQUE_CAT
                      SET ERROR_MESSAGE = 'API- CREATE_VALID_CATEGORY failure',
                        STATUS          = 'E'
                      WHERE ROWID       = R_CAT_CODE_DETAILS.ROW_ID;
                      COMMIT;
                      RAISE E_EXCEPTION;
            
          END IF;
          
 ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP6');

         L_ERROR_DESC := NVL (L_ERROR_DESC, '') || '#API Error while creating Category';
         l_conv_status := 'ERROR';
         FND_FILE.PUT_LINE (FND_FILE.LOG,'API STATUS : ' || O_RETURN_STATUS);
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.segment1|| '.'|| R_CAT_CODE_DETAILS.segment2|| '.'|| R_CAT_CODE_DETAILS.segment3 || SQLERRM);

         IF o_msg_count > 0
         THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP7');

            FND_FILE.PUT_LINE (FND_FILE.LOG,O_ERRORCODE);
            FND_FILE.PUT_LINE (FND_FILE.LOG,o_msg_data);

            FOR i IN 1 .. o_msg_count
            LOOP
               FND_FILE.PUT_LINE
                      (  FND_FILE.LOG, i|| '.'|| SUBSTR(fnd_msg_pub.get (p_encoded      => fnd_api.g_false),1,255));
            END LOOP;
            

            update XXINTG.XX_LOAD_UNIQUE_CAT
             set    error_message = 'API- create_category failure',
                  STATUS   = 'E'
             where    ROWID         = R_CAT_CODE_DETAILS.row_id;            
            
            raise e_exception;
            
         END IF;
      END IF;
      
      
             EXCEPTION WHEN    OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP8');

             update XXINTG.XX_LOAD_UNIQUE_CAT
             set    error_message = 'OTHERS in the API loop',
                  STATUS   = 'E'
             where    ROWID         = R_CAT_CODE_DETAILS.row_id;

             raise e_exception;
      
            end; -- end1
           
         EXCEPTION WHEN    e_exception THEN
 
          FND_FILE.PUT_LINE(FND_FILE.LOG,'In e_exception'); 
             
        end; -- end1
        
      end loop;
      
 
  COMMIT; 
 EXCEPTION 
 
     WHEN e_no_structure THEN
     
        FND_FILE.PUT_LINE(FND_FILE.LOG,'There is no structure set for Finance Category Set!');     
        
     WHEN OTHERS THEN 
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others error'); 
                       FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM); 

END;

ELSIF UPPER(P_CATEGORY_SET_NAME) = 'SALES AND MARKETING' THEN

BEGIN

FND_FILE.PUT_LINE(FND_FILE.LOG,'Loading Sales and Marketing Unique Code Combinations...');
BEGIN

SELECT STRUCTURE_ID, CATEGORY_SET_ID
         INTO   V_STRUCTURE_ID, V_CATEGORY_SET_ID
         FROM MTL_CATEGORY_SETS_V
         WHERE  1=1
         AND    UPPER(CATEGORY_SET_NAME) = 'SALES AND MARKETING';

  FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP2 SM');

 EXCEPTION
         WHEN OTHERS THEN RAISE E_NO_STRUCTURE;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Sales and Marketing Category Not found!');
END;

BEGIN

SELECT COUNT(*)
 into p_sm_total_cnt
        FROM   XXINTG.XX_LOAD_UNIQUE_CAT XLUC
      WHERE  1=1
      AND    STATUS IS NULL
      AND CATEGORY = 'SALES AND MARKETING';

FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Number of Records to Process : '||p_sm_total_cnt);

EXCEPTION
         WHEN OTHERS THEN RAISE E_NO_STRUCTURE;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'No Sales and Marketing Records to Process!');
END;

FOR R_CAT_CODE_DETAILS IN C_CAT_CODE_DETAILS(P_CATEGORY_SET_NAME)
LOOP

FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP3 SM');

BEGIN

BEGIN

     -- L_CATEGORY_REC := NULL;
      L_CATEGORY_REC.STRUCTURE_ID := V_STRUCTURE_ID; --i.structure_id;   
      L_CATEGORY_REC.SUMMARY_FLAG := 'N';
      L_CATEGORY_REC.ENABLED_FLAG := 'Y';
      L_CATEGORY_REC.SEGMENT4 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT4);
      L_CATEGORY_REC.SEGMENT6 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT6);
      L_CATEGORY_REC.SEGMENT7 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT7);
      L_CATEGORY_REC.SEGMENT8 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT8);
      L_CATEGORY_REC.SEGMENT9 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT9);
      L_CATEGORY_REC.SEGMENT10 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT10);

    --  L_CATEGORY_REC.DESCRIPTION    := 'TEST';  
    
      
      --
      -- After the category record is loaded, then call the create_category api to
      -- create the new mtl_categories record.
      
      INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY
                                       (P_API_VERSION        => 1.0,
                                        P_INIT_MSG_LIST      => FND_API.G_TRUE,
                                        P_COMMIT             => FND_API.G_FALSE,
                                        X_RETURN_STATUS      => O_RETURN_STATUS,
                                        X_ERRORCODE          => O_ERRORCODE,
                                        X_MSG_COUNT          => O_MSG_COUNT,
                                        X_MSG_DATA           => O_MSG_DATA,
                                        P_CATEGORY_REC       => L_CATEGORY_REC,
                                        X_CATEGORY_ID        => V_CATEGORY_ID
                                       ); 

FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP4');
FND_FILE.PUT_LINE(FND_FILE.LOG,'O_RETURN_STATUS:'|| O_RETURN_STATUS);
FND_FILE.PUT_LINE(FND_FILE.LOG,'V_CATEGORY_ID:'|| V_CATEGORY_ID);
FND_FILE.PUT_LINE(FND_FILE.LOG,'O_MSG_COUNT:'|| O_MSG_COUNT);




IF (O_RETURN_STATUS = FND_API.G_RET_STS_SUCCESS)
      THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP5');

         FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Category successfully created. New Category Id = '|| V_CATEGORY_ID);
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.SEGMENT4|| '.'|| R_CAT_CODE_DETAILS.SEGMENT10|| '.'|| R_CAT_CODE_DETAILS.SEGMENT7||'.'|| R_CAT_CODE_DETAILS.SEGMENT8|| '.'|| R_CAT_CODE_DETAILS.SEGMENT9|| '.'|| R_CAT_CODE_DETAILS.SEGMENT6);
         FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
         
         
         -- if successfull then call the next API to create valid cat
         
          INV_ITEM_CATEGORY_PUB.CREATE_VALID_CATEGORY (P_API_VERSION           => 1.0,
                                                      P_INIT_MSG_LIST      => FND_API.G_TRUE,
                                                      P_COMMIT             => FND_API.G_FALSE,
                                                      P_CATEGORY_SET_ID    => V_CATEGORY_SET_ID, -- for SandM
                                                      P_CATEGORY_ID        => V_CATEGORY_ID,
                                                      P_PARENT_CATEGORY_ID => NULL,
                                                      X_RETURN_STATUS      => L_RETURN_STATUS,
                                                      X_ERRORCODE          => L_ERRORCODE,
                                                      X_MSG_COUNT          => L_MSG_COUNT,
                                                      X_MSG_DATA           => L_MSG_DATA
                                                       );
    
          IF L_RETURN_STATUS = 'S'
               THEN
                  FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
                  FND_FILE.PUT_LINE (  FND_FILE.LOG, 'Valid Cat successfully created.');
                  FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.SEGMENT4|| '.'|| R_CAT_CODE_DETAILS.SEGMENT10|| '.'|| R_CAT_CODE_DETAILS.SEGMENT7|| R_CAT_CODE_DETAILS.SEGMENT8|| '.'|| R_CAT_CODE_DETAILS.SEGMENT9|| '.'|| R_CAT_CODE_DETAILS.SEGMENT6);
                   FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
                   
                  UPDATE XXINTG.XX_LOAD_UNIQUE_CAT
                   SET    ERROR_MESSAGE = NULL,
                      STATUS   = 'P'
                   WHERE  ROWID         = R_CAT_CODE_DETAILS.ROW_ID;   
                    
                  COMMIT;
                
                ELSE               


                    UPDATE XXINTG.XX_LOAD_UNIQUE_CAT
                      SET ERROR_MESSAGE = 'API- CREATE_VALID_CATEGORY failure',
                        STATUS          = 'E'
                      WHERE ROWID       = R_CAT_CODE_DETAILS.ROW_ID;
                      COMMIT;
                      RAISE E_EXCEPTION;
            
          END IF;
          
 ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP6');

         L_ERROR_DESC := NVL (L_ERROR_DESC, '') || '#API Error while creating Category';
         l_conv_status := 'ERROR';
         FND_FILE.PUT_LINE (FND_FILE.LOG,'API STATUS : ' || O_RETURN_STATUS);
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.segment4|| '.'|| R_CAT_CODE_DETAILS.segment10|| '.'|| R_CAT_CODE_DETAILS.segment7||'.'|| R_CAT_CODE_DETAILS.SEGMENT8|| '.'|| R_CAT_CODE_DETAILS.SEGMENT9|| '.'|| R_CAT_CODE_DETAILS.SEGMENT6 || SQLERRM);

         IF o_msg_count > 0
         THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP7');

            FND_FILE.PUT_LINE (FND_FILE.LOG,O_ERRORCODE);
            FND_FILE.PUT_LINE (FND_FILE.LOG,o_msg_data);

            FOR i IN 1 .. o_msg_count
            LOOP
               FND_FILE.PUT_LINE
                      (  FND_FILE.LOG, i|| '.'|| SUBSTR(fnd_msg_pub.get (p_encoded      => fnd_api.g_false),1,255));
            END LOOP;
            

            update XXINTG.XX_LOAD_UNIQUE_CAT
             set    error_message = 'API- create_category failure',
                  STATUS   = 'E'
             where    ROWID         = R_CAT_CODE_DETAILS.row_id;            
            
            raise e_exception;
            
         END IF;
      END IF;
      
      
             EXCEPTION WHEN    OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP8');

             update XXINTG.XX_LOAD_UNIQUE_CAT
             set    error_message = 'OTHERS in the API loop',
                  STATUS   = 'E'
             where    ROWID         = R_CAT_CODE_DETAILS.row_id;

             raise e_exception;
      
            end; -- end1
           
         EXCEPTION WHEN    e_exception THEN
 
          FND_FILE.PUT_LINE(FND_FILE.LOG,'In e_exception'); 
             
        end; -- end1
        
      end loop;
      
 
  COMMIT; 
 EXCEPTION 
 
     WHEN e_no_structure THEN
     
        FND_FILE.PUT_LINE(FND_FILE.LOG,'There is no structure set for SandM Category Set!');     
        
     WHEN OTHERS THEN 
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others error'); 
                       FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM); 

END;

ELSIF UPPER(P_CATEGORY_SET_NAME) = 'PO ITEM CATEGORY' THEN

BEGIN

FND_FILE.PUT_LINE(FND_FILE.LOG,'Load PO Unique Code Combinations...');
BEGIN

SELECT STRUCTURE_ID, CATEGORY_SET_ID
         INTO   V_STRUCTURE_ID, V_CATEGORY_SET_ID
         FROM MTL_CATEGORY_SETS_V
         WHERE  1=1
         AND    UPPER(CATEGORY_SET_NAME) = 'PO ITEM CATEGORY';

  FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP2 PO');

 EXCEPTION
         WHEN OTHERS THEN RAISE E_NO_STRUCTURE;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'PO Category Not found!');
END;

BEGIN

SELECT COUNT(*)
 into p_sm_total_cnt
        FROM   XXINTG.XX_LOAD_UNIQUE_CAT XLUC
      WHERE  1=1
      AND    STATUS IS NULL
      AND CATEGORY = 'PO ITEM CATEGORY';

FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Number of Records to Process : '||p_sm_total_cnt);

EXCEPTION
         WHEN OTHERS THEN RAISE E_NO_STRUCTURE;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'No Purchasing Records to Process!');
END;


FOR R_CAT_CODE_DETAILS IN C_CAT_CODE_DETAILS(P_CATEGORY_SET_NAME)
LOOP

FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP3 PO');

BEGIN

BEGIN

     -- L_CATEGORY_REC := NULL;
      L_CATEGORY_REC.STRUCTURE_ID := V_STRUCTURE_ID; --i.structure_id;   
      L_CATEGORY_REC.SUMMARY_FLAG := 'N';
      L_CATEGORY_REC.ENABLED_FLAG := 'Y';
      --L_CATEGORY_REC.SEGMENT1 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT1);
      L_CATEGORY_REC.SEGMENT2 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT2);
     -- L_CATEGORY_REC.SEGMENT3 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT3);
     -- L_CATEGORY_REC.SEGMENT4 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT4);
     -- L_CATEGORY_REC.SEGMENT5 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT5);
     -- L_CATEGORY_REC.SEGMENT6 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT6);

    --  L_CATEGORY_REC.DESCRIPTION    := 'TEST';  
    
      
      --
      -- After the category record is loaded, then call the create_category api to
      -- create the new mtl_categories record.
      
      INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY
                                       (P_API_VERSION        => 1.0,
                                        P_INIT_MSG_LIST      => FND_API.G_TRUE,
                                        P_COMMIT             => FND_API.G_FALSE,
                                        X_RETURN_STATUS      => O_RETURN_STATUS,
                                        X_ERRORCODE          => O_ERRORCODE,
                                        X_MSG_COUNT          => O_MSG_COUNT,
                                        X_MSG_DATA           => O_MSG_DATA,
                                        P_CATEGORY_REC       => L_CATEGORY_REC,
                                        X_CATEGORY_ID        => V_CATEGORY_ID
                                       ); 

FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP4');
FND_FILE.PUT_LINE(FND_FILE.LOG,'O_RETURN_STATUS:'|| O_RETURN_STATUS);
FND_FILE.PUT_LINE(FND_FILE.LOG,'V_CATEGORY_ID:'|| V_CATEGORY_ID);
FND_FILE.PUT_LINE(FND_FILE.LOG,'O_MSG_COUNT:'|| O_MSG_COUNT);




IF (O_RETURN_STATUS = FND_API.G_RET_STS_SUCCESS)
      THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP5');

         FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Category successfully created. New Category Id = '|| V_CATEGORY_ID);
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.SEGMENT2);
         FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
         
         
         -- if successfull then call the next API to create valid cat
         
          INV_ITEM_CATEGORY_PUB.CREATE_VALID_CATEGORY (P_API_VERSION           => 1.0,
                                                      P_INIT_MSG_LIST      => FND_API.G_TRUE,
                                                      P_COMMIT             => FND_API.G_FALSE,
                                                      P_CATEGORY_SET_ID    => V_CATEGORY_SET_ID, -- for SandM
                                                      P_CATEGORY_ID        => V_CATEGORY_ID,
                                                      P_PARENT_CATEGORY_ID => NULL,
                                                      X_RETURN_STATUS      => L_RETURN_STATUS,
                                                      X_ERRORCODE          => L_ERRORCODE,
                                                      X_MSG_COUNT          => L_MSG_COUNT,
                                                      X_MSG_DATA           => L_MSG_DATA
                                                       );
    
          IF L_RETURN_STATUS = 'S'
               THEN
                  FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
                  FND_FILE.PUT_LINE (  FND_FILE.LOG, 'Valid Cat successfully created.');
                  FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.SEGMENT2);
                   FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
                   
                  UPDATE XXINTG.XX_LOAD_UNIQUE_CAT
                   SET    ERROR_MESSAGE = NULL,
                      STATUS   = 'P'
                   WHERE  ROWID         = R_CAT_CODE_DETAILS.ROW_ID;   
                    
                  COMMIT;
                
                ELSE               


                    UPDATE XXINTG.XX_LOAD_UNIQUE_CAT
                      SET ERROR_MESSAGE = 'API- CREATE_VALID_CATEGORY failure',
                        STATUS          = 'E'
                      WHERE ROWID       = R_CAT_CODE_DETAILS.ROW_ID;
                      COMMIT;
                      RAISE E_EXCEPTION;
            
          END IF;
          
 ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP6');

         L_ERROR_DESC := NVL (L_ERROR_DESC, '') || '#API Error while creating Category';
         l_conv_status := 'ERROR';
         FND_FILE.PUT_LINE (FND_FILE.LOG,'API STATUS : ' || O_RETURN_STATUS);
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.segment2|| SQLERRM);

         IF o_msg_count > 0
         THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP7');

            FND_FILE.PUT_LINE (FND_FILE.LOG,O_ERRORCODE);
            FND_FILE.PUT_LINE (FND_FILE.LOG,o_msg_data);

            FOR i IN 1 .. o_msg_count
            LOOP
               FND_FILE.PUT_LINE
                      (  FND_FILE.LOG, i|| '.'|| SUBSTR(fnd_msg_pub.get (p_encoded      => fnd_api.g_false),1,255));
            END LOOP;
            

            update XXINTG.XX_LOAD_UNIQUE_CAT
             set    error_message = 'API- create_category failure',
                  STATUS   = 'E'
             where    ROWID         = R_CAT_CODE_DETAILS.row_id;            
            
            raise e_exception;
            
         END IF;
END IF;
      
      
             EXCEPTION WHEN    OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP8');

             update XXINTG.XX_LOAD_UNIQUE_CAT
             set    error_message = 'OTHERS in the API loop',
                  STATUS   = 'E'
             where    ROWID         = R_CAT_CODE_DETAILS.row_id;

             raise e_exception;
      
            end; -- end1
           
         EXCEPTION WHEN    e_exception THEN
 
          FND_FILE.PUT_LINE(FND_FILE.LOG,'In e_exception'); 
             
        end; -- end1
        
      end loop;
      
 
  COMMIT; 
 EXCEPTION 
 
     WHEN e_no_structure THEN
     
        FND_FILE.PUT_LINE(FND_FILE.LOG,'There is no structure set for PO Category Set!');     
        
     WHEN OTHERS THEN 
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others error'); 
                       FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM); 

END;

ELSIF UPPER(P_CATEGORY_SET_NAME) = 'CONTAINED ITEM' THEN

BEGIN

FND_FILE.PUT_LINE(FND_FILE.LOG,'Loading Contained Item Unique Code Combinations...');
BEGIN

SELECT STRUCTURE_ID, CATEGORY_SET_ID
         INTO   V_STRUCTURE_ID, V_CATEGORY_SET_ID
         FROM MTL_CATEGORY_SETS_V
         WHERE  1=1
         AND    UPPER(CATEGORY_SET_NAME) = 'CONTAINED ITEM';

  FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP2 CNT');

 EXCEPTION
         WHEN OTHERS THEN RAISE E_NO_STRUCTURE;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Contained Item Category Not found!');
END;


BEGIN

SELECT COUNT(*)
 into p_sm_total_cnt
        FROM   XXINTG.XX_LOAD_UNIQUE_CAT XLUC
      WHERE  1=1
      AND    STATUS IS NULL
      AND CATEGORY = 'CONTAINED ITEM';

FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Number of Records to Process : '||p_sm_total_cnt);

EXCEPTION
         WHEN OTHERS THEN RAISE E_NO_STRUCTURE;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'No Contained Item Records to Process!');
END;

FOR R_CAT_CODE_DETAILS IN C_CAT_CODE_DETAILS(P_CATEGORY_SET_NAME)
LOOP

FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP3 CNT');

BEGIN

BEGIN

     -- L_CATEGORY_REC := NULL;
      L_CATEGORY_REC.STRUCTURE_ID := V_STRUCTURE_ID; --i.structure_id;   
      L_CATEGORY_REC.SUMMARY_FLAG := 'N';
      L_CATEGORY_REC.ENABLED_FLAG := 'Y';
      L_CATEGORY_REC.SEGMENT1 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT1);
     -- L_CATEGORY_REC.SEGMENT2 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT2);
     -- L_CATEGORY_REC.SEGMENT3 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT3);
     -- L_CATEGORY_REC.SEGMENT4 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT4);
     -- L_CATEGORY_REC.SEGMENT5 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT5);
     -- L_CATEGORY_REC.SEGMENT6 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT6);

    --  L_CATEGORY_REC.DESCRIPTION    := 'TEST';  
    
      
      --
      -- After the category record is loaded, then call the create_category api to
      -- create the new mtl_categories record.
      
      INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY
                                       (P_API_VERSION        => 1.0,
                                        P_INIT_MSG_LIST      => FND_API.G_TRUE,
                                        P_COMMIT             => FND_API.G_FALSE,
                                        X_RETURN_STATUS      => O_RETURN_STATUS,
                                        X_ERRORCODE          => O_ERRORCODE,
                                        X_MSG_COUNT          => O_MSG_COUNT,
                                        X_MSG_DATA           => O_MSG_DATA,
                                        P_CATEGORY_REC       => L_CATEGORY_REC,
                                        X_CATEGORY_ID        => V_CATEGORY_ID
                                       ); 

FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP4');
FND_FILE.PUT_LINE(FND_FILE.LOG,'O_RETURN_STATUS:'|| O_RETURN_STATUS);
FND_FILE.PUT_LINE(FND_FILE.LOG,'V_CATEGORY_ID:'|| V_CATEGORY_ID);
FND_FILE.PUT_LINE(FND_FILE.LOG,'O_MSG_COUNT:'|| O_MSG_COUNT);




IF (O_RETURN_STATUS = FND_API.G_RET_STS_SUCCESS)
      THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP5');

         FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Category successfully created. New Category Id = '|| V_CATEGORY_ID);
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.SEGMENT1);
         FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
         
         
         -- if successfull then call the next API to create valid cat
         
          INV_ITEM_CATEGORY_PUB.CREATE_VALID_CATEGORY (P_API_VERSION           => 1.0,
                                                      P_INIT_MSG_LIST      => FND_API.G_TRUE,
                                                      P_COMMIT             => FND_API.G_FALSE,
                                                      P_CATEGORY_SET_ID    => V_CATEGORY_SET_ID, -- for SandM
                                                      P_CATEGORY_ID        => V_CATEGORY_ID,
                                                      P_PARENT_CATEGORY_ID => NULL,
                                                      X_RETURN_STATUS      => L_RETURN_STATUS,
                                                      X_ERRORCODE          => L_ERRORCODE,
                                                      X_MSG_COUNT          => L_MSG_COUNT,
                                                      X_MSG_DATA           => L_MSG_DATA
                                                       );
    
          IF L_RETURN_STATUS = 'S'
               THEN
                  FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
                  FND_FILE.PUT_LINE (  FND_FILE.LOG, 'Valid Cat successfully created.');
                  FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.SEGMENT1);
                   FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
                   
                  UPDATE XXINTG.XX_LOAD_UNIQUE_CAT
                   SET    ERROR_MESSAGE = NULL,
                      STATUS   = 'P'
                   WHERE  ROWID         = R_CAT_CODE_DETAILS.ROW_ID;   
                    
                  COMMIT;
                
                ELSE               


                    UPDATE XXINTG.XX_LOAD_UNIQUE_CAT
                      SET ERROR_MESSAGE = 'API- CREATE_VALID_CATEGORY failure',
                        STATUS          = 'E'
                      WHERE ROWID       = R_CAT_CODE_DETAILS.ROW_ID;
                      COMMIT;
                      RAISE E_EXCEPTION;
            
          END IF;
          
 ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP6');

         L_ERROR_DESC := NVL (L_ERROR_DESC, '') || '#API Error while creating Category';
         l_conv_status := 'ERROR';
         FND_FILE.PUT_LINE (FND_FILE.LOG,'API STATUS : ' || O_RETURN_STATUS);
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.segment1|| SQLERRM);

         IF o_msg_count > 0
         THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP7');

            FND_FILE.PUT_LINE (FND_FILE.LOG,O_ERRORCODE);
            FND_FILE.PUT_LINE (FND_FILE.LOG,o_msg_data);

            FOR i IN 1 .. o_msg_count
            LOOP
               FND_FILE.PUT_LINE
                      (  FND_FILE.LOG, i|| '.'|| SUBSTR(fnd_msg_pub.get (p_encoded      => fnd_api.g_false),1,255));
            END LOOP;
            

            update XXINTG.XX_LOAD_UNIQUE_CAT
             set    error_message = 'API- create_category failure',
                  STATUS   = 'E'
             where    ROWID         = R_CAT_CODE_DETAILS.row_id;            
            
            raise e_exception;
            
         END IF;
END IF;
      
      
             EXCEPTION WHEN    OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP8');

             update XXINTG.XX_LOAD_UNIQUE_CAT
             set    error_message = 'OTHERS in the API loop',
                  STATUS   = 'E'
             where    ROWID         = R_CAT_CODE_DETAILS.row_id;

             raise e_exception;
      
            end; -- end1
           
         EXCEPTION WHEN    e_exception THEN
 
          FND_FILE.PUT_LINE(FND_FILE.LOG,'In e_exception'); 
             
        end; -- end1
        
      end loop;
      
 
  COMMIT; 
 EXCEPTION 
 
     WHEN e_no_structure THEN
     
        FND_FILE.PUT_LINE(FND_FILE.LOG,'There is no structure set for Contained Item Category Set!');     
        
     WHEN OTHERS THEN 
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others error'); 
                       FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM); 

END;

ELSIF UPPER(P_CATEGORY_SET_NAME) = 'CONTAINER ITEM' THEN

BEGIN

FND_FILE.PUT_LINE(FND_FILE.LOG,'Loading Container Item Unique Code Combinations...');
BEGIN

SELECT STRUCTURE_ID, CATEGORY_SET_ID
         INTO   V_STRUCTURE_ID, V_CATEGORY_SET_ID
         FROM MTL_CATEGORY_SETS_V
         WHERE  1=1
         AND    UPPER(CATEGORY_SET_NAME) = 'CONTAINER ITEM';

  FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP2 CNR');

 EXCEPTION
         WHEN OTHERS THEN RAISE E_NO_STRUCTURE;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Container Item Category Not found!');
END;

BEGIN

SELECT COUNT(*)
 into p_sm_total_cnt
        FROM   XXINTG.XX_LOAD_UNIQUE_CAT XLUC
      WHERE  1=1
      AND    STATUS IS NULL
      AND CATEGORY = 'CONTAINER ITEM';

FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Number of Records to Process : '||p_sm_total_cnt);

EXCEPTION
         WHEN OTHERS THEN RAISE E_NO_STRUCTURE;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'No Container Item Records to Process!');
END;

FOR R_CAT_CODE_DETAILS IN C_CAT_CODE_DETAILS(P_CATEGORY_SET_NAME)
LOOP

FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP3 CNR');

BEGIN

BEGIN

     -- L_CATEGORY_REC := NULL;
      L_CATEGORY_REC.STRUCTURE_ID := V_STRUCTURE_ID; --i.structure_id;   
      L_CATEGORY_REC.SUMMARY_FLAG := 'N';
      L_CATEGORY_REC.ENABLED_FLAG := 'Y';
      L_CATEGORY_REC.SEGMENT1 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT1);
     -- L_CATEGORY_REC.SEGMENT2 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT2);
     -- L_CATEGORY_REC.SEGMENT3 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT3);
     -- L_CATEGORY_REC.SEGMENT4 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT4);
     -- L_CATEGORY_REC.SEGMENT5 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT5);
     -- L_CATEGORY_REC.SEGMENT6 := TO_CHAR (R_CAT_CODE_DETAILS.SEGMENT6);

    --  L_CATEGORY_REC.DESCRIPTION    := 'TEST';  
    
      
      --
      -- After the category record is loaded, then call the create_category api to
      -- create the new mtl_categories record.
      
      INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY
                                       (P_API_VERSION        => 1.0,
                                        P_INIT_MSG_LIST      => FND_API.G_TRUE,
                                        P_COMMIT             => FND_API.G_FALSE,
                                        X_RETURN_STATUS      => O_RETURN_STATUS,
                                        X_ERRORCODE          => O_ERRORCODE,
                                        X_MSG_COUNT          => O_MSG_COUNT,
                                        X_MSG_DATA           => O_MSG_DATA,
                                        P_CATEGORY_REC       => L_CATEGORY_REC,
                                        X_CATEGORY_ID        => V_CATEGORY_ID
                                       ); 

FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP4');
FND_FILE.PUT_LINE(FND_FILE.LOG,'O_RETURN_STATUS:'|| O_RETURN_STATUS);
FND_FILE.PUT_LINE(FND_FILE.LOG,'V_CATEGORY_ID:'|| V_CATEGORY_ID);
FND_FILE.PUT_LINE(FND_FILE.LOG,'O_MSG_COUNT:'|| O_MSG_COUNT);




IF (O_RETURN_STATUS = FND_API.G_RET_STS_SUCCESS)
      THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP5');

         FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Category successfully created. New Category Id = '|| V_CATEGORY_ID);
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.SEGMENT1);
         FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
         
         
         -- if successfull then call the next API to create valid cat
         
          INV_ITEM_CATEGORY_PUB.CREATE_VALID_CATEGORY (P_API_VERSION           => 1.0,
                                                      P_INIT_MSG_LIST      => FND_API.G_TRUE,
                                                      P_COMMIT             => FND_API.G_FALSE,
                                                      P_CATEGORY_SET_ID    => V_CATEGORY_SET_ID, -- for SandM
                                                      P_CATEGORY_ID        => V_CATEGORY_ID,
                                                      P_PARENT_CATEGORY_ID => NULL,
                                                      X_RETURN_STATUS      => L_RETURN_STATUS,
                                                      X_ERRORCODE          => L_ERRORCODE,
                                                      X_MSG_COUNT          => L_MSG_COUNT,
                                                      X_MSG_DATA           => L_MSG_DATA
                                                       );
    
          IF L_RETURN_STATUS = 'S'
               THEN
                  FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
                  FND_FILE.PUT_LINE (  FND_FILE.LOG, 'Valid Cat successfully created.');
                  FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.SEGMENT1);
                   FND_FILE.PUT_LINE (FND_FILE.LOG,'*****************');
                   
                  UPDATE XXINTG.XX_LOAD_UNIQUE_CAT
                   SET    ERROR_MESSAGE = NULL,
                      STATUS   = 'P'
                   WHERE  ROWID         = R_CAT_CODE_DETAILS.ROW_ID;   
                    
                  COMMIT;
                
                ELSE               


                    UPDATE XXINTG.XX_LOAD_UNIQUE_CAT
                      SET ERROR_MESSAGE = 'API- CREATE_VALID_CATEGORY failure',
                        STATUS          = 'E'
                      WHERE ROWID       = R_CAT_CODE_DETAILS.ROW_ID;
                      COMMIT;
                      RAISE E_EXCEPTION;
            
          END IF;
          
 ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP6');

         L_ERROR_DESC := NVL (L_ERROR_DESC, '') || '#API Error while creating Category';
         l_conv_status := 'ERROR';
         FND_FILE.PUT_LINE (FND_FILE.LOG,'API STATUS : ' || O_RETURN_STATUS);
         FND_FILE.PUT_LINE ( FND_FILE.LOG,  'Segment Combination = '|| R_CAT_CODE_DETAILS.segment1|| SQLERRM);

         IF o_msg_count > 0
         THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP7');

            FND_FILE.PUT_LINE (FND_FILE.LOG,O_ERRORCODE);
            FND_FILE.PUT_LINE (FND_FILE.LOG,o_msg_data);

            FOR i IN 1 .. o_msg_count
            LOOP
               FND_FILE.PUT_LINE
                      (  FND_FILE.LOG, i|| '.'|| SUBSTR(fnd_msg_pub.get (p_encoded      => fnd_api.g_false),1,255));
            END LOOP;
            

            update XXINTG.XX_LOAD_UNIQUE_CAT
             set    error_message = 'API- create_category failure',
                  STATUS   = 'E'
             where    ROWID         = R_CAT_CODE_DETAILS.row_id;            
            
            raise e_exception;
            
         END IF;
END IF;
      
      
             EXCEPTION WHEN    OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'STEP8');

             update XXINTG.XX_LOAD_UNIQUE_CAT
             set    error_message = 'OTHERS in the API loop',
                  STATUS   = 'E'
             where    ROWID         = R_CAT_CODE_DETAILS.row_id;

             raise e_exception;
      
            end; -- end1
           
         EXCEPTION WHEN    e_exception THEN
 
          FND_FILE.PUT_LINE(FND_FILE.LOG,'In e_exception'); 
             
        end; -- end1
        
      end loop;
      
 
  COMMIT; 
 EXCEPTION 
 
     WHEN e_no_structure THEN
     
        FND_FILE.PUT_LINE(FND_FILE.LOG,'There is no structure set for Container Item Category Set!');     
        
     WHEN OTHERS THEN 
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others error'); 
                       FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM); 

END;

END If;


EXCEPTION 
  
        
     WHEN OTHERS THEN 
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others error'); 
                       FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM); 

END LOAD_CAT_CODE_COMB;

END XX_UNIQUE_CAT_CODE_COMB; 
/
