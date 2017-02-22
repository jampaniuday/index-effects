SELECT column_name, num_distinct, histogram
FROM   dba_tab_col_statistics
WHERE  owner = 'JKSTILL'
	AND  table_name = 'INDEX_EFFECTS'
/
