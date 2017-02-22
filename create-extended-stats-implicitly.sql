
-- create extented statistics as part of gathering table statistics

exec dbms_stats.gather_table_stats(null,'INDEX_EFFECTS',method_opt=>'for all columns size 1 for columns size 254 (N1,N2,N3)')

