
@@extended_stats_def

set serveroutput on size unlimited

begin
	dbms_stats.drop_extended_stats (
		ownname => user,
		tabname => 'INDEX_EFFECTS',
		extension => '&extended_stats_def'
	);


end;
/

set serveroutput off

