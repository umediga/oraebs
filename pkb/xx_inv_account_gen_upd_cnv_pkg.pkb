DROP PACKAGE BODY APPS.XX_INV_ACCOUNT_GEN_UPD_CNV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_ACCOUNT_GEN_UPD_CNV_PKG" AS

----------------------------------------------------------------------------------
/* $Header: XXINVACCOUNTGENUPDCNV.pkb 1.0 2012/06/12 12:00:00 sujan noship $ */
/*
Created By    : IBM Development Team
Creation Date : 02-May-2012
File Name     : XXINVACCOUNTGENUPDCNV.pkb
Description   : This script creates the body for the Account Generation Revenue Conversion

Change History:

Version Date        Name                   Remarks
------- ----------- -------------------    ----------------------
1.0     20-Feb-12   IBM Development Team   Initial development.
1.0A    12-Jun-12   Sujan                  Changed GL segments as per new COA structure
*/
----------------------------------------------------------------------

--**********************************************************************
 ----Procedure to set environment.
--**********************************************************************
    PROCEDURE set_cnv_env (p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES
                          ) IS
    	x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
    	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside set_cnv_env...');
    	--G_REQUEST_ID	  := xx_emf_pkg.G_REQUEST_ID;
    	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_REQUEST_ID: '||G_REQUEST_ID );

    	-- Set the environment
    	x_error_code := xx_emf_pkg.set_env;
    	IF NVL (p_required_flag, xx_emf_cn_pkg.CN_YES) <> xx_emf_cn_pkg.CN_NO THEN
    		xx_emf_pkg.propagate_error(x_error_code);
    	END IF;
    EXCEPTION
    	WHEN OTHERS THEN
    		RAISE xx_emf_pkg.G_E_ENV_NOT_SET;
    END set_cnv_env;

--**********************************************************************
 ----Procedure to set debug level low.
--**********************************************************************

    PROCEDURE dbg_low (p_dbg_text varchar2)
    IS
        BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low
                                , 'In xx_hr_appl_cnv_validation_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_low;

--**********************************************************************
 ----Procedure to set debug level medium.
--**********************************************************************

   PROCEDURE dbg_med (p_dbg_text varchar2)
   IS
       BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium
                                , 'In xx_hr_appl_cnv_validation_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
   END dbg_med;


--**********************************************************************
-----Procedure to set debug level high.
--**********************************************************************

    PROCEDURE dbg_high (p_dbg_text varchar2)
      IS
      BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high
                                , 'In xx_hr_appl_cnv_validation_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_high;

--**********************************************************************

   PROCEDURE assign_global_var
   IS

   -------------------------------------------------------------------------------
    /*
    Created By     : IBM Technical Team
    Creation Date  : 09-MAY-2012
    Filename       :
    Description    : Procedure to assign global variables.

    Change History:

    Date        Version#    Name                Remarks
    ----------- --------    ---------------     -----------------------------------
    09-MAY-2012   1.0       IBM Technical Team         Initial development.
    */
    --------------------------------------------------------------------------------
      CURSOR cur_get_global_var_value(p_parameter IN VARCHAR2)
      IS
      SELECT emfpp.parameter_value
        FROM xx_emf_process_setup emfps,
             xx_emf_process_parameters emfpp
       WHERE emfps.process_id=emfpp.process_id
         AND emfps.process_name=g_process_name
         AND emfpp.parameter_name=p_parameter;
      x_parameter_name   VARCHAR2(60);
      x_parameter_value  VARCHAR2(60);
   BEGIN
      --Set CAT_SET_NAME
      OPEN cur_get_global_var_value('CAT_SET_NAME');
      FETCH cur_get_global_var_value INTO x_parameter_value;
      CLOSE cur_get_global_var_value;

      G_CAT_SET_NAME := x_parameter_value;


   EXCEPTION
     WHEN OTHERS THEN
       dbg_low('Error while assigning global variables: '||SQLERRM);

   END assign_global_var;
--**********************************************************************

