DROP PACKAGE BODY APPS.XXINTG_DAILY_SLS_ONHAND_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_DAILY_SLS_ONHAND_PKG" AS
----------------------------------------------------------------------
/*
 Created By    : Ravi Vishnu
 Creation Date : 26-Aug-2014
 File Name     : XXINTG_DAILY_SLS_ONHAND_PKG
 Description   : This code is being written Onhand report for Daily Sales Reports

 Change History:
 Date         Name                  Remarks
 ----------- -------------         -----------------------------------
 26-Aug-2014  Ravi Vishnu          Initial Version
*/
----------------------------------------------------------------------
PROCEDURE Main   (pERRBUF OUT VARCHAR2,
                  pRETCODE OUT VARCHAR2,
                  pReportName IN VARCHAR,
                  pFromDate VARCHAR2,
                  pToDate VARCHAR2,
                  pEmail VARCHAR2,
                  pSalesRep IN NUMBER)
    IS
vRespId NUMBER       := fnd_global.resp_id;
vUserId NUMBER       := fnd_global.user_id;
vRespApplId NUMBER   := fnd_global.resp_appl_id;
vProgName VARCHAR2(20);
vRespName VARCHAR2(60);
vDivision VARCHAR2(10);
vRequestID                NUMBER := 0;
vRphase                   VARCHAR2(30);
vDphase                   VARCHAR2(30);
vDstatus                  VARCHAR2(30);
vRstatus                  VARCHAR2(30);
vMessage                  VARCHAR2(240);
vWaitStatus               BOOLEAN;
vTemplateApplication      VARCHAR2(30) := NULL;
vTemplateCode             VARCHAR2(30) := NULL;
vDefaultLanguage          VARCHAR2(30) := NULL;
vDefaultTerritory         VARCHAR2(30) := NULL;
vDefaultOutputType        VARCHAR2(30) := NULL;
vSetLayoutOption          BOOLEAN;
BEGIN

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Report Parameters -');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  ReportName         :'||pReportName );
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  From Date          :'||pFromDate   );
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  To Date            :'||pToDate  );
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  SalesRep           :'||pSalesRep  );


   BEGIN
	SELECT responsibility_name
	  INTO vRespName
	  FROM fnd_responsibility_tl frt
	 WHERE 1 = 1
	   AND frt.responsibility_id = vRespId
	   AND frt.application_id    = vRespApplId
	   AND frt.language = USERENV('LANG');
	EXCEPTION
	WHEN OTHERS THEN
	pRETCODE := 2;
	FND_FILE.PUT_LINE(FND_FILE.LOG, ' Exception while deriving responsibility with the error: '||SQLERRM ||'Error Code: '||SQLCODE);
	END;


	IF vRespName IS NOT NULL THEN   --Valid Responsibility

			vDivision := NULL;

			BEGIN
				   SELECT ffvtl.description
					 INTO vDivision
					 FROM fnd_flex_value_sets  ffvs,
						  fnd_flex_values ffv,
						  fnd_flex_values_tl ffvtl
					WHERE ffvs.flex_value_set_name = 'XXINTG_DAILY_SALES_DIVISIONS'
					  AND ffvs.flex_value_set_id   = ffv.flex_value_set_id
					  AND ffvtl.flex_value_id      = ffv.flex_value_id
					  AND SYSDATE BETWEEN NVL(ffv.start_date_active,sysdate) AND NVL(ffv.end_date_active,sysdate)
					  AND ffv.Enabled_flag         = 'Y'
					  AND upper(ffv.flex_value)    = upper(vRespName)
					  AND ffvtl.LANGUAGE           = userenv('LANG') ;
			EXCEPTION
			WHEN OTHERS THEN
			FND_FILE.PUT_LINE(FND_FILE.LOG, ' Exception while deriving Division :'||vDivision);
			END;

			FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  Responsibility Name    :'||vRespName  );
			FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  Division               :'||vDivision  );

			IF vDivision= 'RECON' THEN   --Division


               IF pReportName = 'Daily Booking' THEN       -- Report Name

				BEGIN

				   SELECT application_short_name,
              			  template_code,
						  default_language,
                          default_territory,
                          default_output_type
                     INTO vTemplateApplication,
                          vTemplateCode,
						  vDefaultLanguage,
                          vDefaultTerritory,
                          vDefaultOutputType
                     FROM xdo_templates_vl
                    WHERE template_code = 'INTGDLBOOKRECON'
                      AND NVL(end_date,SYSDATE) >= SYSDATE
                      AND object_version_number = (SELECT MAX(xdt1.object_version_number)
                                                     FROM xdo_templates_vl xdt1
                                                    WHERE xdt1.template_code = 'INTGDLBOOKRECON'
                                                      AND NVL(xdt1.end_date,SYSDATE) >= SYSDATE)
                      AND ROWNUM < 2;


                     vSetLayoutOption :=
                        fnd_request.add_layout (
                                                  template_appl_name   => vTemplateApplication
                                                  , template_code      => vTemplateCode
                                                  , template_language  => vDefaultLanguage
                                                  , template_territory => 'US'--vDefaultTerritory
                                                  , output_format      => 'EXCEL'   --vDefaultOutputType
                                                  );


		             vRequestID :=   FND_REQUEST.SUBMIT_REQUEST
                            (
                              application    =>'XXINTG',
                              program        =>'INTGDLBOOKRECON',
                              description    => NULL,
                              start_time     => NULL,
                              sub_request    => FALSE,
                              argument1      => vDivision,
                              argument2      => pFromDate,
                              argument3      => pToDate,
                              argument4      => pEmail,
                              argument5      => pSalesRep
                            );
                EXCEPTION
                WHEN OTHERS THEN
				pRETCODE := 2;
                fnd_file.put_line (fnd_file.LOG,'Error while calling Daily Booking Program: ' || SQLERRM);
                END;


				ELSIF pReportName = 'Invoice' THEN       -- Report Name

				BEGIN

				   SELECT application_short_name,
              			  template_code,
						  default_language,
                          default_territory,
                          default_output_type
                     INTO vTemplateApplication,
                          vTemplateCode,
						  vDefaultLanguage,
                          vDefaultTerritory,
                          vDefaultOutputType
                     FROM xdo_templates_vl
                    WHERE template_code = 'INTGPRINVRECON'
                      AND NVL(end_date,SYSDATE) >= SYSDATE
                      AND object_version_number = (SELECT MAX(xdt1.object_version_number)
                                                     FROM xdo_templates_vl xdt1
                                                    WHERE xdt1.template_code = 'INTGPRINVRECON'
                                                      AND NVL(xdt1.end_date,SYSDATE) >= SYSDATE)
                      AND ROWNUM < 2;


                     vSetLayoutOption :=
                        fnd_request.add_layout (
                                                  template_appl_name   => vTemplateApplication
                                                  , template_code      => vTemplateCode
                                                  , template_language  => vDefaultLanguage
                                                  , template_territory => 'US'--vDefaultTerritory
                                                  , output_format      => 'EXCEL'   --vDefaultOutputType
                                                  );


		             vRequestID :=   FND_REQUEST.SUBMIT_REQUEST
                            (
                              application    =>'XXINTG',
                              program        =>'INTGPRINVRECON',
                              description    => NULL,
                              start_time     => NULL,
                              sub_request    => FALSE,
                              argument1      => vDivision,
							  argument2      => fnd_date.canonical_to_date(pFromDate),
                              argument3      => pToDate,
                              argument4      => pEmail,
                              argument5      => NULL,
							  argument6      => pSalesRep
                            );
                EXCEPTION
                WHEN OTHERS THEN
				pRETCODE := 2;
                fnd_file.put_line (fnd_file.LOG,'Error while calling Daily Booking Program: ' || SQLERRM);
                END;

				ELSIF pReportName = 'Back Order' THEN       -- Report Name

				BEGIN

				   SELECT application_short_name,
              			  template_code,
						  default_language,
                          default_territory,
                          default_output_type
                     INTO vTemplateApplication,
                          vTemplateCode,
						  vDefaultLanguage,
                          vDefaultTerritory,
                          vDefaultOutputType
                     FROM xdo_templates_vl
                    WHERE template_code = 'INTGRECBKORDRPTRECON'
                      AND NVL(end_date,SYSDATE) >= SYSDATE
                      AND object_version_number = (SELECT MAX(xdt1.object_version_number)
                                                     FROM xdo_templates_vl xdt1
                                                    WHERE xdt1.template_code = 'INTGRECBKORDRPTRECON'
                                                      AND NVL(xdt1.end_date,SYSDATE) >= SYSDATE)
                      AND ROWNUM < 2;


                     vSetLayoutOption :=
                        fnd_request.add_layout (
                                                  template_appl_name   => vTemplateApplication
                                                  , template_code      => vTemplateCode
                                                  , template_language  => vDefaultLanguage
                                                  , template_territory => 'US'--vDefaultTerritory
                                                  , output_format      => 'EXCEL'   --vDefaultOutputType
                                                  );


		             vRequestID :=   FND_REQUEST.SUBMIT_REQUEST
                            (
                              application    =>'XXINTG',
                              program        =>'INTGRECBKORDRPTRECON',
                              description    => NULL,
                              start_time     => NULL,
                              sub_request    => FALSE,
                              argument1      => pFromDate,
                              argument2      => pToDate,
                              argument3      => vDivision,
                              argument4      => pEmail,
                              argument5      => pSalesRep
                            );
                EXCEPTION
                WHEN OTHERS THEN
				pRETCODE := 2;
                fnd_file.put_line (fnd_file.LOG,'Error while calling Daily Booking Program: ' || SQLERRM);
                END;


				END IF;                 -- Report Name

				ELSIF vDivision= 'NEURO' THEN   --Division

                IF pReportName = 'Daily Booking' THEN     -- Report Name

				BEGIN

				   SELECT application_short_name,
              			  template_code,
						  default_language,
                          default_territory,
                          default_output_type
                     INTO vTemplateApplication,
                          vTemplateCode,
						  vDefaultLanguage,
                          vDefaultTerritory,
                          vDefaultOutputType
                     FROM xdo_templates_vl
                    WHERE template_code = 'INTGDLBOOKNEURO'
                      AND NVL(end_date,SYSDATE) >= SYSDATE
                      AND object_version_number = (SELECT MAX(xdt1.object_version_number)
                                                     FROM xdo_templates_vl xdt1
                                                    WHERE xdt1.template_code = 'INTGDLBOOKNEURO'
                                                      AND NVL(xdt1.end_date,SYSDATE) >= SYSDATE)
                      AND ROWNUM < 2;


                     vSetLayoutOption :=
                        fnd_request.add_layout (
                                                  template_appl_name   => vTemplateApplication
                                                  , template_code      => vTemplateCode
                                                  , template_language  => vDefaultLanguage
                                                  , template_territory => 'US'--vDefaultTerritory
                                                  , output_format      => 'EXCEL'   --vDefaultOutputType
                                                  );


		             vRequestID :=   FND_REQUEST.SUBMIT_REQUEST
                            (
                              application    =>'XXINTG',
                              program        =>'INTGDLBOOKNEURO',
                              description    => NULL,
                              start_time     => NULL,
                              sub_request    => FALSE,
                              argument1      => vDivision,
                              argument2      => pFromDate,
                              argument3      => pToDate,
                              argument4      => pEmail,
                              argument5      => pSalesRep
                            );
                EXCEPTION
                WHEN OTHERS THEN
				pRETCODE := 2;
                fnd_file.put_line (fnd_file.LOG,'Error while calling Daily Booking Program: ' || SQLERRM);
                END;

				ELSIF pReportName = 'Invoice' THEN       -- Report Name

				BEGIN

				   SELECT application_short_name,
              			  template_code,
						  default_language,
                          default_territory,
                          default_output_type
                     INTO vTemplateApplication,
                          vTemplateCode,
						  vDefaultLanguage,
                          vDefaultTerritory,
                          vDefaultOutputType
                     FROM xdo_templates_vl
                    WHERE template_code = 'INTGPRINVNEURO'
                      AND NVL(end_date,SYSDATE) >= SYSDATE
                      AND object_version_number = (SELECT MAX(xdt1.object_version_number)
                                                     FROM xdo_templates_vl xdt1
                                                    WHERE xdt1.template_code = 'INTGPRINVNEURO'
                                                      AND NVL(xdt1.end_date,SYSDATE) >= SYSDATE)
                      AND ROWNUM < 2;


                     vSetLayoutOption :=
                        fnd_request.add_layout (
                                                  template_appl_name   => vTemplateApplication
                                                  , template_code      => vTemplateCode
                                                  , template_language  => vDefaultLanguage
                                                  , template_territory => 'US'--vDefaultTerritory
                                                  , output_format      => 'EXCEL'   --vDefaultOutputType
                                                  );


		             vRequestID :=   FND_REQUEST.SUBMIT_REQUEST
                            (
                              application    =>'XXINTG',
                              program        =>'INTGPRINVNEURO',
                              description    => NULL,
                              start_time     => NULL,
                              sub_request    => FALSE,
                              argument1      => vDivision,
                              argument2      => fnd_date.canonical_to_date(pFromDate),
                              argument3      => pToDate,
                              argument4      => pEmail,
                              argument5      => NULL,
							  argument6      => pSalesRep
                            );
                EXCEPTION
                WHEN OTHERS THEN
				pRETCODE := 2;
                fnd_file.put_line (fnd_file.LOG,'Error while calling Daily Booking Program: ' || SQLERRM);
                END;

				ELSIF pReportName = 'Back Order' THEN       -- Report Name

				BEGIN

				   SELECT application_short_name,
              			  template_code,
						  default_language,
                          default_territory,
                          default_output_type
                     INTO vTemplateApplication,
                          vTemplateCode,
						  vDefaultLanguage,
                          vDefaultTerritory,
                          vDefaultOutputType
                     FROM xdo_templates_vl
                    WHERE template_code = 'INTGRECBKORDRPTNEURO'
                      AND NVL(end_date,SYSDATE) >= SYSDATE
                      AND object_version_number = (SELECT MAX(xdt1.object_version_number)
                                                     FROM xdo_templates_vl xdt1
                                                    WHERE xdt1.template_code = 'INTGRECBKORDRPTNEURO'
                                                      AND NVL(xdt1.end_date,SYSDATE) >= SYSDATE)
                      AND ROWNUM < 2;


                     vSetLayoutOption :=
                        fnd_request.add_layout (
                                                  template_appl_name   => vTemplateApplication
                                                  , template_code      => vTemplateCode
                                                  , template_language  => vDefaultLanguage
                                                  , template_territory => 'US'--vDefaultTerritory
                                                  , output_format      => 'EXCEL'   --vDefaultOutputType
                                                  );


		             vRequestID :=   FND_REQUEST.SUBMIT_REQUEST
                            (
                              application    =>'XXINTG',
                              program        =>'INTGRECBKORDRPTNEURO',
                              description    => NULL,
                              start_time     => NULL,
                              sub_request    => FALSE,
                              argument1      => pFromDate,
                              argument2      => pToDate,
                              argument3      => vDivision,
                              argument4      => pEmail,
                              argument5      => pSalesRep
                            );
                EXCEPTION
                WHEN OTHERS THEN
				pRETCODE := 2;
                fnd_file.put_line (fnd_file.LOG,'Error while calling Daily Booking Program: ' || SQLERRM);
                END;

				END IF;                 -- Report Name

				ELSIF vDivision= 'INSTR' THEN   --Division

                IF pReportName = 'Daily Booking' THEN       -- Report Name

				BEGIN

				   SELECT application_short_name,
              			  template_code,
						  default_language,
                          default_territory,
                          default_output_type
                     INTO vTemplateApplication,
                          vTemplateCode,
						  vDefaultLanguage,
                          vDefaultTerritory,
                          vDefaultOutputType
                     FROM xdo_templates_vl
                    WHERE template_code = 'INTGDLBOOK'
                      AND NVL(end_date,SYSDATE) >= SYSDATE
                      AND object_version_number = (SELECT MAX(xdt1.object_version_number)
                                                     FROM xdo_templates_vl xdt1
                                                    WHERE xdt1.template_code = 'INTGDLBOOK'
                                                      AND NVL(xdt1.end_date,SYSDATE) >= SYSDATE)
                      AND ROWNUM < 2;


                     vSetLayoutOption :=
                        fnd_request.add_layout (
                                                  template_appl_name   => vTemplateApplication
                                                  , template_code      => vTemplateCode
                                                  , template_language  => vDefaultLanguage
                                                  , template_territory => 'US'--vDefaultTerritory
                                                  , output_format      => 'EXCEL'   --vDefaultOutputType
                                                  );


		             vRequestID :=   FND_REQUEST.SUBMIT_REQUEST
                            (
                              application    =>'XXINTG',
                              program        =>'INTGDLBOOK',
                              description    => NULL,
                              start_time     => NULL,
                              sub_request    => FALSE,
                              argument1      => vDivision,
                              argument2      => pFromDate,
                              argument3      => pToDate,
                              argument4      => pEmail,
                              argument5      => pSalesRep
                            );
                EXCEPTION
                WHEN OTHERS THEN
				pRETCODE := 2;
                fnd_file.put_line (fnd_file.LOG,'Error while calling Daily Booking Program: ' || SQLERRM);
                END;

				ELSIF pReportName = 'Invoice' THEN       -- Report Name

				BEGIN

				   SELECT application_short_name,
              			  template_code,
						  default_language,
                          default_territory,
                          default_output_type
                     INTO vTemplateApplication,
                          vTemplateCode,
						  vDefaultLanguage,
                          vDefaultTerritory,
                          vDefaultOutputType
                     FROM xdo_templates_vl
                    WHERE template_code = 'INTGPRINV'
                      AND NVL(end_date,SYSDATE) >= SYSDATE
                      AND object_version_number = (SELECT MAX(xdt1.object_version_number)
                                                     FROM xdo_templates_vl xdt1
                                                    WHERE xdt1.template_code = 'INTGPRINV'
                                                      AND NVL(xdt1.end_date,SYSDATE) >= SYSDATE)
                      AND ROWNUM < 2;


                     vSetLayoutOption :=
                        fnd_request.add_layout (
                                                  template_appl_name   => vTemplateApplication
                                                  , template_code      => vTemplateCode
                                                  , template_language  => vDefaultLanguage
                                                  , template_territory => 'US'--vDefaultTerritory
                                                  , output_format      => 'EXCEL'   --vDefaultOutputType
                                                  );


		             vRequestID :=   FND_REQUEST.SUBMIT_REQUEST
                            (
                              application    =>'XXINTG',
                              program        =>'INTGPRINV',
                              description    => NULL,
                              start_time     => NULL,
                              sub_request    => FALSE,
                              argument1      => vDivision,
                              argument2      => fnd_date.canonical_to_date(pFromDate),
                              argument3      => pToDate,
                              argument4      => pEmail,
                              argument5      => NULL,
							  argument6      => pSalesRep
                            );
                EXCEPTION
                WHEN OTHERS THEN
				pRETCODE := 2;
                fnd_file.put_line (fnd_file.LOG,'Error while calling Daily Booking Program: ' || SQLERRM);
                END;

				ELSIF pReportName = 'Back Order' THEN       -- Report Name

				BEGIN

				   SELECT application_short_name,
              			  template_code,
						  default_language,
                          default_territory,
                          default_output_type
                     INTO vTemplateApplication,
                          vTemplateCode,
						  vDefaultLanguage,
                          vDefaultTerritory,
                          vDefaultOutputType
                     FROM xdo_templates_vl
                    WHERE template_code = 'INTGRECBKORDRPT'
                      AND NVL(end_date,SYSDATE) >= SYSDATE
                      AND object_version_number = (SELECT MAX(xdt1.object_version_number)
                                                     FROM xdo_templates_vl xdt1
                                                    WHERE xdt1.template_code = 'INTGRECBKORDRPT'
                                                      AND NVL(xdt1.end_date,SYSDATE) >= SYSDATE)
                      AND ROWNUM < 2;


                     vSetLayoutOption :=
                        fnd_request.add_layout (
                                                  template_appl_name   => vTemplateApplication
                                                  , template_code      => vTemplateCode
                                                  , template_language  => vDefaultLanguage
                                                  , template_territory => 'US'--vDefaultTerritory
                                                  , output_format      => 'EXCEL'   --vDefaultOutputType
                                                  );


		             vRequestID :=   FND_REQUEST.SUBMIT_REQUEST
                            (
                              application    =>'XXINTG',
                              program        =>'INTGRECBKORDRPT',
                              description    => NULL,
                              start_time     => NULL,
                              sub_request    => FALSE,
                              argument1      => pFromDate,
                              argument2      => pToDate,
                              argument3      => vDivision,
                              argument4      => pEmail,
                              argument5      => pSalesRep
                            );
                EXCEPTION
                WHEN OTHERS THEN
				pRETCODE := 2;
                fnd_file.put_line (fnd_file.LOG,'Error while calling Daily Booking Program: ' || SQLERRM);
                END;

				END IF;                 -- Report Name

				END IF;  				--Division


    			COMMIT;

				fnd_file.put_line (fnd_file.LOG,'vRequestID is  ' || vRequestID);

		        --Request Submitted
				IF vRequestID <= 0
				THEN
						fnd_file.put_line (fnd_file.OUTPUT,' Unable to Submit INTG Daily Sales Booking Report - RECON');

				ELSE
						fnd_file.put_line (fnd_file.OUTPUT,' Submitted INTG Daily Sales Booking Report - RECON and request ID is ' ||vRequestID     || '. For more Details look the Log/Out of that request ' );

				  LOOP
					   vWaitStatus := FND_CONCURRENT.WAIT_FOR_REQUEST(
												vRequestID,   -- request_id
												5,            -- interval time b/w checks.
												0,            -- max_wait
												vRphase,      -- phase
												vRstatus,     -- status
												vDphase,      -- dev_phase
												vDstatus,     -- dev_status
												vMessage);    -- message

					   EXIT WHEN UPPER(vRphase) ='COMPLETED' OR UPPER(vDphase)='COMPLETE';
				  END LOOP;

				  END IF;     --Request Submitted

		COMMIT;

END IF;                 --Valid Responsibility

END Main;

END XXINTG_DAILY_SLS_ONHAND_PKG;
/
