
--==============================================================
-- Database Script to upgrade ONT from 1.7.12a to 1.7.13                 
--==============================================================

-- New 04-20: Create totalnum table to track changes over time
CREATE TABLE totalnum  ( 
    C_FULLNAME	varchar2(850) NULL,
    AGG_DATE  	date NULL,
    AGG_COUNT 	NUMBER(22,0) NULL,
    TYPEFLAG_CD   varchar2(3) NULL
    )
;
CREATE INDEX totalnum_idx ON totalnum(c_fullname, agg_date, typeflag_cd)
;

-- Report table to store most recent obfuscated counts
CREATE TABLE totalnum_report  ( 
    C_FULLNAME	varchar2(850) NULL,
    AGG_DATE  	varchar2(50) NULL,
    AGG_COUNT 	NUMBER(22,0) NULL
    )
;
CREATE INDEX totalnum_report_idx ON totalnum_report(c_fullname)
;