PROCEDURE exec_submit_report_pr (p_request_id IN NUMBER)
IS
  ------------------------------------------------------------------------------
    /*
    Created By     : IBM Technical Team
    Creation Date  : 09-MAY-2012
    Filename       :
    Description    :Procedure to submit report

    Change History:

    Date        Version#    Name                Remarks
    ----------- --------    ---------------     -----------------------------------
    09-MAY-2012   1.0       IBM Technical Team         Initial development.
    */
    --------------------------------------------------------------------------------
      x_conc_request_id   NUMBER;
      x_phase             VARCHAR2 (100);
      x_status            VARCHAR2 (100);
      x_dev_phase         VARCHAR2 (100);
      x_dev_status        VARCHAR2 (100);
      x_message           VARCHAR2 (240);
      x_check             BOOLEAN;
      x_xml_layout        BOOLEAN;
   BEGIN
      dbg_low('Inside exec_submit_report_pr');


      x_xml_layout := FND_REQUEST.ADD_LAYOUT (template_appl_name =>'XXINTG',
                                              template_code =>'XXINVGEN',
                                              template_language =>'en',
                                              template_territory =>'US',
                                              output_format =>'EXCEL');
      x_conc_request_id :=
         fnd_request.submit_request
                                 (application      => 'XXINTG',
                                  program          => 'XXINVGEN',
                                  sub_request      => FALSE,
                                  argument1        => p_request_id
                                 );
      COMMIT;
      dbg_low ('Submitted the request exec_submit_report_pr');
      -- Wait for the completion of Report program
      x_check :=
         fnd_concurrent.wait_for_request (x_conc_request_id,
                                          1,
                                          0,
                                          x_phase,
                                          x_status,
                                          x_dev_phase,
                                          x_dev_status,
                                          x_message
                                         );
   EXCEPTION
      WHEN OTHERS
      THEN
         dbg_low('Error in exec_submit_report_pr'||SQLERRM);
   END exec_submit_report_pr;

--**********************************************************************
   PROCEDURE main( o_errbuf                 OUT VARCHAR2
                  ,o_retcode                OUT VARCHAR2
                  ,p_org_hierachy_name      IN VARCHAR2
                  ,p_inventory_organization IN NUMBER
                  ,p_item_number            IN VARCHAR2
                 ) IS
  ------------------------------------------------------------------------------
    /*
    Created By     : IBM Technical Team
    Creation Date  : 09-MAY-2012
    Filename       :
    Description    :Main Procedure

    Change History:

    Date        Version#    Name                Remarks
    ----------- --------    ---------------     -----------------------------------
    09-MAY-2012   1.0       IBM Technical Team         Initial development.
    */
    --------------------------------------------------------------------------------

 x_error_code          NUMBER                := xx_emf_cn_pkg.CN_SUCCESS;

CURSOR c_get_total_cnt IS
    SELECT COUNT (1) total_count
      FROM xx_inv_account_gen_stg
     WHERE request_id = G_REQUEST_ID;

    x_total_cnt NUMBER:=0;

CURSOR c_get_error_cnt IS
   SELECT SUM(error_count)
     FROM (SELECT COUNT (1) error_count
	     FROM xx_inv_account_gen_stg
	    WHERE request_id = G_REQUEST_ID
	     AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

   x_error_cnt NUMBER:=0;

CURSOR c_get_success_cnt IS
   SELECT COUNT (1) success_count
     FROM xx_inv_account_gen_stg
    WHERE request_id = G_REQUEST_ID
     AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
     AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

   x_success_cnt NUMBER:=0;

--**********************************************************************
    PROCEDURE mark_records_complete
    IS
    ------------------------------------------------------------------------------
    /*
    Created By     : IBM Technical Team
    Creation Date  : 09-MAY-2012
    Filename       :
    Description    :Procedure to mark records for complete

    Change History:

    Date        Version#    Name                Remarks
    ----------- --------    ---------------     -----------------------------------
    09-MAY-2012   1.0       IBM Technical Team         Initial development.
    */
    --------------------------------------------------------------------------------
		x_last_update_date       DATE   := SYSDATE;
		x_last_updated_by        NUMBER := fnd_global.user_id;
		x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

		PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
		dbg_low('Inside of mark records complete...');
		g_api_name := 'main.mark_records_complete';

		   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside mark_records_complete');

			UPDATE xx_inv_account_gen_stg
			  SET  error_code        = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
			       last_updated_by   = x_last_updated_by,
			       last_update_date  = x_last_update_date,
			       last_update_login = x_last_update_login
			 WHERE request_id   = G_REQUEST_ID
			   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);
		COMMIT;

	EXCEPTION
		WHEN OTHERS THEN
	            dbg_low('Error in Update of mark_records_complete '||SQLERRM);
	END mark_records_complete;
-----------------

