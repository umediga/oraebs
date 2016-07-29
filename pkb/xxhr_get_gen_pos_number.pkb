DROP PACKAGE BODY APPS.XXHR_GET_GEN_POS_NUMBER;

CREATE OR REPLACE PACKAGE BODY APPS."XXHR_GET_GEN_POS_NUMBER" 
is

function get_position_number(p_segment1 varchar2,p_segment2 varchar2)
return varchar2
is

l_segment1 varchar2(200);
l_segment2 varchar2(200);

l_next_number varchar2(10);
l_base_number  varchar2(10);
l_pqh_number  varchar2(10);

begin

    l_segment1 := p_segment1;
    l_segment2 := p_segment2;



  BEGIN

    select nvl(max(to_number(segment3)),0)+1
    into l_base_number
    from per_position_definitions ppd
    ,per_positions pp
    where ppd.position_definition_id=pp.position_definition_id
    and segment1 like l_segment1
    and segment2 like l_segment2;


  EXCEPTION
    WHEN others then
      l_next_number := 'XXX';
  END;


  BEGIN

    select nvl(max(to_number(segment3)),0)+1
    into l_pqh_number
    from per_position_definitions ppd
    ,PQH_POSITION_TRANSACTIONS_V pptv
    where ppd.position_definition_id=pptv.position_definition_id
    and segment1 like l_segment1
    and segment2 like l_segment2
    AND pptv.transaction_status in ('PENDING','SUBMITTED','APPROVED');

  EXCEPTION
    WHEN others then
      l_next_number := 'XXX';
  END;

  l_next_number := greatest(to_number(l_base_number),to_number(l_pqh_number));

  IF l_next_number between 1 and 9 THEN
    l_next_number := '00'||l_next_number;
  ELSIF l_next_number between 10 and 99 THEN
    l_next_number := '0'||l_next_number;
  END IF;

  return l_next_number;
exception
   when others then
    raise;
end get_position_number;
end xxhr_get_gen_pos_number;
/
