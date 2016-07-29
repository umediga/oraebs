DROP PACKAGE APPS.XXINTG_IRC_OFFER_UPDATES;

CREATE OR REPLACE PACKAGE APPS."XXINTG_IRC_OFFER_UPDATES" 
as
/*------------------------------------------------------------------------------
-- Module Name  : AME Offer Approval                                                                                 --
-- File Name    : xxintg_irc_offer_updates.pks                                                                       --
-- Description  : This package is package header.                                                                    --
-- Parameters   :                                                                                                    --
--                                                                                                                   --
-- Created By   : Shekhar Nikam                                                                                      --
-- Creation Date: 07/15/2013                                                                                         --
-- History      : Initial Creation.                                                                                  --
--                                                                                                                   --
--                                                                                                                   --
------------------------------------------------------------------------------*/

function get_offer_transaction_mode
(transaction_id in varchar2)
return varchar2;

function get_offer_spe_comp_changed(p_transaction_id in varchar2)
return varchar2;

function get_lti_on_offer(p_transaction_id in varchar2)
return varchar2;

function get_mb_or_nonlti_comps(p_transaction_id in varchar2)
return varchar2;

end xxintg_irc_offer_updates;
/