--**********************************************************************
  PROCEDURE mark_records_for_api_error
  IS
  --------------------------------------------------------------------------------------
   -- Created By                 : Debasmita Sur Dam
   -- Creation Date              : 08-MAY-2012
   -- Description                : Used for marking staging table records with error for interface error records

   -- Parameters description:

   -- p_process_code             : process_code(IN)
   -----------------------------------------------------------------------------------------
      CURSOR cur_print_error_mast_records
     IS
     SELECT  mie.error_message
            ,xima.record_number
            ,mti.segment1
            ,msib.organization_id
            ,msib.cost_of_sales_account
            ,msib.sales_account
      FROM mtl_system_items_interface mti
          ,mtl_interface_errors mie
          ,mtl_system_items_b msib
          ,xx_inv_account_gen_stg xima
      WHERE mti.set_process_id    = g_set_process_id
        AND mti.transaction_id    = mie.transaction_id
        AND mti.request_id        = mie.request_id
        AND mti.organization_id   = mie.organization_id
        AND mti.organization_id   = msib.organization_id
        AND msib.inventory_item_id=mti.inventory_item_id
        AND xima.organization_id = mti.organization_id
        AND xima.inv_item_id = mti.inventory_item_id
        AND mti.ATTRIBUTE30 = xima.request_id
        AND xima.request_id = xx_emf_pkg.G_REQUEST_ID
        AND mie.error_message     IS NOT NULL;


      x_last_update_date       DATE := SYSDATE;
      x_last_updated_by        NUMBER := fnd_global.user_id;
      x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
      x_record_count           NUMBER := 0;
      x_cogs_segment5          VARCHAR2(25):=NULL;
      x_sales_segment5         VARCHAR2(25):=NULL;

     PRAGMA AUTONOMOUS_TRANSACTION;

    BEGIN
        dbg_low('Inside Mark Record for API Error');

   FOR cur_rec IN cur_print_error_mast_records
   LOOP

    BEGIN

     SELECT segment5
       INTO x_cogs_segment5
      FROM gl_code_combinations
      WHERE code_combination_id=cur_rec.cost_of_sales_account;


     SELECT segment5
       INTO x_sales_segment5
      FROM gl_code_combinations
      WHERE code_combination_id=cur_rec.sales_account;

    EXCEPTION
     WHEN OTHERS THEN
       dbg_low('Error in fetching segment5 from gl_code_combinations');

    END;
   -------


          UPDATE xx_inv_account_gen_stg xima
	     SET cogs_segment5=x_cogs_segment5,
                 sales_segment5=x_sales_segment5,
                 error_code   = xx_emf_cn_pkg.CN_REC_ERR,
                 error_mesg   = 'INTERFACE Error :'||' '||cur_rec.error_message,
		 last_updated_by   = x_last_updated_by,
		 last_update_date  = x_last_update_date,
		 last_update_login = x_last_update_login
	   WHERE  error_code    IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
             AND  record_number = cur_rec.record_number
	     AND Exists (SELECT 1
		           FROM mtl_system_items_interface msi
		          WHERE 1=1
		          AND msi.item_number     = xima.item_number
                          AND msi.organization_id   = xima.organization_id
                          AND msi.inventory_item_id = xima.inv_item_id
                          AND msi.ATTRIBUTE30 = xima.request_id
                          AND xima.request_id = xx_emf_pkg.G_REQUEST_ID
		          AND msi.process_flag <> 7
		        );

      END LOOP;
	   x_record_count := SQL%ROWCOUNT;
           dbg_low('No of Master Attribute Record Marked with API Error=>'||x_record_count);
	 COMMIT;

    EXCEPTION
     WHEN OTHERS THEN
       dbg_low('Error in Updating Staging tables with Error from Interface table');
   END mark_records_for_api_error;

---------------------------



