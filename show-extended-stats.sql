
@@extended_stats_def

set serveroutput on size unlimited

declare
	extension_name varchar2(30);
begin
	extension_name := dbms_stats.show_extended_stats_name (
		ownname => user,
		tabname => 'INDEX_EFFECTS',
		extension => '&extended_stats_def'
	);

	dbms_output.put_line(extension_name);

end;
/

set serveroutput off

