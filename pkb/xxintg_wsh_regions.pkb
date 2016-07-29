DROP PACKAGE BODY APPS.XXINTG_WSH_REGIONS;

CREATE OR REPLACE PACKAGE BODY APPS.XXINTG_WSH_REGIONS AS
/*----------------------------------------------------------------------
 Created By     : Ravisankar
 Creation Date  : 25-Feb-2015
 File Name      : XXINTG_WSH_REGIONS.sql
 Description    : This script load the Region data using api.

Change History:

Version Date        Name                  Remarks
------- ----------- ---------            --------------------------------
1.0     25-Feb-2014 Ravisankar            Initial development.
-------------------------------------------------------------------------*/

 g_user_id     NUMBER     := apps.fnd_global.user_id;
 g_login_id    NUMBER     := apps.fnd_global.login_id;

PROCEDURE XXINTG_REGIONS (RETCODE OUT NUMBER,
	                     ERR_BUF OUT VARCHAR)
IS                    
 
   L_RETURN_STATUS VARCHAR2(1);
   L_MSG_COUNT NUMBER := 0;
   L_MSG_DATA  VARCHAR2(2000)  ;
   L_REGION_ID number:= 0;
   L_ZONE_ID number:= 0;
   L_STATUS VARCHAR2(1):='S';
   L_ERROR EXCEPTION;
   L_USER_ID NUMBER := g_user_id;
   L_COUNT NUMBER := 0;
   L_PARENT_REGION number :=-1;
 
   CURSOR CUR_FOR_REC 
   IS
		SELECT  X.ROWID, X.* FROM XXINTG_REG X
		WHERE 1 = 1
		--AND COUNTRY_CODE='AR'
		START WITH PARENT_REGION_ID = -1
		CONNECT BY PRIOR REGION_ID = PARENT_REGION_ID;
   
