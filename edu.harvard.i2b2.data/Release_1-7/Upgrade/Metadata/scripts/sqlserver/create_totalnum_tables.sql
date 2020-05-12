
 --------------------------------------------------------
--  DDL for totalnum table to track counts over time
--------------------------------------------------------

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
    [agg_date]  	datetime NULL,
    [agg_count] 	int NULL
    );
CREATE INDEX totalnum_report_idx ON totalnum([c_fullname]);
