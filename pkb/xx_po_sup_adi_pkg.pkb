DROP PACKAGE BODY APPS.XX_PO_SUP_ADI_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_PO_SUP_ADI_PKG" 
	IS
	   ----------------------------------------------------------------------
	   /*
	    Created By    : Yogesh
	    Creation Date : 06-Jun-2013
	    File Name     : xxposupadi.pkb
	    Description   : This script creates the package body of the object
			    xx_po_sup_adi_pkg
	    Change History:
	    Date        Name                  Remarks
	    ----------- -------------         -----------------------------------
	    26-Jun-2013 Yogesh                Initial Version
	   */
	    ----------------------------------------------------------------------


	    FUNCTION update_po_doc (p_action         IN        VARCHAR2
				   ,p_po_number      IN        VARCHAR2
				   ,p_po_line_num    IN        VARCHAR2
				   ,p_rel_num        IN        VARCHAR2
				   ,p_ship_line_num  IN        VARCHAR2
				   ,p_item           IN        VARCHAR2
				   ,p_item_desc      IN        VARCHAR2
				   ,p_quantity       IN        VARCHAR2
				   ,p_unit_price     IN        NUMBER
				   ,p_need_by_date   IN        VARCHAR2
				   ,p_promise_date   IN        VARCHAR2
				   ,p_sup_name       IN        VARCHAR2
				   ,p_last_line_flag IN        VARCHAR2
				   )
	    RETURN VARCHAR2
	    IS
	       x_result                   NUMBER;
	       x_revision_num             NUMBER;
	       x_org_id                   NUMBER;
	       x_user_id                  NUMBER;
	       x_api_errors               po_api_errors_rec_type;
	       x_resp_id                  NUMBER;
	       x_appl_id                  NUMBER;
	       x_err_msg                  VARCHAR2(1000):=NULL;
	       x_orig_price               NUMBER;
	       x_need_by                  DATE;
	       x_promised                 DATE;
	       x_tolarence                NUMBER;
	       x_per_change               NUMBER;
	       x_po_type                  VARCHAR2(50);
	       x_po_close_code            VARCHAR2(30);
	       x_req_id                   NUMBER;
	       x_layout_status            BOOLEAN;
	       x_date_check               DATE;
	       x_changes                  PO_CHANGES_REC_TYPE;
	       l_return_status            VARCHAR2(1);
	       x_po_line_id               NUMBER;
	       x_po_header_id             NUMBER;
	       x_current_price            NUMBER;
	    BEGIN
	       fnd_global.apps_initialize (fnd_global.USER_ID, fnd_global.RESP_ID, fnd_global.RESP_APPL_ID);
	       mo_global.init('PO');
	 ----
	       IF p_action = 'SYNC'
		  THEN
		  BEGIN
		     SELECT revision_num,org_id,type_lookup_code,closed_code
		       INTO x_revision_num,x_org_id,x_po_type,x_po_close_code
		       FROM po_headers_all
		      WHERE segment1 = p_po_number;
		  EXCEPTION WHEN OTHERS THEN
			 x_err_msg := 'Cannot Fetch ORG_ID and PO Revision Num';
			 --raise_application_error (-20001,x_err_msg);
			 return x_err_msg;
		  END;

		  mo_global.set_policy_context('S',x_org_id);
		  BEGIN
		     SELECT price_change_allowance
		       INTO x_tolarence
		       FROM po_system_parameters;
		  EXCEPTION WHEN OTHERS THEN
			 x_tolarence:=NULL;
			 x_err_msg := 'Cannot Fetch Price Change Tolerance';
			 --raise_application_error (-20001,x_err_msg);
			 return x_err_msg;
		  END;


		  IF x_po_type = 'BLANKET' and p_rel_num is null
		  THEN

		    BEGIN
		     SELECT pla.unit_price,pla.po_line_id,pha.po_header_id
		       INTO x_orig_price,x_po_line_id,x_po_header_id
		       FROM po_lines_all pla,
			    po_headers_all pha
		      WHERE pla.line_num = p_po_line_num
			AND pla.po_header_id = pha.po_header_id
			AND pha.segment1 = p_po_number;
		    EXCEPTION WHEN OTHERS THEN
			   x_err_msg := 'Cannot Fetch Original BPA Line Price';
			   --raise_application_error (-20001,x_err_msg);
			   return x_err_msg;
		    END;

		     IF x_orig_price != to_number(p_unit_price)
		     THEN
			x_per_change:= ((p_unit_price - x_orig_price)/x_orig_price)*100;
			IF x_per_change > to_number(x_tolarence)
			THEN
			   x_err_msg :='Cannot Update the BPA LinePrice - New Price Above Tolerance';
			   return x_err_msg;
			END IF;
			  ----- Create an empty change object for this document.
			x_changes := PO_CHANGES_REC_TYPE.create_object (
									p_po_header_id =>x_po_header_id,--l_po_header_id,
									p_po_release_id => NULL--l_po_release_id
								       );
			x_changes.line_changes.add_change (
							   p_po_line_id => x_po_line_id,--l_po_line_id,
							   p_unit_price => p_unit_price --p_new_price
							  );

			po_document_update_pvt.update_document(
								p_api_version           => 1,
								p_init_msg_list         => FND_API.G_TRUE,
								x_return_status         => l_return_status,
								p_changes               => x_changes,
								p_run_submission_checks => FND_API.G_FALSE,
								p_launch_approvals_flag => FND_API.G_FALSE,--l_launch_approvals_flag,
								p_buyer_id              => NULL,--l_buyer_id,
								p_update_source         => NULL,--p_update_source,
								p_override_date         => NULL,
								x_api_errors            => x_api_errors
							      );

			IF (l_return_status = FND_API.G_RET_STS_SUCCESS)
			THEN
			     --dbms_output.put_line('Success');
			     x_err_msg:=NULL;
			     return x_err_msg;
			ELSE
			  --dbms_output.put_line('FAILED');
			  --dbms_output.put_line('Failed to update the PO Line Price->'||x_api_errors.MESSAGE_TEXT (1));
			  x_err_msg:=('Failed to Update the BPA Line Price->'||x_api_errors.MESSAGE_TEXT (1));
			  return x_err_msg;
			END IF;
		     END IF;
		     x_err_msg:= 'No Price Change to Update for BPA Line';
		     return x_err_msg;
		  END IF;

		  -- For Blanket Releases

		  IF x_po_type != 'STANDARD' and  p_rel_num is not null
		  THEN
		     BEGIN
			select pr.revision_num,pr.org_id,pr.release_type,pr.closed_code
			  INTO x_revision_num,x_org_id,x_po_type,x_po_close_code
			  FROM po_headers_all pha,
			       po_releases_all pr,
			       po_line_locations_all plla
			 WHERE pha.segment1 = p_po_number
			   AND plla.po_header_id = pha.po_header_id
			   AND pr.po_release_id = plla.po_release_id
			   AND PR.RELEASE_NUM= p_rel_num
			   AND plla.shipment_num = p_ship_line_num
			   AND rownum =1;
		     EXCEPTION WHEN OTHERS THEN
			    x_err_msg := 'Cannot Fetch ORG_ID and PO Revision Num';
			    --raise_application_error (-20001,x_err_msg);
			    return x_err_msg;
		     END;
		  END IF;

		  -- For Standard Purchase Orders

		  IF x_po_type = 'STANDARD'
		  THEN
		     BEGIN
			SELECT distinct porl.unit_price
			  INTO x_orig_price
			  FROM po_headers_all poh, po_lines_all pol,
			       po_line_locations_all poll,
			       po_requisition_headers_all porh,
			       po_requisition_lines_all porl
			 WHERE porh.requisition_header_id = porl.requisition_header_id
			   AND porl.line_location_id = poll.line_location_id
			   AND poh.po_header_id = pol.po_header_id
			   AND pol.po_line_id = poll.po_line_id
			   AND poh.segment1 = p_po_number
			   AND pol.line_num = p_po_line_num
			   AND poll.shipment_num = p_ship_line_num ;

			SELECT pla.unit_price
			  INTO x_current_price
			  FROM po_lines_all pla,
			       po_headers_all pha
			 WHERE pla.line_num = p_po_line_num
			   AND pla.po_header_id = pha.po_header_id
			   AND pha.segment1 = p_po_number;
		     EXCEPTION WHEN OTHERS THEN
			    x_err_msg := 'Cannot Fetch Original PO Line Price/ Cannot Find Purchase Requition for this PO';
			    --raise_application_error (-20001,x_err_msg);
			    return x_err_msg;
		     END;
		  END IF;

		  IF x_po_type != 'STANDARD' and  p_rel_num is not null
		  THEN
		    BEGIN
                       SELECT pla.unit_price
			 INTO x_orig_price
			 FROM po_headers_all pha,
			      po_releases_all pr,
			      po_lines_all pla,
			      po_line_locations_all plla
			WHERE pha.segment1 = p_po_number
	                  AND pla.po_header_id = pha.po_header_id
                          AND pla.line_num = p_po_line_num
                          AND pla.po_line_id = plla.po_line_id
			  AND pr.po_release_id = plla.po_release_id
			  AND pr.release_num= p_rel_num
                          AND plla.shipment_num = p_ship_line_num;

			SELECT pla.unit_price
			  INTO x_current_price
			  FROM po_lines_all pla,
			       po_headers_all pha
			 WHERE pla.line_num = p_po_line_num
			   AND pla.po_header_id = pha.po_header_id
			   AND pha.segment1 = p_po_number;
		    EXCEPTION WHEN OTHERS THEN
			   x_err_msg := 'Cannot Fetch Original PO Line Price/ Cannot Find Release for this PO';
			   --raise_application_error (-20001,x_err_msg);
			   return x_err_msg;
		    END;
		  END IF;
		  IF (x_current_price != to_number(p_unit_price))
		  THEN
		    IF p_unit_price > x_orig_price and x_po_type = 'STANDARD'
		    THEN

		       x_per_change:= ((p_unit_price - x_orig_price)/x_orig_price)*100;
		       IF x_per_change > to_number(x_tolarence)
		       THEN
			  x_err_msg :='Cannot Update the PO LinePrice - New Price Above Tolerance';
			  return x_err_msg;
		       END IF;
		    END IF;

		    IF x_po_type != 'STANDARD' and  p_rel_num is not null
		    THEN
		       x_result :=po_change_api1_s.update_po(x_po_number            =>      p_po_number 	--Enter the PO Number
							    ,x_release_number       =>      p_rel_num      --Enter the Release Num
							    ,x_revision_number      =>      x_revision_num 	--Enter the Revision Number
							    ,x_line_number          =>      p_po_line_num   	--Enter the Line Number
							    ,x_shipment_number      =>      NULL  		--i.shipment_num, --Enter the Shipment Number
							    ,new_quantity           =>      NULL 		--l_quantity, --Enter the new quantity
							    ,new_price              =>      p_unit_price	--Enter the new price,
							    ,new_promised_date      =>      NULL		--l_promised_date, --Enter the new promised date,
							    ,new_need_by_date       =>      NULL		--l_need_by_date, --Enter the new need by date,
							    ,launch_approvals_flag  =>      'Y'
							    ,update_source          =>      NULL
							    ,version                =>      '1'
							    ,x_override_date        =>      NULL
							    ,x_api_errors           =>      X_api_errors
							    ,p_buyer_name           =>      NULL
							    ,p_secondary_quantity   =>      NULL
							    ,p_preferred_grade      =>      NULL
							    ,p_org_id               =>      x_org_id
							    );
		    ELSE
		       x_result :=po_change_api1_s.update_po(x_po_number            =>      p_po_number 	--Enter the PO Number
							    ,x_release_number       =>      NULL                --Enter the Release Num
							    ,x_revision_number      =>      x_revision_num 	--Enter the Revision Number
							    ,x_line_number          =>      p_po_line_num 	--Enter the Line Number
							    ,x_shipment_number      =>      NULL  		--i.shipment_num, --Enter the Shipment Number
							    ,new_quantity           =>      NULL 		--l_quantity, --Enter the new quantity
							    ,new_price              =>      p_unit_price	--Enter the new price,
							    ,new_promised_date      =>      NULL		--l_promised_date, --Enter the new promised date,
							    ,new_need_by_date       =>      NULL		--l_need_by_date, --Enter the new need by date,
							    ,launch_approvals_flag  =>      'Y'
							    ,update_source          =>      NULL
							    ,version                =>      '1'
							    ,x_override_date        =>      NULL
							    ,x_api_errors           =>      X_api_errors
							    ,p_buyer_name           =>      NULL
							    ,p_secondary_quantity   =>      NULL
							    ,p_preferred_grade      =>      NULL
							    ,p_org_id               =>      x_org_id
							   );
		    END IF;

		    IF (x_result = 1)
		    THEN
		      x_err_msg:= x_err_msg||'Successfully Updated the PO Line Price';
		    END IF;

		    IF (x_result <> 1)
		    THEN
		       -- Display the errors
		       x_err_msg:= x_err_msg||'Failed to update the PO Line Price->'||x_api_errors.MESSAGE_TEXT (1);
		       --raise_application_error (-20001,x_err_msg);
		       return x_err_msg;
		    END IF;
		  END IF;

		  BEGIN
		     SELECT revision_num,org_id
		       INTO x_revision_num,x_org_id
		       FROM po_headers_all
		      WHERE segment1 = p_po_number;
		  EXCEPTION WHEN OTHERS THEN
			 x_err_msg := 'Cannot Fetch ORG_ID and PO Revision Num';
		     --    raise_application_error (-20001,x_err_msg);
			 return x_err_msg;
		  END;

		  IF x_po_type != 'STANDARD' and  p_rel_num is not null
		  THEN
		     BEGIN
			select pr.revision_num,pr.org_id
			  INTO x_revision_num,x_org_id
			  FROM po_line_locations_all plla,
			       po_headers_all pha,
			       po_lines_all pla,
			       PO_RELEASES_ALL PR
			 WHERE pha.segment1 = p_po_number
			   AND pla.po_header_id = pha.po_header_id
			   AND plla.po_header_id = pha.po_header_id
			   AND plla.po_line_id = pla.po_line_id
			   AND plla.shipment_num = p_ship_line_num
			   AND pla.line_num = p_po_line_num
			   AND pr.po_release_id = plla.po_release_id
			   AND PR.RELEASE_NUM= p_rel_num;
		     EXCEPTION WHEN OTHERS THEN
			    x_err_msg := 'Cannot Fetch ORG_ID and PO Revision Num';
			    --raise_application_error (-20001,x_err_msg);
			    return x_err_msg;
		     END;
		  END IF;

		  IF x_po_type = 'STANDARD'
		  THEN
		     BEGIN
			SELECT trunc(nvl(plla.need_by_date,sysdate)),trunc(nvl(plla.promised_date,sysdate))
			  INTO x_need_by,x_promised
			  FROM po_line_locations_all plla,
			       po_headers_all pha,
			       po_lines_all pla
			 WHERE pha.segment1 = p_po_number
			   AND pla.po_header_id = pha.po_header_id
			   AND plla.po_header_id = pha.po_header_id
			   AND plla.po_line_id = pla.po_line_id
			   AND plla.shipment_num = p_ship_line_num
			   AND pla.line_num = p_po_line_num;
		     EXCEPTION WHEN OTHERS THEN
			    x_err_msg := 'Error in Fetching Need By Date and Promised Date';
			--    raise_application_error (-20001,x_err_msg);
			    return x_err_msg;
		     END;
		  /*ELSE
		     BEGIN
			SELECT trunc(nvl(plla.need_by_date,sysdate)),trunc(nvl(plla.promised_date,sysdate))
			  INTO x_need_by,x_promised
			  FROM po_line_locations_all plla,
			       po_headers_all pha,
			       po_lines_all pla,
			       PO_RELEASES_ALL PR
			 WHERE pha.segment1 = p_po_number
			   AND pla.po_header_id = pha.po_header_id
			   AND plla.po_header_id = pha.po_header_id
			   AND plla.po_line_id = pla.po_line_id
			   AND plla.shipment_num = p_ship_line_num
			   AND pla.line_num = p_po_line_num
			   AND pr.po_release_id = plla.po_release_id
			   AND PR.RELEASE_NUM= p_rel_num;
		     EXCEPTION WHEN OTHERS THEN
			    x_err_msg := 'Release Number is NULL OR Cannot Update dates for Blanket Purchase Agreement';
			--    raise_application_error (-20001,x_err_msg);
			    return x_err_msg;
		     END;  */
		  END IF;

		     BEGIN
			x_date_check:= trunc(to_date(nvl(p_promise_date,sysdate),'YYYY-MM-DD HH24:MI:SS'));
		     EXCEPTION WHEN OTHERs THEN
			    x_err_msg := 'Invalid Value Entered For Promise Date';
			--    raise_application_error (-20001,x_err_msg);
			    return x_err_msg;
		     END;

		     BEGIN
			x_date_check:=trunc(to_date(nvl(p_need_by_date,sysdate),'YYYY-MM-DD HH24:MI:SS'));
		     EXCEPTION WHEN OTHERs THEN
			    x_err_msg := 'Invalid Value Entered For Need By Date';
			--    raise_application_error (-20001,x_err_msg);
			    return x_err_msg;
		     END;

		  IF p_need_by_date is not null and x_need_by != trunc(to_date(p_need_by_date,'YYYY-MM-DD HH24:MI:SS'))
		  AND trunc(SYSDATE) > trunc(to_date(p_need_by_date,'YYYY-MM-DD HH24:MI:SS'))
		  THEN
		     x_err_msg := 'ERROR - Need By Date entered is in the past. During Upload';
		     return x_err_msg;
		  END IF;

		  IF p_promise_date is not null and x_promised != trunc(to_date(p_promise_date,'YYYY-MM-DD HH24:MI:SS'))
		  AND trunc(SYSDATE) > trunc(to_date(p_promise_date,'YYYY-MM-DD HH24:MI:SS'))
		  THEN
		     x_err_msg := 'ERROR - Promised Date entered is in the past. During Upload';
		     return x_err_msg;
		  END IF;

		  IF x_po_close_code = 'CLOSED'
		  THEN
		     x_err_msg := 'ERROR - Cannot Update Dates For The Closed PO';
		     return x_err_msg;
		  END IF;

		  IF x_po_type != 'STANDARD' and p_rel_num is not null
		  THEN
		     x_result :=po_change_api1_s.update_po(x_po_number            =>      p_po_number 			--Enter the PO Number
							  ,x_release_number       =>      p_rel_num      		--Enter the Release Num
							  ,x_revision_number      =>      x_revision_num                --Enter the Revision Number
							  ,x_line_number          =>      p_po_line_num          	--Releases do not have lines., Enter the Line Number
							  ,x_shipment_number      =>      p_ship_line_num 		--Releases do not have shipment lines, --Enter the Shipment Number
							  ,new_quantity           =>      NULL 				--l_quantity, --Enter the new quantity
							  ,new_price              =>      NULL 				--Enter the new price,
							  ,new_promised_date      =>      to_date(to_char(to_date(p_promise_date,'YYYY-MM-DD HH24:MI:SS'),'MM/DD/YY'),'MM/DD/YY')---> Accepting the date format, same as the displayed format.
							  ,new_need_by_date       =>      to_date(to_char(to_date(p_need_by_date,'YYYY-MM-DD HH24:MI:SS'),'MM/DD/YY'),'MM/DD/YY')---> Accepting the date format, same as the displayed format.
							  ,launch_approvals_flag  =>      'Y'
							  ,update_source          =>      NULL
							  ,version                =>      '1'
							  ,x_override_date        =>      NULL
							  ,x_api_errors           =>      x_api_errors
							  ,p_buyer_name           =>      NULL
							  ,p_secondary_quantity   =>      NULL
							  ,p_preferred_grade      =>      NULL
							  ,p_org_id               =>      x_org_id
							  );
		  ELSE
		     x_result :=po_change_api1_s.update_po(x_po_number            =>      p_po_number 			--Enter the PO Number
							  ,x_release_number       =>      NULL      		        --Enter the Release Num
							  ,x_revision_number      =>      x_revision_num 		--Enter the Revision Number
							  ,x_line_number          =>      p_po_line_num 		--Enter the Line Number
							  ,x_shipment_number      =>      p_ship_line_num     		--i.shipment_num, --Enter the Shipment Number
							  ,new_quantity           =>      NULL 				--l_quantity, --Enter the new quantity
							  ,new_price              =>      NULL 				--Enter the new price,
							  ,new_promised_date      =>      to_date(to_char(to_date(p_promise_date,'YYYY-MM-DD HH24:MI:SS'),'MM/DD/YY'),'MM/DD/YY')---> Accepting the date format, same as the displayed format.
							  ,new_need_by_date       =>      to_date(to_char(to_date(p_need_by_date,'YYYY-MM-DD HH24:MI:SS'),'MM/DD/YY'),'MM/DD/YY')---> Accepting the date format, same as the displayed format.
							  ,launch_approvals_flag  =>      'Y'
							  ,update_source          =>      NULL
							  ,version                =>      '1'
							  ,x_override_date        =>      NULL
							  ,x_api_errors           =>      x_api_errors
							  ,p_buyer_name           =>      NULL
							  ,p_secondary_quantity   =>      NULL
							  ,p_preferred_grade      =>      NULL
							  ,p_org_id               =>      x_org_id
							  );

		  END IF;

		  IF (x_result = 1)
		  THEN
		     x_err_msg:= x_err_msg||'Successfully updated the PO Shipment Line Dates:=>';
		  END IF;

		  IF (x_result <> 1)
		  THEN
		     -- Display the errors
		     x_err_msg:= x_err_msg||'Failed to update the PO PO Shipment Line Dates Due->'||x_api_errors.MESSAGE_TEXT (1)||'-'||x_api_errors.MESSAGE_TEXT (2);
		     --raise_application_error (-20001,x_err_msg);
		     return x_err_msg;
		  END IF;
		  Commit;
		  IF upper(p_last_line_flag) = 'Y'
		  THEN
		    x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name => 'XXINTG'
								     ,template_code      => 'XXPO_CHANGE_PO_REP'
								     ,template_language  => 'en'
								     ,template_territory => 'US'
								     ,output_format      => 'PDF'
								    );

		    x_req_id:= fnd_request.submit_request
						       (application      => 'XXINTG',
							program          => 'XXPO_CHANGE_PO_REP',
							description      => 'INTG Purchase Order Change Report',
							argument1        => fnd_profile.VALUE ('org_id'),
							argument2        => NULL,
							argument3        => p_po_number,
							argument4        => p_po_number,
							argument5        => NULL,
							argument6        => NULL,
							argument7        => NULL,
							argument8        => NULL,
							argument9        => NULL,
							argument10       => NULL,
							argument11       => NULL,
							argument12       => NULL
						       );
		  END IF;
		  x_err_msg:=NULL;
	       return x_err_msg;
	       ELSE
		 x_err_msg:='Invalid Action Type';
	       return x_err_msg;
	       END IF;
	    EXCEPTION WHEN OTHERs
	    THEN
	    x_err_msg:='Failed to update the PO'||SQLERRM;
	    return x_err_msg;
	    END update_po_doc;

	    ----------------------------------------------------------------------
	    FUNCTION add_line_bpa_doc (p_action          IN        VARCHAR2
				      ,p_po_num          IN        VARCHAR2
				      ,P_line_num        IN        VARCHAR2
				      ,p_line_type       IN        VARCHAR2
				      ,p_item            IN        VARCHAR2
				      ,p_item_desc       IN        VARCHAR2
				      ,P_unit_price      IN        NUMBER
				      ,p_supplier        IN        VARCHAR2
				      ,p_last_line_flag  IN        VARCHAR2
				      )
	    RETURN VARCHAR2
	    IS
	       CURSOR c_po_num_details (p_po_num VARCHAR2)
	       IS
	       SELECT pha.segment1 po_num,
		      pha.org_id,
		      pha.vendor_id,
		      pha.vendor_site_id,
		      pha.type_lookup_code,
		      pha.reference_num,
		      assa.vendor_site_code,
		      pha.po_header_id
		 FROM po_headers_all pha,
		      ap_supplier_sites_all assa
		WHERE pha.vendor_site_id = assa.vendor_site_id
		  AND pha.segment1 = p_po_num;

	       x_po_dtl_rec               C_PO_NUM_DETAILS%ROWTYPE;
	       x_err_msg                  VARCHAR2(1000):=NULL;
	       x_asl_flag                 VARCHAR2(1);
	       x_intf_header_id           NUMBER;
	       x_item_desc                VARCHAR2(240);
	       x_item_uom                 VARCHAR2(25);
	       x_line_type_id             NUMBER;
	    BEGIN
	       IF p_action = 'ADD'
	       THEN
		  OPEN c_po_num_details(p_po_num);

		  FETCH c_po_num_details
		    INTO x_po_dtl_rec;
		  IF c_po_num_details%NOTFOUND
		  THEN
		    x_err_msg:= 'Cannot Fetch Blanket PO Details:';
		    RETURN x_err_msg;
		  END IF;

		  CLOSE c_po_num_details;

		 --Commented as per the Changes requested by Jerry
		 /*BEGIN
		     SELECT 'Y'
		       INTO x_asl_flag
		       FROM po_approved_supplier_list
		      WHERE vendor_id =  x_po_dtl_rec.vendor_id
			AND vendor_site_id =  x_po_dtl_rec.vendor_site_id
			AND item_id IN (SELECT inventory_item_id
					  FROM mtl_system_items_b
					 WHERE segment1 = p_item
					   AND ROWNUM = 1);
		  EXCEPTION
		  WHEN NO_DATA_FOUND
		  THEN
		     x_err_msg:= 'ERROR- Item Is Not on Approved Vendor List(ASL)';
		     RETURN x_err_msg;
		  WHEN OTHERS
		  THEN
		     x_err_msg:= 'ERROR While verifying the ASL for the ITEM:';
		     RETURN x_err_msg;
		  END; */

		  -- Query to check if the line item already has an APPROVED BPA
		  /*SELECT 'Y'
		    FROM po_headers_all pha,
			 po_lines_all pla
		   WHERE NVL(pha.approved_flag, 'N') = 'Y'
		     AND pha.enabled_flag = 'Y'
		     AND NVL (pha.cancel_flag, 'N') <> 'Y'
		     AND pha.authorization_status IN ('APPROVED', 'PRE-APPROVED')
		     AND pha.po_header_id = pla.po_header_id
		     AND pha.vendor_id =2315
		     AND pha.vendor_site_id = 5181
		     AND pla.item_id =  36865
		   GROUP BY pla.item_id*/

		  BEGIN
		     SELECT description,primary_unit_of_measure
		       INTO x_item_desc,x_item_uom
		       FROM mtl_system_items_b
		      WHERE segment1 = p_item
			AND ROWNUM = 1;
		  EXCEPTION WHEN OTHERS
		  THEN
		     x_err_msg:= 'ERROR While Fetching Item Desc and UOM:';
		     RETURN x_err_msg;
		  END;

		  BEGIN
		     SELECT line_type_id
		       INTO x_line_type_id
		       FROM po_line_types_tl pltt
		      WHERE upper(pltt.LINE_TYPE) = upper(p_line_type)
			AND pltt.LANGUAGE(+) = USERENV ('LANG');
		  EXCEPTION WHEN NO_DATA_FOUND
		  THEN
		     x_err_msg:= 'ERROR- Invalid Line Type';
		     RETURN x_err_msg;
		  WHEN OTHERS
		  THEN
		     x_err_msg:= 'ERROR While fetching Line Type ID:';
		     RETURN x_err_msg;
		  END;

		 -- IF x_asl_flag = 'Y'
		 -- THEN
		    BEGIN
		       SELECT interface_header_id
			 INTO x_intf_header_id
			 FROM po_headers_interface
			WHERE interface_source_code = 'WEB ADI'
			  AND document_type_code = 'BLANKET'
			  AND po_header_id = x_po_dtl_rec.po_header_id
			  AND nvl(process_code,'NEW') not in ('REJECTED','ACCEPTED')
			  AND rownum =1;
		    EXCEPTION WHEN NO_DATA_FOUND
		    THEN
		      INSERT INTO po_headers_interface
						       (interface_header_id
						       ,batch_id
						       ,interface_source_code
						       ,action
						       ,org_id
						       ,document_type_code
						       ,po_header_id
						       ,vendor_id
						       ,vendor_site_code
						       ,vendor_site_id
						       ,reference_num)
					       values
						      (po_headers_interface_s.nextval,
						       xx_po_blanket_batch_id_s.nextval,
						       'WEB ADI',
						       'UPDATE',
						       x_po_dtl_rec.org_id,
						       x_po_dtl_rec.type_lookup_code,
						       x_po_dtl_rec.po_header_id,
						       x_po_dtl_rec.vendor_id,
						       x_po_dtl_rec.vendor_site_code,
						       x_po_dtl_rec.vendor_site_id,
						       x_po_dtl_rec.reference_num);

		      x_intf_header_id:=po_headers_interface_s.CURRVAL;
		    WHEN OTHERS
		    THEN
		       x_err_msg:= 'ERROR While fetching the Interface Header ID:';
		       RETURN x_err_msg;
		    END;
		    INSERT INTO po_lines_interface
						    (
						     interface_header_id
						    ,interface_line_id
						    ,action
						    ,line_num
						    ,document_num
						    ,line_type_id
						    ,item
						    ,item_description
						    ,unit_of_measure
						    ,unit_price
						    )
					      VALUES(
						     x_intf_header_id
						    ,PO_LINES_INTERFACE_S.NEXTVAL
	,                                            'ADD'
						    ,p_line_num
						    ,p_po_num
						    ,x_line_type_id
						    ,p_item
						    , x_item_desc
						    ,'Each'
						    ,P_unit_price
						    );
		 commit;
		 -- END IF;
		 IF nvl(p_last_line_flag,'N') = 'Y'
		 THEN
		    SELECT xx_po_sup_adi_pkg.call_import_program
		      INTO x_err_msg
		      FROM DUAL;
		 END IF;
	       ELSIF p_action is NULL
		THEN
		     x_err_msg:= 'Action Not Specified';
		     RETURN x_err_msg;
	       ELSE
		     x_err_msg:= 'Action Type Specified in the ADI excel is INVALID';
		     RETURN x_err_msg;
	       END IF;
	       commit;

	       x_err_msg:= NULL;
	       RETURN x_err_msg;

	    EXCEPTION WHEN OTHERS
	    THEN
	      x_err_msg:='Failed to ADD Line to the BPA'||SQLERRM;
	      return x_err_msg;
	    END add_line_bpa_doc;
	----------------------------------------------------------------------
	    FUNCTION call_import_program
	    RETURN VARCHAR2
	    IS
	       CURSOR c_intf_bpa_details
	       IS
		 SELECT batch_id,document_num
		   FROM po_headers_interface
		  WHERE interface_source_code = 'WEB ADI'
		    AND document_type_code = 'BLANKET'
		    AND nvl(process_code,'NEW') not in ('REJECTED','ACCEPTED');

	       x_req_id                   NUMBER;
	       x_batch_id                 NUMBER;
	       x_org_id                   NUMBER;
	       x_err_msg                  VARCHAR2(1000):=NULL;
	       PRAGMA AUTONOMOUS_TRANSACTION;
	    BEGIN
	       /*fnd_global.apps_initialize(user_id =>1179,
					  resp_id => 20707,
					  resp_appl_id => 201);  */
	       --fnd_global.apps_initialize (fnd_global.USER_ID, fnd_global.RESP_ID, fnd_global.RESP_APPL_ID);
	       FOR intf_bpa_details_rec in c_intf_bpa_details
	       LOOP
		 BEGIN
		    SELECT org_id
		      INTO x_org_id
		      FROM po_headers_all
		     WHERE segment1 = intf_bpa_details_rec.document_num;
		 EXCEPTION WHEN OTHERS
		 THEN
			x_org_id := fnd_profile.VALUE ('org_id');
		 END;
		      mo_global.set_policy_context ('S', x_org_id);
		      mo_global.init('PO');
		      fnd_request.set_org_id(x_org_id);
		   x_req_id:= fnd_request.submit_request
						       (application      => 'PO',
							program          => 'POXPDOI',
							description      => 'Importing Price Catalogs (Blanket and Quotation) Program',
							--start_time       => SYSDATE,
							--sub_request      => FALSE,
							argument1        => NULL,
							argument2        => 'Blanket',
							argument3        => NULL,
							argument4        => 'Y',
							argument5        => 'N',
							argument6        => 'APPROVED',
							argument7        => NULL,
							argument8        => intf_bpa_details_rec.batch_id,
							argument9        => NULL,--fnd_profile.VALUE ('org_id'),
							argument10       => NULL,
							argument11       => 'Y',
							argument12       => NULL,
							argument13       => NULL,
							argument14       => NULL,
							argument15       => NULL,
							argument16       => NULL
						       );
	       END LOOP;
	       COMMIT;
	       IF x_req_id = 0
	       THEN
		  x_err_msg:='Failed to Submit Program - Import Catalog Prices';
		  return x_err_msg;
	       ELSIF x_req_id > 0
	       THEN
		  x_err_msg:= NULL;
		  return x_err_msg;
	       END IF;
	       x_err_msg:= NULL;
	       return x_err_msg;
	    EXCEPTION WHEN OTHERS
	    THEN
	      x_err_msg:='Failed to Call the Program - Import Price Catalogs '||SQLERRM;
	      return x_err_msg;
	    END call_import_program;
	END xx_po_sup_adi_pkg;
/