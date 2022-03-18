CREATE OR REPLACE NONEDITIONABLE PROCEDURE "Insert_Concept_FROMTableAccess" IS

    sqltext VARCHAR(2000);
    CURSOR getsql IS
    SELECT
        'insert into concept_dimension select c_dimcode AS concept_path, c_basecode AS concept_cd,
        c_name AS name_char, null AS concept_blob, update_date AS update_date,
        download_date as download_date, import_date as import_date, sourcesystem_cd as sourcesystem_cd, 1 as upload_id from '
        || c_table_name
        || ' where m_applied_path=''@'' and lower(c_tablename)=''concept_dimension'' 
        and lower(c_columnname)=''concept_path'' and (lower(c_columndatatype)=''t'' or
        lower(c_columndatatype)=''n'') and lower(c_synonym_cd) = ''n'' and m_exclusion_cd is null 
        and c_basecode is not null'
    FROM
        table_access
    WHERE
        c_visualattributes LIKE '%A%';

BEGIN
    DELETE FROM concept_dimension;

    OPEN getsql;
    LOOP
        FETCH getsql INTO sqltext;
        EXIT WHEN getsql%notfound;
        dbms_output.put_line(sqltext);
        EXECUTE IMMEDIATE sqltext;
    END LOOP;

END;
