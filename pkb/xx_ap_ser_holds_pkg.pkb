DROP PACKAGE BODY APPS.XX_AP_SER_HOLDS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AP_SER_HOLDS_PKG" 
AS
	/****************************************************************************
	**
	-- Filename:  XX_AP_SER_HOLDS_PKG.pkb
	-- RICEW Object id : R2R-EXT_157
	-- Purpose :  Package Body applying hold on the invoice if the Invoice is
	--            mathed to PO and requires approval. Only Invoices that are
	--            matched to PO and has service line against that PO are
	--            included in auto application of holds.
	--
	-- Usage: Concurrent Program ( Type PL/SQL Procedure)
	-- Caution:
	-- Copyright (c) IBM
	-- All rights reserved.
	-- Ver  Date         Author             Modification
	-- ---- -----------  ------------------
	--------------------------------------
	-- 1.0  10-Oct-2013  Naga Uppara          Created
	--
	--
	*****************************************************************************
	*/
	g_creation_date DATE := sysdate;
	g_created_by NUMBER := fnd_global.user_id;
	g_last_update_date DATE := sysdate;
	g_last_updated_by NUMBER := fnd_global.user_id;
	g_last_update_login NUMBER := fnd_global.login_id;
	g_request_id NUMBER := fnd_global.conc_request_id;
	g_user_id NUMBER := fnd_global.user_id;
	g_resp_id NUMBER := fnd_global.resp_id;
	g_resp_appl_id NUMBER := fnd_global.resp_appl_id;
	g_org_id NUMBER := fnd_global.org_id;
FUNCTION check_po_has_svc_line_with_req(
		p_po_header_id IN NUMBER)
	RETURN BOOLEAN
IS
	l_count_services_lines NUMBER;
BEGIN
	IF p_po_header_id IS NULL THEN
		RETURN false;
	END IF;
	l_count_services_lines := 0;
		SELECT  NVL(no_req_count , 0) + NVL(req_count , 0)
					INTO l_count_services_lines
					FROM
			(SELECT  COUNT(*) no_req_count
							FROM po_lines_all pol , po_distributions_all pod , po_line_types plt
						WHERE pol.po_header_id = p_po_header_id AND
					pol.line_type_id = plt.line_type_id AND
					plt.receiving_flag = 'N' AND
					pod.po_line_id = pol.po_line_id AND
					pod.req_distribution_id IS NULL
			) ,(SELECT  COUNT(*) req_count
							FROM po_lines_all pol , po_distributions_all pod , po_line_types plt
						WHERE pol.po_header_id = p_po_header_id AND
					pol.line_type_id = plt.line_type_id AND
					plt.receiving_flag = 'N' AND
					pod.po_line_id = pol.po_line_id AND
					pod.req_distribution_id IS NOT NULL
			) ;
	IF(l_count_services_lines > 0) THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
EXCEPTION
WHEN no_data_found THEN
	RETURN false;
WHEN OTHERS THEN
	po_message_s.sql_error('xx_ap_ser_holds_pkg.check_po_has_svc_line_with_req' , '000' , SQLCODE) ;
	raise;
END check_po_has_svc_line_with_req;
FUNCTION get_inv_matched_status(
		p_invoice_id IN NUMBER)
	RETURN BOOLEAN
IS
	l_matched_count NUMBER;
	l_debug_loc VARCHAR2(30) := 'Get_Inv_Matched_Status';
	l_debug_info VARCHAR2(1000) ;
BEGIN
		SELECT  COUNT(*)
					INTO l_matched_count
					FROM ap_invoice_distributions
				WHERE invoice_id = p_invoice_id AND
			po_distribution_id IS NOT NULL AND
			line_type_lookup_code IN('ITEM' , 'ACCRUAL' , 'IPV') ;
	IF(l_matched_count > 0) THEN
		RETURN(true) ;
	ELSE
		RETURN(false) ;
	END IF;
EXCEPTION
WHEN no_data_found THEN
	RETURN(false) ;
WHEN OTHERS THEN
	IF(SQLCODE <> -20001) THEN
		NULL;
	END IF;
	app_exception.raise_exception;
END get_inv_matched_status;
PROCEDURE process_service_holds(
		p_invoice_id IN NUMBER)
