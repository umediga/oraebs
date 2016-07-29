DROP PACKAGE BODY APPS.XX_LOAD_CARRIER_SERVICE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.XX_LOAD_CARRIER_SERVICE_PKG IS
/*+=====================================================================================+
| Header: XX_LOAD_CARRIER_SERVICE_PKG.pkb                                               |
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
| 1.0       26-Feb-2015 Venkat Kumar S       Initial Version                            |
+======================================================================================*/
   
 PROCEDURE XX_LOAD_MAIN_PRC ( errorbuf         OUT  VARCHAR2
                            , retcode          OUT  NUMBER 
                            , pc_freight_code    IN  VARCHAR2							   
                            )
 IS 
   -- CURSOR DECLARATION
    CURSOR lcu_load_freight_data(pc_freight_code IN VARCHAR2)
    IS
    SELECT 
    wc.FREIGHT_CODE
   ,wc.SCAC_CODE
   ,wc.MANIFESTING_ENABLED_FLAG
   ,wc.CURRENCY_CODE
   ,wc.GENERIC_FLAG
   ,wc.FREIGHT_BILL_AUTO_APPROVAL
   ,wc.FREIGHT_AUDIT_LINE_LEVEL
   ,wc.SUPPLIER_ID
   ,wc.SUPPLIER_SITE_ID
   ,wc.MAX_NUM_STOPS_PERMITTED
   ,wc.MAX_TOTAL_DISTANCE
   ,wc.MAX_TOTAL_TIME
   ,wc.ALLOW_INTERSPERSE_LOAD
   ,wc.MIN_LAYOVER_TIME
   ,wc.MAX_LAYOVER_TIME
   ,wc.MAX_TOTAL_DISTANCE_IN_24HR
   ,wc.MAX_DRIVING_TIME_IN_24HR
   ,wc.MAX_DUTY_TIME_IN_24HR
   ,wc.ALLOW_CONTINUOUS_MOVE
   ,wc.MAX_CM_DISTANCE
   ,wc.MAX_CM_TIME
   ,wc.MAX_CM_DH_DISTANCE
   ,wc.MAX_CM_DH_TIME
   ,wc.MIN_CM_DISTANCE
   ,wc.MIN_CM_TIME
   ,wc.CM_FREE_DH_MILEAGE
   ,wc.CM_FIRST_LOAD_DISCOUNT
   ,wc.CM_RATE_VARIANT
   ,wc.MAX_SIZE_WIDTH
   ,wc.MAX_SIZE_HEIGHT
   ,wc.MAX_SIZE_LENGTH
   ,wc.MIN_SIZE_WIDTH
   ,wc.MIN_SIZE_HEIGHT
   ,wc.MIN_SIZE_LENGTH
   ,wc.TIME_UOM
   ,wc.DIMENSION_UOM
   ,wc.DISTANCE_UOM
   ,wc.WEIGHT_UOM
   ,wc.VOLUME_UOM
   ,wc.MAX_OUT_OF_ROUTE
   ,wc.DISTANCE_CALCULATION_METHOD
   ,wc.ORIGIN_DSTN_SURCHARGE_LEVEL
   ,wc.UNIT_RATE_BASIS
   ,wc.DIM_DIMENSIONAL_FACTOR
   ,wc.DIM_WEIGHT_UOM
   ,wc.DIM_VOLUME_UOM
   ,wc.DIM_DIMENSION_UOM
   ,wc.DIM_MIN_PACK_VOL    
  FROM XX_CARRIER_SERVICES  wc
 WHERE wc.FREIGHT_CODE  = NVL(pc_freight_code,wc.FREIGHT_CODE)
 GROUP BY wc.FREIGHT_CODE
   ,wc.SCAC_CODE
   ,wc.MANIFESTING_ENABLED_FLAG
   ,wc.CURRENCY_CODE
   ,wc.GENERIC_FLAG
   ,wc.FREIGHT_BILL_AUTO_APPROVAL
   ,wc.FREIGHT_AUDIT_LINE_LEVEL
   ,wc.SUPPLIER_ID
   ,wc.SUPPLIER_SITE_ID
   ,wc.MAX_NUM_STOPS_PERMITTED
   ,wc.MAX_TOTAL_DISTANCE
   ,wc.MAX_TOTAL_TIME
   ,wc.ALLOW_INTERSPERSE_LOAD
   ,wc.MIN_LAYOVER_TIME
   ,wc.MAX_LAYOVER_TIME
   ,wc.MAX_TOTAL_DISTANCE_IN_24HR
   ,wc.MAX_DRIVING_TIME_IN_24HR
   ,wc.MAX_DUTY_TIME_IN_24HR
   ,wc.ALLOW_CONTINUOUS_MOVE
   ,wc.MAX_CM_DISTANCE
   ,wc.MAX_CM_TIME
   ,wc.MAX_CM_DH_DISTANCE
   ,wc.MAX_CM_DH_TIME
   ,wc.MIN_CM_DISTANCE
   ,wc.MIN_CM_TIME
   ,wc.CM_FREE_DH_MILEAGE
   ,wc.CM_FIRST_LOAD_DISCOUNT
   ,wc.CM_RATE_VARIANT
   ,wc.MAX_SIZE_WIDTH
   ,wc.MAX_SIZE_HEIGHT
   ,wc.MAX_SIZE_LENGTH
   ,wc.MIN_SIZE_WIDTH
   ,wc.MIN_SIZE_HEIGHT
   ,wc.MIN_SIZE_LENGTH
   ,wc.TIME_UOM
   ,wc.DIMENSION_UOM
   ,wc.DISTANCE_UOM
   ,wc.WEIGHT_UOM
   ,wc.VOLUME_UOM
   ,wc.MAX_OUT_OF_ROUTE
   ,wc.DISTANCE_CALCULATION_METHOD
   ,wc.ORIGIN_DSTN_SURCHARGE_LEVEL
   ,wc.UNIT_RATE_BASIS
   ,wc.DIM_DIMENSIONAL_FACTOR
   ,wc.DIM_WEIGHT_UOM
   ,wc.DIM_VOLUME_UOM
   ,wc.DIM_DIMENSION_UOM
   ,wc.DIM_MIN_PACK_VOL
   ;
   
    CURSOR lcu_ORG_FREIGHT_DATA(p_freight_code IN VARCHAR2)
    IS
    SELECT 
    XCS.FREIGHT_CODE
   ,XCS.ORGANIZATION_ID
   ,XCS.ORGANIZATION_CODE
   ,XCS.ENABLED_FLAG_ORG
    FROM XX_CARRIER_SERVICES  xCS
    WHERE xCS.FREIGHT_CODE  = p_freight_code
    GROUP BY XCS.FREIGHT_CODE
   ,XCS.ORGANIZATION_ID
   ,XCS.ORGANIZATION_CODE
   ,XCS.ENABLED_FLAG_ORG

	;
	
    CURSOR lcu_service_data_cur(p_freight_code IN VARCHAR2)
    IS
    SELECT 
    XCS.MODE_OF_TRANSPORT_S
   ,XCS.ENABLED_FLAG_S
   ,XCS.WEB_ENABLED_S
   ,XCS.SERVICE_LEVEL_S
   ,XCS.MIN_SL_TIME_S
   ,XCS.MAX_SL_TIME_S
   ,XCS.SL_TIME_UOM_S
   ,XCS.SHIP_METHOD_CODE_S
   ,XCS.SHIP_METHOD_MEANING_S
   ,XCS.MAX_NUM_STOPS_PERMITTED_S
   ,XCS.MAX_TOTAL_DISTANCE_S
   ,XCS.MAX_TOTAL_TIME_S
   ,XCS.ALLOW_INTERSPERSE_LOAD_S
   ,XCS.MAX_LAYOVER_TIME_S
   ,XCS.MIN_LAYOVER_TIME_S
   ,XCS.MAX_TOTAL_DISTANCE_IN_24HR_S
   ,XCS.MAX_DRIVING_TIME_IN_24HR_S
   ,XCS.MAX_DUTY_TIME_IN_24HR_S
   ,XCS.ALLOW_CONTINUOUS_MOVE_S
   ,XCS.MAX_CM_DISTANCE_S
   ,XCS.MAX_CM_TIME_S
   ,XCS.MAX_CM_DH_DISTANCE_S
   ,XCS.MAX_CM_DH_TIME_S
   ,XCS.MAX_SIZE_WIDTH_S
   ,XCS.MAX_SIZE_HEIGHT_S
   ,XCS.MAX_SIZE_LENGTH_S
   ,XCS.MIN_SIZE_WIDTH_S
   ,XCS.MIN_SIZE_HEIGHT_S
   ,XCS.MIN_SIZE_LENGTH_S
   ,XCS.MAX_OUT_OF_ROUTE_S
   ,XCS.CM_FREE_DH_MILEAGE_S
   ,XCS.MIN_CM_DISTANCE_S
   ,XCS.CM_FIRST_LOAD_DISCOUNT_S
   ,XCS.MIN_CM_TIME_S
   ,XCS.UNIT_RATE_BASIS_S
   ,XCS.CM_RATE_VARIANT_S
   ,XCS.DISTANCE_CALCULATION_METHOD_S
   ,XCS.ORIGIN_DSTN_SURCHARGE_LEVEL_S
   ,XCS.DIM_DIMENSIONAL_FACTOR_S
   ,XCS.DIM_WEIGHT_UOM_S
   ,XCS.DIM_VOLUME_UOM_S
   ,XCS.DIM_DIMENSION_UOM_S
   ,XCS.DIM_MIN_PACK_VOL_S
   ,XCS.DEFAULT_VEHICLE_TYPE_ID
   ,XCS.UPDATE_MOT_SL
    FROM XX_CARRIER_SERVICES  XCS
    WHERE FREIGHT_CODE  = p_freight_code
    GROUP BY 
    XCS.MODE_OF_TRANSPORT_S
   ,XCS.ENABLED_FLAG_S
   ,XCS.WEB_ENABLED_S
   ,XCS.SERVICE_LEVEL_S
   ,XCS.MIN_SL_TIME_S
   ,XCS.MAX_SL_TIME_S
   ,XCS.SL_TIME_UOM_S
   ,XCS.SHIP_METHOD_CODE_S
   ,XCS.SHIP_METHOD_MEANING_S
   ,XCS.MAX_NUM_STOPS_PERMITTED_S
   ,XCS.MAX_TOTAL_DISTANCE_S
   ,XCS.MAX_TOTAL_TIME_S
   ,XCS.ALLOW_INTERSPERSE_LOAD_S
   ,XCS.MAX_LAYOVER_TIME_S
   ,XCS.MIN_LAYOVER_TIME_S
   ,XCS.MAX_TOTAL_DISTANCE_IN_24HR_S
   ,XCS.MAX_DRIVING_TIME_IN_24HR_S
   ,XCS.MAX_DUTY_TIME_IN_24HR_S
   ,XCS.ALLOW_CONTINUOUS_MOVE_S
   ,XCS.MAX_CM_DISTANCE_S
   ,XCS.MAX_CM_TIME_S
   ,XCS.MAX_CM_DH_DISTANCE_S
   ,XCS.MAX_CM_DH_TIME_S
   ,XCS.MAX_SIZE_WIDTH_S
   ,XCS.MAX_SIZE_HEIGHT_S
   ,XCS.MAX_SIZE_LENGTH_S
   ,XCS.MIN_SIZE_WIDTH_S
   ,XCS.MIN_SIZE_HEIGHT_S
   ,XCS.MIN_SIZE_LENGTH_S
   ,XCS.MAX_OUT_OF_ROUTE_S
   ,XCS.CM_FREE_DH_MILEAGE_S
   ,XCS.MIN_CM_DISTANCE_S
   ,XCS.CM_FIRST_LOAD_DISCOUNT_S
   ,XCS.MIN_CM_TIME_S
   ,XCS.UNIT_RATE_BASIS_S
   ,XCS.CM_RATE_VARIANT_S
   ,XCS.DISTANCE_CALCULATION_METHOD_S
   ,XCS.ORIGIN_DSTN_SURCHARGE_LEVEL_S
   ,XCS.DIM_DIMENSIONAL_FACTOR_S
   ,XCS.DIM_WEIGHT_UOM_S
   ,XCS.DIM_VOLUME_UOM_S
   ,XCS.DIM_DIMENSION_UOM_S
   ,XCS.DIM_MIN_PACK_VOL_S
   ,XCS.DEFAULT_VEHICLE_TYPE_ID
   ,XCS.UPDATE_MOT_SL;
   	
   g_user_id               NUMBER     :=apps.fnd_global.user_id;
   g_login_id              NUMBER     :=apps.fnd_global.login_id;
   lc_ROWID                VARCHAR2(1000); 
   xc_Rowid                VARCHAR2(1000);   
   xn_Carrier_Service_id   NUMBER;   
   xc_Return_Status        VARCHAR2(1000);   
   xn_position             NUMBER;   
   xc_procedure            VARCHAR2(1000);   
   xc_sqlerr               VARCHAR2(1000);   
   xc_sql_code             VARCHAR2(1000);   
   l_Carrier_Id            NUMBER;
   l_carrier_name          VARCHAR2(1000);
   l_status                VARCHAR2(1000);
   l_organization_id       VARCHAR2(10);
   l_Carrier_Rec_Type      WSH_CARRIERS_GRP.Carrier_Rec_Type;
   lr_service_rec          WSH_CARRIER_SERVICES_PKG.CSRecType;
   o_Carrier_Rec_Type      WSH_CARRIERS_GRP.Carrier_Out_Rec_Type;
   o_org_carrier_rec_type  WSH_CARRIERS_GRP.Org_Carrier_Ser_Out_Tab_Type;
   o_status                VARCHAR2(100);
   o_msg_count             NUMBER;
   o_msg_data              VARCHAR2(2000);
   o_org_status            VARCHAR2(100);
   o_org_msg_count         NUMBER;
   o_org_msg_data          VARCHAR2(2000);

   BEGIN 
   
     FOR lr_LOAD_DATA_REC IN lcu_LOAD_FREIGHT_DATA(pc_freight_code)

     LOOP 
	       
       /*########################################
         Loading Freight Data using API
        ##########################################*/
		
       lc_ROWID := NULL;--lr_LOAD_DATA_REC.ROWID;
       l_Carrier_Rec_Type := NULL;
       o_Carrier_Rec_Type := NULL;
		   
		   
       l_Carrier_Rec_Type.CARRIER_ID                  := NULL;
       l_Carrier_Rec_Type.FREIGHT_CODE                := lr_LOAD_DATA_REC.FREIGHT_CODE;
       l_Carrier_Rec_Type.SCAC_CODE                   := lr_LOAD_DATA_REC.SCAC_CODE;
       l_Carrier_Rec_Type.MANIFESTING_ENABLED_FLAG    := lr_LOAD_DATA_REC.MANIFESTING_ENABLED_FLAG;
       l_Carrier_Rec_Type.CURRENCY_CODE               := lr_LOAD_DATA_REC.CURRENCY_CODE;
       l_Carrier_Rec_Type.CREATION_DATE               := SYSDATE;
       l_Carrier_Rec_Type.CREATED_BY                  := g_user_id; --fnd_global.user_id
       l_Carrier_Rec_Type.LAST_UPDATE_DATE            := SYSDATE;
       l_Carrier_Rec_Type.LAST_UPDATED_BY             := g_user_id; --fnd_global.user_id
       l_Carrier_Rec_Type.CARRIER_NAME                := lr_LOAD_DATA_REC.FREIGHT_CODE;
       l_Carrier_Rec_Type.MAX_NUM_STOPS_PERMITTED     := lr_LOAD_DATA_REC.MAX_NUM_STOPS_PERMITTED;
       l_Carrier_Rec_Type.MAX_TOTAL_DISTANCE          := lr_LOAD_DATA_REC.MAX_TOTAL_DISTANCE;
       l_Carrier_Rec_Type.MAX_TOTAL_TIME              := lr_LOAD_DATA_REC.MAX_TOTAL_TIME;
       l_Carrier_Rec_Type.ALLOW_INTERSPERSE_LOAD      := lr_LOAD_DATA_REC.ALLOW_INTERSPERSE_LOAD;
       l_Carrier_Rec_Type.MAX_LAYOVER_TIME            := lr_LOAD_DATA_REC.MAX_LAYOVER_TIME;
       l_Carrier_Rec_Type.MIN_LAYOVER_TIME            := lr_LOAD_DATA_REC.MIN_LAYOVER_TIME;
       l_Carrier_Rec_Type.MAX_TOTAL_DISTANCE_IN_24HR  := lr_LOAD_DATA_REC.MAX_TOTAL_DISTANCE_IN_24HR;
       l_Carrier_Rec_Type.MAX_DRIVING_TIME_IN_24HR    := lr_LOAD_DATA_REC.MAX_DRIVING_TIME_IN_24HR;
       l_Carrier_Rec_Type.MAX_DUTY_TIME_IN_24HR       := lr_LOAD_DATA_REC.MAX_DUTY_TIME_IN_24HR;
       l_Carrier_Rec_Type.ALLOW_CONTINUOUS_MOVE       := lr_LOAD_DATA_REC.ALLOW_CONTINUOUS_MOVE;
       l_Carrier_Rec_Type.MAX_CM_DISTANCE             := lr_LOAD_DATA_REC.MAX_CM_DISTANCE;
       l_Carrier_Rec_Type.MAX_CM_TIME                 := lr_LOAD_DATA_REC.MAX_CM_TIME;
       l_Carrier_Rec_Type.MAX_CM_DH_DISTANCE          := lr_LOAD_DATA_REC.MAX_CM_DH_DISTANCE;
       l_Carrier_Rec_Type.MAX_CM_DH_TIME              := lr_LOAD_DATA_REC.MAX_CM_DH_TIME;
       l_Carrier_Rec_Type.MAX_SIZE_WIDTH              := lr_LOAD_DATA_REC.MAX_SIZE_WIDTH;
       l_Carrier_Rec_Type.MAX_SIZE_HEIGHT             := lr_LOAD_DATA_REC.MAX_SIZE_HEIGHT;
       l_Carrier_Rec_Type.MAX_SIZE_LENGTH             := lr_LOAD_DATA_REC.MAX_SIZE_LENGTH;
       l_Carrier_Rec_Type.MIN_SIZE_WIDTH              := lr_LOAD_DATA_REC.MIN_SIZE_WIDTH;
       l_Carrier_Rec_Type.MIN_SIZE_HEIGHT             := lr_LOAD_DATA_REC.MIN_SIZE_HEIGHT;
       l_Carrier_Rec_Type.MIN_SIZE_LENGTH             := lr_LOAD_DATA_REC.MIN_SIZE_LENGTH;
       l_Carrier_Rec_Type.TIME_UOM                    := lr_LOAD_DATA_REC.TIME_UOM;
       l_Carrier_Rec_Type.DIMENSION_UOM               := lr_LOAD_DATA_REC.DIMENSION_UOM;
       l_Carrier_Rec_Type.DISTANCE_UOM                := lr_LOAD_DATA_REC.DISTANCE_UOM;
       l_Carrier_Rec_Type.MAX_OUT_OF_ROUTE            := lr_LOAD_DATA_REC.MAX_OUT_OF_ROUTE;
       l_Carrier_Rec_Type.CM_FREE_DH_MILEAGE          := lr_LOAD_DATA_REC.CM_FREE_DH_MILEAGE;
       l_Carrier_Rec_Type.MIN_CM_DISTANCE             := lr_LOAD_DATA_REC.MIN_CM_DISTANCE;
       l_Carrier_Rec_Type.CM_FIRST_LOAD_DISCOUNT      := lr_LOAD_DATA_REC.CM_FIRST_LOAD_DISCOUNT;
       l_Carrier_Rec_Type.MIN_CM_TIME                 := lr_LOAD_DATA_REC.MIN_CM_TIME;
       l_Carrier_Rec_Type.UNIT_RATE_BASIS             := lr_LOAD_DATA_REC.UNIT_RATE_BASIS;
       l_Carrier_Rec_Type.WEIGHT_UOM                  := lr_LOAD_DATA_REC.WEIGHT_UOM;
       l_Carrier_Rec_Type.VOLUME_UOM                  := lr_LOAD_DATA_REC.VOLUME_UOM;
       l_Carrier_Rec_Type.GENERIC_FLAG                := lr_LOAD_DATA_REC.GENERIC_FLAG;
       l_Carrier_Rec_Type.FREIGHT_BILL_AUTO_APPROVAL  := lr_LOAD_DATA_REC.FREIGHT_BILL_AUTO_APPROVAL;
       l_Carrier_Rec_Type.FREIGHT_AUDIT_LINE_LEVEL    := lr_LOAD_DATA_REC.FREIGHT_AUDIT_LINE_LEVEL;
       l_Carrier_Rec_Type.SUPPLIER_ID                 := lr_LOAD_DATA_REC.SUPPLIER_ID;
       l_Carrier_Rec_Type.SUPPLIER_SITE_ID            := lr_LOAD_DATA_REC.SUPPLIER_SITE_ID;
       l_Carrier_Rec_Type.CM_RATE_VARIANT             := lr_LOAD_DATA_REC.CM_RATE_VARIANT;
       l_Carrier_Rec_Type.DISTANCE_CALCULATION_METHOD := lr_LOAD_DATA_REC.DISTANCE_CALCULATION_METHOD;
       l_Carrier_Rec_Type.ORIGIN_DSTN_SURCHARGE_LEVEL := lr_LOAD_DATA_REC.ORIGIN_DSTN_SURCHARGE_LEVEL;
       l_Carrier_Rec_Type.DIM_DIMENSIONAL_FACTOR      := lr_LOAD_DATA_REC.DIM_DIMENSIONAL_FACTOR;
       l_Carrier_Rec_Type.DIM_WEIGHT_UOM              := lr_LOAD_DATA_REC.DIM_WEIGHT_UOM;
       l_Carrier_Rec_Type.DIM_VOLUME_UOM              := lr_LOAD_DATA_REC.DIM_VOLUME_UOM;
       l_Carrier_Rec_Type.DIM_DIMENSION_UOM           := lr_LOAD_DATA_REC.DIM_DIMENSION_UOM;
       l_Carrier_Rec_Type.DIM_MIN_PACK_VOL            := lr_LOAD_DATA_REC.DIM_MIN_PACK_VOL;
     
     
       WSH_CARRIERS_GRP.Create_Update_Carrier
       ( p_api_version_number     => 1.0,
         p_init_msg_list          => NULL,
         p_commit                 => NULL,
         p_action_code            => 'CREATE',
         p_rec_attr_tab           => l_Carrier_Rec_Type,
         p_carrier_name           => lr_LOAD_DATA_REC.FREIGHT_CODE,
         p_status                 => l_status,
         x_car_out_rec_tab        => o_Carrier_Rec_Type,
         x_return_status          => o_status,
         x_msg_count              => o_msg_count,
         x_msg_data               => o_msg_data
         );
       dbms_output.put_line('CARRIER_ID :'||o_Carrier_Rec_Type.CARRIER_ID);
       dbms_output.put_line('MSG :'||o_msg_data||' '||o_msg_count||' '||o_status);
       IF (fnd_msg_pub.count_msg > 0)THEN
         FOR i IN 1..fnd_msg_pub.count_msg
         LOOP
       
           fnd_msg_pub.get
           ( p_msg_index => i,
             p_encoded => 'F',
             p_data => o_msg_data,
             p_msg_index_out => o_msg_count
           );

           DBMS_OUTPUT.PUT_LINE('API ERROR: ' || o_msg_data);
         END LOOP;
         dbms_output.put_line( 'o_status'|| o_status ||'--'|| o_msg_count ||'--'|| o_msg_data);
       End if;
       
              -- OPEN CURSOR 
       FOR lr_service_data_rec IN lcu_SERVICE_DATA_CUR(lr_LOAD_DATA_REC.FREIGHT_CODE)
       	 
       LOOP 
       
        lr_service_rec.Carrier_Service_id            := NULL                                                ;
        lr_service_rec.Carrier_Id                    := o_Carrier_Rec_Type.CARRIER_ID                       ;
        lr_service_rec.mode_of_transport             := lr_service_data_rec.mode_of_transport_s             ;
        lr_service_rec.Enabled_Flag                  := lr_service_data_rec.Enabled_Flag_s                  ;
        lr_service_rec.Web_Enabled                   := lr_service_data_rec.Web_Enabled_s		    ; 
        lr_service_rec.service_level                 := lr_service_data_rec.service_level_s		    ;
        lr_service_rec.min_sl_time                   := lr_service_data_rec.min_sl_time_s                   ;
        lr_service_rec.max_sl_time                   := lr_service_data_rec.max_sl_time_s                   ;
        lr_service_rec.sl_time_uom                   := lr_service_data_rec.sl_time_uom_s                   ;
        lr_service_rec.ship_method_code              := lr_service_data_rec.ship_method_code_s              ;
        lr_service_rec.ship_method_meaning           := lr_service_data_rec.ship_method_meaning_s           ;
        lr_service_rec.Creation_Date                 := SYSDATE                                             ; 
        lr_service_rec.Created_By                    := g_user_id                                           ;
        lr_service_rec.Last_Update_Date              := SYSDATE                                             ; 
        lr_service_rec.Last_Updated_By               := g_user_id                                           ;
        lr_service_rec.Last_Update_Login             := g_login_id                                          ; 
        lr_service_rec.MAX_NUM_STOPS_PERMITTED       := lr_service_data_rec.MAX_NUM_STOPS_PERMITTED_s       ;
        lr_service_rec.MAX_TOTAL_DISTANCE            := lr_service_data_rec.MAX_TOTAL_DISTANCE_s            ;
        lr_service_rec.MAX_TOTAL_TIME                := lr_service_data_rec.MAX_TOTAL_TIME_s                ;
        lr_service_rec.ALLOW_INTERSPERSE_LOAD        := lr_service_data_rec.ALLOW_INTERSPERSE_LOAD_s        ;
        lr_service_rec.MAX_LAYOVER_TIME              := lr_service_data_rec.MAX_LAYOVER_TIME_s              ;
        lr_service_rec.MIN_LAYOVER_TIME              := lr_service_data_rec.MIN_LAYOVER_TIME_s              ;
        lr_service_rec.MAX_TOTAL_DISTANCE_IN_24HR    := lr_service_data_rec.MAX_TOTAL_DISTANCE_IN_24HR_s    ;
        lr_service_rec.MAX_DRIVING_TIME_IN_24HR      := lr_service_data_rec.MAX_DRIVING_TIME_IN_24HR_s      ;
        lr_service_rec.MAX_DUTY_TIME_IN_24HR         := lr_service_data_rec.MAX_DUTY_TIME_IN_24HR_s         ;
        lr_service_rec.ALLOW_CONTINUOUS_MOVE         := lr_service_data_rec.ALLOW_CONTINUOUS_MOVE_s         ;
        lr_service_rec.MAX_CM_DISTANCE               := lr_service_data_rec.MAX_CM_DISTANCE_s               ;
        lr_service_rec.MAX_CM_TIME                   := lr_service_data_rec.MAX_CM_TIME_s                   ;
        lr_service_rec.MAX_CM_DH_DISTANCE            := lr_service_data_rec.MAX_CM_DH_DISTANCE_s            ;
        lr_service_rec.MAX_CM_DH_TIME                := lr_service_data_rec.MAX_CM_DH_TIME_s                ;
        lr_service_rec.MAX_SIZE_WIDTH                := lr_service_data_rec.MAX_SIZE_WIDTH_s                ;
        lr_service_rec.MAX_SIZE_HEIGHT               := lr_service_data_rec.MAX_SIZE_HEIGHT_s               ;
        lr_service_rec.MAX_SIZE_LENGTH               := lr_service_data_rec.MAX_SIZE_LENGTH_s               ;
        lr_service_rec.MIN_SIZE_WIDTH                := lr_service_data_rec.MIN_SIZE_WIDTH_s                ;
        lr_service_rec.MIN_SIZE_HEIGHT               := lr_service_data_rec.MIN_SIZE_HEIGHT_s               ;
        lr_service_rec.MIN_SIZE_LENGTH               := lr_service_data_rec.MIN_SIZE_LENGTH_s               ;
        lr_service_rec.MAX_OUT_OF_ROUTE              := lr_service_data_rec.MAX_OUT_OF_ROUTE_s              ;
        lr_service_rec.CM_FREE_DH_MILEAGE            := lr_service_data_rec.CM_FREE_DH_MILEAGE_s            ;
        lr_service_rec.MIN_CM_DISTANCE               := lr_service_data_rec.MIN_CM_DISTANCE_s               ;
        lr_service_rec.CM_FIRST_LOAD_DISCOUNT        := lr_service_data_rec.CM_FIRST_LOAD_DISCOUNT_s        ;
        lr_service_rec.MIN_CM_TIME                   := lr_service_data_rec.MIN_CM_TIME_s                   ;
        lr_service_rec.UNIT_RATE_BASIS               := lr_service_data_rec.UNIT_RATE_BASIS_s               ;
        lr_service_rec.CM_RATE_VARIANT               := lr_service_data_rec.CM_RATE_VARIANT_s               ;
        lr_service_rec.DISTANCE_CALCULATION_METHOD   := lr_service_data_rec.DISTANCE_CALCULATION_METHOD_s   ;
        lr_service_rec.ORIGIN_DSTN_SURCHARGE_LEVEL   := lr_service_data_rec.ORIGIN_DSTN_SURCHARGE_LEVEL_s   ;
        lr_service_rec.DIM_DIMENSIONAL_FACTOR        := lr_service_data_rec.DIM_DIMENSIONAL_FACTOR_s        ;
        lr_service_rec.DIM_WEIGHT_UOM                := lr_service_data_rec.DIM_WEIGHT_UOM_s                ;
        lr_service_rec.DIM_VOLUME_UOM                := lr_service_data_rec.DIM_VOLUME_UOM_s                ;
        lr_service_rec.DIM_DIMENSION_UOM             := lr_service_data_rec.DIM_DIMENSION_UOM_s             ;
        lr_service_rec.DIM_MIN_PACK_VOL              := lr_service_data_rec.DIM_MIN_PACK_VOL_s              ;
        lr_service_rec.DEFAULT_VEHICLE_TYPE_ID       := lr_service_data_rec.DEFAULT_VEHICLE_TYPE_ID         ;
        lr_service_rec.UPDATE_MOT_SL                 := lr_service_data_rec.UPDATE_MOT_SL                   ;


        WSH_CARRIER_SERVICES_PKG.Create_Carrier_Service (
          p_Carrier_Service_Info      => lr_service_rec         
         , x_Rowid                     => xc_Rowid                   
         , x_Carrier_Service_id        => xn_Carrier_Service_id      
         , x_Return_Status             => xc_Return_Status           
         , x_position                  => xn_position                
         , x_procedure                 => xc_procedure               
         , x_sqlerr                    => xc_sqlerr                  
         , x_sql_code                  => xc_sql_code                
         );

        DBMS_OUTPUT.PUT_LINE('Create_Carrier_Service API RESULT: ' ||' '||xc_Return_Status||' '|| xc_sqlerr||' '||xc_sql_code);
	   

       END LOOP;
      
       FOR lr_org_freight_rec IN lcu_ORG_FREIGHT_DATA(lr_LOAD_DATA_REC.FREIGHT_CODE)
       LOOP
        DBMS_OUTPUT.PUT_LINE('Org Assign');
   	BEGIN
   	  SELECT organization_id
   	    INTO l_organization_id 
   	    FROM mtl_parameters
   	   WHERE organization_code = lr_org_freight_rec.ORGANIZATION_CODE
   	   ;
   	EXCEPTION
   	  WHEN NO_DATA_FOUND THEN
   	    l_organization_id := NULL;
   	END;
   	WSH_CARRIERS_GRP.Assign_Org_Carrier (
   	  p_api_version_number     => 1.0,
	  p_init_msg_list          => NULL,
	  p_commit                 => NULL,
	  p_action_code            => 'ASSIGN',
	  p_carrier_id             => o_Carrier_Rec_Type.CARRIER_ID,
	  p_organization_id        => l_organization_id, 
	  x_orgcar_ser_out_tab     => o_org_carrier_rec_type,
	  x_return_status          => o_org_status,
	  x_msg_count              => o_org_msg_count,
          x_msg_data               => o_org_msg_data
          );
        DBMS_OUTPUT.PUT_LINE('API Status: '||o_org_status);
        IF (fnd_msg_pub.count_msg > 0)THEN
          FOR i IN 1..fnd_msg_pub.count_msg
          LOOP

            fnd_msg_pub.get
            ( p_msg_index => i,
              p_encoded => 'F',
              p_data => o_org_msg_data,
              p_msg_index_out => o_org_msg_count
            );

            DBMS_OUTPUT.PUT_LINE('API ERROR: ' || o_org_msg_data);
          END LOOP;
          dbms_output.put_line( 'o_status'|| o_org_status ||'--'|| o_org_msg_count ||'--'|| o_org_msg_data);
        End if;   	     
   
      END LOOP;
   
    END LOOP;
END;

END XX_LOAD_CARRIER_SERVICE_PKG;
/
