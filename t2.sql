
set serveroutput off

col PLAN_TABLE_OUTPUT format a150

select /*+ index(index_effects) */
	count(*) rowcount
	--n1,n2,n3
from index_effects
where n2=4 and n3=4
/

@showplan_last

