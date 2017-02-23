
<h2>Explore Indexes and Extended Statistics Effects on the Oracle Optimizer</h2>

The Oracle optimizer uses columns from indexes to create associations base on those column values 

Questions:

<style>
table {
    font-family: arial, sans-serif;
    border-collapse: collapse;
    width: 100%;
}

td, th {
    border: 1px solid #dddddd;
    text-align: left;
    padding: 8px;
}

tr:nth-child(even) {
    background-color: #dddddd;
}
</style>
</head>
<body>

<table>
  <tr>
    <th>Q#</th>
    <th>Question</th>
  </tr>
  <tr>
    <td>#1</td>
    <td>does marking an index invisible completely hide it from the optimizer?</td>
  </tr>
  <tr>
    <td>#2</td>
    <td>if an index is dropped  causing the optimize to mis-estimate the cardinalities will extended statistics put it back on track</td>
  </tr>
</table>

Those are the 2 questions I started of with. 

However I noticed something unusual before I got too far with this.

Note: this was first tested on 11.2.0.2, and then on 11.2.0.3.

When extended statistics are created via dbms_stats.gather_table_stats, the optimizer treats
them differently than when created with dbms_stats.create_extended_stats.

First run create.sql to create the test table.

Then run one of the following scripts to create extended statistics.

<h4>create-extended-stats-explicitly.sql</h4>

Create extended statistics using dbms_stats.create_extended_stats


<h4>create-extended-stats-implicitly.sql</h4>

Create extended statistics using dbms_stats.gather_table_stats


I will start with create-extended-stats-implicitly.sql

@create.sql
@create-extended-stats-implicitly.sql

Now check for extended stats:


<blockquote style='border: 2px solid #000;background-color:#D8D8D8;color:#0B0B61; white-space: pre-wrap;'>
<pre><code><i>
SQL# @show-extended-stats.sql
SYS_STUOYQUEIAZ7FI9DV53VLN$$$0

PL/SQL procedure successfully completed.
</i></code></pre>
</blockquote>

These stats also show up as a virtual column:


SQL# @virtual-columns

COLUMN
------------------------------
SYS_STUOYQUEIAZ7FI9DV53VLN$$$0


Now check in dba_tab_col_statistics

<blockquote style='border: 2px solid #000;background-color:#A9F5F2;color:#0B0B61; white-space: pre-wrap;'>
<pre><code><i>
@stats

COLUMN                         NUM_DISTINCT HISTOGRAM
------------------------------ ------------ ---------------
N1                                       10 NONE
N2                                      100 NONE
N3                                     1000 NONE
C1                                        1 NONE
SYS_STUOYQUEIAZ7FI9DV53VLN$$$0         1000 HEIGHT BALANCED

5 rows selected.
</i></code></pre>
</blockquote>

Now drop the extended statistics

<blockquote style='border: 2px solid #000;background-color:#A9F5F2;color:#0B0B61; white-space: pre-wrap;'>
<pre><code><i>
@drop-extended-stats.sql

 PL/SQL procedure successfully completed.

Create the extended stats with dbms_stats.create_extended_stats

@create-extended-stats-explicitly.sql
SYS_STUOYQUEIAZ7FI9DV53VLN$$$0

PL/SQL procedure successfully completed.
</i></code></pre>
</blockquote>

Now check with stats.sql again:

Hmm, there does not seem to be any extended stats...

<blockquote style='border: 2px solid #000;background-color:#A9F5F2;color:#0B0B61; white-space: pre-wrap;'>
<pre><code><i>
 SQL# @stats

 COLUMN                         NUM_DISTINCT HISTOGRAM
 ------------------------------ ------------ ---------------
 N1                                       10 NONE
 N2                                      100 NONE
 N3                                     1000 NONE
 C1                                        1 NONE

 4 rows selected.

</i></code></pre>
</blockquote>

Now check with dbms_stats.show_extended_stats

<blockquote style='border: 2px solid #000;background-color:#A9F5F2;color:#0B0B61; white-space: pre-wrap;'>
<pre><code><i>
 @show-extended-stats
 SYS_STUOYQUEIAZ7FI9DV53VLN$$$0

 PL/SQL procedure successfully completed.
</i></code></pre>
</blockquote>


The virtual column also appears:

<blockquote style='border: 2px solid #000;background-color:#A9F5F2;color:#0B0B61; white-space: pre-wrap;'>
<pre><code><i>
 @virtual-columns

 COLUMN
 ------------------------------
 SYS_STUOYQUEIAZ7FI9DV53VLN$$$0

 1 row selected.