------------------------------------------------------------
FUNCTION process_item_account_gen
    RETURN NUMBER
    IS
    --------------------------------------------------------------------------------------
   -- Created By                 : Debasmita Sur Dam
   -- Creation Date              : 03-May-2012
   -- Description                : This function is used to insert records in mtl_system_items_interface table
   --                              run the Item Open Interface in CREATE Mode

   -- Parameters description:

   -- return NUMBER
   -----------------------------------------------------------------------------------------


    x_return_status       VARCHAR2(15)  := xx_emf_cn_pkg.CN_SUCCESS;
    x_last_update_login   NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
    x_cmmit_org           NUMBER :=0;
    x_req_return_status   BOOLEAN;
    x_req_id              NUMBER;
    x_dev_phase           VARCHAR2(20);
    x_phase               VARCHAR2(20);
    x_dev_status          VARCHAR2(20);
    x_status              VARCHAR2(20);
    x_message             VARCHAR2(100);
    x_organization_id     NUMBER;
    x_org_err_code        VARCHAR2(30);
    x_org_err_msg         VARCHAR2(200);
    x_cnt                 NUMBER;

      CURSOR c_get_organization
      IS
      SELECT distinct organization_id
        FROM mtl_system_items_interface
       WHERE set_process_id =g_set_process_id
       ORDER by organization_id;


       --cursor to insert into ITEM interface table
       CURSOR c_xx_item_account_gen_upld IS
         SELECT *
           FROM xx_inv_account_gen_stg
           WHERE request_id   = xx_emf_pkg.G_REQUEST_ID
	    AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
	  ORDER BY record_number;


     BEGIN
      g_api_name := 'main.process_item_account_gen';

      dbg_med('Inside process_item_account_gen');

      --Get the set_process_id to group the extension runs

      BEGIN
         SELECT xx_inv_ac_gen_process_id_s.NEXTVAL
           INTO   G_SET_PROCESS_ID
         FROM   dual;
         dbg_low('Derived set_process_id'||G_SET_PROCESS_ID);
      EXCEPTION
       WHEN OTHERS THEN
           dbg_low('Unable to derive set_process_id'||SQLCODE||':'||SQLERRM);
      END;


    FOR c_xx_item_account_gen_rec IN c_xx_item_account_gen_upld
    LOOP
          x_cmmit_org := x_cmmit_org + 1;
         BEGIN

           INSERT INTO mtl_system_items_interface
               (
                inventory_item_id,
                organization_id,
                cost_of_sales_account,
                sales_account,
                attribute30,
                process_flag,
                transaction_type,
                set_process_id,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login
               )
            VALUES
               (c_xx_item_account_gen_rec.inv_item_id,
                c_xx_item_account_gen_rec.organization_id,
                c_xx_item_account_gen_rec.cogs_new_ccid,
                c_xx_item_account_gen_rec.sales_new_ccid,
                xx_emf_pkg.G_REQUEST_ID,
                G_PROCESS_FLAG,
                G_TRANS_TYPE_MAST,
                G_SET_PROCESS_ID,
                c_xx_item_account_gen_rec.created_by,
                SYSDATE,
                c_xx_item_account_gen_rec.last_updated_by,
                SYSDATE,
                c_xx_item_account_gen_rec.last_update_login
             );
          END;
          IF x_cmmit_org >= 10000 THEN -- Commit for every 10000 record
                 commit;
          END IF;
      END LOOP;
      commit;

      FOR cur_rec IN c_get_organization
      LOOP
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Open Interface Submit =>BEFORE'||cur_rec.organization_id);
       x_req_id :=FND_REQUEST.SUBMIT_REQUEST (application =>'INV'
                                            ,program => 'INCOIN'
                                            ,description => 'Item Open Interface'
                                            ,argument1 => cur_rec.organization_id
                                            ,argument2 => 2
                                            ,argument3 => 1
                                            ,argument4 => 1
                                            ,argument5 => 1
                                            ,argument6 => g_set_process_id
                                            ,argument7 => 2  --Update Items
                                            ,argument8 => 2  --Gather statistics = No
                                            );
       COMMIT;

      IF x_req_id > 0 THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Open Interface Submited for Organization attribute Updatation =>SUCCESS');
          x_req_return_status := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id      => x_req_id,
                                                                 INTERVAL        => 10,
                                                                 max_wait        => 0,
                                                                 phase           => x_phase,
                                                                 status          => x_status,
                                                                 dev_phase       => x_dev_phase,
                                                                 dev_status      => x_dev_status,
                                                                 message         => x_message
                                                                 );

      IF x_req_return_status = TRUE THEN
            dbg_low('Item Open Interface Submited for Organization Updatation Completed =>'||x_dev_status);
            dbg_low('Organization_id =>'||cur_rec.organization_id);
            mark_records_for_api_error;
            -- Print the records with API Error
            x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
          END IF;
        ELSE
          dbg_low('Error in Item Open Interface for Organization Updatation Submit');
          x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
                           ,p_category    =>      xx_emf_cn_pkg.CN_STG_APICALL
                           ,p_error_text  => 'Error in Item Open Interface for Organization Updatation Submit'
                           ,p_record_identifier_1 => 'Process level error : Exiting'
                           );
         END IF;
      END LOOP;

   RETURN x_return_status;
	       EXCEPTION
		       WHEN OTHERS THEN
			       dbg_low('Error while inserting into Standard Interface Tables: ' ||SQLERRM);
			       xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
			       x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
			       RETURN x_error_code;

   END process_item_account_gen;

--*****************************************************************


PROCEDURE insert_staging_table(p_org_hierachy_name      VARCHAR2,
                               p_inventory_organization NUMBER,
                               p_item_number            VARCHAR2)
