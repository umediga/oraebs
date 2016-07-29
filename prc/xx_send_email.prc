DROP PROCEDURE APPS.XX_SEND_EMAIL;

CREATE OR REPLACE PROCEDURE APPS."XX_SEND_EMAIL" (p_email IN VARCHAR2, p_user_name IN VARCHAR2, p_pwd IN VARCHAR2) IS
  v_From      VARCHAR2(80) := 'delphi.uat@integralife.com';
  v_Recipient VARCHAR2(80) := p_email;   --'maheshwar.ganguli@integralife.com';
  v_Subject   VARCHAR2(80) := 'UAT - Account Information';
  v_Mail_Host VARCHAR2(30) := 'azorasmtp000';
  v_Mail_Conn utl_smtp.Connection;
  v_pwd VARCHAR2(25) := p_pwd;
  v_username varchar2(100) := p_user_name;
  crlf        VARCHAR2(2)  := chr(13)||chr(10);
BEGIN
 v_Mail_Conn := utl_smtp.Open_Connection(v_Mail_Host, 25);
 utl_smtp.Helo(v_Mail_Conn, v_Mail_Host);
 utl_smtp.Mail(v_Mail_Conn, v_From);
 utl_smtp.Rcpt(v_Mail_Conn, v_Recipient);
 utl_smtp.Data(v_Mail_Conn,
   'Date: '   || to_char(sysdate, 'Dy, DD Mon YYYY hh24:mi:ss') || crlf ||
   'From: '   || v_From || crlf ||
   'Subject: '|| v_Subject || crlf ||
   'To: '     || v_Recipient || crlf ||
   crlf ||
   'UAT URL: http://uspsapp01.integralife.com'|| crlf ||    -- Message body
   'Username: '||v_username ||' '|| crlf||
   'Password: '||v_pwd ||' '|| crlf
 );
 utl_smtp.Quit(v_mail_conn);
EXCEPTION
 WHEN utl_smtp.Transient_Error OR utl_smtp.Permanent_Error then
   raise_application_error(-20000, 'Unable to send mail: '||sqlerrm);
END; 
/
