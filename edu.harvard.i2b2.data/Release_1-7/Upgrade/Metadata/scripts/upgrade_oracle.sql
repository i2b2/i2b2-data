--==============================================================
-- Database Script to upgrade ONT from 1.7.10 to 1.7.11                  
--==============================================================


alter table TABLE_ACCESS  add (C_ONTOLOGY_PROTECTION  clob)
;