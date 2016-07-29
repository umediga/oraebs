DROP PACKAGE APPS.XX_COMMON_PROCESS_EMAIL;

CREATE OR REPLACE PACKAGE APPS."XX_COMMON_PROCESS_EMAIL" 
AS
--------------------------------------------------------------------
--
-- Package Name:  XXCOMMONPROCESSEMAIL.pks
-- Author's name: IBM Development
-- Description:   Custom Common Process to Send email for each custom program
--
-- Change History:
--
-- Date        Ver  Name            Change
-- ----------- ----  ------------  --------------------------------------------
-- 07-MAR-2012 1.0   IBM Development          Intial version
--
--------------------------------------------------------------------

   TYPE ARGTYPE IS RECORD (
      arg1 VARCHAR2(200));

   TYPE ARGTBL IS VARRAY(2000) OF ARGTYPE;
v_max_sleep_time    NUMBER:=1000;

-- Function to get the concurrent program's log and output links
FUNCTION XX_LINK_OUTPUTLOG (p_request_id  IN      NUMBER  ,
                             x_log_url     OUT     VARCHAR2,
                             x_out_url     OUT     VARCHAR2)
RETURN VARCHAR2;

-- Get email address from process setup form
FUNCTION EMAIL(p_process_name IN VARCHAR2) RETURN VARCHAR2;

-- Procedure to get the concurrent Progream name
FUNCTION CONC_NAME(p_request_Id IN VARCHAR2,x_conc_name OUT VARCHAR2,x_user OUT VARCHAR2)
RETURN VARCHAR2;

-- Procedure to send email
PROCEDURE NOTIFY_USER(p_request_id IN NUMBER ); --,x_status OUT VARCHAR2);

-- Procedure to get the arguments
PROCEDURE USER_PARAM(p_request_id IN NUMBER,x_praram out ARGTBL, j out NUMBER,x_request_id out number);

procedure PUT_LINE(--WHICH in number,
                   BUFF in varchar2);

FUNCTION EMAIL_CHECK(EMAIL_ID VARCHAR2) RETURN NUMBER;

END XX_COMMON_PROCESS_EMAIL;
/


GRANT EXECUTE ON APPS.XX_COMMON_PROCESS_EMAIL TO INTG_XX_NONHR_RO;
