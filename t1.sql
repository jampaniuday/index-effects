
set serveroutput off

col PLAN_TABLE_OUTPUT format a150

select /*+ index(index_effects) */
	count(*) rowcount
from index_effects
where n1=4 and n2=4
/

@showplan_last