IS
--------------------------------------------------------------
------ Created By                : Debasmita Sur Dam
   -- Creation Date              : 03-May-2012
   -- Description                : This function is used to insert records in XX_INV_ACCOUNT_GEN_STG table
   --

   -- Parameters description:

   -- return NUMBER
   -----------------------------------------------------------------------------------------
CURSOR c_item_detail IS
SELECT  msib.segment1        item_number
       ,msib.organization_id
       ,ord.organization_code
       ,msib.inventory_item_id
       ,msib.cost_of_sales_account
       ,gcc.segment1  cogs_segment1
       ,gcc.segment2  cogs_segment2
       ,gcc.segment3  cogs_segment3
       ,gcc.segment4  cogs_segment4
       ,gcc.segment5  cogs_segment5
       ,gcc.segment6  cogs_segment6
       ,gcc.segment7  cogs_segment7
       ,gcc.segment8  cogs_segment8
       ,gcc.segment9  cogs_segment9
       ,msib.sales_account
       ,gcc1.segment1 sales_segment1
       ,gcc1.segment2 sales_segment2
       ,gcc1.segment3 sales_segment3
       ,gcc1.segment4 sales_segment4
       ,gcc1.segment5 sales_segment5
       ,gcc1.segment6 sales_segment6
       ,gcc1.segment7 sales_segment7
       ,gcc1.segment8 sales_segment8
       ,gcc1.segment9 sales_segment9
FROM  mtl_system_items_b msib
     ,org_organization_definitions ord
     ,gl_code_combinations gcc
     ,gl_code_combinations gcc1
WHERE msib.organization_id=ord.organization_id
AND   ord.inventory_enabled_flag='Y'
AND   NVL(ord.disable_date,sysdate+1) > sysdate
AND   gcc.code_combination_id=msib.cost_of_sales_account
AND   gcc1.code_combination_id=msib.sales_account
AND   msib.segment1=NVL(p_item_number,msib.segment1)
AND   msib.organization_id IN ((SELECT  organization_id_child
                                 FROM  per_organization_structures pos
                                       ,per_org_structure_versions pov
                                       ,per_org_structure_elements ose
                                 WHERE pos.name=p_org_hierachy_name
                                  AND   pos.organization_structure_id = pov.organization_structure_id
                                  AND ose.org_structure_version_id = pov.org_structure_version_id)
                                  UNION ALL
                                ( select ord.organization_id
                                  from org_organization_definitions ord
                                  where p_org_hierachy_name = 'None'
                                  AND ord.inventory_enabled_flag='Y'
                                  AND NVL(ord.disable_date,sysdate+1) > sysdate))
AND  msib.organization_id = NVL(p_inventory_organization,msib.organization_id);


CURSOR c_cat_id( p_cat_set_id NUMBER,p_inv_item_id NUMBER,p_mst_org_id NUMBER) IS
SELECT category_id
FROM mtl_item_categories
WHERE category_set_id=p_cat_set_id
AND   inventory_item_id=p_inv_item_id
AND organization_id=p_mst_org_id;

CURSOR c_cat_segment(p_cat_id NUMBER) IS
SELECT segment1
FROM mtl_categories_b_kfv
WHERE category_id=p_cat_id;



x_error_code VARCHAR2(240):=xx_emf_cn_pkg.CN_SUCCESS;
x_error_mesg VARCHAR2(2000);
x_organization_id NUMBER;
x_organization_code VARCHAR2(30);
x_cat_set_id        NUMBER;
x_mst_org_id        NUMBER;
x_delim             CHAR (1);
x_coa_id            NUMBER;
x_cat_id            NUMBER:=NULL;
x_cat_segment       VARCHAR2(25):=NULL;
x_cogs_new_ccid  NUMBER;
x_cogs_segment1  VARCHAR2(25);
x_cogs_segment2  VARCHAR2(25);
x_cogs_segment3  VARCHAR2(25);
x_cogs_segment4  VARCHAR2(25);
x_cogs_segment5  VARCHAR2(25);
x_cogs_segment6  VARCHAR2(25);
x_cogs_segment7  VARCHAR2(25);
x_cogs_segment8  VARCHAR2(25);
x_cogs_segment9  VARCHAR2(25);
x_sales_new_ccid  NUMBER;
x_sales_segment1  VARCHAR2(25);
x_sales_segment2  VARCHAR2(25);
x_sales_segment3  VARCHAR2(25);
x_sales_segment4  VARCHAR2(25);
x_sales_segment5  VARCHAR2(25);
x_sales_segment6  VARCHAR2(25);
x_sales_segment7  VARCHAR2(25);
x_sales_segment8  VARCHAR2(25);
x_sales_segment9  VARCHAR2(25);