IS
	CURSOR c1(cp_invoice_id IN NUMBER)
	IS
		SELECT DISTINCT MAX(pod.line_location_id) po_line_location_id , pod.deliver_to_person_id requester_id , a.org_id
						FROM ap_invoices_v A , ap_invoice_distributions_all b , po_distributions_all pod
					WHERE a.invoice_id = p_invoice_id AND
				--pod.po_header_id               = b.po_header_id AND
				NVL(b.cancelled_flag , 'N') ='N' AND
				--NVL( b.discarded_flag,'N')     ='N' AND
				A.invoice_id =b.invoice_id AND
				b.po_distribution_Id =pod.po_distribution_id AND
				A.APPROVAL_STATUS_LOOKUP_CODE IN('NEEDS REAPPROVAL' , 'NEVER APPROVED') AND
				A.po_number <>'UNMATCHED' AND
				A.SELECTED_FOR_PAYMENT_FLAG <>'Y' AND
				a.PAYMENTS_EXIST_FLAG <>'Y' AND
				A.INVOICE_TYPE_LOOKUP_CODE ='STANDARD' AND
				A.cancelled_date IS NULL AND
				pod.deliver_to_person_id IS NOT NULL AND
				EXISTS
				(SELECT  1
								FROM po_lines_all pol , po_line_types plt
							WHERE pol.po_header_id = pod.po_header_id AND
						pol.line_type_id = plt.line_type_id AND
						plt.receiving_flag = 'N' AND
						pod.po_line_id = pol.po_line_id
				) AND
			NOT EXISTS
			(SELECT  1
							FROM ap_holds_all b
						WHERE a.invoice_id = b.invoice_id AND
					b.hold_lookup_code = 'Integra Service PO Hold' AND
					pod.deliver_to_person_id=b.attribute4 and
     b.wf_status in ('RELEASED','STARTED','MANUALLYRELEASED')
			)
	GROUP BY pod.deliver_to_person_id , a.org_id
			UNION
	SELECT DISTINCT MAX(pod.line_location_id) po_line_location_id , a.requester_id requester_id , a.org_id
					FROM ap_invoices_v A , ap_invoice_distributions_all b , po_distributions_all pod
				WHERE a.invoice_id = p_invoice_id AND
			--pod.po_header_id               = b.po_header_id AND
			NVL(b.cancelled_flag , 'N') ='N' AND
			--NVL( b.discarded_flag,'N')     ='N' AND
			A.invoice_id =b.invoice_id AND
			b.po_distribution_Id =pod.po_distribution_id AND
			A.APPROVAL_STATUS_LOOKUP_CODE IN('NEEDS REAPPROVAL' , 'NEVER APPROVED') AND
			A.po_number <>'UNMATCHED' AND
			A.SELECTED_FOR_PAYMENT_FLAG <>'Y' AND
			a.PAYMENTS_EXIST_FLAG <>'Y' AND
			A.INVOICE_TYPE_LOOKUP_CODE ='STANDARD' AND
			A.cancelled_date IS NULL AND
			pod.deliver_to_person_id IS NULL AND
			a.requester_id IS NOT NULL AND
			EXISTS
			(SELECT  1
							FROM po_lines_all pol , po_line_types plt
						WHERE pol.po_header_id = pod.po_header_id AND
					pol.line_type_id = plt.line_type_id AND
					plt.receiving_flag = 'N' AND
					pod.po_line_id = pol.po_line_id
			) AND
			NOT EXISTS
			(SELECT  1
							FROM ap_holds_all b
						WHERE a.invoice_id = b.invoice_id AND
					b.hold_lookup_code = 'Integra Service PO Hold' AND
					A.requester_id =b.attribute4 and
     b.wf_status in ('RELEASED','STARTED','MANUALLYRELEASED')
			)
	GROUP BY a.requester_id , a.org_id
			UNION
	SELECT DISTINCT MAX(pod.line_location_id) po_line_location_id , get_default_approver requester_id , a.org_id
					FROM ap_invoices_v A , ap_invoice_distributions_all b , po_distributions_all pod
				WHERE a.invoice_id = p_invoice_id AND
			--pod.po_header_id               = b.po_header_id AND
			NVL(b.cancelled_flag , 'N') ='N' AND
			--NVL( b.discarded_flag,'N')     ='N' AND
			A.invoice_id =b.invoice_id AND
			b.po_distribution_Id =pod.po_distribution_id AND
			A.APPROVAL_STATUS_LOOKUP_CODE IN('NEEDS REAPPROVAL' , 'NEVER APPROVED') AND
			A.po_number <>'UNMATCHED' AND
			A.SELECTED_FOR_PAYMENT_FLAG <>'Y' AND
			a.PAYMENTS_EXIST_FLAG <>'Y' AND
			A.INVOICE_TYPE_LOOKUP_CODE ='STANDARD' AND
			A.cancelled_date IS NULL AND
			pod.deliver_to_person_id IS NULL AND
			a.requester_id IS NULL AND
			EXISTS
			(SELECT  1
							FROM po_lines_all pol , po_line_types plt
						WHERE pol.po_header_id = pod.po_header_id AND
					pol.line_type_id = plt.line_type_id AND
					plt.receiving_flag = 'N' AND
					pod.po_line_id = pol.po_line_id
			) AND
			NOT EXISTS
			(SELECT  1
							FROM ap_holds_all b
						WHERE a.invoice_id = b.invoice_id AND
					b.hold_lookup_code = 'Integra Service PO Hold' AND
					get_default_approver=b.attribute4 and
     b.wf_status in ('RELEASED','STARTED','MANUALLYRELEASED')
			)
	GROUP BY get_default_approver , a.org_id;
	l_emp_name VARCHAR2(1000) ;
	l_email VARCHAR2(1000) ;
	l_buyer_name VARCHAR2(1000) ;
	l_buyer_id NUMBER;
	l_requester_id NUMBER;
	l_rowid rowid;
	l_hold_id NUMBER;
	l_rule_applied VARCHAR2(40) ;
