
<h2>Explore Indexes and Extended Statistics Effects on the Oracle Optimizer</h2>

The Oracle optimizer uses columns from indexes to create associations base on those column values 

Questions:

1) does marking an index invisible completely hide it from the optimizer?
2) if an index is dropped, causing the optimize to mis-estimate the cardinalities,
   will extended statistics put it back on track?

Those are the 2 questions I started of with. 

However I noticed something unusual before I got too far with this.

Note: this was first tested on 11.2.0.2, and then on 11.2.0.4.

When extended statistics are created via dbms_stats.gather_table_stats, the optimizer treats
them differently than when created with dbms_stats.create_extended_stats.

First run create.sql to create the test table.

Then run one of the following scripts to create extended statistics.

<h2>create-extended-stats-explicitly.sql</h2>

Create extended statistics using dbms_stats.create_extended_stats


<h2>create-extended-stats-implicitly.sql</h2>

Create extended statistics using dbms_stats.gather_table_stats


I will start with create-extended-stats-implicitly.sql

@create.sql
@create-extended-stats-implicitly.sql

Now check for extended stats:


QL> @show-extended-stats.sql
SYS_STUOYQUEIAZ7FI9DV53VLN$$$0

PL/SQL procedure successfully completed.

These stats also show up as a virtual column:


SQL> @virtual-columns

COLUMN
------------------------------
SYS_STUOYQUEIAZ7FI9DV53VLN$$$0


Now check in dba_tab_col_statistics

@stats

COLUMN                         NUM_DISTINCT HISTOGRAM
------------------------------ ------------ ---------------
N1                                       10 NONE
N2                                      100 NONE
N3                                     1000 NONE
C1                                        1 NONE
SYS_STUOYQUEIAZ7FI9DV53VLN$$$0         1000 HEIGHT BALANCED

5 rows selected.

Now drop the extended statistics

@drop-extended-stats.sql

 PL/SQL procedure successfully completed.

Create the extended stats with dbms_stats.create_extended_stats

@create-extended-stats-explicitly.sql
SYS_STUOYQUEIAZ7FI9DV53VLN$$$0

PL/SQL procedure successfully completed.

Now check with stats.sql again:

Hmm, there does not seem to be any extended stats...

 SQL> @stats

 COLUMN                         NUM_DISTINCT HISTOGRAM
 ------------------------------ ------------ ---------------
 N1                                       10 NONE
 N2                                      100 NONE
 N3                                     1000 NONE
 C1                                        1 NONE

 4 rows selected.

Now check with dbms_stats.show_extended_stats

 @show-extended-stats
 SYS_STUOYQUEIAZ7FI9DV53VLN$$$0

 PL/SQL procedure successfully completed.


The virtual column also appears:

 @virtual-columns

 COLUMN
 ------------------------------
 SYS_STUOYQUEIAZ7FI9DV53VLN$$$0

 1 row selected.

Though the extended statistics can be seen via dbms_stats.show_extended_stats, when created with dbms_stats.create_extended_stats they do not appear in dba_tab_col_statistics.

At this point I wondered: "Might the optimizer be treating extended stats differently depending on how they were created?"

The answer to that can be seen by using the 10053 optimizer trace.


<h3>10053 Trace on Extended Stats - created via =>method_opt</h3>





<h3>10053 Trace on Extended Stats - created via dbms_stats.create_extended_stats</h3>






<h2>drop-extended-stats.sql</h2>

Drop the exteneded statistics

A call to dbms_stats.drop_extended_stats

<h2>show-extended-stats.sql</h2>

PL/SQL call to dbms_stats.show_extended_stats_name

<h2>stats.sql</h2>

Show stats from dba_tab_col_statistics

<h2>tid.sql</h2>

Runs the SQL in sql2trace.sql and retrieves the trace file from the server.

See <a href="https://github.com/jkstill/tracefile_identifier">Tracefile identifier</a> for more on using this script.

<h2>virtual-columns.sql</h2>

Show any virtual columns on the test table




