-----------------------------------------------------------------------------------------------------------------
-- Function to run totalnum counts on all tables in table_access that have a key like PCORI_
-- Depends on the run_all_counts(tablename) function in totalnum_loader_postgres.sql, which must be loaded first
-- 6/8/2016 
-- Modified for PostgreSQL by Dan Vianello, Center for Biomedical Informatics, Washington University in St. Louis
-- If you have questions or issues with the script, please contact i2b2admin@bmi.wustl.edu 
-- Team at WashU: Snehil Gupta, Connie Zabarovskaya, Brian Romine, Dan Vianello

-- DISCLAIMER for PostgreSQL:
-- It's assumed that all functions and related tables used below are in i2b2metadata schema. Please adjust if necessary.
----------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION runtotalnum()
  RETURNS void AS
$BODY$
DECLARE 
    curRecord RECORD;
    --will take advantage of the planned loop through TABLE_ACCESS to also dynamically 
    --build a view of all results with the same number of source tables as found in TABLE_ACCES
    v_sqlstring text = 'CREATE OR REPLACE VIEW pcornet_master_vw AS ';
    v_union text = '';
    --adding variable to hold counts of ontology records with counts.
    v_numpats integer;
begin
    -- added feedback to user defining progress of function
    raise info 'At %, running RunTotalnum()',clock_timestamp();

    -- rather than pre-defining a cursor that needs to be opened and fetched, using FOR RECORD IN QUERY syntax for ease of use and ease of populating variables
    for curRecord IN 
        select 'select run_all_counts(' || quote_literal(''||c_table_name) || ')' as sqltext
             , c_table_name
        from i2b2metadata.TABLE_ACCESS 
        where c_visualattributes like '%A%' and c_table_cd like 'PCORI%'
    LOOP 
        raise info 'At %: Running: %',clock_timestamp(), curRecord.sqltext;
        execute curRecord.sqltext;

        -- display count summary information to the user
        execute 'select count(*) from '||curRecord.c_table_name||' where c_totalnum is not null and c_totalnum <> 0' into v_numpats;
        raise info 'At %: populated % totals for %',clock_timestamp(),v_numpats, curRecord.c_table_name;

        -- build the query to create the view using tables listed in TABLE_ACCESS
        v_sqlstring := v_sqlstring || v_union || 'SELECT C_HLEVEL, C_FULLNAME, C_NAME '
                                   || ', C_SYNONYM_CD, C_VISUALATTRIBUTES '
                                   || ', C_TOTALNUM, C_BASECODE, C_METADATAXML '
                                   || ', C_FACTTABLECOLUMN, C_TABLENAME '
                                   || ', C_COLUMNNAME, C_COLUMNDATATYPE '
                                   || ', C_OPERATOR, C_DIMCODE, C_COMMENT '
                                   || ', C_TOOLTIP, M_APPLIED_PATH, UPDATE_DATE '
                                   || ', DOWNLOAD_DATE, IMPORT_DATE '
                                   || ', SOURCESYSTEM_CD, VALUETYPE_CD '
                                   || ', M_EXCLUSION_CD, C_PATH, C_SYMBOL '
                                   || ', PCORI_BASECODE '
                                   || ' FROM ' || 'i2b2metadata.'||curRecord.c_table_name;
                                   
        --will need to add the keyword in between each table listed, but not before the first table listed
        v_union = ' UNION  ALL ';
    END LOOP;
    --create the view used for reporting information on counts
    raise info 'At %: [Re-]creating view pcornet_master_vw',clock_timestamp();
    execute v_sqlstring;
end; 
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;