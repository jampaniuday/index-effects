
-- there are only 100 rows where n1,n2 and n3 have the same value

select n1,n2,n3 from index_effects
where n1=n2
and n2=n3
and n3=n1
/