</i></code></pre>
</blockquote>

Though the extended statistics can be seen via dbms_stats.show_extended_stats, when created with dbms_stats.create_extended_stats they do not appear in dba_tab_col_statistics.

At this point I wondered: "Might the optimizer be treating extended stats differently depending on how they were created?"

The answer to that can be seen by using the 10053 optimizer trace.


<h3>10053 Trace on Extended Stats - created via =>method_opt</h3>

Run the create.sql script to recreate the table and indexes, and initial statistics.

Now recreate the extended statistics via the method_opt method

<blockquote style='border: 2px solid #000;background-color:#A9F5F2;color:#0B0B61; white-space: pre-wrap;'>
<pre><code><i>
 SQL# @create-extended-stats-implicitly.sql

 PL/SQL procedure successfully completed.

 Elapsed: 00:00:00.75
 SQL# @show-extended-stats.sql
 SYS_STUOYQUEIAZ7FI9DV53VLN$$$0

 PL/SQL procedure successfully completed.

 Elapsed: 00:00:00.00
 SQL# @stats

 COLUMN                         NUM_DISTINCT HISTOGRAM
 ------------------------------ ------------ ---------------
 N1                                       10 NONE
 N2                                      100 NONE
 N3                                     1000 NONE
 C1                                        1 NONE
 SYS_STUOYQUEIAZ7FI9DV53VLN$$$0         1000 HEIGHT BALANCED

 5 rows selected.
</i></code></pre>
</blockquote>


The script tid-10053.sql has been set to do the following

-- connect to the database
-- set the tracefile_identifier
-- initiate a 10053 trace
-- run the following SQL statement

<pre>
  select /*+ index(index_effects) */
  count(\*)
  from index_effects
  where n2=4 and n3=4
</pre>

-- complete the 10053 trace
-- retrieve the trace file

Following are the relevant bits of the trace file for this execution

<blockquote style='border: 2px solid #000;background-color:#D8D8D8;color:#0B0B61; white-space: pre-wrap;'>
<pre><code><i>
***************************************
BASE STATISTICAL INFORMATION
***********************
Table Stats::
  Table: INDEX_EFFECTS  Alias: INDEX_EFFECTS
    #Rows: 10000  #Blks:  89  AvgRowLen:  65.00  ChainCnt:  0.00
Index Stats::
  Index: INDEX_EFFECTS_2_COL  Col#: 1 2
    LVLS: 1  #LB: 24  #DK: 100  LB/K: 1.00  DB/K: 80.00  CLUF: 8019.00
    User hint to use this index
  Index: INDEX_EFFECTS_3_COL  Col#: 1 2 3
    LVLS: 1  #LB: 29  #DK: 1000  LB/K: 1.00  DB/K: 10.00  CLUF: 10000.00
    User hint to use this index
