DROP PACKAGE BODY APPS.XX_OE_PROSHIP_WS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OE_PROSHIP_WS_PKG" 
AS
/* $Header: XXOEPROSHIPWSPKG.pkb 1.0 2013/07/23 700:00:00 bedabrata noship $ */
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
   g_transaction_id   VARCHAR2 (100) := NULL;
   g_object_name VARCHAR2 (30) := 'XXOEPROSHIPWS';
   g_target_url VARCHAR2(250) := 'http://'|| xx_emf_pkg.get_paramater_value (g_object_name, 'TARGET_URL');
   g_username varchar2(100) := xx_emf_pkg.get_paramater_value (g_object_name, 'USERNAME');

   PROCEDURE xx_proship_addr_call (
      p_address_req     IN       xx_oe_addr_req_typ
    -- Request for Webservice
   ,  p_ws_response     OUT      xx_oe_addr_resp_tabtyp
    -- Response from Webservice.
   ,  p_error           OUT      VARCHAR2
    , p_alt_addresses   OUT      xx_oe_address_tabtyp
   -- Alternate Addresses from WS response
   )
   IS
      --
      l_response_payload    XMLTYPE;
      l_payload             CLOB           := NULL;
      l_payload_namespace   VARCHAR2 (200);
      l_error_code      NUMBER       := xx_emf_cn_pkg.cn_success;
   BEGIN
      l_error_code := xx_emf_pkg.set_env (p_process_name => g_object_name);
      p_error := NULL;
      g_transaction_id := NVL (p_address_req.transactionidentifier, -1);

      ------Added EMF Log Message start------
      xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium
                      , p_category                 => 'Proship WS Address Call'
                      , p_error_text               =>    'ProShip WS Username is: '
                                                      || g_username||' and Proship WS URL is: '||g_target_url
                      , p_record_identifier_1      => g_transaction_id
                      , p_record_identifier_2      => NULL
                       );
   ------Added EMF Log Message end------
      IF ((LENGTH(g_target_url)>8) AND (g_username IS NOT NULL))
      THEN
         -- Build the request payload XML from input parameters
         l_payload :=
               '<?xml version="1.0" encoding="UTF-8"?><PierbridgeAddressValidationRequest><TransactionIdentifier>'
            || g_transaction_id
            || '</TransactionIdentifier><UserName>'
            || g_username
            || '</UserName><Carrier>'
            || p_address_req.carrier
            || '</Carrier><Address><Street>'
            || p_address_req.street
            || '</Street><City>'
            || p_address_req.city
            || '</City><Region>'
            || p_address_req.region
            || '</Region><PostalCode>'
            || p_address_req.postalcode
            || '</PostalCode><Country>'
            || p_address_req.country
            || '</Country></Address></PierbridgeAddressValidationRequest>';

         ------Added EMF Log Message start------
         xx_emf_pkg.error
                (p_severity                 => xx_emf_cn_pkg.cn_medium
               , p_category                 => 'Proship WS Address Call'
               , p_error_text               =>    'ProShip Address Validation Payload is: '
                                               || l_payload
               , p_record_identifier_1      => g_transaction_id
               , p_record_identifier_2      => NULL
                );
         ------Added EMF Log Message end------

         -- Call procedure to call ProShip Webservice
         xx_oe_proship_ws_pkg.xx_ws_call (l_payload
                                        , g_target_url
                                        , NULL
                                        , NULL
                                        , l_response_payload
                                        , p_error
                                         );

         --
         IF p_error IS NOT NULL
         THEN
            ------Added EMF Log Message start------
            xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_high
                            , p_category                 => 'Proship WS Address Call'
                            , p_error_text               =>    'Error from WS Call: '
                                                            || p_error
                            , p_record_identifier_1      => g_transaction_id
                            , p_record_identifier_2      => NULL
                             );
         ------Added EMF Log Message end------
         END IF;

         -- Extract the response XML for Address Validation
         xx_oe_proship_ws_pkg.xx_extract_addr (l_response_payload
                                             , p_error
                                             , p_ws_response
                                             , p_alt_addresses
                                              );

         ------Added EMF Log Message start------
         IF p_error IS NOT NULL
         THEN
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_high
              , p_category                 => 'Proship WS Address Call'
              , p_error_text               =>    'After Address Extraction. Error While Extraction: '
                                              || p_error
              , p_record_identifier_1      => g_transaction_id
              , p_record_identifier_2      => NULL
               );
         ------Added EMF Log Message end------
         END IF;

      ELSE
         ----Added EMF Log Message start------
         xx_emf_pkg.error
            (p_severity                 => xx_emf_cn_pkg.cn_high
           , p_category                 => 'Proship WS Address Call'
           , p_error_text               => 'Proship Webservice Target URL OR UserName are not properly setup in Process Setup Form.'
           , p_record_identifier_1      => g_transaction_id
           , p_record_identifier_2      => NULL
            );
      ------Added EMF Log Message end------
      END IF;
   --
   EXCEPTION
      WHEN OTHERS
      THEN
         p_error :=
                  'Unexpected Error in Main Address Call. Error: ' || SQLERRM;

         xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_high
                         , p_category                 => 'Proship WS Address Call'
                         , p_error_text               =>    'Proship Address validation.'
                                                         || p_error
                         , p_record_identifier_1      => g_transaction_id
                         , p_record_identifier_2      => NULL
                          );
   END xx_proship_addr_call;

   --
