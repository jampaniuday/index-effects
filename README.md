
<h2>Explore Indexes and Extended Statistics Effects on the Oracle Optimizer</h2>

The Oracle optimizer uses columns from indexes to create associations base on those column values 

Questions:

1) does marking an index invisible completely hide it from the optimizer?
2) if an index is dropped, causing the optimize to mis-estimate the cardinalities,
   will extended statistics put it back on track?

Those are the 2 questions I started of with. 

However I noticed something unusual before I got too far with this.

When extended statistics are created via dbms_stats.gather_table_stats, the optimizer treats
them differently than when created with dbms_stats.create_extended_stats.






