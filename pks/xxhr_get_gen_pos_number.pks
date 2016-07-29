DROP PACKAGE APPS.XXHR_GET_GEN_POS_NUMBER;

CREATE OR REPLACE PACKAGE APPS."XXHR_GET_GEN_POS_NUMBER" 
is
function get_position_number(p_segment1 varchar2,p_segment2 varchar2)
return varchar2;
end xxhr_get_gen_pos_number;
/