-- Procedure to Validate Shimpent Feasibility via Proship Rate WS Call
   PROCEDURE xx_proship_rate_call (
      p_rate_req   IN       xx_oe_rate_typ
    -- Request for Webservice
   ,  p_error      OUT      VARCHAR2
    -- system error
   ,  p_message    OUT      VARCHAR2
   -- Shipment Feasibility Status (Success -> Feasible, Other Status -> Issue in Shipment method)
   )
   IS
      l_response_payload    XMLTYPE;
      l_payload             CLOB            := NULL;       --varchar2(32767);
      l_payload_namespace   VARCHAR2 (200);
      l_status              VARCHAR2 (1)    := '1';
      l_message             VARCHAR2 (4000);
      l_error_code      NUMBER       := xx_emf_cn_pkg.cn_success;

-- Cursor to extract staus and message from response XML
      CURSOR cur_get_resp (cp_response_xml XMLTYPE)
      IS
         SELECT EXTRACTVALUE (COLUMN_VALUE, '/Status/Code') "STATUS_CODE"
              , EXTRACTVALUE (COLUMN_VALUE, '/Status/Description')
                                                                "STATUS_DESC"
           FROM TABLE
                   (XMLSEQUENCE
                       (cp_response_xml.EXTRACT
                            ('/PierbridgeRateResponse/Packages/Package/Status')
                       )
                   );
   BEGIN
      l_error_code := xx_emf_pkg.set_env (p_process_name => g_object_name);
      p_error := NULL;
      g_transaction_id := NVL (p_rate_req.transactionidentifier, -1);
      ------Added EMF Log Message start------
      xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium
                      , p_category                 => 'Proship WS Rate Call'
                      , p_error_text               =>    'ProShip WS Username is: '
                                                      || g_username||' and Proship WS URL is: '||g_target_url
                      , p_record_identifier_1      => g_transaction_id
                      , p_record_identifier_2      => NULL
                       );
   ------Added EMF Log Message end------
      IF ((LENGTH(g_target_url)>8) AND (g_username IS NOT NULL))
      THEN
         -- Build the request payload XML from input parameters
         l_payload :=
               '<?xml version="1.0" encoding="UTF-8"?>
            <PierbridgeRateRequest>
            <TransactionIdentifier>'
            || g_transaction_id
            || '</TransactionIdentifier>
            <Carrier>'
            || p_rate_req.carrier
            || '</Carrier>
            <ServiceType>'
            || p_rate_req.servicetype
            || '</ServiceType>
            <ShipDate/>
            <Receiver>
            <CompanyName>'
            || p_rate_req.companyname
            || '</CompanyName>
            <Street>'
            || p_rate_req.street
            || '</Street>
            <City>'
            || p_rate_req.city
            || '</City>
            <Region>'
            || p_rate_req.region
            || '</Region>
            <PostalCode>'
            || p_rate_req.postalcode
            || '</PostalCode>
            <Country>'
            || p_rate_req.country
            || '</Country>
            </Receiver>
            <Packages>
            <Package>
            <Weight>'
            || p_rate_req.weight
            || '</Weight>
            </Package>
            </Packages>
            <UserName>'
            || g_username
            || '</UserName>
            </PierbridgeRateRequest>';
         ------Added EMF Log Message start------
         xx_emf_pkg.error
                (p_severity                 => xx_emf_cn_pkg.cn_medium
               , p_category                 => 'Proship WS Rate Call'
               , p_error_text               =>    'ProShip Address Validation Payload is: '
                                               || l_payload
               , p_record_identifier_1      => g_transaction_id
               , p_record_identifier_2      => NULL
                );
         ------Added EMF Log Message end------

         -- Call procedure to call ProShip Webservice
         xx_oe_proship_ws_pkg.xx_ws_call (l_payload
                                        , g_target_url
                                        , NULL
                                        , NULL
                                        , l_response_payload
                                        , p_error
                                         );

         --
         IF p_error IS NOT NULL
         THEN
            ------Added EMF Log Message start------
            xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_high
                            , p_category                 => 'Proship WS Rate Call'
                            , p_error_text               =>    'Error from WS Call: '
                                                            || p_error
                            , p_record_identifier_1      => g_transaction_id
                            , p_record_identifier_2      => NULL
                             );
         ------Added EMF Log Message end------
         END IF;

         -- Extract the status and description
         BEGIN
            FOR rec_get_resp IN cur_get_resp (l_response_payload)
            LOOP
               l_status := rec_get_resp.status_code;
               l_message := rec_get_resp.status_desc;
            END LOOP;

         EXCEPTION
            WHEN OTHERS
            THEN
               l_status := '0';
               p_error :=
                     'Unexpected Exception while parsing Response XML. Error: '
                  || SQLERRM;
               ------Added EMF Log Message start------
               xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_high
                               , p_category                 => 'Proship WS Rate Call'
                               , p_error_text               => p_error
                               , p_record_identifier_1      => g_transaction_id
                               , p_record_identifier_2      => NULL
                                );

               ------Added EMF Log Message end------
         END;

         ------Added EMF Log Message start------
         xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium
                         , p_category                 => 'Proship WS Rate Call'
                         , p_error_text               =>    'Status From Response XML: '
                                                         || l_status
                                                         || ' and Message: '
                                                         || l_message
                         , p_record_identifier_1      => g_transaction_id
                         , p_record_identifier_2      => NULL
                          );

         ------Added EMF Log Message end------
         IF l_status = '1'
         THEN
            p_message := 'Success';
         ELSIF l_status = '0'
         THEN
            p_message := l_message;
         END IF;

         ------Added EMF Log Message start------
         xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium
                         , p_category                 => 'Proship WS Rate Call'
                         , p_error_text               => 'End of Rate Call.'
                         , p_record_identifier_1      => g_transaction_id
                         , p_record_identifier_2      => NULL
                          );
      ------Added EMF Log Message end------
      ELSE
         ----Added EMF Log Message start------
         xx_emf_pkg.error
            (p_severity                 => xx_emf_cn_pkg.cn_high
           , p_category                 => 'Proship WS Rate Call'
           , p_error_text               => 'Proship Webservice Target URL OR UserName are not properly setup in Process Setup Form.'
           , p_record_identifier_1      => g_transaction_id
           , p_record_identifier_2      => NULL
            );
      ------Added EMF Log Message end------
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_error := 'Unexpected Error in Main Rate Call. Error: ' || SQLERRM;

         xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_high
                         , p_category                 => 'Proship WS Rate Call'
                         , p_error_text               =>    'Proship Shipment Feasibility.'
                                                         || p_error
                         , p_record_identifier_1      => g_transaction_id
                         , p_record_identifier_2      => NULL
                          );
   END xx_proship_rate_call;

   -- Procedure to make the webservice call using UTL_HTTP
   PROCEDURE xx_ws_call (
      p_payload       IN       CLOB
    , p_target_url    IN       VARCHAR2
    , p_username      IN       VARCHAR2
    , p_password      IN       VARCHAR2
    , p_xmlresponse   OUT      XMLTYPE
    , p_error         OUT      VARCHAR2
   )
   IS
      l_request         CLOB;                             -- varchar2(30000);
      l_response        VARCHAR2 (32767);
      l_response_clob   CLOB;
      l_http_req        UTL_HTTP.req;
      l_http_resp       UTL_HTTP.resp;
