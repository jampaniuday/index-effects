

set serveroutput off

col PLAN_TABLE_OUTPUT format a150

select 
	count(*) rowcount
from index_effects
where n1=4 and n3=4
/

@showplan_last


