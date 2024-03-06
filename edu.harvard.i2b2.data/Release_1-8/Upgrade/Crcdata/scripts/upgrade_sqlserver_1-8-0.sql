--==============================================================
-- Database Script to upgrade CRC from 1.8.0 to 1.8.1                  
--==============================================================



alter table QT_BREAKDOWN_PATH alter column  VALUE VARCHAR(MAX)
;

