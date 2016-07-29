DROP PACKAGE BODY APPS.XXINTG_UPDATE_EXPIRATION_DATE;

CREATE OR REPLACE PACKAGE BODY APPS.XXINTG_UPDATE_EXPIRATION_DATE
IS
----------------------------------------------------------------------
/*
Created By : Deepti
Creation Date : 08-Apr-2015
File Name : XXUPDEXPDATE.pkb
Description : This script creates the body of the package XXINTG_UPDATE_EXPIRATION_DATE
Change History:
Version Date Name Remarks
------- ----------- -------- -------------------------------
1.0 08-Apr-2015 IBM Development Team Initial development.
*/
----------------------------------------------------------------------
PROCEDURE MAIN (  errbuf     out varchar2,
                  retcode    out number,
                  p_job_num   in varchar2)
IS

l_return_status VARCHAR2(10);
l_msg_count NUMBER;
l_msg_data VARCHAR2(1000);
l_inventory_item_id mtl_system_items_b.inventory_item_id%TYPE ;
l_organization_id mtl_lot_numbers.organization_id%TYPE ;
l_organization_id_lkup mtl_lot_numbers.organization_id%TYPE ;
l_lot_number mtl_lot_numbers.lot_number%TYPE ;
l_expiration_date mtl_lot_numbers.expiration_date%TYPE ;
l_origination_date mtl_lot_numbers.origination_date%TYPE;
x_error_msg                  VARCHAR2 (2000);
p_lot_num		      VARCHAR2 (100);
l_exp_date        date ;
l_orgin_date       date ;
l_exists_count          number;
l_lot_count             number := 0;
i  number;


l_attributes_tbl inv_lot_api_pub.char_tbl;
l_c_attributes_tbl inv_lot_api_pub.char_tbl;
l_n_attributes_tbl inv_lot_api_pub.number_tbl;
l_d_attributes_tbl inv_lot_api_pub.date_tbl;

PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

dbms_lock.sleep(15) ;




        x_error_msg := NULL;


        BEGIN
            SELECT lot_number ,organization_id
              INTO p_lot_num ,l_organization_id
              FROM wip_discrete_jobs_v
             WHERE wip_entity_name = p_job_num;
         EXCEPTION

            WHEN OTHERS
            THEN
               x_error_msg :=
                     x_error_msg
                  || 'Error: p_lot_num could not be fetched from Job Number'
                  || SQLERRM;


         END;




                BEGIN
                   SELECT primary_item_id
                     INTO l_inventory_item_id
                     FROM wip_discrete_jobs_v
                    WHERE wip_entity_name = p_job_num
                      AND organization_id = l_organization_id;
                EXCEPTION

                   WHEN OTHERS
                   THEN
                      x_error_msg :=
                            x_error_msg
                         || 'Error: Inventory_item_id could not be fetched from Job Number'
                         || SQLERRM;
                END;



	BEGIN
	    SELECT lot_number
	      INTO l_lot_number
	      FROM wip_discrete_jobs_v
	     WHERE lot_number = p_lot_num;
	EXCEPTION

	   WHEN OTHERS
	   THEN
	      x_error_msg :=
	            x_error_msg
	         || 'Error: lot_number could not be fetched from Job Number'
	         || SQLERRM;
	 END;



         BEGIN
            SELECT count(*)
              INTO l_exists_count
              FROM MTL_LOT_NUMBERS
             WHERE lot_number = p_lot_num
               and inventory_item_id = l_inventory_item_id
               and organization_id = l_organization_id;

         EXCEPTION

            WHEN OTHERS
            THEN
               x_error_msg :=
                     x_error_msg
                  || 'Error: l_exists_count could not be fetched from Job Number'
                  || SQLERRM;
         END;



	 BEGIN
	    SELECT d_attribute1,d_attribute2
	      INTO l_exp_date ,l_orgin_date
	      FROM mtl_lot_numbers
	     WHERE lot_number = p_lot_num
         AND organization_id = l_organization_id
         AND inventory_item_id = l_inventory_item_id
         AND lot_attribute_category in ('Irvine Attributes','Irvine Date Attributes');

	 EXCEPTION

	    WHEN OTHERS
	    THEN
	       x_error_msg :=
	             x_error_msg
	          || 'Error: Experation Date could not be fetched from Job Number'
	          || SQLERRM;

	  END;



 	      BEGIN
 	        SELECT count(1)
 	          INTO l_lot_count
 	          FROM mtl_lot_numbers
 	         WHERE lot_number = p_lot_num ;



 	      EXCEPTION

		    WHEN OTHERS
		    THEN
		       x_error_msg :=
		             x_error_msg
		          || 'Error: Lot Number Could not be fetched from Job Number'
		          || SQLERRM;

 	      END ;


         l_expiration_date := to_date(l_exp_date,'YYYY/MM/DD HH24:MI:SS')   ;
         l_origination_date := to_date(l_orgin_date,'YYYY/MM/DD HH24:MI:SS')   ;



	 IF l_lot_count > 0 THEN




	 inv_lot_api_pub.update_inv_lot (x_return_status => l_return_status,
	 x_msg_count => l_msg_count,
	 x_msg_data => l_msg_data,
	 p_inventory_item_id => l_inventory_item_id,
	 p_organization_id => l_organization_id,
	 p_lot_number => l_lot_number,
	 p_expiration_date => l_exp_date,
         p_origination_date => l_orgin_date ,
	 p_attributes_tbl => l_attributes_tbl,
	 p_c_attributes_tbl => l_c_attributes_tbl,
	 p_n_attributes_tbl => l_n_attributes_tbl,
	 p_d_attributes_tbl => l_d_attributes_tbl,
	 p_source => 401--l_application_id for application 'INV',
	 );




         dbms_output.put_line ('API is being called');

         dbms_output.put_line ('The Status Returned by the API is =>' ||l_return_status);
         dbms_output.put_line ('The Status Returned by the API is =>' ||l_msg_data);





        IF l_return_status = fnd_api.g_ret_sts_success THEN
           COMMIT;
           x_error_msg := 'Lot Number Updated Successfully' ;
        ELSE
           ROLLBACK;
           x_error_msg := x_error_msg ||'API Error'||l_msg_data ;
        END IF;

        dbms_output.put_line ('API Executed :' ||x_error_msg)  ;


    END IF;

    COMMIT;
 END;
END XXINTG_UPDATE_EXPIRATION_DATE;
/
