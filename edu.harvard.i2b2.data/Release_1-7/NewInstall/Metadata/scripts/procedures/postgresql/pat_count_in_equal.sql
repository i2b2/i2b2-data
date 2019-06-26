---------------------------------------------------------------
-- pat_count_in_equal(tabname)
---------------------------------------------------------------  
CREATE OR REPLACE FUNCTION pat_count_in_equal(tabname character varying, observationtable character varying)
  RETURNS void AS
$BODY$
declare 
    -- see also the notes listed in pat_visit_counts().  The methodolgy of the code here is the same unless noted
    v_sqlstr text;
    curRecord RECORD;
    v_num integer;
BEGIN
    raise info 'At %, running PAT_COUNT_IN_EQUAL(''%'')',clock_timestamp(), tabname;

    DISCARD TEMP;
    -- IN / = operator queries on concept or provider dimension

	v_sqlstr := 'create temp table ontInOperator AS '
             || ' select c_fullname '
             || ', c_basecode '
             || ', c_facttablecolumn '
             || ', c_tablename '
             || ', c_columnname '
             || ', c_operator '
             || ', c_dimcode '
             || ', null::integer as numpats '
             || ' from ' || tabname
             || ' where  m_applied_path = ''@'' '
             || ' and lower(c_operator) in (''in'', ''='') '
             || ' and lower(c_tablename) in (''concept_dimension'', ''provider_dimension'') ';
            
    execute v_sqlstr;

    FOR curRecord IN 
        select c_fullname, c_facttablecolumn, c_tablename, c_columnname, c_operator, c_dimcode from ontInOperator
    LOOP 
        if exists(select 1 from information_schema.columns 
                  where table_catalog = current_catalog 
                    and table_schema = 'i2b2demodata'
                    and table_name = lower(curRecord.c_tablename)
                    and column_name = lower(curRecord.c_columnname)
                 ) then 

            -- unlike the pat_visit_counts(), see long note there, this function dynamic query queries
            -- against obersvation_fact rather than the one of the dimension tables.  The original version used 
            -- syntax of WHERE IN (SUBQUERY), which has been converted here to an inner join which Postgres processes
            -- much more quickly than IN ().
            v_sqlstr := 'UPDATE ontInOperator '
                     || ' SET numpats = ( '
                     ||         ' select count(distinct patient_num) '
                     ||         ' from ' || observationtable || ' o'
                     ||         ' inner join i2b2demodata.' || curRecord.c_tablename || ' t'
                     ||         ' on o.' || curRecord.c_facttablecolumn || ' = t.' || curRecord.c_facttablecolumn
                     --||         ' where ' || curRecord.c_facttablecolumn || ' in ( '
                     --||             ' select ' || curRecord.c_facttablecolumn 
                     --||             ' from i2b2demodata.' || curRecord.c_tablename 
                     ||             ' where t.' || curRecord.c_columnname || ' ' || curRecord.c_operator || ' ';
                     
            CASE lower(curRecord.c_operator)
                WHEN 'like' then --this won't be used because of the query above only looking for "IN" and "="
                    v_sqlstr := v_sqlstr || '''' || replace(replace(curRecord.c_dimcode,'\','\\'),'''','''''') || '%''' ;
                WHEN 'in' THEN 
                    v_sqlstr := v_sqlstr || '(' || curRecord.c_dimcode || ')';
                WHEN '=' THEN 
                    v_sqlstr := v_sqlstr || replace(curRecord.c_dimcode,'''','''''') ; -- replace ' with '' in value from table
                ELSE
                v_sqlstr := v_sqlstr || curRecord.c_dimcode;
            END CASE;
            
            v_sqlstr := v_sqlstr --|| ') ' --in
                     ||        ' ) '
                     || ' where c_fullname = ''' || curRecord.c_fullname ||  ''' and numpats is null';

            if lower(curRecord.c_operator) <> 'in' then 
                raise info 'sql: %',v_sqlstr;
            end if;
            execute v_sqlstr;
        else
            -- do nothing since the column does not exist in our schema.
        end if;
    END LOOP;
	
	v_sqlstr := ' update ' || tabname || ' a set c_totalnum=b.numpats '
             || ' from ontInOperator b '
             || ' where a.c_fullname=b.c_fullname ';

    select count(*) into v_num from ontInOperator where numpats is not null and numpats <> 0;
    raise info 'At %, updating c_totalnum in % for % records',clock_timestamp(), tabname, v_num;
    
	execute v_sqlstr;
    discard temp;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;
  