--      l_ntlm_auth_str   VARCHAR2 (2000);
      l_status_code     VARCHAR2 (2000);
--      l_length          NUMBER;
      v_length          NUMBER;
      v_index           NUMBER;
   BEGIN
      l_request := p_payload;
      v_length := DBMS_LOB.getlength (l_request);

--      l_ntlm_auth_str := begin_request (p_target_url, p_username, p_password);
      ------Added EMF Log Message start------
      xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium
                 , p_category                 => 'Proship WS Call'
                 , p_error_text               => 'Inside WS Call. Start Calling Webservice'
                 , p_record_identifier_1      => g_transaction_id
                 , p_record_identifier_2      => NULL
                  );
      ------Added EMF Log Message end------
      UTL_HTTP.set_transfer_timeout (1200);
      l_http_req := UTL_HTTP.begin_request (p_target_url, 'POST', 'HTTP/1.1');
--      utl_http.set_header(l_http_req, 'Proxy-Connection', 'Keep-Alive');
--      UTL_HTTP.set_transfer_timeout (l_http_req, 1200);
      IF ((p_username IS NOT NULL) and (p_password is NOT NULL)) THEN
      UTL_HTTP.set_authentication (l_http_req, p_username, p_password);
      END IF;

      UTL_HTTP.set_header (l_http_req
                         , 'Content-Type'
                         , 'application/x-www-form-urlencoded'
                          --'text/xml;charset=utf-8' --
                          );
      UTL_HTTP.set_header (l_http_req, 'Content-Length', v_length);

