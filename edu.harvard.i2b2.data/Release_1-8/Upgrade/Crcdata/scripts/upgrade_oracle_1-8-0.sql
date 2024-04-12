--==============================================================
-- Database Script to upgrade CRC from 1.8.0 to 1.8.1                  
--==============================================================


ALTER TABLE QT_BREAKDOWN_PATH ADD (foo CLOB);
UPDATE QT_BREAKDOWN_PATH SET foo = VALUE;
ALTER TABLE QT_BREAKDOWN_PATH DROP COLUMN VALUE;
ALTER TABLE QT_BREAKDOWN_PATH RENAME COLUMN foo TO VALUE;