BEGIN

dbg_low('Inside insert_staging_table' );

-----Derive Category Set ID----

BEGIN

  SELECT category_set_id
    INTO x_cat_set_id
   FROM   mtl_category_sets
  WHERE category_set_name=g_cat_set_name;

dbg_low('x_cat_set_id' ||x_cat_set_id);

 EXCEPTION
     WHEN OTHERS THEN
           dbg_med('Unexpected error while deriving Category Set ID');

END;
--------Derive Master Org id----


BEGIN

  SELECT organization_id
    INTO x_mst_org_id
   FROM   mtl_parameters
  WHERE organization_code='MST';--g_master_org;

 EXCEPTION
     WHEN OTHERS THEN
           dbg_med('Unexpected error while deriving Category Set ID');

END;
--------Deriving Chart of Accounts
 BEGIN
    SELECT chart_of_accounts_id
     INTO x_coa_id
     FROM gl_sets_of_books
     WHERE set_of_books_id = fnd_profile.value('GL_SET_OF_BKS_ID');
 EXCEPTION
    WHEN OTHERS THEN
         dbg_med('Unexpected error while deriving the chart_of_accounts_id');

 END;

 IF x_coa_id IS NOT NULL
 THEN
    x_delim := fnd_flex_ext.get_delimiter ('SQLGL', 'GL#', x_coa_id);
 END IF;
--------

 FOR r_item_detail IN c_item_detail LOOP




x_cat_id:=NULL;
x_cat_segment:=NULL;
x_error_code:=xx_emf_cn_pkg.CN_SUCCESS;
x_error_mesg:=NULL;
------

 OPEN c_cat_id(x_cat_set_id,r_item_detail.inventory_item_id,x_mst_org_id);
 FETCH c_cat_id INTO x_cat_id;



 IF c_cat_id%NOTFOUND THEN

    x_cat_id:=NULL;
    x_error_code:=xx_emf_cn_pkg.CN_REC_ERR;
    x_error_mesg:='Category Set'||' '||g_cat_set_name||' '||'is not associated with item';

 ELSE

   OPEN c_cat_segment(x_cat_id);
   FETCH c_cat_segment INTO x_cat_segment;
   IF c_cat_segment%NOTFOUND THEN
     x_cat_segment:=NULL;
     x_error_code:=xx_emf_cn_pkg.CN_REC_ERR;
     x_error_mesg:='category segment1 does not exist';

 END IF;
CLOSE c_cat_segment;
 END IF;

CLOSE c_cat_id;

----Derivation of cogs_new_ccid

IF x_cat_segment IS NOT NULL THEN

 x_cogs_new_ccid:=
                 fnd_flex_ext.get_ccid ('SQLGL',
                                         'GL#',
                                        x_coa_id,
                                        TO_CHAR (SYSDATE, 'DD-MON-YYYY'),
                                        r_item_detail.cogs_segment1
                                        || x_delim
                                        || r_item_detail.cogs_segment2
                                        || x_delim
                                        || r_item_detail.cogs_segment3
                                        || x_delim
                                        || r_item_detail.cogs_segment4
                                        || x_delim
                                        --|| r_item_detail.cogs_segment5  # Modified by Sujan, 06/12/2012
                                        --|| x_delim                      # Modified by Sujan, 06/12/2012
                                        || x_cat_segment
                                        || x_delim
                                        || r_item_detail.cogs_segment6 -- # Modified by Sujan, 06/12/2012
                                        || x_delim                     -- # Modified by Sujan, 06/12/2012
                                        || r_item_detail.cogs_segment7
                                        || x_delim
                                        || r_item_detail.cogs_segment8
                                        --|| x_delim                      # Modified by Sujan, 06/12/2012
                                        --|| r_item_detail.cogs_segment9  # Modified by Sujan, 06/12/2012
                                       );
  IF x_cogs_new_ccid <= 0
  THEN
    x_error_code:=xx_emf_cn_pkg.CN_REC_ERR;
    x_error_mesg:='Unexpected error while deriving the cogs_new_ccid'||r_item_detail.item_number;

  END IF;

ELSE
  x_cogs_new_ccid := NULL;

END IF;
----------

IF x_cat_segment IS NOT NULL THEN

