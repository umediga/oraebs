DROP PACKAGE BODY APPS.XX_INTG_MAIL_UTIL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INTG_MAIL_UTIL_PKG" IS
--------------------------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 07-MAR-2012
 File Name     : XXINTGMAILUTL.pkb
 Description   : The purpose of this utility to use in sending mail program
                 with diffrent type of attachment option
 Change History:

 Date        Name              Remarks
 ----------- -----------       ---------------------------------------
 07-MAR-2012 IBM Development   Initial development
 10-MAY-2012 Renjith           Added send_mail_attach
 11-Sep-2012 Renjith           Added validate_email function
 25-Sep-2012 Renjith           Added test_subject function
 10-Oct-2012 Renjith           Added distinct to validate_email
 24-Jan-2013 Renjith           Added from mail id from wf 
parameters
 01-AUG-2013 Sanjeev           Modified to send emails to multiple email addresses
 */
--------------------------------------------------------------------------------------

  -- Return the next email address in the list of email addresses, separated
  -- by either a "," or a ";".  The format of mailbox may be in one of these:
  --   someone@some-domain
  --   "Someone at some domain" <someone@some-domain>
  --   Someone at some domain <someone@some-domain>
  FUNCTION get_address(addr_list IN OUT VARCHAR2) RETURN VARCHAR2 IS

    addr VARCHAR2(256);
    i    pls_integer;

    FUNCTION lookup_unquoted_char(str  IN VARCHAR2,
                  chrs IN VARCHAR2) RETURN pls_integer AS
      c            VARCHAR2(5);
      i            pls_integer;
      len          pls_integer;
      inside_quote BOOLEAN;
    BEGIN
       inside_quote := false;
       i := 1;
       len := length(str);
       WHILE (i <= len) LOOP

     c := substr(str, i, 1);

     IF (inside_quote) THEN
       IF (c = '"') THEN
         inside_quote := false;
       ELSIF (c = '\') THEN
         i := i + 1; -- Skip the quote character
       END IF;
       GOTO next_char;
     END IF;

     IF (c = '"') THEN
       inside_quote := true;
       GOTO next_char;
     END IF;

     IF (instr(chrs, c) >= 1) THEN
        RETURN i;
     END IF;

     <<next_char>>
     i := i + 1;

       END LOOP;

       RETURN 0;

    END;

  BEGIN

    addr_list := ltrim(addr_list);
    i := lookup_unquoted_char(addr_list, ',;');
    IF (i >= 1) THEN
      addr      := substr(addr_list, 1, i - 1);
      addr_list := substr(addr_list, i + 1);
    ELSE
      addr := addr_list;
      addr_list := '';
    END IF;

    i := lookup_unquoted_char(addr, '<');
    IF (i >= 1) THEN
      addr := substr(addr, i + 1);
      i := instr(addr, '>');
      IF (i >= 1) THEN
    addr := substr(addr, 1, i - 1);
      END IF;
    END IF;

    RETURN addr;
  END;
------------------------------------------------------------------------
  -- Write a MIME header
  PROCEDURE write_mime_header(conn  IN OUT NOCOPY utl_smtp.connection,
                  name  IN VARCHAR2,
                  value IN VARCHAR2) IS
  BEGIN
    utl_smtp.write_data(conn, name || ': ' || value || utl_tcp.CRLF);
  END;
------------------------------------------------------------------------
  -- Mark a message-part boundary.  Set <last> to TRUE for the last boundary.
  PROCEDURE write_boundary(conn  IN OUT NOCOPY utl_smtp.connection,
               last  IN            BOOLEAN DEFAULT FALSE) AS
  BEGIN
    IF (last) THEN
      utl_smtp.write_data(conn, LAST_BOUNDARY);
    ELSE
      utl_smtp.write_data(conn, FIRST_BOUNDARY);
    END IF;
  END;
------------------------------------------------------------------------
  FUNCTION test_subject RETURN VARCHAR2
  IS
      x_subject VARCHAR2(1000) := NULL;
  BEGIN
      xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXCOMMONMAIL'
                                                 ,p_param_name      => 'SUBJECT'
                                                 ,x_param_value     =>  x_subject);  
      IF NVL(x_subject,'X') <> '-'  THEN
         RETURN x_subject;
      ELSE
         RETURN NULL;
      END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN x_subject;      
  END test_subject;