--      UTL_HTTP.set_header (l_http_req, 'Persistent-Auth', 'true');
--      UTL_HTTP.set_header (l_http_req, 'Authorization', l_ntlm_auth_str);
      ------Added EMF Log Message start------
      xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium
              , p_category                 => 'Proship WS Call'
              , p_error_text               => 'Inside WS Call. Setting Headers for WS Call'
              , p_record_identifier_1      => g_transaction_id
              , p_record_identifier_2      => NULL
               );
      ------Added EMF Log Message end------
      --      l_length := DBMS_LOB.getlength (l_request);
      v_index := 1;

      IF v_length <= 4000
      THEN
         UTL_HTTP.write_text (l_http_req, l_request);
      ELSE
         WHILE v_index <= v_length
         LOOP
            UTL_HTTP.write_text (l_http_req
                               , SUBSTR (l_request, v_index, 4000)
                                );
            v_index := v_index + 4000;
         END LOOP;
      END IF;

      l_http_resp := UTL_HTTP.get_response (l_http_req);
      l_status_code := l_http_resp.status_code;

      ------Added EMF Log Message start------
      xx_emf_pkg.error
         (p_severity                 => xx_emf_cn_pkg.cn_medium
        , p_category                 => 'Proship WS Call'
        , p_error_text               =>    'Inside WS Call.Response Code from WS is HTTP - '
                                        || l_status_code
        , p_record_identifier_1      => g_transaction_id
        , p_record_identifier_2      => NULL
         );
      ------Added EMF Log Message end------
      DBMS_LOB.createtemporary (l_response_clob, FALSE);

      -- Copy the response into the CLOB.
      BEGIN
         LOOP
            UTL_HTTP.read_text (l_http_resp, l_response, 4000);
            DBMS_LOB.writeappend (l_response_clob
                                , LENGTH (l_response)
                                , l_response
                                 );

         END LOOP;
      EXCEPTION
         WHEN UTL_HTTP.end_of_body
         THEN
            NULL;
      END;

      UTL_HTTP.end_response (l_http_resp);

--      utl_http.close_persistent_conns;

      p_xmlresponse := XMLTYPE.createxml (l_response_clob);

   EXCEPTION
      WHEN UTL_HTTP.request_failed
      THEN
         fnd_file.put_line (fnd_file.LOG
                          , 'Request_Failed: '
                            || UTL_HTTP.get_detailed_sqlerrm
                           );
         p_error := 'REQUEST_FAILED: ' || UTL_HTTP.get_detailed_sqlerrm;
      WHEN UTL_HTTP.http_server_error
      THEN
         fnd_file.put_line (fnd_file.LOG
                          ,    'Http_Server_Error: '
                            || UTL_HTTP.get_detailed_sqlerrm
                           );
         p_error := 'HTTP_SERVER_ERROR: ' || UTL_HTTP.get_detailed_sqlerrm;
      WHEN UTL_HTTP.http_client_error
      THEN
         fnd_file.put_line (fnd_file.LOG
                          ,    'Http_Client_Error: '
                            || UTL_HTTP.get_detailed_sqlerrm
                           );
         p_error := 'HTTP_CLIENT_ERROR: ' || UTL_HTTP.get_detailed_sqlerrm;
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'xx_soap_call -- ' || SQLERRM);
         p_error := 'WS call failed. Unexpected Error: ' || SQLERRM;
   END xx_ws_call;

   --

   -- Procedure to extract data from the response XML
   PROCEDURE xx_extract_addr (
      p_response_xml    IN       XMLTYPE
    , p_error           IN OUT   VARCHAR2
    , p_ws_response     OUT      xx_oe_addr_resp_tabtyp
    , p_alt_addresses   OUT      xx_oe_address_tabtyp
   )
   IS
