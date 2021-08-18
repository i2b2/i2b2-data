
--==============================================================
-- Database Script to upgrade ONT from 1.7.12a to 1.7.13                  
--==============================================================

-- New 04-20: Create totalnum table to track changes over time
CREATE TABLE [totalnum]  ( 
    [c_fullname]	varchar(850) NULL,
    [agg_date]  	datetime NULL,
    [agg_count] 	int NULL,
    [typeflag_cd]   varchar(3) NULL
    );
CREATE INDEX totalnum_idx ON totalnum([c_fullname], [agg_date], [typeflag_cd]);

-- Report table to store most recent obfuscated counts
CREATE TABLE [totalnum_report]  ( 
    [c_fullname]	varchar(850) NULL,
    [agg_date]  	varchar(50) NULL,
    [agg_count] 	int NULL
    );
CREATE INDEX totalnum_report_idx ON totalnum_report([c_fullname]);