x_sales_new_ccid :=
                 fnd_flex_ext.get_ccid ('SQLGL',
                                         'GL#',
                                        x_coa_id,
                                        TO_CHAR (SYSDATE, 'DD-MON-YYYY'),
                                        r_item_detail.sales_segment1
                                        || x_delim
                                        || r_item_detail.sales_segment2
                                        || x_delim
                                        || r_item_detail.sales_segment3
                                        || x_delim
                                        || r_item_detail.sales_segment4
                                        || x_delim
                                        -- || r_item_detail.sales_segment5  -- # Modified by Sujan, 06/12/2012
                                        -- || x_delim                       -- # Modified by Sujan, 06/12/2012
                                        || x_cat_segment
                                        || x_delim
                                        || r_item_detail.sales_segment6     -- # Modified by Sujan, 06/12/2012
                                        || x_delim                          -- # Modified by Sujan, 06/12/2012
                                        || r_item_detail.sales_segment7
                                        || x_delim
                                        || r_item_detail.sales_segment8
                                        --|| x_delim                           # Modified by Sujan, 06/12/2012
                                        --|| r_item_detail.sales_segment9      # Modified by Sujan, 06/12/2012
                                       );
 IF x_sales_new_ccid <= 0
 THEN
  x_error_code:=xx_emf_cn_pkg.CN_REC_ERR;
  x_error_mesg:='Unexpected error while deriving the sales_new_ccid'||r_item_detail.item_number;

 END IF;

ELSE
  x_sales_new_ccid:=NULL;

END IF;
---------
IF (x_cat_segment = r_item_detail.cogs_segment5 ) AND -- Modified by Sujan, 06/12/2012
    (x_cat_segment = r_item_detail.sales_segment5)  THEN
  x_error_code:=xx_emf_cn_pkg.CN_REC_ERR;
  x_error_mesg:='No update required for the Cost of Sales Account or Sales Account';
END IF;


IF x_error_code NOT IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN) THEN
    x_error_code:=xx_emf_cn_pkg.CN_REC_ERR;
ELSE
   x_error_code:=xx_emf_cn_pkg.CN_SUCCESS;
END IF;
 -------Inserting data into staging table----
      BEGIN
          INSERT INTO XX_INV_ACCOUNT_GEN_STG
               (RECORD_NUMBER,
                ORG_HIERACHY_NAME,
                ORGANIZATION_CODE,
                ORGANIZATION_ID,
                ITEM_NUMBER,
                INV_ITEM_ID,
                CATEGORY_NAME,
                CATEGORY_SET_ID,
                CATEGORY_ID,
                CAT_SEGMENT1,
                COST_OF_SALES_ACCOUNT,
                COGS_SEGMENT1,
                COGS_SEGMENT2,
                COGS_SEGMENT3,
                COGS_SEGMENT4,
                COGS_SEGMENT5,
                COGS_SEGMENT6,
                COGS_SEGMENT7,
                COGS_SEGMENT8,
                COGS_SEGMENT9,
                SALES_ACCOUNT,
                SALES_SEGMENT1,
                SALES_SEGMENT2,
                SALES_SEGMENT3,
                SALES_SEGMENT4,
                SALES_SEGMENT5,
                SALES_SEGMENT6,
                SALES_SEGMENT7,
                SALES_SEGMENT8,
                SALES_SEGMENT9,
                COGS_NEW_CCID,
                SALES_NEW_CCID,
                ERROR_CODE,
                ERROR_MESG,
                REQUEST_ID)
           VALUES(XX_INV_AC_GEN_STG_S.NEXTVAL,
                  p_org_hierachy_name,
                  r_item_detail.organization_code,
                  r_item_detail.organization_id,
                  r_item_detail.item_number,
                  r_item_detail.inventory_item_id,
                  g_cat_set_name,
                  x_cat_set_id,
                  x_cat_id,
                  x_cat_segment,
                  r_item_detail.cost_of_sales_account,
                  r_item_detail.cogs_segment1,
                  r_item_detail.cogs_segment2,
                  r_item_detail.cogs_segment3,
                  r_item_detail.cogs_segment4,
                  -- r_item_detail.cogs_segment5,                 -- Modified by Sujan, 06/12/2012
                  NVL(x_cat_segment,r_item_detail.cogs_segment5), -- Modified by Sujan, 06/12/2012
                  r_item_detail.cogs_segment6,                    -- Modified by Sujan, 06/12/2012
                  r_item_detail.cogs_segment7,
                  r_item_detail.cogs_segment8,
                  r_item_detail.cogs_segment9,
                  r_item_detail.sales_account,
                  r_item_detail.sales_segment1,
                  r_item_detail.sales_segment2,
                  r_item_detail.sales_segment3,
                  r_item_detail.sales_segment4,
                  -- r_item_detail.sales_segment5,                 -- Modified by Sujan, 06/12/2012
                  NVL(x_cat_segment,r_item_detail.sales_segment5), -- Modified by Sujan, 06/12/2012
                  r_item_detail.sales_segment6,                    -- Modified by Sujan, 06/12/2012
                  r_item_detail.sales_segment7,
                  r_item_detail.sales_segment8,
                  r_item_detail.sales_segment9,
                  x_cogs_new_ccid,
                  x_sales_new_ccid,
                  x_error_code,
                  x_error_mesg,
                  xx_emf_pkg.G_REQUEST_ID);
       EXCEPTION
        WHEN OTHERS THEN
           dbg_med('Unexpected error while iserting records in XX_INV_ACCOUNT_GEN_STG table');
      END;

 END LOOP;

 COMMIT;

