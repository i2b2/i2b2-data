CREATE OR REPLACE FUNCTION remove_temp_table ( tempTableName IN varchar, errorMsg OUT text )
RETURNS text AS $body$

DECLARE

BEGIN
    EXECUTE 'DROP TABLE ' || tempTableName|| ' CASCADE ';

EXCEPTION 
WHEN OTHERS THEN
    RAISE EXCEPTION 'An error was encountered - % -ERROR- %',SQLSTATE,SQLERRM;      
END;
$body$
LANGUAGE PLPGSQL;