-- Cursor to get Response from XML
      CURSOR cur_get_resp
      IS
         SELECT EXTRACTVALUE
                           (COLUMN_VALUE
                          , '/PierbridgeAddressValidationResponse/Status/Code'
                           ) "STATUS_CODE"
              , EXTRACTVALUE
                    (COLUMN_VALUE
                   , '/PierbridgeAddressValidationResponse/Status/Description'
                    ) "STATUS_DESC"
              , EXTRACTVALUE
                   (COLUMN_VALUE
                  , '/PierbridgeAddressValidationResponse/OriginalAddressValidated'
                   ) "ORIGINALADDRESSVALIDATED"
              , EXTRACTVALUE
                   (COLUMN_VALUE
                  , '/PierbridgeAddressValidationResponse/OriginalAddressResidential'
                   ) "ORIGINALADDRESSRESIDENTIAL"
              , EXTRACTVALUE (COLUMN_VALUE
                            , '/PierbridgeAddressValidationResponse/Carrier'
                             ) "CARRIER"
              , EXTRACTVALUE
                           (COLUMN_VALUE
                          , '/PierbridgeAddressValidationResponse/CarrierName'
                           ) "CARRIER_NAME"
              , EXTRACTVALUE
                           (COLUMN_VALUE
                          , '/PierbridgeAddressValidationResponse/CarrierScac'
                           ) "CARRIER_SCAC"
              , EXTRACTVALUE
                           (COLUMN_VALUE
                          , '/PierbridgeAddressValidationResponse/ServiceType'
                           ) "SERVICE_TYPE"
              , EXTRACTVALUE
                       (COLUMN_VALUE
                      , '/PierbridgeAddressValidationResponse/ServiceTypeName'
                       ) "SERVICE_TYPE_NAME"
              , EXTRACTVALUE (COLUMN_VALUE
                            , '/PierbridgeAddressValidationResponse/Weight'
                             ) "WEIGHT"
              , EXTRACTVALUE
                   (COLUMN_VALUE
                  , '/PierbridgeAddressValidationResponse/TransactionIdentifier'
                   ) "TRANSACTION_ID"
           FROM TABLE
                   (XMLSEQUENCE
                       (p_response_xml.EXTRACT
                                       ('/PierbridgeAddressValidationResponse')
                       )
                   );

