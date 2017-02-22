
exec dbms_stats.delete_table_stats(user,'INDEX_EFFECTS')

drop table index_effects purge;

create table index_effects 
as 
select
	mod(level,  10) n1,
	mod(level, 100) n2,
	mod(level,1000) n3,
	lpad('x',42,'x') c1
from dual
connect by level <= 10000
/

exec dbms_stats.gather_table_stats(null,'INDEX_EFFECTS',method_opt=>'for all columns size 1')

--exec dbms_stats.gather_table_stats(null,'INDEX_EFFECTS',method_opt=>'for all columns size auto')

--exec dbms_stats.gather_table_stats(null,'INDEX_EFFECTS',method_opt=>'for all columns size 1 for columns size 254 N1 N2 N3')
--exec dbms_stats.gather_table_stats(null,'INDEX_EFFECTS',method_opt=>'for all columns size 1 for columns size 254 N1 N2 N3 (N1,N2,N3)')
--exec dbms_stats.gather_table_stats(null,'INDEX_EFFECTS',method_opt=>'for all columns size 1 for columns size 254 (N1,N2,N3)')

create index index_effects_2_col on index_effects(n1,n2);
create index index_effects_3_col on index_effects(n1,n2,n3);