------------------------------------------------------------------------
  FUNCTION validate_email (p_mail_id IN VARCHAR2) RETURN VARCHAR2
  IS
      x_process_mail_id  VARCHAR2(1000);
      x_rect_mail_id     VARCHAR2(1000);
      x_final_mail_id    VARCHAR2(1000);
      x_position         NUMBER := 0;
  BEGIN
      xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXCOMMONMAIL'
                                                 ,p_param_name      => 'MAIL_ID'
                                                 ,x_param_value     =>  x_process_mail_id);
      IF x_process_mail_id IS NOT NULL AND NVL(x_process_mail_id,'X') <> '-' THEN
         x_final_mail_id := x_process_mail_id;
      ELSE
         BEGIN
             SELECT  DISTINCT fscpv.parameter_value
                    ,INSTR(fscpv.parameter_value,'@')
               INTO  x_rect_mail_id
                    ,x_position
               FROM  fnd_svc_comp_params_tl fscpt
                    ,fnd_svc_comp_param_vals fscpv
                    ,fnd_svc_components fsc
              WHERE  fscpt.parameter_id = fscpv.parameter_id
                AND  fscpv.component_id = fsc.component_id
                AND  fscpt.display_name = 'Test Address'
                AND  fsc.component_name = 'Workflow Notification Mailer';
              IF NVL(x_rect_mail_id,'X') <> 'NONE' OR NVL(x_position,0) <> 0 THEN
                 x_final_mail_id := x_rect_mail_id;
              ELSE
                 x_final_mail_id := NULL;
              END IF;
         EXCEPTION 
            WHEN OTHERS THEN
              x_final_mail_id := NULL;
         END;
      END IF;
      IF x_final_mail_id IS NULL THEN
         x_final_mail_id := p_mail_id;
      END IF;
      RETURN x_final_mail_id;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN p_mail_id;
  END validate_email;
  
  ------------------------------------------------------------------------
  PROCEDURE mail(sender     IN VARCHAR2,
         recipients IN VARCHAR2,
         subject    IN VARCHAR2,
         message    IN VARCHAR2) IS
    conn utl_smtp.connection;
    l_subject       VARCHAR2(1000) := subject;
    l_instance_name VARCHAR2(1000); 
    x_to_mail_id    VARCHAR2(1000);
    --x_mail_exp      EXCEPTION;
    x_test_subject  VARCHAR2(1000) := NULL;
    x_from_mail_id  VARCHAR2(1000) := NULL;
  BEGIN
    x_to_mail_id := validate_email(recipients);
    x_test_subject := test_subject;
    BEGIN
      SELECT value
        INTO l_instance_name
        FROM V$PARAMETER
       WHERE name='instance_name';
    EXCEPTION 
      WHEN OTHERS THEN
        l_instance_name := null;
    END;
    IF xx_emf_pkg.g_request_id is not null AND xx_emf_pkg.g_request_id != -1 THEN
        l_subject := 'Request ID '|| xx_emf_pkg.g_request_id || ' : '|| l_subject;
    END IF;
    l_subject := l_subject || ' ('|| l_instance_name || ')';
    L_SUBJECT := X_TEST_SUBJECT||L_SUBJECT;
    
    BEGIN
       SELECT parameter_value
         INTO x_from_mail_id
         FROM fnd_svc_comp_param_vals pv, fnd_svc_comp_params_b pb
        WHERE pv.parameter_id = pb.parameter_id
          AND parameter_name = 'REPLYTO';    
    EXCEPTION 
      WHEN OTHERS THEN
        x_from_mail_id := sender;
    END;
    
    DBMS_OUTPUT.PUT_LINE('From Mail:'||x_from_mail_id);
    conn := begin_mail(x_from_mail_id,x_to_mail_id, l_subject);
    write_text(conn, message);
    end_mail(conn);
  EXCEPTION 
     WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('No mail ' || SQLERRM);  
  END;

  ------------------------------------------------------------------------
  FUNCTION begin_mail(sender     IN VARCHAR2,
              recipients IN VARCHAR2,
              subject    IN VARCHAR2,
              mime_type  IN VARCHAR2    DEFAULT 'text/plain',
              priority   IN PLS_INTEGER DEFAULT NULL)
              RETURN utl_smtp.connection IS
    conn utl_smtp.connection;
  BEGIN
    conn := begin_session;
    begin_mail_in_session(conn, sender, recipients, subject, mime_type,
      priority);
    RETURN conn;
  END;

  ------------------------------------------------------------------------
  PROCEDURE write_text(conn    IN OUT NOCOPY utl_smtp.connection,
               message IN VARCHAR2) IS
  BEGIN
    utl_smtp.write_data(conn, message);
  END;

  ------------------------------------------------------------------------
  PROCEDURE write_mb_text(conn    IN OUT NOCOPY utl_smtp.connection,
              message IN            VARCHAR2) IS
  BEGIN
    utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw(message));
  END;

  ------------------------------------------------------------------------
  PROCEDURE write_raw(conn    IN OUT NOCOPY utl_smtp.connection,
              message IN RAW) IS
  BEGIN
    utl_smtp.write_raw_data(conn, message);
  END;

  ------------------------------------------------------------------------
  PROCEDURE attach_text(conn         IN OUT NOCOPY utl_smtp.connection,
            data         IN VARCHAR2,
            mime_type    IN VARCHAR2 DEFAULT 'text/plain',
            inline       IN BOOLEAN  DEFAULT TRUE,
            filename     IN VARCHAR2 DEFAULT NULL,
                last         IN BOOLEAN  DEFAULT FALSE) IS
  BEGIN
    begin_attachment(conn, mime_type, inline, filename);
    write_text(conn, data);
    end_attachment(conn, last);
  END;

  ------------------------------------------------------------------------
  PROCEDURE attach_base64(conn         IN OUT NOCOPY utl_smtp.connection,
              data         IN RAW,
              mime_type    IN VARCHAR2 DEFAULT 'application/octet',
              inline       IN BOOLEAN  DEFAULT TRUE,
              filename     IN VARCHAR2 DEFAULT NULL,
              last         IN BOOLEAN  DEFAULT FALSE) IS
    i   PLS_INTEGER;
    len PLS_INTEGER;
  BEGIN

    begin_attachment(conn, mime_type, inline, filename, 'base64');

    -- Split the Base64-encoded attachment into multiple lines
    i   := 1;
    len := utl_raw.length(data);
    WHILE (i < len) LOOP
       IF (i + MAX_BASE64_LINE_WIDTH < len) THEN
     utl_smtp.write_raw_data(conn,
        utl_encode.base64_encode(utl_raw.substr(data, i,
        MAX_BASE64_LINE_WIDTH)));
       ELSE
     utl_smtp.write_raw_data(conn,
       utl_encode.base64_encode(utl_raw.substr(data, i)));
       END IF;
       utl_smtp.write_data(conn, utl_tcp.CRLF);
       i := i + MAX_BASE64_LINE_WIDTH;
    END LOOP;

    end_attachment(conn, last);

  END;

  ------------------------------------------------------------------------
  PROCEDURE begin_attachment(conn         IN OUT NOCOPY utl_smtp.connection,
                 mime_type    IN VARCHAR2 DEFAULT 'text/plain',
                 inline       IN BOOLEAN  DEFAULT TRUE,
                 filename     IN VARCHAR2 DEFAULT NULL,
                 transfer_enc IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    write_boundary(conn);
    write_mime_header(conn, 'Content-Type', mime_type);

    IF (filename IS NOT NULL) THEN
       IF (inline) THEN
      write_mime_header(conn, 'Content-Disposition',
        'inline; filename="'||filename||'"');
       ELSE
      write_mime_header(conn, 'Content-Disposition',
        'attachment; filename="'||filename||'"');
       END IF;
    END IF;

    IF (transfer_enc IS NOT NULL) THEN
      write_mime_header(conn, 'Content-Transfer-Encoding', transfer_enc);
    END IF;

    utl_smtp.write_data(conn, utl_tcp.CRLF);
  END;

  ------------------------------------------------------------------------
  PROCEDURE end_attachment(conn IN OUT NOCOPY utl_smtp.connection,
               last IN BOOLEAN DEFAULT FALSE) IS
  BEGIN
    utl_smtp.write_data(conn, utl_tcp.CRLF);
    IF (last) THEN
      write_boundary(conn, last);
    END IF;
  END;

  ------------------------------------------------------------------------
  PROCEDURE end_mail(conn IN OUT NOCOPY utl_smtp.connection) IS
  BEGIN
    end_mail_in_session(conn);
    end_session(conn);
  END;

  ------------------------------------------------------------------------
  FUNCTION begin_session RETURN utl_smtp.connection IS
    conn utl_smtp.connection;
    CURSOR c_smtp_host IS
    SELECT parameter_value
      FROM fnd_svc_comp_param_vals pv
          ,fnd_svc_comp_params_b pb 
     WHERE pv.parameter_id = pb.parameter_id 
       AND parameter_name = 'OUTBOUND_SERVER';

  BEGIN
    -- open SMTP connection
    OPEN c_smtp_host;

    FETCH c_smtp_host INTO smtp_host;
  
    conn := utl_smtp.open_connection(smtp_host, smtp_port);
    CLOSE c_smtp_host;
    utl_smtp.helo(conn, smtp_domain);
    RETURN conn;
  END;

  ------------------------------------------------------------------------
  PROCEDURE begin_mail_in_session(conn       IN OUT NOCOPY utl_smtp.connection,
                  sender     IN VARCHAR2,
                  recipients IN VARCHAR2,
                  subject    IN VARCHAR2,
                  mime_type  IN VARCHAR2  DEFAULT 'text/plain',
                  priority   IN PLS_INTEGER DEFAULT NULL) IS
    my_recipients VARCHAR2(32767) := recipients;
    my_sender     VARCHAR2(32767) := sender;
  BEGIN

    -- Specify sender's address (our server allows bogus address
    -- as long as it is a full email address (xxx@yyy.com).
    utl_smtp.mail(conn, get_address(my_sender));

    -- Specify recipient(s) of the email.
    WHILE (my_recipients IS NOT NULL) LOOP
      utl_smtp.rcpt(conn, get_address(my_recipients));
    END LOOP;

    -- Start body of email
    utl_smtp.open_data(conn);

    -- Set "From" MIME header
    write_mime_header(conn, 'From', sender);

    -- Set "To" MIME header
    write_mime_header(conn, 'To', recipients);

    -- Set "Subject" MIME header
    write_mime_header(conn, 'Subject', subject);

    -- Set "Content-Type" MIME header
    write_mime_header(conn, 'Content-Type', mime_type);

    -- Set "X-Mailer" MIME header
    write_mime_header(conn, 'X-Mailer', MAILER_ID);

    -- Set priority:
    --   High      Normal       Low
    --   1     2     3     4     5
    IF (priority IS NOT NULL) THEN
      write_mime_header(conn, 'X-Priority', priority);
    END IF;

    -- Send an empty line to denotes end of MIME headers and
    -- beginning of message body.
    utl_smtp.write_data(conn, utl_tcp.CRLF);

    IF (mime_type LIKE 'multipart/mixed%') THEN
      write_text(conn, 'This is a multi-part message in MIME format.' ||
    utl_tcp.crlf);
    END IF;

  END;

  ------------------------------------------------------------------------
  PROCEDURE end_mail_in_session(conn IN OUT NOCOPY utl_smtp.connection) IS
  BEGIN
    utl_smtp.close_data(conn);
  END;

  ------------------------------------------------------------------------
  PROCEDURE end_session(conn IN OUT NOCOPY utl_smtp.connection) IS
  BEGIN
    utl_smtp.quit(conn);
  END;
  ------------------------------------------------------------------------
  PROCEDURE send_mail_attach( p_from_name            VARCHAR2
                             ,p_to_name              VARCHAR2
                             ,p_cc_name              VARCHAR2 DEFAULT NULL
                             ,p_bc_name              VARCHAR2 DEFAULT NULL
                             ,p_subject              VARCHAR2
                             ,p_message              VARCHAR2
                             ,p_max_size             NUMBER DEFAULT 9999999999
                             ,p_oracle_directory     VARCHAR2
                             ,p_binary_file          VARCHAR2
                            )
  IS
    x_smtp_server          VARCHAR2 (100);-- := 'oraclesmtp000.integralife.com';
    x_smtp_server_port     NUMBER   := 25;
    x_mail_exp             EXCEPTION;
    
    
    CURSOR c_smtp_host IS
    SELECT parameter_value
      FROM fnd_svc_comp_param_vals pv
          ,fnd_svc_comp_params_b pb 
     WHERE pv.parameter_id = pb.parameter_id 
       AND parameter_name = 'OUTBOUND_SERVER';
       
   x_src_loc  BFILE;
   x_buffer   RAW(54);
   x_tamount  BINARY_INTEGER := 54;
   x_pos      INTEGER := 1;
   x_blob     BLOB := EMPTY_BLOB;
   x_blob_len INTEGER;
   x_amount   INTEGER;
   x_connection_handle  UTL_SMTP.CONNECTION;
   x_to_mail_id VARCHAR2(1000);
   x_test_subject  VARCHAR2(1000) := NULL;
   x_from_mail_id  VARCHAR2(1000) := NULL;  
   type Trecipients is table of varchar2(500);   -- added for multiple email ids
   x_to_mail_list  TRecipients; -- added for multiple email ids
     
   
   PROCEDURE send_header(p_name IN VARCHAR2, p_header IN VARCHAR2) AS
   BEGIN
     UTL_SMTP.WRITE_DATA(x_connection_handle,
                         p_name || ': ' || p_header || UTL_TCP.CRLF);
   END;       
       
BEGIN
   IF p_to_name IS NULL OR p_binary_file IS NULL OR p_oracle_directory IS NULL THEN
      RAISE x_mail_exp;
   END IF;

   x_to_mail_id   := validate_email(p_to_name);
   x_test_subject := test_subject||p_subject;
   
   BEGIN
     SELECT parameter_value
       INTO x_from_mail_id
       FROM fnd_svc_comp_param_vals pv, fnd_svc_comp_params_b pb
      WHERE pv.parameter_id = pb.parameter_id
        AND parameter_name = 'REPLYTO';    
   EXCEPTION 
      WHEN OTHERS THEN
        x_from_mail_id := p_from_name;
   END;   
   
   
   BEGIN
      SELECT regexp_substr( x_to_mail_id,'[^;,]+', 1, level) 
      BULK COLLECT INTO x_to_mail_list 
      FROM dual  
      connect by regexp_substr(x_to_mail_id, '[^,;]+', 1, level) is not null;
   EXCEPTION 
      WHEN OTHERS THEN 
        x_to_mail_id := x_to_mail_id;
   END; 
   
   x_src_loc := BFILENAME(p_oracle_directory,p_binary_file);
   
   OPEN c_smtp_host;
   FETCH c_smtp_host INTO x_smtp_server;
   CLOSE c_smtp_host;

   DBMS_LOB.OPEN (x_src_loc, DBMS_LOB.LOB_READONLY);
   DBMS_LOB.CREATETEMPORARY (x_blob, TRUE); 
   x_amount := DBMS_LOB.GETLENGTH (x_src_loc);
   DBMS_LOB.LOADFROMFILE (x_blob, x_src_loc, x_amount);
   x_blob_len := DBMS_LOB.getlength (x_blob);   

   x_connection_handle := UTL_SMTP.OPEN_CONNECTION(host => x_smtp_server);
   UTL_SMTP.HELO(x_connection_handle, x_smtp_server);
   UTL_SMTP.MAIL(x_connection_handle, x_from_mail_id);
   for i in 1..x_to_mail_list.count loop 
      UTL_SMTP.RCPT(x_connection_handle, x_to_mail_list(i));
   end loop;   
   UTL_SMTP.OPEN_DATA(x_connection_handle);
   send_header('From',x_from_mail_id );
   for i in 1..x_to_mail_list.count loop
      send_header('To',x_to_mail_list(i));
   end loop;   
   send_header('Subject', x_test_subject);   

   --MIME header.
   UTL_SMTP.WRITE_DATA(x_connection_handle,
                       'MIME-Version: 1.0' || UTL_TCP.CRLF);
   UTL_SMTP.WRITE_DATA(x_connection_handle,
                       'Content-Type: multipart/mixed; ' || UTL_TCP.CRLF);
   UTL_SMTP.WRITE_DATA(x_connection_handle,
                       ' boundary= "' || 'SAUBHIK.SECBOUND' || '"' ||
                       UTL_TCP.CRLF);
   UTL_SMTP.WRITE_DATA(x_connection_handle, UTL_TCP.CRLF);
 
   -- Mail Body
   UTL_SMTP.WRITE_DATA(x_connection_handle,
                       '--' || 'SAUBHIK.SECBOUND' || UTL_TCP.CRLF);
   UTL_SMTP.WRITE_DATA(x_connection_handle,
                       'Content-Type: text/plain;' || UTL_TCP.CRLF);
   UTL_SMTP.WRITE_DATA(x_connection_handle,
                       ' charset=US-ASCII' || UTL_TCP.CRLF);
   UTL_SMTP.WRITE_DATA(x_connection_handle, UTL_TCP.CRLF);
   UTL_SMTP.WRITE_DATA(x_connection_handle, p_message || UTL_TCP.CRLF);
   UTL_SMTP.WRITE_DATA(x_connection_handle, UTL_TCP.CRLF);
 
   -- Mail Attachment
   UTL_SMTP.WRITE_DATA(x_connection_handle,
                       '--' || 'SAUBHIK.SECBOUND' || UTL_TCP.CRLF);
   UTL_SMTP.WRITE_DATA(x_connection_handle,
                       'Content-Type: application/pdf' ||
                       UTL_TCP.CRLF);
   UTL_SMTP.WRITE_DATA(x_connection_handle,
                       'Content-Disposition: attachment; ' || UTL_TCP.CRLF);
   UTL_SMTP.WRITE_DATA(x_connection_handle,
                       ' filename="' || p_binary_file || '"' || --My filename
                       UTL_TCP.CRLF);
   UTL_SMTP.WRITE_DATA(x_connection_handle,
                       'Content-Transfer-Encoding: base64' || UTL_TCP.CRLF);
   UTL_SMTP.WRITE_DATA(x_connection_handle, UTL_TCP.CRLF);
   
 /* Writing the BLOL in chunks */
   WHILE x_pos < x_blob_len LOOP
     DBMS_LOB.READ(x_blob, x_tamount, x_pos, x_buffer);
     UTL_SMTP.write_raw_data(x_connection_handle,
                             UTL_ENCODE.BASE64_ENCODE(x_buffer));
     UTL_SMTP.WRITE_DATA(x_connection_handle, UTL_TCP.CRLF);
     x_buffer := NULL;
     x_pos    := x_pos + x_tamount;
   END LOOP;
   UTL_SMTP.WRITE_DATA(x_connection_handle, UTL_TCP.CRLF);
 
   -- Close Email
   UTL_SMTP.WRITE_DATA(x_connection_handle,
                       '--' || 'SAUBHIK.SECBOUND' || '--' || UTL_TCP.CRLF);
   UTL_SMTP.WRITE_DATA(x_connection_handle,
                       UTL_TCP.CRLF || '.' || UTL_TCP.CRLF);
 
   UTL_SMTP.CLOSE_DATA(x_connection_handle);
   UTL_SMTP.QUIT(x_connection_handle);
   DBMS_LOB.FREETEMPORARY(x_blob);
   DBMS_LOB.FILECLOSE(x_src_loc);
   
EXCEPTION 
    WHEN x_mail_exp THEN
        DBMS_OUTPUT.PUT_LINE('send_mail_attach: Validation Failed for To mail id OR Directory Name OR File Name');        
        FND_FILE.PUT_LINE( FND_FILE.LOG,'send_mail_attach: Validation Failed for To mail id OR Directory Name OR File Name');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error send_mail_attach: ' || SQLERRM);        
        FND_FILE.PUT_LINE( FND_FILE.LOG,'Error send_mail_attach: ' || SQLERRM);
END send_mail_attach;
END xx_intg_mail_util_pkg;
/


GRANT EXECUTE ON APPS.XX_INTG_MAIL_UTIL_PKG TO INTG_XX_NONHR_RO;