-- Cursor to get Alternate Address from XML
      CURSOR cur_get_addr
      IS
         SELECT EXTRACTVALUE (COLUMN_VALUE, '/AlternateAddress/Street')
                                                                     "STREET"
              , EXTRACTVALUE (COLUMN_VALUE, '/AlternateAddress/Locale')
                                                                     "LOCALE"
              , EXTRACTVALUE (COLUMN_VALUE, '/AlternateAddress/Other')
                                                                      "OTHER"
              , EXTRACTVALUE (COLUMN_VALUE, '/AlternateAddress/City') "CITY"
              , EXTRACTVALUE (COLUMN_VALUE, '/AlternateAddress/Region')
                                                                     "REGION"
              , EXTRACTVALUE (COLUMN_VALUE, '/AlternateAddress/PostalCode')
                                                                "POSTAL_CODE"
              , EXTRACTVALUE (COLUMN_VALUE, '/AlternateAddress/Country')
                                                                    "COUNTRY"
              , EXTRACTVALUE (COLUMN_VALUE, '/AlternateAddress/Residential')
                                                                "RESIDENTIAL"
           FROM TABLE
                   (XMLSEQUENCE
                       (p_response_xml.EXTRACT
                           ('/PierbridgeAddressValidationResponse/AlternateAddresses/AlternateAddress'
                           )
                       )
                   );

      i   NUMBER := NULL;
   BEGIN
      i := 0;
      ------Added EMF Log Message start------
      xx_emf_pkg.error
         (p_severity                 => xx_emf_cn_pkg.cn_medium
        , p_category                 => 'Proship Address Parsing'
        , p_error_text               => 'Inside Address Extraction. Starting XML Parsing.'
        , p_record_identifier_1      => g_transaction_id
        , p_record_identifier_2      => NULL
         );
      ------Added EMF Log Message end------

      FOR rec_get_resp IN cur_get_resp
      LOOP
         i := i + 1;
         p_ws_response (i).status_code := rec_get_resp.status_code;
         p_ws_response (i).status := rec_get_resp.status_desc;
         ------Added EMF Log Message start------
         xx_emf_pkg.error
                 (p_severity                 => xx_emf_cn_pkg.cn_medium
                , p_category                 => 'Proship Address Parsing'
                , p_error_text               =>    'Inside Address Extraction. Status is: '
                                                || p_ws_response (i).status
                , p_record_identifier_1      => g_transaction_id
                , p_record_identifier_2      => NULL
                 );
         ------Added EMF Log Message end------

         p_ws_response (i).origaddrvalidated :=
                                         rec_get_resp.originaladdressvalidated;
         p_ws_response (i).origaddrresidential :=
                                       rec_get_resp.originaladdressresidential;
         p_ws_response (i).carrier := rec_get_resp.carrier;
         p_ws_response (i).carriername := rec_get_resp.carrier_name;
         p_ws_response (i).carrierscac := rec_get_resp.carrier_scac;
         p_ws_response (i).servicetype := rec_get_resp.service_type;
         p_ws_response (i).servicetypename := rec_get_resp.service_type_name;
         p_ws_response (i).weight := rec_get_resp.weight;
         p_ws_response (i).transactionidentifier :=
                                                   rec_get_resp.transaction_id;

         ------Added EMF Log Message start------
         xx_emf_pkg.error
            (p_severity                 => xx_emf_cn_pkg.cn_medium
           , p_category                 => 'Proship Address Parsing'
           , p_error_text               => 'Inside Address Extraction. End Response Extraction'
           , p_record_identifier_1      => g_transaction_id
           , p_record_identifier_2      => NULL
            );
      ------Added EMF Log Message end------
      END LOOP;

      i := 0;

      FOR rec_get_addr IN cur_get_addr
      LOOP
         ------Added EMF Log Message start------
         xx_emf_pkg.error
            (p_severity                 => xx_emf_cn_pkg.cn_medium
           , p_category                 => 'Proship Address Parsing'
           , p_error_text               => 'Inside Address Extraction. Start Alternate Address Extraction.'
           , p_record_identifier_1      => g_transaction_id
           , p_record_identifier_2      => NULL
            );
         ------Added EMF Log Message end------
         i := i + 1;
         p_alt_addresses (i).street := rec_get_addr.street;
         p_alt_addresses (i).locale := rec_get_addr.locale;
         p_alt_addresses (i).other := rec_get_addr.other;
         p_alt_addresses (i).city := rec_get_addr.city;
         p_alt_addresses (i).region := rec_get_addr.region;
         p_alt_addresses (i).postalcode := rec_get_addr.postal_code;
         p_alt_addresses (i).country := rec_get_addr.country;
         p_alt_addresses (i).residential := rec_get_addr.residential;
         ------Added EMF Log Message start------
         xx_emf_pkg.error
            (p_severity                 => xx_emf_cn_pkg.cn_medium
           , p_category                 => 'Proship Address Parsing'
           , p_error_text               =>    'Inside Address Extraction. Alternate Address Street: '
                                           || p_alt_addresses (i).street
           , p_record_identifier_1      => g_transaction_id
           , p_record_identifier_2      => NULL
            );
         ------Added EMF Log Message end------
      END LOOP;

      ------Added EMF Log Message start------
      xx_emf_pkg.error
         (p_severity                 => xx_emf_cn_pkg.cn_medium
        , p_category                 => 'Proship Address Parsing'
        , p_error_text               => 'Inside Address Extraction. End of Address Parsing.'
        , p_record_identifier_1      => g_transaction_id
        , p_record_identifier_2      => NULL
         );
      ------Added EMF Log Message end------
   EXCEPTION
      WHEN OTHERS
      THEN
         p_error :=
                'Unexpected Error in Address Extraction. Error - ' || SQLERRM;

   END xx_extract_addr;
   --
   --Function used to validate the address from Sales Order form personalization
   Function xx_validate_shipment ( p_hdr_del_to_loc IN VARCHAR2
                                  ,p_lne_del_to_loc IN VARCHAR2 DEFAULT NULL
                                  ,p_ship_method    IN VARCHAR2)
   RETURN VARCHAR2
   IS
      l_error                  VARCHAR2(4000) := NULL;
      l_message                VARCHAR2(4000) := NULL;
      l_rate_req               xx_oe_proship_ws_pkg.xx_oe_rate_typ;
      l_call_ws                VARCHAR2(1) := 'Y';
      x_ship_exception         EXCEPTION;
      x_meaning                VARCHAR2(200);
   BEGIN
      BEGIN
        SELECT meaning
          INTO x_meaning
          FROM fnd_lookup_values_vl
         WHERE lookup_type = 'XXINTG_8AM_SHIPPING_METHOD'
           AND meaning = p_ship_method
           AND NVL(enabled_flag,'X')='Y'
           AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE);
      EXCEPTION WHEN OTHERS THEN
         RAISE x_ship_exception;
      END;
      --Carrier_ID, ServiceType and Item weight is hardcoded
      --L_Rate_Req.Carrier := '12';
      --L_Rate_Req.Servicetype := '77';
      --L_Rate_Req.Weight := '2';
      BEGIN
        SELECT  wcs.attribute1 service_type_id
               ,wc.attribute1 carrier_id
          INTO  l_rate_req.servicetype
               ,l_rate_req.carrier
          FROM  wsh_carrier_services wcs
               ,wsh_carriers wc
         WHERE  wcs.carrier_id= wc.carrier_id
           AND  wcs.ship_method_meaning = p_ship_method;
      EXCEPTION
         WHEN OTHERS THEN
            l_rate_req.carrier := '12';
            l_rate_req.servicetype := '77';
      END;

      BEGIN
         xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXOESHIPVALD'
                                                    ,p_param_name      => 'ITEM_WEIGHT'
                                                    ,x_param_value     =>  l_rate_req.weight);
      END;
      --Set the sequence value
      SELECT XXOE_SHIP_ADDR_VALID_STG_S.nextval
        INTO L_Rate_Req.Transactionidentifier
        FROM dual;

      BEGIN
        --Get the delivery address of the record (header or line if line delivery is not null)
        SELECT  hl.address1, hl.city,hl.state,hl.postal_code,hl.country
          INTO 	l_rate_req.street, l_rate_req.city,  l_rate_req.region ,
                l_rate_req.postalcode, l_rate_req.country
          FROM  Hz_Cust_Site_Uses_All Hcsu, Hz_Cust_Acct_Sites_All Hcas, Hz_Party_Sites Hps, Hz_Locations Hl
         WHERE  Hcsu.Location= to_char(nvl(p_lne_del_to_loc,P_Hdr_Del_To_Loc))
           AND  Hcas.Cust_Acct_Site_Id= Hcsu.Cust_Acct_Site_Id
           AND  Hps.Party_Site_Id = Hcas.Party_Site_Id
           AND  Hps.Location_Id= Hl.Location_Id;
      EXCEPTION
        WHEN OTHERS THEN
           --Do not call the web service
           l_call_ws := 'N';
      END;

      IF (L_Call_Ws = 'Y' ) THEN
          --Call the WS
          xx_oe_proship_ws_pkg.xx_proship_rate_call
            ( l_rate_req
             ,l_error
             ,l_message);

         IF L_Message ='Success' THEN
            --Return success for the successful Address validation
            RETURN 'S';
         ELSE
            RETURN L_Message;
         END IF;
      ELSE
         --Do not call the web service
         RETURN 'Delivery Address not found';
      END IF;
   EXCEPTION
      WHEN x_ship_exception THEN
         RETURN 'S';
      WHEN OTHERS THEN
         RETURN 'E';
   END xx_validate_shipment;
   --

   FUNCTION validate_shipment_method ( p_ship_method IN VARCHAR2)
   RETURN VARCHAR2
   IS
     x_meaning VARCHAR2(200);
   BEGIN
      SELECT meaning
        INTO x_meaning
        FROM fnd_lookup_values_vl
       WHERE lookup_type = 'XXINTG_8AM_SHIPPING_METHOD'
         AND meaning = p_ship_method
         AND NVL(enabled_flag,'X')='Y'
         AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE);
     RETURN 'Y';
   EXCEPTION WHEN OTHERS THEN
     RETURN 'E';
   END;
End Xx_Oe_Proship_Ws_Pkg;
/
