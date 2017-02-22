

set serveroutput off

col PLAN_TABLE_OUTPUT format a180

select /*+ index(index_effects) */
		distinct count(*) over ( partition by n2,n3) rowcount
from index_effects
where n2=4 and n3=4
/

@showplan_last