BEGIN
	FOR i IN c1(p_invoice_id)
	LOOP
		l_requester_id:=NULL;
		l_emp_name :=NULL;
		l_rule_applied:=NULL;
		BEGIN
				SELECT  person_id
							INTO l_requester_id
							FROM per_workforce_current_x
						WHERE person_id=i.requester_id;
		EXCEPTION
		WHEN no_data_found THEN
			l_requester_id:=NULL;
			BEGIN
					SELECT  supervisor_id
								INTO l_requester_id
								FROM per_all_assignments_f
							WHERE person_id=i.requester_id AND
						assignment_status_type_Id=1 AND
						effective_end_date =
						(SELECT  MAX(effective_end_date)
										FROM per_all_assignments_f
									WHERE person_id=i.requester_id AND
								assignment_status_type_Id=1
						) ;
			EXCEPTION
			WHEN no_data_found THEN
				l_requester_id:=get_default_approver;
			END;
		WHEN OTHERS THEN
			l_requester_id:=get_default_approver;
		END;
		BEGIN
				SELECT  full_name , email_address
							INTO l_emp_name , l_email
							FROM per_workforce_current_x
						WHERE person_id=l_requester_id;
		EXCEPTION
		WHEN OTHERS THEN
			l_emp_name:='No Requester Found';
		END;
		ap_holds_pkg.insert_row(x_rowid => l_rowid , x_hold_id => l_hold_id , x_invoice_id => p_invoice_id ,
		x_line_location_id => i.po_line_location_id , x_hold_lookup_code => 'Integra Service PO Hold' , x_last_update_date =>
		g_last_update_date , x_last_updated_by => g_last_updated_by , x_held_by => g_last_updated_by , x_hold_date =>
		g_creation_date , x_hold_reason => 'Service PO Hold that waits till all requesters approve' , x_release_lookup_code
		=> NULL , x_release_reason => NULL , x_status_flag => NULL , x_last_update_login => g_last_update_login ,
		x_creation_date => g_creation_date , x_created_by => g_last_updated_by , x_responsibility_id => g_resp_id ,
		x_attribute1 => l_emp_name , x_attribute2 => l_email , x_attribute3 => NULL , x_attribute4 => l_requester_id ,
		x_attribute5 => NULL , x_attribute6 => NULL , x_attribute7 => NULL , x_attribute8 => NULL , x_attribute9 => NULL ,
		x_attribute10 => NULL , x_attribute11 => NULL , x_attribute12 => NULL , x_attribute13 => NULL , x_attribute14 => NULL
		, x_attribute15 => NULL , x_attribute_category => NULL , x_org_id => i.org_id , x_calling_sequence => NULL) ;
	END LOOP;
END;
FUNCTION get_default_approver
	RETURN NUMBER
IS
BEGIN
	RETURN fnd_profile.value('INTG_AP_SER_HOLD_DEFAULT_APPROVER') ;
EXCEPTION
WHEN OTHERS THEN
	RETURN 1;
END;
END;
/