EXCEPTION
   WHEN OTHERS THEN
    dbg_low('Error while inserting into XX_INV_ACCOUNT_GEN_STG Tables: ' ||SQLERRM);

END insert_staging_table;


---------------------------------------

BEGIN
      --Main Begin
      ----------------------------------------------------------------------------------------------------
      --Initialize Trace
      --Purpose : Set the program environment for Tracing
      ----------------------------------------------------------------------------------------------------

   fnd_file.put_line (fnd_file.LOG, '***DS - 1');
    o_retcode := xx_emf_cn_pkg.CN_SUCCESS;

          dbg_low('Before Setting Environment');

          -- Set Env --
	    dbg_low('Calling Account Genarator Set_cnv_env');

            set_cnv_env (xx_emf_cn_pkg.CN_YES);

      fnd_file.put_line (fnd_file.LOG, '***DS - 2');

     G_REQUEST_ID:=xx_emf_pkg.G_REQUEST_ID;

dbg_low('Starting main process with the following parameters G_REQUEST_ID'||G_REQUEST_ID);

            -- include all the parameters to the conversion main here

       -- as medium log messages
	     dbg_med('Starting main process with the following parameters');
	     dbg_med('Main:Param - p_org_hierachy_name '	|| p_org_hierachy_name);
             dbg_med('Main:Param - p_inventory_organization '	|| p_inventory_organization);
             dbg_med('Main:Param - p_item_number '	        || p_item_number);


     ----Assign Global variable

        assign_global_var;

      dbg_low('Calling after assign_global_var..');

     -------Insert records from pre staging table to staging table

      insert_staging_table(p_org_hierachy_name,
                           p_inventory_organization,
                           p_item_number);
  ----------------
  x_error_code := process_item_account_gen;
  mark_records_complete;

-----Record Count

OPEN c_get_total_cnt;
    FETCH c_get_total_cnt INTO x_total_cnt;
    CLOSE c_get_total_cnt;

------------------
    OPEN c_get_error_cnt;
    FETCH c_get_error_cnt INTO x_error_cnt;
    CLOSE c_get_error_cnt;

------------------------------


       OPEN c_get_success_cnt;
       FETCH c_get_success_cnt INTO x_success_cnt;
       CLOSE c_get_success_cnt;

-----------------------
  dbg_low('x_total_cnt'||x_total_cnt);
  dbg_low('x_success_cnt'||x_success_cnt);
  dbg_low('x_error_cnt'||x_error_cnt);

IF x_error_cnt > 0 THEN

  o_retcode := xx_emf_cn_pkg.CN_REC_WARN;

ELSE

  o_retcode := xx_emf_cn_pkg.CN_SUCCESS;

END IF;



--------Calling Submit report to display the report

exec_submit_report_pr (p_request_id  => G_REQUEST_ID);


COMMIT;

EXCEPTION
    WHEN xx_emf_pkg.G_E_ENV_NOT_SET THEN
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Checking if this is OK');
	fnd_file.put_line ( fnd_file.output, xx_emf_pkg.CN_ENV_NOT_SET);
	o_retcode := xx_emf_cn_pkg.CN_REC_ERR;

    WHEN xx_emf_pkg.G_E_REC_ERROR THEN

	o_retcode := xx_emf_cn_pkg.CN_REC_ERR;

     WHEN xx_emf_pkg.G_E_PRC_ERROR THEN

	o_retcode := xx_emf_cn_pkg.CN_PRC_ERR;

     WHEN OTHERS THEN

	o_retcode := xx_emf_cn_pkg.CN_PRC_ERR;

END main;

END xx_inv_account_gen_upd_cnv_pkg;
/