Access path analysis for INDEX_EFFECTS
***************************************
SINGLE TABLE ACCESS PATH
  Single Table Cardinality Estimation for INDEX_EFFECTS[INDEX_EFFECTS]
  Column (#2): N2(
    AvgLen: 3 NDV: 100 Nulls: 0 Density: 0.010000 Min: 0 Max: 99
  Column (#3): N3(
    AvgLen: 4 NDV: 1000 Nulls: 0 Density: 0.001000 Min: 0 Max: 999
  Column (#5):
    NewDensity:0.001000, OldDensity:0.001000 BktCnt:254, PopBktCnt:0, PopValCnt:0, NDV:1000
  Column (#5): SYS_STUOYQUEIAZ7FI9DV53VLN$$$0(
    AvgLen: 12 NDV: 1000 Nulls: 0 Density: 0.001000 Min: 10995152 Max: 9999971098
    Histogram: HtBal  #Bkts: 254  UncompBkts: 254  EndPtVals: 255
  Column (#1): N1(
    AvgLen: 3 NDV: 10 Nulls: 0 Density: 0.100000 Min: 0 Max: 9
  <b style='background-color:yellow; color:black'>ColGroup (#1, VC) SYS_STUOYQUEIAZ7FI9DV53VLN$$$0</b>
    <b style='background-color:yellow; color:black'>Col#: 1 2 3    CorStregth: 1000.00</b>
  <b style='background-color:yellow; color:black'>ColGroup (#2, Index) INDEX_EFFECTS_2_COL</b>
    <b style='background-color:yellow; color:black'>Col#: 1 2    CorStregth: 10.00</b>
  <b style='background-color:yellow; color:black'>ColGroup Usage:: PredCnt: 2  Matches Full:  Partial: #1 (2 3 )  Sel: 0.0010</b>
  Table: INDEX_EFFECTS  Alias: INDEX_EFFECTS
    Card: Original: 10000.000000  Rounded: 10  Computed: 10.00  Non Adjusted: 10.00
kkofmx: index filter:"INDEX_EFFECTS"."N2"=4

kkofmx: index filter:"INDEX_EFFECTS"."N2"=4

kkofmx: index filter:"INDEX_EFFECTS"."N3"=4

  Access Path: index (skip-scan)
    SS sel: 0.010000  ANDV (#skips): 10.000000
    SS io: 10.000000 vs. table scan io: 26.000000
    Skip Scan chosen
  Access Path: index (SkipScan)
    Index: INDEX_EFFECTS_2_COL
    resc_io: 92.00  resc_cpu: 699172
    ix_sel: 0.010000  ix_sel_with_filters: 0.010000
    Cost: 92.03  Resp: 92.03  Degree: 1
  ColGroup Usage:: PredCnt: 2  Matches Full:  Partial: #1 (2 3 )  Sel: 0.0010
  Access Path: index (skip-scan)
    SS sel: 0.001000  ANDV (#skips): 10.000000
    SS io: 10.000000 vs. table scan io: 26.000000
    Skip Scan chosen
  Access Path: index (SkipScan)
    Index: INDEX_EFFECTS_3_COL
    resc_io: 11.00  resc_cpu: 80336
    ix_sel: 0.001000  ix_sel_with_filters: 0.001000
    Cost: 11.00  Resp: 11.00  Degree: 1
  Best:: AccessPath: IndexRange
  Index: INDEX_EFFECTS_3_COL
         Cost: 11.00  Degree: 1  Resp: 11.00  Card: 10.00  Bytes: 0

</i></code></pre>
</blockquote>

The label of CorStegth refers to 'Correlation Strength', meaning the correlation beween the index and the column group.

Using the script stats.sql we can see what Oracle has recorded for NDV (Num Distinct Values) for each column, including the column group

<blockquote style='border: 2px solid #000;background-color:#A9F5F2;color:#0B0B61; white-space: pre-wrap;'>
<pre><code><i>
 SQL# @stats

 COLUMN                         NUM_DISTINCT HISTOGRAM
 ------------------------------ ------------ ---------------
 N1                                       10 NONE
 N2                                      100 NONE
 N3                                     1000 NONE
 C1                                        1 NONE
 SYS_STUOYQUEIAZ7FI9DV53VLN$$$0         1000 HEIGHT BALANCED
</i></code></pre>
</blockquote>


The formula used to compute the cardinality can be found in this Oracle Support Note:
<i>MultiColumn/Column Group Statistics - Additional Examples (Doc ID 872406.1)</i>

The initial and computed Cardinality values are seen in this line:
<i>    Card: Original: 10000.000000  Rounded: 10  Computed: 10.00  Non Adjusted: 10.00</i>

The optimizer arrived at a value of 10 via this formula:

CG = Column Group
NDV = Number of Distinct Values

Predicate Selectivity = 1/NDV(CG #1) * 1/NDV(N1) = 1/1000 * 1/10 = 1/10000

Next:  Original Cardinality (in 10053 trace file) / value just computed

10000 * (1/1000) = 10

<h3>10053 Trace on Extended Stats - created via dbms_stats.create_extended_stats</h3>

Now let's do the excercise again, this time creating the extended statistics with dbms_stats.create_extended_stats

<blockquote style='border: 2px solid #000;background-color:#A9F5F2;color:#0B0B61; white-space: pre-wrap;'>
<pre><code><i>
SQL# @drop-extended-stats.sql

PL/SQL procedure successfully completed.

SQL# @show-extended-stats.sql
declare
*
ERROR at line 1:
ORA-20000: extension "(N1,N2,N3)" does not exist
ORA-06512: at "SYS.DBMS_STATS", line 31791
ORA-06512: at line 4


SQL# @create-extended-stats-explicitly.sql
SYS_STUOYQUEIAZ7FI9DV53VLN$$$0

PL/SQL procedure successfully completed.
</i></code></pre>
</blockquote>


Verify the stats do not appear in dba_tab_col_statistics


<blockquote style='border: 2px solid #000;background-color:#A9F5F2;color:#0B0B61; white-space: pre-wrap;'>
<pre><code><i>
SQL# @stats

COLUMN                         NUM_DISTINCT HISTOGRAM
------------------------------ ------------ ---------------
N1                                       10 NONE
N2                                      100 NONE
N3                                     1000 NONE
C1                                        1 NONE

4 rows selected.
</i></code></pre>
</blockquote>

... but they are found by dbms_stats.show_extended_stats.

<blockquote style='border: 2px solid #000;background-color:#A9F5F2;color:#0B0B61; white-space: pre-wrap;'>
<pre><code><i>
SQL# @show-extended-stats.sql
SYS_STUOYQUEIAZ7FI9DV53VLN$$$0

PL/SQL procedure successfully completed.
</i></code></pre>
</blockquote>

OK, now run a 10053 trace again

Before continuing I have to admit that I been unable to exactly reproduce the results I had previously seen on two different databases.

What was previously seen was this:

<blockquote style='border: 2px solid #000;background-color:#D8D8D8;color:#0B0B61; white-space: pre-wrap;'>
<pre><code><i>
SINGLE TABLE ACCESS PATH
  Single Table Cardinality Estimation for INDEX_EFFECTS[INDEX_EFFECTS]
  Column (#2):
    NewDensity:0.005000, OldDensity:0.000050 BktCnt:10000, PopBktCnt:10000, PopValCnt:100, NDV:100
  Column (#2): N2(
    AvgLen: 3 NDV: 100 Nulls: 0 Density: 0.005000 Min: 0 Max: 99
    Histogram: Freq  #Bkts: 100  UncompBkts: 10000  EndPtVals: 100
  Column (#3):
    NewDensity:0.001000, OldDensity:0.001000 BktCnt:254, PopBktCnt:0, PopValCnt:0, NDV:1000
  Column (#3): N3(
    AvgLen: 4 NDV: 1000 Nulls: 0 Density: 0.001000 Min: 0 Max: 999
    Histogram: HtBal  #Bkts: 254  UncompBkts: 254  EndPtVals: 255
  ColGroup (#1, Index) INDEX_EFFECTS_3_COL
    Col#: 1 2 3    CorStregth: -1.00
  ColGroup (#2, Index) INDEX_EFFECTS_2_COL
    Col#: 1 2    CorStregth: -1.00
  ColGroup Usage:: PredCnt: 2  Matches Full:  Partial:
  Table: INDEX_EFFECTS  Alias: INDEX_EFFECTS
    Card: Original: 10000.000000  Rounded: 1  Computed: 0.10  Non Adjusted: 0.10
</i></code></pre>
</blockquote>

Notice the -1.00 values for CorStregth.

Also notice the cardinality has changed from 10 to .1, a 100x difference.

When rerunning this test I find the the CorStregth values are the same as when the column group was created via method_opt, but the cardinality is still wrong.

This is the result of the test just executed:

<blockquote style='border: 2px solid #000;background-color:#D8D8D8;color:#0B0B61; white-space: pre-wrap;'>
<pre><code><i>
BASE STATISTICAL INFORMATION
***********************
Table Stats::
  Table: INDEX_EFFECTS  Alias: INDEX_EFFECTS
    #Rows: 10000  #Blks:  89  AvgRowLen:  53.00  ChainCnt:  0.00
Index Stats::
  Index: INDEX_EFFECTS_2_COL  Col#: 1 2
    LVLS: 1  #LB: 24  #DK: 100  LB/K: 1.00  DB/K: 80.00  CLUF: 8019.00
    User hint to use this index
  Index: INDEX_EFFECTS_3_COL  Col#: 1 2 3
    LVLS: 1  #LB: 29  #DK: 1000  LB/K: 1.00  DB/K: 10.00  CLUF: 10000.00
    User hint to use this index
Access path analysis for INDEX_EFFECTS
***************************************
SINGLE TABLE ACCESS PATH
  Single Table Cardinality Estimation for INDEX_EFFECTS[INDEX_EFFECTS]
  Column (#2):
    NewDensity:0.005000, OldDensity:0.000050 BktCnt:10000, PopBktCnt:10000, PopValCnt:100, NDV:100
  Column (#2): N2(
    AvgLen: 3 NDV: 100 Nulls: 0 Density: 0.005000 Min: 0 Max: 99
    Histogram: Freq  #Bkts: 100  UncompBkts: 10000  EndPtVals: 100
  Column (#3):
    NewDensity:0.001000, OldDensity:0.001000 BktCnt:254, PopBktCnt:0, PopValCnt:0, NDV:1000
  Column (#3): N3(
    AvgLen: 4 NDV: 1000 Nulls: 0 Density: 0.001000 Min: 0 Max: 999
    Histogram: HtBal  #Bkts: 254  UncompBkts: 254  EndPtVals: 255
  <b style='background-color:yellow; color:black'>Column (#5): SYS_STUOYQUEIAZ7FI9DV53VLN$$$0(  NO STATISTICS (using defaults)</b>
    AvgLen: 13 NDV: 312 Nulls: 0 Density: 0.003200
  Column (#1):
    NewDensity:0.050000, OldDensity:0.000050 BktCnt:10000, PopBktCnt:10000, PopValCnt:10, NDV:10
  Column (#1): N1(
    AvgLen: 3 NDV: 10 Nulls: 0 Density: 0.050000 Min: 0 Max: 9
    Histogram: Freq  #Bkts: 10  UncompBkts: 10000  EndPtVals: 10
  ColGroup (#1, Index) INDEX_EFFECTS_3_COL
    Col#: 1 2 3    CorStregth: 1000.00
  ColGroup (#2, Index) INDEX_EFFECTS_2_COL
    Col#: 1 2    CorStregth: 10.00
  ColGroup Usage:: PredCnt: 2  Matches Full:  Partial:
  Table: INDEX_EFFECTS  Alias: INDEX_EFFECTS
    Card: Original: 10000.000000  Rounded: 1  Computed: 0.10  Non Adjusted: 0.10
kkofmx: index filter:"INDEX_EFFECTS"."N2"=4

kkofmx: index filter:"INDEX_EFFECTS"."N2"=4

kkofmx: index filter:"INDEX_EFFECTS"."N3"=4

  Access Path: index (skip-scan)
    SS sel: 0.010000  ANDV (#skips): 10.000000
    SS io: 10.000000 vs. table scan io: 26.000000
    Skip Scan chosen
  Access Path: index (SkipScan)
    Index: INDEX_EFFECTS_2_COL
    resc_io: 92.00  resc_cpu: 699172
    ix_sel: 0.010000  ix_sel_with_filters: 0.010000
    Cost: 92.03  Resp: 92.03  Degree: 1
  ColGroup Usage:: PredCnt: 2  Matches Full:  Partial:
  Access Path: index (skip-scan)
    SS sel: 0.000010  ANDV (#skips): 10.000000
    SS io: 10.000000 vs. table scan io: 26.000000
    Skip Scan chosen
  Access Path: index (SkipScan)
    Index: INDEX_EFFECTS_3_COL
    resc_io: 11.00  resc_cpu: 78536
    ix_sel: 0.000010  ix_sel_with_filters: 0.000010
    Cost: 11.00  Resp: 11.00  Degree: 1
  Best:: AccessPath: IndexRange
  Index: INDEX_EFFECTS_3_COL
         Cost: 11.00  Degree: 1  Resp: 11.00  Card: 0.10  Bytes: 0
</i></code></pre>
</blockquote>

Note that the optimizer shows there are NO STATISTICS for the Column 5, the virtual column created for the extended statistics.

The result is that default values are used to estimate the cardinality, which is incorrect.

What the optimizer appears to have done is multiply the original cardinality * the selectivity of index INDEX_EFFECTS_3_COL

10000 * 0.000010 = 0.10


<h3>Summary</h3>

Extended statistics created via dbms_stats.create_extended_stats are incomplete.

It is best to use the method_opt method to create extended statistics (column groups)

<h3>To Do</h3>

- Construct a test case such that the inaccurate cardinality causes the optimizer to choose a poor execution plan
- Determine how the optimizer is gather the statistics information, leading to this condition.
  This could be done by combining a 10046 trace with a 10053 trace. I just have not yet done so.


<h3>SQL Scripts</h3>


<h4>create-extended-stats-explicitly.sql</h4>

Create extended statistics using dbms_stats.create_extended_stats


<h4>create-extended-stats-implicitly.sql</h4>

Create extended statistics using dbms_stats.gather_table_stats


<h4>drop-extended-stats.sql</h4>

Drop the exteneded statistics

A call to dbms_stats.drop_extended_stats

<h4>show-extended-stats.sql</h4>

PL/SQL call to dbms_stats.show_extended_stats_name

<h4>stats.sql</h4>

Show stats from dba_tab_col_statistics

<h4>tid-10053.sql</h4>

Runs the SQL in sql2trace.sql and retrieves the trace file from the server.

See <a href="https://github.com/jkstill/tracefile_identifier">Tracefile identifier</a> for more on using this script.

<h4>virtual-columns.sql</h4>

Show any virtual columns on the test table




