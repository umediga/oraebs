DROP PACKAGE BODY APPS.XX_SFDC_ORDER_LOAD_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_SFDC_ORDER_LOAD_PKG" 
AS
  ----------------------------------------------------------------------
  /*
  Created By    : Vishal
  Creation Date : 19-MAY-2014
  File Name     : XX_SFDC_ORDER_LOAD_PKG.pkb
  Description   : This script creates the body of the package
  xx_sfdc_order_load_pkg
  Change History:
  Date        Name          Remarks
  ----------- ------------- -----------------------------------
  19-MAY-2014 Vishal        Initial Development
  */
  ----------------------------------------------------------------------
PROCEDURE submit_order_details(
    x_return_status OUT nocopy  VARCHAR2 ,
    x_return_message OUT nocopy VARCHAR2 )
IS
  min_order oe_order_headers_all.order_number%type;
  max_order oe_order_headers_all.order_number%type :=0;
  order_count         NUMBER                               := 1000;
  max_inprocess_count NUMBER                               := 5000;
  inprocess_count     NUMBER                               := 0;
  l_request_id        NUMBER;
  l_dev_status        VARCHAR2(100);
  l_dev_phase         VARCHAR2(100);
  l_phase             VARCHAR2(100);
  l_status            VARCHAR2(30);
  l_message           VARCHAR2(4000);
  L_REQUEST_COMPLETE  BOOLEAN;
  tot_order           NUMBER;
BEGIN
  BEGIN
    SELECT MAX(HEADER_ID) INTO MIN_ORDER FROM XX_OM_SFDC_HEAD_CONTROL_TBL ;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    SELECT MIN(HEADER_ID) INTO MIN_ORDER FROM OE_ORDER_HEADERS_ALL ;
  WHEN OTHERS THEN
    MIN_ORDER := 0;
  END;
  IF MIN_ORDER IS NULL THEN
    SELECT MIN(HEADER_ID) INTO MIN_ORDER FROM OE_ORDER_HEADERS_ALL ;
  END IF;
  SELECT MAX(header_id) INTO tot_order FROM oe_order_headers_all ;
  WHILE min_order < tot_order
  LOOP
    SELECT MIN(header_id)
    INTO max_order
    FROM
      (SELECT header_id FROM oe_order_headers_all ORDER BY header_id
      )
    WHERE header_id > min_order + order_count ;
    fnd_file.put_line ( fnd_file.log,'Min Order :' || min_order);
    fnd_file.put_line ( fnd_file.log,'Max Order :' || max_order);
    L_REQUEST_ID := FND_REQUEST.SUBMIT_REQUEST( application => 'XXINTG' ,program => 'XXSFDCOMRMA' ,description => NULL ,start_time => sysdate ,sub_request => false ,argument1 => 'Initial' ,argument2 => NULL ,argument3 => 'Y' ,argument4 => min_order ,argument5 => max_order ,argument6 => NULL ,argument7 => NULL );
    COMMIT;
    fnd_file.put_line ( fnd_file.log,'L_REQUEST_ID :' || l_request_id);
    IF l_request_id !=0 THEN
      LOOP
        l_request_complete := APPS.FND_CONCURRENT.WAIT_FOR_REQUEST(l_request_id, 1, 0, l_phase, l_status, l_dev_phase, l_dev_status, l_message);
        IF upper(l_phase)   = 'COMPLETED' THEN
          EXIT;
        END IF;
      END LOOP;
    END IF;
    DBMS_LOCK.SLEEP(60);
    SELECT COUNT(1)
    INTO inprocess_count
    FROM xx_om_sfdc_head_control_tbl
    WHERE status_flag NOT IN ('SUCCESS','FAILED');
    fnd_file.put_line ( fnd_file.log, 'INPROCESS_COUNT :' || inprocess_count);
    IF inprocess_count > max_inprocess_count*4 THEN
      EXIT;
    ELSIF inprocess_count > max_inprocess_count*3 THEN
      dbms_lock.sleep(180);
    ELSIF inprocess_count > max_inprocess_count*2 THEN
      dbms_lock.sleep(120);
    ELSIF inprocess_count > max_inprocess_count THEN
      dbms_lock.sleep(60);
    END IF;
    SELECT MIN(header_id)
    INTO min_order
    FROM
      (SELECT header_id FROM oe_order_headers_all ORDER BY header_id
      )
    WHERE header_id > max_order ;
  END LOOP;
END submit_order_details ;
END xx_sfdc_order_load_pkg;
/
