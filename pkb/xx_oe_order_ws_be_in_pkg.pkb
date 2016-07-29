DROP PACKAGE BODY APPS.XX_OE_ORDER_WS_BE_IN_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OE_ORDER_WS_BE_IN_PKG" IS

  ----------------------------------------------------------------------------------
  /* $Header: XXOERESUBORDERWSIN.pkb 1.0 2012/04/04 12:00:00 Damd noship $ */
  /*
  Created By    : IBM Technical Team
  Creation Date : 04-Apr-2012
  File Name     : XXOERESUBORDERWSIN.pkb
  Description   : Sales Order Resubmission Public API.

  Change History:

  Version Date        Name                   Remarks
  ------- ----------- -------------------    ----------------------
  1.0     04-Apr-12   IBM Technical Team    Initial development.

  */
  ----------------------------------------------------------------------

  PROCEDURE xx_submit_event(p_header_id IN NUMBER) IS

    -------------------------------------------------------------------------------
    /*
    Created By     : IBM Technical Team
    Creation Date  : 11-APRIL-2012
    Filename       :
    Description    : This procedure raises the custom business event for Inbound Sales Orders.

    Change History:

    Date        Version#    Name                Remarks
    ----------- --------    ---------------     -----------------------------------
    11-Apr-2012   1.0       IBM Technical Team         Initial development.
    */
    --------------------------------------------------------------------------------
    x_event_parameter_list wf_parameter_list_t;
    x_param                wf_parameter_t;
    x_event_name           VARCHAR2(100) := 'intg.oracle.apps.order.inbound.resubmitOrder';
    x_event_key            VARCHAR2(100) := NULL;
    x_parameter_index      NUMBER := 0;

  BEGIN
    
    BEGIN
    
    DELETE FROM XX_OE_ORDER_WS_IN_ERROR_STG
    WHERE  header_id=p_header_id;
     
    EXCEPTION
    WHEN OTHERS THEN
       fnd_file.put_line(fnd_file.log,
                        'Exception while deleteting from XX_OE_ORDER_WS_IN_ERROR_STG.');
      fnd_file.put_line(fnd_file.log, SQLCODE || '-' || SQLERRM);
    END;


    x_event_key            := to_char(SYSDATE, 'YYYYMMDDHH24MISSSSSSS');
    x_event_parameter_list := wf_parameter_list_t();
    -- Add the values to the Event Parameters
    x_param := wf_parameter_t(NULL, NULL);
    x_event_parameter_list.EXTEND;
    x_param.setname('HEADER_ID');
    x_param.setvalue(p_header_id);
    x_parameter_index := x_parameter_index + 1;
    x_event_parameter_list(x_parameter_index) := x_param;
    wf_event.RAISE(p_event_name => x_event_name,
                   p_event_key  => x_event_key,
                   p_parameters => x_event_parameter_list);

  EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,
                        'Exception while raising business event.');
      fnd_file.put_line(fnd_file.log, SQLCODE || '-' || SQLERRM);

  END xx_submit_event;

  PROCEDURE xx_raise_resub_event(errbuf          OUT VARCHAR2,
                                 retcode         OUT NUMBER,
                                 p_headerid_from IN NUMBER,
                                 p_headerid_to   IN NUMBER,
                                 p_date_from     IN VARCHAR2,
                                 p_date_to       IN VARCHAR2) IS
    -------------------------------------------------------------------------------
    /*
    Created By     : IBM Technical Team
    Creation Date  : 11-APRIL-2012
    Filename       :
    Description    : This procedure is invoked from the Concurrent program for raising custom business event for Inbound Sales Orders.

    Change History:

    Date        Version#    Name                Remarks
    ----------- --------    ---------------     -----------------------------------
    11-Apr-2012   1.0       IBM Technical Team         Initial development.
    24-Oct-2012   1.1       IBM Technical Team         Modified to handle Discarded Orders.
    20-MAR-2013   1.2       IBM Technical Team         Modified to update Intermediate Status. Case#002284
    */
    --------------------------------------------------------------------------------

     CURSOR c_get_headerid#(p_headerid_from_val NUMBER, p_headerid_to_val NUMBER, p_date_from_val DATE, p_date_to_val DATE) IS
      SELECT DISTINCT header_id
        FROM xx_oe_order_ws_in_header_stg
       WHERE ((creation_date BETWEEN p_date_from_val AND
             nvl(p_date_to_val, p_date_from_val + 1)) OR
             (header_id BETWEEN p_headerid_from_val AND
             nvl(p_headerid_to_val, p_headerid_from_val)))
         AND NVL(status,'Failed') NOT IN (G_SUCCESS_MSG, G_DISCARD_MSG, G_PROCESSING_MSG) -- Modified on 24Oct2012 to handle Discarded Orders
       ORDER BY header_id;

    l_header_id NUMBER;

    x_date_from DATE;
    x_date_to   DATE;

    l_count NUMBER := 0;

  BEGIN

    x_date_from := fnd_date.canonical_to_date(p_date_from);
    x_date_to   := fnd_date.canonical_to_date(p_date_to) + 1;

    fnd_file.put_line(fnd_file.log, 'Paramteres: ');
    fnd_file.put_line(fnd_file.log, 'Header ID From: ' || p_headerid_from);
    fnd_file.put_line(fnd_file.log, 'Header ID To: ' || p_headerid_to);
    fnd_file.put_line(fnd_file.log, 'Date From: ' || x_date_from);
    fnd_file.put_line(fnd_file.log, 'Date To: ' || x_date_to);
    fnd_file.put_line(fnd_file.log, 'Resubmitted Orders: ');

    OPEN c_get_headerid#(p_headerid_from_val => p_headerid_from,
                         p_headerid_to_val   => p_headerid_to,
                         p_date_from_val     => x_date_from,
                         p_date_to_val       => x_date_to);

    LOOP
      FETCH c_get_headerid#
        INTO l_header_id;

      EXIT WHEN c_get_headerid#%NOTFOUND;
      --- Update with processing intermediate status
      --- Added on 20Mar2013 for Case# 002284 
      BEGIN
        UPDATE xx_oe_order_ws_in_header_stg
           SET status = 'Processing'
         WHERE header_id =  l_header_id; 
         fnd_file.put_line(fnd_file.log, 'Updated Intermediate Status as Processing for Header Id: ' || l_header_id);
      EXCEPTION
       WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log, 'Error While Updating Intermediate Status for Header ID: ' || l_header_id);
        fnd_file.put_line(fnd_file.log, 'Error : ' || SQLERRM);
      END;
      -- End of Code addition
      xx_submit_event(l_header_id);
      fnd_file.put_line(fnd_file.log, 'Header ID: ' || l_header_id);
      l_count := l_count + 1;

    END LOOP;

    CLOSE c_get_headerid#;

    IF (l_count = 0) THEN
      fnd_file.put_line(fnd_file.log, 'No records found.');

    ELSE
      fnd_file.put_line(fnd_file.log, 'Records fetched: ' || l_count);

    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      errbuf := 'Exception :' || SQLERRM;
      fnd_file.put_line(fnd_file.log,
                        'Exception occurred while resubmitting...');
      fnd_file.put_line(fnd_file.log, SQLCODE || '-' || SQLERRM);

  END xx_raise_resub_event;

END xx_oe_order_ws_be_in_pkg; 
/
