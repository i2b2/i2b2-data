
--==============================================================
-- Database Script to upgrade ONT from 1.7.10 to 1.7.11                  
--==============================================================

alter table TABLE_ACCESS add column C_ONTOLOGY_PROTECTION TEXT
;

--==============================================================
-- Database Script to upgrade ONT from 1.7.11 to 1.7.13                 
--==============================================================

-- New 04-20: Create totalnum table to track changes over time
CREATE TABLE TOTALNUM  ( 
    C_FULLNAME	VARCHAR(850) NULL,
    AGG_DATE  	date NULL,
    AGG_COUNT 	int NULL,
    TYPEFLAG_CD   VARCHAR(3) NULL
    )
;
CREATE INDEX totalnum_idx ON totalnum(c_fullname, agg_date, typeflag_cd)
;
-- Report table to store most recent obfuscated counts
CREATE TABLE TOTALNUM_REPORT  ( 
    C_FULLNAME	VARCHAR(850) NULL,
    AGG_DATE  	VARCHAR(50) NULL,
    AGG_COUNT 	int NULL
    )
;
CREATE INDEX totalnum_report_idx ON totalnum_report(c_fullname)
;