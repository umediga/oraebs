DROP PACKAGE APPS.XX_IB_SFDC_OUTBOUND_INT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_IB_SFDC_OUTBOUND_INT_PKG" authid current_user
IS
  ----------------------------------------------------------------------
  /*
  Created By : Vishal
  Creation Date : 28-Feb-2014
  File Name : XX_SDC_IB_INT.pks
  Description : This script creates the specification of the package
  Change History:
  Date          Name           Remarks
  -----------   ----           ---------------------------------------
  28-Feb-2014   Vishal        Initial development.
  */
  ----------------------------------------------------------------------
PROCEDURE get_instbase_details(
    p_publish_batch_id IN NUMBER,
    p_instance_id      IN NUMBER,
    x_ib_output_instance OUT nocopy xx_ib_sfdc_outbound_typ ,
    x_return_status OUT nocopy  VARCHAR2 ,
    x_return_message OUT nocopy VARCHAR2 );
PROCEDURE update_batch(
    p_ib_input_instance IN xx_ib_sfdc_instid_in_typ_tab ,
    x_out_batch_id OUT nocopy NUMBER );
PROCEDURE update_instance(
    p_instance_id  IN NUMBER ,
    p_out_batch_id IN NUMBER );
PROCEDURE update_response(
    p_error_tab IN xx_ib_sfdc_err_mess_typ_tab );
  FUNCTION xx_catch_business_event(
      p_subscription_guid IN raw ,
      p_event             IN OUT nocopy wf_event_t )
    RETURN VARCHAR2;
    -- This procedure is used by the republish concurrent program
  PROCEDURE xx_republish_ib_instance(
      p_errbuf OUT nocopy  VARCHAR2,
      p_retcode OUT nocopy VARCHAR2,
      p_type             IN VARCHAR2,
      p_hidden           IN VARCHAR2,
      p_ib_instance_from IN csi_item_instances.instance_number%type DEFAULT NULL,
      p_ib_instance_to   IN csi_item_instances.instance_number%type DEFAULT NULL,
      p_date_from        IN DATE DEFAULT NULL,
      p_date_to          IN DATE DEFAULT NULL );
  END xx_ib_sfdc_outbound_int_pkg ;
/
