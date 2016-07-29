DROP PACKAGE APPS.XX_OE_PROSHIP_WS_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OE_PROSHIP_WS_PKG" 
AUTHID CURRENT_USER AS
/* $Header: XXOMPROSHIPWSPKG.pkb 1.0 2013/07/23 700:00:00 bedabrata noship $ */
-------------------------------------------------------------------------------
/*
 Package Name  :  XX_OE_PROSHIP_WS_PKG
 Author's name :  Bedabrata Bhattacharjee(IBM)
 Date written  :  08-JUL-2013
 Description   :  This is an outbound interface from Oracle to Proship

 Maintenance History:

 Date        Issue#   Name                            Remarks
 ----------- -------- -------------------             -------------------------
 08-JUL-2013       1  Bedabrata Bhattacharjee (IBM)   Initial Development.
*/
-------------------------------------------------------------------------------



   -- Declare types for Address validation WS Request.
   TYPE xx_oe_addr_req_typ IS RECORD (
      transactionidentifier   VARCHAR2 (100)
    , carrier                 VARCHAR2 (10)
    , street                  VARCHAR2 (250)
    , city                    VARCHAR2 (250)
    , region                  VARCHAR2 (250)
    , postalcode              VARCHAR2 (50)
    , country                 VARCHAR2 (250)
   );

--   TYPE xx_oe_addr_req_tabtyp IS TABLE OF xx_oe_addr_req_typ
--      INDEX BY BINARY_INTEGER;
-- End types for Address validation WS Request.

   -- Declare types for Address validation WS response.
   TYPE xx_oe_addr_resp_typ IS RECORD (
      status_code             NUMBER
    , status                  VARCHAR2 (250)
    , origaddrvalidated       NUMBER
    , origaddrresidential     NUMBER
    , carrier                 VARCHAR2 (10)
    , carriername             VARCHAR2 (250)
    , carrierscac             VARCHAR2 (10)
    , servicetype             VARCHAR2 (50)
    , servicetypename         VARCHAR2 (250)
    , weight                  VARCHAR2 (50)
    , transactionidentifier   VARCHAR2 (100)
   );

   TYPE xx_oe_addr_resp_tabtyp IS TABLE OF xx_oe_addr_resp_typ
      INDEX BY BINARY_INTEGER;

   TYPE xx_oe_address_typ IS RECORD (
      street        VARCHAR2 (250)
    , locale        VARCHAR2 (250)
    , other         VARCHAR2 (250)
    , city          VARCHAR2 (250)
    , region        VARCHAR2 (250)
    , postalcode    VARCHAR2 (50)
    , country       VARCHAR2 (250)
    , residential   NUMBER
   );

   TYPE xx_oe_address_tabtyp IS TABLE OF xx_oe_address_typ
      INDEX BY BINARY_INTEGER;

-- End types for Address validation WS response.

   -- Declare types for Rate WS request.
   TYPE xx_oe_rate_typ IS RECORD (
      transactionidentifier   VARCHAR2 (100)
    , carrier                 VARCHAR2 (10)
    , servicetype             VARCHAR2 (50)
    , companyname             VARCHAR2 (250)
    , street                  VARCHAR2 (250)
    , city                    VARCHAR2 (250)
    , region                  VARCHAR2 (250)
    , postalcode              VARCHAR2 (50)
    , country                 VARCHAR2 (250)
    , weight                  VARCHAR2 (50)
   );

--   TYPE xx_oe_rate_tabtyp IS TABLE OF xx_oe_rate_typ
--      INDEX BY BINARY_INTEGER;
-- End types for Rate WS request.


   --Function used to validate the address from Sales Order form personalization
   Function Xx_Validate_Shipment ( p_hdr_del_to_loc IN VARCHAR2
				  ,p_lne_del_to_loc IN VARCHAR2 DEFAULT NULL
				  ,p_ship_method    IN VARCHAR2)
   RETURN VARCHAR2;
   -- Procedure to Validate Address via Proship WS Call
   PROCEDURE xx_proship_addr_call (
      p_address_req     IN       xx_oe_addr_req_typ
    -- Request for Webservice
   ,  p_ws_response     OUT      xx_oe_addr_resp_tabtyp
    -- Response from Webservice.
   ,  p_error           OUT      VARCHAR2
    -- system error
   ,  p_alt_addresses   OUT      xx_oe_address_tabtyp
   -- Alternate Addresses from WS response
   );

-- Procedure to Validate Shimpent Feasibility via Proship Rate WS Call
   PROCEDURE xx_proship_rate_call (
      p_rate_req   IN       xx_oe_rate_typ
    -- Request for Webservice
   ,  p_error      OUT      VARCHAR2
    -- system error
   ,  p_message    OUT      VARCHAR2
   -- Shipment Feasibility Status (Success -> Feasible, Other Status -> Issue in Shipment method)
   );
--
-- Procedure to make independent WebService Call
   PROCEDURE xx_ws_call (
      p_payload       IN       CLOB
    , p_target_url    IN       VARCHAR2
    , p_username      IN       VARCHAR2
    , p_password      IN       VARCHAR2
    , p_xmlresponse   OUT      XMLTYPE
    , p_error         OUT      VARCHAR2
   );
--
-- Procedure to Extract Address from response XML
   PROCEDURE xx_extract_addr (
      p_response_xml    IN       XMLTYPE
    , p_error           IN OUT   VARCHAR2
    , p_ws_response     OUT      xx_oe_addr_resp_tabtyp
    , p_alt_addresses   OUT      xx_oe_address_tabtyp
   );
--
-- Added by Renjith on 12-Aug-2013, for checking with lookup
   FUNCTION validate_shipment_method ( p_ship_method IN VARCHAR2)
   RETURN VARCHAR2;

End Xx_Oe_Proship_Ws_Pkg;
/
