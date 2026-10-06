CREATE OR REPLACE PROCEDURE run_on_all_fact(
    crc_schema VARCHAR DEFAULT 'I2B2DATA'
)
RETURNS INTEGER NULL
LANGUAGE SQL
AS
DECLARE
    results RESULTSET;
    query VARCHAR DEFAULT 'select c_table_name, c_facttablecolumn from table_access where c_visualattributes like ''%A%'' and c_facttablecolumn like ''%.concept_cd'' ';
    tableName VARCHAR;
    ont_table VARCHAR;
BEGIN
    execute immediate 'truncate totalnum';
    execute immediate 'truncate totalnum_report';
    results := (EXECUTE IMMEDIATE :query);
    let cur CURSOR FOR results;
    for record in cur do
        tableName := split_part(record.c_facttablecolumn, '.', 0);
        ont_table := record.c_table_name;
        EXECUTE IMMEDIATE ('update ' || ont_table || ' set c_totalnum = null');
        call RUNTOTALNUM(:tableName, :crc_schema, :ont_table);
    end for;
END;