BEGIN
--- getting the old region_id

  FOR C_FOR_REC IN CUR_FOR_REC
	LOOP
  BEGIN		
  --L_STATUS:='S';
     IF C_FOR_REC.PARENT_REGION_ID <> -1 THEN
	 BEGIN
	   SELECT NEW_REGION INTO L_PARENT_REGION
	   FROM XXINTG_REG
	   WHERE REGION_ID = C_FOR_REC.PARENT_REGION_ID;	   
	 EXCEPTION
	 WHEN OTHERS THEN
	 L_PARENT_REGION := -1;
	 FND_FILE.PUT_LINE(FND_FILE.LOG,'Fetching Parent Regtion ID error'||'--'||C_FOR_REC.PARENT_REGION_ID);
	 END;
   ELSE
	L_PARENT_REGION := -1;
   END IF;	 
  -- Region Creation	
 -- FND_FILE.PUT_LINE(FND_FILE.LOG,'Before API--'||C_FOR_REC.REGION_ID);
 -- FND_FILE.PUT_LINE(FND_FILE.LOG,'Parent Region Id--'||l_parent_region);
  WSH_REGIONS_PKG.Insert_Region (
     p_country_code    		   => C_FOR_REC.COUNTRY_CODE
    ,p_country_region_code 	   => C_FOR_REC.COUNTRY_REGION_CODE --NULL
    ,p_state_code      		   => C_FOR_REC.STATE_CODE --null 
    ,p_city_code        	   => C_FOR_REC.CITY_CODE -- null
    ,p_port_flag         	   => C_FOR_REC.PORT_FLAG  -- Null
    ,p_airport_flag            => C_FOR_REC.AIRPORT_FLAG -- Null
    ,p_road_terminal_flag      => C_FOR_REC.ROAD_TERMINAL_FLAG  -- Null
    ,p_rail_terminal_flag      => C_FOR_REC.RAIL_TERMINAL_FLAG -- Null
    ,p_longitude       		   => C_FOR_REC.LONGITUDE    -- Null
    ,p_latitude       		   => C_FOR_REC.LATITUDE -- Null
    ,p_timezone        		   => C_FOR_REC.TIMEZONE -- Null
    ,p_continent       		   => C_FOR_REC.CONTINENT  -- Null
    ,p_country       		   => C_FOR_REC.COUNTRY
    ,p_country_region    	   => C_FOR_REC.COUNTRY_REGION -- Null
    ,p_state          		   => C_FOR_REC.STATE
    ,p_city            		   => C_FOR_REC.CITY -- Null
    ,p_alternate_name   	   => C_FOR_REC.ALTERNATE_NAME -- Null
    ,p_county           	   => C_FOR_REC.COUNTY
    ,p_postal_code_from 	   => C_FOR_REC.POSTAL_CODE_FROM  -- NULL
    ,p_postal_code_to   	   => C_FOR_REC.POSTAL_CODE_TO
    ,p_lang_code      		   => 'US' --C_FOR_REC.COUNTRY_CODE
    ,p_interface_flag  		   => NULL
    ,p_tl_only_flag        	   => 'N'
    ,p_region_id  		       => C_FOR_REC.REGION_ID 
    ,p_parent_region_id        => L_PARENT_REGION--C_FOR_REC.PARENT_REGION_ID
    ,p_user_id            	   => L_USER_ID
    ,p_insert_parent_flag      => NULL
    ,p_region_dff         	   => NULL 
    ,x_region_id   		       => L_REGION_ID
    ,x_status        		   => L_RETURN_STATUS
    ,x_error_msg 		       => L_MSG_DATA
    ,p_deconsol_location_id    => NULL --C_FOR_REC.DECONSOL_LOCATION_ID
    ,p_conc_request_flag 	   => 'N');
		FND_FILE.PUT_LINE(FND_FILE.LOG,'old REGION_ID--'||C_FOR_REC.REGION_ID);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'L_REGION_ID--'||L_REGION_ID);
		IF L_RETURN_STATUS <> 0 THEN
			UPDATE XXINTG_REG SET STATUS = 'E', ERROR_DESC = L_MSG_DATA
			  WHERE REGION_ID = C_FOR_REC.REGION_ID
			  AND PARENT_REGION_ID = C_FOR_REC.PARENT_REGION_ID;
			FND_FILE.PUT_LINE(FND_FILE.LOG,'WSH_REGIONS_PKG.INSERT_REGION IS ERROR'||'--'||L_MSG_DATA);
			FND_FILE.PUT_LINE(FND_FILE.LOG,'L_MSG_DATA --' || L_MSG_DATA);
			FND_FILE.PUT_LINE(FND_FILE.LOG,'L_RETURN_STATUS --' || L_RETURN_STATUS);
		  ELSE
		    UPDATE XXINTG_REG SET STATUS = 'P', NEW_REGION = L_REGION_ID
			  WHERE REGION_ID = C_FOR_REC.REGION_ID
			  AND PARENT_REGION_ID = C_FOR_REC.PARENT_REGION_ID;
			--FND_FILE.PUT_LINE(FND_FILE.LOG,'WSH_REGIONS_PKG.Insert_Region is Success');
			--FND_FILE.PUT_LINE(FND_FILE.LOG,'L_REGION_ID' || L_REGION_ID);
		END IF;	
      --commit;
     L_COUNT := L_COUNT + 1;	  
	
	IF L_COUNT = 1000  THEN
		COMMIT;
		L_COUNT:=0;
    END IF;
   	--COMMIT;  
 EXCEPTION
 WHEN OTHERS THEN
  UPDATE XXINTG_REG SET STATUS = 'E'
   WHERE ROWID = C_FOR_REC.ROWID;
 COMMIT;     
 END;
 END LOOP;
 COMMIT;
	FND_FILE.PUT_LINE(FND_FILE.LOG,'ZONE and REGION creation is Success');
EXCEPTION
WHEN OTHERS THEN
	RETCODE:=2;
	ERR_BUF:=SQLERRM;
END XXINTG_REGIONS;
END XXINTG_WSH_REGIONS;
/
