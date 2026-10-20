CREATE OR REPLACE PROCEDURE run_on_all_fact(
    crc_schema VARCHAR DEFAULT 'I2B2DATA'
)
RETURNS INTEGER NULL
LANGUAGE SQL
AS
DECLARE
    results RESULTSET;
    query VARCHAR DEFAULT 'select c_table_name, c_facttablecolumn from table_access where c_visualattributes like ''%A%'' and lower(c_facttablecolumn) like ''%concept_cd'' ';
    tableName VARCHAR;
    ont_table VARCHAR;
    tbl_exists INTEGER;
BEGIN
    execute immediate 'truncate totalnum';
    execute immediate 'truncate totalnum_report';
    results := (EXECUTE IMMEDIATE :query);
    let cur CURSOR FOR results;
    for record in cur do
        -- c_facttablecolumn is either 'concept_cd' (single fact table) or
        -- '<fact_table>.concept_cd' (multi-fact). Fall back to observation_fact
        -- when there is no prefix or the named fact table does not exist.
        IF (record.c_facttablecolumn LIKE '%.%') THEN
            tableName := split_part(record.c_facttablecolumn, '.', 1);
            select count(*) into :tbl_exists
              from information_schema.tables
             where table_schema = upper(:crc_schema)
               and table_name = upper(:tableName);
            IF (tbl_exists = 0) THEN
                tableName := 'observation_fact';
            END IF;
        ELSE
            tableName := 'observation_fact';
        END IF;
        ont_table := record.c_table_name;
        EXECUTE IMMEDIATE ('update ' || ont_table || ' set c_totalnum = null');
        call RUNTOTALNUM(:tableName, :crc_schema, :ont_table);
    end for;
END;
